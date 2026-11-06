// CNK-FarmaStatR - charts of the dissolution analyses (FSR-TN-PLT-14, KK-80; request 11052026-a).
// One drawing function per chart, used both on the screen and for the Word report (GR-5).
// The page computes nothing: every value drawn comes from R (platform_dis_grafik); here only
// positions on the canvas are worked out. Series differ by colour and by marker and line type.
// Research and education only; not a system validated for GxP environments.

export const LIGHT = { fg: '#1f1f1c', muted: '#5f5f5a', grid: '#d9d8d2', bg: '#ffffff', T: '#b5482b', R: '#2b6cb0', bar: '#9fb7d3', ref: '#7a4a00' };

function frame(ctx, W, H, C, box, xr, yr, xt, yt, xl, yl) {
  const { L, R, T, B } = box;
  const x = (v) => L + (W - L - R) * (v - xr[0]) / (xr[1] - xr[0]);
  const y = (v) => T + (H - T - B) * (1 - (v - yr[0]) / (yr[1] - yr[0]));
  ctx.fillStyle = C.bg; ctx.fillRect(0, 0, W, H);
  ctx.font = '12px sans-serif'; ctx.lineWidth = 1;
  for (const g of yt) { ctx.strokeStyle = C.grid; ctx.beginPath(); ctx.moveTo(L, y(g)); ctx.lineTo(W - R, y(g)); ctx.stroke();
    ctx.fillStyle = C.muted; ctx.textAlign = 'right'; ctx.fillText(String(g), L - 6, y(g) + 4); }
  ctx.textAlign = 'center';
  let last = -1e9;   // skip labels that would overlap the previous one
  for (const v of xt) { if (x(v) - last < 30) continue; ctx.fillText(String(v), x(v), H - B + 16); last = x(v); }
  ctx.fillText(xl, (L + W - R) / 2, H - 6);
  ctx.save(); ctx.translate(14, (T + H - B) / 2); ctx.rotate(-Math.PI / 2); ctx.fillText(yl, 0, 0); ctx.restore();
  ctx.strokeStyle = C.muted; ctx.beginPath(); ctx.moveTo(L, T); ctx.lineTo(L, H - B); ctx.lineTo(W - R, H - B); ctx.stroke();
  return { x, y };
}
function marker(ctx, kind, px, py, col, filled) {
  ctx.strokeStyle = col; ctx.fillStyle = filled ? col : '#ffffff'; ctx.lineWidth = 1.6; ctx.beginPath();
  if (kind === 'o') ctx.arc(px, py, 4, 0, 2 * Math.PI); else ctx.rect(px - 4, py - 4, 8, 8);
  ctx.fill(); ctx.stroke();
}
function legend(ctx, items, x0, y0, C) {
  let x = x0; ctx.font = '12px sans-serif'; ctx.textAlign = 'left';
  for (const it of items) {
    ctx.strokeStyle = it.col; ctx.lineWidth = 2; ctx.setLineDash(it.dash || []);
    ctx.beginPath(); ctx.moveTo(x, y0); ctx.lineTo(x + 22, y0); ctx.stroke(); ctx.setLineDash([]);
    if (it.m) marker(ctx, it.m, x + 11, y0, it.col, it.filled !== false);
    ctx.fillStyle = C.fg; ctx.fillText(it.lab, x + 28, y0 + 4); x += 36 + ctx.measureText(it.lab).width;
  }
}
const ticksX = (z) => z;   // the time points themselves
const niceMax = (m) => (m <= 100 ? 100 : Math.ceil(m / 10) * 10);
const niceStep = (r) => { const p = Math.pow(10, Math.floor(Math.log10(r))), f = r / p; return (f <= 1 ? 1 : f <= 2 ? 2 : f <= 5 ? 5 : 10) * p; };

// mean profiles of test (circles, solid) and reference (squares, dashed); +/- SD; 85 % line;
// points not used in the analysis drawn open (GR-1). For Weibull also the fitted curves (GR-3).
export function drawProfile(ctx, W, H, g, lab, C = LIGHT) {
  const z = g.zaman, ymax = niceMax(Math.max(...g.ortT.map((v, i) => v + g.sdT[i]), ...g.ortR.map((v, i) => v + g.sdR[i])));
  const z0 = Math.min(...z, ...(g.egri ? g.egri.tt : [])), z1 = Math.max(...z, ...(g.egri ? g.egri.tt : [])), pad = (z1 - z0) * 0.04 || 1;
  const xr = [z0 - pad >= 0 || z0 < 0 ? z0 - pad : 0, z1 + pad];
  const { x, y } = frame(ctx, W, H, C, { L: 54, R: 16, T: 30, B: 44 }, xr, [0, ymax], ticksX(z),
    [0, 20, 40, 60, 80, 100].filter((v) => v <= ymax), lab.x, lab.y);
  ctx.strokeStyle = C.muted; ctx.setLineDash([6, 4]); ctx.beginPath(); ctx.moveTo(x(xr[0]), y(85)); ctx.lineTo(x(xr[1]), y(85)); ctx.stroke(); ctx.setLineDash([]);
  ctx.fillStyle = C.muted; ctx.textAlign = 'left'; ctx.fillText('85 %', x(xr[0]) + 4, y(85) - 4);
  const ser = [[g.ortT, g.sdT, C.T, 'o', [], -2], [g.ortR, g.sdR, C.R, 's', [7, 4], 2]];
  if (g.egri) {
    for (const [e, col, dash] of [[g.egri.egT, C.T, []], [g.egri.egR, C.R, [7, 4]]]) {
      ctx.strokeStyle = col; ctx.lineWidth = 2; ctx.setLineDash(dash); ctx.beginPath();
      g.egri.tt.forEach((t, i) => (i ? ctx.lineTo(x(t), y(e[i])) : ctx.moveTo(x(t), y(e[i])))); ctx.stroke(); ctx.setLineDash([]);
    }
  }
  for (const [m, sd, col, mk, dash, off] of ser) {
    if (!g.egri) { ctx.strokeStyle = col; ctx.lineWidth = 2; ctx.setLineDash(dash); ctx.beginPath();
      z.forEach((t, i) => (i ? ctx.lineTo(x(t) + off, y(m[i])) : ctx.moveTo(x(t) + off, y(m[i])))); ctx.stroke(); ctx.setLineDash([]); }
    z.forEach((t, i) => {
      ctx.strokeStyle = col; ctx.lineWidth = 1.2; ctx.beginPath(); ctx.moveTo(x(t) + off, y(m[i] - sd[i])); ctx.lineTo(x(t) + off, y(m[i] + sd[i]));
      ctx.moveTo(x(t) + off - 3, y(m[i] - sd[i])); ctx.lineTo(x(t) + off + 3, y(m[i] - sd[i])); ctx.moveTo(x(t) + off - 3, y(m[i] + sd[i])); ctx.lineTo(x(t) + off + 3, y(m[i] + sd[i])); ctx.stroke();
      marker(ctx, mk === 'o' ? 'o' : 's', x(t) + off, y(m[i]), g.kullanilan[i] ? col : C.muted, g.kullanilan[i]);
    });
  }
  const items = [{ lab: `T (${g.test})`, col: C.T, m: 'o' }, { lab: `R (${g.ref})`, col: C.R, m: 's', dash: [7, 4] }];
  if (g.kullanilan.some((u) => !u)) items.push({ lab: lab.unused, col: C.muted, m: 'o', filled: false, dash: [0, 100] });
  legend(ctx, items, 60, 16, C);
}

// bootstrap distribution of the estimator: histogram, point estimate, 90 % interval, 50 line (GR-2)
export function drawHist(ctx, W, H, h, lab, C = LIGHT) {
  const br = h.kirilim, n = h.sayi, ys = niceStep(Math.max(...n) / 4), top = Math.ceil(Math.max(...n) * 1.12 / ys) * ys;
  const lo = Math.min(br[0], 49), hi = Math.max(br[br.length - 1], 51);
  const step = br[1] - br[0], xt = br.filter((v, i) => i % Math.max(1, Math.round(br.length / 10)) === 0);
  const { x, y } = frame(ctx, W, H, C, { L: 60, R: 16, T: 30, B: 44 }, [lo, hi], [0, top], xt,
    Array.from({ length: Math.round(top / ys) + 1 }, (_, i) => i * ys), lab.x, lab.y);
  ctx.fillStyle = C.bar; ctx.strokeStyle = C.bg; ctx.lineWidth = 1;
  n.forEach((c, i) => { const a = x(br[i]), b = x(br[i] + step); ctx.fillRect(a, y(c), b - a, y(0) - y(c)); ctx.strokeRect(a, y(c), b - a, y(0) - y(c)); });
  const vline = (v, col, dash, text, dy) => { ctx.strokeStyle = col; ctx.lineWidth = 2; ctx.setLineDash(dash); ctx.beginPath(); ctx.moveTo(x(v), y(0)); ctx.lineTo(x(v), y(top)); ctx.stroke(); ctx.setLineDash([]);
    ctx.fillStyle = col; ctx.textAlign = 'left'; ctx.fillText(text, x(v) + 4, y(top) + 14 + dy); };
  vline(h.alt, C.fg, [6, 4], lab.lo, 0); vline(h.ust, C.fg, [6, 4], lab.hi, 0); vline(h.nokta, C.T, [], lab.est, 16); vline(50, C.ref, [2, 3], '50', 32);
  legend(ctx, [{ lab: lab.bars, col: C.bar }, { lab: lab.ci, col: C.fg, dash: [6, 4] }, { lab: lab.est, col: C.T }, { lab: '50', col: C.ref, dash: [2, 3] }], 66, 16, C);
}

// screen: a canvas sized for the device; report: an off-screen canvas -> PNG bytes (GR-6)
export function onScreen(host, draw, W = 620, H = 300) {
  const c = document.createElement('canvas'), r = window.devicePixelRatio || 1;
  c.width = Math.round(W * r); c.height = Math.round(H * r); c.style.width = '100%'; c.style.maxWidth = W + 'px'; c.setAttribute('role', 'img');
  const ctx = c.getContext('2d'); ctx.scale(r, r); draw(ctx, W, H); host.append(c); return c;
}
export function pngBytes(draw, W = 620, H = 300, scale = 2) {
  const c = document.createElement('canvas'); c.width = W * scale; c.height = H * scale;
  const ctx = c.getContext('2d'); ctx.scale(scale, scale); draw(ctx, W, H);
  const b64 = c.toDataURL('image/png').split(',')[1], s = atob(b64), out = new Uint8Array(s.length);
  for (let i = 0; i < s.length; i++) out[i] = s.charCodeAt(i);
  return { bytes: out, w: W, h: H };
}
