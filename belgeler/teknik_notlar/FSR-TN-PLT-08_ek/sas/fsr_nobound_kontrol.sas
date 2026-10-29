/*============================================================================
  CNK-FarmaStatR - PROC MIXED bound / NOBOUND / TYPE3 check (EMA paths b, c)
  Data: constructed (R, set.seed(2)), 3 batches x 10 containers per product,
  m = 1, log scale. Constructed so that for TEST MS(batch) < MS(container):
  the ANOVA estimate of the batch variance is negative, and default REML
  sets it to 0. For REF the batch variance estimate is positive.
  Question: does NOBOUND or METHOD=TYPE3 give the platform's path (b), and
  what does the default (bounded) REML give compared with path (c)?
  Research and education only; not a system validated for GxP environments.
============================================================================*/

data neg;
  input batch container stage $ product $ score;
  datalines;
1 1 B REF 5.897178
1 2 B REF 5.700171
1 3 B REF 5.772577
1 4 B REF 5.320449
1 5 B REF 5.649807
1 6 B REF 5.787216
1 7 B REF 5.912236
1 8 B REF 5.857406
1 9 B REF 5.2272
1 10 B REF 5.674159
2 1 B REF 6.709263
2 2 B REF 6.196842
2 3 B REF 6.744212
2 4 B REF 5.825651
2 5 B REF 5.911506
2 6 B REF 5.874179
2 7 B REF 5.468337
2 8 B REF 5.612529
2 9 B REF 6.774365
2 10 B REF 5.722945
3 1 B REF 6.571711
3 2 B REF 5.642396
3 3 B REF 5.275073
3 4 B REF 5.932236
3 5 B REF 6.43577
3 6 B REF 6.517117
3 7 B REF 6.730072
3 8 B REF 5.346128
3 9 B REF 6.873922
3 10 B REF 5.780167
4 1 B TEST 5.691234
4 2 B TEST 6.12394
4 3 B TEST 6.685138
4 4 B TEST 5.59785
4 5 B TEST 6.017899
4 6 B TEST 6.102968
4 7 B TEST 6.333182
4 8 B TEST 5.954121
4 9 B TEST 6.84379
4 10 B TEST 5.994485
5 1 B TEST 6.21706
5 2 B TEST 6.442701
5 3 B TEST 5.892922
5 4 B TEST 5.634132
5 5 B TEST 6.762892
5 6 B TEST 5.125572
5 7 B TEST 6.401442
5 8 B TEST 6.064323
5 9 B TEST 6.455131
5 10 B TEST 6.222906
6 1 B TEST 6.886328
6 2 B TEST 5.57003
6 3 B TEST 6.685855
6 4 B TEST 6.831861
6 5 B TEST 6.051975
6 6 B TEST 5.069317
6 7 B TEST 6.240895
6 8 B TEST 5.811377
6 9 B TEST 6.366881
6 10 B TEST 6.165855
;
run;

proc sort data=neg; by product batch container; run;

/* one PROC MIXED run per variant: intercept estimate, SE, df, variance components */
%macro fit(tag, procopt, ddfm);
  ods exclude all;
  proc mixed data=neg &procopt;
    by product;
    class batch;
    model score = / solution ddfm=&ddfm;
    random batch;
    ods output SolutionF=sf_&tag CovParms=cp_&tag;
  run;
  ods exclude none;
  data sf_&tag; length variant $24; set sf_&tag; variant = "&tag"; keep variant product Estimate StdErr DF; run;
  data cp_&tag; length variant $24; set cp_&tag; variant = "&tag"; keep variant product CovParm Estimate; run;
%mend;

%fit(reml_bound_contain,  %str(method=reml),         containment);
%fit(reml_bound_satterth, %str(method=reml),         satterthwaite);
%fit(reml_nobound,       %str(method=reml nobound), containment);
%fit(type3,              %str(method=type3),        containment);

data sf; set sf_reml_bound_contain sf_reml_bound_satterth sf_reml_nobound sf_type3; run;
data cp; set cp_reml_bound_contain cp_reml_bound_satterth cp_reml_nobound cp_type3; run;

/* EMA 90% CI from each variant: SE = sqrt(vT + vR), Welch-Satterthwaite df */
proc sort data=sf; by variant product; run;
data ci;
  set sf; by variant;
  retain gR vR fR;
  if product = 'REF' then do; gR = Estimate; vR = StdErr**2; fR = DF; end;
  else do;
    gT = Estimate; vT = StdErr**2; fT = DF;
    d  = gT - gR;
    se = sqrt(vT + vR);
    nu = (vT + vR)**2 / (vT**2/fT + vR**2/fR);
    q  = tinv(0.95, nu);
    GMR = exp(d); lower = exp(d - q*se); upper = exp(d + q*se);
    length decision $4;
    decision = ifc(lower >= 0.85 and upper <= 1.18, 'PASS', 'FAIL');
    output;
  end;
  keep variant GMR lower upper se nu decision;
run;

title 'Variance components by variant';
proc print data=cp noobs; format Estimate 14.10; run;
title 'Intercept (product mean): estimate, SE, df by variant';
proc print data=sf noobs; format Estimate StdErr 14.10 DF 10.4; run;
title 'EMA 90% CI by variant';
proc print data=ci noobs; var variant GMR lower upper se nu decision; format GMR lower upper se 14.10 nu 12.8; run;
title;

/* Expected (R, CNKfarmastatr 1.0.0.9000 and closed forms):
   Mean squares   REF  MS(batch) 0.5824425674  MS(container) 0.2136827598
                  TEST MS(batch) 0.0056881248  MS(container) 0.2363228621
   ANOVA batch variance (MS(batch) - MS(container))/10:
                  REF   0.0368759808     TEST -0.0230634737  (negative)
   Product means  REF 5.9580940000   TEST 6.1414687333   GMR 1.2012644776

   Intercept SE expected
     NOBOUND / TYPE3 (= path b, v = MS(batch)/30, df 2):
                  REF 0.1393368302   TEST 0.0137696826
     bounded REML, TEST batch variance set to 0
       (v = pooled MS / 30, pooled MS = (2*MS(batch) + 27*MS(container))/29):
                  TEST 0.0857160075   (REF unchanged 0.1393368302)

   EMA 90% CI expected
     reml_nobound, type3 (= platform path b):
            0.80237643274 - 1.7984530530   se 0.14001555773  nu 2.0390602106  FAIL
     reml_bound_contain (TEST df stays 2):
            0.82962405619 - 1.7393858512   se 0.16359091107  nu 3.3241117922  FAIL
     platform path c (TEST pooled df 29, FarmaStatR derivation):
            0.84216137005 - 1.7134914951   se 0.16359091107  nu 3.7630031455  FAIL
     platform path a:
            0.97676405498 - 1.4773643008   se 0.12376476193  nu 57.904138564  FAIL
     reml_bound_satterth: df chosen by SAS; compare with path c.
*/
