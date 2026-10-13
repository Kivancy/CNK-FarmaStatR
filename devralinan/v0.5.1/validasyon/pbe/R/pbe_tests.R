# =============================================================================
# CNK-FarmaStatR — PBE modülü · Validasyon test vakaları
#   Test edilen: pbe_core.R (PBE_webr_v05_3 gömülü kodu, bayt bayt;
#                SHA-256 e7be66b8e93c79ec3cc78463513db3a2e2d48031dbdc0d41975ed6232426ac65)
#   Kaynak: FDA PSG_020929 (Budesonide, Aralık 2025), Appendix
#
# Referans türleri:
#   (Y) Yayımlanmış — PSG_020929 örnek sonuçları (6 anlamlı basamak) → göreli tolerans 5e-5
#   (B) Bağımsız uygulama — pbe_referans.py (PSG adımlarından yazılmış Python) → 1e-10
#   (A) Analitik / mantıksal
#
# Çalıştırma: source("pbe_core.R"); source("referans_python.R"); source("pbe_tests.R")
# =============================================================================

.sonuclar <- data.frame(TC = character(), kontrol = character(), kaynak = character(),
                        beklenen = numeric(), hesaplanan = numeric(), fark = numeric(),
                        tol = numeric(), durum = character(), stringsAsFactors = FALSE)
kontrol <- function(tc, ad, kaynak, beklenen, hesaplanan, tol, goreli = FALSE) {
  fark <- abs(beklenen - hesaplanan); if (goreli) fark <- fark / abs(beklenen)
  durum <- if (isTRUE(fark <= tol + 1e-15)) "GEÇTİ" else "KALDI"
  .sonuclar[nrow(.sonuclar) + 1, ] <<- list(tc, ad, kaynak, beklenen, hesaplanan, fark, tol, durum)
}
kontrol_mantik <- function(tc, ad, kaynak, beklenen, hesaplanan) {
  durum <- if (identical(beklenen, hesaplanan)) "GEÇTİ" else "KALDI"
  .sonuclar[nrow(.sonuclar) + 1, ] <<- list(tc, ad, kaynak, as.numeric(beklenen), as.numeric(hesaplanan), NA, NA, durum)
}
hata_var <- function(expr) inherits(try(expr, silent = TRUE), "try-error")
oku <- function(f) read.csv(file.path("test_verisi", f), stringsAsFactors = FALSE)
ALANLAR <- names(REF_B$P1)
b_karsilastir <- function(tc, senaryo, r, alanlar = ALANLAR) {
  for (a in alanlar) kontrol(tc, sprintf("%s: %s", senaryo, a), "B", unname(REF_B[[senaryo]][a]), r[[a]], 1e-10)
  kontrol_mantik(tc, sprintf("%s: ölçüt", senaryo), "B", TRUE, r$criterion == KRITER_B[[senaryo]])
  kontrol_mantik(tc, sprintf("%s: karar", senaryo), "B", TRUE, r$pass_fail == KARAR_B[[senaryo]])
}

# =============================================================================
# TC-P1 · PSG_020929 örnek verisi (180 gözlem: 2 ürün × 3 parti × 10 kap × 3 aşama)
# =============================================================================
p1 <- calc_pbe(oku("P1_psg020929.csv"))
psg <- c(E_D = 0.022094106, H_D = 0.113976896, U_D = 0.008442447, E1 = 0.219742944, H1 = 0.359860715, U1 = 0.01963299,
         E2 = 3.9108E-05, H2 = 5.43319E-05, U2 = 2.31765E-10, E3s = -0.505515326, H3s = -0.344478125, U3s = 0.02593298,
         E4s = -0.000256672, H4s = -0.000194739, U4s = 3.83572E-09, Eq_Ref = -0.26389584, Uq_Ref = 0.054008421,
         H_eta_Ref = -0.031498721, E3c = -0.163644789, H3c = -0.111514028, U3c = 0.002717616, E4c = -8.30895E-05,
         H4c = -6.30405E-05, U4c = 4.0196E-10, Eq_Const = 0.057257267, Uq_Const = 0.030793054, H_eta_Const = 0.232736764)
for (a in names(psg)) kontrol("TC-P1", paste("PSG:", a), "Y", unname(psg[a]), p1[[a]], 5e-5, goreli = TRUE)
kontrol("TC-P1", "PSG: σR² (MSB_R/m + (m−1)MSW_R/m)", "Y", 0.163727878, p1$Sigma_R^2, 5e-5, goreli = TRUE)
kontrol_mantik("TC-P1", "PSG: σR > σT0 → referans ölçekli", "Y", TRUE, p1$criterion == "Reference-scaled")
kontrol_mantik("TC-P1", "PSG: karar PASS (Hη ≤ 0)", "Y", TRUE, p1$pass_fail == "PASS")
kontrol("TC-P1", "tasarım: m = 3", "A", 3, p1$m, 0)
kontrol("TC-P1", "tasarım: toplam kap T = n·l = 30", "A", 30, p1$total_t, 0)
kontrol("TC-P1", "θ_P = ((ln 1.11)² + 0.01)/σT0²", "A", ((log(1.11))^2 + 0.01) / 0.1^2, p1$Theta_p, 1e-14)
b_karsilastir("TC-P1", "P1", p1)
# Tek yönlü seçenek: PSG verisinde μT > μR olduğundan devreye girmez → sonuç değişmez
p1t <- calc_pbe(oku("P1_psg020929.csv"), one_sided = TRUE)
kontrol_mantik("TC-P1", "tek yönlü seçenek, μT > μR: etkin değil", "A", FALSE, p1t$one_sided_active)
kontrol("TC-P1", "tek yönlü seçenek, μT > μR: Hη değişmez", "A", p1$H_eta_Ref, p1t$H_eta_Ref, 0)

# =============================================================================
# TC-P2 · Tek aşama (m = 1): yalnızca "B" aşaması
# =============================================================================
p2 <- calc_pbe(oku("P2_m1.csv"))
kontrol("TC-P2", "m = 1", "A", 1, p2$m, 0)
for (a in c("msw_t", "msw_r", "E2", "E4s", "E4c", "H2", "H4s", "H4c", "U2", "U4s", "U4c"))
  kontrol("TC-P2", paste(a, "= 0"), "A", 0, p2[[a]], 0)
kontrol("TC-P2", "σR = √MSB_R (m = 1)", "A", sqrt(p2$msb_r), p2$Sigma_R, 1e-15)
b_karsilastir("TC-P2", "P2", p2)

# =============================================================================
# TC-P3 · Dengesiz tasarım (FarmaStatR türetimi: toplam kap sayısı kullanılır)
#   TEST ilk partiden 2 kap, REF ikinci partiden 1 kap çıkarıldı
# =============================================================================
p3 <- calc_pbe(oku("P3_dengesiz.csv"))
kontrol("TC-P3", "toplam kap T = 28", "A", 28, p3$total_t, 0)
kontrol("TC-P3", "toplam kap R = 29", "A", 29, p3$total_r, 0)
kontrol_mantik("TC-P3", "dengesizlik tespit edildi (T ve R)", "A", TRUE, !p3$bal_t && !p3$bal_r)
kontrol_mantik("TC-P3", "dengeli veride denge bayrağı (P1)", "A", TRUE, p1$bal_t && p1$bal_r)
b_karsilastir("TC-P3", "P3", p3)

# =============================================================================
# TC-P4 · Modified one-sided PBE (PSG_020121): μT < μR iken E_D = H_D = U_D = 0
#   Veri: PSG örneğinde TEST değerleri 0.3 azaltıldı
# =============================================================================
p4t <- calc_pbe(oku("P4_tekyon_aktif.csv"), one_sided = TRUE)
p4i <- calc_pbe(oku("P4_tekyon_aktif.csv"), one_sided = FALSE)
kontrol_mantik("TC-P4", "μT < μR: tek yönlü düzeltme etkin", "A", TRUE, p4t$one_sided_active)
for (a in c("E_D", "H_D", "U_D")) kontrol("TC-P4", paste(a, "= 0"), "A", 0, p4t[[a]], 0)
for (a in c("E1", "E2", "E3s", "E4s", "U1", "U3s")) kontrol("TC-P4", paste(a, ": iki yönlüyle aynı"), "A", p4i[[a]], p4t[[a]], 0)
kontrol_mantik("TC-P4", "iki yönlü: E_D > 0", "A", TRUE, p4i$E_D > 0)
b_karsilastir("TC-P4", "P4_tekyon", p4t, c("E_D", "H_D", "U_D", "Eq_Ref", "Uq_Ref", "H_eta_Ref", "H_eta_Const"))
b_karsilastir("TC-P4", "P4_iki", p4i, c("E_D", "H_D", "U_D", "Eq_Ref", "Uq_Ref", "H_eta_Ref", "H_eta_Const"))

# =============================================================================
# TC-P5 · Log dönüşümü, parti + kap gruplaması, hata yakalama
# =============================================================================
p5e <- calc_pbe(oku("P5_exp.csv"), log_transform = TRUE)
for (a in c("E_D", "E1", "E2", "E3s", "E4s", "H_eta_Ref", "H_eta_Const", "Sigma_R"))
  kontrol("TC-P5", paste("exp(veri) + log dönüşümü = PSG:", a), "A", p1[[a]], p5e[[a]], 1e-12)
p5k <- calc_pbe(oku("P5_kap_tekrar.csv"))
for (a in c("msb_t", "msw_t", "msb_r", "msw_r", "H_eta_Ref", "H_eta_Const"))
  kontrol("TC-P5", paste("kap no her partide 1–10: sonuç aynı:", a), "A", p1[[a]], p5k[[a]], 1e-15)
kontrol_mantik("TC-P5", "Stage kümeleri uyuşmazsa hata", "A", TRUE, hata_var(calc_pbe(oku("P5_stage_hata.csv"))))
kontrol_mantik("TC-P5", "log dönüşümünde negatif değer → hata", "A", TRUE,
               hata_var(suppressWarnings(calc_pbe(oku("P5_negatif.csv"), log_transform = TRUE))))
kontrol_mantik("TC-P5", "log dönüşümü yokken negatif değer kabul", "A", FALSE, hata_var(calc_pbe(oku("P5_negatif.csv"))))
kontrol_mantik("TC-P5", "boş TEST grubu → hata", "A", TRUE,
               hata_var(calc_pbe(subset(oku("P1_psg020929.csv"), Product == "REF"))))
b_karsilastir("TC-P5", "P5_exp", p5e, c("H_eta_Ref", "H_eta_Const", "Sigma_R"))
b_karsilastir("TC-P5", "P5_kap", p5k, c("H_eta_Ref", "H_eta_Const", "Sigma_R"))

# =============================================================================
# TC-P6 · Ölçüt sınırı: σR = σT0 → sabit ölçekli (PSG: "σR ≤ σT0 constant-scaled")
# =============================================================================
p6e <- calc_pbe(oku("P6_sinir_esit.csv")); p6u <- calc_pbe(oku("P6_sinir_ustu.csv"))
kontrol("TC-P6", "σR = 0.1 (kayan noktada σT0 ile eşit)", "A", 0.1, p6e$Sigma_R, 0)
kontrol_mantik("TC-P6", "σR = σT0 → sabit ölçekli", "A", TRUE, p6e$criterion == "Constant-scaled")
kontrol_mantik("TC-P6", "σR = 0.10001 → referans ölçekli", "A", TRUE, p6u$criterion == "Reference-scaled")
kontrol("TC-P6", "sabit ölçekte nihai Hη = Hη_Const", "A", p6e$H_eta_Const, p6e$H_eta_final, 0)
b_karsilastir("TC-P6", "P6_esit", p6e, c("H_eta_Ref", "H_eta_Const", "Sigma_R"))
b_karsilastir("TC-P6", "P6_ustu", p6u, c("H_eta_Ref", "H_eta_Const", "Sigma_R"))

# ---- Özet ---------------------------------------------------------------------
cat("\n==================== VALİDASYON ÖZETİ (PBE) ====================\n")
print(.sonuclar[, c("TC", "kontrol", "kaynak", "beklenen", "hesaplanan", "fark", "durum")], row.names = FALSE, digits = 10)
cat(sprintf("\nToplam: %d kontrol · GEÇTİ: %d · KALDI: %d\n",
            nrow(.sonuclar), sum(.sonuclar$durum == "GEÇTİ"), sum(.sonuclar$durum == "KALDI")))
