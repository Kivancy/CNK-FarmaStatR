# Chow, Shao ve Wang 2003: in vitro BE testi ve tip I hata tablosunun yeniden üretimi

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.

**Kaynak:** Chow S-C, Shao J, Wang H. In vitro bioequivalence testing. *Statistics in Medicine*
2003;22:55–68. doi:10.1002/sim.1345. (Chow ve Liu 2008 §14.4–14.7 aynı çalışmayı aktarır.)

**Amaç:** Platform dışı literatür kontrolü (FSR-LOG-01 G-123). Platformun PBE hesabı PSG 020929
ölçütünü kullanır (t kantili, θ_P = 2,0891, σ_T0 = 0,1); Chow ve ark. FDA 1999 ölçütünü kullanır
(z kantili, θ_BE = 1,125, σ₀ = 0,2) ve seri düzeyi yoktur. Bu yüzden karşılaştırma ekranda değil,
bu betiklerle yapıldı. Veri, platformun simülasyon üreteciyle (`invitro_fast.R::invitro_gen`; tek
seri, seri varyansı 0) üretildi; test istatistiği makalenin Bölüm 2 formülleriyle yazıldı (`csw2003.R`).

## 1. Sayısal örnek (Bölüm 5, Tablo III) · `csw2003_ornek.R` → `csw2003_ornek.csv`

- Tekrarsız (her kaptan ilk gözlem, FDA 1999 sınırı): δ̂, s²_T, s²_R, U, η̃_U altı ondalıkta yayımlanan
  değerlerle aynı (fark ≤ 7,5 × 10⁻⁷, yuvarlama).
- Tekrarlı (30 kap × 2 tekrar): basılı veriyle δ̂, s²_BR, s²_WR, U ve η̂_U tutmaz. Bulunan üç baskı
  hatası:
  1. Tablo III'te "Test" ve "Reference" sütun başlıkları yer değiştirmiş: δ̂ = −0,268 yalnız
     "Reference" sütunları test alınınca çıkar.
  2. Basılı "Test product, Replicate 2" sütununda 17. satır −0,033335 basılmış; −0,053335 olmalı.
     Tek basamaklı değişikliklerin taranmasında yayımlanan bütün istatistikleri birlikte üreten tek
     değer budur (düzeltmeyle hepsi 10⁻⁶ içinde; en yakın ikinci aday 4 × 10⁻⁵ uzakta).
  3. s²_T = 0,292889 basılmış; s²_BT + s²_WT/2 = 0,197011 + 0,182724/2 = 0,288373 olmalı (makalenin
     kendi bileşenleriyle). U ve η̂_U bu değeri kullanmaz; sonuç etkilenmez.

## 2. Tip I hata (Bölüm 3, Tablo I) · `csw2003_tablo1.R` → `csw2003_tablo1.csv`

16 varyans bileşimi × 6 tasarım = 96 hücre; her hücrede 10 000 tekrar (makaleyle aynı); δ, η = 0
olacak biçimde seçildi (makale Bölüm 3). Seed 20031, Mersenne-Twister / Inversion / Rejection.

| | Makale | CNK-FarmaStatR |
|---|---|---|
| Aralık | 0,0341 – 0,0517 | 0,0308 – 0,0486 |
| Ortalama fark (CNK − makale) | | 0,00018 |
| \|z\| > 2 olan hücre (beklenen ≈ 4,4) | | 4 |
| \|z\| > 3 olan hücre | | 0 |
| Σz² (96 sd) | | 93,7 (p = 0,55) |

z = (CNK − makale) / √(p̂₁(1−p̂₁)/10⁴ + p̂₂(1−p̂₂)/10⁴): iki sonuç da Monte Carlo tahminidir.
Sonuç: Tablo I, Monte Carlo hatası sınırları içinde yeniden üretildi.

**Uygulama notu:** Bölüm 2'de c (referans ölçekli mi, sabit ölçekli mi) yalnız beşinci U teriminde
basılıdır; dördüncü terimde (s⁴_BR) de kullanıldı, çünkü tekrarsız sınırda (s. 57) R terimi
(1 + cθ_BE)² ile yazılır. Tablo I senaryolarında σ²_R ≥ 0,0625 > σ₀² = 0,04 olduğundan c çoğunlukla 1'dir.
