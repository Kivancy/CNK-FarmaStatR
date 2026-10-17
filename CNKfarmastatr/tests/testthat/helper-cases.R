# Test-case data shared by the tests and the FSR-VAL-SIM-1 evidence script
# (belgeler/validasyon/FSR-VAL-SIM-1_ek/kanit.R), so that both always use the
# same data sets (session review G-49, point 7). Each function sets its own seed;
# the order of the draws is the order used by the tests since v0.1 / v0.3.

# Long format (calc_pbe input) from simulated arrays; compared PBE quantities
to_long <- function(X, r, l, n, prod) {
  N <- l * n; m <- dim(X)[3]
  g <- expand.grid(u = seq_len(N), s = seq_len(m))
  data.frame(Batches = paste0(prod, (g$u - 1) %/% n + 1), Container = paste0("c", g$u),
             Stage = g$s, Product = prod, score = X[cbind(r, g$u, g$s)])
}
pbe_cols <- c("msb_t", "msw_t", "msb_r", "msw_r", "Eq_Ref", "Uq_Ref", "H_eta_Ref",
              "Eq_Const", "Uq_Const", "H_eta_Const")

# TC-F2: pbe_fast vs calc_pbe; m = 1, 2, 3; designs 3x10/3x10 and 4x7/2x5; 8 data sets each
cases_tcf2 <- function() {
  set.seed(20261015)
  out <- list()
  for (m in 1:3) for (cfg in list(c(3, 10, 3, 10), c(4, 7, 2, 5))) {
    lT <- cfg[1]; nT <- cfg[2]; lR <- cfg[3]; nR <- cfg[4]
    XT <- invitro_gen(8, lT, nT, m, mu = 0.05, sB = 0.05, sC = 0.08, sW = 0.04,
                      tau = invitro_drift(m, 0.0005))
    XR <- invitro_gen(8, lR, nR, m, sB = if (m > 1) 0.12 else 0.02, sC = 0.06, sW = 0.03)
    out[[length(out) + 1]] <- list(m = m, lT = lT, nT = nT, lR = lR, nR = nR, XT = XT, XR = XR)
  }
  out
}

# TC-F11: 24 pairs (m = 1, 3; four variance cases; GMR 1.00, 1.10, 1.15), design 3 x 6,
# and one pair shifted so that the upper EMA (c) limit is 1.18 (1 - 3e-6)
cases_tcf11 <- function() {
  set.seed(11); l <- 3; n <- 6
  vc <- list(c(0.03, 0.02, 0.02), c(0, 0.02, 0.02), c(0, 0, 0.03), c(0.02, 0, 0.02))
  pairs <- list()
  for (m in c(1, 3)) for (cs in vc) for (mu in log(c(1.00, 1.10, 1.15))) {
    XT <- invitro_gen(1, l, n, m, mu = mu, sB = cs[1], sC = cs[2], sW = cs[3])
    XR <- invitro_gen(1, l, n, m, sB = cs[1], sC = cs[2], sW = cs[3])
    pairs[[length(pairs) + 1]] <- list(m = m, XT = XT, XR = XR)
  }
  XT <- invitro_gen(1, l, n, 3, mu = log(1.10), sB = 0.03, sC = 0.02, sW = 0.02)
  XR <- invitro_gen(1, l, n, 3, sB = 0.03, sC = 0.02, sW = 0.02)
  up0 <- ema_ci_fast(XT, XR, l, n, l, n, methods = "c")$c$upper
  XT <- XT + log(1.18 * (1 - 3e-6)) - log(up0)   # shift moves the mean difference only
  list(l = l, n = n, pairs = pairs, near = list(m = 3, XT = XT, XR = XR))
}

# TC-S5: the four Monte Carlo comparisons of the reference scenario (estimate, truth, MCSE, z)
mc_tcs5 <- function() {
  r <- sim_run("demo_mean_ci", params = list(n = 10L), n_sim = 4000, seed = 2026)
  pf <- r$performance
  ck <- list(c("t", "coverage", 0.95), c("z", "coverage", 2 * stats::pt(stats::qnorm(0.975), 9) - 1),
             c("t", "rejection", 0.05), c("t", "bias", 0))
  out <- do.call(rbind, lapply(ck, function(k) {
    row <- pf[pf$method == k[1] & pf$measure == k[2], ]
    data.frame(test = "TC-S5", item = paste(k[1], k[2]), estimate = row$estimate,
               truth = as.numeric(k[3]), mcse = row$mcse,
               z = (row$estimate - as.numeric(k[3])) / row$mcse)
  }))
  attr(out, "performance") <- pf
  out
}

# TC-F10: expected mean squares (TN Eq. 12-15) by Monte Carlo; returns estimate, formula, MCSE, z
mc_tcf10 <- function(m, pB, q, R = 4000, l = 3, n = 10, sig = 0.12, pL = 0.15) {
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
  sim <- c(mean(s$msb), mean(s$msw), mean(s2hat), stats::var(s$g))
  se  <- c(stats::sd(s$msb), stats::sd(s$msw), stats::sd(s2hat), 0) / sqrt(R)
  se[4] <- stats::var(s$g) * sqrt(2 / (R - 1))
  data.frame(test = "TC-F10", item = paste0(names(f), " (m ", m, ", pB ", pB, ", q ", q, ")"),
             estimate = sim, truth = unname(f), mcse = se,
             z = ifelse(se > 0, (sim - f) / se, 0), row.names = NULL)
}
