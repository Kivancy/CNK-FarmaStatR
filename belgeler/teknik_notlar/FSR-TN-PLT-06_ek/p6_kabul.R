# =============================================================================
# CNK-FarmaStatR - P6 acceptance (FSR-TN-PLT-06 v0.1, Table 7.1; frozen in v0.1)
# Revised for FSR-TN-PLT-09 v0.1 (KK-66): dissolution cases 10 -> 9 (Weibull B-L2b removed from the
# screen) and three added rows: P9-G1 (EMA integer row of f2), P9-G2 (region options), P9-G3 (labels).
#
# Reads the browser output of web/analiz/kabul6.html (p6/p6_kabul.zip:
# p6_tarayici.csv and the Word reports), recomputes in local R every analysis the
# screen ran, opens the reports with R's own unzip and writes one line per
# criterion: GECTI (pass), KALDI (fail) or EKSIK (data missing).
#   F-1 PBE: example (3 settings) and the test-data files: screen = local R
#   F-2 input errors: the bridge's message, no result, report buttons off
#   F-3 f2 and bootstrap f2; F-4 MSD; F-5 Weibull MSD: screen = local R
#   F-6 Turkish CSV (';', decimal comma, Turkish column names) = example
#   F-7 reports: numbers and labels = screen; disclaimer; valid file; determinism;
#       time (the Word check is done by the project owner)
#   F-8 no outside request during reading, analysis and report
#   F-9 validation in the browser: 516/516 and the package tests (0 failed, 0 errors)
#   F-10 regression: pinned files, dis_kopru.R (G-01), P5 report unchanged
#   F-11 TR/EN keys; narrow screen; F-12 documents present
#   FSR-TN-PLT-11 (KK-75): D-1 ... D-8, Section 9 'Analysed data'
#   FSR-TN-PLT-12 (KK-78): W-0 ... W-11, wide layout of dissolution data (rows 'W')
#   FSR-TN-PLT-14 (KK-80): GR-1 ... GR-7, BS-1 ... BS-6, BS-8, DV-1, DV-2 (rows 'G'; BS-7 is the owner's SAS run)
# Numbers: K(1e-12, 1e-12) (absolute or relative difference); texts and decisions
# exactly. Run from the repository root:
#   source("belgeler/teknik_notlar/FSR-TN-PLT-06_ek/p6_kabul.R", encoding = "UTF-8")
# Base R plus jsonlite (reading the screen's JSON). Research and education only;
# not a system validated for GxP environments.
# =============================================================================
local({
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("jsonlite is needed: install.packages('jsonlite')")
E <- file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-06_ek")
zf <- file.path(E, "p6", "p6_kabul.zip")
if (!file.exists(zf)) stop("p6/p6_kabul.zip not found")
X <- file.path(tempdir(), "p6_kabul"); unlink(X, recursive = TRUE); dir.create(X)
utils::unzip(zf, exdir = X)
br <- utils::read.csv(file.path(X, "p6_tarayici.csv"), colClasses = "character", encoding = "UTF-8", na.strings = character(0))
if (nrow(br) == 0) stop("p6_tarayici.csv is empty")

# the package code as the screen loads it (Collate order), no installation needed
Rdir <- file.path("CNKfarmastatr", "R")
coll <- strsplit(gsub("'", "", read.dcf(file.path("CNKfarmastatr", "DESCRIPTION"), fields = "Collate")[1, 1]), "[[:space:]]+")[[1]]
pk <- new.env(parent = globalenv())
for (f in coll[nzchar(coll)]) sys.source(file.path(Rdir, f), envir = pk, keep.source = FALSE)
kp <- pk$platform_dis_kopru(file.path("CNKfarmastatr", "inst", "kopru", "dis_kopru.R"), parent = pk)

res <- data.frame(olcut = character(0), sonuc = character(0), ayrinti = character(0), stringsAsFactors = FALSE)
put <- function(o, ok, a) { s <- if (is.na(ok)) "EKSIK" else if (isTRUE(ok)) "GECTI" else "KALDI"
  res[nrow(res) + 1, ] <<- c(o, s, a); cat(sprintf("%-26s %-6s %s\n", o, s, a)) }
g <- function(b, d = NULL, y = NULL, a = NULL) { x <- br[br$bolum == b, ]
  if (!is.null(d)) x <- x[x$durum == d, ]; if (!is.null(y)) x <- x[x$ayar == y, ]; if (!is.null(a)) x <- x[x$ad == a, ]; x }
v1 <- function(b, d, y, a) { x <- g(b, d, y, a)$deger; if (length(x) == 1) x else NA_character_ }
K <- function(a, b) abs(a - b) <= 1e-12 + 1e-12 * pmax(abs(a), abs(b))
num <- function(x) suppressWarnings(as.numeric(x))

# compare a screen result (JSON) with the local one: numbers K(), others exactly;
# fields the screen drops (bootstrap vector, curve points) are skipped
cmp <- function(js, loc) {
  a <- jsonlite::fromJSON(js, simplifyVector = FALSE)
  loc <- loc[!names(loc) %in% c("boot", "tt", "egR", "egT", "tekT", "tekR")]
  bad <- character(0)
  for (n in names(loc)) {
    vb <- unlist(loc[[n]], use.names = FALSE); va <- unlist(a[[n]], use.names = FALSE)
    if (is.null(vb)) { if (!(is.null(va) || all(is.na(va)))) bad <- c(bad, n); next }
    ok <- if (is.numeric(vb)) { va <- num(va); length(va) == length(vb) && all((is.na(va) & is.na(vb)) | K(va, vb), na.rm = FALSE) }
          else if (is.logical(vb)) identical(as.logical(va), vb)
          else identical(as.character(va), as.character(vb))
    if (!isTRUE(ok)) bad <- c(bad, n)
  }
  extra <- setdiff(names(a), names(loc))
  list(ok = !length(bad), bad = c(bad, if (length(extra)) paste0("+", extra)), n = length(names(loc)))
}
pbe_local <- function(id, form) {
  f <- sub("\\|.*$", "", id)
  v <- if (grepl("^pbe-ornek", id)) pk$platform_pbe_veri(ornek = "psg020929")
       else if (id == "pbe-csv-tr") pk$platform_pbe_veri(paste(readLines(file.path(E, "veri", "psg020929_tr.csv"), encoding = "UTF-8", warn = FALSE), collapse = "\n"))
       else pk$platform_pbe_veri(paste(readLines(file.path("CNKfarmastatr", "inst", "validasyon", "pbe", "test_verisi", f), warn = FALSE), collapse = "\n"))
  pk$platform_pbe(v, form$test, form$ref, isTRUE(form$log_d), isTRUE(form$tek))$sonuc
}
dis_local <- function(id, form) {
  src <- sub("\\|.*$", "", id)
  v <- if (id == "dis-csv-tr") pk$platform_dis_veri(paste(readLines(file.path(E, "veri", "tsong1996_tr.csv"), encoding = "UTF-8", warn = FALSE), collapse = "\n"))
       else pk$platform_dis_veri(ornek = src)
  ay <- form$ayar[!vapply(form$ayar, is.null, NA)]
  pk$platform_dis(kp, v, form$test, form$ref, unlist(form$lotlar), form$birim, form$yontem, ay)$sonuc
}

# ---------------------------------------------------------------- F-1 ... F-6
ids <- unique(g("F", a = "sonuc")$durum)
sonuc <- list()
for (id in ids) {
  sec <- g("F", id, a = "sonuc")$ayar[1]
  form <- jsonlite::fromJSON(v1("F", id, sec, "form"), simplifyVector = TRUE)
  loc <- tryCatch(if (sec == "pbe") pbe_local(id, form) else dis_local(id, form), error = function(e) e)
  sonuc[[id]] <- loc
  c1 <- if (inherits(loc, "error")) list(ok = FALSE, bad = paste("R:", conditionMessage(loc)), n = 0) else cmp(v1("F", id, sec, "sonuc"), loc)
  o <- if (sec == "pbe") "F-1" else switch(form$yontem, f2 = "F-3", msd = "F-4", weibull = "F-5")
  if (id %in% c("pbe-csv-tr", "dis-csv-tr")) o <- "F-6"
  put(paste(o, id), c1$ok, sprintf("%d alan%s", c1$n, if (length(c1$bad)) paste0("; farklı: ", paste(c1$bad, collapse = ", ")) else ""))
}
# expected number of analyses: PBE example 3 + files 24 valid (30 runs, 6 rejected; F-2); dissolution 9
nf <- sum(grepl("\\|", ids) & !grepl("^(tsong1996|noce2020)", ids))
put("F-1 kapsam", length(grep("^pbe-ornek", ids)) == 3 && nf == 24, sprintf("örnek %d, test verisi %d (beklenen 3 ve 24)", length(grep("^pbe-ornek", ids)), nf))
put("F-3/4/5 kapsam", sum(grepl("^(tsong1996|noce2020)\\|", ids)) == 9, sprintf("%d dissolüsyon durumu (beklenen 9)", sum(grepl("^(tsong1996|noce2020)\\|", ids))))
# ---------------------------------------------------------------- FSR-TN-PLT-09 G-1, G-2 (KK-66)
f2ids <- ids[grepl("\\|f2\\|", ids)]
g1 <- vapply(f2ids, function(id) {
  sec <- g("F", id, a = "sonuc")$ayar[1]; s <- jsonlite::fromJSON(v1("F", id, sec, "sonuc"))
  rows <- jsonlite::fromJSON(v1("F", id, sec, "ekran"), simplifyVector = FALSE)
  hit <- Filter(function(r) length(r) >= 2 && grepl("^(EMA raporlamas\u0131|EMA reporting)", r[[1]]), rows)
  if (identical(s$perspektif, "EMA")) length(hit) == 1 && identical(hit[[1]][[2]], format(s$tamsayi)) && isTRUE(s$tamsayi == round(s$alt))
  else length(hit) == 0 }, NA)
put("P9-G1 f2 tam sayı satırı", length(g1) >= 3 && all(g1), sprintf("%d f2 analizi (EMA'da satır = round(alt), FDA'da yok)", length(g1)))
opt <- v1("P9-G2", "weibull", "", "bolge_secenekleri")
put("P9-G2 Weibull bölgeleri", identical(jsonlite::fromJSON(opt), c("B-L3", "B-L2a")), if (is.na(opt)) "kayıt yok" else opt)
# G-3: old labels absent and "Tasarım gereği" / "By design" equal in number in notes, screen and help texts
lf <- c(Sys.glob(file.path("web", "yardim", "kaynak", "*.txt")), file.path("web", "app", "ceviri.json"), file.path("web", "yardim", "yardim.json"))
old_re <- "FarmaStatR (türet|kural|seçim|tasarım kararı|derivation|rule|choice|design decision|reading)|FarmaStatR’in"
cnt <- vapply(lf, function(f) { x <- paste(readLines(f, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  c(eski = length(gregexpr(old_re, x, perl = TRUE)[[1]][gregexpr(old_re, x, perl = TRUE)[[1]] > 0]),
    tr = lengths(regmatches(x, gregexpr("asarım gereği", x))), en = lengths(regmatches(x, gregexpr("y design", x)))) }, numeric(3))
put("P9-G3 etiketler", all(cnt["eski", ] == 0) && all(cnt["tr", ] == cnt["en", ]),
    sprintf("%d dosya; eski etiket %d; Tasarım gereği %d, By design %d", length(lf), sum(cnt["eski", ]), sum(cnt["tr", ]), sum(cnt["en", ])))
if (!is.null(sonuc[["pbe-csv-tr"]]) && !is.null(sonuc[["pbe-ornek-ham"]]))
  put("F-6 PBE CSV = örnek", identical(sonuc[["pbe-csv-tr"]], sonuc[["pbe-ornek-ham"]]), "Türkçe CSV ile örnek, yerel R'de birebir")
if (!is.null(sonuc[["dis-csv-tr"]]) && !is.null(sonuc[["tsong1996|msd|L2a-none"]])) {
  a <- sonuc[["dis-csv-tr"]]; b <- sonuc[["tsong1996|msd|L2a-none"]]
  put("F-6 MSD CSV = örnek", identical(a[names(a) != "notlar"], b[names(b) != "notlar"]), "notlar hariç (veri kaynağına göre değişebilir)")
}

# ---------------------------------------------------------------- F-2 errors
err <- unique(g("F-2", a = "hata")$durum)
exp_err <- c("P5_negatif.csv|log", "P5_stage_hata.csv|ham", "P5_stage_hata.csv|log", "P5_stage_hata.csv|tek",
             "P6_sinir_esit.csv|log", "P6_sinir_ustu.csv|log", "dis-l2a-lotsuz")
put("F-2 hatalı durumlar", setequal(err, exp_err), paste(sort(err), collapse = "; "))
for (id in err) {
  sec <- g("F-2", id, a = "hata")$ayar[1]
  msg <- if (sec == "pbe") {
    f <- sub("\\|.*$", "", id); s <- sub("^.*\\|", "", id)
    v <- pk$platform_pbe_veri(paste(readLines(file.path("CNKfarmastatr", "inst", "validasyon", "pbe", "test_verisi", f), warn = FALSE), collapse = "\n"))
    tryCatch({ pk$platform_pbe(v, "TEST", "REF", s == "log", s == "tek"); "" }, error = conditionMessage)
  } else tryCatch({ pk$platform_dis(kp, pk$platform_dis_veri(ornek = "tsong1996"), "TEST", "REF", character(0), "dakika", "msd", list(sinir = "L2a")); "" },
                  error = conditionMessage)
  ekran <- v1("F-2", id, sec, "hata")
  ok <- nzchar(msg) && grepl(msg, ekran, fixed = TRUE) && v1("F-2", id, sec, "sonuc_gizli") == "true" &&
    v1("F-2", id, sec, "rapor_etkin") == "false" && v1("F-2", id, sec, "json_etkin") == "false"
  put(paste("F-2", id), ok, substr(msg, 1, 90))
}
put("F-2 sonuç öncesi rapor pasif", v1("F-2", "once", "pbe", "rapor_etkin") == "false", "")
put("F-2 girdi değişince rapor pasif", v1("F-2", "pbe-ornek-ham", "pbe", "girdi_degisince_rapor_etkin") == "false", "")
ok_on <- g("F-2", a = "rapor_etkin"); ok_on <- ok_on[ok_on$durum %in% ids, ]
put("F-2 sonuçta rapor etkin", nrow(ok_on) > 0 && all(ok_on$deger == "true"), sprintf("%d sonuç", nrow(ok_on)))

# ---------------------------------------------------------------- F-7 reports
xml_unesc <- function(s) { s <- gsub("&lt;", "<", s, fixed = TRUE); s <- gsub("&gt;", ">", s, fixed = TRUE)
  s <- gsub("&quot;", "\"", s, fixed = TRUE); gsub("&amp;", "&", s, fixed = TRUE) }
doc_xml <- function(f) { d <- file.path(tempdir(), "p6_docx"); unlink(d, recursive = TRUE); dir.create(d)
  utils::unzip(file.path(X, f), exdir = d); x <- readLines(file.path(d, "word", "document.xml"), encoding = "UTF-8", warn = FALSE)
  list(xml = paste(x, collapse = "\n"), header = paste(readLines(file.path(d, "word", "header1.xml"), encoding = "UTF-8", warn = FALSE), collapse = ""),
       footer = paste(readLines(file.path(d, "word", "footer1.xml"), encoding = "UTF-8", warn = FALSE), collapse = "")) }
paras <- function(xml) {
  p <- regmatches(xml, gregexpr("<w:p>.*?</w:p>", xml, perl = TRUE))[[1]]
  vapply(p, function(q) { tk <- regmatches(q, gregexpr("<w:t[^>]*>[^<]*</w:t>", q, perl = TRUE))[[1]]
    xml_unesc(paste(sub("^<w:t[^>]*>", "", sub("</w:t>$", "", tk)), collapse = "")) }, "", USE.NAMES = FALSE)
}
cells <- function(xml) { tc <- regmatches(xml, gregexpr("<w:tc>.*?</w:tc>", xml, perl = TRUE))[[1]]
  vapply(tc, function(q) paste(paras(q), collapse = ""), "", USE.NAMES = FALSE) }
tr_json <- jsonlite::fromJSON(file.path("web", "app", "ceviri.json"), simplifyVector = FALSE)
rp <- g("R", a = "dosya")
for (i in seq_len(nrow(rp))) {
  id <- rp$durum[i]; lg <- rp$ayar[i]; f <- rp$deger[i]
  d <- tryCatch(doc_xml(f), error = function(e) NULL)
  if (is.null(d)) { put(paste("F-7", id, lg), FALSE, "açılamadı"); next }
  ok_xml <- !inherits(tryCatch(regmatches(d$xml, gregexpr("<w:body>.*</w:body>", d$xml)), error = function(e) e), "error") && grepl("</w:document>$", d$xml)
  vw <- jsonlite::fromJSON(v1("R", id, lg, "gorunum"), simplifyVector = FALSE)
  all_txt <- c(paras(d$xml), cells(d$xml))
  want <- c(vw$verdict, unlist(vw$main), unlist(lapply(vw$tables, function(t) c(t$title, unlist(t$head), unlist(t$rows)))),
            unlist(vw$des), unlist(vw$sum), unlist(vw$comp), unlist(vw$warnings), vw$source)
  missing <- setdiff(want, all_txt)
  dis <- c(tr_json$tr$disclaimer, tr_json$en$disclaimer)
  ok_dis <- all(dis %in% paras(d$xml)) && all(vapply(dis, function(s) grepl(s, xml_unesc(d$footer), fixed = TRUE), NA))
  put(paste("F-7", id, lg), ok_xml && !length(missing) && ok_dis,
      sprintf("%d metin; eksik %d%s; beyan %s; %s ms", length(want), length(missing),
              if (length(missing)) paste0(" (", paste(head(missing, 3), collapse = " | "), ")") else "", if (ok_dis) "var" else "YOK", v1("R", id, lg, "ms")))
}
put("F-7 rapor sayısı", nrow(rp) >= 8, sprintf("%d rapor (PBE ve 3 dissolüsyon, TR ve EN)", nrow(rp)))
mx <- num(v1("R-10", "", "", "en_uzun_ms")); put("F-7 süre", !is.na(mx) && mx <= 2000, sprintf("en uzun %.1f ms (≤ 2000)", mx))
f1 <- v1("R", "pbe-ornek-ham", "en", "dosya"); f2 <- v1("R-7", "pbe-ornek-ham", "en", "dosya")
if (!is.na(f1) && !is.na(f2)) {
  a <- doc_xml(f1)$xml; b <- doc_xml(f2)$xml
  strip <- function(x) gsub("[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC", "<zaman>", x)
  ra <- readBin(file.path(X, f1), "raw", file.size(file.path(X, f1))); rb <- readBin(file.path(X, f2), "raw", file.size(file.path(X, f2)))
  put("F-7 belirlenimcilik", identical(strip(a), strip(b)) && length(ra) == length(rb), sprintf("oluşturma zamanı dışında aynı; %d bayt", length(ra)))
} else put("F-7 belirlenimcilik", NA, "")

# ---------------------------------------------------------------- F-8 privacy
yi <- g("F-8", a = "yeni_istek"); ri <- g("R", a = "ag_istegi")
put("F-8 analiz", nrow(yi) > 0 && all(yi$deger == "0"), sprintf("%d analiz; dış istek toplamı %d", nrow(yi), sum(num(yi$deger))))
put("F-8 rapor", nrow(ri) > 0 && all(ri$deger == "0"), sprintf("%d rapor", nrow(ri)))
put("F-8 oturum", identical(v1("F-8", "son", "", "dis_istek"), "0"), "açılıştan sonra dış istek yok")

# ---------------------------------------------------------------- F-9 validation in the browser
lg9 <- g("F-9", a = "gecen_beklenen")
okl <- vapply(strsplit(lg9$deger, "/"), function(x) length(unique(x)) == 1, NA)
put("F-9 devralınan validasyon", nrow(lg9) == 5 && all(okl), paste(lg9$durum, lg9$deger, collapse = "; "))
tt <- g("F-9", a = "nb_fail_err_skip"); z <- do.call(rbind, lapply(strsplit(tt$deger, "/"), function(x) data.frame(nb = num(x[1]), f = num(x[2]), e = x[3], s = x[4])))
if (nrow(tt)) put("F-9 paket testleri (webR)", all(z$f == 0) && all(z$e == "false"),
                  sprintf("%d blok, %d beklenti, başarısız %d, hata %d, atlanan %d", nrow(z), sum(z$nb), sum(z$f), sum(z$e == "true"), sum(z$s == "true")))
else put("F-9 paket testleri (webR)", NA, "")

man <- readLines(file.path("web", "analiz", "dogrula_dosyalar.txt"), warn = FALSE)
gercek <- c("CNKfarmastatr/DESCRIPTION", sort(list.files(c("CNKfarmastatr/R", "CNKfarmastatr/inst", "CNKfarmastatr/tests/testthat"), recursive = TRUE, full.names = TRUE)))
put("F-9 dosya listesi", setequal(man[startsWith(man, "CNKfarmastatr/")], gercek), sprintf("liste %d, klasörler %d", sum(startsWith(man, "CNKfarmastatr/")), length(gercek)))

# ---------------------------------------------------------------- F-10 regression
pin <- utils::read.table(file.path("CNKfarmastatr", "inst", "validasyon", "CEKIRDEK_SHA256.txt"), col.names = c("sha", "f"), stringsAsFactors = FALSE)
okp <- vapply(seq_len(nrow(pin)), function(i) { b <- readBin(file.path(Rdir, pin$f[i]), "raw", file.size(file.path(Rdir, pin$f[i]))); identical(pk$.fsr_sha256(b), pin$sha[i]) }, NA)
put("F-10 sabitli çekirdekler", all(okp), sprintf("%d/%d", sum(okp), nrow(pin)))
kb <- file.path("CNKfarmastatr", "inst", "kopru", "dis_kopru.R")
put("F-10 dis_kopru.R (G-01)", identical(pk$.fsr_sha256(readBin(kb, "raw", file.size(kb))), "5dea054408d594a2eafecfeacde272bbc8f21e9da9507bbef1b15898274c4e28"), "")
mt <- jsonlite::fromJSON(v1("F-10", "motor", "", "dosyalar"), simplifyVector = FALSE)
n_ok <- sum(vapply(mt, function(r) length(r) >= 2 && grepl("^\u2713", r[[2]]), NA))
n_kay <- sum(vapply(mt, function(r) length(r) >= 2 && r[[1]] == "platform_analiz.R" && !grepl("\u2717", r[[2]]), NA))
# FSR-TN-PLT-08 v0.1 (KK-64): the screen also loads the pinned invitro_fast.R (EMA) -> 9 pinned + dis_kopru.R
put("F-10 ekran motor denetimi", v1("F-10", "motor", "", "durum") == "an_st_data_ok" && n_ok == 10 && n_kay == 1 &&
      any(vapply(mt, function(r) r[[1]] == "invitro_fast.R" && grepl("^\u2713", r[[2]]), NA)),
    sprintf("%d dosya \u2713 (9 sabitli, invitro_fast.R dahil, + dis_kopru.R); platform_analiz.R kaydedildi: %d", n_ok, n_kay))
p5z <- file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-05_ek", "p5", "p5_kabul.zip")
fn <- v1("F-10", "p5", "tr", "dosya")
if (file.exists(p5z) && !is.na(fn)) {
  d5 <- file.path(tempdir(), "p5z"); unlink(d5, recursive = TRUE); dir.create(d5)
  utils::unzip(p5z, files = "raporlar/tek-hazir-1_tr.docx", exdir = d5)
  file.copy(file.path(d5, "raporlar", "tek-hazir-1_tr.docx"), file.path(X, "p5_eski.docx"))
  a <- paras(doc_xml("p5_eski.docx")$xml); b <- paras(doc_xml(fn)$xml)
  drop <- function(p) p[!grepl("^(Oluşturma|Created)|^https?://|^Başlama|UTC", p)]
  # FSR-TN-PLT-09 (KK-66, T-3): only the two source sentences rp_src_ema and rp_src_sim may change, to the new text
  tr <- jsonlite::fromJSON(file.path("web", "app", "ceviri.json"))$tr
  src <- "^(EMA, CPMP/EWP/4151/00 Rev\\. 2, Bölüm 5\\.1|Morris, White ve Crowther 2019)"
  a2 <- drop(a); b2 <- drop(b)
  a2 <- a2[nzchar(trimws(a2))]; b2 <- b2[nzchar(trimws(b2))]   # empty spacing paragraphs (e.g. after a table) carry no text
  # FSR-TN-PLT-15 (KK-83): the only addition is the block of regulatory constants under Section 3
  cst <- c(tr$rp_s_const, tr$rp_const, tr$rp_value, tr$rp_source, tr$rp_c_alpha, "0,05", tr$rp_c_alpha_src,
           tr$rp_c_sigmaT0, "0,1", tr$rp_c_sigmaT0_src, tr$rp_c_thetap, "2,0891", tr$rp_c_thetap_src,
           tr$rp_c_ema, "0,85 \u2013 1,18", tr$rp_c_ema_src, tr$rp_const_note)
  k <- match(tr$rp_s_const, b2)
  ok_cst <- !is.na(k) && identical(trimws(b2[k:min(length(b2), k + length(cst) - 1)]), trimws(cst))
  if (!is.na(k)) b2 <- b2[-(k:(k + length(cst) - 1))]
  ia <- grepl(src, a2); ib <- grepl(src, b2)
  ok_src <- sum(ia) == 2 && sum(ib) == 2 && all(trimws(b2[ib]) %in% trimws(c(tr$rp_src_ema, tr$rp_src_sim)))
  put("F-10 P5 raporu değişmedi", identical(a2[!ia], b2[!ib]) && ok_src && ok_cst,
      sprintf("%d paragraf (oluşturma zamanı, bağlantı ve zaman satırları hariç); kaynak cümleleri yeni metinle: %s; düzenleyici sabitler bloğu (FSR-TN-PLT-15): %s",
              length(a2), if (ok_src) "evet" else "HAYIR", if (ok_cst) "eklendi, metni ceviri.json ile aynı" else "HAYIR"))
} else put("F-10 P5 raporu değişmedi", NA, "p5_kabul.zip ya da yeni rapor yok")

# ---------------------------------------------------------------- F-11, F-12
put("F-11 çeviri anahtarları", identical(names(tr_json$tr), names(tr_json$en)) && all(nzchar(unlist(tr_json$en))) && all(nzchar(unlist(tr_json$tr))),
    sprintf("%d anahtar", length(tr_json$tr)))
dk <- g("F-11", a = "yatay_kaydirma")
put("F-11 dar ekran (390 px)", nrow(dk) == 2 && all(dk$deger == "false"), paste(dk$ayar, dk$deger, collapse = "; "))
docs <- c(file.path("belgeler", "validasyon", "FSR-VAL-PLT-1_v1.0.docx"), file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-01_v0.7.docx"),
          file.path("web", "analiz", "README.md"), "CITATION.cff", ".zenodo.json", file.path("belgeler", "yayin", "YAYIN_KONTROL_LISTESI.md"))
put("F-12 belgeler", all(file.exists(docs)), paste(basename(docs)[!file.exists(docs)], collapse = ", "))

put("ortam", NA, paste(v1("ortam", "", "", "tarayici"), "·", v1("ortam", "", "", "sure_s"), "sn"))
res <- res[res$olcut != "ortam", ]
# ---------------------------------------------------------------- FSR-TN-PLT-11 (KK-75): Section 9 "Analysed data"
sha_f <- function(f) {
  if (requireNamespace("openssl", quietly = TRUE)) return(as.character(openssl::sha256(file(f))))
  if (requireNamespace("digest", quietly = TRUE)) return(digest::digest(file = f, algo = "sha256"))
  NA_character_ }
sec9 <- function(f) {                       # tables of Section 9 as lists of rows (cell texts)
  x <- doc_xml(f)$xml
  h <- regexpr("<w:p><w:pPr><w:pStyle w:val=\"Heading1\"/></w:pPr><w:r><w:t[^>]*>9\\. ", x, perl = TRUE)
  if (h < 0) return(NULL)
  y <- substring(x, h)
  head <- paras(regmatches(y, regexpr("<w:p>.*?</w:p>", y, perl = TRUE)))
  tbls <- regmatches(y, gregexpr("<w:tbl>.*?</w:tbl>", y, perl = TRUE))[[1]]
  rows <- lapply(tbls, function(tb) lapply(regmatches(tb, gregexpr("<w:tr>.*?</w:tr>", tb, perl = TRUE))[[1]], cells))
  list(head = head, tables = rows, paras = paras(y)) }
h9 <- c(tr = "9. Analiz edilen veri", en = "9. Analysed data")
TRJ <- tr_json
# D-1 every analysis report (P6 'R' rows and 'D' rows) has Section 9 in its language
allrep <- rbind(g("R", a = "dosya"), g("D", a = "dosya"))
d1 <- vapply(seq_len(nrow(allrep)), function(i) { z <- sec9(allrep$deger[i]); l <- allrep$ayar[i]
  !is.null(z) && identical(z$head, h9[[l]]) && length(z$tables) >= 1 &&
    all(c(TRJ[[l]]$rp_data_src, TRJ[[l]]$rp_data_sha, TRJ[[l]]$rp_data_products) %in% vapply(z$tables[[1]], `[`, "", 1)) }, NA)
put("D-1 bölüm 9 (P6 raporları)", nrow(allrep) > 0 && all(d1), sprintf("%d/%d rapor (PBE, MSD, Weibull, f2; TR ve EN)", sum(d1), nrow(allrep)))
ex <- g("R", a = "dosya")
d1e <- vapply(seq_len(nrow(ex)), function(i) { z <- sec9(ex$deger[i]); l <- ex$ayar[i]; if (is.null(z)) return(FALSE)
  v <- Filter(function(r) identical(r[1], TRJ[[l]]$rp_data_sha), z$tables[[1]])
  length(v) == 1 && startsWith(v[[1]][2], sub(" \\(.*$", "", TRJ[[l]]$rp_data_example)) }, NA)
put("D-1 örnek veri etiketi", nrow(ex) > 0 && all(d1e), sprintf("%d/%d örnek veri raporunda “örnek veri, parmak izi yok”", sum(d1e), nrow(ex)))
# D-2, D-3, D-4, D-6 for the uploaded files
for (sec in c("pbe", "dis")) {
  src <- v1("D", sec, "", "kaynak"); fm <- jsonlite::fromJSON(v1("D", sec, "", "form"))
  if (is.na(src)) { put(paste("D-2", sec), NA, "kayıt yok"); next }
  hs <- sha_f(src); scr <- v1("D", sec, "", "ekran")
  dr <- g("D", a = "dosya"); dr <- dr[startsWith(dr$durum, paste0(sec, "|")), ]
  shas <- vapply(dr$deger, function(f) { z <- sec9(f); l <- dr$ayar[dr$deger == f][1]
    v <- Filter(function(r) identical(r[1], TRJ[[l]]$rp_data_sha), z$tables[[1]]); if (length(v)) v[[1]][2] else "" }, "")
  put(paste("D-2", sec), !is.na(hs) && all(shas == hs) && grepl(paste0("SHA-256 ", hs), scr, fixed = TRUE),
      if (is.na(hs)) "R'de SHA-256 için openssl ya da digest paketi gerekli: install.packages('openssl')" else sprintf("%s · %d rapor ve ekran = yerel R", substr(hs, 1, 16), length(shas)))
  txt <- paste(readLines(src, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  v <- if (sec == "pbe") pk$platform_pbe_veri(txt) else pk$platform_dis_veri(txt)
  used <- c(fm$test, fm$ref, if (sec == "dis") unlist(fm$lotlar))
  if (sec == "pbe") { i <- v$urun %in% used; exp <- cbind(v$parti[i], v$kap[i], v$asama[i], v$urun[i], v$olcum[i]) }
  else { i <- v$Product %in% used; exp <- cbind(v$Product[i], v$Unit[i], v$Time[i], v$Diss[i]) }
  okD3 <- vapply(seq_len(nrow(dr)), function(k) { z <- sec9(dr$deger[k]); l <- dr$ayar[k]; with <- endsWith(dr$durum[k], "|1")
    if (!with) return(length(z$tables) == 1 && TRJ[[l]]$rp_data_omitted %in% z$paras)
    if (length(z$tables) != 2) return(FALSE)
    body <- do.call(rbind, z$tables[[2]][-1]); if (nrow(body) != nrow(exp)) return(FALSE)
    if (sec == "pbe") identical(unname(body), unname(exp))
    else identical(body[, 1:2], unname(exp[, 1:2])) && identical(as.numeric(body[, 3]), v$Time[i]) && identical(as.numeric(body[, 4]), v$Diss[i]) }, NA)
  put(paste("D-3", sec), nrow(dr) > 0 && all(okD3), sprintf("%d rapor; kutu boşken tablo yok, işaretliyken %d satır = yerel R", sum(okD3), nrow(exp)))
  put(paste("D-6", sec), all(g("D", a = "ag_istegi")$deger[startsWith(g("D", a = "ag_istegi")$durum, paste0(sec, "|"))] == "0"), "rapor üretiminde dış istek 0")
}
f1 <- v1("D", "pbe|1", "tr", "dosya"); f2 <- v1("D", "pbe-tekrar|1", "tr", "dosya")
if (!is.na(f1) && !is.na(f2)) {
  strip <- function(x) gsub("[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC", "<zaman>", x)
  put("D-4 belirlenimcilik", identical(strip(doc_xml(f1)$xml), strip(doc_xml(f2)$xml)), "veri tablosuyla iki rapor oluşturma zamanı dışında aynı")
} else put("D-4 belirlenimcilik", NA, "")
put("D-8 kutu varsayılanı", identical(v1("D-8", "kutu", "pbe", "varsayilan_isaretli"), "false") && identical(v1("D-8", "kutu", "dis", "varsayilan_isaretli"), "false"),
    "“Veriyi rapora ekle” iki sekmede de varsayılan olarak boş")
put("D-8 çeviri", all(c("an_with_data", "rp_s_data", "rp_data_omitted") %in% names(TRJ$tr)) && identical(sort(names(TRJ$tr)), sort(names(TRJ$en))), "yeni anahtarlar TR ve EN")

# ---------------------------------------------------------------- FSR-TN-PLT-12 (KK-78): wide layout, dissolution only
wv <- function(id, a, sec = "dis") v1("W", id, sec, a)
if (!nrow(g("W"))) put("W geniş biçim", NA, "W satırı yok") else {
  rdw <- function(f) paste(readLines(f, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  fT <- wv("tsong-genis", "kaynak"); fN <- wv("noce-genis", "kaynak")
  vT <- pk$platform_dis_veri(rdw(fT)); vN <- pk$platform_dis_veri(rdw(fN))
  put("W-1/3/4 okuma (ekran)", identical(wv("tsong-genis", "veri_durum"), "an_st_data_ok") && identical(wv("noce-genis", "veri_durum"), "an_st_data_ok") &&
        grepl(" 192 ", wv("tsong-genis", "ekran"), fixed = TRUE) && length(vT$Diss) == 192,
      "DDSolver düzeni (';', ondalık virgül, ikinci başlık satırı) ve ',' dosyası okundu; Tsong 192 değer")
  put("W-7 varsayılan seçim", identical(c(wv("tsong-genis", "test_varsayilan"), wv("tsong-genis", "ref_varsayilan")), c("Test", "Ref")) &&
        identical(c(wv("noce-genis", "test_varsayilan"), wv("noce-genis", "ref_varsayilan")), c("Urun1", "Urun2")),
      sprintf("Tsong: %s/%s (ad); Noce: %s/%s (ilk iki ürün)", wv("tsong-genis", "test_varsayilan"), wv("tsong-genis", "ref_varsayilan"),
              wv("noce-genis", "test_varsayilan"), wv("noce-genis", "ref_varsayilan")))
  for (id in c("tsong-genis", "noce-genis")) {
    if (!identical(wv(id, "durum"), "an_st_done")) { put(paste("W-8", id), FALSE, paste("durum:", wv(id, "durum"))); next }
    fm <- jsonlite::fromJSON(wv(id, "form"), simplifyVector = TRUE); ay <- fm$ayar[!vapply(fm$ayar, is.null, NA)]
    vg <- if (id == "tsong-genis") vT else vN
    vu <- pk$platform_dis_veri(ornek = if (id == "tsong-genis") "tsong1996" else "noce2020")
    tr <- if (id == "tsong-genis") c(Test = "TEST", Ref = "REF") else c(Urun1 = "Urun1", Urun2 = "Urun2")
    lg <- pk$platform_dis(kp, vg, fm$test, fm$ref, unlist(fm$lotlar), fm$birim, fm$yontem, ay)$sonuc
    lu <- pk$platform_dis(kp, vu, tr[[fm$test]], tr[[fm$ref]], unlist(fm$lotlar), fm$birim, fm$yontem, ay)$sonuc
    c1 <- cmp(wv(id, "sonuc"), lg)
    put(paste("W-8", id), identical(lg, lu) && c1$ok,
        sprintf("%s: R geniş = R uzun (identical); ekran = R, %d alan%s", fm$yontem, c1$n, if (length(c1$bad)) paste0("; farklı: ", paste(c1$bad, collapse = ", ")) else ""))
  }
  rf <- wv("tsong-genis", "rapor", "tr"); z <- if (is.na(rf)) NULL else sec9(rf); hs <- sha_f(fT)
  okW9 <- !is.null(z) && length(z$tables) == 2 && {
    sh <- Filter(function(r) identical(r[1], TRJ$tr$rp_data_sha), z$tables[[1]])
    body <- do.call(rbind, z$tables[[2]][-1])
    length(sh) == 1 && isTRUE(sh[[1]][2] == hs) && nrow(body) == 192 && identical(unname(body[, 1:2]), cbind(vT$Product, vT$Unit)) &&
      identical(as.numeric(body[, 3]), vT$Time) && identical(as.numeric(body[, 4]), vT$Diss) }
  put("W-9 rapor bölüm 9", isTRUE(okW9) && identical(wv("tsong-genis", "ag_istegi", "tr"), "0"),
      sprintf("SHA-256 %s = yerel; tablo uzun biçimde 192 satır = yerel R", substr(hs, 1, 16)))
  put("W-5 boş hücre (ekran)", identical(wv("bos-hucre", "veri_durum"), "an_st_data_error") && grepl("column Test.2, time 5", wv("bos-hucre", "hata"), fixed = TRUE) &&
        identical(wv("bos-hucre", "calistir_etkin"), "false"), wv("bos-hucre", "hata"))
  put("W-0 PBE paneli geniş biçimi okumaz", identical(wv("pbe-genis", "veri_durum", "pbe"), "an_st_data_error") &&
        grepl("Missing column", wv("pbe-genis", "hata", "pbe"), fixed = TRUE) && identical(wv("pbe-genis", "calistir_etkin", "pbe"), "false"),
      wv("pbe-genis", "hata", "pbe"))
  sb <- pk$platform_dis_veri(rdw(file.path("web", "yardim", "sablon", "dis_sablon_en.csv")))
  hd <- strsplit(readLines(file.path("web", "yardim", "sablon", "dis_sablon_en.csv"), n = 1, warn = FALSE), ",")[[1]]
  put("W-10 şablon", identical(hd, c("Time", paste0(rep(c("Test", "Ref", "STD1", "STD2"), each = 6), ".", 1:6))) &&
        identical(sb$Diss, pk$platform_dis_veri(ornek = "tsong1996")$Diss), "geniş biçim; değerler Tsong örneğiyle aynı")
  yj <- jsonlite::fromJSON(file.path("web", "yardim", "yardim.json"), simplifyVector = FALSE)
  ph <- function(l) paste(vapply(yj[[l]]$panel$dis, function(b) if (is.null(b$html)) "" else b$html, ""), collapse = " ")
  put("W-11 yardım metni", all(vapply(c("tr", "en"), function(l) grepl("Test.1", ph(l), fixed = TRUE) && grepl("Product, Unit, Time, Diss", ph(l), fixed = TRUE), NA)),
      "dissolüsyon paneli TR ve EN: geniş biçim ve uzun biçim")
  t9 <- g("F-9", "test-platform-dis-genis.R", a = "nb_fail_err_skip")
  put("W-2/5/6/8 paket testleri (webR)", nrow(t9) == 9 && all(vapply(strsplit(t9$deger, "/"), function(x) x[2] == "0" && x[3] == "false" && x[4] == "false", NA)),
      sprintf("test-platform-dis-genis.R: %d blok", nrow(t9)))
}

# ---------------------------------------------------------------- FSR-TN-PLT-14 (KK-80): charts, variability, bootstrap files
gv <- function(id, a, y = "") v1("G", id, y, a)
if (!nrow(g("G"))) put("G grafik/bootstrap", NA, "G satırı yok") else {
  med <- function(f) { z <- utils::unzip(file.path(X, f), list = TRUE)$Name; sort(z[startsWith(z, "word/media/")]) }
  rd_m <- function(f, m) { d <- file.path(tempdir(), "p6_med"); unlink(d, recursive = TRUE); dir.create(d); utils::unzip(file.path(X, f), files = m, exdir = d)
    readBin(file.path(d, m), "raw", file.size(file.path(d, m))) }
  png_sig <- as.raw(c(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a))
  nimg <- c(f2 = 2L, msd = 1L, wb = 1L)
  loc_run <- function(id) { fm <- jsonlite::fromJSON(gv(id, "form"), simplifyVector = TRUE); ay <- fm$ayar[!vapply(fm$ayar, is.null, NA)]
    v <- pk$platform_dis_veri(ornek = if (id == "f2") "noce2020" else "tsong1996")
    pk$platform_dis(kp, v, fm$test, fm$ref, unlist(fm$lotlar), fm$birim, fm$yontem, ay) }
  for (id in names(nimg)) {
    if (!identical(gv(id, "durum"), "an_st_done")) { put(paste("GR-1", id), FALSE, paste("durum:", gv(id, "durum"))); next }
    r <- loc_run(id)
    gl <- pk$platform_dis_grafik(kp, r); dl <- pk$platform_dis_degiskenlik(r)
    c1 <- cmp(gv(id, "grafik"), gl[setdiff(names(gl), c("hist", "egri"))])
    c2 <- if (!is.null(gl$hist)) cmp(jsonlite::toJSON(jsonlite::fromJSON(gv(id, "grafik"), simplifyVector = FALSE)$hist, auto_unbox = TRUE, digits = NA), gl$hist) else list(ok = TRUE, n = 0, bad = character(0))
    c3 <- if (!is.null(gl$egri)) cmp(jsonlite::toJSON(jsonlite::fromJSON(gv(id, "grafik"), simplifyVector = FALSE)$egri, auto_unbox = TRUE, digits = NA), gl$egri) else list(ok = TRUE, n = 0, bad = character(0))
    put(paste("GR-4", id), c1$ok && c2$ok && c3$ok, sprintf("grafik verisi = yerel R (%d + %d + %d alan)%s", c1$n, c2$n, c3$n,
        if (length(c(c1$bad, c2$bad, c3$bad))) paste0("; farklı: ", paste(c(c1$bad, c2$bad, c3$bad), collapse = ", ")) else ""))
    c4 <- cmp(gv(id, "degiskenlik"), dl)
    put(paste("DV-2", id), c4$ok, sprintf("CV_T, CV_R, oran = yerel R (%d alan)", c4$n))
    okr <- vapply(c("tr", "en"), function(lg) { f <- gv(id, "rapor", lg); m <- med(f); x <- doc_xml(f)$xml; pp <- paras(x)
      length(m) == nimg[[id]] && all(vapply(m, function(k) identical(rd_m(f, k)[1:8], png_sig), NA)) &&
        TRJ[[lg]]$an_charts %in% pp && lengths(regmatches(x, gregexpr("r:embed=\"rIdImg", x, fixed = TRUE))) == nimg[[id]] &&
        (id != "f2" || any(startsWith(pp, sub("\\{e\\}.*$", "", TRJ[[lg]]$an_ch_hist)))) &&
        (id != "wb" || TRJ[[lg]]$an_ch_weibull %in% pp) && (id == "wb" || TRJ[[lg]]$an_ch_profile %in% pp) &&
        TRJ[[lg]]$an_var_table %in% pp && TRJ[[lg]]$an_var_note %in% pp }, NA)
    put(paste("GR-1/2/3, DV-1 rapor", id), all(okr) && identical(gv(id, "canvas", "ekran"), as.character(nimg[[id]])),
        sprintf("TR %s, EN %s; %d PNG; ekranda %s grafik; değişkenlik tablosu ve EMA alıntısı", okr[1], okr[2], nimg[[id]], gv(id, "canvas", "ekran")))
    put(paste("DV-1 ekran", id), identical(gv(id, "dv_tablo", "ekran"), "true") && identical(gv(id, "dv_not", "ekran"), TRJ$tr$an_var_note), "tablo ve alıntı ekranda")
    put(paste("GR-6 dış istek", id), all(c(gv(id, "ag_istegi", "tr"), gv(id, "ag_istegi", "en"), gv(id, "ag_analiz")) == "0"), "analiz ve rapor")
  }
  put("N-1 örnek varsayılanı (G)", identical(gv("f2", "varsayilan", "secim"), "Urun1/Urun3"),
      sprintf("dosyadan sonra Noce örneği: %s (beklenen Urun1/Urun3)", gv("f2", "varsayilan", "secim")))
  f1 <- gv("f2", "rapor", "tr"); f2b <- gv("f2", "rapor_tekrar", "tr")
  strip <- function(x) gsub("[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC", "<zaman>", x)
  put("GR-6 belirlenimcilik", identical(strip(doc_xml(f1)$xml), strip(doc_xml(f2b)$xml)) &&
        all(vapply(med(f1), function(k) identical(rd_m(f1, k), rd_m(f2b, k)), NA)), "aynı tarayıcıda iki rapor: metin ve PNG baytları aynı")
  pr <- g("D", a = "dosya"); pr <- pr$deger[startsWith(pr$durum, "pbe")]
  put("GR-7 PBE/EMA raporu", length(pr) > 0 && all(vapply(pr, function(f) !length(med(f)), NA)), sprintf("%d PBE raporunda resim yok", length(pr)))
  # BS
  put("BS-1 kutular", identical(gv("f2", "kutu_gorunur", "bs"), "true") && identical(gv("msd", "kutu_gorunur", "bs"), "false") &&
        identical(gv("wb", "kutu_gorunur", "bs"), "false") && identical(v1("G", "bs", "", "csv_varsayilan"), "false") &&
        identical(v1("G", "bs", "", "idx_etkin_once"), "false") && identical(v1("G", "bs", "", "idx_etkin_sonra"), "true") &&
        identical(v1("G", "bs", "", "idx_varsayilan"), "false"), "yalnız f2'de görünür; ikisi de boş; ikincisi birincisiyle etkin")
  rf <- loc_run("f2"); ff <- kp$.kp$f2
  fm <- jsonlite::fromJSON(gv("f2", "form"), simplifyVector = TRUE)
  rdx <- function(f) { x <- readLines(file.path(X, f), encoding = "UTF-8", warn = FALSE); list(bas = x[startsWith(x, "#")], d = utils::read.csv(file.path(X, f), comment.char = "#")) }
  A <- rdx(v1("G", "bs", "a", "csv")); Bx <- rdx(v1("G", "bs", "b", "csv"))
  sc <- jsonlite::fromJSON(gv("f2", "sonuc"), simplifyVector = TRUE)
  keys <- c("package:", "data_sha256:", "seed = ", "RNG = ", "estimator = ", "truncation = ", "truncation mode = ", "interval = ",
            "quantile type = ", "test: ", "time points", "point estimates", "decision interval", "percentile interval of")
  put("BS-2 künye", all(vapply(keys, function(k) any(grepl(k, A$bas, fixed = TRUE)), NA)) &&
        any(grepl(paste0("data_sha256: "), A$bas, fixed = TRUE)), sprintf("%d künye satırı", length(A$bas)))
  # webR and the local R may differ in the last bit; full precision in the file is shown by BS-5 (exact) and
  # by the package tests (identical); here the values are compared with the local R as the F rows: K()
  kv <- function(a, b) identical(is.na(a), is.na(b)) && all(K(a[!is.na(a)], b[!is.na(b)]))
  okv <- all(vapply(c("f2", "Ef2", "bcf2"), function(k) kv(A$d[[k]], unname(ff$replikalar[, k])) && identical(A$d[[k]], Bx$d[[k]]), NA)) &&
    identical(as.numeric(A$d$P), unname(ff$replikalar[, "P"])) && nrow(A$d) == ff$B
  hd <- function(k) { ln <- grep("point estimates", A$bas, value = TRUE); num(sub(paste0("^.*[:;] ", k, " = ([^;]+).*$"), "\\1", ln)) }
  okh <- identical(hd("Ef2"), num(sc$Ef2)) && identical(hd("f2"), num(sc$f2))
  put("BS-3 replika değerleri", okv && okh, sprintf("%d replika = yerel R, K(1e-12); iki düzey aynı; künyedeki nokta tahminleri = ekran", nrow(A$d)))
  nT <- ncol(ff$idx$T); nR <- ncol(ff$idx$R)
  oki <- identical(unname(as.matrix(Bx$d[, paste0("T", seq_len(ncol(ff$idx$T)))])), unname(ff$idx$T) + 0L) &&
    identical(unname(as.matrix(Bx$d[, paste0("R", seq_len(ncol(ff$idx$R)))])), unname(ff$idx$R) + 0L) &&
    any(grepl("test units: 1=", Bx$bas, fixed = TRUE)) && !any(grepl("^T1$", names(A$d)))
  put("BS-4 tablet indeksleri", oki, "indeksli düzeyde T ve R sıra numaraları = yerel R; yalın düzeyde yok")
  a2 <- (1 - ff$conf) / 2; v <- A$d[[ff$tahminci]]; v <- v[is.finite(v)]
  q <- unname(stats::quantile(v, c(a2, 1 - a2), type = ff$q_type))
  put("BS-5 persentil", identical(q, c(num(sc$alt), num(sc$ust))) || all(K(q, c(num(sc$alt), num(sc$ust)))),
      sprintf("CSV'den %s – %s = ekran %s – %s", format(q[1], digits = 17), format(q[2], digits = 17), sc$alt, sc$ust))
  ss <- v1("G", "bs", "b", "sas")
  okS <- !is.na(ss) && is.na(v1("G", "bs", "a", "sas")) && {
    L <- readLines(file.path(X, ss), encoding = "UTF-8", warn = FALSE)
    i <- which(L == "data test_u; input x1-x&nP; datalines;"); j <- which(L == "data ref_u; input x1-x&nP; datalines;")
    dt <- do.call(rbind, lapply(strsplit(L[(i + 1):(i + nT)], " "), as.numeric)); dr <- do.call(rbind, lapply(strsplit(L[(j + 1):(j + nR)], " "), as.numeric))
    identical(unname(dt), unname(ff$kontrol$XT_tum)) && identical(unname(dr), unname(ff$kontrol$XR_tum)) &&
      any(grepl(sprintf("%%let rule = %s;", ff$kontrol$truncation), L, fixed = TRUE)) && any(grepl(sprintf("%%let est = %s;", ff$tahminci), L, fixed = TRUE)) &&
      any(grepl(sprintf("%%let B = %d;", ff$B), L, fixed = TRUE)) && any(grepl("proc iml;", L, fixed = TRUE)) }
  put("BS-6 SAS programı", isTRUE(okS), "yalnız indeksli düzeyde; gömülü veri ve makro değerleri = yerel R")
  put("BS-8 dış istek", identical(v1("G", "bs", "a", "ag_istegi"), "0") && identical(v1("G", "bs", "b", "ag_istegi"), "0"), "dosya üretiminde dış istek 0")
}

utils::write.csv(res, file.path(E, "p6_kabul.csv"), row.names = FALSE, fileEncoding = "UTF-8")
writeLines(utils::capture.output(utils::sessionInfo()), file.path(E, "p6_yerel_sessionInfo.txt"), useBytes = TRUE)
cat(sprintf("\nToplam: %d ölçüt satırı; GECTI %d, KALDI %d, EKSIK %d. Ayrıntı: %s\n", nrow(res), sum(res$sonuc == "GECTI"),
            sum(res$sonuc == "KALDI"), sum(res$sonuc == "EKSIK"), file.path(E, "p6_kabul.csv")))
})
