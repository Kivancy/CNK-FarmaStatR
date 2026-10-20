# Design selection for a target power (FSR-TN-PLT-05 v0.2 Section 3; KK-56, KK-57).
# D-1: the rules reproduce Tables 11.3a and 11.3b of FSR-TN-PBE-01 v0.11
# (simulasyon/FSR-TN-PBE-01/asama1_tablo113.csv) from the Stage 1 results.

repo_file <- function(...) {
  for (d in c("../../..", "../..", ".")) {
    f <- file.path(d, ...)
    if (file.exists(f)) return(f)
  }
  NA_character_
}

pop0 <- function(pB) list(sigma_R = 0.12, rho = 1, pB_T = pB, pB_R = pB, pL = 0.15, q = 0)

# results of the planned runs taken from the Stage 1 grid (no simulation)
stage1_sonuc <- function(pl, s) {
  did <- ifelse(is.na(pl$plan$sinir), ifelse(abs(pl$plan$delta - log(1.05)) < 1e-15, "gmr_1.05", "gmr_1.00"),
                pl$plan$sinir)
  k <- match(paste(pl$pop$pB_T, pl$plan$l, pl$plan$n, did), paste(s$pB_T, s$l, s$n, s$delta_id))
  s[k, ]
}

test_that("plan: runs, roles, keys and total work", {
  pl <- platform_tasarim_plan(pop0(0.1), toplam_max = NULL)
  expect_true(pl$ok)
  expect_identical(nrow(pl$plan), 90L)                      # 30 designs x 3 differences
  expect_identical(nrow(pl$rol), 90L)
  expect_identical(sort(unique(pl$rol$rol)), c("guc", "t1_ema", "t1_fda"))
  expect_identical(pl$toplam_hucre, 3 * sum(outer(2:6, c(5, 8, 10, 15, 20, 30))) * 3 * 10000)
  expect_false(anyDuplicated(pl$plan$anahtar) > 0)
  k <- pl$plan[pl$plan$l == 3 & pl$plan$n == 10 & pl$plan$sinir %in% "ema_1.18", "anahtar"]
  expect_identical(k, platform_anahtar(0.12, 1, 0.1, 0.1, 0.15, 0, 3, 10, 3, sinir = "ema_1.18",
                                       n_sim = 10000, seed = 20261015, kosu = TRUE))
  # P5-K6 (a): the full Stage 1 candidate set is above the live limit
  big <- platform_tasarim_plan(pop0(0.1))
  expect_false(big$ok); expect_identical(big$problems$code, "design_size")
  small <- platform_tasarim_plan(pop0(0.1), l = 3:4, n = c(10, 15))
  expect_true(small$ok); expect_identical(nrow(small$plan), 12L)
  # a power difference equal to a boundary shares the run (same delta, same seed)
  sh <- platform_tasarim_plan(pop0(0), l = 3, n = 10, guc = list(sinir = "ema_1.18"))
  expect_identical(nrow(sh$plan), 2L); expect_identical(nrow(sh$rol), 3L)
})

test_that("plan: input problems are reported with codes", {
  expect_identical(platform_tasarim_plan(list(rho = 1))$problems$code, "missing_param")
  expect_identical(platform_tasarim_plan(pop0(0), l = c(1, 3))$problems$code, "candidate_list")
  expect_identical(platform_tasarim_plan(pop0(0), n = c(10, 10))$problems$code, "candidate_list")
  expect_identical(platform_tasarim_plan(pop0(0), guc = list(gmr = -1))$problems$code, "power_difference")
  expect_identical(platform_tasarim_plan(c(pop0(0), list(x = 1)))$problems$code, "unknown_param")
  p <- pop0(0); p$q <- 0.5
  expect_true("q_needs_m2" %in% platform_tasarim_plan(p, l = 3, n = 10, m = c(1, 3))$problems$code)
  expect_true("run_size" %in% platform_tasarim_plan(pop0(0), l = 6, n = 30, n_sim = 20000)$problems$code)
  # FDA delta0 undefined (eta > 0 at delta = 0): no FDA type I runs, a note
  u <- platform_tasarim_plan(list(sigma_R = 0.12, rho = 1.8), l = 3, n = 10)
  expect_true(u$ok); expect_identical(u$notlar, "fda_delta0_undefined")
  expect_false("t1_fda" %in% u$rol$rol)
})

test_that("D-1: Tables 11.3a and 11.3b are reproduced from the Stage 1 results", {
  fs <- repo_file("simulasyon", "FSR-TN-PBE-01", "asama1_sonuc.csv")
  ft <- repo_file("simulasyon", "FSR-TN-PBE-01", "asama1_tablo113.csv")
  expect_false(is.na(fs)); expect_false(is.na(ft))
  s <- utils::read.csv(fs, stringsAsFactors = FALSE)
  ref <- utils::read.csv(ft, stringsAsFactors = FALSE)
  mm <- c(FDA = "fda", EMA_a = "ema_a", EMA_b = "ema_b", EMA_c = "ema_c")
  lab <- c(exceeds = "nominali_asiyor", controlled = "kontrol_kanitli", inconclusive = "ayirt_edilemiyor")
  n_cells <- 0
  for (pb in c(0, 0.1, 0.3)) {
    pl <- platform_tasarim_plan(pop0(pb), toplam_max = NULL)
    so <- stage1_sonuc(pl, s)
    expect_false(anyNA(so$fda_pass))
    sel <- platform_tasarim_secim(pl, so)$secim
    for (me in names(mm)) for (k in c("A", "B")) {
      r <- ref[ref$table == (if (k == "A") "11.3a" else "11.3b") & ref$method == me & ref$pB == pb, ]
      x <- sel[sel$yontem == mm[[me]] & sel$kural == k, ]
      expect_identical(nrow(r), 1L)
      if (is.na(r$l)) {
        expect_false(x$var)
      } else {
        expect_true(x$var)
        expect_identical(c(x$l, x$n), as.integer(c(r$l, r$n)) + 0)
        expect_equal(c(x$guc, x$guc_mcse, x$t1, x$t1_mcse), c(r$power, r$power_mcse, r$t1, r$t1_mcse),
                     tolerance = 0)
        expect_identical(x$t1_etiket, unname(lab[r$t1_class]))
      }
      n_cells <- n_cells + 1
    }
  }
  expect_identical(n_cells, 24)
})

test_that("rules: class first, ties, near-target flag and reasons (constructed results)", {
  pl <- platform_tasarim_plan(pop0(0), l = 2:4, n = c(5, 10), toplam_max = NULL)
  so <- data.frame(row.names = seq_len(nrow(pl$plan)))
  for (me in c("fda", "ema_a", "ema_b", "ema_c")) { so[[paste0(me, "_pass")]] <- 0.01; so[[paste0(me, "_pass_mcse")]] <- 0.001 }
  g <- pl$rol[pl$rol$rol == "guc", ]
  set_p <- function(l, n, v, se = 0.004) { k <- g$kosu_no[g$l == l & g$n == n]; so[k, "ema_c_pass"] <<- v; so[k, "ema_c_pass_mcse"] <<- se }
  set_p(2, 10, 0.81)          # total 20, rule A; l = 2 outside the regulatory region
  set_p(4, 5, 0.85)           # total 20 too, larger l: loses the tie
  set_p(3, 10, 0.805)         # total 30, rule B; within 2 MCSE of 0.80 -> near flag
  r <- platform_tasarim_secim(pl, so)
  a <- r$secim[r$secim$yontem == "ema_c" & r$secim$kural == "A", ]
  b <- r$secim[r$secim$yontem == "ema_c" & r$secim$kural == "B", ]
  expect_identical(c(a$l, a$n), c(2, 10)); expect_false(a$esik_yakin)
  expect_identical(c(b$l, b$n), c(3, 10)); expect_true(b$esik_yakin)
  expect_identical(b$t1_etiket, "kontrol_kanitli")
  # power not reached by other methods
  expect_identical(r$secim$neden[r$secim$yontem == "fda" & r$secim$kural == "A"], "guc_yetersiz")
  # type I error over the nominal level removes the design from rule B only
  t <- pl$rol[pl$rol$rol == "t1_ema" & pl$rol$l == 3 & pl$rol$n == 10, "kosu_no"]
  so[t, "ema_c_pass"] <- 0.08; so[t, "ema_c_pass_mcse"] <- 0.003
  r2 <- platform_tasarim_secim(pl, so)$secim
  expect_identical(r2$neden[r2$yontem == "ema_c" & r2$kural == "B"], "tip1_kalibrasyon")
  expect_true(r2$var[r2$yontem == "ema_c" & r2$kural == "A"])
  # GMR 1.18 is not H1 for EMA: no power selection, with the reason
  p3 <- platform_tasarim_plan(pop0(0), l = 3, n = 10, guc = list(gmr = 1.18))
  so3 <- data.frame(fda_pass = c(0.9, 0.04), fda_pass_mcse = 0.003, ema_a_pass = 0.9, ema_a_pass_mcse = 0.003,
                    ema_b_pass = 0.9, ema_b_pass_mcse = 0.003, ema_c_pass = 0.9, ema_c_pass_mcse = 0.003)[seq_len(nrow(p3$plan)), ]
  r3 <- platform_tasarim_secim(p3, so3)
  expect_true(all(r3$secim$neden[r3$secim$yontem != "fda"] == "sinif_h1_degil"))
  expect_true(all(!r3$tablo$hedef_ok[r3$tablo$yontem != "fda"]))
  expect_error(platform_tasarim_secim(pl, so, hedef = 1.2), "hedef")
})

test_that("D-3 (R side): live runs reproduce the Stage 1 counts with the common seed", {
  fs <- repo_file("simulasyon", "FSR-TN-PBE-01", "asama1_sonuc.csv")
  s <- utils::read.csv(fs, stringsAsFactors = FALSE)
  r <- platform_tasarim(pop0(0.1), l = 2, n = 5)
  so <- stage1_sonuc(r$plan, s)
  for (me in c("fda", "ema_a", "ema_b", "ema_c"))
    expect_identical(round(r$sonuc[[paste0(me, "_pass")]] * 10000), round(so[[paste0(me, "_pass")]] * 10000))
  expect_identical(nrow(r$tablo), 4L); expect_identical(nrow(r$secim), 8L)
})
