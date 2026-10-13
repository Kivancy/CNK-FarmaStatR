# =============================================================================
# FarmaStatR — Dissolüsyon Modülü 1A · Validasyon test vakaları
#
# Referans değer kaynakları:
#   (Y) Yayımlanmış değer — Tsong ve ark. 1996, 2 ondalık → tolerans 0.005
#   (B) Bağımsız uygulama — Python/NumPy/SciPy ile ayrı yazılmış kod → tolerans 1e-8
#   (A) Analitik kapalı form — elle hesaplanabilir → tolerans 1e-10
#
# Çalıştırma: source("msd_core.R"); source("msd_tests.R")
# =============================================================================

# ---- Test altyapısı ---------------------------------------------------------
.sonuclar <- data.frame(TC = character(), kontrol = character(), kaynak = character(),
                        beklenen = numeric(), hesaplanan = numeric(), fark = numeric(),
                        tol = numeric(), durum = character(), stringsAsFactors = FALSE)

kontrol <- function(tc, ad, kaynak, beklenen, hesaplanan, tol) {
  fark  <- abs(beklenen - hesaplanan)
  durum <- if (isTRUE(fark <= tol + 1e-12)) "GEÇTİ" else "KALDI"
  .sonuclar[nrow(.sonuclar) + 1, ] <<- list(tc, ad, kaynak, beklenen, hesaplanan, fark, tol, durum)
}
kontrol_mantik <- function(tc, ad, kaynak, beklenen, hesaplanan) {
  durum <- if (identical(beklenen, hesaplanan)) "GEÇTİ" else "KALDI"
  .sonuclar[nrow(.sonuclar) + 1, ] <<- list(tc, ad, kaynak, as.numeric(beklenen),
                                            as.numeric(hesaplanan), NA, NA, durum)
}
TOL_Y <- 0.005; TOL_B <- 1e-8; TOL_A <- 1e-10


# =============================================================================
# VERİ — Tsong ve ark. 1996, Tablo 1 ve Tablo 3
# =============================================================================
zamanlar <- c(5, 10, 15, 20, 30, 60, 90, 120)

tsong_ref_yayimlanan <- matrix(c(
  42.06, 59.91, 65.58, 71.81, 77.77, 85.67, 93.14, 94.23,
  44.16, 60.18, 67.17, 70.82, 76.11, 83.27, 88.01, 89.59,
  45.63, 55.77, 65.56, 70.50, 76.92, 83.91, 86.83, 90.12,
  48.52, 60.39, 66.51, 73.06, 78.54, 84.99, 88.00, 93.43,   # ← 30 dk: 78.54 (dizgi hatası)
  50.49, 61.82, 69.06, 72.85, 78.99, 86.86, 89.70, 90.79,
  49.77, 62.73, 69.77, 72.88, 80.18, 84.20, 88.88, 90.47),
  nrow = 6, byrow = TRUE, dimnames = list(paste0("R", 1:6), zamanlar))

# ERRATUM: REF tablet 4, 30. dakika = 78.45 olmalı.
# Gerekçe: Tablo 1'den hesaplanan kovaryans, Tablo 2'deki yayımlanmış S1'den
# yalnızca 30 dk satır/sütununda sapar (maks. 0.036). Tek hücre taramasında
# 78.45 değeri sapmayı 0.0008'e (yuvarlama düzeyi) indirir ve D_M = 26.49,
# GA = (19.65, 33.32), T² = 2104.46 yayımlanmış değerleri birebir üretilir.
tsong_ref <- tsong_ref_yayimlanan
tsong_ref[4, "30"] <- 78.45

tsong_test <- matrix(c(
  19.99, 36.70, 47.77, 55.08, 65.69, 81.37, 92.39, 97.10,
  22.08, 39.29, 49.46, 56.79, 67.22, 82.42, 89.93, 95.62,
  21.93, 38.54, 47.76, 55.14, 65.25, 83.49, 90.19, 95.62,
  22.44, 39.46, 49.72, 58.67, 69.21, 84.93, 94.12, 95.51,
  25.67, 42.35, 52.68, 59.71, 71.51, 86.61, 93.80, 96.70,
  26.37, 41.34, 51.01, 57.75, 69.44, 85.90, 94.45, 98.07),
  nrow = 6, byrow = TRUE, dimnames = list(paste0("T", 1:6), zamanlar))

tsong_std1 <- matrix(c(
  34.70, 54.77, 65.75, 72.65, 81.24, 90.69, 95.68, 93.37,
  39.43, 59.40, 67.24, 75.23, 83.52, 93.52, 96.14, 96.46,
  40.74, 57.61, 67.50, 74.11, 83.01, 91.63, 93.56, 96.63,
  40.95, 57.53, 69.05, 77.18, 85.02, 92.71, 95.56, 96.38,
  41.34, 59.60, 68.15, 75.18, 82.83, 92.48, 96.00, 96.44,
  41.93, 57.06, 67.33, 76.44, 83.39, 93.60, 97.91, 97.61),
  nrow = 6, byrow = TRUE, dimnames = list(NULL, zamanlar))

tsong_std2 <- matrix(c(
  44.35, 59.22, 64.90, 68.13, 73.10, 77.32, 82.38, 85.51,
  45.30, 61.36, 67.91, 73.93, 78.88, 85.84, 89.68, 90.62,
  47.35, 59.77, 64.79, 68.72, 72.25, 77.06, 81.00, 84.09,
  51.27, 69.35, 74.32, 76.24, 78.24, 86.24, 90.09, 92.01,
  52.32, 64.86, 69.20, 74.43, 79.81, 86.12, 89.96, 91.85,
  50.50, 61.47, 66.22, 70.43, 73.74, 78.81, 82.62, 84.27),
  nrow = 6, byrow = TRUE, dimnames = list(NULL, zamanlar))


# =============================================================================
# TC-1 · Tsong DATA1 — 15 ve 90 dk (P = 2), D_g = 15
# =============================================================================
s1 <- calc_msd(tsong_test[, c("15", "90")], tsong_ref[, c("15", "90")],
               limit = "L1", Dg = 15)

kontrol("TC-1", "d[15]",          "Y", -17.54, s1$d[1], TOL_Y)
kontrol("TC-1", "d[90]",          "Y",   3.39, s1$d[2], TOL_Y)
kontrol("TC-1", "S[1,1]",         "Y",  3.396, s1$S[1, 1], 0.0005)
kontrol("TC-1", "S[1,2]",         "Y",  1.030, s1$S[1, 2], 0.0005)
kontrol("TC-1", "S[2,2]",         "Y",  4.435, s1$S[2, 2], 0.0005)
kontrol("TC-1", "K",              "Y",   1.35, s1$K, TOL_A)          # tam değer
kontrol("TC-1", "F(2,9;0.90)",    "Y",   3.01, s1$F, TOL_Y)
kontrol("TC-1", "D_M",            "Y",  10.44, s1$DM, TOL_Y)
kontrol("TC-1", "D_M alt",        "Y",   8.95, s1$DM_l, TOL_Y)
kontrol("TC-1", "D_M üst",        "Y",  11.93, s1$DM_u, TOL_Y)
kontrol("TC-1", "sınır nok. alt 1","Y", -15.03, s1$sinir_nokta_alt[1], TOL_Y)
kontrol("TC-1", "sınır nok. alt 2","Y",   2.90, s1$sinir_nokta_alt[2], TOL_Y)
kontrol("TC-1", "sınır nok. üst 1","Y", -20.05, s1$sinir_nokta_ust[1], TOL_Y)
kontrol("TC-1", "sınır nok. üst 2","Y",   3.87, s1$sinir_nokta_ust[2], TOL_Y)
kontrol("TC-1", "R_D",            "Y",   9.63, s1$RD, TOL_Y)
kontrol_mantik("TC-1", "karar: benzer değil", "Y", FALSE, s1$benzer_msd)
kontrol("TC-1", "D_M",            "B", 10.440448914919306, s1$DM,   TOL_B)
kontrol("TC-1", "D_M alt",        "B",  8.94813467499969,  s1$DM_l, TOL_B)
kontrol("TC-1", "D_M üst",        "B", 11.932763154838923, s1$DM_u, TOL_B)
kontrol("TC-1", "R_D",            "B",  9.630776502154019, s1$RD,   TOL_B)
kontrol("TC-1", "T²",             "B", 327.0089206351192,  s1$T2,   1e-7)


# =============================================================================
# TC-2 · Tsong DATA2 — 8 zaman noktası, düzeltilmiş veri, D_g = 15
# =============================================================================
s2 <- calc_msd(tsong_test, tsong_ref, limit = "L1", Dg = 15)

kontrol("TC-2", "K",           "Y",  0.1125, s2$K, TOL_A)
kontrol("TC-2", "D_M",         "Y",   26.49, s2$DM, TOL_Y)
kontrol("TC-2", "D_M alt",     "Y",   19.65, s2$DM_l, TOL_Y)
kontrol("TC-2", "D_M üst",     "Y",   33.32, s2$DM_u, TOL_Y)
kontrol("TC-2", "T²",          "Y", 2104.46, s2$T2, TOL_Y)
kontrol("TC-2", "d[30]",       "Y",  -10.02, s2$d["30"], TOL_Y)   # yayımlanan vektör
kontrol_mantik("TC-2", "karar: benzer değil", "Y", FALSE, s2$benzer_msd)
kontrol("TC-2", "D_M",         "B", 26.485616774496517, s2$DM,   TOL_B)
kontrol("TC-2", "D_M üst",     "B", 33.31800440435441,  s2$DM_u, TOL_B)
kontrol("TC-2", "R_D",         "B", 29.140784743440364, s2$RD,   TOL_B)
kontrol("TC-2", "F(8,3;0.90)", "B", 5.251671081521461,  s2$F,    TOL_B)

# Erratum kanıtı: yayımlanmış (hatalı) Tablo 1 verisi farklı sonuç üretir
s2h <- calc_msd(tsong_test, tsong_ref_yayimlanan, limit = "L1", Dg = 15)
kontrol("TC-2e", "D_M (hatalı veri)", "B", 27.054296804590457, s2h$DM, TOL_B)
kontrol_mantik("TC-2e", "hatalı veri yayımlanan D_M'yi üretmez", "Y",
               TRUE, abs(s2h$DM - 26.49) > 0.5)


# =============================================================================
# TC-3 · Lot tabanlı sınırlar (L2a / L2b) — Tsong Tablo 3, STD1 ve STD2
# (Yayımlanmış hedef yok → bağımsız uygulama ile karşılaştırma)
# =============================================================================
lotlar <- list(STD1 = tsong_std1, STD2 = tsong_std2)

s3a <- calc_msd(tsong_test[, c("15", "90")], tsong_ref[, c("15", "90")],
                limit = "L2a", ref_lots = lapply(lotlar, function(m) m[, c("15", "90")]))
s3b <- calc_msd(tsong_test[, c("15", "90")], tsong_ref[, c("15", "90")],
                limit = "L2b", ref_lots = lapply(lotlar, function(m) m[, c("15", "90")]))
kontrol("TC-3", "2 nokta: D_g (L2a)",  "B", 9.853333333333339, s3a$Dg, TOL_B)
kontrol("TC-3", "2 nokta: R_D (L2a)",  "B", 6.326350075637177, s3a$RD, TOL_B)
kontrol("TC-3", "2 nokta: R_D (L2b)",  "B", 4.624820009597654, s3b$RD, TOL_B)

s3c <- calc_msd(tsong_test, tsong_ref, limit = "L2a", ref_lots = lotlar)
s3d <- calc_msd(tsong_test, tsong_ref, limit = "L2b", ref_lots = lotlar)
kontrol("TC-3", "8 nokta: D_g (L2a)",  "B", 10.54,              s3c$Dg, TOL_B)
kontrol("TC-3", "8 nokta: R_D (L2a)",  "B", 20.476258079724115, s3c$RD, TOL_B)
kontrol("TC-3", "8 nokta: R_D (L2b)",  "B",  9.167244574421542, s3d$RD, TOL_B)


# =============================================================================
# TC-4 · Analitik vaka — MSD "benzer", L3 hiperküp "benzer değil"
# EMA Q&A 3.9 itirazının deterministik gösterimi
#
# Tasarım: 12+12 ünite, 2 zaman noktası (10 ve 30 dk)
#   u, v ortogonal, ortalaması 0, varyansı (n-1 paydalı) tam 1 olan vektörler
#   → S = diag(8², 2²) tam olarak; korelasyon 0
#   REF ort. = (25, 80), TEST ort. = (37, 80) → d = (12, 0)
#
# Kapalı form beklenen değerler:
#   D_M = 12/8 = 1.5 ;  T² = 6 · 1.5² = 13.5
#   K   = 6 · 21 / (22 · 2) = 63/22
#   F(2, 21; 0.90) = (21/2)·(0.1^(-2/21) - 1)   [ν1 = 2 için F kantilinin kapalı formu]
#   r   = √(F/K) ;  D_M^üst = 1.5 + r ≈ 2.448
#   R_D = √(10²/64 + 10²/4) = √26.5625 ≈ 5.154  → MSD: BENZER
#   L3, 10 dk: |12| + 8r ≈ 19.59 > 10          → L3: BENZER DEĞİL
#   Üstelik nokta tahmini düzeyinde bile fark 12 > 10.
# =============================================================================
u <- c(rep(-1, 6), rep(1, 6)) * sqrt(11 / 12)
v <- rep(c(-1, 1), 6)         * sqrt(11 / 12)
tc4_ref  <- cbind(`10` = 25 + 8 * u, `30` = 80 + 2 * v)
tc4_test <- cbind(`10` = 37 + 8 * u, `30` = 80 + 2 * v)
s4 <- calc_msd(tc4_test, tc4_ref, limit = "L1", Dg = 10)

F_kapali <- (21 / 2) * (0.1^(-2 / 21) - 1)
K_kapali <- 63 / 22
r_kapali <- sqrt(F_kapali / K_kapali)
kontrol("TC-4", "S[1,1] = 64",   "A", 64,                 s4$S[1, 1], TOL_A)
kontrol("TC-4", "S[1,2] = 0",    "A", 0,                  s4$S[1, 2], TOL_A)
kontrol("TC-4", "S[2,2] = 4",    "A", 4,                  s4$S[2, 2], TOL_A)
kontrol("TC-4", "D_M = 1.5",     "A", 1.5,                s4$DM, TOL_A)
kontrol("TC-4", "T² = 13.5",     "A", 13.5,               s4$T2, TOL_A)
kontrol("TC-4", "K = 63/22",     "A", K_kapali,           s4$K,  TOL_A)
kontrol("TC-4", "F kapalı form", "A", F_kapali,           s4$F,  TOL_A)
kontrol("TC-4", "D_M üst",       "A", 1.5 + r_kapali,     s4$DM_u, TOL_A)
kontrol("TC-4", "R_D",           "A", sqrt(26.5625),      s4$RD, TOL_A)
kontrol("TC-4", "L3 uç nokta 10dk","A", 12 + 8 * r_kapali, s4$L3$uc_nokta[1], TOL_A)
kontrol("TC-4", "L3 uç nokta 30dk","A", 0 + 2 * r_kapali,  s4$L3$uc_nokta[2], TOL_A)
kontrol_mantik("TC-4", "MSD kararı: BENZER",       "A", TRUE,  s4$benzer_msd)
kontrol_mantik("TC-4", "L3 kararı: BENZER DEĞİL",  "A", FALSE, s4$benzer_L3)


# =============================================================================
# TC-5 · %85 kesme kuralları [FDA97 V.A; EMA10 App. I; EMAQA 3.11]
# =============================================================================
kontrol("TC-5", "none: 3 nokta", "A", 3, length(msd_truncate(c(50, 86, 95), c(40, 80, 90), "none")), 0)
kontrol("TC-5", "EMA: 2 nokta (biri >85)", "A", 2,
        length(msd_truncate(c(50, 86, 95), c(40, 80, 90), "EMA")), 0)
kontrol("TC-5", "FDA: 3 nokta (ikisi >85)", "A", 3,
        length(msd_truncate(c(50, 86, 95), c(40, 80, 90), "FDA")), 0)
kontrol("TC-5", "Tsong EMA: 7 nokta (90 dk dahil)", "A", 7,
        length(msd_truncate(colMeans(tsong_test), colMeans(tsong_ref), "EMA")), 0)


# =============================================================================
# TC-6 · Hata yakalama
# =============================================================================
hata_var <- function(expr) inherits(try(expr, silent = TRUE), "try-error")
kontrol_mantik("TC-6", "P > nT+nR-2 reddedilir", "A", TRUE,
               hata_var(calc_msd(tsong_test[1:3, ], tsong_ref[1:3, ])))
kontrol_mantik("TC-6", "L2 tek lotla reddedilir", "A", TRUE,
               hata_var(calc_msd(tsong_test, tsong_ref, limit = "L2a", ref_lots = list(tsong_std1))))
kontrol_mantik("TC-6", "sütun uyuşmazlığı reddedilir", "A", TRUE,
               hata_var(calc_msd(tsong_test[, 1:3], tsong_ref[, 2:4])))


# ---- Özet -------------------------------------------------------------------
cat("\n==================== VALİDASYON ÖZETİ (1A) ====================\n")
print(.sonuclar[, c("TC", "kontrol", "kaynak", "beklenen", "hesaplanan", "fark", "durum")],
      row.names = FALSE, digits = 10)
cat(sprintf("\nToplam: %d kontrol · GEÇTİ: %d · KALDI: %d\n",
            nrow(.sonuclar), sum(.sonuclar$durum == "GEÇTİ"), sum(.sonuclar$durum == "KALDI")))
