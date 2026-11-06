# Inventario del origen y del entorno — Unidad 7

**Fecha:** 2026-11-06 · **Alcance:** comprobaciones del entorno, lectura de
solo lectura del origen PostgreSQL y descarga de la imagen MongoDB.
**No es una extracción ni una migración.** No se escribió en PostgreSQL ni se
inició MongoDB.

> **Documento histórico.** Registra el estado del 2026-11-06 antes de la
> migración, y sus secciones §5 y §7 describen ese momento. El estado vigente
> (MongoDB 9.0.4, carga, validaciones y consultas ejecutadas) está en
> [laboratorio_migracion.md](laboratorio_migracion.md).

El trabajo se hizo en dos intervenciones del mismo día:

1. **Primera inspección (bloqueada):** se revisaron los documentos y el entorno.
   El contenedor de origen estaba detenido y no había autorización para
   iniciarlo, así que no se leyó ningún dato.
2. **Segunda intervención:** con autorización para iniciar ese contenedor, se
   hizo la lectura real (§3) y se descargó `mongo:8.0` (§5).

---

## 1. Repositorios

| Elemento | Observado |
|---|---|
| Repositorio de trabajo | `foodstore_nosql_movil`, rama `main`, sin commits previos, sin remotos |
| Repositorio relacional | `foodstore_baseII`, `HEAD` = etiqueta anotada `u6-cierre` = `8f7877c8a1ff25c1be28b29c46c38cd7c9663e86`; solo `odd/` sin seguimiento (no se tocó) |

Archivos de origen leídos con `git show u6-cierre:<ruta>`, sin cambiar de rama:
`schema.sql`, `datos_iniciales.sql`, `tpi/sql/objetos_programables.sql`,
`unidades/unidad-6/README.md` y `unidades/unidad-6/EVALUACION.md`.

## 2. Comprobaciones previas sin conexión

| Herramienta | Resultado |
|---|---|
| Bash | GNU bash 5.3.9; la shell de login es fish |
| Docker | Cliente y servidor 29.9.3; host `x86_64` |
| `psql` / `pg_dump` en el host | No disponibles; se usan los del contenedor |
| `mongosh`, `mongod`, `mongoimport`, `mongoexport`, Compass | No encontrados en el host |
| Imágenes PostgreSQL | `postgres:17` (`2d2b8998d310`), `postgres:17.9-bookworm`, `postgres:16` |

Identidad de `foodstore-u6-evaluacion` comprobada con `docker inspect`, sin
leer variables de entorno ni archivos de credenciales:

| Atributo | Valor | Coincide con U6 |
|---|---|---|
| ID | `e46713bd8004f4e004c78fd696f4c9a1e5205ebe5d993072519951ee1bb4eb8c` | Sí (`docs/ensayo_evaluacion.md`) |
| Imagen | `postgres:17`, `sha256:2d2b8998d310…` | Sí |
| Volumen de datos | `foodstore_u6_evaluacion_data` | Sí |
| Red | `NetworkMode=none`; sin `PortBindings` ni `PublishAllPorts` | Sí, aislado |
| Autenticación | bind de solo lectura en `/run/foodstore-u6-auth`; el directorio de origen existe (no se leyó su contenido) | Sí (`EVALUACION.md`) |

En la primera inspección el estado era `exited` (detenido el 2026-11-06
02:20:35 UTC) y la lectura no se hizo. En la segunda, con la identidad
confirmada otra vez, se ejecutó `docker start foodstore-u6-evaluacion` a las
14:50:47 UTC. `pg_isready -h 127.0.0.1` respondió en el segundo intento, de un
máximo de 30. **El contenedor queda en ejecución**, sin cambios de
configuración.

## 3. Lectura ejecutada

Se ejecutó una vez, en Bash, con código de salida 0:

```bash
docker exec -i foodstore-u6-evaluacion \
  psql -X -w -U postgres -d foodstore -v ON_ERROR_STOP=1 -P pager=off -f - <<'SQL'
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY;
SELECT current_setting('transaction_isolation') AS isolation,
       current_setting('transaction_read_only') AS read_only;
-- Q1 identidad y versión
SELECT current_database() AS base, d.oid AS base_oid, current_user, session_user,
       current_setting('server_version') AS server_version,
       inet_server_addr() AS addr, inet_server_port() AS port
FROM pg_database d WHERE d.datname = current_database();
-- Q2 conteos, con bajas lógicas
SELECT t.tabla, t.total, t.eliminados FROM (
  SELECT 1 o, 'categoria' tabla, count(*) total, count(*) FILTER (WHERE eliminado) eliminados FROM categoria
  UNION ALL SELECT 2, 'usuario', count(*), count(*) FILTER (WHERE eliminado) FROM usuario
  UNION ALL SELECT 3, 'producto', count(*), count(*) FILTER (WHERE eliminado) FROM producto
  UNION ALL SELECT 4, 'pedido', count(*), count(*) FILTER (WHERE eliminado) FROM pedido
  UNION ALL SELECT 5, 'detalle_pedido', count(*), count(*) FILTER (WHERE eliminado) FROM detalle_pedido
) t ORDER BY t.o;
-- Q3 pedidos
SELECT id AS pedido_id, usuario_id, fecha, estado, forma_pago, total, eliminado
FROM pedido ORDER BY id;
-- Q4 usuarios relacionados: solo id y existencia
SELECT p.usuario_id, count(*) AS pedidos, (u.id IS NOT NULL) AS existe
FROM pedido p LEFT JOIN usuario u ON u.id = p.usuario_id
GROUP BY p.usuario_id, u.id ORDER BY p.usuario_id;
-- Q5 detalles
SELECT dp.id AS detalle_id, dp.pedido_id, dp.producto_id, dp.cantidad,
       dp.precio_unitario, dp.subtotal, dp.eliminado
FROM detalle_pedido dp ORDER BY dp.pedido_id, dp.id;
-- Q6 productos referenciados; el nombre es descriptivo, no clave
SELECT pr.id AS producto_id, pr.nombre, pr.precio AS precio_catalogo_actual,
       pr.disponible, pr.eliminado,
       count(DISTINCT dp.pedido_id) AS pedidos_con_linea,
       string_agg(DISTINCT dp.precio_unitario::text, ', ') AS precios_historicos
FROM producto pr JOIN detalle_pedido dp ON dp.producto_id = pr.id
GROUP BY pr.id ORDER BY pr.id;
-- Q7 RI-01 en todas las líneas, y total no negativo
SELECT count(*) FILTER (WHERE cantidad <= 0) AS cantidad_no_positiva,
       count(*) FILTER (WHERE precio_unitario < 0) AS precio_negativo,
       count(*) FILTER (WHERE subtotal < 0) AS subtotal_negativo
FROM detalle_pedido;
SELECT count(*) FILTER (WHERE total < 0) AS total_negativo FROM pedido;
-- Q8 RI-02a: subtotal = cantidad * precio_unitario
SELECT id, subtotal, cantidad * precio_unitario AS calculado
FROM detalle_pedido WHERE subtotal IS DISTINCT FROM cantidad * precio_unitario;
-- Q9 RI-02b: total = suma de subtotales no eliminados, o 0
SELECT p.id, p.total, x.total_calculado
FROM pedido p CROSS JOIN LATERAL (
  SELECT COALESCE(SUM(dp.subtotal), 0) AS total_calculado
  FROM detalle_pedido dp WHERE dp.pedido_id = p.id AND dp.eliminado = FALSE) x
WHERE p.total IS DISTINCT FROM x.total_calculado;
-- Q10 estados
SELECT estado, eliminado, count(*) AS pedidos FROM pedido GROUP BY 1, 2 ORDER BY 1, 2;
-- Q11 estadísticos de totales
SELECT count(*) AS n, min(total), max(total), round(avg(total), 2) AS promedio,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY total) AS mediana
FROM pedido WHERE eliminado = FALSE;
ROLLBACK;
SQL
```

No se seleccionaron `usuario.*`, `contrasena`, `mail`, `celular`, `rol`,
`nombre` ni `apellido`. No se ejecutaron seed, funciones de negocio, DML, DDL
ni mantenimiento.

### 3.1. Resultados observados

**Transacción:** `repeatable read`, `read_only = on`; terminó con `ROLLBACK`.

**Q1:** base `foodstore`, OID 16384 (el mismo del ensayo U6), `current_user` y
`session_user` `postgres`, PostgreSQL `17.11 (Debian 17.11-1.pgdg13+2)`,
`127.0.0.1:5432`.

**Q2:** categoria 2, usuario 3, producto 3, pedido 5, detalle_pedido 7. Ninguna
fila con `eliminado = true` en ninguna tabla.

**Q3, pedidos:**

| pedido_id | usuario_id | fecha | estado | forma_pago | total | eliminado |
|---|---|---|---|---|---|---|
| 1 | 1 | 2026-03-01 | TERMINADO | EFECTIVO | 2800.00 | f |
| 2 | 2 | 2026-03-01 | TERMINADO | TARJETA | 1500.00 | f |
| 3 | 1 | 2026-03-05 | TERMINADO | TRANSFERENCIA | 3150.00 | f |
| 4 | 3 | 2026-03-06 | TERMINADO | EFECTIVO | 6200.00 | f |
| 5 | 2 | 2026-03-07 | TERMINADO | TARJETA | 1050.00 | f |

**Q4:** usuario 1 tiene 2 pedidos, usuario 2 tiene 2 y usuario 3 tiene 1.
Los tres existen.

**Q5, detalles:**

| detalle_id | pedido_id | producto_id | cantidad | precio_unitario | subtotal | eliminado |
|---|---|---|---|---|---|---|
| 1 | 1 | 1 | 2 | 1000.00 | 2000.00 | f |
| 2 | 1 | 3 | 1 | 800.00 | 800.00 | f |
| 3 | 2 | 2 | 1 | 1500.00 | 1500.00 | f |
| 4 | 3 | 1 | 3 | 1050.00 | 3150.00 | f |
| 5 | 4 | 3 | 4 | 800.00 | 3200.00 | f |
| 6 | 4 | 2 | 2 | 1500.00 | 3000.00 | f |
| 7 | 5 | 1 | 1 | 1050.00 | 1050.00 | f |

**Q6, productos:**

| producto_id | nombre | precio actual | disponible | eliminado | pedidos | precios históricos |
|---|---|---|---|---|---|---|
| 1 | Muzzarella | 1050.00 | t | f | 3 | 1000.00, 1050.00 |
| 2 | Napolitana | 1500.00 | t | f | 2 | 1500.00 |
| 3 | Coca 1.5L | 800.00 | t | f | 2 | 800.00 |

**Controles:**
- Q7: 0 cantidades no positivas, 0 precios negativos, 0 subtotales negativos y
  0 totales negativos.
- Q8: 0 filas, todos los subtotales coinciden.
- Q9: 0 filas, todos los totales coinciden.

**Q10:** solo `TERMINADO` con `eliminado = f`, 5 pedidos.

**Q11:** n = 5, mínimo 1050.00, máximo 6200.00, promedio 2940.00,
mediana 2800.

### 3.2. Esperado frente a leído

| Dato | Esperado según seed y evidencias U6 | Leído el 2026-11-06 |
|---|---|---|
| Conteos | 2, 3, 3, 5 y 7, sin bajas | Igual |
| Estados | Todos `TERMINADO` | Igual |
| Totales | 2800, 1500, 3150, 6200 y 1050 | Igual, con `pedido_id` 1–5 en ese orden |
| IDs | No deducibles: los pedidos se insertan en CTE modificadoras de un mismo `WITH`, sin orden garantizado | Pedidos 1–5, usuarios 1–3, productos 1–3, detalles 1–7 |

Los IDs coinciden con el orden textual del seed, pero eso se sabe **por la
lectura**, no porque el seed lo garantice.

## 4. Lote y filtros seleccionados

| Elemento | Selección | Motivo |
|---|---|---|
| Lote | Pedidos **1, 2, 3, 4, 5** | El origen tiene exactamente los cinco esperados; no se agregan registros |
| Estado (C4b) | `TERMINADO` | Es el único presente. Devuelve el lote completo; no se inventa variedad |
| Producto (C4c) | `producto_id = 1` (Muzzarella) | Aparece en tres pedidos (1, 3 y 5) y es el único con dos precios históricos |
| Umbral (C4d) | `total > 3000.00` | Importe redondo apenas superior al promedio (2940.00). Ningún total es igual a 3000.00 |
| Datos del cliente | `usuario_id` (1, 2, 3), `nombre` y `apellido` sintéticos | Se extraerán en T2b; no se consultaron todavía |

Filtros de `design.md` §7: todo se limita al lote; C4b, C4c y C4d exigen pedido
no eliminado; C4c exige producto y línea no eliminada en la misma línea. Como no
hay bajas lógicas en el lote, esos filtros no cambian los resultados, pero se
mantienen.

Resultados esperados a partir de la lectura, **todavía no ejecutados como
consultas en ningún motor**: C4b → 5 (1–5), C4c → 3 (1, 3, 5), C4d → 2 (3, 4).

Las propuestas de la primera inspección (`TERMINADO`, Muzzarella y
`> 3000.00`) quedan confirmadas por los datos leídos.

## 5. Imagen MongoDB

| Dato | Valor |
|---|---|
| Referencia solicitada | `mongo:8.0` (resuelta como `docker.io/library/mongo:8.0`) |
| Descarga | 2026-11-06, de 14:51:16 a 14:52:36 UTC, código 0 |
| ID | `sha256:b9924c330a8bbc5800fe9c69f04a84e221eca7b28fd049a0354147d9908fa142` |
| RepoDigest | `mongo@sha256:b9924c330a8bbc5800fe9c69f04a84e221eca7b28fd049a0354147d9908fa142` |
| Arquitectura | `linux/amd64` |
| Creación de la imagen | 2026-10-26T23:25:57Z |

La preparación posterior usará `mongo@sha256:b9924c33…fa142`, no una nueva
resolución de la etiqueta.

**El servidor no se inició.** No se crearon contenedores, volúmenes, redes,
usuarios, bases ni colecciones. La etiqueta OCI `version` de la imagen vale
`24.04` y corresponde a la base del sistema, no a MongoDB. La versión exacta de
`mongod` y la compatibilidad local quedan **sin comprobar**.

## 6. Estado de las observaciones de la primera inspección

| # | Observación | Resolución |
|---|---|---|
| O1 | Filtros de baja lógica en C4b y C4c | Adoptado: `design.md` §4 y §7 |
| O2 | Mismo lote en PostgreSQL | Adoptado: lista explícita 1–5 (`design.md` §7.1) |
| O3 | Duplicados al repetir la carga | Adoptado: `_id` = `pedido.id` y detención ante colisión (`design.md` §1 y §8) |
| O4 | Referencia del origen en T2 | Corregido en `tasks.md` |
| O5 | `psql` y `pg_dump` en el host | Corregido en `tasks.md` |
| O6 | Alcance de RI-01 y control del subtotal | Adoptado: RI-01 en todas las líneas; RI-02 incluye el subtotal (`design.md` §6) |
| O7 | Base atribuida a la consigna | Corregido en `requirements.md` REQ-U7-03 |
| O8 | Tipos numéricos en `mongosh` | **Corregido:** en la primera inspección se afirmó que los literales eran siempre `Double`. `mongosh` usa `Int32` cuando el entero cabe en ese tipo y `Double` en otros casos. Se fijan tipos explícitos (`design.md` §3) |

## 7. Pendiente

- T2b: extraer nombre y apellido sintéticos de los usuarios 1–3 y los nombres
  de producto.
- T3–T5: iniciar MongoDB desde el digest registrado, crear el script de carga,
  verificar RI-01 y RI-02 y ejecutar las consultas en ambos motores.
- Comprobar la versión real de `mongod` al iniciar el servidor.
- Aprobación docente del modelo: no la hay. Las decisiones son del equipo.
