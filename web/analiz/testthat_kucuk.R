# =============================================================================
# CNK-FarmaStatR - a small base-R stand-in for the testthat functions used by the
# package tests, so that the test folder can run in webR without installing
# packages (FSR-TN-PLT-06, T-3; open item A-3 of FSR-TN-PLT-05, FSR-VAL-SIM-1
# Section 9). FarmaStatR derivation, not testthat:
#   - expect_equal(): all.equal() with tolerance sqrt(.Machine$double.eps) by
#     default (testthat 3e uses waldo with the same default tolerance); a given
#     tolerance is passed on; tolerance = 0 means exact equality.
#   - expect_error(): an error must occur; regexp is matched with grepl().
#   - skip_*(): the block stops and is counted as skipped.
# Every expectation is counted: passed, failed (with its message) or the block
# errored. The result is one row per block (file, test, nb, failed, skipped, error).
# Research and education only; not a system validated for GxP environments.
# =============================================================================
.tk <- new.env()
.tk$rows <- NULL; .tk$file <- ""
.tk_hit <- function(ok, msg) {
  .tk$nb <- .tk$nb + 1L
  if (!isTRUE(ok)) { .tk$failed <- .tk$failed + 1L; .tk$msgs <- c(.tk$msgs, msg) }
  invisible(ok)
}
.tk_lab <- function(e) paste(deparse(e, width.cutoff = 60L)[1], collapse = "")
expect <- function(ok, failure_message = "expectation failed", ...) .tk_hit(isTRUE(ok), failure_message)
expect_true <- function(object, info = NULL, ...) .tk_hit(isTRUE(object), paste("not TRUE:", .tk_lab(substitute(object))))
expect_false <- function(object, info = NULL, ...) .tk_hit(identical(as.vector(object), FALSE), paste("not FALSE:", .tk_lab(substitute(object))))
expect_null <- function(object, ...) .tk_hit(is.null(object), paste("not NULL:", .tk_lab(substitute(object))))
expect_identical <- function(object, expected, info = NULL, ...)
  .tk_hit(identical(object, expected), paste("not identical:", .tk_lab(substitute(object))))
expect_equal <- function(object, expected, tolerance = sqrt(.Machine$double.eps), info = NULL, ...) {
  ok <- if (identical(tolerance, 0)) identical(unclass(object), unclass(expected)) || isTRUE(all.equal(object, expected, tolerance = 0, check.attributes = TRUE))
        else isTRUE(all.equal(object, expected, tolerance = tolerance))
  .tk_hit(ok, paste("not equal:", .tk_lab(substitute(object)), if (!is.null(info)) paste0("(", info, ")") else ""))
}
expect_setequal <- function(object, expected, ...)
  .tk_hit(length(setdiff(object, expected)) == 0 && length(setdiff(expected, object)) == 0, paste("sets differ:", .tk_lab(substitute(object))))
expect_lte <- function(object, expected, ...) .tk_hit(isTRUE(all(object <= expected)), paste("not <=:", .tk_lab(substitute(object))))
expect_match <- function(object, regexp, fixed = FALSE, all = TRUE, ...) {
  ok <- length(object) > 0 && (if (all) all(grepl(regexp, object, fixed = fixed)) else any(grepl(regexp, object, fixed = fixed)))
  .tk_hit(ok, paste("no match:", regexp))
}
expect_s3_class <- function(object, class, ...) .tk_hit(inherits(object, class), paste("not class", class))
expect_error <- function(object, regexp = NULL, class = NULL, ..., fixed = FALSE) {
  e <- tryCatch({ force(object); NULL }, error = function(e) e)
  ok <- !is.null(e) && (is.null(regexp) || grepl(regexp, conditionMessage(e), fixed = fixed)) &&
    (is.null(class) || inherits(e, class))
  .tk_hit(ok, paste("error not as expected:", if (is.null(e)) "no error" else conditionMessage(e)))
  invisible(e)
}
.tk_skip <- function(msg) stop(structure(class = c("tk_skip", "condition"), list(message = msg, call = NULL)))
skip <- function(message = "skipped") .tk_skip(message)
skip_if_not <- function(condition, message = "condition not met") if (!isTRUE(condition)) .tk_skip(message)
skip_on_cran <- function() if (!identical(Sys.getenv("NOT_CRAN"), "true")) .tk_skip("On CRAN")
test_that <- function(desc, code) {
  .tk$nb <- 0L; .tk$failed <- 0L; .tk$msgs <- character(0)
  sk <- FALSE; er <- NA_character_
  t0 <- proc.time()[[3]]
  tryCatch(eval(substitute(code), envir = new.env(parent = parent.frame())),
           tk_skip = function(s) sk <<- TRUE,
           error = function(e) er <<- conditionMessage(e))
  .tk$rows <- rbind(.tk$rows, data.frame(file = .tk$file, test = desc, nb = .tk$nb, failed = .tk$failed,
                                         skipped = sk, error = !is.na(er), secs = proc.time()[[3]] - t0,
                                         detail = paste(c(if (!is.na(er)) paste("ERROR:", er), utils::head(.tk$msgs, 3)), collapse = " | "),
                                         stringsAsFactors = FALSE))
  invisible(NULL)
}
# installed-package paths of CNKfarmastatr point to the inst/ folder of the copy
tk_pkg_inst <- NULL
system.file <- function(..., package = "base", lib.loc = NULL, mustWork = FALSE) {
  if (identical(package, "CNKfarmastatr") && !is.null(tk_pkg_inst)) {
    p <- if (length(list(...))) file.path(tk_pkg_inst, ...) else tk_pkg_inst
    return(if (file.exists(p)) p else "")
  }
  base::system.file(..., package = package, lib.loc = lib.loc, mustWork = mustWork)
}
# the package is not installed here: its R files are sourced into the global
# environment. tk_paket() makes library(CNKfarmastatr) a no-op and puts a
# DESCRIPTION-only stub first on .libPaths() so that
# utils::packageVersion("CNKfarmastatr") gives the version of the copy
# (FarmaStatR derivation; only for running the tests in webR).
tk_paket <- function(description) {
  v <- read.dcf(description, fields = "Version")[1, 1]
  lib <- file.path(tempdir(), "tk_lib"); dir.create(file.path(lib, "CNKfarmastatr"), recursive = TRUE, showWarnings = FALSE)
  writeLines(c("Package: CNKfarmastatr", paste("Version:", v), paste0("Built: R ", getRversion(), "; ; 2026-01-01; unix")),
             file.path(lib, "CNKfarmastatr", "DESCRIPTION"))
  .libPaths(c(lib, .libPaths()))
  assign("library", function(package, ...) {
    p <- if (is.character(substitute(package))) package else deparse(substitute(package))
    if (identical(p, "CNKfarmastatr")) return(invisible(NULL))
    eval(substitute(base::library(package, ...)), parent.frame())
  }, envir = globalenv())
  invisible(v)
}
# run every helper and test file of a folder (helpers first, as testthat does)
tk_test_dir <- function(dir, env = globalenv(), only = NULL) {
  .tk$rows <- NULL                              # each call reports its own blocks only
  old <- setwd(dir); on.exit(setwd(old))
  src <- function(f, e) {                       # testthat::expect -> expect, CNKfarmastatr::: -> global (no namespaces here)
    x <- readLines(f, encoding = "UTF-8", warn = FALSE); x <- gsub("testthat::", "", x, fixed = TRUE); x <- gsub("CNKfarmastatr:::", "", x, fixed = TRUE)
    for (ex in parse(text = x, keep.source = FALSE, encoding = "UTF-8")) eval(ex, envir = e)
  }
  for (f in sort(list.files(".", "^helper.*\\.R$"))) src(f, env)
  fs <- sort(list.files(".", "^test.*\\.R$")); if (!is.null(only)) fs <- fs[fs %in% only]
  for (f in fs) {
    .tk$file <- f
    tryCatch(src(f, new.env(parent = env)), error = function(e)      # an error outside test_that()
      .tk$rows <- rbind(.tk$rows, data.frame(file = f, test = "(file)", nb = 0L, failed = 0L, skipped = FALSE,
                                             error = TRUE, secs = 0, detail = paste("ERROR:", conditionMessage(e)),
                                             stringsAsFactors = FALSE)))
  }
  .tk$rows
}
