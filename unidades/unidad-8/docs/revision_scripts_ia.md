# Revisión de los scripts de la cursada con IA — Unidad 8

Consigna 3.c del TP8. **Estado:** 115 lecturas completas de 120 scripts,
incluida la lectura de ChatGPT/Mila comunicada en esta conversación; los
5 de U7 se cubren por correspondencia histórica con su auditoría, no como
lectura actual nueva. No quedan lecturas pendientes en el inventario.
Hay seis fichas con alcances de evidencia diferenciados. El equipo aprobó
el informe presentado, incluido H1/H3/H6, según comunicación de Ismael.
Esto no acredita revisión humana individual de los 120 scripts ni
aprobación de toda la tarea E3.

## 1. Método y herramientas

- La consigna pide usar OpenCode en el agente Plan. Según informa el equipo,
  el docente autorizó sustituir OpenCode por Claude. La revisión la hizo
  Claude en las sesiones del 2026-11-07, con subagentes de exploración de
  solo lectura (`gentle-ai-explore`): uno hizo el mapeo inicial de U1–U6 y
  tres hicieron la lectura completa archivo por archivo. La sesión principal
  volvió a comprobar con `git show` una muestra de los fragmentos. Ninguna de
  esas lecturas es una revisión humana.
- Según informó el equipo, ChatGPT (Mila) revisó, fuera del repositorio,
  especificaciones, código y evidencias compartidas en el chat. Esa revisión
  no dejó registros propios en el repositorio. En este complemento se
  registra específicamente su lectura completa de
  `tpi/sql/consultas_cobertura_tpi.sql`, vía conector GitHub con el commit U6
  fijado; fue comunicada en esta conversación y se cotejó el blob local
  `1c5bb99ef73492e9cff364bcdfdde91c8906b095`. No se atribuye a Claude ni a
  revisión humana; no se ejecutó en PostgreSQL ni se comprobaron sus
  resultados o todos sus enlaces relativos (ver inventario y bitácora).
- No se creó la rama `review-final` que sugiere el apunte (parada 10): en esta
  intervención no había permiso para crear ramas. La revisión se hizo sobre
  referencias fijas: U1–U6 en `foodstore_baseII` `u6-cierre`
  (`8f7877c8…`), leída con `git show`; U7 en `u7-cierre` (`703583e2…`); U8
  sobre los archivos actuales, identificados por su huella.
- En esta intervención **no se ejecutó ningún motor**: no se usó Docker ni
  PostgreSQL. Cada hallazgo se apoya en evidencia ya existente, registrada en
  la versión revisada, o queda pendiente con un ensayo propuesto. Una
  observación estática no es una prueba ejecutada.
- Los ejemplos del apunte («hacé UNIQUE la columna `id_local`», «usá la hora
  de la tablet») no se cuentan como hallazgos del proyecto.

## 2. Inventario por unidad

El inventario archivo por archivo (ruta, blob, propósito, resultado,
evidencia y pendiente) está en
[revision_inventario_scripts.md](revision_inventario_scripts.md). Resumen:

| Unidad | Scripts | Leídos completos | Pendientes |
|---|---:|---:|---|
| Raíz + `tpi/sql/` | 4 | 4 | — |
| `tpi/pruebas/` | 8 | 8 | — |
| U1 | 1 | 1 | — |
| U2 | 8 | 8 | — |
| U3 | 5 | 5 | — |
| U4 | 6 | 6 | — |
| U5 | 51 | 51 | — |
| U6 | 5 | 5 | — |
| U7 | 5 | por correspondencia de huellas con la auditoría U7 | — |
| U8 | 27 | 27 | — |

Total: **115 lecturas completas + 5 correspondencias históricas U7 = 120**;
pendientes de lectura: **0**. Los «84 scripts» corresponden solo a
`tpi/pruebas/` y `unidades/` de U1–U6; sumados a raíz/TPI (4), U7 (5) y
U8 (27) dan 120. La huella igual acredita identidad de versión, no por sí
sola revisión del contenido.

Los archivos con nombres parecidos en distintas carpetas de U5 tienen blobs
distintos; las copias archivadas bajo `evidencia/` se registran como
artefactos y no se cuentan como hallazgos aparte.

La tabla siguiente es la versión anterior de esta sección, que se conserva
como registro de la primera pasada (2026-11-07, 20:34). Sus pendientes de U1,
U2 y U5 quedaron cubiertos por el inventario detallado.

| Unidad | Archivos (cantidad) y función | Revisión realizada | Evidencia existente relevante | Observaciones / pendientes |
|---|---|---|---|---|
| Raíz / TPI | `schema.sql`, `datos_iniciales.sql` (2): modelo y seed. `tpi/sql/objetos_programables.sql`, `tpi/sql/consultas_cobertura_tpi.sql`, `tpi/pruebas/` (10): rutinas, triggers y pruebas transaccionales | Lectura de los tres archivos de instalación; reinstalados desde `git show` en el bloque C de U8 | `unidad-8/evidencias/bloque_c_postgresql_20261107_125121.txt` (instalación con código 0, verificaciones del seed con 0 filas); `unidad-6/evidencias/correccion_restauracion_20261105.txt` | `tpi/pruebas/` no se revisó archivo por archivo |
| U1 | `unidades/unidad-1/tp2/sql/restricciones_integridad.sql` (1) | Ubicado; sin lectura detallada | No se vinculó a una salida específica | Pendiente |
| U2 | `unidades/unidad-2/tp3/sql/` y `tp4/sql/` (8): carga masiva, consultas y alternativas | Ubicados; sin lectura detallada | `unidad-2/tp3/duia/duia_tp3.md`, líneas 14–24 (relato de la carga) | Pendiente vincular cada consulta a su medición |
| U3 | `unidades/unidad-3/sql/` (5): índices, vistas, materializada, consultas y seguridad | Lectura de `indices.sql` y de su informe de mediciones | `unidad-3/informes/evidencia_modelo_oficial.md` (mismo commit `da5f3e4` que `indices.sql`) | Hallazgo H3 |
| U4 | `unidades/unidad-4/sql/` (6): FNBC, candidato de desnormalización, carga, benchmark y pruebas | Lectura del candidato y de las evidencias de decisión | `unidad-4/informes/evidencia_implementacion_candidato_a_modelo_canonico.md`; `evidencia_read_after_decision_modelo_canonico.md` | Hallazgo H4 |
| U5 | `unidades/unidad-5/sql/`, `sql/pruebas/`, `poc_permisos/`, `validacion_parte_a/` (51): roles, funciones, auditoría, permisos y arneses | **No revisados archivo por archivo** | No contrastada | Pendiente; es la principal falta de cobertura |
| U6 | `unidades/unidad-6/` (5): `backup_foodstore.sh`, `restore_test.sh`, `health_check.sql`, `maintenance.sql`, `validaciones.sql` | Lectura de los dos scripts de respaldo y restauración, con huellas | `unidad-6/evidencias/ensayo_evaluacion_20261105.txt`; `correccion_restauracion_20261105.txt` | Hallazgos H1 y H2 |
| U7 | `unidades/unidad-7/postgresql/` (2) y `mongodb/` (3) en `u7-cierre` | Ya auditados en U7 (revisión R1–R6); no se repitió esa auditoría | `unidad-7/evidencias/` | Sin hallazgos nuevos en esta intervención |
| U8 | `movil/` (18) y `postgresql/` (9), huellas en `unidad-8/evidencias/bloque_d_cierre_20261107_195631.txt` | Escritos y ejecutados en los bloques B–D | Evidencias `bloque_b_*`, `bloque_c_*`, `bloque_d_*` | Hallazgos H5 y H6 |

## 3. Tabla de hallazgos

| # | Unidad | Archivo | Observación | Decisión | Motivo |
|---|---|---|---|---|---|
| H1 | U6 | `restore_test.sh` | «La restauración necesita que exista la base de origen» | **Descartado** | La evidencia muestra una restauración validada con el origen ausente |
| H2-a | U6 | `backup_foodstore.sh` | El comentario dice que la versión con línea base no fue probada, pero hay una ejecución de esa misma versión | **Aceptado** (documental) | Misma huella en la evidencia de ejecución |
| H2-b | U6 | `backup_foodstore.sh` | Escrituras entre la línea base y `pg_dump` | **Hipótesis no ensayada** | El propio script declara el límite; E-1 no está autorizado |
| H3 | U3 | `sql/indices.sql` | El índice `idx_usuario_mail_lower` encarece la escritura | **Aceptado** como costo medido | Escritura de `usuario` +91,88 %; lectura de 10,89 a 0,14 ms |
| H4 | U4 | `sql/tp_desnormalizacion_top_categorias.sql` | El candidato desnormalizado puede producir deadlocks y no cumple su criterio de recursos | **Aceptado** (antecedente ya resuelto en U4) | Deadlock 40P01 registrado; decisión final `REJECT / DO_NOT_ADOPT` |
| H5 | U8 | `movil/preparar_foodstore_movil.sh` | Comportamiento original de `.import` informado, sin registro disponible que lo reproduzca | **Complemento: control previo comprobado** | e3 rechaza el CSV antes de abrir la base para renovar; no prueba una importación en el motor |
| H6 | U8 | `movil/semaforo.sql` | «El semáforo podría volver a evaluar solicitudes ya evaluadas» | **Descartado para el caso y versión documentados** | Filtro `estado = 'PENDIENTE'` más el caso C6-2 con 0 procesadas |

Las hipótesis surgidas en la lectura completa (N1–N9) se clasifican en
[revision_inventario_scripts.md §10](revision_inventario_scripts.md). Ninguna
se agrega como ficha para completar una cuota.

**Selección aprobada por el equipo para su presentación en el informe
(consigna 3.c): H1, H3 y H6 como principales**, de U6, U3 y U8, según
comunicación de Ismael. No implica aprobación docente.
Las referencias se contrastaron por lectura en este complemento; las
comprobaciones en motores son históricas, no ensayos nuevos.

| Hallazgo | Unidad | Decisión | Comprobación en el motor |
|---|---|---|---|
| H1 | U6 | Descartado | Restauración con el origen ausente (2026-11-05), sobre la versión `68031b1f…`; la diferencia con la de cierre se justifica con el diff |
| H3 | U3 | Aceptado como costo observado | Mediciones `EXPLAIN ANALYZE` del 2026-09-20 sobre la misma versión (`da5f3e4`) |
| H6 | U8 | Descartado para el caso y versión documentados | Caso C6-2 del bloque D, versión `2635767318a7…`; 0 procesadas y comparación del estado consultado |

**H5 queda como complemento**, no como comprobación del comportamiento
original de `.import` en el motor: no hay registro disponible que lo
reproduzca. e3 acredita el rechazo por el control previo del auxiliar;
el registro dice «no se abre la base». H2-a (documental) y H4 (antecedente)
son otros complementos. E-1 continúa opcional y no autorizado.

Referencias contrastadas para esta selección:

- **H1:** `foodstore_baseII/unidades/unidad-6/evidencias/correccion_restauracion_20261105.txt:17,122–130,158–172`:
  versión ensayada `68031b1f…`, origen ausente y restauración validada.
  El diff `451718f..u6-cierre` de `restore_test.sh` cambia solo comentario
  y mensajes (líneas de cierre 34, 89, 243 y 317), no la conexión ni la
  restauración; huella de cierre `973223df…`.
- **H3:** `foodstore_baseII/unidades/unidad-3/informes/evidencia_modelo_oficial.md:18–23,97–104,207–208,258,288–302`:
  entorno/fecha, protocolo, medias de lectura y escritura, y límites del
  costo. El cálculo (14,7085 − 7,6655) / 7,6655 × 100 da 91,8792 %.
- **H5:** `unidades/unidad-8/evidencias/bloque_c_sqlite_20261107_130343.txt:219–227`:
  CSV sobrante, código 1, rechazo previo sin abrir la base para renovar y
  tablas de catálogo/instantánea idénticas; no reproduce el `.import` original.
- **H6:** `unidades/unidad-8/evidencias/bloque_d_entregable_continuacion_c6_20261107_195500.txt:147–154,177–197`:
  0 procesadas, controles OK, estado consultado idéntico y CONFLICTO original
  conservado (no es comparación de toda la base). Filtros contrastados en
  `unidades/unidad-8/movil/semaforo.sql:56,103–109`; control de evaluadas en
  líneas 125–129.

Trazabilidad y huellas: `evidencias/bloque_e_complemento_20261107_212101.txt`.

## 4. Fichas

### H1 — U6: la restauración no depende de la base de origen (descartado)

- **Hipótesis:** `restore_test.sh` recibe `-s BASE_ORIGEN`; un revisor puede
  suponer que se conecta a ella y que, sin el origen, no se puede restaurar.
- **Fragmento:** `unidades/unidad-6/restore_test.sh`, líneas 11–13:
  «`-s` base de origen registrada en el .baseline. Solo se usa para comprobar
  la procedencia […] No necesita existir y el script nunca se conecta a ella.»
- **Se esperaba**, si la hipótesis fuera cierta, que la restauración fallara
  con el origen ausente.
- **Comprobación en el motor (histórica):**
  `unidades/unidad-6/evidencias/correccion_restauracion_20261105.txt`. La base
  origen se renombra (línea 122), la consulta a `pg_database` informa
  `u6_fix_origen|ausente` (línea 128) y la restauración termina en
  `RESULTADO=RESTAURACION_VALIDADA` con `exit=0` (líneas 168–172).
- **Versión ensayada y versión de cierre no son idénticas.** La evidencia
  registra `restore_test.sh` con huella SHA-256 `68031b1f…`, que es la del
  commit `451718f`. En `u6-cierre` (`8f7877c8…`) la huella es
  `973223df…`. `git diff 451718f u6-cierre -- unidades/unidad-6/restore_test.sh`
  muestra 4 líneas cambiadas, todas en mensajes que el script imprime o
  registra (`printf 'METAS=…'`, `log INFO …`) o en un comentario: el texto
  «metas RPO/RTO pendientes de aprobación» pasa a «El script registra las
  mediciones; su comparación con los objetivos se documenta en el informe y
  en SPEC_U6.md». Ninguna línea cambiada participa en la conexión, en
  `createdb` ni en `pg_restore`.
- **Decisión: descartado**, para la versión `68031b1f…`, el modo
  `sin-propietarios` y el caso ensayado. Para la versión de cierre, la
  conclusión se apoya en ese diff, no en una ejecución propia.

### H2 — U6: comentario desactualizado (aceptado) y concurrencia (hipótesis no ensayada)

H2 tiene dos partes, con distinto respaldo.

**H2-a, observación documental (aceptada).**

- **Fragmento:** `unidades/unidad-6/backup_foodstore.sh`, líneas 22–23: «Esta
  versión (con línea base) todavía no fue probada funcionalmente».
- **Comprobación:** la huella de `backup_foodstore.sh` en `u6-cierre`
  (`3b8e39c8…`) es la misma que registra
  `unidades/unidad-6/evidencias/ensayo_evaluacion_20261105.txt` (línea 64). En
  esa ejecución del mismo archivo, la línea base y `pg_dump` terminaron con
  `exit=0` (líneas 81–83) y la restauración posterior quedó validada
  (líneas 100–117). El comentario contradice esa evidencia.
- **Decisión: aceptado** como inconsistencia documental, no funcional. Cambio
  propuesto, no aplicado (U6 no se modifica): actualizar el comentario para
  citar el ensayo del 2026-11-05.

**H2-b, concurrencia (hipótesis no ensayada, no es un defecto confirmado).**

- **Fragmento:** líneas 19–21: «El script no garantiza ni impone esa
  ventana: la línea base y pg_dump usan instantáneas distintas.» El propio
  script declara el límite y exige una ventana sin escrituras.
- **Lo que muestra la evidencia:** la ejecución registró
  `sesiones_en_origen=0` (línea 76). Prueba una corrida sin escrituras, no lo
  que pasa si alguien escribe entre la línea base y el dump.
- **Clasificación:** hipótesis abierta. El ensayo que la resolvería (E-1,
  §5) **no está autorizado** y no es condición para entregar el TP8.

### H3 — U3: costo de escritura del índice por `lower(mail)` (aceptado como costo observado)

- **Fragmento:** `unidades/unidad-3/sql/indices.sql`, líneas 31–33:
  `CREATE INDEX idx_usuario_mail_lower ON usuario (lower(mail)) WHERE eliminado = FALSE;`
- **Hipótesis:** el índice acelera la búsqueda por mail, pero cada alta de
  usuario paga su mantenimiento.
- **Evidencia (histórica, misma versión):**
  `unidades/unidad-3/informes/evidencia_modelo_oficial.md`. `indices.sql` y la
  evidencia son del mismo commit, `da5f3e4`.
- **Condiciones del ensayo:**
  - PostgreSQL 17.11 sobre la base local descartable `foodstore_tp5_oficial`,
    el 2026-09-20 (línea 5 y §1).
  - Tiempos tomados de `Execution Time` de
    `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)`.
  - Tres corridas por caso: la 1 es de calentamiento y el valor informado es
    la media de las corridas 2 y 3 (§3, línea 98).
- **Operaciones medidas:**
  - **Lectura:** búsqueda con `lower(mail) = lower('usuario8452@foodstore.test')`
    (línea 196). Media 2+3: antes 10,8865 ms (11,006 y 10,767), después
    0,136 ms (líneas 207 y 227).
  - **Escritura:** `INSERT` de 1.000 filas en `usuario` dentro de
    `BEGIN … ROLLBACK` (§6, línea 288). Media 2+3: antes 7,6655 ms
    (8,053 y 7,278), después 14,7085 ms (15,081 y 14,336) (líneas 299–300).
- **Cálculo:** (14,7085 − 7,6655) / 7,6655 = 7,043 / 7,6655 = 0,918792, es
  decir +91,8792 % (línea 258).
- **Límites:** son dos corridas válidas por caso, sin análisis estadístico.
  El «después» de escritura se midió con los tres candidatos de `indices.sql`
  recreados; de ellos, el único sobre `usuario` es `idx_usuario_mail_lower`.
  La propia evidencia advierte que la variación incluye otros efectos del
  entorno y no es una estimación aislada (línea 302). Tampoco se midió la
  proporción real de altas frente a búsquedas.
- **Decisión: aceptado como costo observado en ese ensayo**, no como regla
  general ni como defecto. Sin cambio propuesto: la conveniencia depende de
  la carga.

### H4 — U4: deadlock del candidato desnormalizado (antecedente, no defecto vigente)

- **Alternativa evaluada:** el «candidato A» de U4, una desnormalización
  para la consulta de categorías más vendidas mantenida con triggers
  (`unidades/unidad-4/sql/tp_desnormalizacion_top_categorias.sql`), frente a
  la consulta sobre el modelo normalizado.
- **Hipótesis:** mantener la copia desnormalizada con triggers puede tomar
  bloqueos en orden inverso y producir deadlocks.
- **Versión con el fallo:** blob `9fb145be…`, del commit `7eea571`
  («test(u4): documentar fallo concurrente candidato A»). Su evidencia es
  `unidades/unidad-4/informes/evidencia_implementacion_candidato_a_modelo_canonico.md`,
  línea 257: escenario S4, «FAIL, 40P01 en B».
- **Versión de cierre:** blob `e23f76c0…`, del commit `ac668ef`
  («remediar concurrencia candidato A»), igual en `u6-cierre`. El diff entre
  las dos versiones cambia 242 líneas. Esta versión se midió en el commit
  `20fd6b6`
  (`unidades/unidad-4/informes/evidencia_read_after_decision_modelo_canonico.md`):
  la mediana mejora de 212,668 a 87,657 ms, pero los accesos a buffers suben
  de 6794 a 12091 (+77,97 %). La decisión es `REJECT / DO_NOT_ADOPT`
  (líneas 3–4).
- **Decisión: aceptado como antecedente ya tratado en U4.** El deadlock
  corresponde a la versión anterior. La alternativa fue rechazada y no forma
  parte del modelo canónico, así que no es un defecto vigente de la entrega.
  Sin cambio propuesto.

### H5 — U8: columnas sobrantes en el CSV (complemento: control previo comprobado)

- **Comportamiento original (sin registro conservado):** al prototipar el
  bloque C, el subagente que redactó los scripts informó que `.import` de
  `sqlite3` 3.54.1 solo advierte cuando una línea tiene columnas de más y
  sigue hasta el `COMMIT`. **No existe un registro de esa ejecución en el
  repositorio**: solo consta el informe del subagente. Ninguna evidencia
  muestra la versión anterior del coordinador aceptando ese CSV.
- **Corrección:** `movil/preparar_foodstore_movil.sh` (huella `d806311f…`)
  comprueba el encabezado y siete campos por línea antes de abrir la base.
- **Evidencia de la corrección:**
  `unidades/unidad-8/evidencias/bloque_c_sqlite_20261107_130343.txt`, paso 4
  (prueba e3). Un CSV con una columna sobrante, en una copia, se rechaza con
  código 1 y el mensaje «CSV fuera de contrato», antes de abrir la base;
  `snapshot_servidor` y `producto_cache` quedan idénticos antes y después.
  e3 prueba que el control añadido rechaza, no cómo se comportaba la
  versión anterior.
- **Decisión: complemento con control previo comprobado.** El informe del
  subagente no sustituye un registro que reproduzca el comportamiento
  original de `.import`. e3 no ejecutó esa importación en el motor: el
  registro indica que no se abrió la base para renovar. No se ejecutan
  nuevas pruebas para convertir H5 en otro hallazgo. El subconjunto de CSV
  admitido está documentado en `docs/kiro/design.md` §10.1.

### H6 — U8: el semáforo no reevalúa solicitudes evaluadas (descartado)

- **Hipótesis:** si el semáforo se vuelve a correr, podría cambiar el estado de
  solicitudes ya evaluadas, por ejemplo el CONFLICTO original de C2 después de
  aceptar el precio.
- **Fragmento:** `movil/semaforo.sql` calcula resultados solo para
  `cola_sync WHERE estado = 'PENDIENTE'` y actualiza con
  `AND cola_sync.estado = 'PENDIENTE'`; antes del `COMMIT` comprueba que las
  solicitudes evaluadas no cambiaron.
- **Comprobación en el motor:**
  `unidades/unidad-8/evidencias/bloque_d_entregable_continuacion_c6_20261107_195500.txt`,
  pasos 7–11 (C6-2):
  - `procesadas | 0` y los controles internos del semáforo en OK
    (solicitudes evaluadas, precios de los ítems y `producto_cache` sin
    cambios).
  - Salida de `estado_bloque_d.sql` idéntica byte a byte antes y después. Esa
    consulta muestra `cola_sync` completa, `pedido_borrador` sin `creado_en`,
    `item_borrador`, `producto_cache`, los ids del catálogo visible,
    `snapshot_servidor` resumida por fecha y conteo, y la integridad. No es
    una comparación de toda la base.
  - El CONFLICTO original de C2 sigue con el mismo motivo.
- **Decisión: descartado**, para el filtro `estado = 'PENDIENTE'` de la
  versión `2635767318a7…` de `semaforo.sql` y para el caso C6-2
  documentado.

## 5. Ensayos y lecturas pendientes

- **E-1** es opcional y **no está autorizado**. Resolvería H2-b, pero no es
  condición para entregar el TP8.
- **E-2 y E-3** se completaron por lectura el 2026-11-07 (inventario
  detallado). La lectura comunicada de ChatGPT/Mila de
  `tpi/sql/consultas_cobertura_tpi.sql` queda incorporada tras cotejar el
  blob local; ya no es opcional ni pendiente. La revisión humana continúa
  pendiente.

Registro original de la propuesta:

| Id | Para | Motor y copia | Comandos previstos | Resultado esperado | Evidencia | Permisos necesarios |
|---|---|---|---|---|---|---|
| E-1 | H2-b, concurrencia (opcional, no autorizado) | PostgreSQL de laboratorio U6 o una base nueva en un contenedor descartable; nunca la base conservada | Iniciar `backup_foodstore.sh` y, entre `LINEA_BASE_FIN` y `PG_DUMP_INICIO`, insertar una fila en una tabla controlada desde otra sesión; luego `restore_test.sh` | Que `restore_test.sh` informe una discrepancia con la línea base. Si no la informa, H2-b pasaría a defecto aceptado | Registro nuevo en `unidades/unidad-8/evidencias/` | Docker, crear contenedor o base descartable, escribir datos de prueba |
| E-2 | Cobertura U5 | Lectura, sin motor | Leer los 51 scripts de U5 con `git show u6-cierre:…` y anotar hallazgos por archivo | Tabla de U5 completa; cada hallazgo con decisión | Esta revisión, ampliada | Solo lectura (ya autorizada en general) |
| E-3 | Cobertura U1, U2 y `tpi/pruebas/` | Lectura; si aparece una hipótesis, una copia descartable | Igual que E-2 | Tabla completa | Esta revisión, ampliada | Lectura; para comprobar en el motor, los mismos permisos que E-1 |

## 6. Antecedentes de U8 ya corregidos (no son defectos presentes)

- `crear_borrador.sql` y `aceptar_precio.sql` usaban vistas temporales con
  parámetros (`parameters are not allowed in views`). Se detectó en el
  prototipo sobre copias, antes de la ejecución real, y se corrigió con tablas
  temporales.
- `ejecutar_bloque_d.sh` escribía los estados de C6-1 en la raíz del
  repositorio. Se detuvo en el paso 32
  (`evidencias/bloque_d_entregable_20261107_195358.txt`). Los archivos se
  trasladaron sin modificarlos, se corrigió el script y C6 se completó con
  `--continuar-c6`.
