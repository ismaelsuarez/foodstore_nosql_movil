#!/usr/bin/env bash
# =============================================================================
# Food Store — Unidad 8 — Ejecución y verificación del bloque B
#
# Crea una base SQLite DESCARTABLE en un directorio temporal nuevo, fuera del
# repositorio, ejecuta schema_sqlite.sql y pruebas_sqlite.sql con sqlite3 y
# comprueba salidas y códigos de salida. Todo el SQL está en esos dos
# archivos; este auxiliar no ejecuta SQL propio. Nunca abre foodstore_movil.db.
#
# Uso:
#   bash unidades/unidad-8/movil/verificar_bloque_b.sh [REGISTRO]
#
#   REGISTRO  archivo de evidencia nuevo. Antes de ejecutar las pruebas se
#             comprueba que no exista y que su directorio exista y admita
#             escritura. La salida se captura en un temporal del mismo
#             directorio y se publica con `ln`, que no reemplaza un archivo
#             existente.
#
# Códigos de salida: 0 todas las comprobaciones OK (y registro guardado, si
# se pidió); 1 alguna comprobación falló; 2 error de uso o de entorno,
# incluido el fallo al guardar el registro.
# =============================================================================
set -uo pipefail

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SCHEMA="$DIR/schema_sqlite.sql"
PRUEBAS="$DIR/pruebas_sqlite.sql"

seccion() { printf '\n=== %s ===\n' "$1"; }

mostrar() {  # mostrar <título> <archivo>
    printf -- '--- %s (%s líneas) ---\n' "$1" "$(wc -l < "$2")"
    cat "$2"
    printf -- '--- fin %s ---\n' "$1"
}

linea_de() {  # número de línea de la única sentencia marcada en pruebas_sqlite.sql
    local lineas
    lineas=$(grep -n -- "^INSERT .*; -- $1\$" "$PRUEBAS" | cut -d: -f1)
    if [[ $(printf '%s\n' "$lineas" | grep -c .) -ne 1 ]]; then
        echo "La marca $1 debe aparecer exactamente una vez en $PRUEBAS" >&2
        return 1
    fi
    printf '%s\n' "$lineas"
}

principal() {
    local fallos=0

    command -v sqlite3 > /dev/null || { echo 'sqlite3 no está disponible' >&2; return 2; }
    [[ -f $SCHEMA && -f $PRUEBAS ]] || { echo 'Faltan los scripts SQL del bloque B' >&2; return 2; }

    local tmp db
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/foodstore_u8_bloque_b.XXXXXX") || return 2
    db="$tmp/prueba_bloque_b_descartable.db"

    seccion 'Entorno'
    echo "Fecha:          $(date '+%Y-%m-%dT%H:%M:%S%z')"
    echo "Bash:           $BASH_VERSION"
    echo "sqlite3:        $(command -v sqlite3)"
    echo "Versión:        $(sqlite3 --version)"
    echo "Base temporal:  $db (descartable; no se borra al terminar)"
    echo 'Huellas SHA-256 de los scripts:'
    (cd "$DIR" && sha256sum schema_sqlite.sql pruebas_sqlite.sql verificar_bloque_b.sh)

    # --- Esquema -------------------------------------------------------------
    seccion 'Paso 1: esquema'
    echo "Comando: sqlite3 -batch \"$db\" < schema_sqlite.sql"
    sqlite3 -batch "$db" < "$SCHEMA" > "$tmp/schema.out" 2> "$tmp/schema.err"
    local rc_schema=$?
    echo "Código de salida: $rc_schema (esperado 0)"
    mostrar 'stdout esquema' "$tmp/schema.out"
    mostrar 'stderr esquema' "$tmp/schema.err"
    local v_schema=OK
    if [[ $rc_schema -ne 0 || -s $tmp/schema.err ]]; then v_schema=FALLA; fallos=1; fi

    # --- Pruebas -------------------------------------------------------------
    seccion 'Paso 2: pruebas'
    echo "Comando: sqlite3 -batch \"$db\" < pruebas_sqlite.sql"
    sqlite3 -batch "$db" < "$PRUEBAS" > "$tmp/pruebas.out" 2> "$tmp/pruebas.err"
    local rc_pruebas=$?
    echo "Código de salida: $rc_pruebas (esperado 1: dos errores de restricción provocados)"
    mostrar 'stdout pruebas' "$tmp/pruebas.out"
    mostrar 'stderr pruebas' "$tmp/pruebas.err"

    # --- Verificación --------------------------------------------------------
    seccion 'Paso 3: verificación'
    local linea_a linea_b
    linea_a=$(linea_de C7A_SENTENCIA_INVALIDA) || return 2
    linea_b=$(linea_de C7B_SENTENCIA_INVALIDA) || return 2

    # Diagnósticos esperados del cliente, en orden y sin ningún otro error.
    local err_a="Error near line $linea_a: CHECK constraint failed: cantidad > 0"
    local err_b="Error near line $linea_b: FOREIGN KEY constraint failed"
    printf '%s\n%s\n' "$err_a" "$err_b" > "$tmp/pruebas.err.esperado"
    echo 'stderr esperado:'
    sed 's/^/  /' "$tmp/pruebas.err.esperado"
    local v_stderr=OK
    if ! diff -u "$tmp/pruebas.err.esperado" "$tmp/pruebas.err"; then v_stderr=FALLA; fallos=1; fi

    local v_rc=OK
    if [[ $rc_pruebas -ne 1 ]]; then v_rc=FALLA; fallos=1; fi

    # Cada iif( del SQL es una comprobación: todas deben imprimir OK.
    local esperadas ok falla
    esperadas=$(grep -c 'iif(' "$PRUEBAS")
    ok=$(grep -c ' | OK$' "$tmp/pruebas.out")
    falla=$(grep -c ' | FALLA$' "$tmp/pruebas.out")
    echo "Comprobaciones SQL: esperadas=$esperadas OK=$ok FALLA=$falla"
    local v_sql=OK
    if [[ $ok -ne $esperadas || $falla -ne 0 ]]; then v_sql=FALLA; fallos=1; fi

    # Veredicto de un grupo: todas sus comprobaciones SQL impresas y en OK.
    grupo() {  # grupo <prefijo> <cantidad esperada>
        local n_ok n_total
        n_total=$(grep -c "^$1-" "$tmp/pruebas.out")
        n_ok=$(grep -c "^$1-.* | OK$" "$tmp/pruebas.out")
        if [[ $n_total -eq $2 && $n_ok -eq $2 ]]; then echo OK; else echo FALLA; fi
    }
    con_error() {  # con_error <veredicto del grupo> <diagnóstico esperado>
        if [[ $1 == OK ]] && grep -qxF -- "$2" "$tmp/pruebas.err"; then echo OK; else echo FALLA; fi
    }

    local v_commit v_rollback v_c1 v_c7a v_c7b
    v_commit=$(grupo COMMIT 4)
    v_rollback=$(grupo ROLLBACK 4)
    v_c1=$(grupo C1 4)
    v_c7a=$(con_error "$(grupo C7A 6)" "$err_a")
    v_c7b=$(con_error "$(grupo C7B 7)" "$err_b")

    seccion 'Resumen'
    printf '%-10s | %-62s | %s\n' 'Prueba' 'Esperado' 'Resultado'
    printf '%-10s | %-62s | %s\n' 'Esquema' 'código 0, sin errores' "$v_schema"
    printf '%-10s | %-62s | %s\n' 'COMMIT' '1 encabezado, 2 ítems, 1 PENDIENTE con motivo NULL' "$v_commit"
    printf '%-10s | %-62s | %s\n' 'ROLLBACK' '3 filas antes, 0 en las tres tablas después' "$v_rollback"
    printf '%-10s | %-62s | %s\n' 'C1' 'vista con 9101 y 9102; lápida 9104 conservada' "$v_c1"
    printf '%-10s | %-62s | %s\n' 'C7-a' "CHECK cantidad > 0 en línea $linea_a; 0 filas tras ROLLBACK" "$v_c7a"
    printf '%-10s | %-62s | %s\n' 'C7-b' "FOREIGN KEY en línea $linea_b; 0 filas tras ROLLBACK" "$v_c7b"
    printf '%-10s | %-62s | %s\n' 'stderr' 'exactamente los dos diagnósticos esperados' "$v_stderr"
    printf '%-10s | %-62s | %s\n' 'Código' "salida de pruebas = 1 (observado $rc_pruebas)" "$v_rc"
    printf '%-10s | %-62s | %s\n' 'SQL' "$esperadas comprobaciones en OK (observado $ok OK, $falla FALLA)" "$v_sql"

    for v in "$v_commit" "$v_rollback" "$v_c1" "$v_c7a" "$v_c7b"; do
        [[ $v == OK ]] || fallos=1
    done

    echo
    if [[ $fallos -eq 0 ]]; then
        echo 'RESULTADO GLOBAL: OK'
    else
        echo 'RESULTADO GLOBAL: FALLA'
    fi
    echo "Base temporal conservada: $db"
    return "$fallos"
}

if [[ $# -gt 1 ]]; then
    echo "Uso: bash $0 [REGISTRO]" >&2
    exit 2
fi

if [[ $# -eq 1 ]]; then
    registro=$1
    padre=$(dirname -- "$registro")
    if [[ -e $registro || -L $registro ]]; then
        echo "El registro ya existe y no se sobrescribe: $registro" >&2
        exit 2
    fi
    if [[ ! -d $padre || ! -w $padre ]]; then
        echo "El directorio del registro no existe o no admite escritura: $padre" >&2
        exit 2
    fi
    captura=$(mktemp "$padre/.captura_bloque_b.XXXXXX") || {
        echo "No se pudo crear la captura temporal en: $padre" >&2
        exit 2
    }
    trap 'rm -f -- "$captura"' EXIT

    principal 2>&1 | tee -- "$captura"
    estados=("${PIPESTATUS[@]}")
    rc_pruebas=${estados[0]}
    rc_tee=${estados[1]}

    if [[ $rc_tee -ne 0 ]]; then
        echo "Fallo al capturar el registro (tee terminó con código $rc_tee);" \
             "no se guardó: $registro" >&2
        exit 2
    fi
    # ln falla si el destino apareció entretanto: nunca reemplaza un registro.
    if ! ln -- "$captura" "$registro" || ! cmp -s -- "$captura" "$registro"; then
        echo "No se pudo publicar el registro sin sobrescribir: $registro" >&2
        exit 2
    fi
    echo "Registro guardado en: $registro"
    exit "$rc_pruebas"
fi

principal
