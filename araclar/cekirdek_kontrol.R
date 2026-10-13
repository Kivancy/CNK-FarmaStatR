# =============================================================================
# CNK-FarmaStatR v1 · Validated core integrity check (SHA-256, base R only)
#   Run from the CNK-FarmaStatR-v1 folder:  source("araclar/cekirdek_kontrol.R")
#   Compares CNKfarmastatr/R/*.R with inst/validasyon/CEKIRDEK_SHA256.txt.
#   A mismatch means a validated file changed: re-run the tests and record a
#   revision in the validation document (project instructions, "Validasyon").
# =============================================================================
source(file.path("araclar", "sha256.R"), encoding = "UTF-8")
liste <- read.table(file.path("CNKfarmastatr", "inst", "validasyon", "CEKIRDEK_SHA256.txt"),
                    col.names = c("sha256", "dosya"), stringsAsFactors = FALSE)
hesap <- vapply(liste$dosya, function(f) {
  yol <- file.path("CNKfarmastatr", "R", f)
  sha256_raw(readBin(yol, "raw", file.info(yol)$size))
}, character(1))
liste$durum <- ifelse(hesap == liste$sha256, "AYNI", "DEĞİŞMİŞ")
print(liste[, c("dosya", "durum")], row.names = FALSE)
cat(if (all(liste$durum == "AYNI")) "\nÇekirdekler: tümü validasyondaki hâliyle aynı.\n"
    else "\nUYARI: değişmiş çekirdek var. Testleri yeniden koşun ve belgeye işleyin.\n")
