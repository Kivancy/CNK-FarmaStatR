# FSR-TN-PLT-15 · Simülasyon raporlarında ve betiklerinde düzenleyici sabitler: kabul ölçütleri

Proje sahibinin tespiti (06.11.2026): raporda σR = 0,12 ve ρ = 1 yazarken dışa aktarılan betikte `sigma_T0 = 0.1` görünüyor.
Yanıt: σT0, PSG 020929'da (2025, Ek A Adım 1 ve 3) “regulatory constant (σT0 = 0.1)” olarak geçen sabit eşiktir; test ürününün SD'si değildir. Simge kılavuzdaki gibi σT0 olarak kalır (proje sahibinin sorusu: “σ0 mı desen?”; kılavuz σT0 yazar; Chow ve Liu 2008 de σT0).
Karar ve yetki: “Aç ve bitir.” (KK-83, FSR-LOG-01 G-147). Ölçütler bu yetkiyle koddan önce donduruldu (KK-45). Bu dosya değiştirilmez.

Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.

| No | Ölçüt |
|---|---|
| C-1 | Simülasyon raporlarında (tek koşu: hazır ve canlı; tasarım seçimi) Bölüm 3'te “Düzenleyici sabitler” alt tablosu (TR/EN): α = 0,05 (PSG 020929 Ek A Adım 4), σT0 = 0,1 (Ek A Adım 1 ve 3; test ürününün SD'si değildir), θp = 2,0891 (Ek A Adım 1), EMA sınırları 0,85–1,18 (CPMP/EWP/4151/00 Rev. 2, 5.1 ölçüt 8). |
| C-2 | Dışa aktarılan senaryo betiğinde `alpha`, `sigma_T0`, `ema_limits` `params` içinde kalır (koşu kaydı değişmez) ama ayrı bir yorum bloğuyla: düzenleyici sabitler; `sigma_T0` test SD'si değildir; değiştirilirse sonuç kılavuz ölçütü olmaz. Tasarım betiğinde motorun kullandığı sabitler bilgi yorumu olarak yazılır. |
| C-3 | Hesap değişmez: betikler aynı koşuyu üretir (testthat E-1 … E-9 ve tasarım betiği testleri geçer); sabitli dosyalar değişmez. |
| C-4 | Analiz raporları (PBE, EMA, dissolüsyon) ve ekranlar değişmez. |
| C-5 | Gerileme: testthat, P5 kabul aracı, P6 (F-10 revize: P5 raporunda yalnız sabitler bloğu eklenir, geri kalan paragraflar aynı). |
