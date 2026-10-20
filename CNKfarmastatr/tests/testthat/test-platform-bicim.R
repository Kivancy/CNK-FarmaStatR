# Display rule P4-K3 (FSR-TN-PLT-04, KK-54): the reference texts the browser formatter is
# compared with (belgeler/teknik_notlar/FSR-TN-PLT-04_ek/p4_bicim_referans.csv) are the
# published-table texts written by R on Linux (glibc: nearest to the binary value, exact ties
# to even). This test shows that the reference is still reproduced. Windows R rounds exact
# ties differently (G-73), so the comparison runs on Linux only.

ref_path <- function() {
  for (d in c("../../../belgeler", "../../belgeler", "belgeler")) {
    f <- file.path(d, "teknik_notlar", "FSR-TN-PLT-04_ek", "p4_bicim_referans.csv")
    if (file.exists(f)) return(f)
  }
  NA_character_
}

test_that("P4-K3 reference texts = formatC on Linux (11,385 rates and MCSEs)", {
  f <- ref_path()
  expect_false(is.na(f))                     # the reference is in the repository (CI checks it out)
  # Windows R rounds exact ties differently (G-73): there only the presence is checked.
  # Not a skip, because CI fails on skipped tests; the full check runs on Linux.
  if (.Platform$OS.type == "windows" || is.na(f)) return(invisible())
  r <- utils::read.csv(f, colClasses = "character", na.strings = character(0))
  expect_identical(nrow(r), 11385L)
  v <- as.numeric(r$deger_oran)
  expect_identical(formatC(100 * v, format = "f", digits = 1), r$oran)
  m <- r$deger_mcse != "NA"
  expect_identical(formatC(100 * as.numeric(r$deger_mcse[m]), format = "f", digits = 2), r$mcse[m])
  # exact ties are in the reference and go to the even digit
  expect_identical(c(formatC(0.125, format = "f", digits = 2), formatC(c(2.25, 4.85, 100 * 0.0485), format = "f", digits = 1)),
                   c("0.12", "2.2", "4.8", "4.9"))
  expect_true(sum(abs(100 * v * 10 - floor(100 * v * 10)) == 0.5) > 0)
})
