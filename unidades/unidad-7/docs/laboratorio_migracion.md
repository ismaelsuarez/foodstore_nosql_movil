# Laboratorio de migración — Unidad 7

**Estado al 2026-11-06:** extracción, carga, validaciones, consultas en ambos
motores y prueba de repetición **ejecutadas** con MongoDB 9.0.4. El contraste
de IA está en [contraste_ia.md](contraste_ia.md). La
[conclusión](conclusion_u7.md) es una propuesta pendiente de revisión del
equipo. El informe y la publicación siguen pendientes.

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

Las credenciales se guardan en un directorio privado fuera del repositorio,
elegido por el operador. Este laboratorio usó `~/.local/share/foodstore-u7-mongo9`.
Ninguna contraseña aparece en comandos ni en archivos versionados.

```bash
U7_PRIV="$HOME/.local/share/foodstore-u7-mongo9"; U7_AUTH="$U7_PRIV/auth"
IMG9="mongo@sha256:452bdaf2127b8ff851e31410a267809b9829eded219979f2210e7c7efb85a058"
docker pull mongo:9.0.4   # comprobar que el digest coincide con IMG9
umask 077; mkdir -p "$U7_AUTH" "$U7_PRIV/evidencias"
openssl rand -hex 24 > "$U7_AUTH/u7_admin.pwd"
openssl rand -hex 24 > "$U7_AUTH/u7_operador.pwd"
# El entrypoint lee MONGO_INITDB_ROOT_PASSWORD_FILE después de bajar a
# mongodb (uid 999). Una ACL da lectura solo a ese uid y solo sobre ese archivo.
setfacl -m u:999:x "$U7_AUTH"
setfacl -m u:999:r "$U7_AUTH/u7_admin.pwd"
docker volume create foodstore_u7_mongo9_data
docker create --name foodstore-u7-mongo9 --pull never --network none --restart no \
  -v foodstore_u7_mongo9_data:/data/db --tmpfs /data/configdb \
  -v "$U7_AUTH":/run/foodstore-u7-auth:ro \
  -v "$PWD/unidades/unidad-7":/u7:ro \
  -e MONGO_INITDB_ROOT_USERNAME=u7_admin \
  -e MONGO_INITDB_ROOT_PASSWORD_FILE=/run/foodstore-u7-auth/u7_admin.pwd \
  "$IMG9"
docker start foodstore-u7-mongo9
```

- **Usuario raíz.** El mecanismo de archivo de la imagen crea `u7_admin` con rol
  `root` y reinicia `mongod` con `--auth`.
- **Espera.** Antes de continuar, comprobar dos cosas, como se hizo en este
  laboratorio:

  ```bash
  docker logs foodstore-u7-mongo9 2>&1 | grep -n "MongoDB init process complete"
  docker exec foodstore-u7-mongo9 mongosh --quiet --norc --eval "db.runCommand({ping:1}).ok"  # 1
  ```

  El 2026-11-06 un bucle automático de espera informó «no listo» aunque el
  servidor ya estaba disponible. Con `set -o pipefail`, `grep -q` cierra la
  tubería antes de que `docker logs` termine; `docker logs` recibe SIGPIPE y la
  condición resulta falsa. Ese bucle no es un procedimiento validado.
- **Comprobaciones del contenedor.** Red `none`, sin puertos, sin privilegios
  ni socket de Docker, y montajes de solo lectura para scripts, datos y
  credenciales.

Crear `u7_operador` desde la sesión administrativa:

```bash
docker exec foodstore-u7-mongo9 mongosh --quiet --norc mongodb://127.0.0.1:27017/admin --eval '
  const fs = require("fs");
  const leer = (f) => fs.readFileSync("/run/foodstore-u7-auth/" + f, "utf8").trim();
  db.getSiblingDB("admin").auth("u7_admin", leer("u7_admin.pwd"));
  db.getSiblingDB("foodstore_u7").createUser({ user: "u7_operador", pwd: leer("u7_operador.pwd"),
    roles: [{ role: "readWrite", db: "foodstore_u7" }] });'
docker exec foodstore-u7-mongo9 mongod --version
docker exec foodstore-u7-mongo9 mongosh --version
```

## 5. Ejecución

Origen PostgreSQL (con `foodstore-u6-evaluacion` en ejecución). La extracción
versionada ya existe. Para comprobar que el origen no cambió, se extrae a un
archivo fuera del repositorio y se compara sin el momento de extracción:

```bash
docker exec -i foodstore-u6-evaluacion \
  psql -X -w -q -A -t -U postgres -d foodstore -v ON_ERROR_STOP=1 -f - \
  < unidades/unidad-7/postgresql/extraccion_pedidos.sql > "$U7_PRIV/evidencias/control.json"
diff <(jq -S 'del(.extraccion.momento_utc)' unidades/unidad-7/datos/pedidos_origen.json) \
     <(jq -S 'del(.extraccion.momento_utc)' "$U7_PRIV/evidencias/control.json")

docker exec -i foodstore-u6-evaluacion \
  psql -X -w -U postgres -d foodstore -v ON_ERROR_STOP=1 -P pager=off -f - \
  < unidades/unidad-7/postgresql/consultas_postgresql.sql
```

MongoDB, cada script en una sesión nueva autenticada como `u7_operador`:

```bash
U7_EXEC=(docker exec -e U7_OPERADOR_PASSWORD_FILE=/run/foodstore-u7-auth/u7_operador.pwd
         foodstore-u7-mongo9 mongosh --quiet --norc mongodb://127.0.0.1:27017)
"${U7_EXEC[@]}" /u7/mongodb/migracion_pedidos.js;    echo "exit=$?"   # 0
"${U7_EXEC[@]}" /u7/mongodb/validaciones_mongodb.js; echo "exit=$?"   # 0
"${U7_EXEC[@]}" /u7/mongodb/consultas_mongodb.js;    echo "exit=$?"   # 0
"${U7_EXEC[@]}" /u7/mongodb/migracion_pedidos.js;    echo "exit=$?"   # repetición: 3
"${U7_EXEC[@]}" /u7/mongodb/validaciones_mongodb.js; echo "exit=$?"   # misma huella
# Misma lectura sin autenticación: debe rechazarse.
docker exec foodstore-u7-mongo9 mongosh --quiet --norc mongodb://127.0.0.1:27017 \
  --eval 'db.getSiblingDB("foodstore_u7").pedidos.countDocuments({})'
```

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

**Validaciones**, código 0, 13 comprobaciones:

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
