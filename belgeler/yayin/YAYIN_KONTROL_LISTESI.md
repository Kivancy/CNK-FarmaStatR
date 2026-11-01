# CNK-FarmaStatR · Açık geliştirme ve yayın kontrol listesi / open development and release checklist

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.

Kaynak: FSR-TN-PLT-06 v0.1 Bölüm 8 (P6, G-94); yol değişikliği KK-69 (FSR-LOG-01 G-118): hedef dergi
JOSS; depo v1.0.0'dan önce açılır, çünkü JOSS başvurudan önce en az altı aylık açık geliştirme geçmişi
ister. Claude bu listedeki işleri **hazırlar**; işaretli adımların kararı ve yürütülmesi proje
sahibindedir (geri döndürülemez ya da proje sahibine ait). Bir aşama öncekiler tamamlanmadan başlamaz.

## A · Depoyu açma

| # | Adım | Kim | Durum |
|---|---|---|---|
| A1 | Lisans: kod MIT (`LICENSE`, `CNKfarmastatr/LICENSE`, `DESCRIPTION`), belgeler CC BY 4.0 (`LICENSE-belgeler.md`); `CITATION.cff`, `.zenodo.json` | Proje sahibi karar verdi (KK-69); Claude yazdı | Tamam (G-118) |
| A2 | `CONTRIBUTING.md` (sorun bildirme, katkı, destek); README ve OKUBENI güncellendi | Claude | Tamam (G-118) |
| A3 | Telif ve gizlilik taraması, bugünkü dosyalar: izlenen 400 dosyada PDF yok, `kaynaklar/` izlenmiyor, parola ya da anahtar yok | Claude | Tamam (G-118) |
| A4 | Telif taraması, **git geçmişi**: geçmişte depoya girmiş bütün dosya adlarının listesi | Proje sahibi tek komut çalıştırır; Claude inceler | Tamam: geçmiş temiz (G-119) |
| A5 | Karar: `belgeler/teknik_notlar/FSR-TN-PBE-01_ek/chow1452.csv` (Chow ve Liu 2008 kitabının iki tablosundan elle aktarılmış 1080 değer) depoda kalsın mı | Proje sahibi | Tamam: kalır (KK-70, G-119) |
| A6 | Karar: kökteki `G-98_yardim_dosyalari.zip` (21.10.2026 tarihli eski dosya kopyaları) silinsin mi; Claude önerisi: silinsin | Proje sahibi | Tamam: silindi (G-119) |
| A7 | Bilgi: açılınca commit'lerdeki e-posta adresi görünür olur (adres zaten `DESCRIPTION` ve `CITATION.cff`'te iletişim adresi) | Proje sahibi | Tamam: açık kalır; `CITATION.cff`'te kurumsal adres (KK-70, G-119) |
| A8 | ORCID ve kurum bilgisi (`CITATION.cff`, `.zenodo.json`, `DESCRIPTION`); JOSS'ta ORCID beklenir | Proje sahibi bilgileri verir | Tamam: Ege Üniversitesi; ORCID 0000-0003-3491-0099 (G-119) |
| A9 | **Deponun açılması**: GitHub > Settings > General > Danger Zone > Change visibility > Public | Proje sahibi | Bekliyor |
| A10 | GitHub > About: kısa açıklama, konu etiketleri (bioequivalence, dissolution, r, webr); Issues açık | Proje sahibi (Claude metni hazırlar) | Bekliyor |
| A11 | Günlük: açılış tarihi (JOSS'un altı aylık süresi bu tarihten başlar) | Claude | Bekliyor |

## B · Altı aylık açık geliştirme

| # | Adım | Kim | Durum |
|---|---|---|---|
| B1 | Ara sürümler (GitHub Releases; ör. geliştirme sürümü etiketleri) | Proje sahibi etiketler; Claude sürüm notlarını yazar | Bekliyor |
| B2 | Duyuru ve geri bildirim: BEBAC forumu (https://forum.bebac.at/) | Proje sahibi | Bekliyor |
| B3 | Gelen issue'ların yanıtlanması; değişiklikler teknik not ve kabul ölçütleriyle | Proje sahibi karar verir; Claude yazar | Sürekli |
| B4 | A-9: dışa açılan fonksiyonların ayıklanması ve belgeleri | Claude, proje sahibi onaylar | Bekliyor |
| B5 | **GitHub Pages**: `belgeler/yayin/pages.yml.taslak` → `.github/workflows/pages.yml`; Settings > Pages > Source: GitHub Actions | Proje sahibi (iş akışı dosyası korumalı) | Taslak hazır |
| B6 | JOSS makalesi: `paper.md` ve `paper.bib` (Summary, Statement of need, State of the field, AI beyanı, kaynaklar) | Claude yazar, proje sahibi düzeltir ve onaylar | Bekliyor |

## C · JOSS başvurusu ve v1.0.0

| # | Adım | Kim | Durum |
|---|---|---|---|
| C1 | Sürüm numarası: `DESCRIPTION` 1.0.0.9000 → 1.0.0; `CITATION.cff` version; NEWS | Claude | Bekliyor |
| C2 | **Zenodo bağlantısı**: zenodo.org > GitHub > depoyu etkinleştir (etiketten önce) | Proje sahibi | Bekliyor |
| C3 | **v1.0.0 etiketi ve GitHub sürümü** (Releases > Draft a new release > Tag v1.0.0) | Proje sahibi | Bekliyor |
| C4 | Zenodo DOI'si gelince: `CITATION.cff` doi, README rozeti | Claude yazar, proje sahibi commit eder | Bekliyor |
| C5 | Yayındaki sayfaların denetimi: üç adres açılır; `dogrula.html` 516/516; bir analiz ve bir rapor | Proje sahibi + Claude | Bekliyor |
| C6 | **JOSS başvurusu** (https://joss.theoj.org/papers/new); açık geçmiş en az altı ay | Proje sahibi | Bekliyor |
| C7 | Günlük: yayın girdisi, A-15 kapanışı | Claude | Bekliyor |

## Notlar

- JOSS koşulları (Ocak 2026): depoda OSI onaylı lisans dosyası; en az altı aylık açık geliştirme geçmişi
  (sürümler, açık issue ya da pull request); makalede yapay zekâ kullanım beyanı ve "Statement of need",
  "State of the field" bölümleri; testler, belgeler ve katkı kılavuzu
  (https://blog.joss.theoj.org/2026/01/preparing-joss-for-a-generative-ai-future,
  https://joss.readthedocs.io/en/latest/review_criteria.html).
- Pages iş akışı yalnız `v*` etiketlerinde ve elle tetiklemede çalışacak biçimde hazırlandı; her push'ta
  yayımlamaz.
- webR (`webr.r-wasm.org`) ve sql.js internetten yüklenir; depoda üçüncü taraf kodu yoktur.
- Sabitli dosyalarda değişiklik yeni sürüm ve validasyon belgesinde revizyon gerektirir
  (proje talimatları, Validasyon).
