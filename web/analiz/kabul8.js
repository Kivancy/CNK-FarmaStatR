// CNK-FarmaStatR - EMA acceptance tool (FSR-TN-PLT-08 v0.1, Table 5.1: E-1, E-4, E-5, E-6, E-9; frozen in v0.1).
// Drives the analysis screen (index.html, PBE tab, "Method: EMA 90% CI") in a same-origin frame, reads
// what it shows (DOM) and holds (window.__p6), makes the Word reports with the screen's own report
// function and packs everything into one stored ZIP (p8_kabul.zip): the record p8_tarayici.csv and the
// reports. The comparison with local R is done by belgeler/teknik_notlar/FSR-TN-PLT-08_ek/p8_kabul.R.
// Turkish only (internal tool). Research and education only; not a system validated for GxP environments.

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
  put('E-5', id, sec, 'yeni_istek', reqs().slice(before).filter((u) => !u.startsWith(location.origin)).length);
  put('E-4', id, sec, 'rapor_etkin', enabled(`#${sec}_report`));
  put('E-4', id, sec, 'json_etkin', enabled(`#${sec}_json`));
  if (st().status[sec] === 'an_st_done') {
    const D = st()[sec];
    put('F', id, sec, 'form', JSON.stringify(D.form));
    put('F', id, sec, 'veri', D.data.src);
    put('F', id, sec, 'sonuc', JSON.stringify(D.sonuc, (k, v) => (typeof v === 'number' && !Number.isFinite(v) ? String(v) : v)));
    put('F', id, sec, 'karar_metni', Dc().querySelector(`#${sec}_verdict`).textContent);
    put('F', id, sec, 'ekran', JSON.stringify(texts(`#${sec}_main`)));
    put('F', id, sec, 'yollar', JSON.stringify(texts('#pbe_ema_paths')));
    put('F', id, sec, 'karar_satiri', (Dc().querySelector('#pbe_ema_paths tbody tr:nth-child(2)') || { className: 'NA' }).className);
    put('F', id, sec, 'uyarilar', JSON.stringify([...Dc().querySelectorAll('#pbe_warn p')].map((p) => p.textContent)));
    put('F', id, sec, 'fda_gizli', Dc().querySelector('#pbe_fda_only').hidden);
    put('F', id, sec, 'sure_ms', D.ms.toFixed(0));
  } else {
    put('E-4', id, sec, 'hata', Dc().querySelector(`#${sec}_errors`).textContent);
    put('E-4', id, sec, 'sonuc_gizli', Dc().querySelector(`#${sec}_result`).hidden);
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


const FILES = ['P1_psg020929.csv', 'P2_m1.csv', 'P3_dengesiz.csv', 'P4_tekyon_aktif.csv', 'P5_exp.csv', 'P5_kap_tekrar.csv',
  'P5_negatif.csv', 'P5_stage_hata.csv', 'P6_sinir_esit.csv', 'P6_sinir_ustu.csv'];
const SET = [['ham', false], ['log', true]];
const vis = (sel) => !Dc().querySelector(sel).hidden;

async function main() {
  $('#b_run').disabled = true; $('#status').textContent = 'Testler: çalışıyor';
  const t0 = performance.now();
  put('ortam', '', '', 'tarayici', navigator.userAgent); put('ortam', '', '', 'baslangic', new Date().toISOString());
  put('ortam', '', '', 'adres', location.origin);

  await load('index.html'); await waitFor(() => st() && st().ready); await waitSt('pbe', DATA);
  put('E-6', 'acilis', '', 'durum', st().status.pbe);
  put('E-6', 'acilis', '', 'yontem', Dc().querySelector('#pbe_form [name=yontem]').value);
  put('E-6', 'acilis', '', 'tek_gorunur', vis('#pbe_tek_wrap'));
  put('E-6', 'acilis', '', 'motor', JSON.stringify([...Dc().querySelectorAll('#engine_table tr')].map((r) => [...r.children].map((c) => c.textContent))));
  const bootReq = reqs(); put('E-5', 'acilis', '', 'istekler', JSON.stringify(bootReq));
  await select('pbe_form', 'yontem', 'ema');
  put('E-6', 'ema_secildi', '', 'tek_gorunur', vis('#pbe_tek_wrap'));
  put('E-6', 'ema_secildi', '', 'not_gorunur', vis('#pbe_ema_note'));
  log('analiz ekranı hazır; EMA seçildi');

  // E-1 example (raw and log); E-5 reports; E-6 method switch
  for (const [ad, lg] of SET) {
    await check('pbe_form', 'log_d', lg);
    await run('pbe', `ema-ornek-${ad}`);
    if (ad === 'ham') {
      await report('pbe', 'ema-ornek-ham'); await langSwitch(); await report('pbe', 'ema-ornek-ham');
      put('E-9', 'ema-ornek-ham', 'en', 'ekran', JSON.stringify(texts('#pbe_main')));
      put('E-9', 'ema-ornek-ham', 'en', 'yollar', JSON.stringify(texts('#pbe_ema_paths')));
      await sleep(1100); const r = st().makeReport('pbe'); files.push(['raporlar/ema-ornek-ham_en_tekrar.docx', r.bytes]);
      put('R-7', 'ema-ornek-ham', 'en', 'dosya', 'raporlar/ema-ornek-ham_en_tekrar.docx');
      await langSwitch();
      await check('pbe_form', 'log_d', true); await sleep(100);
      put('E-6', 'girdi_degisti', '', 'rapor_etkin', enabled('#pbe_report'));
      await check('pbe_form', 'log_d', false); await sleep(100);
      put('E-6', 'girdi_geri', '', 'rapor_etkin', enabled('#pbe_report'));
      await select('pbe_form', 'yontem', 'fda');
      put('E-6', 'fda_secildi', '', 'rapor_etkin', enabled('#pbe_report'));
      put('E-6', 'fda_secildi', '', 'sonuc_gizli', Dc().querySelector('#pbe_result').hidden);
      put('E-6', 'fda_secildi', '', 'tek_gorunur', vis('#pbe_tek_wrap'));
      await run('pbe', 'fda-ornek-ham');
      put('E-6', 'fda-ornek-ham', '', 'ema_gizli', Dc().querySelector('#pbe_ema_only').hidden);
      await select('pbe_form', 'yontem', 'ema');
      put('E-6', 'ema_geri', '', 'rapor_etkin', enabled('#pbe_report'));
      put('E-6', 'ema_geri', '', 'sonuc_gizli', Dc().querySelector('#pbe_result').hidden);
    }
  }
  log('EMA örnek: ham ve log; yöntem geçişi');
  // E-1, E-4 test data files
  for (const f of FILES) {
    const b = await fetchBytes('CNKfarmastatr/inst/validasyon/pbe/test_verisi/' + f);
    await upload('pbe', f, b); put('F', f, 'pbe', 'veri_durumu', st().status.pbe);
    for (const [ad, lg] of SET) { await check('pbe_form', 'log_d', lg); await run('pbe', `${f}|${ad}`); }
    log(`test verisi: ${f}`);
  }
  // one report for a file with a non-computable path (warnings in the report)
  await upload('pbe', 'P6_sinir_esit.csv', await fetchBytes('CNKfarmastatr/inst/validasyon/pbe/test_verisi/P6_sinir_esit.csv'));
  await check('pbe_form', 'log_d', false); await run('pbe', 'P6_sinir_esit.csv|rapor');
  await report('pbe', 'ema-p6-sinir-esit');
  // E-1 Turkish CSV
  await upload('pbe', 'psg020929_tr.csv', await fetchBytes('belgeler/teknik_notlar/FSR-TN-PLT-06_ek/veri/psg020929_tr.csv'));
  await check('pbe_form', 'log_d', false);
  await run('pbe', 'ema-csv-tr');

  // E-9 narrow screen (390 px) with the EMA result shown
  fr.style.width = '390px'; await sleep(400);
  put('E-9', 'dar', 'pbe', 'yatay_kaydirma', Dc().documentElement.scrollWidth > Dc().documentElement.clientWidth + 1);
  fr.style.width = '';
  put('E-5', 'son', '', 'dis_istek', reqs().slice(bootReq.length).filter((u) => !u.startsWith(location.origin)).length);

  put('R-10', '', '', 'rapor_n', nRep); put('R-10', '', '', 'en_uzun_ms', maxMs.toFixed(1));
  put('ortam', '', '', 'sure_s', Math.round((performance.now() - t0) / 1000));
  log(`Bitti: ${nRep} rapor. “p8_kabul.zip indir” düğmesine basın.`);
  $('#status').textContent = 'Testler: tamamlandı'; window.__p8k_done = true;
  $('#b_zip').disabled = false;
}

function pack() {
  const q = (s) => '"' + String(s).replaceAll('"', '""') + '"';
  const csv = [['bolum', 'durum', 'ayar', 'ad', 'deger'].map(q).join(','), ...out.map((r) => r.map(q).join(','))].join('\n') + '\n';
  return zipStored([['p8_tarayici.csv', enc.encode(csv)], ...files]);
}
function download() {
  const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([pack()], { type: 'application/zip' }));
  a.download = 'p8_kabul.zip'; a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}
window.__p8k_out = out; window.__p8k_pack = pack;
$('#b_run').addEventListener('click', () => main().catch((e) => { log('HATA: ' + (e.message || e)); $('#status').textContent = 'Testler: hata'; $('#b_zip').disabled = false; }));
$('#b_zip').addEventListener('click', download);
