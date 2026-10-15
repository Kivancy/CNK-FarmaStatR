# =============================================================================
# FSR-TN-PBE-01 v0.4 - Stage 1 of the scenario list (decision KK-34)
#   Base: sigma_R 0.12, rho 1, pL 0.15, m 3, q 0, same shares for T and R
#   Factors: pB {0, 0.10, 0.30} x l {2..6} x n {5, 8, 10, 15, 20, 30}
#            x delta {FDA delta0, log 1.18, 0, log 1.05}  = 360 scenarios
#   n_sim 10,000; every scenario starts from the same seed (KK-35)
# Run from the repository root:  Rscript simulasyon/FSR-TN-PBE-01/asama1.R
# Output: asama1_sonuc.csv (one row per scenario), asama1_kayit.csv (run record)
# Research and education only; not a system validated for GxP environments.
# =============================================================================
library(CNKfarmastatr)
out_dir <- file.path("simulasyon", "FSR-TN-PBE-01")
seed <- 20261015; n_sim <- 10000; sigma_R <- 0.12
d0 <- invitro_delta0(sigma_R)
deltas <- c(fda_delta0 = d0, ema_1.18 = log(1.18), gmr_1.00 = 0, gmr_1.05 = log(1.05))
grid <- expand.grid(pB = c(0, 0.10, 0.30), l = 2:6, n = c(5, 8, 10, 15, 20, 30),
                    delta_id = names(deltas), stringsAsFactors = FALSE)
res <- vector("list", nrow(grid)); t0 <- Sys.time()
for (i in seq_len(nrow(grid))) {
  g <- grid[i, ]
  r <- invitro_scenario(sigma_R, rho = 1, pB = g$pB, pL = 0.15, q = 0,
                        l = g$l, n = g$n, m = 3, delta = deltas[[g$delta_id]],
                        n_sim = n_sim, seed = seed)
  res[[i]] <- cbind(scenario = sprintf("S1-%03d", i), delta_id = g$delta_id, r)
  if (i %% 30 == 0) message(i, "/", nrow(grid), "  ", format(Sys.time() - t0))
}
res <- do.call(rbind, res)
utils::write.csv(res, file.path(out_dir, "asama1_sonuc.csv"), row.names = FALSE)
rec <- invitro_run_record("FSR-TN-PBE-01 Asama 1 (KK-34)", seed, n_sim)
rec$scenarios <- nrow(res); rec$elapsed_min <- round(as.numeric(Sys.time() - t0, units = "mins"), 2)
utils::write.csv(rec, file.path(out_dir, "asama1_kayit.csv"), row.names = FALSE)
