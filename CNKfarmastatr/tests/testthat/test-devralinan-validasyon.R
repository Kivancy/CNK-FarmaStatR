# Inherited validation test sets (v0.5.1), run unchanged against the package code.
# Each legacy script fills a results table (`.sonuclar`, or `.kt` for the PBE
# bridge), one row per check; every row must pass.
# Expected counts are the documented validation counts (FSR-LOG-01, G-01/G-03).

run_legacy <- function(subdir, script, setup = character(), result = ".sonuclar") {
  dir <- system.file("validasyon", subdir, package = "CNKfarmastatr")
  expect_true(nzchar(dir))
  old <- setwd(dir); on.exit(setwd(old), add = TRUE)
  env <- globalenv()   # legacy scripts assign with <<- and source() nested files
  for (f in setup) source(f, local = env, encoding = "UTF-8")   # reference values
  suppressWarnings(invisible(capture.output(source(script, local = env, encoding = "UTF-8"))))
  res <- get(result, envir = env)
  rm(list = intersect(ls(env, all.names = TRUE), result), envir = env)
  res
}

expect_all_pass <- function(res, n) {
  failed <- res[res$durum != "GEÇTİ", c("TC", "kontrol")]
  expect_equal(nrow(res), n)
  expect_equal(nrow(failed), 0, info = paste(failed$TC, failed$kontrol, collapse = "; "))
}

test_that("1A model-independent MSD: 60/60 (Tsong 1996, analytic cases)", {
  expect_all_pass(run_legacy("dissolusyon", "msd_tests.R"), 60)
})

test_that("1B Weibull MSD: 98/98 (Sathe 1996, analytic cases, time-unit invariance)", {
  expect_all_pass(run_legacy("dissolusyon", "msd_weibull_tests.R"), 98)
})

test_that("2 f2 and bootstrap f2, EMA and FDA perspectives: 120/120 (Noce 2020, Xu 2021)", {
  skip_on_cran()   # bootstrap replicates: about 10-60 s
  expect_all_pass(run_legacy("dissolusyon", "f2_tests.R"), 120)
})

test_that("PBE core: 213/213 (FDA PSG 020929, independent Python reference)", {
  expect_all_pass(run_legacy("pbe", "pbe_tests.R", setup = "referans_python.R"), 213)
})

test_that("PBE bridge (input checks B-2, B-4): 25/25 (bridge = core; invalid input rejected)", {
  expect_all_pass(run_legacy("pbe", "pbe_kopru_tests.R", result = ".kt"), 25)
})
