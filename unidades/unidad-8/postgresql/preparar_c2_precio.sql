-- Food Store — Unidad 8 — Preparación del escenario C2 (bloque D).
-- Cambia SOLO el precio de '[U8 prueba] Base C2 precio': 1200.00 → 1320.00.
-- Preparación deliberada del servidor de pruebas, separada de la simulación.
-- Falla y revierte si no modifica exactamente una fila con el estado esperado.
\set ON_ERROR_STOP on
BEGIN;

SELECT 'antes' AS momento, id, nombre, precio, stock, disponible, eliminado
FROM producto WHERE nombre = '[U8 prueba] Base C2 precio';

DO $$
DECLARE
    filas integer;
BEGIN
    UPDATE producto SET precio = 1320.00
    WHERE id = 4
      AND nombre = '[U8 prueba] Base C2 precio'
      AND precio = 1200.00 AND stock = 20 AND disponible AND NOT eliminado;
    GET DIAGNOSTICS filas = ROW_COUNT;
    IF filas <> 1 THEN
        RAISE EXCEPTION 'C2: se esperaba modificar exactamente 1 fila; modificadas: %', filas;
    END IF;
END;
$$;

SELECT 'despues' AS momento, id, nombre, precio, stock, disponible, eliminado
FROM producto WHERE nombre = '[U8 prueba] Base C2 precio';

COMMIT;
