# Tasks — Unidad 7: Lista de implementación

**Estado al 2026-11-06:** T1 y la lectura de T2 completadas; extracción,
migración, verificación y consultas pendientes. Ningún script de migración ni
consulta entregable ha sido creado ni ejecutado.

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

**Pendiente (T2b):** extraer nombre y apellido sintéticos de los usuarios 1–3 y
los nombres de producto para construir los documentos, en una etapa autorizada.

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

**Pendiente:** ejecución autorizada sobre MongoDB.

---

## T4 — Verificar datos y reglas de integridad

**Resultado esperado:**
- RI-01 verificada en todas las líneas, incluidas las eliminadas: cantidad
  `Int32` positiva e importes no negativos.
- RI-02 verificada: subtotal = cantidad × precio histórico en cada línea, y
  total = suma de subtotales de líneas no eliminadas (o cero).
- Comparación de conteos entre el origen PostgreSQL y la colección MongoDB.

**Dependencias:** T3.

**Pendiente:** ejecución autorizada.

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

**Pendiente:** ejecución autorizada.

---

## T6 — Contrastar la respuesta de IA

**Resultado esperado:**
- Prompt enviado a la herramienta de IA registrado en `bitacora_ia.md`.
- Dos afirmaciones concretas de la respuesta contrastadas con documentación
  oficial (MongoDB docs o PostgreSQL docs) o con resultados del laboratorio.
- Conclusión de hasta 200 palabras fundamentada en al menos dos criterios técnicos.

**Dependencias:** T5 (resultados del laboratorio disponibles para el contraste).

**Pendiente:** ejecución de la consulta a IA y contraste.

---

## T7 — Preparar informe, guía de reproducción y cierre

**Resultado esperado:**
- `informe_u7.pdf` de hasta 5 páginas con todos los entregables de la consigna.
- Guía de reproducción mínima que permita al evaluador recrear el laboratorio.
- `bitacora_ia.md` actualizada con T6.
- Git: `git status` limpio (salvo archivos de datos explícitamente excluidos
  por `.gitignore`).

**Dependencias:** T6.

**Pendiente:** no generar el PDF hasta tener las evidencias reales de T5 y T6.
