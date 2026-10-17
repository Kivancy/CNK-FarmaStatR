# =============================================================================
# FSR-TN-PLT-01 v0.2 - P0 prototype: hypothesis state per scenario and method
#   (owner's review of v0.1, section 4: "every scenario and method needs its true
#   hypothesis state; pass rate under H0 = pointwise type I error, under H1 = power")
#   Rules (FarmaStatR derivation, to be fixed in P0; FSR-TN-PLT-01 Section 5):
#     FDA PBE  : true eta from the true parameters (criterion chosen by the TRUE
#                sigma_R; PSG 020929). H0: eta >= 0; H1: eta < 0.
#                Boundary: |eta| <= tol_eta (eta at delta0 is 0 only up to rounding).
#     EMA (a), (b), (c): true GMR = exp(delta). H0: GMR <= 0.85 or GMR >= 1.18;
#                H1: 0.85 < GMR < 1.18 (EMA OIP Rev. 2, Section 5.1 criterion 8).
#                Boundary: |log GMR - log limit| <= tol_log.
#   Applied to the Stage 1 and Stage 2 grids; prints the classes and checks that
#   the technical note's reading (type I at FDA delta0 / EMA 1.18 and 0.85; power at
#   GMR 1.00 and 1.05) agrees with the classification.
# Run from the repository root:
#   Rscript belgeler/teknik_notlar/FSR-TN-PLT-01_ek/hipotez_siniflandirma.R
# Output: hipotez_siniflandirma.csv (counts) in this folder.
# Research and education only; not a system validated for GxP environments.
# =============================================================================
S <- file.path("simulasyon", "FSR-TN-PBE-01")
out <- file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-01_ek")
a <- utils::read.csv(file.path(S, "asama1_sonuc.csv"), stringsAsFactors = FALSE); a$stage <- 1
b <- utils::read.csv(file.path(S, "asama2_sonuc.csv"), stringsAsFactors = FALSE); b$stage <- 2
cols <- c("stage", "scenario", "delta_id", "sigma_R", "rho", "delta", "gmr", "eta")
g <- rbind(a[, cols], b[, cols])
tol_eta <- 1e-12; tol_log <- 1e-12
theta_p <- ((log(1.11))^2 + 0.01) / 0.01
# true eta recomputed from the parameters (independent of the stored column)
sT <- g$rho * g$sigma_R
eta_true <- g$delta^2 + sT^2 - g$sigma_R^2 - theta_p * pmax(g$sigma_R^2, 0.01)
stopifnot(max(abs(eta_true - g$eta)) < 1e-12)
cls_fda <- ifelse(abs(eta_true) <= tol_eta, "H0_sinir", ifelse(eta_true > 0, "H0_ic", "H1"))
lg <- log(g$gmr); lo <- log(0.85); hi <- log(1.18)
cls_ema <- ifelse(abs(lg - lo) <= tol_log | abs(lg - hi) <= tol_log, "H0_sinir",
                  ifelse(lg < lo | lg > hi, "H0_ic", "H1"))
long <- rbind(data.frame(g[, c("stage", "scenario", "delta_id")], method = "fda", class = cls_fda),
              data.frame(g[, c("stage", "scenario", "delta_id")], method = "ema", class = cls_ema))
long$metric <- ifelse(long$class == "H1", "guc", "noktasal_tip1")
tab <- stats::aggregate(list(n = rep(1, nrow(long))), long[, c("stage", "delta_id", "method", "class", "metric")], sum)
tab <- tab[order(tab$stage, tab$delta_id, tab$method, tab$class), ]
utils::write.csv(tab, file.path(out, "hipotez_siniflandirma.csv"), row.names = FALSE)
print(tab, row.names = FALSE)
# checks against the technical note's reading
chk <- function(d, m, want) all(long$class[long$delta_id %in% d & long$method == m] %in% want)
res <- c(fda_typeI_at_delta0 = chk(c("fda_delta0", "fda_minus_delta0"), "fda", "H0_sinir"),
         ema_typeI_at_limits = chk(c("ema_1.18", "ema_0.85"), "ema", "H0_sinir"),
         power_cells_H1_fda  = chk(c("gmr_1.00", "gmr_1.05"), "fda", "H1"),
         power_cells_H1_ema  = chk(c("gmr_1.00", "gmr_1.05"), "ema", "H1"),
         eta_sign_alone_would_misclassify = sum(g$delta_id == "fda_delta0" & g$eta < 0))
print(res)
