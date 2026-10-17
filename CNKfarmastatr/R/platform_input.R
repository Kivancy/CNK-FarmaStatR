# =============================================================================
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
# Each problem has a code (for the TR/EN translation file) and an English message.
# Base R only. Version 0.1.0
# Research and education only; not a system validated for GxP environments.
# =============================================================================

.platform_invitro_params <- c("sigma_R", "rho", "pB", "pL", "q", "l", "n", "m", "delta",
                              "pB_T", "pB_R", "n_sim", "seed", "alpha", "sigma_T0",
                              "ema_limits", "keep_reps")

# -----------------------------------------------------------------------------
# platform_check_invitro(): check a parameter list for invitro_scenario()
#   params    : named list of arguments for invitro_scenario()
#   n_sim_max : platform upper limit for n_sim
# Returns a data frame of problems (field, code, message); zero rows = valid.
# -----------------------------------------------------------------------------
platform_check_invitro <- function(params, n_sim_max = 20000) {
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
platform_run_invitro <- function(params, n_sim_max = 20000) {
  pr <- platform_check_invitro(params, n_sim_max = n_sim_max)
  if (nrow(pr) > 0) {
    msg <- paste0("Invalid input:\n", paste0("- ", pr$message, collapse = "\n"))
    stop(structure(class = c("farmastat_input_error", "error", "condition"),
                   list(message = msg, call = NULL, problems = pr)))
  }
  do.call(invitro_scenario, params)
}
