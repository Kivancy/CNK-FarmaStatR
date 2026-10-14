\name{calc_pbe}
\alias{calc_pbe}
\title{In vitro population bioequivalence (PBE)}
\description{
Population bioequivalence test of the FDA product-specific guidance on
budesonide inhalation suspension (PSG 020929, revised December 2025,
Appendix): linearized criterion and its 95\% upper confidence bound. Usually
called through the input-checking bridge \code{\link{kp_hazirla}} /
\code{\link{kp_pbe}}; see Warning.
}
\usage{
calc_pbe(df, log_transform = FALSE, one_sided = FALSE)
}
\arguments{
  \item{df}{A data frame with exactly five columns \strong{in this order}:
    batch, container, life stage, product, measurement. The column names are
    replaced by position with \code{Batches}, \code{Container}, \code{Stage},
    \code{Product}, \code{score}. The product column must contain the values
    \code{"TEST"} and \code{"REF"}.}
  \item{log_transform}{If \code{TRUE}, the measurements are log-transformed
    first. If \code{FALSE}, they are assumed to be on the log scale already
    (as in the PSG example data, \code{\link{ornek_psg020929}}).}
  \item{one_sided}{If \code{TRUE} and the test mean is below the reference
    mean, the mean-difference term is set to zero (modified one-sided PBE,
    FDA PSG 020121, Appendix).}
}
\details{
Regulatory constants: \eqn{\sigma_{T0} = 0.1},
\eqn{\theta_p = ((\ln 1.11)^2 + 0.01)/\sigma_{T0}^2 = 2.0891},
\eqn{\alpha = 0.05}. With \eqn{m} life stages, MSB the between-container and
MSW the within-container mean squares, the total standard deviation of a
product is \eqn{\sqrt{MSB/m + (m-1) MSW/m}}.

The reference-scaled criterion is used when \eqn{\sigma_R > \sigma_{T0}},
otherwise the constant-scaled one (PSG 020929 Appendix, step 1). The 95\%
upper bound \eqn{H_\eta = E_q + \sqrt{U_q}} is computed for both; the product
passes when the bound of the applicable criterion is \eqn{\le 0}.

For unbalanced designs (different numbers of containers per batch) the
calculation uses the total number of containers; with a balanced design this
is identical to the PSG formulas (FarmaStatR derivation).
}
\section{Warning}{
\code{calc_pbe} does not check that every container was measured exactly
once at every life stage; with a missing or duplicated stage measurement it
still returns a result (validation test TC-K3). Use
\code{\link{kp_hazirla}} and \code{\link{kp_pbe}}, which reject such data.
}
\value{
A list. Main elements:
\item{pass_fail}{\code{"PASS"} or \code{"FAIL"}.}
\item{criterion}{\code{"Reference-scaled"} or \code{"Constant-scaled"}.}
\item{H_eta_final, Eq_final, Uq_final}{Upper bound and its components for the applicable criterion.}
\item{H_eta_Ref, H_eta_Const}{Upper bounds of both criteria.}
\item{Sigma_R, Sigma_T}{Total standard deviations.}
\item{mean_t, mean_r, msb_t, msw_t, msb_r, msw_r}{Means and mean squares.}
\item{GM_T, GM_R, GMR}{Geometric means and their ratio (meaningful on the log scale only).}
\item{E_D, E1, \ldots, H_D, \ldots, U_D, \ldots}{Intermediate quantities of the upper bound calculation.}
\item{m, l_t, l_r, n_t, n_r, total_t, total_r, bal_t, bal_r}{Design: life stages, batches, containers per batch, total containers, balance.}
\item{SigmaT0, Theta_p, alpha, log_transform, one_sided, one_sided_active}{Constants and settings.}
}
\references{
FDA. Draft Guidance on Budesonide Inhalation Suspension, PSG 020929 (revised December 2025), Appendix.
FDA. Draft Guidance on Fluticasone Propionate Nasal Spray, PSG 020121 (revised December 2025), Appendix (one-sided PBE).
}
\seealso{\code{\link{kp_hazirla}}, \code{\link{ornek_psg020929}}}
\examples{
r <- calc_pbe(ornek_psg020929())
r$criterion
r$H_eta_final
r$pass_fail
}
