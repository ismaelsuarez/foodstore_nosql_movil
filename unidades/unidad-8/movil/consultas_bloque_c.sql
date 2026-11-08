.bail on
.headers off
.mode list
.separator ' | '
-- Food Store — Unidad 8 — Pruebas b/c/f del bloque C.
-- Son grupos de verificación, NO los casos C1–C7 de la consigna.
-- sqlite3 -readonly <db> < consultas_bloque_c.sql, desde el directorio del CSV.
-- Solo se crean objetos TEMP: la base entregable permanece de solo lectura.
PRAGMA foreign_keys = ON;
SELECT 'C-F-01', 'foreign_keys activo', 1, foreign_keys,
       iif(foreign_keys = 1, 'OK', 'FALLA') FROM pragma_foreign_keys;

CREATE TEMP TABLE csv_original (
    producto_id TEXT NOT NULL,
    nombre TEXT NOT NULL,
    precio_centavos TEXT NOT NULL,
    stock TEXT NOT NULL,
    disponible TEXT NOT NULL,
    eliminado TEXT NOT NULL,
    capturado_en TEXT NOT NULL
) STRICT;
.import --csv --skip 1 --schema temp servidor_snapshot.csv csv_original

-- Comparar las siete columnas como texto evita conversiones numéricas
-- implícitas que podrían esconder diferencias respecto del archivo original.
CREATE TEMP VIEW csv_texto AS
SELECT CAST(producto_id AS TEXT) AS producto_id, CAST(nombre AS TEXT) AS nombre,
       CAST(precio_centavos AS TEXT) AS precio_centavos, CAST(stock AS TEXT) AS stock,
       CAST(disponible AS TEXT) AS disponible, CAST(eliminado AS TEXT) AS eliminado,
       CAST(capturado_en AS TEXT) AS capturado_en FROM csv_original;
CREATE TEMP VIEW snapshot_texto AS
SELECT CAST(producto_id AS TEXT) AS producto_id, CAST(nombre AS TEXT) AS nombre,
       CAST(precio_centavos AS TEXT) AS precio_centavos, CAST(stock AS TEXT) AS stock,
       CAST(disponible AS TEXT) AS disponible, CAST(eliminado AS TEXT) AS eliminado,
       CAST(capturado_en AS TEXT) AS capturado_en FROM snapshot_servidor;
CREATE TEMP VIEW cache_texto AS
SELECT CAST(producto_id AS TEXT) AS producto_id, CAST(nombre AS TEXT) AS nombre,
       CAST(precio_centavos AS TEXT) AS precio_centavos, CAST(stock_visto AS TEXT) AS stock,
       CAST(CASE disponible_visto WHEN 1 THEN 't' WHEN 0 THEN 'f' END AS TEXT) AS disponible,
       CAST(CASE eliminado WHEN 1 THEN 't' WHEN 0 THEN 'f' END AS TEXT) AS eliminado,
       CAST(capturado_en AS TEXT) AS capturado_en FROM producto_cache;

.print '== b: correspondencia con CSV'
SELECT 'C-B-01', 'filas CSV original', 9, n, iif(n = 9, 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM csv_original);
SELECT 'C-B-02', 'filas snapshot iguales al CSV y a nueve', 9, n,
       iif(n = 9 AND n = (SELECT count(*) FROM csv_original), 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM snapshot_servidor);
SELECT 'C-B-03', 'diferencias CSV/snapshot en ambas direcciones', 0, n,
       iif(n = 0, 'OK', 'FALLA')
FROM (SELECT (SELECT count(*) FROM (SELECT * FROM csv_texto EXCEPT SELECT * FROM snapshot_texto))
           + (SELECT count(*) FROM (SELECT * FROM snapshot_texto EXCEPT SELECT * FROM csv_texto)) AS n);
SELECT 'C-B-04', 'diferencias CSV/cache reconvertido en ambas direcciones', 0, n,
       iif(n = 0, 'OK', 'FALLA')
FROM (SELECT (SELECT count(*) FROM (SELECT * FROM csv_texto EXCEPT SELECT * FROM cache_texto))
           + (SELECT count(*) FROM (SELECT * FROM cache_texto EXCEPT SELECT * FROM csv_texto)) AS n);
SELECT 'C-B-05', 'una misma captura en CSV, snapshot y cache', 1, n,
       iif(n = 1, 'OK', 'FALLA')
FROM (SELECT count(DISTINCT capturado_en) AS n FROM (
    SELECT capturado_en FROM csv_original UNION ALL
    SELECT capturado_en FROM snapshot_servidor UNION ALL
    SELECT capturado_en FROM producto_cache
));
SELECT 'C-B-06', 'filas cache iguales al CSV y a nueve', 9, n,
       iif(n = 9 AND n = (SELECT count(*) FROM csv_original), 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM producto_cache);

.print '== c: catalogo y lapidas'
SELECT 'C-C-01', 'ids disponibles ordenados', '1,2,3,4,5,6,7', ids,
       iif(ids = '1,2,3,4,5,6,7', 'OK', 'FALLA')
FROM (SELECT group_concat(producto_id, ',') AS ids
      FROM (SELECT producto_id FROM v_catalogo_disponible ORDER BY producto_id));
.print 'producto_id | nombre | precio | stock_visto'
SELECT * FROM v_catalogo_disponible ORDER BY producto_id;
SELECT 'C-C-02', 'producto 9 conserva lapida y no aparece en vista', 1, n,
       iif(n = 1 AND NOT EXISTS (SELECT 1 FROM v_catalogo_disponible WHERE producto_id = 9), 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM producto_cache WHERE producto_id = 9 AND eliminado = 1);
SELECT 'C-C-03', 'producto 8 no disponible y ausente en vista', 1, n,
       iif(n = 1 AND NOT EXISTS (SELECT 1 FROM v_catalogo_disponible WHERE producto_id = 8), 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM producto_cache WHERE producto_id = 8 AND disponible_visto = 0);

.print '== f: integridad, fixture ausente y tablas vacias'
SELECT 'C-F-02', 'pedido_borrador vacio', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM pedido_borrador);
SELECT 'C-F-03', 'item_borrador vacio', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM item_borrador);
SELECT 'C-F-04', 'cola_sync vacia', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM cola_sync);
SELECT 'C-F-05', 'fixture B ausente de cache y snapshot', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM (
    SELECT producto_id, nombre, capturado_en FROM producto_cache UNION ALL
    SELECT producto_id, nombre, capturado_en FROM snapshot_servidor
) WHERE producto_id IN (9101, 9102, 9103, 9104, 9999)
     OR capturado_en = 'fixture-no-extraido' OR nombre LIKE '%(fixture)%');
SELECT 'C-F-06', 'integrity_check', 'ok', resultado,
       iif(resultado = 'ok', 'OK', 'FALLA')
FROM (SELECT group_concat(integrity_check, ';') AS resultado FROM pragma_integrity_check);
SELECT 'C-F-07', 'foreign_key_check sin infracciones', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM pragma_foreign_key_check);
SELECT 'C-F-08', 'cinco tablas main STRICT', 5, n, iif(n = 5, 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM pragma_table_list
      WHERE schema = 'main' AND type = 'table' AND strict = 1
        AND name IN ('producto_cache', 'pedido_borrador', 'item_borrador', 'cola_sync', 'snapshot_servidor'));
