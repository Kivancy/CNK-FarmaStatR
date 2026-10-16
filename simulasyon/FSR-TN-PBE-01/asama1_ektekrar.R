# =============================================================================
# FSR-TN-PBE-01 - Stage 1 extra replicates (decision KK-37 rule, applied to
#   Stage 1 on 16.10.2026; review report 02, M-08 and gate G5)
# Rule (fixed before the run): a power cell (GMR 1.00 or 1.05) is re-run with
#   n_sim = 40,000 and a new, recorded seed if, for any method, the Stage 1
#   pass rate is within 2 MCSE of 0.80. The rule is applied to every Stage 1
#   cell that meets it, not only to those in Table 11.3a.
# Reporting: the original 10,000 replicates (seed 20261015) and the new 40,000
#   (seed 20261016) are reported separately; the combined 50,000 estimate is
#   given under the assumption that the two Mersenne-Twister streams are
#   independent. Method differences use paired MCSEs (invitro_grid.R 0.2.0).
# Run from the repository root:  Rscript simulasyon/FSR-TN-PBE-01/asama1_ektekrar.R
# Output: asama1_ektekrar.csv, asama1_ektekrar_kayit.csv
# Research and education only; not a system validated for GxP environments.
# =============================================================================
library(CNKfarmastatr)
out_dir <- file.path("simulasyon", "FSR-TN-PBE-01")
s1 <- utils::read.csv(file.path(out_dir, "asama1_sonuc.csv"), stringsAsFactors = FALSE)
seed0 <- 20261015; seed1 <- 20261016; n0 <- 10000; n1 <- 40000
meth <- c("fda", "ema_a", "ema_b", "ema_c")
pw <- s1[s1$delta_id %in% c("gmr_1.00", "gmr_1.05"), ]
hit <- Reduce(`|`, lapply(meth, function(me)
  abs(pw[[paste0(me, "_pass")]] - 0.80) < 2 * pw[[paste0(me, "_pass_mcse")]]))
cells <- pw[hit, ]
t0 <- Sys.time()
rows <- lapply(seq_len(nrow(cells)), function(i) {
  g <- cells[i, ]
  a <- invitro_scenario(0.12, 1, pB = g$pB_T, pL = 0.15, q = 0, l = g$l, n = g$n, m = 3,
                        delta = g$delta, n_sim = n0, seed = seed0)
  b <- invitro_scenario(0.12, 1, pB = g$pB_T, pL = 0.15, q = 0, l = g$l, n = g$n, m = 3,
                        delta = g$delta, n_sim = n1, seed = seed1)
  stopifnot(abs(a$fda_pass - g$fda_pass) < 1e-12, abs(a$ema_c_pass - g$ema_c_pass) < 1e-12)
  do.call(rbind, lapply(meth, function(me) {
    p0 <- a[[paste0(me, "_pass")]]; p1 <- b[[paste0(me, "_pass")]]
    pc <- (n0 * p0 + n1 * p1) / (n0 + n1)
    data.frame(scenario = g$scenario, pB = g$pB_T, l = g$l, n = g$n, delta_id = g$delta_id,
               method = me, triggered = abs(p0 - 0.80) < 2 * sqrt(p0 * (1 - p0) / n0),
               power_10k = p0, mcse_10k = sqrt(p0 * (1 - p0) / n0),
               power_40k = p1, mcse_40k = sqrt(p1 * (1 - p1) / n1),
               power_50k = pc, mcse_50k = sqrt(pc * (1 - pc) / (n0 + n1)),
               ge_080_40k = p1 >= 0.80, ge_080_50k = pc >= 0.80,
               diff_vs_ema_c_40k = if (me == "ema_c") NA else
                 b[[paste0("diff_", me, "_ema_c")]],
               diff_vs_ema_c_40k_mcse = if (me == "ema_c") NA else
                 b[[paste0("diff_", me, "_ema_c_mcse")]],
               ema_c_pooled_T_40k = b$ema_c_pooled_T, ema_c_pooled_R_40k = b$ema_c_pooled_R)
  }))
})
res <- do.call(rbind, rows)
utils::write.csv(res, file.path(out_dir, "asama1_ektekrar.csv"), row.names = FALSE)
rec <- invitro_run_record("FSR-TN-PBE-01 Asama 1 ek tekrar (KK-37 kurali)", seed1, n1)
rec$seed_original <- seed0; rec$cells <- nrow(cells)
rec$elapsed_min <- round(as.numeric(Sys.time() - t0, units = "mins"), 2)
utils::write.csv(rec, file.path(out_dir, "asama1_ektekrar_kayit.csv"), row.names = FALSE)
print(res[res$triggered, c("scenario", "pB", "l", "n", "delta_id", "method",
                           "power_10k", "power_40k", "mcse_40k", "power_50k")], digits = 4)
