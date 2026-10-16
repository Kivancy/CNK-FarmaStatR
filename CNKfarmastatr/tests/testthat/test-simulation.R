# Simulation framework (sim_performance, sim_run, run record, export)
# Test cases TC-S1 ... TC-S10. Expected values of TC-S1 are computed by hand
# from the formulas of Morris, White & Crowther (2019), Table 6.
# Acceptance rules (FSR-VAL-SIM-1 v0.2, KK-41): expect_close() = combined absolute
# and relative tolerance (helper-tolerance.R); Monte Carlo checks |z| < 4.

perf_value <- function(tab, m, col = "estimate") tab[tab$measure == m, col]

test_that("TC-S1 performance measures and MCSE equal the hand-computed values", {
  # est = 1..5, theta = 2.5:  mean 3, sum of squared deviations 10, n = 5
  est <- 1:5; truth <- 2.5
  se <- c(1, 1, 2, 2, 2)            # se^2 = 1,1,4,4,4: mean 2.8, var 2.7
  lower <- est - 1; upper <- est + 1
  p <- c(0.01, 0.04, 0.05, 0.20, 0.90)
  tab <- sim_performance(est, truth, se, lower, upper, p, alpha = 0.05)
  tol <- 1e-12
  # Bias = 3 - 2.5;            MCSE = sqrt(10 / (5 * 4))
  expect_close(perf_value(tab, "bias"), 0.5, atol = tol, rtol = tol)
  expect_close(perf_value(tab, "bias", "mcse"), sqrt(0.5), atol = tol, rtol = tol)
  # EmpSE = sqrt(10 / 4);      MCSE = EmpSE / sqrt(8)
  expect_close(perf_value(tab, "empse"), sqrt(2.5), atol = tol, rtol = tol)
  expect_close(perf_value(tab, "empse", "mcse"), 0.5590169943749475, atol = tol, rtol = tol)
  # MSE: (est - 2.5)^2 = 2.25, .25, .25, 2.25, 6.25 -> 2.25; MCSE = sqrt(24 / 20)
  expect_close(perf_value(tab, "mse"), 2.25, atol = tol, rtol = tol)
  expect_close(perf_value(tab, "mse", "mcse"), sqrt(1.2), atol = tol, rtol = tol)
  # ModSE = sqrt(2.8);         MCSE = sqrt(2.7 / (4 * 5 * 2.8))
  expect_close(perf_value(tab, "modse"), sqrt(2.8), atol = tol, rtol = tol)
  expect_close(perf_value(tab, "modse", "mcse"), 0.21957751641341997, atol = tol, rtol = tol)
  # Relative error = 100 (sqrt(2.8 / 2.5) - 1)
  expect_close(perf_value(tab, "relerr_modse"), 5.830052442583611, atol = 1e-10, rtol = 1e-10)
  expect_close(perf_value(tab, "relerr_modse", "mcse"), 39.91061441342569, atol = 1e-10, rtol = 1e-10)
  # Coverage of 2.5 by [0,2],[1,3],[2,4],[3,5],[4,6] = 2/5; of mean 3 = 3/5
  expect_close(perf_value(tab, "coverage"), 0.4, atol = tol, rtol = tol)
  expect_close(perf_value(tab, "coverage", "mcse"), sqrt(0.24 / 5), atol = tol, rtol = tol)
  expect_close(perf_value(tab, "be_coverage"), 0.6, atol = tol, rtol = tol)
  # Rejection at alpha = 0.05: p <= 0.05 in 3 of 5
  expect_close(perf_value(tab, "rejection"), 0.6, atol = tol, rtol = tol)
  expect_close(perf_value(tab, "rejection", "mcse"), sqrt(0.24 / 5), atol = tol, rtol = tol)
})

test_that("TC-S2 missing estimates are excluded and counted", {
  tab <- sim_performance(c(1:5, NA, NaN), truth = 2.5)
  expect_equal(attr(tab, "n_missing"), 2L, tolerance = 0)
  expect_close(perf_value(tab, "bias"), 0.5, atol = 1e-12, rtol = 1e-12)
  expect_error(sim_performance(1:5), "truth")
})

test_that("TC-S3 number of replicates for a target MCSE", {
  expect_equal(sim_n_required(mcse = 0.005, p = 0.95), 1900, tolerance = 0)      # 0.0475 / 0.000025
  expect_equal(sim_n_required(mcse = 0.01, var_est = 0.25), 2500, tolerance = 0)
  expect_error(sim_n_required(0.01))
})

test_that("TC-S4 same seed reproduces the run; caller's RNG is untouched", {
  RNGkind("default", "default", "default"); set.seed(99); u <- runif(1)
  set.seed(99)
  a <- sim_run("demo_mean_ci", n_sim = 200, seed = 7)
  expect_identical(runif(1), u)                              # caller's stream restored
  b <- sim_run("demo_mean_ci", n_sim = 200, seed = 7)
  c <- sim_run("demo_mean_ci", n_sim = 200, seed = 8)
  expect_identical(a$raw, b$raw)
  expect_false(identical(a$raw$est, c$raw$est))
  expect_identical(a$record$rng_kind, c("Mersenne-Twister", "Inversion", "Rejection"))
  expect_identical(a$record$seed, 7)
  expect_true(all(c("r_version", "package_version", "params", "started") %in% names(a$record)))
})

test_that("TC-S5 demo scenario reproduces the analytic values within 4 MCSE", {
  # common Monte Carlo acceptance rule |z| < 4 (FSR-VAL-SIM-1 v0.2, KK-41);
  # 3 <= |z| < 4 is reported as a warning by the evidence script, not here
  r <- sim_run("demo_mean_ci", params = list(n = 10L), n_sim = 4000, seed = 2026)
  pf <- r$performance
  within <- function(m, meas, true) {
    row <- pf[pf$method == m & pf$measure == meas, ]
    abs(row$estimate - true) < 4 * row$mcse
  }
  expect_true(within("t", "coverage", 0.95))
  expect_true(within("z", "coverage", 2 * pt(qnorm(0.975), 9) - 1))   # 0.9183509
  expect_true(within("t", "rejection", 0.05))
  expect_true(within("t", "bias", 0))
  # t and z share the estimate, so bias and EmpSE are identical
  expect_identical(pf$estimate[pf$method == "t" & pf$measure == "bias"],
                   pf$estimate[pf$method == "z" & pf$measure == "bias"])
})

test_that("TC-S6 user parameters override the defaults; invalid ones are rejected", {
  r <- sim_run("demo_mean_ci", params = list(n = 125, dist = "lognormal"), n_sim = 50, seed = 1)
  expect_equal(r$record$params$n, 125, tolerance = 0)
  expect_close(r$record$ademp$truth, exp(0.5), atol = 1e-12, rtol = 1e-12)
  expect_equal(r$record$params$sigma, 1, tolerance = 0)                     # default kept
  expect_error(sim_run("demo_mean_ci", params = list(N = 5)), "Unknown parameter")
  expect_error(sim_run("demo_mean_ci", params = list(n = 1)), "n must be")
  expect_error(sim_run("no_such_scenario"), "Unknown scenario")
})

test_that("TC-S7 the exported R script reproduces the run exactly", {
  r <- sim_run("demo_mean_ci", params = list(n = 12L, mu = 0.1, conf = 0.9), n_sim = 300, seed = 31)
  txt <- sim_export_script(r)
  expect_match(txt, "params <- list(n = 12L, mu = 0.1, sigma = 1, dist = \"normal\", conf = 0.9)", fixed = TRUE)
  env <- new.env()
  invisible(capture.output(eval(parse(text = txt), envir = env)))
  expect_identical(env$res$raw, r$raw)
  expect_identical(env$res$performance, r$performance)
})

test_that("TC-S8 run record as JSON: exact numbers, required fields", {
  expect_identical(as.numeric(.num_exact(0.1 + 0.2)), 0.1 + 0.2)
  expect_identical(.num_exact(c(0.95, 2026, 1/3)), c("0.95", "2026", "0.3333333333333333"))
  r <- sim_run("demo_mean_ci", n_sim = 20, seed = 3)
  js <- sim_record_json(r)
  expect_match(js, "^\\{\"record\":\\{")
  for (k in c("\"rng_kind\":[\"Mersenne-Twister\",\"Inversion\",\"Rejection\"]",
              "\"seed\":3", "\"n_sim\":20", "\"package_version\":", "\"r_version\":",
              "\"disclaimer\":", "\"performance\":"))
    expect_match(js, k, fixed = TRUE)
  expect_identical(.to_json(list(a = NA, b = "x\"y", c = c(TRUE, FALSE))),
                   "{\"a\":null,\"b\":\"x\\\"y\",\"c\":[true,false]}")
})

test_that("TC-S9 failing replicates are caught, counted and do not stop the run", {
  scn <- sim_scenario(
    id = "test_failures", title = "failures", aim = "test", dgm_text = "uniform",
    dgm = function(p) runif(1), estimand = "none", truth = 0.5,
    methods = list(fragile = function(x, p) { if (x < 0.3) stop("too small"); c(est = x) },
                   robust  = function(x, p) c(est = x)),
    params = list())
  r <- sim_run(scn, n_sim = 500, seed = 5)
  f <- r$record$failed
  expect_true(f$fragile > 100 && f$fragile < 200)            # about 30% of 500
  expect_equal(f$robust, 0, tolerance = 0)
  expect_equal(sum(r$raw$method == "fragile" & !is.na(r$raw$error)), f$fragile, tolerance = 0)
  expect_true(all(r$raw$error[!is.na(r$raw$error)] == "too small"))
})

test_that("TC-S10 a single replicate can be regenerated from the stored RNG state", {
  r <- sim_run("demo_mean_ci", n_sim = 30, seed = 11, keep_states = TRUE)
  x17 <- sim_replicate(r, 17)
  expect_identical(mean(x17), r$raw$est[r$raw$rep == 17 & r$raw$method == "t"])
  expect_error(sim_replicate(sim_run("demo_mean_ci", n_sim = 5, seed = 1), 1), "keep_states")
})
