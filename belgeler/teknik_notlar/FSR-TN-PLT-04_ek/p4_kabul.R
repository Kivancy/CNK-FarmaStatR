# =============================================================================
# CNK-FarmaStatR - P4 acceptance (FSR-TN-PLT-04 v0.1, Table 9.1; frozen by KK-54)
#
# Reads the browser output of web/app/kabul.html (p4/p4_tarayici.csv, p4/p4_betik.R),
# recomputes in local R what the screen should show and writes one line per
# criterion: GECTI (pass), KALDI (fail) or EKSIK (data missing).
#   U-1 class, metric, KK-38 label and near-boundary warning = R (live: a local
#       run with the same inputs; precomputed: the database), texts = translation
#   U-2 every displayed number = the rule P4-K3 applied to the R value; the
#       browser formatter = the Linux reference (p4_bicim_referans.csv) on all
#       11,385 rates of the database
#   U-3 1,085 keys; precomputed values = database, webR not started; run shown
#       by P4-K1; changed database closes the tier
#   U-4 tier selection; U-5 links and version; U-6 TR/EN; U-7 charts;
#   U-8 warnings; U-9 information before the run and cancel; U-11 the script
#   downloaded from the screen = the script written here (P3 E-9 rule) and the
#   pinned cores unchanged; U-12 narrow screen. U-10 (database) is checked by
#   p4_kabul_vt.R; its browser part (sql.js values) is part of U-3 here.
# Live values: decisions are compared as counts (equal), other numbers with
#   K(1e-12, 1e-12) (P1 rule; browser R and local R may differ in version).
# Run from the repository root:
#   source("belgeler/teknik_notlar/FSR-TN-PLT-04_ek/p4_kabul.R", encoding = "UTF-8")
# Base R plus RSQLite (database read). Research and education only; not a system
# validated for GxP environments.
# =============================================================================
local({
E <- file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-04_ek")
br <- utils::read.csv(file.path(E, "p4", "p4_tarayici.csv"), colClasses = "character", encoding = "UTF-8", na.strings = character(0))
Rdir <- file.path("CNKfarmastatr", "R")
pk <- new.env(parent = globalenv())
for (f in c("sim_run.R", "invitro_fast.R", "invitro_grid.R", "platform_input.R", "platform_hipotez.R", "platform_export.R"))
  sys.source(file.path(Rdir, f), envir = pk, keep.source = FALSE)
suppressPackageStartupMessages({ library(DBI); library(RSQLite) })
con <- dbConnect(SQLite(), file.path("veri", "farmastatr_v1.sqlite")); on.exit(dbDisconnect(con))
res <- data.frame(olcut = character(0), sonuc = character(0), ayrinti = character(0), stringsAsFactors = FALSE)
put <- function(o, ok, a) { s <- if (is.na(ok)) "EKSIK" else if (isTRUE(ok)) "GECTI" else "KALDI"
  res[nrow(res) + 1, ] <<- c(o, s, a); cat(sprintf("%-40s %-6s %s\n", o, s, a)) }
g <- function(b, s = NULL, y = NULL, a = NULL) { x <- br[br$bolum == b, ]
  if (!is.null(s)) x <- x[x$senaryo == s, ]; if (!is.null(y)) x <- x[x$yontem == y, ]; if (!is.null(a)) x <- x[x$ad == a, ]; x }
v1 <- function(b, s, y, a) { x <- g(b, s, y, a)$deger; if (length(x) == 1) x else NA_character_ }
tf <- function(x) length(x) > 0 && all(x == "true")
eq <- function(a, b) length(a) == 1 && length(b) == 1 && isTRUE(as.character(unname(a)) == as.character(unname(b)))
K <- function(a, b) abs(a - b) <= 1e-12 + 1e-12 * pmax(abs(a), abs(b))
num <- function(x) suppressWarnings(as.numeric(x))
ME <- c("fda", "ema_a", "ema_b", "ema_c")
if (nrow(br) == 0) stop("p4_tarayici.csv is empty")

# ---------------------------------------------------------------- live scenarios: local R
live_ids <- unique(g("U-canli")$senaryo)
base <- list(pL = 0.15, q = 0, l = 3, n = 10, m = 3, n_sim = 2000, seed = 20261015)
parse_id <- function(id) {
  if (id == "C-yakin") return(list(sigma_R = 0.12, rho = 1, sinir = NULL, delta = 0.1734448575079488))
  p <- strsplit(sub("^C-", "", id), "-")[[1]]
  list(sigma_R = as.numeric(p[1]), rho = as.numeric(p[2]), sinir = paste(p[-(1:2)], collapse = "-"), delta = NULL)
}
u1 <- u2 <- u8 <- logical(0); det <- character(0)
for (id in live_ids) {
  s <- parse_id(id)
  p <- c(list(sigma_R = s$sigma_R, rho = s$rho, pB_T = 0, pB_R = 0), base)
  d <- if (is.null(s$sinir)) s$delta else pk$platform_sinir_delta(s$sinir, s$sigma_R, s$rho)
  r <- pk$platform_run_invitro(c(p, list(delta = d)))
  h <- if (is.null(s$sinir)) pk$platform_hipotez(s$sigma_R, s$rho, delta = d) else pk$platform_hipotez(s$sigma_R, s$rho, sinir = s$sinir)
  rate <- unlist(r[paste0(ME, "_pass")]); se <- unlist(r[paste0(ME, "_pass_mcse")])
  lab <- pk$platform_kk38(unname(rate), unname(se), h$sinif)
  for (i in seq_along(ME)) {
    y <- ME[i]
    ok1 <- eq(v1("U-canli", id, y, "sinif"), h$sinif[i]) && eq(v1("U-canli", id, y, "metrik"), h$metrik[i]) &&
      eq(v1("U-canli", id, y, "yakinlik"), tolower(as.character(h$yakinlik_uyarisi[i]))) &&
      eq(v1("U-canli", id, y, "kk38"), ifelse(is.na(lab[i]), "NA", lab[i]))
    rb <- num(v1("U-canli", id, y, "rate")); sb <- num(v1("U-canli", id, y, "mcse"))
    ok2 <- round(rb * 2000) == round(rate[i] * 2000) && K(sb, se[i])
    u1 <- c(u1, ok1); u2 <- c(u2, ok2)
    if (!ok1 || !ok2) det <- c(det, paste(id, y))
  }
  w <- strsplit(v1("U-canli", id, "", "warn"), ";")[[1]]
  u8 <- c(u8, ("warn_power" %in% w) == any(h$sinif == "H1"), ("warn_near" %in% w) == any(h$yakinlik_uyarisi))
}
txt_ok <- tf(c(g("U-canli", a = "txt_ok")$deger, g("U-canli-en", a = "txt_ok")$deger, g("U-hazir", a = "txt_ok")$deger))

# ---------------------------------------------------------------- precomputed scenarios: database
hz_ids <- unique(g("U-hazir")$senaryo); u1h <- u3h <- u7h <- logical(0)
for (k in hz_ids) {
  no <- dbGetQuery(con, "SELECT senaryo_no FROM senaryo WHERE senaryo_anahtar = ?", params = list(k))$senaryo_no
  hp <- dbGetQuery(con, "SELECT * FROM hipotez WHERE senaryo_no = ?", params = list(no))
  ks <- dbGetQuery(con, "SELECT DISTINCT k.kosu_id, k.tur FROM sonuc s JOIN kosu k USING (kosu_id) WHERE s.senaryo_no = ?", params = list(no))
  shown <- if (any(ks$tur == "birlesik")) ks$kosu_id[ks$tur == "birlesik"] else ks$kosu_id[ks$tur == "tek"]
  so <- dbGetQuery(con, "SELECT * FROM sonuc WHERE senaryo_no = ? AND kosu_id = ? AND olcut_id = 'pass'", params = list(no, shown))
  for (y in ME) {
    hh <- hp[hp$yontem_id == y, ]; ss <- so[so$yontem_id == y, ]
    o1 <- eq(v1("U-hazir", k, y, "sinif"), hh$sinif) && eq(v1("U-hazir", k, y, "metrik"), hh$metrik) &&
                  eq(v1("U-hazir", k, y, "yakinlik"), tolower(as.character(hh$yakinlik_uyarisi == 1))) &&
                  eq(v1("U-hazir", k, y, "kk38"), ifelse(is.na(ss$kk38), "NA", ss$kk38))
    if (!o1) det <- c(det, paste(substr(k, 1, 40), y))
    u1h <- c(u1h, o1)
    u3h <- c(u3h, identical(num(v1("U-hazir", k, y, "rate")), ss$tahmin) && identical(num(v1("U-hazir", k, y, "mcse")), ss$mcse))
  }
  u3h <- c(u3h, identical(v1("U-hazir", k, "", "kosu_shown"), shown), identical(v1("U-hazir", k, "", "webr_started"), "false"))
  # G2 values = database (run shown by P4-K1 for each neighbour)
  g2 <- g("U-hazir", k); g2 <- g2[grepl("^g2_[0-9]+$", g2$ad), ]
  for (j in seq_len(nrow(g2))) {
    nb <- as.integer(sub("g2_", "", g2$ad[j]))
    kn <- dbGetQuery(con, "SELECT DISTINCT k.kosu_id, k.tur FROM sonuc s JOIN kosu k USING (kosu_id) WHERE s.senaryo_no = ?", params = list(nb))
    sh <- if (any(kn$tur == "birlesik")) kn$kosu_id[kn$tur == "birlesik"] else kn$kosu_id[kn$tur == "tek"]
    val <- dbGetQuery(con, "SELECT tahmin FROM sonuc WHERE senaryo_no = ? AND kosu_id = ? AND yontem_id = ? AND olcut_id = 'pass'",
                      params = list(nb, sh, g2$yontem[j]))$tahmin
    u7h <- c(u7h, identical(num(g2$deger[j]), val))
  }
  w <- strsplit(v1("U-hazir", k, "", "warn"), ";")[[1]]
  u8 <- c(u8, ("warn_power" %in% w) == any(hp$sinif == "H1"))
}

# ---------------------------------------------------------------- criteria
put("U-1 Sınıf, metrik ve etiket", length(u1) > 0 && all(u1) && all(u1h) && txt_ok,
    sprintf("canlı %d/%d yöntem satırı = yerel R; hazır %d/%d = veri tabanı; metinler çeviriyle aynı (TR, EN): %s%s",
            sum(u1), length(u1), sum(u1h), length(u1h), txt_ok, if (length(det)) paste0("; fark: ", paste(det, collapse = ", ")) else ""))
ref <- utils::read.csv(file.path(E, "p4_bicim_referans.csv"), colClasses = "character", encoding = "UTF-8", na.strings = character(0))
bc <- g("bicim"); m <- match(ref$anahtar, bc$senaryo)
fark <- sum(is.na(m)) + sum(bc$ad[m] != ref$oran, na.rm = TRUE) + sum(bc$deger[m] != ref$mcse, na.rm = TRUE)
put("U-2 Sayılar", txt_ok && all(u2) && fark == 0 && nrow(ref) == nrow(bc),
    sprintf("biçim fonksiyonu = Linux başvurusu: %d oran ve MCSE, fark %d; ekrandaki metin = kural(değer); canlı değerler yerel R ile sayım düzeyinde ve K içinde: %d/%d",
            nrow(ref), fark, sum(u2), length(u2)))
put("U-3 Hazır katman", identical(v1("U-3", "", "", "anahtar_fark"), "0") && identical(v1("U-3", "", "", "anahtar_n"), "1085") &&
      all(u3h) && tf(g("U-3", "vtbozuk")$deger) && identical(v1("U-3", "", "", "vt_ok"), "true"),
    sprintf("anahtar 1.085, fark %s; %d hazır senaryoda değerler = veri tabanı, gösterilen koşu P4-K1, webR başlamadı: %d/%d; bozuk veri tabanında katman kapandı: %s",
            v1("U-3", "", "", "anahtar_fark"), length(hz_ids), sum(u3h), length(u3h), tf(g("U-3", "vtbozuk")$deger)))
k4 <- c(sinir_ustu = v1("U-4", "sinir_ustu", "", "katman"), izgara_disi = v1("U-4", "izgara_disi", "", "katman"), izgara = v1("U-4", "izgara", "", "katman"))
put("U-4 Katman seçimi", identical(unname(k4), c("betik", "canli", "hazir")) && identical(v1("U-4", "sinir_ustu", "", "betik_onerisi"), "true") &&
      grepl("not_positive", v1("U-4", "gecersiz", "", "kodlar")),
    sprintf("sınır üstü %s (betik önerisi %s), ızgara dışı %s, ızgara %s, geçersiz: %s", k4[1], v1("U-4", "sinir_ustu", "", "betik_onerisi"), k4[2], k4[3], v1("U-4", "gecersiz", "", "kodlar")))
l5 <- g("U-5"); l5k <- l5[l5$ad %in% c("link_key_ok", "link_ayni_sonuc"), ]
put("U-5 Bağlantı", tf(l5k$deger) && length(unique(l5k$senaryo)) == length(live_ids) && identical(v1("U-5", "surum", "", "kutu"), "true") &&
      identical(v1("U-5", "surum", "", "sessiz_yok"), "true"),
    sprintf("%d senaryoda bağlantı → aynı anahtar ve aynı sonuç: %s; farklı sürüm: açıklama %s, onaydan önce sonuç yok %s",
            length(unique(l5k$senaryo)), tf(l5k$deger), v1("U-5", "surum", "", "kutu"), v1("U-5", "surum", "", "sessiz_yok")))
i18 <- c(g("U-canli", a = "i18n_raw")$deger, g("U-canli-en", a = "i18n_raw")$deger, g("U-hazir", a = "i18n_raw")$deger)
put("U-6 TR/EN", identical(v1("U-6", "", "", "ceviri_anahtar_esit"), "true") && all(i18 == "0") &&
      tf(c(g("U-canli", a = "disclaimer_ok")$deger, g("U-canli-en", a = "disclaimer_ok")$deger, g("U-hazir", a = "disclaimer_ok")$deger)),
    sprintf("çeviri anahtarları TR = EN (%s); çevirisiz metin: %d ekranda 0; beyan görünür", v1("U-6", "", "", "ceviri_n"), sum(i18 == "0")))
g1 <- c(g("U-canli", a = "g1_ok")$deger, g("U-hazir", a = "g1_ok")$deger, g("U-canli", a = "g1_nominal_ok")$deger, g("U-hazir", a = "g1_nominal_ok")$deger)
put("U-7 Grafikler", tf(g1) && tf(g("U-hazir", a = "g2_ok")$deger) && tf(g("U-hazir", a = "g2_sel")$deger) && all(u7h),
    sprintf("G1 işaretleri = tablo ve nominal çizgi kuralı: %s; G2 işaretleri = ekran verisi: %s, = veri tabanı: %d/%d", tf(g1), tf(g("U-hazir", a = "g2_ok")$deger), sum(u7h), length(u7h)))
d8 <- g("U-8"); d8 <- d8[d8$ad %in% c("hata_metni", "sonuc_yok"), ]
put("U-8 Uyarılar", all(u8) && tf(d8$deger) && length(unique(d8$senaryo)) >= 2,
    sprintf("güç ve yakınlık uyarıları sınıflarla tutarlı: %d/%d; δ₀ tanımsız (%d senaryo): koşu yok ve uyarı: %s", sum(u8), length(u8), length(unique(d8$senaryo)), tf(d8$deger)))
ms <- num(v1("U-9", "iptal", "", "durma_ms"))
put("U-9 Önceden bilgi ve iptal", tf(c(g("U-canli", a = "mc_info_ok")$deger, g("U-hazir", a = "mc_info_ok")$deger)) && !is.na(ms) && ms <= 2000 &&
      identical(v1("U-9", "iptal", "", "kosu_suruyordu"), "true") && identical(v1("U-9", "iptal", "", "kismi_sonuc_yok"), "true"),
    sprintf("beklenen MCSE, nsim üst sınırı ve tahmini süre görünür; iptal %s ms (koşu sürüyordu: %s; kısmi sonuç yok: %s)",
            ms, v1("U-9", "iptal", "", "kosu_suruyordu"), v1("U-9", "iptal", "", "kismi_sonuc_yok")))
# U-11: the script from the screen = the script written here; pinned cores
sc <- file.path(E, "p4", "p4_betik.R")
ok11 <- NA; a11 <- "p4_betik.R yok"
if (file.exists(sc)) {
  b <- readLines(sc, warn = FALSE, encoding = "UTF-8")
  env <- new.env(); tx <- sub("\nrun <- .fsr_main(params, sinir, delta, output_dir, .fsr_files, .fsr_export)\n", "\n", paste0(paste(b, collapse = "\n"), "\n"), fixed = TRUE)
  eval(parse(text = tx, keep.source = FALSE), envir = env)
  p <- env$params; if (is.null(env$sinir)) p$delta <- env$delta
  loc <- strsplit(pk$platform_export_invitro(p, sinir = env$sinir, dosyalar = pk$platform_motor_dosyalari(Rdir),
                    cekirdek_sha = pk$platform_cekirdek_sha(file.path("CNKfarmastatr", "inst", "validasyon", "CEKIRDEK_SHA256.txt")),
                    kaynak = env$.fsr_export$source_run, paket_surumu = env$.fsr_export$package_version), "\n")[[1]]
  same <- length(loc) == length(b) && identical(which(loc != b), grep("^\\.fsr_created <- ", b))
  ck <- new.env(); sys.source(file.path("araclar", "cekirdek_kontrol.R"), envir = ck)
  ok11 <- same && all(ck$liste$durum == "AYNI")
  a11 <- sprintf("ekrandan indirilen betik = yerel betik (zaman satırı dışında): %s; çekirdek SHA-256 %d/%d AYNI; test kümesi ve CI ayrıca (GitHub Actions)",
                 same, sum(ck$liste$durum == "AYNI"), nrow(ck$liste))
}
put("U-11 Gerileme", ok11, a11)
sw <- num(v1("U-12", "dar", "", "scroll_genislik")); pw <- num(v1("U-12", "dar", "", "pencere"))
put("U-12 Dar ekran", !is.na(sw) && sw <= pw && identical(v1("U-12", "dar", "", "dugmeler_gorunur"), "true"),
    sprintf("çerçeve 375 px: sayfa genişliği %s, pencere %s; düğmeler görünür: %s", sw, pw, v1("U-12", "dar", "", "dugmeler_gorunur")))
vt <- file.path(E, "p4_kabul_vt.csv")
if (file.exists(vt)) { x <- utils::read.csv(vt, encoding = "UTF-8")
  put("U-10 Veri tabanı (p4_kabul_vt.R)", all(x$sonuc == "GECTI"), sprintf("%d/%d kontrol GECTI; tarayıcıdaki sql.js okuması U-3'te", sum(x$sonuc == "GECTI"), nrow(x))) }

utils::write.csv(res, file.path(E, "p4_kabul.csv"), row.names = FALSE, fileEncoding = "UTF-8")
writeLines(c(utils::capture.output(utils::sessionInfo()), "", paste("tarayıcı:", v1("ortam", "", "", "user_agent"))),
           file.path(E, "p4_yerel_sessionInfo.txt"))
genel <- if (any(res$sonuc == "KALDI")) "KALDI" else if (any(res$sonuc == "EKSIK")) "EKSIK" else "GECTI"
cat("\nGenel:", genel, "| yazıldı:", file.path(E, "p4_kabul.csv"), "\n")
})
