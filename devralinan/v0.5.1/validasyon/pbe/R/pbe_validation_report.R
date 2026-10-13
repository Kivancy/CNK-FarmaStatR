# =============================================================================
# CNK-FarmaStatR — PBE modülü · Validasyon belgesi üretici (FSR-VAL-PBE-1)
#   R sonuçları CANLI üretilir (pbe_tests.R). webR ve SAS sonuçları koşu kayıtlarından aktarılır.
# Çalıştırma: setwd(<PBE/R>); source("pbe_validation_report.R")
# =============================================================================
suppressPackageStartupMessages({ library(officer); library(flextable) })
adim <- function(ad, ifade) tryCatch(ifade, error = function(e) stop(sprintf("[CNK-FarmaStatR rapor] '%s' adımında hata: %s", ad, conditionMessage(e)), call. = FALSE))
gerekli <- c("pbe_core.R", "referans_python.R", "pbe_tests.R", "kopru.R", "pbe_ornek_veri.R", "pbe_kopru_tests.R", "test_verisi/P1_psg020929.csv")
eksik <- gerekli[!file.exists(gerekli)]
if (length(eksik)) stop("Eksik dosya(lar): ", paste(eksik, collapse = ", "), "\n  Çalışma klasörü: ", getwd(), call. = FALSE)

BELGE_NO <- "FSR-VAL-PBE-1"; SURUM <- "1.1"
CIKTI <- sprintf("CNK-FarmaStatR_PBE_Validasyon_v%s.docx", SURUM)
SHA_CEKIRDEK <- "e7be66b8e93c79ec3cc78463513db3a2e2d48031dbdc0d41975ed6232426ac65"

adim("Çekirdek ve referans yükleme", { source("pbe_core.R"); source("referans_python.R") })
adim("PBE testleri", invisible(capture.output(source("pbe_tests.R", encoding = "UTF-8"))))
adim("Köprü testleri", { source("kopru.R", encoding = "UTF-8"); source("pbe_ornek_veri.R"); invisible(capture.output(source("pbe_kopru_tests.R", encoding = "UTF-8"))) })
k_top <- nrow(.kt); k_gec <- sum(.kt$durum == "GEÇTİ")
r_son <- .sonuclar; r_top <- nrow(r_son); r_gec <- sum(r_son$durum == "GEÇTİ")
sha256 <- function(f) { if (nzchar(Sys.which("certutil")) && .Platform$OS.type == "windows") {
    o <- system2("certutil", c("-hashfile", shQuote(normalizePath(f)), "SHA256"), stdout = TRUE); tolower(gsub(" ", "", o[2]))
  } else if (nzchar(Sys.which("sha256sum"))) sub(" .*", "", system2("sha256sum", shQuote(f), stdout = TRUE)) else NA_character_ }
sha_cek <- sha256("pbe_core.R")
veri_dosyalari <- sort(list.files("test_verisi", pattern = "\\.csv$"))
veri_sha <- vapply(file.path("test_verisi", veri_dosyalari), sha256, character(1))
p1 <- calc_pbe(read.csv("test_verisi/P1_psg020929.csv"))

# ---- Biçim yardımcıları -------------------------------------------------------------
FONT <- "Calibri"; LACI <- "#1F3864"
p <- function(doc, ...) body_add_fpar(doc, fpar(ftext(paste0(...), fp_text(font.size = 10, font.family = FONT)),
                                                fp_p = fp_par(text.align = "justify", padding.bottom = 4)))
h1 <- function(doc, x) body_add_fpar(doc, fpar(ftext(x, fp_text(font.size = 14, bold = TRUE, color = LACI, font.family = FONT)),
                                               fp_p = fp_par(padding.top = 12, padding.bottom = 4)))
h2 <- function(doc, x) body_add_fpar(doc, fpar(ftext(x, fp_text(font.size = 11.5, bold = TRUE, color = LACI, font.family = FONT)),
                                               fp_p = fp_par(padding.top = 8, padding.bottom = 3)))
formul <- function(doc, x) body_add_fpar(doc, fpar(ftext(x, fp_text(font.size = 10.5, italic = TRUE, font.family = "Cambria Math")),
                                                   fp_p = fp_par(padding.left = 28, padding.bottom = 3)))
tablo <- function(df, gen, sol = 1, boyut = 9) {
  ft <- flextable(df); ft <- theme_box(ft); ft <- font(ft, fontname = FONT, part = "all"); ft <- fontsize(ft, size = boyut, part = "all")
  ft <- bg(ft, bg = LACI, part = "header"); ft <- color(ft, color = "white", part = "header"); ft <- bold(ft, part = "header")
  ft <- width(ft, width = gen); ft <- align(ft, j = sol, align = "left", part = "all"); ft
}
durum_renk <- function(ft, j) { ft <- color(ft, i = ~ Durum == "GEÇTİ", j = j, color = "#2E7D32"); color(ft, i = ~ Durum != "GEÇTİ", j = j, color = "#C62828") }

# ---- Belge ------------------------------------------------------------------------
doc <- read_docx()
doc <- body_set_default_section(doc, prop_section(page_size = page_size(orient = "portrait", width = 21/2.54, height = 29.7/2.54),
  page_margins = page_mar(top = 0.9, bottom = 0.9, left = 0.85, right = 0.85, header = 0.4, footer = 0.4),
  header_default = block_list(fpar(ftext(sprintf("CNK-FarmaStatR · %s · Sürüm %s", BELGE_NO, SURUM), fp_text(font.size = 8, color = "#555555", font.family = FONT)), fp_p = fp_par(text.align = "right"))),
  footer_default = block_list(fpar(ftext("Sayfa ", fp_text(font.size = 8, font.family = FONT)), run_word_field("PAGE", prop = fp_text(font.size = 8, font.family = FONT)), fp_p = fp_par(text.align = "center")))))
kp <- function(doc, x, s, b = FALSE, it = FALSE, col = "black", top = 0, bot = 0)
  body_add_fpar(doc, fpar(ftext(x, fp_text(font.size = s, bold = b, italic = it, color = col, font.family = FONT)), fp_p = fp_par(text.align = "center", padding.top = top, padding.bottom = bot)))
doc <- kp(doc, "CNK-FarmaStatR", 26, TRUE, col = LACI, top = 70)
doc <- kp(doc, "Farmasötik İstatistik Ekosistemi", 13, col = "#555555", bot = 36)
doc <- kp(doc, "YAZILIM VALİDASYON BELGESİ", 18, TRUE)
doc <- kp(doc, "PBE Modülü · Population Bioequivalence", 14)
doc <- kp(doc, "FDA PSG_020929 (Aralık 2025) · PSG_020121 (Aralık 2025) · PSG_021433 · PSG_205625", 10.5, it = TRUE, bot = 30)
kapak <- data.frame(Alan = c("Belge no", "Sürüm / tarih", "Validasyonu yapılan yazılım", "SHA-256 (pbe_core.R)",
                             "Bağımsız doğrulama", "Genel sonuç"),
  Değer = c(BELGE_NO, paste(SURUM, "/", format(Sys.Date(), "%d.%m.%Y")),
            "pbe_core.R — PBE_webr_v05_3.html içindeki R kodunun bayt bayt kopyası (calc_pbe)",
            SHA_CEKIRDEK, "Python (pbe_referans.py) · SAS 9.4 (pbe_validation.sas v0.1, PROC SQL + DATA adımı) · webR 0.4.3",
            sprintf("Çekirdek — R: %d/%d · webR: 213/213 · SAS: 177/177 GEÇTİ · Köprü — R: %d/%d · webR: 25/25 GEÇTİ", r_gec, r_top, k_gec, k_top)), stringsAsFactors = FALSE)
ft <- tablo(kapak, c(2.1, 4.7)); ft <- bold(ft, j = 1); doc <- body_add_flextable(doc, ft, align = "center")
doc <- p(doc, "")
doc <- body_add_fpar(doc, fpar(ftext("Bu belge, düzenlemeye tabi kullanıcının kendi validasyonunu desteklemek amacıyla hazırlanmıştır. Yazılımın belirli bir GMP sürecindeki kullanımına ilişkin nihai değerlendirme kullanıcı kuruluşa aittir.",
  fp_text(font.size = 9, italic = TRUE, color = "#444444", font.family = FONT)), fp_p = fp_par(text.align = "center")))
rev <- data.frame(Sürüm = c("1.0", "1.1"), Değişiklik = c("İlk sürüm. Kanonik çekirdeğin ayrıştırılması; TC-P1 … TC-P6; R, webR, Python ve SAS doğrulaması.",
  "Düzeltme: PSG_020121 künyesi (güncel sürüm Aralık 2025; v1.0'da Şubat 2019 yazılmıştı, teknik içerik etkilenmedi). Kapsam: PSG_021433 ve PSG_205625 PBE için PSG_020929'a atıf yapar. Ek: arayüz köprüsü (kopru.R) ve TC-K1 … TC-K4; B-2 ve B-4 kapatıldı."), stringsAsFactors = FALSE)
doc <- body_add_flextable(doc, tablo(rev, c(0.8, 6)), align = "center")
doc <- body_add_break(doc)

doc <- h1(doc, "1. Amaç ve kapsam")
doc <- p(doc, "Bu belge, CNK-FarmaStatR PBE modülünün hesap çekirdeğinin (pbe_core.R, calc_pbe) FDA PSG_020929 Appendix'inde tanımlanan ",
         "population bioequivalence (PBE) hesabını doğru uyguladığını belgeler. Kapsam: ortalama ve kareler ortalamaları (MSB, MSW); ",
         "E, H ve U bileşenleri; referans ve sabit ölçekli ölçütler; σR ile ölçüt seçimi; karar; tek aşama (m = 1); dengesiz tasarım; ",
         "modified one-sided PBE (PSG_020121); log dönüşümü; parti + kap gruplaması; girdi hatalarının yakalanması.")
doc <- p(doc, "Kapsam ayrıca arayüz köprüsünü (kopru.R: girdi dönüşümü ve kontrolleri) içerir (Ek-D). PSG_021433 ve PSG_205625 PBE analizi için PSG_020929'a atıf yaptığından, ",
         "bu PSG'lerin PBE çalışmaları da kapsamdadır. Kapsam dışı: platform katmanı (FSR-VAL-PLT ile ele alınacaktır); σT0 ve θP'nin farklı olduğu ürünler; GMR ve f2 çalışma tipleri.")

doc <- h1(doc, "2. Dayanaklar")
day <- data.frame(Kısaltma = c("PSG929", "PSG121", "PSG1433", "PSG5625", "v0.5"),
  Kaynak = c("FDA. Draft Guidance on Budesonide (inhalation suspension), PSG_020929, Aralık 2025.",
             "FDA. Draft Guidance on Fluticasone Propionate (nasal spray, metered), PSG_020121, Aralık 2025 (Recommended Eylül 2015; Revised Şubat 2019, Haziran 2020, Mayıs 2023, Aralık 2025).",
             "FDA. Draft Guidance on Fluticasone Propionate (inhalation aerosol, metered), PSG_021433, Ağustos 2024.",
             "FDA. Draft Guidance on Fluticasone Furoate (inhalation powder), PSG_205625, Ekim 2025.",
             "CNK-FarmaStatR PBE v0.5 (webR) — PSG_020929 örneğiyle doğrulama (önceki çalışma)."),
  `İlgili bölüm` = c("Appendix: PBE adımları, örnek veri ve örnek sonuçlar; σR ≤ σT0 ise sabit ölçekli",
                     "Appendix: PBE modified to be one-sided; μT ≥ μR geleneksel PBE, μT < μR ortalama farkı terimi dışarıda; θp = 2.0891",
                     "PBE analizi için PSG_020929'a atıf (\"Refer to the most recent version…\")", "PBE analizi için PSG_020929'a atıf",
                     "PSG örneği ile 13 parametrenin iki ölçekte doğrulanması"), check.names = FALSE, stringsAsFactors = FALSE)
doc <- body_add_flextable(doc, tablo(day, c(0.9, 3.4, 2.5)))

doc <- h1(doc, "3. Yazılım tanımı")
doc <- p(doc, sprintf(paste0("Validasyonu yapılan dosya pbe_core.R'dir. Dosya, PBE_webr_v05_3.html içindeki R_CALC_PBE bloğunun, Windows satır sonları ",
  "(CRLF) dahil bayt bayt kopyasıdır. Beklenen SHA-256: %s. Bu koşuda hesaplanan: %s (%s)."), SHA_CEKIRDEK,
  ifelse(is.na(sha_cek), "hesaplanamadı", sha_cek), ifelse(identical(sha_cek, SHA_CEKIRDEK), "EŞLEŞTİ", "KONTROL EDİN")))
fark <- data.frame(Özellik = c("Bağımlılık", "Log dönüşümü", "Modified one-sided PBE", "Stage uyum kontrolü", "Dengesiz tasarımda payda"),
  `Shiny app.R (emekli)` = c("dplyr paketi", "yok", "yok", "yok", "ilk partinin kap sayısı × l"),
  `pbe_core.R (kanonik)` = c("yalnızca temel R", "var", "var", "var", "toplam kap sayısı"), check.names = FALSE, stringsAsFactors = FALSE)
doc <- body_add_flextable(doc, tablo(fark, c(2, 2.4, 2.4)))
doc <- p(doc, "Kanonik çekirdek, çerçevenin \"yalnızca temel R\" ilkesine uyduğu ve v0.5 düzeltmelerini içerdiği için seçilmiştir. Shiny sürümü emekliye ayrılmıştır.")

doc <- h1(doc, "4. Matematiksel model (PSG_020929 Appendix)")
doc <- p(doc, "Kap = parti + kap numarası; m = kap başına aşama sayısı; N = toplam kap sayısı; ȳ_k kap ortalaması, ȳ genel ortalama.")
doc <- formul(doc, "MSB = m·Σ(ȳ_k − ȳ)² / (N − 1)      MSW = ΣΣ(y − ȳ_k)² / (N·(m − 1)),  m = 1 ise 0")
doc <- formul(doc, "σ² = MSB/m + (m − 1)·MSW/m      θP = ((ln 1.11)² + 0.01)/σT0² = 2.0891,  σT0 = 0.1")
doc <- formul(doc, "E_D = (μT − μR)²;  E1 = MSB_T/m;  E2 = MSW_T(m−1)/m;  E3s = −(1+θP)MSB_R/m;  E4s = −(1+θP)MSW_R(m−1)/m")
doc <- formul(doc, "H_D = (|μT − μR| + t₀.₉₅,N_T+N_R−2 · √(MSB_T/(N_T m) + MSB_R/(N_R m)))²;  H1, H3: χ² (N − 1 sd);  H2, H4: χ² (N(m−1) sd)")
doc <- formul(doc, "Eq = ΣE;  Uq = Σ(H − E)²;  Hη = Eq + √Uq;  σR > σT0 → referans ölçekli, aksi halde sabit ölçekli;  Hη ≤ 0 → PASS")
doc <- p(doc, "Modified one-sided PBE (PSG121): μT < μR ise E_D = H_D = U_D = 0. Dengesiz tasarımda N olarak toplam kap sayısı kullanılır; ",
         "dengeli tasarımda PSG'deki n·l ile özdeştir. Dengesiz tasarım genellemesi bir FarmaStatR türetimidir.")

doc <- h1(doc, "5. Validasyon stratejisi")
str_ <- data.frame(Yol = c("Yayımlanmış (Y)", "Bağımsız Python (B)", "Analitik (A)", "webR", "SAS"),
  Açıklama = c("PSG_020929'un 27 örnek sonucu ve σR²; PSG değerleri 6 anlamlı basamakla basıldığı için göreli tolerans 5×10⁻⁵",
               "pbe_referans.py: PSG Appendix adımlarından yazılmış, R kodundan kopyalanmamış uygulama; mutlak tolerans 10⁻¹⁰",
               "Tasarım sabitleri, sıfır olması gereken terimler, dönüşüm ve yeniden numaralandırma değişmezlikleri, hata yakalama",
               "Aynı test seti dağıtım motorunda (webR 0.4.3, R 4.4.2)",
               "PROC SQL + DATA adımıyla yeniden kurulmuş hesap (IML kullanılmadan); 27 Y + 150 B kontrol"), stringsAsFactors = FALSE)
doc <- body_add_flextable(doc, tablo(str_, c(1.6, 5.2)))
doc <- p(doc, "")
tcs <- data.frame(TC = paste0("TC-P", 1:6),
  Konu = c("PSG_020929 örneği (180 gözlem): 27 değer, σR², ölçüt, karar; tek yönlü seçenek μT > μR iken etkisiz",
           "Tek aşama (m = 1): MSW, E2, E4, H2, H4, U2, U4 = 0; σR = √MSB_R",
           "Dengesiz tasarım (28 ve 29 kap); denge bayrakları",
           "Modified one-sided PBE: μT < μR iken E_D = H_D = U_D = 0; diğer terimler iki yönlüyle aynı",
           "exp(veri) + log dönüşümü = PSG sonucu; kap numaralarının her partide 1–10 olması; Stage uyuşmazlığı, negatif değer, boş grup hataları",
           "σR = σT0 (kayan noktada tam eşit) → sabit ölçekli; σR = 0.10001 → referans ölçekli"),
  Veri = c("P1_psg020929", "P2_m1", "P3_dengesiz", "P4_tekyon_aktif", "P5_*", "P6_sinir_*"), stringsAsFactors = FALSE)
doc <- body_add_flextable(doc, tablo(tcs, c(0.7, 4.6, 1.5), sol = 1:3))

doc <- h1(doc, "6. Sonuçlar")
oz <- aggregate(durum ~ TC + kaynak, r_son, function(x) sprintf("%d/%d", sum(x == "GEÇTİ"), length(x)))
oz <- reshape(oz, idvar = "TC", timevar = "kaynak", direction = "wide"); names(oz) <- sub("durum.", "", names(oz)); oz[is.na(oz)] <- "—"
doc <- body_add_flextable(doc, tablo(oz[, c("TC", intersect(c("Y", "B", "A"), names(oz)))], c(1.2, 1.2, 1.2, 1.2)))
doc <- p(doc, "")
ozet <- data.frame(Ortam = c("R (bu koşu)", "webR 0.4.3 (R 4.4.2)", "SAS 9.4 (pbe_validation.sas v0.1)"),
  Sonuç = c(sprintf("%d/%d GEÇTİ", r_gec, r_top), "213/213 GEÇTİ", "177/177 GEÇTİ (Y 27/27, B 150/150)"),
  Not = c(sprintf("%s; en büyük göreli fark (Y) %.2e", R.version.string, max(r_son$fark[r_son$kaynak == "Y"], na.rm = TRUE)),
          "Hη_Ref (P1) yerel R ile 15 basamağa kadar aynı: −0.031498739318481", "Kullanıcı ortamında, ilk koşuda"), stringsAsFactors = FALSE)
doc <- body_add_flextable(doc, tablo(ozet, c(2, 2, 2.8), sol = 1:3))
doc <- h2(doc, "6.1 PSG_020929 karşılaştırması (seçilmiş değerler)")
sec <- data.frame(Nicelik = c("Eq (referans ölçekli)", "Uq (referans ölçekli)", "Hη (referans ölçekli)", "Hη (sabit ölçekli)", "σR", "Ölçüt / karar"),
  PSG = c("−0.26389584", "0.054008421", "−0.031498721", "0.232736764", "√0.163727878 = 0.404633", "Reference-scaled / PASS"),
  `CNK-FarmaStatR` = c(sprintf("%.9f", p1$Eq_Ref), sprintf("%.9f", p1$Uq_Ref), sprintf("%.9f", p1$H_eta_Ref), sprintf("%.9f", p1$H_eta_Const),
                       sprintf("%.6f", p1$Sigma_R), paste(p1$criterion, "/", p1$pass_fail)), check.names = FALSE, stringsAsFactors = FALSE)
doc <- body_add_flextable(doc, tablo(sec, c(2.2, 2.3, 2.3), sol = 1:3))
doc <- h2(doc, sprintf("6.2 R sonuçlarının tam listesi (%d kontrol)", r_top))
tam <- data.frame(TC = r_son$TC, Kontrol = r_son$kontrol, Kaynak = r_son$kaynak,
  Beklenen = formatC(r_son$beklenen, digits = 9, format = "g"), Hesaplanan = formatC(r_son$hesaplanan, digits = 9, format = "g"),
  Fark = ifelse(is.na(r_son$fark), "—", formatC(r_son$fark, digits = 2, format = "e")), Durum = r_son$durum, stringsAsFactors = FALSE)
ft <- tablo(tam, c(0.55, 2.3, 0.5, 1.1, 1.1, 0.75, 0.55), sol = 1:2, boyut = 7.5); ft <- durum_renk(ft, 7)
doc <- body_add_flextable(doc, ft)

doc <- h1(doc, "7. Geliştirme sırasında elde edilen bulgular")
bul <- data.frame(No = paste0("B-", 1:6),
  Bulgu = c("v05_3'te eklenen parti + kap gruplaması PSG verisiyle sınanamaz: PSG'de kap numaraları tüm veride benzersizdir. TC-P5 bu boşluğu kap numaralarını her partide 1–10 olarak yeniden numaralandırarak kapatır.",
            "Çekirdek, kap başına eksik ya da tekrarlı aşama ölçümünü kontrol etmez; MSB formülü her kapta tam m ölçüm varsayar. v1.1: kapatıldı — köprü eksik ya da tekrarlı ölçümde hesabı reddeder (TC-K3); çekirdeğin bu durumda hata vermediği ayrıca gösterilmiştir.",
            "σT0 = 0.1 ve θP sabit kodludur; PSG_020929 ve PSG_020121 için doğrudur. Farklı değer öngören ürünlerde modül kullanılmamalıdır.",
            "GM_T, GM_R ve GMR log dönüşümü kapalıyken de hesaplanır ve bu durumda anlamsızdır; v1.1: kapatıldı — köprü, log dönüşümü kapalıyken bu alanları sonuçtan çıkarır (TC-K1, TC-K2).",
            "Dengesiz tasarımda toplam kap sayısının kullanılması FarmaStatR türetimidir; dengeli tasarımda PSG ile özdeştir (TC-P1, TC-P3).",
            "PSG örnek sonuçları 6 anlamlı basamakla basılmıştır; en büyük göreli farklar (≈ 2×10⁻⁵) en küçük değerlerde (E4, U4) görülür. Y toleransı buna göre belirlenmiştir."),
  stringsAsFactors = FALSE)
doc <- body_add_flextable(doc, tablo(bul, c(0.55, 6.25), sol = 1:2))
doc <- h1(doc, "8. Sapma kaydı")
doc <- p(doc, "Bu validasyon döngüsünde sapma kaydedilmemiştir. SAS programı ilk koşuda hatasız çalışmıştır.")
doc <- h1(doc, "9. Kullanım sınırlamaları")
doc <- p(doc, "(1) Modül PSG_020929 ve PSG_020121'deki PBE tanımı için doğrulanmıştır (σT0 = 0.1, θP = 2.0891). (2) Her kapta her aşamada tam bir ölçüm ",
         "bulunmalıdır. (3) Dengesiz tasarım desteklenir; bu genelleme protokolde belirtilmelidir. (4) Log dönüşümünün uygulanıp uygulanmayacağı ilgili PSG'ye göre ",
         "önceden tanımlanmalıdır. (5) Modified one-sided PBE yalnızca bunu öngören PSG'lerde seçilmelidir.")
doc <- h1(doc, "10. Sonuç")
doc <- p(doc, sprintf(paste0("pbe_core.R, tanımlanan kapsamda R ortamında %d/%d, webR ortamında 213/213 ve bağımsız SAS uygulamasında 177/177 kontrolü geçmiştir. ",
  "PSG_020929'un yayımladığı tüm örnek sonuçlar PSG'nin basamak hassasiyetinde üretilmiştir. Modül, bölüm 9'daki sınırlamalar ve bölüm 7'deki açık maddeler ",
  "arayüzde ele alınmak koşuluyla kullanıma uygundur."), r_gec, r_top))
doc <- h2(doc, "Onay")
onay <- data.frame(Rol = c("Hazırlayan", "Gözden geçiren", "Onaylayan"), `Ad Soyad` = "", İmza = "", Tarih = "", check.names = FALSE)
ft <- tablo(onay, c(1.5, 2.2, 1.6, 1.4)); ft <- height_all(ft, 0.45); doc <- body_add_flextable(doc, ft)

doc <- body_add_break(doc)
doc <- h1(doc, "Ek-A · Ortam")
ort <- data.frame(Bileşen = c("R", "Platform", "İşletim sistemi", "webR", "SAS", "Python", "Belge üretimi"),
  Sürüm = c(R.version.string, R.version$platform, utils::sessionInfo()$running, "webR 0.4.3 (R 4.4.2), Node.js üzerinde",
            "SAS 9.4 (kullanıcı ortamı)", "Python 3 + SciPy (geliştirme ortamı)",
            sprintf("officer %s, flextable %s", packageVersion("officer"), packageVersion("flextable"))), stringsAsFactors = FALSE)
doc <- body_add_flextable(doc, tablo(ort, c(1.6, 5.2)))
doc <- h1(doc, "Ek-B · Test verisi dosyaları")
tv <- data.frame(Dosya = veri_dosyalari, `SHA-256` = unname(veri_sha), check.names = FALSE, stringsAsFactors = FALSE)
doc <- body_add_flextable(doc, tablo(tv, c(1.9, 4.9), boyut = 8))
doc <- p(doc, "Test verisi test_verisi_olustur.R ile PSG örneğinden deterministik dönüşümlerle üretilir; PSG örneği PSG_020929 Appendix'ten ayıklanmıştır (180 satır).")
doc <- h1(doc, "Ek-D · Arayüz köprüsü testleri (kopru.R)")
doc <- p(doc, "Köprü, arayüzden gelen sütunları çekirdeğin beklediği biçime getirir ve çekirdeği değiştirmeden çağırır. Ana ilke: köprü üzerinden hesap, çekirdeğin doğrudan çağrısıyla birebir aynıdır; hatalı girdi reddedilir.")
kd <- data.frame(TC = .kt$TC, Kontrol = .kt$kontrol, Durum = .kt$durum, stringsAsFactors = FALSE)
ft <- tablo(kd, c(0.7, 5.3, 0.8), sol = 1:2, boyut = 8); ft <- durum_renk(ft, 3); doc <- body_add_flextable(doc, ft)
doc <- p(doc, sprintf("Toplam %d kontrol; GEÇTİ %d. Aynı test seti webR 0.4.3 (R 4.4.2) ortamında da 25/25 geçmiştir.", k_top, k_gec))
doc <- h1(doc, "Ek-C · Doğrulanan kaynak kod (pbe_core.R)")
kod <- readLines("pbe_core.R", warn = FALSE)
for (s in kod) doc <- body_add_fpar(doc, fpar(ftext(ifelse(nzchar(s), s, " "), fp_text(font.size = 7, font.family = "Consolas")),
                                               fp_p = fp_par(padding.top = 0, padding.bottom = 0)))
print(doc, target = CIKTI)
cat("Belge üretildi:", normalizePath(CIKTI), sprintf("| R: %d/%d\n", r_gec, r_top))
