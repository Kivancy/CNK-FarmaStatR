// CNK-FarmaStatR - P6 validation page (FSR-TN-PLT-06 v0.1, T-3; open item A-3).
// Loads the package sources, the inherited validation sets and the test folder (list in
// dogrula_dosyalar.txt) into webR, checks the pinned files against CEKIRDEK_SHA256.txt and runs
//   (1) the five inherited validation scripts unchanged (expected 60, 98, 120, 213, 25 checks;
//       FSR-LOG-01 G-01/G-03),
//   (2) every testthat file of the package with the base-R stand-in testthat_kucuk.R.
// Nothing is sent anywhere; the results can be saved as CSV.
// Research and education only; not a system validated for GxP environments.

import { WEBR_VERSION, WEBR_BASE, fetchBytes, sha256 } from '../p1/motor.js';

const $ = (s) => document.querySelector(s);
const W = '/home/web_user/repo';
const LEG = [['dissolusyon', 'msd_tests.R', '', '.sonuclar', 60], ['dissolusyon', 'msd_weibull_tests.R', '', '.sonuclar', 98],
  ['dissolusyon', 'f2_tests.R', '', '.sonuclar', 120], ['pbe', 'pbe_tests.R', 'referans_python.R', '.sonuclar', 213],
  ['pbe', 'pbe_kopru_tests.R', '', '.kt', 25]];
let T = {}, lang = new URLSearchParams(location.search).get('lang') === 'en' ? 'en' : 'tr';
let webR = null, files = [], env = {}, legRows = [], testRows = [], busy = false;
const st = window.__p6v = { ready: false, status: '', leg: legRows, tests: testRows, env };
const t = (k) => (T[lang] && T[lang][k] !== undefined ? T[lang][k] : k);

function setStatus(k, cls = '', arg = '') { st.status = k; const e = $('#dg_status'); e.textContent = t(k) + (arg ? ' ' + arg : ''); e.className = 'status ' + cls; e.dataset.key = k; e.dataset.cls = cls; e.dataset.arg = arg; }
function table(sel, head, rows) {
  const tb = $(sel); tb.querySelector('tbody').innerHTML = '';
  const th = tb.querySelector('thead');
  if (th) { th.innerHTML = ''; const tr = document.createElement('tr'); for (const h of head) { const c = document.createElement('th'); c.textContent = h; tr.append(c); } th.append(tr); }
  for (const r of rows) { const tr = document.createElement('tr'); for (const v of r) { const c = document.createElement('td'); c.textContent = v; tr.append(c); } tb.querySelector('tbody').append(tr); }
}
function render() {
  table('#dg_leg_t', [t('dg_script'), t('dg_expected'), t('dg_passed'), t('dg_rows'), t('dg_secs'), t('dg_result')],
    legRows.map((r) => [r.script, String(r.expected), String(r.passed), String(r.rows), r.secs.toFixed(0), r.ok ? t('dg_ok') : t('dg_fail')]));
  table('#dg_tests_t', [t('dg_file'), t('dg_block'), 'nb', t('dg_failed'), t('dg_skipped'), t('dg_error'), t('dg_secs'), t('dg_detail')],
    testRows.map((r) => [r.file, r.test, String(r.nb), String(r.failed), r.skipped ? t('an_yes') : '', r.error ? t('an_yes') : '', r.secs.toFixed(0), r.detail]));
  if (testRows.length) {
    const s = (k) => testRows.reduce((a, r) => a + Number(r[k]), 0);
    const bad = s('failed') + s('error');
    $('#dg_total').textContent = `${t('dg_total')}: ${testRows.length} ${t('dg_blocks')}, ${s('nb')} ${t('dg_expect')}, ${s('failed')} ${t('dg_failed').toLowerCase()}, ${s('error')} ${t('dg_error').toLowerCase()}, ${s('skipped')} ${t('dg_skipped').toLowerCase()}`;
    $('#dg_total').className = 'verdict ' + (bad ? 'no' : 'yes');
  }
  table('#dg_env', [], Object.entries(env).map(([k, v]) => [t(k), String(v)]));
  $('#dg_csv').disabled = busy || !(legRows.length || testRows.length);
}
function csv() {
  const q = (v) => `"${String(v).replace(/"/g, '""')}"`;
  const lines = ['part,file,test,expected_or_nb,passed_or_failed,error,skipped,secs,detail'];
  for (const r of legRows) lines.push(['legacy', r.script, r.sub, r.expected, r.passed, !r.ok, '', r.secs.toFixed(1), `rows ${r.rows}`].map(q).join(','));
  for (const r of testRows) lines.push(['testthat', r.file, r.test, r.nb, r.failed, r.error, r.skipped, r.secs.toFixed(1), r.detail].map(q).join(','));
  for (const [k, v] of Object.entries(env)) lines.push(['env', k, '', '', '', '', '', '', v].map(q).join(','));
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob(['\ufeff' + lines.join('\r\n') + '\r\n'], { type: 'text/csv' }));
  a.download = `farmastatr_dogrulama_${new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)}.csv`; a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}

async function boot() {
  T = await (await fetch('../app/ceviri.json', { cache: 'no-store' })).json();
  applyLang(); setStatus('st_verifying');
  const list = new TextDecoder().decode(await fetchBytes('web/analiz/dogrula_dosyalar.txt')).trim().split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
  const shaTxt = new TextDecoder().decode(await fetchBytes('CNKfarmastatr/inst/validasyon/CEKIRDEK_SHA256.txt'));
  const pinned = Object.fromEntries(shaTxt.trim().split(/\r?\n/).map((l) => { const [h, f] = l.trim().split(/\s+/); return [f, h]; }));
  for (const p of list) {
    const e = { path: p, bytes: null, status: 'ok' };
    try { e.bytes = await fetchBytes(p); } catch (err) { e.status = 'fetch_failed'; }
    const base = p.split('/').pop();
    if (e.bytes && p.startsWith('CNKfarmastatr/R/') && pinned[base]) {
      e.sha256 = await sha256(e.bytes); e.pinned = true;           // same bytes as the analysis pages (motor.js)
      if (e.sha256 !== pinned[base]) e.status = 'hash_mismatch';
    }
    files.push(e);
  }
  const bad = files.filter((e) => e.status !== 'ok');
  const npin = files.filter((e) => e.pinned && e.status === 'ok').length;
  env.dg_files = `${files.length - bad.length}/${files.length}`;
  env.dg_pinned = `${npin}/${Object.keys(pinned).length}`;
  if (bad.length || npin !== Object.keys(pinned).length) {
    setStatus('st_blocked', 'bad');
    $('#dg_errors').hidden = false; $('#dg_errors').textContent = bad.map((e) => `${e.path}: ${t(e.status)}`).join('; ') || t('hash_missing');
    render(); st.ready = true; st.blocked = true; return;
  }
  setStatus('st_loading');
  const { WebR, ChannelType } = await import(WEBR_BASE + 'webr.mjs');
  webR = new WebR({ baseUrl: WEBR_BASE, channelType: ChannelType.PostMessage });
  await webR.init();
  const made = new Set();
  const mk = async (d) => { let p = ''; for (const x of d.split('/').filter(Boolean)) { p += '/' + x; if (!made.has(p)) { made.add(p); try { await webR.FS.mkdir(p); } catch (err) { /* exists */ } } } };
  for (const e of files) { await mk(`${W}/${e.path.split('/').slice(0, -1).join('/')}`); await webR.FS.writeFile(`${W}/${e.path}`, e.bytes); }
  await webR.FS.writeFile('/home/web_user/tk.R', await fetchBytes('web/analiz/testthat_kucuk.R'));
  await webR.evalRVoid(`
    Sys.setenv(NOT_CRAN = "true")
    sys.source("/home/web_user/tk.R", envir = globalenv(), keep.source = FALSE)
    assign("tk_pkg_inst", "${W}/CNKfarmastatr/inst", envir = globalenv())
    tk_paket("${W}/CNKfarmastatr/DESCRIPTION")
    .dg_coll <- strsplit(gsub("'", "", read.dcf("${W}/CNKfarmastatr/DESCRIPTION", fields = "Collate")[1, 1]), "[[:space:]]+")[[1]]
    .dg_coll <- .dg_coll[nzchar(.dg_coll)]
    for (f in .dg_coll) sys.source(file.path("${W}/CNKfarmastatr/R", f), envir = globalenv(), keep.source = FALSE)
    .dg_leg <- function(sub, script, setup, result) {
      old <- setwd(file.path("${W}/CNKfarmastatr/inst/validasyon", sub)); on.exit(setwd(old))
      if (nzchar(setup)) source(setup, local = globalenv(), encoding = "UTF-8")
      t0 <- proc.time()[[3]]
      suppressWarnings(invisible(capture.output(source(script, local = globalenv(), encoding = "UTF-8"))))
      r <- get(result, envir = globalenv()); rm(list = result, envir = globalenv())
      list(rows = nrow(r), passed = sum(r$durum == "GE\\u00c7T\\u0130"), secs = proc.time()[[3]] - t0)
    }
    .dg_test <- function(f) {
      r <- tk_test_dir("${W}/CNKfarmastatr/tests/testthat", only = f)
      list(file = r$file, test = r$test, nb = r$nb, failed = r$failed, skipped = r$skipped, error = r$error, secs = r$secs, detail = r$detail)
    }`);
  env.dg_webr = WEBR_VERSION;
  env.dg_r = await webR.evalRString('R.version.string');
  env.dg_pkg = await webR.evalRString(`read.dcf("${W}/CNKfarmastatr/DESCRIPTION", fields = "Version")[1, 1]`);
  env.dg_collate = String((await webR.evalRNumber('length(.dg_coll)')));
  env.dg_browser = navigator.userAgent;
  setStatus('st_ready', 'ok'); render();
  $('#dg_leg').disabled = false; $('#dg_tests').disabled = false; st.ready = true;
}
const toArr = (x) => (Array.isArray(x) ? x : [x]);
function plainList(js) { const o = {}; js.names.forEach((n, i) => { o[n] = js.values[i].values; }); return o; }
async function runLeg() {
  busy = true; $('#dg_leg').disabled = true; $('#dg_tests').disabled = true; legRows.length = 0; render();
  for (const [sub, script, setup, result, n] of LEG) {
    setStatus('dg_running', '', script);
    const sh = await new webR.Shelter();
    try {
      const r = plainList(await (await sh.evalR(`.dg_leg("${sub}", "${script}", "${setup}", "${result}")`)).toJs());
      legRows.push({ sub, script, expected: n, rows: r.rows[0], passed: r.passed[0], secs: r.secs[0], ok: r.rows[0] === n && r.passed[0] === n });
    } catch (err) { legRows.push({ sub, script, expected: n, rows: 0, passed: 0, secs: 0, ok: false, err: String(err.message) }); }
    finally { await sh.purge(); }
    render();
  }
  const ok = legRows.every((r) => r.ok);
  env.dg_leg_total = `${legRows.reduce((a, r) => a + r.passed, 0)}/${LEG.reduce((a, r) => a + r[4], 0)}`;
  busy = false; setStatus(ok ? 'dg_done_ok' : 'dg_done_fail', ok ? 'ok' : 'bad'); $('#dg_leg').disabled = false; $('#dg_tests').disabled = false; render();
}
async function runTests() {
  busy = true; $('#dg_leg').disabled = true; $('#dg_tests').disabled = true; testRows.length = 0; render();
  const tf = files.map((e) => e.path).filter((p) => /^CNKfarmastatr\/tests\/testthat\/test-.*\.R$/.test(p)).map((p) => p.split('/').pop());
  for (const f of tf) {
    setStatus('dg_running', '', f);
    const sh = await new webR.Shelter();
    try {
      const r = plainList(await (await sh.evalR(`.dg_test("${f}")`)).toJs());
      toArr(r.test).forEach((_, i) => testRows.push({ file: r.file[i], test: r.test[i], nb: r.nb[i], failed: r.failed[i], skipped: r.skipped[i], error: r.error[i], secs: r.secs[i], detail: r.detail[i] }));
    } catch (err) { testRows.push({ file: f, test: '-', nb: 0, failed: 0, skipped: false, error: true, secs: 0, detail: String(err.message) }); }
    finally { await sh.purge(); }
    render();
  }
  const bad = testRows.some((r) => r.failed || r.error);
  env.dg_tests_total = `${testRows.length} / ${testRows.reduce((a, r) => a + r.nb, 0)}`;
  busy = false; setStatus(bad ? 'dg_done_fail' : 'dg_done_ok', bad ? 'bad' : 'ok'); $('#dg_leg').disabled = false; $('#dg_tests').disabled = false; render();
}
function applyLang() {
  document.documentElement.lang = lang;
  document.querySelectorAll('[data-i18n]').forEach((e) => { e.textContent = t(e.dataset.i18n); });
  const e = $('#dg_status'); if (e.dataset.key) setStatus(e.dataset.key, e.dataset.cls, e.dataset.arg);
  render();
}
$('#lang').addEventListener('click', () => { lang = lang === 'tr' ? 'en' : 'tr'; applyLang(); });
$('#dg_leg').addEventListener('click', runLeg);
$('#dg_tests').addEventListener('click', runTests);
$('#dg_csv').addEventListener('click', csv);
st.runLeg = runLeg; st.runTests = runTests;
boot().catch((err) => { setStatus('st_error', 'bad'); $('#dg_errors').hidden = false; $('#dg_errors').textContent = String(err && err.message || err); });
