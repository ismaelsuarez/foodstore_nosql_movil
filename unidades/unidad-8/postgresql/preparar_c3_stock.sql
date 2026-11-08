-- Food Store — Unidad 8 — Preparación del escenario C3 (bloque D).
-- Cambia SOLO el stock de '[U8 prueba] Base C3 stock': 10 → 2.
-- Preparación deliberada del servidor de pruebas, separada de la simulación.
-- No representa una venta: no crea pedidos ni invoca registrar_detalle_pedido.
-- Falla y revierte si no modifica exactamente una fila con el estado esperado.
\set ON_ERROR_STOP on
BEGIN;

SELECT 'antes' AS momento, id, nombre, precio, stock, disponible, eliminado
FROM producto WHERE nombre = '[U8 prueba] Base C3 stock';

DO $$
DECLARE
    filas integer;
BEGIN
    UPDATE producto SET stock = 2
    WHERE id = 5
      AND nombre = '[U8 prueba] Base C3 stock'
      AND precio = 900.00 AND stock = 10 AND disponible AND NOT eliminado;
    GET DIAGNOSTICS filas = ROW_COUNT;
    IF filas <> 1 THEN
        RAISE EXCEPTION 'C3: se esperaba modificar exactamente 1 fila; modificadas: %', filas;
    END IF;
END;
$$;

SELECT 'despues' AS momento, id, nombre, precio, stock, disponible, eliminado
FROM producto WHERE nombre = '[U8 prueba] Base C3 stock';

COMMIT;
