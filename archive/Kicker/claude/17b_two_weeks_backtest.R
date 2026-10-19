# Backtest for to-do #17b: can the model project TWO weeks out (and next week without lines)?
# Added 2026-09-29. Run by hand; not part of the weekly run. Needs run_all.R's outputs.
#
# WHY NO LINES: on 2026-09-29 nflverse had lines for weeks 4-5 but none for week 6 (0 of 14 games),
# so a live two-weeks-out projection gets the league-average implied team total. The backtest does
# the same: the target week's spread/total are blanked, so 09's rule fills the league average.
#
# RULES (set 2026-09-29 before any result; approved by the user "Proceed"):
#   Weeks W = 4..18 of the 2023-2025 regular season (W >= 4 so every variant is cut in-season: a
#   Tuesday run after week 1 is the earliest that projects week 4). For each game, four projections:
#     same_week        : games before W, final lines        (the main file)
#     early1           : games before W-1, final lines      (next-week file, lines posted; 17a)
#     early1_nolines   : games before W-1, no lines         (next-week file if lines are late)
#     early2_nolines   : games before W-2, no lines         (the proposed two-weeks-out file)
#   Volume models refit leave-one-season-out on pre-game top-16 team-games, gamma per fold (as 08a).
#   Scored on team-games where every variant named the kicker who actually kicked and every
#   baseline is defined; wrong-kicker games counted separately.
#   PASS (two-weeks-out file ships) only if, all kickers, early2_nolines beats the kicker's points
#   per game as of the same W-2 cut in >= 2 of 3 seasons on BOTH (1) squared error and (2) pairwise
#   hit rate (pairs in the same week with different actual points; tied projection = 1/2).
#   Reported, not pass/fail: every variant vs same_week; early1_nolines vs its PPG baseline;
#   wrong-kicker rates; results for the same-week pre-game top 16.

suppressMessages({library(dplyr); library(readr)})
source("00_nflverse_data.R")
source("08_points_distribution.R")
source("09_weekly_inputs.R")
set.seed(20260929)

SEASONS <- 2023:2025
WEEKS <- 4:18
MODEL_NAMES <- c("xp_attempts", "att_039", "att_4049", "att_50")
pbp_all <- load_pbp_data(SEASONS) |> mutate(ord = season * 100 + week)
sched_all <- load_schedule_data(SEASONS) |> mutate(ord = season * 100 + week)
vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE)
formulas <- lapply(setNames(MODEL_NAMES, MODEL_NAMES), function(o)
  formula(readRDS(file.path("models", paste0("volume_", o, "_model.rds")))))
reg_ords <- sort(unique(sched_all$ord[sched_all$game_type == "REG"]))

cut_data <- function(cut_ord, blank_lines_ord = NULL) {
  s <- sched_all |> mutate(result = if_else(ord >= cut_ord, NA_real_, result),
                           home_score = if_else(ord >= cut_ord, NA_real_, home_score),
                           away_score = if_else(ord >= cut_ord, NA_real_, away_score))
  if (!is.null(blank_lines_ord)) s <- s |> mutate(spread_line = if_else(ord == blank_lines_ord, NA_real_, spread_line),
                                                  total_line = if_else(ord == blank_lines_ord, NA_real_, total_line))
  list(pbp = pbp_all |> filter(ord < cut_ord) |> select(-ord), sched = s |> select(-ord))
}

train_all <- vol |> filter(top16pre)
folds <- lapply(setNames(SEASONS, SEASONS), function(s) {
  tr <- train_all[train_all$season != s, ]
  fits <- lapply(formulas, function(f) glm(f, family = poisson, data = tr))
  list(fits = fits, gamma = estimate_gamma(fits, tr))
})

VARIANTS <- list(same_week = list(back = 0, lines = TRUE), early1 = list(back = 1, lines = TRUE),
                 early1_nolines = list(back = 1, lines = FALSE), early2_nolines = list(back = 2, lines = FALSE))
rows <- list()
for (s in SEASONS) for (w in WEEKS) {
  tord <- s * 100 + w
  f <- folds[[as.character(s)]]
  for (v in names(VARIANTS)) {
    back <- VARIANTS[[v]]$back
    cut_ord <- if (back == 0) tord else rev(reg_ords[reg_ords < tord])[back]
    d <- cut_data(cut_ord, if (VARIANTS[[v]]$lines) NULL else tord)
    res <- tryCatch(suppressWarnings(project_week(d$pbp, d$sched, s, w, f$fits, f$gamma, "backtest",
                                                  last_played_week = NA, N_DRAWS = 20)), error = function(e) NULL)
    if (is.null(res)) { message("skip ", s, " wk", w, " ", v); next }
    rows[[length(rows) + 1]] <- res$out |>
      transmute(variant = v, season, week, game_id, team, kicker_player_id, projected_points,
                ppg = coalesce(kicker_ppg_pre, league_ppg), league_ppg, top16pre)
  }
  message("Done ", s, " week ", w)
}
proj <- bind_rows(rows)
write_csv(proj |> mutate(across(where(is.double), ~ round(.x, 4))), "data/two_weeks_backtest_projections.csv")

actual <- vol |> select(game_id, team = posteam, actual_kicker = kicker_player_id, fpts)
keys <- proj |> left_join(actual, by = c("game_id", "team")) |>
  group_by(season, week, game_id, team) |>
  summarise(n_var = n_distinct(variant), all_right = all(kicker_player_id == actual_kicker),
            all_finite = all(is.finite(ppg)) & all(is.finite(league_ppg)),
            top16_same = any(top16pre & variant == "same_week"), .groups = "drop")
kicker_check <- proj |> left_join(actual, by = c("game_id", "team")) |> filter(!is.na(fpts)) |>
  group_by(variant) |> summarise(team_games = n(), wrong_kicker = sum(kicker_player_id != actual_kicker),
                                 wrong_pct = round(100 * mean(kicker_player_id != actual_kicker), 1), .groups = "drop")
scored <- proj |> inner_join(keys |> filter(n_var == length(VARIANTS), all_right, all_finite),
                             by = c("season", "week", "game_id", "team")) |>
  left_join(actual |> select(game_id, team, fpts), by = c("game_id", "team"))
message("Scored team-games: ", n_distinct(paste(scored$game_id, scored$team)))

pair_hit <- function(pred, actual, grp) {
  num <- 0; den <- 0
  for (g in unique(grp)) {
    i <- which(grp == g); if (length(i) < 2) next
    dp <- outer(pred[i], pred[i], "-"); da <- outer(actual[i], actual[i], "-"); keep <- upper.tri(da) & da != 0
    num <- num + sum(ifelse(dp[keep] == 0, 0.5, sign(dp[keep]) == sign(da[keep]))); den <- den + sum(keep)
  }
  num / den
}
score <- function(d) {
  grp <- paste(d$season, d$week)
  tibble(team_games = nrow(d), mse = mean((d$fpts - d$projected_points)^2), mse_ppg = mean((d$fpts - d$ppg)^2),
         mse_league = mean((d$fpts - d$league_ppg)^2), hit = pair_hit(d$projected_points, d$fpts, grp),
         hit_ppg = pair_hit(d$ppg, d$fpts, grp), bias = mean(d$projected_points) - mean(d$fpts))
}
summ <- bind_rows(lapply(c("all kickers", "same-week top 16"), function(set) {
  d0 <- if (set == "all kickers") scored else scored |> filter(top16_same)
  bind_rows(lapply(c(as.character(SEASONS), "all"), function(ss) {
    d1 <- if (ss == "all") d0 else d0 |> filter(season == as.integer(ss))
    d1 |> group_by(variant) |> group_modify(~ score(.x)) |> ungroup() |> mutate(set = set, season = ss)
  }))
})) |> relocate(set, season, variant)
same <- summ |> filter(variant == "same_week") |> select(set, season, mse_same = mse, hit_same = hit)
summ <- summ |> left_join(same, by = c("set", "season")) |>
  mutate(mse_ratio_vs_same = mse / mse_same, hit_gap_vs_same = hit - hit_same) |> select(-mse_same, -hit_same)

by_s <- summ |> filter(set == "all kickers", season != "all")
rule_rows <- function(v) {
  b <- by_s |> filter(variant == v)
  tibble(variant = v, mse_beats_ppg = paste(sum(b$mse < b$mse_ppg), "of 3"), hit_beats_ppg = paste(sum(b$hit > b$hit_ppg), "of 3"),
         passes = sum(b$mse < b$mse_ppg) >= 2 & sum(b$hit > b$hit_ppg) >= 2,
         role = if (v == "early2_nolines") "RULE (two-weeks-out ships?)" else "reported only")
}
rules <- bind_rows(lapply(c("early2_nolines", "early1_nolines", "early1"), rule_rows))

write_csv(summ |> mutate(across(where(is.double), ~ round(.x, 4))), "data/two_weeks_backtest_summary.csv")
write_csv(rules, "data/two_weeks_backtest_rules.csv")
write_csv(kicker_check, "data/two_weeks_backtest_kicker_check.csv")
print(as.data.frame(rules)); print(as.data.frame(kicker_check))
print(as.data.frame(summ |> mutate(across(where(is.double), ~ round(.x, 4)))), width = 200)
