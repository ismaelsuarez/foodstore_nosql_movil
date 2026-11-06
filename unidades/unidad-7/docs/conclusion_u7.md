# Conclusión — Unidad 7 (consigna 7)

> **Propuesta pendiente de revisión del equipo.** La redactó el asistente de IA
> el 2026-11-06 y se ajustó ese mismo día. No consta todavía una aprobación
> formal del equipo, y no es una aprobación docente.

<!-- cuerpo -->
Proponemos mantener PostgreSQL como fuente principal de los pedidos y usar MongoDB solo como copia documental de lectura de este subconjunto, si el acceso al pedido completo lo justifica.

Integridad: en PostgreSQL, las claves foráneas y las restricciones CHECK rechazan en cada escritura líneas sin producto o cantidades no positivas, y los disparadores del TPI mantienen el total agregado, con límites declarados. En la colección, RI-01 y RI-02 se verificaron con scripts después de la carga; no se instalaron validadores permanentes.

Forma de acceso: cada documento contiene cliente e items, devuelve el pedido completo en una sola lectura y se escribe de forma atómica por documento, no por lote. Se conservaron IDs Long, cantidades Int32, importes Decimal128 y precios históricos; C4b y C4c devolvieron los mismos pedidos en ambos motores.

Duplicación: los nombres de cliente y de producto son copias; la coincidencia entre motores se verificó el 2026-11-06 y no implica sincronización.

El lote tiene cinco pedidos, un solo estado y ninguna baja lógica, y no se midió rendimiento. Ampliar el uso de MongoDB exigiría pruebas con más volumen y una carga reproducible desde el origen.
<!-- /cuerpo -->

---

**Conteo de palabras del cuerpo:** 186. Límite de la consigna: 200.
Se cuenta el texto entre los marcadores `cuerpo` con `wc -w`.

**Versiones:**

- Primera versión del 2026-11-06: 183 palabras.
- Versión ajustada del mismo día, que precisa la atribución de los disparadores
  al TPI y la atomicidad por documento.

Fundamento: [contraste de IA](contraste_ia.md) y
[laboratorio](laboratorio_migracion.md).
