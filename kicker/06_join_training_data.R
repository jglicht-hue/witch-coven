# Assembles the two final training tables from scripts 01-05's outputs.
# This is task #7 on the project's build list ("join-everything"), named
# 06 to match its actual position in the pipeline's file sequence.
#
# Produces TWO separate tables, not one merged table (confirmed with user
# 2026-09-21) - they serve two different models with two different grains,
# and forcing them into one wide table would mean repeating every team-
# level covariate once per kicker in a multi-kicker game for no benefit:
#
#   1. data/team_game_training_table.csv - the VOLUME TABLE. Team-game
#      grain. Training set for the Poisson FG-attempts / XP-attempts
#      volume models. REGULAR SEASON ONLY (confirmed 2026-09-21,
#      reaffirming the original design-phase decision). This is a
#      deliberate exclusion, not an oversight: scripts 02/03/04 (red zone/
#      coach tendencies, dome/altitude, Vegas implied totals) all filter
#      to regular-season games (game_type == "REG" in nflreadr's schedule
#      data) before computing anything, so playoff-game covariates don't exist
#      anywhere in the pipeline for those three inputs - not NA, just no
#      rows. Including playoff rows here would mean joining real outcomes
#      to covariates that were never computed for them. Making playoffs
#      count for the volume model would require reopening and rerunning
#      02/03/04 (already-shipped scripts) and would change what their
#      trailing windows mean (e.g. an 8-game red zone window would start
#      mixing playoff and regular-season games) - raised as an option
#      2026-09-21, user has NOT decided, not implemented here.
#
#      Table 1 (data/team_game_fg_xp_counts.csv, from 01) has been
#      playoff-inclusive since 2026-09-21's XP-accuracy bugfix and carries
#      no game_type column, so THIS script derives the regular-season
#      game_id list itself via a lightweight schedules pull
#      (load_schedule_data(), schedule data only, not play-by-play) rather than editing
#      01's already-shipped output to add the column back (decided
#      2026-09-21: cheaper and keeps 01 from having to change again for
#      this).
#
#   2. data/kicker_training_table.csv - the ACCURACY TABLE.
#      Kicker-game-distance_range grain (long format: one row per kicker
#      per game per distance range, confirmed 2026-09-21). Training set
#      for the kicker-accuracy/shrinkage model. PLAYOFF-INCLUSIVE
#      (confirmed 2026-09-21) - no regular-season filtering needed or
#      applied here, because neither of this table's two inputs (01's
#      kicker_accuracy.csv, 05's kicker_game_accuracy.csv) filters by
#      game_type to begin with.
#
# IMPUTATION POLICY (confirmed 2026-09-21): any covariate column that is
# NA after joining is filled with that column's own league-average value
# - computed ONCE across this table's full sample, same non-walk-forward
# convention already used for 02's coach_fg_or_go_rate league average and
# 05's per-distance-range league averages - and paired with a companion
# <column>_imputed (0/1) flag column, so the model can distinguish a real
# 0/observed value from a filled one. Applied uniformly to every
# covariate column listed in TEAM_GAME_IMPUTE_COLS / KICKER_IMPUTE_COLS
# below. Diagnostic/audit columns that carry real meaning in their NA-ness
# (slump_p_value, slump_deficit_ratio, slump_flagged, slump_pool_games)
# are deliberately excluded from imputation - see NOTE ON is_high_altitude
# below for one nuance worth a second look. ONE EXCEPTION: 02's trailing-
# window covariates are never imputed - rows missing them are dropped
# instead (see WINDOW-START ROWS).
#
# WINDOW-START ROWS (decided with user 2026-09-22): 02's trailing-window
# covariates (TRAILING_WINDOW_COLS below - red zone rates/volume and
# distance mix) are undefined at the very start of the 3-season window,
# because there are no earlier games to trail over (e.g. every team in
# the first week of the earliest season), or a team has had no red zone
# trips / FG attempts yet. On the first real run (2026-09-22) that was 38
# of 1632 volume-table rows, all in the first 3 weeks of the earliest
# season. These rows are DROPPED from the volume table rather than
# imputed: filling several predictors at once with league averages
# distorts the predictors' variance and makes these poor training
# examples. This only affects training - when predicting an upcoming week,
# the trailing windows always reach back into earlier games, so they're
# never empty. A regular-season team-game with NO row at all in 02's
# output (a real join gap, not a window-start row) triggers a warning
# before the drop, so a genuine upstream problem can't hide in this drop.
#
# NOTE ON is_high_altitude: this column is designed to be a strict binary
# (0/1, locked in 03's design phase) and should essentially never be NA in
# practice - 03 only leaves is_enclosed as NA on an unrecognised roof
# value; is_high_altitude has no NA branch at all. The uniform imputation
# policy above is applied to it anyway for consistency and to guard
# against a genuine join gap (e.g. a schedules-vintage mismatch between
# 03's run and this script's), but note that "impute with the league
# average" for a column meant to be strictly binary fills any such gap
# with a small fraction (the league-wide share of high-altitude games,
# ~1-2%) rather than a clean 0 or 1. In the extremely unlikely event this
# ever fires, that's worth a manual look rather than trusting it blindly -
# flagging this now rather than silently special-casing the column against
# the policy you approved.
#
# SCOPE: historical training tables only (confirmed 2026-09-21). Building
# the live-inference feature set (joining scrape_odds.py's daily pull for
# an upcoming week) is deferred to its own pass - it still needs the
# team-name crosswalk (task #10) and a resolution of the closing-line vs.
# snapshot-timing question (flagged in 04's header), neither of which is
# addressed here.
#
# Reads (all written by earlier scripts - run 01-05 first):
#   data/team_game_fg_xp_counts.csv   (01, Table 1)
#   data/kicker_accuracy.csv          (01, Table 2)
#   data/team_game_covariates.csv     (02)
#   data/team_game_venue.csv          (03)
#   data/team_game_odds.csv           (04)
#   data/kicker_game_accuracy.csv     (05)
#
# NOTE ON COLUMN NAMES: assumes each upstream script's output columns are
# unchanged from their own current headers (see each script's own header
# comment). If any of them changes, this fails loudly via the stopifnot
# column checks below, not silently.
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

paths <- list(
  team_counts     = "data/team_game_fg_xp_counts.csv",
  kicker_accuracy = "data/kicker_accuracy.csv",
  team_covariates = "data/team_game_covariates.csv",
  team_venue      = "data/team_game_venue.csv",
  team_odds       = "data/team_game_odds.csv",
  kicker_game_acc = "data/kicker_game_accuracy.csv"
)
missing_files <- names(paths)[!file.exists(unlist(paths))]
if (length(missing_files) > 0) {
  stop("Missing input file(s) - run 01_pull_kicker_game_outcomes.R, ",
       "02_pull_team_covariates.R, 03_pull_venue_covariates.R, ",
       "04_pull_odds_covariates.R and 05_pull_kicker_accuracy.R first. ",
       "Missing: ", paste(unlist(paths[missing_files]), collapse = ", "))
}

team_game_fg_xp_counts <- read_csv(paths$team_counts, show_col_types = FALSE)
kicker_accuracy        <- read_csv(paths$kicker_accuracy, show_col_types = FALSE)
team_game_covariates   <- read_csv(paths$team_covariates, show_col_types = FALSE)
team_game_venue        <- read_csv(paths$team_venue, show_col_types = FALSE)
team_game_odds         <- read_csv(paths$team_odds, show_col_types = FALSE)
kicker_game_accuracy   <- read_csv(paths$kicker_game_acc, show_col_types = FALSE)

stopifnot(all(c("season", "week", "game_id", "posteam", "fg_attempts", "fg_makes",
                 "xp_attempts", "xp_makes") %in% names(team_game_fg_xp_counts)))
stopifnot(all(c("season", "week", "game_id", "posteam", "kicker_player_id",
                 "kicker_player_name", "distance_range", "attempts", "makes") %in% names(kicker_accuracy)))
stopifnot(all(c("season", "week", "game_id", "posteam") %in% names(team_game_covariates)))
stopifnot(all(c("season", "week", "game_id", "posteam", "is_enclosed", "is_high_altitude") %in% names(team_game_venue)))
stopifnot(all(c("season", "week", "game_id", "posteam", "implied_team_total") %in% names(team_game_odds)))
stopifnot(all(c("season", "week", "game_id", "posteam", "kicker_player_id", "kicker_player_name",
                 "in_season_game_num", "long_run_rate_0_39", "long_run_rate_40_49", "long_run_rate_50plus",
                 "final_rate_0_39", "final_rate_40_49", "final_rate_50plus", "slump_flagged",
                 "slump_deficit_ratio", "slump_p_value", "slump_pool_games",
                 "xp_accuracy_rate") %in% names(kicker_game_accuracy)))

# --- Generic imputation helper -----------------------------------------------
# For each named column: fill NA with that column's own mean (computed once,
# over this table's full sample, ignoring existing NAs), and add a companion
# <col>_imputed 0/1 flag recording which rows were filled.
impute_with_flag <- function(df, cols) {
  for (col in cols) {
    flag_col <- paste0(col, "_imputed")
    was_na <- is.na(df[[col]])
    league_avg <- mean(df[[col]], na.rm = TRUE)
    if (is.nan(league_avg)) {
      warning("Column '", col, "' is NA for every row - cannot compute a league ",
              "average to impute with. Left as NA; check the upstream join.")
      league_avg <- NA_real_
    }
    df[[flag_col]] <- as.integer(was_na)
    df[[col]] <- if_else(was_na, league_avg, df[[col]])
  }
  df
}

# ============================================================================
# Volume Table: team-game training table (volume models), regular season only
# ============================================================================

message("Loading schedules for seasons: ", paste(SEASONS, collapse = ", "),
        " to derive the regular-season game_id list")
schedules <- load_schedule_data(SEASONS)
regu_ssn_game_ids <- schedules |> filter(game_type == "REG") |> distinct(game_id) |> pull(game_id)

team_game_regu_ssn <- team_game_fg_xp_counts |> filter(game_id %in% regu_ssn_game_ids)
message("Table 1: ", nrow(team_game_fg_xp_counts), " total team-game rows -> ",
        nrow(team_game_regu_ssn), " after restricting to the regular season (",
        nrow(team_game_fg_xp_counts) - nrow(team_game_regu_ssn), " playoff rows dropped)")

# Trailing-window covariates from 02 - rows missing any of these are
# dropped, not imputed (see WINDOW-START ROWS in the header).
TRAILING_WINDOW_COLS <- c(
  "redzone_td_rate_trail8", "redzone_trips_per_game_trail8",
  "opp_redzone_td_rate_allowed_trail8",
  "share_0_39_trail8", "share_40_49_trail8", "share_50plus_trail8"
)

# Everything else gets the league-average + flag imputation policy.
TEAM_GAME_IMPUTE_COLS <- c(
  "coach_fg_or_go_rate", "coach_long_fg_rate", "is_enclosed", "is_high_altitude", "implied_team_total"
)

join_keys <- c("season", "week", "game_id", "posteam")

# Guard: a regular-season team-game with no row at all in 02's output is a
# real join gap, not a window-start row - flag it before the drop below
# would silently absorb it.
n_missing_from_02 <- nrow(anti_join(team_game_regu_ssn, team_game_covariates, by = join_keys))
if (n_missing_from_02 > 0) {
  warning(n_missing_from_02, " regular-season team-game row(s) have no matching row in ",
          "data/team_game_covariates.csv at all - a real join gap, not a window-start ",
          "row. They will be dropped with the window-start rows below; check that 02 ",
          "was rerun on the same seasons as 01.")
}

team_game_joined <- team_game_regu_ssn |>
  left_join(team_game_covariates, by = join_keys) |>
  left_join(team_game_venue, by = join_keys) |>
  left_join(team_game_odds, by = join_keys)

is_window_start <- team_game_joined |>
  transmute(missing = if_any(all_of(TRAILING_WINDOW_COLS), is.na)) |>
  pull(missing)

if (any(is_window_start)) {
  dropped_summary <- team_game_joined[is_window_start, ] |>
    count(season, week) |>
    mutate(label = paste0(season, " wk", week, ": ", n))
  message("Dropping ", sum(is_window_start), " window-start team-game rows (empty ",
          "trailing window) - by season/week: ", paste(dropped_summary$label, collapse = ", "))
}

team_game_training_table <- team_game_joined[!is_window_start, ] |>
  impute_with_flag(TEAM_GAME_IMPUTE_COLS)

stopifnot(!anyDuplicated(team_game_training_table[c("season", "week", "game_id", "posteam")]))

n_unjoined <- team_game_training_table |>
  filter(if_any(all_of(paste0(TEAM_GAME_IMPUTE_COLS, "_imputed")), ~ .x == 1)) |>
  nrow()
if (n_unjoined > 0) {
  message(n_unjoined, " of ", nrow(team_game_training_table),
          " team-game rows had at least one covariate imputed - see the *_imputed columns")
}

write_csv(team_game_training_table, "data/team_game_training_table.csv")
message("Wrote data/team_game_training_table.csv (", nrow(team_game_training_table), " rows)")

# ============================================================================
# Accuracy Table: kicker training table (accuracy/shrinkage model), playoff-inclusive
# ============================================================================
# 05's output is wide by distance range (long_run_rate_0_39/40_49/50plus,
# final_rate_0_39/40_49/50plus). Pivot those two column families to long
# format together, keyed by a distance_range value that matches Table 2's
# own naming ("0-39"/"40-49"/"50+"), then join onto Table 2 (the real
# attempts/makes outcomes) so every real attempt-outcome row is preserved
# as the base grain.

RANGE_LABEL <- c("0_39" = "0-39", "40_49" = "40-49", "50plus" = "50+")

kicker_features_long <- kicker_game_accuracy |>
  pivot_longer(
    cols = c(long_run_rate_0_39, long_run_rate_40_49, long_run_rate_50plus,
             final_rate_0_39, final_rate_40_49, final_rate_50plus),
    names_to = c(".value", "range_suffix"),
    names_pattern = "(long_run_rate|final_rate)_(.*)"
  ) |>
  mutate(distance_range = RANGE_LABEL[range_suffix]) |>
  select(season, week, game_id, posteam, kicker_player_id,
         distance_range, long_run_rate, final_rate,
         in_season_game_num, slump_flagged, slump_deficit_ratio,
         slump_p_value, slump_pool_games, xp_accuracy_rate)

kicker_training_table <- kicker_accuracy |>
  left_join(
    kicker_features_long,
    by = c("season", "week", "game_id", "posteam", "kicker_player_id", "distance_range")
  )

KICKER_IMPUTE_COLS <- c("long_run_rate", "final_rate", "xp_accuracy_rate")
kicker_training_table <- kicker_training_table |> impute_with_flag(KICKER_IMPUTE_COLS)

stopifnot(!anyDuplicated(
  kicker_training_table[c("season", "week", "game_id", "kicker_player_id", "distance_range")]
))

# Two different kinds of imputation here, reported separately:
#   - FG accuracy rates (long_run_rate / final_rate) should NEVER be
#     imputed: 05 falls back to the league average itself for a kicker's
#     first game, so a missing value here means 05's output has no row for
#     some Table 2 row - a real join failure (e.g. 05 not rerun after 01).
#   - xp_accuracy_rate imputation is EXPECTED: 05 leaves it NA for a
#     kicker's first tracked game(s), before any XP history exists. On the
#     first real run (2026-09-22) this was 108 of 2427 rows, touching all
#     59 kickers' first game or two.
n_fg_rate_imputed <- sum(kicker_training_table$long_run_rate_imputed == 1 |
                           kicker_training_table$final_rate_imputed == 1)
if (n_fg_rate_imputed > 0) {
  warning(n_fg_rate_imputed, " kicker-game-distance_range row(s) had an FG accuracy ",
          "rate imputed - 05's output has no matching row for them. This is a real ",
          "join failure, not expected behavior: rerun 05 after 01 and check before ",
          "training on this table.")
}
message(sum(kicker_training_table$xp_accuracy_rate_imputed), " of ",
        nrow(kicker_training_table), " rows had xp_accuracy_rate imputed (expected - ",
        "each kicker's first tracked game(s), before any XP history exists)")

write_csv(kicker_training_table, "data/kicker_training_table.csv")
message("Wrote data/kicker_training_table.csv (", nrow(kicker_training_table), " rows)")
