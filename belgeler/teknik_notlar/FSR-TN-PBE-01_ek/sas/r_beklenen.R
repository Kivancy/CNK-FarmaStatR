# =============================================================================
# FSR-TN-PBE-01 Ek B - SAS cross-check: data sets and R expected values
#   Builds sas_veri.csv (input for sas_kontrol.sas) and r_beklenen.csv
#   (R results to compare with the SAS output).
# Data sets:
#   K01-K06  Chow & Liu (2008) Tables 14.5.2-14.5.3 (D50, SPAN x 3, 5, 7 cm)
#   K07      FDA PSG 020929 example (simulated data in the guidance)
#   K08-K11  simulated with invitro_gen (chosen to cover every REML case)
# Run from the repository root (package installed):
#   Rscript belgeler/teknik_notlar/FSR-TN-PBE-01_ek/sas/r_beklenen.R
# Research and education only; not a system validated for GxP environments.
# =============================================================================
library(CNKfarmastatr)
ek <- file.path("belgeler", "teknik_notlar", "FSR-TN-PBE-01_ek")
out <- file.path(ek, "sas")
iv <- asNamespace("CNKfarmastatr")

long_from_array <- function(X, l, n, set, prod) {
  m <- dim(X)[3]; g <- expand.grid(u = seq_len(l * n), s = seq_len(m))
  data.frame(set = set, product = prod, batch = paste0(prod, (g$u - 1) %/% n + 1),
             unit = (g$u - 1) %% n + 1, stage = g$s, y = X[cbind(1, g$u, g$s)])
}
sets <- list()
# K01-K06: Chow raw data, log scale
d <- utils::read.csv(file.path(ek, "chow1452.csv"))
k <- 0
for (v in c("D50", "SPAN")) for (dist in c(3, 5, 7)) {
  k <- k + 1; id <- sprintf("K%02d", k)
  x <- d[d$var == v & d$dist == dist, ]
  sets[[id]] <- data.frame(set = id, product = ifelse(x$prod == "Test", "T", "R"),
                           batch = x$lot, unit = x$bottle,
                           stage = match(x$stage, c("Beg", "Mid", "End")), y = log(x$y))
}
# K07: PSG 020929 example, used as given (no transformation; as in calc_pbe tests)
p <- ornek_psg020929()
sets[["K07"]] <- data.frame(set = "K07", product = ifelse(p$Product == "TEST", "T", "R"),
                            batch = paste0("B", p$Batches), unit = p$Container,
                            stage = match(p$Stage, c("B", "M", "E")), y = p$score)
# K08-K11: simulated (l, n, sB, sC, sW) per product; fixed seeds
sim <- list(K08 = list(3, 10, c(.08, .06, .03), c(.08, .06, .03), 101),
            K09 = list(3, 10, c(0, .06, .03),   c(.05, .06, .03), 102),
            K10 = list(3, 5,  c(0, 0, .05),     c(0, .02, .05),   103),
            K11 = list(2, 5,  c(.05, .03, .02), c(0, 0, .04),     104))
for (id in names(sim)) {
  s <- sim[[id]]; set.seed(s[[5]])
  XT <- invitro_gen(1, s[[1]], s[[2]], 3, mu = 0.03, sB = s[[3]][1], sC = s[[3]][2], sW = s[[3]][3])
  XR <- invitro_gen(1, s[[1]], s[[2]], 3, mu = 0,    sB = s[[4]][1], sC = s[[4]][2], sW = s[[4]][3])
  sets[[id]] <- rbind(long_from_array(XT, s[[1]], s[[2]], id, "T"),
                      long_from_array(XR, s[[1]], s[[2]], id, "R"))
}
dat <- do.call(rbind, sets); rownames(dat) <- NULL
dat$batch <- paste(dat$product, dat$batch, sep = "_")       # unique across products
utils::write.csv(dat, file.path(out, "sas_veri.csv"), row.names = FALSE)

# ---- expected values --------------------------------------------------------
case_of <- function(s) {           # which strata REML pools (isotonic regression)
  N <- s$N; l <- s$l; n <- s$n; m <- s$m
  s2b <- rowSums((s$Bm - s$g)^2) / (l - 1)
  ms <- c(lot = n * m * s2b,
          unit = m * rowSums((s$U - s$Bm[, s$bidx, drop = FALSE])^2) / (l * (n - 1)),
          res = s$msw_resid)
  df <- c(l - 1, l * (n - 1), (N - 1) * (m - 1))
  th <- ms
  if (ms["unit"] < ms["res"]) th[2:3] <- sum(df[2:3] * ms[2:3]) / sum(df[2:3])
  if (th["lot"] < th["unit"]) {
    if (ms["unit"] >= ms["res"] && sum(df[1:2] * ms[1:2]) / sum(df[1:2]) >= ms["res"]) {
      th[1:2] <- sum(df[1:2] * ms[1:2]) / sum(df[1:2])
    } else th[1:3] <- sum(df * ms) / sum(df)
  }
  case <- if (all(th == ms)) "none" else if (th[1] == th[3]) "all" else
          if (th[1] == th[2]) "lot+unit" else "unit+res"
  list(ms = ms, th = th, case = case,
       vc = c(sB2 = (th[[1]] - th[[2]]) / (n * m), sC2 = (th[[2]] - th[[3]]) / m, sW2 = th[[3]]))
}
res <- list()
for (id in names(sets)) {
  x <- dat[dat$set == id, ]
  A <- lapply(c(T = "T", R = "R"), function(pr) invitro_array(x[x$product == pr, c("batch", "unit", "stage", "product", "y")], pr))
  st <- lapply(A, function(a) { s <- iv$.iv_stats(a$X, a$l, a$n); s$msw_resid <- iv$.iv_msw_resid(a$X); s })
  e <- ema_ci_fast(A$T$X, A$R$X, A$T$l, A$T$n, A$R$l, A$R$n)
  f <- pbe_fast(A$T$X, A$R$X, A$T$l, A$T$n, A$R$l, A$R$n)
  ca <- lapply(st, case_of)
  row <- data.frame(set = id, l = A$T$l, n = A$T$n, m = A$T$m,
                    mean_T = st$T$g, mean_R = st$R$g, diff = st$T$g - st$R$g,
                    msb_psg_T = f$msb_t, msw_psg_T = f$msw_t, msb_psg_R = f$msb_r, msw_psg_R = f$msw_r)
  for (pr in c("T", "R")) {
    row[[paste0("ms_lot_", pr)]] <- ca[[pr]]$ms[["lot"]]
    row[[paste0("ms_unit_", pr)]] <- ca[[pr]]$ms[["unit"]]
    row[[paste0("ms_res_", pr)]] <- ca[[pr]]$ms[["res"]]
    row[[paste0("reml_case_", pr)]] <- ca[[pr]]$case
    for (v in names(ca[[pr]]$vc)) row[[paste0(v, "_", pr)]] <- ca[[pr]]$vc[[v]]
  }
  for (me in c("a", "b", "c")) {
    row[[paste0("se_", me)]] <- e[[me]]$se; row[[paste0("df_", me)]] <- e[[me]]$df
    row[[paste0("lower90_", me)]] <- e[[me]]$lower; row[[paste0("upper90_", me)]] <- e[[me]]$upper
  }
  res[[id]] <- row
}
res <- do.call(rbind, res)
utils::write.csv(res, file.path(out, "r_beklenen.csv"), row.names = FALSE)
print(res[, c("set", "reml_case_T", "reml_case_R", "diff", "se_b", "se_c", "df_c")], digits = 6)
