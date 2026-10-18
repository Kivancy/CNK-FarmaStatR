// CNK-FarmaStatR - tier 2: precomputed results from the SQLite database (FSR-TN-PLT-04 T-3).
// The database file is checked against veri/VT_SHA256.txt before it is opened; on a mismatch
// the tier is closed and the page works with live runs only. sql.js 1.12.0 (pinned).
// The page does no statistics: classes, labels and numbers are the ones R wrote into the
// database (araclar/vt_insa.R).
// Research and education only; not a system validated for GxP environments.

import { ROOT, sha256, fetchBytes } from '../p1/motor.js';

export const SQLJS_VERSION = '1.12.0';
const Q = new URLSearchParams(location.search);
// A same-origin sql.js override (?sqljs=/path/) is accepted for offline tests only.
export const SQLJS_BASE = (() => {
  const v = Q.get('sqljs');
  return v && v.startsWith('/') && !v.startsWith('//') ? (v.endsWith('/') ? v : v + '/')
    : `https://cdn.jsdelivr.net/npm/sql.js@${SQLJS_VERSION}/dist/`;
})();
// Acceptance hook (U-3): ?vtbozuk=<byte> flips one bit of the downloaded database.
const VT_TAMPER = (() => { const p = Number(Q.get('vtbozuk')); return Q.has('vtbozuk') && Number.isInteger(p) && p >= 0 ? p : null; })();

const DB_PATH = 'veri/farmastatr_v1.sqlite', SHA_PATH = 'veri/VT_SHA256.txt';

function loadScript(src) {
  return new Promise((res, rej) => {
    const s = document.createElement('script'); s.src = src; s.onload = res; s.onerror = () => rej(new Error('sql.js: ' + src));
    document.head.appendChild(s);
  });
}

// Returns { ok, reason, db, index, info } ; never throws.
export async function openDb() {
  const t0 = performance.now();
  const info = { file: DB_PATH, sqljs: SQLJS_VERSION, tamper: VT_TAMPER };
  try {
    const [bytes, listTxt] = await Promise.all([fetchBytes(DB_PATH), fetchBytes(SHA_PATH)]);
    if (VT_TAMPER !== null && VT_TAMPER < bytes.length) bytes[VT_TAMPER] ^= 0x01;
    info.expected = new TextDecoder().decode(listTxt).trim().split(/\s+/)[0];
    info.sha256 = await sha256(bytes);
    info.bytes = bytes.length;
    if (info.sha256 !== info.expected) return { ok: false, reason: 'db_hash_mismatch', info };
    await loadScript(SQLJS_BASE + 'sql-wasm.js');
    const SQL = await window.initSqlJs({ locateFile: (f) => SQLJS_BASE + f });
    const db = new SQL.Database(bytes);
    const index = new Map(rows(db, 'SELECT senaryo_no, senaryo_anahtar FROM senaryo').map((r) => [r.senaryo_anahtar, r.senaryo_no]));
    info.vt_surumu = rows(db, "SELECT deger FROM insa WHERE anahtar = 'vt_surumu'")[0].deger;
    info.paket_surumu = rows(db, "SELECT deger FROM insa WHERE anahtar = 'paket_surumu'")[0].deger;
    info.ms = Math.round(performance.now() - t0);
    return { ok: true, db, index, info };
  } catch (err) {
    return { ok: false, reason: 'db_unavailable', info: { ...info, error: String(err && err.message || err) } };
  }
}

export function rows(db, sql, params = []) {
  const st = db.prepare(sql); st.bind(params);
  const out = []; while (st.step()) out.push(st.getAsObject()); st.free();
  return out;
}

// Everything the screen needs for one scenario (P4-K1: the combined run when it exists).
export function scenario(db, no) {
  const s = rows(db, 'SELECT * FROM senaryo WHERE senaryo_no = ?', [no])[0];
  const son = rows(db, 'SELECT * FROM sonuc WHERE senaryo_no = ?', [no]);
  const hip = rows(db, 'SELECT * FROM hipotez WHERE senaryo_no = ? ORDER BY yontem_id', [no]);
  const runIds = [...new Set(son.map((r) => r.kosu_id))];
  const kosu = runIds.map((id) => rows(db, 'SELECT * FROM kosu WHERE kosu_id = ?', [id])[0]);
  const main = kosu.find((k) => k.tur === 'tek');
  const comb = kosu.find((k) => k.tur === 'birlesik');
  const shown = comb || main;                                  // P4-K1
  const pick = (yontem, olcut) => son.find((r) => r.kosu_id === shown.kosu_id && r.yontem_id === yontem && r.olcut_id === olcut)
    || son.find((r) => r.kosu_id === main.kosu_id && r.yontem_id === yontem && r.olcut_id === olcut) || null;
  const fk = rows(db, 'SELECT * FROM fark WHERE senaryo_no = ?', [no]);
  const pickDiff = (a, b) => fk.find((r) => r.kosu_id === shown.kosu_id && r.yontem_1 === a && r.yontem_2 === b)
    || fk.find((r) => r.kosu_id === main.kosu_id && r.yontem_1 === a && r.yontem_2 === b) || null;
  const sources = comb ? rows(db, 'SELECT kaynak_kosu_id FROM kosu_kaynak WHERE kosu_id = ?', [comb.kosu_id]).map((r) => r.kaynak_kosu_id) : [];
  return { s, hip, kosu, main, comb, shown, pick, pickDiff, sources };
}

// G2: neighbours in the same grid block that differ from the scenario in exactly one parameter.
const PAR = ['sigma_R', 'rho', 'pB_T', 'pB_R', 'pL', 'q', 'l', 'n', 'm'];
export function neighbours(db, s) {
  const cand = rows(db, 'SELECT * FROM senaryo WHERE asama = ? AND blok = ? AND delta_ad = ?', [s.asama, s.blok, s.delta_ad]);
  let best = null;
  for (const v of PAR) {
    const others = PAR.filter((p) => p !== v);
    const set = cand.filter((c) => others.every((p) => c[p] === s[p]));
    const xs = new Set(set.map((c) => c[v]));
    if (xs.size >= 3 && (!best || xs.size > best.set.length)) best = { v, set: set.sort((a, b) => a[v] - b[v]) };
  }
  if (!best) return null;
  const pts = best.set.map((c) => {
    const d = scenario(db, c.senaryo_no);
    return { x: c[best.v], no: c.senaryo_no, rates: Object.fromEntries(['fda', 'ema_a', 'ema_b', 'ema_c'].map((me) => [me, d.pick(me, 'pass')?.tahmin ?? null])) };
  });
  return { param: best.v, pts };
}
