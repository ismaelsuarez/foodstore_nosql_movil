# AGENTS.md — Food Store NoSQL / Bases de Datos II (U7–U8)

## Propósito

Proyecto académico de UTN que extiende el trabajo relacional de U1–U6 hacia el
modelo documental (U7) y temas futuros (U8). El origen de los datos es el
repositorio `foodstore_baseII` en la etiqueta `u6-cierre`.

## Reglas de trabajo

1. **Seguir la consigna y el modelo de origen verificado.** Los campos, tipos,
   estados y relaciones del modelo MongoDB deben derivarse de `schema.sql` y
   `datos_iniciales.sql` del repositorio relacional, no de ejemplos genéricos.

2. **No modificar el repositorio relacional ni sus datos.** El repositorio
   `foodstore_baseII` y la etiqueta `u6-cierre` son de solo lectura desde este
   proyecto. No hacer commits, staging ni cambios en ese árbol.

3. **PostgreSQL es el origen; MongoDB representa el subconjunto de U7.**
   La colección `pedidos` en MongoDB contiene una representación parcial del
   dominio. No sustituye ni sincroniza automáticamente con PostgreSQL.

4. **Distinguir propuestas, implementación y resultados ejecutados.**
   Un documento de diseño o especificación no es evidencia de ejecución. Ninguna
   afirmación de resultado se hace sin haberlo observado en una ejecución real
   autorizada.

5. **No inventar datos de origen.** Los IDs de pedido, usuario y producto los
   asigna la secuencia de PostgreSQL al instalar el seed; son IDs a comprobar
   mediante lectura del origen existente. Los IDs leídos están registrados en
   `unidades/unidad-7/docs/inventario_origen_entorno.md`. No fijar valores
   supuestos. Los precios históricos de cada línea provienen de `detalle_pedido.precio_unitario` del
   origen, no del precio actual de `producto.precio`.

6. **No copiar contraseñas, hashes ni datos personales reales.** El campo
   `contrasena` del dataset tiene el marcador académico `SEED_NO_AUTH`; no se
   incluye en ningún documento MongoDB. Los mails del seed terminan en
   `.test` y son sintéticos; si se usan, se identifican como tales.

7. **No hacer operaciones destructivas ni publicaciones sin autorización.**
   No hacer push, no borrar el repositorio hermano, no eliminar etiquetas.

8. **Mantener instrucciones reproducibles para el evaluador.** Cualquier secuencia
   de instalación debe poder ejecutarse partiendo del seed mínimo de U6.

9. **No tratar ejemplos de compañeros ni del apunte como especificación oficial.**
   Los nombres `Ana`, `Luis`, `entregado`, `cliente_id` que aparecen en los
   apuntes son ilustrativos. El modelo real usa `usuario`, `TERMINADO`, y los
   campos definidos en `schema.sql`.

## Modelo canónico de origen

Cinco tablas: `categoria`, `usuario`, `producto`, `pedido`, `detalle_pedido`.
Estado `TERMINADO` (ENUM `estado_pedido`). Fecha `DATE` en `pedido.fecha`,
distinta de `created_at TIMESTAMPTZ`. Precio histórico en
`detalle_pedido.precio_unitario`. Total físico en `pedido.total`.

Para el detalle completo ver `schema.sql` del repositorio `foodstore_baseII`.
