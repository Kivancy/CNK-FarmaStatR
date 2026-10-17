# =============================================================================
# CNK-FarmaStatR - In vitro PBE (FDA PSG 020929) with your own data, in local R
#
# Uses the validated core unchanged: kp_hazirla() (input checks B-2, B-4) and
# kp_pbe() -> calc_pbe() (CNKfarmastatr/R/pbe_core.R, pbe_kopru.R).
# This file is only a convenience wrapper for reading a CSV and printing the result.
#
# KULLANIM (R konsolunda):
#   setwd("C:/cloud/CNK-FarmaStatR/CNK-FarmaStatR")
#   source("araclar/pbe_hesapla.R", encoding = "UTF-8")
#   pbe_hesapla("araclar/pbe_ornek_psg020929.csv", log_d = FALSE)   # PSG örneği
#   pbe_hesapla("C:/verilerim/olcumler.csv", log_d = TRUE)          # kendi veriniz
#
# CSV: one row per measurement, five columns with these names (any order):
#   parti, kap, asama, urun, olcum
#   - urun: product label; by default "TEST" and "REF" (change with test=, ref=)
#   - every container (kap) must be measured exactly once at every stage (asama)
#   - Excel "CSV (noktalı virgülle ayrılmış)" with decimal comma is also accepted
#   - .xlsx / .xls: the first sheet is read (needs the readxl package)
#   - one stage only (m = 1) needs nothing extra: asama holds the same value in all rows
# log_d = TRUE : raw measurements, ln is taken by the core (all values must be > 0)
# log_d = FALSE: values are used as given (e.g. already on the ln scale)
#
# Research and education only; not a system validated for GxP environments.
# =============================================================================
for (.f in c("pbe_core.R", "pbe_kopru.R"))
  source(file.path("CNKfarmastatr", "R", .f), encoding = "UTF-8")
rm(.f)

.pbe_oku <- function(dosya) {
  if (!file.exists(dosya)) stop("Dosya bulunamadı: ", normalizePath(dosya, mustWork = FALSE),
                                "\n  Çalışma klasörü: ", getwd())
  if (grepl("\\.xlsx?$", dosya, ignore.case = TRUE)) {
    if (!requireNamespace("readxl", quietly = TRUE))
      stop("Excel dosyası için readxl paketi gerekli: install.packages(\"readxl\")\n  ya da dosyayı Excel'de CSV olarak kaydedin.")
    d <- as.data.frame(readxl::read_excel(dosya, sheet = 1, col_types = "text"), stringsAsFactors = FALSE)
    return(.pbe_sutunlar(d, "Excel, ilk sayfa"))
  }
  ilk <- readLines(dosya, n = 1, warn = FALSE, encoding = "UTF-8")
  ilk <- sub("^\ufeff", "", ilk)                                    # BOM from Excel
  noktali <- lengths(regmatches(ilk, gregexpr(";", ilk))) > lengths(regmatches(ilk, gregexpr(",", ilk)))
  d <- if (noktali) utils::read.csv2(dosya, colClasses = "character", fileEncoding = "UTF-8-BOM", strip.white = TRUE)
       else utils::read.csv(dosya, colClasses = "character", fileEncoding = "UTF-8-BOM", strip.white = TRUE)
  .pbe_sutunlar(d, if (noktali) "CSV, noktalı virgül" else "CSV, virgül")
}

.pbe_sutunlar <- function(d, kaynak) {
  names(d) <- tolower(trimws(names(d)))
  names(d) <- chartr("şıçğüö", "sicguo", names(d))                   # aşama -> asama, ölçüm -> olcum
  gerek <- c("parti", "kap", "asama", "urun", "olcum")
  eksik <- setdiff(gerek, names(d))
  if (length(eksik)) stop("CSV'de eksik sütun: ", paste(eksik, collapse = ", "),
                          "\n  Bulunan sütunlar: ", paste(names(d), collapse = ", "),
                          "\n  Gerekli: parti, kap, asama, urun, olcum")
  d <- d[!(is.na(d$olcum) & is.na(d$parti) & is.na(d$kap)), , drop = FALSE]   # empty Excel rows
  d$olcum <- gsub(",", ".", d$olcum, fixed = TRUE)                  # decimal comma
  list(d = d, ayrac = kaynak)
}

pbe_hesapla <- function(dosya, log_d = TRUE, test = "TEST", ref = "REF", tek_yonlu = FALSE) {
  o <- .pbe_oku(dosya); d <- o$d
  h <- kp_hazirla(parti = d$parti, kap = d$kap, asama = d$asama, urun = d$urun,
                  deger = d$olcum, test = test, ref = ref, log_d = log_d)
  r <- kp_pbe(tek_yonlu = tek_yonlu)
  f <- function(x, k = 6) formatC(x, digits = k, format = "f")
  cat("\nCNK-FarmaStatR · In vitro PBE (FDA PSG 020929)\n")
  cat("Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.\n\n")
  cat(sprintf("Dosya       : %s (%d satır; %s)\n", dosya, nrow(d), o$ayrac))
  cat(sprintf("Ölçek       : %s\n", h$olcek))
  cat(sprintf("Tasarım     : TEST %d parti, %d kap · REF %d parti, %d kap · %d aşama (%s)\n",
              h$T$parti, h$T$toplam_kap, h$R$parti, h$R$toplam_kap, h$m, paste(h$asamalar, collapse = ", ")))
  if (length(h$uyarilar)) cat("Uyarılar    :\n", paste0("  - ", h$uyarilar, collapse = "\n"), "\n", sep = "")
  cat("\n")
  cat(sprintf("σT, σR      : %s, %s\n", f(r$Sigma_T, 4), f(r$Sigma_R, 4)))
  if (!is.null(r$GMR)) cat(sprintf("GMR (T/R)   : %s\n", f(r$GMR, 4)))
  cat(sprintf("Kriter      : %s (σR %s σT0 = %s)\n", r$criterion, if (r$Sigma_R > r$SigmaT0) ">" else "≤", r$SigmaT0))
  cat(sprintf("Eη          : %s\n", f(r$Eq_final)))
  cat(sprintf("Hη (95%% üst): %s\n", f(r$H_eta_final)))
  cat(sprintf("Sonuç       : %s (Hη ≤ 0 ise PBE gösterilmiştir)\n\n", r$pass_fail))
  invisible(r)
}
