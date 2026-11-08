-- Food Store — Unidad 8: vista de instantánea según design.md §5.
-- Conserva bajas de producto y categoría; no expone usuarios ni pedidos.
-- BIGINT permite representar en centavos todo NUMERIC(12,2) finito positivo.
-- Exportar con: bash unidades/unidad-8/postgresql/laboratorio_u8.sh exportar CSV META
-- La exportación usa exportar_snapshot.sql en una única transacción de lectura.
CREATE VIEW v_snapshot_movil AS
SELECT p.id                          AS producto_id,
       p.nombre,
       (p.precio * 100)::BIGINT       AS precio_centavos,
       p.stock,
       p.disponible,
       (p.eliminado OR c.eliminado)   AS eliminado,
       now()                         AS capturado_en
FROM producto p
JOIN categoria c ON c.id = p.categoria_id;
