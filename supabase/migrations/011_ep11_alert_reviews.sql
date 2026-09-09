-- ============================================================
-- Abarrotería Pro — Migración 011: Centro de alertas (US-061)
-- Ejecuta en Supabase SQL Editor (proyecto conectado)
-- ============================================================

-- ── Tabla: alert_reviews ──────────────────────────────────────
-- Las alertas del centro NO se guardan: se derivan de consultar
-- products, cash_registers y expenses. Lo único que hace falta
-- persistir es cuáles ya revisó el AdminMaster, y eso tiene que
-- sobrevivir a que cambie de dispositivo.
--
-- La clave es (alert_type, alert_key), donde alert_key es el id de la
-- fila que originó la alerta: product_id, cash_register_id o expense_id.
CREATE TABLE IF NOT EXISTS public.alert_reviews (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type    TEXT NOT NULL CHECK (alert_type IN ('stock', 'cuadre', 'gasto')),
  alert_key     TEXT NOT NULL,
  context_value NUMERIC,
  reviewed_by   UUID REFERENCES public.profiles(id),
  reviewed_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (alert_type, alert_key)
);

COMMENT ON TABLE public.alert_reviews IS 'Alertas del centro que el AdminMaster ya revisó. Las alertas en sí son derivadas, no se guardan — US-061';
COMMENT ON COLUMN public.alert_reviews.alert_key IS 'id de la fila que originó la alerta: product_id, cash_register_id o expense_id';
COMMENT ON COLUMN public.alert_reviews.context_value IS 'Solo para stock: existencia al momento de revisar. La alerta reaparece si el stock baja de este valor — un cuadre o un gasto no cambian, pero el stock sí';

CREATE INDEX IF NOT EXISTS idx_alert_reviews_type_key ON public.alert_reviews(alert_type, alert_key);

-- ── Row Level Security ────────────────────────────────────────
-- Solo el AdminMaster: el centro de alertas es una pantalla suya.
-- Mismo patrón que admin_full_access_restock_requests (003:57-65).
ALTER TABLE public.alert_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_full_access_alert_reviews" ON public.alert_reviews;
CREATE POLICY "admin_full_access_alert_reviews"
  ON public.alert_reviews FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'adminmaster')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'adminmaster')
  );
