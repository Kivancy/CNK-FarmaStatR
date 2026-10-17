# CNK-FarmaStatR · P1 prototipi / P1 prototype

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.
For research and education; not a system validated for GxP environments.

Kaynak / source: FSR-TN-PLT-01 v0.4 (D-05; Tablo 11.1–11.2).

## TR

Minimal tarayıcı prototipi. Sayfa hesap yapmaz: motor dosyalarını (`CNKfarmastatr/R/invitro_fast.R`,
`invitro_grid.R`) indirir, SHA-256 değerlerini `CNKfarmastatr/inst/validasyon/CEKIRDEK_SHA256.txt`
ile karşılaştırır; uyuşmazlık varsa hiçbir dosyayı yüklemez. Doğrulanan baytları webR 0.5.4'e yükler
ve `platform_run_invitro()` fonksiyonunu çağırır (`platform_input.R`: giriş kontrolü, ardından
değiştirilmemiş `invitro_scenario()`).

Oranlar P1'de hipotez durumuna göre sınıflandırılmaz; hepsi "BE kabul olasılığı" olarak gösterilir.
Sınıflandırma P2'nin işidir.

**Yerelde açma.** Sayfa, depo kökünden sunulmalıdır; çünkü motor dosyalarını `../../CNKfarmastatr/`
yolundan okur. R konsolunda şunları çalıştırın:

```r
install.packages("httpuv")   # bir kez / once
setwd("C:/cloud/CNK-FarmaStatR/CNK-FarmaStatR")
httpuv::runStaticServer(".", port = 8000)
```

Ardından tarayıcıda `http://127.0.0.1:8000/web/p1/` adresini açın. webR internetten
(`webr.r-wasm.org`) yüklenir. `file://` ile açmak çalışmaz, çünkü tarayıcı modülleri ve SHA-256
hesabını yalnız güvenli bir kaynaktan (`localhost`) izin verir.

**İptal.** webR, çapraz köken yalıtımı başlıkları olmadan (GitHub Pages koşulu) çalışan bir R
hesabını kesemez. Bu yüzden İptal düğmesi webR'yi kapatır ve doğrulanmış dosyalardan yeniden
başlatır. Kısmi sonuç tutulmaz.

## EN

Minimal browser prototype. The page does no statistics. It downloads the engine files, compares
their SHA-256 values with `CEKIRDEK_SHA256.txt` and, if any value differs, loads nothing. The verified
bytes are loaded into webR 0.5.4, and the page calls `platform_run_invitro()`: the input check
first, then the unchanged `invitro_scenario()`. Rates are not classified by hypothesis state in P1.

**To open it locally**, serve the page from the repository root (see the R commands above) and
open `http://127.0.0.1:8000/web/p1/`. webR loads from `webr.r-wasm.org`. The page does not work
from `file://`.

**Cancel** closes webR and restarts it from the verified files; no partial result is kept.

## Kabul testleri / Acceptance tests (Tablo 11.1–11.2)

1. Sunucu açıkken Chrome'da `http://127.0.0.1:8000/web/p1/kabul.html` adresini açın ve sayfadaki
   0–5. adımları sırayla izleyin. Sonunda `p1_tarayici.csv` iner.
2. Dosyayı `belgeler/teknik_notlar/FSR-TN-PLT-01_ek/p1/` klasörüne koyun.
3. R konsolunda, depo kökündeyken `source("web/p1/kabul/p1_kabul.R", encoding = "UTF-8")` komutunu
   çalıştırın. Betik aynı hesapları (`web/p1/kabul/kabul.R`) yerel R'de yapar, her ölçütü GECTI,
   KALDI ya da EKSIK olarak yazar ve sonuçları aynı klasöre kaydeder.

Open `kabul.html` and follow steps 0–5; put `p1_tarayici.csv` into
`belgeler/teknik_notlar/FSR-TN-PLT-01_ek/p1/` and source `web/p1/kabul/p1_kabul.R` from the
repository root. The same R code runs in the browser and in local R; each Table 11.1 criterion is
marked GECTI (pass), KALDI (fail) or EKSIK (missing).
