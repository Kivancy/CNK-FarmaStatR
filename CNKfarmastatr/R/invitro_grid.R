# =============================================================================
# CNK-FarmaStatR v1 - In vitro equivalence: one scenario of the results grid
#
# Technical note FSR-TN-PBE-01 v0.4, Section 10 (ADEMP); decisions KK-29 ...
#   KK-35. One call = one data-generating mechanism; FDA PBE and EMA CI methods
#   (a), (b), (c) are applied to the same simulated data sets (Morris, White &
#   Crowther 2019, Section 4.3). Every scenario starts from the same seed
#   (common random numbers; Morris et al. 2019, Sections 4.1.1 and 5.4).
# Performance measures and Monte Carlo SEs: Morris et al. 2019, Table 6.
# v0.2.0 (decision of 16.10.2026, review report 02, M-07/M-09): paired Monte
#   Carlo SEs for method differences (sd of per-replicate decision differences
#   / sqrt(n_sim); Morris et al. 2019, Section 5.2), the share of replicates in
#   which EMA method (c) pools strata (REML boundary), and optional per-replicate
#   decisions (keep_reps). No extra random numbers are drawn: results of v0.1.0
#   are reproduced exactly.
# Base R only. Version 0.2.0
# =============================================================================

# -----------------------------------------------------------------------------
# invitro_scenario(): simulate one scenario and return a one-row data frame
#   sigma_R : total SD of the reference (log scale); sigma_T = rho * sigma_R
#   pB, pL  : batch and life-stage shares of the total variance (KK-29);
#             pB_T / pB_R allow different batch shares for T and R (KK-30)
#   q       : share of the life-stage component that is systematic drift (KK-31)
#   l, n, m : batches per product, units per batch, life stages (T = R design)
#   delta   : true mean difference mu_T - mu_R (log scale)
# -----------------------------------------------------------------------------
invitro_scenario <- function(sigma_R, rho = 1, pB = 0, pL = 0.15, q = 0,
                             l = 3, n = 10, m = 3, delta = 0,
                             pB_T = pB, pB_R = pB, n_sim = 10000, seed = 20261015,
                             alpha = 0.05, sigma_T0 = 0.1, ema_limits = c(0.85, 1.18),
                             keep_reps = FALSE) {
  # m = 1: one measurement per unit; the life-stage share is part of the unit
  # level (PSG 020929 Appendix Step 4) and a systematic stage drift cannot exist
  if (m == 1 && q > 0) stop("q > 0 needs m >= 2 (with m = 1 there is no stage drift).")
  sigma_T <- rho * sigma_R
  cT <- invitro_components(sigma_T, pB_T, pL, q)
  cR <- invitro_components(sigma_R, pB_R, pL, q)
  set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion")
  XT <- invitro_gen(n_sim, l, n, m, mu = delta, sB = cT$sB, sC = cT$sC, sW = cT$sW,
                    tau = invitro_drift(m, cT$drift_var))
  XR <- invitro_gen(n_sim, l, n, m, mu = 0, sB = cR$sB, sC = cR$sC, sW = cR$sW,
                    tau = invitro_drift(m, cR$drift_var))
  f <- pbe_fast(XT, XR, l, n, l, n, alpha = alpha, sigma_T0 = sigma_T0)
  e <- ema_ci_fast(XT, XR, l, n, l, n, level = 1 - 2 * alpha, limits = ema_limits)
  theta_p <- ((log(1.11))^2 + 0.01) / sigma_T0^2
  # true eta with the criterion chosen by the true sigma_R (TN 10.3)
  ref_true <- sigma_R > sigma_T0
  eta <- if (ref_true) delta^2 + sigma_T^2 - (1 + theta_p) * sigma_R^2 else
    delta^2 + sigma_T^2 - sigma_R^2 - theta_p * sigma_T0^2
  Eq <- if (ref_true) f$Eq_Ref else f$Eq_Const
  Hq <- if (ref_true) f$H_eta_Ref else f$H_eta_Const
  pr <- function(x) c(mean(x), sqrt(mean(x) * (1 - mean(x)) / length(x)))
  mn <- function(x) c(mean(x), stats::sd(x) / sqrt(length(x)))
  out <- data.frame(sigma_R = sigma_R, rho = rho, pB_T = pB_T, pB_R = pB_R, pL = pL,
                    q = q, l = l, n = n, m = m, delta = delta, gmr = exp(delta),
                    eta = eta, n_sim = n_sim, seed = seed)
  add <- function(name, v) { out[[name]] <<- v[1]; out[[paste0(name, "_mcse")]] <<- v[2] }
  add("fda_pass", pr(f$pass))
  add("fda_crit_err", pr(f$ref_scaled != ref_true))
  add("fda_cover", pr(Hq >= eta))
  add("fda_bias_Eq", mn(Eq - eta))
  add("fda_bias_s2R", mn(f$sigma_r^2 - sigma_R^2))
  for (me in names(e)) {
    x <- e[[me]]
    add(paste0("ema_", me, "_pass"), pr(x$pass))
    add(paste0("ema_", me, "_cover"), pr(x$lower <= exp(delta) & exp(delta) <= x$upper))
  }
  # EMA (c): share of replicates in which the REML solution pools strata
  # (boundary: a variance component estimated as 0), per product
  pooled <- function(X) {
    s <- .iv_stats(X, l, n); s$msw_resid <- .iv_msw_resid(X)
    .iv_var_mean(s, "c")$df != l - 1
  }
  pT <- pooled(XT); pR <- pooled(XR)
  add("ema_c_pooled_T", pr(pT)); add("ema_c_pooled_R", pr(pR))
  # paired differences of pass decisions on the same data sets
  dec <- data.frame(fda = f$pass, ema_a = e$a$pass, ema_b = e$b$pass, ema_c = e$c$pass)
  pairs <- list(c("fda", "ema_a"), c("fda", "ema_b"), c("fda", "ema_c"),
                c("ema_a", "ema_c"), c("ema_b", "ema_c"))
  for (pp in pairs) add(paste0("diff_", pp[1], "_", pp[2]),
                        mn(as.numeric(dec[[pp[1]]]) - as.numeric(dec[[pp[2]]])))
  if (keep_reps) attr(out, "reps") <- cbind(rep = seq_len(n_sim), dec,
                                            ema_c_pooled_T = pT, ema_c_pooled_R = pR)
  out
}

# Boundary mean difference for FDA type I error (TN Eq. 11): eta = 0
invitro_delta0 <- function(sigma_R, rho = 1, sigma_T0 = 0.1) {
  theta_p <- ((log(1.11))^2 + 0.01) / sigma_T0^2
  sigma_T <- rho * sigma_R
  d2 <- if (sigma_R > sigma_T0) (1 + theta_p) * sigma_R^2 - sigma_T^2 else
    sigma_R^2 + theta_p * sigma_T0^2 - sigma_T^2
  if (d2 < 0) NA_real_ else sqrt(d2)
}

# Run record (project rule: parameters, seed, RNG kind, R and package versions)
invitro_run_record <- function(grid_id, seed, n_sim) {
  pv <- tryCatch(as.character(utils::packageVersion("CNKfarmastatr")),
                 error = function(e) "source")
  data.frame(grid_id = grid_id, seed = seed, n_sim = n_sim,
             rng = paste(RNGkind()[1:2], collapse = "/"),
             r_version = R.version.string, package_version = pv,
             engine = "invitro_fast.R 0.1.1; invitro_grid.R 0.2.0",
             run_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
}
