// Food Store U7 — Carga del lote extraído en foodstore_u7.pedidos.
//
// Uso (Bash, desde la raíz del repositorio; ver docs/laboratorio_migracion.md):
//   docker exec -e U7_OPERADOR_PASSWORD_FILE=/run/foodstore-u7-auth/u7_operador.pwd \
//     foodstore-u7-mongo9 mongosh --quiet --norc mongodb://127.0.0.1:27017 \
//     /u7/mongodb/migracion_pedidos.js
//
// Lee el archivo de intercambio (U7_JSON o /u7/datos/pedidos_origen.json);
// no contiene los pedidos en el código. Tipos según design.md §3:
// IDs Long desde texto, cantidad Int32 e importes Decimal128 desde texto.
//
// Códigos de salida:
//   0 carga completa y reconocida
//   2 entrada o destino inválidos (no se escribió nada)
//   3 algún _id del lote ya existe (carga rechazada antes de escribir)
//   4 fallo durante insertMany (puede haber una carga parcial; no se limpia
//     ni se reintenta)

const fs = require('fs');

const LOTE = ['1', '2', '3', '4', '5'];
const RUTA_JSON = process.env.U7_JSON || '/u7/datos/pedidos_origen.json';
const ID = /^[1-9][0-9]{0,18}$/;
const IMPORTE = /^[0-9]{1,10}\.[0-9]{2}$/; // NUMERIC(12,2) no negativo
const CANTIDAD = /^[1-9][0-9]{0,9}$/;
const FECHA = /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/;
const ESTADOS = ['PENDIENTE', 'CONFIRMADO', 'TERMINADO', 'CANCELADO'];
const FORMAS_PAGO = ['EFECTIVO', 'TARJETA', 'TRANSFERENCIA'];

// 1. Sesión autenticada como u7_operador. La contraseña se lee de un archivo
//    y nunca aparece en el código ni en la línea de comandos.
const archivoClave = process.env.U7_OPERADOR_PASSWORD_FILE;
if (!archivoClave) {
  print('ERROR: falta U7_OPERADOR_PASSWORD_FILE');
  quit(2);
}
const destino = db.getSiblingDB('foodstore_u7');
destino.auth('u7_operador', fs.readFileSync(archivoClave, 'utf8').trim());

// 2. Validación del archivo de intercambio antes de cualquier escritura.
//    Los importes se comparan en centavos con BigInt: nunca con Number.
const centavos = (texto) => BigInt(texto.replace('.', ''));
const errores = [];
const exigir = (condicion, mensaje) => { if (!condicion) errores.push(mensaje); };

let datos;
try {
  datos = JSON.parse(fs.readFileSync(RUTA_JSON, 'utf8'));
} catch (e) {
  print(`ERROR: no se pudo leer ${RUTA_JSON}: ${e.message}`);
  quit(2);
}
const esperado = datos.expectativas_inventario || {};
exigir(datos.formato === 'foodstore-u7-pedidos/1', 'formato desconocido');
exigir(JSON.stringify(datos.lote) === JSON.stringify(LOTE), 'el lote del archivo no es el aprobado');
exigir(Array.isArray(datos.pedidos), 'falta el arreglo pedidos');

const pedidos = Array.isArray(datos.pedidos) ? datos.pedidos : [];
const totalLineas = pedidos.reduce((n, p) => n + (Array.isArray(p.items) ? p.items.length : 0), 0);
exigir(JSON.stringify(pedidos.map((p) => p.pedido_id)) === JSON.stringify(LOTE),
  'los pedidos del archivo no coinciden con el lote, en orden');
exigir(pedidos.length === esperado.pedidos,
  `pedidos: ${pedidos.length}; inventario: ${esperado.pedidos}`);
exigir(totalLineas === esperado.lineas,
  `líneas: ${totalLineas}; inventario: ${esperado.lineas}`);

const detallesVistos = new Set();
for (const p of pedidos) {
  const ref = `pedido ${p.pedido_id}`;
  exigir(ID.test(p.pedido_id), `${ref}: pedido_id inválido`);
  exigir(FECHA.test(p.fecha), `${ref}: fecha no es YYYY-MM-DD`);
  exigir(ESTADOS.includes(p.estado), `${ref}: estado fuera del ENUM`);
  exigir(FORMAS_PAGO.includes(p.forma_pago), `${ref}: forma_pago fuera del ENUM`);
  exigir(IMPORTE.test(p.total), `${ref}: total inválido`);
  exigir(typeof p.eliminado === 'boolean', `${ref}: eliminado no es booleano`);
  exigir(p.usuario && ID.test(p.usuario.usuario_id), `${ref}: usuario_id inválido`);
  exigir(p.usuario && typeof p.usuario.nombre === 'string' && p.usuario.nombre !== '', `${ref}: falta nombre`);
  exigir(p.usuario && typeof p.usuario.apellido === 'string' && p.usuario.apellido !== '', `${ref}: falta apellido`);
  exigir(Array.isArray(p.items), `${ref}: items no es un arreglo`);

  let sumaVigentes = 0n;
  for (const i of (Array.isArray(p.items) ? p.items : [])) {
    const refLinea = `${ref}, detalle ${i.detalle_id}`;
    exigir(ID.test(i.detalle_id) && !detallesVistos.has(i.detalle_id), `${refLinea}: detalle_id inválido o repetido`);
    detallesVistos.add(i.detalle_id);
    exigir(ID.test(i.producto_id), `${refLinea}: producto_id inválido`);
    exigir(typeof i.producto_nombre === 'string' && i.producto_nombre !== '', `${refLinea}: falta producto_nombre`);
    exigir(typeof i.eliminado === 'boolean', `${refLinea}: eliminado no es booleano`);
    // RI-01: cantidad entera positiva (Int32) e importes no negativos.
    const cantidadValida = CANTIDAD.test(i.cantidad) && BigInt(i.cantidad) <= 2147483647n;
    const importesValidos = IMPORTE.test(i.precio_unitario) && IMPORTE.test(i.subtotal);
    exigir(cantidadValida, `${refLinea}: RI-01 cantidad inválida`);
    exigir(importesValidos, `${refLinea}: RI-01 importe inválido`);
    if (cantidadValida && importesValidos) {
      // RI-02: subtotal = cantidad × precio histórico.
      exigir(centavos(i.subtotal) === BigInt(i.cantidad) * centavos(i.precio_unitario),
        `${refLinea}: RI-02 subtotal incoherente`);
      if (i.eliminado === false) sumaVigentes += centavos(i.subtotal);
    }
  }
  // RI-02: total = suma de subtotales de líneas no eliminadas, o cero.
  if (IMPORTE.test(p.total)) {
    exigir(centavos(p.total) === sumaVigentes, `${ref}: RI-02 total incoherente`);
  }
}

if (errores.length > 0) {
  print(`ERROR: el archivo no supera la validación (${errores.length}); no se escribe nada.`);
  errores.forEach((e) => print(`  - ${e}`));
  quit(2);
}
print(`archivo=${RUTA_JSON} pedidos=${pedidos.length} lineas=${totalLineas} validacion=OK`);

// 3. Destino explícito.
const coleccion = destino.getCollection('pedidos');
if (destino.getName() !== 'foodstore_u7' || coleccion.getFullName() !== 'foodstore_u7.pedidos') {
  print(`ERROR: destino inesperado ${coleccion.getFullName()}`);
  quit(2);
}

// 4. Construcción de documentos según design.md §2. El precio de cada línea
//    es el histórico extraído, nunca el precio actual del producto.
const documentos = pedidos.map((p) => ({
  _id: NumberLong(p.pedido_id),
  fecha: p.fecha,
  estado: p.estado,
  forma_pago: p.forma_pago,
  total: NumberDecimal(p.total),
  eliminado: p.eliminado,
  usuario: {
    usuario_id: NumberLong(p.usuario.usuario_id),
    nombre: p.usuario.nombre,
    apellido: p.usuario.apellido
  },
  items: p.items.map((i) => ({
    detalle_id: NumberLong(i.detalle_id),
    producto_id: NumberLong(i.producto_id),
    producto_nombre: i.producto_nombre,
    cantidad: NumberInt(parseInt(i.cantidad, 10)), // validada arriba como Int32
    precio_unitario: NumberDecimal(i.precio_unitario),
    subtotal: NumberDecimal(i.subtotal),
    eliminado: i.eliminado
  }))
}));
const ids = documentos.map((d) => d._id);

// 5. Repetición: si algún _id del lote ya existe, se rechaza sin escribir.
//    El índice único de _id sigue protegiendo ante una colisión posterior.
const existentes = coleccion.find({ _id: { $in: ids } }, { _id: 1 }).sort({ _id: 1 }).toArray();
if (existentes.length > 0) {
  print(`RECHAZADO: ya existen los pedidos ${existentes.map((d) => d._id.toString()).join(',')}; no se inserta nada.`);
  quit(3);
}

// 6. Inserción con reconocimiento en el diario. insertMany no es atómico para
//    el lote: en modo ordenado se detiene en el primer error y lo insertado
//    antes permanece.
try {
  const resultado = coleccion.insertMany(documentos, { ordered: true, writeConcern: { w: 1, j: true } });
  const insertados = Object.keys(resultado.insertedIds).length;
  print(`insertMany acknowledged=${resultado.acknowledged} insertados=${insertados}`);
  if (!resultado.acknowledged || insertados !== documentos.length) quit(4);
} catch (e) {
  print('ERROR durante insertMany; no se limpia ni se reintenta.');
  print(`  mensaje=${e.message}`);
  print(`  pedidos_del_lote_presentes=${coleccion.countDocuments({ _id: { $in: ids } })}`);
  quit(4);
}
