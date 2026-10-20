# =============================================================================
# CNK-FarmaStatR - in vitro esdegerlik senaryosu / in vitro equivalence scenario
# Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.
# For research and education; not a system validated for GxP environments.
# -----------------------------------------------------------------------------
# Exported by: platform_export_invitro 0.1.0, CNKfarmastatr 1.0.0.9000 (time: .fsr_created below)
# Document   : FSR-TN-PLT-03 (P3, tier 3: stand-alone R script)
# Requires   : R >= 4.0 and base R only; CNKfarmastatr need not be installed
# Use        : Rscript <this file>      or      source("<this file>")
# Source run :
#   (none: exported without a run)
# Engine     : FDA PBE (PSG 020929) and EMA OIP Rev. 2 Section 5.1 criterion 8,
#              methods (a), (b), (c); invitro_scenario() unchanged (FSR-VAL-SIM-1)
# =============================================================================
.fsr_created <- "2026-10-20 15:20:20 +0300"   # time of export

# ---- 1. Parameters: you may change these --------------------------------------
params <- list(
  sigma_R = 0.13,
  rho = 1,
  pB_T = 0,
  pB_R = 0,
  pL = 0.15,
  q = 0,
  l = 6,
  n = 30,
  m = 3,
  n_sim = 50000,
  seed = 20261015,
  alpha = 0.05,
  sigma_T0 = 0.1,
  ema_limits = c(0.85, 1.18)
)
sinir <- "gmr_1.05"   # boundary name: fda_delta0, fda_minus_delta0, ema_1.18, ema_0.85,
#                gmr_1.00, gmr_1.05; NULL = use delta below
delta <- NULL   # true mean difference mu_T - mu_R, log scale (used when sinir is NULL)
output_dir <- "."   # result (.csv) and run record (.json) are written here; NULL = no files

# ---- 2. Size: information only ------------------------------------------------
# l * n * m * n_sim = 27,000,000 cells as exported. For orientation: the browser
# prototype needed about 688 MB for 8.1 million cells (P1, decision KK-47). Local R
# may differ; no limit is applied. Replicates are not split into chunks, because
# splitting would change the random number stream and the result.

# ---- 3. Program: do not change ------------------------------------------------
.fsr_export <- list(created = .fsr_created, package_version = "1.0.0.9000", source_run = NULL,
                    disclaimer_tr = "Ara\u015ft\u0131rma ve e\u011fitim ama\u00e7l\u0131d\u0131r; GxP ortam\u0131nda valide edilmi\u015f sistem de\u011fildir.",
                    disclaimer_en = "For research and education; not a system validated for GxP environments.")
.fsr_K <- c(
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2)
.fsr_sha256 <- function(x) {
  # FIPS 180-4; 32-bit words held as doubles in [0, 2^32), bit operations on 16-bit halves
  stopifnot(is.raw(x))
  M <- 4294967296
  xr <- function(a, b) bitwXor(a %/% 65536, b %/% 65536) * 65536 + bitwXor(a %% 65536, b %% 65536)
  an <- function(a, b) bitwAnd(a %/% 65536, b %/% 65536) * 65536 + bitwAnd(a %% 65536, b %% 65536)
  nt <- function(a) (M - 1) - a
  rr <- function(v, k) (v %/% 2^k) + (v %% 2^k) * 2^(32 - k)
  sr <- function(v, k) v %/% 2^k
  n <- length(x)
  b <- as.numeric(c(x, as.raw(0x80), raw((55 - n) %% 64), as.raw(rev(floor(n * 8 / 256^(0:7)) %% 256))))
  W <- b[c(TRUE, FALSE, FALSE, FALSE)] * 16777216 + b[c(FALSE, TRUE, FALSE, FALSE)] * 65536 +
       b[c(FALSE, FALSE, TRUE, FALSE)] * 256 + b[c(FALSE, FALSE, FALSE, TRUE)]
  H <- c(0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19)
  for (blk in seq_len(length(W) / 16)) {
    w <- numeric(64); w[1:16] <- W[(blk - 1) * 16 + 1:16]
    for (t in 17:64) {
      s0 <- xr(xr(rr(w[t - 15], 7), rr(w[t - 15], 18)), sr(w[t - 15], 3))
      s1 <- xr(xr(rr(w[t - 2], 17), rr(w[t - 2], 19)), sr(w[t - 2], 10))
      w[t] <- (w[t - 16] + s0 + w[t - 7] + s1) %% M
    }
    a <- H[1]; bb <- H[2]; cc <- H[3]; d <- H[4]; e <- H[5]; f <- H[6]; g <- H[7]; h <- H[8]
    for (t in 1:64) {
      t1 <- (h + xr(xr(rr(e, 6), rr(e, 11)), rr(e, 25)) + xr(an(e, f), an(nt(e), g)) + .fsr_K[t] + w[t]) %% M
      t2 <- (xr(xr(rr(a, 2), rr(a, 13)), rr(a, 22)) + xr(xr(an(a, bb), an(a, cc)), an(bb, cc))) %% M
      h <- g; g <- f; f <- e; e <- (d + t1) %% M; d <- cc; cc <- bb; bb <- a; a <- (t1 + t2) %% M
    }
    H <- (H + c(a, bb, cc, d, e, f, g, h)) %% M
  }
  paste(sprintf("%08x", as.integer(H - (H >= 2^31) * M)), collapse = "")
}
.fsr_main <- function(params, sinir, delta, output_dir, files, info) {
  t0 <- proc.time()[["elapsed"]]
  started <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")
  # 3a. verify every embedded file before anything is computed
  got <- vapply(files, function(f) .fsr_sha256(charToRaw(gsub("\r\n", "\n", f$text, fixed = TRUE))), "")
  bad <- names(files)[got != vapply(files, function(f) f$sha256, "")]
  if (length(bad)) stop("SHA-256 mismatch in: ", paste(bad, collapse = ", "),
                        ". The file was changed (or re-encoded by an editor); nothing was computed.", call. = FALSE)
  cat("SHA-256 verified:", paste(names(files), collapse = ", "), "\n")
  # 3b. load into a new environment (the workspace is not changed)
  env <- new.env(parent = globalenv())
  for (f in files) eval(parse(text = gsub("\r\n", "\n", f$text, fixed = TRUE), keep.source = FALSE), envir = env)
  # 3c. delta from the boundary name, input check (browser limit not applied), run
  if (!is.null(sinir)) {
    delta <- env$platform_sinir_delta(sinir, params$sigma_R, params$rho, params$sigma_T0, params$ema_limits)
    if (is.na(delta)) stop("FDA delta0 is not defined for these sigma_R and rho.", call. = FALSE)
  }
  p <- c(params, list(delta = delta))
  pr <- env$platform_check_invitro(p, n_sim_max = Inf, cells_max = Inf)
  if (nrow(pr) > 0) stop("Invalid input:\n", paste0("- ", pr$message, collapse = "\n"), call. = FALSE)
  cat(sprintf("Running: l * n * m * n_sim = %s cells ...\n", format(p$l * p$n * p$m * p$n_sim, big.mark = ",", scientific = FALSE)))
  res <- env$platform_run_invitro(p, n_sim_max = Inf, cells_max = Inf)
  rng <- RNGkind()[1:2]
  secs <- proc.time()[["elapsed"]] - t0
  # 3d. summary: rates with Monte Carlo SE, hypothesis class, metric, KK-38 label
  h <- if (is.null(sinir)) env$platform_hipotez(params$sigma_R, params$rho, delta = delta,
                                                sigma_T0 = params$sigma_T0, ema_limits = params$ema_limits) else
    env$platform_hipotez(params$sigma_R, params$rho, sinir = sinir, sigma_T0 = params$sigma_T0, ema_limits = params$ema_limits)
  me <- c("fda", "ema_a", "ema_b", "ema_c")
  rate <- unlist(res[paste0(me, "_pass")]); se <- unlist(res[paste0(me, "_pass_mcse")])
  cls <- h$sinif[match(me, h$yontem)]
  tab <- data.frame(method = me, pass_rate = unname(rate), mcse = unname(se), class = cls,
                    metric = h$metrik[match(me, h$yontem)],
                    kk38 = env$platform_kk38(unname(rate), unname(se), cls, nominal = params$alpha),
                    near_boundary = h$yakinlik_uyarisi[match(me, h$yontem)], stringsAsFactors = FALSE)
  key_args <- c(params[c("sigma_R", "rho", "pB_T", "pB_R", "pL", "q", "l", "n", "m", "n_sim", "seed")],
                if (is.null(sinir)) list(delta = delta) else list(sinir = sinir))
  scen_key <- do.call(env$platform_anahtar, key_args)
  run_key <- do.call(env$platform_anahtar, c(key_args, list(kosu = TRUE)))
  cat("\nScenario:", scen_key, "\n")
  cat(sprintf("n_sim = %s, seed = %s, RNG %s; %.1f s\n\n", format(params$n_sim, big.mark = ","), params$seed,
              paste(rng, collapse = "/"), secs))
  print(transform(tab, pass_rate = formatC(pass_rate, digits = 4, format = "f"),
                  mcse = formatC(mcse, digits = 4, format = "f")), row.names = FALSE)
  cat("\n", info$disclaimer_tr, "\n", info$disclaimer_en, "\n", sep = "")
  # 3e. files: result with exact numbers, run record (JSON)
  stamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
  rec <- list(run_id = paste0("script-", stamp), platform = "CNK-FarmaStatR",
              document = "FSR-TN-PLT-03", result_source = "script",
              disclaimer_tr = info$disclaimer_tr, disclaimer_en = info$disclaimer_en,
              exported = info$created, package_version = info$package_version, started = started,
              seconds = secs, r_version = R.version.string, r_platform = R.version$platform,
              rng = rng, seed = params$seed, n_sim = params$n_sim, params = p, sinir = sinir,
              scenario_key = scen_key, run_key = run_key,
              files = lapply(names(files), function(k) list(file = k, pinned = files[[k]]$pinned,
                                                            sha256 = files[[k]]$sha256, verified = TRUE)),
              source_run = info$source_run, summary = tab, result = as.list(res))
  if (!is.null(output_dir)) {
    num <- vapply(res, function(v) if (is.numeric(v)) env$.num_exact(v) else as.character(v), "")
    f_csv <- file.path(output_dir, paste0("farmastatr_", stamp, "_sonuc.csv"))
    f_js <- file.path(output_dir, paste0("farmastatr_", stamp, "_kayit.json"))
    writeLines(c(paste(names(res), collapse = ","), paste(num, collapse = ",")), f_csv, useBytes = TRUE)
    writeLines(env$.to_json(rec), f_js, useBytes = TRUE)
    cat("Written:", f_csv, "and", f_js, "\n")
  }
  invisible(list(result = res, summary = tab, record = rec))
}

# ---- 4. Embedded source files: do not change (verified by SHA-256) -------------
.fsr_files <- list(
  "sim_run.R" = list(pinned = TRUE, sha256 = "e45b2d3230ff7a6095fc8a9f3ab3ff80ddabda53ef1ea802df4394b035390cd2", text = r"---(# =============================================================================
# CNK-FarmaStatR v1 - Simulation framework - Scenarios, runner, run record
#
# Design framework: ADEMP (Aims, Data-generating mechanisms, Estimands,
#   Methods, Performance measures); Morris TP, White IR, Crowther MJ.
#   Stat Med 2019;38:2074-2102.
# Project rules (project instructions, "Simulasyon Ilkeleri"):
#   - every parameter can be set by the user (defaults = the publication's values)
#   - every result carries its Monte Carlo standard error
#   - every run records parameters, seed, RNG kind, R and package versions
#   - a run can be reproduced from its record (JSON) or exported as an R script
# Base R only. Version 0.1.0
# =============================================================================

.sim_registry <- new.env(parent = emptyenv())

# -----------------------------------------------------------------------------
# sim_scenario(): defines a simulation scenario in ADEMP terms
#   id         : short identifier, used in records, URLs and exported scripts
#   dgm        : function(params) returning one simulated data set
#   methods    : named list of function(data, params); each returns a named
#                numeric vector with any of: est, se, lower, upper, p, reject
#   truth      : value of the estimand, or function(params) returning it
#   params     : named list of default parameters (the publication's values)
#   aim, estimand, dgm_text : plain-text ADEMP description
#   param_text : named character vector describing each parameter
#   check      : optional function(params) that stops on invalid parameters
# -----------------------------------------------------------------------------
sim_scenario <- function(id, title, aim, dgm, dgm_text, estimand, truth,
                         methods, params, param_text = NULL, check = NULL,
                         references = character(0), version = "0.1.0") {
  stopifnot(is.character(id), length(id) == 1, grepl("^[A-Za-z0-9_]+$", id),
            is.function(dgm), is.list(methods), length(methods) >= 1,
            !is.null(names(methods)), all(vapply(methods, is.function, TRUE)),
            is.list(params), !is.null(names(params)) || length(params) == 0)
  structure(list(id = id, title = title, version = version, aim = aim,
                 dgm = dgm, dgm_text = dgm_text, estimand = estimand, truth = truth,
                 methods = methods, params = params, param_text = param_text,
                 check = check, references = references),
            class = "farmastat_scenario")
}

sim_register <- function(scenario) {
  stopifnot(inherits(scenario, "farmastat_scenario"))
  assign(scenario$id, scenario, envir = .sim_registry)
  invisible(scenario$id)
}

sim_get <- function(id) {
  if (inherits(id, "farmastat_scenario")) return(id)
  if (!exists(id, envir = .sim_registry, inherits = FALSE))
    stop(sprintf("Unknown scenario '%s'. Available: %s", id,
                 paste(sort(ls(.sim_registry)), collapse = ", ")))
  get(id, envir = .sim_registry)
}

sim_scenarios <- function() {
  ids <- sort(ls(.sim_registry))
  data.frame(id = ids,
             title = vapply(ids, function(i) get(i, envir = .sim_registry)$title, ""),
             version = vapply(ids, function(i) get(i, envir = .sim_registry)$version, ""),
             row.names = NULL, stringsAsFactors = FALSE)
}

# Defaults overridden by user values; unknown names are an error
.sim_params <- function(scn, params) {
  bad <- setdiff(names(params), names(scn$params))
  if (length(bad)) stop(sprintf("Unknown parameter(s) for '%s': %s. Valid: %s",
                                scn$id, paste(bad, collapse = ", "),
                                paste(names(scn$params), collapse = ", ")))
  p <- scn$params; p[names(params)] <- params
  if (!is.null(scn$check)) scn$check(p)
  p
}

.sim_fields <- c("est", "se", "lower", "upper", "p", "reject")

# -----------------------------------------------------------------------------
# sim_run(): runs a scenario n_sim times
#   One random number stream: RNGkind is fixed and recorded, set.seed(seed)
#   once. The caller's RNG kind and state are restored afterwards.
#   Errors in data generation or in a method are caught, stored per replicate
#   and counted; they never stop the run.
#   keep_states = TRUE stores the RNG state at the start of each replicate, so
#   that a single replicate can be regenerated (sim_replicate).
# -----------------------------------------------------------------------------
sim_run <- function(scenario, params = list(), n_sim = 1000, seed = 1,
                    alpha = 0.05, keep_states = FALSE) {
  scn <- sim_get(scenario)
  n_sim <- as.integer(n_sim)
  if (is.na(n_sim) || n_sim < 2) stop("n_sim must be at least 2.")
  if (!is.numeric(seed) || length(seed) != 1 || !is.finite(seed)) stop("seed must be one number.")
  p <- .sim_params(scn, params)
  truth <- if (is.function(scn$truth)) scn$truth(p) else scn$truth

  # --- RNG: fixed kind, single stream, caller's state restored on exit -------
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  old_seed <- if (had_seed) get(".Random.seed", envir = globalenv()) else NULL
  on.exit({
    RNGkind(old_kind[1], old_kind[2], old_kind[3])
    if (had_seed) assign(".Random.seed", old_seed, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE))
      rm(".Random.seed", envir = globalenv())
  }, add = TRUE)
  suppressWarnings(RNGkind("Mersenne-Twister", "Inversion", "Rejection"))
  set.seed(seed)
  rng <- RNGkind()

  m_names <- names(scn$methods); M <- length(m_names)
  res <- matrix(NA_real_, n_sim * M, length(.sim_fields),
                dimnames = list(NULL, .sim_fields))
  err <- rep(NA_character_, n_sim * M)
  states <- if (keep_states) vector("list", n_sim) else NULL

  t0 <- Sys.time()
  for (i in seq_len(n_sim)) {
    if (keep_states) states[[i]] <- get(".Random.seed", envir = globalenv())
    rows <- (i - 1) * M + seq_len(M)
    dat <- tryCatch(scn$dgm(p), error = function(e) e)
    if (inherits(dat, "error")) { err[rows] <- paste("dgm:", conditionMessage(dat)); next }
    for (j in seq_len(M)) {
      r <- tryCatch(scn$methods[[j]](dat, p), error = function(e) e)
      if (inherits(r, "error")) { err[rows[j]] <- conditionMessage(r); next }
      k <- intersect(names(r), .sim_fields)
      res[rows[j], k] <- as.numeric(r[k])
    }
  }
  t1 <- Sys.time()

  raw <- data.frame(rep = rep(seq_len(n_sim), each = M),
                    method = rep(m_names, times = n_sim),
                    res, error = err, stringsAsFactors = FALSE)

  perf <- do.call(rbind, lapply(m_names, function(m) {
    d <- raw[raw$method == m & is.na(raw$error), ]
    has <- function(f) any(!is.na(d[[f]]))
    tab <- sim_performance(
      est   = if (has("est")) d$est else NULL, truth = truth,
      se    = if (has("se")) d$se else NULL,
      lower = if (has("lower")) d$lower else NULL,
      upper = if (has("upper")) d$upper else NULL,
      p     = if (has("p")) d$p else NULL,
      reject = if (has("reject")) as.logical(d$reject) else NULL,
      alpha = alpha)
    if (nrow(tab)) cbind(method = m, tab, stringsAsFactors = FALSE) else NULL
  }))
  rownames(perf) <- NULL
  failed <- vapply(m_names, function(m) sum(!is.na(raw$error[raw$method == m])), 0L)

  record <- list(
    platform     = "CNK-FarmaStatR",
    disclaimer   = "Research and education only; not a validated system for GxP environments.",
    scenario     = scn$id, scenario_version = scn$version, title = scn$title,
    ademp        = list(aim = scn$aim, data_generating = scn$dgm_text,
                        estimand = scn$estimand, truth = truth,
                        methods = m_names,
                        performance = unique(perf$measure)),
    params       = p,
    n_sim        = n_sim, seed = seed, alpha = alpha,
    rng_kind     = rng,
    r_version    = R.version$version.string,
    package      = "CNKfarmastatr",
    package_version = as.character(utils::packageVersion("CNKfarmastatr")),
    os           = R.version$platform,
    started      = format(t0, "%Y-%m-%dT%H:%M:%S%z"),
    seconds      = round(as.numeric(difftime(t1, t0, units = "secs")), 3),
    failed       = as.list(failed),
    references   = scn$references)

  structure(list(record = record, performance = perf, raw = raw, states = states),
            class = "farmastat_sim")
}

# Regenerates the data set of replicate i (needs keep_states = TRUE)
sim_replicate <- function(x, i) {
  stopifnot(inherits(x, "farmastat_sim"))
  if (is.null(x$states)) stop("Run sim_run(..., keep_states = TRUE) to regenerate replicates.")
  scn <- sim_get(x$record$scenario)
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  old_seed <- if (had_seed) get(".Random.seed", envir = globalenv()) else NULL
  on.exit({
    RNGkind(old_kind[1], old_kind[2], old_kind[3])
    if (had_seed) assign(".Random.seed", old_seed, envir = globalenv())
  }, add = TRUE)
  suppressWarnings(RNGkind("Mersenne-Twister", "Inversion", "Rejection"))
  assign(".Random.seed", x$states[[i]], envir = globalenv())
  scn$dgm(x$record$params)
}

print.farmastat_sim <- function(x, digits = 4, ...) {
  r <- x$record
  cat(sprintf("\n== CNK-FarmaStatR simulation: %s (%s v%s) ==\n", r$title, r$scenario, r$scenario_version))
  cat("Parameters:", paste(sprintf("%s = %s", names(r$params),
      vapply(r$params, function(v) paste(format(v), collapse = ","), "")), collapse = "; "), "\n")
  cat(sprintf("n_sim = %d, seed = %s, RNG = %s, alpha = %g\n", r$n_sim, format(r$seed),
              paste(r$rng_kind, collapse = " / "), r$alpha))
  cat(sprintf("Estimand: %s (true value %s)\n", r$ademp$estimand, format(r$ademp$truth, digits = 8)))
  f <- function(v) formatC(v, digits = digits, format = "f")
  cat("\nPerformance (estimate and Monte Carlo SE):\n")
  pt <- x$performance
  print(data.frame(method = pt$method, measure = pt$measure,
                   estimate = f(pt$estimate), MCSE = f(pt$mcse)), row.names = FALSE)
  if (any(unlist(r$failed) > 0))
    cat("\nFailed replicates:", paste(sprintf("%s %d", names(r$failed), unlist(r$failed)), collapse = ", "), "\n")
  cat(sprintf("\n%s, %s - %s %s - %.1f s\n", r$r_version, r$os, r$package, r$package_version, r$seconds))
  cat(r$disclaimer, "\n")
  invisible(x)
}

# Shortest decimal text (15-17 significant digits) that reads back to exactly
# the same double
.num_exact <- function(x) {
  vapply(x, function(v) {
    if (!is.finite(v)) return(as.character(v))
    for (d in 15:17) { s <- sprintf(paste0("%.", d, "g"), v); if (as.numeric(s) == v) return(s) }
    s
  }, "")
}

# R code for a scalar or vector parameter value (exact numbers)
.r_value <- function(v) {
  if (is.null(v)) return("NULL")
  val <- if (is.character(v)) ifelse(is.na(v), "NA_character_", .json_str(v))
         else if (is.logical(v)) ifelse(is.na(v), "NA", ifelse(v, "TRUE", "FALSE"))
         else if (is.integer(v)) ifelse(is.na(v), "NA_integer_", paste0(v, "L"))
         else if (is.numeric(v)) ifelse(is.na(v), "NA_real_", .num_exact(v))
         else stop("Unsupported parameter type: ", class(v)[1])
  if (length(val) == 1) val else paste0("c(", paste(val, collapse = ", "), ")")
}

.r_list <- function(l) {
  if (!length(l)) return("list()")
  paste0("list(", paste(sprintf("%s = %s", names(l), vapply(l, .r_value, "")), collapse = ", "), ")")
}

# -----------------------------------------------------------------------------
# Run record as JSON (base R writer). Numbers are written with the shortest
# decimal text that reproduces the double exactly. Vectors of length 1 are written
# as scalars. include_raw = TRUE adds the replicate-level results.
# -----------------------------------------------------------------------------
.json_str <- function(s) {
  s <- gsub("\\", "\\\\", s, fixed = TRUE); s <- gsub("\"", "\\\"", s, fixed = TRUE)
  s <- gsub("\n", "\\n", s, fixed = TRUE); s <- gsub("\r", "\\r", s, fixed = TRUE)
  s <- gsub("\t", "\\t", s, fixed = TRUE)
  paste0("\"", s, "\"")
}

.to_json <- function(x) {
  if (is.null(x)) return("null")
  if (is.data.frame(x)) x <- as.list(x)
  if (is.list(x)) {
    if (!is.null(names(x)) && all(nzchar(names(x)))) {
      return(paste0("{", paste(vapply(names(x), function(k)
        paste0(.json_str(k), ":", .to_json(x[[k]])), ""), collapse = ","), "}"))
    }
    return(paste0("[", paste(vapply(x, .to_json, ""), collapse = ","), "]"))
  }
  if (is.factor(x)) x <- as.character(x)
  v <- if (is.logical(x)) ifelse(is.na(x), "null", ifelse(x, "true", "false"))
       else if (is.numeric(x)) ifelse(is.finite(x), .num_exact(x), "null")
       else if (is.character(x)) ifelse(is.na(x), "null", .json_str(x))
       else stop("Cannot write class ", class(x)[1], " to JSON.")
  if (length(v) == 1) v else paste0("[", paste(v, collapse = ","), "]")
}

sim_record_json <- function(x, file = NULL, include_raw = FALSE) {
  stopifnot(inherits(x, "farmastat_sim"))
  out <- list(record = x$record, performance = x$performance)
  if (include_raw) out$raw <- x$raw
  js <- .to_json(out)
  if (!is.null(file)) { writeLines(js, file, useBytes = TRUE); return(invisible(file)) }
  js
}

# -----------------------------------------------------------------------------
# Tier 3: the run as a stand-alone R script (heavy runs on the user's machine)
# -----------------------------------------------------------------------------
sim_export_script <- function(x, file = NULL, n_sim = NULL) {
  stopifnot(inherits(x, "farmastat_sim"))
  r <- x$record
  txt <- c(
    "# =============================================================================",
    sprintf("# CNK-FarmaStatR - simulation run - %s (%s v%s)", r$title, r$scenario, r$scenario_version),
    sprintf("# Original run: %s - %s - %s %s", r$started, r$r_version, r$package, r$package_version),
    sprintf("# RNG: %s", paste(r$rng_kind, collapse = " / ")),
    paste("#", r$disclaimer),
    "# =============================================================================",
    sprintf("# Requires CNKfarmastatr >= %s", r$package_version),
    "library(CNKfarmastatr)",
    "",
    sprintf("params <- %s", .r_list(r$params)),
    "",
    sprintf("res <- sim_run(%s, params = params, n_sim = %s, seed = %s, alpha = %s)",
            .r_value(r$scenario), .r_value(as.integer(n_sim %||% r$n_sim)), .r_value(r$seed), .r_value(r$alpha)),
    "print(res)",
    "# sim_record_json(res, \"run_record.json\")   # run record for the archive")
  if (!is.null(file)) { writeLines(txt, file, useBytes = TRUE); return(invisible(file)) }
  paste(txt, collapse = "\n")
}
)---"),
  "invitro_fast.R" = list(pinned = TRUE, sha256 = "98350729ad62ed8f0859e9bdd380c44b66d256f8e20e19f411d2936d49f144b4", text = r"---(# =============================================================================
# CNK-FarmaStatR v1 - In vitro equivalence simulation engine (balanced designs)
#
# Purpose: fast, vectorised versions of the procedures studied in technical note
#   FSR-TN-PBE-01 v0.4 (decisions KK-34, KK-35), for use inside simulations.
#   v0.1.1: invitro_gen draws standard normals for every component (common
#   random numbers also when a component is 0).
#   - invitro_gen():  data-generating mechanism (TN Section 6, Eq. 8-9)
#   - pbe_fast():     FDA PSG 020929 PBE procedure; must equal calc_pbe() exactly
#   - ema_ci_fast():  90% CI of the T/R geometric mean ratio, three ways (TN 5.3)
#
# Data layout: one product is a numeric array X[r, u, s] with r = replicate
#   (simulated data set), u = unit (units ordered batch by batch: batch 1 units
#   1..n, batch 2 units 1..n, ...), s = life stage. Log scale.
#
# The validated core calc_pbe() is not changed; pbe_fast() is tested against it
#   (tests/testthat/test-invitro-fast.R). Base R only. Version 0.1.1
# =============================================================================

# -----------------------------------------------------------------------------
# invitro_gen(): simulate R data sets for one product
#   X_ijs = mu + b_j + c_ij + tau_s + e_ijs                   (TN Eq. 8)
#   b ~ N(0, sB^2), c ~ N(0, sC^2), e ~ N(0, sW^2); tau fixed, sum(tau) = 0
# Draw order (fixed, for reproducibility): all b, then all c, then all e,
#   each filled replicate-fastest (R x ...).
# -----------------------------------------------------------------------------
invitro_gen <- function(R, l, n, m, mu = 0, sB = 0, sC = 0, sW = 0,
                        tau = rep(0, m)) {
  stopifnot(length(tau) == m, R >= 1, l >= 1, n >= 1, m >= 1)
  N <- l * n
  # standard normals scaled afterwards: rnorm(sd = 0) draws nothing, which
  # would shift the stream and break common random numbers across scenarios
  b  <- matrix(stats::rnorm(R * l) * sB, R, l)
  cc <- matrix(stats::rnorm(R * N) * sC, R, N)
  e  <- array(stats::rnorm(R * N * m) * sW, c(R, N, m))
  unit_level <- mu + b[, rep(seq_len(l), each = n), drop = FALSE] + cc   # R x N
  X <- e + as.vector(unit_level)                       # recycles over stages
  X + rep(tau, each = R * N)
}

# Shares -> components (TN Eq. 9; decision KK-29)
invitro_components <- function(sigma, pB, pL, q = 0) {
  if (pB < 0 || pL < 0 || pB + pL > 1) stop("Shares must satisfy pB, pL >= 0, pB + pL <= 1.")
  v <- sigma^2
  vL <- pL * v
  list(sB = sqrt(pB * v), sC = sqrt((1 - pB - pL) * v),
       sW = sqrt((1 - q) * vL), drift_var = q * vL)
}

# Linear drift scaled so that (1/m) sum(tau^2) = drift_var (TN 6.1)
invitro_drift <- function(m, drift_var) {
  if (m < 2 || drift_var == 0) return(rep(0, m))
  t <- seq_len(m) - (m + 1) / 2
  t * sqrt(drift_var / mean(t^2))
}

# -----------------------------------------------------------------------------
# Internal: per-product summary statistics, vectorised over replicates
# -----------------------------------------------------------------------------
.iv_stats <- function(X, l, n) {
  d <- dim(X); R <- d[1]; N <- d[2]; m <- d[3]
  if (N != l * n) stop("dim(X)[2] must equal l * n.")
  U <- rowMeans(X, dims = 2)                             # R x N unit means
  g <- rowMeans(U)                                       # grand mean
  msb <- m * rowSums((U - g)^2) / (N - 1)
  msw <- if (m > 1) rowSums((X - as.vector(U))^2) / (N * (m - 1)) else rep(0, R)
  bidx <- rep(seq_len(l), each = n)
  Bm <- U %*% outer(bidx, seq_len(l), "==") / n          # R x l batch means
  list(R = R, N = N, m = m, l = l, n = n, U = U, g = g, msb = msb, msw = msw,
       Bm = Bm, bidx = bidx)
}

# -----------------------------------------------------------------------------
# pbe_fast(): FDA PSG 020929 PBE (Appendix Steps 1-5), vectorised.
# Identical formulas to calc_pbe() for balanced data; returns a data frame with
# one row per replicate.
# -----------------------------------------------------------------------------
pbe_fast <- function(XT, XR, lT, nT, lR, nR, alpha = 0.05, sigma_T0 = 0.1) {
  st <- .iv_stats(XT, lT, nT); sr <- .iv_stats(XR, lR, nR)
  if (st$m != sr$m) stop("T and R must have the same number of life stages.")
  m <- st$m; NT <- st$N; NR <- sr$N
  theta_p <- ((log(1.11))^2 + 0.01) / sigma_T0^2
  E_D <- (st$g - sr$g)^2
  E1  <- st$msb / m
  E2  <- if (m > 1) st$msw * (m - 1) / m else 0 * E1
  E3s <- -(1 + theta_p) * sr$msb / m
  E4s <- if (m > 1) -(1 + theta_p) * sr$msw * (m - 1) / m else 0 * E1
  E3c <- -sr$msb / m
  E4c <- if (m > 1) -sr$msw * (m - 1) / m else 0 * E1
  t_val <- stats::qt(1 - alpha, NT + NR - 2)
  H_D <- (sqrt(E_D) + t_val * sqrt(st$msb / (NT * m) + sr$msb / (NR * m)))^2
  H1  <- (NT - 1) * E1  / stats::qchisq(alpha,     NT - 1)
  H3s <- (NR - 1) * E3s / stats::qchisq(1 - alpha, NR - 1)
  H3c <- (NR - 1) * E3c / stats::qchisq(1 - alpha, NR - 1)
  if (m > 1) {
    H2  <- NT * (m - 1) * E2  / stats::qchisq(alpha,     NT * (m - 1))
    H4s <- NR * (m - 1) * E4s / stats::qchisq(1 - alpha, NR * (m - 1))
    H4c <- NR * (m - 1) * E4c / stats::qchisq(1 - alpha, NR * (m - 1))
  } else { H2 <- H4s <- H4c <- 0 * E1 }
  Uq_Ref   <- (H_D - E_D)^2 + (H1 - E1)^2 + (H2 - E2)^2 + (H3s - E3s)^2 + (H4s - E4s)^2
  Uq_Const <- (H_D - E_D)^2 + (H1 - E1)^2 + (H2 - E2)^2 + (H3c - E3c)^2 + (H4c - E4c)^2
  Eq_Ref   <- E_D + E1 + E2 + E3s + E4s
  Eq_Const <- E_D + E1 + E2 + E3c + E4c - theta_p * sigma_T0^2
  H_eta_Ref   <- Eq_Ref + sqrt(Uq_Ref)
  H_eta_Const <- Eq_Const + sqrt(Uq_Const)
  sigma_R <- sqrt(sr$msb / m + (m - 1) * sr$msw / m)
  sigma_T <- sqrt(st$msb / m + (m - 1) * st$msw / m)
  ref <- sigma_R > sigma_T0
  H_eta <- ifelse(ref, H_eta_Ref, H_eta_Const)
  data.frame(mean_t = st$g, mean_r = sr$g, msb_t = st$msb, msw_t = st$msw,
             msb_r = sr$msb, msw_r = sr$msw, sigma_t = sigma_T, sigma_r = sigma_R,
             Eq_Ref = Eq_Ref, Uq_Ref = Uq_Ref, H_eta_Ref = H_eta_Ref,
             Eq_Const = Eq_Const, Uq_Const = Uq_Const, H_eta_Const = H_eta_Const,
             ref_scaled = ref, H_eta = H_eta, pass = H_eta <= 0)
}

# -----------------------------------------------------------------------------
# Internal: variance of one product mean and its degrees of freedom
#   method "a": pooled units          var = s2_units / N,  df = N - 1
#   method "b": batch means           var = s2_batch / l,  df = l - 1
#   method "c": REML for X = mu + tau_s (fixed) + b_j + c_ij + e_ijs, balanced.
#     Three orthogonal strata with mean squares MS_lot (df l-1),
#     MS_unit(lot) (df l(n-1)), MS_resid (df (N-1)(m-1)); expected values
#     theta_lot >= theta_unit >= theta_resid. The REML estimates of the thetas
#     are the df-weighted isotonic regression (pool-adjacent-violators) of the
#     observed MS under this order (Searle, Casella & McCulloch 2006, Ch. 6;
#     closed form for balanced data). Var(mean) = theta_lot / (N m).
#     If no pooling: identical to "b" (TN A.7). df = sum of pooled strata df
#     (FarmaStatR derivation). m = 1: residual stratum absent.
# -----------------------------------------------------------------------------
.iv_var_mean <- function(s, method) {
  N <- s$N; l <- s$l; n <- s$n; m <- s$m
  s2u <- s$msb / m                                        # variance of unit means
  s2b <- rowSums((s$Bm - s$g)^2) / (l - 1)                # variance of batch means
  if (method == "a") return(list(v = s2u / N, df = rep(N - 1, length(s2u))))
  if (method == "b") return(list(v = s2b / l, df = rep(l - 1, length(s2b))))
  ms_lot  <- n * m * s2b
  ms_unit <- m * rowSums((s$U - s$Bm[, s$bidx, drop = FALSE])^2) / (l * (n - 1))
  d1 <- l - 1; d2 <- l * (n - 1); d3 <- (N - 1) * (m - 1)
  th <- ms_lot; df <- rep(d1, length(th))
  # violator lot < unit: pool lot and unit
  p12 <- (d1 * ms_lot + d2 * ms_unit) / (d1 + d2)
  if (m > 1) {
    ms_res <- s$msw_resid
    p23 <- (d2 * ms_unit + d3 * ms_res) / (d2 + d3)
    p123 <- (d1 * ms_lot + d2 * ms_unit + d3 * ms_res) / (d1 + d2 + d3)
    # PAVA on three blocks, ordered decreasing
    case_unit_ok <- ms_unit >= ms_res
    # unit >= resid: only lot/unit can violate
    k1 <- case_unit_ok & ms_lot < ms_unit
    k1b <- k1 & p12 < ms_res                         # then pool all three
    th[k1] <- p12[k1]; df[k1] <- d1 + d2
    th[k1b] <- p123[k1b]; df[k1b] <- d1 + d2 + d3
    # unit < resid: pool unit and resid first
    k2 <- !case_unit_ok
    k2a <- k2 & ms_lot >= p23                        # lot stays alone
    k2b <- k2 & ms_lot < p23                         # pool all three
    th[k2a] <- ms_lot[k2a]; df[k2a] <- d1
    th[k2b] <- p123[k2b]; df[k2b] <- d1 + d2 + d3
  } else {
    k1 <- ms_lot < ms_unit
    th[k1] <- p12[k1]; df[k1] <- d1 + d2
  }
  list(v = th / (N * m), df = df)
}

# -----------------------------------------------------------------------------
# ema_ci_fast(): EMA OIP Rev. 2 §5.1 criterion 8 rule applied to one log-normal
#   quantity: 90% CI of exp(mu_T - mu_R) within [lower, upper] (default 0.85, 1.18).
#   Returns, for each method, the CI and the pass indicator.
# -----------------------------------------------------------------------------
ema_ci_fast <- function(XT, XR, lT, nT, lR, nR, level = 0.90,
                        limits = c(0.85, 1.18), methods = c("a", "b", "c")) {
  st <- .iv_stats(XT, lT, nT); sr <- .iv_stats(XR, lR, nR)
  st$msw_resid <- .iv_msw_resid(XT); sr$msw_resid <- .iv_msw_resid(XR)
  d <- st$g - sr$g
  out <- list()
  for (me in methods) {
    a <- .iv_var_mean(st, me); b <- .iv_var_mean(sr, me)
    se <- sqrt(a$v + b$v)
    df <- (a$v + b$v)^2 / (a$v^2 / a$df + b$v^2 / b$df)   # Welch-Satterthwaite
    q <- stats::qt(1 - (1 - level) / 2, df)
    lo <- exp(d - q * se); hi <- exp(d + q * se)
    out[[me]] <- data.frame(method = me, gmr = exp(d), lower = lo, upper = hi,
                            se = se, df = df,
                            pass = lo >= limits[1] & hi <= limits[2])
  }
  out
}

# Within-unit residual mean square after removing fixed stage effects
#   (two-way unit x stage residual), df = (N - 1)(m - 1); m = 1 -> 0
.iv_msw_resid <- function(X) {
  d <- dim(X); R <- d[1]; N <- d[2]; m <- d[3]
  if (m < 2) return(rep(0, R))
  U <- rowMeans(X, dims = 2)
  S <- colMeans(aperm(X, c(2, 1, 3)))                     # R x m stage means
  g <- rowMeans(U)
  res <- X - as.vector(U) - rep(as.vector(S), each = N) + g
  rowSums(res^2) / ((N - 1) * (m - 1))
}

# -----------------------------------------------------------------------------
# invitro_array(): balanced long data (calc_pbe layout: Batches, Container,
#   Stage, Product, score) -> 1 x (l n) x m array for one product, units ordered
#   batch by batch. Stops if the design is not balanced or complete.
# -----------------------------------------------------------------------------
invitro_array <- function(df, product) {
  names(df) <- c("Batches", "Container", "Stage", "Product", "score")
  d <- df[df$Product == product, ]
  if (nrow(d) == 0) stop("No rows for product ", product, ".")
  d$unit <- paste(d$Batches, d$Container, sep = "\r")
  bt <- sort(unique(as.character(d$Batches))); st <- sort(unique(d$Stage))
  u_b <- unique(d[, c("unit", "Batches")])
  nb <- table(as.character(u_b$Batches))
  if (length(unique(as.vector(nb))) != 1) stop("Unbalanced: units per batch differ.")
  u_b <- u_b[order(match(as.character(u_b$Batches), bt), u_b$unit), ]
  if (nrow(d) != nrow(u_b) * length(st)) stop("Incomplete: each unit needs every stage once.")
  X <- array(NA_real_, c(1, nrow(u_b), length(st)))
  X[cbind(1, match(d$unit, u_b$unit), match(d$Stage, st))] <- as.numeric(d$score)
  if (anyNA(X)) stop("Incomplete: each unit needs every stage once.")
  list(X = X, l = length(bt), n = as.vector(nb)[1], m = length(st))
}
)---"),
  "invitro_grid.R" = list(pinned = TRUE, sha256 = "a10a0427a5480076fabd643baf1219161469e2f0c25b7ef4933db3babcddaba0", text = r"---(# =============================================================================
# CNK-FarmaStatR v1 - In vitro equivalence: one scenario of the results grid
#
# Technical note FSR-TN-PBE-01 v0.4, Section 10 (ADEMP); decisions KK-29 ...
#   KK-35. One call = one data-generating mechanism; FDA PBE and EMA CI methods
#   (a), (b), (c) are applied to the same simulated data sets (Morris, White &
#   Crowther 2019, Section 4.3). Every scenario starts from the same seed
#   (common random numbers; Morris et al. 2019, Sections 4.1.1 and 5.4).
# Performance measures and Monte Carlo SEs: Morris et al. 2019, Table 6.
# v0.2.0 (decision of 16.10.2026, review report 02, M-07/M-09): paired Monte
#   Carlo SEs for method differences (sd of per-replicate decision differences
#   / sqrt(n_sim); Morris et al. 2019, Section 5.2), the share of replicates in
#   which EMA method (c) pools strata (REML boundary), and optional per-replicate
#   decisions (keep_reps). No extra random numbers are drawn: results of v0.1.0
#   are reproduced exactly.
# Base R only. Version 0.2.0
# =============================================================================

# -----------------------------------------------------------------------------
# invitro_scenario(): simulate one scenario and return a one-row data frame
#   sigma_R : total SD of the reference (log scale); sigma_T = rho * sigma_R
#   pB, pL  : batch and life-stage shares of the total variance (KK-29);
#             pB_T / pB_R allow different batch shares for T and R (KK-30)
#   q       : share of the life-stage component that is systematic drift (KK-31)
#   l, n, m : batches per product, units per batch, life stages (T = R design)
#   delta   : true mean difference mu_T - mu_R (log scale)
# -----------------------------------------------------------------------------
invitro_scenario <- function(sigma_R, rho = 1, pB = 0, pL = 0.15, q = 0,
                             l = 3, n = 10, m = 3, delta = 0,
                             pB_T = pB, pB_R = pB, n_sim = 10000, seed = 20261015,
                             alpha = 0.05, sigma_T0 = 0.1, ema_limits = c(0.85, 1.18),
                             keep_reps = FALSE) {
  # m = 1: one measurement per unit; the life-stage share is part of the unit
  # level (PSG 020929 Appendix Step 4) and a systematic stage drift cannot exist
  if (m == 1 && q > 0) stop("q > 0 needs m >= 2 (with m = 1 there is no stage drift).")
  sigma_T <- rho * sigma_R
  cT <- invitro_components(sigma_T, pB_T, pL, q)
  cR <- invitro_components(sigma_R, pB_R, pL, q)
  set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion")
  XT <- invitro_gen(n_sim, l, n, m, mu = delta, sB = cT$sB, sC = cT$sC, sW = cT$sW,
                    tau = invitro_drift(m, cT$drift_var))
  XR <- invitro_gen(n_sim, l, n, m, mu = 0, sB = cR$sB, sC = cR$sC, sW = cR$sW,
                    tau = invitro_drift(m, cR$drift_var))
  f <- pbe_fast(XT, XR, l, n, l, n, alpha = alpha, sigma_T0 = sigma_T0)
  e <- ema_ci_fast(XT, XR, l, n, l, n, level = 1 - 2 * alpha, limits = ema_limits)
  theta_p <- ((log(1.11))^2 + 0.01) / sigma_T0^2
  # true eta with the criterion chosen by the true sigma_R (TN 10.3)
  ref_true <- sigma_R > sigma_T0
  eta <- if (ref_true) delta^2 + sigma_T^2 - (1 + theta_p) * sigma_R^2 else
    delta^2 + sigma_T^2 - sigma_R^2 - theta_p * sigma_T0^2
  Eq <- if (ref_true) f$Eq_Ref else f$Eq_Const
  Hq <- if (ref_true) f$H_eta_Ref else f$H_eta_Const
  pr <- function(x) c(mean(x), sqrt(mean(x) * (1 - mean(x)) / length(x)))
  mn <- function(x) c(mean(x), stats::sd(x) / sqrt(length(x)))
  out <- data.frame(sigma_R = sigma_R, rho = rho, pB_T = pB_T, pB_R = pB_R, pL = pL,
                    q = q, l = l, n = n, m = m, delta = delta, gmr = exp(delta),
                    eta = eta, n_sim = n_sim, seed = seed)
  add <- function(name, v) { out[[name]] <<- v[1]; out[[paste0(name, "_mcse")]] <<- v[2] }
  add("fda_pass", pr(f$pass))
  add("fda_crit_err", pr(f$ref_scaled != ref_true))
  add("fda_cover", pr(Hq >= eta))
  add("fda_bias_Eq", mn(Eq - eta))
  add("fda_bias_s2R", mn(f$sigma_r^2 - sigma_R^2))
  for (me in names(e)) {
    x <- e[[me]]
    add(paste0("ema_", me, "_pass"), pr(x$pass))
    add(paste0("ema_", me, "_cover"), pr(x$lower <= exp(delta) & exp(delta) <= x$upper))
  }
  # EMA (c): share of replicates in which the REML solution pools strata
  # (boundary: a variance component estimated as 0), per product
  pooled <- function(X) {
    s <- .iv_stats(X, l, n); s$msw_resid <- .iv_msw_resid(X)
    .iv_var_mean(s, "c")$df != l - 1
  }
  pT <- pooled(XT); pR <- pooled(XR)
  add("ema_c_pooled_T", pr(pT)); add("ema_c_pooled_R", pr(pR))
  # paired differences of pass decisions on the same data sets
  dec <- data.frame(fda = f$pass, ema_a = e$a$pass, ema_b = e$b$pass, ema_c = e$c$pass)
  pairs <- list(c("fda", "ema_a"), c("fda", "ema_b"), c("fda", "ema_c"),
                c("ema_a", "ema_c"), c("ema_b", "ema_c"))
  for (pp in pairs) add(paste0("diff_", pp[1], "_", pp[2]),
                        mn(as.numeric(dec[[pp[1]]]) - as.numeric(dec[[pp[2]]])))
  if (keep_reps) attr(out, "reps") <- cbind(rep = seq_len(n_sim), dec,
                                            ema_c_pooled_T = pT, ema_c_pooled_R = pR)
  out
}

# Boundary mean difference for FDA type I error (TN Eq. 11): eta = 0
invitro_delta0 <- function(sigma_R, rho = 1, sigma_T0 = 0.1) {
  theta_p <- ((log(1.11))^2 + 0.01) / sigma_T0^2
  sigma_T <- rho * sigma_R
  d2 <- if (sigma_R > sigma_T0) (1 + theta_p) * sigma_R^2 - sigma_T^2 else
    sigma_R^2 + theta_p * sigma_T0^2 - sigma_T^2
  if (d2 < 0) NA_real_ else sqrt(d2)
}

# Run record (project rule: parameters, seed, RNG kind, R and package versions)
invitro_run_record <- function(grid_id, seed, n_sim) {
  pv <- tryCatch(as.character(utils::packageVersion("CNKfarmastatr")),
                 error = function(e) "source")
  data.frame(grid_id = grid_id, seed = seed, n_sim = n_sim,
             rng = paste(RNGkind()[1:2], collapse = "/"),
             r_version = R.version.string, package_version = pv,
             engine = "invitro_fast.R 0.1.1; invitro_grid.R 0.2.0",
             run_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
}
)---"),
  "platform_input.R" = list(pinned = FALSE, sha256 = "30b3d7aeddcdc4daa490136047b27b0a4ca2ccde2bce4dc04339d329e4fca25b", text = r"---(# =============================================================================
# CNK-FarmaStatR v1 - Platform input check for the in vitro equivalence engine
#
# FSR-TN-PLT-01 v0.4, Section 11 (Table 11.1, "Hata yakalama") and G-52 finding:
#   the pinned engine (invitro_grid.R 0.2.0, invitro_fast.R 0.1.1) runs without
#   error on some invalid inputs (negative or zero sigma_R, rho <= 0, q outside
#   [0, 1], alpha outside (0, 0.5), reversed EMA limits) or stops with an
#   obscure message (l = 1, n = 1, non-integer m, infinite delta). The engine
#   files are SHA-256 pinned and are not changed; this separate function rejects
#   such inputs before a run starts. The engine fix is left to its first revision.
# Scope (P1): mathematical validity of each input only. Inputs the engine itself
#   rejects with a clear message (pB, pL shares; q > 0 with m = 1) are left to the
#   engine so that the browser and local R show the same engine message.
#   Domain limits for the user parameter space are set in P2 (TN Table 5.3, H-7).
# Rules: FarmaStatR derivation (no guideline source); n_sim upper limit 20,000 is
#   the temporary platform limit (FSR-TN-PLT-01 Section 3, decision KK-43).
# Run size (version 0.2.0, G-60, KK-47): l * n * m * n_sim <= 8.1e6 cells. Basis:
#   P1 acceptance (G-57) exceeded the 1 GB memory threshold at 6 x 30, m = 3,
#   n_sim 20,000; the frozen rule lowers the temporary limit (KK-46). Prototype
#   alone (G-59): 6 x 30, m = 3 used 688 MB at n_sim 15,000 (8.1e6 cells) and
#   937 MB at 20,000. FarmaStatR derivation; one device, single readings.
# Each problem has a code (for the TR/EN translation file) and an English message.
# Base R only. Version 0.2.0
# Research and education only; not a system validated for GxP environments.
# =============================================================================

.platform_invitro_params <- c("sigma_R", "rho", "pB", "pL", "q", "l", "n", "m", "delta",
                              "pB_T", "pB_R", "n_sim", "seed", "alpha", "sigma_T0",
                              "ema_limits", "keep_reps")

# -----------------------------------------------------------------------------
# platform_check_invitro(): check a parameter list for invitro_scenario()
#   params    : named list of arguments for invitro_scenario()
#   n_sim_max : platform upper limit for n_sim
#   cells_max : platform upper limit for l * n * m * n_sim (run size)
# Returns a data frame of problems (field, code, message); zero rows = valid.
# -----------------------------------------------------------------------------
platform_check_invitro <- function(params, n_sim_max = 20000, cells_max = 8.1e6) {
  out <- data.frame(field = character(0), code = character(0), message = character(0),
                    stringsAsFactors = FALSE)
  bad <- function(field, code, message)
    out[nrow(out) + 1, ] <<- c(field, code, message)
  if (!is.list(params) || (length(params) > 0 && (is.null(names(params)) || any(names(params) == "")))) {
    bad("params", "params_not_named_list", "Parameters must be a named list.")
    return(out)
  }
  unk <- setdiff(names(params), .platform_invitro_params)
  for (u in unk) bad(u, "unknown_param", paste0("Unknown parameter '", u, "'."))
  if (anyDuplicated(names(params)))
    bad("params", "duplicate_param", "A parameter is given more than once.")
  if (!"sigma_R" %in% names(params))
    bad("sigma_R", "missing_param", "sigma_R is required.")

  num1 <- function(f) {                          # one finite number, else record
    v <- params[[f]]
    ok <- is.numeric(v) && length(v) == 1 && !is.na(v) && is.finite(v)
    if (!ok) bad(f, "not_finite_number", paste0(f, " must be one finite number."))
    ok
  }
  has <- function(f) f %in% names(params)
  whole <- function(v) abs(v - round(v)) == 0

  for (f in c("sigma_R", "rho", "sigma_T0"))
    if (has(f) && num1(f) && params[[f]] <= 0)
      bad(f, "not_positive", paste0(f, " must be > 0."))
  for (f in c("pB", "pL", "pB_T", "pB_R")) if (has(f)) num1(f)   # ranges: engine
  if (has("q") && num1("q") && (params$q < 0 || params$q > 1))
    bad("q", "out_of_unit_interval", "q must be in [0, 1].")
  for (f in c("l", "n"))
    if (has(f) && num1(f) && (!whole(params[[f]]) || params[[f]] < 2))
      bad(f, "integer_min_2", paste0(f, " must be a whole number >= 2."))
  if (has("m") && num1("m") && (!whole(params$m) || params$m < 1))
    bad("m", "integer_min_1", "m must be a whole number >= 1.")
  if (has("delta")) num1("delta")
  if (has("n_sim") && num1("n_sim") &&
      (!whole(params$n_sim) || params$n_sim < 1 || params$n_sim > n_sim_max))
    bad("n_sim", "n_sim_range", paste0("n_sim must be a whole number in [1, ", n_sim_max, "]."))
  # run size: checked only when l, n, m and n_sim are themselves valid
  dims <- c(l = 3, n = 10, m = 3)                      # engine defaults (invitro_scenario)
  for (f in names(dims)) if (has(f)) dims[[f]] <- params[[f]]
  if (has("n_sim") && !any(c("l", "n", "m", "n_sim") %in% out$field) &&
      all(vapply(c(as.list(dims), list(params$n_sim)), function(v) is.numeric(v) && length(v) == 1 && is.finite(v), TRUE))) {
    size <- prod(dims) * params$n_sim
    if (size > cells_max)
      bad("n_sim", "run_size", paste0("l * n * m * n_sim must be <= ", format(cells_max, scientific = FALSE, big.mark = ","),
                                     "; for this design n_sim <= ", floor(cells_max / prod(dims)), "."))
  }
  if (has("seed") && num1("seed") &&
      (!whole(params$seed) || abs(params$seed) > .Machine$integer.max))
    bad("seed", "seed_integer", "seed must be a whole number within the R integer range.")
  if (has("alpha") && num1("alpha") && (params$alpha <= 0 || params$alpha >= 0.5))
    bad("alpha", "alpha_range", "alpha must be in (0, 0.5).")
  if (has("ema_limits")) {
    v <- params$ema_limits
    if (!(is.numeric(v) && length(v) == 2 && all(is.finite(v)) && v[1] > 0 && v[1] < 1 && v[2] > 1))
      bad("ema_limits", "ema_limits_order", "ema_limits must be two numbers with 0 < lower < 1 < upper.")
  }
  if (has("keep_reps") && !(is.logical(params$keep_reps) && length(params$keep_reps) == 1 &&
                            !is.na(params$keep_reps)))
    bad("keep_reps", "not_flag", "keep_reps must be TRUE or FALSE.")
  out
}

# -----------------------------------------------------------------------------
# platform_run_invitro(): check, then run invitro_scenario() unchanged.
#   Stops with a condition of class "farmastat_input_error" that carries the
#   problem table (element $problems) when the check fails.
# -----------------------------------------------------------------------------
platform_run_invitro <- function(params, n_sim_max = 20000, cells_max = 8.1e6) {
  pr <- platform_check_invitro(params, n_sim_max = n_sim_max, cells_max = cells_max)
  if (nrow(pr) > 0) {
    msg <- paste0("Invalid input:\n", paste0("- ", pr$message, collapse = "\n"))
    stop(structure(class = c("farmastat_input_error", "error", "condition"),
                   list(message = msg, call = NULL, problems = pr)))
  }
  do.call(invitro_scenario, params)
}
)---"),
  "platform_hipotez.R" = list(pinned = FALSE, sha256 = "4a9abe12729d88edb7ed2ee8491fc4860a8572641f37718632c6627c4e5c2681", text = r"---(# =============================================================================
# CNK-FarmaStatR v1 - Platform: hypothesis state, metric name, KK-38 label and
#   canonical scenario key for the in vitro equivalence module
#
# FSR-TN-PLT-02 v0.1 (approved, KK-49), T-1 and T-2; rules from FSR-TN-PLT-01
#   v0.5 Section 5 (Table 5.1 classification, Table 5.2 metric names, Section 5.3
#   numerical tolerance; decisions KK-44, KK-45) and Section 6.3 (D-03).
#   FDA PBE (PSG 020929): eta = delta^2 + sigma_T^2 - sigma_R^2
#                                - theta_p * max(sigma_R^2, sigma_T0^2)
#     H0: eta >= 0. The criterion is chosen by the TRUE sigma_R.
#   EMA OIP Rev. 2 Section 5.1 criterion 8: H0: GMR <= 0.85 or GMR >= 1.18;
#     methods (a), (b), (c) test the same hypothesis.
#   Classes: H0_sinir (|distance| <= tol), H0_ic, H1; tol = 1e-12 is a project
#     tolerance for floating-point deviations, not an equivalence margin
#     (FSR-TN-PLT-01 Section 5.3, owner's text).
#   Near-boundary warning (P2-K1, option b; FarmaStatR derivation): one delta
#     scale for both methods, |delta - delta_boundary| <= 1e-4, only when the
#     class is not H0_sinir. FDA boundaries are +-delta0; no FDA warning when
#     delta0 is undefined (eta > 0 already at delta = 0).
#   KK-38: type I error labels, one-sided 95% Monte Carlo limits; z = qnorm(0.95)
#     as in asama2_ozet.R (1.645 in the decision text is this value rounded).
# Base R only. Version 0.1.0
# Research and education only; not a system validated for GxP environments.
# =============================================================================

.platform_sinir_adlari <- c("fda_delta0", "fda_minus_delta0", "ema_1.18", "ema_0.85",
                            "gmr_1.00", "gmr_1.05")

# FDA boundary mean difference delta0 (eta = 0), vectorised; NA if undefined
.platform_delta0 <- function(sigma_R, rho, sigma_T0 = 0.1) {
  theta_p <- ((log(1.11))^2 + 0.01) / sigma_T0^2
  sT2 <- (rho * sigma_R)^2
  d2 <- ifelse(sigma_R > sigma_T0, (1 + theta_p) * sigma_R^2 - sT2,
               sigma_R^2 + theta_p * sigma_T0^2 - sT2)
  ifelse(d2 < 0, NA_real_, sqrt(pmax(d2, 0)))
}

# delta for a named boundary (FSR-TN-PLT-01 Section 5.3; grid column delta_id)
platform_sinir_delta <- function(sinir, sigma_R, rho, sigma_T0 = 0.1, ema_limits = c(0.85, 1.18)) {
  bad <- setdiff(unique(sinir), .platform_sinir_adlari)
  if (length(bad)) stop("Unknown boundary name: ", paste(bad, collapse = ", "), ".")
  d0 <- .platform_delta0(sigma_R, rho, sigma_T0)
  out <- rep(NA_real_, length(sinir))
  out[sinir == "fda_delta0"] <- d0[sinir == "fda_delta0"]
  out[sinir == "fda_minus_delta0"] <- -d0[sinir == "fda_minus_delta0"]
  out[sinir == "ema_1.18"] <- log(ema_limits[2])
  out[sinir == "ema_0.85"] <- log(ema_limits[1])
  out[sinir == "gmr_1.00"] <- log(1.00)
  out[sinir == "gmr_1.05"] <- log(1.05)
  out
}

# -----------------------------------------------------------------------------
# platform_hipotez(): true hypothesis state per scenario and method
#   Give either delta (log scale) or sinir (boundary name). Vectorised: all
#   arguments are recycled to the number of scenarios.
#   Returns one row per scenario and method (fda, ema_a, ema_b, ema_c).
# -----------------------------------------------------------------------------
platform_hipotez <- function(sigma_R, rho = 1, delta = NULL, sinir = NULL, sigma_T0 = 0.1,
                             ema_limits = c(0.85, 1.18), tol = 1e-12, yakinlik = 1e-4) {
  if (is.null(delta) == is.null(sinir)) stop("Give exactly one of delta and sinir.")
  n <- max(length(sigma_R), length(rho), length(delta), length(sinir))
  sigma_R <- rep_len(sigma_R, n); rho <- rep_len(rho, n)
  if (!is.null(sinir)) {
    sinir <- rep_len(sinir, n)
    delta <- platform_sinir_delta(sinir, sigma_R, rho, sigma_T0, ema_limits)
    if (anyNA(delta)) stop("FDA delta0 is not defined for some scenarios (eta > 0 at delta = 0).")
  } else {
    delta <- rep_len(delta, n); sinir <- rep(NA_character_, n)
  }
  if (any(!is.finite(c(sigma_R, rho, delta))) || any(sigma_R <= 0) || any(rho <= 0))
    stop("sigma_R and rho must be > 0 and delta finite.")
  theta_p <- ((log(1.11))^2 + 0.01) / sigma_T0^2
  eta <- delta^2 + (rho * sigma_R)^2 - sigma_R^2 - theta_p * pmax(sigma_R^2, sigma_T0^2)
  cls_fda <- ifelse(abs(eta) <= tol, "H0_sinir", ifelse(eta > 0, "H0_ic", "H1"))
  lo <- log(ema_limits[1]); hi <- log(ema_limits[2])
  cls_ema <- ifelse(abs(delta - lo) <= tol | abs(delta - hi) <= tol, "H0_sinir",
                    ifelse(delta < lo | delta > hi, "H0_ic", "H1"))
  d0 <- .platform_delta0(sigma_R, rho, sigma_T0)
  dist_fda <- ifelse(is.na(d0), Inf, pmin(abs(delta - d0), abs(delta + d0)))
  dist_ema <- pmin(abs(delta - lo), abs(delta - hi))
  metric <- function(cl) c(H0_sinir = "tip1_sinir", H0_ic = "noktasal_tip1", H1 = "guc")[cl]
  meth <- c("fda", "ema_a", "ema_b", "ema_c")
  i <- rep(seq_len(n), each = 4); me <- rep(meth, n)
  is_fda <- me == "fda"
  cls <- ifelse(is_fda, cls_fda[i], cls_ema[i])
  dist <- ifelse(is_fda, dist_fda[i], dist_ema[i])
  data.frame(senaryo = i, yontem = me,
             buyukluk = ifelse(is_fda, eta[i], delta[i]),
             buyukluk_tur = ifelse(is_fda, "eta", "ln_gmr"),
             sinif = cls, metrik = unname(metric(cls)),
             yakinlik_uyarisi = cls != "H0_sinir" & dist <= yakinlik,
             delta = delta[i], delta_metin = .num_exact(delta[i]), sinir = sinir[i],
             stringsAsFactors = FALSE)
}

# -----------------------------------------------------------------------------
# platform_kk38(): three-class type I error label (decision KK-38), H0 only
#   p_hat - z MCSE > nominal  -> "nominali_asiyor"
#   p_hat + z MCSE <= nominal -> "kontrol_kanitli"
#   otherwise                 -> "ayirt_edilemiyor";  H1 -> NA
# -----------------------------------------------------------------------------
platform_kk38 <- function(p_hat, mcse, sinif, nominal = 0.05, z = stats::qnorm(0.95)) {
  lab <- ifelse(p_hat - z * mcse > nominal, "nominali_asiyor",
                ifelse(p_hat + z * mcse <= nominal, "kontrol_kanitli", "ayirt_edilemiyor"))
  ifelse(sinif %in% c("H0_sinir", "H0_ic"), lab, NA_character_)
}

# -----------------------------------------------------------------------------
# platform_anahtar(): canonical keys (FSR-TN-PLT-02 Section 4; D-03)
#   Fixed order of name=value pairs separated by "|". delta is written as the
#   boundary name when one is given, otherwise with .num_exact(); a GMR input
#   is converted once to delta = log(gmr). Defaults of invitro_scenario() are
#   written explicitly.
#   Scenario key = data-generating condition only, independent of the run
#   (FSR-TN-PLT-01 Table 6.1, "senaryo"); run key (kosu = TRUE) = scenario key
#   + n_sim + seed. (FSR-TN-PLT-02 v0.1 Section 4 listed n_sim and seed in one
#   key; resolved into these two keys, G-65.)
# -----------------------------------------------------------------------------
platform_anahtar <- function(sigma_R, rho = 1, pB_T = 0, pB_R = pB_T, pL = 0.15, q = 0,
                             l = 3, n = 10, m = 3, delta = NULL, gmr = NULL, sinir = NULL,
                             n_sim = 10000, seed = 20261015, kosu = FALSE) {
  given <- !c(is.null(delta), is.null(gmr), is.null(sinir))
  if (sum(given) != 1) stop("Give exactly one of delta, gmr and sinir.")
  dtxt <- if (!is.null(sinir)) {
    bad <- setdiff(unique(sinir), .platform_sinir_adlari)
    if (length(bad)) stop("Unknown boundary name: ", paste(bad, collapse = ", "), ".")
    sinir
  } else .num_exact(if (!is.null(gmr)) log(gmr) else delta)
  f <- function(v) .num_exact(as.numeric(v))
  paste0("sigma_R=", f(sigma_R), "|rho=", f(rho), "|pB_T=", f(pB_T), "|pB_R=", f(pB_R),
         "|pL=", f(pL), "|q=", f(q), "|l=", f(l), "|n=", f(n), "|m=", f(m),
         "|delta=", dtxt, if (kosu) paste0("|n_sim=", f(n_sim), "|seed=", f(seed)) else "")
}
)---")
)

run <- .fsr_main(params, sinir, delta, output_dir, .fsr_files, .fsr_export)
