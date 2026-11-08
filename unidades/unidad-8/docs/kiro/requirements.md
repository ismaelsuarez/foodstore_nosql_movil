# Requirements — Unidad 8: Base de datos móvil y sincronización

**Trabajo Práctico N.º 8 — Unidad 8 / Semanas 12 y 13**
Base de Datos II — UTN, Tecnicatura Universitaria en Programación
**Integrantes:** Avalos Pablo · Blangetti Sofia · Suarez Ismael

> Especificación elaborada en Kiro. Una revisión técnica posterior identificó
> ajustes, incorporados en esta versión. Claude implementa el bloque B a partir
> de este documento. Según informa el equipo, el docente autorizó sustituir
> OpenCode por Claude; esa autorización es información aportada por el equipo,
> no texto de la consigna. Este documento no constituye aprobación final del
> equipo ni aprobación docente.
> Los requisitos derivan de la consigna `BDII-U8-TP8-Food-Store.pdf` y del
> apunte `BDII-U8-Material-Teorico-Food-Store.pdf`. Los criterios de aceptación
> son verificables sobre la base SQLite local y la base PostgreSQL de pruebas.

---

## Regla de oro

El móvil propone, el servidor dispone. La tablet consulta y arma borradores.
Precio, stock y ventas los decide PostgreSQL. `SIMULADO_APROBADO` no es una
venta ni reserva stock.

---

## REQ-01 — Catálogo local y conservación de lápidas

**Notación EARS:**

```
WHEN el vendedor consulta el catálogo en la tablet
THE SYSTEM SHALL devolver únicamente los productos con eliminado = 0
y disponible_visto = 1 desde producto_cache, sin requerir conexión
activa al servidor PostgreSQL.

WHEN se carga una nueva instantánea con un producto cuyo eliminado
es 't' o cuyo disponible es 'f' en snapshot_servidor
THE SYSTEM SHALL actualizar la fila correspondiente en producto_cache
(eliminado = 1 o disponible_visto = 0) sin eliminarla físicamente,
de modo que los item_borrador que referencian ese producto_id
conserven sus valores precio_centavos_visto sin modificación automática.
```

**Criterios de aceptación:**

- CA-01a: la vista `v_catalogo_disponible` devuelve solo filas con
  `eliminado = 0 AND disponible_visto = 1`; los productos con lápida
  (`eliminado = 1`) no aparecen en la vista pero su fila existe en
  `producto_cache`.
- CA-01b: un borrador cuyos ítems referencian un producto dado de baja
  puede seguir leyéndose desde `item_borrador`; `precio_centavos_visto`
  no se modifica al renovar el catálogo.
- CA-01c: la consulta de catálogo no falla si el servidor PostgreSQL
  no está disponible; no exige detener los contenedores conservados.

**Trazabilidad:** C1 (consulta local sin servidor), C4 (lápida conservada
tras baja lógica).

---

## REQ-02 — Guardado atómico del borrador y rechazo de datos inválidos

**Notación EARS:**

```
WHEN el sistema guarda un nuevo pedido borrador
THE SYSTEM SHALL insertar en una sola transacción (BEGIN … COMMIT)
las filas de pedido_borrador, de item_borrador y de cola_sync
(con estado PENDIENTE), de modo que todas se graben o no se grabe ninguna.

WHEN una sentencia dentro de esa transacción produce un error por
restricción (CHECK o FOREIGN KEY), la sentencia falla y la transacción
permanece activa.
THE SYSTEM SHALL ejecutar ROLLBACK explícito y no dejar filas nuevas
en pedido_borrador, item_borrador ni cola_sync para esa operación.
```

**Criterios de aceptación:**

- CA-02a: después de un COMMIT exitoso, existen exactamente una fila en
  `pedido_borrador`, N filas en `item_borrador` y una fila en `cola_sync`
  con `estado = 'PENDIENTE'` para ese `id_local`.
- CA-02b: después de un ROLLBACK explícito, las tres tablas no contienen
  filas con el `id_local` de esa operación.
- CA-02c: intentar un ítem con `cantidad = 0` produce un error de CHECK
  (`cantidad > 0`); la sentencia INSERT falla; se ejecuta ROLLBACK;
  ninguna de las tres tablas contiene filas nuevas de esa operación.
  Esta prueba es independiente de CA-02d.
- CA-02d: intentar un ítem con un `producto_id` que no existe en
  `producto_cache` produce un error de FOREIGN KEY; la sentencia INSERT
  falla; se ejecuta ROLLBACK; ninguna de las tres tablas contiene filas
  nuevas de esa operación. Esta prueba es independiente de CA-02c.
- CA-02e: en cada conexión utilizada, `PRAGMA foreign_keys` se activa con
  `PRAGMA foreign_keys = ON` y se verifica (`SELECT * FROM pragma_foreign_keys`
  devuelve 1) antes de ejecutar cualquier `BEGIN`.
- CA-02f: si la sentencia problemática no produce el error esperado, la
  prueba se considera fallida aunque un ROLLBACK posterior deje los conteos
  en cero. El error se reconoce por el diagnóstico real del cliente `sqlite3`
  asociado a esa sentencia (`CHECK constraint failed: cantidad > 0` o
  `FOREIGN KEY constraint failed`); un error de sintaxis u otro fallo no
  equivale al error esperado.
- CA-02g: en C7-a y C7-b, `BEGIN` se ejecuta antes de insertar el
  `pedido_borrador` de la operación; el encabezado que se espera deshacer
  se inserta dentro de la transacción. Las filas de esa operación no se
  borran después para aparentar que el ROLLBACK funcionó.
- CA-02h: las pruebas de este requisito se ejecutan sobre una base SQLite
  descartable, nunca sobre la base entregable `foodstore_movil.db`.

**Trazabilidad:** COMMIT y ROLLBACK de consigna 1.c, C7-a (cantidad = 0),
C7-b (producto inexistente).

---

## REQ-03 — Evaluación del semáforo, prioridad y ausencia de escritura en PostgreSQL

**Notación EARS:**

```
WHEN el sistema evalúa solicitudes en cola_sync
THE SYSTEM SHALL procesar únicamente las filas con estado = 'PENDIENTE'
y actualizar su estado y motivo según las siguientes reglas,
en orden de prioridad decreciente:
  1. RECHAZADO: algún ítem del borrador no existe en snapshot_servidor,
     o su disponible es 'f', o su eliminado es 't', o la cantidad
     supera el stock de snapshot_servidor.
  2. CONFLICTO: no se cumple la condición 1, pero algún ítem tiene
     precio_centavos_visto distinto del precio_centavos de snapshot_servidor.
  3. SIMULADO_APROBADO: no se cumple ninguna de las condiciones anteriores.

THE SYSTEM SHALL registrar en cola_sync.motivo información suficiente
para identificar el ítem problemático; en caso de CONFLICTO, el motivo
debe incluir el precio visto y el precio actual en centavos.
motivo es NULL mientras la solicitud está PENDIENTE sin evaluar y contiene
un mensaje explicativo en toda solicitud evaluada, incluida
SIMULADO_APROBADO. Si hay varios problemas, el motivo corresponde a la
causa que determina el estado de mayor prioridad; entre los ítems con esa
causa se informa el de menor producto_id.

THE SYSTEM SHALL NOT modificar ninguna fila en la base PostgreSQL
durante la evaluación.
```

**Criterios de aceptación:**

- CA-03a: una solicitud con un ítem cuya cantidad supera el stock de
  `snapshot_servidor` resulta en RECHAZADO; la cantidad de pedidos y el
  stock en PostgreSQL de pruebas no cambian respecto al estado inmediatamente
  anterior a la simulación.
- CA-03b: una solicitud con un ítem cuyo precio difiere y sin condición de
  rechazo resulta en CONFLICTO; el motivo registra ambos precios en centavos.
- CA-03c: si un borrador tiene un ítem rechazable (stock, disponibilidad o
  baja) y otro con precio distinto, el resultado es RECHAZADO (prioridad 1
  sobre 2).
- CA-03d: una solicitud sin ninguna discrepancia resulta en
  SIMULADO_APROBADO; el stock en PostgreSQL de pruebas no cambia.
- CA-03e: SIMULADO_APROBADO no descuenta stock, no crea pedido ni confirma
  ninguna venta en PostgreSQL.
- CA-03f: ejecutar el semáforo por segunda vez no cambia el estado de
  solicitudes ya evaluadas (no son PENDIENTE).
- CA-03g: una solicitud con un ítem cuyo producto tiene `eliminado = 't'`
  en `snapshot_servidor` (baja lógica) resulta en RECHAZADO; el motivo
  identifica el `producto_id` y la baja; el stock y la cantidad de pedidos
  en PostgreSQL de pruebas no cambian.
- CA-03h: `motivo` es NULL en las solicitudes PENDIENTE sin evaluar y no es
  NULL en las evaluadas; con varios problemas, informa la causa del estado
  de mayor prioridad y, dentro de ella, el ítem de menor `producto_id`.

**Trazabilidad:** C2 (parte del CONFLICTO), C3 (stock insuficiente), C4
(baja lógica, CA-03g), C5 (todo coincide).

---

## REQ-04 — UUID de solicitud, reintentos sin reevaluación y aceptación explícita de precio

**Notación EARS:**

```
WHEN el sistema intenta insertar en cola_sync una solicitud con un
solicitud_uuid que ya existe
THE SYSTEM SHALL rechazar la inserción con error de clave primaria
y conservar el estado y el motivo de la fila existente sin modificarlos.

WHEN el semáforo se ejecuta sobre una solicitud cuyo estado no es
'PENDIENTE'
THE SYSTEM SHALL omitirla sin cambiar su estado ni su motivo.

WHEN el cliente acepta el precio nuevo tras un resultado CONFLICTO
THE SYSTEM SHALL, en una sola transacción local, actualizar
item_borrador.precio_centavos_visto con el precio actual de
snapshot_servidor e insertar una nueva fila en cola_sync con un nuevo
solicitud_uuid y estado PENDIENTE.
La solicitud previa conserva su estado CONFLICTO y su motivo; no se
modifica su fila en cola_sync.
El precio actualizado en item_borrador no proviene de una columna
adicional de cola_sync sino de snapshot_servidor.
```

**Criterios de aceptación:**

- CA-04a: insertar el mismo `solicitud_uuid` en `cola_sync` produce error
  de PK; la fila original conserva estado y motivo exactamente iguales a
  los anteriores.
- CA-04b: ejecutar el semáforo después de que una solicitud ya fue evaluada
  no cambia su estado (la fila no es PENDIENTE); el semáforo no la procesa.
- CA-04c: tras aceptar el precio nuevo, `item_borrador.precio_centavos_visto`
  contiene el valor de `snapshot_servidor.precio_centavos`; la nueva solicitud
  tiene un UUID distinto del anterior, estado PENDIENTE y, evaluada por el
  semáforo sin otras discrepancias, resulta en SIMULADO_APROBADO.
- CA-04d: el índice `ux_cola_una_pendiente` impide que el mismo `id_local`
  tenga dos filas con `estado = 'PENDIENTE'` simultáneas; permite una nueva
  solicitud PENDIENTE cuando la solicitud anterior ya no está en ese estado.
- CA-04e: C6 requiere que se verifiquen ambas cosas por separado: (1) el
  error de PK por UUID duplicado y (2) la ausencia de reevaluación al
  repetir el semáforo.

**Trazabilidad:** C6 (CA-04a y CA-04b), segunda parte de C2 (CA-04c y
CA-04d).

---

## Tabla de trazabilidad completa

| Caso | REQ | Criterios de aceptación |
|------|-----|------------------------|
| C1   | REQ-01 | CA-01a, CA-01c |
| C2 (CONFLICTO) | REQ-03 | CA-03b, CA-03h |
| C2 (aceptación + nueva solicitud) | REQ-04 | CA-04c, CA-04d |
| C3   | REQ-03 | CA-03a |
| C4 (RECHAZADO) | REQ-03 | CA-03g; además CA-03c si también hay precio distinto |
| C4 (lápida) | REQ-01 | CA-01a, CA-01b |
| C5   | REQ-03 | CA-03d, CA-03e |
| C6   | REQ-04 | CA-04a, CA-04b, CA-04e |
| C7-a | REQ-02 | CA-02c, CA-02e, CA-02f, CA-02g, CA-02h |
| C7-b | REQ-02 | CA-02d, CA-02e, CA-02f, CA-02g, CA-02h |
| COMMIT / ROLLBACK | REQ-02 | CA-02a, CA-02b, CA-02h |
