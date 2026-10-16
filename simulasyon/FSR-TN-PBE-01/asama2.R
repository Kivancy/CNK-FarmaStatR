# =============================================================================
# FSR-TN-PBE-01 - Stage 2 run (decision KK-37; list fixed before the run)
#   Scenarios: asama2_senaryolar.csv (725 rows, validated by asama2_dogrula.R).
#   n_sim 10,000; every scenario starts from the Stage 1 seed (KK-35).
#   Extra-replicate rule (KK-37): power cells (GMR 1.00 or 1.05) in which any
#   method's pass rate is within 2 MCSE of 0.80 are re-run with n_sim 40,000 and
#   seed 20261016; results are reported separately (asama2_ektekrar.csv).
#   Engine: invitro_grid.R 0.2.0 (paired MCSEs, REML boundary share).
# Run from the repository root:  Rscript simulasyon/FSR-TN-PBE-01/asama2.R
# Output: asama2_sonuc.csv, asama2_ektekrar.csv, asama2_kayit.csv
# Research and education only; not a system validated for GxP environments.
# =============================================================================
library(CNKfarmastatr)
out_dir <- file.path("simulasyon", "FSR-TN-PBE-01")
sc <- utils::read.csv(file.path(out_dir, "asama2_senaryolar.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(sc) == 725)
seed <- 20261015; seed_extra <- 20261016; n_sim <- 10000; n_extra <- 40000
run1 <- function(g, ns, sd) invitro_scenario(g$sigma_R, rho = g$rho, pL = g$pL, q = g$q,
  l = g$l, n = g$n, m = g$m, delta = g$delta, pB_T = g$pB_T, pB_R = g$pB_R,
  n_sim = ns, seed = sd)
t0 <- Sys.time()
res <- vector("list", nrow(sc))
for (i in seq_len(nrow(sc))) {
  g <- sc[i, ]
  res[[i]] <- cbind(sc[i, c("scenario", "block", "factor", "delta_id", "regulatory")], run1(g, n_sim, seed))
  if (i %% 50 == 0) message(i, "/", nrow(sc), "  ", format(Sys.time() - t0))
}
res <- do.call(rbind, res)
utils::write.csv(res, file.path(out_dir, "asama2_sonuc.csv"), row.names = FALSE)
# extra replicates (rule fixed in advance)
meth <- c("fda", "ema_a", "ema_b", "ema_c")
pw <- res$delta_id %in% c("gmr_1.00", "gmr_1.05")
hit <- pw & Reduce(`|`, lapply(meth, function(me)
  abs(res[[paste0(me, "_pass")]] - 0.80) < 2 * res[[paste0(me, "_pass_mcse")]]))
ex <- lapply(which(hit), function(i) {
  b <- run1(sc[i, ], n_extra, seed_extra)
  do.call(rbind, lapply(meth, function(me) {
    p0 <- res[[paste0(me, "_pass")]][i]; p1 <- b[[paste0(me, "_pass")]]
    pc <- (n_sim * p0 + n_extra * p1) / (n_sim + n_extra)
    data.frame(scenario = res$scenario[i], method = me,
               triggered = abs(p0 - 0.80) < 2 * sqrt(p0 * (1 - p0) / n_sim),
               power_10k = p0, power_40k = p1, mcse_40k = sqrt(p1 * (1 - p1) / n_extra),
               power_50k = pc, mcse_50k = sqrt(pc * (1 - pc) / (n_sim + n_extra)))
  }))
})
ex <- if (length(ex)) do.call(rbind, ex) else data.frame()
utils::write.csv(ex, file.path(out_dir, "asama2_ektekrar.csv"), row.names = FALSE)
rec <- invitro_run_record("FSR-TN-PBE-01 Asama 2 (KK-37)", seed, n_sim)
rec$scenarios <- nrow(res); rec$extra_cells <- sum(hit); rec$seed_extra <- seed_extra
rec$n_extra <- n_extra
rec$elapsed_min <- round(as.numeric(Sys.time() - t0, units = "mins"), 2)
utils::write.csv(rec, file.path(out_dir, "asama2_kayit.csv"), row.names = FALSE)
message("done: ", nrow(res), " scenarios; extra cells: ", sum(hit))
