// CNK-FarmaStatR - shared engine loader for the P1 pages (index.html, kabul.html).
// Fetches the R files, checks the pinned ones against CEKIRDEK_SHA256.txt and loads only the
// verified bytes into webR. Research and education only; not validated for GxP use.

export const WEBR_VERSION = '0.5.4';
const Q = new URLSearchParams(location.search);
// A same-origin webR override (?webr=/path/) is accepted for offline tests only.
export const WEBR_BASE = (() => {
  const v = Q.get('webr');
  return v && v.startsWith('/') && !v.startsWith('//') ? (v.endsWith('/') ? v : v + '/')
    : `https://webr.r-wasm.org/v${WEBR_VERSION}/`;
})();
export const ROOT = new URL('../../', import.meta.url);   // repository root
const SHA_LIST = 'CNKfarmastatr/inst/validasyon/CEKIRDEK_SHA256.txt';

// Acceptance test hook (FSR-TN-PLT-01 Table 11.1, "Hash kontrolü"): ?bozuk=<file>:<byte>
// flips one bit of that byte after download, i.e. simulates a changed file. It can only
// make verification fail; the value is shown on the page and kept in the run record.
export const TAMPER = (() => {
  const v = Q.get('bozuk'); if (!v) return null;
  const [file, pos] = v.split(':'); const p = Number(pos);
  return file && Number.isInteger(p) && p >= 0 ? { file, pos: p } : null;
})();

export async function sha256(buf) {
  const h = await crypto.subtle.digest('SHA-256', buf);
  return [...new Uint8Array(h)].map((b) => b.toString(16).padStart(2, '0')).join('');
}
export async function fetchBytes(path) {
  const r = await fetch(new URL(path, ROOT), { cache: 'no-store' });
  if (!r.ok) throw new Error(`${r.status}`);
  return new Uint8Array(await r.arrayBuffer());
}

// pinnedFiles must match the SHA list; otherFiles are loaded and their hash is recorded.
export async function verifyFiles(pinnedFiles, otherFiles = []) {
  const listTxt = new TextDecoder().decode(await fetchBytes(SHA_LIST));
  const pinned = Object.fromEntries(listTxt.trim().split(/\r?\n/).map((l) => {
    const [h, f] = l.trim().split(/\s+/); return [f, h];
  }));
  const out = [];
  for (const f of [...pinnedFiles, ...otherFiles]) {
    const e = { file: f, pinned: pinnedFiles.includes(f), expected: pinned[f] || null, sha256: null, status: 'ok' };
    try {
      e.bytes = await fetchBytes('CNKfarmastatr/R/' + f);
      if (TAMPER && TAMPER.file === f && TAMPER.pos < e.bytes.length) e.bytes[TAMPER.pos] ^= 0x01;
      e.sha256 = await sha256(e.bytes);
      if (e.pinned && !e.expected) e.status = 'hash_missing';
      else if (e.pinned && e.sha256 !== e.expected) e.status = 'hash_mismatch';
    } catch (err) { e.status = 'fetch_failed'; }
    out.push(e);
  }
  return out;
}

// Start webR (PostMessage channel = GitHub Pages condition, no cross-origin isolation)
// and source the verified files in order; extraR is evaluated afterwards.
export async function startWebR(files, extraR = '') {
  const { WebR, ChannelType } = await import(WEBR_BASE + 'webr.mjs');
  const webR = new WebR({ baseUrl: WEBR_BASE, channelType: ChannelType.PostMessage });
  await webR.init();
  for (const e of files) {
    await webR.FS.writeFile('/home/web_user/' + e.file, e.bytes);
    await webR.evalRVoid(`source('/home/web_user/${e.file}')`);
  }
  if (extraR) await webR.evalRVoid(extraR);
  return webR;
}

// webR list -> plain object of scalars / arrays
export function plain(js) {
  if (js.type === 'list') {
    const o = {}; js.names.forEach((n, i) => { o[n] = plain(js.values[i]); }); return o;
  }
  const v = js.values; return v.length === 1 ? v[0] : v;
}
