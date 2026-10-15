/* ===========================================================================
   FSR-TN-PBE-01 Ek B - Independent SAS cross-check (SAS OnDemand is enough)
   Input : sas_veri.csv  (from r_beklenen.R; 11 data sets K01-K11, log scale)
   Output: 4 CSV files to send back for comparison with r_beklenen.csv
     sas_glm_ss.csv     PROC GLM type I SS  -> PSG MSB/MSW and EMS mean squares
     sas_covparms.csv   PROC MIXED REML variance components (per product)
     sas_diffs_sat.csv  T-R difference, SE, df, 90% CI (ddfm=satterthwaite)
     sas_diffs_kr.csv   same with ddfm=kenwardroger
   Model (TN Eq. 8, per product k): y = mu_k + tau_ks + b_jk + c_ijk + e_ijks
   Research and education only; not a system validated for GxP environments.
   =========================================================================== */

/* 1. Folder of sas_veri.csv; the output CSV files are written to the same
      folder. Default: this folder in the local repository (SAS for Windows).
      SAS OnDemand: upload sas_veri.csv and use the folder path shown under
      "Server Files and Folders" > Properties, e.g. /home/uXXXXXXXX/fsr.     */
%let yol = C:/cloud/CNK-FarmaStatR/CNK-FarmaStatR/belgeler/teknik_notlar/FSR-TN-PBE-01_ek/sas;

proc import datafile="&yol./sas_veri.csv" out=veri dbms=csv replace;
  guessingrows=max;
run;
proc sort data=veri; by set product; run;

/* 2. PSG mean squares: one GLM per data set and product.
      MSB_PSG = (SS_batch + SS_unit(batch)) / (N - 1)
      MSW_PSG = (SS_stage + SS_error)       / (N (m - 1))
      MS_lot = SS_batch/(l-1); MS_unit = SS_unit(batch)/(l(n-1));
      MS_res = SS_error/((N-1)(m-1))   (Searle et al. 2006, Table 4.10)     */
ods exclude all;
proc glm data=veri;
  by set product;
  class batch unit stage;
  model y = batch unit(batch) stage / ss1;
  ods output ModelANOVA=ss_model OverallANOVA=ss_all;
run; quit;
ods exclude none;
data ss_err; set ss_all; where source = "Error"; keep set product df ss ms; run;
data sas_glm_ss;
  set ss_model(keep=set product source df ss ms) ss_err(in=e);
  if e then source = "Error";
run;
proc export data=sas_glm_ss outfile="&yol./sas_glm_ss.csv" dbms=csv replace; run;

/* 3. EMA method (c): REML, batch and unit random, stage fixed within product,
      separate variances for T and R. lsmeans = product means (balanced).   */
%macro mixed(ddfm, tag);
  ods exclude all;
  proc mixed data=veri method=reml;
    by set;
    class product batch unit stage;
    model y = product stage(product) / ddfm=&ddfm;
    random batch unit(batch) / group=product;
    repeated / group=product;
    lsmeans product / diff cl alpha=0.10;
    ods output CovParms=cp_&tag Diffs=dif_&tag LSMeans=lsm_&tag;
  run;
  ods exclude none;
  proc export data=dif_&tag outfile="&yol./sas_diffs_&tag..csv" dbms=csv replace; run;
%mend;
%mixed(satterthwaite, sat);
%mixed(kenwardroger, kr);
proc export data=cp_sat outfile="&yol./sas_covparms.csv" dbms=csv replace; run;

/* 4. Quick look in the Results window */
proc print data=dif_sat noobs; var set product _product estimate stderr df lower upper; run;
proc print data=cp_sat noobs; run;
