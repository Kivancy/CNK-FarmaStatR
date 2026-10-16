# =============================================================================
# FSR-TN-PBE-01 - Targeted experiment: criterion selection and mechanism
#   (technical note Sections 12.2-12.3; approved 16.10.2026, log G-43)
#   Not a new factorial study: a short experiment on the same data-generating
#   mechanism, design 3 x 10, rho 1, pL 0.15, m 3, q 0.
#   For every simulated data set four FDA decisions are taken on the SAME data:
#     psg    - PSG 020929: criterion chosen by the estimated sigma_R (as in the guidance)
#     oracle - criterion chosen by the true sigma_R
#     ref    - reference-scaled criterion always
#     const  - constant-scaled criterion always
#   delta = delta0 (eta = 0 under the true-sigma_R criterion). At sigma_R = 0.10
#   both population criteria are equal (eta_ref = eta_const = 0).
#   Contribution of data-driven selection = psg - oracle (paired MCSE).
#   Bias decomposition (FarmaStatR derivation, TN Eq. 14-15), b = (n-1)/(nl-1) sB^2:
#     E[Eq_Ref]   - eta_ref   = Var(mean_T - mean_R) + theta_p * b
#     E[Eq_Const] - eta_const = Var(mean_T - mean_R)
#   and the PSG variance used in H_D, E[MSB/(nlm)] summed over products, is
#   compared with the true Var(mean_T - mean_R).
# Run from the repository root:  Rscript simulasyon/FSR-TN-PBE-01/mekanizma.R
# Output: mekanizma.csv, mekanizma_kayit.csv
# Research and education only; not a system validated for GxP environments.
# =============================================================================
library(CNKfarmastatr)
out_dir <- file.path("simulasyon", "FSR-TN-PBE-01")
seed <- 20261020; n_sim <- 40000; l <- 3; n <- 10; m <- 3; pL <- 0.15
theta_p <- ((log(1.11))^2 + 0.01) / 0.01
t0 <- Sys.time()
grid <- expand.grid(sigma_R = c(0.08, 0.099, 0.10, 0.101, 0.12, 0.16), pB = c(0, 0.3))
res <- do.call(rbind, lapply(seq_len(nrow(grid)), function(k) {
  sR <- grid$sigma_R[k]; pB <- grid$pB[k]; d0 <- invitro_delta0(sR)
  cp <- invitro_components(sR, pB, pL)
  set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion")
  XT <- invitro_gen(n_sim, l, n, m, mu = d0, sB = cp$sB, sC = cp$sC, sW = cp$sW)
  XR <- invitro_gen(n_sim, l, n, m, mu = 0,  sB = cp$sB, sC = cp$sC, sW = cp$sW)
  f <- pbe_fast(XT, XR, l, n, l, n)
  ref_true <- sR > 0.1
  dec <- data.frame(psg = f$pass, oracle = if (ref_true) f$H_eta_Ref <= 0 else f$H_eta_Const <= 0,
                    ref = f$H_eta_Ref <= 0, const = f$H_eta_Const <= 0)
  pr <- function(x) c(mean(x), sqrt(mean(x) * (1 - mean(x)) / n_sim))
  pd <- function(a, b) { D <- as.numeric(a) - as.numeric(b); c(mean(D), stats::sd(D) / sqrt(n_sim)) }
  eta_ref <- d0^2 - theta_p * sR^2                      # sigma_T = sigma_R
  eta_con <- d0^2 - theta_p * 0.01
  b <- (n - 1) / (n * l - 1) * cp$sB^2
  v_true <- 2 * (cp$sB^2 / l + cp$sC^2 / (n * l) + cp$sW^2 / (n * l * m))
  v_psg  <- 2 * (cp$sC^2 / (n * l) + cp$sW^2 / (n * l * m) + (l - 1) / (l * (n * l - 1)) * cp$sB^2)
  o <- data.frame(sigma_R = sR, pB = pB, delta0 = d0, eta_ref = eta_ref, eta_const = eta_con,
                  share_ref_selected = mean(f$ref_scaled))
  for (nm in names(dec)) { v <- pr(dec[[nm]]); o[[paste0("t1_", nm)]] <- v[1]; o[[paste0("t1_", nm, "_mcse")]] <- v[2] }
  v <- pd(dec$psg, dec$oracle); o$psg_minus_oracle <- v[1]; o$psg_minus_oracle_mcse <- v[2]
  v <- pd(dec$const, dec$ref);  o$const_minus_ref <- v[1];  o$const_minus_ref_mcse <- v[2]
  o$bias_Eq_ref_sim <- mean(f$Eq_Ref) - eta_ref;   o$bias_Eq_ref_formula <- v_true + theta_p * b
  o$bias_Eq_const_sim <- mean(f$Eq_Const) - eta_con; o$bias_Eq_const_formula <- v_true
  o$bias_mcse <- stats::sd(f$Eq_Ref) / sqrt(n_sim)
  o$sqrtU_ref <- mean(sqrt(f$Uq_Ref)); o$sqrtU_const <- mean(sqrt(f$Uq_Const))
  o$var_diff_true <- v_true; o$var_diff_psg_expected <- v_psg
  o$var_diff_psg_sim <- mean(f$msb_t / (n * l * m) + f$msb_r / (n * l * m))
  o
}))
utils::write.csv(res, file.path(out_dir, "mekanizma.csv"), row.names = FALSE)
rec <- invitro_run_record("FSR-TN-PBE-01 hedefli deney (mekanizma)", seed, n_sim)
rec$elapsed_min <- round(as.numeric(Sys.time() - t0, units = "mins"), 2)
utils::write.csv(rec, file.path(out_dir, "mekanizma_kayit.csv"), row.names = FALSE)
p <- function(x) round(100 * x, 2)
print(data.frame(sR = res$sigma_R, pB = res$pB, refsel = p(res$share_ref_selected),
                 psg = p(res$t1_psg), oracle = p(res$t1_oracle), ref = p(res$t1_ref), const = p(res$t1_const),
                 psg_orc = p(res$psg_minus_oracle), se1 = p(res$psg_minus_oracle_mcse),
                 con_ref = p(res$const_minus_ref), se2 = p(res$const_minus_ref_mcse)))
print(data.frame(sR = res$sigma_R, pB = res$pB,
                 bref_sim = signif(res$bias_Eq_ref_sim, 4), bref_f = signif(res$bias_Eq_ref_formula, 4),
                 bcon_sim = signif(res$bias_Eq_const_sim, 4), bcon_f = signif(res$bias_Eq_const_formula, 4),
                 se = signif(res$bias_mcse, 2), sqU_ref = signif(res$sqrtU_ref, 4), sqU_con = signif(res$sqrtU_const, 4),
                 vtrue = signif(res$var_diff_true, 4), vpsg = signif(res$var_diff_psg_sim, 4)))
