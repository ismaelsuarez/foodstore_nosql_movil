# Tasks — Unidad 7: Lista de implementación

**Estado al 2026-11-06:** T1–T5 ejecutadas con MongoDB 9.0.4 ([laboratorio](../docs/laboratorio_migracion.md)).
El primer intento con `mongo:8.0` quedó bloqueado por la comprobación de kernel
y se conserva como antecedente. T6 está redactada, con la conclusión pendiente de
revisión del equipo. T7: informe y repositorio preparados para la versión de
entrega `u7-cierre`; la revisión del equipo no consta.

---

## T1 — Aprobar el modelo y comprobar el entorno

**Resultado esperado:**
- El equipo revisa y aprueba `design.md` y `requirements.md`.
- Se confirma que MongoDB está disponible (imagen `postgres:17` ya verificada
  para U6; verificar disponibilidad de una imagen MongoDB compatible).
- Se confirma que las herramientas cliente de PostgreSQL (`psql`, `pg_dump`)
  están accesibles para extraer el subconjunto.

**Dependencias:** ninguna.

**Estado:** completada el 2026-11-06 ([inventario](../docs/inventario_origen_entorno.md)).

- Modelo: decisiones adoptadas por el equipo mediante el encargo del
  2026-11-06 (`design.md` §9); no hay aprobación docente.
- Bash 5.3.9 y Docker 29.9.3 disponibles; imagen `postgres:17` local.
- `psql` y `pg_dump` no están en el host, solo dentro del contenedor.
- MongoDB: imagen `mongo:8.0` descargada, digest
  `sha256:b9924c330a8bbc5800fe9c69f04a84e221eca7b28fd049a0354147d9908fa142`.
  Servidor no iniciado; versión exacta sin comprobar. No hay `mongosh`,
  `mongoimport` ni Compass en el host.

---

## T2 — Identificar el origen y extraer el subconjunto (solo lectura)

**Resultado esperado:**
- Consulta de solo lectura sobre la base `foodstore` del contenedor
  `foodstore-u6-evaluacion`, instalada desde `foodstore_baseII` (etiqueta
  `u6-cierre`), que devuelve los cinco pedidos y sus líneas con todos los campos
  necesarios.
- Se registran los IDs reales de pedidos, usuarios y productos.
- Se elige el estado concreto para C4b y el producto para C4c.

**Dependencias:** T1 (entorno disponible y modelo aprobado).

**Estado de la lectura (T2a):** completada el 2026-11-06. La primera inspección
quedó bloqueada porque el contenedor estaba detenido y no había autorización
para iniciarlo; con la autorización posterior se inició y se leyó en una
transacción `REPEATABLE READ, READ ONLY` terminada con `ROLLBACK`. Lote: pedidos
1–5; estado `TERMINADO`; producto 1 (Muzzarella); umbral 3000.00
([inventario](../docs/inventario_origen_entorno.md) §3–§4).

**Estado de la extracción (T2b):** completada el 2026-11-06 con
`postgresql/extraccion_pedidos.sql`, código 0. Se obtuvieron 5 pedidos y 7 líneas,
iguales al inventario. Los usuarios 1–3 se compararon con el seed sintético antes
de exportarlos. El resultado es `datos/pedidos_origen.json`, con SHA-256
`930562ab8d97a1a8eb7a72e972d7b857dd61e73c5db9c86051676513196bec7a` ([laboratorio](../docs/laboratorio_migracion.md) §6).

---

## T3 — Preparar MongoDB y cargar los documentos

**Resultado esperado:**
- Base `foodstore_u7` creada en MongoDB.
- Colección `pedidos` con los 5 documentos del lote cargados mediante
  `insertMany()`, con `_id` = `pedido.id` y tipos explícitos (`design.md` §3).
- Antes de cargar, el script detecta `_id` del lote ya existentes y se detiene
  si hay colisión (`design.md` §8). Sin upserts ni borrados; `insertMany()` no
  se presenta como transacción atómica.
- `db.pedidos.countDocuments()` ≥ 5.
- Los documentos respetan el esquema de `design.md`.

**Dependencias:** T2b (datos del cliente y de productos extraídos).

**Estado:** completada el 2026-11-06 con `foodstore-u7-mongo9`.

- Entorno: `mongo:9.0.4` usado por digest `sha256:452bdaf2…a058`; `mongod`
  9.0.4 y `mongosh` 2.14.0.
- Usuarios: `u7_operador` con `readWrite` solo sobre `foodstore_u7`. Lectura
  autorizada (código 0) y rechazo sin autenticación (código 1) comprobados.
- Carga: `insertMany` reconocido, 5 documentos, código 0.
- Repetición: rechazada antes de escribir, con código 3.

Antecedente: el primer intento con `mongo:8.0` en `foodstore-u7-mongo` terminó
con código 1 por la comprobación de kernel (SERVER-136848). Se conserva detenido.

---

## T4 — Verificar datos y reglas de integridad

**Resultado esperado:**
- RI-01 verificada en todas las líneas, incluidas las eliminadas: cantidad
  `Int32` positiva e importes no negativos.
- RI-02 verificada: subtotal = cantidad × precio histórico en cada línea, y
  total = suma de subtotales de líneas no eliminadas (o cero).
- Comparación de conteos entre el origen PostgreSQL y la colección MongoDB.

**Dependencias:** T3.

**Estado:** completada el 2026-11-06. `mongodb/validaciones_mongodb.js` terminó con
código 0 y 12 comprobaciones OK, antes y después de la repetición, con la misma
huella de documentos (`7a2351dc…`).

---

## T5 — Ejecutar consultas y comparación entre motores

**Resultado esperado:**
- C4a–C4d ejecutadas en MongoDB con los filtros de `design.md` §7, con
  salidas registradas.
- Equivalentes de C4b y C4c ejecutadas en PostgreSQL sobre la misma lista de
  IDs del lote, contando pedidos distintos.
- Tabla de comparación completa (cantidad e IDs coincidentes).
- Diferencias explicadas o corregidas.
- Archivos `consultas_mongodb.js` y `consultas_postgresql.sql` listos.

**Dependencias:** T4.

**Estado:** completada el 2026-11-06; ambos archivos terminaron con código 0.

| Consulta | PostgreSQL | MongoDB | Coinciden los IDs |
|---|---|---|---|
| C4b | 5 (1–5) | 5 (1–5) | Sí |
| C4c | 3 (1, 3, 5) | 3 (1, 3, 5) | Sí |

En MongoDB, C4a devolvió 1–5 y C4d devolvió 3 y 4 ([laboratorio](../docs/laboratorio_migracion.md) §6).

---

## T6 — Contrastar la respuesta de IA

**Resultado esperado:**
- Prompt enviado a la herramienta de IA registrado en `bitacora_ia.md`.
- Dos afirmaciones concretas de la respuesta contrastadas con documentación
  oficial (MongoDB docs o PostgreSQL docs) o con resultados del laboratorio.
- Conclusión de hasta 200 palabras fundamentada en al menos dos criterios técnicos.

**Dependencias:** T5 (resultados del laboratorio disponibles para el contraste).

**Estado:** redactada el 2026-11-06.

- [Contraste de IA](../docs/contraste_ia.md) con el prompt y la respuesta
  generada por Claude Opus 5.5 en la sesión del asistente.
- A1 (atomicidad de `insertMany` y transacciones): primero «necesita matiz»;
  revisada en `contraste_ia.md` §6 como «respaldada documentalmente; no
  ensayada».
- A2 (`CHECK` de PostgreSQL y total del pedido): respaldada.

**Pendiente:** [conclusión](../docs/conclusion_u7.md), de 186 palabras en su
versión ajustada, sujeta a revisión del equipo. El prompt quedó en `contraste_ia.md` en lugar de en
`bitacora_ia.md`, que lo referencia.

---

## T7 — Preparar informe, guía de reproducción y cierre

**Resultado esperado:**
- `informe_u7.pdf` de hasta 5 páginas con todos los entregables de la consigna.
- Guía de reproducción mínima que permita al evaluador recrear el laboratorio.
- `bitacora_ia.md` actualizada con T6.
- Git: `git status` limpio (salvo archivos de datos explícitamente excluidos
  por `.gitignore`).

**Dependencias:** T6.

**Estado:** informe preparado para la versión de entrega `u7-cierre`; la
revisión del equipo no consta.

- [informe_u7.pdf](../informe_u7.pdf): 4 páginas A4, generado el 2026-11-06
  con Chrome headless, con referencias enlazadas al repositorio y a la etiqueta.
- Presentación: [README.md](../README.md) y [EVALUACION.md](../EVALUACION.md).
- Fuente editable: [informe_u7.html](../informe_u7.html).
- La guía de reproducción es [laboratorio_migracion.md](../docs/laboratorio_migracion.md).

**Pendiente:** revisión del equipo. La publicación en
`github.com/ismaelsuarez/foodstore_nosql_movil` se hace con la etiqueta
`u7-cierre`, sin entrega al campus.
