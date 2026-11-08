-- =============================================================================
-- Food Store — Unidad 8 — Guardar un borrador completo (design.md §7.1, §6.1).
--
-- Parámetros (los fija bloque_d.sh con -cmd ".parameter set ..."):
--   @id_local    UUID del borrador          @solicitud  UUID de la solicitud
--   @usuario     usuario_id_servidor        @forma_pago EFECTIVO|TARJETA|TRANSFERENCIA
--   @items       JSON [[producto_id, cantidad, precio_centavos_visto], ...]
--
-- Borrador, ítems y solicitud PENDIENTE en una sola transacción. El precio
-- visto debe coincidir con producto_cache y el producto debe estar en
-- v_catalogo_disponible. Una repetición falla por clave primaria: no se usa
-- INSERT OR REPLACE, OR IGNORE ni borrados. Con .bail on, cualquier error
-- detiene el cliente antes del COMMIT y la transacción se revierte.
-- =============================================================================
.bail on
.headers off
.mode list
.separator ' | '

PRAGMA foreign_keys = ON;

CREATE TEMP TABLE control_borrador (
    control TEXT NOT NULL,
    ok      INTEGER NOT NULL CHECK (ok = 1)
) STRICT;

SELECT 'control', 'foreign_keys', iif(foreign_keys = 1, 'OK', 'FALLA') FROM pragma_foreign_keys;
INSERT INTO control_borrador SELECT 'foreign_keys', foreign_keys = 1 FROM pragma_foreign_keys;

CREATE TEMP TABLE items_pedidos (
    producto_id           INTEGER NOT NULL PRIMARY KEY,
    cantidad              INTEGER NOT NULL,
    precio_centavos_visto INTEGER NOT NULL
) STRICT;
INSERT INTO items_pedidos
SELECT json_extract(value, '$[0]'), json_extract(value, '$[1]'), json_extract(value, '$[2]')
FROM json_each(@items);

SELECT 'control', 'items_recibidos', iif(count(*) > 0, 'OK', 'FALLA') FROM items_pedidos;
INSERT INTO control_borrador SELECT 'items_recibidos', count(*) > 0 FROM items_pedidos;

BEGIN IMMEDIATE;

-- Estado previo: ese borrador y esa solicitud no existen todavía.
CREATE TEMP TABLE identificadores_nuevos AS
SELECT NOT EXISTS (SELECT 1 FROM pedido_borrador WHERE id_local = @id_local)
   AND NOT EXISTS (SELECT 1 FROM cola_sync WHERE solicitud_uuid = @solicitud) AS ok;
SELECT 'control', 'identificadores_nuevos', iif(ok, 'OK', 'FALLA') FROM identificadores_nuevos;
INSERT INTO control_borrador SELECT 'identificadores_nuevos', ok FROM identificadores_nuevos;

-- La tablet ofrece solo lo que ve: producto disponible y precio del catálogo.
CREATE TEMP TABLE items_del_catalogo AS
SELECT count(*) = (SELECT count(*) FROM items_pedidos) AS ok
FROM items_pedidos i
JOIN v_catalogo_disponible v ON v.producto_id = i.producto_id
JOIN producto_cache c ON c.producto_id = i.producto_id
WHERE c.precio_centavos = i.precio_centavos_visto;
SELECT 'control', 'items_del_catalogo_con_precio_vigente', iif(ok, 'OK', 'FALLA') FROM items_del_catalogo;
INSERT INTO control_borrador SELECT 'items_del_catalogo', ok FROM items_del_catalogo;

INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES (@id_local, @usuario, @forma_pago);

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
SELECT @id_local, producto_id, cantidad, precio_centavos_visto
FROM items_pedidos ORDER BY producto_id;

INSERT INTO cola_sync (solicitud_uuid, id_local) VALUES (@solicitud, @id_local);

CREATE TEMP TABLE borrador_completo AS
SELECT (SELECT count(*) FROM pedido_borrador WHERE id_local = @id_local) = 1
   AND (SELECT count(*) FROM item_borrador WHERE id_local = @id_local)
       = (SELECT count(*) FROM items_pedidos)
   AND (SELECT count(*) FROM cola_sync
        WHERE id_local = @id_local AND solicitud_uuid = @solicitud
          AND estado = 'PENDIENTE' AND motivo IS NULL) = 1 AS ok;
SELECT 'control', 'borrador_items_y_solicitud_pendiente', iif(ok, 'OK', 'FALLA') FROM borrador_completo;
INSERT INTO control_borrador SELECT 'borrador_completo', ok FROM borrador_completo;

COMMIT;

SELECT 'borrador', id_local, usuario_id_servidor, forma_pago FROM pedido_borrador WHERE id_local = @id_local;
SELECT 'item', producto_id, cantidad, precio_centavos_visto
FROM item_borrador WHERE id_local = @id_local ORDER BY producto_id;
SELECT 'solicitud', solicitud_uuid, estado, coalesce(motivo, '<NULL>')
FROM cola_sync WHERE id_local = @id_local ORDER BY solicitud_uuid;
.print 'BORRADOR CONFIRMADO'
