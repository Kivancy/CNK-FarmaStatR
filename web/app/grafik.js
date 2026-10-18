// CNK-FarmaStatR - charts as inline SVG (FSR-TN-PLT-04 T-4, P4-K2). No library, no statistics:
// every mark is a value from R or from the database; its value is kept in data-value so the
// acceptance tool can compare it with the table.
// Research and education only; not a system validated for GxP environments.

const NS = 'http://www.w3.org/2000/svg';
const el = (tag, attrs = {}, text) => {
  const e = document.createElementNS(NS, tag);
  for (const [k, v] of Object.entries(attrs)) e.setAttribute(k, v);
  if (text !== undefined) e.textContent = text;
  return e;
};
const METHODS = ['fda', 'ema_a', 'ema_b', 'ema_c'];
const COLORS = { fda: 'var(--c-fda)', ema_a: 'var(--c-a)', ema_b: 'var(--c-b)', ema_c: 'var(--c-c)' };

function niceMax(v) { const s = [1, 2, 2.5, 5, 10, 20, 25, 50, 100]; for (const x of s) if (v <= x) return x; return 100; }

// G1: rate +/- z*MCSE per method; nominal line in H0 classes; marker by class.
// items: [{yontem, label, rate, mcse, sinif}], z, alpha, fmt(p) -> text, lbl(key) -> text
export function g1(host, items, z, alpha, fmt, lbl) {
  host.innerHTML = '';
  const W = 520, H = 230, L = 46, R = 12, T = 14, B = 40;
  const hi = Math.max(...items.map((d) => 100 * (d.rate + z * (d.mcse || 0))), alpha * 100);
  const ymax = niceMax(hi * 1.1), y = (v) => T + (H - T - B) * (1 - v / ymax);
  const step = (W - L - R) / items.length, x = (i) => L + step * (i + 0.5);
  const svg = el('svg', { viewBox: `0 0 ${W} ${H}`, role: 'img', 'aria-label': lbl('g1_title'), class: 'chart' });
  for (const t of [0, 0.25, 0.5, 0.75, 1].map((f) => f * ymax)) {
    svg.append(el('line', { x1: L, x2: W - R, y1: y(t), y2: y(t), class: 'grid' }));
    svg.append(el('text', { x: L - 6, y: y(t) + 4, 'text-anchor': 'end', class: 'tick' }, fmt(t / 100)));
  }
  if (items.some((d) => d.sinif === 'H0_sinir' || d.sinif === 'H0_ic')) {
    svg.append(el('line', { x1: L, x2: W - R, y1: y(alpha * 100), y2: y(alpha * 100), class: 'nominal', 'data-value': String(alpha) }));
    svg.append(el('text', { x: W - R, y: y(alpha * 100) - 4, 'text-anchor': 'end', class: 'tick' }, lbl('g1_nominal')));
  }
  items.forEach((d, i) => {
    const cx = x(i), cy = y(100 * d.rate), col = COLORS[d.yontem];
    if (d.mcse !== null && d.mcse !== undefined) {
      const lo = Math.max(0, 100 * (d.rate - z * d.mcse)), up = 100 * (d.rate + z * d.mcse);
      svg.append(el('line', { x1: cx, x2: cx, y1: y(lo), y2: y(up), stroke: col, 'stroke-width': 2 }));
    }
    const mk = d.sinif === 'H1'
      ? el('polygon', { points: `${cx},${cy - 6} ${cx - 6},${cy + 5} ${cx + 6},${cy + 5}` })
      : d.sinif === 'H0_ic' ? el('rect', { x: cx - 5, y: cy - 5, width: 10, height: 10 })
        : el('circle', { cx, cy, r: 5.5 });
    mk.setAttribute('fill', col); mk.setAttribute('class', 'mark');
    mk.setAttribute('data-yontem', d.yontem); mk.setAttribute('data-value', String(d.rate)); mk.setAttribute('data-sinif', d.sinif);
    mk.append(el('title', {}, `${d.label}: ${fmt(d.rate)}`));
    svg.append(mk);
    svg.append(el('text', { x: cx, y: H - B + 16, 'text-anchor': 'middle', class: 'tick' }, d.label));
  });
  svg.append(el('text', { x: 12, y: T + (H - T - B) / 2, transform: `rotate(-90 12 ${T + (H - T - B) / 2})`, 'text-anchor': 'middle', class: 'tick' }, lbl('g1_y')));
  host.append(svg);
}

// G2: pass rate of the four methods along one grid parameter; the selected scenario marked.
// nb: {param, pts:[{x, no, rates:{fda,...}}]}, selNo, fmt(p), fx(x), lbl(key)
export function g2(host, nb, selNo, fmt, fx, lbl, mlabel) {
  host.innerHTML = '';
  if (!nb) { host.append(Object.assign(document.createElement('p'), { className: 'hint', textContent: lbl('g2_none') })); return; }
  const W = 520, H = 240, L = 46, R = 90, T = 14, B = 40;
  const xs = nb.pts.map((p) => p.x), xmin = Math.min(...xs), xmax = Math.max(...xs);
  const vals = nb.pts.flatMap((p) => METHODS.map((m) => p.rates[m]).filter((v) => v !== null));
  const ymax = niceMax(Math.max(...vals) * 100 * 1.1);
  const X = (v) => L + (W - L - R) * (xmax === xmin ? 0.5 : (v - xmin) / (xmax - xmin)), Y = (v) => T + (H - T - B) * (1 - v / ymax);
  const svg = el('svg', { viewBox: `0 0 ${W} ${H}`, role: 'img', 'aria-label': lbl('g2_title'), class: 'chart' });
  for (const t of [0, 0.25, 0.5, 0.75, 1].map((f) => f * ymax)) {
    svg.append(el('line', { x1: L, x2: W - R, y1: Y(t), y2: Y(t), class: 'grid' }));
    svg.append(el('text', { x: L - 6, y: Y(t) + 4, 'text-anchor': 'end', class: 'tick' }, fmt(t / 100)));
  }
  nb.pts.forEach((p) => svg.append(el('text', { x: X(p.x), y: H - B + 16, 'text-anchor': 'middle', class: 'tick' }, fx(p.x))));
  const sel = nb.pts.find((p) => p.no === selNo);
  if (sel) svg.append(el('line', { x1: X(sel.x), x2: X(sel.x), y1: T, y2: H - B, class: 'selected', 'data-no': String(selNo) }));
  METHODS.forEach((m, k) => {
    const pts = nb.pts.filter((p) => p.rates[m] !== null);
    svg.append(el('polyline', { points: pts.map((p) => `${X(p.x)},${Y(100 * p.rates[m])}`).join(' '), fill: 'none', stroke: COLORS[m], 'stroke-width': 2 }));
    pts.forEach((p) => {
      const c = el('circle', { cx: X(p.x), cy: Y(100 * p.rates[m]), r: p.no === selNo ? 5 : 3, fill: COLORS[m], class: 'mark',
        'data-yontem': m, 'data-no': String(p.no), 'data-value': String(p.rates[m]) });
      c.append(el('title', {}, `${mlabel(m)} · ${fx(p.x)}: ${fmt(p.rates[m])}`));
      svg.append(c);
    });
    svg.append(el('text', { x: W - R + 8, y: T + 14 + 16 * k, class: 'legend', style: `fill: ${COLORS[m]}` }, mlabel(m)));
  });
  svg.append(el('text', { x: L + (W - L - R) / 2, y: H - 6, 'text-anchor': 'middle', class: 'tick' }, lbl('par_' + nb.param)));
  host.append(svg);
}
