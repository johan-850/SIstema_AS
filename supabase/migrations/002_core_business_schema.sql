-- ============================================================
-- Abarrotería Pro — Migración 002: Esquema Core de Negocio
-- Tablas: productos, caja, ventas, inventario y gastos
-- ============================================================

-- ── 1. Productos ──────────────────────────────────────────────
CREATE TABLE public.products (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode      TEXT UNIQUE NOT NULL,
  name         TEXT NOT NULL,
  description  TEXT,
  category     TEXT NOT NULL,
  price        DECIMAL(10, 2) NOT NULL CHECK (price > 0),
  cost_price   DECIMAL(10, 2),
  stock        INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  min_stock    INTEGER NOT NULL DEFAULT 0 CHECK (min_stock >= 0),
  unit         TEXT NOT NULL,
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  image_url    TEXT,
  supplier     TEXT,
  created_by   UUID REFERENCES public.profiles(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 2. Categorías de Gasto ─────────────────────────────────────
CREATE TABLE public.expense_categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL UNIQUE,
  icon        TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE
);

-- ── 3. Cajas (Turnos) ──────────────────────────────────────────
CREATE TABLE public.cash_registers (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cashier_id      UUID NOT NULL REFERENCES public.profiles(id),
  opening_amount  DECIMAL(10, 2) NOT NULL,
  closing_amount  DECIMAL(10, 2),
  opening_time    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  closing_time    TIMESTAMPTZ,
  status          TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
  notes           TEXT
);

-- ── 4. Ventas ──────────────────────────────────────────────────
CREATE TABLE public.sales (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cashier_id        UUID NOT NULL REFERENCES public.profiles(id),
  cash_register_id  UUID NOT NULL REFERENCES public.cash_registers(id),
  total             DECIMAL(10, 2) NOT NULL,
  discount          DECIMAL(10, 2) DEFAULT 0,
  payment_method    TEXT NOT NULL CHECK (payment_method IN ('cash', 'transfer', 'mixed')),
  cash_received     DECIMAL(10, 2),
  change_given      DECIMAL(10, 2),
  status            TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'cancelled')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 5. Ítems de Venta ──────────────────────────────────────────
CREATE TABLE public.sale_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id     UUID NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
  product_id  UUID NOT NULL REFERENCES public.products(id),
  quantity    INTEGER NOT NULL CHECK (quantity > 0),
  unit_price  DECIMAL(10, 2) NOT NULL,
  discount    DECIMAL(10, 2) DEFAULT 0,
  subtotal    DECIMAL(10, 2) NOT NULL
);

-- ── 6. Movimientos de Efectivo ─────────────────────────────────
CREATE TABLE public.cash_movements (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cash_register_id  UUID NOT NULL REFERENCES public.cash_registers(id),
  type              TEXT NOT NULL CHECK (type IN ('opening', 'sale', 'expense', 'closing')),
  amount            DECIMAL(10, 2) NOT NULL,
  description       TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 7. Gastos ──────────────────────────────────────────────────
CREATE TABLE public.expenses (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cash_register_id  UUID NOT NULL REFERENCES public.cash_registers(id),
  cashier_id        UUID NOT NULL REFERENCES public.profiles(id),
  amount            DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  category          TEXT NOT NULL,
  description       TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 8. Movimientos de Stock ────────────────────────────────────
CREATE TABLE public.stock_movements (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id  UUID NOT NULL REFERENCES public.products(id),
  type        TEXT NOT NULL CHECK (type IN ('sale', 'adjustment', 'return', 'reception')),
  quantity    INTEGER NOT NULL, -- Positivo (entrada) o negativo (salida)
  notes       TEXT,
  user_id     UUID NOT NULL REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 9. Cuadres Diarios ─────────────────────────────────────────
CREATE TABLE public.daily_closings (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cash_register_id  UUID NOT NULL REFERENCES public.cash_registers(id),
  expected_cash     DECIMAL(10, 2) NOT NULL,
  counted_cash      DECIMAL(10, 2) NOT NULL,
  difference        DECIMAL(10, 2) NOT NULL,
  total_sales       DECIMAL(10, 2) NOT NULL,
  total_expenses    DECIMAL(10, 2) NOT NULL,
  cashier_comment   TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Triggers de actualización ──────────────────────────────────
-- Actualizar `updated_at` de productos
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_products_updated_at
BEFORE UPDATE ON public.products
FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at_column();

-- Trigger: Descontar stock al confirmar venta
CREATE OR REPLACE FUNCTION public.handle_sale_stock_deduction()
RETURNS TRIGGER AS $$
DECLARE
  v_cashier_id UUID;
BEGIN
  -- Obtener el cajero que hizo la venta
  SELECT cashier_id INTO v_cashier_id FROM public.sales WHERE id = NEW.sale_id;

  -- Insertar movimiento de stock negativo
  INSERT INTO public.stock_movements (product_id, type, quantity, notes, user_id)
  VALUES (NEW.product_id, 'sale', -NEW.quantity, 'Venta generada (Automático)', v_cashier_id);
  
  -- Actualizar inventario en tabla products
  -- El constraint CHECK (stock >= 0) de la tabla evitará que el stock quede en negativo si se intenta vender sin stock
  UPDATE public.products
  SET stock = stock - NEW.quantity
  WHERE id = NEW.product_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_sale_item_insert
AFTER INSERT ON public.sale_items
FOR EACH ROW EXECUTE PROCEDURE public.handle_sale_stock_deduction();

-- ── RLS (Row Level Security) Básica ────────────────────────────
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_registers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_closings ENABLE ROW LEVEL SECURITY;

-- Políticas de Lectura (Generalmente todo autenticado o admin)
CREATE POLICY "authenticated_read_products" ON public.products FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_read_expense_categories" ON public.expense_categories FOR SELECT TO authenticated USING (true);

-- Cajeros solo ven su caja activa, Admin ve todo
CREATE POLICY "cashier_read_own_register" ON public.cash_registers FOR SELECT TO authenticated
USING (auth.uid() = cashier_id OR (auth.jwt() -> 'app_metadata' ->> 'role' = 'adminmaster'));

-- Políticas de Lectura de Transacciones
CREATE POLICY "read_sales" ON public.sales FOR SELECT TO authenticated USING (auth.uid() = cashier_id OR (auth.jwt() -> 'app_metadata' ->> 'role' = 'adminmaster'));
CREATE POLICY "read_sale_items" ON public.sale_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "read_cash_movements" ON public.cash_movements FOR SELECT TO authenticated USING (true);
CREATE POLICY "read_expenses" ON public.expenses FOR SELECT TO authenticated USING (auth.uid() = cashier_id OR (auth.jwt() -> 'app_metadata' ->> 'role' = 'adminmaster'));
CREATE POLICY "read_stock_movements" ON public.stock_movements FOR SELECT TO authenticated USING (true);
CREATE POLICY "read_daily_closings" ON public.daily_closings FOR SELECT TO authenticated USING (true);

-- Políticas de Escritura para AdminMaster
CREATE POLICY "admin_all_products" ON public.products FOR ALL TO authenticated USING ((auth.jwt() -> 'app_metadata' ->> 'role' = 'adminmaster'));
CREATE POLICY "admin_all_expense_categories" ON public.expense_categories FOR ALL TO authenticated USING ((auth.jwt() -> 'app_metadata' ->> 'role' = 'adminmaster'));
CREATE POLICY "admin_all_stock_movements" ON public.stock_movements FOR ALL TO authenticated USING ((auth.jwt() -> 'app_metadata' ->> 'role' = 'adminmaster'));

-- Políticas de Escritura para Cajeros (solo Insert en tablas operativas)
CREATE POLICY "cashier_insert_sales" ON public.sales FOR INSERT TO authenticated WITH CHECK (auth.uid() = cashier_id);
CREATE POLICY "cashier_insert_sale_items" ON public.sale_items FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "cashier_insert_cash_registers" ON public.cash_registers FOR INSERT TO authenticated WITH CHECK (auth.uid() = cashier_id);
CREATE POLICY "cashier_update_cash_registers" ON public.cash_registers FOR UPDATE TO authenticated USING (auth.uid() = cashier_id);
CREATE POLICY "cashier_insert_expenses" ON public.expenses FOR INSERT TO authenticated WITH CHECK (auth.uid() = cashier_id);
CREATE POLICY "cashier_insert_cash_movements" ON public.cash_movements FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "cashier_insert_daily_closings" ON public.daily_closings FOR INSERT TO authenticated WITH CHECK (true);
