# Experiment (to-do #18): kicker accuracy memory (fade) x blend weight, and a two-sided blend with a
# new-kicker starting point. Added 2026-09-29. Not part of the weekly run.
# Log: claude/14c_accuracy_fade_prior_log.md. Builds on 14_fg_shrinkage_experiments.R.
#
# RULES (set with the user 2026-09-29, before any results were seen):
#   Sample: every kicker-game, 2016-2025 regular season. Inputs from build_week_inputs() (09) with 06b's
#     kicker rule and the 4-season window a live run would use (season-3 .. season). Volume models (07)
#     unchanged; only the FG make chances change. Blocked kicks count as misses (14's Test B failed).
#   Decides: pairwise hit rate within the PRE-GAME TOP 16 (pairs of top-16 kickers in the same week whose
#     actual points differ; share where the higher projection scored more; projection tie = 1/2).
#   Guardrail: pairwise hit rate across all kickers must not be worse in >= 95% of bootstrap resamples.
#   Adopt only if, with the setting chosen leave-one-season-out (picked on 9 seasons, scored on the 10th):
#     (1) held-out top-16 hit rate beats the challenged setting in >= 95% of 2,000 week-block bootstrap
#     resamples, (2) better in >= 7 of 10 held-out seasons, (3) guardrail holds.
#   Test C (fade x weight): half-life 12 / 24 / 48 games / no fade x weight 2, 5, 10, 20, 35, 50, 100,
#     200, Inf. Challenges the current setting (12, 5).
#   Test D (two-sided blend + new-kicker start): separate weights for above-league records (2, 5, 10, 20,
#     35, 50) and below-league records (5, 20, 50, 100, Inf), and a new-kicker starting point 0 / 1 / 2 /
#     3 points below league; fade free (12 / 24 / 48 / none). Challenges Test C's winner (or the current
#     setting if C fails).
#   Reported, not deciding: the best setting where established good kickers keep >= 2/3 of their edge
#     (good-record weight <= 5: 10 effective kicks in a range keep >= 10/15); the best setting with no
#     new-kicker dock; Brier score for every setting.
#
# DEFINITIONS
#   Record in range r (fade h): decayed makes m and attempts n before the game (weight 0.5^(games ago/h),
#   games = games with an FG attempt, as in 05). League rate L_r over the window.
#   Blend: p_r = (m + w L_r) / (n + w), w = the good-record weight if m > n L_r, else the bad-record
#   weight (w = Inf gives L_r).
#   New-kicker start: p_r is lowered by delta * s / (N + s), N = the kicker's decayed FG attempts in all
#   ranges, s = 10 (fixed, not tuned): no record -> the full delta; 10 kicks -> half; 30 -> a quarter.

suppressMessages({library(dplyr); library(tidyr); library(readr)})
source("00_nflverse_data.R")
source("08_points_distribution.R")
source("09_weekly_inputs.R")
set.seed(20260929)

SEASONS <- if (exists("SEASONS_OVERRIDE")) SEASONS_OVERRIDE else 2016:2025
CACHE <- if (exists("CACHE_OVERRIDE")) CACHE_OVERRIDE else "data/fade_prior_inputs.rds"
FADES <- c(12, 24, 48, Inf)
FTAG <- c("12", "24", "48", "inf")
PTS <- c("039" = 3, "4049" = 4, "50" = 5)
NEW_S <- 10
MODEL_NAMES <- c("xp_attempts", "att_039", "att_4049", "att_50")
fits <- setNames(lapply(file.path("models", paste0("volume_", MODEL_NAMES, "_model.rds")), readRDS), MODEL_NAMES)

# --- Stage 1: inputs for every kicker-game (cached) ------------------------------------------
if (!file.exists(CACHE)) {
  rows <- list()
  for (S in SEASONS) {
    pbp <- load_pbp_data((S - 3):S); sched <- load_schedule_data((S - 3):S)
    # nflverse play-by-play uses today's team codes for relocated teams; the schedule file keeps the old
    # ones (OAK, SD, STL). Align them, or those teams' games and their opponents' drop out.
    sched <- sched |> mutate(across(c(home_team, away_team), ~ dplyr::recode(.x, OAK = "LV", SD = "LAC", STL = "LA")))
    kp <- pbp |> filter(field_goal_attempt == 1, !is.na(kicker_player_id)) |>
      mutate(made = as.integer(field_goal_result == "made"),
             r = case_when(kick_distance <= 39 ~ "039", kick_distance <= 49 ~ "4049", TRUE ~ "50"))
    kg <- kp |> group_by(season, week, game_id, posteam, kicker_player_id, r) |>
      summarise(att = n(), mk = sum(made, na.rm = TRUE), .groups = "drop") |>
      pivot_wider(names_from = r, values_from = c(att, mk), values_fill = 0) |>
      mutate(ord = season * 100 + week) |> arrange(kicker_player_id, ord)
    for (col in c(paste0("att_", names(PTS)), paste0("mk_", names(PTS)))) if (!col %in% names(kg)) kg[[col]] <- 0
    lg <- sapply(names(PTS), function(r) sum(kg[[paste0("mk_", r)]]) / sum(kg[[paste0("att_", r)]]))
    base_cols <- c(outer(c("att_", "mk_"), names(PTS), paste0))
    logs <- lapply(seq_along(FADES), function(i) kg |> group_by(kicker_player_id) |>
      mutate(across(all_of(base_cols), ~ .running_after(.x, FADES[i]), .names = "h{FTAG[i]}_{.col}")) |> ungroup())
    weeks <- sort(unique(sched$week[sched$season == S & sched$game_type == "REG"]))
    for (wk in weeks) {
      b <- build_week_inputs(pbp, sched, S, wk) |> filter(!is.na(kicker_player_id), !is.na(actual_points))
      for (o in MODEL_NAMES) b[[paste0("lambda_", sub("att_|_attempts", "", o))]] <- predict(fits[[o]], b, type = "response")
      for (i in seq_along(FADES)) {
        cols <- paste0("h", FTAG[i], "_", base_cols)
        st <- .state_before(logs[[i]], b$kicker_player_id, b$ord, cols)
        b <- bind_cols(b, as_tibble(st))
      }
      this <- kg |> filter(season == S, week == wk) |> select(game_id, posteam, kicker_player_id, all_of(base_cols))
      names(this)[-(1:3)] <- paste0("g_", names(this)[-(1:3)])
      b <- b |> left_join(this, by = c("game_id", "posteam", "kicker_player_id")) |> mutate(across(starts_with("g_"), ~ replace_na(.x, 0)))
      for (r in names(PTS)) b[[paste0("lg_", r)]] <- lg[[r]]
      rows[[length(rows) + 1]] <- b |> select(season, week, game_id, posteam, kicker_player_id, kicker_player_name, top16pre,
                                              actual_points, starts_with("lambda_"), p_039, p_4049, p_50, p_xp,
                                              matches("^h(12|24|48|inf)_"), starts_with("g_"), starts_with("lg_"))
    }
    message("Season ", S, " done: ", sum(sapply(rows, nrow)), " kicker-games so far")
    rm(pbp, logs); gc()
  }
  saveRDS(bind_rows(rows), CACHE)
}
d <- readRDS(CACHE)
d$top16pre <- coalesce(d$top16pre, FALSE)
message(nrow(d), " kicker-games, ", n_distinct(paste(d$season, d$week)), " weeks, ", sum(d$top16pre), " pre-game top 16")

# Check: fade 12, weight 5 reproduces 09's make chances exactly
for (r in names(PTS)) {
  p5 <- with(d, (d[[paste0("h12_mk_", r)]] + 5 * d[[paste0("lg_", r)]]) / (d[[paste0("h12_att_", r)]] + 5))
  stopifnot(max(abs(p5 - d[[paste0("p_", r)]])) < 1e-9)
}
message("Check passed: fade 12 / weight 5 reproduces 09's make chances")

# --- Settings ----------------------------------------------------------------------------------
cfg_C <- expand.grid(fade = FTAG, w_pos = c(2, 5, 10, 20, 35, 50, 100, 200, Inf), stringsAsFactors = FALSE) |>
  mutate(w_neg = w_pos, delta = 0, test = "C")
cfg_D <- expand.grid(fade = FTAG, w_pos = c(2, 5, 10, 20, 35, 50), w_neg = c(5, 20, 50, 100, Inf), delta = c(0, 1, 2, 3),
                     stringsAsFactors = FALSE) |> mutate(test = "D")
cfgs <- bind_rows(cfg_C, cfg_D) |> distinct(fade, w_pos, w_neg, delta, .keep_all = TRUE) |>
  mutate(id = sprintf("f%s_wp%s_wn%s_d%s", fade, w_pos, w_neg, delta))
# Test D's pool includes the symmetric settings it overlaps with (same values), flagged C above
cfgs$in_D <- cfgs$w_pos %in% c(2, 5, 10, 20, 35, 50) & cfgs$w_neg %in% c(5, 20, 50, 100, Inf)
cfgs$in_C <- cfgs$w_pos == cfgs$w_neg & cfgs$delta == 0
CURRENT <- "f12_wp5_wn5_d0"

make_p <- function(cf) {
  N <- rowSums(sapply(names(PTS), function(r) d[[paste0("h", cf$fade, "_att_", r)]]))
  dock <- cf$delta / 100 * NEW_S / (N + NEW_S)
  setNames(lapply(names(PTS), function(r) {
    m <- d[[paste0("h", cf$fade, "_mk_", r)]]; n <- d[[paste0("h", cf$fade, "_att_", r)]]; L <- d[[paste0("lg_", r)]]
    w <- ifelse(m > n * L, cf$w_pos, cf$w_neg)
    p <- ifelse(is.infinite(w), L, ifelse(n + w > 0, (m + w * L) / (n + w), L))
    pmin(pmax(p - dock, 0.01), 0.999)
  }), names(PTS))
}
proj_mean <- function(p) with(d, lambda_xp * p_xp + lambda_039 * (p[["039"]] * 4 - 1) + lambda_4049 * (p[["4049"]] * 5 - 1) +
                                lambda_50 * (p[["50"]] * 6 - 1))
wk_all <- paste(d$season, d$week)
pairs_by_week <- function(proj, act, wk) {
  sp <- split(seq_along(proj), wk)
  out <- t(vapply(sp, function(ix) {
    dp <- outer(proj[ix], proj[ix], "-"); da <- outer(act[ix], act[ix], "-"); u <- upper.tri(dp) & da != 0
    c(sum((sign(dp[u]) == sign(da[u])) + 0.5 * (dp[u] == 0)), sum(u))
  }, numeric(2)))
  colnames(out) <- c("conc", "pairs"); out
}
t16 <- which(d$top16pre)
WEEKS <- sort(unique(wk_all))
per_week <- list(); grid <- list()
for (i in seq_len(nrow(cfgs))) {
  cf <- cfgs[i, ]; p <- make_p(cf); pr <- proj_mean(p)
  a16 <- pairs_by_week(pr[t16], d$actual_points[t16], wk_all[t16])[WEEKS, ]
  aall <- pairs_by_week(pr, d$actual_points, wk_all)[WEEKS, ]
  a16[is.na(a16)] <- 0; aall[is.na(aall)] <- 0  # a week with no top-16 kicker-games contributes nothing
  br <- rowSums(sapply(names(PTS), function(r) d[[paste0("g_mk_", r)]] * (1 - p[[r]])^2 +
                         (d[[paste0("g_att_", r)]] - d[[paste0("g_mk_", r)]]) * p[[r]]^2))
  per_week[[cf$id]] <- list(c16 = a16[, 1], p16 = a16[, 2], call = aall[, 1], pall = aall[, 2])
  grid[[cf$id]] <- cf |> mutate(hit16 = sum(a16[, 1]) / sum(a16[, 2]), hit_all = sum(aall[, 1]) / sum(aall[, 2]),
                                brier_x1000 = 1000 * sum(br) / sum(d$g_att_039 + d$g_att_4049 + d$g_att_50),
                                sd_proj16 = sd(pr[t16]))
}
grid <- bind_rows(grid)
wk_season <- as.integer(substr(WEEKS, 1, 4))

# --- Leave-one-season-out selection and tests ----------------------------------------------------
season_hit16 <- function(id, s) { pw <- per_week[[id]]; ix <- wk_season %in% s; sum(pw$c16[ix]) / sum(pw$p16[ix]) }
loso_pick <- function(ids) sapply(SEASONS, function(h) { tr <- setdiff(SEASONS, h); ids[which.max(sapply(ids, season_hit16, s = tr))] })
heldout <- function(picks) {  # per-week vectors, each week taken from the setting picked without its season
  out <- list(c16 = numeric(length(WEEKS)), p16 = numeric(length(WEEKS)), call = numeric(length(WEEKS)), pall = numeric(length(WEEKS)))
  for (j in seq_along(SEASONS)) { ix <- wk_season == SEASONS[j]; pw <- per_week[[picks[j]]]
    for (k in names(out)) out[[k]][ix] <- pw[[k]][ix] }
  out
}
compare <- function(new, base, label) {
  d16 <- new$c16 - base$c16; dall <- new$call - base$call
  B <- 2000; b16 <- numeric(B); ball <- numeric(B)
  for (b in seq_len(B)) { ix <- sample(length(WEEKS), replace = TRUE)
    b16[b] <- sum(d16[ix]) / sum(base$p16[ix]); ball[b] <- sum(dall[ix]) / sum(base$pall[ix]) }
  seas <- sapply(SEASONS, function(s) { ix <- wk_season == s; sum(d16[ix]) / sum(base$p16[ix]) })
  tibble(test = label, hit16_new = sum(new$c16) / sum(new$p16), hit16_base = sum(base$c16) / sum(base$p16),
         diff16 = sum(d16) / sum(base$p16), boot16_lo = quantile(b16, 0.05), boot16_hi = quantile(b16, 0.95),
         share_not_better = mean(b16 <= 0), seasons_better = sum(seas > 0),
         diff_all = sum(dall) / sum(base$pall), share_all_worse = mean(ball < 0),
         pass = share_not_better <= 0.05 & seasons_better >= 7 & share_all_worse < 0.95)
}
ids_C <- cfgs$id[cfgs$in_C]; ids_D <- cfgs$id[cfgs$in_D]
pick_C <- loso_pick(ids_C); resC <- compare(heldout(pick_C), per_week[[CURRENT]], "C: fade x weight (LOSO) vs current (12, 5)")
base_D <- if (resC$pass) heldout(pick_C) else per_week[[CURRENT]]
pick_D <- loso_pick(ids_D); resD <- compare(heldout(pick_D), base_D, paste0("D: two-sided + new-kicker start (LOSO) vs ", if (resC$pass) "Test C winner" else "current"))
# Reported, not deciding
ids_keep23 <- cfgs$id[cfgs$in_D & cfgs$w_pos <= 5]; pick_keep <- loso_pick(ids_keep23)
ids_nodock <- cfgs$id[cfgs$in_D & cfgs$delta == 0]; pick_nod <- loso_pick(ids_nodock)
res_extra <- bind_rows(compare(heldout(pick_keep), per_week[[CURRENT]], "Info: good kickers keep >= 2/3 (LOSO) vs current"),
                       compare(heldout(pick_nod), per_week[[CURRENT]], "Info: no new-kicker dock (LOSO) vs current"),
                       compare(heldout(pick_D), heldout(pick_keep), "Info: Test D pick vs keep->=2/3 pick"))

picks <- tibble(season = SEASONS, C = pick_C, D = pick_D, keep_2_3 = pick_keep, no_dock = pick_nod)
tests <- bind_rows(resC, resD, res_extra)
write_csv(grid |> mutate(across(where(is.double), ~ round(.x, 5))), "data/fade_prior_grid.csv")
write_csv(tests |> mutate(across(where(is.double), ~ round(.x, 5))), "data/fade_prior_tests.csv")
write_csv(picks, "data/fade_prior_loso_picks.csv")
print(as.data.frame(tests |> mutate(across(where(is.double), ~ round(.x, 4)))))
print(as.data.frame(picks))
cat("\nTest C grid (top-16 hit rate by fade x weight):\n")
print(grid |> filter(in_C) |> select(fade, w_pos, hit16) |> mutate(hit16 = round(hit16, 4)) |>
        pivot_wider(names_from = fade, values_from = hit16) |> as.data.frame())
cat("\nBrier x1000 by fade x weight:\n")
print(grid |> filter(in_C) |> select(fade, w_pos, brier_x1000) |> mutate(brier_x1000 = round(brier_x1000, 2)) |>
        pivot_wider(names_from = fade, values_from = brier_x1000) |> as.data.frame())
cat("\nTop 15 settings overall by top-16 hit rate (full sample, for reading only):\n")
print(grid |> arrange(desc(hit16)) |> head(15) |> select(id, hit16, hit_all, brier_x1000) |> mutate(across(where(is.double), ~ round(.x, 4))) |> as.data.frame())
cat("\nCurrent:\n"); print(grid |> filter(id == CURRENT) |> select(id, hit16, hit_all, brier_x1000) |> as.data.frame())
