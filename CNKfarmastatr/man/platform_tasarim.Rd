\name{platform_tasarim}
\alias{platform_tasarim}
\alias{platform_tasarim_plan}
\alias{platform_tasarim_params}
\alias{platform_tasarim_secim}
\alias{platform_tasarim_dosyalari}
\alias{platform_export_tasarim}
\title{Design selection for a target power (number of batches, units per batch, life stages)}
\description{
Plans the runs of a design search, runs them with the unchanged engine
(\code{\link{invitro_scenario}} through \code{\link{platform_run_invitro}}) and
applies the selection rules of FSR-TN-PBE-01 v0.11 Section 11.5 (FSR-TN-PLT-05
v0.2 Section 3; decisions KK-56, KK-57).
\itemize{
  \item Power is read at the chosen true difference (default GMR 1.05); type I
    error at each method's own boundary (FDA: delta0; EMA: GMR 1.18).
  \item Rule A (Table 11.3a): smallest total \eqn{l n m} with power >= target;
    ties to the smaller \eqn{l}, then the smaller \eqn{m}.
  \item Rule B (Table 11.3b): as A within \eqn{l \ge 3} and \eqn{n \ge 10}, and
    the KK-38 type I error label is not \code{"nominali_asiyor"}.
  \item A method is considered only when it is in H1 at the power difference.
    Cells with \eqn{|power - target| <} 2 MCSE are flagged (KK-39).
}
Every run uses the same seed (common random numbers), so live runs with the
grid's seed and \code{n_sim} reproduce the stored grid counts.
\code{platform_export_tasarim} writes the design search as a stand-alone R script
(tier 3): it carries the six source files, verifies their SHA-256, runs every
planned scenario without the browser limit and writes the tables and a run record.
Research and education only; not a system validated for GxP environments.
}
\usage{
platform_tasarim_plan(pop, l = 2:6, n = c(5, 8, 10, 15, 20, 30), m = 3,
                      guc = list(gmr = 1.05), n_sim = 10000, seed = 20261015,
                      toplam_max = 6e7, n_sim_max = 20000, cells_max = 8.1e6)
platform_tasarim_params(pop, run, n_sim, seed)
platform_tasarim_secim(plan, sonuc, hedef = 0.80, esik_k = 2, l_min = 3, n_min = 10)
platform_tasarim(pop, l = 2:6, n = c(5, 8, 10, 15, 20, 30), m = 3,
                 guc = list(gmr = 1.05), hedef = 0.80, n_sim = 10000,
                 seed = 20261015, toplam_max = 6e7, ilerleme = NULL)
platform_tasarim_dosyalari(dizin)
platform_export_tasarim(pop, l = 2:6, n = c(5, 8, 10, 15, 20, 30), m = 3,
                        guc = list(gmr = 1.05), hedef = 0.80, n_sim = 10000,
                        seed = 20261015, dosyalar, cekirdek_sha, file = NULL,
                        zaman = Sys.time(), paket_surumu = NULL)
}
\arguments{
  \item{pop}{Named list: \code{sigma_R} (required), \code{rho}, \code{pB_T},
    \code{pB_R}, \code{pL}, \code{q}; defaults as in \code{invitro_scenario}.}
  \item{l, n, m}{Candidate values; every combination is a candidate design.}
  \item{guc}{True difference for power: \code{list(gmr = )}, \code{list(delta = )}
    or \code{list(sinir = )} with a boundary name.}
  \item{n_sim, seed}{Monte Carlo settings, the same for every run.}
  \item{toplam_max}{Limit of the total work \eqn{\sum l n m \, n_{sim}} (decision
    P5-K6); \code{NULL} for no limit.}
  \item{n_sim_max, cells_max}{Single-run limits of \code{platform_check_invitro}.}
  \item{run}{One row of the plan.}
  \item{plan}{Result of \code{platform_tasarim_plan}.}
  \item{sonuc}{Data frame of engine results, one row per planned run in plan order.}
  \item{hedef}{Target power.}
  \item{esik_k}{Number of MCSEs for the near-target flag.}
  \item{l_min, n_min}{Regulatory lower limits used by rule B.}
  \item{ilerleme}{Optional function \code{(i, total)} called after each run.}
  \item{dizin}{Folder with the R source files (repository: \code{CNKfarmastatr/R}).}
  \item{dosyalar}{Named list of raw vectors, the six source files.}
  \item{cekirdek_sha}{Pinned SHA-256 values (\code{\link{platform_cekirdek_sha}}).}
  \item{file, zaman, paket_surumu}{Output file (UTF-8, LF), time of export and package
    version written into the script.}
}
\value{
\code{platform_tasarim_plan}: list with \code{ok}, \code{problems} (field, code,
message), \code{plan} (one row per distinct run with its canonical key),
\code{rol} (design and role to run), \code{toplam_hucre} and \code{notlar}.
\code{platform_tasarim_secim}: list with \code{tablo} (one row per design and
method) and \code{secim} (one row per method and rule, with the reason when no
design qualifies). \code{platform_tasarim}: both, plus the engine results.
\code{platform_export_tasarim}: the script text (invisibly when written to a file).
}
\examples{
pl <- platform_tasarim_plan(list(sigma_R = 0.12, pB_T = 0.1), l = 3:4, n = c(10, 15))
pl$toplam_hucre
\donttest{
r <- platform_tasarim(list(sigma_R = 0.12, pB_T = 0.1), l = 3, n = 10, n_sim = 500)
r$secim
}
}
