# =============================================================================
# CNK-FarmaStatR - P1 acceptance computations (FSR-TN-PLT-01 v0.4, Table 11.1)
#
# The SAME code runs in the browser (webR, web/p1/kabul.html) and in local R
# (web/p1/kabul/p1_kabul.R); the two outputs are then compared row by row.
# Every function returns data.frame(bolum, anahtar, ad, deger) with deger as
# character: numbers are written with sprintf("%.17g") so they cross between
# webR, the CSV file and R without rounding.
# Needs: invitro_fast.R, invitro_grid.R, pbe_ornek_veri.R, platform_input.R.
# Research and education only; not a system validated for GxP environments.
# =============================================================================

.p1_rows <- function(bolum, anahtar, ad, deger) {
  deger <- if (is.character(deger)) deger else sprintf("%.17g", as.numeric(deger))
  data.frame(bolum = bolum, anahtar = anahtar, ad = ad, deger = deger,
             stringsAsFactors = FALSE)
}

# Table 11.1 "Test kümesi": designs 2 x 5, 3 x 10, 6 x 30; m = 1, 2, 3; pB 0 and
# 0.30; delta = FDA delta0 and GMR 1.05; n_sim 2,000; seed 20261015 (36 runs).
# Parameters not named in Table 11.1 are held at the prototype defaults
# (sigma_R 0.12, rho 1, pL 0.15, q 0).
p1_kabul_kosular <- function(n_sim = 2000, seed = 20261015) {
  out <- list(); k <- 0
  for (d in list(c(2, 5), c(3, 10), c(6, 30))) for (m in 1:3) for (pB in c(0, 0.30))
    for (dl in c("fda_delta0", "gmr_1.05")) {
      k <- k + 1
      p <- list(sigma_R = 0.12, rho = 1, pB = pB, pL = 0.15, q = 0, l = d[1], n = d[2],
                m = m, n_sim = n_sim, seed = seed)
      p$delta <- if (dl == "fda_delta0") invitro_delta0(p$sigma_R, p$rho) else log(1.05)
      r <- platform_run_invitro(p)
      key <- sprintf("K%02d|%dx%d|m%d|pB%s|%s", k, d[1], d[2], m, format(pB), dl)
      out[[k]] <- .p1_rows("kosu", key, names(r), unlist(r[1, ], use.names = FALSE))
    }
  do.call(rbind, out)
}

# Table 11.1 "Ara değerler": pbe_fast and ema_ci_fast intermediate quantities on
# fixed data: the PSG 020929 example and the first data set of TC-F2.
p1_kabul_ara <- function() {
  one <- function(set, XT, XR, lT, nT, lR, nR) {
    f <- pbe_fast(XT, XR, lT, nT, lR, nR)
    rows <- list()
    for (nm in names(f)) rows[[length(rows) + 1]] <-
      .p1_rows("ara", paste0(set, "|pbe|r", seq_len(nrow(f))), nm, as.numeric(f[[nm]]))
    e <- ema_ci_fast(XT, XR, lT, nT, lR, nR)
    for (me in names(e)) for (nm in c("gmr", "lower", "upper", "se", "df", "pass"))
      rows[[length(rows) + 1]] <- .p1_rows("ara", paste0(set, "|ema_", me, "|r", seq_len(nrow(e[[me]]))),
                                          nm, as.numeric(e[[me]][[nm]]))
    do.call(rbind, rows)
  }
  d <- ornek_psg020929()
  t <- invitro_array(d, "TEST"); r <- invitro_array(d, "REF")
  a <- one("psg020929", t$X, r$X, t$l, t$n, r$l, r$n)
  # TC-F2, first set (helper-cases.R cases_tcf2(): m = 1, design 3 x 10 / 3 x 10, 8 data sets)
  set.seed(20261015, kind = "Mersenne-Twister", normal.kind = "Inversion")
  XT <- invitro_gen(8, 3, 10, 1, mu = 0.05, sB = 0.05, sC = 0.08, sW = 0.04,
                    tau = invitro_drift(1, 0.0005))
  XR <- invitro_gen(8, 3, 10, 1, sB = 0.02, sC = 0.06, sW = 0.03)
  rbind(a, one("tcf2_1", XT, XR, 3, 10, 3, 10))
}

# Table 11.1 "Hata yakalama": inputs the engine rejects itself and inputs only the
# platform input check rejects; the run must not start in either case.
p1_kabul_hatalar <- function() {
  base <- list(sigma_R = 0.12, rho = 1, pB = 0, pL = 0.15, q = 0, l = 3, n = 10, m = 3,
               delta = 0, n_sim = 100, seed = 1)
  cases <- list(motor_paylar_pB = list(pB = 0.9), motor_paylar_pL = list(pL = -0.1),
                motor_m1_q = list(m = 1, q = 0.5), platform_sigma_neg = list(sigma_R = -0.12),
                platform_l1 = list(l = 1), platform_n1 = list(n = 1))
  res <- vapply(names(cases), function(k) {
    tryCatch({ platform_run_invitro(utils::modifyList(base, cases[[k]])); "KOSU_BASLADI" },
             farmastat_input_error = function(e) paste0("platform: ", paste(e$problems$code, collapse = ";")),
             error = function(e) paste0("motor: ", conditionMessage(e)))
  }, character(1))
  .p1_rows("hata", names(cases), "sonuc", unname(res))
}

p1_kabul_hepsi <- function() rbind(p1_kabul_kosular(), p1_kabul_ara(), p1_kabul_hatalar())
