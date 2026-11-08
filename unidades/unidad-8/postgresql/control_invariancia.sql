-- Food Store — Unidad 8 — Lectura de control antes/después de cada simulación.
-- Solo lectura. Salida estable y sin marcas de tiempo para compararla byte a
-- byte. No incluye datos de usuarios.
\set ON_ERROR_STOP on
BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;

SELECT 'producto', id, precio, stock, disponible, eliminado
FROM producto ORDER BY id;

SELECT 'pedidos', count(*), coalesce(sum(total), 0) FROM pedido;
SELECT 'detalle_pedido', count(*), coalesce(sum(cantidad), 0) FROM detalle_pedido;

COMMIT;
