-- Food Store — Unidad 8: comprobaciones de solo lectura, sin datos de usuarios.
\set ON_ERROR_STOP on
BEGIN READ ONLY;

\echo 'Conteos del modelo (esperados: 3, 3, 9, 5, 7 respectivamente)'
SELECT 'categoria' AS tabla, count(*) AS filas FROM categoria
UNION ALL SELECT 'usuario', count(*) FROM usuario
UNION ALL SELECT 'producto', count(*) FROM producto
UNION ALL SELECT 'pedido', count(*) FROM pedido
UNION ALL SELECT 'detalle_pedido', count(*) FROM detalle_pedido;

\echo 'Productos seed (3), auxiliares U8 (6) y otros (0)'
SELECT count(*) FILTER (
           WHERE nombre IN ('Muzzarella', 'Napolitana', 'Coca 1.5L')
       ) AS productos_seed,
       count(*) FILTER (WHERE nombre LIKE '[U8 prueba]%') AS productos_u8,
       count(*) FILTER (
           WHERE nombre NOT IN ('Muzzarella', 'Napolitana', 'Coca 1.5L')
             AND nombre NOT LIKE '[U8 prueba]%'
       ) AS productos_otros
FROM producto;

\echo 'Presencia de seis funciones y un procedimiento (presente=t)'
WITH esperados(firma, tipo) AS (VALUES
    ('public.calcular_total_pedido(bigint)', 'f'),
    ('public.fn_set_subtotal()', 'f'),
    ('public.fn_validar_detalle_vigente()', 'f'),
    ('public.fn_recalcular_total_insert()', 'f'),
    ('public.fn_recalcular_total_update()', 'f'),
    ('public.fn_recalcular_total_delete()', 'f'),
    ('public.registrar_detalle_pedido(bigint,bigint,integer)', 'p')
)
SELECT e.firma, e.tipo, p.oid IS NOT NULL AS presente
FROM esperados e
LEFT JOIN pg_proc p ON p.oid = to_regprocedure(e.firma)
                       AND p.prokind::text = e.tipo
ORDER BY e.tipo, e.firma;

\echo 'Presencia de cinco triggers en detalle_pedido (presente=t, habilitado=O)'
WITH esperados(nombre) AS (VALUES
    ('trg_subtotal'), ('trg_detalle_vigente'),
    ('trg_total_detalle_insert'), ('trg_total_detalle_update'),
    ('trg_total_detalle_delete')
)
SELECT e.nombre, t.oid IS NOT NULL AS presente, t.tgenabled AS habilitado
FROM esperados e
LEFT JOIN pg_trigger t ON t.tgname = e.nombre
    AND t.tgrelid = 'public.detalle_pedido'::regclass AND NOT t.tgisinternal
ORDER BY e.nombre;

\echo 'Catálogo completo: IDs reales asignados por PostgreSQL'
SELECT p.id, p.nombre, p.precio, p.stock, p.disponible, p.eliminado,
       c.nombre AS categoria
FROM producto p JOIN categoria c ON c.id = p.categoria_id
ORDER BY p.id;

\echo 'Instantánea: incluye no disponibles y bajas iniciales'
SELECT producto_id, nombre, precio_centavos, stock, disponible, eliminado
FROM v_snapshot_movil
ORDER BY producto_id;

COMMIT;
