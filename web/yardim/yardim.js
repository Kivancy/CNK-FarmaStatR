// CNK-FarmaStatR - help system (FSR-TN-PLT-07 v0.1; decision KK-63).
// Level 1: a "?" button next to every form label marked data-help="<screen>.<field>"; the hint
//          text opens below the label. Level 2: a "Help" button in the header opens a side panel
//          with the help of the visible tab (sections: what it does, data, settings, reading the
//          result, limits, sources) and links to the method notes (Level 3) and CSV templates.
// Texts come from yardim.json (TR and EN, same keys). The page's language is followed through
// <html lang>, which every screen sets. Nothing is computed here; no network request beyond
// loading yardim.json from the same site.
// Research and education only; not a system validated for GxP environments.

const BASE = new URL('./', import.meta.url);
const TABS = { tab_tek: 'tek', tab_tas: 'tas', tab_pbe: 'pbe', tab_dis: 'dis' };
let H = null;
const st = window.__yardim = { ready: false, open: false, screen: null, lang: null };
const L = () => (document.documentElement.lang === 'en' ? 'en' : 'tr');
const T = () => H[L()];

function currentScreen() {
  const on = document.querySelector('.tabs .tab.on');
  return (on && TABS[on.id]) || document.body.dataset.yardim || 'tek';
}

// ---------------------------------------------------------------- Level 1
function addHints() {
  for (const el of document.querySelectorAll('[data-help]')) {
    if (el.querySelector(':scope > .yh-row')) continue;
    const text = el.querySelector(':scope > span, :scope > .lbl');
    const row = document.createElement('span'); row.className = 'yh-row';
    const b = document.createElement('button');
    b.type = 'button'; b.className = 'yh-q'; b.textContent = '?';
    b.setAttribute('aria-expanded', 'false');
    const pop = document.createElement('span');
    pop.className = 'yh-pop'; pop.hidden = true; pop.setAttribute('role', 'note');
    pop.id = 'yh_' + el.dataset.help.replace(/[^a-z0-9]/gi, '_');
    b.setAttribute('aria-controls', pop.id);
    b.addEventListener('click', (ev) => { ev.preventDefault(); ev.stopPropagation(); togglePop(b, pop); });
    if (text) { text.before(row); row.append(text, b); } else { el.prepend(row); row.append(b); }
    row.after(pop);
  }
  fillHints();
}
function togglePop(b, pop, force) {
  const show = force === undefined ? pop.hidden : force;
  for (const p of document.querySelectorAll('.yh-pop')) if (p !== pop) { p.hidden = true; }
  for (const q of document.querySelectorAll('.yh-q')) if (q !== b) q.setAttribute('aria-expanded', 'false');
  pop.hidden = !show; b.setAttribute('aria-expanded', String(show));
}
function fillHints() {
  for (const el of document.querySelectorAll('[data-help]')) {
    const k = el.dataset.help, txt = T().ipucu[k];
    const b = el.querySelector('.yh-q'), pop = el.querySelector(':scope > .yh-pop');
    if (!b || !pop) continue;
    pop.textContent = txt || '';
    b.setAttribute('aria-label', `${T().ui.hint}: ${(el.querySelector('.yh-row > span, .yh-row > .lbl') || {}).textContent || k}`);
    b.title = T().ui.hint;
  }
}

// ---------------------------------------------------------------- Level 2
let panel, btn, lastFocus = null;
function buildPanel() {
  btn = document.createElement('button');
  btn.type = 'button'; btn.id = 'yh_btn'; btn.className = 'ghost yh-btn';
  btn.setAttribute('aria-controls', 'yh_panel'); btn.setAttribute('aria-expanded', 'false');
  const lang = document.getElementById('lang');
  const wrap = document.createElement('div'); wrap.className = 'yh-hdr';
  if (lang) { lang.before(wrap); wrap.append(btn, lang); } else document.querySelector('header').append(btn);
  panel = document.createElement('aside');
  panel.id = 'yh_panel'; panel.className = 'yh-panel'; panel.hidden = true;
  panel.setAttribute('role', 'dialog'); panel.setAttribute('aria-modal', 'false'); panel.setAttribute('aria-labelledby', 'yh_title');
  panel.innerHTML = '<div class="yh-head"><h2 id="yh_title" tabindex="-1"></h2><button type="button" class="ghost yh-close"></button></div><div class="yh-body"></div>';
  document.body.append(panel);
  btn.addEventListener('click', () => (st.open ? closePanel() : openPanel()));
  panel.querySelector('.yh-close').addEventListener('click', closePanel);
  document.addEventListener('keydown', (ev) => {
    if (ev.key !== 'Escape') return;
    if (st.open) { closePanel(); return; }
    for (const p of document.querySelectorAll('.yh-pop')) p.hidden = true;
    for (const q of document.querySelectorAll('.yh-q')) q.setAttribute('aria-expanded', 'false');
  });
  for (const id of Object.keys(TABS)) {
    const t = document.getElementById(id);
    if (t) t.addEventListener('click', () => setTimeout(() => { if (st.open) fillPanel(); }, 0));
  }
}
function fillPanel() {
  const t = T(), s = currentScreen();
  st.screen = s; st.lang = L();
  panel.querySelector('#yh_title').textContent = `${t.ui.panel}: ${t.ui.screens[s]}`;
  panel.querySelector('.yh-close').textContent = t.ui.close;
  const body = panel.querySelector('.yh-body'); body.innerHTML = '';
  for (const sec of t.panel[s]) {
    const d = document.createElement('section'); d.className = 'yh-sec'; d.dataset.sec = sec.id;
    const h = document.createElement('h3'); h.textContent = t.ui.sections[sec.id];
    const c = document.createElement('div'); c.innerHTML = sec.html;          // static text of yardim.json
    for (const a of c.querySelectorAll('a[href]')) a.href = new URL(a.getAttribute('href'), location.href).href;
    d.append(h, c); body.append(d);
  }
}
function openPanel() {
  lastFocus = document.activeElement;
  fillPanel(); panel.hidden = false; st.open = true; btn.setAttribute('aria-expanded', 'true');
  document.body.classList.add('yh-acik');
  panel.querySelector('#yh_title').focus();
}
function closePanel() {
  panel.hidden = true; st.open = false; btn.setAttribute('aria-expanded', 'false');
  document.body.classList.remove('yh-acik');
  if (lastFocus && lastFocus.focus) lastFocus.focus();
}
function applyLang() {
  btn.textContent = T().ui.help;
  fillHints();
  if (st.open) fillPanel();
}

async function boot() {
  const css = document.createElement('link'); css.rel = 'stylesheet'; css.href = new URL('yardim.css', BASE).href;
  document.head.append(css);
  H = await (await fetch(new URL('yardim.json', BASE), { cache: 'no-store' })).json();
  addHints(); buildPanel(); applyLang();
  new MutationObserver(applyLang).observe(document.documentElement, { attributes: true, attributeFilter: ['lang'] });
  st.ready = true; st.openPanel = openPanel; st.closePanel = closePanel; st.screenNow = currentScreen;
}
boot().catch((e) => { st.error = String(e && e.message || e); });
