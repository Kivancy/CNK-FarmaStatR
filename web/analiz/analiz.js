// CNK-FarmaStatR - P6 analysis screen (FSR-TN-PLT-06 v0.1, T-1; decision KK-59).
// One's own data with the inherited, validated models: PBE (FDA PSG 020929), model-independent
// MSD, Weibull MSD, f2 and bootstrap f2. The page computes nothing: R reads the CSV text
// (platform_analiz.R) and the unchanged bridges call the validated cores in webR. The data stay
// in the browser (no request carries them). Every text of a result is made once (pview, dview)
// and used by the screen and by the Word report (rapor.js), as in P5 (P5-K1).
// FSR-TN-PLT-08 v0.1 (KK-64): the PBE tab also runs EMA OIP Rev. 2 Section 5.1 criterion 8 (90% CI)
// with the validated simulation engine (invitro_array, ema_ci_fast; FSR-VAL-SIM-1).
// FSR-TN-PLT-11 v0.1 (KK-75): Section 9 'Analysed data' in the analysis reports: source, structure,
// SHA-256 of the uploaded file and, if the user ticks it, the data table as used in the analysis.
// Research and education only; not a system validated for GxP environments.

import { WEBR_VERSION, TAMPER, verifyFiles, startWebR, fetchBytes, sha256 } from '../p1/motor.js';
import { num, numExact } from '../app/bicim.js';
import { buildReport, TABLE, H2, P, download, stamp } from '../app/rapor.js';

const Q = new URLSearchParams(location.search);
// inherited validated cores (pinned in CEKIRDEK_SHA256.txt) and the platform reader
const ENGINE = ['msd_core.R', 'msd_weibull.R', 'f2_boot.R', 'f2_noce_data.R', 'dis_ornek_veri.R', 'pbe_core.R', 'pbe_kopru.R', 'pbe_ornek_veri.R', 'invitro_fast.R'];
const PLATFORM = ['platform_analiz.R'];
// v0.5.1 dissolution bridge, bytes unchanged (FSR-LOG-01 G-01)
const KOPRU = { file: 'dis_kopru.R', path: 'CNKfarmastatr/inst/kopru/dis_kopru.R', expected: '5dea054408d594a2eafecfeacde272bbc8f21e9da9507bbef1b15898274c4e28' };
const R_AN = `
.an <- new.env()
.an_null <- function(x) if (is.list(x)) lapply(x, function(v) if (is.null(v)) NA else .an_null(v)) else x
.an_hata <- function(e) list(ok = FALSE, message = conditionMessage(e))
.an_pbe_veri <- function(metin, ornek) tryCatch({
  v <- platform_pbe_veri(if (nzchar(metin)) metin else NULL, if (nzchar(ornek)) ornek else NULL)
  .an$pbe <- v; list(ok = TRUE, urunler = v$urunler, n = length(v$olcum)) }, error = .an_hata)
.an_pbe <- function(test, ref, log_d, tek) tryCatch({
  r <- platform_pbe(.an$pbe, test, ref, isTRUE(log_d), isTRUE(tek))
  list(ok = TRUE, hazir = .an_null(r$hazir), sonuc = .an_null(r$sonuc)) }, error = .an_hata)
.an_ema <- function(test, ref, log_d) tryCatch({
  r <- platform_ema(.an$pbe, test, ref, isTRUE(log_d))
  list(ok = TRUE, hazir = .an_null(r$hazir), sonuc = .an_null(r$sonuc)) }, error = .an_hata)
.an_dis_veri <- function(metin, ornek) tryCatch({
  v <- platform_dis_veri(if (nzchar(metin)) metin else NULL, if (nzchar(ornek)) ornek else NULL)
  .an$dis <- v; list(ok = TRUE, urunler = v$urunler, n = length(v$Diss)) }, error = .an_hata)
.an_tablo <- function(tur, urunler, enfazla) tryCatch({        # data as used in the analysis (KK-75)
  u <- strsplit(urunler, "\n", fixed = TRUE)[[1]]
  if (tur == "pbe") { v <- .an$pbe; i <- v$urun %in% u
    d <- list(parti = v$parti[i], kap = v$kap[i], asama = v$asama[i], urun = v$urun[i], olcum = v$olcum[i])
  } else { v <- .an$dis; i <- v$Product %in% u
    d <- list(Product = v$Product[i], Unit = v$Unit[i], Time = as.character(v$Time[i]), Diss = as.character(v$Diss[i])) }
  n <- sum(i); list(ok = TRUE, n = n, tablo = if (n <= enfazla) d else NULL) }, error = .an_hata)
.an_dis <- function(test, ref, lotlar, birim, yontem, ayar_k, ayar_v) tryCatch({
  lotlar <- if (nzchar(lotlar)) strsplit(lotlar, "\n", fixed = TRUE)[[1]] else character(0)
  if (is.null(.an$kp)) .an$kp <- platform_dis_kopru("/home/web_user/dis_kopru.R", globalenv())
  ayar <- list()
  if (nzchar(ayar_k)) { k <- strsplit(ayar_k, "\n", fixed = TRUE)[[1]]; v <- strsplit(ayar_v, "\n", fixed = TRUE)[[1]]
    for (i in seq_along(k)) ayar[[k[i]]] <- if (k[i] %in% c("B", "seed", "Dg", "k")) as.numeric(v[i]) else v[i] }
  r <- platform_dis(.an$kp, .an$dis, test, ref, lotlar, birim, yontem, ayar)
  s <- r$sonuc; s$boot <- NULL; s$tt <- NULL; s$egR <- NULL; s$egT <- NULL
  h <- r$hazir; h$tekT <- NULL; h$tekR <- NULL
  list(ok = TRUE, hazir = .an_null(h), sonuc = .an_null(s)) }, error = .an_hata)`;

const $ = (s) => document.querySelector(s);
// webR object -> plain JS (named lists -> objects, unnamed lists -> arrays, length-1 vectors -> scalars)
function plain(js) {
  if (js.type === 'list') {
    if (!js.names || js.names.every((n) => !n)) return js.values.map(plain);
    const o = {}; js.names.forEach((n, i) => { o[n] = plain(js.values[i]); }); return o;
  }
  if (js.type === 'null') return null;
  const v = js.values; return v.length === 1 ? v[0] : v;
}
let T = {}, lang = Q.get('lang') === 'en' ? 'en' : 'tr', pkgVersion = 'source';
let files = [], kopru = null, webR = null, webRStart = null, rInfo = {};
const st = window.__p6 = { ready: false, status: {}, pbe: null, dis: null };
const t = (k) => (T[lang] && T[lang][k] !== undefined ? T[lang][k] : (T.tr && T.tr[k] !== undefined ? T.tr[k] : k));
const fmtInt = (x) => Number(x).toLocaleString(lang === 'tr' ? 'tr-TR' : 'en-US');
const N = (x, d) => (x === null || x === undefined || Number.isNaN(x) ? '—' : num(x, d, lang));
const arr = (x) => (x === null || x === undefined ? [] : [].concat(x));
const decTxt = (s) => (lang === 'tr' ? String(s).replace('.', ',') : String(s));

// ---------------------------------------------------------------- engine
async function ensureWebR() {
  if (webR) return webR;
  if (webRStart) return webRStart;
  if (files.some((e) => e.status !== 'ok') || !kopru || kopru.status !== 'ok') throw new Error(t('st_blocked'));
  webRStart = (async () => {
    const w = await startWebR(files, R_AN);
    await w.FS.writeFile('/home/web_user/' + KOPRU.file, kopru.bytes);
    rInfo.r_version = await w.evalRString('R.version.string');
    webR = w; renderEngine(); return w;
  })();
  return webRStart;
}
async function callR(code, env) {
  const w = await ensureWebR();
  const sh = await new w.Shelter();
  try { return plain(await (await sh.evalR(code, env ? { env } : undefined)).toJs()); } finally { await sh.purge(); }
}
function renderEngine() {
  const tb = $('#engine_table tbody'); tb.innerHTML = '';
  const add = (a, b, c) => { const tr = document.createElement('tr'); for (const v of [a, b, c]) { const td = document.createElement('td'); td.textContent = v; tr.append(td); } tb.append(tr); };
  for (const e of files) add(e.file, e.status === 'ok' ? (e.pinned ? '✓ SHA-256' : 'SHA-256 (' + t('recorded') + ')') : '✗ ' + t(e.status), e.sha256 || '');
  if (kopru) add(KOPRU.file, kopru.status === 'ok' ? '✓ SHA-256 (G-01)' : '✗ ' + t(kopru.status), kopru.sha256 || '');
  add('webR', webR ? WEBR_VERSION + (rInfo.r_version ? ' · ' + rInfo.r_version : '') : t('webr_not_started'), '');
}

// ---------------------------------------------------------------- shared UI helpers
function setStatus(sec, k, cls = '', arg = '') {
  st.status[sec] = k; const e = $(`#${sec}_status`); e.textContent = k ? t(k) + (arg ? ' ' + arg : '') : ''; e.className = 'status ' + cls;
  e.dataset.key = k || ''; e.dataset.cls = cls; e.dataset.arg = arg;
}
function showErrors(sec, lines) {
  const e = $(`#${sec}_errors`);
  if (!lines) { e.hidden = true; e.innerHTML = ''; return; }
  e.innerHTML = '<b></b><ul></ul>'; e.querySelector('b').textContent = lines[0];
  for (const l of lines.slice(1)) { const li = document.createElement('li'); li.textContent = l; e.querySelector('ul').append(li); }
  e.hidden = false;
}
function fillTable(sel, rows, head) {
  const tb = $(sel); tb.querySelector('tbody').innerHTML = '';
  const th = tb.querySelector('thead'); if (th) th.innerHTML = '';
  if (head && th) { const tr = document.createElement('tr'); for (const h of head) { const c = document.createElement('th'); c.textContent = h; tr.append(c); } th.append(tr); }
  for (const r of rows) { const tr = document.createElement('tr'); r.forEach((v, i) => { const c = document.createElement('td'); c.textContent = v; if (i > 0 && /^[−\-+0-9.,% ]+$/.test(v)) c.className = 'num'; tr.append(c); }); tb.querySelector('tbody').append(tr); }
}
function warnList(sel, list) {
  const b = $(sel); b.innerHTML = '';
  for (const w of list) { const p = document.createElement('p'); p.className = 'warn'; p.textContent = w; b.append(p); }
}
function fillSelect(sel, items, want) {
  const s = $(sel), keep = s.value; s.innerHTML = '';
  for (const u of items) { const o = document.createElement('option'); o.value = u; o.textContent = u; s.append(o); }
  s.value = items.includes(keep) ? keep : (items.includes(want) ? want : items[0] || '');
}
async function readFileText(input) {
  const f = input.files && input.files[0];
  if (!f) return null;
  const bytes = new Uint8Array(await f.arrayBuffer());   // SHA-256 of the file as uploaded (KK-75)
  return { text: new TextDecoder().decode(bytes), name: f.name, size: f.size, modified: f.lastModified, sha256: await sha256(bytes) };
}
// Section 9 'Analysed data' (FSR-TN-PLT-11, KK-75)
const VERI_ENFAZLA = 5000;
async function dataTable(kind, products) {
  const r = await callR('.an_tablo(tur, urunler, enfazla)', { tur: kind, urunler: products.join('\n'), enfazla: VERI_ENFAZLA });
  if (!r.ok) return { n: 0, cols: null, error: r.message };
  return { n: r.n, cols: r.tablo ? Object.fromEntries(Object.entries(r.tablo).map(([k, v]) => [k, arr(v).map(String)])) : null };
}
function dataSection(kind, D, include) {
  const tb = D.tablo, ex = !D.data.sha256, used = kind === 'pbe' ? [D.form.test, D.form.ref] : [D.form.test, D.form.ref, ...D.form.lotlar];
  const rows = [[t('rp_data_src'), D.data.src],
    [t('rp_data_sha'), ex ? t('rp_data_example').replace('{v}', pkgVersion) : D.data.sha256],
    [t('rp_data_products'), used.join(', ')]];
  if (tb && tb.cols) {
    const c = tb.cols, uniq = (a) => new Set(a).size;
    for (const p of used) {
      if (kind === 'pbe') { const ix = c.urun.map((u, i) => (u === p ? i : -1)).filter((i) => i >= 0);
        rows.push([p, t('rp_data_struct_pbe').replace('{s}', uniq(ix.map((i) => c.parti[i]))).replace('{u}', uniq(ix.map((i) => c.parti[i] + '\u0001' + c.kap[i])))
          .replace('{m}', uniq(ix.map((i) => c.asama[i]))).replace('{n}', fmtInt(ix.length))]);
      } else { const ix = c.Product.map((u, i) => (u === p ? i : -1)).filter((i) => i >= 0);
        rows.push([p, t('rp_data_struct_dis').replace('{u}', uniq(ix.map((i) => c.Unit[i]))).replace('{p}', uniq(ix.map((i) => c.Time[i]))).replace('{n}', fmtInt(ix.length))]); }
    }
  }
  rows.push([t('rp_data_rows'), fmtInt(tb ? tb.n : 0)]);
  const out = [TABLE([[t('rp_field'), t('rp_value')], ...rows])];
  if (!include) out.push(P(t('rp_data_omitted')));
  else if (!tb || !tb.cols) out.push(P(t('rp_data_large').replace('{n}', fmtInt(VERI_ENFAZLA))));
  else {
    const keys = kind === 'pbe' ? ['parti', 'kap', 'asama', 'urun', 'olcum'] : ['Product', 'Unit', 'Time', 'Diss'];
    const head = kind === 'pbe' ? ['rp_col_batch', 'rp_col_unit', 'rp_col_stage', 'rp_col_product', 'rp_col_value'].map(t)
      : ['rp_col_product', 'rp_col_unit', 'rp_col_time', 'rp_col_diss'].map(t);
    const body = tb.cols[keys[0]].map((_, i) => keys.map((k) => tb.cols[k][i]));
    out.push(H2(t('rp_data_table')), P(t('rp_data_table_note')), TABLE([head, ...body], kind === 'pbe' ? [4] : [2, 3], true));
  }
  return out;
}

// ---------------------------------------------------------------- PBE
const pbeData = { src: null, info: null };
async function loadPbe() {
  const k = $('#pbe_form [name=kaynak]').value;
  $('#pbe_file_wrap').hidden = k !== 'dosya';
  clearPbe(); showErrors('pbe', null); $('#pbe_data_info').textContent = '';
  let metin = '', ornek = '', src;
  if (k === 'dosya') {
    const f = await readFileText($('#pbe_form [name=dosya]'));
    if (!f) { $('#pbe_run').disabled = true; return; }
    metin = f.text; src = `${f.name} · ${fmtInt(f.size)} B`; pbeData.sha256 = f.sha256;
  } else { ornek = k; src = t('an_ex_psg'); pbeData.sha256 = null; }
  setStatus('pbe', webR ? 'an_st_reading' : 'st_loading');
  const r = await callR('.an_pbe_veri(metin, ornek)', { metin, ornek });
  if (!r.ok) { setStatus('pbe', 'an_st_data_error', 'bad'); showErrors('pbe', [t('an_data_error'), r.message]); $('#pbe_run').disabled = true; return; }
  const u = arr(r.urunler);
  fillSelect('#pbe_form [name=test]', u, 'TEST'); fillSelect('#pbe_form [name=ref]', u, 'REF');
  pbeData.src = src; pbeData.kaynak = k; pbeData.n = r.n;
  $('#pbe_data_info').textContent = `${src} · ${fmtInt(r.n)} ${t('an_rows')} · ${t('an_products')}: ${u.join(', ')}` + (pbeData.sha256 ? ` · SHA-256 ${pbeData.sha256}` : '');
  if (k === 'psg020929') $('#pbe_form [name=log_d]').checked = false;
  setStatus('pbe', 'an_st_data_ok', 'ok'); $('#pbe_run').disabled = false; reportState('pbe');
}
const pbeForm = () => { const f = $('#pbe_form'); const ema = f.yontem.value === 'ema';
  return { yontem: ema ? 'ema' : 'fda', test: f.test.value, ref: f.ref.value, log_d: f.log_d.checked, tek: ema ? false : f.tek.checked }; };
function pbeMethodVis() { const ema = $('#pbe_form [name=yontem]').value === 'ema'; $('#pbe_tek_wrap').hidden = ema; $('#pbe_ema_note').hidden = !ema; }
function clearPbe() { st.pbe = null; $('#pbe_result').hidden = true; reportState('pbe'); }
async function runPbe(ev) {
  ev.preventDefault();
  const c = pbeForm(); showErrors('pbe', null); $('#pbe_run').disabled = true; setStatus('pbe', 'st_running');
  const t0 = performance.now();
  const r = c.yontem === 'ema' ? await callR('.an_ema(test, ref, log_d)', { test: c.test, ref: c.ref, log_d: c.log_d })
                                : await callR('.an_pbe(test, ref, log_d, tek)', { test: c.test, ref: c.ref, log_d: c.log_d, tek: c.tek });
  $('#pbe_run').disabled = false;
  if (!r.ok) { setStatus('pbe', 'an_st_error', 'bad'); showErrors('pbe', [t('an_calc_error'), r.message]); clearPbe(); return; }
  const tablo = await dataTable('pbe', [c.test, c.ref]);
  st.pbe = { form: c, key: JSON.stringify(c), data: { ...pbeData }, hazir: r.hazir, sonuc: r.sonuc, ms: performance.now() - t0,
             started: new Date().toISOString(), r_version: rInfo.r_version, files: fileRows(), tablo };
  renderPbe(); setStatus('pbe', 'an_st_done', 'ok');
}
function pview(D) {
  const s = D.sonuc, h = D.hazir, yes = t('an_yes'), no = t('an_no');
  const pass = s.pass_fail === 'PASS';
  const main = [[t('an_crit'), t(s.criterion === 'Reference-scaled' ? 'an_crit_ref' : 'an_crit_const')],
    ['σT', N(s.Sigma_T, 4)], ['σR', N(s.Sigma_R, 4)], ['σT0', N(s.SigmaT0, 2)]];
  if (s.GMR !== undefined && s.GMR !== null && !Number.isNaN(s.GMR)) main.push(['GMR (T/R)', N(s.GMR, 4)]);
  main.push([t('an_onesided'), s.one_sided ? (s.one_sided_active ? t('an_os_active') : t('an_os_inactive')) : no],
    ['Eη', N(s.Eq_final, 6)], ['Uη', N(s.Uq_final, 6)], ['Hη (' + t('an_upper95') + ')', N(s.H_eta_final, 6)],
    [t('an_decision'), pass ? t('an_pbe_pass_s') : t('an_pbe_fail_s')]);
  const des = [[`TEST (${D.form.test})`, `${fmtInt(h.T.parti)} ${t('an_batch')} · ${fmtInt(h.T.toplam_kap)} ${t('an_cont')} · ${fmtInt(h.T.gozlem)} ${t('an_obs')}`],
    [`REF (${D.form.ref})`, `${fmtInt(h.R.parti)} ${t('an_batch')} · ${fmtInt(h.R.toplam_kap)} ${t('an_cont')} · ${fmtInt(h.R.gozlem)} ${t('an_obs')}`],
    [t('an_stages'), `${h.m} (${arr(h.asamalar).join(', ')})`], [t('an_scale'), h.olcek === 'ölçüm' ? t('an_scale_raw') : t('an_scale_ln')]];
  const sum = arr(h.oz_urun).map((u, i) => [u, String(arr(h.oz_asama)[i]), fmtInt(arr(h.oz_n)[i]), N(arr(h.oz_ort)[i], 4), N(arr(h.oz_sd)[i], 4)]);
  const sx = s.criterion === 'Reference-scaled' ? 's' : 'c';
  const comp = [['D', s.E_D, s.H_D, s.U_D], ['1', s.E1, s.H1, s.U1], ['2', s.E2, s.H2, s.U2], ['3', s['E3' + sx], s['H3' + sx], s['U3' + sx]], ['4', s['E4' + sx], s['H4' + sx], s['U4' + sx]]]
    .map(([k, e, hh, u]) => [k, N(e, 6), N(hh, 6), N(u, 6)]);
  return { verdict: pass ? t('an_pbe_pass') : t('an_pbe_fail'), pass, main, des, sum, sumHead: [t('an_product'), t('an_stage'), 'n', t('an_mean'), 'SD'],
           comp, compHead: [t('an_component'), 'E', 'H', 'U'], warnings: arr(h.uyarilar),
           source: `${t('an_src_live')} · webR ${WEBR_VERSION} · ${D.r_version} · ${D.data.src}` };
}
// EMA view (FSR-TN-PLT-08 E-K2, E-K3): three candidate paths, decision line = path (b)
const EMA_PATHS = ['a', 'b', 'c'];
const isEma = (D) => !!D && D.form.yontem === 'ema';
function eview(D) {
  const s = D.sonuc, h = D.hazir, gec = arr(s.gecti), lim = arr(s.sinir);
  const dec = (v) => (v === true ? t('an_pbe_pass_s') : v === false ? t('an_pbe_fail_s') : '—');
  const karar = s.karar === true ? true : s.karar === false ? false : null;
  const uyum = s.uyum === true ? t('an_ema_agree') : s.uyum === false ? t('an_ema_disagree') : '—';
  const main = [[t('an_method'), t('an_ema_method')], [t('an_ema_level'), lang === 'tr' ? '%' + num(100 * s.duzey, 0, lang) : num(100 * s.duzey, 0, lang) + '%'],
    [t('an_ema_limits'), `${N(lim[0], 2)} – ${N(lim[1], 2)}`], ['GMR (T/R)', N(arr(s.gmr)[0], 4)],
    [t('an_ema_dpath'), t('an_ema_p_b')], [t('an_decision'), dec(karar)], [t('an_ema_paths_agree'), uyum]];
  const paths = EMA_PATHS.map((k, i) => [t('an_ema_p_' + k) + (k === 'b' ? ' · ' + t('an_ema_dline') : ''), N(arr(s.gmr)[i], 4), N(arr(s.alt)[i], 4), N(arr(s.ust)[i], 4),
    N(arr(s.se)[i], 4), N(arr(s.sd)[i], 2), dec(gec[i])]);
  const des = [[`TEST (${D.form.test})`, `${fmtInt(s.T.l)} ${t('an_batch')} × ${fmtInt(s.T.n)} ${t('an_cont')} · ${fmtInt(h.T.gozlem)} ${t('an_obs')}`],
    [`REF (${D.form.ref})`, `${fmtInt(s.R.l)} ${t('an_batch')} × ${fmtInt(s.R.n)} ${t('an_cont')} · ${fmtInt(h.R.gozlem)} ${t('an_obs')}`],
    [t('an_stages'), `${h.m} (${arr(h.asamalar).join(', ')})`], [t('an_scale'), h.olcek === 'ölçüm' ? t('an_scale_raw') : t('an_scale_ln')]];
  const sum = arr(h.oz_urun).map((u, i) => [u, String(arr(h.oz_asama)[i]), fmtInt(arr(h.oz_n)[i]), N(arr(h.oz_ort)[i], 4), N(arr(h.oz_sd)[i], 4)]);
  return { verdict: karar === true ? t('an_ema_pass') : karar === false ? t('an_ema_fail') : t('an_ema_none'), pass: karar === true, main, des, sum,
           sumHead: [t('an_product'), t('an_stage'), 'n', t('an_mean'), 'SD'], paths,
           pathsHead: [t('an_ema_path'), 'GMR', t('an_ema_lo'), t('an_ema_hi'), t('an_ema_se'), t('an_ema_df'), t('an_decision')],
           note: t('an_ema_label'), warnings: arr(h.uyarilar),
           source: `${t('an_src_live')} · webR ${WEBR_VERSION} · ${D.r_version} · ${D.data.src}` };
}
function renderPbe() {
  if (isEma(st.pbe)) return renderEma();
  $('#pbe_fda_only').hidden = false; $('#pbe_ema_only').hidden = true;
  const D = st.pbe, V = pview(D);
  $('#pbe_verdict').textContent = V.verdict; $('#pbe_verdict').className = 'verdict ' + (V.pass ? 'yes' : 'no');
  fillTable('#pbe_main', V.main); fillTable('#pbe_design', V.des); fillTable('#pbe_sum', V.sum, V.sumHead); fillTable('#pbe_comp', V.comp, V.compHead);
  warnList('#pbe_warn', V.warnings); $('#pbe_result').hidden = false; reportState('pbe');
}
function renderEma() {
  const D = st.pbe, V = eview(D);
  $('#pbe_fda_only').hidden = true; $('#pbe_ema_only').hidden = false;
  $('#pbe_verdict').textContent = V.verdict; $('#pbe_verdict').className = 'verdict ' + (V.pass ? 'yes' : 'no');
  fillTable('#pbe_main', V.main); fillTable('#pbe_ema_paths', V.paths, V.pathsHead);
  $('#pbe_ema_paths tbody tr:nth-child(2)').classList.add('dline');
  $('#pbe_ema_label').textContent = V.note;
  fillTable('#pbe_design', V.des); fillTable('#pbe_sum', V.sum, V.sumHead);
  warnList('#pbe_warn', V.warnings); $('#pbe_result').hidden = false; reportState('pbe');
}

// ---------------------------------------------------------------- dissolution
const disData = { src: null };
async function loadDis() {
  const k = $('#dis_form [name=kaynak]').value;
  $('#dis_file_wrap').hidden = k !== 'dosya';
  clearDis(); showErrors('dis', null); $('#dis_data_info').textContent = '';
  let metin = '', ornek = '', src;
  if (k === 'dosya') {
    const f = await readFileText($('#dis_form [name=dosya]'));
    if (!f) { $('#dis_run').disabled = true; return; }
    metin = f.text; src = `${f.name} · ${fmtInt(f.size)} B`; disData.sha256 = f.sha256;
  } else { ornek = k; src = t(k === 'tsong1996' ? 'an_ex_tsong' : 'an_ex_noce'); disData.sha256 = null; }
  setStatus('dis', webR ? 'an_st_reading' : 'st_loading');
  const r = await callR('.an_dis_veri(metin, ornek)', { metin, ornek });
  if (!r.ok) { setStatus('dis', 'an_st_data_error', 'bad'); showErrors('dis', [t('an_data_error'), r.message]); $('#dis_run').disabled = true; return; }
  const u = arr(r.urunler);
  fillSelect('#dis_form [name=test]', u, k === 'noce2020' ? 'Urun1' : 'TEST');
  fillSelect('#dis_form [name=ref]', u, k === 'noce2020' ? 'Urun2' : 'REF');
  disData.src = src; disData.kaynak = k; disData.urunler = u; disData.n = r.n;
  lotBoxes(k === 'tsong1996' ? ['STD1', 'STD2'] : []);
  $('#dis_data_info').textContent = `${src} · ${fmtInt(r.n)} ${t('an_rows')} · ${t('an_products')}: ${u.join(', ')}` + (disData.sha256 ? ` · SHA-256 ${disData.sha256}` : '');
  setStatus('dis', 'an_st_data_ok', 'ok'); $('#dis_run').disabled = false; reportState('dis');
}
function lotBoxes(checked) {
  const box = $('#dis_lots .checks'); box.innerHTML = '';
  const test = $('#dis_form [name=test]').value;
  for (const u of (disData.urunler || []).filter((x) => x !== test)) {
    const l = document.createElement('label'); const i = document.createElement('input'); i.type = 'checkbox'; i.value = u; i.name = 'lot';
    i.checked = checked.includes(u); l.append(i, document.createTextNode(u)); box.append(l);
  }
}
function methodVis() {
  const y = $('#dis_form [name=yontem]').value;
  for (const m of ['f2', 'msd', 'wb']) $('#dis_form .sub-' + m).hidden = (m === 'wb' ? 'weibull' : m) !== y;
  $('#dis_method_note').textContent = t('an_note_' + y);
}
function disForm() {
  const f = $('#dis_form'), y = f.yontem.value, nm = (v) => { const s = String(v).trim().replace(',', '.'); return s === '' ? null : Number(s); };
  const ayar = y === 'f2' ? { perspektif: f.perspektif.value, gatipi: f.gatipi.value, seed: nm(f.seed.value), ...(nm(f.B.value) ? { B: nm(f.B.value) } : {}) }
    : y === 'msd' ? { sinir: f.sinir.value, Dg: nm(f.Dg.value), kesme: f.kesme.value }
      : { param: f.param.value, bolge: f.bolge.value, k: nm(f.k.value), Dg: nm(f.wDg.value) };
  return { test: f.test.value, ref: f.ref.value, birim: f.birim.value, yontem: y,
           lotlar: [...f.querySelectorAll('input[name=lot]:checked')].map((i) => i.value), ayar };
}
function clearDis() { st.dis = null; $('#dis_result').hidden = true; reportState('dis'); }
async function runDis(ev) {
  ev.preventDefault();
  const c = disForm(); showErrors('dis', null); $('#dis_run').disabled = true; setStatus('dis', 'st_running');
  const t0 = performance.now();
  const ak = Object.keys(c.ayar).filter((k) => c.ayar[k] !== null && !Number.isNaN(c.ayar[k]));
  const r = await callR('.an_dis(test, ref, lotlar, birim, yontem, ayar_k, ayar_v)', { test: c.test, ref: c.ref, birim: c.birim, yontem: c.yontem,
    lotlar: c.lotlar.join('\n'), ayar_k: ak.join('\n'), ayar_v: ak.map((k) => String(c.ayar[k])).join('\n') });
  $('#dis_run').disabled = false;
  if (!r.ok) { setStatus('dis', 'an_st_error', 'bad'); showErrors('dis', [t('an_calc_error'), r.message]); clearDis(); return; }
  const tablo = await dataTable('dis', [c.test, c.ref, ...c.lotlar]);
  st.dis = { form: c, key: JSON.stringify(c), data: { ...disData }, hazir: r.hazir, sonuc: r.sonuc, ms: performance.now() - t0,
             started: new Date().toISOString(), r_version: rInfo.r_version, files: fileRows(), tablo };
  renderDis(); setStatus('dis', 'an_st_done', 'ok');
}
const yn = (b) => (b ? t('an_sim_yes') : t('an_sim_no'));
function dview(D) {
  const s = D.sonuc, h = D.hazir, y = D.form.yontem, u = D.form.birim === 'saat' ? t('an_hour_s') : t('an_min_s');
  let verdict, yes, main = [], tables = [];
  const zt = arr(h.zaman);
  tables.push({ title: t('an_profiles'), head: [`${t('an_time')} (${u})`, `${t('an_mean')} T`, 'SD T', 'CV T (%)', `${t('an_mean')} R`, 'SD R', 'CV R (%)'],
    rows: zt.map((z, i) => [N(z, 0), N(arr(h.ortT)[i], 2), N(arr(h.sdT)[i], 2), N(arr(h.cvT)[i], 1), N(arr(h.ortR)[i], 2), N(arr(h.sdR)[i], 2), N(arr(h.cvR)[i], 1)]) });
  main.push([t('an_products_tr'), `${D.form.test} / ${D.form.ref} (n = ${h.nT} / ${h.nR})`]);
  if (arr(h.lotlar).length) main.push([t('an_lots'), arr(h.lotlar).join(', ')]);
  if (y === 'f2') {
    const k = s.karar; yes = k === 'BENZER';
    verdict = k === 'BENZER' ? t('an_f2_sim') : k === 'BENZER DEĞİL' ? t('an_f2_nosim') : t('an_f2_border');
    main.push([t('an_persp'), s.perspektif], [t('an_estimator'), s.tahminci], ['f2', N(s.f2, 2)], ['E(f2)', N(s.Ef2, 2)], ['bc-f2', N(s.bcf2, 2)],
      [`${t('an_ci90')} (${s.ga_tipi})`, `${N(s.alt, 2)} – ${N(s.ust, 2)}`], [t('an_mcse_lower'), N(s.mcse, 2)], [t('an_boot_mean'), N(s.ortalama, 2)],
      ...(s.perspektif === 'EMA' ? [[t('an_f2_int'), String(s.tamsayi)]] : []),
      ['B · seed', `${fmtInt(s.B)} · ${s.seed}`], ['RNG', s.rng], [t('an_trunc'), `${s.kesme} (${s.kmod})`], [t('an_points'), arr(s.zamanlar).map((z) => N(z, 0)).join(', ')],
      [t('an_cvrule'), `${s.cvkural} · ${s.oneri}`], [t('an_seed_sens'), s.seed_duyarli ? t('an_yes') : t('an_no')]);
    tables.push({ title: t('an_cv_table'), head: [`${t('an_time')} (${u})`, 'CV T (%)', 'CV R (%)', t('an_cv_limit'), t('an_cv_violation')],
      rows: arr(s.cv_zaman).map((z, i) => [N(z, 0), N(arr(s.cv_T)[i], 1), N(arr(s.cv_R)[i], 1), N(arr(s.cv_sinir)[i], 0), arr(s.cv_ihlal)[i] ? t('an_yes') : t('an_no')]) });
  } else if (y === 'msd') {
    yes = !!s.benzer_msd; verdict = yn(yes);
    main.push(['D_M', N(s.DM, 4)], ['T²', N(s.T2, 4)], [t('an_ci90'), `${N(s.DM_l, 4)} – ${N(s.DM_u, 4)}`], ['R_D', N(s.RD, 4)], [t('an_limit'), s.aciklama],
      [t('an_l3'), yn(!!s.benzer_L3) + ` (D_g = ${N(s.Dg, 2)})`], [t('an_points'), arr(s.zamanlar).join(', ')]);
    tables.push({ title: t('an_l3_table'), head: [`${t('an_time')} (${u})`, t('an_diff'), t('an_lo'), t('an_hi'), t('an_extreme'), t('an_exceeds')],
      rows: arr(s.l_zaman).map((z, i) => [String(z), N(arr(s.l_fark)[i], 2), N(arr(s.l_alt)[i], 2), N(arr(s.l_ust)[i], 2), N(arr(s.l_uc)[i], 2), arr(s.l_asim)[i] ? t('an_yes') : t('an_no')]) });
    if (arr(s.lot1).length) tables.push({ title: t('an_lot_table'), head: [t('an_lot') + ' 1', t('an_lot') + ' 2', t('an_lot_diff'), 'D_M (R-R)'],
      rows: arr(s.lot1).map((a, i) => [a, arr(s.lot2)[i], N(arr(s.lot_fark)[i], 2), N(arr(s.lot_dm)[i], 4)]) });
  } else {
    yes = !!s.benzer; verdict = yn(yes);
    main.push([t('an_param'), s.param], [t('an_region'), s.aciklama], ['D_M', N(s.DM, 4)], [t('an_ci90'), `${N(s.DM_l, 4)} – ${N(s.DM_u, 4)}`],
      ['R² min (T / R)', `${N(s.R2T, 4)} / ${N(s.R2R, 4)}`]);
    tables.push({ title: t('an_param_diff'), head: [t('an_param'), t('an_diff')], rows: arr(s.p_ad).map((p, i) => [p, N(arr(s.fark)[i], 4)]) });
    const bc = arr(s.bolge_ad), bv = arr(s.bolge);
    const nr = bv.length ? arr(bv[0]).length : 0;
    tables.push({ title: t('an_region_table'), head: bc, rows: Array.from({ length: nr }, (_, i) => bv.map((col) => { const v = arr(col)[i]; return typeof v === 'number' ? N(v, 4) : String(v); })) });
    const ua = arr(s.u_ad), uv = arr(s.uyd), nu = uv.length ? arr(uv[0]).length : 0;
    tables.push({ title: t('an_fit_table'), head: ua, rows: Array.from({ length: nu }, (_, i) => uv.map((col) => { const v = arr(col)[i]; return typeof v === 'number' ? N(v, 4) : String(v); })) });
  }
  return { verdict, yes, main, tables, warnings: [...arr(s.notlar), ...arr(s.regulatif)],
           source: `${t('an_src_live')} · webR ${WEBR_VERSION} · ${D.r_version} · ${D.data.src}` };
}
function profileChart(host, h) {
  host.innerHTML = '';
  const z = arr(h.zaman), a = arr(h.ortT), b = arr(h.ortR); if (!z.length) return;
  const NS = 'http://www.w3.org/2000/svg', W = 520, H = 220, L = 40, R = 12, Tp = 12, B = 30;
  const xmax = Math.max(...z), x = (v) => L + (W - L - R) * v / xmax, y = (v) => Tp + (H - Tp - B) * (1 - v / 100);
  const el = (n, at, tx) => { const e = document.createElementNS(NS, n); for (const [k, v] of Object.entries(at)) e.setAttribute(k, v); if (tx !== undefined) e.textContent = tx; return e; };
  const svg = el('svg', { viewBox: `0 0 ${W} ${H}`, class: 'chart', role: 'img', 'aria-label': t('an_chart') });
  for (const g of [0, 25, 50, 75, 100]) { svg.append(el('line', { x1: L, x2: W - R, y1: y(g), y2: y(g), class: 'grid' })); svg.append(el('text', { x: L - 4, y: y(g) + 4, 'text-anchor': 'end', class: 'tick' }, String(g))); }
  for (const v of z) svg.append(el('text', { x: x(v), y: H - B + 14, 'text-anchor': 'middle', class: 'tick' }, N(v, 0)));
  for (const [s, c] of [[a, 's-t'], [b, 's-r']]) {
    svg.append(el('polyline', { points: z.map((v, i) => `${x(v)},${y(s[i])}`).join(' '), fill: 'none', class: c, 'stroke-width': 2 }));
    s.forEach((v, i) => svg.append(el('circle', { cx: x(z[i]), cy: y(v), r: 3, class: c, fill: 'none', 'stroke-width': 2, 'data-value': String(v) })));
  }
  [['s-t', `T (${st.dis.form.test})`], ['s-r', `R (${st.dis.form.ref})`]].forEach(([c, lab], i) => {
    const lx = L + 12 + i * 150, ly = H - B - 14;
    svg.append(el('line', { x1: lx, x2: lx + 18, y1: ly, y2: ly, class: c, 'stroke-width': 2 }));
    svg.append(el('text', { x: lx + 24, y: ly + 4, class: 'legend' }, lab));
  });
  svg.append(el('text', { x: 4, y: Tp + 4, class: 'tick' }, '%'));
  host.append(svg);
}
function renderDis() {
  const D = st.dis, V = dview(D);
  $('#dis_verdict').textContent = V.verdict; $('#dis_verdict').className = 'verdict ' + (V.yes ? 'yes' : 'no');
  fillTable('#dis_main', V.main); warnList('#dis_warn', V.warnings); profileChart($('#dis_chart'), D.hazir);
  const host = $('#dis_tables'); host.innerHTML = '';
  for (const tb of V.tables) {
    const h = document.createElement('h2'); h.textContent = tb.title; host.append(h);
    const w = document.createElement('div'); w.className = 'tablewrap'; const tab = document.createElement('table'); tab.innerHTML = '<thead></thead><tbody></tbody>';
    tab.id = 'dt_' + host.children.length; w.append(tab); host.append(w); fillTable('#' + tab.id, tb.rows, tb.head);
  }
  $('#dis_result').hidden = false; reportState('dis');
}

// ---------------------------------------------------------------- report, record, button state
function fileRows() { return [...files.map(({ file, pinned, sha256: s, status }) => ({ file, pinned, sha256: s, status })), { file: KOPRU.file, pinned: false, sha256: kopru && kopru.sha256, status: kopru && kopru.status }]; }
function common(kind, D) {
  return { kind, t, lang, created: new Date().toISOString().replace('T', ' ').slice(0, 19) + ' UTC',
    header: `CNK-FarmaStatR · ${t('rp_title_' + kind)} · CNKfarmastatr ${pkgVersion}`, disclaimer_tr: T.tr.disclaimer, disclaimer_en: T.en.disclaimer,
    identity: [[t('an_data'), D.data.src], [t('rp_started'), D.started]],
    versions: [[t('rp_pkg'), pkgVersion], ['webR', WEBR_VERSION], ['R', D.r_version]],
    files: D.files.map((e) => [e.file, e.pinned ? t('an_yes') : t('recorded'), e.sha256 || '', e.status === 'ok' ? '✓' : '✗']),
    link: null,   // no Section 9 in analysis reports (KK-71)
    sources: [[t('rp_src_' + kind + '_k1'), t('rp_src_' + kind + '_1')], [t('rp_src_' + kind + '_k2'), t('rp_src_' + kind + '_2')], [t('rp_src_' + kind + '_k3'), t('rp_src_' + kind + '_3')]] };
}
function reportPbe() {
  const D = st.pbe, V = pview(D), R = common('pbe', D);
  R.params = [[t('an_test'), D.form.test], [t('an_ref'), D.form.ref], [t('an_log'), D.form.log_d ? t('an_yes') : t('an_no')], [t('an_onesided'), D.form.tek ? t('an_yes') : t('an_no')]];
  R.source = V.source;
  R.result = [P(V.verdict, { b: true }), TABLE([[t('rp_field'), t('rp_value')], ...V.main]), H2(t('an_design')), TABLE([[t('rp_field'), t('rp_value')], ...V.des]),
    H2(t('an_pbe_summary')), TABLE([V.sumHead, ...V.sum], [2, 3, 4]), H2(t('an_pbe_comp')), TABLE([V.compHead, ...V.comp], [1, 2, 3])];
  R.warnings = V.warnings;
  R.veri = dataSection('pbe', D, withData('pbe'));
  return R;
}
function reportEma() {
  const D = st.pbe, V = eview(D), R = common('ema', D);
  R.params = [[t('an_method'), t('an_ema_method')], [t('an_test'), D.form.test], [t('an_ref'), D.form.ref], [t('an_log'), D.form.log_d ? t('an_yes') : t('an_no')]];
  R.source = V.source;
  R.result = [P(V.verdict, { b: true }), TABLE([[t('rp_field'), t('rp_value')], ...V.main]), H2(t('an_ema_paths')), TABLE([V.pathsHead, ...V.paths], [1, 2, 3, 4, 5]),
    P(V.note), H2(t('an_design')), TABLE([[t('rp_field'), t('rp_value')], ...V.des]), H2(t('an_pbe_summary')), TABLE([V.sumHead, ...V.sum], [2, 3, 4])];
  R.warnings = V.warnings;
  R.veri = dataSection('pbe', D, withData('pbe'));
  return R;
}
function reportDis() {
  const D = st.dis, V = dview(D), R = common('dis', D), f = D.form;
  R.params = [[t('an_test'), f.test], [t('an_ref'), f.ref], [t('an_lots'), f.lotlar.join(', ') || '—'], [t('an_unit'), t(f.birim === 'saat' ? 'an_hour' : 'an_min')],
    [t('an_method'), t('an_m_' + (f.yontem === 'weibull' ? 'wb' : f.yontem))], ...Object.entries(f.ayar).map(([k, v]) => [k, v === null ? '—' : decTxt(typeof v === 'number' ? numExact(v) : v)])];
  R.source = V.source;
  R.result = [P(V.verdict, { b: true }), TABLE([[t('rp_field'), t('rp_value')], ...V.main])];
  for (const tb of V.tables) R.result.push(H2(tb.title), TABLE([tb.head, ...tb.rows], tb.head.map((_, i) => i).filter((i) => i > 0), true));
  R.warnings = V.warnings;
  R.veri = dataSection('dis', D, withData('dis'));
  return R;
}
const withData = (kind) => !!($(`#${kind}_with_data`) && $(`#${kind}_with_data`).checked);   // default unticked (KK-75)
function makeReport(kind) {
  if (!st[kind]) return null;
  const t0 = performance.now();
  const bytes = buildReport(kind === 'pbe' ? (isEma(st.pbe) ? reportEma() : reportPbe()) : reportDis());
  const r = { bytes, name: `farmastatr_rapor_${kind === 'pbe' && isEma(st.pbe) ? 'ema' : kind}_${stamp()}.docx`, ms: performance.now() - t0 };
  st.report = r; return r;
}
st.makeReport = makeReport;
st.view = (kind) => (kind === 'pbe' ? (isEma(st.pbe) ? eview(st.pbe) : pview(st.pbe)) : dview(st.dis));
function formKey(kind) { return kind === 'pbe' ? JSON.stringify(pbeForm()) : JSON.stringify(disForm()); }
function reportState(kind) {
  const ok = !!st[kind] && st[kind].key === formKey(kind) && !$(`#${kind}_run`).disabled;
  $(`#${kind}_report`).disabled = !ok; $(`#${kind}_json`).disabled = !ok;
}
function downloadJson(kind) {
  const D = st[kind]; if (!D) return;
  const ema = kind === 'pbe' && isEma(D);
  const rec = { platform: 'CNK-FarmaStatR', document: ema ? 'FSR-TN-PLT-08' : 'FSR-TN-PLT-06', kind: ema ? 'ema' : kind, disclaimer_tr: T.tr.disclaimer, disclaimer_en: T.en.disclaimer,
    package_version: pkgVersion, webr_version: WEBR_VERSION, r_version: D.r_version, saved: new Date().toISOString(), started: D.started,
    data: D.data.src, data_sha256: D.data.sha256 || null, settings: D.form, files: D.files, design: D.hazir, result: D.sonuc };
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([JSON.stringify(rec, null, 1)], { type: 'application/json' }));
  a.download = `farmastatr_${ema ? 'ema' : kind}_${stamp()}.json`; a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}

// ---------------------------------------------------------------- tabs, language, boot
function showTab(k) {
  $('#main_pbe').hidden = k !== 'pbe'; $('#main_dis').hidden = k !== 'dis';
  $('#tab_pbe').classList.toggle('on', k === 'pbe'); $('#tab_dis').classList.toggle('on', k === 'dis');
  st.tab = k;
}
function applyLang() {
  document.documentElement.lang = lang;
  document.querySelectorAll('[data-i18n]').forEach((e) => { e.textContent = t(e.dataset.i18n); });
  methodVis(); pbeMethodVis(); renderEngine();
  for (const s of ['pbe', 'dis']) { const e = $(`#${s}_status`); if (e.dataset.key) setStatus(s, e.dataset.key, e.dataset.cls, e.dataset.arg); }
  if (st.pbe) renderPbe(); if (st.dis) renderDis();
}
async function boot() {
  T = await (await fetch('../app/ceviri.json', { cache: 'no-store' })).json();
  try { const d = new TextDecoder().decode(await fetchBytes('CNKfarmastatr/DESCRIPTION')); const m = d.match(/^Version:\s*(\S+)/m); if (m) pkgVersion = m[1]; } catch (e) { /* source */ }
  showTab(Q.get('tab') === 'dis' ? 'dis' : 'pbe');
  if (Q.get('yontem') === 'ema') $('#pbe_form [name=yontem]').value = 'ema';
  applyLang();
  setStatus('pbe', 'st_verifying'); setStatus('dis', 'st_verifying');
  files = await verifyFiles(ENGINE, PLATFORM);
  kopru = { file: KOPRU.file, status: 'ok' };
  try {
    kopru.bytes = await fetchBytes(KOPRU.path);
    if (TAMPER && TAMPER.file === KOPRU.file && TAMPER.pos < kopru.bytes.length) kopru.bytes[TAMPER.pos] ^= 0x01;
    kopru.sha256 = await sha256(kopru.bytes);
    if (kopru.sha256 !== KOPRU.expected) kopru.status = 'hash_mismatch';
  } catch (e) { kopru.status = 'fetch_failed'; }
  renderEngine();
  const blocked = files.some((e) => e.status !== 'ok') || kopru.status !== 'ok';
  if (blocked) {
    $('#engine_box').open = true;
    for (const s of ['pbe', 'dis']) { setStatus(s, 'st_blocked', 'bad'); showErrors(s, [t('st_blocked'), ...[...files, kopru].filter((e) => e.status !== 'ok').map((e) => `${e.file}: ${t(e.status)}`)]); }
    st.ready = true; st.blocked = true; return;
  }
  st.ready = true;
  await loadPbe(); await loadDis();
}

$('#lang').addEventListener('click', () => { lang = lang === 'tr' ? 'en' : 'tr'; applyLang(); });
$('#tab_pbe').addEventListener('click', () => showTab('pbe'));
$('#tab_dis').addEventListener('click', () => showTab('dis'));
$('#pbe_form [name=kaynak]').addEventListener('change', loadPbe);
$('#pbe_form [name=dosya]').addEventListener('change', loadPbe);
$('#pbe_form').addEventListener('submit', runPbe);
$('#pbe_form [name=yontem]').addEventListener('change', () => { pbeMethodVis(); clearPbe(); });
$('#pbe_form').addEventListener('input', () => setTimeout(() => reportState('pbe'), 0));
$('#dis_form [name=kaynak]').addEventListener('change', loadDis);
$('#dis_form [name=dosya]').addEventListener('change', loadDis);
$('#dis_form [name=test]').addEventListener('change', () => lotBoxes([...document.querySelectorAll('#dis_form input[name=lot]:checked')].map((i) => i.value)));
$('#dis_form [name=yontem]').addEventListener('change', methodVis);
$('#dis_form').addEventListener('submit', runDis);
$('#dis_form').addEventListener('input', () => setTimeout(() => reportState('dis'), 0));
$('#pbe_report').addEventListener('click', () => { const r = makeReport('pbe'); if (r) download(r.bytes, r.name); });
$('#dis_report').addEventListener('click', () => { const r = makeReport('dis'); if (r) download(r.bytes, r.name); });
$('#pbe_json').addEventListener('click', () => downloadJson('pbe'));
$('#dis_json').addEventListener('click', () => downloadJson('dis'));
boot().catch((err) => { for (const s of ['pbe', 'dis']) { setStatus(s, 'st_error', 'bad'); showErrors(s, [String(err && err.message || err)]); } });
