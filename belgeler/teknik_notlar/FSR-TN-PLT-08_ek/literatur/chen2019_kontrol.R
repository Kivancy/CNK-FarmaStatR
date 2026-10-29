# =============================================================================
# FSR-TN-PLT-08 - literature check of EMA 90% CI paths (a) and (b) (FSR-LOG-01 G-107)
#   Chen et al. (2019) AAPS PharmSciTech 20:296, Table II, Methods 3 and 4:
#     "Log-Can" ABE   SE1 = sqrt(MSC_T/n + MSC_R/n), df1 = (bc - 1)(MSC_T + MSC_R)^2/(MSC_T^2 + MSC_R^2)
#     "Log-Batch" ABE SE2 = sqrt(MSB_T/n + MSB_R/n), df2 = (b - 1)(MSB_T + MSB_R)^2/(MSB_T^2 + MSB_R^2)
#   n = total number of cans. Written here with base R (lm/anova), independently of
#   ema_ci_fast, and compared with platform_ema() on PSG 020929 Appendix B data.
#   Two readings with life stages: mean squares from can means (n = cans) or from
#   raw rows (one row per stage). Only the first is consistent with n = cans.
# Run from the repository root:
#   source("belgeler/teknik_notlar/FSR-TN-PLT-08_ek/literatur/chen2019_kontrol.R", encoding = "UTF-8")
# Research and education only; not a system validated for GxP environments.
# =============================================================================
local({
platform_ema <- CNKfarmastatr:::platform_ema
d <- utils::read.csv(file.path("CNKfarmastatr", "inst", "validasyon", "pbe", "test_verisi", "P1_psg020929.csv"))
d$ly <- d$score   # PSG 020929 Appendix B values are taken as log scale (platform log_d = FALSE)
d$Batches <- factor(d$Batches); d$unit <- factor(paste(d$Batches, d$Container))
chen <- function(dd, level = 0.90, canmean = TRUE) {
  ms <- function(p) {
    x <- droplevels(dd[dd$Product == p, ])
    if (canmean) x <- stats::aggregate(ly ~ Batches + unit, x, mean)
    x <- droplevels(x)
    MSC <- if (canmean) stats::var(x$ly) else stats::anova(stats::lm(ly ~ unit, x))["unit", "Mean Sq"]
    MSB <- stats::anova(stats::lm(ly ~ Batches, x))["Batches", "Mean Sq"]
    list(mean = mean(x$ly), MSC = MSC, MSB = MSB, b = nlevels(x$Batches), n = nlevels(x$unit))
  }
  T <- ms("TEST"); R <- ms("REF"); dif <- T$mean - R$mean
  f <- function(MT, MR, k) {
    se <- sqrt(MT / T$n + MR / R$n); df <- k * (MT + MR)^2 / (MT^2 + MR^2)
    q <- stats::qt(1 - (1 - level) / 2, df)
    c(alt = exp(dif - q * se), ust = exp(dif + q * se), se = se, sd = df)
  }
  rbind(LogCan = f(T$MSC, R$MSC, T$n - 1), LogBatch = f(T$MSB, R$MSB, T$b - 1))
}
pl <- function(v) { s <- platform_ema(v)$sonuc
  m <- cbind(alt = s$alt, ust = s$ust, se = s$se, sd = s$sd); rownames(m) <- s$yol; m }
v <- data.frame(parti = d$Batches, kap = d$Container, asama = d$Stage, urun = d$Product, olcum = d$score)
out <- list(
  "3 evre: platform (a), (b)"           = pl(v)[c("a", "b"), ],
  "3 evre: Chen, kap ortalamasi"        = suppressWarnings(chen(d)),
  "3 evre: Chen, ham satir (tutarsiz)"  = suppressWarnings(chen(d, canmean = FALSE)),
  "m = 1 (B): platform (a), (b)"        = pl(v[v$asama == "B", ])[c("a", "b"), ],
  "m = 1 (B): Chen"                     = suppressWarnings(chen(d[d$Stage == "B", ])))
for (k in names(out)) { cat("\n", k, "\n", sep = ""); print(signif(out[[k]], 11)) }
dif <- c(max(abs(out[[1]] - out[[2]])), max(abs(out[[4]] - out[[5]])))
cat(sprintf("\nEn buyuk mutlak fark: 3 evre %.1e; m = 1 %.1e -> %s\n", dif[1], dif[2],
            if (all(dif < 1e-10)) "AYNI" else "FARKLI"))
})
