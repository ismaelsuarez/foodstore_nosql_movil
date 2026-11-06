# Conclusión — Unidad 7 (consigna 7)

> **Propuesta pendiente de revisión del equipo.** La redactó el asistente de IA
> el 2026-11-06. Ningún integrante la aceptó todavía y no es una aprobación
> docente.

<!-- cuerpo -->
Proponemos mantener PostgreSQL como fuente de verdad y combinarlo con MongoDB solo como proyección de lectura del subconjunto de pedidos, si el acceso al pedido completo lo justifica.

Primer criterio, integridad: en PostgreSQL, las claves foráneas y las restricciones CHECK rechazan en cada escritura líneas sin producto o cantidades no positivas, y los disparadores de U6 mantienen el total. En nuestra colección, RI-01 y RI-02 se verificaron con scripts después de la carga; no instalamos validadores permanentes.

Segundo criterio, modelo de acceso: el documento con cliente e items embebidos devuelve un pedido completo en una sola lectura y se escribe de forma atómica por documento. Conservamos IDs Long, cantidades Int32, importes Decimal128 y precios históricos; C4b y C4c devolvieron los mismos pedidos en ambos motores.

Tercer criterio, duplicación: los nombres de cliente y de producto son copias, y la coincidencia entre motores es una verificación del 2026-11-06, no una sincronización.

El lote tiene cinco pedidos, un solo estado y ninguna baja lógica, y no medimos rendimiento. Extender el uso de MongoDB exigiría pruebas con más volumen y una carga reproducible desde el origen.
<!-- /cuerpo -->

---

**Conteo de palabras del cuerpo:** 183. Límite de la consigna: 200. Se contó el
texto entre los marcadores `cuerpo` con `wc -w` el 2026-11-06.

Fundamento: [contraste de IA](contraste_ia.md) y
[laboratorio](laboratorio_migracion.md).
