# =============================================================================
# FarmaStatR — Teknik Not FSR-TN-DIS-01
# Tsong ve ark. 1996, REF tablet 4, 30. dakika: 78.54 (basılı) ile 78.45 (düzeltilmiş)
# Tek bir veri değerinin Mahalanobis uzaklığı (D_M) ve Hotelling T² üzerindeki etkisi
#
# Bu betik tüm sayıları kendi içinde yeniden hesaplar ve Word belgesini üretir.
# Gereken dosyalar (aynı klasörde): msd_core.R, dis_ornek_veri.R
# Çalıştırma: source("tsong_duyarlilik_notu.R")
# =============================================================================
suppressPackageStartupMessages({ library(officer); library(flextable) })
source("msd_core.R", encoding = "UTF-8"); source("dis_ornek_veri.R", encoding = "UTF-8")

BELGE_NO <- "FSR-TN-DIS-01"; SURUM <- "1.0"
CIKTI <- sprintf("FarmaStatR_TeknikNot_Tsong1996_REF4_30dk_v%s.docx", SURUM)

# ---- 1. Veri --------------------------------------------------------------------
ts <- ornek_tsong(); zaman <- c(5, 10, 15, 20, 30, 60, 90, 120)
mat <- function(u) { a <- ts[ts$Product == u, ]; tapply(a$Diss, list(a$Unit, a$Time), identity)[, as.character(zaman)] }
T <- mat("TEST"); R_duz <- mat("REF"); R_bas <- R_duz; R_bas[4, "30"] <- 78.54
n <- 6; P <- 8; k <- 5; eps <- 78.54 - 78.45

# ---- 2. Hesap (her iki veri için ayrı ayrı) ----------------------------------------------
hesapla <- function(R) {
  S <- ((n - 1) * cov(T) + (n - 1) * cov(R)) / (2 * n - 2)
  d <- colMeans(T) - colMeans(R); w <- drop(solve(S, d)); D2 <- sum(d * w)
  e <- eigen(S, symmetric = TRUE); a <- drop(t(e$vectors) %*% d)
  v8 <- e$vectors[, 8]; if (v8[5] > 0) { v8 <- -v8; a[8] <- -a[8] }     # işaret yönü sabitlensin
  m <- calc_msd(T, R, limit = "L1", Dg = 15)                             # validasyonlu motor
  list(R = R, S = S, d = d, w = w, D2 = D2, lam = e$values, a = a, v8 = v8, u = R[4, ] - colMeans(R),
       katki = a^2 / e$values, m = m)
}
B <- hesapla(R_bas); D <- hesapla(R_duz)
stopifnot(abs(sqrt(D$D2) - D$m$DM) < 1e-10, abs(sqrt(B$D2) - B$m$DM) < 1e-10)

# Pertürbasyon terimleri (düzeltilmiş veriden basılı veriye)
A  <- -2 * (eps / n) * D$w[k]
B1 <- -(2 * eps * sum(D$u * D$w) * D$w[k]) / (2 * n - 2)
B2 <- -(eps^2 * ((n - 1) / n) * D$w[k]^2) / (2 * n - 2)
ek <- replace(numeric(P), k, 1)
dS_formul <- (eps * (outer(D$u, ek) + outer(ek, D$u)) + eps^2 * ((n - 1) / n) * outer(ek, ek)) / (2 * n - 2)
stopifnot(max(abs(dS_formul - (B$S - D$S))) < 1e-12)

# ---- 3. Biçim yardımcıları ---------------------------------------------------------------
FONT <- "Calibri"; LACI <- "#1F3864"
p  <- function(doc, ...) body_add_fpar(doc, fpar(ftext(paste0(...), fp_text(font.size = 10, font.family = FONT)),
                                                 fp_p = fp_par(text.align = "justify", padding.bottom = 4)))
pi_ <- function(doc, ...) body_add_fpar(doc, fpar(ftext(paste0(...), fp_text(font.size = 9.5, italic = TRUE, color = "#444444", font.family = FONT)),
                                                  fp_p = fp_par(padding.left = 20, padding.bottom = 4)))
h1 <- function(doc, x) body_add_fpar(doc, fpar(ftext(x, fp_text(font.size = 14, bold = TRUE, color = LACI, font.family = FONT)),
                                               fp_p = fp_par(padding.top = 12, padding.bottom = 4)))
h2 <- function(doc, x) body_add_fpar(doc, fpar(ftext(x, fp_text(font.size = 11.5, bold = TRUE, color = LACI, font.family = FONT)),
                                               fp_p = fp_par(padding.top = 8, padding.bottom = 3)))
formul <- function(doc, x) body_add_fpar(doc, fpar(ftext(x, fp_text(font.size = 10.5, italic = TRUE, font.family = "Cambria Math")),
                                                   fp_p = fp_par(padding.left = 28, padding.bottom = 3)))
tablo <- function(df, gen, vurgu = NULL) {
  ft <- flextable(df); ft <- theme_box(ft); ft <- font(ft, fontname = FONT, part = "all"); ft <- fontsize(ft, size = 9, part = "all")
  ft <- bg(ft, bg = LACI, part = "header"); ft <- color(ft, color = "white", part = "header"); ft <- bold(ft, part = "header")
  ft <- width(ft, width = gen); ft <- align(ft, j = seq_len(ncol(df))[-1], align = "right", part = "body")
  if (!is.null(vurgu)) ft <- bg(ft, i = vurgu, bg = "#FFF2CC")
  ft
}
sf <- function(x, d = 4) formatC(x, digits = d, format = "f")
fark <- function(x, y, d = 4) sprintf("%s (%s%%)", formatC(x - y, digits = d, format = "f"), formatC(100 * (x - y) / abs(y), digits = 2, format = "f"))

# ---- 4. Belge --------------------------------------------------------------------------
doc <- read_docx()
doc <- body_set_default_section(doc, prop_section(page_size = page_size(orient = "portrait", width = 21/2.54, height = 29.7/2.54),
  page_margins = page_mar(top = 0.9, bottom = 0.9, left = 0.85, right = 0.85, header = 0.4, footer = 0.4),
  header_default = block_list(fpar(ftext(sprintf("FarmaStatR · %s · Sürüm %s", BELGE_NO, SURUM), fp_text(font.size = 8, color = "#555555", font.family = FONT)), fp_p = fp_par(text.align = "right"))),
  footer_default = block_list(fpar(ftext("Sayfa ", fp_text(font.size = 8, font.family = FONT)), run_word_field("PAGE", prop = fp_text(font.size = 8, font.family = FONT)), fp_p = fp_par(text.align = "center")))))

doc <- body_add_fpar(doc, fpar(ftext("TEKNİK NOT", fp_text(font.size = 18, bold = TRUE, color = LACI, font.family = FONT))))
doc <- body_add_fpar(doc, fpar(ftext("Tek bir veri değerinin Mahalanobis uzaklığı ve Hotelling T² üzerindeki etkisi: Tsong ve ark. 1996, REF tablet 4, 30. dakika (78.54 / 78.45)",
                                     fp_text(font.size = 12, font.family = FONT)), fp_p = fp_par(padding.bottom = 8)))
bilgi <- data.frame(Alan = c("Belge no", "Sürüm / tarih", "İlgili belgeler", "Hesap motoru", "Kaynak veri"),
  Değer = c(BELGE_NO, paste(SURUM, "/", format(Sys.Date(), "%d.%m.%Y")),
            "FSR-VAL-DIS-1A v1.1 (Bölüm 6: dizgi hatası tespiti)",
            "msd_core.R v0.2.0 (validasyonlu; calc_msd), R temel lineer cebir (eigen, solve)",
            "Tsong Y, Hammerstrom T, Sathe P, Shah VP. Drug Inf J 1996;30:1105–1112, Tablo 1 (TEST, REF)"), stringsAsFactors = FALSE)
ft <- tablo(bilgi, c(1.6, 5.2)); ft <- align(ft, j = 2, align = "left", part = "body"); ft <- bold(ft, j = 1)
doc <- body_add_flextable(doc, ft)

doc <- h1(doc, "1. Amaç")
doc <- p(doc, "Tsong ve ark. (1996) Tablo 1'de REF ürününün 4. tabletinin 30. dakika değeri 78.54 olarak basılmıştır. FSR-VAL-DIS-1A ",
         "validasyonunda, makalenin yayımladığı sonuçların (D_M = 26.49; %90 GA 19.65–33.32; T² = 2104.46) yalnızca 78.45 değeriyle ",
         "üretildiği, dolayısıyla basılı değerin iki rakamın yer değiştirmesinden kaynaklanan bir dizgi hatası olduğu gösterilmiştir. ",
         "Bu not, 0.09'luk bu farkın D_M ve T²'de neden orantısız büyük bir değişime yol açtığını sayısal ve cebirsel olarak belgeler.")

doc <- h1(doc, "2. Veri ve yöntem")
doc <- p(doc, "TEST ve REF, her biri 6 tablet × 8 zaman noktası (5, 10, 15, 20, 30, 60, 90, 120 dk). Gösterim: n = 6, P = 8; ",
         "d = x̄_T − x̄_R; S birleştirilmiş kovaryans matrisi; D² = d′S⁻¹d; D_M = √D²; T² = [n_T n_R/(n_T + n_R)]·D² = 3·D². ",
         "Güven bölgesi ve benzerlik sınırı (L1, D_g = 15) validasyonlu calc_msd fonksiyonuyla hesaplanmıştır. ",
         "S = Σ λ_j v_j v_jᵀ özdeğer ayrışımı ve a_j = v_j′d olmak üzere D² = Σ a_j²/λ_j'dir.")

# ---- Tablo 1: ana karşılaştırma
doc <- h1(doc, "3. Karşılaştırmalı sonuçlar")
t1 <- data.frame(
  Nicelik = c("REF tablet 4, 30 dk değeri", "REF 30 dk ortalaması", "d₃₀ = x̄_T − x̄_R (30 dk)", "u₃₀ = tablet 4 sapması (30 dk)",
              "S[30,30] (30 dk varyansı)", "S[30,15] (kovaryans)", "S[30,20] (kovaryans)",
              "λ₁ (en büyük özdeğer)", "λ₇", "λ₈ (en küçük özdeğer)", "Koşul sayısı λ₁/λ₈",
              "a₈ = v₈′d", "a₈²/λ₈ (en küçük yönün D²'ye katkısı)", "Bu katkının D² içindeki payı",
              "w₃₀ = (S⁻¹d)₃₀", "u′w",
              "D²", "D_M (Mahalanobis uzaklığı)", "T² = 3·D²", "%90 GA alt sınır", "%90 GA üst sınır",
              "R_D (L1, D_g = 15)", "Karar (L1, D_g = 15)"),
  Basili = c(sf(78.54, 2), sf(mean(B$R[, k])), sf(B$d[k]), sf(B$u[k]),
             sf(B$S[k, k]), sf(B$S[k, 3]), sf(B$S[k, 4]),
             sf(B$lam[1]), sf(B$lam[7]), sf(B$lam[8]), sf(B$lam[1] / B$lam[8], 1),
             sf(B$a[8]), sf(B$katki[8]), sprintf("%%%s", sf(100 * B$katki[8] / B$D2, 1)),
             sf(B$w[k]), sf(sum(B$u * B$w)),
             sf(B$D2), sf(B$m$DM), sf(3 * B$D2), sf(B$m$DM_l), sf(B$m$DM_u), sf(B$m$RD), if (B$m$benzer_msd) "BENZER" else "BENZER DEĞİL"),
  Duzeltilmis = c(sf(78.45, 2), sf(mean(D$R[, k])), sf(D$d[k]), sf(D$u[k]),
                  sf(D$S[k, k]), sf(D$S[k, 3]), sf(D$S[k, 4]),
                  sf(D$lam[1]), sf(D$lam[7]), sf(D$lam[8]), sf(D$lam[1] / D$lam[8], 1),
                  sf(D$a[8]), sf(D$katki[8]), sprintf("%%%s", sf(100 * D$katki[8] / D$D2, 1)),
                  sf(D$w[k]), sf(sum(D$u * D$w)),
                  sf(D$D2), sf(D$m$DM), sf(3 * D$D2), sf(D$m$DM_l), sf(D$m$DM_u), sf(D$m$RD), if (D$m$benzer_msd) "BENZER" else "BENZER DEĞİL"),
  Fark = c(fark(78.54, 78.45, 2), fark(mean(B$R[, k]), mean(D$R[, k])), fark(B$d[k], D$d[k]), fark(B$u[k], D$u[k]),
           fark(B$S[k, k], D$S[k, k]), fark(B$S[k, 3], D$S[k, 3]), fark(B$S[k, 4], D$S[k, 4]),
           fark(B$lam[1], D$lam[1]), fark(B$lam[7], D$lam[7]), fark(B$lam[8], D$lam[8]), fark(B$lam[1] / B$lam[8], D$lam[1] / D$lam[8], 1),
           fark(B$a[8], D$a[8]), fark(B$katki[8], D$katki[8]), "—",
           fark(B$w[k], D$w[k]), fark(sum(B$u * B$w), sum(D$u * D$w)),
           fark(B$D2, D$D2), fark(B$m$DM, D$m$DM), fark(3 * B$D2, 3 * D$D2), fark(B$m$DM_l, D$m$DM_l), fark(B$m$DM_u, D$m$DM_u),
           fark(B$m$RD, D$m$RD), "aynı"),
  stringsAsFactors = FALSE)
names(t1) <- c("Nicelik", "78.54 (makalede basılı)", "78.45 (düzeltilmiş)", "Fark (basılı − düzeltilmiş) ve %")
doc <- body_add_flextable(doc, tablo(t1, c(2.55, 1.35, 1.35, 1.85), vurgu = c(1, 10, 13, 18, 19)))
doc <- pi_(doc, "Sarı satırlar: değişikliğin kendisi ve etkinin ana göstergeleri. Fark sütunu: mutlak fark (göreli fark, %).")

# ---- Tablo 2: yayımlanan değerler
doc <- h2(doc, "3.1 Tsong 1996'nın yayımlanan değerleriyle karşılaştırma (DATA2)")
t2 <- data.frame(Nicelik = c("D_M", "%90 GA", "T²"),
  Yay = c("26.49", "(19.65, 33.32)", "2104.46"),
  Bas = c(sf(B$m$DM, 2), sprintf("(%s, %s)", sf(B$m$DM_l, 2), sf(B$m$DM_u, 2)), sf(3 * B$D2, 2)),
  Duz = c(sf(D$m$DM, 2), sprintf("(%s, %s)", sf(D$m$DM_l, 2), sf(D$m$DM_u, 2)), sf(3 * D$D2, 2)),
  Sonuc = c("yalnızca 78.45 üretir", "yalnızca 78.45 üretir", "yalnızca 78.45 üretir"), stringsAsFactors = FALSE)
names(t2) <- c("Nicelik", "Tsong 1996 (yayımlanan)", "78.54 ile", "78.45 ile", "Sonuç")
doc <- body_add_flextable(doc, tablo(t2, c(1.2, 1.5, 1.4, 1.4, 1.6)))

# ---- Tablo 3: özdeğer ayrışımı
doc <- h1(doc, "4. Özdeğer ayrışımı: etkinin kaynağı")
t3 <- data.frame(j = 1:8, lb = sf(B$lam), ld = sf(D$lam), ab = sf(B$a, 3), ad = sf(D$a, 3), kb = sf(B$katki, 2), kd = sf(D$katki, 2), stringsAsFactors = FALSE)
t3 <- rbind(t3, data.frame(j = "Toplam = D²", lb = "", ld = "", ab = "", ad = "", kb = sf(B$D2, 2), kd = sf(D$D2, 2)))
names(t3) <- c("j", "λ_j (78.54)", "λ_j (78.45)", "a_j (78.54)", "a_j (78.45)", "a_j²/λ_j (78.54)", "a_j²/λ_j (78.45)")
doc <- body_add_flextable(doc, tablo(t3, c(0.9, 0.95, 0.95, 0.95, 0.95, 1.2, 1.2), vurgu = 8))
doc <- p(doc, "")
t4 <- data.frame(Zaman = paste(zaman, "dk"), vb = sf(B$v8, 3), vd = sf(D$v8, 3), stringsAsFactors = FALSE)
names(t4) <- c("Zaman", "v₈ (78.54)", "v₈ (78.45)")
doc <- body_add_flextable(doc, tablo(t4, c(1.2, 1.3, 1.3), vurgu = 3:5))
doc <- p(doc, sprintf(paste0("En küçük özdeğere karşılık gelen yön (v₈), ağırlıklı olarak 15 ve 20. dakikalar ile 30. dakika arasındaki bir karşıtlıktır. ",
  "Tabletler bu yönde neredeyse hiç değişkenlik göstermez (λ₈ ≈ %s). D² = Σ a_j²/λ_j olduğundan, farkın bu yöndeki küçük bileşeni ",
  "(a₈ ≈ %s) λ₈'e bölünerek büyütülür ve D²'nin yaklaşık %%%s'ini oluşturur; oysa farkın en büyük bileşeni (a₁ ≈ %s) yalnızca %%%s katkı verir. ",
  "0.09'luk değişiklik tam olarak bu hassas yöne giren 30. dakikadadır."),
  sf(D$lam[8], 3), sf(D$a[8], 1), sf(100 * D$katki[8] / D$D2, 0), sf(D$a[1], 1), sf(100 * D$katki[1] / D$D2, 0)))

# ---- Cebirsel türetim
doc <- h1(doc, "5. Cebirsel türetim")
doc <- h2(doc, "5.1 Değişiklik"); doc <- formul(doc, "x₄ → x₄ + ε e_k,   ε = 0.09,   k = 30 dk")
doc <- h2(doc, "5.2 Ortalama farkı"); doc <- formul(doc, sprintf("δd = −(ε/n) e_k = −0.015 e_k"))
doc <- h2(doc, "5.3 Kovaryans matrisi")
doc <- formul(doc, "r_i′ = r_i + ε(δ_i4 − 1/n) e_k ;   Σ(δ_i4 − 1/n) r_i = r₄ ≡ u ;   Σ(δ_i4 − 1/n)² = (n−1)/n")
doc <- formul(doc, "ΔS = [ ε(u e_kᵀ + e_k uᵀ) + ε²((n−1)/n) e_k e_kᵀ ] / (2n − 2)")
doc <- p(doc, sprintf("ΔS rankı 2 olan bir güncellemedir ve yalnızca 30. dakika satır/sütununu değiştirir. Formül ile doğrudan hesap arasındaki en büyük fark %.1e'dir; ΔS[30,30] = %s.",
                      max(abs(dS_formul - (B$S - D$S))), sf(dS_formul[k, k], 6)))
doc <- h2(doc, "5.4 Ters matris ve D²")
doc <- formul(doc, "(S + ΔS)⁻¹ ≈ S⁻¹ − S⁻¹ ΔS S⁻¹ ;   w = S⁻¹d")
doc <- formul(doc, "ΔD² ≈ 2 δd′w − w′ΔSw = −2(ε/n) w_k − 2ε(u′w) w_k/(2n−2) − ε²((n−1)/n) w_k²/(2n−2)")
t5 <- data.frame(Terim = c("A: ortalama farkı", "B₁: kovaryans (birinci mertebe)", "B₂: ε² terimi", "Birinci mertebe toplam", "Gerçek ΔD² (tam hesap)", "ΔT² = 3·ΔD²"),
                 Deger = c(sf(A), sf(B1), sf(B2), sf(A + B1 + B2), sf(B$D2 - D$D2), sf(3 * (B$D2 - D$D2))), stringsAsFactors = FALSE)
names(t5) <- c("Terim (78.45 → 78.54)", "Değer")
doc <- body_add_flextable(doc, tablo(t5, c(3.2, 1.4), vurgu = 2))
doc <- p(doc, "Değişimin neredeyse tamamı B₁ teriminden, yani kovaryans matrisinden gelir; ortalama farkının katkısı (A) küçüktür. ",
         "Birinci mertebe yaklaşım ile tam hesap arasındaki fark yüksek mertebe terimlerden kaynaklanır; ΔS rankı 2 olduğundan tam sonuç ",
         "Sherman–Morrison–Woodbury formülüyle kapalı biçimde de yazılabilir.")

# ---- Yorum
doc <- h1(doc, "6. Değerlendirme")
doc <- h2(doc, "6.1 Bulgular")
doc <- p(doc, sprintf(paste0("(1) 0.09'luk (%%0.11) tek değer farkı D_M'yi %%%s, T²'yi %%%s değiştirmiştir. (2) Etkinin kaynağı ortalama farkı değil, ",
  "kovaryans matrisinin tersidir. (3) Büyütmenin nedeni S'nin kötü koşullu olmasıdır (koşul sayısı ≈ %s): ürün başına 6 tablet ile 8 boyutlu bir ",
  "kovaryans matrisi yalnızca 10 serbestlik derecesiyle tahmin edilmektedir; tek ürünlerin kovaryans matrisleri tekildir (rank 5/8). ",
  "(4) Aynı dizgi hatası, yalnızca 15 ve 90. dakikaları kullanan DATA1 örneğini etkilememektedir."),
  sf(100 * (B$m$DM / D$m$DM - 1), 1), sf(100 * (B$D2 / D$D2 - 1), 1), sf(D$lam[1] / D$lam[8], 0)))
doc <- h2(doc, "6.2 EMA Soru-Cevap 3.9 ile ilişkisi")
doc <- p(doc, "EMA Q&A 3.9, Mahalanobis uzaklığını tercih edilen yöntem olarak desteklememesini üç gözleme dayandırır: MD'nin ",
         "varyans ve kovaryans tahminlerine bağımlı olması (\"MD is dependent on variance and covariance estimates\"); bazı ",
         "koşullarda değişkenlik arttıkça MD'nin küçülmesi; ve bir zaman noktasında %10'dan büyük fark varken MD tabanlı ölçütlerin ",
         "farkı önemsiz bulabilmesi.")
doc <- p(doc, "FarmaStatR yorumu: Bu notun bulgusu, EMA'nın ilk gözleminin somut ve cebirsel bir gösterimidir. MD'nin ölçeğini tahmin edilen ",
         "kovaryans yapısı belirler: bir yönde tahmin edilen varyans büyükse o yöndeki farklar küçülür (EMA'nın ikinci gözlemi), ",
         "tahmin edilen varyans çok küçükse o yöndeki farklar aşırı büyütülür (bu not). İkisi aynı mekanizmanın iki yüzüdür. ",
         "Sonuç olarak MD, küçük örneklemlerde ve çok sayıda zaman noktasında, farmasötik açıdan anlamsız yönlere (burada 15–20 ile 30. ",
         "dakika arasındaki ince bir karşıtlık) yüksek ağırlık verebilir ve tek bir veri hatasına karşı kararsız olabilir. EMA ",
         "belgesinde \"koşul sayısı\" ya da \"kararsızlık\" ifadeleri geçmemektedir; bu çıkarım FarmaStatR'a aittir.")
doc <- h2(doc, "6.3 Pratik öneriler")
doc <- p(doc, "(1) MSD uygulanacaksa tablet sayısının zaman noktası sayısına göre yeterli olması (kılavuzların öngördüğü 12 ünite) ve zaman ",
         "noktası sayısının sınırlı tutulması; (2) sonuçla birlikte kovaryans matrisinin koşul sayısının raporlanması; (3) koşul sayısı ",
         "yüksekse sonucun veri hatalarına duyarlı olabileceğinin belirtilmesi ve kaynak verinin ikinci bir kişi tarafından doğrulanması.")

doc <- h1(doc, "7. Sonuç")
doc <- p(doc, "Makalede basılı 78.54 değeri yayımlanan sonuçları üretmez; 78.45 değeri tüm yayımlanan değerleri iki ondalıkta birebir üretir. ",
         "0.09'luk farkın D_M ve T² üzerindeki orantısız etkisi, kötü koşullu kovaryans matrisinin tersiyle en küçük özdeğer yönünde ",
         "gerçekleşen büyütmeyle açıklanır. Bu durum, MSD'nin kovaryans tahminine bağımlılığına ilişkin EMA Q&A 3.9 gözleminin sayısal bir örneğidir.")
doc <- h1(doc, "Ek · Ortam")
ortam <- data.frame(Bileşen = c("R", "Platform", "Hesap modülü", "Belge üretimi"),
  Sürüm = c(R.version.string, R.version$platform, "msd_core.R v0.2.0 (validasyonlu)",
            sprintf("officer %s, flextable %s", packageVersion("officer"), packageVersion("flextable"))), stringsAsFactors = FALSE)
ft <- tablo(ortam, c(1.6, 5.2)); ft <- align(ft, j = 2, align = "left", part = "body"); doc <- body_add_flextable(doc, ft)
doc <- p(doc, "Bu belge tsong_duyarlilik_notu.R betiğiyle üretilmiştir; tüm sayılar betik içinde yeniden hesaplanır.")
print(doc, target = CIKTI)
cat("Belge üretildi:", normalizePath(CIKTI), "\n")
