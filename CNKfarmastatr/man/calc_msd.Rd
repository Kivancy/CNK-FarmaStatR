\name{calc_msd}
\alias{calc_msd}
\alias{print.farmastat_msd}
\title{Model-independent multivariate statistical distance (MSD) for dissolution profiles}
\description{
Compares the mean dissolution profiles of a test and a reference product with
the Mahalanobis distance \eqn{D_M} and the Hotelling \eqn{T^2} based 90\%
confidence region (FDA 1997, section V.B; Tsong et al. 1996, equations 2--3).
The profiles are declared similar when the upper confidence limit of
\eqn{D_M} does not exceed the similarity limit \eqn{R_D}.
}
\usage{
calc_msd(test, ref, limit = c("L1", "L2a", "L2b"), Dg = 10,
         ref_lots = NULL, truncation = c("none", "FDA", "EMA"), conf = 0.90)

\method{print}{farmastat_msd}(x, digits = 4, ...)
}
\arguments{
  \item{test, ref}{Numeric matrices, one row per dosage unit and one column per
    time point (percent dissolved). Both must have the same time points, at
    least 2 units each and no missing values. \code{\link{msd_prepare}}
    builds them from long-format data.}
  \item{limit}{How the similarity limit \eqn{R_D} is set:
    \describe{
      \item{\code{"L1"}}{fixed global difference \code{Dg} at every time point,
        \eqn{R_D = \sqrt{g' S^{-1} g}} with \eqn{g = D_g 1} (Tsong et al. 1996, p. 1109).}
      \item{\code{"L2a"}}{\code{Dg} is taken as the largest absolute mean
        difference between any two reference lots (FarmaStatR derivation of
        FDA 1997 V.B step 1).}
      \item{\code{"L2b"}}{\eqn{R_D} is the largest MSD between any two
        reference lots (FarmaStatR derivation; literal reading of FDA 1997
        V.B step 1).}
    }}
  \item{Dg}{Global difference in percent dissolved used by \code{"L1"}, and
    the bound of the L3 hypercube check. Default 10 (EMA 2010, App. I).}
  \item{ref_lots}{For \code{"L2a"} and \code{"L2b"}: a list of at least two
    unit-by-time matrices of reference lots, preferably named.}
  \item{truncation}{Which time points enter the analysis: \code{"none"} (all;
    the Tsong 1996 examples), \code{"FDA"} (only one point after both products
    exceed 85\%; FDA 1997 V.A) or \code{"EMA"} (up to and including the point
    where either product exceeds 85\%; EMA 2010 App. I). The guidelines define
    these rules for f2; applying them to MSD is a FarmaStatR design decision.}
  \item{conf}{Confidence level of the region. Default 0.90 (FDA 1997 V.B step 3).}
  \item{x}{A result of \code{calc_msd}.}
  \item{digits}{Number of decimals in the printed report.}
  \item{...}{Not used.}
}
\details{
The pooled covariance is
\eqn{S = [(n_T-1) S_T + (n_R-1) S_R] / (n_T+n_R-2)}, which reduces to
Tsong's \eqn{(S_1+S_2)/2} for equal sample sizes. The number of time points
\eqn{P} may not exceed \eqn{n_T + n_R - 2}; a nearly singular \eqn{S}
(condition number above \eqn{10^{10}}) stops the calculation.

The \emph{L3 hypercube check} is always reported: for every time point the
extreme point of the confidence ellipsoid, \eqn{|d_t| + r \sqrt{S_{tt}}}, must
not exceed \code{Dg} (FarmaStatR derivation of the 10\% condition of EMA 2010,
App. I). When the MSD and L3 decisions disagree, the printed report says so.

Box's M test is given for information only and is undefined when
\eqn{n - 1 < P} within a product.
}
\value{
A list of class \code{"farmastat_msd"}. Main elements:
\item{DM, T2}{Mahalanobis distance \eqn{D_M} and Hotelling \eqn{T^2}.}
\item{DM_l, DM_u}{Lower and upper confidence limits of \eqn{D_M}.}
\item{K, F, df, r}{Scaling constant, F quantile, its degrees of freedom and the radius \eqn{\sqrt{F/K}}.}
\item{RD, Dg, sinir_aciklama}{Similarity limit, global difference used and a description of the limit.}
\item{benzer_msd}{\code{TRUE} if \code{DM_u <= RD} (similar; FDA 1997 V.B step 4).}
\item{L3, benzer_L3, Dg_L3}{Per-time-point L3 table, its decision and bound.}
\item{d, S, ort_T, ort_R}{Mean difference (test minus reference), pooled covariance and mean profiles.}
\item{girdi}{Sample sizes, time points used and excluded, settings.}
\item{lot_bilgi}{For L2a/L2b: pairwise reference lot comparisons.}
\item{tani, boxM}{Coefficients of variation per time point and Box's M.}
\item{uyarilar, regulatif}{Warnings and the regulatory status text (FDA, EMA).}
}
\references{
FDA (1997) Dissolution Testing of Immediate Release Solid Oral Dosage Forms, section V.B.
Tsong Y et al. (1996) Drug Inf J 30:1105--1112.
EMA Q&A 3.9 (Mahalanobis distance).
}
\seealso{\code{\link{msd_prepare}}, \code{\link{calc_msd_weibull}}, \code{\link{ornek_tsong}}}
\examples{
d <- ornek_tsong()
p <- msd_prepare(d[d$Product \%in\% c("TEST", "REF"), ])
calc_msd(p$test, p$ref, limit = "L1", Dg = 10)

# Similarity limit from two reference lots (L2a)
lots <- list(
  STD1 = msd_prepare(transform(d[d$Product == "STD1", ], Product = "REF"))$ref,
  STD2 = msd_prepare(transform(d[d$Product == "STD2", ], Product = "REF"))$ref)
r <- calc_msd(p$test, p$ref, limit = "L2a", ref_lots = lots)
r$Dg
r$benzer_msd
}
