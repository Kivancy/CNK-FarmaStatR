# Wide layout for dissolution data (FSR-TN-PLT-12, KK-78; criteria W-0 ... W-12 frozen
# before code, FSR-LOG-01 G-139). Rows = time points, columns = <product>.<unit>.
# The reader only reshapes; the results must be identical to the long layout (W-8).

kopru_yolu <- system.file("kopru", "dis_kopru.R", package = "CNKfarmastatr")
have_kopru <- nzchar(kopru_yolu) && file.exists(kopru_yolu)
kp <- if (have_kopru) platform_dis_kopru(kopru_yolu)

# long data frame (Product, Unit, Time, Diss) -> wide CSV text
genis_yaz <- function(d, sep = ",", dec = ".", ikinci = FALSE) {
  f <- function(x) if (dec == ",") gsub(".", ",", as.character(x), fixed = TRUE) else as.character(x)
  sut <- unique(paste(d$Product, d$Unit, sep = "."))
  zam <- unique(d$Time)
  satir <- vapply(zam, function(t) {
    v <- vapply(sut, function(s) f(d$Diss[paste(d$Product, d$Unit, sep = ".") == s & d$Time == t]), "")
    paste(c(f(t), v), collapse = sep) }, "")
  paste(c(paste(c("Time", sut), collapse = sep),
          if (ikinci) paste(c("(min)", rep("F(%)", length(sut))), collapse = sep), satir), collapse = "\n")
}
uzun <- function(x) x[c("Product", "Unit", "Time", "Diss", "urunler")]

test_that("W-1, W-3, W-8 Tsong 1996 wide = long, with ',', ';' + decimal comma and tab", {
  o <- platform_dis_veri(ornek = "tsong1996"); ot <- ornek_tsong()
  for (a in list(c(",", "."), c(";", ","), c("\t", ".")))
    expect_identical(uzun(platform_dis_veri(genis_yaz(ot, a[1], a[2]))), uzun(o))
})

test_that("W-8 identical results: MSD (L1, L2a) and Weibull MSD on Tsong 1996", {
  skip_if_not(have_kopru, "inst/kopru/dis_kopru.R not installed")
  o <- platform_dis_veri(ornek = "tsong1996"); w <- platform_dis_veri(genis_yaz(ornek_tsong(), ";", ","))
  lt <- c("STD1", "STD2")
  for (s in c("L1", "L2a"))
    expect_identical(platform_dis(kp, w, "TEST", "REF", lt, yontem = "msd", ayar = list(sinir = s))$sonuc,
                     platform_dis(kp, o, "TEST", "REF", lt, yontem = "msd", ayar = list(sinir = s))$sonuc)
  for (b in c("B-L3", "B-L2a"))
    expect_identical(platform_dis(kp, w, "TEST", "REF", lt, yontem = "weibull", ayar = list(bolge = b))$sonuc,
                     platform_dis(kp, o, "TEST", "REF", lt, yontem = "weibull", ayar = list(bolge = b))$sonuc)
})

test_that("W-8 identical results: f2 and bootstrap f2 on Noce 2020 (EMA and FDA presets)", {
  skip_if_not(have_kopru, "inst/kopru/dis_kopru.R not installed")
  skip_on_cran()
  o <- platform_dis_veri(ornek = "noce2020"); w <- platform_dis_veri(genis_yaz(ornek_noce()))
  expect_identical(uzun(w), uzun(o))
  for (p in c("EMA", "FDA"))
    expect_identical(platform_dis(kp, w, "Urun1", "Urun2", yontem = "f2", ayar = list(perspektif = p, B = 2000))$sonuc,
                     platform_dis(kp, o, "Urun1", "Urun2", yontem = "f2", ayar = list(perspektif = p, B = 2000))$sonuc)
})

test_that("W-2 product and unit are split at the last dot; empty parts are errors", {
  v <- platform_dis_veri("Time,Ref.A.1,Ref.A.2,Test.1,Test.2\n5,10,11,12,13\n10,20,21,22,23")
  expect_identical(v$urunler, c("Ref.A", "Test"))
  expect_identical(v$Unit, c("1", "2", "1", "2", "1", "2", "1", "2"))
  expect_identical(v$Product, rep(c("Ref.A", "Test"), each = 4))
  expect_error(platform_dis_veri("Time,Test.1,Test\n5,10,11"), "not of the form <product>.<unit>.*'Test'")
  expect_error(platform_dis_veri("Time,Test.1,.2\n5,10,11"), "'.2'")
  expect_error(platform_dis_veri("Time,Test.1,Test.\n5,10,11"), "'Test.'")
})

test_that("W-4 DDSolver second header row is skipped; a row with numbers is not", {
  ot <- ornek_tsong()
  expect_identical(uzun(platform_dis_veri(genis_yaz(ot, ikinci = TRUE))), uzun(platform_dis_veri(genis_yaz(ot))))
  v <- platform_dis_veri("Time,Test.1,Ref.1\n5,10,11\n10,20,21")
  expect_identical(v$Time, c(5, 10, 5, 10))
  expect_error(platform_dis_veri("Time,Test.1,Ref.1\n(min),F(%),F(%)\n(h),F(%),F(%)\n5,10,11"), "Time must be a number")
})

test_that("W-5 empty or non-numeric cells are errors naming column and time", {
  expect_error(platform_dis_veri("Time,Test.1,Test.2,Ref.1\n5,10,,12\n10,20,21,22"), "column Test.2, time 5")
  expect_error(platform_dis_veri("Time,Test.1,Test.2,Ref.1\n5,10,11,12\n10,20,21,abc"), "column Ref.1, time 10 \\('abc'\\)")
  expect_error(platform_dis_veri("Time,Test.1,Ref.1\n5,10,11\nx,20,21"), "Time must be a number: 'x'")
})

test_that("W-6 duplicate column names and duplicate time points are errors", {
  expect_error(platform_dis_veri("Time,Test.1,Test.1,Ref.1\n5,10,11,12"), "Duplicate column name\\(s\\): Test.1")
  expect_error(platform_dis_veri("Time,Test.1,Ref.1\n5,10,11\n5,20,21"), "Duplicate time point\\(s\\): 5")
})

test_that("W-1 a file in neither layout names both layouts and the columns found", {
  expect_error(platform_dis_veri("Urun,Unit,Zaman\nA,1,5"), "Missing column\\(s\\): Diss.*Accepted layouts: wide")
  expect_error(platform_dis_veri("Sample,Test.1\n5,10"), "Columns found: Sample, Test.1")
})

test_that("W-0 the PBE reader does not accept the wide layout", {
  expect_error(platform_pbe_veri("Time,Test.1,Ref.1\n5,10,11"), "Missing column")
})
