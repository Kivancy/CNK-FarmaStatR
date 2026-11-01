# Deterministic check: numerical example of Chow, Shao and Wang (2003) Section 5, Table III.
source("csw2003.R")
v <- scan(text = "
0.561666 1.125871 -0.039464 -0.432529
0.798124 1.430523 0.307254 0.267646
0.436184 -0.222413 0.253502 -0.119584
-0.024528 0.393267 -0.648004 -1.177679
-0.090290 -0.627502 0.301081 -0.494485
-0.272998 -0.153278 -0.616031 -0.191127
0.218929 -0.727645 -0.308066 0.234591
-0.540058 -0.053589 0.365324 -0.522845
-0.764153 0.368896 -0.151981 -0.391525
0.806935 1.073829 -0.313767 0.146926
0.285985 -0.079857 0.570084 -0.689592
-0.202443 -0.131901 -0.770030 -0.251785
0.443907 -0.043639 0.015629 0.458543
-0.164041 -0.688999 -0.468089 -0.501593
-1.065702 0.403384 0.167847 -0.268849
-0.320509 -0.584669 0.551757 0.733643
0.390335 -0.033335 0.069074 0.181878
-0.547364 0.351125 -0.006792 0.042096
0.113892 0.321204 -1.563092 -0.869159
-0.201228 0.978660 -0.221517 -0.407714
0.416043 -0.643256 0.624500 0.594661
-0.462978 0.780152 0.171163 1.107604
0.523478 -0.851068 0.386695 -0.810703
0.179169 0.040342 -1.273343 -0.050407
0.486552 0.564771 0.463084 0.172705
1.122766 0.070407 0.214514 0.385597
0.748173 0.236006 -0.208575 -0.301824
1.440898 0.262185 0.628295 -0.131757
-0.327088 0.314147 -0.562163 -1.000834
0.719226 0.428375 -0.794484 0.050426", quiet = TRUE)
M <- matrix(v, ncol = 4, byrow = TRUE)
# Table III column headers are swapped relative to the printed statistics (delta < 0 only
# with the "Reference" columns as test); the statistics are reproduced with the swap.
calc <- function(M) {
  XT <- array(M[, 3:4], c(1, 30, 2)); XR <- array(M[, 1:2], c(1, 30, 2))
  st <- csw_stats(XT); sr <- csw_stats(XR)
  b2 <- csw_bound(st$g - sr$g, st$sB, sr$sB, st$sW, sr$sW, 30, 30, 2, 2)
  # without replicates: first observation of each canister, FDA 1999 bound (n = 1)
  st1 <- csw_stats(XT[, , 1, drop = FALSE]); sr1 <- csw_stats(XR[, , 1, drop = FALSE])
  b1 <- csw_bound(st1$g - sr1$g, st1$sB, sr1$sB, 0, 0, 30, 30, 1, 1)
  c(st$g - sr$g, st$sB, sr$sB, st$sW, sr$sW, st$sB + st$sW/2, sr$sB + sr$sW/2, b2$U, b2$eta_U,
    st1$g - sr1$g, st1$sB, sr1$sB, b1$U, b1$eta_U)
}
# Candidate correction found by searching single-digit changes in the second replicate
# (only that column disagrees; replicate 1 alone reproduces the n = 1 results):
# row 17, printed -0.033335 -> -0.053335 (the only change that matches all printed statistics).
Mc <- M; Mc[17, 2] <- -0.053335
out <- data.frame(
  quantity  = c("delta", "s2BT", "s2BR", "s2WT", "s2WR", "s2T", "s2R", "U", "eta_U",
                "delta (n=1)", "s2T (n=1)", "s2R (n=1)", "U (n=1)", "eta_U (n=1)"),
  published = c(-0.268069, 0.197011, 0.185969, 0.182724, 0.287895, 0.292889, 0.329916, 0.062129, -0.091582,
                -0.252149, 0.307987, 0.331149, 0.120758, 0.015377),
  as_printed = calc(M), corrected = calc(Mc))
out$diff_printed   <- out$as_printed - out$published
out$diff_corrected <- out$corrected - out$published
out$agree_corrected <- abs(out$diff_corrected) <= 1e-6      # 6 printed decimals
print(out, digits = 8)
write.csv(out, "csw2003_ornek.csv", row.names = FALSE)
# Note: published s2T = 0.292889 is not s2BT + s2WT/2 = 0.197011 + 0.182724/2 = 0.288373 (printing error).
