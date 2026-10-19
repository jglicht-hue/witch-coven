# Backtests the fantasy-point projections from 08_points_distribution.R on
# past games. Added 2026-09-26 (to-do #11).
#
# Reads:  data/volume_model_table.csv    (06b)
#         data/kicker_training_table.csv (06, accuracy table)
#         data/kicker_game_accuracy.csv  (05, for the slump adjustment)
#         data/team_game_fg_xp_counts.csv (01, for XP history)
#         models/volume_*_model.rds      (07 - only their formulas are used here)
# Writes: data/points_backtest_games.csv    - one row per held-out team-game
#         data/points_backtest_rules.csv    - the pass/fail rules and results
#         data/points_backtest_summary.csv  - the statistics behind them, per season and overall
#         data/points_backtest_calibration.csv - projected vs actual by projection fifth
#
# DISTRIBUTION: since 2026-09-28 FG attempts depend on the game's XP attempts
# (points_pmf_dep with gamma estimated in each fold; see 12_width_fix_log.md).
#
# RESULT OF THE FIRST RUN (2026-09-26): all four rules pass. See
# claude/08_points_projection_log.md in the project for the numbers.
#
# DESIGN (set 2026-09-26, before seeing results)
#   Scored on pre-game top-16 team-games (the 832 the volume models train on).
#   Leave-one-season-out: the four volume models are refit on the other two
#   seasons, then predict the held-out season. Kicker accuracy inputs are
#   already walk-forward (only games before the one being projected).
#   Rules:
#     1. Projection accuracy: mean squared error lower than both (a) the
#        kicker's own trailing fantasy points per game (kicker_ppg_pre, 06b) and
#        (b) the league average (mean points in the training seasons), in at
#        least 2 of 3 seasons.
#     2. Bias: average projected points within 0.3 of average actual, overall.
#     3. Outcome range honest: share of actual scores inside the middle-80%
#        range within 5 percentage points of the probability the model says the
#        range holds (outcome_range_prob), overall.
#     4. Distribution shape: mean log probability given to the actual score is
#        higher than a single league-wide histogram of scores (training seasons,
#        +0.5 per point value from -5 to 35 so nothing gets zero), in at least 2
#        of 3 seasons.
#   The confidence interval can't be checked against actual scores (a kicker's
#   true average is never observed); its width is reported instead.
#
# INPUTS BUILT HERE (no new modeling choices beyond 05/06b):
#   p_039 / p_4049 / p_50 : 06b's krate_* (identical to 05's long_run_rate_*,
#     checked below) times 05's slump_deficit_ratio for that game (1 if the
#     kicker has no 05 row for the game, i.e. his team attempted no FG).
#   Beta parameters for the CI: the decayed makes and attempts behind krate_*.
#   p_xp : 05's XP method (12-game half-life, shrunk toward the league rate with
#     w = 100 since 2026-09-28, team XPs credited to the
#     game's primary FG kicker, playoffs included), as of before the game;
#     league XP rate if he has no XP history yet.

suppressMessages({library(dplyr); library(tidyr); library(readr)})
source("08_points_distribution.R")
set.seed(20260926)

N_DRAWS <- 2000
HALF_LIFE <- 12
RATE_HALF_LIFE <- 32  # FG make chances (2026-09-29, same as 05 and 09); krate check stays at 12
W <- 5
CI_LEVEL <- 0.90
RANGES <- c("0-39" = "039", "40-49" = "4049", "50+" = "50")
MODEL_NAMES <- c("xp_attempts", "att_039", "att_4049", "att_50")

needed <- c("data/volume_model_table.csv", "data/kicker_training_table.csv", "data/kicker_game_accuracy.csv",
            "data/team_game_fg_xp_counts.csv", file.path("models", paste0("volume_", MODEL_NAMES, "_model.rds")))
if (any(!file.exists(needed))) stop("Missing: ", paste(needed[!file.exists(needed)], collapse = ", "),
                                    " - run 01-07 first.")
vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE)
acc <- read_csv("data/kicker_training_table.csv", show_col_types = FALSE)
k05 <- read_csv("data/kicker_game_accuracy.csv", show_col_types = FALSE)
team_counts <- read_csv("data/team_game_fg_xp_counts.csv", show_col_types = FALSE)
formulas <- lapply(setNames(MODEL_NAMES, MODEL_NAMES), function(o)
  formula(readRDS(file.path("models", paste0("volume_", o, "_model.rds")))))

# --- Kicker state before each team-game (same helpers as 06b) -------------------------
running_after <- function(x, hl) {
  d <- 0.5^(1 / hl); run <- 0; out <- numeric(length(x))
  for (i in seq_along(x)) { run <- d * (run + x[i]); out[i] <- run }
  out
}
state_before <- function(log, cols) {
  out <- matrix(0, nrow(vol), length(cols), dimnames = list(NULL, cols))
  for (k in unique(vol$kicker_player_id)) {
    vi <- which(vol$kicker_player_id == k); li <- which(log$kicker_player_id == k)
    if (!length(li)) next
    pos <- findInterval(vol$ord[vi] - 0.5, log$ord[li]); ok <- pos > 0
    out[vi[ok], ] <- as.matrix(log[li[pos[ok]], cols])
  }
  out
}
vol <- vol |> mutate(ord = season * 100 + week)

# FG: decayed makes/attempts by range -> Beta parameters (mean = krate_*)
kg <- acc |> mutate(r = RANGES[distance_range]) |>
  select(season, week, game_id, posteam, kicker_player_id, r, attempts, makes) |>
  pivot_wider(names_from = r, values_from = c(attempts, makes), values_fill = 0) |>
  mutate(ord = season * 100 + week, tot = attempts_039 + attempts_4049 + attempts_50) |>
  arrange(kicker_player_id, ord)
lg_rate <- sapply(setNames(RANGES, RANGES), function(r) sum(kg[[paste0("makes_", r)]]) / sum(kg[[paste0("attempts_", r)]]))
acc_log <- kg |> group_by(kicker_player_id) |>
  mutate(across(c(starts_with("attempts_"), starts_with("makes_")), ~ running_after(.x, HALF_LIFE), .names = "d_{.col}")) |>
  ungroup()
for (r in RANGES) {
  s <- state_before(acc_log, c(paste0("d_makes_", r), paste0("d_attempts_", r)))
  L <- lg_rate[[r]]
  vol[[paste0("a_", r)]] <- s[, 1] + W * L
  vol[[paste0("b_", r)]] <- (s[, 2] - s[, 1]) + W * (1 - L)
  check <- max(abs(vol[[paste0("a_", r)]] / (vol[[paste0("a_", r)]] + vol[[paste0("b_", r)]]) - vol[[paste0("krate_", r)]]))
  if (check > 1e-9) stop("Rebuilt FG rate for ", r, " doesn't match 06b's krate_", r, " (max diff ", check, ")")
}

# FG make chances use the 32-game fade (2026-09-29): rebuild a_/b_ from it
acc_log_rate <- kg |> group_by(kicker_player_id) |>
  mutate(across(c(starts_with("attempts_"), starts_with("makes_")), ~ running_after(.x, RATE_HALF_LIFE), .names = "d_{.col}")) |>
  ungroup()
for (r in RANGES) {
  s <- state_before(acc_log_rate, c(paste0("d_makes_", r), paste0("d_attempts_", r)))
  L <- lg_rate[[r]]
  vol[[paste0("a_", r)]] <- s[, 1] + W * L
  vol[[paste0("b_", r)]] <- (s[, 2] - s[, 1]) + W * (1 - L)
}

# Slump adjustment from 05 for the game itself (computed from earlier games only)
# Applied slump cut = 05's final_rate / long_run_rate (1 since 2026-09-28, when
# 05 switched the cut off; follows 05 automatically if it's switched back on)
vol <- vol |> left_join(k05 |> transmute(game_id, kicker_player_id, slump_ratio = final_rate_0_39 / long_run_rate_0_39),
                        by = c("game_id", "kicker_player_id")) |>
  mutate(slump_ratio = replace_na(slump_ratio, 1))
for (r in RANGES) vol[[paste0("p_", r)]] <- vol[[paste0("a_", r)]] / (vol[[paste0("a_", r)]] + vol[[paste0("b_", r)]]) * vol$slump_ratio

# XP: 05's method, credited to each team-game's primary FG kicker
primary <- kg |> group_by(game_id, posteam) |> slice_max(tot, n = 1, with_ties = FALSE) |> ungroup() |>
  select(game_id, posteam, ord, kicker_player_id)
xp_log <- primary |> left_join(team_counts |> select(game_id, posteam, xp_attempts, xp_makes), by = c("game_id", "posteam")) |>
  arrange(kicker_player_id, ord) |> group_by(kicker_player_id) |>
  mutate(d_xp_makes = running_after(xp_makes, HALF_LIFE), d_xp_attempts = running_after(xp_attempts, HALF_LIFE)) |>
  ungroup()
lg_xp <- sum(team_counts$xp_makes) / sum(team_counts$xp_attempts)
s <- state_before(xp_log, c("d_xp_makes", "d_xp_attempts"))
XP_SHRINKAGE_W <- 100  # same as 05 (2026-09-28)
vol$p_xp <- (s[, 1] + XP_SHRINKAGE_W * lg_xp) / (s[, 2] + XP_SHRINKAGE_W)
vol$a_xp <- s[, 1] + XP_SHRINKAGE_W * lg_xp
vol$b_xp <- (s[, 2] - s[, 1]) + XP_SHRINKAGE_W * (1 - lg_xp)
xp_check <- vol |> inner_join(k05 |> select(game_id, kicker_player_id, xp_accuracy_rate), by = c("game_id", "kicker_player_id")) |>
  filter(!is.na(xp_accuracy_rate))
xp_mismatch <- sum(abs(xp_check$p_xp - xp_check$xp_accuracy_rate) > 1e-9)
message("XP rate rebuilt from 05's method: ", nrow(xp_check) - xp_mismatch, " of ", nrow(xp_check),
        " team-games match 05's xp_accuracy_rate exactly")

# --- Leave-one-season-out projections --------------------------------------------------
test <- vol |> filter(top16pre)
SEASONS_ <- sort(unique(test$season))
games <- bind_rows(lapply(SEASONS_, function(s) {
  train <- test[test$season != s, ]
  held <- test[test$season == s, ]
  fits <- lapply(formulas, function(f) glm(f, family = poisson, data = train))
  for (o in MODEL_NAMES) held[[paste0("lambda_", sub("att_|_attempts", "", o))]] <- predict(fits[[o]], held, type = "response")
  ci <- projection_ci(fits, held, held, n_draws = N_DRAWS, level = CI_LEVEL)
  gam <- estimate_gamma(fits, train)  # XP/FG dependence (2026-09-28)
  hist_counts <- table(factor(train$fpts, levels = -5:35)) + 0.5
  hist_p <- setNames(as.numeric(hist_counts / sum(hist_counts)), -5:35)
  rows <- lapply(seq_len(nrow(held)), function(i) {
    h <- held[i, ]
    pmf <- points_pmf_dep(h$lambda_xp, h$lambda_039, h$lambda_4049, h$lambda_50, h$p_039, h$p_4049, h$p_50, h$p_xp,
                          gamma = gam)
    sm <- summarise_pmf(pmf)
    p_actual <- pmf$prob[match(h$fpts, pmf$points)]
    c(sm, log_prob_actual = log(max(ifelse(is.na(p_actual), 0, p_actual), 1e-12)),
      log_prob_hist = log(hist_p[[as.character(min(max(h$fpts, -5), 35))]]))
  })
  bind_cols(held |> select(season, week, game_id, posteam, kicker_player_id, fpts, kicker_ppg_pre,
                           starts_with("lambda_"), p_039, p_4049, p_50, p_xp, slump_ratio),
            as_tibble(do.call(rbind, rows)), as_tibble(ci)) |>
    mutate(league_avg = mean(train$fpts))
}))
games <- games |> mutate(in_outcome_range = fpts >= outcome_low & fpts <= outcome_high,
                         ci_width = ci_high - ci_low)

# Sanity: the closed-form projection equals the distribution's average
closed <- with(games, projected_points(lambda_xp, lambda_039, lambda_4049, lambda_50, p_039, p_4049, p_50, p_xp))
stopifnot(max(abs(closed - games$projected_points)) < 1e-6)

# --- Rules ---------------------------------------------------------------------------------
summ <- function(d, label) tibble(
  season = label, team_games = nrow(d),
  mse_model = mean((d$fpts - d$projected_points)^2),
  mse_kicker_ppg = mean((d$fpts - d$kicker_ppg_pre)^2),
  mse_league_avg = mean((d$fpts - d$league_avg)^2),
  mean_projected = mean(d$projected_points), mean_actual = mean(d$fpts),
  bias = mean(d$projected_points) - mean(d$fpts),
  outcome_range_hit_rate = mean(d$in_outcome_range), outcome_range_claimed = mean(d$outcome_range_prob),
  log_score_model = mean(d$log_prob_actual), log_score_histogram = mean(d$log_prob_hist),
  spread_ratio = var(d$fpts - d$projected_points) / mean(d$sd_points^2),
  mean_ci_width = mean(d$ci_width), mean_outcome_range_width = mean(d$outcome_high - d$outcome_low),
  mean_sd_points = mean(d$sd_points))
by_season <- bind_rows(lapply(SEASONS_, function(s) summ(games[games$season == s, ], as.character(s))))
overall <- summ(games, "all")
seasons_beat_ppg <- sum(by_season$mse_model < by_season$mse_kicker_ppg)
seasons_beat_league <- sum(by_season$mse_model < by_season$mse_league_avg)
seasons_beat_hist <- sum(by_season$log_score_model > by_season$log_score_histogram)
rules <- tibble(
  rule = c("1a projection beats kicker's trailing points per game (seasons)",
           "1b projection beats league average (seasons)",
           "2 bias within 0.3 points (overall)",
           "3 middle-80% range honest within 5 points (overall)",
           "4 distribution beats league histogram (seasons)"),
  result = c(paste(seasons_beat_ppg, "of 3"), paste(seasons_beat_league, "of 3"),
             sprintf("%+.3f", overall$bias),
             sprintf("hit %.1f%% vs claimed %.1f%%", 100 * overall$outcome_range_hit_rate, 100 * overall$outcome_range_claimed),
             paste(seasons_beat_hist, "of 3")),
  passes = c(seasons_beat_ppg >= 2, seasons_beat_league >= 2, abs(overall$bias) <= 0.3,
             abs(overall$outcome_range_hit_rate - overall$outcome_range_claimed) <= 0.05, seasons_beat_hist >= 2))

summary_out <- bind_rows(by_season, overall) |> mutate(across(where(is.double), ~ round(.x, 3)))
calibration <- games |> mutate(projection_fifth = ntile(projected_points, 5)) |> group_by(projection_fifth) |>
  summarise(team_games = n(), mean_projected = mean(projected_points), mean_actual = mean(fpts),
            outcome_range_hit_rate = mean(in_outcome_range), .groups = "drop") |>
  mutate(across(where(is.double), ~ round(.x, 3)))

write_csv(games |> mutate(across(where(is.double), ~ round(.x, 4))), "data/points_backtest_games.csv")
write_csv(bind_rows(summary_out |> mutate(section = "stats"), .id = NULL), "data/points_backtest_summary.csv")
write_csv(rules, "data/points_backtest_rules.csv")
write_csv(calibration, "data/points_backtest_calibration.csv")
message("\nBacktest on ", nrow(games), " pre-game top-16 team-games (leave-one-season-out):")
print(as.data.frame(rules))
print(as.data.frame(summary_out))
print(as.data.frame(calibration))
message("Wrote data/points_backtest_games.csv, data/points_backtest_summary.csv, ",
        "data/points_backtest_rules.csv, data/points_backtest_calibration.csv")
