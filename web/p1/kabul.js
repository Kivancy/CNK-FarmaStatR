// CNK-FarmaStatR - P1 acceptance harness (FSR-TN-PLT-01 v0.4, Tables 11.1 and 11.2).
// Collects the browser side of every criterion into one long CSV (bolum, anahtar, ad, deger);
// web/p1/kabul/p1_kabul.R compares it with local R and writes PASS / FAIL per criterion.
// v0.2 (G-68; FSR-TN-PLT-01 v0.6, Table 11.1 revision): the cancel and performance runs use
// 6 x 30 and n_sim 15,000; 20,000 is rejected by the run-size limit (KK-47). Thresholds unchanged.
// Research and education only; not a system validated for GxP environments.
import { WEBR_VERSION, WEBR_BASE, verifyFiles, startWebR, plain, fetchBytes, sha256 } from './motor.js';

const $ = (s) => document.querySelector(s);
const Q = new URLSearchParams(location.search);
const passQ = Q.get('webr') ? `&webr=${encodeURIComponent(Q.get('webr'))}` : '';
const PROTO = `index.html?lang=tr${passQ}`;
const rows = [];                      // {bolum, anahtar, ad, deger}
const add = (bolum, anahtar, ad, deger) => rows.push({ bolum, anahtar, ad, deger: String(deger) });
const drop = (bolum, anahtar) => { for (let i = rows.length - 1; i >= 0; i--) if (rows[i].bolum === bolum && (anahtar === undefined || rows[i].anahtar.startsWith(anahtar))) rows.splice(i, 1); };
let busy = false;

function log(msg) {
  const el = $('#log'); const ts = new Date().toLocaleTimeString('tr-TR');
  el.textContent += `[${ts}] ${msg}\n`; el.scrollTop = el.scrollHeight;
}
function status(msg) { $('#status').textContent = msg; }
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function waitFor(fn, timeout = 120000, step = 50) {
  const t0 = performance.now();
  for (;;) {
    let v; try { v = fn(); } catch (e) { v = null; }
    if (v) return v;
    if (performance.now() - t0 > timeout) throw new Error('zaman aşımı');
    await sleep(step);
  }
}
const median = (a) => { const s = [...a].sort((x, y) => x - y); const n = s.length; return n % 2 ? s[(n - 1) / 2] : (s[n / 2 - 1] + s[n / 2]) / 2; };

// ------------------------------------------------------------- iframe helpers
async function loadProto(extra = '') {
  const fr = $('#fr');
  fr.src = 'about:blank'; await sleep(200);
  fr.src = PROTO + extra;
  await waitFor(() => fr.contentWindow && fr.contentWindow.document.readyState !== 'loading' && fr.contentWindow.location.href.includes('index.html'), 30000);
  return fr.contentWindow;
}
async function protoReady(win, timeout = 120000) {
  return waitFor(() => win.__p1_ready === true || win.__p1_blocked, timeout);
}
function setVals(win, vals) {
  const d = win.document;
  for (const [k, v] of Object.entries(vals)) {
    const el = d.querySelector(`[name="${k}"]`);
    el.value = String(v); el.dispatchEvent(new Event('input', { bubbles: true })); el.dispatchEvent(new Event('change', { bubbles: true }));
  }
}
async function protoRun(win, vals, timeout = 600000) {
  setVals(win, vals);
  win.__p1_last = null;
  win.document.querySelector('#run').click();
  await waitFor(() => win.__p1_last || win.document.querySelector('#status').className === 'bad', timeout);
  if (!win.__p1_last) throw new Error('koşu hata verdi: ' + win.document.querySelector('#errors').textContent);
  return win.__p1_last;
}

// ------------------------------------------------------------- environment
function envAuto() {
  const ua = navigator.userAgent;
  const ch = (ua.match(/Chrome\/([\d.]+)/) || [])[1] || '?';
  $('#env_auto').textContent = `Otomatik: Chrome ${ch} · mantıksal çekirdek ${navigator.hardwareConcurrency ?? '?'} · deviceMemory ${navigator.deviceMemory ?? '?'} GB (tarayıcı 8'de keser) · webR ${WEBR_VERSION} · ${WEBR_BASE}`;
}
function envRows() {
  for (const k of ['cihaz', 'tarayici', 'webr', 'kayit']) drop('ortam', k);
  add('ortam', 'cihaz', 'islemci', $('#env_cpu').value.trim());
  add('ortam', 'cihaz', 'ram_gb', $('#env_ram').value.trim());
  add('ortam', 'cihaz', 'isletim_sistemi', $('#env_os').value.trim());
  add('ortam', 'cihaz', 'not', $('#env_note').value.trim());
  add('ortam', 'tarayici', 'user_agent', navigator.userAgent);
  add('ortam', 'tarayici', 'mantiksal_cekirdek', navigator.hardwareConcurrency ?? '');
  add('ortam', 'tarayici', 'device_memory_gb', navigator.deviceMemory ?? '');
  add('ortam', 'webr', 'surum', WEBR_VERSION);
  add('ortam', 'webr', 'kaynak', WEBR_BASE);
  add('ortam', 'kayit', 'zaman', new Date().toISOString());
  drop('olcum', 'bellek'); drop('olcum', 'mobil');
  add('olcum', 'bellek', 'tepe_mb', $('#mem_mb').value.trim().replace(',', '.'));
  add('olcum', 'mobil', 'gozlem', $('#mobile_note').value.trim());
}

// ------------------------------------------------------------- 1-2: start-up times
async function startup(kind) {
  const key = kind === 'soguk' ? 'soguk_acilis' : 'sicak_acilis';
  drop('olcum', key);
  if (kind === 'soguk') add('olcum', key, 'onbellek_kapali_beyan', $('#cache_off').checked ? 'TRUE' : 'FALSE');
  if (kind === 'sicak') { log('Sıcak açılış için önce bir ısınma yüklemesi.'); const w = await loadProto(); await protoReady(w); }
  for (let i = 1; i <= 5; i++) {
    const w = await loadProto();
    await protoReady(w);
    if (w.__p1_blocked) throw new Error('motor dosyası doğrulanamadı');
    const ms = Math.round(w.__p1_cold_start_ms);
    add('olcum', key, `tekrar${i}`, ms);
    log(`${key} ${i}/5: ${ms} ms`);
  }
}

// ------------------------------------------------------------- 3a: computations in own webR
async function computations() {
  drop('kosu'); drop('ara'); drop('hata'); drop('ortam', 'dosya');
  status('Motor dosyaları doğrulanıyor…');
  const files = await verifyFiles(['invitro_fast.R', 'invitro_grid.R', 'pbe_ornek_veri.R'], ['platform_input.R']);
  for (const e of files) add('ortam', `dosya|${e.file}`, 'sha256', `${e.sha256} ${e.status}`);
  if (files.some((e) => e.status !== 'ok')) throw new Error('motor dosyası doğrulanamadı');
  const kb = await fetchBytes('web/p1/kabul/kabul.R');
  add('ortam', 'dosya|kabul.R', 'sha256', `${await sha256(kb)} kayit`);
  files.push({ file: 'kabul.R', bytes: kb });
  status('webR açılıyor (hesap testleri)…');
  const webR = await startWebR(files);
  add('ortam', 'r', 'surum', await webR.evalRString('R.version.string'));
  add('ortam', 'r', 'rng', await webR.evalRString('paste(RNGkind(), collapse = "/")'));
  status('36 koşu, ara değerler, hata yakalama hesaplanıyor…');
  const t0 = performance.now();
  const sh = await new webR.Shelter();
  try {
    const df = plain(await (await sh.evalR('as.list(p1_kabul_hepsi())')).toJs());
    for (let i = 0; i < df.bolum.length; i++) add(df.bolum[i], df.anahtar[i], df.ad[i], df.deger[i]);
    log(`Hesap testleri: ${df.bolum.length} satır, ${Math.round(performance.now() - t0)} ms`);
  } finally { await sh.purge(); webR.close(); }
  add('ortam', 'r', 'hesap_testleri_ms', Math.round(performance.now() - t0));
}

// ------------------------------------------------------------- 3b: hash attempts
async function hashTests() {
  drop('olcum', 'hash');
  const attempts = [['invitro_fast.R', 100], ['invitro_grid.R', 2000], ['invitro_fast.R', 5000]];
  for (let i = 0; i < attempts.length; i++) {
    const [f, pos] = attempts[i];
    status(`Hash denemesi ${i + 1}/3: ${f}, bayt ${pos}`);
    const w = await loadProto(`&bozuk=${encodeURIComponent(f)}:${pos}`);
    await protoReady(w, 60000);
    await sleep(3000);                                      // would webR start anyway?
    const blocked = Array.isArray(w.__p1_blocked) && w.__p1_blocked.includes(f);
    const k = `hash|${i + 1}`;
    add('olcum', k, 'dosya', f); add('olcum', k, 'konum', pos);
    add('olcum', k, 'engellendi', blocked ? 'TRUE' : 'FALSE');
    add('olcum', k, 'dosya_adi_gosterildi', w.document.querySelector('#errors').textContent.includes(f) ? 'TRUE' : 'FALSE');
    add('olcum', k, 'webr_yuklenmedi', w.__p1_ready === true ? 'FALSE' : 'TRUE');
    add('olcum', k, 'calistir_kapali', w.document.querySelector('#run').disabled ? 'TRUE' : 'FALSE');
    log(`Hash ${i + 1}/3 ${f}:${pos} → engellendi ${blocked}`);
  }
}

// ------------------------------------------------------------- 3c: cancel
async function cancelTest(w) {
  drop('olcum', 'iptal');
  status('İptal testi: 6 × 30, nsim 15.000; 3 sn sonra iptal');
  setVals(w, { sigma_R: 0.12, rho: 1, pB: 0, pL: 0.15, q: 0, l: 6, n: 30, m: 3, delta_choice: 'fda_delta0', n_sim: 15000, seed: 20261015 });
  w.__p1_last = null; w.__p1_cancel_ms = undefined;
  w.document.querySelector('#run').click();
  await sleep(3000);
  const stillRunning = w.__p1_last === null;
  const t0 = performance.now();
  w.document.querySelector('#cancel').click();
  await waitFor(() => w.__p1_cancel_ms !== undefined, 10000, 5);
  const stopMs = performance.now() - t0;
  // UI responsiveness: a timer in the prototype must fire promptly after the cancel
  const lag = await new Promise((res) => { const s = performance.now(); w.setTimeout(() => res(performance.now() - s), 0); });
  const statusBad = w.__p1_status_key === 'st_cancelled';
  const noResult = w.document.querySelector('#result').hidden && w.__p1_last === null;
  await waitFor(() => w.__p1_ready === true, 60000);
  const readyMs = performance.now() - t0;
  await sleep(1000);
  add('olcum', 'iptal', 'iptalde_kosu_suruyordu', stillRunning ? 'TRUE' : 'FALSE');
  add('olcum', 'iptal', 'durma_ms', Math.round(stopMs));
  add('olcum', 'iptal', 'arayuz_gecikme_ms', Math.round(lag));
  add('olcum', 'iptal', 'iptal_iletisi', statusBad ? 'TRUE' : 'FALSE');
  add('olcum', 'iptal', 'kismi_sonuc_gosterilmedi', noResult && w.__p1_last === null ? 'TRUE' : 'FALSE');
  add('olcum', 'iptal', 'yeniden_hazir_ms', Math.round(readyMs));
  log(`İptal: durma ${Math.round(stopMs)} ms, arayüz gecikmesi ${Math.round(lag)} ms, yeniden hazır ${Math.round(readyMs)} ms`);
}

// ------------------------------------------------------------- 3d: performance
async function perfTests(w) {
  drop('olcum', 'perf');
  for (const [l, n, ns] of [[3, 10, 10000], [6, 30, 15000]]) {
    const k = `perf|${l}x${n}|${ns}`;
    for (let i = 1; i <= 5; i++) {
      status(`Performans ${l} × ${n}, nsim ${ns}: ${i}/5 (görev yöneticisinde belleği izleyin)`);
      const rec = await protoRun(w, { sigma_R: 0.12, rho: 1, pB: 0, pL: 0.15, q: 0, l, n, m: 3, delta_choice: 'fda_delta0', n_sim: ns, seed: 20261015 });
      add('olcum', k, `tekrar${i}`, rec.elapsed_ms);
      add('olcum', k, `fda_pass_tekrar${i}`, rec.result.fda_pass);
      log(`${k} ${i}/5: ${rec.elapsed_ms} ms`);
    }
    const v = rows.filter((r) => r.bolum === 'olcum' && r.anahtar === k && /^tekrar\d$/.test(r.ad)).map((r) => Number(r.deger));
    log(`${k}: medyan ${median(v)} ms, en kötü ${Math.max(...v)} ms`);
  }
}

async function guarded(name, fn) {
  if (busy) return; busy = true;
  document.querySelectorAll('button').forEach((b) => { b.disabled = true; });
  try { await fn(); status(`${name}: tamamlandı`); log(`${name}: tamamlandı`); }
  catch (e) { status(`${name}: HATA ${e.message || e}`); log(`${name}: HATA ${e.message || e}`); }
  finally { busy = false; document.querySelectorAll('button').forEach((b) => { b.disabled = false; }); }
}

function csv() {
  envRows();
  const q = (s) => '"' + String(s).replaceAll('"', '""') + '"';
  const body = ['bolum,anahtar,ad,deger', ...rows.map((r) => [r.bolum, r.anahtar, r.ad, r.deger].map(q).join(','))].join('\n') + '\n';
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([body], { type: 'text/csv' }));
  a.download = 'p1_tarayici.csv'; a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  const by = {}; rows.forEach((r) => { by[r.bolum] = (by[r.bolum] || 0) + 1; });
  log(`CSV indirildi: ${rows.length} satır ${JSON.stringify(by)}`);
}

$('#b_cold').addEventListener('click', () => guarded('Soğuk açılış', () => startup('soguk')));
$('#b_warm').addEventListener('click', () => guarded('Sıcak açılış', () => startup('sicak')));
$('#b_tests').addEventListener('click', () => guarded('Testler', async () => {
  await computations();
  await hashTests();
  status('Prototip açılıyor (iptal ve performans)…');
  const w = await loadProto(); await protoReady(w);
  if (w.__p1_blocked) throw new Error('motor dosyası doğrulanamadı');
  await cancelTest(w);
  await perfTests(w);
}));
$('#b_csv').addEventListener('click', csv);
window.__kabul_rows = rows;
envAuto();
status('Hazır. Adımları sırayla izleyin.');
