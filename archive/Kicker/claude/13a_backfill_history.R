# Rebuilds projections for past weeks of the current season and adds them to
# data/projection_history.csv with source = "rebuilt". Added 2026-09-28 (user
# decision: backfill 2026 weeks 1-3, flagged, graded separately from live weeks).
#
# Run once, by hand; not part of the weekly run. Set BACKFILL_WEEKS first
# (default: weeks 1-3 of the current season).
#
# How close to a live projection: the model is today's model. For each week,
# play-by-play is cut to games before that week and the schedule's results
# from that week on are blanked, so every input is "going into the week". The
# difference from a real live run: the betting lines are nflverse's final
# (near-closing) lines, not what was posted on Tuesday or Friday.

suppressMessages({library(dplyr); library(readr)})
source("00_nflverse_data.R")
source("08_points_distribution.R")
source("09_weekly_inputs.R")
set.seed(20260928)

season <- current_nfl_season()
BACKFILL_WEEKS <- if (exists("BACKFILL_WEEKS")) BACKFILL_WEEKS else 1:3
MODEL_NAMES <- c("xp_attempts", "att_039", "att_4049", "att_50")
fits <- setNames(lapply(file.path("models", paste0("volume_", MODEL_NAMES, "_model.rds")), readRDS), MODEL_NAMES)
points_gamma <- read_csv("models/points_gamma.csv", show_col_types = FALSE)$gamma
SAMPLE <- (season - 3):season
pbp_all <- load_pbp_data(SAMPLE)
sched_all <- load_schedule_data(SAMPLE)
HISTORY_PATH <- "data/projection_history.csv"

rows <- bind_rows(lapply(BACKFILL_WEEKS, function(w) {
  tord <- season * 100 + w
  pbp <- pbp_all |> filter(season * 100 + week < tord)
  sched <- sched_all |> mutate(ord = season * 100 + week,
                               result = if_else(ord >= tord, NA_real_, result),
                               home_score = if_else(ord >= tord, NA_real_, home_score),
                               away_score = if_else(ord >= tord, NA_real_, away_score)) |> select(-ord)
  res <- project_week(pbp, sched, season, w, fits, points_gamma, lines_as_of = "rebuilt (final lines)",
                      last_played_week = w - 1)
  message("Rebuilt ", season, " week ", w, ": ", nrow(res$out), " kicker-games")
  res$out |> transmute(season, week, game_id, gameday = as.character(gameday), team, opponent, kicker_player_id,
                       kicker_player_name, played_at_run = FALSE, top16pre, ppg_rank, kicker_ppg_pre, league_ppg,
                       projected_points, ci_low, ci_high, outcome_low, outcome_high, outcome_range_prob,
                       run_date = paste0("rebuilt ", Sys.Date()), run_day = "rebuilt", source = "rebuilt", lines_as_of)
}))

old <- if (file.exists(HISTORY_PATH)) read_csv(HISTORY_PATH, show_col_types = FALSE,
                                               col_types = cols(run_date = col_character(), gameday = col_character())) else NULL
if (!is.null(old)) old <- old |> filter(!(source == "rebuilt" & season == !!season & week %in% BACKFILL_WEEKS))
write_csv(bind_rows(old, rows) |> arrange(season, week, run_date, desc(projected_points)), HISTORY_PATH)
message("Wrote ", nrow(rows), " rebuilt rows to ", HISTORY_PATH)
