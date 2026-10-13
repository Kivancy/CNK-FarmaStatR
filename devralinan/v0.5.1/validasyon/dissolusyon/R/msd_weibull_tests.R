# =============================================================================
# FarmaStatR — Dissolüsyon Modülü 1B · Validasyon test vakaları
#
# Referans değer kaynakları:
#   (Y) Yayımlanmış — Sathe ve ark. 1996 Tablo III (3 ondalık) → tolerans 0.0005–0.001
#   (B) Bağımsız uygulama — Python/NumPy; B-L2b ve B-L3 için elips sınırında
#       2 000 000 noktalık kaba kuvvet ızgarası (R: ızgara + optimize) → 1e-8 / 1e-6
#   (A) Analitik kapalı form → 1e-10
#
# Çalıştırma: source("msd_core.R"); source("msd_weibull.R"); source("msd_weibull_tests.R")
# =============================================================================

# Tsong verisi ve test altyapısı 1A test dosyasından alınır; 1A sonuçları sıfırlanır
invisible(capture.output(source("msd_tests.R", encoding = "UTF-8")))
.sonuclar <- .sonuclar[0, ]
TOL_GRID <- 1e-6


# =============================================================================
# TC-B1 · Analitik vaka — artıksız Weibull verisi, (ln α, ln β)
#
# 12 + 12 ünite; u, v 1A TC-4'teki ortogonal birim varyanslı vektörler.
#   REF : ln α = -3.0 + 0.2u ,  ln β = 0.05v
#   TEST: ln α = -2.8 + 0.2u ,  ln β = 0.05v
#   Veri: X_ij = 100·[1 - exp(-α_i·t^β_i)], t = 10, 15, 20, 30, 45, 60 dk (tümü 0-100 arası)
# Doğrusallaştırılmış EKK, artıksız veride parametreleri tam olarak geri verir:
#   S = diag(0.04, 0.0025), d = (0.2, 0) → D_M = 0.2/0.2 = 1, T² = 6
#   İzdüşüm: ln α ∈ 0.2 ± 0.2r ,  ln β ∈ 0 ± 0.05r ,  r = √(F(2,21;0.90)/(63/22))
# =============================================================================
tB <- c(10, 15, 20, 30, 45, 60)
uret <- function(lnA, lnB) t(sapply(seq_along(lnA), function(i)
  weibull_F(tB, lnA[i], exp(lnB[i]))))
b1_R <- uret(-3.0 + 0.2 * u, 0.05 * v)
b1_T <- uret(-2.8 + 0.2 * u, 0.05 * v)
fR1  <- weibull_fit_units(b1_R, tB, param = "lnA_lnB")
fT1  <- weibull_fit_units(b1_T, tB, param = "lnA_lnB")

r_k  <- sqrt(((21 / 2) * (0.1^(-2 / 21) - 1)) / (63 / 22))
kontrol("TC-B1", "uydurma: max|ln α - tasarım|", "A", 0,
        max(abs(fR1$theta[, 1] - (-3 + 0.2 * u))), 1e-10)
kontrol("TC-B1", "uydurma: max|ln β - tasarım|", "A", 0,
        max(abs(fR1$theta[, 2] - 0.05 * v)), 1e-10)
kontrol("TC-B1", "uydurma: min R² = 1", "A", 1, min(fR1$tablo$R2), 1e-12)

s_b1 <- calc_msd_params(fT1$theta, fR1$theta, param = "lnA_lnB", region = "B-L3", times = tB)
m <- s_b1$motor
kontrol("TC-B1", "S[1,1] = 0.04",    "A", 0.04,   m$S[1, 1], 1e-10)
kontrol("TC-B1", "S[2,2] = 0.0025",  "A", 0.0025, m$S[2, 2], 1e-10)
kontrol("TC-B1", "S[1,2] = 0",       "A", 0,      m$S[1, 2], 1e-10)
kontrol("TC-B1", "D_M = 1",          "A", 1,      m$DM, 1e-10)
kontrol("TC-B1", "T² = 6",           "A", 6,      m$T2, 1e-9)
kontrol("TC-B1", "D_M üst = 1 + r",  "A", 1 + r_k, m$DM_u, 1e-10)
kontrol("TC-B1", "izd. ln α alt",    "A", 0.2 - 0.2 * r_k,  m$izd_alt[1], 1e-10)
kontrol("TC-B1", "izd. ln α üst",    "A", 0.2 + 0.2 * r_k,  m$izd_ust[1], 1e-10)
kontrol("TC-B1", "izd. ln β üst",    "A", 0.05 * r_k,       m$izd_ust[2], 1e-10)


# =============================================================================
# TC-B1a · B-L2a Sathe kutusu — analitik
#   3 lot × 12 ünite: ln α = m_i + 0.2u, ln β = n_i + 0.05v
#   m = (-3, -2.9, -3.1), n = (0, 0.02, -0.02)
#   Lot içi varyans = (0.04, 0.0025); lot ortalamalarının varyansı = (0.01, 0.0004)
#   SD_havuz = (√0.05, √0.0029)
#   k = 3: kutu ±(0.6708, 0.1616) → izdüşümler içinde → BENZER
#   k = 1: kutu ±(0.2236, 0.0539); ln α üst = 0.2 + 0.2r ≈ 0.39 > 0.2236 → BENZER DEĞİL
# =============================================================================
lotlar_b <- lapply(1:3, function(i)
  cbind(ln_alpha = c(-3, -2.9, -3.1)[i] + 0.2 * u, ln_beta = c(0, 0.02, -0.02)[i] + 0.05 * v))
s_a3 <- calc_msd_params(fT1$theta, fR1$theta, param = "lnA_lnB", region = "B-L2a", lot_theta = lotlar_b, k_sd = 3)
s_a1 <- calc_msd_params(fT1$theta, fR1$theta, param = "lnA_lnB", region = "B-L2a", lot_theta = lotlar_b, k_sd = 1)
kontrol("TC-B1a", "SD_havuz ln α = √0.05",   "A", sqrt(0.05),   s_a3$lot$SD_havuz[1], 1e-10)
kontrol("TC-B1a", "SD_havuz ln β = √0.0029", "A", sqrt(0.0029), s_a3$lot$SD_havuz[2], 1e-10)
kontrol_mantik("TC-B1a", "k = 3: BENZER",       "A", TRUE,  s_a3$benzer)
kontrol_mantik("TC-B1a", "k = 1: BENZER DEĞİL", "A", FALSE, s_a1$benzer)


# =============================================================================
# TC-B1b · B-L3 kapalı form — (ln α, β) parametrizasyonu
#   z_t = ln α + β·ln t, a_t = (1, ln t) ile doğrusal → elips üzerindeki uç değerler:
#   z_t^{alt,üst} = z_t(θ̄R) + a_t'd ∓ r·√(a_t' S a_t)   (kapalı form)
#   REF : ln α = -3.0 + 0.2u , β = 1 + 0.05v ;  TEST: ln α = -2.8 + 0.2u , β aynı
#   Bu vaka, elips_uc() sınır aramasını kapalı forma karşı doğrular.
# =============================================================================
thR <- cbind(ln_alpha = -3.0 + 0.2 * u, beta = 1 + 0.05 * v)
thT <- cbind(ln_alpha = -2.8 + 0.2 * u, beta = 1 + 0.05 * v)
s_b1b <- calc_msd_params(thT, thR, param = "lnA_B", region = "B-L3", times = tB)
mb <- s_b1b$motor
G <- function(z) 100 * (1 - exp(-exp(z)))
for (i in seq_along(tB)) {
  a  <- c(1, log(tB[i]))
  zR <- sum(a * mb$ort_R)
  zc <- zR + sum(a * mb$d); w <- mb$r * sqrt(drop(t(a) %*% mb$S %*% a))
  beklenen <- max(abs(G(zc - w) - G(zR)), abs(G(zc + w) - G(zR)))
  kontrol("TC-B1b", sprintf("B-L3 maks fark t=%g (kapalı form)", tB[i]), "A",
          beklenen, s_b1b$bolge_tablo$maks_fark[i], 1e-9)
}


# =============================================================================
# TC-B2 · Sathe ve ark. 1996 Tablo III — yayımlanmış altın standart
#   Parametreler tablodan doğrudan alınır (ünite ham verisi makalede yoktur).
#   Zaman birimi SAAT'tir (Tablo I ile uyum: α ≈ 1.1, 30 dk ≈ %40).
# =============================================================================
sathe_R <- cbind(
  ln_alpha = c(0.09744, 0.01996, 0.06189, 0.03252, 0.42637, 0.45262, 0.16665, 0.03404,
               -0.00882, 0.06601, 0.15522, 0.30426),
  ln_beta  = c(0.24019, 0.17189, 0.09067, 0.08317, 0.11511, 0.09101, 0.19157, 0.02679,
               0.11676, 0.21869, 0.14885, 0.09354))
sathe_mm <- cbind(
  ln_alpha = c(0.10113, -0.02125, -0.0379, 0.04413, 0.01899, -0.06036, 0.02915, 0.06607,
               -0.05216, -0.08066, 0.04367, 0.05669),
  ln_beta  = c(0.22432, -0.01609, 0.02665, 0.08167, 0.00331, 0.11665, 0.06148, 0.00524,
               0.12689, 0.14218, 0.01944, 0.15304))
sathe_MM <- cbind(
  ln_alpha = c(-0.39733, -0.26498, -0.33216, -0.13259, -0.06154, -0.18537, -0.14436,
               -0.18249, -0.28009, -0.11556, -0.17148, -0.25927),
  ln_beta  = c(0.46819, 0.4407, 0.42752, 0.36979, 0.29601, 0.34008, 0.34816, 0.37782,
               0.39551, 0.33722, 0.3575, 0.42384))
t_saat <- c(0.5, 1, 1.5, 3)

s_mm <- calc_msd_params(sathe_mm, sathe_R, param = "lnA_lnB", region = "B-L3", times = t_saat)
s_MM <- calc_msd_params(sathe_MM, sathe_R, param = "lnA_lnB", region = "B-L3", times = t_saat)
kontrol("TC-B2", "mm: fark ln α",    "Y", -0.14172,  s_mm$motor$d[1], 0.00001)
kontrol("TC-B2", "mm: fark ln β",    "Y", -0.05362,  s_mm$motor$d[2], 0.00001)
kontrol("TC-B2", "mm: D_M",          "Y",  1.463,    s_mm$motor$DM, 0.0005)
kontrol("TC-B2", "mm: T² (ölçekli M)","Y", 12.835,   s_mm$motor$T2, 0.0005)
kontrol("TC-B2", "mm: GA ln α alt",  "Y", -0.255,    s_mm$motor$izd_alt[1], 0.0005)
kontrol("TC-B2", "mm: GA ln α üst",  "Y", -0.028,    s_mm$motor$izd_ust[1], 0.0005)
kontrol("TC-B2", "mm: GA ln β alt",  "Y", -0.119,    s_mm$motor$izd_alt[2], 0.0005)
kontrol("TC-B2", "mm: GA ln β üst",  "Y",  0.011,    s_mm$motor$izd_ust[2], 0.001)
kontrol("TC-B2", "MM: fark ln α",    "Y", -0.36128,  s_MM$motor$d[1], 0.00001)
kontrol("TC-B2", "MM: fark ln β",    "Y",  0.2495064, s_MM$motor$d[2], 0.00001)
kontrol("TC-B2", "MM: D_M",          "Y",  4.508,    s_MM$motor$DM, 0.0005)
kontrol("TC-B2", "MM: T² (ölçekli M)","Y", 121.948,  s_MM$motor$T2, 0.0005)
kontrol("TC-B2", "MM: GA ln α alt",  "Y", -0.486,    s_MM$motor$izd_alt[1], 0.0005)
kontrol("TC-B2", "MM: GA ln α üst",  "Y", -0.236,    s_MM$motor$izd_ust[1], 0.0005)
kontrol("TC-B2", "MM: GA ln β alt",  "Y",  0.195,    s_MM$motor$izd_alt[2], 0.0005)
kontrol("TC-B2", "MM: GA ln β üst",  "Y",  0.304,    s_MM$motor$izd_ust[2], 0.0005)
kontrol("TC-B2", "mm: D_M",          "B", 1.462595216884327, s_mm$motor$DM, 1e-8)
kontrol("TC-B2", "mm: T²",           "B", 12.83510861071747, s_mm$motor$T2, 1e-7)
b2_L3 <- c(6.681859591465475, 9.363535995244881, 9.027505776630747, 3.7970927260370075)
for (i in 1:4)
  kontrol("TC-B2", sprintf("mm: B-L3 maks fark t=%g sa", t_saat[i]), "B",
          b2_L3[i], s_mm$bolge_tablo$maks_fark[i], TOL_GRID)
kontrol_mantik("TC-B2", "mm: B-L3 BENZER (Sathe: 3SD içinde)",   "Y", TRUE,  s_mm$benzer)
kontrol_mantik("TC-B2", "MM: B-L3 BENZER DEĞİL (Sathe: dışında)", "Y", FALSE, s_MM$benzer)

# Erratum 1: Tablo III'te mm ortalama ln α "−0.0089583" basılmış; doğrusu +0.0089583
kontrol("TC-B2e", "mm ort. ln α = +0.0089583", "Y", 0.0089583, mean(sathe_mm[, 1]), 1e-6)
# Erratum 2: basılı K' = [(N1+N2-P-1)/((N1+N2-2)P)]·[N1N2/(N1+N2-P)] yayımlanan GA'yı üretmez
K_basili <- (21 / (22 * 2)) * (144 / 22)
r_basili <- sqrt(stats::qf(0.9, 2, 21) / K_basili)
ga_basili <- unname(s_mm$motor$d[1] + r_basili * sqrt(s_mm$motor$S[1, 1]))
kontrol_mantik("TC-B2e", "basılı K' ile GA üst ≠ −0.028", "Y", TRUE, abs(ga_basili - (-0.028)) > 0.004)


# =============================================================================
# TC-B3 · Tsong verisi — ham veriden uçtan uca (W2-LIN + MSD + 3 bölge)
#   Zaman: dakika. Referans lotları: Tsong Tablo 3 STD1, STD2.
# =============================================================================
tT <- c(5, 10, 15, 20, 30, 60, 90, 120)
lotlar_ts <- list(STD1 = tsong_std1, STD2 = tsong_std2)
b3_a  <- calc_msd_weibull(tsong_test, tsong_ref, tT, param = "lnA_lnB", ref_lots = lotlar_ts, region = "B-L2a")
b3_bN <- calc_msd_weibull(tsong_test, tsong_ref, tT, param = "lnA_lnB", ref_lots = lotlar_ts, region = "B-L2b")
b3_bS <- calc_msd_weibull(tsong_test, tsong_ref, tT, param = "lnA_lnB", ref_lots = lotlar_ts, region = "B-L2b",
                          sr_bolen = "sqrtN")
b3_3  <- calc_msd_weibull(tsong_test, tsong_ref, tT, param = "lnA_lnB", region = "B-L3")
kontrol("TC-B3", "ort. ln α TEST", "B", -2.5217376896579107, b3_a$motor$ort_T[1], 1e-8)
kontrol("TC-B3", "ort. ln β TEST", "B", -0.25231582099171035, b3_a$motor$ort_T[2], 1e-8)
kontrol("TC-B3", "ort. ln α REF",  "B", -1.05519610370217,   b3_a$motor$ort_R[1], 1e-8)
kontrol("TC-B3", "ort. ln β REF",  "B", -0.8795222337946654, b3_a$motor$ort_R[2], 1e-8)
kontrol("TC-B3", "D_M",            "B", 10.812309875347891,  b3_a$motor$DM, 1e-8)
kontrol("TC-B3", "D_M üst",        "B", 12.304624115267508,  b3_a$motor$DM_u, 1e-8)
kontrol("TC-B3", "SD_havuz ln α",  "B", 0.48077073604685744, b3_a$lot$SD_havuz[1], 1e-8)
kontrol("TC-B3", "SD_havuz ln β",  "B", 0.3970945225214074,  b3_a$lot$SD_havuz[2], 1e-8)
kontrol("TC-B3", "B-L2b max (Σ2/N)",  "B", 655.5887200809998, b3_bN$SR$maks_nicelik, 1e-5)
kontrol("TC-B3", "B-L2b max (Σ2/√N)", "B", 275.16383710456773, b3_bS$SR$maks_nicelik, 1e-5)
kontrol("TC-B3", "B-L2b F(2,9;0.99)", "B", 8.021517309932058, b3_bN$SR$F_sr, 1e-8)
b3_L3 <- c(26.936308806362455, 24.210250905846223, 21.087284810061576, 18.241351448651187,
           13.559904957426994, 5.881143176047715, 7.220654417003672, 6.644985997733045)
for (i in 1:8)
  kontrol("TC-B3", sprintf("B-L3 maks fark t=%g", tT[i]), "B",
          b3_L3[i], b3_3$bolge_tablo$maks_fark[i], TOL_GRID)

# Aynı veri, (ln α, β) parametrizasyonu — D_M'nin parametrizasyona bağlılığı
b3_B <- calc_msd_weibull(tsong_test, tsong_ref, tT, param = "lnA_B", region = "B-L3")
kontrol("TC-B3", "D_M (ln α, β)",  "B", 10.547026541596258, b3_B$motor$DM, 1e-8)


# =============================================================================
# TC-B4 · Zaman birimi duyarlılığı — analitik özellik
#   t → t/60 (dk → saat): ln α' = ln α + β·ln 60.
#   (ln α, β)   : doğrusal dönüşüm → D_M DEĞİŞMEZ (Mahalanobis afin değişmezliği)
#   (ln α, ln β): doğrusal olmayan dönüşüm → D_M DEĞİŞİR
#   Sonuç: zaman birimi, (ln α, ln β) parametrizasyonunda yöntemin bir parçasıdır.
# =============================================================================
d_dk_B  <- calc_msd_weibull(tsong_test, tsong_ref, tT,      param = "lnA_B",   region = "B-L3")$motor$DM
d_sa_B  <- calc_msd_weibull(tsong_test, tsong_ref, tT / 60, param = "lnA_B",   region = "B-L3")$motor$DM
d_dk_lB <- calc_msd_weibull(tsong_test, tsong_ref, tT,      param = "lnA_lnB", region = "B-L3")$motor$DM
d_sa_lB <- calc_msd_weibull(tsong_test, tsong_ref, tT / 60, param = "lnA_lnB", region = "B-L3")$motor$DM
kontrol("TC-B4", "(ln α, β): D_M dk = D_M saat", "A", d_dk_B, d_sa_B, 1e-9)
kontrol_mantik("TC-B4", "(ln α, ln β): D_M dk ≠ D_M saat", "A", TRUE, abs(d_dk_lB - d_sa_lB) > 1e-3)


# =============================================================================
# TC-B5 · Dışlama kuralları ve hata yakalama
# =============================================================================
x_d <- b1_R; x_d[1, 6] <- 100; x_d[2, 1] <- 0
f_d <- weibull_fit_units(x_d, tB)
kontrol("TC-B5", "X = 100 dışlandı (5 nokta kaldı)", "A", 5, f_d$tablo$n_nokta[1], 0)
kontrol("TC-B5", "X = 0 dışlandı (5 nokta kaldı)",   "A", 5, f_d$tablo$n_nokta[2], 0)
x_e <- b1_R; x_e[1, 3:6] <- 100
kontrol_mantik("TC-B5", "< 3 geçerli nokta reddedilir", "A", TRUE,
               hata_var(weibull_fit_units(x_e, tB)))
x_n <- b1_R; x_n[1, ] <- rev(x_n[1, ])
kontrol_mantik("TC-B5", "negatif eğim (ln β tanımsız) reddedilir", "A", TRUE,
               hata_var(weibull_fit_units(x_n, tB)))
kontrol_mantik("TC-B5", "B-L2a lotsuz reddedilir", "A", TRUE,
               hata_var(calc_msd_params(fT1$theta, fR1$theta, region = "B-L2a")))
kontrol_mantik("TC-B5", "B-L3 zamansız reddedilir", "A", TRUE,
               hata_var(calc_msd_params(fT1$theta, fR1$theta, region = "B-L3")))


# =============================================================================
# TC-B6 · (ln T_d, ln β) — VARSAYILAN parametrizasyon
#   FarmaStatR türetimi: T_d [LANGENBUCHER72] + ln β [SATHE96]; ln T_d = -ln α / β
# =============================================================================
# (a) Analitik: artıksız veri, ln T_d = 3.0 + 0.2u (REF), 3.2 + 0.2u (TEST), ln β = 0.05v
#     X = 100·[1 - exp(-(t/T_d)^β)]  →  S = diag(0.04, 0.0025), d = (0.2, 0), D_M = 1
uretTd <- function(lnTd, lnB) t(sapply(seq_along(lnTd), function(i)
  100 * (1 - exp(-(tB / exp(lnTd[i]))^exp(lnB[i])))))
fR6 <- weibull_fit_units(uretTd(3.0 + 0.2 * u, 0.05 * v), tB)
fT6 <- weibull_fit_units(uretTd(3.2 + 0.2 * u, 0.05 * v), tB)
kontrol_mantik("TC-B6", "varsayılan param = lnTd_lnB", "A", TRUE, identical(fR6$param, "lnTd_lnB"))
kontrol("TC-B6", "uydurma: max|ln T_d - tasarım|", "A", 0, max(abs(fR6$theta[, 1] - (3 + 0.2 * u))), 1e-10)
kontrol("TC-B6", "uydurma: T_d = exp(ln T_d)", "A", 0, max(abs(fR6$tablo$Td - exp(3 + 0.2 * u))), 1e-9)
s6 <- calc_msd_params(fT6$theta, fR6$theta, region = "B-L3", times = tB)
kontrol("TC-B6", "D_M = 1",      "A", 1,      s6$motor$DM, 1e-10)
kontrol("TC-B6", "S[1,1] = 0.04","A", 0.04,   s6$motor$S[1, 1], 1e-10)

# (b) Tsong verisi — bağımsız uygulama (Python)
b6   <- calc_msd_weibull(tsong_test, tsong_ref, tT, ref_lots = lotlar_ts, region = "B-L3")
b6bN <- calc_msd_weibull(tsong_test, tsong_ref, tT, ref_lots = lotlar_ts, region = "B-L2b")
b6a  <- calc_msd_weibull(tsong_test, tsong_ref, tT, ref_lots = lotlar_ts, region = "B-L2a")
kontrol("TC-B6", "Tsong D_M",           "B", 8.55885592940262,   b6$motor$DM, 1e-8)
kontrol("TC-B6", "Tsong D_M üst",       "B", 10.051170169322237, b6$motor$DM_u, 1e-8)
kontrol("TC-B6", "Tsong ort. ln T_d TEST", "B", 3.243319239436173, b6$motor$ort_T[1], 1e-8)
kontrol("TC-B6", "SD_havuz ln T_d",     "B", 0.19864521594306156, b6a$lot$SD_havuz[1], 1e-8)
kontrol("TC-B6", "B-L2b maks (Σ2/N)",   "B", 136.98259916212223, b6bN$SR$maks_nicelik, 1e-5)
b6_L3 <- c(30.066827397789453, 27.354480505969875, 23.440432690035713, 19.657874153772774,
           13.356249763110874, 3.1761834266275457, 5.315960726406274, 5.485275833220015)
for (i in 1:8)
  kontrol("TC-B6", sprintf("B-L3 maks fark t=%g", tT[i]), "B",
          b6_L3[i], b6$bolge_tablo$maks_fark[i], TOL_GRID)

# (c) Zaman birimi değişmezliği: dakika = saat = saniye
b6_sa <- calc_msd_weibull(tsong_test, tsong_ref, tT / 60, region = "B-L3")
b6_sn <- calc_msd_weibull(tsong_test, tsong_ref, tT * 60, region = "B-L3")
kontrol("TC-B6", "D_M dk = D_M saat",   "A", b6$motor$DM, b6_sa$motor$DM, 1e-9)
kontrol("TC-B6", "D_M dk = D_M saniye", "A", b6$motor$DM, b6_sn$motor$DM, 1e-9)
kontrol("TC-B6", "B-L3 dk = saat (maks |fark|)", "A", 0,
        max(abs(b6$bolge_tablo$maks_fark - b6_sa$bolge_tablo$maks_fark)), 1e-7)
kontrol("TC-B6", "B-L3 dk = saniye (maks |fark|)", "A", 0,
        max(abs(b6$bolge_tablo$maks_fark - b6_sn$bolge_tablo$maks_fark)), 1e-7)


# ---- Özet -------------------------------------------------------------------
cat("\n==================== VALİDASYON ÖZETİ (1B) ====================\n")
print(.sonuclar[, c("TC", "kontrol", "kaynak", "beklenen", "hesaplanan", "fark", "durum")],
      row.names = FALSE, digits = 10)
cat(sprintf("\nToplam: %d kontrol · GEÇTİ: %d · KALDI: %d\n",
            nrow(.sonuclar), sum(.sonuclar$durum == "GEÇTİ"), sum(.sonuclar$durum == "KALDI")))

