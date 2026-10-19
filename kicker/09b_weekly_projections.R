# Weekly kicker projections for the upcoming week. Added 2026-09-26 (to-do #12).
#
# MODEL (changed 2026-10-06, to-do #31b): the main files are now written by the
# NEW model (09n_new_model.R: attempts from count models and kick-or-go models
# fit on 2016-2025, dome shifts on the make chances, a closed-roof share for
# unannounced retractable roofs). The previous model (the four volume models
# from 07, with the 0.32 dome placeholder for unknown roofs) is still run and
# written to data/weekly_projections_previous_model.csv, so the two can be
# compared every week.
#
# Run it after run_all.R (it needs the fitted models in models/). It:
#   1. downloads this season's play-by-play and the schedule (refreshed if the
#      local copy is over a day old - see 00_nflverse_data.R);
#   2. picks the target week: the earliest regular-season week of the current
#      season with a game not yet played;
#   3. builds every team's inputs going into that week (09_weekly_inputs.R);
#   4. projects every game of that week with the new model (09n) and the points
#      distribution functions (08), and again with the previous model (07's four
#      volume models). Games already played that week
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
#     Since 2026-10-06 also: exp_margin (2 x implied team total - game total),
#     roof_closed_share (chance the roof is closed: 1 or 0 when known, the
#     stadium's share for the month when roof_unknown), proj_roof_closed /
#     proj_roof_open (roof-unknown rows: the projection either way),
#     p_039_record ... p_xp_record (make chances before the dome shift; p_039 ...
#     p_xp now include it), krate_4049, krate_40plus, coach_long_fg_rate, model.
#     For a roof-unknown row, is_enclosed = roof_closed_share and every number is
#     the closed and open versions blended by it.
#   data/weekly_roof_scenarios_latest.csv (added 2026-10-06) - for roof-unknown
#     rows only: one full row per roof state (roof_assumed = closed / open), same
#     columns. Removed when no roof is unknown.
#   data/weekly_projections_previous_model.csv (added 2026-10-06) - the previous
#     model's projections for the same week and inputs (the main file's columns
#     as they were before 2026-10-06).
#   data/projection_history.csv - every run's projections appended (for the
#     scorecard, 13_scorecard.R; added 2026-09-28). Since 2026-10-06 the new
#     model's rows have source = "live" and the previous model's rows are
#     appended with source = "prev_model".
#   data/weekly_distributions_<season>_wk<week>.csv - the full distribution:
#     one row per kicker-game per point total (team, kicker, points, prob).
#   data/weekly_projections_next.csv / data/weekly_distributions_next.csv (added
#     2026-09-29, to-do #17): the same for the FOLLOWING week, made with the same
#     data, when nflverse has lines for it. Rougher; for add/drop. See the end of
#     this script.
#
# The count models were trained on pre-game top-16 team-games; projections for
# kickers outside the top 16 (top16pre = FALSE) extrapolate beyond that group.

suppressMessages({library(dplyr); library(readr)})
source("00_nflverse_data.R")
source("08_points_distribution.R")
source("09_weekly_inputs.R")
source("09n_new_model.R")
set.seed(20260926)
nm <- load_new_model()
new_model_selftest(nm)

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

res <- project_week_new(pbp, sched, season, week, nm, points_gamma, lines_as_of, last_played_week, N_DRAWS)
out <- res$out; dist_long <- res$dist_long
prev <- project_week(pbp, sched, season, week, fits, points_gamma, lines_as_of, last_played_week, N_DRAWS)$out   # the previous model

stem <- sprintf("data/weekly_projections_%d_wk%02d.csv", season, week)
dstem <- sprintf("data/weekly_distributions_%d_wk%02d.csv", season, week)
write_csv(out |> mutate(across(where(is.double), ~ round(.x, 4))), stem)
write_csv(dist_long |> mutate(prob = round(prob, 6)), dstem)
invisible(file.copy(stem, "data/weekly_projections_latest.csv", overwrite = TRUE))
invisible(file.copy(dstem, "data/weekly_distributions_latest.csv", overwrite = TRUE))
message("Wrote ", stem, " (", nrow(out), " kicker-games, ", sum(out$played), " already played) and ", dstem)
# roof-unknown rows, one row per roof state (for applying weather to the open-roof version)
SCEN <- "data/weekly_roof_scenarios_latest.csv"
if (!is.null(res$scenarios)) {
  write_csv(res$scenarios |> mutate(across(where(is.double), ~ round(.x, 4))), SCEN)
  message("Wrote ", SCEN, " (", nrow(res$scenarios) / 2, " roof-unknown kicker-games)")
} else if (file.exists(SCEN)) invisible(file.remove(SCEN))
# the previous model, same week and inputs
pstem <- sprintf("data/weekly_projections_previous_model_%d_wk%02d.csv", season, week)
write_csv(prev |> mutate(across(where(is.double), ~ round(.x, 4)), model = "previous model (07 volume models)"), pstem)
invisible(file.copy(pstem, "data/weekly_projections_previous_model.csv", overwrite = TRUE))
both <- out |> left_join(prev |> select(team, previous_model = projected_points), by = "team") |> mutate(new_minus_previous = projected_points - previous_model)
message("Wrote ", pstem, ". New model vs previous: mean absolute difference ", round(mean(abs(both$new_minus_previous)), 2),
        ", largest ", round(max(abs(both$new_minus_previous)), 2), " (", both$kicker_player_name[which.max(abs(both$new_minus_previous))], ")")
print(as.data.frame(both |> select(team, opponent, kicker_player_name, top16pre, played, projected_points, ci_low, ci_high,
                                   outcome_low, outcome_high, previous_model, roof_unknown, roof_closed_share, actual_points) |>
                      mutate(across(where(is.double), ~ round(.x, 1)), roof_closed_share = ifelse(roof_unknown, both$roof_closed_share, NA))))

# --- Projection history for the scorecard (added 2026-09-28) ---------------------------
# Every run appends its projections to data/projection_history.csv (the scheduled
# task copies this file in from the project before the run and back after), so
# 13_scorecard.R can grade each week against actual scores. A rerun on the same
# day replaces that day's rows.
HISTORY_PATH <- "data/projection_history.csv"
# Since 2026-10-06: the new model's rows are source = "live" (graded as the live
# projection); the previous model's rows are source = "prev_model" (graded on their
# own, so the two can be compared). The expected attempts, dome value and kicker
# 40-49 accuracy are kept too, for the scorecard's check on accurate dome kickers.
hist_rows <- function(o, src) o |> transmute(season, week, game_id, gameday, team, opponent, kicker_player_id, kicker_player_name,
                             played_at_run = played, top16pre, ppg_rank, kicker_ppg_pre, league_ppg,
                             projected_points, ci_low, ci_high, outcome_low, outcome_high, outcome_range_prob,
                             run_date = as.character(Sys.Date()), run_day = weekdays(Sys.Date()), source = src,
                             lines_as_of, exp_xp_attempts, exp_att_039, exp_att_4049, exp_att_50, is_enclosed)
k4049 <- out |> select(team, krate_4049)
run_rows <- bind_rows(hist_rows(out, "live"), hist_rows(prev, "prev_model")) |> left_join(k4049, by = "team")
old <- if (file.exists(HISTORY_PATH)) read_csv(HISTORY_PATH, show_col_types = FALSE,
                                               col_types = cols(run_date = col_character(), gameday = col_character())) else NULL
if (!is.null(old)) old <- old |> filter(!(source %in% c("live", "prev_model") & run_date == run_rows$run_date[1] & season == !!season & week == !!week))
write_csv(bind_rows(old, run_rows |> mutate(gameday = as.character(gameday))) |>
            arrange(season, week, run_date, source, desc(projected_points)), HISTORY_PATH)
message("Appended ", nrow(run_rows), " rows to ", HISTORY_PATH, " (", sum(run_rows$source == "live"), " new model, ", sum(run_rows$source == "prev_model"), " previous model)")

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
  res_next <- project_week_new(pbp, sched, season, next_week, nm, points_gamma, lines_as_of, last_played_week, N_DRAWS)
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
