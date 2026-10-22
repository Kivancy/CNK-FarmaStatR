# CNK-FarmaStatR · Yardım sistemi / Help system

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.
For research and education; not a system validated for GxP environments.

Kaynak / source: FSR-TN-PLT-07 (KK-63).

## TR

Üç düzey:

1. **Alan ipuçları:** ekranlardaki her girdinin yanında “?” düğmesi. Metinler `yardim.json` → `ipucu`
   (anahtar `<ekran>.<alan>`, ör. `pbe.log_d`). Ekranlarda etiketler `data-help` ile işaretlidir.
2. **Yardım paneli:** başlıktaki “Yardım” düğmesi; açık sekmenin yardımı (Ne yapar · Veri ve girdiler ·
   Ayarlar · Sonucu okuma · Sınırlar · Kaynaklar). Metinler `yardim.json` → `panel`.
3. **Yöntem notları:** `yontem/` (PBE, EMA %90 GA, f2 ve bootstrap f2, MSD, Weibull MSD, simülasyon ve tasarım
   seçimi). Kaynakları `kaynak/<not>.txt`; HTML `araclar/yardim_derle.py` ile üretilir
   (`python3 araclar/yardim_derle.py`; gerekli: `pip install latex2mathml`). Üretilen HTML’i elle
   değiştirmeyin; kaynağı değiştirip yeniden derleyin.

Örnek CSV dosyaları `sablon/` klasöründedir (Excel Türkçe: `;` ve ondalık virgül; uluslararası: `,`).

**Metin değiştirme kuralları:** TR ve EN aynı anahtarlarla güncellenir. Notlarda her denklem satırı
`$$ … $$ :: kaynak` biçimindedir; kaynak etiketi zorunludur (kılavuz ya da makale + madde/denklem,
ya da “FarmaStatR türetimi”). Çalışılmış örnek sayıları `[[kimlik|değer]]` ile yazılır ve
`belgeler/teknik_notlar/FSR-TN-PLT-07_ek/p7_kabul.R` bunları yerel R çıktısıyla karşılaştırır.

Kabul aracı: `kabul7.html` (iç kullanım).

## EN

Three levels: field hints (“?” next to every input; `yardim.json` → `ipucu`), a help panel per screen
(“Help” button; `yardim.json` → `panel`) and method notes (`yontem/`, built from `kaynak/*.txt` by
`araclar/yardim_derle.py`). CSV templates are in `sablon/`. Every equation in the notes carries its
source or the label “FarmaStatR derivation”; the numbers of the worked examples are checked against
local R by `p7_kabul.R`.
