# =============================================================================
# FarmaStatR — Dissolüsyon Modülü, Bölüm 2
# f2 benzerlik faktörü, Expected f2 ve bootstrap %90 güven aralığı
#
# Dayanaklar:
#   [EMA10]  CPMP/EWP/QWP/1401/98 Rev.1/Corr** (2010), Appendix I, Bölüm 2 (s. 20-21)
#   [EMAQA]  EMA PKWP/BSWP Q&A 3.11 — bootstrap beklentileri; Denklem 1 (Expected f2)
#   [MA00]   Ma M-C, Wang BBC, Liu J-P, Tsong Y. J Biopharm Stat 2000;10:229-249
#            (E(f2) türetimi, Denklem 9; bootstrap algoritması, adım 1-4)
#   [HF96]   Hyndman RJ, Fan Y. Am Stat 1996;50:361-365 (kantil tanımları 1-9)
#   [NOCE20] Noce L ve ark. Eur J Pharm Sci 2020;146:105259 (bc-f2 Denk. 2; E(f2) Denk. 3)
#   [M9]     ICH M9 (2019) — CV koşulu: ≤ 10 dk için %20, diğer noktalar %10
#   [FDA97]  FDA Dissolution Testing of IR Solid Oral Dosage Forms (1997), Bölüm V.A
#   [GONG20] Gong X. FDA/OGD/ORS, SBIA 2020 çalıştayı sunumu (resmi FDA politikası değil):
#            bootstrap N ≈ 10 000, klasik f2, persentil %90 GA ("BCa uygulanabilir")
#   [MANDULA19] Mandula H. FDA/OPQ, M-CERSI 2019 sunumu (kişisel görüş): 10 000, BCa
#   [XU21]   Xu Z ve ark. Comput Methods Programs Biomed 2021;212:106449 — BCa Denk. 21-24,
#            jackknife yaklaşım 2; klasik f2 + BCa için tip I hata uyarısı
#
# Gösterim (EMAQA): P = zaman noktası sayısı, n = ürün başına ünite sayısı.
#   Not: EMA10 Appendix I'deki f2 formülünde n zaman noktası sayısıdır.
# Sürüm : 0.3.0 — FDA perspektifi (klasik f2, FDA kesmesi, FDA97 CV), BCa aralığı, bootstrap ortalaması
# =============================================================================


# NULL birleştirme operatörü (R < 4.4 uyumluluğu)
if (!exists("%||%", envir = baseenv())) `%||%` <- function(a, b) if (is.null(a)) b else a


# -----------------------------------------------------------------------------
# f2 tahmincileri
#   D = Σ (X̄_T - X̄_R)²
#   V = Σ (S²_T / n_T + S²_R / n_R)     [n_T = n_R = n iken EMAQA: (1/n) Σ (S²_T + S²_R)]
#   f2    = 100 - 25·log10(1 + D/P)              [EMA10 App. I]
#   E(f2) = 100 - 25·log10(1 + (D + V)/P)        [EMAQA Denk. 1; MA00 Denk. 9]
#   bc-f2 = 100 - 25·log10(1 + (D - V)/P)        [NOCE20 Denk. 2; D ≤ V ise tanımsız]
#   n_T ≠ n_R genellemesi FarmaStatR türetimidir.
# -----------------------------------------------------------------------------
f2_estimators <- function(XT, XR) {
  XT <- as.matrix(XT); XR <- as.matrix(XR)
  P  <- ncol(XT)
  D  <- sum((colMeans(XT) - colMeans(XR))^2)
  V  <- sum(apply(XT, 2, stats::var) / nrow(XT) + apply(XR, 2, stats::var) / nrow(XR))
  f  <- function(x) 100 - 25 * log10(1 + x / P)
  c(f2 = f(D), Ef2 = f(D + V), bcf2 = if (D > V) f(D - V) else NA_real_, D = D, V = V, P = P)
}


# -----------------------------------------------------------------------------
# Hyndman & Fan kantili — BAĞIMSIZ uygulama (stats::quantile ile karşılaştırılır)
#   Tip 1-3: süreksiz; tip 4-9: p_k = (k - α)/(n - α - β + 1) arasında doğrusal enterpolasyon
# -----------------------------------------------------------------------------
hf_quantile <- function(x, p, type = 7) {
  # Sayısal kural: n·p + m tam sayıya kayan nokta hatası kadar yakınsa tam sayı sayılır
  # (fuzz = 4·eps; R'ın stats::quantile uygulamasıyla aynı kural — ör. 0.05·5000 = 250).
  fuzz <- 4 * .Machine$double.eps
  x <- sort(x); n <- length(x)
  sapply(p, function(pp) {
    m <- if (type <= 3) c(0, 0, -0.5)[type] else {
      ab <- switch(as.character(type),
                   "4" = c(0, 1), "5" = c(0.5, 0.5), "6" = c(0, 0), "7" = c(1, 1),
                   "8" = c(1/3, 1/3), "9" = c(3/8, 3/8))
      ab[1] + pp * (1 - ab[1] - ab[2])
    }
    j <- floor(pp * n + m + fuzz)
    g <- pp * n + m - j
    if (abs(g) < fuzz) g <- 0
    gam <- switch(as.character(type),
                  "1" = as.numeric(g > 0),
                  "2" = if (g > 0) 1 else 0.5,
                  "3" = if (g == 0 && j %% 2 == 0) 0 else 1,
                  g)
    xj  <- x[min(max(j, 1), n)]
    xj1 <- x[min(max(j + 1, 1), n)]
    (1 - gam) * xj + gam * xj1
  })
}


# -----------------------------------------------------------------------------
# %85 kesme kuralı — ORTALAMALAR üzerinden; kesmenin tetiklendiği nokta dahil
#   "EMA" : ürünlerden HERHANGİ BİRİ > %85 [EMA10 App. I madde 4; EMAQA 3.11]
#   "FDA" : ürünlerin İKİSİ DE > %85      [FDA 1997 Bölüm V.A]
#   "none": kesme yok
# Döndürür: seçilen sütun indeksleri (pozitif zaman noktaları içinde)
# -----------------------------------------------------------------------------
f2_truncate <- function(mT, mR, rule, cutoff = 85) {
  # Sayısal kural: ortalamalar 10 ondalığa yuvarlanarak karşılaştırılır. Veri 1-2 ondalıklı
  # olduğundan ortalama tam 85.0 olabilir (ör. 12 değerin toplamı 1020.0); kayan nokta
  # toplama sırası farkı "> 85" kararını platforma göre değiştirmesin (R / Python / SAS).
  mT <- round(mT, 10); mR <- round(mR, 10)
  P <- length(mT)
  if (rule == "none") return(seq_len(P))
  asim <- if (rule == "EMA") which(mT > cutoff | mR > cutoff) else which(mT > cutoff & mR > cutoff)
  if (length(asim)) seq_len(min(asim)) else seq_len(P)
}


# -----------------------------------------------------------------------------
# EMA kontrol sırası (adım 0-7) — zaman noktası seçimi ve uygulanabilirlik
#   test, ref : ünite × zaman matrisleri (NA olabilir; bkz. adım 5)
#   times     : zaman noktaları (DAKİKA — CV ve 15 dk kuralları dakika varsayar)
#   truncation: "EMA" (biri >85%), "FDA" (ikisi de >85%), "none"
#   cv_rule   : "M9" (≤10 dk %20 / sonrası %10; EMAQA 3.11'in işaret ettiği güncel kural)
#               "AppI" (ilk nokta < %20, sonrakiler < %10; EMA10 App. I)
# -----------------------------------------------------------------------------
f2_checks <- function(test, ref, times,
                      truncation = c("EMA", "FDA", "none"),
                      cv_rule    = c("M9", "AppI", "FDA97"),
                      cutoff = 85) {
  truncation <- match.arg(truncation); cv_rule <- match.arg(cv_rule)
  test <- as.matrix(test); ref <- as.matrix(ref); times <- as.numeric(times)
  notlar <- character(0); dur <- NULL

  # Adım 2: aynı zaman noktaları [EMA10 App. I, madde 2]
  if (ncol(test) != ncol(ref) || length(times) != ncol(test))
    stop("TEST, REF ve times aynı zaman noktalarını içermeli [EMA10 App. I, madde 2].")

  # Adım 1: t = 0 çıkarılır [madde 1: 'zero excluded']
  pozitif <- which(times > 0)
  if (length(pozitif) < length(times)) notlar <- c(notlar, "t = 0 noktası çıkarıldı.")

  mT <- colMeans(test, na.rm = TRUE); mR <- colMeans(ref, na.rm = TRUE)

  # Adım 0: 15 dakikada > %85 → matematiksel değerlendirme gerekmez [EMA10 App. I]
  t15 <- which(times > 0 & times <= 15)
  hizli <- length(t15) > 0 && mT[max(t15)] > cutoff && mR[max(t15)] > cutoff &&
           times[max(t15)] <= 15
  if (hizli) notlar <- c(notlar, sprintf(
    "Her iki ürün de %g dk'da > %%%g: EMA10 App. I uyarınca profiller matematiksel değerlendirme olmadan benzer kabul edilebilir.",
    times[max(t15)], cutoff))

  # Adım 3: %85 kesmesi — ORTALAMALAR üzerinden, ORİJİNAL veride bir kez [EMA10 madde 4; EMAQA]
  sec <- pozitif[f2_truncate(mT[pozitif], mR[pozitif], truncation, cutoff)]
  dislanan_t <- setdiff(pozitif, sec)
  if (length(dislanan_t)) notlar <- c(notlar, sprintf(
    "%%85 kesmesi (%s): %s dk noktaları çıkarıldı.", truncation,
    paste(times[dislanan_t], collapse = ", ")))

  # Adım 4: en az 3 zaman noktası [madde 1]
  P <- length(sec)
  if (P < 3) dur <- sprintf("Kesme sonrası %d zaman noktası kaldı; en az 3 gerekli [EMA10 App. I, madde 1].", P)

  # Adım 5: geçerli ünite — seçili noktalarda eksiksiz profil (bootstrap tüm profili çeker)
  tam_T <- stats::complete.cases(test[, sec, drop = FALSE])
  tam_R <- stats::complete.cases(ref[,  sec, drop = FALSE])
  kurtarilan <- c(T = sum(tam_T & !stats::complete.cases(test)),
                  R = sum(tam_R & !stats::complete.cases(ref)))
  if (any(kurtarilan > 0)) notlar <- c(notlar, sprintf(
    "Eksik değeri yalnızca kesilen noktalarda olan ünite(ler) analizde tutuldu: TEST %d, REF %d.",
    kurtarilan["T"], kurtarilan["R"]))
  if (any(!tam_T) || any(!tam_R)) notlar <- c(notlar, sprintf(
    "Seçili noktalarda eksik değeri olan ünite(ler) çıkarıldı: TEST %d, REF %d.",
    sum(!tam_T), sum(!tam_R)))
  XT <- test[tam_T, sec, drop = FALSE]; XR <- ref[tam_R, sec, drop = FALSE]
  n <- c(T = nrow(XT), R = nrow(XR))
  if (any(n < 12)) notlar <- c(notlar, sprintf(
    "Ünite sayısı 12'nin altında (TEST %d, REF %d) [EMA10 App. I, madde 3].", n["T"], n["R"]))
  if (any(n > 12)) notlar <- c(notlar,
    "Ünite sayısı 12'den fazla: EMA10 App. I 'twelve' der; EMAQA 3.11 'at least twelve' olarak yorumlar.")
  if (n["T"] != n["R"]) notlar <- c(notlar,
    "n_T ≠ n_R: V = Σ(S²_T/n_T + S²_R/n_R) genellemesi kullanıldı (FarmaStatR türetimi).")

  # Adım 6: CV kontrolü, seçili noktalarda [madde 5; M9]
  cv <- function(M) 100 * apply(M, 2, stats::sd) / colMeans(M)
  cvT <- cv(XT); cvR <- cv(XR); ts <- times[sec]
  # M9    : ≤ 10 dk %20, sonrası %10; "not more than" → ihlal: CV > sınır
  # AppI  : ilk nokta %20, sonrakiler %10; "less than" → ihlal: CV ≥ sınır
  # FDA97 : "earlier time points (e.g., 15 minutes)" %20, diğerleri %10; "not more than"
  #         "erken nokta = t ≤ 15 dk" yorumu FarmaStatR yorumudur
  sinir <- switch(cv_rule,
                  M9    = ifelse(ts <= 10, 20, 10),
                  AppI  = c(20, rep(10, P - 1))[seq_len(P)],
                  FDA97 = ifelse(ts <= 15, 20, 10))
  ihlal <- if (cv_rule == "AppI") (cvT >= sinir | cvR >= sinir) else (cvT > sinir | cvR > sinir)
  cv_tablo <- data.frame(zaman = ts, CV_T = cvT, CV_R = cvR, sinir = sinir, ihlal = ihlal,
                         row.names = NULL)

  # Adım 7: yöntem önerisi [EMAQA 3.11]
  oneri <- if (!is.null(dur)) "UYGULANAMAZ" else if (any(ihlal))
    "Bootstrap %90 GA (CV koşulu sağlanmıyor) [EMAQA 3.11; FDA/OGD: GONG20]" else
    "Klasik f2 (CV koşulu sağlanıyor) [EMA10 App. I]"

  tamT_all <- stats::complete.cases(test[, pozitif, drop = FALSE])
  tamR_all <- stats::complete.cases(ref[,  pozitif, drop = FALSE])
  list(secili = sec, zamanlar = ts, P = P, n = n, XT = XT, XR = XR, hizli = hizli,
       pozitif = pozitif, zaman_tum = times[pozitif],
       XT_tum = test[tamT_all, pozitif, drop = FALSE], XR_tum = ref[tamR_all, pozitif, drop = FALSE],
       cv = cv_tablo, cv_rule = cv_rule, truncation = truncation,
       oneri = oneri, dur = dur, notlar = notlar)
}


# -----------------------------------------------------------------------------
# Bootstrap indeksleri — tüm profil (ünite) bazında, iadeli, ürünlerde bağımsız [MA00 adım 1]
#   Rastgele sayı üreteci açıkça ayarlanır ve raporlanır (yeniden üretilebilirlik).
# -----------------------------------------------------------------------------
f2_boot_indices <- function(nT, nR, B, seed) {
  eski <- RNGkind()
  on.exit(do.call(RNGkind, as.list(eski)), add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(seed)
  iT <- matrix(sample.int(nT, B * nT, replace = TRUE), nrow = B, byrow = TRUE)
  iR <- matrix(sample.int(nR, B * nR, replace = TRUE), nrow = B, byrow = TRUE)
  list(T = iT, R = iR, seed = seed, B = B,
       rng = "Mersenne-Twister / Inversion / Rejection (R ≥ 3.6)")
}

# Verilen indekslerle her replikada tahmincileri hesaplar (deterministik)
#   mod = "replika": %85 kuralı HER replikada, o replikanın ortalamalarına yeniden
#                    uygulanır (VARSAYILAN; bootstrap ilkesi: veriye dayalı tüm adımlar
#                    yeniden üretilir; NOCE20 DDSolver eleştirisi; Bootf2bca ile uyum)
#   mod = "sabit"  : orijinal veride belirlenen noktalar tüm replikalarda kullanılır
#   Replika içi kesme sonrası P < 3 kalırsa replika geçersiz (NA) sayılır.
f2_boot_replicates <- function(XT, XR, idx, rule = "EMA", mod = c("replika", "sabit"),
                               sec_sabit = seq_len(ncol(XT)), cutoff = 85) {
  mod <- match.arg(mod)
  B <- nrow(idx$T)
  out <- matrix(NA_real_, B, 4, dimnames = list(NULL, c("f2", "Ef2", "bcf2", "P")))
  for (b in seq_len(B)) {
    xt <- XT[idx$T[b, ], , drop = FALSE]; xr <- XR[idx$R[b, ], , drop = FALSE]
    sec <- if (mod == "sabit") sec_sabit else f2_truncate(colMeans(xt), colMeans(xr), rule, cutoff)
    if (length(sec) < 3) { out[b, "P"] <- length(sec); next }
    e <- f2_estimators(xt[, sec, drop = FALSE], xr[, sec, drop = FALSE])
    out[b, ] <- c(e[c("f2", "Ef2", "bcf2")], length(sec))
  }
  out
}

# -----------------------------------------------------------------------------
# Jackknife değerleri — yaklaşım 2 [XU21 Bölüm 2.3.4]: önce her TEST ünitesi,
# sonra her REF ünitesi tek tek çıkarılır (n_T + n_R istatistik). Kesme kuralı,
# bootstrap ile tutarlı olarak aynı modda uygulanır.
# -----------------------------------------------------------------------------
f2_jackknife <- function(XT, XR, tahminci, rule, mod, sec_sabit) {
  hesap <- function(xt, xr) {
    sec <- if (mod == "sabit") sec_sabit else f2_truncate(colMeans(xt), colMeans(xr), rule)
    if (length(sec) < 3) return(NA_real_)
    unname(f2_estimators(xt[, sec, drop = FALSE], xr[, sec, drop = FALSE])[tahminci])
  }
  c(vapply(seq_len(nrow(XT)), function(i) hesap(XT[-i, , drop = FALSE], XR), numeric(1)),
    vapply(seq_len(nrow(XR)), function(j) hesap(XT, XR[-j, , drop = FALSE]), numeric(1)))
}

# BCa olasılık seviyeleri [XU21 Denk. 21-24; Efron & Tibshirani]
#   z0 = Φ⁻¹( #{θ*_b < θ̂} / B )
#   a  = Σ(θ̄_J − θ_(i))³ / { 6 [Σ(θ̄_J − θ_(i))²]^(3/2) }
#   α1 = Φ( z0 + (z0 + z_α)   / (1 − a(z0 + z_α)) )
#   α2 = Φ( z0 + (z0 + z_1−α) / (1 − a(z0 + z_1−α)) )
bca_alpha <- function(z0, a, alpha = 0.05) {
  za <- stats::qnorm(c(alpha, 1 - alpha))
  stats::pnorm(z0 + (z0 + za) / (1 - a * (z0 + za)))
}
bca_bilesenler <- function(boot, theta_hat, jack, alpha = 0.05) {
  boot <- boot[is.finite(boot)]; jack <- jack[is.finite(jack)]
  oran <- sum(boot < theta_hat) / length(boot)
  z0 <- stats::qnorm(oran)
  d  <- mean(jack) - jack
  a  <- sum(d^3) / (6 * sum(d^2)^1.5)
  list(oran = oran, z0 = z0, a = a, alpha12 = if (is.finite(z0)) bca_alpha(z0, a, alpha) else c(NA, NA))
}


# Karar kuralı (kullanıcı kararı, FarmaStatR) — 4 ondalık, yuvarlama yok
f2_karar <- function(alt, MCSE) {
  karar <- if (alt >= 50) "BENZER" else if (alt >= 49.5)
    "SINIR VAKA — değerlendirici yorumu gerekli" else "BENZER DEĞİL"
  list(karar = karar, seed_duyarli = unname(abs(alt - 50) < 2 * MCSE))
}


# -----------------------------------------------------------------------------
# Kantilin Monte Carlo belirsizliği — sıra istatistiği (binom) yöntemi
#   B bootstrap değerinin p-kantili için, sıra indeksleri B·p ± z·√(B·p(1-p))
#   arasındaki aralık Monte Carlo belirsizliğini verir; MCSE ≈ aralık / (2z).
# -----------------------------------------------------------------------------
mc_quantile_se <- function(x, p, conf = 0.95) {
  x <- sort(x); B <- length(x); z <- stats::qnorm(1 - (1 - conf) / 2)
  lo <- max(1, floor(B * p - z * sqrt(B * p * (1 - p))))
  hi <- min(B, ceiling(B * p + z * sqrt(B * p * (1 - p))))
  c(mc_alt = x[lo], mc_ust = x[hi], MCSE = (x[hi] - x[lo]) / (2 * z))
}


# =============================================================================
# ANA FONKSİYON
# =============================================================================
# Argümanlar:
#   test, ref, times, truncation, cv_rule : bkz. f2_checks
#   B          : bootstrap örnek sayısı (EMAQA: ≥ 5000)
#   seed       : rastgele sayı tohumu (raporlanır)
#   q_type     : Hyndman & Fan kantil tipi 1-9 (EMAQA: herhangi biri; varsayılan 7)
#   conf       : iki taraflı güven düzeyi (EMAQA: 0.90)
#   idx        : (isteğe bağlı) dışarıdan verilen indeksler — SAS/Python çapraz doğrulama için
# Karar kuralı (kullanıcı kararı, FarmaStatR):
#   Alt sınır 4 ondalıkla, yuvarlanmadan raporlanır.
#   ≥ 50 → BENZER; 49.5 ≤ … < 50 → SINIR VAKA (yorum gerekli); < 49.5 → BENZER DEĞİL.
#   |alt sınır − 50| < 2·MCSE ise ayrıca "seed'e duyarlı" uyarısı.
# =============================================================================
# Perspektif ön ayarları (açıkça verilen argümanlar ön ayarı geçersiz kılar):
#   EMA : E(f2), EMA kesmesi, M9 CV kuralı, B = 5000, persentil        [EMAQA 3.11]
#   FDA : klasik f2, FDA kesmesi, FDA97 CV kuralı, B = 10000, persentil [FDA97; GONG20]
#         (resmi FDA politikası değildir; BCa seçenek: ga_tipi = "BCa")
calc_f2_boot <- function(test, ref, times,
                         perspektif = c("EMA", "FDA"),
                         tahminci = NULL, truncation = NULL, cv_rule = NULL, B = NULL,
                         ga_tipi = c("persentil", "BCa"),
                         kesme_modu = c("replika", "sabit"),
                         seed = 20260927, q_type = 7, conf = 0.90,
                         idx = NULL) {
  perspektif <- match.arg(perspektif); ga_tipi <- match.arg(ga_tipi)
  kesme_modu <- match.arg(kesme_modu)
  on <- if (perspektif == "EMA") list(tahminci = "Ef2", truncation = "EMA", cv_rule = "M9", B = 5000)
        else                     list(tahminci = "f2",  truncation = "FDA", cv_rule = "FDA97", B = 10000)
  tahminci   <- match.arg(tahminci %||% on$tahminci, c("Ef2", "f2", "bcf2"))
  truncation <- match.arg(truncation %||% on$truncation, c("EMA", "FDA", "none"))
  cv_rule    <- match.arg(cv_rule %||% on$cv_rule, c("M9", "AppI", "FDA97"))
  B          <- B %||% on$B
  if (!q_type %in% 1:9) stop("q_type 1-9 arasında olmalı [HF96].")
  k <- f2_checks(test, ref, times, truncation, cv_rule)
  if (!is.null(k$dur)) stop(k$dur, call. = FALSE)
  uyarilar <- character(0)
  if (B < 5000 && is.null(idx)) uyarilar <- c(uyarilar, "B < 5000 [EMAQA 3.11].")
  if (tahminci != "Ef2") uyarilar <- c(uyarilar, sprintf(
    "Tahminci %s: EMAQA 3.11 E(f2) ister; XU21 simülasyonlarında klasik f2 ve bc-f2 tip I hatayı %%5'in üzerine çıkarabilmektedir.",
    tahminci))
  if (ga_tipi == "BCa") uyarilar <- c(uyarilar,
    "BCa aralığı: EMAQA persentil yöntemi ister; XU21'e göre klasik f2 + BCa tip I hatayı artırır. Bootf2BCA'nın 'boot' regresyon BCa'sı jackknife BCa'dan biraz farklıdır.")

  nokta <- f2_estimators(k$XT, k$XR)
  # Replika modunda tüm pozitif noktalarda eksiksiz üniteler kullanılır
  if (kesme_modu == "replika") {
    XT <- k$XT_tum; XR <- k$XR_tum; sec_sabit <- seq_len(ncol(XT))
    if (nrow(XT) != k$n["T"] || nrow(XR) != k$n["R"]) uyarilar <- c(uyarilar,
      "Replika içi kesme: kesilen noktalarda eksik değeri olan üniteler bootstrap'tan çıkarıldı.")
  } else {
    XT <- k$XT; XR <- k$XR; sec_sabit <- seq_len(k$P)
  }
  if (is.null(idx)) idx <- f2_boot_indices(nrow(XT), nrow(XR), B, seed)
  rep <- f2_boot_replicates(XT, XR, idx, truncation, kesme_modu, sec_sabit)
  gecersiz <- sum(is.na(rep[, "Ef2"]))
  if (gecersiz > 0) uyarilar <- c(uyarilar, sprintf(
    "%d replikada kesme sonrası P < 3 kaldı; bu replikalar geçersiz sayıldı.", gecersiz))
  a <- (1 - conf) / 2

  ga <- function(v) { v <- v[is.finite(v)]
    c(alt = unname(stats::quantile(v, a, type = q_type)),
      ust = unname(stats::quantile(v, 1 - a, type = q_type)), B_gecerli = length(v),
      ortalama = mean(v)) }
  GA <- rbind(Ef2 = ga(rep[, "Ef2"]), f2 = ga(rep[, "f2"]), bcf2 = ga(rep[, "bcf2"]))
  vsec <- rep[is.finite(rep[, tahminci]), tahminci]
  mc <- mc_quantile_se(vsec, a)

  # Karar aralığı: seçilen tahminci ve GA tipi
  bca <- NULL
  if (ga_tipi == "BCa") {
    jack <- f2_jackknife(XT, XR, tahminci, truncation, kesme_modu, sec_sabit)
    bca  <- bca_bilesenler(vsec, unname(nokta[tahminci]), jack, a)
    bca$jackknife <- jack
    if (anyNA(bca$alpha12)) stop("BCa tanımsız: tüm bootstrap değerleri nokta tahmininin bir yanında.")
    karar_ga <- c(alt = unname(stats::quantile(vsec, bca$alpha12[1], type = q_type)),
                  ust = unname(stats::quantile(vsec, bca$alpha12[2], type = q_type)))
  } else karar_ga <- GA[tahminci, c("alt", "ust")]

  alt <- unname(karar_ga["alt"])
  kr <- f2_karar(alt, mc["MCSE"])
  if (sum(is.na(rep[, "bcf2"])) > 0) uyarilar <- c(uyarilar, sprintf(
    "bc-f2 %d replikada tanımsız (D ≤ V); bc-f2 GA yalnızca bilgi amaçlıdır.", sum(is.na(rep[, "bcf2"]))))

  s <- list(kontrol = k, nokta = nokta, replikalar = rep, GA = GA, mc = mc,
            B = nrow(idx$T), seed = idx$seed, rng = idx$rng, q_type = q_type, conf = conf,
            kesme_modu = kesme_modu, P_dagilim = table(rep[, "P"]),
            perspektif = perspektif, tahminci = tahminci, ga_tipi = ga_tipi,
            karar_ga = karar_ga, bca = bca, boot_ortalama = mean(vsec),
            karar = kr$karar, seed_duyarli = kr$seed_duyarli,
            ema_tamsayi = round(alt), uyarilar = uyarilar, idx = idx,
            regulatif = c(
              EMA = "EMA Q&A 3.11: yüksek değişkenlikte öncelikli tercih edilen yöntem (Expected f2, bootstrap %90 GA, persentil).",
              FDA = paste0("FDA kılavuzları (FDA 1997 V.A; FDA 2022 taslak III.A.2) klasik f2 nokta tahminini tanımlar. ",
                           "FDA perspektifi ön ayarı FDA/OGD bilimsel sunumlarına dayanır (Gong 2020; Mandula 2019); ",
                           "resmi FDA politikası değildir.")))
  class(s) <- "farmastat_f2boot"
  s
}

# Bootstrap indekslerini uzun formatta CSV'ye yazar (SAS/Python çapraz doğrulama)
f2_export_indices <- function(s, dosya) {
  iT <- s$idx$T; iR <- s$idx$R
  df <- rbind(
    data.frame(rep = rep(seq_len(nrow(iT)), each = ncol(iT)), urun = "T",
               sira = rep(seq_len(ncol(iT)), nrow(iT)), unite = as.vector(t(iT))),
    data.frame(rep = rep(seq_len(nrow(iR)), each = ncol(iR)), urun = "R",
               sira = rep(seq_len(ncol(iR)), nrow(iR)), unite = as.vector(t(iR))))
  utils::write.csv(df, dosya, row.names = FALSE)
  invisible(dosya)
}


# -----------------------------------------------------------------------------
# Yazdırma yöntemi — 4 ondalık, yuvarlama yok
# -----------------------------------------------------------------------------
print.farmastat_f2boot <- function(x, ...) {
  f <- function(v) formatC(v, digits = 4, format = "f")
  k <- x$kontrol
  cat(sprintf("\n== FarmaStatR · Bootstrap f2 — %s perspektifi ==\n", x$perspektif))
  cat(sprintf("Zaman noktaları (P = %d): %s dk   |   n_T = %d, n_R = %d\n",
              k$P, paste(k$zamanlar, collapse = ", "), k$n["T"], k$n["R"]))
  cat(sprintf("Kesme: %s kuralı, %s   CV kuralı: %s\nÖneri: %s\n", k$truncation,
              if (x$kesme_modu == "replika") "her replikada yeniden" else "orijinal veride bir kez (sabit)",
              k$cv_rule, k$oneri))
  cat(sprintf("\nNokta tahminleri:  f2 = %s   E(f2) = %s   bc-f2 = %s\n",
              f(x$nokta["f2"]), f(x$nokta["Ef2"]), f(x$nokta["bcf2"])))
  cat(sprintf("Bootstrap: B = %d, seed = %s, RNG = %s, kantil tipi = %d (Hyndman & Fan)\n",
              x$B, x$seed, x$rng, x$q_type))
  if (x$kesme_modu == "replika")
    cat("Replikalarda P dağılımı:", paste(sprintf("P=%s: %d", names(x$P_dagilim), x$P_dagilim), collapse = ", "), "\n")
  etk <- c(Ef2 = "E(f2)", f2 = "f2", bcf2 = "bc-f2")[x$tahminci]
  cat(sprintf("KARAR ARALIĞI — %s, %s: %%%d GA [%s, %s]   (alt sınır MCSE = %s; bootstrap ortalaması = %s)\n",
              etk, x$ga_tipi, round(100 * x$conf), f(x$karar_ga["alt"]), f(x$karar_ga["ust"]),
              f(x$mc["MCSE"]), f(x$boot_ortalama)))
  if (!is.null(x$bca)) cat(sprintf("  BCa: z0 = %s, a = %s, α1 = %s, α2 = %s\n",
              formatC(x$bca$z0, digits = 6, format = "f"), formatC(x$bca$a, digits = 6, format = "f"),
              formatC(x$bca$alpha12[1], digits = 6, format = "f"), formatC(x$bca$alpha12[2], digits = 6, format = "f")))
  cat(sprintf("Bilgi (persentil): E(f2) [%s, %s]\n", f(x$GA["Ef2", "alt"]), f(x$GA["Ef2", "ust"])))
  cat(sprintf("        f2: [%s, %s]   bc-f2 (bilgi): [%s, %s]\n",
              f(x$GA["f2", "alt"]), f(x$GA["f2", "ust"]), f(x$GA["bcf2", "alt"]), f(x$GA["bcf2", "ust"])))
  cat(sprintf("\nKARAR: %s\n", x$karar))
  if (x$seed_duyarli) cat("  ! Alt sınır 50'ye Monte Carlo belirsizliğinden (2·MCSE) daha yakın: sonuç seed'e duyarlı.\n")
  cat(sprintf("Tam sayı biçimi (EMAQA raporlama biçimi, bilgi amaçlı): alt sınır = %d\n", x$ema_tamsayi))
  if (length(k$notlar)) { cat("\nKontrol notları:\n"); cat(paste0("  - ", k$notlar, "\n"), sep = "") }
  if (length(x$uyarilar)) { cat("Uyarılar:\n"); cat(paste0("  - ", x$uyarilar, "\n"), sep = "") }
  cat("\nRegülatif statü:\n  EMA :", x$regulatif["EMA"], "\n  FDA :", x$regulatif["FDA"], "\n")
  invisible(x)
}
