# =============================================================================
# CNK-FarmaStatR v1 - Simulation framework - Teaching and reference scenario
#
# demo_mean_ci: coverage of the 95% t and z confidence intervals for a mean,
# and type I error of the one-sample t test.
# Under normal data the true values are known exactly, which makes this
# scenario the analytic test case of the simulation framework:
#   coverage of the t interval            = conf
#   coverage of the z interval            = 2 * pt(qnorm((1 + conf) / 2), n - 1) - 1
#   type I error of the t test at theta0 = theta : alpha
# With log-normal data the same scenario shows how skewness affects coverage
# (teaching use). Version 0.1.0
# =============================================================================

.demo_mean_ci <- sim_scenario(
  id = "demo_mean_ci",
  title = "Confidence interval for a mean: t versus z",
  aim = paste("Coverage of the t and z confidence intervals for a population mean",
              "and type I error of the one-sample t test, for small samples and",
              "normal or log-normal data."),
  dgm = function(p) {
    if (p$dist == "normal") stats::rnorm(p$n, p$mu, p$sigma)
    else stats::rlnorm(p$n, p$mu, p$sigma)
  },
  dgm_text = paste("n independent observations from N(mu, sigma^2) or from a",
                   "log-normal distribution with log-scale parameters mu and sigma."),
  estimand = "Population mean",
  truth = function(p) if (p$dist == "normal") p$mu else exp(p$mu + p$sigma^2 / 2),
  methods = list(
    t = function(x, p) {
      n <- length(x); m <- mean(x); se <- stats::sd(x) / sqrt(n)
      q <- stats::qt((1 + p$conf) / 2, n - 1)
      theta <- if (p$dist == "normal") p$mu else exp(p$mu + p$sigma^2 / 2)
      tstat <- (m - theta) / se
      c(est = m, se = se, lower = m - q * se, upper = m + q * se,
        p = 2 * stats::pt(-abs(tstat), n - 1))
    },
    z = function(x, p) {
      n <- length(x); m <- mean(x); se <- stats::sd(x) / sqrt(n)
      q <- stats::qnorm((1 + p$conf) / 2)
      c(est = m, se = se, lower = m - q * se, upper = m + q * se)
    }),
  params = list(n = 10L, mu = 0, sigma = 1, dist = "normal", conf = 0.95),
  param_text = c(n = "Sample size (at least 2)",
                 mu = "Mean (normal) or log-scale mean (log-normal)",
                 sigma = "Standard deviation (normal) or log-scale SD (log-normal), > 0",
                 dist = "\"normal\" or \"lognormal\"",
                 conf = "Confidence level, between 0 and 1"),
  check = function(p) {
    if (!is.numeric(p$n) || p$n < 2 || p$n != round(p$n)) stop("n must be an integer >= 2.")
    if (!is.numeric(p$sigma) || p$sigma <= 0) stop("sigma must be > 0.")
    if (!p$dist %in% c("normal", "lognormal")) stop("dist must be \"normal\" or \"lognormal\".")
    if (!is.numeric(p$conf) || p$conf <= 0 || p$conf >= 1) stop("conf must be in (0, 1).")
  },
  references = c("Morris TP, White IR, Crowther MJ. Stat Med 2019;38:2074-2102 (ADEMP)."),
  version = "0.1.0")

sim_register(.demo_mean_ci)
