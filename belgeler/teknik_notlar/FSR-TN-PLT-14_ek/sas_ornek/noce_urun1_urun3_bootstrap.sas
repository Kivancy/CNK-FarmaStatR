/* ===========================================================================
   CNK-FarmaStatR - bootstrap f2 cross-check in SAS (FSR-TN-PLT-14, KK-80)
   Research and education only; not a system validated for GxP environments.
   platform: CNK-FarmaStatR
   package: 1.0.0.9000
   webR: 0.5.4
   R: R version 4.5.1 (2025-06-13)
   data: Örnek: Noce ve ark. 2020
   data_sha256: example data, no fingerprint
   analysis_started: 2026-11-05T19:30:08.536Z
   csv: farmastatr_bootstrap_2026-11-05T19-30-10.csv
   Recomputes every bootstrap replicate from the units drawn by the platform
   (the companion CSV with the T1... and R1... columns), using the analysis data
   below, and compares f2, Ef2, bc-f2, P and the percentile interval with the
   platform. R and SAS random number generators differ; with the drawn units
   the agreement must be exact up to floating point (criterion BS-7).
   Usage (e.g. SAS OnDemand): upload this program and the CSV to the same folder,
   set CSV below to the full path of the CSV, run. Requires SAS/IML.
   =========================================================================== */
%let csv = noce_urun1_urun3_bootstrap.csv;   /* full path, e.g. /home/u12345/<file>.csv */
%let nT = 12; %let nR = 12; %let nP = 9; %let B = 5000;
%let rule = EMA;     /* EMA, FDA or none */
%let mode = replika;     /* replika: truncation in every replicate; sabit: fixed time points */
%let est = Ef2;      /* f2, Ef2 or bcf2 */
%let qa = 1; %let qb = 1;   /* Hyndman-Fan type 7 (alpha, beta); . = type not reproduced here */
%let conf = 0.90000000000000002;
%let p_lo = 35.616397988118621; %let p_hi = 57.504593767305423;   /* platform percentile interval of the estimator */

/* analysis data: rows = units, columns = time points (minutes): 120 130 135 140 150 165 180 210 240 */
data test_u; input x1-x&nP; datalines;
3.7 17.5 38.4 59.5 75.5 83.2 86.5 90.5 93.6
4 66.6 78.1 84.7 89.2 92.2 94.7 96.5 97.5
4 15.6 34.9 57.4 76.1 85.4 89.1 92.2 93.3
5.1 50 65 73.3 78.1 81.6 82.1 84.8 86.5
4.6 25.8 51.9 70.8 84.6 85.9 92.7 95 97.4
5 41.3 59.9 71.5 79.5 83.6 85.7 88.3 88.9
2.8 24.4 39 78.5 67.3 77 83.2 85.8 89.5
4.2 47.3 65.3 52.7 86.5 89.7 92.1 94.4 96.7
3.1 42 65.3 77.8 86.2 92.7 94.9 96.4 99.6
5.6 76.6 82.7 86.1 88.6 90.6 91.6 92.8 85.5
2.9 20.2 40.9 61.1 78 85.8 87.3 89.8 92.5
3.6 67.8 81.3 84.1 88.4 90.3 91 93.4 94.5
;
run;
data ref_u; input x1-x&nP; datalines;
5.7 22.1 38.2 56.3 70.5 81.8 85.1 88 90.3
4.3 20.3 39.3 56.1 70.6 82.3 83.7 88.7 90.2
3.2 27.5 46 64.7 77.3 84.5 86 87.6 87.3
3.4 43.2 61.6 72.8 80.5 83.1 86.7 86.4 88.1
3.9 14.5 32.3 47.1 67.8 77.8 82.2 86.3 88.3
2.4 6.5 20.7 42.3 66.5 78.5 84.7 86.6 88.7
1.8 10.3 30.4 50.8 75.8 85.7 86.5 89.5 90.8
4.1 28.8 50 63 77.9 83.4 87.4 88.8 87.9
2.7 16.4 37.8 60.3 81.5 86.1 87.7 88.4 89.7
2.6 15.9 34.7 53.7 69.7 78.9 82.4 85.6 86.7
2.7 20.7 43.8 64.1 78.3 84.8 86.2 90.2 90.5
3.5 42.7 63.9 72 80.1 82.1 86.3 86.4 88.1
;
run;

data boot;
  infile "&csv" dsd truncover lrecl=1000000;
  input @1 first $1. @;
  if first in ('#', 'r', ' ') then delete;   /* header, column names, empty lines */
  input @1 rep f2 Ef2 bcf2 P T1-T&nT R1-R&nR;
  drop first;
run;

proc iml;
  use test_u; read all var _num_ into XT; close test_u;
  use ref_u;  read all var _num_ into XR; close ref_u;
  vT = "T1":"T&nT"; vR = "R1":"R&nR";
  use boot; read all var {f2 Ef2 bcf2 P} into V; read all var vT into IT; read all var vR into IR; close boot;
  B = nrow(V); W = j(B, 4, .); cut = 85;
  do b = 1 to B;
    xt = XT[IT[b, ], ]; xr = XR[IR[b, ], ];
    mT = round(xt[:, ], 1e-10); mR = round(xr[:, ], 1e-10);
    np = ncol(XT);
    if "&mode" = "replika" & "&rule" ^= "none" then do;
      if "&rule" = "EMA" then a = loc(mT > cut | mR > cut); else a = loc(mT > cut & mR > cut);
      if ncol(a) > 0 then np = a[1];
    end;
    W[b, 4] = np;
    if np >= 3 then do;
      t = xt[, 1:np]; r = xr[, 1:np];
      D = ssq(t[:, ] - r[:, ]);
      ct = t - repeat(t[:, ], nrow(t), 1); cr = r - repeat(r[:, ], nrow(r), 1);
      Vr = sum(ct[##, ] / (nrow(t) - 1) / nrow(t)) + sum(cr[##, ] / (nrow(r) - 1) / nrow(r));
      W[b, 1] = 100 - 25 * log10(1 + D / np);
      W[b, 2] = 100 - 25 * log10(1 + (D + Vr) / np);
      if D > Vr then W[b, 3] = 100 - 25 * log10(1 + (D - Vr) / np);
    end;
  end;
  /* largest absolute differences SAS - platform, and differences in undefined values */
  maxd = j(1, 4, 0); nmiss = j(1, 4, 0);
  do k = 1 to 4;
    nmiss[k] = sum((W[, k] = .) ^= (V[, k] = .));
    ok = loc((W[, k] ^= .) & (V[, k] ^= .));
    if ncol(ok) > 0 then maxd[k] = max(abs(W[ok, k] - V[ok, k]));
  end;
  print maxd[colname = {'f2' 'Ef2' 'bcf2' 'P'} label = 'Largest |SAS - platform| over the replicates'];
  print nmiss[colname = {'f2' 'Ef2' 'bcf2' 'P'} label = 'Replicates where only one side is undefined'];
  /* percentile interval of the estimator (Hyndman-Fan continuous types 4-9) */
  col = ("&est" = "f2") * 1 + ("&est" = "Ef2") * 2 + ("&est" = "bcf2") * 3;
  v = W[loc(W[, col] ^= .), col]; call sort(v, 1); n = nrow(v);
  a2 = (1 - &conf) / 2; pr = a2 || (1 - a2); q = j(1, 2, .);
  if &qa ^= . then do i = 1 to 2;
    m = &qa + pr[i] * (1 - &qa - &qb); jj = floor(n * pr[i] + m + 4 * constant('maceps')); g = n * pr[i] + m - jj;
    if abs(g) < 4 * constant('maceps') then g = 0;
    lo = max(1, min(n, jj)); hi = max(1, min(n, jj + 1));
    q[i] = (1 - g) * v[lo] + g * v[hi];
  end;
  plat = &p_lo || &p_hi; dq = abs(q - plat);
  print q[colname = {'lower' 'upper'} label = 'SAS percentile interval'],
        plat[colname = {'lower' 'upper'} label = 'Platform percentile interval'],
        dq[colname = {'lower' 'upper'} label = '|difference|'];
  ok_rep = (max(maxd[1:3]) <= 1e-10) & (maxd[4] = 0) & (sum(nmiss) = 0);
  ok_ci = (max(dq) <= 1e-8);
  result = ifc(ok_rep & ok_ci, 'AGREE: replicates and interval equal the platform (BS-7)',
                               'DIFFERENT: see the tables above');
  print result[label = 'Result'];
quit;
