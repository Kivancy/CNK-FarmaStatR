# =============================================================================
# CNK-FarmaStatR v1 · Devralınan dissolüsyon validasyon testlerini çalıştırır
#   Bu klasörde: setwd("<bu klasör>"); source("Calistir.R")
#   Beklenen: 1A MSD 60/60 · 1B Weibull MSD 98/98 · 2 bootstrap f2 120/120
# Not: Test betikleri 13.10.2026'da eski geliştirme sohbetinden yeniden kuruldu
#      (FSR-LOG-01, G-03). Çekirdek dosyalar v0.5.1 ile bayt bayt aynıdır.
# =============================================================================
calistir <- function(cekirdekler, test) {
  for (f in cekirdekler) source(f, encoding = "UTF-8")
  invisible(capture.output(source(test, encoding = "UTF-8")))
  c(toplam = nrow(.sonuclar), gecti = sum(.sonuclar$durum == "GEÇTİ"))
}
sonuc <- rbind(
  "1A  MSD (msd_tests.R)"                 = calistir("msd_core.R", "msd_tests.R"),
  "1B  Weibull MSD (msd_weibull_tests.R)" = calistir(c("msd_core.R", "msd_weibull.R"), "msd_weibull_tests.R"),
  "2   Bootstrap f2 (f2_tests.R)"         = calistir(c("f2_boot.R", "f2_noce_data.R"), "f2_tests.R"))
print(sonuc)
cat(if (all(sonuc[, 1] == sonuc[, 2]) && all(sonuc[, 1] == c(60, 98, 120)))
      "\nSONUÇ: 278/278 GEÇTİ\n" else "\nSONUÇ: BEKLENEN SONUÇ ALINAMADI\n")
