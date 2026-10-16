# =============================================================================
# FSR-TN-PBE-01 - Tables 11.3a and 11.3b from Stage 1 results (gate G4)
#   Decision KK-38 (16.10.2026; review report 02, M-01): three-class label of a
#   type I error estimate p with Monte Carlo SE (Morris, White & Crowther 2019,
#   Table 6), z = 1.645 (one-sided 95%):
#     "exceeds"       p - z MCSE > 0.05   (evidence above the nominal level)
#     "controlled"    p + z MCSE <= 0.05  (evidence at or below the nominal level)
#     "inconclusive"  otherwise           (not distinguishable from 0.05)
#   Table 11.3b admits designs that are not "exceeds". The earlier rule
#   p <= 0.05 + 2 MCSE is withdrawn. Exploratory labels, not proofs.
#   Power is read at GMR 1.05; type I error at the method's own boundary (FDA:
#   delta0; EMA: GMR 1.18). Extra replicates (asama1_ektekrar.csv) do not change
#   any table cell; they are reported in the technical note.
# Run from the repository root:  Rscript simulasyon/FSR-TN-PBE-01/asama1_tablo113.R
# Output: asama1_tablo113.csv
# Research and education only; not a system validated for GxP environments.
# =============================================================================
out_dir <- file.path("simulasyon", "FSR-TN-PBE-01")
s <- utils::read.csv(file.path(out_dir, "asama1_sonuc.csv"), stringsAsFactors = FALSE)
meth <- c(FDA = "fda", EMA_a = "ema_a", EMA_b = "ema_b", EMA_c = "ema_c")
t1d <- c(FDA = "fda_delta0", EMA_a = "ema_1.18", EMA_b = "ema_1.18", EMA_c = "ema_1.18")
z <- stats::qnorm(0.95)
out <- list()
for (mm in names(meth)) for (pb in c(0, 0.1, 0.3)) {
  p <- s[s$delta_id == "gmr_1.05" & s$pB_T == pb, ]
  t1 <- s[s$delta_id == t1d[[mm]] & s$pB_T == pb, ]
  k <- match(paste(p$l, p$n), paste(t1$l, t1$n))
  d <- data.frame(l = p$l, n = p$n, total = p$l * p$n,
                  power = p[[paste0(meth[[mm]], "_pass")]],
                  power_mcse = p[[paste0(meth[[mm]], "_pass_mcse")]],
                  t1 = t1[[paste0(meth[[mm]], "_pass")]][k],
                  t1_mcse = t1[[paste0(meth[[mm]], "_pass_mcse")]][k])
  d$t1_lb <- d$t1 - z * d$t1_mcse
  d$t1_ub <- d$t1 + z * d$t1_mcse
  d$t1_class <- ifelse(d$t1_lb > 0.05, "exceeds", ifelse(d$t1_ub <= 0.05, "controlled", "inconclusive"))
  d$t1_ok <- d$t1_class != "exceeds"
  d <- d[order(d$total, d$l), ]
  a <- d[d$power >= 0.80, ][1, ]
  b <- d[d$power >= 0.80 & d$t1_ok & d$l >= 3 & d$n >= 10, ][1, ]
  for (tab in c("11.3a", "11.3b")) {
    r <- if (tab == "11.3a") a else b
    out[[length(out) + 1]] <- data.frame(table = tab, method = mm, pB = pb,
      l = r$l, n = r$n, total = r$total, power = r$power, power_mcse = r$power_mcse,
      t1 = r$t1, t1_mcse = r$t1_mcse, t1_lb = r$t1_lb, t1_ub = r$t1_ub,
      t1_class = r$t1_class)
  }
}
res <- do.call(rbind, out)
utils::write.csv(res, file.path(out_dir, "asama1_tablo113.csv"), row.names = FALSE)
print(res, digits = 4)
