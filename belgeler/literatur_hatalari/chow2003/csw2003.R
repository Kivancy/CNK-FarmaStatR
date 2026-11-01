# Chow, Shao and Wang (2003) Stat Med 22:55-68: in vitro BE test with replicates (Section 2)
# and its type I error simulation (Section 3, Table I), reproduced with the CNK-FarmaStatR
# data generator invitro_gen (one batch, sB = 0: model (5) of the paper).
# Literature check outside the platform (FSR-LOG-01 G-123); the platform's PBE uses the
# PSG 020929 criterion and constants, which differ (t quantile, theta_P, sigma_T0).
# Research and education only; not a system validated for GxP environments.

# eta-hat_U of Section 2 (n = 1 gives the FDA 1999 bound of model (2)).
# c in the 4th and 5th terms: printed only in the 5th (Section 2, p. 59); used in both here,
# as in the n = 1 bound (p. 57), so that the R terms match the scaling chosen.
csw_bound <- function(d, sBT, sBR, sWT, sWR, mT, mR, nT, nR, theta = 1.125, s0 = 0.2, a = 0.05) {
  sR2 <- sBR + (1 - 1/nR) * sWR
  cc  <- as.numeric(sR2 > s0^2)
  pe  <- d^2 + sBT + (1 - 1/nT) * sWT - sBR - (1 - 1/nR) * sWR - theta * pmax(s0^2, sR2)
  q   <- function(p, df) ifelse(df > 0, stats::qchisq(p, pmax(df, 1)), NA)
  u1 <- ((abs(d) + stats::qnorm(1 - a) * sqrt(sBT/mT + sBR/mR))^2 - d^2)^2
  u2 <- sBT^2 * ((mT - 1) / q(a, mT - 1) - 1)^2
  u3 <- if (nT > 1) (1 - 1/nT)^2 * sWT^2 * (mT*(nT-1) / q(a, mT*(nT-1)) - 1)^2 else 0
  u4 <- (1 + cc*theta)^2 * sBR^2 * ((mR - 1) / q(1 - a, mR - 1) - 1)^2
  u5 <- if (nR > 1) (1 + cc*theta)^2 * (1 - 1/nR)^2 * sWR^2 * (mR*(nR-1) / q(1 - a, mR*(nR-1)) - 1)^2 else 0
  U <- u1 + u2 + u3 + u4 + u5
  list(eta_U = pe + sqrt(U), U = U, pe = pe)
}

# statistics from an R x m x n array (canisters x replicates), per replication
csw_stats <- function(X) {   # X: R x N x n
  N <- dim(X)[2]; n <- dim(X)[3]
  cm <- rowMeans(X, dims = 2)                          # R x N canister means
  g  <- rowMeans(cm)
  sB <- rowSums((cm - g)^2) / (N - 1)
  sW <- if (n > 1) rowSums((X - as.vector(cm))^2) / (N * (n - 1)) else 0 * g   # cm recycled over replicates
  list(g = g, sB = sB, sW = sW)
}
