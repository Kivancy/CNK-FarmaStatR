# Charts, variability table and bootstrap replicate files of the dissolution analyses
# (FSR-TN-PLT-14, KK-80; request 11052026-a; criteria frozen before code, FSR-LOG-01 G-142).
# The functions only take values from the bridge result; these tests check that the values
# are the analysis' own (GR-4, DV-2, BS-2 ... BS-6).

kopru_yolu <- system.file("kopru", "dis_kopru.R", package = "CNKfarmastatr")
have_kopru <- nzchar(kopru_yolu) && file.exists(kopru_yolu)
kp <- if (have_kopru) platform_dis_kopru(kopru_yolu)
oku <- function(txt) utils::read.csv(text = txt, comment.char = "#")

test_that("GR-4, DV-2 f2: chart data and variability are the analysis' values", {
  skip_if_not(have_kopru, "inst/kopru/dis_kopru.R not installed")
  r <- platform_dis(kp, platform_dis_veri(ornek = "noce2020"), "Urun1", "Urun3", yontem = "f2", ayar = list(B = 500))
  g <- platform_dis_grafik(kp, r); h <- r$hazir; f <- kp$.kp$f2
  expect_identical(g[c("zaman", "ortT", "sdT", "ortR", "sdR")], h[c("zaman", "ortT", "sdT", "ortR", "sdR")])
  expect_identical(g$kullanilan, h$zaman %in% r$sonuc$zamanlar)              # EMA truncation: 120 ... 165
  expect_identical(sum(!g$kullanilan), 3L)
  v <- f$replikalar[, "Ef2"]; v <- v[is.finite(v)]
  expect_identical(g$hist$sayi, as.integer(graphics::hist(v, breaks = g$hist$kirilim, plot = FALSE)$counts))
  expect_identical(sum(g$hist$sayi), length(v))
  expect_identical(c(g$hist$alt, g$hist$ust), c(r$sonuc$alt, r$sonuc$ust))
  expect_identical(g$hist$nokta, r$sonuc$Ef2)
  d <- platform_dis_degiskenlik(r)
  expect_identical(d$oran, h$cvT / h$cvR)
  expect_identical(c(d$cvT, d$cvR), c(h$cvT, h$cvR))
})

test_that("GR-3, GR-4 Weibull and MSD: fitted curves and used points", {
  skip_if_not(have_kopru, "inst/kopru/dis_kopru.R not installed")
  ts <- platform_dis_veri(ornek = "tsong1996")
  w <- platform_dis(kp, ts, "TEST", "REF", yontem = "weibull")
  gw <- platform_dis_grafik(kp, w)
  expect_identical(gw$egri, list(tt = w$sonuc$tt, egT = w$sonuc$egT, egR = w$sonuc$egR))
  expect_true(all(gw$kullanilan)); expect_null(gw$hist)
  m <- platform_dis(kp, ts, "TEST", "REF", c("STD1", "STD2"), yontem = "msd", ayar = list(sinir = "L2a"))
  gm <- platform_dis_grafik(kp, m)
  expect_identical(gm$kullanilan, m$hazir$zaman %in% as.numeric(m$sonuc$zamanlar))
  expect_null(gm$egri)
})

test_that("BS-2 ... BS-5 bootstrap CSV: header, replicate values, drawn units, interval", {
  skip_if_not(have_kopru, "inst/kopru/dis_kopru.R not installed")
  r <- platform_dis(kp, platform_dis_veri(ornek = "noce2020"), "Urun1", "Urun3", yontem = "f2", ayar = list(B = 500))
  f <- kp$.kp$f2
  a <- platform_f2_disa(kp, FALSE, list(package = "test", data_sha256 = "x"))
  expect_null(a$sas)
  ba <- oku(a$csv)
  expect_identical(names(ba), c("rep", "f2", "Ef2", "bcf2", "P"))
  expect_identical(nrow(ba), 500L)
  for (k in c("f2", "Ef2", "bcf2")) expect_identical(ba[[k]], unname(f$replikalar[, k]))
  expect_identical(as.numeric(ba$P), unname(f$replikalar[, "P"]))
  bas <- grep("^#", strsplit(a$csv, "\n")[[1]], value = TRUE)
  for (k in c("package: test", "data_sha256: x", "seed = 20260927", "estimator = Ef2", "truncation = EMA",
              "truncation mode = replika", "quantile type = 7", "decision interval", "percentile interval of Ef2"))
    expect_true(any(grepl(k, bas, fixed = TRUE)))
  a2 <- (1 - 0.90) / 2                                       # as in calc_f2_boot: (1 - conf) / 2, not the literal 0.05
  q <- unname(stats::quantile(ba$Ef2[is.finite(ba$Ef2)], c(a2, 1 - a2), type = 7))
  expect_identical(q, c(r$sonuc$alt, r$sonuc$ust))
  b <- platform_f2_disa(kp, TRUE, list(csv = "boot.csv"))
  bb <- oku(b$csv)
  expect_identical(unname(as.matrix(bb[, paste0("T", 1:12)])), unname(f$idx$T) + 0L)
  expect_identical(unname(as.matrix(bb[, paste0("R", 1:12)])), unname(f$idx$R) + 0L)
  expect_true(any(grepl("#   test units: 1=1; 2=2", strsplit(b$csv, "\n")[[1]], fixed = TRUE)))
})

test_that("BS-6 SAS program: macro values and embedded data are the analysis'", {
  skip_if_not(have_kopru, "inst/kopru/dis_kopru.R not installed")
  platform_dis(kp, platform_dis_veri(ornek = "noce2020"), "Urun1", "Urun3", yontem = "f2", ayar = list(B = 200))
  f <- kp$.kp$f2; s <- platform_f2_disa(kp, TRUE, list(csv = "boot.csv"))$sas
  L <- strsplit(s, "\n")[[1]]
  expect_true(any(grepl("%let nT = 12; %let nR = 12; %let nP = 9; %let B = 200;", L, fixed = TRUE)))
  expect_true(any(grepl("%let rule = EMA;", L, fixed = TRUE)))
  expect_true(any(grepl("%let est = Ef2;", L, fixed = TRUE)))
  expect_true(any(grepl("%let qa = 1; %let qb = 1;", L, fixed = TRUE)))
  i <- which(L == "data test_u; input x1-x&nP; datalines;")
  dat <- do.call(rbind, lapply(strsplit(L[(i + 1):(i + 12)], " "), as.numeric))
  expect_identical(unname(dat), unname(f$kontrol$XT_tum))
  j <- which(L == "data ref_u; input x1-x&nP; datalines;")
  dat <- do.call(rbind, lapply(strsplit(L[(j + 1):(j + 12)], " "), as.numeric))
  expect_identical(unname(dat), unname(f$kontrol$XR_tum))
  expect_true(any(grepl("Research and education only", L, fixed = TRUE)))
  # SAS names are not case sensitive: the names assigned in PROC IML must stay distinct ignoring case
  # (G-144: XT/xt, XR/xr, B/b and V/v collided in the first version; found in the owner's SAS run)
  iml <- L[which(L == "proc iml;"):which(L == "quit;")]
  nm <- unique(unlist(regmatches(iml, gregexpr("\\b[A-Za-z_][A-Za-z0-9_]*(?=\\s*(\\[[^]]*\\])?\\s*=[^=])", iml, perl = TRUE))))
  nm <- c(nm, unlist(regmatches(iml, gregexpr("(?<=into )[A-Za-z_][A-Za-z0-9_]*", iml, perl = TRUE))),
          unlist(regmatches(iml, gregexpr("(?<=do )[A-Za-z_][A-Za-z0-9_]*", iml, perl = TRUE))))
  nm <- unique(nm)
  expect_identical(anyDuplicated(tolower(nm)), 0L)
  expect_true(all(c("DATT", "PLAT_V", "smpT", "ib", "nrep") %in% nm))
})
