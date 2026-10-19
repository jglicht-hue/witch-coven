# Confirms that 09_weekly_inputs.R reproduces the training tables exactly.
# Added 2026-09-26. Not part of the weekly run; rerun it whenever 02, 05, 06b
# or 09 changes.
#
# Runs build_week_inputs() on past weeks of the three training seasons, with
# the same data the training tables were built from, and compares every
# predictor against data/volume_model_table.csv (06b), and the slump and XP
# inputs against data/kicker_game_accuracy.csv (05). Past games use 06b's
# kicker rule, so the kicker is the same as in training.
#
# Writes data/weekly_inputs_check.csv (one row per column checked: rows
# compared, rows differing, largest difference). Stops with an error if any
# value differs by more than 1e-9.

suppressMessages({library(dplyr); library(readr)})
source("00_nflverse_data.R")
source("09_weekly_inputs.R")

CHECK_SEASONS <- 2023:2025
CHECK_WEEKS <- if (exists("CHECK_WEEKS_OVERRIDE")) CHECK_WEEKS_OVERRIDE else
  expand.grid(week = 1:18, season = CHECK_SEASONS)[, c("season", "week")]

pbp <- load_pbp_data(CHECK_SEASONS)
sched <- load_schedule_data(CHECK_SEASONS)
vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE)
k05 <- read_csv("data/kicker_game_accuracy.csv", show_col_types = FALSE)

built <- bind_rows(lapply(seq_len(nrow(CHECK_WEEKS)), function(i) {
  b <- build_week_inputs(pbp, sched, CHECK_WEEKS$season[i], CHECK_WEEKS$week[i])
  b |> select(-any_of(c("home_coach", "away_coach")))
}))
message("Built ", nrow(built), " team-games across ", nrow(CHECK_WEEKS), " weeks")

COLS <- c("implied_team_total", "is_enclosed", "redzone_td_rate_trail8", "redzone_trips_per_game_trail8",
          "opp_redzone_td_rate_allowed_trail8", "coach_long_fg_rate", "krate_039", "krate_4049", "krate_50",
          "krate_40plus", "kshare_4049_hlall", "kicker_ppg_pre", "top16pre")
j <- inner_join(built, vol, by = c("game_id", "posteam"), suffix = c("_new", "_train"))
row_check <- tibble(column = c("team-games in both", "only in 09 output", "only in training table", "same kicker"),
                    rows_compared = c(nrow(j), nrow(anti_join(built, vol, by = c("game_id", "posteam"))),
                                      nrow(anti_join(vol |> filter(paste(season, week) %in% paste(CHECK_WEEKS$season, CHECK_WEEKS$week)),
                                                     built, by = c("game_id", "posteam"))),
                                      sum(j$kicker_player_id_new == j$kicker_player_id_train)),
                    rows_differing = NA_integer_, max_abs_diff = NA_real_)
col_check <- bind_rows(lapply(COLS, function(cn) {
  a <- as.numeric(j[[paste0(cn, "_new")]]); b <- as.numeric(j[[paste0(cn, "_train")]])
  d <- abs(a - b); d[is.na(a) != is.na(b)] <- Inf; d[is.na(a) & is.na(b)] <- 0
  tibble(column = cn, rows_compared = length(d), rows_differing = sum(d > 1e-9), max_abs_diff = max(d))
}))
k <- inner_join(built, k05, by = c("game_id", "kicker_player_id"))
extra <- tibble(
  column = c("slump_test_ratio vs 05 slump_deficit_ratio", "p_xp vs 05 xp_accuracy_rate"),
  rows_compared = c(nrow(k), sum(!is.na(k$xp_accuracy_rate))),
  rows_differing = c(sum(abs(k$slump_test_ratio - k$slump_deficit_ratio) > 1e-9),
                     sum(abs(k$p_xp - k$xp_accuracy_rate) > 1e-9, na.rm = TRUE)),
  max_abs_diff = c(max(abs(k$slump_test_ratio - k$slump_deficit_ratio)),
                   max(abs(k$p_xp - k$xp_accuracy_rate), na.rm = TRUE)))
check <- bind_rows(row_check, col_check, extra)
write_csv(check, "data/weekly_inputs_check.csv")
print(as.data.frame(check))
bad <- check |> filter(!is.na(rows_differing), rows_differing > 0)
if (nrow(bad) || row_check$rows_compared[2] > 0 || row_check$rows_compared[3] > 0 ||
    row_check$rows_compared[4] != row_check$rows_compared[1]) {
  stop("09_weekly_inputs.R does NOT reproduce the training tables - see data/weekly_inputs_check.csv")
}
message("09_weekly_inputs.R reproduces the training tables exactly on every checked column.")
