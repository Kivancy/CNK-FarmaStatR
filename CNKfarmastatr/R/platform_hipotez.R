# =============================================================================
# CNK-FarmaStatR v1 - Platform: hypothesis state, metric name, KK-38 label and
#   canonical scenario key for the in vitro equivalence module
#
# FSR-TN-PLT-02 v0.1 (approved, KK-49), T-1 and T-2; rules from FSR-TN-PLT-01
#   v0.5 Section 5 (Table 5.1 classification, Table 5.2 metric names, Section 5.3
#   numerical tolerance; decisions KK-44, KK-45) and Section 6.3 (D-03).
#   FDA PBE (PSG 020929): eta = delta^2 + sigma_T^2 - sigma_R^2
#                                - theta_p * max(sigma_R^2, sigma_T0^2)
#     H0: eta >= 0. The criterion is chosen by the TRUE sigma_R.
#   EMA OIP Rev. 2 Section 5.1 criterion 8: H0: GMR <= 0.85 or GMR >= 1.18;
#     methods (a), (b), (c) test the same hypothesis.
#   Classes: H0_sinir (|distance| <= tol), H0_ic, H1; tol = 1e-12 is a project
#     tolerance for floating-point deviations, not an equivalence margin
#     (FSR-TN-PLT-01 Section 5.3, owner's text).
#   Near-boundary warning (P2-K1, option b; FarmaStatR derivation): one delta
#     scale for both methods, |delta - delta_boundary| <= 1e-4, only when the
#     class is not H0_sinir. FDA boundaries are +-delta0; no FDA warning when
#     delta0 is undefined (eta > 0 already at delta = 0).
#   KK-38: type I error labels, one-sided 95% Monte Carlo limits; z = qnorm(0.95)
#     as in asama2_ozet.R (1.645 in the decision text is this value rounded).
# Base R only. Version 0.1.0
# Research and education only; not a system validated for GxP environments.
# =============================================================================

.platform_sinir_adlari <- c("fda_delta0", "fda_minus_delta0", "ema_1.18", "ema_0.85",
                            "gmr_1.00", "gmr_1.05")

# FDA boundary mean difference delta0 (eta = 0), vectorised; NA if undefined
.platform_delta0 <- function(sigma_R, rho, sigma_T0 = 0.1) {
  theta_p <- ((log(1.11))^2 + 0.01) / sigma_T0^2
  sT2 <- (rho * sigma_R)^2
  d2 <- ifelse(sigma_R > sigma_T0, (1 + theta_p) * sigma_R^2 - sT2,
               sigma_R^2 + theta_p * sigma_T0^2 - sT2)
  ifelse(d2 < 0, NA_real_, sqrt(pmax(d2, 0)))
}

# delta for a named boundary (FSR-TN-PLT-01 Section 5.3; grid column delta_id)
platform_sinir_delta <- function(sinir, sigma_R, rho, sigma_T0 = 0.1, ema_limits = c(0.85, 1.18)) {
  bad <- setdiff(unique(sinir), .platform_sinir_adlari)
  if (length(bad)) stop("Unknown boundary name: ", paste(bad, collapse = ", "), ".")
  d0 <- .platform_delta0(sigma_R, rho, sigma_T0)
  out <- rep(NA_real_, length(sinir))
  out[sinir == "fda_delta0"] <- d0[sinir == "fda_delta0"]
  out[sinir == "fda_minus_delta0"] <- -d0[sinir == "fda_minus_delta0"]
  out[sinir == "ema_1.18"] <- log(ema_limits[2])
  out[sinir == "ema_0.85"] <- log(ema_limits[1])
  out[sinir == "gmr_1.00"] <- log(1.00)
  out[sinir == "gmr_1.05"] <- log(1.05)
  out
}

# -----------------------------------------------------------------------------
# platform_hipotez(): true hypothesis state per scenario and method
#   Give either delta (log scale) or sinir (boundary name). Vectorised: all
#   arguments are recycled to the number of scenarios.
#   Returns one row per scenario and method (fda, ema_a, ema_b, ema_c).
# -----------------------------------------------------------------------------
platform_hipotez <- function(sigma_R, rho = 1, delta = NULL, sinir = NULL, sigma_T0 = 0.1,
                             ema_limits = c(0.85, 1.18), tol = 1e-12, yakinlik = 1e-4) {
  if (is.null(delta) == is.null(sinir)) stop("Give exactly one of delta and sinir.")
  n <- max(length(sigma_R), length(rho), length(delta), length(sinir))
  sigma_R <- rep_len(sigma_R, n); rho <- rep_len(rho, n)
  if (!is.null(sinir)) {
    sinir <- rep_len(sinir, n)
    delta <- platform_sinir_delta(sinir, sigma_R, rho, sigma_T0, ema_limits)
    if (anyNA(delta)) stop("FDA delta0 is not defined for some scenarios (eta > 0 at delta = 0).")
  } else {
    delta <- rep_len(delta, n); sinir <- rep(NA_character_, n)
  }
  if (any(!is.finite(c(sigma_R, rho, delta))) || any(sigma_R <= 0) || any(rho <= 0))
    stop("sigma_R and rho must be > 0 and delta finite.")
  theta_p <- ((log(1.11))^2 + 0.01) / sigma_T0^2
  eta <- delta^2 + (rho * sigma_R)^2 - sigma_R^2 - theta_p * pmax(sigma_R^2, sigma_T0^2)
  cls_fda <- ifelse(abs(eta) <= tol, "H0_sinir", ifelse(eta > 0, "H0_ic", "H1"))
  lo <- log(ema_limits[1]); hi <- log(ema_limits[2])
  cls_ema <- ifelse(abs(delta - lo) <= tol | abs(delta - hi) <= tol, "H0_sinir",
                    ifelse(delta < lo | delta > hi, "H0_ic", "H1"))
  d0 <- .platform_delta0(sigma_R, rho, sigma_T0)
  dist_fda <- ifelse(is.na(d0), Inf, pmin(abs(delta - d0), abs(delta + d0)))
  dist_ema <- pmin(abs(delta - lo), abs(delta - hi))
  metric <- function(cl) c(H0_sinir = "tip1_sinir", H0_ic = "noktasal_tip1", H1 = "guc")[cl]
  meth <- c("fda", "ema_a", "ema_b", "ema_c")
  i <- rep(seq_len(n), each = 4); me <- rep(meth, n)
  is_fda <- me == "fda"
  cls <- ifelse(is_fda, cls_fda[i], cls_ema[i])
  dist <- ifelse(is_fda, dist_fda[i], dist_ema[i])
  data.frame(senaryo = i, yontem = me,
             buyukluk = ifelse(is_fda, eta[i], delta[i]),
             buyukluk_tur = ifelse(is_fda, "eta", "ln_gmr"),
             sinif = cls, metrik = unname(metric(cls)),
             yakinlik_uyarisi = cls != "H0_sinir" & dist <= yakinlik,
             delta = delta[i], delta_metin = .num_exact(delta[i]), sinir = sinir[i],
             stringsAsFactors = FALSE)
}

# -----------------------------------------------------------------------------
# platform_kk38(): three-class type I error label (decision KK-38), H0 only
#   p_hat - z MCSE > nominal  -> "nominali_asiyor"
#   p_hat + z MCSE <= nominal -> "kontrol_kanitli"
#   otherwise                 -> "ayirt_edilemiyor";  H1 -> NA
# -----------------------------------------------------------------------------
platform_kk38 <- function(p_hat, mcse, sinif, nominal = 0.05, z = stats::qnorm(0.95)) {
  lab <- ifelse(p_hat - z * mcse > nominal, "nominali_asiyor",
                ifelse(p_hat + z * mcse <= nominal, "kontrol_kanitli", "ayirt_edilemiyor"))
  ifelse(sinif %in% c("H0_sinir", "H0_ic"), lab, NA_character_)
}

# -----------------------------------------------------------------------------
# platform_anahtar(): canonical keys (FSR-TN-PLT-02 Section 4; D-03)
#   Fixed order of name=value pairs separated by "|". delta is written as the
#   boundary name when one is given, otherwise with .num_exact(); a GMR input
#   is converted once to delta = log(gmr). Defaults of invitro_scenario() are
#   written explicitly.
#   Scenario key = data-generating condition only, independent of the run
#   (FSR-TN-PLT-01 Table 6.1, "senaryo"); run key (kosu = TRUE) = scenario key
#   + n_sim + seed. (FSR-TN-PLT-02 v0.1 Section 4 listed n_sim and seed in one
#   key; resolved into these two keys, G-65.)
# -----------------------------------------------------------------------------
platform_anahtar <- function(sigma_R, rho = 1, pB_T = 0, pB_R = pB_T, pL = 0.15, q = 0,
                             l = 3, n = 10, m = 3, delta = NULL, gmr = NULL, sinir = NULL,
                             n_sim = 10000, seed = 20261015, kosu = FALSE) {
  given <- !c(is.null(delta), is.null(gmr), is.null(sinir))
  if (sum(given) != 1) stop("Give exactly one of delta, gmr and sinir.")
  dtxt <- if (!is.null(sinir)) {
    bad <- setdiff(unique(sinir), .platform_sinir_adlari)
    if (length(bad)) stop("Unknown boundary name: ", paste(bad, collapse = ", "), ".")
    sinir
  } else .num_exact(if (!is.null(gmr)) log(gmr) else delta)
  f <- function(v) .num_exact(as.numeric(v))
  paste0("sigma_R=", f(sigma_R), "|rho=", f(rho), "|pB_T=", f(pB_T), "|pB_R=", f(pB_R),
         "|pL=", f(pL), "|q=", f(q), "|l=", f(l), "|n=", f(n), "|m=", f(m),
         "|delta=", dtxt, if (kosu) paste0("|n_sim=", f(n_sim), "|seed=", f(seed)) else "")
}
