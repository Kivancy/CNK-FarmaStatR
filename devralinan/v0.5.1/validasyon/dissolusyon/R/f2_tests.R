# =============================================================================
# FarmaStatR — Dissolüsyon Modülü Bölüm 2 · Validasyon test vakaları
#
# Referans türleri:
#   (Y) Yayımlanmış — Noce ve ark. 2020 Tablo 3 (2 ondalık) → 0.005; Tablo 4 → 0.5 (stokastik)
#   (B) Bağımsız uygulama — Python/NumPy; AYNI bootstrap indeksleriyle → 1e-10
#   (A) Analitik / mantıksal
#
# Doğrulama katmanları:
#   1. Deterministik: f2, E(f2), bc-f2, %85 kuralları, EMA kontrol sırası, kantiller
#   2. Rastgelelikten arındırılmış bootstrap: aynı indekslerle R = Python (= SAS)
#   3. Stokastik: Noce Tablo 4 (Bootf2bca, 5000) ile tolerans içinde uyum
#
# Çalıştırma: source("f2_boot.R"); source("f2_noce_data.R"); source("f2_tests.R")
# =============================================================================

.sonuclar <- data.frame(TC = character(), kontrol = character(), kaynak = character(),
                        beklenen = numeric(), hesaplanan = numeric(), fark = numeric(),
                        tol = numeric(), durum = character(), stringsAsFactors = FALSE)
kontrol <- function(tc, ad, kaynak, beklenen, hesaplanan, tol) {
  fark <- abs(beklenen - hesaplanan)
  durum <- if (isTRUE(fark <= tol + 1e-12)) "GEÇTİ" else "KALDI"
  .sonuclar[nrow(.sonuclar) + 1, ] <<- list(tc, ad, kaynak, beklenen, hesaplanan, fark, tol, durum)
}
kontrol_mantik <- function(tc, ad, kaynak, beklenen, hesaplanan) {
  durum <- if (identical(beklenen, hesaplanan)) "GEÇTİ" else "KALDI"
  .sonuclar[nrow(.sonuclar) + 1, ] <<- list(tc, ad, kaynak, as.numeric(beklenen),
                                            as.numeric(hesaplanan), NA, NA, durum)
}
hata_var <- function(expr) inherits(try(expr, silent = TRUE), "try-error")


# =============================================================================
# TC-F1 · Noce 2020 Tablo 3 — f2, E(f2), bc-f2; üç kesme kuralı (18 yayımlanmış değer)
# =============================================================================
noce3 <- list(
  P1 = rbind(none = c(49.66, 48.35, 51.14), EMA = c(45.85, 44.54, 47.36), FDA = c(47.34, 46.02, 48.83)),
  P2 = rbind(none = c(54.87, 54.04, 55.76), EMA = c(57.11, 55.70, 58.73), FDA = c(56.47, 55.29, 57.78)))
noce3_B <- list(
  P1 = rbind(none = c(49.6575334971596, 48.35244228132215, 51.141212095413024),
             EMA  = c(45.85482540208222, 44.536059970771, 47.35620838203285),
             FDA  = c(47.33633506635533, 46.01992239977972, 48.834668211011625)),
  P2 = rbind(none = c(54.870095781908624, 54.044468163293466, 55.76371222684373),
             EMA  = c(57.109676664341244, 55.69968980478564, 58.73049005580802),
             FDA  = c(56.467772001839265, 55.293672731755095, 57.78440578461556)))
for (pr in c("P1", "P2")) for (tr in c("none", "EMA", "FDA")) {
  X <- if (pr == "P1") noce_P1 else noce_P2
  k <- f2_checks(X, noce_P3, noce_t, truncation = tr)
  e <- f2_estimators(k$XT, k$XR)
  for (j in 1:3) {
    ad <- sprintf("%s-P3 %s %s", pr, tr, c("f2", "E(f2)", "bc-f2")[j])
    kontrol("TC-F1", ad, "Y", noce3[[pr]][tr, j], unname(e[j]), 0.005)
    kontrol("TC-F1", ad, "B", noce3_B[[pr]][tr, j], unname(e[j]), 1e-10)
  }
}


# =============================================================================
# TC-F2 · Analitik tahminci vakası
#   P = 3, n = 12; u birim varyanslı (n-1 paydalı) vektör.
#   REF = 50 + 2u (her noktada), TEST = REF + 10 → D = 3·100 = 300; V = 3·(4+4)/12 = 2
#   f2 = 100 - 25 log10(1 + 100); E(f2) = 100 - 25 log10(1 + 302/3); bc = 100 - 25 log10(1 + 298/3)
# =============================================================================
u <- c(rep(-1, 6), rep(1, 6)) * sqrt(11 / 12)
aR <- cbind(50 + 2 * u, 60 + 2 * u, 70 + 2 * u); aT <- aR + 10
e2 <- f2_estimators(aT, aR)
kontrol("TC-F2", "D = 300", "A", 300, unname(e2["D"]), 1e-10)
kontrol("TC-F2", "V = 2",   "A", 2,   unname(e2["V"]), 1e-12)
kontrol("TC-F2", "f2",      "A", 100 - 25 * log10(101),          unname(e2["f2"]), 1e-12)
kontrol("TC-F2", "E(f2)",   "A", 100 - 25 * log10(1 + 302 / 3),  unname(e2["Ef2"]), 1e-12)
kontrol("TC-F2", "bc-f2",   "A", 100 - 25 * log10(1 + 298 / 3),  unname(e2["bcf2"]), 1e-12)
# n_T ≠ n_R genellemesi: TEST 12, REF 24 (REF iki kez) → V = 3·(4/12 + 4·(11/12)·(24/23)... ) doğrudan
aR2 <- rbind(aR, aR)
v_bek <- sum(apply(aT, 2, var) / 12 + apply(aR2, 2, var) / 24)
kontrol("TC-F2", "V (n_T=12, n_R=24)", "A", v_bek, unname(f2_estimators(aT, aR2)["V"]), 1e-12)
# bc-f2 tanımsız: TEST = REF → D = 0 < V
kontrol_mantik("TC-F2", "bc-f2 tanımsız (D ≤ V)", "A", TRUE, unname(is.na(f2_estimators(aR, aR)["bcf2"])))


# =============================================================================
# TC-F3 · Hyndman & Fan kantilleri — bağımsız uygulama (hf_quantile) vs stats::quantile
# =============================================================================
set.seed(11); xq <- rnorm(5000)
xk <- c(3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8)
for (ty in 1:9) {
  d1 <- max(abs(hf_quantile(xq, c(0.05, 0.95), ty) - quantile(xq, c(0.05, 0.95), type = ty, names = FALSE)))
  d2 <- max(abs(hf_quantile(xk, seq(0, 1, 0.05), ty) - quantile(xk, seq(0, 1, 0.05), type = ty, names = FALSE)))
  kontrol("TC-F3", sprintf("tip %d (B=5000 ve n=12, 21 olasılık)", ty), "B", 0, max(d1, d2), 1e-12)
}


# =============================================================================
# TC-F4 · EMA kontrol sırası (adım 0-7)
# =============================================================================
k_e <- f2_checks(noce_P1, noce_P3, noce_t, "EMA")
k_f <- f2_checks(noce_P1, noce_P3, noce_t, "FDA")
k_n <- f2_checks(noce_P1, noce_P3, noce_t, "none")
kontrol("TC-F4", "EMA kesmesi: P = 6 (165 dk'ya kadar)", "A", 6, k_e$P, 0)
kontrol("TC-F4", "FDA kesmesi: P = 7 (180 dk'ya kadar)", "A", 7, k_f$P, 0)
kontrol("TC-F4", "kesme yok: P = 9", "A", 9, k_n$P, 0)
kontrol_mantik("TC-F4", "Noce verisi CV koşulunu sağlamıyor → bootstrap önerisi", "A",
               TRUE, grepl("Bootstrap", k_e$oneri))
# t = 0 çıkarılır
k0 <- f2_checks(cbind(0, noce_P1), cbind(0, noce_P3), c(0, noce_t), "EMA")
kontrol("TC-F4", "t = 0 çıkarıldı, P yine 6", "A", 6, k0$P, 0)
# 15 dakikada > %85 kuralı
hT <- matrix(rep(c(70, 90, 95, 98), each = 12), 12) + outer(u, rep(0.5, 4))
kh <- f2_checks(hT, hT, c(10, 15, 20, 30), "EMA")
kontrol_mantik("TC-F4", "15 dk'da > %85 → değerlendirme gerekmez notu", "A", TRUE, kh$hizli)
# P < 3 → uygulanamaz
kontrol_mantik("TC-F4", "kesme sonrası P < 3 → UYGULANAMAZ", "A", TRUE,
               f2_checks(hT, hT, c(10, 15, 20, 30), "EMA")$oneri == "UYGULANAMAZ")
kontrol_mantik("TC-F4", "P < 3 iken calc_f2_boot durur", "A", TRUE,
               hata_var(calc_f2_boot(hT, hT, c(10, 15, 20, 30), B = 10)))
# n < 12 uyarısı; eksik değer kuralları
kontrol_mantik("TC-F4", "n = 11 → madde 3 notu", "A", TRUE,
               any(grepl("12'nin altında", f2_checks(noce_P1[-1, ], noce_P3, noce_t)$notlar)))
Xna <- noce_P1; Xna[3, 9] <- NA      # yalnızca kesilen noktada (240 dk) eksik
k_na <- f2_checks(Xna, noce_P3, noce_t, "EMA")
kontrol("TC-F4", "kesilen noktadaki eksik: ünite tutuldu (n_T = 12)", "A", 12, unname(k_na$n["T"]), 0)
Xna2 <- noce_P1; Xna2[3, 2] <- NA    # seçili noktada eksik
kontrol("TC-F4", "seçili noktadaki eksik: ünite çıkarıldı (n_T = 11)", "A", 11,
        unname(f2_checks(Xna2, noce_P3, noce_t, "EMA")$n["T"]), 0)
# CV kuralı: M9 (≤10 dk %20) ve AppI (ilk nokta %20) farkı
cvT <- cbind(100 + 15 * u / 1, 100 + 15 * u, 100 + 5 * u) * 0.5    # CV ≈ %15, %15, %5
k_m9 <- f2_checks(cvT, cvT, c(5, 10, 15), "none", "M9")
k_ap <- f2_checks(cvT, cvT, c(5, 10, 15), "none", "AppI")
kontrol_mantik("TC-F4", "M9: 10 dk'da CV %15 → ihlal yok", "A", FALSE, k_m9$cv$ihlal[2])
kontrol_mantik("TC-F4", "AppI: 2. noktada CV %15 → ihlal", "A", TRUE, k_ap$cv$ihlal[2])
# %85 sınırında eşitlik: ortalama tam 85.0 → "> 85" DEĞİL
m85 <- f2_truncate(c(80, 85.0, 90), c(70, 80, 86), "EMA")
kontrol("TC-F4", "ortalama tam 85.0 kesmeyi tetiklemez", "A", 3, length(m85), 0)
m85b <- f2_truncate(c(80, sum(rep(85, 12) + c(0.1, -0.1)) / 12, 90), c(70, 80, 86), "EMA")
kontrol("TC-F4", "toplam 1020 (ort. 85.0): kayan nokta güvenli", "A", 3, length(m85b), 0)


# =============================================================================
# TC-F5 · Bootstrap motoru — deterministik özellikler
# =============================================================================
kP <- f2_checks(noce_P1, noce_P3, noce_t, "EMA")
# (a) Özdeşlik indeksi: her replika orijinal veri → E(f2) = nokta tahmini
id <- list(T = matrix(1:12, 3, 12, byrow = TRUE), R = matrix(1:12, 3, 12, byrow = TRUE))
r_id <- f2_boot_replicates(kP$XT_tum, kP$XR_tum, id, "EMA", "replika")
kontrol("TC-F5", "özdeşlik indeksi → E(f2) = 44.536…", "A",
        unname(f2_estimators(kP$XT, kP$XR)["Ef2"]), max(abs(r_id[, "Ef2"])), 1e-12)
# (b) Elle indeks: tek replika, doğrudan hesapla karşılaştır
el <- list(T = matrix(c(1, 1, 2, 3, 5, 5, 5, 8, 9, 10, 12, 12), 1), R = matrix(c(2:12, 2), 1))
r_el <- f2_boot_replicates(kP$XT_tum, kP$XR_tum, el, "EMA", "replika")
xt <- noce_P1[el$T[1, ], ]; xr <- noce_P3[el$R[1, ], ]
sec <- f2_truncate(colMeans(xt), colMeans(xr), "EMA")
kontrol("TC-F5", "elle indeks: replika E(f2) = doğrudan hesap", "A",
        unname(f2_estimators(xt[, sec], xr[, sec])["Ef2"]), unname(r_el[1, "Ef2"]), 1e-12)
# (c) Yeniden üretilebilirlik ve RNG'nin eski haline dönmesi
RNGkind("Knuth-TAOCP-2002"); on_rng <- RNGkind()[1]
s_a <- calc_f2_boot(noce_P1, noce_P3, noce_t, B = 500, seed = 7)
s_b <- calc_f2_boot(noce_P1, noce_P3, noce_t, B = 500, seed = 7)
kontrol_mantik("TC-F5", "aynı seed → özdeş replikalar", "A", TRUE, identical(s_a$replikalar, s_b$replikalar))
kontrol_mantik("TC-F5", "kullanıcının RNG ayarı geri yüklendi", "A", TRUE, RNGkind()[1] == on_rng)
RNGkind("default", "default", "default")
# (d) Kesme modları: "sabit" modda P hep 6; "replika" modda değişken
kontrol_mantik("TC-F5", "sabit modda tüm replikalarda P = 6", "A", TRUE,
               all(calc_f2_boot(noce_P1, noce_P3, noce_t, kesme_modu = "sabit", B = 500)$replikalar[, "P"] == 6))


# =============================================================================
# TC-F6 · Aynı indekslerle R = Python (rastgelelikten arındırılmış bootstrap)
#   seed = 20260927, B = 5000, Mersenne-Twister/Inversion/Rejection, kantil tipi 7
# =============================================================================
b6_B <- list(
  P1 = rbind(EMA  = c(35.616397988118635, 57.504593767305415),
             FDA  = c(37.76944459586995, 58.41598813489947),
             none = c(39.983695047316324, 59.96930768920983)),
  P2 = rbind(EMA  = c(48.19828458969192, 63.3062627954034),
             FDA  = c(48.84563821240875, 60.9267318669856),
             none = c(49.03307842917356, 58.43492166312372)))
for (pr in c("P1", "P2")) for (tr in c("EMA", "FDA", "none")) {
  X <- if (pr == "P1") noce_P1 else noce_P2
  s <- calc_f2_boot(X, noce_P3, noce_t, truncation = tr)
  kontrol("TC-F6", sprintf("%s-P3 %s alt sınır", pr, tr), "B", b6_B[[pr]][tr, 1], unname(s$GA["Ef2", "alt"]), 1e-10)
  kontrol("TC-F6", sprintf("%s-P3 %s üst sınır", pr, tr), "B", b6_B[[pr]][tr, 2], unname(s$GA["Ef2", "ust"]), 1e-10)
}
s6 <- calc_f2_boot(noce_P1, noce_P3, noce_t)
kontrol("TC-F6", "P1-P3 EMA: P = 5/6/7 sayıları (125/4278/597)", "B", 0,
        sum(abs(as.numeric(s6$P_dagilim) - c(125, 4278, 597))), 0)
kontrol("TC-F6", "P1-P3 EMA sabit mod alt sınır", "B", 35.878601277806126,
        unname(calc_f2_boot(noce_P1, noce_P3, noce_t, kesme_modu = "sabit")$GA["Ef2", "alt"]), 1e-10)


# =============================================================================
# TC-F7 · Stokastik: Noce Tablo 4 (Bootf2bca, 5000 replika) ile uyum
#   Tolerans 0.5: Noce'nin platformlar arası farkı < 0.30; bizim MCSE ≈ 0.08-0.15
# =============================================================================
noce4 <- c("P1 none" = 40.02, "P1 EMA" = 35.82, "P1 FDA" = 38.04,
           "P2 none" = 48.93, "P2 EMA" = 48.05, "P2 FDA" = 48.71)
for (nm in names(noce4)) {
  pr <- substr(nm, 1, 2); tr <- sub(".* ", "", nm)
  kontrol("TC-F7", sprintf("%s-P3 %s alt sınır ~ Bootf2bca", pr, tr), "Y", noce4[[nm]],
          unname(b6_B[[pr]][tr, 1]), 0.5)
}


# =============================================================================
# TC-F8 · Karar kuralı (kullanıcı kararı): 4 ondalık, yuvarlama yok
# =============================================================================
kontrol_mantik("TC-F8", "50.0000 → BENZER", "A", TRUE, f2_karar(50, 0.1)$karar == "BENZER")
kontrol_mantik("TC-F8", "49.6000 → SINIR VAKA", "A", TRUE, grepl("SINIR", f2_karar(49.6, 0.1)$karar))
kontrol_mantik("TC-F8", "49.4999 → BENZER DEĞİL", "A", TRUE, f2_karar(49.4999, 0.01)$karar == "BENZER DEĞİL")
kontrol_mantik("TC-F8", "50.15, MCSE 0.1 → seed'e duyarlı", "A", TRUE, f2_karar(50.15, 0.1)$seed_duyarli)
kontrol_mantik("TC-F8", "52.00, MCSE 0.1 → duyarlı değil", "A", FALSE, f2_karar(52, 0.1)$seed_duyarli)


# =============================================================================
# TC-F9 · FDA perspektifi ve BCa [FDA97 V.A; GONG20; MANDULA19; XU21]
# =============================================================================
# (a) Ön ayar çözümlemesi
fd <- calc_f2_boot(noce_P1, noce_P3, noce_t, perspektif = "FDA")
kontrol_mantik("TC-F9", "FDA ön ayarı: tahminci f2", "A", TRUE, fd$tahminci == "f2")
kontrol_mantik("TC-F9", "FDA ön ayarı: FDA kesmesi, FDA97 CV", "A", TRUE,
               fd$kontrol$truncation == "FDA" && fd$kontrol$cv_rule == "FDA97")
kontrol("TC-F9", "FDA ön ayarı: B = 10000", "A", 10000, fd$B, 0)
kontrol_mantik("TC-F9", "açık argüman ön ayarı geçersiz kılar (B = 500)", "A", TRUE,
               calc_f2_boot(noce_P1, noce_P3, noce_t, perspektif = "FDA", B = 500)$B == 500)
# (b) FDA97 CV kuralı: t ≤ 15 dk %20, sonrası %10
cvF <- cbind(100 + 15 * u, 100 + 15 * u, 100 + 15 * u, 100 + 5 * u) * 0.5   # CV ≈ 15, 15, 15, 5
kF  <- f2_checks(cvF, cvF, c(5, 15, 20, 30), "none", "FDA97")
kontrol_mantik("TC-F9", "FDA97: 15 dk'da CV %15 → ihlal yok", "A", FALSE, kF$cv$ihlal[2])
kontrol_mantik("TC-F9", "FDA97: 20 dk'da CV %15 → ihlal", "A", TRUE, kF$cv$ihlal[3])
# (c) BCa formülü analitik: z0 = 0, a = 0 → persentil (0.05, 0.95)
kontrol("TC-F9", "BCa α1 (z0=0, a=0) = 0.05", "A", 0.05, bca_alpha(0, 0)[1], 1e-15)
kontrol("TC-F9", "BCa α2 (z0=0, a=0) = 0.95", "A", 0.95, bca_alpha(0, 0)[2], 1e-15)
z0t <- 0.1; at <- 0.02; zt <- qnorm(0.05)
kontrol("TC-F9", "BCa α1 (z0=0.1, a=0.02) kapalı form", "A",
        pnorm(z0t + (z0t + zt) / (1 - at * (z0t + zt))), bca_alpha(z0t, at)[1], 1e-15)
# (d) Jackknife: n_T + n_R değer; ilk değer = TEST ünitesi 1 çıkarılmış doğrudan hesap
jk <- f2_jackknife(noce_P1, noce_P3, "f2", "FDA", "replika", NULL)
kontrol("TC-F9", "jackknife değer sayısı = 24", "A", 24, length(jk), 0)
x1 <- noce_P1[-1, ]; s1 <- f2_truncate(colMeans(x1), colMeans(noce_P3), "FDA")
kontrol("TC-F9", "jackknife[1] = TEST ünitesi 1 çıkarılmış f2", "A",
        unname(f2_estimators(x1[, s1], noce_P3[, s1])["f2"]), jk[1], 1e-12)
# (e) Aynı indekslerle R = Python (seed 20260927, B = 10000, P1-P3, FDA ön ayarı)
kontrol("TC-F9", "FDA persentil alt sınır", "B", 38.52407885796531, unname(fd$karar_ga["alt"]), 1e-10)
kontrol("TC-F9", "FDA persentil üst sınır", "B", 62.58796864746083, unname(fd$karar_ga["ust"]), 1e-10)
kontrol("TC-F9", "FDA bootstrap ortalaması", "B", 48.67359789223987, fd$boot_ortalama, 1e-10)
fb <- calc_f2_boot(noce_P1, noce_P3, noce_t, perspektif = "FDA", ga_tipi = "BCa")
kontrol("TC-F9", "BCa: #{f* < f̂}/B", "B", 0.4826, fb$bca$oran, 1e-15)
kontrol("TC-F9", "BCa: z0", "B", -0.04362916941356756, fb$bca$z0, 1e-10)
kontrol("TC-F9", "BCa: a (jackknife)", "B", -0.008052559676979274, fb$bca$a, 1e-12)
kontrol("TC-F9", "BCa: α1", "B", 0.039596647946083634, fb$bca$alpha12[1], 1e-12)
kontrol("TC-F9", "BCa: α2", "B", 0.9378792977395758, fb$bca$alpha12[2], 1e-12)
kontrol("TC-F9", "BCa alt sınır", "B", 37.95882179042025, unname(fb$karar_ga["alt"]), 1e-10)
kontrol("TC-F9", "BCa üst sınır", "B", 61.30844366982826, unname(fb$karar_ga["ust"]), 1e-10)
kontrol_mantik("TC-F9", "BCa seçilince tip I hata uyarısı", "A", TRUE, any(grepl("XU21", fb$uyarilar)))
# (f) EMA varsayılanı değişmedi (regresyon)
kontrol("TC-F9", "EMA varsayılanı: alt sınır değişmedi", "B", 35.616397988118635,
        unname(calc_f2_boot(noce_P1, noce_P3, noce_t)$karar_ga["alt"]), 1e-10)


# ---- Özet -------------------------------------------------------------------
cat("\n==================== VALİDASYON ÖZETİ (Bölüm 2) ====================\n")
print(.sonuclar[, c("TC", "kontrol", "kaynak", "beklenen", "hesaplanan", "fark", "durum")],
      row.names = FALSE, digits = 10)
cat(sprintf("\nToplam: %d kontrol · GEÇTİ: %d · KALDI: %d\n",
            nrow(.sonuclar), sum(.sonuclar$durum == "GEÇTİ"), sum(.sonuclar$durum == "KALDI")))
