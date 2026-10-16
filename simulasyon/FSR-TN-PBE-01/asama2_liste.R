# =============================================================================
# FSR-TN-PBE-01 - Stage 2 scenario list (pre-registered before any Stage 2 run)
#   Decisions: KK-34 (one-at-a-time from the base scenario), KK-36 (m = 1, 2, 3
#   as general cases; no m is tied to budesonide), KK-37 (pB {0, 0.30} crossed
#   with every one-at-a-time factor; additions from the review report of
#   16.10.2026: EMA lower limit, sigma_R threshold, 2 x 2 T/R batch asymmetry,
#   60-unit designs, FDA -delta0 symmetry check, extra-replicate rule).
#   Morris, White & Crowther 2019, Sections 3.2 and 8.1 (protocol before run).
#
# Base scenario (TN 10.2): sigma_R 0.12, rho 1, pL 0.15, m 3, q 0, T/R shares equal.
# Designs (l x n): 3x10, 3x20, 5x10, 6x5.
# delta set: FDA delta0 (eta = 0, TN Eq. 11), EMA GMR 1.18, GMR 1.00, GMR 1.05.
#
# Blocks
#   A one-at-a-time factors x pB {0, 0.30}               13 x 2 x 4 x 4 = 416
#       sigma_R {0.06, 0.08, 0.10, 0.16, 0.40}; rho 1.15; pL {0.01, 0.30};
#       m {1, 2}; q 0.5; stress sigma_R 0.25, rho 0.80
#   B stress pB 0.50                                      1 x 4 x 4     =  16
#   C T/R batch asymmetry (pB_T, pB_R) = (0.30, 0), (0, 0.30)  2 x 4 x 4 = 32
#       (0/0 and 0.30/0.30 are Stage 1 cells)
#   D sigma_R threshold: (sigma_R, rho) in {0.099, 0.100, 0.101} x {1, 1.15},
#       without (0.100, 1) which is in block A; x pB {0, 0.30}  5 x 2 x 4 x 4 = 160
#   E EMA lower limit GMR 0.85 on the full Stage 1 grid
#       pB {0, 0.10, 0.30} x l {2..6} x n {5, 8, 10, 15, 20, 30}           =  90
#   F 60-unit design 5 x 12 (3x20, 4x15, 6x10 are Stage 1 cells);
#       pB {0, 0.30} x 5 delta (4 + GMR 0.85)                             =  10
#   G FDA -delta0 symmetry check: 3 x 10, pB 0.30 (expected = +delta0)    =   1
#                                                                  total  = 725
# m = 1: PSG 020929 Appendix Step 4 (E2, E4 and their H, U terms dropped);
#   with one measurement per unit the stage share is part of the unit level,
#   so pL is kept at its base value and has no separate role.
#
# Extra-replicate rule (fixed now, applied after the first pass):
#   for power cells (GMR 1.00 or 1.05) and each method, if |pass - 0.80| < 2 MCSE
#   the cell is re-run with n_sim = 40,000 and a new, recorded seed.
#
# Run from the repository root:  Rscript simulasyon/FSR-TN-PBE-01/asama2_liste.R
# Output: asama2_senaryolar.csv (one row per scenario; no simulation is run here)
# Research and education only; not a system validated for GxP environments.
# =============================================================================
library(CNKfarmastatr)
out_dir <- file.path("simulasyon", "FSR-TN-PBE-01")

base <- list(sigma_R = 0.12, rho = 1, pL = 0.15, q = 0, m = 3)
designs <- data.frame(l = c(3, 3, 5, 6), n = c(10, 20, 10, 5))
d4 <- c("fda_delta0", "ema_1.18", "gmr_1.00", "gmr_1.05")

row <- function(block, factor, sigma_R = base$sigma_R, rho = base$rho,
                pB_T, pB_R = pB_T, pL = base$pL, q = base$q, m = base$m,
                l, n, delta_id) {
  data.frame(block = block, factor = factor, sigma_R = sigma_R, rho = rho,
             pB_T = pB_T, pB_R = pB_R, pL = pL, q = q, m = m, l = l, n = n,
             delta_id = delta_id, stringsAsFactors = FALSE)
}
over <- function(block, factor, pBs, deltas = d4, dz = designs, ...) {
  g <- expand.grid(i = seq_len(nrow(dz)), pB = pBs, delta_id = deltas,
                   stringsAsFactors = FALSE)
  do.call(rbind, lapply(seq_len(nrow(g)), function(k)
    row(block, factor, pB_T = g$pB[k], l = dz$l[g$i[k]], n = dz$n[g$i[k]],
        delta_id = g$delta_id[k], ...)))
}
pB2 <- c(0, 0.30)

A <- rbind(
  do.call(rbind, lapply(c(0.06, 0.08, 0.10, 0.16, 0.40), function(s)
    over("A", "sigma_R", pB2, sigma_R = s))),
  over("A", "rho", pB2, rho = 1.15),
  do.call(rbind, lapply(c(0.01, 0.30), function(p) over("A", "pL", pB2, pL = p))),
  do.call(rbind, lapply(c(1, 2), function(mm) over("A", "m", pB2, m = mm))),
  over("A", "q", pB2, q = 0.5),
  over("A", "stress_sigma_R", pB2, sigma_R = 0.25),
  over("A", "stress_rho", pB2, rho = 0.80))
B <- over("B", "stress_pB", 0.50)
C <- rbind(
  do.call(rbind, lapply(seq_len(nrow(designs) * 4), function(k) {
    i <- (k - 1) %% 4 + 1; d <- d4[(k - 1) %/% 4 + 1]
    rbind(row("C", "TR_asym", pB_T = 0.30, pB_R = 0, l = designs$l[i], n = designs$n[i], delta_id = d),
          row("C", "TR_asym", pB_T = 0, pB_R = 0.30, l = designs$l[i], n = designs$n[i], delta_id = d))
  })))
thr <- expand.grid(sigma_R = c(0.099, 0.100, 0.101), rho = c(1, 1.15))
thr <- thr[!(thr$sigma_R == 0.100 & thr$rho == 1), ]
D <- do.call(rbind, lapply(seq_len(nrow(thr)), function(k)
  over("D", "threshold", pB2, sigma_R = thr$sigma_R[k], rho = thr$rho[k])))
g1 <- expand.grid(pB = c(0, 0.10, 0.30), l = 2:6, n = c(5, 8, 10, 15, 20, 30))
E <- do.call(rbind, lapply(seq_len(nrow(g1)), function(k)
  row("E", "ema_lower", pB_T = g1$pB[k], l = g1$l[k], n = g1$n[k], delta_id = "ema_0.85")))
F <- over("F", "units60", pB2, deltas = c(d4, "ema_0.85"), dz = data.frame(l = 5, n = 12))
G <- row("G", "fda_minus_delta0", pB_T = 0.30, l = 3, n = 10, delta_id = "fda_minus_delta0")

s <- rbind(A, B, C, D, E, F, G)
d0 <- mapply(function(sr, r) invitro_delta0(sr, rho = r), s$sigma_R, s$rho)
s$delta <- ifelse(s$delta_id == "fda_delta0", d0,
           ifelse(s$delta_id == "fda_minus_delta0", -d0,
           ifelse(s$delta_id == "ema_1.18", log(1.18),
           ifelse(s$delta_id == "ema_0.85", log(0.85),
           ifelse(s$delta_id == "gmr_1.05", log(1.05), 0)))))
s$regulatory <- s$l >= 3 & s$n >= 10           # PSG / EMA OIP minimums (KK-28)
s$scenario <- sprintf("S2-%03d", seq_len(nrow(s)))
s <- s[, c("scenario", setdiff(names(s), "scenario"))]
stopifnot(nrow(s) == 725, !anyDuplicated(s[, setdiff(names(s), c("scenario", "block", "factor"))]))
utils::write.csv(s, file.path(out_dir, "asama2_senaryolar.csv"), row.names = FALSE)
print(table(s$block))
