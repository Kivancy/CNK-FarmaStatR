\name{platform}
\alias{platform}
\alias{platform_check_invitro}
\alias{platform_run_invitro}
\alias{platform_hipotez}
\alias{platform_kk38}
\alias{platform_anahtar}
\alias{platform_sinir_delta}
\alias{platform_export_invitro}
\alias{platform_motor_dosyalari}
\alias{platform_cekirdek_sha}
\title{Platform layer of CNK-FarmaStatR: input check, hypothesis classes, keys and R script export}
\description{
Functions used by the CNK-FarmaStatR web platform around the unchanged, SHA-256
pinned in vitro equivalence engine (\code{\link{invitro_scenario}}). They do not
change any engine result.
\itemize{
  \item \code{platform_check_invitro}, \code{platform_run_invitro}: input check and
    run (FSR-TN-PLT-01 Table 11.1; run-size limit KK-47).
  \item \code{platform_hipotez}, \code{platform_kk38}, \code{platform_sinir_delta},
    \code{platform_anahtar}: true hypothesis class of each method, metric name,
    near-boundary warning, KK-38 label, boundary names and canonical keys
    (FSR-TN-PLT-02).
  \item \code{platform_export_invitro}, \code{platform_motor_dosyalari},
    \code{platform_cekirdek_sha}: one scenario as a stand-alone R script (tier 3,
    FSR-TN-PLT-03).
}
Research and education only; not a system validated for GxP environments.
}
\usage{
platform_check_invitro(params, n_sim_max = 20000, cells_max = 8.1e6)
platform_run_invitro(params, n_sim_max = 20000, cells_max = 8.1e6)

platform_hipotez(sigma_R, rho = 1, delta = NULL, sinir = NULL, sigma_T0 = 0.1,
                 ema_limits = c(0.85, 1.18), tol = 1e-12, yakinlik = 1e-4)
platform_kk38(p_hat, mcse, sinif, nominal = 0.05, z = stats::qnorm(0.95))
platform_sinir_delta(sinir, sigma_R, rho, sigma_T0 = 0.1, ema_limits = c(0.85, 1.18))
platform_anahtar(sigma_R, rho = 1, pB_T = 0, pB_R = pB_T, pL = 0.15, q = 0, l = 3,
                 n = 10, m = 3, delta = NULL, gmr = NULL, sinir = NULL,
                 n_sim = 10000, seed = 20261015, kosu = FALSE)

platform_export_invitro(params, sinir = NULL, dosyalar, cekirdek_sha, kaynak = NULL,
                        file = NULL, zaman = Sys.time(), paket_surumu = NULL)
platform_motor_dosyalari(dizin)
platform_cekirdek_sha(path = system.file("validasyon", "CEKIRDEK_SHA256.txt",
                                         package = "CNKfarmastatr"))
}
\arguments{
  \item{params}{Named list of arguments for \code{invitro_scenario()}.}
  \item{n_sim_max, cells_max}{Platform limits for \code{n_sim} and for
    \eqn{l \cdot n \cdot m \cdot n_{sim}}. The R script uses \code{Inf}.}
  \item{sigma_R, rho, pB_T, pB_R, pL, q, l, n, m}{Scenario parameters as in
    \code{invitro_scenario()}.}
  \item{delta}{True mean difference \eqn{\mu_T - \mu_R} (log scale).}
  \item{gmr}{Geometric mean ratio; converted once to \code{log(gmr)}.}
  \item{sinir}{Boundary name: \code{"fda_delta0"}, \code{"fda_minus_delta0"},
    \code{"ema_1.18"}, \code{"ema_0.85"}, \code{"gmr_1.00"}, \code{"gmr_1.05"}.
    The value is computed in R.}
  \item{sigma_T0, ema_limits}{FDA constant and EMA limits.}
  \item{tol}{Absolute tolerance for boundary classes (FSR-TN-PLT-01 Section 5.3,
    D-02, KK-45).}
  \item{yakinlik}{Near-boundary warning: \eqn{|\delta - \delta_{boundary}| \le}
    \code{yakinlik} (P2-K1 (b), KK-49).}
  \item{p_hat, mcse, sinif}{Estimated rate, its Monte Carlo SE and the hypothesis class.}
  \item{nominal, z}{Nominal level and normal quantile of the KK-38 label.}
  \item{n_sim, seed, kosu}{\code{kosu = TRUE} gives the run key (scenario key plus
    \code{n_sim} and \code{seed}).}
  \item{dosyalar}{Named list of raw vectors: \code{sim_run.R}, \code{invitro_fast.R},
    \code{invitro_grid.R}, \code{platform_input.R}, \code{platform_hipotez.R}.}
  \item{cekirdek_sha}{Pinned SHA-256 values, \code{platform_cekirdek_sha()}.}
  \item{kaynak}{Optional named list of scalars describing the source run.}
  \item{file}{File to write the script to (UTF-8, LF line ends).}
  \item{zaman}{Time of export; the only line that differs between two calls.}
  \item{paket_surumu}{Package version written into the script.}
  \item{dizin}{Folder holding the R source files (\code{<repository>/CNKfarmastatr/R}).}
  \item{path}{Path of \code{CEKIRDEK_SHA256.txt}.}
}
\value{
\code{platform_check_invitro}: data frame of problems (\code{field}, \code{code},
\code{message}); no rows means valid. \code{platform_run_invitro}: the one-row
result of \code{invitro_scenario()}, or an error of class
\code{farmastat_input_error}. \code{platform_hipotez}: one row per scenario and
method (\code{fda}, \code{ema_a}, \code{ema_b}, \code{ema_c}).
\code{platform_export_invitro}: the script text. The script verifies the SHA-256
of the five embedded files, loads them into a new environment and calls the
unchanged engine; it writes the result (\code{.csv}, exact numbers) and a run
record (\code{.json}).
}
\references{
FDA (2025). Draft Guidance on Budesonide, PSG 020929.

EMA (2025). CPMP/EWP/4151/00 Rev. 2.

Morris TP, White IR, Crowther MJ (2019). Using simulation studies to evaluate
statistical methods. \emph{Statistics in Medicine} 38:2074-2102.
}
\examples{
h <- platform_hipotez(0.12, rho = 1, sinir = c("fda_delta0", "ema_1.18"))
h[, c("senaryo", "yontem", "sinif", "metrik")]
platform_anahtar(0.12, gmr = 1.05, n_sim = 2000, kosu = TRUE)
}
