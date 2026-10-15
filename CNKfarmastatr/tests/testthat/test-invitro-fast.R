# In vitro simulation engine (invitro_fast.R): pbe_fast, ema_ci_fast, invitro_gen
# Test cases TC-F1 ... TC-F6. Reference for pbe_fast is the validated calc_pbe().

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
  expect_equal(c(t$l, t$n, t$m), c(3, 10, 3))
  f <- pbe_fast(t$X, r$X, t$l, t$n, r$l, r$n)
  o <- calc_pbe(d)
  for (k in pbe_cols) expect_equal(f[[k]], o[[k]], tolerance = 1e-12, info = k)
  expect_equal(f$sigma_r, o$Sigma_R, tolerance = 1e-12)
  expect_equal(f$H_eta, o$H_eta_final, tolerance = 1e-12)
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
      for (k in pbe_cols) expect_equal(f[[k]][i], o[[k]], tolerance = 1e-12,
                                       info = paste(m, k, i))
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
  expect_equal(e$a$se, sqrt(vT + vR), tolerance = 1e-12)
  expect_equal(e$a$df, dfa, tolerance = 1e-12)
  expect_equal(e$a$lower, exp(0.1 - qt(0.95, dfa) * sqrt(vT + vR)), tolerance = 1e-12)
  # (b) batch means T (0.2, 0.4), R (0.1, 0.3): var 0.02 / 2 each, df 1
  expect_equal(e$b$se, sqrt(0.02), tolerance = 1e-12)
  expect_equal(e$b$df, 2, tolerance = 1e-12)
  # (c) T: MS_lot 0.04 < MS_unit 0.05 -> pooled (0.04 + 2 * 0.05) / 3 = (a), df 3
  #     R: MS_lot 0.04 >= MS_unit 0.02 -> batch means (b), df 1
  vRb <- 0.01
  expect_equal(e$c$se, sqrt(vT + vRb), tolerance = 1e-12)
  expect_equal(e$c$df, (vT + vRb)^2 / (vT^2 / 3 + vRb^2 / 1), tolerance = 1e-12)
  expect_equal(e$a$gmr, exp(0.1), tolerance = 1e-12)
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
    expect_equal(vc$v, reml_var(X, 3, 4), tolerance = 1e-5, info = paste(m, cs))
    if (vc$df == 2) expect_equal(vc$v, vb$v, tolerance = 1e-12)
  }
  expect_true(seen_pool && seen_b)
})

test_that("TC-F5 invitro_gen is reproducible and has the intended structure", {
  set.seed(1); a <- invitro_gen(3, 2, 4, 3, mu = 1, sB = 0.1, sC = 0.2, sW = 0.3, tau = c(-0.1, 0, 0.1))
  set.seed(1); b <- invitro_gen(3, 2, 4, 3, mu = 1, sB = 0.1, sC = 0.2, sW = 0.3, tau = c(-0.1, 0, 0.1))
  expect_identical(a, b)
  expect_equal(dim(a), c(3, 8, 3))
  # sW = 0 and no drift: every unit is constant across stages
  z <- invitro_gen(2, 2, 3, 3, sB = 0.1, sC = 0.2)
  expect_equal(z[, , 1], z[, , 3], tolerance = 0)
  # sC = sW = 0: units within a batch are identical
  y <- invitro_gen(2, 2, 3, 1, sB = 0.1)
  expect_equal(y[, 1, 1], y[, 3, 1], tolerance = 0)
  expect_false(isTRUE(all.equal(y[, 1, 1], y[, 4, 1])))
})

test_that("TC-F6 shares and drift reproduce the total variance", {
  cp <- invitro_components(0.12, pB = 0.2, pL = 0.3, q = 0.25)
  tau <- invitro_drift(3, cp$drift_var)
  expect_equal(sum(tau), 0, tolerance = 1e-15)
  expect_equal(mean(tau^2), cp$drift_var, tolerance = 1e-12)
  expect_equal(cp$sB^2 + cp$sC^2 + cp$sW^2 + mean(tau^2), 0.12^2, tolerance = 1e-12)
  expect_error(invitro_components(0.1, 0.7, 0.5))
})
