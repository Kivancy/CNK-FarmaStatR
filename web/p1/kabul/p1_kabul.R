# =============================================================================
# CNK-FarmaStatR - P1 acceptance comparison (FSR-TN-PLT-01 v0.4, Tables 11.1-11.2)
#
# Reads the browser output p1_tarayici.csv (web/p1/kabul.html), recomputes the same
# quantities in local R with the same code (web/p1/kabul/kabul.R) from the same
# engine files, and evaluates every criterion of Table 11.1 as GECTI (pass),
# KALDI (fail) or EKSIK (data missing). The criteria were frozen before the test
# (KK-45); this script only applies them.
#   Rule K(a, r): |x_hat - x| <= a + r * max(|x|, |x_hat|)   (KK-41), a = r = 1e-12
# Run from the repository root:
#   Rscript web/p1/kabul/p1_kabul.R [browser_csv] [output_folder]
# Defaults: belgeler/teknik_notlar/FSR-TN-PLT-01_ek/p1/p1_tarayici.csv and that folder.
# Version 0.2 (G-58, KK-46): the "Performans ve bellek" row is applied as frozen in
#   Table 11.1: "Aşılırsa test kalmaz; geçici üst sınır düşürülür". An exceeded time
#   or memory threshold is reported as ASILDI_SINIR_DUSER (threshold exceeded; the
#   temporary n_sim upper limit is lowered), not as KALDI. Version 0.1 wrote KALDI
#   (G-57), which did not follow the frozen text. The thresholds are unchanged.
# Version 0.3 (G-68; FSR-TN-PLT-01 v0.6): the 6 x 30 performance run is read with
#   n_sim 15,000 (revised Table 11.1); a browser file of the official P1 run (G-57,
#   n_sim 20,000) is still evaluated with its own n_sim. Thresholds unchanged.
# Base R only. Research and education only; not validated for GxP environments.
# =============================================================================
args <- commandArgs(trailingOnly = TRUE)
out_dir <- if (length(args) >= 2) args[2] else file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-01_ek", "p1")
br_csv  <- if (length(args) >= 1) args[1] else file.path(out_dir, "p1_tarayici.csv")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# --- engine files: pinned ones must match the validation list ----------------
source(file.path("araclar", "sha256.R"), encoding = "UTF-8")
Rdir <- file.path("CNKfarmastatr", "R")
pin <- utils::read.table(file.path("CNKfarmastatr", "inst", "validasyon", "CEKIRDEK_SHA256.txt"),
                         col.names = c("sha256", "dosya"), stringsAsFactors = FALSE)
shaf <- function(p) sha256_raw(readBin(p, "raw", file.info(p)$size))
files <- c("invitro_fast.R", "invitro_grid.R", "pbe_ornek_veri.R", "platform_input.R")
for (f in files) {
  h <- shaf(file.path(Rdir, f)); exp <- pin$sha256[pin$dosya == f]
  if (length(exp) == 1 && h != exp) stop("Pinned file changed: ", f)
  source(file.path(Rdir, f), encoding = "UTF-8")
}
source(file.path("web", "p1", "kabul", "kabul.R"), encoding = "UTF-8")

# --- local computation (same code as in the browser) -------------------------
loc <- p1_kabul_hepsi()
utils::write.csv(loc, file.path(out_dir, "p1_yerel_r.csv"), row.names = FALSE, fileEncoding = "UTF-8")
br <- utils::read.csv(br_csv, colClasses = "character", encoding = "UTF-8", fileEncoding = "UTF-8")

K <- function(xh, x, a = 1e-12, r = 1e-12) {
  both_na <- is.na(xh) & is.na(x)
  ok <- abs(xh - x) <= a + r * pmax(abs(x), abs(xh))
  both_na | (!is.na(ok) & ok) | (!is.na(xh) & !is.na(x) & xh == x)
}
res <- data.frame(olcut = character(0), sonuc = character(0), ayrinti = character(0), stringsAsFactors = FALSE)
put <- function(o, s, a) res[nrow(res) + 1, ] <<- c(o, s, a)
detail <- list()
key <- function(d) paste(d$bolum, d$anahtar, d$ad, sep = " | ")
get <- function(an, ad) { v <- br$deger[br$bolum == "olcum" & br$anahtar == an & br$ad == ad]; if (length(v)) v[1] else NA_character_ }
tf <- function(v) !is.na(v) && v == "TRUE"

# 1 Test kümesi
kb <- unique(br$anahtar[br$bolum == "kosu"]); kl <- unique(loc$anahtar[loc$bolum == "kosu"])
put("Test kümesi (36 koşu)", if (length(kb) == 0) "EKSIK" else if (length(kb) == 36 && setequal(kb, kl)) "GECTI" else "KALDI",
    sprintf("tarayıcı %d koşu, yerel R %d koşu", length(kb), length(kl)))

# 2 Nihai karar birebirliği (counts) and 3 Ara değerler (K rule)
cmp <- merge(loc, br[br$bolum %in% c("kosu", "ara"), ], by = c("bolum", "anahtar", "ad"),
             all.x = TRUE, suffixes = c("_r", "_t"))
cmp <- cmp[cmp$bolum %in% c("kosu", "ara"), ]
missing_rows <- sum(is.na(cmp$deger_t))
x <- suppressWarnings(as.numeric(cmp$deger_r)); xh <- suppressWarnings(as.numeric(cmp$deger_t))
is_cnt <- cmp$bolum == "kosu" & grepl("(_pass|_cover|_crit_err|_pooled_T|_pooled_R)$", cmp$ad)
nsim <- as.numeric(loc$deger[loc$bolum == "kosu" & loc$ad == "n_sim"][1])
cnt_eq <- round(x[is_cnt] * nsim) == round(xh[is_cnt] * nsim)
if (nrow(cmp) == 0 || all(is.na(xh))) put("Nihai karar birebirliği", "EKSIK", "tarayıcı koşu satırı yok") else
  put("Nihai karar birebirliği", if (missing_rows == 0 && all(cnt_eq %in% TRUE)) "GECTI" else "KALDI",
      sprintf("%d sayım (geçme, kapsama, kriter seçim hatası, havuzlama) karşılaştırıldı; farklı: %d; eksik satır: %d",
              sum(is_cnt), sum(!(cnt_eq %in% TRUE)), missing_rows))
kok <- K(xh, x)
dd <- cmp[!kok | is.na(cmp$deger_t), ]
if (nrow(dd)) detail$ara <- dd
put("Ara değerler ve özetler K(1e-12, 1e-12)", if (nrow(cmp) == 0 || all(is.na(xh))) "EKSIK" else if (all(kok) && missing_rows == 0) "GECTI" else "KALDI",
    sprintf("%d değer (ara büyüklükler %d, koşu özetleri %d); kural dışı: %d; en büyük mutlak fark %.3g",
            nrow(cmp), sum(cmp$bolum == "ara"), sum(cmp$bolum == "kosu"), sum(!kok), suppressWarnings(max(abs(xh - x), na.rm = TRUE))))

# 4 Hata yakalama
hl <- loc[loc$bolum == "hata", ]; hb <- br[br$bolum == "hata", ]
hm <- merge(hl, hb, by = c("bolum", "anahtar", "ad"), all.x = TRUE, suffixes = c("_r", "_t"))
same <- !is.na(hm$deger_t) & hm$deger_t == hm$deger_r
kind_ok <- ifelse(startsWith(hm$anahtar, "motor"), startsWith(hm$deger_r, "motor: "), startsWith(hm$deger_r, "platform: "))
if (any(!same)) detail$hata <- hm[!same, ]
put("Hata yakalama", if (nrow(hb) == 0) "EKSIK" else if (all(same) && all(kind_ok)) "GECTI" else "KALDI",
    sprintf("%d vaka; tarayıcı = yerel R: %d; motorun reddettiği 3 vaka motor iletisiyle, platform kontrolünün reddettiği 3 vaka kodla; hiçbirinde koşu başlamadı: %s",
            nrow(hm), sum(same), all(hm$deger_r != "KOSU_BASLADI")))

# 5 Hash kontrolü
hs <- sapply(1:3, function(i) { k <- paste0("hash|", i)
  c(tf(get(k, "engellendi")), tf(get(k, "dosya_adi_gosterildi")), tf(get(k, "webr_yuklenmedi")), tf(get(k, "calistir_kapali"))) })
hfile <- sapply(1:3, function(i) paste0(get(paste0("hash|", i), "dosya"), ":", get(paste0("hash|", i), "konum")))
put("Hash kontrolü (3 deneme)", if (all(is.na(sapply(1:3, function(i) get(paste0("hash|", i), "engellendi"))))) "EKSIK" else if (all(hs)) "GECTI" else "KALDI",
    sprintf("%s; her denemede engellendi, dosya adı gösterildi, webR yüklenmedi, Çalıştır kapalı: %s",
            paste(hfile, collapse = ", "), paste(apply(hs, 2, all), collapse = "/")))

# 6 İptal
dms <- as.numeric(get("iptal", "durma_ms"))
put("İptal (≤ 2 sn)", if (is.na(dms)) "EKSIK" else if (tf(get("iptal", "iptalde_kosu_suruyordu")) && dms <= 2000 &&
      tf(get("iptal", "kismi_sonuc_gosterilmedi")) && tf(get("iptal", "iptal_iletisi"))) "GECTI" else "KALDI",
    sprintf("iptal anında koşu sürüyordu: %s; durma %s ms; arayüz zamanlayıcı gecikmesi %s ms; iptal iletisi: %s; kısmi sonuç gösterilmedi: %s; yeniden hazır %s ms",
            get("iptal", "iptalde_kosu_suruyordu"), get("iptal", "durma_ms"), get("iptal", "arayuz_gecikme_ms"),
            get("iptal", "iptal_iletisi"), get("iptal", "kismi_sonuc_gosterilmedi"), get("iptal", "yeniden_hazir_ms")))

# 7 Başlatma (cold start) - worst of 5 (Table 11.2)
rep5 <- function(an) as.numeric(sapply(1:5, function(i) get(an, paste0("tekrar", i))))
cs <- rep5("soguk_acilis"); ws <- rep5("sicak_acilis")
cold_ok <- tf(get("soguk_acilis", "onbellek_kapali_beyan"))
put("Başlatma: soğuk açılış ≤ 15 sn (en kötü / 5)",
    if (any(is.na(cs))) "EKSIK" else if (!cold_ok) "KOSUL_SAGLANMADI" else if (max(cs) <= 15000) "GECTI" else "KALDI",
    sprintf("soğuk: medyan %s ms, en kötü %s ms, önbellek kapalı beyanı %s; sıcak (yalnız rapor): medyan %s ms, en kötü %s ms",
            stats::median(cs), max(cs), get("soguk_acilis", "onbellek_kapali_beyan"), stats::median(ws), max(ws)))

# 8 Performans ve bellek - worst of 5
k6 <- if (!is.na(get("perf|6x30|15000", "tekrar1"))) "perf|6x30|15000" else "perf|6x30|20000"   # v0.6: 15,000
ns6 <- sub(".*\\|", "", k6); ns6_lab <- format(as.numeric(ns6), big.mark = ".")
p1 <- rep5("perf|3x10|10000"); p2 <- rep5(k6)
mem <- suppressWarnings(as.numeric(get("bellek", "tepe_mb")))
pdet <- function(k) { v <- sapply(1:5, function(i) get(k, paste0("fda_pass_tekrar", i))); length(unique(v[!is.na(v)])) == 1 }
ASILDI <- "ASILDI_SINIR_DUSER"   # Table 11.1: exceeded -> test does not fail; temporary limit lowered
put("Performans: 3 × 10, nsim 10.000 ≤ 10 sn", if (any(is.na(p1))) "EKSIK" else if (max(p1) <= 10000) "GECTI" else ASILDI,
    sprintf("medyan %s ms, en kötü %s ms; 5 tekrarda aynı sonuç: %s", stats::median(p1), max(p1), pdet("perf|3x10|10000")))
put(paste0("Performans: 6 × 30, nsim ", ns6_lab, " ≤ 60 sn"), if (any(is.na(p2))) "EKSIK" else if (max(p2) <= 60000) "GECTI" else ASILDI,
    sprintf("medyan %s ms, en kötü %s ms; 5 tekrarda aynı sonuç: %s", stats::median(p2), max(p2), pdet(k6)))
put("Tepe bellek ≤ 1 GB", if (is.na(mem)) "EKSIK" else if (mem <= 1024) "GECTI" else ASILDI,
    sprintf("%s MB (Chrome görev yöneticisi, elle girildi)%s", get("bellek", "tepe_mb"),
            if (!is.na(mem) && mem > 1024) "; eşik aşıldı: Tablo 11.1'e göre test kalmaz, geçici nsim üst sınırı düşürülür" else ""))

# 9 Mobil
mn <- get("mobil", "gozlem")
put("Mobil", "GOZLEM", if (is.na(mn) || mn == "") "gözlem girilmedi" else mn)

# --- output ------------------------------------------------------------------
env <- br[br$bolum == "ortam", c("anahtar", "ad", "deger")]
utils::write.csv(res, file.path(out_dir, "p1_karsilastirma.csv"), row.names = FALSE, fileEncoding = "UTF-8")
if (length(detail)) utils::write.csv(do.call(rbind, lapply(names(detail), function(n) cbind(kume = n, detail[[n]][, c("bolum", "anahtar", "ad", "deger_r", "deger_t")]))),
                                     file.path(out_dir, "p1_fark_ayrinti.csv"), row.names = FALSE, fileEncoding = "UTF-8")
writeLines(c(utils::capture.output(utils::sessionInfo()), "",
             paste("Engine SHA-256:", paste(files, vapply(file.path(Rdir, files), shaf, ""), collapse = "; ")),
             paste("kabul.R SHA-256:", shaf(file.path("web", "p1", "kabul", "kabul.R")))),
           file.path(out_dir, "p1_yerel_sessionInfo.txt"))
cat("\nP1 kabul testleri (FSR-TN-PLT-01 v0.4, Tablo 11.1)\n")
cat(sprintf("Tarayıcı: %s\n", paste(env$deger[env$ad %in% c("islemci", "isletim_sistemi")], collapse = " · ")))
for (i in seq_len(nrow(res))) cat(sprintf("  %-46s %-16s %s\n", res$olcut[i], res$sonuc[i], res$ayrinti[i]))
genel <- if (any(res$sonuc %in% c("KALDI"))) "KALDI" else if (any(res$sonuc %in% c("EKSIK", "KOSUL_SAGLANMADI"))) "EKSIK" else "GECTI"
cat("\nGenel:", genel, "(P1'in başarısına proje sahibi karar verir; KK-45)\n")
if (any(res$sonuc == ASILDI))
  cat("Eşik aşımı:", paste(res$olcut[res$sonuc == ASILDI], collapse = "; "),
      "\n  -> Tablo 11.1: test kalmaz; geçici nsim üst sınırı düşürülür (yeni sınır ölçümle belirlenir).\n")
