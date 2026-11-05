// CNK-FarmaStatR - help acceptance tool (FSR-TN-PLT-07 v0.1, Table 6.1: Y-1 ... Y-9, Y-11; v0.2: six notes).
// FSR-TN-PLT-09 v0.1 (KK-66): the Y-3 counter counts the label “Tasarım gereği” / “By design”.
// FSR-TN-PLT-10 v0.1 (KK-72): B-1 ... B-5 for the plain-words pages basit_<note>.html (rows 'B-*').
// Drives the simulation screen, the analysis screen and the method notes in a same-origin frame,
// records what they show and hold, and packs the record into one stored ZIP (p7_kabul.zip).
// The comparison with local R (numbers of the worked examples, templates) and the verdicts are
// made by belgeler/teknik_notlar/FSR-TN-PLT-07_ek/p7_kabul.R. Turkish only (internal tool).
// Research and education only; not a system validated for GxP environments.

import { zipStored } from '../app/rapor.js';
import { fetchBytes } from '../p1/motor.js';

const Q = new URLSearchParams(location.search);
const PASS = ['webr', 'sqljs'].filter((k) => Q.get(k)).map((k) => `${k}=${encodeURIComponent(Q.get(k))}`).join('&');
const $ = (s) => document.querySelector(s);
const fr = $('#fr');
const W = () => fr.contentWindow, Dc = () => fr.contentDocument;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const out = [];
const enc = new TextEncoder();
const put = (bolum, durum, ayar, ad, deger) => out.push([bolum, durum, ayar, ad, deger === null || deger === undefined ? 'NA' : String(deger)]);
const NOTES = ['pbe', 'ema', 'f2', 'msd', 'weibull', 'simulasyon', 'index'];   // ema: FSR-TN-PLT-07 v0.2 (KK-64)
let H = null;
function log(s) { const l = $('#log'); l.textContent += `[${new Date().toLocaleTimeString()}] ${s}\n`; l.scrollTop = l.scrollHeight; }
async function waitFor(fn, ms = 600000) {
  const t0 = performance.now();
  for (;;) { try { const v = fn(); if (v) return v; } catch (e) { /* frame loading */ } if (performance.now() - t0 > ms) throw new Error('zaman aşımı'); await sleep(100); }
}
const load = (url) => new Promise((res) => { fr.onload = () => res(); fr.src = url + (url.includes('?') ? '&' : '?') + PASS; });
const reqs = () => W().performance.getEntriesByType('resource').map((e) => e.name);
const ext = (list) => list.filter((u) => !u.startsWith(location.origin)).length;
async function lang(to) { if (Dc().documentElement.lang !== to) { Dc().querySelector('#lang').click(); await waitFor(() => Dc().documentElement.lang === to); await sleep(150); } }
async function tab(id) { const t = Dc().getElementById(id); if (t) { t.click(); await sleep(250); } }
const links = new Set();

// Y-1: every form field has a hint, the hint opens with its text and closes
async function hints(scr, formSel) {
  const f = Dc().querySelector(formSel);
  const fields = [...f.querySelectorAll('input[name], select[name]')].filter((e) => !(e.type === 'checkbox' && e.name === 'lot'));
  let missing = [];
  for (const e of fields) { const l = e.closest('[data-help]'); if (!l) missing.push(e.name); }
  put('Y-1', scr, '', 'alan_sayisi', fields.length);
  put('Y-1', scr, '', 'ipucusuz_alan', missing.join(';'));
  for (const lg of ['tr', 'en']) {
    await lang(lg);
    let ok = 0, bad = [];
    for (const el of f.querySelectorAll('[data-help]')) {
      const k = el.dataset.help, b = el.querySelector('.yh-q'), pop = el.querySelector(':scope > .yh-pop');
      const want = H[lg].ipucu[k];
      b.click(); await sleep(20);
      const shown = !pop.hidden && pop.textContent === want && b.getAttribute('aria-expanded') === 'true';
      b.click(); await sleep(20);
      const closed = pop.hidden && b.getAttribute('aria-expanded') === 'false';
      const acc = b.tagName === 'BUTTON' && b.type === 'button' && (b.getAttribute('aria-label') || '').length > 3;
      if (shown && closed && acc && want && want.trim()) ok++; else bad.push(k);
    }
    put('Y-1', scr, lg, 'ipucu_tamam', ok);
    put('Y-1', scr, lg, 'ipucu_hatali', bad.join(';'));
  }
}
// Y-2: panel of the visible tab, six sections, follows the language
async function panel(scr) {
  for (const lg of ['tr', 'en']) {
    await lang(lg);
    const r0 = reqs().length;
    Dc().getElementById('yh_btn').click(); await sleep(150);
    const p = Dc().getElementById('yh_panel');
    const secs = [...p.querySelectorAll('.yh-sec')];
    const title = p.querySelector('#yh_title').textContent;
    const want = H[lg].panel[scr];
    const same = secs.length === 6 && secs.every((s, i) => s.dataset.sec === want[i].id && s.querySelector('h3').textContent === H[lg].ui.sections[want[i].id] && s.textContent.trim().length > 40);
    put('Y-2', scr, lg, 'baslik', title);
    put('Y-2', scr, lg, 'baslik_dogru', title.includes(H[lg].ui.screens[scr]));
    put('Y-2', scr, lg, 'bolum_sayisi', secs.length);
    put('Y-2', scr, lg, 'bolumler_dogru', same);
    put('Y-9', scr, lg, 'odak_baslikta', Dc().activeElement === p.querySelector('#yh_title'));
    for (const a of p.querySelectorAll('a[href]')) links.add(a.href.split('#')[0]);
    // the language button while the panel is open
    const other = lg === 'tr' ? 'en' : 'tr';
    await lang(other);
    put('Y-2', scr, lg, 'dil_degisince_yenilendi', p.querySelector('#yh_title').textContent.includes(H[other].ui.screens[scr]));
    await lang(lg);
    Dc().dispatchEvent(new (W().KeyboardEvent)('keydown', { key: 'Escape', bubbles: true })); await sleep(100);
    put('Y-9', scr, lg, 'esc_kapatti', p.hidden);
    put('Y-7', scr, lg, 'dis_istek', ext(reqs().slice(r0)));
  }
}
async function narrow(scr) {
  fr.style.width = '390px'; await sleep(300);
  Dc().getElementById('yh_btn').click(); await sleep(150);
  const de = Dc().documentElement;
  put('Y-8', scr, '', 'panel_yatay_kaydirma', de.scrollWidth > de.clientWidth + 1);
  const p = Dc().getElementById('yh_panel');
  put('Y-8', scr, '', 'panel_genislik', `${Math.round(p.getBoundingClientRect().width)}/${de.clientWidth}`);
  Dc().getElementById('yh_btn').click(); await sleep(100);
  fr.style.width = '';
}

async function main() {
  $('#b_run').disabled = true; $('#status').textContent = 'Testler: çalışıyor';
  const t0 = performance.now();
  put('ortam', '', '', 'tarayici', navigator.userAgent); put('ortam', '', '', 'baslangic', new Date().toISOString());
  H = JSON.parse(new TextDecoder().decode(await fetchBytes('web/yardim/yardim.json')));

  // ---- simulation screen
  await load('../app/index.html?lang=tr'); await waitFor(() => W().__yardim && W().__yardim.ready);
  put('Y-9', 'app', '', 'yardim_dugmesi', (() => { const b = Dc().getElementById('yh_btn'); return b.tagName === 'BUTTON' && b.textContent.length > 0; })());
  await hints('tek', '#form'); await panel('tek'); await narrow('tek');
  await tab('tab_tas'); await hints('tas', '#ts_form'); await panel('tas');
  log('simülasyon ekranı');

  // ---- analysis screen
  await load('../analiz/index.html?lang=tr'); await waitFor(() => W().__yardim && W().__yardim.ready && W().__p6 && W().__p6.ready);
  await waitFor(() => ['an_st_data_ok', 'st_blocked', 'st_error'].includes(W().__p6.status.pbe));
  await hints('pbe', '#pbe_form'); await panel('pbe'); await narrow('pbe');
  // Y-11: decision text of the PBE example
  for (const lg of ['tr', 'en']) {
    await lang(lg);
    W().__p6.status.pbe = null; Dc().querySelector('#pbe_run').click();
    await waitFor(() => ['an_st_done', 'an_st_error'].includes(W().__p6.status.pbe));
    put('Y-11', 'pbe', lg, 'karar_metni', Dc().querySelector('#pbe_verdict').textContent);
    put('Y-11', 'pbe', lg, 'rapor_gorunum', JSON.stringify(W().__p6.view('pbe').verdict));
  }
  await lang('tr');
  await tab('tab_dis'); await waitFor(() => ['an_st_data_ok', 'st_blocked', 'st_error'].includes(W().__p6.status.dis));
  await hints('dis', '#dis_form'); await panel('dis');
  log('analiz ekranı');

  // ---- Y-5 templates: read on the screen, default analysis, result recorded for R
  const upload = async (sec, path) => {
    const sel = Dc().querySelector(`#${sec}_form [name=kaynak]`); sel.value = 'dosya'; sel.dispatchEvent(new Event('change', { bubbles: true })); await sleep(50);
    const inp = Dc().querySelector(`#${sec}_form [name=dosya]`);
    const dt = new (W().DataTransfer)(); dt.items.add(new (W().File)([await fetchBytes(path)], path.split('/').pop(), { type: 'text/csv' }));
    inp.files = dt.files; W().__p6.status[sec] = null; inp.dispatchEvent(new Event('change', { bubbles: true }));
    await waitFor(() => ['an_st_data_ok', 'an_st_data_error'].includes(W().__p6.status[sec]));
    return W().__p6.status[sec];
  };
  const run = async (sec) => { W().__p6.status[sec] = null; Dc().querySelector(`#${sec}_run`).click(); await waitFor(() => ['an_st_done', 'an_st_error'].includes(W().__p6.status[sec])); return W().__p6.status[sec]; };
  await tab('tab_pbe');
  for (const f of ['pbe_sablon_en.csv']) {   // Turkish template removed (KK-77, FSR-LOG-01 G-138)
    put('Y-5', f, 'pbe', 'veri', await upload('pbe', 'web/yardim/sablon/' + f));
    Dc().querySelector('#pbe_form [name=log_d]').checked = false; Dc().querySelector('#pbe_form [name=tek]').checked = false;
    put('Y-5', f, 'pbe', 'durum', await run('pbe'));
    put('Y-5', f, 'pbe', 'sonuc', JSON.stringify(W().__p6.pbe && W().__p6.pbe.sonuc));
  }
  await tab('tab_dis');
  for (const f of ['dis_sablon_en.csv']) {   // Turkish template removed (KK-77)
    put('Y-5', f, 'dis', 'veri', await upload('dis', 'web/yardim/sablon/' + f));
    for (const i of Dc().querySelectorAll('#dis_form input[name=lot]')) i.checked = ['STD1', 'STD2'].includes(i.value);
    const y = Dc().querySelector('#dis_form [name=yontem]'); y.value = 'msd'; y.dispatchEvent(new Event('change', { bubbles: true }));
    const s = Dc().querySelector('#dis_form [name=sinir]'); s.value = 'L2a'; s.dispatchEvent(new Event('change', { bubbles: true }));
    const k = Dc().querySelector('#dis_form [name=kesme]'); k.value = 'none'; k.dispatchEvent(new Event('change', { bubbles: true }));
    await sleep(50);
    put('Y-5', f, 'dis', 'durum', await run('dis'));
    put('Y-5', f, 'dis', 'form', JSON.stringify(W().__p6.dis && W().__p6.dis.form));
    put('Y-5', f, 'dis', 'sonuc', JSON.stringify(W().__p6.dis && W().__p6.dis.sonuc));
  }
  log('şablonlar');

  // ---- Y-3, Y-4, Y-8 method notes
  for (const n of NOTES) {
    for (const lg of ['tr', 'en']) {
      await load(`yontem/${n}.html?lang=${lg}`); await waitFor(() => W().__not && W().__not.ready);
      const r0 = reqs().length;
      const s = Dc().querySelector(`section.not[data-lang="${lg}"]`);
      put('Y-3', n, lg, 'gorunur', !s.hidden && Dc().documentElement.lang === lg);
      put('Y-3', n, lg, 'baslik', s.querySelector('h1').textContent);
      put('Y-3', n, lg, 'bolumler', JSON.stringify([...s.querySelectorAll('h2')].map((h) => h.textContent)));
      const eqs = [...s.querySelectorAll('.eq')];
      put('Y-3', n, lg, 'denklem', eqs.length);
      put('Y-3', n, lg, 'denklem_kaynaksiz', eqs.filter((e) => !(e.dataset.kaynak || '').trim()).length);
      put('Y-3', n, lg, 'denklem_mathml', eqs.filter((e) => e.querySelector('math')).length);
      put('Y-3', n, lg, 'farmastatr_etiketi', eqs.filter((e) => /Tasarım gereği|By design/i.test(e.dataset.kaynak)).length);
      for (const d of s.querySelectorAll('[data-deger]')) put('Y-4', n, lg, d.dataset.deger, d.textContent);
      for (const a of s.querySelectorAll('a[href]')) links.add(a.href.split('#')[0]);
      const de = Dc().documentElement;
      fr.style.width = '390px'; await sleep(200);
      put('Y-8', n, lg, 'not_yatay_kaydirma', de.scrollWidth > de.clientWidth + 1);
      fr.style.width = '';
      put('Y-7', n, lg, 'dis_istek', ext(reqs().slice(r0)) + ext(reqs().filter((u) => !u.startsWith(location.origin))));
    }
  }
  log('yöntem notları');

  // ---- B-1 ... B-5 plain-words pages (FSR-TN-PLT-10): the list comes from the index
  for (const lg of ['tr', 'en']) {
    await load(`yontem/index.html?lang=${lg}`); await waitFor(() => W().__not && W().__not.ready);
    const s = Dc().querySelector(`section.not[data-lang="${lg}"]`);
    const h = [...s.querySelectorAll('h2')].map((x) => x.textContent);
    const bl = [...s.querySelectorAll('a[href]')].map((a) => a.getAttribute('href').split('?')[0]).filter((u) => /^basit_/.test(u));
    put('B-3', 'index', lg, 'baslik', JSON.stringify(h)); put('B-3', 'index', lg, 'sayfalar', JSON.stringify(bl));
  }
  const basit = [...new Set(out.filter((r) => r[0] === 'B-3' && r[3] === 'sayfalar').flatMap((r) => JSON.parse(r[4])))]
    .map((u) => u.replace(/^basit_/, '').replace(/\.html$/, ''));
  for (const n of basit) {
    for (const lg of ['tr', 'en']) {
      await load(`yontem/${n}.html?lang=${lg}`); await waitFor(() => W().__not && W().__not.ready);
      const t = Dc().querySelector(`section.not[data-lang="${lg}"] .basit-bag a`);
      put('B-2', n, lg, 'teknikten_basite', t ? t.getAttribute('href').split('?')[0] + '|' + t.textContent : '');
      await load(`yontem/basit_${n}.html?lang=${lg}`); await waitFor(() => W().__not && W().__not.ready);
      const r0 = reqs().length;
      const s = Dc().querySelector(`section.not[data-lang="${lg}"]`);
      put('B-1', n, lg, 'gorunur', !s.hidden && Dc().documentElement.lang === lg);
      put('B-1', n, lg, 'baslik', s.querySelector('h1').textContent);
      put('B-1', n, lg, 'beyan', (s.querySelector('.disclaimer') || {}).textContent || '');
      const back = [...s.querySelectorAll('.ust a')].map((a) => a.getAttribute('href').split('?')[0]);
      put('B-2', n, lg, 'basitten_teknige', back.includes(`${n}.html`));
      put('B-5', n, lg, 'denklem', s.querySelectorAll('.eq, math').length);
      for (const d of s.querySelectorAll('[data-deger]')) put('B-4', n, lg, d.dataset.deger, d.textContent);
      for (const a of s.querySelectorAll('a[href]')) links.add(a.href.split('#')[0]);
      const de = Dc().documentElement;
      fr.style.width = '390px'; await sleep(200);
      put('B-1', n, lg, 'yatay_kaydirma', de.scrollWidth > de.clientWidth + 1);
      fr.style.width = '';
      put('B-5', n, lg, 'dis_istek', ext(reqs().slice(r0)) + ext(reqs().filter((u) => !u.startsWith(location.origin))));
    }
  }
  log(`basit anlatımlar: ${basit.length}`);

  // ---- Y-6 links (same site): every link opens
  for (const u of [...links].sort()) {
    let st = 'dis';
    if (u.startsWith(location.origin)) { try { st = (await fetch(u, { cache: 'no-store' })).status; } catch (e) { st = 'hata'; } }
    put('Y-6', u.replace(location.origin, ''), '', 'durum', st);
  }
  put('ortam', '', '', 'sure_s', Math.round((performance.now() - t0) / 1000));
  log(`Bitti: ${links.size} bağlantı. “p7_kabul.zip indir” düğmesine basın.`);
  $('#status').textContent = 'Testler: tamamlandı'; window.__p7k_done = true; $('#b_zip').disabled = false;
}

function pack() {
  const q = (s) => '"' + String(s).replaceAll('"', '""') + '"';
  const csv = [['bolum', 'durum', 'ayar', 'ad', 'deger'].map(q).join(','), ...out.map((r) => r.map(q).join(','))].join('\n') + '\n';
  return zipStored([['p7_tarayici.csv', enc.encode(csv)]]);
}
function download() {
  const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([pack()], { type: 'application/zip' }));
  a.download = 'p7_kabul.zip'; a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}
window.__p7k_pack = pack;
$('#b_run').addEventListener('click', () => main().catch((e) => { log('HATA: ' + (e.message || e)); $('#status').textContent = 'Testler: hata'; $('#b_zip').disabled = false; }));
$('#b_zip').addEventListener('click', download);
