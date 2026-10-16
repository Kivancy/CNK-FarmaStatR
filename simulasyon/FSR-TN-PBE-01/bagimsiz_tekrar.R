# =============================================================================
# FSR-TN-PBE-01 - Independent re-run of the main Stage 1 cells (review report 02,
#   M-12: main result cells re-produced with a new seed)
#   Cells: Tables 11.1 and 11.2 of the technical note (design 3 x 10;
#   pB {0, 0.10, 0.30}; delta {FDA delta0, EMA GMR 1.18, GMR 1.00, GMR 1.05}).
#   New seed 20261019, n_sim 40,000. For every method the difference to Stage 1
#   is given with z = (p_new - p_old) / sqrt(MCSE_new^2 + MCSE_old^2)
#   (independent streams assumed).
# Run from the repository root:  Rscript simulasyon/FSR-TN-PBE-01/bagimsiz_tekrar.R
# Output: bagimsiz_tekrar.csv
# Research and education only; not a system validated for GxP environments.
# =============================================================================
library(CNKfarmastatr)
out_dir <- file.path("simulasyon", "FSR-TN-PBE-01")
s1 <- utils::read.csv(file.path(out_dir, "asama1_sonuc.csv"), stringsAsFactors = FALSE)
cells <- s1[s1$l == 3 & s1$n == 10, ]
meth <- c("fda", "ema_a", "ema_b", "ema_c")
res <- do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
  g <- cells[i, ]
  b <- invitro_scenario(0.12, 1, pB = g$pB_T, pL = 0.15, q = 0, l = 3, n = 10, m = 3,
                        delta = g$delta, n_sim = 40000, seed = 20261019)
  do.call(rbind, lapply(meth, function(me) {
    p0 <- g[[paste0(me, "_pass")]]; s0 <- g[[paste0(me, "_pass_mcse")]]
    p1 <- b[[paste0(me, "_pass")]]; s1_ <- b[[paste0(me, "_pass_mcse")]]
    data.frame(scenario = g$scenario, pB = g$pB_T, delta_id = g$delta_id, method = me,
               stage1 = p0, stage1_mcse = s0, rerun = p1, rerun_mcse = s1_,
               z = (p1 - p0) / sqrt(s0^2 + s1_^2))
  }))
}))
utils::write.csv(res, file.path(out_dir, "bagimsiz_tekrar.csv"), row.names = FALSE)
cat("cells:", nrow(res), " max |z|:", round(max(abs(res$z)), 2),
    " |z| > 2:", sum(abs(res$z) > 2), " |z| > 3:", sum(abs(res$z) > 3), "\n")
