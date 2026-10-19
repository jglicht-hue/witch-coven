# Experiment: FG accuracy shrinkage weight (w) and blocked kicks. Added 2026-09-28.
# Not part of the weekly run. Log: claude/14_fg_shrinkage_log.md.
#
# QUESTION. Script 05 / 09 blend each kicker's decayed FG record with the league
# rate: p_r = (decayed makes + w * league_r) / (decayed attempts + w), w = 5, a
# design-phase value never tested. Does another w pick better kickers week to
# week? Second question: should blocked FGs be left out of the kicker's record
# (they still score -1)?
#
# RULES (set with the user 2026-09-28, before any results were seen). The user's
# priority: identify good kicker games more than predict the average.
#   Sample: every kicker-game (all teams), 2019-2025 regular season. Inputs are
#     built by build_week_inputs() (09) with 06b's kicker rule (the kicker who
#     kicked; else the team's last primary FG kicker), using the 4-season window
#     a live run would use (season-3 .. season). Volume models (07) unchanged -
#     their kicker-accuracy features stay at w = 5; only the make chances move.
#   Primary metric - pairwise hit rate: over all pairs of kickers in the same
#     week whose actual points differ, the share where the higher projection
#     scored more (a tie in projection counts 1/2). Pooled over pairs.
#   Secondary (reported, not decisive): top-12 capture (average actual points
#     of each week's 12 highest projections), MSE of projected points, Brier
#     score of the FG make chances on the game's actual attempts.
#   Grid: w = 0, 1, 2, 5, 10, 20, 35, 50, 75, 100, 150, 200, 300, 500, Inf.
#   Test A (w): w picked leave-one-season-out (best pooled hit rate on the other
#     six seasons), scored on the held-out season. Adopt only if (1) the
#     held-out hit rate beats w = 5 in >= 95% of 2,000 week-block bootstrap
#     resamples and (2) it's better in >= 5 of 7 held-out seasons. Otherwise
#     w = 5 stays. If ranking can't separate but Brier clearly prefers
#     something, that goes to the user as a decision, not adopted.
#   Test B (blocks): same rules; blocked FGs dropped from the accuracy record
#     (w picked leave-one-season-out within that variant) vs Test A's winner.

suppressMessages({library(dplyr); library(tidyr); library(readr)})
source("00_nflverse_data.R")
source("08_points_distribution.R")
source("09_weekly_inputs.R")
set.seed(20260928)

SEASONS <- if (exists("SEASONS_OVERRIDE")) SEASONS_OVERRIDE else 2019:2025
W_GRID <- c(0, 1, 2, 5, 10, 20, 35, 50, 75, 100, 150, 200, 300, 500, Inf)
PTS <- c("039" = 3, "4049" = 4, "50" = 5)
CACHE <- if (exists("CACHE_OVERRIDE")) CACHE_OVERRIDE else "data/fg_shrink_inputs.rds"
MODEL_NAMES <- c("xp_attempts", "att_039", "att_4049", "att_50")
fits <- setNames(lapply(file.path("models", paste0("volume_", MODEL_NAMES, "_model.rds")), readRDS), MODEL_NAMES)
points_gamma <- read_csv("models/points_gamma.csv", show_col_types = FALSE)$gamma

# --- Stage 1: inputs for every kicker-game (cached) ------------------------------------
if (!file.exists(CACHE)) {
  rows <- list()
  for (S in SEASONS) {
    pbp <- load_pbp_data((S - 3):S); sched <- load_schedule_data((S - 3):S)
    # Kicker FG log with and without blocked kicks (same game rows, so decay timing is identical)
    kp <- pbp |> filter(field_goal_attempt == 1, !is.na(kicker_player_id)) |>
      mutate(made = as.integer(field_goal_result == "made"), blocked = field_goal_result == "blocked",
             r = case_when(kick_distance <= 39 ~ "039", kick_distance <= 49 ~ "4049", TRUE ~ "50"))
    kg <- kp |> group_by(season, week, game_id, posteam, kicker_player_id, r) |>
      summarise(att = n(), att_nb = sum(!blocked), mk = sum(made, na.rm = TRUE), .groups = "drop") |>
      pivot_wider(names_from = r, values_from = c(att, att_nb, mk), values_fill = 0) |>
      mutate(ord = season * 100 + week) |> arrange(kicker_player_id, ord)
    lg <- sapply(names(PTS), function(r) c(inc = sum(kg[[paste0("mk_", r)]]) / sum(kg[[paste0("att_", r)]]),
                                          nb = sum(kg[[paste0("mk_", r)]]) / sum(kg[[paste0("att_nb_", r)]])))
    dcols <- c(outer(c("att_", "att_nb_", "mk_"), names(PTS), paste0))
    acc_log <- kg |> group_by(kicker_player_id) |>
      mutate(across(all_of(dcols), ~ .running_after(.x, WK_HALF_LIFE), .names = "d_{.col}")) |> ungroup()
    weeks <- sort(unique(sched$week[sched$season == S & sched$game_type == "REG"]))
    for (wk in weeks) {
      b <- build_week_inputs(pbp, sched, S, wk)  # 06b kicker rule (the kicker who kicked)
      b <- b |> filter(!is.na(kicker_player_id), !is.na(actual_points))
      for (o in MODEL_NAMES) b[[paste0("lambda_", sub("att_|_attempts", "", o))]] <- predict(fits[[o]], b, type = "response")
      st <- .state_before(acc_log, b$kicker_player_id, b$ord, paste0("d_", dcols))
      colnames(st) <- sub("^d_", "h_", colnames(st))
      # This game's attempts by the projected kicker (for the Brier score)
      this <- kg |> filter(season == S, week == wk) |> select(game_id, posteam, kicker_player_id, all_of(dcols))
      names(this)[-(1:3)] <- paste0("g_", names(this)[-(1:3)])
      b <- bind_cols(b, as_tibble(st)) |> left_join(this, by = c("game_id", "posteam", "kicker_player_id")) |>
        mutate(across(starts_with("g_"), ~ replace_na(.x, 0)))
      for (r in names(PTS)) { b[[paste0("lg_inc_", r)]] <- lg["inc", r]; b[[paste0("lg_nb_", r)]] <- lg["nb", r] }
      rows[[length(rows) + 1]] <- b |> select(season, week, game_id, posteam, kicker_player_id, kicker_player_name,
                                              top16pre, kicker_ppg_pre, actual_points, starts_with("lambda_"),
                                              p_039, p_4049, p_50, p_xp, starts_with("h_"), starts_with("g_"), starts_with("lg_"))
    }
    message("Season ", S, " done: ", sum(sapply(rows, nrow)), " kicker-games so far")
    rm(pbp); gc()
  }
  saveRDS(bind_rows(rows), CACHE)
}
d <- readRDS(CACHE)
message(nrow(d), " kicker-games, ", n_distinct(paste(d$season, d$week)), " weeks")

# --- Checks: replication and the analytic mean ---------------------------------------
rate <- function(m, n, L, w) if (is.infinite(w)) L else ifelse(n + w > 0, (m + w * L) / (n + w), L)
for (r in names(PTS)) {
  rep5 <- rate(d[[paste0("h_mk_", r)]], d[[paste0("h_att_", r)]], d[[paste0("lg_inc_", r)]], 5)
  stopifnot(max(abs(rep5 - d[[paste0("p_", r)]])) < 1e-9)
}
proj_mean <- function(d, p) with(d, lambda_xp * p_xp +
  lambda_039 * (p[["039"]] * 4 - 1) + lambda_4049 * (p[["4049"]] * 5 - 1) + lambda_50 * (p[["50"]] * 6 - 1))
chk <- sample(nrow(d), 25)
full <- sapply(chk, function(i) with(d[i, ], sum(points_pmf_dep(lambda_xp, lambda_039, lambda_4049, lambda_50,
                                                                p_039, p_4049, p_50, p_xp, gamma = points_gamma) |>
                                                   with(points * prob))))
stopifnot(max(abs(full - proj_mean(d[chk, ], list("039" = d$p_039[chk], "4049" = d$p_4049[chk], "50" = d$p_50[chk])))) < 1e-4)
message("Checks passed: rates at w = 5 reproduce 09 exactly; analytic mean matches the full distribution")

# --- Metrics --------------------------------------------------------------------------
wk_id <- paste(d$season, d$week)
pair_counts <- function(proj, act, wk) {  # per week: concordant (ties 1/2) and usable pairs
  sp <- split(seq_along(proj), wk)
  t(sapply(sp, function(ix) {
    dp <- outer(proj[ix], proj[ix], "-"); da <- outer(act[ix], act[ix], "-")
    u <- upper.tri(dp) & da != 0
    c(conc = sum((sign(dp[u]) == sign(da[u])) + 0.5 * (dp[u] == 0)), pairs = sum(u))
  }))
}
top12 <- function(proj, act, wk) sapply(split(seq_along(proj), wk), function(ix) mean(act[ix][order(-proj[ix])][1:min(12, length(ix))]))

variant_rates <- function(w, blocks) {
  v <- if (blocks == "included") "" else "nb_"
  setNames(lapply(names(PTS), function(r) rate(d[[paste0("h_mk_", r)]], d[[paste0("h_att_", v, r)]],
                                             d[[paste0("lg_", if (v == "") "inc" else "nb", "_", r)]], w)), names(PTS))
}
per_week <- list(); summary_rows <- list()
for (blocks in c("included", "excluded")) for (w in W_GRID) {
  p <- variant_rates(w, blocks); pr <- proj_mean(d, p)
  pc <- pair_counts(pr, d$actual_points, wk_id)
  br <- rowSums(sapply(names(PTS), function(r) d[[paste0("g_mk_", r)]] * (1 - p[[r]])^2 +
                         (d[[paste0("g_att_", r)]] - d[[paste0("g_mk_", r)]]) * p[[r]]^2))
  key <- paste(blocks, w)
  per_week[[key]] <- tibble(wk = rownames(pc), season = as.integer(substr(rownames(pc), 1, 4)),
                            conc = pc[, "conc"], pairs = pc[, "pairs"], top12 = top12(pr, d$actual_points, wk_id))
  summary_rows[[key]] <- tibble(blocks, w, hit_rate = sum(pc[, 1]) / sum(pc[, 2]),
                                top12_capture = mean(per_week[[key]]$top12),
                                mse = mean((d$actual_points - pr)^2),
                                brier_x1000 = 1000 * sum(br) / sum(d$g_att_039 + d$g_att_4049 + d$g_att_50),
                                sd_proj = sd(pr))
}
grid <- bind_rows(summary_rows)
by_season <- bind_rows(lapply(names(per_week), function(k) per_week[[k]] |> group_by(season) |>
  summarise(conc = sum(conc), pairs = sum(pairs), .groups = "drop") |>
  mutate(blocks = sub(" .*", "", k), w = as.numeric(sub(".* ", "", k)))))

# Baselines for context: points per game going into the week, and a coin flip (0.5)
pc_ppg <- pair_counts(coalesce(d$kicker_ppg_pre, mean(d$actual_points)), d$actual_points, wk_id)
ppg_hit <- sum(pc_ppg[, 1]) / sum(pc_ppg[, 2])

# --- Leave-one-season-out selection and the bootstrap -------------------------------
loso <- function(blocks) {
  bind_rows(lapply(SEASONS, function(h) {
    tr <- by_season |> filter(blocks == !!blocks, season != h) |> group_by(w) |>
      summarise(hr = sum(conc) / sum(pairs), .groups = "drop")
    tibble(season = h, w_chosen = tr$w[which.max(tr$hr)])
  }))
}
heldout_weeks <- function(sel, blocks) bind_rows(lapply(seq_len(nrow(sel)), function(i)
  per_week[[paste(blocks, sel$w_chosen[i])]] |> filter(season == sel$season[i])))
test <- function(new_wk, base_wk, label) {
  stopifnot(identical(new_wk$wk, base_wk$wk))
  diff_c <- new_wk$conc - base_wk$conc; pairs <- base_wk$pairs
  boot <- replicate(2000, { ix <- sample(length(pairs), replace = TRUE); sum(diff_c[ix]) / sum(pairs[ix]) })
  seas <- tibble(season = new_wk$season, dc = diff_c, pairs) |> group_by(season) |>
    summarise(diff = sum(dc) / sum(pairs), .groups = "drop")
  tibble(test = label, hit_new = sum(new_wk$conc) / sum(pairs), hit_base = sum(base_wk$conc) / sum(pairs),
         diff = sum(diff_c) / sum(pairs), boot_share_not_better = mean(boot <= 0),
         boot_lo = quantile(boot, 0.05), boot_hi = quantile(boot, 0.95),
         seasons_better = sum(seas$diff > 0), top12_new = mean(new_wk$top12), top12_base = mean(base_wk$top12),
         pass = boot_share_not_better <= 0.05 & seasons_better >= 5)
}
selA <- loso("included")
base5 <- per_week[["included 5"]] |> arrange(wk)
resA <- test(heldout_weeks(selA, "included") |> arrange(wk), base5, "A: w chosen leave-one-season-out vs w = 5")
winnerA <- if (resA$pass) heldout_weeks(selA, "included") |> arrange(wk) else base5
selB <- loso("excluded")
resB <- test(heldout_weeks(selB, "excluded") |> arrange(wk), winnerA, "B: blocks excluded (w chosen LOSO) vs Test A winner")
# Also, fixed-w comparisons against w = 5 for reading the curve (not decisive)
fixed <- bind_rows(lapply(W_GRID[W_GRID != 5], function(w) test(per_week[[paste("included", w)]] |> arrange(wk), base5,
                                                              paste0("w = ", w, " vs 5 (fixed, not decisive)"))))

dir.create("data", showWarnings = FALSE)
write_csv(grid |> mutate(across(where(is.double), ~ round(.x, 5))), "data/fg_shrink_grid.csv")
write_csv(bind_rows(resA, resB, fixed) |> mutate(across(where(is.double), ~ round(.x, 5))), "data/fg_shrink_tests.csv")
write_csv(bind_rows(selA |> mutate(blocks = "included"), selB |> mutate(blocks = "excluded")), "data/fg_shrink_loso_choices.csv")
write_csv(by_season |> mutate(hit_rate = round(conc / pairs, 5)), "data/fg_shrink_by_season.csv")
message("Points-per-game baseline hit rate: ", round(ppg_hit, 4))
print(as.data.frame(grid |> mutate(across(where(is.double), ~ round(.x, 4)))))
print(as.data.frame(bind_rows(resA, resB) |> mutate(across(where(is.double), ~ round(.x, 4)))))
print(selA); print(selB)
print(as.data.frame(fixed |> select(test, diff, boot_share_not_better, seasons_better) |> mutate(across(where(is.double), ~ round(.x, 4)))))
