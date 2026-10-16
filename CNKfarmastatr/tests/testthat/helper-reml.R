# Independent REML tools for TC-F11 and the FSR-VAL-SIM-1 evidence script.
# Model for one product (balanced): X_ijs = mu + tau_s (fixed) + b_j + c_ij + e_ijs.
# Written from the model, not from invitro_fast.R:
#   ms_strata()   : mean squares of the three strata from the raw array
#   pava_down()   : weighted pool-adjacent-violators for a decreasing order
#   reml_closed() : REML estimates as the isotonic regression of the strata
#                   mean squares (Searle et al. 2006 Sec. 3.8, Eq. 146, extended
#                   to three strata; FarmaStatR derivation)
#   reml_nll()    : REML criterion (-log restricted likelihood, up to a constant)
#   reml_numeric(): numerical REML (L-BFGS-B, four starting points)

ms_strata <- function(X, l, n) {            # X: N x m matrix, units batch by batch
  N <- l * n; m <- ncol(X)
  U <- rowMeans(X); B <- tapply(U, rep(seq_len(l), each = n), mean); g <- mean(U)
  ms_lot <- n * m * sum((B - g)^2) / (l - 1)
  ms_unit <- m * sum((U - rep(B, each = n))^2) / (l * (n - 1))
  ms_res <- if (m > 1) {
    S <- colMeans(X); sum((X - U - rep(S, each = N) + g)^2) / ((N - 1) * (m - 1))
  } else NA_real_
  list(ms = c(ms_lot, ms_unit, ms_res), df = c(l - 1, l * (n - 1), (N - 1) * (m - 1)))
}

pava_down <- function(y, w) {               # fitted values non-increasing
  blocks <- lapply(seq_along(y), function(i) list(v = y[i], w = w[i], k = 1L))
  i <- 1
  while (i < length(blocks)) {
    if (blocks[[i]]$v < blocks[[i + 1]]$v) {
      a <- blocks[[i]]; b <- blocks[[i + 1]]
      blocks[[i]] <- list(v = (a$w * a$v + b$w * b$v) / (a$w + b$w), w = a$w + b$w, k = a$k + b$k)
      blocks[[i + 1]] <- NULL
      i <- max(1, i - 1)
    } else i <- i + 1
  }
  list(fit = unlist(lapply(blocks, function(b) rep(b$v, b$k))),
       first_df = blocks[[1]]$w)
}

reml_closed <- function(X, l, n) {
  m <- ncol(X); s <- ms_strata(X, l, n); k <- if (m > 1) 3 else 2
  p <- pava_down(s$ms[1:k], s$df[1:k]); th <- p$fit
  comp <- if (m > 1) c(sB2 = (th[1] - th[2]) / (n * m), sC2 = (th[2] - th[3]) / m, sW2 = th[3])
          else c(sB2 = (th[1] - th[2]) / n, sC2 = 0, sW2 = th[2])
  list(comp = comp, v_mean = th[1] / (l * n * m), df = p$first_df)
}

.reml_design <- function(l, n, m) {
  g <- expand.grid(u = seq_len(l * n), s = seq_len(m)); S <- factor(g$s)
  Xf <- if (m > 1) model.matrix(~ S, contrasts.arg = list(S = "contr.sum")) else matrix(1, nrow(g))
  ZL <- outer((g$u - 1) %/% n, seq_len(l) - 1, "==") * 1
  ZC <- outer(g$u, seq_len(l * n), "==") * 1
  list(g = g, Xf = Xf, JL = ZL %*% t(ZL), JC = ZC %*% t(ZC), I = diag(nrow(g)))
}

reml_nll <- function(v, X, l, n, d = .reml_design(l, n, ncol(X))) {   # v = (sB2, sC2, sW2)
  y <- X[cbind(d$g$u, d$g$s)]
  V <- v[1] * d$JL + v[2] * d$JC + v[3] * d$I
  Rc <- chol(V); Vi <- chol2inv(Rc); A <- t(d$Xf) %*% Vi %*% d$Xf
  r <- y - d$Xf %*% solve(A, t(d$Xf) %*% Vi %*% y)
  0.5 * (2 * sum(log(diag(Rc))) + as.numeric(determinant(A)$modulus) + sum(r * (Vi %*% r)))
}

reml_numeric <- function(X, l, n) {
  m <- ncol(X); best <- NULL; d <- .reml_design(l, n, m)
  f <- function(th) reml_nll(exp(th), X, l, n, d)
  for (s0 in list(c(-5, -5, -5), c(-25, -5, -5), c(-5, -25, -5), c(-25, -25, -5))) {
    o <- optim(s0, f, method = "L-BFGS-B", lower = -30, upper = 2, control = list(factr = 1, maxit = 2000))
    if (is.null(best) || o$value < best$value) best <- o
  }
  v <- exp(best$par)
  V <- v[1] * d$JL + v[2] * d$JC + v[3] * d$I
  list(comp = v, nll = best$value, v_mean = solve(t(d$Xf) %*% solve(V) %*% d$Xf)[1, 1])
}

# 90% CI of exp(mu_T - mu_R) from two variances of the mean and their df (Welch-Satterthwaite)
ci_from_var <- function(d, vT, vR, dfT, dfR, level = 0.90) {
  se <- sqrt(vT + vR); df <- (vT + vR)^2 / (vT^2 / dfT + vR^2 / dfR)
  q <- stats::qt(1 - (1 - level) / 2, df)
  c(lower = exp(d - q * se), upper = exp(d + q * se))
}
