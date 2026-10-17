# =============================================================================
# FSR-VAL-SIM-1 - Evidence script (simulation framework and in vitro engine)
#   v0.2 (decision KK-41): acceptance rules of Table 5.1 applied explicitly.
#   v0.3: TC-F11 near-limit pair (flagging rule) reported in sayisal_ozet.csv.
#   v0.4: test data come from tests/testthat/helper-cases.R (no copied code; G-49).
#   Numerical rule: |x_hat - x| <= atol + rtol * max(|x|, |x_hat|); reported as
#   the largest ratio |diff| / (atol + rtol * max), which must be <= 1.
#   Outputs (this folder):
#     test_sonuclari.csv : every testthat block with its number of expectations
#     sha256.csv         : SHA-256 of the files under validation (base R, araclar/sha256.R)
#     sayisal_ozet.csv   : reference comparisons (pbe_fast vs calc_pbe; EMA (c) vs
#                          numerical REML incl. criterion, CI and decision)
#     sas_kabul.csv      : SAS comparison per data set against the rules of Table 5.1
#     mc_z.csv           : Monte Carlo checks (TC-S5, TC-F10) with z and warning flag
#     sessionInfo.txt    : R session
# Run from the repository root after installing the package:
#   R CMD INSTALL CNKfarmastatr
#   Rscript belgeler/validasyon/FSR-VAL-SIM-1_ek/kanit.R
# (Linux: LANG=C.UTF-8 is needed for the inherited test scripts.)
# Research and education only; not a system validated for GxP environments.
# =============================================================================
library(CNKfarmastatr)
out <- file.path("belgeler", "validasyon", "FSR-VAL-SIM-1_ek")
tdir <- file.path("CNKfarmastatr", "tests", "testthat")
Sys.setenv(NOT_CRAN = "true")
source(file.path(tdir, "helper-reml.R")); source(file.path(tdir, "helper-cases.R"))   # shared test data
ratio <- function(x, y, atol, rtol) max(abs(x - y) / (atol + rtol * pmax(abs(x), abs(y))))

# ---- 1. Tests ---------------------------------------------------------------
res <- testthat::test_dir(tdir, package = "CNKfarmastatr", load_package = "installed",
                          reporter = "silent", stop_on_failure = FALSE)
d <- as.data.frame(res)
tc <- sub("^(TC-[A-Z]+[0-9]+).*$", "\\1", d$test)
tab <- data.frame(file = d$file, test_case = ifelse(grepl("^TC-", d$test), tc, d$test),
                  expectations = d$nb, failed = d$failed, skipped = as.integer(d$skipped),
                  error = d$error, stringsAsFactors = FALSE)
utils::write.csv(tab, file.path(out, "test_sonuclari.csv"), row.names = FALSE)

# ---- 2. SHA-256 -------------------------------------------------------------
source(file.path("araclar", "sha256.R"), encoding = "UTF-8")
files <- c("sim_performance.R", "sim_run.R", "sim_scenario_demo.R", "invitro_fast.R", "invitro_grid.R")
sha <- vapply(files, function(f) {
  p <- file.path("CNKfarmastatr", "R", f); sha256_raw(readBin(p, "raw", file.info(p)$size))
}, character(1))
utils::write.csv(data.frame(file = files, sha256 = unname(sha),
                            bytes = file.info(file.path("CNKfarmastatr", "R", files))$size),
                 file.path(out, "sha256.csv"), row.names = FALSE)

# ---- 3. Reference comparisons ----------------------------------------------
cols <- pbe_cols                                   # helper-cases.R
# 3a. pbe_fast vs calc_pbe: PSG example + the TC-F2 designs (rule: atol = rtol = 1e-12)
dd <- ornek_psg020929(); t <- invitro_array(dd, "TEST"); r <- invitro_array(dd, "REF")
f <- pbe_fast(t$X, r$X, t$l, t$n, r$l, r$n); o <- calc_pbe(dd)
rp <- max(sapply(cols, function(k) ratio(f[[k]], o[[k]], 1e-12, 1e-12)))
nset <- 1; agree <- f$pass == (o$pass_fail == "PASS")
for (cs in cases_tcf2()) {                         # helper-cases.R (TC-F2 data)
  f <- pbe_fast(cs$XT, cs$XR, cs$lT, cs$nT, cs$lR, cs$nR)
  for (i in 1:8) {
    o <- calc_pbe(rbind(to_long(cs$XT, i, cs$lT, cs$nT, "TEST"), to_long(cs$XR, i, cs$lR, cs$nR, "REF")))
    rp <- max(rp, sapply(cols, function(k) ratio(f[[k]][i], o[[k]], 1e-12, 1e-12)))
    agree <- c(agree, f$pass[i] == (o$pass_fail == "PASS"), f$ref_scaled[i] == (o$criterion == "Reference-scaled"))
    nset <- nset + 1
  }
}
# 3b. EMA (c) vs numerical REML, TC-F11 data sets (rules: variance and CI atol 1e-10,
#     rtol 1e-5; criterion closed <= numerical + 1e-8; decision identical unless a
#     CI limit is within a relative 1e-5 of 0.85 or 1.18)
c11 <- cases_tcf11(); l <- c11$l; n <- c11$n        # helper-cases.R (TC-F11 data)
rv <- rci <- 0; dnll <- -Inf; npair <- npool <- nagree <- nflag <- npass <- 0
for (pr in c11$pairs) {
  m <- pr$m; XT <- pr$XT; XR <- pr$XR
  MT <- matrix(XT[1, , ], l * n, m); MR <- matrix(XR[1, , ], l * n, m)
  cl <- list(T = reml_closed(MT, l, n), R = reml_closed(MR, l, n))
  nu <- list(T = reml_numeric(MT, l, n), R = reml_numeric(MR, l, n))
  for (p in c("T", "R")) {
    M <- if (p == "T") MT else MR
    rv <- max(rv, ratio(cl[[p]]$v_mean, nu[[p]]$v_mean, 1e-10, 1e-5))
    dnll <- max(dnll, reml_nll(cl[[p]]$comp, M, l, n) - nu[[p]]$nll)
    npool <- npool + (cl[[p]]$df > l - 1)
  }
  ci <- ema_ci_fast(XT, XR, l, n, l, n, methods = "c")$c
  cn <- ci_from_var(mean(MT) - mean(MR), nu$T$v_mean, nu$R$v_mean, cl$T$df, cl$R$df)
  rci <- max(rci, ratio(c(ci$lower, ci$upper), cn, 1e-10, 1e-5))
  near <- any(abs(c(ci$lower, ci$upper) - c(0.85, 1.18)) <= 1e-5 * c(0.85, 1.18))
  nflag <- nflag + near
  nagree <- nagree + (!near && ci$pass == (cn[1] >= 0.85 && cn[2] <= 1.18))
  npass <- npass + ci$pass; npair <- npair + 1
}
# 3c. Flagging rule (v0.3): the TC-F11 pair shifted so that the upper limit is 1.18 (1 - 3e-6)
XT <- c11$near$XT; XR <- c11$near$XR
ci <- ema_ci_fast(XT, XR, l, n, l, n, methods = "c")$c
MT <- matrix(XT[1, , ], l * n, 3); MR <- matrix(XR[1, , ], l * n, 3)
cn <- ci_from_var(mean(MT) - mean(MR), reml_numeric(MT, l, n)$v_mean, reml_numeric(MR, l, n)$v_mean,
                  reml_closed(MT, l, n)$df, reml_closed(MR, l, n)$df)
near_flag <- any(abs(c(ci$lower, ci$upper) - c(0.85, 1.18)) <= 1e-5 * c(0.85, 1.18))
utils::write.csv(data.frame(
  check = c("pbe_fast_vs_calc_pbe_data_sets", "pbe_fast_vs_calc_pbe_max_ratio_atol1e-12_rtol1e-12",
            "pbe_fast_vs_calc_pbe_decisions_and_criteria_identical",
            "ema_c_vs_reml_data_set_pairs", "ema_c_vs_reml_products_pooled",
            "ema_c_vs_reml_var_mean_max_ratio_atol1e-10_rtol1e-5",
            "ema_c_vs_reml_max_criterion_closed_minus_numerical",
            "ema_c_vs_reml_ci_max_ratio_atol1e-10_rtol1e-5",
            "ema_c_vs_reml_decisions_identical", "ema_c_vs_reml_decisions_flagged_near_limit",
            "ema_c_vs_reml_pairs_passing_0.85_1.18",
            "near_limit_pair_engine_upper", "near_limit_pair_numerical_upper", "near_limit_pair_flagged",
            "near_limit_pair_engine_pass", "near_limit_pair_numerical_pass", "near_limit_pair_ci_max_ratio"),
  value = c(nset, signif(rp, 3), as.character(all(agree)), npair, npool, signif(rv, 3),
            signif(dnll, 3), signif(rci, 3), nagree, nflag, npass,
            sprintf("%.10f", ci$upper), sprintf("%.10f", cn[2]), near_flag, ci$pass,
            cn[1] >= 0.85 && cn[2] <= 1.18, signif(ratio(c(ci$lower, ci$upper), cn, 1e-10, 1e-5), 3))),
  file.path(out, "sayisal_ozet.csv"), row.names = FALSE)

# ---- 4. SAS comparison against Table 5.1 -----------------------------------
#   Deterministic quantities (all sets) and interior REML solutions (sets where no
#   stratum is pooled in either product): atol 1e-10, rtol 1e-9.
#   REML boundary solutions: (1) REML criterion at the R closed form <= at the SAS
#   estimates + 1e-8 (per product); (2) 90% CI limits on the ratio scale within
#   1e-4; (3) EMA decision identical. Variance components, SE and df at the
#   boundary are recorded, not judged (SAS stops at its convergence criterion).
S <- file.path("belgeler", "teknik_notlar", "FSR-TN-PBE-01_ek", "sas")
rd <- function(f) utils::read.csv(file.path(S, f), stringsAsFactors = FALSE)
rb <- rd("r_beklenen.csv"); dat <- rd("sas_veri.csv"); ss <- rd("sas_glm_ss.csv")
cp <- rd("sas_covparms.csv"); sat <- rd("sas_diffs_sat.csv"); cv <- rd("sas_conv_sat.csv")
nll_sas <- function(v, x) {
  y <- x$y; S_ <- factor(x$stage); X <- stats::model.matrix(~ S_)
  ZL <- stats::model.matrix(~ factor(x$batch) - 1)
  ZC <- stats::model.matrix(~ factor(paste(x$batch, x$unit)) - 1)
  V <- v[1] * ZL %*% t(ZL) + v[2] * ZC %*% t(ZC) + v[3] * diag(length(y))
  Rc <- chol(V); Vi <- chol2inv(Rc); A <- t(X) %*% Vi %*% X
  e <- y - X %*% solve(A, t(X) %*% Vi %*% y)
  0.5 * (2 * sum(log(diag(Rc))) + as.numeric(determinant(A)$modulus) + sum(e * (Vi %*% e)))
}
h <- function(s, pr, src, col = "MS") ss[[col]][ss$set == s & ss$product == pr & ss$Source == src]
g <- function(s, pr, par) cp$Estimate[cp$set == s & cp$Group == paste("product", pr) & cp$CovParm == par]
pass_ema <- function(lo, hi) lo >= 0.85 & hi <= 1.18
sas <- do.call(rbind, lapply(seq_len(nrow(rb)), function(i) {
  s <- rb$set[i]; N <- rb$l[i] * rb$n[i]; m <- rb$m[i]
  interior <- rb$reml_case_T[i] == "none" && rb$reml_case_R[i] == "none"
  det <- max(sapply(c("T", "R"), function(pr) max(
    ratio(h(s, pr, "batch"), rb[[paste0("ms_lot_", pr)]][i], 1e-10, 1e-9),
    ratio(h(s, pr, "unit(batch)"), rb[[paste0("ms_unit_", pr)]][i], 1e-10, 1e-9),
    ratio(h(s, pr, "Error"), rb[[paste0("ms_res_", pr)]][i], 1e-10, 1e-9),
    ratio((h(s, pr, "batch", "SS") + h(s, pr, "unit(batch)", "SS")) / (N - 1), rb[[paste0("msb_psg_", pr)]][i], 1e-10, 1e-9),
    ratio((h(s, pr, "stage", "SS") + h(s, pr, "Error", "SS")) / (N * (m - 1)), rb[[paste0("msw_psg_", pr)]][i], 1e-10, 1e-9))))
  x <- dat[dat$set == s, ]; vc_r <- dl <- numeric(0)
  for (pr in c("T", "R")) {
    vR <- c(rb[[paste0("sB2_", pr)]][i], rb[[paste0("sC2_", pr)]][i], rb[[paste0("sW2_", pr)]][i])
    vS <- c(g(s, pr, "batch"), g(s, pr, "unit(batch)"), g(s, pr, "Residual"))
    vc_r <- c(vc_r, ratio(vS, vR, 1e-10, 1e-9))
    dl <- c(dl, nll_sas(vR, x[x$product == pr, ]) - nll_sas(vS, x[x$product == pr, ]))
  }
  j <- match(s, sat$set); has <- !is.na(j) && cv$Status[cv$set == s] == 0
  o <- data.frame(set = s, solution = if (interior) "interior" else "boundary",
                  sas_status = cv$Reason[cv$set == s], det_ratio = det,
                  vc_ratio = max(vc_r), criterion_r_minus_sas = max(dl))
  if (has) {
    lo_s <- exp(-sat$Upper[j]); hi_s <- exp(-sat$Lower[j])
    o$diff_ratio <- ratio(-sat$Estimate[j], rb$diff[i], 1e-10, 1e-9)
    o$se_ratio <- ratio(sat$StdErr[j], rb$se_c[i], 1e-10, 1e-9)
    o$df_ratio <- ratio(sat$DF[j], rb$df_c[i], 1e-10, 1e-9)
    o$ci_absdiff <- max(abs(c(lo_s, hi_s) - c(rb$lower90_c[i], rb$upper90_c[i])))
    o$ci_ratio <- ratio(c(lo_s, hi_s), c(rb$lower90_c[i], rb$upper90_c[i]), 1e-10, 1e-9)
    o$decision_same <- pass_ema(lo_s, hi_s) == pass_ema(rb$lower90_c[i], rb$upper90_c[i])
  } else o[c("diff_ratio", "se_ratio", "df_ratio", "ci_absdiff", "ci_ratio", "decision_same")] <- NA
  o$accept <- if (!has) "SAS sonuc uretmedi" else if (interior) {
    if (max(det, o$vc_ratio, o$diff_ratio, o$se_ratio, o$df_ratio, o$ci_ratio) <= 1 && o$decision_same) "GECTI" else "KALDI"
  } else {
    if (det <= 1 && o$diff_ratio <= 1 && o$criterion_r_minus_sas <= 1e-8 && o$ci_absdiff <= 1e-4 && o$decision_same) "GECTI" else "KALDI"
  }
  o
}))
utils::write.csv(sas, file.path(out, "sas_kabul.csv"), row.names = FALSE)

# ---- 5. Monte Carlo checks with z and warning flag (|z| < 4 accept; 3 <= |z| < 4 warn)
mc_s5 <- mc_tcs5(); attr(mc_s5, "performance") <- NULL   # helper-cases.R
mc <- rbind(mc_s5, mc_tcf10(3, 0.3, 0.5), mc_tcf10(3, 0, 0.5), mc_tcf10(2, 0.1, 0.5), mc_tcf10(1, 0.3, 0))
mc$status <- ifelse(abs(mc$z) >= 4, "KALDI", ifelse(abs(mc$z) >= 3, "UYARI", "GECTI"))
utils::write.csv(mc, file.path(out, "mc_z.csv"), row.names = FALSE)

# ---- 6. Session -------------------------------------------------------------
writeLines(utils::capture.output(utils::sessionInfo()), file.path(out, "sessionInfo.txt"))
cat("blocks:", nrow(tab), " expectations:", sum(tab$expectations), " failed:", sum(tab$failed),
    " skipped:", sum(tab$skipped), "\n")
print(utils::read.csv(file.path(out, "sayisal_ozet.csv")))
print(sas, digits = 3)
print(mc[, c("test", "item", "z", "status")], digits = 3)
