// Food Store U7 — Validación de la carga sobre los documentos almacenados.
//
// Uso (Bash, desde la raíz del repositorio; ver docs/laboratorio_migracion.md):
//   docker exec -e U7_OPERADOR_PASSWORD_FILE=/run/foodstore-u7-auth/u7_operador.pwd \
//     foodstore-u7-mongo9 mongosh --quiet --norc mongodb://127.0.0.1:27017 \
//     /u7/mongodb/validaciones_mongodb.js
//
// Compara foodstore_u7.pedidos con el archivo de intercambio extraído de
// PostgreSQL. Valida ESTA carga: no instala validadores ni restricciones en el
// servidor, así que no impide escrituras inválidas futuras.
// Importes: aritmética Decimal128 del motor o texto exacto; nunca Number.
// Código de salida: 0 si todas las comprobaciones pasan; 1 si alguna falla.

const fs = require('fs');
const crypto = require('crypto');

const LOTE = ['1', '2', '3', '4', '5'];
const RUTA_JSON = process.env.U7_JSON || '/u7/datos/pedidos_origen.json';

const archivoClave = process.env.U7_OPERADOR_PASSWORD_FILE;
if (!archivoClave) {
  print('ERROR: falta U7_OPERADOR_PASSWORD_FILE');
  quit(1);
}
const destino = db.getSiblingDB('foodstore_u7');
destino.auth('u7_operador', fs.readFileSync(archivoClave, 'utf8').trim());
const pedidos = destino.getCollection('pedidos');

let datos;
try {
  datos = JSON.parse(fs.readFileSync(RUTA_JSON, 'utf8'));
} catch (e) {
  print(`ERROR: no se pudo leer ${RUTA_JSON}: ${e.message}`);
  quit(1);
}

let fallos = 0;
const comprobar = (nombre, ok, detalle) => {
  print(`${ok ? 'OK   ' : 'FALLO'} ${nombre}${detalle ? ` — ${detalle}` : ''}`);
  if (!ok) fallos += 1;
};
const iguales = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const canonico = (valor) => EJSON.stringify(valor, null, 0, { relaxed: false });
const filtroLote = { _id: { $in: LOTE.map((id) => NumberLong(id)) } };

// 1. Conteos del lote.
const almacenados = pedidos.find(filtroLote).sort({ _id: 1 }).toArray();
const lineas = pedidos.aggregate([
  { $match: filtroLote }, { $unwind: '$items' }, { $count: 'n' }
]).toArray();
comprobar('pedidos del lote', almacenados.length === 5, `${almacenados.length}`);
comprobar('líneas del lote', lineas.length === 1 && lineas[0].n === 7, `${lineas.length ? lineas[0].n : 0}`);
print(`info  documentos en la colección: ${pedidos.countDocuments({})}`);

// 2. Identificadores conservados (como texto, ordenados).
const ordenar = (lista) => [...lista].sort((a, b) => Number(BigInt(a) - BigInt(b)));
const deArchivo = {
  pedidos: datos.pedidos.map((p) => p.pedido_id),
  usuarios: ordenar([...new Set(datos.pedidos.map((p) => p.usuario.usuario_id))]),
  detalles: ordenar(datos.pedidos.flatMap((p) => p.items.map((i) => i.detalle_id))),
  productos: ordenar([...new Set(datos.pedidos.flatMap((p) => p.items.map((i) => i.producto_id)))])
};
const deMongo = {
  pedidos: almacenados.map((d) => d._id.toString()),
  usuarios: ordenar([...new Set(almacenados.map((d) => d.usuario.usuario_id.toString()))]),
  detalles: ordenar(almacenados.flatMap((d) => d.items.map((i) => i.detalle_id.toString()))),
  productos: ordenar([...new Set(almacenados.flatMap((d) => d.items.map((i) => i.producto_id.toString())))])
};
for (const clave of Object.keys(deArchivo)) {
  comprobar(`IDs de ${clave}`, iguales(deMongo[clave], deArchivo[clave]), deMongo[clave].join(','));
}

// 3. Tipos BSON con $type. $not también detecta campos ausentes.
const tiposRaiz = pedidos.countDocuments({
  ...filtroLote,
  $or: [
    { _id: { $not: { $type: 'long' } } },
    { fecha: { $not: { $type: 'string' } } },
    { fecha: { $not: /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ } },
    { estado: { $not: { $type: 'string' } } },
    { forma_pago: { $not: { $type: 'string' } } },
    { total: { $not: { $type: 'decimal' } } },
    { eliminado: { $not: { $type: 'bool' } } },
    { 'usuario.usuario_id': { $not: { $type: 'long' } } },
    { 'usuario.nombre': { $not: { $type: 'string' } } },
    { 'usuario.apellido': { $not: { $type: 'string' } } },
    { items: { $not: { $type: 'array' } } }
  ]
});
const tiposLineas = pedidos.countDocuments({
  ...filtroLote,
  items: { $elemMatch: { $or: [
    { detalle_id: { $not: { $type: 'long' } } },
    { producto_id: { $not: { $type: 'long' } } },
    { producto_nombre: { $not: { $type: 'string' } } },
    { cantidad: { $not: { $type: 'int' } } },
    { precio_unitario: { $not: { $type: 'decimal' } } },
    { subtotal: { $not: { $type: 'decimal' } } },
    { eliminado: { $not: { $type: 'bool' } } }
  ] } }
});
comprobar('tipos del documento raíz', tiposRaiz === 0, `${tiposRaiz} documentos con tipos inesperados`);
comprobar('tipos de las líneas', tiposLineas === 0, `${tiposLineas} documentos con líneas de tipo inesperado`);

// 4. Correspondencia completa con la extracción. Se arma el documento
//    esperado a partir del archivo y se compara en EJSON canónico, que
//    incluye tipos, escala decimal, orden de campos y ausencia de extras.
const esperado = (p) => ({
  _id: NumberLong(p.pedido_id),
  fecha: p.fecha,
  estado: p.estado,
  forma_pago: p.forma_pago,
  total: NumberDecimal(p.total),
  eliminado: p.eliminado,
  usuario: { usuario_id: NumberLong(p.usuario.usuario_id), nombre: p.usuario.nombre, apellido: p.usuario.apellido },
  items: p.items.map((i) => ({
    detalle_id: NumberLong(i.detalle_id),
    producto_id: NumberLong(i.producto_id),
    producto_nombre: i.producto_nombre,
    cantidad: NumberInt(parseInt(i.cantidad, 10)),
    precio_unitario: NumberDecimal(i.precio_unitario),
    subtotal: NumberDecimal(i.subtotal),
    eliminado: i.eliminado
  }))
});
const distintos = datos.pedidos.filter((p) => {
  const doc = almacenados.find((d) => d._id.toString() === p.pedido_id);
  return !doc || canonico(doc) !== canonico(esperado(p));
}).map((p) => p.pedido_id);
comprobar('correspondencia campo a campo con la extracción', distintos.length === 0,
  distintos.length ? `difieren: ${distintos.join(',')}` : 'los 5 documentos coinciden');

// 5. RI-01: cantidad Int32 positiva e importes no negativos en todas las
//    líneas, incluidas las eliminadas.
const ri01 = pedidos.countDocuments({
  ...filtroLote,
  items: { $elemMatch: { $or: [
    { cantidad: { $not: { $type: 'int' } } },
    { cantidad: { $lte: 0 } },
    { precio_unitario: { $lt: NumberDecimal('0') } },
    { subtotal: { $lt: NumberDecimal('0') } }
  ] } }
});
comprobar('RI-01', ri01 === 0, `${ri01} documentos con líneas inválidas`);

// 6. RI-02: subtotal = cantidad × precio histórico; total = suma de
//    subtotales de líneas no eliminadas ($sum de un arreglo vacío es 0).
//    $multiply de Int32 por Decimal128 devuelve Decimal128.
const ri02 = pedidos.aggregate([
  { $match: filtroLote },
  { $project: {
    total: 1,
    lineas_incoherentes: { $size: { $filter: {
      input: '$items',
      cond: { $ne: ['$$this.subtotal', { $multiply: ['$$this.cantidad', '$$this.precio_unitario'] }] }
    } } },
    suma_vigentes: { $sum: { $map: {
      input: { $filter: { input: '$items', cond: { $eq: ['$$this.eliminado', false] } } },
      in: '$$this.subtotal'
    } } }
  } },
  { $match: { $or: [
    { lineas_incoherentes: { $gt: 0 } },
    { $expr: { $ne: ['$total', '$suma_vigentes'] } }
  ] } }
]).toArray();
comprobar('RI-02', ri02.length === 0,
  ri02.length ? `incoherentes: ${ri02.map((d) => d._id.toString()).join(',')}` : '0 documentos incoherentes');

// 7. Precio histórico del producto 1: debe coincidir con la extracción y
//    conservar 1000.00 y 1050.00 (no el precio actual del catálogo).
const preciosMongo = pedidos.aggregate([
  { $match: filtroLote },
  { $unwind: '$items' },
  { $match: { 'items.producto_id': NumberLong('1') } },
  { $sort: { _id: 1, 'items.detalle_id': 1 } },
  { $project: { _id: 1, precio: '$items.precio_unitario' } }
]).toArray().map((d) => `${d._id.toString()}:${d.precio.toString()}`);
const preciosArchivo = datos.pedidos.flatMap((p) => p.items
  .filter((i) => i.producto_id === '1')
  .map((i) => `${p.pedido_id}:${i.precio_unitario}`));
const distintosPrecios = [...new Set(preciosMongo.map((x) => x.split(':')[1]))].sort();
comprobar('precios históricos del producto 1',
  iguales(preciosMongo, preciosArchivo) && iguales(distintosPrecios, ['1000.00', '1050.00']),
  preciosMongo.join(' '));

// 8. Huella de los documentos almacenados, para comparar antes y después
//    de un intento de carga repetida.
const huella = crypto.createHash('sha256').update(almacenados.map(canonico).join('\n')).digest('hex');
print(`info  sha256 de los documentos del lote: ${huella}`);

print(fallos === 0 ? 'RESULTADO: todas las comprobaciones pasaron' : `RESULTADO: ${fallos} comprobaciones fallaron`);
quit(fallos === 0 ? 0 : 1);
