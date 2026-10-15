# =============================================================================
# CNK-FarmaStatR v1 - In vitro equivalence simulation engine (balanced designs)
#
# Purpose: fast, vectorised versions of the procedures studied in technical note
#   FSR-TN-PBE-01 v0.4 (decisions KK-34, KK-35), for use inside simulations.
#   - invitro_gen():  data-generating mechanism (TN Section 6, Eq. 8-9)
#   - pbe_fast():     FDA PSG 020929 PBE procedure; must equal calc_pbe() exactly
#   - ema_ci_fast():  90% CI of the T/R geometric mean ratio, three ways (TN 5.3)
#
# Data layout: one product is a numeric array X[r, u, s] with r = replicate
#   (simulated data set), u = unit (units ordered batch by batch: batch 1 units
#   1..n, batch 2 units 1..n, ...), s = life stage. Log scale.
#
# The validated core calc_pbe() is not changed; pbe_fast() is tested against it
#   (tests/testthat/test-invitro-fast.R). Base R only. Version 0.1.0
# =============================================================================

# -----------------------------------------------------------------------------
# invitro_gen(): simulate R data sets for one product
#   X_ijs = mu + b_j + c_ij + tau_s + e_ijs                   (TN Eq. 8)
#   b ~ N(0, sB^2), c ~ N(0, sC^2), e ~ N(0, sW^2); tau fixed, sum(tau) = 0
# Draw order (fixed, for reproducibility): all b, then all c, then all e,
#   each filled replicate-fastest (R x ...).
# -----------------------------------------------------------------------------
invitro_gen <- function(R, l, n, m, mu = 0, sB = 0, sC = 0, sW = 0,
                        tau = rep(0, m)) {
  stopifnot(length(tau) == m, R >= 1, l >= 1, n >= 1, m >= 1)
  N <- l * n
  b  <- matrix(stats::rnorm(R * l, 0, sB), R, l)
  cc <- matrix(stats::rnorm(R * N, 0, sC), R, N)
  e  <- array(stats::rnorm(R * N * m, 0, sW), c(R, N, m))
  unit_level <- mu + b[, rep(seq_len(l), each = n), drop = FALSE] + cc   # R x N
  X <- e + as.vector(unit_level)                       # recycles over stages
  X + rep(tau, each = R * N)
}

# Shares -> components (TN Eq. 9; decision KK-29)
invitro_components <- function(sigma, pB, pL, q = 0) {
  if (pB < 0 || pL < 0 || pB + pL > 1) stop("Shares must satisfy pB, pL >= 0, pB + pL <= 1.")
  v <- sigma^2
  vL <- pL * v
  list(sB = sqrt(pB * v), sC = sqrt((1 - pB - pL) * v),
       sW = sqrt((1 - q) * vL), drift_var = q * vL)
}

# Linear drift scaled so that (1/m) sum(tau^2) = drift_var (TN 6.1)
invitro_drift <- function(m, drift_var) {
  if (m < 2 || drift_var == 0) return(rep(0, m))
  t <- seq_len(m) - (m + 1) / 2
  t * sqrt(drift_var / mean(t^2))
}

# -----------------------------------------------------------------------------
# Internal: per-product summary statistics, vectorised over replicates
# -----------------------------------------------------------------------------
.iv_stats <- function(X, l, n) {
  d <- dim(X); R <- d[1]; N <- d[2]; m <- d[3]
  if (N != l * n) stop("dim(X)[2] must equal l * n.")
  U <- rowMeans(X, dims = 2)                             # R x N unit means
  g <- rowMeans(U)                                       # grand mean
  msb <- m * rowSums((U - g)^2) / (N - 1)
  msw <- if (m > 1) rowSums((X - as.vector(U))^2) / (N * (m - 1)) else rep(0, R)
  bidx <- rep(seq_len(l), each = n)
  Bm <- U %*% outer(bidx, seq_len(l), "==") / n          # R x l batch means
  list(R = R, N = N, m = m, l = l, n = n, U = U, g = g, msb = msb, msw = msw,
       Bm = Bm, bidx = bidx)
}

# -----------------------------------------------------------------------------
# pbe_fast(): FDA PSG 020929 PBE (Appendix Steps 1-5), vectorised.
# Identical formulas to calc_pbe() for balanced data; returns a data frame with
# one row per replicate.
# -----------------------------------------------------------------------------
pbe_fast <- function(XT, XR, lT, nT, lR, nR, alpha = 0.05, sigma_T0 = 0.1) {
  st <- .iv_stats(XT, lT, nT); sr <- .iv_stats(XR, lR, nR)
  if (st$m != sr$m) stop("T and R must have the same number of life stages.")
  m <- st$m; NT <- st$N; NR <- sr$N
  theta_p <- ((log(1.11))^2 + 0.01) / sigma_T0^2
  E_D <- (st$g - sr$g)^2
  E1  <- st$msb / m
  E2  <- if (m > 1) st$msw * (m - 1) / m else 0 * E1
  E3s <- -(1 + theta_p) * sr$msb / m
  E4s <- if (m > 1) -(1 + theta_p) * sr$msw * (m - 1) / m else 0 * E1
  E3c <- -sr$msb / m
  E4c <- if (m > 1) -sr$msw * (m - 1) / m else 0 * E1
  t_val <- stats::qt(1 - alpha, NT + NR - 2)
  H_D <- (sqrt(E_D) + t_val * sqrt(st$msb / (NT * m) + sr$msb / (NR * m)))^2
  H1  <- (NT - 1) * E1  / stats::qchisq(alpha,     NT - 1)
  H3s <- (NR - 1) * E3s / stats::qchisq(1 - alpha, NR - 1)
  H3c <- (NR - 1) * E3c / stats::qchisq(1 - alpha, NR - 1)
  if (m > 1) {
    H2  <- NT * (m - 1) * E2  / stats::qchisq(alpha,     NT * (m - 1))
    H4s <- NR * (m - 1) * E4s / stats::qchisq(1 - alpha, NR * (m - 1))
    H4c <- NR * (m - 1) * E4c / stats::qchisq(1 - alpha, NR * (m - 1))
  } else { H2 <- H4s <- H4c <- 0 * E1 }
  Uq_Ref   <- (H_D - E_D)^2 + (H1 - E1)^2 + (H2 - E2)^2 + (H3s - E3s)^2 + (H4s - E4s)^2
  Uq_Const <- (H_D - E_D)^2 + (H1 - E1)^2 + (H2 - E2)^2 + (H3c - E3c)^2 + (H4c - E4c)^2
  Eq_Ref   <- E_D + E1 + E2 + E3s + E4s
  Eq_Const <- E_D + E1 + E2 + E3c + E4c - theta_p * sigma_T0^2
  H_eta_Ref   <- Eq_Ref + sqrt(Uq_Ref)
  H_eta_Const <- Eq_Const + sqrt(Uq_Const)
  sigma_R <- sqrt(sr$msb / m + (m - 1) * sr$msw / m)
  sigma_T <- sqrt(st$msb / m + (m - 1) * st$msw / m)
  ref <- sigma_R > sigma_T0
  H_eta <- ifelse(ref, H_eta_Ref, H_eta_Const)
  data.frame(mean_t = st$g, mean_r = sr$g, msb_t = st$msb, msw_t = st$msw,
             msb_r = sr$msb, msw_r = sr$msw, sigma_t = sigma_T, sigma_r = sigma_R,
             Eq_Ref = Eq_Ref, Uq_Ref = Uq_Ref, H_eta_Ref = H_eta_Ref,
             Eq_Const = Eq_Const, Uq_Const = Uq_Const, H_eta_Const = H_eta_Const,
             ref_scaled = ref, H_eta = H_eta, pass = H_eta <= 0)
}

# -----------------------------------------------------------------------------
# Internal: variance of one product mean and its degrees of freedom
#   method "a": pooled units          var = s2_units / N,  df = N - 1
#   method "b": batch means           var = s2_batch / l,  df = l - 1
#   method "c": REML for X = mu + tau_s (fixed) + b_j + c_ij + e_ijs, balanced.
#     Three orthogonal strata with mean squares MS_lot (df l-1),
#     MS_unit(lot) (df l(n-1)), MS_resid (df (N-1)(m-1)); expected values
#     theta_lot >= theta_unit >= theta_resid. The REML estimates of the thetas
#     are the df-weighted isotonic regression (pool-adjacent-violators) of the
#     observed MS under this order (Searle, Casella & McCulloch 2006, Ch. 6;
#     closed form for balanced data). Var(mean) = theta_lot / (N m).
#     If no pooling: identical to "b" (TN A.7). df = sum of pooled strata df
#     (FarmaStatR derivation). m = 1: residual stratum absent.
# -----------------------------------------------------------------------------
.iv_var_mean <- function(s, method) {
  N <- s$N; l <- s$l; n <- s$n; m <- s$m
  s2u <- s$msb / m                                        # variance of unit means
  s2b <- rowSums((s$Bm - s$g)^2) / (l - 1)                # variance of batch means
  if (method == "a") return(list(v = s2u / N, df = rep(N - 1, length(s2u))))
  if (method == "b") return(list(v = s2b / l, df = rep(l - 1, length(s2b))))
  ms_lot  <- n * m * s2b
  ms_unit <- m * rowSums((s$U - s$Bm[, s$bidx, drop = FALSE])^2) / (l * (n - 1))
  d1 <- l - 1; d2 <- l * (n - 1); d3 <- (N - 1) * (m - 1)
  th <- ms_lot; df <- rep(d1, length(th))
  # violator lot < unit: pool lot and unit
  p12 <- (d1 * ms_lot + d2 * ms_unit) / (d1 + d2)
  if (m > 1) {
    ms_res <- s$msw_resid
    p23 <- (d2 * ms_unit + d3 * ms_res) / (d2 + d3)
    p123 <- (d1 * ms_lot + d2 * ms_unit + d3 * ms_res) / (d1 + d2 + d3)
    # PAVA on three blocks, ordered decreasing
    case_unit_ok <- ms_unit >= ms_res
    # unit >= resid: only lot/unit can violate
    k1 <- case_unit_ok & ms_lot < ms_unit
    k1b <- k1 & p12 < ms_res                         # then pool all three
    th[k1] <- p12[k1]; df[k1] <- d1 + d2
    th[k1b] <- p123[k1b]; df[k1b] <- d1 + d2 + d3
    # unit < resid: pool unit and resid first
    k2 <- !case_unit_ok
    k2a <- k2 & ms_lot >= p23                        # lot stays alone
    k2b <- k2 & ms_lot < p23                         # pool all three
    th[k2a] <- ms_lot[k2a]; df[k2a] <- d1
    th[k2b] <- p123[k2b]; df[k2b] <- d1 + d2 + d3
  } else {
    k1 <- ms_lot < ms_unit
    th[k1] <- p12[k1]; df[k1] <- d1 + d2
  }
  list(v = th / (N * m), df = df)
}

# -----------------------------------------------------------------------------
# ema_ci_fast(): EMA OIP Rev. 2 §5.1 criterion 8 rule applied to one log-normal
#   quantity: 90% CI of exp(mu_T - mu_R) within [lower, upper] (default 0.85, 1.18).
#   Returns, for each method, the CI and the pass indicator.
# -----------------------------------------------------------------------------
ema_ci_fast <- function(XT, XR, lT, nT, lR, nR, level = 0.90,
                        limits = c(0.85, 1.18), methods = c("a", "b", "c")) {
  st <- .iv_stats(XT, lT, nT); sr <- .iv_stats(XR, lR, nR)
  st$msw_resid <- .iv_msw_resid(XT); sr$msw_resid <- .iv_msw_resid(XR)
  d <- st$g - sr$g
  out <- list()
  for (me in methods) {
    a <- .iv_var_mean(st, me); b <- .iv_var_mean(sr, me)
    se <- sqrt(a$v + b$v)
    df <- (a$v + b$v)^2 / (a$v^2 / a$df + b$v^2 / b$df)   # Welch-Satterthwaite
    q <- stats::qt(1 - (1 - level) / 2, df)
    lo <- exp(d - q * se); hi <- exp(d + q * se)
    out[[me]] <- data.frame(method = me, gmr = exp(d), lower = lo, upper = hi,
                            se = se, df = df,
                            pass = lo >= limits[1] & hi <= limits[2])
  }
  out
}

# Within-unit residual mean square after removing fixed stage effects
#   (two-way unit x stage residual), df = (N - 1)(m - 1); m = 1 -> 0
.iv_msw_resid <- function(X) {
  d <- dim(X); R <- d[1]; N <- d[2]; m <- d[3]
  if (m < 2) return(rep(0, R))
  U <- rowMeans(X, dims = 2)
  S <- colMeans(aperm(X, c(2, 1, 3)))                     # R x m stage means
  g <- rowMeans(U)
  res <- X - as.vector(U) - rep(as.vector(S), each = N) + g
  rowSums(res^2) / ((N - 1) * (m - 1))
}

# -----------------------------------------------------------------------------
# invitro_array(): balanced long data (calc_pbe layout: Batches, Container,
#   Stage, Product, score) -> 1 x (l n) x m array for one product, units ordered
#   batch by batch. Stops if the design is not balanced or complete.
# -----------------------------------------------------------------------------
invitro_array <- function(df, product) {
  names(df) <- c("Batches", "Container", "Stage", "Product", "score")
  d <- df[df$Product == product, ]
  if (nrow(d) == 0) stop("No rows for product ", product, ".")
  d$unit <- paste(d$Batches, d$Container, sep = "\r")
  bt <- sort(unique(as.character(d$Batches))); st <- sort(unique(d$Stage))
  u_b <- unique(d[, c("unit", "Batches")])
  nb <- table(as.character(u_b$Batches))
  if (length(unique(as.vector(nb))) != 1) stop("Unbalanced: units per batch differ.")
  u_b <- u_b[order(match(as.character(u_b$Batches), bt), u_b$unit), ]
  if (nrow(d) != nrow(u_b) * length(st)) stop("Incomplete: each unit needs every stage once.")
  X <- array(NA_real_, c(1, nrow(u_b), length(st)))
  X[cbind(1, match(d$unit, u_b$unit), match(d$Stage, st))] <- as.numeric(d$score)
  if (anyNA(X)) stop("Incomplete: each unit needs every stage once.")
  list(X = X, l = length(bt), n = as.vector(nb)[1], m = length(st))
}
