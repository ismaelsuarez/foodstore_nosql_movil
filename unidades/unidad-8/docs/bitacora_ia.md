# Bitácora de uso de IA — Unidad 8

Consigna 4.b del TP8. **Fecha de redacción:** 2026-11-07, en forma
retrospectiva, a partir de los archivos, las huellas y las evidencias del
repositorio. Cada entrada separa la fecha de trabajo de la de redacción.

En las entradas retrospectivas 1–7 no se transcriben prompts literales: los
encargos del equipo no están guardados en el repositorio. Se resume lo que
pidió cada encargo, tal como quedó reflejado en los documentos. La entrada 8
conserva la cita de autorización aportada para este cierre.

**Estado actual (2026-11-07):** Ismael autorizó versionar y publicar el TP8
en `main` de `ismaelsuarez/foodstore_nosql_movil`, con etiqueta `tp8`.
Está en preparación; la entrada 8 actualiza el estado sin reescribir los
relatos históricos 1–7. No consta aquí el resultado del commit/push.

**Herramientas que constan:**
- **Kiro:** especificación inicial de U8. Según el equipo, los tres archivos
  `docs/kiro/*.md` se elaboraron en Kiro. No consta qué modelo interno usa.
- **Claude:** implementación de los bloques B–D, correcciones de las
  especificaciones y documentación de E, en sesiones con el arnés el
  Gentleman.
- **Subagentes coordinados en sesiones de Claude** (`gentle-ai-worker` y
  `gentle-ai-explore`): redacción de scripts, verificaciones delegadas y
  mapeo de solo lectura. Cada uso se indica en su entrada; esos nombres no
  acreditan el modelo ni el proveedor de cada subagente.
- **writer acotado de Pi (OpenAI):** complemento puntual de E documentado
  en la entrada 6 y en
  `evidencias/bloque_e_complemento_20261107_212101.txt:1–5`. No se atribuye
  a la sesión principal de Claude ni a revisión humana; no consta el modelo.
- **ChatGPT (al que el equipo llama Mila):** coordinación y revisión fuera
  del repositorio (ver la entrada transversal). No dejó registros propios;
  su participación se documenta a partir de la información que aportó el
  equipo y, en la entrada 6, de la lectura comunicada en esta conversación.
- **Equipo humano:** decisiones, autorizaciones por bloque y revisiones que
  comunicó en sus encargos. La aprobación del informe comunicada por Ismael
  se registra en la entrada 7; no implica aprobación final de todo TP8.

Según informa el equipo, el docente autorizó sustituir OpenCode por Claude.
No se infiere de esa información autorización docente adicional para Pi
ni para otras herramientas o modalidades de defensa. Ninguna ejecución de
un agente equivale a una revisión humana. Las revisiones del equipo constan
solo como lo que el propio equipo comunicó en sus encargos. La DUIA sigue
siendo un borrador pendiente de contraste con el formato oficial y de
revisión humana, sin firmas ni aprobación final.

---

## Entrada transversal — ChatGPT (Mila): coordinación y revisión externa

- **Procedencia:** información de continuidad que el equipo aportó en la
  sesión del 2026-11-07, al pedir la continuación del bloque E. Se registra
  como dato aportado por el equipo; el repositorio no tiene registros propios
  de esa herramienta. Texto aportado: «ChatGPT, denominado Mila por el
  equipo, se utilizó fuera del repositorio para interpretar la consigna,
  coordinar el trabajo por bloques, preparar encargos para Kiro y Claude y
  revisar especificaciones, código y evidencias compartidas en el chat.
  Esta participación se documenta retrospectivamente a partir de la
  conversación aportada por el equipo. No equivale a una ejecución de
  comandos sobre la computadora local ni sustituye la revisión humana.»
- **Fecha de trabajo:** durante el TP8, sin fechas exactas registradas.
- **Qué hizo:** interpretar la consigna, dividir el trabajo en bloques con
  permisos explícitos, preparar los encargos que recibieron Kiro y Claude, y
  revisar las especificaciones, el código y las evidencias que el equipo
  compartió en el chat.
- **Qué no hizo en ese entorno de chat y conector GitHub:** ChatGPT/Mila no
  operó sobre la computadora ni los motores locales del equipo. Esto no
  describe la intervención diferenciada del writer de Pi de la entrada 6.
  Su revisión no reemplaza la revisión humana.
- **Relación con las entradas siguientes:** las correcciones que los
  encargos describen como «problema comprobado» o como revisión previa
  (entradas 1 y 2) llegaron por esa vía o por el equipo. El repositorio no
  permite separar qué parte aportó cada uno; no se atribuye a ninguno en
  particular.
- **Evidencia:** no hay en el repositorio. No se transcriben prompts, no hay
  enlaces a la conversación y no consta el modelo de ChatGPT utilizado.

## Entrada 1 — Especificación en Kiro y correcciones (bloque A)

- **Fecha de trabajo:** los archivos `docs/kiro/` existían el 2026-11-06 (la
  fecha de la sesión de Kiro no consta). Correcciones del 2026-11-07.
- **Qué se pidió:** cuatro requisitos EARS ligados a los casos C1–C7, más
  `design.md` y `tasks.md`. Después, a Claude, corregir solo las
  inconsistencias que enumeró el equipo.
- **Qué se aceptó:** las cuatro tablas STRICT, el índice
  `ux_cola_una_pendiente`, `::BIGINT` para los centavos y la prioridad del
  rechazo sobre el conflicto.
- **Qué se corrigió:**
  - En C7, el `BEGIN` pasa antes del encabezado del borrador.
  - El error esperado se reconoce por el diagnóstico real del cliente.
  - Se agregó el criterio CA-03g, de baja lógica.
  - Se unificó la regla de `motivo`.
  - La renovación de la instantánea pasa a ser transaccional, y la
    invariancia del servidor se comprueba en cada simulación.
- **Qué se descartó y por qué:**
  - «Ausencia de salida» como prueba de error: no distingue un error
    esperado de cualquier otro fallo.
  - `INSERT OR REPLACE` para el catálogo: borra y reinserta la fila. Se
    reemplazó por un UPSERT.
  - La afirmación de que `REPLACE` viola necesariamente la clave foránea:
    el equipo la observó y se quitó porque no estaba demostrada.
- **Atribución:** la versión original de la cabecera atribuía la redacción
  a Claude. El equipo indicó que la especificación se elaboró en Kiro, y la
  cabecera se ajustó a esa indicación.
- **Evidencia:** `docs/kiro/requirements.md`, `design.md` y `tasks.md`.

## Entrada 2 — Bloque B: esquema y pruebas SQLite

- **Fecha de trabajo:** 2026-11-07 (10:45 y 12:18, -03:00).
- **Qué se pidió:** a Claude, `schema_sqlite.sql`, `pruebas_sqlite.sql` y un
  auxiliar Bash, ejecutados sobre una base descartable.
- **Qué se aceptó:** las 33 comprobaciones SQL. Se ejecutaron sobre una base
  descartable y dieron OK en el primer intento.
- **Qué se corrigió:** el equipo detectó que el auxiliar decía «Registro
  guardado» aunque `tee` hubiera fallado. Se corrigió con validación previa,
  captura temporal y publicación con `ln` sin sobrescribir. Antes se observó
  el fallo con un `tee` simulado.
- **Qué intervino:** Claude. Un subagente `gentle-ai-worker` ejecutó los
  casos a–e de verificación del registro.
- **Evidencia:** `evidencias/bloque_b_20261107_104530.txt`,
  `bloque_b_control_negativo_20261107_104542.txt`,
  `bloque_b_20261107_121805.txt` y
  `bloque_b_verificacion_registro_20261107_121806.txt`.

## Entrada 3 — Bloque C: laboratorio PostgreSQL e instantánea

- **Fecha de trabajo:** 2026-11-07 (12:51 a 13:06).
- **Qué se pidió:** un laboratorio PostgreSQL nuevo, la vista de
  instantánea, la exportación CSV, la renovación transaccional y la carga
  del catálogo.
- **Qué intervino:** un subagente `gentle-ai-worker` redactó los scripts. Se
  negó a ejecutar operaciones fuera de sus rutas permitidas, así que la
  sesión principal de Claude leyó los scripts y los ejecutó.
- **Qué se aceptó:** la exportación con conteo y datos de la misma
  transacción y la renovación de instantánea y catálogo en un único
  `COMMIT`.
- **Qué se corrigió:** el subagente informó que `.import` acepta columnas
  sobrantes con solo una advertencia; no hay registro disponible que
  reproduzca ese comportamiento original. La sesión principal agregó una
  comprobación estructural previa (H5, complemento). e3 demuestra el
  rechazo del CSV por ese control sin abrir la base para renovar, no una
  ejecución de esa importación en el motor.
- **Qué se descartó:** nada adicional. Dos listados finales del esquema
  fallaron por un error de comillas del comando; se repitieron y se
  registraron como tales.
- **Evidencia:** `evidencias/bloque_c_postgresql_20261107_125121.txt`,
  `bloque_c_sqlite_20261107_130343.txt`,
  `bloque_c_cierre_20261107_130545.txt` y
  `bloque_c_cierre_complemento_20261107_130601.txt`.

## Entrada 4 — Bloque D: semáforo y casos C2–C6

- **Fecha de trabajo:** 2026-11-07 (19:53 a 19:56).
- **Qué se pidió:** el semáforo, la aceptación de precio, los casos C2–C6 y
  los controles sobre copias.
- **Qué intervino:** Claude, en la sesión principal, redactó y ejecutó.
- **Qué se corrigió:**
  - El prototipo sobre copias falló con `parameters are not allowed in
    views`. Se cambiaron las vistas temporales por tablas temporales.
  - La secuencia real se detuvo en el paso 32: el coordinador escribía en la
    raíz del repositorio. Se corrigió y C6 se completó con
    `--continuar-c6`.
- **Qué se descartó:** reinicializar la base o repetir la secuencia completa
  para ocultar el fallo. Se conservó el intento detenido como evidencia.
- **Evidencia:** `evidencias/bloque_d_entregable_20261107_195358.txt`,
  `bloque_d_entregable_continuacion_c6_20261107_195500.txt`,
  `bloque_d_controles_copias_20261107_195510.txt` y
  `bloque_d_cierre_20261107_195631.txt`.

## Entrada 5 — Bloque E: integración y revisión de scripts

- **Fecha de trabajo:** 2026-11-07 (desde las 20:34).
- **Qué se pidió:** documentación de integración y mantenimiento, y la
  revisión de los scripts de la cursada.
- **Qué intervino:** Claude. Un subagente `gentle-ai-explore` hizo un mapeo
  de solo lectura de U1–U6; la sesión principal comprobó con `git show` los
  fragmentos citados.
- **Qué se aceptó y qué se descartó:** dos hipótesis se descartaron con
  fundamento (H1 y H6 en `docs/revision_scripts_ia.md`). Al comprobar las
  huellas, se encontró que el comentario de `backup_foodstore.sh` está
  desactualizado (H2).
- **Pendientes al redactar esta entrada:** la revisión archivo por archivo
  de U5, U1, U2 y `tpi/pruebas/` (cubierta después por el inventario; ver
  entrada 6). E-1 es opcional y continúa no autorizado.
- **Evidencia:** `evidencias/bloque_e_lectura_base_final_20261107_203411.txt`
  y `docs/revision_scripts_ia.md`.


## Entrada 6 — Complemento puntual de cobertura y evidencia de E

- **Fecha de trabajo y redacción:** 2026-11-07T21:24:26.465850-03:00 (fecha real).
- **Qué se pidió:** registrar la lectura que faltaba, precisar la selección
  para 3.c, comprobar huellas históricas con el código correcto y conservar
  las capturas C6; sin repetir revisiones o pruebas B/C/D.
- **Qué intervino:** writer acotado de Pi (OpenAI), bajo coordinación de la
  sesión principal. La lectura completa de
  `tpi/sql/consultas_cobertura_tpi.sql` es de **ChatGPT/Mila**, vía conector
  GitHub fijando el commit U6, comunicada en esta conversación. No se
  atribuye a la sesión principal de Claude ni a revisión humana. El
  encabezado de `evidencias/bloque_e_complemento_20261107_212101.txt:3–4`
  identifica al writer y limita su ejecución a archivos, sin motores ni
  scripts de la cursada; no permite inferir un modelo ni el proveedor de
  otros subagentes.
- **Qué se incorporó (observaciones estáticas y cobertura):** blob local de `u6-cierre`
  `1c5bb99ef73492e9cff364bcdfdde91c8906b095` cotejado; dos consultas de
  lectura, sin inconsistencia estática encontrada respecto de su propósito.
  No se ejecutaron en PostgreSQL ni se comprobaron sus resultados o todos
  sus enlaces relativos. Inventario: **115 lecturas completas + 5
  correspondencias históricas U7 = 120**, pendientes de lectura 0. Los 84
  scripts son solo `tpi/pruebas/` + `unidades/` U1–U6: no incluyen raíz/TPI,
  U7 ni U8. La igualdad de huellas acredita identidad de versión, no por sí
  sola revisión de contenido; U7 no se cuenta como lectura nueva.
- **Qué se propuso:** H1, H3 y H6 como principales de 3.c, tras contrastar
  sus referencias. H1 distingue versión ensayada/cierre y diff; H3 conserva
  condiciones, tiempos y cálculo; H6 limita el descarte al caso y versión
  documentados. Al registrar esa propuesta no estaban aprobados por el
  equipo humano; la aprobación para el informe se registra en la entrada 7.
- **Qué se limitó:** H5 es complemento. No hay registro que reproduzca el
  comportamiento original de `.import`; e3 acredita el rechazo por el
  control previo sin abrir la base para renovar, no esa importación en el
  motor. E-1 sigue opcional y no autorizado.
- **Verificación observada sobre archivos, no ensayo de motores:** 48
  registros históricos de D comprobados,
  incluidas base final y copia inicial de C: todos coincidentes, stderr
  vacío y `sha256sum -c` con código 0 capturado inmediatamente. El primer
  intento de extracción falló por una aserción de conteo del writer; se
  conserva la explicación en el complemento. El registro anterior mostró
  el código de `wc`: no se modifica ni se reinterpreta retroactivamente.
- **Conservación:** 9 archivos regulares C6 copiados sin seguir enlaces ni
  mover originales, con huellas origen/destino iguales. Solo dos tienen
  huella histórica; en los otros siete solo se acredita la copia actual.
  Destino nuevo:
  `~/.local/share/foodstore_u8_resguardos/20261107_205605/complemento_20261107_212146/`.
  Allí se conservan también copias nuevas de los cinco documentos y de la
  evidencia al finalizar, sin sobrescribir resguardos anteriores.
- **Pendientes de E al registrar esta entrada (estado del informe actualizado
  en la entrada 7):** revisión humana, DUIA, informe, ensayo de defensa y
  preparación de la entrega elegida. La consigna admite **ZIP o repositorio
  con etiqueta `tp8`**; modalidad y operaciones Git pendientes de decisión
  del equipo. E no está completo ni aprobado.
- **Evidencia:** `evidencias/bloque_e_complemento_20261107_212101.txt`.

## Entrada 7 — Generación del informe y aprobación comunicada por el equipo

- **Fecha real de registro:** 2026-11-07. La fecha y hora de aprobación no
  constan; no se atribuyen firmas ni reuniones.
- **Generación anterior:** `docs/informe.html` y `docs/informe.pdf` se
  produjeron con asistencia de IA como borrador de seis páginas. La
  generación, conversión con Chrome 157, revisión visual del agente y
  huellas están registradas en
  `evidencias/bloque_e_informe_20261107_220745.txt`; esa evidencia histórica
  se conserva intacta y no acredita aprobación humana en aquel momento.
- **Procedencia de la aprobación:** Ismael comunicó en nombre del equipo,
  en la conversación de coordinación: «Bien el equipo lo aprueba».
  Se registra como comunicación aportada por el equipo, no como firma ni
  aprobación docente.
- **Alcance aceptado:** el informe presentado, incluido el desarrollo de
  H1, H3 y H6 y su selección para presentación en el informe.
- **Actualización actual:** writer acotado de Pi (OpenAI), bajo coordinación
  de la sesión principal, conservó los originales HTML/PDF en un directorio
  nuevo de resguardo, actualizó únicamente las menciones autorizadas de
  estado y regeneró el PDF con el mismo comando y diseño. Se mantuvieron
  seis páginas, con revisión visual de todas y contraste de texto extraído.
  No se ejecutaron motores, clientes de bases ni scripts de la cursada.
- **Qué no se aceptó como consecuencia de esta aprobación:** cierre de todo
  TP8 o E, revisión humana individual de los 120 scripts, DUIA definitiva,
  ensayo realizado, aprobación docente ni autorización para publicar.
  Las propuestas de mantenimiento siguen como propuestas; la elección de
  qué mostrar en vivo y el ensayo siguen pendientes.
- **Pendientes:** contraste de la DUIA con el formato oficial y revisión
  humana de esa declaración; ensayo de defensa y preparación de la entrega
  elegida. No se publica ni se realizan operaciones Git modificadoras.
- **Evidencia de esta actualización:**
  `evidencias/bloque_e_informe_aprobado_20261107_230321.txt`.

## Entrada 8 — Autorización y ajustes documentales de cierre TP8

- **Fecha real de registro:** 2026-11-07, comprobada con `date`.
- **Autorización de Ismael:** «bien terminemos el trabajo y realicemos el commit + push al repo
  remoto, en main por favor».
  El encargo de cierre indica el repositorio
  `ismaelsuarez/foodstore_nosql_movil`, la rama `main` y la etiqueta `tp8`.
  La modalidad elegida es versionar y publicar en GitHub; ya no está
  pendiente de autorización, pero está en preparación.
- **Aprobación para presentación:** el informe y H1/H3/H6 fueron aprobados
  por el equipo, según lo comunicado por Ismael y registrado en la entrada 7.
  Esa aprobación no cierra todo TP8 ni el bloque E en sentido académico.
- **Qué se pidió y qué se ajustó:** ajustes documentales mínimos en el
  README raíz, el README de U8, `docs/kiro/tasks.md`, esta bitácora y
  `docs/DUIA.md`: enlaces de U8, estado de autorización y versión actual de
  la DUIA. Intervino el writer acotado de Pi (OpenAI), bajo coordinación de
  la sesión principal. Se conservaron las entradas 1–7 y las herramientas
  declaradas; no se modificaron informes, scripts, bases ni evidencias, ni
  se ejecutaron motores o scripts de la cursada.
- **Límite del registro:** el resultado del commit/push y la comprobación de
  publicación se informan después; no constan en este archivo. Este paso
  documental no ejecuta operaciones Git de escritura.
- **Pendientes que siguen abiertos:** no consta ensayo humano de defensa
  ni aprobación docente; siguen pendientes la elección de defensa y la
  revisión humana individual de los scripts. La DUIA continúa como borrador
  sin firmas, pendiente de revisión humana y contraste formal con la
  plantilla oficial no vista; ese contraste no bloquea el versionado.
  No consta entrega en el campus: publicar en GitHub no la reemplaza.
