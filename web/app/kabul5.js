// CNK-FarmaStatR - P5 acceptance tool (FSR-TN-PLT-05 v0.2, Table 8.1: D-1 ... D-7, R-1 ... R-11;
// frozen by KK-57). Drives the screen (index.html) in a same-origin frame, reads what it shows
// (DOM) and what it holds (window.__p4, window.__p5), makes the Word reports with the screen's
// own report function and packs everything into one stored ZIP (p5_kabul.zip): the record
// p5_tarayici.csv, the reports and the design script. The comparison with R is done by
// belgeler/teknik_notlar/FSR-TN-PLT-05_ek/p5_kabul.R, which reads the reports with R's own
// unzip. Turkish only (internal tool).
// Research and education only; not a system validated for GxP environments.

import { numExact, fixed } from './bicim.js';
import { zipStored } from './rapor.js';

const Q = new URLSearchParams(location.search);
const PASS = ['webr', 'sqljs'].filter((k) => Q.get(k)).map((k) => `${k}=${encodeURIComponent(Q.get(k))}`).join('&');
const $ = (s) => document.querySelector(s);
const fr = $('#fr');
const W = () => fr.contentWindow, Dc = () => fr.contentDocument;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const out = [], files = [];
const enc = new TextEncoder();
const put = (bolum, senaryo, yontem, ad, deger) => out.push([bolum, senaryo, yontem, ad, deger === null || deger === undefined ? 'NA' : String(deger)]);
let T = null, nRep = 0, maxMs = 0;
function log(s) { const l = $('#log'); l.textContent += `[${new Date().toLocaleTimeString()}] ${s}\n`; l.scrollTop = l.scrollHeight; }
async function waitFor(fn, ms = 600000) {
  const t0 = performance.now();
  for (;;) { try { const v = fn(); if (v) return v; } catch (e) { /* frame loading */ } if (performance.now() - t0 > ms) throw new Error('zaman aşımı'); await sleep(100); }
}
function load(params) {
  return new Promise((res) => { fr.onload = () => res(); fr.src = 'index.html?' + [params, PASS].filter(Boolean).join('&'); });
}
const ready = () => waitFor(() => W().__p4 && W().__p4.ready);
const qs = (o) => Object.entries(o).map(([k, v]) => `${k}=${encodeURIComponent(v)}`).join('&');
const click = (sel) => Dc().querySelector(sel).click();
const enabled = (sel) => !Dc().querySelector(sel).disabled;
const nReq = () => W().performance.getEntriesByType('resource').length;

// ---------------------------------------------------------------- frozen scenario sets
// single scenario: the P4 sets (FSR-TN-PLT-04 Table 9.1)
const BASE = { pBT: 0, pBR: 0, pL: 0.15, q: 0, l: 3, n: 10, m: 3, nsim: 2000, seed: 20261015 };
const LIVE = [];
for (const sR of [0.06, 0.12]) for (const rho of [1, 1.8]) for (const d of ['fda_delta0', 'ema_1.18', 'gmr_1.00', 'gmr_1.05'])
  LIVE.push({ id: `C-${sR}-${rho}-${d}`, sR, rho, d });
LIVE.push({ id: 'C-yakin', sR: 0.12, rho: 1, d: 'delta:0.1734448575079488' });
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
// design selection (FSR-TN-PLT-05 Section 7)
const S1 = (pB) => ({ t_sigma_R: 0.12, t_rho: 1, t_pB_T: pB, t_pB_R: pB, t_pL: 0.15, t_q: 0 });
const TAS = [
  { id: 'T-A1-pB0', p: { ...S1(0), ls: '2-3-4-5-6', ns: '5-8-10-15-20-30', ms: '3', g: 'gmr_1.05', hedef: 80, nsim: 10000 }, d1: 0 },
  { id: 'T-A1-pB0.1', p: { ...S1(0.1), ls: '2-3-4-5-6', ns: '5-8-10-15-20-30', ms: '3', g: 'gmr_1.05', hedef: 80, nsim: 10000 }, d1: 0.1 },
  { id: 'T-A1-pB0.3', p: { ...S1(0.3), ls: '2-3-4-5-6', ns: '5-8-10-15-20-30', ms: '3', g: 'gmr_1.05', hedef: 80, nsim: 10000 }, d1: 0.3 },
  { id: 'T-A1-gmr1.00', p: { ...S1(0.3), ls: '2-3-4-5-6', ns: '5-8-10-15-20-30', ms: '3', g: 'gmr_1.00', hedef: 90, nsim: 10000 } },
  { id: 'T-dar', p: { ...S1(0.1), ls: '3-4', ns: '10-15', ms: '3', g: 'gmr_1.05', hedef: 80, nsim: 10000 }, live: true },
  { id: 'T-yeni', p: { t_sigma_R: 0.15, t_rho: 1.15, t_pB_T: 0.3, t_pB_R: 0.3, t_pL: 0.15, t_q: 0, ls: '3-4', ns: '10-20', ms: '2-3', g: 'gmr_1.05', hedef: 80, nsim: 2000 }, script: true },
  { id: 'T-delta0', p: { t_sigma_R: 0.12, t_rho: 1.8, t_pB_T: 0, t_pB_R: 0, t_pL: 0.15, t_q: 0, ls: '3', ns: '10', ms: '3', g: 'gmr_1.05', hedef: 80, nsim: 2000 } },
  { id: 'T-h1degil', p: { ...S1(0), ls: '3', ns: '10', ms: '3', g: 'gmr:1.18', hedef: 80, nsim: 2000 } }];
const tasQs = (p) => qs({ mode: 'tasarim', ...p, seed: 20261015 });

// ---------------------------------------------------------------- what the screen shows
function screenTek() {
  const d = Dc(), s = [d.querySelector('#source').textContent, d.querySelector('#truth').textContent];
  for (const tr of d.querySelectorAll('#res_table tbody tr, #more_table tbody tr')) for (const c of tr.children) s.push(c.textContent);
  for (const p of d.querySelectorAll('#warnings p')) s.push(p.textContent);
  return s;
}
function screenTas() {
  const d = Dc(), s = [d.querySelector('#ts_source').textContent, d.querySelector('#ts_target').textContent, d.querySelector('#ts_legend').textContent];
  for (const tr of d.querySelectorAll('#ts_sum tbody tr')) for (const c of tr.children) if (c.textContent !== '') s.push(c.textContent);
  for (const p of d.querySelectorAll('#ts_warnings p')) s.push(p.textContent);
  for (const h of d.querySelectorAll('#ts_grids h3')) s.push(h.textContent);
  for (const tb of d.querySelectorAll('#ts_grids table')) {
    for (const th of tb.querySelectorAll('th')) s.push(th.textContent);
    for (const c of tb.querySelectorAll('td.cell')) s.push(c.children.length ? c.children[0].textContent + '\n' + c.children[1].textContent : c.textContent);
  }
  return s;
}
// report with the screen's own function; recorded with the screen texts it must contain
async function report(kind, id) {
  const st = kind === 'tas' ? W().__p5 : W().__p4;
  const lang = Dc().documentElement.lang;
  const r0 = nReq();
  const r = st.makeReport();
  const name = `raporlar/${id}_${lang}.docx`;
  files.push([name, r.bytes]); nRep++; maxMs = Math.max(maxMs, r.ms);
  put('R', id, lang, 'dosya', name); put('R', id, lang, 'tur', kind); put('R', id, lang, 'ms', r.ms.toFixed(1));
  put('R', id, lang, 'ag_istegi', nReq() - r0);
  put('R', id, lang, 'ekran', JSON.stringify(kind === 'tas' ? screenTas() : screenTek()));
  put('R', id, lang, 'dugme_etkin', enabled(kind === 'tas' ? '#ts_report' : '#report'));
  return name;
}
// values held by the screen (for the R side)
function valuesTek(set, id) {
  const st = W().__p4, d = st.display, lang = Dc().documentElement.lang, L = T[lang];
  put(set, id, '', 'source', d.source); put(set, id, '', 'key', d.key);
  if (d.source === 'canli') { put(set, id, '', 'n_sim', d.n_sim); put(set, id, '', 'seed', d.seed); }
  else { put(set, id, '', 'kosu_shown', d.kosu.shown.kosu_id); put(set, id, '', 'senaryo_no', d.no); }
  let ok = true;
  for (const tr of Dc().querySelectorAll('#res_table tbody tr')) {
    const y = tr.dataset.yontem, r = d.rows.find((x) => x.yontem === y), td = (c) => tr.querySelector(`[data-col=${c}]`).textContent;
    for (const [k, v] of Object.entries({ sinif: r.sinif, metrik: r.metrik, kk38: r.kk38 ?? 'NA', rate: numExact(r.rate), mcse: numExact(r.mcse) })) put(set, id, y, k, v);
    const dec = (s) => (lang === 'tr' ? s.replace('.', ',') : s);
    const exp = { metrik: L['metrik_' + r.metrik], sinif: L['sinif_' + r.sinif], kk38: r.kk38 ? L['kk38_' + r.kk38] : '—', oran: dec(fixed(100 * r.rate, 1)), mcse: dec(fixed(100 * r.mcse, 2)) };
    for (const c of Object.keys(exp)) if (td(c) !== exp[c]) { ok = false; put(set, id, y, 'txt_fark_' + c, td(c) + ' != ' + exp[c]); }
  }
  put(set, id, '', 'txt_ok', ok);
}
function valuesTas(id, tag = '') {
  const R = W().__p5.result, set = 'D' + tag;
  put(set, id, '', 'source', R.source); put(set, id, '', 'hedef', numExact(R.hedef));
  for (const k of ['sigma_R', 'rho', 'pB_T', 'pB_R', 'pL', 'q']) put(set, id, '', 'pop_' + k, numExact(R.c.pop[k]));
  put(set, id, '', 'ls', R.c.l.join(' ')); put(set, id, '', 'ns', R.c.n.join(' ')); put(set, id, '', 'ms', R.c.m.join(' '));
  put(set, id, '', 'guc', R.c.guc); put(set, id, '', 'custom', Number.isFinite(R.c.custom) ? numExact(R.c.custom) : 'NA');
  put(set, id, '', 'n_sim', numExact(R.c.n_sim)); put(set, id, '', 'seed', numExact(R.c.seed));
  put(set, id, '', 'gdelta', numExact(R.plan.gdelta));
  if (R.source === 'hazir') put(set, id, '', 'kosular', R.runs.map((k) => k.kosu_id).join(';'));
  put(set, id, '', 'anahtarlar', R.plan.anahtar.join(' ; '));
  put(set, id, '', 'notlar', R.plan.notlar.join(';'));
  put(set, id, '', 'sinif', R.plan.yontem.map((m, i) => m + ':' + R.plan.sinif[i]).join(';'));
  const T2 = R.tablo, S = R.secim;
  for (let i = 0; i < T2.yontem.length; i++)
    put(set, id, T2.yontem[i], `tablo_${T2.l[i]}_${T2.n[i]}_${T2.m[i]}`,
      [numExact(T2.guc[i]), numExact(T2.guc_mcse[i]), T2.t1[i] === null ? 'NA' : numExact(T2.t1[i]), T2.t1[i] === null ? 'NA' : numExact(T2.t1_mcse[i]),
       T2.t1_etiket[i] ?? 'NA', T2.guc_sinif[i], T2.hedef_ok[i], T2.esik_yakin[i]].join('|'));
  for (let i = 0; i < S.yontem.length; i++)
    put(set, id, S.yontem[i], 'secim_' + S.kural[i], S.var[i] ? `${S.l[i]}|${S.n[i]}|${S.m[i]}|${S.esik_yakin[i]}` : 'yok|' + S.neden[i]);
  put(set, id, '', 'uyarilar', [...Dc().querySelectorAll('#ts_warnings [data-warn]')].map((e) => e.dataset.warn).join(';'));
  // the screen's marks agree with the table (D-6)
  const cells = [...Dc().querySelectorAll('#ts_grids td.cell[data-l]')];
  put(set, id, '', 'isaret_ok', cells.every((c) => {
    const i = T2.yontem.findIndex((y, j) => y === c.closest('table').dataset.yontem && String(T2.l[j]) === c.dataset.l && String(T2.n[j]) === c.dataset.n && String(T2.m[j]) === c.dataset.m);
    return i >= 0 && c.classList.contains('ok') === !!T2.hedef_ok[i] && c.classList.contains('near') === !!T2.esik_yakin[i];
  }) && cells.length === T2.yontem.length);
}
async function tasRun(sel = '#ts_run') {
  W().__p5.status = null;
  click(sel);
  await waitFor(() => ['ts_st_hazir', 'ts_st_done', 'ts_st_error', 'ts_st_betik', 'ts_st_cancelled'].includes(W().__p5.status));
  return W().__p5.status;
}
async function langSwitch() { click('#lang'); await sleep(200); }

// ---------------------------------------------------------------- the run
async function main() {
  $('#b_run').disabled = true;
  const t0 = performance.now();
  T = await (await fetch('ceviri.json', { cache: 'no-store' })).json();
  put('ortam', '', '', 'user_agent', navigator.userAgent); put('ortam', '', '', 'baslangic', new Date().toISOString());
  put('R-3', '', '', 'ceviri_anahtar_esit', Object.keys(T.tr).sort().join() === Object.keys(T.en).sort().join());
  put('R-3', '', '', 'ceviri_n', Object.keys(T.tr).length);

  // ---- single scenario: 8 precomputed, 17 live; reports TR and EN
  for (const [i, k] of GRID.entries()) {
    await load(qs({ ...keyToParams(k), lang: 'tr' })); await ready();
    await waitFor(() => W().__p4.display && W().__p4.display.source === 'hazir');
    const id = `tek-hazir-${i + 1}`;
    valuesTek('tek', id); await report('tek', id);
    await langSwitch(); await report('tek', id);
    if (i === 0) {                          // R-7: the same result twice
      await sleep(1100); const r = W().__p4.makeReport(); files.push([`raporlar/${id}_en_tekrar.docx`, r.bytes]); put('R-7', id, 'en', 'dosya', `raporlar/${id}_en_tekrar.docx`);
    }
    log(`tek senaryo, hazır: ${id}`);
  }
  for (const s of LIVE) {
    await load(qs({ ...BASE, sR: s.sR, rho: s.rho, d: s.d, lang: 'tr' })); await ready();
    await waitFor(() => W().__p4.pre || W().__p4.display);
    if (W().__p4.pre && W().__p4.pre.ok === false && W().__p4.pre.kind === 'delta0') { put('R-9', s.id, '', 'delta0_rapor_pasif', !enabled('#report')); log(`canlı: ${s.id} (δ₀ tanımsız; rapor yok)`); continue; }
    // before the run: enabled exactly when a result is shown (a grid scenario shows the precomputed one)
    put('R-9', s.id, '', 'once_dogru', enabled('#report') === !!W().__p4.display);
    await waitFor(() => enabled('#run')); click('#run');
    await sleep(50); put('R-9', s.id, '', 'kosu_suruyor_pasif', !enabled('#report'));
    await waitFor(() => W().__p4.display && W().__p4.display.source === 'canli' && W().__p4.status === 'st_done');
    const id = `tek-canli-${s.id}`;
    valuesTek('tek', id); await report('tek', id);
    await langSwitch(); await report('tek', id);
    if (s.id === 'C-0.12-1-gmr_1.05') {    // R-6: the report's link reproduces the result
      const link = W().__p4.display.link, rates = W().__p4.display.rows.map((r) => r.rate).join(';'), key = W().__p4.display.key;
      await new Promise((res) => { fr.onload = res; fr.src = link; }); await ready();
      await waitFor(() => enabled('#run')); click('#run');
      await waitFor(() => W().__p4.display && W().__p4.display.source === 'canli' && W().__p4.status === 'st_done');
      put('R-6', id, '', 'ayni_anahtar', W().__p4.display.key === key);
      put('R-6', id, '', 'ayni_sonuc', W().__p4.display.rows.map((r) => r.rate).join(';') === rates);
      // R-9: input change and cancel
      const inp = Dc().querySelector('#form [name=sigma_R]'); inp.value = '0.13'; inp.dispatchEvent(new Event('input', { bubbles: true })); await sleep(400);
      put('R-9', id, '', 'girdi_degisince_pasif', !enabled('#report'));
      inp.value = '0.12'; inp.dispatchEvent(new Event('input', { bubbles: true })); await sleep(400);
      put('R-9', id, '', 'geri_donunce_etkin', enabled('#report'));
      inp.value = '0.13'; inp.dispatchEvent(new Event('input', { bubbles: true }));     // not a grid scenario
      const n = Dc().querySelector('#form [name=n_sim]'); n.value = '15000'; n.dispatchEvent(new Event('input', { bubbles: true }));
      const l = Dc().querySelector('#form [name=l]'); l.value = '6'; l.dispatchEvent(new Event('input', { bubbles: true }));
      const nn = Dc().querySelector('#form [name=n]'); nn.value = '30'; nn.dispatchEvent(new Event('input', { bubbles: true }));
      await sleep(500); await waitFor(() => enabled('#run')); click('#run'); await waitFor(() => W().__p4.status === 'st_running'); await sleep(1500);
      put('R-9', id, '', 'uzun_kosu_pasif', !enabled('#report'));
      click('#cancel'); await waitFor(() => W().__p4.status === 'st_cancelled');
      put('R-9', id, '', 'iptal_sonrasi_pasif', !enabled('#report'));
    }
    log(`tek senaryo, canlı: ${s.id}`);
  }

  // ---- design selection
  for (const c of TAS) {
    await load(tasQs({ ...c.p, lang: 'tr' })); await ready(); await sleep(200);
    put('R-9', c.id, '', 'once_pasif', !enabled('#ts_report'));
    const st = await tasRun();
    put('D', c.id, '', 'durum', st);
    if (!W().__p5.result) { log(`tasarım: ${c.id} → ${st}`); continue; }
    valuesTas(c.id);
    await report('tas', c.id); await langSwitch(); await report('tas', c.id);
    if (c.live) {                                         // D-3: live = precomputed
      const st2 = await tasRun('#ts_live'); put('D-3', c.id, '', 'canli_durum', st2);
      valuesTas(c.id, '-canli');
    }
    if (c.script) {                                       // D-5: the design script of this set
      W().__p5.script = null; click('#ts_script'); await waitFor(() => W().__p5.script);
      files.push(['p5_tasarim_betik.R', enc.encode(W().__p5.script)]); put('D-5', c.id, '', 'betik', 'p5_tasarim_betik.R');
    }
    if (c.id === 'T-A1-pB0.1') {                          // R-6 and R-9 for the design tab
      const link = W().__p5.result.link, tab = JSON.stringify(W().__p5.result.tablo);
      await new Promise((res) => { fr.onload = res; fr.src = link; }); await ready(); await sleep(200);
      await tasRun();
      put('R-6', c.id, '', 'ayni_tablo', JSON.stringify(W().__p5.result.tablo) === tab);
      const h = Dc().querySelector('#ts_form [name=hedef]'); h.value = '85'; h.dispatchEvent(new Event('input', { bubbles: true })); await sleep(300);
      put('R-9', c.id, '', 'girdi_degisince_pasif', !enabled('#ts_report'));
    }
    log(`tasarım: ${c.id} → ${st}`);
  }
  // D-7: above the limit, no live run; cancel
  await load(tasQs({ t_sigma_R: 0.15, t_rho: 1, t_pB_T: 0.1, t_pB_R: 0.1, t_pL: 0.15, t_q: 0, ls: '2-3-4-5-6', ns: '5-8-10-15-20-30', ms: '3', g: 'gmr_1.05', hedef: 80, nsim: 10000, lang: 'tr' })); await ready();
  const st8 = await tasRun();
  put('D-7', 'sinir', '', 'durum', st8); put('D-7', 'sinir', '', 'kosu_yok', !W().__p5.partial && !W().__p5.result);
  put('D-7', 'sinir', '', 'betik_metni', Dc().querySelector('#ts_errors').textContent.includes(T.tr.ts_layer_betik));
  await load(tasQs({ t_sigma_R: 0.15, t_rho: 1, t_pB_T: 0.1, t_pB_R: 0.1, t_pL: 0.15, t_q: 0, ls: '3-4-5', ns: '10-15', ms: '3', g: 'gmr_1.05', hedef: 80, nsim: 10000, lang: 'tr' })); await ready();
  W().__p5.status = null; click('#ts_run');
  await waitFor(() => W().__p5.partial && W().__p5.partial.done >= 2);
  put('R-9', 'tas-iptal', '', 'kosu_suruyor_pasif', !enabled('#ts_report'));
  const tc = performance.now(); click('#ts_cancel'); await waitFor(() => W().__p5.status === 'ts_st_cancelled');
  put('D-7', 'iptal', '', 'durma_ms', Math.round(performance.now() - tc));
  put('D-7', 'iptal', '', 'kismi', Dc().querySelector('#ts_partial').textContent);
  put('D-7', 'iptal', '', 'kismi_gorunur', !Dc().querySelector('#ts_partial').hidden);
  put('D-7', 'iptal', '', 'secim_yok', !W().__p5.result && Dc().querySelector('#ts_result').hidden);
  put('R-9', 'tas-iptal', '', 'iptal_sonrasi_pasif', !enabled('#ts_report'));

  put('R-10', '', '', 'rapor_n', nRep); put('R-10', '', '', 'en_uzun_ms', maxMs.toFixed(1));
  put('ortam', '', '', 'sure_s', Math.round((performance.now() - t0) / 1000));
  log(`Bitti: ${nRep} rapor. “p5_kabul.zip indir” düğmesine basın.`);
  $('#status').textContent = 'Testler: tamamlandı'; window.__p5k_done = true;
  $('#b_zip').disabled = false;
}

function pack() {
  const q = (s) => '"' + String(s).replaceAll('"', '""') + '"';
  const csv = [['bolum', 'senaryo', 'yontem', 'ad', 'deger'].map(q).join(','), ...out.map((r) => r.map(q).join(','))].join('\n') + '\n';
  return zipStored([['p5_tarayici.csv', enc.encode(csv)], ...files]);
}
function download() {
  const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([pack()], { type: 'application/zip' }));
  a.download = 'p5_kabul.zip'; a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}
window.__p5k_out = out;
$('#b_run').addEventListener('click', () => main().catch((e) => { log('HATA: ' + (e.message || e)); $('#status').textContent = 'Testler: hata'; $('#b_zip').disabled = false; }));
$('#b_zip').addEventListener('click', download);
