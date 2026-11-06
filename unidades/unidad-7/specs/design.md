# Design — Unidad 7: Modelo documental MongoDB

**Trabajo Práctico — Unidad 7 / Semana 11**
Base de Datos II — UTN
**Integrantes:** Avalos Pablo · Blangetti Sofia · Suarez Ismael

> Diseño con decisiones adoptadas por el equipo mediante el encargo del
> 2026-11-06. No es una aprobación docente. Ningún script de migración ni
> consulta MongoDB se creó ni se ejecutó.
> Los IDs y los parámetros de §7 provienen de la lectura real del origen del
> 2026-11-06, registrada en el
> [inventario del origen y del entorno](../docs/inventario_origen_entorno.md).

---

## 1. Base y colección

| Parámetro | Valor |
|---|---|
| Base MongoDB | `foodstore_u7` |
| Colección | `pedidos` |
| Estructura | Un documento por pedido |
| Clave del documento | `_id` = `pedido.id` del origen, como `Long` |

Las tres primeras filas son decisiones del equipo, no requisitos de la consigna.

### Justificación del modelo

Las cuatro consultas de la consigna acceden a un pedido completo
(C4a, C4d) o filtran por estado (C4b) y por producto dentro de las
líneas (C4c). En todos los casos, la unidad de lectura es el pedido
con sus líneas. Embeber el arreglo de líneas y los datos mínimos del
cliente evita consultas a otras colecciones para las operaciones
requeridas. Los identificadores de usuario, detalle y producto se conservan
para mantener trazabilidad con el modelo relacional.

Usar el ID del pedido como `_id` aprovecha el índice único que MongoDB crea
siempre sobre `_id`: un pedido no puede quedar duplicado en la colección.

No se crean cinco colecciones replicando las cinco tablas relacionales.
No se diseñan sharding, replica sets ni sincronización automática.

---

## 2. Tabla de conversión de campos

### 2.1. Campos del documento raíz

| Campo PostgreSQL | Campo MongoDB | Tipo MongoDB | Regla de conversión |
|---|---|---|---|
| `pedido.id` | `_id` | `Long` (Int64) | ID del origen, construido desde texto: `Long("1")` |
| `pedido.fecha` | `fecha` | `String` `"YYYY-MM-DD"` | Fecha comercial `DATE`, sin hora ni zona horaria. No se usa `created_at`, que es la marca técnica `TIMESTAMPTZ`. Ejemplo: `"2026-03-01"` |
| `pedido.estado` | `estado` | `String` | Valor exacto del ENUM: `PENDIENTE`, `CONFIRMADO`, `TERMINADO` o `CANCELADO`. No se sustituye por `entregado` ni por otro valor |
| `pedido.forma_pago` | `forma_pago` | `String` | Valor exacto del ENUM: `EFECTIVO`, `TARJETA` o `TRANSFERENCIA` |
| `pedido.total` | `total` | `Decimal128` | Copia del valor almacenado, desde texto decimal: `Decimal128("2800.00")` |
| `pedido.eliminado` | `eliminado` | `Boolean` | Se conserva (§4) |
| `pedido.usuario_id` | `usuario.usuario_id` | `Long` | ID relacional conservado, desde texto |
| `usuario.nombre` | `usuario.nombre` | `String` | Dato sintético del seed (§2.3) |
| `usuario.apellido` | `usuario.apellido` | `String` | Dato sintético del seed (§2.3) |

### 2.2. Arreglo de líneas (`items`)

| Campo PostgreSQL | Campo MongoDB | Tipo MongoDB | Regla de conversión |
|---|---|---|---|
| `detalle_pedido.id` | `items[].detalle_id` | `Long` | ID original conservado, desde texto |
| `detalle_pedido.producto_id` | `items[].producto_id` | `Long` | ID relacional conservado, desde texto |
| `producto.nombre` | `items[].producto_nombre` | `String` | Nombre descriptivo vigente al migrar; es una instantánea y no una clave. Los filtros usan `producto_id` |
| `detalle_pedido.cantidad` | `items[].cantidad` | `Int32` | Entero explícito: `Int32(2)` |
| `detalle_pedido.precio_unitario` | `items[].precio_unitario` | `Decimal128` | **Precio histórico de la línea**, no `producto.precio`. En el origen, Muzzarella tiene líneas a 1000.00 y 1050.00 con catálogo actual 1050.00 |
| `detalle_pedido.subtotal` | `items[].subtotal` | `Decimal128` | Copia del valor almacenado en el origen, desde texto decimal |
| `detalle_pedido.eliminado` | `items[].eliminado` | `Boolean` | Se conserva (§4) |

### 2.3. Datos del cliente

Solo se trasladan `usuario_id`, `nombre` y `apellido`, sintéticos del seed
autorizado. No se trasladan `mail` (aunque termine en `.test`), `celular`,
`contrasena`, `rol`, `eliminado` ni `created_at` del usuario. La extracción
de nombre y apellido corresponde a la tarea T2b y aún no se hizo.

---

## 3. Tipos explícitos y representación decimal

En `mongosh`, un número literal entero se almacena como `Int32` cuando cabe en
ese tipo y como `Double` en los demás casos. Para no depender de esa inferencia,
el contrato de datos fija los tipos de forma explícita:

| Dato | Constructor en `mongosh` | Motivo |
|---|---|---|
| Identificadores | `Long("<id>")` | `BIGINT` del origen; el texto evita pasar por `Double` |
| Cantidad | `Int32(<n>)` | `INTEGER` del origen |
| Importes | `Decimal128("<importe>")` | `NUMERIC(12,2)`; el texto evita conversiones intermedias a punto flotante binario |

Los valores se extraen de PostgreSQL como texto: `id::text`, `total::text`
(conserva la escala, por ejemplo `2800.00`) y `to_char(fecha, 'YYYY-MM-DD')`,
que no depende de `DateStyle`.

---

## 4. Política para bajas lógicas

El campo `eliminado` existe en `pedido` y en `detalle_pedido` del origen.

- Se conservan todos los pedidos del lote con su `eliminado`.
- Se conservan todas las líneas de cada pedido del lote, incluidas las
  eliminadas, con su `items[].eliminado`.
- El `total` es el valor almacenado en `pedido.total`. Coincide con la suma de
  subtotales de líneas no eliminadas, que es la regla de
  `calcular_total_pedido` en `tpi/sql/objetos_programables.sql`.
  No se recalcula en la migración: se copia y se verifica (§6).
- Un pedido histórico no se excluye por bajas posteriores de su usuario, de sus
  productos o de la categoría. `producto.disponible` expresa disponibilidad
  comercial y no equivale a `eliminado`; ninguno de los dos se filtra.

En el lote leído no hay pedidos ni líneas eliminados (inventario §4). Los
filtros sobre `eliminado` se mantienen igual: forman parte de la definición de
las consultas, no del resultado esperado.

---

## 5. Estructura de documento

Ejemplo con los valores del pedido 1 leídos el 2026-11-06. Nombre y apellido
quedan sin valor porque no se consultaron:

```javascript
{
  _id: Long("1"),
  fecha: "2026-03-01",
  estado: "TERMINADO",
  forma_pago: "EFECTIVO",
  total: Decimal128("2800.00"),
  eliminado: false,
  usuario: {
    usuario_id: Long("1"),
    nombre: "<nombre sintético del seed>",
    apellido: "<apellido sintético del seed>"
  },
  items: [
    { detalle_id: Long("1"), producto_id: Long("1"),
      producto_nombre: "Muzzarella", cantidad: Int32(2),
      precio_unitario: Decimal128("1000.00"),
      subtotal: Decimal128("2000.00"), eliminado: false },
    { detalle_id: Long("2"), producto_id: Long("3"),
      producto_nombre: "Coca 1.5L", cantidad: Int32(1),
      precio_unitario: Decimal128("800.00"),
      subtotal: Decimal128("800.00"), eliminado: false }
  ]
}
```

---

## 6. Dos reglas de integridad y cómo verificarlas

Los importes se copian del origen y se verifican. No se corrigen en silencio
para que los resultados coincidan: una diferencia se informa.

### RI-01 — Cantidad positiva e importes no negativos en todas las líneas

**Regla:** en todas las líneas, incluidas las eliminadas, `cantidad` es un
`Int32` mayor que cero, y `precio_unitario` y `subtotal` no son negativos.
Corresponde a `chk_detalle_pedido_cantidad`, `chk_detalle_pedido_precio_unitario`
y `chk_detalle_pedido_subtotal` del origen.

Verificación prevista en MongoDB (borrador, no ejecutado):

```javascript
db.pedidos.countDocuments({
  items: { $elemMatch: { $or: [
    { cantidad: { $not: { $type: "int" } } },
    { cantidad: { $lte: 0 } },
    { precio_unitario: { $lt: Decimal128("0") } },
    { subtotal: { $lt: Decimal128("0") } }
  ] } }
})
// Debe devolver 0
```

Control equivalente en PostgreSQL, ejecutado el 2026-11-06 con resultado 0 en
las tres columnas (inventario, Q7):

```sql
SELECT count(*) FILTER (WHERE cantidad <= 0),
       count(*) FILTER (WHERE precio_unitario < 0),
       count(*) FILTER (WHERE subtotal < 0)
FROM detalle_pedido;
```

### RI-02 — Subtotal y total coherentes

**Regla:** en cada línea, `subtotal = cantidad × precio_unitario`. En cada
pedido, `total` es la suma de `subtotal` de las líneas no eliminadas, o cero si
no hay ninguna.

Verificación prevista en MongoDB (borrador, no ejecutado):

```javascript
db.pedidos.aggregate([
  { $project: {
      total: 1,
      lineas_incoherentes: { $size: { $filter: {
        input: "$items",
        cond: { $ne: ["$$this.subtotal",
                      { $multiply: ["$$this.cantidad", "$$this.precio_unitario"] }] }
      } } },
      suma_vigentes: { $sum: { $map: {
        input: { $filter: { input: "$items",
                            cond: { $eq: ["$$this.eliminado", false] } } },
        in: "$$this.subtotal"
      } } }
  } },
  { $match: { $or: [
      { lineas_incoherentes: { $gt: 0 } },
      { $expr: { $ne: ["$total", "$suma_vigentes"] } }
  ] } }
])
// Debe devolver cero documentos. $sum de un arreglo vacío devuelve 0.
```

Controles equivalentes en PostgreSQL, ejecutados el 2026-11-06 con 0 filas
(inventario, Q8 y Q9).

---

## 7. Lote y consultas

### 7.1. Lote

Lote explícito, idéntico para ambos motores: **pedidos 1, 2, 3, 4 y 5**. Son
los cinco pedidos del origen, que coinciden con los esperados del seed
(inventario §4). No se agregan pedidos de prueba.

En MongoDB, el lote se expresa como
`{ _id: { $in: [Long("1"), Long("2"), Long("3"), Long("4"), Long("5")] } }`;
en PostgreSQL, como `p.id IN (1, 2, 3, 4, 5)`.

### 7.2. Definición de las consultas

| ID | Motor | Filtro |
|---|---|---|
| C4a | MongoDB | Lote; proyección de `_id` y `estado` |
| C4b | MongoDB + PostgreSQL | Lote + pedido no eliminado + `estado = 'TERMINADO'` |
| C4c | MongoDB + PostgreSQL | Lote + pedido no eliminado + una misma línea con `producto_id = 1` y `eliminado = false` |
| C4d | MongoDB | Lote + pedido no eliminado + `total > 3000.00` |

En C4c, la condición de producto y la de línea vigente deben cumplirse en la
**misma línea**: en MongoDB con
`items: { $elemMatch: { producto_id: Long("1"), eliminado: false } }`, y en
PostgreSQL con un `EXISTS` sobre `detalle_pedido` que exija
`dp.pedido_id = p.id AND dp.producto_id = 1 AND dp.eliminado = FALSE`.

Las consultas comparativas cuentan **pedidos distintos**, no líneas.

### 7.3. Parámetros elegidos según la lectura

| Parámetro | Valor | Justificación con los datos leídos |
|---|---|---|
| Estado (C4b) | `TERMINADO` | Es el único estado presente: 5 pedidos no eliminados. El resultado incluye todo el lote; es una limitación del origen y no se transforman estados para lograr variedad |
| Producto (C4c) | `producto_id = 1` (Muzzarella) | Es el producto presente en más pedidos (1, 3 y 5) y el único con dos precios históricos (1000.00 y 1050.00), así que pone a prueba el uso de `precio_unitario` |
| Umbral (C4d) | `total > 3000.00` | Totales: 1050.00, 1500.00, 2800.00, 3150.00 y 6200.00; promedio 2940.00, mediana 2800.00. 3000.00 es un importe redondo apenas superior al promedio. Ningún total es igual a 3000.00, así que `>` y `>=` no se confunden |

Resultados esperados según la lectura del origen (todavía no son resultados de
consultas ejecutadas en ningún motor): C4b → 5 pedidos (1–5), C4c → 3 pedidos
(1, 3, 5), C4d → 2 pedidos (3, 4).

---

## 8. Repetición de la carga

- Antes de insertar, el futuro script cuenta los `_id` del lote que ya existen
  en `pedidos`. Si encuentra alguno, se detiene sin intentar la carga e informa
  los IDs en colisión.
- El índice único de `_id` sigue siendo la protección del motor ante una
  colisión que la comprobación previa no detecte.
- `insertMany()` no es una transacción atómica del lote: con el modo ordenado
  por defecto, se detiene en el primer error y los documentos ya insertados
  permanecen. Una carga parcial se informa como tal.
- No se usan upserts, borrados ni sincronización automática.

---

## 9. Decisiones

| Decisión | Estado |
|---|---|
| Destino, `_id`, tipos, bajas lógicas, reglas, repetición y datos del cliente (§1–§8) | Adoptadas por el equipo mediante el encargo del 2026-11-06; sin aprobación docente |
| IDs del lote, estado, producto y umbral | Fijados tras la lectura del 2026-11-06 (§7) |
| Pedidos de prueba adicionales | No necesarios: el origen tiene los cinco pedidos |
| Imagen MongoDB | `mongo:9.0.4` por digest `sha256:452bdaf2…a058`, elegida por el equipo. Antecedente: `mongo:8.0` no arranca en el kernel del host (`docs/laboratorio_migracion.md` §3) |
| Extracción de nombre/apellido y nombres de producto | Hecha (T2b), `datos/pedidos_origen.json` |
| Script de carga, verificación y consultas MongoDB | Ejecutados el 2026-11-06 con 9.0.4 (T3–T5) |
