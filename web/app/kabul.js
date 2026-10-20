// CNK-FarmaStatR - P4 acceptance tool (FSR-TN-PLT-04 v0.1, Table 9.1; frozen by KK-54).
// Drives the screen (index.html) in a same-origin frame, reads what it shows (DOM) and what
// it holds (window.__p4), and writes p4_tarayici.csv. The comparison with R is done by
// belgeler/teknik_notlar/FSR-TN-PLT-04_ek/p4_kabul.R. Turkish only (internal tool).
// Research and education only; not a system validated for GxP environments.

import { openDb, rows } from './hazir.js';
import { anahtar, fixed, numExact } from './bicim.js';

const Q = new URLSearchParams(location.search);
const PASS = ['webr', 'sqljs'].filter((k) => Q.get(k)).map((k) => `${k}=${encodeURIComponent(Q.get(k))}`).join('&');
const $ = (s) => document.querySelector(s);
const fr = $('#fr');
const W = () => fr.contentWindow, Dc = () => fr.contentDocument;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const out = [];
const put = (bolum, senaryo, yontem, ad, deger) => out.push([bolum, senaryo, yontem, ad, deger === null || deger === undefined ? 'NA' : String(deger)]);
let T = null, script = null;
function log(s) { const l = $('#log'); l.textContent += `[${new Date().toLocaleTimeString()}] ${s}\n`; l.scrollTop = l.scrollHeight; }
async function waitFor(fn, ms = 240000) {
  const t0 = performance.now();
  for (;;) { try { const v = fn(); if (v) return v; } catch (e) { /* frame loading */ } if (performance.now() - t0 > ms) throw new Error('zaman aşımı'); await sleep(100); }
}
function load(params) {
  return new Promise((res) => { fr.onload = () => res(); fr.src = 'index.html?' + [params, PASS].filter(Boolean).join('&'); });
}
const ready = () => waitFor(() => W().__p4 && W().__p4.ready);

// ---------------------------------------------------------------- scenario sets (frozen, Table 9.1)
const BASE = { pBT: 0, pBR: 0, pL: 0.15, q: 0, l: 3, n: 10, m: 3, nsim: 2000, seed: 20261015 };
const LIVE = [];
for (const sR of [0.06, 0.12]) for (const rho of [1, 1.8]) for (const d of ['fda_delta0', 'ema_1.18', 'gmr_1.00', 'gmr_1.05'])
  LIVE.push({ id: `C-${sR}-${rho}-${d}`, sR, rho, d });
// delta0 * (1 + 1e-6) for sigma_R 0.12, rho 1, computed in R: invitro_delta0(0.12, 1) * (1 + 1e-6)
LIVE.push({ id: 'C-yakin', sR: 0.12, rho: 1, d: 'delta:0.1734448575079488' });
// eight grid scenarios (senaryo_no 1, 2, 67, 257, 258, 259, 260, 480): both stages, every class, one combined run
const GRID = [
  'sigma_R=0.06|rho=1|pB_T=0.3|pB_R=0.3|pL=0.15|q=0|l=3|n=10|m=3|delta=ema_1.18',
  'sigma_R=0.06|rho=1|pB_T=0.3|pB_R=0.3|pL=0.15|q=0|l=3|n=10|m=3|delta=fda_delta0',
  'sigma_R=0.099|rho=1.15|pB_T=0.3|pB_R=0.3|pL=0.15|q=0|l=3|n=10|m=3|delta=gmr_1.00',
  'sigma_R=0.12|rho=1|pB_T=0.1|pB_R=0.1|pL=0.15|q=0|l=2|n=10|m=3|delta=ema_0.85',
  'sigma_R=0.12|rho=1|pB_T=0.1|pB_R=0.1|pL=0.15|q=0|l=2|n=10|m=3|delta=ema_1.18',
  'sigma_R=0.12|rho=1|pB_T=0.1|pB_R=0.1|pL=0.15|q=0|l=2|n=10|m=3|delta=fda_delta0',
  'sigma_R=0.12|rho=1|pB_T=0.1|pB_R=0.1|pL=0.15|q=0|l=2|n=10|m=3|delta=gmr_1.00',
  'sigma_R=0.12|rho=1|pB_T=0.3|pB_R=0.3|pL=0.15|q=0|l=3|n=10|m=3|delta=fda_minus_delta0'];
function keyToParams(k) {
  const o = Object.fromEntries(k.split('|').map((x) => x.split('=')));
  return { sR: o.sigma_R, rho: o.rho, pBT: o.pB_T, pBR: o.pB_R, pL: o.pL, q: o.q, l: o.l, n: o.n, m: o.m, nsim: 10000, seed: 20261015, d: o.delta };
}
const qs = (o) => Object.entries(o).map(([k, v]) => `${k}=${encodeURIComponent(v)}`).join('&');

// ---------------------------------------------------------------- what the screen shows
function capture(set, id) {
  const st = W().__p4, d = st.display, lang = Dc().documentElement.lang, L = T[lang];
  put(set, id, '', 'lang', lang); put(set, id, '', 'source', d.source); put(set, id, '', 'key', d.key);
  put(set, id, '', 'webr_started', st.webrStarted);
  if (d.source === 'canli') { put(set, id, '', 'n_sim', d.n_sim); put(set, id, '', 'seed', d.seed); }
  else { put(set, id, '', 'kosu_shown', d.kosu.shown.kosu_id); put(set, id, '', 'kosu_main', d.kosu.main.kosu_id); put(set, id, '', 'senaryo_no', d.no); }
  let txtOk = true;
  for (const tr of Dc().querySelectorAll('#res_table tbody tr')) {
    const y = tr.dataset.yontem, r = d.rows.find((x) => x.yontem === y), td = (c) => tr.querySelector(`[data-col=${c}]`).textContent;
    for (const [k, v] of Object.entries({ sinif: r.sinif, metrik: r.metrik, kk38: r.kk38 ?? 'NA', yakinlik: r.yakinlik, rate: numExact(r.rate), mcse: numExact(r.mcse) })) put(set, id, y, k, v);
    for (const c of ['metrik', 'sinif', 'oran', 'mcse', 'kk38']) put(set, id, y, 'txt_' + c, td(c));
    const exp = { metrik: L['metrik_' + r.metrik], sinif: L['sinif_' + r.sinif], kk38: r.kk38 ? L['kk38_' + r.kk38] : '—',
      oran: (lang === 'tr' ? (s) => s.replace('.', ',') : (s) => s)(fixed(100 * r.rate, 1)), mcse: (lang === 'tr' ? (s) => s.replace('.', ',') : (s) => s)(fixed(100 * r.mcse, 2)) };
    for (const c of Object.keys(exp)) if (td(c) !== exp[c]) { txtOk = false; put(set, id, y, 'txt_fark_' + c, td(c) + ' != ' + exp[c]); }
  }
  put(set, id, '', 'txt_ok', txtOk);
  // G1
  const marks = [...Dc().querySelectorAll('#g1 .mark')];
  const g1ok = marks.length === d.rows.length && d.rows.every((r) => marks.some((m) => m.dataset.yontem === r.yontem && m.dataset.value === String(r.rate) && m.dataset.sinif === r.sinif));
  const anyH0 = d.rows.some((r) => r.sinif !== 'H1'), nom = !!Dc().querySelector('#g1 .nominal');
  put(set, id, '', 'g1_ok', g1ok); put(set, id, '', 'g1_nominal_ok', anyH0 === nom);
  if (d.source === 'hazir') {
    const g2m = [...Dc().querySelectorAll('#g2 .mark')];
    const want = d.nb ? d.nb.pts.flatMap((p) => Object.entries(p.rates).filter(([, v]) => v !== null).map(([m, v]) => `${p.no}|${m}|${v}`)) : [];
    const got = g2m.map((m) => `${m.dataset.no}|${m.dataset.yontem}|${m.dataset.value}`);
    put(set, id, '', 'g2_n', got.length); put(set, id, '', 'g2_ok', want.length === got.length && want.every((w) => got.includes(w)));
    put(set, id, '', 'g2_sel', !d.nb || !!Dc().querySelector(`#g2 .selected[data-no="${d.no}"]`));
    if (d.nb) for (const p of d.nb.pts) for (const [m, v] of Object.entries(p.rates)) put(set, id, m, `g2_${p.no}`, v === null ? 'NA' : numExact(v));
  }
  put(set, id, '', 'warn', [...Dc().querySelectorAll('#warnings [data-warn]')].map((e) => e.dataset.warn).join(';'));
  const mc = Dc().querySelector('#mc_info').textContent;
  put(set, id, '', 'mc_info_ok', [L.exp_mcse, L.est_time, L.nsim_max_design].every((s) => mc.includes(s)));
  // TR/EN: nothing shown as a raw key; disclaimer visible
  const raw = [...Dc().querySelectorAll('[data-i18n]')].filter((e) => L[e.dataset.i18n] === undefined || e.textContent !== L[e.dataset.i18n]).length;
  const disc = Dc().querySelector('.disclaimer');
  put(set, id, '', 'i18n_raw', raw); put(set, id, '', 'disclaimer_ok', disc.textContent === L.disclaimer && disc.offsetHeight > 0);
}

async function liveRun() {
  await waitFor(() => !W().document.querySelector('#run').disabled);
  W().document.querySelector('#run').click();
  await waitFor(() => W().__p4.display && W().__p4.display.source === 'canli');
}

// ---------------------------------------------------------------- the run
async function main() {
  $('#b_run').disabled = true;
  const t0 = performance.now();
  T = await (await fetch('ceviri.json', { cache: 'no-store' })).json();
  put('ortam', '', '', 'user_agent', navigator.userAgent); put('ortam', '', '', 'baslangic', new Date().toISOString());
  const kt = Object.keys(T.tr).sort().join(), ke = Object.keys(T.en).sort().join();
  put('U-6', '', '', 'ceviri_anahtar_esit', kt === ke); put('U-6', '', '', 'ceviri_n', Object.keys(T.tr).length);

  // U-3 (all 1,085 keys) and U-2 (display rule over the whole grid)
  log('Veri tabanı: anahtar ve biçim denetimi');
  const hz = await openDb();
  put('U-3', '', '', 'vt_ok', hz.ok);
  const sen = rows(hz.db, 'SELECT * FROM senaryo');
  let bad = 0;
  for (const s of sen) if (anahtar(s, s.delta_ad) !== s.senaryo_anahtar) bad++;
  put('U-3', '', '', 'anahtar_n', sen.length); put('U-3', '', '', 'anahtar_fark', bad);
  const so = rows(hz.db, "SELECT s.senaryo_no, s.kosu_id, s.yontem_id, s.olcut_id, s.tahmin, s.mcse FROM sonuc s JOIN olcut o USING (olcut_id) WHERE o.tur = 'oran' ORDER BY 1, 2, 3, 4");
  for (const r of so) put('bicim', `${r.senaryo_no}|${r.kosu_id}|${r.yontem_id}|${r.olcut_id}`, '', fixed(100 * r.tahmin, 1), r.mcse === null ? 'NA' : fixed(100 * r.mcse, 2));
  log(`  anahtar: ${sen.length} senaryo, fark ${bad}; biçim: ${so.length} oran`);

  // tier 2: eight grid scenarios
  for (const k of GRID) {
    await load(qs(keyToParams(k))); await ready();
    await waitFor(() => W().__p4.display && W().__p4.display.source === 'hazir');
    capture('U-hazir', k);
    log(`hazır: ${k} → ${W().__p4.display.kosu.shown.kosu_id}; webR ${W().__p4.webrStarted}`);
  }

  // tier 1: 17 live scenarios, TR then EN on the same run; link round trip
  for (const s of LIVE) {
    const P = { ...BASE, sR: s.sR, rho: s.rho, d: s.d };
    await load(qs(P)); await ready();
    await waitFor(() => W().__p4.pre || W().__p4.display);
    if (W().__p4.pre && W().__p4.pre.ok === false && W().__p4.pre.kind === 'delta0') {      // delta0 not defined: no run (U-8)
      W().document.querySelector('#run').click(); await waitFor(() => W().__p4.status === 'st_error');
      put('U-8', s.id, '', 'hata_metni', Dc().querySelector('#errors').textContent.includes(T.tr.err_delta0));
      put('U-8', s.id, '', 'sonuc_yok', !W().__p4.display || W().__p4.display.source !== 'canli');
      log(`canlı: ${s.id} (δ₀ tanımsız; koşu yok)`); continue;
    }
    await liveRun();
    capture('U-canli', s.id);
    W().document.querySelector('#lang').click(); await sleep(150); capture('U-canli-en', s.id);
    W().document.querySelector('#link').click(); await waitFor(() => W().__p4.link);
    const link = W().__p4.link, rates = W().__p4.display.rows.map((r) => r.rate).join(';'), key = W().__p4.display.key;
    await new Promise((res) => { fr.onload = res; fr.src = link; }); await ready();
    put('U-5', s.id, '', 'link_key_ok', W().__p4.key === key.split('|n_sim=')[0]);
    await liveRun();
    put('U-5', s.id, '', 'link_ayni_sonuc', W().__p4.display.rows.map((r) => r.rate).join(';') === rates && W().__p4.display.key === key);
    log(`canlı: ${s.id}`);
  }

  // U-8: FDA delta0 not defined
  await load(qs({ ...BASE, sR: 0.06, rho: 3, d: 'fda_delta0' })); await ready();
  await waitFor(() => W().__p4.pre); W().document.querySelector('#run').click();
  await waitFor(() => W().__p4.status === 'st_error');
  put('U-8', 'delta0_tanimsiz', '', 'hata_metni', Dc().querySelector('#errors').textContent.includes(T.tr.err_delta0));
  put('U-8', 'delta0_tanimsiz', '', 'sonuc_yok', !W().__p4.display);

  // U-5: version mismatch
  await load(qs({ ...keyToParams(GRID[1]), v: '0.0.0' })); await ready(); await sleep(1000);
  put('U-5', 'surum', '', 'kutu', !Dc().querySelector('#version_box').hidden); put('U-5', 'surum', '', 'sessiz_yok', !W().__p4.display);
  Dc().querySelector('#ver_ok').click(); await waitFor(() => W().__p4.display);
  put('U-5', 'surum', '', 'onaydan_sonra', W().__p4.display.source);

  // U-3: tampered database
  await load('vtbozuk=5000&' + qs(keyToParams(GRID[1]))); await ready(); await sleep(500);
  put('U-3', 'vtbozuk', '', 'hazir_kapali', W().__p4.hz.ok === false && W().__p4.layer !== 'hazir');
  put('U-3', 'vtbozuk', '', 'uyari', !!Dc().querySelector('[data-warn=db]'));

  // U-4: tiers; above the limit -> script
  await load(qs({ ...BASE, sR: 0.13, l: 6, n: 30, nsim: 50000, d: 'gmr_1.05' })); await ready(); await sleep(500);
  put('U-4', 'sinir_ustu', '', 'katman', W().__p4.layer);
  W().document.querySelector('#run').click(); await waitFor(() => W().__p4.status === 'st_error');
  put('U-4', 'sinir_ustu', '', 'betik_onerisi', Dc().querySelector('#errors').textContent.includes(T.tr.go_script));
  W().document.querySelector('#script').click(); await waitFor(() => W().__p4.script);
  script = W().__p4.script; put('U-11', 'betik', '', 'uzunluk', script.length);
  await load(qs({ ...BASE, sR: 0.13, d: 'gmr_1.05' })); await ready(); await sleep(500); put('U-4', 'izgara_disi', '', 'katman', W().__p4.layer);
  await load(qs(keyToParams(GRID[0]))); await ready(); await waitFor(() => W().__p4.display); put('U-4', 'izgara', '', 'katman', W().__p4.layer);
  await load(qs({ ...BASE, sR: -1, d: 'gmr_1.05' })); await ready(); await waitFor(() => W().__p4.pre);
  put('U-4', 'gecersiz', '', 'kodlar', W().__p4.pre.ok === false && W().__p4.pre.kind === 'input' ? [].concat(W().__p4.pre.code).join(';') : 'yok');

  // U-9: cancel (6 x 30, 15,000) after 3 s
  await load(qs({ ...BASE, sR: 0.13, l: 6, n: 30, nsim: 15000, d: 'gmr_1.05' })); await ready(); await waitFor(() => W().__p4.pre);
  W().document.querySelector('#run').click(); await waitFor(() => W().__p4.status === 'st_running'); await sleep(3000);
  const was = W().__p4.status === 'st_running', tc = performance.now();
  W().document.querySelector('#cancel').click(); await waitFor(() => W().__p4.status === 'st_cancelled');
  put('U-9', 'iptal', '', 'kosu_suruyordu', was); put('U-9', 'iptal', '', 'durma_ms', Math.round(performance.now() - tc));
  put('U-9', 'iptal', '', 'kismi_sonuc_yok', !W().__p4.display || W().__p4.display.source !== 'canli');

  // U-12: narrow screen
  fr.style.width = '375px'; await load(qs(keyToParams(GRID[2]))); await ready(); await waitFor(() => W().__p4.display); await sleep(300);
  put('U-12', 'dar', '', 'scroll_genislik', Dc().documentElement.scrollWidth); put('U-12', 'dar', '', 'pencere', W().innerWidth);
  put('U-12', 'dar', '', 'dugmeler_gorunur', [...Dc().querySelectorAll('button')].filter((b) => !b.hidden && b.offsetParent !== null).every((b) => b.getBoundingClientRect().right <= W().innerWidth + 0.5));
  fr.style.width = '';

  put('ortam', '', '', 'sure_s', Math.round((performance.now() - t0) / 1000));
  log('Bitti. CSV ve betiği indirin.');
  $('#status').textContent = 'Testler: tamamlandı'; window.__p4k_done = true;
  $('#b_csv').disabled = false;
}

function download() {
  const q = (s) => '"' + String(s).replaceAll('"', '""') + '"';
  const csv = [['bolum', 'senaryo', 'yontem', 'ad', 'deger'].map(q).join(','), ...out.map((r) => r.map(q).join(','))].join('\n') + '\n';
  for (const [name, text, type] of [['p4_tarayici.csv', csv, 'text/csv'], ['p4_betik.R', script || '', 'text/plain']]) {
    const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([text], { type: type + ';charset=utf-8' }));
    a.download = name; a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  }
}
window.__p4k_out = out;
$('#b_run').addEventListener('click', () => main().catch((e) => { log('HATA: ' + (e.message || e)); $('#status').textContent = 'Testler: hata'; $('#b_csv').disabled = false; }));
$('#b_csv').addEventListener('click', download);
