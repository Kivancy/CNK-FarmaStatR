# =============================================================================
# CNK-FarmaStatR v1 - Simulation framework - Performance measures
#
# Source: Morris TP, White IR, Crowther MJ. Using simulation studies to evaluate
#   statistical methods. Stat Med 2019;38:2074-2102, Table 6 (performance
#   measures and their Monte Carlo standard errors).
#
# Every measure is returned with its Monte Carlo standard error (MCSE).
# Base R only. Version 0.1.0
# =============================================================================

# One measure: estimate and MCSE (NA when not estimable)
.sim_measure <- function(measure, estimate, mcse) {
  data.frame(measure = measure, estimate = estimate, mcse = mcse,
             stringsAsFactors = FALSE)
}

# -----------------------------------------------------------------------------
# sim_performance()
#   est        : point estimates, one per replicate
#   truth      : true value of the estimand (theta)
#   se         : model-based standard errors (optional)
#   lower,upper: confidence limits (optional)
#   p          : p-values (optional)
#   alpha      : significance level for the rejection rate
#   reject     : logical rejection decisions (optional; used instead of p)
# Replicates with a missing estimate are excluded from estimate-based measures
# and counted in n_missing (Morris et al. 2019 recommend reporting them).
# -----------------------------------------------------------------------------
sim_performance <- function(est = NULL, truth = NULL, se = NULL,
                            lower = NULL, upper = NULL, p = NULL,
                            alpha = 0.05, reject = NULL) {
  out <- list()

  if (!is.null(est)) {
    if (is.null(truth)) stop("truth is required with est.")
    x <- est[is.finite(est)]; n <- length(x)
    if (n >= 2) {
      xbar <- mean(x); s2 <- sum((x - xbar)^2) / (n - 1)
      # Bias = mean(est) - theta; MCSE = sqrt(sum((est - mean)^2) / (n (n - 1)))
      out$bias <- .sim_measure("bias", xbar - truth, sqrt(s2 / n))
      # EmpSE = sd(est); MCSE = EmpSE / sqrt(2 (n - 1))
      empse <- sqrt(s2)
      out$empse <- .sim_measure("empse", empse, empse / sqrt(2 * (n - 1)))
      # MSE = mean((est - theta)^2); MCSE = sqrt(sum(((est - theta)^2 - MSE)^2) / (n (n - 1)))
      d2 <- (x - truth)^2; mse <- mean(d2)
      out$mse <- .sim_measure("mse", mse, sqrt(sum((d2 - mse)^2) / (n * (n - 1))))

      if (!is.null(se)) {
        v <- se[is.finite(est)]^2; v <- v[is.finite(v)]; nv <- length(v)
        if (nv >= 2) {
          # ModSE = sqrt(mean(se^2)); MCSE ~ sqrt(Var(se^2) / (4 n ModSE^2))
          modse <- sqrt(mean(v)); varv <- stats::var(v)
          out$modse <- .sim_measure("modse", modse, sqrt(varv / (4 * nv * modse^2)))
          # Relative % error in ModSE = 100 (ModSE / EmpSE - 1)
          # MCSE ~ 100 (ModSE / EmpSE) sqrt(Var(se^2) / (4 n ModSE^4) + 1 / (2 (n - 1)))
          out$relerr_modse <- .sim_measure(
            "relerr_modse", 100 * (modse / empse - 1),
            100 * (modse / empse) * sqrt(varv / (4 * nv * modse^4) + 1 / (2 * (n - 1))))
        }
      }
    }
  }

  if (!is.null(lower) && !is.null(upper)) {
    ok <- is.finite(lower) & is.finite(upper); nc <- sum(ok)
    if (nc >= 1) {
      if (is.null(truth)) stop("truth is required with lower/upper.")
      # Coverage = mean(lower <= theta <= upper); MCSE = sqrt(C (1 - C) / n)
      cov <- mean(lower[ok] <= truth & truth <= upper[ok])
      out$coverage <- .sim_measure("coverage", cov, sqrt(cov * (1 - cov) / nc))
      if (!is.null(est)) {
        # Bias-eliminated coverage: theta replaced by mean(est)
        xbar <- mean(est[is.finite(est)])
        bec <- mean(lower[ok] <= xbar & xbar <= upper[ok])
        out$be_coverage <- .sim_measure("be_coverage", bec, sqrt(bec * (1 - bec) / nc))
      }
    }
  }

  if (is.null(reject) && !is.null(p)) reject <- p <= alpha
  if (!is.null(reject)) {
    r <- reject[!is.na(reject)]; nr <- length(r)
    if (nr >= 1) {
      # Rejection rate (power or type I error) = mean(reject); MCSE = sqrt(R (1 - R) / n)
      rr <- mean(r)
      out$rejection <- .sim_measure("rejection", rr, sqrt(rr * (1 - rr) / nr))
    }
  }

  tab <- if (length(out)) do.call(rbind, out) else
    .sim_measure(character(0), numeric(0), numeric(0))
  rownames(tab) <- NULL
  attr(tab, "n_missing") <- if (is.null(est)) NA_integer_ else sum(!is.finite(est))
  tab
}

# -----------------------------------------------------------------------------
# sim_n_required(): number of replicates for a target MCSE
#   Proportions (coverage, rejection): n = p (1 - p) / MCSE^2
#   Bias:                              n = Var(est) / MCSE^2
# (Morris et al. 2019, choice of the number of repetitions n_sim)
# -----------------------------------------------------------------------------
sim_n_required <- function(mcse, p = NULL, var_est = NULL) {
  if (!xor(is.null(p), is.null(var_est))) stop("Give exactly one of p or var_est.")
  v <- if (!is.null(p)) p * (1 - p) else var_est
  ceiling(round(v / mcse^2, 8))   # round first: 0.95 * (1 - 0.95) is not exact in binary
}
