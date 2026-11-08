# DUIA — Declaración de Uso de IA — TP8 (Unidad 8)

**Borrador.** La consigna pide «la Declaración de Uso de IA de la cátedra»,
pero la plantilla oficial no se encontró en los materiales disponibles
localmente: se revisaron la consigna, el apunte y los PDF de la carpeta de la
materia. Este borrador sigue la estructura de las DUIA anteriores del
proyecto (`foodstore_baseII`, `unidades/unidad-1/tp2/duia/duia_parte1.md`).
**Falta contrastarlo con la plantilla oficial** y completar lo que esta
exija.

**Versión actual:** borrador del 2026-11-07, incluido en el versionado TP8
para la publicación autorizada en `main` con etiqueta `tp8`, todavía en
preparación. El contraste formal con la plantilla oficial sigue pendiente;
no se afirma equivalencia con ella y ese contraste no bloquea el versionado.

**Equipo:** Avalos Pablo · Blangetti Sofia · Suarez Ismael.

**Estado:** sin firmas y sin aprobación del equipo ni del docente. No se
declaran porcentajes de autoría.

## 1. Herramientas utilizadas

| Herramienta | Uso | Fuente de la información |
|---|---|---|
| Kiro | Especificación inicial: `docs/kiro/requirements.md`, `design.md` y `tasks.md` | Indicación del equipo. No consta el modelo interno de Kiro |
| Claude, con el arnés el Gentleman | Correcciones de las especificaciones, scripts SQLite, SQL y Bash de los bloques B–D, ejecución de pruebas y documentación de E | Archivos y evidencias del repositorio |
| Subagentes (`gentle-ai-worker`, `gentle-ai-explore`) coordinados en sesiones de Claude | Redacción de scripts del bloque C, verificaciones delegadas del bloque B, mapeo y lectura de solo lectura de U1–U6 | Bitácora, entradas 2, 3 y 5. Los nombres no acreditan modelo ni proveedor de cada subagente |
| writer acotado de Pi (OpenAI) | Complemento puntual de E: cotejo de blob y cobertura comunicada, contraste de referencias para 3.c, verificación de huellas históricas y nueve copias persistentes C6; sin motores ni repetición de B/C/D | Bitácora, entrada 6; `evidencias/bloque_e_complemento_20261107_212101.txt:1–5,176–200`. No se atribuye a la sesión principal de Claude ni a revisión humana; no consta el modelo |
| ChatGPT (Mila, nombre que le da el equipo) | Coordinación y revisión externa de lo compartido en el chat; lectura comunicada vía conector GitHub del archivo indicado en la entrada 6. En ese entorno no operó sobre la computadora ni los motores locales del equipo | Información aportada por el equipo el 2026-11-07 (bitácora, entrada transversal y entrada 6). No consta el modelo utilizado |
| Equipo humano | Decisiones, autorizaciones por bloque y revisiones comunicadas en los encargos; aprobación del informe presentado, incluido H1/H3/H6 | Ismael comunicó en nombre del equipo: «Bien el equipo lo aprueba» (bitácora, entrada 7). No implica aprobación docente ni cierre de todo TP8 |

La consigna prevé OpenCode. Según comunicó el equipo, el docente autorizó
sustituirlo por Claude. Esta declaración registra esa autorización como
información aportada por el equipo, no como texto de la consigna. No se
infiere de ella autorización docente adicional para la intervención de Pi
ni para otras herramientas o modalidades de defensa.

Ninguna de estas herramientas sustituye la revisión humana. Una ejecución
de un agente no equivale a una revisión del equipo.

## 2. Qué se pidió a la IA

Los pedidos se resumen en `docs/bitacora_ia.md`, sin transcribir prompts
literales que no se conservan. En resumen:
- especificar los requisitos y el diseño;
- corregir inconsistencias puntuales;
- implementar y ejecutar cada bloque dentro de permisos definidos;
- revisar los scripts de la cursada;
- realizar los ajustes documentales mínimos de cierre (bitácora, entrada 8),
  con el writer acotado de Pi (OpenAI), sin modificar informes, scripts,
  bases ni evidencias.

## 3. Qué generó la IA

- Scripts de `movil/` y `postgresql/` de la Unidad 8.
- Evidencias de ejecución en `evidencias/`.
- Documentos de U8: guía de laboratorio, integración, mantenimiento,
  revisión, bitácora, guía de defensa y README.
- `docs/informe.html` y `docs/informe.pdf`: informe producido con asistencia
  de IA. Generación original en
  `evidencias/bloque_e_informe_20261107_220745.txt`; actualización documental
  y regeneración del PDF tras la aprobación comunicada, con intervención
  del writer acotado de Pi (OpenAI), en la bitácora, entrada 7.

## 4. Qué se aceptó

Se registra la aceptación técnica reflejada en los bloques, no una aprobación
final humana o docente: los scripts cuyos resultados constan en las
evidencias de los bloques B–D, que terminaron con resultado global OK. El intento detenido de D quedó
registrado como fallido y no se presenta como aceptado.

**Registro del informe (2026-11-07):** Ismael comunicó en la conversación de
coordinación, en nombre del equipo: «Bien el equipo lo aprueba». Abarca el
informe presentado, incluido el desarrollo de H1/H3/H6. No implica revisión
humana individual de los 120 scripts, aprobación docente, cierre de TP8 o E,
DUIA definitiva, ensayo realizado ni autorización para publicar. No consta
fecha u hora de aprobación; esta es la fecha de registro documental.

**Autorización posterior de cierre (2026-11-07):** Ismael autorizó versionar
y publicar en `main` de `ismaelsuarez/foodstore_nosql_movil`, con etiqueta
`tp8` (bitácora, entrada 8). Es una autorización separada de la aprobación
del informe; no supone aprobación de esta DUIA. El resultado del commit/push
se comprueba después y no consta aquí. No consta ensayo humano de defensa,
aprobación docente ni entrega en el campus; publicar en GitHub no reemplaza
esa entrega.

## 5. Qué se modificó o descartó, y por qué

Ver `docs/bitacora_ia.md`. Entre otros:
- `INSERT OR REPLACE` se reemplazó por un UPSERT.
- Se descartó la «ausencia de salida» como prueba de error.
- Se corrigieron el guardado del registro del bloque B, la validación previa
  del CSV con columnas sobrantes y la ruta de escritura del coordinador de D.
  Para H5 se comprobó ese rechazo previo, no el `.import` original.
- En la revisión de scripts se descartaron dos hipótesis con fundamento
  (`docs/revision_scripts_ia.md`).

## 6. Verificación realizada

- **Resultados de ejecución:** se remiten a los registros históricos de
  `evidencias/`, con huellas de los scripts; no se presentan como ejecuciones
  actuales. El complemento de Pi comprueba huellas y copias de archivos,
  no resultados nuevos de motores.
- **Observaciones estáticas:** lecturas, cotejo del blob y contraste de
  referencias documentados en la bitácora y en las fichas de revisión.
  La coincidencia de huellas no prueba por sí sola revisión de contenido.
- **Selección H1/H3/H6:** aprobada por el equipo para su presentación en el
  informe, según comunicación de Ismael. No acredita revisión humana
  individual de los 120 scripts.
- **Propuestas:** mantenimiento y opciones de defensa; no equivalen a
  restauraciones ensayadas, ensayo humano ni decisiones aprobadas.
- Las pruebas históricas de U8 que escriben datos se hicieron sobre bases
  descartables o sobre el laboratorio U8, nunca sobre U6 ni U7.
- La aprobación comunicada por el equipo se limita al informe presentado.
  No consta aprobación docente ni aprobación de esta DUIA: sigue siendo un
  borrador pendiente de contraste con el formato oficial y de revisión
  humana; no se agregan firmas ni se inventan aprobaciones.

## 7. Pendiente para cerrar la DUIA

1. Conseguir la plantilla oficial de la cátedra y adaptar este borrador a
   ella.
2. Que el equipo revise el contenido, complete los datos que la plantilla
   pida y firme, si corresponde.
