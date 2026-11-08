-- =============================================================================
-- Food Store — Unidad 8 — Pruebas del bloque B sobre una base DESCARTABLE
-- Fuente: unidades/unidad-8/docs/kiro/design.md §7.1, §8 y §9;
--         requirements.md REQ-01 (C1) y REQ-02 (COMMIT, ROLLBACK, C7-a, C7-b).
--
-- Requisito: la base ya tiene el esquema de schema_sqlite.sql y está vacía.
-- NUNCA ejecutar sobre foodstore_movil.db: la fixture es sintética.
--
--   sqlite3 <base_descartable>.db < pruebas_sqlite.sql
--
-- Cada comprobación imprime: id | descripción | esperado | observado | OK/FALLA,
-- y el veredicto se calcula en SQL. C7-a y C7-b provocan a propósito un error
-- de restricción: el cliente lo escribe en la salida de error con el número
-- de línea de la sentencia marcada (C7A_SENTENCIA_INVALIDA,
-- C7B_SENTENCIA_INVALIDA) y termina con código 1. Que ese diagnóstico sea el
-- esperado se comprueba fuera del SQL (verificar_bloque_b.sh): los conteos en
-- cero no bastan para aprobar C7.
--
-- No se usa .bail on: el ROLLBACK posterior a la sentencia inválida debe
-- ejecutarse en la misma sesión.
-- =============================================================================

.headers off
.mode list
.separator ' | '

-- -----------------------------------------------------------------------------
-- Conexión: activar y comprobar claves foráneas antes de cualquier BEGIN
-- -----------------------------------------------------------------------------
.print '== Conexion: foreign_keys'
PRAGMA foreign_keys = ON;

SELECT 'B-01', 'PRAGMA foreign_keys activo', 1, foreign_keys,
       iif(foreign_keys = 1, 'OK', 'FALLA')
FROM pragma_foreign_keys;

-- -----------------------------------------------------------------------------
-- Esquema: cuatro tablas STRICT, índice parcial y vista
-- -----------------------------------------------------------------------------
.print '== Esquema'
SELECT 'B-02', 'tablas STRICT del esquema', 4, n, iif(n = 4, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n
      FROM pragma_table_list
      WHERE schema = 'main' AND type = 'table' AND strict = 1
        AND name IN ('producto_cache', 'pedido_borrador', 'item_borrador', 'cola_sync'));

SELECT 'B-03', 'indice ux_cola_una_pendiente y vista v_catalogo_disponible', 2, n,
       iif(n = 2, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n
      FROM sqlite_schema
      WHERE (type = 'index' AND name = 'ux_cola_una_pendiente')
         OR (type = 'view' AND name = 'v_catalogo_disponible'));

SELECT 'B-04', 'base sin datos previos (4 tablas)', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT (SELECT COUNT(*) FROM producto_cache)
           + (SELECT COUNT(*) FROM pedido_borrador)
           + (SELECT COUNT(*) FROM item_borrador)
           + (SELECT COUNT(*) FROM cola_sync) AS n);

-- -----------------------------------------------------------------------------
-- Fixture sintética local (design.md §9). Valores inventados: no provienen de
-- PostgreSQL ni se presentan como extraídos. Ids altos para no confundirlos
-- con ids del servidor.
--   9101 y 9102: vigentes y disponibles.
--   9103: no disponible (disponible_visto = 0).
--   9104: dado de baja (lápida, eliminado = 1).
--   9999: no existe en producto_cache (se usa en C7-b).
-- -----------------------------------------------------------------------------
.print '== Fixture sintetica'
BEGIN;
INSERT INTO producto_cache
    (producto_id, nombre, precio_centavos, stock_visto,
     disponible_visto, eliminado, capturado_en)
VALUES
    (9101, 'Muzzarella (fixture)',        105000, 10, 1, 0, 'fixture-no-extraido'),
    (9102, 'Empanada de carne (fixture)',  15000, 40, 1, 0, 'fixture-no-extraido'),
    (9103, 'Fugazzeta (fixture)',         120000,  0, 0, 0, 'fixture-no-extraido'),
    (9104, 'Napolitana (fixture)',        115000,  5, 1, 1, 'fixture-no-extraido');
COMMIT;

SELECT 'FIX-01', 'productos de la fixture en producto_cache', 4, n,
       iif(n = 4, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM producto_cache);

-- -----------------------------------------------------------------------------
-- COMMIT: borrador completo (design.md §7.1, CA-02a)
-- Borrador  b1000000-0000-4000-8000-000000000001
-- Solicitud c1000000-0000-4000-8000-000000000001
-- -----------------------------------------------------------------------------
.print '== COMMIT: borrador completo'
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES ('b1000000-0000-4000-8000-000000000001', 9001, 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('b1000000-0000-4000-8000-000000000001', 9101, 2, 105000),
       ('b1000000-0000-4000-8000-000000000001', 9102, 6,  15000);
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('c1000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001');
COMMIT;

SELECT 'COMMIT-01', 'pedido_borrador del borrador confirmado', 1, n, iif(n = 1, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM pedido_borrador
      WHERE id_local = 'b1000000-0000-4000-8000-000000000001');

SELECT 'COMMIT-02', 'item_borrador del borrador confirmado', 2, n, iif(n = 2, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM item_borrador
      WHERE id_local = 'b1000000-0000-4000-8000-000000000001');

SELECT 'COMMIT-03', 'cola_sync PENDIENTE con motivo NULL', 1, n, iif(n = 1, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM cola_sync
      WHERE id_local = 'b1000000-0000-4000-8000-000000000001'
        AND solicitud_uuid = 'c1000000-0000-4000-8000-000000000001'
        AND estado = 'PENDIENTE' AND motivo IS NULL);

SELECT 'COMMIT-04', 'total visto del borrador en centavos', 300000, n,
       iif(n = 300000, 'OK', 'FALLA')
FROM (SELECT SUM(cantidad * precio_centavos_visto) AS n FROM item_borrador
      WHERE id_local = 'b1000000-0000-4000-8000-000000000001');

-- -----------------------------------------------------------------------------
-- ROLLBACK: operación válida deshecha explícitamente (CA-02b)
-- Borrador  b2000000-0000-4000-8000-000000000001
-- Solicitud c2000000-0000-4000-8000-000000000001
-- -----------------------------------------------------------------------------
.print '== ROLLBACK: operacion deshecha'
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES ('b2000000-0000-4000-8000-000000000001', 9001, 'TRANSFERENCIA');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('b2000000-0000-4000-8000-000000000001', 9102, 1, 15000);
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('c2000000-0000-4000-8000-000000000001', 'b2000000-0000-4000-8000-000000000001');

SELECT 'ROLLBACK-01', 'filas de la operacion antes de ROLLBACK (3 tablas)', 3, n,
       iif(n = 3, 'OK', 'FALLA')
FROM (SELECT (SELECT COUNT(*) FROM pedido_borrador
              WHERE id_local = 'b2000000-0000-4000-8000-000000000001')
           + (SELECT COUNT(*) FROM item_borrador
              WHERE id_local = 'b2000000-0000-4000-8000-000000000001')
           + (SELECT COUNT(*) FROM cola_sync
              WHERE id_local = 'b2000000-0000-4000-8000-000000000001') AS n);
ROLLBACK;

SELECT 'ROLLBACK-02', 'pedido_borrador tras ROLLBACK', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM pedido_borrador
      WHERE id_local = 'b2000000-0000-4000-8000-000000000001');

SELECT 'ROLLBACK-03', 'item_borrador tras ROLLBACK', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM item_borrador
      WHERE id_local = 'b2000000-0000-4000-8000-000000000001');

SELECT 'ROLLBACK-04', 'cola_sync tras ROLLBACK', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM cola_sync
      WHERE id_local = 'b2000000-0000-4000-8000-000000000001');

-- -----------------------------------------------------------------------------
-- C1: consulta local del catálogo disponible (REQ-01, CA-01a, CA-01c)
-- Solo se usa el archivo SQLite local; no hay conexión a ningún servidor.
-- -----------------------------------------------------------------------------
.print '== C1: v_catalogo_disponible (producto_id | nombre | precio | stock_visto)'
SELECT producto_id, nombre, printf('%.2f', precio), stock_visto
FROM v_catalogo_disponible
ORDER BY producto_id;

SELECT 'C1-01', 'productos en v_catalogo_disponible', 2, n, iif(n = 2, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM v_catalogo_disponible);

SELECT 'C1-02', 'ids visibles en el catalogo', '9101,9102', ids,
       iif(ids = '9101,9102', 'OK', 'FALLA')
FROM (SELECT group_concat(producto_id, ',') AS ids
      FROM (SELECT producto_id FROM v_catalogo_disponible ORDER BY producto_id));

SELECT 'C1-03', 'lapida 9104 conservada en producto_cache y oculta en la vista', 1, n,
       iif(n = 1, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM producto_cache
      WHERE producto_id = 9104 AND eliminado = 1
        AND producto_id NOT IN (SELECT producto_id FROM v_catalogo_disponible));

SELECT 'C1-04', 'no disponible 9103 oculto en la vista', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM v_catalogo_disponible WHERE producto_id = 9103);

-- -----------------------------------------------------------------------------
-- C7-a: cantidad = 0 (CA-02c, CA-02e, CA-02f, CA-02g)
-- Borrador b7a00000-0000-4000-8000-000000000001
-- Error esperado: CHECK constraint failed: cantidad > 0
-- -----------------------------------------------------------------------------
.print '== C7-a: cantidad = 0 (se espera CHECK constraint failed: cantidad > 0)'
SELECT 'C7A-01', 'foreign_keys activo antes de BEGIN', 1, foreign_keys,
       iif(foreign_keys = 1, 'OK', 'FALLA')
FROM pragma_foreign_keys;

BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES ('b7a00000-0000-4000-8000-000000000001', 9001, 'TARJETA');

SELECT 'C7A-02', 'preparacion valida: encabezado dentro de la transaccion', 1, n,
       iif(n = 1, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM pedido_borrador
      WHERE id_local = 'b7a00000-0000-4000-8000-000000000001');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto) VALUES ('b7a00000-0000-4000-8000-000000000001', 9101, 0, 105000); -- C7A_SENTENCIA_INVALIDA

SELECT 'C7A-03', 'item invalido no grabado (dentro de la transaccion)', 0, n,
       iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM item_borrador
      WHERE id_local = 'b7a00000-0000-4000-8000-000000000001');
ROLLBACK;

SELECT 'C7A-04', 'pedido_borrador tras ROLLBACK', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM pedido_borrador
      WHERE id_local = 'b7a00000-0000-4000-8000-000000000001');

SELECT 'C7A-05', 'item_borrador tras ROLLBACK', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM item_borrador
      WHERE id_local = 'b7a00000-0000-4000-8000-000000000001');

SELECT 'C7A-06', 'cola_sync tras ROLLBACK', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM cola_sync
      WHERE id_local = 'b7a00000-0000-4000-8000-000000000001');

-- -----------------------------------------------------------------------------
-- C7-b: producto inexistente (CA-02d, CA-02e, CA-02f, CA-02g)
-- Borrador b7b00000-0000-4000-8000-000000000001
-- Error esperado: FOREIGN KEY constraint failed (producto 9999)
-- -----------------------------------------------------------------------------
.print '== C7-b: producto inexistente (se espera FOREIGN KEY constraint failed)'
SELECT 'C7B-01', 'foreign_keys activo antes de BEGIN', 1, foreign_keys,
       iif(foreign_keys = 1, 'OK', 'FALLA')
FROM pragma_foreign_keys;

SELECT 'C7B-02', 'producto 9999 ausente de producto_cache', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM producto_cache WHERE producto_id = 9999);

BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES ('b7b00000-0000-4000-8000-000000000001', 9001, 'EFECTIVO');

SELECT 'C7B-03', 'preparacion valida: encabezado dentro de la transaccion', 1, n,
       iif(n = 1, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM pedido_borrador
      WHERE id_local = 'b7b00000-0000-4000-8000-000000000001');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto) VALUES ('b7b00000-0000-4000-8000-000000000001', 9999, 1, 50000); -- C7B_SENTENCIA_INVALIDA

SELECT 'C7B-04', 'item invalido no grabado (dentro de la transaccion)', 0, n,
       iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM item_borrador
      WHERE id_local = 'b7b00000-0000-4000-8000-000000000001');
ROLLBACK;

SELECT 'C7B-05', 'pedido_borrador tras ROLLBACK', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM pedido_borrador
      WHERE id_local = 'b7b00000-0000-4000-8000-000000000001');

SELECT 'C7B-06', 'item_borrador tras ROLLBACK', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM item_borrador
      WHERE id_local = 'b7b00000-0000-4000-8000-000000000001');

SELECT 'C7B-07', 'cola_sync tras ROLLBACK', 0, n, iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM cola_sync
      WHERE id_local = 'b7b00000-0000-4000-8000-000000000001');

-- -----------------------------------------------------------------------------
-- Estado final: solo queda el borrador confirmado; base íntegra
-- -----------------------------------------------------------------------------
.print '== Estado final'
SELECT 'FIN-01', 'filas finales pedido_borrador | item_borrador | cola_sync', '1|2|1', n,
       iif(n = '1|2|1', 'OK', 'FALLA')
FROM (SELECT (SELECT COUNT(*) FROM pedido_borrador) || '|'
          || (SELECT COUNT(*) FROM item_borrador) || '|'
          || (SELECT COUNT(*) FROM cola_sync) AS n);

SELECT 'FIN-02', 'violaciones de claves foraneas (foreign_key_check)', 0, n,
       iif(n = 0, 'OK', 'FALLA')
FROM (SELECT COUNT(*) AS n FROM pragma_foreign_key_check);

SELECT 'FIN-03', 'integrity_check', 'ok', integrity_check,
       iif(integrity_check = 'ok', 'OK', 'FALLA')
FROM pragma_integrity_check;
