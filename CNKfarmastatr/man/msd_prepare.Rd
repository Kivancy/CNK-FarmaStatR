\name{msd_prepare}
\alias{msd_prepare}
\title{Long-format dissolution data to unit-by-time matrices}
\description{
Turns long-format dissolution data (one row per unit and time point) into the
unit-by-time matrices used by \code{\link{calc_msd}} and
\code{\link{calc_msd_weibull}}; optionally also splits the reference product
into lots.
}
\usage{
msd_prepare(df, product_col = "Product", unit_col = "Unit", time_col = "Time",
            value_col = "Diss", lot_col = NULL,
            test_label = "TEST", ref_label = "REF")
}
\arguments{
  \item{df}{A data frame in long format.}
  \item{product_col, unit_col, time_col, value_col}{Column names for product,
    dosage unit, time point and percent dissolved.}
  \item{lot_col}{Optional column name of the reference lot. When given, the
    reference rows are split by lot into \code{ref_lots}.}
  \item{test_label, ref_label}{Values of \code{product_col} that identify the
    test and the reference product.}
}
\value{
A list with \code{test} and \code{ref} (matrices; rows named by unit, columns
by time) and \code{ref_lots} (a named list of matrices, or \code{NULL}).
Stops with an error if a column is missing or if any unit lacks a measurement
at any time point.
}
\seealso{\code{\link{calc_msd}}, \code{\link{ornek_tsong}}}
\examples{
d <- ornek_tsong()
p <- msd_prepare(d[d$Product \%in\% c("TEST", "REF"), ])
dim(p$test)
}
