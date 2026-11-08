-- Food Store — Unidad 8 — Estado de borradores, solicitudes y catálogo (lectura).
-- sqlite3 -readonly -batch <base>.db < estado_bloque_d.sql
.headers off
.mode list
.separator ' | '
PRAGMA foreign_keys = ON;

.print '-- cola_sync: solicitud_uuid | id_local | estado | motivo | creada_en'
SELECT solicitud_uuid, id_local, estado, coalesce(motivo, '<NULL>'), creada_en
FROM cola_sync ORDER BY creada_en, solicitud_uuid;
.print '-- pedido_borrador: id_local | usuario_id_servidor | forma_pago'
SELECT id_local, usuario_id_servidor, forma_pago FROM pedido_borrador ORDER BY id_local;
.print '-- item_borrador: id_local | producto_id | cantidad | precio_centavos_visto'
SELECT id_local, producto_id, cantidad, precio_centavos_visto
FROM item_borrador ORDER BY id_local, producto_id;
.print '-- producto_cache: id | nombre | centavos | stock_visto | disponible | eliminado | capturado_en'
SELECT * FROM producto_cache ORDER BY producto_id;
.print '-- v_catalogo_disponible: producto_id'
SELECT group_concat(producto_id, ',') FROM (SELECT producto_id FROM v_catalogo_disponible ORDER BY producto_id);
.print '-- snapshot_servidor: capturado_en | filas'
SELECT capturado_en, count(*) FROM snapshot_servidor GROUP BY capturado_en;
.print '-- integridad: integrity_check | foreign_key_check'
SELECT (SELECT group_concat(integrity_check, ';') FROM pragma_integrity_check),
       (SELECT count(*) FROM pragma_foreign_key_check);
