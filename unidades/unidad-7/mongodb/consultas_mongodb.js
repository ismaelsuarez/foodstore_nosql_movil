// Food Store U7 — Consultas C4a–C4d (consigna 4).
//
// Uso (Bash, desde la raíz del repositorio; ver docs/laboratorio_migracion.md):
//   docker exec -e U7_OPERADOR_PASSWORD_FILE=/run/foodstore-u7-auth/u7_operador.pwd \
//     foodstore-u7-mongo9 mongosh --quiet --norc mongodb://127.0.0.1:27017 \
//     /u7/mongodb/consultas_mongodb.js
//
// Mismo lote y mismas condiciones que consultas_postgresql.sql (design.md §7).
// Solo lectura. Cada consulta imprime cantidad e IDs ordenados.

const fs = require('fs');

const archivoClave = process.env.U7_OPERADOR_PASSWORD_FILE;
if (!archivoClave) {
  print('ERROR: falta U7_OPERADOR_PASSWORD_FILE');
  quit(1);
}
const destino = db.getSiblingDB('foodstore_u7');
destino.auth('u7_operador', fs.readFileSync(archivoClave, 'utf8').trim());
const pedidos = destino.getCollection('pedidos');

// Lote aprobado: pedidos 1–5, como Long construidos desde texto.
const lote = { _id: { $in: ['1', '2', '3', '4', '5'].map((id) => NumberLong(id)) } };

const informar = (consulta, documentos) => {
  const ids = documentos.map((d) => d._id.toString());
  print(`${consulta} | cantidad=${ids.length} | pedidos=${ids.join(',')}`);
};

// C4a: todos los pedidos del lote, con identificador y estado.
const c4a = pedidos.find(lote, { _id: 1, estado: 1 }).sort({ _id: 1 }).toArray();
c4a.forEach((d) => print(`C4a   _id=${d._id.toString()} estado=${d.estado}`));
informar('C4a', c4a);

// C4b: lote + pedido no eliminado + estado TERMINADO.
const c4b = pedidos.find(
  { ...lote, eliminado: false, estado: 'TERMINADO' },
  { _id: 1 }
).sort({ _id: 1 }).toArray();
informar('C4b', c4b);

// C4c: lote + pedido no eliminado + una MISMA línea con el producto 1 y
// eliminado false. $elemMatch exige ambas condiciones en el mismo elemento;
// el resultado son documentos (pedidos), no líneas.
const c4c = pedidos.find(
  { ...lote, eliminado: false, items: { $elemMatch: { producto_id: NumberLong('1'), eliminado: false } } },
  { _id: 1 }
).sort({ _id: 1 }).toArray();
informar('C4c', c4c);

// C4d: lote + pedido no eliminado + total > 3000.00 (comparación Decimal128).
// Umbral: importe redondo apenas superior al promedio del lote (2940.00).
const c4d = pedidos.find(
  { ...lote, eliminado: false, total: { $gt: NumberDecimal('3000.00') } },
  { _id: 1, total: 1 }
).sort({ _id: 1 }).toArray();
c4d.forEach((d) => print(`C4d   _id=${d._id.toString()} total=${d.total.toString()}`));
informar('C4d', c4d);
