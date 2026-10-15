\name{invitro_fast}
\alias{invitro_fast}
\alias{invitro_gen}
\alias{invitro_components}
\alias{invitro_drift}
\alias{invitro_array}
\alias{pbe_fast}
\alias{ema_ci_fast}
\title{Fast in vitro equivalence engine for balanced designs (FDA PBE, EMA CI)}
\description{
Vectorised versions of the procedures studied in technical note
FSR-TN-PBE-01, for use inside simulations. \code{invitro_gen} simulates
balanced data from the model
\eqn{X_{ijs} = \mu + b_j + c_{ij} + \tau_s + e_{ijs}} (batch \eqn{j},
unit \eqn{i}, life stage \eqn{s}); \code{pbe_fast} applies the FDA PSG 020929
population bioequivalence procedure and returns the same quantities as
\code{\link{calc_pbe}}; \code{ema_ci_fast} computes the 90\% confidence
interval of the test/reference geometric mean ratio (EMA CPMP/EWP/4151/00
Rev. 2, Section 5.1, criterion 8) in three ways.
}
\usage{
invitro_gen(R, l, n, m, mu = 0, sB = 0, sC = 0, sW = 0, tau = rep(0, m))
invitro_components(sigma, pB, pL, q = 0)
invitro_drift(m, drift_var)
invitro_array(df, product)
pbe_fast(XT, XR, lT, nT, lR, nR, alpha = 0.05, sigma_T0 = 0.1)
ema_ci_fast(XT, XR, lT, nT, lR, nR, level = 0.90,
            limits = c(0.85, 1.18), methods = c("a", "b", "c"))
}
\arguments{
  \item{R}{Number of simulated data sets (replicates).}
  \item{l, n, m}{Batches, units per batch, life stages.}
  \item{mu}{Product mean (log scale).}
  \item{sB, sC, sW}{Standard deviations of batch, unit-within-batch and
    within-unit (life stage) effects.}
  \item{tau}{Fixed stage effects (systematic drift), length \code{m}.}
  \item{sigma}{Total standard deviation.}
  \item{pB, pL}{Batch and life-stage shares of the total variance.}
  \item{q}{Share of the life-stage component that is systematic drift.}
  \item{drift_var}{Variance of the drift, \eqn{(1/m)\sum\tau_s^2}.}
  \item{df}{Long data in the \code{calc_pbe} layout (batch, container, stage,
    product, score).}
  \item{product}{Product label to extract.}
  \item{XT, XR}{Arrays \code{[replicate, unit, stage]} for test and reference;
    units ordered batch by batch.}
  \item{lT, nT, lR, nR}{Batches and units per batch for test and reference.}
  \item{alpha}{One-sided level of the PBE upper bound (PSG: 0.05).}
  \item{sigma_T0}{Regulatory constant (PSG: 0.1).}
  \item{level}{Confidence level of the EMA interval.}
  \item{limits}{Acceptance limits for the ratio.}
  \item{methods}{\code{"a"} pooled units, \code{"b"} batch means,
    \code{"c"} REML (batch and unit random, stage fixed).}
}
\details{
\code{pbe_fast} is tested against \code{calc_pbe} (relative difference
below \eqn{10^{-12}}, tests TC-F1, TC-F2). For method \code{"c"} the REML
estimates in a balanced design are the degrees-of-freedom weighted isotonic
regression of the mean squares of the batch, unit-within-batch and residual
strata (FarmaStatR derivation); the variance of the product mean is
\eqn{\hat\theta_{batch}/(lnm)}. Test and reference variances are combined
with Welch-Satterthwaite degrees of freedom. The result was checked against
numerical REML (TC-F4) and SAS PROC MIXED (technical note, Appendix B.1).
\code{invitro_gen} draws standard normal deviates for every component, so
scenarios started from the same seed share their random numbers even when a
component is zero.
}
\value{
\code{invitro_gen}: array \code{R x (l n) x m}. \code{invitro_components}:
list \code{sB, sC, sW, drift_var}. \code{invitro_drift}: numeric vector.
\code{invitro_array}: list \code{X, l, n, m}. \code{pbe_fast}: data frame,
one row per replicate (mean squares, \code{Eq}, \code{Uq}, \code{H_eta} for
both criteria, \code{ref_scaled}, \code{pass}). \code{ema_ci_fast}: named
list of data frames (\code{gmr, lower, upper, se, df, pass}).
}
\references{
FDA (2025). Draft Guidance on Budesonide, PSG 020929.

EMA (2025). CPMP/EWP/4151/00 Rev. 2.

Searle SR, Casella G, McCulloch CE (2006). \emph{Variance Components}. Wiley.
}
\note{Research and education only; not a system validated for GxP environments.}
\seealso{\code{\link{calc_pbe}}, \code{\link{invitro_scenario}}}
\examples{
set.seed(1)
XT <- invitro_gen(100, 3, 10, 3, mu = 0.05, sB = 0.05, sC = 0.1, sW = 0.04)
XR <- invitro_gen(100, 3, 10, 3, sB = 0.05, sC = 0.1, sW = 0.04)
mean(pbe_fast(XT, XR, 3, 10, 3, 10)$pass)
sapply(ema_ci_fast(XT, XR, 3, 10, 3, 10), function(x) mean(x$pass))
}
