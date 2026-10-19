# Builds venue covariates for the volume models: whether a game is played
# in an enclosed stadium, and whether it is played at high altitude.
#
# Output: data/team_game_venue.csv - one row per (season, week, game_id,
# posteam), joinable onto the outcome tables from script 01 and the
# covariates from script 02 on those same four columns. Both flags are
# properties of the GAME, so the two teams in a game get identical values.
#
#   is_enclosed      : 1 if the schedule's roof value is "dome" or "closed"
#                      (a retractable roof that was closed for that game);
#                      0 if "outdoors" or "open". NA if roof is missing or
#                      is a value this script doesn't recognise - NAs are
#                      left as NA here (not imputed) so the join script's
#                      league-average imputation policy handles them
#                      consistently with the other covariates.
#   is_high_altitude : 1 for Denver home games and for games played in
#                      Mexico City; 0 otherwise. Binary by design (locked
#                      in the design phase).
#
# Regular season only, same 3-season training window as scripts 01 and 02.
#
# NOTE ON COLUMN NAMES: assumes the nflverse schedules include roof,
# stadium, location, home_team, away_team and game_type. Current as of
# recent nflverse releases, but not verified live from the build
# environment. If this errors with "object not found", run
# names(load_schedule_data(2024)) to check current names.
#
# NOTE ON MEXICO CITY MATCHING: it is identified by a text match on the
# stadium name ("Azteca", "Banorte" or "Mexico"), because the stadium has
# been renamed over the years. The script prints which stadiums were
# flagged as high-altitude - eyeball that list on first run.
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

message("Loading schedules for seasons: ", paste(SEASONS, collapse = ", "))
schedules <- load_schedule_data(SEASONS) |>
  filter(game_type == "REG")

message("Roof values seen: ", paste(sort(unique(schedules$roof), na.last = TRUE), collapse = ", "))

game_venue <- schedules |>
  mutate(
    is_enclosed = case_when(
      roof %in% c("dome", "closed") ~ 1L,
      roof %in% c("outdoors", "open") ~ 0L,
      TRUE ~ NA_integer_
    ),
    is_high_altitude = as.integer(
      (home_team == "DEN" & location %in% "Home") |
        grepl("Azteca|Banorte|Mexico", stadium, ignore.case = TRUE)
    )
  )

# --- Diagnostics -------------------------------------------------------------

n_na_roof <- sum(is.na(game_venue$is_enclosed))
if (n_na_roof > 0) {
  warning(n_na_roof, " game(s) have a missing or unrecognised roof value - is_enclosed left as NA")
}

message("Games flagged high-altitude, by stadium:")
print(
  game_venue |>
    filter(is_high_altitude == 1) |>
    count(stadium, name = "games")
)

# --- Reshape to team-game grain and write ------------------------------------

team_game_venue <- game_venue |>
  select(season, week, game_id, home_team, away_team, is_enclosed, is_high_altitude) |>
  pivot_longer(cols = c(home_team, away_team), values_to = "posteam") |>
  select(season, week, game_id, posteam, is_enclosed, is_high_altitude)

stopifnot(!anyDuplicated(team_game_venue[c("season", "week", "game_id", "posteam")]))

write_csv(team_game_venue, "data/team_game_venue.csv")
message("Wrote data/team_game_venue.csv (", nrow(team_game_venue), " rows)")
