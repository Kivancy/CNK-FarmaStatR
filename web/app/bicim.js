// CNK-FarmaStatR - number display and canonical key in the browser (FSR-TN-PLT-04, KK-54).
// No statistics here: these functions only format numbers that R produced, and build the
// text key used to look a scenario up in the database.
// Research and education only; not a system validated for GxP environments.

// ---------------------------------------------------------------- P4-K3: one display rule
// Fixed decimals from the exact binary value of x: nearest; an exact tie goes to the even
// digit (C99 printf, IEEE 754 round-half-even), i.e. the same text as R's formatC() on Linux
// (glibc), which wrote the published tables. Number.prototype.toFixed is exact too but takes
// the larger value on a tie (ECMA-262), so ties are detected with integer arithmetic.
function exactParts(x) {                         // |x| = m * 2^e exactly
  const dv = new DataView(new ArrayBuffer(8)); dv.setFloat64(0, Math.abs(x));
  const hi = dv.getUint32(0), lo = dv.getUint32(4);
  const ex = (hi >>> 20) & 0x7ff;
  const m = (BigInt(hi & 0xfffff) << 32n) | BigInt(lo);
  return ex === 0 ? { m, e: -1074 } : { m: m | (1n << 52n), e: ex - 1075 };
}
export function fixed(x, f) {
  if (x === null || x === undefined || Number.isNaN(x)) return 'NA';
  if (!Number.isFinite(x)) return x > 0 ? 'Inf' : '-Inf';
  const { m, e } = exactParts(x);
  if (e < 0) {
    const num = 2n * m * 10n ** BigInt(f), den = 1n << BigInt(-e);
    if (num % den === 0n && (num / den) % 2n === 1n) {           // exact tie at f decimals
      const q = (num / den - 1n) / 2n;                            // lower candidate of |x| * 10^f
      const k = q % 2n === 0n ? q : q + 1n;                       // the even one
      const s = (Number(k) / 10 ** f).toFixed(f);
      return (x < 0 && k !== 0n ? '-' : '') + s;
    }
  }
  return x.toFixed(f);
}
// display helpers: decimal mark by language
export const dec = (s, lang) => (lang === 'tr' ? s.replace('.', ',') : s);
export const pct = (p, lang) => dec(fixed(100 * p, 1), lang);          // rates: percent, 1 decimal
export const pp = (se, lang) => dec(fixed(100 * se, 2), lang);         // MCSE: percentage points, 2 decimals
export const num = (x, f, lang) => dec(fixed(x, f), lang);

// ---------------------------------------------------------------- canonical key (D-03)
// Same text as R's platform_anahtar() (FSR-TN-PLT-02 Section 4): .num_exact() writes the
// shortest of %.15g, %.16g, %.17g that reads back to the same double.
function cg(x, d) {                               // C printf "%.<d>g", exact (half-even on ties)
  if (x === 0) return Object.is(x, -0) ? '-0' : '0';
  const { m, e } = exactParts(x);
  // exact decimal digits D and exponent so that |x| = 0.D * 10^P
  let D, P;
  if (e >= 0) { D = (m << BigInt(e)).toString(); P = D.length; }
  else { const t = (m * 5n ** BigInt(-e)).toString(); D = t; P = t.length + e; }   // value = t * 10^e
  D = D.replace(/0+$/, '') || '0';
  // round to d significant digits, ties to even
  let Q = D.slice(0, d).padEnd(d, '0'), rest = D.slice(d);
  let up = false;
  if (rest.length) {
    const r0 = rest[0], tail = rest.slice(1).replace(/0+$/, '');
    if (r0 > '5' || (r0 === '5' && tail.length)) up = true;
    else if (r0 === '5' && !tail.length) up = Number(Q[Q.length - 1]) % 2 === 1;
  }
  if (up) { const t = (BigInt(Q) + 1n).toString(); if (t.length > d) { Q = t.slice(0, d); P += 1; } else Q = t; }
  const X = P - 1, neg = x < 0 ? '-' : '';
  const trim = (s) => (s.includes('.') ? s.replace(/0+$/, '').replace(/\.$/, '') : s);
  if (X < -4 || X >= d) {
    const mant = trim(Q[0] + '.' + Q.slice(1)), a = Math.abs(X);
    return neg + mant + 'e' + (X < 0 ? '-' : '+') + (a < 10 ? '0' + a : String(a));
  }
  let s;
  if (X >= 0) s = Q.slice(0, X + 1) + '.' + Q.slice(X + 1);
  else s = '0.' + '0'.repeat(-X - 1) + Q;
  return neg + trim(s);
}
export function numExact(x) {
  if (!Number.isFinite(x)) return Number.isNaN(x) ? 'NaN' : (x > 0 ? 'Inf' : '-Inf');
  let s;
  for (const d of [15, 16, 17]) { s = cg(x, d); if (Number(s) === x) return s; }
  return s;
}
export const SINIRLAR = ['fda_delta0', 'fda_minus_delta0', 'ema_1.18', 'ema_0.85', 'gmr_1.00', 'gmr_1.05'];
// p: {sigma_R, rho, pB_T, pB_R, pL, q, l, n, m, n_sim, seed}; d: boundary name or a number (delta)
export function anahtar(p, d, kosu = false) {
  const f = (v) => numExact(Number(v));
  const dt = typeof d === 'string' ? d : numExact(d);
  let k = `sigma_R=${f(p.sigma_R)}|rho=${f(p.rho)}|pB_T=${f(p.pB_T)}|pB_R=${f(p.pB_R)}|pL=${f(p.pL)}|q=${f(p.q)}` +
          `|l=${f(p.l)}|n=${f(p.n)}|m=${f(p.m)}|delta=${dt}`;
  if (kosu) k += `|n_sim=${f(p.n_sim)}|seed=${f(p.seed)}`;
  return k;
}
