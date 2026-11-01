# Type I error of the Chow-Shao-Wang (2003) test: Table I (theta_BE = 1.125, sigma_0 = 0.2,
# 10 000 replications per cell), regenerated with the CNK-FarmaStatR generator invitro_gen.
# Mapping: one batch (l = 1, sB = 0); canisters = units (sC = sigma_B); replicates = stages
# (sW = sigma_W). delta chosen so that eta = 0 (Section 3).
# Run from this folder: Rscript csw2003_tablo1.R
source("csw2003.R")
source(file.path("..", "..", "..", "CNKfarmastatr", "R", "invitro_fast.R"))
pub <- read.table(header = TRUE, text = "
sBT  sBR  sWT  sWR  m60 m50 m40 m30 m30n2 m30n3
0    0    0.25 0.25 0.0431 0.0427 0.0388 0.0381 0.0390 0.0471
0    0    0.25 0.50 0.0479 0.0421 0.0433 0.0411 0.0503 0.0517
0    0    0.50 0.50 0.0431 0.0408 0.0410 0.0382 0.0431 0.0470
0.25 0.25 0.25 0.25 0.0391 0.0430 0.0395 0.0373 0.0433 0.0423
0.25 0.25 0.25 0.50 0.0444 0.0439 0.0449 0.0444 0.0451 0.0493
0.25 0.25 0.50 0.50 0.0414 0.0423 0.0455 0.0424 0.0429 0.0454
0.50 0.25 0.25 0.50 0.0414 0.0412 0.0412 0.0402 0.0415 0.0436
0.50 0.25 0.50 0.50 0.0389 0.0361 0.0408 0.0353 0.0355 0.0404
0.25 0.50 0.25 0.25 0.0434 0.0396 0.0428 0.0437 0.0401 0.0454
0.25 0.50 0.50 0.25 0.0439 0.0442 0.0419 0.0396 0.0405 0.0391
0.25 0.50 0.25 0.50 0.0431 0.0444 0.0446 0.0395 0.0460 0.0448
0.25 0.50 0.50 0.50 0.0406 0.0431 0.0406 0.0379 0.0385 0.0420
0.50 0.50 0.25 0.25 0.0416 0.0430 0.0418 0.0369 0.0380 0.0392
0.50 0.50 0.50 0.25 0.0398 0.0404 0.0360 0.0365 0.0350 0.0341
0.50 0.50 0.25 0.50 0.0452 0.0453 0.0400 0.0391 0.0463 0.0439
0.50 0.50 0.50 0.50 0.0468 0.0473 0.0401 0.0432 0.0425 0.0411")
des <- list(m60 = c(60, 1), m50 = c(50, 1), m40 = c(40, 1), m30 = c(30, 1), m30n2 = c(30, 2), m30n3 = c(30, 3))
theta <- 1.125; s0 <- 0.2; R <- 10000
RNGkind("Mersenne-Twister", "Inversion", "Rejection"); set.seed(20031)
rows <- list()
for (i in seq_len(nrow(pub))) for (k in names(des)) {
  p <- pub[i, ]; m <- des[[k]][1]; n <- des[[k]][2]
  vT <- p$sBT^2 + p$sWT^2; vR <- p$sBR^2 + p$sWR^2
  delta <- sqrt(theta * max(s0^2, vR) - vT + vR)                     # eta = 0
  XT <- invitro_gen(R, l = 1, n = m, m = n, mu = delta, sB = 0, sC = p$sBT, sW = p$sWT)
  XR <- invitro_gen(R, l = 1, n = m, m = n, mu = 0,     sB = 0, sC = p$sBR, sW = p$sWR)
  st <- csw_stats(XT); sr <- csw_stats(XR)
  b <- csw_bound(st$g - sr$g, st$sB, sr$sB, st$sW, sr$sW, m, m, n, n, theta, s0)
  ours <- mean(b$eta_U < 0); theirs <- p[[k]]
  se <- sqrt((ours * (1 - ours) + theirs * (1 - theirs)) / R)       # both are Monte Carlo estimates
  rows[[length(rows) + 1]] <- data.frame(p[1:4], design = sprintf("(%d,%d)", m, n), delta = delta,
    published = theirs, cnk = ours, mcse_cnk = sqrt(ours * (1 - ours) / R), z = (ours - theirs) / se)
}
res <- do.call(rbind, rows)
write.csv(res, "csw2003_tablo1.csv", row.names = FALSE)
cat(sprintf("cells %d; published range %.4f-%.4f; CNK range %.4f-%.4f\n", nrow(res), min(res$published), max(res$published), min(res$cnk), max(res$cnk)))
cat(sprintf("mean difference %.5f; |z| > 2: %d (expected about %.1f); |z| > 3: %d; sum z^2 = %.1f on %d df (p = %.3f)\n",
  mean(res$cnk - res$published), sum(abs(res$z) > 2), 0.0455 * nrow(res), sum(abs(res$z) > 3),
  sum(res$z^2), nrow(res), stats::pchisq(sum(res$z^2), nrow(res), lower.tail = FALSE)))
cat(R.version.string, "| seed 20031, Mersenne-Twister / Inversion / Rejection\n")
