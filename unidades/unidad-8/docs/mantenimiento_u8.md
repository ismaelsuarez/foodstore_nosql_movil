# Ampliación del plan de mantenimiento — Unidad 8

Consigna 3.b del TP8. Agregado al plan de la Unidad 6, que no se modifica.

**Plan de referencia:** `foodstore_baseII`, etiqueta `u6-cierre`
(`8f7877c8a1ff25c1be28b29c46c38cd7c9663e86`):
`unidades/unidad-6/README.md` (líneas 47–77 y 147–193),
`unidades/unidad-6/EVALUACION.md` y los scripts `backup_foodstore.sh` y
`restore_test.sh` de esa unidad.

Lo que el plan U6 ya cubre, según su propia documentación y evidencia:
respaldo de la base PostgreSQL con `pg_dump -Fc` y una línea base de
controles; restauración de prueba con `restore_test.sh` en una base nueva.
El ensayo citado se ejecutó el 2026-11-05, en modo `sin-propietarios`
(`unidades/unidad-6/evidencias/ensayo_evaluacion_20261105.txt`, líneas
100–117: `RESULTADO=RESTAURACION_VALIDADA`, `exit=0`). La programación diaria
quedó propuesta y no instalada (`unidades/unidad-6/README.md`, líneas 16–20).

Los responsables y frecuencias de este documento son **propuestas**: el
equipo todavía no los acordó. Ninguna restauración de U8 se ejecutó.

## 1. Qué se respalda de cada motor

| Motor | Qué se respalda | Por qué | ¿Reconstruible? |
|---|---|---|---|
| PostgreSQL | La base completa, con el procedimiento U6 | Es la fuente de verdad de catálogo, stock, usuarios y ventas | No: un respaldo perdido es información perdida |
| MongoDB (U7) | Nada adicional al repositorio | La colección `pedidos` se reconstruye desde el archivo de intercambio versionado (`unidades/unidad-7/datos/pedidos_origen.json`) y los scripts U7 | Sí, por carga desde el repositorio. La reconstrucción documentada es la de U7, no un ensayo de U8 |
| SQLite de cada tablet | El archivo `foodstore_movil.db` completo | Contiene borradores y solicitudes que **solo existen en la tablet** | Parcialmente (ver abajo) |

Dentro de la base SQLite:

- **Reconstruible desde la instantánea:** `snapshot_servidor` y las filas de
  `producto_cache` presentes en ella (`preparar_foodstore_movil.sh renovar`).
  Al cargarla en una base nueva se reciben también las bajas que contiene:
  `eliminado = 't'` se convierte en `eliminado = 1` (lápida), no se omite
  (`movil/renovar_snapshot.sql:58–71`). La instantánea no recupera borradores
  locales perdidos ni filas históricas que ya no están presentes en ella.
- **No debe perderse:** `pedido_borrador`, `item_borrador` (con el precio que
  vio el cliente) y `cola_sync` (con el historial de estados y motivos). No
  hay otra copia de esos datos.

**Respaldo propuesto de la tablet:** una copia del archivo cerrado (o
`sqlite3 foodstore_movil.db ".backup destino.db"`) al cierre de cada turno
y antes de cada renovación de la instantánea. A cada copia se le registra la
huella SHA-256 y el resultado de `integrity_check`. No está implementado ni
ensayado.

## 2. Cómo se probaría la restauración

**PostgreSQL:** con el procedimiento U6 (`restore_test.sh`), que restaura en
una base nueva y compara con la línea base del respaldo. Para U8 se agregaría
una sola validación: que `v_snapshot_movil` exista y devuelva una fila por
producto.

**SQLite (propuesta, no ejecutada):**

1. Copiar el respaldo a un directorio nuevo, sin tocar la base de la tablet.
2. Abrirlo con `sqlite3 -readonly` y comprobar `PRAGMA integrity_check` = `ok`
   y `PRAGMA foreign_key_check` sin filas.
3. Comparar la huella con la registrada al respaldar.
4. Ejecutar `movil/estado_bloque_d.sql` y comparar su salida con la guardada
   al respaldar: borradores, ítems, solicitudes por estado, catálogo y fecha de
   la instantánea. Esta consulta no es un volcado íntegro: omite `creado_en`
   de `pedido_borrador` y resume `snapshot_servidor` por fecha y conteo.

## 3. Si se restaura un respaldo viejo de PostgreSQL

El servidor vuelve a un estado anterior, y las tablets pueden haber visto
precios, stock o bajas posteriores. Propuesta:

1. **Instantánea nueva antes de evaluar.** Cada tablet obtiene y renueva una
   instantánea del servidor restaurado. El UPSERT conserva **sin cambios**
   las filas de `producto_cache` ausentes de `snapshot_servidor`; no las marca
   automáticamente `eliminado = 1` ni las oculta necesariamente del catálogo
   (`movil/renovar_snapshot.sql:58–71,86–94`;
   `movil/schema_sqlite.sql:70–76`). Es una limitación de la implementación,
   no una baja lógica automática. Los precios vistos de los borradores no
   cambian (`movil/renovar_snapshot.sql:96–100`).
2. **Las solicitudes PENDIENTE** se evalúan contra esa instantánea nueva con
   el semáforo habitual. Un ítem cuyo producto falta en `snapshot_servidor`
   causa RECHAZADO, aunque siga visible en el catálogo local
   (`movil/semaforo.sql:55–69,92–101`).
3. **Las solicitudes ya evaluadas no se reevalúan ni se reenvían en forma
   automática.** Se propone que el responsable funcional revise manualmente
   las solicitudes previas potencialmente afectadas por la restauración;
   ante falta de información, se incluyen en la revisión. No hay un dato
   estructurado de fecha histórica de evaluación para cada solicitud:
   `cola_sync.creada_en` registra su creación, no su evaluación
   (`movil/schema_sqlite.sql:56–63`). `producto_cache.capturado_en` conserva
   la captura más reciente cargada para ese producto, no la fecha histórica
   de todas las evaluaciones (`movil/schema_sqlite.sql:21–29`;
   `movil/renovar_snapshot.sql:65–71`). El motivo de SIMULADO_APROBADO cita
   una captura, pero no da esa trazabilidad para todas las solicitudes
   (`movil/semaforo.sql:92–101`). Por eso no se promete una selección
   automática precisa por fecha. La revisión no modifica estados evaluados
   ni genera reenvíos: una solicitud nueva, con UUID nuevo, solo surge de
   una decisión explícita; la anterior conserva su estado como historial.
4. **Un `SIMULADO_APROBADO` nunca se convierte en venta.** Ninguna venta se
   registró desde la tablet, así que la restauración no deja ventas
   "huérfanas" del lado móvil. La confirmación real de una venta corresponde
   al servidor.

## 4. Revisión de CONFLICTO y RECHAZADO

| Qué | Quién (propuesta) | Cada cuánto (propuesta) |
|---|---|---|
| Solicitudes en CONFLICTO: decidir con el cliente si acepta el precio nuevo (aceptación de design.md §7.2, con solicitud nueva) | Vendedor de la tablet, con el cliente | En el momento, o al final del turno si el cliente no está |
| Solicitudes en RECHAZADO: stock insuficiente, baja o no disponible | Responsable comercial del local | Una vez por día, al cierre, y siempre después de restaurar PostgreSQL |
| Conteo de solicitudes por estado y por tablet | Responsable comercial | Semanal |

La consulta de revisión es de lectura (`movil/estado_bloque_d.sql`). Ninguna
revisión cambia estados ya evaluados.

## 5. Copias del laboratorio: qué es y qué no es un respaldo

| Copia | Ruta | Qué es |
|---|---|---|
| Copia inicial de C | `/tmp/foodstore_u8_copia_inicial_c.7CuDfN/foodstore_movil_inicial_c.db` (huella `81ca5120…`) | Punto de comparación del laboratorio, previo a D |
| Puntos de prueba de D | `/tmp/foodstore_u8_d_puntos_20261107_195358/` | Copias para los controles sobre copias descartables |
| Copias de los controles | `/tmp/foodstore_u8_d_control.*`, `/tmp/foodstore_u8_c_*` | Bases descartables de pruebas negativas |
| Resguardo local del trabajo | `~/.local/share/foodstore_u8_resguardos/20261107_205605/`, fuera de `/tmp` y de los repositorios | Copia del 2026-11-07, 20:56: las tres bases temporales de arriba y los 61 archivos de `unidades/unidad-8/` tal como estaban a esa hora, incluida la base final cerrada (`cf541fa5…`) |
| Respaldos operativos | — | Propuestos en este documento; **no existen** |

Las rutas `/tmp` son temporales: el sistema puede borrarlas al reiniciar. No
son respaldos permanentes ni garantizados. Las huellas registradas en las
evidencias permiten reconocer esas copias mientras existan.

**Resguardo local.** Sirve para conservar el trabajo del laboratorio, no
para probar una restauración, y no lo necesita el evaluador.

- La copia se hizo con las bases cerradas, sin procesos que las tuvieran
  abiertas y sin archivos de journal.
- Las huellas de origen y destino coinciden: están en `origen_unidad-8.sha256`
  y `temporales.sha256`, dentro del propio resguardo, y en la evidencia
  `evidencias/bloque_e_resguardo_revision_*.txt`.
- Las rutas citadas en las evidencias históricas no se modificaron; la
  correspondencia entre ruta original y resguardo está en esa evidencia.
- Los documentos de E editados después de las 20:56 quedan en el
  repositorio, y su versión de cierre también se copió al resguardo
  (`docs_cierre/`).
- El complemento `evidencias/bloque_e_complemento_20261107_212101.txt:176–200`
  registra las **nueve copias persistentes C6** en
  `~/.local/share/foodstore_u8_resguardos/20261107_205605/complemento_20261107_212146/`:
  `c6_1_antes/despues.txt` y sus `.txt.completo`,
  `c6_2_antes/despues.txt` y sus `.txt.completo`, y `c6_simulacion.txt`.
  Los originales temporales no se movieron. Dos copias coinciden además
  con huellas históricas; para las otras siete solo consta la coincidencia
  origen/destino al copiarlas. Esto conserva capturas, no prueba una
  restauración.
