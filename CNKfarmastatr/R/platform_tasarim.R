# =============================================================================
# CNK-FarmaStatR v1 - Platform: design selection for a target power
#
# FSR-TN-PLT-05 v0.2 (approved, KK-57), Section 3; scope decision KK-56.
# Research question (FSR-TN-PBE-01 v0.11 Section 1; KK-23, KK-28): which
#   number of batches l, units per batch n and, where needed, life stages m
#   reach the target power, and what is the type I error of that design.
# Rules (FSR-TN-PBE-01 v0.11 Section 11.5; simulasyon/FSR-TN-PBE-01/asama1_tablo113.R):
#   power is read at the chosen true difference (default GMR 1.05); type I error
#   at the method's own boundary (FDA: delta0; EMA: GMR 1.18).
#   Rule A (Table 11.3a): smallest total l * n * m with power >= target; ties to
#     the smaller l, then the smaller m (the m order is a FarmaStatR derivation;
#     with one m value the order is the published one).
#   Rule B (Table 11.3b): as A, within l >= 3 and n >= 10, and the type I error
#     label (KK-38) is not "nominali_asiyor"; otherwise none, with the reason.
#   A power cell counts only when R classifies the method as H1 at that
#     difference (KK-43, P4 rule); otherwise no selection for that method.
#   Near the target (KK-39): |power - target| < 2 MCSE is flagged; such a
#     selection does not show that the target is surely met.
# Common random numbers: every run starts from the same seed (invitro_grid.R),
#   so a live run with the grid's seed and n_sim reproduces the grid counts.
# Total work limit P5-K6 (a): sum of l * n * m * n_sim over the runs
#   <= 6e7 cells (temporary; FarmaStatR derivation, to be measured in P5).
# This file only plans runs, calls the pinned engine through
#   platform_run_invitro() and applies the rules; it computes no statistic.
# Version 0.2.0 (T-3): platform_export_tasarim(), the candidate set as a stand-alone
#   R script (tier 3; same structure as platform_export_invitro, FSR-TN-PLT-03).
# Base R only. Version 0.2.0
# Research and education only; not a system validated for GxP environments.
# =============================================================================

.tasarim_pop <- c("sigma_R", "rho", "pB_T", "pB_R", "pL", "q")
.tasarim_yontem <- c("fda", "ema_a", "ema_b", "ema_c")
.tasarim_t1_sinir <- c(fda = "fda_delta0", ema_a = "ema_1.18", ema_b = "ema_1.18", ema_c = "ema_1.18")

# -----------------------------------------------------------------------------
# platform_tasarim_plan(): the runs needed for a design search
#   pop      : named list sigma_R, rho, pB_T, pB_R, pL, q (defaults as the engine)
#   l, n, m  : candidate values (whole numbers; every combination is a design)
#   guc      : the true difference for power: list(gmr = ), list(delta = ) or
#              list(sinir = ) (a boundary name); default GMR 1.05
#   n_sim, seed : Monte Carlo settings, the same for every run (common seed)
#   toplam_max  : limit for the total work (cells); NULL = no limit
# Returns list(ok, problems, plan, rol, toplam_hucre, notlar):
#   plan : one row per distinct run (kosu_no, l, n, m, delta, sinir, anahtar)
#   rol  : one row per design and role (guc, t1_fda, t1_ema) -> kosu_no
# -----------------------------------------------------------------------------
platform_tasarim_plan <- function(pop, l = 2:6, n = c(5, 8, 10, 15, 20, 30), m = 3,
                                  guc = list(gmr = 1.05), n_sim = 10000, seed = 20261015,
                                  toplam_max = 6e7, n_sim_max = 20000, cells_max = 8.1e6) {
  pr <- data.frame(field = character(0), code = character(0), message = character(0),
                   stringsAsFactors = FALSE)
  bad <- function(field, code, message) pr[nrow(pr) + 1, ] <<- c(field, code, message)
  res <- function(...) list(ok = nrow(pr) == 0, problems = pr, ...)
  if (!is.list(pop) || is.null(names(pop)) || any(names(pop) == ""))
    { bad("pop", "params_not_named_list", "pop must be a named list."); return(res()) }
  for (u in setdiff(names(pop), .tasarim_pop)) bad(u, "unknown_param", paste0("Unknown parameter '", u, "'."))
  d <- list(sigma_R = NULL, rho = 1, pB_T = 0, pB_R = NULL, pL = 0.15, q = 0)
  for (k in names(pop)) d[[k]] <- pop[[k]]
  if (is.null(d$pB_R)) d$pB_R <- d$pB_T
  if (is.null(d$sigma_R)) bad("sigma_R", "missing_param", "sigma_R is required.")
  cand <- list(l = l, n = n, m = m)
  for (k in names(cand)) {
    v <- cand[[k]]
    if (!is.numeric(v) || length(v) < 1 || anyNA(v) || any(!is.finite(v)) ||
        any(abs(v - round(v)) > 0) || any(v < if (k == "m") 1 else 2) || anyDuplicated(v))
      bad(k, "candidate_list", paste0(k, " must be distinct whole numbers >= ", if (k == "m") 1 else 2, "."))
  }
  g <- guc
  if (!is.list(g) || length(g) != 1 || !names(g) %in% c("gmr", "delta", "sinir"))
    bad("guc", "power_difference", "guc must be list(gmr = ), list(delta = ) or list(sinir = ).")
  if (nrow(pr) > 0) return(res())
  gdelta <- switch(names(g),
                   gmr = if (is.numeric(g$gmr) && length(g$gmr) == 1 && is.finite(g$gmr) && g$gmr > 0) log(g$gmr) else NA_real_,
                   delta = if (is.numeric(g$delta) && length(g$delta) == 1 && is.finite(g$delta)) g$delta else NA_real_,
                   sinir = if (is.character(g$sinir) && length(g$sinir) == 1 && g$sinir %in% .platform_sinir_adlari)
                     platform_sinir_delta(g$sinir, d$sigma_R, d$rho) else NA_real_)
  if (is.na(gdelta)) { bad("guc", "power_difference", "The true difference for power is not valid or not defined."); return(res()) }
  gsinir <- if (names(g) == "sinir") g$sinir else NA_character_
  d0 <- platform_sinir_delta("fda_delta0", d$sigma_R, d$rho)
  notlar <- character(0)
  if (is.na(d0)) notlar <- c(notlar, "fda_delta0_undefined")
  des <- expand.grid(m = sort(m), n = sort(n), l = sort(l))[, c("l", "n", "m")]
  roles <- list(guc = list(delta = gdelta, sinir = gsinir),
                t1_fda = list(delta = d0, sinir = "fda_delta0"),
                t1_ema = list(delta = platform_sinir_delta("ema_1.18", d$sigma_R, d$rho), sinir = "ema_1.18"))
  if (is.na(d0)) roles$t1_fda <- NULL
  rol <- do.call(rbind, lapply(names(roles), function(r)
    data.frame(l = des$l, n = des$n, m = des$m, rol = r, delta = roles[[r]]$delta,
               sinir = roles[[r]]$sinir, stringsAsFactors = FALSE)))
  # a run is identified by its design and delta; a power difference equal to a
  # boundary shares the run (common seed: the same data sets)
  idk <- paste(rol$l, rol$n, rol$m, .num_exact(rol$delta))
  u <- !duplicated(idk)
  plan <- rol[u, c("l", "n", "m", "delta", "sinir")]
  plan$kosu_no <- seq_len(nrow(plan))
  rol$kosu_no <- match(idk, idk[u])
  plan$sinir[is.na(plan$sinir)] <- NA_character_
  plan$anahtar <- vapply(seq_len(nrow(plan)), function(i) {
    a <- list(sigma_R = d$sigma_R, rho = d$rho, pB_T = d$pB_T, pB_R = d$pB_R, pL = d$pL, q = d$q,
              l = plan$l[i], n = plan$n[i], m = plan$m[i], n_sim = n_sim, seed = seed, kosu = TRUE)
    if (is.na(plan$sinir[i])) a$delta <- plan$delta[i] else a$sinir <- plan$sinir[i]
    do.call(platform_anahtar, a)
  }, "")
  # every run must pass the single-run input check (KK-47 limits included)
  for (i in seq_len(nrow(plan))) {
    p <- platform_tasarim_params(d, plan[i, ], n_sim, seed)
    ch <- platform_check_invitro(p, n_sim_max = n_sim_max, cells_max = cells_max)
    for (j in seq_len(nrow(ch))) if (!paste(ch$field[j], ch$code[j]) %in% paste(pr$field, pr$code))
      bad(ch$field[j], ch$code[j], ch$message[j])
  }
  if (any(d$q > 0 & plan$m == 1))
    bad("m", "q_needs_m2", "q > 0 needs m >= 2 for every candidate m.")
  tot <- sum(plan$l * plan$n * plan$m) * n_sim
  if (!is.null(toplam_max) && nrow(pr) == 0 && tot > toplam_max)
    bad("tasarim", "design_size", paste0("Total work ", format(tot, scientific = FALSE, big.mark = ","),
                                          " cells exceeds ", format(toplam_max, scientific = FALSE, big.mark = ","),
                                          "; use the R script or fewer candidates."))
  res(plan = plan, rol = rol[, c("l", "n", "m", "rol", "kosu_no")], toplam_hucre = tot,
      notlar = notlar, pop = d, guc = g, n_sim = n_sim, seed = seed)
}

# engine arguments for one planned run
platform_tasarim_params <- function(pop, run, n_sim, seed) {
  list(sigma_R = pop$sigma_R, rho = pop$rho, pB_T = pop$pB_T, pB_R = pop$pB_R, pL = pop$pL,
       q = pop$q, l = run$l, n = run$n, m = run$m, delta = run$delta, n_sim = n_sim, seed = seed)
}

# -----------------------------------------------------------------------------
# platform_tasarim_secim(): apply the rules to run results
#   plan   : result of platform_tasarim_plan(); a plan above the total-work
#            limit is accepted (its results come from the database)
#   sonuc  : data frame, one row per run in plan order (kosu_no), with the
#            engine columns <method>_pass and <method>_pass_mcse
#   hedef  : target power (default 0.80)
# Returns list(tablo, secim):
#   tablo : one row per design and method: power, its MCSE, class and metric at
#           the power difference, type I error, MCSE and KK-38 label, flags
#   secim : one row per method and rule (A, B): chosen design or none + reason
# -----------------------------------------------------------------------------
platform_tasarim_secim <- function(plan, sonuc, hedef = 0.80, esik_k = 2,
                                   l_min = 3, n_min = 10) {
  # only the total-work limit may be exceeded: such a plan is selected from stored results
  if (is.null(plan$plan) || any(plan$problems$code != "design_size"))
    stop("The plan has problems; nothing to select.")
  if (!is.numeric(hedef) || length(hedef) != 1 || !(hedef > 0 && hedef < 1))
    stop("hedef must be one number in (0, 1).")
  if (nrow(sonuc) != nrow(plan$plan)) stop("sonuc must have one row per planned run.")
  d <- plan$pop; rol <- plan$rol
  des <- unique(rol[, c("l", "n", "m")])
  des <- des[order(des$l * des$n * des$m, des$l, des$m), ]
  gk <- rol$kosu_no[rol$rol == "guc"]; names(gk) <- with(rol[rol$rol == "guc", ], paste(l, n, m))
  pick <- function(r, me) {
    k <- rol$kosu_no[rol$rol == r]; names(k) <- with(rol[rol$rol == r, ], paste(l, n, m))
    k[paste(des$l, des$n, des$m)]
  }
  gdelta <- plan$plan$delta[gk[1]]
  hip <- platform_hipotez(d$sigma_R, d$rho, delta = gdelta)
  out <- list()
  for (me in .tasarim_yontem) {
    kg <- pick("guc", me)
    rt <- if (me == "fda") "t1_fda" else "t1_ema"
    kt <- if (rt %in% rol$rol) pick(rt, me) else rep(NA_integer_, nrow(des))
    p <- sonuc[[paste0(me, "_pass")]][kg]; pm <- sonuc[[paste0(me, "_pass_mcse")]][kg]
    t1 <- if (all(is.na(kt))) rep(NA_real_, nrow(des)) else sonuc[[paste0(me, "_pass")]][kt]
    t1m <- if (all(is.na(kt))) rep(NA_real_, nrow(des)) else sonuc[[paste0(me, "_pass_mcse")]][kt]
    h <- hip[hip$yontem == me, ]
    lab <- ifelse(is.na(t1), NA_character_, platform_kk38(t1, t1m, rep("H0_sinir", nrow(des))))
    out[[me]] <- data.frame(yontem = me, l = des$l, n = des$n, m = des$m,
      toplam = des$l * des$n * des$m, kosu_guc = unname(kg), kosu_t1 = unname(kt),
      guc_sinif = h$sinif, guc_metrik = h$metrik, guc = p, guc_mcse = pm,
      t1 = t1, t1_mcse = t1m, t1_etiket = lab,
      hedef_ok = h$sinif == "H1" & p >= hedef,
      esik_yakin = h$sinif == "H1" & abs(p - hedef) < esik_k * pm,
      duzenleyici = des$l >= l_min & des$n >= n_min,
      stringsAsFactors = FALSE)
  }
  tablo <- do.call(rbind, out); rownames(tablo) <- NULL
  sec <- list()
  for (me in .tasarim_yontem) {
    t <- tablo[tablo$yontem == me, ]
    h1 <- t$guc_sinif[1] == "H1"
    a <- which(t$hedef_ok)[1]
    reg <- t$duzenleyici
    okB <- t$hedef_ok & reg & !is.na(t$t1_etiket) & t$t1_etiket != "nominali_asiyor"
    b <- which(okB)[1]
    nedenA <- if (!h1) "sinif_h1_degil" else if (is.na(a)) "guc_yetersiz" else NA_character_
    nedenB <- if (!h1) "sinif_h1_degil" else if (!is.na(b)) NA_character_ else
      if (!any(t$hedef_ok & reg)) "guc_yetersiz" else
      if (all(is.na(t$t1_etiket[t$hedef_ok & reg]))) "tip1_hesaplanamadi" else "tip1_kalibrasyon"
    for (k in c("A", "B")) {
      i <- if (k == "A") a else b
      sec[[length(sec) + 1]] <- data.frame(yontem = me, kural = k, var = !is.na(i),
        l = t$l[i], n = t$n[i], m = t$m[i], toplam = t$toplam[i], guc = t$guc[i],
        guc_mcse = t$guc_mcse[i], t1 = t$t1[i], t1_mcse = t$t1_mcse[i],
        t1_etiket = t$t1_etiket[i], esik_yakin = if (is.na(i)) NA else t$esik_yakin[i],
        neden = if (k == "A") nedenA else nedenB, stringsAsFactors = FALSE)
    }
  }
  secim <- do.call(rbind, sec); rownames(secim) <- NULL
  list(tablo = tablo, secim = secim, hedef = hedef)
}

# -----------------------------------------------------------------------------
# platform_tasarim(): plan, run every planned scenario, select (local R, script)
#   ilerleme : optional function(i, toplam) called after each run
# -----------------------------------------------------------------------------
platform_tasarim <- function(pop, l = 2:6, n = c(5, 8, 10, 15, 20, 30), m = 3,
                             guc = list(gmr = 1.05), hedef = 0.80, n_sim = 10000,
                             seed = 20261015, toplam_max = 6e7, ilerleme = NULL) {
  pl <- platform_tasarim_plan(pop, l, n, m, guc, n_sim, seed, toplam_max)
  if (!pl$ok) {
    msg <- paste0("Invalid input:\n", paste0("- ", pl$problems$message, collapse = "\n"))
    stop(structure(class = c("farmastat_input_error", "error", "condition"),
                   list(message = msg, call = NULL, problems = pl$problems)))
  }
  rows <- vector("list", nrow(pl$plan))
  for (i in seq_len(nrow(pl$plan))) {
    rows[[i]] <- platform_run_invitro(platform_tasarim_params(pl$pop, pl$plan[i, ], n_sim, seed))
    if (is.function(ilerleme)) ilerleme(i, nrow(pl$plan))
  }
  sonuc <- do.call(rbind, rows)
  c(list(plan = pl, sonuc = sonuc), platform_tasarim_secim(pl, sonuc, hedef))
}

# =============================================================================
# Tier 3 for the design search (FSR-TN-PLT-05 v0.2 Section 3.4; T-3)
#   The script carries the five files of the scenario script and this file,
#   verifies their SHA-256, plans the runs, runs every planned scenario with
#   the unchanged engine (no browser limit) and applies rules A and B.
#   With the same seed and n_sim it gives the browser's counts and selection.
# =============================================================================
# (written out: this file is also loaded alone into the exported script)
.platform_tasarim_dosyalar <- c(sim_run.R = TRUE, invitro_fast.R = TRUE, invitro_grid.R = TRUE,
                                platform_input.R = FALSE, platform_hipotez.R = FALSE,
                                platform_tasarim.R = FALSE)

# bytes of the six source files from a folder (repository: <repo>/CNKfarmastatr/R)
platform_tasarim_dosyalari <- function(dizin) {
  f <- file.path(dizin, names(.platform_tasarim_dosyalar))
  miss <- f[!file.exists(f)]
  if (length(miss)) stop("Source file not found: ", paste(miss, collapse = ", "))
  stats::setNames(lapply(f, function(p) readBin(p, "raw", file.size(p))), names(.platform_tasarim_dosyalar))
}

# -----------------------------------------------------------------------------
# platform_export_tasarim(): stand-alone R script for a design search
#   pop, l, n, m, guc, hedef, n_sim, seed : as platform_tasarim()
#   dosyalar     : named list of raw vectors (platform_tasarim_dosyalari())
#   cekirdek_sha : pinned values (platform_cekirdek_sha())
#   file, zaman, paket_surumu : as platform_export_invitro()
# Returns the script text (one string), invisibly when written to a file.
# -----------------------------------------------------------------------------
platform_export_tasarim <- function(pop, l = 2:6, n = c(5, 8, 10, 15, 20, 30), m = 3,
                                    guc = list(gmr = 1.05), hedef = 0.80, n_sim = 10000,
                                    seed = 20261015, dosyalar, cekirdek_sha, file = NULL,
                                    zaman = Sys.time(), paket_surumu = NULL) {
  pl <- platform_tasarim_plan(pop, l, n, m, guc, n_sim, seed, toplam_max = NULL,
                              n_sim_max = Inf, cells_max = Inf)
  if (!pl$ok) {
    msg <- paste0("Invalid input:\n", paste0("- ", pl$problems$message, collapse = "\n"))
    stop(structure(class = c("farmastat_input_error", "error", "condition"),
                   list(message = msg, call = NULL, problems = pl$problems)))
  }
  if (!is.numeric(hedef) || length(hedef) != 1 || !(hedef > 0 && hedef < 1))
    stop("hedef must be one number in (0, 1).")
  need <- names(.platform_tasarim_dosyalar)
  if (!is.list(dosyalar) || !all(need %in% names(dosyalar)))
    stop("dosyalar must hold: ", paste(need, collapse = ", "), ".")
  sha <- vapply(need, function(f) { b <- dosyalar[[f]]; if (!is.raw(b)) stop(f, " must be raw.")
                                    .fsr_sha256(b) }, "")
  for (f in need[.platform_tasarim_dosyalar]) {
    if (is.na(cekirdek_sha[f])) stop(f, " is not in the pinned list.")
    if (!identical(sha[[f]], unname(cekirdek_sha[f])))
      stop("SHA-256 of ", f, " differs from CEKIRDEK_SHA256.txt; no script was written.")
  }
  if (any(vapply(need, function(f) any(dosyalar[[f]] == as.raw(13)), TRUE)))
    stop("Source files must have LF line ends.")
  pv <- if (!is.null(paket_surumu)) as.character(paket_surumu) else
    tryCatch(as.character(utils::packageVersion("CNKfarmastatr")), error = function(e) "source")
  d <- pl$pop
  popl <- vapply(names(d), function(k) sprintf("  %s = %s", k, .r_value(d[[k]])), "")
  popl[-length(popl)] <- paste0(popl[-length(popl)], ",")
  gtxt <- sprintf("list(%s = %s)", names(guc), .r_value(guc[[1]]))
  delim <- "---"
  has_end <- function(dl) any(vapply(need, function(f)
    grepl(paste0(")", dl, "\""), rawToChar(dosyalar[[f]]), fixed = TRUE, useBytes = TRUE), TRUE))
  while (has_end(delim)) delim <- paste0(delim, "-")
  out <- c(
    "# =============================================================================",
    "# CNK-FarmaStatR - hedef guc icin tasarim secimi / design selection for a target power",
    paste("#", .platform_beyan_tr),
    paste("#", .platform_beyan_en),
    "# -----------------------------------------------------------------------------",
    sprintf("# Exported by: platform_export_tasarim 0.2.0, CNKfarmastatr %s (time: .fsr_created below)", pv),
    "# Document   : FSR-TN-PLT-05 (P5, design selection; tier 3: stand-alone R script)",
    "# Requires   : R >= 4.0 and base R only; CNKfarmastatr need not be installed",
    "# Use        : Rscript <this file>      or      source(\"<this file>\")",
    "# Rules      : FSR-TN-PBE-01 v0.11 Section 11.5 (Tables 11.3a and 11.3b): power at the",
    "#              chosen difference, type I error at FDA delta0 and EMA GMR 1.18;",
    "#              rule A = smallest l*n*m with power >= target; rule B = also l >= 3,",
    "#              n >= 10 and KK-38 label not 'nominali_asiyor'; near target: < 2 MCSE",
    "# Engine     : FDA PBE (PSG 020929) and EMA OIP Rev. 2 Section 5.1 criterion 8,",
    "#              methods (a), (b), (c); invitro_scenario() unchanged (FSR-VAL-SIM-1)",
    "# =============================================================================",
    sprintf(".fsr_created <- %s   # time of export", .json_str(format(zaman, "%Y-%m-%d %H:%M:%S %z"))),
    "",
    "# ---- 1. Parameters: you may change these --------------------------------------",
    "pop <- list(",
    popl,
    ")",
    sprintf("l <- %s   # candidate batches per product", .r_value(as.numeric(l))),
    sprintf("n <- %s   # candidate units per batch", .r_value(as.numeric(n))),
    sprintf("m <- %s   # candidate life stages", .r_value(as.numeric(m))),
    sprintf("guc <- %s   # true difference for power: list(gmr = ), list(delta = ) or list(sinir = )", gtxt),
    sprintf("hedef <- %s   # target power", .r_value(hedef)),
    sprintf("n_sim <- %s; seed <- %s   # the same for every run (common seed)", .r_value(n_sim), .r_value(seed)),
    "output_dir <- \".\"   # tables (.csv) and run record (.json) are written here; NULL = no files",
    "# Regulatory constants used by the engine (its defaults; values of the guidelines, not settings;",
    "#   FSR-TN-PLT-15, KK-83): alpha = 0.05 (FDA 95% upper bound, PSG 020929 App. A, Step 4);",
    "#   sigma_T0 = 0.1 (FDA regulatory constant, scaling threshold, App. A, Steps 1 and 3; NOT the SD",
    "#   of the test product); theta_p = 2.0891; EMA limits 0.85 - 1.18 (CPMP/EWP/4151/00 Rev. 2, 5.1).",
    "",
    "# ---- 2. Size: information only ------------------------------------------------",
    sprintf("# %d candidate designs, %d runs, %s cells in total as exported. The browser",
            nrow(unique(pl$rol[, c("l", "n", "m")])), nrow(pl$plan),
            format(pl$toplam_hucre, big.mark = ",", scientific = FALSE)),
    "# limit (6e7 cells, P5-K6) is not applied here. Runs are done one after the other;",
    "# each starts from the same seed, so the order does not change any result.",
    "",
    "# ---- 3. Program: do not change ------------------------------------------------",
    sprintf(".fsr_export <- list(created = .fsr_created, package_version = %s,", .json_str(pv)),
    sprintf("                    disclaimer_tr = \"%s\",", .platform_esc_u(.platform_beyan_tr)),
    sprintf("                    disclaimer_en = \"%s\")", .platform_beyan_en),
    .platform_sha256_kod,
    .platform_script_tasarim_main,
    "",
    "# ---- 4. Embedded source files: do not change (verified by SHA-256) -------------",
    ".fsr_files <- list(")
  tail_txt <- c(")", "", "run <- .fsr_main(pop, l, n, m, guc, hedef, n_sim, seed, output_dir, .fsr_files, .fsr_export)")
  u <- function(x) charToRaw(enc2utf8(paste0(paste(x, collapse = "\n"), "\n")))
  emb <- lapply(need, function(f) c(
    charToRaw(sprintf("  %s = list(pinned = %s, sha256 = \"%s\", text = r\"%s(",
                      .json_str(f), if (.platform_tasarim_dosyalar[[f]]) "TRUE" else "FALSE", sha[[f]], delim)),
    dosyalar[[f]], charToRaw(paste0(")", delim, "\")", if (f == need[length(need)]) "" else ",", "\n"))))
  bytes <- c(u(out), unlist(emb), u(tail_txt))
  if (!is.null(file)) {
    con <- file(file, "wb"); on.exit(close(con))
    writeBin(bytes, con)
  }
  res <- rawToChar(bytes); Encoding(res) <- "UTF-8"
  if (!is.null(file)) invisible(res) else res
}

# Main program of the exported design script (written as text into the script)
.platform_script_tasarim_main <- c(
  ".fsr_main <- function(pop, l, n, m, guc, hedef, n_sim, seed, output_dir, files, info) {",
  "  t0 <- proc.time()[[\"elapsed\"]]",
  "  started <- format(Sys.time(), \"%Y-%m-%d %H:%M:%S %z\")",
  "  # 3a. verify every embedded file before anything is computed",
  "  got <- vapply(files, function(f) .fsr_sha256(charToRaw(gsub(\"\\r\\n\", \"\\n\", f$text, fixed = TRUE))), \"\")",
  "  bad <- names(files)[got != vapply(files, function(f) f$sha256, \"\")]",
  "  if (length(bad)) stop(\"SHA-256 mismatch in: \", paste(bad, collapse = \", \"),",
  "                        \". The file was changed (or re-encoded by an editor); nothing was computed.\", call. = FALSE)",
  "  cat(\"SHA-256 verified:\", paste(names(files), collapse = \", \"), \"\\n\")",
  "  # 3b. load into a new environment (the workspace is not changed)",
  "  env <- new.env(parent = globalenv())",
  "  for (f in files) eval(parse(text = gsub(\"\\r\\n\", \"\\n\", f$text, fixed = TRUE), keep.source = FALSE), envir = env)",
  "  # 3c. plan (browser limit not applied), run every planned scenario, select",
  "  pl <- env$platform_tasarim_plan(pop, l, n, m, guc, n_sim, seed, toplam_max = NULL, n_sim_max = Inf, cells_max = Inf)",
  "  if (!pl$ok) stop(\"Invalid input:\\n\", paste0(\"- \", pl$problems$message, collapse = \"\\n\"), call. = FALSE)",
  "  N <- nrow(pl$plan)",
  "  cat(sprintf(\"Plan: %d designs, %d runs, %s cells\\n\", nrow(unique(pl$rol[, c(\"l\", \"n\", \"m\")])), N,",
  "              format(pl$toplam_hucre, big.mark = \",\", scientific = FALSE)))",
  "  rows <- vector(\"list\", N)",
  "  for (i in seq_len(N)) {",
  "    rows[[i]] <- env$platform_run_invitro(env$platform_tasarim_params(pl$pop, pl$plan[i, ], n_sim, seed),",
  "                                          n_sim_max = Inf, cells_max = Inf)",
  "    cat(sprintf(\"  run %d/%d  l = %g, n = %g, m = %g  (%.0f s)\\n\", i, N, pl$plan$l[i], pl$plan$n[i], pl$plan$m[i],",
  "                proc.time()[[\"elapsed\"]] - t0))",
  "  }",
  "  sonuc <- do.call(rbind, rows)",
  "  s <- env$platform_tasarim_secim(pl, sonuc, hedef)",
  "  rng <- RNGkind()[1:2]",
  "  secs <- proc.time()[[\"elapsed\"]] - t0",
  "  # 3d. summary: chosen design per method and rule",
  "  sel <- s$secim",
  "  show <- data.frame(method = sel$yontem, rule = sel$kural,",
  "                     design = ifelse(sel$var, sprintf(\"%g x %g x %g\", sel$l, sel$n, sel$m), \"none\"),",
  "                     power = ifelse(sel$var, formatC(sel$guc, digits = 4, format = \"f\"), \"\"),",
  "                     mcse = ifelse(sel$var, formatC(sel$guc_mcse, digits = 4, format = \"f\"), \"\"),",
  "                     type1 = ifelse(sel$var & !is.na(sel$t1), formatC(sel$t1, digits = 4, format = \"f\"), \"\"),",
  "                     kk38 = ifelse(is.na(sel$t1_etiket), \"\", sel$t1_etiket),",
  "                     note = ifelse(sel$var, ifelse(sel$esik_yakin, \"near target (KK-39)\", \"\"), sel$neden),",
  "                     stringsAsFactors = FALSE)",
  "  cat(sprintf(\"\\nTarget power %s; n_sim = %s, seed = %s, RNG %s; %.1f s\\n\\n\", formatC(hedef, digits = 2, format = \"f\"),",
  "              format(n_sim, big.mark = \",\"), seed, paste(rng, collapse = \"/\"), secs))",
  "  print(show, row.names = FALSE)",
  "  cat(\"\\nThe search is limited to the candidate set.\\n\", info$disclaimer_tr, \"\\n\", info$disclaimer_en, \"\\n\", sep = \"\")",
  "  # 3e. files: tables with exact numbers, engine results, run record (JSON)",
  "  stamp <- format(Sys.time(), \"%Y%m%d-%H%M%S\")",
  "  rec <- list(run_id = paste0(\"script-\", stamp), platform = \"CNK-FarmaStatR\",",
  "              document = \"FSR-TN-PLT-05\", result_source = \"script\", kind = \"design_selection\",",
  "              disclaimer_tr = info$disclaimer_tr, disclaimer_en = info$disclaimer_en,",
  "              exported = info$created, package_version = info$package_version, started = started,",
  "              seconds = secs, r_version = R.version.string, r_platform = R.version$platform,",
  "              rng = rng, seed = seed, n_sim = n_sim, pop = pl$pop, l = l, n = n, m = m, guc = guc,",
  "              hedef = hedef, run_keys = pl$plan$anahtar,",
  "              files = lapply(names(files), function(k) list(file = k, pinned = files[[k]]$pinned,",
  "                                                            sha256 = files[[k]]$sha256, verified = TRUE)),",
  "              secim = s$secim, tablo = s$tablo)",
  "  if (!is.null(output_dir)) {",
  "    wcsv <- function(df, f) {",
  "      txt <- vapply(df, function(v) if (is.numeric(v)) ifelse(is.na(v), \"NA\", env$.num_exact(v)) else",
  "                    ifelse(is.na(v), \"NA\", as.character(v)), character(nrow(df)))",
  "      if (!is.matrix(txt)) txt <- matrix(txt, nrow = nrow(df))",
  "      writeLines(c(paste(names(df), collapse = \",\"), apply(txt, 1, paste, collapse = \",\")), f, useBytes = TRUE)",
  "    }",
  "    fb <- file.path(output_dir, paste0(\"farmastatr_tasarim_\", stamp))",
  "    wcsv(s$secim, paste0(fb, \"_secim.csv\")); wcsv(s$tablo, paste0(fb, \"_tablo.csv\"))",
  "    wcsv(cbind(kosu_no = pl$plan$kosu_no, anahtar = pl$plan$anahtar, sonuc), paste0(fb, \"_sonuc.csv\"))",
  "    writeLines(env$.to_json(rec), paste0(fb, \"_kayit.json\"), useBytes = TRUE)",
  "    cat(\"Written:\", paste0(fb, c(\"_secim.csv\", \"_tablo.csv\", \"_sonuc.csv\", \"_kayit.json\")), sep = \"\\n  \")",
  "  }",
  "  invisible(list(plan = pl, sonuc = sonuc, tablo = s$tablo, secim = s$secim, record = rec))",
  "}")
