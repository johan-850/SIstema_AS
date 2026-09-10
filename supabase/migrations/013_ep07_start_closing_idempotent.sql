-- ============================================================
-- Abarrotería Pro — Migración 013: iniciar el cierre es idempotente
-- Complementa el arreglo del cierre a medias (EP-07)
--
-- Opcional: el arreglo de fondo está en la app. Esto solo quita un
-- callejón sin salida cuando se pierde la respuesta del servidor.
-- ============================================================

-- El problema: start_register_closing() exigía status = 'open' y
-- lanzaba 'Esta caja ya no está abierta' con cualquier otra cosa. Si el
-- UPDATE se confirmaba pero la respuesta no llegaba al celular —cosa
-- normal con mala señal en una tienda— el cajero reintentaba y recibía
-- ese error para siempre: la caja ya estaba en 'closing'.
--
-- Pedir "inicia el cierre" sobre una caja que ya está cerrándose no es
-- un error: el estado que se pide ya es el que hay. Se devuelve la caja
-- tal cual y el cajero sigue al conteo.
--
-- Cerrada sí sigue siendo error: ahí ya no hay cuadre que hacer.
--
-- Misma firma que la 008, así que reemplaza — no crea una sobrecarga.
CREATE OR REPLACE FUNCTION public.start_register_closing(p_register_id UUID)
RETURNS public.cash_registers
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_register public.cash_registers;
BEGIN
  SELECT * INTO v_register
  FROM public.cash_registers
  WHERE id = p_register_id AND cashier_id = auth.uid()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Caja no encontrada';
  END IF;

  -- Ya estaba cerrándose: no hay nada que cambiar, se devuelve igual.
  IF v_register.status = 'closing' THEN
    RETURN v_register;
  END IF;

  IF v_register.status != 'open' THEN
    RAISE EXCEPTION 'Esta caja ya fue cerrada';
  END IF;

  UPDATE public.cash_registers
  SET status = 'closing', updated_at = NOW()
  WHERE id = p_register_id
  RETURNING * INTO v_register;

  RETURN v_register;
END;
$$;

COMMENT ON FUNCTION public.start_register_closing(UUID) IS
  'Pasa la caja a closing y bloquea ventas y gastos. Idempotente: sobre una caja ya en closing devuelve la fila sin tocarla, para que una respuesta perdida no deje al cajero sin poder cuadrar — EP-07';
