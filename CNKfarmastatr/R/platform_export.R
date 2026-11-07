# =============================================================================
# CNK-FarmaStatR v1 - Platform tier 3: one in vitro scenario as a stand-alone
#   R script (FSR-TN-PLT-03 v0.1, decisions P3-K1 (b), P3-K2, P3-K3; KK-51)
#
# The script carries the five R source files that the browser loads
#   (pinned: sim_run.R, invitro_fast.R, invitro_grid.R; platform layer:
#   platform_input.R, platform_hipotez.R) as readable raw strings, verifies
#   their SHA-256 before anything else, loads them into a new environment and
#   calls the unchanged engine through platform_run_invitro(). The browser
#   run-size limit (KK-47) is not applied: running large scenarios on the
#   user's own machine is the purpose of tier 3 (FSR-TN-PLT-01 Table 3.1).
# SHA-256: FIPS 180-4 in base R; same algorithm as araclar/sha256.R 0.3.0
#   (G-05, G-44: equal to GNU sha256sum). R has no SHA-256 in base before
#   tools::sha256sum.
# FarmaStatR derivation. Base R only. Version 0.1.0
# Research and education only; not a system validated for GxP environments.
# =============================================================================

# Turkish disclaimer (escaped: package sources stay ASCII, output is UTF-8)
.platform_beyan_tr <- "Ara\u015ft\u0131rma ve e\u011fitim ama\u00e7l\u0131d\u0131r; GxP ortam\u0131nda valide edilmi\u015f sistem de\u011fildir."
.platform_beyan_en <- "For research and education; not a system validated for GxP environments."

# Non-ASCII characters as \uXXXX escapes (for R string literals in the script)
.platform_esc_u <- function(s) {
  vapply(enc2utf8(as.character(s)), function(x) {
    cp <- utf8ToInt(x)
    paste(ifelse(cp < 128, vapply(cp, intToUtf8, ""), sprintf("\\u%04x", cp)), collapse = "")
  }, "", USE.NAMES = FALSE)
}

# Files carried by the script, in loading order; TRUE = pinned (CEKIRDEK_SHA256.txt)
.platform_export_dosyalar <- c(sim_run.R = TRUE, invitro_fast.R = TRUE, invitro_grid.R = TRUE,
                               platform_input.R = FALSE, platform_hipotez.R = FALSE)

# SHA-256 kept as source text: the same lines run here and are written into the
# exported script, so the script verifies with exactly this code.
.platform_sha256_kod <- c(
  ".fsr_K <- c(",
  "  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,",
  "  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,",
  "  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,",
  "  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,",
  "  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,",
  "  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,",
  "  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,",
  "  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2)",
  ".fsr_sha256 <- function(x) {",
  "  # FIPS 180-4; 32-bit words held as doubles in [0, 2^32), bit operations on 16-bit halves",
  "  stopifnot(is.raw(x))",
  "  M <- 4294967296",
  "  xr <- function(a, b) bitwXor(a %/% 65536, b %/% 65536) * 65536 + bitwXor(a %% 65536, b %% 65536)",
  "  an <- function(a, b) bitwAnd(a %/% 65536, b %/% 65536) * 65536 + bitwAnd(a %% 65536, b %% 65536)",
  "  nt <- function(a) (M - 1) - a",
  "  rr <- function(v, k) (v %/% 2^k) + (v %% 2^k) * 2^(32 - k)",
  "  sr <- function(v, k) v %/% 2^k",
  "  n <- length(x)",
  "  b <- as.numeric(c(x, as.raw(0x80), raw((55 - n) %% 64), as.raw(rev(floor(n * 8 / 256^(0:7)) %% 256))))",
  "  W <- b[c(TRUE, FALSE, FALSE, FALSE)] * 16777216 + b[c(FALSE, TRUE, FALSE, FALSE)] * 65536 +",
  "       b[c(FALSE, FALSE, TRUE, FALSE)] * 256 + b[c(FALSE, FALSE, FALSE, TRUE)]",
  "  H <- c(0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19)",
  "  for (blk in seq_len(length(W) / 16)) {",
  "    w <- numeric(64); w[1:16] <- W[(blk - 1) * 16 + 1:16]",
  "    for (t in 17:64) {",
  "      s0 <- xr(xr(rr(w[t - 15], 7), rr(w[t - 15], 18)), sr(w[t - 15], 3))",
  "      s1 <- xr(xr(rr(w[t - 2], 17), rr(w[t - 2], 19)), sr(w[t - 2], 10))",
  "      w[t] <- (w[t - 16] + s0 + w[t - 7] + s1) %% M",
  "    }",
  "    a <- H[1]; bb <- H[2]; cc <- H[3]; d <- H[4]; e <- H[5]; f <- H[6]; g <- H[7]; h <- H[8]",
  "    for (t in 1:64) {",
  "      t1 <- (h + xr(xr(rr(e, 6), rr(e, 11)), rr(e, 25)) + xr(an(e, f), an(nt(e), g)) + .fsr_K[t] + w[t]) %% M",
  "      t2 <- (xr(xr(rr(a, 2), rr(a, 13)), rr(a, 22)) + xr(xr(an(a, bb), an(a, cc)), an(bb, cc))) %% M",
  "      h <- g; g <- f; f <- e; e <- (d + t1) %% M; d <- cc; cc <- bb; bb <- a; a <- (t1 + t2) %% M",
  "    }",
  "    H <- (H + c(a, bb, cc, d, e, f, g, h)) %% M",
  "  }",
  "  paste(sprintf(\"%08x\", as.integer(H - (H >= 2^31) * M)), collapse = \"\")",
  "}")
eval(parse(text = .platform_sha256_kod, keep.source = FALSE))

# -----------------------------------------------------------------------------
# platform_cekirdek_sha(): pinned SHA-256 values (file name -> value)
# -----------------------------------------------------------------------------
platform_cekirdek_sha <- function(path = system.file("validasyon", "CEKIRDEK_SHA256.txt",
                                                     package = "CNKfarmastatr")) {
  if (!nzchar(path) || !file.exists(path)) stop("CEKIRDEK_SHA256.txt not found.")
  x <- utils::read.table(path, header = FALSE, stringsAsFactors = FALSE, comment.char = "#",
                         col.names = c("sha256", "dosya"))
  stats::setNames(tolower(x$sha256), x$dosya)
}

# -----------------------------------------------------------------------------
# platform_motor_dosyalari(): bytes of the five source files from a folder
#   (the installed package holds no R source files; the repository does:
#   <repository>/CNKfarmastatr/R)
# -----------------------------------------------------------------------------
platform_motor_dosyalari <- function(dizin) {
  f <- file.path(dizin, names(.platform_export_dosyalar))
  miss <- f[!file.exists(f)]
  if (length(miss)) stop("Source file not found: ", paste(miss, collapse = ", "))
  stats::setNames(lapply(f, function(p) readBin(p, "raw", file.size(p))), names(.platform_export_dosyalar))
}

# -----------------------------------------------------------------------------
# platform_export_invitro(): stand-alone R script for one scenario
#   params       : named list for invitro_scenario() (n_sim and seed included);
#                  delta in params, or a boundary name in sinir
#   sinir        : "fda_delta0", "fda_minus_delta0", "ema_1.18", "ema_0.85",
#                  "gmr_1.00", "gmr_1.05" (FSR-TN-PLT-02 Section 4)
#   dosyalar     : named list of raw vectors, the five source files
#   cekirdek_sha : pinned values (platform_cekirdek_sha())
#   kaynak       : optional named list of scalars describing the source run
#                  (written into the header and the run record)
#   file         : write the script to this file (UTF-8, LF)
#   zaman        : time of export (the only line that changes between calls)
#   paket_surumu : package version written into the script (default: installed
#                  version; the browser passes the Version field of DESCRIPTION)
# Returns the script text (one string), invisibly when written to a file.
# -----------------------------------------------------------------------------
platform_export_invitro <- function(params, sinir = NULL, dosyalar, cekirdek_sha, kaynak = NULL,
                                    file = NULL, zaman = Sys.time(), paket_surumu = NULL) {
  # --- input: the browser limit is not applied (tier 3) ----------------------
  if (!is.list(params)) stop("params must be a named list.")
  if (!is.null(sinir)) {
    if (!(is.character(sinir) && length(sinir) == 1 && sinir %in% .platform_sinir_adlari))
      stop("sinir must be one of: ", paste(.platform_sinir_adlari, collapse = ", "), ".")
    if ("delta" %in% names(params)) stop("Give either delta in params or sinir, not both.")
  }
  chk <- if (is.null(sinir)) params else c(params, list(delta = 0))
  pr <- platform_check_invitro(chk, n_sim_max = Inf, cells_max = Inf)
  if (nrow(pr) > 0) {
    msg <- paste0("Invalid input:\n", paste0("- ", pr$message, collapse = "\n"))
    stop(structure(class = c("farmastat_input_error", "error", "condition"),
                   list(message = msg, call = NULL, problems = pr)))
  }
  # --- canonical parameter list (engine defaults written out) ----------------
  g <- function(k, d) if (is.null(params[[k]])) d else params[[k]]
  pB <- g("pB", 0)
  p <- list(sigma_R = params$sigma_R, rho = g("rho", 1), pB_T = g("pB_T", pB), pB_R = g("pB_R", pB),
            pL = g("pL", 0.15), q = g("q", 0), l = g("l", 3), n = g("n", 10), m = g("m", 3),
            n_sim = g("n_sim", 10000), seed = g("seed", 20261015), alpha = g("alpha", 0.05),
            sigma_T0 = g("sigma_T0", 0.1), ema_limits = g("ema_limits", c(0.85, 1.18)))
  if (isTRUE(params$keep_reps)) p$keep_reps <- TRUE
  if (is.null(sinir)) {
    d <- params$delta
    if (is.null(d)) d <- 0
  }
  if (!is.null(sinir) && sinir %in% c("fda_delta0", "fda_minus_delta0") &&
      is.na(.platform_delta0(p$sigma_R, p$rho, p$sigma_T0)))
    stop("FDA delta0 is not defined for these sigma_R and rho (eta > 0 at delta = 0).")

  # --- source files: names, pinned values -----------------------------------
  need <- names(.platform_export_dosyalar)
  if (!is.list(dosyalar) || !all(need %in% names(dosyalar)))
    stop("dosyalar must hold: ", paste(need, collapse = ", "), ".")
  sha <- vapply(need, function(f) { b <- dosyalar[[f]]; if (!is.raw(b)) stop(f, " must be raw.")
                                    .fsr_sha256(b) }, "")
  for (f in need[.platform_export_dosyalar]) {
    if (is.na(cekirdek_sha[f])) stop(f, " is not in the pinned list.")
    if (!identical(sha[[f]], unname(cekirdek_sha[f])))
      stop("SHA-256 of ", f, " differs from CEKIRDEK_SHA256.txt; no script was written.")
  }
  if (any(vapply(need, function(f) any(dosyalar[[f]] == as.raw(13)), TRUE)))
    stop("Source files must have LF line ends.")

  # --- script text ------------------------------------------------------------
  pv <- if (!is.null(paket_surumu)) as.character(paket_surumu) else
    tryCatch(as.character(utils::packageVersion("CNKfarmastatr")), error = function(e) "source")
  cells <- p$l * p$n * p$m * p$n_sim
  if (!is.null(kaynak) && (!is.list(kaynak) || is.null(names(kaynak)) || any(!nzchar(names(kaynak)))))
    stop("kaynak must be a named list.")
  kv <- if (is.null(kaynak)) character(0) else
    .platform_esc_u(gsub("[\r\n]", " ", vapply(kaynak, function(v) paste(unlist(v), collapse = " "), "")))
  src <- if (is.null(kaynak)) "#   (none: exported without a run)" else
    paste0("#   ", .platform_esc_u(names(kaynak)), ": ", kv)
  pl <- vapply(names(p), function(k) sprintf("  %s = %s", k, .r_value(p[[k]])), "")
  pl[-length(pl)] <- paste0(pl[-length(pl)], ",")
  # regulatory constants in a block of their own (FSR-TN-PLT-15, KK-83): the run record is unchanged
  ia <- which(names(p) == "alpha")
  pl <- c(pl[seq_len(ia - 1)],
          "  # -- regulatory constants: values of the guidelines, not settings of the scenario --",
          "  #    alpha    : one-sided level, FDA 95% upper confidence bound (PSG 020929 App. A, Step 4)",
          "  #    sigma_T0 : FDA regulatory constant, the scaling threshold (PSG 020929 App. A, Steps 1",
          "  #               and 3); NOT the SD of the test product (that is rho * sigma_R).",
          "  #               theta_p = ((log(1.11))^2 + 0.01) / sigma_T0^2 = 2.0891 is computed from it",
          "  #    ema_limits: EMA acceptance limits of the 90% CI of the GMR (CPMP/EWP/4151/00 Rev. 2, 5.1)",
          "  #    Change them only to study the method: the result is then not the guideline's criterion.",
          pl[ia:length(pl)])
  delim <- "---"
  has_end <- function(d) any(vapply(need, function(f)
    grepl(paste0(")", d, "\""), rawToChar(dosyalar[[f]]), fixed = TRUE, useBytes = TRUE), TRUE))
  while (has_end(delim)) delim <- paste0(delim, "-")
  kay <- if (is.null(kaynak)) "NULL" else
    paste0("list(", paste(sprintf("%s = %s", .platform_esc_u(vapply(names(kaynak), .json_str, "")),
                                  .platform_esc_u(vapply(kaynak, function(v) .r_value(if (is.list(v)) unlist(v) else v), ""))),
                          collapse = ", "), ")")

  out <- c(
    "# =============================================================================",
    "# CNK-FarmaStatR - in vitro esdegerlik senaryosu / in vitro equivalence scenario",
    paste("#", .platform_beyan_tr),
    paste("#", .platform_beyan_en),
    "# -----------------------------------------------------------------------------",
    sprintf("# Exported by: platform_export_invitro 0.1.0, CNKfarmastatr %s (time: .fsr_created below)", pv),
    "# Document   : FSR-TN-PLT-03 (P3, tier 3: stand-alone R script)",
    "# Requires   : R >= 4.0 and base R only; CNKfarmastatr need not be installed",
    "# Use        : Rscript <this file>      or      source(\"<this file>\")",
    "# Source run :",
    src,
    "# Engine     : FDA PBE (PSG 020929) and EMA OIP Rev. 2 Section 5.1 criterion 8,",
    "#              methods (a), (b), (c); invitro_scenario() unchanged (FSR-VAL-SIM-1)",
    "# =============================================================================",
    sprintf(".fsr_created <- %s   # time of export", .json_str(format(zaman, "%Y-%m-%d %H:%M:%S %z"))),
    "",
    "# ---- 1. Parameters: you may change these --------------------------------------",
    "params <- list(",
    pl,
    ")",
    sprintf("sinir <- %s   # boundary name: fda_delta0, fda_minus_delta0, ema_1.18, ema_0.85,",
            if (is.null(sinir)) "NULL" else .json_str(sinir)),
    "#                gmr_1.00, gmr_1.05; NULL = use delta below",
    sprintf("delta <- %s   # true mean difference mu_T - mu_R, log scale (used when sinir is NULL)",
            if (is.null(sinir)) .r_value(d) else "NULL"),
    "output_dir <- \".\"   # result (.csv) and run record (.json) are written here; NULL = no files",
    "",
    "# ---- 2. Size: information only ------------------------------------------------",
    sprintf("# l * n * m * n_sim = %s cells as exported. For orientation: the browser",
            format(cells, big.mark = ",", scientific = FALSE)),
    "# prototype needed about 688 MB for 8.1 million cells (P1, decision KK-47). Local R",
    "# may differ; no limit is applied. Replicates are not split into chunks, because",
    "# splitting would change the random number stream and the result.",
    "",
    "# ---- 3. Program: do not change ------------------------------------------------",
    sprintf(".fsr_export <- list(created = .fsr_created, package_version = %s, source_run = %s,",
            .json_str(pv), kay),
    sprintf("                    disclaimer_tr = \"%s\",", .platform_esc_u(.platform_beyan_tr)),
    sprintf("                    disclaimer_en = \"%s\")", .platform_beyan_en),
    .platform_sha256_kod,
    .platform_script_main,
    "",
    "# ---- 4. Embedded source files: do not change (verified by SHA-256) -------------",
    ".fsr_files <- list(")
  tail_txt <- c(")", "", "run <- .fsr_main(params, sinir, delta, output_dir, .fsr_files, .fsr_export)")
  u <- function(x) charToRaw(enc2utf8(paste0(paste(x, collapse = "\n"), "\n")))
  emb <- lapply(need, function(f) c(
    charToRaw(sprintf("  %s = list(pinned = %s, sha256 = \"%s\", text = r\"%s(",
                      .json_str(f), if (.platform_export_dosyalar[[f]]) "TRUE" else "FALSE", sha[[f]], delim)),
    dosyalar[[f]], charToRaw(paste0(")", delim, "\")", if (f == need[length(need)]) "" else ",", "\n"))))
  bytes <- c(u(out), unlist(emb), u(tail_txt))
  if (!is.null(file)) {
    con <- file(file, "wb"); on.exit(close(con))
    writeBin(bytes, con)
  }
  res <- rawToChar(bytes); Encoding(res) <- "UTF-8"
  if (!is.null(file)) invisible(res) else res
}

# Main program of the exported script (written as text into the script)
.platform_script_main <- c(
  ".fsr_main <- function(params, sinir, delta, output_dir, files, info) {",
  "  t0 <- proc.time()[[\"elapsed\"]]",
  "  started <- format(Sys.time(), \"%Y-%m-%d %H:%M:%S %z\")",
  "  # 3a. verify every embedded file before anything is computed",
  "  got <- vapply(files, function(f) .fsr_sha256(charToRaw(gsub(\"\\r\\n\", \"\\n\", f$text, fixed = TRUE))), \"\")",
  "  bad <- names(files)[got != vapply(files, function(f) f$sha256, \"\")]",
  "  if (length(bad)) stop(\"SHA-256 mismatch in: \", paste(bad, collapse = \", \"),",
  "                        \". The file was changed (or re-encoded by an editor); nothing was computed.\", call. = FALSE)",
  "  cat(\"SHA-256 verified:\", paste(names(files), collapse = \", \"), \"\\n\")",
  "  # 3b. load into a new environment (the workspace is not changed)",
  "  env <- new.env(parent = globalenv())",
  "  for (f in files) eval(parse(text = gsub(\"\\r\\n\", \"\\n\", f$text, fixed = TRUE), keep.source = FALSE), envir = env)",
  "  # 3c. delta from the boundary name, input check (browser limit not applied), run",
  "  if (!is.null(sinir)) {",
  "    delta <- env$platform_sinir_delta(sinir, params$sigma_R, params$rho, params$sigma_T0, params$ema_limits)",
  "    if (is.na(delta)) stop(\"FDA delta0 is not defined for these sigma_R and rho.\", call. = FALSE)",
  "  }",
  "  p <- c(params, list(delta = delta))",
  "  pr <- env$platform_check_invitro(p, n_sim_max = Inf, cells_max = Inf)",
  "  if (nrow(pr) > 0) stop(\"Invalid input:\\n\", paste0(\"- \", pr$message, collapse = \"\\n\"), call. = FALSE)",
  "  cat(sprintf(\"Running: l * n * m * n_sim = %s cells ...\\n\", format(p$l * p$n * p$m * p$n_sim, big.mark = \",\", scientific = FALSE)))",
  "  res <- env$platform_run_invitro(p, n_sim_max = Inf, cells_max = Inf)",
  "  rng <- RNGkind()[1:2]",
  "  secs <- proc.time()[[\"elapsed\"]] - t0",
  "  # 3d. summary: rates with Monte Carlo SE, hypothesis class, metric, KK-38 label",
  "  h <- if (is.null(sinir)) env$platform_hipotez(params$sigma_R, params$rho, delta = delta,",
  "                                                sigma_T0 = params$sigma_T0, ema_limits = params$ema_limits) else",
  "    env$platform_hipotez(params$sigma_R, params$rho, sinir = sinir, sigma_T0 = params$sigma_T0, ema_limits = params$ema_limits)",
  "  me <- c(\"fda\", \"ema_a\", \"ema_b\", \"ema_c\")",
  "  rate <- unlist(res[paste0(me, \"_pass\")]); se <- unlist(res[paste0(me, \"_pass_mcse\")])",
  "  cls <- h$sinif[match(me, h$yontem)]",
  "  tab <- data.frame(method = me, pass_rate = unname(rate), mcse = unname(se), class = cls,",
  "                    metric = h$metrik[match(me, h$yontem)],",
  "                    kk38 = env$platform_kk38(unname(rate), unname(se), cls, nominal = params$alpha),",
  "                    near_boundary = h$yakinlik_uyarisi[match(me, h$yontem)], stringsAsFactors = FALSE)",
  "  key_args <- c(params[c(\"sigma_R\", \"rho\", \"pB_T\", \"pB_R\", \"pL\", \"q\", \"l\", \"n\", \"m\", \"n_sim\", \"seed\")],",
  "                if (is.null(sinir)) list(delta = delta) else list(sinir = sinir))",
  "  scen_key <- do.call(env$platform_anahtar, key_args)",
  "  run_key <- do.call(env$platform_anahtar, c(key_args, list(kosu = TRUE)))",
  "  cat(\"\\nScenario:\", scen_key, \"\\n\")",
  "  cat(sprintf(\"n_sim = %s, seed = %s, RNG %s; %.1f s\\n\\n\", format(params$n_sim, big.mark = \",\"), params$seed,",
  "              paste(rng, collapse = \"/\"), secs))",
  "  print(transform(tab, pass_rate = formatC(pass_rate, digits = 4, format = \"f\"),",
  "                  mcse = formatC(mcse, digits = 4, format = \"f\")), row.names = FALSE)",
  "  cat(\"\\n\", info$disclaimer_tr, \"\\n\", info$disclaimer_en, \"\\n\", sep = \"\")",
  "  # 3e. files: result with exact numbers, run record (JSON)",
  "  stamp <- format(Sys.time(), \"%Y%m%d-%H%M%S\")",
  "  rec <- list(run_id = paste0(\"script-\", stamp), platform = \"CNK-FarmaStatR\",",
  "              document = \"FSR-TN-PLT-03\", result_source = \"script\",",
  "              disclaimer_tr = info$disclaimer_tr, disclaimer_en = info$disclaimer_en,",
  "              exported = info$created, package_version = info$package_version, started = started,",
  "              seconds = secs, r_version = R.version.string, r_platform = R.version$platform,",
  "              rng = rng, seed = params$seed, n_sim = params$n_sim, params = p, sinir = sinir,",
  "              scenario_key = scen_key, run_key = run_key,",
  "              files = lapply(names(files), function(k) list(file = k, pinned = files[[k]]$pinned,",
  "                                                            sha256 = files[[k]]$sha256, verified = TRUE)),",
  "              source_run = info$source_run, summary = tab, result = as.list(res))",
  "  if (!is.null(output_dir)) {",
  "    num <- vapply(res, function(v) if (is.numeric(v)) env$.num_exact(v) else as.character(v), \"\")",
  "    f_csv <- file.path(output_dir, paste0(\"farmastatr_\", stamp, \"_sonuc.csv\"))",
  "    f_js <- file.path(output_dir, paste0(\"farmastatr_\", stamp, \"_kayit.json\"))",
  "    writeLines(c(paste(names(res), collapse = \",\"), paste(num, collapse = \",\")), f_csv, useBytes = TRUE)",
  "    writeLines(env$.to_json(rec), f_js, useBytes = TRUE)",
  "    cat(\"Written:\", f_csv, \"and\", f_js, \"\\n\")",
  "  }",
  "  invisible(list(result = res, summary = tab, record = rec))",
  "}")
