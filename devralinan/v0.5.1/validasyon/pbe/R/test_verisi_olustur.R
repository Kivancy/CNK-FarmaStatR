# CNK-FarmaStatR · PBE · Test veri setlerinin üretimi (deterministik dönüşümler)
d <- read.csv("psg020929_ornek.csv", stringsAsFactors = FALSE)
yaz <- function(x, ad) write.csv(x, file.path("test_verisi", ad), row.names = FALSE)
yaz(d, "P1_psg020929.csv")                                          # TC-P1: PSG örneği
yaz(d[d$Stage == "B", ], "P2_m1.csv")                                 # TC-P2: tek aşama (m = 1)
# kaplar veriden seçilir: TEST'in ilk partisinin son iki kabı, REF'in ikinci partisinin son kabı
kT <- sort(unique(d$Container[d$Product == "TEST" & d$Batches == min(d$Batches[d$Product == "TEST"])]))
kR <- sort(unique(d$Container[d$Product == "REF" & d$Batches == sort(unique(d$Batches[d$Product == "REF"]))[2]]))
dd <- d[!(d$Container %in% c(tail(kT, 2), tail(kR, 1))), ]
yaz(dd, "P3_dengesiz.csv")                                            # TC-P3: dengesiz tasarım
dp <- d; dp$score[dp$Product == "TEST"] <- dp$score[dp$Product == "TEST"] - 0.3
yaz(dp, "P4_tekyon_aktif.csv")                                        # TC-P4: μT < μR (PSG verisinde μT > μR)
de <- d; de$score <- exp(de$score); yaz(de, "P5_exp.csv")             # TC-P5a: log dönüşümü
dk <- d; dk$Container <- ave(dk$Container, dk$Product, dk$Batches, FUN = function(x) match(x, sort(unique(x))))
yaz(dk, "P5_kap_tekrar.csv")                                          # TC-P5b: her partide kap 1–10
ds <- d[!(d$Product == "TEST" & d$Stage == "E"), ]; yaz(ds, "P5_stage_hata.csv")   # TC-P5c: Stage uyumsuz
dn <- d; dn$score[1] <- -1; yaz(dn, "P5_negatif.csv")                # TC-P5d: log + negatif değer
# TC-P6: σR sınırı (m = 1; 1 parti × 5 kap). REF sapmaları ±0.1 → σR² = 0.04/4 = 0.01
s6 <- function(r) data.frame(Batches = rep(c(1, 2), each = 5), Container = 1:10, Stage = "B",
                             Product = rep(c("REF", "TEST"), each = 5), score = c(r, c(0.05, -0.05, 0.02, 0.00, -0.02)))
yaz(s6(c(0.1, -0.1, 0.1, -0.1, 0)), "P6_sinir_esit.csv")
yaz(s6(c(0.1, -0.1, 0.1, -0.1, 0) * 1.0001), "P6_sinir_ustu.csv")
cat("Veri setleri:", paste(list.files("test_verisi"), collapse = ", "), "\n")
