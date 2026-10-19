# Weekly kicker projections for the upcoming week. Added 2026-09-26 (to-do #12).
#
# Run it after run_all.R (it needs the fitted models in models/). It:
#   1. downloads this season's play-by-play and the schedule (refreshed if the
#      local copy is over a day old - see 00_nflverse_data.R);
#   2. picks the target week: the earliest regular-season week of the current
#      season with a game not yet played;
#   3. builds every team's inputs going into that week (09_weekly_inputs.R);
#   4. projects every game of that week with the four volume models (07) and
#      the points distribution functions (08). Games already played that week
#      (e.g. Thursday night, on a Friday run) are kept, flagged played = TRUE,
#      with the projection the model would have made before kickoff (same
#      pre-game kicker rule) and actual_points (added 2026-09-26).
#
# ODDS: the spread and total come from nflverse's schedule file (decided
# 2026-09-26; no API or scraper). They're only as fresh as nflverse's last
# update - lines_as_of says when this run downloaded them.
#
# Writes (also copied to *_latest.csv, overwritten each run):
#   data/weekly_projections_<season>_wk<week>.csv - one row per kicker-game:
#     team, opponent, home_away, gameday, kicker_player_name/id, kicker_source,
#     kicker_last_game (the game he last kicked in - confirm he's still the
#     starter), ppg_rank / top16pre (pre-game top 16 by fantasy points per
#     game), projected_points, ci_low / ci_high (90% confidence interval on the
#     projection - the headline range), outcome_low / outcome_high (middle 80%
#     of likely scores) and outcome_range_prob, sd_points, prob_negative
#     (chance of scoring below 0), prob_10plus, the inputs (expected attempts by
#     range, make chances, implied team total, dome, roof_unknown, slump), and
#     slump_flagged / slump_test_ratio / slump_p_value (added 2026-09-28): the
#     kicker tripped 05's slump test going into this game, and the cut it would
#     make - informational only, not applied (slump_ratio stays 1),
#     lines_as_of, league_ppg (league-average points per game going into the
#     week), played and actual_points (the team's kicking fantasy points
#     in a game already played; NA otherwise).
#   data/projection_history.csv - every run's projections appended (for the
#     scorecard, 13_scorecard.R; added 2026-09-28)
#   data/weekly_distributions_<season>_wk<week>.csv - the full distribution:
#     one row per kicker-game per point total (team, kicker, points, prob).
#   data/weekly_projections_next.csv / data/weekly_distributions_next.csv (added
#     2026-09-29, to-do #17): the same for the FOLLOWING week, made with the same
#     data, when nflverse has lines for it. Rougher; for add/drop. See the end of
#     this script.
#
# The volume models were trained on pre-game top-16 team-games; projections for
# kickers outside the top 16 (top16pre = FALSE) extrapolate beyond that group.

suppressMessages({library(dplyr); library(readr)})
source("00_nflverse_data.R")
source("08_points_distribution.R")
source("09_weekly_inputs.R")
set.seed(20260926)

N_DRAWS <- 2000
MODEL_NAMES <- c("xp_attempts", "att_039", "att_4049", "att_50")
model_paths <- file.path("models", paste0("volume_", MODEL_NAMES, "_model.rds"))
if (any(!file.exists(model_paths))) stop("Fitted models missing - run run_all.R first.")
fits <- setNames(lapply(model_paths, readRDS), MODEL_NAMES)
gamma_path <- "models/points_gamma.csv"   # XP/FG dependence (2026-09-28), written by 07
if (!file.exists(gamma_path)) stop("Missing ", gamma_path, " - run 07_fit_volume_models.R first.")
points_gamma <- read_csv(gamma_path, show_col_types = FALSE)$gamma

season <- current_nfl_season()
if (is.na(season)) stop("No NFL season in progress (offseason) - nothing to project.")
SAMPLE <- (season - 3):season  # the three training seasons' span, plus this season to date
pbp <- load_pbp_data(SAMPLE)
sched <- load_schedule_data(SAMPLE)

upcoming <- sched |> filter(season == !!season, game_type == "REG", is.na(result))
if (!nrow(upcoming)) stop("No unplayed regular-season games left in ", season, ".")
week <- min(upcoming$week)
last_played_week <- max(pbp$week[pbp$season == season & pbp$season_type == "REG"], na.rm = TRUE)
log_path <- file.path(RAW_DIR, "download_log.csv")
lines_as_of <- if (file.exists(log_path)) {
  dl <- read.csv(log_path); tail(dl$downloaded_at[dl$file == "games.rds"], 1)
} else format(file.mtime(file.path(RAW_DIR, "games.rds")), "%Y-%m-%d %H:%M:%S %Z")
message("Projecting ", season, " week ", week, " (play-by-play through week ", last_played_week,
        "; lines downloaded ", lines_as_of, ")")

res <- project_week(pbp, sched, season, week, fits, points_gamma, lines_as_of, last_played_week, N_DRAWS)
out <- res$out; dist_long <- res$dist_long

stem <- sprintf("data/weekly_projections_%d_wk%02d.csv", season, week)
dstem <- sprintf("data/weekly_distributions_%d_wk%02d.csv", season, week)
write_csv(out |> mutate(across(where(is.double), ~ round(.x, 4))), stem)
write_csv(dist_long |> mutate(prob = round(prob, 6)), dstem)
invisible(file.copy(stem, "data/weekly_projections_latest.csv", overwrite = TRUE))
invisible(file.copy(dstem, "data/weekly_distributions_latest.csv", overwrite = TRUE))
message("Wrote ", stem, " (", nrow(out), " kicker-games, ", sum(out$played), " already played) and ", dstem)
print(as.data.frame(out |> select(team, opponent, kicker_player_name, top16pre, played, projected_points, ci_low, ci_high,
                                  outcome_low, outcome_high, actual_points) |> mutate(across(where(is.double), ~ round(.x, 1)))))

# --- Projection history for the scorecard (added 2026-09-28) ---------------------------
# Every run appends its projections to data/projection_history.csv (the scheduled
# task copies this file in from the project before the run and back after), so
# 13_scorecard.R can grade each week against actual scores. A rerun on the same
# day replaces that day's rows.
HISTORY_PATH <- "data/projection_history.csv"
run_rows <- out |> transmute(season, week, game_id, gameday, team, opponent, kicker_player_id, kicker_player_name,
                             played_at_run = played, top16pre, ppg_rank, kicker_ppg_pre, league_ppg,
                             projected_points, ci_low, ci_high, outcome_low, outcome_high, outcome_range_prob,
                             run_date = as.character(Sys.Date()), run_day = weekdays(Sys.Date()), source = "live",
                             lines_as_of)
old <- if (file.exists(HISTORY_PATH)) read_csv(HISTORY_PATH, show_col_types = FALSE,
                                               col_types = cols(run_date = col_character(), gameday = col_character())) else NULL
if (!is.null(old)) old <- old |> filter(!(source == "live" & run_date == run_rows$run_date[1] & season == !!season & week == !!week))
write_csv(bind_rows(old, run_rows |> mutate(gameday = as.character(gameday))) |>
            arrange(season, week, run_date, desc(projected_points)), HISTORY_PATH)
message("Appended ", nrow(run_rows), " rows to ", HISTORY_PATH)

# --- Next week too, for add/drop (added 2026-09-29, to-do #17) --------------------------
# Projects the week after the target week with the same data (games played so far), if
# nflverse has a betting line for at least one of its games. Rougher than the main file:
# one more week of kicker and team history is missing, the kicker is assumed to be whoever
# last kicked (a week more room for injuries and signings), and early lines move more.
# Backtest (17a_next_week_backtest.R, rules set first): see claude/17_next_week_log.md.
# Written to separate files (*_next.csv, plus dated copies); NOT added to
# projection_history.csv, so the scorecard only grades the main projections. Games
# with no line yet get the league-average implied total (implied_imputed = TRUE).
NEXT_STEM <- "data/weekly_projections_next.csv"; NEXT_DSTEM <- "data/weekly_distributions_next.csv"
next_week <- week + 1
next_games <- sched |> filter(season == !!season, game_type == "REG", week == next_week)
n_lined <- sum(!is.na(next_games$spread_line) & !is.na(next_games$total_line))
if (!nrow(next_games) || n_lined == 0) {
  message("No next-week projection: ", if (!nrow(next_games)) paste("no regular-season week", next_week)
          else paste("no betting lines yet for week", next_week))
  invisible(file.remove(intersect(c(NEXT_STEM, NEXT_DSTEM), list.files("data", full.names = TRUE))))
} else {
  res_next <- project_week(pbp, sched, season, next_week, fits, points_gamma, lines_as_of, last_played_week, N_DRAWS)
  out_next <- res_next$out |> mutate(projected_weeks_ahead = 2L)
  nstem <- sprintf("data/weekly_projections_next_%d_wk%02d.csv", season, next_week)
  ndstem <- sprintf("data/weekly_distributions_next_%d_wk%02d.csv", season, next_week)
  write_csv(out_next |> mutate(across(where(is.double), ~ round(.x, 4))), nstem)
  write_csv(res_next$dist_long |> mutate(prob = round(prob, 6)), ndstem)
  invisible(file.copy(nstem, NEXT_STEM, overwrite = TRUE))
  invisible(file.copy(ndstem, NEXT_DSTEM, overwrite = TRUE))
  message("Wrote next-week projection ", nstem, " (week ", next_week, ", ", nrow(out_next), " kicker-games; ",
          n_lined, " of ", nrow(next_games), " games have a betting line)")
}
