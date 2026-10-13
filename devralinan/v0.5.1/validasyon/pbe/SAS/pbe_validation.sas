/* =============================================================================
   CNK-FarmaStatR - PBE modulu - SAS dogrulama programi (surum 0.1)
   Test edilen: pbe_core.R (PBE_webr_v05_3 gomulu kodu; SHA-256 e7be66b8...)
   Kaynak: FDA PSG_020929 (Budesonide, Aralik 2025), Appendix

   Hesap SAS/IML KULLANILMADAN, PROC SQL ve DATA adimiyla yeniden kurulmustur
   (R ve Python'dan bagimsiz ucuncu hesaplama yolu).
     - Kap = Parti + Kap numarasi (ayni kap numarasi farkli partilerde tekrar edebilir)
     - MSB = m * SUM(kap ort - genel ort)^2 / (N_kap - 1)
     - MSW = SUM(y - kap ort)^2 / (N_kap * (m - 1)),  m = 1 ise 0
   Kontroller:
     (Y) PSG_020929 yayimlanan 27 deger, goreli tolerans 5e-5
     (B) Bagimsiz Python referansi (pbe_referans.py), mutlak tolerans 1e-10

   Once test_verisi klasorundeki CSV dosyalarini YOL klasorune kopyalayin.
   Kodlama kurallari: ASCII; sas_case_check.py ile taranmistir.
   ============================================================================= */

%let YOL = C:/CNK-FarmaStatR/PBE/test_verisi;   /* <-- CSV klasoru */
options nodate nonumber ls=160 nonotes;
title "CNK-FarmaStatR PBE - SAS dogrulama (v0.1)";

%macro dosya_kontrol;
  %if not %sysfunc(fileexist(&YOL/P1_psg020929.csv)) %then %do;
    %put ERROR: [CNK-FarmaStatR] Test verisi bulunamadi: &YOL/P1_psg020929.csv;
    %abort cancel;
  %end;
%mend;
%dosya_kontrol;

/* ---- Beklenen degerler ---- */
data beklenen_b;
  length senaryo $12 alan $12;
  input senaryo $ alan $ beklenen;
  datalines;
P1 E_D 0.022094103940287813
P1 E1 0.21974291361855539
P1 E2 3.9108250200000176e-05
P1 E3s -0.5055152949072995
P1 E4s -0.0002566691099138148
P1 E3c -0.1636447785655755
P1 E4c -8.308860301481468e-05
P1 H_D 0.11397688339756053
P1 H1 0.35986066863237015
P1 H2 5.433215868492246e-05
P1 H3s -0.34447810332090784
P1 H4s -0.00019473656970075113
P1 H3c -0.11151402045901856
P1 H4c -6.303987861167089e-05
P1 U_D 0.008442445160793817
P1 U1 0.019632985270111415
P1 U2 2.317673895572888e-10
P1 U3s 0.02593297707403222
P1 U4s 3.83563953724275e-09
P1 U3c 0.002717615940764351
P1 U4c 4.0195135019321327e-10
P1 Eq_Ref -0.2638958382081701
P1 Uq_Ref 0.05400841157234438
P1 H_eta_Ref -0.03149873931848002
P1 Eq_Const 0.05725724584197671
P1 Uq_Const 0.030793047005388326
P1 H_eta_Const 0.2327367232898775
P1 Sigma_R 0.40463300306399913
P1 KRITER 1
P1 KARAR 1
P2 E_D 0.022228086523417758
P2 E1 0.22008579314410226
P2 E2 0.0
P2 E3s -0.5072798333049026
P2 E4s -0.0
P2 E3c -0.16421599272715523
P2 E4c -0.0
P2 H_D 0.11443320392400047
P2 H1 0.36042218323728636
P2 H2 0.0
P2 H3s -0.3456805295314831
P2 H4s 0.0
P2 H3c -0.11190326836695202
P2 H4c 0.0
P2 U_D 0.00850178367485524
P2 U1 0.019694302384386343
P2 U2 0.0
P2 U3s 0.026114334980053902
P2 U4s 0.0
P2 U3c 0.0027366211299865977
P2 U4c 0.0
P2 Eq_Ref -0.2649659536373825
P2 Uq_Ref 0.05431042103929548
P2 H_eta_Ref -0.03191999027544079
P2 Eq_Const 0.05720687414188859
P2 Uq_Const 0.03093270718922818
P2 H_eta_Const 0.2330838401983571
P2 Sigma_R 0.40523572489003884
P2 KRITER 1
P2 KARAR 1
P3 E_D 0.024832375237038424
P3 E1 0.22978562416768075
P3 E2 3.877879807936505e-05
P3 E3s -0.523139314831583
P3 E4s -0.00025620324841001975
P3 E3c -0.16935000423728053
P3 E4c -8.293779491187737e-05
P3 H_D 0.12664055334913651
P3 H1 0.38412852426351807
P3 H2 5.456138148582423e-05
P3 H3s -0.35435207830851073
P3 H4s -0.00019354276622862696
P3 H3c -0.1147104112837603
P3 H4c -6.265342204583662e-05
P3 U_D 0.01036490513050469
P3 U1 0.02382173080999362
P3 U2 2.490899389818405e-10
P3 U3s 0.028489131213095556
P3 U4s 3.926336027204644e-09
P3 U3c 0.0029854851181263767
P3 U4c 4.1145578256857014e-10
P3 Eq_Ref -0.26873873987719454
P3 Uq_Ref 0.06267577132901983
P3 H_eta_Ref -0.018387444036690015
P3 Eq_Const 0.06433282337212992
P3 Uq_Const 0.037172121719170406
P3 H_eta_Const 0.25713355397025395
P3 Sigma_R 0.4116223293653934
P3 KRITER 1
P3 KARAR 1
P4_tekyon E_D 0.0
P4_tekyon H_D 0.0
P4_tekyon U_D 0.0
P4_tekyon Eq_Ref -0.2859899421484578
P4_tekyon Uq_Ref 0.04556596641155058
P4_tekyon H_eta_Ref -0.07252808042240946
P4_tekyon H_eta_Const 0.18466431863483218
P4_tekyon Sigma_R 0.40463300306399913
P4_tekyon KRITER 1
P4_tekyon KARAR 1
P4_iki E_D 0.022909590606953856
P4_iki H_D 0.11581968629863172
P4_iki U_D 0.008632285881436738
P4_iki Eq_Ref -0.26308035154150394
P4_iki Uq_Ref 0.05419825229298732
P4_iki H_eta_Ref -0.030275170557516135
P4_iki H_eta_Const 0.23409229882452504
P4_iki Sigma_R 0.40463300306399913
P4_iki KRITER 1
P4_iki KARAR 1
P5_exp E_D 0.022094103940287813
P5_exp H_D 0.11397688339756046
P5_exp U_D 0.008442445160793805
P5_exp Eq_Ref -0.2638958382081708
P5_exp Uq_Ref 0.05400841157234434
P5_exp H_eta_Ref -0.03149873931848085
P5_exp H_eta_Const 0.23273672328987688
P5_exp Sigma_R 0.4046330030639992
P5_exp KRITER 1
P5_exp KARAR 1
P5_kap E_D 0.022094103940287813
P5_kap H_D 0.11397688339756053
P5_kap U_D 0.008442445160793817
P5_kap Eq_Ref -0.2638958382081701
P5_kap Uq_Ref 0.05400841157234438
P5_kap H_eta_Ref -0.03149873931848002
P5_kap H_eta_Const 0.2327367232898775
P5_kap Sigma_R 0.40463300306399913
P5_kap KRITER 1
P5_kap KARAR 1
P6_esit E_D 0.0
P6_esit H_D 0.007918634289896677
P6_esit U_D 6.270476901712744e-05
P6_esit Eq_Ref -0.0294410127984762
P6_esit Uq_Ref 0.00042698402157618766
P6_esit H_eta_Ref -0.008777421107383686
P6_esit H_eta_Const -0.01755853438667144
P6_esit Sigma_R 0.1
P6_esit KRITER 0
P6_esit KARAR 1
P6_ustu E_D 0.0
P6_ustu H_D 0.007920017526616608
P6_ustu U_D 6.272667762191425e-05
P6_ustu Eq_Ref -0.02944719130994602
P6_ustu Uq_Ref 0.0004271336476202853
P6_ustu H_eta_Ref -0.008779979412346352
P6_ustu H_eta_Const -0.01755904951031443
P6_ustu Sigma_R 0.10001
P6_ustu KRITER 1
P6_ustu KARAR 1
;
run;
data beklenen_y;
  length senaryo $12 alan $12;
  input senaryo $ alan $ beklenen;
  datalines;
P1 E_D 0.022094106
P1 H_D 0.113976896
P1 U_D 0.008442447
P1 E1 0.219742944
P1 H1 0.359860715
P1 U1 0.01963299
P1 E2 3.9108e-05
P1 H2 5.43319e-05
P1 U2 2.31765e-10
P1 E3s -0.505515326
P1 H3s -0.344478125
P1 U3s 0.02593298
P1 E4s -0.000256672
P1 H4s -0.000194739
P1 U4s 3.83572e-09
P1 Eq_Ref -0.26389584
P1 Uq_Ref 0.054008421
P1 H_eta_Ref -0.031498721
P1 E3c -0.163644789
P1 H3c -0.111514028
P1 U3c 0.002717616
P1 E4c -8.30895e-05
P1 H4c -6.30405e-05
P1 U4c 4.0196e-10
P1 Eq_Const 0.057257267
P1 Uq_Const 0.030793054
P1 H_eta_Const 0.232736764
;
run;

/* ---- PBE hesabi: tek senaryo ---- */
%macro pbe_hesap(senaryo=, dosya=, logd=0, tekyon=0);
  proc import datafile="&YOL/&dosya..csv" out=ham dbms=csv replace; getnames=yes; guessingrows=max; run;
  data g;
    set ham;
    length kap $40 urun $8 asama $8;
    urun = strip(Product); asama = strip(Stage);
    kap = catx("_", Batches, Container);
    y = score;
    %if &logd = 1 %then %do; y = log(score); %end;
  run;
  proc sql noprint;
    select count(distinct asama) into :m_asama trimmed from g;
    create table kapo as select urun, kap, mean(y) as kort from g group by urun, kap;
    create table geno as select urun, mean(y) as gort from g group by urun;
    create table ssb as select k.urun, count(*) as nkap, sum((k.kort - e.gort)**2) as skare
      from kapo k inner join geno e on k.urun = e.urun group by k.urun;
    create table ssw as select g.urun, sum((g.y - k.kort)**2) as ssw
      from g inner join kapo k on g.urun = k.urun and g.kap = k.kap group by g.urun;
    create table ozet as select a.urun, a.nkap, a.skare, b.ssw, e.gort
      from ssb a, ssw b, geno e where a.urun = b.urun and a.urun = e.urun;
  quit;
  data sonuc;
    set ozet end = son;
    retain nT nR sbT sbR swT swR muT muR;
    if urun = "TEST" then do; nT = nkap; sbT = skare; swT = ssw; muT = gort; end;
    if urun = "REF"  then do; nR = nkap; sbR = skare; swR = ssw; muR = gort; end;
    if son then do;
      m = &m_asama; alfa = 0.05; s0 = 0.1;
      th = (log(1.11)**2 + 0.01) / s0**2;
      msbT = m * sbT / (nT - 1); msbR = m * sbR / (nR - 1);
      if m > 1 then do; mswT = swT / (nT * (m - 1)); mswR = swR / (nR * (m - 1)); end;
      else do; mswT = 0; mswR = 0; end;
      aktif = (&tekyon = 1 and muT < muR);
      if aktif then E_D = 0; else E_D = (muT - muR)**2;
      E1 = msbT / m;   E2 = mswT * (m - 1) / m;
      E3s = -(1 + th) * msbR / m;  E4s = -(1 + th) * mswR * (m - 1) / m;
      E3c = -msbR / m;             E4c = -mswR * (m - 1) / m;
      tq = quantile("T", 1 - alfa, nT + nR - 2);
      if aktif then H_D = 0;
      else H_D = (sqrt(E_D) + tq * sqrt(msbT / (nT * m) + msbR / (nR * m)))**2;
      H1  = (nT - 1) * E1  / quantile("CHISQ", alfa,     nT - 1);
      H3s = (nR - 1) * E3s / quantile("CHISQ", 1 - alfa, nR - 1);
      H3c = (nR - 1) * E3c / quantile("CHISQ", 1 - alfa, nR - 1);
      if m > 1 then do;
        H2  = nT * (m - 1) * E2  / quantile("CHISQ", alfa,     nT * (m - 1));
        H4s = nR * (m - 1) * E4s / quantile("CHISQ", 1 - alfa, nR * (m - 1));
        H4c = nR * (m - 1) * E4c / quantile("CHISQ", 1 - alfa, nR * (m - 1));
      end;
      else do; H2 = 0; H4s = 0; H4c = 0; end;
      U_D = (H_D - E_D)**2; U1 = (H1 - E1)**2; U2 = (H2 - E2)**2;
      U3s = (H3s - E3s)**2; U4s = (H4s - E4s)**2; U3c = (H3c - E3c)**2; U4c = (H4c - E4c)**2;
      Eq_Ref = E_D + E1 + E2 + E3s + E4s;  Uq_Ref = U_D + U1 + U2 + U3s + U4s;
      Eq_Const = E_D + E1 + E2 + E3c + E4c - th * s0**2;  Uq_Const = U_D + U1 + U2 + U3c + U4c;
      H_eta_Ref = Eq_Ref + sqrt(Uq_Ref);  H_eta_Const = Eq_Const + sqrt(Uq_Const);
      Sigma_R = sqrt(msbR / m + (m - 1) * mswR / m);
      KRITER = (Sigma_R > s0);
      if KRITER then Hf = H_eta_Ref; else Hf = H_eta_Const;
      KARAR = (Hf <= 0);
      output;
    end;
    keep E_D E1 E2 E3s E4s E3c E4c H_D H1 H2 H3s H4s H3c H4c U_D U1 U2 U3s U4s U3c U4c
         Eq_Ref Uq_Ref H_eta_Ref Eq_Const Uq_Const H_eta_Const Sigma_R KRITER KARAR;
  run;
  proc transpose data=sonuc out=uzun(rename=(_name_=alan col1=hesap)); run;
  data uzun; length senaryo $12 alan $12; set uzun; senaryo = "&senaryo"; run;
  proc append base=hepsi data=uzun force; run;
%mend;

proc datasets lib=work nolist; delete hepsi; quit;
%pbe_hesap(senaryo=P1, dosya=P1_psg020929, logd=0, tekyon=0);
%pbe_hesap(senaryo=P2, dosya=P2_m1, logd=0, tekyon=0);
%pbe_hesap(senaryo=P3, dosya=P3_dengesiz, logd=0, tekyon=0);
%pbe_hesap(senaryo=P4_tekyon, dosya=P4_tekyon_aktif, logd=0, tekyon=1);
%pbe_hesap(senaryo=P4_iki, dosya=P4_tekyon_aktif, logd=0, tekyon=0);
%pbe_hesap(senaryo=P5_exp, dosya=P5_exp, logd=1, tekyon=0);
%pbe_hesap(senaryo=P5_kap, dosya=P5_kap_tekrar, logd=0, tekyon=0);
%pbe_hesap(senaryo=P6_esit, dosya=P6_sinir_esit, logd=0, tekyon=0);
%pbe_hesap(senaryo=P6_ustu, dosya=P6_sinir_ustu, logd=0, tekyon=0);

/* ---- Karsilastirma ---- */
proc sql;
  create table kars_b as
    select "B" as kaynak length=1, b.senaryo, b.alan, b.beklenen, h.hesap,
           abs(b.beklenen - h.hesap) as fark format=e10.,
           case when calculated fark <= 1e-10 then "GECTI" else "KALDI" end as durum length=5
    from beklenen_b b left join hepsi h on b.senaryo = h.senaryo and upcase(b.alan) = upcase(h.alan);
  create table kars_y as
    select "Y" as kaynak length=1, y.senaryo, y.alan, y.beklenen, h.hesap,
           abs(y.beklenen - h.hesap) / abs(y.beklenen) as fark format=e10.,
           case when calculated fark <= 5e-5 then "GECTI" else "KALDI" end as durum length=5
    from beklenen_y y left join hepsi h on y.senaryo = h.senaryo and upcase(y.alan) = upcase(h.alan);
quit;
data tum; set kars_y kars_b; run;
proc print data=tum noobs label; format beklenen hesap best16.; run;
proc sql;
  title2 "OZET";
  select kaynak, count(*) as kontrol, sum(durum = "GECTI") as gecti, sum(durum = "KALDI") as kaldi
    from tum group by kaynak;
quit;
