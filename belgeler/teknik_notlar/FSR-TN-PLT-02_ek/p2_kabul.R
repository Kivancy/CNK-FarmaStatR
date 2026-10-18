# =============================================================================
# FSR-TN-PLT-02 - P2 acceptance checks on the simulation grids (Table 8.1)
#   Part 1 (T-1, T-2): H-1...H-4 (FSR-TN-PLT-01 Table 5.3), S-3 (class counts
#   equal to the P0 prototype), S-4 (KK-38 labels equal to asama2_ozet.R output),
#   K-1 (ii) and (iv) (canonical keys on the grid).
#   The unit tests (H-5, H-6, H-7, K-1 i/iii) are in
#   CNKfarmastatr/tests/testthat/test-platform-hipotez.R.
# Run from the repository root with the package installed:
#   Rscript belgeler/teknik_notlar/FSR-TN-PLT-02_ek/p2_kabul.R
# Output: p2_kabul_t1.csv (check, result, detail) in this folder.
# Research and education only; not a system validated for GxP environments.
# =============================================================================
suppressPackageStartupMessages(library(CNKfarmastatr))
S <- file.path("simulasyon", "FSR-TN-PBE-01")
out_dir <- file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-02_ek")
rd <- function(f) utils::read.csv(file.path(S, f), stringsAsFactors = FALSE)
a <- rd("asama1_sonuc.csv"); a$stage <- 1
b <- rd("asama2_sonuc.csv"); b$stage <- 2
cols <- c("stage", "scenario", "delta_id", "sigma_R", "rho", "pB_T", "pB_R", "pL", "q", "l", "n", "m", "delta", "eta")
g <- rbind(a[, cols], b[, cols])
res <- data.frame(kontrol = character(0), sonuc = character(0), ayrinti = character(0), stringsAsFactors = FALSE)
put <- function(k, ok, d) res[nrow(res) + 1, ] <<- c(k, if (ok) "GECTI" else "KALDI", d)

h <- platform_hipotez(g$sigma_R, g$rho, sinir = g$delta_id)
h$stage <- g$stage[h$senaryo]; h$delta_id <- g$delta_id[h$senaryo]
fda <- h[h$yontem == "fda", ]; ema <- h[h$yontem != "fda", ]

# H-1 ... H-4
k <- fda$delta_id %in% c("fda_delta0", "fda_minus_delta0")
put("H-1 FDA δ₀ ve −δ₀ senaryoları FDA'da H0 sınırı", all(fda$sinif[k] == "H0_sinir"), sprintf("%d senaryo", sum(k)))
k <- ema$delta_id %in% c("ema_1.18", "ema_0.85")
put("H-2 GMR 1,18 ve 0,85 senaryoları EMA'da H0 sınırı", all(ema$sinif[k] == "H0_sinir"), sprintf("%d senaryo × 3 yol", sum(k) / 3))
k <- h$delta_id %in% c("gmr_1.00", "gmr_1.05")
put("H-3 GMR 1,00 ve 1,05 senaryoları iki yöntemde H1", all(h$sinif[k] == "H1"), sprintf("%d senaryo", sum(k) / 4))
d_eta <- abs(fda$buyukluk - g$eta)
d_del <- abs(platform_sinir_delta(g$delta_id, g$sigma_R, g$rho) - g$delta)
sign_wrong <- sum(g$delta_id == "fda_delta0" & g$eta < 0)
put("H-4 Saklanan η ile hesaplanan η farkı ≤ 1e-12; işaret tek başına yetmez",
    max(d_eta) <= 1e-12, sprintf("en büyük |Δη| %.2e; en büyük |Δδ| (CSV 15 basamak) %.2e; işarete göre yanlış sınıflanacak δ₀ senaryosu %d (tolerans giderir)",
                                 max(d_eta), max(d_del), sign_wrong))

# S-3: class counts equal to the P0 prototype (FSR-TN-PLT-01_ek/hipotez_siniflandirma.csv)
p0 <- utils::read.csv(file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-01_ek", "hipotez_siniflandirma.csv"), stringsAsFactors = FALSE)
cur <- h[h$yontem %in% c("fda", "ema_a"), ]
cur$method <- ifelse(cur$yontem == "fda", "fda", "ema")
cc <- stats::aggregate(list(n = rep(1, nrow(cur))), cur[, c("stage", "delta_id", "method", "sinif")], sum)
names(cc)[4] <- "class"
m <- merge(cc, p0[, c("stage", "delta_id", "method", "class", "n")], by = c("stage", "delta_id", "method", "class"),
           all = TRUE, suffixes = c("_p2", "_p0"))
ema_same <- all(tapply(ema$sinif, ema$senaryo, function(x) length(unique(x)) == 1))
put("S-3 Izgara sınıf sayıları = P0 prototipi", nrow(m) == nrow(p0) && all(m$n_p2 == m$n_p0, na.rm = FALSE) && !anyNA(m$n_p2) && ema_same,
    sprintf("%d grup; EMA üç yolda aynı sınıf: %s", nrow(m), ema_same))

# S-4: KK-38 labels - re-run asama2_ozet.R with its label rule replaced by platform_kk38()
tmp <- tempfile("p2ozet"); dir.create(file.path(tmp, S, "sekil"), recursive = TRUE)
for (f in c("asama1_sonuc.csv", "asama2_sonuc.csv", "asama2_ektekrar.csv")) file.copy(file.path(S, f), file.path(tmp, S, f))
src <- readLines(file.path(S, "asama2_ozet.R"), encoding = "UTF-8")
i <- grep("^lab <- function\\(p, se\\)", src); stopifnot(length(i) == 1)
src[i] <- 'lab <- function(p, se) paste0(pct(p), c(nominali_asiyor = "*", ayirt_edilemiyor = "+", kontrol_kanitli = "")[CNKfarmastatr::platform_kk38(p, se, "H0_sinir")])'
owd <- setwd(tmp); ok_run <- tryCatch({ eval(parse(text = src, encoding = "UTF-8"), envir = new.env()); TRUE },
                                      error = function(e) { message(conditionMessage(e)); FALSE }); setwd(owd)
oz <- list.files(S, pattern = "^asama2_ozet_.*\\.csv$")
same <- vapply(oz, function(f) identical(readLines(file.path(S, f), encoding = "UTF-8"),
                                         readLines(file.path(tmp, S, f), encoding = "UTF-8")), TRUE)
put("S-4 KK-38 etiketleri = asama2_ozet.R tabloları", ok_run && all(same) && length(oz) == 7,
    sprintf("%d özet CSV, platform_kk38() ile yeniden üretildi; birebir aynı: %d", length(oz), sum(same)))

# K-1 (ii), (iv): keys on the grid
key_name <- with(g, platform_anahtar(sigma_R, rho, pB_T, pB_R, pL, q, l, n, m, sinir = delta_id))
key_num  <- with(g, platform_anahtar(sigma_R, rho, pB_T, pB_R, pL, q, l, n, m, delta = delta))
named0 <- g$delta_id == "fda_delta0"
put("K-1 (ii) δ₀: ad anahtarı ≠ 15 basamaklı CSV sayısının anahtarı", all(key_name[named0] != key_num[named0]),
    sprintf("%d δ₀ senaryosu; satırlar ada göre eşleşir", sum(named0)))
dup_in <- tapply(key_name, g$stage, function(x) sum(duplicated(x)))
cross <- sum(key_name[g$stage == 2] %in% key_name[g$stage == 1])
put("K-1 (iv) Anahtar her aşamada tekil", all(dup_in == 0),
    sprintf("Aşama 1: %d, Aşama 2: %d senaryo; aşama içi yinelenen %s; iki aşamada ortak senaryo %d (aynı koşul, ayrı koşu)",
            sum(g$stage == 1), sum(g$stage == 2), paste(dup_in, collapse = "/"), cross))

utils::write.csv(res, file.path(out_dir, "p2_kabul_t1.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nP2 kabul (bölüm 1: sınıflandırma ve anahtar)\n")
for (r in seq_len(nrow(res))) cat(sprintf("  %-6s %s\n         %s\n", res$sonuc[r], res$kontrol[r], res$ayrinti[r]))
cat("\nGenel:", if (all(res$sonuc == "GECTI")) "GECTI" else "KALDI", "\n")
