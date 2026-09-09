-- ============================================================
-- Reparación de datos — cajas huérfanas del bug del turno activo (EP-07)
-- NO es una migración: arregla filas, no el esquema. Por eso vive fuera
-- de migrations/ — en una base nueva no hay nada que reparar.
--
-- Diagnóstico del 2026-09-09: el cajero "johan" tenía 7 cajas sin cerrar.
-- ============================================================

-- ── PASO 1: mirar antes de tocar ─────────────────────────────
-- Corre esto solo. Si alguna de estas cajas es el turno que estás
-- trabajando AHORA, anota su id y exclúyela en el paso 2.
--
-- SELECT cr.id, cr.status,
--        cr.opening_time AT TIME ZONE 'America/Bogota' AS abierta,
--        cr.opening_amount,
--        (SELECT COUNT(*) FROM public.sales    s WHERE s.cash_register_id = cr.id) AS ventas,
--        (SELECT COUNT(*) FROM public.expenses e WHERE e.cash_register_id = cr.id) AS gastos
-- FROM public.cash_registers cr
-- WHERE cr.status IN ('open', 'closing')
-- ORDER BY cr.opening_time;

-- ── PASO 2: cerrarlas con el cuadre real ─────────────────────
-- No borra nada: las ventas y los gastos siguen colgando de su caja y
-- el historial queda completo. Calcula el mismo cuadre que hace
-- close_register(), así que el admin ve estos turnos igual que los
-- cerrados a mano.
--
-- Sobre el efectivo contado: estos turnos nunca se contaron, y ese
-- dinero hace días que se mezcló con los turnos siguientes. Inventar
-- una diferencia sería peor que no tenerla, así que se registra
-- contado = esperado (diferencia 0) y la nota lo dice explícitamente,
-- para que nadie lea después un "cuadró perfecto" que nunca ocurrió.
--
-- Diferencia 0 además evita que el centro de alertas (US-061) llene la
-- pantalla del admin con avisos de descuadre inventados.

WITH agg AS (
  SELECT
    cr.id,
    cr.opening_amount,
    COALESCE((SELECT SUM(s.total) FROM public.sales s
               WHERE s.cash_register_id = cr.id AND s.payment_method = 'efectivo'), 0)      AS v_efectivo,
    COALESCE((SELECT SUM(s.cash_amount) FROM public.sales s
               WHERE s.cash_register_id = cr.id AND s.payment_method = 'mixto'), 0)         AS v_mixto_efec,
    COALESCE((SELECT SUM(s.total) FROM public.sales s
               WHERE s.cash_register_id = cr.id AND s.payment_method = 'transferencia'), 0) AS v_transf,
    COALESCE((SELECT SUM(s.total) FROM public.sales s
               WHERE s.cash_register_id = cr.id), 0)                                        AS v_total,
    (SELECT COUNT(*) FROM public.sales s WHERE s.cash_register_id = cr.id)                  AS n_tx,
    COALESCE((SELECT SUM(e.amount) FROM public.expenses e
               WHERE e.cash_register_id = cr.id), 0)                                        AS g_total
  FROM public.cash_registers cr
  WHERE cr.status IN ('open', 'closing')
  -- Si estás trabajando un turno de verdad, exclúyelo:
  -- AND cr.id <> '<pega-aqui-el-id>'
)
UPDATE public.cash_registers cr
SET
  status         = 'closed',
  closing_time   = NOW(),
  closing_amount = a.opening_amount + a.v_efectivo + a.v_mixto_efec - a.g_total,
  closing_notes  = 'Cerrada administrativamente: turno huerfano por el bug del turno activo (EP-07). Nunca hubo conteo fisico; el efectivo contado se registro igual al esperado.',
  closing_summary = jsonb_build_object(
    'opening_amount',       a.opening_amount,
    'sales_efectivo',       a.v_efectivo,
    'sales_mixto_efectivo', a.v_mixto_efec,
    'sales_transferencia',  a.v_transf,
    'sales_total',          a.v_total,
    'transaction_count',    a.n_tx,
    'total_expenses',       a.g_total,
    'expected_cash',        a.opening_amount + a.v_efectivo + a.v_mixto_efec - a.g_total,
    'counted_cash',         a.opening_amount + a.v_efectivo + a.v_mixto_efec - a.g_total,
    'difference',           0
  ),
  updated_at = NOW()
FROM agg a
WHERE cr.id = a.id;

-- ── PASO 3: comprobar ────────────────────────────────────────
-- Debe devolver 0 filas.
--
-- SELECT COUNT(*) FROM public.cash_registers WHERE status IN ('open','closing');
