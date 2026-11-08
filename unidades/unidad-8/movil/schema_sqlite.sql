-- =============================================================================
-- Food Store — Unidad 8 — Esquema de la base SQLite móvil (bloque B)
-- Fuente: unidades/unidad-8/docs/kiro/design.md §3.
--
-- Se ejecuta una sola vez sobre una base nueva:
--   sqlite3 <base>.db < schema_sqlite.sql
-- Las tablas se crean sin IF NOT EXISTS: sobre una base que ya tiene el
-- esquema, el script falla en lugar de mezclar versiones.
--
-- No incluye snapshot_servidor (bloque C) ni el semáforo (bloque D).
-- Precios en centavos enteros. Booleanos como INTEGER 0/1.
-- =============================================================================

PRAGMA foreign_keys = ON;

BEGIN;

-- Copia del catálogo traída del servidor. producto_id es el mismo id que en
-- PostgreSQL. Las bajas se marcan con eliminado = 1 (lápida); la fila no se
-- borra para no dejar huérfanos a los item_borrador que la referencian.
CREATE TABLE producto_cache (
    producto_id       INTEGER PRIMARY KEY,
    nombre            TEXT    NOT NULL,
    precio_centavos   INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock_visto       INTEGER NOT NULL CHECK (stock_visto >= 0),
    disponible_visto  INTEGER NOT NULL CHECK (disponible_visto IN (0, 1)),
    eliminado         INTEGER NOT NULL DEFAULT 0 CHECK (eliminado IN (0, 1)),
    capturado_en      TEXT    NOT NULL
) STRICT;

-- Pedido anotado sin conexión. No es una venta. id_local es un UUID generado
-- en la tablet.
CREATE TABLE pedido_borrador (
    id_local             TEXT    PRIMARY KEY,
    usuario_id_servidor  INTEGER NOT NULL,
    forma_pago           TEXT    NOT NULL
                         CHECK (forma_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA')),
    creado_en            TEXT    NOT NULL
                         DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
) STRICT;

-- Productos de cada borrador, con el precio que vio el cliente al anotar.
CREATE TABLE item_borrador (
    id_local               TEXT    NOT NULL
                           REFERENCES pedido_borrador (id_local) ON DELETE CASCADE,
    producto_id            INTEGER NOT NULL
                           REFERENCES producto_cache (producto_id),
    cantidad               INTEGER NOT NULL CHECK (cantidad > 0),
    precio_centavos_visto  INTEGER NOT NULL CHECK (precio_centavos_visto >= 0),
    PRIMARY KEY (id_local, producto_id)
) STRICT;

-- Cada intento de enviar un borrador, con su resultado. solicitud_uuid no
-- cambia en los reintentos. motivo es NULL mientras la solicitud está
-- PENDIENTE sin evaluar.
CREATE TABLE cola_sync (
    solicitud_uuid  TEXT PRIMARY KEY,
    id_local        TEXT NOT NULL REFERENCES pedido_borrador (id_local),
    estado          TEXT NOT NULL DEFAULT 'PENDIENTE'
                    CHECK (estado IN ('PENDIENTE', 'CONFLICTO', 'RECHAZADO', 'SIMULADO_APROBADO')),
    motivo          TEXT,
    creada_en       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
) STRICT;

-- Un borrador no puede tener dos solicitudes PENDIENTE a la vez.
CREATE UNIQUE INDEX ux_cola_una_pendiente
    ON cola_sync (id_local) WHERE estado = 'PENDIENTE';

-- Catálogo que ve el vendedor: sin bajas ni productos no disponibles.
CREATE VIEW v_catalogo_disponible AS
SELECT producto_id,
       nombre,
       precio_centavos / 100.0 AS precio,
       stock_visto
FROM producto_cache
WHERE eliminado = 0 AND disponible_visto = 1;

COMMIT;
