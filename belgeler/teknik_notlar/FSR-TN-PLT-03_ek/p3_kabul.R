# =============================================================================
# CNK-FarmaStatR - P3 acceptance (FSR-TN-PLT-03 v0.1, Table 8.1; frozen by KK-51)
#
# Applies the frozen criteria and writes one line per criterion as GECTI (pass),
# KALDI (fail) or EKSIK (data missing):
#   E-1  the 36-run P1 set: script result identical() to platform_run_invitro()
#   E-2  browser runs: the downloaded scripts, run in this R, give the browser's
#        decision counts exactly; all other numbers within K(1e-12, 1e-12)
#   E-3  integrity: one changed byte in three files stops the script; SHA-256 of
#        the script = CEKIRDEK_SHA256.txt = an independent SHA-256 tool
#   E-4  embedded files byte-identical to the repository files
#   E-9  (browser part) the script written in webR = the script written here,
#        apart from the export time line
#   E-10 the script runs with R --vanilla, CNKfarmastatr not loaded (and, where the
#        library paths allow, not installed), and gives the E-1 result
# E-5 ... E-9 (local part) are testthat tests (test-platform-export.R), run by CI.
# Rule K(a, r): |x_hat - x| <= a + r * max(|x|, |x_hat|)   (KK-41), a = r = 1e-12
#
# Browser files for E-2 (FSR-TN-PLT-03_ek/p3/): for each of the three runs in the
#   prototype, the run record (farmastatr_p1_*.json, "Koşu kaydını indir") and the
#   script (farmastatr_senaryo_*.R, "R betiği indir"). Pairs are matched by the
#   start time of the run, which the script carries in its header.
# Run from the repository root:  source("belgeler/teknik_notlar/FSR-TN-PLT-03_ek/p3_kabul.R", encoding = "UTF-8")
# Base R only (the package is not needed; the R files are read from the repository).
# Research and education only; not a system validated for GxP environments.
# =============================================================================
local({
out_dir <- file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-03_ek")
br_dir <- file.path(out_dir, "p3")
Rdir <- file.path("CNKfarmastatr", "R")
stopifnot(file.exists(file.path(Rdir, "platform_export.R")))
t_start <- Sys.time()

# --- the R files of this repository, in a private environment ------------------
pk <- new.env(parent = globalenv())
for (f in c("sim_run.R", "invitro_fast.R", "invitro_grid.R", "platform_input.R",
            "platform_hipotez.R", "platform_export.R"))
  sys.source(file.path(Rdir, f), envir = pk, keep.source = FALSE)
files <- pk$platform_motor_dosyalari(Rdir)
pinned <- pk$platform_cekirdek_sha(file.path("CNKfarmastatr", "inst", "validasyon", "CEKIRDEK_SHA256.txt"))
T0 <- as.POSIXct("2026-10-18 12:00:00", tz = "UTC")
exp_txt <- function(p, sinir = NULL, ...)
  pk$platform_export_invitro(p, sinir = sinir, dosyalar = files, cekirdek_sha = pinned, zaman = T0, ...)
run_txt <- function(txt) {
  txt <- sub("output_dir <- \".\"", "output_dir <- NULL", txt, fixed = TRUE)
  env <- new.env(parent = globalenv())
  err <- tryCatch({ invisible(utils::capture.output(eval(parse(text = txt, keep.source = FALSE), envir = env))); NULL },
                  error = function(e) conditionMessage(e))
  list(env = env, error = err)
}
full <- function(p, delta) {
  q <- list(sigma_R = p$sigma_R, rho = 1, pB_T = p$pB, pB_R = p$pB, pL = 0.15, q = 0, l = p$l, n = p$n,
            m = p$m, n_sim = p$n_sim, seed = 20261015, alpha = 0.05, sigma_T0 = 0.1, ema_limits = c(0.85, 1.18))
  c(q, list(delta = delta))
}
K <- function(a, b) abs(a - b) <= 1e-12 + 1e-12 * pmax(abs(a), abs(b))
res <- data.frame(olcut = character(0), sonuc = character(0), ayrinti = character(0), stringsAsFactors = FALSE)
put <- function(o, s, a) { res[nrow(res) + 1, ] <<- c(o, s, a); cat(sprintf("%-46s %-6s %s\n", o, s, a)) }

# --- E-1: the P1 test set (36 runs) ---------------------------------------------
grid <- expand.grid(d = c("2x5", "3x10", "6x30"), m = 1:3, pB = c(0, 0.3), s = c("fda_delta0", "gmr_1.05"),
                    stringsAsFactors = FALSE)
same <- logical(nrow(grid)); e1_first <- NULL
for (i in seq_len(nrow(grid))) {
  g <- grid[i, ]; ln <- as.numeric(strsplit(g$d, "x")[[1]])
  p <- list(sigma_R = 0.12, pB = g$pB, l = ln[1], n = ln[2], m = g$m, n_sim = 2000)
  r <- run_txt(exp_txt(p, g$s))
  d <- pk$platform_sinir_delta(g$s, 0.12, 1)
  ref <- pk$platform_run_invitro(full(p, d), n_sim_max = Inf, cells_max = Inf)
  same[i] <- is.null(r$error) && identical(r$env$run$result, ref)
  if (i == 1) e1_first <- list(p = p, s = g$s, ref = ref)
  cat(".")
}
cat("\n")
put("E-1 Aynı ortamda birebir (36 koşu)", if (all(same)) "GECTI" else "KALDI",
    sprintf("identical: %d / %d", sum(same), length(same)))

# --- E-3: integrity -----------------------------------------------------------------
indep <- function(path) {                     # an independent SHA-256 tool, if any
  if (exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE))
    return(list(tool = "tools::sha256sum", v = unname(tools::sha256sum(path))))
  if (requireNamespace("digest", quietly = TRUE))
    return(list(tool = "digest", v = digest::digest(file = path, algo = "sha256")))
  if (nzchar(Sys.which("sha256sum")))
    return(list(tool = "GNU sha256sum", v = sub(" .*", "", system2("sha256sum", shQuote(path), stdout = TRUE))))
  if (.Platform$OS.type == "windows" && nzchar(Sys.which("certutil"))) {
    o <- system2("certutil", c("-hashfile", shQuote(normalizePath(path)), "SHA256"), stdout = TRUE)
    h <- gsub("[^0-9a-fA-F]", "", o[2])
    if (nchar(h) == 64) return(list(tool = "Windows certutil", v = tolower(h)))
  }
  list(tool = "yok", v = NA_character_)
}
txt <- exp_txt(list(sigma_R = 0.12, n_sim = 200), "fda_delta0")
tamper <- list(invitro_fast.R = c("pbe_fast <- function", "pbe_fast <- functioN"),
               invitro_grid.R = c("ref_true <- sigma_R > sigma_T0", "ref_true <- sigma_R >= sigma_T0"),
               platform_input.R = c("n_sim_max = 20000", "n_sim_max = 20001"))
stopped <- vapply(names(tamper), function(f) {
  r <- run_txt(sub(tamper[[f]][1], tamper[[f]][2], txt, fixed = TRUE))
  !is.null(r$error) && grepl(paste0("SHA-256 mismatch in: ", f), r$error, fixed = TRUE) &&
    !exists("run", envir = r$env, inherits = FALSE)
}, TRUE)
ind <- lapply(names(files), function(f) indep(file.path(Rdir, f)))
own <- vapply(files, pk$.fsr_sha256, "")
pin_ok <- all(own[names(pinned)[names(pinned) %in% names(own)]] == pinned[names(pinned) %in% names(own)])
ind_ok <- vapply(seq_along(ind), function(i) identical(ind[[i]]$v, unname(own[i])), TRUE)
tool <- ind[[1]]$tool
put("E-3 Bütünlük", if (tool == "yok") "EKSIK" else if (all(stopped) && pin_ok && all(ind_ok)) "GECTI" else "KALDI",
    sprintf("bozulan dosyada durdu: %d / 3; sabitlenmiş = CEKIRDEK: %s; bağımsız araç (%s) aynı: %d / %d",
            sum(stopped), pin_ok, tool, sum(ind_ok), length(ind_ok)))

# --- E-4: byte equality ---------------------------------------------------------------
tx <- sub("\nrun <- .fsr_main(params, sinir, delta, output_dir, .fsr_files, .fsr_export)\n", "\n", txt, fixed = TRUE)
e4 <- new.env(); eval(parse(text = tx, keep.source = FALSE), envir = e4)
b_ok <- vapply(names(files), function(f) identical(charToRaw(e4$.fsr_files[[f]]$text), files[[f]]), TRUE)
put("E-4 Bayt eşitliği", if (all(b_ok)) "GECTI" else "KALDI", sprintf("%d / %d dosya bayt bayt aynı", sum(b_ok), length(b_ok)))

# --- E-10: R --vanilla, package not loaded ---------------------------------------------
td <- tempfile("p3_"); dir.create(td); lib <- file.path(td, "bos_kutuphane"); dir.create(lib)
scr <- file.path(td, "betik.R")
pk$platform_export_invitro(e1_first$p, sinir = e1_first$s, dosyalar = files, cekirdek_sha = pinned, file = scr)
wr <- readLines(scr, warn = FALSE)
wr <- sub("output_dir <- \".\"", sprintf("output_dir <- \"%s\"", gsub("\\\\", "/", td)), wr, fixed = TRUE)
writeLines(c(wr, "cat('\\nE10|loaded=', 'CNKfarmastatr' %in% loadedNamespaces(), '|available=',",
             "    requireNamespace('CNKfarmastatr', quietly = TRUE), '|libs=', paste(.libPaths(), collapse = ';'), '\\n', sep = '')"),
           scr, useBytes = TRUE)
old <- Sys.getenv(c("R_LIBS", "R_LIBS_USER", "R_LIBS_SITE"), unset = NA)
Sys.setenv(R_LIBS = lib, R_LIBS_USER = lib, R_LIBS_SITE = lib)
out <- tryCatch(system2(file.path(R.home("bin"), "Rscript"), c("--vanilla", shQuote(scr)), stdout = TRUE, stderr = TRUE),
                error = function(e) conditionMessage(e))
for (k in names(old)) if (is.na(old[[k]])) Sys.unsetenv(k) else do.call(Sys.setenv, stats::setNames(list(old[[k]]), k))
tag <- grep("^E10\\|", out, value = TRUE)
csv <- list.files(td, "_sonuc\\.csv$", full.names = TRUE)
e10_same <- FALSE
if (length(csv) == 1) {
  x <- utils::read.csv(csv, colClasses = "character"); ref <- e1_first$ref
  e10_same <- all(vapply(names(ref), function(k) if (is.numeric(ref[[k]])) identical(as.numeric(x[[k]]), as.numeric(ref[[k]]))
                                                  else identical(x[[k]], as.character(ref[[k]])), TRUE))
}
loaded <- length(tag) == 1 && grepl("loaded=FALSE", tag, fixed = TRUE)
avail <- length(tag) == 1 && grepl("available=TRUE", tag, fixed = TRUE)
put("E-10 Bağımsızlık (R --vanilla)", if (length(tag) != 1) "KALDI" else if (loaded && e10_same) "GECTI" else "KALDI",
    sprintf("%s; paket yüklenmedi: %s; kütüphane yolunda kurulu: %s; sonuç (17 basamak) = E-1: %s",
            R.version.string, loaded, if (avail) "evet (sistem kütüphanesi)" else "hayır", e10_same))

# --- E-2 and E-9 (browser files) ------------------------------------------------------
jsn <- list.files(br_dir, "^farmastatr_p1_.*\\.json$", full.names = TRUE)
rsc <- list.files(br_dir, "^farmastatr_senaryo_.*\\.R$", full.names = TRUE)
num_after <- function(js, key) {                 # one number of the "result" object
  r <- substring(js, regexpr("\"result\":\\s*\\{", js))
  m <- regmatches(r, regexpr(paste0("\"", key, "\":\\s*(-?[0-9.]+([eE][-+]?[0-9]+)?|null)"), r))
  if (!length(m)) return(NA_real_)
  v <- sub(".*:\\s*", "", m); if (v == "null") NA_real_ else as.numeric(v)
}
str_of <- function(js, key) { m <- regmatches(js, regexpr(paste0("\"", key, "\":\\s*\"[^\"]*\""), js)); sub(".*:\\s*\"(.*)\"", "\\1", m) }
pairs <- list()
for (s in rsc) {
  st <- sub("^#   started: ", "", grep("^#   started: ", readLines(s, warn = FALSE, encoding = "UTF-8"), value = TRUE))
  for (j in jsn) { js <- paste(readLines(j, warn = FALSE, encoding = "UTF-8"), collapse = "")
                   if (length(st) == 1 && identical(str_of(js, "started"), st)) pairs[[length(pairs) + 1]] <- list(s = s, j = js) }
}
cnt_keys <- c("fda_pass", "fda_crit_err", "fda_cover", "ema_a_pass", "ema_a_cover", "ema_b_pass", "ema_b_cover",
              "ema_c_pass", "ema_c_cover", "ema_c_pooled_T", "ema_c_pooled_R")
e2 <- lapply(pairs, function(pp) {
  r <- run_txt(paste(readLines(pp$s, warn = FALSE, encoding = "UTF-8"), collapse = "\n"))
  if (!is.null(r$error)) return(c(ok = FALSE, cnt = NA, k = NA, n = NA))
  x <- r$env$run$result; ns <- x$n_sim
  num <- names(x)[vapply(x, is.numeric, TRUE)]
  b <- vapply(num, function(k) num_after(pp$j, k), 0)
  cd <- vapply(cnt_keys, function(k) round(x[[k]] * ns) - round(b[[k]] * ns), 0)
  kk <- K(unlist(x[num]), b)
  c(ok = TRUE, cnt = max(abs(cd)), k = sum(kk, na.rm = TRUE), n = length(kk))
})
if (length(pairs) == 0) put("E-2 Tarayıcı → betik → yerel R", "EKSIK", paste("eşleşen dosya çifti yok:", br_dir)) else {
  m <- do.call(rbind, e2)
  ok <- length(pairs) >= 3 && all(m[, "ok"] == 1) && all(m[, "cnt"] == 0) && all(m[, "k"] == m[, "n"])
  put("E-2 Tarayıcı → betik → yerel R", if (ok) "GECTI" else "KALDI",
      sprintf("%d çift; en büyük sayım farkı %s; K(1e-12, 1e-12) içinde %s / %s değer", length(pairs),
              max(m[, "cnt"]), sum(m[, "k"]), sum(m[, "n"])))
}
# E-9 (browser part): rebuild each browser script here from its own parameters and source run
e9 <- vapply(rsc, function(s) {
  b <- readLines(s, warn = FALSE, encoding = "UTF-8")
  env <- new.env(); tx <- sub("\nrun <- .fsr_main(params, sinir, delta, output_dir, .fsr_files, .fsr_export)\n", "\n",
                               paste0(paste(b, collapse = "\n"), "\n"), fixed = TRUE)
  eval(parse(text = tx, keep.source = FALSE), envir = env)
  p <- env$params; if (is.null(env$sinir)) p$delta <- env$delta
  loc <- strsplit(pk$platform_export_invitro(p, sinir = env$sinir, dosyalar = files, cekirdek_sha = pinned,
                                             kaynak = env$.fsr_export$source_run, paket_surumu = env$.fsr_export$package_version), "\n")[[1]]
  length(loc) == length(b) && identical(which(loc != b), grep("^\\.fsr_created <- ", b))
}, TRUE)
put("E-9 webR metni = yerel R metni", if (!length(rsc)) "EKSIK" else if (all(e9)) "GECTI" else "KALDI",
    sprintf("%d / %d betik zaman satırı dışında aynı", sum(e9), length(e9)))

# --- output ---------------------------------------------------------------------------
utils::write.csv(res, file.path(out_dir, "p3_kabul.csv"), row.names = FALSE, fileEncoding = "UTF-8")
writeLines(c(utils::capture.output(utils::sessionInfo()), "",
             paste("p3_kabul.R:", format(t_start, "%Y-%m-%d %H:%M:%S %z"), "-", format(Sys.time(), "%H:%M:%S"))),
           file.path(out_dir, "p3_yerel_sessionInfo.txt"))
genel <- if (any(res$sonuc == "KALDI")) "KALDI" else if (any(res$sonuc == "EKSIK")) "EKSIK" else "GECTI"
cat("\nGenel:", genel, "| yazıldı:", file.path(out_dir, "p3_kabul.csv"), "\n")
})
