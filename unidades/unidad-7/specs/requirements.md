# Requirements — Unidad 7: NoSQL y nuevas formas de almacenamiento

**Trabajo Práctico — Unidad 7 / Semana 11**
Base de Datos II — UTN
**Integrantes:** Avalos Pablo · Blangetti Sofia · Suarez Ismael

> Sin restricción de extensión para este documento (a diferencia de SPEC_U6,
> que tenía límite de una página). La consigna de U7 no impone ese límite.

---

## Fuentes

| Fuente | Estado |
|---|---|
| Consigna oficial TP U7 (PDF adjunto) | Disponible — leída en esta sesión |
| Apunte teórico U7 (PDF adjunto, Food Store) | Disponible — leído en esta sesión |
| Apunte teórico U7 (PDF adjunto, general) | Disponible — leído en esta sesión |
| `schema.sql` de `foodstore_baseII` etiqueta `u6-cierre` | Disponible — leído |
| `datos_iniciales.sql` de `foodstore_baseII` etiqueta `u6-cierre` | Disponible — leído |
| `AGENTS.md` de `foodstore_baseII` | Disponible — leído |

---

## Contexto del sistema de origen

El modelo relacional de Food Store comprende cinco tablas:
`categoria`, `usuario`, `producto`, `pedido`, `detalle_pedido`.

El dataset del seed contiene:
- 3 usuarios (Ana Gómez, Luis Paz, Marta Ruiz)
- 2 categorías (Pizzas, Bebidas)
- 3 productos (Muzzarella 1050.00, Napolitana 1500.00, Coca 1.5L 800.00)
- **5 pedidos**, todos con estado `TERMINADO`
- 7 líneas de detalle; Muzzarella aparece en 3 pedidos con dos precios históricos distintos (1000.00 y 1050.00)

Los IDs concretos los asigna la secuencia de PostgreSQL al instalar el seed;
son IDs a comprobar mediante lectura del origen existente.
La lectura del 2026-11-06 sobre la base `foodstore` del contenedor
`foodstore-u6-evaluacion` confirmó los conteos del seed (2, 3, 3, 5 y 7, sin
bajas lógicas) y registró los IDs reales: pedidos 1–5, usuarios 1–3,
productos 1–3 y detalles 1–7 (ver [inventario](../docs/inventario_origen_entorno.md)).

---

## Requisitos de la consigna (Parte 1 — Modelo documental y migración)

### REQ-U7-01 — Selección del subconjunto

Seleccionar el subconjunto «pedidos y detalle de pedidos» de Food Store.
Identificar las tablas y claves de PostgreSQL que intervienen.

**Criterio de aceptación:** el documento de diseño lista las tablas
(`pedido`, `detalle_pedido`, `usuario`, `producto`) y las claves relevantes
(`pedido.id`, `detalle_pedido.pedido_id`, `detalle_pedido.producto_id`,
`pedido.usuario_id`).

### REQ-U7-02 — Esquema documental

Elaborar un esquema breve de la colección propuesta, indicando:
- Campos principales del documento raíz.
- Objeto(s) embebido(s).
- Arreglo de líneas.
- Identificadores conservados desde el origen.

**Criterio de aceptación:** el diseño muestra la estructura del documento
y justifica qué se embebe y por qué.

### REQ-U7-03 — Migración de al menos cinco pedidos

Crear una base y una colección en MongoDB (el equipo eligió `foodstore_u7` y
`pedidos`; ver la tabla final). Migrar un mínimo de **cinco pedidos** con sus
líneas y datos esenciales del usuario. Los documentos deben incluir: fecha, estado, usuario (identificador
y nombre/apellido), líneas de detalle (producto identificador y nombre,
cantidad, precio histórico), y total.

**Criterio de aceptación:**
- `db.pedidos.countDocuments()` devuelve ≥ 5; el lote del equipo son los
  pedidos 1–5.
- Cada documento contiene los campos requeridos, con los tipos de
  `design.md` §2–§3 (`_id` y demás IDs `Long`, cantidad `Int32`, importes
  `Decimal128`, fecha `"YYYY-MM-DD"`).
- Los IDs, fechas, estados, cantidades e importes coinciden con el origen.
- El precio de cada línea es el `precio_unitario` histórico de
  `detalle_pedido`, no el precio actual de `producto`.

### REQ-U7-04 — Dos reglas de integridad y justificación del embebido

Indicar dos reglas de integridad que deben conservarse durante la migración
y justificar qué datos se incluyeron dentro del documento en lugar de
almacenarse en colecciones separadas.

**Criterio de aceptación:** el diseño declara dos reglas verificables y explica
la decisión de embebido en términos de las consultas de la Parte 2. Reglas
adoptadas por el equipo (`design.md` §6):

- **RI-01:** cantidad entera positiva e importes no negativos en todas las
  líneas, incluidas las eliminadas lógicamente.
- **RI-02:** subtotal igual a cantidad × precio histórico en cada línea; total
  igual a la suma de subtotales de líneas no eliminadas, o cero si no hay
  ninguna.

Los importes se copian y se verifican; no se corrigen en silencio.

---

## Requisitos de la consigna (Parte 2 — Consultas y verificación)

### REQ-U7-05 — Cuatro consultas en MongoDB

Ejecutar las siguientes cuatro consultas adaptadas a los nombres reales del
modelo implementado:

| Consulta | Descripción |
|---|---|
| C4a | Mostrar todos los pedidos incluyendo identificador y estado |
| C4b | Filtrar pedidos por un estado que exista en los datos migrados |
| C4c | Buscar pedidos que contengan un producto determinado dentro del arreglo de líneas |
| C4d | Buscar pedidos cuyo total sea superior a un importe elegido y justificar el umbral |

**Criterio de aceptación:** cada consulta se ejecuta sin errores y devuelve
el conjunto esperado dado el dataset. C4b y C4c se usan también en REQ-U7-06.

Filtros adoptados por el equipo (`design.md` §7): todas las consultas se
limitan al lote; C4b, C4c y C4d excluyen pedidos eliminados; C4c exige el
producto y `eliminado = false` en la misma línea (`$elemMatch`). Parámetros
fijados tras la lectura: estado `TERMINADO`, `producto_id = 1` (Muzzarella) y
`total > 3000.00`.

### REQ-U7-06 — Consultas equivalentes en PostgreSQL y comparación

Resolver en PostgreSQL las consultas equivalentes a C4b (por estado) y C4c
(por producto). Comparar en una tabla la cantidad y los identificadores de
pedidos recuperados en ambos motores.

**Formato de evidencia requerido:**

| Consulta | Cantidad PostgreSQL | Cantidad MongoDB | IDs coinciden |
|---|---|---|---|
| Estado seleccionado | — | — | Sí / No |
| Producto seleccionado | — | — | Sí / No |

**Criterio de aceptación:**
- El mismo subconjunto de pedidos (mismo estado, mismo producto) se usa en
  ambos motores, con la misma lista de IDs del lote y los mismos filtros de
  baja lógica.
- Se cuentan pedidos distintos, no líneas.
- Las diferencias se explican y se corrige el modelo o la consulta cuando
  corresponda.
- No basta con que la consulta se ejecute sin errores; debe devolver el
  conjunto correcto.

---

## Requisitos de la consigna (Parte 3 — Evaluación de la tecnología e IA)

### REQ-U7-07 — Consulta a IA y contraste de dos afirmaciones

Utilizar una herramienta de IA para comparar PostgreSQL y MongoDB respecto del
almacenamiento y la consulta de pedidos de Food Store. La consulta debe
mencionar el modelo actual, el acceso frecuente a pedidos completos y la
necesidad de conservar coherencia de cantidades y precios.

**Criterio de aceptación:**
- Se registran el prompt enviado y la respuesta relevante recibida.
- Se contrastan **dos afirmaciones concretas** de la respuesta con documentación
  oficial o resultados del laboratorio.
- La conclusión (hasta 200 palabras) indica si conviene mantener PostgreSQL,
  usar MongoDB para el subconjunto o combinar tecnologías, fundamentada en
  al menos dos criterios técnicos.

---

## Requisitos de entrega

### REQ-U7-08 — Entregables físicos

| Entregable | Descripción |
|---|---|
| PDF de hasta 5 páginas | Modelo sintético, evidencias de colección y consultas, tabla de verificación, contraste de IA, conclusión |
| `consultas_mongodb.js` (o nombre equivalente) | Instrucciones mongosh ejecutadas |
| `consultas_postgresql.sql` (o nombre equivalente) | Consultas SQL equivalentes ejecutadas |

Las evidencias pueden consistir en capturas legibles o salidas de ejecución.
No se incorporan imágenes decorativas, transcripciones extensas de
conversaciones ni datos personales reales.

---

## Separación: requisitos docentes vs. decisiones técnicas del equipo

| Requisito | Origen |
|---|---|
| Cinco pedidos mínimos | Consigna (§ Alcance sugerido) |
| Fecha, estado, cliente, productos, cantidades y precios históricos | Consigna (Consigna 2) |
| Dos reglas de integridad y justificación del embebido | Consigna (Consigna 3) |
| Las cuatro consultas C4a–C4d | Consigna (Consigna 4) |
| Comparación con PostgreSQL para b) y c) | Consigna (Consigna 5) |
| Consulta a IA y contraste de dos afirmaciones | Consigna (Consignas 6 y 7) |
| Base `foodstore_u7`, colección `pedidos` | Decisión del equipo (ver design.md) |
| Un documento por pedido con cliente y líneas embebidas | Decisión del equipo (ver design.md) |
| Uso de `Decimal128` para importes | Decisión del equipo (ver design.md) |
| `_id` = `pedido.id` como `Long`; IDs desde texto; cantidad `Int32`; fecha `"YYYY-MM-DD"` | Decisión del equipo, encargo del 2026-11-06 |
| Conservar bajas lógicas y filtrar en las consultas (C4b–C4d) | Decisión del equipo, encargo del 2026-11-06 |
| RI-01 y RI-02 en su forma de `design.md` §6 | Decisión del equipo, encargo del 2026-11-06 |
| Detener la carga ante IDs existentes; sin upserts ni borrados | Decisión del equipo, encargo del 2026-11-06 |
| Lote 1–5, estado `TERMINADO`, producto 1, umbral 3000.00 | Decisión del equipo tras la lectura del 2026-11-06 |

Las decisiones del equipo no son aprobaciones docentes.
