# CNK-FarmaStatR · P1 prototipi / P1 prototype

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.
For research and education; not a system validated for GxP environments.

Kaynak / source: FSR-TN-PLT-01 v0.6 (D-05; Tablo 11.1–11.2, KK-47).

## TR

### Sunucuyu açma (her iki sayfa için)

Sayfalar depo kökünden sunulmalıdır, çünkü motor dosyalarını `../../CNKfarmastatr/` yolundan
okurlar. R konsolunda:

```r
install.packages("httpuv")   # bir kez
setwd("C:/cloud/CNK-FarmaStatR/CNK-FarmaStatR")
httpuv::runStaticServer(".", port = 8000)
```

Sunucuyu durdurmak için R konsolunda Esc'e basın (gerekirse `httpuv::stopAllServers()`).
`file://` ile açmak çalışmaz; tarayıcı modülleri ve SHA-256 hesabını yalnız güvenli bir
kaynaktan (`localhost`) izin verir. webR internetten (`webr.r-wasm.org`) yüklenir.

### İki sayfa

| Adres | Sayfa | Ne için |
|---|---|---|
| `http://127.0.0.1:8000/web/p1/` | Prototip (`index.html`) | Tek bir senaryoyu çalıştırmak |
| `http://127.0.0.1:8000/web/p1/kabul.html` | Kabul aracı | Tablo 11.1 testlerini toplu koşmak |

### Prototip

Sayfa hesap yapmaz. Motor dosyalarını (`invitro_fast.R`, `invitro_grid.R`) indirir ve SHA-256
değerlerini `CNKfarmastatr/inst/validasyon/CEKIRDEK_SHA256.txt` ile karşılaştırır; uyuşmazlık
varsa hiçbir dosyayı yüklemez. Doğrulanan baytları webR 0.5.4'e yükler ve `platform_run_invitro()`
fonksiyonunu çağırır (`platform_input.R`: giriş kontrolü, ardından değiştirilmemiş
`invitro_scenario()`).

- Oranlar P1'de hipotez durumuna göre sınıflandırılmaz; hepsi "BE kabul olasılığı" olarak
  gösterilir. Sınıflandırma fonksiyonu P2'de yazıldı (`platform_hipotez()`); ekranda görünmesi P4'te.
- Koşu büyüklüğü sınırı (KK-47): n_sim ≤ 20.000 ve ℓ · n · m · n_sim ≤ 8,1 milyon. Ekran,
  seçilen tasarım için üst sınırı gösterir (6 × 30, m = 3: 15.000).
- **İptal:** webR, çapraz köken yalıtımı başlıkları olmadan (GitHub Pages koşulu) çalışan bir R
  hesabını kesemez. Bu yüzden İptal düğmesi webR'yi kapatır ve doğrulanmış dosyalardan yeniden
  başlatır. Kısmi sonuç tutulmaz.

### Kabul aracı (Tablo 11.1–11.2)

1. `kabul.html` adresini açın ve sayfadaki 0–5. adımları sırayla izleyin. İptal ve performans
   adımları 6 × 30 ve 15.000 tekrarla koşar (v0.6; resmi P1 koşusu 20.000 ile yapılmıştı).
   Sonunda `p1_tarayici.csv` iner.
2. Dosyayı `belgeler/teknik_notlar/FSR-TN-PLT-01_ek/p1/` klasörüne koyun.
3. R konsolunda, depo kökündeyken
   `source("web/p1/kabul/p1_kabul.R", encoding = "UTF-8")` komutunu çalıştırın. Betik aynı
   hesapları (`web/p1/kabul/kabul.R`) yerel R'de yapar, her ölçütü GECTI, KALDI, EKSIK ya da
   ASILDI_SINIR_DUSER olarak yazar ve sonuçları aynı klasöre kaydeder.

## EN

**Server (both pages):** serve the repository root, e.g. `httpuv::runStaticServer(".", port = 8000)`
from the repository folder; stop it with Esc. The pages do not work from `file://`. webR loads
from `webr.r-wasm.org`.

**Pages:** `http://127.0.0.1:8000/web/p1/` is the prototype (one scenario);
`http://127.0.0.1:8000/web/p1/kabul.html` is the acceptance tool (Table 11.1).

**Prototype:** the page does no statistics. It verifies the engine files against
`CEKIRDEK_SHA256.txt`, loads only the verified bytes into webR 0.5.4 and calls
`platform_run_invitro()` (input check, then the unchanged `invitro_scenario()`). Rates are shown
as "probability of BE acceptance"; the run-size limit is n_sim ≤ 20,000 and
ℓ · n · m · n_sim ≤ 8.1 million. Cancel closes webR and restarts it from the verified files.

**Acceptance tool:** follow steps 0–5 of `kabul.html` (cancel and performance runs use 6 × 30
and 15,000 replicates), put `p1_tarayici.csv` into `belgeler/teknik_notlar/FSR-TN-PLT-01_ek/p1/`
and source `web/p1/kabul/p1_kabul.R` from the repository root.
