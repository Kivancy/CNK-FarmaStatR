# =============================================================================
# CNK-FarmaStatR v1 - Platform: analysis of one's own data with the inherited,
#   validated models (FSR-TN-PLT-06 v0.1, T-1; decision KK-59)
#
# The screen gives the text of a CSV file (or chooses an example data set); this
# file reads it, maps the columns and calls the inherited bridges UNCHANGED:
#   PBE (FDA PSG 020929): kp_hazirla() and kp_pbe() of pbe_kopru.R -> calc_pbe()
#   dissolution: kp_hazirla(), kp_f2(), kp_msd(), kp_wb() of the v0.5.1 bridge
#     (inst/kopru/dis_kopru.R, bytes unchanged, SHA-256 5dea0544...; FSR-LOG-01
#     G-01) -> calc_f2_boot(), calc_msd(), calc_msd_weibull()
# The two bridges both define kp_hazirla(); the dissolution bridge is therefore
# loaded into its own environment (platform_dis_kopru()).
# Nothing here computes a statistic. Column names are matched without case and
# Turkish letters; a decimal comma is accepted (as araclar/pbe_hesapla.R).
# FarmaStatR derivation. Base R only. Version 0.1.0
# Research and education only; not a system validated for GxP environments.
# =============================================================================

.analiz_sutun <- function(x) tolower(chartr("\u015f\u0131\u00e7\u011f\u00fc\u00f6\u015e\u0130\u00c7\u011e\u00dc\u00d6", "sicguoSICGUO", trimws(x)))

# -----------------------------------------------------------------------------
# platform_csv(): CSV text -> data frame of character columns
#   separator: ";" when the first line has more ";" than "," (Excel, Turkish
#   locale), tab when it has tabs and neither, otherwise ","; a UTF-8 BOM is dropped
# -----------------------------------------------------------------------------
platform_csv <- function(metin) {
  if (!is.character(metin) || length(metin) != 1 || !nzchar(metin)) stop("Empty file.")
  metin <- sub("^\ufeff", "", metin)
  ilk <- strsplit(metin, "\r?\n")[[1]][1]
  n <- function(ch) lengths(regmatches(ilk, gregexpr(ch, ilk, fixed = TRUE)))
  sep <- if (n(";") > n(",")) ";" else if (n("\t") > 0 && n(",") == 0) "\t" else ","
  d <- utils::read.table(text = metin, sep = sep, header = TRUE, colClasses = "character",
                         quote = "\"", strip.white = TRUE, comment.char = "", check.names = FALSE,
                         na.strings = c("", "NA"), encoding = "UTF-8")
  d <- d[rowSums(!is.na(d)) > 0, , drop = FALSE]                  # empty spreadsheet rows
  attr(d, "ayrac") <- sep
  d
}
.analiz_sayi <- function(x) suppressWarnings(as.numeric(gsub(",", ".", x, fixed = TRUE)))
.analiz_esle <- function(d, adlar) {             # adlar: target -> accepted names
  nm <- .analiz_sutun(names(d)); out <- list(); eksik <- character(0)
  for (k in names(adlar)) {
    i <- match(.analiz_sutun(adlar[[k]]), nm); i <- i[!is.na(i)][1]
    if (is.na(i)) eksik <- c(eksik, k) else out[[k]] <- d[[i]]
  }
  if (length(eksik)) stop(sprintf("Missing column(s): %s. Columns found: %s.",
                                  paste(eksik, collapse = ", "), paste(names(d), collapse = ", ")))
  out
}

# -----------------------------------------------------------------------------
# PBE
# -----------------------------------------------------------------------------
.analiz_pbe_adlar <- list(parti = c("parti", "batch", "batches", "lot"),
                          kap = c("kap", "container", "unit", "birim"),
                          asama = c("asama", "stage"),
                          urun = c("urun", "product"),
                          olcum = c("olcum", "score", "value", "deger"))
platform_pbe_veri <- function(metin = NULL, ornek = NULL) {
  d <- if (identical(ornek, "psg020929")) {
    o <- ornek_psg020929()
    list(parti = as.character(o$Batches), kap = as.character(o$Container), asama = o$Stage,
         urun = o$Product, olcum = as.character(o$score))
  } else .analiz_esle(platform_csv(metin), .analiz_pbe_adlar)
  d$olcum <- gsub(",", ".", d$olcum, fixed = TRUE)
  d$urunler <- sort(unique(d$urun))
  d
}
# returns the bridge's own lists: hazir (design, summaries, warnings) and sonuc (calc_pbe)
platform_pbe <- function(veri, test = "TEST", ref = "REF", log_d = FALSE, tek_yonlu = FALSE) {
  h <- kp_hazirla(parti = veri$parti, kap = veri$kap, asama = veri$asama, urun = veri$urun,
                  deger = veri$olcum, test = test, ref = ref, log_d = log_d)
  r <- kp_pbe(tek_yonlu = tek_yonlu)
  list(hazir = h, sonuc = r, test = test, ref = ref, log_d = isTRUE(log_d), tek_yonlu = isTRUE(tek_yonlu))
}

# -----------------------------------------------------------------------------
# Dissolution
# -----------------------------------------------------------------------------
.analiz_dis_adlar <- list(Product = c("product", "urun"), Unit = c("unit", "tablet", "unite", "birim", "kap"),
                          Time = c("time", "zaman", "dakika", "saat", "minute"),
                          Diss = c("diss", "cozunen", "dissolved", "yuzde", "percent"))
platform_dis_veri <- function(metin = NULL, ornek = NULL) {
  d <- if (identical(ornek, "tsong1996")) ornek_tsong() else if (identical(ornek, "noce2020")) ornek_noce() else {
    e <- .analiz_esle(platform_csv(metin), .analiz_dis_adlar)
    data.frame(Product = trimws(e$Product), Unit = trimws(e$Unit), Time = .analiz_sayi(e$Time),
               Diss = .analiz_sayi(e$Diss), stringsAsFactors = FALSE)
  }
  if (anyNA(d$Time) || anyNA(d$Diss)) stop("Time and dissolved values must be numbers.")
  list(Product = as.character(d$Product), Unit = as.character(d$Unit), Time = as.numeric(d$Time),
       Diss = as.numeric(d$Diss), urunler = unique(as.character(d$Product)))
}
# the v0.5.1 dissolution bridge in its own environment (its kp_hazirla() would
# otherwise replace the PBE bridge's function of the same name)
platform_dis_kopru <- function(path = system.file("kopru", "dis_kopru.R", package = "CNKfarmastatr"),
                               parent = environment(calc_msd)) {
  if (!nzchar(path) || !file.exists(path)) stop("dis_kopru.R not found.")
  e <- new.env(parent = parent)
  sys.source(path, envir = e, keep.source = FALSE)
  e
}
platform_dis <- function(kopru, veri, test, ref, lotlar = character(0), birim = "dakika",
                         yontem = c("f2", "msd", "weibull"), ayar = list()) {
  yontem <- match.arg(yontem)
  hz <- kopru$kp_hazirla(veri$Product, veri$Unit, veri$Time, veri$Diss, test, ref, lotlar, birim)
  g <- function(k, d) if (is.null(ayar[[k]])) d else ayar[[k]]
  # perspective presets of calc_f2_boot() (EMA Q&A 3.11; FDA 1997): explicit settings win
  ps <- if (identical(g("perspektif", "EMA"), "FDA")) list(tahminci = "f2", kesme = "FDA", cvkural = "FDA97", B = 10000)
        else list(tahminci = "Ef2", kesme = "EMA", cvkural = "M9", B = 5000)
  r <- switch(yontem,
    f2 = kopru$kp_f2(g("perspektif", "EMA"), g("tahminci", ps$tahminci), g("kesme", ps$kesme), g("kmod", "replika"),
                     g("cvkural", ps$cvkural), g("gatipi", "persentil"), g("B", ps$B), g("seed", 20260927), g("qtip", 7)),
    msd = kopru$kp_msd(g("sinir", "L1"), g("Dg", 10), g("kesme", "none")),
    weibull = kopru$kp_wb(g("param", "lnTd_lnB"), g("bolge", "B-L3"), g("Dg", 10), g("k", 3), g("bolen", "N")))
  list(hazir = hz, sonuc = r, yontem = yontem, test = test, ref = ref, lotlar = lotlar, birim = birim, ayar = ayar)
}
