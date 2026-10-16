# =============================================================================
# FSR-TN-PBE-01 - Stage 2 summary tables and figure (technical note v0.9, Sec. 12)
#   Input: asama1_sonuc.csv (base scenario, Stage 1), asama2_sonuc.csv,
#          asama2_ektekrar.csv. Base R only.
#   Type I error labels (decision KK-38), z = 1.645: "*" exceeds the nominal
#   level (p - z MCSE > 0.05); "+" inconclusive; no mark: controlled.
#   Type I error is read at each method's own boundary: FDA delta0, EMA GMR 1.18
#   (and GMR 0.85 in block E). Power at GMR 1.05. Main design 3 x 10.
# Run from the repository root:  Rscript simulasyon/FSR-TN-PBE-01/asama2_ozet.R
# Output: asama2_ozet_t12_*.csv, sekil/sekil3_asama2.png (300 dpi)
# Research and education only; not a system validated for GxP environments.
# =============================================================================
d <- file.path("simulasyon", "FSR-TN-PBE-01")
s1 <- utils::read.csv(file.path(d, "asama1_sonuc.csv"), stringsAsFactors = FALSE)
s2 <- utils::read.csv(file.path(d, "asama2_sonuc.csv"), stringsAsFactors = FALSE)
z <- stats::qnorm(0.95)
pct <- function(x) formatC(100 * x, format = "f", digits = 1, decimal.mark = ",")
lab <- function(p, se) paste0(pct(p), ifelse(p - z * se > 0.05, "*", ifelse(p + z * se <= 0.05, "", "+")))
meth <- c("fda", "ema_a", "ema_b", "ema_c")
base <- function(x) { x$block <- "S1"; x$factor <- "base"; x }
all <- rbind(base(s1)[, intersect(names(s1), names(s2))][, ], s2[, intersect(names(s1), names(s2))])
all$block <- c(rep("S1", nrow(s1)), s2$block); all$factor <- c(rep("base", nrow(s1)), s2$factor)
cell <- function(x, me, what) {
  k <- if (what == "t1") x$delta_id == (if (me == "fda") "fda_delta0" else "ema_1.18") else x$delta_id == "gmr_1.05"
  y <- x[k, ]; stopifnot(nrow(y) == 1)
  p <- y[[paste0(me, "_pass")]]; se <- y[[paste0(me, "_pass_mcse")]]
  if (what == "t1") lab(p, se) else pct(p)
}
row_of <- function(x, label) data.frame(condition = label,
  t1_fda = cell(x, "fda", "t1"), t1_a = cell(x, "ema_a", "t1"), t1_b = cell(x, "ema_b", "t1"),
  t1_c = cell(x, "ema_c", "t1"), pw_fda = cell(x, "fda", "pw"), pw_c = cell(x, "ema_c", "pw"))
pick <- function(sel) all[sel & all$l == 3 & all$n == 10, ]
sym <- all$pB_T == all$pB_R
basecond <- all$rho == 1 & all$pL == 0.15 & all$q == 0 & all$m == 3 & sym
# --- Table 12.1: sigma_R (scale invariance; EMA dependence), 3 x 10 ----------
t121 <- do.call(rbind, lapply(c(0, 0.3), function(pb) do.call(rbind, lapply(
  c(0.06, 0.08, 0.10, 0.12, 0.16, 0.25, 0.40), function(sr) {
    x <- pick(basecond & all$pB_T == pb & abs(all$sigma_R - sr) < 1e-9 & all$block %in% c("S1", "A"))
    cbind(pB = pb, row_of(x, sr)) }))))
# --- Table 12.2: criterion threshold (Hp4), 3 x 10, with selection error -------
t122 <- do.call(rbind, lapply(c(0, 0.3), function(pb) do.call(rbind, lapply(c(1, 1.15), function(rh)
  do.call(rbind, lapply(c(0.099, 0.10, 0.101), function(sr) {
    x <- pick(all$rho == rh & all$pL == 0.15 & all$q == 0 & all$m == 3 & sym & all$pB_T == pb &
              abs(all$sigma_R - sr) < 1e-9)
    ce <- x$fda_crit_err[x$delta_id == "fda_delta0"]
    r <- cbind(pB = pb, rho = rh, row_of(x, sr)); r$crit_err <- pct(ce); r }))))))
# --- Table 12.3: T/R batch asymmetry (Hp6), 3 x 10 -----------------------------
t123 <- do.call(rbind, lapply(list(c(0, 0), c(0.3, 0), c(0, 0.3), c(0.3, 0.3)), function(pr) {
  x <- all[all$l == 3 & all$n == 10 & all$rho == 1 & all$pL == 0.15 & all$q == 0 & all$m == 3 &
           abs(all$sigma_R - 0.12) < 1e-9 & all$pB_T == pr[1] & all$pB_R == pr[2] &
           all$block %in% c("S1", "C"), ]
  row_of(x, paste0(pr[1], "/", pr[2])) }))
# --- Table 12.4: variance structure (rho, pL, m, q, pB 0.5), 3 x 10 -----------
conds <- list(list("Temel (rho 1, pL 0,15, m 3, q 0)", basecond & abs(all$sigma_R - 0.12) < 1e-9),
              list("rho 1,15", all$rho == 1.15 & all$block == "A"),
              list("rho 0,80 (zorlama)", all$rho == 0.8 & all$block == "A"),
              list("pL 0,01", all$pL == 0.01), list("pL 0,30", all$pL == 0.30),
              list("m 1", all$m == 1), list("m 2", all$m == 2), list("q 0,5", all$q == 0.5))
t124 <- do.call(rbind, lapply(c(0, 0.3), function(pb) do.call(rbind, lapply(conds, function(cd) {
  x <- pick(cd[[2]] & all$pB_T == pb & sym & all$block %in% c("S1", "A"))
  cbind(pB = pb, row_of(x, cd[[1]])) }))))
t124 <- rbind(t124, cbind(pB = 0.5, row_of(pick(all$block == "B"), "pB 0,50 (zorlama)")))
# --- Table 12.5: equal total of 60 units, pB 0.3 ------------------------------
t125 <- do.call(rbind, lapply(list(c(3, 20), c(4, 15), c(5, 12), c(6, 10)), function(ds) {
  x <- all[all$l == ds[1] & all$n == ds[2] & basecond & abs(all$sigma_R - 0.12) < 1e-9 &
           all$pB_T == 0.3 & all$block %in% c("S1", "F"), ]
  row_of(x, paste0(ds[1], " x ", ds[2])) }))
# --- Table 12.6: EMA lower limit (block E), label counts ----------------------
E <- s2[s2$block == "E", ]
t126 <- do.call(rbind, lapply(c("ema_a", "ema_b", "ema_c"), function(me) {
  p <- E[[paste0(me, "_pass")]]; se <- E[[paste0(me, "_pass_mcse")]]
  k <- match(paste(E$pB_T, E$l, E$n), paste(s1$pB_T, s1$l, s1$n)[s1$delta_id == "ema_1.18"])
  up <- s1[s1$delta_id == "ema_1.18", ][k, ]
  pu <- up[[paste0(me, "_pass")]]; seu <- up[[paste0(me, "_pass_mcse")]]
  cls <- function(p, se) ifelse(p - z * se > 0.05, "exceeds", ifelse(p + z * se <= 0.05, "controlled", "inconclusive"))
  data.frame(method = me, limit = c("0,85", "1,18"),
             controlled = c(sum(cls(p, se) == "controlled"), sum(cls(pu, seu) == "controlled")),
             inconclusive = c(sum(cls(p, se) == "inconclusive"), sum(cls(pu, seu) == "inconclusive")),
             exceeds = c(sum(cls(p, se) == "exceeds"), sum(cls(pu, seu) == "exceeds")),
             max = c(pct(max(p)), pct(max(pu))))
}))
# --- EMA (c) boundary share (REML pooling), Stage 2 blocks A and B ------------
pool <- aggregate(cbind(T = ema_c_pooled_T, R = ema_c_pooled_R) ~ pB_T + l + n,
                  s2[s2$block %in% c("A", "B"), ], mean)
for (nm in c("t121", "t122", "t123", "t124", "t125", "t126"))
  utils::write.csv(get(nm), file.path(d, paste0("asama2_ozet_", sub("t", "t", nm), ".csv")), row.names = FALSE)
utils::write.csv(pool, file.path(d, "asama2_ozet_havuz.csv"), row.names = FALSE)
# --- Figure 3: type I error and power vs sigma_R (3 x 10) ---------------------
ink <- "#0b0b0b"; ink2 <- "#52514e"; grid_col <- "#e4e3df"
mlab <- c(fda = "FDA PBE", ema_a = "EMA (a) havuzlanmış", ema_b = "EMA (b) seri ort.", ema_c = "EMA (c) REML")
mcol <- c(fda = "#2a78d6", ema_a = "#eb6834", ema_b = "#1baf7a", ema_c = "#eda100")
mpch <- c(fda = 16, ema_a = 17, ema_b = 15, ema_c = 18)
srs <- c(0.06, 0.08, 0.099, 0.10, 0.101, 0.12, 0.16, 0.25, 0.40)
xs <- seq_along(srs); xl <- formatC(srs, format = "fg", decimal.mark = ",")
getv <- function(pb, sr, me, what) {
  x <- all[all$l == 3 & all$n == 10 & basecond & all$pB_T == pb & abs(all$sigma_R - sr) < 1e-9, ]
  dd <- if (what == "t1") (if (me == "fda") "fda_delta0" else "ema_1.18") else "gmr_1.05"
  x[[paste0(me, "_pass")]][x$delta_id == dd][1]
}
mc2 <- 2 * sqrt(0.05 * 0.95 / 10000)
dir.create(file.path(d, "sekil"), showWarnings = FALSE)
png(file.path(d, "sekil", "sekil3_asama2.png"), width = 16, height = 11.5, units = "cm", res = 300, pointsize = 9)
layout(rbind(1:2, 3:4, 5), heights = c(1, 1, 0.18))
par(mar = c(3.4, 3.4, 1.6, 0.6), bg = "white", family = "sans")
for (what in c("t1", "pw")) for (pb in c(0, 0.3)) {
  yl <- if (what == "t1") c(0, 0.25) else c(0, 1); ya <- if (what == "t1") seq(0, 0.25, 0.05) else seq(0, 1, 0.2)
  plot(NA, xlim = c(1, length(srs)), ylim = yl, axes = FALSE, xlab = "", ylab = "")
  abline(h = ya, col = grid_col, lwd = 0.8)
  axis(1, at = xs, labels = xl, col = ink2, col.axis = ink2, cex.axis = 0.72, lwd = 0.6, tcl = -0.25)
  axis(2, at = ya, labels = paste0(ya * 100), las = 1, col = ink2, col.axis = ink2, cex.axis = 0.8, lwd = 0.6, tcl = -0.25)
  abline(v = 4, lty = 3, col = ink2, lwd = 0.8)
  if (what == "t1") { rect(0, 0.05 - mc2, 10, 0.05 + mc2, col = "#f0efec", border = NA); abline(h = 0.05, lty = 2, col = ink2, lwd = 0.8) }
  else abline(h = 0.80, lty = 2, col = ink2, lwd = 0.8)
  mtext(bquote(.(if (what == "t1") "Tip I hata" else "Güç, GMR 1,05") * ", " * p[B] == .(format(pb, decimal.mark = ","))),
        3, 0.3, cex = 0.78, col = ink, font = 2)
  mtext(expression(sigma[R] ~ "(3 × 10; noktalı çizgi: 0,1 eşiği)"), 1, 2.1, cex = 0.66, col = ink2)
  mtext(if (what == "t1") "Tip I hata (%)" else "Güç (%)", 2, 2.2, cex = 0.7, col = ink2)
  for (me in if (what == "t1") names(mlab) else c("fda", "ema_c")) {
    y <- sapply(srs, getv, pb = pb, me = me, what = what)
    lines(xs, y, col = mcol[me], lwd = 1.6); points(xs, y, col = mcol[me], pch = mpch[me], cex = 0.9)
  }
}
par(mar = c(0, 0, 0, 0)); plot.new()
legend("center", legend = mlab, col = mcol, pch = mpch, lwd = 1.6, ncol = 4, bty = "n", cex = 0.8,
       text.col = ink, text.width = 0.2, x.intersp = 0.6)
dev.off()
print(t121); print(t122); print(t123); print(t124); print(t125); print(t126); print(pool)
