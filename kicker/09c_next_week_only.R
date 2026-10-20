# Next-week projection only (the "early look" for add/drop). Added 2026-10-15.
#
# WHY: 09b writes the next-week files only when nflverse already has betting lines for
# the following week. On the Tuesday-morning run it usually doesn't (2026 week 7: 0 of
# 14 games lined at 8:45 Central on Tuesday, 14 of 14 by Thursday), so Tuesday summaries
# had no look-ahead. This script is the light mid-week run: it redoes ONLY 09b's
# next-week section, with the same functions, so it needs 00, 08, 09 and 09n plus the
# new model's two data files - not 01-07, the previous model, the history or the
# scorecard. It doesn't touch any other file.
#
# Output is the same as 09b's next-week section: data/weekly_projections_next.csv and
# data/weekly_distributions_next.csv (plus dated copies), projected_weeks_ahead = 2.
# Projections and distributions match 09b's exactly for the same data; the confidence
# interval is a Monte Carlo draw, so it differs from a 09b run by simulation noise only.
#
# XP/FG dependence (gamma): 09b reads it from models/points_gamma.csv, written by 07.
# 07's training data is fixed for the season, so the values below are copied from it
# (2026-10-15). If 07 is ever refit on new data, update them here too.

suppressMessages({library(dplyr); library(readr)})
source("00_nflverse_data.R")
source("08_points_distribution.R")
source("09_weekly_inputs.R")
source("09n_new_model.R")
set.seed(20261015)
nm <- load_new_model()
new_model_selftest(nm)
POINTS_GAMMA <- c(att_039 = -0.08210770324353311, att_4049 = -0.1019442602604589, att_50 = -0.15681688871751043)
N_DRAWS <- 2000

season <- current_nfl_season()
if (is.na(season)) stop("No NFL season in progress (offseason) - nothing to project.")
SAMPLE <- (season - 3):season
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

dir.create("data", showWarnings = FALSE)
NEXT_STEM <- "data/weekly_projections_next.csv"; NEXT_DSTEM <- "data/weekly_distributions_next.csv"
next_week <- week + 1
next_games <- sched |> filter(season == !!season, game_type == "REG", week == next_week)
n_lined <- sum(!is.na(next_games$spread_line) & !is.na(next_games$total_line))
message("Upcoming week ", week, "; next week ", next_week, ": ", n_lined, " of ", nrow(next_games),
        " games have a betting line (lines downloaded ", lines_as_of, "; play-by-play through week ", last_played_week, ")")
if (!nrow(next_games) || n_lined == 0) {
  message("No next-week projection: ", if (!nrow(next_games)) paste("no regular-season week", next_week)
          else paste("no betting lines yet for week", next_week))
} else {
  res_next <- project_week_new(pbp, sched, season, next_week, nm, POINTS_GAMMA, lines_as_of, last_played_week, N_DRAWS)
  out_next <- res_next$out |> mutate(projected_weeks_ahead = 2L)
  nstem <- sprintf("data/weekly_projections_next_%d_wk%02d.csv", season, next_week)
  ndstem <- sprintf("data/weekly_distributions_next_%d_wk%02d.csv", season, next_week)
  write_csv(out_next |> mutate(across(where(is.double), ~ round(.x, 4))), nstem)
  write_csv(res_next$dist_long |> mutate(prob = round(prob, 6)), ndstem)
  invisible(file.copy(nstem, NEXT_STEM, overwrite = TRUE))
  invisible(file.copy(ndstem, NEXT_DSTEM, overwrite = TRUE))
  message("Wrote next-week projection ", nstem, " (week ", next_week, ", ", nrow(out_next), " kicker-games; ",
          n_lined, " of ", nrow(next_games), " games have a betting line)")
  print(as.data.frame(out_next |> arrange(desc(projected_points)) |> head(8) |>
          select(team, opponent, kicker_player_name, projected_points, ci_low, ci_high, implied_imputed, roof_unknown) |>
          mutate(across(where(is.double), ~ round(.x, 2)))))
}
message("Next-week run done.")
