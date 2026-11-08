# Inventario de la revisión de scripts — U1 a U8

Complemento de [revision_scripts_ia.md](revision_scripts_ia.md) para la
consigna 3.c. Para cada script se registra la ruta, el blob de Git
(prefijo), el propósito, el resultado de la lectura, la evidencia de
ejecución que existe y lo que quede pendiente. Las hipótesis nuevas se
clasifican al final; no se ensayaron.

## Cómo se hizo

- **U1–U6:** referencia `u6-cierre` de `foodstore_baseII`
  (`8f7877c8a1ff25c1be28b29c46c38cd7c9663e86`).
  - El 2026-11-07 se comprobó que los 84 scripts de `unidades/` y de
    `tpi/pruebas/` del árbol de trabajo tienen el mismo blob que en
    `u6-cierre` (`git hash-object` contra `git ls-tree`: 0 diferencias). Por
    eso se leyeron desde el árbol de trabajo, sin cambiar el checkout. No se
    inspeccionó `odd/`.
  - Hecho por tres subagentes de exploración de solo lectura
    (`gentle-ai-explore`), que leyeron cada archivo completo. La sesión
    principal de Claude volvió a leer con `git show` una muestra de los
    fragmentos citados, no todas las filas:
    `unidad-2/tp3/sql/carga_masiva_tp3.sql:25`,
    `unidad-1/tp2/sql/restricciones_integridad.sql`,
    `unidad-5/sql/roles.sql:65–69`,
    `unidad-5/poc_permisos/sql/09_p8_limpieza.sql:20–21` con su salida
    archivada, y `unidad-5/poc_permisos/run_poc.sh:65`.
  - Los **84 scripts** son `tpi/pruebas/` (8) + U1 (1) + U2 (8) +
    U3 (5) + U4 (6) + U5 (51) + U6 (5). No incluyen los 4 de raíz y
    `tpi/sql/`, los 5 de U7 ni los 27 de U8: 84 + 4 + 5 + 27 = 120.
    El cotejo de blobs acredita identidad de versión, no por sí solo una
    revisión de contenido; la lectura se registra por separado.
  - La lectura completa de `tpi/sql/consultas_cobertura_tpi.sql` fue hecha
    por **ChatGPT/Mila**, vía conector GitHub fijando el commit de
    `u6-cierre`, y comunicada en esta conversación. El complemento cotejó
    el blob local en esa etiqueta: `1c5bb99ef73492e9cff364bcdfdde91c8906b095`.
    No se atribuye a la sesión principal de Claude ni a revisión humana.
  - Ninguna de estas lecturas es una revisión humana.
- **U7:** referencia `u7-cierre` (`703583e2…`).
- **U8:** archivos actuales, identificados por su huella SHA-256 (ver
  `evidencias/bloque_d_cierre_20261107_195631.txt`).
- No se ejecutó ningún script ni ningún motor.
- **«Sin observaciones nuevas»** significa que el archivo se leyó completo y
  no surgió nada que agregar a lo que ya documenta su unidad.

## Totales

| Unidad | Scripts | Leídos completos | Pendientes |
|---|---:|---:|---|
| Raíz + `tpi/sql/` | 4 | 4 (3 de instalación + lectura comunicada de ChatGPT/Mila) | — |
| `tpi/pruebas/` | 8 | 8 | — |
| U1 | 1 | 1 | — |
| U2 | 8 | 8 | — |
| U3 | 5 | 5 | — |
| U4 | 6 | 6 | — |
| U5 | 51 | 51 | — |
| U6 | 5 | 5 | — |
| U7 | 5 | por correspondencia con la auditoría U7 (ver §8) | — |
| U8 | 27 | 27 (escritos y ejecutados en los bloques B–D) | — |
| **Total** | **120** | **115 leídos completos + 5 por correspondencia histórica U7** | **0** |

Comprobación contra las filas: 4 + 84 + 27 = **115 lecturas completas**;
115 + 5 correspondencias históricas U7 = **120**. U7 no se cuenta como una
lectura actual nueva: la igualdad de huellas prueba identidad de versión,
no una revisión de contenido por sí sola.

Rutas de U1–U6 relativas a `foodstore_baseII/`.

## 1. Raíz y TPI

| Blob | Ruta | Propósito | Resultado | Evidencia | Pendiente |
|---|---|---|---|---|---|
| 9047b6fefc | `schema.sql` | Modelo canónico | Leído y reinstalado en U8 | `unidad-8/evidencias/bloque_c_postgresql_20261107_125121.txt` | — |
| ee9bb62cd6 | `datos_iniciales.sql` | Seed | Leído y reinstalado; dos consultas de verificación con 0 filas | ídem | — |
| 668b48c1f8 | `tpi/sql/objetos_programables.sql` | Triggers, funciones, `registrar_detalle_pedido` | Leído y reinstalado | ídem | — |
| 1c5bb99ef7 | `tpi/sql/consultas_cobertura_tpi.sql` | Consultas de cobertura del TPI | Leído completo por ChatGPT/Mila; sin inconsistencia estática respecto de su propósito (ver detalle debajo) | Lectura vía conector GitHub fijando `u6-cierre`, comunicada en esta conversación; blob local de la etiqueta cotejado en el complemento E | — |
| 8a1e0d4738 | `tpi/pruebas/pruebas_objetos_programables.sql` | Pruebas de objetos y atomicidad | `DELETE` de fixtures dentro de una transacción revertida; la concurrencia queda fuera | `tpi/evidencia_modelo_oficial.md:107,125` | — |
| 9ae6951d1b | `tpi/pruebas/transacciones/auditoria.sql` | Auditoría de datos y catálogo | Sin observaciones nuevas; usa el id 1, verificado por `guard.sql` | `tpi/evidencia_cierre_objetivo_8.md:215` | — |
| 44102af34e | `tpi/pruebas/transacciones/guard.sql` | Precondiciones del laboratorio | Comprueba el id 1 por nombre, stock y vigencia | `tpi/evidencia_cierre_objetivo_8.md:82` | — |
| 3ae0998306 | `tpi/pruebas/transacciones/rr_a.sql` | Snapshot en REPEATABLE READ | Sin observaciones nuevas; requiere el intercalado del arnés | `…objetivo_8.md:140` | — |
| efadb7c0fa | `tpi/pruebas/transacciones/rr_b.sql` | Cambio concurrente confirmado | Sin observaciones nuevas; la restauración la hace el arnés | `…objetivo_8.md:141` | — |
| fe53478636 | `tpi/pruebas/transacciones/savepoint.sql` | Reversión parcial | `ROLLBACK` final sobre la fixture | `…objetivo_8.md:99` | — |
| ad6eee013d | `tpi/pruebas/transacciones/serial_a.sql` | Escritura SERIALIZABLE | Sin observaciones nuevas; la restauración es externa | `…objetivo_8.md:165` | — |
| d18a5135ef | `tpi/pruebas/transacciones/serial_b.sql` | Conflicto SERIALIZABLE | Sin observaciones nuevas; no reintenta (es el objetivo de la prueba) | `…objetivo_8.md:171` | — |

### Lectura comunicada de `consultas_cobertura_tpi.sql`

Procedencia: **ChatGPT/Mila**, conector GitHub con commit U6 fijado a
`8f7877c8a1ff25c1be28b29c46c38cd7c9663e86`, comunicada en esta conversación;
no sesión principal de Claude ni revisión humana. Blob cotejado localmente:
`1c5bb99ef73492e9cff364bcdfdde91c8906b095`.

- Contiene dos consultas de lectura, sin modificación de datos o esquema.
- La primera agrupa pedidos no eliminados por usuario y aplica `HAVING`,
  sin multiplicar pedidos mediante una unión al detalle.
- La segunda agrega importes por usuario antes de aplicar `RANK`; conserva
  empates y estabiliza la presentación con `id`.
- Usa el modelo canónico `usuario`/`pedido` y advierte que las consultas
  históricas de U2 no son automáticamente compatibles con el modelo vigente.
- No se encontró inconsistencia estática respecto de ese propósito.
- **No se ejecutó en PostgreSQL ni se comprobaron resultados. No se
  verificaron todos sus enlaces relativos.** El cotejo local del blob no
  equivale a repetir esa revisión de contenido.

Registro: `evidencias/bloque_e_complemento_20261107_212101.txt`.

## 2. U1 y U2

| Blob | Ruta | Propósito | Resultado | Evidencia | Pendiente |
|---|---|---|---|---|---|
| 9c5cd1887b | `unidades/unidad-1/tp2/sql/restricciones_integridad.sql` | CHECK de `detalle_pedido` | Los dos nombres de restricción ya existen en `schema.sql`; volver a aplicarlo sobre el modelo canónico fallaría (N3) | no localizada | — |
| 12c979ce16 | `unidades/unidad-2/tp3/sql/carga_masiva_tp3.sql` | Volumen de laboratorio | Usa `cliente`, `activo` y `cliente_id`, que no existen en `schema.sql` (N1). Transacción externa declarada en las líneas 6–12 | no localizada | — |
| 82413a9ff4 | `unidades/unidad-2/tp3/sql/consulta_a_alternativa.sql` | Productos por categoría | Usa `activo` (N1) | `unidad-2/tp3/informes/informe_consultas_tp3.md:110` | — |
| 95c5aae559 | `unidades/unidad-2/tp3/sql/consulta_b_correlacionada_optimizada.sql` | Precio frente al promedio (LATERAL) | Usa `activo` (N1) | no localizada | — |
| f549f09c7a | `unidades/unidad-2/tp3/sql/consultas_tp3_alternativas.sql` | Precio frente al promedio agrupado | Usa `activo` (N1) | `informe_consultas_tp3.md:404` | — |
| d461fca919 | `unidades/unidad-2/tp3/sql/consultas_tp3_ia.sql` | Consultas TP3 propuestas por IA | Usa `activo` (N1) | `informe_consultas_tp3.md:110` | — |
| 030504f86f | `unidades/unidad-2/tp4/sql/consulta_a_tp4_alternativa.sql` | Gasto por cliente | Usa `cliente` y `cliente_id` (N1); no filtra detalles dados de baja (N2) | `unidad-2/tp4/informes/informe_consultas_tp4.md:134` | — |
| 32c0c91a30 | `unidades/unidad-2/tp4/sql/consulta_b_tp4_alternativa.sql` | Facturación por categoría | Usa `activo` (N1); no filtra bajas (N2) | `informe_consultas_tp4.md:332` | — |
| 4ef1768b70 | `unidades/unidad-2/tp4/sql/consultas_tp4_ia.sql` | Consultas TP4 propuestas por IA | Usa `cliente`, `cliente_id` y `activo` (N1); no filtra bajas (N2) | `informe_consultas_tp4.md:134` | — |

## 3. U3

| Blob | Ruta | Propósito | Resultado | Evidencia | Pendiente |
|---|---|---|---|---|---|
| 0a63095b42 | `unidades/unidad-3/sql/indices.sql` | Índices candidatos | Hallazgo H3 | `unidad-3/informes/evidencia_modelo_oficial.md:207,258,299–300` | — |
| 281142e7c9 | `unidades/unidad-3/sql/materializadas.sql` | Facturación mensual materializada | El índice UNIQUE permite `REFRESH … CONCURRENTLY`; la frecuencia de refresco no está automatizada | `evidencia_modelo_oficial.md:571` | — |
| 2134090cdb | `unidades/unidad-3/sql/queries.sql` | Consultas sobre las vistas | Sin observaciones nuevas | `evidencia_modelo_oficial.md:316` | — |
| 738a75c61e | `unidades/unidad-3/sql/seguridad.sql` | Lectura de una vista pública | El GRANT no revoca privilegios previos sobre la tabla base: el efecto depende de los permisos existentes (no se contrastó con U5) | `evidencia_modelo_oficial.md:513` | — |
| c6709a3d49 | `unidades/unidad-3/sql/views.sql` | Vistas del modelo | `CREATE OR REPLACE VIEW` no sirve para cambios incompatibles de columnas (límite conocido del motor) | `evidencia_modelo_oficial.md:316` | — |

## 4. U4

| Blob | Ruta | Propósito | Resultado | Evidencia | Pendiente |
|---|---|---|---|---|---|
| 1fd2e60e00 | `unidades/unidad-4/sql/tp_fnbc_control_lote.sql` | Descomposición FNBC | Usa los usuarios 1 y 2 de la fixture; reconoce que la dependencia R1 no se preserva localmente | `unidad-4/informes/evidencia_revalidacion_fnbc_modelo_canonico.md:113` | — |
| 3542e92cac | `unidades/unidad-4/sql/carga_laboratorio_parte2_modelo_canonico.sql` | Dataset controlado | Ids explícitos y `setval` después del COMMIT; si se interrumpe, hay que diagnosticar a mano | `evidencia_dataset_parte2_modelo_canonico.md:45` | — |
| 29692a1411 | `unidades/unidad-4/sql/benchmark_baseline_top_categorias_modelo_canonico.sql` | Línea base con caché caliente | Sin observaciones nuevas | `evidencia_baseline_parte2_modelo_canonico.md:190` | — |
| e23f76c070 | `unidades/unidad-4/sql/tp_desnormalizacion_top_categorias.sql` | Candidato A remediado | Hallazgo H4. API `SECURITY DEFINER` con `search_path` fijo; no adoptado | `evidencia_read_after_decision_modelo_canonico.md:3–4` | — |
| 8877d33ab6 | `unidades/unidad-4/sql/pruebas_candidato_a_modelo_canonico.sql` | Pruebas y concurrencia del candidato | El protocolo S4 documenta el orden inverso que produjo el deadlock (H4) | `evidencia_implementacion_candidato_a_modelo_canonico.md:257` | — |
| 671fd29a67 | `unidades/unidad-4/sql/pruebas_remediacion_serializada_modelo_canonico.sql` | Pruebas de la ruta serializada | Pruebas reversibles; protocolo multisesión aparte | `evidencia_remediacion_serializada_modelo_canonico.md:170` | — |

## 5. U5 — `sql/` y `sql/pruebas/`

`V` = `unidades/unidad-5/validacion_parte_a/20261102T190345Z`.

| Blob | Ruta (`unidades/unidad-5/`) | Propósito | Resultado | Evidencia | Pendiente |
|---|---|---|---|---|---|
| 1a5afbbb0f | `sql/00_precondiciones.sql` | Precondiciones | Rechaza ACL incompatibles; CONNECT y TEMP de PUBLIC quedan para decidir (documentado en la unidad) | `V/12_roles.txt:167` | — |
| 3470bdee53 | `sql/auditoria_test.sql` | Operaciones auditables | Escrituras bajo ROLLBACK | `docs/log_auditoria_prueba.txt:7` | — |
| 974d7af51d | `sql/funciones_seguridad.sql` | Funciones `SECURITY DEFINER` | Las tres fijan `search_path` y revocan PUBLIC | `V/13_funciones.txt:4` | — |
| 922294c167 | `sql/roles.sql` | Roles y privilegios | `UPDATE (celular)` a `rol_propietario_ventas` (N4) | `V/12_roles.txt:172` | — |
| 9bd81bb1fa | `sql/simulacro_incidente.sh` | Orquestar el simulacro | El trap no destruye el contenedor si falla un paso intermedio (N6) | no localizada | — |
| 247a2f4fd2 | `sql/simulacro_incidente.sql` | Acceso indebido y escalamiento | Si el GRANT esperado como fallido prosperara, el script no fallaría solo (N6) | `docs/log_simulacro_anonimizado.txt:15` | — |
| e554a6523c | `sql/usuario_anon.sql` | Tabla seudonimizada | Conserva el `id` original: seudonimiza, no anonimiza (N7) | no localizada | — |
| ef46f97a3f | `sql/pruebas/00_destino.sql` | Base y versión de destino | Sin observaciones nuevas | `V/23_login_reportes.txt:2` | — |
| a85465ea8a | `sql/pruebas/00_guardas.sql` | Exigir superusuario para el setup | Sin observaciones nuevas | no localizada | — |
| c07680b8bf | `sql/pruebas/00_guardas_credenciales.sql` | Controles previos de credenciales | Sin observaciones nuevas | no localizada | — |
| 0d0df2f4c9 | `sql/pruebas/00_helpers.sql` | Auxiliares de aserción | Adaptación declarada de la POC; contenido distinto del de `poc_permisos/sql/00_helpers.sql` (blobs distintos) | no localizada | — |
| 1915919043 | `sql/pruebas/01_f0.sql` | Inventario previo | Sin observaciones nuevas | `V/11_f0.txt:19` | — |
| 681f754bfc | `sql/pruebas/02_f1.sql` | Huella posterior frente a F0 | Sin observaciones nuevas | `V/14_f1.txt:20` | — |
| 93ae38025a | `sql/pruebas/10_catalogo.sql` | Atributos, membresías y definers | CONNECT y TEMP solo se inventarían | `V/15_catalogo.txt:30` | — |
| 7a21829f07 | `sql/pruebas/11_matriz.sql` | Matriz de ACL esperadas | Sin observaciones nuevas | `V/16_matriz.txt:53` | — |
| e70ae851c1 | `sql/pruebas/12_reservar_ids.sql` | Reservar ids | `nextval` deja huecos aunque haya ROLLBACK (comportamiento normal) | `V/18_reservar_ids.txt:8` | — |
| 90dd4a7d18 | `sql/pruebas/13_fixtures.sql` | Fixtures sintéticas | La transacción la abre el llamante | `V/19_permisos.txt:16` | — |
| cdfdb5583b | `sql/pruebas/14_identidades.sql` | Identidades efímeras | Comprueba colisiones de nombres | `V/21_credenciales.txt:51` | — |
| e004572763 | `sql/pruebas/15_limpieza.sql` | Retirar identidades | `DROP OWNED` / `DROP ROLE` sin guarda propia; depende del llamante. No ejecutar suelto | `V/27_limpiar_logins.txt:14` | — |
| f8cdd6e502 | `sql/pruebas/16_matriz_efectiva.sql` | Privilegios efectivos | Sin observaciones nuevas | `V/17_matriz_efectiva.txt:10` | — |
| 2c893d443e | `sql/pruebas/20_permisos.sql` | Permisos positivos y negativos | Dentro de una transacción revertida | `V/19_permisos.txt:46` | — |
| 93ffbfb190 | `sql/pruebas/30_equivalencia.sql` | Venta canónica frente a API | Dos transacciones revertidas | `V/21_credenciales.txt:1` | — |
| c5441bfa2e | `sql/pruebas/40_credenciales.sql` | Autenticación y reset | Exige controles preventivos y parámetros enlazados | `V/21_credenciales.txt:60` | — |
| bfb54ece28 | `sql/pruebas/49_preparar_logins.sql` | Logins efímeros | El COMMIT deja los roles activos hasta la limpieza posterior (52) | `V/22_preparar_logins.txt:32` | — |
| d9af29605a | `sql/pruebas/50_login_reportes.sql` | Login de reportes | Sin observaciones nuevas | `V/23_login_reportes.txt:8` | — |
| 498e47ffc7 | `sql/pruebas/51_login_soporte.sql` | Login de soporte | Sin observaciones nuevas | `V/24_login_soporte.txt:9` | — |
| 65357b3532 | `sql/pruebas/52_limpiar_logins.sql` | Limpiar logins | Valida la procedencia por OID y la ausencia de conexiones | `V/27_limpiar_logins.txt:45` | — |
| 29f8de6565 | `sql/pruebas/99_cierre.sql` | Cierre de la sesión de control | Sin observaciones nuevas | `V/28_cierre.txt:9` | — |
| d8feea3687 | `sql/pruebas/huella.sql` | Huella temporal del modelo | Basada en la POC; contenido distinto de `poc_permisos/sql/huella.sql` (blobs distintos) | `V/11_f0.txt:15` | — |

## 6. U5 — `poc_permisos/` y `validacion_parte_a/`

`P` = `unidades/unidad-5/poc_permisos`. Los archivos bajo `evidencia/` y
`validacion_parte_a/<fecha>/` son artefactos archivados de ejecuciones.

| Blob | Ruta | Propósito | Resultado | Evidencia | Pendiente |
|---|---|---|---|---|---|
| 5ce244a9c1 | `P/run_poc.sh` | Arnés de la POC | `diff … \|\| true` en la línea 65: el paso no falla si las huellas difieren; el resultado queda en `t14_diff.txt` (N8) | no localizada | — |
| a5d2906b55 | `P/evidencia/arnes_ejecutado/run_poc.sh` | Arnés archivado | Distinto del actual: rutas, salida y comentarios | `P/evidencia/corrida_final/00_instancia.txt:1` | — |
| b3ad12b1c3 | `P/evidencia/intentos_arnes/07_pruebas_intento1.sql` | Primer intento archivado | Distinto de `07_pruebas.sql` (casts booleanos, orden de ACL, filtro de membresías) | `…/07_pruebas_intento1.txt:174` | — |
| 37f9d212ec | `P/sql/00_guarda_sin_roles.sql` | Rechazar roles preexistentes | Sin observaciones nuevas | no localizada | — |
| 5c1f414270 | `P/sql/00_guardas.sql` | Base y versión | Verifica el nombre y la versión, no la identidad de la instancia | no localizada | — |
| 99800ab429 | `P/sql/00_helpers.sql` | Registro de resultados | Un `FAIL` se emite como NOTICE y no aborta: el código de salida no basta (N8) | `…/07_pruebas_intento1.txt:174` | — |
| d6d0c39103 | `P/sql/00_ids.sql` | Resolver ids de la fixture | Busca por nombre y correo sintético, sin ids fijos | no localizada | — |
| 8cf737d215 | `P/sql/01_p0_inventario.sql` | Inventario inicial | Sin observaciones nuevas | `P/evidencia/corrida_final/01_p0_inventario.txt:8` | — |
| e0bf14be73 | `P/sql/02_vp_post_p1.sql` | Inventario tras instalar | Sin observaciones nuevas | `…/02_p1_instalacion.txt:50` | — |
| b10ab16020 | `P/sql/03_p2_fixtures.sql` | Fixtures sintéticas | En una transacción; marcador académico sin autenticación | `…/03_p2_fixtures.txt:21` | — |
| b249d391a8 | `P/sql/04_p3_p4_roles_matriz.sql` | Roles y matriz | Mismo `UPDATE (celular)` que `sql/roles.sql` (N4) | no localizada | — |
| 236c88de30 | `P/sql/05_t12_atomicidad.sql` | Rollback de la API | `SECURITY DEFINER` con `search_path` fijo | `…/05_t12.txt:28` | — |
| 610b720dc6 | `P/sql/06_p5_api.sql` | API de ventas | Creación, dueño y ACL en una transacción | `…/06_p5_api.txt:7` | — |
| 09e5c3b6d1 | `P/sql/07_pruebas.sql` | Pruebas de permisos y ventas | Usa los auxiliares que registran FAIL sin abortar | `…/07_pruebas.txt:32` | — |
| b5047eb352 | `P/sql/08_t07_ablacion.sql` | Ablación de privilegios | Revocaciones dentro de transacciones revertidas | `…/08_t07.txt:27` | — |
| 5a4050a474 | `P/sql/09_p8_limpieza.sql` | Limpieza y verificación | Cuenta todas las membresías del clúster; la salida registra `P8.membresias FAIL` (esperado 0, observado 3). Ya documentado como límite A-3 en `P/README.md:55` | `…/09_p8_limpieza.txt:30` | — |
| 4f1f1b6598 | `P/sql/acl_tablas.sql` | Inventario de ACL | Sin observaciones nuevas | `…/acl_tablas_f1.txt:9` | — |
| a3fc6a2947 | `P/sql/huella.sql` | Huella de catálogo | Excluye a propósito las ACL de tablas (se comparan aparte) | `…/f0_huella.txt:49` | — |
| 5dc772f8a6 | `validacion_parte_a/20261102T185421Z/ejecutar_validacion.py` | Validación archivada | Registra la excepción sin propagarla; podría terminar con código 0 | `…/BLOCKED_o_fallo_runner.txt:1` | — |
| c87e331a7d | `validacion_parte_a/20261102T190345Z/ejecutar_validacion.py` | Validación archivada | Registra los códigos esperados pero no los exige | `…/control_session_exit.txt:1` | — |
| 60433dfd10 | `validacion_parte_a/20261102T191848Z/ejecutar_cierre.py` | Cierre archivado | Cerca de la línea 360, una cadena no cruda contiene `\unset`; en Python, `\u` inicia un escape Unicode y el archivo podría no compilar (N9) | no localizada | — |
| 50d47bf141 | `validacion_parte_a/20261102T191848Z/ejecutar_cierre_v2.py` | Cierre archivado (v2) | Usa literales crudos, que corrigen lo anterior | no localizada | — |

## 7. U6

| Blob | Ruta | Propósito | Resultado | Evidencia | Pendiente |
|---|---|---|---|---|---|
| 52a01a1598 | `unidades/unidad-6/backup_foodstore.sh` | Respaldo con línea base | Hallazgo H2 | `unidad-6/evidencias/ensayo_evaluacion_20261105.txt:64,81–83` | — |
| 95cd0b4348 | `unidades/unidad-6/restore_test.sh` | Restauración de prueba | Hallazgo H1 | `correccion_restauracion_20261105.txt:122–172` | — |
| e42a2f4379 | `unidades/unidad-6/health_check.sql` | Salud de la base | Sin observaciones nuevas | `ensayo_canonico_20261105.txt:318` | — |
| 1ce5380eb3 | `unidades/unidad-6/maintenance.sql` | Diagnóstico y ANALYZE autorizado | Sin observaciones nuevas; no afirma mejoras | `ensayo_canonico_20261105.txt:348` | — |
| 3d98da8f06 | `unidades/unidad-6/validaciones.sql` | Conteos e invariantes | Sin observaciones nuevas | `ensayo_canonico_20261105.txt:101` | — |

## 8. U7 — correspondencia con la auditoría U7

Las huellas SHA-256 de los cinco scripts y del JSON en `u7-cierre` son las
que registra la columna «Al finalizar» de
`unidades/unidad-7/evidencias/README.md` (líneas 24–29, en `u7-cierre`).
Esa columna corresponde a la ejecución con MongoDB 9.0.4.

| Archivo (`unidades/unidad-7/`) | SHA-256 en `u7-cierre` | Evidencia |
|---|---|---|
| `postgresql/extraccion_pedidos.sql` | `e06667ab…` | `evidencias/ejecucion_20261106_mongo9.txt` |
| `postgresql/consultas_postgresql.sql` | `cd8b6af3…` | ídem |
| `mongodb/migracion_pedidos.js` | `36af25b4…` | ídem |
| `mongodb/validaciones_mongodb.js` | `b2d2f960…` | ídem |
| `mongodb/consultas_mongodb.js` | `b9544831…` | ídem |
| `datos/pedidos_origen.json` | `930562ab…` | ídem |

Los tres `.js` cambian entre «Al iniciar» y «Al finalizar» por un ajuste del
comentario de uso, hecho antes de ejecutarlos y documentado en la misma
evidencia.

El cierre de las observaciones de la revisión del ZIP de U7 (R1–R6) consta
en `unidades/unidad-7/docs/bitacora_ia.md` (`u7-cierre`, entrada de cierre,
alrededor de la línea 365). El
documento de revisión original es material interno no versionado (excluido
por `.gitignore`), así que la correspondencia se sostiene en la bitácora y
en las huellas, no en ese documento. No se repitió la auditoría.

## 9. U8

Escritos y ejecutados en los bloques B–D. Las huellas, que coinciden con
los archivos actuales, están en `evidencias/bloque_d_cierre_20261107_195631.txt`
y `evidencias/bloque_e_cierre_20261107_204519.txt`.

| SHA-256 | Archivo | Bloque y evidencia |
|---|---|---|
| `cd3371df…` | `movil/schema_sqlite.sql` | B: `bloque_b_20261107_121805.txt` |
| `2616f7ac…` | `movil/pruebas_sqlite.sql` | B: ídem |
| `cf0cecca…` | `movil/verificar_bloque_b.sh` | B: ídem y `bloque_b_verificacion_registro_20261107_121806.txt` |
| `523f31b8…` | `movil/snapshot_servidor.sql` | C: `bloque_c_sqlite_20261107_130343.txt` |
| `1273c013…` | `movil/renovar_snapshot.sql` | C: ídem |
| `be699c02…` | `movil/consultas_bloque_c.sql` | C: ídem |
| `d806311f…` | `movil/preparar_foodstore_movil.sh` | C: ídem (H5) |
| `b063dec0…` | `movil/verificar_bloque_c.sh` | C: ídem |
| `a2fbec88…`, `97afca55…`, `b5aceb77…`, `6bb56060…`, `e9e0f37c…` | `postgresql/laboratorio_u8.sh`, `datos_auxiliares_u8.sql`, `snapshot_movil.sql`, `exportar_snapshot.sql`, `verificar_instalacion_u8.sql` | C: `bloque_c_postgresql_20261107_125121.txt` |
| `26357673…` | `movil/semaforo.sql` | D: `bloque_d_entregable_*` (H6) |
| `fddeeff8…`, `10801439…`, `22306717…`, `5a23749d…`, `c607185e…`, `7c952fc5…` | `movil/crear_borrador.sql`, `aceptar_precio.sql`, `insertar_solicitud.sql`, `comprobar_caso_d.sql`, `estado_bloque_d.sql`, `simular_producto_ausente.sql` | D: ídem y `bloque_d_controles_copias_20261107_195510.txt` |
| `b301aa8c…`, `90f075bd…`, `52cdd7a6…` | `movil/bloque_d.sh`, `ejecutar_bloque_d.sh`, `controles_d.sh` | D: ídem |
| `2693c27a…`, `d8b3ba75…`, `3f89d553…`, `1427f343…` | `postgresql/preparar_c2_precio.sql`, `preparar_c3_stock.sql`, `preparar_c4_baja.sql`, `control_invariancia.sql` | D: ídem |

## 10. Hipótesis nuevas y su clasificación

Ninguna se ensayó, y ninguna lleva a modificar entregas anteriores. Solo se
propondría una prueba si una conclusión del informe dependiera de ella; por
ahora, ninguna lo hace.

| Id | Unidad | Hipótesis u observación | Clasificación | Fundamento |
|---|---|---|---|---|
| N1 | U2 | Los scripts de TP3 y TP4 usan `cliente`, `cliente_id` y `activo`, que no existen en `schema.sql` del modelo canónico | **Aceptado como límite de compatibilidad**, no como defecto vigente | Comprobado con `schema.sql`: existen `usuario`, `disponible` y `eliminado`, no `cliente` ni `activo`. `unidad-2/tp3/README.md:31` declara que la carga no es parte del esquema base. No se pueden ejecutar sobre el modelo canónico sin adaptarlos |
| N2 | U2 | Las consultas de TP4 suman `detalle_pedido` sin excluir bajas lógicas | **Hipótesis no ensayada** | Depende del esquema de laboratorio de TP4, que no es el canónico (N1). Sin impacto en U8 |
| N3 | U1 | `restricciones_integridad.sql` repite restricciones que `schema.sql` ya trae con el mismo nombre | **Observación sin impacto** | Script histórico de TP2, anterior al modelo canónico; no forma parte de la instalación |
| N4 | U5 | `UPDATE (celular)` a `rol_propietario_ventas` parece un permiso de más | **Descartado como hallazgo nuevo** | Es una decisión documentada (D11, riesgo residual RR-01) en `sql/roles.sql:65–68` y en `docs/kiro_roles_spec/design.md:208`: habilita `FOR SHARE`; el rol es NOLOGIN, sin miembros, y la cadena canónica nunca escribe `celular` |
| N5 | U5 | `P8.membresias` da FAIL | **Antecedente ya documentado** | Límite A-3 en `poc_permisos/README.md:55`: las tres filas son membresías predefinidas de `pg_monitor` |
| N6 | U5 | El simulacro puede dejar el contenedor ante un fallo intermedio, y no falla solo si un GRANT indebido prosperara | **Hipótesis no ensayada** | Lectura de `sql/simulacro_incidente.sh:30,146` y `sql/simulacro_incidente.sql:43–50` |
| N7 | U5 | `usuario_anon.sql` conserva el `id` original | **Observación**: seudonimización, no anonimización | `sql/usuario_anon.sql:16–21` |
| N8 | U5 | En la POC, un FAIL no cambia el código de salida (`RAISE NOTICE`, `diff … \|\| true`) | **Observación de diseño** | El resultado se lee en las líneas `RESULT\|…\|FAIL`, como hace `poc_permisos/README.md` con A-2 y A-3 |
| N9 | U5 | `ejecutar_cierre.py` podría no compilar por `\unset` en una cadena no cruda | **Hipótesis no ensayada**; artefacto archivado, reemplazado por la v2 | No se ejecutó Python ni `py_compile` en esta intervención |
