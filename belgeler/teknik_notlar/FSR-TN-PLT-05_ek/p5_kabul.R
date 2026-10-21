# =============================================================================
# CNK-FarmaStatR - P5 acceptance (FSR-TN-PLT-05 v0.2, Table 8.1; frozen by KK-57)
#
# Reads the browser output of web/app/kabul5.html (p5/p5_kabul.zip: p5_tarayici.csv,
# the Word reports, the design script), opens the reports with R's own unzip (an
# independent reader of what the browser wrote), recomputes in local R what the
# screen should show and writes one line per criterion: GECTI (pass), KALDI
# (fail) or EKSIK (data missing).
#   D-1 Tables 11.3a/b of FSR-TN-PBE-01 (asama1_tablo113.csv) reproduced
#   D-2 selection = an independent implementation of rules A and B (below)
#   D-3 precomputed table = database; live = precomputed (counts, common seed)
#   D-4 class and metric = platform_hipotez(); no selection outside H1
#   D-5 the design script downloaded from the screen gives the same counts and
#       the same selection; a changed byte stops it
#   D-6 near-target flags and warnings; D-7 limit and cancel
#   R-1 report content; R-2 numbers; R-3 labels; R-4 disclaimer; R-5 valid file
#   R-6 link; R-7 determinism; R-8 no network request; R-9 button state;
#   R-10 time; R-11 regression (screen texts of P4, pinned cores)
# Live values: decisions as counts (equal), other numbers with K(1e-12, 1e-12).
# Run from the repository root:
#   source("belgeler/teknik_notlar/FSR-TN-PLT-05_ek/p5_kabul.R", encoding = "UTF-8")
# Base R plus RSQLite. Research and education only; not a system validated for
# GxP environments.
# =============================================================================
local({
E <- file.path("belgeler", "teknik_notlar", "FSR-TN-PLT-05_ek")
zf <- file.path(E, "p5", "p5_kabul.zip")
if (!file.exists(zf)) stop("p5/p5_kabul.zip not found")
X <- file.path(tempdir(), "p5_kabul"); unlink(X, recursive = TRUE); dir.create(X)
zl <- utils::unzip(zf, list = TRUE); utils::unzip(zf, exdir = X)
br <- utils::read.csv(file.path(X, "p5_tarayici.csv"), colClasses = "character", encoding = "UTF-8", na.strings = character(0))
Rdir <- file.path("CNKfarmastatr", "R")
pk <- new.env(parent = globalenv())
for (f in c("sim_run.R", "invitro_fast.R", "invitro_grid.R", "platform_input.R", "platform_hipotez.R",
            "platform_export.R", "platform_tasarim.R"))
  sys.source(file.path(Rdir, f), envir = pk, keep.source = FALSE)
suppressPackageStartupMessages({ library(DBI); library(RSQLite) })
con <- dbConnect(SQLite(), file.path("veri", "farmastatr_v1.sqlite")); on.exit(dbDisconnect(con))
res <- data.frame(olcut = character(0), sonuc = character(0), ayrinti = character(0), stringsAsFactors = FALSE)
put <- function(o, ok, a) { s <- if (is.na(ok)) "EKSIK" else if (isTRUE(ok)) "GECTI" else "KALDI"
  res[nrow(res) + 1, ] <<- c(o, s, a); cat(sprintf("%-28s %-6s %s\n", o, s, a)) }
g <- function(b, s = NULL, y = NULL, a = NULL) { x <- br[br$bolum == b, ]
  if (!is.null(s)) x <- x[x$senaryo == s, ]; if (!is.null(y)) x <- x[x$yontem == y, ]; if (!is.null(a)) x <- x[x$ad == a, ]; x }
v1 <- function(b, s, y, a) { x <- g(b, s, y, a)$deger; if (length(x) == 1) x else NA_character_ }
tf <- function(x) length(x) > 0 && all(x == "true")
K <- function(a, b) abs(a - b) <= 1e-12 + 1e-12 * pmax(abs(a), abs(b))
num <- function(x) suppressWarnings(as.numeric(x))
ME <- c("fda", "ema_a", "ema_b", "ema_c")
z <- stats::qnorm(0.95)
if (nrow(br) == 0) stop("p5_tarayici.csv is empty")

# ---------------------------------------------------------------- reading a report (base R)
xml_unesc <- function(s) { s <- gsub("&lt;", "<", s, fixed = TRUE); s <- gsub("&gt;", ">", s, fixed = TRUE)
  s <- gsub("&quot;", "\"", s, fixed = TRUE); gsub("&amp;", "&", s, fixed = TRUE) }
paras <- function(xml) {
  p <- regmatches(xml, gregexpr("<w:p>.*?</w:p>", xml, perl = TRUE))[[1]]
  vapply(p, function(q) {
    tk <- regmatches(q, gregexpr("<w:t[^>]*>[^<]*</w:t>|<w:br/>", q, perl = TRUE))[[1]]
    xml_unesc(paste(ifelse(tk == "<w:br/>", "\n", sub("^<w:t[^>]*>", "", sub("</w:t>$", "", tk))), collapse = ""))
  }, "", USE.NAMES = FALSE)
}
rd <- function(f, part = "word/document.xml") {
  d <- file.path(tempdir(), "p5_docx"); unlink(d, recursive = TRUE); dir.create(d)
  ok <- tryCatch({ utils::unzip(file.path(X, f), exdir = d); TRUE }, error = function(e) FALSE, warning = function(w) FALSE)
  if (!ok || !file.exists(file.path(d, part))) return(NULL)
  x <- readChar(file.path(d, part), file.size(file.path(d, part)), useBytes = TRUE); Encoding(x) <- "UTF-8"
  x
}
json_strs <- function(s) {                 # JSON array of strings -> character (JSON escapes are R escapes)
  if (s == "[]") return(character(0))
  eval(parse(text = paste0("c(", substr(s, 2, nchar(s) - 1), ")"), encoding = "UTF-8", keep.source = FALSE))
}
# translation file (one "key": "value" per line)
tr_file <- readLines(file.path("web", "app", "ceviri.json"), encoding = "UTF-8", warn = FALSE)
i_en <- grep('^  "en": \\{', tr_file)
tr_get <- function(lang, key) {
  rng <- if (lang == "tr") seq_len(i_en - 1) else seq(i_en, length(tr_file))
  l <- grep(paste0('^    "', key, '": '), tr_file[rng], value = TRUE)
  if (length(l) != 1) return(NA_character_)
  json_strs(paste0("[", sub(",$", "", sub(paste0('^    "', key, '": '), "", l)), "]"))
}

# ---------------------------------------------------------------- R-1 ... R-5: every report
reps <- g("R"); ids <- unique(paste(reps$senaryo, reps$yontem))
r1 <- r2 <- r4 <- r5 <- r8 <- r9b <- logical(0); det <- character(0); nmiss <- 0
for (k in ids) {
  s <- sub(" .*$", "", k); lang <- sub("^.* ", "", k); x <- reps[reps$senaryo == s & reps$yontem == lang, ]
  f <- x$deger[x$ad == "dosya"]; kind <- x$deger[x$ad == "tur"]
  doc <- rd(f); hdr <- rd(f, "word/header1.xml"); ftr <- rd(f, "word/footer1.xml")
  if (is.null(doc) || is.null(ftr) || is.null(hdr)) { r5 <- c(r5, FALSE); det <- c(det, paste("açılamadı:", f)); next }
  # R-5: parts present, tags balanced
  bal <- function(a, b) lengths(regmatches(doc, gregexpr(a, doc, fixed = TRUE))) == lengths(regmatches(doc, gregexpr(b, doc, fixed = TRUE)))
  r5 <- c(r5, bal("<w:p>", "</w:p>") && bal("<w:tbl>", "</w:tbl>") && bal("<w:tr>", "</w:tr>") && bal("<w:tc>", "</w:tc>"))
  P <- paras(doc)
  # R-1: title, nine numbered sections, created line, link
  kk <- if (kind == "tas") "tasarim" else "tek"
  heads <- c("rp_s_identity", "rp_s_versions", "rp_s_params", "rp_s_source", "rp_s_result", "rp_s_warnings",
             "rp_s_sources", "rp_s_validation", "rp_s_link")
  want <- c(tr_get(lang, paste0("rp_title_", kk)), paste0(seq_along(heads), ". ", vapply(heads, function(h) tr_get(lang, h), "")))
  ok1 <- all(want %in% P) && any(startsWith(P, paste0(tr_get(lang, "rp_created"), ": "))) &&
    any(grepl("index.html?", P, fixed = TRUE)) && all(vapply(c("rp_src_fda", "rp_src_ema", "rp_src_sim"), function(h) tr_get(lang, h) %in% P, TRUE))
  r1 <- c(r1, ok1); if (!ok1) det <- c(det, paste("R-1:", f))
  # R-2, R-3: every string the screen showed is a paragraph (or cell) of the report
  scr <- json_strs(x$deger[x$ad == "ekran"])
  miss <- setdiff(scr, P); nmiss <- nmiss + length(miss)
  r2 <- c(r2, length(scr) > 0 && length(miss) == 0); if (length(miss)) det <- c(det, paste0("R-2/R-3 ", f, ": ", paste(utils::head(miss, 3), collapse = " | ")))
  # R-4: disclaimer on the first page (both languages) and in every page's footer
  dtr <- tr_get("tr", "disclaimer"); den <- tr_get("en", "disclaimer")
  fp <- paras(ftr)
  r4 <- c(r4, isTRUE(P[2] == dtr && P[3] == den) && any(grepl(dtr, fp, fixed = TRUE) & grepl(den, fp, fixed = TRUE)))
  r8 <- c(r8, x$deger[x$ad == "ag_istegi"] == "0")
  r9b <- c(r9b, x$deger[x$ad == "dugme_etkin"] == "true")
}
n_rep <- length(ids)
put("R-1 Rapor içeriği", length(r1) == n_rep && all(r1), sprintf("%d/%d rapor: başlık, 9 bölüm, oluşturma zamanı, kaynaklar, bağlantı", sum(r1), n_rep))
put("R-2 Sayılar", length(r2) == n_rep && all(r2), sprintf("rapor metni = ekran metni: %d/%d rapor (eksik dize %d)", sum(r2), n_rep, nmiss))
put("R-4 Beyan", length(r4) == n_rep && all(r4), sprintf("ilk sayfada iki dil ve her sayfanın alt bilgisinde: %d/%d", sum(r4), n_rep))
put("R-5 Geçerli belge", length(r5) == n_rep && all(r5), sprintf("R unzip ve XML okuma: %d/%d (Word'de açılış: proje sahibi)", sum(r5), n_rep))
put("R-8 Gizlilik", length(r8) == n_rep && all(r8), sprintf("rapor üretilirken ağ isteği 0: %d/%d", sum(r8), n_rep))

# ---------------------------------------------------------------- single scenario values (R-2, R-3, R-11)
tek <- g("tek"); tids <- unique(tek$senaryo)
okv <- logical(0); okt <- logical(0)
for (id in tids) {
  src <- v1("tek", id, "", "source"); key <- v1("tek", id, "", "key")
  kv <- strsplit(strsplit(key, "|", fixed = TRUE)[[1]], "=", fixed = TRUE)
  kp <- stats::setNames(vapply(kv, `[`, "", 2), vapply(kv, `[`, "", 1))
  okt <- c(okt, tf(g("tek", id, "", "txt_ok")$deger))
  if (src == "canli") {
    p <- list(sigma_R = num(kp[["sigma_R"]]), rho = num(kp[["rho"]]), pB_T = num(kp[["pB_T"]]), pB_R = num(kp[["pB_R"]]),
              pL = num(kp[["pL"]]), q = num(kp[["q"]]), l = num(kp[["l"]]), n = num(kp[["n"]]), m = num(kp[["m"]]),
              n_sim = num(kp[["n_sim"]]), seed = num(kp[["seed"]]))
    d <- if (grepl("^[a-z]", kp[["delta"]])) pk$platform_sinir_delta(kp[["delta"]], p$sigma_R, p$rho) else num(kp[["delta"]])
    r <- pk$platform_run_invitro(c(p, list(delta = d)))
    h <- if (grepl("^[a-z]", kp[["delta"]])) pk$platform_hipotez(p$sigma_R, p$rho, sinir = kp[["delta"]]) else pk$platform_hipotez(p$sigma_R, p$rho, delta = d)
    for (me in ME) {
      rate <- num(v1("tek", id, me, "rate")); se <- num(v1("tek", id, me, "mcse"))
      okv <- c(okv, round(rate * p$n_sim) == round(r[[paste0(me, "_pass")]] * p$n_sim) && K(se, r[[paste0(me, "_pass_mcse")]]) &&
               v1("tek", id, me, "sinif") == h$sinif[h$yontem == me])
    }
  } else {
    no <- num(v1("tek", id, "", "senaryo_no")); ks <- v1("tek", id, "", "kosu_shown")
    db <- dbGetQuery(con, "SELECT yontem_id, tahmin, mcse FROM sonuc WHERE senaryo_no = ? AND kosu_id = ? AND olcut_id = 'pass'", params = list(no, ks))
    hp <- dbGetQuery(con, "SELECT yontem_id, sinif FROM hipotez WHERE senaryo_no = ?", params = list(no))
    for (me in ME) okv <- c(okv, num(v1("tek", id, me, "rate")) == db$tahmin[db$yontem_id == me] &&
                              identical(num(v1("tek", id, me, "mcse")), db$mcse[db$yontem_id == me]) &&
                              v1("tek", id, me, "sinif") == hp$sinif[hp$yontem_id == me])
  }
}
put("R-2 Değerler (tek senaryo)", length(okv) > 0 && all(okv), sprintf("ekrandaki değer = yerel R (canlı, sayım ve K) ya da veri tabanı (hazır): %d/%d yöntem satırı; %d senaryo", sum(okv), length(okv), length(tids)))
put("R-3 Etiketler", length(okt) > 0 && all(okt) && tf(g("R-3", a = "ceviri_anahtar_esit")$deger),
    sprintf("ekran metni = çeviri ve kural(değer) (%d senaryo, TR); çeviri anahtarları TR = EN (%s)", sum(okt), v1("R-3", "", "", "ceviri_n")))

# ---------------------------------------------------------------- design results
rules <- function(tb, hedef, l_min = 3, n_min = 10) {        # independent rules A and B (D-2)
  out <- list()
  for (me in ME) {
    t <- tb[tb$yontem == me, ]; t <- t[order(t$l * t$n * t$m, t$l, t$m), ]
    h1 <- t$sinif[1] == "H1"
    ok <- h1 & t$guc >= hedef
    a <- which(ok)[1]
    okb <- ok & t$l >= l_min & t$n >= n_min & !is.na(t$etiket) & t$etiket != "nominali_asiyor"
    b <- which(okb)[1]
    na <- if (!h1) "sinif_h1_degil" else if (is.na(a)) "guc_yetersiz" else NA
    nb <- if (!h1) "sinif_h1_degil" else if (!is.na(b)) NA else if (!any(ok & t$l >= l_min & t$n >= n_min)) "guc_yetersiz" else
      if (all(is.na(t$etiket[ok & t$l >= l_min & t$n >= n_min]))) "tip1_hesaplanamadi" else "tip1_kalibrasyon"
    near <- function(i) abs(t$guc[i] - hedef) < 2 * t$mcse[i]
    out[[paste0(me, "_A")]] <- if (is.na(a)) paste0("yok|", na) else paste(t$l[a], t$n[a], t$m[a], tolower(near(a)), sep = "|")
    out[[paste0(me, "_B")]] <- if (is.na(b)) paste0("yok|", nb) else paste(t$l[b], t$n[b], t$m[b], tolower(near(b)), sep = "|")
  }
  out
}
tab_of <- function(set, id) {
  x <- g(set, id); x <- x[startsWith(x$ad, "tablo_"), ]
  p <- strsplit(sub("^tablo_", "", x$ad), "_"); v <- strsplit(x$deger, "|", fixed = TRUE)
  data.frame(yontem = x$yontem, l = num(vapply(p, `[`, "", 1)), n = num(vapply(p, `[`, "", 2)), m = num(vapply(p, `[`, "", 3)),
             guc = num(vapply(v, `[`, "", 1)), mcse = num(vapply(v, `[`, "", 2)), t1 = num(vapply(v, `[`, "", 3)),
             t1m = num(vapply(v, `[`, "", 4)), etiket = ifelse(vapply(v, `[`, "", 5) == "NA", NA, vapply(v, `[`, "", 5)),
             sinif = vapply(v, `[`, "", 6), hedef_ok = vapply(v, `[`, "", 7) == "true", yakin = vapply(v, `[`, "", 8) == "true",
             stringsAsFactors = FALSE)
}
sel_of <- function(set, id) { x <- g(set, id); x <- x[startsWith(x$ad, "secim_"), ]; stats::setNames(x$deger, paste0(x$yontem, "_", sub("secim_", "", x$ad))) }
inp_of <- function(set, id) {
  pop <- lapply(c("sigma_R", "rho", "pB_T", "pB_R", "pL", "q"), function(k) num(v1(set, id, "", paste0("pop_", k))))
  names(pop) <- c("sigma_R", "rho", "pB_T", "pB_R", "pL", "q")
  gc <- v1(set, id, "", "guc"); cu <- num(v1(set, id, "", "custom"))
  list(pop = pop, l = num(strsplit(v1(set, id, "", "ls"), " ")[[1]]), n = num(strsplit(v1(set, id, "", "ns"), " ")[[1]]),
       m = num(strsplit(v1(set, id, "", "ms"), " ")[[1]]),
       guc = if (gc == "gmr") list(gmr = cu) else if (gc == "delta") list(delta = cu) else list(sinir = gc),
       hedef = num(v1(set, id, "", "hedef")), n_sim = num(v1(set, id, "", "n_sim")), seed = num(v1(set, id, "", "seed")))
}
dids <- unique(g("D")$senaryo); dids <- dids[!is.na(vapply(dids, function(i) v1("D", i, "", "source"), ""))]

# D-1: Tables 11.3a and 11.3b
ref <- utils::read.csv(file.path("simulasyon", "FSR-TN-PBE-01", "asama1_tablo113.csv"), stringsAsFactors = FALSE)
mm <- c(FDA = "fda", EMA_a = "ema_a", EMA_b = "ema_b", EMA_c = "ema_c"); lab <- c(exceeds = "nominali_asiyor", controlled = "kontrol_kanitli", inconclusive = "ayirt_edilemiyor")
d1 <- logical(0)
for (pb in c(0, 0.1, 0.3)) {
  id <- paste0("T-A1-pB", pb); tb <- tab_of("D", id); sl <- sel_of("D", id)
  for (me in names(mm)) for (k in c("A", "B")) {
    r <- ref[ref$table == (if (k == "A") "11.3a" else "11.3b") & ref$method == me & ref$pB == pb, ]
    s <- strsplit(sl[[paste0(mm[[me]], "_", k)]], "|", fixed = TRUE)[[1]]
    if (is.na(r$l)) { d1 <- c(d1, s[1] == "yok"); next }
    row <- tb[tb$yontem == mm[[me]] & tb$l == as.numeric(s[1]) & tb$n == as.numeric(s[2]), ]
    d1 <- c(d1, length(s) == 4 && as.numeric(s[1]) == r$l && as.numeric(s[2]) == r$n && nrow(row) == 1 &&
              row$guc == r$power && row$mcse == r$power_mcse && row$t1 == r$t1 && row$t1m == r$t1_mcse && row$etiket == lab[[r$t1_class]])
  }
}
put("D-1 Yayımlanmış tablo", length(d1) == 24 && all(d1), sprintf("Tablo 11.3a ve 11.3b, üç p_B, dört yöntem: %d/24 hücre (tasarım, güç, MCSE, tip I hata, etiket, \"yok\")", sum(d1)))

# D-2: independent rules on every design result shown
d2 <- logical(0)
for (set in c("D", "D-canli")) for (id in unique(g(set)$senaryo)) {
  tb <- tab_of(set, id); if (!nrow(tb)) next
  mine <- rules(transform(tb, mcse = mcse), num(v1(set, id, "", "hedef"))); sl <- sel_of(set, id)
  d2 <- c(d2, all(vapply(names(mine), function(k) identical(mine[[k]], sl[[k]]), TRUE)))
}
put("D-2 Bağımsız kural", length(d2) > 0 && all(d2), sprintf("ekrandaki seçim = bağımsız uygulama: %d/%d tasarım sonucu (8 yöntem × kural)", sum(d2), length(d2)))

# D-3: precomputed = database; live = precomputed
d3 <- logical(0)
for (id in dids[vapply(dids, function(i) v1("D", i, "", "source") == "hazir", TRUE)]) {
  tb <- tab_of("D", id); inp <- inp_of("D", id); pl <- pk$platform_tasarim_plan(inp$pop, inp$l, inp$n, inp$m, inp$guc, inp$n_sim, inp$seed, toplam_max = NULL)
  ks <- sub("\\|n_sim=.*$", "", pl$plan$anahtar)
  for (j in seq_len(nrow(pl$plan))) {
    no <- dbGetQuery(con, "SELECT senaryo_no FROM senaryo WHERE senaryo_anahtar = ?", params = list(ks[j]))$senaryo_no
    db <- dbGetQuery(con, "SELECT s.yontem_id, s.tahmin, s.mcse FROM sonuc s JOIN kosu k USING (kosu_id) WHERE s.senaryo_no = ? AND k.tur = 'tek' AND s.olcut_id = 'pass'", params = list(no))
    rl <- pl$rol[pl$rol$kosu_no == j, ]
    for (q in seq_len(nrow(rl))) for (me in ME) {
      if (rl$rol[q] == "t1_fda" && me != "fda" || rl$rol[q] == "t1_ema" && me == "fda") next
      row <- tb[tb$yontem == me & tb$l == rl$l[q] & tb$n == rl$n[q] & tb$m == rl$m[q], ]
      v <- if (rl$rol[q] == "guc") c(row$guc, row$mcse) else c(row$t1, row$t1m)
      d3 <- c(d3, identical(v, c(db$tahmin[db$yontem_id == me], db$mcse[db$yontem_id == me])))
    }
  }
}
tl <- tab_of("D-canli", "T-dar"); th <- tab_of("D", "T-dar")
same <- nrow(tl) > 0 && nrow(tl) == nrow(th) && all(round(tl$guc * 10000) == round(th$guc * 10000)) && all(round(tl$t1 * 10000) == round(th$t1 * 10000)) &&
  all(K(tl$mcse, th$mcse)) && all(K(tl$t1m, th$t1m)) && identical(tl$etiket, th$etiket)
put("D-3 Canlı = hazır", length(d3) > 0 && all(d3) && same && v1("D-3", "T-dar", "", "canli_durum") == "ts_st_done",
    sprintf("hazır hücreler = veri tabanı ana koşusu: %d/%d; daraltılmış kümede canlı = hazır (sayım; MCSE K içinde): %s", sum(d3), length(d3), same))

# D-4: class and metric from R; no selection outside H1
d4 <- logical(0)
for (id in dids) {
  inp <- inp_of("D", id); gd <- num(v1("D", id, "", "gdelta"))
  h <- pk$platform_hipotez(inp$pop$sigma_R, inp$pop$rho, delta = gd)
  shown <- stats::setNames(sub("^.*:", "", strsplit(v1("D", id, "", "sinif"), ";")[[1]]), sub(":.*$", "", strsplit(v1("D", id, "", "sinif"), ";")[[1]]))
  tb <- tab_of("D", id); sl <- sel_of("D", id)
  for (me in ME) d4 <- c(d4, shown[[me]] == h$sinif[h$yontem == me] && all(tb$sinif[tb$yontem == me] == h$sinif[h$yontem == me]) &&
                          (h$sinif[h$yontem == me] == "H1" || (!any(tb$hedef_ok[tb$yontem == me]) && all(sl[paste0(me, c("_A", "_B"))] == "yok|sinif_h1_degil"))))
}
nh <- sum(vapply(dids, function(i) sum(!grepl(":H1$", strsplit(v1("D", i, "", "sinif"), ";")[[1]])), 0))
put("D-4 Sınıf ve etiket", length(d4) > 0 && all(d4) && nh > 0, sprintf("sınıf = platform_hipotez(): %d/%d yöntem; H1 olmayan %d yöntemde seçim yok ve neden yazılı", sum(d4), length(d4), nh))

# D-5: the design script from the screen
bf <- file.path(X, "p5_tasarim_betik.R"); d5 <- NA; d5a <- "betik yok"
if (file.exists(bf)) {
  txt <- readChar(bf, file.size(bf), useBytes = TRUE); Encoding(txt) <- "UTF-8"
  run_txt <- function(tx) { env <- new.env(parent = globalenv())
    env$.err <- tryCatch({ invisible(utils::capture.output(eval(parse(text = sub("output_dir <- \".\"", "output_dir <- NULL", tx, fixed = TRUE), keep.source = FALSE, encoding = "UTF-8"), envir = env))); NULL },
                         error = function(e) conditionMessage(e)); env }
  e1 <- run_txt(txt)
  tb <- tab_of("D", "T-yeni"); sl <- sel_of("D", "T-yeni")
  ok <- is.null(e1$.err)
  if (ok) {
    st <- e1$run$tablo; ss <- e1$run$secim
    for (i in seq_len(nrow(st))) {
      row <- tb[tb$yontem == st$yontem[i] & tb$l == st$l[i] & tb$n == st$n[i] & tb$m == st$m[i], ]
      ok <- ok && nrow(row) == 1 && round(row$guc * 2000) == round(st$guc[i] * 2000) && round(row$t1 * 2000) == round(st$t1[i] * 2000) &&
        K(row$mcse, st$guc_mcse[i]) && identical(row$etiket, st$t1_etiket[i])
    }
    mine <- stats::setNames(ifelse(ss$var, paste(ss$l, ss$n, ss$m, tolower(ss$esik_yakin), sep = "|"), paste0("yok|", ss$neden)), paste0(ss$yontem, "_", ss$kural))
    ok <- ok && all(vapply(names(mine), function(k) identical(mine[[k]], sl[[k]]), TRUE))
  }
  k <- regexpr("theta_p <- ((log(1.11))^2 + 0.01) / sigma_T0^2", txt, fixed = TRUE); bad <- txt
  substr(bad, k + 30, k + 30) <- "2"
  e2 <- run_txt(bad)
  stop_ok <- !is.null(e2$.err) && grepl("SHA-256 mismatch", e2$.err) && is.null(e2$run)
  d5 <- ok && stop_ok
  d5a <- sprintf("betik (yerel R) = ekran: %s (%d hücre, seçim 8/8); bir bayt değişince durdu: %s", ok, nrow(tb), stop_ok)
}
put("D-5 Tasarım betiği", d5, d5a)

# D-6: near-target flags, marks and warnings
d6 <- logical(0)
for (set in c("D", "D-canli")) for (id in unique(g(set)$senaryo)) {
  tb <- tab_of(set, id); if (!nrow(tb)) next
  h <- num(v1(set, id, "", "hedef"))
  d6 <- c(d6, all(tb$yakin == (tb$sinif == "H1" & abs(tb$guc - h) < 2 * tb$mcse)), all(tb$hedef_ok == (tb$sinif == "H1" & tb$guc >= h)),
          tf(v1(set, id, "", "isaret_ok")), grepl("ts_w_cand", v1(set, id, "", "uyarilar")))
}
w0 <- v1("D", "T-delta0", "", "uyarilar"); s0 <- sel_of("D", "T-delta0")
# delta0 undefined means eta > 0 for every delta: FDA is never in H1, so no FDA selection (sinif_h1_degil)
d6 <- c(d6, grepl("ts_w_delta0", w0), v1("D", "T-delta0", "", "notlar") == "fda_delta0_undefined",
        s0[["fda_A"]] == "yok|sinif_h1_degil", s0[["fda_B"]] == "yok|sinif_h1_degil")
near_any <- any(grepl("\\|true$", unlist(lapply(c("T-A1-pB0.1", "T-A1-pB0.3"), function(i) sel_of("D", i)))))
d6 <- c(d6, near_any == (grepl("ts_w_near", v1("D", "T-A1-pB0.1", "", "uyarilar")) || grepl("ts_w_near", v1("D", "T-A1-pB0.3", "", "uyarilar"))))
put("D-6 Eşik ve uyarılar", all(d6), sprintf("eşiğe yakınlık = |güç − hedef| < 2 MCSE, hedef işareti ve hücre işaretleri, aday küme uyarısı, δ₀ tanımsız (uyarı, FDA seçimsiz): %d/%d", sum(d6), length(d6)))

# D-7: limit and cancel
d7 <- c(v1("D-7", "sinir", "", "durum") == "ts_st_betik", tf(v1("D-7", "sinir", "", "kosu_yok")), tf(v1("D-7", "sinir", "", "betik_metni")),
        num(v1("D-7", "iptal", "", "durma_ms")) <= 2000, tf(v1("D-7", "iptal", "", "kismi_gorunur")), tf(v1("D-7", "iptal", "", "secim_yok")))
put("D-7 Sınır, süre, iptal", all(d7), sprintf("sınır üstü: betik önerisi, koşu yok; iptal %s ms, kısmi tablo \"%s\", seçim yok", v1("D-7", "iptal", "", "durma_ms"), v1("D-7", "iptal", "", "kismi")))

# ---------------------------------------------------------------- R-6, R-7, R-9, R-10, R-11
r6 <- g("R-6"); put("R-6 Yeniden üretim", nrow(r6) == 3 && tf(r6$deger), sprintf("rapordaki bağlantı: tek senaryo aynı anahtar ve sonuç, tasarım aynı tablo (%d/3)", sum(r6$deger == "true")))
r7 <- NA; r7a <- "eksik"
f7 <- v1("R-7", "tek-hazir-1", "en", "dosya")
if (!is.na(f7)) {
  a <- rd("raporlar/tek-hazir-1_en.docx"); b <- rd(f7)
  pa <- paras(a); pb <- paras(b)
  d <- which(pa != pb)
  la <- utils::unzip(file.path(X, "raporlar/tek-hazir-1_en.docx"), list = TRUE); lb <- utils::unzip(file.path(X, f7), list = TRUE)
  r7 <- length(pa) == length(pb) && length(d) == 1 && startsWith(pa[d], tr_get("en", "rp_created")) && identical(la$Name, lb$Name)
  r7a <- sprintf("aynı sonuçtan iki rapor: %d paragraf, fark %d (oluşturma zamanı)", length(pa), length(d))
}
put("R-7 Belirlenimcilik", r7, r7a)
r9 <- g("R-9"); r9ok <- tf(r9$deger) && all(r9b)
put("R-9 Düğme durumu", r9ok, sprintf("%d/%d durum doğru (koşu sürerken, girdi değişince, iptal sonrası pasif; sonuç varken etkin); rapor anında etkin: %d/%d", sum(r9$deger == "true"), nrow(r9), sum(r9b), length(r9b)))
mx <- num(v1("R-10", "", "", "en_uzun_ms"))
put("R-10 Süre", !is.na(mx) && mx <= 2000, sprintf("%s rapor; en uzun %s ms (≤ 2000)", v1("R-10", "", "", "rapor_n"), v1("R-10", "", "", "en_uzun_ms")))
ck <- new.env(); sys.source(file.path("araclar", "cekirdek_kontrol.R"), envir = ck)
put("R-11 Gerileme", all(okt) && all(ck$liste$durum == "AYNI"),
    sprintf("P4 ekran metinleri = çeviri ve kural(değer) (%d senaryo); çekirdek SHA-256 %d/%d AYNI; test kümesi ve CI ayrıca (GitHub Actions)", length(okt), sum(ck$liste$durum == "AYNI"), nrow(ck$liste)))

genel <- if (all(res$sonuc == "GECTI")) "GECTI" else "KALDI"
utils::write.csv(res, file.path(E, "p5_kabul.csv"), row.names = FALSE, fileEncoding = "UTF-8")
writeLines(c(utils::capture.output(utils::sessionInfo()), "", paste("tarayıcı:", v1("ortam", "", "", "user_agent")),
             paste("tarayıcı süresi (s):", v1("ortam", "", "", "sure_s"))),
           file.path(E, "p5_yerel_sessionInfo.txt"))
if (length(det)) cat("\nAyrıntı:\n", paste0("  ", utils::head(det, 20), "\n"), sep = "")
cat("\nGenel:", genel, "| yazıldı:", file.path(E, "p5_kabul.csv"), "\n")
})
