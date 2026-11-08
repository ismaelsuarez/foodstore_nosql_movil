-- Food Store — Unidad 8 — Tabla auxiliar del bloque C (design.md §4).
-- Crear una sola vez, después de schema_sqlite.sql. Orden idéntico al CSV.
PRAGMA foreign_keys = ON;

BEGIN;
CREATE TABLE snapshot_servidor (
    producto_id      INTEGER NOT NULL PRIMARY KEY,
    nombre           TEXT    NOT NULL,
    precio_centavos  INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock            INTEGER NOT NULL CHECK (stock >= 0),
    disponible       TEXT    NOT NULL CHECK (disponible IN ('t', 'f')),
    eliminado        TEXT    NOT NULL CHECK (eliminado IN ('t', 'f')),
    capturado_en     TEXT    NOT NULL
) STRICT;
COMMIT;
