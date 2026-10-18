# =============================================================================
# FSR-TN-PLT-04 - P4 acceptance, criterion U-10 (database version 2, T-1)
#   (a) bagimsiz_tekrar and mekanizma = source CSVs (every number exactly, row
#       counts equal); runs PBE01-A1-BT and PBE01-MEK present with version fields
#   (b) two builds give the same content dump SHA-256 (all tables, build time
#       excluded)
#   (c) the new tables read with sql.js (Node) = R (the browser read is part of the
#       browser acceptance tool)
#   (d) VT_SHA256.txt = SHA-256 of the database file
# Needs: RSQLite, the installed CNKfarmastatr package; Node + sql.js for (c).
# Run from the repository root:
#   Rscript belgeler/teknik_notlar/FSR-TN-PLT-04_ek/p4_kabul_vt.R [db] [sqljs_dir]
# Output: p4_kabul_vt.csv in this folder.
# Research and education only; not a system validated for GxP environments.
# =============================================================================
suppressPackageStartupMessages({ library(DBI); library(RSQLite) })
args <- commandArgs(trailingOnly = TRUE)
vt <- if (length(args) >= 1) args[1] else file.path("veri", "farmastatr_v1.sqlite")
sq_dir <- if (length(args) >= 2) args[2] else NA
out_dir <- file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-04_ek")
S <- file.path("simulasyon", "FSR-TN-PBE-01")
source(file.path("araclar", "sha256.R"), encoding = "UTF-8")
sha_file <- function(p) {
  if (exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE)) return(unname(tools::sha256sum(p)))
  if (requireNamespace("digest", quietly = TRUE)) return(digest::digest(file = p, algo = "sha256"))
  sha256_raw(readBin(p, "raw", file.info(p)$size))
}
sha_txt <- function(s) { f <- tempfile(); writeBin(charToRaw(enc2utf8(s)), f); on.exit(unlink(f)); sha_file(f) }
rd <- function(f) utils::read.csv(file.path(S, f), colClasses = "character", stringsAsFactors = FALSE)
num <- function(x) { v <- as.numeric(x); v[x %in% c("NA", "")] <- NA_real_; v }
res <- data.frame(kontrol = character(0), sonuc = character(0), ayrinti = character(0), stringsAsFactors = FALSE)
put <- function(k, ok, d) res[nrow(res) + 1, ] <<- c(k, if (isTRUE(ok)) "GECTI" else "KALDI", d)
same_num <- function(a, b) identical(is.na(a), is.na(b)) && all(a[!is.na(a)] == b[!is.na(b)])

con <- dbConnect(SQLite(), vt)
bt_db <- dbGetQuery(con, "SELECT b.*, s.izgara_kodu AS kod FROM bagimsiz_tekrar b JOIN senaryo s USING (senaryo_no)")
mk_db <- dbGetQuery(con, "SELECT * FROM mekanizma ORDER BY deney_no")
ks <- dbGetQuery(con, "SELECT * FROM kosu WHERE kosu_id IN ('PBE01-A1-BT', 'PBE01-MEK')")
vs <- dbGetQuery(con, "SELECT deger FROM insa WHERE anahtar = 'vt_surumu'")$deger
dbDisconnect(con)

# (a)
bt <- rd("bagimsiz_tekrar.csv"); mk <- rd("mekanizma.csv")
key_c <- paste(bt$scenario, bt$method); key_d <- paste(bt_db$izgara_kodu, bt_db$yontem_id)
m <- match(key_c, key_d)
ok_bt <- nrow(bt_db) == nrow(bt) && !anyNA(m) && all(bt_db$kod[m] == bt$scenario) &&
  same_num(bt_db$asama1[m], num(bt$stage1)) && same_num(bt_db$asama1_mcse[m], num(bt$stage1_mcse)) &&
  same_num(bt_db$tekrar[m], num(bt$rerun)) && same_num(bt_db$tekrar_mcse[m], num(bt$rerun_mcse)) &&
  same_num(bt_db$z[m], num(bt$z)) && same_num(bt_db$pB[m], num(bt$pB)) && all(bt_db$delta_ad[m] == bt$delta_id)
ok_mk <- nrow(mk_db) == nrow(mk) && all(vapply(names(mk), function(k) same_num(mk_db[[k]], num(mk[[k]])), TRUE))
ok_k <- nrow(ks) == 2 && all(!is.na(ks$seed) & !is.na(ks$rng) & !is.na(ks$r_surumu) & !is.na(ks$paket_surumu) &
                               !is.na(ks$motor_surumu) & (!is.na(ks$motor_sha256) | !is.na(ks$motor_sha256_not)))
put("U-10 (a) Yeni tablolar = CSV; koşu satırları", ok_bt && ok_mk && ok_k && identical(vs, "2"),
    sprintf("bagimsiz_tekrar %d/%d satır birebir: %s; mekanizma %d/%d satır, %d sütun birebir: %s; koşu satırı 2, sürüm alanları dolu: %s; vt_surumu %s",
            nrow(bt_db), nrow(bt), ok_bt, nrow(mk_db), nrow(mk), ncol(mk), ok_mk, ok_k, vs))

# (b) deterministic build over all tables
vt_dokum <- function(path) {
  con <- dbConnect(SQLite(), path); on.exit(dbDisconnect(con))
  tabs <- dbGetQuery(con, "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name")$name
  txt <- character(0)
  for (t in tabs) {
    sch <- dbGetQuery(con, sprintf("SELECT sql FROM sqlite_master WHERE name = '%s'", t))$sql
    pk <- dbGetQuery(con, sprintf("PRAGMA table_info(%s)", t)); pk <- pk$name[pk$pk > 0][order(pk$pk[pk$pk > 0])]
    x <- dbGetQuery(con, sprintf("SELECT * FROM %s ORDER BY %s", t, paste(pk, collapse = ", ")))
    if (t == "insa") x <- x[x$anahtar != "insa_zamani", ]
    f <- function(v) if (is.numeric(v)) ifelse(is.na(v), "NULL", sprintf("%.17g", v)) else ifelse(is.na(v), "NULL", v)
    rows <- if (nrow(x)) do.call(paste, c(lapply(x, f), sep = "\t")) else character(0)
    txt <- c(txt, paste("TABLE", t), sch, rows)
  }
  txt
}
tmp <- tempfile(fileext = ".sqlite")
o <- system2(file.path(R.home("bin"), "Rscript"), c("araclar/vt_insa.R", shQuote(tmp)), stdout = TRUE, stderr = TRUE)
d1 <- vt_dokum(vt); d2 <- vt_dokum(tmp)
h1 <- sha_txt(paste(d1, collapse = "\n")); h2 <- sha_txt(paste(d2, collapse = "\n"))
put("U-10 (b) İki inşanın döküm SHA-256'sı aynı (bütün tablolar)", identical(h1, h2) && length(d1) > 0,
    sprintf("döküm %s; tablo sayısı %d", substr(h1, 1, 16), sum(grepl("^TABLE ", d1))))
unlink(c(tmp, file.path(dirname(tmp), "VT_SHA256.txt")))

# (c) sql.js
if (is.na(sq_dir)) put("U-10 (c) sql.js ile okuma = R", FALSE, "sql.js çıktısı verilmedi (vt_oku_p4.mjs)") else {
  jb <- utils::read.csv(file.path(sq_dir, "sqljs_bagimsiz_tekrar.csv"), colClasses = "character", na.strings = "NA")
  jm <- utils::read.csv(file.path(sq_dir, "sqljs_mekanizma.csv"), colClasses = "character", na.strings = "NA")
  con <- dbConnect(SQLite(), vt)
  rb <- dbGetQuery(con, "SELECT * FROM bagimsiz_tekrar ORDER BY senaryo_no, yontem_id")
  rm_ <- dbGetQuery(con, "SELECT * FROM mekanizma ORDER BY deney_no"); dbDisconnect(con)
  eq <- function(r, j) all(vapply(names(r), function(k) if (is.numeric(r[[k]])) same_num(r[[k]], num(j[[k]])) else identical(r[[k]], j[[k]]), TRUE))
  put("U-10 (c) sql.js ile okuma = R", nrow(jb) == nrow(rb) && nrow(jm) == nrow(rm_) && eq(rb, jb) && eq(rm_, jm),
      sprintf("bagimsiz_tekrar %d, mekanizma %d satır; bütün sütunlar birebir", nrow(jb), nrow(jm)))
}

# (d)
vs_txt <- readLines(file.path(dirname(vt), "VT_SHA256.txt"), warn = FALSE)
put("U-10 (d) VT_SHA256.txt = veri tabanı dosyası", identical(sub(" .*", "", vs_txt), sha_file(vt)),
    sprintf("%s", substr(sha_file(vt), 1, 16)))

utils::write.csv(res, file.path(out_dir, "p4_kabul_vt.csv"), row.names = FALSE, fileEncoding = "UTF-8")
for (r in seq_len(nrow(res))) cat(sprintf("  %-6s %s\n         %s\n", res$sonuc[r], res$kontrol[r], res$ayrinti[r]))
