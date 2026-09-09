-- ============================================================
-- Abarrotería Pro — Migración 010: Descuentos en venta (US-029)
-- Ejecuta en Supabase SQL Editor (proyecto conectado)
--
-- Conviene correrla cuando no haya una venta en curso: borra y
-- recrea confirm_sale (ver la nota sobre las firmas duplicadas).
-- ============================================================

-- ── Extensión para hashear el PIN ─────────────────────────────
-- pgcrypto no estaba habilitado explícitamente en ninguna migración.
-- Supabase suele traerlo en el esquema `extensions`, pero las funciones
-- de este proyecto usan `SET search_path = public`, así que crypt() no
-- resolvería. Las dos funciones del PIN declaran el search_path ampliado.
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- ── Columnas de descuento ─────────────────────────────────────
-- Todas con DEFAULT 0: las ventas históricas quedan válidas sin migrar
-- datos. sale_items.subtotal SIGUE SIENDO BRUTO (cantidad × precio) y
-- sales.total SIGUE SIENDO NETO (lo que paga el cliente) — el cuadre de
-- caja de 008 suma sales.total, así que cambiar ese significado haría
-- que el arqueo dejara de cuadrar.
ALTER TABLE public.sale_items
  ADD COLUMN IF NOT EXISTS discount_amount NUMERIC NOT NULL DEFAULT 0 CHECK (discount_amount >= 0);

ALTER TABLE public.sales
  ADD COLUMN IF NOT EXISTS discount_amount NUMERIC NOT NULL DEFAULT 0 CHECK (discount_amount >= 0);

ALTER TABLE public.sales
  ADD COLUMN IF NOT EXISTS discount_authorized BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN public.sale_items.discount_amount IS 'Descuento aplicado a este ítem, en pesos. subtotal sigue siendo bruto — US-029';
COMMENT ON COLUMN public.sales.discount_amount IS 'Descuento global de la venta, en pesos (no incluye los descuentos por ítem) — US-029';
COMMENT ON COLUMN public.sales.discount_authorized IS 'TRUE si el descuento superó el umbral y se validó con el PIN del AdminMaster — US-029';

-- Umbral configurable: a partir de qué % de descuento se exige PIN.
ALTER TABLE public.store_settings
  ADD COLUMN IF NOT EXISTS discount_pin_threshold_percent NUMERIC NOT NULL DEFAULT 10;

COMMENT ON COLUMN public.store_settings.discount_pin_threshold_percent IS 'Porcentaje de descuento a partir del cual se exige el PIN del AdminMaster — US-029';

-- ── Tabla: admin_secrets ──────────────────────────────────────
-- RLS habilitado y CERO policies a propósito: en Postgres eso deniega
-- todo acceso desde el cliente, incluso al AdminMaster. Solo la alcanzan
-- las funciones SECURITY DEFINER de abajo. El hash NO puede vivir en
-- store_settings, cuya policy de SELECT es `TO authenticated USING (true)`
-- (006:22-25): cualquier cajero lee esa fila completa.
CREATE TABLE IF NOT EXISTS public.admin_secrets (
  id                 INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  discount_pin_hash  TEXT,
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.admin_secrets (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.admin_secrets ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.admin_secrets IS 'Secretos que ningún cliente debe leer. RLS sin policies = acceso denegado salvo desde funciones SECURITY DEFINER — US-029';

-- ── Función: fijar el PIN de descuentos ───────────────────────
CREATE OR REPLACE FUNCTION public.set_discount_pin(p_pin TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public, extensions
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'adminmaster'
  ) THEN
    RAISE EXCEPTION 'Solo el AdminMaster puede configurar el PIN de descuentos';
  END IF;

  IF p_pin IS NULL OR length(trim(p_pin)) < 4 THEN
    RAISE EXCEPTION 'El PIN debe tener al menos 4 caracteres';
  END IF;

  UPDATE public.admin_secrets
  SET discount_pin_hash = crypt(trim(p_pin), gen_salt('bf')), updated_at = NOW()
  WHERE id = 1;
END;
$$;

-- ── Función: saber si hay PIN configurado ─────────────────────
-- Devuelve solo un booleano; nunca expone el hash.
CREATE OR REPLACE FUNCTION public.has_discount_pin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_hash TEXT;
BEGIN
  SELECT discount_pin_hash INTO v_hash FROM public.admin_secrets WHERE id = 1;
  RETURN v_hash IS NOT NULL;
END;
$$;

-- ── confirm_sale: se borran las firmas viejas ─────────────────
-- IMPORTANTE: hasta ahora convivían DOS versiones de confirm_sale.
-- 004 la creó con 5 parámetros y 006 hizo CREATE OR REPLACE con 6 — pero
-- la identidad de una función en Postgres incluye su lista de argumentos,
-- así que eso NO reemplazó nada: creó una sobrecarga. (El comentario de
-- 006:82-85 afirma lo contrario; es incorrecto.)
--
-- Funcionaba por casualidad porque el cliente siempre manda los 6.
-- Si aquí hiciéramos otro CREATE OR REPLACE quedarían TRES versiones y
-- la de 5 argumentos seguiría cobrando sin aplicar descuentos. Por eso
-- se borran ambas explícitamente antes de crear la definitiva.
DROP FUNCTION IF EXISTS public.confirm_sale(UUID, TEXT, NUMERIC, NUMERIC, JSONB);
DROP FUNCTION IF EXISTS public.confirm_sale(UUID, TEXT, NUMERIC, NUMERIC, JSONB, TEXT);

-- ── confirm_sale: versión con descuentos ──────────────────────
-- Mantiene el criterio de siempre: calcula todo server-side y nunca
-- confía en los totales que manda el cliente. El descuento se aplica
-- ANTES de validar el pago, o el cambio a devolver saldría mal.
CREATE FUNCTION public.confirm_sale(
  p_cash_register_id   UUID,
  p_payment_method     TEXT,
  p_cash_amount        NUMERIC,
  p_transfer_amount    NUMERIC,
  p_items              JSONB,
  p_receipt_photo_url  TEXT DEFAULT NULL,
  p_discount_amount    NUMERIC DEFAULT 0,
  p_discount_pin       TEXT DEFAULT NULL
)
RETURNS public.sales
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public, extensions
AS $$
DECLARE
  v_cashier_id      UUID := auth.uid();
  v_gross           NUMERIC := 0;   -- suma de cantidad × precio, sin descuentos
  v_item_discounts  NUMERIC := 0;   -- suma de los descuentos por ítem
  v_global_discount NUMERIC := COALESCE(p_discount_amount, 0);
  v_total           NUMERIC := 0;   -- neto: lo que paga el cliente
  v_discount_pct    NUMERIC := 0;
  v_threshold       NUMERIC := 10;
  v_pin_hash        TEXT;
  v_authorized      BOOLEAN := FALSE;
  v_change          NUMERIC := 0;
  v_sale            public.sales;
  v_item            JSONB;
  v_product_id      UUID;
  v_quantity        INTEGER;
  v_unit_price      NUMERIC;
  v_item_discount   NUMERIC;
  v_current_stock   INTEGER;
BEGIN
  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'La venta no tiene productos';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.cash_registers
    WHERE id = p_cash_register_id AND cashier_id = v_cashier_id AND status = 'open'
  ) THEN
    RAISE EXCEPTION 'No tienes una caja abierta válida para esta venta';
  END IF;

  IF v_global_discount < 0 THEN
    RAISE EXCEPTION 'El descuento no puede ser negativo';
  END IF;

  -- ── Bucle 1: valida stock y acumula bruto + descuentos de ítem ──
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_product_id    := (v_item->>'product_id')::UUID;
    v_quantity      := (v_item->>'quantity')::INTEGER;
    v_unit_price    := (v_item->>'unit_price')::NUMERIC;
    v_item_discount := COALESCE((v_item->>'discount')::NUMERIC, 0);

    IF v_quantity <= 0 THEN
      RAISE EXCEPTION 'Cantidad inválida para %', v_item->>'product_name';
    END IF;

    IF v_item_discount < 0 THEN
      RAISE EXCEPTION 'El descuento de "%" no puede ser negativo', v_item->>'product_name';
    END IF;

    IF v_item_discount > (v_quantity * v_unit_price) THEN
      RAISE EXCEPTION 'El descuento de "%" supera su subtotal', v_item->>'product_name';
    END IF;

    SELECT stock INTO v_current_stock
    FROM public.products
    WHERE id = v_product_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Producto no encontrado: %', v_item->>'product_name';
    END IF;

    IF v_current_stock < v_quantity THEN
      RAISE EXCEPTION 'Stock insuficiente para "%" (disponible: %, solicitado: %)',
        v_item->>'product_name', v_current_stock, v_quantity;
    END IF;

    v_gross          := v_gross + (v_quantity * v_unit_price);
    v_item_discounts := v_item_discounts + v_item_discount;
  END LOOP;

  -- ── Descuento global y neto ────────────────────────────────
  -- El global no puede superar lo que queda tras los descuentos de ítem:
  -- así el neto nunca es negativo y el CHECK (total >= 0) sigue intacto.
  IF v_global_discount > (v_gross - v_item_discounts) THEN
    RAISE EXCEPTION 'El descuento global supera el total de la venta';
  END IF;

  v_total := v_gross - v_item_discounts - v_global_discount;

  -- ── PIN si el descuento supera el umbral ───────────────────
  IF v_gross > 0 THEN
    v_discount_pct := ((v_item_discounts + v_global_discount) / v_gross) * 100;
  END IF;

  SELECT COALESCE(discount_pin_threshold_percent, 10) INTO v_threshold
  FROM public.store_settings WHERE id = 1;

  IF v_discount_pct > COALESCE(v_threshold, 10) THEN
    SELECT discount_pin_hash INTO v_pin_hash FROM public.admin_secrets WHERE id = 1;

    -- Nota: RAISE de plpgsql usa % como marcador posicional y no admite
    -- formato printf (%.1f imprimiría ".1f" literal), por eso el redondeo
    -- va en round() y el símbolo de porcentaje se escribe con palabras.
    IF v_pin_hash IS NULL THEN
      RAISE EXCEPTION 'Este descuento (% por ciento) requiere autorización, pero no hay un PIN configurado. Pídele al AdminMaster que lo configure en Ajustes.', round(v_discount_pct, 1);
    END IF;

    IF p_discount_pin IS NULL OR crypt(trim(p_discount_pin), v_pin_hash) <> v_pin_hash THEN
      RAISE EXCEPTION 'PIN de autorización incorrecto. Este descuento (% por ciento) supera el máximo permitido sin autorización (% por ciento).', round(v_discount_pct, 1), v_threshold;
    END IF;

    v_authorized := TRUE;
  END IF;

  -- ── Validación del pago, contra el NETO ────────────────────
  IF p_payment_method = 'efectivo' THEN
    IF p_cash_amount IS NULL OR p_cash_amount < v_total THEN
      RAISE EXCEPTION 'El monto recibido es menor al total de la venta';
    END IF;
    v_change := p_cash_amount - v_total;
  ELSIF p_payment_method = 'mixto' THEN
    IF abs(COALESCE(p_cash_amount, 0) + COALESCE(p_transfer_amount, 0) - v_total) > 1 THEN
      RAISE EXCEPTION 'La suma de efectivo y transferencia no coincide con el total';
    END IF;
  ELSIF p_payment_method != 'transferencia' THEN
    RAISE EXCEPTION 'Método de pago inválido: %', p_payment_method;
  END IF;

  INSERT INTO public.sales (
    cashier_id, cash_register_id, total, payment_method, cash_amount, transfer_amount, change_amount,
    receipt_photo_url, discount_amount, discount_authorized
  ) VALUES (
    v_cashier_id, p_cash_register_id, v_total, p_payment_method, p_cash_amount, p_transfer_amount, v_change,
    p_receipt_photo_url, v_global_discount, v_authorized
  )
  RETURNING * INTO v_sale;

  -- ── Bucle 2: ítems, stock y auditoría ──────────────────────
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_product_id    := (v_item->>'product_id')::UUID;
    v_quantity      := (v_item->>'quantity')::INTEGER;
    v_unit_price    := (v_item->>'unit_price')::NUMERIC;
    v_item_discount := COALESCE((v_item->>'discount')::NUMERIC, 0);

    INSERT INTO public.sale_items (
      sale_id, product_id, product_name, quantity, unit_price, subtotal, discount_amount
    )
    VALUES (
      v_sale.id, v_product_id, v_item->>'product_name', v_quantity, v_unit_price,
      v_quantity * v_unit_price, v_item_discount
    );

    UPDATE public.products
    SET stock = stock - v_quantity, updated_at = NOW()
    WHERE id = v_product_id;

    INSERT INTO public.stock_movements (
      product_id, movement_type, reason, quantity, previous_stock, new_stock, notes, user_id
    )
    SELECT
      v_product_id, 'salida', 'venta', v_quantity,
      stock + v_quantity, stock,
      'Venta #' || v_sale.id, v_cashier_id
    FROM public.products WHERE id = v_product_id;
  END LOOP;

  RETURN v_sale;
END;
$$;
