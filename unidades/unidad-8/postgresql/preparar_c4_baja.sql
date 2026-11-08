-- Food Store — Unidad 8 — Preparación del escenario C4 (bloque D).
-- Baja lógica SOLO de '[U8 prueba] Base C4 baja': eliminado false → true.
-- Preparación deliberada del servidor de pruebas, separada de la simulación.
-- Falla y revierte si no modifica exactamente una fila con el estado esperado.
\set ON_ERROR_STOP on
BEGIN;

SELECT 'antes' AS momento, id, nombre, precio, stock, disponible, eliminado
FROM producto WHERE nombre = '[U8 prueba] Base C4 baja';

DO $$
DECLARE
    filas integer;
BEGIN
    UPDATE producto SET eliminado = true
    WHERE id = 6
      AND nombre = '[U8 prueba] Base C4 baja'
      AND precio = 700.00 AND stock = 15 AND disponible AND NOT eliminado;
    GET DIAGNOSTICS filas = ROW_COUNT;
    IF filas <> 1 THEN
        RAISE EXCEPTION 'C4: se esperaba modificar exactamente 1 fila; modificadas: %', filas;
    END IF;
END;
$$;

SELECT 'despues' AS momento, id, nombre, precio, stock, disponible, eliminado
FROM producto WHERE nombre = '[U8 prueba] Base C4 baja';

COMMIT;
