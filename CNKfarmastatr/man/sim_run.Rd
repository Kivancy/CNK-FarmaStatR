\name{sim_run}
\alias{sim_run}
\alias{sim_scenario}
\alias{sim_register}
\alias{sim_get}
\alias{sim_scenarios}
\alias{sim_replicate}
\alias{sim_record_json}
\alias{sim_export_script}
\alias{print.farmastat_sim}
\title{Simulation scenarios, runs and reproducible run records}
\description{
The simulation framework of CNK-FarmaStatR. A \emph{scenario} describes a
simulation study in ADEMP terms (aims, data-generating mechanism, estimand,
methods, performance measures; Morris et al. 2019) with default parameters
taken from the source publication. \code{sim_run} runs it with any parameter
values the user chooses and returns every performance measure with its Monte
Carlo standard error and a run record that makes the run reproducible.
}
\usage{
sim_run(scenario, params = list(), n_sim = 1000, seed = 1, alpha = 0.05,
        keep_states = FALSE)

sim_scenario(id, title, aim, dgm, dgm_text, estimand, truth, methods, params,
             param_text = NULL, check = NULL, references = character(0),
             version = "0.1.0")
sim_register(scenario)
sim_get(id)
sim_scenarios()

sim_replicate(x, i)
sim_record_json(x, file = NULL, include_raw = FALSE)
sim_export_script(x, file = NULL, n_sim = NULL)

\method{print}{farmastat_sim}(x, digits = 4, ...)
}
\arguments{
  \item{scenario}{A scenario identifier (see \code{sim_scenarios()}) or a scenario object.}
  \item{params}{Named list of parameters that replace the defaults. Unknown
    names and invalid values are rejected.}
  \item{n_sim}{Number of replicates.}
  \item{seed}{Seed of the random number stream.}
  \item{alpha}{Significance level for rejection rates.}
  \item{keep_states}{Store the RNG state at the start of each replicate, so
    that \code{sim_replicate} can regenerate any replicate.}
  \item{id}{Scenario identifier (letters, digits, underscore).}
  \item{title, aim, dgm_text, estimand}{Plain-text ADEMP description.}
  \item{dgm}{\code{function(params)} returning one simulated data set.}
  \item{truth}{Value of the estimand, or \code{function(params)}.}
  \item{methods}{Named list of \code{function(data, params)}, each returning a
    named numeric vector with any of \code{est}, \code{se}, \code{lower},
    \code{upper}, \code{p}, \code{reject}.}
  \item{param_text}{Named description of each parameter.}
  \item{check}{\code{function(params)} that stops on invalid parameters.}
  \item{references, version}{Sources of the scenario and its version.}
  \item{x}{A result of \code{sim_run}.}
  \item{i}{Replicate number.}
  \item{file}{File to write; when \code{NULL} the text is returned.}
  \item{include_raw}{Add the replicate-level results to the JSON record.}
  \item{digits}{Decimals in the printed report.}
  \item{...}{Not used.}
}
\details{
\strong{Random numbers.} A run uses one stream: the RNG kind is fixed to
Mersenne-Twister / Inversion / Rejection and \code{set.seed(seed)} is called
once. The RNG kind and state of the caller are restored afterwards.

\strong{Failures.} An error in data generation or in a method is caught,
stored with the replicate and counted per method; the run continues
(\code{record$failed}). Failed replicates are excluded from the measures.

\strong{Run record.} \code{record} holds the scenario and its version, the
ADEMP description, the true value, all parameters, \code{n_sim}, seed,
\code{alpha}, RNG kind, R version, package version, platform, start time and
duration. \code{sim_record_json} writes it as JSON; numbers are written with
the shortest text that reads back to exactly the same value.
\code{sim_export_script} writes the run as a stand-alone R script that
reproduces it exactly (for heavy runs on the user's own computer; a larger
\code{n_sim} can be given).

\strong{Built-in scenarios.} \code{"demo_mean_ci"}: coverage of the t and z
confidence intervals for a mean and type I error of the t test (parameters
\code{n}, \code{mu}, \code{sigma}, \code{dist}, \code{conf}). With normal data
the true values are known exactly (t coverage = \code{conf}; z coverage =
\eqn{2F_{t,n-1}(z_{(1+conf)/2}) - 1}), which makes it the analytic test case
of the framework; with log-normal data it shows the effect of skewness.
}
\value{
\code{sim_run}: a list of class \code{"farmastat_sim"} with \code{record},
\code{performance} (method, measure, estimate, mcse), \code{raw} (one row per
replicate and method) and \code{states}.
}
\references{
Morris TP, White IR, Crowther MJ (2019). Using simulation studies to evaluate
statistical methods. Stat Med 38:2074--2102.
}
\seealso{\code{\link{sim_performance}}}
\examples{
sim_scenarios()

# Default parameters (n = 10, normal data)
r <- sim_run("demo_mean_ci", n_sim = 1000, seed = 2026)
r

# The user's own setting: n = 125, log-normal data
r2 <- sim_run("demo_mean_ci", params = list(n = 125, dist = "lognormal"),
              n_sim = 1000, seed = 2026)
r2$performance

# Reproduce elsewhere
cat(sim_export_script(r2))
substr(sim_record_json(r2), 1, 200)
}
