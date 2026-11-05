# FSR-TN-PLT-12 · Dissolüsyon verisi için geniş biçim: kabul ölçütleri

Donduruldu: 04.11.2026, proje sahibinin onayıyla (“donduralım.”; KK-78, FSR-LOG-01 G-139).
Ölçütler koddan önce donduruldu (KK-45). Bu dosya değiştirilmez; revizyon yeni dosyayla yapılır.

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.

| No | Ölçüt |
|---|---|
| W-0 | Kapsam: geniş biçim yalnız dissolüsyon profili benzerliği panelinde okunur. PBE ve EMA panelleri G-138 sonrasındaki hâliyle kalır (Türkçe şablon kaldırılmış; okuyucu, uluslararası şablon, yardım metni ve sonuçlar değişmemiş). P6'daki PBE/EMA satırları ve P8 aynen geçer; geniş biçimli bir dosya PBE paneline yüklenirse bugünkü “eksik sütun” hatası verilir. |
| W-1 | Tanıma: ilk sütun adı zaman bildirir (Time, Zaman, Dakika, Saat, Minute) ve diğer bütün sütunlar `<ürün>.<kap>` ise geniş biçim; `Product, Unit, Time, Diss` varsa bugünkü uzun biçim aynen okunur; ikisine de uymayan dosya, bulunan sütunları sayan anlaşılır bir hata verir. |
| W-2 | Ürün/kap: sütun adı son noktadan bölünür (`Ref.A.3` → ürün `Ref.A`, kap `3`); ürün ya da kap kısmı boşsa hata. |
| W-3 | Ayraç: `,` `;` sekme ve ondalık virgül bugünkü kuralla okunur. |
| W-4 | DDSolver ikinci başlık satırı (`(min)`, `F(%)`): içinde hiç sayı olmayan ilk veri satırı atlanır. Tasarım gereği. |
| W-5 | Boş ya da sayı olmayan hücre: hata; mesaj sütun adını ve zamanı söyler. Sessizce atılmaz. |
| W-6 | Yinelenen sütun adı ya da yinelenen zaman: hata. |
| W-7 | Varsayılan test/referans seçimi: adı test olan ürün test, ref/reference/referans olan referans (büyük-küçük harf duyarsız); yoksa ilk iki ürün. Tasarım gereği. |
| W-8 | Birebir eşdeğerlik: Tsong 1996 ve Noce 2020 verisi geniş biçime çevrilip yüklendiğinde f2, bootstrap f2, MSD (L1, L2a) ve Weibull MSD sonuçları uzun biçimle `identical`. |
| W-9 | Rapor Bölüm 9 (kaynak, SHA-256, isteğe bağlı tablo) çalışır; tablo, analizde kullanılan hâliyle uzun biçimde gösterilir. |
| W-10 | Şablon: `dis_sablon_en.csv` geniş biçime çevrilir (Tsong verisi; `Time, Test.1…Test.6, Ref.1…Ref.6, STD1.1…STD1.6, STD2.1…STD2.6`). |
| W-11 | Panel yardımı (TR/EN) geniş biçimi anlatır ve uzun biçimin de kabul edildiğini söyler. |
| W-12 | Gerileme: testthat, P6, P7, P8 geçer; P7'nin şablon satırları yeni biçime göre revize edilir ve kayda geçer. |
