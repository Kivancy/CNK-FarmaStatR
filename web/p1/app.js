// CNK-FarmaStatR - P1 minimal browser prototype (FSR-TN-PLT-01 v0.4, D-05, Table 11.1).
// The page does no statistics: it verifies the engine files, loads them into webR and
// calls platform_run_invitro() (platform input check + invitro_scenario, unchanged).
// P3 (FSR-TN-PLT-03, KK-51, P3-K2): "R script" button. The script is written by
// platform_export_invitro() in webR from the same verified bytes; no run is needed, so
// n_sim above the browser limit can be exported (tier 3).
// Research and education only; not a system validated for GxP environments.

import { WEBR_VERSION, WEBR_BASE, TAMPER, verifyFiles as verify, startWebR, plain, fetchBytes } from './motor.js';

const Q = new URLSearchParams(location.search);
const ENGINE = ['sim_run.R', 'invitro_fast.R', 'invitro_grid.R'];   // pinned: must match the SHA list
const PLATFORM = ['platform_input.R', 'platform_hipotez.R', 'platform_export.R'];   // not pinned: hash recorded
const N_SIM_MAX = 20000;
const CELLS_MAX = 8.1e6;      // display only; the limit is enforced by platform_input.R (G-60, KK-47)

const $ = (s) => document.querySelector(s);
let T = {}, lang = Q.get('lang') === 'en' ? 'en' : 'tr';
let webR = null, files = [], tInitMs = null, rInfo = {}, record = null, runToken = 0, pkgVersion = 'source';

// ---------------------------------------------------------------- i18n
function t(k, f) { const s = (T[lang] && T[lang][k]) || k; return f ? s.replaceAll('{f}', f) : s; }
function applyLang() {
  document.documentElement.lang = lang;
  document.querySelectorAll('[data-i18n]').forEach((el) => { el.textContent = t(el.dataset.i18n); });
  updateMcse(); renderEngine(); renderTimes();
  if (record) renderRecord(record);
  if (statusKey) setStatus(statusKey, statusCls);
  if (errFn) showErrors(errFn);
}
let statusKey = null, statusCls = '';
function setStatus(k, cls = '') {
  statusKey = k; statusCls = cls; window.__p1_status_key = k;
  const el = $('#status'); el.textContent = t(k); el.className = cls;
}
function fmt(x, d = 4) {
  if (x === null || x === undefined || Number.isNaN(x)) return 'NA';
  const s = x.toFixed(d);
  return lang === 'tr' ? s.replace('.', ',') : s;
}

// ---------------------------------------------------------------- files and hashes
const verifyFiles = () => verify(ENGINE, PLATFORM);
function renderEngine() {
  const tb = $('#engine_table tbody'); tb.innerHTML = '';
  for (const e of files) {
    const tr = document.createElement('tr');
    const st = e.status === 'ok' ? (e.pinned ? '✓ SHA-256' : 'SHA-256 (P1: ' + (lang === 'tr' ? 'kayıt' : 'recorded') + ')') : '✗ ' + t(e.status);
    tr.innerHTML = `<td>${e.file}</td><td>${st}</td><td>${e.sha256 || ''}</td>`;
    tb.appendChild(tr);
  }
}

// ---------------------------------------------------------------- webR start-up
const R_WRAPPER = `
.p1_run <- function(p, choice, gmr) {
  pr <- platform_check_invitro(c(p, list(delta = 0)))
  if (nrow(pr) > 0) return(list(ok = FALSE, kind = "input", field = pr$field, code = pr$code, message = pr$message))
  d <- switch(choice,
    fda_delta0 = invitro_delta0(p$sigma_R, p$rho),
    "gmr_1.00" = log(1.00), "gmr_1.05" = log(1.05),
    ema_upper = log(1.18), ema_lower = log(0.85),
    custom = suppressWarnings(log(gmr)))
  if (choice == "fda_delta0" && is.na(d)) return(list(ok = FALSE, kind = "delta0"))
  p$delta <- d
  r <- tryCatch(platform_run_invitro(p),
    farmastat_input_error = function(e) e,
    error = function(e) structure(list(message = conditionMessage(e)), class = "p1_engine_error"))
  if (inherits(r, "farmastat_input_error"))
    return(list(ok = FALSE, kind = "input", field = r$problems$field, code = r$problems$code, message = r$problems$message))
  if (inherits(r, "p1_engine_error")) return(list(ok = FALSE, kind = "engine", message = r$message))
  c(list(ok = TRUE, rng = paste(RNGkind()[1:2], collapse = "/")), as.list(r))
}
.p3_export <- function(p, choice, gmr, kaynak, pinned, ver) {
  sinir <- switch(choice, fda_delta0 = "fda_delta0", "gmr_1.00" = "gmr_1.00", "gmr_1.05" = "gmr_1.05",
                  ema_upper = "ema_1.18", ema_lower = "ema_0.85", custom = NULL)
  if (is.null(sinir)) p$delta <- suppressWarnings(log(gmr))
  if (!length(kaynak)) kaynak <- NULL
  r <- tryCatch(platform_export_invitro(p, sinir = sinir, dosyalar = platform_motor_dosyalari("/home/web_user"),
                                        cekirdek_sha = pinned, kaynak = kaynak, paket_surumu = ver),
    farmastat_input_error = function(e) e,
    error = function(e) structure(list(message = conditionMessage(e)), class = "p3_error"))
  if (inherits(r, "farmastat_input_error"))
    return(list(ok = FALSE, kind = "input", field = r$problems$field, code = r$problems$code, message = r$problems$message))
  if (inherits(r, "p3_error"))
    return(list(ok = FALSE, kind = if (grepl("delta0 is not defined", r$message)) "delta0" else "engine", message = r$message))
  list(ok = TRUE, text = r)
}`;

async function startEngine(afterCancel = false) {
  if (!afterCancel) setStatus('st_loading');
  const t0 = performance.now();
  webR = await startWebR(files, R_WRAPPER);
  rInfo.r_version = await webR.evalRString('R.version.string');
  tInitMs = performance.now() - t0;
  if (afterCancel) setStatus('st_cancelled_ready', 'ok'); else setStatus('st_ready', 'ok');
  renderTimes();
  $('#run').disabled = false; $('#export').disabled = false;
  window.__p1_ready = true;
}

async function boot() {
  T = await (await fetch('ceviri.json', { cache: 'no-store' })).json();
  try {                                                     // package version for the script header
    const d = new TextDecoder().decode(await fetchBytes('CNKfarmastatr/DESCRIPTION'));
    const m = d.match(/^Version:\s*(\S+)/m); if (m) pkgVersion = m[1];
  } catch (e) { /* stays 'source' */ }
  applyLang();
  setStatus('st_verifying');
  const tv = performance.now();
  files = await verifyFiles();
  rInfo.verify_ms = performance.now() - tv;
  renderEngine();
  if (files.some((e) => e.status !== 'ok')) {
    setStatus('st_blocked', 'bad');
    window.__p1_blocked = files.filter((e) => e.status !== 'ok').map((e) => e.file);
    $('#engine_box').open = true;
    showErrors(() => [t('st_blocked'), ...files.filter((e) => e.status !== 'ok').map((e) => `${e.file}: ${t(e.status)}`),
      ...(TAMPER ? [`test: ?bozuk=${TAMPER.file}:${TAMPER.pos}`] : [])]);
    return;                                                 // nothing is sourced, nothing runs
  }
  await startEngine();
  rInfo.cold_start_ms = performance.now();                  // navigation start -> engine ready
  window.__p1_cold_start_ms = rInfo.cold_start_ms;
}

// ---------------------------------------------------------------- run, cancel, record
function readForm() {
  const f = new FormData($('#form'));
  const num = (k) => { const s = String(f.get(k) ?? '').trim().replace(',', '.'); return s === '' ? NaN : Number(s); };
  const p = {};
  for (const k of ['sigma_R', 'rho', 'pB', 'pL', 'q', 'l', 'n', 'm', 'n_sim', 'seed']) p[k] = num(k);
  return { p, choice: f.get('delta_choice'), gmr: num('custom_gmr') };
}
function rNum(x) { return Number.isFinite(x) ? String(x) : (Number.isNaN(x) ? 'NA_real_' : (x > 0 ? 'Inf' : '-Inf')); }
function rList(p) { return 'list(' + Object.entries(p).map(([k, v]) => `${k} = ${rNum(v)}`).join(', ') + ')'; }

async function run(ev) {
  ev.preventDefault();
  if (!webR) return;
  const { p, choice, gmr } = readForm();
  const token = ++runToken;
  $('#run').disabled = true; $('#cancel').disabled = false; $('#download').disabled = true;
  $('#export').disabled = true;
  $('#result').hidden = true; showErrors(null); record = null;
  setStatus('st_running');
  const started = new Date();
  const t0 = performance.now();
  let out;
  try {
    const code = `.p1_run(${rList(p)}, ${JSON.stringify(choice)}, ${rNum(gmr)})`;
    const shelter = await new webR.Shelter();
    try { out = plain(await (await shelter.evalR(code)).toJs()); } finally { await shelter.purge(); }
  } catch (err) {
    if (token !== runToken) return;                          // cancelled meanwhile
    out = { ok: false, kind: 'engine', message: String(err && err.message || err) };
  }
  if (token !== runToken) return;
  const elapsed = performance.now() - t0;
  $('#cancel').disabled = true; $('#run').disabled = false; $('#export').disabled = false;
  if (!out.ok) {
    setStatus('st_error', 'bad');
    if (out.kind === 'input') {
      const fields = [].concat(out.field), codes = [].concat(out.code);
      const mx = nsimMax(p);
      showErrors(() => [t('err_input'), ...codes.map((c, i) => t('code_' + c, T[lang] && T[lang][fields[i]] ? t(fields[i]) : fields[i])
        .replace('{max}', mx === null ? '—' : fmtInt(mx)))]);
    } else if (out.kind === 'delta0') showErrors(() => [t('err_delta0')]);
    else showErrors(() => [t('err_engine'), out.message]);
    return;
  }
  record = {
    platform: 'CNK-FarmaStatR', stage: 'P1 prototype', document: 'FSR-TN-PLT-01 v0.4',
    form: JSON.stringify({ p, choice, gmr: choice === 'custom' ? gmr : null }),
    disclaimer: T.en.disclaimer,
    started: started.toISOString(), elapsed_ms: Math.round(elapsed),
    inputs: { ...p, delta_choice: choice, custom_gmr: choice === 'custom' ? gmr : null },
    seed: p.seed, rng: out.rng, r_version: rInfo.r_version, webr_version: WEBR_VERSION,
    webr_base: WEBR_BASE, tamper: TAMPER, engine_call: 'platform_run_invitro() -> invitro_scenario()',
    files: files.map(({ file, pinned, sha256, status }) => ({ file, pinned, sha256, status })),
    start_up_ms: Math.round(tInitMs), cold_start_ms: Math.round(rInfo.cold_start_ms), user_agent: navigator.userAgent,
    hardware_concurrency: navigator.hardwareConcurrency ?? null,
    device_memory_gb: navigator.deviceMemory ?? null,
    result: Object.fromEntries(Object.entries(out).filter(([k]) => !['ok', 'rng'].includes(k)))
  };
  window.__p1_last = record;                                  // read by the acceptance harness
  setStatus('st_done', 'ok'); renderRecord(record); renderTimes();
  $('#download').disabled = false;
}

async function cancel() {
  // webR cannot interrupt R on the PostMessage channel: the worker is closed and a new one
  // started from the already verified bytes. No partial result is kept.
  runToken++;
  $('#cancel').disabled = true; $('#run').disabled = true;
  const tc = performance.now();
  try { webR.close(); } catch (e) { /* worker already gone */ }
  webR = null; window.__p1_ready = false;
  rInfo.cancel_stop_ms = performance.now() - tc;
  window.__p1_cancel_ms = rInfo.cancel_stop_ms;
  setStatus('st_cancelled', 'bad');
  await startEngine(true);
}

function renderRecord(rec) {
  const r = rec.result, tb = $('#res_table tbody'); tb.innerHTML = '';
  const rows = [['fda_pass'], ['ema_a_pass'], ['ema_b_pass'], ['ema_c_pass'],
    ['fda_crit_err'], ['fda_cover'], ['ema_c_cover'], ['diff_fda_ema_c']];
  for (const [k] of rows) {
    const tr = document.createElement('tr');
    tr.innerHTML = `<td>${t('row_' + k)}</td><td class="num">${fmt(r[k])}</td><td class="num">${fmt(r[k + '_mcse'])}</td>`;
    tb.appendChild(tr);
  }
  $('#truth').textContent = `${t('truth')}: ${t('true_delta')} = ${fmt(r.delta, 6)} · ${t('true_gmr')} = ${fmt(r.gmr, 6)} · ${t('true_eta')} = ${fmt(r.eta, 6)} · nsim = ${r.n_sim} · seed = ${r.seed}`;
  $('#result').hidden = false;
}
function renderTimes() {
  const parts = [];
  if (tInitMs !== null) parts.push(`${t('t_init')}: ${fmt(tInitMs / 1000, 1)} s`);
  if (record) parts.push(`${t('t_run')}: ${fmt(record.elapsed_ms / 1000, 1)} s`);
  $('#times').textContent = parts.join(' · ');
}
// Errors are kept as a function so that a language switch re-renders them
let errFn = null;
function showErrors(fn) {
  const el = $('#errors');
  errFn = fn;
  if (!fn) { el.hidden = true; el.innerHTML = ''; return; }
  const lines = fn();
  el.innerHTML = `<b></b><ul></ul>`;
  el.querySelector('b').textContent = lines[0];
  for (const l of lines.slice(1)) { const li = document.createElement('li'); li.textContent = l; el.querySelector('ul').appendChild(li); }
  el.hidden = false;
}
function fmtInt(x) { return x.toLocaleString(lang === 'tr' ? 'tr-TR' : 'en-US'); }
// Largest n_sim allowed for the design in the form (min of N_SIM_MAX and CELLS_MAX / (l n m))
function nsimMax(p) {
  const d = [p.l, p.n, p.m];
  if (!d.every((v) => Number.isInteger(v) && v >= 1)) return null;
  return Math.min(N_SIM_MAX, Math.floor(CELLS_MAX / (p.l * p.n * p.m)));
}
function updateMcse() {
  const n = Number(String(new FormData($('#form')).get('n_sim')).replace(',', '.'));
  $('#mcse_exp').textContent = Number.isInteger(n) && n >= 1 && n <= N_SIM_MAX ? fmt(Math.sqrt(0.25 / n), 4) : '—';
  const mx = nsimMax(readForm().p);
  $('#nsim_max').textContent = mx === null ? '—' : fmtInt(mx);
}
// ---------------------------------------------------------------- P3: R script (tier 3)
async function exportScript() {
  if (!webR) return;
  const { p, choice, gmr } = readForm();
  const form = JSON.stringify({ p, choice, gmr: choice === 'custom' ? gmr : null });
  // header of the script names the browser run only if it used exactly these inputs
  const src = record && record.form === form ? {
    run_source: 'browser', started: record.started, elapsed_ms: record.elapsed_ms,
    webr_version: record.webr_version, r_version: record.r_version, rng: record.rng } : {};
  const rStr = (s) => JSON.stringify(String(s));
  const kaynak = 'list(' + Object.entries(src).map(([k, v]) => `${k} = ${typeof v === 'number' ? rNum(v) : rStr(v)}`).join(', ') + ')';
  const pinned = 'c(' + files.filter((e) => e.pinned).map((e) => `${rStr(e.file)} = ${rStr(e.expected)}`).join(', ') + ')';
  $('#export').disabled = true; $('#run').disabled = true; showErrors(null);
  setStatus('st_exporting');
  let out;
  try {
    const code = `.p3_export(${rList(p)}, ${JSON.stringify(choice)}, ${rNum(gmr)}, ${kaynak}, ${pinned}, ${rStr(pkgVersion)})`;
    const shelter = await new webR.Shelter();
    try { out = plain(await (await shelter.evalR(code)).toJs()); } finally { await shelter.purge(); }
  } catch (err) { out = { ok: false, kind: 'engine', message: String(err && err.message || err) }; }
  $('#export').disabled = false; $('#run').disabled = false;
  if (!out.ok) {
    setStatus('st_export_error', 'bad');
    if (out.kind === 'input') {
      const fields = [].concat(out.field), codes = [].concat(out.code);
      showErrors(() => [t('err_input'), ...codes.map((c, i) => t('code_' + c, T[lang] && T[lang][fields[i]] ? t(fields[i]) : fields[i]))]);
    } else if (out.kind === 'delta0') showErrors(() => [t('err_delta0')]);
    else showErrors(() => [t('err_engine'), out.message]);
    return;
  }
  window.__p3_last_script = out.text;                       // read by the acceptance tool
  const stamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const blob = new Blob([out.text], { type: 'text/plain;charset=utf-8' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `farmastatr_senaryo_${stamp}.R`;
  a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  setStatus(Object.keys(src).length ? 'st_exported_run' : 'st_exported', 'ok');
}

function download() {
  if (!record) return;
  const blob = new Blob([JSON.stringify(record, null, 1)], { type: 'application/json' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `farmastatr_p1_${record.started.replace(/[:.]/g, '-')}.json`;
  a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}

$('#form').addEventListener('submit', run);
$('#cancel').addEventListener('click', cancel);
$('#download').addEventListener('click', download);
$('#export').addEventListener('click', () => { exportScript(); });
$('#lang').addEventListener('click', () => { lang = lang === 'tr' ? 'en' : 'tr'; applyLang(); });
$('#form').addEventListener('input', updateMcse);
$('select[name=delta_choice]').addEventListener('change', (e) => { $('#custom_wrap').hidden = e.target.value !== 'custom'; });
boot().catch((err) => { setStatus('st_error', 'bad'); showErrors(() => [String(err && err.message || err)]); });
