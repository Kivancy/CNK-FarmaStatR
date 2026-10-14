\name{ornek_veri}
\alias{ornek_veri}
\alias{ornek_tsong}
\alias{ornek_noce}
\alias{ornek_psg020929}
\alias{uzun_format}
\alias{noce_t}
\alias{noce_P1}
\alias{noce_P2}
\alias{noce_P3}
\title{Example data from the validation sources}
\description{
Published data sets used in the validation of the models ("örnek veri" =
example data).
}
\usage{
ornek_tsong()
ornek_noce()
ornek_psg020929()
uzun_format(M, urun, zamanlar)
noce_t
noce_P1
noce_P2
noce_P3
}
\arguments{
  \item{M}{Unit-by-time matrix.}
  \item{urun}{Product label.}
  \item{zamanlar}{Time points.}
}
\details{
\describe{
  \item{\code{ornek_tsong()}}{Tsong et al. (1996), Table 1 (products
    \code{"TEST"} and \code{"REF"}) and Table 3 (standard lots \code{"STD1"},
    \code{"STD2"}): 6 tablets at 5, 10, 15, 20, 30, 60, 90 and 120 minutes.
    Reference tablet 4 at 30 minutes is 78.45 instead of the printed 78.54;
    only the corrected value reproduces the published \eqn{D_M}, confidence
    region and \eqn{T^2}. Validation data of \code{\link{calc_msd}} and
    \code{\link{calc_msd_weibull}}.}
  \item{\code{ornek_noce()}, \code{noce_t}, \code{noce_P1}--\code{noce_P3}}{Noce
    et al. (2020), Table 1: products 1--3, 12 tablets at 9 time points (minutes).
    \code{ornek_noce()} returns them in long format. Validation data of
    \code{\link{calc_f2_boot}}.}
  \item{\code{ornek_psg020929()}}{Example data of FDA PSG 020929 (budesonide,
    December 2025), Appendix: 180 observations, batches 1--3 reference and
    4--6 test, 10 containers per batch, life stages B, M, E; measurements on
    the log scale. Validation data of \code{\link{calc_pbe}}.}
  \item{\code{uzun_format()}}{Converts a unit-by-time matrix to long format.}
}
}
\value{
Long-format data frames with columns \code{Product}, \code{Unit},
\code{Time}, \code{Diss} (dissolution) or \code{Batches}, \code{Container},
\code{Stage}, \code{Product}, \code{score} (PBE); \code{noce_t} is a numeric
vector and \code{noce_P1}--\code{noce_P3} are matrices.
}
\references{
Tsong Y et al. (1996) Drug Inf J 30:1105--1112.
Noce L et al. (2020) Eur J Pharm Sci 146:105259.
FDA. Draft Guidance on Budesonide Inhalation Suspension, PSG 020929 (revised December 2025), Appendix.
}
\examples{
head(ornek_tsong())
table(ornek_noce()$Product)
str(ornek_psg020929())
}
