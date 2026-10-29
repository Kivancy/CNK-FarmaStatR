# SAS çapraz kontrolleri / SAS cross-checks (EMA %90 GA, FSR-TN-PLT-08)

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.
For research and education; not a system validated for GxP environments.

Programlar Claude tarafından yazıldı, proje sahibi SAS'ta çalıştırdı. Veriler programın içinde.
Beklenen değerler (R, CNKfarmastatr 1.0.0.9000) her programın sonundaki yorumda.

| Program | Veri | Sonuç | Günlük |
|---|---|---|---|
| `fsr_m1_kontrol.sas` | PSG 020929 örneğinin yalnız B evresi (3 × 10, m = 1) | FDA PBE ara değerleri ve Hη = −0,0319199903; EMA (a), (b), (c) sınırları, SE ve serbestlik derecesi R ile 10 basamakta aynı; (c) için PROC MIXED REML | G-103 |
| `fsr_nobound_kontrol.sas` | Kurgu veri (R, set.seed(2); 3 × 10, m = 1); TEST'te seri varyansının ANOVA tahmini negatif | NOBOUND = TYPE3 = platform (b): 0,8023764327–1,7984530530. Sınırlı REML + DDFM=SATTERTHWAITE = platform (c): 0,8421613700–1,7134914951. Sınırlı REML + containment: 0,8296240562–1,7393858512 | G-105 |

Sınır: programlar Claude'un yorumuyla yazıldı. "m = 1'de evre terimleri düşer" okumasını ve (b)/(c)
seçimini doğrulamaz; bağımsız olan kısım PROC MIXED'in kendi REML hesabıdır. (c)'nin Satterthwaite
eşdeğerliği yalnız iki tabakalı durumda (m = 1) gösterildi.

Kaynaklar: Stroup WW, Milliken GA, Claassen EA, Wolfinger RD (2018) SAS for Mixed Models:
Introduction and Basic Applications, §5.4 ve §5.7.2–5.7.3; Casella G, Berger RL (2002) Statistical
Inference, 2. baskı, Teorem 5.3.1, Örnek 7.2.3.
