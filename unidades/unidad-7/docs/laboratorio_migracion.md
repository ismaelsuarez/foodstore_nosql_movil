# Laboratorio de migración — Unidad 7

**Estado al 2026-11-06:** extracción, carga, validaciones, consultas en ambos
motores y prueba de repetición **ejecutadas** con MongoDB 9.0.4. El contraste
de IA está en [contraste_ia.md](contraste_ia.md). La
[conclusión](conclusion_u7.md) es una propuesta pendiente de revisión del
equipo. El informe ([informe_u7.pdf](../informe_u7.pdf), con fuente
[informe_u7.html](../informe_u7.html)) corresponde a la versión de entrega
identificada por la etiqueta `u7-cierre`. La revisión del equipo no consta.

La elección de versión es del equipo, no una exigencia ni una aprobación del
docente.

---

## 1. Origen y destino

| Elemento | Valor |
|---|---|
| Esquema relacional | `foodstore_baseII`, etiqueta `u6-cierre`, commit `8f7877c8a1ff25c1be28b29c46c38cd7c9663e86` |
| Origen | Contenedor `foodstore-u6-evaluacion` (`postgres:17`, PostgreSQL 17.11, red `none`), base `foodstore`, OID 16384 |
| Destino | Contenedor `foodstore-u7-mongo9`, base `foodstore_u7`, colección `pedidos` |
| Lote | Pedidos 1–5 con sus 7 líneas |

## 2. Archivos

| Archivo | Función |
|---|---|
| `postgresql/extraccion_pedidos.sql` | Controles previos y exportación JSON del lote; solo lectura |
| `datos/pedidos_origen.json` | Resultado real de la extracción del 2026-11-06T15:13:28Z (no se editó a mano) |
| `postgresql/consultas_postgresql.sql` | Equivalentes de C4b y C4c; solo lectura |
| `mongodb/migracion_pedidos.js` | Valida el JSON, rechaza IDs existentes y carga con `insertMany` |
| `mongodb/validaciones_mongodb.js` | Conteos, IDs, `$type`, correspondencia, RI-01, RI-02 y precios históricos |
| `mongodb/consultas_mongodb.js` | C4a–C4d |
| `evidencias/ejecucion_20261106_mongo9.txt` | Extracto de la ejecución con 9.0.4 |
| `evidencias/ejecucion_20261106.txt` | Antecedente: extracción y fallo de arranque con 8.0 |

## 3. Versión elegida y antecedente

**Antecedente.** El primer intento usó `mongo:8.0`, que trae MongoDB 8.0.34, con
digest `sha256:b9924c33…fa142`. El contenedor `foodstore-u7-mongo` terminó con
código 1 a los 0,17 s con este mensaje (id 12257600):

> MongoDB cannot start: Linux kernel versions 6.19 and newer has a known
> incompatibility with this version of MongoDB.

El kernel del host es Ubuntu `7.0.0-42-generic`, que corresponde al upstream
7.0.14 según `/proc/version_signature`. La comprobación de esa versión lee
`uname -r` y no reconoce el nivel upstream de Ubuntu (SERVER-136848). Ese
contenedor y su volumen `foodstore_u7_mongo_data` se conservan detenidos y sin
uso.

**Versión elegida por el equipo:** `mongo:9.0.4`. SERVER-131779 corrige la
detección de kernels Ubuntu y figura como corregido en 9.0.4; las notas de
versión de 9.0 incluyen soporte para Ubuntu 26.04.

| Dato | Valor observado |
|---|---|
| Descarga | 2026-11-06, de 15:46:46 a 15:48:26 UTC |
| ID | `sha256:452bdaf2127b8ff851e31410a267809b9829eded219979f2210e7c7efb85a058` |
| RepoDigest | `mongo@sha256:452bdaf2127b8ff851e31410a267809b9829eded219979f2210e7c7efb85a058` |
| Arquitectura | `linux/amd64` |
| `mongod --version` | `db version v9.0.4`, gitVersion `64ade602b836c9adeffba7fa038c887ffab56196`, distmod `ubuntu2604` |
| `mongosh --version` | `2.14.0` |
| Kernel del host | `7.0.0-42-generic`; `Ubuntu 7.0.0-42.42-generic 7.0.14` |

## 4. Preparación (Bash, desde la raíz del repositorio)

### 4.1. Prerrequisitos

- **Host:** Bash, Docker, `jq`, `openssl` y `setfacl` (paquete `acl`), sin
  clientes de MongoDB instalados. Los comandos se ejecutan en Bash desde la
  raíz del repositorio, porque el montaje usa `$PWD/unidades/unidad-7`.
- **Origen PostgreSQL:** se usa el repositorio relacional
  [foodstore_baseII en la etiqueta `u6-cierre`](https://github.com/ismaelsuarez/foodstore_baseII/tree/u6-cierre)
  (commit `8f7877c8a1ff25c1be28b29c46c38cd7c9663e86`) y su guía
  [`unidades/unidad-6/EVALUACION.md`](https://github.com/ismaelsuarez/foodstore_baseII/blob/u6-cierre/unidades/unidad-6/EVALUACION.md).
  Esa guía crea el contenedor `foodstore-u6-evaluacion` y la base `foodstore`
  con `schema.sql`, `datos_iniciales.sql` y `tpi/sql/objetos_programables.sql`.
  Hay dos formas de partir:
  - **Laboratorio existente** (el caso de esta corrida): el contenedor ya está
    cargado y debe estar en ejecución.
  - **Instancia descartable nueva:** se prepara siguiendo esa guía, sin
    duplicarla aquí. Si se usa otro nombre de contenedor, hay que reemplazarlo
    en §5.2.
- **Lote registrado frente a extracción nueva:** en una instancia recreada, los
  identificadores reales deben comprobarse, porque su asignación no se deduce
  del orden textual del seed (inventario §3.2). Una extracción nueva se guarda
  en un archivo propio fuera del repositorio. Si sus datos no coinciden con el
  lote registrado, se informa la diferencia; `datos/pedidos_origen.json` y su
  huella no se sobrescriben.
- **Imagen:** `mongo:9.0.4`, fijada por digest. En este host `mongo:8.0` no
  arrancó (§3).
- **Directorio privado:** el operador elige uno fuera del repositorio para las
  credenciales y las salidas completas. Este laboratorio usó
  `~/.local/share/foodstore-u7-mongo9`. Ninguna contraseña aparece en comandos
  ni en archivos versionados.

```bash
U7_PRIV="$HOME/.local/share/foodstore-u7-mongo9"   # elegido por el operador
U7_AUTH="$U7_PRIV/auth"
IMG9="mongo@sha256:452bdaf2127b8ff851e31410a267809b9829eded219979f2210e7c7efb85a058"
```

### 4.2. Preparación nueva

Solo si el laboratorio no existe. Las guardas van **antes** de generar
credenciales: si encuentran el contenedor, el volumen o el directorio de
credenciales, el bloque se detiene sin crear ni sobrescribir nada, y se sigue
por §4.3. El paréntesis ejecuta el bloque en un subshell, así que `exit` no
cierra la terminal.

```bash
(
  set -eu
  # 1. Guardas: no reutilizar ni pisar recursos existentes.
  if docker container inspect foodstore-u7-mongo9 >/dev/null 2>&1; then
    echo "Ya existe foodstore-u7-mongo9: usar §4.3" >&2; exit 1; fi
  if docker volume inspect foodstore_u7_mongo9_data >/dev/null 2>&1; then
    echo "Ya existe foodstore_u7_mongo9_data: usar §4.3" >&2; exit 1; fi
  if [ -e "$U7_AUTH" ]; then
    echo "Ya existe $U7_AUTH: no se regeneran credenciales" >&2; exit 1; fi
  # 2. Imagen exacta por digest.
  docker pull "$IMG9"
  # 3. Credenciales nuevas; nunca se imprimen. Con noclobber (set -C), ">"
  #    falla si el archivo ya existe: creación exclusiva, nunca reemplazo.
  set -C
  umask 077; mkdir -p "$U7_PRIV/evidencias"; mkdir "$U7_AUTH"
  openssl rand -hex 24 > "$U7_AUTH/u7_admin.pwd"
  openssl rand -hex 24 > "$U7_AUTH/u7_operador.pwd"
  # El entrypoint lee MONGO_INITDB_ROOT_PASSWORD_FILE después de bajar a
  # mongodb (uid 999). La ACL da lectura solo a ese uid y solo sobre ese archivo.
  setfacl -m u:999:x "$U7_AUTH"
  setfacl -m u:999:r "$U7_AUTH/u7_admin.pwd"
  # 4. Volumen y contenedor: standalone, sin red ni puertos.
  docker volume create foodstore_u7_mongo9_data
  docker create --name foodstore-u7-mongo9 --pull never --network none --restart no \
    -v foodstore_u7_mongo9_data:/data/db --tmpfs /data/configdb \
    -v "$U7_AUTH":/run/foodstore-u7-auth:ro \
    -v "$PWD/unidades/unidad-7":/u7:ro \
    -e MONGO_INITDB_ROOT_USERNAME=u7_admin \
    -e MONGO_INITDB_ROOT_PASSWORD_FILE=/run/foodstore-u7-auth/u7_admin.pwd \
    "$IMG9"
  docker start foodstore-u7-mongo9
)
```

El mecanismo de archivo de la imagen crea `u7_admin` con rol `root` y reinicia
`mongod` con `--auth`. Después de la espera (§4.4), y solo en una preparación
nueva, se crea `u7_operador` desde la sesión administrativa:

```bash
docker exec foodstore-u7-mongo9 mongosh --quiet --norc mongodb://127.0.0.1:27017/admin --eval '
  const fs = require("fs");
  const leer = (f) => fs.readFileSync("/run/foodstore-u7-auth/" + f, "utf8").trim();
  db.getSiblingDB("admin").auth("u7_admin", leer("u7_admin.pwd"));
  db.getSiblingDB("foodstore_u7").createUser({ user: "u7_operador", pwd: leer("u7_operador.pwd"),
    roles: [{ role: "readWrite", db: "foodstore_u7" }] });'
```

### 4.3. Laboratorio existente

Si el contenedor y sus credenciales ya existen, no se recrean ni se regeneran,
y `u7_operador` no se vuelve a crear. Primero se comprueba la identidad del
contenedor y después se inicia solo si está detenido:

```bash
docker container inspect foodstore-u7-mongo9 \
  --format "estado={{.State.Status}} imagen={{.Config.Image}} red={{.HostConfig.NetworkMode}}"
# la imagen debe ser el valor de IMG9 y la red, none
docker start foodstore-u7-mongo9   # solo si estaba detenido
```

Si la colección ya contiene el lote, la carga devuelve el código 3, porque
rechaza los IDs existentes. En ese caso se ejecutan las validaciones y las
consultas sobre los documentos ya cargados; no se borra nada para repetir la
carga.

### 4.4. Espera y versiones

Esta comprobación funcionó en este laboratorio:

```bash
docker logs foodstore-u7-mongo9 2>&1 | grep -n "MongoDB init process complete"
docker exec foodstore-u7-mongo9 mongosh --quiet --norc --eval "db.runCommand({ping:1}).ok"  # 1
docker exec foodstore-u7-mongo9 mongod --version
docker exec foodstore-u7-mongo9 mongosh --version
```

El 2026-11-06 un bucle automático de espera informó «no listo» aunque el
servidor ya estaba disponible. Con `set -o pipefail`, `grep -q` cierra la
tubería antes de que `docker logs` termine; `docker logs` recibe SIGPIPE y la
condición resulta falsa. Ese bucle no es un procedimiento validado.

Comprobaciones del contenedor: red `none`, sin puertos, sin privilegios ni
socket de Docker, y montajes de solo lectura para scripts, datos y
credenciales.

## 5. Ejecución

### 5.1. Control de códigos de salida

Cada paso declara el código que espera, y la cadena `&&` se detiene en el
primer código distinto. `huella` guarda la salida en un archivo y devuelve el
código de `mongosh`, no el de `tee`.

```bash
paso() {   # uso: paso CODIGO_ESPERADO comando [args...]
  local esperado=$1; shift
  "$@"; local rc=$?
  if [ "$rc" -ne "$esperado" ]; then echo "FALLO: código $rc, se esperaba $esperado" >&2; return 1; fi
  echo "OK: código $rc (esperado $esperado)"
}
huella() { # uso: huella ARCHIVO comando...
  local salida=$1; shift
  "$@" | tee "$salida"; return "${PIPESTATUS[0]}"
}
```

Las dos funciones se comprobaron el 2026-11-06 con comandos inertes (`true` y
`bash -c "exit N"`), sin bases de datos: la cadena se detuvo ante un código
inesperado y `huella` conservó el código del comando.

### 5.2. Origen PostgreSQL

La extracción versionada ya existe y no se reemplaza. Para comprobar que el
origen no cambió, se extrae a un archivo fuera del repositorio y se comparan
**solo los datos del lote**: `lote`, `conteos_extraidos` y `pedidos`. Los
metadatos del entorno (`origen`, `extraccion` y `sha256_pedidos`) se muestran
aparte como información, porque en otro entorno cambian aunque los datos sean
iguales: OID, versión y fecha.

```bash
paso 0 bash -c 'docker exec -i foodstore-u6-evaluacion \
  psql -X -w -q -A -t -U postgres -d foodstore -v ON_ERROR_STOP=1 -f - \
  < unidades/unidad-7/postgresql/extraccion_pedidos.sql > "$1"' _ "$U7_PRIV/evidencias/control.json" \
&& paso 0 diff <(jq -S '{lote, conteos_extraidos, pedidos}' unidades/unidad-7/datos/pedidos_origen.json) \
               <(jq -S '{lote, conteos_extraidos, pedidos}' "$U7_PRIV/evidencias/control.json") \
&& echo "Datos del lote: iguales a la extracción versionada"
# Informativo, no bloqueante:
diff <(jq -S '{origen, extraccion, sha256_pedidos}' unidades/unidad-7/datos/pedidos_origen.json) \
     <(jq -S '{origen, extraccion, sha256_pedidos}' "$U7_PRIV/evidencias/control.json")

paso 0 bash -c 'docker exec -i foodstore-u6-evaluacion \
  psql -X -w -U postgres -d foodstore -v ON_ERROR_STOP=1 -P pager=off -f - \
  < unidades/unidad-7/postgresql/consultas_postgresql.sql'
```

Esta comparación se probó con copias en memoria de `datos/pedidos_origen.json`:

- Con metadatos de otro entorno y los mismos datos, los datos dieron iguales.
- Con un importe alterado, se detectó la diferencia.
- La comparación anterior de esta guía, que solo excluía `momento_utc`, daba
  diferencia en otro entorno aunque los datos fueran iguales.

### 5.3. MongoDB

Cada script corre en una sesión nueva autenticada como `u7_operador`:

```bash
U7_EXEC=(docker exec -e U7_OPERADOR_PASSWORD_FILE=/run/foodstore-u7-auth/u7_operador.pwd
         foodstore-u7-mongo9 mongosh --quiet --norc mongodb://127.0.0.1:27017)
E="$U7_PRIV/evidencias"
paso 0 "${U7_EXEC[@]}" /u7/mongodb/migracion_pedidos.js \
&& paso 0 huella "$E/validaciones_1.txt" "${U7_EXEC[@]}" /u7/mongodb/validaciones_mongodb.js \
&& paso 0 "${U7_EXEC[@]}" /u7/mongodb/consultas_mongodb.js \
&& paso 3 "${U7_EXEC[@]}" /u7/mongodb/migracion_pedidos.js \
&& paso 0 huella "$E/validaciones_2.txt" "${U7_EXEC[@]}" /u7/mongodb/validaciones_mongodb.js \
&& paso 0 diff <(grep "sha256 de los documentos" "$E/validaciones_1.txt") \
               <(grep "sha256 de los documentos" "$E/validaciones_2.txt") \
&& paso 1 docker exec foodstore-u7-mongo9 mongosh --quiet --norc mongodb://127.0.0.1:27017 \
     --eval 'db.getSiblingDB("foodstore_u7").pedidos.countDocuments({})' \
&& echo "Recorrido completo con los códigos esperados"
```

- **Códigos esperados:**
  - `migracion_pedidos.js`: 0 en la primera carga y **3** en la repetición
    (rechazo antes de escribir). Devuelve 2 si el archivo es inválido y 4 si
    falla `insertMany`.
  - `validaciones_mongodb.js`: 0, con 12 comprobaciones OK.
  - Lectura sin autenticación: 1 (`requires authentication`).
- **Laboratorio existente (§4.3) con el lote ya cargado:** la primera línea
  devuelve 3; se empieza por la validación.
- **Registro de esta corrida:** el 2026-11-06 los pasos se ejecutaron uno por
  uno con `echo "exit=$?"`, sin `paso`, y los códigos observados fueron los
  esperados (E1). Las funciones de §5.1 se agregaron después, como control
  reproducible.

Ajuste mecánico del 2026-11-06: en el comentario de uso de los tres `.js` se
cambió el nombre del contenedor de `foodstore-u7-mongo` a `foodstore-u7-mongo9`.
La lógica no cambió; las huellas posteriores al ajuste están en §7.

## 6. Resultados observados

**Comprobaciones previas:**
- **Archivo de extracción:** SHA-256 de `datos/pedidos_origen.json` =
  `930562ab8d97a1a8eb7a72e972d7b857dd61e73c5db9c86051676513196bec7a`, igual al
  registrado.
- **Origen PostgreSQL:** leído en solo lectura a las 15:46:58Z y a las 15:52:26Z;
  coincide con el archivo, excluido `momento_utc`.

**Autenticación**, antes de la carga y repetida con los datos cargados:

| Sesión | Lectura `foodstore_u7.pedidos.countDocuments({})` | Código |
|---|---|---|
| Autenticada como `u7_operador` | `0` antes de cargar | 0 |
| Sin autenticación | `MongoServerError: Command aggregate requires authentication` | 1 |

**Carga** (15:51:30Z):
`insertMany acknowledged=true insertados=5`, código 0.

**Validaciones**, código 0, 12 comprobaciones OK y 0 FALLO (una versión anterior
de esta guía decía 13 por error de conteo):

| Comprobación | Resultado |
|---|---|
| Conteos | 5 pedidos y 7 líneas |
| IDs de pedido, usuario, detalle y producto | 1–5, 1–3, 1–7 y 1–3 |
| Tipos con `$type` | `long`, `int`, `decimal`, `string` y `bool`, sin excepciones |
| Correspondencia con la extracción | Los 5 documentos coinciden en EJSON canónico |
| RI-01 y RI-02 | 0 documentos incoherentes |
| Precios del producto 1 | `1:1000.00 3:1050.00 5:1050.00` |
| Índices | Solo `_id_` |

**Consultas:**

| Consulta | Cantidad PostgreSQL | Cantidad MongoDB | Pedidos | Coinciden los IDs |
|---|---|---|---|---|
| C4b, estado `TERMINADO` | 5 | 5 | 1,2,3,4,5 | Sí |
| C4c, producto 1 | 3 | 3 | 1,3,5 | Sí |

En MongoDB, C4a devolvió 5 pedidos (1–5, todos `TERMINADO`) y C4d devolvió 2
pedidos: 3 (3150.00) y 4 (6200.00).

**Umbral de C4d:** `total > 3000.00` es un importe redondo apenas superior al
promedio del lote (2940.00). Ningún total es exactamente 3000.00.

**Repetición** (15:52:08Z):
- La segunda carga se rechazó antes de escribir:
  `RECHAZADO: ya existen los pedidos 1,2,3,4,5; no se inserta nada.`, código 3.
- Después, la colección siguió con 5 documentos y la huella de los documentos
  del lote no cambió: `7a2351dc7db148c5fa53e1524fefe8e261f7dd848a7ffdfb958ab443975033dc`.

## 7. Huellas de los archivos

| Archivo | SHA-256 al iniciar | SHA-256 al finalizar |
|---|---|---|
| `datos/pedidos_origen.json` | `930562ab…bec7a` | Igual |
| `postgresql/extraccion_pedidos.sql` | `e06667ab…536f8` | Igual |
| `postgresql/consultas_postgresql.sql` | `cd8b6af3…81771` | Igual |
| `mongodb/migracion_pedidos.js` | `951436f4…b9656` | `36af25b4…1785` (ajuste mecánico) |
| `mongodb/validaciones_mongodb.js` | `231886c2…832c3` | `b2d2f960…f92a` (ajuste mecánico) |
| `mongodb/consultas_mongodb.js` | `b611fe6e…194a` | `b9544831…d734` (ajuste mecánico) |

Los tres `.js` no cambiaron entre el ajuste, hecho antes de ejecutarlos, y el
final.

## 8. Limitaciones

- El lote tiene un solo estado (`TERMINADO`): C4b devuelve el lote completo.
- No hay bajas lógicas en el lote: los filtros sobre `eliminado` se aplican,
  pero estos datos no los ponen a prueba.
- Las validaciones comprueban esta carga; no hay validador `$jsonSchema` ni
  restricciones permanentes en el servidor.
- `insertMany` no es atómico para el lote; el caso de fallo parcial no se probó.
- Durante su inicialización, la imagen oficial pasa la contraseña de la cuenta
  raíz a un `mongosh` interno del contenedor. Ese comportamiento es propio del
  mecanismo de la imagen y no se modificó.
