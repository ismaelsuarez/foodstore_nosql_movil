# Tasks — Unidad 8: Base de datos móvil y sincronización

**Trabajo Práctico N.º 8 — Unidad 8 / Semanas 12 y 13**
Base de Datos II — UTN, Tecnicatura Universitaria en Programación
**Integrantes:** Avalos Pablo · Blangetti Sofia · Suarez Ismael

> Plan de tareas derivado de requirements.md y design.md, elaborados en Kiro.
> Una revisión técnica posterior identificó ajustes, incorporados en los tres
> documentos. Claude implementa el bloque B. Según informa el equipo, el
> docente autorizó sustituir OpenCode por Claude; esa autorización es
> información aportada por el equipo, no texto de la consigna. No constituye
> aprobación final del equipo ni aprobación docente.
> Solo se marca como realizado lo que se observó en una ejecución real, con
> la ubicación de su evidencia. Las observaciones de la revisión son insumos
> de diseño, no resultados ejecutados.

---

## Permisos generales

Las cinco categorías de permiso son independientes. Autorizar una no autoriza
las demás:

| Categoría | Qué incluye |
|---|---|
| **a) Especificaciones** | `requirements.md`, `design.md`, `tasks.md` |
| **b) Scripts** | `schema_sqlite.sql`, `pruebas_sqlite.sql`, `semaforo.sql`, `snapshot_movil.sql` y archivos similares |
| **c) Laboratorio PostgreSQL** | Levantar contenedor de pruebas, instalar esquema canónico, seed sintético, exportar CSV |
| **d) Pruebas y datos de prueba** | Ejecutar sqlite3 con scripts, preparar escenarios C2–C5, capturar evidencias; los escenarios se autorizan con el bloque que los contiene; solo afecta la base de pruebas |
| **e) Git modificador** | Staging, commit, push y crear etiqueta `tp8`; autorización de cierre en `main` registrada debajo |

Crear archivos (b) no autoriza un commit (e).
Crear especificaciones (a) no autoriza escribir scripts (b).
Cada bloque se autoriza una vez, nombrando sus recursos (bases, contenedores,
archivos), escenarios y operaciones; dentro de ese marco no hace falta pedir
autorización por cada sentencia. Lo que quede fuera del marco autorizado
requiere una autorización nueva.

**Autorización de cierre (2026-11-07):** Ismael autorizó versionar y publicar
el TP8 en `main` de `ismaelsuarez/foodstore_nosql_movil`, con etiqueta `tp8`
(ver `docs/bitacora_ia.md`, entrada 8). Esta decisión reemplaza la rama
`feat/u8-movil` prevista inicialmente. El versionado está en preparación;
no se registra aquí el resultado del commit/push.

---

## Bloque A — Especificaciones ✓

**Entregables:**
- `unidades/unidad-8/docs/kiro/requirements.md`
- `unidades/unidad-8/docs/kiro/design.md`
- `unidades/unidad-8/docs/kiro/tasks.md`

**Dependencias:** ninguna.

**Pruebas previstas:** lectura de los tres archivos después de crear;
verificación de que C1–C7 tienen trazabilidad; comprobación de Git.

**Evidencia a conservar:** estado de Git con los tres archivos nuevos
sin seguimiento (pending commit por el equipo).

**Permisos necesarios:** (a).

**Estado:** redactado en Kiro; la revisión técnica identificó ajustes que
se incorporaron (orden transaccional de C7, renovación transaccional de la
instantánea, UPSERT del catálogo, criterio de baja lógica CA-03g, regla de
`motivo`, invariancia por simulación en el bloque D). Sin aprobación final
del equipo y sin commit.

---

## Bloque B — Base SQLite: schema y pruebas

**Entregables:**
- `unidades/unidad-8/movil/schema_sqlite.sql`
- `unidades/unidad-8/movil/pruebas_sqlite.sql`
- Base SQLite descartable para las pruebas del bloque B, creada en un
  directorio temporal fuera del repositorio. Las pruebas B nunca abren ni
  modifican la base entregable `foodstore_movil.db`.

**Dependencias:** bloque A.

**Tareas:**

- B1: redactar `schema_sqlite.sql` con:
  - `PRAGMA foreign_keys = ON;`
  - Cuatro tablas STRICT (`producto_cache`, `pedido_borrador`,
    `item_borrador`, `cola_sync`) según design.md §3.
  - Índice `ux_cola_una_pendiente`.
  - Vista `v_catalogo_disponible`.

- B2: redactar `pruebas_sqlite.sql` con:
  - Al inicio de cada conexión: `PRAGMA foreign_keys = ON;` y verificación
    (debe devolver 1) antes de cualquier `BEGIN`.
  - Fixture sintética local en base descartable (design.md §9).
  - COMMIT exitoso: borrador + ítems + solicitud PENDIENTE (consigna 1.c).
  - ROLLBACK: operación deshecha; verificación de cero filas en las tres
    tablas (consigna 1.c).
  - C1: consulta de `v_catalogo_disponible` sobre la fixture; confirma
    que devuelve filas sin conectarse al servidor.
  - C7-a y C7-b siguen design.md §8: `BEGIN` → encabezado válido dentro
    de la transacción → comprobar la preparación → sentencia inválida →
    `ROLLBACK` en la misma sesión → cero filas de esa operación en las
    tres tablas.
  - C7-a: cantidad = 0; el error debe ser
    `CHECK constraint failed: cantidad > 0` en la línea de esa sentencia.
  - C7-b: producto inexistente; el error debe ser
    `FOREIGN KEY constraint failed` en la línea de esa sentencia.
  - Si el error esperado no ocurre, o el diagnóstico es otro (por ejemplo
    un error de sintaxis), la prueba se considera fallida aunque los
    conteos queden en cero. No se borran filas después del ROLLBACK.
  - C7-a y C7-b usan UUIDs distintos y son pruebas independientes.

- B3: ejecutar `pruebas_sqlite.sql` con `sqlite3` sobre la base
  descartable; capturar la salida estándar, la salida de error y los
  códigos de salida como evidencia. Un auxiliar Bash breve
  (`movil/verificar_bloque_b.sh`) solo organiza la ejecución y comprueba
  salidas y códigos; las operaciones SQL quedan en los archivos `.sql`.

**Pruebas previstas:** ver B2 arriba. Cada prueba negativa verifica
explícitamente que el error esperado ocurrió y que los conteos son cero
después del ROLLBACK.

**Evidencia a conservar:** salida de `sqlite3` para cada prueba
(archivo de texto en `unidades/unidad-8/evidencias/`).

**Permisos necesarios:** (b) para escribir scripts; (d) para ejecutar
sobre la base descartable.

**Estado (observado el 2026-11-07):** B1, B2 y B3 realizados.

- Scripts: `movil/schema_sqlite.sql`, `movil/pruebas_sqlite.sql` y el
  auxiliar `movil/verificar_bloque_b.sh`.
- Ejecución: `bash unidades/unidad-8/movil/verificar_bloque_b.sh <registro>`
  con `sqlite3` 3.54.1 y Bash 5.3.9, sobre
  `/tmp/gpIy264d/foodstore_u8_bloque_b.lmnc1q/prueba_bloque_b_descartable.db`
  (base temporal fuera del repositorio; `foodstore_movil.db` no se creó ni
  se abrió).
- Esquema: código de salida 0, sin errores.
- Pruebas: código de salida 1, esperado por los dos errores provocados;
  33 de 33 comprobaciones SQL en OK. La salida de error contiene
  exactamente `Error near line 201: CHECK constraint failed: cantidad > 0`
  (C7-a) y `Error near line 243: FOREIGN KEY constraint failed` (C7-b).
- Resultado: COMMIT, ROLLBACK, C1, C7-a y C7-b en OK; resultado global OK
  en el primer intento.
- Control negativo del verificador, sobre copias alteradas fuera del
  repositorio: si C7-a no produce error o C7-b produce un error de
  sintaxis, el verificador informa FALLA y termina con código 1.
- Evidencia: `unidades/unidad-8/evidencias/bloque_b_20261107_104530.txt` y
  `unidades/unidad-8/evidencias/bloque_b_control_negativo_20261107_104542.txt`.
- Sin commit. Los casos C2–C6 no se ejecutaron: dependen del semáforo
  (bloque D).

**Ajuste del auxiliar (observado el 2026-11-07):** la versión anterior
(`01e59b5a…`) usaba `principal | tee`, conservaba solo `PIPESTATUS[0]` e
imprimía "Registro guardado" aunque `tee` no pudiera escribir; con un `tee`
simulado que falla y con un directorio inexistente terminó con código 0.
La versión actual (`cf0cecca…`) comprueba antes de ejecutar las pruebas
que el registro no exista y que su directorio exista y admita escritura;
captura en un temporal del mismo directorio, conserva los dos estados de la
tubería, publica con `ln` sin sobrescribir y devuelve 2 si falla el guardado.
`schema_sqlite.sql` y `pruebas_sqlite.sql` no cambiaron.

- Registro nuevo válido: código 0, 33 de 33 comprobaciones en OK,
  resultado global OK.
- Registro existente: código 2, contenido sin cambios, pruebas no ejecutadas.
- Directorio inexistente: código 2, sin mensaje de guardado ni archivo.
- `tee` simulado que falla: código 2, sin mensaje de guardado, sin registro
  ni temporales restantes.
- Controles negativos de C7 sobre copias fuera del repositorio: código 1;
  C7-a y C7-b en FALLA.
- Evidencia: `unidades/unidad-8/evidencias/bloque_b_20261107_121805.txt`
  (ejecución con el auxiliar actual) y
  `unidades/unidad-8/evidencias/bloque_b_verificacion_registro_20261107_121806.txt`
  (casos de guardado y controles negativos). Las evidencias anteriores se
  conservan sin cambios.

---

## Bloque C — Laboratorio PostgreSQL e instantánea

**Entregables:**
- `unidades/unidad-8/postgresql/snapshot_movil.sql`
  (vista `v_snapshot_movil` + instrucciones de exportación)
- `unidades/unidad-8/movil/servidor_snapshot.csv`
  (datos sintéticos de prueba, no datos reales de producción)
- `snapshot_servidor` cargada en `foodstore_movil.db`
- `producto_cache` cargada en `foodstore_movil.db`

**Dependencias:** bloque B aprobado; autorización para levantar contenedor
PostgreSQL de pruebas.

**Tareas:** se numeran TC1–TC10 para no confundirlas con los casos de
prueba C1–C7 de la consigna.

- TC1: levantar un contenedor PostgreSQL de **pruebas** (nuevo, distinto de
  `foodstore-u6-evaluacion`).
- TC2: instalar el esquema canónico en la base de pruebas:
  `schema.sql` + `datos_iniciales.sql` + `objetos_programables.sql` del
  commit `8f7877c` de `foodstore_baseII`. Hacerlo desde archivos del
  repositorio relacional, leyéndolos con `git show u6-cierre:<ruta>`.
- TC3: insertar datos sintéticos de prueba (productos con precios, stock
  y estados controlados para los escenarios C2–C5). Estos datos son
  independientes del seed canónico y se insertan en un script separado.
- TC4: crear la vista `v_snapshot_movil` según design.md §5.
- TC5: exportar la instantánea base desde la vista, vía `docker exec`,
  hacia `movil/servidor_snapshot.csv` en el host.
- TC6: crear la tabla `snapshot_servidor` en SQLite según design.md §4.
- TC7: renovación transaccional (design.md §4 y §10): `BEGIN` →
  `DELETE FROM snapshot_servidor` → `.import --csv --skip 1` en la misma
  sesión.
- TC8: validar la importación (diagnósticos del cliente, conteos y NULLs)
  según design.md §4. `COMMIT` solo si importación y validación tienen
  éxito; si no, la transacción se revierte y no se continúa. Que se hayan
  importado algunas filas no basta para darla por exitosa.
- TC9: cargar `producto_cache` desde `snapshot_servidor` con conversión de
  booleanos `'t'`/`'f'` → `1`/`0` mediante UPSERT
  `ON CONFLICT(producto_id) DO UPDATE` (no `INSERT OR REPLACE`), conservando
  lápidas y sin modificar `item_borrador.precio_centavos_visto`.
- TC10: anotar la fecha real de la instantánea (`capturado_en` del CSV).

**Nota:** la preparación de escenarios (mutaciones de precio, stock y
estado) se realiza en el bloque D, no en este bloque. La instantánea base
de este bloque corresponde al estado inicial de la base de pruebas.

**Pruebas previstas:** validación de importación (TC8); verificación de
conteos en `producto_cache` y `snapshot_servidor`; consulta de
`v_catalogo_disponible` sobre la base resultante.

**Evidencia a conservar:** CSV exportado; salida de las validaciones;
`foodstore_movil.db` resultante.

**Permisos necesarios:** (c) para laboratorio; (d) para ejecutar
importación y carga; (b) para escribir `snapshot_movil.sql`.

**Estado (observado el 2026-11-07):** TC1–TC10 realizados. Guía operativa:
`unidades/unidad-8/docs/laboratorio_u8.md`.

- TC1: contenedor `foodstore-u8-postgres` (volumen `foodstore_u8_pg_data`,
  `--network none`, sin puertos, `no-new-privileges`), imagen
  `postgres@sha256:2d2b8998d31037bf721cfdf764d76ba74171b4fab3431b7f72c27c56ddbdf9e3`,
  PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2), base `foodstore_u8`.
- TC2: los tres archivos se leyeron con `git show u6-cierre:<ruta>`
  (blobs `9047b6f`, `ee9bb62`, `668b48c`); instalación con código 0 y las
  dos consultas de verificación del seed con 0 filas.
- TC3: `postgresql/datos_auxiliares_u8.sql`; ids devueltos por
  PostgreSQL: 4 (C2 precio), 5 (C3 stock), 6 (C4 baja), 7 (C5 sin cambios),
  8 (no disponible inicial), 9 (baja inicial). Seed: 1–3. Sin pedidos nuevos.
- TC4–TC5: `postgresql/snapshot_movil.sql` y
  `postgresql/exportar_snapshot.sql` (lectura REPEATABLE READ); 9 filas,
  `capturado_en` = `2026-11-07 15:51:24.499236+00`, SHA-256 del CSV
  `46bc4b6727d8e907c9113fd2aa3da16b350583b5e7625800a9403531b994bbfc`.
- TC6–TC10: `movil/snapshot_servidor.sql`, `movil/renovar_snapshot.sql`,
  `movil/preparar_foodstore_movil.sh`; `foodstore_movil.db` creada con
  `schema_sqlite.sql` (sin `pruebas_sqlite.sql`) y renovada con código 0.
- Pruebas del bloque C (`movil/verificar_bloque_c.sh` y
  `movil/consultas_bloque_c.sql`): correspondencia de valores CSV →
  `snapshot_servidor` → `producto_cache` y con el servidor, catálogo
  disponible 1–7, producto 8 no disponible y producto 9 con baja lógica
  (lápida), integridad, ausencia de la fixture B y
  tablas de borradores vacías: 17 de 17 en OK. Renovación repetida sobre
  copia: OK. Importaciones inválidas sobre copias (booleano `x`, fila
  faltante, columna sobrante): rechazadas con código 1 y contenido de
  `snapshot_servidor` y `producto_cache` idéntico al anterior.
- Evidencia: `evidencias/bloque_c_postgresql_20261107_125121.txt`,
  `evidencias/bloque_c_sqlite_20261107_130343.txt`,
  `evidencias/bloque_c_cierre_20261107_130545.txt` y
  `evidencias/bloque_c_cierre_complemento_20261107_130601.txt`. En los dos
  primeros registros de cierre, el listado del esquema falló por las comillas
  del comando de la sesión, no por la base; el complemento lo repite con
  código 0: 5 tablas, índice y vista; borradores 0/0/0; catálogo e
  instantánea con 9 filas; `integrity_check` ok.
- No se ejecutaron el semáforo ni los casos C2–C6 (bloque D).

---

## Bloque D — Semáforo y casos C2–C6

**Entregables:**
- `unidades/unidad-8/movil/semaforo.sql`
- Evidencias de cada caso (C2–C6) en `unidades/unidad-8/evidencias/`
- `foodstore_movil.db` con los resultados de los casos

**Dependencias:** bloque C completado.

**Tareas:**

- D1: redactar `semaforo.sql` según la lógica de design.md §6. Solo
  evalúa solicitudes con `estado = 'PENDIENTE'`. No modifica PostgreSQL.

**Preparación común a cada caso C2–C5:** cada caso usa su propio borrador
(`id_local`), sus propios ítems y su propia solicitud (`solicitud_uuid`),
con identificadores fijados y registrados en el script del caso. El borrador
y su solicitud PENDIENTE se crean con la transacción de design.md §7.1 sobre
el catálogo vigente. La invariancia del servidor se comprueba con stock y
cantidad de pedidos en PostgreSQL de pruebas inmediatamente antes y
inmediatamente después de cada simulación, una vez preparado el escenario.

- D2 — C2 (precio cambiado → CONFLICTO, luego aceptación → SIMULADO_APROBADO):
  - Borrador previo: crear el borrador del caso y su solicitud PENDIENTE
    con el precio vigente, antes de cambiar el servidor.
  - Preparación: subir el precio de un producto en la base PostgreSQL de
    pruebas; exportar nueva instantánea; importar y validar.
  - Verificar stock y cantidad de pedidos en PostgreSQL inmediatamente
    antes de simular.
  - Simular: correr `semaforo.sql` → resultado esperado: CONFLICTO;
    verificar motivo con ambos precios.
  - Verificar stock y cantidad de pedidos en PostgreSQL inmediatamente
    después: deben ser iguales a antes.
  - Aceptación del cliente: transacción local que actualiza
    `item_borrador.precio_centavos_visto` e inserta nueva solicitud
    (nuevo UUID, PENDIENTE).
  - Correr `semaforo.sql` sobre la nueva solicitud → SIMULADO_APROBADO.

- D3 — C3 (stock insuficiente → RECHAZADO):
  - Borrador del caso: crear el borrador y su solicitud PENDIENTE.
  - Preparación: reducir el stock de un producto en la base de pruebas
    por debajo de la cantidad del borrador; exportar nueva instantánea.
  - Verificar stock y pedidos en PostgreSQL antes de simular.
  - Simular → RECHAZADO. Verificar stock y pedidos después: sin cambios.

- D4 — C4 (baja lógica → RECHAZADO; lápida en catálogo):
  - Borrador previo: crear el borrador del caso y su solicitud PENDIENTE
    mientras el producto está vigente, antes de la baja en el servidor.
  - Preparación: dar de baja un producto (baja lógica) en la base de
    pruebas; exportar nueva instantánea; importar y cargar catálogo.
  - Verificar que el producto desaparece de `v_catalogo_disponible` pero
    su fila existe en `producto_cache` con `eliminado = 1`.
  - Verificar que `item_borrador.precio_centavos_visto` no se modificó.
  - Verificar stock y pedidos en PostgreSQL antes de simular.
  - Simular → RECHAZADO (CA-03g). Verificar stock y pedidos después: sin
    cambios.

- D5 — C5 (todo coincide → SIMULADO_APROBADO):
  - Borrador del caso sin discrepancias respecto de `snapshot_servidor`
    vigente, con su solicitud PENDIENTE.
  - Verificar stock y pedidos antes y después de simular: sin cambios.

- D6 — C6 (UUID duplicado; ausencia de reevaluación):
  - Prueba 1: intentar insertar el mismo `solicitud_uuid` en `cola_sync`
    → error de PK; la fila original conserva estado y motivo.
  - Prueba 2: ejecutar `semaforo.sql` nuevamente sobre una solicitud ya
    evaluada → no cambia su estado (no es PENDIENTE).
  - Las dos pruebas se documentan y evidencian por separado.
  - Incluir una oración sobre la protección real en el servidor
    (parada 8 del apunte; no implementada en el proyecto).

- D7 — Verificación de PostgreSQL por simulación:
  - Para cada simulación, comparar stock y cantidad de pedidos en
    PostgreSQL de pruebas inmediatamente antes y después, una vez
    preparado el escenario; deben coincidir.
  - No se exige que el stock final coincida con el inicial del bloque C:
    la preparación de los escenarios lo modifica deliberadamente.

**Pruebas previstas:** resultado de cada caso según consigna; verificación
de stock/pedidos antes y después de cada simulación; sin cambios en
PostgreSQL en ningún caso.

**Evidencia a conservar:** salida del semáforo por caso; consultas de
verificación de PostgreSQL; `foodstore_movil.db` actualizado.

**Permisos necesarios:** (b) para `semaforo.sql`; (d) para ejecutar
simulaciones y preparar escenarios en la base de pruebas.

**Estado (observado el 2026-11-07, ejecución `20261107_195358`):** D1–D7
realizados sobre `foodstore_movil.db`. Decisiones y valores: design.md §6.1.
Orden de ejecución: `docs/laboratorio_u8.md`.

- Copia íntegra de la base inicial de C, antes de D:
  `/tmp/foodstore_u8_copia_inicial_c.7CuDfN/foodstore_movil_inicial_c.db`
  (`81ca5120…`, igual a la base de C).
- Scripts: `movil/semaforo.sql`, `crear_borrador.sql`, `aceptar_precio.sql`,
  `insertar_solicitud.sql`, `comprobar_caso_d.sql`, `estado_bloque_d.sql`,
  `simular_producto_ausente.sql` (solo copias), `bloque_d.sh`,
  `ejecutar_bloque_d.sh`, `controles_d.sh`; `postgresql/preparar_c2_precio.sql`,
  `preparar_c3_stock.sql`, `preparar_c4_baja.sql`, `control_invariancia.sql`.
- Usuario de los borradores: `usuario_id_servidor = 1`, leído del seed.

| Caso | Borrador / solicitud | Preparación en PostgreSQL | Resultado observado |
|---|---|---|---|
| C2 | `d2000000-0000-4000-8000-0000000000b1` / `…c1`; aceptación `…c2` | producto 4: precio 1200.00 → 1320.00 | `…c1` CONFLICTO, motivo `producto_id=4: precio_visto=120000 centavos, precio_actual=132000 centavos`; aceptación simulada a 132000; `…c2` SIMULADO_APROBADO; `…c1` sin cambios |
| C3 | `d3000000-…-b1` / `…c1` | producto 5: stock 10 → 2 | RECHAZADO, `producto_id=5: stock disponible=2, cantidad solicitada=3` |
| C4 | `d4000000-…-b1` / `…c1` | producto 6: eliminado false → true | RECHAZADO, `producto_id=6: eliminado=t`; lápida en `producto_cache` (eliminado = 1), fuera de `v_catalogo_disponible`, precio visto 70000 sin cambio |
| C5 | `d5000000-…-b1` / `…c1` | ninguna | SIMULADO_APROBADO (no es venta ni reserva de stock) |
| C6-1 | reinserción de `d2000000-…-c1` | ninguna | `UNIQUE constraint failed: cola_sync.solicitud_uuid`; 5 filas antes y después; estado SQLite idéntico |
| C6-2 | semáforo repetido | ninguna | 0 procesadas; estado SQLite idéntico; el CONFLICTO original de C2 sigue igual |

- D7: en las seis simulaciones (C2, C2 tras la aceptación, C3, C4, C5 y
  C6-2), la lectura de PostgreSQL inmediatamente antes y después fue
  idéntica byte a byte: precio, stock, disponibilidad y baja de los 9
  productos; 5 pedidos (total 14700.00) y 7 líneas. `semaforo.sql` no
  contiene sentencias hacia PostgreSQL.
- Instantáneas (9 filas cada una) en `movil/instantaneas/20261107_195358/`:
  `c2_precio` (`f489d5d3…`), `c3_stock` (`d8526133…`), `c4_baja`
  (`6f3ea435…`). La instantánea inicial de C no cambió.
- Primer intento: la secuencia se detuvo en el paso 32 (comparación de C6-1)
  por un error de `ejecutar_bloque_d.sh`, que escribía los estados de C6-1 en
  la raíz del repositorio. La reinserción ya había dado el resultado
  esperado. Los cuatro archivos se movieron sin cambios al directorio de
  puntos, se corrigió el script y se agregó `--continuar-c6`, que comprueba
  C2–C5 y ejecuta solo C6 y el estado final, con código 0.
- Controles del diseño sobre copias descartables, no sobre la base
  entregable (`controles_d.sh`, resultado global OK): prioridad del
  rechazo (CA-03c); segunda PENDIENTE rechazada por `ux_cola_una_pendiente`
  (CA-04d); aceptación imposible por producto ausente de
  `snapshot_servidor`, detenida antes del UPDATE; fallo del INSERT después
  del UPDATE, con la actualización revertida. En los dos últimos, el estado
  de la copia quedó idéntico.
- Protección real en el servidor (parada 8 del apunte): en producción, el
  servidor debería registrar cada `solicitud_uuid` recibida (por ejemplo, una
  tabla `solicitud_movil` con `ON CONFLICT DO NOTHING`) para no procesar dos
  veces un reenvío. No está implementada en este proyecto: en el TP8 la
  protección es local (clave primaria de `cola_sync` y evaluación solo de
  PENDIENTE).
- Evidencia: `evidencias/bloque_d_entregable_20261107_195358.txt` (intento
  detenido en C6-1), `bloque_d_entregable_continuacion_c6_20261107_195500.txt`,
  `bloque_d_controles_copias_20261107_195510.txt` y
  `bloque_d_cierre_20261107_195631.txt`. Base cerrada al terminar D:
  `cf541fa5974d16f884c0d897916b7c72964b5171d7f89329f531d818a3a12ace`;
  `integrity_check` ok y `foreign_key_check` sin infracciones.
- Después de D no se vuelve a ejecutar `verificar_bloque_c.sh` sobre la base:
  comprueba el estado inicial de C, con tablas de borradores vacías.

---

## Bloque E — Integración, revisión, informe y cierre

### E1 — Mapa de los tres motores

Tabla de los tres motores según design.md §13: qué guarda cada uno y
quién manda. Se incluye en el informe (consigna 3.a).

### E2 — Agregado al plan de mantenimiento

Documento en `unidades/unidad-8/docs/` con referencia explícita a
`unidades/unidad-6/` del repositorio relacional. No modifica la entrega
de U6. Responde a:

- ¿Qué se respalda y cómo se prueba la restauración?
- Si se restaura un respaldo viejo de PostgreSQL, ¿qué hacen las tablets?
  (las tablets deben volver a descargar el catálogo).
- ¿Cada cuánto y quién revisa las solicitudes en CONFLICTO o RECHAZADO?

### E3 — Code review con IA

Revisión de todos los scripts de la cursada por unidades (U1–U8) con
asistencia de Claude. Se desarrollan al menos tres hallazgos de al menos
dos unidades distintas, con descripción de cómo se comprobó cada uno en
el motor. Al menos uno debe estar descartado con fundamento. Los hallazgos
son del trabajo real del equipo; no se copian los ejemplos del apunte.
Se registra en el informe (consigna 3.c) y en la bitácora.

### E4 — Bitácora de IA y DUIA

- `unidades/unidad-8/docs/bitacora_ia.md`: al menos tres entradas con
  qué se pidió a Claude, qué se aceptó, qué se descartó y por qué.
- `unidades/unidad-8/docs/DUIA.md`: Declaración de Uso de IA de la cátedra.

### E5 — README reproducible

`unidades/unidad-8/README.md` con el orden para crear todo desde cero.
La reproducción requiere una copia de trabajo nueva y un entorno Docker
sin `foodstore-u8-postgres` ni `foodstore_u8_pg_data` en el daemon del
contexto `default`; cambiar de usuario no garantiza independencia.
El script usa `--network none`, sin red propia ni puertos publicados
(`postgresql/laboratorio_u8.sh:16–18,26,69–74,84–89`). No se elimina el
laboratorio conservado. Este orden previsto no acredita un ensayo completo:

1. Verificar Bash y `sqlite3` disponibles (`sqlite3` con soporte de tablas
   STRICT, versión 3.37 o posterior). Python no es requisito.
2. Crear esquema SQLite (`schema_sqlite.sql`) sobre base nueva.
3. Levantar contenedor PostgreSQL de pruebas; instalar esquema canónico;
   insertar datos sintéticos.
4. Exportar instantánea base (`v_snapshot_movil` → CSV).
5. Importar CSV en SQLite; cargar `producto_cache`.
6. Ejecutar pruebas del bloque B.
7. Preparar escenarios C2–C5 (modificar base de pruebas; re-exportar).
8. Correr `semaforo.sql` para cada caso.
9. Verificar evidencias.

### E6 — Informe PDF (máximo 6 páginas)

Cubre consignas 1.a, 2.c, 3.a, 3.b y 3.c. Fuente editable recomendada:
HTML (como en U7). No incluye contraseñas ni datos personales reales.

### E7 — Ensayo de defensa (semana 13, 10 minutos)

1. Mapa de la capa de datos (tres motores, quién manda).
2. Demostración en vivo: crear la base desde cero y correr un caso que
   elija la cátedra.
3. Una decisión de diseño y la alternativa descartada.
4. Un hallazgo de la IA aceptado y uno descartado.

Cada integrante debe poder explicar cualquier script sin ayuda.

### E8 — Entrega

- ZIP o repositorio con etiqueta `tp8` en el campus, antes del cierre
  de la semana 13.
- Incluir `unidades/unidad-8/movil/foodstore_movil.db`.
  Si se usa `.gitignore`, declarar la excepción explícitamente.
- No hay entregas tardías.

**Permisos necesarios para E5–E8:** (b) para README e informe HTML;
(d) para verificar que el README funciona desde cero; (e) para la etiqueta
`tp8` al cierre.

**Estado (2026-11-07):** bloque E en curso, sin ejecución de motores, salvo
una lectura `sqlite3 -readonly` de la base final.

- Lectura de control de la base final: 8 de 8 comprobaciones OK.
  Comprueba 4 borradores, 5 solicitudes (2|1|2|0) e integridad, y que
  `snapshot_servidor` y `producto_cache` coinciden en sus siete valores con
  `instantaneas/20261107_195358/c4_baja`. Huella sin cambios (`cf541fa5…`).
  Evidencia: `evidencias/bloque_e_lectura_base_final_20261107_203411.txt`.
- E1 redactado: `docs/integracion_motores.md`.
- E2 redactado: `docs/mantenimiento_u8.md`. Responsables y frecuencias son
  propuestas; ninguna restauración de U8 se ejecutó.
- E3, revisión estática: `docs/revision_scripts_ia.md` y
  `docs/revision_inventario_scripts.md`.
  - **Cobertura:** de 120 scripts, 115 leídos completos y 5 de U7 cubiertos
    por correspondencia histórica con su auditoría (no lectura actual
    nueva); pendientes de lectura: 0. Los 84 scripts de `unidades/` U1–U6
    y `tpi/pruebas/` se distinguen de los 4 de raíz/TPI, 5 de U7 y 27 de
    U8. La lectura de los 84 la hicieron subagentes, con comprobación por
    muestreo de la sesión principal. La lectura faltante de
    `tpi/sql/consultas_cobertura_tpi.sql` fue comunicada por ChatGPT/Mila
    (conector GitHub, commit U6 fijado); se cotejó el blob local. No es
    revisión humana ni ejecución en PostgreSQL. Huella igual acredita
    identidad de versión, no revisión de contenido por sí sola.
  - **Fichas fundamentadas:** H1 (U6, descartado), H2-a (U6, documental),
    H3 (U3), H4 (U4, antecedente), H5 (U8, control previo comprobado) y
    H6 (U8, descartado para el caso y versión documentados).
    Selección principal para 3.c: **H1, H3 y H6**, aprobada por el equipo
    para su presentación en el informe, según comunicación de Ismael. H5 queda como complemento: no hay registro que reproduzca el
    `.import` original; e3 rechazó el CSV antes de abrir la base para renovar,
    no ejecutó esa importación en el motor.
  - **Hipótesis no ensayadas:** H2-b, concurrencia del respaldo; E-1 es
    opcional y no está autorizado. N2, N6 y N9, clasificadas en el
    inventario.
  - **Límite:** la aprobación del informe y de H1/H3/H6 comunicada por
    Ismael no acredita revisión humana individual de los 120 scripts ni
    aprobación de toda E3.
- E4:
  - La bitácora tiene ocho entradas más una entrada transversal sobre
    ChatGPT (Mila), con procedencia y límites de la lectura comunicada en
    esta conversación. La entrada 8 registra la autorización de cierre.
  - La versión actual de la DUIA es un **borrador del 2026-11-07**, incluido
    en el versionado TP8 autorizado: falta contrastarla con el formato de la
    cátedra y que el equipo la revise. Ese contraste formal no bloquea el
    versionado.
- Resguardo local: `~/.local/share/foodstore_u8_resguardos/20261107_205605/`,
  con las huellas comprobadas. Evidencia:
  `evidencias/bloque_e_resguardo_revision_*.txt`. No es un ensayo de
  restauración.
- E5 redactado: `unidades/unidad-8/README.md`. La reproducción completa desde
  cero no se ensayó. Se mantienen separados la consulta de la base final
  (sección A), la reproducción en un entorno nuevo (sección B) y el ensayo
  humano de defensa pendiente (E7). Las salidas enlazadas son evidencias
  históricas: leerlas no constituye una ejecución actual.
- Complemento puntual sin motores:
  `evidencias/bloque_e_complemento_20261107_212101.txt`. Conserva stdout,
  stderr y código inmediato de `sha256sum -c`: 48 huellas históricas
  coincidentes, incluida la base final; no reemplaza el registro anterior
  que mostró el código de `wc`. Resguardo nuevo de las 9 capturas C6:
  `~/.local/share/foodstore_u8_resguardos/20261107_205605/complemento_20261107_212146/`.
  Solo 2 capturas tienen huella histórica; en las otras 7 se comprobó
  únicamente la coincidencia actual de la copia.
- E6: **Informe revisado y aprobado por el equipo**, según comunicación de
  Ismael; no implica aprobación docente:
  `docs/informe.html` (autónomo) y `docs/informe.pdf` (A4, **6 páginas reales**).
  Chrome 157 realizó la conversión; el agente renderizó y revisó visualmente
  las seis páginas, corrigió paginación y un quiebre de identificador, y
  comprobó la extracción de texto y ausencia de recursos externos.
  Evidencia de generación original: `evidencias/bloque_e_informe_20261107_220745.txt`, con el
  comando, iteraciones y SHA-256 de aquella generación. La aprobación
  comunicada por Ismael y la actualización del estado del informe se registran
  en `evidencias/bloque_e_informe_aprobado_20261107_230321.txt`.
  La huella de la base sigue siendo
  `cf541fa5974d16f884c0d897916b7c72964b5171d7f89329f531d818a3a12ace`.
  No se ejecutaron motores, clientes de bases ni scripts de la cursada en
  esta generación documental; no se repitieron B/C/D.
- **E no está completo:** faltan revisión humana individual de los scripts,
  contraste de DUIA con el formato oficial, elección y ensayo humano de
  defensa (E7; guía en `docs/guia_defensa.md`) y E8 (preparación de la
  entrega elegida). La aprobación del equipo se limita al informe presentado,
  incluido H1/H3/H6; no acredita aprobación docente ni ensayo.
- La consigna admite **ZIP o repositorio con etiqueta `tp8`**. Ismael
  autorizó versionar y publicar en `main` de
  `ismaelsuarez/foodstore_nosql_movil`, con etiqueta `tp8`; está en
  preparación. El informe y H1/H3/H6 están aprobados por el equipo para su
  presentación (entrada 7 de la bitácora). El resultado del commit/push se
  comprueba después y no consta aquí. No consta ensayo humano ni aprobación
  docente, ni entrega en el campus; publicar en GitHub no reemplaza esa
  entrega. E sigue abierto en sentido académico.

---

## Estructura de archivos prevista

```
unidades/unidad-8/
├── README.md
├── movil/
│   ├── schema_sqlite.sql
│   ├── pruebas_sqlite.sql
│   ├── verificar_bloque_b.sh
│   ├── semaforo.sql
│   ├── servidor_snapshot.csv
│   └── foodstore_movil.db
├── postgresql/
│   └── snapshot_movil.sql
├── evidencias/
│   └── (salidas de ejecución por caso)
└── docs/
    ├── informe.html
    ├── informe.pdf
    ├── kiro/
    │   ├── requirements.md    ← este bloque
    │   ├── design.md          ← este bloque
    │   └── tasks.md           ← este bloque
    ├── bitacora_ia.md
    └── DUIA.md
```

`postgresql/` y `evidencias/` son decisiones organizativas del equipo,
no exigencias expresas de la consigna.

---

## Resumen de dependencias entre bloques

```
A (specs) → B (schema + pruebas SQLite)
          → C (laboratorio + instantánea)
          → D (semáforo + casos C2–C6)
          → E (integración + cierre)
```

Los bloques se encadenan en ese orden: cada uno empieza cuando el anterior
está completo y autorizado.
