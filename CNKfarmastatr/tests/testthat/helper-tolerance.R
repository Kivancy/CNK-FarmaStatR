# Acceptance rule for numerical comparisons (FSR-VAL-SIM-1 v0.2, decision KK-41)
#   |x_hat - x| <= atol + rtol * max(|x|, |x_hat|), element by element.
# Unlike expect_equal(tolerance = ), which compares the mean absolute difference
# with the mean absolute target, the rule holds for every element and stays
# defined when the true value is 0. Exact (integer, identity) checks keep
# expect_equal(tolerance = 0) or expect_identical().
expect_close <- function(object, expected, atol = 1e-12, rtol = 1e-12, info = NULL) {
  x <- unname(as.numeric(object)); y <- unname(as.numeric(expected))
  ok <- length(x) == length(y) && !anyNA(x) && !anyNA(y)
  ratio <- NA_real_
  if (ok) {
    ratio <- max(abs(x - y) / (atol + rtol * pmax(abs(x), abs(y))))
    ok <- ratio <= 1
  }
  testthat::expect(isTRUE(ok),
    sprintf("|diff| exceeds atol + rtol * max(|x|, |y|): max ratio %.3g (atol %g, rtol %g)%s",
            ratio, atol, rtol, if (is.null(info)) "" else paste0("; ", info)))
  invisible(object)
}
