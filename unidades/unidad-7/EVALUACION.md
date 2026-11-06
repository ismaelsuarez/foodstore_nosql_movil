# Evaluación — Unidad 7

Esta guía indica cómo revisar y cómo reproducir el trabajo. Los comandos están
solo en [docs/laboratorio_migracion.md](docs/laboratorio_migracion.md), la
única guía operativa.

Clonar el repositorio no inicia ningún servicio ni da acceso a los contenedores
del equipo: los motores corren en la computadora de quien reproduce. La guía
actualizada no se ejecutó en otra computadora.

## 1. Revisión sin ejecutar motores

1. **Comparar con la consigna.** Leer [informe_u7.pdf](informe_u7.pdf) y la
   matriz de [README.md](README.md).
2. **Leer los scripts.**
   - [postgresql/consultas_postgresql.sql](postgresql/consultas_postgresql.sql)
     y [postgresql/extraccion_pedidos.sql](postgresql/extraccion_pedidos.sql):
     solo lectura (`REPEATABLE READ, READ ONLY`, `ROLLBACK`).
   - [mongodb/migracion_pedidos.js](mongodb/migracion_pedidos.js): es el
     **único** script que escribe, y solo inserta.
   - [mongodb/validaciones_mongodb.js](mongodb/validaciones_mongodb.js) y
     [mongodb/consultas_mongodb.js](mongodb/consultas_mongodb.js): solo leen.
3. **Revisar el lote sin motores.** El archivo
   [datos/pedidos_origen.json](datos/pedidos_origen.json) tiene IDs e importes
   como texto. Con él se pueden recalcular los subtotales, los totales y los
   filtros de C4b, C4c y C4d.
4. **Contrastar con los extractos.** Comparar las huellas y los resultados con
   [evidencias/README.md](evidencias/README.md).

## 2. Reproducción en un laboratorio

| Etapa | Qué hace | Guía |
|---|---|---|
| Prerrequisitos y origen | Herramientas del host y laboratorio U6 (`EVALUACION.md` de `foodstore_baseII` en `u6-cierre`) | [§4.1](docs/laboratorio_migracion.md#41-prerrequisitos) |
| Preparación nueva | Crea credenciales, volumen y contenedor; se detiene si ya existen | [§4.2](docs/laboratorio_migracion.md#42-preparación-nueva) |
| Laboratorio existente | Comprueba la identidad del contenedor; no recrea nada | [§4.3](docs/laboratorio_migracion.md#43-laboratorio-existente) |
| Espera y versiones | Arranque, `mongod` y `mongosh` | [§4.4](docs/laboratorio_migracion.md#44-espera-y-versiones) |
| Control de códigos | Funciones `paso` y `huella` | [§5.1](docs/laboratorio_migracion.md#51-control-de-códigos-de-salida) |
| Origen PostgreSQL | Extracción de control y consultas SQL, de solo lectura | [§5.2](docs/laboratorio_migracion.md#52-origen-postgresql) |
| MongoDB | Carga (escritura), validación, consultas y repetición | [§5.3](docs/laboratorio_migracion.md#53-mongodb) |

**Preparación, escritura y lectura**, en orden:

1. La preparación crea recursos locales y credenciales nuevas, que nunca se
   versionan.
2. La única escritura de datos es `migracion_pedidos.js` sobre
   `foodstore_u7.pedidos`.
3. Todo lo demás lee: las consultas SQL dentro de transacciones de solo lectura,
   y las validaciones y consultas MongoDB sin modificar documentos.

**Identidades, sin secretos:**

- **PostgreSQL:** rol `postgres` dentro del contenedor del laboratorio U6.
- **MongoDB:** `u7_admin` solo para crear usuarios y `u7_operador`
  (`readWrite` sobre `foodstore_u7`) para la carga, las validaciones y las
  consultas.
- **Contraseñas:** se leen de archivos privados fuera del repositorio.

## 3. Resultados esperados, observados y no probados

Ambos motores se comparan sobre el mismo lote (pedidos 1–5) y con los mismos
filtros de baja lógica.

| Elemento | Esperado según el inventario | Observado el 2026-11-06 |
|---|---|---|
| Carga | 5 pedidos, 7 líneas | 5 insertados; 12 comprobaciones OK |
| C4a | 1–5 | 1–5 |
| C4b (PostgreSQL / MongoDB) | 1–5 | 1–5 / 1–5 |
| C4c (PostgreSQL / MongoDB) | 1, 3, 5 | 1, 3, 5 / 1, 3, 5 |
| C4d | 3, 4 | 3, 4 |
| Repetición | Rechazo, código 3 | Rechazo, código 3; contenido sin cambios |
| Lectura sin autenticación | Rechazo | `requires authentication`, código 1 |

Lo observado proviene de
[evidencias/ejecucion_20261106_mongo9.txt](evidencias/ejecucion_20261106_mongo9.txt)
y del [§6 de la guía](docs/laboratorio_migracion.md#6-resultados-observados).

**No probado:**

- Fallo parcial de `insertMany`.
- Transacciones.
- Bajas lógicas reales, porque el lote no tiene ninguna.
- Rendimiento.
- La guía actualizada en otra computadora.
