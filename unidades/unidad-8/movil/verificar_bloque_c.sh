#!/usr/bin/env bash
# Food Store — Unidad 8 — Pruebas b/c/f, d, e del bloque C (no casos C1–C7).
# Uso: bash verificar_bloque_c.sh <db>
# La base recibida SOLO se abre con sqlite3 -readonly. Las renovaciones se
# ejecutan sobre copias nuevas, conservadas junto con todas las capturas.
# 0: todo OK; 1: alguna comprobación FALLA; 2: uso/entorno inválido.
set -uo pipefail
export LC_ALL=C
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit 2
CSV="$DIR/servidor_snapshot.csv"
META="$DIR/servidor_snapshot_meta.txt"
SQL="$DIR/consultas_bloque_c.sql"
PREPARAR="$DIR/preparar_foodstore_movil.sh"
error_entorno() { printf 'Error de uso/entorno: %s\n' "$*" >&2; exit 2; }
seccion() { printf '\n=== %s ===\n' "$1"; }
mostrar() {
    printf -- '--- %s ---\n' "$1"
    cat -- "$2"
    printf -- '--- fin %s ---\n' "$1"
}
fallos=0
veredicto() {
    # Recibe un predicado ya calculado, no una etiqueta optimista.
    if [[ $2 -eq 0 ]]; then
        printf '%s: OK\n' "$1"
    else
        printf '%s: FALLA\n' "$1"
        fallos=1
    fi
}
nuevo_directorio() {
    trabajo=$(mktemp -d /tmp/foodstore_u8_c_verificacion.XXXXXX) || error_entorno 'No se pudo crear un directorio temporal'
    printf 'Directorio temporal conservado: %s\n' "$trabajo"
}
dump_datos() {
    local db=$1 destino=$2 etapa=$3 tabla rc resultado=0
    for tabla in snapshot_servidor producto_cache; do
        sqlite3 -readonly -batch -list -separator ' | ' -nullvalue '<NULL>' "$db" \
            "SELECT * FROM $tabla ORDER BY producto_id;" \
            > "$destino/$etapa.$tabla" 2> "$destino/$etapa.$tabla.err"
        rc=$?
        printf 'Dump %s/%s: código esperado=0 observado=%s\n' "$etapa" "$tabla" "$rc"
        mostrar "diagnóstico dump $etapa/$tabla" "$destino/$etapa.$tabla.err"
        if [[ $rc -ne 0 || -s $destino/$etapa.$tabla.err ]]; then resultado=1; fi
    done
    return "$resultado"
}
comparar_dumps() {
    local destino=$1 tabla resultado=0
    for tabla in snapshot_servidor producto_cache; do
        if diff -u -- "$destino/antes.$tabla" "$destino/despues.$tabla"; then
            printf '%s antes/después: idénticos byte a byte\n' "$tabla"
        else
            resultado=1
        fi
    done
    return "$resultado"
}
ejecutar_renovacion() {
    # Siempre Bash explícito y siempre una copia, nunca la base original.
    bash "$PREPARAR" renovar "$trabajo/copia.db" "$1" "$2" \
        > "$trabajo/renovar.out" 2> "$trabajo/renovar.err"
    rc_renovar=$?
    mostrar 'stdout coordinador' "$trabajo/renovar.out"
    mostrar 'stderr coordinador' "$trabajo/renovar.err"
}

[[ $# -eq 1 ]] || error_entorno 'Uso: verificar_bloque_c.sh <db>'
[[ -f $1 && -r $1 ]] || error_entorno 'La base debe existir y admitir lectura'
for herramienta in sqlite3 bash mktemp cp sha256sum realpath diff cmp grep sed tail cut wc cat; do
    command -v "$herramienta" > /dev/null || error_entorno "Falta $herramienta"
done
for archivo in "$CSV" "$META" "$SQL" "$PREPARAR" "$DIR/renovar_snapshot.sql"; do
    [[ -f $archivo && -r $archivo ]] || error_entorno "Falta $archivo"
done
DB=$(realpath -e -- "$1") || error_entorno 'No se pudo resolver la base'
printf 'Base original (solo lectura): %s\n' "$DB"
printf 'Bash: %s\nSQLite: %s\n' "$BASH_VERSION" "$(sqlite3 --version)"

seccion 'b/c/f: correspondencia, catálogo, integridad'
nuevo_directorio
bcf=$trabajo
(cd "$DIR" && sqlite3 -readonly -batch "$DB" < "$SQL") > "$bcf/consultas.out" 2> "$bcf/consultas.err"
rc_sql=$?
mostrar 'stdout consultas' "$bcf/consultas.out"
mostrar 'stderr consultas' "$bcf/consultas.err"
esperadas=$(grep -c 'iif(' "$SQL")
ok=$(grep -c ' | OK$' "$bcf/consultas.out")
mal=$(grep -c ' | FALLA$' "$bcf/consultas.out")
printf 'Código esperado=0 observado=%s; comprobaciones esperadas=%s OK=%s FALLA=%s; stderr esperado vacío\n' "$rc_sql" "$esperadas" "$ok" "$mal"
resultado=1
if [[ $rc_sql -eq 0 && ! -s $bcf/consultas.err && $esperadas -gt 0 && $ok -eq $esperadas && $mal -eq 0 ]]; then resultado=0; fi
veredicto 'b/c/f SQL' "$resultado"

seccion 'b: correspondencia con servidor sin modificarlo'
# No iniciar el contenedor ni ejecutar mutaciones de PostgreSQL.
resultado=1
if ! command -v docker > /dev/null; then
    echo 'FALLA: docker no está disponible; no se puede consultar el servidor.'
    echo 'Código COPY esperado=0 observado=no ejecutado'
else
    docker inspect --format '{{.State.Running}}' foodstore-u8-postgres > "$bcf/contenedor.out" 2> "$bcf/contenedor.err"
    rc_estado=$?
    estado=$(< "$bcf/contenedor.out")
    printf 'Código inspect esperado=0 observado=%s; estado esperado=true observado=%s\n' "$rc_estado" "$estado"
    mostrar 'diagnóstico inspect' "$bcf/contenedor.err"
    if [[ $rc_estado -eq 0 && ! -s $bcf/contenedor.err && $estado == true ]]; then
        docker exec foodstore-u8-postgres psql -X -q -U postgres -d foodstore_u8 -c "COPY (SELECT producto_id, nombre, precio_centavos, stock, disponible, eliminado FROM v_snapshot_movil ORDER BY producto_id) TO STDOUT WITH (FORMAT csv)" > "$bcf/servidor.csv" 2> "$bcf/servidor.err"
        rc_servidor=$?
        tail -n +2 "$CSV" | cut -d, -f1-6 > "$bcf/exportado.csv"
        rc_csv=$?
        printf 'Código COPY esperado=0 observado=%s; extracción CSV esperada=0 observada=%s\n' "$rc_servidor" "$rc_csv"
        mostrar 'diagnóstico COPY' "$bcf/servidor.err"
        if [[ $rc_servidor -eq 0 && $rc_csv -eq 0 && ! -s $bcf/servidor.err ]]; then
            if cmp -s -- "$bcf/exportado.csv" "$bcf/servidor.csv"; then resultado=0; else diff -u -- "$bcf/exportado.csv" "$bcf/servidor.csv"; fi
        fi
    else
        echo 'FALLA: contenedor no disponible/en ejecución; no se inicia.'
        echo 'Código COPY esperado=0 observado=no ejecutado'
    fi
fi
veredicto 'b servidor: seis columnas idénticas byte a byte' "$resultado"

seccion 'd: repetir renovación válida sobre copia'
nuevo_directorio
cp -- "$DB" "$trabajo/copia.db" || error_entorno 'No se pudo copiar la base'
dump_datos "$trabajo/copia.db" "$trabajo" antes
rc_antes=$?
ejecutar_renovacion "$CSV" "$META"
printf 'Código renovación esperado=0 observado=%s\n' "$rc_renovar"
dump_datos "$trabajo/copia.db" "$trabajo" despues
rc_despues=$?
comparar_dumps "$trabajo"
rc_comparacion=$?
resultado=1
if [[ $rc_renovar -eq 0 && $rc_antes -eq 0 && $rc_despues -eq 0 && $rc_comparacion -eq 0 && ! -s $trabajo/renovar.err ]] \
    && grep -qxF 'Resultado renovación: OK' "$trabajo/renovar.out"; then resultado=0; fi
veredicto 'd renovación repetible' "$resultado"

for variante in e1 e2; do
    seccion "$variante: importación inválida y reversión comprobada"
    nuevo_directorio
    cp -- "$DB" "$trabajo/copia.db" || error_entorno 'No se pudo copiar la base'
    cp -- "$CSV" "$trabajo/original.csv" || error_entorno 'No se pudo copiar el CSV'
    cp -- "$META" "$trabajo/original.meta" || error_entorno 'No se pudieron copiar los metadatos'
    alteracion=1
    if [[ $variante == e1 ]]; then
        sed '/^5,/s/,t,f,/,x,f,/' "$trabajo/original.csv" > "$trabajo/servidor_snapshot.csv" || error_entorno 'No se pudo alterar el CSV'
        # El campo alterado es disponible del producto 5, no otro texto.
        n_original=$(grep -c '^5,[^,]*,[0-9]*,[0-9]*,t,f,' "$trabajo/original.csv")
        n_alterado=$(grep -c '^5,[^,]*,[0-9]*,[0-9]*,x,f,' "$trabajo/servidor_snapshot.csv")
        if [[ $n_original -eq 1 && $n_alterado -eq 1 ]] && ! cmp -s -- "$trabajo/original.csv" "$trabajo/servidor_snapshot.csv"; then alteracion=0; fi
        printf 'Alteración esperada: producto 5 disponible t→x; filas originales coincidentes=%s alteradas=%s\n' "$n_original" "$n_alterado"
    else
        sed '$d' "$trabajo/original.csv" > "$trabajo/servidor_snapshot.csv" || error_entorno 'No se pudo quitar la última fila'
        n_original=$(wc -l < "$trabajo/original.csv")
        n_alterado=$(wc -l < "$trabajo/servidor_snapshot.csv")
        if [[ $n_original -eq 10 && $n_alterado -eq 9 ]] && ! cmp -s -- "$trabajo/original.csv" "$trabajo/servidor_snapshot.csv"; then alteracion=0; fi
        printf 'Alteración esperada: última fila retirada (líneas 10→9); observado=%s→%s\n' "$n_original" "$n_alterado"
    fi
    veredicto "$variante preparación de la copia alterada" "$alteracion"
    # Mantener nueve como expectativa: la huella coincide con la copia
    # alterada, de modo que el rechazo DEBE ocurrir dentro de la renovación.
    huella=$(sha256sum < "$trabajo/servidor_snapshot.csv") || error_entorno 'No se pudo calcular SHA-256'
    huella=${huella%% *}
    sed -e 's/^filas=.*/filas=9/' -e "s/^sha256_csv=.*/sha256_csv=$huella/" \
        "$trabajo/original.meta" > "$trabajo/servidor_snapshot_meta.txt" || error_entorno 'No se pudo preparar meta alterado'
    dump_datos "$trabajo/copia.db" "$trabajo" antes
    rc_antes=$?
    ejecutar_renovacion "$trabajo/servidor_snapshot.csv" "$trabajo/servidor_snapshot_meta.txt"
    printf 'Código renovación esperado=1 observado=%s; diagnóstico esperado no vacío\n' "$rc_renovar"
    # El coordinador muestra el stderr de sqlite3 en stdout; se comprueba el
    # diagnóstico de restricción concreto, no solo su mensaje final FALLA.
    diagnostico=1
    if [[ $variante == e1 ]]; then
        if grep -F 'CHECK constraint failed: disponible IN' "$trabajo/renovar.out"; then diagnostico=0; fi
    else
        if grep -F 'CHECK constraint failed: ok = 1' "$trabajo/renovar.out" \
            && grep -qxF 'filas_importadas | FALLA' "$trabajo/renovar.out"; then diagnostico=0; fi
    fi
    dump_datos "$trabajo/copia.db" "$trabajo" despues
    rc_despues=$?
    comparar_dumps "$trabajo"
    rc_comparacion=$?
    resultado=1
    if [[ $alteracion -eq 0 && $rc_renovar -eq 1 && $diagnostico -eq 0 && $rc_antes -eq 0 && $rc_despues -eq 0 && $rc_comparacion -eq 0 ]] \
        && ! grep -qxF 'RENOVACION CONFIRMADA' "$trabajo/renovar.out"; then resultado=0; fi
    veredicto "$variante rechazo con snapshot y catálogo intactos" "$resultado"
done

seccion 'Resumen'
if [[ $fallos -eq 0 ]]; then echo 'RESULTADO GLOBAL: OK'; else echo 'RESULTADO GLOBAL: FALLA'; fi
echo 'Todos los directorios temporales indicados se conservan; la base original no se renovó.'
exit "$fallos"
