# Guía para el ensayo de defensa — TP8

Consigna 4.c: ensayo de 10 minutos con el mapa de los tres motores, un caso
en vivo y un hallazgo de la IA. **El ensayo todavía no se realizó.** Esta guía
es una propuesta de preparación.

## Distribución propuesta (no acordada)

| Tramo | Minutos | Integrante (propuesta) |
|---|---:|---|
| 1. Mapa de los motores y regla de oro | 2 | Avalos Pablo |
| 2. Caso en vivo | 4 | Blangetti Sofia |
| 3. Decisión de diseño y alternativa descartada | 2 | Suarez Ismael |
| 4. Hallazgo de la IA aceptado y descartado | 2 | Rotativo |

Las preguntas son individuales: **cada integrante tiene que poder explicar
cualquier script**, no solo su tramo.

## 1. Papel y autoridad de cada motor

- **PostgreSQL** manda sobre catálogo, precio, stock y ventas.
- **MongoDB** (U7) guarda una representación documental de un lote de
  pedidos. No reemplaza a PostgreSQL y no se sincroniza.
- **SQLite** guarda la copia del catálogo, los borradores y los resultados
  locales. Propone; no decide.
- Frase clave: «`SIMULADO_APROBADO` no es una venta: no crea pedidos ni
  descuenta stock».
- Referencia: `docs/integracion_motores.md`.

## 2. Puntos técnicos que hay que poder explicar

| Tema | Qué decir | Dónde mirarlo |
|---|---|---|
| Transacción del borrador | Encabezado, ítems y solicitud PENDIENTE en un solo `BEGIN … COMMIT`; si algo falla, no queda nada | `movil/crear_borrador.sql`; `design.md` §7.1; pruebas COMMIT/ROLLBACK en `movil/pruebas_sqlite.sql` |
| Claves foráneas | `PRAGMA foreign_keys = ON` y su comprobación en cada conexión, antes del `BEGIN` | Cualquier script de `movil/` |
| Centavos | Precios como enteros; `::BIGINT` porque `NUMERIC(12,2)` supera `INTEGER` | `postgresql/snapshot_movil.sql`; `design.md` §5 |
| Instantánea | Conteo y datos de la misma transacción; la renovación y el catálogo se confirman juntos o no se confirman | `postgresql/exportar_snapshot.sql`; `movil/renovar_snapshot.sql` |
| Lápidas y productos ausentes | Una baja incluida en la instantánea queda con `eliminado = 1`, fuera del catálogo visible (C4). Una fila ausente de la instantánea se conserva sin cambios: no se convierte automáticamente en lápida ni necesariamente se oculta; el semáforo rechaza el ítem ausente. Los borradores conservan su precio | `movil/renovar_snapshot.sql:58–71,86–100`; `movil/schema_sqlite.sql:70–76`; `movil/semaforo.sql:55–69,92–101` |
| Semáforo y prioridad | Evalúa solo PENDIENTE contra `snapshot_servidor`. Primero RECHAZADO (inexistente, baja, no disponible, stock), después CONFLICTO (precio), y si no hay nada, SIMULADO_APROBADO. El motivo informa el ítem de menor `producto_id` | `movil/semaforo.sql`; `design.md` §6 |
| Aceptación del precio | Todo o nada: actualiza el precio visto e inserta una solicitud con UUID nuevo; la anterior conserva su CONFLICTO | `movil/aceptar_precio.sql`; C2; controles T3 y T4 |
| Error esperado frente a prueba fallida | En C7 la sentencia **debe** fallar con un diagnóstico concreto. Si no falla, o falla con otro error (por ejemplo de sintaxis), la prueba se considera fallida aunque los conteos den cero | `movil/verificar_bloque_b.sh`; control negativo `evidencias/bloque_b_control_negativo_20261107_104542.txt` |
| PostgreSQL no cambia | Se lee antes y después de cada simulación con una consulta de control: valores por producto y agregados de pedidos. No es una comparación de todas las columnas | `postgresql/control_invariancia.sql` |

## 3. Caso en vivo

La consigna prevé un caso elegido por la cátedra. La base entregada ya tiene
los resultados de D, así que **no se vuelve a preparar sobre ella**.
Estas opciones son propuestas: la elección humana y el ensayo siguen
pendientes; no consta aceptación docente de esta modalidad.

- **C7 mediante el verificador B, opción de ensayo en vivo:**
  `bash unidades/unidad-8/movil/verificar_bloque_b.sh`. El auxiliar crea un
  directorio temporal nuevo con `mktemp -d` y usa
  `prueba_bloque_b_descartable.db`, no la base entregada
  (`movil/verificar_bloque_b.sh:53–55,69–81`). Ejecutaría el bloque B completo
  (COMMIT, ROLLBACK, C1 y C7), no solo C7. Es una propuesta para preparar la
  defensa, **no ejecutada en esta corrección**; las ejecuciones históricas
  de B no equivalen al ensayo humano pendiente.
- **C2–C6, mostrar resultados históricos:** consulta de solo lectura con
  `bash unidades/unidad-8/movil/bloque_d.sh estado unidades/unidad-8/movil/foodstore_movil.db`.
  Mostrar el estado conservado no es ejecutar el caso en vivo.
- **C2–C6, ejecución en vivo:** haría falta un entorno nuevo que cumpla la
  sección B del README, sin el contenedor `foodstore-u8-postgres` ni el
  volumen `foodstore_u8_pg_data` en el daemon Docker usado por el contexto
  `default`. Cambiar de usuario no garantiza otro daemon. El script usa
  `--network none`, sin puertos publicados
  (`postgresql/laboratorio_u8.sh:16–18,26,69–74,84–89`).
  **La reproducción completa desde cero no está ensayada.**

Antes de la clase, el equipo debe elegir una opción y ensayarla, con los
permisos que requiera. Esta guía no autoriza ni registra una ejecución nueva.

## 4. Decisión de diseño y alternativa descartada

Se propone una de estas dos:

- **UPSERT en lugar de `INSERT OR REPLACE`** para cargar el catálogo.
  `REPLACE` borra y reinserta la fila; el UPSERT la actualiza en su lugar y
  conserva las lápidas (`design.md` §10).
- **Índice parcial `ux_cola_una_pendiente`** en lugar de `UNIQUE(id_local)`.
  Con `UNIQUE`, un borrador en CONFLICTO no podría reenviarse con una
  solicitud nueva. Ojo: este es también el ejemplo del apunte; si se elige,
  hay que presentarlo como decisión de diseño, no como hallazgo propio de la
  revisión.

## 5. Hallazgos de la revisión con IA

Ver `docs/revision_scripts_ia.md` §3 y fichas H1, H3 y H6. El inventario
cubre **115 lecturas completas + 5 correspondencias históricas U7 = 120**,
sin lecturas pendientes. Las correspondencias no son lecturas nuevas ni
revisión humana.

**Selección principal aprobada por el equipo para su presentación en el
informe (3.c): H1 (U6), H3 (U3) y H6 (U8)**, según comunicación de Ismael.
No implica aprobación docente. La elección de qué mostrar en vivo y el
ensayo siguen pendientes; las comprobaciones citadas son históricas, no
ejecuciones de esta preparación.

| Hallazgo | Qué presentar | Límite |
|---|---|---|
| H1, descartado | Restauración U6 validada con el origen ausente | Versión ensayada `68031b1f…`, modo `sin-propietarios`; la conclusión sobre la versión de cierre se apoya en el diff, no en una ejecución nueva |
| H3, aceptado como costo observado | Costo de escritura del índice por `lower(mail)` en U3 | Mediciones históricas bajo las condiciones de la ficha; no es un defecto ni una regla general |
| H6, descartado para el caso y versión documentados | C6-2: semáforo repetido, 0 procesadas y estado consultado idéntico | Versión `2635767318a7…`; no es comparación de toda la base |

**H5 queda complementario:** e3 muestra rechazo por el control previo del
auxiliar, sin abrir la base para renovar
(`evidencias/bloque_c_sqlite_20261107_130343.txt:219–227`). No hay registro
que reproduzca el comportamiento original de `.import`; no presentarlo
como una importación comprobada en el motor.

La hipótesis de concurrencia H2-b sigue sin ensayo: **E-1 es opcional y no
está autorizado**. No es un pendiente de lectura. La aprobación del informe
no acredita revisión humana individual de los 120 scripts.

## 6. Preguntas probables

- ¿Por qué `SIMULADO_APROBADO` no es una venta?
- ¿Qué pasa si la tablet ve un precio viejo?
- ¿Por qué un rechazo gana sobre un conflicto?
- ¿Qué hace la tablet si se restaura un respaldo viejo del servidor?
  Ver `docs/mantenimiento_u8.md` §3.
- ¿Dónde iría la protección real contra reenvíos? En el servidor, con un
  registro de `solicitud_uuid` (parada 8 del apunte). No está implementada.
