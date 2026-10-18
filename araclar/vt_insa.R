# =============================================================================
# CNK-FarmaStatR - Build the SQLite database of precomputed results (P2, T-3/T-4)
#
# FSR-TN-PLT-02 v0.1 (approved, KK-49): Section 5 (combined runs, D-04),
#   Section 6 (schema, build, reading); decision P2-K3: built in R with RSQLite
#   (a tool dependency only; the statistical core stays base R).
# Sources (repository, read as text): simulasyon/FSR-TN-PBE-01/
#   asama1_sonuc.csv, asama2_sonuc.csv, asama1_ektekrar.csv, asama2_ektekrar.csv
#   and the run records *_kayit.csv.
# Rules
#   - Every number is taken from the CSV text with as.numeric(); nothing is
#     rounded. Derived values (hypothesis class, KK-38 label, binomial MCSE where
#     a CSV gives none) are computed here and marked as derived.
#   - Each run is its own `kosu` row; a combined run (10k + 40k) has type
#     "birlesik" and its sources in `kosu_kaynak` (KK-39). Its paired MCSE is not
#     stored because the runs kept no replicate-level decisions (P2-K2).
#   - Rows are inserted in a fixed order; the content dump (vt_dokum) is
#     deterministic. Only the build time differs between builds.
# Version 2 of the database (FSR-TN-PLT-04 T-1, KK-54; open item A-3 of KK-50):
#   adds the independent re-run of Stage 1 (bagimsiz_tekrar.csv, 48 rows) and the
#   targeted mechanism experiment (mekanizma.csv, 12 rows) as their own tables,
#   each with its run in `kosu`; writes veri/VT_SHA256.txt (SHA-256 of the
#   database file) for the browser check.
#   The re-run has no run-record file: seed, n_sim and RNG are taken from its
#   script (bagimsiz_tekrar.R); R, package and engine versions are those of the
#   environment in which it ran on 16.10.2026 together with Stage 2 (log G-41;
#   engine 0.2.0 was in the repository from the Stage 2 run, commit 44b5ef65e1).
#   This derivation is written into the run row.
# Run from the repository root:  Rscript araclar/vt_insa.R [output.sqlite]
# Default output: veri/farmastatr_v1.sqlite
# Research and education only; not a system validated for GxP environments.
# =============================================================================
suppressPackageStartupMessages({ library(DBI); library(RSQLite); library(CNKfarmastatr) })
args <- commandArgs(trailingOnly = TRUE)
vt_yol <- if (length(args) >= 1) args[1] else file.path("veri", "farmastatr_v1.sqlite")
S <- file.path("simulasyon", "FSR-TN-PBE-01")
source(file.path("araclar", "sha256.R"), encoding = "UTF-8")
sha_file <- function(p) {          # same value from every route; the base R one is slow on MB files
  if (exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE)) return(unname(tools::sha256sum(p)))
  if (requireNamespace("digest", quietly = TRUE)) return(digest::digest(file = p, algo = "sha256"))
  sha256_raw(readBin(p, "raw", file.info(p)$size))
}
rd <- function(f) utils::read.csv(file.path(S, f), colClasses = "character", stringsAsFactors = FALSE)
num <- function(x) { v <- as.numeric(x); v[x %in% c("NA", "")] <- NA_real_; v }
lg <- function(x) ifelse(x %in% c("TRUE", "FALSE"), as.integer(x == "TRUE"), NA_integer_)

# ---- pinned engine files: version -> SHA-256 (CEKIRDEK_SHA256.txt) -----------
pin <- utils::read.table(file.path("CNKfarmastatr", "inst", "validasyon", "CEKIRDEK_SHA256.txt"),
                         col.names = c("sha256", "dosya"), stringsAsFactors = FALSE)
cur_ver <- c(invitro_fast.R = "0.1.1", invitro_grid.R = "0.2.0")      # versions of the pinned files
# Earlier versions found in the git history (G-67): blob of invitro_grid.R in commit a81bebc35c
# ("Aşama 1 simülasyonu", 15.10.2026 21:19), the commit that holds the Stage 1 run.
# The 0.2.0 files are also the same git blobs as in commit 44b5ef65e1 (Stage 2 run).
hist_sha <- c("invitro_grid.R 0.1.0" = "aa5c1ab6e3ab5577302950613f3120198f03df46f6b76ceedf708733525af198")
motor_sha <- function(engine) {
  parts <- trimws(strsplit(engine, ";")[[1]])
  sh <- vapply(parts, function(p) {
    f <- sub(" .*$", "", p); v <- sub("^.* ", "", p)
    if (!is.na(cur_ver[f]) && cur_ver[f] == v) paste0(f, " ", v, " ", pin$sha256[pin$dosya == f])
    else if (!is.na(hist_sha[p])) paste0(p, " ", hist_sha[[p]], " (git a81bebc35c)") else NA_character_
  }, "")
  if (anyNA(sh)) list(sha = NA_character_,
                      not = paste0("kayitta yok: ", paste(parts[is.na(sh)], collapse = ", "),
                                   " sabitlenmis surum degil; SHA-256 kosu kaydinda yok (FSR-TN-PLT-02 Bulgu 2)"))
  else list(sha = paste(sh, collapse = "; "), not = NA_character_)
}

# ---- sources -------------------------------------------------------------------
src_files <- c("asama1_sonuc.csv", "asama2_sonuc.csv", "asama1_ektekrar.csv", "asama2_ektekrar.csv",
               "asama1_kayit.csv", "asama2_kayit.csv", "asama1_ektekrar_kayit.csv",
               "bagimsiz_tekrar.csv", "bagimsiz_tekrar.R", "mekanizma.csv", "mekanizma_kayit.csv")
a1 <- rd("asama1_sonuc.csv"); a2 <- rd("asama2_sonuc.csv")
e1 <- rd("asama1_ektekrar.csv"); e2 <- rd("asama2_ektekrar.csv")
k1 <- rd("asama1_kayit.csv"); k2 <- rd("asama2_kayit.csv"); k1e <- rd("asama1_ektekrar_kayit.csv")
a1$asama <- "1"; a1$block <- "S1"; a1$factor <- NA; a1$regulatory <- NA; a2$asama <- "2"
pcols <- c("sigma_R", "rho", "pB_T", "pB_R", "pL", "q", "l", "n", "m")
g <- rbind(a1[, c("scenario", "asama", "block", "factor", "regulatory", pcols, "delta_id", "delta", "gmr", "eta")],
           a2[, c("scenario", "asama", "block", "factor", "regulatory", pcols, "delta_id", "delta", "gmr", "eta")])
g$senaryo_id <- with(g, platform_anahtar(num(sigma_R), num(rho), num(pB_T), num(pB_R), num(pL), num(q),
                                         num(l), num(n), num(m), sinir = delta_id))
stopifnot(!anyDuplicated(g$senaryo_id))
g <- g[order(g$senaryo_id, method = "radix"), ]   # byte order, independent of locale (G-67)
g$senaryo_no <- seq_len(nrow(g))                       # compact integer id, ordered by key
sid <- setNames(g$senaryo_no, g$scenario)

# ---- tables ---------------------------------------------------------------------
modul <- data.frame(modul_id = "invitro_pbe", ad = "In vitro esdegerlik: FDA PBE (PSG 020929) ve EMA OIP (Rev. 2, 5.1 olcut 8)",
                    calisma = "FSR-TN-PBE-01", stringsAsFactors = FALSE)
senaryo <- data.frame(senaryo_no = g$senaryo_no, senaryo_anahtar = g$senaryo_id, modul_id = "invitro_pbe", calisma = "FSR-TN-PBE-01",
                      asama = as.integer(g$asama), izgara_kodu = g$scenario, blok = g$block, faktor = g$factor,
                      duzenleyici = lg(g$regulatory),
                      sigma_R = num(g$sigma_R), rho = num(g$rho), pB_T = num(g$pB_T), pB_R = num(g$pB_R),
                      pL = num(g$pL), q = num(g$q), l = as.integer(g$l), n = as.integer(g$n), m = as.integer(g$m),
                      delta_ad = g$delta_id, delta = num(g$delta), gmr = num(g$gmr), eta = num(g$eta),
                      stringsAsFactors = FALSE)

kosu_row <- function(id, tur, asama, aciklama, n_sim, seed, rec, kaynak, kayit) {
  ms <- if (is.null(rec)) list(sha = NA_character_, not = "birlesik kosu: kaynak kosulara bakiniz") else motor_sha(rec$engine)
  data.frame(kosu_id = id, tur = tur, calisma = "FSR-TN-PBE-01", asama = asama, aciklama = aciklama,
             n_sim = as.integer(n_sim), seed = if (is.na(seed)) NA_integer_ else as.integer(seed),
             rng = if (is.null(rec)) NA else rec$rng, r_surumu = if (is.null(rec)) NA else rec$r_version,
             paket_surumu = if (is.null(rec)) NA else rec$package_version,
             motor_surumu = if (is.null(rec)) NA else rec$engine, motor_sha256 = ms$sha, motor_sha256_not = ms$not,
             calisma_zamani = if (is.null(rec)) NA else rec$run_time, kaynak_dosya = kaynak, kayit_dosyasi = kayit,
             stringsAsFactors = FALSE)
}
k2e <- k2; k2e$seed <- k2$seed_extra; k2e$n_sim <- k2$n_extra
kosu <- rbind(
  kosu_row("PBE01-A1", "tek", 1L, "Asama 1 ana kosu (KK-34)", k1$n_sim, k1$seed, k1, "asama1_sonuc.csv", "asama1_kayit.csv"),
  kosu_row("PBE01-A1-EK", "ek", 1L, "Asama 1 ek tekrar, esige yakin guc hucreleri (KK-37)", k1e$n_sim, k1e$seed, k1e, "asama1_ektekrar.csv", "asama1_ektekrar_kayit.csv"),
  kosu_row("PBE01-A1-BIR", "birlesik", 1L, "Asama 1 birlesik 10.000 + 40.000 (bagimsiz akis varsayimi; KK-39)", 50000, NA, NULL, "asama1_ektekrar.csv", NA),
  kosu_row("PBE01-A2", "tek", 2L, "Asama 2 ana kosu (KK-37)", k2$n_sim, k2$seed, k2, "asama2_sonuc.csv", "asama2_kayit.csv"),
  kosu_row("PBE01-A2-EK", "ek", 2L, "Asama 2 ek tekrar, esige yakin guc hucreleri (KK-37)", k2e$n_sim, k2e$seed, k2e, "asama2_ektekrar.csv", "asama2_kayit.csv"),
  kosu_row("PBE01-A2-BIR", "birlesik", 2L, "Asama 2 birlesik 10.000 + 40.000 (bagimsiz akis varsayimi; KK-39)", 50000, NA, NULL, "asama2_ektekrar.csv", NA))
bt <- rd("bagimsiz_tekrar.csv"); mk <- rd("mekanizma.csv"); kmk <- rd("mekanizma_kayit.csv")
bt_src <- readLines(file.path(S, "bagimsiz_tekrar.R"), warn = FALSE, encoding = "UTF-8")
stopifnot(any(grepl("seed = 20261019", bt_src, fixed = TRUE)), any(grepl("n_sim = 40000", bt_src, fixed = TRUE)))
kbt <- data.frame(seed = "20261019", n_sim = "40000", rng = "Mersenne-Twister/Inversion",
                  r_version = k2$r_version, package_version = k2$package_version, engine = k2$engine,
                  run_time = NA_character_, stringsAsFactors = FALSE)
kosu <- rbind(kosu,
  kosu_row("PBE01-A1-BT", "tekrar", 1L, paste("Asama 1 ana hucrelerinin bagimsiz seed ile yeniden uretimi (M-12, G-41).",
           "Kosu kaydi dosyasi yok: seed, n_sim ve RNG betikten (bagimsiz_tekrar.R; invitro_scenario RNG turunu sabitler);",
           "R, paket ve motor surumu, kosunun Asama 2 ile ayni gun ve ayni ortamda yapilmasindan turetildi (asama2_kayit.csv; G-41)"),
           kbt$n_sim, kbt$seed, kbt, "bagimsiz_tekrar.csv", NA),
  kosu_row("PBE01-MEK", "deney", NA_integer_, "Hedefli deney: kriter secimi ve mekanizma (teknik not 12.2-12.3; G-43)",
           kmk$n_sim, kmk$seed, kmk, "mekanizma.csv", "mekanizma_kayit.csv"))
bagimsiz_tekrar <- data.frame(senaryo_no = unname(sid[bt$scenario]), izgara_kodu = bt$scenario, kosu_id = "PBE01-A1-BT",
                              yontem_id = bt$method, pB = num(bt$pB), delta_ad = bt$delta_id,
                              asama1 = num(bt$stage1), asama1_mcse = num(bt$stage1_mcse),
                              tekrar = num(bt$rerun), tekrar_mcse = num(bt$rerun_mcse), z = num(bt$z), stringsAsFactors = FALSE)
stopifnot(!anyNA(bagimsiz_tekrar$senaryo_no))
mekanizma <- data.frame(deney_no = seq_len(nrow(mk)), kosu_id = "PBE01-MEK",
                        as.data.frame(lapply(mk, num), stringsAsFactors = FALSE), stringsAsFactors = FALSE)

kosu_kaynak <- data.frame(kosu_id = rep(c("PBE01-A1-BIR", "PBE01-A2-BIR"), each = 2),
                          kaynak_kosu_id = c("PBE01-A1", "PBE01-A1-EK", "PBE01-A2", "PBE01-A2-EK"),
                          varsayim = "bagimsiz rastgele sayi akislari (farkli seed); birlesik oran = toplam gecme / toplam tekrar",
                          stringsAsFactors = FALSE)
yontem <- data.frame(yontem_id = c("fda", "ema_a", "ema_b", "ema_c"),
                     ad = c("FDA PBE (PSG 020929)", "EMA (a) birimler havuzlu", "EMA (b) seri ortalamalari", "EMA (c) REML"),
                     stringsAsFactors = FALSE)
olcut <- data.frame(olcut_id = c("pass", "cover", "crit_err", "bias_Eq", "bias_s2R", "pooled_T", "pooled_R"),
                    tur = c("oran", "oran", "oran", "ortalama", "ortalama", "oran", "oran"),
                    aciklama = c("BE kabul (gecme) orani", "kapsama orani", "kriter secim hatasi orani",
                                 "Eq sapmasi", "sigma_R^2 sapmasi", "REML havuzlama orani (TEST)", "REML havuzlama orani (REF)"),
                    stringsAsFactors = FALSE)

# results from the main grids (wide CSV -> long)
long_main <- function(x, kosu_id) {
  spec <- rbind(
    data.frame(y = "fda", o = c("pass", "cover", "crit_err", "bias_Eq", "bias_s2R"),
               col = c("fda_pass", "fda_cover", "fda_crit_err", "fda_bias_Eq", "fda_bias_s2R")),
    do.call(rbind, lapply(c("ema_a", "ema_b", "ema_c"), function(me)
      data.frame(y = me, o = c("pass", "cover"), col = paste0(me, c("_pass", "_cover"))))),
    data.frame(y = "ema_c", o = c("pooled_T", "pooled_R"), col = c("ema_c_pooled_T", "ema_c_pooled_R")))
  spec <- spec[spec$col %in% names(x), ]
  do.call(rbind, lapply(seq_len(nrow(spec)), function(j) data.frame(
    senaryo_no = sid[x$scenario], kosu_id = kosu_id, yontem_id = spec$y[j], olcut_id = spec$o[j],
    tahmin = num(x[[spec$col[j]]]), mcse = num(x[[paste0(spec$col[j], "_mcse")]]), mcse_kaynak = "csv",
    n_tekrar = as.integer(x$n_sim), stringsAsFactors = FALSE)))
}
sonuc <- rbind(long_main(a1, "PBE01-A1"), long_main(a2, "PBE01-A2"))

# extra and combined runs (pass rates only; pooled shares of Stage 1 extra run)
binse <- function(p, n) sqrt(p * (1 - p) / n)
ek1 <- data.frame(senaryo_no = sid[e1$scenario], kosu_id = "PBE01-A1-EK", yontem_id = e1$method, olcut_id = "pass",
                  tahmin = num(e1$power_40k), mcse = num(e1$mcse_40k), mcse_kaynak = "csv", n_tekrar = 40000L, stringsAsFactors = FALSE)
pc <- e1[e1$method == "ema_c", ]
ek1p <- do.call(rbind, lapply(c("T", "R"), function(pr) {
  p <- num(pc[[paste0("ema_c_pooled_", pr, "_40k")]])
  data.frame(senaryo_no = sid[pc$scenario], kosu_id = "PBE01-A1-EK", yontem_id = "ema_c", olcut_id = paste0("pooled_", pr),
             tahmin = p, mcse = binse(p, 40000), mcse_kaynak = "turetilmis: sqrt(p(1-p)/n)", n_tekrar = 40000L, stringsAsFactors = FALSE) }))
bir1 <- data.frame(senaryo_no = sid[e1$scenario], kosu_id = "PBE01-A1-BIR", yontem_id = e1$method, olcut_id = "pass",
                   tahmin = num(e1$power_50k), mcse = num(e1$mcse_50k), mcse_kaynak = "csv", n_tekrar = 50000L, stringsAsFactors = FALSE)
ek2 <- data.frame(senaryo_no = sid[e2$scenario], kosu_id = "PBE01-A2-EK", yontem_id = e2$method, olcut_id = "pass",
                  tahmin = num(e2$power_40k), mcse = num(e2$mcse_40k), mcse_kaynak = "csv", n_tekrar = 40000L, stringsAsFactors = FALSE)
bir2 <- data.frame(senaryo_no = sid[e2$scenario], kosu_id = "PBE01-A2-BIR", yontem_id = e2$method, olcut_id = "pass",
                   tahmin = num(e2$power_50k), mcse = num(e2$mcse_50k), mcse_kaynak = "csv", n_tekrar = 50000L, stringsAsFactors = FALSE)
sonuc <- rbind(sonuc, ek1, ek1p, bir1, ek2, bir2)
stopifnot(!anyNA(sonuc$senaryo_no))

# paired differences
pairs <- list(c("fda", "ema_a"), c("fda", "ema_b"), c("fda", "ema_c"), c("ema_a", "ema_c"), c("ema_b", "ema_c"))
fark <- do.call(rbind, lapply(pairs, function(pp) {
  col <- paste0("diff_", pp[1], "_", pp[2])
  data.frame(senaryo_no = sid[a2$scenario], kosu_id = "PBE01-A2", yontem_1 = pp[1], yontem_2 = pp[2],
             tahmin = num(a2[[col]]), mcse = num(a2[[paste0(col, "_mcse")]]), mcse_not = NA_character_, stringsAsFactors = FALSE) }))
f1 <- e1[e1$method != "ema_c", ]
fark <- rbind(fark, data.frame(senaryo_no = sid[f1$scenario], kosu_id = "PBE01-A1-EK", yontem_1 = f1$method, yontem_2 = "ema_c",
                               tahmin = num(f1$diff_vs_ema_c_40k), mcse = num(f1$diff_vs_ema_c_40k_mcse), mcse_not = NA_character_,
                               stringsAsFactors = FALSE))
fb <- e1[e1$method != "ema_c", ]
pw <- function(e, me, sc) num(e$power_50k[e$method == me & e$scenario == sc])
fark <- rbind(fark, data.frame(senaryo_no = sid[fb$scenario], kosu_id = "PBE01-A1-BIR", yontem_1 = fb$method, yontem_2 = "ema_c",
                               tahmin = num(fb$power_50k) - vapply(fb$scenario, function(sc) pw(e1, "ema_c", sc), 0),
                               mcse = NA_real_, mcse_not = "saklanmadi: tekrar duzeyinde karar yok (P2-K2)", stringsAsFactors = FALSE))

# hypothesis state (derived) and KK-38 labels on pass rates (derived)
h <- platform_hipotez(senaryo$sigma_R, senaryo$rho, sinir = senaryo$delta_ad)
hipotez <- data.frame(senaryo_no = senaryo$senaryo_no[h$senaryo], yontem_id = h$yontem, buyukluk = h$buyukluk,
                      buyukluk_tur = h$buyukluk_tur, sinif = h$sinif, metrik = h$metrik,
                      yakinlik_uyarisi = as.integer(h$yakinlik_uyarisi), delta_hesap_metin = h$delta_metin,
                      stringsAsFactors = FALSE)
cls <- setNames(hipotez$sinif, paste(hipotez$senaryo_no, hipotez$yontem_id))
ip <- sonuc$olcut_id == "pass"
sonuc$kk38 <- NA_character_
sonuc$kk38[ip] <- platform_kk38(sonuc$tahmin[ip], sonuc$mcse[ip], cls[paste(sonuc$senaryo_no[ip], sonuc$yontem_id[ip])])

# fixed order
sonuc <- sonuc[order(sonuc$senaryo_no, sonuc$kosu_id, sonuc$yontem_id, sonuc$olcut_id, method = "radix"), ]
fark <- fark[order(fark$senaryo_no, fark$kosu_id, fark$yontem_1, fark$yontem_2, method = "radix"), ]
hipotez <- hipotez[order(hipotez$senaryo_no, hipotez$yontem_id, method = "radix"), ]
senaryo <- senaryo[order(senaryo$senaryo_no, method = "radix"), ]
bagimsiz_tekrar <- bagimsiz_tekrar[order(bagimsiz_tekrar$senaryo_no, bagimsiz_tekrar$yontem_id, method = "radix"), ]

dosya <- data.frame(dosya_yolu = c(file.path(S, src_files), file.path("araclar", "vt_insa.R"),
                                   file.path("CNKfarmastatr", "R", "platform_hipotez.R")),
                    rol = c(rep("kaynak", length(src_files)), "insa_betigi", "turetme"), stringsAsFactors = FALSE)
dosya$sha256 <- vapply(dosya$dosya_yolu, sha_file, "")
insa <- data.frame(anahtar = c("platform", "paket_surumu", "vt_surumu", "beyan", "r_surumu", "rsqlite_surumu", "insa_zamani"),
                   deger = c("CNK-FarmaStatR", as.character(utils::packageVersion("CNKfarmastatr")), "2",
                             "Arastirma ve egitim amaclidir; GxP ortaminda valide edilmis sistem degildir.",
                             R.version.string, as.character(utils::packageVersion("RSQLite")),
                             format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")), stringsAsFactors = FALSE)

# ---- write --------------------------------------------------------------------
dir.create(dirname(vt_yol), showWarnings = FALSE, recursive = TRUE)
if (file.exists(vt_yol)) file.remove(vt_yol)
con <- dbConnect(RSQLite::SQLite(), vt_yol)
ddl <- c(
  "CREATE TABLE insa (anahtar TEXT PRIMARY KEY, deger TEXT)",
  "CREATE TABLE dosya (dosya_yolu TEXT PRIMARY KEY, rol TEXT, sha256 TEXT NOT NULL)",
  "CREATE TABLE modul (modul_id TEXT PRIMARY KEY, ad TEXT, calisma TEXT)",
  "CREATE TABLE senaryo (senaryo_no INTEGER PRIMARY KEY, senaryo_anahtar TEXT NOT NULL UNIQUE, modul_id TEXT REFERENCES modul, calisma TEXT, asama INTEGER, izgara_kodu TEXT,
     blok TEXT, faktor TEXT, duzenleyici INTEGER, sigma_R REAL, rho REAL, pB_T REAL, pB_R REAL, pL REAL, q REAL,
     l INTEGER, n INTEGER, m INTEGER, delta_ad TEXT, delta REAL, gmr REAL, eta REAL)",
  "CREATE TABLE kosu (kosu_id TEXT PRIMARY KEY, tur TEXT NOT NULL, calisma TEXT, asama INTEGER, aciklama TEXT, n_sim INTEGER NOT NULL,
     seed INTEGER, rng TEXT, r_surumu TEXT, paket_surumu TEXT, motor_surumu TEXT, motor_sha256 TEXT, motor_sha256_not TEXT,
     calisma_zamani TEXT, kaynak_dosya TEXT, kayit_dosyasi TEXT)",
  "CREATE TABLE kosu_kaynak (kosu_id TEXT REFERENCES kosu, kaynak_kosu_id TEXT REFERENCES kosu, varsayim TEXT, PRIMARY KEY (kosu_id, kaynak_kosu_id))",
  "CREATE TABLE yontem (yontem_id TEXT PRIMARY KEY, ad TEXT)",
  "CREATE TABLE olcut (olcut_id TEXT PRIMARY KEY, tur TEXT, aciklama TEXT)",
  "CREATE TABLE sonuc (senaryo_no INTEGER REFERENCES senaryo, kosu_id TEXT REFERENCES kosu, yontem_id TEXT REFERENCES yontem,
     olcut_id TEXT REFERENCES olcut, tahmin REAL, mcse REAL, mcse_kaynak TEXT, n_tekrar INTEGER, kk38 TEXT,
     PRIMARY KEY (senaryo_no, kosu_id, yontem_id, olcut_id))",
  "CREATE TABLE fark (senaryo_no INTEGER REFERENCES senaryo, kosu_id TEXT REFERENCES kosu, yontem_1 TEXT, yontem_2 TEXT,
     tahmin REAL, mcse REAL, mcse_not TEXT, PRIMARY KEY (senaryo_no, kosu_id, yontem_1, yontem_2))",
  "CREATE TABLE hipotez (senaryo_no INTEGER REFERENCES senaryo, yontem_id TEXT REFERENCES yontem, buyukluk REAL, buyukluk_tur TEXT,
     sinif TEXT, metrik TEXT, yakinlik_uyarisi INTEGER, delta_hesap_metin TEXT, PRIMARY KEY (senaryo_no, yontem_id))",
  "CREATE TABLE bagimsiz_tekrar (senaryo_no INTEGER REFERENCES senaryo, izgara_kodu TEXT, kosu_id TEXT REFERENCES kosu,
     yontem_id TEXT REFERENCES yontem, pB REAL, delta_ad TEXT, asama1 REAL, asama1_mcse REAL, tekrar REAL, tekrar_mcse REAL, z REAL,
     PRIMARY KEY (senaryo_no, yontem_id))",
  paste0("CREATE TABLE mekanizma (deney_no INTEGER PRIMARY KEY, kosu_id TEXT REFERENCES kosu, ",
         paste(sprintf("%s REAL", names(mk)), collapse = ", "), ")"),
  "CREATE TABLE yayin (yayin_id TEXT PRIMARY KEY, kunye TEXT, doi TEXT)",
  "CREATE TABLE veri_seti (veri_seti_id TEXT PRIMARY KEY, yayin_id TEXT REFERENCES yayin, aciklama TEXT, sha256 TEXT)",
  "CREATE TABLE test_vakasi (test_id TEXT PRIMARY KEY, modul_id TEXT REFERENCES modul, aciklama TEXT, beklenen TEXT)")
dbBegin(con)
for (d in ddl) dbExecute(con, d)
for (nm in c("insa", "dosya", "modul", "senaryo", "kosu", "kosu_kaynak", "yontem", "olcut", "sonuc", "fark", "hipotez",
             "bagimsiz_tekrar", "mekanizma")) {
  x <- get(nm); rownames(x) <- NULL
  dbWriteTable(con, nm, x, append = TRUE)
}
dbCommit(con)
# integrity: every run row must carry the version fields (S-9)
k <- dbGetQuery(con, "SELECT * FROM kosu")
tek <- k$tur != "birlesik"
bad <- tek & (is.na(k$seed) | is.na(k$rng) | is.na(k$r_surumu) | is.na(k$paket_surumu) | is.na(k$motor_surumu) |
               (is.na(k$motor_sha256) & is.na(k$motor_sha256_not)))
if (any(bad)) { dbDisconnect(con); file.remove(vt_yol); stop("Run record incomplete: ", paste(k$kosu_id[bad], collapse = ", ")) }
n <- vapply(c("senaryo", "kosu", "sonuc", "fark", "hipotez", "bagimsiz_tekrar", "mekanizma"), function(t) dbGetQuery(con, paste("SELECT COUNT(*) AS n FROM", t))$n, 0)
dbDisconnect(con)
cat(sprintf("Veri tabani: %s (%.2f MB)\n", vt_yol, file.info(vt_yol)$size / 2^20))
# SHA-256 of the database file for the browser check (FSR-TN-PLT-04 Section 5)
writeLines(paste0(sha_file(vt_yol), "  ", basename(vt_yol)), file.path(dirname(vt_yol), "VT_SHA256.txt"))
print(n)
