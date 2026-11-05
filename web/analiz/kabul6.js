// CNK-FarmaStatR - P6 acceptance tool (FSR-TN-PLT-06 v0.1, Table 7.1: F-1 ... F-12; frozen in v0.1).
// Revised for FSR-TN-PLT-09 v0.1 (KK-66): the Weibull B-L2b case is removed (no longer offered on the
// screen; the core test stays in testthat) and the region options are recorded (G-2).
// Drives the analysis screen (index.html) and the validation page (dogrula.html) in a same-origin
// frame, reads what they show (DOM) and hold (window.__p6, window.__p6v), makes the Word reports with
// the screen's own report function and packs everything into one stored ZIP (p6_kabul.zip): the
// record p6_tarayici.csv and the reports. The comparison with local R is done by
// belgeler/teknik_notlar/FSR-TN-PLT-06_ek/p6_kabul.R. Turkish only (internal tool).
// FSR-TN-PLT-11 v0.1 (KK-75): rows 'D', 'D-8' for Section 9 'Analysed data' of the analysis reports.
// FSR-TN-PLT-12 (KK-78): rows 'W' for the wide layout of dissolution data (W-0 ... W-11).
// Research and education only; not a system validated for GxP environments.

import { zipStored } from '../app/rapor.js';
import { fetchBytes } from '../p1/motor.js';

const Q = new URLSearchParams(location.search);
const PASS = ['webr', 'sqljs'].filter((k) => Q.get(k)).map((k) => `${k}=${encodeURIComponent(Q.get(k))}`).join('&');
const $ = (s) => document.querySelector(s);
const fr = $('#fr');
const W = () => fr.contentWindow, Dc = () => fr.contentDocument;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const out = [], files = [];
const enc = new TextEncoder();
const put = (bolum, durum, ayar, ad, deger) => out.push([bolum, durum, ayar, ad, deger === null || deger === undefined ? 'NA' : String(deger)]);
let nRep = 0, maxMs = 0;
function log(s) { const l = $('#log'); l.textContent += `[${new Date().toLocaleTimeString()}] ${s}\n`; l.scrollTop = l.scrollHeight; }
async function waitFor(fn, ms = 1800000) {
  const t0 = performance.now();
  for (;;) { try { const v = fn(); if (v) return v; } catch (e) { /* frame loading */ } if (performance.now() - t0 > ms) throw new Error('zaman aşımı'); await sleep(100); }
}
const load = (page, params = '') => new Promise((res) => { fr.onload = () => res(); fr.src = page + '?' + [params, PASS].filter(Boolean).join('&'); });
const enabled = (sel) => !Dc().querySelector(sel).disabled;
const reqs = () => W().performance.getEntriesByType('resource').map((e) => e.name);
const st = () => W().__p6;
const waitSt = (sec, keys) => waitFor(() => keys.includes(st().status[sec]));
const DONE = ['an_st_done', 'an_st_error'], DATA = ['an_st_data_ok', 'an_st_data_error', 'st_blocked', 'st_error'];
async function select(form, name, v) { const e = Dc().querySelector(`#${form} [name=${name}]`); e.value = v; e.dispatchEvent(new Event('change', { bubbles: true })); e.dispatchEvent(new Event('input', { bubbles: true })); await sleep(50); }
async function check(form, name, v) { const e = Dc().querySelector(`#${form} [name=${name}]`); e.checked = v; e.dispatchEvent(new Event('input', { bubbles: true })); await sleep(50); }
async function upload(sec, name, bytes) {
  await select(`${sec}_form`, 'kaynak', 'dosya');
  const inp = Dc().querySelector(`#${sec}_form [name=dosya]`);
  const dt = new (W().DataTransfer)(); dt.items.add(new (W().File)([bytes], name, { type: 'text/csv' }));
  inp.files = dt.files; st().status[sec] = null;
  inp.dispatchEvent(new Event('change', { bubbles: true }));
  await waitSt(sec, DATA);
}
async function langSwitch() { Dc().querySelector('#lang').click(); await sleep(200); }
const texts = (sel) => [...Dc().querySelectorAll(sel + ' tr')].map((r) => [...r.children].map((c) => c.textContent));

// one analysis: run, then record the result object, the screen texts and the button states
async function run(sec, id) {
  const before = reqs().length;
  st().status[sec] = null; Dc().querySelector(`#${sec}_run`).click();
  const s = await waitSt(sec, DONE); await sleep(100);
  put('F', id, sec, 'durum', st().status[sec]);
  put('F-8', id, sec, 'yeni_istek', reqs().slice(before).filter((u) => !u.startsWith(location.origin)).length);
  put('F-2', id, sec, 'rapor_etkin', enabled(`#${sec}_report`));
  put('F-2', id, sec, 'json_etkin', enabled(`#${sec}_json`));
  if (st().status[sec] === 'an_st_done') {
    const D = st()[sec];
    put('F', id, sec, 'form', JSON.stringify(D.form));
    put('F', id, sec, 'veri', D.data.src);
    put('F', id, sec, 'sonuc', JSON.stringify(D.sonuc, (k, v) => (typeof v === 'number' && !Number.isFinite(v) ? String(v) : v)));
    put('F', id, sec, 'karar_metni', Dc().querySelector(`#${sec}_verdict`).textContent);
    put('F', id, sec, 'ekran', JSON.stringify(texts(`#${sec}_main`)));
    put('F', id, sec, 'sure_ms', D.ms.toFixed(0));
  } else {
    put('F-2', id, sec, 'hata', Dc().querySelector(`#${sec}_errors`).textContent);
    put('F-2', id, sec, 'sonuc_gizli', Dc().querySelector(`#${sec}_result`).hidden);
  }
  return s;
}
async function report(sec, id) {
  const lang = Dc().documentElement.lang, r0 = reqs().length;
  const r = st().makeReport(sec);
  const name = `raporlar/${id}_${lang}.docx`;
  files.push([name, r.bytes]); nRep++; maxMs = Math.max(maxMs, r.ms);
  put('R', id, lang, 'dosya', name); put('R', id, lang, 'tur', sec); put('R', id, lang, 'ms', r.ms.toFixed(1));
  put('R', id, lang, 'ag_istegi', reqs().length - r0);
  put('R', id, lang, 'gorunum', JSON.stringify(st().view(sec)));
  return r;
}

const PBE_FILES = ['P1_psg020929.csv', 'P2_m1.csv', 'P3_dengesiz.csv', 'P4_tekyon_aktif.csv', 'P5_exp.csv', 'P5_kap_tekrar.csv',
  'P5_negatif.csv', 'P5_stage_hata.csv', 'P6_sinir_esit.csv', 'P6_sinir_ustu.csv'];
const PBE_SET = [['ham', false, false], ['log', true, false], ['tek', false, true]];
const DIS = [['tsong1996', 'msd', { sinir: 'L1', kesme: 'none' }], ['tsong1996', 'msd', { sinir: 'L2a', kesme: 'none' }],
  ['tsong1996', 'msd', { sinir: 'L2b', kesme: 'FDA' }], ['tsong1996', 'weibull', { param: 'lnTd_lnB', bolge: 'B-L3' }],
  ['tsong1996', 'weibull', { param: 'lnA_lnB', bolge: 'B-L2a' }],
  ['tsong1996', 'f2', { perspektif: 'EMA', gatipi: 'persentil' }], ['noce2020', 'f2', { perspektif: 'EMA', gatipi: 'persentil' }],
  ['noce2020', 'f2', { perspektif: 'FDA', gatipi: 'persentil' }], ['noce2020', 'f2', { perspektif: 'EMA', gatipi: 'BCa' }]];

async function main() {
  $('#b_run').disabled = true; $('#status').textContent = 'Testler: çalışıyor';
  const t0 = performance.now();
  put('ortam', '', '', 'tarayici', navigator.userAgent); put('ortam', '', '', 'baslangic', new Date().toISOString());
  put('ortam', '', '', 'adres', location.origin);

  // ---- analysis screen
  await load('index.html'); await waitFor(() => st() && st().ready); await waitSt('pbe', DATA);
  put('F-10', 'motor', '', 'durum', st().status.pbe);
  put('F-10', 'motor', '', 'dosyalar', JSON.stringify([...Dc().querySelectorAll('#engine_table tr')].map((r) => [...r.children].map((c) => c.textContent))));
  const bootReq = reqs(); put('F-8', 'acilis', '', 'istekler', JSON.stringify(bootReq));
  log(`analiz ekranı hazır (${st().status.pbe})`);
  put('F-2', 'once', 'pbe', 'rapor_etkin', enabled('#pbe_report'));

  // F-1 PBE example
  for (const [ad, lg, tek] of PBE_SET) {
    await check('pbe_form', 'log_d', lg); await check('pbe_form', 'tek', tek);
    await run('pbe', `pbe-ornek-${ad}`);
    if (ad === 'ham') {
      await report('pbe', 'pbe-ornek-ham'); await langSwitch(); await report('pbe', 'pbe-ornek-ham');
      await sleep(1100); const r = st().makeReport('pbe'); files.push(['raporlar/pbe-ornek-ham_en_tekrar.docx', r.bytes]);
      put('R-7', 'pbe-ornek-ham', 'en', 'dosya', 'raporlar/pbe-ornek-ham_en_tekrar.docx');
      await langSwitch();
      await check('pbe_form', 'tek', true); await sleep(100);
      put('F-2', 'pbe-ornek-ham', 'pbe', 'girdi_degisince_rapor_etkin', enabled('#pbe_report'));
      await check('pbe_form', 'tek', false);
    }
  }
  log('PBE örnek: 3 ayar');
  // F-1, F-2 PBE test data files
  for (const f of PBE_FILES) {
    const b = await fetchBytes('CNKfarmastatr/inst/validasyon/pbe/test_verisi/' + f);
    await upload('pbe', f, b); put('F', f, 'pbe', 'veri_durumu', st().status.pbe);
    for (const [ad, lg, tek] of PBE_SET) {
      await check('pbe_form', 'log_d', lg); await check('pbe_form', 'tek', tek);
      await run('pbe', `${f}|${ad}`);
    }
    log(`PBE test verisi: ${f}`);
  }
  // F-6 PBE Turkish CSV
  await upload('pbe', 'psg020929_tr.csv', await fetchBytes('belgeler/teknik_notlar/FSR-TN-PLT-06_ek/veri/psg020929_tr.csv'));
  await check('pbe_form', 'log_d', false); await check('pbe_form', 'tek', false);
  await run('pbe', 'pbe-csv-tr');

  // ---- dissolution
  Dc().querySelector('#tab_dis').click(); await waitSt('dis', DATA);
  put('P9-G2', 'weibull', '', 'bolge_secenekleri', JSON.stringify([...Dc().querySelectorAll('#dis_form [name=bolge] option')].map((o) => o.value)));
  let cur = 'tsong1996';
  for (const [src, y, set] of DIS) {
    if (src !== cur) { st().status.dis = null; await select('dis_form', 'kaynak', src); await waitSt('dis', DATA); cur = src; }
    await select('dis_form', 'yontem', y);
    for (const [k, v] of Object.entries(set)) await select('dis_form', k, v);
    const id = `${src}|${y}|${Object.values(set).join('-')}`;
    await run('dis', id);
    if (['tsong1996|msd|L2a-none', 'tsong1996|weibull|lnA_lnB-B-L2a', 'noce2020|f2|EMA-persentil'].includes(id)) {
      const rid = id.replace(/\|/g, '_');
      await report('dis', rid); await langSwitch(); await report('dis', rid); await langSwitch();
    }
    log(`dissolüsyon: ${id}`);
  }
  // F-6 dissolution Turkish CSV (MSD L2a with the two reference lots)
  await upload('dis', 'tsong1996_tr.csv', await fetchBytes('belgeler/teknik_notlar/FSR-TN-PLT-06_ek/veri/tsong1996_tr.csv'));
  for (const i of Dc().querySelectorAll('#dis_form input[name=lot]')) { i.checked = ['STD1', 'STD2'].includes(i.value); }
  await select('dis_form', 'yontem', 'msd'); await select('dis_form', 'sinir', 'L2a'); await select('dis_form', 'kesme', 'none');
  await run('dis', 'dis-csv-tr');
  // F-2 dissolution input error: L2a without reference lots
  for (const i of Dc().querySelectorAll('#dis_form input[name=lot]')) i.checked = false;
  await run('dis', 'dis-l2a-lotsuz');

  // ---- FSR-TN-PLT-11 (KK-75): Section 9 'Analysed data'; D-1 ... D-4, D-8 (rows 'D')
  const runD = async (sec) => { st().status[sec] = null; Dc().querySelector(`#${sec}_run`).click(); await waitSt(sec, DONE); await sleep(100);
    put('D', sec, '', 'durum', st().status[sec]); };                  // no 'F' rows: the F-* counts stay as frozen
  const withData = async (sec, v) => { const e = Dc().querySelector(`#${sec}_with_data`); e.checked = v; await sleep(50); };
  put('D-8', 'kutu', 'pbe', 'varsayilan_isaretli', Dc().querySelector('#pbe_with_data').checked);
  put('D-8', 'kutu', 'dis', 'varsayilan_isaretli', Dc().querySelector('#dis_with_data').checked);
  const dRep = async (sec, id, wd) => {
    await withData(sec, wd);
    const lang = Dc().documentElement.lang, r0 = reqs().length, r = st().makeReport(sec), name = `raporlar/d11_${id}_${wd ? 'veri' : 'veri-yok'}_${lang}.docx`;
    files.push([name, r.bytes]);
    put('D', `${id}|${wd ? 1 : 0}`, lang, 'dosya', name); put('D', `${id}|${wd ? 1 : 0}`, lang, 'ag_istegi', reqs().length - r0);
    await withData(sec, false); return r;
  };
  // D-dis: Turkish CSV of Tsong 1996 is loaded above (dis-csv-tr); rerun MSD L2a with lots for a report
  for (const i of Dc().querySelectorAll('#dis_form input[name=lot]')) { i.checked = ['STD1', 'STD2'].includes(i.value); }
  await runD('dis');
  put('D', 'dis', '', 'kaynak', 'belgeler/teknik_notlar/FSR-TN-PLT-06_ek/veri/tsong1996_tr.csv');
  put('D', 'dis', '', 'ekran', Dc().querySelector('#dis_data_info').textContent);
  put('D', 'dis', '', 'form', JSON.stringify(st().dis.form));
  await dRep('dis', 'dis', false); await dRep('dis', 'dis', true); await langSwitch(); await dRep('dis', 'dis', true); await langSwitch();

  // ---- FSR-TN-PLT-12 (KK-78): wide layout of dissolution data; rows 'W' (no 'F' rows: F counts stay as frozen)
  const WV = 'belgeler/teknik_notlar/FSR-TN-PLT-12_ek/veri/';
  const wLoad = async (id, sec, f) => {
    await upload(sec, f, await fetchBytes(WV + f));
    put('W', id, sec, 'kaynak', WV + f); put('W', id, sec, 'veri_durum', st().status[sec]);
    put('W', id, sec, 'ekran', Dc().querySelector(`#${sec}_data_info`).textContent);
    put('W', id, sec, 'hata', Dc().querySelector(`#${sec}_errors`).textContent);
    if (sec === 'dis') { put('W', id, sec, 'test_varsayilan', Dc().querySelector('#dis_form [name=test]').value);
      put('W', id, sec, 'ref_varsayilan', Dc().querySelector('#dis_form [name=ref]').value); }
  };
  const wRun = async (id) => {
    st().status.dis = null; Dc().querySelector('#dis_run').click(); await waitSt('dis', DONE); await sleep(100);
    put('W', id, 'dis', 'durum', st().status.dis);
    if (st().status.dis === 'an_st_done') { put('W', id, 'dis', 'form', JSON.stringify(st().dis.form));
      put('W', id, 'dis', 'sonuc', JSON.stringify(st().dis.sonuc, (k, v) => (typeof v === 'number' && !Number.isFinite(v) ? String(v) : v))); }
  };
  // W-1, W-3, W-4, W-7, W-8, W-9: Tsong 1996 in the DDSolver layout (';', decimal comma, second header row)
  await wLoad('tsong-genis', 'dis', 'tsong1996_genis_ddsolver.csv');
  for (const i of Dc().querySelectorAll('#dis_form input[name=lot]')) i.checked = ['STD1', 'STD2'].includes(i.value);
  await select('dis_form', 'yontem', 'msd'); await select('dis_form', 'sinir', 'L2a'); await select('dis_form', 'kesme', 'none');
  await wRun('tsong-genis');
  await withData('dis', true);
  { const lang = Dc().documentElement.lang, r0 = reqs().length, r = st().makeReport('dis'), name = `raporlar/w12_tsong-genis_veri_${lang}.docx`;
    files.push([name, r.bytes]); put('W', 'tsong-genis', lang, 'rapor', name); put('W', 'tsong-genis', lang, 'ag_istegi', reqs().length - r0); }
  await withData('dis', false);
  // W-7 fallback (first two products), W-8 f2 with the EMA preset: Noce 2020 in the wide layout
  await wLoad('noce-genis', 'dis', 'noce2020_genis.csv');
  await select('dis_form', 'yontem', 'f2');
  await wRun('noce-genis');
  // W-5 empty cell: data error on the screen
  await wLoad('bos-hucre', 'dis', 'hata_bos_hucre.csv');
  put('W', 'bos-hucre', 'dis', 'calistir_etkin', enabled('#dis_run'));
  log('FSR-TN-PLT-12: geniş biçim (dissolüsyon)');
  // W-0 the PBE panel does not read the wide layout (checked below with the PBE tab)
  // D-pbe: test data file P1 (PSG example as a file)
  Dc().querySelector('#tab_pbe').click(); await sleep(200);
  await wLoad('pbe-genis', 'pbe', 'tsong1996_genis_ddsolver.csv');                  // W-0 (FSR-TN-PLT-12)
  put('W', 'pbe-genis', 'pbe', 'calistir_etkin', enabled('#pbe_run'));
  await upload('pbe', 'P1_psg020929.csv', await fetchBytes('CNKfarmastatr/inst/validasyon/pbe/test_verisi/P1_psg020929.csv'));
  await check('pbe_form', 'log_d', false); await check('pbe_form', 'tek', false);
  await runD('pbe');
  put('D', 'pbe', '', 'kaynak', 'CNKfarmastatr/inst/validasyon/pbe/test_verisi/P1_psg020929.csv');
  put('D', 'pbe', '', 'ekran', Dc().querySelector('#pbe_data_info').textContent);
  put('D', 'pbe', '', 'form', JSON.stringify(st().pbe.form));
  await dRep('pbe', 'pbe', false); await dRep('pbe', 'pbe', true);
  await sleep(1100); await dRep('pbe', 'pbe-tekrar', true);           // D-4 determinism with the data table
  await langSwitch(); await dRep('pbe', 'pbe', true); await langSwitch();
  log('FSR-TN-PLT-11: veri bölümü');

  // ---- F-11 narrow screen (390 px): no horizontal scrolling on either tab
  fr.style.width = '390px'; await sleep(400);
  for (const tab of ['pbe', 'dis']) {
    Dc().querySelector('#tab_' + tab).click(); await sleep(300);
    put('F-11', 'dar', tab, 'yatay_kaydirma', Dc().documentElement.scrollWidth > Dc().documentElement.clientWidth + 1);
  }
  fr.style.width = '';
  put('F-8', 'son', '', 'dis_istek', reqs().slice(bootReq.length).filter((u) => !u.startsWith(location.origin)).length);

  // ---- F-10 the P5 report with the P6 rapor.js (same precomputed scenario as tek-hazir-1 of P5)
  await new Promise((res) => { fr.onload = res; fr.src = '../app/index.html?' + ['sR=0.06&rho=1&pBT=0.3&pBR=0.3&pL=0.15&q=0&l=3&n=10&m=3&nsim=10000&seed=20261015&d=ema_1.18&lang=tr', PASS].filter(Boolean).join('&'); });
  await waitFor(() => W().__p4 && W().__p4.ready);
  await waitFor(() => W().__p4.display && W().__p4.display.source === 'hazir');
  const r5 = W().__p4.makeReport(); files.push(['raporlar/p5_tek-hazir-1_tr.docx', r5.bytes]);
  put('F-10', 'p5', 'tr', 'dosya', 'raporlar/p5_tek-hazir-1_tr.docx');
  log('P5 raporu (gerileme)');

  // ---- F-9 validation in the browser
  await load('dogrula.html'); await waitFor(() => W().__p6v && W().__p6v.ready, 600000);
  put('F-9', 'yukleme', '', 'durum', W().__p6v.status);
  log('doğrulama: devralınan setler'); await W().__p6v.runLeg();
  for (const r of W().__p6v.leg) put('F-9', r.script, '', 'gecen_beklenen', `${r.passed}/${r.rows}/${r.expected}`);
  log('doğrulama: paket testleri'); await W().__p6v.runTests();
  for (const r of W().__p6v.tests) put('F-9', r.file, r.test, 'nb_fail_err_skip', `${r.nb}/${r.failed}/${r.error}/${r.skipped}`);
  for (const [k, v] of Object.entries(W().__p6v.env)) put('F-9', 'ortam', '', k, v);

  put('R-10', '', '', 'rapor_n', nRep); put('R-10', '', '', 'en_uzun_ms', maxMs.toFixed(1));
  put('ortam', '', '', 'sure_s', Math.round((performance.now() - t0) / 1000));
  log(`Bitti: ${nRep} rapor. “p6_kabul.zip indir” düğmesine basın.`);
  $('#status').textContent = 'Testler: tamamlandı'; window.__p6k_done = true;
  $('#b_zip').disabled = false;
}

function pack() {
  const q = (s) => '"' + String(s).replaceAll('"', '""') + '"';
  const csv = [['bolum', 'durum', 'ayar', 'ad', 'deger'].map(q).join(','), ...out.map((r) => r.map(q).join(','))].join('\n') + '\n';
  return zipStored([['p6_tarayici.csv', enc.encode(csv)], ...files]);
}
function download() {
  const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([pack()], { type: 'application/zip' }));
  a.download = 'p6_kabul.zip'; a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}
window.__p6k_out = out; window.__p6k_pack = pack;
$('#b_run').addEventListener('click', () => main().catch((e) => { log('HATA: ' + (e.message || e)); $('#status').textContent = 'Testler: hata'; $('#b_zip').disabled = false; }));
$('#b_zip').addEventListener('click', download);
