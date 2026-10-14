\name{calc_f2_boot}
\alias{calc_f2_boot}
\alias{print.farmastat_f2boot}
\alias{f2_estimators}
\alias{f2_export_indices}
\title{f2, expected f2 and bootstrap f2 with EMA and FDA perspectives}
\description{
Checks the applicability conditions of the similarity factor f2, computes the
point estimates f2, expected f2 and bias-corrected f2, and the bootstrap 90\%
confidence interval used for the similarity decision (EMA Q&A 3.11; Ma et al.
2000; Xu et al. 2021).
}
\usage{
calc_f2_boot(test, ref, times, perspektif = c("EMA", "FDA"),
             tahminci = NULL, truncation = NULL, cv_rule = NULL, B = NULL,
             ga_tipi = c("persentil", "BCa"), kesme_modu = c("replika", "sabit"),
             seed = 20260927, q_type = 7, conf = 0.90, idx = NULL)

f2_estimators(XT, XR)

f2_export_indices(s, dosya)

\method{print}{farmastat_f2boot}(x, ...)
}
\arguments{
  \item{test, ref}{Unit-by-time matrices of percent dissolved. Missing values
    are allowed; see Details.}
  \item{times}{Time points \strong{in minutes} (the CV and 15-minute rules
    assume minutes). A time point 0 is removed.}
  \item{perspektif}{Perspective (preset). \code{"EMA"}: expected f2, EMA
    truncation, ICH M9 CV rule, \code{B = 5000}, percentile interval
    (EMA Q&A 3.11). \code{"FDA"}: classic f2, FDA truncation, FDA 1997 CV rule,
    \code{B = 10000}, percentile interval. The FDA preset follows FDA scientific
    presentations (Gong 2020; Mandula 2019) and is not official FDA policy.
    Arguments given explicitly override the preset.}
  \item{tahminci}{Estimator used for the decision: \code{"Ef2"} (expected
    f2), \code{"f2"} (classic) or \code{"bcf2"} (bias-corrected).
    \code{NULL} takes the preset.}
  \item{truncation}{85\% truncation of time points, applied to the mean
    profiles: \code{"EMA"} (up to the first point where \emph{either} product
    exceeds 85\%; EMA 2010 App. I item 4), \code{"FDA"} (where \emph{both}
    exceed 85\%; FDA 1997 V.A) or \code{"none"}. \code{NULL} takes the preset.}
  \item{cv_rule}{Coefficient of variation condition for classic f2:
    \code{"M9"} (at most 20\% up to 10 minutes, 10\% afterwards; ICH M9),
    \code{"AppI"} (first point below 20\%, others below 10\%; EMA 2010 App. I)
    or \code{"FDA97"} (20\% at early points, 10\% at others; "early" read as up
    to 15 minutes, a FarmaStatR interpretation). \code{NULL} takes the preset.}
  \item{B}{Number of bootstrap samples (EMA Q&A 3.11: at least 5000). \code{NULL} takes the preset.}
  \item{ga_tipi}{Confidence interval type: \code{"persentil"} (percentile, as
    required by EMA Q&A 3.11) or \code{"BCa"} (jackknife BCa; Xu et al. 2021,
    equations 21--24). Xu et al. report that classic f2 with BCa can inflate the
    type I error; a warning is added.}
  \item{kesme_modu}{\code{"replika"}: truncation is re-applied in every
    bootstrap replicate; \code{"sabit"}: the time points selected on the
    original data are kept fixed.}
  \item{seed}{Random number seed; reported with the RNG kind for reproducibility.}
  \item{q_type}{Quantile definition 1--9 of Hyndman and Fan (1996); default 7.}
  \item{conf}{Two-sided confidence level (EMA Q&A 3.11: 0.90).}
  \item{idx}{Optional externally supplied bootstrap indices, for cross-checks with SAS or Python.}
  \item{XT, XR}{Unit-by-time matrices on the selected time points.}
  \item{s}{A result of \code{calc_f2_boot}.}
  \item{dosya}{File name of the CSV to write.}
  \item{x}{A result of \code{calc_f2_boot}.}
  \item{...}{Not used.}
}
\details{
With \eqn{D = \sum (\bar X_T - \bar X_R)^2},
\eqn{V = \sum (S_T^2/n_T + S_R^2/n_R)} and \eqn{P} time points:
\deqn{f_2 = 100 - 25 \log_{10}(1 + D/P)}{f2 = 100 - 25 log10(1 + D/P)}
(EMA 2010 App. I),
\deqn{E(f_2) = 100 - 25 \log_{10}(1 + (D+V)/P)}{E(f2) = 100 - 25 log10(1 + (D+V)/P)}
(EMA Q&A 3.11 equation 1; Ma et al. 2000 equation 9),
\deqn{bc\mbox{-}f_2 = 100 - 25 \log_{10}(1 + (D-V)/P)}{bc-f2 = 100 - 25 log10(1 + (D-V)/P)}
(Noce et al. 2020 equation 2; undefined when \eqn{D \le V}).
The generalization to \eqn{n_T \ne n_R} is a FarmaStatR derivation.

The checks follow the EMA order: time 0 removed; if both products exceed
85\% within 15 minutes the profiles may be accepted as similar without
calculation; 85\% truncation; at least 3 time points (otherwise the function
stops); units with missing values at the selected points are dropped; CV
condition; method recommendation.

\strong{Decision rule} (FarmaStatR decision): the lower confidence limit is
reported with 4 decimals, without rounding. At least 50: similar
(\code{"BENZER"}); from 49.5 to below 50: borderline case, assessor judgement
needed (\code{"SINIR VAKA"}); below 49.5: not similar (\code{"BENZER DEĞİL"}).
When the lower limit is within 2 Monte Carlo standard errors of 50 the result
is flagged as seed-sensitive.

\code{f2_estimators} returns the three point estimates and \eqn{D}, \eqn{V},
\eqn{P}. \code{f2_export_indices} writes the bootstrap indices of a result in
long format to a CSV file.
}
\value{
A list of class \code{"farmastat_f2boot"}. Main elements:
\item{karar}{Decision text (see Details).}
\item{karar_ga}{Decision interval (\code{alt}, \code{ust}) for the chosen estimator and interval type.}
\item{mc}{Monte Carlo uncertainty of the lower limit, including \code{MCSE}.}
\item{seed_duyarli}{\code{TRUE} if the decision is seed-sensitive.}
\item{nokta}{Point estimates \code{f2}, \code{Ef2}, \code{bcf2} and \code{D}, \code{V}, \code{P}.}
\item{GA}{Percentile intervals, valid replicate counts and bootstrap means for all three estimators.}
\item{replikalar}{Bootstrap replicate values.}
\item{kontrol}{Results of the applicability checks: selected time points,
  CV table, notes and the method recommendation (\code{oneri}).}
\item{B, seed, rng, q_type, conf, perspektif, tahminci, ga_tipi, kesme_modu}{Settings used, for reproducibility.}
\item{bca}{BCa components (\code{z0}, \code{a}, jackknife values) when \code{ga_tipi = "BCa"}.}
\item{ema_tamsayi}{Lower limit rounded to an integer (EMA reporting format; information only).}
\item{uyarilar, regulatif}{Warnings and the regulatory status text (EMA, FDA).}
}
\references{
EMA (2010) CPMP/EWP/QWP/1401/98 Rev. 1, Appendix I.
EMA PKWP/BSWP Q&A 3.11.
FDA (1997) Dissolution Testing of Immediate Release Solid Oral Dosage Forms, section V.A.
ICH M9 (2019).
Ma M-C, Wang BBC, Liu J-P, Tsong Y (2000) J Biopharm Stat 10:229--249.
Hyndman RJ, Fan Y (1996) Am Stat 50:361--365.
Noce L et al. (2020) Eur J Pharm Sci 146:105259.
Xu Z et al. (2021) Comput Methods Programs Biomed 212:106449.
}
\seealso{\code{\link{ornek_noce}}}
\examples{
# Noce et al. (2020), products 1 and 2; small B to keep the example fast
s <- calc_f2_boot(noce_P1, noce_P2, noce_t, B = 1000, seed = 1)
s$karar
s$karar_ga
f2_estimators(s$kontrol$XT, s$kontrol$XR)

\donttest{
# FDA perspective with BCa interval
calc_f2_boot(noce_P1, noce_P2, noce_t, perspektif = "FDA", ga_tipi = "BCa", B = 2000)
}
}
