-- =============================================================================
-- Food Store — Unidad 8 — Aceptación explícita del precio nuevo (design.md §7.2).
--
-- Parámetros (bloque_d.sh): @id_local, @solicitud_anterior (en CONFLICTO),
-- @solicitud_nueva (UUID nuevo).
--
-- Todo o nada: actualiza precio_centavos_visto de los ítems del borrador con
-- el precio de snapshot_servidor e inserta una solicitud PENDIENTE nueva. Si
-- falta un producto en la instantánea, o falla cualquier sentencia, el
-- cliente se detiene (.bail on) antes del COMMIT y la transacción se
-- revierte: no quedan precios parciales ni solicitud nueva, y la anterior
-- conserva su CONFLICTO y su motivo. La unicidad de la solicitud nueva la
-- garantiza la clave primaria de cola_sync.
-- =============================================================================
.bail on
.headers off
.mode list
.separator ' | '

PRAGMA foreign_keys = ON;

CREATE TEMP TABLE control_aceptacion (
    control TEXT NOT NULL,
    ok      INTEGER NOT NULL CHECK (ok = 1)
) STRICT;

SELECT 'control', 'foreign_keys', iif(foreign_keys = 1, 'OK', 'FALLA') FROM pragma_foreign_keys;
INSERT INTO control_aceptacion SELECT 'foreign_keys', foreign_keys = 1 FROM pragma_foreign_keys;

BEGIN IMMEDIATE;

CREATE TEMP TABLE anterior_antes AS
SELECT * FROM cola_sync WHERE solicitud_uuid = @solicitud_anterior;

CREATE TEMP TABLE anterior_en_conflicto AS
SELECT count(*) = 1 AS ok FROM anterior_antes
WHERE id_local = @id_local AND estado = 'CONFLICTO';
SELECT 'control', 'solicitud_anterior_en_conflicto', iif(ok, 'OK', 'FALLA') FROM anterior_en_conflicto;
INSERT INTO control_aceptacion SELECT 'anterior_en_conflicto', ok FROM anterior_en_conflicto;

-- Antes del UPDATE: ningún ítem del borrador puede faltar en la instantánea.
CREATE TEMP TABLE items_en_snapshot AS
SELECT count(*) > 0 AND count(*) = count(s.producto_id) AS ok
FROM item_borrador i
LEFT JOIN snapshot_servidor s ON s.producto_id = i.producto_id
WHERE i.id_local = @id_local;
SELECT 'control', 'items_en_snapshot', iif(ok, 'OK', 'FALLA') FROM items_en_snapshot;
INSERT INTO control_aceptacion SELECT 'items_en_snapshot', ok FROM items_en_snapshot;

UPDATE item_borrador
SET precio_centavos_visto = (
    SELECT s.precio_centavos FROM snapshot_servidor s
    WHERE s.producto_id = item_borrador.producto_id
)
WHERE id_local = @id_local;

SELECT 'paso', 'precios_actualizados_en_la_transaccion', changes();

-- Si este INSERT falla, la actualización anterior se revierte con él.
INSERT INTO cola_sync (solicitud_uuid, id_local) VALUES (@solicitud_nueva, @id_local);

CREATE TEMP TABLE anterior_sin_cambios AS
SELECT NOT EXISTS (SELECT * FROM anterior_antes
                   EXCEPT SELECT * FROM cola_sync WHERE solicitud_uuid = @solicitud_anterior) AS ok;
SELECT 'control', 'solicitud_anterior_sin_cambios', iif(ok, 'OK', 'FALLA') FROM anterior_sin_cambios;
INSERT INTO control_aceptacion SELECT 'anterior_sin_cambios', ok FROM anterior_sin_cambios;

CREATE TEMP TABLE precios_de_snapshot AS
SELECT NOT EXISTS (SELECT 1 FROM item_borrador i
                   JOIN snapshot_servidor s ON s.producto_id = i.producto_id
                   WHERE i.id_local = @id_local
                     AND i.precio_centavos_visto <> s.precio_centavos) AS ok;
SELECT 'control', 'precios_iguales_a_snapshot', iif(ok, 'OK', 'FALLA') FROM precios_de_snapshot;
INSERT INTO control_aceptacion SELECT 'precios_de_snapshot', ok FROM precios_de_snapshot;

CREATE TEMP TABLE nueva_pendiente AS
SELECT count(*) = 1 AS ok FROM cola_sync
WHERE solicitud_uuid = @solicitud_nueva AND id_local = @id_local
  AND estado = 'PENDIENTE' AND motivo IS NULL
  AND solicitud_uuid <> @solicitud_anterior;
SELECT 'control', 'solicitud_nueva_pendiente', iif(ok, 'OK', 'FALLA') FROM nueva_pendiente;
INSERT INTO control_aceptacion SELECT 'nueva_pendiente', ok FROM nueva_pendiente;

COMMIT;

SELECT 'item', producto_id, cantidad, precio_centavos_visto
FROM item_borrador WHERE id_local = @id_local ORDER BY producto_id;
SELECT 'solicitud', solicitud_uuid, estado, coalesce(motivo, '<NULL>')
FROM cola_sync WHERE id_local = @id_local ORDER BY creada_en, solicitud_uuid;
.print 'ACEPTACION CONFIRMADA'
