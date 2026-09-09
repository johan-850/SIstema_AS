-- ============================================================
-- Abarrotería Pro — Migración 012: una sola caja sin cerrar por cajero
-- Corrige el bug del "turno activo" (EP-07)
--
--   *** NO CORRAS ESTE ARCHIVO DE UNA. LEE EL PASO 1 PRIMERO. ***
--
-- El índice del paso 2 FALLA si ya existen cajas duplicadas, que es
-- justamente lo que este bug venía produciendo. Primero hay que ver
-- qué hay y resolverlo.
-- ============================================================

-- ── PASO 1: diagnóstico (corre solo esto primero) ─────────────
-- Muestra las cajas sin cerrar, con cuántas ventas y gastos cuelgan de
-- cada una. Si algún cajero aparece con más de una fila, hay duplicados
-- que resolver antes de seguir.
--
-- SELECT
--   p.name                        AS cajero,
--   cr.id,
--   cr.status,
--   cr.opening_time AT TIME ZONE 'America/Bogota' AS apertura_local,
--   cr.opening_amount,
--   (SELECT COUNT(*) FROM public.sales    s WHERE s.cash_register_id = cr.id) AS ventas,
--   (SELECT COUNT(*) FROM public.expenses e WHERE e.cash_register_id = cr.id) AS gastos,
--   COUNT(*) OVER (PARTITION BY cr.cashier_id) AS cajas_sin_cerrar_del_cajero
-- FROM public.cash_registers cr
-- JOIN public.profiles p ON p.id = cr.cashier_id
-- WHERE cr.status IN ('open', 'closing')
-- ORDER BY cajero, cr.opening_time;

-- ── Cómo resolver los duplicados ──────────────────────────────
-- NO borres filas: las ventas y los gastos apuntan a la caja por clave
-- foránea, así que borrarla rompería el historial (y el arqueo de ese
-- turno dejaría de existir).
--
-- Para cada cajero deja UNA sola caja sin cerrar — normalmente la más
-- reciente, la que de verdad está usando. Las demás ciérralas:
--
--   a) Si tiene ventas, lo correcto es cerrarla desde la app: el
--      asistente de cierre calcula el cuadre real contra sus ventas y
--      gastos. Con el arreglo de esta versión, la app ya te deja
--      retomar una caja vieja o a medio cerrar.
--
--   b) Si está vacía (0 ventas y 0 gastos), fue una apertura fantasma
--      del bug y se puede cerrar a mano dejando constancia:
--
--      UPDATE public.cash_registers
--      SET status = 'closed',
--          closing_time = NOW(),
--          closing_amount = opening_amount,
--          closing_notes = 'Cerrada administrativamente: apertura duplicada por el bug del turno activo (EP-07)',
--          updated_at = NOW()
--      WHERE id = '<pega-el-id-aqui>';

-- ── PASO 2: el índice (solo cuando el paso 1 ya no muestre duplicados) ──
-- Esta es la garantía real: a partir de acá la base misma impide que un
-- cajero tenga dos cajas sin cerrar, pase lo que pase en la app.
CREATE UNIQUE INDEX IF NOT EXISTS idx_cash_registers_one_open_per_cashier
  ON public.cash_registers (cashier_id)
  WHERE status IN ('open', 'closing');

COMMENT ON INDEX public.idx_cash_registers_one_open_per_cashier IS
  'Un cajero no puede tener dos cajas sin cerrar a la vez. Antes nada lo impedía y el filtro de fecha en UTC generaba aperturas duplicadas — EP-07';
