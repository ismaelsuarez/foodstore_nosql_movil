.bail on
.headers off
.mode list
.separator ' | '
-- Food Store — Unidad 8 — Renovación atómica de instantánea Y catálogo.
-- Ejecutar desde el directorio del CSV, con @filas_esperadas enlazado por -cmd.
-- Un error detiene el cliente ANTES del COMMIT; al cerrar, SQLite revierte
-- la transacción abierta. No usar .bail off ni confirmar pasos intermedios.
PRAGMA foreign_keys = ON;
CREATE TEMP TABLE control_renovacion (
    control TEXT NOT NULL,
    ok INTEGER NOT NULL CHECK (ok = 1)
) STRICT;

SELECT 'foreign_keys', iif(foreign_keys = 1, 'OK', 'FALLA')
FROM pragma_foreign_keys;
INSERT INTO control_renovacion
SELECT 'foreign_keys', foreign_keys = 1 FROM pragma_foreign_keys;

SELECT 'filas_esperadas',
       iif(typeof(@filas_esperadas) = 'integer' AND @filas_esperadas > 0, 'OK', 'FALLA');
INSERT INTO control_renovacion
VALUES ('filas_esperadas', coalesce(typeof(@filas_esperadas) = 'integer' AND @filas_esperadas > 0, 0));

BEGIN;
CREATE TEMP TABLE cache_antes AS SELECT * FROM producto_cache;
CREATE TEMP TABLE items_antes AS SELECT * FROM item_borrador;
CREATE TEMP TABLE cola_antes AS SELECT * FROM cola_sync;
DELETE FROM snapshot_servidor;
.import --csv --skip 1 servidor_snapshot.csv snapshot_servidor

SELECT 'filas_importadas', iif(count(*) = @filas_esperadas, 'OK', 'FALLA')
FROM snapshot_servidor;
INSERT INTO control_renovacion
SELECT 'filas_importadas', count(*) = @filas_esperadas FROM snapshot_servidor;

CREATE TEMP VIEW importacion_sin_nulos AS
SELECT count(*) = 0 AS ok FROM snapshot_servidor
WHERE producto_id IS NULL OR nombre IS NULL OR precio_centavos IS NULL
   OR stock IS NULL OR disponible IS NULL OR eliminado IS NULL OR capturado_en IS NULL;
SELECT 'sin_nulos', iif(ok, 'OK', 'FALLA') FROM importacion_sin_nulos;
INSERT INTO control_renovacion SELECT 'sin_nulos', ok FROM importacion_sin_nulos;

CREATE TEMP VIEW importacion_enteros AS
SELECT count(*) = 0 AS ok FROM snapshot_servidor
WHERE typeof(producto_id) <> 'integer' OR typeof(precio_centavos) <> 'integer'
   OR typeof(stock) <> 'integer';
SELECT 'tipos_enteros', iif(ok, 'OK', 'FALLA') FROM importacion_enteros;
INSERT INTO control_renovacion SELECT 'tipos_enteros', ok FROM importacion_enteros;

SELECT 'captura_unica', iif(count(DISTINCT capturado_en) = 1, 'OK', 'FALLA')
FROM snapshot_servidor;
INSERT INTO control_renovacion
SELECT 'captura_unica', count(DISTINCT capturado_en) = 1 FROM snapshot_servidor;

-- Único punto de conversión de booleanos. Nunca REPLACE ni DELETE del cache:
-- se conservan las lápidas y las referencias de los borradores.
INSERT INTO producto_cache
    (producto_id, nombre, precio_centavos, stock_visto, disponible_visto, eliminado, capturado_en)
SELECT producto_id, nombre, precio_centavos, stock,
       CASE disponible WHEN 't' THEN 1 WHEN 'f' THEN 0 END,
       CASE eliminado WHEN 't' THEN 1 WHEN 'f' THEN 0 END,
       capturado_en
FROM snapshot_servidor WHERE true
ON CONFLICT(producto_id) DO UPDATE SET
    nombre = excluded.nombre,
    precio_centavos = excluded.precio_centavos,
    stock_visto = excluded.stock_visto,
    disponible_visto = excluded.disponible_visto,
    eliminado = excluded.eliminado,
    capturado_en = excluded.capturado_en;

CREATE TEMP VIEW correspondencia_cache AS
SELECT count(*) = 0 AS ok FROM (
    SELECT producto_id, nombre, precio_centavos, stock,
           CASE disponible WHEN 't' THEN 1 WHEN 'f' THEN 0 END,
           CASE eliminado WHEN 't' THEN 1 WHEN 'f' THEN 0 END, capturado_en
    FROM snapshot_servidor
    EXCEPT
    SELECT producto_id, nombre, precio_centavos, stock_visto,
           disponible_visto, eliminado, capturado_en FROM producto_cache
);
SELECT 'correspondencia_cache', iif(ok, 'OK', 'FALLA') FROM correspondencia_cache;
INSERT INTO control_renovacion SELECT 'correspondencia_cache', ok FROM correspondencia_cache;

CREATE TEMP VIEW cache_ausente_antes AS
SELECT * FROM cache_antes WHERE producto_id NOT IN (SELECT producto_id FROM snapshot_servidor);
CREATE TEMP VIEW cache_ausente_despues AS
SELECT * FROM producto_cache WHERE producto_id NOT IN (SELECT producto_id FROM snapshot_servidor);
CREATE TEMP VIEW lapidas_conservadas AS
SELECT NOT EXISTS (SELECT * FROM cache_ausente_antes EXCEPT SELECT * FROM cache_ausente_despues)
   AND NOT EXISTS (SELECT * FROM cache_ausente_despues EXCEPT SELECT * FROM cache_ausente_antes) AS ok;
SELECT 'lapidas_conservadas', iif(ok, 'OK', 'FALLA') FROM lapidas_conservadas;
INSERT INTO control_renovacion SELECT 'lapidas_conservadas', ok FROM lapidas_conservadas;

CREATE TEMP VIEW items_conservados AS
SELECT NOT EXISTS (SELECT * FROM items_antes EXCEPT SELECT * FROM item_borrador)
   AND NOT EXISTS (SELECT * FROM item_borrador EXCEPT SELECT * FROM items_antes) AS ok;
SELECT 'items_conservados', iif(ok, 'OK', 'FALLA') FROM items_conservados;
INSERT INTO control_renovacion SELECT 'items_conservados', ok FROM items_conservados;

CREATE TEMP VIEW cola_conservada AS
SELECT NOT EXISTS (SELECT * FROM cola_antes EXCEPT SELECT * FROM cola_sync)
   AND NOT EXISTS (SELECT * FROM cola_sync EXCEPT SELECT * FROM cola_antes) AS ok;
SELECT 'cola_conservada', iif(ok, 'OK', 'FALLA') FROM cola_conservada;
INSERT INTO control_renovacion SELECT 'cola_conservada', ok FROM cola_conservada;

COMMIT;
.print 'RENOVACION CONFIRMADA'
