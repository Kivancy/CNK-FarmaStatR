---
title: "CNK-FarmaStatR v1 · Proje Günlüğü"
subtitle: "FSR-LOG-01 · Sürüm 1.85 · Son güncelleme: 20.10.2026"
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

## G-37 · Süreç gözden geçirmesi (oturum sonu) — 15.10.2026

- **İstek (K):** "Sen de yarına kadar kendi süreçlerini gözden geçir." Proje sahibi teknik not v0.6'yı 16.10.2026'da okuyacak.
- **Yapılan kontroller:**
  1. Depo ile proje sahibinin klasörü dosya dosya karşılaştırıldı: dosya listesi ve boyutlar aynı (.git hariç).
  2. Paket için `R CMD check` (testler hariç) koşuldu.
  3. Paket testleri yeniden koşuldu.
  4. Teknik not v0.6'da, sonradan gelen sonuçlarla çelişen ya da artık geçerli olmayan gelecek zamanlı ifadeler tarandı.
- **Bulgular ve düzeltmeler:**
  - **Bulgu 1 (düzeltildi):** Bu oturumda eklenen 9 fonksiyonun yardım sayfası yoktu (`R CMD check`: undocumented code objects). Fonksiyonlar: `invitro_gen`, `invitro_components`, `invitro_drift`, `invitro_array`, `pbe_fast`, `ema_ci_fast`, `invitro_scenario`, `invitro_delta0`, `invitro_run_record`. `man/invitro_fast.Rd` ve `man/invitro_scenario.Rd` eklendi (İngilizce, örnekli); örnekler hatasız çalıştı.
  - **Bulgu 2 (bilgi):** `R CMD check` ASCII dışı karakter uyarısı verdi. Uyarı devralınan validasyonlu dosyalardan geliyor (`f2_boot.R`, `msd_core.R`, `msd_weibull.R`, `pbe_kopru.R`). SHA-256 ile sabitli oldukları için değiştirilmedi; ilk revizyonlarında ele alınacak (proje kuralı: devralınan çekirdekler ilk revizyona kadar olduğu gibi kalır).
  - **Bulgu 3 (açık, düşük öncelik):** İş akışı etiketi yalnızca "491 checks" diyor, oysa iş akışı bütün paket testlerini koşuyor. Davranışta sorun yok; atlanan test olursa iş akışı duruyor. `.github/workflows/dogrulama.yml` uzak araçlarla yazılamayan korumalı bir dosya. Etiketi proje sahibi elle düzeltebilir ya da konu bir sonraki iş akışı değişikliğine bırakılır.
  - **Bulgu 4 (v0.6 için düzeltme listesi; v0.7'de uygulanacak):**
    - D1: Bölüm 5.3'teki "Bulgu" paragrafının sonu ("(b) … aşırı iyimser olabilir; (c) bunu düzeltir. Üç yolun tip I hata ve gücü simülasyonla karşılaştırılacaktır.") Aşama 1 sonucuyla güncellenmedi. Tek veri setinde (b)'nin SE'si (c)'den küçük olabilir, ancak Aşama 1'de (b)'nin tip I hatası ≤ %5 ve kapsaması ≥ %90 (Bölüm 11.7).
    - D2: Ek A.7 yalnız "seri varyansı sıfırda kesilir → birim düzeyine döner" durumunu anlatıyor; kapalı biçimin tamamı (izotonik regresyon, dört durum) Bölüm 5.3'te. A.7 oraya atıf yapmalı.
  - **Bulgu 5 (bilgi):** 3. ve 4. bölümdeki tablolar güncel değildi; bu sürümde güncellendi (paket satırı, A-10, yeni A-12).
- **Bu oturumdaki süreç hataları ve bundan sonraki kurallar (Claude):**
  1. *Atıf numarası sonradan düzeltildi* (Morris §5.2 → §5.3 Denk. 1; §5.4 → §4.3, G-31). Kural: bölüm/denklem numarası yazılmadan önce kaynakta aranıp doğrulanır.
  2. *Sınanmamış kod belgeye girdi* (Ek B SAS kodu v0.3–v0.5'te hatalıydı, G-35). Kural: koşulmamış kod belgede "sınanmadı" etiketi taşır.
  3. *Yeni fonksiyon yardım sayfasız eklendi* (Bulgu 1). Kural: her yeni dışa açık fonksiyon testi ve yardım sayfasıyla birlikte teslim edilir; teslimden önce `R CMD check` koşulur.
  4. *Ortak seed varsayımı başta sınanmadı* (`rnorm(sd = 0)`, G-33). Kural: simülasyon tasarımındaki her varsayım (ortak rastgele sayılar dahil) için bir test yazılır.
  5. *Spekülatif uyarılar yanlış çıktı:* "SAS farklı sd verebilir" (G-36) ve Hp7'deki "(b) aşırı iyimser" (G-34). Kural: beklenti ve hipotezler metinde öyle etiketlenir; sonuç gelince belgede ilgili bütün ifadeler taranır (D1 bu taramanın eksikliğiydi).
  6. *Dış araç çıktısının hassasiyeti baştan istenmedi* (SAS 4 basamak, ek koşu gerekti). Kural: dış araçtan tam hassasiyet ve yakınsama/durum bilgisi baştan istenir.
  7. *Proje sahibinin klasörüne yazma bu oturumda en az iki kez eski içerikle sonuçlandı* (G-35, G-36). Her seferinde `cmp` ile yakalandı ve yeniden yazıldı. Kural (sürüyor): her yazımdan sonra bayt karşılaştırması yapılır.
- **Sonraki oturum için:**
  - Proje sahibinin v0.6 değerlendirmesi.
  - Ardından v0.7 (D1, D2 ve proje sahibinin notları).
  - Aşama 2.
  - EMS testinin pakete eklenmesi.
  - 4 × 7 koşusu.

## G-38 · v0.6 incelemesi, metodolojik kontrol raporu, m kararı ve Aşama 2 listesi — 16.10.2026

- **Oturum başı:** Günlük okundu (v1.34). Bölüm 4'te günlüğün sürümü 1.27 yazılıydı; düzeltildi.
- **Konuşulanlar (proje sahibinin soruları):**
  - ADEMP = Aims, Data-generating mechanisms, Estimands, Methods, Performance measures (Morris ve ark. 2019, Bölüm 3, Tablo 1). Teknik notun 0. bölümünde açılmadan kullanılmış → düzeltme D3.
  - Proje dosyalarındaki PBE kaynaklarının listesi (kod, başlık, yıl) çıkarıldı.
  - Chow ve Liu 2008 §14.3: BE limiti = [(ln ortalama limiti)² + varyans payı] / ölçekleme varyansı. FDA 1999 değerleriyle (0,90; 0; 0,10) θ_BE = 1,11 (Denk. 14.3.1); güncel PSG ve FDA 2022/2026 değerleriyle (ln 1,11; 0,01; 0,10) θ_P = 2,0891. PDR karşılığı 1,25 ve yaklaşık 1,43 (FarmaStatR hesabı). Kitapta 1,125 de geçer (PDR 1,25'ten geri hesap; §14.7 simülasyonu bununla ve σ₀ = 0,2 ile yapılmış).
  - Ölçekleme varyansı log dönüşümünden kaynaklanmaz; kriterin referansa göre ölçeklenmesinden gelir (Chow ve Liu 2008 §14.3; FDA 2026 §III.A.1). Log dönüşümü sabit σ₀'ı birimsiz kılar (σ = 0,10 → CV ≈ %10; FarmaStatR yorumu).
  - İç içe yapı: veri üretme modeli tam iç içe (seri, seri içinde birim; evre birimle çaprazlı sabit etki). FDA PSG tahmin edicisi seri düzeyini bilinçli olarak havuzlar (FDA 1999, 18 Ağustos). EMA (a) yapıyı yok sayar, (b) dolaylı olarak hesaba katar, (c) iç içe karma modeldir.
- **Proje sahibinin metodolojik kontrol raporu:** `FSR-TN-PBE-01_v06_Metodolojik_Kontrol_ve_Dogrulama_Raporu01.docx` (16.10.2026; K01–K13; 5 karar kapısı). Claude değerlendirmesi:
  - Bölüm 4'teki sayısal örnek yeniden hesaplandı ve doğru bulundu (oran 4,46; teknik not Denk. 15 ve 18 ile uyumlu).
  - **K13 doğrudan hata (Claude):** 4 × 7 = 28, 30 değil (G-23'ten beri; v0.6 Bölüm 1). 30 birimde iki düzenleyici alt sınırı birlikte karşılayan tek tasarım 3 × 10'dur; eşit toplamlı karşılaştırma 60 birimde yapılır. Chow, Shao, Wang 2003 §4'te örneklem büyüklüğü yöntemi var; katkı iddiası daraltılacak.
  - **K05:** FDA PBE istatistiği Δ̂'yı yalnız Δ̂² ve |Δ̂| üzerinden kullanır; bu yüzden −δ₀ ve +δ₀'ın ret olasılıkları aynıdır (FarmaStatR türetimi; S2-725 ile sınanacak). EMA sınırları simetrik değildir (ln 0,85 = −0,1625; ln 1,18 = 0,1655); alt sınır sınanmamıştı. ρ > 1,758'de δ = 0 da H₀ içindedir.
  - **K02 (kodda kontrol edildi):** T ve R ayrı üretiliyor (`invitro_scenario`: önce XT, sonra XR); `pB_T` ve `pB_R` asimetriyi destekliyor.
  - **K10:** G-33 düzeltmesinden sonra aynı tasarım içinde (p_B, δ değişince) veriler eşleşik; ℓ ya da n değişince eşleşme yok. v0.6 §10.5'teki "senaryolar arası farkların MCSE'si küçülür" ifadesi bununla sınırlanacak.
  - **K11:** "SAS toleransı" açıklaması REML ölçütü karşılaştırmasına dayanır (G-36); metne yazılacak. SAS'ın K07 veri setindeki "infinite likelihood" uyarısı incelenmedi, açık.
  - Kalan maddeler (K03, K06, K07, K08, K12) v0.7 metnine işlenecek; K04 açık iş A-12'dir.
- **Karar (K): KK-36.** Model m = 1, 2 ve 3 için geneldir; Budesonid tek bir m değerine bağlanmaz. Dayanak: PSG 020929 ana metninde yaşam evresi tanımlı değildir ("The number of ampules per determination should be one"); B/M/E yalnız Ek'teki simüle örnekte geçer. Evreleri etiketli puf sayısına göre tanımlayan PSG'ler çok dozlu cihazlar içindir: 020121 (SAC, damlacık boyutu: B, E; m = 2), 021433 ve 205625 (SAC: B, M, E; m = 3; APSD: B, E; m = 2). G-22'deki "Budesonid'de m = 3" düzeltmesi bu kararla değişti. Aşama 1 sonuçları "m = 3, çok dozlu cihaz" senaryosu olarak etiketlenir.
- **Düzeltme (Claude):** m = 1'de evre payının birim düzeyine katılmasını "FarmaStatR türetimi" diye etiketleme önerisi yanlıştı (proje sahibi düzeltti). m = 1 kaynakta tanımlı: PSG 020929 Ek Adım 4 ve PSG 020121 Ek Adım 3D (E2, E4 ve karşılık gelen H, U terimleri hesaba katılmaz). Birim başına tek ölçümde evre ve birim bileşenleri ayırt edilemez; bu bir model seçimi değil, aynı modelin farklı yazılışıdır.
- **Bulgu:** v0.6'da Aşama 2 "temelden tek faktör değişir" diye tanımlı, ama temel senaryoda p_B değeri yazılı değildi (256 sayısı tek bir p_B'ye göre).
- **Karar (K, Claude önerisi): KK-37.** Aşama 2 senaryo listesi koşudan önce sabitlendi (Morris ve ark. 2019 §3.2, §8.1). Tek faktörlü değişimler p_B {0; 0,30} ile çaprazlanır (0 nominal karşılaştırma noktası; 0,30 veride karşılığı olan üst uç, KK-32). Raporun ekleri: EMA GMR 0,85 (Aşama 1 ızgarasının tamamı); σ_R eşik çevresi {0,099; 0,100; 0,101} × ρ {1; 1,15}; 2 × 2 T/R seri asimetrisi (KK-30'un yerine; 0/0 ve 0,30/0,30 Aşama 1'de); 60 birimlik tasarım 5 × 12 (3 × 20, 4 × 15, 6 × 10 Aşama 1'de); FDA −δ₀ simetri kontrolü (tek hücre). Ek tekrar kuralı: güç hücrelerinde |güç − 0,80| < 2 MCSE ise 40.000 tekrar ve yeni, kayıtlı seed. Toplam **725 senaryo** (A 416, B 16, C 32, D 160, E 90, F 10, G 1); 527'si düzenleyici alt sınırlar içinde.
- **Dosyalar:** `simulasyon/FSR-TN-PBE-01/asama2_liste.R` (liste betiği; simülasyon koşmaz) ve `asama2_senaryolar.csv` (725 satır). Claude ortamında (R 4.3.3) koşuldu; satır sayısı ve tekrarsızlık betikte denetleniyor. δ₀ elle kontrol edildi (σ_R 0,06: 0,14454; ρ 0,80: 0,18780).
- **v0.7 düzeltme listesi:** D1 (§5.3 "Bulgu" paragrafı), D2 (Ek A.7 → §5.3 atfı), D3 (ADEMP açılımı), D4 (K13: 4 × 7; katkı iddiası), D5 (K03: estimandın koşullu ve marjinal tanımı), D6 (K06/K07: Tablo 11.3 ikiye, MCSE ile), D7 (K08: "EMA ölçütü için aday uygulama"), D8 (K12: seri payının belirsizliği), D9 (K11: REML ölçütü kanıtı), D10 (KK-36: Bölüm 3, temel senaryo gerekçesi, ürün–ölçüm–m tablosu), D11 (m = 1 için PSG atfı), D12 (K10: §10.5 ortak seed ifadesi), D13 (KK-37: §10.2 Aşama 2 tablosu).
- **Sıradaki:** teknik not v0.7; ardından Aşama 2 koşu betiği ve koşu.

## G-39 · Teknik not FSR-TN-PBE-01 v0.7 — 16.10.2026

- **Depo:** G-38 dosyaları proje sahibince commit + push edildi; GitHub Actions GEÇTİ (proje sahibi: "action ok").
- **İş (K: "başla"):** `belgeler/teknik_notlar/FSR-TN-PBE-01_v0.7.docx` (17 sayfa). v0.6 dosyası üzerinde düzenlendi (biçim ve şekiller korundu); v0.6 kayıt olarak kalır. Sürüm geçmişine 0.7 satırı eklendi.
- **İşlenen düzeltmeler (G-38'deki D1–D13):** §1 katkı iddiası daraltıldı (Chow ve ark. 2003 §4; Chow ve Liu 2008 §14.7) ve 4 × 7 örneği 60 birimlik tasarımlarla değiştirildi; §3 ürün–ölçüm–evre tablosu (KK-36); §5.3 "Statü" paragrafı (aday uygulama), (b) beklentisi Aşama 1 sonucuyla güncellendi, REML sınır durumunun kanıtı yazıldı; §6 m = 1 için PSG 020929 Ek Adım 4 ve PSG 020121 Ek Adım 3D atfı; §6.1 2 × 2 T/R asimetrisi; §7 koşullu ve marjinal estimand, bileşik H₀, ±δ₀ simetrisi ve EMA sınırlarının asimetrisi; §9 seri payının belirsizliği; §10 ADEMP açılımı, faktör tablosu ve Aşama 2 satırı (725; toplam 1.085 senaryo); §10.5 ortak seed tasarım içiyle sınırlandı, ek tekrar kuralı; §11.5 Tablo 11.3a (yalnız güç) ve yeni Tablo 11.3b (güç + tip I hata + düzenleyici alt sınırlar); §11.7 Hp5/Hp6 satırı; §11.8, §12, §13, §14; kaynakçaya PSG 205625; Ek A.7.
- **Ek düzeltme:** v0.6 §5.3'te dosya adı "`invitrofast.R`" olarak bozuk görünüyordu (alt çizgi alt simgeye dönüşmüştü); "invitro_fast.R" yapıldı.
- **Yeni sonuç (Aşama 1 verisinden; asama1_sonuc.csv):**
  - Tablo 11.3b: düzenleyici alt sınırlar içinde gücü ≥ %80 ve tip I hatası ≤ %5 + 2 MCSE olan en küçük tasarım. p_B = 0'da bütün yollarda 3 × 10. Seri varyansı varken FDA PBE ve EMA (a) için Aşama 1 ızgarasında (ℓ ≤ 6, n ≤ 30) böyle bir tasarım yok. EMA (b)/(c): p_B 0,10'da 4 × 10, p_B 0,30'da 6 × 10.
  - 60 birim (3 × 20, 4 × 15, 6 × 10), GMR 1,05, p_B 0,30: FDA güç %84,6 / 87,5 / 91,2, tip I hata %18,2 / 16,3 / 13,9; EMA (c) güç %40,2 / 61,4 / 82,2, tip I hata %3,9 / 4,3 / 4,0.
  - Tablo 11.3a'daki 80,0 ve 80,7 güç değerleri %80'e 2 MCSE'den yakın; ek tekrar kuralı kapsamında.
- **Doğrulama:** belge XSD doğrulamasından geçti; PDF'e çevrilip sayfalar görsel olarak kontrol edildi; 4 × 8 / 3 × 10 sayıları CSV'den yeniden hesaplandı.
- **Onay bekleyen:** v0.7'deki düzeltmelerin metne işlenişi ve Tablo 11.3b.

## G-40 · Kontrol raporu 02; motor 0.2.0; Aşama 1 ek tekrar; Aşama 2 koşuldu — 16.10.2026

- **Depo:** G-39 dosyaları commit + push edildi; GitHub Actions GEÇTİ (proje sahibi: "action ok").
- **Proje sahibinin kontrol raporu 02** (`FSR-TN-PBE-01_v06_Metodolojik_Kontrol_ve_Dogrulama_Raporu02.docx`, v0.7 üzerine; M-01–M-13, kapılar G1–G5). Proje sahibi ek tekrar kuralının Aşama 1'e uygulanmasını ve `invitro_fast.R` adının düzeltilmesini onayladı. Claude değerlendirmesi: M-01 (tip I uyum ölçütü), M-06 (GMR 1,10 listede yok), M-08 (MCSE ifadesi), M-07/M-09 (eşleşik MCSE, REML sınır payı), M-03 (m = 1 akış testi), M-11 (adlandırma) haklı; M-05 ve M-12 kısmen karşılanmıştı. İş sırası (K: "başla"): motor → G1 → G5 → G4 → Aşama 2 → yeniden üretim paketi.
- **Motor `invitro_grid.R` 0.2.0:** yöntem farklarının eşleşik MCSE'si (sd(D_i)/√n_sim; Morris ve ark. 2019 §5.2), EMA (c)'nin ürün başına sınır (birleştirme) payı, `keep_reps` ile tekrar düzeyinde kararlar; m = 1 ile q > 0 birlikte verilirse hata. Ek rastgele sayı çekilmez: Aşama 1'in üç senaryosu 4 × 10⁻¹⁵ içinde birebir yeniden üretildi. Bulunan nokta: m = 1 ve q > 0'da eski kod evre kayması varyansını sessizce düşürüyordu (Aşama 2 listesinde bu durum yoktu).
- **Yeni testler:** TC-F8 (eşleşik MCSE, sınır payı, keep_reps sonucu değiştirmez), TC-F9 (uçtan uca akış: veri üretimi → `calc_pbe` kararı; m = 1, m = 2 ve m = 3 ile q = 0,5; birebir aynı), TC-F10 (Denk. 12–15'in Monte Carlo kontrolü; q > 0 ve m = 1 dahil; p_B = 0'da PSG tahmin edicisi marjinal toplam varyans için yansız). Paket testleri: 25 test bloğu, 722 beklenti, başarısız 0, atlanan 0 (R 4.3.3, Linux). `R CMD check`: yalnız bilinen ASCII uyarısı. Not: bu ortamda UTF-8 yerel ayarı tanımlı değilken devralınan Türkçe test betikleri okunamıyor; `LANG=C.UTF-8` ile geçti.
- **G1, senaryo listesi:** `asama2_dogrula.R` → `asama2_dogrulama.csv`: 24 kontrol, hepsi geçti (satır ve blok sayıları, faktör düzeyleri, T ve R toplam varyansı, m = 1'de q = 0, δ değerleri, Aşama 1 ile çakışma yok, GMR 1,10 satırı yok).
- **G5, Aşama 1 ek tekrar (`asama1_ektekrar.R`; seed 20261016, 40.000 tekrar):** KK-37 kuralı yalnız Tablo 11.3a'daki iki hücreye değil, kuralı karşılayan bütün Aşama 1 güç hücrelerine uygulandı: 9 senaryo, 12 yöntem hücresi (Ö, Claude: nesnel kuralın seçici uygulanmaması için; proje sahibinin onayına sunuldu). FDA p_B 0,10, 3 × 10: %80,0 → %80,7; EMA (b)/(c) p_B 0,30, 6 × 8: %80,7 → %81,2. EMA (b) p_B 0,10, 3 × 30: %79,7 → %80,2. Hiçbir tablo hücresi değişmedi. Süre 0,8 dk.
- **G4, Tablo 11.3a/b (`asama1_tablo113.R`):** raporun M-01 önerisiyle (p̂ + 1,645·MCSE ≤ 0,05) yeniden kuruldu. Tablo 11.3b'de yalnız EMA (a), p_B = 0 değişti: 3 × 10 → 3 × 15 = 45.
- **Aşama 2 koşuldu (`asama2.R`):** 725 senaryo × 10.000 tekrar, seed 20261015, 10,2 dk; kurala giren 10 güç senaryosu 40.000 tekrarla yeniden koşuldu (`asama2_sonuc.csv`, `asama2_ektekrar.csv`, `asama2_kayit.csv`). İlk bulgular (3 × 10; değerlendirme ve teknik nota işleme sonraki iş):
  - FDA ±δ₀ simetrisi: 10.000 tekrarlık eşleşik karşılaştırmada %13,2 ve %14,1 (eşleşik z = −1,88); bağımsız 40.000'er tekrarda %13,5 ve %13,3 (z = 0,88). Simetri türetimiyle uyumlu.
  - EMA alt sınırı (GMR 0,85): (b) ve (c) en çok %5,2; (a) p_B 0,30'da %22,3.
  - σ_R eşik çevresi, p_B = 0: FDA tip I hata %5,2–5,5 (Hp4 lehine). p_B 0,30 ve σ_R ≤ 0,10'da FDA %19–20, σ_R ≥ 0,12'de %12,5.
  - T/R asimetrisi: seri varyansı yalnız testte FDA %11,8; yalnız referansta %7,2. Hp6'nın "yalnız R → tutucu" beklentisi desteklenmedi.
  - m = 1: FDA p_B 0,30'da %11,6. EMA (c) σ_R 0,40'ta %0,2–0,5 (çok tutucu).
  - EMA (c) sınır payı (birleştirme) senaryolara göre %0,3–67,6.
- **Bulunan sorun (Claude): M-01 ölçütü sınırda nominal bir yöntemi de "uyumsuz" sayıyor.** EMA (b)/(c) gibi tip I hatası sınırda tam %5 olan bir yöntemde p̂ + 1,645·MCSE ≤ 0,05 koşulu, gerçek oran 0,05 iken yalnız yaklaşık %5 olasılıkla sağlanır; Aşama 2'nin E bloğunda (b) 38/90, (c) 22/90 hücrede bu ölçüt sağlanmıyor. Ölçüt "kontrol kanıtı" sorusunu yanıtlıyor; "nominali aşma kanıtı" (p̂ − 1,645·MCSE > 0,05) ayrı bir sorudur. Karar proje sahibinde; teknik not v0.8 taslağı (KK-38'i tek ölçütle yazan) bu yüzden teslim edilmedi.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `CNKfarmastatr/R/invitro_grid.R`, `man/invitro_scenario.Rd`, `tests/testthat/test-invitro-fast.R`; `simulasyon/FSR-TN-PBE-01/` altında `asama1_ektekrar.R/.csv`, `asama1_ektekrar_kayit.csv`, `asama1_tablo113.R/.csv`, `asama2_dogrula.R`, `asama2_dogrulama.csv`, `asama2.R`, `asama2_sonuc.csv`, `asama2_ektekrar.csv`, `asama2_kayit.csv`.
- **Açık:** tip I uyum ölçütü kararı; teknik not v0.8 (ölçüt kararından sonra) ve Aşama 2 sonuçlarının nota işlenmesi; yeniden üretim paketi.

## G-41 · Üç sınıflı tip I hata etiketi; teknik not v0.8; yeniden üretim paketi — 16.10.2026

- **Karar (K, Claude önerisi üzerine): KK-38.** Tip I hata tahmini tek taraflı %95 Monte Carlo sınırlarıyla (z = 1,645) üç sınıfa ayrılır: p̂ − z·MCSE > 0,05 *nominali aşıyor*; p̂ + z·MCSE ≤ 0,05 *kontrol kanıtlı*; arası *ayırt edilemiyor*. Tasarım karşılaştırmasında ölçüt "nominali aşmıyor"dur. Gerekçe: raporun tek ölçütü (p̂ + z·MCSE ≤ 0,05), sınırda tam nominal düzeyde çalışan bir yöntemi gerçek oran 0,05 iken yalnız yaklaşık %5 olasılıkla kabul eder (G-40). Raporun ölçütü "kontrol kanıtlı" sınıfına karşılık gelir. v0.7'deki "%5 + 2 MCSE" kuralı geri çekildi.
- **Tablolar (`asama1_tablo113.R` güncellendi):** Tablo 11.3b'nin hücreleri v0.7 ile aynı; EMA (a), p_B = 0, 3 × 10 "ayırt edilemiyor" (%4,9; sınırlar %4,5–5,2). Tablo 11.3a'da FDA ve EMA (a)'nın seri varyanslı hücreleri "nominali aşıyor". Aşama 2 EMA alt sınırı bloğunda (90 hücre): EMA (b) 52 kontrol kanıtlı / 38 ayırt edilemiyor; EMA (c) 68 / 22; ikisinde de nominali aşan yok; EMA (a) 61 hücrede aşıyor.
- **Teknik not v0.8:** `belgeler/teknik_notlar/FSR-TN-PBE-01_v0.8.docx` (18 sayfa; v0.7 üzerinde düzenlendi). Kontrol raporu 02'nin işlenen maddeleri: M-01 (KK-38, Tablo 11.3a/b), M-06 (GMR 1,10 yalnız platformda), M-07/M-09 (eşleşik MCSE, sınır payı; örnek oran), M-08 (MCSE ifadesi; ek tekrar sonuçları), M-11 (işlem karakteristiği), M-03/M-05 (TC-F9, TC-F10), G1 (liste doğrulaması). Aşama 2 sonuçları henüz nota işlenmedi.
- **Bağımsız seed ile yeniden üretim (M-12; `bagimsiz_tekrar.R`):** Tablo 11.1–11.2'nin 48 yöntem hücresi seed 20261019 ve 40.000 tekrarla yeniden koşuldu: en büyük |z| = 2,65, |z| > 3 yok. Aşama 1'de ortak seed kullanıldığından karşılaştırmalar bağımsız değil. En büyük farklı hücre (EMA (a), p_B 0,30, δ₀) iki ek seed'le daha koşuldu: %17,5 ve %17,7 (Aşama 1: %17,1 ± 0,4); sistematik fark yok.
- **Yeniden üretim paketi:** `belgeler/teknik_notlar/FSR-TN-PBE-01_ek/yeniden_uretim/FSR-TN-PBE-01_yeniden_uretim_v0.8.zip` (1,1 MB). İçerik: paket kaynağı (tar.gz), simülasyon betikleri ve bütün CSV'ler, şekiller, teknik not v0.8, ek dosyaları (EMS, Chow, SAS), `sessionInfo.txt`, `test_sonuclari.csv` (25 blok, 722 beklenti, başarısız 0, atlanan 0), `SHA256SUMS.txt` (43 dosya), `OKUBENI.md` (raporun (a)–(g) maddeleriyle eşleştirme ve adımlar). Paketten bir betik çalıştırılarak yolların doğruluğu sınandı.
- **Sıradaki:** Aşama 2 sonuçlarının değerlendirilmesi ve teknik nota işlenmesi (v0.9); motor dosyaları için validasyon belgesi ve SHA-256 sabitleme (A-12).

## G-42 · Aşama 2 sonuçları değerlendirildi; teknik not v0.9 — 16.10.2026

- **Depo:** G-40 ve G-41 dosyaları (19 dosya; son commit'ten sonra değişen dosyalar klasörde mtime ile sayılarak doğrulandı) commit + push edildi; GitHub Actions GEÇTİ (proje sahibi: "actions ok"). Not: Claude önce dosya sayısını 21 diye yanlış toplamıştı; liste doğruydu, toplam 19.
- **İş (K: "başla"):** Aşama 2 sonuçlarının değerlendirilmesi ve teknik nota işlenmesi.
- **Özet betiği:** `simulasyon/FSR-TN-PBE-01/asama2_ozet.R` → `asama2_ozet_t121.csv` … `t126.csv`, `asama2_ozet_havuz.csv`, `sekil/sekil3_asama2.png`. Teknik nottaki tablolar bu CSV'lerden doğrudan üretildi (elle aktarım yok); etiketler KK-38'e göre.
- **Teknik not v0.9:** `belgeler/teknik_notlar/FSR-TN-PBE-01_v0.9.docx` (23 sayfa; v0.8 üzerinde). Yeni Bölüm 12 "Aşama 2 sonuçları" (12.1–12.10; Şekil 3; Tablo 12.1–12.7); eski 12–14. bölümler 13–15 oldu; çapraz atıflar güncellendi.
- **Bulgular (3 × 10; simülasyon sonucu):**
  - FDA ±δ₀ simetrisi ve ölçek değişmezliği (Bölüm 8.3) doğrulandı: σ_R 0,16 / 0,25 / 0,40'ta FDA tip I hatası ortak seed altında birebir aynı (p_B 0: %4,2; 0,30: %12,5). σ_R 0,12 hâlâ eşikten etkileniyor (%13,2).
  - Hp4 desteklendi: p_B 0'da eşik çevresinde (σ_R 0,099–0,101) FDA %5,2–5,9 (çoğu "nominali aşıyor"), kriter seçim hatası %42–51; uzakta %4,2–4,9. Seri varyansıyla (p_B 0,30) gerçek σ_R 0,101'de tekrarların %68'inde sabit ölçekli kriter seçiliyor.
  - Sabit ölçekli bölgede seri varyansıyla FDA daha liberal: p_B 0,30'da σ_R ≤ 0,101'de %19,1–20,0, σ_R ≥ 0,16'da %12,5. Mekanizma hipotezi (FarmaStatR türetimi, sınanmadı): referans ölçekli kriterde σ̂²_R eksikliği (1 + θ_p) katsayısıyla tutucu pay bırakır, sabit ölçekli kriterde σ̂²_T ve σ̂²_R eksiklikleri birbirini götürür.
  - Hp6 kısmen: seri varyansı yalnız testte FDA %11,8; yalnız referansta %7,2 (liberal; "tutucu" beklentisi desteklenmedi). Açıklama Denk. 15'ten (H_D'de σ²_B/ℓ eksik temsili).
  - Hp5 bu parametrelendirmede desteklenmedi (q 0,5'in etkisi MC belirsizliği düzeyinde). ρ 1,15 FDA gücünü düşürür (%85,2 → %61,8); m azaldıkça FDA tip I hata ve gücü biraz düşer.
  - EMA (b)/(c) Aşama 2'nin hiçbir koşulunda "nominali aşıyor" değil; σ_R büyüdükçe çok tutucu ve güçsüz (EMA (c), GMR 1,05, p_B 0: σ_R 0,25 %31,3; 0,40 %1,7). Alt sınırda (GMR 0,85) "kontrol kanıtlı" hücre sayısı daha az (fark ortalama 0,2 yüzde puanı); kuramsal olarak iki sınır eşit (FarmaStatR türetimi), fark tek akışın asimetrisi.
  - Eşit toplam 60 birim, p_B 0,30: EMA (c) gücü 3 × 20 → 6 × 10: %40,2 → %82,2; FDA tip I hata %18,2 → %13,9 (hep nominali aşıyor).
  - EMA (c) REML sınır payı: p_B 0'da %56–63, 0,30'da %5–16, 0,50'de %1–8.
  - Ek tekrar: 10 senaryo / 11 hücre; iki FDA hücresi %80'in altına geçti (%80,37 → %79,98; %80,26 → %79,66).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `asama2_ozet.R`, 7 özet CSV, `sekil/sekil3_asama2.png`, teknik not v0.9, bu günlük.
- **Onay bekleyen:** Bölüm 12'nin sonuç ve yorumları (özellikle Hp4, Hp6 ve Bölüm 12.2'deki mekanizma hipotezi); v0.8'den açık: KK-38 uygulaması, ek tekrar kapsamı, Tablo 11.3a/b.
- **Sıradaki öneri:** Bölüm 12.2 mekanizma hipotezinin hedefli bir simülasyonla sınanması (isteğe bağlı); motor için validasyon belgesi ve SHA-256 sabitleme (A-12); platform tarafına geçiş (G-37 / genel durum özeti).

## G-43 · v0.9 onayı; hedefli deney (kriter seçimi ve mekanizma); teknik not v0.10 — 16.10.2026

- **Onay (K):** Proje sahibi G-42'deki altı öneriyi üç metodolojik açıklamayla onayladı: "Altı öneriyi, yukarıdaki üç metodolojik açıklama ile birlikte onaylıyorum." Böylece v0.8'den açık kalan onaylar (KK-38 uygulaması, ek tekrar kapsamı, Tablo 11.3a/b) da kapandı. → **KK-39**.
  - **Hp4 ifadesi:** "≤ 1 yüzde puanı" yerine "yaklaşık 1 yüzde puanı düzeyinde, bazı karşılaştırmalarda biraz daha büyük" (ör. %5,5 ile %4,2: 1,3). Kriter seçim hatası tip I hata artışı demek değildir; gerçek σ_R = 0,10'da iki kriter eşittir. Sonuç cümlesi: "Hp4, incelenen sınır senaryolarında desteklenmiştir. FDA Tip I hata oranında küçük fakat tekrarlanan bir artış gözlenmiştir. Bu artışta veri temelli kriter seçiminin katkısı, ayrıca hedefli algoritmik karşılaştırmayla doğrulanmalıdır."
  - **Mekanizma testi:** E[η̂] ile kararı belirleyen üst sınırın örnekleme dağılımı farklıdır. Aynı veride referans ve sabit ölçekli üst sınırlar ayrı hesaplanır, FDA kararları tekrar düzeyinde eşleştirilir. Yeni bir faktöriyel değil, kısa bir hedefli deney.
  - **Tablo 11.3b:** 3 × 10 ve † korunur; başlık "Nominal Tip I hata aşımı saptanmayan ve en az %80 tahmini güce ulaşan keşifsel tasarımlar". 3 × 15'e geçmek kendiliğinden daha doğru değildir.
  - **Ek tekrar:** Kuralı karşılayan bütün Aşama 1 hücreleri için onaylandı. %80,2, %80 gücün kesin sağlandığı biçiminde okunmaz. 10.000 ve 40.000 tekrar ayrı raporlanır; 50.000 birleşik tahmin yalnız akışlar bağımsızsa.
- **Hedefli deney:** `simulasyon/FSR-TN-PBE-01/mekanizma.R` → `mekanizma.csv`, `mekanizma_kayit.csv`. 3 × 10, ρ 1, p_L 0,15, m 3, q 0; σ_R {0,08; 0,099; 0,10; 0,101; 0,12; 0,16} × p_B {0; 0,30}; δ = δ₀; n_sim 40.000; seed 20261020; 0,22 dk. Aynı veride dört FDA kararı: PSG (σ̂_R ile seçim), kâhin (gerçek σ_R ile seçim), yalnız referans ölçekli, yalnız sabit ölçekli; eşleşik MCSE.
- **Bulgular (simülasyon sonucu):**
  - Kriter seçiminin katkısı (PSG − kâhin), p_B 0: σ_R 0,10'da +1,34 puan (MCSE 0,07; PSG %5,7, iki kriter de %4,3, aralarındaki fark 0,09 ± 0,09); 0,099 ve 0,101'de +1,03 ve +1,15; eşikten uzakta 0. Hp4'ün artışının kaynağı veri temelli seçimdir. Neden (FarmaStatR türetimi): Eq_Ref − Eq_Const = −θ_p(σ̂²_R − σ²_T0); seçim kuralı nokta tahmininde her zaman küçük Eq'yu veren kriteri seçer.
  - Seri varyansı, p_B 0,30, σ_R 0,10: yalnız sabit %18,9, yalnız referans %12,6 (fark 6,33; MCSE 0,15). σ_R 0,101'deki %19,3'ün kâhine (%12,6) göre fazlası tümüyle seçimden (+6,76; σ̂_R eksik tahmini tekrarların %67,5'inde sabit kriteri seçtiriyor). σ_R 0,12'de seçimin katkısı 0,75.
  - Yanlılık ayrıştırması (Denk. 14–15): E[Eq_Ref] − η = Var(X̄_T − X̄_R) + θ_p·b, E[Eq_Const] − η = Var(X̄_T − X̄_R); 12 hücrede fark < 1 MCSE (aynı yönde, ortak seed). Üst sınırın kullandığı ortalama farkı varyansı 0,00054, gerçek 0,00240 (oran 4,5).
  - Sonuç: G-42'deki mekanizma hipotezi desteklendi. Liberalliğin ortak kaynağı üst sınırdaki varyansın seri varyansını eksik temsil etmesi; referans ölçekli kriterde θ_p·b kayması bunun bir kısmını telafi ediyor.
- **Teknik not v0.10:** `belgeler/teknik_notlar/FSR-TN-PBE-01_v0.10.docx` (24 sayfa; v0.9 üzerinde). Hp4 ifadesi (12.3, Tablo 12.7); 12.2 mekanizma "sınandı"; yeni Bölüm 12.10 "Hedefli deney" (Tablo 12.8); "Yorumun sınırları" 12.11; Tablo 11.3b başlığı ve † tanımı; Tablo 11.1'e KK-38 etiketleri (FDA p_B 0,10 ve 0,30, EMA (a) p_B 0,10 ve 0,30 nominali aşıyor; EMA (a) p_B 0 ayırt edilemiyor); 11.5'e %80,2 yorumu (MCSE 0,2; 50.000 birleşik %80,1).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `mekanizma.R`, `mekanizma.csv`, `mekanizma_kayit.csv`, teknik not v0.10, bu günlük.
- **Depo:** G-42 (v0.9) dosyaları henüz commit edilmedi; G-42 ve G-43 dosyaları birlikte commit + push edilebilir.
- **Onay bekleyen:** Bölüm 12.10'un sonuç ve yorumu.
- **Sıradaki öneri:** Motor için validasyon belgesi ve SHA-256 sabitleme (A-12); platform tarafı (SQLite, webR arayüzü).

## G-44 · Validasyon belgesi FSR-VAL-SIM-1 v0.1 (simülasyon çatısı ve in vitro motoru) — 16.10.2026

- **Depo:** G-42 ve G-43 dosyaları commit + push edildi; GitHub Actions GEÇTİ (proje sahibi: "actions ok").
- **Karar (K, Claude önerisi üzerine): KK-40.** Motorun (`invitro_fast.R`, `invitro_grid.R`) validasyonu A-12'deki plana göre FSR-VAL-SIM-1 içinde ayrı bir bölüm olarak yapılır; ayrı bir belge açılmaz (motor yeni bir PBE modeli değil, validasyonlu `calc_pbe` ile birebir aynı sonucu verdiği gösterilerek doğrulanır). EMA (c) yolu önceden valide edilmiş bir çekirdeğe dayanmadığı için belgede not düşülür; EMA yöntemi platformda bağımsız bir analiz olarak sunulursa kendi belgesi (ör. FSR-VAL-EMA-1) açılır. Not: Claude önce "FSR-VAL-PBE-SIM-1" adlı ayrı bir belge seçeneğini sordu; bu ad var olan bir belge değildi ve soru A-12'deki plan nedeniyle gereksizdi.
- **Kanıt betiği:** `belgeler/validasyon/FSR-VAL-SIM-1_ek/kanit.R` → `test_sonuclari.csv`, `sha256.csv`, `sayisal_ozet.csv`, `sessionInfo.txt` (R 4.3.3, Linux; yaklaşık 40 sn).
  - Paket testleri: 25 test bloğu, 722 beklenti, başarısız 0, atlanan 0 (çatı TC-S1–S10: 58; motor TC-F1–F10: 649; devralınan: 15 = 491 kontrol).
  - `pbe_fast` – `calc_pbe`: 49 veri seti, en büyük göreli fark 6,2 × 10⁻¹⁶; karar ve kriter seçimi her sette aynı.
  - EMA (c) – sayısal REML: 40 veri seti (17 birleştirmeli), en büyük göreli fark 4,4 × 10⁻⁷.
  - SHA-256 (temel R `araclar/sha256.R`; GNU sha256sum ile aynı; depo ve proje sahibinin klasörü aynı): `sim_performance.R` 9a0fd323…032f, `sim_run.R` e45b2d32…0cd2, `sim_scenario_demo.R` e32b2b6a…203c, `invitro_fast.R` 98350729…44b4, `invitro_grid.R` a10a0427…aba0 (tam değerler `sha256.csv` ve belgenin Tablo 3.1'inde).
- **Belge:** `belgeler/validasyon/FSR-VAL-SIM-1_v0.1.docx` (7 sayfa; teknik notun biçim şablonuyla). Bölümler: kapsam ve EMA (c) notu; dayanaklar (Morris 2019 Tablo 6, §4.1, §4.3, §5.3 Denk. 1; PSG 020929 Ek; EMA OIP §5.1 ölçüt 8; Searle 2006 §3.8 Denk. 145–146, §4.8; Satterthwaite 1946); yazılım tanımı ve SHA-256; hesabın tanımı; doğrulama yolları ve kabul ölçütleri (FarmaStatR seçimi); 20 test vakası; sonuçlar (paket testleri, sayısal uyum, SAS Ek B.1); geliştirmede bulunan üç hata (G-15, G-33, G-40); sınırlar; sabitleme önerisi.
- **Bulunan noktalar (belgeye yazıldı):** (i) `invitro_fast.R` ve `invitro_grid.R` başlıkları teknik not v0.4'e atıf yapıyor; düzeltmek SHA-256'yı değiştireceği için ilk kod revizyonunda. (ii) GitHub Actions iş akışının açıklama metni ("7 validated core files", "491 checks") güncel değil: listede 8 dosya var ve iş akışı bütün test klasörünü (722 beklenti) koşuyor; sabitlemeyle birlikte güncellenecek. (iii) webR'de koşu henüz yok (platform aşaması).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** FSR-VAL-SIM-1 v0.1, `FSR-VAL-SIM-1_ek/` (kanıt betiği ve dört çıktı), bu günlük.
- **Onay bekleyen:** FSR-VAL-SIM-1 v0.1 içeriği; onaydan sonra beş dosyanın `CEKIRDEK_SHA256.txt`'ye eklenmesi ve iş akışı açıklamasının güncellenmesi. Teknik not v0.10 Bölüm 12.10 onayı da açık (G-43).
- **Sıradaki öneri:** Onaydan sonra sabitleme (A-12 kapanır); ardından platform tarafı (SQLite, webR arayüzü).

## G-45 · FSR-VAL-SIM-1 değerlendirmesi; kabul ölçütleri yeniden yazıldı; v0.2 — 16.10.2026

- **Depo:** G-44 dosyaları commit + push edildi; GitHub Actions GEÇTİ (proje sahibi: "action ok").
- **Proje sahibinin değerlendirmesi (K):** Doğrulama yaklaşımı ve beş yol uygun; Tablo 5.1 koşulsuz onaylanmadı, sınırlı revizyon istendi. Eşiklerin Claude tarafından seçilmiş olması sorun değil; eşikler hesabın sayısal hassasiyetine uygun, yanlış algoritmayı kabul riskini düşük tutan, doğru algoritmayı gereksiz reddetmeyen ve önceden tanımlı olmalı. İstenenler (öncelik sırasıyla): (1) SAS kabul ölçütleri nicel (deterministik için öneri: göreli 10⁻⁹, mutlak 10⁻¹⁰; sınır çözümünde amaç fonksiyonu, varyans bileşenleri, SH ve GA farkları ayrı kaydedilsin; eşikler sonuca göre sonradan genişletilmesin); (2) analitik ve referans karşılaştırmalarında mutlak ve göreli tolerans birlikte, |x̂ − x| ≤ 10⁻¹² + 10⁻¹²·max(|x|, |x̂|); (3) Monte Carlo eşiği tutarlı: Seçenek B, TC-S5 ve TC-F10'da ortak 4 MCSE, 3–4 MCSE arası uyarı; (4) REML'de parametreye ek olarak amaç fonksiyonu, kısıtlar, %90 GA ve karar; sınırdaki karar farkları işaretlensin; (5) yeniden üretim koşulları (aynı kod, girdi, RNG, ortam). Ölçütler değişince testler yeniden koşulup kaydedilmeli; yeni kapsamlı simülasyon gerekmez. K07 açık kontrol maddesi olarak kalmalı. → **KK-41**.
- **Uygulama (Claude):**
  - `tests/testthat/helper-tolerance.R` (yeni): `expect_close()` her eleman için |x̂ − x| ≤ a + r·max(|x|, |x̂|). testthat'in `expect_equal(tolerance = )` ortalama farkı ortalama değere böldüğü için iki test dosyasındaki 60 sayısal karşılaştırma `expect_close()`'a çevrildi; tam sayı, sayım ve özdeşlik kontrolleri `tolerance = 0` ile birebir kaldı. TC-F4'te REML: mutlak 10⁻¹⁰, göreli 10⁻⁵.
  - TC-S5: 3 → 4 MCSE.
  - Yeni TC-F11 ve `tests/testthat/helper-reml.R` (motordan bağımsız PAVA, REML ölçütü, sayısal REML): 24 veri seti çifti (m = 1 ve 3), (i) motorun kapalı biçimi = bağımsız PAVA, (ii) bileşenler ≥ 0, (iii) kapalı biçimdeki REML ölçütü ≤ sayısal optimum + 10⁻⁸, (iv) %90 GA K(10⁻¹⁰, 10⁻⁵) ve karar birebir; sınıra göreli 10⁻⁵ yakın kararlar işaretlenir. 242 beklenti, yaklaşık 11 sn.
  - `kanit.R` v0.2: oranlar Tablo 5.1 kuralıyla; yeni `sas_kabul.csv` (SAS, set başına) ve `mc_z.csv` (z ve uyarı).
- **SAS eşiklerinin seçimi (Claude, belgeye yazıldı):** SAS sonuçları G-36'da görülmüştü. Sınır çözümü eşikleri bu yüzden gözlenen farklardan değil iki ilkeden seçildi: kapalı biçim kısıtlı REML optimumu olduğundan ölçütte SAS'tan kötü olamaz (10⁻⁸ yuvarlama payı); GA eşiği 10⁻⁴, EMA sınırlarının yazım çözünürlüğünün iki basamak altı. İç çözümlü setlere deterministik kural (10⁻¹⁰, 10⁻⁹) uygulandı.
- **Sonuçlar (R 4.3.3, Linux):** 26 test bloğu, 964 beklenti, başarısız 0, atlanan 0 (çatı 58, motor 891). `pbe_fast` – `calc_pbe` en büyük oran 3,4 × 10⁻⁶ (≤ 1). EMA (c) – sayısal REML: Var(X̄) oranı 0,032; REML ölçütünde kapalı biçim hiçbir sette kötü değil; GA oranı 8,1 × 10⁻⁴; karar 24/24 aynı (19 geçen), işaretlenen 0. SAS: 10 set GEÇTİ (iç çözüm K04, K08, K09; sınır K01–K03, K05, K06, K10, K11; GA farkı en çok 5,4 × 10⁻⁶), K07'de SAS sonuç üretmedi (açık madde). MC: TC-S5 en büyük |z| 1,25; TC-F10 1,90; uyarı 0.
- **Belge:** `belgeler/validasyon/FSR-VAL-SIM-1_v0.2.docx` (8 sayfa): Tablo 5.1 yeniden yazıldı; eşiklerin gerekçesi, SAS eşiklerinin seçimi, MC eşiği (Bonferroni: TC-S5 4 karşılaştırma 2,5 × 10⁻⁴; TC-F10 16 karşılaştırma 1,0 × 10⁻³); Tablo 6.1'e TC-F11; yeni Tablo 7.3 (SAS) ve Bölüm 7.4 (MC); sınırlara test kapsamı notu; K07 açık kontrol maddesi. Not: değerlendirmede TC-S5 için 5 MC karşılaştırması varsayılmıştı; 5 beklentinin 4'ü MC karşılaştırmasıdır (beşincisi t ve z yanlılığının özdeşliği).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `CNKfarmastatr/tests/testthat/test-simulation.R`, `test-invitro-fast.R`, `helper-tolerance.R`, `helper-reml.R`; `belgeler/validasyon/FSR-VAL-SIM-1_v0.2.docx`; `FSR-VAL-SIM-1_ek/` (`kanit.R` ve altı çıktı); bu günlük. Validasyonlu çekirdek ve motor dosyaları değişmedi (SHA-256 aynı).
- **Onay bekleyen:** FSR-VAL-SIM-1 v0.2 (Tablo 5.1, TC-F11, Bölüm 7). Onaydan sonra sabitleme (A-12). GitHub Actions'ta v0.2 testlerinin ilk koşusu bir sonraki push'ta.

## G-46 · Eşik onayı; TC-F11'e sınır çifti; FSR-VAL-SIM-1 v0.3 — 16.10.2026

- **Depo:** G-45 dosyaları commit + push edildi; GitHub Actions GEÇTİ (proje sahibi: "action ok"). v0.2 testleri (`expect_close`, TC-F11, TC-S5 |z| < 4) Linux ve Windows'ta ilk kez koştu ve geçti.
- **Onay (K):** Claude'un seçtiği iki eşik onaylandı (KK-41 kapsamında): SAS sınır çözümünde %90 GA sınırları farkı ≤ 10⁻⁴; REML ölçütü payı 10⁻⁸ ("ikisi de uygun").
- **TC-F11 eki (Ö, Claude; proje sahibi itiraz etmedi):** İşaretleme kuralı yazılıydı ama 24 rastgele çiftte hiç devreye girmemişti. Bir veri seti çifti, T verisine sabit eklenerek üst sınırı 1,18·(1 − 3 × 10⁻⁶) olacak biçimde kaydırıldı (sabit ekleme yalnız ortalama farkını değiştirir; varyanslar, sd ve GA genişliği aynı kalır). Sonuç: karar işaretlendi; motor üst sınırı 1,1799965, sayısal REML 1,1799965; iki yolda da geçer; GA oranı 3,7 × 10⁻⁴. TC-F11: 246 beklenti.
- **Sonuçlar:** 26 test bloğu, 968 beklenti, başarısız 0, atlanan 0 (çatı 58, motor 895). Diğer kanıtlar değişmedi.
- **Belge:** `belgeler/validasyon/FSR-VAL-SIM-1_v0.3.docx` (8 sayfa): sürüm geçmişi, Tablo 6.1 (TC-F11), Tablo 7.1 (Actions), Tablo 7.2'ye işaretleme satırı, onay bölümü.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `test-invitro-fast.R`, `kanit.R`, `sayisal_ozet.csv`, `test_sonuclari.csv`, FSR-VAL-SIM-1 v0.3, bu günlük.
- **Onay bekleyen:** FSR-VAL-SIM-1 v0.3 (onayla 1.0); ardından beş dosyanın SHA-256 sabitlemesi ve iş akışı açıklamasının güncellenmesi (A-12).

## G-47 · FSR-VAL-SIM-1 1.0 onaylandı; beş dosya SHA-256 ile sabitlendi — 16.10.2026

- **Depo:** G-46 dosyaları commit + push edildi; GitHub Actions GEÇTİ (proje sahibi: "actions ok"). TC-F11'in sınır çifti Linux ve Windows'ta koştu.
- **Onay (K):** "belgeyi onaylıyorum." FSR-VAL-SIM-1 v0.3 içeriğiyle sürüm 1.0 oldu. Claude, "actions ok"u belge onayı saymadı; sabitleme kalıcı olduğu için açık onay istendi.
- **Sabitleme (A-12):** `CNKfarmastatr/inst/validasyon/CEKIRDEK_SHA256.txt`'ye beş satır eklendi (alfabetik sıra; 13 dosya): `sim_performance.R` 9a0fd323…032f, `sim_run.R` e45b2d32…0cd2, `sim_scenario_demo.R` e32b2b6a…203c, `invitro_fast.R` 98350729…44b4, `invitro_grid.R` a10a0427…aba0. `araclar/cekirdek_kontrol.R`: 13/13 AYNI (R 4.3.3; UTF-8 yerel ayarıyla).
- **İş akışı:** `.github/workflows/dogrulama.yml` yalnız açıklama metni ve 2. adımın adı değişti ("7 validated core files", "491 checks" → 13 dosya; bütün test klasörü, 26 blok, 968 beklenti). Adımların komutları değişmedi; YAML sözdizimi denetlendi. Uzaktan yazma araçları `.github/workflows/` altını korumalı tuttuğu için Claude bu dosyayı klasöre yazamadı; güncellenmiş dosya proje sahibine verildi, proje sahibi klasörde değiştirip aynı commit'e ekler.
- **Belge:** `belgeler/validasyon/FSR-VAL-SIM-1_v1.0.docx` (8 sayfa): sürüm 1.0 (onaylandı); Bölüm 10 "Uygulama"; Bölüm 11 "Onay"; Tablo 7.1'de v0.3 Actions sonucu. Açık kalan maddeler: SAS K07 uyarısının nedeni, webR'de koşu, kod başlıklarındaki teknik not atfı (ilk kod revizyonunda; revizyon belgeye işlenir).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `CEKIRDEK_SHA256.txt`, FSR-VAL-SIM-1 1.0, bu günlük. `dogrulama.yml`: proje sahibi yerleştirir (yukarıda).
- **Kapanan:** A-12. A-10'un validasyon ve sabitleme kısmı tamam.
- **Sıradaki öneri:** Platform tarafı (SQLite sonuç ızgarası, webR arayüzü); teknik not v0.10 Bölüm 12.10 onayı açık (G-43).

## G-48 · Sabitleme Actions'ta geçti; teknik not v0.10 onayı; v0.11 — 16.10.2026

- **Depo:** G-47'nin dört dosyası (`CEKIRDEK_SHA256.txt`, `dogrulama.yml`, FSR-VAL-SIM-1 1.0, günlük) commit + push edildi; GitHub Actions GEÇTİ (proje sahibi: "4 dosya action oldu"). 1. adım 13 dosyayı Linux ve Windows'ta denetledi. Not: GitHub Desktop önce 3 dosya gösterdi; `dogrulama.yml`'yi korumalı klasör nedeniyle proje sahibi yerleştirdi.
- **Onay (K): KK-42.** Teknik not v0.10 Bölüm 12.10 kalır: "Evet, kalabilir. Ancak 'mekanizma tamamen kanıtlandı' anlamında kullanılmamalı." Hedefli deney mekanizmayı destekler ve sonuçlar onunla uyumludur; kesin kanıt değildir (tek tasarım; başka etkenler dışlanmış değil).
- **Teknik not v0.11:** `belgeler/teknik_notlar/FSR-TN-PBE-01_v0.11.docx` (24 sayfa). İfadeler düzeltildi: Bölüm 12.2 "sınandı" → "hedefli deneyin sonuçlarıyla uyumlu; tamamen kanıtlanmış değildir"; 12.3 "doğrulandı" → "incelendi" ve "incelenen tasarımla (3 × 10) sınırlıdır"; Tablo 12.7 Hp4 ve "Yeni" satırları; 12.10 Sonuç ("uyumludur ve onu destekler; tamamen kanıtlandığı anlamına gelmez"; başka etkenler dışlanmış değil); 12.11 sınırlar; onay bölümü; sürüm geçmişine 0.11.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** teknik not v0.11, bu günlük.
- **Açık:** teknik not v0.11'in proje sahibince okunması; İngilizce sürüm (içerik onayından sonra). Sıradaki öneri: platform tarafı (SQLite sonuç ızgarası, webR arayüzü).

## G-49 · Oturum sonu: eleştirel süreç değerlendirmesi — 16.10.2026

- **Depo:** G-48 dosyaları (teknik not v0.11, günlük) commit + push edildi; GitHub Actions GEÇTİ (proje sahibi: "action ok").
- **İstek (K):** "Buraya kadar olan süreci eleştirel bir açıdan değerlendir. Günlük çalışma notuna dönüştür ve projeye ekle. Yarın devam edelim."
- **Oturumun dökümü (16.10.2026, G-38 … G-48):**
  - Teknik not v0.7 → v0.11. Proje sahibinin iki kontrol raporu işlendi, Aşama 2 (725 senaryo) koşuldu ve nota işlendi, hedefli deney yapıldı.
  - Validasyon belgesi FSR-VAL-SIM-1 v0.1 → 1.0: kabul ölçütleri yeniden yazıldı, TC-F11 eklendi, beş dosya SHA-256 ile sabitlendi (13 dosya).
  - Yedi karar: KK-36 … KK-42.
  - Paket testleri 722 → 968 beklenti. Bütün commit'ler GitHub Actions'ta geçti.
- **İyi işleyenler:**
  1. Proje sahibinin incelemeleri sonucu gerçekten değiştirdi. Örnekler: m kararı (KK-36); üç sınıflı tip I etiketi (KK-38); kabul ölçütlerinin nicel hale gelmesi (KK-41); ifadelerin "destekler" düzeyine çekilmesi (KK-42). Rapor → değerlendirme → onay zinciri çalışıyor.
  2. Her yazımdan sonra bayt karşılaştırması bir kez daha işe yaradı. G-47'de günlüğün eski içeriği yazılmıştı; karşılaştırma bunu yakaladı ve dosya yeniden yazıldı (G-37 kural 7).
  3. Kanıt yeniden üretilebilir hale geldi. `kanit.R` belgedeki bütün sayıları üretiyor; `mekanizma.R`, `asama2_ozet.R` ve diğer betikler sonuçları CSV'den doğrudan tabloya taşıyor, elle aktarım yok.
  4. Sabitleme için açık onay istendi. "actions ok" belge onayı sayılmadı (G-47).
- **Claude'un hataları ve zayıf noktaları:**
  1. *Günlükte kararı verilmiş konular yeniden soruldu.* "FSR-VAL-PBE-SIM-1" diye var olmayan bir belge önerilip soruldu, oysa A-12'de karar yazılıydı (G-44). `dogrulama.yml`'nin korumalı olduğu G-37 Bulgu 3'te kayıtlıydı; buna rağmen G-47'de yazılmaya çalışıldı ve proje sahibine önce "4 dosya" denildi. Kök neden ikisinde de aynı: günlük, soru sormadan ya da plan bildirmeden önce taranmadı.
  2. *Kabul ölçütleri sonuçlardan sonra tanımlandı ve ilk hali zayıftı* (FSR-VAL-SIM-1 v0.1). Toleranslar yalnız göreliydi (gerçek değer 0'da tanımsız). SAS için "birebir" yazıldı, oysa aynı belge 7,7 × 10⁻¹¹ fark bildiriyordu. Sınır çözümü için ölçüt nicel değildi. Proje sahibi yakaladı (G-45). SAS sınır eşikleri sonuçlar görüldükten sonra seçildi. İlkeye dayandırıldı ve belgede açıkça yazıldı, ama sonradan seçilmiş olma zayıflığı ortadan kalkmıyor.
  3. *Sonuçlar olduğundan güçlü ifade edildi.* Örnekler: Hp4 için "≤ 1 yüzde puanı" (G-43), mekanizma için "sınandı / doğrulandı / desteklendi" (G-48). İkisini de proje sahibi düzeltti. G-37 kural 5 hipotezlerin etiketlenmesini istiyordu; yorumların gücü için bir kural yoktu.
  4. *Bilinen bir kusur sabitlemeden önce giderilmedi.* `invitro_fast.R` ve `invitro_grid.R` başlıkları teknik not v0.4'e atıf yapıyor; G-44'te fark edildi ama dosyalar bu haliyle sabitlendi. Düzeltmek artık bir revizyon gerektiriyor (SHA-256 değişir). Önce düzeltip sonra sabitlemek daha doğruydu.
  5. *Dosya sayısı yine yanlış bildirildi.* G-47'de "4 dosya" denildi, GitHub Desktop 3 gösterdi (bkz. hata 1). Önceki oturumdaki 21/19 hatasıyla aynı türden. Sayı, gerçekte yazılıp doğrulanan dosyalardan verilmeli.
  6. *Proje sahibine kısa sürede çok sayıda onay sunuldu.* Bir günde beş teknik not sürümü, dört validasyon belgesi sürümü ve yedi karar. Proje sahibi bir noktada "Tablo 5.1, TC-F11, Bölüm 7 benden ne istiyor" diye sordu; onay istekleri yeterince açık değildi. Hafıza yükü projenin bilinen kısıtı. Daha az sayıda, belge başına toplanmış ve "sizden istenen tek karar şu" biçiminde onay istekleri daha uygun.
  7. *Kod tekrarı.* `kanit.R`, TC-F2 ve TC-F4 testlerinin veri üretimini kopyalıyor. Testler değişirse kanıt betiği sessizce ayrışabilir. REML araçları `helper-reml.R`'de ortak; aynı yol veri üretimi için de izlenmeli.
- **Açık kalan teknik maddeler:**
  - SAS K07 uyarısının nedeni incelenmedi.
  - Testler webR'de koşulmadı.
  - Kod başlıklarındaki eski atıf (ilk revizyonda).
  - Teknik notun İngilizce sürümü.
  - Lisans kararı (A-6).
  - Paket testleri yaklaşık 45 sn sürüyor; TC-F11 tek başına 11 sn. Henüz sorun değil.
- **Bundan sonraki kurallar (Claude; G-37'deki kurallara ek):**
  8. Bir soru sormadan ya da bir dosya/yol hakkında plan bildirmeden önce günlükte ilgili karar ve bulgular taranır (KK dizini, açık işler, önceki bulgular).
  9. Kabul ölçütleri, karşılaştırma koşulmadan önce yazılır; sonuç görüldükten sonra belirlenen bir eşik belgede öyle etiketlenir.
  10. Yorumlarda varsayılan dil "uyumludur / destekler"dir. "Doğrulandı" yalnız deterministik eşitlikler ve önceden tanımlı kabul ölçütleri için, "kanıtlandı" yalnız matematiksel türetim için kullanılır.
  11. Sabitlemeden önce dosyalardaki bilinen kusurlar (yorum, atıf, ad) giderilir.
  12. Proje sahibine bildirilen dosya sayısı yalnız yazılıp bayt karşılaştırması yapılan dosyalardan verilir. Proje sahibinin elle yapacağı dosyalar ayrı listelenir.
  13. Onay istekleri belge başına toplanır ve "sizden istenen karar" tek cümleyle yazılır.
- **Sonraki oturum (17.10.2026):** Platform tasarım notu: SQLite tabloları (yayın veri setleri, test vakaları ve beklenen sonuçlar, simülasyon sonuç ızgarası, modül/sürüm kaydı) ve webR arayüzünün ilk ekranı. Kodlamadan önce proje sahibinin onayına sunulur.

## G-50 · Kod tekrarı giderildi; webR ve SQLite denemeleri; platform tasarım notu FSR-TN-PLT-01 v0.1 — 17.10.2026

- **Oturum başı:** Günlük okundu (v1.46); proje sahibinin klasöründeki ve proje dosyalarındaki günlük aynı. G-49 commit'inin durumu bu oturumda proje sahibince ayrıca bildirilmedi.
- **Kod tekrarı (G-49 hata 7):** Yeni `tests/testthat/helper-cases.R`: `to_long`, `pbe_cols`, `cases_tcf2()`, `cases_tcf11()` (24 çift + sınır çifti), `mc_tcs5()`, `mc_tcf10()`. TC-F2, TC-F10, TC-F11 ve TC-S5 bu yardımcıları kullanıyor; TC-F4'teki satır içi sayısal REML yerine `helper-reml.R`'deki `reml_numeric()`. `kanit.R` (v0.4) aynı yardımcıları `source` ediyor; kopyalanmış veri üretimi kalmadı. Kontrol: testler 26 blok, 968 beklenti, başarısız 0, atlanan 0 (blok başına sayılar aynı); kanıt betiğinin beş çıktısı (`sayisal_ozet.csv`, `sas_kabul.csv`, `mc_z.csv`, `test_sonuclari.csv`, `sha256.csv`) önceki hâliyle bayt bayt aynı. Sabitlenmiş dosyalara dokunulmadı.
- **webR denemesi (Ö):** webR 0.5.4 (R 4.5.1), Node 22 üzerinde; motorun iki dosyası paket kurulmadan `source` edildi. `invitro_scenario()` (p_B 0,10, δ₀, seed 20261015) yerel R 4.3.3 ile 17 anlamlı basamakta aynı sonucu verdi (FDA, EMA (c), EMA (b) geçme oranı, FDA σ̂²_R yanlılığı). Süre: 3 × 10, 10.000 tekrar 2,1 sn (yerel 0,5); 6 × 30, 10.000 tekrar 11,0 sn (yerel 3,9); açılış 1,5 sn. Tarayıcıda ölçülmedi. Dosyalar: `belgeler/teknik_notlar/FSR-TN-PLT-01_ek/webr_hiz.mjs`, `webr_hiz.csv`.
- **SQLite denemesi (Ö):** Aşama 1 (360 × 38) ve Aşama 2 (725 × 55) sonuçları denemelik SQLite dosyasında 0,66 MB; sql.js 1.12.0 ile Node'da okundu (0,03 sn). webR'de RSQLite sınanamadı (webR paket deposuna bu ortamdan erişim yok). Deneme veri tabanı depoya konmadı.
- **Bulunan eksik:** `sim_export_script()` yalnız `sim_run()` koşularını betiğe çeviriyor; `invitro_scenario()` için dışa aktarma yok (hesaplama katmanı 3). Yeni fonksiyon gerekir (FSR-VAL-SIM-1 revizyonu).
- **Teknik not FSR-TN-PLT-01 v0.1** (`belgeler/teknik_notlar/FSR-TN-PLT-01_v0.1.docx`, 4 sayfa): amaç ve değişmez ilkeler; denemeler (Tablo 2.1); üç hesaplama katmanı; SQLite şeması (8 tablo; sonuçlar uzun biçimde; inşa betiği); ilk ekran (PBE simülasyonu); rapor (.docx; sayılar R'de, biçim JavaScript ile; denenmedi); platform doğrulaması (FSR-VAL-PLT-1); uygulama sırası P1–P6; açık sorular (tarayıcı hızı, GitHub Pages'te çapraz köken yalıtımı, özel depoda Pages, lisans); onaya sunulan yedi öneri (Ö1–Ö7, Tablo 10.1).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `CNKfarmastatr/tests/testthat/helper-cases.R` (yeni), `test-invitro-fast.R`, `test-simulation.R`, `belgeler/validasyon/FSR-VAL-SIM-1_ek/kanit.R`, `belgeler/teknik_notlar/FSR-TN-PLT-01_v0.1.docx`, `FSR-TN-PLT-01_ek/webr_hiz.mjs`, `webr_hiz.csv`, bu günlük.
- **Onay bekleyen:** FSR-TN-PLT-01 v0.1, öneriler Ö1–Ö7. Onaylanırsa P1 (prototip sayfa).

## G-51 · FSR-TN-PLT-01 v0.1 incelemesi; P0 spesifikasyonu; v0.2 — 17.10.2026

- **Depo:** G-50 dosyaları commit + push edildi; GitHub Actions GEÇTİ (proje sahibi: "Action tamam").
- **Proje sahibinin incelemesi (K):** "FSR-TN-PLT-01 v0.1 Metodolojik Değerlendirme ve Değişiklik Talepleri" (17.10.2026). Genel karar: temel mimari korunur; Ö1 ve Ö6 onay (minör), Ö2 ve Ö3 koşullu (majör), Ö4, Ö5 ve Ö7 revizyon (majör). İlk iş P0 teknik spesifikasyonu; P0 tamamlanmadan kullanıcıya açık tam arayüz geliştirilmez. → **KK-43**. Ana istekler:
  - Ö1: kapsam sınırları yazılı (dengeli, eksiksiz, tek log-normal ölçüt; FDA PBE ve EMA (a), (b), (c)); çekirdeğin doğrudan çağrısı = arayüz çağrısı.
  - Ö2: SHA-256 "onaylanan baytlarla aynı dosya" kanıtıdır, tedarik zinciri garantisi değil; gerçek tarayıcı testi; hash uyuşmazlığında durma; koşu kaydına webR sürümü, webR'deki R sürümü, çekirdek sürümü, hash'ler, RNG, seed. Node sonucu tarayıcı geneline genişletilmez.
  - Ö3: varsayılan 10.000; 20.000 yalnız prototip performans sınırı; MCSE, süre, ilerleme, iptal; kalıcı sınır cihaz testinden sonra.
  - Ö4: senaryo, koşu ve sonuç bağımsız kimliklerle; yöntem–ölçüt ilişkisi; hipotez tablosu; KK-38 sınıfı, MCSE ve eşleşik farklar inşada R'de; webR başlamadan hazır sonuç okunur; yuvarlanmış metin kimlik olmaz; sürüm uyuşmazlığı gösterilir.
  - Ö5 ve Bölüm 4 ("zorunlu iş kuralı"): her senaryo ve yöntem için gerçek H0/H1; H0'da geçme oranı noktasal tip I hata, H1'de güç, sınıfsız ise "BE kabul olasılığı"; KK-38 yalnız H0'da; tek H0 noktası bileşik H0 kontrolünün kanıtı değil; girdiler A/B/C gruplarında; m ön ayarları; bağlantıda ham veri yok, eski sürüm bağlantısı sessizce yeni sürüme çevrilmez.
  - Ö6: hesap, etiket ve yuvarlama R'de, DOCX biçimi JavaScript'te; R–ekran–Word uyumu otomatik test; koşu kimliği raporda.
  - Ö7: P0 eklendi; betik dışa aktarma P3'e; GitHub Pages koşulları P1'de.
- **Doğrulama (Claude):** İncelemedeki MCSE tablosu, GMR 1,189 (FDA δ₀, temel senaryo), Tablo 4.2'deki FDA ve EMA (c) değerleri yeniden hesaplanarak ya da teknik notla karşılaştırılarak doğru bulundu.
- **P0 prototipi:** `belgeler/teknik_notlar/FSR-TN-PLT-01_ek/hipotez_siniflandirma.R` → `hipotez_siniflandirma.csv`. Kurallar (FarmaStatR türetimi): FDA, gerçek η (kriter gerçek σ_R ile) ≥ 0 ise H0; EMA, gerçek GMR ≤ 0,85 ya da ≥ 1,18 ise H0; sınır toleransı 10⁻¹². Izgaraya (1.085 senaryo) uygulandı:
  - Teknik notun okuması tutarlı: tip I hata olarak raporlanan bütün hücreler H0 sınırında, güç olarak raporlananların hepsi iki yöntemde H1'de.
  - Yeni: Aşama 2'nin 72 senaryosunda (ρ 1'de σ_R 0,06–0,101; ρ 1,15'te σ_R 0,099–0,12) GMR 1,18 FDA için H0 içinde (FDA geçme oranı orada noktasal tip I hata); aynı senaryolarda FDA δ₀ EMA için H1. Teknik not bu hücreleri raporlamadığı için yorum değişmiyor.
  - Sınır toleransı gerekli: δ₀'da η ±2 × 10⁻¹⁶; yalnız işarete bakılsaydı 72 FDA δ₀ senaryosu H1 (güç) sayılırdı.
- **Teknik not FSR-TN-PLT-01 v0.2** (`belgeler/teknik_notlar/FSR-TN-PLT-01_v0.2.docx`, 8 sayfa): inceleme kararları tablosu; denemeler (webR, SQLite, sınıflandırma prototipi); katmanlar, hash iddiasının sınırı, koşu kaydı alanları, P1 geçiş koşulu, n_sim ve MCSE tablosu; FDA/EMA hipotezleri; P0 hipotez sınıflandırması (kurallar, metrik etiketi, KK-38, kabul testleri H-1…H-6, K-1…K-3); P0 veri sözleşmesi (senaryo, koşu, yöntem, ölçüt, sonuç, hipotez; kanonik parametre anahtarı `.num_exact` kuralıyla; sürüm uyuşmazlığı); ekran (A/B/C girdi grupları; ürün tipine göre m ön ayarları, KK-36 ile tutarlı; sürüme bağlı bağlantı); rapor sorumlulukları; platform doğrulaması; P0–P6 ve geçiş ölçütleri.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** FSR-TN-PLT-01 v0.2, `hipotez_siniflandirma.R`, `hipotez_siniflandirma.csv`, bu günlük.
- **Onay bekleyen:** v0.2'nin incelemeyi doğru işlediği ve P0'ın tamamlandığı; sınıflandırma toleransı 10⁻¹².

## G-52 · FSR-TN-PLT-01 v0.2 incelemesi; D-01 … D-06; v0.3 — 17.10.2026

- **Depo:** G-51 dosyaları commit + push edildi; GitHub Actions GEÇTİ (proje sahibi: "actio ok"). Claude bunu v0.2 onayı saymadı ve onay istedi.
- **Proje sahibinin incelemesi (K):** "FSR-TN-PLT-01 v0.2 Metodolojik Değerlendirme" (17.10.2026). P0 tasarımına koşullu olumlu görüş; Ö1–Ö7 büyük ölçüde karşılandı. D-01, D-02 ve D-05 belge düzeyinde kapatılıp D-06 kabul ölçütleri sabitlenince P1'e geçilir; D-03 ve D-04 P2 öncesinde kapatılır. Yeni faktöriyel simülasyon ya da yeniden tasarım gerekmez. → **KK-44**.
  - D-01 (majör): "ρ > 1,758 ve δ = 0 ⇒ FDA H0" yalnız referans ölçekli bölgede geçerli; H-5 iki varyans bölgesini kapsamalı.
  - D-02 (minör): 10⁻¹² toleransın sayısal niteliği ve geçerlilik alanı yazılsın; kullanıcı girişinde sınır yakınlığı ele alınsın.
  - D-03 (majör, P2 öncesi): GMR ya da δ girişinde ondalık dönüşüm anahtarı bozmasın; tek iç gösterim ve kayıpsızlık testleri.
  - D-04 (majör, P2 öncesi): birleşik sonuçların kaynak run_id ilişkisi; yöntem çifti ve eşleşik MCSE saklama kuralı.
  - D-05 (minör): P1 yalnız minimal prototip; üretim tipi sınıflandırma fonksiyonu P2 teslimatı.
  - D-06 (majör): P1 için ara değer toleransı, nihai karar birebirliği, hata yakalama, iptal ve cihaz performansı eşikleri önceden sabitlensin.
- **Doğrulama (Claude):** D-01'deki iki örnek yeniden hesaplandı: σ_R 0,12, ρ 1,8, δ 0 → η = +0,002173 (H0 içi); σ_R 0,06 → η = −0,012827 (H1). Genel koşul ρ² ≥ 1 + θ_p·max(σ²_R, 0,01)/σ²_R; σ_R 0,06'da eşik ρ ≥ 2,608. v0.2'nin ifadesi ve H-5 eksikti; proje sahibi haklı.
- **Bulgu (Claude, P1 ölçütlerini yazarken):** Motor negatif σ_R ile hata vermeden koşuyor; ℓ = 1 ya da n = 1'de anlamsız bir R iletisiyle duruyor ("NAs are not allowed in subscripted assignments"). Sabitlenmiş motor dosyaları değiştirilmeden, platformun R giriş kontrolü (ayrı fonksiyon) bu girdileri reddedecek; motorda düzeltme ilk revizyona (FSR-VAL-SIM-1 açık maddesi).
- **Teknik not FSR-TN-PLT-01 v0.3** (`belgeler/teknik_notlar/FSR-TN-PLT-01_v0.3.docx`, 10 sayfa): D-01 (Tablo 5.1 notu ve H-5'in dört vakası); D-02 (yeni Bölüm 5.3: toleransın niteliği, geçerlilik alanı, sınır noktasının adlandırılmış seçenekle seçilmesi, sınır yakınlığı uyarısı FDA |η| ≤ 10⁻⁶, EMA |δ − ln L| ≤ 10⁻⁴); D-05 (P1 minimal prototip, oranlar "BE kabul olasılığı"; üretim fonksiyonu P2); D-06 (yeni Bölüm 11, Tablo 11.1: 36 koşuluk test kümesi; karar sayıları birebir; ara değerler K(10⁻¹², 10⁻¹²); hata yakalama; hash; iptal ≤ 2 sn; açılış ≤ 15 sn; 3 × 10 ve 10.000 ≤ 10 sn; 6 × 30 ve 20.000 ≤ 60 sn; bellek ≤ 1 GB; mobil yalnız gözlem); D-03 ve D-04 için öneriler (Bölüm 6.3; P2 öncesi kapanacak).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** FSR-TN-PLT-01 v0.3, bu günlük.
- **Onay bekleyen:** D-01, D-02, D-05'in kapandığı ve Tablo 11.1'deki P1 kabul ölçütleri (süre, bellek, iptal eşikleri Claude önerisi). Onaylanırsa P0 kapanır, P1 başlar.

## G-53 · v0.3 nihai görüşü; D-02 metni; P1 test koşulları; P0 kapandı — 17.10.2026

- **Proje sahibinin nihai görüşü (K):** FSR-TN-PLT-01 v0.3'ün temel tasarımı onaylandı ve P1 geliştirmesine geçiş desteklendi. İki koşul kondu: D-02 gerekçesi düzeltilecek; performans ve doğrulama ölçütlerinin test koşulları uygulamadan önce sabitlenecek. Bunlar mimariyi değiştirmiyor, validasyonun bilimsel savunulabilirliğini güçlendiriyor. → **KK-45**.
- **D-02 öz eleştirisi (Claude):** v0.3'teki "σ ≤ 10 iken yuvarlama hatası < 10⁻¹³" ifadesi türetilmemiş ve test edilmemişti. Sonradan yapılan ön sınama: σ_R 0,01–10 ve ρ 0,1–3 aralığında 10⁶ rastgele noktada, δ₀'da en büyük |η| = 5,7 × 10⁻¹⁴ çıktı. Bu bir güvence değil, yalnız gözlemdir; belgeye girmedi. Ayrıca iki zayıflık bildirildi: mutlak toleransın büyük σ'larda payının daralması ve FDA/EMA uyarı eşiklerinin ortak bir ölçeğe dayanmaması.
- **Proje sahibinin D-02 kararı (K):** 10⁻¹² mutlak tolerans korunur. Bölüm 5.3'teki geçerlilik açıklaması proje sahibinin metniyle değiştirilir: tolerans bir proje toleransıdır, eşdeğerlik marjı değildir; mevcut ızgarada sapma en çok 2 × 10⁻¹⁶; geniş parametre alanında uygunluk P2'de sınır ve sınır yakınlığı testleriyle doğrulanır; tolerans kanıtlanmış bir analitik üst sınır olarak yorumlanmaz. Doğrulanmamış 10⁻¹³ güvencesi kaldırıldı.
- **P1 test koşulları (Claude önerisi, proje sahibince onaylandı):** ortam kaydı (cihaz, işletim sistemi, tarayıcı sürümü, webR 0.5.4, R ve paket sürümü, motor SHA-256 değerleri); süre `performance.now()` ile ölçülür, her ölçüm 5 kez tekrarlanır, medyan ve en kötü değer raporlanır, eşik en kötü değere uygulanır; soğuk ve sıcak açılış ayrı ölçülür; bellek Chrome görev yöneticisinin tepe değeridir; ölçüm sırasında başka yük yoktur; yerel statik sunucu çapraz köken yalıtımı başlıkları olmadan kullanılır; yerel R referansı aynı seed, RNG türü ve paket sürümüyle üretilir; karşılaştırma `p1_kabul.R` betiğiyle yapılır; çıktılar `FSR-TN-PLT-01_ek/p1/` klasörüne CSV olarak yazılır. Ölçütler test sonuçları görüldükten sonra gevşetilmez.
- **Teknik not FSR-TN-PLT-01 v0.4** (`belgeler/teknik_notlar/FSR-TN-PLT-01_v0.4.docx`, 10 sayfa):
  - Bölüm 5.3: proje sahibinin D-02 metni olduğu gibi kondu.
  - Tablo 5.3: P2 için genişletilmiş parametre alanı testi H-7 eklendi.
  - Bölüm 11: Tablo 11.1 ve yeni Tablo 11.2 (test koşulları) donduruldu.
  - Bölüm 13: kararlar (KK-44, KK-45).
  - Meta ve beyan: P0 onaylandı.
  - Derleme notu: ilk derleme yanlış şablonla yapıldı (üstbilgide "FSR-TN-PBE-01 v0.10", pakette kullanılmayan görseller, 562 KB). Teslim edilen dosya v0.3 paketi üzerine yeniden derlendi (31 KB); üstbilgi ve belge başlığı "FSR-TN-PLT-01 v0.4".
- **Durum:** P0 kapandı; P1 (minimal tarayıcı prototipi ve R giriş kontrolü) başlıyor. P1'in başarısına dondurulmuş Tablo 11.1 testleri koşulduktan sonra proje sahibi karar verecek. D-03 ve D-04 P2 öncesinde kapatılacak.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** FSR-TN-PLT-01 v0.4, bu günlük.

## G-54 · P1 başladı: platform giriş kontrolü (R) — 17.10.2026

- **Depo:** G-53 dosyaları commit + push edildi; GitHub Actions GEÇTİ (proje sahibi: "action tamam"). P1 başladı.
- **Motorun sınanması (Claude):** sabitlenmiş motor (`invitro_scenario`) uç girdilerle denendi. Sessizce sonuç veren girdiler:
  - σ_R = 0 → FDA geçme 1,000, EMA (c) NA;
  - ρ = 0 → iki yöntemde de geçme 1,000;
  - α = 0,6;
  - ters EMA sınırları (1,2; 0,8) → EMA (c) geçme 0;
  - σ_T0 < 0.

  Uyarıyla NaN üreten girdi: q < 0 ya da q > 1. Anlamsız iletiyle duran girdiler: m = 2,5 ("length(tau) == m is not TRUE"), δ = Inf ("NAs are not allowed…"). Bunlar G-52 bulgusunu (negatif σ_R; ℓ = 1, n = 1) genişletiyor.
- **Yeni dosya `CNKfarmastatr/R/platform_input.R` (0.1.0):** `platform_check_invitro(params, n_sim_max = 20000)` her sorunu alan, kod ve İngilizce iletiyle bir tabloya yazar; kodlar TR/EN çeviri dosyası içindir. `platform_run_invitro(params)` önce kontrol eder; sorun varsa `farmastat_input_error` sınıfında durur, yoksa `invitro_scenario`'yu değiştirmeden çağırır.
  - **Kapsam (P1):** yalnız matematiksel geçerlilik [FarmaStatR türetimi]:
    - σ_R, ρ, σ_T0 > 0;
    - q ∈ [0, 1];
    - ℓ, n tam sayı ve ≥ 2; m tam sayı ve ≥ 1;
    - δ sonlu;
    - n_sim tam sayı ve [1, 20.000] aralığında (geçici platform sınırı);
    - seed R tam sayı aralığında;
    - α ∈ (0, 0,5);
    - 0 < alt EMA sınırı < 1 < üst EMA sınırı;
    - bilinmeyen, eksik ya da yinelenen parametre reddedilir.
  - **Motora bırakılanlar:** motorun açık bir iletiyle reddettiği girdiler (paylar; m = 1 iken q > 0). Tablo 11.1 uyarınca tarayıcıda ve yerel R'de aynı motor iletisi görünür.
  - **Sonraya kalanlar:** kullanıcı parametre alanının sınırları P2'de (H-7).
- **Testler `test-platform-input.R` (PLT-IN-1…4, 151 beklenti):**
  - geçerli girdi motorla birebir aynı sonucu verir (`identical`);
  - 26 geçersiz girdi doğru alan ve kodla reddedilir, koşu başlamaz;
  - birden çok sorun birlikte raporlanır;
  - motorun reddettiği girdilerde ileti motorunkiyle aynıdır.
- **Sonuçlar:**
  - Tam test kümesi (yüklü paket, NOT_CRAN = true): 30 blok, 1.119 beklenti, 0 hata, 0 atlanan.
  - Çekirdek SHA-256 kontrolü: 13 dosyanın 13'ü AYNI; motor dosyalarına dokunulmadı.
  - `DESCRIPTION` Collate listesine `platform_input.R` eklendi.
  - Yeni dosya validasyonlu çekirdek değil; SHA-256 listesine alınmadı.
- **Açık:** `dogrulama.yml` başlığındaki sayılar (26 blok, 968 beklenti) eskidi. Dosya korumalı; yalnız yorum satırı olduğu için CI'yi etkilemez, P1 sonunda proje sahibi günceller.
- **Sıradaki iş (P1):** minimal tarayıcı prototipi (webR; tek koşu ve sonuç tablosu; hash kontrolü; iptal), ardından `p1_kabul.R` ve Tablo 11.1–11.2 testleri.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `R/platform_input.R`, `tests/testthat/test-platform-input.R`, `DESCRIPTION`, bu günlük.

## G-55 · P1: minimal tarayıcı prototipi — 17.10.2026

- **Depo:** G-54 dosyaları commit + push edildi; GitHub Actions GEÇTİ (proje sahibi: "action ok. 4 dosya yüklü").
- **Yeni klasör `web/p1/`:** `index.html`, `app.js`, `stil.css`, `ceviri.json` (TR/EN, 78 anahtar), `README.md`. Sayfa hesap yapmaz. İşleyiş:
  1. `invitro_fast.R` ve `invitro_grid.R` indirilir; SHA-256 değerleri tarayıcıda hesaplanıp `CEKIRDEK_SHA256.txt` ile karşılaştırılır. Uyuşmazlıkta hiçbir dosya yüklenmez, dosya adı gösterilir.
  2. Doğrulanan baytlar (ikinci bir indirme değil) webR 0.5.4'e PostMessage kanalıyla yüklenir. Bu kanal, çapraz köken yalıtımı olmayan GitHub Pages koşuludur.
  3. `platform_run_invitro()` çağrılır.
  4. Oranlar "BE kabul olasılığı" adıyla ve MCSE ile gösterilir.
  5. Koşu kaydı JSON olarak indirilebilir: girdiler, seed, RNG, R ve webR sürümü, dosya hash'leri, süreler, tarayıcı bilgisi ve sonuç.
- **Ortalama farkı:** adlandırılmış seçeneklerle seçilir: FDA δ₀, GMR 1,00, GMR 1,05, EMA üst sınır, EMA alt sınır ve özel GMR. δ₀ R'de `invitro_delta0()` ile hesaplanır; tanımsızsa açıklayıcı bir iletiyle durulur.
- **`platform_input.R`:** P1'de sabitlenmiş değil; hash'i yalnız kayda yazılır.
- **İptal:** webR, PostMessage kanalında R hesabını kesemez. İptal webR'yi kapatıp doğrulanmış baytlardan yeniden başlatır; kısmi sonuç tutulmaz.
- **Kapsayıcıda yapılan ön deneme (Claude; Playwright, başsız Chromium; resmi P1 testi değildir, Tablo 11.2 koşulları sağlanmadı):**
  - **Özdeşlik:** 3 × 10, FDA δ₀, n_sim 2.000 koşusunda FDA ve EMA (c) geçme oranları ve δ yerel R ile 17 hanede aynı (0,0445; 0,0130; 0,17344468406326474).
  - **Hata yakalama:**
    - negatif σ_R, ℓ = 1 ve n = 1 birlikte raporlandı; sonuç gösterilmedi;
    - pB = 0,9'da motorun kendi iletisi göründü;
    - ρ = 3'te δ₀ iletisi çıktı;
    - dil değişince iletiler çevrildi.
  - **Hash:** sunulan dosyada bir bayt değiştirildi (`invitro_fast.R` 100. ve 5000. bayt, `invitro_grid.R` 2000. bayt). Üç denemenin üçünde hesap engellendi, uyuşmayan dosya adı gösterildi, webR yüklenmedi.
  - **İptal:** 6 × 30 ve n_sim 20.000 koşusu 3 sn sonra iptal edildi. Arayüz 53 ms'de yanıt verdi, sonuç gösterilmedi; motor 1,8 sn'de yeniden hazırdı ve sonraki koşu doğru sonuç verdi.
  - **Süre:** açılış 4,7 sn; 3 × 10 ve 10.000 tekrar 2,1 sn; 6 × 30 ve 20.000 tekrar 20,8 sn.
  - **Mobil (390 px):** düzen tek sütuna geçiyor.
  - **Yerel sunucu:** `httpuv::runStaticServer()` dosyaları doğru türlerle sunuyor.
  - **Denenmedi:** webR'nin CDN'den (`webr.r-wasm.org`) yüklenmesi; kapsayıcının internet erişimi yok, denemede webR npm paketinden yerel olarak sunuldu.
- **Sıradaki iş (P1):** kabul aracı. Tarayıcıda 36 koşuluk test kümesi ve ara değer testi (CSV çıktısı), `p1_kabul.R` karşılaştırması, ardından Tablo 11.2 koşullarında proje sahibinin makinesinde resmi koşu.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `web/p1/` altındaki 5 dosya ve bu günlük.

## G-56 · Prototip proje sahibinin makinesinde çalıştı; P1 kabul aracı — 17.10.2026

- **Proje sahibinin makinesi:** `httpuv::runStaticServer()` ilk denemede "there is no package called 'httpuv'" hatası verdi. Claude paketin kurulu olduğunu varsaymıştı. `install.packages("httpuv")` sonrasında prototip açıldı: durum "Hazır", hesap çalıştı (proje sahibi: "Hazır. çalıştı."). Böylece webR'nin CDN'den yüklenmesi de ilk kez denenmiş oldu. README'ye kurulum satırı eklendi.
- **Ortak modül `web/p1/motor.js`:** dosya doğrulama, webR başlatma ve sonuç dönüştürme, `app.js` ve `kabul.js` tarafından ortak kullanılır.
  - **Hash testi için kanca:** `?bozuk=<dosya>:<bayt>` indirilen dosyanın bir baytını değiştirir. Yalnız doğrulamayı düşürebilir; sayfada gösterilir ve koşu kaydına yazılır.
- **Prototipte düzeltme:** İptal edildi iletisi, motor yeniden başlarken anında "webR yükleniyor" ile eziliyordu; kullanıcı iptal iletisini hiç görmüyordu. Kabul aracının ilk kuru denemesi bunu yakaladı. Artık motor hazır olunca "İptal edildi; sonuç üretilmedi. Motor yeniden hazır." gösteriliyor. Yeni çeviri anahtarı: `st_cancelled_ready` (TR/EN, 79 anahtar).
- **Kabul aracı:**
  - **`web/p1/kabul.html` ve `kabul.js` (yalnız Türkçe, iç araç):** Tablo 11.2 adımlarını sayfada sırayla yönetir:
    0. ortam bilgisi;
    1. soğuk açılış ×5 (DevTools'ta "Disable cache" açık, beyan kutusuyla);
    2. sıcak açılış ×5;
    3. ayrı bir webR'de 36 koşu, ara değerler ve hata yakalama; çerçevedeki prototipte 3 hash denemesi, iptal testi ve 5 + 5 performans koşusu;
    4. tepe bellek (görev yöneticisinden elle) ve mobil gözlem;
    5. `p1_tarayici.csv` indirme. CSV'nin tek uzun biçimi: bolum, anahtar, ad, deger.
  - **`web/p1/kabul/kabul.R`:** tarayıcıda ve yerel R'de aynı kod koşar. Sayılar `%.17g` ile yazılır.
    - **Test kümesi:** Tablo 11.1'deki 36 koşu. Tabloda adı geçmeyen parametreler prototip varsayılanlarında tutuldu (σ_R 0,12, ρ 1, p_L 0,15, q 0) [FarmaStatR türetimi; donmuş tabloda belirtilmemişti].
    - **Ara değerler:** PSG 020929 örneği ve TC-F2'nin ilk veri seti üzerinde `pbe_fast` ve `ema_ci_fast`.
    - **Hata vakaları:** 3 motor, 3 platform.
  - **`web/p1/kabul/p1_kabul.R`:** sabitlenmiş dosyaların SHA-256 değerlerini denetler, yerel hesabı yapar ve ölçütleri yalnız uygular (GECTI, KALDI, EKSIK, KOSUL_SAGLANMADI). Çıktılar `FSR-TN-PLT-01_ek/p1/` klasörüne yazılır: `p1_karsilastirma.csv`, `p1_yerel_r.csv`, gerekirse `p1_fark_ayrinti.csv`, `p1_yerel_sessionInfo.txt`.
  - **Tanımsız eşik:** "arayüz yanıt verir" için donmuş tabloda sayısal eşik yok. Ölçüt iptal iletisinin görünmesi olarak uygulandı; zamanlayıcı gecikmesi yalnız raporlanıyor.
- **Kuru deneme (Claude, kapsayıcı; resmi koşu değildir):** Tüm ölçütler GECTI. Ayrıntılar:
  - **Karar sayımları:** 396 sayımın hepsi aynı.
  - **Ara değerler ve koşu özetleri:** 2.115 değer K(10⁻¹², 10⁻¹²) içinde. 2.121 değerin 13'ü son bitte farklı (göreli fark ≤ 4,3 × 10⁻¹⁶): sapma payı ortalamaları ve eşleşik fark MCSE'leri. Olası neden: yerel R `mean()` hesabında uzun çift duyarlık (long double) kullanıyor, WebAssembly'de bu yok. Kararlar ve ara büyüklükler birebir aynı. Bu, G-50'deki "17 hanede aynı" gözlemini daraltıyor: o gözlem yalnız dört değer üzerindeydi.
  - **Diğer ölçümler:**
    - hash 3/3 engellendi;
    - iptalde durma ≤ 1 ms, motor 1,3 sn'de yeniden hazır;
    - soğuk açılış en kötü 2,7 sn;
    - 3 × 10 ve 10.000 tekrarda en kötü 1,9 sn; 6 × 30 ve 20.000 tekrarda en kötü 18,7 sn.

  Bellek değeri kuru denemede elle uyduruldu (650 MB); resmi koşuda görev yöneticisinden okunacak.
- **Sıradaki iş:** proje sahibinin makinesinde Tablo 11.2 koşullarında resmi koşu ve `p1_kabul.R` karşılaştırması. Sonra P1 kararı proje sahibinindir (KK-45).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `web/p1/` altında `motor.js`, `app.js`, `ceviri.json`, `README.md`, `kabul.html`, `kabul.js`, `kabul/kabul.R`, `kabul/p1_kabul.R`; bu günlük.

## G-57 · P1 resmi kabul koşusu — 17.10.2026

- **Kod:** G-56 commit + push edildi (commit `671d1ae`). Claude, depodaki `.git/index` kaydından G-55 ve G-56 dosyalarının commit'te ve güncel olduğunu doğruladı. Commit kodu 0. adımda "Not" alanına yazıldı; CSV'ye girdi.
- **Ortam (Tablo 11.2):**
  - **Cihaz:** Intel Core i7-11370H (8 mantıksal çekirdek), 16 GB RAM, Windows 11 Home Single Language.
  - **Tarayıcı:** Chrome 155; webR 0.5.4 CDN'den (`webr.r-wasm.org`).
  - **R sürümleri:** webR içindeki R 4.5.1; yerel R 4.6.1 (ucrt). Tablo 11.2 aynı R sürümünü şart koşmuyor; aynı seed, aynı RNG türü ve aynı motor dosyaları (SHA-256 ile) şart koşuyor.
  - **Ölçüm:** Soğuk açılış için DevTools'ta "Disable cache" açık beyan edildi. Bellek, Chrome görev yöneticisinde "CNK-FarmaStatR · P1 kabul testleri" sekme satırından okundu: 1.094.000 K = 1.068 MB.
- **`p1_kabul.R` sonucu** (`belgeler/teknik_notlar/FSR-TN-PLT-01_ek/p1/`):
  - **Test kümesi:** GECTI; 36/36 koşu.
  - **Nihai karar birebirliği:** GECTI; 396 sayımın 0'ı farklı.
  - **Ara değerler ve özetler, K(10⁻¹², 10⁻¹²):** GECTI; 2.115 değer, en büyük mutlak fark 2,2 × 10⁻¹⁶. Son bitte farklı değer 13 (göreli fark ≤ 5,4 × 10⁻¹⁶): 8 sapma payı, 4 eşleşik fark MCSE'si ve 1 EMA üst güven sınırı. Kararlar birebir aynı.
  - **Hata yakalama:** GECTI; 6/6.
  - **Hash:** GECTI; 3/3 engellendi.
  - **İptal:** GECTI; durma 1 ms, arayüz gecikmesi 2 ms, iptal iletisi göründü, kısmi sonuç gösterilmedi, motor 0,97 sn'de yeniden hazır.
  - **Soğuk açılış:** GECTI; medyan 1,4 sn, en kötü 2,8 sn. Sıcak açılış (yalnız rapor): medyan 1,1 sn.
  - **Performans 3 × 10, 10.000 tekrar:** GECTI; en kötü 2,6 sn.
  - **Performans 6 × 30, 20.000 tekrar:** GECTI; en kötü 29,5 sn. Her iki düzende 5 tekrarın sonucu aynı.
  - **Tepe bellek:** betiğe göre "KALDI"; 1.068 MB, eşik 1.024 MB.
  - **Mobil:** gözlem girilmedi.
- **Claude'un hatası (betik donmuş ölçütü yanlış uyguladı):** Tablo 11.1'in "Performans ve bellek" satırı (v0.4, KK-45 ile donduruldu) aynen şöyle: "3 × 10 ve 10.000 ≤ 10 sn; 6 × 30 ve 20.000 ≤ 60 sn; tepe bellek ≤ 1 GB. **Aşılırsa test kalmaz; geçici üst sınır düşürülür.**" `p1_kabul.R` aşımı KALDI olarak yazdı ve genel sonucu KALDI yaptı. Donmuş ölçüte göre bellek aşımı testi düşürmez; sonucu, geçici n_sim üst sınırının (20.000) düşürülmesidir. Bu bir ölçüt gevşetmesi değil, betiğin donmuş metne uydurulmasıdır. Düzeltme proje sahibinin onayına sunuldu.
- **Gözlem:** Ölçülen sekme, kabul sayfasının kendisini ve prototipin çerçevede defalarca yeniden açıldığı hâli içeriyor. Prototip tek başına daha az bellek kullanıyor olabilir; bu ayrıca ölçülmedi. Ayrıca WebAssembly belleği büyüdükten sonra işletim sistemine geri verilmez; tepe değer, sekmenin en büyük koşusunu yansıtır.
- **Karar bekleyen (proje sahibi, KK-45):**
  - Bellek satırının donmuş metne göre uygulanması: test kalmaz, geçici üst sınır düşer;
  - P1'in başarılı sayılması;
  - yeni geçici üst sınırın nasıl belirleneceği.
- **Dosyalar:** `FSR-TN-PLT-01_ek/p1/` altındaki 4 çıktı dosyasını proje sahibi oluşturdu (`p1_tarayici.csv`, `p1_karsilastirma.csv`, `p1_yerel_r.csv`, `p1_yerel_sessionInfo.txt`); Claude dokunmadı. Bu günlük depoya yazıldı ve bayt bayt doğrulandı.

## G-58 · P1 koşullu başarılı; bellek kuralı; yeni üst sınır için ölçüm — 17.10.2026

- **Proje sahibinin sorusu ve Claude'un değerlendirmesi:** Proje sahibi, sınırı aşan değeri başarılı saymanın ileride sorun çıkarıp çıkarmayacağını sordu. Claude'un değerlendirmesi:
  - Kural testten önce donduruldu (v0.4, KK-45). Aşımı yok saymıyor; bir sonuç bağlıyor: üst sınır düşürülür.
  - Sorun çıkaracak durumlar şunlar: belgelerde "bellek GEÇTİ" yazmak, 20.000 sınırını bırakmak, yeni sınırı tahminle koymak, tek ve elle okunmuş ölçüme fazla güvenmek.
  - Önerisi: P1 koşullu başarılı sayılsın; kapanış, yeni sınırın ölçümle doğrulanmasına bağlansın.
- **Proje sahibinin kararı (K):** "sağla" → **KK-46**.
  - P1 koşullu başarılı.
  - Bellek eşiğinin aşıldığı (1.068 > 1.024 MB) açıkça kaydedilir; hiçbir belgede "bellek geçti" denmez.
  - Donmuş kurala göre geçici n_sim üst sınırı (20.000) düşürülür; yeni sınır ölçümle belirlenir.
  - P1'in kapanışı bu ölçüme ve belgeye işlenmesine bağlıdır.
- **`web/p1/kabul/p1_kabul.R` 0.2:** "Performans ve bellek" satırı donmuş metne göre uygulanır. Aşım `ASILDI_SINIR_DUSER` olarak yazılır, KALDI olarak değil; eşikler değişmedi. Resmi CSV ile yeniden koşuldu (Claude, kapsayıcı): bellek `ASILDI_SINIR_DUSER`, diğer ölçütler GECTI, genel GECTI ve eşik aşımı notu. Proje sahibinin makinesinde yeniden koşulacak; 0.1'in çıktıları G-57 commit'inde kalır.
- **Yeni üst sınır için ölçüm planı (Claude önerisi):**
  - Prototip (`web/p1/`) tek başına; her ölçüm yeni bir sekmede, çünkü WebAssembly belleği küçülmez.
  - Sabit girdiler: 6 × 30, m = 3, FDA δ₀.
  - Ölçümler: "Hazır" durumunda taban değer, ardından n_sim 10.000, 15.000 ve 20.000. Her biri sekmenin görev yöneticisindeki tepe bellek değeri.
  - Yeni sınır, bellek ile n_sim·ℓ·n·m arasındaki ilişkiden önerilecek ve FSR-TN-PLT-01 v0.5'e işlenecek.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `web/p1/kabul/p1_kabul.R`, bu günlük.

## G-59 · Bellek ölçümü: prototip tek başına — 17.10.2026

- **Depo:** G-57 ve G-58 commit edildi. `p1_kabul.R` 0.2 proje sahibinin makinesinde yeniden koşuldu: bellek `ASILDI_SINIR_DUSER`, diğer ölçütler GECTI. Çıktılar ayrı bir commit'te.
- **Ölçüm:** proje sahibi, aynı makine ve Chrome; her ölçüm yeni bir sekmede; prototip `web/p1/` tek başına; 6 × 30, m = 3, FDA δ₀. Değerler "Sekme: CNK-FarmaStatR · P1 prototipi" satırının tepe değeri (K ÷ 1024 = MB):

  | Durum | K | MB | ℓ·n·m·n_sim (hücre) |
  |---|---|---|---|
  | Taban ("Hazır") | 156.692 | 153,0 | – |
  | n_sim 10.000 | 602.960 | 588,8 | 5,4 × 10⁶ |
  | n_sim 15.000 | 704.920 | 688,4 | 8,1 × 10⁶ |
  | n_sim 20.000 | 959.652 | 937,2 | 10,8 × 10⁶ |

- **Okuma (Claude):**
  - Prototip tek başına 20.000 tekrarda 937 MB kullanıyor. Bu 1 GB'ın altında, ama yalnız %8,5 pay bırakıyor.
  - Resmi koşudaki 1.068 MB'ın yaklaşık 130 MB'ı kabul sayfasının kendi yükü; sayfa prototipi defalarca yeniden açtı.
  - Artış doğrusal değil: 10.000'den 15.000'e +100 MB, 15.000'den 20.000'e +249 MB. Bu, WebAssembly belleğinin parça parça büyümesiyle uyumlu bir gözlem, ama ayrıca doğrulanmadı.
  - Ölçüm tek makinede ve birer kez, elle okundu.
- **Kural gereği (KK-46):** Resmi ölçüm eşiği aştığı için geçici üst sınır yine de düşürülür. Prototipin tek başına eşiğin altında kalması bu sonucu değiştirmez; yalnız sınırın ne kadar düşeceğine bilgi verir.
- **Öneri (Claude) [FarmaStatR türetimi]:** Geçici sınırı yalnız n_sim'e değil, koşunun büyüklüğüne (hücre sayısı ℓ·n·m·n_sim) bağlamak:
  - n_sim ≤ 20.000 ve ℓ·n·m·n_sim ≤ 8,1 × 10⁶ (ölçülen 15.000 noktası, 688 MB, yaklaşık %33 pay). Örneğin 6 × 30, m = 3 düzeninde en çok 15.000 tekrar; 3 × 10 düzeni ve varsayılan 10.000 tekrar etkilenmez.
  - Ayrıca P1'deki girdi kontrolünde ℓ ve n için üst sınır yok; hücre sınırı bunu da kapsar.
  - Uygulama yeri: `platform_input.R` (sabitlenmiş değil) ve testleri; arayüzde iletisi. Belge: FSR-TN-PLT-01 v0.5. P1 kapanışı bunlardan sonra.
- **Karar bekleyen:** önerilen kural.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** bu günlük.

## G-60 · Koşu büyüklüğü sınırı uygulandı; FSR-TN-PLT-01 v0.5 — 17.10.2026

- **Depo:** G-59 commit edildi; Actions GEÇTİ (proje sahibi: "commit edildi action ok").
- **Proje sahibinin kararı (K):** "onaylıyorum" → **KK-47**: geçici üst sınır n_sim ≤ 20.000 ve ℓ·n·m·n_sim ≤ 8,1 × 10⁶ [FarmaStatR türetimi; dayanak G-59].
- **`CNKfarmastatr/R/platform_input.R` 0.2.0:** `platform_check_invitro()` ve `platform_run_invitro()` fonksiyonlarına `cells_max = 8.1e6` bağımsız değişkeni eklendi.
  - Koşu büyüklüğü yalnız ℓ, n, m ve n_sim geçerliyse denetlenir. Verilmeyen boyut için motorun varsayılanı kullanılır (3, 10, 3).
  - Aşımda kod `run_size`, alan `n_sim`; ileti tasarıma göre üst sınırı söyler (6 × 30, m = 3 için 15.000).
  - Dosya sabitlenmiş değil; SHA-256 listesi değişmedi.
- **Test PLT-IN-5 (13 beklenti):**
  - 6 × 30, m = 3: 15.000 geçer, 15.001 reddedilir. m = 1 ve 20.000 geçer.
  - 3 × 10, m = 3 ve 20.000 geçer. 100 × 100, m = 3: 270 geçer, 271 reddedilir.
  - Varsayılan boyutlar doğru işler; geçersiz boyutta ikinci bir ileti çıkmaz; sınır değiştirilebilir.

  Tam test kümesi (yüklü paket, NOT_CRAN): 31 blok, 1.131 beklenti, 0 hata, 0 atlanan. Çekirdek SHA-256: 13/13 AYNI.
- **Arayüz (`web/p1/index.html`, `app.js`, `ceviri.json`):** Monte Carlo grubunda "Bu tasarımda nsim üst sınırı" satırı gösteriliyor. Bu yalnız gösterim; sınırı R uygular. Yeni çeviri anahtarları: `code_run_size`, `nsim_max_design` (TR/EN, 81 anahtar). Kapsayıcıda denendi:
  - varsayılan düzende 20.000, 6 × 30'da 15.000 gösteriliyor;
  - 20.000 girilince Türkçe ve İngilizce ileti çıkıyor, koşu başlamıyor;
  - 2.000 tekrarlık koşu çalışıyor.
- **Teknik not FSR-TN-PLT-01 v0.5** (11 sayfa):
  - **Bölüm 3.3:** sınır kuralı.
  - **Yeni Bölüm 11.3:** resmi koşunun sonuç tablosu, betik düzeltmesi ve KK-46.
  - **Yeni Bölüm 11.4:** bellek ölçümü tablosu, kural, sınırlılıklar ve açık madde.
  - **Bölüm 12 ve 13:** güncellendi. 13'te karar isteği: v0.5 onaylanırsa P1 kapanır.
- **Açık maddeler:**
  - Kabul aracının iptal ve performans adımları 6 × 30 ve 20.000 tekrar kullanıyor; bu girdi artık reddedilir. Araç yeniden kullanılmadan önce (P2 kabul ölçütleriyle) ölçüt revizyonu olarak düzeltilecek.
  - `dogrulama.yml` başlığındaki sayılar eskidi (şimdi 31 blok, 1.131 beklenti).
  - README'de iki sayfanın (prototip ve kabul aracı) yan yana anlatımı.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `platform_input.R`, `test-platform-input.R`, `web/p1/index.html`, `app.js`, `ceviri.json`, `FSR-TN-PLT-01_v0.5.docx`, bu günlük.

## G-61 · FSR-TN-PLT-01 v0.5 onaylandı; P1 kapandı — 18.10.2026

- **Depo:** G-60 commit edildi; Actions GEÇTİ (proje sahibi: "action tamam").
- **Proje sahibinin kararı (K):** "onaylıyorum" → **KK-48**. FSR-TN-PLT-01 v0.5 onaylandı. KK-46'nın koşulu sağlandı: yeni sınır ölçüldü, uygulandı ve belgelendi. **P1 kapandı.** Sıradaki aşama P2.
- **Ara soru:** Proje sahibi, simülasyon dışında gerçek veriyle PBE hesabının yapılıp yapılamayacağını sordu. Claude'un cevabı:
  - Yapılabilir, ama şimdilik yalnız R'de: önce `kp_hazirla()` ile giriş kontrolü, sonra `kp_pbe()` (validasyonlu `calc_pbe`). Tarayıcıda veri analizi ekranı henüz yok; ileride ayrı bir modül olacak.
  - PSG 020929 örneğinde beklenen sonuç: Reference-scaled, σ_R 0,405, GMR 1,16, Hη −0,0315, PASS.
  - Log dönüşümü uyarısı verildi.
- **Sunucuyu kapatma:** R konsolunda Esc (RStudio'da Dur simgesi); gerekirse `httpuv::stopAllServers()`.
- **Not:** v0.5'in künye tablosu "v0.5 onayı bekliyor" diyor. Onay bu girdiyle kayıtlı; künye bir sonraki sürümde güncellenecek.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** bu günlük.

## G-62 · Gerçek veriyle PBE için yardımcı betik — 18.10.2026

- **Depo:** G-61 commit edildi; Actions GEÇTİ.
- **Sorun:** Proje sahibi G-61'de verilen kodla analiz yapamadı ("olmadı"); kendi verisini nasıl gireceğini ve PSG örneğini nasıl çalıştıracağını sordu. Hata iletisi paylaşılmadı. Claude'un değerlendirmesi:
  - Verilen kod `verim.csv` adlı, var olmayan bir dosyayı okuyordu; sütun adlarının ne olması gerektiği yalnız yorum satırında yazıyordu.
  - Türkçe Excel'in "CSV" çıktısı noktalı virgül ve ondalık virgül kullanır; `read.csv` bunu okuyamaz.
  - Açıklama yetersizdi.
- **Yeni dosya `araclar/pbe_hesapla.R`:** `pbe_hesapla(dosya, log_d, test, ref, tek_yonlu)` fonksiyonu.
  - CSV'yi okur: virgüllü ya da noktalı virgüllü, ondalık nokta ya da virgül, Excel'in BOM'u. Türkçe sütun başlıklarını (Aşama, Ölçüm) tanır.
  - Validasyonlu çekirdeği değiştirmeden çağırır: `kp_hazirla()`, ardından `kp_pbe()`, o da `calc_pbe()`'yi.
  - Tasarımı, uyarıları ve sonucu beyanla birlikte yazdırır. Dosya bulunamazsa çalışma klasörünü de söyler.
- **Yeni dosya `araclar/pbe_ornek_psg020929.csv`:** PSG 020929 örnek verisi (180 satır), şablon biçiminde: `parti, kap, asama, urun, olcum`.
- **Denendi (Claude, kapsayıcı):**
  - **Virgüllü CSV, log_d = FALSE:** Reference-scaled, σ_T 0,4688, σ_R 0,4046, Eη −0,263896, Hη −0,031499, PASS. Hη, `calc_pbe(ornek_psg020929())` ile birebir aynı (`identical`).
  - **Excel biçimi** (noktalı virgül, ondalık virgül, BOM, "Aşama" ve "Ölçüm" başlıkları): aynı sonuç.
  - **log_d = TRUE:** Constant-scaled, Hη −0,014189, PASS.
  - **Olmayan dosya:** açıklayıcı ileti.
- **Not:** PSG örneği, validasyondaki gibi `log_d = FALSE` ile çalıştırılıyor. Örnek verinin kılavuzda hangi ölçekte verildiği bu girdide doğrulanmadı.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `araclar/pbe_hesapla.R`, `araclar/pbe_ornek_psg020929.csv`, bu günlük.

## G-63 · PBE, m = 1 ve Excel dosyası — 18.10.2026

- **Soru (proje sahibi):** Elindeki veri tek aşamalı (m = 1). Ek bir şey yapması gerekip gerekmediğini sordu. Dosya `C:\cloud\CNK-pharmastat-depo\data01\sample\pbe_ornek_psg020929m1.xlsx`; depo dışında.
- **Erişim:** Proje sahibi bu klasöre okuma erişimi verdi. Dosya yalnız okundu, değiştirilmedi ve depoya alınmadı. İçerik: 60 satır; sütunlar `parti, kap, asama, urun, olcum`; tek aşama "B"; TEST ve REF için 3'er parti ve 30'ar kap. PSG 020929 örneğinin B aşaması.
- **Cevap:**
  - m = 1 için ek bir şey gerekmiyor. Validasyonlu çekirdek tek aşamayı işler: E2 = E4 = 0 ve MSW = 0. Devralınan validasyonda m = 1 vakası var (`devralinan/v0.5.1/validasyon/pbe/R/test_verisi/P2_m1.csv`).
  - Eksik olan Excel okumasıydı.
- **`araclar/pbe_hesapla.R` değişikliği:**
  - `.xlsx` ve `.xls` dosyalarının ilk sayfası `readxl` paketiyle metin olarak okunuyor; paket yoksa kurulum ya da CSV'ye kaydetme öneren bir ileti çıkıyor.
  - Boş Excel satırları atlanıyor.
  - Sütun eşleme ortak bir fonksiyona taşındı.
- **Denendi (Claude, kapsayıcı):**
  - **m = 1 Excel dosyası, log_d = FALSE:** Reference-scaled, σ_T 0,4691, σ_R 0,4052, Eη −0,264966, Hη −0,031920, PASS. Sonuç, `calc_pbe(ornek_psg020929()[Stage == "B", ])` ile birebir aynı (`identical`).
  - **CSV ve Excel biçimli CSV:** G-62'deki sonuçlar değişmedi.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `araclar/pbe_hesapla.R`, bu günlük.

## G-64 · Veri dönüşümü; P2 tasarım notu FSR-TN-PLT-02 v0.1 — 18.10.2026

- **Veri dönüşümü (proje sahibinin isteği):** `Deneysel_Veri_Tablosu_ref_test.xlsx` dosyası `pbe_ornek_psg020929m1.xlsx` yapısına çevrildi ve `Deneysel_Veri_Tablosu_ref_test_m1.xlsx` olarak aynı klasöre kaydedildi (depo dışı: `C:\cloud\CNK-pharmastat-depo\data01\sample`). Yazılan dosya bayt bayt doğrulandı; orijinale dokunulmadı.
  - **Eşleme:** seri → parti (ref1–3 → 1–3, test1–3 → 4–6); uzun formattaki ID → kap (1–120); aşama "B" (veride yok, örnek dosyaya uymak için konan etiket); Referans/Test → REF/TEST; değer → olcum.
  - **Kontrol:** uzun format = geniş tablo (120/120).
  - **Gözlem:** değerler ln ölçeğinde görünüyor; exp(değer) tam sayı (ör. 331). `log_d = FALSE` önerildi.
  - **Deneme hesabı:** Constant-scaled, σ_T = σ_R = 0,0050, Hη −0,020875, PASS.
- **Yerel ayna:** Claude'un çalışma kopyasında `asama1.R`, `asama1_kayit.csv` ve `asama1_sekil.R` eksikti; proje sahibinin deposundan alındı. Depodaki dosyalar eksiksiz.
- **Proje sahibi:** "Tamamdır. şimdi ilerleyebilirsin." G-62 ve G-63 commit'lerinin durumu bu girdide teyit edilmedi.
- **Teknik not FSR-TN-PLT-02 v0.1** (`belgeler/teknik_notlar/FSR-TN-PLT-02_v0.1.docx`, 5 sayfa): P2'nin tasarımı ve kabul ölçütleri, kod yazılmadan önce onaya.
  - **Teslimatlar:**
    - T-1: sınıflandırma fonksiyonu `platform_hipotez()` ve `platform_kk38()`;
    - T-2: kanonik anahtar (D-03);
    - T-3: birleşik sonuçlar (D-04);
    - T-4: SQLite şeması, inşa ve sql.js ile okuma;
    - T-5: P1'den kalan açık maddeler.
  - **Bulgu 1:** Izgara CSV'leri 15 anlamlı basamakla yazılmış; örneğin δ₀(0,12) R'de 0,17344468406326474, CSV'de 0,173444684063265. Bu yüzden anahtar sayıdan değil sınır adından üretilmeli; yeni çıktılar `.num_exact` ile yazılmalı.
  - **Bulgu 2:** Koşu kayıtlarında motor SHA-256'sı yok. Aşama 1 `invitro_grid.R` 0.1.0 ile koşulmuş; değer git geçmişinden aranacak, bulunamazsa "kayıtta yok" yazılacak.
  - **Kararlar (Claude önerisi):**
    - P2-K1 sınır yakınlığı: ortak δ ölçeği, |δ − δ_sınır| ≤ 10⁻⁴;
    - P2-K2 birleşik eşleşik MCSE: Dᵢ yoksa saklanmaz;
    - P2-K3 inşa aracı: R + RSQLite.
  - **Kabul ölçütleri:** S-1…S-11. H-7'nin test noktaları: σ_R 11 değer × ρ 7 değer = 77 çift.
- **Onay bekleyen:** FSR-TN-PLT-02 v0.1 (P2-K1…K3 ve Tablo 8.1).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** FSR-TN-PLT-02 v0.1, bu günlük.

## G-65 · FSR-TN-PLT-02 v0.1 onaylandı; P2 T-1 ve T-2 — 18.10.2026

- **Depo:** G-62, G-63 ve G-64 commit + push edildi; Actions GEÇTİ. Proje sahibi deponun özel ("Private") olduğunu doğruladı. Ona hesap ve e-posta gizliliği hakkında bilgi verildi: Settings → Emails → "Keep my email addresses private" ve GitHub Desktop'ta noreply adresi.
- **Proje sahibinin kararı (K):** "onaylıyorum" → **KK-49**: FSR-TN-PLT-02 v0.1 Claude'un önerileriyle onaylandı.
  - P2-K1 (b): ortak δ ölçeğinde sınır yakınlığı uyarısı, |δ − δ_sınır| ≤ 10⁻⁴.
  - P2-K2: tekrar düzeyinde karar yoksa birleşik eşleşik MCSE saklanmaz.
  - P2-K3: veri tabanı R ve RSQLite ile inşa edilir.
  - Tablo 8.1'deki S-1…S-11 kabul ölçütleri donduruldu.
- **Yeni dosya `CNKfarmastatr/R/platform_hipotez.R` (0.1.0, sabitlenmiş değil):**
  - `platform_hipotez()`: vektörleştirilmiş; δ ya da sınır adıyla çalışır. Yöntem başına gerçek büyüklük (η ya da ln GMR), sınıf, metrik adı (`tip1_sinir`, `noktasal_tip1`, `guc`), yakınlık uyarısı ve δ'nın tam metnini verir.
  - `platform_kk38()`: KK-38 etiketi, yalnız H0 sınıflarında.
  - `platform_anahtar()`: kanonik anahtar.
  - `platform_sinir_delta()`: sınır adından δ.
  - `DESCRIPTION` Collate listesine eklendi.
- **İki tutarsızlık bulundu ve çözüldü (Claude):**
  - **(1) Anahtar tanımı:** FSR-TN-PLT-02 v0.1 Bölüm 4 n_sim ve seed'i tek anahtara koymuştu. FSR-TN-PLT-01 Tablo 6.1 ise senaryoyu "koşudan bağımsız" tanımlıyor. İki anahtara ayrıldı: senaryo anahtarı yalnız veri üretme koşulunu, koşu anahtarı (`kosu = TRUE`) ek olarak n_sim ve seed'i taşır. v0.2'de metin düzeltilecek.
  - **(2) KK-38'deki z değeri:** Karar metni z = 1,645 diyor; `asama2_ozet.R` ise `qnorm(0.95)` = 1,6449 kullanıyor. Fonksiyon tabloların birebir yeniden üretilmesi için `qnorm(0.95)` kullanır; 1,645 bu değerin yuvarlanmışıdır.
- **Testler:**
  - **testthat (`test-platform-hipotez.R`, 848 beklenti):**
    - H-5: dört analitik vaka ve genel FDA koşulu;
    - H-6: KK-38 sınıfları ve sınır değerleri;
    - H-7: 77 çift (σ_R 11 × ρ 7); δ₀ tanımlı ve tanımsız çiftler, yakınlık uyarısı, EMA sınırları;
    - K-1 (i) ve (iii): GMR ve δ ile aynı anahtar; 10.000 rastgele δ'da `.num_exact` kayıpsız.
  - **Izgaraya dayalı kabul betiği (`belgeler/teknik_notlar/FSR-TN-PLT-02_ek/p2_kabul.R`, bölüm 1):** sonuç `p2_kabul_t1.csv`. Izgara CSV'leri paketin içinde değil; bu yüzden bu kontroller CI testinde değil, kabul betiğinde.
    - **H-1:** 249 δ₀ senaryosu FDA'da H0 sınırı.
    - **H-2:** 340 senaryo, EMA'nın üç yolunda H0 sınırı.
    - **H-3:** 496 senaryo, iki yöntemde H1.
    - **H-4:** en büyük |Δη| 2,2 × 10⁻¹⁶. CSV'nin 15 basamağından gelen en büyük |Δδ| 4,4 × 10⁻¹⁶. Yalnız işarete bakılsaydı 72 δ₀ senaryosu yanlış sınıflanırdı; tolerans bunu gideriyor.
    - **S-3:** 22 grubun sınıf sayıları P0 prototipiyle birebir aynı.
    - **S-4:** `asama2_ozet.R`'nin etiket kuralı `platform_kk38()` ile değiştirilip yeniden koşuldu; 7 özet CSV'nin 7'si birebir aynı.
    - **K-1 (ii):** 248 δ₀ senaryosunda ad anahtarı, sayının anahtarından farklı.
    - **K-1 (iv):** anahtarlar aşama içinde tekil; iki aşamada ortak senaryo 0.
  - **Tam test kümesi** (yüklü paket, NOT_CRAN): 35 blok, 1.979 beklenti, 0 hata, 0 atlanan. Çekirdek SHA-256: 13/13 AYNI.
- **Sıradaki iş:** T-3 ve T-4 (SQLite şeması, inşa betiği, birleşik sonuçlar, sql.js ile okuma), ardından T-5.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `platform_hipotez.R`, `test-platform-hipotez.R`, `DESCRIPTION`, `p2_kabul.R`, `p2_kabul_t1.csv`, bu günlük.

## G-66 · P2 T-3 ve T-4: SQLite veri tabanı — 18.10.2026

- **Depo:** G-65 commit + push edildi; Actions GEÇTİ.
- **İnşa betiği `araclar/vt_insa.R`** (P2-K3: R + RSQLite; paketin bağımlılığı değil):
  - **Kaynaklar:** Aşama 1 ve 2 ızgaraları, iki ek tekrar dosyası ve üç koşu kaydı. Bütün sayılar CSV metninden `as.numeric` ile okunuyor; hiçbir sayı yuvarlanmıyor.
  - **Çıktı:** `veri/farmastatr_v1.sqlite` (2,2 MB).
  - **Satır sayıları:** 1.085 senaryo, 6 koşu, 13.555 sonuç, 3.679 fark, 4.340 hipotez.
  - **Şema** (FSR-TN-PLT-02 Tablo 6.1): `insa`, `dosya`, `modul`, `senaryo`, `kosu`, `kosu_kaynak`, `yontem`, `olcut`, `sonuc`, `fark`, `hipotez`; boş açılanlar: `yayin`, `veri_seti`, `test_vakasi`. Senaryo, metin anahtarın (`senaryo_anahtar`, tekil) yanında bir de tam sayı numarası (`senaryo_no`) taşıyor; böylece dosya boyutu 5,4 MB'tan 2,2 MB'a indi.
  - **Koşular:** A1 ve A2 ana koşu (tür "tek"); A1-EK ve A2-EK (40.000 tekrar, seed 20261016); A1-BIR ve A2-BIR ("birleşik", 50.000 tekrar; kaynakları `kosu_kaynak` tablosunda; bağımsız akış varsayımı yazılı).
  - **Birleşik eşleşik MCSE** (P2-K2): saklanmadı; gerekçe yazılı ("tekrar düzeyinde karar yok"). Aşama 1 birleşik farkı tahmin olarak saklandı.
  - **Türetilmiş değerler:** hipotez sınıfı, KK-38 etiketi ve CSV'de MCSE'si olmayan 18 havuzlama oranının binom MCSE'si. Kaynak sütununda "türetilmiş" diye işaretli.
  - **Motor SHA-256:** sürüm numarası sabitlenmiş dosyanın sürümüyle aynıysa SHA-256 sabitleme listesinden alınıyor [FarmaStatR türetimi: dosyanın sürümü değişmediyse içeriği de değişmemiştir varsayımı]. A1 koşusundaki `invitro_grid.R` 0.1.0 sabitlenmiş sürüm değil; satırına gerekçeli "kayıtta yok" yazıldı.
  - **Git geçmişi:** Claude, GitHub deposunu bu oturuma ekleyemedi (GitHub hesabı bağlı değil). Sizin bilgisayarınızdaki `.git` nesneleri yüzlerce dosya olduğu için taranmadı. Değer bulunursa sonradan eklenebilir.
- **Kabul betikleri:**
  - **`p2_kabul_vt.R`:** S-6, S-7, S-8 ve S-9 ölçütlerini sınar. Sınıf ve KK-38 kurallarını platform fonksiyonunu çağırmadan, bağımsız olarak yeniden yazar.
  - **`vt_oku.mjs`:** Node ve sql.js 1.12.0 ile S-8 için veri tabanını okur.
  - **Çıktılar:** `p2_kabul_vt.csv` ve `vt_dokum_sha256.txt`.
- **Sonuçlar (Claude, kapsayıcı): hepsi GECTI.**
  - **S-6a:** 1.085 senaryo; 12 parametre sütunu CSV ile birebir; anahtar yeniden üretildi.
  - **S-6b:** 13.555 sonuç satırının tahmin, MCSE ve tekrar sayısı birebir.
  - **S-6c:** 11.385 oranın MCSE'si √(p(1−p)/n) ile tolerans içinde (en büyük göreli fark 4,9 × 10⁻¹⁵).
  - **S-6d:** Ek tekrar dosyalarındaki 10.000 tekrarlık değer, 76 hücrede ana koşuyla aynı.
  - **S-6e:** Birleşik oran = (10.000 p + 40.000 p) / 50.000 (76 hücre).
  - **S-6f:** Aşama 2 eşleşik farkları CSV ile aynı; birleşik koşuda MCSE yok, gerekçesi yazılı.
  - **S-6g:** 4.340 hipotez sınıfı ve 4.492 KK-38 etiketi bağımsız yeniden hesapla birebir.
  - **S-7:** İki inşanın içerik dökümü aynı (SHA-256 bdcdfc1d…).
  - **S-8:** sql.js ile okunan `sonuc` ve `hipotez` tabloları her sütunda birebir.
  - **S-9:** 6 koşu; 3'ünde motor SHA-256 dolu, 1'inde gerekçeli "kayıtta yok", 2'si birleşik.
- **Hata ve düzeltme:** S-8 ilk koşuda KALDI çıktı. Neden: `read.csv`, sql.js çıktısındaki sayıya benzeyen metin sütununu (`delta_hesap_metin`) sayıya çevirdi. Karşılaştırma bütün sütunları metin olarak okuyup R'deki türüne çevirecek şekilde düzeltildi. Veri tabanında hata yoktu.
- **Sınırlılıklar:**
  - S-8 yalnız Claude'un ortamında (Node) sınandı; proje sahibinin makinesinde Node olmayabilir.
  - Döküm SHA-256'sı R ve RSQLite sürümünü içerir; başka bir makinedeki inşa farklı bir değer verir. S-7 aynı makinedeki iki inşayı karşılaştırır.
  - Bağımsız tekrar (48) ve mekanizma (12) dosyaları P2 kapsamında değil; veri tabanına sonra eklenecek.
- **Sıradaki iş:** T-5 (P1'den kalan açık maddeler), FSR-TN-PLT-02 v0.2 (anahtar tanımı, sonuçlar) ve P2 kapanışı.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `araclar/vt_insa.R`, `veri/farmastatr_v1.sqlite`, `FSR-TN-PLT-02_ek/` altında `p2_kabul_vt.R`, `vt_oku.mjs`, `p2_kabul_vt.csv`, `vt_dokum_sha256.txt`; bu günlük.

## G-67 · Veri tabanı: Aşama 1 motor SHA-256'sı git geçmişinden; yerel ayardan bağımsız sıralama — 18.10.2026

- **Durum:** G-66'nın dosyaları (`vt_insa.R`, veri tabanı, kabul betikleri, günlük) 11:25'te depoya yazılmıştı ama henüz commit edilmemişti. Proje sahibinin "actions tamam. ilerleyebilirsin" mesajı (11:41) G-65'in Actions sonucuydu.
- **Claude'un hatası:** Bu turda Claude G-66'yı bağlamında görmeden T-3/T-4'e yeniden başladı ve ikinci bir inşa betiği yazdı. Depodaki klasörü listeleyince durumu fark etti. İkinci uygulama atıldı ve depoya yazılmadı; G-66 sürümü korundu. Yerel ayna depodan yenilendi.
- **G-66 sürümüne iki iyileştirme (`araclar/vt_insa.R`):**
  - **(1) Aşama 1 motor SHA-256'sı:** G-66'da "kayıtta yok" yazıyordu; değer git geçmişinde bulundu. Claude, sizin depodaki `.git` nesnelerini tek tek okuyarak Aşama 1 commit'ine (`a81bebc35c`, "Aşama 1 simülasyonu", 15.10.2026 21:19) ulaştı.
    - O commit'teki `invitro_grid.R` 0.1.0 dosyasının SHA-256'sı `aa5c1ab6…af198`. Commit, koşudan 5 dakika sonra yapılmış.
    - Aynı commit'teki `invitro_fast.R` sabitlenmiş değerle aynı (`98350729…`).
    - Aşama 2 commit'indeki (`44b5ef65e1`) `invitro_grid.R`, bugünkü sabitlenmiş dosyayla aynı git nesnesi (blob `3baf48d5`). G-66'daki "sürüm aynıysa içerik de aynıdır" varsayımı artık doğrulanmış oldu.
    - Bugünkü durum: 4 tek koşunun 4'ünde motor SHA-256 dolu; "kayıtta yok" kalmadı.
  - **(2) Yerel ayardan bağımsız sıralama:** Satır sıralamaları `order(..., method = "radix")` ile bayt sırasına alındı. R'nin varsayılan sıralaması yerel ayara bağlıdır; Windows ile Linux senaryo numaralarını farklı verebilirdi.
- **Yeniden inşa ve kabul (Claude, kapsayıcı):** 2,22 MB; 1.085 senaryo, 6 koşu, 13.555 sonuç, 3.679 fark, 4.340 hipotez. Bütün S-6a…g, S-7, S-8 ve S-9 GECTI.
  - S-9: motor SHA-256 4/4 dolu.
  - Döküm SHA-256: `f2e49a95…`. G-66'daki değerden farkı, motor SHA alanının dolmasından geliyor.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `araclar/vt_insa.R`, `veri/farmastatr_v1.sqlite`, `FSR-TN-PLT-02_ek/p2_kabul_vt.csv`, `FSR-TN-PLT-02_ek/vt_dokum_sha256.txt`, bu günlük. G-66'nın commit edilmemiş dosyaları (`p2_kabul_vt.R`, `vt_oku.mjs`) değişmedi.

## G-68 · P2 T-5: P1'den kalan açık maddeler; FSR-TN-PLT-01 v0.6 — 18.10.2026

- **Depo:** G-66 ve G-67 commit edildi (proje sahibi: "commit de tamam").
- **(1) Kabul aracı, Tablo 11.1 revizyonu (KK-47 gereği):**
  - **`web/p1/kabul.js` 0.2:** İptal ve performans adımlarındaki koşu 6 × 30 ve 20.000 tekrardan 6 × 30 ve 15.000 tekrara çevrildi; 20.000 tekrar artık giriş kontrolünce reddediliyor. Eşikler (≤ 2 sn, ≤ 60 sn, ≤ 1 GB) değişmedi.
  - **`web/p1/kabul/p1_kabul.R` 0.3:** 6 × 30 performans satırı 15.000 tekrarla okunuyor. Resmi P1 koşusunun CSV'si (G-57, 20.000 tekrar) kendi n_sim değeriyle değerlendirilmeye devam ediyor; yeniden koşuldu, sonuç değişmedi (GECTI; bellek ASILDI_SINIR_DUSER).
  - **Kuru deneme (Claude, kapsayıcı; resmi koşu değil):** Ölçütlerin hepsi GECTI. İptal: durma 1 ms, yeniden hazır 1,1 sn. 6 × 30 ve 15.000 tekrar: en kötü 12,8 sn.
- **(2) CI başlığı (`.github/workflows/dogrulama.yml`):** Yorum satırı güncellendi: platform testleri eklendi; 35 blok, 1.979 beklenti, 18.10.2026. Dosya korumalı olduğu için yazılamadı ("protected file"); güncel dosya proje sahibine gönderildi, o yerleştirecek. Değişen yalnız yorum satırları; CI'nin işleyişi değişmiyor.
- **(3) `web/p1/README.md`:** Yeniden düzenlendi. Ortak bir sunucu bölümü, iki sayfanın adresleriyle bir tablo, prototip ve kabul aracı ayrı başlıklarda. Koşu büyüklüğü sınırı ve sunucuyu durdurma yolu eklendi.
- **(4) Teknik not FSR-TN-PLT-01 v0.6** (12 sayfa):
  - Künye: v0.5 onaylandı, P1 kapandı (KK-48).
  - Sürüm geçmişine 0.6 satırı eklendi.
  - Tablo 11.1'in "İptal" ve "Performans ve bellek" satırları revize edildi; resmi P1 koşusunun 20.000 tekrarla yapıldığı not edildi.
  - Bölüm 11.4'teki açık madde kapandı.
  - Bölüm 13'teki karar isteği, KK-48'in kaydıyla değiştirildi.
- **P2 durumu:** T-1…T-5 tamam. Sırada FSR-TN-PLT-02 v0.2 var: anahtar tanımı düzeltmesi, sonuçlar ve S-1…S-11 özeti; ardından P2 kapanışı için proje sahibinin kararı.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `web/p1/kabul.js`, `web/p1/kabul/p1_kabul.R`, `web/p1/README.md`, `FSR-TN-PLT-01_v0.6.docx`, bu günlük. `dogrulama.yml`'yi proje sahibi yerleştirecek.

## G-69 · FSR-TN-PLT-02 v0.2: P2 sonuçları ve kapanış önerisi — 18.10.2026

- **Depo:** G-68 commit edildi. Proje sahibi güncel `dogrulama.yml`'yi yerleştirdi; Actions geçti ("action tamamlandı"). Böylece S-11'in dört maddesi kapandı.
- **Gerileme yeniden koşusu (Claude, kapsayıcı, UTF-8 yerel ayarı; CI ile aynı komut):** 35 blok, 1.979 beklenti, 0 hata, 0 atlanan. Çekirdek SHA-256 13/13 AYNI.
  - Not: Yerel ayar UTF-8 olmadan koşulursa devralınan validasyon testleri "GEÇTİ" metnini eşleyemez ve hata verir. CI bu yüzden `C.UTF-8` ayarlıyor; sonuç değişmez, yalnız koşu koşuludur.
- **Teknik not FSR-TN-PLT-02 v0.2** (6 sayfa; onay bekliyor):
  - **Bölüm 4:** Anahtar tanımı düzeltildi (G-65). Senaryo anahtarı yalnız veri üretme koşulunu, koşu anahtarı ek olarak n_sim ve seed'i taşır. Örnekler ve veri tabanındaki tamsayı `senaryo_no` eklendi.
  - **Bölüm 3:** z = qnorm(0,95) notu. Kararlar P2-K1, P2-K2, P2-K3 KK-49 olarak kaydedildi.
  - **Bölüm 2:** Bulgu 2'nin sonucu (0.1.0 SHA-256'sı git geçmişinden, G-67).
  - **Bölüm 6.1:** Uygulanan şema ve satır sayıları.
  - **Bölüm 9 (yeni):** Tablo 9.1, kabul sonuçları. S-1…S-11'in 11'i GEÇTİ.
  - **Bölüm 10 (yeni):** Sapmalar ve açık maddeler.
    - A-1: H-1…H-4 CI'da değil, `p2_kabul.R`'de koşuyor. Öneri: sapma kabul edilsin; ızgara kontrolleri sonraki `dogrulama.yml` güncellemesinde CI'a ayrı adım olarak eklensin.
    - A-2: Şema farkları. Tamsayı satır kimliği; KK-38 etiketi `sonuc` tablosunda, çünkü koşuya bağlı; "ek" koşu türü; birleşik koşularda sürüm alanları kaynak koşulardan; `olcut` ve `insa` tabloları.
    - A-3: Bağımsız tekrar ve mekanizma verileri veri tabanına alınmadı; açık madde.
    - A-4: İnşa Windows'ta denenmedi; isteğe bağlı.
    - A-5: G-67'deki süreç hatası.
  - Tablo 8.1'deki ölçütler değişmedi.
- **Proje sahibinden istenen:** v0.2'nin onayı ve P2'nin kapanışı. Onaylanırsa sırada P3 var (senaryonun R betiği olarak dışa aktarılması).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `belgeler/teknik_notlar/FSR-TN-PLT-02_v0.2.docx`, bu günlük.

## G-70 · FSR-TN-PLT-02 v0.2 onaylandı; P2 kapandı — 18.10.2026

- **Depo:** G-69 commit + push edildi; Actions geçti ("action tamam").
- **Proje sahibinin kararı (K):** "v0.2'yi önerilerimle onaylıyorum" → **KK-50**. Claude'un Bölüm 10 ve 12'deki önerileriyle onay olarak işlendi:
  - FSR-TN-PLT-02 v0.2 onaylandı; S-1…S-11 GEÇTİ; **P2 kapandı**.
  - A-1 sapması kabul edildi: H-1…H-4 `p2_kabul.R`'de koşuyor. Izgara kontrollerinin CI'a ayrı adım olarak eklenmesi açık madde olarak sonraki aşamaya taşındı.
  - A-2'deki şema farkları kabul edildi.
  - A-3 açık madde: bağımsız tekrar ve mekanizma verileri veri tabanına alınacak.
  - A-4 isteğe bağlı: veri tabanının Windows'ta inşası.
- **Belge:** FSR-TN-PLT-02'nin künyesi v0.2 içinde "onay bekliyor" olarak kaldı. Onay bu girdi ve KK-50 ile kayıtlıdır; künye bir sonraki revizyonda düzeltilir. Belge yalnız bunun için yeniden yayımlanmadı.
- **Sıradaki iş:** P3, senaryonun R betiği olarak dışa aktarılması (FSR-TN-PLT-01 Bölüm 10). İlk adım, kod yazılmadan önce tasarım ve kabul ölçütlerini onaya sunan FSR-TN-PLT-03 v0.1 (KK-45 ilkesi).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** bu günlük.

## G-71 · P3 tasarımı: FSR-TN-PLT-03 v0.1 (taslak) — 18.10.2026

- **Depo:** G-70 commit edildi; Actions geçti. Proje sahibi: "ilerleyebilirsin".
- **Ön denemeler (Claude, kapsayıcı):**
  - **Bağımsız yükleme:** Beş dosya paket kurulmadan, `R --vanilla` içinde boş bir ortama yüklendi: `sim_run.R`, `invitro_fast.R`, `invitro_grid.R`, `platform_input.R`, `platform_hipotez.R`. `platform_run_invitro()` sonucu kurulu paketinkiyle `identical()`. `sim_run.R`, `platform_hipotez.R`'nin kullandığı `.num_exact()` için gerekli. Beş dosya toplam 47,6 KB.
  - **δ₀:** `invitro_delta0()` ile `platform_sinir_delta()` 5.003 rastgele noktada `identical()`.
  - **SHA-256:** R 4.3.3'te `tools::sha256sum` yok; projenin temel R uygulaması `araclar/sha256.R` kullanılacak.
  - **UTF-8 / CR denetimi:** Beş dosyada CR yok; ASCII dışı karakter yalnız `invitro_fast.R`'nin bir satırında.
- **Teknik not FSR-TN-PLT-03 v0.1** (5 sayfa; onay bekliyor):
  - **Teslimatlar:**
    - T-1: `platform_export_invitro()`. Tarayıcı sınırı uygulanmaz; sabitlenmiş dosyaların SHA-256'sı denetlenir.
    - T-2: Betiğin yapısı.
    - T-3: Prototipe "R betiği" düğmesi.
    - T-4: Testler, kabul betiği, FSR-VAL-SIM-1 v1.1.
    - T-5: KK-50'den taşınan A-1, yani ızgara kontrollerinin CI'a eklenmesi.
  - **Kapsam dışı:** SAS betiği, ızgara betiği, ekran (P4) ve rapor (P5).
  - **Karar bekleyen (Claude'un önerileri):**
    - **P3-K1, betiğin biçimi:** (b) tek dosya. Beş dosya okunur ham dize olarak gömülür; açılışta SHA-256 ile doğrulanır; R ≥ 4.0; paket gerekmez. Diğer seçenekler: (a) paket tabanlı, (c) onaltılık gömülü.
    - **P3-K2:** Düğme P3'te prototipe eklenir. Koşu gerektirmez: sınırın üstündeki n_sim için de betik indirilebilir.
    - **P3-K3:** Izgara betiği P3'ün dışında.
  - **Kabul ölçütleri E-1…E-12 (Tablo 8.1):**
    - E-1: P1'in 36 koşuluk kümesinde aynı R'de `identical()`.
    - E-2: Tarayıcıdan indirilen 3 betik, proje sahibinin R'sinde sayım farkı 0.
    - E-3: Bütünlük; bir bayt değişince hesap başlamaz.
    - E-4: Bayt eşitliği.
    - E-5: Parametre düzenleme.
    - E-6: Sınır adları.
    - E-7: Giriş kontrolü; sınırın üstündeki n_sim kabul edilir.
    - E-8: Koşu kaydı.
    - E-9: Belirlenimci metin.
    - E-10: `R --vanilla` ile paketsiz; Linux ve Windows.
    - E-11: Gerileme.
    - E-12: CI ızgara adımı.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `belgeler/teknik_notlar/FSR-TN-PLT-03_v0.1.docx`, bu günlük.

## G-72 · FSR-TN-PLT-03 v0.1 onaylandı; P3 uygulaması (T-1…T-5) ve kuru kabul — 18.10.2026

- **Depo:** G-71 commit edildi; Actions geçti.
- **Proje sahibinin kararı (K):** "onaylıyorum" → **KK-51**. FSR-TN-PLT-03 v0.1, Claude'un önerileriyle onaylandı:
  - P3-K1 (b): tek dosya; beş kaynak dosya okunur ham dize olarak gömülü; SHA-256 doğrulaması.
  - P3-K2: Prototipe "R betiği" düğmesi P3'te eklenir.
  - P3-K3: Izgara betiği P3'ün dışında.
  - Tablo 8.1'deki E-1…E-12 donduruldu.
- **T-1 · `CNKfarmastatr/R/platform_export.R` 0.1.0 (yeni; platform katmanı, sabitlenmiş değil; yalnız temel R):**
  - `platform_export_invitro()`:
    - Girdi denetimi `platform_check_invitro(…, Inf, Inf)`; tarayıcı sınırı uygulanmaz.
    - Sabitlenmiş üç dosyanın SHA-256'sı `CEKIRDEK_SHA256.txt` ile aynı değilse betik yazılmaz.
    - Betik baytları UTF-8 ve LF olarak birleştirilir. Paket kaynakları ASCII'dir; Türkçe beyan `\u` kaçışlarıyla yazılır.
  - `platform_motor_dosyalari()` ve `platform_cekirdek_sha()` yardımcıları.
  - SHA-256, `araclar/sha256.R` ile aynı algoritmadır. Kod metin olarak tutulur; pakette ve betikte aynı satırlar çalışır.
- **T-2 · Betik:**
  - Bölümler: başlık, düzenlenebilir `params`, `sinir`/`delta`, `output_dir`, büyüklük bilgisi, program, gömülü dosyalar.
  - Dışa aktarma zamanı tek satırda (`.fsr_created`).
  - Çıktılar: ekran özeti (oran, MCSE, sınıf, metrik, KK-38 etiketi, yakınlık uyarısı), `…_sonuc.csv` (`.num_exact`), `…_kayit.json`.
  - Boyut yaklaşık 58 KB, 1.047 satır.
  - **Denendi:**
    - C ve UTF-8 yerel ayarlarında koşar.
    - CRLF'ye çevrilmiş dosya doğrulamayı geçer.
    - Bir bayt değişince "SHA-256 mismatch in: invitro_fast.R" iletisiyle durur.
    - Latin-1'e çevrilmiş dosyada R ayrıştırıcısı durur; hesap başlamaz.
- **T-3 · Prototip (`web/p1/app.js`, `index.html`, `ceviri.json` 87 anahtar):**
  - "R betiği indir" düğmesi eklendi.
  - webR'e yüklenen dosyalar: `sim_run.R` (sabitlenmiş) ve `platform_hipotez.R`, `platform_export.R` eklendi.
  - Son koşu aynı girdilerle yapıldıysa betiğin başlığına o koşunun kaydı yazılır.
  - Tarayıcıda dışa aktarma 9–12 sn sürüyor, çünkü SHA-256 webR'de temel R ile hesaplanıyor. Gözlem; ölçüt değil.
- **T-4 · Testler ve belgeler:**
  - `tests/testthat/test-platform-export.R` (E-1, E-3…E-9; 89 beklenti).
  - `belgeler/teknik_notlar/FSR-TN-PLT-03_ek/p3_kabul.R` (E-1 tam küme, E-2, E-3, E-4, E-9 webR kısmı, E-10).
  - `web/p1/README.md`: R betiği bölümü (TR/EN).
  - FSR-VAL-SIM-1 v1.1 kapanışta, sonuçlarla birlikte yazılacak.
- **Bulgu (Claude):** FSR-TN-PLT-01 Bölüm 10 P2 satırı "test ve yardım sayfasıyla" diyordu; P1 ve P2'nin platform fonksiyonlarının yardım sayfası yoktu. `man/platform.Rd` dokuz platform fonksiyonunu belgeler. `R CMD check --no-tests` içinde yardım sayfası uyarısı yok; tek uyarı devralınan dosyalardaki ASCII dışı karakterler (önceden vardı).
- **T-5 · CI (`dogrulama.yml`):**
  - Yeni "Step 3: P2 grid checks" adımı: `p2_kabul.R`'yi kendi ortamında koşar, sonuç dosyasını önce siler. 8 satırın hepsi GECTI değilse hata koduyla biter.
  - Başlık güncellendi: 43 blok, 2.068 beklenti.
  - Dosya korumalı; proje sahibi yerleştirecek.
  - **E-12'nin bozma kısmı (Claude, kapsayıcıda kopya üzerinde; depoya girmedi):** normal koşu çıkış 0. Bir δ₀ senaryosunun η'sına 10⁻⁹ eklenince H-4 KALDI ve çıkış 1.
- **Kuru kabul (Claude, kapsayıcı, Linux, R 4.3.3; resmi değil):**
  - testthat: 43 blok, 2.068 beklenti, 0 hata, 0 atlanan. Çekirdek SHA-256 13/13 AYNI.
  - `p3_kabul.R`, tarayıcıda (Playwright, webR 0.5.4) indirilen 3 çiftle:
    - E-1: 36/36.
    - E-2: sayım farkı 0; 150/150 değer K içinde.
    - E-3: 3/3; bağımsız araç digest 5/5.
    - E-4: 5/5.
    - E-9: 3/3.
    - E-10: `R --vanilla`, paket yüklenmedi, sonuç birebir.
    - Hepsi GECTI.
  - E-11: P1 kabul aracı kuru denemede bütün ölçütlerde GECTI. Soğuk açılış en kötü 3,9 sn; 6 × 30 ve 15.000 en kötü 14,6 sn. Bellek elle girilen deneme değeri.
- **Proje sahibinden istenen (resmi koşu):**
  - `dogrulama.yml`'yi yerleştirip commit + push; Actions sonucu E-12 içindir.
  - Prototipte üç koşu (2 × 5, 3 × 10, 6 × 30; n_sim 2.000); her biri için JSON kaydı ve R betiği `FSR-TN-PLT-03_ek/p3/` klasörüne.
  - `p3_kabul.R`'nin sizin R'nizde (Windows) koşulması. Bu E-1, E-2, E-3, E-4, E-9 ve E-10'u Windows'ta sağlar.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `CNKfarmastatr/R/platform_export.R`, `CNKfarmastatr/DESCRIPTION`, `CNKfarmastatr/man/platform.Rd`, `CNKfarmastatr/tests/testthat/test-platform-export.R`, `web/p1/app.js`, `web/p1/index.html`, `web/p1/ceviri.json`, `web/p1/README.md`, `belgeler/teknik_notlar/FSR-TN-PLT-03_ek/p3_kabul.R`, bu günlük. `dogrulama.yml` proje sahibine gönderildi.

## G-73 · CI (G-72 commit'i): Windows'ta S-4 KALDI; neden: yüzde gösteriminde platforma bağlı yuvarlama — 18.10.2026

- **Durum:** G-72 commit edildi (bf2e767); Actions #54 kırmızı. Proje sahibi kayıtları `C:\cloud\CNK-pharmastat-depo\fromGithubToClaude\1` klasörüne koydu; Claude okudu.
- **Sonuçlar:**
  - **Step 1 ve Step 2:** Linux ve Windows'ta geçti (R 4.6.1). 2.068 beklenti, 0 hata, 0 atlanan. P3 testleri (E-1, E-3…E-9) de bunların içinde.
  - **Step 3 (yeni, P2 ızgara kontrolleri):** Linux'ta 8/8 GECTI. Windows'ta 7 GECTI, 1 KALDI: S-4'te "birebir aynı: 3 / 7".
- **Neden (Claude):**
  - `asama2_ozet.R` yüzdeleri `formatC(100 * x, format = "f", digits = 1)` ile yazıyor.
  - Ondalık gösterimi tam yarıda olan değerlerde iki platform farklı yuvarlıyor. Örnek: 0,0485 → 100·x ikili sistemde 4,8500000000000005. Linux 4,9 yazıyor (ikili değere göre doğru); Windows 4,8 yazıyor. Kayıtta görülen satır: "0/0 … 4,9+" (Linux) ve "4,8+" (Windows).
  - Etiket işaretleri (*, +) aynı; fark yalnız sayının son basamağında.
  - Aşama 2 verisinde 6.725 oranın 555'i böyle bir yarım noktada.
- **Kapsam:**
  - S-4'ün dondurulmuş ölçütü etiketler içindir ("H0 hücrelerindeki etiketler … birebir aynı"). `p2_kabul.R` ise satırın tamamını karşılaştırıyor, yani ölçütten katı.
  - Depodaki yayın tabloları Linux'ta üretildi ve ikili değere göre doğru yuvarlanmış.
  - Aynı betik Windows'ta, yarım noktalarda son basamağı farklı bir tablo üretir. Bu, "yayındaki her tablo yeniden üretilebilir" ilkesi için bir bulgudur.
- **Denendi:** Yuvarlamayı önce `round()` ile yapmak çözüm değil. R'nin `round()` kuralı da ikili değere göre yuvarlamıyor (ör. 4,45000000000000018 → 4,4). Linux'ta 7 tablonun 3'ü değişti.
- **Karar bekleyen (Claude'un önerisi):**
  - (1) `p2_kabul.R` 0.2: S-4 ölçütteki gibi yalnız etiketleri karşılaştırır. Sayı metnindeki farklar ayrıca sayılır ve "bilgi" olarak yazılır. Ölçüt değişmez.
  - (2) Gösterim yuvarlamasının platformdan bağımsız kuralı açık madde olarak P5'e (Word raporu) alınır.
- **Dosyalar:** bu günlük.

## G-74 · `p2_kabul.R` 0.2: S-4 ölçütteki gibi etiketleri karşılaştırır (KK-52) — 18.10.2026

- **Proje sahibinin kararı (K):** "onaylıyorum" → **KK-52**. G-73'teki iki öneri kabul edildi:
  - (1) `p2_kabul.R` 0.2: S-4 yalnız KK-38 etiketlerini karşılaştırır. Yüzde metnindeki son basamak farkları sayılır ve bilgi olarak yazılır. Ölçüt değişmedi.
  - (2) Platformdan bağımsız gösterim yuvarlaması P5'te (Word raporu) açık madde.
- **Değişiklik (`belgeler/teknik_notlar/FSR-TN-PLT-02_ek/p2_kabul.R` 0.2):**
  - Her özet tablonun hücreleri tek tek karşılaştırılır.
  - Yüzde hücrelerinde etiket (*, +, yok) birebir aynı olmalı.
  - Sayı farkı en çok 0,1 olabilir (tek son basamak adımı).
  - Yüzde olmayan hücreler birebir aynı olmalı.
  - Aksi durumda KALDI.
  - Satırları da birebir aynı olan tablo sayısı ayrıca raporlanır.
  - Depodaki G-65 sonuç dosyası (`p2_kabul_t1.csv`) kanıt olarak değiştirilmedi; CI kendi kopyasını üretir.
- **Deneme (Claude, kapsayıcıda kopya üzerinde; depoya girmedi):**
  - Normal: GECTI. Etiketler 7/7; satırlar 7/7; bilgi 0.
  - Windows benzetimi, bir hücrede "4,9+" → "4,8+": GECTI. Satırlar 6/7; bilgi 1.
  - Etiket değişimi, "4,9+" → "4,9*": KALDI, çıkış 1.
  - Sayı farkı 0,2, "4,9+" → "5,1+": KALDI, çıkış 1.
- **Açık madde (P5):** Rapor ve ekran yüzdelerinin her platformda aynı yazılması için yuvarlama kuralı (FarmaStatR türetimi) P5 tasarımında belirlenecek. `formatC` ve `round()` ikisi de yarım noktalarda platformdan ya da ondalık gösterimden etkileniyor (G-73).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `belgeler/teknik_notlar/FSR-TN-PLT-02_ek/p2_kabul.R`, bu günlük.

## G-75 · P3 resmi kabulü (Windows): 12/12 GEÇTİ; FSR-TN-PLT-03 v0.2 ve FSR-VAL-SIM-1 v1.1 — 18.10.2026

- **Depo:** G-74 commit edildi. Actions Linux ve Windows'ta yeşil; proje sahibi: "action yeşil ok". Bu, E-12'nin CI kısmıdır.
- **Resmi koşu (proje sahibi; Windows 11, R 4.6.1; tarayıcı webR 0.5.4, R 4.5.1):**
  - Prototipte üç koşu yapıldı: 2 × 5, 3 × 10, 6 × 30; m = 3; δ = FDA δ₀; n_sim = 2.000. Her biri için JSON kaydı ve R betiği `FSR-TN-PLT-03_ek/p3/` klasörüne kondu. Claude betik başlıklarında ayarları doğruladı.
  - `p3_kabul.R` sonuçları:
    - E-1: 36/36 `identical()`.
    - E-2: 3 çift; sayım farkı 0; 150/150 değer K içinde.
    - E-3: 3/3; bağımsız araç `tools::sha256sum` 5/5.
    - E-4: 5/5.
    - E-9: 3/3.
    - E-10: `R --vanilla`, paket yüklenmedi ve kurulu değil; sonuç 17 basamakta aynı.
    - Genel: GECTI.
  - Çıktılar: `p3_kabul.csv`, `p3_yerel_sessionInfo.txt`.
- **Teknik not FSR-TN-PLT-03 v0.2** (7 sayfa):
  - KK-51 kararları ilgili bölümlere işlendi.
  - Uygulanan biçim yazıldı.
  - Tablo 9.1: E-1…E-12, 12/12 GEÇTİ.
  - Tablo 10.1:
    - B-1: Yardım sayfası eksikliği; `man/platform.Rd` ile kapandı.
    - B-2: Yüzde yuvarlaması; KK-52 ile kapandı.
    - A-1: Gösterim yuvarlaması, P5'te.
    - A-2: FSR-VAL-SIM-1 v1.1.
    - A-3: Bağımsız tekrar ve mekanizma verileri; P4'ten önce.
    - A-4: Tarayıcıda betik üretim süresi.
  - P3 kapanışı onaya sunuldu.
- **FSR-VAL-SIM-1 v1.1** (9 sayfa; revizyon, onay bekliyor):
  - TC-S11 eklendi: dışa aktarılan in vitro betiği, 89 beklenti.
  - Tablo 7.1'e 1.1 satırları eklendi; yeni Bölüm 7.6 (P3 kabul sonuçları).
  - Bölüm 9'da webR maddesi güncellendi. Motor koşusu P1 ve P3'te tarayıcıda yapıldı; testthat kümesinin webR'de koşulması açık kalır.
  - Sabitlenmiş 13 dosya değişmedi.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `belgeler/teknik_notlar/FSR-TN-PLT-03_v0.2.docx`, `belgeler/validasyon/FSR-VAL-SIM-1_v1.1.docx`, bu günlük. Kabul çıktıları ve `p3/` dosyaları proje sahibinin klasöründe; commit edilecek.

## G-76 · P3 kapandı (KK-53) — 18.10.2026

- **Depo:** G-75 commit edildi. Actions Linux ve Windows'ta yeşil; proje sahibi: "action yeşil geçti". Kabul çıktıları (`p3_kabul.csv`, `p3_yerel_sessionInfo.txt`, `p3/`) depoda.
- **Proje sahibinin kararı (K):** "p3'ü onaylıyorum" → **KK-53**. Claude bunu G-75'teki soruya ("FSR-TN-PLT-03 v0.2'yi ve FSR-VAL-SIM-1 v1.1'i onaylayıp P3'ü kapatıyor musunuz?") verilen onay olarak işledi:
  - FSR-TN-PLT-03 v0.2 onaylandı; 12/12 GEÇTİ; **P3 kapandı**.
  - FSR-VAL-SIM-1 v1.1 (TC-S11) onaylandı.
- **Künyeler:** İki belgenin künyesinde "onay bekliyor" yazıyor. Onay bu girdi ve KK-53 ile kayıtlıdır; künyeler bir sonraki revizyonda düzeltilir.
- **Taşınan açık maddeler:**
  - Gösterim yuvarlaması (P5; KK-52).
  - Bağımsız tekrar ve mekanizma verilerinin veri tabanına alınması (P4'ten önce; KK-50).
  - Tarayıcıda betik üretim süresi (P4).
  - testthat kümesinin webR'de koşulması (FSR-VAL-SIM-1 Bölüm 9).
- **Sıradaki iş:** P4, sınıflandırmanın ekranda gösterilmesi. İlk adım FSR-TN-PLT-04 v0.1: tasarım ve kabul ölçütleri, kod yazılmadan önce (KK-45 ilkesi).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** bu günlük.

## G-77 · P4 tasarımı: FSR-TN-PLT-04 v0.1 (taslak) — 18.10.2026

- **Depo:** G-76 commit edildi; Actions yeşil. Proje sahibi: "başla".
- **Ön deneme (Claude, kapsayıcı) — gösterim yuvarlaması:**
  - Linux R (glibc `formatC`) ikili değere en yakını seçer; tam eşitlikte çift rakama yuvarlar (C99).
  - JavaScript `toFixed()` da ikili değere en yakını seçer, ama tam eşitlikte büyüğü alır (ECMA-262). Izgaradaki 6.525 yüzde değerinin 43'ünde Linux R'den farklı yazıyor (ör. 0,125 → 0,13).
  - BigInt ile tam eşitlik denetimi yapan JavaScript taslağı 6.525 değerin hepsinde Linux R ile aynı yazdı (fark 0). Uç değerler de aynı: 0,125 → 0,12; 2,25 → 2,2; 100 · 0,0485 → 4,9.
  - İlk taslakta `x · 10^f` çarpımıyla yapılan eşitlik denetimi yanlış eşitlik buluyordu (184 fark), çünkü çarpım yuvarlanıyor. Bu yüzden BigInt'e geçildi.
- **Teknik not FSR-TN-PLT-04 v0.1** (5 sayfa; onay bekliyor):
  - **Teslimatlar:**
    - T-1: Veri tabanına bağımsız tekrar ve mekanizma tabloları; tarayıcı doğrulaması için `VT_SHA256.txt` (KK-50, A-3).
    - T-2: Ekran `web/app/`. Girdi grupları A/B/C, sınıflandırılmış sonuç, uyarılar, alt düğmeler. P1 sayfası değişmez.
    - T-3: Katman seçimi ve sql.js ile hazır sonuç. Anahtar JavaScript'te kurulur; veri tabanı SHA-256 ile denetlenir.
    - T-4: Grafikler.
    - T-5: Bağlantı ve sayı gösterimi.
    - T-6: Testler ve kabul aracı.
  - **Karar bekleyen (Claude'un önerileri):**
    - **P4-K1:** Hazır sonuçta birleşik koşu varsa o, yoksa ana koşu.
    - **P4-K2:** G1 (sonuç ± z·MCSE) ve G2 (ızgara bağlamı) P4'te.
    - **P4-K3:** Tek JavaScript biçimlendirme fonksiyonu. Kural: ikili değere en yakın, tam eşitlikte çift. Oran 1, MCSE 2 ondalık.
  - **Kabul ölçütleri U-1…U-12 (Tablo 9.1):**
    - Sınıf, metrik ve etiket; sayılar.
    - Hazır katman: 1.085 anahtar ve 8 senaryo; webR başlatılmadan.
    - Katman seçimi; bağlantı; TR/EN; grafikler; uyarılar.
    - Önceden bilgi ve iptal.
    - Veri tabanı; gerileme; dar ekran.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `belgeler/teknik_notlar/FSR-TN-PLT-04_v0.1.docx`, bu günlük.

## G-78 · FSR-TN-PLT-04 v0.1 onaylandı (KK-54); P4 T-1: veri tabanı sürüm 2 — 18.10.2026

- **Depo:** G-77 commit edildi.
- **Proje sahibinin kararı (K):** "onaylıyorum" → **KK-54**. FSR-TN-PLT-04 v0.1, Claude'un önerileriyle onaylandı:
  - P4-K1: Hazır sonuçta birleşik koşu varsa o, yoksa ana koşu.
  - P4-K2: G1 ve G2 grafikleri P4'te.
  - P4-K3: Tek JavaScript biçimlendirme fonksiyonu. Kural: ikili değere en yakın, tam eşitlikte çift. Oran 1, MCSE 2 ondalık.
  - Tablo 9.1'deki U-1…U-12 donduruldu.
- **T-1 · `araclar/vt_insa.R` (veri tabanı sürüm 2):**
  - **Yeni tablolar:**
    - `bagimsiz_tekrar`: 48 satır. Senaryo, yöntem, Aşama 1 ve tekrar oranları, MCSE'leri, z.
    - `mekanizma`: 12 satır, 28 sütun.
  - **Yeni koşu satırları:** `PBE01-A1-BT` (tür "tekrar") ve `PBE01-MEK` (tür "deney").
  - **Bağımsız tekrarın koşu kaydı dosyası yok:**
    - Seed 20261019, n_sim 40.000 ve RNG betikten alındı (`bagimsiz_tekrar.R`). `invitro_scenario` RNG türünü sabitler.
    - R, paket ve motor sürümü türetildi: koşu Aşama 2 ile aynı gün ve aynı ortamda yapıldı (`asama2_kayit.csv`, G-41).
    - Türetme açıklama alanına yazıldı; `vt_insa.R` başlığında da var.
  - `veri/VT_SHA256.txt` artık veri tabanı dosyasının SHA-256'sını taşıyor; tarayıcı bununla denetleyecek.
  - Dosya SHA-256'sı için hızlı yol eklendi: önce `tools::sha256sum` (R ≥ 4.5), yoksa `digest`, o da yoksa temel R. Değerler aynı. Temel R 2,2 MB'lık dosyada yaklaşık 2 dk sürüyordu.
- **Sonuç:** 2,25 MB. 1.085 senaryo, 8 koşu, 13.555 sonuç, 3.679 fark, 4.340 hipotez, 48 bağımsız tekrar, 12 mekanizma. Dosya SHA-256 `c8832cd3…`.
- **U-10 (kuru koşu, Claude; `FSR-TN-PLT-04_ek/p4_kabul_vt.R` → `p4_kabul_vt.csv`):**
  - (a) Yeni tablolar CSV ile birebir; koşu satırlarında sürüm alanları dolu.
  - (b) İki inşanın döküm SHA-256'sı aynı (16 tablo).
  - (c) sql.js 1.12.0 (Node) ile okunan değerler R ile birebir.
  - (d) `VT_SHA256.txt` dosyayla aynı.
  - Hepsi GECTI. U-10'un tarayıcıdaki sql.js okuması kabul sayfasında yapılacak.
- **Gerileme (kopya üzerinde):** P2'nin veri tabanı kontrolleri (`p2_kabul_vt.R`; S-6a…g, S-7, S-8, S-9) yeni veri tabanında GECTI. S-9: 8 koşu, 6 tek/ek, motor SHA-256 6/6 dolu. P2'nin depodaki kanıt dosyaları değiştirilmedi.
- **Sıradaki iş:** T-2…T-5, ekran (`web/app/`).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `araclar/vt_insa.R`, `veri/farmastatr_v1.sqlite`, `veri/VT_SHA256.txt`, `belgeler/teknik_notlar/FSR-TN-PLT-04_ek/p4_kabul_vt.R`, `vt_oku_p4.mjs`, `p4_kabul_vt.csv`, bu günlük.

## G-79 · P4 T-2…T-5: ekranın geliştirme sürümü (`web/app/`) — 18.10.2026

- **Depo:** G-78 commit edildi; Actions yeşil ("action ok başarılı").
- **Yeni dosyalar (`web/app/`, P1'in `motor.js`'ini paylaşır):**
  - **`bicim.js`:**
    - Gösterim kuralı (P4-K3): ikili değere en yakın, tam eşitlikte çift. BigInt ile tam eşitlik denetimi yapar.
    - Kanonik anahtar: R'deki `.num_exact` ile aynı `%.15g/16g/17g` metni; eşitlikte çifte yuvarlar.
  - **`hazir.js`:** sql.js 1.12.0. Veri tabanını `VT_SHA256.txt` ile doğrular. Senaryo, sonuç, hipotez, koşu ve G2 komşularını okur. P4-K1: birleşik koşu varsa o.
  - **`grafik.js`:** G1 ve G2, satır içi SVG. Her işaretin değeri `data-value` özniteliğinde.
  - **`app.js`:**
    - Katman seçimi. webR yalnız gerektiğinde başlar; ızgaradaki senaryoda hiç başlamaz.
    - Koşudan önce hipotez durumu R'den alınır (`platform_hipotez`). Canlı koşu `platform_run_invitro` ve `platform_kk38` ile.
    - Uyarılar, bağlantı ve sürüm kontrolü, JSON kaydı, R betiği, iptal.
  - **Diğer:** `index.html`, `stil.css`, `ceviri.json` (151 anahtar, TR = EN), `README.md`.
- **Denemeler (Claude, kapsayıcı, Node ve Playwright; resmi kabul değil):**
  - **JavaScript–R uyumu:**
    - JavaScript anahtarı, ızgaradaki 1.085 senaryonun hepsinde R anahtarıyla aynı.
    - Biçimlendirme, 6.525 yüzde değerinde Linux R ile aynı.
    - `numExact`, 6.012 sayının 6.011'inde R ile aynı.
  - **Ekran (Playwright):**
    - Hazır senaryo 0,7 sn'de göründü; webR başlatılmadı.
    - Birleşik koşulu senaryoda gösterilen koşu PBE01-A2-BIR (n = 50.000).
    - Izgara dışı senaryo canlı koşuldu; hipotez durumu koşudan önce göründü.
    - Bağlantı yeni sekmede aynı anahtarı verdi.
    - Farklı sürüm etiketli bağlantı onaya kadar bir şey göstermedi.
    - Bir baytı değiştirilmiş veri tabanında hazır katman kapandı ve uyarı göründü.
    - 6 × 30 ve 50.000'de koşu reddedildi, betik önerildi; betik ekrandan indirildi.
    - İptal 36 ms'de durdu.
    - 375 piksel genişlikte yatay kaydırma yok (ilk denemedeki taşma CSS'de düzeltildi).
- **Bulgu (Claude):** R'nin sayı ayrıştırıcısı (`as.numeric`) her zaman doğru yuvarlamıyor. Örnek: "140573413.3919404" komşu double'a okunuyor; bu yüzden `.num_exact` bu sayı için 17 basamak yazıyor, JavaScript 16 basamak yazıyor. Etkisi yalnız böyle bir değer girildiğinde hazır katmanın kaçmasıdır; sonuç yanlış olmaz. Izgarada fark 0.
- **Sıradaki iş:** T-6 (kabul sayfası `web/app/kabul.html`, `p4_kabul.R`, testthat), ardından resmi kabul (U-1…U-12) ve FSR-TN-PLT-04 v0.2.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `web/app/` altındaki 8 dosya, bu günlük.

## G-80 · P4 T-6: kabul araçları; kuru kabul U-1…U-12 GECTI — 18–20.10.2026

- **Depo:** G-79 commit edildi ("commit tamam"). Oturum 18.10 akşamı yarıda kaldı, 20.10'da devam edildi.
- **T-6 · yeni dosyalar:**
  - **`web/app/kabul.html`, `kabul.js`:** Ekranı aynı kökenli bir çerçevede sürer; DOM'u ve `window.__p4`'ü okur. İndirilenler: `p4_tarayici.csv` ve `p4_betik.R`.
    - Senaryo kümesi Tablo 9.1'deki gibi: 16 + 1 canlı (TR ve EN) ve 8 hazır. Hazır senaryolar: `senaryo_no` 1, 2, 67, 257, 258, 259, 260, 480. Her sınıftan, iki aşamadan, biri birleşik koşulu.
    - Ek denetimler: δ₀ tanımsız, bağlantı ve sürüm farkı, bozuk veri tabanı, katmanlar, R betiği, iptal, dar ekran.
  - **`belgeler/teknik_notlar/FSR-TN-PLT-04_ek/p4_kabul.R`:** Tarayıcı çıktısını yerel R ve veri tabanıyla karşılaştırır. Canlı değerler sayım düzeyinde ve K(10⁻¹², 10⁻¹²) içinde karşılaştırılır. Sonuç `p4_kabul.csv` ve `p4_yerel_sessionInfo.txt`.
  - **`p4_bicim_referans.R` ve `p4_bicim_referans.csv`:** Veri tabanındaki 11.385 oran ve MCSE için Linux R `formatC` metinleri ve 17 basamaklı değerleri. Yalnız Linux'ta üretilir (G-73).
  - **`CNKfarmastatr/tests/testthat/test-platform-bicim.R`:**
    - Linux'ta başvuru dosyasını yeniden üretir; tam eşitlik vakaları da var.
    - Windows'ta yalnız dosyanın varlığını denetler. Atlama değil, çünkü CI atlanan testte başarısız sayar.
  - `web/app/app.js`: kabul aracı için `state.key`. `web/app/README.md`: kabul adımları.
  - `dogrulama.yml`: başlık 44 blok, 2.074 beklenti (Windows 2.069). Korumalı dosya; proje sahibi yerleştirecek.
- **Kuru kabul (Claude, kapsayıcı; Playwright, webR 0.5.4; yerel R 4.3.3):**
  - **Genel GECTI.**
  - U-1: canlı 64/64 ve hazır 32/32 yöntem satırı R ile aynı; metinler TR ve EN çeviriyle aynı.
  - U-2: başvuruyla fark 0 (11.385); canlı değerler 64/64.
  - U-3: anahtar fark 0 (1.085). Hazırda 48/48 aynı; webR başlamadı; bozuk veri tabanında katman kapandı.
  - U-4: katmanlar doğru.
  - U-5: 16 bağlantı aynı sonucu verdi; farklı sürümde onaysız sonuç yok.
  - U-6: çeviri anahtarları 151 = 151; çevirisiz metin 0.
  - U-7: G2 156/156 veri tabanıyla aynı.
  - U-8: uyarılar 40/40; δ₀ tanımsız 2 senaryoda koşu yok ve uyarı var.
  - U-9: iptal 1 ms.
  - U-10: 4/4.
  - U-11: betik E-9 kuralıyla aynı; SHA-256 13/13.
  - U-12: yatay taşma yok.
  - Tam test kümesi: 44 blok, 2.074 beklenti, 0 hata, 0 atlanan.
- **Kuru koşuda düzeltilen kabul aracı hataları (Claude):**
  - Senaryo kümesindeki σR 0,12, ρ 1,8, FDA δ₀ için δ₀ tanımsız (η, δ = 0'da pozitif). Araç bu durumda koşu beklerken zaman aşımına düşüyordu. Tablo 9.1 bunu öngörür ("δ₀ tanımsız olanlar uyarıyla"); araç bu senaryoyu artık U-8 olarak işliyor.
  - "seed" gibi çevirisi anahtarıyla aynı olan metinler yanlışlıkla eksik çeviri sayılıyordu.
  - R'nin `read.csv` fonksiyonu "NA" metnini eksik değere çeviriyordu (`na.strings = character(0)`).
  - Adlandırılmış vektör karşılaştırmasında `identical()` yerine değer karşılaştırması kullanıldı.
- **Proje sahibinden istenen (resmi koşu):**
  - `dogrulama.yml`'yi yerleştirip commit + push.
  - Kabul sayfasını kendi Chrome'unda koşmak; iki dosyayı `FSR-TN-PLT-04_ek/p4/` klasörüne koymak.
  - `p4_kabul.R`'yi koşmak.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** yukarıdakiler ve bu günlük.

## G-81 · P4 resmi kabul: U-1…U-12 GECTI; FSR-TN-PLT-04 v0.2 (taslak) — 20.10.2026

- **Resmi koşu (proje sahibi, 20.10.2026):**
  - Ortam: Windows 11 x64 (build 26300), Chrome 155, yerel R 4.4.1 (ucrt). Kabul sayfası yaklaşık 90 s sürdü.
  - `p4_kabul.R` sonucu: **U-1…U-12 GECTI (12/12), Genel GECTI.**
  - RSQLite ve DBI'nin eski R sürümüyle derlendiği uyarıları sonucu etkilemez.
- **Depoya alınan çıktılar (proje sahibinin dosyaları; bayt bayt):**
  - `belgeler/teknik_notlar/FSR-TN-PLT-04_ek/p4/p4_tarayici.csv` ve `p4_betik.R`.
  - `p4_kabul.csv` ve `p4_yerel_sessionInfo.txt`.
- **Teknik not FSR-TN-PLT-04 v0.2** (6 sayfa; onay bekliyor):
  - KK-54 kararları ilgili bölümlere işlendi.
  - Bölüm 10: resmi sonuçlar (Tablo 10.1; 12/12).
  - Bölüm 11: bulgular B-1…B-4 ve açık maddeler A-1…A-3 (A-1: Word raporunda aynı gösterim kuralı, P5; A-2: tarayıcı üretim süresi; A-3: testthat kümesinin webR'de koşulması, P6).
  - Bölüm 12: proje sahibinden istenen karar (P4'ün kapatılması).
  - U-11'deki CI sonucu: G-80 commit'inin Actions sonucu proje sahibince bildirilecek.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `belgeler/teknik_notlar/FSR-TN-PLT-04_v0.2.docx`, bu günlük.
- **Sıradaki iş:** proje sahibinin v0.2 onayı ile P4'ün kapanışı; ardından P5 (Word raporu).

## G-82 · P4 kapandı (KK-55) — 20.10.2026

- **Depo:** G-81 commit edildi. Actions başarılı; proje sahibi: "actions başarılı. ok." Böylece FSR-TN-PLT-04 v0.2 Tablo 10.1'deki U-11'in CI kısmı da sağlandı. Resmi kabul çıktıları (`p4/`, `p4_kabul.csv`, `p4_yerel_sessionInfo.txt`) depoda.
- **Proje sahibinin kararı (K):** "Onaylıyorum kapatıyorum" → **KK-55**. Claude bunu G-81'deki soruya ("FSR-TN-PLT-04 v0.2'yi onaylayıp P4'ü kapatıyor musunuz?") verilen onay olarak işledi:
  - FSR-TN-PLT-04 v0.2 onaylandı; U-1…U-12 GECTI (12/12).
  - **P4 kapandı.**
- **Künye:** Belgenin künyesinde "taslak" ve "onay bekliyor" yazıyor. Onay bu girdi ve KK-55 ile kayıtlıdır; künye bir sonraki revizyonda düzeltilir (G-76'daki uygulama).
- **Sonraki aşamalara taşınan açık maddeler (FSR-TN-PLT-04 v0.2 Bölüm 11):**
  - A-1: Word raporunda ekrandaki gösterim kuralı (P4-K3) Windows dahil aynı olmalı. R tarafında aynı kuralı uygulayan biçimlendirici gerekir (P5; KK-52 açık maddesi).
  - A-2: Tarayıcıda betik üretim süresi 9–12 sn (P3 A-4); değişmedi.
  - A-3: testthat kümesinin webR'de koşulması (P6; FSR-VAL-SIM-1 Bölüm 9).
- **Sıradaki iş:** P5, Word (.docx) raporu. İlk adım FSR-TN-PLT-05 v0.1: tasarım ve kabul ölçütleri, kod yazılmadan önce (KK-45 ilkesi).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** bu günlük.

## G-83 · Tanıtım belgesi; P5 tasarımı: FSR-TN-PLT-05 v0.1 (taslak) — 20.10.2026

- **Depo:** G-82 commit edildi; Actions başarılı ("action ok").
- **Tanıtım belgesi (proje sahibinin isteği):** "P5'e kadar ne yaptık", projeyi bilmeyen eczacılık 2. sınıf öğrencisine anlatır gibi. Önce yanıt olarak yazıldı, sonra istek üzerine claude.ai'de bir Docs belgesine dönüştürüldü ("CNK-FarmaStatR: P5'e kadar ne yaptık?"; 11 bölüm, hesap katmanları akış şeması, küçük sözlük). Depoya girmedi. Belgede açık soru: İngilizce sürüm eklenecek mi.
- **Ön deneme (Claude, kapsayıcı) — Word yazıcı:**
  - Kütüphanesiz, yaklaşık 90 satırlık JavaScript yazıcı: sıkıştırmasız ZIP, CRC-32 ve altı OOXML parçası.
  - Türkçe karakterli, başlık satırı yinelenen tablolu ve üst bilgili 5,8 KB'lık .docx üretti. `unzip -t` hatasız; python-docx ve LibreOffice metni, tablo hücrelerini ve üst bilgiyi birebir okudu.
  - Microsoft Word'de açılış denenmedi; kabulde proje sahibi sınayacak.
  - Karşılaştırma: docx 9.13.0 kütüphanesi (npm) açılmış hâliyle 20 MB.
- **Teknik not FSR-TN-PLT-05 v0.1** (4 sayfa; onay bekliyor):
  - Dayanak: FSR-TN-PLT-01 v0.6 Bölüm 8 ve Tablo 8.1 (rapor içeriği ve sorumluluklar), Tablo 10.1 P5 satırı; FSR-TN-PLT-04 v0.2 A-1.
  - Teslimatlar T-1…T-5: rapor içeriği (Tablo 3.1, 10 bölüm), `web/app/rapor.js`, rapor düğmesi, çeviri ve belgeler, kabul aracı. R çekirdeği ve sabit 13 dosya değişmez.
  - Yöntem kaynakları önerisi (Tablo 3.2): FDA PSG 020929 Ek Adım 1–4; EMA CPMP/EWP/4151/00 Rev. 2 Bölüm 5.1; EMA (c) serbestlik derecesi FarmaStatR türetimi; ADEMP (Morris ve ark. 2019).
  - Kararlar (Tablo 4.1; öneri hepsinde (a)):
    - P5-K1 sayı biçimi: ekrandaki `bicim.js` Word'de de kullanılır; FSR-TN-PLT-01 Tablo 8.1'in biçim satırı "R (tercih)"den JavaScript'e revize edilir; A-1 kapanır.
    - P5-K2 DOCX üretimi: kendi küçük yazıcı, kütüphane yok.
    - P5-K3 rapor dili: ekranın dili; beyan iki dilde.
    - P5-K4 grafik: P5'te yok.
  - Belirlenimcilik (FarmaStatR türetimi): ZIP tarihleri sabit; aynı sonuçtan iki rapor, oluşturma zamanı satırı dışında bayt bayt aynı.
  - Kabul yöntemi: P4 kümesi (8 hazır + 17 canlı; TR ve EN); raporlar tek ZIP'te; `p5_kabul.R` raporları R `unzip` ile bağımsız okur; R = ekran = Word üçlü karşılaştırması.
  - Kabul ölçütleri R-1…R-11 (Tablo 7.1): içerik, sayılar, etiketler, beyan, geçerli belge (Word'de açılış dahil), yeniden üretim, belirlenimcilik, gizlilik, düğme durumu, süre ≤ 2 sn, gerileme.
  - Katman 3 (R betiği) için rapor kapsam dışı.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `belgeler/teknik_notlar/FSR-TN-PLT-05_v0.1.docx`, bu günlük.
- **Sıradaki iş:** proje sahibinin P5-K1…P5-K4 kararları ve R-1…R-11'in dondurulması; ardından uygulama.

## G-84 · P5 kapsamı genişledi: tasarım seçimi (KK-56); FSR-TN-PLT-05 v0.2 (taslak) — 20.10.2026

- **Proje sahibinin hatırlatması (K):** "Benim simülasyondaki asıl amacım istatistiksel gücün hedeflenen düzeyde olması için ℓ, n ve gerektiğinde m değerlerinin seçimini optimum düzeyde yapabilmek; parametrelerin değişik değerlerine göre kurgulanan denemelerde gücü öngörebilmek." FSR-TN-PLT-05 v0.1 buna değinmiyordu.
- **Claude'un tespiti:**
  - Amaç FSR-TN-PBE-01 Bölüm 1'de yazılı (KK-23, KK-28); yanıtı Bölüm 11.5'te (Tablo 11.3a ve 11.3b).
  - Platform P4'e kadar yalnız tek tasarımın sonucunu gösteriyordu; "hedef güç için hangi ℓ × n" sorusunu doğrudan yanıtlamıyordu.
  - Bu eksik P0'daki platform tasarımında (FSR-TN-PLT-01) da vardı; v0.1'de Claude'un atladığı bir noktadır.
- **Proje sahibinin kararı (K):** "P5'te ikisini de yapalım" → **KK-56**. P5 = tasarım seçimi + Word raporu; aşama numaraları değişmez. G-83 olduğu gibi commit edilecek (v0.1 taslak olarak kayıtta kalır).
- **Teknik not FSR-TN-PLT-05 v0.2** (6 sayfa; onay bekliyor):
  - Yeni Bölüm 3 (tasarım seçimi):
    - Girdiler: popülasyon, güç için gerçek fark (GMR 1,05 varsayılan), hedef güç (%80 varsayılan), aday küme (ℓ 2–6 × n 5–30, m tek ya da liste), n_sim 10.000, seed 20261015.
    - Tip I hata her yöntemin kendi sınırında: FDA δ₀, EMA 1,18 (`asama1_tablo113.R` ile aynı).
    - Sınıf önce gelir: H1 olmayan hücrede güç seçimi yapılmaz.
    - Kural A = Tablo 11.3a (yalnız güç; en küçük ℓ·n, eşitlikte küçük ℓ). Kural B = Tablo 11.3b (ℓ ≥ 3, n ≥ 10, tip I hata "nominali aşıyor" değil; yoksa "yok"). m sırası FarmaStatR türetimi.
    - Eşiğe yakınlık işareti: KK-39.
    - Katmanlar: hazır (bütün adaylar veri tabanında ise), canlı (sınır içinde), betik (aday küme betiği; P3-K3'ün dışarıda bıraktığı ızgara betiği).
    - Ortak seed sayesinde canlı = hazır sayım düzeyinde.
  - Yeni teslimatlar: `platform_tasarim()` (R), tasarım sekmesi (`tasarim.js`), tasarım betiği.
  - Yeni kararlar (öneri hepsinde (a)):
    - P5-K5: Kural A ve B birlikte; önerilen tasarım B'ninki.
    - P5-K6: canlı sınırı toplam ≤ 6 × 10⁷ hücre, ölçümle kesinleşir.
    - P5-K7: tablo ya tümüyle hazır ya tümüyle canlı.
  - Rapor (Tablo 4.1) tasarım seçimi raporunu da kapsar.
  - Kabul ölçütleri: D-1…D-7 (D-1: Aşama 1'in üç p_B değerinde Tablo 11.3a ve 11.3b'nin `asama1_tablo113.csv` ile hücre hücre yeniden üretimi) ve R-1…R-11.
  - Hız tahmini: Aşama 1'in tam aday kümesi canlıda yaklaşık 1,6 × 10⁸ hücre, 4–5 dk (P1 ölçümünden; FarmaStatR türetimi).
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `belgeler/teknik_notlar/FSR-TN-PLT-05_v0.2.docx`, bu günlük.
- **Sıradaki iş:** proje sahibinin P5-K1…P5-K7 kararları ve D-1…D-7, R-1…R-11'in dondurulması. Onaydan sonra FSR-TN-PLT-01 Tablo 8.1 (P5-K1) ve Tablo 10.1 (P5 satırı) revize edilir.

## G-85 · FSR-TN-PLT-05 v0.2 onaylandı (KK-57); P5 uygulaması başlıyor — 20.10.2026

- **Depo:** G-83 commit edildi (proje sahibi). G-84 ve bu girdi tek commit'le gönderilecek.
- **Proje sahibinin kararı (K):** "onaylıyorum" → **KK-57**. Claude bunu G-84'teki soruya ("P5-K1…P5-K7 için önerdiğim (a) seçeneklerini ve 18 kabul ölçütünü onaylıyor musunuz?") verilen onay olarak işledi:
  - P5-K1 (a): sayılar ekranda ve Word'de aynı JavaScript fonksiyonuyla (`bicim.js`, P4-K3 kuralı). FSR-TN-PLT-01 Tablo 8.1'in biçim satırı revize edilecek; FSR-TN-PLT-04 A-1 bu kararla kapanır.
  - P5-K2 (a): kendi küçük DOCX yazıcı, kütüphane yok.
  - P5-K3 (a): rapor ekranın dilinde; beyan iki dilde.
  - P5-K4 (a): P5'te raporda grafik yok.
  - P5-K5 (a): Kural A ve B birlikte; önerilen tasarım Kural B'ninki.
  - P5-K6 (a): canlı sınırı toplam ≤ 6 × 10⁷ hücre; P5'te ölçümle kesinleşir.
  - P5-K7 (a): tablo ya tümüyle hazır ya tümüyle canlı.
  - Tablo 3.2'deki yöntem kaynakları metni onaylandı.
  - Kabul ölçütleri D-1…D-7 ve R-1…R-11 donduruldu (FSR-TN-PLT-05 v0.2 Tablo 8.1).
- **Künye:** Belgenin künyesinde "onay bekliyor" yazıyor; onay bu girdi ve KK-57 ile kayıtlıdır, künye v0.3'te düzeltilir.
- **Bekleyen belge işi:** FSR-TN-PLT-01 v0.7: Tablo 8.1 (P5-K1) ve Tablo 10.1 P5 satırı (KK-56). Uygulamayla birlikte yapılacak.
- **Sıradaki iş:** P5 uygulaması. İlk adım T-1: `platform_tasarim()` (R) ve testleri.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** bu günlük.

## G-86 · P5 T-1: `platform_tasarim()`; D-1 (Tablo 11.3a ve 11.3b) yeniden üretildi — 20.10.2026

- **Depo:** G-84 ve G-85 commit edildi; Actions başarılı ("action tamam").
- **T-1 · yeni dosyalar (R paketi):**
  - **`R/platform_tasarim.R` 0.1.0:** FSR-TN-PLT-05 v0.2 Bölüm 3'ün uygulaması. Temel R; motoru yalnız `platform_run_invitro()` ile çağırır, istatistik hesaplamaz.
    - `platform_tasarim_plan()`: aday tasarımlar (ℓ × n × m) ve üç gerçek fark (güç farkı, FDA δ₀, EMA 1,18) için koşu planı. Aynı tasarım ve δ'daki roller tek koşuyu paylaşır (ortak seed). Her koşuya kanonik anahtar; her koşu `platform_check_invitro()` denetiminden geçer (KK-47). FDA δ₀ tanımsızsa FDA tip I koşuları planlanmaz, not düşülür. Toplam iş sınırı 6 × 10⁷ hücre (P5-K6), aşılınca `design_size` kodu.
    - `platform_tasarim_secim()`: Kural A ve B (`asama1_tablo113.R` ile aynı sıralama: toplam, sonra küçük ℓ, sonra küçük m). Sınıf H1 değilse seçim yok (`sinif_h1_degil`). Eşiğe yakınlık |güç − hedef| < 2 MCSE (KK-39). Kural B'de "yok" nedeni: `guc_yetersiz`, `tip1_kalibrasyon` ya da `tip1_hesaplanamadi`.
    - `platform_tasarim_params()`, `platform_tasarim()` (planla, koş, seç; yerel R ve betik için).
  - **`man/platform_tasarim.Rd`**, **`DESCRIPTION`** (Collate'e `platform_tasarim.R`).
  - **`tests/testthat/test-platform-tasarim.R`** (5 blok, 154 beklenti):
    - Plan: 30 tasarımda 90 koşu; anahtarlar; toplam iş; Aşama 1'in tam kümesi canlı sınırının üstünde; paylaşılan koşu.
    - Girdi hataları kodlarıyla; FDA δ₀ tanımsız.
    - **D-1:** Aşama 1 sonuçlarından (`asama1_sonuc.csv`) Kural A ve B, `asama1_tablo113.csv`'nin 24 hücresini birebir üretti: tasarım, güç ve MCSE'si, tip I hata ve MCSE'si, KK-38 etiketi, "yok" hücreleri dahil.
    - Kurallar: eşitlikte küçük ℓ, eşiğe yakınlık, tip I hata aşımının yalnız Kural B'yi etkilemesi, H1 olmayan sınıf.
    - **D-3 (R tarafı):** 2 × 5 tasarımında canlı koşu, ortak seed ile Aşama 1 sayımlarını birebir verdi.
- **Sonuçlar (Claude, kapsayıcı; R 4.3.3, NOT_CRAN = true):** test kümesi 49 blok, 2.228 beklenti, 0 hata, 0 atlanan (Windows'ta beklenen 2.223; biçim testi Windows'ta 1 beklenti). Çekirdek SHA-256 13/13 AYNI. Sabit dosyalar değişmedi.
- **`dogrulama.yml`:** yalnız başlık yorumu (49 blok, 2.228 beklenti; Windows 2.223). Korumalı dosya; proje sahibi isterse yerleştirir, işleyişi değişmedi.
- **Uygulama notu (v0.3'e):** hazır katmanda seçim kurallarını da R uygular; bu yüzden tasarım seçiminde hazır sonuç için webR açılır (sayılar veri tabanından). Arayüz hesap yapmaz ilkesi korunur; "anında" ifadesi webR başlangıç süresi kadar gecikir.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** yukarıdakiler (`dogrulama.yml` hariç; proje sahibine gönderildi) ve bu günlük.
- **Sıradaki iş:** T-2, tasarım seçimi sekmesi (`web/app/tasarim.js`).

## G-87 · P5 T-2: tasarım seçimi sekmesi — 20.10.2026

- **Depo:** G-86 commit edildi; `dogrulama.yml` yerleştirildi; Actions başarılı.
- **T-2 · ekran (`web/app/`):**
  - **Yeni sekme "Tasarım seçimi (hedef güç)"** (`tasarim.js`, yeni; `index.html`, `stil.css`, `ceviri.json` +57 anahtar, TR = EN = 208; `README.md`).
  - Girdiler: popülasyon; güç için gerçek fark (GMR 1,05 varsayılan, GMR 1,00, özel GMR ya da δ); hedef güç (%80); aday ℓ, n, m listeleri; nsim ve seed. Bilgi satırı: aday tasarım sayısı, toplam iş, tahmini süre.
  - **R yapar, sayfa göstermekle yetinir:** plan `platform_tasarim_plan()`, koşular `platform_run_invitro()` (koşu koşu, ilerleme ve iptalle), seçim `platform_tasarim_secim()`. Sayılar webR'e `evalR` ortamıyla ikili (binary) olarak geçer; metin dönüşümü yok (B-1 riski yok).
  - **Katman:** bütün planlı koşular veri tabanında aynı nsim ve seed'li ana koşu (`tek`) olarak varsa hazır (P5-K7; birleşik koşu kullanılmaz, ortak seed korunur); değilse toplam iş ≤ 6 × 10⁷ ise canlı; üstündeyse betik önerisi (T-3 gelince düğme etkinleşir).
  - **Gösterim:** özet tablo (yöntem × Kural A/B: tasarım, toplam ölçüm, güç, MCSE, tip I hata, KK-38 etiketi, eşiğe yakınlık ya da "yok" nedeni), yöntem başına ℓ × n tabloları (güç, MCSE, tip I hata ve işareti; hedefe ulaşan, eşiğe yakın ve seçilen hücreler işaretli), uyarılar (aday küme, güç–tip I hata, FDA δ₀ tanımsız, H1 olmayan yöntem, eşiğe yakınlık). "Canlı da koş" hazır tabloyu yeniden üretir. Bağlantı tasarım girdilerini taşır (`mode=tasarim`).
  - `app.js`: sekme bağlantısı, `callR(code, env)`, `killWebR()`, `platform_tasarim.R` yüklenen platform dosyalarına eklendi (SHA-256 kaydı).
- **R tarafı düzeltme (`platform_tasarim.R`):** toplam iş sınırını aşan plan, sonuçları veri tabanından geldiğinde seçime kabul edilir (Aşama 1'in tam kümesi hazırdır ama canlı sınırının üstündedir). Test +2 beklenti (156; toplam 2.230, Windows 2.225; `dogrulama.yml` başlığı T-3'te güncellenecek).
- **Kuru denemeler (Claude, kapsayıcı; Playwright, Chromium, webR 0.5.4):**
  - Aşama 1, p_B 0,10, tam aday küme: hazır, yaklaşık 4 sn; özet Tablo 11.3a/b ile aynı (ör. FDA Kural A 3 × 10, %80,0, tip I %7,5 nominali aşıyor, eşiğe yakın; FDA Kural B yok; EMA (b) ve (c) Kural B 4 × 10).
  - Daraltılmış kümede canlı = hazır: oranlar birebir; MCSE'ler 10⁻¹⁷ düzeyinde farklı (veri tabanı MCSE'yi 15 anlamlı basamakla saklıyor). D-3 ölçütü sayım düzeyinde olduğundan uygun; kabulde K(10⁻¹², 10⁻¹²) ile karşılaştırılacak.
  - Yeni popülasyon (σ_R 0,15; 3 × {10, 15}) canlı 19 sn; tam küme sınır üstünde (1,58 × 10⁸ > 6 × 10⁷) betik uyarısı; iptal 58 ms, "tamamlanmadı 2/18", seçim yok; girdi hatası kodla; EN metinler; 375 px'te taşma yok (bağlantı iletisi satır kırma düzeltildi).
  - Tek senaryo sekmesi değişmedi: hazır ve canlı koşu çalışıyor.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `web/app/tasarim.js`, `app.js`, `index.html`, `ceviri.json`, `stil.css`, `README.md`; `CNKfarmastatr/R/platform_tasarim.R`, `tests/testthat/test-platform-tasarim.R`; bu günlük.
- **Sıradaki iş:** T-3, tasarım betiği (aday kümenin R betiği olarak dışa aktarılması).

## G-88 · P5 T-3: tasarım betiği — 20.10.2026

- **Depo:** G-87 commit edildi; Actions başarılı.
- **Proje sahibinin uyarısı ve kararı (K):** "Kullanıcı dilediği ℓ × n × m değerlerini de kendisi set edebiliyor olmalı. Bu çok önemli."
  - Claude'un yanıtı: bu G-87'de zaten var. "Aday tasarımlar" alanındaki ℓ, n, m listelerine kullanıcı istediği tam sayıları yazar (ℓ, n ≥ 2; m ≥ 1); ızgarada olmayan değerler canlı ya da betikle hesaplanır; tek tasarım da girilebilir. Listelerin bütün birleşimleri aday olur.
  - Bağımsız tasarım listesi (ör. yalnız 3 × 10, 4 × 8, 6 × 5) önerildi; proje sahibi: "gerek yok; istenen ℓ, n, m değerleri yeterli." Aday küme tanımı değişmedi.
- **T-3 · tasarım betiği (`R/platform_tasarim.R` 0.2.0):**
  - `platform_export_tasarim()`: aday kümeyi tek dosyalık R betiği olarak yazar. P3 betiğinin yapısı: altı kaynak dosya gömülü (P3'ün beşi + `platform_tasarim.R`), önce SHA-256 doğrulaması, tek zaman satırı, temel R. Tarayıcı sınırları uygulanmaz.
  - Betik: planlar, her koşuyu sırayla yapar (ilerleme satırıyla), Kural A ve B'yi uygular; özet yazdırır; `_secim.csv`, `_tablo.csv`, `_sonuc.csv` (kesin sayılarla) ve `_kayit.json` yazar.
  - `platform_tasarim_dosyalari()`; `.platform_tasarim_dosyalar` liste olarak yazıldı (dosya betikte tek başına da yüklendiği için).
  - `man/platform_tasarim.Rd` iki fonksiyonla genişledi.
  - **Ekran:** tasarım sekmesinde "R betiği" düğmesi etkin; sınır üstü uyarısı betiği gösteriyor (`tasarim.js`, `app.js`, `ceviri.json`).
- **Testler (`test-platform-tasarim.R`, yeni D-5 bloğu):** betik = `platform_tasarim()` (seçim, tablo, motor sonuçları birebir); iki dışa aktarım yalnız zaman satırında farklı; gömülü dosyada bir bayt değişince SHA-256 durdurur, hesap yok; geçersiz girdi, hedef ve sabit dosya farkı dışa aktarımda reddedilir; Aşama 1'in tam kümesi betikte 30 tasarım, 90 koşu, 158.400.000 hücre.
- **Sonuçlar (Claude, kapsayıcı):**
  - Test kümesi 50 blok, 2.244 beklenti, 0 hata, 0 atlanan (Windows'ta beklenen 2.239). Çekirdek SHA-256 13/13 AYNI.
  - Tarayıcıdan indirilen betik (σ_R 0,15; 3 × {5, 10}; nsim 300) yerel R'de (`--vanilla`) tarayıcıdaki canlı sonuçla aynı güç, tip I hata, tasarım ve nedenleri verdi (D-5'in kuru denemesi).
  - Not: betikler UTF-8 yereliyle çalıştırılmalı; C yerelinde gömülü metin bozulur ve SHA-256 durdurur (P3'teki gibi, güvenli yönde).
- **`dogrulama.yml`:** başlık yorumu 50 blok, 2.244 beklenti (Windows 2.239). Korumalı; proje sahibine gönderildi.
- **Dosyalar (depoya yazıldı, bayt bayt doğrulandı):** `CNKfarmastatr/R/platform_tasarim.R`, `man/platform_tasarim.Rd`, `tests/testthat/test-platform-tasarim.R`, `web/app/tasarim.js`, `app.js`, `ceviri.json`; bu günlük.
- **Sıradaki iş:** T-4 ve T-5, Word raporu (tek senaryo ve tasarım seçimi).

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
| A-10 | Simülasyon altyapısı: validasyon belgesi FSR-VAL-SIM-1 ve SHA-256 sabitleme; ilk yayın senaryosu | Altyapı v0.1.0 tamam (G-15); ilk senaryo PBE güç / seri başına kap sayısı; teknik not v0.4 (G-31); hızlı motor `invitro_fast.R` (G-32); Aşama 1 koşuldu (G-33) ve nota işlendi (G-34); SAS kontrolü (G-36); sırada Aşama 2; Aşama 2 listesi sabitlendi, 725 senaryo (G-38); motor 0.2.0, Aşama 2 koşuldu (G-40); FSR-VAL-SIM-1 v0.1 taslak (G-44); FSR-VAL-SIM-1 1.0 ve sabitleme tamam (G-47) |
| A-12 | `invitro_fast.R` ve `invitro_grid.R` için validasyon belgesi (FSR-VAL-SIM-1 kapsamında) ve SHA-256 sabitleme; EMS testi (teknik not 8.5) pakete | Tamam: FSR-VAL-SIM-1 1.0 onaylandı, beş dosya SHA-256 ile sabitlendi (G-47) |
| A-13 | Teknik not v0.7: D1–D13 (G-38) | Tamam: v0.7 (G-39) |
| A-14 | Tip I uyum ölçütü kararı; teknik not v0.8 (rapor 02) ve Aşama 2 sonuçları; yeniden üretim paketi (G-40) | Tamam: ölçüt (KK-38), v0.8, paket (G-41), Aşama 2 sonuçları v0.9 (G-42); v0.9 onaylandı, hedefli deney ve v0.10 (G-43); 12.10 onay bekliyor; v0.10 onaylandı, v0.11 (G-48) |
| A-9 | Dışa açılan fonksiyonların gözden geçirilmesi (şu an tümü açık; `exportPattern`) ve dissolüsyon köprüsü | Arayüz tasarımıyla birlikte |
| A-11 | Birincil kaynakların temini ve incelenmesi (KK-25; liste G-20) | Büyük ölçüde tamam (G-21); eksik: Ting ve ark. 1990, Langenbucher 1972 |
| A-15 | Platform: tasarım notu FSR-TN-PLT-01, P0 spesifikasyonu, prototip (P1) ve P2–P6 | P0, P1, P2, P3 ve P4 kapandı (KK-55, G-82; P4 resmi kabul 12/12 GECTI, G-81). P5 (tasarım seçimi ve Word raporu; KK-56): FSR-TN-PLT-05 v0.2 onaylandı (KK-57, G-85); T-1 `platform_tasarim()` tamam, D-1 yeniden üretildi (G-86); T-2 tasarım sekmesi (G-87); T-3 tasarım betiği (G-88). Açık: testthat kümesinin webR'de koşulması. Izgara kontrolleri CI'da (G-72, G-74) |
| A-2 | Proje dosyalarının temizlenmesi: eski günlük, yol haritası, app.R, PBE_webr HTML'leri, GMP kılavuzları kaldırılır | Proje sahibi |

# 4. Belge ve sürüm dizini

| Belge / yazılım | Sürüm | Durum |
|---|---|---|
| FSR-LOG-01 · Proje günlüğü | 1.85 | Bu belge |
| FSR-TN-PBE-01 · In vitro eşdeğerlik (FDA PBE, EMA OIP) simülasyon modeli ve tasarımı | 0.11 | Taslak; Bölüm 12.10 onaylandı, mekanizma "destekler" düzeyinde (G-48, KK-42) |
| FSR-VAL-SIM-1 · Simülasyon çatısı ve in vitro simülasyon motoru validasyon belgesi | 1.1 | 1.0 onaylı; beş dosya sabitlendi (G-47). 1.1: TC-S11 (dışa aktarılan betik), onaylandı (KK-53, G-76) |
| FSR-TN-PLT-01 · Platform tasarımı ve P0 spesifikasyonu | 0.6 | Onaylı (KK-48); P0 ve P1 kapandı; v0.6: künye ve Tablo 11.1 revizyonu (G-68) |
| FSR-TN-PLT-02 · P2 tasarımı, kabul ölçütleri ve sonuçları | 0.2 | v0.1 onaylı (KK-49); v0.2: anahtar düzeltmesi, sonuçlar (11/11 GEÇTİ), sapmalar (G-69); onaylandı, P2 kapandı (KK-50, G-70) |
| FSR-TN-PLT-03 · P3 tasarımı, kabul ölçütleri ve sonuçları | 0.2 | v0.1 onaylı (KK-51); v0.2: sonuçlar 12/12 GEÇTİ, bulgular (G-75); onaylandı, P3 kapandı (KK-53, G-76) |
| FSR-TN-PLT-04 · P4 tasarımı ve kabul ölçütleri | 0.2 | v0.1 onaylı (KK-54); v0.2: resmi kabul 12/12 GECTI (G-81); onaylandı, P4 kapandı (KK-55, G-82) |
| FSR-TN-PLT-05 · P5 tasarımı ve kabul ölçütleri (tasarım seçimi ve Word raporu) | 0.2 | v0.1 taslak (G-83); v0.2: tasarım seçimi eklendi (KK-56, G-84); onaylandı, D-1…D-7 ve R-1…R-11 donduruldu (KK-57, G-85) |
| CNK-FarmaStatR | 1.0.0.9000 | Geliştirme başladı (G-01) |
| CNKfarmastatr (R paketi) | 1.0.0.9000 | 13 dosya SHA-256 ile sabit (8 devralınan çekirdek + simülasyon çatısı ve in vitro motoru; FSR-VAL-SIM-1 1.0, G-47); testler 26 blok, 968 beklenti GEÇTİ (G-46) |

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
| KK-36 | m = 1, 2, 3 genel; Budesonid tek m değerine bağlanmaz | G-38 |
| KK-37 | Aşama 2 listesi koşudan önce sabit: p_B {0; 0,30} çaprazlı + rapor ekleri; 725 senaryo | G-38 |
| KK-38 | Tip I hata üç sınıflı etiket (nominali aşıyor / kontrol kanıtlı / ayırt edilemiyor); tasarım ölçütü "nominali aşmıyor" | G-41 |
| KK-39 | v0.9 onayı: Hp4 ifadesi; mekanizma hedefli deneyle (eşleşik karar, üst sınır düzeyinde); Tablo 11.3b başlığı; ek tekrarda 10k/40k ayrı, 50k yalnız bağımsız akışla, eşiğe yakın güç kesin sayılmaz | G-43 |
| KK-40 | Motor validasyonu FSR-VAL-SIM-1 içinde ayrı bölüm; EMA (c) bağımsız analiz olursa kendi belgesi (ör. FSR-VAL-EMA-1) | G-44 |
| KK-41 | Validasyon kabul ölçütleri: birleşik mutlak + göreli tolerans; SAS nicel (deterministik 10⁻¹⁰/10⁻⁹; sınırda ölçüt, GA, karar); REML'de ölçüt, kısıt, GA, karar; MC ortak |z| < 4, 3–4 uyarı; yeniden üretim koşulları | G-45 |
| KK-42 | Teknik not Bölüm 12.10 kalır; hedefli deney mekanizmayı destekler, "tamamen kanıtladı" anlamında kullanılmaz | G-48 |
| KK-43 | FSR-TN-PLT-01 v0.1 incelemesi: Ö1, Ö6 onay; Ö2, Ö3 koşullu; Ö4, Ö5, Ö7 revizyon; önce P0; yöntem bazında H0/H1 ve metrik etiketi zorunlu; n_sim varsayılan 10.000, geçici üst sınır 20.000 | G-51 |
| KK-44 | FSR-TN-PLT-01 v0.2 incelemesi: P0'a koşullu olumlu görüş; D-01, D-02, D-05 belge düzeyinde, D-06 P1 ölçütleri sabitlenince P1; D-03, D-04 P2 öncesi | G-52 |
| KK-45 | FSR-TN-PLT-01 v0.3 nihai görüşü: temel tasarım onaylandı; 10⁻¹² mutlak tolerans korunur, D-02 gerekçesi proje sahibinin metniyle; P1 test koşulları onaylandı ve Tablo 11.1 ile donduruldu; P0 kapandı, P1'e geçildi; P1 başarısına dondurulmuş kabul testleri koşulduktan sonra karar verilir | G-53 |
| KK-46 | P1 koşullu başarılı: bellek eşiği aşıldı (1.068 > 1.024 MB) ve açıkça kaydedilir; donmuş kurala göre geçici n_sim üst sınırı düşürülür, yeni sınır ölçümle belirlenir; P1 kapanışı bu ölçüm ve belgelemeye bağlı | G-58 |
| KK-47 | Geçici üst sınır: n_sim ≤ 20.000 ve ℓ·n·m·n_sim ≤ 8,1 × 10⁶ (dayanak: prototip tek başına 15.000 tekrarda 688 MB; FarmaStatR türetimi; tek cihaz) | G-60 |
| KK-48 | FSR-TN-PLT-01 v0.5 onaylandı; KK-46 koşulu sağlandı; P1 kapandı, P2'ye geçilir | G-61 |
| KK-49 | FSR-TN-PLT-02 v0.1 onaylandı: P2-K1 (b) ortak δ ölçeğinde yakınlık uyarısı ≤ 10⁻⁴; P2-K2 Dᵢ yoksa birleşik eşleşik MCSE saklanmaz; P2-K3 inşa R + RSQLite; S-1…S-11 donduruldu | G-65 |
| KK-50 | FSR-TN-PLT-02 v0.2 onaylandı; P2 kapandı. A-1 (H-1…H-4 kabul betiğinde) ve A-2 (şema farkları) kabul; ızgara kontrollerinin CI'a eklenmesi ve A-3 sonraki aşamaya; A-4 isteğe bağlı | G-70 |
| KK-51 | FSR-TN-PLT-03 v0.1 onaylandı: P3-K1 (b) tek dosya, okunur gömülü kaynak, SHA-256 doğrulaması; P3-K2 prototipe R betiği düğmesi P3'te; P3-K3 ızgara betiği P3 dışında; E-1…E-12 donduruldu | G-72 |
| KK-52 | p2_kabul.R 0.2: S-4 ölçütteki gibi KK-38 etiketlerini karşılaştırır, yüzde metnindeki son basamak farkı bilgi olarak raporlanır; platformdan bağımsız gösterim yuvarlaması P5'te açık madde | G-74 |
| KK-53 | FSR-TN-PLT-03 v0.2 ve FSR-VAL-SIM-1 v1.1 onaylandı; P3 kapandı | G-76 |
| KK-54 | FSR-TN-PLT-04 v0.1 onaylandı: P4-K1 hazır sonuçta birleşik koşu varsa o; P4-K2 G1 ve G2 grafikleri P4'te; P4-K3 tek JS biçimlendirme fonksiyonu (ikili değere en yakın, eşitlikte çift); U-1…U-12 donduruldu | G-78 |
| KK-55 | FSR-TN-PLT-04 v0.2 onaylandı; P4 kapandı | G-82 |
| KK-56 | P5 kapsamı: hedef güç için ℓ, n, m tasarım seçimi ve Word raporu birlikte P5'te | G-84 |
| KK-57 | FSR-TN-PLT-05 v0.2 onaylandı: P5-K1…P5-K7 hepsi (a); D-1…D-7 ve R-1…R-11 donduruldu | G-85 |
