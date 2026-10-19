# Builds team-game-level covariates used by the volume/opportunity models.
#
# Output: data/team_game_covariates.csv - one row per (season, week,
# game_id, posteam), joinable onto the outcome tables from script 01 on
# those same four columns. Columns:
#
#   redzone_td_rate_trail8       : trailing 8-game red zone TD% (team-keyed,
#                                   offense)
#   redzone_trips_per_game_trail8: trailing 8-game red zone trips per game
#                                   (team-keyed, offense) - a volume/pace
#                                   measure, distinct from the rate above
#   opp_redzone_td_rate_allowed_trail8 : trailing 8-game red zone TD% that
#                                   THIS WEEK'S OPPONENT's defense has
#                                   allowed (i.e. how stingy they are at
#                                   forcing FGs instead of TDs). Attached to
#                                   each team's offensive row based on who
#                                   they're playing that week.
#   share_0_39_trail8       : trailing 8-game share of that team's FG
#   share_40_49_trail8        attempts falling in each distance range -
#   share_50plus_trail8       the "distance-mix" input. Boundaries match
#                              the fantasy scoring rule (0-39/40-49/50+),
#                              not the original 0-30/31-49/50+ split this
#                              had until it was caught and corrected.
#   coach_fg_or_go_rate     : trailing 32-game FG-or-go rate on 4th-and-
#                             in-range (opponent's 42 or closer), keyed by
#                             (team, coach) so a coaching change resets the
#                             window automatically. Shrunk toward the
#                             league-average rate using the same
#                             mathematical form as the accuracy model's
#                             w=5 shrinkage; COACH_SHRINKAGE_W below is a
#                             starting value, not yet validated against
#                             holdout data - same caveat as w=5.
#   coach_long_fg_rate      : same method, restricted to 4th downs at the
#                             opponent's 33-42 (a ~50-59 yard kick), the
#                             zone that decides 50+ attempts. Added
#                             2026-09-24 (moved here from the experimental
#                             07b script after passing the 95% placebo test
#                             for XP and 50+ attempts). League average in
#                             this zone is ~40%, vs ~60% for the full zone.
#   coach_long_4th_downs_trail : raw count of such 4th downs in the trailing
#                             window - how much evidence is behind the rate.
#
# All trailing windows exclude the current game itself (leakage-safe) and
# cross the season boundary automatically early in a season rather than
# resetting to an empty window.
#
# NOTE ON COLUMN NAMES: assumes nflverse's pbp includes fixed_drive,
# drive_inside20, fixed_drive_result, posteam, and defteam, and that
# the schedules include home_coach/away_coach, home_team/away_team, and
# gameday. Current as of recent nflverse releases, but not verified live
# from this environment - if anything errors with "object not found", run
# names(load_schedule_data(2024)) and
# dplyr::glimpse(load_pbp_data(2024)) to check current
# names and adjust.
#
# BUGFIX (this version): opponent_lookup previously built its "opponent"
# column with pivot_longer(cols = c(home_team, away_team), ...) and then
# referenced home_team/away_team in the following mutate() - but
# pivot_longer had already consumed those two columns into side/posteam,
# so they no longer existed ("object 'away_team' not found"). Rebuilt
# below with bind_rows of the two team perspectives instead, which keeps
# both the team and its opponent available in the same row without
# pivoting either one away. team_game_backbone's pivot_longer (just above)
# was never affected by this bug - it only reads home_coach/away_coach in
# its mutate, and those columns aren't part of that pivot.
#
# DATA LOADING (changed 2026-09-24): play-by-play and schedules now come
# through 00_nflverse_data.R - the same nflverse release files nflreadr reads,
# cached in data/raw/ - instead of calling nflreadr directly, so this script
# gives identical results on any machine.

library(dplyr)
library(tidyr)
library(readr)
library(slider)
source("00_nflverse_data.R")

CURRENT_SEASON <- 2026
SEASONS <- (CURRENT_SEASON - 3):(CURRENT_SEASON - 1)

REDZONE_DISTANCE_WINDOW <- 8       # games, team-keyed
COACH_TENDENCY_WINDOW <- 32        # games, (team, coach)-keyed
COACH_SHRINKAGE_W <- 10            # starting value - unvalidated, same caveat as accuracy model's w=5
FOURTH_DOWN_RANGE_YARDLINE <- 42   # yardline_100 <= this = "in range" (~58-yard FG)
LONG_ZONE_MIN <- 33                # opponent's 33 -> ~50-yard kick (coach_long_fg_rate)
LONG_ZONE_MAX <- 42                # opponent's 42 -> ~59-yard kick

dir.create("data", showWarnings = FALSE)

message("Loading play-by-play and schedules for seasons: ", paste(SEASONS, collapse = ", "))
pbp <- load_pbp_data(SEASONS)
schedules <- load_schedule_data(SEASONS) |> filter(game_type == "REG")

# --- Shared scaffolding: one row per team-game, chronologically ordered ---

team_game_backbone <- schedules |>
  select(season, week, game_id, gameday, home_team, away_team, home_coach, away_coach) |>
  pivot_longer(cols = c(home_team, away_team), names_to = "side", values_to = "posteam") |>
  mutate(coach = if_else(side == "home_team", home_coach, away_coach)) |>
  select(season, week, game_id, gameday, posteam, coach)

# Opponent lookup: for a given (season, week, game_id, posteam) row, who did
# they play that week? Used to attach the OPPONENT's defensive tendencies
# onto a team's own offensive row. Built via bind_rows (not pivot_longer)
# because each row needs BOTH team columns available at once - pivot_longer
# would consume whichever two columns it's given, leaving nothing to pair
# posteam against.
opponent_lookup <- bind_rows(
  schedules |> transmute(season, week, game_id, posteam = home_team, opponent = away_team),
  schedules |> transmute(season, week, game_id, posteam = away_team, opponent = home_team)
)

# Generic helper: given one row per (group_key, game) with a numerator and
# denominator already summed for that single game, adds a trailing sum of
# each over the `window` games immediately before (never including) that
# row, within the same group_key. Also adds a trailing count of games
# actually in that window (trail_games), needed to turn a trailing sum
# into a per-game rate that's comparable across partial and full windows -
# a raw trailing sum isn't on the same scale early in a team's history
# (e.g. 2 games' worth of trips) as it is once the window is full (8
# games' worth), but a per-game average is.
add_trailing_sums <- function(df, window) {
  df |>
    arrange(group_key, gameday) |>
    group_by(group_key) |>
    mutate(
      trail_numerator = slide_dbl(numerator, sum, .before = window, .after = -1, .complete = FALSE),
      trail_denominator = slide_dbl(denominator, sum, .before = window, .after = -1, .complete = FALSE),
      trail_games = slide_dbl(rep(1, dplyr::n()), sum, .before = window, .after = -1, .complete = FALSE)
    ) |>
    ungroup()
}

# --- Red zone TD% and trip volume (team-keyed, trailing 8 games) -----------
# One drive-level table, keyed by both posteam and defteam, feeds both the
# offensive version (this team's own red zone TD%) and the defensive
# version (how stingy this team's defense is) below.

drive_summary <- pbp |>
  filter(!is.na(posteam), !is.na(defteam), !is.na(fixed_drive)) |>
  group_by(season, week, game_id, posteam, defteam, fixed_drive) |>
  summarise(
    reached_red_zone = any(drive_inside20 == 1, na.rm = TRUE),
    touchdown = dplyr::first(fixed_drive_result) == "Touchdown",
    .groups = "drop"
  ) |>
  filter(reached_red_zone)

# Offense: this team's own red zone TD rate and trip volume
redzone_by_game <- drive_summary |>
  group_by(season, week, game_id, posteam) |>
  summarise(numerator = sum(touchdown), denominator = n(), .groups = "drop") |>
  rename(group_key = posteam)

redzone_trailing <- team_game_backbone |>
  rename(group_key = posteam) |>
  left_join(redzone_by_game, by = c("season", "week", "game_id", "group_key")) |>
  mutate(across(c(numerator, denominator), ~ replace_na(.x, 0))) |>
  add_trailing_sums(REDZONE_DISTANCE_WINDOW) |>
  transmute(
    season, week, game_id, posteam = group_key,
    redzone_td_rate_trail8 = if_else(trail_denominator == 0, NA_real_, trail_numerator / trail_denominator),
    redzone_trips_per_game_trail8 = if_else(trail_games == 0, NA_real_, trail_denominator / trail_games)
  )

# Defense: how often this team's defense has allowed red zone trips to
# become touchdowns (vs. forcing a FG or a stop), trailing 8 games. Keyed
# by the team's own identity while ON DEFENSE - joined onto each team's
# OFFENSIVE row further down via opponent_lookup, since what matters for
# predicting THIS team's FG attempts is THEIR OPPONENT's defensive
# tendency, not their own.
defense_redzone_by_game <- drive_summary |>
  group_by(season, week, game_id, defteam) |>
  summarise(numerator = sum(touchdown), denominator = n(), .groups = "drop") |>
  rename(group_key = defteam)

defense_redzone_trailing <- team_game_backbone |>
  rename(group_key = posteam) |>
  left_join(defense_redzone_by_game, by = c("season", "week", "game_id", "group_key")) |>
  mutate(across(c(numerator, denominator), ~ replace_na(.x, 0))) |>
  add_trailing_sums(REDZONE_DISTANCE_WINDOW) |>
  transmute(
    season, week, game_id,
    defending_team = group_key,
    own_redzone_td_rate_allowed_trail8 = if_else(trail_denominator == 0, NA_real_, trail_numerator / trail_denominator)
  )

# Attach the OPPONENT's stinginess to each team's own offensive row.
opp_redzone_stinginess <- opponent_lookup |>
  left_join(
    defense_redzone_trailing,
    by = c("season", "week", "game_id", "opponent" = "defending_team")
  ) |>
  transmute(
    season, week, game_id, posteam,
    opp_redzone_td_rate_allowed_trail8 = own_redzone_td_rate_allowed_trail8
  )

# --- Distance mix: trailing 8-game share of FG attempts by distance range --

fg_attempts <- pbp |>
  filter(field_goal_attempt == 1) |>
  mutate(
    distance_range = case_when(
      kick_distance <= 39 ~ "0_39",
      kick_distance <= 49 ~ "40_49",
      TRUE ~ "50plus"
    )
  )

distance_mix_by_range <- function(range_name) {
  range_counts <- fg_attempts |>
    group_by(season, week, game_id, posteam) |>
    summarise(
      numerator = sum(distance_range == range_name),
      denominator = n(),
      .groups = "drop"
    ) |>
    rename(group_key = posteam)

  team_game_backbone |>
    rename(group_key = posteam) |>
    left_join(range_counts, by = c("season", "week", "game_id", "group_key")) |>
    mutate(across(c(numerator, denominator), ~ replace_na(.x, 0))) |>
    add_trailing_sums(REDZONE_DISTANCE_WINDOW) |>
    transmute(
      season, week, game_id, posteam = group_key,
      !!paste0("share_", range_name, "_trail8") := if_else(
        trail_denominator == 0, NA_real_, trail_numerator / trail_denominator
      )
    )
}

distance_mix <- distance_mix_by_range("0_39") |>
  left_join(distance_mix_by_range("40_49"), by = c("season", "week", "game_id", "posteam")) |>
  left_join(distance_mix_by_range("50plus"), by = c("season", "week", "game_id", "posteam"))

# --- Coach FG-or-go rate (team+coach-keyed, trailing 32 games, shrunk) -----

fourth_down_range <- pbp |>
  filter(down == 4, yardline_100 <= FOURTH_DOWN_RANGE_YARDLINE, !is.na(posteam)) |>
  mutate(went_for_fg = as.integer(field_goal_attempt == 1))

league_avg_fg_or_go <- mean(fourth_down_range$went_for_fg, na.rm = TRUE)
message("League-average FG-or-go rate in range: ", round(league_avg_fg_or_go, 3))

fourth_down_by_game <- fourth_down_range |>
  group_by(season, week, game_id, posteam) |>
  summarise(numerator = sum(went_for_fg), denominator = n(), .groups = "drop")

coach_trailing <- team_game_backbone |>
  mutate(group_key = paste(posteam, coach, sep = " | ")) |>
  left_join(fourth_down_by_game, by = c("season", "week", "game_id", "posteam")) |>
  mutate(across(c(numerator, denominator), ~ replace_na(.x, 0))) |>
  add_trailing_sums(COACH_TENDENCY_WINDOW) |>
  transmute(
    season, week, game_id, posteam,
    coach_fg_or_go_rate = (trail_numerator + COACH_SHRINKAGE_W * league_avg_fg_or_go) /
      (trail_denominator + COACH_SHRINKAGE_W)
  )

# --- Coach long-range FG rate (4th down at opponent's 33-42) ----------------
# Same (team, coach) keying, window and shrinkage as coach_fg_or_go_rate.

long_zone <- pbp |>
  filter(down == 4, !is.na(posteam),
         yardline_100 >= LONG_ZONE_MIN, yardline_100 <= LONG_ZONE_MAX) |>
  mutate(went_for_fg = as.integer(field_goal_attempt == 1))

league_avg_long_fg <- mean(long_zone$went_for_fg, na.rm = TRUE)
message("League-average FG rate on 4th down at the opponent's ", LONG_ZONE_MIN, "-", LONG_ZONE_MAX,
        ": ", round(league_avg_long_fg, 3), " (", nrow(long_zone), " plays)")

long_by_game <- long_zone |>
  group_by(season, week, game_id, posteam) |>
  summarise(numerator = sum(went_for_fg, na.rm = TRUE), denominator = n(), .groups = "drop")

coach_long_trailing <- team_game_backbone |>
  mutate(group_key = paste(posteam, coach, sep = " | ")) |>
  left_join(long_by_game, by = c("season", "week", "game_id", "posteam")) |>
  mutate(across(c(numerator, denominator), ~ replace_na(.x, 0))) |>
  add_trailing_sums(COACH_TENDENCY_WINDOW) |>
  transmute(
    season, week, game_id, posteam,
    coach_long_fg_rate = (trail_numerator + COACH_SHRINKAGE_W * league_avg_long_fg) /
      (trail_denominator + COACH_SHRINKAGE_W),
    coach_long_4th_downs_trail = trail_denominator
  )

# --- Combine and write ------------------------------------------------------

team_game_covariates <- redzone_trailing |>
  left_join(opp_redzone_stinginess, by = c("season", "week", "game_id", "posteam")) |>
  left_join(distance_mix, by = c("season", "week", "game_id", "posteam")) |>
  left_join(coach_trailing, by = c("season", "week", "game_id", "posteam")) |>
  left_join(coach_long_trailing, by = c("season", "week", "game_id", "posteam"))

write_csv(team_game_covariates, "data/team_game_covariates.csv")
message("Wrote data/team_game_covariates.csv (", nrow(team_game_covariates), " rows)")
