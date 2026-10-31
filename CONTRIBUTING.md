# Katkı ve destek / Contributing and support

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.
For research and education; not a system validated for GxP environments.

## English

### Reporting a problem or asking a question
Open an issue at https://github.com/Kivancy/CNK-FarmaStatR/issues. Please include:
- what you did (screen or R function, settings, data source; a small example data file if possible),
- what you expected and what you got (copy the message or attach the run record `.json` that the screen saves),
- your browser or R version.

Do not upload confidential or proprietary data. The platform runs in your browser and never sends your data anywhere; an issue, however, is public.

Questions about methods (for example, how a guideline is interpreted) are welcome as issues. Each method note on the platform lists its sources; please cite the guideline section or paper you refer to.

### Proposing a change
1. Open an issue first and describe the change, so that we can agree on the approach.
2. Fork the repository, make the change on a branch and open a pull request.
3. Add or update tests (`CNKfarmastatr/tests/testthat/`). The test suite runs on every push (GitHub Actions, Linux and Windows) and must stay green.
4. Validated statistical cores are pinned with SHA-256 (`CNKfarmastatr/inst/validasyon/CEKIRDEK_SHA256.txt`). A change to a pinned file needs a technical note with acceptance criteria agreed before the code, a rerun of the validation tests and a new revision of the validation document. Please discuss such changes in an issue first.
5. Every method step carries its source (guideline and section, or paper and equation); a step that no source defines is labelled "By design".

The statistical cores use base R only. Code comments are in English; user-facing texts are in Turkish and English (`web/app/ceviri.json`).

### Conduct
Be respectful and constructive. Disagreement about methods is welcome; personal remarks are not.

## Türkçe

### Sorun bildirme ve soru sorma
https://github.com/Kivancy/CNK-FarmaStatR/issues adresinde bir issue açın. Lütfen şunları yazın:
- ne yaptığınız (ekran ya da R fonksiyonu, ayarlar, veri kaynağı; mümkünse küçük bir örnek veri dosyası),
- ne beklediğiniz ve ne aldığınız (iletiyi kopyalayın ya da ekranın kaydettiği koşu kaydı `.json` dosyasını ekleyin),
- tarayıcı ya da R sürümünüz.

Gizli ya da şirkete ait veri yüklemeyin. Platform tarayıcınızda çalışır ve verinizi hiçbir yere göndermez; ama issue herkese açıktır.

Yöntemle ilgili sorular (ör. bir kılavuzun nasıl yorumlandığı) issue olarak sorulabilir. Platformdaki her yöntem notu kaynaklarını listeler; lütfen başvurduğunuz kılavuz bölümünü ya da makaleyi belirtin.

### Değişiklik önerme
1. Önce bir issue açıp değişikliği anlatın; yaklaşımda anlaşalım.
2. Depoyu çatallayın (fork), değişikliği bir dalda yapın ve pull request açın.
3. Testleri ekleyin ya da güncelleyin (`CNKfarmastatr/tests/testthat/`). Test kümesi her push'ta GitHub Actions'ta Linux ve Windows'ta koşar ve yeşil kalmalıdır.
4. Validasyonlu istatistik çekirdekleri SHA-256 ile sabitlidir (`CNKfarmastatr/inst/validasyon/CEKIRDEK_SHA256.txt`). Sabitli bir dosyadaki değişiklik; kodlamadan önce kabul ölçütleri kararlaştırılmış bir teknik not, validasyon testlerinin yeniden koşulması ve validasyon belgesinde yeni bir revizyon gerektirir. Bu tür değişiklikleri önce issue'da tartışın.
5. Her yöntem adımı kaynağını taşır (kılavuz ve bölüm ya da makale ve denklem); hiçbir kaynağın tanımlamadığı adım "Tasarım gereği" olarak etiketlenir.

İstatistik çekirdekleri yalnız temel R kullanır. Kod yorumları İngilizcedir; kullanıcıya görünen metinler Türkçe ve İngilizcedir (`web/app/ceviri.json`).

### Davranış
Saygılı ve yapıcı olun. Yöntem üzerine görüş ayrılığı değerlidir; kişisel ifadeler değildir.

## Bakım / Maintainer
Kıvanç Yüksel (kivancyuksel@gmail.com)
