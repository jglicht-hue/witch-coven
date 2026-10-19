# Fits the new model and writes the two data files the weekly run reads
# (09n_new_model.R). Added 2026-10-06 (to-do #31b). RUN BY HAND, once before
# each season (and whenever the model is changed); the scheduled weekly run
# does NOT run this file - it only applies the stored weights.
#
# WHAT IT NEEDS: nflverse play-by-play for 2011 to last season and the schedule
# file in data/raw/ (00_nflverse_data.R's layout), and the production scripts
# 08_points_distribution.R, 09_weekly_inputs.R and 09n_new_model.R in the
# working folder. It takes about 15 minutes, most of it step 2.
#
# HOW IT WAS RUN ON 2026-10-06: steps 1-6 are the research scripts that built
# the data, exactly as they were run on 2026-10-05/06, in this order (each
# reads the files the earlier ones wrote; file names are the workspace's).
# Step 7 was re-run on its own from those files and wrote the stored data files.
# The file has not been run top to bottom as one script.
#
#   STEP 1  t25_build.R         kicker and team-game history from 2011 (the pre-game top-16 flag) and 4th downs
#   STEP 2  t26_build_inputs.R  weekly inputs for every week of 2016-2025, as a live run would have had them
#                               (run once per season: Rscript ... <season>)
#   STEP 3  XP attempts per team-game (from t28_audit.R)
#   STEP 4  t29_build.R         the ten-season team-game table
#   STEP 5  t31_build.R         4th downs at the opponent's 41 or closer, with each team-game's inputs
#   STEP 6  t36_build.R         makes by range per team-game; roof history (from t37.R)
#   STEP 7  fit and write the data files
#   STEP 8  store the self-test values
#
# BEFORE THE NEXT SEASON: set the last season in the year ranges below
# (2025 -> 2026) and S in step 7 (2026 -> 2027), and check the roof values of
# the newest seasons before using them for the closed shares (2020, 2024 and
# 2025 show no open roof at all in the schedule file and are left out).
# See claude/39_new_model_build_log.md.

stop("Run the steps one at a time; see the header.")

# ===================== STEP 1: t25_build.R =====================
# #23 Does long-range accuracy raise long attempts? Build step (2026-10-05).
suppressMessages({library(dplyr); library(tidyr); library(readr)})
YEARS <- 2011:2025
fix <- function(x) recode(x, OAK = "LV", SD = "LAC", STL = "LA", .default = x)
kicks <- list(); fourth <- list()
for (y in YEARS) {
  p <- readRDS(sprintf("data/raw/play_by_play_%d.rds", y))
  kicks[[as.character(y)]] <- p |> filter(field_goal_attempt == 1 | extra_point_attempt == 1, !is.na(posteam)) |>
    transmute(season, week, game_id, season_type, posteam = fix(posteam), kicker_player_id, kicker_player_name,
              fg = field_goal_attempt == 1, dist = kick_distance, made = field_goal_result == "made",
              xp_good = extra_point_attempt == 1 & extra_point_result == "good")
  fourth[[as.character(y)]] <- p |> filter(season_type == "REG", down == 4, yardline_100 >= 22, yardline_100 <= 41,
                                           play_type %in% c("field_goal", "punt", "pass", "run")) |>
    transmute(season, week, game_id, posteam = fix(posteam), yardline_100, ydstogo, score_differential,
              half_seconds_remaining, qtr, kicked = as.integer(field_goal_attempt == 1))
  rm(p); gc(verbose = FALSE)
}
kicks <- bind_rows(kicks); fourth <- bind_rows(fourth)
sched <- readRDS("data/raw/games.rds") |> filter(season %in% YEARS) |>
  mutate(home_team = fix(home_team), away_team = fix(away_team))
fgk <- kicks |> filter(fg, !is.na(kicker_player_id), !is.na(dist)) |> mutate(ord = season * 100 + week, long = dist >= 40)

# League 40+ make rate over the 3 seasons before each season
lg <- fgk |> filter(long) |> group_by(season) |> summarise(a = n(), m = sum(made), .groups = "drop")
L <- sapply(YEARS, function(s) { x <- lg[lg$season %in% (s - 3):(s - 1), ]; if (nrow(x)) sum(x$m) / sum(x$a) else NA })
names(L) <- YEARS; L["2011"] <- lg$m[lg$season == 2011] / lg$a[lg$season == 2011]

# Kicker-game log and decayed 40+ makes / attempts
kg <- fgk |> group_by(kicker_player_id, season, week, ord, game_id, posteam) |>
  summarise(tot = n(), a40 = sum(long), m40 = sum(long & made), a4049 = sum(dist >= 40 & dist <= 49), m4049 = sum(dist >= 40 & dist <= 49 & made), .groups = "drop") |> arrange(kicker_player_id, ord)
run_after <- function(x, hl) { d <- 0.5^(1 / hl); r <- 0; out <- numeric(length(x)); for (i in seq_along(x)) { r <- d * (r + x[i]); out[i] <- r }; out }
kg <- kg |> group_by(kicker_player_id) |> mutate(da12 = run_after(a40, 12), dm12 = run_after(m40, 12),
  da32 = run_after(a40, 32), dm32 = run_after(m40, 32), career_a40 = cumsum(a40), da4049 = run_after(a4049, 12), dm4049 = run_after(m4049, 12)) |> ungroup()

# Team-games (regular season), outcomes, kicker assignment
reg <- sched |> filter(game_type == "REG", !is.na(result))
tg <- bind_rows(reg |> transmute(season, week, game_id, posteam = home_team, roof),
                reg |> transmute(season, week, game_id, posteam = away_team, roof)) |>
  mutate(ord = season * 100 + week, dome = as.integer(roof %in% c("dome", "closed")))
cnt <- kicks |> group_by(game_id, posteam) |>
  summarise(att_4049 = sum(fg & dist >= 40 & dist <= 49, na.rm = TRUE), att_50 = sum(fg & dist >= 50, na.rm = TRUE),
            att_039 = sum(fg & dist <= 39, na.rm = TRUE),
            fpts = sum(ifelse(fg, ifelse(made, ifelse(dist >= 50, 5, ifelse(dist >= 40, 4, 3)), -1), as.integer(xp_good)), na.rm = TRUE),
            .groups = "drop")
tg <- tg |> left_join(cnt, by = c("game_id", "posteam")) |>
  mutate(across(c(att_4049, att_50, att_039, fpts), ~ replace_na(.x, 0)), att_40p = att_4049 + att_50)
primary <- kg |> group_by(game_id, posteam) |> slice_max(tot, n = 1, with_ties = FALSE) |> ungroup() |>
  select(game_id, posteam, ord, kicker_player_id)
tg <- tg |> left_join(primary |> select(-ord), by = c("game_id", "posteam"))
pr_by_team <- split(primary, primary$posteam)
for (i in which(is.na(tg$kicker_player_id))) {
  p <- pr_by_team[[tg$posteam[i]]]; p <- p[p$ord < tg$ord[i], ]
  if (nrow(p)) tg$kicker_player_id[i] <- p$kicker_player_id[which.max(p$ord)]
}
tg <- tg |> filter(!is.na(kicker_player_id))
state_before <- function(log, cols) {
  out <- matrix(0, nrow(tg), length(cols), dimnames = list(NULL, cols))
  for (k in unique(tg$kicker_player_id)) {
    vi <- which(tg$kicker_player_id == k); li <- which(log$kicker_player_id == k); if (!length(li)) next
    pos <- findInterval(tg$ord[vi] - 0.5, log$ord[li]); ok <- pos > 0
    out[vi[ok], ] <- as.matrix(log[li[pos[ok]], cols]) }
  out }
s <- state_before(kg, c("da12", "dm12", "da32", "dm32", "career_a40", "da4049", "dm4049"))
lg49 <- fgk |> filter(dist >= 40, dist <= 49) |> group_by(season) |> summarise(a = n(), m = sum(made), .groups = "drop")
L49 <- sapply(YEARS, function(s) { x <- lg49[lg49$season %in% (s - 3):(s - 1), ]; if (nrow(x)) sum(x$m) / sum(x$a) else NA }); names(L49) <- YEARS
L49["2011"] <- lg49$m[lg49$season == 2011] / lg49$a[lg49$season == 2011]
Ls <- L[as.character(tg$season)]
tg$acc12 <- (s[, "dm12"] + 5 * Ls) / (s[, "da12"] + 5) - Ls
tg$acc32 <- (s[, "dm32"] + 5 * Ls) / (s[, "da32"] + 5) - Ls
tg$prior_a40 <- s[, "career_a40"]; tg$lg40 <- Ls
tg$r4049 <- (s[, "dm4049"] + 5 * L49[as.character(tg$season)]) / (s[, "da4049"] + 5)
# Pre-game top 16 (06b's rule) on the long table
pts <- tg |> select(kicker_player_id, ord, fpts) |> arrange(kicker_player_id, ord) |> group_by(kicker_player_id) |>
  mutate(d_pts = run_after(fpts, 12), d_g = run_after(rep(1, n()), 12)) |> ungroup()
sp <- state_before(pts, c("d_pts", "d_g")); lgp <- mean(tg$fpts)
tg$ppg_pre <- ifelse(sp[, 2] > 0, (sp[, 1] + 4 * lgp) / (sp[, 2] + 4), NA)
tg <- tg |> group_by(season, week) |> mutate(top16pre = !is.na(ppg_pre) & rank(-ppg_pre, ties.method = "first", na.last = "keep") <= 16) |>
  ungroup() |> mutate(top16pre = replace_na(top16pre, FALSE))
fourth <- fourth |> inner_join(tg |> select(game_id, posteam, dome, acc12, acc32, top16pre, kicker_player_id), by = c("game_id", "posteam"))
saveRDS(tg, "t25_tg.rds"); saveRDS(fourth, "t25_fourth.rds")
cat("team-games 2011-2025:", nrow(tg), "; 2016-2025:", sum(tg$season >= 2016), "; top16pre 2016-25:", sum(tg$season >= 2016 & tg$top16pre), "\n")
cat("4th downs in long FG range 2016-2025:", sum(fourth$season >= 2016), " kicked share", round(mean(fourth$kicked[fourth$season >= 2016]), 3), "\n")
print(round(L, 3))
print(tg |> filter(season >= 2016) |> group_by(season) |> summarise(att40 = mean(att_40p), dome = mean(dome), sd12 = sd(acc12), sd32 = sd(acc32)) |> as.data.frame() |> round(3))
# Check vs production table for 2023-25: att counts and kicker
v <- read_csv("data/volume_model_table.csv", show_col_types = FALSE) |> select(game_id, posteam, p4049 = att_4049, p50 = att_50, pk = kicker_player_id, pdome = is_enclosed, ptop = top16pre)
ck <- inner_join(tg, v, by = c("game_id", "posteam"))
cat("vs production (", nrow(ck), "rows): att mismatch", sum(ck$att_4049 != ck$p4049 | ck$att_50 != ck$p50), "; kicker mismatch", sum(ck$kicker_player_id != ck$pk),
    "; dome mismatch", sum(ck$dome != round(ck$pdome)), "; top16 agree", round(mean(ck$top16pre == ck$ptop), 3), "\n")

# ===================== STEP 2: t26_build_inputs.R (once per season 2016-2025) =====================
# #26 step 1: weekly inputs for one season of the long window, as a live run would have had them (2026-10-05).
# Usage: Rscript t26_build_inputs.R <season>. Writes t26_inputs_<season>.rds.
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
out <- bind_rows(lapply(weeks, function(w) { tord <- S * 100 + w
  # data through the target week only; later results blanked (the target week's kicks are kept so the kicker is who kicked, as in training)
  p <- pbp |> filter(ord <= tord) |> select(-ord)
  s <- sched |> mutate(result = if_else(ord > tord, NA_real_, as.numeric(result))) |> select(-ord)
  build_week_inputs(p, s, S, w) }))
saveRDS(out, sprintf("t26_inputs_%d.rds", S)); cat(S, "rows", nrow(out), "weeks", length(weeks), "\n")

# ===================== STEP 3: XP attempts per team-game (from t28_audit.R) =====================
# #28 (exploratory): do the production coefficients hold on other seasons? Descriptive only - no adoption test.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
fix <- function(x) recode(x, OAK = "LV", SD = "LAC", STL = "LA", .default = x)
if (!file.exists("t28_xp.rds")) {
  xp <- bind_rows(lapply(2016:2025, function(y) readRDS(sprintf("data/raw/play_by_play_%d.rds", y))[, c("game_id", "posteam", "extra_point_attempt", "season_type")] |>
    filter(extra_point_attempt == 1, season_type == "REG") |> mutate(posteam = fix(posteam)) |> count(game_id, posteam, name = "xp_attempts")))
  saveRDS(xp, "t28_xp.rds") }
xp <- readRDS("t28_xp.rds")

# ===================== STEP 4: t29_build.R =====================
# #29 step 1: ten-season test table (team-games 2016-2025 with live-style inputs and outcomes) and 4th-down plays for the decision model.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
inp <- bind_rows(lapply(2016:2025, function(s) readRDS(sprintf("t26_inputs_%d.rds", s))))
lt <- readRDS("t25_tg.rds") |> select(game_id, posteam, att_039, att_4049, att_50, fpts, top = top16pre)
xp <- readRDS("t28_xp.rds")
D <- inp |> inner_join(lt, by = c("game_id", "posteam")) |> left_join(xp, by = c("game_id", "posteam")) |>
  mutate(xp_attempts = replace_na(xp_attempts, 0L), att_tot = att_039 + att_4049 + att_50, att_40p = att_4049 + att_50,
         exp_margin = 2 * implied_team_total - total_line, fs = factor(season)) |>
  select(season, week, game_id, posteam, opponent, home_away, kicker_player_id, kicker_player_name, top, fs,
         xp_attempts, att_039, att_4049, att_50, att_tot, att_40p, fpts,
         implied_team_total, total_line, spread_line, exp_margin, is_enclosed, redzone_td_rate_trail8, redzone_trips_per_game_trail8,
         opp_redzone_td_rate_allowed_trail8, coach_long_fg_rate, krate_039, krate_4049, krate_50, krate_40plus, kshare_4049_hlall,
         p_039, p_4049, p_50, p_xp)
stopifnot(!anyNA(D), !anyDuplicated(D[c("game_id", "posteam")]))
# sanity: expected margin has the same sign as the favorite; the two teams' margins cancel
chk <- D |> group_by(game_id) |> summarise(s = sum(exp_margin), t = sum(implied_team_total) - first(total_line), n = n(), .groups = "drop")
cat("team-games", nrow(D), "; top-16", sum(D$top), "; games with both teams", sum(chk$n == 2), "; max |margin sum|", max(abs(chk$s[chk$n == 2])), "; max |implied sum - total|", max(abs(chk$t[chk$n == 2])), "\n")
print(as.data.frame(D |> group_by(season) |> summarise(n = n(), top = sum(top), fpts = mean(fpts), fpts_top = mean(fpts[top]), tot = mean(att_tot)) |> mutate(across(where(is.double), ~ round(.x, 2)))))
plays <- readRDS("t25_fourth.rds") |> filter(season >= 2016) |>
  select(season, week, game_id, posteam, yardline_100, ydstogo, score_differential, half_seconds_remaining, qtr, kicked) |>
  inner_join(D |> select(game_id, posteam, fs, is_enclosed, krate_40plus, krate_4049, krate_50, coach_long_fg_rate), by = c("game_id", "posteam")) |>
  mutate(zone = if_else(yardline_100 <= 31, "A", "B"), q4 = as.integer(qtr >= 4), late = as.integer(half_seconds_remaining <= 120), lytg = log(ydstogo)) |>
  filter(!is.na(score_differential), !is.na(half_seconds_remaining), !is.na(kicked))
cat("4th downs in 40-59 yard range, 2016-2025:", nrow(plays), "; kick share zone A (40-49):", round(mean(plays$kicked[plays$zone == "A"]), 3), " n", sum(plays$zone == "A"),
    "; zone B (50-59):", round(mean(plays$kicked[plays$zone == "B"]), 3), " n", sum(plays$zone == "B"), "\n")
# how many long attempts come from these plays
cat("share of 40-49 attempts that are 4th-down kicks in zone A:", round(sum(plays$kicked[plays$zone == "A"]) / sum(D$att_4049), 3), "; 50+ in zone B:", round(sum(plays$kicked[plays$zone == "B"]) / sum(D$att_50), 3), "\n")
saveRDS(D, "t29_D.rds"); saveRDS(plays, "t29_plays.rds")

# ===================== STEP 5: t31_build.R (data part) =====================
# #31 step 1: 4th downs in field-goal range, all three ranges, 2016-2025 (regular season), with chances per team-game.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
fix <- function(x) recode(x, OAK = "LV", SD = "LAC", STL = "LA", .default = x)
D <- readRDS("t29_D.rds")
COLS <- c("season", "week", "game_id", "play_id", "season_type", "posteam", "down", "yardline_100", "ydstogo", "score_differential", "half_seconds_remaining", "game_seconds_remaining", "qtr",
          "play_type", "field_goal_attempt", "kick_distance", "field_goal_result")
pb <- bind_rows(lapply(2016:2025, function(y) readRDS(sprintf("data/raw/play_by_play_%d.rds", y))[, COLS] |> filter(season_type == "REG", !is.na(posteam)))) |> mutate(posteam = fix(posteam))
fg <- pb |> filter(field_goal_attempt == 1, !is.na(kick_distance)) |> mutate(range = case_when(kick_distance <= 39 ~ "S", kick_distance <= 49 ~ "M", TRUE ~ "L"))
p4 <- pb |> filter(down == 4, yardline_100 <= 41, play_type %in% c("field_goal", "punt", "pass", "run")) |>
  mutate(kicked = as.integer(field_goal_attempt == 1), zone = case_when(yardline_100 <= 21 ~ "S", yardline_100 <= 31 ~ "M", TRUE ~ "L"), lytg = log(ydstogo)) |>
  filter(!is.na(score_differential), !is.na(half_seconds_remaining))
cat("FG attempts 2016-2025:", nrow(fg), "; on 4th down:", round(mean(fg$down == 4, na.rm = TRUE), 3), "; by range (S/M/L):", paste(table(fg$range)[c("S", "M", "L")], collapse = " / "), "\n")
cov <- fg |> mutate(in_zone = down == 4 & ((range == "S" & yardline_100 <= 21) | (range == "M" & yardline_100 >= 22 & yardline_100 <= 31) | (range == "L" & yardline_100 >= 32 & yardline_100 <= 41))) |>
  group_by(range) |> summarise(attempts = n(), from_4th_down_in_zone = mean(in_zone, na.rm = TRUE))
print(as.data.frame(cov))
cat("4th downs in range:", nrow(p4), "; by zone:", paste(table(p4$zone)[c("S", "M", "L")], collapse = " / "), "; kick share by zone:", paste(round(tapply(p4$kicked, p4$zone, mean)[c("S", "M", "L")], 3), collapse = " / "), "\n")
cnt <- p4 |> count(game_id, posteam, zone) |> pivot_wider(names_from = zone, values_from = n, values_fill = 0, names_prefix = "n4_")
D2 <- D |> left_join(cnt, by = c("game_id", "posteam")) |> mutate(across(starts_with("n4_"), ~ replace_na(.x, 0L)))
cat("chances per team-game (mean): short", round(mean(D2$n4_S), 3), " 40-49", round(mean(D2$n4_M), 3), " 50-59", round(mean(D2$n4_L), 3), "\n")
plays <- p4 |> inner_join(D |> select(game_id, posteam, fs, top, is_enclosed, krate_039, krate_40plus, krate_4049, krate_50, coach_long_fg_rate, implied_team_total, exp_margin, total_line,
                                      opp_redzone_td_rate_allowed_trail8, redzone_td_rate_trail8, redzone_trips_per_game_trail8), by = c("game_id", "posteam"))
cat("plays joined to team-game inputs:", nrow(plays), "of", nrow(p4), "\n")
saveRDS(D2, "t31_D.rds"); saveRDS(plays, "t31_plays.rds")

# ===================== STEP 6: t36_build.R, and the roof history =====================
# #36 (2026-10-06): makes by range per team-game (regular season 2016-2025), and each kicker's dome share going into the game.
suppressMessages({library(dplyr); library(tidyr)})
fix <- function(x) recode(x, OAK = "LV", SD = "LAC", STL = "LA", .default = x)
mk <- bind_rows(lapply(2016:2025, function(s) { p <- readRDS(sprintf("data/raw/play_by_play_%d.rds", s)) |> filter(season_type == "REG", !is.na(posteam))
  fg <- p |> filter(field_goal_attempt == 1, !is.na(kick_distance)) |> mutate(posteam = fix(posteam), r = case_when(kick_distance <= 39 ~ "039", kick_distance <= 49 ~ "4049", TRUE ~ "50"), made = as.integer(field_goal_result == "made")) |>
    group_by(game_id, posteam, r) |> summarise(a = n(), m = sum(made), .groups = "drop") |> pivot_wider(names_from = r, values_from = c(a, m), values_fill = 0)
  xp <- p |> filter(extra_point_attempt == 1) |> mutate(posteam = fix(posteam)) |> group_by(game_id, posteam) |> summarise(a_xp = n(), m_xp = sum(extra_point_result == "good", na.rm = TRUE), .groups = "drop")
  full_join(fg, xp, by = c("game_id", "posteam")) }))
D <- readRDS("t31_D.rds") |> left_join(mk, by = c("game_id", "posteam")) |> mutate(across(c(a_039, a_4049, a_50, m_039, m_4049, m_50, a_xp, m_xp), ~ coalesce(.x, 0L)))
cat("attempt counts match the table: 0-39", mean(D$a_039 == D$att_039), " 40-49", mean(D$a_4049 == D$att_4049), " 50+", mean(D$a_50 == D$att_50), " XP", mean(D$a_xp == D$xp_attempts), "\n")
D <- D |> mutate(pts_check = m_xp + 3 * m_039 + 4 * m_4049 + 5 * m_50 - (a_039 - m_039) - (a_4049 - m_4049) - (a_50 - m_50)); cat("points rebuilt from makes equal fpts in", mean(D$pts_check == D$fpts), "of rows; mismatches", sum(D$pts_check != D$fpts), "\n")
# kicker's dome share over his previous 32 games (any team), blended with the league share as if 5 league-average games were added
g <- readRDS("data/raw/games.rds") |> select(game_id, gameday)
D <- D |> left_join(g, by = "game_id") |> arrange(kicker_player_id, gameday, game_id) |> group_by(kicker_player_id) |>
  mutate(k_n = pmin(row_number() - 1L, 32L), k_dome = { cs <- c(0, cumsum(is_enclosed)); i <- seq_along(is_enclosed); cs[i] - cs[pmax(1, i - 32)] }) |> ungroup()
lg <- mean(D$is_enclosed); D <- D |> mutate(dome_share = (k_dome + 5 * lg) / (k_n + 5), dome_rel = is_enclosed - dome_share)
cat("league dome share", round(lg, 3), "| kicker dome share: summary\n"); print(summary(D$dome_share)); cat("dome_rel by venue (top-16, 2019+):\n"); print(tapply(D$dome_rel[D$top & D$season >= 2019], D$is_enclosed[D$top & D$season >= 2019], function(x) round(c(mean = mean(x), sd = sd(x)), 3)))
saveRDS(D |> select(-pts_check), "t36_D.rds")
# roof history (from t37.R): retractable-roof games, seasons whose roof values are usable
g <- readRDS("data/raw/games.rds") |> filter(game_type == "REG", roof %in% c("open", "closed"), !grepl("Maracana", stadium)) |> mutate(closed = as.integer(roof == "closed"), month = as.integer(substr(gameday, 6, 7)), mg = ifelse(month == 9, "Sep", ifelse(month == 10, "Oct", ifelse(month == 11, "Nov", "Dec-Jan"))), st = ifelse(home_team == "SF", "ARI", home_team))
OK <- c(2016:2019, 2021:2023); gg <- g[g$season %in% OK, ]; saveRDS(list(gg = gg), "t37_results.rds")

# ===================== STEP 7 and 8 =====================
# --- STEP 7: fit the new model and write its weights (standalone; reads the three files built above) -----------
# Inputs: t36_D.rds (team-games 2016-2025 with live-style inputs, outcomes, makes by range), t31_plays.rds (4th downs
# at the opponent's 41 or closer), t37_results.rds$gg (retractable-roof games in the seasons whose roof values are usable).
# Output: the two data files 09n_new_model.R reads (new_model_weights.csv, new_model_kick_table.csv).
# S = the season to be projected.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
OUT <- Sys.getenv("NEW_MODEL_OUT", "data"); S <- 2026; CALS <- (S - 3):(S - 1)
D <- readRDS("t36_D.rds") |> filter(season < S) |> mutate(fs = factor(season))
plays <- readRDS("t31_plays.rds") |> filter(season < S) |> mutate(q4 = as.integer(qtr >= 4), late = as.integer(half_seconds_remaining <= 120), fs = factor(season))
stopifnot(!anyNA(D[c("implied_team_total", "exp_margin", "is_enclosed", "krate_40plus", "coach_long_fg_rate")]))
# count models: pre-game top-16 team-games, season fixed effects (the level is reset on the calibration rows by 09n)
tr <- D[D$top, ]; tr$fs <- droplevels(tr$fs)
fxp <- glm(xp_attempts ~ implied_team_total + fs, poisson, tr); f039 <- glm(att_039 ~ implied_team_total + I(implied_team_total^2) + exp_margin + fs, poisson, tr)
W <- list(); V <- list()
nfe <- function(f) { b <- coef(f); k <- !grepl("^fs|Intercept", names(b)); list(b = b[k], V = vcov(f)[k, k, drop = FALSE]) }
x <- nfe(fxp); W$xp <- x$b; V$xp <- x$V; x <- nfe(f039); names(x$b)[names(x$b) == "I(implied_team_total^2)"] <- "implied_team_total_sq"; dimnames(x$V) <- list(names(x$b), names(x$b)); W$att_039 <- x$b; V$att_039 <- x$V
# kick-or-go models: all teams' 4th downs in the zone (M = opponent's 22-31, L = 32-41)
TEAM <- c("is_enclosed", "krate_40plus", "coach_long_fg_rate", "is_enclosed:krate_40plus"); SIT <- c("score_differential", "d4", "d9", "d4:q4"); REF <- list()
for (z in c("M", "L")) {
  pt <- plays[plays$zone == z, ]; pt$fs <- droplevels(pt$fs); pt$d4 <- as.integer(pt$score_differential <= -4); pt$d9 <- as.integer(pt$score_differential <= -9)
  g <- glm(kicked ~ yardline_100 + lytg + score_differential + d4 + d9 + q4 + late + q4:d4 + is_enclosed + krate_40plus + is_enclosed:krate_40plus + coach_long_fg_rate + fs, binomial, pt); b <- coef(g)
  lv <- levels(pt$fs); fe <- c(0, b[paste0("fs", lv[-1])]); names(fe) <- lv; level <- mean(fe[as.character(intersect(CALS, as.integer(lv)))])   # level = average of the last three seasons
  fx <- b[["(Intercept)"]] + level + b[["yardline_100"]] * pt$yardline_100 + b[["lytg"]] * pt$lytg + b[["q4"]] * pt$q4 + b[["late"]] * pt$late
  slope <- coef(lm(score_differential ~ exp_margin, pt))[[2]]   # how the score at a 4th down moves with the pre-game expected margin
  W[[paste0("kick_", z, "_team")]] <- b[TEAM]; V[[paste0("kick_", z, "_team")]] <- vcov(g)[TEAM, TEAM]; W[[paste0("kick_", z, "_situation")]] <- c(b[SIT], score_shift_slope = slope)
  REF[[z]] <- list(fx = fx, sc = pt$score_differential, q4 = pt$q4, m = pt$exp_margin, sit = b[SIT], slope = slope) }
# Exact kick chance for a team term t and an expected margin m: the model's chance averaged over the zone's past
# 4th downs, each play's score shifted by slope x (m - that play's own expected margin). deriv = TRUE gives d/dt.
kick_exact <- function(z, t, m, deriv = FALSE) { r <- REF[[z]]
  vapply(seq_along(t), function(j) { sc <- r$sc + r$slope * (m[j] - r$m)
    p <- plogis(r$fx + r$sit[["score_differential"]] * sc + r$sit[["d4"]] * (sc <= -4) + r$sit[["d9"]] * (sc <= -9) + r$sit[["d4:q4"]] * r$q4 * (sc <= -4) + t[j])
    if (deriv) mean(p * (1 - p)) else mean(p) }, numeric(1)) }
xteam <- function(d) cbind(d$is_enclosed, d$krate_40plus, d$coach_long_fg_rate, d$is_enclosed * d$krate_40plus)
# The kick chance as a table (log-odds) over the team term (rows) and the expected margin (columns); 09n interpolates in it.
# Steps of 0.5 and 4 keep the file small; the table is within 0.003 of the exact chance (a finer one is no closer,
# because the exact chance moves in small steps as past plays cross the score thresholds).
T_GRID <- seq(-4, 10, by = 0.5); M_GRID <- seq(-32, 32, by = 4)
KT <- bind_rows(lapply(c("M", "L"), function(z) { G <- sapply(M_GRID, function(m) qlogis(kick_exact(z, T_GRID, rep(m, length(T_GRID)))))
  colnames(G) <- paste0("m_", M_GRID); bind_cols(tibble(zone = z, team_term = T_GRID), as_tibble(round(G, 5))) }))
kick_table <- function(z, t, m) { G <- as.matrix(KT[KT$zone == z, -(1:2)])     # the same interpolation 09n uses
  ti <- pmin(pmax((t - T_GRID[1]) / 0.5, 0), length(T_GRID) - 1 - 1e-9); i0 <- floor(ti); ft <- ti - i0; mi <- pmin(pmax((m - M_GRID[1]) / 4, 0), length(M_GRID) - 1 - 1e-9); j0 <- floor(mi); fm <- mi - j0
  at <- function(i, j) G[cbind(i + 1, j + 1)]; plogis((1 - ft) * (1 - fm) * at(i0, j0) + ft * (1 - fm) * at(i0 + 1, j0) + (1 - ft) * fm * at(i0, j0 + 1) + ft * fm * at(i0 + 1, j0 + 1)) }
# dome shifts on the make chances: all team-games' kicks; made/missed on dome, the kicker's make chance as the starting point
for (r in c("039", "4049", "50", "xp")) { d <- D[D[[paste0("a_", r)]] > 0, ]; a <- d[[paste0("a_", r)]]; m <- d[[paste0("m_", r)]]
  f <- glm(cbind(m, a - m) ~ x + offset(qlogis(p)), binomial, data.frame(m = m, a = a, x = d$is_enclosed, p = d[[paste0("p_", r)]]))
  W[[paste0("make_shift_", r)]] <- c(shift = coef(f)[["x"]], se = sqrt(vcov(f)["x", "x"]), dome_share = sum(a * d$is_enclosed) / sum(a), kicks = sum(a)) }
# Levels. Calibration rows = pre-game top-16 team-games of the last three seasons. For each part:
#   scale      makes predicted attempts add up to actual attempts on the calibration rows;
#   cal_total  those rows' actual attempts (its Poisson noise goes into the confidence interval);
#   center_* / grad_*  how the calibration total moves when a weight is redrawn (first order), so the
#              confidence interval can reset the level for each draw without the rows themselves.
cal <- D |> filter(season %in% CALS, top)
cnt_level <- function(b, X, y) { e <- exp(as.numeric(X %*% b)); c(scale = sum(y) / sum(e), cal_total = sum(y), setNames(colSums(X * e) / sum(e), paste0("center_", names(b)))) }
W$xp_level <- cnt_level(W$xp, cbind(implied_team_total = cal$implied_team_total), cal$xp_attempts)
W$att_039_level <- cnt_level(W$att_039, cbind(implied_team_total = cal$implied_team_total, implied_team_total_sq = cal$implied_team_total^2, exp_margin = cal$exp_margin), cal$att_039)
for (z in c("M", "L")) { b <- W[[paste0("kick_", z, "_team")]]; tc <- as.numeric(xteam(cal) %*% b); p <- kick_table(z, tc, cal$exp_margin); dp <- kick_exact(z, tc, cal$exp_margin, deriv = TRUE)
  y <- cal[[if (z == "M") "att_4049" else "att_50"]]
  W[[paste0("kick_", z, "_level")]] <- c(scale = sum(y) / sum(p), cal_total = sum(y), setNames(colSums(xteam(cal) * dp) / sum(p), paste0("grad_", TEAM))) }
W$meta <- c(fit_first_season = min(D$season), fit_last_season = max(D$season), level_first_season = min(CALS), level_last_season = max(CALS), team_games_count_models = nrow(tr), plays_M = length(REF$M$fx), plays_L = length(REF$L$fx), calibration_rows = nrow(cal))
# roof: closed share by stadium and month group, blended with the all-stadium share as if 4 games were added
gg <- readRDS("t37_results.rds")$gg; all_share <- mean(gg$closed)
roof <- bind_rows(gg |> group_by(home_team = st, month_group = mg) |> summarise(games = n(), closed = sum(closed), .groups = "drop"), tibble(home_team = "ALL", month_group = "ALL", games = nrow(gg), closed = sum(gg$closed))) |>
  mutate(share = ifelse(home_team == "ALL", closed / games, (closed + 4 * all_share) / (games + 4)))
wl <- bind_rows(lapply(names(W), function(p) tibble(part = p, term = names(W[[p]]), term2 = NA_character_, value = unname(W[[p]]))))
vl <- bind_rows(lapply(names(V), function(p) { m <- V[[p]]; as_tibble(as.data.frame(as.table(m))) |> transmute(part = paste0("vcov_", p), term = as.character(Var1), term2 = as.character(Var2), value = Freq) }))
rl <- roof |> transmute(part = "roof_closed_share", term = home_team, term2 = month_group, value = round(share, 4))
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
write_csv(bind_rows(wl, vl) |> mutate(value = signif(value, 10)) |> bind_rows(rl), file.path(OUT, "new_model_weights.csv"), na = "")
write_csv(KT, file.path(OUT, "new_model_kick_table.csv"))
saveRDS(list(REF = REF, cal = cal, kick_exact = kick_exact, W = W), file.path(OUT, "new_model_exact.rds"))   # for checking the table against the exact values; not used by the weekly run
# --- STEP 8: store the self-test values (run from the folder that holds 08, 09n and the data folder just written) ---
# source("08_points_distribution.R"); source("09n_new_model.R"); nm <- load_new_model(); st <- new_model_selftest_values(nm)
# w <- read_csv("data/new_model_weights.csv", col_types = cols(part = "c", term = "c", term2 = "c", value = "d")) |> filter(part != "selftest")
# write_csv(bind_rows(w, tibble(part = "selftest", term = st$term, term2 = NA_character_, value = signif(st$value, 10))), "data/new_model_weights.csv", na = "")
