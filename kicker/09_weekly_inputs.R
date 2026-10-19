# Builds the model inputs for every team-game in one target week - the
# "going into the week" values of every predictor the volume models (07) and
# the points distribution (08) need. Added 2026-09-26 (to-do #12).
#
# This file only defines functions. 09b (weekly projections) calls
# build_week_inputs() on the current week; 09a (check) calls it on past weeks
# and confirms it reproduces the training tables exactly.
#
# WHY A SEPARATE BUILDER: scripts 01-06b build training tables for three
# completed seasons and write fixed files. The weekly step needs the same
# values for a week that hasn't been played, with this season's games in the
# trailing windows. Rather than change 01-06b, this reimplements their
# calculations for one target week, line for line where possible. 09a proves
# they agree. If 02, 05 or 06b change a formula, the same change must be made
# here, and 09a will fail until it is.
#
# WHAT IS COMPUTED (all using only games before the target week unless noted):
#   implied_team_total   04's formula from nflverse's spread_line/total_line
#                        (these are the lines for the target game itself)
#   is_enclosed          03's rule from the schedule's roof field. Retractable
#                        roofs show as blank until game day: filled with the
#                        league-average share (06's imputation rule) and
#                        flagged in roof_unknown.
#   redzone_td_rate_trail8, redzone_trips_per_game_trail8,
#   opp_redzone_td_rate_allowed_trail8, coach_long_fg_rate    02's method
#   krate_039/4049/50/40plus, kshare_4049_hlall, kicker_ppg_pre, top16pre   06b's method
#   slump_test_ratio     05's slump test run for the target game (the cut it would make)
#   slump_ratio          the cut actually applied: 1 since 2026-09-28 (WK_APPLY_SLUMP)
#   p_039/4049/50        FG make chances: 05's method with a 32-game fade (since 2026-09-29)
#   p_xp                 05's XP method (shrunk toward the league rate, w = 100, since 2026-09-28)
#   a_*/b_*              Beta parameters for the confidence interval (as in 08a)
#
# KICKER FOR THE TARGET GAME: for a game already played, the team's primary FG
# kicker in it (06b's rule). For an unplayed game, the last kicker to attempt
# an FG or XP for the team (kicker_source = "last_kicked"). Injuries, cuts and
# signings since then are NOT in the data - confirm the starter elsewhere.
#
# LEAGUE AVERAGES (shrinkage targets) are computed over everything in `pbp`,
# as in 02, 05 and 06b. For the weekly run that is the three training seasons
# plus this season to date, so they differ slightly from training.

suppressMessages({library(dplyr); library(tidyr); library(slider)})

WK_RANGES <- c("0-39" = "039", "40-49" = "4049", "50+" = "50")
WK_HALF_LIFE <- 12; WK_W <- 5; WK_TOP_N <- 16; WK_TOP_PRE_W <- 4
WK_RATE_HALF_LIFE <- 32       # FG make chances (p_*, a_/b_ for the CI, slump test): 32 games since
                              # 2026-09-29, same as 05. krate_* (volume features), XP and points per
                              # game stay at WK_HALF_LIFE = 12, as the volume models were fit.
WK_XP_W <- 100                # XP shrinkage weight, same as 05 (2026-09-28)
WK_APPLY_SLUMP <- FALSE       # slump cut switched off, same as 05 (2026-09-28)
WK_COACH_WINDOW <- 32; WK_COACH_W <- 10; WK_RZ_WINDOW <- 8; WK_LONG_MIN <- 33; WK_LONG_MAX <- 42

.running_after <- function(x, hl) {
  d <- if (is.infinite(hl)) 1 else 0.5^(1 / hl)
  run <- 0; out <- numeric(length(x))
  for (i in seq_along(x)) { run <- d * (run + x[i]); out[i] <- run }
  out
}
# Log values for kicker `k` as of his last log row strictly before `ord`.
.state_before <- function(log, kickers, ords, cols) {
  out <- matrix(0, length(kickers), length(cols), dimnames = list(NULL, cols))
  for (k in unique(kickers[!is.na(kickers)])) {
    vi <- which(kickers == k); li <- which(log$kicker_player_id == k)
    if (!length(li)) next
    pos <- findInterval(ords[vi] - 0.5, log$ord[li]); ok <- pos > 0
    out[vi[ok], ] <- as.matrix(log[li[pos[ok]], cols])
  }
  out
}
.add_trailing_sums <- function(df, window) {
  df |> arrange(group_key, gameday) |> group_by(group_key) |>
    mutate(trail_numerator = slide_dbl(numerator, sum, .before = window, .after = -1, .complete = FALSE),
           trail_denominator = slide_dbl(denominator, sum, .before = window, .after = -1, .complete = FALSE),
           trail_games = slide_dbl(rep(1, dplyr::n()), sum, .before = window, .after = -1, .complete = FALSE)) |>
    ungroup()
}

# pbp: play-by-play for the sample seasons (games played so far).
# sched: nflverse schedules for the sample seasons.
# pregame_kicker_for_played: FALSE (default, used by 09a) gives a target-week
#   game that was already played the kicker who actually kicked in it, as the
#   training tables do. TRUE (used by 09b, added 2026-09-26) gives it the same
#   pre-game rule as unplayed games (last kicker before the week), so its
#   projection is what the model would have said before kickoff.
# Returns one row per team-game in the target week (regular season), with
# actual_points (the team's kicking fantasy points) for games already played.
build_week_inputs <- function(pbp, sched, target_season, target_week, pregame_kicker_for_played = FALSE) {
  tord <- target_season * 100 + target_week
  reg <- sched |> filter(game_type == "REG") |> mutate(ord = season * 100 + week)
  # Backbone: every played regular-season game, plus every game in the target week
  reg <- reg |> filter(!is.na(result) | ord == tord)
  stopifnot(any(reg$ord == tord))
  backbone <- reg |>
    select(season, week, game_id, gameday, home_team, away_team, home_coach, away_coach) |>
    pivot_longer(c(home_team, away_team), names_to = "side", values_to = "posteam") |>
    mutate(coach = if_else(side == "home_team", home_coach, away_coach)) |>
    select(season, week, game_id, gameday, posteam, coach)
  opp <- bind_rows(reg |> transmute(game_id, posteam = home_team, opponent = away_team, home_away = "home"),
                   reg |> transmute(game_id, posteam = away_team, opponent = home_team, home_away = "away"))

  # --- 02: red zone (offense and opponent defense), trailing 8 games ---------------
  drives <- pbp |> filter(!is.na(posteam), !is.na(defteam), !is.na(fixed_drive)) |>
    group_by(season, week, game_id, posteam, defteam, fixed_drive) |>
    summarise(reached_red_zone = any(drive_inside20 == 1, na.rm = TRUE),
              touchdown = dplyr::first(fixed_drive_result) == "Touchdown", .groups = "drop") |>
    filter(reached_red_zone)
  trail_team <- function(by_game, key) {
    backbone |> rename(group_key = posteam) |>
      left_join(by_game |> rename(group_key = all_of(key)), by = c("season", "week", "game_id", "group_key")) |>
      mutate(across(c(numerator, denominator), ~ replace_na(.x, 0))) |>
      .add_trailing_sums(WK_RZ_WINDOW)
  }
  rz_off <- trail_team(drives |> group_by(season, week, game_id, posteam) |>
                         summarise(numerator = sum(touchdown), denominator = n(), .groups = "drop"), "posteam") |>
    transmute(game_id, posteam = group_key,
              redzone_td_rate_trail8 = if_else(trail_denominator == 0, NA_real_, trail_numerator / trail_denominator),
              redzone_trips_per_game_trail8 = if_else(trail_games == 0, NA_real_, trail_denominator / trail_games))
  rz_def <- trail_team(drives |> group_by(season, week, game_id, defteam) |>
                         summarise(numerator = sum(touchdown), denominator = n(), .groups = "drop"), "defteam") |>
    transmute(game_id, opponent = group_key,
              opp_redzone_td_rate_allowed_trail8 = if_else(trail_denominator == 0, NA_real_, trail_numerator / trail_denominator))
  # Distance-mix windows (02's share_*_trail8) - needed only to find 06's
  # window-start rows, which are left out of the fantasy-points history.
  fg_share_trail <- trail_team(pbp |> filter(field_goal_attempt == 1) |>
                                 group_by(season, week, game_id, posteam) |>
                                 summarise(numerator = 0, denominator = n(), .groups = "drop"), "posteam") |>
    transmute(game_id, posteam = group_key, trail_fg = trail_denominator)

  # --- 02: coach long-range FG rate (team + coach, trailing 32 games, shrunk) -----
  long_zone <- pbp |> filter(down == 4, !is.na(posteam), yardline_100 >= WK_LONG_MIN, yardline_100 <= WK_LONG_MAX) |>
    mutate(went_for_fg = as.integer(field_goal_attempt == 1))
  lg_long <- mean(long_zone$went_for_fg, na.rm = TRUE)
  coach_long <- backbone |> mutate(group_key = paste(posteam, coach, sep = " | ")) |>
    left_join(long_zone |> group_by(season, week, game_id, posteam) |>
                summarise(numerator = sum(went_for_fg, na.rm = TRUE), denominator = n(), .groups = "drop"),
              by = c("season", "week", "game_id", "posteam")) |>
    mutate(across(c(numerator, denominator), ~ replace_na(.x, 0))) |>
    .add_trailing_sums(WK_COACH_WINDOW) |>
    transmute(game_id, posteam, coach_long_fg_rate = (trail_numerator + WK_COACH_W * lg_long) / (trail_denominator + WK_COACH_W))

  # --- 03 / 04: venue and implied team total ----------------------------------------
  played <- reg |> filter(!is.na(result), !is.na(spread_line))
  sign_cor <- cor(played$spread_line, played$home_score - played$away_score)
  home_margin <- if (sign_cor > 0) reg$spread_line else -reg$spread_line
  game_lines <- reg |> transmute(game_id, spread_line, total_line, roof, result,
                                 home_itt = total_line / 2 + home_margin / 2, away_itt = total_line / 2 - home_margin / 2,
                                 is_enclosed = case_when(roof %in% c("dome", "closed") ~ 1, roof %in% c("outdoors", "open") ~ 0,
                                                         TRUE ~ NA_real_))

  tg <- backbone |> left_join(opp, by = c("game_id", "posteam")) |>
    left_join(game_lines, by = "game_id") |>
    mutate(ord = season * 100 + week,
           implied_team_total = if_else(home_away == "home", home_itt, away_itt)) |>
    select(-home_itt, -away_itt) |>
    left_join(rz_off, by = c("game_id", "posteam")) |>
    left_join(rz_def, by = c("game_id", "opponent")) |>
    left_join(coach_long, by = c("game_id", "posteam")) |>
    left_join(fg_share_trail, by = c("game_id", "posteam")) |>
    mutate(window_start = is.na(redzone_td_rate_trail8) | is.na(redzone_trips_per_game_trail8) |
             is.na(opp_redzone_td_rate_allowed_trail8) | trail_fg == 0)
  # 06's imputation: league average over the (non-window-start) team-games
  fill <- tg |> filter(!window_start)
  tg <- tg |> mutate(roof_unknown = is.na(is_enclosed),
                     is_enclosed = if_else(is.na(is_enclosed), mean(fill$is_enclosed, na.rm = TRUE), is_enclosed),
                     implied_imputed = is.na(implied_team_total),
                     implied_team_total = if_else(is.na(implied_team_total), mean(fill$implied_team_total, na.rm = TRUE),
                                                  implied_team_total))

  # --- Kicker logs (01 / 05 / 06b) ---------------------------------------------------------
  kick_pbp <- pbp |> filter(field_goal_attempt == 1, !is.na(kicker_player_id)) |>
    mutate(made = as.integer(field_goal_result == "made"),
           r = case_when(kick_distance <= 39 ~ "039", kick_distance <= 49 ~ "4049", TRUE ~ "50"))
  kg <- kick_pbp |> group_by(season, week, game_id, posteam, kicker_player_id, r) |>
    summarise(attempts = n(), makes = sum(made, na.rm = TRUE), .groups = "drop") |>
    pivot_wider(names_from = r, values_from = c(attempts, makes), values_fill = 0)
  for (col in c(paste0("attempts_", WK_RANGES), paste0("makes_", WK_RANGES))) if (!col %in% names(kg)) kg[[col]] <- 0
  kg <- kg |> mutate(ord = season * 100 + week, tot = attempts_039 + attempts_4049 + attempts_50,
                     attempts_40plus = attempts_4049 + attempts_50, makes_40plus = makes_4049 + makes_50) |>
    arrange(kicker_player_id, ord)

  # Kicker for each team-game: primary FG kicker if the team kicked a FG,
  # else the team's most recent primary FG kicker before (06b)
  primary <- kg |> group_by(game_id, posteam) |> slice_max(tot, n = 1, with_ties = FALSE) |> ungroup() |>
    select(game_id, posteam, ord, kicker_player_id)
  tg <- tg |> left_join(primary |> select(game_id, posteam, kicker_player_id), by = c("game_id", "posteam")) |>
    mutate(kicker_source = if_else(is.na(kicker_player_id), NA_character_, "primary_fg_kicker"))
  for (i in which(is.na(tg$kicker_player_id) & !is.na(tg$result))) {
    p <- primary[primary$posteam == tg$posteam[i] & primary$ord < tg$ord[i], ]
    if (nrow(p)) { tg$kicker_player_id[i] <- p$kicker_player_id[which.max(p$ord)]; tg$kicker_source[i] <- "last_primary_fg_kicker" }
  }
  # Unplayed target-week games: last kicker to attempt an FG or XP for the team
  last_kick <- pbp |> filter((field_goal_attempt == 1 | extra_point_attempt == 1), !is.na(kicker_player_id)) |>
    mutate(ord = season * 100 + week) |> filter(ord < tord) |> arrange(ord, game_id, play_id) |>
    group_by(posteam) |> slice_tail(n = 1) |> ungroup()
  kicker_names <- pbp |> filter(!is.na(kicker_player_id)) |> group_by(kicker_player_id) |>
    summarise(kicker_player_name = dplyr::last(kicker_player_name), .groups = "drop")
  tg$kicker_last_game <- NA_character_
  for (i in which(tg$ord == tord & (is.na(tg$result) | pregame_kicker_for_played))) {
    lk <- last_kick[last_kick$posteam == tg$posteam[i], ]
    if (nrow(lk)) {
      tg$kicker_player_id[i] <- lk$kicker_player_id; tg$kicker_source[i] <- "last_kicked"
      tg$kicker_last_game[i] <- lk$game_id
    }
  }

  # --- Kicker accuracy (05 / 06b): decayed makes/attempts before each game ----------
  lg_rate <- sapply(c(setNames(WK_RANGES, WK_RANGES), `40plus` = "40plus"), function(r)
    sum(kg[[paste0("makes_", r)]]) / sum(kg[[paste0("attempts_", r)]]))
  names(lg_rate) <- c(WK_RANGES, "40plus")
  acc_log <- kg |> group_by(kicker_player_id) |>
    mutate(across(c(starts_with("attempts_"), starts_with("makes_")), ~ .running_after(.x, WK_HALF_LIFE), .names = "d_{.col}")) |>
    ungroup()
  for (r in names(lg_rate)) {
    s <- .state_before(acc_log, tg$kicker_player_id, tg$ord, c(paste0("d_makes_", r), paste0("d_attempts_", r)))
    tg[[paste0("a_", r)]] <- s[, 1] + WK_W * lg_rate[[r]]
    tg[[paste0("b_", r)]] <- (s[, 2] - s[, 1]) + WK_W * (1 - lg_rate[[r]])
    tg[[paste0("krate_", r)]] <- tg[[paste0("a_", r)]] / (tg[[paste0("a_", r)]] + tg[[paste0("b_", r)]])
  }
  # Kicker's share of FG attempts from 40-49, full history (06b's kshare_4049_hlall)
  lg_share_4049 <- sum(kg$attempts_4049) / sum(kg$tot)
  share_log <- kg |> group_by(kicker_player_id) |>
    mutate(d_a4049 = cumsum(attempts_4049), d_tot = cumsum(tot)) |> ungroup()
  s <- .state_before(share_log, tg$kicker_player_id, tg$ord, c("d_a4049", "d_tot"))
  tg$kshare_4049_hlall <- (s[, 1] + WK_W * lg_share_4049) / (s[, 2] + WK_W)

  # FG make chances (p_*) and their Beta parameters (a_/b_, for the CI) use the
  # 32-game fade (05's FG_RATE_HALF_LIFE_GAMES, 2026-09-29); krate_* above stays
  # at 12 because the volume models were fit with it.
  acc_log_rate <- kg |> group_by(kicker_player_id) |>
    mutate(across(c(starts_with("attempts_"), starts_with("makes_")), ~ .running_after(.x, WK_RATE_HALF_LIFE), .names = "d_{.col}")) |>
    ungroup()
  for (r in WK_RANGES) {
    s <- .state_before(acc_log_rate, tg$kicker_player_id, tg$ord, c(paste0("d_makes_", r), paste0("d_attempts_", r)))
    tg[[paste0("a_", r)]] <- s[, 1] + WK_W * lg_rate[[r]]
    tg[[paste0("b_", r)]] <- (s[, 2] - s[, 1]) + WK_W * (1 - lg_rate[[r]])
  }

  # Slump adjustment for each team-game (05's test, pooled over the kicker's
  # earlier games this season that had an FG attempt)
  rate_before <- acc_log_rate |> group_by(kicker_player_id) |>
    mutate(across(c(d_makes_039, d_attempts_039, d_makes_4049, d_attempts_4049, d_makes_50, d_attempts_50),
                  ~ dplyr::lag(.x, default = 0))) |> ungroup() |>
    mutate(lr_039 = (d_makes_039 + WK_W * lg_rate[["039"]]) / (d_attempts_039 + WK_W),
           lr_4049 = (d_makes_4049 + WK_W * lg_rate[["4049"]]) / (d_attempts_4049 + WK_W),
           lr_50 = (d_makes_50 + WK_W * lg_rate[["50"]]) / (d_attempts_50 + WK_W),
           exp_makes = attempts_039 * lr_039 + attempts_4049 * lr_4049 + attempts_50 * lr_50,
           act_makes = makes_039 + makes_4049 + makes_50)
  tg$slump_test_ratio <- 1; tg$slump_p_value <- NA_real_
  for (i in which(!is.na(tg$kicker_player_id))) {
    pool <- rate_before[rate_before$kicker_player_id == tg$kicker_player_id[i] &
                          rate_before$season == tg$season[i] & rate_before$ord < tg$ord[i], ]
    if (nrow(pool) < 2) next
    n_pool <- if (nrow(pool) < 3) 2 else 3; alpha <- if (n_pool == 2) 0.10 else 0.15
    pool <- tail(pool[order(pool$ord), ], n_pool)
    att <- sum(pool$tot); if (att == 0) next
    test <- binom.test(round(sum(pool$act_makes)), att, sum(pool$exp_makes) / att, alternative = "less")
    tg$slump_p_value[i] <- test$p.value
    if (test$p.value < alpha) tg$slump_test_ratio[i] <- sum(pool$act_makes) / sum(pool$exp_makes)
  }
  # slump_test_ratio = the cut 05's test would make; slump_ratio = the cut applied
  tg$slump_ratio <- if (WK_APPLY_SLUMP) tg$slump_test_ratio else 1
  for (r in WK_RANGES) tg[[paste0("p_", r)]] <- tg[[paste0("a_", r)]] / (tg[[paste0("a_", r)]] + tg[[paste0("b_", r)]]) * tg$slump_ratio

  # XP accuracy (05's method: team XPs credited to the game's primary FG kicker)
  team_xp <- pbp |> filter(extra_point_attempt == 1) |>
    group_by(game_id, posteam) |>
    summarise(xp_attempts = n(), xp_makes = sum(extra_point_result == "good", na.rm = TRUE), .groups = "drop")
  lg_xp <- sum(team_xp$xp_makes) / sum(team_xp$xp_attempts)
  xp_log <- primary |> left_join(team_xp, by = c("game_id", "posteam")) |>
    mutate(across(c(xp_attempts, xp_makes), ~ replace_na(.x, 0))) |>
    arrange(kicker_player_id, ord) |> group_by(kicker_player_id) |>
    mutate(d_xp_makes = .running_after(xp_makes, WK_HALF_LIFE), d_xp_attempts = .running_after(xp_attempts, WK_HALF_LIFE)) |>
    ungroup()
  s <- .state_before(xp_log, tg$kicker_player_id, tg$ord, c("d_xp_makes", "d_xp_attempts"))
  tg$p_xp <- (s[, 1] + WK_XP_W * lg_xp) / (s[, 2] + WK_XP_W)
  tg$a_xp <- s[, 1] + WK_XP_W * lg_xp
  tg$b_xp <- (s[, 2] - s[, 1]) + WK_XP_W * (1 - lg_xp)

  # --- Fantasy points per game going into the week, and pre-game top 16 (06b) -------
  team_fg <- pbp |> filter(field_goal_attempt == 1) |> group_by(game_id, posteam) |>
    summarise(fg_attempts = n(), fg_makes = sum(field_goal_result == "made", na.rm = TRUE), .groups = "drop")
  team_mk <- kick_pbp |> group_by(game_id, posteam) |>
    summarise(mk_039 = sum(made[r == "039"]), mk_4049 = sum(made[r == "4049"]), mk_50 = sum(made[r == "50"]), .groups = "drop")
  hist <- tg |> filter(!is.na(result), !window_start) |>
    left_join(team_fg, by = c("game_id", "posteam")) |> left_join(team_mk, by = c("game_id", "posteam")) |>
    left_join(team_xp, by = c("game_id", "posteam")) |>
    mutate(across(c(fg_attempts, fg_makes, mk_039, mk_4049, mk_50, xp_makes), ~ replace_na(.x, 0)),
           fpts = 3 * mk_039 + 4 * mk_4049 + 5 * mk_50 - (fg_attempts - fg_makes) + xp_makes) |>
    filter(!is.na(kicker_player_id))
  pts_log <- hist |> select(kicker_player_id, ord, fpts) |> arrange(kicker_player_id, ord) |>
    group_by(kicker_player_id) |>
    mutate(d_pts = .running_after(fpts, WK_HALF_LIFE), d_games = .running_after(rep(1, n()), WK_HALF_LIFE)) |> ungroup()
  lg_ppg <- mean(hist$fpts)
  s <- .state_before(pts_log, tg$kicker_player_id, tg$ord, c("d_pts", "d_games"))
  tg$kicker_ppg_pre <- ifelse(s[, 2] > 0, (s[, 1] + WK_TOP_PRE_W * lg_ppg) / (s[, 2] + WK_TOP_PRE_W), NA_real_)

  out <- tg |> filter(ord == tord, !window_start) |>
    left_join(hist |> select(game_id, posteam, actual_points = fpts), by = c("game_id", "posteam")) |>
    mutate(ppg_rank = rank(-kicker_ppg_pre, ties.method = "first", na.last = "keep"),
           top16pre = !is.na(ppg_rank) & ppg_rank <= WK_TOP_N) |>
    left_join(kicker_names, by = "kicker_player_id")
  attr(out, "league_averages") <- c(lg_rate, long_fg = lg_long, xp = lg_xp, ppg = lg_ppg)
  out
}


# Projects every team-game of one week (used by 09b for the live run and by
# 13a to rebuild past weeks). Added 2026-09-28 (moved out of 09b unchanged).
# Returns list(out = one row per kicker-game, dist_long = full distributions).
project_week <- function(pbp, sched, season, week, fits, points_gamma, lines_as_of, last_played_week, N_DRAWS = 2000) {
  MODEL_NAMES <- names(fits)
  inputs <- build_week_inputs(pbp, sched, season, week, pregame_kicker_for_played = TRUE)
  league_ppg <- attr(inputs, "league_averages")[["ppg"]]
  proj <- inputs |> mutate(played = !is.na(result))
  if (any(is.na(proj$kicker_player_id))) warning("No kicker found for: ", paste(proj$posteam[is.na(proj$kicker_player_id)], collapse = ", "))
  proj <- proj |> filter(!is.na(kicker_player_id))
  if (any(proj$implied_imputed)) warning("No betting line yet for: ", paste(proj$game_id[proj$implied_imputed], collapse = ", "),
                                         " - league-average implied total used")

  for (o in MODEL_NAMES) proj[[paste0("lambda_", sub("att_|_attempts", "", o))]] <- predict(fits[[o]], proj, type = "response")
  ci <- projection_ci(fits, proj, proj, n_draws = N_DRAWS, level = 0.90)
  dists <- lapply(seq_len(nrow(proj)), function(i) with(proj[i, ],
    points_pmf_dep(lambda_xp, lambda_039, lambda_4049, lambda_50, p_039, p_4049, p_50, p_xp, gamma = points_gamma)))
  summ <- do.call(rbind, lapply(dists, function(d) c(summarise_pmf(d), prob_negative = sum(d$prob[d$points < 0]),
                                                     prob_10plus = sum(d$prob[d$points >= 10]))))

  out <- bind_cols(proj, as_tibble(summ), as_tibble(ci)) |>
    transmute(season, week, game_id, gameday, team = posteam, opponent, home_away, played, actual_points,
              kicker_player_name, kicker_player_id, kicker_source, kicker_last_game,
              ppg_rank, top16pre, kicker_ppg_pre,
              projected_points, ci_low, ci_high, outcome_low, outcome_high, outcome_range_prob, sd_points,
              prob_negative, prob_10plus,
              exp_xp_attempts = lambda_xp, exp_att_039 = lambda_039, exp_att_4049 = lambda_4049, exp_att_50 = lambda_50,
              p_039, p_4049, p_50, p_xp, slump_ratio,
              slump_flagged = slump_test_ratio < 1, slump_test_ratio, slump_p_value,
              implied_team_total, spread_line, total_line, is_enclosed, roof_unknown, implied_imputed,
              lines_as_of = lines_as_of, pbp_through_week = last_played_week, league_ppg = league_ppg) |>
    arrange(desc(projected_points))
  dist_long <- bind_rows(lapply(seq_along(dists), function(i)
    tibble(season = season, week = week, team = proj$posteam[i], kicker_player_name = proj$kicker_player_name[i],
           kicker_player_id = proj$kicker_player_id[i], points = dists[[i]]$points, prob = dists[[i]]$prob)))
  list(out = out, dist_long = dist_long)
}
