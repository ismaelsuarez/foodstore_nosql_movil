#!/usr/bin/env bash
# =============================================================================
# Food Store — Unidad 8 — Secuencia del bloque D sobre la base entregable.
#
#   bash ejecutar_bloque_d.sh <ejecucion AAAAMMDD_HHMMSS> <dir_puntos_nuevo>
#   bash ejecutar_bloque_d.sh --continuar-c6 <ejecucion> <dir_puntos_existente>
#
# --continuar-c6 ejecuta solo C6 y el estado final, sobre una base que ya
# completó C2–C5 en esa ejecución. Existe porque la primera ejecución real
# se detuvo en C6 por un error de este script (ver tasks.md); no repite
# ningún paso anterior. Se niega a continuar si los resultados de C2–C5 no
# son los esperados.
#
# Parte del estado final del bloque C (borradores vacíos, instantánea inicial)
# y ejecuta, en este orden, los casos C2, C3, C4, C5 y C6 con bloque_d.sh.
# Cada caso termina su preparación (borrador, mutación en PostgreSQL,
# instantánea y renovación) antes de simular. Se detiene en el primer paso
# fallido, sin reintentar ni reinicializar nada.
#
# <dir_puntos_nuevo>: directorio nuevo fuera del repositorio donde se guardan
# copias de la base en dos momentos, para los controles de controles_d.sh:
#   punto_c2_borrador.db  (borrador C2 creado, servidor sin cambios)
#   punto_c2_conflicto.db (C2 evaluado en CONFLICTO, antes de la aceptación)
#
# Códigos: 0 secuencia completa; 1 un paso falló; 2 uso o entorno.
# =============================================================================
set -uo pipefail
export LC_ALL=C

DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 2
REPO=$(cd -- "$DIR/../../.." && pwd -P) || exit 2
DB="$DIR/foodstore_movil.db"
D="$DIR/bloque_d.sh"

entorno() { printf 'Error de uso/entorno: %s\n' "$*" >&2; exit 2; }

MODO=completo
if [[ ${1-} == --continuar-c6 ]]; then MODO=c6; shift; fi
[[ $# -eq 2 ]] || entorno 'Uso: ejecutar_bloque_d.sh [--continuar-c6] <ejecucion> <dir_puntos>'
EJECUCION=$1
[[ $EJECUCION =~ ^[0-9]{8}_[0-9]{6}$ ]] || entorno 'La ejecución debe tener la forma AAAAMMDD_HHMMSS'
padre=$(cd -- "$(dirname -- "$2")" && pwd -P) || entorno 'El directorio padre de los puntos no existe'
PUNTOS="$padre/$(basename -- "$2")"
[[ $PUNTOS != "$REPO"/* ]] || entorno 'Los puntos deben quedar fuera del repositorio'
[[ -f $DB ]] || entorno "No existe la base entregable: $DB"
if [[ $MODO == completo ]]; then
    [[ ! -e $DIR/instantaneas/$EJECUCION ]] || entorno "Ya existen instantáneas de la ejecución $EJECUCION"
    [[ ! -e $PUNTOS ]] || entorno "El directorio de puntos ya existe: $PUNTOS"
    mkdir -m 700 -- "$PUNTOS" || entorno "No se pudo crear $PUNTOS"
else
    [[ -d $DIR/instantaneas/$EJECUCION/c4_baja ]] || entorno "Faltan las instantáneas de la ejecución $EJECUCION"
    [[ -d $PUNTOS && -f $PUNTOS/punto_c2_conflicto.db ]] || entorno "No es un directorio de puntos de esa ejecución: $PUNTOS"
    for archivo in c6_2_antes.txt c6_2_despues.txt c6_simulacion.txt; do
        [[ ! -e $PUNTOS/$archivo ]] || entorno "C6-2 ya se ejecutó con estos puntos: $PUNTOS/$archivo"
    done
fi

n=0
paso() {  # paso <título> <comando...>
    local rc
    n=$((n + 1))
    printf '\n######## Paso %02d — %s (%s)\n' "$n" "$1" "$(date '+%Y-%m-%dT%H:%M:%S%z')"
    shift
    "$@"
    rc=$?
    printf '>> Paso %02d: código %s\n' "$n" "$rc"
    if [[ $rc -ne 0 ]]; then
        printf 'SECUENCIA DETENIDA en el paso %02d. No se reintenta ni se reinicializa.\n' "$n"
        exit 1
    fi
}

punto() {  # copia de la base cerrada: ningún cliente sqlite3 está abierto aquí
    cp -- "$DB" "$PUNTOS/$1" && chmod a-w -- "$PUNTOS/$1" && sha256sum -- "$PUNTOS/$1"
}

captura_de() {  # capturado_en de la instantánea de un escenario
    local meta="$DIR/instantaneas/$EJECUCION/$1/servidor_snapshot_meta.txt" valor
    valor=$(grep -E '^capturado_en=' "$meta" | cut -d= -f2-) || return 1
    [[ -n $valor ]] || return 1
    printf '%s\n' "$valor"
}

estado_de() {  # estado_de <nombre>: en $PUNTOS, solo el bloque de datos
    local destino="$PUNTOS/$1"
    [[ ! -e $destino ]] || { echo "Ya existe $destino"; return 1; }
    bash "$D" estado "$DB" > "$destino.completo" || return 1
    sed -n '/^--- estado de /,/^--- fin estado de /p' "$destino.completo" > "$destino"
    [[ -s $destino ]] && echo "Estado guardado en $destino"
}

simular_con_cero() {  # C6: segunda ejecución sin pendientes
    bash "$D" simular "$DB" | tee "$PUNTOS/c6_simulacion.txt"
    [[ ${PIPESTATUS[0]} -eq 0 ]] || return 1
    grep -qx 'procesadas | 0' "$PUNTOS/c6_simulacion.txt" || { echo 'FALLA: se esperaba procesar 0'; return 1; }
    echo 'Solicitudes procesadas: 0 (esperado 0): OK'
}

comparar_estados() {
    if cmp -s -- "$PUNTOS/$1" "$PUNTOS/$2"; then
        echo "Estado SQLite $1 / $2: idéntico byte a byte (cola_sync, borradores, ítems, catálogo, instantánea)"
        return 0
    fi
    diff -u -- "$PUNTOS/$1" "$PUNTOS/$2"
    return 1
}

C2_SOL=d2000000-0000-4000-8000-0000000000c1
C2_NUEVA=d2000000-0000-4000-8000-0000000000c2
C3_SOL=d3000000-0000-4000-8000-0000000000c1
C4_SOL=d4000000-0000-4000-8000-0000000000c1
C5_SOL=d5000000-0000-4000-8000-0000000000c1
C2_MOTIVO='producto_id=4: precio_visto=120000 centavos, precio_actual=132000 centavos'

printf 'Ejecución %s (%s); base entregable %s; puntos en %s\n' "$EJECUCION" "$MODO" "$DB" "$PUNTOS"
sha256sum -- "$DB"

casos_c2_c5() {
paso 'Estado inicial (fin del bloque C)' bash "$D" estado "$DB"

# ---- C2: cambio de precio ---------------------------------------------------
paso 'C2 — borrador previo (1 u. a 120000) y solicitud PENDIENTE' bash "$D" borrador "$DB" c2
paso 'C2 — punto de copia: borrador creado' punto punto_c2_borrador.db
paso 'C2 — preparación en PostgreSQL: precio 1200.00 → 1320.00' bash "$D" preparar c2
paso 'C2 — instantánea c2_precio y renovación' bash "$D" instantanea c2 "$EJECUCION" "$DB"
paso 'C2 — el borrador conserva 120000 tras la renovación' \
    bash "$D" comprobar "$DB" c2 "$C2_SOL" 4 120000 PENDIENTE '<NULL>' 0
paso 'C2 — simulación' bash "$D" simular "$DB"
paso 'C2 — resultado CONFLICTO con ambos precios' \
    bash "$D" comprobar "$DB" c2 "$C2_SOL" 4 120000 CONFLICTO "$C2_MOTIVO" 0
paso 'C2 — punto de copia: CONFLICTO antes de aceptar' punto punto_c2_conflicto.db
paso 'C2 — aceptación simulada del cliente (132000) y solicitud nueva' bash "$D" aceptar "$DB" c2
paso 'C2 — solicitud nueva PENDIENTE con 132000' \
    bash "$D" comprobar "$DB" c2 "$C2_NUEVA" 4 132000 PENDIENTE '<NULL>' 0
paso 'C2 — la solicitud anterior conserva CONFLICTO y su motivo' \
    bash "$D" comprobar "$DB" c2 "$C2_SOL" 4 132000 CONFLICTO "$C2_MOTIVO" 0
paso 'C2 — simulación de la solicitud nueva' bash "$D" simular "$DB"
CAP_C2=$(captura_de c2_precio) || entorno 'No se pudo leer capturado_en de c2_precio'
paso 'C2 — solicitud nueva SIMULADO_APROBADO' \
    bash "$D" comprobar "$DB" c2 "$C2_NUEVA" 4 132000 SIMULADO_APROBADO "todo coincide con snapshot de $CAP_C2" 0

# ---- C3: stock insuficiente -------------------------------------------------
paso 'C3 — borrador (3 u. a 90000) y solicitud PENDIENTE' bash "$D" borrador "$DB" c3
paso 'C3 — preparación en PostgreSQL: stock 10 → 2' bash "$D" preparar c3
paso 'C3 — instantánea c3_stock y renovación' bash "$D" instantanea c3 "$EJECUCION" "$DB"
paso 'C3 — simulación' bash "$D" simular "$DB"
paso 'C3 — resultado RECHAZADO por stock' \
    bash "$D" comprobar "$DB" c3 "$C3_SOL" 5 90000 RECHAZADO 'producto_id=5: stock disponible=2, cantidad solicitada=3' 0

# ---- C4: baja lógica --------------------------------------------------------
paso 'C4 — borrador previo (1 u. a 70000) y solicitud PENDIENTE' bash "$D" borrador "$DB" c4
paso 'C4 — preparación en PostgreSQL: eliminado false → true' bash "$D" preparar c4
paso 'C4 — instantánea c4_baja y renovación' bash "$D" instantanea c4 "$EJECUCION" "$DB"
paso 'C4 — lápida en producto_cache, fuera del catálogo, precio del ítem sin cambio' \
    bash "$D" comprobar "$DB" c4 "$C4_SOL" 6 70000 PENDIENTE '<NULL>' 1
paso 'C4 — simulación' bash "$D" simular "$DB"
paso 'C4 — resultado RECHAZADO por baja' \
    bash "$D" comprobar "$DB" c4 "$C4_SOL" 6 70000 RECHAZADO 'producto_id=6: eliminado=t' 1

# ---- C5: sin discrepancias --------------------------------------------------
paso 'C5 — borrador (2 u. a 50000) contra la instantánea vigente' bash "$D" borrador "$DB" c5
paso 'C5 — simulación' bash "$D" simular "$DB"
CAP_C4=$(captura_de c4_baja) || entorno 'No se pudo leer capturado_en de c4_baja'
paso 'C5 — resultado SIMULADO_APROBADO (no es venta ni reserva de stock)' \
    bash "$D" comprobar "$DB" c5 "$C5_SOL" 7 50000 SIMULADO_APROBADO "todo coincide con snapshot de $CAP_C4" 0
}

# Guarda de --continuar-c6: C2–C5 deben estar en el estado esperado.
resultados_c2_c5() {
CAP_C2=$(captura_de c2_precio) || entorno 'No se pudo leer capturado_en de c2_precio'
CAP_C4=$(captura_de c4_baja) || entorno 'No se pudo leer capturado_en de c4_baja'
paso 'Guarda — C2 original en CONFLICTO' \
    bash "$D" comprobar "$DB" c2 "$C2_SOL" 4 132000 CONFLICTO "$C2_MOTIVO" 0
paso 'Guarda — C2 nueva SIMULADO_APROBADO' \
    bash "$D" comprobar "$DB" c2 "$C2_NUEVA" 4 132000 SIMULADO_APROBADO "todo coincide con snapshot de $CAP_C2" 0
paso 'Guarda — C3 RECHAZADO' \
    bash "$D" comprobar "$DB" c3 "$C3_SOL" 5 90000 RECHAZADO 'producto_id=5: stock disponible=2, cantidad solicitada=3' 0
paso 'Guarda — C4 RECHAZADO con lápida' \
    bash "$D" comprobar "$DB" c4 "$C4_SOL" 6 70000 RECHAZADO 'producto_id=6: eliminado=t' 1
paso 'Guarda — C5 SIMULADO_APROBADO' \
    bash "$D" comprobar "$DB" c5 "$C5_SOL" 7 50000 SIMULADO_APROBADO "todo coincide con snapshot de $CAP_C4" 0
}

# ---- C6: dos comprobaciones independientes ---------------------------------
c6_1() {
paso 'C6-1 — estado antes de reinsertar' estado_de c6_1_antes.txt
paso 'C6-1 — reinsertar el solicitud_uuid original de C2' bash "$D" reinsertar "$DB" c6_uuid
paso 'C6-1 — estado después' estado_de c6_1_despues.txt
paso 'C6-1 — sin inserción ni cambios' comparar_estados c6_1_antes.txt c6_1_despues.txt
}

c6_2_y_final() {
paso 'C6-2 — estado antes de repetir el semáforo' estado_de c6_2_antes.txt
paso 'C6-2 — semáforo sin pendientes' simular_con_cero
paso 'C6-2 — estado después' estado_de c6_2_despues.txt
paso 'C6-2 — solicitudes evaluadas sin cambios' comparar_estados c6_2_antes.txt c6_2_despues.txt
paso 'C6-2 — el CONFLICTO original de C2 sigue igual tras la aceptación' \
    bash "$D" comprobar "$DB" c2 "$C2_SOL" 4 132000 CONFLICTO "$C2_MOTIVO" 0

paso 'Estado final' bash "$D" estado "$DB"
}

if [[ $MODO == completo ]]; then
    casos_c2_c5
    c6_1
else
    resultados_c2_c5
    [[ -f $PUNTOS/c6_1_antes.txt && -f $PUNTOS/c6_1_despues.txt ]] ||
        entorno 'Faltan los estados de C6-1 en el directorio de puntos'
    paso 'C6-1 — comparación de los estados capturados antes y después de la reinserción' \
        comparar_estados c6_1_antes.txt c6_1_despues.txt
fi
c6_2_y_final
sha256sum -- "$DB"
echo
echo "SECUENCIA DEL BLOQUE D ($MODO) COMPLETA: todos los pasos con código 0."
