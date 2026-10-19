# Builds the implied_team_total covariate for the Poisson volume models,
# for HISTORICAL/TRAINING games only.
#
# Source: nflreadr::load_schedules()'s compiled historical betting lines
# (spread_line, total_line) - confirmed present by the user on 2026-09-19
# via names(nflreadr::load_schedules(seasons = 2023)). This is a separate
# data source from scrape_odds.py, which pulls LIVE lines from
# the-odds-api.com for upcoming weeks. The two are not interchangeable and
# this script only produces the historical side:
#   - Historical/training (this script): nflreadr's compiled lines, which
#     are historical closing-line archives.
#   - Live/inference (scrape_odds.py, not this script): daily API pull,
#     written to data/odds/odds_YYYY-MM-DD.csv.
# Whichever script eventually joins live odds into the feature set for a
# current week needs to reconcile two things this script does NOT handle:
#   1. Team identifiers: scrape_odds.py writes full team names ("Kansas
#      City Chiefs"), nflreadr and the rest of this pipeline use
#      abbreviations ("KC"). Needs a crosswalk.
#   2. Snapshot timing: nflreadr's historical lines are closing-line
#      archives, but scrape_odds.py captures whatever day it happens to
#      run (once per day, skips if already pulled today). Early-week and
#      closing lines can differ meaningfully; if predictions are made
#      several days before kickoff, training on closing lines while
#      predicting from an earlier-week snapshot is a mild train/inference
#      mismatch. Not addressed here - flagged for the join-everything
#      script.
#
# Output: data/team_game_odds.csv - one row per (season, week, game_id,
# posteam), same grain/join keys as scripts 01-03.
#   implied_team_total : that team's Vegas-implied expected point total for
#                         the game, in the SAME units and formula as
#                         scrape_odds.py's own implied_team_total column:
#                             implied_total = total_line / 2 - own_spread / 2
#                         where own_spread follows the odds-api convention
#                         (favorite's own spread is negative, underdog's is
#                         positive). NA when total_line or spread_line is
#                         missing for that game - left un-imputed here, per
#                         the same league-average-at-join-time policy used
#                         for the other covariate scripts.
#
# SIGN-CONVENTION SELF-CHECK: nflverse data sources have used different
# spread_line conventions over time (some store it as "home team's expected
# margin", positive = home favored; others store it as "home team's own
# spread" in the traditional betting sense, negative = home favored). Rather
# than assume one, this script infers the convention at runtime from the
# actual correlation between spread_line and real game margins, and prints
# what it inferred. EYEBALL THE PRINTED DIAGNOSTIC on first run - if
# |correlation| is small, the inference is unreliable and the result should
# not be trusted without manual review.
#
# Regular season only, same 3-season training window as scripts 01-03.
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

stopifnot(all(c("spread_line", "total_line", "home_score", "away_score") %in% names(schedules)))

# --- Infer spread_line sign convention ---------------------------------------

completed <- schedules |>
  filter(!is.na(home_score), !is.na(away_score), !is.na(spread_line))

actual_home_margin <- completed$home_score - completed$away_score
sign_cor <- cor(completed$spread_line, actual_home_margin, use = "complete.obs")

message(
  "spread_line vs. actual (home_score - away_score) correlation: ",
  round(sign_cor, 3),
  " (n = ", nrow(completed), " completed games with a line)"
)

if (abs(sign_cor) < 0.1) {
  warning(
    "Sign-convention inference is weak (|correlation| < 0.1) - the ",
    "convention below may be wrong. Check manually before trusting ",
    "implied_team_total."
  )
}

if (sign_cor > 0) {
  message("Inferred convention: spread_line = home team's expected margin (positive = home favored). Flipping sign to match odds-api's own-spread convention (favorite negative).")
  home_own_spread_expr <- quote(-spread_line)
} else {
  message("Inferred convention: spread_line = home team's own spread, odds-api style (negative = home favored). Using as-is.")
  home_own_spread_expr <- quote(spread_line)
}

schedules <- schedules |>
  mutate(home_own_spread = !!home_own_spread_expr)

# --- Compute per-team implied totals -----------------------------------------

game_odds <- schedules |>
  mutate(
    home_implied_team_total = total_line / 2 - home_own_spread / 2,
    away_implied_team_total = total_line / 2 + home_own_spread / 2
  )

# Sanity check: the two implied totals should always sum back to total_line
# by construction. A failure here means a formula or reshaping bug, not a
# data issue.
check_sums <- game_odds |>
  filter(!is.na(total_line), !is.na(home_own_spread)) |>
  mutate(diff = abs((home_implied_team_total + away_implied_team_total) - total_line))
stopifnot(all(check_sums$diff < 1e-6))

n_missing <- sum(is.na(game_odds$total_line) | is.na(game_odds$spread_line))
if (n_missing > 0) {
  warning(n_missing, " game(s) missing total_line and/or spread_line - implied_team_total left as NA")
}

message("Sample rows (first 5 completed games), for a manual gut-check against known lines:")
print(
  game_odds |>
    filter(!is.na(total_line), !is.na(spread_line)) |>
    select(season, week, home_team, away_team, spread_line, total_line, home_implied_team_total, away_implied_team_total) |>
    head(5)
)

# --- Reshape to team-game grain and write ------------------------------------

team_game_odds <- game_odds |>
  select(season, week, game_id, home_team, away_team, home_implied_team_total, away_implied_team_total) |>
  pivot_longer(
    cols = c(home_team, away_team),
    names_to = "side",
    values_to = "posteam"
  ) |>
  mutate(
    implied_team_total = if_else(side == "home_team", home_implied_team_total, away_implied_team_total)
  ) |>
  select(season, week, game_id, posteam, implied_team_total)

stopifnot(!anyDuplicated(team_game_odds[c("season", "week", "game_id", "posteam")]))

write_csv(team_game_odds, "data/team_game_odds.csv")
message("Wrote data/team_game_odds.csv (", nrow(team_game_odds), " rows)")
