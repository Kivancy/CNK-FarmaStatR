# =============================================================================
# FSR-TN-PLT-02 - P2 acceptance checks on the SQLite database (Table 8.1)
#   Part 2 (T-3, T-4): S-6 (database = source CSVs), S-7 (deterministic build),
#   S-8 (read with sql.js), S-9 (run-version link).
# Needs: RSQLite, the installed CNKfarmastatr package; for S-8 the output of
#   vt_oku.mjs (Node + sql.js 1.12.0), passed as the third argument.
# Run from the repository root:
#   Rscript belgeler/teknik_notlar/FSR-TN-PLT-02_ek/p2_kabul_vt.R [db] [sqljs_dir]
# Output: p2_kabul_vt.csv and vt_dokum_sha256.txt in this folder.
# Research and education only; not a system validated for GxP environments.
# =============================================================================
suppressPackageStartupMessages({ library(DBI); library(RSQLite); library(CNKfarmastatr) })
args <- commandArgs(trailingOnly = TRUE)
vt <- if (length(args) >= 1) args[1] else file.path("veri", "farmastatr_v1.sqlite")
sq_dir <- if (length(args) >= 2) args[2] else NA
out_dir <- file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-02_ek")
S <- file.path("simulasyon", "FSR-TN-PBE-01")
source(file.path("araclar", "sha256.R"), encoding = "UTF-8")
rd <- function(f) utils::read.csv(file.path(S, f), colClasses = "character", stringsAsFactors = FALSE)
res <- data.frame(kontrol = character(0), sonuc = character(0), ayrinti = character(0), stringsAsFactors = FALSE)
put <- function(k, ok, d) res[nrow(res) + 1, ] <<- c(k, if (isTRUE(ok)) "GECTI" else "KALDI", d)
Kok <- function(xh, x, a = 1e-12, r = 1e-12) all(abs(xh - x) <= a + r * pmax(abs(x), abs(xh)))

# deterministic content dump: every table in fixed order, rows by primary key,
# REAL as %.17g; the build time is excluded
vt_dokum <- function(path) {
  con <- dbConnect(SQLite(), path); on.exit(dbDisconnect(con))
  tabs <- c("insa", "dosya", "modul", "senaryo", "kosu", "kosu_kaynak", "yontem", "olcut", "sonuc", "fark",
            "hipotez", "yayin", "veri_seti", "test_vakasi")
  txt <- character(0)
  for (t in tabs) {
    sch <- dbGetQuery(con, sprintf("SELECT sql FROM sqlite_master WHERE name = '%s'", t))$sql
    pk <- dbGetQuery(con, sprintf("PRAGMA table_info(%s)", t)); pk <- pk$name[pk$pk > 0][order(pk$pk[pk$pk > 0])]
    x <- dbGetQuery(con, sprintf("SELECT * FROM %s ORDER BY %s", t, paste(pk, collapse = ", ")))
    if (t == "insa") x <- x[x$anahtar != "insa_zamani", ]
    if (t == "dosya") x <- x[x$rol != "insa_betigi_kopya", ]
    f <- function(v) if (is.numeric(v)) ifelse(is.na(v), "NULL", sprintf("%.17g", v)) else ifelse(is.na(v), "NULL", v)
    rows <- if (nrow(x)) do.call(paste, c(lapply(x, f), sep = "\t")) else character(0)
    txt <- c(txt, paste("TABLE", t), sch, rows)
  }
  txt
}

con <- dbConnect(SQLite(), vt)
q <- function(s) dbGetQuery(con, s)

# ---- S-6: database = source ------------------------------------------------
a1 <- rd("asama1_sonuc.csv"); a2 <- rd("asama2_sonuc.csv"); e1 <- rd("asama1_ektekrar.csv"); e2 <- rd("asama2_ektekrar.csv")
sen <- q("SELECT * FROM senaryo")
src <- rbind(cbind(a1[, c("scenario", "sigma_R", "rho", "pB_T", "pB_R", "pL", "q", "l", "n", "m", "delta_id", "delta", "gmr", "eta")], asama = 1L),
             cbind(a2[, c("scenario", "sigma_R", "rho", "pB_T", "pB_R", "pL", "q", "l", "n", "m", "delta_id", "delta", "gmr", "eta")], asama = 2L))
mm <- merge(src, sen, by.x = "scenario", by.y = "izgara_kodu", suffixes = c("_csv", "_vt"))
pc <- c("sigma_R", "rho", "pB_T", "pB_R", "pL", "q", "l", "n", "m", "delta", "gmr", "eta")
eq_par <- vapply(pc, function(p) identical(as.numeric(mm[[paste0(p, "_csv")]]), as.numeric(mm[[paste0(p, "_vt")]])), TRUE)
key_ok <- identical(mm$senaryo_anahtar, with(mm, platform_anahtar(as.numeric(sigma_R_csv), as.numeric(rho_csv), as.numeric(pB_T_csv),
  as.numeric(pB_R_csv), as.numeric(pL_csv), as.numeric(q_csv), as.numeric(l_csv), as.numeric(n_csv), as.numeric(m_csv), sinir = delta_id)))
put("S-6a senaryo = CSV (1.085 satır; parametreler birebir; anahtar)",
    nrow(sen) == nrow(src) && nrow(mm) == nrow(src) && all(eq_par) && key_ok && all(mm$delta_id == mm$delta_ad),
    sprintf("%d / %d satır; %d parametre sütunu birebir: %s; anahtar yeniden üretildi: %s", nrow(mm), nrow(src), length(pc), all(eq_par), key_ok))

# independent long form of the main grids: every *_x column that has a *_x_mcse partner
son <- q("SELECT s.izgara_kodu, r.* FROM sonuc r JOIN senaryo s USING (senaryo_no)")
ref_main <- do.call(rbind, lapply(list(list(a1, "PBE01-A1"), list(a2, "PBE01-A2")), function(z) {
  x <- z[[1]]; cols <- grep("^(fda|ema_[abc])_.*_mcse$", names(x), value = TRUE); cols <- sub("_mcse$", "", cols)
  cols <- cols[!grepl("^diff_", cols)]
  do.call(rbind, lapply(cols, function(cn) data.frame(izgara_kodu = x$scenario, kosu_id = z[[2]],
    yontem_id = sub("^(fda|ema_[abc])_.*$", "\\1", cn), olcut_id = sub("^(fda|ema_[abc])_(c_)?", "", sub("^ema_c_pooled", "pooled", cn)),
    t_csv = x[[cn]], m_csv = x[[paste0(cn, "_mcse")]], n_csv = x$n_sim, stringsAsFactors = FALSE)))
}))
ref_main$olcut_id[ref_main$olcut_id == "pooled_T" | grepl("pooled_T$", ref_main$olcut_id)] <- "pooled_T"
ref_main$olcut_id[grepl("pooled_R$", ref_main$olcut_id)] <- "pooled_R"
ref_main$yontem_id[grepl("^ema_c_pooled", paste0(ref_main$yontem_id, "_", ref_main$olcut_id))] <- "ema_c"
ref_ek <- rbind(
  data.frame(izgara_kodu = e1$scenario, kosu_id = "PBE01-A1-EK", yontem_id = e1$method, olcut_id = "pass", t_csv = e1$power_40k, m_csv = e1$mcse_40k, n_csv = "40000"),
  data.frame(izgara_kodu = e1$scenario, kosu_id = "PBE01-A1-BIR", yontem_id = e1$method, olcut_id = "pass", t_csv = e1$power_50k, m_csv = e1$mcse_50k, n_csv = "50000"),
  data.frame(izgara_kodu = e2$scenario, kosu_id = "PBE01-A2-EK", yontem_id = e2$method, olcut_id = "pass", t_csv = e2$power_40k, m_csv = e2$mcse_40k, n_csv = "40000"),
  data.frame(izgara_kodu = e2$scenario, kosu_id = "PBE01-A2-BIR", yontem_id = e2$method, olcut_id = "pass", t_csv = e2$power_50k, m_csv = e2$mcse_50k, n_csv = "50000"))
ec <- e1[e1$method == "ema_c", ]
ref_pool <- rbind(data.frame(izgara_kodu = ec$scenario, kosu_id = "PBE01-A1-EK", yontem_id = "ema_c", olcut_id = "pooled_T", t_csv = ec$ema_c_pooled_T_40k, m_csv = NA, n_csv = "40000"),
                  data.frame(izgara_kodu = ec$scenario, kosu_id = "PBE01-A1-EK", yontem_id = "ema_c", olcut_id = "pooled_R", t_csv = ec$ema_c_pooled_R_40k, m_csv = NA, n_csv = "40000"))
ref <- rbind(ref_main, ref_ek, ref_pool)
j <- merge(ref, son, by = c("izgara_kodu", "kosu_id", "yontem_id", "olcut_id"), all = TRUE)
t_eq <- identical(as.numeric(j$t_csv), j$tahmin)
csv_m <- !is.na(j$m_csv)
m_eq <- identical(as.numeric(j$m_csv[csv_m]), j$mcse[csv_m])
n_eq <- identical(as.integer(j$n_csv), j$n_tekrar)
put("S-6b sonuc = CSV (her tahmin, MCSE ve tekrar sayısı birebir)",
    nrow(j) == nrow(son) && nrow(j) == nrow(ref) && t_eq && m_eq && n_eq && all(j$mcse_kaynak[csv_m] == "csv"),
    sprintf("%d satır (kaynak %d, veri tabanı %d); tahmin birebir: %s; CSV MCSE birebir: %s; tekrar sayısı: %s; türetilmiş MCSE %d satır",
            nrow(j), nrow(ref), nrow(son), t_eq, m_eq, n_eq, sum(!csv_m)))
# recomputed binomial MCSE for rates, and derived MCSE
rate <- son$olcut_id %in% c("pass", "cover", "crit_err", "pooled_T", "pooled_R")
mc <- rep(NA_real_, nrow(son)); mc[rate] <- sqrt(son$tahmin[rate] * (1 - son$tahmin[rate]) / son$n_tekrar[rate])
put("S-6c Oranların MCSE'si √(p(1−p)/n) ile K(1e-12, 1e-12)", Kok(son$mcse[rate], mc[rate]),
    sprintf("%d oran satırı; en büyük göreli fark %.2e", sum(rate), max(abs(son$mcse[rate] - mc[rate]) / pmax(mc[rate], 1e-300))))
# extra runs: their 10k column must equal the main run
base <- son[son$olcut_id == "pass" & son$kosu_id %in% c("PBE01-A1", "PBE01-A2"), c("izgara_kodu", "yontem_id", "tahmin")]
chk10 <- rbind(data.frame(izgara_kodu = e1$scenario, yontem_id = e1$method, p10 = as.numeric(e1$power_10k)),
               data.frame(izgara_kodu = e2$scenario, yontem_id = e2$method, p10 = as.numeric(e2$power_10k)))
cm <- merge(chk10, base)
put("S-6d Ek tekrar dosyalarındaki 10.000 değeri = ana koşu", nrow(cm) == nrow(chk10) && identical(cm$p10, cm$tahmin),
    sprintf("%d hücre", nrow(cm)))
# combined = (10k p + 40k p) by pooled counts
bir <- merge(merge(son[son$kosu_id %in% c("PBE01-A1-BIR", "PBE01-A2-BIR") & son$olcut_id == "pass", c("izgara_kodu", "yontem_id", "tahmin")],
                   setNames(son[son$kosu_id %in% c("PBE01-A1-EK", "PBE01-A2-EK") & son$olcut_id == "pass", c("izgara_kodu", "yontem_id", "tahmin")], c("izgara_kodu", "yontem_id", "p40"))),
             setNames(base, c("izgara_kodu", "yontem_id", "p10")))
put("S-6e Birleşik oran = (10.000 p + 40.000 p) / 50.000", Kok(bir$tahmin, (1e4 * bir$p10 + 4e4 * bir$p40) / 5e4),
    sprintf("%d hücre", nrow(bir)))
# differences and paired MCSE rule (P2-K2)
fk <- q("SELECT * FROM fark")
na_ok <- all(is.na(fk$mcse[grepl("BIR$", fk$kosu_id)])) && all(!is.na(fk$mcse_not[grepl("BIR$", fk$kosu_id)])) &&
  all(!is.na(fk$mcse[!grepl("BIR$", fk$kosu_id)]))
dd <- unlist(lapply(c("fda_ema_a", "fda_ema_b", "fda_ema_c", "ema_a_ema_c", "ema_b_ema_c"), function(p) as.numeric(a2[[paste0("diff_", p)]])))
put("S-6f fark: Aşama 2 eşleşik farkları = CSV; birleşik eşleşik MCSE saklanmadı (P2-K2)",
    na_ok && identical(sort(dd), sort(fk$tahmin[fk$kosu_id == "PBE01-A2"])),
    sprintf("%d fark satırı; birleşik koşuda MCSE yok, gerekçe yazılı: %s", nrow(fk), na_ok))
# hypothesis classes and KK-38 labels: independent re-implementation of the rules
hp <- q("SELECT h.*, s.sigma_R, s.rho, s.delta_ad FROM hipotez h JOIN senaryo s USING (senaryo_no)")
tp <- ((log(1.11))^2 + 0.01) / 0.01
d <- ifelse(hp$delta_ad == "fda_delta0", 1, ifelse(hp$delta_ad == "fda_minus_delta0", -1, NA))
sT2 <- (hp$rho * hp$sigma_R)^2
d0 <- sqrt(pmax(0, ifelse(hp$sigma_R > 0.1, (1 + tp) * hp$sigma_R^2 - sT2, hp$sigma_R^2 + tp * 0.01 - sT2)))
del <- ifelse(!is.na(d), d * d0, c(ema_1.18 = log(1.18), ema_0.85 = log(0.85), gmr_1.00 = 0, gmr_1.05 = log(1.05))[hp$delta_ad])
eta <- del^2 + sT2 - hp$sigma_R^2 - tp * pmax(hp$sigma_R^2, 0.01)
cl_f <- ifelse(abs(eta) <= 1e-12, "H0_sinir", ifelse(eta > 0, "H0_ic", "H1"))
cl_e <- ifelse(abs(del - log(0.85)) <= 1e-12 | abs(del - log(1.18)) <= 1e-12, "H0_sinir", ifelse(del < log(0.85) | del > log(1.18), "H0_ic", "H1"))
exp_cl <- ifelse(hp$yontem_id == "fda", cl_f, cl_e)
z <- stats::qnorm(0.95)
ps <- son[son$olcut_id == "pass", ]
ps <- merge(ps, hp[, c("senaryo_no", "yontem_id", "sinif")], by = c("senaryo_no", "yontem_id"))
lab <- ifelse(ps$tahmin - z * ps$mcse > 0.05, "nominali_asiyor", ifelse(ps$tahmin + z * ps$mcse <= 0.05, "kontrol_kanitli", "ayirt_edilemiyor"))
lab[ps$sinif == "H1"] <- NA
put("S-6g hipotez sınıfı ve KK-38 etiketi bağımsız yeniden hesapla birebir",
    identical(exp_cl, hp$sinif) && identical(lab, ps$kk38) && Kok(hp$buyukluk[hp$yontem_id == "fda"], eta[hp$yontem_id == "fda"]),
    sprintf("%d hipotez satırı; %d geçme oranı etiketi (H0: %d)", nrow(hp), nrow(ps), sum(!is.na(lab))))

# ---- S-9: run-version link -----------------------------------------------------
k <- q("SELECT * FROM kosu"); t1 <- k$tur != "birlesik"
okv <- all(!is.na(k$seed[t1]) & !is.na(k$rng[t1]) & !is.na(k$r_surumu[t1]) & !is.na(k$paket_surumu[t1]) & !is.na(k$motor_surumu[t1]) &
           (!is.na(k$motor_sha256[t1]) | !is.na(k$motor_sha256_not[t1])))
kk <- q("SELECT * FROM kosu_kaynak")
put("S-9 Koşu–sürüm bağlantısı", okv && all(k$kosu_id[!t1] %in% kk$kosu_id),
    sprintf("%d koşu (%d tek/ek, %d birleşik); motor SHA-256 dolu: %d; gerekçeli 'kayıtta yok': %d",
            nrow(k), sum(t1), sum(!t1), sum(!is.na(k$motor_sha256)), sum(t1 & is.na(k$motor_sha256))))
dbDisconnect(con)

# ---- S-7: determinism -----------------------------------------------------------
tmp <- tempfile(fileext = ".sqlite")
st <- system2(file.path(R.home("bin"), "Rscript"), c(file.path("araclar", "vt_insa.R"), tmp), stdout = FALSE, stderr = FALSE)
h1 <- sha256_raw(charToRaw(paste(vt_dokum(vt), collapse = "\n")))
h2 <- sha256_raw(charToRaw(paste(vt_dokum(tmp), collapse = "\n")))
writeLines(c(paste("dokum_sha256", h1), paste("dosya_sha256", sha256_raw(readBin(vt, "raw", file.info(vt)$size)))),
           file.path(out_dir, "vt_dokum_sha256.txt"))
put("S-7 İki inşanın içerik dökümü SHA-256 aynı", st == 0 && identical(h1, h2), sprintf("döküm %s…", substr(h1, 1, 16)))

# ---- S-8: sql.js --------------------------------------------------------------
if (is.na(sq_dir)) put("S-8 sql.js ile okuma", FALSE, "sql.js çıktısı verilmedi (vt_oku.mjs)") else {
  con <- dbConnect(SQLite(), vt)
  rs <- dbGetQuery(con, "SELECT * FROM sonuc ORDER BY senaryo_no, kosu_id, yontem_id, olcut_id")
  rh <- dbGetQuery(con, "SELECT * FROM hipotez ORDER BY senaryo_no, yontem_id"); dbDisconnect(con)
  js <- utils::read.csv(file.path(sq_dir, "sqljs_sonuc.csv"), colClasses = "character", na.strings = "NA")
  jh <- utils::read.csv(file.path(sq_dir, "sqljs_hipotez.csv"), colClasses = "character", na.strings = "NA")
  conv <- function(ref, txt) if (is.integer(ref)) as.integer(txt) else if (is.numeric(ref)) as.numeric(txt) else txt
  same <- function(a, b) identical(names(a), names(b)) &&
    all(vapply(names(a), function(n) identical(as.vector(a[[n]]), as.vector(conv(a[[n]], b[[n]]))), TRUE))
  put("S-8 sql.js ile okunan sonuc ve hipotez = R", nrow(js) == nrow(rs) && nrow(jh) == nrow(rh) && same(rs, js) && same(rh, jh),
      sprintf("sonuc %d, hipotez %d satır; bütün sütunlar birebir", nrow(js), nrow(jh)))
}

utils::write.csv(res, file.path(out_dir, "p2_kabul_vt.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nP2 kabul (bölüm 2: veri tabanı)\n")
for (r in seq_len(nrow(res))) cat(sprintf("  %-6s %s\n         %s\n", res$sonuc[r], res$kontrol[r], res$ayrinti[r]))
cat("\nGenel:", if (all(res$sonuc == "GECTI")) "GECTI" else "KALDI", "\n")
