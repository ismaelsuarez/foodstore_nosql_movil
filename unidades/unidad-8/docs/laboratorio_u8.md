# Laboratorio U8 — PostgreSQL de pruebas e instantánea hacia SQLite

Guía operativa del bloque C del TP8. Prepara un PostgreSQL de pruebas
exclusivo de U8, exporta el catálogo y deja lista `foodstore_movil.db`
para el bloque D. No ejecuta el semáforo ni los casos C2–C6.

Los comandos se ejecutan con Bash desde la raíz del repositorio. Cada
script devuelve 0 si todo salió bien, 1 si falló una comprobación y 2 ante
un error de uso o de entorno. **Ante cualquier código distinto de 0, no se
sigue con el paso siguiente.**

## Recursos

| Recurso | Nombre |
|---|---|
| Contenedor | `foodstore-u8-postgres` (`--network none`, sin puertos publicados, `no-new-privileges`, sin socket de Docker) |
| Volumen | `foodstore_u8_pg_data` |
| Base PostgreSQL | `foodstore_u8` |
| Imagen | `postgres@sha256:2d2b8998d31037bf721cfdf764d76ba74171b4fab3431b7f72c27c56ddbdf9e3` (etiqueta local `postgres:17`) |
| Credencial | `~/.local/share/foodstore_u8_lab/pg_superusuario`, fuera del repositorio: directorio 0700, archivo 0640 con ACL de lectura para el uid 999 del contenedor. Nunca se muestra ni se copia. |
| Base SQLite | `unidades/unidad-8/movil/foodstore_movil.db` |

No se usan contenedores, volúmenes ni credenciales de U6 o U7.

## Versiones observadas (2026-11-07)

- PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2).
- Docker 29.9.3 (contexto `default`).
- sqlite3 3.54.1 y Bash 5.3.9.

## Procedencia

- Modelo canónico: `schema.sql`, `datos_iniciales.sql` y
  `tpi/sql/objetos_programables.sql` de `foodstore_baseII`, etiqueta
  `u6-cierre` (`8f7877c8a1ff25c1be28b29c46c38cd7c9663e86`). Se leen con
  `git show u6-cierre:<ruta>`, sin cambiar el checkout. Es una copia de
  laboratorio reconstruida desde esos archivos, no un volcado de una base
  conservada.
- Datos auxiliares de U8, en un script aparte
  (`postgresql/datos_auxiliares_u8.sql`): la categoría
  `[U8 prueba] Catálogo de pruebas U8` y seis productos `[U8 prueba]`. Ids
  devueltos por PostgreSQL:

| id | Producto | Precio | Stock | Estado inicial | Uso previsto |
|---:|---|---:|---:|---|---|
| 1–3 | Muzzarella, Napolitana, Coca 1.5L (seed) | 1050 / 1500 / 800 | 50 / 40 / 100 | vigentes | — |
| 4 | Base C2 precio | 1200.00 | 20 | vigente | bloque D, C2 |
| 5 | Base C3 stock | 900.00 | 10 | vigente | bloque D, C3 |
| 6 | Base C4 baja | 700.00 | 15 | vigente | bloque D, C4 |
| 7 | Base C5 sin cambios | 500.00 | 30 | vigente | bloque D, C5 |
| 8 | No disponible inicial | 650.00 | 8 | `disponible = false` | catálogo |
| 9 | Baja inicial | 450.00 | 5 | `eliminado = true` | lápida |

  No se crean pedidos ni se invoca `registrar_detalle_pedido`. Los cinco
  pedidos presentes son los del seed.
- Vista de instantánea: `postgresql/snapshot_movil.sql` (design.md §5).

## Orden reproducible

1. **Credencial privada.** Se crea una sola vez, sin mostrar su contenido.
   Si el directorio o el archivo ya existen, la secuencia se detiene y no
   los reemplaza:

   ```bash
   bash -c 'set -e
   d=~/.local/share/foodstore_u8_lab; f=$d/pg_superusuario
   if [ -e "$d" ] || [ -e "$f" ]; then echo "Ya existe $d: no se reemplaza" >&2; exit 2; fi
   mkdir -p ~/.local/share && mkdir -m 700 "$d"
   (umask 077; set -o noclobber
    head -c 64 /dev/urandom | base64 | tr -dc A-Za-z0-9 | head -c 32 > "$f")
   setfacl -m u:999:r "$f"'
   ```

2. **Contenedor y volumen.** Si alguno ya existe, el script se detiene sin
   reutilizarlo:

   ```bash
   bash unidades/unidad-8/postgresql/laboratorio_u8.sh crear
   ```

3. **Modelo, datos auxiliares y vista.** Sobre `public` vacío, en este orden:
   `schema.sql` (en una transacción), `datos_iniciales.sql` (con su propio
   BEGIN/COMMIT), `objetos_programables.sql` (en una transacción),
   `datos_auxiliares_u8.sql`, `snapshot_movil.sql` y las comprobaciones de
   `verificar_instalacion_u8.sql`. Todo con `ON_ERROR_STOP`; se detiene en el
   primer error.

   ```bash
   bash unidades/unidad-8/postgresql/laboratorio_u8.sh instalar
   ```

4. **Exportación.** `psql` corre dentro del contenedor. Su salida estándar,
   que contiene solo el CSV, se guarda en el host. Los metadatos salen por
   la salida de error y van al archivo de metadatos. Conteo y datos
   provienen de la misma transacción de lectura. No se sobrescriben
   destinos existentes.

   ```bash
   bash unidades/unidad-8/postgresql/laboratorio_u8.sh exportar \
       unidades/unidad-8/movil/servidor_snapshot.csv \
       unidades/unidad-8/movil/servidor_snapshot_meta.txt
   ```

   El contrato de columnas es
   `producto_id,nombre,precio_centavos,stock,disponible,eliminado,capturado_en`,
   con orden por `producto_id`, booleanos `t`/`f` y centavos enteros.
   Solo se admite el subconjunto de CSV usado en este laboratorio: siete
   campos simples, sin entrecomillado y sin comas, comillas ni saltos de
   línea dentro de un campo. Un CSV válido fuera de ese subconjunto se
   rechaza (design.md §10.1).

5. **Base SQLite nueva.** Se aplican `schema_sqlite.sql` y
   `snapshot_servidor.sql`. Nunca se ejecuta `pruebas_sqlite.sql` sobre esta
   base.

   ```bash
   bash unidades/unidad-8/movil/preparar_foodstore_movil.sh crear \
       unidades/unidad-8/movil/foodstore_movil.db
   ```

6. **Renovación de la instantánea y carga del catálogo.** Primero se
   comprueba la huella y la estructura del CSV. Después, en una sola
   transacción: `DELETE`, `.import`, controles, UPSERT de `producto_cache` y
   `COMMIT`. Ante cualquier fallo se revierte todo y el catálogo no se toca
   (design.md §10.1).

   ```bash
   bash unidades/unidad-8/movil/preparar_foodstore_movil.sh renovar \
       unidades/unidad-8/movil/foodstore_movil.db \
       unidades/unidad-8/movil/servidor_snapshot.csv \
       unidades/unidad-8/movil/servidor_snapshot_meta.txt
   ```

   La renovación es exitosa solo si el código es 0, la salida de error está
   vacía y la última línea es `RENOVACION CONFIRMADA`.

7. **Verificación del bloque C.** Abre la base entregable en modo de solo
   lectura. Las pruebas de renovación repetida e importación inválida
   trabajan sobre copias en `/tmp`.

   ```bash
   bash unidades/unidad-8/movil/verificar_bloque_c.sh \
       unidades/unidad-8/movil/foodstore_movil.db
   ```

   Se espera `RESULTADO GLOBAL: OK`. Los grupos b/c/d/e/f de este script son
   pruebas del bloque C y no los casos C1–C7 de la consigna.

## Estado al cerrar el bloque C

- `pedido_borrador`, `item_borrador` y `cola_sync` vacías.
- `producto_cache` y `snapshot_servidor` con los 9 productos de la
  instantánea `2026-11-07 15:51:24.499236+00`.
- El contenedor queda en ejecución para el bloque D. No se elimina.

## Bloque D: semáforo y casos C2–C6

Se parte del estado de C. Antes de empezar se guardó una copia de la base
cerrada en `/tmp/foodstore_u8_copia_inicial_c.7CuDfN/` (huella `81ca5120…`).
Del laboratorio C solo se usan `laboratorio_u8.sh exportar` y
`preparar_foodstore_movil.sh renovar`; nunca `crear` ni `instalar`.

**Secuencia completa** (casos C2 → C3 → C4 → C5 → C6):

```bash
bash unidades/unidad-8/movil/ejecutar_bloque_d.sh <AAAAMMDD_HHMMSS> /tmp/<dir_puntos_nuevo>
```

Cada caso termina su preparación antes de simular:

1. Crea el borrador y su solicitud PENDIENTE (`bloque_d.sh borrador`). En C2
   y C4, el borrador se crea antes de cambiar el servidor.
2. Ejecuta la mutación de PostgreSQL del escenario (`bloque_d.sh preparar`).
   Cada una cambia un campo de un producto y falla si no modifica
   exactamente una fila.
3. Exporta a `movil/instantaneas/<ejecucion>/<escenario>/` y renueva
   (`bloque_d.sh instantanea`).
4. Simula (`bloque_d.sh simular`). PostgreSQL se lee inmediatamente antes y
   después; el semáforo corre solo en SQLite.
5. Comprueba el resultado (`bloque_d.sh comprobar`).

En C2, después del CONFLICTO, se registra la aceptación simulada del cliente
(`bloque_d.sh aceptar`) y se evalúa la solicitud nueva. C6 reinserta el UUID
original de C2 y repite el semáforo sin pendientes. Ante un código distinto
de 0, la secuencia se detiene sin reintentar ni reinicializar.

El directorio de puntos guarda dos copias de la base para los controles:

```bash
bash unidades/unidad-8/movil/controles_d.sh /tmp/<dir_puntos>/punto_c2_borrador.db \
    /tmp/<dir_puntos>/punto_c2_conflicto.db \
    unidades/unidad-8/movil/instantaneas/<ejecucion>/c3_stock
```

Los controles trabajan sobre copias en `/tmp` y no abren la base entregable.

**Orden real del 2026-11-07, ejecución `20261107_195358`:** la secuencia
completa se detuvo en el paso 32 (comparación de C6-1) por un error del
propio script: guardaba los estados en el directorio de trabajo. Después de
corregirlo se continuó con
`bash unidades/unidad-8/movil/ejecutar_bloque_d.sh --continuar-c6 20261107_195358 /tmp/foodstore_u8_d_puntos_20261107_195358`,
que comprueba C2–C5 y ejecuta solo C6 y el estado final. Por último se
ejecutó `controles_d.sh`. No se vuelve a correr `verificar_bloque_c.sh` sobre
la base: ese verificador corresponde al estado inicial de C.

## Estado al cerrar el bloque D

- PostgreSQL de pruebas: producto 4 a 1320.00, producto 5 con stock 2,
  producto 6 con baja lógica. Pedidos y líneas del seed sin cambios.
- `foodstore_movil.db`: 4 borradores, 5 solicitudes evaluadas, sin
  PENDIENTE. Instantánea vigente `c4_baja`. Catálogo disponible: 1, 2, 3, 4,
  5, 7.
- El contenedor sigue en ejecución. No se elimina.

## Evidencias

- `unidades/unidad-8/evidencias/bloque_c_postgresql_20261107_125121.txt`:
  creación del laboratorio, instalación, ids y exportación.
- `unidades/unidad-8/evidencias/bloque_c_sqlite_20261107_130343.txt`:
  creación y renovación de `foodstore_movil.db` y pruebas b–f.
- `unidades/unidad-8/evidencias/bloque_c_cierre_20261107_130545.txt`:
  huellas finales, estado de Git y del contenedor.
- `unidades/unidad-8/evidencias/bloque_c_cierre_complemento_20261107_130601.txt`:
  esquema, conteos e `integrity_check` de la base entregable. Repite el
  listado que había fallado por las comillas del comando en los dos
  registros anteriores.

- `unidades/unidad-8/evidencias/bloque_d_entregable_20261107_195358.txt`:
  secuencia D, intento detenido en C6-1.
- `unidades/unidad-8/evidencias/bloque_d_entregable_continuacion_c6_20261107_195500.txt`:
  continuación de C6 y estado final.
- `unidades/unidad-8/evidencias/bloque_d_controles_copias_20261107_195510.txt`:
  controles sobre copias descartables.
- `unidades/unidad-8/evidencias/bloque_d_cierre_*.txt`: huellas, estado de
  Git y del contenedor.

Las pruebas las ejecutó Claude en la sesión principal. En el bloque C, un
subagente redactó los scripts y la sesión principal los leyó antes de
ejecutarlos. Los scripts D los redactó la sesión principal. No reemplaza una
revisión humana.
