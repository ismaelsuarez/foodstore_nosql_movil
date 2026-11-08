#!/usr/bin/env bash
# =============================================================================
# Food Store — Unidad 8 — Laboratorio PostgreSQL aislado e instantánea inicial.
# Uso: bash laboratorio_u8.sh crear | instalar | exportar CSV_NUEVO META_NUEVO
# Salidas: 0 OK; 1 comprobación/ejecución fallida; 2 uso o entorno incorrecto.
# No crea credenciales, no publica puertos ni toca otros contenedores/volúmenes.
# Nunca elimina recursos Docker ni destinos publicados, incluso ante un fallo.
# =============================================================================
set -uo pipefail

DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 2
RAIZ=$(cd -- "$DIR/../../.." && pwd) || exit 2
ORIGEN="$RAIZ/../foodstore_baseII"
COMMIT=8f7877c8a1ff25c1be28b29c46c38cd7c9663e86
IMAGEN=sha256:2d2b8998d31037bf721cfdf764d76ba74171b4fab3431b7f72c27c56ddbdf9e3
CONTENEDOR=foodstore-u8-postgres
VOLUMEN=foodstore_u8_pg_data
BASE=foodstore_u8
CREDENCIAL="${HOME-}/.local/share/foodstore_u8_lab/pg_superusuario"
ARCHIVOS=(schema.sql datos_iniciales.sql tpi/sql/objetos_programables.sql)
BLOBS=()
TEMPORALES=()

entorno() { printf 'ERROR de uso/entorno: %s\n' "$*" >&2; return 2; }
fallo() { printf 'FALLA: %s\n' "$*" >&2; return 1; }
docker_u8() { docker --context default "$@"; }
psql_u8() {
    docker_u8 exec -i "$CONTENEDOR" psql -X -v ON_ERROR_STOP=1 \
        -U postgres -d "$BASE" "$@"
}
requerir() {
    local herramienta
    for herramienta in "$@"; do
        command -v "$herramienta" >/dev/null || {
            entorno "Falta la herramienta $herramienta"; return 2;
        }
    done
}

# Se consulta solo el recurso U8 y únicamente campos seleccionados, nunca Env.
comprobar_contenedor() {
    local identidad
    identidad=$(docker_u8 inspect --type container --format \
        '{{.Image}}|{{.HostConfig.NetworkMode}}|{{index .Config.Labels "proyecto"}}|{{.State.Status}}' \
        "$CONTENEDOR") || { entorno 'No se pudo inspeccionar el contenedor U8'; return 2; }
    [[ $identidad == "$IMAGEN|none|foodstore-u8|running" ]] || {
        entorno 'El contenedor U8 no está ejecutándose con la imagen, red y etiqueta esperadas'; return 2;
    }
}

procedencia() {
    local revision archivo blob
    requerir git || return $?
    revision=$(git -C "$ORIGEN" rev-parse --verify 'u6-cierre^{commit}') || return 2
    [[ $revision == "$COMMIT" ]] || { entorno 'u6-cierre no apunta al commit autorizado'; return 2; }
    BLOBS=()
    for archivo in "${ARCHIVOS[@]}"; do
        blob=$(git -C "$ORIGEN" rev-parse --verify "u6-cierre:$archivo") || return 2
        BLOBS+=("$blob")
    done
}

crear() {
    [[ -n ${HOME-} ]] || { entorno 'HOME no está definido'; return 2; }
    requerir docker sleep || return $?
    local contenedores volumenes nombre id logs inicio listo=0 rc
    local -a comando
    # Listar nombres no conecta, inicia ni inspecciona los otros recursos.
    contenedores=$(docker_u8 container ls -a --filter "name=^${CONTENEDOR}$" --format '{{.Names}}') || return 2
    volumenes=$(docker_u8 volume ls --filter "name=^${VOLUMEN}$" --format '{{.Name}}') || return 2
    [[ -z $contenedores ]] || { entorno "Ya existe $CONTENEDOR; no se reutiliza"; return 2; }
    while IFS= read -r nombre; do
        [[ $nombre != "$VOLUMEN" ]] || { entorno "Ya existe $VOLUMEN; no se reutiliza"; return 2; }
    done <<< "$volumenes"
    [[ -f $CREDENCIAL ]] || { entorno "Falta la credencial privada: $CREDENCIAL"; return 2; }
    # Nunca se lee el contenido de la credencial ni se pasa como argumento.
    id=$(docker_u8 image inspect --format '{{.Id}}' "$IMAGEN") || return 2
    [[ $id == "$IMAGEN" ]] || { entorno 'La imagen local no coincide'; return 2; }

    printf 'Comando: docker volume create --label proyecto=foodstore-u8 %s\n' "$VOLUMEN"
    docker_u8 volume create --label proyecto=foodstore-u8 "$VOLUMEN"
    rc=$?; printf 'Código de salida (crear volumen): %s\n' "$rc"
    [[ $rc -eq 0 ]] || return 1
    # --pull=never garantiza que una carrera con la caché no descargue imágenes.
    comando=(run -d --pull=never --name "$CONTENEDOR" --network none
        --security-opt no-new-privileges:true --label proyecto=foodstore-u8
        -v "$VOLUMEN:/var/lib/postgresql/data"
        -v "$CREDENCIAL:/run/secrets/pg_superusuario:ro"
        -e POSTGRES_PASSWORD_FILE=/run/secrets/pg_superusuario
        -e POSTGRES_DB="$BASE" "$IMAGEN")
    printf 'Comando: docker --context default'
    printf ' %q' "${comando[@]}"
    printf '\n'
    docker_u8 "${comando[@]}"
    rc=$?; printf 'Código de salida (crear contenedor): %s\n' "$rc"
    [[ $rc -eq 0 ]] || return 1

    inicio=$SECONDS
    while (( SECONDS - inicio < 120 )); do
        logs=$(docker_u8 logs "$CONTENEDOR" 2>&1) || {
            entorno 'No se pudieron consultar los logs de U8'; return 2;
        }
        if [[ $logs == *'PostgreSQL init process complete; ready for start up.'* ]] &&
           docker_u8 exec "$CONTENEDOR" pg_isready -U postgres -d "$BASE" >/dev/null 2>&1; then
            listo=1
            break
        fi
        sleep 2 || return 2
    done
    [[ $listo -eq 1 ]] || { fallo 'Tiempo agotado esperando fin del init y pg_isready'; return 1; }
    comprobar_contenedor || return $?
    psql_u8 -c 'SHOW server_version;' || return 1
    docker_u8 exec "$CONTENEDOR" postgres --version || return 1
    docker_u8 image inspect --format 'Imagen={{.Id}} RepoDigests={{json .RepoDigests}}' "$IMAGEN" || return 2
    docker_u8 inspect --type container --format \
        'Config.Image={{.Config.Image}}
Image={{.Image}}
NetworkMode={{.HostConfig.NetworkMode}}
PortBindings={{json .HostConfig.PortBindings}}
Privileged={{.HostConfig.Privileged}}
SecurityOpt={{json .HostConfig.SecurityOpt}}
CapAdd={{json .HostConfig.CapAdd}}
{{range .Mounts}}Mount Type={{.Type}} Source={{.Source}} Destination={{.Destination}} RW={{.RW}}
{{end}}State.Status={{.State.Status}}' "$CONTENEDOR" || return 2
}

instalar() {
    requerir docker git sha256sum || return $?
    local tablas i archivo huella rc
    local -a opciones estados
    comprobar_contenedor || return $?
    procedencia || return $?
    for archivo in datos_auxiliares_u8.sql snapshot_movil.sql verificar_instalacion_u8.sql; do
        [[ -f $DIR/$archivo && -r $DIR/$archivo ]] || {
            entorno "Falta el SQL local $archivo"; return 2;
        }
    done
    tablas=$(psql_u8 -At -c "SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relkind IN ('r','p','f');")
    rc=$?; printf 'Código de salida (comprobar public vacío): %s\n' "$rc"
    [[ $rc -eq 0 ]] || return 1
    [[ $tablas == 0 ]] || { entorno 'public ya contiene tablas; no se instala ni se reintenta sobre ellas'; return 2; }

    for i in "${!ARCHIVOS[@]}"; do
        archivo=${ARCHIVOS[$i]}
        printf '\nOrigen: foodstore_baseII u6-cierre %s\nArchivo: %s\nBlob: %s\n' "$COMMIT" "$archivo" "${BLOBS[$i]}"
        huella=$(git -C "$ORIGEN" show "u6-cierre:$archivo" | sha256sum)
        rc=$?; printf 'Código de salida (huella origen): %s\n' "$rc"
        [[ $rc -eq 0 ]] || return 1
        printf 'SHA-256: %s\n' "${huella%% *}"
        opciones=(--single-transaction)
        [[ $archivo != datos_iniciales.sql ]] || opciones=()
        printf 'Comando: git show u6-cierre:%s | docker exec -i %s psql -X -v ON_ERROR_STOP=1 -U postgres -d %s %s\n' \
            "$archivo" "$CONTENEDOR" "$BASE" "${opciones[*]}"
        git -C "$ORIGEN" show "u6-cierre:$archivo" | psql_u8 "${opciones[@]}"
        estados=("${PIPESTATUS[@]}")
        printf 'Códigos de salida: git show=%s psql=%s\n' "${estados[0]}" "${estados[1]}"
        [[ ${estados[0]} -eq 0 && ${estados[1]} -eq 0 ]] || return 1
    done
    for archivo in datos_auxiliares_u8.sql snapshot_movil.sql verificar_instalacion_u8.sql; do
        opciones=()
        [[ $archivo != snapshot_movil.sql ]] || opciones=(--single-transaction)
        printf '\nComando: docker exec -i %s psql -X -v ON_ERROR_STOP=1 -U postgres -d %s %s < %s\n' \
            "$CONTENEDOR" "$BASE" "${opciones[*]}" "$DIR/$archivo"
        psql_u8 "${opciones[@]}" < "$DIR/$archivo"
        rc=$?; printf 'Código de salida (%s): %s\n' "$archivo" "$rc"
        [[ $rc -eq 0 ]] || return 1
    done
}

# Solo se retiran temporales propios, jamás el CSV/META publicado ni recursos.
limpiar_temporales() {
    local rc=$?
    trap - EXIT
    if (( ${#TEMPORALES[@]} > 0 )); then
        if ! rm -f -- "${TEMPORALES[@]}"; then
            printf 'ERROR: no se pudieron retirar todos los temporales\n' >&2
            rc=2
        fi
    fi
    exit "$rc"
}

exportar() {
    local csv=$1 meta=$2 destino padre nombre csv_dir meta_dir
    local tmp_csv tmp_err tmp_meta rc linea clave valor huella lineas fecha
    local -A datos=()
    # Todo destino se comprueba ANTES de Docker, mktemp o lectura del origen.
    for destino in "$csv" "$meta"; do
        [[ -n $destino && $destino != */ ]] || { entorno 'Destino vacío o terminado en /'; return 2; }
        [[ ! -e $destino && ! -L $destino ]] || { entorno "El destino ya existe: $destino"; return 2; }
        padre=$(dirname -- "$destino") || return 2
        [[ -d $padre && -w $padre && -x $padre ]] || {
            entorno "Directorio inexistente o sin permiso de escritura/acceso: $padre"; return 2;
        }
    done
    csv_dir=$(cd -- "$(dirname -- "$csv")" && pwd -P) || return 2
    meta_dir=$(cd -- "$(dirname -- "$meta")" && pwd -P) || return 2
    nombre=$(basename -- "$csv") || return 2
    csv="$csv_dir/$nombre"
    nombre=$(basename -- "$meta") || return 2
    meta="$meta_dir/$nombre"
    [[ $csv != "$meta" ]] || { entorno 'CSV y META deben ser destinos distintos'; return 2; }
    requerir docker git mktemp awk sha256sum wc ln rm date || return $?
    [[ -r $DIR/exportar_snapshot.sql ]] || { entorno 'Falta exportar_snapshot.sql'; return 2; }
    comprobar_contenedor || return $?
    procedencia || return $?
    umask 077
    trap limpiar_temporales EXIT
    trap 'exit 2' HUP INT TERM
    tmp_csv=$(mktemp "$csv_dir/.snapshot_csv.XXXXXX") || return 2
    TEMPORALES+=("$tmp_csv")
    tmp_err=$(mktemp "$csv_dir/.snapshot_stderr.XXXXXX") || return 2
    TEMPORALES+=("$tmp_err")
    tmp_meta=$(mktemp "$meta_dir/.snapshot_meta.XXXXXX") || return 2
    TEMPORALES+=("$tmp_meta")

    printf 'Comando: docker exec -i %s psql -X -q -v ON_ERROR_STOP=1 -U postgres -d %s < %s\n' "$CONTENEDOR" "$BASE" "$DIR/exportar_snapshot.sql"
    psql_u8 -q < "$DIR/exportar_snapshot.sql" > "$tmp_csv" 2> "$tmp_err"
    rc=$?
    printf 'Código de salida (psql exportación): %s\n' "$rc"
    while IFS= read -r linea || [[ -n $linea ]]; do
        printf '%s\n' "$linea" >&2
    done < "$tmp_err"
    [[ $rc -eq 0 ]] || { fallo 'psql no terminó correctamente; no se publica'; return 1; }

    # Exactamente cinco META conocidos, únicos y no vacíos; ningún diagnóstico.
    while IFS= read -r linea || [[ -n $linea ]]; do
        if [[ $linea =~ ^META\ (filas|fechas|capturado_en|base|version_servidor)=(.*)$ ]]; then
            clave=${BASH_REMATCH[1]}; valor=${BASH_REMATCH[2]}
            if [[ -n ${datos[$clave]+presente} || -z $valor ]]; then
                fallo "META duplicado o vacío: $clave"; return 1
            fi
            datos[$clave]=$valor
        else
            fallo 'stderr contiene una línea ajena a META'; return 1
        fi
    done < "$tmp_err"
    for clave in filas fechas capturado_en base version_servidor; do
        [[ -n ${datos[$clave]+presente} ]] || { fallo "Falta META $clave"; return 1; }
    done
    [[ ${datos[filas]} =~ ^(0|[1-9][0-9]*)$ && ${datos[fechas]} == 1 && ${datos[base]} == "$BASE" ]] || {
        fallo 'META inválidos: filas, fechas (debe ser 1) o base'; return 1;
    }
    # Comparación decimal por longitud/texto: no pierde precisión con IDs BIGINT.
    awk -F, -v filas="${datos[filas]}" -v fecha="${datos[capturado_en]}" '
        function error(m) { print "FALLA CSV: " m > "/dev/stderr"; mal=1; exit 1 }
        function normalizar(x) { sub(/^0+/, "", x); return x == "" ? "0" : x }
        function mayor(a,b) {
            a=normalizar(a); b=normalizar(b)
            return length(a)>length(b) || (length(a)==length(b) && ("x" a)>("x" b))
        }
        NR==1 {
            if ($0 != "producto_id,nombre,precio_centavos,stock,disponible,eliminado,capturado_en")
                error("encabezado incorrecto o command tags en stdout")
            next
        }
        {
            if (NF!=7 || index($0, "\"") || $2=="") error("campos, comillas o nombre inválidos")
            if ($1 !~ /^[0-9]+$/ || $3 !~ /^[0-9]+$/ || $4 !~ /^[0-9]+$/)
                error("id, centavos o stock no enteros no negativos")
            if ($5 !~ /^[tf]$/ || $6 !~ /^[tf]$/) error("booleano distinto de t/f")
            if ($7 != fecha) error("capturado_en no coincide con META")
            if (NR>2 && !mayor($1, anterior)) error("producto_id no estrictamente creciente")
            anterior=$1
        }
        END { if (!mal && (NR==0 || NR-1!=filas)) error("conteo no coincide con META") }
    ' "$tmp_csv" || return 1
    lineas=$(wc -l < "$tmp_csv") || return 2
    [[ $lineas -eq $((${datos[filas]} + 1)) ]] || { fallo 'Número de líneas físicas incorrecto'; return 1; }
    huella=$(sha256sum < "$tmp_csv") || return 2
    huella=${huella%% *}
    fecha=$(date '+%Y-%m-%dT%H:%M:%S%z') || return 2
    {
        printf 'base=%s\nversion_servidor=%s\nimagen=%s\ncontenedor=%s\n' "${datos[base]}" "${datos[version_servidor]}" "$IMAGEN" "$CONTENEDOR" &&
        printf 'capturado_en=%s\nfilas=%s\nsha256_csv=%s\n' "${datos[capturado_en]}" "${datos[filas]}" "$huella" &&
        printf 'origen=foodstore_baseII u6-cierre %s\n' "$COMMIT" &&
        printf 'blob_schema_sql=%s\nblob_datos_iniciales_sql=%s\nblob_objetos_programables_sql=%s\n' "${BLOBS[0]}" "${BLOBS[1]}" "${BLOBS[2]}" &&
        printf 'generado_por=laboratorio_u8.sh exportar; Bash %s; %s\n' "$BASH_VERSION" "$fecha"
    } > "$tmp_meta" || { entorno 'No se pudo escribir META temporal'; return 2; }

    # -T impide que una carrera convierta el destino en un directorio receptor.
    # Dos nombres no pueden publicarse atómicamente como pareja: si falla el
    # segundo ln, se conserva el CSV y se informa el estado parcial, sin borrar.
    ln -T -- "$tmp_csv" "$csv" || { entorno 'No se pudo publicar CSV sin sobrescribir'; return 2; }
    ln -T -- "$tmp_meta" "$meta" || {
        entorno "CSV publicado en $csv, pero META no publicado en $meta; no reintentar sobre esos destinos"; return 2;
    }
    printf 'CSV publicado: %s\nMETA publicado: %s\nfilas=%s\ncapturado_en=%s\nsha256_csv=%s\nLíneas CSV (con encabezado): %s\n' \
        "$csv" "$meta" "${datos[filas]}" "${datos[capturado_en]}" "$huella" "$lineas"
}

case ${1-} in
    crear|instalar)
        [[ $# -eq 1 ]] || { entorno "Uso: bash $0 $1"; exit 2; }
        "$1"
        exit $?
        ;;
    exportar)
        [[ $# -eq 3 ]] || { entorno "Uso: bash $0 exportar CSV_NUEVO META_NUEVO"; exit 2; }
        exportar "$2" "$3"
        exit $?
        ;;
    *) entorno "Uso: bash $0 crear | instalar | exportar CSV_NUEVO META_NUEVO"; exit 2 ;;
esac
