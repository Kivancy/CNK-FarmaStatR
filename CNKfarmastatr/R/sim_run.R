# =============================================================================
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
