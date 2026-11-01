# Tsong ve ark. 1996, Tablo 1: REF tablet 4, 30. dakika (78.54 → 78.45)

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.

**Kaynak:** Tsong Y, Hammerstrom T, Sathe P, Shah VP. Statistical assessment of mean differences
between two dissolution data sets. *Drug Information Journal* 1996;30:1105–1112, Tablo 1.

**Bulgu:** Tablo 1'deki referans tablet 4, 30. dakika değeri 78.54 basılmıştır; makalenin yayımladığı
Mahalanobis uzaklığı (D_M = 26.49), %90 güven bölgesi (19.65, 33.32) ve Hotelling T² (2104.46) yalnız
78.45 ile elde edilir (basamak yer değiştirmesi). Bulgu v0.5.1'den devralındı (FSR-LOG-01 G-01);
paket testi `CNKfarmastatr/inst/validasyon/dissolusyon/msd_tests.R` (TC-2, TC-2e).

**Bağımsız doğrulama (FSR-LOG-01 G-119):** DDSolver (Zhang ve ark. 2010), Dissolution Profile
Comparison > Multivariate Confidence Region; proje sahibinin bilgisayarında koşuldu, 01.11.2026.

| Veri | Araç | Hotelling T² | D_M | %90 GB alt | %90 GB üst |
|---|---|---|---|---|---|
| Basılı (78.54) | DDSolver | 2195.8049 | 27.0543 | 20.2219 | 33.8867 |
| Basılı (78.54) | CNK-FarmaStatR | 2195.80 | 27.0543 | 20.2219 | 33.8867 |
| Düzeltilmiş (78.45) | DDSolver | 2104.4637 | 26.4856 | 19.6532 | 33.3180 |
| Düzeltilmiş (78.45) | CNK-FarmaStatR | 2104.46 | 26.4856 | 19.6532 | 33.3180 |
| — | Tsong 1996 (yayımlanan) | 2104.46 | 26.49 | 19.65 | 33.32 |

DDSolver ayrıca K = 0.1125 ve F(8, 3; 0.90) = 5.2517 bildirir. DDSolver'ın benzerlik sınırı (Max_MSD)
iki veri setinde farklıdır (19.4272 ve 19.7076), çünkü referans verisinden türetilir; bu karşılaştırma
yalnız D_M, T² ve güven bölgesi içindir.

Dosyalar: `Tsong1996_DDSolver_karsilastirma.xlsx` (iki veri seti ve beklenen sonuçlar),
`ddsolver_yayimlanan_7854.png`, `ddsolver_duzeltilmis_7845.png` (DDSolver çıktı ekranları).
Veriler Tsong ve ark. 1996'ya aittir (`LICENSE-belgeler.md`).
