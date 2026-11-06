# Bitácora de uso de IA — Unidad 7

**Registro de intervenciones de herramientas de IA durante la planificación.**

---

## Entrada 001 — Planificación inicial del repositorio (Kiro / Claude)

**Fecha de la sesión:** 2026-10-25

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

*Las entradas siguientes se agregarán cuando se ejecuten las tareas del TP.*
