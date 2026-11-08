#!/usr/bin/env bash
# =============================================================================
# Food Store — Unidad 8 — Coordinador de las operaciones del bloque D.
# Toda la lógica de datos está en los archivos SQL; este script solo elige el
# archivo, fija parámetros, captura salidas y comprueba códigos y marcas.
#
# Uso:
#   bash bloque_d.sh borrador    <db> <c2|c3|c4|c5|prioridad>
#   bash bloque_d.sh preparar    <c2|c3|c4>          (mutación en PostgreSQL)
#   bash bloque_d.sh instantanea <c2|c3|c4> <ejecucion> <db>
#   bash bloque_d.sh simular     <db>                (PostgreSQL antes/después)
#   bash bloque_d.sh aceptar     <db> <c2|c2_uuid_repetido>
#   bash bloque_d.sh reinsertar  <db> <c6_uuid|pendiente_doble>
#   bash bloque_d.sh ausente     <db_copia> <producto_id>   (solo copias)
#   bash bloque_d.sh estado      <db>
#   bash bloque_d.sh comprobar   <db> <caso> <solicitud> <producto_id> <precio_visto>
#                                <estado> <motivo|'<NULL>'> <lapida 0|1>
#
# Códigos: 0 operación comprobada; 1 falló una comprobación o la operación;
# 2 error de uso o de entorno.
# =============================================================================
set -uo pipefail
export LC_ALL=C

DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 2
REPO=$(cd -- "$DIR/../../.." && pwd -P) || exit 2
PG_DIR="$DIR/../postgresql"
CONTENEDOR=foodstore-u8-postgres
IMAGEN=sha256:2d2b8998d31037bf721cfdf764d76ba74171b4fab3431b7f72c27c56ddbdf9e3
BASE_PG=foodstore_u8

# -----------------------------------------------------------------------------
# Identificadores de prueba (design.md §6.1). Fijos y registrados en tasks.md.
# usuario_id_servidor 1: usuario del seed leído en PostgreSQL (vigente).
# -----------------------------------------------------------------------------
declare -A BORRADOR=(
    [c2]=d2000000-0000-4000-8000-0000000000b1
    [c3]=d3000000-0000-4000-8000-0000000000b1
    [c4]=d4000000-0000-4000-8000-0000000000b1
    [c5]=d5000000-0000-4000-8000-0000000000b1
    [prioridad]=d9000000-0000-4000-8000-0000000000b1
)
declare -A SOLICITUD=(
    [c2]=d2000000-0000-4000-8000-0000000000c1
    [c3]=d3000000-0000-4000-8000-0000000000c1
    [c4]=d4000000-0000-4000-8000-0000000000c1
    [c5]=d5000000-0000-4000-8000-0000000000c1
    [prioridad]=d9000000-0000-4000-8000-0000000000c1
)
declare -A FORMA_PAGO=([c2]=EFECTIVO [c3]=TARJETA [c4]=TRANSFERENCIA [c5]=EFECTIVO [prioridad]=TARJETA)
# [[producto_id, cantidad, precio_centavos_visto], ...]
declare -A ITEMS=(
    [c2]='[[4,1,120000]]'
    [c3]='[[5,3,90000]]'
    [c4]='[[6,1,70000]]'
    [c5]='[[7,2,50000]]'
    [prioridad]='[[4,1,120000],[5,3,90000]]'
)
USUARIO=1
SOLICITUD_ACEPTACION_C2=d2000000-0000-4000-8000-0000000000c2
SOLICITUD_PENDIENTE_DOBLE=d9000000-0000-4000-8000-0000000000c9
declare -A ESCENARIO_DIR=([c2]=c2_precio [c3]=c3_stock [c4]=c4_baja)
declare -A ESCENARIO_SQL=([c2]=preparar_c2_precio.sql [c3]=preparar_c3_stock.sql [c4]=preparar_c4_baja.sql)

entorno() { printf 'Error de uso/entorno: %s\n' "$*" >&2; exit 2; }
mostrar() {
    printf -- '--- %s ---\n' "$1"
    cat -- "$2"
    printf -- '--- fin %s ---\n' "$1"
}

TRABAJO=$(mktemp -d "${TMPDIR:-/tmp}/foodstore_u8_d.XXXXXX") || entorno 'No se pudo crear un directorio temporal'

base_existente() {
    [[ -f $1 && -r $1 && -w $1 ]] || entorno "La base debe existir y admitir escritura: $1"
    realpath -e -- "$1" || entorno "No se pudo resolver $1"
}

# param <nombre> <valor_texto>: valor como literal SQL de texto.
param_texto() { printf '.parameter set @%s "%s"' "$1" "'$2'"; }
param_entero() { printf '.parameter set @%s %s' "$1" "$2"; }

# sqlite_bail <db> <sql> <marca_final> [-cmd ...]: script con .bail on.
# Correcto solo si código 0, stderr vacío y última línea igual a la marca.
sqlite_bail() {
    local db=$1 sql=$2 marca=$3 rc ultima
    shift 3
    printf 'Comando: sqlite3 -batch'
    printf ' %q' "$@" "$db"
    printf ' < %s\n' "${sql##*/}"
    sqlite3 -batch "$@" "$db" < "$DIR/$sql" > "$TRABAJO/sql.out" 2> "$TRABAJO/sql.err"
    rc=$?
    mostrar stdout "$TRABAJO/sql.out"
    mostrar stderr "$TRABAJO/sql.err"
    ultima=$(tail -n 1 -- "$TRABAJO/sql.out")
    printf 'Código de salida: %s (esperado 0); última línea: %s\n' "$rc" "$ultima"
    if [[ $rc -eq 0 && ! -s $TRABAJO/sql.err && $ultima == "$marca" ]]; then
        echo "Resultado ${sql%.sql}: OK"
        return 0
    fi
    echo "Resultado ${sql%.sql}: FALLA (transacción revertida al cerrar el cliente)"
    return 1
}

contenedor_u8() {
    local identidad
    identidad=$(docker inspect --type container --format \
        '{{.Image}}|{{.HostConfig.NetworkMode}}|{{json .HostConfig.PortBindings}}|{{.State.Status}}' \
        "$CONTENEDOR") || entorno 'No se pudo consultar el contenedor U8'
    [[ $identidad == "$IMAGEN|none|{}|running" ]] ||
        entorno "Contenedor U8 con identidad o estado inesperado: $identidad (no se inicia ni se recrea)"
}

psql_u8() {
    docker exec -i "$CONTENEDOR" psql -X -v ON_ERROR_STOP=1 -U postgres -d "$BASE_PG" "$@"
}

leer_servidor() {  # leer_servidor <destino>
    psql_u8 -q -At -F ' | ' < "$PG_DIR/control_invariancia.sql" > "$1" 2> "$1.err"
    local rc=$?
    printf 'Lectura PostgreSQL (%s): código %s\n' "${1##*/}" "$rc"
    mostrar "lectura ${1##*/}" "$1"
    mostrar "diagnóstico ${1##*/}" "$1.err"
    [[ $rc -eq 0 && ! -s $1.err ]]
}

caso_valido() {  # caso_valido <caso> <lista...>
    local caso=$1 c
    shift
    for c in "$@"; do [[ $caso == "$c" ]] && return 0; done
    entorno "Caso no válido: $caso (válidos: $*)"
}

borrador() {
    local db caso=$2
    db=$(base_existente "$1") || exit 2
    caso_valido "$caso" c2 c3 c4 c5 prioridad
    printf 'Borrador %s: id_local=%s solicitud=%s usuario=%s forma_pago=%s items=%s\n' \
        "$caso" "${BORRADOR[$caso]}" "${SOLICITUD[$caso]}" "$USUARIO" "${FORMA_PAGO[$caso]}" "${ITEMS[$caso]}"
    sqlite_bail "$db" crear_borrador.sql 'BORRADOR CONFIRMADO' \
        -cmd "$(param_texto id_local "${BORRADOR[$caso]}")" \
        -cmd "$(param_texto solicitud "${SOLICITUD[$caso]}")" \
        -cmd "$(param_entero usuario "$USUARIO")" \
        -cmd "$(param_texto forma_pago "${FORMA_PAGO[$caso]}")" \
        -cmd "$(param_texto items "${ITEMS[$caso]}")"
}

preparar() {
    local caso=$1 rc
    caso_valido "$caso" c2 c3 c4
    contenedor_u8
    printf 'Preparación del escenario %s en PostgreSQL de pruebas: %s\n' "$caso" "${ESCENARIO_SQL[$caso]}"
    printf 'Comando: docker exec -i %s psql -X -v ON_ERROR_STOP=1 -U postgres -d %s < %s\n' \
        "$CONTENEDOR" "$BASE_PG" "${ESCENARIO_SQL[$caso]}"
    psql_u8 < "$PG_DIR/${ESCENARIO_SQL[$caso]}" > "$TRABAJO/pg.out" 2> "$TRABAJO/pg.err"
    rc=$?
    mostrar stdout "$TRABAJO/pg.out"
    mostrar stderr "$TRABAJO/pg.err"
    printf 'Código de salida: %s (esperado 0)\n' "$rc"
    if [[ $rc -eq 0 && ! -s $TRABAJO/pg.err ]] && grep -qx 'COMMIT' "$TRABAJO/pg.out"; then
        echo "Resultado preparación $caso: OK"
        return 0
    fi
    echo "Resultado preparación $caso: FALLA (transacción revertida en PostgreSQL)"
    return 1
}

instantanea() {
    local caso=$1 ejecucion=$2 db destino rc
    caso_valido "$caso" c2 c3 c4
    [[ $ejecucion =~ ^[0-9]{8}_[0-9]{6}$ ]] || entorno 'La ejecución debe tener la forma AAAAMMDD_HHMMSS'
    db=$(base_existente "$3") || exit 2
    destino="$DIR/instantaneas/$ejecucion/${ESCENARIO_DIR[$caso]}"
    [[ ! -e $destino ]] || entorno "La carpeta de la instantánea ya existe: $destino"
    mkdir -p -- "$DIR/instantaneas/$ejecucion" || entorno 'No se pudo crear la carpeta de la ejecución'
    mkdir -- "$destino" || entorno "No se pudo crear $destino"
    echo "Exportación: bash postgresql/laboratorio_u8.sh exportar $destino/servidor_snapshot.csv $destino/servidor_snapshot_meta.txt"
    bash "$PG_DIR/laboratorio_u8.sh" exportar "$destino/servidor_snapshot.csv" "$destino/servidor_snapshot_meta.txt"
    rc=$?
    printf 'Código de salida exportar: %s (esperado 0)\n' "$rc"
    [[ $rc -eq 0 ]] || return 1
    echo "Renovación: bash movil/preparar_foodstore_movil.sh renovar $db $destino/servidor_snapshot.csv $destino/servidor_snapshot_meta.txt"
    bash "$DIR/preparar_foodstore_movil.sh" renovar "$db" "$destino/servidor_snapshot.csv" "$destino/servidor_snapshot_meta.txt"
    rc=$?
    printf 'Código de salida renovar: %s (esperado 0)\n' "$rc"
    [[ $rc -eq 0 ]] || return 1
    sha256sum -- "$destino/servidor_snapshot.csv" "$destino/servidor_snapshot_meta.txt"
}

simular() {
    local db rc_sem iguales=1
    db=$(base_existente "$1") || exit 2
    contenedor_u8
    leer_servidor "$TRABAJO/servidor_antes" || { echo 'FALLA: lectura previa de PostgreSQL'; return 1; }
    echo '>> Simulación únicamente en SQLite (semaforo.sql no contiene operaciones sobre PostgreSQL)'
    sqlite_bail "$db" semaforo.sql 'SEMAFORO CONFIRMADO'
    rc_sem=$?
    leer_servidor "$TRABAJO/servidor_despues" || { echo 'FALLA: lectura posterior de PostgreSQL'; return 1; }
    if cmp -s -- "$TRABAJO/servidor_antes" "$TRABAJO/servidor_despues"; then
        iguales=0
        echo 'PostgreSQL antes/después: idéntico byte a byte (precio, stock y estado por producto; pedidos y líneas)'
    else
        diff -u -- "$TRABAJO/servidor_antes" "$TRABAJO/servidor_despues"
        echo 'PostgreSQL antes/después: DIFERENTE'
    fi
    if [[ $rc_sem -eq 0 && $iguales -eq 0 ]]; then
        echo 'Resultado simulación: OK'
        return 0
    fi
    echo 'Resultado simulación: FALLA'
    return 1
}

aceptar() {
    local db caso=$2 nueva
    db=$(base_existente "$1") || exit 2
    caso_valido "$caso" c2 c2_uuid_repetido
    nueva=$SOLICITUD_ACEPTACION_C2
    # Variante de control: la solicitud nueva repite el UUID de la anterior,
    # de modo que el INSERT falla DESPUÉS de actualizar los precios.
    [[ $caso == c2 ]] || nueva=${SOLICITUD[c2]}
    echo "ACEPTACIÓN SIMULADA DEL CLIENTE: el cliente del borrador ${BORRADOR[c2]} acepta el precio actual de la instantánea."
    printf 'Solicitud anterior=%s; solicitud nueva=%s\n' "${SOLICITUD[c2]}" "$nueva"
    sqlite_bail "$db" aceptar_precio.sql 'ACEPTACION CONFIRMADA' \
        -cmd "$(param_texto id_local "${BORRADOR[c2]}")" \
        -cmd "$(param_texto solicitud_anterior "${SOLICITUD[c2]}")" \
        -cmd "$(param_texto solicitud_nueva "$nueva")"
}

reinsertar() {
    local db caso=$2 uuid columna linea rc esperadas ok falla esperado
    db=$(base_existente "$1") || exit 2
    caso_valido "$caso" c6_uuid pendiente_doble
    if [[ $caso == c6_uuid ]]; then
        uuid=${SOLICITUD[c2]}; columna=solicitud_uuid
    else
        uuid=$SOLICITUD_PENDIENTE_DOBLE; columna=id_local
    fi
    linea=$(grep -n -- '-- SOLICITUD_INVALIDA$' "$DIR/insertar_solicitud.sql" | cut -d: -f1)
    [[ $linea =~ ^[0-9]+$ ]] || entorno 'La marca SOLICITUD_INVALIDA debe aparecer una vez'
    esperado="Error near line $linea: UNIQUE constraint failed: cola_sync.$columna"
    printf 'Intento %s: solicitud=%s id_local=%s\n' "$caso" "$uuid" "${BORRADOR[c2]}"
    printf 'Comando: sqlite3 -batch -cmd ... %q < insertar_solicitud.sql\n' "$db"
    sqlite3 -batch \
        -cmd "$(param_texto solicitud "$uuid")" \
        -cmd "$(param_texto id_local "${BORRADOR[c2]}")" \
        "$db" < "$DIR/insertar_solicitud.sql" > "$TRABAJO/ins.out" 2> "$TRABAJO/ins.err"
    rc=$?
    mostrar stdout "$TRABAJO/ins.out"
    mostrar stderr "$TRABAJO/ins.err"
    printf '%s\n' "$esperado" > "$TRABAJO/ins.err.esperado"
    esperadas=$(grep -c 'iif(' "$DIR/insertar_solicitud.sql")
    ok=$(grep -c ' | OK$' "$TRABAJO/ins.out")
    falla=$(grep -c ' | FALLA$' "$TRABAJO/ins.out")
    printf 'Código: %s (esperado 1); stderr esperado: %s\n' "$rc" "$esperado"
    printf 'Comprobaciones SQL: esperadas=%s OK=%s FALLA=%s\n' "$esperadas" "$ok" "$falla"
    if [[ $rc -eq 1 && $ok -eq $esperadas && $falla -eq 0 ]] &&
       diff -u -- "$TRABAJO/ins.err.esperado" "$TRABAJO/ins.err"; then
        echo "Resultado $caso: OK (error esperado y cola_sync sin cambios)"
        return 0
    fi
    echo "Resultado $caso: FALLA"
    return 1
}

ausente() {
    local db
    db=$(base_existente "$1") || exit 2
    [[ $2 =~ ^[1-9][0-9]*$ ]] || entorno 'producto_id debe ser un entero positivo'
    # Nunca sobre una base del repositorio: solo copias descartables.
    [[ $db != "$REPO"/* ]] || entorno "Se rechaza: $db está dentro del repositorio"
    sqlite_bail "$db" simular_producto_ausente.sql 'COPIA PREPARADA' \
        -cmd "$(param_entero producto_id "$2")"
}

comprobar() {
    local db caso=$2 solicitud=$3 rc esperadas ok falla
    db=$(realpath -e -- "$1") || entorno "No existe $1"
    caso_valido "$caso" c2 c3 c4 c5 prioridad
    [[ $4 =~ ^[1-9][0-9]*$ && $5 =~ ^[0-9]+$ && $8 =~ ^[01]$ ]] || entorno 'producto_id, precio_visto o lapida inválidos'
    [[ $7 != *"'"* && $7 != *'"'* ]] || entorno 'El motivo esperado no admite comillas'
    printf 'Comprobación %s: solicitud=%s producto=%s precio_visto=%s estado=%s motivo=%s lapida=%s\n' \
        "$caso" "$solicitud" "$4" "$5" "$6" "$7" "$8"
    sqlite3 -readonly -batch \
        -cmd "$(param_texto id_local "${BORRADOR[$caso]}")" \
        -cmd "$(param_texto solicitud "$solicitud")" \
        -cmd "$(param_entero producto_id "$4")" \
        -cmd "$(param_entero precio_visto "$5")" \
        -cmd "$(param_texto estado "$6")" \
        -cmd "$(param_texto motivo "$7")" \
        -cmd "$(param_entero lapida "$8")" \
        "$db" < "$DIR/comprobar_caso_d.sql" > "$TRABAJO/comp.out" 2> "$TRABAJO/comp.err"
    rc=$?
    mostrar stdout "$TRABAJO/comp.out"
    mostrar stderr "$TRABAJO/comp.err"
    esperadas=$(grep -c 'iif(' "$DIR/comprobar_caso_d.sql")
    ok=$(grep -c ' | OK$' "$TRABAJO/comp.out")
    falla=$(grep -c ' | FALLA$' "$TRABAJO/comp.out")
    printf 'Código: %s (esperado 0); comprobaciones esperadas=%s OK=%s FALLA=%s\n' "$rc" "$esperadas" "$ok" "$falla"
    if [[ $rc -eq 0 && ! -s $TRABAJO/comp.err && $ok -eq $esperadas && $falla -eq 0 ]]; then
        echo "Resultado comprobación $caso: OK"
        return 0
    fi
    echo "Resultado comprobación $caso: FALLA"
    return 1
}

estado() {
    local db rc
    db=$(realpath -e -- "$1") || entorno "No existe $1"
    sqlite3 -readonly -batch "$db" < "$DIR/estado_bloque_d.sql" > "$TRABAJO/estado.out" 2> "$TRABAJO/estado.err"
    rc=$?
    mostrar "estado de $db" "$TRABAJO/estado.out"
    mostrar stderr "$TRABAJO/estado.err"
    printf 'Código: %s (esperado 0)\n' "$rc"
    [[ $rc -eq 0 && ! -s $TRABAJO/estado.err ]]
}

printf 'Directorio de capturas conservado: %s\n' "$TRABAJO"
[[ $# -ge 1 ]] || entorno 'Falta la operación'
operacion=$1
shift
case $operacion in
    borrador)    [[ $# -eq 2 ]] || entorno 'Uso: borrador <db> <caso>'; borrador "$@" ;;
    preparar)    [[ $# -eq 1 ]] || entorno 'Uso: preparar <c2|c3|c4>'; preparar "$@" ;;
    instantanea) [[ $# -eq 3 ]] || entorno 'Uso: instantanea <caso> <ejecucion> <db>'; instantanea "$@" ;;
    simular)     [[ $# -eq 1 ]] || entorno 'Uso: simular <db>'; simular "$@" ;;
    aceptar)     [[ $# -eq 2 ]] || entorno 'Uso: aceptar <db> <caso>'; aceptar "$@" ;;
    reinsertar)  [[ $# -eq 2 ]] || entorno 'Uso: reinsertar <db> <caso>'; reinsertar "$@" ;;
    ausente)     [[ $# -eq 2 ]] || entorno 'Uso: ausente <db_copia> <producto_id>'; ausente "$@" ;;
    estado)      [[ $# -eq 1 ]] || entorno 'Uso: estado <db>'; estado "$@" ;;
    comprobar)   [[ $# -eq 8 ]] || entorno 'Uso: comprobar <db> <caso> <solicitud> <producto_id> <precio_visto> <estado> <motivo> <lapida>'; comprobar "$@" ;;
    *) entorno "Operación desconocida: $operacion" ;;
esac
exit $?
