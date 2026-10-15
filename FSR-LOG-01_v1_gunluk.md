---
title: "CNK-FarmaStatR v1 · Proje Günlüğü"
subtitle: "FSR-LOG-01 · Sürüm 1.33 · Son güncelleme: 15.10.2026"
---

# Bu belge hakkında

Bu günlük CNK-FarmaStatR v1'in (akademik eğitim ve araştırma platformu) geliştirme kaydıdır: aşamalar, kararlar (kimin kararı olduğu dahil), bulgular ve çıktılar kronolojik olarak tutulur.

**Güncelleme kuralı.** Her oturum sonunda yeni girdi eklenir; mevcut girdiler değiştirilmez. Düzeltme, eski girdiye atıf yapan yeni bir girdiyle yapılır. Bölüm 3–5'teki tablolar güncel durumu gösterir ve her sürümde güncellenir.

**Kısaltmalar.** K = kullanıcı kararı (proje sahibi). Ö = Claude önerisi; kullanıcı onayıyla uygulandı. KK-n = kullanıcı kararları dizinindeki numara.

**Önceki çalışma.** v0.5.1 ve öncesi bu projenin tarihçesi değildir (KK-1). Oradan yalnızca malzeme devralınmıştır; devralınan her şey G-01'de envanterlenmiştir.

# 1. Proje çerçevesi

- **Ad:** CNK-FarmaStatR v1 · Farmasötik İstatistik Platformu.
- **Amaç:** Akademik eğitim ve araştırma için yeniden üretilebilir, simülasyon odaklı platform. GxP/GMP/GAMP kapsam dışı.
- **Ana fikir:** Yayındaki her örnek platformda yeniden üretilebilir; yayındaki simülasyon parametreleri kullanıcı tarafından değiştirilebilir.
- **Ayrıntılı çerçeve:** Proje talimatları (13.10.2026 sürümü).

# 2. Kronolojik günlük

## G-01 · Yeni başlangıç: yön değişikliği ve devralınan malzeme — 13.10.2026

**Kararlar (K):**

- **KK-1:** v0.5.1 tarihçe olarak taşınmaz; yeni sayfa açılır. v0.5.1 yalnızca malzeme deposudur.
- **KK-2:** Platform akademik eğitim ve araştırma odaklıdır; GxP/GMP/GAMP kapsam dışıdır. Arayüzde ve raporlarda kalıcı beyan bulunur.
- **KK-3:** Validasyon istatistik model bazında bir kez yapılır ve bir kez belgelenir; analiz başına tekrarlanmaz.
- **KK-4:** Tamamen web: statik web uygulaması (webR, GitHub Pages), sunucu yok. Hibrit hesaplama: tarayıcı + SQLite'ta önceden hesaplanmış ızgara + R betiği olarak dışa aktarma (Ö).
- **KK-5:** Veri tabanı SQLite (yayın veri setleri, test vakaları, simülasyon sonuçları, modül/sürüm kaydı).
- **KK-6:** GitHub kullanılır; sürümler Zenodo DOI alır.
- **KK-7:** Yayın modülleri: her makalenin uygulaması platforma modül olarak gömülür; makaledeki örnekler platformda doğrulanabilir.
- **KK-8:** Simülasyon odaklıdır; simülasyon parametreleri kullanıcı tarafından ayarlanabilir. Tasarım çerçevesi ADEMP (Ö).
- **KK-9:** Hedef kitle: akademi (hakem, öğrenci, araştırmacı) ve endüstri.
- **KK-10:** İki dilli yapı (TR/EN). Kod yorumları İngilizce (kullanıcı kararı Claude'a bıraktı; Ö).
- **KK-11:** SAS çapraz kontrolü isteğe bağlıdır (kullanıcı tercihi; SAS OnDemand).
- **KK-12:** Önce platform makalesi yayımlanır; sonraki makaleler ona atıf yapar.
- **KK-13:** Sürüm: geliştirme 1.0.0.9000; v1.0.0 platform makalesiyle birlikte ilk açık sürüm (Ö).
- **KK-14:** Çalışma klasörü `C:\cloud\CNK-FarmaStatR-v1`. Kalıcı kaynak bu klasör, GitHub'a geçildikten sonra GitHub deposu.

**Devralınan malzeme.** Kaynak: `C:\cloud\final_pbe-dissolution_v5\CNK-FarmaStatR_v0.5.1_program` (yalnızca okundu, değiştirilmedi). Hedef: `devralinan/v0.5.1/`. Her dosyanın SHA-256 değeri v0.5.1'in bütünlük listesiyle (`butunluk.js`) karşılaştırıldı ve kopyadan sonra yeniden doğrulandı: 9/9 eşleşiyor.

| Dosya | Model | SHA-256 | Devralınan validasyon kanıtı |
|---|---|---|---|
| `hesap/dissolusyon/msd_core.R` (v0.2.0) | Model bağımsız MSD (Mahalanobis, Hotelling T²) | `855dc32cc43913df4bbb021ab6d3a98c569a8ecd003ad33f14ed5d6c6dea69d5` | R 60/60 · SAS 27/27 · webR 60/60 (eski belge DIS-1A v1.1) |
| `hesap/dissolusyon/msd_weibull.R` (v0.2.0) | Weibull tabanlı MSD | `b053a1f1f5487149284b19f0b0426b76f1e16576fea05874539f47c5cb7c5ce2` | R 98/98 · SAS 52/52 · webR 98/98 (DIS-1B v1.1) |
| `hesap/dissolusyon/f2_boot.R` (v0.3.0) | f2, E(f2), bc-f2, bootstrap f2 (persentil, BCa) | `ad6aabd8b6a249afd16beccac8bb74d3ac33f6260e85f74cc6fd8a826faebf3e` | R 120/120 · SAS 44/44 · webR 120/120 (DIS-2 v1.1) |
| `hesap/dissolusyon/f2_noce_data.R` | Noce 2020 örnek verisi | `638a2d824b29d55bfbe5be119ab05206a14b11a0a828bcd4fc8db27c93c59f95` | Veri |
| `hesap/dissolusyon/dis_ornek_veri.R` | Tsong 1996 ve Noce örnek verileri | `0379f5bad11860fa3eb74cec08078615c3586d67eec6e78308f686c590441c1c` | Veri |
| `hesap/dissolusyon/kopru.R` | Arayüz–çekirdek köprüsü (dissolüsyon) | `5dea054408d594a2eafecfeacde272bbc8f21e9da9507bbef1b15898274c4e28` | Uçtan uca testte sınandı |
| `hesap/pbe/pbe_core.R` (v05_3) | PBE (FDA PSG_020929) | `e7be66b8e93c79ec3cc78463513db3a2e2d48031dbdc0d41975ed6232426ac65` | R 213/213 · SAS 177/177 · webR 213/213 (PBE-1 v1.1) |
| `hesap/pbe/kopru.R` (v0.1.0) | PBE köprüsü (girdi kontrolleri) | `4478174f174070487cac2d19ec9b5445983195d31d2df97c05d2db508624166c` | R 25/25 · webR 25/25 |
| `hesap/pbe/pbe_ornek_veri.R` | PSG_020929 örnek verisi | `a761f88b96e373f9d5bace5fd7036ce3a95beaf9de774ee5e5882fbe12ccf2b6` | Veri |

Ayrıca: `belgeler/dissolusyon_kilavuz_v2.2.html` (eski dissolüsyon kullanım kılavuzu; yöntem açıklamaları yeniden kullanılmak üzere; GMP bölümleri kullanılmayacak).

**Devralınan bilimsel kararlar** (modüllerin parçası olarak geçerli):

- **f2 karar kuralı:** Alt sınır 4 ondalıkla, yuvarlanmadan raporlanır. ≥ 50 benzer; 49.5–50 sınır vaka (değerlendirici yorumu); < 49.5 benzer değil.
- **%85 kesmesi** her bootstrap replikasında yeniden uygulanır (Bootf2bca ile uyumlu; Noce 2020'nin DDSolver eleştirisiyle tutarlı). Ortalamalar karşılaştırmada 10 ondalığa yuvarlanır (sınırda eşitlik).
- **EMA ve FDA perspektifleri** seçimli. FDA ön ayarı: klasik f2, FDA kesmesi, FDA 1997 CV kuralı, B = 10.000. Güven aralığı varsayılanı persentil, BCa seçenek (Xu 2021, Denklem 21–24).
- **Weibull MSD parametrizasyonu:** varsayılan (ln T_d, ln β) (FarmaStatR türetimi; zaman biriminden bağımsız). Σ₂ böleni seçimli (varsayılan N). W2-NLS ve W3 planlanmıyor.
- **MSD benzerlik sınırları:** L1, L2a, L2b, L3 (L3: EMA %10 koşulu için hiperküp kontrolü; FarmaStatR türetimi).
- **Karşılaştırılan referans** ürün, referans partilerinden biri olarak da seçilebilir.
- **PBE köprüsü:** kap başına eksik/tekrarlı aşama reddedilir; log kapalıyken geometrik ortalamalar gösterilmez. σT0 = 0.1 ve θP sabit (kapsam sınırı).

**Literatürde bulunan hatalar** (platform makalesinin malzemesi):

| Kaynak | Bulgu | Kanıt düzeyi |
|---|---|---|
| Tsong 1996, Tablo 1 | REF tablet 4, 30 dk: 78.54 → 78.45 | Kanıtlı: yayımlanan D_M, GA ve T² yalnızca düzeltilmiş değerle üretiliyor |
| Tsong 1996 | DATA2 fark vektöründe −0.70 eksik; DATA2 R_D verilmemiş | Kanıtlı |
| Sathe 1996 | E-1, E-2, E-3, N-1 | Tanımlar eski DIS-1B v1.1 belgesinde |
| Ma 2000, Tablo 1 | Değişiklik öncesi parti, tablet 1, 60 dk: 56.6 → 58.6 | Güçlü: iki partinin f2'si birebir üretiliyor |
| Ma 2000, Tablo 1 | SONRASI5, 180 dk ortalaması 98.6 / 98.03 | Tutarsızlık; tek hücreyle açıklanamıyor |

Diğer makale malzemesi: DDSolver değerlendirmesi (benzerlik sınırının test–referans uzaklığından türetilmesi ve farklı uzaylarda uygulanması); Tsong 78.54/78.45 duyarlılık notu (kovaryans matrisinin koşul sayısı ≈ 485).

**Taşınmayanlar:** kimlik, denetim izi, ana defter, imza alanları, çalışma ayarları, Baslat.bat ve yerel sunucu (`sunucu.R`, `sha256.R`), platform JS/CSS, URS-PLT-DI, eski yol haritası, eski günlük ve karar numaraları. webR çalışma dosyaları kopyalanmadı (yeni mimaride güncel webR sürümü kullanılacak).

**Eksik malzeme (v0.5.1 program klasöründe yok):** validasyon test betikleri (R), SAS doğrulama programları ve çıktıları, validasyon belgeleri (DIS-1A, 1B, 2, PBE-1), test verisi Excel paketleri (Tsong, Ma/Shah, Noce). Bu dosyalar olmadan devralınan validasyon kanıtı yeniden koşturulamaz; yeri proje sahibine soruldu.

## G-02 · Validasyon malzemesinin aranması: PBE tamam, dissolüsyon eksik — 13.10.2026

- **Bilgi (K):** PBE ve dissolüsyon validasyonları ayrı ayrı, farklı dosyalarda yürütülmüştü.
- **Arama:** `C:\cloud` okuma izniyle tarandı (hiçbir dosya değiştirilmedi).
- **PBE (tam):** Kaynak `C:\cloud\final_pbe-dissolution_v2\files\PBE_validasyon_v0.2.zip` (v0.1'in köprü testleri ve rapor betiğiyle güncellenmiş hali) ve `CNK-FarmaStatR_PBE_Validasyon_v1.1.docx`. Zip'teki `pbe_core.R`, `kopru.R` ve `pbe_ornek_veri.R` G-01'deki parmak izleriyle birebir aynı. Hedef: `devralinan/v0.5.1/validasyon/pbe/` (R testleri, Python referansı, 10 test CSV'si, SAS programı, belge v1.1).
- **Dissolüsyon (kısmi):** Bulunanlar `devralinan/v0.5.1/validasyon/dissolusyon/` altına alındı: üç Excel test paketi (Tsong 1996, Ma 2000/Shah 1998, Noce 2020; "Yayımlanan sonuçlar" sayfasını içeren son sürümler), iki örnek yükleme CSV'si, Tsong teknik notu (FSR-TN-DIS-01 v1.0) ve üretici betiği.
- **Bulunamayanlar (dissolüsyon):** `msd_tests.R`, `f2_tests.R`, `f2_export_for_sas.R`, Weibull MSD test betiği, MSD ve f2 SAS programları, `msd_validation_report.R`, validasyon belgeleri DIS-1A, 1B, 2. `C:\cloud` içinde yok.

## G-03 · Dissolüsyon test betiklerinin eski sohbetten yeniden kurulması — 13.10.2026

- **Durum (G-02 devamı):** Proje sahibinin R ile yaptığı tam disk araması (`list.files("C:/", recursive = TRUE, ...)`) dissolüsyon test betiklerinin bilgisayarda bulunmadığını doğruladı. Olası neden: dosyalar eski oturumlarda indirme kartından doğrudan açılıp kalıcı bir klasöre kaydedilmedi; Claude'un çalışma alanı da oturumlar arasında sıfırlanıyordu. Bu yüzden v1'de dosyalar doğrudan çalışma klasörüne yazılır (KK-14).
- **Karar (K, Ö üzerine):** Test betikleri, yazıldıkları eski geliştirme sohbetinden ("In vitro BE eşdeğerlik sınaması: Weibull-tabanlı MSD yaklaşımı") yeniden kurulur. Ölçüt: yeniden kurulan testler, parmak izi sabit çekirdeklere karşı eski kontrol sayılarını eksiksiz vermelidir.
- **Yöntem:** Her betiğin ilk tam metni (create_file) alındı, ardından sohbette o dosyaya uygulanan değişiklikler sırasıyla yeniden uygulandı:
  - `msd_tests.R`: tur 7 (ilk metin, sonradan değişmedi).
  - `msd_weibull_tests.R`: tur 31 (ilk metin + `ga_basili` düzeltmesi), tur 63 (parametrizasyonun açıkça belirtilmesi, TC-B6 eklentisi, mantıksal karşılaştırma düzeltmesi).
  - `f2_tests.R`: tur 87 (ilk metin + üç karşılaştırma düzeltmesi), tur 119 (TC-F9: FDA perspektifi ve BCa).
  - `f2_export_for_sas.R`: tur 119'daki son hâli.
- **Sonuç:** G-01'deki parmak izleriyle birebir aynı çekirdeklere karşı **1A 60/60 · 1B 98/98 · 2 120/120 = 278/278 GEÇTİ** (R 4.x, Linux; `Calistir.R`). Sayılar eski validasyon kayıtlarıyla aynı; yeniden kurulumun doğruluğuna kanıttır.
- **Konum:** `devralinan/v0.5.1/validasyon/dissolusyon/R/` (çekirdeklerin bayt bayt kopyaları + test betikleri + `Calistir.R`).
- **SHA-256 (yeniden kurulan dosyalar):**

| Dosya | SHA-256 |
|---|---|
| `msd_tests.R` | `d793f11ce1494c3e589e2df713b35ba6ef7bae60fc7155152256424042dde73c` |
| `msd_weibull_tests.R` | `cd41e7c04ccb5e6fc2b337ef95b72b7ed38f6859bfc7f02a57dedad8408bc176` |
| `f2_tests.R` | `52112723d43b4c049063bb78b30504d81d431af85776a917a53c90d3e386a816` |
| `f2_export_for_sas.R` | `c6f818a57629757e905916d0dd7d29967405c33cbc35685b34074fc13a4dbe80` |
| `Calistir.R` | `24586cbb1e99ba9394ada24b547aeb9c09e781725d87c764641c8eb53b730a25` |

- **Yeniden kurulmayanlar:** MSD, Weibull MSD ve f2 SAS programları (son sürümleri sohbette çok sayıda yamayla oluştu) ve validasyon belgeleri DIS-1A, 1B, 2. SAS isteğe bağlı olduğundan (KK-11) ertelendi; gerekirse aynı yöntemle kurulabilir. Validasyon belgeleri v1 düzeninde yeniden yazılacak.
- **Bekleyen:** `Calistir.R`'nin proje sahibinin Windows/RStudio ortamında çalıştırılması (beklenen: 278/278).

## G-04 · Kullanıcı ortamında teyit: 278/278 — 13.10.2026

- Proje sahibi `Calistir.R`'yi kendi Windows/RStudio ortamında çalıştırdı: **1A 60/60 · 1B 98/98 · 2 120/120 = 278/278 GEÇTİ**. Yeniden kurulan test betikleri iki bağımsız ortamda (Linux ve Windows) aynı sonucu verdi. Devralınan dissolüsyon validasyonunun R kanıtı yeniden kurulmuş sayılır.

## G-05 · R paketi iskeleti: CNKfarmastatr 1.0.0.9000 — 13.10.2026

- **Kararlar (K):** **KK-15:** R paketinin adı `CNKfarmastatr` (R paket adlarında tire kullanılamaz). Platform, depo, web sitesi ve atıflarda **CNK-FarmaStatR** adı korunur. **KK-16:** Proje sahibinin GitHub hesabı var; depo bağlantısı sonraki adım.
- **Yapı:** `CNKfarmastatr/R/` altında yedi çekirdek dosya (msd_core, msd_weibull, f2_boot, f2_noce_data, dis_ornek_veri, pbe_core, pbe_ornek_veri) **bayt bayt** aynı; parmak izleri `inst/validasyon/CEKIRDEK_SHA256.txt`'de. Devralınan test betikleri değiştirilmeden `inst/validasyon/` altında; `tests/testthat/` bunları paket koduna karşı çalıştıran sarmalayıcılar içerir.
- **Bütünlük aracı:** `araclar/cekirdek_kontrol.R` + `araclar/sha256.R` (v0.5.1'in temel R SHA-256 uygulaması). Sonuç: 7/7 AYNI.
- **R CMD check (R 4.3.3, Linux):** testler **12/12 beklenti GEÇTİ** → MSD 60, Weibull 98, f2 120, PBE 213 = **491 kontrol**. 2 uyarı, beklenen: (1) çekirdeklerin kod içindeki Türkçe karakterleri (ASCII dışı; çekirdekler değiştirilemeyeceği için ilk planlı revizyona kadar kalır), (2) fonksiyon belgeleri henüz yok.
- **Kapsam dışı bırakılanlar:** iki `kopru.R` dosyası (arayüz katmanı; aynı adlı fonksiyonlar çakışıyor) ve bu yüzden PBE köprü testleri (25). Arayüz yeniden tasarlanırken ele alınacak.
- **Lisans:** henüz karar verilmedi; `LICENSE` dosyası "tüm hakları saklıdır" geçici metniyle.

## G-06 · Paket testleri kullanıcı ortamında: R 4.6.1 / Windows — 13.10.2026

- Proje sahibi `testthat::test_local()` ile paket testlerini düz R'da (RGui, **R 4.6.1**, Windows) çalıştırdı: **[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]**, 15.8 sn. Dört model, 491 kontrol paket kodu üzerinden geçti.
- Paket böylece üç ortamda sınanmış oldu: R 4.3.3 / Linux (R CMD check), R 4.4.1 / Windows (`Calistir.R`, G-04), R 4.6.1 / Windows (bu girdi).
- **Ortam notu:** Bilgisayarda iki R sürümü var (RStudio: 4.4.1; masaüstü kısayolu: 4.6.1) ve paket kütüphaneleri ayrıdır. RStudio, kendi kullandığı `cli` paketini Windows'ta güncelleyemiyor (oturum yeniden başlatma döngüsü); paket güncellemeleri RStudio kapalıyken düz R'da yapılmalıdır.

## G-07 · GitHub hazırlığı — 13.10.2026

- **Bilgi (K):** GitHub kullanıcı adı **Kivancy** (Kıvanç YÜKSEL; Ege Üniversitesi). Hesapta henüz depo yok.
- **Bulgu:** `pbe_core.R` Windows satır sonlarıyla (CRLF), diğer çekirdekler LF ile kayıtlı. Git'in Windows'taki satır sonu dönüştürmesi bu dosyaların baytlarını, dolayısıyla SHA-256 parmak izlerini değiştirebilirdi.
- **Önlem (Ö):** Kök klasöre `.gitattributes` eklendi: `CNKfarmastatr/R`, `CNKfarmastatr/inst` ve `devralinan` altında satır sonu dönüştürmesi kapalı; .docx/.xlsx/.jpg ikili dosya. `.gitignore`: R/RStudio geçici dosyaları, paket denetim çıktıları ve **tüm PDF'ler** (telifli kılavuz ve makaleler depoya girmez).
- **Karar (K): KK-17:** GitHub deposu **özel (private)** olacak: `github.com/Kivancy/CNK-FarmaStatR`. Lisans kararı ve platform makalesiyle birlikte (v1.0.0) açık hale getirilir; Zenodo DOI o aşamada alınır.

## G-08 · Özel GitHub deposu yayında — 13.10.2026

- Proje sahibi GitHub Desktop ile `C:\cloud\CNK-FarmaStatR-v1` klasörünü depoya çevirdi, ilk kaydı ("v1.0.0.9000: başlangıç") yaptı ve **özel** olarak yayımladı: `github.com/Kivancy/CNK-FarmaStatR` (kilit simgesi; dal `main`; yerel değişiklik yok).
- Bundan sonra kalıcı kaynak bu depodur. Çalışma akışı: Claude klasöre yazar → proje sahibi GitHub Desktop'ta kısa bir açıklamayla kaydeder (Commit) ve gönderir (Push).

## G-09 · Düzeltme (G-08'e): depo yanlış klasörde açılmıştı; çalışma klasörü taşındı — 13.10.2026

- **Bulgu:** GitHub Desktop'ın "create a repository" adımı mevcut klasörü depoya çevirmek yerine `C:\cloud\CNK-FarmaStatR` adında **yeni ve boş** bir klasör açtı. G-08'deki ilk kayıt ve yayımlanan özel depo yalnızca GitHub Desktop'ın varsayılan `.gitattributes` dosyasını içeriyordu; proje dosyaları depoya girmemişti. Ayrıca Claude'un G-08 günlük yazımı klasöre eski hâliyle ulaşmıştı (aktarım sonrası boyut kontrolüyle yakalandı ve yeniden yazıldı).
- **Düzeltici faaliyet:** Proje dosyalarının tamamı (95 dosya) `C:\cloud\CNK-FarmaStatR` depo klasörüne kopyalandı; GitHub Desktop'ın varsayılan `.gitattributes` dosyası (satır sonu dönüştürmesi açık) projenin `.gitattributes` dosyasıyla değiştirildi. Kayıt ve gönderim proje sahibince yapılır.
- **Karar (Ö, KK-14'ün güncellenmesi): KK-18:** Çalışma klasörü artık **`C:\cloud\CNK-FarmaStatR`** (depo klasörü). `C:\cloud\CNK-FarmaStatR-v1` yedek olarak durur; depoda her şey doğrulandıktan sonra proje sahibi silebilir.
- **Önlem:** Claude her dosya yazımından sonra hedef dosyanın boyutunu klasörde kontrol eder.

## G-10 · Düzeltme (G-09'a): doğru depo klasörü — 13.10.2026

- **Bulgu:** GitHub Desktop'ta iki ayrı depo oluşmuştu: GitHub'a bağlı olan `Belgeler\GitHub\CNK-FarmaStatR` (OneDrive içinde; yalnızca `.gitattributes`) ve uzak bağlantısı olmayan `C:\cloud\CNK-FarmaStatR` (G-09'da proje dosyaları buraya yazılmıştı). Proje dosyaları GitHub'a hiç gönderilmemişti. Claude, G-09'da `.git` yapılandırmasını kontrol etmeden işlemi tamamlanmış saymıştı.
- **Düzeltici faaliyet:** Proje sahibi `C:\cloud\CNK-FarmaStatR` klasörünü sildi ve GitHub'daki depoyu klonladı. GitHub Desktop klonu `C:\cloud\CNK-FarmaStatR\CNK-FarmaStatR` yoluna açtı; `.git/config` içinde `origin = https://github.com/Kivancy/CNK-FarmaStatR.git` doğrulandı. Proje dosyaları (95) bu klasöre yazıldı; GitHub Desktop'ın varsayılan `.gitattributes` dosyası (`* text=auto`, satır sonlarını dönüştürür) projeninkiyle değiştirildi.
- **Karar (Ö): KK-19 (KK-18'in yerine):** Çalışma klasörü **`C:\cloud\CNK-FarmaStatR\CNK-FarmaStatR`**. OneDrive içindeki `Belgeler\GitHub\CNK-FarmaStatR` kopyası GitHub Desktop'tan kaldırılıp silinecek.
- **Önlem:** Claude, bir depo işlemini tamamlanmış saymadan önce `.git/config` içindeki uzak adresi ve hedef dosya boyutlarını doğrular.

## G-11 · Depo GitHub'da doğrulandı; otomatik doğrulama (GitHub Actions) eklendi — 13.10.2026

- **Depo:** Proje sahibi 95 dosyayı `v1.0.0.9000: proje dosyaları` mesajıyla commit + push etti (commit `80556e5`); github.com'da klasörler görüldü. OneDrive içindeki `Belgeler\GitHub\CNK-FarmaStatR` kopyası GitHub Desktop'tan kaldırıldı; tek yerel depo `C:\cloud\CNK-FarmaStatR\CNK-FarmaStatR` (KK-19). Yedek `C:\cloud\CNK-FarmaStatR-v1` şimdilik korunuyor.
- **Çalışma düzeni (K):** Claude dosyaları yerel depoya yazar ve doğrular; proje sahibi GitHub Desktop'ta inceleyip Commit + Push yapar. Push, proje sahibinin onayıdır.
- **Otomatik doğrulama (Ö, K onayı):** `.github/workflows/dogrulama.yml`. Her push'ta (ve elle) Linux ve Windows üzerinde: (1) 7 validasyonlu çekirdeğin SHA-256 değerleri `CEKIRDEK_SHA256.txt` ile karşılaştırılır, farklıysa iş başarısız olur; (2) paket kurulur ve devralınan testler koşar (491 kontrol, 12 beklenti; atlanan test kabul edilmez). Bu yeniden validasyon değil, bozulmadığının kanıtıdır.
- **Ön deneme (Claude ortamı, R 4.3.3, Linux):** SHA-256 7/7 AYNI; 12/12 beklenti GEÇTİ, atlanan 0, yaklaşık 21 s. Negatif deneme: bir çekirdeğe tek satır eklenince 1. adım hata koduyla durdu.
- **Bekleyen:** GitHub üzerindeki ilk koşunun sonucu (Actions sekmesi).

## G-12 · Otomatik doğrulamanın ilk koşusu: GEÇTİ — 13.10.2026

- Commit `0648682` push edildi; GitHub Actions `dogrulama #1` koşusu Linux (ubuntu-latest) ve Windows (windows-latest) üzerinde yeşil tamamlandı (2 dk 13 s): 7 çekirdeğin SHA-256 değerleri aynı, 491 kontrol GEÇTİ. Böylece satır sonu ayarının (`.gitattributes`) Windows'ta da çekirdekleri bozmadığı doğrulandı.
- Bundan sonra her push'ta aynı kontrol kendiliğinden koşar; sonuç Actions sekmesinde yeşil tik / kırmızı çarpı olarak görülür.

## G-13 · PBE köprüsü pakete alındı: 516 kontrol — 14.10.2026

- **Oturum başı:** Günlük okundu; bilgisayardaki, depodaki ve proje belgelerindeki günlük aynı (v1.9). Son commit `81678ff` ("Günlük: ilk doğrulama koşusu").
- **İş (A-7'nin ilk parçası):** PBE köprüsü (`devralinan/v0.5.1/hesap/pbe/kopru.R`, v0.1.0) pakete **değiştirilmeden** `CNKfarmastatr/R/pbe_kopru.R` adıyla alındı (SHA-256 `4478174f…`, G-01 envanteriyle aynı). Validasyonlu dosya listesi (`CEKIRDEK_SHA256.txt`) 8 dosyaya çıktı; GitHub Actions'taki parmak izi kontrolü yeni dosyayı da kapsar.
- **Gerekçe:** Köprü, çekirdeğin kendisinin yapmadığı girdi kontrollerini yapar (B-2: kap başına eksik ya da tekrarlı aşama ölçümü reddedilir; B-4: log kapalıyken geometrik ortalamalar gösterilmez). TC-K3, eksik aşamalı veride `calc_pbe()` doğrudan çağrılırsa hata vermediğini gösterir; köprü bu yüzden çekirdeğin ayrılmaz parçasıdır.
- **Testler:** Köprü test seti (`pbe_kopru_tests.R`, TC-K1…K4, 25 kontrol) değiştirilmeden `inst/validasyon/pbe/` altına alındı ve testthat'e bağlandı (sonuç tablosu `.kt`). Toplam: MSD 60 + Weibull 98 + f2 120 + PBE 213 + PBE köprüsü 25 = **516 kontrol** (15 beklenti). Claude ortamında (R 4.3.3, Linux) 15/15 GEÇTİ, atlanan 0; `R CMD check`: 0 hata, aynı 2 beklenen uyarı.
- **Ertelenen:** Dissolüsyon köprüsü (`hesap/dissolusyon/kopru.R`) pakete alınmadı: PBE köprüsüyle aynı adlı fonksiyonlar içeriyor (`kp_hazirla`, `kp_calistir`). Arayüz tasarlanırken ilk revizyonuyla birlikte ele alınacak.
- **Not:** `.github/workflows/dogrulama.yml` içindeki adım adı hâlâ "491 checks" diyor (yalnızca etiket; sayılar testthat'te denetlenir). Bu klasöre köprü üzerinden yazılamadığı için iş akışında bir sonraki gerçek değişiklikle düzeltilecek.

## G-14 · Fonksiyon belgeleri (İngilizce) ve yazdırma yöntemlerinin kaydı — 14.10.2026

- **İş (A-7'nin ikinci parçası):** Paketin yardım sayfaları `CNKfarmastatr/man/` altına elle yazılmış Rd dosyaları olarak eklendi (9 dosya): paket genel bakışı, `calc_msd`, `msd_prepare`, `calc_msd_weibull` (+ `calc_msd_params`), `calc_f2_boot` (+ `f2_estimators`, `f2_export_indices`), `calc_pbe`, PBE köprüsü (`kp_hazirla`, `kp_pbe`, `kp_calistir`), örnek veriler ve iç fonksiyonlar (tek sayfa, `internal`).
- **Yöntem kararı (Ö):** Belgeler çekirdek dosyalara roxygen yorumu olarak **yazılmadı**: validasyonlu dosyalara eklenen her satır SHA-256 değerini değiştirir. Rd dosyaları ayrı tutulur; çekirdekler bayt bayt aynı kaldı. roxygen2 bağımlılığı da gerekmedi.
- **İçerik ilkeleri:** Her sayfada kaynak (kılavuz/makale + bölüm/denklem) belirtildi; kaynakta doğrudan olmayan kurallar "FarmaStatR derivation" olarak işaretlendi (ör. MSD'ye %85 kesmesi, L2a/L2b, L3 hiperküpü, lnTd_lnB parametrizasyonu, f2 karar kuralı, dengesiz PBE tasarımı). Türkçe argüman değerleri, sonuç öğeleri ve mesajlar İngilizce açıklandı. Tek yönlü PBE seçeneğinin kaynağı FDA PSG 020121 (flutikazon nazal sprey, Aralık 2025) Appendix olarak belirlendi (proje dosyalarından doğrulandı). `calc_pbe` sayfasına, eksik aşamalı veriyi reddetmediği ve köprü üzerinden kullanılması gerektiği uyarısı eklendi (TC-K3).
- **Bulunan ve düzeltilen hata:** Sonuç sınıflarının yazdırma yöntemleri (`print.farmastat_msd`, `print.farmastat_msd_weibull`, `print.farmastat_f2boot`) NAMESPACE'te kayıtlı değildi; paket yüklüyken sonuçlar rapor yerine ham liste olarak basılıyordu. NAMESPACE'e `S3method()` satırları eklendi. Çekirdekler değişmedi.
- **Doğrulama (Claude ortamı, R 4.3.3):** `R CMD check`: 0 hata, 1 uyarı (çekirdeklerdeki Türkçe karakterler; çekirdekler revize edilene kadar kalacak). "Eksik belge" uyarısı kalktı. Tüm örnekler hatasız çalıştı; testler 15/15 (516 kontrol) GEÇTİ.

## G-15 · Lisans: üniversite görüşü bekleniyor; simülasyon altyapısı v0.1.0 — 14.10.2026

- **Lisans (A-6):** Seçenekler (MIT, GPL-3, Apache-2.0; içerik için CC BY 4.0) ve ticarileşmeyle ilişkisi konuşuldu. Claude önerisi: yazılım MIT, içerik CC BY 4.0; ticarileşme (ör. çift lisans) düşünülürse GPL-3. **K:** Karar öncesinde üniversiteye (TTO / fikri mülkiyet birimi) danışılacak. Sorulacaklar: hak sahipliği (FSEK md. 18), açık kaynak yayımı için izin/bildirim, telif notu, ticari yollar, yapay zekâ katkısının etkisi. Depo özel olduğu için karar zamanı platform makalesine kadar.
- **Simülasyon altyapısı (Ö, K onayı "başlayalım"):** Pakete üç yeni dosya eklendi (temel R, İngilizce yorumlar, ASCII):
  - `R/sim_performance.R`: Morris, White & Crowther 2019 (Stat Med 38:2074-2102) Tablo 6 performans ölçütleri, her biri Monte Carlo SH ile (bias, EmpSE, MSE, ModSE, ModSE göreli hatası, kapsama, yanlılığı giderilmiş kapsama, reddetme oranı); hedef MCSE için tekrar sayısı (`sim_n_required`).
  - `R/sim_run.R`: ADEMP senaryo tanımı (`sim_scenario`, kayıt defteri), çalıştırıcı (`sim_run`: tek RNG akışı, RNG türü sabit ve kayıtlı, kullanıcının RNG durumu korunur, hatalı tekrarlar yakalanıp sayılır), tek tekrarın yeniden üretimi (`sim_replicate`), koşu kaydı (parametreler, seed, RNG türü, R ve paket sürümü, platform, zaman) ve JSON dışa aktarımı (sayılar birebir geri okunacak en kısa biçimde), 3. katman için bağımsız R betiği (`sim_export_script`).
  - `R/sim_scenario_demo.R`: eğitim ve referans senaryosu `demo_mean_ci` (ortalama için t ve z güven aralığı kapsaması, t testi tip I hatası; normal veride gerçek değerler analitik olarak bilinir).
- **Testler (TC-S1…S10, 58 beklenti):** elle hesaplanmış performans değerleri (TC-S1), eksik tahminler, tekrar sayısı formülü, aynı seed = aynı sonuç ve kullanıcı RNG'sinin korunması, analitik değerlere 3 MCSE içinde yakınsama (t kapsaması 0,95; z kapsaması 2·F_t(1,96; 9) − 1 = 0,9184; tip I hata 0,05), parametre geçersiz kılma ve reddi, dışa aktarılan betiğin koşuyu birebir yeniden üretmesi, JSON, hatalı tekrarların yakalanması, tek tekrarın yeniden üretimi. Geliştirme sırasında bulunan hata: `sim_n_required` ikili kayan nokta yüzünden 1900 yerine 1901 veriyordu; düzeltildi.
- **Doğrulama (Claude ortamı, R 4.3.3):** tüm testler 73/73 beklenti GEÇTİ (devralınan 516 kontrol + simülasyon 58); `R CMD check` 0 hata, 1 uyarı (devralınan çekirdeklerdeki Türkçe karakterler). Yardım sayfaları: `sim_performance`, `sim_run`.
- **Açık:** Simülasyon çerçevesinin validasyon belgesi (FSR-VAL-SIM-1) ve SHA-256 sabitlemesi, proje sahibinin incelemesinden sonra. Sıradaki: ilk yayın senaryosu (hangi makalenin simülasyonu) — proje sahibinin kararı.

## G-16 · PBE simülasyon çalışması: model ve araştırma sorusu (tasarım aşaması, kod yok) — 14.10.2026

- **Konu seçimi (K):** İlk yayın senaryosu PBE güç / örneklem büyüklüğü. Gerekçe (K): literatürde güncel PSG tasarımı için güç ya da örneklem büyüklüğü çalışması yok; istatistik modelin sağlam kurulması öncelikli.
- **Okunan kaynaklar:** PSG 020929 (Aralık 2025) Appendix tamamı; Chow & Liu 2008, Bölüm 14 (özellikle 14.4.2, 14.6, 14.7.1-14.7.2); FDA 2026 (Mayıs) *Statistical Approaches to Establishing Bioequivalence*, III.A.1 ve Ek D-E. Telifli belgeler depoya alınmadı.
- **Kaynaklardan saptananlar:** (1) PSG tahmin edicisi seri düzeyini yok sayar; kaplar havuzlanır (MSB, sd nℓ-1). (2) FDA 2026 III.A.1: σ_T², σ_R² "population variances of the log-transformed measure"; kriter seçimi *tahmin edilen* σ_R'ye göre. (3) Chow & Liu 2008, 14.4.1: seriler arası, seri içi kaplar arası ve kap içi evreler arası değişkenlik uygun modelle değerlendirilmeli. (4) Chow & Liu 2008, 14.6-14.7.1: iki düzeyli modelde (kap + tekrar; seri yok) örneklem büyüklüğü yöntemi (Chow, Shao, Wang 2003a, Stat Med 22:55-68) ve simülasyon; eski sabitler (θ = 1,125; σ₀ = 0,2); 30 kap çoğu zaman yetersiz güç; kaplar arası varyans varken kap sayısını artırmak tekrar sayısını artırmaktan iyi.
- **Model (Ö, tartışma sürüyor):** Varyans bileşenleri (karma) modeli, log ölçeği: X = μ_k + b (seri, rastgele) + c (seri içinde kap, rastgele) + τ (yaşam evresi, sabit) + e. Beklenen kareler ortalamaları Claude tarafından türetildi (kaynakta yok; FarmaStatR türetimi) ve 20.000 tekrarlı Monte Carlo ile kontrol edildi; seri varyansı ve evre etkisi sıfırken Chow & Liu 2008 s. 479 sonucuyla örtüşüyor. Sonuç: E[σ̂²] = σ²_C + σ²_W + Στ²/m + n(ℓ-1)/(nℓ-1)·σ²_B. Proje sahibi türetimin kaynağını sordu; kaynaktan gelen / türetilen / yorum ayrımı açıkça yapıldı; SAS PROC GLM (RANDOM, beklenen kareler ortalamaları) ile bağımsız kontrol önerildi.
- **Karar (K): KK-22.** Seri etkisi **rastgele**: üretilmiş ve üretilecek serilere genelleme ancak böyle istatistiksel olarak doğru. Estimand (toplam varyans) seri varyansını içerir. Varsayım (makalede yazılacak): seriler seri popülasyonunu temsil eder.
- **Karar (K): KK-23.** Araştırma sorusunun odağı **seri başına kap sayısı n** (PSG: 10). Seri sayısı ℓ = 3 ve yaşam evresi sayısı m = 3 (B/M/E) PSG'deki gibi sabit. (Claude'un "seri sayısı" çerçevelemesi proje sahibince düzeltildi.)
- **Açık:** (1) Yaşam evresi kaymasının (1/m)Στ² estimand'a katılıp katılmayacağı. (2) Teknik not (model + ADEMP) yazılacak; kodlama onaydan sonra. (3) Türetimin SAS ile bağımsız kontrolü (isteğe bağlı).

## G-17 · Birincil kaynak: FDA 1999 (Haziran taslağı IX.B + 18 Ağustos 1999 istatistik bilgisi) — 14.10.2026

- **Kaynak (proje sahibi sağladı):** *Statistical Information from the June 1999 Draft Guidance and Statistical Information for In Vitro Bioequivalence Data Posted on August 18, 1999* (FDA, 04/10/03 derlemesi). PSG 020121 ve 021433 bu belgeye atıf yapar.
- **Saptananlar (doğrudan alıntı):**
  1. IX.B.2.a: σ²_R = σ²_BR + σ²_CR + σ²_LR ve σ²_T = σ²_BT + σ²_CT + σ²_LT. B = seriler arası, C = kaplar arası, L = kap içi yaşam evreleri arası standart sapma. **Toplam varyans seri varyansını açıkça içerir.**
  2. IX.B.1: "Rather than evaluate performance at each life stage separately, a criterion is recommended that combines the multiple life stages … Lack of uniformity between life stages should be treated as another variance component in the criterion."
  3. IX.B.2.a: Ortalamalar tüm kaplar, yaşam evreleri ve seriler üzerinden alınır.
  4. IX.B.1: En az 30 birim (3 serinin her birinden en az 10); "The number of units is a function of T to R product means and variances. Estimates … will necessitate pilot studies." Seri başına 10 kap bir alt sınırdır; sayı ortalama ve varyanslara göre belirlenmelidir.
  5. IX.B.2.b: Momentler yöntemi önerilir; REML özel durumlarda kullanılabilir.
  6. 18 Ağustos 1999: "Since three batches are not sufficient to reliably estimate the between batch component of variance, the total variances are estimated as the between canister variance of the 'super-batch' consisting of the three batches combined." PSG tahmin edicisinin seri düzeyini havuzlaması bu bilinçli yaklaşımdan gelir. Evre bileşeni sonradan eklendi (MSW).
- **Sonuç:** G-15/G-16'da "FarmaStatR türetimi" olarak işaretlenen iki nokta artık **kaynağa dayalıdır**: (i) toplam varyans seri varyansını içerir (KK-22 ile tutarlı); (ii) yaşam evreleri arası tekdüzelik eksikliği bir varyans bileşenidir. Araştırma sorusu FDA'nın kendi çerçevesinde kurulur: üç bileşenli modelde "süper-seri" yaklaşımlı PBE prosedürünün, seri başına kap sayısına (n) göre tip I hata ve gücü.
- **Düzeltme (Claude):** G-16 öncesinde Claude "hiçbir kaynak σ²'nin seri varyansını içerdiğini doğrudan söylemiyor" demişti; FDA 1999 IX.B.2.a bunu doğrudan söylüyor.

## G-18 · Karar: yaşam evresi değişkenliği toplam varyansa dahil; kaynaklar proje dosyalarında — 14.10.2026

- **Karar (K): KK-24.** Yaşam evreleri arası tekdüzelik eksikliği (rastgele ve sistematik) toplam varyansın bir bileşenidir. Estimand: σ²_k = σ²_B,k + σ²_C,k + σ²_L,k (FDA 1999 Haziran taslağı IX.B.1 ve IX.B.2.a). Veri üretiminde σ²_L = σ²_W + (1/m)Στ² ayrımı yalnızca kayma senaryolarını kurmak için kullanılır (FarmaStatR türetimi; estimand'ı değiştirmez). m ürün tipine göre 1, 2 ya da 3 (PSG 020121, 021433, 020929).
- **Kaynaklar (K):** Chow & Liu 2008, FDA 2026 (Mayıs) ve FDA 1999 belgesi proje dosyalarına eklendi. Proje sahibinin notu: Chow & Liu 2008, f2 ve MSD gibi profil benzerliği değerlendirmelerinde de (Bölüm 15) kaynak olarak kullanılmalı.
- **Sıradaki:** Teknik not (model, estimand, ADEMP, kaynak eşlemesi); kodlama notun onayından sonra.

## G-19 · Teknik not FSR-TN-PBE-01 v0.1 (taslak) — 14.10.2026

- **İş (K: "ben uyurken sen teknik notu yaz"):** Proje sahibi yokken yazıldı; verilen kararlar notun 0. bölümünde listelendi (dil TR, biçim Word, parametrelendirme, faktör düzeyleri, hızlı eşdeğer tahmin edici, belge numarası). Hepsi onay bekliyor.
- **Dosya:** `belgeler/teknik_notlar/FSR-TN-PBE-01_v0.1.docx` (9 sayfa). Ekler: `FSR-TN-PBE-01_ek/ems_check.R` ve `ems_check.csv`.
- **İçerik:** amaç ve araştırma sorusu; kaynak-katkı tablosu; PBE kriteri ve PSG prosedürü (PSG 020929 Adım 1-5); "süper-seri" kökeni (FDA 1999); tasarım ve gösterim (ℓ = 3, n araştırma faktörü, m = 1/2/3); veri üretme modeli (seri, kap rastgele; evre bileşeni σ²_L = σ²_W + Στ²/m); estimand (FDA 1999 IX.B.2.a); PSG tahmin edicisinin beklenen değerleri, yanlılığı, ortalama farkı varyansının eksik tahmini, χ² varsayımlarının bozulması (FarmaStatR türetimi); beş hipotez (Hp1-Hp5); ADEMP (önerilen ızgara, n_sim = 10.000); doğrulama planı; sınırlılıklar; SAS PROC GLM/MIXED kontrol kodu; adım adım türetimler.
- **Doğrulama:** Beklenen kareler ortalamaları ve ortalama varyansı formülleri 30 konfigürasyonda (n ∈ {5, 10, 20}, m ∈ {1, 2, 3}, σ_B ∈ {0; 0,2}, evre kayması var/yok), her biri 20.000 veri setiyle sınandı: 150 karşılaştırmada en büyük |z| = 2,39. Satterthwaite etkin serbestlik derecesi örneği (σ_B = 0,2, σ_C = 0,3, σ_W = 0,05, m = 3): n = 10 için 16,7 (nominal 29). PSG'nin ortalama farkı varyans tahmini gerçeğin n = 10'da yaklaşık %24'ü.
- **Bulunan nokta:** Evre kayması varsa MSW merkezi olmayan χ² dağılımına uyar (PSG merkezi χ² varsayar); hipotez Hp5 olarak eklendi.
- **Açık:** Notun proje sahibince incelenmesi ve onayı; İngilizce sürüm onaydan sonra; kodlama onaydan sonra.

## G-20 · Çalışma kuralı: ikincil atıflar için birincil kaynak istenir — 15.10.2026

- **Karar (K): KK-25.** Claude, yalnızca başka bir kaynak üzerinden bildiği (birincil metnini okumadığı) her kaynağı listeler ve proje sahibinden proje dosyalarına yüklenmesini ister; yüklenen birincil kaynağı ayrıntılı inceler ve belgeleri ona göre günceller. Birincil metin okunana kadar atıf "aktaran: …" biçiminde işaretli kalır.
- **Tespit (Claude):** Atıf denetimi yapıldı. Birincil metni okunmamış kaynaklar: Chow, Shao, Wang 2003a (Stat Med 22:55-68); Hyslop, Hsuan, Holder 2000 (Stat Med 19:2885-2897); Howe 1974 (JASA 69:789-794); Ting ve ark. 1990 (J Stat Comput Simul 35:135-143); Morris, White, Crowther 2019 (Stat Med 38:2074-2102; simülasyon altyapısının performans formülleri); Langenbucher 1972 (J Pharm Pharmacol 24:979-981); ICH M9 (2019). Teknik notta kaynaksız kullanılan Satterthwaite yaklaşımı (Satterthwaite 1946) ve iç içe ANOVA beklenen kareler ortalamaları için bir ders kitabı kaynağı da eklenmeli. Proje dosyalarındaki numaralı dosyaların eşlemesi doğrulandı (ör. dosya 8 = Sathe ve ark. 1996, DOI 10.1023/A:1016020822093).

## G-21 · Birincil kaynaklar okundu; teknik not v0.2 — 15.10.2026

- **İş (K: "kaynakları düzenledim … 5 değişikliği yeniden gözden geçir"):** G-19/G-20'deki beş değişiklik (teknik not, iki ek, OKUBENI, günlük) yeni yüklenen birincil kaynaklarla karşılaştırıldı (KK-25).
- **Okunan birincil kaynaklar:** Chow, Shao, Wang 2003 (Stat Med 22:55-68); Hyslop, Hsuan, Holder 2000 (Stat Med 19:2885-2897); Howe 1974 (JASA 69:789-794); Satterthwaite 1946 (Biometrics Bull 2:110-114); Morris, White, Crowther 2019 (Stat Med 38:2074-2102); Searle, Casella, McCulloch 2006 (Variance Components; Tablo 4.10, Bölüm 4.5); ICH M9 (2019) Bölüm 3.2.2 ve ICH M9 Soru-Cevap.
- **Sonuç:** v0.1'in hiçbir türetimi ya da sayısal sonucu değişmedi. Bulgular:
  1. PSG'nin σ̂² ayrıştırması, Chow ve ark. 2003 Bölüm 2'deki s²_B ve (1 − 1/m)s²_W tahmin edicileriyle cebirsel olarak aynıdır. Dikkat: makalede m kap sayısı, n tekrar sayısıdır; bizde tersidir.
  2. Üst sınırın E-H-U yapısı Hyslop ve ark. 2000 Bölüm 3 Adım 1-3'tür (Denk. 20-22); Howe 1974 Approximation I'in (Denk. 3.4) ikiden fazla değişkene genişletilmesidir. PSG ortalama teriminde t kantili kullanır (Hyslop Denk. 20); Chow ve ark. 2003 z kullanır. Bu yüzden Chow'un tip I hata tablosu ile karşılaştırma yalnızca niteldir.
  3. Chow ve ark. 2003 modeli (5) "no period effect" varsayar; teknik notun evre kayması (q > 0) bu varsayımdan bilinçli sapmadır, FDA 1999 IX.B.1'e dayanır.
  4. Denk. 14 (E[MSB]) artık Searle ve ark. 2006 Tablo 4.10'dan, PSG'nin iki satırı havuzlamasıyla doğrudan elde edilir. χ² ve bağımsızlık varsayımları Searle Bölüm 4.5a (Denk. 34), evre kaymasında merkeziyetsizlik de aynı bölümdendir. Etkin serbestlik derecesi Satterthwaite 1946 Denk. 6 (beklenen değerlerle); katsayılar pozitif olduğundan negatif katsayı uyarısı geçerli değildir.
  5. Chow ve Liu 2008 kitabındaki aktarımda dizgi hataları var (sayısal örnekte üst sınırın işareti, s²_T = 0,29889 → makalede 0,292889, bir gözlemde σ_T² ile σ_R² arasındaki eşitsizliğin yönü); makale esas alınır.
  6. `sim_performance.R`, Morris ve ark. 2019 Tablo 6'nın 9 ölçütünden 8'ini birebir uygular (eksik: göreli hassasiyet artışı; yalnız yöntem karşılaştırmasında gerekir). `sim_n_required` Denk. 1 ve Bölüm 7.1 örnekleriyle (1900, 1600) uyumlu. Kod değişikliği gerekmedi.
  7. `f2_boot.R`'nin M9 CV kuralı (≤ 10 dk %20, sonrası %10; ihlal CV > sınır) ICH M9 Bölüm 3.2.2 metniyle aynı. Gözlem (değişiklik yok, A-9'a not): M9 "≥ %85" yazar, EMA Ek I "> %85"; kod EMA perspektifinde EMA metnini izler. ICH M9 Soru-Cevap 3.2.3: BCS Sınıf I ürünlerde yüksek değişkenlikte bootstrap gibi alternatif yöntemler "not considered applicable"; bu kısıt yalnız BCS biyomuafiyeti bağlamındadır ve `calc_f2_boot` belgesine kullanım notu olarak eklenmeli (A-9).
  8. "An_Approximate_Confidence_Interval_for_the_Varianc.pdf" = Alamro, Al-Shiha, Almohisen 2023 (Int J Stat Probab 12(4):40-63). Ting ve ark. 1990'ın yerini tutmaz; teknik notta kullanılmadı.
- **Dosyalar:** `belgeler/teknik_notlar/FSR-TN-PBE-01_v0.2.docx` (11 sayfa; Bölüm 0.1'de değişiklik listesi; v0.1 dosyası kayıt olarak kalır). `FSR-TN-PBE-01_ek/ems_check.R`: yalnızca başlık yorumu (kaynak satırı); sonuç tablosu değişmedi. OKUBENI değişmedi.
- **Yeni açık noktalar (teknik not Bölüm 11):** (6) tüm senaryolarda ortak seed (Morris ve ark. 2019 Bölüm 5.4); (7) Ting ve ark. 1990 birincil metnine ulaşılamadı.
- **Hâlâ eksik birincil kaynaklar:** Ting ve ark. 1990; Langenbucher 1972 (Weibull MSD; teknik notla ilgisiz).

## G-22 · Varyans bileşenlerinin anlamı; "3 seri"nin kaynağı; EMA kapsama alındı — 15.10.2026

- **Açıklama (proje sahibinin isteği):** PSG 020929 formüllerinin kaynağı olan ANOVA modeli açıklandı. PSG'nin MSB ve MSW'si, kaplar grup, evreler tekrar olmak üzere tek yönlü rastgele etkili ANOVA'nın kareler ortalamalarıdır (Chow, Shao, Wang 2003 model 5; Searle ve ark. 2006 Tablo 4.8). PSG'deki "(MSB − MSW)/m: between-bottle variability" ve "MSW: within-bottle variability" tanımları ile σ̂² = MSB/m + (m−1)MSW/m bu modelin momentler yöntemi tahminleridir. Kontrol: PSG'nin kendi E3s/E4s değerlerinden 0,163603 + 0,000125 = 0,163728 = PSG'deki σ²_R. FDA 1999'un üç bileşenli tanımı iki düzeyli iç içe ANOVA'ya karşılık gelir (Searle Tablo 4.10); PSG seri satırını kaplarla havuzlar.
- **Düzeltmeler (Claude):** (1) PSG 020929 örnek verisi simüle edilmiştir ("The data given in this example are simulated"). (2) Claude, Budesonid'de evre olmadığını (m = 1) önermişti; proje sahibi düzeltti: B/M/E evreleri vardır; teknik nottaki m = 3 doğrudur. (3) Claude "FDA seri değişkenliğini dikkate almıyor" demişti; doğrusu: ayrı tahmin etmiyor ve kısmen eksik sayıyor (toplam varyansta n = 10'da yaklaşık %69'u, ortalama farkının varyansında yaklaşık %7'si yakalanır; teknik not Denk. 15, 17-18).
- **Veri gözlemleri:** Chow ve Liu 2008 Tablo 14.5.10 (log D50, REML) payları: R için seri 0,25, kap 0,49, evre 0,26; T için 0, 0,70, 0,30 (bileşenler toplamla tutarlı). Tablo 14.5.11 (log SPAN): bileşenler "Total" satırıyla tutmuyor (R: 0,0144 ≠ 0,0347). PSG örnek verisinde (simüle) payların neredeyse tamamı kaplar arası.
- **"En az 3 seri"nin kaynağı (birincil metinler okundu):** ICH Q1A(R2) §2.2.3 "at least three primary batches", §2.2.9 "a minimum of three batches … The degree of variability of individual batches affects the confidence that a future production batch will remain within specification"; §1.2 jenerikleri ("abbreviated or abridged applications") kapsam dışı bırakır. FDA ANDA Stability Q&A (Mayıs 2014): "please follow ICH Q1A(R2) recommendations for all ANDAs", "three batches". PSG 020929 "three primary stability batches". Hiçbir halka "3"ü istatistiksel olarak türetmez; asgari düzenleyici sayıdır. Q1A §2.2.9 seri havuzlamasını bir ön teste bağlar (p > 0,25); PSG koşulsuz havuzlar.
- **EMA (birincil metin okundu): CPMP/EWP/4151/00 Rev. 2** (CHMP 14.07.2025; yürürlük 01.02.2026). Basamaklı yaklaşım (§4.1); nebülizasyon ürünleri kapsamda, Q1/Q2 aynıysa APSD karşılaştırmasından muafiyet mümkün (§4.2.2). §5.1: istatistik gerektiren üç ölçüt: 6 hava akışı direnci ±%15, 7 hedef verilen doz ±%15 (ikisinde de yöntem tanımlı değil), 8 APSD: geometrik ortalamalar oranının %90 GA'sı 85-118 (log-normal). "At least three consecutive batches … minimum of ten inhalers or units of each batch. If there is a high variability, a larger number of batches and/or more inhalers per batch needs to be tested." Seri ve birim sayısı tip II hata riskini en aza indirmeli (dipnotta "patient risk" olarak tanımlı; klasik eşdeğerlik terminolojisinden farklı). §5.2.3: referans serileri arası değişkenlik "can be significant"; karakterizasyon için en az 5 seri. Evreler (B/M/E) metinde geçmez. %90 GA'nın seri ve evre yapısıyla nasıl hesaplanacağı tanımlı değil.
- **Karar (K): KK-26.** Çalışma EMA'yı da kapsar: FDA PSG PBE prosedürü ile EMA OIP in vitro yöntemi aynı veri üretme modelinde karşılaştırılır. Proje sahibinin önceliği EMA.
- **Karar (K): KK-27.** EMA %90 GA'sı üç yöntemle hesaplanır ve karşılaştırılır (hepsi FarmaStatR türetimi): (a) havuzlanmış birimler ("süper-seri" karşılığı); (b) seri ortalamaları; (c) seri rastgele etkili karma model (REML).
- **Açık:** Format kararı (varyans girişi: toplam + paylar / bileşenler / iki yol) beklemede; proje sahibi önce bileşenlerin anlamının netleşmesini istedi. EMA insan ilaçları stabilite kılavuzu CPMP/QWP/122/02 Rev. 1 birincil metni yok (yalnız veteriner karşılığı görüldü; kullanılmadı). Teknik not v0.3 (EMA kolu, KK-26/27, düzeltmeler) yazılacak.

## G-23 · Araştırma sorusu genişletildi: seri sayısı ve seri başına ampul birlikte — 15.10.2026

- **Karar (K): KK-28.** KK-23 genişletildi. Seri sayısı ℓ ile seri başına birim (ampul) sayısı n birlikte araştırma faktörüdür. Temel tasarım 3 test + 3 referans seri × 10 ampuldür. Düzenleyici alt sınırların (ℓ ≥ 3: PSG "at least three batches", EMA OIP §5.1 "at least three consecutive batches"; n ≥ 10: PSG "no fewer than 10 units from each batch", EMA "a minimum of ten inhalers or units of each batch") dışındaki tasarımlar yalnızca karşılaştırma amacıyla ve etiketlenerek gösterilir. Toplam birim sayısı sabitken farklı ℓ × n dağılımları (ör. 2 × 15, 3 × 10, 4 × 7, 5 × 6) karşılaştırılır.
- **Gerekçe (proje sahibi):** Seri değişkenliği PSG'de ayrı tahmin edilmediğine göre seri sayısının ve dağılımın etkisi sorulmalı; üretim serilerinden gelen değişkenlik gözden kaçırılmamalı.
- **Destekleyici gözlem (FarmaStatR türetimi, teknik not Denk. 15, 18):** PSG'de yakalanan seri varyansı payı toplam varyansta n(ℓ−1)/(nℓ−1), ortalama farkı varyansında (ℓ−1)/(nℓ−1): 2 × 15: %52 / %3; 3 × 10: %69 / %7; 4 × 7: %78 / %11; 5 × 6: %83 / %14. Ortalamanın gerçek varyansındaki σ²_B/ℓ terimini yalnız seri sayısı küçültür. Kaynakta benzer ilke iki düzeyli modelde: Chow, Shao, Wang 2003 Bölüm 3 gözlem 3 ("having more canisters is preferred than having more replicates within each canister"); bizim modelde bir düzey yukarıda hipotez olarak sınanacak.
- **Gösterim kararı:** ℓ seri sayısı, n seri başına birim (Budesonid'de ampul; PSG'de "canisters or bottles", "container", "unit"), m evre sayısı (B, M, E); indisler k ürün, j seri, i birim, s evre (PSG MSB/MSW gösterimi). Chow, Shao, Wang 2003'te m ile n ters anlamdadır.
- **PSG bulgusu (proje sahibinin gönderdiği sayfa görüntüsüyle doğrulandı):** PSG 020929 Appendix Adım 2'de X̄..k. formülünün indis aralıkları MSB/MSW ile ters yazılmıştır (Σ_{i=1}^{ℓk} Σ_{j=1}^{nk}); toplam tüm birimler üzerinden olduğundan sonuç değişmez. Adım 4 tablosu teknik not ve `calc_pbe` ile birebir uyumlu.
- **Açık:** Varyans giriş biçimi kararı (B seçeneği: makale ızgarası toplam + paylarla, platform iki yolla) bekliyor.

## G-24 · Varyans giriş biçimi kararı; PBE'nin ölçek değişmezliği — 15.10.2026

- **Karar (K): KK-29.** Makalenin simülasyon ızgarası "toplam σ_R + ρ (= σ_T/σ_R) + paylar (p_B, p_C, p_L; toplamı 1)" ile kurulur. Pay = bileşen varyansı / toplam varyans (p_B, seri düzeyindeki sınıf içi korelasyon katsayısıdır). Platformda kullanıcı ister payları, ister bileşenleri (σ_B, σ_C, σ_W; ör. kendi REML tablosundan) girer; bileşenler paylara çevrilir ve iki gösterim birlikte gösterilir. Gerekçe: bir koşul (ör. seri payı) değiştirildiğinde toplam σ_R, dolayısıyla kriter ve tip I hata sınırı δ₀ sabit kalır; ℓ × n'nin etkisi farklı varyans yapılarında aynı noktada karşılaştırılır (FarmaStatR türetimi).
- **δ₀ açıklaması:** σ_T = σ_R iken referans ölçekli kriterde η = 0 sınırı δ₀ = √θ_p·σ_R = 1,4454·σ_R (teknik not Denk. 12); örn. σ_R = 0,304 → 0,440 (GMR 1,55), 0,364 → 0,526 (GMR 1,69). Sabit ölçekli bölgede δ₀ = √(θ_p·0,01) = 0,1445 (GMR 1,155).
- **Bulgu (FarmaStatR türetimi; sayısal olarak doğrulandı):** Referans ölçekli PBE ölçek değişmezdir: tüm log ölçümler c ile çarpılınca E_q, H_q, U_q bileşenleri c² (U_q c⁴) ile ölçeklenir, H_η işaretini korur. `calc_pbe` ile PSG örnek verisinde c = 0,5 ve 2 için H_η,Ref/c² = −0,03149874 (özgün değerle birebir). Sabit ölçekli kriter (θ_p·σ²_T0 sabit terimi) değişmez değildir; c = 0,2'de σ̂_R < 0,1 olduğundan sabit ölçekli kriter seçilir ve karar değişir. Sonuç: PBE'de tip I hata ve güç, σ_R > 0,1 bölgesinde σ_R'nin büyüklüğüne değil, paylara, ρ'ya, δ/σ_R'ye ve ℓ, n, m'ye bağlıdır; σ_R yalnızca 0,1 eşiğine göre konumuyla önemlidir. EMA %90 GA yönteminde sınırlar (85–118) sabit olduğundan σ_R'nin büyüklüğü doğrudan önemlidir.
- **σ_R'nin planlama değeri:** FDA 1999 IX.B.1 ("will necessitate pilot studies"); EMA OIP §5.2.3 (referansın en az 5 seriyle karakterizasyonu). Referans ürün piyasadan alınarak ölçülebilir.
- **Açık:** q (evre içi sistematik kayma) ve T ile R için payların aynı mı ayrı mı olacağı; faktör düzeyleri (teknik not Bölüm 8.2); teknik not v0.3.

## G-25 · Test ve referans payları: ana senaryolarda aynı, hedefli senaryolarda ayrı — 15.10.2026

- **Karar (K): KK-30.** Simülasyon senaryolarının çoğunda (ana ızgara) test ve referansın varyans payları (p_B, p_C, p_L) aynıdır; ürünler arasındaki toplam değişkenlik farkı ρ ile verilir. Ek olarak iki hedefli senaryo grubu birkaç seçilmiş σ_R ve ℓ × n değerinde koşulur: (i) seri varyansı yalnız referansta, (ii) seri varyansı yalnız testte. Platformda kullanıcı iki ürünün paylarını her zaman ayrı girebilir.
- **Gerekçe:** Chow ve Liu 2008 Tablo 14.5.10'daki T–R pay farkı (lot payı R 0,25, T 0) 2 serbestlik derecesine dayanır; T'deki 0 REML'in sıfır sınırına takılmasıdır; gerçek bir yapı farkının kanıtı değildir. Hedefli senaryoların gerekçesi (FarmaStatR türetimi, teknik not Denk. 16'dan; hipotez): PSG havuzlaması nedeniyle eksik tahmin η̂ = Δ̂² + σ̂²_T − (1+θ_p)σ̂²_R üzerinde ters yönde işler: yalnız referansta seri varyansı → σ̂²_R eksik → η̂ büyür → tutucu (güç kaybı); yalnız testte → σ̂²_T eksik → η̂ küçülür → liberal (tip I hata artışı; hasta riski). Karşılıkları: EMA OIP §5.2.3 (referans serileri arası değişkenlik "can be significant"); yeni üreticinin henüz oturmamış süreci.
- **Açıklama notları:** "Pay" = toplam varyansın kaynağa göre yüzdesi (pasta dilimi). "Izgara" = simülasyon senaryolarının tam listesi (faktör düzeylerinin kombinasyonları; Morris ve ark. 2019 §3.2 "data-generating mechanisms"); projede 2. hesaplama katmanı (SQLite sonuç ızgarası). Chow ve Liu 2008 Tablo 14.5.10 bağlamı: burun spreyi, lazer difraksiyon D50, 3 lot × 10 şişe × 3 evre, 3 mesafe (3, 5, 7 cm); tablonun mesafeleri nasıl ele aldığı belirtilmemiş. Kitap REML'i "as suggested by the FDA draft guidance" diye anar; FDA 1999 IX.B.2.b momentler yöntemini önerir.
- **Açık:** q (evre içi sistematik kayma); faktör düzeyleri (teknik not Bölüm 8.2); teknik not v0.3.

## G-26 · Evre içi sistematik kayma (q) yalnız duyarlılık analizinde; faktör düzeylerinin rolü — 15.10.2026

- **Karar (K): KK-31.** q (evre varyansının tüm birimlerde aynı yönde olan sistematik kaymadan gelen payı; ör. dozun B'den E'ye düzenli düşmesi) ana senaryolarda 0 alınır; q > 0 yalnız duyarlılık analizinde kullanılır.
- **Gerekçe:** PSG rastgele ve sistematik evre farkını ayırmaz (ikisi de MSW, "within-bottle variability"); FDA 1999 IX.B.1 tekdüzelik eksikliğini varyans bileşeni sayar. Sistematik kayma MSW'yi merkezi olmayan χ²'ye dönüştürür (teknik not Bölüm 7.4, Hp5). Verilerde belirgin kayma yok: PSG 020929 örnek verisinde (simüle) evre etkisi p = 0,68; Chow ve Liu 2008 Tablo 14.5.7'de D50 için evrelere göre GMR %98,7–103,6.
- **Açıklama (proje sahibinin sorusu):** Faktör düzeyleri kullanıcının yerine seçilmez; proje ilkesi gereği tüm parametreler platformda kullanıcı tarafından ayarlanabilir (1. katman, tarayıcıda koşu). Seçilen düzeyler yalnızca (i) makalenin önceden belirlenmiş senaryo listesini (Morris ve ark. 2019 §8.1: koşudan önce protokol; seçici raporlamaya karşı) ve (ii) önceden hesaplanmış SQLite sonuç ızgarasını (2. katman) tanımlar.
- **Sıradaki:** faktör düzeyleri (σ_R, ρ, paylar, ℓ × n, δ); ardından teknik not v0.3 (EMA kolu ve KK-26 … KK-31).

## G-27 · Faktör düzeyleri veriye dayandırıldı; zorlama senaryoları — 15.10.2026

- **İlke (proje sahibi):** Düzey önerileri Chow ve Liu 2008 ve PSG'ye dayanmalı; veride karşılığı olmayan değer uydurulmamalı.
- **Veri analizi (FarmaStatR türetimi; hesap Claude'a ait):** Chow ve Liu 2008 Tablo 14.5.2 (D50) ve 14.5.3 (SPAN) ham verisi (butorfanol burun spreyi T, Stadol NS R; 3 lot × 10 şişe × 3 evre; 3, 5, 7 cm; Bölüm 14.5.1) metinden aktarıldı ve her değişken, mesafe ve ürün için ayrı ayrı log ölçeğinde PSG MSB/MSW ile iki düzeyli iç içe ANOVA'nın lot satırından (Searle ve ark. 2006 Tablo 4.10) varyans bileşenleri hesaplandı. İki bağımsız uygulama (lm tabanlı ve temel R) aynı sonucu verdi. Sonuçlar: σ 0,059–0,164; R'de p_B 0,05–0,32 (D50'de lot farkı üç mesafede anlamlı, p ≈ 0,01), T'de p_B 0 (yalnız SPAN 3 cm 0,19, p = 0,027); p_L 0,07–0,31; ρ = σ_T/σ_R 1,00–1,14. PSG örneği (simüle): σ_R 0,41, ρ 1,16, p_B 0,03–0,05, p_L ≈ 0.
- **Gözlem:** Tablo 14.5.10'daki evre bileşeni (R 0,0053) mesafe başına hesaplananlardan (0,001–0,003) büyüktür; mesafeler arası ortalama farkı (D50 yaklaşık 58, 52, 53 µm; log ölçeğinde yaklaşık 0,0026) farkı büyük ölçüde açıklar. Çıkarım: kitap tablosu mesafeleri birleştirmiş olabilir (kitap açıklamaz). Mesafe başına hesaplar esas alınır.
- **Karar (K): KK-32.** Makale senaryo listesi düzeyleri (veriye dayalı): σ_R 0,06; 0,08; 0,10; 0,12; 0,16 (Chow) ve 0,40 (PSG örneği); ρ 1,00; 1,15; p_B 0; 0,10; 0,30; p_L 0,01; 0,15; 0,30 (p_C kalan); ℓ 2–6, n 5–30 (temel 3 × 10; KK-28); güç için GMR 1,00; 1,05; 1,10 (Chow Tablo 14.5.7: D50 0,99–1,04, SPAN 0,95–0,98; PSG örneği |Δ̂| = 0,149, GMR 1,16); tip I hata için δ₀ (teknik not Denk. 12). Veride karşılığı olmayan σ_R = 0,25, ρ = 0,8 ve p_B = 0,50 **"zorlama senaryosu"** etiketiyle tutulur.
- **Sınırlılık:** Düzeyler tek bir gerçek ürüne (butorfanol burun spreyi) ve bir simüle veriye dayanır; Budesonid için varyans verisi yok. Makalede belirtilecek.
- **Dosyalar:** `belgeler/teknik_notlar/FSR-TN-PBE-01_ek/chow_vc.R` ve `chow_vc.csv` (sonuçlar). Kitaptan aktarılan ham veri dosyası (chow1452.csv) telifli kaynaktan alındığı için depoya konmadı; depoya girip girmeyeceği proje sahibine sorulacak.
- **Sıradaki:** teknik not v0.3 (EMA kolu ve KK-26 … KK-32).

## G-28 · Chow ham verisi depoya eklendi — 15.10.2026

- **Karar (K): KK-33.** Chow ve Liu 2008 Tablo 14.5.2 ve 14.5.3'ten aktarılan ham veri (`chow1452.csv`, 1080 satır) kaynağı belirtilerek depoya konur. Gerekçe (proje sahibi): kitap artık kamuya açık. Böylece `chow_vc.R` depodaki verilerle birebir yeniden üretilebilir.
- **Doğrulama:** Betik depo dosyasıyla yeniden koşuldu; `chow_vc.csv` değişmedi. G-27 commit'i sonrası GitHub Actions GEÇTİ (proje sahibi).
- **Not:** `chow_vc.R` başlık yorumu güncellendi (veri artık depoda).

## G-29 · Teknik not FSR-TN-PBE-01 v0.3 — 15.10.2026

- **İş (K: "şimdi başla"):** KK-26 … KK-33 tek belgede toplandı. Dosya: `belgeler/teknik_notlar/FSR-TN-PBE-01_v0.3.docx` (11 sayfa). Başlık genişletildi: "In vitro eşdeğerlik: seri sayısı ve seri başına birim sayısı için istatistik model ve simülasyon tasarımı (FDA PBE ve EMA OIP)"; belge numarası korundu.
- **Yeni bölümler:** sürüm geçmişi (0); gösterim (3; Chow ters gösterimi ve PSG indis tutarsızlığı); PSG tahmin edicisinin kaynağı olan tek yönlü ANOVA ve PSG sayılarıyla kontrol (4.2); EMA OIP yöntemi ve üç GA yolu (5); parametrelendirme ve T/R payları, q (6.1); ℓ × n yakalanan pay tablosu (8.1); ölçek değişmezliği (8.3); Hp6 (T/R asimetrisi) ve Hp7 (EMA yolları); gerçek veri varyans yapısı (9); veriye dayalı senaryo listesi ve zorlama düzeyleri (10.2); kaynakça (EMA OIP, ICH Q1A(R2), FDA ANDA S-C eklendi); Ek A.7 ve Ek B'ye PROC MIXED.
- **Yeni bulgu (FarmaStatR türetimi; sayısal olarak doğrulandı):** Dengeli tasarımda REML seri varyansını pozitif tahmin ettiğinde EMA yolu (c) ile (b) aynı SE'yi verir (Var(X̄) = E[MS_seri]/(ℓnm)). Chow ham verisinde temel R ile yazılan REML: seri varyansı pozitif 7 veri setinde SE'ler birebir aynı (ör. D50 3 cm R 0,055751); sıfırda kesilen 5 veri setinde REML SE'si seri ortalaması SE'sinin 1,3–3,8 katı. (b) seri ortalamaları tesadüfen yakın düştüğünde aşırı iyimser olabilir.
- **Senaryo sayısı:** m = 3 için tam faktöriyel ana liste 21.600 (6 σ_R × 2 ρ × 3 p_B × 3 p_L × 40 ℓ × n × 5 δ); m = 2 için 21.600; m = 1 için 7.200. Aşamalandırma açık.
- **Açık (notun 13. bölümü):** aşamalandırma ve n_sim; hızlı PBE eşdeğeri ve EMA (c) kapalı biçimi; ortak seed; EMA'da tek büyüklükle başlama; Ting 1990; İngilizce sürüm.

## G-30 · Senaryo listesi iki aşamaya indirildi (yaklaşık 620 senaryo) — 15.10.2026

- **Gerekçe (proje sahibi):** Tam faktöriyel liste (m = 3 için 21.600 senaryo) yönetilebilir değil.
- **Karar (K): KK-34.** Morris ve ark. 2019 §3.2 (temel senaryo + birlikte değiştirilen ana faktörler + birer birer değiştirilen koşullar; uç noktalarda etkileşim kontrolü).
  - **Temel senaryo (veriye dayalı öneri):** σ_R 0,12 (Chow 0,06–0,16 ortası, 0,1 eşiği üzerinde); ρ 1,00 (Chow 1,00–1,14); p_L 0,15 (Chow 0,07–0,31); m 3 (Budesonid); q 0 (KK-31).
  - **Aşama 1 (araştırma sorusunun çekirdeği):** p_B {0; 0,10; 0,30} × ℓ {2, 3, 4, 5, 6} × n {5, 8, 10, 15, 20, 30} × δ {FDA δ₀; EMA GMR 1,18; GMR 1,00; GMR 1,05} = 360 senaryo; her senaryoda FDA PBE ve EMA yolları (a), (b), (c) aynı veri setlerine uygulanır.
  - **Aşama 2 (birer birer):** temelden tek faktör değiştirilir; 4 tasarım (3 × 10, 3 × 20, 5 × 10, 6 × 5) × 4 δ: σ_R {0,06; 0,08; 0,10; 0,16; 0,40}; ρ 1,15; p_L {0,01; 0,30}; m {1; 2}; q 0,5; T/R hedefli (yalnız R / yalnız T); zorlama (σ_R 0,25; ρ 0,80; p_B 0,50) = yaklaşık 256 senaryo.
  - **Toplam** yaklaşık 620 senaryo; n_sim 10.000 ile yaklaşık 6 milyon veri seti.
  - **Dayanak:** ölçek değişmezliği (G-24; teknik not 8.3): σ_R > 0,1 bölgesinde PBE sonuçları σ_R'nin büyüklüğüne bağlı değil; çok sayıda σ_R düzeyi yalnız EMA ve eşik çevresi için gerekli.
  - Listede olmayan her kombinasyon platformda kullanıcı tarafından koşulabilir.
- **Açık:** n_sim onayı; hızlı PBE eşdeğeri ve EMA (c) kapalı biçimi; ortak seed; EMA'da tek büyüklük; teknik not v0.4'te Bölüm 10.2'nin bu kararla güncellenmesi.

## G-31 · Simülasyon yürütme kararları; teknik not v0.4 — 15.10.2026

- **Karar (K): KK-35** (proje sahibi dört öneriyi onayladı: "ok … ilerleyebilirsin"):
  1. Senaryo başına tekrar sayısı n_sim = 10.000 (Morris ve ark. 2019 §5.3, Denklem 1: oran 0,5 iken MCSE ≤ 0,005).
  2. Simülasyonda dengeli tasarım için vektörleştirilmiş hızlı PBE tahmin edicisi kullanılır; sonuçları validasyonlu `calc_pbe` ile birebir aynı olmalıdır. EMA yolu (c) dengeli tasarımda kapalı biçimle hesaplanır; sayısal REML ile doğrulanır.
  3. Ortak seed: bir senaryoda FDA PBE ve EMA yolları (a), (b), (c) aynı veri setlerine uygulanır (Morris ve ark. 2019 §4.3); senaryolar aynı seed ile koşar (§4.1.1, §5.4).
  4. EMA tarafında başlangıçta tek büyüklük (tek uç nokta) incelenir; çoklu uç nokta sonraki aşama.
- **Teknik not v0.4:** `belgeler/teknik_notlar/FSR-TN-PBE-01_v0.4.docx` (11 sayfa). Değişiklikler: Bölüm 10.2 iki aşamalı senaryo tablosu (KK-34); 10.4, 10.5 ve 5.3 KK-35 olarak işaretlendi; Bölüm 13'te açık kalanlar yalnız Ting 1990 ve İngilizce sürüm.

## G-32 · Simülasyon motoru: hızlı PBE ve EMA %90 GA (invitro_fast.R v0.1.0) — 15.10.2026

- **Dosyalar:** `CNKfarmastatr/R/invitro_fast.R` (yeni; yalnız temel R), `tests/testthat/test-invitro-fast.R` (TC-F1 … TC-F6), `DESCRIPTION` (Collate'e eklendi). Validasyonlu çekirdek dosyalara dokunulmadı (SHA-256: 8/8 AYNI).
- **İçerik:**
  - `invitro_gen()`: veri üretim modeli X = μ + b + c + τ_s + e (teknik not Bölüm 6); `invitro_components()` paylardan bileşenlere (KK-29); `invitro_drift()` doğrusal kayma (KK-31).
  - `pbe_fast()`: PSG 020929 Ek Adım 1–5, tekrarlar üzerinde vektörleştirilmiş.
  - `ema_ci_fast()`: EMA OIP Rev. 2 §5.1 ölçüt 8 kuralı (GMR %90 GA, 85–118) üç yolla: (a) havuzlanmış birimler, (b) seri ortalamaları, (c) REML. Test ve referans varyansları Welch–Satterthwaite serbestlik derecesiyle birleştirilir (FarmaStatR türetimi; EMA yöntem belirtmiyor).
  - `invitro_array()`: `calc_pbe` biçimindeki uzun veriyi diziye çevirir.
- **(c) kapalı biçimi (FarmaStatR türetimi):** Dengeli tasarımda üç tabaka (seri, seri içi birim, artık) ortogonaldir. REML tahminleri, beklenen kareler ortalamalarının sırası (seri ≥ birim ≥ artık) altında, gözlenen kareler ortalamalarının serbestlik derecesi ağırlıklı izotonik regresyonudur. Var(X̄) = θ̂_seri/(ℓnm). Birleştirme yoksa (b) ile aynıdır (G-29 bulgusu); seri ile birim birleşirse (a) ile aynıdır. Serbestlik derecesi, birleştirilen tabakaların sd toplamıdır (FarmaStatR türetimi).
- **Doğrulama:**
  - `pbe_fast` ile `calc_pbe` arasındaki en büyük göreli fark 2,6 × 10⁻¹⁵. Sınanan durumlar: PSG örnek verisi; m = 1, 2, 3; 3 × 10 / 3 × 10 ve 4 × 7 / 2 × 5 tasarımları. PASS/FAIL kararı ve ölçüt seçimi her durumda aynı.
  - (c), temel R ile yazılan sayısal REML (L-BFGS-B) ile karşılaştırıldı. 40 veri setinde en büyük göreli fark 2 × 10⁻⁷, yani optimizasyon duyarlılığı düzeyinde. Bu 40 setin içinde iç çözüm ve sınır durumları birlikte var.
  - Ayrıca (a), (b) ve (c) için elle hesaplanmış küçük bir örnek kullanıldı (TC-F3).
- **Testler:** Yeni 621 kontrolün tamamı GEÇTİ. Mevcut testler değişmedi.
- **Hız:** 3 × 10 × 3 tasarımı ve 10.000 tekrarla `pbe_fast` 0,04 sn sürdü. `calc_pbe` ile aynı iş yaklaşık 56 sn sürüyor (5,6 ms/veri seti), yani yaklaşık 1.400 kat hızlı. `ema_ci_fast` aynı iş için 0,5 sn. KK-34 kapsamındaki yaklaşık 620 senaryo × 10.000 tekrar birkaç dakikada koşulabilir.
- **Sonraki:** Aşama 1 senaryolarının koşulması ve sonuç ızgarası. Ardından FSR-VAL-SIM-1 ve `invitro_fast.R` SHA-256 sabitlemesi.

## G-33 · Aşama 1 koşuldu (360 senaryo × 10.000 tekrar) — 15.10.2026

- **Ön düzeltme (G-32'ye ek):** R'de `rnorm(sd = 0)` rastgele sayı çekmiyor. Bu yüzden bir bileşeni 0 olan senaryo (ör. p_B = 0), sayı dizisinde diğerlerinden kayıyordu ve ortak seed (KK-35) bozuluyordu. `invitro_gen` artık her bileşen için standart normal çekip ölçekliyor (`invitro_fast.R` v0.1.1). G-32'deki doğrulama sonuçları bu değişiklikten etkilenmez: karşılaştırmalar aynı veri üzerinde yapılmıştı. Yeni test TC-F5'e eklendi.
- **Yeni dosyalar:**
  - `CNKfarmastatr/R/invitro_grid.R` v0.1.0: `invitro_scenario()` tek senaryo ve performans ölçütleri + MCSE (Morris Tablo 6); `invitro_delta0()` FDA tip I sınırı; `invitro_run_record()` koşu kaydı.
  - TC-F7 eklendi; yeni dosyada toplam 628 kontrol GEÇTİ.
  - `simulasyon/FSR-TN-PBE-01/asama1.R` (betik), `asama1_sonuc.csv` (360 satır), `asama1_kayit.csv` (seed 20261015, Mersenne-Twister/Inversion, R 4.3.3, paket 1.0.0.9000; 3,15 dk).
- **Tasarım (KK-34 Aşama 1):** σ_R = σ_T = 0,12; p_L 0,15; m 3; q 0. p_B {0; 0,10; 0,30} × ℓ {2–6} × n {5, 8, 10, 15, 20, 30} × δ {FDA δ₀ = 0,1734 (GMR 1,189); GMR 1,18; 1,00; 1,05}. Güç oranlarında en büyük MCSE 0,005.
- **Bulgular (simülasyon sonucu; yalnız bu temel senaryo için):**
  - *FDA PBE tip I hata (δ₀):* p_B = 0 iken %3–5 (koruyucu). Seri varyansı varken şişiyor ve n ile artıyor, ℓ'ye pek bağlı değil: p_B 0,10 → 3 × 10'da %7,5, n = 30'da %13–14; p_B 0,30 → 3 × 10'da %13,2, n = 30'da %22. Bu, PSG tahmin edicisinin seri varyansını eksik sayması bulgusunun (teknik not 8.1) sayısal karşılığıdır.
  - *EMA tip I hata (GMR 1,18):* (a) havuzlanmış birimler aynı örüntüyü daha güçlü gösteriyor (p_B 0,30, 3 × 10: %20,8). (b) ve (c) tüm tasarımlarda ≤ %5; ℓ = 2'de koruyucu (%2–4).
  - *Güç (GMR 1,05), 3 × 10:* FDA %85 / %80 / %72; EMA (c) %92 / %68 / %36 (p_B 0 / 0,10 / 0,30). Seri varyansı varken EMA (b)/(c) gücünü n değil ℓ belirliyor: p_B 0,30'da n 5'ten 30'a çıkınca güç %31'den %41'e çıkıyor, ℓ 3'ten 6'ya çıkınca %36'dan %82'ye.
  - *Proje sahibinin 4 × 7 / 3 × 10 sorusu (G-23) için ilk ipucu:* p_B 0,10'da 4 × 8 (32 birim) ile 3 × 10 (30 birim) karşılaştırması: FDA %84 / %80, EMA (c) %83 / %68. 4 × 7 Aşama 1 ızgarasında yok; platformda koşulabilir.
- **Açık:**
  - Sonuçların teknik nota ve şekillere işlenmesi.
  - Aşama 2.
  - SQLite'a aktarım. Bu ortamda RSQLite kurulamadı; şimdilik CSV.
  - İş akışı etiketi "491 checks".

## G-34 · Teknik not v0.5: Aşama 1 sonuçları şekillerle işlendi — 15.10.2026

- **İş (K: "Aşama 1 sonuçlarını şekillerle teknik nota (v0.5) işle").**
- **Dosyalar:**
  - `belgeler/teknik_notlar/FSR-TN-PBE-01_v0.5.docx` (15 sayfa).
  - `simulasyon/FSR-TN-PBE-01/asama1_sekil.R` (temel R): `sekil/sekil1_tip1.png` ve `sekil/sekil2_guc.png` (300 dpi). Yöntemler için renkler ve ayrıca farklı nokta simgeleri kullanıldı; ℓ tek renk tonunun koyulaşmasıyla gösterildi.
- **Teknik notta değişenler:**
  - Yeni Bölüm 11 "Aşama 1 sonuçları": koşu ve yeniden üretim (11.1); Denk. 14'ün simülasyonla kontrolü (11.2); tip I hata, Şekil 1 ve Tablo 11.1 (11.3); güç, Şekil 2 ve Tablo 11.2 (11.4); %80 güce ulaşan en küçük tasarım, Tablo 11.3 (11.5); kapsama ve kriter seçimi (11.6); Hp1–Hp7'nin durumu (11.7); yorumun sınırları (11.8).
  - Bölüm 5.3: EMA (c) kapalı biçimi (izotonik regresyon) ve serbestlik derecesi seçimi, FarmaStatR türetimi olarak eklendi; tablodaki (c) satırı güncellendi.
  - 10.4 ve doğrulama planı güncellendi. Eski 11–13. bölümler 12–14 oldu.
- **Yeni sayılar (G-33'e ek):**
  - Denk. 14'teki σ̂²_R yanlılığı simülasyonla uyumlu. En büyük |z| = 3,21; ortak seed nedeniyle yaklaşık 90 karşılaştırma bağımsız değil.
  - EMA (a) kapsaması p_B > 0 iken %36–83; (b) ve (c) %90–96.
  - Kriter seçim hatası p_B = 0 ve 2 × 5'te %24,9; tip I hata yine ≤ %5.
- **Hp7 düzeltmesi:** v0.3'teki "(b) aşırı iyimser olabilir" beklentisi Aşama 1'de desteklenmedi. (b)'de tip I hata ≤ %5, kapsama ≥ %90.
- **Onay bekleyen:** Bölüm 11'in sonuç ve yorumları.

## G-35 · Ek B: SAS bağımsız kontrol paketi hazırlandı — 15.10.2026

- **Gerekçe (K: proje sahibi Ek B'yi SAS OnDemand'da koşacak):** SAS kontrolü isteğe bağlıdır (KK-11). Bu kontrolün asıl hedefi EMA (c): notta FarmaStatR türetimi olarak işaretli tek hesap.
- **Dosyalar** (`belgeler/teknik_notlar/FSR-TN-PBE-01_ek/sas/`):
  - `r_beklenen.R`: veriyi ve R'nin beklenen sonuçlarını üretir.
  - `sas_veri.csv`: 11 veri seti, 1.770 satır, log ölçeği.
  - `r_beklenen.csv`: her veri seti için ortalamalar; PSG MSB ve MSW; Searle Tablo 4.10'daki kareler ortalamaları; REML varyans bileşenleri ve hangi tabakaların birleştirildiği; (a), (b), (c) için SE, serbestlik derecesi ve %90 GA.
  - `sas_kontrol.sas`: PROC GLM ile tip I kareler toplamları; PROC MIXED REML, `ddfm=satterthwaite` ve `kenwardroger` ile. Sonuçlar 4 CSV dosyası olarak dışa aktarılıyor.
- **Veri setleri:**
  - K01–K06: Chow ham verisi.
  - K07: PSG 020929 örneği.
  - K08–K11: `invitro_gen` ile simüle edildi.
  - REML'in dört durumunun hepsi kapsanıyor: birleştirme yok; seri+birim birleşik; birim+artık birleşik; hepsi birleşik.
- **Ek B kodunda düzeltme (v0.5'teki hali):** `model y = product stage` yerine `product stage(product)` olmalı; teknik nottaki model evre etkisini ürün başına ayrı alıyor. Ayrıca iç içe evre etkisi varken `estimate 'T - R' product 1 -1` tahmin edilebilir olmayabilir; `lsmeans product / diff cl alpha=0.10` kullanıldı. Teknik not SAS sonuçlarıyla birlikte düzeltilecek.
- **Beklenen:**
  - Kareler ortalamaları, REML varyans bileşenleri, fark ve SE birebir aynı çıkmalı (deterministik).
  - Serbestlik derecesi ve GA sınırları farklı çıkabilir: FarmaStatR türetimi ile Satterthwaite / Kenward-Roger farkı. Bu fark Bölüm 5.3 ve 11.8'deki sınırlılığın sayısal ölçüsü olacak.

## G-36 · SAS bağımsız kontrolü tamamlandı; teknik not v0.6 — 15.10.2026

- **Koşu (proje sahibi; SAS masaüstü, 15.10.2026):**
  - `sas_kontrol.sas` iki kez koşuldu; ikisinde de hata yok.
  - İlk koşuda çıktılar 4 anlamlı basamakla yazıldı. Program tam hassasiyetle (best32.) ve yakınsama durumunu da dışa aktaracak şekilde düzeltildi, sonra yeniden koşuldu.
  - Çıktılar: `sas_glm_ss.csv`, `sas_covparms.csv`, `sas_diffs_sat.csv`, `sas_diffs_kr.csv`, `sas_conv_sat.csv`, `sas_conv_kr.csv`.
- **Karşılaştırma:** `sas_karsilastir.R` → `sas_karsilastir.csv`. Sonuçlar:
  - PSG MSB ve MSW; Searle Tablo 4.10 kareler ortalamaları: en çok 7,7 × 10⁻¹¹ göreli fark. Birebir aynı.
  - T − R farkı: en çok 9,3 × 10⁻¹³. Aynı.
  - Varyans bileşenlerinin sıfırda kesilmediği (iç çözüm) veri setleri (K04, K07, K08, K09):
    - REML varyans bileşenleri en çok 4,3 × 10⁻¹².
    - SE en çok 3,6 × 10⁻¹³ göreli.
    - Serbestlik derecesi: SAS Satterthwaite ve Kenward-Roger ile 10⁻¹² düzeyinde aynı.
  - Bir bileşenin sıfırda kesildiği (sınır) veri setleri (K01–K03, K05, K06, K10, K11):
    - Varyans bileşenleri en çok 2,2 × 10⁻⁴, SE en çok 9,8 × 10⁻⁵ göreli; serbestlik derecesi en çok 0,0067 (K10); %90 GA sınırı en çok 5 × 10⁻⁶.
    - Bu farkların nedeni SAS'ın yakınsama toleransı. REML ölçütü SAS tahminlerinde ve R kapalı biçiminde ayrı ayrı hesaplandı; R kapalı biçimi her durumda daha yüksek olabilirlik verdi (fark 2 × 10⁻¹¹ – 3 × 10⁻⁷).
  - K07 (PSG örneği): SAS "WARNING: Stopped because of infinite likelihood" ile durdu ve fark/GA üretmedi. Varyans bileşenleri R ile 6 × 10⁻¹⁴ düzeyinde aynı. Nedeni incelenmedi.
- **Sonuç:** EMA (c)'nin kapalı biçimi ve serbestlik derecesi seçimi SAS ile bağımsız olarak doğrulandı. Teknik notta (Bölüm 5.3, 11.8) "SAS farklı sd verebilir" uyarısı kaldırıldı; bulgu Ek B.1'e yazıldı.
- **Teknik not v0.6** (`FSR-TN-PBE-01_v0.6.docx`, 15 sayfa): Ek B kodu düzeltildi (G-35); yeni Ek B.1 sonuç tablosu; Bölüm 5.3, 11.8 ve 12 güncellendi.

# 3. Açık işler

| No | İş | Durum |
|---|---|---|
| A-1 | Eksik malzemenin (test betikleri, SAS programları, validasyon belgeleri, Excel test paketleri) bulunup `devralinan/v0.5.1/` altına alınması | PBE tamam; Excel paketleri tamam (G-02); dissolüsyon R testleri yeniden kuruldu, 278/278 (G-03). SAS programları ertelendi |
| A-3 | `Calistir.R`'nin proje sahibinin bilgisayarında çalıştırılması (beklenen 278/278) | Tamam: 278/278 (G-04) |
| A-4 | Paket testlerinin proje sahibinin bilgisayarında çalıştırılması (`testthat::test_local()`) | Tamam: 12/12, R 4.6.1 (G-06) |
| A-5 | GitHub deposu (CNK-FarmaStatR) ve bağlantı | Tamam: dosyalar GitHub'da, commit `80556e5` (G-10, G-11) |
| A-8 | Otomatik doğrulama (GitHub Actions): her push'ta SHA-256 + 491 kontrol | Tamam: ilk koşu Linux + Windows GEÇTİ (G-12) |
| A-6 | Lisans kararı (MIT / GPL-3 / diğer) | Üniversite görüşü bekleniyor (G-15); platform makalesinden önce |
| A-7 | Fonksiyon belgeleri (İngilizce) ve PBE köprüsünün pakete alınması | Tamam: PBE köprüsü (G-13), belgeler (G-14) |
| A-10 | Simülasyon altyapısı: validasyon belgesi FSR-VAL-SIM-1 ve SHA-256 sabitleme; ilk yayın senaryosu | Altyapı v0.1.0 tamam (G-15); ilk senaryo PBE güç / seri başına kap sayısı; teknik not v0.4 (G-31); hızlı motor `invitro_fast.R` (G-32); Aşama 1 koşuldu (G-33) ve nota işlendi (G-34); sırada Aşama 2 |
| A-9 | Dışa açılan fonksiyonların gözden geçirilmesi (şu an tümü açık; `exportPattern`) ve dissolüsyon köprüsü | Arayüz tasarımıyla birlikte |
| A-11 | Birincil kaynakların temini ve incelenmesi (KK-25; liste G-20) | Büyük ölçüde tamam (G-21); eksik: Ting ve ark. 1990, Langenbucher 1972 |
| A-2 | Proje dosyalarının temizlenmesi: eski günlük, yol haritası, app.R, PBE_webr HTML'leri, GMP kılavuzları kaldırılır | Proje sahibi |

# 4. Belge ve sürüm dizini

| Belge / yazılım | Sürüm | Durum |
|---|---|---|
| FSR-LOG-01 · Proje günlüğü | 1.27 | Bu belge |
| FSR-TN-PBE-01 · In vitro eşdeğerlik (FDA PBE, EMA OIP) simülasyon modeli ve tasarımı | 0.6 | Taslak; Bölüm 11 onay bekliyor; SAS kontrolü tamam (G-36) |
| CNK-FarmaStatR | 1.0.0.9000 | Geliştirme başladı (G-01) |
| CNKfarmastatr (R paketi) | 1.0.0.9000 | 8 validasyonlu dosya; 516 kontrol GEÇTİ (G-13); yardım sayfaları (G-14) |

# 5. Kullanıcı kararları dizini

| No | Karar | Girdi |
|---|---|---|
| KK-1 | v0.5.1 tarihçe değil, yalnızca malzeme | G-01 |
| KK-2 | Akademik eğitim/araştırma; GxP kapsam dışı; kalıcı beyan | G-01 |
| KK-3 | Validasyon model bazında, bir kez | G-01 |
| KK-4 | Tamamen web, sunucusuz, hibrit hesaplama | G-01 |
| KK-5 | SQLite | G-01 |
| KK-6 | GitHub + Zenodo DOI | G-01 |
| KK-7 | Yayın modülleri | G-01 |
| KK-8 | Simülasyon odağı; parametreler kullanıcıda; ADEMP | G-01 |
| KK-9 | Hedef kitle: akademi ve endüstri | G-01 |
| KK-10 | TR/EN; kod yorumları İngilizce | G-01 |
| KK-11 | SAS isteğe bağlı | G-01 |
| KK-12 | Önce platform makalesi | G-01 |
| KK-13 | 1.0.0.9000 → v1.0.0 makaleyle | G-01 |
| KK-14 | Çalışma klasörü `C:\cloud\CNK-FarmaStatR-v1` | G-01 |
| KK-15 | R paketi adı `CNKfarmastatr`; platform adı CNK-FarmaStatR | G-05 |
| KK-16 | GitHub kullanılacak; hesap mevcut | G-05 |
| KK-17 | Depo özel; v1.0.0 ile açık + Zenodo DOI | G-07 |
| KK-18 | Çalışma klasörü `C:\cloud\CNK-FarmaStatR` (depo); v1 klasörü yedek | G-09 |
| KK-19 | Çalışma klasörü `C:\cloud\CNK-FarmaStatR\CNK-FarmaStatR` (GitHub klonu) | G-10 |
| KK-20 | Claude yazar ve doğrular; proje sahibi Commit + Push yapar | G-11 |
| KK-21 | Lisans kararından önce üniversiteye danışılacak | G-15 |
| KK-22 | PBE modelinde seri etkisi rastgele; toplam varyans seri varyansını içerir | G-16 |
| KK-23 | PBE araştırma sorusu: seri başına kap sayısı n (ℓ = 3, m = 3 sabit) | G-16 |
| KK-24 | Yaşam evresi değişkenliği toplam varyansa dahil (FDA 1999 IX.B.1); m = 1, 2 ya da 3 | G-18 |
| KK-25 | İkincil atıflar için birincil kaynak istenir ve ayrıntılı incelenir | G-20 |
| KK-26 | Çalışma EMA OIP in vitro yöntemini de kapsar; FDA PBE ile karşılaştırılır | G-22 |
| KK-27 | EMA %90 GA üç yöntemle: havuzlanmış, seri ortalamaları, karma model | G-22 |
| KK-28 | Seri sayısı ℓ ve seri başına birim n birlikte araştırma faktörü; temel 3 × 10 | G-23 |
| KK-29 | Izgara toplam σ_R + ρ + paylarla; platform paylar ya da bileşenlerle giriş | G-24 |
| KK-30 | Paylar T ve R için aynı; hedefli senaryolar: seri varyansı yalnız R / yalnız T | G-25 |
| KK-31 | Evre içi sistematik kayma q ana senaryolarda 0; yalnız duyarlılık analizinde | G-26 |
| KK-32 | Faktör düzeyleri Chow ham verisi ve PSG örneğine dayalı; veride olmayanlar "zorlama senaryosu" | G-27 |
| KK-33 | Chow Tablo 14.5.2–14.5.3 ham verisi kaynağıyla depoda | G-28 |
| KK-34 | Senaryo listesi iki aşamalı: temel senaryo + Aşama 1 (360) + Aşama 2 (yaklaşık 256) | G-30 |
| KK-35 | n_sim = 10.000; hızlı PBE + EMA (c) kapalı biçim; ortak seed; EMA tek büyüklükle başlar | G-31 |
