# FSR-TN-PLT-14 · Profil benzerliği raporlarında grafik, bootstrap örnekleri dosyası ve değişkenlik tablosu: kabul ölçütleri

İstek 11052026-a (proje sahibi, 05.11.2026). Donduruldu: 05.11.2026, proje sahibinin onayıyla (“dondur bakalım.”; KK-80, FSR-LOG-01 G-142).
Ölçütler koddan önce donduruldu (KK-45). Bu dosya değiştirilmez; revizyon yeni dosyayla yapılır.

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.

Kararlar: grafik önerisi uygun (1); bootstrap dosyası CSV, isteğe bağlı, iki düzey (değerler / değerler + tablet indeksleri) ve indeksli düzeyde SAS programı (2); değişkenlik benzerliği yalnız gösterilir, eşik yok (3, seçenek i). Kapsam dışı: sınır seçiminde “FDA 1997 yolu” notu; L2a seri sayısı simülasyonu.

## Grafikler (GR)

| No | Ölçüt |
|---|---|
| GR-1 | f2, MSD ve Weibull raporlarında (TR/EN) grafik bölümü: test ve referansın ortalama profilleri, ±SD, %85 çizgisi; analize girmeyen (kesilen) noktalar ayrı işaretli. |
| GR-2 | f2 raporunda ek olarak bootstrap dağılımı: histogram, nokta tahmini, %90 GA sınırları, 50 çizgisi. |
| GR-3 | Weibull raporunda ek olarak gözlenen ortalamalar ve test ile referansın uydurulan Weibull eğrileri. |
| GR-4 | Grafikteki her değer analizde kullanılan değerle aynı; kabul aracı grafik verisini kaydeder, yerel R ile karşılaştırır. |
| GR-5 | Ekran ve rapor aynı çizim fonksiyonunu kullanır; seriler renk dışında işaret ve çizgi tipiyle de ayrılır; etiketler TR/EN. |
| GR-6 | Rapor geçerli Word dosyası, PNG gömülü; tarayıcıda üretilir, dış istek yok; aynı tarayıcıda iki üretim oluşturma zamanı dışında aynı. |
| GR-7 | PBE, EMA ve simülasyon raporları değişmez. |

## Bootstrap dosyası (BS), yalnız f2

| No | Ölçüt |
|---|---|
| BS-1 | İki kutu: “Bootstrap örneklerini indir (CSV)” ve “Çekilen tabletleri ekle (SAS/R ile yeniden hesap için)”; varsayılan boş; ikincisi yalnız birincisi işaretliyken etkin. |
| BS-2 | CSV `#` satırlarıyla künye: seed, RNG, B, tahminci, kesme kuralı ve modu, GA tipi, persentil tipi, paket sürümü, veri SHA-256, ürün adları, tablet sayıları, zaman noktaları, platform sonucu (f2, E(f2), alt, üst). |
| BS-3 | Her replika bir satır: replika no, f2, E(f2), bc-f2, P; değerler R'dekiyle tam duyarlıkta aynı. |
| BS-4 | İndeksli düzeyde test ve referansta çekilen tablet sıra numaraları; tablet adı–sıra numarası eşlemesi künyede. |
| BS-5 | CSV'den tip 7 persentilleri yeniden hesaplanınca rapordaki alt ve üst sınır birebir. |
| BS-6 | İndeksli düzeyle birlikte `.sas` programı: analiz verisi gömülü; indeksli CSV'yi okur, her replikada kesmeyi uygular, f2, E(f2), bc-f2 ve tip 7 persentilleri hesaplar, künyedeki değerlerle karşılaştırır. |
| BS-7 | Program SAS OnDemand'de proje sahibince çalıştırılır: replika değerleri 1e-10 içinde, alt ve üst sınır 2 ondalıkta CSV ile aynı. |
| BS-8 | Dosyalar tarayıcıda üretilir; dış istek yok. |

## Değişkenlik benzerliği (DV)

| No | Ölçüt |
|---|---|
| DV-1 | f2, MSD ve Weibull ekranı ve raporunda her zaman noktası için CV_T, CV_R, CV_T/CV_R; altında EMA Ek I koşulunun alıntısı; eşik ve karar yok. |
| DV-2 | Gösterilen değerler yerel R ile aynı. |

## Gerileme (RG)

| No | Ölçüt |
|---|---|
| RG-1 | testthat, P6, P7, P8 geçer; sabitli çekirdek dosyalar değişmez; yeni satırlar P6 aracına eklenir. |
