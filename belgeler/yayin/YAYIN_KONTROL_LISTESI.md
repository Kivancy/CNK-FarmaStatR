# CNK-FarmaStatR v1.0.0 · Yayın kontrol listesi / release checklist

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.

Kaynak: FSR-TN-PLT-06 v0.1 Bölüm 8 (P6, G-94). Claude bu listedeki işleri **hazırlar**; işaretli
adımların kararı ve yürütülmesi proje sahibindedir (geri döndürülemez ya da proje sahibine ait).
Sıra önemlidir: bir adım öncekiler tamamlanmadan başlamaz.

| # | Adım | Kim | Durum |
|---|---|---|---|
| 1 | P6 resmî kabulü (`web/analiz/kabul6.html` + `p6_kabul.R`, Windows) ve Word denetimi | Proje sahibi | Bekliyor |
| 2 | FSR-VAL-PLT-1 v1.0 onayı | Proje sahibi | Bekliyor |
| 3 | **Lisans (A-6)**: üniversite görüşü; yazılım ve içerik lisansı. `LICENSE` dosyası, `DESCRIPTION` License alanı, `CITATION.cff` ve `.zenodo.json` lisans alanları | Proje sahibi karar verir; Claude dosyaları yazar | Üniversite görüşü bekleniyor |
| 4 | Telif denetimi: depoda kılavuz ve makale PDF'i yok (`.gitignore`: `*.pdf`, `kaynaklar/`); örnek veri setlerinin kaynak atıfları README'de | Claude hazırlar, proje sahibi onaylar | Hazırlanacak (lisanstan sonra) |
| 5 | Sürüm numarası: `DESCRIPTION` 1.0.0.9000 → 1.0.0; `CITATION.cff` version; NEWS | Claude | Lisanstan sonra |
| 6 | Yazar bilgileri: ORCID ve kurum (CITATION.cff, .zenodo.json, DESCRIPTION) | Proje sahibi bilgileri verir | Bekliyor |
| 7 | **Deponun açılması** (GitHub > Settings > General > Change visibility) | Proje sahibi | Bekliyor |
| 8 | **GitHub Pages**: `belgeler/yayin/pages.yml.taslak` → `.github/workflows/pages.yml`; Settings > Pages > Source: GitHub Actions | Proje sahibi (iş akışı dosyası korumalı) | Taslak hazır |
| 9 | **Zenodo bağlantısı**: zenodo.org > GitHub > depoyu etkinleştir (etiketten önce) | Proje sahibi | Bekliyor |
| 10 | **v1.0.0 etiketi ve GitHub sürümü** (Releases > Draft a new release > Tag v1.0.0) | Proje sahibi | Bekliyor |
| 11 | Zenodo DOI'si gelince: `CITATION.cff` doi, README rozeti, platform makalesi | Claude yazar, proje sahibi commit eder | Bekliyor |
| 12 | Yayındaki sayfaların denetimi: üç adres açılır; `dogrula.html` 516/516; bir analiz ve bir rapor | Proje sahibi + Claude | Bekliyor |
| 13 | Günlük: yayın girdisi (FSR-LOG-01), A-6 ve A-15 kapanışı | Claude | Bekliyor |

## Notlar

- Pages iş akışı yalnız `v*` etiketlerinde ve elle tetiklemede çalışacak biçimde hazırlandı; her push'ta
  yayımlamaz.
- webR (`webr.r-wasm.org`) ve sql.js internetten yüklenir; yayındaki site de internet ister.
- Yayından sonra sabitli dosyalarda değişiklik yeni sürüm ve validasyon belgesinde revizyon gerektirir
  (proje talimatları, Validasyon).
