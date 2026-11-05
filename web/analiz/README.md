# CNK-FarmaStatR · Veri analizi ekranı / Data analysis screen (P6)

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.
For research and education; not a system validated for GxP environments.

Kaynak / source: FSR-TN-PLT-06 v0.1 (KK-59); EMA: FSR-TN-PLT-08 v0.1 (KK-64). Geliştirme sürümü / development version.

## TR

Sunucu depo kökünden açılır (P4 ve P5 ile aynı):

```r
setwd("C:/cloud/CNK-FarmaStatR/CNK-FarmaStatR")
httpuv::runStaticServer(".", port = 8000)
```

| Adres | İçerik |
|---|---|
| `http://127.0.0.1:8000/web/analiz/` | Kendi verinizle analiz: PBE ve EMA (FDA PSG 020929; EMA OIP Rev. 2 ölçüt 8, %90 GA) ve dissolüsyon benzerliği (f2 ve bootstrap f2, model bağımsız MSD, Weibull MSD) |
| `http://127.0.0.1:8000/web/analiz/dogrula.html` | Tarayıcıda doğrulama: devralınan 516 kontrol ve paket testleri webR'de |
| `http://127.0.0.1:8000/web/analiz/kabul6.html` | P6 kabul aracı (iç kullanım) |
| `http://127.0.0.1:8000/web/analiz/kabul8.html` | EMA kabul aracı (iç kullanım; FSR-TN-PLT-08) |
| `http://127.0.0.1:8000/web/app/` | Simülasyon ve tasarım ekranı (P4, P5) |

- **Hesap:** tarayıcıdaki R'de (webR 0.5.4). Değiştirilmemiş validasyonlu çekirdekler ve köprüler
  çağrılır; sayfa hesap yapmaz. Çekirdek dosyaları SHA-256 ile denetlenir; uyuşmazlıkta hesap engellenir.
- **Veri:** örnek veri ya da CSV dosyası. Ayraç `;`, `,` ya da sekme; ondalık virgül olabilir.
  - PBE sütunları: `parti, kap, asama, urun, olcum` (ya da `batch, container, stage, product, score`).
    Aynı veriyle “Yöntem: EMA %90 GA” seçilebilir (yalnız dengeli tasarım; üç hesaplama yolu, karar (b) yolu).
  - Dissolüsyon: geniş biçim (KK-78, FSR-TN-PLT-12): ilk sütun `Time`, diğer sütunlar `<ürün>.<ünite>` (`Test.1`, `Ref.1`, …), her satır bir zaman noktası; DDSolver'ın ikinci başlık satırı atlanır. Uzun biçim de okunur: `Product, Unit, Time, Diss` (ya da `urun, tablet, zaman, cozunen`).
    Referans lotları ayrı ürün adlarıyla verilir (L2a/L2b, B-L2a/B-L2b için).
- **Gizlilik:** dosya tarayıcıda okunur; hiçbir yere gönderilmez.
- **Çıktı:** Word raporu (.docx) ve koşu kaydı (JSON). Rapor ekrandakiyle aynı metinleri taşır.
- **İletiler:** devralınan çekirdeklerin hata ve uyarı iletileri Türkçedir (ilk revizyonlarına kadar
  değiştirilmez).
- webR internetten (`webr.r-wasm.org`) yüklenir; ilk açılış birkaç saniye sürer.

## EN

Serve the repository root as above and open the addresses in the table: `web/analiz/` (analysis of your
own data; PBE tab: FDA PBE or EMA 90% CI), `web/analiz/dogrula.html` (validation in the browser), `web/app/` (simulation and design).
The computation runs in R inside the browser (webR); the validated cores and bridges are called
unchanged and checked with SHA-256. CSV columns are listed above (Turkish or English names). Your
file is read in the browser and sent nowhere. Messages of the inherited cores are in Turkish.

## Dosyalar / files

| Dosya | Görev |
|---|---|
| `index.html`, `analiz.js`, `analiz.css` | Analiz ekranı |
| `dogrula.html`, `dogrula.js`, `dogrula_dosyalar.txt` | Tarayıcıda doğrulama ve yüklenen dosyaların listesi |
| `testthat_kucuk.R` | webR için testthat yerine geçen küçük temel R kodu (FarmaStatR türetimi) |
| `kabul6.html`, `kabul6.js` | P6 kabul aracı; karşılaştırma `belgeler/teknik_notlar/FSR-TN-PLT-06_ek/p6_kabul.R` |
| `kabul8.html`, `kabul8.js` | EMA kabul aracı; karşılaştırma `belgeler/teknik_notlar/FSR-TN-PLT-08_ek/p8_kabul.R` |
| `../../CNKfarmastatr/R/platform_analiz.R` | CSV okuma, sütun eşleme, köprü çağrısı; `platform_ema` (EMA: `invitro_array` + `ema_ci_fast`) |
| `../../CNKfarmastatr/inst/kopru/dis_kopru.R` | v0.5.1 dissolüsyon köprüsü (bayt bayt aynı; FSR-LOG-01 G-01) |

`dogrula_dosyalar.txt`, paket klasörüne (`R/`, `inst/`, `tests/testthat/`) dosya eklenince
güncellenmelidir; `p6_kabul.R` listeyi klasörlerle karşılaştırır (F-9).
