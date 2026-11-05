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
# EMA OIP Rev. 2 Section 5.1 criterion 8 (90% CI of the T/R ratio within 0.85-1.18)
#   on one's own data (FSR-TN-PLT-08, KK-64). Input checks: the PBE bridge (kp_hazirla);
#   long -> array: invitro_array; computation: ema_ci_fast (validated simulation engine,
#   FSR-VAL-SIM-1 v1.1). Nothing is computed here. Paths (a), (b), (c) are candidate
#   implementations (FarmaStatR derivation, KK-27); the decision line is path (b).
# -----------------------------------------------------------------------------
platform_ema <- function(veri, test = "TEST", ref = "REF", log_d = FALSE, level = 0.90, limits = c(0.85, 1.18)) {
  h <- kp_hazirla(parti = veri$parti, kap = veri$kap, asama = veri$asama, urun = veri$urun,
                  deger = veri$olcum, test = test, ref = ref, log_d = log_d)
  for (p in c("T", "R")) if (h[[p]]$kap_min != h[[p]]$kap_max)
    stop(sprintf("EMA %%90 GA yaln\u0131z dengeli tasar\u0131mda hesaplan\u0131r: %s \u00fcr\u00fcn\u00fcnde parti ba\u015f\u0131na kap say\u0131s\u0131 farkl\u0131 (%d\u2013%d). Dengesiz tasar\u0131mda FDA PBE se\u00e7ilebilir.",
                 if (p == "T") "TEST" else "REF", h[[p]]$kap_min, h[[p]]$kap_max))
  df <- .pbe$df
  if (isTRUE(log_d)) df$score <- log(df$score)
  aT <- invitro_array(df, "TEST"); aR <- invitro_array(df, "REF")
  r <- ema_ci_fast(aT$X, aR$X, aT$l, aT$n, aR$l, aR$n, level = level, limits = limits)
  tab <- do.call(rbind, r)
  ok <- is.finite(tab$lower) & is.finite(tab$upper) & is.finite(tab$se) & is.finite(tab$df)
  if (!all(ok)) {
    tab[!ok, c("lower", "upper", "se", "df")] <- NA_real_; tab$pass[!ok] <- NA
    h$uyarilar <- c(h$uyarilar, sprintf("Hesaplanamayan yol: %s. Serbestlik derecesi ya da standart hata s\u0131f\u0131r (en az iki seri ve seriler aras\u0131 de\u011fi\u015fkenlik gerekir).",
                                        paste(tab$method[!ok], collapse = ", ")))
  }
  h$uyarilar <- h$uyarilar[!grepl("PSG_020929", h$uyarilar, fixed = TRUE)]
  if (aT$l < 3 || aR$l < 3 || aT$n < 10 || aR$n < 10) h$uyarilar <- c(h$uyarilar, "EMA OIP Rev. 2 B\u00f6l\u00fcm 5.1: her \u00fcr\u00fcnde en az \u00fc\u00e7 seri ve seri ba\u015f\u0131na en az on birim \u00f6nerilir.")
  list(hazir = h,
       sonuc = list(yol = as.character(tab$method), gmr = tab$gmr, alt = tab$lower, ust = tab$upper,
                    se = tab$se, sd = tab$df, gecti = tab$pass, karar = tab$pass[tab$method == "b"],
                    uyum = if (anyNA(tab$pass)) NA else length(unique(tab$pass)) == 1L, duzey = level, sinir = limits,
                    T = list(l = aT$l, n = aT$n, m = aT$m), R = list(l = aR$l, n = aR$n, m = aR$m)),
       test = test, ref = ref, log_d = isTRUE(log_d))
}

# -----------------------------------------------------------------------------
# Dissolution
# -----------------------------------------------------------------------------
.analiz_dis_adlar <- list(Product = c("product", "urun"), Unit = c("unit", "tablet", "unite", "birim", "kap"),
                          Time = c("time", "zaman", "dakika", "saat", "minute"),
                          Diss = c("diss", "cozunen", "dissolved", "yuzde", "percent"))
# Wide layout (FSR-TN-PLT-12, KK-78): rows = time points, columns = units,
#   header "Time, <product>.<unit>, ..." (DDSolver style). Returned in the long
#   layout ordered product -> time -> unit (column order), as the examples are.
.analiz_dis_genis_mi <- function(d) {
  nm <- .analiz_sutun(names(d))
  uzun <- all(vapply(.analiz_dis_adlar, function(a) any(.analiz_sutun(a) %in% nm), NA))
  !uzun && ncol(d) >= 2 && nm[1] %in% .analiz_sutun(.analiz_dis_adlar$Time)
}
.analiz_dis_genis <- function(d) {
  cn <- trimws(names(d))[-1]
  if (anyDuplicated(cn)) stop(sprintf("Duplicate column name(s): %s.", paste(unique(cn[duplicated(cn)]), collapse = ", ")))
  nokta <- regexpr("\\.[^.]*$", cn)
  urun <- ifelse(nokta > 0, trimws(substr(cn, 1, nokta - 1)), "")
  kap <- ifelse(nokta > 0, trimws(substr(cn, nokta + 1, nchar(cn))), "")
  bad <- !nzchar(urun) | !nzchar(kap)
  if (any(bad)) stop(sprintf("Column name(s) not of the form <product>.<unit> (e.g. Test.1, Ref.1): %s.",
                             paste(sprintf("'%s'", cn[bad]), collapse = ", ")))
  m <- as.matrix(d); m[is.na(m)] <- ""
  # DDSolver second header row ("(min)", "F(%)"): the first row without any number is skipped (by design, W-4)
  if (nrow(m) >= 1 && all(is.na(.analiz_sayi(m[1, ])))) m <- m[-1, , drop = FALSE]
  if (!nrow(m)) stop("No data rows.")
  zs <- trimws(m[, 1]); zaman <- .analiz_sayi(zs)
  if (anyNA(zaman)) stop(sprintf("Time must be a number: '%s' (data row %d).", zs[which(is.na(zaman))[1]], which(is.na(zaman))[1]))
  if (anyDuplicated(zaman)) stop(sprintf("Duplicate time point(s): %s.", paste(unique(zs[duplicated(zaman)]), collapse = ", ")))
  x <- m[, -1, drop = FALSE]; v <- matrix(.analiz_sayi(x), nrow(x))
  if (anyNA(v)) {
    k <- which(is.na(v), arr.ind = TRUE)[1, ]
    stop(sprintf("Empty or non-numeric cell: column %s, time %s ('%s'). Every unit needs a value at every time point.",
                 cn[k[2]], zs[k[1]], trimws(x[k[1], k[2]])))
  }
  P <- character(0); U <- character(0); Tm <- numeric(0); D <- numeric(0)
  for (p in unique(urun)) {
    j <- which(urun == p)
    for (i in seq_len(nrow(v))) {
      P <- c(P, rep(p, length(j))); U <- c(U, kap[j]); Tm <- c(Tm, rep(zaman[i], length(j))); D <- c(D, v[i, j])
    }
  }
  data.frame(Product = P, Unit = U, Time = Tm, Diss = D, stringsAsFactors = FALSE)
}
platform_dis_veri <- function(metin = NULL, ornek = NULL) {
  d <- if (identical(ornek, "tsong1996")) ornek_tsong() else if (identical(ornek, "noce2020")) ornek_noce() else {
    cs <- platform_csv(metin)
    if (.analiz_dis_genis_mi(cs)) .analiz_dis_genis(cs) else {
      e <- tryCatch(.analiz_esle(cs, .analiz_dis_adlar), error = function(err)
        stop(conditionMessage(err), " Accepted layouts: wide (Time, Test.1, Test.2, ..., Ref.1, ...) or long (Product, Unit, Time, Diss).", call. = FALSE))
      data.frame(Product = trimws(e$Product), Unit = trimws(e$Unit), Time = .analiz_sayi(e$Time),
                 Diss = .analiz_sayi(e$Diss), stringsAsFactors = FALSE)
    }
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
