# =============================================================================
# FSR-TN-PLT-04 - reference texts for the display rule P4-K3 (criterion U-2)
#   Every rate of the database (olcut type "oran") written as the published tables
#   were written: formatC(100 * x, format = "f", digits = 1) and, for the MCSE,
#   digits = 2, by R on Linux (glibc: nearest to the binary value, exact ties to even).
#   Windows R differs on exact ties (G-73), so the reference is made on Linux only
#   and kept in the repository; CI (Linux) checks that it is still reproduced.
# Run from the repository root (Linux):  Rscript belgeler/teknik_notlar/FSR-TN-PLT-04_ek/p4_bicim_referans.R
# Output: p4_bicim_referans.csv (key, rate text, MCSE text, the two values with 17
#   significant digits) in this folder; the values let CI check the reference
#   without the database (test-platform-bicim.R).
# Research and education only; not a system validated for GxP environments.
# =============================================================================
if (.Platform$OS.type == "windows") stop("Make the reference on Linux (Windows R rounds exact ties differently, G-73).")
suppressPackageStartupMessages({ library(DBI); library(RSQLite) })
con <- dbConnect(SQLite(), file.path("veri", "farmastatr_v1.sqlite"))
x <- dbGetQuery(con, "SELECT s.senaryo_no, s.kosu_id, s.yontem_id, s.olcut_id, s.tahmin, s.mcse FROM sonuc s JOIN olcut o USING (olcut_id) WHERE o.tur = 'oran' ORDER BY 1, 2, 3, 4")
dbDisconnect(con)
ref <- data.frame(anahtar = paste(x$senaryo_no, x$kosu_id, x$yontem_id, x$olcut_id, sep = "|"),
                  oran = formatC(100 * x$tahmin, format = "f", digits = 1),
                  mcse = ifelse(is.na(x$mcse), "NA", formatC(100 * x$mcse, format = "f", digits = 2)),
                  deger_oran = sprintf("%.17g", x$tahmin), deger_mcse = ifelse(is.na(x$mcse), "NA", sprintf("%.17g", x$mcse)),
                  stringsAsFactors = FALSE)
utils::write.csv(ref, file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-04_ek", "p4_bicim_referans.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat(nrow(ref), "satır\n")
