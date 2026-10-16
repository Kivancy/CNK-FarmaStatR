# =============================================================================
# FSR-TN-PBE-01 - Stage 2 scenario list: machine-readable validation (gate G1)
#   Review report 02 (16.10.2026), M-06 and gate G1. Checks asama2_senaryolar.csv
#   against decision KK-37 before any Stage 2 run.
# Run from the repository root:  Rscript simulasyon/FSR-TN-PBE-01/asama2_dogrula.R
# Output: asama2_dogrulama.csv (one row per check: check, expected, observed, pass)
# Research and education only; not a system validated for GxP environments.
# =============================================================================
library(CNKfarmastatr)
out_dir <- file.path("simulasyon", "FSR-TN-PBE-01")
s <- utils::read.csv(file.path(out_dir, "asama2_senaryolar.csv"), stringsAsFactors = FALSE)
res <- data.frame(check = character(), expected = character(), observed = character(),
                  pass = logical(), stringsAsFactors = FALSE)
ck <- function(name, expected, observed) {
  e <- paste(expected, collapse = " "); o <- paste(observed, collapse = " ")
  res[nrow(res) + 1, ] <<- list(name, e, o, identical(e, o))
}
ck("rows", 725, nrow(s))
ck("unique scenario id", 725, length(unique(s$scenario)))
ck("unique parameter rows", 725,
   nrow(unique(s[, c("sigma_R", "rho", "pB_T", "pB_R", "pL", "q", "m", "l", "n", "delta")])))
tb <- table(s$block)
ck("block counts A..G", c(416, 16, 32, 160, 90, 10, 1), as.vector(tb[c("A", "B", "C", "D", "E", "F", "G")]))
ck("regulatory rows (l >= 3, n >= 10)", 527, sum(s$l >= 3 & s$n >= 10))
ck("regulatory flag consistent", TRUE, all(s$regulatory == (s$l >= 3 & s$n >= 10)))
ck("sigma_R levels", "0.06 0.08 0.099 0.1 0.101 0.12 0.16 0.25 0.4", sort(unique(s$sigma_R)))
ck("rho levels", "0.8 1 1.15", sort(unique(s$rho)))
ck("pB_T levels", "0 0.1 0.3 0.5", sort(unique(s$pB_T)))
ck("pB_R levels", "0 0.1 0.3 0.5", sort(unique(s$pB_R)))
ck("pL levels", "0.01 0.15 0.3", sort(unique(s$pL)))
ck("q levels", "0 0.5", sort(unique(s$q)))
ck("m levels", "1 2 3", sort(unique(s$m)))
ck("T/R asymmetry only in block C", TRUE, all((s$pB_T != s$pB_R) == (s$block == "C")))
ck("block C pairs", "0.3/0 0/0.3", sort(unique(paste(s$pB_T[s$block == "C"], s$pB_R[s$block == "C"], sep = "/")), method = "radix"))
ck("m = 1 rows have q = 0", TRUE, all(s$q[s$m == 1] == 0))
ck("q > 0 rows have m >= 2", TRUE, all(s$m[s$q > 0] >= 2))
ck("GMR 1.10 rows (not in the article list; platform only)", 0, sum(abs(s$delta - log(1.10)) < 1e-12))
ck("delta ids", "ema_0.85 ema_1.18 fda_delta0 fda_minus_delta0 gmr_1.00 gmr_1.05", sort(unique(s$delta_id), method = "radix"))
d0 <- mapply(function(a, b) invitro_delta0(a, rho = b), s$sigma_R, s$rho)
dd <- ifelse(s$delta_id == "fda_delta0", d0, ifelse(s$delta_id == "fda_minus_delta0", -d0,
      ifelse(s$delta_id == "ema_1.18", log(1.18), ifelse(s$delta_id == "ema_0.85", log(0.85),
      ifelse(s$delta_id == "gmr_1.05", log(1.05), 0)))))
ck("delta values recomputed (max abs diff < 1e-12)", TRUE, max(abs(dd - s$delta)) < 1e-12)
ck("delta0 defined in every row", TRUE, !anyNA(d0))
# total variance of T and R equals the target in every row (shares + drift)
tot <- function(sig, pB, pL, q, m) {
  cp <- invitro_components(sig, pB, pL, q)
  cp$sB^2 + cp$sC^2 + cp$sW^2 + mean(invitro_drift(m, cp$drift_var)^2)
}
vT <- mapply(tot, s$rho * s$sigma_R, s$pB_T, s$pL, s$q, s$m)
vR <- mapply(tot, s$sigma_R, s$pB_R, s$pL, s$q, s$m)
ck("total variance T = (rho sigma_R)^2", TRUE, max(abs(vT - (s$rho * s$sigma_R)^2)) < 1e-14)
ck("total variance R = sigma_R^2", TRUE, max(abs(vR - s$sigma_R^2)) < 1e-14)
# no overlap with Stage 1 (base sigma_R 0.12, rho 1, pL 0.15, q 0, m 3, symmetric shares,
# pB {0, 0.1, 0.3}, l 2..6, n {5, 8, 10, 15, 20, 30}, delta {fda_delta0, ema_1.18, gmr_1.00, gmr_1.05})
st1 <- s$sigma_R == 0.12 & s$rho == 1 & s$pL == 0.15 & s$q == 0 & s$m == 3 & s$pB_T == s$pB_R &
       s$pB_T %in% c(0, 0.1, 0.3) & s$l %in% 2:6 & s$n %in% c(5, 8, 10, 15, 20, 30) &
       s$delta_id %in% c("fda_delta0", "ema_1.18", "gmr_1.00", "gmr_1.05")
ck("rows duplicating Stage 1 cells", 0, sum(st1))
utils::write.csv(res, file.path(out_dir, "asama2_dogrulama.csv"), row.names = FALSE)
print(res, right = FALSE)
cat("\nAll checks passed:", all(res$pass), "\n")
if (!all(res$pass)) quit(status = 1)
