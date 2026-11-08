-- =============================================================================
-- Food Store — Unidad 8 — Intento de insertar una solicitud que DEBE fallar.
-- Usos (bloque_d.sh): C6, reinsertar un solicitud_uuid existente
-- (REQ-04, CA-04a); control de copia: segunda solicitud PENDIENTE para el
-- mismo borrador (CA-04d).
--
-- Parámetros: @solicitud, @id_local.
--
-- Sin .bail: el cliente informa el error de la sentencia marcada
-- (SOLICITUD_INVALIDA) y sigue con las comprobaciones. El coordinador exige
-- en stderr el diagnóstico exacto de esa línea; los conteos sin cambios no
-- bastan para aprobar. No se borra nada para aparentar el resultado.
-- =============================================================================
.headers off
.mode list
.separator ' | '

PRAGMA foreign_keys = ON;
SELECT 'I-01', 'foreign_keys activo', 1, foreign_keys, iif(foreign_keys = 1, 'OK', 'FALLA')
FROM pragma_foreign_keys;

CREATE TEMP TABLE cola_antes AS SELECT * FROM cola_sync;

SELECT 'I-02', 'filas de cola_sync antes del intento', '>0', count(*), iif(count(*) > 0, 'OK', 'FALLA')
FROM cola_antes;

INSERT INTO cola_sync (solicitud_uuid, id_local) VALUES (@solicitud, @id_local); -- SOLICITUD_INVALIDA

SELECT 'I-03', 'filas de cola_sync despues del intento', (SELECT count(*) FROM cola_antes), n,
       iif(n = (SELECT count(*) FROM cola_antes), 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM cola_sync);

SELECT 'I-04', 'cola_sync identica a la anterior (ambas direcciones)', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT (SELECT count(*) FROM (SELECT * FROM cola_antes EXCEPT SELECT * FROM cola_sync))
           + (SELECT count(*) FROM (SELECT * FROM cola_sync EXCEPT SELECT * FROM cola_antes)) AS n);

SELECT 'I-05', 'violaciones de claves foraneas', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM pragma_foreign_key_check);

SELECT 'solicitud', solicitud_uuid, estado, coalesce(motivo, '<NULL>')
FROM cola_sync WHERE id_local = @id_local OR solicitud_uuid = @solicitud
ORDER BY creada_en, solicitud_uuid;
