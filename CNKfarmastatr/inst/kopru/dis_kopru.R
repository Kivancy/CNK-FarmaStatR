# ==============================================================================
# FarmaStatR — Dissolüsyon · webR köprüsü (arayüz ↔ validasyonlu modüller)
#   Bu dosya HESAP YAPMAZ. Veriyi matrislere çevirir, validasyonlu fonksiyonları
#   (calc_f2_boot, calc_msd, calc_msd_weibull) çağırır ve sonuçları arayüzün
#   okuyacağı düz listelere dönüştürür.
#   Validasyonlu dosyalar: msd_core.R, msd_weibull.R, f2_boot.R (değiştirilmeden).
# Sürüm: 0.2.1 — karşılaştırılan referans ürünü, referans partilerinden biri olarak seçilebilir
# ==============================================================================

.kp <- new.env()

# "lot" → "parti" terim birliği (modül mesajları)
kp_parti <- function(x) {
  if (is.null(x) || !length(x)) return(character(0))
  kural <- c("lotları" = "partileri", "Lotları" = "Partileri", "lotlar" = "partiler",
             "Lotlar" = "Partiler", "lotu" = "partisi", "Lotu" = "Partisi", "lot" = "parti")
  for (k in names(kural)) x <- gsub(k, kural[[k]], x, fixed = TRUE)
  unname(as.character(x))
}

kp_urun_matrisi <- function(df, urun) {
  alt <- df[df$Product == urun, , drop = FALSE]
  zamanlar <- sort(unique(alt$Time))
  uniteler <- unique(alt$Unit)
  M <- matrix(NA_real_, length(uniteler), length(zamanlar),
              dimnames = list(uniteler, as.character(zamanlar)))
  M[cbind(match(alt$Unit, uniteler), match(alt$Time, zamanlar))] <- alt$Diss
  M
}

# Veri hazırlama: JS'den gelen vektörler (Product, Unit, Time, Diss)
kp_hazirla <- function(Product, Unit, Time, Diss, test, ref, lotlar, birim) {
  df <- data.frame(Product = as.character(Product), Unit = as.character(Unit),
                   Time = as.numeric(Time), Diss = as.numeric(Diss), stringsAsFactors = FALSE)
  if (anyNA(df$Time)) stop("Zaman sütununda sayısal olmayan değer var.")
  if (test == ref) stop("Test ve referans ürün farklı seçilmelidir.")
  XT <- kp_urun_matrisi(df, test); XR <- kp_urun_matrisi(df, ref)
  if (!identical(colnames(XT), colnames(XR)))
    stop("Test ve referansın zaman noktaları aynı olmalıdır [EMA10 App. I madde 2].")
  # Referans partileri: karşılaştırılan referans ürünü de seçilebilir (referans–referans
  # değişkenliğine katkı verir). Test ürünü referans partisi olamaz.
  lotlar <- setdiff(as.character(lotlar), test)
  L <- lapply(lotlar, function(l) kp_urun_matrisi(df, l)); names(L) <- lotlar
  for (l in lotlar) if (!identical(colnames(L[[l]]), colnames(XR)))
    stop(sprintf("Referans partisi '%s' farklı zaman noktalarına sahip.", l))
  zaman <- as.numeric(colnames(XT))
  .kp$d <- list(test = XT, ref = XR, lotlar = if (length(L)) L else NULL, zaman = zaman,
                zaman_dk = if (birim == "saat") zaman * 60 else zaman, birim = birim,
                test_ad = test, ref_ad = ref)
  cv <- function(M) 100 * apply(M, 2, stats::sd, na.rm = TRUE) / colMeans(M, na.rm = TRUE)
  list(zaman = zaman, nT = nrow(XT), nR = nrow(XR), n_lot = length(L), lotlar = lotlar,
       ortT = unname(colMeans(XT, na.rm = TRUE)), ortR = unname(colMeans(XR, na.rm = TRUE)),
       sdT = unname(apply(XT, 2, stats::sd, na.rm = TRUE)), sdR = unname(apply(XR, 2, stats::sd, na.rm = TRUE)),
       cvT = unname(cv(XT)), cvR = unname(cv(XR)),
       tekT = lapply(seq_len(nrow(XT)), function(i) unname(XT[i, ])),
       tekR = lapply(seq_len(nrow(XR)), function(i) unname(XR[i, ])))
}

kp_f2 <- function(perspektif, tahminci, kesme, kmod, cvkural, gatipi, B, seed, qtip) {
  d <- .kp$d
  s <- calc_f2_boot(d$test, d$ref, d$zaman_dk, perspektif = perspektif, tahminci = tahminci,
                    truncation = kesme, cv_rule = cvkural, B = as.integer(B), ga_tipi = gatipi,
                    kesme_modu = kmod, seed = as.numeric(seed), q_type = as.integer(qtip))
  .kp$f2 <- s
  v <- s$replikalar[, s$tahminci]; v <- v[is.finite(v)]
  k <- s$kontrol
  list(karar = s$karar, alt = unname(s$karar_ga["alt"]), ust = unname(s$karar_ga["ust"]),
       mcse = unname(s$mc["MCSE"]), ortalama = s$boot_ortalama, tamsayi = s$ema_tamsayi,
       seed_duyarli = s$seed_duyarli, f2 = unname(s$nokta["f2"]), Ef2 = unname(s$nokta["Ef2"]),
       bcf2 = unname(s$nokta["bcf2"]), tahminci = s$tahminci, perspektif = s$perspektif,
       ga_tipi = s$ga_tipi, kesme = k$truncation, kmod = s$kesme_modu, cvkural = k$cv_rule,
       oneri = k$oneri, zamanlar = k$zamanlar, P = k$P, B = s$B, seed = s$seed, rng = s$rng,
       qtip = s$q_type, P_ad = names(s$P_dagilim), P_sayi = as.integer(s$P_dagilim),
       bca = if (is.null(s$bca)) NULL else c(z0 = s$bca$z0, a = s$bca$a,
                                               a1 = s$bca$alpha12[1], a2 = s$bca$alpha12[2]),
       cv_zaman = k$cv$zaman, cv_T = k$cv$CV_T, cv_R = k$cv$CV_R, cv_sinir = k$cv$sinir,
       cv_ihlal = k$cv$ihlal, notlar = kp_parti(c(k$notlar, s$uyarilar)),
       regulatif = unname(s$regulatif[[s$perspektif]]), boot = v)
}

kp_msd <- function(sinir, Dg, kesme) {
  d <- .kp$d
  m <- calc_msd(d$test, d$ref, limit = sinir, Dg = as.numeric(Dg), ref_lots = d$lotlar,
                truncation = kesme)
  .kp$msd <- m
  l <- m$L3
  list(benzer_msd = m$benzer_msd, benzer_L3 = m$benzer_L3, Dg = m$Dg_L3, DM = m$DM, T2 = m$T2,
       DM_l = m$DM_l, DM_u = m$DM_u, RD = m$RD, aciklama = kp_parti(m$sinir_aciklama),
       zamanlar = m$girdi$zamanlar,
       lot1 = if (is.null(m$lot_bilgi)) character(0) else as.character(m$lot_bilgi$lot1),
       lot2 = if (is.null(m$lot_bilgi)) character(0) else as.character(m$lot_bilgi$lot2),
       lot_fark = if (is.null(m$lot_bilgi)) numeric(0) else m$lot_bilgi$max_ort_fark,
       lot_dm = if (is.null(m$lot_bilgi)) numeric(0) else m$lot_bilgi$DM_RR,
       l_zaman = l$zaman, l_fark = l$fark, l_alt = l$es_alt,
       l_ust = l$es_ust, l_uc = l$uc_nokta, l_asim = l$nokta_asim,
       notlar = kp_parti(m$uyarilar), regulatif = kp_parti(unname(m$regulatif)))
}

kp_wb <- function(param, bolge, Dg, k, bolen) {
  d <- .kp$d
  w <- calc_msd_weibull(d$test, d$ref, d$zaman, ref_lots = d$lotlar, param = param,
                        region = bolge, k_sd = as.numeric(k), sr_bolen = bolen, Dg = as.numeric(Dg))
  .kp$wb <- w
  m <- w$motor
  t <- d$zaman; tt <- seq(min(t[t > 0]) / 2, max(t) * 1.05, length.out = 120)
  eg <- function(th) 100 * (1 - exp(-exp(z_weibull(th, tt, w$param))))
  bt <- w$bolge_tablo
  u <- rbind(cbind(Urun = "Test", w$uydurma$test), cbind(Urun = "Referans", w$uydurma$ref))
  list(benzer = w$benzer, aciklama = kp_parti(w$aciklama), param = w$param,
       p_ad = names(m$d), fark = unname(m$d), DM = m$DM, DM_l = m$DM_l, DM_u = m$DM_u,
       R2T = min(w$uydurma$test$R2), R2R = min(w$uydurma$ref$R2),
       tt = tt, egR = eg(m$ort_R), egT = eg(m$ort_T),
       bolge_ad = if (is.null(bt)) c("maks K'·y'Q⁻¹y", "F", "Oran") else names(bt),
       bolge = if (is.null(bt)) list(w$SR$maks_nicelik, w$SR$F_sr, w$SR$oran)
               else unname(lapply(bt, function(x) if (is.logical(x)) ifelse(x, "Evet", "Hayır") else x)),
       u_ad = names(u), uyd = unname(lapply(u, function(x) if (is.numeric(x)) round(x, 4) else as.character(x))),
       regulatif = kp_parti(unname(w$regulatif)))
}

# Hata sarmalayıcı: arayüze yalnızca okunabilir mesaj döner
kp_calistir <- function(ifade) {
  tryCatch(ifade, error = function(e) list(.hata = kp_parti(conditionMessage(e))),
           warning = function(w) list(.hata = kp_parti(conditionMessage(w))))
}
