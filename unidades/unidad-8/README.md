# Unidad 8 — Base de datos móvil y sincronización (TP8)

**Integrantes:** Avalos Pablo · Blangetti Sofia · Suarez Ismael

La tablet del local usa SQLite para guardar una copia del catálogo, armar
borradores de pedido y simular su envío. PostgreSQL decide precio, stock y
ventas. **Regla de oro:** el móvil propone, el servidor dispone.
`SIMULADO_APROBADO` no es una venta.

**Estado:** los bloques A–D están implementados y tienen evidencia. En el
bloque E están redactados el mapa, el mantenimiento, la bitácora y la guía de
defensa. El inventario cubre **115 lecturas completas + 5 correspondencias
históricas U7 = 120**, sin lecturas pendientes; la correspondencia no se
cuenta como lectura actual nueva. Incluye la lectura comunicada de
ChatGPT/Mila de `tpi/sql/consultas_cobertura_tpi.sql`, con blob local
cotejado; no es revisión humana ni prueba en PostgreSQL.
**E no está completo:** faltan el contraste de la DUIA con el formato de la
cátedra, la elección y el ensayo de defensa, la revisión humana individual de
los scripts y la preparación de la entrega elegida. El informe ya
tiene fuente HTML y PDF de **6 páginas**: **Informe revisado y aprobado por el equipo**,
según lo comunicado por Ismael; no implica aprobación docente.
La consigna admite **ZIP o repositorio con etiqueta `tp8`**. Ismael autorizó
versionar y publicar el TP8 en `main` del repositorio
`ismaelsuarez/foodstore_nosql_movil`, con etiqueta `tp8`. El versionado está
en preparación; el resultado del commit/push y de la publicación se comprueba
después y no consta en este archivo (ver `docs/bitacora_ia.md`, entrada 8).
El contraste formal de la DUIA sigue pendiente y no bloquea este versionado.
No consta ensayo humano de defensa ni aprobación docente. Tampoco consta
entrega en el campus: publicar en GitHub no la reemplaza.

Para 3.c, **H1 (U6), H3 (U3) y H6 (U8)** están aprobados por el equipo
para su presentación en el informe, según lo comunicado por Ismael. H5 queda como complemento: e3 prueba el rechazo
por el control previo sin abrir la base para renovar, no el comportamiento
original de `.import`, del que no hay registro disponible.

Complemento sin motores: [evidencias/bloque_e_complemento_20261107_212101.txt](evidencias/bloque_e_complemento_20261107_212101.txt).

## Documentos

| Documento | Contenido |
|---|---|
| [docs/kiro/](docs/kiro/) | `requirements.md` (REQ-01 a REQ-04), `design.md` y `tasks.md`, con el estado observado de cada bloque |
| [docs/laboratorio_u8.md](docs/laboratorio_u8.md) | Guía operativa del laboratorio y orden real de ejecución de C y D |
| [docs/informe.html](docs/informe.html) · [docs/informe.pdf](docs/informe.pdf) | Informe TP8 de 6 páginas revisado y aprobado por el equipo, según comunicación de Ismael; no implica aprobación docente. Generación original y revisión visual del agente en [la evidencia de generación](evidencias/bloque_e_informe_20261107_220745.txt) |
| [docs/integracion_motores.md](docs/integracion_motores.md) | Mapa de los tres motores y datos que viajan (consigna 3.a) |
| [docs/mantenimiento_u8.md](docs/mantenimiento_u8.md) | Agregado al plan de mantenimiento de U6 (3.b) |
| [docs/revision_scripts_ia.md](docs/revision_scripts_ia.md) | Revisión de scripts con IA (3.c): fichas H1–H6 y selección para el informe |
| [docs/revision_inventario_scripts.md](docs/revision_inventario_scripts.md) | Inventario archivo por archivo de U1–U8 e hipótesis N1–N9 |
| [docs/bitacora_ia.md](docs/bitacora_ia.md) · [docs/DUIA.md](docs/DUIA.md) | Uso de IA (4.b); la DUIA es un borrador |
| [docs/guia_defensa.md](docs/guia_defensa.md) | Preparación del ensayo de 10 minutos (4.c) |
| [evidencias/](evidencias/) | Salidas registradas de cada ejecución |

## A. Revisar la entrega ya construida

Todo lo de esta sección es de solo lectura y no necesita Docker. Las salidas
enlazadas son registros históricos, no una ejecución actual. Consultar la
base final no reproduce los casos ni reemplaza el ensayo humano pendiente.

**Base final:** `movil/foodstore_movil.db`, en su estado posterior al bloque D.
Su huella es `cf541fa5974d16f884c0d897916b7c72964b5171d7f89329f531d818a3a12ace`.
Tiene 4 borradores y 5 solicitudes: 2 SIMULADO_APROBADO, 1 CONFLICTO, 2
RECHAZADO y ninguna PENDIENTE. Lectura de control:
[evidencias/bloque_e_lectura_base_final_20261107_203411.txt](evidencias/bloque_e_lectura_base_final_20261107_203411.txt).

```bash
sha256sum unidades/unidad-8/movil/foodstore_movil.db
bash unidades/unidad-8/movil/bloque_d.sh estado unidades/unidad-8/movil/foodstore_movil.db
```

`bloque_d.sh estado` abre la base con `sqlite3 -readonly` y ejecuta
`movil/estado_bloque_d.sql`. Ese archivo no es un volcado íntegro: omite
`creado_en` de `pedido_borrador` y resume `snapshot_servidor` por fecha y
conteo.

### Matriz de casos de la consigna

| Caso | Requisito | Script | Evidencia |
|---|---|---|---|
| COMMIT / ROLLBACK (1.c) | REQ-02 | `movil/pruebas_sqlite.sql` (grupos COMMIT y ROLLBACK) | `evidencias/bloque_b_20261107_121805.txt` |
| C1 catálogo sin conexión | REQ-01 | `movil/pruebas_sqlite.sql` (grupo C1) | ídem |
| C7-a cantidad 0 / C7-b producto inexistente | REQ-02 | `movil/pruebas_sqlite.sql` + `movil/verificar_bloque_b.sh` | ídem; control negativo en `bloque_b_control_negativo_20261107_104542.txt` |
| C2 precio → CONFLICTO → aceptación → SIMULADO_APROBADO | REQ-03, REQ-04 | `movil/semaforo.sql`, `aceptar_precio.sql`, coordinados por `ejecutar_bloque_d.sh` | `evidencias/bloque_d_entregable_20261107_195358.txt` |
| C3 stock insuficiente → RECHAZADO | REQ-03 | ídem | ídem |
| C4 baja lógica → RECHAZADO y lápida | REQ-01, REQ-03 | ídem | ídem |
| C5 sin cambios → SIMULADO_APROBADO | REQ-03 | ídem | ídem |
| C6-1 UUID duplicado | REQ-04 | `movil/insertar_solicitud.sql` | ejecutado en `bloque_d_entregable_20261107_195358.txt` (paso 30); comparación de estados en la continuación |
| C6-2 semáforo repetido, 0 procesadas | REQ-04 | `movil/semaforo.sql` | `bloque_d_entregable_continuacion_c6_20261107_195500.txt` |

Precisiones para leer estos resultados:

- Las **33 comprobaciones** del bloque B son consultas de verificación
  dentro de `pruebas_sqlite.sql`. No equivalen a 33 casos de la consigna:
  cubren COMMIT, ROLLBACK, C1 y C7.
- **PostgreSQL sin cambios** significa que las salidas de la consulta de
  control `postgresql/control_invariancia.sql` (valores por producto y
  agregados de pedidos y líneas) fueron idénticas antes y después de cada
  simulación. No se comparó toda la base.
- **Secuencia D:** el intento original se detuvo en el paso 32, después de
  ejecutar C6-1, por un error del coordinador, que escribió sus archivos de
  control en la raíz del repositorio. Esos archivos se trasladaron y el
  estado final quedó sin esos residuos. La continuación comparó los estados
  conservados de C6-1 y ejecutó C6-2. **No hay una ejecución íntegra desde
  cero de la secuencia D corregida.**
- **Controles sobre copias** (`controles_d.sh`, controles B y C): son
  resultados de bases descartables, no de la base final. En esos controles
  la operación puede fallar y la prueba aprobar. El auxiliar genérico
  (`bloque_d.sh`) informa el resultado de la operación («FALLA… esperado
  0»), mientras que `controles_d.sh` valida que el fallo sea el esperado.

## B. Reproducir desde un entorno nuevo

**No ensayada en esta forma completa.** Es una ruta de reproducción distinta
de consultar la base final (sección A) y del ensayo humano de defensa, que
sigue pendiente (`docs/guia_defensa.md`). Seguí el orden y detenete ante
cualquier código de salida distinto de 0.

### Requisitos

- Bash 5 (los comandos se ejecutan con `bash`, aunque la shell interactiva
  sea otra) y `sqlite3` con tablas STRICT, JSON y `.parameter`. Se usó la
  versión 3.54.1. Python **no** es requisito.
- Docker, `git`, `setfacl` y utilidades estándar (`sha256sum`, `awk`,
  `mktemp`, `ln`, `realpath`).
- La imagen PostgreSQL local con id
  `sha256:2d2b8998d31037bf721cfdf764d76ba74171b4fab3431b7f72c27c56ddbdf9e3`
  (`postgres:17`, PostgreSQL 17.11). Los scripts la usan con
  `--pull=never` y verifican ese id. Otra imagen exige editar la constante
  `IMAGEN` de `postgresql/laboratorio_u8.sh` y de `movil/bloque_d.sh`.
- El repositorio relacional como directorio hermano, `../foodstore_baseII`,
  con la etiqueta `u6-cierre`
  (`8f7877c8a1ff25c1be28b29c46c38cd7c9663e86`). La ruta está fijada en
  `laboratorio_u8.sh`.

### Nombres fijados en el código

Esto es una condición de los scripts entregados, no una exigencia de la
consigna. No son configurables:

- contenedor `foodstore-u8-postgres`, volumen `foodstore_u8_pg_data`, base
  `foodstore_u8`; Docker se invoca con `--context default`, usa la red
  `none` (`--network none`) y no publica puertos: no hay una red propia de
  nombre fijo ni un puerto del host que reservar
  (`postgresql/laboratorio_u8.sh:16–18,26,84–89`);
- credencial en `~/.local/share/foodstore_u8_lab/pg_superusuario`;
- base de D en `movil/foodstore_movil.db`, que también es la que lee
  `verificar_bloque_c.sh` junto con `movil/servidor_snapshot.csv`;
- los ids de producto 4, 5 y 6 de las mutaciones de D, que se obtienen al
  instalar el seed y los datos auxiliares en ese orden sobre una base vacía.

Por eso, la reproducción necesita:

1. **Un entorno Docker sin ese contenedor ni ese volumen en el daemon al
   que apunta el contexto `default`.** Los scripts se detienen si ya existen
   (`postgresql/laboratorio_u8.sh:69–74`). Cambiar de usuario no garantiza un
   entorno independiente: ambos usuarios pueden usar el mismo daemon.
   No se debe borrar el laboratorio conservado para hacer lugar.
2. **Una copia de trabajo nueva sin los artefactos generados:**
   `movil/foodstore_movil.db`, `movil/servidor_snapshot.csv`,
   `movil/servidor_snapshot_meta.txt` y `movil/instantaneas/`. El exportador
   y `preparar_foodstore_movil.sh crear` no sobrescriben destinos.
3. **La credencial nueva**, creada como indica
   [docs/laboratorio_u8.md](docs/laboratorio_u8.md), paso 1. Ese paso se
   detiene si ya existe.

### Orden

Desde la raíz del repositorio:

```bash
# 1. Bloque B: siempre sobre una base descartable nueva
bash unidades/unidad-8/movil/verificar_bloque_b.sh

# 2. Laboratorio PostgreSQL (bloque C)
bash unidades/unidad-8/postgresql/laboratorio_u8.sh crear
bash unidades/unidad-8/postgresql/laboratorio_u8.sh instalar
bash unidades/unidad-8/postgresql/laboratorio_u8.sh exportar \
    unidades/unidad-8/movil/servidor_snapshot.csv \
    unidades/unidad-8/movil/servidor_snapshot_meta.txt

# 3. Base SQLite y renovación (bloque C)
bash unidades/unidad-8/movil/preparar_foodstore_movil.sh crear unidades/unidad-8/movil/foodstore_movil.db
bash unidades/unidad-8/movil/preparar_foodstore_movil.sh renovar \
    unidades/unidad-8/movil/foodstore_movil.db \
    unidades/unidad-8/movil/servidor_snapshot.csv \
    unidades/unidad-8/movil/servidor_snapshot_meta.txt

# 4. Verificación de C: solo ahora, ANTES de D
bash unidades/unidad-8/movil/verificar_bloque_c.sh unidades/unidad-8/movil/foodstore_movil.db

# 5. Bloque D y controles sobre copias
bash unidades/unidad-8/movil/ejecutar_bloque_d.sh <AAAAMMDD_HHMMSS> /tmp/<dir_puntos_nuevo>
bash unidades/unidad-8/movil/controles_d.sh /tmp/<dir_puntos_nuevo>/punto_c2_borrador.db \
    /tmp/<dir_puntos_nuevo>/punto_c2_conflicto.db \
    unidades/unidad-8/movil/instantaneas/<AAAAMMDD_HHMMSS>/c3_stock
```

Reglas:

- **No** ejecutar `verificar_bloque_c.sh` contra la base posterior a D:
  comprueba el estado inicial de C, con las tablas de borradores vacías.
- **No** volver a ejecutar la preparación ni `ejecutar_bloque_d.sh` sobre la
  base ya entregada.
- **CSV admitido:** siete campos simples, sin entrecomillado y sin comas,
  comillas ni saltos de línea dentro de un campo. Un CSV válido fuera de ese
  subconjunto se rechaza (`docs/kiro/design.md` §10.1).

## Resguardo local del trabajo

El 2026-11-07 se copiaron a
`~/.local/share/foodstore_u8_resguardos/20261107_205605/` los 61 archivos de
`unidades/unidad-8/` (incluida la base final cerrada) y las tres bases
temporales de los bloques C y D, con huellas de origen y destino
coincidentes (ver [docs/mantenimiento_u8.md](docs/mantenimiento_u8.md) §5).
Es una copia local para conservar el trabajo: no es un ensayo de
restauración ni algo que el evaluador necesite.

El complemento del 2026-11-07 comprobó las **48 huellas históricas del cierre
D**, incluida la base final, con stdout y stderr conservados y código de
`sha256sum -c` guardado inmediatamente: 0, todas coincidentes. El registro
anterior que mostró por error el código de `wc` se conserva sin modificar.
También se resguardaron los 9 archivos regulares `c6_*.txt` y
`c6_*.txt.completo` disponibles, sin enlaces ni bases, en el subdirectorio
nuevo `complemento_20261107_212146/` del mismo resguardo. Dos coinciden
además con huellas históricas; para los otros siete solo se acredita la
coincidencia actual origen/destino. Los cinco documentos actualizados y el
complemento nuevo se copian allí al finalizar, sin sobrescribir resguardos
anteriores. Detalles y rutas en la evidencia complementaria enlazada arriba.

## Estructura

```text
unidades/unidad-8/
├── README.md
├── docs/          kiro/, laboratorio, integración, mantenimiento, revisión,
│                  bitácora, DUIA y guía de defensa
├── movil/         esquema, pruebas, renovación, semáforo, aceptación,
│                  coordinadores, CSV, instantáneas y foodstore_movil.db
├── postgresql/    instalación del laboratorio, vista, exportación y mutaciones de D
└── evidencias/    registros de ejecución con fecha
```

La consigna propone `food-store/movil/` y `food-store/docs/` en la raíz. Este
repositorio agrupa todo por unidad (`unidades/unidad-8/`), igual que en U7.
`docs/informe.html` y `docs/informe.pdf` tienen estado **Informe revisado y
aprobado por el equipo**, según comunicación de Ismael; no implica aprobación docente. Chrome 157 convirtió el HTML autónomo a
PDF A4 de 6 páginas; el agente revisó visualmente las seis páginas
renderizadas. La [evidencia de generación](evidencias/bloque_e_informe_20261107_220745.txt)
registra comando, correcciones de paginación y huellas de aquella generación.
La aprobación comunicada por Ismael y esta actualización se registran en
[la evidencia de actualización](evidencias/bloque_e_informe_aprobado_20261107_230321.txt).
No se repitieron B/C/D ni se ejecutaron motores o clientes de bases; la huella de
la base entregable sigue siendo `cf541fa5…12ace`. Esta verificación no
acredita revisión humana individual de los scripts ni el ensayo de defensa pendiente.
