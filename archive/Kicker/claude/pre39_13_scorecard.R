# Live scorecard: grades past weeks' projections against actual fantasy points.
# Added 2026-09-28. Run by the scheduled task after 09b (and by hand any time).
#
# Design (decided with the user 2026-09-28):
#   - Which projection is graded: for each team-game, the LATEST run made
#     before that game was played. In practice that's Friday's run, and
#     Tuesday's for Thursday games (played before Friday's run).
#   - Weeks 1-3 of 2026 were rebuilt afterwards (13a_backfill_history.R; final
#     lines, today's model) and are graded separately (source = "rebuilt").
#     Live grading starts with week 4.
#   - If the projected kicker didn't kick in the game (injury, cut, benched),
#     the game is left out of the accuracy numbers and counted as a "wrong
#     starter" instead. If the team attempted no kicks at all, the projected
#     kicker is graded with 0 points.
#   Scoring: 3/4/5 per made FG (0-39 / 40-49 / 50+ yards), -1 per missed FG
#   (blocked included), +1 per made XP - credited to the kicker who kicked.
#
# Reads data/projection_history.csv (09b, 13a) and nflverse play-by-play and
# schedules. Writes data/scorecard_games.csv (one row per graded kicker-game)
# and data/scorecard_summary.csv (per week and per source, plus all weeks).
#
# Columns in the summary:
#   graded / wrong_starter : kicker-games graded / left out because someone else kicked
#   mse_model / mse_ppg / mse_league : mean squared error of the projection, of
#     the kicker's points per game going into the week (league average for a
#     kicker with no history yet), and of the league average
#   bias : average projection minus average actual
#   range_hit / range_claimed : share of actual scores inside the middle-80%
#     range vs the probability the model said the range held
#   rank_corr : Spearman correlation between projected and actual points
#   top12_minus_rest : average actual points of the 12 highest projections
#     minus the average of the rest (is the ranking useful?)

suppressMessages({library(dplyr); library(readr)})
source("00_nflverse_data.R")

HISTORY_PATH <- "data/projection_history.csv"
if (!file.exists(HISTORY_PATH)) stop("No ", HISTORY_PATH, " yet - run 09b first.")
hist <- read_csv(HISTORY_PATH, show_col_types = FALSE, col_types = cols(run_date = col_character(), gameday = col_character()))
seasons <- sort(unique(hist$season))
pbp <- load_pbp_data(seasons)
sched <- load_schedule_data(seasons)
done <- sched |> filter(!is.na(result)) |> pull(game_id)

# Actual points by kicker
fg <- pbp |> filter(field_goal_attempt == 1, !is.na(kicker_player_id)) |>
  mutate(pts = ifelse(field_goal_result == "made", ifelse(kick_distance <= 39, 3, ifelse(kick_distance <= 49, 4, 5)), -1)) |>
  group_by(game_id, posteam, kicker_player_id) |> summarise(fg_pts = sum(pts), .groups = "drop")
xp <- pbp |> filter(extra_point_attempt == 1, !is.na(kicker_player_id)) |>
  group_by(game_id, posteam, kicker_player_id) |> summarise(xp_pts = sum(extra_point_result == "good", na.rm = TRUE), .groups = "drop")
kicked <- full_join(fg, xp, by = c("game_id", "posteam", "kicker_player_id")) |>
  mutate(actual = coalesce(fg_pts, 0) + coalesce(xp_pts, 0))
team_kicked <- kicked |> distinct(game_id, posteam) |> mutate(team_had_kicks = TRUE)

# The graded projection per team-game: latest run before the game; live preferred over rebuilt
graded_proj <- hist |> filter(game_id %in% done, !played_at_run) |>
  mutate(src_rank = ifelse(source == "live", 1, 2)) |>
  group_by(game_id, team) |> filter(src_rank == min(src_rank)) |>
  slice_max(run_date, n = 1, with_ties = FALSE) |> ungroup() |> select(-src_rank)

games <- graded_proj |>
  left_join(kicked |> select(game_id, team = posteam, kicker_player_id, actual), by = c("game_id", "team", "kicker_player_id")) |>
  left_join(team_kicked |> rename(team = posteam), by = c("game_id", "team")) |>
  mutate(team_had_kicks = coalesce(team_had_kicks, FALSE),
         wrong_starter = is.na(actual) & team_had_kicks,
         actual = ifelse(!team_had_kicks, 0, actual),
         in_range = actual >= outcome_low & actual <= outcome_high)
write_csv(games |> mutate(across(where(is.double), ~ round(.x, 4))), "data/scorecard_games.csv")

grade <- function(d) {
  g <- d |> filter(!wrong_starter)
  top <- (if ("week" %in% names(g)) group_by(g, week) else g) |>
    mutate(r = rank(-projected_points, ties.method = "first")) |> ungroup()  # rank within each week
  tibble(graded = nrow(g), wrong_starter = sum(d$wrong_starter),
         mse_model = mean((g$actual - g$projected_points)^2), mse_ppg = mean((g$actual - coalesce(g$kicker_ppg_pre, g$league_ppg))^2),
         mse_league = mean((g$actual - g$league_ppg)^2), bias = mean(g$projected_points) - mean(g$actual),
         range_hit = mean(g$in_range), range_claimed = mean(g$outcome_range_prob),
         rank_corr = if (nrow(g) > 2) cor(g$projected_points, g$actual, method = "spearman") else NA_real_,
         top12_minus_rest = mean(top$actual[top$r <= 12]) - mean(top$actual[top$r > 12]))
}
summary_tbl <- bind_rows(
  games |> group_by(source, season, week) |> group_modify(~ grade(.x)) |> ungroup() |> mutate(week = as.character(week)),
  games |> group_by(source, season) |> group_modify(~ grade(.x)) |> ungroup() |> mutate(week = "all")) |>
  arrange(source, season, week) |> mutate(across(where(is.double), ~ round(.x, 3)))
write_csv(summary_tbl, "data/scorecard_summary.csv")
message("Scorecard: ", nrow(games), " kicker-games graded or checked (", sum(games$wrong_starter), " wrong starter)")
print(as.data.frame(summary_tbl))
