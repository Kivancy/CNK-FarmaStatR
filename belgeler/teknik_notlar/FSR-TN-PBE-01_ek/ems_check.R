# FSR-TN-PBE-01 v0.1-v0.2, Section 7.6 / Appendix A: Monte Carlo check of the
# expected mean squares. Run: OUTCSV=ems_check.csv Rscript ems_check.R  (R >= 4.1)
# Expected mean squares of the batch and container(batch) lines: Searle SR,
#   Casella G, McCulloch CE. Variance Components. Wiley 2006, Table 4.10.
# Their pooling into the PSG MSB and the life-stage terms: FarmaStatR derivation.
# Monte Carlo check of the expected mean squares of the PSG estimator
# under the three-level model X = mu + b + c + tau + e (one product).
set.seed(20261014)
one <- function(l, n, m, sB, sC, sW, tau) {
  b <- rnorm(l, 0, sB)
  cc <- rnorm(n * l, 0, sC)
  X <- matrix(rep(b, each = n) + cc, n * l, m) +
       matrix(tau, n * l, m, byrow = TRUE) + matrix(rnorm(n * l * m, 0, sW), n * l, m)
  cm <- rowMeans(X); gm <- mean(cm)
  MSB <- m * sum((cm - gm)^2) / (n * l - 1)
  MSW <- if (m > 1) sum((X - cm)^2) / (n * l * (m - 1)) else 0
  c(MSB = MSB, MSW = MSW, s2 = MSB / m + (m - 1) * MSW / m, gm = gm,
    vD = MSB / (n * l * m))
}
cfg <- expand.grid(n = c(5, 10, 20), m = c(1, 2, 3), sB = c(0, 0.2), drift = c(FALSE, TRUE))
cfg <- cfg[!(cfg$m == 1 & cfg$drift), ]
l <- 3; sC <- 0.3; sW <- 0.05; R <- 20000
out <- do.call(rbind, lapply(seq_len(nrow(cfg)), function(k) {
  n <- cfg$n[k]; m <- cfg$m[k]; sB <- cfg$sB[k]
  tau <- if (cfg$drift[k]) { t <- seq(-0.03, 0.03, length.out = m); t - mean(t) } else rep(0, m)
  S <- replicate(R, one(l, n, m, sB, sC, sW, tau))
  st2 <- sum(tau^2)
  f <- c(MSB = m * sC^2 + sW^2 + m * n * (l - 1) / (n * l - 1) * sB^2,
         MSW = if (m > 1) sW^2 + st2 / (m - 1) else 0,
         s2  = sC^2 + sW^2 + st2 / m + n * (l - 1) / (n * l - 1) * sB^2,
         VarD_true = sB^2 / l + sC^2 / (n * l) + sW^2 / (n * l * m),
         VarD_psg  = (m * sC^2 + sW^2 + m * n * (l - 1) / (n * l - 1) * sB^2) / (n * l * m))
  sim <- c(MSB = mean(S["MSB", ]), MSW = mean(S["MSW", ]), s2 = mean(S["s2", ]),
           VarD_true = var(S["gm", ]), VarD_psg = mean(S["vD", ]))
  se <- c(sd(S["MSB", ]), sd(S["MSW", ]), sd(S["s2", ]),
          var(S["gm", ]) * sqrt(2 / (R - 1)), sd(S["vD", ])) / c(rep(sqrt(R), 3), 1, sqrt(R))
  z <- ifelse(se > 0, (sim - f) / se, 0)
  data.frame(n = n, m = m, sB = sB, drift = cfg$drift[k], quantity = names(f),
             formula = f, simulated = sim, mcse = se, z = round(z, 2), row.names = NULL)
}))
out$sigma2_total <- NA
print(out, digits = 5)
cat("\nmax |z| =", max(abs(out$z)), " over", nrow(out), "comparisons\n")
write.csv(out, Sys.getenv("OUTCSV"), row.names = FALSE)
