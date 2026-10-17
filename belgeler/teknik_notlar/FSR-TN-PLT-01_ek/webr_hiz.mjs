// FSR-TN-PLT-01 - webR speed and identity trial of the in vitro engine (invitro_fast.R, invitro_grid.R).
// Sources the two engine files into webR (no package build), runs invitro_scenario() and prints
// time and four results to 17 significant digits for comparison with native R.
// Research and education only; not a system validated for GxP environments.
import { WebR } from 'webr';
import fs from 'fs';
// Run from the repository root:  npm install webr@0.5.4 && node belgeler/teknik_notlar/FSR-TN-PLT-01_ek/webr_hiz.mjs
const R = 'CNKfarmastatr/R/';
const t0 = Date.now();
const webR = new WebR();
await webR.init();
const tInit = (Date.now() - t0) / 1000;
for (const f of ['invitro_fast.R', 'invitro_grid.R']) {
  await webR.FS.writeFile('/home/web_user/' + f, fs.readFileSync(R + f));
  await webR.evalRVoid(`source('/home/web_user/${f}')`);
}
const ver = await webR.evalRString('R.version.string');
const runs = [];
for (const [lab, nsim, l, n] of [['3x10 n_sim 1000', 1000, 3, 10], ['3x10 n_sim 10000', 10000, 3, 10], ['6x30 n_sim 10000', 10000, 6, 30]]) {
  const t1 = Date.now();
  const res = await webR.evalRString(`{
    a <- invitro_scenario(0.12, pB = 0.1, l = ${l}, n = ${n}, delta = invitro_delta0(0.12), n_sim = ${nsim}, seed = 20261015)
    paste(sprintf('%.17g', c(a$fda_pass, a$ema_c_pass, a$ema_b_pass, a$fda_bias_s2R)), collapse = ' ')
  }`);
  runs.push({ lab, sec: (Date.now() - t1) / 1000, res });
}
console.log(JSON.stringify({ ver, tInit, runs }, null, 1));
await webR.close();
process.exit(0);
