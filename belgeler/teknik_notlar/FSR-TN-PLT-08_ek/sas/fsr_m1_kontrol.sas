/*============================================================================
  CNK-FarmaStatR - m = 1 cross-check in SAS (P2_m1 data)
  FDA PBE (PSG 020929, Appendix A, Steps 1-5) and EMA OIP Rev. 2 Section 5.1
  criterion 8 (90% CI, paths a, b, c).
  Data: FDA PSG 020929 Appendix B example, stage B only (simulated data per the
  PSG); 3 batches x 10 containers per product, 1 value per container (log scale).
  Written from the formulas in the guidance and the technical note, not
  translated from the R code. Expected values (R, CNKfarmastatr 1.0.0.9000)
  are printed next to the SAS values at the end.
  Research and education only; not a system validated for GxP environments.
============================================================================*/

data p2;
  input batch container stage $ product $ score;
  datalines;
1 31 B REF 5.957211
1 32 B REF 6.010251
1 33 B REF 5.884161
1 34 B REF 5.624705
1 35 B REF 5.957329
1 36 B REF 5.074298
1 37 B REF 5.418587
1 38 B REF 6.325178
1 39 B REF 5.656286
1 40 B REF 5.792299
2 41 B REF 5.601033
2 42 B REF 5.61553
2 43 B REF 5.682466
2 44 B REF 5.844336
2 45 B REF 5.898151
2 46 B REF 6.100662
2 47 B REF 6.294753
2 48 B REF 5.638072
2 49 B REF 5.113562
2 50 B REF 5.932752
3 51 B REF 5.961947
3 52 B REF 6.2334
3 53 B REF 6.041431
3 54 B REF 6.049713
3 55 B REF 6.834563
3 56 B REF 4.864966
3 57 B REF 5.895176
3 58 B REF 6.45826
3 59 B REF 6.090533
3 60 B REF 5.886724
4 1 B TEST 6.894594
4 2 B TEST 5.832334
4 3 B TEST 6.235755
4 4 B TEST 5.646185
4 5 B TEST 5.960711
4 6 B TEST 5.500354
4 7 B TEST 6.663099
4 8 B TEST 5.724774
4 9 B TEST 6.183375
4 10 B TEST 5.64053
5 11 B TEST 6.69764
5 12 B TEST 6.555609
5 13 B TEST 5.009683
5 14 B TEST 5.440976
5 15 B TEST 6.477609
5 16 B TEST 6.442601
5 17 B TEST 5.640496
5 18 B TEST 6.597718
5 19 B TEST 6.007241
5 20 B TEST 6.781806
6 21 B TEST 5.993852
6 22 B TEST 6.012322
6 23 B TEST 5.965969
6 24 B TEST 5.592609
6 25 B TEST 6.002182
6 26 B TEST 5.267014
6 27 B TEST 5.766104
6 28 B TEST 6.054975
6 29 B TEST 5.838689
6 30 B TEST 5.784255
;
run;

/*---------------------------------------------------------------------------
  1. FDA PBE with m = 1
     With one stage, each container mean is its single value, MSW does not
     exist and the E2, E4 terms (and their H, U) drop out.
     MSB_k = m * sum (Ubar_ij - gbar)^2 / (N_k - 1),  N_k = l_k * n_k
     sigma_k^2 = MSB_k / m
---------------------------------------------------------------------------*/
proc means data=p2 noprint nway;
  class product;
  var score;
  output out=ms(drop=_type_ _freq_) n=N mean=gbar var=s2;
run;

data pbe;
  set ms end=last;
  retain NT gT msbT NR gR msbR;
  m = 1;
  if product = 'TEST' then do; NT = N; gT = gbar; msbT = m * s2; end;
  else do;                     NR = N; gR = gbar; msbR = m * s2; end;
  if last then do;
    alpha  = 0.05;
    sT0    = 0.1;
    thetap = ((log(1.11))**2 + 0.01) / sT0**2;         /* Step 1 */
    sigT   = sqrt(msbT / m);
    sigR   = sqrt(msbR / m);
    delta  = gT - gR;
    /* Step 4: point estimates */
    E_D  = delta**2;
    E1   = msbT / m;
    E3s  = -(1 + thetap) * msbR / m;
    E3c  = -msbR / m;
    /* Step 4: confidence bounds */
    tq   = tinv(1 - alpha, NT + NR - 2);
    H_D  = (abs(delta) + tq * sqrt(msbT/(NT*m) + msbR/(NR*m)))**2;
    H1   = (NT - 1) * E1  / cinv(alpha,     NT - 1);
    H3s  = (NR - 1) * E3s / cinv(1 - alpha, NR - 1);
    H3c  = (NR - 1) * E3c / cinv(1 - alpha, NR - 1);
    U_D  = (H_D - E_D)**2;  U1 = (H1 - E1)**2;
    U3s  = (H3s - E3s)**2;  U3c = (H3c - E3c)**2;
    Eq_ref  = E_D + E1 + E3s;
    Uq_ref  = U_D + U1 + U3s;
    H_ref   = Eq_ref + sqrt(Uq_ref);
    Eq_con  = E_D + E1 + E3c - thetap * sT0**2;
    H_con   = Eq_con + sqrt(U_D + U1 + U3c);
    /* Step 3 and 5 */
    if sigR > sT0 then do; criterion = 'reference-scaled'; H_eta = H_ref; end;
    else do;               criterion = 'constant-scaled '; H_eta = H_con; end;
    length decision $4;
    decision = ifc(H_eta <= 0, 'PASS', 'FAIL');
    GMR = exp(delta);
    output;
  end;
  keep thetap gT gR msbT msbR sigT sigR E_D E1 E3s H_D H1 H3s U_D U1 U3s
       Eq_ref Uq_ref H_ref H_con criterion H_eta decision GMR;
run;

/*---------------------------------------------------------------------------
  2. EMA 90% CI of exp(mu_T - mu_R), limits 0.85-1.18
     (a) pooled units:  v = var(unit means)/N,          df = N - 1
     (b) batch means:   v = var(batch means)/l,         df = l - 1
     (c) mixed model, random batch (REML, PROC MIXED):  v = SE(intercept)^2,
         df = containment df of the intercept (l - 1). If REML puts the batch
         variance at 0, SAS keeps df = l - 1 while the platform pools the df
         (FarmaStatR derivation); in these data there is no pooling.
     Combined: SE = sqrt(vT + vR), df by Welch-Satterthwaite.
     Paths a, b, c are candidate implementations (FarmaStatR derivation).
---------------------------------------------------------------------------*/
proc means data=p2 noprint nway;
  class product batch;
  var score;
  output out=bm(drop=_type_ _freq_) mean=bmean;
run;
proc means data=bm noprint nway;
  class product;
  var bmean;
  output out=bv(drop=_type_ _freq_) n=L var=s2b;
run;

proc sort data=p2 out=p2s; by product batch; run;
ods exclude all;
proc mixed data=p2s method=reml;
  by product;
  class batch;
  model score = / solution ddfm=containment;
  random batch;
  ods output SolutionF=solf CovParms=cp;
run;
ods exclude none;

data ema_in;
  merge ms bv solf(keep=product StdErr DF rename=(StdErr=seC DF=dfC));
  by product;
  vA = s2 / N;     dfA = N - 1;
  vB = s2b / L;    dfB = L - 1;
  vC = seC**2;
run;

data ema;
  set ema_in end=last;
  retain gT gR vAT vAR dAT dAR vBT vBR dBT dBR vCT vCR dCT dCR;
  if product = 'TEST' then do; gT = gbar; vAT = vA; dAT = dfA; vBT = vB; dBT = dfB; vCT = vC; dCT = dfC; end;
  else do;                     gR = gbar; vAR = vA; dAR = dfA; vBR = vB; dBR = dfB; vCR = vC; dCR = dfC; end;
  if last then do;
    d = gT - gR;
    length path $1;
    array vt{3} vAT vBT vCT;  array vr{3} vAR vBR vCR;
    array ft{3} dAT dBT dCT;  array fr{3} dAR dBR dCR;
    do k = 1 to 3;
      path  = substr('abc', k, 1);
      se    = sqrt(vt{k} + vr{k});
      df    = (vt{k} + vr{k})**2 / (vt{k}**2/ft{k} + vr{k}**2/fr{k});
      q     = tinv(0.95, df);
      GMR   = exp(d);
      lower = exp(d - q*se);
      upper = exp(d + q*se);
      length decision $4;
      decision = ifc(lower >= 0.85 and upper <= 1.18, 'PASS', 'FAIL');
      output;
    end;
  end;
  keep path GMR lower upper se df decision;
run;

/*---------------------------------------------------------------------------
  3. Results and the expected values from R
---------------------------------------------------------------------------*/
title 'FDA PBE, m = 1 (P2_m1)';
proc print data=pbe noobs;
  var thetap gT gR msbT msbR sigT sigR criterion;
  format thetap gT gR msbT msbR sigT sigR 14.10;
run;
proc print data=pbe noobs;
  var E_D E1 E3s H_D H1 H3s U_D U1 U3s Eq_ref Uq_ref H_eta H_con decision;
  format E_D E1 E3s H_D H1 H3s U_D U1 U3s Eq_ref Uq_ref H_eta H_con 14.10;
run;
title 'EMA 90% CI, m = 1 (P2_m1)';
proc print data=ema noobs;
  var path GMR lower upper se df decision;
  format GMR lower upper se 14.10 df 12.8;
run;
title 'PROC MIXED variance components (path c)';
proc print data=cp noobs; run;
title;

/* Expected (R, CNKfarmastatr 1.0.0.9000):
   thetap 2.0891012798   gT 6.0070353667   gR 5.8579445000
   msbT   0.2200857931   msbR 0.1642159927  sigT 0.4691330229  sigR 0.4052357249
   criterion reference-scaled
   E_D 0.0222280865  E1 0.2200857931  E3s -0.5072798333
   H_D 0.1144332039  H1 0.3604221832  H3s -0.3456805295
   U_D 0.0085017837  U1 0.0196943024  U3s  0.0261143350
   Eq_ref -0.2649659536  Uq_ref 0.0543104210
   H_eta  -0.0319199903  (PASS)       H_con 0.2330838402
   EMA (GMR 1.1607784605):
     a  0.9606328792 - 1.402623899   se 0.1131815335  df 56.79952224  FAIL
     b  0.8770732888 - 1.536253186   se 0.1309218568  df  3.94362885  FAIL
     c  0.8770732888 - 1.536253186   se 0.1309218568  df  3.94362885  FAIL
*/
