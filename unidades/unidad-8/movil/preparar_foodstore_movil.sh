#!/usr/bin/env bash
# Food Store — Unidad 8 — Crear esquema nuevo o renovar snapshot + catálogo.
# Uso: bash preparar_foodstore_movil.sh crear <db_nuevo>
#      bash preparar_foodstore_movil.sh renovar <db> <servidor_snapshot.csv> <meta>
# 0: operación comprobada; 1: ejecución fallida; 2: uso/entorno inválido.
# Nunca ejecuta pruebas_sqlite.sql ni modifica el CSV o sus metadatos.
set -uo pipefail
export LC_ALL=C
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit 2
temporales=()
tmpdb=''
limpiar() {
    # Solo archivos creados por esta ejecución; nunca la base destino.
    local archivo
    for archivo in "${temporales[@]}"; do rm -f -- "$archivo"; done
    if [[ -n $tmpdb ]]; then rm -f -- "$tmpdb-journal"; fi
}
trap limpiar EXIT
trap 'exit 2' HUP INT TERM
error_entorno() { printf 'Error de uso/entorno: %s\n' "$*" >&2; exit 2; }
mostrar() {
    printf -- '--- %s ---\n' "$1"
    cat -- "$2"
    printf -- '--- fin %s ---\n' "$1"
}
capturas() {
    salida=$(mktemp "$1/.foodstore_stdout.XXXXXX") || error_entorno 'No se pudo crear stdout temporal'
    temporales+=("$salida")
    errores=$(mktemp "$1/.foodstore_stderr.XXXXXX") || error_entorno 'No se pudo crear stderr temporal'
    temporales+=("$errores")
}
comprobar_esquema() {
    local sql=$1 rc
    sqlite3 -batch "$tmpdb" < "$sql" > "$salida" 2> "$errores"
    rc=$?
    printf '%s: código esperado=0 observado=%s\n' "${sql##*/}" "$rc"
    mostrar stdout "$salida" && mostrar stderr "$errores" || error_entorno 'No se pudieron mostrar las capturas'
    if [[ $rc -eq 0 && ! -s $errores ]]; then
        echo 'Resultado esquema: OK'
    else
        echo 'Resultado esquema: FALLA (no se publica la base)' >&2
        exit 1
    fi
}

[[ $# -ge 1 ]] || error_entorno 'Uso: crear <db_nuevo> | renovar <db> <csv> <meta>'
case $1 in
    crear)
        [[ $# -eq 2 ]] || error_entorno 'Uso: crear <db_nuevo>'
        db=$2
        padre=$(dirname -- "$db")
        # Antes de crear temporales o ejecutar sqlite3: no sobrescribir ni
        # seguir enlaces, incluso si el enlace apunta a un destino inexistente.
        [[ ! -e $db && ! -L $db ]] || error_entorno "El destino ya existe: $db"
        [[ -d $padre && -w $padre && -x $padre ]] || error_entorno "Directorio inexistente o no escribible: $padre"
        for herramienta in sqlite3 mktemp ln basename dirname cat rm; do
            command -v "$herramienta" > /dev/null || error_entorno "Falta $herramienta"
        done
        [[ -r $DIR/schema_sqlite.sql && -r $DIR/snapshot_servidor.sql ]] || error_entorno 'Faltan los scripts de esquema'
        padre=$(cd "$padre" && pwd -P) || error_entorno 'No se pudo resolver el directorio destino'
        db="$padre/$(basename -- "$db")"
        tmpdb=$(mktemp "$padre/.foodstore_base.XXXXXX") || error_entorno 'No se pudo crear la base temporal'
        temporales+=("$tmpdb")
        capturas "$padre"
        comprobar_esquema "$DIR/schema_sqlite.sql"
        comprobar_esquema "$DIR/snapshot_servidor.sql"
        # Enlace duro en el mismo sistema de archivos: publicación atómica,
        # sin reemplazar un destino que pudiera haber aparecido entretanto.
        ln -T -- "$tmpdb" "$db" || error_entorno "No se pudo publicar sin sobrescribir: $db"
        printf 'BASE NUEVA PUBLICADA: %s\n' "$db"
        ;;
    renovar)
        [[ $# -eq 4 ]] || error_entorno 'Uso: renovar <db> <csv> <meta>'
        for herramienta in sqlite3 mktemp sha256sum realpath dirname tail cat rm; do
            command -v "$herramienta" > /dev/null || error_entorno "Falta $herramienta"
        done
        [[ -f $2 && -r $2 && -w $2 ]] || error_entorno "La base debe existir y admitir lectura/escritura: $2"
        [[ -f $3 && -r $3 && ${3##*/} == servidor_snapshot.csv ]] || error_entorno 'El CSV debe existir y llamarse servidor_snapshot.csv'
        [[ -f $4 && -r $4 && -r $DIR/renovar_snapshot.sql ]] || error_entorno 'Faltan metadatos o renovar_snapshot.sql'
        db_abs=$(realpath -e -- "$2") || error_entorno 'No se pudo resolver la base'
        csv_abs=$(realpath -e -- "$3") || error_entorno 'No se pudo resolver el CSV'
        # Resolver el directorio, no el nombre de un posible enlace del CSV:
        # .import siempre busca el nombre contractual servidor_snapshot.csv.
        csv_dir=$(cd "$(dirname -- "$3")" && pwd -P) || error_entorno 'No se pudo resolver el directorio CSV'
        db_dir=$(dirname -- "$db_abs")
        [[ -w $db_dir && -x $db_dir ]] || error_entorno 'El directorio de la base no admite el journal'
        declare -A metadatos=()
        while IFS= read -r linea || [[ -n $linea ]]; do
            [[ $linea =~ ^([a-z][a-z0-9_]*)=(.*)$ ]] || error_entorno 'Metadatos inválidos: se requiere clave=valor sin espacios en la clave'
            clave=${BASH_REMATCH[1]}
            valor=${BASH_REMATCH[2]}
            [[ ! -v metadatos[$clave] ]] || error_entorno "Clave duplicada en metadatos: $clave"
            metadatos[$clave]=$valor
        done < "$4"
        filas=${metadatos[filas]-}
        sha=${metadatos[sha256_csv]-}
        [[ $filas =~ ^[1-9][0-9]*$ ]] || error_entorno 'filas debe ser un entero positivo'
        # Comparación léxica intencional para 19 dígitos: evita desbordar Bash.
        # shellcheck disable=SC2071
        [[ ${#filas} -lt 19 || ( ${#filas} -eq 19 && ! $filas > 9223372036854775807 ) ]] || error_entorno 'filas excede INTEGER de SQLite'
        [[ $sha =~ ^[[:xdigit:]]{64}$ ]] || error_entorno 'sha256_csv debe contener 64 dígitos hexadecimales'
        calculado=$(sha256sum < "$csv_abs") || error_entorno 'No se pudo calcular SHA-256 del CSV'
        calculado=${calculado%% *}
        [[ $calculado == "${sha,,}" ]] || error_entorno 'SHA-256 del CSV distinto de los metadatos'
        # .import ignora con una advertencia las columnas sobrantes y seguiría
        # hasta el COMMIT: la estructura del contrato se comprueba antes de abrir
        # la base. Los valores y la cantidad de filas los valida
        # renovar_snapshot.sql dentro de la transacción.
        awk -F, '
            NR == 1 { if ($0 != "producto_id,nombre,precio_centavos,stock,disponible,eliminado,capturado_en") mal = "encabezado"; next }
            NF != 7 || index($0, "\"") { mal = "línea " NR ": se esperaban 7 campos sin comillas"; exit }
            END { if (NR == 0) mal = "archivo vacío"
                  if (mal != "") { print "CSV fuera de contrato: " mal > "/dev/stderr"; exit 1 } }
        ' "$csv_abs" || { echo 'FALLA: CSV fuera de contrato; no se abre la base.' >&2; exit 1; }
        capturas "$db_dir"
        (cd "$csv_dir" && sqlite3 -batch -cmd ".parameter set @filas_esperadas $filas" "$db_abs" < "$DIR/renovar_snapshot.sql") > "$salida" 2> "$errores"
        rc=$?
        printf 'Renovación: código esperado=0 observado=%s\n' "$rc"
        mostrar stdout "$salida" && mostrar stderr "$errores" || error_entorno 'No se pudieron mostrar las capturas'
        ultima=$(tail -n 1 -- "$salida")
        if [[ $rc -eq 0 && ! -s $errores && $ultima == 'RENOVACION CONFIRMADA' ]]; then
            echo 'Resultado renovación: OK'
        else
            if [[ $ultima == 'RENOVACION CONFIRMADA' ]]; then
                # No afirmar un rollback si el COMMIT fue alcanzado pero hubo
                # un diagnóstico (por ejemplo, una advertencia de .import).
                echo 'FALLA: hay diagnósticos o salida anómala; se alcanzó COMMIT, no afirmar reversión.' >&2
            else
                echo 'FALLA: renovación interrumpida; la transacción abierta se revierte al cerrar, catálogo no cargado.' >&2
            fi
            exit 1
        fi
        ;;
    *) error_entorno 'Uso: crear <db_nuevo> | renovar <db> <csv> <meta>' ;;
esac
