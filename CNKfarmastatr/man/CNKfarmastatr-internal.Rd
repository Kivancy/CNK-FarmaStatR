\name{CNKfarmastatr-internal}
\alias{CNKfarmastatr-internal}
\alias{msd_engine}
\alias{msd_pooled_cov}
\alias{msd_distance}
\alias{msd_truncate}
\alias{msd_boxM}
\alias{weibull_F}
\alias{z_weibull}
\alias{weibull_fit_units}
\alias{elips_uc}
\alias{sathe_lot_bilesen}
\alias{PARAMLAR}
\alias{f2_checks}
\alias{f2_truncate}
\alias{f2_boot_indices}
\alias{f2_boot_replicates}
\alias{f2_jackknife}
\alias{bca_alpha}
\alias{bca_bilesenler}
\alias{f2_karar}
\alias{mc_quantile_se}
\alias{hf_quantile}
\title{Internal functions of CNKfarmastatr}
\description{
Building blocks of the validated models, called by the documented main
functions. They are visible because all functions of the inherited validated
source files are exported (to be reviewed for v1.0.0) and because the
validation test sets call some of them directly. They are not intended to be
called by users; their interfaces may change.
}
\details{
\describe{
  \item{MSD (\code{\link{calc_msd}}, \code{\link{calc_msd_weibull}})}{
    \code{msd_engine} (common Hotelling \eqn{T^2} calculation),
    \code{msd_pooled_cov}, \code{msd_distance}, \code{msd_truncate},
    \code{msd_boxM}; \code{weibull_F}, \code{z_weibull},
    \code{weibull_fit_units}, \code{elips_uc} (extremes of a function on the
    confidence ellipse), \code{sathe_lot_bilesen} (reference-lot components),
    \code{PARAMLAR} (parametrization names).}
  \item{f2 (\code{\link{calc_f2_boot}})}{
    \code{f2_checks} (applicability checks), \code{f2_truncate},
    \code{f2_boot_indices}, \code{f2_boot_replicates}, \code{f2_jackknife},
    \code{bca_alpha}, \code{bca_bilesenler}, \code{f2_karar} (decision rule),
    \code{mc_quantile_se} (Monte Carlo error of a quantile),
    \code{hf_quantile} (independent implementation of the Hyndman and Fan
    quantiles, compared with \code{stats::quantile} in validation).}
}
}
\keyword{internal}
