-- =============================================================================
-- Food Store — Unidad 8 — Comprobación de un caso del bloque D (solo lectura).
--   sqlite3 -readonly -batch <db> < comprobar_caso_d.sql
-- Parámetros (bloque_d.sh comprobar):
--   @id_local, @solicitud, @producto_id, @precio_visto,
--   @estado, @motivo ('<NULL>' = motivo NULL), @lapida (1 = exigir lápida).
-- Cada comprobación imprime: id | descripción | esperado | observado | OK/FALLA.
-- =============================================================================
.headers off
.mode list
.separator ' | '
PRAGMA foreign_keys = ON;

SELECT 'K-01', 'foreign_keys activo', 1, foreign_keys, iif(foreign_keys = 1, 'OK', 'FALLA')
FROM pragma_foreign_keys;

SELECT 'K-02', 'precio visto del item (centavos)', @precio_visto, coalesce(v, '<sin item>'),
       iif(v IS @precio_visto, 'OK', 'FALLA')
FROM (SELECT (SELECT precio_centavos_visto FROM item_borrador
              WHERE id_local = @id_local AND producto_id = @producto_id) AS v);

SELECT 'K-03', 'estado de la solicitud', @estado, coalesce(e, '<sin solicitud>'),
       iif(e IS @estado, 'OK', 'FALLA')
FROM (SELECT (SELECT estado FROM cola_sync
              WHERE solicitud_uuid = @solicitud AND id_local = @id_local) AS e);

SELECT 'K-04', 'motivo de la solicitud', @motivo, coalesce(m, '<NULL>'),
       iif(coalesce(m, '<NULL>') = @motivo, 'OK', 'FALLA')
FROM (SELECT (SELECT motivo FROM cola_sync
              WHERE solicitud_uuid = @solicitud AND id_local = @id_local) AS m);

-- Lápida (C4): la fila sigue en producto_cache con eliminado = 1 y no se ve
-- en el catálogo. Sin lápida exigida, el producto debe seguir visible.
SELECT 'K-05', 'fila del producto en producto_cache', 1, n, iif(n = 1, 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM producto_cache WHERE producto_id = @producto_id);

SELECT 'K-06', 'eliminado en producto_cache', @lapida, e, iif(e IS @lapida, 'OK', 'FALLA')
FROM (SELECT (SELECT eliminado FROM producto_cache WHERE producto_id = @producto_id) AS e);

SELECT 'K-07', 'visible en v_catalogo_disponible', 1 - @lapida, n, iif(n = 1 - @lapida, 'OK', 'FALLA')
FROM (SELECT count(*) AS n FROM v_catalogo_disponible WHERE producto_id = @producto_id);

SELECT 'K-08', 'integrity_check y foreign_key_check', 'ok|0', r, iif(r = 'ok|0', 'OK', 'FALLA')
FROM (SELECT (SELECT group_concat(integrity_check, ';') FROM pragma_integrity_check)
          || '|' || (SELECT count(*) FROM pragma_foreign_key_check) AS r);

SELECT 'dato', 'producto_cache', producto_id, nombre, precio_centavos, stock_visto,
       disponible_visto, eliminado, capturado_en
FROM producto_cache WHERE producto_id = @producto_id;
SELECT 'dato', 'snapshot_servidor', coalesce(
    (SELECT producto_id || ' | ' || precio_centavos || ' | ' || stock || ' | '
            || disponible || ' | ' || eliminado || ' | ' || capturado_en
     FROM snapshot_servidor WHERE producto_id = @producto_id), '<ausente>');
