# Contraste de IA — Unidad 7 (consignas 6 y 7)

## 1. Consulta realizada

| Dato | Valor |
|---|---|
| Herramienta | Asistente de programación «el Gentleman» sobre el entorno Pi (Claude Code / Claude Agent SDK) |
| Modelo | Claude Opus 5.5 (`claude-opus-5-5`), según la información de sesión disponible para el asistente |
| Fecha | 2026-11-06 |
| Contexto | El mismo asistente que implementó la migración generó la respuesta en la misma sesión. No es una consulta independiente del laboratorio (ver §5) |

La respuesta se generó y se guardó en este archivo **antes** de leer la
documentación usada en el contraste.

### 1.1. Prompt enviado

> Compará PostgreSQL y MongoDB para almacenar y consultar los pedidos de
> nuestro Food Store.
>
> El origen PostgreSQL tiene las tablas categoria, usuario, producto, pedido y
> detalle_pedido, con identificadores, claves foráneas, restricciones y lógica
> programable para subtotales y totales.
>
> En MongoDB representamos cinco pedidos como documentos con cliente e items
> embebidos. Conservamos IDs Long, cantidades Int32, importes Decimal128 y los
> precios históricos.
>
> El acceso frecuente consiste en recuperar un pedido completo. Necesitamos
> conservar cantidades positivas, subtotales coherentes y el total de las
> líneas no eliminadas.
>
> Explicá ventajas, costos y responsabilidades de integridad de ambas
> alternativas. Diferenciá capacidades del motor de lo que efectivamente
> implementamos. No afirmes mejoras de rendimiento que no medimos ni que
> MongoDB carezca de transacciones o validación.

### 1.2. Respuesta recibida (texto completo, sin editar)

> **PostgreSQL (modelo actual)**
>
> *Ventajas.* Cada pedido se reparte en `pedido` y `detalle_pedido`, con
> referencias a `usuario` y `producto`. El motor hace cumplir la integridad en
> cada escritura: las claves foráneas impiden líneas sin pedido o sin producto,
> y las restricciones `CHECK` rechazan cantidades no positivas o importes
> negativos. Las transacciones ACID permiten modificar varias filas y tablas
> como una unidad. Los datos del cliente y del catálogo no se duplican.
>
> *Costos.* Recuperar un pedido completo exige unir varias tablas. Una
> restricción `CHECK` evalúa solo la fila que se inserta o actualiza; no puede
> comparar `pedido.total` con la suma de las filas de `detalle_pedido`. Por eso
> esa coherencia depende de lógica programable (funciones y disparadores), que
> también hay que mantener y probar.
>
> *Responsabilidad de integridad.* Mayormente del motor, con una parte
> delegada a los objetos programables.
>
> **MongoDB (lo que implementaron)**
>
> *Ventajas.* Un documento contiene el pedido, su cliente y sus líneas: el
> acceso frecuente se resuelve leyendo un solo documento, sin uniones. Una
> escritura sobre un único documento es atómica, incluidos sus subdocumentos y
> arreglos embebidos, de modo que el pedido y sus líneas pueden cambiar juntos.
> Decimal128 conserva importes decimales exactos y los tipos Long e Int32
> preservan el contrato numérico del origen.
>
> *Costos.* El cliente y el nombre del producto quedan duplicados como
> instantánea: si cambian en el origen, el documento no se actualiza solo.
> `insertMany` con varios documentos no es atómico para todo el lote: si falla
> a mitad de camino, los documentos ya insertados permanecen. Para
> atomicidad entre varios documentos MongoDB ofrece transacciones
> multidocumento, que requieren un replica set o un clúster fragmentado; una
> instancia standalone como la del laboratorio no las admite.
>
> *Capacidad del motor frente a lo implementado.* MongoDB permite definir
> validación de esquema en la colección (`$jsonSchema` y operadores de
> consulta) para exigir tipos, campos obligatorios y rangos, como cantidad
> mayor que cero. Ustedes no definieron ningún validador: las reglas se
> comprobaron con un script después de la carga. Esa verificación demuestra
> que *esta* carga es correcta, pero no impide que una escritura posterior
> guarde un documento incoherente. Decimal128 tampoco valida reglas de
> negocio: solo representa el número con exactitud.
>
> *Responsabilidad de integridad.* Hoy recae en la aplicación y en los scripts
> de verificación; el motor solo garantiza la unicidad de `_id`.
>
> **Recomendación.** Mantener PostgreSQL como fuente de verdad para escritura,
> porque concentra en el motor las reglas relacionales que necesitan
> (cantidades, referencias y totales mediante los objetos programables). Usar
> MongoDB, si se justifica, como proyección de lectura del pedido completo,
> reconstruida desde PostgreSQL y verificada contra el origen. Antes de
> afirmar que mejora el acceso habría que medir ambos motores con un volumen
> realista; con cinco pedidos no se puede concluir sobre rendimiento.

---

## 2. Fuentes consultadas

Todas se consultaron el 2026-11-06, después de guardar la respuesta. La última
consulta terminó antes de las 16:20:30 UTC, la hora registrada con `date -u`; la
hora exacta de cada consulta no se registró.

| Id | Fuente | URL |
|---|---|---|
| F1 | MongoDB Manual — Atomicity and Transactions | https://www.mongodb.com/docs/manual/core/write-operations-atomicity/ |
| F2 | MongoDB Manual — Transactions | https://www.mongodb.com/docs/manual/core/transactions/ |
| F3 | MongoDB Manual — Schema Validation | https://www.mongodb.com/docs/manual/core/schema-validation/ |
| F4 | MongoDB Manual — Embedded Data in Your MongoDB Schema | https://www.mongodb.com/docs/manual/data-modeling/embedding/ |
| F5 | PostgreSQL 17 — 5.5. Constraints | https://www.postgresql.org/docs/17/ddl-constraints.html |
| L1 | Laboratorio U7 | `docs/laboratorio_migracion.md`, `mongodb/migracion_pedidos.js`, `evidencias/ejecucion_20261106_mongo9.txt` |
| L2 | Código U6 (`u6-cierre`) | `schema.sql` y `tpi/sql/objetos_programables.sql` de `foodstore_baseII` |

## 3. Afirmaciones contrastadas

### A1 — Atomicidad de `insertMany` y transacciones multidocumento

**Afirmación:**

> «`insertMany` con varios documentos no es atómico para todo el lote: si falla
> a mitad de camino, los documentos ya insertados permanecen. Para atomicidad
> entre varios documentos MongoDB ofrece transacciones multidocumento, que
> requieren un replica set o un clúster fragmentado; una instancia standalone
> como la del laboratorio no las admite.»

**Qué respaldan las fuentes:**

- **F1:**
  - «In MongoDB, write operations are atomic on the single-document level».
  - Para una sola operación que modifica varios documentos: «the modification
    of each document is atomic, but the operation as a whole is not atomic».
  - Para atomicidad sobre varios documentos, MongoDB ofrece transacciones
    distribuidas, «including transactions on replica sets and sharded
    clusters».
- **F2:**
  - «an operation on a single document is atomic».
  - En la sección de motores de almacenamiento: «Transactions are supported on
    replica sets and sharded clusters».
  - La tabla de versión de compatibilidad solo enumera *Replica Set* y
    *Sharded Cluster*.
  - La página no menciona la palabra «standalone».
- **L1:**
  - `migracion_pedidos.js` usa `insertMany` con `ordered: true` y documenta
    que no es atómico para el lote.
  - La instancia del laboratorio es standalone.
  - No se probó un fallo parcial: la repetición se rechazó **antes** de
    escribir, por la comprobación previa de `_id` (código 3).
  - No se probó ninguna transacción.

**Resultado: necesita matiz.**

- Lo que F1 respalda: la atomicidad por documento y la no atomicidad de una
  operación que escribe varios documentos.
- Lo que F1 y F2 no dicen literalmente: ninguna de las dos páginas dice que
  una instancia standalone «no admite» transacciones. Solo enumeran los
  despliegues donde están soportadas.
- Lo que el laboratorio no observó: ni la carga parcial ni el comportamiento
  de transacciones en standalone.

**Consecuencia para Food Store:**

- Embeber las líneas en el pedido hace que cada pedido se escriba de forma
  atómica (F1, F4: «update related data in a single atomic write operation»).
- La carga del lote de cinco pedidos no es atómica en conjunto.
- La protección del diseño es la comprobación previa de `_id`, el índice único
  y la regla de no limpiar ni reintentar ante un fallo (`design.md` §8).
- Si el equipo necesitara una carga atómica del lote, tendría que usar un
  replica set con transacciones. Queda fuera del alcance de U7 y no se agregó.

### A2 — `CHECK` en PostgreSQL y coherencia del total

**Afirmación:**

> «Una restricción `CHECK` evalúa solo la fila que se inserta o actualiza; no
> puede comparar `pedido.total` con la suma de las filas de `detalle_pedido`.
> Por eso esa coherencia depende de lógica programable (funciones y
> disparadores), que también hay que mantener y probar.»

**Qué respaldan las fuentes:**

- **F5:** «PostgreSQL does not support `CHECK` constraints that reference table
  data other than the new or updated row being checked». Agrega que una
  restricción de ese tipo «may appear to work in simple tests» pero no
  garantiza que la base no llegue a un estado que la viole.
- **L2, `schema.sql`:**
  - Declara `CHECK (cantidad > 0)`, `CHECK (precio_unitario >= 0)` y
    `CHECK (subtotal >= 0)`, que son reglas de una sola fila.
  - Indica que «subtotal y pedido.total son físicos y deliberadamente
    derivados» y que «su mantenimiento automático pertenece a la siguiente capa
    de objetos programables».
- **L2, `objetos_programables.sql`:**
  - Define `calcular_total_pedido` (suma de subtotales con
    `eliminado = FALSE`) y los disparadores que recalculan el total.
  - Declara sus límites: «DML directo concurrente requiere un protocolo
    externo: estos triggers no garantizan serialización completa» y «Una
    escritura directa de `pedido.total` queda fuera de estos triggers de
    detalle».

**Resultado: respaldada.**

F5 confirma el límite de `CHECK` y el código U6 confirma que el total se
mantiene con lógica programable. El código agrega un matiz que la respuesta no
menciona: esa lógica no cubre todos los caminos de escritura (DML concurrente
directo, escritura directa del total). Por eso «responsabilidad mayormente del
motor» es una simplificación.

**Consecuencia para Food Store:**

- En ambos motores, la regla «total = suma de subtotales vigentes» no la hace
  cumplir una restricción declarativa simple.
- En PostgreSQL depende de los disparadores de U6 y de sus límites declarados.
- En MongoDB, en esta implementación, depende de las comprobaciones de
  `migracion_pedidos.js` y `validaciones_mongodb.js`, que verifican esta carga
  pero no son validadores permanentes de la colección.
- Por eso el diseño copia el total del origen y lo **verifica** (RI-02) en
  lugar de recalcularlo o corregirlo.

## 4. Lo que no se afirma

- **Rendimiento.** Leer un documento completo evita uniones, pero no se
  midió: F4 menciona «better performance for read operations» como beneficio
  general del embebido, no como resultado de este laboratorio.
- **Validación de esquema.** F3 describe validación de tipos y rangos que,
  por defecto, rechaza inserciones inválidas. En este laboratorio no se creó
  ningún validador: `migracion_pedidos.js` crea la colección implícitamente con
  `insertMany`. Las verificaciones del script no equivalen a un validador
  permanente.
- **Decimal128.** Conserva importes exactos; no valida reglas de negocio.
- **Sincronización.** La coincidencia del lote entre motores es una
  comprobación puntual del 2026-11-06, no una sincronización futura.

## 5. Límites de este contraste

- La respuesta la produjo el mismo asistente que implementó la migración y
  redactó este contraste, en la misma sesión. Tenía contexto previo del
  proyecto, de modo que no es una consulta independiente. El equipo puede
  repetir el prompt en otra herramienta para comparar.
- Solo se contrastaron dos afirmaciones; el resto de la respuesta no se
  verificó con fuentes.
- Ningún integrante del equipo revisó todavía este contraste.
