# Bitácora de uso de IA — Unidad 7

**Registro de intervenciones de herramientas de IA durante la planificación.**

---

## Entrada 001 — Planificación inicial del repositorio (Kiro / Claude)

**Fecha de la sesión:** 2026-10-25

> **Fecha no comprobada (nota del 2026-11-06).** No hay evidencia de
> 2026-10-25. Según la fecha de creación del sistema de archivos, los siete
> documentos de esta entrada se crearon en este repositorio el 2026-11-06,
> entre las 10:55 y las 11:02 (-03:00), y `.git/` el mismo día a las 10:55:59.
> La fecha real de la sesión de planificación con Kiro no consta. Se conserva
> el valor original y no se lo reemplaza por una fecha supuesta.

**Herramienta:** Claude (implementación); Kiro (especificación y planificación).
Ambas autorizadas por el docente.

**Qué se solicitó:**
Crear el segundo repositorio `foodstore_nosql_movil` con la estructura inicial
para la Unidad 7, a partir de la consigna oficial (PDF adjunto) y los apuntes
teóricos de la Unidad 7, usando el repositorio relacional `foodstore_baseII`
en la etiqueta `u6-cierre` como origen de referencia de solo lectura.

**Documentos producidos:**
- `README.md` — presentación del repositorio, integrantes y estado
- `AGENTS.md` — reglas de trabajo
- `.gitignore` — exclusión de credenciales, datos locales y respaldos
- `unidades/unidad-7/specs/requirements.md` — requisitos derivados de las
  siete consignas del TP
- `unidades/unidad-7/specs/design.md` — modelo documental propuesto,
  tabla de conversión de campos, reglas de integridad, estructura del
  documento y decisiones pendientes
- `unidades/unidad-7/specs/tasks.md` — siete tareas ordenadas para la
  implementación
- `unidades/unidad-7/docs/bitacora_ia.md` — este archivo

**Decisiones que siguen propuestas (no aprobadas ni ejecutadas):**
- Base `foodstore_u7` y colección `pedidos` en MongoDB.
- Un documento por pedido con cliente y líneas embebidas.
- Uso de `Decimal128` para importes.
- Política de migración de bajas lógicas (incluir con `eliminado: true`).
- Las dos reglas de integridad RI-01 y RI-02 y sus consultas de verificación.
- El entorno de laboratorio (contenedor MongoDB).

**Qué no se ejecutó:**
- Ningún script SQL ni JavaScript.
- Ninguna conexión a PostgreSQL ni a MongoDB.
- Ningún contenedor creado, iniciado ni detenido.
- Ningún dato extraído ni migrado.
- Ningún resultado observado.

**Validación humana pendiente:**
El equipo debe revisar los documentos producidos y aprobar o corregir el
modelo antes de continuar con las tareas T2–T7 de `tasks.md`.

---

## Entrada 002 — Revisión de documentos e inventario del origen (Claude)

**Fecha de la sesión:** 2026-11-06

**Herramienta:** Claude (el Gentleman, en Pi).

**Qué se solicitó:** leer los documentos de Kiro, contrastarlos con la consigna
y con el origen de `u6-cierre`, inventariar el entorno sin instalar nada y leer
el origen PostgreSQL en una transacción `REPEATABLE READ, READ ONLY`.

**Qué se hizo:**
- Lectura de los siete documentos, de la consigna y de `schema.sql`,
  `datos_iniciales.sql`, `tpi/sql/objetos_programables.sql` y la guía U6,
  mediante `git show u6-cierre:<ruta>`.
- Inventario: Bash 5.3.9, Docker 29.9.3, `postgres:17` local; sin MongoDB.
- Identidad de `foodstore-u6-evaluacion` comprobada con `docker inspect`:
  coincide con el laboratorio U6, pero estaba **detenido**.
- Informe [inventario_origen_entorno.md](inventario_origen_entorno.md), con las
  consultas de lectura preparadas, ocho observaciones al diseño (O1–O8) y una
  propuesta de subconjunto y filtros condicionada a la lectura.
- Correcciones puntuales: la frase sobre IDs «desconocidos hasta ejecutar el
  seed» pasa a «IDs a comprobar mediante lectura del origen existente»;
  estados de T1, T2 y §8 de `design.md`; enlaces al informe; referencia del
  origen en T2.

**Qué no se ejecutó:**
- Ninguna consulta de datos sobre PostgreSQL: el contenedor estaba detenido y no
  se autorizó iniciarlo.
- Ninguna conexión a MongoDB, extracción ni migración.
- Ningún contenedor creado, iniciado ni detenido; ninguna imagen descargada.
- Ningún script creado; ningún cambio en Git ni en el repositorio relacional.

**Validación humana pendiente:** el modelo sigue sin aprobar. El equipo debe
decidir si inicia el contenedor para la lectura y si adopta las observaciones
O1–O3 del informe.

---

## Entrada 003 — Lectura del origen, decisiones de modelo e imagen MongoDB (Claude)

**Fecha de la sesión:** 2026-11-06

**Herramienta:** Claude (el Gentleman, en Pi).

**Qué se solicitó:** iniciar el contenedor de origen, leer PostgreSQL en modo de
solo lectura, documentar las decisiones de modelo del equipo, descargar
`mongo:8.0` y hacer el primer commit local de la documentación.

**Qué se hizo:**
- Identidad de `foodstore-u6-evaluacion` confirmada (ID, imagen, volumen, red
  `none` sin puertos publicados, montaje de autenticación). El contenedor se
  inició con `docker start`, autorizado en este encargo, y queda en ejecución.
- Lectura en `REPEATABLE READ, READ ONLY` con `ROLLBACK`: conteos 2, 3, 3, 5
  y 7 sin bajas lógicas; pedidos 1–5, todos `TERMINADO`; controles RI-01 y
  RI-02 sin filas inconsistentes.
- Lote 1–5, estado `TERMINADO`, producto 1 (Muzzarella) y umbral 3000.00,
  elegidos con los datos leídos.
- `design.md` y `requirements.md`: `_id` = `pedido.id` como `Long`, tipos
  explícitos, bajas lógicas y filtros, RI-01 y RI-02, y detención ante IDs
  existentes. Se corrigió O8 sobre los tipos numéricos de `mongosh`.
- `docker pull mongo:8.0`: digest
  `sha256:b9924c330a8bbc5800fe9c69f04a84e221eca7b28fd049a0354147d9908fa142`,
  `linux/amd64`.

**Origen de las decisiones:** adoptadas por el equipo mediante este encargo.
No son aprobaciones docentes.

**Qué no se ejecutó:**
- Ningún seed, función de negocio, DML, DDL ni mantenimiento en PostgreSQL.
- Ningún contenedor, volumen, red, base ni colección MongoDB; el servidor no
  se inició.
- Ningún script de migración ni consulta entregable; ninguna extracción de
  nombres ni migración.
- Ningún cambio en el repositorio U6, `odd/` u otros contenedores.

---

## Entrada 004 — Implementación de la migración (Claude)

**Fecha de la sesión:** 2026-11-06

**Herramienta:** Claude (el Gentleman, en Pi).

**Qué se solicitó:** implementar y ejecutar la extracción, la carga en MongoDB,
las validaciones, las consultas en ambos motores y la prueba de repetición.
Todo en la rama `feat/u7-migracion`, sin commits.

**Qué se hizo:**
- Rama `feat/u7-migracion` creada desde `a14066f`.
- Laboratorio MongoDB:
  - Credenciales nuevas en un directorio privado fuera del repositorio; no se
    mostraron ni se reutilizaron las de U6.
  - Volumen `foodstore_u7_mongo_data` y contenedor `foodstore-u7-mongo` creados
    desde `mongo@sha256:b9924c33…fa142`, con red `none` y sin puertos.
  - `mongod` 8.0.34 terminó con código 1: su comprobación de kernel rechaza
    `7.0.0-42-generic` aunque el kernel es el upstream 7.0.14
    (SERVER-121912, SERVER-136848).
- Scripts escritos y revisados:
  - `extraccion_pedidos.sql` y `consultas_postgresql.sql`: ejecutados con
    código 0.
  - `migracion_pedidos.js`, `validaciones_mongodb.js` y `consultas_mongodb.js`:
    solo comprobación de sintaxis con `node --check`.
- Extracción real en `datos/pedidos_origen.json`, con SHA-256 `930562ab…bec7a`.
- Resultados de PostgreSQL: C4b = 1,2,3,4,5 y C4c = 1,3,5. La reextracción de
  control confirmó que el origen no cambió.
- Guía `docs/laboratorio_migracion.md` y extracto
  `evidencias/ejecucion_20261106.txt`.

**Qué no se ejecutó:**
- Creación de usuarios MongoDB, versiones efectivas de `mongod` y `mongosh`, y
  rechazo sin autenticación.
- Carga, validaciones, C4a–C4d en MongoDB y prueba de repetición.
- Ninguna escritura en PostgreSQL; ningún cambio en U6, `odd/` ni en otros
  contenedores.
- Ningún staging ni commit.

**Decisión pendiente del equipo:** cómo desbloquear MongoDB (laboratorio §8).
No se cambió de versión. También quedan pendientes el contraste de la IA, la
conclusión y el PDF.

---

## Entrada 005 — MongoDB 9.0.4 y migración completa (Claude)

**Fecha de la sesión:** 2026-11-06

**Herramienta:** Claude (el Gentleman, en Pi).

**Qué se solicitó:** reemplazar el entorno bloqueado por `mongo:9.0.4`, elegida
por el equipo, y completar la carga, las validaciones, las consultas y la
repetición. Sin commits.

**Qué se hizo:**
- **Comprobaciones previas:** SHA-256 del JSON igual al informado; origen igual
  a la extracción (excluido `momento_utc`); recursos de 8.0 conservados sin
  iniciar.
- **Imagen:** `mongo:9.0.4` descargada, digest `sha256:452bdaf2…a058`, `linux/amd64`.
- **Contenedor:** volumen `foodstore_u7_mongo9_data` y contenedor
  `foodstore-u7-mongo9` creados con red `none`, sin puertos, `tmpfs` y montajes
  de solo lectura.
- **Credenciales:** nuevas, en un directorio privado. Se usó
  `MONGO_INITDB_ROOT_PASSWORD_FILE`, con una ACL de lectura solo para el uid
  999 sobre ese archivo, porque el entrypoint lo lee después de `gosu`.
- **Versiones:** `mongod` 9.0.4 y `mongosh` 2.14.0.
- **Usuarios:** `u7_operador` creado con `readWrite` sobre `foodstore_u7`.
  Lectura autorizada (código 0) y rechazo sin autenticación (código 1), antes y
  después de la carga.
- **Ajuste mecánico:** el nombre del contenedor en el comentario de uso de los
  tres `.js`; la lógica no cambió.
- **Carga y validaciones:** carga con 5 documentos (código 0) y validaciones con
  13 comprobaciones OK. [Corrección: fueron 12; ver la entrada 008.]
- **Consultas:** C4a = 1–5, C4b = 1–5, C4c = 1, 3, 5 y C4d = 3, 4. C4b y C4c
  coinciden con PostgreSQL.
- **Repetición:** rechazada con código 3; misma huella de documentos.
- **Documentación:** guía reescrita para 9.0.4, con el antecedente de 8.0;
  extracto `evidencias/ejecucion_20261106_mongo9.txt`.

**Qué no se hizo:**
- Ninguna escritura en PostgreSQL ni en U6.
- Ningún borrado de recursos o evidencias.
- Ningún staging ni commit.
- No se probó un fallo parcial de `insertMany`.

**Pendiente:** consulta a IA y contraste de dos afirmaciones, conclusión, informe
y publicación. Ninguna aprobación docente.

---

## Entrada 006 — Consolidación, contraste de IA y conclusión (Claude)

**Fecha de la sesión:** 2026-11-06

**Herramienta:** Claude Opus 5.5 (`claude-opus-5-5`) como asistente «el
Gentleman» en Pi.

**Qué se solicitó:** revisar código y evidencias sin conectarse a los motores,
completar las consignas 6 y 7 y guardar un commit local.

**Qué se hizo:**
- **Revisión acotada:** las huellas de los scripts y del JSON coinciden con las
  de la ejecución con 9.0.4, y las salidas registradas respaldan los
  resultados citados. Se agregaron a la guía los comandos de espera que
  funcionaron y la advertencia sobre el bucle fallido.
- **Consigna 6:** prompt registrado y respuesta generada por este asistente en
  la misma sesión, antes de leer las fuentes. Ver
  [contraste_ia.md](contraste_ia.md).
- **Consigna 7:** contraste de dos afirmaciones con documentación oficial de
  MongoDB y PostgreSQL 17 y con el código U6. A1 necesita matiz; A2 está
  respaldada.
- **Conclusión:** propuesta de 183 palabras en
  [conclusion_u7.md](conclusion_u7.md).

**Límites:** la respuesta de IA no es independiente del laboratorio, porque el
mismo asistente tenía el contexto del proyecto. Ningún integrante revisó todavía
el contraste ni la conclusión.

**No se ejecutó:** SQL, `mongosh`, cargas ni pruebas nuevas; no se tocaron
contenedores, permisos ni U6.

**Pendiente:** revisión del equipo, informe PDF y publicación.

---

## Entrada 007 — Precisiones del contraste e informe borrador (Claude)

**Fecha de la sesión:** 2026-11-06

**Herramienta:** Claude Opus 5.5 (`claude-opus-5-5`) como asistente «el
Gentleman» en Pi.

**Qué se solicitó:** completar dos precisiones del contraste, ajustar la
conclusión y generar el informe del TP7 a partir de lo ya conservado.

**Qué se hizo:**
- **Contraste, §6:** ampliación con F6 (*Production Considerations*, sección
  *Availability*), que menciona de forma explícita que los despliegues
  standalone no admiten transacciones. A1 pasa de «necesita matiz» a
  «respaldada documentalmente; no ensayada». Se mantienen el matiz sobre la
  permanencia de lo ya insertado y la aclaración de que no se probaron un fallo
  parcial ni una transacción.
- **A2:** se precisó la diferencia entre las reglas de una fila y el total
  agregado, y se atribuyeron los disparadores al TPI conservado en
  `u6-cierre`, no al mantenimiento U6. El veredicto se mantiene: respaldada.
- **Respuesta de IA:** no se modificó.
- **Conclusión:** ajustada a 186 palabras (`wc -w`). Por error de entrega, no se
  recibió el texto ajustado que debía acompañar el encargo, así que se usó una
  redacción equivalente.
- **Informe:** `informe_u7.html` e `informe_u7.pdf` (4 páginas A4, Chrome
  headless). Las cuatro páginas se renderizaron como imagen y se revisaron. Se
  corrigieron tres defectos de maquetación detectados en esa revisión: un
  título huérfano, una tabla desbordada y código partido. Los fragmentos de
  código se verificaron como copia literal de los archivos, y la conclusión es
  idéntica a `conclusion_u7.md`.

**No se ejecutó:** SQL, `mongosh` ni scripts del proyecto. No se tocaron
contenedores, permisos ni U6, y no se hizo staging ni commit.

**Pendiente:** revisión del equipo del contraste, la conclusión y el informe;
publicación. Ninguna aprobación docente.

---

## Entrada 008 — Correcciones acotadas de la revisión del ZIP (Claude)

**Fecha de la sesión:** 2026-11-06

**Herramienta:** Claude Opus 5.5 (`claude-opus-5-5`) como asistente «el
Gentleman» en Pi.

**Qué se solicitó:** corregir puntos concretos de la revisión del ZIP sin
rehacer la implementación. El archivo `Revision_TP7_FoodStore_2026-11-06.md` no
estaba disponible en el disco ni dentro del ZIP. Se trabajó con los puntos
detallados en el encargo.

**Qué se corrigió:**
- **Conteo de validaciones:** las salidas originales `11_validaciones_1.txt` y
  `16_validaciones_2.txt` tienen 12 líneas OK, 0 FALLO y 2 líneas `info`, y el
  script hace 12 comprobaciones en el recorrido normal. El «13» era un error de
  conteo al resumir. Se corrigió en el informe, la guía y `tasks.md`, con nota
  trazable en el extracto `ejecucion_20261106_mongo9.txt` y en la entrada 005.
  El mensaje del commit `235cdbd` también dice «13 validaciones OK»; no se
  cambia porque requeriría `amend`.
- **Guía:**
  - Prerrequisitos y referencia estable a la reproducción U6 (etiqueta, commit
    y ruta de `EVALUACION.md`).
  - Guardas de recursos **antes** de generar credenciales.
  - Preparación nueva separada del laboratorio existente.
  - Comparación de los datos del lote separada de los metadatos del entorno.
  - Control de códigos de salida con `paso` y `huella`, incluido el rechazo
    esperado (código 3) de la repetición.
  - Las funciones se probaron con comandos inertes y la comparación, con copias
    en memoria del JSON; no se usaron las bases.
- **C4a y C4d:** el diseño y el informe decían que devuelven pedidos completos.
  Sus proyecciones son parciales (`_id`/`estado` y `_id`/`total`). Se corrigió
  la frase sin cambiar las consultas.
- **Estados y referencias:**
  - Cabecera de `design.md` y de la guía.
  - Nota de documento histórico en el inventario.
  - En el README, el enlace relativo al repositorio U6 pasa a una cita por
    etiqueta y commit.
  - Exclusión de `.git/` y `.atl/` del ZIP documentada.
  - En `tasks.md`, 186 palabras y el veredicto revisado de A1.
- **Fecha de la entrada 001:** no se pudo comprobar 2026-10-25. Se conservó el
  valor y se agregó la evidencia disponible (creación de los archivos el
  2026-11-06).
- **Informe:** HTML y PDF regenerados y revisados página por página.

**No se modificó:** los cinco scripts, el JSON, las salidas originales,
contenedores, permisos ni credenciales. No se hizo staging ni commit.

**Pendiente:** revisión del equipo y publicación. Ninguna aprobación docente.

---

## Entrada 009 — Cierre de observaciones de la revisión (Claude)

**Fecha de la sesión:** 2026-11-06

**Herramienta:** Claude Opus 5.5 (`claude-opus-5-5`) como asistente «el
Gentleman» en Pi.

**Qué se hizo:**
- **Revisión leída:** `docs/Revision_TP7_FoodStore_2026-11-06.md`, ya
  disponible, comparada con las correcciones de la entrada 008.
  - R1, R3, R4 y R6 y los ajustes menores ya estaban resueltos.
  - R2 y R5 estaban resueltos en parte.
- **Ajustes adicionales:**
  - **Guía §4.2:** creación exclusiva de credenciales con `set -C` y
    `mkdir` sin `-p`; ningún archivo existente se reemplaza. Se probó con
    archivos inertes en un directorio temporal.
  - **Guía §4.1:** enlace al repositorio relacional y a su `EVALUACION.md` en
    la etiqueta `u6-cierre`. Se comprobó en solo lectura que la etiqueta
    existe en el remoto y apunta a `8f7877c8`. Se agregó la distinción entre
    laboratorio existente e instancia descartable, y entre lote registrado y
    extracción nueva.
  - **README:** U8 «prevista, no iniciada»; enlace estable a U6. El documento
    de revisión se declara material de trabajo, fuera de la entrega.
- **Copia anterior del informe:** `docs/informe_u7.pdf` ya no existía al
  empezar esta sesión y no se encontró bajo `~/Documentos/utn`, así que no se
  trasladó nada. Esa versión anterior se conserva dentro de
  `foodstore_nosql_movil.zip`.
- **PDF:** no se regeneró, porque estos ajustes no afectan su contenido.

**No se modificó:** los cinco scripts, el JSON, el commit histórico, las
salidas originales, Docker, las credenciales ni los permisos. No se hizo staging
ni commit.

**Pendiente:** decisión del equipo sobre la conclusión y el contraste,
versionado y publicación. Ninguna aprobación docente.

---

## Entrada 010 — Repositorio académico e informe referenciado (Claude)

**Fecha de la sesión:** 2026-11-06

**Herramienta:** Claude Opus 5.5 (`claude-opus-5-5`) como asistente «el
Gentleman» en Pi.

**Qué se solicitó:** preparar el repositorio como entrega académica,
referenciar el informe y publicar la versión `u7-cierre` en
`github.com/ismaelsuarez/foodstore_nosql_movil`.

**Qué se hizo antes del commit:**
- README raíz como portada académica. Se crearon `unidades/unidad-7/README.md`
  (matriz de las siete consignas), `EVALUACION.md` (revisión y reproducción,
  sin duplicar comandos) y `evidencias/README.md` (índice y huellas reales).
- Ruta de lectura y criterio de revisión independiente en `AGENTS.md`.
- En `.gitignore`, reglas para `.atl/`, ZIP, archivos de contraseñas y la
  revisión interna, que no se versiona.
- Informe con enlaces absolutos a la etiqueta `u7-cierre`, a U6 y a las
  fuentes oficiales (sección y fecha). Se regeneró en 4 páginas A4 y cada
  página se revisó. No incluye el hash del commit que lo contiene.

**Estado humano:** no consta una revisión del equipo ni una aprobación docente.
La publicación no equivale a aprobación.

**No se modificó:** los cinco scripts, el JSON, las salidas originales, U6,
Docker, las credenciales ni los permisos.

---

*Las entradas siguientes se agregarán cuando se ejecuten las tareas del TP.*
