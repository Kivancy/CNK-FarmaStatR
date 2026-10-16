# =============================================================================
# FSR-VAL-SIM-1 - Evidence script (simulation framework and in vitro engine)
#   Produces the numbers quoted in the validation document:
#     test_sonuclari.csv : every testthat block with its number of expectations
#     sha256.csv         : SHA-256 of the files under validation (base R, araclar/sha256.R)
#     sayisal_ozet.csv   : largest differences pbe_fast vs calc_pbe and
#                          EMA (c) closed form vs numerical REML
#     sessionInfo.txt    : R session
# Run from the repository root after installing the package:
#   R CMD INSTALL CNKfarmastatr
#   Rscript belgeler/validasyon/FSR-VAL-SIM-1_ek/kanit.R
# (Linux: LANG=C.UTF-8 is needed for the inherited test scripts.)
# Research and education only; not a system validated for GxP environments.
# =============================================================================
library(CNKfarmastatr)
out <- file.path("belgeler", "validasyon", "FSR-VAL-SIM-1_ek")
Sys.setenv(NOT_CRAN = "true")

# ---- 1. Tests ---------------------------------------------------------------
res <- testthat::test_dir(file.path("CNKfarmastatr", "tests", "testthat"), package = "CNKfarmastatr",
                          load_package = "installed", reporter = "silent", stop_on_failure = FALSE)
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
utils::write.csv(data.frame(file = files, sha256 = unname(sha), bytes = file.info(file.path("CNKfarmastatr", "R", files))$size),
                 file.path(out, "sha256.csv"), row.names = FALSE)

# ---- 3. Numerical agreement -------------------------------------------------
to_long <- function(X, r, l, n, prod) {
  N <- l * n; m <- dim(X)[3]; g <- expand.grid(u = seq_len(N), s = seq_len(m))
  data.frame(Batches = paste0(prod, (g$u - 1) %/% n + 1), Container = paste0("c", g$u),
             Stage = g$s, Product = prod, score = X[cbind(r, g$u, g$s)])
}
cols <- c("msb_t", "msw_t", "msb_r", "msw_r", "Eq_Ref", "Uq_Ref", "H_eta_Ref", "Eq_Const", "Uq_Const", "H_eta_Const")
rel <- function(a, b) ifelse(b == 0, abs(a - b), abs(a - b) / abs(b))
# 3a. pbe_fast vs calc_pbe: PSG example + the TC-F2 designs (m = 1, 2, 3; 3x10/3x10, 4x7/2x5)
dd <- ornek_psg020929(); t <- invitro_array(dd, "TEST"); r <- invitro_array(dd, "REF")
f <- pbe_fast(t$X, r$X, t$l, t$n, r$l, r$n); o <- calc_pbe(dd)
mx <- max(sapply(cols, function(k) rel(f[[k]], o[[k]]))); nset <- 1; agree <- f$pass == (o$pass_fail == "PASS")
set.seed(20261015)
for (m in 1:3) for (cfg in list(c(3, 10, 3, 10), c(4, 7, 2, 5))) {
  lT <- cfg[1]; nT <- cfg[2]; lR <- cfg[3]; nR <- cfg[4]
  XT <- invitro_gen(8, lT, nT, m, mu = 0.05, sB = 0.05, sC = 0.08, sW = 0.04, tau = invitro_drift(m, 0.0005))
  XR <- invitro_gen(8, lR, nR, m, sB = if (m > 1) 0.12 else 0.02, sC = 0.06, sW = 0.03)
  f <- pbe_fast(XT, XR, lT, nT, lR, nR)
  for (i in 1:8) {
    o <- calc_pbe(rbind(to_long(XT, i, lT, nT, "TEST"), to_long(XR, i, lR, nR, "REF")))
    mx <- max(mx, sapply(cols, function(k) rel(f[[k]][i], o[[k]])))
    agree <- c(agree, f$pass[i] == (o$pass_fail == "PASS"), f$ref_scaled[i] == (o$criterion == "Reference-scaled"))
    nset <- nset + 1
  }
}
# 3b. EMA (c) closed form vs numerical REML (base R, L-BFGS-B, four starting points)
reml_var <- function(X, l, n) {
  m <- dim(X)[3]; g <- expand.grid(u = seq_len(l * n), s = seq_len(m)); y <- X[cbind(1, g$u, g$s)]
  S <- factor(g$s)
  Xf <- if (m > 1) model.matrix(~ S, contrasts.arg = list(S = "contr.sum")) else matrix(1, length(y))
  ZL <- outer((g$u - 1) %/% n, seq_len(l) - 1, "==") * 1; ZC <- outer(g$u, seq_len(l * n), "==") * 1
  JL <- ZL %*% t(ZL); JC <- ZC %*% t(ZC); I <- diag(length(y))
  nll <- function(th) {
    v <- exp(th); V <- v[1] * JL + v[2] * JC + v[3] * I
    Rc <- chol(V); Vi <- chol2inv(Rc); A <- t(Xf) %*% Vi %*% Xf
    rr <- y - Xf %*% solve(A, t(Xf) %*% Vi %*% y)
    0.5 * (2 * sum(log(diag(Rc))) + as.numeric(determinant(A)$modulus) + sum(rr * (Vi %*% rr)))
  }
  best <- NULL
  for (s0 in list(c(-5, -5, -5), c(-25, -5, -5), c(-5, -25, -5), c(-25, -25, -5))) {
    o <- optim(s0, nll, method = "L-BFGS-B", lower = -30, upper = 2, control = list(factr = 1, maxit = 2000))
    if (is.null(best) || o$value < best$value) best <- o
  }
  v <- exp(best$par); V <- v[1] * JL + v[2] * JC + v[3] * I
  solve(t(Xf) %*% solve(V) %*% Xf)[1, 1]
}
set.seed(7); rmx <- 0; npool <- 0; nset2 <- 0
for (rep_ in 1:5) for (m in c(1, 3)) for (cs in list(c(0.05, 0.04), c(0, 0.04), c(0, 0), c(0.03, 0))) {
  X <- invitro_gen(1, 3, 4, m, sB = cs[1], sC = cs[2], sW = 0.05)
  s <- CNKfarmastatr:::.iv_stats(X, 3, 4); s$msw_resid <- CNKfarmastatr:::.iv_msw_resid(X)
  vc <- CNKfarmastatr:::.iv_var_mean(s, "c")
  rmx <- max(rmx, rel(vc$v, reml_var(X, 3, 4))); npool <- npool + (vc$df > 2); nset2 <- nset2 + 1
}
utils::write.csv(data.frame(
  check = c("pbe_fast_vs_calc_pbe_max_rel_diff", "pbe_fast_vs_calc_pbe_data_sets", "pbe_fast_vs_calc_pbe_decisions_identical",
            "ema_c_vs_reml_max_rel_diff", "ema_c_vs_reml_data_sets", "ema_c_vs_reml_pooled_sets"),
  value = c(signif(mx, 3), nset, all(agree), signif(rmx, 3), nset2, npool)),
  file.path(out, "sayisal_ozet.csv"), row.names = FALSE)

# ---- 4. Session -------------------------------------------------------------
writeLines(utils::capture.output(utils::sessionInfo()), file.path(out, "sessionInfo.txt"))
cat("blocks:", nrow(tab), " expectations:", sum(tab$expectations), " failed:", sum(tab$failed),
    " skipped:", sum(tab$skipped), "\n")
print(utils::read.csv(file.path(out, "sayisal_ozet.csv")))
print(data.frame(file = files, sha256 = unname(sha)))
