# Pulls play-by-play data and builds two outcome tables:
#
#   1. data/team_game_fg_xp_counts.csv  - one row per team per game: total
#      FG attempts/makes and XP attempts/makes. This is the grain the
#      volume/Poisson models get fit on. Includes team-games with ZERO FG
#      attempts (built off the schedule, not just off attempts that
#      happened), which matters for fitting a count model correctly.
#      INTENTIONALLY includes playoff games (as of 2026-09-21 - previously
#      REG-only; see BUGFIX note below). The eventual volume/Poisson models
#      are REG-season-only by design, so whatever script assembles their
#      training set (the not-yet-built join-everything script, #7) must
#      filter to game_type == "REG" itself when it reads this table -
#      that filtering no longer happens here.
#
#   2. data/kicker_accuracy.csv  - one row per kicker per game per
#      distance range (0-39 / 40-49 / 50+): attempts and makes. This is
#      the grain the kicker accuracy/shrinkage model (05) gets fit on.
#      Range boundaries match the fantasy scoring rule exactly (0-39yd=
#      3pts, 40-49yd=4pts, 50+yd=5pts) - they were originally 0-30/31-49/
#      50+, which didn't match scoring and went unnoticed until the
#      probability-distribution design work surfaced it. Corrected here;
#      02's distance-mix ranges were corrected to match at the same time.
#      Also playoff-inclusive - a playoff kick is real, recent evidence of
#      a kicker's accuracy and there's no reason to throw it away
#      (confirmed with user 2026-09-21). If nflreadr's pbp for a season
#      ever includes preseason plays too, those would also flow through
#      here since there's no game_type filter on this table by design.
#
# BUGFIX (2026-09-21): table 1 used to be REG-only while table 2 was
# already playoff-inclusive. That mismatch meant a playoff-game row in 05
# (which reads both tables) would left_join to a missing row in table 1,
# producing NA xp_attempts/xp_makes for that game. Because 05's XP
# attribution assigns the full team XP total to whichever kicker attempted
# the most FGs that game, that NA regularly landed on the primary kicker -
# and 05's exponential-decay recursion (`running <- d * (running + x[i])`)
# has no NA-handling, so one poisoned input made xp_accuracy_rate NA for
# every game that kicker played afterward, forever. Confirmed on real data:
# 24 of 59 kickers affected. Fix: dropped the REG filter from table 1 so
# it's playoff-inclusive like table 2, eliminating the join gap. REG-only
# filtering is deferred to the join-everything script (#7) instead, which
# needs it anyway for the Poisson volume-model training set.
#
# Training window: 3 prior seasons, hard cutoff (decided in design phase).
# Update CURRENT_SEASON below each year; it always pulls the 3 seasons
# before it, so it never needs to be told to "add" a season manually.
#
# NOTE ON COLUMN NAMES: this relies on nflverse's current pbp/schedule
# column names (field_goal_attempt, field_goal_result, kick_distance,
# extra_point_attempt, extra_point_result, kicker_player_id,
# kicker_player_name, posteam, game_type). nflverse occasionally renames
# fields between releases. If this errors with "object not found" for one
# of those names, run dplyr::glimpse(pbp) to see the current name and
# swap it in.
#
# DATA LOADING (changed 2026-09-24): play-by-play and schedules now come
# through 00_nflverse_data.R - the same nflverse release files nflreadr reads,
# cached in data/raw/ - instead of calling nflreadr directly, so this script
# gives identical results on any machine.

library(dplyr)
library(tidyr)
library(readr)
source("00_nflverse_data.R")

CURRENT_SEASON <- 2026
SEASONS <- (CURRENT_SEASON - 3):(CURRENT_SEASON - 1)

dir.create("data", showWarnings = FALSE)

message("Loading play-by-play for seasons: ", paste(SEASONS, collapse = ", "))
pbp <- load_pbp_data(SEASONS)

# --- Table 1: team-game FG/XP counts (volume model grain) ------------------

fg_by_team_game <- pbp |>
  filter(field_goal_attempt == 1) |>
  mutate(fg_made = as.integer(field_goal_result == "made")) |>
  group_by(season, week, game_id, posteam) |>
  summarise(
    fg_attempts = n(),
    fg_makes = sum(fg_made, na.rm = TRUE),
    .groups = "drop"
  )

xp_by_team_game <- pbp |>
  filter(extra_point_attempt == 1) |>
  mutate(xp_made = as.integer(extra_point_result == "good")) |>
  group_by(season, week, game_id, posteam) |>
  summarise(
    xp_attempts = n(),
    xp_makes = sum(xp_made, na.rm = TRUE),
    .groups = "drop"
  )

# Backbone of every team-game that actually happened, so games with zero FG
# or XP attempts show up as 0 rather than being silently absent from the
# table (which would bias a Poisson fit on attempt counts).
schedules <- load_schedule_data(SEASONS)

team_game_backbone <- schedules |>
  # No game_type filter - INTENTIONALLY includes playoff games, matching
  # table 2 below (see header). Previously REG-only; that filter was
  # dropped 2026-09-21 to fix a bug where a playoff-game left_join miss
  # against this table (when it was REG-only) fed an NA into 05's
  # exponential-decay XP-accuracy recursion, permanently poisoning all of
  # that kicker's future xp_accuracy_rate values (confirmed on real data:
  # 24/59 kickers affected). REG-only filtering is now the responsibility
  # of the eventual join-everything script (#7), which needs it anyway to
  # assemble the Poisson volume-model training set (that model's grain was
  # locked to regular season only in the original design) - filter there,
  # not here.
  select(season, week, game_id, home_team, away_team) |>
  pivot_longer(cols = c(home_team, away_team), values_to = "posteam") |>
  select(season, week, game_id, posteam)

team_game_fg_xp_counts <- team_game_backbone |>
  left_join(fg_by_team_game, by = c("season", "week", "game_id", "posteam")) |>
  left_join(xp_by_team_game, by = c("season", "week", "game_id", "posteam")) |>
  mutate(across(c(fg_attempts, fg_makes, xp_attempts, xp_makes), ~ replace_na(.x, 0)))

write_csv(team_game_fg_xp_counts, "data/team_game_fg_xp_counts.csv")
message("Wrote data/team_game_fg_xp_counts.csv (", nrow(team_game_fg_xp_counts), " rows)")

# --- Table 2: kicker accuracy by distance range (shrinkage model grain) ----
# Range boundaries match the fantasy scoring rule: 0-39yd / 40-49yd / 50+yd.
# No game_type filter - intentionally includes playoff games (see header).

kicker_accuracy <- pbp |>
  filter(field_goal_attempt == 1, !is.na(kicker_player_id)) |>
  mutate(
    fg_made = as.integer(field_goal_result == "made"),
    distance_range = case_when(
      kick_distance <= 39 ~ "0-39",
      kick_distance <= 49 ~ "40-49",
      TRUE ~ "50+"
    )
  ) |>
  group_by(season, week, game_id, posteam, kicker_player_id, kicker_player_name, distance_range) |>
  summarise(
    attempts = n(),
    makes = sum(fg_made, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(kicker_accuracy, "data/kicker_accuracy.csv")
message("Wrote data/kicker_accuracy.csv (", nrow(kicker_accuracy), " rows)")
