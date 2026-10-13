# =============================================================================
# FarmaStatR — Dissolüsyon Modülü, Bölüm 1A
# Model bağımsız çok değişkenli istatistiksel uzaklık (MSD / Mahalanobis)
# ve Hotelling T² tabanlı %90 güven bölgesi
#
# Dayanaklar:
#   [FDA97]   FDA Guidance for Industry: Dissolution Testing of Immediate
#             Release Solid Oral Dosage Forms (Ağustos 1997), Bölüm V.B
#   [TSONG96] Tsong Y, Hammerstrom T, Sathe P, Shah VP. Statistical
#             assessment of mean differences between two dissolution data
#             sets. Drug Inf J 1996;30:1105-1112, Denklem (2)-(3)
#   [EMA10]   CPMP/EWP/QWP/1401/98 Rev.1/Corr** (2010), Appendix I, Bölüm 2
#   [EMAQA]   EMA PKWP/BSWP Q&A 3.9 (Mahalanobis uzaklığı) ve 3.11 (bootstrap f2)
#
# Sürüm : 0.2.0 — ortak msd_engine() eklendi (1B ile paylaşılır)
# Durum : Validasyon öncesi — TC-1/TC-2 ile analitik doğrulama yapıldı
# =============================================================================


# -----------------------------------------------------------------------------
# Yardımcı: uzun formattaki veriyi ünite × zaman matrisine çevirir
# Shiny arayüzünde CSV girişi bu fonksiyondan geçecek
# -----------------------------------------------------------------------------
msd_prepare <- function(df,
                        product_col = "Product",
                        unit_col    = "Unit",
                        time_col    = "Time",
                        value_col   = "Diss",
                        lot_col     = NULL,
                        test_label  = "TEST",
                        ref_label   = "REF") {

  gerekli <- c(product_col, unit_col, time_col, value_col, lot_col)
  eksik <- setdiff(gerekli, names(df))
  if (length(eksik) > 0)
    stop("Eksik sütun(lar): ", paste(eksik, collapse = ", "))

  # Tek bir ürün/lot alt kümesini ünite × zaman matrisine döndürür
  genis <- function(alt) {
    zamanlar <- sort(unique(as.numeric(alt[[time_col]])))
    uniteler <- unique(as.character(alt[[unit_col]]))
    m <- matrix(NA_real_, length(uniteler), length(zamanlar),
                dimnames = list(uniteler, zamanlar))
    for (i in seq_len(nrow(alt))) {
      m[as.character(alt[[unit_col]][i]),
        as.character(as.numeric(alt[[time_col]][i]))] <- as.numeric(alt[[value_col]][i])
    }
    if (anyNA(m)) stop("Eksik (NA) hücre var: her ünite her zaman noktasında ölçülmüş olmalı.")
    m
  }

  urun <- as.character(df[[product_col]])
  test <- genis(df[urun == test_label, , drop = FALSE])
  ref  <- genis(df[urun == ref_label,  , drop = FALSE])

  # İsteğe bağlı: referans lotları (L2a/L2b sınırları için)
  ref_lots <- NULL
  if (!is.null(lot_col)) {
    alt_ref <- df[urun == ref_label, , drop = FALSE]
    lotlar  <- unique(as.character(alt_ref[[lot_col]]))
    ref_lots <- lapply(lotlar, function(l)
      genis(alt_ref[as.character(alt_ref[[lot_col]]) == l, , drop = FALSE]))
    names(ref_lots) <- lotlar
  }

  list(test = test, ref = ref, ref_lots = ref_lots)
}


# -----------------------------------------------------------------------------
# Yardımcı: %85 kesme kuralı — hangi zaman noktalarının analize gireceği
#   "none" : tüm noktalar (Tsong 1996 örnekleri bu şekilde hesaplanmıştır)
#   "FDA"  : her iki ürün %85'i geçtikten sonra yalnızca bir ölçüm
#            [FDA97 V.A, 2. madde işareti]
#   "EMA"  : ürünlerden herhangi biri %85'i geçtiği noktaya kadar (dahil)
#            [EMA10 App. I, 4. koşul; EMAQA 3.11]
# NOT: Kılavuzlar bu kuralları f2 için tanımlar. MSD'ye uygulanması
#      FarmaStatR tasarım kararıdır ve raporda böyle etiketlenir.
# -----------------------------------------------------------------------------
msd_truncate <- function(mT, mR, rule = c("none", "FDA", "EMA"), cutoff = 85) {
  rule <- match.arg(rule)
  P <- length(mT)
  if (rule == "none") return(seq_len(P))

  asim <- if (rule == "FDA") which(mT > cutoff & mR > cutoff)
          else               which(mT > cutoff | mR > cutoff)
  if (length(asim) == 0) return(seq_len(P))   # hiç aşım yoksa hepsi girer
  seq_len(min(asim))                           # ilk aşım noktası dahil
}


# -----------------------------------------------------------------------------
# Yardımcı: iki ünite matrisi için birleştirilmiş kovaryans matrisi
#   S = [(nT-1)·S_T + (nR-1)·S_R] / (nT + nR - 2)
#   Eşit n'de Tsong'un (S1+S2)/2 formülüne indirgenir [TSONG96 Denk. 2]
# -----------------------------------------------------------------------------
msd_pooled_cov <- function(A, B) {
  nA <- nrow(A); nB <- nrow(B)
  ((nA - 1) * stats::cov(A) + (nB - 1) * stats::cov(B)) / (nA + nB - 2)
}


# -----------------------------------------------------------------------------
# Yardımcı: iki grup arasındaki Mahalanobis uzaklığı (nokta tahmini)
# -----------------------------------------------------------------------------
msd_distance <- function(A, B) {
  S <- msd_pooled_cov(A, B)
  d <- colMeans(A) - colMeans(B)
  sqrt(drop(crossprod(d, solve(S, d))))
}


# =============================================================================
# ORTAK MOTOR (v0.2.0) — 1A (zaman noktaları) ve 1B (model parametreleri)
# aynı Hotelling T² hesabını kullanır.
#   A, B : ünite × değişken matrisleri (A = TEST, B = REF)
# Döndürür: d, S, D_M, T², K, F, df, r, güven aralığı, sınır noktaları ve
#           değişken bazında eşzamanlı izdüşüm aralıkları (d_j ± r·√S_jj)
# [TSONG96 Denk. 2-3]
# Not: izdüşüm aralıkları Sathe ve ark. 1996 Tablo III "90% C.I." sütunlarıyla özdeştir.
# =============================================================================
msd_engine <- function(A, B, conf = 0.90) {
  A <- as.matrix(A); B <- as.matrix(B)
  nA <- nrow(A); nB <- nrow(B); P <- ncol(A)
  df2 <- nA + nB - P - 1
  if (df2 < 1)
    stop(sprintf("Değişken sayısı (P=%d) çok fazla: en fazla nT+nR-2 = %d olabilir [TSONG96].",
                 P, nA + nB - 2))

  d <- colMeans(A) - colMeans(B)                 # TEST - REF
  S <- msd_pooled_cov(A, B)
  kosul <- kappa(S, exact = TRUE)
  if (!is.finite(kosul) || kosul > 1e10)
    stop("Birleştirilmiş kovaryans matrisi neredeyse tekil (koşul sayısı > 1e10).")

  DM <- sqrt(drop(crossprod(d, solve(S, d))))
  h  <- nA * nB / (nA + nB)
  T2 <- h * DM^2
  K  <- h * df2 / ((nA + nB - 2) * P)
  Fk <- stats::qf(conf, P, df2)
  r  <- sqrt(Fk / K)

  yari <- r * sqrt(diag(S))
  list(nT = nA, nR = nB, P = P, ort_T = colMeans(A), ort_R = colMeans(B),
       d = d, S = S, kosul_sayisi = kosul,
       DM = DM, T2 = T2, K = K, F = Fk, df = c(P, df2), r = r, conf = conf,
       DM_l = max(0, DM - r), DM_u = DM + r,
       sinir_nokta_alt = if (DM > r) d * (1 - r / DM) else rep(0, P),
       sinir_nokta_ust = d * (1 + r / DM),
       izd_alt = d - yari, izd_ust = d + yari)
}


# =============================================================================
# ANA FONKSİYON
# =============================================================================
# Argümanlar:
#   test, ref  : ünite × zaman matrisleri (satır = tablet, sütun = zaman noktası)
#   limit      : benzerlik sınırı yöntemi
#                "L1"  sabit global D_g           [TSONG96; EMA10 ≤ %10]
#                "L2a" referans lotları arası en büyük ortalama fark → D_g
#                "L2b" referans lotları arası en büyük MSD, doğrudan sınır
#   Dg         : L1 için global fark (varsayılan 10) — L3 hiperküp sınırı da budur
#   ref_lots   : L2a/L2b için referans lot matrisleri listesi (en az 2)
#   truncation : "none" / "FDA" / "EMA" (bkz. msd_truncate)
#   conf       : güven düzeyi (varsayılan 0.90 [FDA97 V.B adım 3])
# =============================================================================
calc_msd <- function(test, ref,
                     limit      = c("L1", "L2a", "L2b"),
                     Dg         = 10,
                     ref_lots   = NULL,
                     truncation = c("none", "FDA", "EMA"),
                     conf       = 0.90) {

  limit      <- match.arg(limit)
  truncation <- match.arg(truncation)

  # --- 0. Girdi kontrolleri ---------------------------------------------------
  test <- as.matrix(test); ref <- as.matrix(ref)
  if (!is.numeric(test) || !is.numeric(ref)) stop("Veri sayısal olmalı.")
  if (anyNA(test) || anyNA(ref))            stop("Veride NA var.")
  if (ncol(test) != ncol(ref))              stop("TEST ve REF zaman noktası sayısı farklı.")
  if (!is.null(colnames(test)) && !is.null(colnames(ref)) &&
      !identical(colnames(test), colnames(ref)))
    stop("TEST ve REF zaman noktaları aynı olmalı [FDA97 V.A; EMA10 App. I].")
  if (nrow(test) < 2 || nrow(ref) < 2)      stop("Her grupta en az 2 ünite olmalı.")
  if (is.null(colnames(test))) colnames(test) <- colnames(ref) <- paste0("t", seq_len(ncol(test)))

  uyarilar <- character(0)
  if (nrow(test) < 12 || nrow(ref) < 12)
    uyarilar <- c(uyarilar, "Ünite sayısı 12'den az [FDA97 V.A adım 1; EMA10 App. I].")

  # --- 1. %85 kesme kuralı ----------------------------------------------------
  secili <- msd_truncate(colMeans(test), colMeans(ref), truncation)
  test_k <- test[, secili, drop = FALSE]
  ref_k  <- ref[,  secili, drop = FALSE]

  # --- 2-4. Ortak motor: d, S, D_M, T², K, F, güven bölgesi -------------------
  m  <- msd_engine(test_k, ref_k, conf)
  nT <- m$nT; nR <- m$nR; P <- m$P
  mT <- m$ort_T; mR <- m$ort_R; d <- m$d; S <- m$S
  kosul_sayisi <- m$kosul_sayisi
  DM <- m$DM; T2 <- m$T2; K <- m$K; Fk <- m$F; df2 <- m$df[2]; r <- m$r
  DM_l <- m$DM_l; DM_u <- m$DM_u
  sinir_nokta_alt <- m$sinir_nokta_alt; sinir_nokta_ust <- m$sinir_nokta_ust

  # --- 5. Benzerlik sınırı ----------------------------------------------------
  lot_bilgi <- NULL
  if (limit %in% c("L2a", "L2b")) {
    if (is.null(ref_lots) || length(ref_lots) < 2)
      stop("L2a/L2b için en az 2 referans lotu gerekli [FDA97 V.B adım 1].")
    ref_lots <- lapply(ref_lots, function(m) as.matrix(m)[, secili, drop = FALSE])
    ciftler <- utils::combn(length(ref_lots), 2)
    lot_bilgi <- data.frame(
      lot1 = names(ref_lots)[ciftler[1, ]] %||% ciftler[1, ],
      lot2 = names(ref_lots)[ciftler[2, ]] %||% ciftler[2, ],
      max_ort_fark = apply(ciftler, 2, function(ij)
        max(abs(colMeans(ref_lots[[ij[1]]]) - colMeans(ref_lots[[ij[2]]])))),
      DM_RR = apply(ciftler, 2, function(ij)
        msd_distance(ref_lots[[ij[1]]], ref_lots[[ij[2]]]))
    )
  }

  if (limit == "L1") {
    # R_D = √(D_g·1' S⁻¹ D_g·1) [TSONG96, s.1109]
    Dg_kul <- Dg
    g   <- rep(Dg_kul, P)
    RD  <- sqrt(drop(crossprod(g, solve(S, g))))
    sinir_aciklama <- sprintf("L1: sabit global D_g = %g", Dg_kul)
  } else if (limit == "L2a") {
    # Referans lot çiftleri arasındaki en büyük mutlak ortalama fark → D_g
    # (FarmaStatR türetimi; TSONG96 + FDA97 V.B adım 1)
    Dg_kul <- max(lot_bilgi$max_ort_fark)
    g   <- rep(Dg_kul, P)
    RD  <- sqrt(drop(crossprod(g, solve(S, g))))
    sinir_aciklama <- sprintf("L2a: lotlar arası en büyük ortalama fark → D_g = %.4f", Dg_kul)
  } else {
    # Referans lot çiftleri arasındaki en büyük MSD, doğrudan sınır
    # (FarmaStatR türetimi; FDA97 V.B adım 1'in literal okuması)
    # Not: her çiftin MSD'si o çiftin kendi birleştirilmiş kovaryansıyla hesaplanır
    Dg_kul <- NA_real_
    RD  <- max(lot_bilgi$DM_RR)
    sinir_aciklama <- "L2b: lotlar arası en büyük MSD (D_M^RR)"
  }

  # Karar: güven aralığının üst sınırı ≤ benzerlik sınırı [FDA97 V.B adım 4]
  benzer_msd <- DM_u <= RD

  # --- 6. L3 hiperküp kontrolü (her zaman raporlanır) ------------------------
  # Güven elipsoidinin t'inci eksendeki en uç noktası:
  #   |d_t| + r·√S_tt   (Hotelling tabanlı eşzamanlı güven aralığı)
  # Koşul: her t için ≤ Dg (EMA10 App. I: "not greater than a 10% difference")
  # (FarmaStatR türetimi)
  yari_gen <- r * sqrt(diag(S))
  L3_tablo <- data.frame(
    zaman     = colnames(test_k),
    ort_T     = mT,
    ort_R     = mR,
    fark      = d,
    es_alt    = d - yari_gen,
    es_ust    = d + yari_gen,
    uc_nokta  = abs(d) + yari_gen,
    nokta_asim = abs(d) > Dg,         # nokta tahmini düzeyinde D_g aşımı (TRUE = aşım)
    row.names = NULL
  )
  benzer_L3 <- all(L3_tablo$uc_nokta <= Dg)

  # --- 7. Tanısal çıktılar ----------------------------------------------------
  cv <- function(m) 100 * apply(m, 2, stats::sd) / colMeans(m)
  tani <- data.frame(
    zaman   = colnames(test_k),
    CV_T    = cv(test_k),
    CV_R    = cv(ref_k),
    CV_oran = cv(test_k) / cv(ref_k),
    row.names = NULL
  )
  # FDA97 V.B tetikleyicisi: seri içi CV > %15
  if (max(c(tani$CV_T, tani$CV_R)) <= 15)
    uyarilar <- c(uyarilar,
      "Tüm CV ≤ %15: FDA97 V.B tetikleyici koşulu sağlanmıyor; f2 [V.A] uygun olabilir.")

  # Box's M (yalnızca bilgi amaçlı; ürün bazında n ≤ P ise tanımsız)
  boxM <- msd_boxM(test_k, ref_k)

  # --- 8. Sonuç nesnesi -------------------------------------------------------
  sonuc <- list(
    girdi        = list(nT = nT, nR = nR, P = P, zamanlar = colnames(test_k),
                        dislanan = setdiff(colnames(test), colnames(test_k)),
                        truncation = truncation, conf = conf, limit = limit),
    ort_T = mT, ort_R = mR, d = d, S = S, kosul_sayisi = kosul_sayisi,
    DM = DM, T2 = T2, K = K, F = Fk, df = c(P, df2), r = r,
    DM_l = DM_l, DM_u = DM_u,
    sinir_nokta_alt = sinir_nokta_alt, sinir_nokta_ust = sinir_nokta_ust,
    Dg = Dg_kul, RD = RD, sinir_aciklama = sinir_aciklama, lot_bilgi = lot_bilgi,
    benzer_msd = benzer_msd,
    L3 = L3_tablo, Dg_L3 = Dg, benzer_L3 = benzer_L3,
    tani = tani, boxM = boxM,
    uyarilar = uyarilar,
    regulatif = c(
      FDA = "FDA 1997 Bölüm V.B'ye uygun model bağımsız çok değişkenli güven bölgesi yöntemi.",
      EMA = paste0("EMA/TİTCK için \"destekleyici; öncelikli tercih edilen yöntem ",
                   "bootstrap f2'dir\" (EMA Q&A 3.9).")
    )
  )
  class(sonuc) <- "farmastat_msd"
  sonuc
}


# NULL birleştirme operatörü (R < 4.4 uyumluluğu için)
`%||%` <- function(a, b) if (is.null(a)) b else a


# -----------------------------------------------------------------------------
# Box's M testi — kovaryans eşitliği için (yalnızca bilgi amaçlı)
# Ürün bazında n_i - 1 < P ise |S_i| = 0 olur ve test tanımsızdır.
# -----------------------------------------------------------------------------
msd_boxM <- function(A, B) {
  P <- ncol(A); n <- c(nrow(A), nrow(B))
  if (any(n - 1 < P))
    return(list(M = NA, chi2 = NA, df = NA, p = NA,
                not = "Ürün bazında n-1 < P: tekil kovaryans, Box's M tanımsız."))
  Si <- list(stats::cov(A), stats::cov(B))
  Sp <- msd_pooled_cov(A, B)
  M  <- sum(n - 2) * log(det(Sp)) - sum((n - 1) * sapply(Si, function(s) log(det(s))))
  c1 <- (sum(1 / (n - 1)) - 1 / sum(n - 1)) * (2 * P^2 + 3 * P - 1) / (6 * (P + 1))
  chi2 <- M * (1 - c1)
  dfb  <- P * (P + 1) / 2
  list(M = M, chi2 = chi2, df = dfb, p = stats::pchisq(chi2, dfb, lower.tail = FALSE),
       not = "Bilgi amaçlı; normallikten sapmaya duyarlıdır.")
}


# -----------------------------------------------------------------------------
# Yazdırma yöntemi
# -----------------------------------------------------------------------------
print.farmastat_msd <- function(x, digits = 4, ...) {
  f <- function(v) formatC(v, digits = digits, format = "f")
  cat("\n== FarmaStatR · MSD (model bağımsız, FDA 1997 V.B / Tsong 1996) ==\n")
  cat(sprintf("nT = %d, nR = %d, P = %d zaman noktası, kesme kuralı: %s\n",
              x$girdi$nT, x$girdi$nR, x$girdi$P, x$girdi$truncation))
  if (length(x$girdi$dislanan))
    cat("Dışlanan noktalar:", paste(x$girdi$dislanan, collapse = ", "), "\n")
  cat(sprintf("\nD_M = %s   T² = %s\n", f(x$DM), f(x$T2)))
  cat(sprintf("K = %s   F(%d, %d; %.2f) = %s   yarıçap √(F/K) = %s\n",
              f(x$K), x$df[1], x$df[2], x$girdi$conf, f(x$F), f(x$r)))
  cat(sprintf("%%%d güven aralığı: [%s, %s]\n", round(100 * x$girdi$conf), f(x$DM_l), f(x$DM_u)))
  cat(sprintf("\nBenzerlik sınırı (%s): R_D = %s\n", x$sinir_aciklama, f(x$RD)))
  cat(sprintf("KARAR (MSD): %s  (D_M^üst %s R_D)\n",
              if (x$benzer_msd) "BENZER" else "BENZER DEĞİL",
              if (x$benzer_msd) "≤" else ">"))
  cat(sprintf("KARAR (L3 hiperküp, sınır ±%g): %s\n", x$Dg_L3,
              if (x$benzer_L3) "BENZER" else "BENZER DEĞİL"))
  if (x$benzer_msd != x$benzer_L3)
    cat("  ! MSD ve L3 kararları çelişiyor — EMA Q&A 3.9'daki itirazın somut örneği.\n")
  cat("\nRegülatif statü:\n")
  cat("  FDA :", x$regulatif["FDA"], "\n")
  cat("  EMA :", x$regulatif["EMA"], "\n")
  if (length(x$uyarilar)) { cat("\nUyarılar:\n"); cat(paste0("  - ", x$uyarilar, "\n"), sep = "") }
  invisible(x)
}
