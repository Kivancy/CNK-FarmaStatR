# CNK-FarmaStatR v1

Farmasötik istatistik için akademik eğitim ve araştırma platformu (geliştirme sürümü 1.0.0.9000).

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.

English: [README.md](README.md)

## Kullanım

Depo kökünden yerel sunucu (R):

```r
setwd("C:/cloud/CNK-FarmaStatR/CNK-FarmaStatR")
httpuv::runStaticServer(".", port = 8000)
```

| Adres | İçerik |
|---|---|
| `http://127.0.0.1:8000/web/app/` | In vitro PBE simülasyonu ve tasarım seçimi (ℓ × n × m; FDA, EMA) |
| `http://127.0.0.1:8000/web/analiz/` | Kendi verinizle analiz: PBE; f2 ve bootstrap f2; model bağımsız MSD; Weibull MSD |
| `http://127.0.0.1:8000/web/analiz/dogrula.html` | Tarayıcıda doğrulama (devralınan 516 kontrol, paket testleri) |
| `http://127.0.0.1:8000/web/yardim/yontem/` | Yöntem notları (PBE, f2, MSD, Weibull, simülasyon) |

Hesaplar tarayıcıdaki R'de (webR) yapılır; veriler tarayıcıdan çıkmaz. Her sonuç seed, RNG ve
sürümlerle kaydedilir; bağlantıyla ya da dışa aktarılan R betiğiyle yeniden üretilir.

## Klasör

- `FSR-LOG-01_v1_gunluk.md` — proje günlüğü (her oturum burada kaydedilir)
- `CNKfarmastatr/` — R paketi (istatistik çekirdeği, platform fonksiyonları ve testler)
- `web/` — tarayıcı arayüzü (`app/`: simülasyon ve tasarım; `analiz/`: veri analizi ve doğrulama; `yardim/`: yardım ve yöntem notları; `p1/`: prototip)
- `veri/` — SQLite veri tabanı (önceden hesaplanmış simülasyon sonuçları; SHA-256 `VT_SHA256.txt`)
- `simulasyon/` — simülasyon çalışmalarının betikleri ve sonuçları
- `araclar/` — yardımcı betikler (`cekirdek_kontrol.R`: çekirdeklerin parmak izi kontrolü)
- `devralinan/v0.5.1/` — önceki çalışmadan alınan malzeme (değiştirilmeden; SHA-256 değerleri günlükte)
- `belgeler/` — teknik notlar ve validasyon belgeleri (Word); ekleri (betik, sonuç tabloları) yanlarında;
  `yayin/` yayın hazırlığı (kontrol listesi, Pages taslağı)

Atıf: `CITATION.cff` (taslak; lisans A-6 ve DOI sürümde).

Özel GitHub deposu: github.com/Kivancy/CNK-FarmaStatR
