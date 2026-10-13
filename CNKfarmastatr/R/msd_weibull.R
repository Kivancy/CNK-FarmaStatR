# =============================================================================
# FarmaStatR — Dissolüsyon Modülü, Bölüm 1B
# Model bağımlı yaklaşım: Weibull parametreleri üzerinde MSD
#
# Dayanaklar:
#   [FDA97]  FDA Dissolution Testing of IR Solid Oral Dosage Forms (1997), Bölüm V.C
#   [SATHE96] Sathe PM, Tsong Y, Shah VP. In-vitro dissolution profile comparison:
#            statistics and analysis, model dependent approach.
#            Pharm Res 1996;13(12):1799-1803
#   [TSONG96] Drug Inf J 1996;30:1105-1112 (güven bölgesi, Denk. 3)
#   [EMA10]  CPMP/EWP/QWP/1401/98 Rev.1 (2010), Appendix I
#   [MUSELIK21] Pharmaceutics 2021;13:1703 (%10 koşulunun parametre uzayına çevrilmesi)
#   [LANGENBUCHER72] Langenbucher F. Linearization of dissolution rate curves by the
#            Weibull distribution. J Pharm Pharmacol 1972;24:979-981 (dissolüsyon zamanı T_d)
#
# Gereksinim: msd_core.R (msd_engine, msd_pooled_cov) önce yüklenmiş olmalı.
# Sürüm : 0.2.0 — (ln T_d, ln β) parametrizasyonu eklendi ve varsayılan yapıldı
# =============================================================================


# -----------------------------------------------------------------------------
# Weibull modeli [SATHE96 s.1800]
#   X(t) = 100 · [1 - exp(-α · t^β)]
#   Doğrusallaştırılmış: ln(-ln(1 - X/100)) = ln α + β · ln t
# Parametrizasyon (MSD'nin hesaplandığı vektör):
#   "lnTd_lnB": (ln T_d, ln β) — VARSAYILAN. FarmaStatR türetimi:
#               T_d LANGENBUCHER72'nin dissolüsyon zamanı (%63.2 çözünme süresi),
#               ln β SATHE96'nın dönüşümü. ln T_d = -ln α / β.
#               Zaman birimi değişince ln T_d tüm ünitelerde aynı sabit kadar kayar
#               → D_M ve B-L3 zaman biriminden BAĞIMSIZDIR (TC-B6).
#   "lnA_lnB" : (ln α, ln β)  — SATHE96 (yayımlanmış sonuçları üretmek için)
#   "lnA_B"   : (ln α, β)     — alternatif; B-L3 kapalı forma iner
# Her üç durumda da F(t) = G(z_t), G(z) = 100·[1 - exp(-e^z)] kesin artan;
# z_t parametrizasyona göre:
#   lnTd_lnB : z_t = e^θ2 · (ln t - θ1)      gradyan (-e^θ2, e^θ2(ln t - θ1)) ≠ 0
#   lnA_lnB  : z_t = θ1 + e^θ2 · ln t        gradyan (1, e^θ2 ln t) ≠ 0
#   lnA_B    : z_t = θ1 + θ2 · ln t          gradyan (1, ln t) ≠ 0
# -----------------------------------------------------------------------------
weibull_F <- function(t, lnA, beta) 100 * (1 - exp(-exp(lnA + beta * log(t))))

PARAMLAR <- c("lnTd_lnB", "lnA_lnB", "lnA_B")

z_weibull <- function(theta, t, param) {
  switch(param,
         lnTd_lnB = exp(theta[2]) * (log(t) - theta[1]),
         lnA_lnB  = theta[1] + exp(theta[2]) * log(t),
         lnA_B    = theta[1] + theta[2] * log(t))
}

# -----------------------------------------------------------------------------
# Ünite bazında doğrusallaştırılmış Weibull uydurması (W2-LIN) [SATHE96]
#   X     : ünite × zaman matrisi (% çözünen)
#   times : zaman noktaları (X sütunlarıyla aynı sıra)
# Kurallar:
#   - t ≤ 0, X ≤ 0 ve X ≥ 100 noktaları dönüşümde tanımsızdır → dışlanır
#   - her ünitede en az 3 geçerli nokta gerekir
#   - eğim β ≤ 0 ise ln β tanımsızdır → hata
# -----------------------------------------------------------------------------
weibull_fit_units <- function(X, times, param = PARAMLAR, min_nokta = 3) {
  param <- match.arg(param)
  X <- as.matrix(X); times <- as.numeric(times)
  if (length(times) != ncol(X)) stop("times uzunluğu X'in sütun sayısına eşit olmalı.")
  if (anyNA(X)) stop("Veride NA var.")

  uniteler <- rownames(X) %||% paste0("U", seq_len(nrow(X)))
  sonuc <- lapply(seq_len(nrow(X)), function(i) {
    x <- X[i, ]
    gecerli <- times > 0 & x > 0 & x < 100
    if (sum(gecerli) < min_nokta)
      stop(sprintf("Ünite %s: geçerli nokta sayısı %d < %d (0 < X < 100, t > 0).",
                   uniteler[i], sum(gecerli), min_nokta))
    lx <- log(times[gecerli])
    y  <- log(-log(1 - x[gecerli] / 100))
    # Basit doğrusal regresyon — kapalı form EKK
    b  <- sum((lx - mean(lx)) * (y - mean(y))) / sum((lx - mean(lx))^2)
    a  <- mean(y) - b * mean(lx)
    if (b <= 0 && param != "lnA_B")
      stop(sprintf("Ünite %s: eğim β = %.4g ≤ 0; ln β tanımsız.", uniteler[i], b))
    yhat <- a + b * lx
    R2 <- 1 - sum((y - yhat)^2) / sum((y - mean(y))^2)
    list(lnA = a, beta = b, n = sum(gecerli), R2 = R2,
         dislanan = paste(times[!gecerli], collapse = ", "))
  })

  tab <- data.frame(
    unite    = uniteler,
    alpha    = exp(sapply(sonuc, `[[`, "lnA")),
    beta     = sapply(sonuc, `[[`, "beta"),
    lnA      = sapply(sonuc, `[[`, "lnA"),
    n_nokta  = sapply(sonuc, `[[`, "n"),
    R2       = sapply(sonuc, `[[`, "R2"),
    dislanan = sapply(sonuc, `[[`, "dislanan"),
    stringsAsFactors = FALSE)

  tab$Td <- exp(-tab$lnA / tab$beta)              # %63.2 çözünme süresi [LANGENBUCHER72]
  theta <- switch(param,
    lnTd_lnB = cbind(ln_Td = -tab$lnA / tab$beta, ln_beta = log(tab$beta)),
    lnA_lnB  = cbind(ln_alpha = tab$lnA, ln_beta = log(tab$beta)),
    lnA_B    = cbind(ln_alpha = tab$lnA, beta = tab$beta))
  rownames(theta) <- uniteler
  list(theta = theta, tablo = tab, param = param)
}


# -----------------------------------------------------------------------------
# Güven elipsinin sınırı üzerinde bir fonksiyonun uç değerlerini bulur (P = 2).
#   Elips: y = d + r · L · (cos φ, sin φ),  S = L L'
#   g(y) sürekli türevlenebilir ve gradyanı hiç sıfır olmuyorsa uç değerleri
#   sınırdadır; φ üzerinde ızgara + yerel iyileştirme yapılır.
# -----------------------------------------------------------------------------
elips_uc <- function(g, d, S, r, n_izgara = 3600) {
  L <- t(chol(S))
  nokta <- function(phi) d + r * drop(L %*% c(cos(phi), sin(phi)))
  f <- function(phi) unname(g(nokta(phi)))[1]
  phis <- seq(0, 2 * pi, length.out = n_izgara + 1)[-1]
  deger <- vapply(phis, f, numeric(1))
  adim <- 2 * pi / n_izgara
  iyilestir <- function(i0, maks) {
    o <- stats::optimize(f, c(phis[i0] - adim, phis[i0] + adim), maximum = maks,
                         tol = 1e-12)
    if (maks) o$objective else o$objective
  }
  c(min = iyilestir(which.min(deger), FALSE), max = iyilestir(which.max(deger), TRUE))
}


# -----------------------------------------------------------------------------
# Referans lotlarından Sathe benzerlik bölgesi bileşenleri
#   lot_theta : her lot için ünite × parametre matrisleri listesi (en az 2)
# Döndürür:
#   SD_havuz_j = √[ lot içi varyansların ortalaması + lot ortalamalarının varyansı ]
#                [SATHE96 s.1800 "Pooled SD"]
#   Sigma1     = lot ortalamalarının kovaryansı (lotlar arası)      [SATHE96 Ek]
#   Sigma2     = birleştirilmiş lot içi kovaryans                     [SATHE96 Ek]
# -----------------------------------------------------------------------------
sathe_lot_bilesen <- function(lot_theta) {
  if (length(lot_theta) < 2) stop("Benzerlik bölgesi için en az 2 referans lotu gerekli [SATHE96].")
  n_lot <- sapply(lot_theta, nrow)
  ort   <- t(sapply(lot_theta, colMeans))                       # lot × parametre
  if (ncol(lot_theta[[1]]) == 1) ort <- t(ort)
  var_ic <- t(sapply(lot_theta, function(m) apply(m, 2, stats::var)))
  Sigma2 <- Reduce(`+`, lapply(lot_theta, function(m) (nrow(m) - 1) * stats::cov(m))) /
            (sum(n_lot) - length(n_lot))
  Sigma1 <- stats::cov(ort)
  list(n_lot = n_lot, lot_ort = ort,
       SD_havuz = sqrt(colMeans(var_ic) + apply(ort, 2, stats::var)),
       Sigma1 = Sigma1, Sigma2 = Sigma2)
}


# =============================================================================
# ANA FONKSİYON — parametre matrisleri üzerinden (uydurma sonrası)
# =============================================================================
# Argümanlar:
#   thetaT, thetaR : ünite × parametre matrisleri (TEST, REF)
#   param          : "lnTd_lnB" (varsayılan), "lnA_lnB" (SATHE96) veya "lnA_B"
#   region         : "B-L2a" Sathe kutusu, "B-L2b" Sathe eki elips, "B-L3" %10 yanıt
#   lot_theta      : B-L2a / B-L2b için referans lot parametre matrisleri listesi
#   k_sd           : B-L2a kutu genişliği (±k·SD_havuz), SATHE96: 1, 2 veya 3
#   sr_bolen       : B-L2b'de Σ2 böleni: "N" (varsayılan) veya "sqrtN" (SATHE96 literal)
#   sr_conf        : B-L2b güven düzeyi (SATHE96: 0.99)
#   times, Dg      : B-L3 için zaman noktaları ve yanıt sınırı (EMA10: 10)
#   conf           : güven bölgesi düzeyi (FDA97 V.C adım 5: 0.90)
# =============================================================================
calc_msd_params <- function(thetaT, thetaR,
                            param     = PARAMLAR,
                            region    = c("B-L2a", "B-L2b", "B-L3"),
                            lot_theta = NULL,
                            k_sd      = 3,
                            sr_bolen  = c("N", "sqrtN"),
                            sr_conf   = 0.99,
                            times     = NULL,
                            Dg        = 10,
                            conf      = 0.90) {
  param    <- match.arg(param)
  region   <- match.arg(region)
  sr_bolen <- match.arg(sr_bolen)
  thetaT <- as.matrix(thetaT); thetaR <- as.matrix(thetaR)
  if (ncol(thetaT) != ncol(thetaR)) stop("TEST ve REF parametre sayısı farklı.")
  if (ncol(thetaT) > 3) stop("FDA97 V.C: model en fazla 3 parametreli olmalı.")

  # --- Hotelling motoru [TSONG96; SATHE96 Tablo III] --------------------------
  m <- msd_engine(thetaT, thetaR, conf)
  P <- m$P
  sonuc <- list(motor = m, param = param, region = region)

  # --- Benzerlik bölgesi ------------------------------------------------------
  if (region %in% c("B-L2a", "B-L2b")) {
    if (is.null(lot_theta)) stop(region, " için lot_theta (referans lotları) gerekli.")
    lb <- sathe_lot_bilesen(lot_theta)
    sonuc$lot <- lb
  }

  if (region == "B-L2a") {
    # Sathe kutusu: izdüşüm aralıkları [d_j ± r√S_jj] ⊂ [-k·SD_j, +k·SD_j]
    # [SATHE96 s.1800-1801, Şekil 4]
    yari <- k_sd * lb$SD_havuz
    tab <- data.frame(parametre = colnames(thetaT), fark = m$d,
                      izd_alt = m$izd_alt, izd_ust = m$izd_ust,
                      kutu_alt = -yari, kutu_ust = yari,
                      icinde = m$izd_alt >= -yari & m$izd_ust <= yari, row.names = NULL)
    sonuc$bolge_tablo <- tab
    sonuc$benzer <- all(tab$icinde)
    sonuc$aciklama <- sprintf("B-L2a: Sathe kutusu ±%g·SD_havuz", k_sd)

  } else if (region == "B-L2b") {
    # Sathe eki: SR = {Δ : K'·Δ'(Σ1 + Σ2/c)⁻¹Δ ≤ F(P, 2N-P-1; sr_conf)}
    #   c = N (varsayılan) veya √N (SATHE96 literal; olası dizgi hatası)
    # Karar: güven elipsi ⊂ SR  ⇔  max_{y ∈ CR} K'·y'Q⁻¹y ≤ F_SR  [SATHE96 Şekil 5]
    if (P != 2) stop("B-L2b sınır araması şu an yalnızca P = 2 için uygulanmıştır.")
    N  <- stats::median(lb$n_lot)
    if (length(unique(lb$n_lot)) > 1)
      warning("Lotların ünite sayıları farklı; N olarak medyan kullanıldı.")
    cb <- if (sr_bolen == "N") N else sqrt(N)
    Q  <- lb$Sigma1 + lb$Sigma2 / cb
    Kp <- (N * N / (2 * N)) * (2 * N - P - 1) / ((2 * N - 2) * P)   # TSONG96 K (n1 = n2 = N)
    F_sr <- stats::qf(sr_conf, P, 2 * N - P - 1)
    Qinv <- solve(Q)
    g <- function(y) Kp * drop(crossprod(y, Qinv %*% y))
    uc <- elips_uc(g, m$d, m$S, m$r)
    sonuc$SR <- list(N = N, bolen = sr_bolen, Q = Q, Kp = Kp, F_sr = F_sr,
                     maks_nicelik = uc[["max"]], oran = uc[["max"]] / F_sr,
                     merkez_nicelik = g(m$d))
    sonuc$benzer <- uc[["max"]] <= F_sr
    sonuc$aciklama <- sprintf("B-L2b: Sathe eki elips, Σ2/%s, %%%g", 
                              if (sr_bolen == "N") "N" else "√N", 100 * sr_conf)

  } else {
    # B-L3: her t için max_{y ∈ CR} |F(t; θ̄R + y) − F(t; θ̄R)| ≤ Dg
    # F, z_t = ln α + β·ln t'nin artan fonksiyonu olduğundan z_t'nin elips
    # üzerindeki uç değerleri yeterlidir. z_t'nin gradyanı hiç sıfır olmadığı
    # için uç değerler elips sınırındadır. (FarmaStatR türetimi; EMA10; MUSELIK21)
    if (is.null(times)) stop("B-L3 için times (zaman noktaları) gerekli.")
    if (P != 2) stop("B-L3 şu an yalnızca 2 parametreli Weibull için uygulanmıştır.")
    tR <- m$ort_R
    tt <- sort(unique(times[times > 0]))
    z_of <- function(theta, t) z_weibull(theta, t, param)
    satir <- lapply(tt, function(t) {
      zR <- z_of(tR, t)
      uc <- elips_uc(function(y) z_of(tR + y, t), m$d, m$S, m$r)
      FR <- 100 * (1 - exp(-exp(zR)))
      Fa <- 100 * (1 - exp(-exp(uc[["min"]])))
      Fu <- 100 * (1 - exp(-exp(uc[["max"]])))
      FT <- 100 * (1 - exp(-exp(z_of(tR + m$d, t))))
      data.frame(zaman = t, F_ref = FR, F_test_nokta = FT,
                 F_alt = Fa, F_ust = Fu, maks_fark = max(abs(Fa - FR), abs(Fu - FR)),
                 row.names = NULL)
    })
    tab <- do.call(rbind, satir)
    sonuc$bolge_tablo <- tab
    sonuc$benzer <- all(tab$maks_fark <= Dg)
    sonuc$Dg <- Dg
    sonuc$aciklama <- sprintf("B-L3: yanıt uzayında ±%g (gözlenen zaman noktaları)", Dg)
  }

  sonuc$regulatif <- c(
    FDA = "FDA 1997 Bölüm V.C'ye uygun model bağımlı yaklaşım (Sathe ve ark. 1996).",
    EMA = paste0("EMA/TİTCK için \"destekleyici; öncelikli tercih edilen yöntem ",
                 "bootstrap f2'dir\" (EMA Q&A 3.9)."))
  class(sonuc) <- "farmastat_msd_weibull"
  sonuc
}


# =============================================================================
# ÜST FONKSİYON — ham dissolüsyon verisinden (uydurma + MSD)
#   ref_lots : B-L2a / B-L2b için referans lot ünite × zaman matrisleri listesi
# =============================================================================
calc_msd_weibull <- function(test, ref, times, ref_lots = NULL,
                             param = PARAMLAR, ...) {
  param <- match.arg(param)
  fT <- weibull_fit_units(test, times, param)
  fR <- weibull_fit_units(ref,  times, param)
  lot_theta <- if (!is.null(ref_lots))
    lapply(ref_lots, function(m) weibull_fit_units(m, times, param)$theta) else NULL
  s <- calc_msd_params(fT$theta, fR$theta, param = param, lot_theta = lot_theta,
                       times = times, ...)
  s$uydurma <- list(test = fT$tablo, ref = fR$tablo)
  s
}


# -----------------------------------------------------------------------------
# Yazdırma yöntemi
# -----------------------------------------------------------------------------
print.farmastat_msd_weibull <- function(x, digits = 4, ...) {
  f <- function(v) formatC(v, digits = digits, format = "f")
  m <- x$motor
  cat("\n== FarmaStatR · Weibull MSD (FDA 1997 V.C / Sathe 1996) ==\n")
  etiket <- c(lnTd_lnB = "(ln T_d, ln β) — Langenbucher + Sathe (FarmaStatR türetimi)",
              lnA_lnB = "(ln α, ln β) — Sathe 1996", lnA_B = "(ln α, β)")
  cat(sprintf("Parametrizasyon: %s   nT = %d, nR = %d\n", etiket[x$param], m$nT, m$nR))
  if (!is.null(x$uydurma)) {
    cat(sprintf("Uydurma R² (min): TEST %s · REF %s\n",
                f(min(x$uydurma$test$R2)), f(min(x$uydurma$ref$R2))))
  }
  cat(sprintf("Fark d = (%s)\n", paste(f(m$d), collapse = ", ")))
  cat(sprintf("D_M = %s   T² = %s   %%%d GA: [%s, %s]\n", f(m$DM), f(m$T2),
              round(100 * m$conf), f(m$DM_l), f(m$DM_u)))
  cat("Parametre izdüşüm aralıkları:\n")
  for (j in seq_along(m$d))
    cat(sprintf("  %-9s [%s, %s]\n", names(m$d)[j], f(m$izd_alt[j]), f(m$izd_ust[j])))
  cat(sprintf("\nBenzerlik bölgesi: %s\n", x$aciklama))
  if (x$region == "B-L2b")
    cat(sprintf("  max K'·y'Q⁻¹y = %s  vs  F = %s  (oran %s)\n",
                f(x$SR$maks_nicelik), f(x$SR$F_sr), f(x$SR$oran)))
  cat(sprintf("KARAR: %s\n", if (x$benzer) "BENZER" else "BENZER DEĞİL"))
  cat("\nRegülatif statü:\n  FDA :", x$regulatif["FDA"], "\n  EMA :", x$regulatif["EMA"], "\n")
  invisible(x)
}
