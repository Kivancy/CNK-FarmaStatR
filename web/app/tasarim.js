// CNK-FarmaStatR - P5 design selection screen (FSR-TN-PLT-05 v0.2 Section 3; KK-56, KK-57).
// Which number of batches l, units per batch n and life stages m reach the target power, and
// what is the type I error of that design? The page plans nothing and computes nothing: R plans
// the runs (platform_tasarim_plan), the engine runs them (platform_run_invitro) and R applies the
// selection rules A and B of FSR-TN-PBE-01 Table 11.3a/b (platform_tasarim_secim). In the
// precomputed tier the numbers come from the database R built; the rules are still applied by R.
// Research and education only; not a system validated for GxP environments.

import { rows } from './hazir.js';
import { pct, pp, num, numExact } from './bicim.js';

export const R_P5 = `
.p5 <- new.env()
.p5_plan <- function(pop, l, n, m, guc, n_sim, seed) {
  pl <- platform_tasarim_plan(pop, l, n, m, guc, n_sim, seed)
  .p5$pl <- pl; .p5$rows <- list()
  prob <- pl$problems
  hard <- prob[prob$code != "design_size", ]
  if (nrow(hard) > 0) return(list(ok = FALSE, kind = "input", field = hard$field, code = hard$code, message = hard$message))
  gd <- pl$plan$delta[pl$rol$kosu_no[pl$rol$rol == "guc"][1]]
  h <- platform_hipotez(pl$pop$sigma_R, pl$pop$rho, delta = gd)
  list(ok = TRUE, buyuk = nrow(prob) > 0, toplam = pl$toplam_hucre, notlar = as.character(pl$notlar),
       kosu_no = pl$plan$kosu_no, l = pl$plan$l, n = pl$plan$n, m = pl$plan$m,
       anahtar = pl$plan$anahtar, n_kosu = nrow(pl$plan), n_tasarim = nrow(unique(pl$rol[, c("l", "n", "m")])),
       yontem = h$yontem, sinif = h$sinif, metrik = h$metrik, gdelta = gd, gmr = exp(gd),
       rng = paste(RNGkind()[1:2], collapse = "/"))
}
.p5_run <- function(i) {
  pl <- .p5$pl
  r <- tryCatch(platform_run_invitro(platform_tasarim_params(pl$pop, pl$plan[i, ], pl$n_sim, pl$seed)),
                error = function(e) structure(list(message = conditionMessage(e)), class = "p5_err"))
  if (inherits(r, "p5_err")) return(list(ok = FALSE, kind = "engine", message = r$message))
  .p5$rows[[i]] <- r
  me <- c("fda", "ema_a", "ema_b", "ema_c")
  list(ok = TRUE, pass = unname(unlist(r[paste0(me, "_pass")])), mcse = unname(unlist(r[paste0(me, "_pass_mcse")])))
}
.p5_export <- function(pop, l, n, m, guc, hedef, n_sim, seed, pinned, ver) {
  r <- tryCatch(platform_export_tasarim(pop, l, n, m, guc, hedef, n_sim, seed,
                                        dosyalar = platform_tasarim_dosyalari("/home/web_user"),
                                        cekirdek_sha = pinned, paket_surumu = ver),
    farmastat_input_error = function(e) e, error = function(e) structure(list(message = conditionMessage(e)), class = "p5_err"))
  if (inherits(r, "farmastat_input_error"))
    return(list(ok = FALSE, kind = "input", field = r$problems$field, code = r$problems$code, message = r$problems$message))
  if (inherits(r, "p5_err")) return(list(ok = FALSE, kind = "engine", message = r$message))
  list(ok = TRUE, text = r)
}
.p5_secim <- function(sonuc, hedef) {
  if (is.null(sonuc)) sonuc <- do.call(rbind, .p5$rows) else sonuc <- as.data.frame(sonuc)
  s <- platform_tasarim_secim(.p5$pl, sonuc, hedef)
  list(tablo = as.list(s$tablo), secim = as.list(s$secim))
}`;

const METHODS = ['fda', 'ema_a', 'ema_b', 'ema_c'];
const TOTAL_MAX = 6e7;                         // display only; R enforces (P5-K6)
const $ = (s) => document.querySelector(s);
let A = null;                                  // api from app.js
let token = 0, last = null, partial = null, statusKey = null, statusCls = '', statusArg = '', errFn = null;
const state = window.__p5 = { status: null, layer: null, result: null, partial: null, plan: null };

const t = (k) => A.t(k);
const L = () => A.lang();
const fmtInt = (x) => x.toLocaleString(L() === 'tr' ? 'tr-TR' : 'en-US');

function setStatus(k, cls = '', arg = '') {
  statusKey = k; statusCls = cls; statusArg = arg; state.status = k;
  const e = $('#ts_status'); e.textContent = t(k) + (arg ? ' ' + arg : ''); e.className = cls;
}
function showErrors(fn) {
  const e = $('#ts_errors'); errFn = fn;
  if (!fn) { e.hidden = true; e.innerHTML = ''; return; }
  const lines = fn(); e.innerHTML = '<b></b><ul></ul>'; e.querySelector('b').textContent = lines[0];
  for (const l of lines.slice(1)) { const li = document.createElement('li'); li.textContent = l; e.querySelector('ul').append(li); }
  e.hidden = false;
}

// ---------------------------------------------------------------- form
const intList = (s) => String(s ?? '').trim().split(/[\s,;]+/).filter(Boolean).map(Number);
export function readTas() {
  const f = new FormData($('#ts_form'));
  const nm = (k) => { const s = String(f.get(k) ?? '').trim().replace(',', '.'); return s === '' ? NaN : Number(s); };
  const pop = {}; for (const k of ['sigma_R', 'rho', 'pB_T', 'pB_R', 'pL', 'q']) pop[k] = nm(k);
  return { pop, l: intList(f.get('ls')), n: intList(f.get('ns')), m: intList(f.get('ms')),
           guc: f.get('guc_choice'), custom: nm('guc_custom'), hedef: nm('hedef'), n_sim: nm('n_sim'), seed: nm('seed') };
}
export function setTas(o) {
  for (const [k, v] of Object.entries(o)) { const e = $(`#ts_form [name=${k}]`); if (e && v !== null && v !== undefined) e.value = String(v); }
  customVis();
}
function customVis() {
  const v = $('#ts_form [name=guc_choice]').value;
  $('#ts_custom_wrap').hidden = !['gmr', 'delta'].includes(v);
  $('#ts_custom_label').textContent = t(v === 'delta' ? 'custom_delta' : 'custom_gmr');
}
const rNum = (x) => (Number.isFinite(x) ? numExact(x) : 'NA_real_');
const rVec = (v) => 'c(' + v.map(rNum).join(', ') + ')';
function rGuc(c) {
  if (c.guc === 'gmr') return `list(gmr = ${rNum(c.custom)})`;
  if (c.guc === 'delta') return `list(delta = ${rNum(c.custom)})`;
  return `list(sinir = ${JSON.stringify(c.guc)})`;
}
export const formKey = (c) => JSON.stringify(c);

function info() {
  const c = readTas();
  const ok = (v) => v.length > 0 && v.every((x) => Number.isInteger(x) && x >= 1);
  const parts = [];
  if (ok(c.l) && ok(c.n) && ok(c.m)) {
    const nd = c.l.length * c.n.length * c.m.length;
    const sum = c.l.reduce((a, x) => a + x, 0) * c.n.reduce((a, x) => a + x, 0) * c.m.reduce((a, x) => a + x, 0);
    parts.push(`${t('ts_designs')}: ${fmtInt(nd)}`);
    if (Number.isInteger(c.n_sim) && c.n_sim >= 1) {
      const cells = 3 * sum * c.n_sim;        // display only (R counts shared runs once)
      parts.push(`${t('ts_cells')}: ~${fmtInt(cells)} (${t('ts_limit')} ${fmtInt(TOTAL_MAX)})`);
      parts.push(`${t('est_time')}: ~${num(A.kcell() * cells / 60, 1, L())} ${t('ts_min')}`);
    }
  }
  $('#ts_info').textContent = parts.join(' · ');
}

// ---------------------------------------------------------------- run
async function hesapla(ev, forceLive = false) {
  if (ev) ev.preventDefault();
  const c = readTas(); const my = ++token;
  showErrors(null); $('#ts_result').hidden = true; $('#ts_live').hidden = true; last = null; partial = null; state.result = null; state.partial = null;
  $('#ts_run').disabled = true; $('#ts_cancel').disabled = false; $('#ts_live').disabled = true;
  setStatus(A.webrReady() ? 'ts_st_plan' : 'st_loading');
  const end = () => { if (my === token) { $('#ts_run').disabled = false; $('#ts_cancel').disabled = true; $('#ts_live').disabled = false; } };
  try {
    const hedef = c.hedef / 100;
    const plan = await A.callR(`.p5_plan(list(sigma_R = ${rNum(c.pop.sigma_R)}, rho = ${rNum(c.pop.rho)}, pB_T = ${rNum(c.pop.pB_T)}, pB_R = ${rNum(c.pop.pB_R)}, pL = ${rNum(c.pop.pL)}, q = ${rNum(c.pop.q)}), ` +
      `${rVec(c.l)}, ${rVec(c.n)}, ${rVec(c.m)}, ${rGuc(c)}, ${rNum(c.n_sim)}, ${rNum(c.seed)})`);
    if (my !== token) return;
    if (!plan.ok) {
      setStatus('ts_st_error', 'bad'); end();
      const f = [].concat(plan.field);
      showErrors(() => [t('err_input'), ...[].concat(plan.code).map((k, i) => A.codeMsg(k, f[i]))]);
      return;
    }
    if (!(hedef > 0 && hedef < 1)) { setStatus('ts_st_error', 'bad'); end(); showErrors(() => [t('err_input'), t('ts_err_hedef')]); return; }
    const P = { ...plan, kosu_no: [].concat(plan.kosu_no), l: [].concat(plan.l), n: [].concat(plan.n), m: [].concat(plan.m),
                anahtar: [].concat(plan.anahtar), notlar: [].concat(plan.notlar ?? []), yontem: [].concat(plan.yontem),
                sinif: [].concat(plan.sinif), metrik: [].concat(plan.metrik) };
    state.plan = P;
    // tier 2: every run is the main run of a stored scenario with the same n_sim and seed (P5-K7)
    const hz = A.hz();
    let hz_rows = null;
    if (hz && hz.ok && !forceLive) {
      hz_rows = [];
      for (const k of P.anahtar) {
        const sk = k.replace(/\|n_sim=.*$/, ''); const no = hz.index.get(sk);
        if (no === undefined) { hz_rows = null; break; }
        const main = rows(hz.db, "SELECT k.* FROM kosu k WHERE k.tur = 'tek' AND k.kosu_id IN (SELECT DISTINCT kosu_id FROM sonuc WHERE senaryo_no = ?)", [no])[0];
        if (!main || main.n_sim !== c.n_sim || main.seed !== c.seed) { hz_rows = null; break; }
        const son = rows(hz.db, "SELECT yontem_id, tahmin, mcse FROM sonuc WHERE senaryo_no = ? AND kosu_id = ? AND olcut_id = 'pass'", [no, main.kosu_id]);
        const by = Object.fromEntries(son.map((r) => [r.yontem_id, r]));
        if (!METHODS.every((me) => by[me])) { hz_rows = null; break; }
        hz_rows.push({ no, kosu: main, pass: METHODS.map((me) => by[me].tahmin), mcse: METHODS.map((me) => by[me].mcse) });
      }
    }
    let sonuc, source, runs = null;
    const t0 = performance.now();
    if (hz_rows) {
      source = 'hazir'; state.layer = 'hazir';
      sonuc = {}; METHODS.forEach((me, j) => { sonuc[me + '_pass'] = hz_rows.map((r) => r.pass[j]); sonuc[me + '_pass_mcse'] = hz_rows.map((r) => r.mcse[j]); });
      runs = [...new Set(hz_rows.map((r) => r.kosu.kosu_id))].map((id) => hz_rows.find((r) => r.kosu.kosu_id === id).kosu);
    } else if (plan.buyuk) {
      state.layer = 'betik'; setStatus('ts_st_betik', 'bad'); end();
      showErrors(() => [t('ts_layer_betik'), `${t('ts_cells')}: ${fmtInt(plan.toplam)} > ${fmtInt(TOTAL_MAX)}`]);
      return;
    } else {
      source = 'canli'; state.layer = 'canli';
      partial = { done: 0, total: P.n_kosu, pass: [], mcse: [] }; state.partial = partial;
      for (let i = 1; i <= P.n_kosu; i++) {
        setStatus('ts_st_running', '', `${i}/${P.n_kosu}`);
        const r = await A.callR(`.p5_run(${i})`);
        if (my !== token) return;
        if (!r.ok) { setStatus('ts_st_error', 'bad'); end(); showErrors(() => [t('err_engine'), r.message]); return; }
        partial.pass.push([].concat(r.pass)); partial.mcse.push([].concat(r.mcse)); partial.done = i;
      }
      sonuc = null;
    }
    const s = sonuc ? await A.callR('.p5_secim(sonuc, hedef)', { sonuc, hedef }) : await A.callR('.p5_secim(NULL, hedef)', { hedef });
    if (my !== token) return;
    const tab = s.tablo, sec = s.secim;
    const arr = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, [].concat(v)]));
    last = {
      source, c, hedef, plan: P, tablo: arr(tab), secim: arr(sec), runs,
      elapsed_ms: Math.round(performance.now() - t0), started: new Date().toISOString(),
      r_version: A.rVersion(), files: A.files()
    };
    if (source === 'canli' && P.n_kosu) A.updateKcell(last.elapsed_ms / 1000 / (plan.toplam || 1));
    partial = null; state.partial = null; state.result = last;
    render();
    setStatus(source === 'hazir' ? 'ts_st_hazir' : 'ts_st_done', 'ok');
    $('#ts_live').hidden = source !== 'hazir';
  } catch (err) {
    if (my !== token) return;
    setStatus('ts_st_error', 'bad'); showErrors(() => [t('err_engine'), String(err && err.message || err)]);
  }
  end();
}
async function iptal() {
  token++;
  $('#ts_cancel').disabled = true;
  await A.cancelWebR();
  $('#ts_run').disabled = false;
  setStatus('ts_st_cancelled', 'bad');
  if (partial && partial.done > 0) renderPartial();
}

// ---------------------------------------------------------------- tier 3: design script (T-3)
async function betik() {
  const c = readTas();
  $('#ts_script').disabled = true; setStatus('st_exporting'); showErrors(null);
  let out;
  try {
    const pinned = 'c(' + A.files().filter((e) => e.pinned).map((e) => `${JSON.stringify(e.file)} = ${JSON.stringify(e.sha256)}`).join(', ') + ')';
    out = await A.callR(`.p5_export(list(sigma_R = ${rNum(c.pop.sigma_R)}, rho = ${rNum(c.pop.rho)}, pB_T = ${rNum(c.pop.pB_T)}, pB_R = ${rNum(c.pop.pB_R)}, pL = ${rNum(c.pop.pL)}, q = ${rNum(c.pop.q)}), ` +
      `${rVec(c.l)}, ${rVec(c.n)}, ${rVec(c.m)}, ${rGuc(c)}, ${rNum(c.hedef / 100)}, ${rNum(c.n_sim)}, ${rNum(c.seed)}, ${pinned}, ${JSON.stringify(A.pkgVersion())})`);
  } catch (e) { out = { ok: false, kind: 'engine', message: String(e.message || e) }; }
  $('#ts_script').disabled = false;
  if (!out.ok) {
    setStatus('st_export_error', 'bad');
    if (out.kind === 'input') { const f = [].concat(out.field); showErrors(() => [t('err_input'), ...[].concat(out.code).map((k, i) => A.codeMsg(k, f[i]))]); }
    else showErrors(() => [t('err_engine'), out.message]);
    return;
  }
  state.script = out.text;
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([out.text], { type: 'text/plain;charset=utf-8' }));
  a.download = `farmastatr_tasarim_${new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)}.R`;
  a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  setStatus('st_exported', 'ok');
}

// ---------------------------------------------------------------- display
const td = (txt, cls) => { const e = document.createElement('td'); e.textContent = txt; if (cls) e.className = cls; return e; };
const th = (txt) => { const e = document.createElement('th'); e.textContent = txt; return e; };
function k38sym(lab) { return lab === 'nominali_asiyor' ? '!' : lab === 'ayirt_edilemiyor' ? '†' : ''; }

function render() {
  const D = last; if (!D) return;
  $('#ts_result').hidden = false; $('#ts_partial').hidden = true;
  const P = D.plan, T = D.tablo, S = D.secim, lg = L();
  // source line
  if (D.source === 'hazir') {
    const k = D.runs[0];
    $('#ts_source').textContent = `${t('src_hazir')} · ${t('src_main')}: ${D.runs.map((r) => r.kosu_id).join(', ')} (n = ${fmtInt(k.n_sim)}, seed ${k.seed}, ${k.rng}) · ${t('src_engine')}: ${k.motor_surumu} · ${t('src_db')} v${A.hz().info.vt_surumu}, SHA-256 ${A.hz().info.sha256.slice(0, 12)}…`;
  } else {
    $('#ts_source').textContent = `${t('src_canli')} · ${D.r_version} · n = ${fmtInt(D.c.n_sim)}, seed ${D.c.seed}, ${P.rng} · ${fmtInt(P.n_kosu)} ${t('ts_runs')} · ${num(D.elapsed_ms / 1000, 1, lg)} s`;
  }
  const gtxt = D.c.guc === 'gmr' || D.c.guc === 'delta' ? `GMR = ${num(P.gmr, 4, lg)}` : t('opt_' + D.c.guc);
  $('#ts_target').textContent = `${t('ts_power_at')}: ${gtxt} · ${t('ts_t1_at')} · ${t('ts_hedef')}: %${num(100 * D.hedef, 1, lg)} · ${t('ts_cand')}: ℓ {${D.c.l.join(', ')}} × n {${D.c.n.join(', ')}} × m {${D.c.m.join(', ')}}`;
  // summary
  const sb = $('#ts_sum tbody'); sb.innerHTML = '';
  for (let i = 0; i < S.yontem.length; i++) {
    const tr = document.createElement('tr'); tr.dataset.yontem = S.yontem[i]; tr.dataset.kural = S.kural[i];
    tr.append(td(t('m_' + S.yontem[i])), td(t('ts_rule_' + S.kural[i])));
    if (S.var[i]) {
      tr.append(td(`${S.l[i]} × ${S.n[i]} × ${S.m[i]}`), td(fmtInt(S.toplam[i]), 'num'), td(pct(S.guc[i], lg), 'num'), td(pp(S.guc_mcse[i], lg), 'num'),
        td(S.t1[i] === null || Number.isNaN(S.t1[i]) ? '—' : pct(S.t1[i], lg), 'num'), td(S.t1_etiket[i] ? t('kk38_' + S.t1_etiket[i]) : '—'),
        td(S.esik_yakin[i] ? t('ts_near') : ''));
    } else {
      const c = td(t('ts_none') + ' — ' + t('ts_why_' + S.neden[i])); c.colSpan = 7; tr.append(c);
    }
    sb.append(tr);
  }
  // warnings
  const w = [['ts_w_cand', t('ts_w_cand')], ['warn_power', t('warn_power')]];
  if (P.notlar.includes('fda_delta0_undefined')) w.push(['ts_w_delta0', t('ts_w_delta0')]);
  const nonH1 = P.yontem.filter((me, i) => P.sinif[i] !== 'H1');
  if (nonH1.length) w.push(['ts_w_h1', t('ts_w_h1') + ' ' + nonH1.map((me) => t('m_' + me)).join(', ')]);
  if (S.esik_yakin.some((x) => x)) w.push(['ts_w_near', t('ts_w_near')]);
  const wb = $('#ts_warnings'); wb.innerHTML = '';
  for (const [k, v] of w) { const p = document.createElement('p'); p.className = 'warn'; p.dataset.warn = k; p.textContent = v; wb.append(p); }
  // per method grids
  const host = $('#ts_grids'); host.innerHTML = '';
  for (const me of METHODS) {
    const idx = T.yontem.map((y, i) => (y === me ? i : -1)).filter((i) => i >= 0);
    const h = document.createElement('h3'); h.textContent = `${t('m_' + me)} · ${t('metrik_' + T.guc_metrik[idx[0]])} (${t('sinif_' + T.guc_sinif[idx[0]])})`; host.append(h);
    const ms = [...new Set(idx.map((i) => T.m[i]))];
    for (const mv of ms) {
      const wrap = document.createElement('div'); wrap.className = 'tablewrap';
      const tb = document.createElement('table'); tb.className = 'grid'; tb.dataset.yontem = me; tb.dataset.m = mv;
      const ns = [...new Set(idx.filter((i) => T.m[i] === mv).map((i) => T.n[i]))].sort((a, b) => a - b);
      const ls = [...new Set(idx.filter((i) => T.m[i] === mv).map((i) => T.l[i]))].sort((a, b) => a - b);
      const hr = document.createElement('tr'); hr.append(th(`m = ${mv} · ℓ \\ n`)); ns.forEach((n) => hr.append(th(String(n))));
      const thead = document.createElement('thead'); thead.append(hr); tb.append(thead);
      const tbody = document.createElement('tbody');
      for (const l of ls) {
        const tr = document.createElement('tr'); tr.append(th(String(l)));
        for (const n of ns) {
          const i = idx.find((j) => T.l[j] === l && T.n[j] === n && T.m[j] === mv);
          const c = document.createElement('td'); c.className = 'num cell';
          if (i === undefined) { c.textContent = '—'; tr.append(c); continue; }
          const a = S.yontem.findIndex((y, j) => y === me && S.kural[j] === 'A' && S.var[j] && S.l[j] === l && S.n[j] === n && S.m[j] === mv);
          const b = S.yontem.findIndex((y, j) => y === me && S.kural[j] === 'B' && S.var[j] && S.l[j] === l && S.n[j] === n && S.m[j] === mv);
          if (T.hedef_ok[i]) c.classList.add('ok'); if (T.esik_yakin[i]) c.classList.add('near');
          if (a >= 0) c.classList.add('selA'); if (b >= 0) c.classList.add('selB');
          c.dataset.l = l; c.dataset.n = n; c.dataset.m = mv; c.dataset.guc = String(T.guc[i]); c.dataset.t1 = String(T.t1[i]);
          const g = document.createElement('div'); g.className = 'g';
          g.textContent = pct(T.guc[i], lg) + (a >= 0 ? ' A' : '') + (b >= 0 ? ' B' : '') + (T.esik_yakin[i] ? ' ≈' : '');
          const s2 = document.createElement('div'); s2.className = 's';
          s2.textContent = `± ${pp(T.guc_mcse[i], lg)}` + (T.t1[i] === null || Number.isNaN(T.t1[i]) ? '' : ` · I ${pct(T.t1[i], lg)}${k38sym(T.t1_etiket[i])}`);
          c.append(g, s2); tr.append(c);
        }
        tbody.append(tr);
      }
      tb.append(tbody); wrap.append(tb); host.append(wrap);
    }
  }
  $('#ts_legend').textContent = t('ts_legend');
}
function renderPartial() {
  const p = partial; const box = $('#ts_partial'); box.hidden = false; $('#ts_result').hidden = true;
  box.textContent = `${t('ts_partial')} ${p.done}/${p.total}`;
}

// ---------------------------------------------------------------- link (R-6)
export function tasLink(u) {
  const c = readTas();
  u.searchParams.set('mode', 'tasarim');
  for (const k of ['sigma_R', 'rho', 'pB_T', 'pB_R', 'pL', 'q']) u.searchParams.set('t_' + k, numExact(c.pop[k]));
  u.searchParams.set('ls', c.l.join('-')); u.searchParams.set('ns', c.n.join('-')); u.searchParams.set('ms', c.m.join('-'));
  u.searchParams.set('g', ['gmr', 'delta'].includes(c.guc) ? `${c.guc}:${numExact(c.custom)}` : c.guc);
  u.searchParams.set('hedef', numExact(c.hedef)); u.searchParams.set('nsim', numExact(c.n_sim)); u.searchParams.set('seed', numExact(c.seed));
  return u;
}
function parseTasLink(Q) {
  if (Q.get('mode') !== 'tasarim') return false;
  const o = {};
  for (const k of ['sigma_R', 'rho', 'pB_T', 'pB_R', 'pL', 'q']) if (Q.has('t_' + k)) o[k] = Q.get('t_' + k);
  for (const k of ['ls', 'ns', 'ms']) if (Q.has(k)) o[k] = Q.get(k).split('-').join(' ');
  if (Q.has('g')) { const [kind, v] = Q.get('g').split(':'); o.guc_choice = kind; if (v !== undefined) o.guc_custom = v; }
  for (const [k, f] of [['hedef', 'hedef'], ['nsim', 'n_sim'], ['seed', 'seed']]) if (Q.has(k)) o[f] = Q.get(k);
  setTas(o); return true;
}

// ---------------------------------------------------------------- tabs, language, init
export function showMode(mode) {
  const tas = mode === 'tasarim';
  $('#main_tek').hidden = tas; $('#main_tas').hidden = !tas;
  $('#tab_tek').classList.toggle('on', !tas); $('#tab_tas').classList.toggle('on', tas);
  $('#tab_tek').setAttribute('aria-selected', String(!tas)); $('#tab_tas').setAttribute('aria-selected', String(tas));
  state.mode = mode;
}
export function onLang() {
  if (!A) return;
  customVis(); info();
  if (statusKey) setStatus(statusKey, statusCls, statusArg);
  if (errFn) showErrors(errFn);
  if (last) render(); else if (partial && partial.done) renderPartial();
}
export function setReady(ok) { $('#ts_run').disabled = !ok; $('#ts_live').disabled = !ok; $('#ts_script').disabled = !ok; }
export function initTasarim(api, Q) {
  A = api;
  $('#ts_form').addEventListener('submit', hesapla);
  $('#ts_form').addEventListener('input', info);
  $('#ts_form [name=guc_choice]').addEventListener('change', (e) => { $('#ts_form [name=guc_custom]').value = e.target.value === 'delta' ? '0.04879' : '1.05'; customVis(); });
  $('#ts_cancel').addEventListener('click', iptal);
  $('#ts_live').addEventListener('click', () => hesapla(null, true));
  $('#ts_script').addEventListener('click', betik);
  $('#tab_tek').addEventListener('click', () => showMode('tek'));
  $('#tab_tas').addEventListener('click', () => showMode('tasarim'));
  const linked = parseTasLink(Q);
  showMode(linked ? 'tasarim' : 'tek');
  customVis(); info();
  return linked;
}
