# =============================================================================
# FarmaStatR Bölüm 2 — SAS çapraz doğrulaması için bootstrap indekslerini dışa aktarır
#   seed = 20260927, n_T = n_R = 12 (Mersenne-Twister/Inversion/Rejection)
#   1) EMA ön ayarı, B = 5000   → f2_idx_seed20260927.csv
#   2) FDA ön ayarı, B = 10000  → f2_idx_seed20260927_B10000.csv
# İsteğe bağlı: cikti_klasoru — SAS'ın okuyacağı ASCII bir klasör (ör. "C:/FarmaStatR")
# =============================================================================
cikti_klasoru <- if (exists("cikti_klasoru")) cikti_klasoru else "."
source("f2_boot.R", encoding = "UTF-8")
source("f2_noce_data.R", encoding = "UTF-8")
dir.create(cikti_klasoru, showWarnings = FALSE, recursive = TRUE)
d1 <- file.path(cikti_klasoru, "f2_idx_seed20260927.csv")
d2 <- file.path(cikti_klasoru, "f2_idx_seed20260927_B10000.csv")
f2_export_indices(calc_f2_boot(noce_P1, noce_P3, noce_t), d1)
f2_export_indices(calc_f2_boot(noce_P1, noce_P3, noce_t, perspektif = "FDA"), d2)
cat("İndeksler yazıldı:\n ", normalizePath(d1), "\n ", normalizePath(d2), "\n")
