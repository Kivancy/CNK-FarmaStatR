# P1 input check (FSR-TN-PLT-01 v0.4, Table 11.1 "Hata yakalama"; G-52 finding).
# Valid inputs pass and give exactly the engine result; inputs the pinned engine
# accepts silently or stops on with an obscure message are rejected with a code;
# inputs the engine rejects itself keep the engine's own message.

base <- list(sigma_R = 0.12, rho = 1, pB = 0, pL = 0.15, q = 0, l = 3, n = 10, m = 3,
             delta = 0, n_sim = 200, seed = 20261015)

test_that("PLT-IN-1: valid input has no problems and gives the engine result unchanged", {
  expect_equal(nrow(platform_check_invitro(base)), 0)
  expect_equal(nrow(platform_check_invitro(list(sigma_R = 0.06))), 0)
  expect_identical(platform_run_invitro(base), do.call(invitro_scenario, base))
  p2 <- modifyList(base, list(l = 2, n = 2, m = 1, pB_T = 0.3, pB_R = 0, alpha = 0.05,
                              sigma_T0 = 0.1, ema_limits = c(0.85, 1.18), keep_reps = TRUE))
  expect_equal(nrow(platform_check_invitro(p2)), 0)
  expect_identical(platform_run_invitro(p2), do.call(invitro_scenario, p2))
})

bad_cases <- list(
  list(f = "sigma_R", v = -0.12, code = "not_positive"),       # G-52: engine runs silently
  list(f = "sigma_R", v = 0,     code = "not_positive"),
  list(f = "rho",     v = 0,     code = "not_positive"),
  list(f = "sigma_T0", v = -0.1, code = "not_positive"),
  list(f = "l",       v = 1,     code = "integer_min_2"),      # G-52: obscure engine error
  list(f = "n",       v = 1,     code = "integer_min_2"),      # G-52: obscure engine error
  list(f = "l",       v = 2.5,   code = "integer_min_2"),
  list(f = "m",       v = 2.5,   code = "integer_min_1"),
  list(f = "m",       v = 0,     code = "integer_min_1"),
  list(f = "q",       v = 1.5,   code = "out_of_unit_interval"),
  list(f = "q",       v = -0.2,  code = "out_of_unit_interval"),
  list(f = "delta",   v = Inf,   code = "not_finite_number"),
  list(f = "delta",   v = NA_real_, code = "not_finite_number"),
  list(f = "sigma_R", v = "0.12", code = "not_finite_number"),
  list(f = "sigma_R", v = c(0.1, 0.2), code = "not_finite_number"),
  list(f = "n_sim",   v = 0,     code = "n_sim_range"),
  list(f = "n_sim",   v = 20001, code = "n_sim_range"),
  list(f = "n_sim",   v = 100.5, code = "n_sim_range"),
  list(f = "seed",    v = 1.5,   code = "seed_integer"),
  list(f = "seed",    v = 3e9,   code = "seed_integer"),
  list(f = "alpha",   v = 0.6,   code = "alpha_range"),
  list(f = "alpha",   v = 0,     code = "alpha_range"),
  list(f = "ema_limits", v = c(1.18, 0.85), code = "ema_limits_order"),
  list(f = "ema_limits", v = 1.18, code = "ema_limits_order"),
  list(f = "keep_reps", v = NA,  code = "not_flag"),
  list(f = "sigmaR",  v = 0.12,  code = "unknown_param"))

test_that("PLT-IN-2: each invalid input is rejected with its code and the run does not start", {
  for (k in bad_cases) {
    p <- base; p[[k$f]] <- k$v
    pr <- platform_check_invitro(p)
    expect_equal(nrow(pr), 1, info = paste(k$f, format(k$v)))
    expect_equal(pr$field, k$f, info = k$code)
    expect_equal(pr$code, k$code, info = paste(k$f, format(k$v)))
    err <- tryCatch(platform_run_invitro(p), error = function(e) e)
    expect_s3_class(err, "farmastat_input_error")
    expect_identical(err$problems, pr)
  }
})

test_that("PLT-IN-3: several problems are reported together; malformed lists are rejected", {
  p <- modifyList(base, list(sigma_R = -1, l = 1, n = 1))
  expect_setequal(platform_check_invitro(p)$field, c("sigma_R", "l", "n"))
  expect_equal(platform_check_invitro(list(0.12))$code, "params_not_named_list")
  expect_equal(platform_check_invitro(0.12)$code, "params_not_named_list")
  expect_equal(platform_check_invitro(list(rho = 1))$code, "missing_param")
  expect_true("duplicate_param" %in% platform_check_invitro(c(base, list(rho = 2)))$code)
  expect_equal(nrow(platform_check_invitro(base, n_sim_max = 200)), 0)
  expect_equal(platform_check_invitro(base, n_sim_max = 199)$code, "n_sim_range")
})

test_that("PLT-IN-4: inputs the engine rejects itself keep the engine's message", {
  engine_cases <- list(list(pB = 0.9), list(pL = -0.1), list(m = 1, q = 0.5))
  for (k in engine_cases) {
    p <- modifyList(base, k)
    expect_equal(nrow(platform_check_invitro(p)), 0)
    e1 <- tryCatch(platform_run_invitro(p), error = conditionMessage)
    e2 <- tryCatch(do.call(invitro_scenario, p), error = conditionMessage)
    expect_identical(e1, e2)
    expect_false(inherits(tryCatch(platform_run_invitro(p), error = function(e) e),
                          "farmastat_input_error"))
  }
})
