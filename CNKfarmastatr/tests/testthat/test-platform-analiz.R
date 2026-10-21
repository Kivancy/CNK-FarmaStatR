# Analysis of one's own data with the inherited, validated models (FSR-TN-PLT-06 v0.1,
# Section 4; KK-59). platform_analiz.R only reads data and calls the inherited bridges
# unchanged; these tests check the wiring (A-1 ... A-8), not the statistics, which the
# inherited validation covers (test-devralinan-validasyon.R; FSR-LOG-01 G-01).

kopru_yolu <- system.file("kopru", "dis_kopru.R", package = "CNKfarmastatr")
have_kopru <- nzchar(kopru_yolu) && file.exists(kopru_yolu)
kp <- if (have_kopru) platform_dis_kopru(kopru_yolu)

csv_yaz <- function(d, sep = ",", dec = ".") {
  con <- textConnection("out", "w", local = TRUE)
  utils::write.table(d, con, sep = sep, dec = dec, row.names = FALSE, quote = FALSE)
  close(con)
  paste(out, collapse = "\n")
}

test_that("A-1 dis_kopru.R is the v0.5.1 bridge byte for byte (FSR-LOG-01 G-01)", {
  skip_if_not(have_kopru, "inst/kopru/dis_kopru.R not installed")
  b <- readBin(kopru_yolu, "raw", file.size(kopru_yolu))
  b <- charToRaw(gsub("\r\n", "\n", rawToChar(b), fixed = TRUE))   # a Windows checkout may add CR
  expect_identical(.fsr_sha256(b), "5dea054408d594a2eafecfeacde272bbc8f21e9da9507bbef1b15898274c4e28")
})

test_that("A-2 platform_csv reads ; , and tab files, a BOM and a decimal comma", {
  d0 <- data.frame(a = c("x", "y"), b = c("1.5", "2"), stringsAsFactors = FALSE)
  for (s in list(c(",", "."), c(";", ","), c("\t", "."))) {
    txt <- csv_yaz(data.frame(a = c("x", "y"), b = c(1.5, 2)), s[1], s[2])
    d <- platform_csv(paste0("\ufeff", txt, "\n", s[1], "\n"))   # BOM; an empty spreadsheet row is dropped
    expect_identical(attr(d, "ayrac"), s[1])
    expect_identical(names(d), c("a", "b"))
    expect_identical(d$a, d0$a)
    expect_equal(.analiz_sayi(d$b), c(1.5, 2), tolerance = 0)
  }
  expect_error(platform_csv(""), "Empty file")
  expect_error(platform_pbe_veri("x,y\n1,2"), "Missing column\\(s\\): parti, kap, asama, urun, olcum")
})

test_that("A-3 PBE: the screen path equals the bridge called directly; CSV input gives the same", {
  o <- ornek_psg020929()
  dogrudan <- function(log_d, tek) {
    kp_hazirla(parti = as.character(o$Batches), kap = as.character(o$Container), asama = o$Stage,
               urun = o$Product, deger = as.character(o$score), test = "TEST", ref = "REF", log_d = log_d)
    kp_pbe(tek_yonlu = tek)
  }
  v <- platform_pbe_veri(ornek = "psg020929")
  expect_identical(v$urunler, c("REF", "TEST"))
  for (k in list(c(FALSE, FALSE), c(TRUE, FALSE), c(FALSE, TRUE))) {
    r <- platform_pbe(v, "TEST", "REF", k[1], k[2])
    expect_identical(r$sonuc, dogrudan(k[1], k[2]))
  }
  r0 <- platform_pbe(v, "TEST", "REF")
  expect_identical(r0$sonuc$pass_fail, "PASS")
  expect_identical(round(r0$sonuc$H_eta_final, 6), -0.031499)            # FarmaStatR reference (P6)
  # the same data as files: English names with ',' and Turkish names with ';' and decimal comma
  en <- data.frame(Batch = o$Batches, Container = o$Container, Stage = o$Stage, Product = o$Product, Score = o$score)
  tr <- stats::setNames(en, c("Parti", "Kap", "A\u015fama", "\u00dcr\u00fcn", "\u00d6l\u00e7\u00fcm"))
  for (txt in list(csv_yaz(en), csv_yaz(tr, ";", ","))) {
    r <- platform_pbe(platform_pbe_veri(txt), "TEST", "REF")
    expect_identical(r$sonuc, r0$sonuc)
  }
})

test_that("A-4 PBE: the bridge's own messages reach the screen", {
  v <- platform_pbe_veri(ornek = "psg020929")
  expect_error(platform_pbe(v, "TEST", "TEST"))
  expect_error(platform_pbe(v, "TEST", "YOK"))
  v$olcum[3] <- "abc"
  expect_error(platform_pbe(v, "TEST", "REF"))
})

test_that("A-5 dissolution: the two bridges live side by side", {
  skip_if_not(have_kopru, "inst/kopru/dis_kopru.R not installed")
  expect_true(exists("kp_f2", envir = kp, inherits = FALSE))
  expect_false(identical(kp$kp_hazirla, kp_hazirla))                      # PBE bridge unchanged
  expect_identical(names(formals(kp_hazirla))[1:3], c("parti", "kap", "asama"))
})

test_that("A-6 dissolution: the screen path equals the bridge called directly", {
  skip_if_not(have_kopru, "inst/kopru/dis_kopru.R not installed")
  ts <- platform_dis_veri(ornek = "tsong1996"); ot <- ornek_tsong()
  dg <- function() kp$kp_hazirla(ot$Product, ot$Unit, ot$Time, ot$Diss, "TEST", "REF", c("STD1", "STD2"), "dakika")
  r <- platform_dis(kp, ts, "TEST", "REF", c("STD1", "STD2"), yontem = "msd", ayar = list(sinir = "L2a"))
  dg(); expect_identical(r$sonuc, kp$kp_msd("L2a", 10, "none"))
  expect_identical(round(r$sonuc$DM, 4), 26.4856)                            # FarmaStatR reference (P6)
  expect_false(r$sonuc$benzer_msd)
  r <- platform_dis(kp, ts, "TEST", "REF", c("STD1", "STD2"), yontem = "weibull", ayar = list(param = "lnA_lnB", bolge = "B-L2a"))
  dg(); expect_identical(r$sonuc, kp$kp_wb("lnA_lnB", "B-L2a", 10, 3, "N"))
  expect_identical(round(r$sonuc$DM, 4), 10.8123)
  r <- platform_dis(kp, ts, "TEST", "REF", yontem = "weibull")
  expect_identical(r$sonuc$param, "lnTd_lnB")
  # CSV input with Turkish names, ';' and decimal comma gives the same result
  tr <- data.frame(urun = ot$Product, tablet = ot$Unit, zaman = ot$Time, cozunen = ot$Diss)
  r2 <- platform_dis(kp, platform_dis_veri(csv_yaz(tr, ";", ",")), "TEST", "REF", c("STD1", "STD2"), yontem = "msd", ayar = list(sinir = "L2a"))
  expect_identical(r2$sonuc[names(r2$sonuc) != "notlar"], platform_dis(kp, ts, "TEST", "REF", c("STD1", "STD2"), yontem = "msd",
                                                     ayar = list(sinir = "L2a"))$sonuc[names(r2$sonuc) != "notlar"])
})

test_that("A-7 f2: perspective presets of calc_f2_boot (EMA Q&A 3.11; FDA 1997); explicit settings win", {
  skip_if_not(have_kopru, "inst/kopru/dis_kopru.R not installed")
  skip_on_cran()
  no <- platform_dis_veri(ornek = "noce2020")
  e <- platform_dis(kp, no, "Urun1", "Urun2", yontem = "f2")$sonuc
  expect_identical(c(e$perspektif, e$tahminci, e$cvkural), c("EMA", "Ef2", "M9"))
  expect_identical(c(e$B, e$seed), c(5000, 20260927))
  expect_identical(e$karar, "BENZER DE\u011e\u0130L")
  expect_identical(round(e$alt, 2), 30.90)                                    # FarmaStatR reference (P6)
  f <- platform_dis(kp, no, "Urun1", "Urun2", yontem = "f2", ayar = list(perspektif = "FDA", B = 2000))$sonuc
  expect_identical(c(f$perspektif, f$tahminci, f$cvkural), c("FDA", "f2", "FDA97"))
  expect_equal(f$B, 2000)
  kp$kp_hazirla(no$Product, no$Unit, no$Time, no$Diss, "Urun1", "Urun2", character(0), "dakika")
  expect_identical(f, local({ s <- kp$kp_f2("FDA", "f2", "FDA", "replika", "FDA97", "persentil", 2000, 20260927, 7); s }))
})

test_that("A-8 dissolution input errors", {
  skip_if_not(have_kopru, "inst/kopru/dis_kopru.R not installed")
  ts <- platform_dis_veri(ornek = "tsong1996")
  expect_error(platform_dis(kp, ts, "TEST", "TEST"), "farkl")
  expect_error(platform_dis(kp, ts, "TEST", "REF", yontem = "xyz"))
  expect_error(platform_dis_veri("Product,Unit,Time,Diss\nA,1,x,5"), "must be numbers")
  expect_error(platform_dis_veri("Product,Unit,Zaman\nA,1,5"), "Missing column\\(s\\): Diss")
  expect_error(platform_dis(kp, ts, "TEST", "REF", yontem = "msd", ayar = list(sinir = "L2a")))   # no reference lots
})
