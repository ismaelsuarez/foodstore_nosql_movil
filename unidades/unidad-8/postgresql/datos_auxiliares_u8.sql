-- Food Store — Unidad 8: catálogo sintético separado del seed canónico.
-- Solo estado INICIAL: el bloque D cambiará los productos C2/C3/C4.
-- No se crean pedidos ni se invoca registrar_detalle_pedido.
BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM categoria WHERE nombre = 'Pizzas')
       OR NOT EXISTS (SELECT 1 FROM categoria WHERE nombre = 'Bebidas')
       OR (SELECT count(*) FROM producto
           WHERE nombre IN ('Muzzarella', 'Napolitana', 'Coca 1.5L')) <> 3 THEN
        RAISE EXCEPTION 'Debe instalarse primero el seed canónico de U6';
    END IF;
    IF EXISTS (SELECT 1 FROM categoria WHERE nombre LIKE '[U8 prueba]%')
       OR EXISTS (SELECT 1 FROM producto WHERE nombre LIKE '[U8 prueba]%') THEN
        RAISE EXCEPTION 'Ya existen categorías o productos auxiliares de U8';
    END IF;
END;
$$;

WITH categoria_auxiliar AS (
    INSERT INTO categoria (nombre, descripcion, eliminado)
    VALUES ('[U8 prueba] Catálogo de pruebas U8',
            'Datos sintéticos iniciales del laboratorio U8', false)
    RETURNING id
), productos_auxiliares AS (
    INSERT INTO producto
        (categoria_id, nombre, precio, stock, disponible, eliminado)
    SELECT c.id, v.nombre, v.precio, v.stock, v.disponible, v.eliminado
    FROM categoria_auxiliar c
    CROSS JOIN (VALUES
        ('[U8 prueba] Base C2 precio',        1200.00, 20, true,  false),
        ('[U8 prueba] Base C3 stock',          900.00, 10, true,  false),
        ('[U8 prueba] Base C4 baja',           700.00, 15, true,  false),
        ('[U8 prueba] Base C5 sin cambios',    500.00, 30, true,  false),
        ('[U8 prueba] No disponible inicial',  650.00,  8, false, false),
        ('[U8 prueba] Baja inicial',           450.00,  5, true,  true)
    ) AS v(nombre, precio, stock, disponible, eliminado)
    RETURNING id, nombre, precio, stock, disponible, eliminado
)
SELECT id, nombre, precio, stock, disponible, eliminado
FROM productos_auxiliares
ORDER BY id;

COMMIT;
