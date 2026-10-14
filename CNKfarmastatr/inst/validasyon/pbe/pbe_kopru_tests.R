# =============================================================================
# CNK-FarmaStatR — PBE köprüsü (kopru.R) test vakaları · TC-K1 … TC-K4
#   Köprü üzerinden hesap = çekirdeğin doğrudan çağrısı (birebir); hatalı girdi reddedilir.
# Çalıştırma: source("pbe_core.R"); source("kopru.R"); source("pbe_ornek_veri.R"); source("pbe_kopru_tests.R")
# =============================================================================
.kt <- data.frame(TC = character(), kontrol = character(), durum = character(), stringsAsFactors = FALSE)
kt <- function(tc, ad, kosul) .kt[nrow(.kt) + 1, ] <<- list(tc, ad, if (isTRUE(kosul)) "GEÇTİ" else "KALDI")
hata <- function(x) !is.null(x$.hata)
d <- ornek_psg020929(); ch <- function(x) as.character(x)
hz <- function(dd, test = "TEST", ref = "REF", log_d = FALSE)
  kp_calistir(kp_hazirla(ch(dd$Batches), ch(dd$Container), ch(dd$Stage), ch(dd$Product), dd$score, test, ref, log_d))
ayni <- function(a, b) { k <- intersect(names(a), names(b)); all(vapply(k, function(x) identical(a[[x]], b[[x]]), TRUE)) }

# TC-K1 · Köprü = çekirdek (PSG örneği)
h <- hz(d); kt("TC-K1", "hazırlama başarılı", !hata(h))
kt("TC-K1", "m = 3, aşamalar B/E/M", h$m == 3 && identical(h$asamalar, c("B", "E", "M")))
kt("TC-K1", "tasarım: TEST 3 parti × 10 kap, REF 3 × 10", h$T$parti == 3 && h$T$toplam_kap == 30 && h$R$toplam_kap == 30)
r <- kp_calistir(kp_pbe(FALSE)); dogrudan <- calc_pbe(d)
kt("TC-K1", "köprü sonucu = calc_pbe (tüm ortak alanlar birebir)", ayni(r, dogrudan))
kt("TC-K1", "Hη_Ref = −0.031498739318…", abs(r$H_eta_Ref - (-0.031498739318481)) < 1e-14)
kt("TC-K1", "B-4: log kapalıyken GM_T/GM_R/GMR yok", !any(c("GM_T", "GM_R", "GMR") %in% names(r)))
# Farklı etiketler (T/R) ve karışık sıra
d2 <- d[sample(nrow(d)), ]; set.seed(1); d2$Product <- ifelse(d2$Product == "TEST", "Jenerik", "Orijinal")
h2 <- hz(d2, "Jenerik", "Orijinal"); r2 <- kp_calistir(kp_pbe(FALSE))
kt("TC-K1", "farklı ürün etiketleri ve karışık satır sırası: sonuç aynı", !hata(h2) && abs(r2$H_eta_Ref - r$H_eta_Ref) < 1e-14 && abs(r2$H_eta_Const - r$H_eta_Const) < 1e-14)
# Diğer ürünler veride olsa bile yok sayılır
d3 <- rbind(d, transform(d[d$Product == "REF", ], Product = "BASKA", score = score + 1))
h3 <- hz(d3); r3 <- kp_calistir(kp_pbe(FALSE))
kt("TC-K1", "veride üçüncü ürün varken yalnızca TEST/REF kullanılır", !hata(h3) && h3$satir == 180 && abs(r3$H_eta_Ref - r$H_eta_Ref) < 1e-14)

# TC-K2 · Log dönüşümü ve tek yönlü seçenek
de <- transform(d, score = exp(score)); hz(de, log_d = TRUE); re <- kp_calistir(kp_pbe(FALSE))
kt("TC-K2", "exp(veri) + log = PSG sonucu", abs(re$H_eta_Ref - r$H_eta_Ref) < 1e-12 && abs(re$Sigma_R - r$Sigma_R) < 1e-12)
kt("TC-K2", "log açıkken GM alanları var", all(c("GM_T", "GM_R", "GMR") %in% names(re)))
d4 <- transform(d, score = ifelse(Product == "TEST", score - 0.3, score)); hz(d4)
r4t <- kp_calistir(kp_pbe(TRUE)); r4i <- kp_calistir(kp_pbe(FALSE))
kt("TC-K2", "tek yönlü, μT < μR: etkin ve E_D = 0", isTRUE(r4t$one_sided_active) && r4t$E_D == 0)
kt("TC-K2", "tek yönlü sonuç = calc_pbe(one_sided = TRUE)", ayni(r4t, calc_pbe(d4, one_sided = TRUE)))
kt("TC-K2", "iki yönlü: E_D > 0", r4i$E_D > 0)

# TC-K3 · Tamlık kontrolü (B-2)
dt <- rbind(d, d[1, ]); kt("TC-K3", "aynı kap + aşamada tekrarlı ölçüm reddedilir", hata(hz(dt)) && grepl("birden fazla", hz(dt)$.hata))
de2 <- d[-5, ]; kt("TC-K3", "bir kapta eksik aşama reddedilir", hata(hz(de2)) && grepl("eksik", hz(de2)$.hata))
kt("TC-K3", "eksik aşamada çekirdek doğrudan çağrılsa hata VERMEZ (köprünün gerekçesi)", !inherits(try(calc_pbe(de2), silent = TRUE), "try-error"))
de3 <- d[d$Product == "REF" | d$Stage != "E", ]; kt("TC-K3", "TEST/REF aşama kümeleri farklı → reddedilir", hata(hz(de3)) && grepl("aşamaları farklı", hz(de3)$.hata))
# Dengesiz ama tam tasarım kabul edilir ve uyarı verilir
kap_sil <- unique(d$Container[d$Product == "TEST"])[1]; dd <- d[d$Container != kap_sil, ]
hd <- hz(dd); kt("TC-K3", "dengesiz ama tam tasarım kabul edilir, uyarı verilir", !hata(hd) && hd$T$toplam_kap == 29 && any(grepl("dengesiz", hd$uyarilar)))
kt("TC-K3", "dengesiz tasarım sonucu = calc_pbe", ayni(kp_calistir(kp_pbe(FALSE)), calc_pbe(dd)))

# TC-K4 · Girdi hataları
dn <- d; dn$score[3] <- NA; kt("TC-K4", "eksik ölçüm reddedilir", hata(hz(dn)))
dg <- de; dg$score[7] <- -1; kt("TC-K4", "log + negatif değer reddedilir", hata(hz(dg, log_d = TRUE)))
kt("TC-K4", "TEST = REF reddedilir", hata(hz(d, "TEST", "TEST")))
kt("TC-K4", "olmayan ürün etiketi reddedilir", hata(hz(d, "YOK", "REF")))
db <- d; db$Stage[2] <- ""; kt("TC-K4", "boş aşama hücresi reddedilir", hata(hz(db)))
hz(dn); kt("TC-K4", "başarısız hazırlamadan sonra hesap yapılmaz", hata(kp_calistir(kp_pbe(FALSE))))

cat(sprintf("Köprü testleri: %d kontrol · GEÇTİ: %d · KALDI: %d\n", nrow(.kt), sum(.kt$durum == "GEÇTİ"), sum(.kt$durum != "GEÇTİ")))
if (any(.kt$durum != "GEÇTİ")) print(.kt[.kt$durum != "GEÇTİ", ], row.names = FALSE)
