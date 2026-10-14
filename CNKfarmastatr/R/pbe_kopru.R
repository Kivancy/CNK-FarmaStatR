# =============================================================================
# CNK-FarmaStatR — PBE modülü · Arayüz köprüsü
#   Arayüzden gelen sütunları validasyonlu çekirdeğin (pbe_core.R, calc_pbe) beklediği
#   biçime getirir, girdi kontrollerini yapar ve çekirdeği DEĞİŞTİRMEDEN çağırır.
#   FSR-VAL-PBE-1 açık maddeleri burada kapatılır:
#     B-2  Kap başına eksik ya da tekrarlı aşama ölçümü → hesap yapılmaz (hata)
#     B-4  Log dönüşümü kapalıyken geometrik ortalamalar sonuçtan çıkarılır
# Sürüm: 0.1.0
# =============================================================================

kp_calistir <- function(ifade) tryCatch(ifade, error = function(e) list(.hata = conditionMessage(e)))
.pbe <- new.env()

.ornekle <- function(x, n = 3) paste(utils::head(x, n), collapse = "; ")

# parti, kap, asama, urun: karakter; deger: sayısal; test/ref: ürün etiketleri; log_d: mantıksal
kp_hazirla <- function(parti, kap, asama, urun, deger, test, ref, log_d) {
  .pbe$df <- NULL
  n <- length(deger)
  if (!all(c(length(parti), length(kap), length(asama), length(urun)) == n)) stop("Sütun uzunlukları farklı.")
  if (identical(test, ref)) stop("TEST ve REF ürünü aynı olamaz.")
  s <- urun %in% c(test, ref)
  if (!any(urun == test)) stop(sprintf("TEST ürünü (%s) veride bulunamadı.", test))
  if (!any(urun == ref))  stop(sprintf("REF ürünü (%s) veride bulunamadı.", ref))
  df <- data.frame(Batches = trimws(as.character(parti[s])), Container = trimws(as.character(kap[s])),
                   Stage = trimws(as.character(asama[s])), Product = ifelse(urun[s] == test, "TEST", "REF"),
                   score = suppressWarnings(as.numeric(deger[s])), stringsAsFactors = FALSE)
  bos <- which(is.na(df$Batches) | df$Batches == "" | is.na(df$Container) | df$Container == "" | is.na(df$Stage) | df$Stage == "")
  if (length(bos)) stop(sprintf("Parti, kap ya da aşama sütununda %d boş hücre var.", length(bos)))
  kotu <- which(is.na(df$score) | !is.finite(df$score))
  if (length(kotu)) stop(sprintf("Ölçüm sütununda %d eksik ya da sayısal olmayan değer var.", length(kotu)))
  if (isTRUE(log_d) && any(df$score <= 0))
    stop(sprintf("Log dönüşümü için tüm ölçümler pozitif olmalı; %d değer sıfır ya da negatif.", sum(df$score <= 0)))

  sT <- sort(unique(df$Stage[df$Product == "TEST"])); sR <- sort(unique(df$Stage[df$Product == "REF"]))
  if (!identical(sT, sR))
    stop(sprintf("TEST ve REF aşamaları farklı (TEST: %s | REF: %s) [PSG_020929 Appendix].", paste(sT, collapse = ", "), paste(sR, collapse = ", ")))

  # B-2: her kapta (ürün + parti + kap) her aşama için tam bir ölçüm
  kap_id <- paste(df$Product, df$Batches, df$Container, sep = " / ")
  tab <- table(kap_id, df$Stage)
  tekrar <- which(tab > 1, arr.ind = TRUE); eksik <- which(tab == 0, arr.ind = TRUE)
  if (nrow(tekrar)) stop(sprintf("Aynı kap ve aşamada birden fazla ölçüm var (%d durum). Örnek (ürün / parti / kap, aşama): %s.",
    nrow(tekrar), .ornekle(paste0(rownames(tab)[tekrar[, 1]], ", ", colnames(tab)[tekrar[, 2]]))))
  if (nrow(eksik)) stop(sprintf("Bazı kaplarda aşama ölçümü eksik (%d durum). Örnek (ürün / parti / kap, aşama): %s. Her kap her aşamada tam bir kez ölçülmüş olmalıdır.",
    nrow(eksik), .ornekle(paste0(rownames(tab)[eksik[, 1]], ", ", colnames(tab)[eksik[, 2]]))))

  tasarim <- function(p) {
    a <- df[df$Product == p, ]; kp <- tapply(a$Container, a$Batches, function(x) length(unique(x)))
    list(parti = length(kp), kap_min = min(kp), kap_max = max(kp), toplam_kap = sum(kp), gozlem = nrow(a))
  }
  dT <- tasarim("TEST"); dR <- tasarim("REF")
  if (dT$toplam_kap < 2 || dR$toplam_kap < 2) stop("Her üründe en az 2 kap gereklidir.")
  uyarilar <- character(0)
  for (p in c("TEST", "REF")) { d <- if (p == "TEST") dT else dR
    if (d$kap_min != d$kap_max) uyarilar <- c(uyarilar, sprintf(
      "%s: parti başına kap sayısı dengesiz (%d–%d). Hesap toplam kap sayısıyla yapılır (FarmaStatR türetimi; dengeli tasarımda PSG ile özdeş).", p, d$kap_min, d$kap_max)) }
  if (dT$parti != dR$parti) uyarilar <- c(uyarilar, sprintf("Parti sayısı farklı: TEST %d, REF %d.", dT$parti, dR$parti))
  if (dT$parti < 3 || dR$parti < 3) uyarilar <- c(uyarilar, "PSG_020929 her ürün için en az üç parti önerir.")

  y <- if (isTRUE(log_d)) log(df$score) else df$score
  oz <- aggregate(y, by = list(urun = df$Product, asama = df$Stage), FUN = function(v) c(n = length(v), ort = mean(v), sd = stats::sd(v)))
  .pbe$df <- df; .pbe$log <- isTRUE(log_d)
  list(m = length(sT), asamalar = sT, satir = nrow(df), T = dT, R = dR, uyarilar = uyarilar,
       oz_urun = oz$urun, oz_asama = oz$asama, oz_n = unname(oz$x[, "n"]), oz_ort = unname(oz$x[, "ort"]), oz_sd = unname(oz$x[, "sd"]),
       olcek = if (isTRUE(log_d)) "ln(ölçüm)" else "ölçüm")
}

kp_pbe <- function(tek_yonlu) {
  if (is.null(.pbe$df)) stop("Önce veriyi hazırlayın.")
  r <- calc_pbe(.pbe$df, log_transform = .pbe$log, one_sided = isTRUE(tek_yonlu))
  if (!isTRUE(.pbe$log)) r[c("GM_T", "GM_R", "GMR")] <- NULL      # B-4
  r
}
