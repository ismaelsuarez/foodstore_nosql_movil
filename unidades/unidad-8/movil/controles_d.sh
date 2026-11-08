#!/usr/bin/env bash
# =============================================================================
# Food Store — Unidad 8 — Controles del diseño D sobre COPIAS descartables.
# No son casos nuevos de la consigna: verifican comportamientos ya exigidos
# por requirements.md (CA-03c, CA-04d) y design.md §7.2.
#
#   bash controles_d.sh <punto_c2_borrador.db> <punto_c2_conflicto.db> <dir_c3_stock>
#
# Los puntos los genera ejecutar_bloque_d.sh; <dir_c3_stock> es la carpeta de
# la instantánea c3_stock de la misma ejecución. Cada control trabaja sobre
# su propia copia en un directorio nuevo de /tmp, que se conserva. La base
# entregable no se abre.
#
#   T1 prioridad: ítem con precio distinto + ítem con stock insuficiente
#      → RECHAZADO con motivo de rechazo.
#   T2 una sola PENDIENTE por borrador (índice ux_cola_una_pendiente).
#   T3 aceptación imposible: producto ausente de snapshot_servidor.
#   T4 fallo al insertar la solicitud nueva DESPUÉS de actualizar precios.
#
# Códigos: 0 todos OK; 1 algún control falló; 2 uso o entorno.
# =============================================================================
set -uo pipefail
export LC_ALL=C

DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 2
REPO=$(cd -- "$DIR/../../.." && pwd -P) || exit 2
D="$DIR/bloque_d.sh"

entorno() { printf 'Error de uso/entorno: %s\n' "$*" >&2; exit 2; }
[[ $# -eq 3 ]] || entorno 'Uso: controles_d.sh <punto_c2_borrador.db> <punto_c2_conflicto.db> <dir_c3_stock>'
A0=$(realpath -e -- "$1") || entorno "No existe $1"
A1=$(realpath -e -- "$2") || entorno "No existe $2"
C3=$(realpath -e -- "$3") || entorno "No existe $3"
for p in "$A0" "$A1"; do [[ $p != "$REPO"/* ]] || entorno "Los puntos deben estar fuera del repositorio: $p"; done
[[ -f $C3/servidor_snapshot.csv && -f $C3/servidor_snapshot_meta.txt ]] || entorno 'Falta la instantánea c3_stock'

fallos=0
veredicto() {  # veredicto <nombre> <predicado 0|1>
    if [[ $2 -eq 0 ]]; then printf '%s: OK\n' "$1"; else printf '%s: FALLA\n' "$1"; fallos=1; fi
}
copia() {  # copia <punto> → deja $T y $T/copia.db
    T=$(mktemp -d /tmp/foodstore_u8_d_control.XXXXXX) || entorno 'No se pudo crear un directorio temporal'
    cp -- "$1" "$T/copia.db" && chmod u+w -- "$T/copia.db" || entorno 'No se pudo copiar el punto'
    printf 'Copia descartable: %s (desde %s)\n' "$T/copia.db" "$1"
}
estado_datos() {  # estado_datos <destino>: bloque de datos sin rutas temporales
    bash "$D" estado "$T/copia.db" > "$1.completo" || return 1
    sed -n '/^--- estado de /,/^--- fin estado de /p' "$1.completo" > "$1"
    [[ -s $1 ]]
}
ejecutar() {  # ejecutar <salida> <comando...>; muestra la salida y deja rc
    local salida=$1
    shift
    "$@" > "$salida" 2>&1
    rc=$?
    cat -- "$salida"
}

echo "=== T1 — prioridad del rechazo sobre el conflicto (CA-03c) ==="
copia "$A0"
ejecutar "$T/borrador.out" bash "$D" borrador "$T/copia.db" prioridad
rc_borrador=$rc
ejecutar "$T/renovar.out" bash "$DIR/preparar_foodstore_movil.sh" renovar "$T/copia.db" \
    "$C3/servidor_snapshot.csv" "$C3/servidor_snapshot_meta.txt"
rc_renovar=$rc
ejecutar "$T/simular.out" bash "$D" simular "$T/copia.db"
rc_simular=$rc
ejecutar "$T/comprobar.out" bash "$D" comprobar "$T/copia.db" prioridad \
    d9000000-0000-4000-8000-0000000000c1 5 90000 RECHAZADO \
    'producto_id=5: stock disponible=2, cantidad solicitada=3' 0
rc_comprobar=$rc
# El ítem de menor producto_id (4) tiene solo un conflicto de precio.
grep -F 'dato | snapshot_servidor | 5 | 90000 | 2 | t | f |' "$T/comprobar.out" > /dev/null
rc_stock=$?
printf 'Códigos: borrador=%s renovar=%s simular=%s comprobar=%s (esperados 0)\n' \
    "$rc_borrador" "$rc_renovar" "$rc_simular" "$rc_comprobar"
r=1; [[ $rc_borrador -eq 0 && $rc_renovar -eq 0 && $rc_simular -eq 0 && $rc_comprobar -eq 0 && $rc_stock -eq 0 ]] && r=0
veredicto 'T1 prioridad: RECHAZADO con motivo de stock aunque el producto 4 cambió de precio' "$r"

echo
echo "=== T2 — una sola solicitud PENDIENTE por borrador (CA-04d) ==="
copia "$A0"
estado_datos "$T/antes.txt" || entorno 'No se pudo leer el estado'
ejecutar "$T/reinsertar.out" bash "$D" reinsertar "$T/copia.db" pendiente_doble
rc_reinsertar=$rc
estado_datos "$T/despues.txt" || entorno 'No se pudo leer el estado'
cmp -s -- "$T/antes.txt" "$T/despues.txt"
rc_igual=$?
printf 'Código reinsertar=%s (0 = se observó UNIQUE constraint failed: cola_sync.id_local); estado idéntico=%s\n' \
    "$rc_reinsertar" "$([[ $rc_igual -eq 0 ]] && echo sí || echo no)"
r=1; [[ $rc_reinsertar -eq 0 && $rc_igual -eq 0 ]] && r=0
veredicto 'T2 segunda PENDIENTE rechazada por ux_cola_una_pendiente, sin cambios' "$r"

echo
echo "=== T3 — aceptación imposible: producto ausente de snapshot_servidor (design.md §7.2) ==="
copia "$A1"
ejecutar "$T/ausente.out" bash "$D" ausente "$T/copia.db" 4
rc_ausente=$rc
estado_datos "$T/antes.txt" || entorno 'No se pudo leer el estado'
ejecutar "$T/aceptar.out" bash "$D" aceptar "$T/copia.db" c2
rc_aceptar=$rc
estado_datos "$T/despues.txt" || entorno 'No se pudo leer el estado'
cmp -s -- "$T/antes.txt" "$T/despues.txt"
rc_igual=$?
errores=$(grep -cE '^Error near line [0-9]+: ' "$T/aceptar.out")
grep -qE '^Error near line [0-9]+: CHECK constraint failed: ok = 1$' "$T/aceptar.out"; rc_diag=$?
grep -qxF 'control | items_en_snapshot | FALLA' "$T/aceptar.out"; rc_control=$?
grep -qF 'precios_actualizados' "$T/aceptar.out"; rc_update=$?
printf 'Códigos: ausente=%s (esperado 0) aceptar=%s (esperado 1); diagnósticos=%s (esperado 1)\n' \
    "$rc_ausente" "$rc_aceptar" "$errores"
r=1
[[ $rc_ausente -eq 0 && $rc_aceptar -eq 1 && $errores -eq 1 && $rc_diag -eq 0 && $rc_control -eq 0 \
   && $rc_update -ne 0 && $rc_igual -eq 0 ]] && r=0
veredicto 'T3 detenida antes del UPDATE; precios, solicitudes y catálogo idénticos' "$r"

echo
echo "=== T4 — falla el INSERT de la solicitud nueva después del UPDATE (design.md §7.2) ==="
copia "$A1"
estado_datos "$T/antes.txt" || entorno 'No se pudo leer el estado'
ejecutar "$T/aceptar.out" bash "$D" aceptar "$T/copia.db" c2_uuid_repetido
rc_aceptar=$rc
estado_datos "$T/despues.txt" || entorno 'No se pudo leer el estado'
cmp -s -- "$T/antes.txt" "$T/despues.txt"
rc_igual=$?
errores=$(grep -cE '^Error near line [0-9]+: ' "$T/aceptar.out")
grep -qE '^Error near line [0-9]+: UNIQUE constraint failed: cola_sync\.solicitud_uuid$' "$T/aceptar.out"; rc_diag=$?
grep -qxF 'paso | precios_actualizados_en_la_transaccion | 1' "$T/aceptar.out"; rc_update=$?
grep -qxF 'ACEPTACION CONFIRMADA' "$T/aceptar.out"; rc_confirmada=$?
printf 'Código aceptar=%s (esperado 1); diagnósticos=%s (esperado 1); UPDATE ejecutado antes del error=%s\n' \
    "$rc_aceptar" "$errores" "$([[ $rc_update -eq 0 ]] && echo sí || echo no)"
r=1
[[ $rc_aceptar -eq 1 && $errores -eq 1 && $rc_diag -eq 0 && $rc_update -eq 0 && $rc_confirmada -ne 0 \
   && $rc_igual -eq 0 ]] && r=0
veredicto 'T4 UPDATE revertido con el INSERT fallido; estado idéntico' "$r"
if [[ $rc_igual -ne 0 ]]; then diff -u -- "$T/antes.txt" "$T/despues.txt"; fi

echo
if [[ $fallos -eq 0 ]]; then echo 'RESULTADO GLOBAL CONTROLES D: OK'; else echo 'RESULTADO GLOBAL CONTROLES D: FALLA'; fi
exit "$fallos"
