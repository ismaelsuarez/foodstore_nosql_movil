# Food Store — Bases de Datos II — Unidades 7 y 8

**Universidad Tecnológica Nacional — Tecnicatura Universitaria en Programación**

**Integrantes:** Avalos Pablo · Blangetti Sofia · Suarez Ismael

---

## Propósito

Este repositorio continúa el proyecto integrador Food Store en las **Unidades 7
y 8** de Bases de Datos II. El trabajo relacional de las Unidades 1 a 6 está en
el repositorio
[foodstore_baseII, etiqueta `u6-cierre`](https://github.com/ismaelsuarez/foodstore_baseII/tree/u6-cierre),
commit `8f7877c8a1ff25c1be28b29c46c38cd7c9663e86`. Ese repositorio es el origen
de los datos y no se copia ni se modifica desde aquí.

## Índice

| Unidad | Tema | Estado |
|---|---|---|
| [Unidad 7](unidades/unidad-7/README.md) | NoSQL y nuevas formas de almacenamiento: pedidos de Food Store en MongoDB, comparados con PostgreSQL | Implementada y documentada |
| Unidad 8 | — | Prevista, no iniciada |

## Accesos directos (Unidad 7)

- [Presentación de la Unidad 7](unidades/unidad-7/README.md): consignas,
  archivos, evidencias y resultados.
- [Informe de entrega (PDF)](unidades/unidad-7/informe_u7.pdf), con su fuente
  editable [informe_u7.html](unidades/unidad-7/informe_u7.html).
- [Guía de evaluación](unidades/unidad-7/EVALUACION.md): revisión sin ejecutar
  motores y reproducción en laboratorio.
- Consultas entregables:
  [consultas_mongodb.js](unidades/unidad-7/mongodb/consultas_mongodb.js) y
  [consultas_postgresql.sql](unidades/unidad-7/postgresql/consultas_postgresql.sql).

## Estructura

```text
README.md                  este archivo
AGENTS.md                  reglas de trabajo y ruta de lectura
unidades/unidad-7/
  README.md                presentación de la unidad
  EVALUACION.md            ruta de revisión y de reproducción
  informe_u7.pdf / .html   informe de entrega y su fuente
  postgresql/              extracción y consultas SQL (solo lectura)
  mongodb/                 carga, validaciones y consultas MongoDB
  datos/                   archivo de intercambio extraído del origen
  evidencias/              extractos de las ejecuciones
  docs/                    laboratorio, contraste de IA, conclusión, inventario, bitácora
  specs/                   requisitos, diseño y tareas
```

## Estado

- **Versión de entrega:** etiqueta `u7-cierre` de este repositorio.
- **Revisión:** el informe, el contraste de IA y la conclusión son propuestas
  redactadas con asistencia de IA. No consta todavía una revisión del equipo ni
  una aprobación docente.
- **Herramientas:** Kiro se usó para especificar y Claude para implementar y
  documentar; ambas fueron autorizadas por el docente. Las decisiones de modelo
  y de versión son del equipo.

## Entrega en ZIP

El ZIP académico se genera desde la etiqueta `u7-cierre` y contiene solo los
archivos versionados. Quedan fuera `.git/`, `.atl/` (registro local de
herramientas del asistente), las credenciales y las salidas completas del
laboratorio, que nunca estuvieron en el repositorio, y el material interno de
revisión.
