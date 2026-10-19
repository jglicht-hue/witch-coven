# Part 1 of 2 for to-do #13 (weather): builds the game weather, team-game
# attempts and kick tables from 2016-2025 nflverse data. Part 2,
# 11b_weather_effects.R, runs the selection and writes the effects (it runs
# in a separate R process because 10 seasons of play-by-play use too much
# memory for the parallel placebo runs). Added 2026-09-28.
#
# Original header (applies to both parts):
# Estimates how game-time weather changes kicker opportunities and accuracy
# (to-do #13). Not part of the weekly run: its output is a
# small adjustment table the Kicker Wizerd agent applies to forecasts.
#
# RULES (set with the user 2026-09-28, before results were seen)
#   Data: regular-season games 2016-2025 (10 seasons - more than the models'
#   3-season window, because weather effects are physical and rare conditions
#   need many games; the weekly models themselves are unchanged).
#   Weather (0 for dome / closed-roof games):
#     wind   : game-time wind, mph
#     cold   : degrees below 40 F, i.e. max(0, 40 - temp)
#     precip : 1 if the play-by-play weather text mentions rain, snow, sleet,
#              drizzle, showers or flurries
#     From nflverse's schedule (temp, wind); blanks filled from the
#     play-by-play weather text. Outdoor games still missing wind or temp are
#     left out.
#   Outcomes and base models:
#     attempts (Poisson, one row per team-game): xp_attempts, att_039,
#       att_4049, att_50 ~ implied_team_total + implied_team_total^2 + is_enclosed
#       (the implied total controls for what the betting line already prices in)
#     makes (logistic, one row per kick): FG made in 0-39 / 40-49 / 50+, and XP
#       made ~ is_enclosed
#   Rule: forward selection per outcome, as in 07c. A term is added if it beats
#   at least 95% of placebo shuffles (share of shuffles doing at least as well
#   < 0.05), where a shuffle permutes that weather variable among each season's
#   outdoor games. Score = leave-one-season-out mean deviance per row (x1000).
#   Among passing terms, the one with the lowest placebo share is added first
#   (ties: larger gain); the rest are retested; stop when none passes.
#
# Writes:
#   data/weather_selection_steps.csv  - every candidate at every step
#   data/weather_effects.csv          - adopted terms: coefficient, rate/odds
#                                       ratio per unit, reference outdoor means
#   data/weather_game_table.csv       - the game-level weather used
#
# USING THE EFFECTS: the weekly models have no weather terms, so their outdoor
# predictions reflect average outdoor weather. An adjustment for a forecast x
# is therefore relative to the average outdoor value x_ref (2023-2025 outdoor
# games, the models' training window): expected attempts x exp(b * (x - x_ref));
# make chance on the log-odds scale + b * (x - x_ref).

suppressMessages({library(dplyr); library(tidyr); library(readr); library(parallel)})
source("00_nflverse_data.R")
set.seed(20260928)

WEATHER_SEASONS <- 2016:2025
REF_SEASONS <- 2023:2025
N_SHUFFLES <- 200
PASS_BAR <- 0.05
N_CORES <- max(1, min(4, detectCores()))
TERMS <- c("wind", "cold", "precip")
PRECIP_PATTERN <- "rain|snow|sleet|drizzle|shower|flurr"
# Added 2026-09-28 (round 2): snow = snow, sleet or flurries; rain = any other precipitation
SNOW_PATTERN <- "snow|sleet|flurr"

pbp <- load_pbp_data(WEATHER_SEASONS)
sched <- load_schedule_data(WEATHER_SEASONS) |> filter(game_type == "REG")

# --- Game-level weather ---------------------------------------------------------------
txt <- pbp |> filter(!is.na(weather)) |> group_by(game_id) |> summarise(weather = dplyr::first(weather), .groups = "drop") |>
  mutate(txt_temp = suppressWarnings(as.numeric(sub(".*Temp: *(-?[0-9]+).*", "\\1", weather))),
         txt_wind = suppressWarnings(as.numeric(sub(".*Wind: *[A-Za-z]* *([0-9]+) *mph.*", "\\1", weather))),
         txt_wind = ifelse(grepl("calm", weather, ignore.case = TRUE) & is.na(txt_wind), 0, txt_wind),
         precip_txt = as.integer(grepl(PRECIP_PATTERN, weather, ignore.case = TRUE)),
         snow_txt = as.integer(grepl(SNOW_PATTERN, weather, ignore.case = TRUE)),
         rain_txt = as.integer(precip_txt == 1 & snow_txt == 0))
games <- sched |> select(season, week, game_id, home_team, away_team, roof, temp, wind, spread_line, total_line, home_score, away_score) |>
  left_join(txt, by = "game_id") |>
  mutate(is_enclosed = case_when(roof %in% c("dome", "closed") ~ 1L, roof %in% c("outdoors", "open") ~ 0L, TRUE ~ NA_integer_),
         temp_f = coalesce(temp, txt_temp), wind_mph = coalesce(wind, txt_wind)) |>
  filter(!is.na(is_enclosed)) |>
  mutate(wind = if_else(is_enclosed == 1, 0, wind_mph),
         cold = if_else(is_enclosed == 1, 0, pmax(0, 40 - temp_f)),
         precip = if_else(is_enclosed == 1, 0L, coalesce(precip_txt, 0L)),
         snow = if_else(is_enclosed == 1, 0L, coalesce(snow_txt, 0L)),
         rain = if_else(is_enclosed == 1, 0L, coalesce(rain_txt, 0L))) |>
  filter(!is.na(wind), !is.na(cold))
message("Games: ", nrow(games), " (outdoor ", sum(games$is_enclosed == 0), "); dropped for missing roof/weather: ",
        nrow(sched) - nrow(games))

# Implied team totals (04's formula; sign inferred per season)
games <- games |> group_by(season) |>
  mutate(sgn = sign(cor(spread_line, home_score - away_score, use = "complete.obs"))) |> ungroup() |>
  mutate(home_margin = sgn * spread_line,
         home_itt = total_line / 2 + home_margin / 2, away_itt = total_line / 2 - home_margin / 2)
write_csv(games |> select(season, week, game_id, is_enclosed, temp_f, wind_mph, wind, cold, precip, rain, snow, weather), "data/weather_game_table.csv")

# --- Team-game attempts table and kick table ------------------------------------------------
fg <- pbp |> filter(field_goal_attempt == 1, game_id %in% games$game_id) |>
  mutate(r = case_when(kick_distance <= 39 ~ "039", kick_distance <= 49 ~ "4049", TRUE ~ "50"),
         made = as.integer(field_goal_result == "made"))
xpk <- pbp |> filter(extra_point_attempt == 1, game_id %in% games$game_id) |>
  mutate(made = as.integer(extra_point_result == "good"))
tg <- bind_rows(games |> transmute(season, game_id, posteam = home_team, implied_team_total = home_itt),
                games |> transmute(season, game_id, posteam = away_team, implied_team_total = away_itt)) |>
  left_join(fg |> count(game_id, posteam, r) |> pivot_wider(names_from = r, values_from = n, names_prefix = "att_", values_fill = 0),
            by = c("game_id", "posteam")) |>
  left_join(xpk |> count(game_id, posteam, name = "xp_attempts"), by = c("game_id", "posteam")) |>
  mutate(across(c(att_039, att_4049, att_50, xp_attempts), ~ replace_na(.x, 0L))) |>
  filter(!is.na(implied_team_total))
kicks <- bind_rows(fg |> transmute(season, game_id, outcome = paste0("make_", r), made),
                   xpk |> transmute(season, game_id, outcome = "make_xp", made))
write_csv(tg, "data/weather_team_games.csv")
write_csv(kicks, "data/weather_kicks.csv")
message("Wrote data/weather_game_table.csv, data/weather_team_games.csv (", nrow(tg), " team-games), data/weather_kicks.csv (",
        nrow(kicks), " kicks)")
