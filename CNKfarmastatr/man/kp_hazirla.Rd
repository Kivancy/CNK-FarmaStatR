\name{kp_hazirla}
\alias{kp_hazirla}
\alias{kp_pbe}
\alias{kp_calistir}
\title{PBE bridge: input checks and calculation}
\description{
The bridge between user data and the validated PBE core \code{\link{calc_pbe}}.
\code{kp_hazirla} ("prepare") checks the data and stores it; \code{kp_pbe}
runs the unchanged core on the stored data. \code{kp_calistir} ("run") wraps a
call so that an error is returned as a readable message instead of stopping.
The bridge does not compute anything itself. Validated with 25 checks
(test cases TC-K1 to TC-K4).
}
\usage{
kp_hazirla(parti, kap, asama, urun, deger, test, ref, log_d)
kp_pbe(tek_yonlu)
kp_calistir(ifade)
}
\arguments{
  \item{parti, kap, asama, urun}{Vectors of batch, container, life stage and
    product labels (one element per measurement).}
  \item{deger}{Numeric vector of measurements.}
  \item{test, ref}{Labels in \code{urun} of the test and the reference
    product; other products in the data are ignored.}
  \item{log_d}{\code{TRUE} to log-transform the measurements.}
  \item{tek_yonlu}{\code{TRUE} for the one-sided option of \code{\link{calc_pbe}}.}
  \item{ifade}{An expression, typically a call to \code{kp_hazirla} or \code{kp_pbe}.}
}
\details{
\code{kp_hazirla} stops with a message when: the vectors differ in length;
test and reference are the same product or missing from the data; a batch,
container or stage cell is empty; a measurement is missing or not numeric; a
measurement is zero or negative while \code{log_d = TRUE}; test and reference
have different sets of life stages (PSG 020929 Appendix); a container has a
missing or duplicated stage measurement (FSR-VAL-PBE-1 item B-2); a product
has fewer than 2 containers.

It does not stop, but adds a note to \code{uyarilar}, when the number of containers per batch is
unbalanced, when the products have different numbers of batches, and when a
product has fewer than three batches (recommended by PSG 020929).

\code{kp_pbe} removes the geometric means \code{GM_T}, \code{GM_R} and
\code{GMR} from the result when the log transform is off, since they are not
meaningful on the original scale (item B-4).
}
\value{
\code{kp_hazirla}: a summary list with the number of stages \code{m}, the stage
labels, the design of each product (\code{T}, \code{R}), warnings
(\code{uyarilar}) and descriptive statistics by product and stage.

\code{kp_pbe}: the result of \code{\link{calc_pbe}} (see item B-4 above).

\code{kp_calistir}: the value of \code{ifade}, or \code{list(.hata = message)} on error.
}
\seealso{\code{\link{calc_pbe}}}
\examples{
d <- ornek_psg020929()
h <- kp_calistir(kp_hazirla(d$Batches, d$Container, d$Stage, d$Product,
                            d$score, "TEST", "REF", FALSE))
h$m
r <- kp_calistir(kp_pbe(FALSE))
r$pass_fail

# A container with a missing stage measurement is rejected
d2 <- d[-5, ]
kp_calistir(kp_hazirla(d2$Batches, d2$Container, d2$Stage, d2$Product,
                       d2$score, "TEST", "REF", FALSE))$.hata
}
