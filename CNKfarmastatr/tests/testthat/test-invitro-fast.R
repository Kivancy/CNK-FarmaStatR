# In vitro simulation engine (invitro_fast.R): pbe_fast, ema_ci_fast, invitro_gen
# Test cases TC-F1 ... TC-F11. Reference for pbe_fast is the validated calc_pbe().
# Acceptance rules (FSR-VAL-SIM-1 v0.2, KK-41): expect_close() = combined absolute
# and relative tolerance (helper-tolerance.R); Monte Carlo checks |z| < 4.

to_long <- function(X, r, l, n, prod) {
  N <- l * n; m <- dim(X)[3]
  g <- expand.grid(u = seq_len(N), s = seq_len(m))
  data.frame(Batches = paste0(prod, (g$u - 1) %/% n + 1), Container = paste0("c", g$u),
             Stage = g$s, Product = prod, score = X[cbind(r, g$u, g$s)])
}
pbe_cols <- c("msb_t", "msw_t", "msb_r", "msw_r", "Eq_Ref", "Uq_Ref", "H_eta_Ref",
              "Eq_Const", "Uq_Const", "H_eta_Const")

test_that("TC-F1 pbe_fast equals calc_pbe on the PSG 020929 example data", {
  d <- ornek_psg020929()
  t <- invitro_array(d, "TEST"); r <- invitro_array(d, "REF")
  expect_equal(c(t$l, t$n, t$m), c(3, 10, 3), tolerance = 0)
  f <- pbe_fast(t$X, r$X, t$l, t$n, r$l, r$n)
  o <- calc_pbe(d)
  for (k in pbe_cols) expect_close(f[[k]], o[[k]], atol = 1e-12, rtol = 1e-12, info = k)
  expect_close(f$sigma_r, o$Sigma_R, atol = 1e-12, rtol = 1e-12)
  expect_close(f$H_eta, o$H_eta_final, atol = 1e-12, rtol = 1e-12)
  expect_identical(f$pass, o$pass_fail == "PASS")
})

test_that("TC-F2 pbe_fast equals calc_pbe for m = 1, 2, 3 and unequal designs", {
  set.seed(20261015)
  for (m in 1:3) for (cfg in list(c(3, 10, 3, 10), c(4, 7, 2, 5))) {
    lT <- cfg[1]; nT <- cfg[2]; lR <- cfg[3]; nR <- cfg[4]
    XT <- invitro_gen(8, lT, nT, m, mu = 0.05, sB = 0.05, sC = 0.08, sW = 0.04,
                      tau = invitro_drift(m, 0.0005))
    XR <- invitro_gen(8, lR, nR, m, sB = if (m > 1) 0.12 else 0.02, sC = 0.06, sW = 0.03)
    f <- pbe_fast(XT, XR, lT, nT, lR, nR)
    for (i in 1:8) {
      o <- calc_pbe(rbind(to_long(XT, i, lT, nT, "TEST"), to_long(XR, i, lR, nR, "REF")))
      for (k in pbe_cols) expect_close(f[[k]][i], o[[k]], atol = 1e-12, rtol = 1e-12, info = paste(m, k, i))
      expect_identical(f$pass[i], o$pass_fail == "PASS")
      expect_identical(f$ref_scaled[i], o$criterion == "Reference-scaled")
    }
  }
})

test_that("TC-F3 ema_ci_fast methods a, b, c equal hand-computed values", {
  # l = 2, n = 2, m = 1. T: batch 1 (0.1, 0.3), batch 2 (0.2, 0.6); mean 0.3
  #                      R: batch 1 (0.0, 0.2), batch 2 (0.4, 0.2); mean 0.2
  XT <- array(c(0.1, 0.3, 0.2, 0.6), c(1, 4, 1))
  XR <- array(c(0.0, 0.2, 0.4, 0.2), c(1, 4, 1))
  e <- ema_ci_fast(XT, XR, 2, 2, 2, 2)
  # (a) var T = (0.14/3)/4, var R = (0.08/3)/4, df 3 and 3
  vT <- 0.14 / 12; vR <- 0.08 / 12
  dfa <- (vT + vR)^2 / (vT^2 / 3 + vR^2 / 3)
  expect_close(e$a$se, sqrt(vT + vR), atol = 1e-12, rtol = 1e-12)
  expect_close(e$a$df, dfa, atol = 1e-12, rtol = 1e-12)
  expect_close(e$a$lower, exp(0.1 - qt(0.95, dfa) * sqrt(vT + vR)), atol = 1e-12, rtol = 1e-12)
  # (b) batch means T (0.2, 0.4), R (0.1, 0.3): var 0.02 / 2 each, df 1
  expect_close(e$b$se, sqrt(0.02), atol = 1e-12, rtol = 1e-12)
  expect_close(e$b$df, 2, atol = 1e-12, rtol = 1e-12)
  # (c) T: MS_lot 0.04 < MS_unit 0.05 -> pooled (0.04 + 2 * 0.05) / 3 = (a), df 3
  #     R: MS_lot 0.04 >= MS_unit 0.02 -> batch means (b), df 1
  vRb <- 0.01
  expect_close(e$c$se, sqrt(vT + vRb), atol = 1e-12, rtol = 1e-12)
  expect_close(e$c$df, (vT + vRb)^2 / (vT^2 / 3 + vRb^2 / 1), atol = 1e-12, rtol = 1e-12)
  expect_close(e$a$gmr, exp(0.1), atol = 1e-12, rtol = 1e-12)
})

test_that("TC-F4 method c equals numerical REML (base R) including boundary cases", {
  reml_var <- function(X, l, n) {
    m <- dim(X)[3]; g <- expand.grid(u = seq_len(l * n), s = seq_len(m))
    y <- X[cbind(1, g$u, g$s)]
    S <- factor(g$s)
    Xf <- if (m > 1) model.matrix(~ S, contrasts.arg = list(S = "contr.sum")) else matrix(1, length(y))
    ZL <- outer((g$u - 1) %/% n, seq_len(l) - 1, "==") * 1
    ZC <- outer(g$u, seq_len(l * n), "==") * 1
    JL <- ZL %*% t(ZL); JC <- ZC %*% t(ZC); I <- diag(length(y))
    nll <- function(th) {
      v <- exp(th); V <- v[1] * JL + v[2] * JC + v[3] * I
      Rc <- chol(V); Vi <- chol2inv(Rc); A <- t(Xf) %*% Vi %*% Xf
      r <- y - Xf %*% solve(A, t(Xf) %*% Vi %*% y)
      0.5 * (2 * sum(log(diag(Rc))) + as.numeric(determinant(A)$modulus) + sum(r * (Vi %*% r)))
    }
    best <- NULL
    for (s0 in list(c(-5, -5, -5), c(-25, -5, -5), c(-5, -25, -5), c(-25, -25, -5))) {
      o <- optim(s0, nll, method = "L-BFGS-B", lower = -30, upper = 2,
                 control = list(factr = 1, maxit = 2000))
      if (is.null(best) || o$value < best$value) best <- o
    }
    v <- exp(best$par); V <- v[1] * JL + v[2] * JC + v[3] * I
    solve(t(Xf) %*% solve(V) %*% Xf)[1, 1]
  }
  set.seed(7)
  cases <- list(c(0.05, 0.04), c(0, 0.04), c(0, 0), c(0.03, 0))   # (sB, sC), sW = 0.05
  seen_pool <- FALSE; seen_b <- FALSE
  for (m in c(1, 3)) for (cs in cases) {
    X <- invitro_gen(1, 3, 4, m, sB = cs[1], sC = cs[2], sW = 0.05)
    s <- CNKfarmastatr:::.iv_stats(X, 3, 4); s$msw_resid <- CNKfarmastatr:::.iv_msw_resid(X)
    vc <- CNKfarmastatr:::.iv_var_mean(s, "c"); vb <- CNKfarmastatr:::.iv_var_mean(s, "b")
    if (vc$df > 2) seen_pool <- TRUE else seen_b <- TRUE
    expect_close(vc$v, reml_var(X, 3, 4), atol = 1e-10, rtol = 1e-5, info = paste(m, cs))
    if (vc$df == 2) expect_close(vc$v, vb$v, atol = 1e-12, rtol = 1e-12)
  }
  expect_true(seen_pool && seen_b)
})

test_that("TC-F5 invitro_gen is reproducible and has the intended structure", {
  set.seed(1); a <- invitro_gen(3, 2, 4, 3, mu = 1, sB = 0.1, sC = 0.2, sW = 0.3, tau = c(-0.1, 0, 0.1))
  set.seed(1); b <- invitro_gen(3, 2, 4, 3, mu = 1, sB = 0.1, sC = 0.2, sW = 0.3, tau = c(-0.1, 0, 0.1))
  expect_identical(a, b)
  expect_equal(dim(a), c(3, 8, 3), tolerance = 0)
  # sW = 0 and no drift: every unit is constant across stages
  z <- invitro_gen(2, 2, 3, 3, sB = 0.1, sC = 0.2)
  expect_equal(z[, , 1], z[, , 3], tolerance = 0)
  # sC = sW = 0: units within a batch are identical
  y <- invitro_gen(2, 2, 3, 1, sB = 0.1)
  expect_equal(y[, 1, 1], y[, 3, 1], tolerance = 0)
  expect_false(isTRUE(all.equal(y[, 1, 1], y[, 4, 1])))
  # common random numbers: a zero component still consumes its draws
  set.seed(9); u0 <- invitro_gen(4, 3, 2, 2, sB = 0,   sC = 0.2, sW = 0.1)
  set.seed(9); u1 <- invitro_gen(4, 3, 2, 2, sB = 0.3, sC = 0.2, sW = 0.1)
  w0 <- u0[, 2, ] - u0[, 1, ]; w1 <- u1[, 2, ] - u1[, 1, ]   # batch effect cancels
  expect_close(w0, w1, atol = 1e-14, rtol = 1e-14)
})

test_that("TC-F6 shares and drift reproduce the total variance", {
  cp <- invitro_components(0.12, pB = 0.2, pL = 0.3, q = 0.25)
  tau <- invitro_drift(3, cp$drift_var)
  expect_close(sum(tau), 0, atol = 1e-15, rtol = 1e-15)
  expect_close(mean(tau^2), cp$drift_var, atol = 1e-12, rtol = 1e-12)
  expect_close(cp$sB^2 + cp$sC^2 + cp$sW^2 + mean(tau^2), 0.12^2, atol = 1e-12, rtol = 1e-12)
  expect_error(invitro_components(0.1, 0.7, 0.5))
})

test_that("TC-F7 invitro_delta0 puts eta at 0; invitro_scenario is reproducible", {
  th <- ((log(1.11))^2 + 0.01) / 0.01
  expect_close(invitro_delta0(0.12), sqrt(th) * 0.12, atol = 1e-12, rtol = 1e-12)
  expect_close(invitro_delta0(0.05), sqrt(th) * 0.1, atol = 1e-12, rtol = 1e-12)   # constant-scaled
  a <- invitro_scenario(0.12, delta = invitro_delta0(0.12), n_sim = 300)
  b <- invitro_scenario(0.12, delta = invitro_delta0(0.12), n_sim = 300)
  expect_identical(a, b)
  expect_close(a$eta, 0, atol = 1e-15, rtol = 1e-15)
  # common random numbers: delta shifts only the T mean, variances are identical
  z <- invitro_scenario(0.12, delta = 0, n_sim = 300)
  expect_close(z$fda_bias_s2R, a$fda_bias_s2R, atol = 1e-15, rtol = 1e-15)
  expect_close(z$ema_b_cover, a$ema_b_cover, atol = 1e-15, rtol = 1e-15)
})

test_that("TC-F8 paired Monte Carlo SEs, REML boundary share and keep_reps (v0.2.0)", {
  a <- invitro_scenario(0.12, pB = 0.1, l = 3, n = 5, delta = log(1.05), n_sim = 400,
                        keep_reps = TRUE)
  r <- attr(a, "reps")
  expect_equal(nrow(r), 400, tolerance = 0)
  expect_close(a$fda_pass, mean(r$fda), atol = 1e-12, rtol = 1e-12); expect_close(a$ema_c_pass, mean(r$ema_c), atol = 1e-12, rtol = 1e-12)
  D <- as.numeric(r$fda) - as.numeric(r$ema_c)
  expect_close(a$diff_fda_ema_c, mean(D), atol = 1e-15, rtol = 1e-15)
  expect_close(a$diff_fda_ema_c_mcse, sd(D) / sqrt(400), atol = 1e-15, rtol = 1e-15)
  expect_close(a$ema_c_pooled_T, mean(r$ema_c_pooled_T), atol = 1e-12, rtol = 1e-12)
  expect_true(a$ema_c_pooled_R > 0 && a$ema_c_pooled_R < 1)
  # keep_reps does not change any result
  b <- invitro_scenario(0.12, pB = 0.1, l = 3, n = 5, delta = log(1.05), n_sim = 400)
  attr(a, "reps") <- NULL
  expect_identical(a, b)
  # pooling indicator agrees with the REML degrees of freedom
  set.seed(20261015, kind = "Mersenne-Twister", normal.kind = "Inversion")
  cp <- invitro_components(0.12, 0.1, 0.15)
  XT <- invitro_gen(400, 3, 5, 3, mu = log(1.05), sB = cp$sB, sC = cp$sC, sW = cp$sW)
  s <- CNKfarmastatr:::.iv_stats(XT, 3, 5); s$msw_resid <- CNKfarmastatr:::.iv_msw_resid(XT)
  expect_close(mean(CNKfarmastatr:::.iv_var_mean(s, "c")$df != 2), a$ema_c_pooled_T, atol = 1e-12, rtol = 1e-12)
  expect_error(invitro_scenario(0.12, m = 1, q = 0.5, n_sim = 10))
})

test_that("TC-F9 end-to-end flow (generation -> calc_pbe decision) for m = 1 and q > 0", {
  flow <- function(m, q, pB, n_sim = 40) {
    seed <- 20261015; l <- 3; n <- 10; sR <- 0.12; d <- invitro_delta0(sR)
    sc <- invitro_scenario(sR, pB = pB, pL = 0.15, q = q, l = l, n = n, m = m, delta = d,
                           n_sim = n_sim, seed = seed, keep_reps = TRUE)
    set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion")
    cp <- invitro_components(sR, pB, 0.15, q)
    XT <- invitro_gen(n_sim, l, n, m, mu = d, sB = cp$sB, sC = cp$sC, sW = cp$sW,
                      tau = invitro_drift(m, cp$drift_var))
    XR <- invitro_gen(n_sim, l, n, m, mu = 0, sB = cp$sB, sC = cp$sC, sW = cp$sW,
                      tau = invitro_drift(m, cp$drift_var))
    ref <- vapply(seq_len(n_sim), function(i)
      calc_pbe(rbind(to_long(XT, i, l, n, "TEST"), to_long(XR, i, l, n, "REF")))$pass_fail == "PASS",
      logical(1))
    expect_identical(attr(sc, "reps")$fda, ref, info = paste(m, q, pB))
    expect_close(sc$eta, 0, atol = 1e-15, rtol = 1e-15)
  }
  flow(m = 1, q = 0,   pB = 0.3)
  flow(m = 2, q = 0.5, pB = 0.3)
  flow(m = 3, q = 0.5, pB = 0)
})

test_that("TC-F10 expected mean squares (TN Eq. 12-15) incl. drift and m = 1", {
  # Monte Carlo check with the package generator; FarmaStatR derivation, TN 8.5
  chk <- function(m, pB, q, R = 4000, l = 3, n = 10, sig = 0.12, pL = 0.15) {
    cp <- invitro_components(sig, pB, pL, q); tau <- invitro_drift(m, cp$drift_var)
    set.seed(20261016 + m)
    X <- invitro_gen(R, l, n, m, sB = cp$sB, sC = cp$sC, sW = cp$sW, tau = tau)
    s <- CNKfarmastatr:::.iv_stats(X, l, n)
    s2hat <- s$msb / m + (m - 1) * s$msw / m
    sB2 <- cp$sB^2; sC2 <- cp$sC^2; sW2 <- cp$sW^2; st2 <- sum(tau^2)
    f <- c(msb = m * sC2 + sW2 + m * n * (l - 1) / (n * l - 1) * sB2,
           msw = if (m > 1) sW2 + st2 / (m - 1) else 0,
           s2  = sC2 + sW2 + st2 / m + n * (l - 1) / (n * l - 1) * sB2,
           vm  = sB2 / l + sC2 / (n * l) + sW2 / (n * l * m))
    sim <- c(mean(s$msb), mean(s$msw), mean(s2hat), var(s$g))
    se  <- c(sd(s$msb), sd(s$msw), sd(s2hat), 0) / sqrt(R); se[4] <- var(s$g) * sqrt(2 / (R - 1))
    z <- ifelse(se > 0, (sim - f) / se, 0)
    expect_true(all(abs(z) < 4), info = paste(m, pB, q, paste(round(z, 2), collapse = " ")))
    # with pB = 0 the PSG estimator is unbiased for the marginal total variance
    if (pB == 0) expect_close(unname(f["s2"]), sig^2, atol = 1e-12, rtol = 1e-12)
  }
  chk(m = 3, pB = 0.3, q = 0.5); chk(m = 3, pB = 0, q = 0.5)
  chk(m = 2, pB = 0.1, q = 0.5); chk(m = 1, pB = 0.3, q = 0)
})

test_that("TC-F11 EMA (c): REML objective, constraints, 90% CI and decision vs numerical REML", {
  # FSR-VAL-SIM-1 v0.2 (KK-41): beyond the variance of the mean (TC-F4), check
  # (i) the engine's closed form against an independent PAVA implementation,
  # (ii) non-negative variance components, (iii) the REML criterion at the closed
  # form is not worse than the numerical optimum, (iv) 90% CI limits and the EMA
  # decision (0.85-1.18) agree with those from numerical REML; decisions with a
  # limit within a relative 1e-5 of 0.85 or 1.18 are flagged, not compared.
  set.seed(11); l <- 3; n <- 6
  cases <- list(c(0.03, 0.02, 0.02), c(0, 0.02, 0.02), c(0, 0, 0.03), c(0.02, 0, 0.02))
  flagged <- 0; seen <- c(pass = FALSE, fail = FALSE)
  for (m in c(1, 3)) for (cs in cases) for (mu in log(c(1.00, 1.10, 1.15))) {
    XT <- invitro_gen(1, l, n, m, mu = mu, sB = cs[1], sC = cs[2], sW = cs[3])
    XR <- invitro_gen(1, l, n, m, sB = cs[1], sC = cs[2], sW = cs[3])
    MT <- matrix(XT[1, , ], l * n, m); MR <- matrix(XR[1, , ], l * n, m)
    cl <- list(T = reml_closed(MT, l, n), R = reml_closed(MR, l, n))
    nu <- list(T = reml_numeric(MT, l, n), R = reml_numeric(MR, l, n))
    for (p in c("T", "R")) {
      X <- if (p == "T") XT else XR; M <- if (p == "T") MT else MR
      s <- CNKfarmastatr:::.iv_stats(X, l, n); s$msw_resid <- CNKfarmastatr:::.iv_msw_resid(X)
      e <- CNKfarmastatr:::.iv_var_mean(s, "c")
      expect_close(e$v, cl[[p]]$v_mean, info = paste(m, p))                       # (i)
      expect_equal(e$df, cl[[p]]$df, tolerance = 0)
      expect_true(all(cl[[p]]$comp >= 0))                                           # (ii)
      expect_true(reml_nll(cl[[p]]$comp, M, l, n) <= nu[[p]]$nll + 1e-8)            # (iii)
    }
    ci <- ema_ci_fast(XT, XR, l, n, l, n, methods = "c")$c                          # (iv)
    ci_num <- ci_from_var(mean(MT) - mean(MR), nu$T$v_mean, nu$R$v_mean, cl$T$df, cl$R$df)
    expect_close(c(ci$lower, ci$upper), ci_num, atol = 1e-10, rtol = 1e-5)
    near <- any(abs(c(ci$lower, ci$upper) - c(0.85, 1.18)) <= 1e-5 * c(0.85, 1.18))
    if (near) flagged <- flagged + 1
    else expect_identical(ci$pass, unname(ci_num[1] >= 0.85 && ci_num[2] <= 1.18))
    seen[if (ci$pass) "pass" else "fail"] <- TRUE
  }
  expect_true(all(seen))     # both decisions occur among the 24 data-set pairs
  expect_equal(flagged, 0, tolerance = 0)
  # (v) the flagging rule itself (FSR-VAL-SIM-1 v0.3): one pair shifted so that the
  #     upper limit lies inside 1.18 by a relative 3e-6. A shift of the T data moves
  #     the mean difference only; variances, df and the CI width are unchanged.
  XT <- invitro_gen(1, l, n, 3, mu = log(1.10), sB = 0.03, sC = 0.02, sW = 0.02)
  XR <- invitro_gen(1, l, n, 3, sB = 0.03, sC = 0.02, sW = 0.02)
  up0 <- ema_ci_fast(XT, XR, l, n, l, n, methods = "c")$c$upper
  XT <- XT + log(1.18 * (1 - 3e-6)) - log(up0)
  ci <- ema_ci_fast(XT, XR, l, n, l, n, methods = "c")$c
  MT <- matrix(XT[1, , ], l * n, 3); MR <- matrix(XR[1, , ], l * n, 3)
  ci_num <- ci_from_var(mean(MT) - mean(MR), reml_numeric(MT, l, n)$v_mean, reml_numeric(MR, l, n)$v_mean,
                        reml_closed(MT, l, n)$df, reml_closed(MR, l, n)$df)
  expect_close(ci$upper, 1.18 * (1 - 3e-6), atol = 1e-12, rtol = 1e-12)
  expect_true(ci$pass)                                                   # inside 1.18
  expect_true(any(abs(c(ci$lower, ci$upper) - c(0.85, 1.18)) <= 1e-5 * c(0.85, 1.18)))   # flagged
  expect_close(c(ci$lower, ci$upper), ci_num, atol = 1e-10, rtol = 1e-5)  # limits still agree
})
