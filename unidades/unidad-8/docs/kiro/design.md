# Design — Unidad 8: Base de datos móvil y sincronización

**Trabajo Práctico N.º 8 — Unidad 8 / Semanas 12 y 13**
Base de Datos II — UTN, Tecnicatura Universitaria en Programación
**Integrantes:** Avalos Pablo · Blangetti Sofia · Suarez Ismael

> Diseño elaborado en Kiro. Una revisión técnica posterior identificó
> ajustes, incorporados en esta versión. Claude implementa el bloque B a partir
> de este documento. Según informa el equipo, el docente autorizó sustituir
> OpenCode por Claude; esa autorización es información aportada por el equipo,
> no texto de la consigna. No constituye aprobación final del equipo ni
> aprobación docente. Los scripts se generan por bloques a partir de este
> documento y de tasks.md.

---

## 1. Modelo canónico de origen

El modelo relacional en `foodstore_baseII` (etiqueta `u6-cierre`,
commit `8f7877c8a1ff25c1be28b29c46c38cd7c9663e86`) define cinco tablas:
`categoria`, `usuario`, `producto`, `pedido`, `detalle_pedido`.

Campos relevantes para U8:

| Campo origen | Tipo PostgreSQL | Notas |
|---|---|---|
| `producto.id` | `BIGINT GENERATED ALWAYS AS IDENTITY` | Identificador del producto |
| `producto.precio` | `NUMERIC(12,2)` | Máximo positivo finito: 9 999 999 999,99 |
| `producto.stock` | `INTEGER` | No negativo |
| `producto.disponible` | `BOOLEAN` | Disponibilidad comercial |
| `producto.eliminado` | `BOOLEAN` | Baja lógica |
| `categoria.eliminado` | `BOOLEAN` | Baja lógica de la categoría |

Los objetos programables (`tpi/sql/objetos_programables.sql`) definen
`registrar_detalle_pedido(BIGINT, BIGINT, INTEGER)`, que agrega una línea a
un pedido existente, valida vigencia y stock, y descuenta inventario. La
transacción pertenece al llamante. No es `sp_crear_pedido` del apunte; el
apunte usa ese nombre como ejemplo ilustrativo del comportamiento del servidor.
No se implementa idempotencia de servidor (tabla `solicitud_movil` con
`ON CONFLICT DO NOTHING`): el TP no lo pide y no está en el proyecto.

---

## 2. Regla de oro

El móvil propone, el servidor dispone. La tablet consulta y arma borradores.
`SIMULADO_APROBADO` no es una venta, no descuenta stock y no crea pedidos en
PostgreSQL.

---

## 3. Cuatro tablas SQLite (STRICT)

### 3.1 producto_cache

Copia del catálogo traída del servidor. La fecha `capturado_en` indica cuándo
se copió; no es la fecha de la fixture de prueba.

```
producto_id        INTEGER  PRIMARY KEY        -- mismo id que en el servidor (BIGINT en origen)
nombre             TEXT     NOT NULL
precio_centavos    INTEGER  NOT NULL CHECK (precio_centavos >= 0)
stock_visto        INTEGER  NOT NULL CHECK (stock_visto >= 0)
disponible_visto   INTEGER  NOT NULL CHECK (disponible_visto IN (0,1))
eliminado          INTEGER  NOT NULL DEFAULT 0 CHECK (eliminado IN (0,1))
capturado_en       TEXT     NOT NULL           -- ISO 8601, fecha real de extracción
```

Tabla STRICT. Los booleanos del servidor (`'t'`/`'f'`) se convierten a
`1`/`0` en el momento de cargar esta tabla desde `snapshot_servidor`.
**Decisión de diseño:** la conversión ocurre en un único punto (el UPSERT de
carga, §10), no en el semáforo.

### 3.2 pedido_borrador

Un pedido anotado sin conexión. No es una venta.

```
id_local             TEXT  PRIMARY KEY        -- UUID generado en la tablet
usuario_id_servidor  INTEGER NOT NULL
forma_pago           TEXT    NOT NULL
                     CHECK (forma_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA'))
creado_en            TEXT    NOT NULL
                     DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
```

Tabla STRICT. `id_local` es un UUID de 36 caracteres generado localmente;
sin red no hay servidor que asigne números secuenciales.

### 3.3 item_borrador

Productos de cada borrador, con el precio que vio el cliente al anotar.

```
id_local              TEXT    NOT NULL
                      REFERENCES pedido_borrador(id_local) ON DELETE CASCADE
producto_id           INTEGER NOT NULL
                      REFERENCES producto_cache(producto_id)
cantidad              INTEGER NOT NULL CHECK (cantidad > 0)
precio_centavos_visto INTEGER NOT NULL CHECK (precio_centavos_visto >= 0)
PRIMARY KEY (id_local, producto_id)
```

Tabla STRICT. `precio_centavos_visto` refleja el precio en el momento de
anotar. No se modifica automáticamente al renovar el catálogo. Se actualiza
únicamente cuando el cliente acepta explícitamente un precio nuevo tras un
CONFLICTO (operación transaccional deliberada).

### 3.4 cola_sync

Cada intento de enviar un borrador al servidor, con su resultado.

```
solicitud_uuid  TEXT  PRIMARY KEY   -- UUID estable; no cambia en reintentos
id_local        TEXT  NOT NULL REFERENCES pedido_borrador(id_local)
estado          TEXT  NOT NULL DEFAULT 'PENDIENTE'
                CHECK (estado IN ('PENDIENTE','CONFLICTO','RECHAZADO','SIMULADO_APROBADO'))
motivo          TEXT              -- NULL solo mientras está PENDIENTE sin evaluar;
                                  -- mensaje explicativo en toda solicitud evaluada
creada_en       TEXT  NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
```

Tabla STRICT.

**Índice de unicidad parcial** (decisión de diseño):

```sql
CREATE UNIQUE INDEX ux_cola_una_pendiente
    ON cola_sync(id_local) WHERE estado = 'PENDIENTE';
```

Un borrador no puede tener dos solicitudes PENDIENTE simultáneas. Puede tener
solicitudes posteriores con UUID distintos una vez que la anterior deja de ser
PENDIENTE. Este índice no impide un segundo envío después de resolver un
CONFLICTO.

### 3.5 Vista del catálogo disponible

```sql
CREATE VIEW v_catalogo_disponible AS
SELECT producto_id,
       nombre,
       precio_centavos / 100.0 AS precio,
       stock_visto
FROM producto_cache
WHERE eliminado = 0 AND disponible_visto = 1;
```

---

## 4. Tabla auxiliar snapshot_servidor

Tabla de trabajo en la base SQLite. Almacena la copia más reciente del
catálogo exportado desde PostgreSQL, con los booleanos en su representación
de texto original (`'t'`/`'f'`). No es una de las cuatro tablas requeridas
por la consigna; cumple una función auxiliar.

**Decisión de diseño:** se declara STRICT y con CHECK sobre los booleanos
para detectar importaciones malformadas antes de continuar.

```
producto_id      INTEGER  NOT NULL
nombre           TEXT     NOT NULL
precio_centavos  INTEGER  NOT NULL CHECK (precio_centavos >= 0)
stock            INTEGER  NOT NULL CHECK (stock >= 0)
disponible       TEXT     NOT NULL CHECK (disponible IN ('t','f'))
eliminado        TEXT     NOT NULL CHECK (eliminado IN ('t','f'))
capturado_en     TEXT     NOT NULL
PRIMARY KEY (producto_id)
```

Tabla STRICT.

**Orden de columnas en el CSV** (debe coincidir con el SELECT de la vista
PostgreSQL):
`producto_id, nombre, precio_centavos, stock, disponible, eliminado, capturado_en`

**Renovación transaccional:** el esquema de `snapshot_servidor` se crea una
vez; sus datos se renuevan dentro de una única transacción:
`BEGIN` → `DELETE FROM snapshot_servidor` → importación del CSV nuevo →
validación → `COMMIT` solo si la importación y la validación tuvieron
éxito; `ROLLBACK` si cualquiera de las dos falla, y en ese caso no se
continúa con la actualización del catálogo ni con el semáforo. El `DELETE`
solo es reversible mientras la transacción sigue abierta: un `DELETE` ya
confirmado no se recupera abortando un paso posterior. No se usa
`CREATE TABLE IF NOT EXISTS` con `.import` automático, porque eso depende de
la creación implícita de la tabla. Que la importación haya producido algunas
filas no la da por exitosa: el cliente no debe informar errores de
inserción y los conteos deben cumplir la validación siguiente.

**Validación antes de simular:**

```sql
SELECT COUNT(*) FROM snapshot_servidor;
-- debe coincidir con las filas de datos del CSV (sin encabezado) y con el
-- número de filas de v_snapshot_movil en la base de pruebas al exportar

SELECT COUNT(*) FROM snapshot_servidor
WHERE precio_centavos IS NULL OR stock IS NULL;
-- debe devolver 0
```

---

## 5. Vista de instantánea en PostgreSQL de pruebas

```sql
CREATE VIEW v_snapshot_movil AS
SELECT p.id                          AS producto_id,
       p.nombre,
       (p.precio * 100)::BIGINT      AS precio_centavos,
       p.stock,
       p.disponible,
       (p.eliminado OR c.eliminado)  AS eliminado,
       now()                         AS capturado_en
FROM producto p
JOIN categoria c ON c.id = p.categoria_id;
```

**Por qué `::BIGINT` y no `::INTEGER`:** `producto.precio` es `NUMERIC(12,2)`.
El máximo positivo finito es 9 999 999 999,99, cuyo equivalente en centavos es
999 999 999 999. Ese valor supera el rango de `INTEGER` de PostgreSQL
(máximo: 2 147 483 647); una conversión con `::INTEGER` produciría un error en
PostgreSQL, no un desbordamiento silencioso. Se usa `::BIGINT` para evitar ese
error. En SQLite, la columna `precio_centavos` se declara `INTEGER` (que
soporta hasta 8 bytes). Esta es una divergencia justificada respecto del
`::INTEGER` del apunte de la cátedra.
**Decisión de diseño del equipo.**

`capturado_en` registra la fecha y hora reales del momento de extracción.
No se usa la fecha de una fixture de prueba como fecha de extracción.

---

## 6. Semáforo — lógica de evaluación

El semáforo actualiza `cola_sync` para las solicitudes con
`estado = 'PENDIENTE'`. No escribe en PostgreSQL.

**Orden de prioridad (el rojo gana sobre el amarillo):**

1. **RECHAZADO** si algún ítem del borrador:
   - no existe en `snapshot_servidor` (LEFT JOIN devuelve NULL),
   - tiene `disponible = 'f'`,
   - tiene `eliminado = 't'`, o
   - su `cantidad` supera el `stock` de `snapshot_servidor`.
2. **CONFLICTO** si no hay rechazo y algún ítem tiene
   `precio_centavos_visto ≠ precio_centavos` en `snapshot_servidor`.
3. **SIMULADO_APROBADO** si no se cumple ninguna de las anteriores.

**Contenido del campo `motivo`:**

| Estado | Contenido mínimo |
|---|---|
| RECHAZADO (stock) | `"producto_id=X: stock disponible=Y, cantidad solicitada=Z"` |
| RECHAZADO (baja) | `"producto_id=X: eliminado=t"` |
| RECHAZADO (no disponible) | `"producto_id=X: disponible=f"` |
| RECHAZADO (inexistente) | `"producto_id=X: no existe en snapshot_servidor"` |
| CONFLICTO | `"producto_id=X: precio_visto=Y centavos, precio_actual=Z centavos"` |
| SIMULADO_APROBADO | `"todo coincide con snapshot de <capturado_en>"` |

`motivo` es NULL mientras la solicitud está PENDIENTE sin evaluar; toda
solicitud evaluada recibe un mensaje explicativo, incluida SIMULADO_APROBADO.

Si el borrador tiene varios problemas, el motivo corresponde a la causa que
determina el estado de mayor prioridad (un rechazo gana sobre un conflicto de
precio). Orden reproducible: entre los ítems con esa causa se informa el de
menor `producto_id`; si un mismo ítem reúne varias causas de rechazo, se
informa la primera en este orden: inexistente, baja (`eliminado = 't'`), no
disponible (`disponible = 'f'`), stock insuficiente.

### 6.1 Decisiones de implementación del bloque D

Registradas antes de ejecutar el bloque D. Son decisiones de prueba del
equipo, no valores impuestos por la consigna.

- **Semáforo** (`movil/semaforo.sql`): toda la lógica está en SQL, en una
  transacción bajo `.bail on`. Calcula el resultado de todas las
  solicitudes PENDIENTE contra `snapshot_servidor` y actualiza solo esas
  filas. Antes del `COMMIT` comprueba que las solicitudes ya evaluadas,
  `item_borrador` y `producto_cache` no cambiaron. Imprime las solicitudes
  procesadas y su cantidad; sin pendientes, procesa cero. No tiene ninguna
  conexión ni sentencia hacia PostgreSQL.
- **Borradores** (`movil/crear_borrador.sql`): borrador, ítems y solicitud
  PENDIENTE en una transacción (§7.1). El precio visto de cada ítem debe
  coincidir con `producto_cache` y el producto debe figurar en
  `v_catalogo_disponible`: la tablet solo ofrece lo que ve en su catálogo.
  Una repetición falla por clave primaria; no se usa `INSERT OR REPLACE`,
  `OR IGNORE` ni borrados.
- **Aceptación** (`movil/aceptar_precio.sql`): implementa §7.2 con
  controles que cancelan la transacción completa. La unicidad de la nueva
  solicitud la garantiza la clave primaria de `cola_sync`.
- **Mutaciones de PostgreSQL** (`postgresql/preparar_c2_precio.sql`,
  `preparar_c3_stock.sql`, `preparar_c4_baja.sql`): cada una cambia un
  único campo de un único producto, identificado por id, nombre y estado
  esperado, y falla si no modifica exactamente una fila.
- **Instantáneas por escenario**:
  `movil/instantaneas/<ejecucion>/{c2_precio,c3_stock,c4_baja}/`, con el
  nombre `servidor_snapshot.csv` que exige el importador. La instantánea
  inicial de C (`movil/servidor_snapshot.csv`) no se modifica.
- **Invariancia del servidor** (`postgresql/control_invariancia.sql`):
  lectura de id, precio, stock, disponibilidad y baja de cada producto, más
  la cantidad de pedidos y de líneas y la suma de totales, inmediatamente
  antes y después de cada simulación. Las dos lecturas se comparan byte a
  byte.

| Caso | Producto (id leído en C) | Borrador | Cambio en PostgreSQL | Resultado esperado |
|---|---|---|---|---|
| C2 | `[U8 prueba] Base C2 precio` (4), 1200.00, stock 20 | 1 u. a 120000 centavos, creado antes del cambio | precio → 1320.00 | CONFLICTO; tras la aceptación (132000), SIMULADO_APROBADO |
| C3 | `[U8 prueba] Base C3 stock` (5), 900.00, stock 10 | 3 u. a 90000 | stock → 2 | RECHAZADO por stock (2 < 3) |
| C4 | `[U8 prueba] Base C4 baja` (6), 700.00, stock 15 | 1 u. a 70000, creado antes de la baja | eliminado → true | RECHAZADO por baja; lápida en `producto_cache` |
| C5 | `[U8 prueba] Base C5 sin cambios` (7), 500.00, stock 30 | 2 u. a 50000 | ninguno | SIMULADO_APROBADO (no es venta ni reserva) |
| C6 | solicitud original de C2 | — | ninguno | reinserción rechazada por clave primaria; segundo semáforo procesa 0 |

Los UUID de cada caso están fijados en `movil/bloque_d.sh` y se registran
en `tasks.md`.

---

## 7. Transacciones y atomicidad

### 7.1 Guardar un borrador completo

```
BEGIN;
  INSERT INTO pedido_borrador ...
  INSERT INTO item_borrador ... (N líneas)
  INSERT INTO cola_sync ... (estado PENDIENTE)
COMMIT;
```

Si alguna sentencia falla, la transacción permanece activa (no se aborta
automáticamente en SQLite para las restricciones consideradas); el script debe
ejecutar `ROLLBACK` explícito. El borrador no es una venta: no toca PostgreSQL.

### 7.2 Aceptación explícita de precio nuevo (tras CONFLICTO)

```
BEGIN;
  UPDATE item_borrador
  SET precio_centavos_visto = (
      SELECT precio_centavos FROM snapshot_servidor
      WHERE producto_id = item_borrador.producto_id
  )
  WHERE id_local = '<uuid_borrador>';

  INSERT INTO cola_sync (solicitud_uuid, id_local)
  VALUES ('<nuevo_uuid>', '<uuid_borrador>');
COMMIT;
```

La solicitud anterior conserva `estado = 'CONFLICTO'` y su motivo. El precio
actualizado proviene de `snapshot_servidor`, no de una columna adicional de
`cola_sync`. El nuevo `solicitud_uuid` es distinto del anterior.

**Aceptación imposible o fallida:** si algún producto del borrador falta en
`snapshot_servidor`, o falla cualquier sentencia de la aceptación, se
deshace la operación completa con `ROLLBACK`: no se cambian precios de forma
parcial ni se crea una solicitud nueva, y la solicitud anterior se conserva
con su estado y su motivo. Dentro de la transacción, antes del `UPDATE`, se
comprueba que no haya ítems del borrador sin fila en `snapshot_servidor`;
además, la subconsulta devolvería NULL para ese ítem y el `NOT NULL` de
`precio_centavos_visto` haría fallar el `UPDATE`. Este caso queda previsto
para el bloque D; no se ejecuta en el bloque B.

---

## 8. Manejo de errores en C7 — Pruebas de datos inválidos

**Comportamiento de SQLite ante restricciones:** cuando una sentencia viola
CHECK o FOREIGN KEY, la sentencia falla con el modo de acción ABORT por
defecto: deshace los cambios de esa sentencia y la transacción permanece
activa. El script debe ejecutar `ROLLBACK` explícito.

**Dos pruebas independientes.** El catálogo sintético (§9) puede
prepararse antes; el encabezado de la operación que se espera deshacer se
inserta dentro de la transacción.

**C7-a — cantidad = 0:**
1. `PRAGMA foreign_keys = ON;` + verificar que devuelve 1.
2. `BEGIN;`
3. Preparación válida: insertar `pedido_borrador` con un UUID propio.
4. Comprobar que la preparación tuvo éxito (SELECT devuelve 1 fila para
   ese UUID dentro de la transacción).
5. `INSERT INTO item_borrador ... cantidad = 0 ...` → debe fallar con
   `CHECK constraint failed: cantidad > 0`.
6. Verificar que ocurrió ese error en esa sentencia. Si no ocurrió, o
   ocurrió otro, la prueba es fallida.
7. `ROLLBACK;` en la misma sesión.
8. Verificar: `COUNT(*) = 0` en `pedido_borrador`, `item_borrador` y
   `cola_sync` para el UUID de esta prueba.

**C7-b — producto inexistente:**
1. `PRAGMA foreign_keys = ON;` + verificar que devuelve 1.
2. `BEGIN;`
3. Preparación válida: insertar `pedido_borrador` con un UUID propio,
   distinto del de C7-a.
4. Comprobar que la preparación tuvo éxito.
5. `INSERT INTO item_borrador ... producto_id = <id inexistente en producto_cache> ...`
   → debe fallar con `FOREIGN KEY constraint failed`.
6. Verificar que ocurrió ese error en esa sentencia. Si no ocurrió, o
   ocurrió otro, la prueba es fallida.
7. `ROLLBACK;` en la misma sesión.
8. Verificar: `COUNT(*) = 0` en las tres tablas para el UUID de esta prueba.

Las filas de la operación no se borran después del ROLLBACK para aparentar
que funcionó: los conteos en cero deben resultar solo del ROLLBACK.

**Manejo del cliente sqlite3:** no se usa `.bail on` como sustituto del
`ROLLBACK` situado después de la sentencia que falla: `.bail on` detiene el
script al primer error sin ejecutar sentencias posteriores, incluido el
ROLLBACK. Sin `.bail`, el cliente sigue con la sentencia siguiente, escribe
en la salida de error un diagnóstico con el número de línea del script
(`Error near line N: CHECK constraint failed: cantidad > 0` o
`Error near line N: FOREIGN KEY constraint failed`) y termina con código de
salida distinto de cero. El error esperado se reconoce por ese diagnóstico
real y por la línea de la sentencia inválida; la ausencia de salida no es
prueba de error. Un error de sintaxis (`Parse error ...`) u otro diagnóstico
no equivale al error esperado y hace fallar la prueba.

---

## 9. Datos de prueba — fixture local del bloque B

Las pruebas del bloque B (schema y transacciones SQLite) requieren al menos un
producto en `producto_cache` para poder insertar `item_borrador` sin violar
la clave foránea. Esta fixture es independiente de la instantánea.

**Decisión de diseño:** el bloque B usa una base SQLite descartable y separada
de `foodstore_movil.db`, creada en un directorio temporal fuera del
repositorio. Las pruebas del bloque B nunca abren ni modifican la base
entregable. La fixture de prueba es un dato sintético local; no proviene de
PostgreSQL y no se presenta como dato extraído. La base entregable
(`foodstore_movil.db`) se prepara mediante el flujo documentado de instantánea
y casos (bloque C en adelante), sin arrastrar datos de la fixture.

Ejemplo de fixture mínima (valores inventados):

```sql
INSERT INTO producto_cache
    (producto_id, nombre, precio_centavos, stock_visto,
     disponible_visto, eliminado, capturado_en)
VALUES
    (1, 'Muzzarella (fixture)', 105000, 10, 1, 0, 'fixture-no-extraido');
```

---

## 10. Instantánea — flujo de renovación y conservación de lápidas

1. Exportar desde la base PostgreSQL de pruebas:
   `\copy (SELECT * FROM v_snapshot_movil) TO 'servidor_snapshot.csv' CSV HEADER`
   y registrar el número de filas de la vista en ese momento.
2. En SQLite, en una sola sesión: `BEGIN;` y luego
   `DELETE FROM snapshot_servidor;`
3. Importar CSV dentro de la misma transacción:
   `.import --csv --skip 1 servidor_snapshot.csv snapshot_servidor`
4. Validar la importación (diagnósticos del cliente, conteos y NULLs, §4).
5. Si la importación o la validación fallan, la transacción se revierte
   (la tabla conserva la instantánea anterior) y no se continúa con el
   catálogo ni con el semáforo. Si ambas tienen éxito, la misma
   transacción continúa con el paso 6: no hay un `COMMIT` intermedio.
6. Dentro de esa transacción, cargar `producto_cache` con un UPSERT
   `INSERT ... ON CONFLICT(producto_id) DO UPDATE SET ...`, convirtiendo
   booleanos `'t'`/`'f'` → `1`/`0`. Se prefiere a `INSERT OR REPLACE`
   porque actualiza la fila existente en su lugar, sin la semántica de
   borrado y reinserción de `REPLACE`, cuyos efectos sobre las filas que
   referencian el producto y sobre las columnas omitidas habría que
   analizar aparte. `REPLACE` no se implementa. El UPSERT no elimina filas
   de `producto_cache` que ya no estén en `snapshot_servidor`
   (conservación de lápidas). **Decisión de implementación.**
7. `item_borrador.precio_centavos_visto` no se modifica durante este flujo.
8. Un único `COMMIT` confirma juntas la instantánea y la carga del catálogo,
   solo después de los controles de §10.1. Es la implementación vigente.

### 10.1 Decisiones de implementación del bloque C

- **Exportación** (`postgresql/exportar_snapshot.sql`): el cliente `psql`
  corre dentro del contenedor y escribe el CSV por su salida estándar, que
  el coordinador guarda en el host. Conteo y datos salen de la misma
  transacción `REPEATABLE READ READ ONLY`, con `TimeZone = UTC`; los
  metadatos van por la salida de error (`\warn`) y nunca se mezclan con el
  CSV. `capturado_en` queda con el formato ISO de PostgreSQL
  (`2026-11-07 15:51:24.499236+00`).
- **Una sola transacción para instantánea y catálogo**
  (`movil/renovar_snapshot.sql`): los pasos 2–6 se confirman juntos. El
  script usa `.bail on`: ante cualquier error el cliente termina antes del
  `COMMIT` y, al cerrar la conexión con la transacción abierta, SQLite la
  revierte. Cada control se inserta en una tabla temporal con
  `CHECK (ok = 1)`, de modo que un control fallido es un error del cliente.
  Se comprueban: `foreign_keys`, filas importadas = filas exportadas
  (parámetro `@filas_esperadas`), ausencia de NULL, enteros, una sola
  `capturado_en`, correspondencia de valores con `producto_cache`, lápidas
  conservadas e `item_borrador` y `cola_sync` sin cambios.
- **Comprobación previa del CSV** (`movil/preparar_foodstore_movil.sh`): la
  huella debe coincidir con los metadatos y el archivo debe tener el
  encabezado del contrato y siete campos por línea. `.import` ignora con una
  advertencia las columnas sobrantes y llegaría al `COMMIT`; por eso se
  rechaza antes de abrir la base.
- **Subconjunto de CSV admitido**: exportador e importador manejan solo el
  subconjunto usado en este laboratorio: siete campos simples separados por
  comas, sin entrecomillado, sin comas ni comillas dentro de un campo y sin
  saltos de línea dentro de campos. Un CSV válido según RFC 4180 pero fuera
  de ese subconjunto (por ejemplo, un nombre con coma entre comillas) se
  rechaza: el exportador no lo publica y el coordinador no lo importa. No se
  amplía el analizador en este trabajo.
- **Datos auxiliares de U8** (`postgresql/datos_auxiliares_u8.sql`): una
  categoría y seis productos con prefijo `[U8 prueba]`, separados del seed;
  sus ids se obtienen con `RETURNING`, no por orden textual.

---

## 11. Objetos programables del servidor — alcance en TP8

El procedimiento `registrar_detalle_pedido` del proyecto agrega una línea a
un pedido existente y descuenta stock. Requiere que el pedido ya exista.
La transacción pertenece al llamante.

El apunte menciona `sp_crear_pedido` como ejemplo ilustrativo; no es un
procedimiento del proyecto. El patrón de idempotencia de servidor
(tabla `solicitud_movil` + `ON CONFLICT DO NOTHING`) que el apunte muestra
como "cómo sería en producción" **no está implementado** y el TP no lo pide.
En TP8, la protección contra doble evaluación se implementa mediante la clave
primaria de `cola_sync.solicitud_uuid` y la evaluación exclusiva de
solicitudes `PENDIENTE`.

---

## 12. Base PostgreSQL de pruebas — procedencia del esquema

La base de pruebas de U8 reproduce el modelo canónico:
- `schema.sql` del commit `8f7877c` de `foodstore_baseII`.
- `datos_iniciales.sql` del mismo commit.
- `tpi/sql/objetos_programables.sql` del mismo commit.

Los datos sintéticos para los escenarios C2–C5 se insertan por separado, en
scripts propios del bloque C/D, con productos, stock y precios controlados
para cada caso. No se mezcla la definición del esquema ni los objetos
programables con las mutaciones de escenario en un mismo archivo.

---

## 13. Mapa de los tres motores

| Motor | Qué guarda | Quién manda | Construido en |
|---|---|---|---|
| PostgreSQL | Catálogo oficial, usuarios, pedidos, stock | Fuente de verdad: decide precio, stock y ventas | Unidades 1 a 6 |
| MongoDB | Colección `pedidos` con documentos embebidos (pedidos 1–5) | Solo sobre esos documentos | Unidad 7 |
| SQLite | Copia del catálogo, borradores y cola de envío | Nadie le pide que decida: solo prepara | Unidad 8 |

MongoDB no reemplaza PostgreSQL ni sincroniza automáticamente. Sus límites
están documentados en `unidades/unidad-7/README.md`.

---

## 14. Decisiones de diseño — resumen

| Decisión | Justificación |
|---|---|
| `::BIGINT` en lugar de `::INTEGER` para precio_centavos en la vista | `NUMERIC(12,2)` puede superar el rango de INTEGER en PostgreSQL; se evita error en conversión |
| `snapshot_servidor` como tabla STRICT con CHECK en booleanos | Detecta importaciones malformadas antes de proceder |
| Booleanos `TEXT('t'/'f')` en `snapshot_servidor`, convertidos en la carga | Preserva la representación del CSV sin ambigüedad; la conversión ocurre en un único punto |
| Fixture en base descartable separada | Evita que datos de prueba contaminen la base entregable |
| Renovación de `snapshot_servidor` en una transacción (`BEGIN` antes del `DELETE`) | Un fallo de importación o validación se deshace con ROLLBACK y conserva la instantánea anterior |
| UPSERT `ON CONFLICT(producto_id) DO UPDATE` en lugar de `INSERT OR REPLACE` | Actualiza la fila en su lugar, sin la semántica de borrado y reinserción; conserva lápidas |
| Aceptación de precio todo o nada (§7.2) | Si falta un producto en la instantánea o falla una sentencia, ROLLBACK: sin precios parciales ni solicitud nueva |
| `motivo` NULL solo en PENDIENTE sin evaluar; causa de mayor prioridad y menor `producto_id` | Resultado del semáforo reproducible y explicable |
| Índice parcial `ux_cola_una_pendiente` | Permite reenvíos con UUID nuevo; impide dos PENDIENTE simultáneos |
| No implementar idempotencia de servidor | El TP no lo pide; se documenta el patrón por referencia al apunte |
| Separar preparación de escenarios y simulación | La simulación no debe modificar PostgreSQL; la preparación es anterior y deliberada |
