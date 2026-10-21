# CNK-FarmaStatR · P4 ekranı / P4 screen

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.
For research and education; not a system validated for GxP environments.

Kaynak / source: FSR-TN-PLT-04 v0.1 (KK-54). Geliştirme sürümü; kabul testleri `kabul.html` ile (aşağıda).
Development version; acceptance tests in kabul.html (see below).

## TR

Sunucu P1'deki gibi depo kökünden açılır:

```r
setwd("C:/cloud/CNK-FarmaStatR/CNK-FarmaStatR")
httpuv::runStaticServer(".", port = 8000)
```

Adres: `http://127.0.0.1:8000/web/app/` (ilk açılışta Ctrl + F5).

- **Hazır sonuç (katman 2):** girdiler ızgaradaki bir senaryoyla aynıysa sonuç veri tabanından
  (`veri/farmastatr_v1.sqlite`, SHA-256 `veri/VT_SHA256.txt` ile doğrulanır) webR başlatılmadan
  gelir. Birleşik koşu (50.000) varsa o gösterilir (P4-K1). sql.js 1.12.0 internetten yüklenir.
- **Canlı koşu (katman 1):** ızgarada olmayan ve tarayıcı sınırı içindeki senaryolar webR'de koşulur.
- **R betiği (katman 3):** sınırın üstündeki senaryolar için.
- Her oran R'nin verdiği metrik adıyla (tip I hata sınırda / noktasal tip I hata / güç), hipotez
  durumu ve KK-38 etiketiyle gösterilir. Sayılar tek kuralla yazılır: ikili değere en yakın, tam
  eşitlikte çift (P4-K3; `bicim.js`).
- "Bağlantıyı kopyala" parametreleri ve paket sürümünü taşır; farklı sürümün bağlantısı sessizce
  çevrilmez.
- P1 prototipi (`web/p1/`) P1'in kanıtı olarak değişmeden kalır.
- **Tasarım seçimi (P5, FSR-TN-PLT-05; KK-56, KK-57):** "Tasarım seçimi (hedef güç)" sekmesi.
  Popülasyon, güç için gerçek fark (varsayılan GMR 1,05), hedef güç (varsayılan %80) ve aday
  ℓ, n, m listeleri girilir. Koşu planını, motor koşularını ve Kural A/B seçimini R yapar
  (`platform_tasarim_plan`, `platform_run_invitro`, `platform_tasarim_secim`). Bütün adaylar
  veri tabanında varsa (aynı nsim ve seed) sayılar oradan gelir, kuralları yine R uygular (webR
  açılır); değilse canlı koşulur; toplam iş 6 × 10⁷ hücreyi aşarsa tasarım betiği önerilir
  (T-3). "Canlı da koş" hazır tabloyu ortak seed ile yeniden üretir.
- **Word raporu (P5-K1 … P5-K4):** iki sekmede de "Rapor (.docx)" düğmesi, gösterilen sonucun
  raporunu tarayıcıda üretir (`rapor.js`; kütüphane yok, ağ isteği yok). Rapor ekrandaki metinlerin
  aynısını içerir (aynı biçimlendirme fonksiyonu), ekranın dilindedir; beyan her sayfada iki dilde.
  Sonuç yokken, girdi değişince ya da koşu sürerken düğme pasiftir.

### Kabul testleri (FSR-TN-PLT-04 Tablo 9.1, U-1 … U-12)

1. `http://127.0.0.1:8000/web/app/kabul.html` adresini açın, "Testleri başlat"a basın (5–10 dk;
   sekme önde kalsın). Bitince "p4_tarayici.csv indir": `p4_tarayici.csv` ve `p4_betik.R` iner.
2. İki dosyayı `belgeler/teknik_notlar/FSR-TN-PLT-04_ek/p4/` klasörüne koyun.
3. Sunucuyu kapatın (Esc) ve depo kökünde:
   `source("belgeler/teknik_notlar/FSR-TN-PLT-04_ek/p4_kabul.R", encoding = "UTF-8")`
   (RSQLite gerekir: bir kez `install.packages("RSQLite")`).

## EN

Serve the repository root as for P1 and open `http://127.0.0.1:8000/web/app/`. Scenarios of the
results grid come from the SHA-256-checked database without webR (tier 2; the combined run when
there is one); other scenarios within the browser limit run in webR (tier 1); above the limit the R
script is offered (tier 3). Every rate is shown with R's metric name, hypothesis state and KK-38
label; numbers use one rule (nearest to the binary value, exact ties to even). The "Design
selection (target power)" tab (P5) shows, for a population, a target power and candidate ℓ, n, m,
the power and type I error of every candidate and the smallest design by rules A and B of
FSR-TN-PBE-01 Table 11.3a/b; R plans, runs and selects. Links carry the
parameters and the package version; a link of another version is not converted silently.
