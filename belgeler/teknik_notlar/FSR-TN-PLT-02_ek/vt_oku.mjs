// FSR-TN-PLT-02 S-8: read the SQLite database with sql.js (as the browser will) and
// write the `sonuc` and `hipotez` tables as CSV. Numbers are written with
// JavaScript's shortest round-trip text, so R reads back exactly the same double.
// Run (Node, sql.js 1.12.0):  node vt_oku.mjs <db.sqlite> <out_dir>
// Research and education only; not a system validated for GxP environments.
import initSqlJs from 'sql.js';
import fs from 'fs';
const [db_path, out] = process.argv.slice(2);
const SQL = await initSqlJs();
const db = new SQL.Database(fs.readFileSync(db_path));
const q = (s) => '"' + String(s).replaceAll('"', '""') + '"';
const cell = (v) => v === null ? 'NA' : (typeof v === 'number' ? String(v) : q(v));
for (const [t, ord] of [['sonuc', 'senaryo_no, kosu_id, yontem_id, olcut_id'], ['hipotez', 'senaryo_no, yontem_id']]) {
  const r = db.exec(`SELECT * FROM ${t} ORDER BY ${ord}`)[0];
  const lines = [r.columns.map(q).join(','), ...r.values.map((row) => row.map(cell).join(','))];
  fs.writeFileSync(`${out}/sqljs_${t}.csv`, lines.join('\n') + '\n');
  console.log(t, r.values.length);
}
const v = db.exec("SELECT deger FROM insa WHERE anahtar = 'vt_surumu'")[0].values[0][0];
console.log('sql.js', '1.12.0', 'vt_surumu', v);
