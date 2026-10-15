# =============================================================================
# FSR-TN-PBE-01 v0.5 - Figures of Stage 1 (from asama1_sonuc.csv), base R only
# Run from the repository root:  Rscript simulasyon/FSR-TN-PBE-01/asama1_sekil.R
# Output: sekil/sekil1_tip1.png, sekil/sekil2_guc.png (300 dpi)
# Colours: categorical slots 1-4 for methods (+ distinct point symbols, so that
#   identity never depends on colour alone); one-hue ramp for l (magnitude).
# =============================================================================
d <- file.path("simulasyon", "FSR-TN-PBE-01")
r <- utils::read.csv(file.path(d, "asama1_sonuc.csv"))
dir.create(file.path(d, "sekil"), showWarnings = FALSE)
ink <- "#0b0b0b"; ink2 <- "#52514e"; grid_col <- "#e4e3df"
meth <- c(fda = "FDA PBE", ema_a = "EMA (a) havuzlanmış", ema_b = "EMA (b) seri ort.",
          ema_c = "EMA (c) REML")
mcol <- c(fda = "#2a78d6", ema_a = "#eb6834", ema_b = "#1baf7a", ema_c = "#eda100")
mpch <- c(fda = 16, ema_a = 17, ema_b = 15, ema_c = 18)
pBs <- c(0, 0.10, 0.30)
nul <- function(me) if (me == "fda") "fda_delta0" else "ema_1.18"
mc2 <- 2 * sqrt(0.05 * 0.95 / 10000)
panel <- function(xlim, ylim, xat, main, xlab, ylab, yat) {
  plot(NA, xlim = xlim, ylim = ylim, axes = FALSE, xlab = "", ylab = "")
  abline(h = yat, col = grid_col, lwd = 0.8)
  axis(1, at = xat, col = ink2, col.axis = ink2, cex.axis = 0.8, lwd = 0.6, tcl = -0.25)
  axis(2, at = yat, labels = paste0(yat * 100), las = 1, col = ink2, col.axis = ink2,
       cex.axis = 0.8, lwd = 0.6, tcl = -0.25)
  mtext(main, 3, 0.3, cex = 0.78, col = ink, font = 2)
  mtext(xlab, 1, 1.9, cex = 0.7, col = ink2); mtext(ylab, 2, 2.2, cex = 0.7, col = ink2)
}
# --- Figure 1: type I error vs n (l = 3) and vs l (n = 10) -----------------
png(file.path(d, "sekil", "sekil1_tip1.png"), width = 16, height = 11.5, units = "cm",
    res = 300, pointsize = 9)
layout(rbind(1:3, 4:6, 7), heights = c(1, 1, 0.18))
par(mar = c(3.2, 3.4, 1.6, 0.6), bg = "white", family = "sans")
for (row in 1:2) for (p in pBs) {
  xv <- if (row == 1) c(5, 8, 10, 15, 20, 30) else 2:6
  panel(range(xv), c(0, 0.33), xv,
        bquote(p[B] == .(format(p, decimal.mark = ","))),
        if (row == 1) "n (birim/seri), ℓ = 3" else "ℓ (seri), n = 10",
        "Tip I hata (%)", seq(0, 0.3, 0.05))
  rect(min(xv) - 1, 0.05 - mc2, max(xv) + 1, 0.05 + mc2, col = "#f0efec", border = NA)
  abline(h = 0.05, lty = 2, col = ink2, lwd = 0.8)
  for (me in names(meth)) {
    y <- r[r$delta_id == nul(me) & r$pB_T == p & (if (row == 1) r$l == 3 else r$n == 10), ]
    y <- y[order(if (row == 1) y$n else y$l), ]
    xx <- if (row == 1) y$n else y$l
    lines(xx, y[[paste0(me, "_pass")]], col = mcol[me], lwd = 1.6)
    points(xx, y[[paste0(me, "_pass")]], col = mcol[me], pch = mpch[me], cex = 0.9)
  }
}
par(mar = c(0, 0, 0, 0)); plot.new()
legend("center", legend = meth, col = mcol, pch = mpch, lwd = 1.6, ncol = 4,
       bty = "n", cex = 0.8, text.col = ink, text.width = 0.2, x.intersp = 0.6)
dev.off()
# --- Figure 2: power at GMR 1.05, FDA and EMA (c), lines by l ---------------
lcol <- c("#86b6ef", "#5598e7", "#2a78d6", "#1c5cab", "#104281")
png(file.path(d, "sekil", "sekil2_guc.png"), width = 16, height = 11.5, units = "cm",
    res = 300, pointsize = 9)
layout(rbind(1:3, 4:6, 7), heights = c(1, 1, 0.18))
par(mar = c(3.2, 3.4, 1.6, 0.6), bg = "white", family = "sans")
nv <- c(5, 8, 10, 15, 20, 30)
for (me in c("fda", "ema_c")) for (p in pBs) {
  panel(c(5, 30), c(0, 1), nv,
        bquote(.(meth[[me]]) ~ "·" ~ p[B] == .(format(p, decimal.mark = ","))),
        "n (birim/seri)", "Güç (%)", seq(0, 1, 0.2))
  abline(h = 0.8, lty = 2, col = ink2, lwd = 0.8)
  for (l in 2:6) {
    y <- r[r$delta_id == "gmr_1.05" & r$pB_T == p & r$l == l, ]; y <- y[order(y$n), ]
    lines(y$n, y[[paste0(me, "_pass")]], col = lcol[l - 1], lwd = 1.6)
    points(y$n, y[[paste0(me, "_pass")]], col = lcol[l - 1], pch = 16, cex = 0.7)
  }
}
par(mar = c(0, 0, 0, 0)); plot.new()
legend("center", legend = paste0("ℓ = ", 2:6), col = lcol, pch = 16, lwd = 1.6,
       ncol = 5, bty = "n", cex = 0.8, text.col = ink, text.width = 0.1, x.intersp = 0.6)
dev.off()
