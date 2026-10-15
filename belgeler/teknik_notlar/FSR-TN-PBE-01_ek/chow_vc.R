# FSR-TN-PBE-01 (v0.3 attachment): variance structure of real in vitro data
# Source data: Chow SC, Liu JP (2008) Design and Analysis of Bioavailability and
#   Bioequivalence Studies, 3rd ed., Tables 14.5.2 (D50) and 14.5.3 (SPAN):
#   butorphanol nasal spray (test) vs Stadol NS (reference), laser diffraction,
#   3 lots x 10 bottles x 3 life stages (Beg, Mid, End), at 3, 5 and 7 cm.
# The transcribed data file (chow1452.csv: var, dist, prod, lot, stage, bottle, y)
#   is kept outside the repository (taken from a copyrighted book).
# Method (FarmaStatR derivation): log scale, separately per variable, distance and
#   product; PSG 020929 mean squares (MSB pooled over bottles, MSW within bottle)
#   plus the lot line of the two-level nested ANOVA (Searle et al. 2006, Table 4.10).
#   sigma2_B = (MS_lot - MS_bottle(lot)) / (n m), sigma2_C = (MS_bottle(lot) - MSW) / m,
#   sigma2_L = MSW; negative estimates truncated at 0.
# Run: Rscript chow_vc.R chow1452.csv   (R >= 4.1, base R only)
args <- commandArgs(TRUE); d <- read.csv(if (length(args)) args[1] else "chow1452.csv")
vc <- function(x, l = 3, n = 10, m = 3) {
  x$ly <- log(x$y); x$C <- paste(x$lot, x$bottle)
  cm <- tapply(x$ly, x$C, mean); lm_ <- tapply(x$ly, x$lot, mean); g <- mean(x$ly)
  MSW <- sum((x$ly - cm[x$C])^2) / (n * l * (m - 1))
  bot_lot <- sapply(strsplit(names(cm), " "), `[`, 1)
  MSc <- m * sum((cm - lm_[bot_lot])^2) / (l * (n - 1))
  MSl <- n * m * sum((lm_ - g)^2) / (l - 1)
  sB <- max((MSl - MSc) / (n * m), 0); sC <- max((MSc - MSW) / m, 0); sL <- MSW
  tot <- sB + sC + sL
  c(sB2 = sB, sC2 = sC, sL2 = sL, sigma = sqrt(tot), pB = sB / tot, pC = sC / tot,
    pL = sL / tot, p_lot = pf(MSl / MSc, l - 1, l * (n - 1), lower.tail = FALSE))
}
out <- NULL
for (v in c("D50", "SPAN")) for (k in c(3, 5, 7)) for (p in c("Reference", "Test"))
  out <- rbind(out, data.frame(var = v, dist_cm = k, product = p,
                               t(round(vc(d[d$var == v & d$dist == k & d$prod == p, ]), 4))))
print(out, row.names = FALSE)
write.csv(out, "chow_vc.csv", row.names = FALSE)
