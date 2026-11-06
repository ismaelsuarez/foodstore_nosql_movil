-- Food Store U7 — Consultas equivalentes a C4b y C4c (consigna 5).
-- Solo lectura: REPEATABLE READ, READ ONLY y ROLLBACK final.
-- Mismo lote y mismas condiciones que consultas_mongodb.js (design.md §7).
-- Uso (Bash, desde la raíz del repositorio):
--   docker exec -i foodstore-u6-evaluacion \
--     psql -X -w -U postgres -d foodstore -v ON_ERROR_STOP=1 -P pager=off -f - \
--     < unidades/unidad-7/postgresql/consultas_postgresql.sql

\set ON_ERROR_STOP on

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY;

-- C4b: lote + pedido no eliminado + estado TERMINADO.
SELECT 'C4b' AS consulta,
       count(*) AS cantidad,
       string_agg(p.id::text, ',' ORDER BY p.id) AS pedidos
FROM pedido p
WHERE p.id IN (1, 2, 3, 4, 5)
  AND p.eliminado = FALSE
  AND p.estado = 'TERMINADO';

-- C4c: lote + pedido no eliminado + una misma línea con producto 1 no
-- eliminada. EXISTS cuenta cada pedido una sola vez, aunque tuviera
-- varias líneas que cumplan la condición.
SELECT 'C4c' AS consulta,
       count(*) AS cantidad,
       string_agg(p.id::text, ',' ORDER BY p.id) AS pedidos
FROM pedido p
WHERE p.id IN (1, 2, 3, 4, 5)
  AND p.eliminado = FALSE
  AND EXISTS (
      SELECT 1
      FROM detalle_pedido dp
      WHERE dp.pedido_id = p.id
        AND dp.producto_id = 1
        AND dp.eliminado = FALSE);

ROLLBACK;
