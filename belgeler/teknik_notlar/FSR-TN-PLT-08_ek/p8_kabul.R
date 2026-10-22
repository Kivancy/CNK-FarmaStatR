# =============================================================================
# CNK-FarmaStatR - EMA acceptance (FSR-TN-PLT-08 v0.1, Table 5.1; frozen in v0.1)
#
# Reads the browser output of web/analiz/kabul8.html (p8/p8_kabul.zip:
# p8_tarayici.csv and the Word reports) and writes one line per criterion:
# GECTI, KALDI or EKSIK.
#   E-1 screen = local platform_ema (PSG example raw and log, test data files,
#       Turkish CSV); the FDA path on the same screen = local platform_pbe
#   E-4 input errors: the R message on the screen, no result, buttons passive
#   E-5 reports: screen texts in the .docx, disclaimer TR and EN, deterministic,
#       no network request; no outside request in the session
#   E-6 method choice: one-sided box hidden in EMA, report passive after a change
#   E-9 TR/EN keys; English screen; narrow screen (390 px)
#   E-10 documents present
# E-2, E-3 are testthat A-9, A-10 (CI); E-7 the P6 acceptance tool; E-8 the help
# acceptance tool.
# Numbers: K(1e-12, 1e-12); texts and decisions exactly. Run from the repository root:
#   source("belgeler/teknik_notlar/FSR-TN-PLT-08_ek/p8_kabul.R", encoding = "UTF-8")
# Base R plus jsonlite. Research and education only; not a system validated for
# GxP environments.
# =============================================================================
local({
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("jsonlite is needed: install.packages('jsonlite')")
E <- file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-08_ek")
zf <- file.path(E, "p8", "p8_kabul.zip")
if (!file.exists(zf)) stop("p8/p8_kabul.zip not found")
X <- file.path(tempdir(), "p8_kabul"); unlink(X, recursive = TRUE); dir.create(X)
utils::unzip(zf, exdir = X)
br <- utils::read.csv(file.path(X, "p8_tarayici.csv"), colClasses = "character", encoding = "UTF-8", na.strings = character(0))
if (nrow(br) == 0) stop("p8_tarayici.csv is empty")

Rdir <- file.path("CNKfarmastatr", "R")
coll <- strsplit(gsub("'", "", read.dcf(file.path("CNKfarmastatr", "DESCRIPTION"), fields = "Collate")[1, 1]), "[[:space:]]+")[[1]]
pk <- new.env(parent = globalenv())
for (f in coll[nzchar(coll)]) sys.source(file.path(Rdir, f), envir = pk, keep.source = FALSE)

res <- data.frame(olcut = character(0), sonuc = character(0), ayrinti = character(0), stringsAsFactors = FALSE)
put <- function(o, ok, a) { s <- if (is.na(ok)) "EKSIK" else if (isTRUE(ok)) "GECTI" else "KALDI"
  res[nrow(res) + 1, ] <<- c(o, s, a); cat(sprintf("%-34s %-6s %s\n", o, s, a)) }
g <- function(b, d = NULL, y = NULL, a = NULL) { x <- br[br$bolum == b, ]
  if (!is.null(d)) x <- x[x$durum == d, ]; if (!is.null(y)) x <- x[x$ayar == y, ]; if (!is.null(a)) x <- x[x$ad == a, ]; x }
v1 <- function(b, d, y, a) { x <- g(b, d, y, a)$deger; if (length(x) == 1) x else NA_character_ }
K <- function(a, b) abs(a - b) <= 1e-12 + 1e-12 * pmax(abs(a), abs(b))
num <- function(x) suppressWarnings(as.numeric(x))
TV <- file.path("CNKfarmastatr", "inst", "validasyon", "pbe", "test_verisi")
oku <- function(id) {
  if (grepl("^(ema|fda)-ornek", id)) pk$platform_pbe_veri(ornek = "psg020929")
  else if (id == "ema-csv-tr") pk$platform_pbe_veri(paste(readLines(file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-06_ek", "veri", "psg020929_tr.csv"), encoding = "UTF-8", warn = FALSE), collapse = "\n"))
  else pk$platform_pbe_veri(paste(readLines(file.path(TV, sub("\\|.*$", "", id)), warn = FALSE), collapse = "\n"))
}

# compare a screen result (JSON) with the local one: numbers K(), others exactly; JSON null = NA
cmp <- function(js, loc) {
  a <- jsonlite::fromJSON(js, simplifyVector = FALSE)
  nn <- function(z) if (is.null(z)) NA else if (is.list(z)) unlist(lapply(z, nn), use.names = FALSE) else z
  bad <- character(0)
  for (n in names(loc)) {
    vb <- unlist(loc[[n]], use.names = FALSE); va <- nn(a[[n]])
    ok <- if (is.numeric(vb)) { va <- num(va); length(va) == length(vb) && all((is.na(va) & is.na(vb)) | (!is.na(va) & !is.na(vb) & K(va, vb))) }
          else if (is.logical(vb)) identical(as.logical(va), vb)
          else identical(as.character(va), as.character(vb))
    if (!isTRUE(ok)) bad <- c(bad, n)
  }
  extra <- setdiff(names(a), names(loc))
  list(ok = !length(bad), bad = c(bad, if (length(extra)) paste0("+", extra)), n = length(names(loc)))
}

# ---------------------------------------------------------------- E-1
ids <- unique(g("F", a = "sonuc")$durum)
yerel <- list()
for (id in ids) {
  form <- jsonlite::fromJSON(v1("F", id, "pbe", "form"), simplifyVector = TRUE)
  ema <- identical(form$yontem, "ema")
  r <- tryCatch(if (ema) pk$platform_ema(oku(id), form$test, form$ref, isTRUE(form$log_d))
                else pk$platform_pbe(oku(id), form$test, form$ref, isTRUE(form$log_d), isTRUE(form$tek)), error = function(e) e)
  yerel[[id]] <- r
  c1 <- if (inherits(r, "error")) list(ok = FALSE, bad = paste("R:", conditionMessage(r)), n = 0) else cmp(v1("F", id, "pbe", "sonuc"), r$sonuc)
  uy <- if (ema && !inherits(r, "error")) identical(jsonlite::fromJSON(v1("F", id, "pbe", "uyarilar")), as.character(r$hazir$uyarilar)) ||
          (length(r$hazir$uyarilar) == 0 && identical(v1("F", id, "pbe", "uyarilar"), "[]")) else TRUE
  ek <- if (ema) identical(v1("F", id, "pbe", "fda_gizli"), "true") && identical(v1("F", id, "pbe", "karar_satiri"), "dline") else TRUE
  put(paste(if (ema) "E-1" else "E-1 FDA", id), c1$ok && uy && ek,
      sprintf("%d alan%s; uyarılar %s; karar satırı %s", c1$n, if (length(c1$bad)) paste0("; farklı: ", paste(c1$bad, collapse = ", ")) else "",
              if (uy) "aynı" else "FARKLI", v1("F", id, "pbe", "karar_satiri")))
}
nf <- sum(grepl("\\|(ham|log)$", ids))
put("E-1 kapsam", all(c("ema-ornek-ham", "ema-ornek-log", "ema-csv-tr", "fda-ornek-ham") %in% ids) && nf == 13,
    sprintf("örnek 2 + FDA 1 + Türkçe CSV 1; test verisi %d (beklenen 13: 20 koşu, 7 hata)", nf))
if (!is.null(yerel[["ema-csv-tr"]]) && !is.null(yerel[["ema-ornek-ham"]]))
  put("E-1 Türkçe CSV = örnek", identical(yerel[["ema-csv-tr"]]$sonuc, yerel[["ema-ornek-ham"]]$sonuc), "yerel R'de birebir")
if (!is.null(yerel[["P5_exp.csv|log"]]) && !is.null(yerel[["ema-ornek-ham"]])) {
  a <- yerel[["P5_exp.csv|log"]]$sonuc; b <- yerel[["ema-ornek-ham"]]$sonuc
  put("E-1 ham + log = log ölçeği", all(abs(c(a$alt, a$ust) - c(b$alt, b$ust)) < 1e-12), "P5_exp (exp ölçeği) log ile = PSG örneği")
}
ex <- yerel[["ema-ornek-ham"]]$sonuc
if (!is.null(ex)) put("E-1 PSG örneği referansı", identical(round(c(ex$alt[2], ex$ust[2]), 6), c(0.877170, 1.534702)) && identical(ex$karar, FALSE),
                      sprintf("(b) %.6f–%.6f, karar %s (FSR-TN-PLT-08 Bölüm 3)", ex$alt[2], ex$ust[2], ex$karar))
p6 <- yerel[["P6_sinir_esit.csv|ham"]]$sonuc
if (!is.null(p6)) put("E-1 hesaplanamayan yol", is.na(p6$karar) && all(is.na(p6$alt[2:3])) && grepl("Karar verilemedi|No decision", v1("F", "P6_sinir_esit.csv|ham", "pbe", "karar_metni")),
                      v1("F", "P6_sinir_esit.csv|ham", "pbe", "karar_metni"))

# ---------------------------------------------------------------- E-4 errors
err <- unique(g("E-4", a = "hata")$durum)
exp_err <- c("P3_dengesiz.csv|ham", "P3_dengesiz.csv|log", "P5_negatif.csv|log", "P5_stage_hata.csv|ham", "P5_stage_hata.csv|log",
             "P6_sinir_esit.csv|log", "P6_sinir_ustu.csv|log")
put("E-4 hatalı durumlar", setequal(err, exp_err), paste(sort(err), collapse = "; "))
for (id in err) {
  msg <- tryCatch({ pk$platform_ema(oku(id), "TEST", "REF", grepl("\\|log$", id)); "" }, error = conditionMessage)
  ekran <- v1("E-4", id, "pbe", "hata")
  ok <- nzchar(msg) && grepl(msg, ekran, fixed = TRUE) && v1("E-4", id, "pbe", "sonuc_gizli") == "true" &&
    v1("E-4", id, "pbe", "rapor_etkin") == "false" && v1("E-4", id, "pbe", "json_etkin") == "false"
  put(paste("E-4", id), ok, substr(msg, 1, 90))
}
ok_on <- g("E-4", a = "rapor_etkin"); ok_on <- ok_on[ok_on$durum %in% ids, ]
put("E-4 sonuçta rapor etkin", nrow(ok_on) > 0 && all(ok_on$deger == "true"), sprintf("%d sonuç", nrow(ok_on)))

# ---------------------------------------------------------------- E-5 reports
xml_unesc <- function(s) { s <- gsub("&lt;", "<", s, fixed = TRUE); s <- gsub("&gt;", ">", s, fixed = TRUE)
  s <- gsub("&quot;", "\"", s, fixed = TRUE); gsub("&amp;", "&", s, fixed = TRUE) }
doc_xml <- function(f) { d <- file.path(tempdir(), "p8_docx"); unlink(d, recursive = TRUE); dir.create(d)
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
  if (is.null(d)) { put(paste("E-5", id, lg), FALSE, "açılamadı"); next }
  ok_xml <- grepl("</w:document>$", d$xml)
  vw <- jsonlite::fromJSON(v1("R", id, lg, "gorunum"), simplifyVector = FALSE)
  all_txt <- c(paras(d$xml), cells(d$xml))
  want <- c(vw$verdict, unlist(vw$main), unlist(vw$pathsHead), unlist(vw$paths), vw$note, unlist(vw$des), unlist(vw$sum), unlist(vw$warnings), vw$source)
  missing <- setdiff(want, all_txt)
  dis <- c(tr_json$tr$disclaimer, tr_json$en$disclaimer)
  ok_dis <- all(dis %in% paras(d$xml)) && all(vapply(dis, function(s) grepl(s, xml_unesc(d$footer), fixed = TRUE), NA))
  ok_t <- any(grepl(tr_json[[lg]]$rp_title_ema, all_txt, fixed = TRUE)) && any(grepl(tr_json[[lg]]$rp_validation_ema, all_txt, fixed = TRUE))
  put(paste("E-5", id, lg), ok_xml && !length(missing) && ok_dis && ok_t && identical(v1("R", id, lg, "ag_istegi"), "0"),
      sprintf("%d metin; eksik %d%s; beyan %s; başlık ve validasyon metni %s; %s ms", length(want), length(missing),
              if (length(missing)) paste0(" (", paste(head(missing, 3), collapse = " | "), ")") else "", if (ok_dis) "var" else "YOK",
              if (ok_t) "var" else "YOK", v1("R", id, lg, "ms")))
}
put("E-5 rapor sayısı", nrow(rp) == 3, sprintf("%d rapor (örnek TR ve EN; hesaplanamayan yol TR)", nrow(rp)))
f1 <- v1("R", "ema-ornek-ham", "en", "dosya"); f2 <- v1("R-7", "ema-ornek-ham", "en", "dosya")
if (!is.na(f1) && !is.na(f2)) {
  a <- doc_xml(f1)$xml; b <- doc_xml(f2)$xml
  strip <- function(x) gsub("[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC", "<zaman>", x)
  put("E-5 belirlenimcilik", identical(strip(a), strip(b)), "oluşturma zamanı dışında aynı")
} else put("E-5 belirlenimcilik", NA, "")
yi <- g("E-5", a = "yeni_istek")
put("E-5 dış istek", nrow(yi) > 0 && all(yi$deger == "0") && identical(v1("E-5", "son", "", "dis_istek"), "0"),
    sprintf("%d analiz; oturum sonunda dış istek %s", nrow(yi), v1("E-5", "son", "", "dis_istek")))
mt <- jsonlite::fromJSON(v1("E-6", "acilis", "", "motor"), simplifyVector = FALSE)
put("E-5 motor dosyası invitro_fast.R", any(vapply(mt, function(r) r[[1]] == "invitro_fast.R" && grepl("^✓ SHA-256", r[[2]]), NA)), "sabitli, SHA-256 doğrulandı")

# ---------------------------------------------------------------- E-6 method choice
e6 <- c(acilis_yontem = v1("E-6", "acilis", "", "yontem") == "fda", acilis_tek = v1("E-6", "acilis", "", "tek_gorunur") == "true",
        ema_tek_gizli = v1("E-6", "ema_secildi", "", "tek_gorunur") == "false", ema_not = v1("E-6", "ema_secildi", "", "not_gorunur") == "true",
        girdi_pasif = v1("E-6", "girdi_degisti", "", "rapor_etkin") == "false",
        fda_pasif = v1("E-6", "fda_secildi", "", "rapor_etkin") == "false", fda_gizli = v1("E-6", "fda_secildi", "", "sonuc_gizli") == "true",
        fda_tek = v1("E-6", "fda_secildi", "", "tek_gorunur") == "true", fda_ema_tablo_gizli = v1("E-6", "fda-ornek-ham", "", "ema_gizli") == "true",
        ema_geri_pasif = v1("E-6", "ema_geri", "", "rapor_etkin") == "false", ema_geri_gizli = v1("E-6", "ema_geri", "", "sonuc_gizli") == "true")
e6[is.na(e6)] <- FALSE
put("E-6 yöntem seçimi", all(e6), if (all(e6)) sprintf("%d koşul", length(e6)) else paste("sağlanmayan:", paste(names(e6)[!e6], collapse = ", ")))

# ---------------------------------------------------------------- E-9
put("E-9 çeviri anahtarları", identical(names(tr_json$tr), names(tr_json$en)) && all(nzchar(unlist(tr_json$en))) && all(nzchar(unlist(tr_json$tr))),
    sprintf("%d anahtar", length(tr_json$tr)))
en <- c(unlist(jsonlite::fromJSON(v1("E-9", "ema-ornek-ham", "en", "ekran"))), unlist(jsonlite::fromJSON(v1("E-9", "ema-ornek-ham", "en", "yollar"))))
put("E-9 İngilizce ekran", all(c(tr_json$en$an_ema_method, tr_json$en$an_ema_p_a, tr_json$en$an_ema_lo) %in% en) && !any(grepl("[ğış]", en)),
    sprintf("%d metin", length(en)))
put("E-9 dar ekran (390 px)", identical(v1("E-9", "dar", "pbe", "yatay_kaydirma"), "false"), "")

# ---------------------------------------------------------------- E-10
docs <- c(file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-08_v0.1.docx"), file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-07_v0.2.docx"),
          file.path("belgeler", "validasyon", "FSR-VAL-PLT-1_v1.3.docx"), file.path("web", "yardim", "yontem", "ema.html"), "FSR-LOG-01_v1_gunluk.md")
put("E-10 belgeler", all(file.exists(docs)), paste(basename(docs)[!file.exists(docs)], collapse = ", "))

put("ortam", NA, paste(v1("ortam", "", "", "tarayici"), "·", v1("ortam", "", "", "sure_s"), "sn"))
res <- res[res$olcut != "ortam", ]
utils::write.csv(res, file.path(E, "p8_kabul.csv"), row.names = FALSE, fileEncoding = "UTF-8")
writeLines(utils::capture.output(utils::sessionInfo()), file.path(E, "p8_yerel_sessionInfo.txt"), useBytes = TRUE)
cat(sprintf("\nToplam: %d ölçüt satırı; GECTI %d, KALDI %d, EKSIK %d. Ayrıntı: %s\n", nrow(res), sum(res$sonuc == "GECTI"),
            sum(res$sonuc == "KALDI"), sum(res$sonuc == "EKSIK"), file.path(E, "p8_kabul.csv")))
})
