# =============================================================================
# FSR-TN-PBE-01 Ek B - Compare SAS output with R expected values (base R)
# Inputs (this folder): r_beklenen.csv, sas_veri.csv, sas_glm_ss.csv,
#   sas_covparms.csv, sas_diffs_sat.csv, sas_diffs_kr.csv, sas_conv_sat.csv
# Output: sas_karsilastir.csv (one row per data set) and a console summary.
# Run from the repository root:
#   Rscript belgeler/teknik_notlar/FSR-TN-PBE-01_ek/sas/sas_karsilastir.R
# =============================================================================
S <- file.path("belgeler", "teknik_notlar", "FSR-TN-PBE-01_ek", "sas")
rd <- function(f) utils::read.csv(file.path(S, f))
r <- rd("r_beklenen.csv"); dat <- rd("sas_veri.csv"); ss <- rd("sas_glm_ss.csv")
cp <- rd("sas_covparms.csv"); sat <- rd("sas_diffs_sat.csv"); kr <- rd("sas_diffs_kr.csv")
cv <- rd("sas_conv_sat.csv")
rel <- function(a, b) abs(a - b) / pmax(abs(b), 1e-300)

# REML criterion (-loglik/2 up to a constant) for one product, v = (sB2, sC2, sW2)
nll <- function(v, x) {
  y <- x$y; S_ <- factor(x$stage)
  X <- stats::model.matrix(~ S_)
  ZL <- stats::model.matrix(~ factor(x$batch) - 1)
  ZC <- stats::model.matrix(~ factor(paste(x$batch, x$unit)) - 1)
  V <- v[1] * ZL %*% t(ZL) + v[2] * ZC %*% t(ZC) + v[3] * diag(length(y))
  Rc <- chol(V); Vi <- chol2inv(Rc); A <- t(X) %*% Vi %*% X
  e <- y - X %*% solve(A, t(X) %*% Vi %*% y)
  0.5 * (2 * sum(log(diag(Rc))) + as.numeric(determinant(A)$modulus) + sum(e * (Vi %*% e)))
}
g <- function(s, pr, par) cp$Estimate[cp$set == s & cp$Group == paste("product", pr) & cp$CovParm == par]
h <- function(s, pr, src, col = "MS") ss[[col]][ss$set == s & ss$product == pr & ss$Source == src]

out <- list()
for (i in seq_len(nrow(r))) {
  s <- r$set[i]; N <- r$l[i] * r$n[i]; m <- r$m[i]
  o <- data.frame(set = s, case_T = r$reml_case_T[i], case_R = r$reml_case_R[i],
                  sas_status = cv$Status[cv$set == s], sas_reason = cv$Reason[cv$set == s])
  # PSG and EMS mean squares (deterministic)
  o$max_rel_ms <- max(sapply(c("T", "R"), function(pr) max(
    rel(h(s, pr, "batch"), r[[paste0("ms_lot_", pr)]][i]),
    rel(h(s, pr, "unit(batch)"), r[[paste0("ms_unit_", pr)]][i]),
    rel(h(s, pr, "Error"), r[[paste0("ms_res_", pr)]][i]),
    rel((h(s, pr, "batch", "SS") + h(s, pr, "unit(batch)", "SS")) / (N - 1), r[[paste0("msb_psg_", pr)]][i]),
    rel((h(s, pr, "stage", "SS") + h(s, pr, "Error", "SS")) / (N * (m - 1)), r[[paste0("msw_psg_", pr)]][i]))))
  # REML variance components and REML criterion at R and at SAS estimates
  x <- dat[dat$set == s, ]
  dv <- dl <- numeric(0)
  for (pr in c("T", "R")) {
    vR <- c(r[[paste0("sB2_", pr)]][i], r[[paste0("sC2_", pr)]][i], r[[paste0("sW2_", pr)]][i])
    vS <- c(g(s, pr, "batch"), g(s, pr, "unit(batch)"), g(s, pr, "Residual"))
    dv <- c(dv, max(abs(vS - vR) / max(vR)))
    dl <- c(dl, nll(vS, x[x$product == pr, ]) - nll(vR, x[x$product == pr, ]))
  }
  o$max_rel_vc <- max(dv); o$nll_sas_minus_r <- max(dl)
  # EMA (c): difference, SE, df, CI (SAS reports R - T)
  j <- match(s, sat$set)
  if (!is.na(j)) {
    o$abs_diff <- abs(-sat$Estimate[j] - r$diff[i])
    o$rel_se <- rel(sat$StdErr[j], r$se_c[i])
    o$df_r <- r$df_c[i]; o$df_sat <- sat$DF[j]; o$df_kr <- kr$DF[match(s, kr$set)]
    o$abs_lower <- abs(-sat$Upper[j] - log(r$lower90_c[i]))
  } else { o$abs_diff <- o$rel_se <- o$df_r <- o$df_sat <- o$df_kr <- o$abs_lower <- NA }
  out[[s]] <- o
}
out <- do.call(rbind, out)
utils::write.csv(out, file.path(S, "sas_karsilastir.csv"), row.names = FALSE)
print(out[, -5], digits = 3)
cat("\nREML criterion: SAS - R > 0 means the R closed form attains the higher likelihood.\n")
