# Backfill the new model AND the previous model for the early weeks of the season, so the
# scorecard can compare them over the WHOLE season on identical games. Added 2026-11-03.
# RUN BY HAND, once (the weekly run does not run this file). Run after run_all.R (needs models/).
#
# Why: the new model went live in week 5, the previous model was live through week 4, and
# weeks 1-3 had been rebuilt with the previous model only. This projects weeks 1..BACKFILL_THROUGH
# of the current season with both models, each as it would have been going into that week:
# play-by-play and results from later weeks are removed first, the kicker is the pre-game one.
# Same caveat as the earlier rebuild: the betting lines are the schedule file's final lines, not
# the lines live at the time - the same for both models, so the comparison stays fair.
# Leakage check: the new model's weights were fit on 2011-2025 (07n_fit_new_model.R); the previous
# model's on 2016-2025 - neither saw 2026.
# Writes source = "rebuilt_new" and "rebuilt_prev" rows into data/projection_history.csv
# (replacing earlier rows with those sources); 13_scorecard.R grades them.
suppressMessages({library(dplyr); library(readr)})
BACKFILL_FROM <- as.integer(Sys.getenv("BACKFILL_FROM", "1")); BACKFILL_THROUGH <- as.integer(Sys.getenv("BACKFILL_THROUGH", "4"))
source("00_nflverse_data.R"); source("08_points_distribution.R"); source("09_weekly_inputs.R"); source("09n_new_model.R")
set.seed(20261103)
nm <- load_new_model(); new_model_selftest(nm)
MODEL_NAMES <- c("xp_attempts", "att_039", "att_4049", "att_50")
fits <- setNames(lapply(file.path("models", paste0("volume_", MODEL_NAMES, "_model.rds")), readRDS), MODEL_NAMES)
points_gamma <- read_csv("models/points_gamma.csv", show_col_types = FALSE)$gamma
season <- current_nfl_season(); SAMPLE <- (season - 3):season
pbp_all <- load_pbp_data(SAMPLE); sched_all <- load_schedule_data(SAMPLE)
stamp <- paste("backfill", Sys.Date())
hist_rows <- function(o, src) o |> transmute(season, week, game_id, gameday, team, opponent, kicker_player_id, kicker_player_name,
    played_at_run = FALSE, top16pre, ppg_rank, kicker_ppg_pre, league_ppg, projected_points, ci_low, ci_high,
    outcome_low, outcome_high, outcome_range_prob, run_date = stamp, run_day = src, source = src,
    lines_as_of = "rebuilt (final lines)", exp_xp_attempts, exp_att_039, exp_att_4049, exp_att_50, is_enclosed)
rows <- list()
for (w in BACKFILL_FROM:BACKFILL_THROUGH) {
  ord <- function(s, k) s * 100 + k
  pbp <- pbp_all |> filter(ord(season, week) <= ord(!!season, !!w))
  sched <- sched_all |> mutate(result = ifelse(ord(season, week) > ord(!!season, !!w), NA, result))
  # A retractable roof is blank in the schedule until game day, so a live run had it unknown: blank it again
  # for this week's games at those stadiums (the roof recorded after the game would be hindsight).
  retr <- setdiff(nm$roof$home_team, "ALL")
  sched <- sched |> mutate(roof = ifelse(season == !!season & week == !!w & home_team %in% retr, NA_character_, roof))
  sched <- sched |> filter(ord(season, week) <= ord(!!season, !!w) | game_type != "REG")
  message("Backfilling ", season, " week ", w)
  nw <- project_week_new(pbp, sched, season, w, nm, points_gamma, stamp, w - 1, 2000)$out
  pv <- project_week(pbp, sched, season, w, fits, points_gamma, stamp, w - 1, 2000)$out
  k <- nw |> select(team, krate_4049)
  rows[[w]] <- bind_rows(hist_rows(nw, "rebuilt_new") |> left_join(k, by = "team"), hist_rows(pv, "rebuilt_prev") |> left_join(k, by = "team"))
}
new <- bind_rows(rows) |> mutate(gameday = as.character(gameday))
H <- "data/projection_history.csv"
old <- read_csv(H, show_col_types = FALSE, col_types = cols(run_date = col_character(), gameday = col_character())) |>
  filter(!(source %in% c("rebuilt_new", "rebuilt_prev")))
write_csv(bind_rows(old, new) |> arrange(season, week, run_date, source, desc(projected_points)), H)
message("Wrote ", nrow(new), " backfill rows to ", H)
