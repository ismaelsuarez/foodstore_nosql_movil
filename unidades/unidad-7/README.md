# Unidad 7 — NoSQL y nuevas formas de almacenamiento | Food Store

**Bases de Datos II — UTN, Tecnicatura Universitaria en Programación**
**Integrantes:** Avalos Pablo · Blangetti Sofia · Suarez Ismael

**Consigna:** `BDII_Unidad7_TP_FoodStore_NoSQL.pdf`, «Trabajo Práctico ·
Unidad 7 — NoSQL y nuevas formas de almacenamiento | Food Store». Es material
de la cátedra y no se incluye en el repositorio.

## Objetivo y alcance

Representar en MongoDB el subconjunto «pedidos y detalle de pedidos» de Food
Store, consultarlo, comparar los resultados con PostgreSQL y contrastar
recomendaciones de IA con documentación oficial.

- **Lote:** los pedidos 1 a 5 con sus 7 líneas, leídos de la base `foodstore`.
- **Fuera de alcance:** no se migra toda la base, no se configura un clúster y
  no hay sincronización entre motores.
- **Origen:**
  [foodstore_baseII, etiqueta `u6-cierre`](https://github.com/ismaelsuarez/foodstore_baseII/tree/u6-cierre),
  commit `8f7877c8a1ff25c1be28b29c46c38cd7c9663e86`.

## Entregables

| Entregable | Archivo |
|---|---|
| Informe (PDF, 4 páginas) | [informe_u7.pdf](informe_u7.pdf), con fuente editable en [informe_u7.html](informe_u7.html) |
| Consultas MongoDB | [mongodb/consultas_mongodb.js](mongodb/consultas_mongodb.js) |
| Consultas PostgreSQL | [postgresql/consultas_postgresql.sql](postgresql/consultas_postgresql.sql) |

## Las siete consignas

| Consigna | Archivos | Evidencia | Resultado registrado |
|---|---|---|---|
| 1. Subconjunto, tablas, claves y esquema documental | [design.md](specs/design.md) §1–§2, informe §A | [inventario](docs/inventario_origen_entorno.md) §3 | Un documento por pedido, `_id` = `pedido.id` (Long), cliente e `items` embebidos |
| 2. Base, colección y al menos cinco pedidos | [extraccion_pedidos.sql](postgresql/extraccion_pedidos.sql), [pedidos_origen.json](datos/pedidos_origen.json), [migracion_pedidos.js](mongodb/migracion_pedidos.js) | [ejecución 9.0.4](evidencias/ejecucion_20261106_mongo9.txt) | `foodstore_u7.pedidos`: 5 pedidos y 7 líneas insertados (código 0) |
| 3. Dos reglas de integridad y justificación del embebido | [design.md](specs/design.md) §1 y §6, [validaciones_mongodb.js](mongodb/validaciones_mongodb.js) | [ejecución 9.0.4](evidencias/ejecucion_20261106_mongo9.txt) | 12 comprobaciones OK; RI-01 y RI-02 sin incoherencias |
| 4. Cuatro consultas en MongoDB | [consultas_mongodb.js](mongodb/consultas_mongodb.js) | [ejecución 9.0.4](evidencias/ejecucion_20261106_mongo9.txt) | C4a: 1–5 · C4b: 1–5 · C4c: 1, 3, 5 · C4d: 3, 4 |
| 5. Equivalentes en PostgreSQL y comparación | [consultas_postgresql.sql](postgresql/consultas_postgresql.sql) | [ejecución 9.0.4](evidencias/ejecucion_20261106_mongo9.txt) | C4b: 1–5 y C4c: 1, 3, 5 en ambos motores; los IDs coinciden |
| 6. Consulta a una herramienta de IA | [contraste_ia.md](docs/contraste_ia.md) §1 | Prompt y respuesta registrados | La respuesta no es independiente: la generó el mismo asistente |
| 7. Dos afirmaciones contrastadas y conclusión | [contraste_ia.md](docs/contraste_ia.md) §3 y §6, [conclusion_u7.md](docs/conclusion_u7.md) | Fuentes oficiales citadas con fecha | A1 respaldada documentalmente y no ensayada; A2 respaldada; conclusión de 186 palabras pendiente de revisión del equipo |

## Resultados registrados

Son resultados de la ejecución del 2026-11-06, no de pruebas nuevas
([laboratorio §6](docs/laboratorio_migracion.md#6-resultados-observados)):

- **Carga:** 5 pedidos y 7 líneas; `validaciones_mongodb.js` hizo 12
  comprobaciones, todas OK.
- **Comparación entre motores:**

  | Consulta | PostgreSQL | MongoDB | Coinciden |
  |---|---|---|---|
  | C4b, estado `TERMINADO` | 1, 2, 3, 4, 5 | 1, 2, 3, 4, 5 | Sí |
  | C4c, producto 1 en una línea vigente | 1, 3, 5 | 1, 3, 5 | Sí |

- **Solo en MongoDB:** C4a devolvió 1–5 y C4d (`total > 3000.00`) devolvió los
  pedidos 3 y 4.
- **Repetición:** la segunda carga se rechazó antes de escribir (código 3) y el
  contenido no cambió.

## Entorno

| Componente | Versión |
|---|---|
| Origen | PostgreSQL 17.11, contenedor `foodstore-u6-evaluacion`, base `foodstore` |
| Destino | MongoDB 9.0.4 y `mongosh` 2.14.0, imagen `mongo@sha256:452bdaf2…a058`, instancia standalone sin red |

Antecedente: `mongo:8.0` no arrancó en el kernel del host
([laboratorio §3](docs/laboratorio_migracion.md#3-versión-elegida-y-antecedente)).

## Límites

- Cinco pedidos, un solo estado (`TERMINADO`) y ninguna baja lógica en el lote.
- No se midió rendimiento.
- Sin validadores permanentes en la colección.
- No se probaron un fallo parcial de `insertMany` ni transacciones.
- La coincidencia entre motores es una verificación puntual, no una
  sincronización.

## Orden de lectura

1. [informe_u7.pdf](informe_u7.pdf).
2. [EVALUACION.md](EVALUACION.md): cómo revisar y cómo reproducir.
3. [specs/design.md](specs/design.md): modelo, tipos, reglas y consultas.
4. Scripts: [postgresql/](postgresql/) y [mongodb/](mongodb/).
5. [evidencias/README.md](evidencias/README.md): extractos y huellas.
6. [docs/contraste_ia.md](docs/contraste_ia.md) y
   [docs/conclusion_u7.md](docs/conclusion_u7.md).
7. Antecedentes: [inventario](docs/inventario_origen_entorno.md),
   [requisitos](specs/requirements.md), [tareas](specs/tasks.md) y
   [bitácora de IA](docs/bitacora_ia.md).
