# =============================================================================
# A-16 review, item K-8 (FSR-LOG-01 G-111): Sathe, Tsong, Shah (1996) Pharm Res 13:1799-1803,
#   Appendix, similarity region SR = K'(dmu)'(S1 + S2/sqrt(N))^{-1}(dmu) <= F(P, 2N-P-1, .99)
#   (read from the scanned page; the paper prints sqrt(N)). Platform core: divisor N (default) or sqrtN.
# Question: under the paper's own model y_ij = mu + A_i + E_ij, A ~ MVN(0, S1), E ~ MVN(0, S2),
#   which divisor makes SR a 99% region for the difference of two batch means?
#   Cov(batch mean) = S1 + S2/N: Casella and Berger (2002) Theorem 5.2.6(b) applied to a'E_ij.
# Finding: neither. K' (p. 1801) already carries N/2, so the calibrated matrix is N*S1 + S2.
#   "platform_S1hat" approximates the core, whose S1 estimate (covariance of lot means) has
#   expectation S1 + S2/N; it uses that expectation, not finite-sample estimates.
# Research and education only; not a system validated for GxP environments.
# =============================================================================
set.seed(20261030)
P <- 2; N <- 12; nsim <- 2e5
S1 <- matrix(c(0.004, 0.001, 0.001, 0.002), 2)   # between-batch (A)
S2 <- matrix(c(0.020, 0.004, 0.004, 0.003), 2)   # within-batch (E)
Kp <- ((2*N - P - 1) / ((2*N - 2) * P)) * (N*N / (2*N))
Fq <- qf(0.99, P, 2*N - P - 1)
rmvn <- function(n, S) matrix(rnorm(n * ncol(S)), n) %*% chol(S)
# exact distribution of a batch mean: A + mean(E) -> cov S1 + S2/N (Casella-Berger Thm 5.2.6(b) on a'E)
d <- rmvn(nsim, S1) + rmvn(nsim, S2 / N) - (rmvn(nsim, S1) + rmvn(nsim, S2 / N))
cat("empirical cov(d) / [2(S1 + S2/N)]:\n"); print(round(cov(d) / (2 * (S1 + S2 / N)), 3))
cov_rate <- function(Q) mean(Kp * rowSums((d %*% solve(Q)) * d) <= Fq)
cat(sprintf("\ncoverage of SR (target 0.99), true S1, S2:\n  c = N     : %.4f\n  c = sqrt(N): %.4f\n",
            cov_rate(S1 + S2 / N), cov_rate(S1 + S2 / sqrt(N))))
cat(sprintf("  calibrated reference, Q = N*S1 + S2 (= N(S1 + S2/N)): %.4f\n", cov_rate(N * S1 + S2)))
# Within-batch only (S1 = 0): does K' with Q = S2 give 99%? (two-sample Hotelling check)
d0 <- rmvn(nsim, S2 / N) - rmvn(nsim, S2 / N)
cat(sprintf("  S1 = 0, Q = S2 (Hotelling form): %.4f\n", mean(Kp * rowSums((d0 %*% solve(S2)) * d0) <= Fq)))

# --- other designs and variance ratios ---
set.seed(7)
rmvn <- function(n, S) matrix(rnorm(n * ncol(S)), n) %*% chol(S)
run <- function(N, S1, S2, nsim = 2e5, P = 2) {
  Kp <- ((2*N - P - 1) / ((2*N - 2) * P)) * (N*N / (2*N)); Fq <- qf(0.99, P, 2*N - P - 1)
  d <- rmvn(nsim, S1) + rmvn(nsim, S2 / N) - (rmvn(nsim, S1) + rmvn(nsim, S2 / N))
  f <- function(Q) mean(Kp * rowSums((d %*% solve(Q)) * d) <= Fq)
  c(N = N, c_N = f(S1 + S2/N), c_sqrtN = f(S1 + S2/sqrt(N)), platform_S1hat = f(S1 + 2*S2/N), kalibre = f(N*S1 + S2))
}
A <- matrix(c(0.004, 0.001, 0.001, 0.002), 2); B <- matrix(c(0.020, 0.004, 0.004, 0.003), 2)
print(round(rbind(run(6, A, B), run(12, A, B), run(12, A/10, B), run(12, 10*A, B)), 4))
