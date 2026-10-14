\name{calc_msd_weibull}
\alias{calc_msd_weibull}
\alias{calc_msd_params}
\alias{print.farmastat_msd_weibull}
\title{Weibull model-dependent multivariate statistical distance}
\description{
Model-dependent comparison of dissolution profiles (FDA 1997, section V.C;
Sathe et al. 1996). A two-parameter Weibull model is fitted to every dosage
unit, and the test and reference products are compared on the fitted
parameters with the same Hotelling \eqn{T^2} confidence region as
\code{\link{calc_msd}}. \code{calc_msd_params} performs the comparison when
the unit-level parameters are already available.
}
\usage{
calc_msd_weibull(test, ref, times, ref_lots = NULL, param = PARAMLAR, ...)

calc_msd_params(thetaT, thetaR, param = PARAMLAR,
                region = c("B-L2a", "B-L2b", "B-L3"), lot_theta = NULL,
                k_sd = 3, sr_bolen = c("N", "sqrtN"), sr_conf = 0.99,
                times = NULL, Dg = 10, conf = 0.90)

\method{print}{farmastat_msd_weibull}(x, digits = 4, ...)
}
\arguments{
  \item{test, ref}{Unit-by-time matrices of percent dissolved (see \code{\link{msd_prepare}}).}
  \item{times}{Time points in the column order of \code{test} and \code{ref}.}
  \item{ref_lots}{List of unit-by-time matrices of reference lots; required by
    regions \code{"B-L2a"} and \code{"B-L2b"}.}
  \item{param}{Parameter vector on which the distance is computed; one of
    \code{PARAMLAR = c("lnTd_lnB", "lnA_lnB", "lnA_B")}, the first being the default:
    \describe{
      \item{\code{"lnTd_lnB"}}{(ln \eqn{T_d}, ln \eqn{\beta}), the default.
        \eqn{T_d} is Langenbucher's dissolution time (63.2\% dissolved),
        \eqn{\ln T_d = -\ln\alpha/\beta}. The result does not depend on the time
        unit (FarmaStatR derivation).}
      \item{\code{"lnA_lnB"}}{(ln \eqn{\alpha}, ln \eqn{\beta}) as in Sathe et
        al. (1996); use it to reproduce the published results.}
      \item{\code{"lnA_B"}}{(ln \eqn{\alpha}, \eqn{\beta}).}
    }}
  \item{...}{Passed from \code{calc_msd_weibull} to \code{calc_msd_params}
    (\code{region}, \code{k_sd}, \code{sr_bolen}, \code{sr_conf}, \code{Dg}, \code{conf}).}
  \item{thetaT, thetaR}{Unit-by-parameter matrices (at most 3 parameters; FDA 1997 V.C).}
  \item{region}{Similarity region:
    \describe{
      \item{\code{"B-L2a"}}{the default. Sathe box: every projection interval
        \eqn{d_j \pm r\sqrt{S_{jj}}} must lie within \eqn{\pm k \cdot SD_j}, where
        \eqn{SD_j} is the pooled reference-lot standard deviation (Sathe et al.
        1996, p. 1800--1801). Needs reference lots.}
      \item{\code{"B-L2b"}}{Sathe appendix ellipse built from the between-lot and
        within-lot covariances; the confidence ellipse must lie inside it.
        Needs reference lots; two parameters only.}
      \item{\code{"B-L3"}}{response space: at every observed time point, the
        predicted profile anywhere on the confidence ellipse may differ from
        the reference profile by at most \code{Dg} (FarmaStatR derivation of
        EMA 2010 App. I; Muselík et al. 2021). Two parameters only.}
    }}
  \item{lot_theta}{List of unit-by-parameter matrices of reference lots (at least 2).}
  \item{k_sd}{Half-width of the Sathe box in pooled standard deviations (Sathe: 1, 2 or 3).}
  \item{sr_bolen}{Divisor of the within-lot covariance in B-L2b: \code{"N"}
    (default) or \code{"sqrtN"} (literal reading of Sathe's appendix, possibly
    a typesetting error).}
  \item{sr_conf}{Confidence level of the B-L2b region (Sathe: 0.99).}
  \item{Dg}{Response bound of B-L3 in percent dissolved (EMA 2010: 10).}
  \item{conf}{Confidence level of the Hotelling region (FDA 1997 V.C step 5: 0.90).}
  \item{x}{A result of \code{calc_msd_weibull} or \code{calc_msd_params}.}
  \item{digits}{Number of decimals in the printed report.}
}
\details{
Each unit is fitted by least squares on the linearized model
\eqn{\ln(-\ln(1 - X/100)) = \ln\alpha + \beta \ln t}
(Sathe et al. 1996, p. 1800). Points with \eqn{t \le 0},
\eqn{X \le 0} or \eqn{X \ge 100} are excluded; every unit needs at least
3 usable points and, for the logarithmic parametrizations, a positive slope.
}
\value{
A list of class \code{"farmastat_msd_weibull"}. Main elements:
\item{benzer}{Decision: \code{TRUE} if similar.}
\item{aciklama}{Description of the similarity region.}
\item{motor}{Hotelling calculation: \code{d}, \code{S}, \code{DM}, \code{T2},
  \code{DM_l}, \code{DM_u}, \code{r} and the projection intervals \code{izd_alt}, \code{izd_ust}.}
\item{bolge_tablo}{Table of the region check (B-L2a and B-L3).}
\item{lot}{Reference-lot components (B-L2a, B-L2b).}
\item{SR}{B-L2b quantities: largest value on the ellipse, F limit and their ratio.}
\item{uydurma}{Per-unit fits of test and reference (alpha, beta, R2, \eqn{T_d}, excluded points); \code{calc_msd_weibull} only.}
\item{param, region, regulatif}{Settings and the regulatory status text.}
}
\references{
FDA (1997) Dissolution Testing of Immediate Release Solid Oral Dosage Forms, section V.C.
Sathe PM, Tsong Y, Shah VP (1996) Pharm Res 13:1799--1803.
Langenbucher F (1972) J Pharm Pharmacol 24:979--981.
Muselík et al. (2021) Pharmaceutics 13:1703.
}
\seealso{\code{\link{calc_msd}}, \code{\link{ornek_tsong}}}
\examples{
d <- ornek_tsong()
p <- msd_prepare(d[d$Product \%in\% c("TEST", "REF"), ])
lots <- list(
  STD1 = msd_prepare(transform(d[d$Product == "STD1", ], Product = "REF"))$ref,
  STD2 = msd_prepare(transform(d[d$Product == "STD2", ], Product = "REF"))$ref)
times <- c(5, 10, 15, 20, 30, 60, 90, 120)

# Sathe box with the published parametrization
calc_msd_weibull(p$test, p$ref, times, ref_lots = lots,
                 param = "lnA_lnB", region = "B-L2a", k_sd = 3)

# Response-space region, no reference lots needed
w <- calc_msd_weibull(p$test, p$ref, times, region = "B-L3")
w$benzer
}
