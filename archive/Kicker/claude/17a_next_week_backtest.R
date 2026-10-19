# Backtest for to-do #17 (project next week too): how much worse is a projection made one week early?
# Added 2026-09-29. Run by hand; not part of the weekly run. Needs run_all.R's outputs
# (data/volume_model_table.csv, models/).
#
# RULES (set 2026-09-29 before any result was seen; sent to the user the same day):
#   For every week W = 2..18 of the 2023-2025 regular season, two projections of the same games:
#     same-week : inputs from games before W (what the Tuesday/Friday run of week W knows);
#     early     : inputs from games before W-1 (what a Tuesday run projecting "next week" knows).
#   Week 1 is left out: a week before week 1 is the offseason, so early and same-week coincide.
#   Both use the pre-game kicker rule (whoever last kicked for the team) and nflverse's final lines
#   (early lines aren't archived), so this measures the cost of stale kicker/team inputs, NOT of
#   stale lines. Volume models are refit leave-one-season-out on pre-game top-16 team-games, with
#   gamma per fold, as in 08a.
#   Scored against the team's actual kicking fantasy points (06b's fpts) on team-games where both
#   projections named the kicker who actually kicked (06b's kicker); wrong-kicker games are counted
#   separately.
#   Ship the next-week file only if ALL hold:
#     1. early projection's mean squared error < early points-per-game baseline's (kicker_ppg_pre as
#        of the early cut; league average if he has none), all kickers, in >= 2 of 3 seasons;
#     2. early projection's pairwise hit rate > early points-per-game's, all kickers, in >= 2 of 3
#        seasons;
#     3. 09a stays exact and 08a passes 4 of 4 (checked separately).
#   Pairwise hit rate: over every pair of kickers in the same week whose actual points differ, the
#   share where the higher projection scored more (a tied projection counts 1/2).
#   Reported, not pass/fail: early vs same-week (squared-error ratio, hit-rate gap) for all kickers
#   and for the same-week pre-game top 16; wrong-kicker rates.

suppressMessages({library(dplyr); library(readr)})
source("00_nflverse_data.R")
source("08_points_distribution.R")
source("09_weekly_inputs.R")
set.seed(20260929)

SEASONS <- 2023:2025
WEEKS <- 2:18
MODEL_NAMES <- c("xp_attempts", "att_039", "att_4049", "att_50")
pbp_all <- load_pbp_data(SEASONS) |> mutate(ord = season * 100 + week)
sched_all <- load_schedule_data(SEASONS) |> mutate(ord = season * 100 + week)
vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE)
formulas <- lapply(setNames(MODEL_NAMES, MODEL_NAMES), function(o)
  formula(readRDS(file.path("models", paste0("volume_", o, "_model.rds")))))
reg_ords <- sort(unique(sched_all$ord[sched_all$game_type == "REG"]))

# Data as known before `cut_ord`: play-by-play before it, results blanked from it on
cut_data <- function(cut_ord) list(
  pbp = pbp_all |> filter(ord < cut_ord) |> select(-ord),
  sched = sched_all |> mutate(result = if_else(ord >= cut_ord, NA_real_, result),
                              home_score = if_else(ord >= cut_ord, NA_real_, home_score),
                              away_score = if_else(ord >= cut_ord, NA_real_, away_score)) |> select(-ord))

# Fits per held-out season (leave-one-season-out, as 08a)
train_all <- vol |> filter(top16pre)
folds <- lapply(setNames(SEASONS, SEASONS), function(s) {
  tr <- train_all[train_all$season != s, ]
  fits <- lapply(formulas, function(f) glm(f, family = poisson, data = tr))
  list(fits = fits, gamma = estimate_gamma(fits, tr))
})

rows <- list()
for (s in SEASONS) for (w in WEEKS) {
  tord <- s * 100 + w
  prev_ord <- max(reg_ords[reg_ords < tord])
  f <- folds[[as.character(s)]]
  for (kind in c("same_week", "early")) {
    d <- cut_data(if (kind == "same_week") tord else prev_ord)
    res <- tryCatch(suppressWarnings(project_week(d$pbp, d$sched, s, w, f$fits, f$gamma, "backtest (final lines)",
                                                  last_played_week = NA, N_DRAWS = 20)), error = function(e) NULL)
    if (is.null(res)) { message("skip ", s, " wk", w, " ", kind); next }
    rows[[length(rows) + 1]] <- res$out |>
      transmute(kind, season, week, game_id, team, kicker_player_id, projected_points, kicker_ppg_pre, league_ppg, top16pre)
  }
  message("Done ", s, " week ", w)
}
proj <- bind_rows(rows)

wide <- proj |> filter(kind == "same_week") |> select(-kind) |>
  rename_with(~ paste0(.x, "_same"), c(kicker_player_id, projected_points, kicker_ppg_pre, league_ppg, top16pre)) |>
  inner_join(proj |> filter(kind == "early") |> select(-kind) |>
               rename_with(~ paste0(.x, "_early"), c(kicker_player_id, projected_points, kicker_ppg_pre, league_ppg, top16pre)),
             by = c("season", "week", "game_id", "team")) |>
  inner_join(vol |> select(game_id, team = posteam, actual_kicker = kicker_player_id, fpts), by = c("game_id", "team")) |>
  mutate(right_same = kicker_player_id_same == actual_kicker, right_early = kicker_player_id_early == actual_kicker,
         ppg_early = coalesce(kicker_ppg_pre_early, league_ppg_early),
         ppg_same = coalesce(kicker_ppg_pre_same, league_ppg_same))
write_csv(wide |> mutate(across(where(is.double), ~ round(.x, 4))), "data/next_week_backtest_games.csv")

pair_hit <- function(pred, actual, grp) {
  num <- 0; den <- 0
  for (g in unique(grp)) {
    i <- which(grp == g); if (length(i) < 2) next
    p <- pred[i]; a <- actual[i]
    dp <- outer(p, p, "-"); da <- outer(a, a, "-"); keep <- upper.tri(da) & da != 0
    num <- num + sum(ifelse(dp[keep] == 0, 0.5, sign(dp[keep]) == sign(da[keep])))
    den <- den + sum(keep)
  }
  num / den
}
score <- function(d, label) {
  grp <- paste(d$season, d$week)
  tibble(set = label, team_games = nrow(d),
         mse_early = mean((d$fpts - d$projected_points_early)^2), mse_same = mean((d$fpts - d$projected_points_same)^2),
         mse_ppg_early = mean((d$fpts - d$ppg_early)^2), mse_ppg_same = mean((d$fpts - d$ppg_same)^2),
         mse_league = mean((d$fpts - d$league_ppg_early)^2),
         hit_early = pair_hit(d$projected_points_early, d$fpts, grp), hit_same = pair_hit(d$projected_points_same, d$fpts, grp),
         hit_ppg_early = pair_hit(d$ppg_early, d$fpts, grp), hit_ppg_same = pair_hit(d$ppg_same, d$fpts, grp),
         bias_early = mean(d$projected_points_early) - mean(d$fpts))
}
scored <- wide |> filter(right_same, right_early)
# Fix of 2026-09-29, made after the first run printed NaN for 2023's baseline (so both rules showed
# "NA of 3"): early 2023 weeks
# have no earlier games in the window, so the points-per-game baseline and league average are
# undefined (NaN) there. Scored games must have every compared number; this drops the same rows
# for every method.
n_before <- nrow(scored)
scored <- scored |> filter(is.finite(ppg_early), is.finite(ppg_same), is.finite(league_ppg_early))
message("Scored team-games: ", nrow(scored), " (", n_before - nrow(scored), " dropped for an undefined baseline)")
summary_tbl <- bind_rows(
  bind_rows(lapply(SEASONS, function(s) score(scored[scored$season == s, ], "all kickers") |> mutate(season = as.character(s)))),
  score(scored, "all kickers") |> mutate(season = "all"),
  bind_rows(lapply(SEASONS, function(s) score(scored[scored$season == s & scored$top16pre_same, ], "same-week top 16") |>
                     mutate(season = as.character(s)))),
  score(scored[scored$top16pre_same, ], "same-week top 16") |> mutate(season = "all")) |>
  relocate(season, .after = set) |>
  mutate(mse_ratio_early_vs_same = mse_early / mse_same, hit_gap_early_minus_same = hit_early - hit_same)

by_s <- summary_tbl |> filter(set == "all kickers", season != "all")
rules <- tibble(
  rule = c("1 early projection's squared error beats early points per game (all kickers, seasons)",
           "2 early projection's pairwise hit rate beats early points per game (all kickers, seasons)"),
  result = c(paste(sum(by_s$mse_early < by_s$mse_ppg_early), "of 3"), paste(sum(by_s$hit_early > by_s$hit_ppg_early), "of 3")),
  passes = c(sum(by_s$mse_early < by_s$mse_ppg_early) >= 2, sum(by_s$hit_early > by_s$hit_ppg_early) >= 2))
kicker_check <- tibble(team_games_both = nrow(wide), wrong_kicker_same = sum(!wide$right_same),
                       wrong_kicker_early = sum(!wide$right_early),
                       wrong_early_only = sum(wide$right_same & !wide$right_early))

write_csv(summary_tbl |> mutate(across(where(is.double), ~ round(.x, 4))), "data/next_week_backtest_summary.csv")
write_csv(rules, "data/next_week_backtest_rules.csv")
write_csv(kicker_check, "data/next_week_backtest_kicker_check.csv")
print(as.data.frame(rules)); print(as.data.frame(kicker_check))
print(as.data.frame(summary_tbl |> mutate(across(where(is.double), ~ round(.x, 4)))))
