// CNK-FarmaStatR - P4 full screen (FSR-TN-PLT-04 v0.1, KK-54).
// Three tiers (FSR-TN-PLT-01 Table 3.1): a scenario of the results grid is shown from the
// database without starting webR (tier 2); any other scenario within the browser limit is
// run in webR (tier 1); above the limit the R script is offered (tier 3).
// The page does no statistics: classes, metric names, KK-38 labels and numbers come from R
// (platform_hipotez, platform_kk38, platform_run_invitro) or from the database R built.
// Research and education only; not a system validated for GxP environments.

import { WEBR_VERSION, TAMPER, verifyFiles, startWebR, plain, fetchBytes } from '../p1/motor.js';
import { openDb, scenario, neighbours, SQLJS_VERSION } from './hazir.js';
import { pct, pp, num, anahtar, numExact, SINIRLAR } from './bicim.js';
import { g1, g2 } from './grafik.js';
import { R_P5, initTasarim, onLang as tasLang, setReady as tasReady, tasLink } from './tasarim.js';

const Q = new URLSearchParams(location.search);
const ENGINE = ['sim_run.R', 'invitro_fast.R', 'invitro_grid.R'];                     // pinned
const PLATFORM = ['platform_input.R', 'platform_hipotez.R', 'platform_export.R', 'platform_tasarim.R'];   // hash recorded
const N_SIM_MAX = 20000, CELLS_MAX = 8.1e6;            // display only; R enforces (KK-47)
const Z = 1.6448536269514722;                           // qnorm(0.95) in R (KK-38)
const ALPHA = 0.05;
const METHODS = ['fda', 'ema_a', 'ema_b', 'ema_c'];
const PAIRS = [['fda', 'ema_a'], ['fda', 'ema_b'], ['fda', 'ema_c'], ['ema_a', 'ema_c'], ['ema_b', 'ema_c']];
let K_CELL = 1.75e-6;     // s per cell; P1 run 6 x 30, m = 3, 15,000 (about 14 s); updated after a live run

const $ = (s) => document.querySelector(s);
let T = {}, lang = Q.get('lang') === 'en' ? 'en' : 'tr', pkgVersion = 'source';
let files = [], webR = null, webRStart = null, rInfo = {}, hz = null, runToken = 0;
let cur = null, display = null, versionHold = false, layerKey = '';
function setLayer(k) { layerKey = k; $('#layer_info').textContent = k ? t(k) : ''; }
const state = window.__p4 = { webrStarted: false, ready: false, hz: null, display: null, layer: null, pre: null };

// ---------------------------------------------------------------- i18n
const t = (k) => (T[lang] && T[lang][k] !== undefined ? T[lang][k] : (T.tr && T.tr[k] !== undefined ? T.tr[k] : k));
function applyLang() {
  document.documentElement.lang = lang;
  document.querySelectorAll('[data-i18n]').forEach((e) => { e.textContent = t(e.dataset.i18n); });
  $('#custom_label').textContent = t($('select[name=delta_choice]').value === 'delta' ? 'custom_delta' : 'custom_gmr');
  renderEngine(); updateInfo(); setLayer(layerKey); if (display) render(display); if (state.pre) renderPre(state.pre);
  if (statusKey) setStatus(statusKey, statusCls, statusArg); if (errFn) showErrors(errFn); if (versionHold) showVersionBox();
  tasLang();
}
let statusKey = null, statusCls = '', statusArg = '';
function setStatus(k, cls = '', arg = '') {
  statusKey = k; statusCls = cls; statusArg = arg; state.status = k;
  const e = $('#status'); e.textContent = t(k) + (arg ? ' ' + arg : ''); e.className = cls;
}
let errFn = null;
function showErrors(fn) {
  const e = $('#errors'); errFn = fn;
  if (!fn) { e.hidden = true; e.innerHTML = ''; return; }
  const lines = fn(); e.innerHTML = '<b></b><ul></ul>'; e.querySelector('b').textContent = lines[0];
  for (const l of lines.slice(1)) { const li = document.createElement('li'); li.textContent = l; e.querySelector('ul').append(li); }
  e.hidden = false;
}
// input-check message: {f} = field label, {max} = largest n_sim for the design in the form
function codeMsg(code, field) {
  const { p } = readForm(); const okDim = [p.l, p.n, p.m].every((v) => Number.isInteger(v) && v >= 1);
  const mx = okDim ? Math.min(N_SIM_MAX, Math.floor(CELLS_MAX / (p.l * p.n * p.m))) : null;
  return t('code_' + code).replace('{f}', field && t(field) !== field ? t(field) : (field || '')).replace('{max}', mx === null ? '—' : fmtInt(mx));
}
const fmtInt = (x) => x.toLocaleString(lang === 'tr' ? 'tr-TR' : 'en-US');

// ---------------------------------------------------------------- form
function readForm() {
  const f = new FormData($('#form'));
  const nm = (k) => { const s = String(f.get(k) ?? '').trim().replace(',', '.'); return s === '' ? NaN : Number(s); };
  const p = {};
  for (const k of ['sigma_R', 'rho', 'pB_T', 'pB_R', 'pL', 'q', 'l', 'n', 'm', 'n_sim', 'seed']) p[k] = nm(k);
  const choice = f.get('delta_choice'), custom = nm('custom');
  return { p, choice, custom };
}
function setForm(o) {
  for (const [k, v] of Object.entries(o)) { const e = $(`[name=${k}]`); if (e && v !== null && v !== undefined) e.value = String(v); }
  $('#custom_wrap').hidden = !['gmr', 'delta'].includes($('select[name=delta_choice]').value);
}
// boundary name, or a delta (log scale) for custom inputs; GMR is converted in R for runs
function deltaOf(c) {
  if (SINIRLAR.includes(c.choice)) return { sinir: c.choice, delta: null, key: c.choice };
  if (c.choice === 'gmr') return { sinir: null, delta: null, gmr: c.custom, key: Math.log(c.custom) };
  return { sinir: null, delta: c.custom, key: c.custom };
}
const formString = (c) => JSON.stringify({ p: c.p, choice: c.choice, custom: ['gmr', 'delta'].includes(c.choice) ? c.custom : null });
const rNum = (x) => (Number.isFinite(x) ? numExact(x) : 'NA_real_');
const rList = (p) => 'list(' + Object.entries(p).map(([k, v]) => `${k} = ${rNum(v)}`).join(', ') + ')';
const rStr = (s) => JSON.stringify(String(s));

function updateInfo() {
  const { p } = readForm();
  const okDim = [p.l, p.n, p.m].every((v) => Number.isInteger(v) && v >= 1);
  $('#design_info').textContent = okDim ? `${t('units_per_product')}: ${fmtInt(p.l * p.n)} · ${t('meas_per_product')}: ${fmtInt(p.l * p.n * p.m)}` : '';
  const n = p.n_sim, mx = okDim ? Math.min(N_SIM_MAX, Math.floor(CELLS_MAX / (p.l * p.n * p.m))) : null;
  const parts = [];
  if (Number.isInteger(n) && n >= 1) {
    parts.push(`${t('exp_mcse')}: p = ${num(0.05, 2, lang)} → ${pp(Math.sqrt(0.05 * 0.95 / n), lang)} ${t('pp')}; p = ${num(0.8, 2, lang)} → ${pp(Math.sqrt(0.8 * 0.2 / n), lang)} ${t('pp')}`);
    if (okDim) parts.push(`${t('est_time')}: ~${num(K_CELL * p.l * p.n * p.m * n, 0, lang)} s`);
  }
  if (mx !== null) parts.push(`${t('nsim_max_design')}: ${fmtInt(mx)}`);
  $('#mc_info').textContent = parts.join(' · ');
}

// ---------------------------------------------------------------- engine (lazy: tier 2 needs no webR)
function renderEngine() {
  const tb = $('#engine_table tbody'); tb.innerHTML = '';
  const add = (a, b, c) => { const tr = document.createElement('tr'); tr.innerHTML = '<td></td><td></td><td></td>';
    tr.children[0].textContent = a; tr.children[1].textContent = b; tr.children[2].textContent = c; tb.append(tr); };
  for (const e of files) add(e.file, e.status === 'ok' ? (e.pinned ? '✓ SHA-256' : 'SHA-256 (' + t('recorded') + ')') : '✗ ' + t(e.status), e.sha256 || '');
  if (hz) add('veri/farmastatr_v1.sqlite', hz.ok ? '✓ SHA-256 · sql.js ' + SQLJS_VERSION : '✗ ' + t(hz.reason), hz.info.sha256 || '');
  add('webR', state.webrStarted ? WEBR_VERSION + (rInfo.r_version ? ' · ' + rInfo.r_version : '') : t('webr_not_started'), '');
}
const R_WRAPPER = `
.p4_hip <- function(p, sinir, delta) {
  pr <- platform_check_invitro(c(p, list(delta = if (is.null(delta)) 0 else delta)), n_sim_max = Inf, cells_max = Inf)
  if (nrow(pr) > 0) return(list(ok = FALSE, kind = "input", field = pr$field, code = pr$code, message = pr$message))
  h <- tryCatch(if (is.null(sinir)) platform_hipotez(p$sigma_R, p$rho, delta = delta) else platform_hipotez(p$sigma_R, p$rho, sinir = sinir),
                error = function(e) e)
  if (inherits(h, "error")) return(list(ok = FALSE, kind = if (grepl("delta0", conditionMessage(h))) "delta0" else "engine", message = conditionMessage(h)))
  list(ok = TRUE, yontem = h$yontem, sinif = h$sinif, metrik = h$metrik, yakinlik = h$yakinlik_uyarisi, delta = h$delta[1])
}
.p4_run <- function(p, sinir, delta) {
  pr <- platform_check_invitro(c(p, list(delta = if (is.null(delta)) 0 else delta)))
  if (nrow(pr) > 0) return(list(ok = FALSE, kind = "input", field = pr$field, code = pr$code, message = pr$message))
  d <- if (is.null(sinir)) delta else platform_sinir_delta(sinir, p$sigma_R, p$rho)
  if (is.na(d)) return(list(ok = FALSE, kind = "delta0"))
  r <- tryCatch(platform_run_invitro(c(p, list(delta = d))), farmastat_input_error = function(e) e,
                error = function(e) structure(list(message = conditionMessage(e)), class = "p4_engine_error"))
  if (inherits(r, "farmastat_input_error"))
    return(list(ok = FALSE, kind = "input", field = r$problems$field, code = r$problems$code, message = r$problems$message))
  if (inherits(r, "p4_engine_error")) return(list(ok = FALSE, kind = "engine", message = r$message))
  h <- if (is.null(sinir)) platform_hipotez(p$sigma_R, p$rho, delta = d) else platform_hipotez(p$sigma_R, p$rho, sinir = sinir)
  me <- h$yontem
  rate <- unlist(r[paste0(me, "_pass")]); se <- unlist(r[paste0(me, "_pass_mcse")])
  list(ok = TRUE, rng = paste(RNGkind()[1:2], collapse = "/"), result = as.list(r), yontem = me, sinif = h$sinif,
       metrik = h$metrik, yakinlik = h$yakinlik_uyarisi, kk38 = unname(platform_kk38(unname(rate), unname(se), h$sinif)),
       key = platform_anahtar(p$sigma_R, p$rho, p$pB_T, p$pB_R, p$pL, p$q, p$l, p$n, p$m,
                              delta = if (is.null(sinir)) d else NULL, sinir = sinir, n_sim = p$n_sim, seed = p$seed, kosu = TRUE))
}
.p4_export <- function(p, sinir, delta, kaynak, pinned, ver) {
  if (!is.null(delta)) p$delta <- delta
  if (!length(kaynak)) kaynak <- NULL
  r <- tryCatch(platform_export_invitro(p, sinir = sinir, dosyalar = platform_motor_dosyalari("/home/web_user"),
                                        cekirdek_sha = pinned, kaynak = kaynak, paket_surumu = ver),
    farmastat_input_error = function(e) e, error = function(e) structure(list(message = conditionMessage(e)), class = "p4_engine_error"))
  if (inherits(r, "farmastat_input_error"))
    return(list(ok = FALSE, kind = "input", field = r$problems$field, code = r$problems$code, message = r$problems$message))
  if (inherits(r, "p4_engine_error")) return(list(ok = FALSE, kind = if (grepl("delta0 is not defined", r$message)) "delta0" else "engine", message = r$message))
  list(ok = TRUE, text = r)
}`;
function ensureWebR() {
  if (webR) return Promise.resolve(webR);
  if (webRStart) return webRStart;
  if (files.some((e) => e.status !== 'ok')) return Promise.reject(new Error(t('st_blocked')));
  state.webrStarted = true; renderEngine();
  const t0 = performance.now();
  webRStart = (async () => {
    const w = await startWebR(files, R_WRAPPER + R_P5);
    rInfo.r_version = await w.evalRString('R.version.string');
    rInfo.start_ms = Math.round(performance.now() - t0);
    webR = w; webRStart = null; renderEngine(); return w;
  })();
  return webRStart;
}
async function callR(code, env) {
  const w = await ensureWebR();
  const sh = await new w.Shelter();
  try { return plain(await (await sh.evalR(code, env ? { env } : undefined)).toJs()); } finally { await sh.purge(); }
}
function killWebR() {
  try { if (webR) webR.close(); } catch (e) { /* gone */ }
  webR = null; webRStart = null; state.webrStarted = false; renderEngine();
}
// R strings for the arguments (GMR -> delta in R, as in P1)
function rArgs(c) {
  const d = deltaOf(c);
  const delta = d.sinir ? 'NULL' : (c.choice === 'gmr' ? `suppressWarnings(log(${rNum(c.custom)}))` : rNum(c.custom));
  return { p: rList(c.p), sinir: d.sinir ? rStr(d.sinir) : 'NULL', delta };
}

// ---------------------------------------------------------------- tier selection
let updTimer = null;
function scheduleUpdate() { updateInfo(); clearTimeout(updTimer); updTimer = setTimeout(update, 250); }
async function update() {
  if (versionHold) return;
  const c = readForm(); const d = deltaOf(c);
  c.key = anahtar(c.p, d.sinir || d.key);              // NaN inputs give a key that matches nothing
  cur = c; state.key = c.key; showErrors(null);
  const no = hz && hz.ok && c.key ? hz.index.get(c.key) : undefined;
  if (no !== undefined) {                                    // tier 2
    state.layer = 'hazir'; state.pre = null; $('#hyp_pre').textContent = '';
    setLayer('layer_hazir');
    $('#run').dataset.i18n = 'run_live_too'; $('#run').textContent = t('run_live_too');
    showHazir(no);
    return;
  }
  $('#run').dataset.i18n = 'run'; $('#run').textContent = t('run');
  const p = c.p, cells = p.l * p.n * p.m * p.n_sim;
  const above = Number.isFinite(cells) && (p.n_sim > N_SIM_MAX || cells > CELLS_MAX);
  state.layer = above ? 'betik' : 'canli';
  setLayer(above ? 'layer_betik' : 'layer_canli');
  if (display && display.source === 'hazir') clearResult();
  // hypothesis state before the run, from R
  $('#hyp_pre').textContent = t('hyp_wait');
  const token = ++runToken;
  try {
    const a = rArgs(c);
    const out = await callR(`.p4_hip(${a.p}, ${a.sinir}, ${a.delta})`);
    if (token !== runToken) return;
    state.pre = out; renderPre(out);
  } catch (e) { if (token === runToken) $('#hyp_pre').textContent = String(e.message || e); }
}
function renderPre(o) {
  if (!o) return;
  if (!o.ok) { const f = [].concat(o.field); $('#hyp_pre').textContent = o.kind === 'delta0' ? t('err_delta0') : o.kind === 'input' ? t('err_input') + ': ' + [].concat(o.code).map((k, i) => codeMsg(k, f[i])).join(' ') : o.message; return; }
  const ys = [].concat(o.yontem), cs = [].concat(o.sinif), ms = [].concat(o.metrik);
  $('#hyp_pre').textContent = t('hyp_pre') + ': ' + ys.map((y, i) => `${t('m_' + y)} — ${t('sinif_' + cs[i])} (${t('metrik_' + ms[i])})`).join(' · ');
}
function clearResult() { display = null; state.display = null; $('#result').hidden = true; $('#json').disabled = true; }

// ---------------------------------------------------------------- tier 2 display
function showHazir(no) {
  const d = scenario(hz.db, no);
  const hip = Object.fromEntries(d.hip.map((h) => [h.yontem_id, h]));
  const rowsM = METHODS.map((me) => {
    const r = d.pick(me, 'pass');
    return { yontem: me, metrik: hip[me].metrik, sinif: hip[me].sinif, rate: r.tahmin, mcse: r.mcse, kk38: r.kk38, yakinlik: !!hip[me].yakinlik_uyarisi, kosu: r.kosu_id, n: r.n_tekrar };
  });
  const extra = [];
  const ex = (key, me, olcut) => { const r = d.pick(me, olcut); if (r) extra.push({ key, rate: r.tahmin, mcse: r.mcse, kosu: r.kosu_id }); };
  ex('crit_err_fda', 'fda', 'crit_err');
  for (const me of METHODS) ex('cover_' + me, me, 'cover');
  ex('pooled_T', 'ema_c', 'pooled_T'); ex('pooled_R', 'ema_c', 'pooled_R');
  for (const [a, b] of PAIRS) { const r = d.pickDiff(a, b); if (r) extra.push({ key: `diff_${a}_${b}`, rate: r.tahmin, mcse: r.mcse, mcse_not: r.mcse_not, kosu: r.kosu_id, diff: true }); }
  const s = d.s;
  display = {
    source: 'hazir', no, key: s.senaryo_anahtar, rows: rowsM, extra,
    truth: { delta: s.delta, gmr: s.gmr, eta: s.eta, delta_ad: s.delta_ad },
    kosu: { shown: d.shown, main: d.main, sources: d.sources },
    nb: neighbours(hz.db, s), db: hz.info
  };
  render(display);
  setStatus('st_hazir', 'ok');
}

// ---------------------------------------------------------------- render (shared by tiers 1 and 2)
function render(D) {
  state.display = D;
  const tb = $('#res_table tbody'); tb.innerHTML = '';
  for (const r of D.rows) {
    const tr = document.createElement('tr'); tr.dataset.yontem = r.yontem;
    const cells = [t('m_' + r.yontem), t('metrik_' + r.metrik), t('sinif_' + r.sinif), pct(r.rate, lang), pp(r.mcse, lang),
      r.kk38 ? t('kk38_' + r.kk38) : '—'];
    cells.forEach((v, i) => { const td = document.createElement('td'); td.textContent = v; if (i === 3 || i === 4) td.className = 'num';
      td.dataset.col = ['yontem', 'metrik', 'sinif', 'oran', 'mcse', 'kk38'][i]; tr.append(td); });
    tb.append(tr);
  }
  // warnings
  const w = [];
  if (D.rows.some((r) => r.sinif === 'H1')) w.push(['warn_power', t('warn_power')]);
  if (D.rows.some((r) => r.yakinlik)) w.push(['warn_near', t('warn_near')]);
  if (D.source === 'hazir') {
    const k = D.kosu.main, c = cur && cur.p;
    if (c && (c.n_sim !== D.kosu.shown.n_sim || c.seed !== k.seed)) w.push(['warn_hazir_nsim', t('warn_hazir_nsim')]);
  }
  const wb = $('#warnings'); wb.innerHTML = '';
  for (const [k, v] of w) { const p = document.createElement('p'); p.className = 'warn'; p.dataset.warn = k; p.textContent = v; wb.append(p); }
  // source
  if (D.source === 'hazir') {
    const sh = D.kosu.shown, mn = D.kosu.main;
    $('#source').textContent = `${t('src_hazir')} · ${t('src_shown')}: ${sh.kosu_id} (n = ${fmtInt(sh.n_sim)}${sh.tur === 'birlesik' ? ' = ' + D.kosu.sources.join(' + ') : ''})` +
      ` · ${t('src_main')}: ${mn.kosu_id} (n = ${fmtInt(mn.n_sim)}, seed ${mn.seed}, ${mn.rng}) · ${t('src_engine')}: ${mn.motor_surumu} · ${t('src_db')} v${D.db.vt_surumu}, SHA-256 ${D.db.sha256.slice(0, 12)}…`;
  } else {
    $('#source').textContent = `${t('src_canli')} · webR ${WEBR_VERSION} · ${rInfo.r_version} · n = ${fmtInt(D.n_sim)}, seed ${D.seed}, ${D.rng} · ${num(D.elapsed_ms / 1000, 1, lang)} s`;
  }
  // more
  const mt = $('#more_table tbody'); mt.innerHTML = '';
  for (const e of D.extra) {
    const tr = document.createElement('tr'); tr.dataset.key = e.key;
    let lab = e.diff ? t('diff') + ': ' + e.key.slice(5).split('_ema').join(' − ema').replace(/^fda/, 'FDA').replaceAll('ema_', 'EMA ') : t('x_' + e.key);
    if (D.source === 'hazir' && e.kosu && e.kosu !== D.kosu.shown.kosu_id) lab += ` (${e.kosu}, n = ${fmtInt(D.kosu.main.n_sim)})`;
    const se = e.mcse === null || e.mcse === undefined ? '— (' + t('no_paired_mcse') + ')' : pp(e.mcse, lang) + ' ' + t('pp');
    [lab, e.diff ? num(100 * e.rate, 2, lang) + ' ' + t('pp') : pct(e.rate, lang) + ' %', se].forEach((v, i) => {
      const td = document.createElement('td'); td.textContent = v; if (i > 0) td.className = 'num'; tr.append(td); });
    mt.append(tr);
  }
  // charts
  g1($('#g1'), D.rows.map((r) => ({ yontem: r.yontem, label: t('m_' + r.yontem), rate: r.rate, mcse: r.mcse, sinif: r.sinif })),
    Z, ALPHA, (p) => pct(p, lang), t);
  $('#g2_head').hidden = D.source !== 'hazir'; $('#g2').hidden = D.source !== 'hazir';
  if (D.source === 'hazir') g2($('#g2'), D.nb, D.no, (p) => pct(p, lang), (x) => num(x, 3, lang).replace(/[,.]?0+$/, ''), t, (m) => t('m_' + m));
  $('#truth').textContent = `${t('truth')}: δ = ${num(D.truth.delta, 6, lang)} · GMR = ${num(D.truth.gmr, 6, lang)} · η = ${num(D.truth.eta, 6, lang)}`;
  $('#result').hidden = false; $('#json').disabled = false;
}

// ---------------------------------------------------------------- tier 1 run, cancel
async function run(ev) {
  ev.preventDefault();
  if (versionHold) return;
  const c = readForm(); cur = c;
  const token = ++runToken;
  $('#run').disabled = true; $('#cancel').disabled = false; $('#script').disabled = true; showErrors(null);
  setStatus(webR ? 'st_running' : 'st_loading');
  const t0 = performance.now(); const started = new Date();
  let out;
  try {
    await ensureWebR(); if (token !== runToken) return;
    setStatus('st_running');
    const a = rArgs(c);
    const t1 = performance.now();
    out = await callR(`.p4_run(${a.p}, ${a.sinir}, ${a.delta})`);
    out.elapsed_ms = performance.now() - t1;
  } catch (err) {
    if (token !== runToken) return;
    out = { ok: false, kind: 'engine', message: String(err && err.message || err) };
  }
  if (token !== runToken) return;
  $('#cancel').disabled = true; $('#run').disabled = false; $('#script').disabled = false;
  if (!out.ok) {
    setStatus('st_error', 'bad');
    if (out.kind === 'input') {
      const codes = [].concat(out.code), fields = [].concat(out.field);
      const big = codes.some((k) => k === 'run_size' || k === 'n_sim_range');
      showErrors(() => [t('err_input'), ...codes.map((k, i) => codeMsg(k, fields[i])), ...(big ? [t('go_script')] : [])]);
    } else if (out.kind === 'delta0') showErrors(() => [t('err_delta0')]);
    else showErrors(() => [t('err_engine'), out.message]);
    return;
  }
  const r = out.result, ys = [].concat(out.yontem);
  const cells = c.p.l * c.p.n * c.p.m * c.p.n_sim; K_CELL = out.elapsed_ms / 1000 / cells; updateInfo();
  display = {
    source: 'canli', key: out.key, n_sim: r.n_sim, seed: r.seed, rng: out.rng, elapsed_ms: Math.round(out.elapsed_ms),
    started: started.toISOString(), form: formString(c), inputs: { ...c.p, delta_choice: c.choice, custom: ['gmr', 'delta'].includes(c.choice) ? c.custom : null },
    rows: ys.map((me, i) => ({ yontem: me, metrik: [].concat(out.metrik)[i], sinif: [].concat(out.sinif)[i], rate: r[me + '_pass'],
      mcse: r[me + '_pass_mcse'], kk38: [].concat(out.kk38)[i] === null || [].concat(out.kk38)[i] === 'NA' ? null : [].concat(out.kk38)[i], yakinlik: !![].concat(out.yakinlik)[i] })),
    extra: [
      { key: 'crit_err_fda', rate: r.fda_crit_err, mcse: r.fda_crit_err_mcse },
      ...METHODS.map((me) => ({ key: 'cover_' + me, rate: r[me + '_cover'], mcse: r[me + '_cover_mcse'] })),
      { key: 'pooled_T', rate: r.ema_c_pooled_T, mcse: r.ema_c_pooled_T_mcse }, { key: 'pooled_R', rate: r.ema_c_pooled_R, mcse: r.ema_c_pooled_R_mcse },
      ...PAIRS.map(([a, b]) => ({ key: `diff_${a}_${b}`, rate: r[`diff_${a}_${b}`], mcse: r[`diff_${a}_${b}_mcse`], diff: true }))],
    truth: { delta: r.delta, gmr: r.gmr, eta: r.eta }, result: r,
    files: files.map(({ file, pinned, sha256, status }) => ({ file, pinned, sha256, status }))
  };
  render(display);
  setStatus('st_done', 'ok');
}
async function cancel() {
  runToken++;
  $('#cancel').disabled = true;
  killWebR();
  setStatus('st_cancelled', 'bad');
  $('#run').disabled = false; $('#script').disabled = false;
}

// ---------------------------------------------------------------- bottom buttons
function linkUrl() {
  const c = readForm(), u = new URL(location.href.split('?')[0]);
  const P = { sR: 'sigma_R', rho: 'rho', pBT: 'pB_T', pBR: 'pB_R', pL: 'pL', q: 'q', l: 'l', n: 'n', m: 'm', nsim: 'n_sim', seed: 'seed' };
  for (const [k, f] of Object.entries(P)) u.searchParams.set(k, numExact(c.p[f]));
  u.searchParams.set('d', SINIRLAR.includes(c.choice) ? c.choice : `${c.choice}:${numExact(c.custom)}`);
  u.searchParams.set('lang', lang); u.searchParams.set('v', pkgVersion);
  for (const k of ['webr', 'sqljs']) if (Q.get(k)) u.searchParams.set(k, Q.get(k));
  return u.toString();
}
async function copyLink() {
  const u = window.__p5.mode === 'tasarim' ? tasLinkUrl() : linkUrl(); state.link = u;
  const msg = window.__p5.mode === 'tasarim' ? '#ts_link_msg' : '#link_msg';
  try { await navigator.clipboard.writeText(u); $(msg).textContent = t('link_copied'); }
  catch (e) { $(msg).textContent = u; }
}
function tasLinkUrl() {
  const u = tasLink(new URL(location.href.split('?')[0]));
  u.searchParams.set('lang', lang); u.searchParams.set('v', pkgVersion);
  for (const k of ['webr', 'sqljs']) if (Q.get(k)) u.searchParams.set(k, Q.get(k));
  return u.toString();
}
function parseLink() {
  if (!Q.has('sR')) return;
  const P = { sR: 'sigma_R', rho: 'rho', pBT: 'pB_T', pBR: 'pB_R', pL: 'pL', q: 'q', l: 'l', n: 'n', m: 'm', nsim: 'n_sim', seed: 'seed' };
  const o = {}; for (const [k, f] of Object.entries(P)) if (Q.has(k)) o[f] = Q.get(k);
  const d = Q.get('d') || 'fda_delta0';
  if (SINIRLAR.includes(d)) o.delta_choice = d; else { const [kind, v] = d.split(':'); o.delta_choice = kind; o.custom = v; }
  setForm(o);
  if (Q.has('v') && Q.get('v') !== pkgVersion) { versionHold = true; showVersionBox(); }
}
function showVersionBox() {
  const b = $('#version_box'); b.hidden = false; b.innerHTML = '<p></p><button type="button" id="ver_ok"></button>';
  b.querySelector('p').textContent = t('ver_diff').replace('{link}', Q.get('v')).replace('{site}', pkgVersion);
  const btn = b.querySelector('button'); btn.textContent = t('ver_continue');
  btn.addEventListener('click', () => { versionHold = false; b.hidden = true; scheduleUpdate(); });
}
function downloadJson() {
  if (!display) return;
  const rec = { platform: 'CNK-FarmaStatR', document: 'FSR-TN-PLT-04', disclaimer: T.en.disclaimer, disclaimer_tr: T.tr.disclaimer,
    package_version: pkgVersion, link: linkUrl(), saved: new Date().toISOString(), result_source: display.source,
    ...(display.source === 'hazir' ? { scenario_key: display.key, runs: display.kosu, database: display.db } :
      { run_key: display.key, webr_version: WEBR_VERSION, r_version: rInfo.r_version, files: display.files, started: display.started }),
    rows: display.rows, extra: display.extra, truth: display.truth, result: display.result || null };
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([JSON.stringify(rec, null, 1)], { type: 'application/json' }));
  a.download = `farmastatr_${display.source}_${new Date().toISOString().replace(/[:.]/g, '-')}.json`;
  a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}
async function exportScript() {
  const c = readForm();
  $('#script').disabled = true; setStatus('st_exporting'); showErrors(null);
  let out;
  try {
    const a = rArgs(c);
    const src = display && display.source === 'canli' && display.form === formString(c) ?
      `list(run_source = "browser", started = ${rStr(display.started)}, elapsed_ms = ${display.elapsed_ms}, webr_version = ${rStr(WEBR_VERSION)}, r_version = ${rStr(rInfo.r_version)}, rng = ${rStr(display.rng)})` : 'list()';
    const pinned = 'c(' + files.filter((e) => e.pinned).map((e) => `${rStr(e.file)} = ${rStr(e.expected)}`).join(', ') + ')';
    out = await callR(`.p4_export(${a.p}, ${a.sinir}, ${a.delta === 'NULL' ? 'NULL' : a.delta}, ${src}, ${pinned}, ${rStr(pkgVersion)})`);
  } catch (e) { out = { ok: false, kind: 'engine', message: String(e.message || e) }; }
  $('#script').disabled = false;
  if (!out.ok) {
    setStatus('st_export_error', 'bad');
    if (out.kind === 'input') { const f = [].concat(out.field); showErrors(() => [t('err_input'), ...[].concat(out.code).map((k, i) => codeMsg(k, f[i]))]); }
    else if (out.kind === 'delta0') showErrors(() => [t('err_delta0')]); else showErrors(() => [t('err_engine'), out.message]);
    return;
  }
  state.script = out.text;
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([out.text], { type: 'text/plain;charset=utf-8' }));
  a.download = `farmastatr_senaryo_${new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)}.R`;
  a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  setStatus('st_exported', 'ok');
}

// ---------------------------------------------------------------- boot
async function boot() {
  T = await (await fetch('ceviri.json', { cache: 'no-store' })).json();
  try { const d = new TextDecoder().decode(await fetchBytes('CNKfarmastatr/DESCRIPTION')); const m = d.match(/^Version:\s*(\S+)/m); if (m) pkgVersion = m[1]; } catch (e) { /* source */ }
  parseLink();
  initTasarim({
    t, lang: () => lang, callR, hz: () => hz, webrReady: () => !!webR, rVersion: () => rInfo.r_version,
    files: () => files.map(({ file, pinned, sha256, status }) => ({ file, pinned, sha256, status })),
    kcell: () => K_CELL, updateKcell: (k) => { if (Number.isFinite(k) && k > 0) { K_CELL = k; updateInfo(); } },
    codeMsg, cancelWebR: async () => killWebR(), pkgVersion: () => pkgVersion
  }, Q);
  if (Q.get('mode') === 'tasarim' && Q.has('v') && Q.get('v') !== pkgVersion) { versionHold = true; showVersionBox(); }
  applyLang();
  setStatus('st_verifying');
  [files, hz] = await Promise.all([verifyFiles(ENGINE, PLATFORM), openDb()]);
  state.hz = hz.ok ? hz.info : { ok: false, reason: hz.reason, ...hz.info };
  renderEngine();
  const blocked = files.some((e) => e.status !== 'ok');
  if (blocked) {
    $('#engine_box').open = true;
    showErrors(() => [t('st_blocked'), ...files.filter((e) => e.status !== 'ok').map((e) => `${e.file}: ${t(e.status)}`), ...(TAMPER ? [`test: ?bozuk=${TAMPER.file}:${TAMPER.pos}`] : [])]);
  }
  if (!hz.ok) { const p = document.createElement('p'); p.className = 'warn'; p.dataset.warn = 'db'; p.textContent = t('warn_db_' + hz.reason); $('#layer_info').after(p); }
  setStatus(blocked ? 'st_blocked' : 'st_ready', blocked ? 'bad' : 'ok');
  $('#run').disabled = blocked; $('#script').disabled = blocked; tasReady(!blocked);
  state.ready = true;
  await update();
}

$('#form').addEventListener('submit', run);
$('#form').addEventListener('input', scheduleUpdate);
$('#cancel').addEventListener('click', cancel);
$('#lang').addEventListener('click', () => { lang = lang === 'tr' ? 'en' : 'tr'; applyLang(); });
$('#link').addEventListener('click', copyLink);
$('#ts_link').addEventListener('click', copyLink);
$('#json').addEventListener('click', downloadJson);
$('#script').addEventListener('click', exportScript);
$('select[name=delta_choice]').addEventListener('change', (e) => {
  $('#custom_wrap').hidden = !['gmr', 'delta'].includes(e.target.value);
  $('[name=custom]').value = e.target.value === 'delta' ? '0' : '1.10';
  $('#custom_label').textContent = t(e.target.value === 'delta' ? 'custom_delta' : 'custom_gmr');
});
$('select[name=m_preset]').addEventListener('change', (e) => { if (e.target.value) { $('[name=m]').value = e.target.value; scheduleUpdate(); } });
boot().catch((err) => { setStatus('st_error', 'bad'); showErrors(() => [String(err && err.message || err)]); });
