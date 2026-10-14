\name{sim_performance}
\alias{sim_performance}
\alias{sim_n_required}
\title{Performance measures of a simulation study with Monte Carlo standard errors}
\description{
Computes the performance measures of Morris, White and Crowther (2019,
Table 6), each with its Monte Carlo standard error (MCSE).
\code{sim_n_required} gives the number of replicates needed for a target MCSE.
}
\usage{
sim_performance(est = NULL, truth = NULL, se = NULL, lower = NULL, upper = NULL,
                p = NULL, alpha = 0.05, reject = NULL)

sim_n_required(mcse, p = NULL, var_est = NULL)
}
\arguments{
  \item{est}{Point estimates, one per replicate. Non-finite values are excluded and counted.}
  \item{truth}{True value \eqn{\theta} of the estimand.}
  \item{se}{Model-based standard errors.}
  \item{lower, upper}{Confidence limits.}
  \item{p}{p-values; a replicate rejects when \code{p <= alpha}.}
  \item{alpha}{Significance level.}
  \item{reject}{Logical rejection decisions, used instead of \code{p}.}
  \item{mcse}{Target Monte Carlo standard error.}
  \item{var_est}{Expected variance of the estimates (for bias).}
}
\details{
With \eqn{n} replicates, \eqn{\bar\theta} the mean estimate and
\eqn{s^2 = \sum(\hat\theta_i - \bar\theta)^2/(n-1)}:
\tabular{lll}{
  \strong{Measure} \tab \strong{Estimate} \tab \strong{MCSE} \cr
  \code{bias} \tab \eqn{\bar\theta - \theta} \tab \eqn{\sqrt{s^2/n}} \cr
  \code{empse} \tab \eqn{s} \tab \eqn{s/\sqrt{2(n-1)}} \cr
  \code{mse} \tab \eqn{\frac1n\sum(\hat\theta_i-\theta)^2} \tab \eqn{\sqrt{\sum[(\hat\theta_i-\theta)^2-MSE]^2/(n(n-1))}} \cr
  \code{modse} \tab \eqn{\sqrt{\overline{SE^2}}} \tab \eqn{\sqrt{Var(SE^2)/(4n\,ModSE^2)}} \cr
  \code{relerr_modse} \tab \eqn{100(ModSE/EmpSE-1)} \tab \eqn{100\frac{ModSE}{EmpSE}\sqrt{\frac{Var(SE^2)}{4n\,ModSE^4}+\frac{1}{2(n-1)}}} \cr
  \code{coverage} \tab share of intervals containing \eqn{\theta} \tab \eqn{\sqrt{C(1-C)/n}} \cr
  \code{be_coverage} \tab share containing \eqn{\bar\theta} (bias-eliminated) \tab as coverage \cr
  \code{rejection} \tab share of rejections (power or type I error) \tab \eqn{\sqrt{R(1-R)/n}}
}
\code{sim_n_required} uses \eqn{n = p(1-p)/MCSE^2} for proportions and
\eqn{n = Var(\hat\theta)/MCSE^2} for bias.
}
\value{
\code{sim_performance}: a data frame with columns \code{measure},
\code{estimate}, \code{mcse}; attribute \code{n_missing} gives the number of
excluded estimates. Measures whose inputs are not given are omitted.
\code{sim_n_required}: an integer.
}
\references{
Morris TP, White IR, Crowther MJ (2019). Using simulation studies to evaluate
statistical methods. Stat Med 38:2074--2102, Table 6.
}
\seealso{\code{\link{sim_run}}}
\examples{
sim_performance(est = 1:5, truth = 2.5, se = c(1, 1, 2, 2, 2),
                lower = (1:5) - 1, upper = (1:5) + 1,
                p = c(0.01, 0.04, 0.05, 0.20, 0.90))

# Replicates for coverage near 95\% with MCSE 0.5 percentage points
sim_n_required(mcse = 0.005, p = 0.95)
}
