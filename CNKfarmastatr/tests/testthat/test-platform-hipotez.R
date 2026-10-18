# P2 T-1/T-2 (FSR-TN-PLT-02 v0.1, KK-49): hypothesis state, KK-38 label, canonical key.
# Grid-based checks (H-1...H-4, S-3, S-4, K-1 ii/iv) are in
# belgeler/teknik_notlar/FSR-TN-PLT-02_ek/p2_kabul.R; here: analytic and domain tests.

sel <- function(h, me) h[h$yontem == me, ]

test_that("H-5: analytic cases of FSR-TN-PLT-01 v0.5 Table 5.3", {
  a <- sel(platform_hipotez(0.12, 1.8, delta = 0), "fda")          # (i)
  expect_close(a$buyukluk, 0.002173, atol = 5e-7, rtol = 0); expect_equal(a$sinif, "H0_ic")
  b <- sel(platform_hipotez(0.06, 1.8, delta = 0), "fda")          # (ii)
  expect_close(b$buyukluk, -0.012827, atol = 5e-7, rtol = 0); expect_equal(b$sinif, "H1")
  c <- platform_hipotez(0.06, 1, delta = log(1.18))                # (iii)
  expect_equal(sel(c, "fda")$sinif, "H0_ic")
  expect_equal(unique(c$sinif[c$yontem != "fda"]), "H0_sinir")
  d <- platform_hipotez(0.12, 1, delta = log(1.155))               # (iv)
  expect_equal(unique(d$sinif[d$yontem != "fda"]), "H1")
  # the general FDA condition at delta = 0: H0 iff rho^2 >= 1 + theta_p max(sR^2, 0.01) / sR^2
  tp <- ((log(1.11))^2 + 0.01) / 0.01
  for (sr in c(0.06, 0.12)) {
    r0 <- sqrt(1 + tp * max(sr^2, 0.01) / sr^2)
    expect_equal(sel(platform_hipotez(sr, r0 * (1 + 1e-6), delta = 0), "fda")$sinif, "H0_ic")
    expect_equal(sel(platform_hipotez(sr, r0 * (1 - 1e-6), delta = 0), "fda")$sinif, "H1")
  }
})

test_that("H-6: KK-38 label only under H0; three classes as in asama2_ozet.R", {
  z <- stats::qnorm(0.95)
  expect_equal(platform_kk38(0.07, 0.002, "H0_sinir"), "nominali_asiyor")
  expect_equal(platform_kk38(0.04, 0.002, "H0_ic"), "kontrol_kanitli")
  expect_equal(platform_kk38(0.05, 0.002, "H0_sinir"), "ayirt_edilemiyor")
  expect_true(is.na(platform_kk38(0.80, 0.004, "H1")))
  # boundaries of the rule: p + z se <= 0.05 controlled; p - z se > 0.05 exceeds
  se <- 0.002
  expect_equal(platform_kk38(0.05 - z * se, se, "H0_sinir"), "kontrol_kanitli")
  expect_equal(platform_kk38(0.05 + z * se + 1e-12, se, "H0_sinir"), "nominali_asiyor")
  h <- platform_hipotez(0.12, 1, sinir = c("fda_delta0", "gmr_1.05"))
  lab <- platform_kk38(0.05, 0.002, h$sinif)
  expect_true(all(is.na(lab[h$sinif == "H1"]))); expect_true(all(!is.na(lab[h$sinif != "H1"])))
  expect_equal(h$metrik[h$sinif == "H1"][1], "guc")
  expect_equal(h$metrik[h$sinif == "H0_sinir"][1], "tip1_sinir")
})

test_that("H-7: extended domain, 11 x 7 pairs (FSR-TN-PLT-02 Section 3.2)", {
  sr <- c(0.01, 0.05, 0.0999, 0.1, 0.1001, 0.12, 0.2, 0.5, 1, 2, 5)
  rh <- c(0.5, 0.8, 1, 1.15, 1.5, 2, 3)
  g <- expand.grid(sr = sr, rh = rh)
  d0 <- CNKfarmastatr:::.platform_delta0(g$sr, g$rh)
  def <- !is.na(d0)
  expect_true(any(def)); expect_true(any(!def))
  for (k in which(def)) {
    for (nm in c("fda_delta0", "fda_minus_delta0")) {
      h <- sel(platform_hipotez(g$sr[k], g$rh[k], sinir = nm), "fda")
      expect_equal(h$sinif, "H0_sinir", info = paste(k, nm))
      expect_lte(abs(h$buyukluk), 1e-12)
      expect_false(h$yakinlik_uyarisi)
    }
    up <- sel(platform_hipotez(g$sr[k], g$rh[k], delta = d0[k] * (1 + 1e-6)), "fda")
    dn <- sel(platform_hipotez(g$sr[k], g$rh[k], delta = d0[k] * (1 - 1e-6)), "fda")
    far <- sel(platform_hipotez(g$sr[k], g$rh[k], delta = d0[k] * (1 + 1e-2)), "fda")
    expect_equal(c(up$sinif, dn$sinif), c("H0_ic", "H1"), info = k)
    expect_equal(c(up$yakinlik_uyarisi, dn$yakinlik_uyarisi), c(d0[k] * 1e-6 <= 1e-4, d0[k] * 1e-6 <= 1e-4))
    expect_equal(far$yakinlik_uyarisi, d0[k] * 1e-2 <= 1e-4, info = k)
  }
  for (k in which(!def)) {
    h <- sel(platform_hipotez(g$sr[k], g$rh[k], delta = 0), "fda")
    expect_equal(h$sinif, "H0_ic", info = k); expect_false(h$yakinlik_uyarisi)
    expect_error(platform_hipotez(g$sr[k], g$rh[k], sinir = "fda_delta0"), "not defined")
  }
  for (k in seq_len(nrow(g))) {
    e <- platform_hipotez(g$sr[k], g$rh[k], sinir = c("ema_1.18", "ema_0.85"))
    expect_equal(unique(e$sinif[e$yontem != "fda"]), "H0_sinir")
    e2 <- platform_hipotez(g$sr[k], g$rh[k], delta = log(c(1.18 * (1 + 1e-6), 1.18 * (1 - 1e-6),
                                                              0.85 * (1 - 1e-6), 0.85 * (1 + 1e-6))))
    ee <- e2[e2$yontem == "ema_c", ]
    expect_equal(ee$sinif, c("H0_ic", "H1", "H0_ic", "H1"), info = k)
    expect_true(all(ee$yakinlik_uyarisi))
  }
})

test_that("K-1 (i, iii): canonical keys", {
  k1 <- platform_anahtar(0.12, gmr = 1.05); k2 <- platform_anahtar(0.12, delta = log(1.05))
  expect_identical(k1, k2)
  expect_false(identical(platform_anahtar(0.12, sinir = "gmr_1.05"), k2))     # name, not number
  expect_identical(platform_anahtar(0.12, pB_T = 0.3, sinir = "fda_delta0"),
                   platform_anahtar(0.12, pB_T = 0.3, pB_R = 0.3, sinir = "fda_delta0"))
  expect_false(grepl("n_sim", platform_anahtar(0.12, delta = 0)))
  expect_match(platform_anahtar(0.12, delta = 0, kosu = TRUE), "\\|n_sim=10000\\|seed=20261015$")
  set.seed(1); x <- c(stats::rnorm(5000, 0, 0.3), exp(stats::runif(5000, -40, 3)))
  back <- as.numeric(CNKfarmastatr:::.num_exact(x))
  expect_identical(back, x)
  expect_error(platform_anahtar(0.12, delta = 0, gmr = 1), "exactly one")
  expect_error(platform_hipotez(0.12, delta = 0, sinir = "gmr_1.00"), "exactly one")
  expect_error(platform_hipotez(0.12, sinir = "xx"), "Unknown boundary")
})
