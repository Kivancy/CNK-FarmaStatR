# =============================================================================
# CNK-FarmaStatR - P6 acceptance (FSR-TN-PLT-06 v0.1, Table 7.1; frozen in v0.1)
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
# expected number of analyses: PBE example 3 + files 24 valid (30 runs, 6 rejected; F-2); dissolution 10
nf <- sum(grepl("\\|", ids) & !grepl("^(tsong1996|noce2020)", ids))
put("F-1 kapsam", length(grep("^pbe-ornek", ids)) == 3 && nf == 24, sprintf("örnek %d, test verisi %d (beklenen 3 ve 24)", length(grep("^pbe-ornek", ids)), nf))
put("F-3/4/5 kapsam", sum(grepl("^(tsong1996|noce2020)\\|", ids)) == 10, sprintf("%d dissolüsyon durumu (beklenen 10)", sum(grepl("^(tsong1996|noce2020)\\|", ids))))
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
  put("F-10 P5 raporu değişmedi", identical(drop(a), drop(b)), sprintf("%d paragraf (oluşturma zamanı, bağlantı ve zaman satırları hariç)", length(drop(a))))
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
utils::write.csv(res, file.path(E, "p6_kabul.csv"), row.names = FALSE, fileEncoding = "UTF-8")
writeLines(utils::capture.output(utils::sessionInfo()), file.path(E, "p6_yerel_sessionInfo.txt"), useBytes = TRUE)
cat(sprintf("\nToplam: %d ölçüt satırı; GECTI %d, KALDI %d, EKSIK %d. Ayrıntı: %s\n", nrow(res), sum(res$sonuc == "GECTI"),
            sum(res$sonuc == "KALDI"), sum(res$sonuc == "EKSIK"), file.path(E, "p6_kabul.csv")))
})
