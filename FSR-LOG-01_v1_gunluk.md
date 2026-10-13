---
title: "CNK-FarmaStatR v1 · Proje Günlüğü"
subtitle: "FSR-LOG-01 · Sürüm 1.7 · Son güncelleme: 13.10.2026"
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

# 3. Açık işler

| No | İş | Durum |
|---|---|---|
| A-1 | Eksik malzemenin (test betikleri, SAS programları, validasyon belgeleri, Excel test paketleri) bulunup `devralinan/v0.5.1/` altına alınması | PBE tamam; Excel paketleri tamam (G-02); dissolüsyon R testleri yeniden kuruldu, 278/278 (G-03). SAS programları ertelendi |
| A-3 | `Calistir.R`'nin proje sahibinin bilgisayarında çalıştırılması (beklenen 278/278) | Tamam: 278/278 (G-04) |
| A-4 | Paket testlerinin proje sahibinin bilgisayarında çalıştırılması (`testthat::test_local()`) | Tamam: 12/12, R 4.6.1 (G-06) |
| A-5 | GitHub deposu (CNK-FarmaStatR) ve bağlantı | Tamam: özel depo yayında (G-08) |
| A-6 | Lisans kararı (MIT / GPL-3 / diğer) | Platform makalesinden önce |
| A-7 | Fonksiyon belgeleri (İngilizce) ve PBE köprüsünün pakete alınması | Planlandı |
| A-2 | Proje dosyalarının temizlenmesi: eski günlük, yol haritası, app.R, PBE_webr HTML'leri, GMP kılavuzları kaldırılır | Proje sahibi |

# 4. Belge ve sürüm dizini

| Belge / yazılım | Sürüm | Durum |
|---|---|---|
| FSR-LOG-01 · Proje günlüğü | 1.7 | Bu belge |
| CNK-FarmaStatR | 1.0.0.9000 | Geliştirme başladı (G-01) |
| CNKfarmastatr (R paketi) | 1.0.0.9000 | İskelet; 491 kontrol GEÇTİ (G-05) |

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