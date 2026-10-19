# #42 step 1: weekly inputs for one season, as a live run would have had them (same as 07n step 2 / t26),
# also keeping the league rates each week used. Usage: Rscript t42_build_inputs.R <season>. Writes t42/inputs_<season>.rds.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
source("09_weekly_inputs.R")
S <- as.integer(commandArgs(TRUE)[1])
fix <- function(x) recode(x, OAK = "LV", SD = "LAC", STL = "LA", .default = x)
COLS <- c("season", "week", "game_id", "play_id", "season_type", "posteam", "defteam", "fixed_drive", "drive_inside20", "fixed_drive_result", "down",
          "yardline_100", "field_goal_attempt", "extra_point_attempt", "field_goal_result", "extra_point_result", "kick_distance",
          "kicker_player_id", "kicker_player_name")
pbp <- bind_rows(lapply((S - 3):S, function(y) readRDS(sprintf("data/raw/play_by_play_%d.rds", y))[, COLS])) |>
  mutate(posteam = fix(posteam), defteam = fix(defteam), ord = season * 100 + week)
sched <- readRDS("data/raw/games.rds") |> filter(season %in% (S - 3):S) |>
  mutate(home_team = fix(home_team), away_team = fix(away_team), ord = season * 100 + week)
weeks <- sort(unique(sched$week[sched$season == S & sched$game_type == "REG" & !is.na(sched$result)]))
KEEP <- c("season", "week", "game_id", "posteam", "opponent", "kicker_player_id", "kicker_player_name", "top16pre", "actual_points",
          "implied_team_total", "total_line", "spread_line", "implied_imputed", "is_enclosed", "roof_unknown", "krate_40plus", "coach_long_fg_rate",
          "a_039", "b_039", "a_4049", "b_4049", "a_50", "b_50", "p_039", "p_4049", "p_50", "p_xp", "a_40plus", "b_40plus")
out <- bind_rows(lapply(weeks, function(w) { tord <- S * 100 + w
  p <- pbp |> filter(ord <= tord) |> select(-ord)
  s <- sched |> mutate(result = if_else(ord > tord, NA_real_, as.numeric(result))) |> select(-ord)
  x <- build_week_inputs(p, s, S, w); lg <- attr(x, "league_averages")
  x[, KEEP] |> mutate(lg_039 = lg[["039"]], lg_4049 = lg[["4049"]], lg_50 = lg[["50"]], lg_40plus = lg[["40plus"]]) }))
dir.create("t42", showWarnings = FALSE)
saveRDS(out, sprintf("t42/inputs_%d.rds", S)); cat(S, "rows", nrow(out), "weeks", length(weeks), "\n")
