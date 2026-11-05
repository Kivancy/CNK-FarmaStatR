\name{platform_analiz}
\alias{platform_analiz}
\alias{platform_csv}
\alias{platform_pbe_veri}
\alias{platform_pbe}
\alias{platform_ema}
\alias{platform_dis_veri}
\alias{platform_dis_kopru}
\alias{platform_dis}
\title{Analysis of one's own data with the inherited validated models (analysis screen)}
\description{
Reader and caller behind the analysis screen \code{web/analiz/} (FSR-TN-PLT-06 v0.1;
decision KK-59). The functions read a CSV text or choose an example data set, map
the columns and call the inherited bridges unchanged; they compute no statistic.
\itemize{
  \item PBE (FDA PSG 020929): \code{kp_hazirla()} and \code{kp_pbe()} of the PBE
    bridge, which call \code{\link{calc_pbe}}.
  \item EMA OIP Rev. 2 Section 5.1 criterion 8 (FSR-TN-PLT-08 v0.1; decision KK-64):
    the same input checks (\code{kp_hazirla()}), then \code{\link{invitro_array}} and
    \code{\link{ema_ci_fast}} of the validated simulation engine (FSR-VAL-SIM-1).
    The 90\% confidence intervals of the three candidate paths (a) pooled units,
    (b) batch means and (c) mixed model (REML) are returned (FarmaStatR derivation,
    KK-27); the decision line is path (b). Balanced designs only.
  \item Dissolution: the v0.5.1 bridge \code{inst/kopru/dis_kopru.R} (bytes unchanged,
    FSR-LOG-01 G-01), loaded into its own environment by \code{platform_dis_kopru}
    because it also defines \code{kp_hazirla()}; it calls \code{\link{calc_f2_boot}},
    \code{\link{calc_msd}} and \code{\link{calc_msd_weibull}}.
}
\code{platform_csv} accepts \code{;}, \code{,} or tab as separator, drops a UTF-8
byte-order mark and empty rows; numbers may use a decimal comma. Column names are
matched without case and Turkish letters (PBE: parti/batch, kap/container,
asama/stage, urun/product, olcum/score; dissolution: Product/urun, Unit/tablet,
Time/zaman, Diss/cozunen).
\code{platform_dis_veri} also reads the wide layout (FSR-TN-PLT-12; decision KK-78):
first column Time, the other columns \code{<product>.<unit>} (split at the last dot,
e.g. \code{Test.1}, \code{Ref.1}), one row per time point; a first data row without
any number (DDSolver's second header row) is skipped; empty or non-numeric cells,
duplicate columns and duplicate time points are errors. It is returned in the long
layout, ordered product, time, unit; results equal those of the long layout.
In \code{platform_dis} the f2 perspective presets are those of \code{calc_f2_boot}
(EMA: Ef2, EMA truncation, rule M9, B = 5000; FDA: f2, FDA truncation, FDA97,
B = 10000); explicit settings in \code{ayar} win.
Research and education only; not a system validated for GxP environments.
}
\usage{
platform_csv(metin)
platform_pbe_veri(metin = NULL, ornek = NULL)
platform_pbe(veri, test = "TEST", ref = "REF", log_d = FALSE, tek_yonlu = FALSE)
platform_ema(veri, test = "TEST", ref = "REF", log_d = FALSE, level = 0.90,
             limits = c(0.85, 1.18))
platform_dis_veri(metin = NULL, ornek = NULL)
platform_dis_kopru(path = system.file("kopru", "dis_kopru.R", package = "CNKfarmastatr"),
                   parent = environment(calc_msd))
platform_dis(kopru, veri, test, ref, lotlar = character(0), birim = "dakika",
             yontem = c("f2", "msd", "weibull"), ayar = list())
}
\arguments{
  \item{metin}{CSV file content as one character string.}
  \item{ornek}{example data set instead of \code{metin}: \code{"psg020929"} (PBE),
    \code{"tsong1996"} or \code{"noce2020"} (dissolution).}
  \item{veri}{result of \code{platform_pbe_veri} or \code{platform_dis_veri}.}
  \item{test, ref}{product labels of test and reference.}
  \item{log_d}{logical; analyse \code{log(score)}.}
  \item{level, limits}{confidence level and acceptance limits of the ratio (EMA).}
  \item{tek_yonlu}{logical; one-sided test with sigma_T0 (PSG 020929).}
  \item{path, parent}{file of the dissolution bridge and the parent environment
    (where the cores are).}
  \item{kopru}{environment returned by \code{platform_dis_kopru}.}
  \item{lotlar}{reference lot labels (L2a/L2b, B-L2a/B-L2b).}
  \item{birim}{time unit, \code{"dakika"} or \code{"saat"}.}
  \item{yontem}{\code{"f2"}, \code{"msd"} or \code{"weibull"}.}
  \item{ayar}{named list of settings: f2 \code{perspektif, tahminci, kesme, kmod,
    cvkural, gatipi, B, seed, qtip}; MSD \code{sinir, Dg, kesme}; Weibull
    \code{param, bolge, Dg, k, bolen}.}
}
\value{
\code{platform_csv}: a data frame of character columns (attribute \code{ayrac}).
\code{platform_pbe_veri}, \code{platform_dis_veri}: lists of columns and the product
labels (\code{urunler}). \code{platform_pbe}, \code{platform_dis}: lists with the
bridge's own results \code{hazir} (design, summaries, warnings) and \code{sonuc}.
\code{platform_ema}: \code{hazir} and \code{sonuc} (per path: \code{yol, gmr, alt, ust,
se, sd, gecti}; \code{karar} = path (b); \code{uyum}: the three paths agree).
}
\seealso{\code{\link{kp_hazirla}}, \code{\link{calc_pbe}}, \code{\link{calc_f2_boot}},
  \code{\link{calc_msd}}, \code{\link{calc_msd_weibull}}}
\examples{
r <- platform_pbe(platform_pbe_veri(ornek = "psg020929"))
r$sonuc$pass_fail
e <- platform_ema(platform_pbe_veri(ornek = "psg020929"))
e$sonuc$karar
kp <- platform_dis_kopru()
m <- platform_dis(kp, platform_dis_veri(ornek = "tsong1996"), "TEST", "REF",
                  c("STD1", "STD2"), yontem = "msd", ayar = list(sinir = "L2a"))
m$sonuc$DM
}
\keyword{datasets}
