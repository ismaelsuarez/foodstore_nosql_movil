# Evidencias — Unidad 7

Extractos breves de las ejecuciones del 2026-11-06. Las salidas completas
están fuera del repositorio, en el directorio privado del laboratorio, y los
extractos indican su procedencia. Ninguno contiene credenciales.

## Índice

| Archivo | Alcance |
|---|---|
| [ejecucion_20261106.txt](ejecucion_20261106.txt) | Extracción PostgreSQL, consultas SQL y **antecedente**: el intento con `mongo:8.0` (8.0.34), que no arrancó en el kernel del host |
| [ejecucion_20261106_mongo9.txt](ejecucion_20261106_mongo9.txt) | Ejecución satisfactoria con MongoDB 9.0.4: usuarios, carga, validaciones, consultas en ambos motores y repetición |

Los dos intentos se registran por separado. El fallo de 8.0 no se presenta como
ejecución y el éxito de 9.0.4 no reemplaza ese antecedente.

## Relación entre scripts, datos y ejecución

Huellas SHA-256 registradas en la ejecución con 9.0.4. Los archivos actuales
coinciden con la columna «al finalizar».

| Archivo | Al iniciar | Al finalizar |
|---|---|---|
| `datos/pedidos_origen.json` | `930562ab8d97a1a8eb7a72e972d7b857dd61e73c5db9c86051676513196bec7a` | Igual |
| `postgresql/extraccion_pedidos.sql` | `e06667abc7582e78f635ddba75486d2c22a94079c170dcb0e571ad72480536f8` | Igual |
| `postgresql/consultas_postgresql.sql` | `cd8b6af312f896b4ec68d3a859001968a6335e472374745c8b1eac9040481771` | Igual |
| `mongodb/migracion_pedidos.js` | `951436f40dde47dac86f29237e70188762d9c17e6c89fe6e7ea01c8dd4a9b656` | `36af25b4a08a61a8a50f18db1c7992b7f3f7fbc9151f5cbe0e691f735a291785` |
| `mongodb/validaciones_mongodb.js` | `231886c20e090239111f0ef579057869eeb0df5fd0dfda0cd50ea193eb5832c3` | `b2d2f960ac853a4de948cc23c45a187a9784958c0d07929b256e56e31034f92a` |
| `mongodb/consultas_mongodb.js` | `b611fe6e4de6cefddb494ea954b72381341cbaa6ebb20cdfb505caf0e1fb194a` | `b9544831b7de3202c2aa96dc2390175a5bbb6bf2cb982515e174c1985f44d734` |

Las huellas de los tres `.js` cambian por un único ajuste mecánico, hecho antes
de ejecutarlos: el nombre del contenedor en el comentario de uso. La lógica no
cambió ([laboratorio §7](../docs/laboratorio_migracion.md#7-huellas-de-los-archivos)).

## Nota sobre el número de comprobaciones

`validaciones_mongodb.js` hace **12 comprobaciones** en el recorrido normal.
Las salidas originales registran 12 líneas OK, 0 FALLO y 2 líneas `info`. Una
versión anterior de los documentos decía 13 por un error de conteo. El extracto
lo corrige con una nota trazable y las salidas originales no se modificaron.
El mensaje del commit `235cdbd` conserva el «13» original.

## Límites

- Los extractos resumen salidas reales; no son capturas ni salidas completas.
- Las salidas completas no viajan en el repositorio.
- Corresponden a una sola computadora del equipo y a una única ejecución
  satisfactoria con 9.0.4.
