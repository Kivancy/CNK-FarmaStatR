\name{CNKfarmastatr-package}
\alias{CNKfarmastatr-package}
\alias{CNKfarmastatr}
\docType{package}
\title{CNKfarmastatr: Reproducible Pharmaceutical Statistics for Education and Research}
\description{
Statistical core of the CNK-FarmaStatR platform. Each statistical model is
validated once, against analytic test cases and published examples, and its
source files are pinned by SHA-256 fingerprints.

\strong{For research and education. Not a validated system for GxP environments.}
}
\details{
Models and their main functions:
\tabular{lll}{
  \strong{Model} \tab \strong{Function} \tab \strong{Source} \cr
  Model-independent multivariate statistical distance (MSD) \tab \code{\link{calc_msd}} \tab FDA (1997) V.B; Tsong et al. (1996) \cr
  Weibull model-dependent MSD \tab \code{\link{calc_msd_weibull}} \tab FDA (1997) V.C; Sathe et al. (1996) \cr
  f2, expected f2 and bootstrap f2 \tab \code{\link{calc_f2_boot}} \tab EMA (2010) App. I; EMA Q&A 3.11; Xu et al. (2021) \cr
  In vitro population bioequivalence (PBE) \tab \code{\link{calc_pbe}}, \code{\link{kp_hazirla}} \tab FDA PSG 020929 (budesonide)
}
Example data sets from the validation sources: \code{\link{ornek_tsong}},
\code{\link{ornek_noce}}, \code{\link{ornek_psg020929}}.

\strong{Validation.} The package ships the inherited validation test sets in
\code{system.file("validasyon", package = "CNKfarmastatr")}:
MSD 60, Weibull MSD 98, f2 and bootstrap f2 120, PBE 213 and PBE bridge 25
checks (516 in total). They run with \code{testthat} on every change. The
SHA-256 values of the validated source files are listed in
\code{validasyon/CEKIRDEK_SHA256.txt}.

\strong{Language.} The validated source files were inherited from an earlier
version and are kept unchanged until their first revision. Their argument
values, result element names, messages and printed reports are in Turkish;
this documentation is in English and explains each of them. Methods or
interpretations that are not given directly in a cited source are labelled
\emph{FarmaStatR derivation}.
}
\references{
FDA (1997). Guidance for Industry: Dissolution Testing of Immediate Release
Solid Oral Dosage Forms.

EMA (2010). Guideline on the Investigation of Bioequivalence,
CPMP/EWP/QWP/1401/98 Rev. 1/Corr**, Appendix I.

EMA PKWP/BSWP. Questions and answers on product-specific bioequivalence, Q&A 3.9 and 3.11.

FDA. Draft Guidance on Budesonide, PSG 020929 (in vitro population bioequivalence).

Tsong Y, Hammerstrom T, Sathe P, Shah VP (1996). Statistical assessment of
mean differences between two dissolution data sets. Drug Inf J 30:1105--1112.

Sathe PM, Tsong Y, Shah VP (1996). In-vitro dissolution profile comparison:
statistics and analysis, model dependent approach. Pharm Res 13:1799--1803.
}
\author{Kıvanç Yüksel \email{kivancyuksel@gmail.com}}
\keyword{package}
