# Platform tier 3: stand-alone R script for one in vitro scenario
# FSR-TN-PLT-03 v0.1, Table 8.1 (E-1, E-3 ... E-9; decisions KK-51). The full
# 36-run set of E-1, E-2 (browser) and E-10 (R --vanilla, no package) run in
# belgeler/teknik_notlar/FSR-TN-PLT-03_ek/p3_kabul.R.

src_dir <- function() {
  # repository folder with the R sources (tests run from <repo>/CNKfarmastatr/tests/testthat
  # or from the repository root in CI)
  for (d in c("../../R", "CNKfarmastatr/R", "../../../CNKfarmastatr/R"))
    if (file.exists(file.path(d, "invitro_grid.R"))) return(d)
  NA_character_
}
have_src <- !is.na(src_dir())
files <- if (have_src) platform_motor_dosyalari(src_dir())
pinned <- platform_cekirdek_sha()

exp_script <- function(params, sinir = NULL, ...)
  platform_export_invitro(params, sinir = sinir, dosyalar = files, cekirdek_sha = pinned,
                          zaman = as.POSIXct("2026-10-18 12:00:00", tz = "UTC"), ...)

# Run a script text without writing files; returns the environment it ran in
run_script <- function(txt, edit = NULL) {
  txt <- sub("output_dir <- \".\"", "output_dir <- NULL", txt, fixed = TRUE)
  if (!is.null(edit)) txt <- edit(txt)
  env <- new.env(parent = globalenv())
  res <- tryCatch({ invisible(capture.output(eval(parse(text = txt, keep.source = FALSE), envir = env))); NULL },
                  error = function(e) conditionMessage(e))
  env$.error <- res
  env
}

direct <- function(params, delta) {
  p <- list(sigma_R = params$sigma_R, rho = 1, pB_T = 0, pB_R = 0, pL = 0.15, q = 0, l = 3, n = 10,
            m = 3, n_sim = 10000, seed = 20261015, alpha = 0.05, sigma_T0 = 0.1, ema_limits = c(0.85, 1.18))
  p[names(params)] <- params
  platform_run_invitro(c(p, list(delta = delta)), n_sim_max = Inf, cells_max = Inf)
}

test_that("E-1 the script reproduces the run exactly (same R)", {
  skip_if_not(have_src, "R source folder not found")
  cases <- list(
    list(p = list(sigma_R = 0.12, l = 2, n = 5, m = 1, pB = 0, n_sim = 400), s = "fda_delta0"),
    list(p = list(sigma_R = 0.12, l = 3, n = 10, m = 2, pB = 0.3, n_sim = 400), s = "gmr_1.05"),
    list(p = list(sigma_R = 0.06, l = 6, n = 30, m = 3, pB = 0.3, n_sim = 200), s = "fda_delta0"))
  for (cc in cases) {
    env <- run_script(exp_script(cc$p, sinir = cc$s))
    expect_null(env$.error)
    pp <- cc$p; pp$pB_T <- pp$pB; pp$pB_R <- pp$pB; pp$pB <- NULL
    d <- platform_sinir_delta(cc$s, cc$p$sigma_R, 1)
    expect_identical(env$run$result, direct(pp, d))
  }
})

test_that("E-3 integrity: a changed byte stops the script before any computation", {
  skip_if_not(have_src, "R source folder not found")
  # SHA-256 implementation: FIPS 180-4 vectors and the pinned values
  expect_identical(.fsr_sha256(charToRaw("abc")),
                   "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
  expect_identical(.fsr_sha256(raw(0)),
                   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  expect_identical(.fsr_sha256(charToRaw(strrep("a", 1000))),
                   "41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3")
  for (f in c("sim_run.R", "invitro_fast.R", "invitro_grid.R"))
    expect_identical(.fsr_sha256(files[[f]]), unname(pinned[f]))
  txt <- exp_script(list(sigma_R = 0.12, n_sim = 200), sinir = "fda_delta0")
  tamper <- list(invitro_fast.R = c("pbe_fast <- function", "pbe_fast <- functioN"),
                 invitro_grid.R = c("ref_true <- sigma_R > sigma_T0", "ref_true <- sigma_R >= sigma_T0"),
                 platform_input.R = c("n_sim_max = 20000", "n_sim_max = 20001"))
  for (f in names(tamper)) {
    env <- run_script(txt, edit = function(t) sub(tamper[[f]][1], tamper[[f]][2], t, fixed = TRUE))
    expect_match(env$.error, paste0("SHA-256 mismatch in: ", f), fixed = TRUE)
    expect_false(exists("run", envir = env, inherits = FALSE))          # nothing computed
  }
  # export refuses a pinned file that differs from CEKIRDEK_SHA256.txt
  bad <- files; bad$invitro_grid.R[200] <- as.raw(bitwXor(as.integer(bad$invitro_grid.R[200]), 1L))
  expect_error(platform_export_invitro(list(sigma_R = 0.12), dosyalar = bad, cekirdek_sha = pinned),
               "SHA-256 of invitro_grid.R differs")
})

test_that("E-4 the embedded files are byte-identical to the sources", {
  skip_if_not(have_src, "R source folder not found")
  txt <- exp_script(list(sigma_R = 0.12, n_sim = 200), sinir = "ema_1.18")
  txt <- sub("\nrun <- .fsr_main(params, sinir, delta, output_dir, .fsr_files, .fsr_export)\n", "\n", txt, fixed = TRUE)
  env <- new.env(); eval(parse(text = txt, keep.source = FALSE), envir = env)
  expect_identical(names(env$.fsr_files), names(files))
  for (f in names(files)) {
    expect_identical(charToRaw(env$.fsr_files[[f]]$text), files[[f]])
    expect_identical(env$.fsr_files[[f]]$sha256, .fsr_sha256(files[[f]]))
  }
})

test_that("E-5 parameters edited in the script are used", {
  skip_if_not(have_src, "R source folder not found")
  txt <- exp_script(list(sigma_R = 0.2, rho = 1.2, n_sim = 300), sinir = "gmr_1.00")
  env <- run_script(txt, edit = function(t) {
    t <- sub("  n_sim = 300,", "  n_sim = 375,", t, fixed = TRUE)
    sub("  seed = 20261015,", "  seed = 77,", t, fixed = TRUE) })
  expect_null(env$.error)
  expect_identical(env$run$result, direct(list(sigma_R = 0.2, rho = 1.2, n_sim = 375, seed = 77), 0))
})

test_that("E-6 boundary names: delta computed in R, key carries the name", {
  skip_if_not(have_src, "R source folder not found")
  for (s in c("fda_delta0", "fda_minus_delta0", "ema_1.18", "ema_0.85")) {
    env <- run_script(exp_script(list(sigma_R = 0.15, rho = 1.1, n_sim = 200), sinir = s))
    d <- platform_sinir_delta(s, 0.15, 1.1)
    expect_identical(env$run$result, direct(list(sigma_R = 0.15, rho = 1.1, n_sim = 200), d))
    expect_match(env$run$record$scenario_key, paste0("|delta=", s), fixed = TRUE)
  }
  # numeric delta is written exactly
  d <- log(1.0333)
  env <- run_script(exp_script(list(sigma_R = 0.15, n_sim = 200, delta = d)))
  expect_identical(env$run$result, direct(list(sigma_R = 0.15, n_sim = 200), d))
})

test_that("E-7 input check: export, edited script, browser limit not applied", {
  skip_if_not(have_src, "R source folder not found")
  e <- tryCatch(exp_script(list(sigma_R = -1, l = 1, n_sim = 2.5)), farmastat_input_error = function(e) e)
  expect_s3_class(e, "farmastat_input_error")
  expect_setequal(e$problems$code, c("not_positive", "integer_min_2", "n_sim_range"))
  expect_error(exp_script(list(sigma_R = 0.12, delta = 0), sinir = "ema_1.18"), "not both")
  expect_error(exp_script(list(sigma_R = 0.12), sinir = "gmr_2"), "sinir must be one of")
  expect_error(exp_script(list(sigma_R = 0.05, rho = 4), sinir = "fda_delta0"), "not defined")
  env <- run_script(exp_script(list(sigma_R = 0.12, n_sim = 200), sinir = "gmr_1.00"),
                    edit = function(t) sub("  n = 10,", "  n = 1,", t, fixed = TRUE))
  expect_match(env$.error, "Invalid input", fixed = TRUE)
  expect_false(exists("run", envir = env, inherits = FALSE))
  big <- exp_script(list(sigma_R = 0.12, l = 6, n = 30, m = 3, n_sim = 50000), sinir = "gmr_1.05")
  expect_match(big, "  n_sim = 50000,", fixed = TRUE)
  expect_match(big, "l * n * m * n_sim = 27,000,000 cells", fixed = TRUE)
})

test_that("E-8 run record: fields, exact numbers, source 'script', run key", {
  skip_if_not(have_src, "R source folder not found")
  td <- tempfile(); dir.create(td); on.exit(unlink(td, recursive = TRUE))
  txt <- exp_script(list(sigma_R = 0.12, n_sim = 300, seed = 5), sinir = "fda_delta0",
                    kaynak = list(started = "2026-10-18T10:00:00.000Z", webr_version = "0.5.4"))
  txt <- sub("output_dir <- \".\"", sprintf("output_dir <- \"%s\"", gsub("\\\\", "/", td)), txt, fixed = TRUE)
  env <- new.env(); invisible(capture.output(eval(parse(text = txt, keep.source = FALSE), envir = env)))
  js <- readLines(list.files(td, "_kayit\\.json$", full.names = TRUE), warn = FALSE)
  csv <- read.csv(list.files(td, "_sonuc\\.csv$", full.names = TRUE), colClasses = "character")
  for (k in c("run_id", "platform", "document", "result_source", "disclaimer_tr", "disclaimer_en",
              "exported", "package_version", "started", "seconds", "r_version", "r_platform", "rng",
              "seed", "n_sim", "params", "sinir", "scenario_key", "run_key", "files", "source_run",
              "summary", "result"))
    expect_match(js, paste0("\"", k, "\":"), fixed = TRUE)
  expect_match(js, "\"result_source\":\"script\"", fixed = TRUE)
  expect_match(js, "\"webr_version\":\"0.5.4\"", fixed = TRUE)
  r <- env$run$result
  key <- platform_anahtar(0.12, rho = 1, pB_T = 0, pB_R = 0, pL = 0.15, q = 0, l = 3, n = 10, m = 3,
                          sinir = "fda_delta0", n_sim = 300, seed = 5, kosu = TRUE)
  expect_identical(env$run$record$run_key, key)
  expect_match(js, paste0("\"run_key\":\"", key, "\""), fixed = TRUE)
  for (k in c("fda_pass", "fda_pass_mcse", "ema_c_pass", "eta", "delta")) {
    v <- as.numeric(regmatches(js, regexpr(paste0("\"", k, "\":[-0-9.eE+]+"), js)) |> sub(pattern = ".*:", replacement = ""))
    expect_identical(v, r[[k]])
    expect_identical(as.numeric(csv[[k]]), r[[k]])
  }
})

test_that("E-9 the script text is deterministic apart from the export time", {
  skip_if_not(have_src, "R source folder not found")
  p <- list(sigma_R = 0.12, n_sim = 500)
  a <- strsplit(platform_export_invitro(p, "fda_delta0", dosyalar = files, cekirdek_sha = pinned,
                                        zaman = as.POSIXct("2026-01-01", tz = "UTC")), "\n")[[1]]
  b <- strsplit(platform_export_invitro(p, "fda_delta0", dosyalar = files, cekirdek_sha = pinned,
                                        zaman = as.POSIXct("2026-06-30 13:14:15", tz = "UTC")), "\n")[[1]]
  expect_identical(length(a), length(b))
  expect_identical(grep("^\\.fsr_created <- ", a), which(a != b))
})
