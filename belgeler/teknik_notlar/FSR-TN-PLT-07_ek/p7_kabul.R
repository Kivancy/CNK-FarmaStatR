# =============================================================================
# CNK-FarmaStatR - help acceptance (FSR-TN-PLT-07 v0.1, Table 6.1; frozen in v0.1)
#
# Reads the browser output of web/yardim/kabul7.html (p7/p7_kabul.zip:
# p7_tarayici.csv) and writes one line per criterion: GECTI, KALDI or EKSIK.
#   Y-1 hints on every form field (4 screens, TR and EN)
#   Y-2 help panels, six sections, follow tab and language
#   Y-3 method notes: 5 notes + index, TR and EN, 8 sections, every equation
#       with a source label, MathML
#   Y-4 numbers of the worked examples = local R (shown decimals)
#   Y-5 CSV templates: read in R and on the screen; same result as the example
#   Y-6 links; Y-7 no outside request; Y-8 narrow screen; Y-9 accessibility
#   Y-11 PBE decision text "Hη ≤ 0"; Y-12 documents present
# Y-10 (regression) is checked with the P5 and P6 acceptance tools and CI.
# Run from the repository root:
#   source("belgeler/teknik_notlar/FSR-TN-PLT-07_ek/p7_kabul.R", encoding = "UTF-8")
# Base R plus jsonlite. Research and education only; not a system validated for
# GxP environments.
# =============================================================================
local({
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("jsonlite is needed: install.packages('jsonlite')")
E <- file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-07_ek")
zf <- file.path(E, "p7", "p7_kabul.zip")
if (!file.exists(zf)) stop("p7/p7_kabul.zip not found")
X <- file.path(tempdir(), "p7_kabul"); unlink(X, recursive = TRUE); dir.create(X)
utils::unzip(zf, exdir = X)
br <- utils::read.csv(file.path(X, "p7_tarayici.csv"), colClasses = "character", encoding = "UTF-8", na.strings = character(0))

Rdir <- file.path("CNKfarmastatr", "R")
coll <- strsplit(gsub("'", "", read.dcf(file.path("CNKfarmastatr", "DESCRIPTION"), fields = "Collate")[1, 1]), "[[:space:]]+")[[1]]
pk <- new.env(parent = globalenv())
for (f in coll[nzchar(coll)]) sys.source(file.path(Rdir, f), envir = pk, keep.source = FALSE)
kp <- pk$platform_dis_kopru(file.path("CNKfarmastatr", "inst", "kopru", "dis_kopru.R"), parent = pk)
H <- jsonlite::fromJSON(file.path("web", "yardim", "yardim.json"), simplifyVector = FALSE)

res <- data.frame(olcut = character(0), sonuc = character(0), ayrinti = character(0), stringsAsFactors = FALSE)
put <- function(o, ok, a) { s <- if (is.na(ok)) "EKSIK" else if (isTRUE(ok)) "GECTI" else "KALDI"
  res[nrow(res) + 1, ] <<- c(o, s, a); cat(sprintf("%-30s %-6s %s\n", o, s, a)) }
g <- function(b, d = NULL, y = NULL, a = NULL) { x <- br[br$bolum == b, ]
  if (!is.null(d)) x <- x[x$durum == d, ]; if (!is.null(y)) x <- x[x$ayar == y, ]; if (!is.null(a)) x <- x[x$ad == a, ]; x }
v1 <- function(b, d, y, a) { x <- g(b, d, y, a)$deger; if (length(x) == 1) x else NA_character_ }
num <- function(x) suppressWarnings(as.numeric(x))

# ---------------------------------------------------------------- Y-1
for (s in c("tek", "tas", "pbe", "dis")) {
  n <- num(v1("Y-1", s, "", "alan_sayisi")); miss <- v1("Y-1", s, "", "ipucusuz_alan")
  keys <- grep(paste0("^", s, "\\."), names(H$tr$ipucu), value = TRUE)
  ok_lang <- vapply(c("tr", "en"), function(l) identical(v1("Y-1", s, l, "ipucu_hatali"), "") &&
                      num(v1("Y-1", s, l, "ipucu_tamam")) == length(keys), NA)
  put(paste("Y-1", s), !is.na(n) && n > 0 && identical(miss, "") && all(ok_lang),
      sprintf("%d alan, %d ipucu; TR %s, EN %s", n, length(keys), v1("Y-1", s, "tr", "ipucu_tamam"), v1("Y-1", s, "en", "ipucu_tamam")))
}
put("Y-1 anahtarlar TR = EN", identical(sort(names(H$tr$ipucu)), sort(names(H$en$ipucu))) &&
      all(nzchar(trimws(unlist(H$tr$ipucu)))) && all(nzchar(trimws(unlist(H$en$ipucu)))), sprintf("%d anahtar", length(H$tr$ipucu)))

# ---------------------------------------------------------------- Y-2, Y-9
for (s in c("tek", "tas", "pbe", "dis")) for (l in c("tr", "en")) {
  ok <- identical(v1("Y-2", s, l, "baslik_dogru"), "true") && identical(v1("Y-2", s, l, "bolum_sayisi"), "6") &&
    identical(v1("Y-2", s, l, "bolumler_dogru"), "true") && identical(v1("Y-2", s, l, "dil_degisince_yenilendi"), "true")
  put(paste("Y-2", s, l), ok, v1("Y-2", s, l, "baslik"))
  put(paste("Y-9", s, l), identical(v1("Y-9", s, l, "esc_kapatti"), "true") && identical(v1("Y-9", s, l, "odak_baslikta"), "true"), "Esc kapatır, odak başlıkta")
}
put("Y-9 yardım düğmesi", identical(v1("Y-9", "app", "", "yardim_dugmesi"), "true"), "")

# ---------------------------------------------------------------- Y-3
notes <- c("pbe", "f2", "msd", "weibull", "simulasyon")
for (n in notes) for (l in c("tr", "en")) {
  b <- jsonlite::fromJSON(v1("Y-3", n, l, "bolumler"))
  ne <- num(v1("Y-3", n, l, "denklem"))
  ok <- identical(v1("Y-3", n, l, "gorunur"), "true") && length(b) == 8 && all(vapply(1:8, function(i) startsWith(b[i], paste0(i, ". ")), NA)) &&
    ne > 0 && identical(v1("Y-3", n, l, "denklem_kaynaksiz"), "0") && identical(num(v1("Y-3", n, l, "denklem_mathml")), ne)
  put(paste("Y-3", n, l), ok, sprintf("%s · %d bölüm, %g denklem, FarmaStatR etiketli %s", v1("Y-3", n, l, "baslik"), length(b), ne, v1("Y-3", n, l, "farmastatr_etiketi")))
}
for (n in notes) put(paste("Y-3", n, "TR = EN denklem"), identical(v1("Y-3", n, "tr", "denklem"), v1("Y-3", n, "en", "denklem")), "")
put("Y-3 dizin", identical(v1("Y-3", "index", "tr", "gorunur"), "true") && identical(v1("Y-3", "index", "en", "gorunur"), "true"), "")

# ---------------------------------------------------------------- Y-4 numbers of the worked examples
pbe <- pk$platform_pbe(pk$platform_pbe_veri(ornek = "psg020929"))$sonuc
ts <- pk$platform_dis_veri(ornek = "tsong1996"); no <- pk$platform_dis_veri(ornek = "noce2020")
m1 <- pk$platform_dis(kp, ts, "TEST", "REF", c("STD1", "STD2"), yontem = "msd", ayar = list(sinir = "L1"))$sonuc
m2 <- pk$platform_dis(kp, ts, "TEST", "REF", c("STD1", "STD2"), yontem = "msd", ayar = list(sinir = "L2a"))$sonuc
w2 <- pk$platform_dis(kp, ts, "TEST", "REF", c("STD1", "STD2"), yontem = "weibull", ayar = list(param = "lnA_lnB", bolge = "B-L2a"))$sonuc
w3 <- pk$platform_dis(kp, ts, "TEST", "REF", character(0), yontem = "weibull")$sonuc
f2 <- pk$platform_dis(kp, no, "Urun1", "Urun2", yontem = "f2")$sonuc
th <- ((log(1.11))^2 + 0.01) / 0.1^2
ref <- list(pbe_sigma_r = c(pbe$Sigma_R, 4), pbe_ed = c(pbe$E_D, 6), pbe_e1 = c(pbe$E1, 6), pbe_e3s = c(pbe$E3s, 6),
            pbe_eq = c(pbe$Eq_Ref, 6), pbe_uq = c(pbe$Uq_Ref, 6), pbe_heta = c(pbe$H_eta_Ref, 6), pbe_heta_c = c(pbe$H_eta_Const, 6),
            f2_p = c(length(f2$zamanlar), 0), f2_f2 = c(f2$f2, 2), f2_ef2 = c(f2$Ef2, 2), f2_bcf2 = c(f2$bcf2, 2),
            f2_alt = c(f2$alt, 2), f2_ust = c(f2$ust, 2), f2_mcse = c(f2$mcse, 2), f2_tamsayi = c(f2$tamsayi, 0),
            msd_dm = c(m2$DM, 4), msd_dml = c(m2$DM_l, 4), msd_dmu = c(m2$DM_u, 4), msd_rd_l1 = c(m1$RD, 4),
            msd_dg_l2a = c(max(m2$lot_fark), 2), msd_rd_l2a = c(m2$RD, 4),
            wb_dm_l2a = c(w2$DM, 4), wb_dml_l2a = c(w2$DM_l, 4), wb_dmu_l2a = c(w2$DM_u, 4), wb_dm_l3 = c(w3$DM, 4),
            wb_l3_max = c(w3$bolge[[6]][1], 2), wb_r2t = c(w3$R2T, 4), wb_r2r = c(w3$R2R, 4),
            sim_thetap = c(th, 4), sim_sqrt_thetap = c(sqrt(th), 4), sim_delta0 = c(sqrt(th) * 0.12, 5),
            sim_gmr0 = c(exp(sqrt(th) * 0.12), 4), sim_mcse05 = c(100 * sqrt(0.05 * 0.95 / 1e4), 2), sim_mcse80 = c(100 * sqrt(0.8 * 0.2 / 1e4), 2))
yz <- function(x, d, l) { s <- formatC(x, format = "f", digits = d); s <- sub("^-", "−", s); if (l == "tr") chartr(".", ",", s) else s }
dg <- g("Y-4")
bad <- character(0)
for (i in seq_len(nrow(dg))) {
  id <- dg$ad[i]; r <- ref[[id]]
  if (is.null(r)) { bad <- c(bad, paste(id, "(R karşılığı yok)")); next }
  w <- yz(r[1], r[2], dg$ayar[i])
  if (!identical(dg$deger[i], w)) bad <- c(bad, sprintf("%s/%s: not %s, R %s", id, dg$ayar[i], dg$deger[i], w))
}
eksik <- setdiff(names(ref), unique(dg$ad))
put("Y-4 çalışılmış örnekler", nrow(dg) > 0 && !length(bad) && !length(eksik),
    sprintf("%d sayı (TR ve EN); farklı %d%s%s", nrow(dg), length(bad), if (length(bad)) paste0(": ", paste(head(bad, 4), collapse = "; ")) else "",
            if (length(eksik)) paste0("; notta yok: ", paste(eksik, collapse = ", ")) else ""))

# ---------------------------------------------------------------- Y-5 templates
S <- file.path("web", "yardim", "sablon")
rd <- function(f) paste(readLines(file.path(S, f), encoding = "UTF-8", warn = FALSE), collapse = "\n")
cmp_js <- function(js, loc) {
  a <- jsonlite::fromJSON(js, simplifyVector = FALSE); loc <- loc[!names(loc) %in% c("boot", "tt", "egR", "egT")]
  all(vapply(names(loc), function(n) { vb <- unlist(loc[[n]]); va <- unlist(a[[n]])
    if (is.null(vb)) return(is.null(va) || all(is.na(va)))
    if (is.numeric(vb)) { va <- num(va); return(length(va) == length(vb) && all(abs(va - vb) <= 1e-12 + 1e-12 * pmax(abs(va), abs(vb)))) }
    identical(as.character(va), as.character(vb)) || identical(as.logical(va), vb) }, NA))
}
for (f in c("pbe_sablon_tr.csv", "pbe_sablon_en.csv")) {
  loc <- pk$platform_pbe(pk$platform_pbe_veri(rd(f)))$sonuc
  js <- v1("Y-5", f, "pbe", "sonuc")
  put(paste("Y-5", f), identical(loc, pbe) && identical(v1("Y-5", f, "pbe", "durum"), "an_st_done") && !is.na(js) && cmp_js(js, pbe),
      "R: şablon = örnek; ekran = R")
}
m2s <- m2[names(m2) != "notlar"]
for (f in c("dis_sablon_tr.csv", "dis_sablon_en.csv")) {
  loc <- pk$platform_dis(kp, pk$platform_dis_veri(rd(f)), "TEST", "REF", c("STD1", "STD2"), yontem = "msd", ayar = list(sinir = "L2a"))$sonuc
  js <- v1("Y-5", f, "dis", "sonuc")
  put(paste("Y-5", f), identical(loc[names(loc) != "notlar"], m2s) && identical(v1("Y-5", f, "dis", "durum"), "an_st_done") && !is.na(js) && cmp_js(js, loc),
      "R: şablon = örnek (notlar hariç); ekran = R")
}

# ---------------------------------------------------------------- Y-6, Y-7, Y-8, Y-11
ln <- g("Y-6")
put("Y-6 bağlantılar", nrow(ln) > 0 && all(ln$deger == "200"), sprintf("%d bağlantı; açılmayan: %s", nrow(ln), paste(ln$durum[ln$deger != "200"], collapse = ", ")))
ex <- g("Y-7")
put("Y-7 dış istek", nrow(ex) > 0 && all(ex$deger == "0"), sprintf("%d ölçüm; toplam %d", nrow(ex), sum(num(ex$deger))))
nw <- br[br$bolum == "Y-8" & grepl("kaydirma", br$ad), ]
put("Y-8 dar ekran (390 px)", nrow(nw) > 0 && all(nw$deger == "false"), sprintf("%d sayfa/panel; %s", nrow(nw), paste(g("Y-8", a = "panel_genislik")$deger, collapse = ", ")))
put("Y-11 PBE karar metni", grepl("Hη ≤ 0", v1("Y-11", "pbe", "tr", "karar_metni"), fixed = TRUE) &&
      grepl("Hη ≤ 0", v1("Y-11", "pbe", "en", "karar_metni"), fixed = TRUE) &&
      identical(jsonlite::fromJSON(v1("Y-11", "pbe", "en", "rapor_gorunum")), v1("Y-11", "pbe", "en", "karar_metni")),
    paste(v1("Y-11", "pbe", "tr", "karar_metni"), "|", v1("Y-11", "pbe", "en", "karar_metni")))

# ---------------------------------------------------------------- Y-12
docs <- c(file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-07_v0.1.docx"), file.path("belgeler", "validasyon", "FSR-VAL-PLT-1_v1.2.docx"),
          file.path("web", "yardim", "README.md"), "FSR-LOG-01_v1_gunluk.md")
put("Y-12 belgeler", all(file.exists(docs)), paste(basename(docs)[!file.exists(docs)], collapse = ", "))

utils::write.csv(res, file.path(E, "p7_kabul.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat(sprintf("\nToplam: %d ölçüt satırı; GECTI %d, KALDI %d, EKSIK %d. Ayrıntı: %s\n", nrow(res), sum(res$sonuc == "GECTI"),
            sum(res$sonuc == "KALDI"), sum(res$sonuc == "EKSIK"), file.path(E, "p7_kabul.csv")))
})
