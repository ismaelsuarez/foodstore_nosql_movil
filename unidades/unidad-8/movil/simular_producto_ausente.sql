-- =============================================================================
-- Food Store — Unidad 8 — SOLO PARA COPIAS DESCARTABLES (controles del bloque D).
-- Quita un producto de snapshot_servidor para probar la aceptación imposible
-- de design.md §7.2. bloque_d.sh se niega a ejecutarlo sobre una base dentro
-- del repositorio. Nunca se borran productos en PostgreSQL.
--
-- Parámetro: @producto_id.
-- =============================================================================
.bail on
.headers off
.mode list
.separator ' | '

PRAGMA foreign_keys = ON;
CREATE TEMP TABLE control_copia (
    control TEXT NOT NULL,
    ok      INTEGER NOT NULL CHECK (ok = 1)
) STRICT;

BEGIN IMMEDIATE;
DELETE FROM snapshot_servidor WHERE producto_id = @producto_id;
SELECT 'control', 'una_fila_quitada_de_snapshot', iif(changes() = 1, 'OK', 'FALLA');
INSERT INTO control_copia SELECT 'una_fila_quitada', count(*) = 0
FROM snapshot_servidor WHERE producto_id = @producto_id;
COMMIT;
.print 'COPIA PREPARADA'
