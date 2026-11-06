# Food Store NoSQL — Bases de Datos II

## Tecnicatura Universitaria en Programación — UTN

**Integrantes:** Avalos Pablo · Blangetti Sofia · Suarez Ismael

---

## Propósito

Este repositorio es la continuación del proyecto integrador Food Store para las
**Unidades 7 y 8** de Bases de Datos II. El trabajo relacional (U1–U6) se conserva en
el repositorio original [foodstore_baseII](../foodstore_baseII/README.md), etiqueta
`u6-cierre`, commit `8f7877c8a1ff25c1be28b29c46c38cd7c9663e86`.

No se copia ni se modifica el repositorio relacional.

---

## Estado actual

**Diseño cerrado por el equipo y origen leído; migración y consultas pendientes.**

El 2026-11-06 se registró el [inventario del origen y del entorno](unidades/unidad-7/docs/inventario_origen_entorno.md):

- La primera inspección quedó bloqueada porque el contenedor de origen estaba
  detenido. Después, con autorización, se inició y se leyó la base `foodstore` en
  una transacción de solo lectura.
- Lote elegido: pedidos 1–5. Parámetros: estado `TERMINADO`, producto 1
  (Muzzarella) y umbral 3000.00.
- Se descargó la imagen `mongo:8.0` y quedó registrado su digest. El servidor
  MongoDB no se inició.

Las decisiones de modelo son del equipo, no aprobaciones docentes. Ningún
script de migración ni consulta entregable ha sido creado ni ejecutado.
Ningún dato ha sido migrado.

---

## Alcance por unidad

| Unidad | Tema | Estado |
|---|---|---|
| Unidad 7 | NoSQL — MongoDB: modelado y consultas sobre el subconjunto de pedidos | Diseño cerrado; implementación pendiente |
| Unidad 8 | Prevista; tema y consigna pendientes de publicación | No iniciada |

---

## Documentos disponibles (Unidad 7)

| Documento | Contenido |
|---|---|
| [Requisitos](unidades/unidad-7/specs/requirements.md) | Traducción de las siete consignas a criterios comprobables |
| [Diseño](unidades/unidad-7/specs/design.md) | Modelo documental, tipos, reglas de integridad, lote y consultas |
| [Tareas](unidades/unidad-7/specs/tasks.md) | Lista ordenada para la implementación |
| [Inventario](unidades/unidad-7/docs/inventario_origen_entorno.md) | Entorno, lectura real del origen, lote elegido e imagen MongoDB |
| [Bitácora IA](unidades/unidad-7/docs/bitacora_ia.md) | Registro de las intervenciones de IA |

---

## Origen de los datos

- **Modelo relacional:** `schema.sql` y `datos_iniciales.sql` del repositorio
  `foodstore_baseII` en la etiqueta `u6-cierre`.
- **Dataset del seed:** cinco pedidos de Ana Gómez, Luis Paz y Marta Ruiz, todos
  con estado TERMINADO, fechas entre 2026-03-01 y 2026-03-07.
- **Origen leído:** base `foodstore` del contenedor `foodstore-u6-evaluacion`.
  Contiene los pedidos 1–5 y los usuarios 1–3, confirmados por lectura el
  2026-11-06 (ver el inventario).
- La consigna autoriza incorporar pedidos de prueba adicionales si el dataset real
  no alcanza los cinco pedidos requeridos, indicando su procedencia.

---

## Herramientas

Kiro para especificación; Claude para implementación (ambas autorizadas por el docente).
Toda propuesta de IA se revisa antes de ejecutarse.
