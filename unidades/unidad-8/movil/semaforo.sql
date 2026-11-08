-- =============================================================================
-- Food Store — Unidad 8 — Semáforo (bloque D). Fuente: design.md §6 y §6.1;
-- requirements.md REQ-03 y REQ-04.
--
--   sqlite3 -batch <base>.db < semaforo.sql
--
-- Evalúa SOLO las solicitudes PENDIENTE contra snapshot_servidor y guarda
-- estado y motivo. No modifica precios de item_borrador, no toca solicitudes
-- ya evaluadas y no tiene ninguna conexión ni sentencia hacia PostgreSQL:
-- SIMULADO_APROBADO no es una venta, no crea pedidos ni descuenta stock.
--
-- Con .bail on, cualquier error o control fallido detiene el cliente antes
-- del COMMIT; al cerrar la conexión, SQLite revierte la transacción abierta.
-- La última línea de una ejecución correcta es SEMAFORO CONFIRMADO.
-- =============================================================================
.bail on
.headers off
.mode list
.separator ' | '

PRAGMA foreign_keys = ON;

CREATE TEMP TABLE control_semaforo (
    control TEXT NOT NULL,
    ok      INTEGER NOT NULL CHECK (ok = 1)
) STRICT;

-- Antes de BEGIN: claves foráneas activas.
SELECT 'control', 'foreign_keys', iif(foreign_keys = 1, 'OK', 'FALLA') FROM pragma_foreign_keys;
INSERT INTO control_semaforo SELECT 'foreign_keys', foreign_keys = 1 FROM pragma_foreign_keys;

BEGIN IMMEDIATE;

-- Una instantánea con una sola fecha de captura (la cita el motivo).
SELECT 'control', 'captura_unica', iif(count(DISTINCT capturado_en) = 1, 'OK', 'FALLA')
FROM snapshot_servidor;
INSERT INTO control_semaforo
SELECT 'captura_unica', count(DISTINCT capturado_en) = 1 FROM snapshot_servidor;

-- Copias para comprobar al final que nada ajeno a las pendientes cambió.
CREATE TEMP TABLE evaluadas_antes AS SELECT * FROM cola_sync WHERE estado <> 'PENDIENTE';
CREATE TEMP TABLE items_antes     AS SELECT * FROM item_borrador;
CREATE TEMP TABLE cache_antes     AS SELECT * FROM producto_cache;

-- Resultado de cada solicitud PENDIENTE. motivo NOT NULL: toda solicitud
-- evaluada recibe un mensaje explicativo.
CREATE TEMP TABLE resultado (
    solicitud_uuid TEXT NOT NULL PRIMARY KEY,
    id_local       TEXT NOT NULL,
    estado         TEXT NOT NULL CHECK (estado IN ('CONFLICTO', 'RECHAZADO', 'SIMULADO_APROBADO')),
    motivo         TEXT NOT NULL
) STRICT;

INSERT INTO resultado (solicitud_uuid, id_local, estado, motivo)
WITH pendientes AS (
    SELECT solicitud_uuid, id_local FROM cola_sync WHERE estado = 'PENDIENTE'
), items AS (
    -- LEFT JOIN: un producto ausente de la instantánea queda con s_id NULL.
    SELECT p.solicitud_uuid, i.producto_id, i.cantidad, i.precio_centavos_visto,
           s.producto_id AS s_id, s.precio_centavos, s.stock, s.disponible, s.eliminado
    FROM pendientes p
    JOIN item_borrador i ON i.id_local = p.id_local
    LEFT JOIN snapshot_servidor s ON s.producto_id = i.producto_id
), rechazos AS (
    -- Primera causa del ítem: inexistente, baja, no disponible, stock.
    SELECT solicitud_uuid, producto_id,
           CASE
               WHEN s_id IS NULL THEN
                   printf('producto_id=%d: no existe en snapshot_servidor', producto_id)
               WHEN eliminado = 't' THEN
                   printf('producto_id=%d: eliminado=t', producto_id)
               WHEN disponible = 'f' THEN
                   printf('producto_id=%d: disponible=f', producto_id)
               WHEN cantidad > stock THEN
                   printf('producto_id=%d: stock disponible=%d, cantidad solicitada=%d',
                          producto_id, stock, cantidad)
           END AS motivo
    FROM items
), primer_rechazo AS (
    -- Entre los ítems rechazables, el de menor producto_id.
    SELECT solicitud_uuid, motivo,
           row_number() OVER (PARTITION BY solicitud_uuid ORDER BY producto_id) AS orden
    FROM rechazos WHERE motivo IS NOT NULL
), primer_conflicto AS (
    SELECT solicitud_uuid,
           printf('producto_id=%d: precio_visto=%d centavos, precio_actual=%d centavos',
                  producto_id, precio_centavos_visto, precio_centavos) AS motivo,
           row_number() OVER (PARTITION BY solicitud_uuid ORDER BY producto_id) AS orden
    FROM items
    WHERE s_id IS NOT NULL AND precio_centavos_visto <> precio_centavos
)
SELECT p.solicitud_uuid, p.id_local,
       CASE WHEN r.motivo IS NOT NULL THEN 'RECHAZADO'
            WHEN c.motivo IS NOT NULL THEN 'CONFLICTO'
            ELSE 'SIMULADO_APROBADO' END,
       coalesce(r.motivo, c.motivo,
                'todo coincide con snapshot de '
                    || (SELECT max(capturado_en) FROM snapshot_servidor))
FROM pendientes p
LEFT JOIN primer_rechazo   r ON r.solicitud_uuid = p.solicitud_uuid AND r.orden = 1
LEFT JOIN primer_conflicto c ON c.solicitud_uuid = p.solicitud_uuid AND c.orden = 1;

-- Solo filas que siguen PENDIENTE; nunca una solicitud ya evaluada.
UPDATE cola_sync
SET estado = r.estado,
    motivo = r.motivo
FROM resultado r
WHERE cola_sync.solicitud_uuid = r.solicitud_uuid
  AND cola_sync.estado = 'PENDIENTE';

CREATE TEMP TABLE actualizadas (n INTEGER NOT NULL) STRICT;
INSERT INTO actualizadas SELECT changes();

SELECT 'control', 'filas_actualizadas_igual_a_procesadas',
       iif((SELECT n FROM actualizadas) = (SELECT count(*) FROM resultado), 'OK', 'FALLA');
INSERT INTO control_semaforo
SELECT 'filas_actualizadas', (SELECT n FROM actualizadas) = (SELECT count(*) FROM resultado);

CREATE TEMP VIEW sin_pendientes_procesadas AS
SELECT NOT EXISTS (SELECT 1 FROM cola_sync c JOIN resultado r USING (solicitud_uuid)
                   WHERE c.estado = 'PENDIENTE' OR c.motivo IS NULL) AS ok;
SELECT 'control', 'procesadas_con_estado_y_motivo', iif(ok, 'OK', 'FALLA') FROM sin_pendientes_procesadas;
INSERT INTO control_semaforo SELECT 'procesadas_con_estado_y_motivo', ok FROM sin_pendientes_procesadas;

CREATE TEMP VIEW evaluadas_sin_cambios AS
SELECT NOT EXISTS (SELECT * FROM evaluadas_antes
                   EXCEPT SELECT * FROM cola_sync WHERE estado <> 'PENDIENTE') AS ok;
SELECT 'control', 'evaluadas_previas_sin_cambios', iif(ok, 'OK', 'FALLA') FROM evaluadas_sin_cambios;
INSERT INTO control_semaforo SELECT 'evaluadas_previas_sin_cambios', ok FROM evaluadas_sin_cambios;

CREATE TEMP VIEW items_sin_cambios AS
SELECT NOT EXISTS (SELECT * FROM items_antes EXCEPT SELECT * FROM item_borrador)
   AND NOT EXISTS (SELECT * FROM item_borrador EXCEPT SELECT * FROM items_antes) AS ok;
SELECT 'control', 'precios_de_items_sin_cambios', iif(ok, 'OK', 'FALLA') FROM items_sin_cambios;
INSERT INTO control_semaforo SELECT 'items_sin_cambios', ok FROM items_sin_cambios;

CREATE TEMP VIEW cache_sin_cambios AS
SELECT NOT EXISTS (SELECT * FROM cache_antes EXCEPT SELECT * FROM producto_cache)
   AND NOT EXISTS (SELECT * FROM producto_cache EXCEPT SELECT * FROM cache_antes) AS ok;
SELECT 'control', 'producto_cache_sin_cambios', iif(ok, 'OK', 'FALLA') FROM cache_sin_cambios;
INSERT INTO control_semaforo SELECT 'cache_sin_cambios', ok FROM cache_sin_cambios;

COMMIT;

SELECT 'procesada', solicitud_uuid, id_local, estado, motivo
FROM resultado ORDER BY solicitud_uuid;
SELECT 'procesadas', count(*) FROM resultado;
.print 'SEMAFORO CONFIRMADO'
