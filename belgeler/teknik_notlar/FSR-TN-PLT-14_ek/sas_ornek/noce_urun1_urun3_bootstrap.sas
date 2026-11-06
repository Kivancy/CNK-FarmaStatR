/* ===========================================================================
   CNK-FarmaStatR - bootstrap f2 cross-check in SAS (FSR-TN-PLT-14, KK-80)
   Research and education only; not a system validated for GxP environments.
   platform: CNK-FarmaStatR
   package: 1.0.0.9000
   webR: 0.5.4
   R: R version 4.5.1 (2025-06-13)
   data: Örnek: Noce ve ark. 2020
   data_sha256: example data, no fingerprint
   analysis_started: 2026-11-06T06:19:20.141Z
   csv: farmastatr_bootstrap_2026-11-06T06-19-20.csv
   Recomputes every bootstrap replicate from the units drawn by the platform
   (the companion CSV with the T1... and R1... columns), using the analysis data
   below, and compares f2, Ef2, bc-f2, P and the percentile interval with the
   platform. R and SAS random number generators differ; with the drawn units
   the agreement must be exact up to floating point (criterion BS-7).
   Usage (e.g. SAS OnDemand): upload this program and the CSV to the same folder,
   set CSV below to the full path of the CSV, run. Requires SAS/IML.
   =========================================================================== */
%let csv = C:\cloud\CNK-FarmaStatR\CNK-FarmaStatR\belgeler\teknik_notlar\FSR-TN-PLT-14_ek\sas_ornek\noce_urun1_urun3_bootstrap.csv;   /* full path of the CSV (set by the owner) */
%put &csv;
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
  /* SAS names are not case sensitive: every name below is distinct ignoring case */
  use test_u; read all var _num_ into DATT; close test_u;
  use ref_u;  read all var _num_ into DATR; close ref_u;
  vT = "T1":"T&nT"; vR = "R1":"R&nR";
  use boot; read all var {f2 Ef2 bcf2 P} into PLAT_V; read all var vT into IDXT; read all var vR into IDXR; close boot;
  nrep = nrow(PLAT_V); W = j(nrep, 4, .); cut = 85;
  do ib = 1 to nrep;
    smpT = DATT[IDXT[ib, ], ]; smpR = DATR[IDXR[ib, ], ];
    mT = round(smpT[:, ], 1e-10); mR = round(smpR[:, ], 1e-10);
    npt = ncol(DATT);
    if "&mode" = "replika" & "&rule" ^= "none" then do;
      if "&rule" = "EMA" then a = loc(mT > cut | mR > cut); else a = loc(mT > cut & mR > cut);
      if ncol(a) > 0 then npt = a[1];
    end;
    W[ib, 4] = npt;
    if npt >= 3 then do;
      uT = smpT[, 1:npt]; uR = smpR[, 1:npt];
      dsum = ssq(uT[:, ] - uR[:, ]);
      cT = uT - repeat(uT[:, ], nrow(uT), 1); cR = uR - repeat(uR[:, ], nrow(uR), 1);
      vsum = sum(cT[##, ] / (nrow(uT) - 1) / nrow(uT)) + sum(cR[##, ] / (nrow(uR) - 1) / nrow(uR));
      W[ib, 1] = 100 - 25 * log10(1 + dsum / npt);
      W[ib, 2] = 100 - 25 * log10(1 + (dsum + vsum) / npt);
      if dsum > vsum then W[ib, 3] = 100 - 25 * log10(1 + (dsum - vsum) / npt);
    end;
  end;
  /* largest absolute differences SAS - platform, and differences in undefined values */
  maxd = j(1, 4, 0); n_undef = j(1, 4, 0);
  do k = 1 to 4;
    n_undef[k] = sum((W[, k] = .) ^= (PLAT_V[, k] = .));
    okr = loc((W[, k] ^= .) & (PLAT_V[, k] ^= .));
    if ncol(okr) > 0 then maxd[k] = max(abs(W[okr, k] - PLAT_V[okr, k]));
  end;
  print nrep[label = 'Replicates read from the CSV'];
  print maxd[colname = {'f2' 'Ef2' 'bcf2' 'P'} label = 'Largest |SAS - platform| over the replicates'];
  print n_undef[colname = {'f2' 'Ef2' 'bcf2' 'P'} label = 'Replicates where only one side is undefined'];
  /* percentile interval of the estimator (Hyndman-Fan continuous types 4-9) */
  col = ("&est" = "f2") * 1 + ("&est" = "Ef2") * 2 + ("&est" = "bcf2") * 3;
  est_v = W[loc(W[, col] ^= .), col]; call sort(est_v, 1); nv = nrow(est_v);
  a2 = (1 - &conf) / 2; pr = a2 || (1 - a2); qs = j(1, 2, .);
  if &qa ^= . then do i = 1 to 2;
    hm = &qa + pr[i] * (1 - &qa - &qb); jj = floor(nv * pr[i] + hm + 4 * constant('maceps')); gg = nv * pr[i] + hm - jj;
    if abs(gg) < 4 * constant('maceps') then gg = 0;
    lo = max(1, min(nv, jj)); hi = max(1, min(nv, jj + 1));
    qs[i] = (1 - gg) * est_v[lo] + gg * est_v[hi];
  end;
  plat = &p_lo || &p_hi; dq = abs(qs - plat);
  print qs[colname = {'lower' 'upper'} label = 'SAS percentile interval'],
        plat[colname = {'lower' 'upper'} label = 'Platform percentile interval'],
        dq[colname = {'lower' 'upper'} label = '|difference|'];
  ok_rep = (nrep = &B) & (max(maxd[1:3]) <= 1e-10) & (maxd[4] = 0) & (sum(n_undef) = 0);
  ok_ci = (max(dq) <= 1e-8);
  result = ifc(ok_rep & ok_ci, 'AGREE: replicates and interval equal the platform (BS-7)',
                               'DIFFERENT: see the tables above');
  print result[label = 'Result'];
quit;
