\name{invitro_scenario}
\alias{invitro_scenario}
\alias{invitro_delta0}
\alias{invitro_run_record}
\title{One scenario of the in vitro equivalence simulation grid}
\description{
Simulates one data-generating mechanism and applies FDA PBE and the three
EMA confidence-interval methods to the same data sets; returns performance
measures with Monte Carlo standard errors (Morris, White and Crowther 2019,
Table 6). Every scenario starts from the same seed (common random numbers).
}
\usage{
invitro_scenario(sigma_R, rho = 1, pB = 0, pL = 0.15, q = 0,
                 l = 3, n = 10, m = 3, delta = 0,
                 pB_T = pB, pB_R = pB, n_sim = 10000, seed = 20261015,
                 alpha = 0.05, sigma_T0 = 0.1, ema_limits = c(0.85, 1.18))
invitro_delta0(sigma_R, rho = 1, sigma_T0 = 0.1)
invitro_run_record(grid_id, seed, n_sim)
}
\arguments{
  \item{sigma_R}{Total SD of the reference (log scale).}
  \item{rho}{\eqn{\sigma_T/\sigma_R}.}
  \item{pB, pL, q}{Batch share, life-stage share, drift share
    (see \code{\link{invitro_components}}).}
  \item{pB_T, pB_R}{Separate batch shares for test and reference.}
  \item{l, n, m}{Batches, units per batch, life stages (same for T and R).}
  \item{delta}{True mean difference \eqn{\mu_T - \mu_R} (log scale).}
  \item{n_sim}{Number of simulated data sets.}
  \item{seed}{Seed (Mersenne-Twister, Inversion).}
  \item{alpha, sigma_T0}{PBE constants.}
  \item{ema_limits}{EMA acceptance limits.}
  \item{grid_id}{Label of the run.}
}
\details{
\code{invitro_delta0} returns the mean difference at which the PBE
criterion \eqn{\eta} equals 0 (technical note FSR-TN-PBE-01, Eq. 11); it is
used for the FDA type I error.
}
\value{
\code{invitro_scenario}: one-row data frame with the parameters and, each
with an \code{_mcse} column: \code{fda_pass}, \code{fda_crit_err},
\code{fda_cover}, \code{fda_bias_Eq}, \code{fda_bias_s2R},
\code{ema_a_pass}, \code{ema_a_cover} (and \code{b}, \code{c}).
\code{invitro_delta0}: number (\code{NA} if the boundary cannot be reached).
\code{invitro_run_record}: one-row data frame (seed, RNG kind, R and package
versions, time).
}
\references{
Morris TP, White IR, Crowther MJ (2019). Using simulation studies to evaluate
statistical methods. \emph{Statistics in Medicine} 38:2074-2102.
}
\note{Research and education only; not a system validated for GxP environments.}
\seealso{\code{\link{pbe_fast}}, \code{\link{ema_ci_fast}}}
\examples{
invitro_scenario(0.12, pB = 0.1, delta = invitro_delta0(0.12), n_sim = 500)
}
