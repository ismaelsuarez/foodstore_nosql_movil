# Integración de los tres motores — Unidad 8

Consigna 3.a del TP8. Este documento describe qué guarda cada motor del
proyecto Food Store y quién manda sobre cada dato. No propone aplicaciones,
API ni sincronización real: en el TP8 la sincronización es una simulación
local.

## 1. Mapa de la capa de datos

| Motor | Qué guarda | De dónde sale | Quién manda | Límites |
|---|---|---|---|---|
| PostgreSQL 17 (`foodstore_baseII`, U1–U6; laboratorio U8 `foodstore_u8`) | Modelo canónico: `categoria`, `usuario`, `producto`, `pedido`, `detalle_pedido`, más los objetos programables de U6 | `schema.sql`, `datos_iniciales.sql` y `tpi/sql/objetos_programables.sql` de `u6-cierre`. En U8, más los productos auxiliares `[U8 prueba]` | **Autoridad** sobre catálogo, precio, stock, usuarios y ventas (`pedido`, `detalle_pedido`) | La base de laboratorio U8 es una copia reconstruida para pruebas, no una base de producción |
| MongoDB (U7) | Colección `pedidos`: representación documental de los pedidos del lote U7, con sus líneas embebidas y el precio histórico de `detalle_pedido.precio_unitario` | Extracción de solo lectura desde PostgreSQL (`unidades/unidad-7/postgresql/extraccion_pedidos.sql`) y carga con `unidades/unidad-7/mongodb/migracion_pedidos.js` | Solo sobre esos documentos, como representación de consulta | No reemplaza a PostgreSQL y no se sincroniza en forma permanente: es un subconjunto cargado una vez (`unidades/unidad-7/README.md`, sección «Límites») |
| SQLite (U8, `movil/foodstore_movil.db`) | Copia del catálogo (`producto_cache`), la última instantánea (`snapshot_servidor`), los borradores (`pedido_borrador`, `item_borrador`) y la cola local con los resultados de la simulación (`cola_sync`) | Instantánea CSV exportada de PostgreSQL (`v_snapshot_movil`). Los borradores y la cola se crean en la tablet | Ninguna autoridad comercial: la tablet **propone**. Decide solo sobre sus propios borradores y su cola | No decide ventas ni reserva stock. `SIMULADO_APROBADO` no es una venta: no crea pedidos ni descuenta stock en PostgreSQL |

Regla de oro del TP: el móvil propone, el servidor dispone.

## 2. Datos que viajan a SQLite

La única vía de datos del servidor hacia la tablet es la instantánea
(`postgresql/snapshot_movil.sql` → `servidor_snapshot.csv` → `snapshot_servidor`
→ `producto_cache`). Nada viaja de la tablet al servidor.

| Origen en PostgreSQL | En la instantánea | En `producto_cache` |
|---|---|---|
| `producto.id` | `producto_id` | `producto_id` |
| `producto.nombre` | `nombre` | `nombre` |
| `producto.precio` (`NUMERIC(12,2)`) | `precio_centavos` = `(precio * 100)::BIGINT` | `precio_centavos` (`INTEGER`) |
| `producto.stock` | `stock` | `stock_visto` |
| `producto.disponible` | `disponible` (`t`/`f`) | `disponible_visto` (1/0) |
| `producto.eliminado OR categoria.eliminado` | `eliminado` (`t`/`f`) | `eliminado` (1/0); la fila no se borra (lápida) |
| `now()` en la transacción de exportación | `capturado_en` | `capturado_en` |

**No viajan:** `producto.descripcion`, `imagen`, `categoria_id` y
`created_at`; la tabla `categoria` (solo su baja, combinada en `eliminado`);
la tabla `usuario` completa (nombre, apellido, mail, celular, contraseña,
rol); `pedido` y `detalle_pedido`; los objetos programables.

**Datos que existen solo en la tablet:** `pedido_borrador`
(`id_local`, `usuario_id_servidor`, `forma_pago`, `creado_en`),
`item_borrador` (cantidad y `precio_centavos_visto`) y `cola_sync`
(`solicitud_uuid`, estado, motivo, `creada_en`).

### `usuario_id_servidor`

Es un número que referencia el `usuario.id` del servidor. No implica copiar
perfiles de usuario, mails ni contraseñas a la tablet. Como `usuario` no
viaja, SQLite no tiene clave foránea sobre esa columna ni puede comprobar que
el usuario exista o esté vigente; esa comprobación le correspondería al
servidor. En el bloque D se usó `usuario_id_servidor = 1`, leído del seed
del laboratorio.

## 3. Precisiones

- PostgreSQL conserva la autoridad sobre catálogo, stock y ventas. Los
  cambios de precio, stock y baja del bloque D se hicieron en PostgreSQL de
  pruebas como **preparación** de escenarios, nunca desde la tablet.
- El semáforo (`movil/semaforo.sql`) solo lee `snapshot_servidor` y escribe
  `cola_sync` en SQLite. No tiene conexiones ni sentencias hacia PostgreSQL.
- La comparación de PostgreSQL antes y después de cada simulación se hizo
  con `postgresql/control_invariancia.sql`: precio, stock, disponibilidad y
  baja de cada producto, más la cantidad y los agregados de `pedido` y
  `detalle_pedido`. Las salidas de esa consulta de control resultaron
  idénticas; no se compararon todas las columnas de todas las tablas.
- MongoDB no participa del flujo de U8. Se incluye en el mapa porque forma
  parte de la capa de datos del proyecto.
