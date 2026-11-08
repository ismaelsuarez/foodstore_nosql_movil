-- Food Store — Unidad 8: stdout contiene solo CSV al ejecutar psql -X -q.
-- Los META van a stderr. REPEATABLE READ y now() comparten transacción.
\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
SET DateStyle = 'ISO, YMD';
BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;

SELECT count(*) AS filas,
       count(DISTINCT capturado_en) AS fechas,
       min(capturado_en) AS capturado_en,
       current_database() AS base,
       current_setting('server_version') AS version_servidor
FROM v_snapshot_movil
\gset

\warn META filas=:filas
\warn META fechas=:fechas
\warn META capturado_en=:capturado_en
\warn META base=:base
\warn META version_servidor=:version_servidor

COPY (
    SELECT producto_id, nombre, precio_centavos, stock,
           disponible, eliminado, capturado_en
    FROM v_snapshot_movil
    ORDER BY producto_id
) TO STDOUT WITH (FORMAT csv, HEADER true);

COMMIT;
