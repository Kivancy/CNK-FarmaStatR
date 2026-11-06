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

# -----------------------------------------------------------------------------
# FSR-TN-PLT-14 (KK-80; request 11052026-a): data of the charts, the variability
#   table and the bootstrap replicate files of the last dissolution analysis.
#   Nothing new is estimated here: the values are taken from the bridge result
#   (hazir, sonuc) and from the bridge's own copy of the f2 result (kopru$.kp$f2);
#   the histogram counts and the CV ratio are the only arithmetic.
# -----------------------------------------------------------------------------
# r: result of platform_dis(); returns lists that the screen and the report draw
platform_dis_grafik <- function(kopru, r) {
  h <- r$hazir; s <- r$sonuc; d <- kopru$.kp$d
  kul <- switch(r$yontem,
    f2 = d$zaman_dk %in% as.numeric(s$zamanlar),
    msd = d$zaman %in% as.numeric(s$zamanlar),
    weibull = rep(TRUE, length(d$zaman)))
  out <- list(yontem = r$yontem, zaman = h$zaman, ortT = h$ortT, sdT = h$sdT, ortR = h$ortR, sdR = h$sdR,
              kullanilan = kul, test = r$test, ref = r$ref)
  if (r$yontem == "f2") {
    f <- kopru$.kp$f2
    v <- f$replikalar[, f$tahminci]; v <- v[is.finite(v)]
    br <- pretty(range(v), n = 30)
    # counts as graphics::hist (right-closed, lowest included), with base R only
    out$hist <- list(kirilim = br, sayi = tabulate(cut(v, br, include.lowest = TRUE, right = TRUE, labels = FALSE), nbins = length(br) - 1L),
                     tahminci = f$tahminci, nokta = unname(f$nokta[f$tahminci]),
                     alt = unname(f$karar_ga["alt"]), ust = unname(f$karar_ga["ust"]), B_gecerli = length(v))
  }
  if (r$yontem == "weibull") out$egri <- list(tt = s$tt, egT = s$egT, egR = s$egR)
  out
}
# variability of test and reference at every time point (EMA 2010 Annex I; shown, not judged)
platform_dis_degiskenlik <- function(r) {
  h <- r$hazir
  list(zaman = h$zaman, cvT = h$cvT, cvR = h$cvR, oran = h$cvT / h$cvR)
}
# bootstrap replicates of the last f2 analysis as CSV text; with indeks = TRUE also the
# drawn units and a SAS program that recomputes every replicate from them.
#   kunye: named character values added to the header (package version, data SHA-256, ...)
platform_f2_disa <- function(kopru, indeks = FALSE, kunye = list()) {
  f <- kopru$.kp$f2
  if (is.null(f)) stop("No f2 analysis has been run.")
  d <- kopru$.kp$d; k <- f$kontrol
  XT <- if (f$kesme_modu == "replika") k$XT_tum else k$XT
  XR <- if (f$kesme_modu == "replika") k$XR_tum else k$XR
  zm <- if (f$kesme_modu == "replika") k$zaman_tum else k$zamanlar
  g17 <- function(x) ifelse(is.na(x), "", sprintf("%.17g", x))
  ga <- f$GA[f$tahminci, c("alt", "ust")]
  bas <- c(
    "# CNK-FarmaStatR - bootstrap f2 replicates (FSR-TN-PLT-14, KK-80)",
    "# Research and education only; not a system validated for GxP environments.",
    sprintf("# %s: %s", names(kunye), unlist(kunye)),
    sprintf("# test: %s; reference: %s; n_T = %d; n_R = %d", d$test_ad, d$ref_ad, nrow(XT), nrow(XR)),
    sprintf("# time points of the bootstrap (minutes): %s", paste(zm, collapse = " ")),
    sprintf("# B = %d; seed = %s; RNG = %s", f$B, format(f$seed, scientific = FALSE), f$rng),
    sprintf("# estimator = %s; truncation = %s; truncation mode = %s; interval = %s; quantile type = %d; level = %s",
            f$tahminci, k$truncation, f$kesme_modu, f$ga_tipi, f$q_type, format(f$conf)),
    sprintf("# point estimates: f2 = %s; Ef2 = %s; bcf2 = %s", g17(f$nokta["f2"]), g17(f$nokta["Ef2"]), g17(f$nokta["bcf2"])),
    sprintf("# decision interval (%s): lower = %s; upper = %s", f$ga_tipi, g17(f$karar_ga["alt"]), g17(f$karar_ga["ust"])),
    sprintf("# percentile interval of %s: lower = %s; upper = %s", f$tahminci, g17(ga["alt"]), g17(ga["ust"])),
    "# columns: rep, f2, Ef2, bcf2 (empty: undefined), P (time points after truncation in the replicate)")
  rp <- f$replikalar
  cols <- c("rep", "f2", "Ef2", "bcf2", "P")
  body <- cbind(seq_len(nrow(rp)), g17(rp[, "f2"]), g17(rp[, "Ef2"]), g17(rp[, "bcf2"]), as.integer(rp[, "P"]))
  if (isTRUE(indeks)) {
    bas <- c(bas,
      "# T1 ... and R1 ...: row numbers of the units drawn in the replicate (1-based):",
      sprintf("#   test units: %s", paste(sprintf("%d=%s", seq_len(nrow(XT)), rownames(XT)), collapse = "; ")),
      sprintf("#   reference units: %s", paste(sprintf("%d=%s", seq_len(nrow(XR)), rownames(XR)), collapse = "; ")))
    cols <- c(cols, paste0("T", seq_len(ncol(f$idx$T))), paste0("R", seq_len(ncol(f$idx$R))))
    body <- cbind(body, f$idx$T, f$idx$R)
  }
  csv <- paste(c(bas, paste(cols, collapse = ","), apply(body, 1, paste, collapse = ",")), collapse = "\n")
  list(csv = paste0(csv, "\n"), sas = if (isTRUE(indeks)) .f2_sas(f, XT, XR, zm, ga, kunye) else NULL)
}
.f2_sas <- function(f, XT, XR, zm, ga, kunye) {
  g15 <- function(x) sprintf("%.15g", x)
  g17 <- function(x) sprintf("%.17g", x)
  satir <- function(M) apply(M, 1, function(r) paste(g15(r), collapse = " "))
  qt <- f$q_type
  ab <- switch(as.character(qt), "4" = c(0, 1), "5" = c(0.5, 0.5), "6" = c(0, 0), "7" = c(1, 1),
               "8" = c(1/3, 1/3), "9" = c(3/8, 3/8), c(NA, NA))
  paste0(paste(c(
"/* ===========================================================================",
"   CNK-FarmaStatR - bootstrap f2 cross-check in SAS (FSR-TN-PLT-14, KK-80)",
"   Research and education only; not a system validated for GxP environments.",
sprintf("   %s: %s", names(kunye), unlist(kunye)),
"   Recomputes every bootstrap replicate from the units drawn by the platform",
"   (the companion CSV with the T1... and R1... columns), using the analysis data",
"   below, and compares f2, Ef2, bc-f2, P and the percentile interval with the",
"   platform. R and SAS random number generators differ; with the drawn units",
"   the agreement must be exact up to floating point (criterion BS-7).",
"   Usage (e.g. SAS OnDemand): upload this program and the CSV to the same folder,",
"   set CSV below to the full path of the CSV, run. Requires SAS/IML.",
"   =========================================================================== */",
sprintf("%%let csv = %s;   /* full path, e.g. /home/u12345/<file>.csv */", if (!is.null(kunye$csv)) kunye$csv else "boot.csv"),
sprintf("%%let nT = %d; %%let nR = %d; %%let nP = %d; %%let B = %d;", nrow(XT), nrow(XR), ncol(XT), f$B),
sprintf("%%let rule = %s;     /* EMA, FDA or none */", f$kontrol$truncation),
sprintf("%%let mode = %s;     /* replika: truncation in every replicate; sabit: fixed time points */", f$kesme_modu),
sprintf("%%let est = %s;      /* f2, Ef2 or bcf2 */", f$tahminci),
sprintf("%%let qa = %s; %%let qb = %s;   /* Hyndman-Fan type %d (alpha, beta); . = type not reproduced here */", if (is.na(ab[1])) "." else g17(ab[1]), if (is.na(ab[2])) "." else g17(ab[2]), qt),
sprintf("%%let conf = %s;", g17(f$conf)),
sprintf("%%let p_lo = %s; %%let p_hi = %s;   /* platform percentile interval of the estimator */", g17(ga["alt"]), g17(ga["ust"])),
"",
sprintf("/* analysis data: rows = units, columns = time points (minutes): %s */", paste(zm, collapse = " ")),
"data test_u; input x1-x&nP; datalines;", satir(XT), ";", "run;",
"data ref_u; input x1-x&nP; datalines;", satir(XR), ";", "run;",
"",
"data boot;",
"  infile \"&csv\" dsd truncover lrecl=1000000;",
"  input @1 first $1. @;",
"  if first in ('#', 'r', ' ') then delete;   /* header, column names, empty lines */",
"  input @1 rep f2 Ef2 bcf2 P T1-T&nT R1-R&nR;",
"  drop first;",
"run;",
"",
"proc iml;",
"  use test_u; read all var _num_ into XT; close test_u;",
"  use ref_u;  read all var _num_ into XR; close ref_u;",
"  vT = \"T1\":\"T&nT\"; vR = \"R1\":\"R&nR\";",
"  use boot; read all var {f2 Ef2 bcf2 P} into V; read all var vT into IT; read all var vR into IR; close boot;",
"  B = nrow(V); W = j(B, 4, .); cut = 85;",
"  do b = 1 to B;",
"    xt = XT[IT[b, ], ]; xr = XR[IR[b, ], ];",
"    mT = round(xt[:, ], 1e-10); mR = round(xr[:, ], 1e-10);",
"    np = ncol(XT);",
"    if \"&mode\" = \"replika\" & \"&rule\" ^= \"none\" then do;",
"      if \"&rule\" = \"EMA\" then a = loc(mT > cut | mR > cut); else a = loc(mT > cut & mR > cut);",
"      if ncol(a) > 0 then np = a[1];",
"    end;",
"    W[b, 4] = np;",
"    if np >= 3 then do;",
"      t = xt[, 1:np]; r = xr[, 1:np];",
"      D = ssq(t[:, ] - r[:, ]);",
"      ct = t - repeat(t[:, ], nrow(t), 1); cr = r - repeat(r[:, ], nrow(r), 1);",
"      Vr = sum(ct[##, ] / (nrow(t) - 1) / nrow(t)) + sum(cr[##, ] / (nrow(r) - 1) / nrow(r));",
"      W[b, 1] = 100 - 25 * log10(1 + D / np);",
"      W[b, 2] = 100 - 25 * log10(1 + (D + Vr) / np);",
"      if D > Vr then W[b, 3] = 100 - 25 * log10(1 + (D - Vr) / np);",
"    end;",
"  end;",
"  /* largest absolute differences SAS - platform, and differences in undefined values */",
"  maxd = j(1, 4, 0); nmiss = j(1, 4, 0);",
"  do k = 1 to 4;",
"    nmiss[k] = sum((W[, k] = .) ^= (V[, k] = .));",
"    ok = loc((W[, k] ^= .) & (V[, k] ^= .));",
"    if ncol(ok) > 0 then maxd[k] = max(abs(W[ok, k] - V[ok, k]));",
"  end;",
"  print maxd[colname = {'f2' 'Ef2' 'bcf2' 'P'} label = 'Largest |SAS - platform| over the replicates'];",
"  print nmiss[colname = {'f2' 'Ef2' 'bcf2' 'P'} label = 'Replicates where only one side is undefined'];",
"  /* percentile interval of the estimator (Hyndman-Fan continuous types 4-9) */",
"  col = (\"&est\" = \"f2\") * 1 + (\"&est\" = \"Ef2\") * 2 + (\"&est\" = \"bcf2\") * 3;",
"  v = W[loc(W[, col] ^= .), col]; call sort(v, 1); n = nrow(v);",
"  a2 = (1 - &conf) / 2; pr = a2 || (1 - a2); q = j(1, 2, .);",
"  if &qa ^= . then do i = 1 to 2;",
"    m = &qa + pr[i] * (1 - &qa - &qb); jj = floor(n * pr[i] + m + 4 * constant('maceps')); g = n * pr[i] + m - jj;",
"    if abs(g) < 4 * constant('maceps') then g = 0;",
"    lo = max(1, min(n, jj)); hi = max(1, min(n, jj + 1));",
"    q[i] = (1 - g) * v[lo] + g * v[hi];",
"  end;",
"  plat = &p_lo || &p_hi; dq = abs(q - plat);",
"  print q[colname = {'lower' 'upper'} label = 'SAS percentile interval'],",
"        plat[colname = {'lower' 'upper'} label = 'Platform percentile interval'],",
"        dq[colname = {'lower' 'upper'} label = '|difference|'];",
"  ok_rep = (max(maxd[1:3]) <= 1e-10) & (maxd[4] = 0) & (sum(nmiss) = 0);",
"  ok_ci = (max(dq) <= 1e-8);",
"  result = ifc(ok_rep & ok_ci, 'AGREE: replicates and interval equal the platform (BS-7)',",
"                               'DIFFERENT: see the tables above');",
"  print result[label = 'Result'];",
"quit;"), collapse = "\n"), "\n")
}
