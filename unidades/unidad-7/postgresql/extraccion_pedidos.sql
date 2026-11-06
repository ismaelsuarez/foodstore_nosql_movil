-- Food Store U7 — Extracción del lote aprobado (pedidos 1–5) a JSON.
-- Solo lectura: REPEATABLE READ, READ ONLY y ROLLBACK final.
-- Uso (Bash, desde la raíz del repositorio):
--   docker exec -i foodstore-u6-evaluacion \
--     psql -X -w -q -A -t -U postgres -d foodstore -v ON_ERROR_STOP=1 -f - \
--     < unidades/unidad-7/postgresql/extraccion_pedidos.sql > SALIDA.json
-- Salida: un único documento JSON. IDs, cantidades e importes viajan como
-- texto para no pasar por números de punto flotante.
-- Del usuario se leen solo id, nombre y apellido, y únicamente se exportan si
-- coinciden con los usuarios sintéticos 1–3 del seed (datos_iniciales.sql).

\set ON_ERROR_STOP on

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY;

-- Controles previos. Cualquier fallo detiene la extracción sin generar JSON.
DO $$
DECLARE
    -- Mantener igual al lote de la consulta de exportación (más abajo).
    v_lote CONSTANT bigint[] := ARRAY[1, 2, 3, 4, 5];
    v_n bigint;
BEGIN
    SELECT count(*) INTO v_n FROM pedido WHERE id = ANY (v_lote);
    IF v_n <> cardinality(v_lote) THEN
        RAISE EXCEPTION 'Lote incompleto: % de % pedidos', v_n, cardinality(v_lote);
    END IF;

    -- Referencias faltantes: un JOIN interno perdería estas filas.
    SELECT count(*) INTO v_n
    FROM detalle_pedido dp
    LEFT JOIN producto pr ON pr.id = dp.producto_id
    WHERE dp.pedido_id = ANY (v_lote) AND pr.id IS NULL;
    IF v_n > 0 THEN
        RAISE EXCEPTION '% líneas del lote sin producto', v_n;
    END IF;

    SELECT count(*) INTO v_n
    FROM pedido p
    LEFT JOIN usuario u ON u.id = p.usuario_id
    WHERE p.id = ANY (v_lote) AND u.id IS NULL;
    IF v_n > 0 THEN
        RAISE EXCEPTION '% pedidos del lote sin usuario', v_n;
    END IF;

    -- RI-01 en todas las líneas del lote, incluidas las eliminadas.
    SELECT count(*) INTO v_n
    FROM detalle_pedido
    WHERE pedido_id = ANY (v_lote)
      AND (cantidad <= 0 OR precio_unitario < 0 OR subtotal < 0);
    IF v_n > 0 THEN
        RAISE EXCEPTION 'RI-01: % líneas con cantidad o importes inválidos', v_n;
    END IF;

    -- RI-02: subtotal = cantidad × precio histórico.
    SELECT count(*) INTO v_n
    FROM detalle_pedido
    WHERE pedido_id = ANY (v_lote)
      AND subtotal IS DISTINCT FROM cantidad * precio_unitario;
    IF v_n > 0 THEN
        RAISE EXCEPTION 'RI-02: % líneas con subtotal incoherente', v_n;
    END IF;

    -- RI-02: total = suma de subtotales no eliminados, o cero.
    SELECT count(*) INTO v_n
    FROM pedido p
    WHERE p.id = ANY (v_lote)
      AND (p.total < 0 OR p.total IS DISTINCT FROM (
          SELECT COALESCE(sum(dp.subtotal), 0)
          FROM detalle_pedido dp
          WHERE dp.pedido_id = p.id AND dp.eliminado = FALSE));
    IF v_n > 0 THEN
        RAISE EXCEPTION 'RI-02: % pedidos con total incoherente', v_n;
    END IF;

    -- Datos del cliente: solo los usuarios sintéticos 1–3 del seed.
    -- El mensaje no muestra nombres para no difundir datos ajenos.
    SELECT count(*) INTO v_n
    FROM pedido p
    JOIN usuario u ON u.id = p.usuario_id
    WHERE p.id = ANY (v_lote)
      AND (u.id NOT IN (1, 2, 3)
           OR (u.nombre, u.apellido) NOT IN
              (('Ana', 'Gómez'), ('Luis', 'Paz'), ('Marta', 'Ruiz')));
    IF v_n > 0 THEN
        RAISE EXCEPTION '% pedidos con usuarios ajenos al seed sintético; no se exportan', v_n;
    END IF;
END;
$$;

-- Exportación. Orden determinista: pedidos por id y líneas por id.
-- Se usa json (no jsonb) para conservar el orden de las claves.
WITH lote (id) AS (
    SELECT unnest(ARRAY[1, 2, 3, 4, 5]::bigint[])
), lineas AS (
    SELECT dp.pedido_id,
           count(*) AS n,
           json_agg(json_build_object(
               'detalle_id', dp.id::text,
               'producto_id', dp.producto_id::text,
               'producto_nombre', pr.nombre,
               'cantidad', dp.cantidad::text,
               'precio_unitario', dp.precio_unitario::text,
               'subtotal', dp.subtotal::text,
               'eliminado', dp.eliminado
           ) ORDER BY dp.id) AS items
    FROM detalle_pedido dp
    JOIN lote l ON l.id = dp.pedido_id
    LEFT JOIN producto pr ON pr.id = dp.producto_id
    GROUP BY dp.pedido_id
), pedidos AS (
    SELECT count(*) AS n_pedidos,
           COALESCE(sum(li.n), 0) AS n_lineas,
           json_agg(json_build_object(
               'pedido_id', p.id::text,
               'fecha', to_char(p.fecha, 'YYYY-MM-DD'),
               'estado', p.estado::text,
               'forma_pago', p.forma_pago::text,
               'total', p.total::text,
               'eliminado', p.eliminado,
               'usuario', json_build_object(
                   'usuario_id', u.id::text,
                   'nombre', u.nombre,
                   'apellido', u.apellido),
               'items', COALESCE(li.items, '[]'::json)
           ) ORDER BY p.id) AS datos
    FROM pedido p
    JOIN lote l ON l.id = p.id
    JOIN usuario u ON u.id = p.usuario_id
    LEFT JOIN lineas li ON li.pedido_id = p.id
)
SELECT json_build_object(
    'formato', 'foodstore-u7-pedidos/1',
    'origen', json_build_object(
        'base', current_database(),
        'base_oid', (SELECT oid FROM pg_database
                     WHERE datname = current_database())::text,
        'servidor', current_setting('server_version'),
        'rol_conexion', current_user,
        'referencia_esquema', 'foodstore_baseII u6-cierre 8f7877c8a1ff25c1be28b29c46c38cd7c9663e86 (declarada; SQL no la verifica)'),
    'extraccion', json_build_object(
        'momento_utc', to_char(transaction_timestamp() AT TIME ZONE 'UTC',
                               'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'aislamiento', current_setting('transaction_isolation'),
        'solo_lectura', current_setting('transaction_read_only'),
        'script', 'unidades/unidad-7/postgresql/extraccion_pedidos.sql'),
    'lote', (SELECT json_agg(id::text ORDER BY id) FROM lote),
    'expectativas_inventario', json_build_object(
        'pedidos', 5,
        'lineas', 7,
        'fuente', 'unidades/unidad-7/docs/inventario_origen_entorno.md'),
    'conteos_extraidos', json_build_object(
        'pedidos', n_pedidos,
        'lineas', n_lineas),
    -- Huella del texto JSON de "pedidos" tal como lo genera PostgreSQL;
    -- sirve para comparar extracciones sucesivas del mismo origen.
    'sha256_pedidos', encode(sha256(convert_to(datos::text, 'UTF8')), 'hex'),
    'pedidos', datos
)
FROM pedidos;

ROLLBACK;
