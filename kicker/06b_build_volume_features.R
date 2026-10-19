# Builds the kicker-level features and per-range outcomes the volume models
# need, on top of 06's volume table. Added 2026-09-24: this code previously
# lived inside the experiment script (07a); it moved here so the experiments
# (07a, 07c) and the final models (07) all use one copy of it.
#
# Reads:  data/team_game_training_table.csv (06's volume table)
#         data/kicker_training_table.csv    (06's accuracy table)
# Writes: data/volume_model_table.csv - the volume table (one row per team per
#         regular-season game, window-start rows already dropped by 06) plus
#         the columns below.
#
# PER-RANGE OUTCOMES
#   att_039 / att_4049 / att_50 : FG attempts that team-game from 0-39, 40-49
#     and 50+ yards (they sum to fg_attempts); mk_* = makes.
#   fpts : fantasy points the team's kicking produced that game (3/4/5 per
#     make by range, -1 per missed FG, +1 per made XP).
#
# KICKER ASSIGNMENT
#   kicker_player_id : whoever attempted the most FGs for the team that game,
#     or, if the team attempted none, the team's most recent such kicker.
#
# KICKER FEATURES (all walk-forward: only games before the one they're
# attached to, so nothing leaks from the game being predicted)
#   krate_039 / krate_4049 / krate_50 : make rate by range, script 05's
#     method (12-game half-life, shrunk toward the league rate, w = 5).
#     Games with >= 1 FG attempt, playoffs included, matching 05.
#   krate_40plus : same, pooling 40-49 and 50+ kicks into one long-range rate.
#   kvol_<range>_hl<12|24|48|all> : FG attempts PER GAME in that range, with a
#     12/24/48-game half-life or the full history in the window, shrunk toward
#     the league per-game average (w = 5 games). Includes his teams' zero-FG
#     games. kvol_total_hl12 = all ranges combined. (Experiment-only: none of
#     these predicted anything; kept so 07a can reproduce those tests.)
#   kshare_<range>_hl<12|24|48|all> : share of his FG attempts in that range,
#     shrunk toward the league share (w = 5 attempts). Experiment-only too.
#
# FANTASY-RELEVANT KICKERS
#   kicker_ppg_pre : the kicker's fantasy points per game over his earlier
#     games in this table (12-game half-life, shrunk toward the league average
#     with w = 4 games). NA if he has no earlier game in the table.
#   top16pre : TRUE if kicker_ppg_pre ranks top 16 among that week's kickers -
#     the "pre-game top 16", i.e. the kickers a fantasy manager would roster
#     going into the week. Uses only information available before kickoff.
#     Decided 2026-09-24: the volume models are trained and judged on these
#     team-games. History starts with 2023 week 2 (window-start rows are
#     dropped in 06) and excludes playoffs.
#   top16 : TRUE if the kicker finished top 16 in fantasy points THAT SEASON.
#     Picked using the season's own results, so it's kept only so 07a can
#     reproduce earlier comparisons - not used for any decision.

suppressMessages({library(dplyr); library(tidyr); library(readr)})

VOL_PATH <- "data/team_game_training_table.csv"
ACC_PATH <- "data/kicker_training_table.csv"
if (!file.exists(VOL_PATH) || !file.exists(ACC_PATH)) {
  stop("Missing ", VOL_PATH, " and/or ", ACC_PATH, " - run 06_join_training_data.R first.")
}
vol <- read_csv(VOL_PATH, show_col_types = FALSE) |> mutate(ord = season * 100 + week)
acc <- read_csv(ACC_PATH, show_col_types = FALSE)

TOP_N <- 16
RANGES <- c("0-39" = "039", "40-49" = "4049", "50+" = "50")
HALF_LIFE <- 12          # games, kicker accuracy (same as script 05)
W <- 5                   # shrinkage weight, kicker accuracy/volume/share
TOP_PRE_HALF_LIFE <- 12  # games, fantasy points per game for the pre-game top 16
TOP_PRE_W <- 4           # shrinkage weight (games) for fantasy points per game

# --- Per-range outcomes per team-game -------------------------------------------
rng <- acc |> filter(game_id %in% vol$game_id) |>
  group_by(game_id, posteam, distance_range) |>
  summarise(att = sum(attempts), mk = sum(makes), .groups = "drop") |>
  mutate(r = RANGES[distance_range]) |> select(-distance_range) |>
  pivot_wider(names_from = r, values_from = c(att, mk), values_fill = 0)
vol <- vol |> left_join(rng, by = c("game_id", "posteam")) |>
  mutate(across(matches("^(att|mk)_"), ~ replace_na(.x, 0)))
stopifnot(all(vol$att_039 + vol$att_4049 + vol$att_50 == vol$fg_attempts))

# --- Kicker-game log (games with >= 1 FG attempt, playoffs included) ---------------
kg <- acc |> mutate(r = RANGES[distance_range]) |>
  select(season, week, game_id, posteam, kicker_player_id, r, attempts, makes) |>
  pivot_wider(names_from = r, values_from = c(attempts, makes), values_fill = 0) |>
  mutate(ord = season * 100 + week, tot = attempts_039 + attempts_4049 + attempts_50,
         attempts_40plus = attempts_4049 + attempts_50, makes_40plus = makes_4049 + makes_50) |>
  arrange(kicker_player_id, ord)

# --- Assign a kicker to every team-game ----------------------------------------------
primary <- kg |> group_by(game_id, posteam) |> slice_max(tot, n = 1, with_ties = FALSE) |>
  ungroup() |> select(game_id, posteam, ord, kicker_player_id)
vol <- vol |> left_join(primary |> select(game_id, posteam, kicker_player_id), by = c("game_id", "posteam"))
for (i in which(is.na(vol$kicker_player_id))) {
  p <- primary[primary$posteam == vol$posteam[i] & primary$ord < vol$ord[i], ]
  if (nrow(p)) vol$kicker_player_id[i] <- p$kicker_player_id[which.max(p$ord)]
}
n_unassigned <- sum(is.na(vol$kicker_player_id))
if (n_unassigned > 0) warning(n_unassigned, " team-games have no identifiable kicker - dropped")
vol <- vol |> filter(!is.na(kicker_player_id))

# --- Decayed running sums, and state strictly before each team-game -------------------
running_after <- function(x, hl) {
  d <- if (is.infinite(hl)) 1 else 0.5^(1 / hl)
  run <- 0; out <- numeric(length(x))
  for (i in seq_along(x)) { run <- d * (run + x[i]); out[i] <- run }
  out
}
# For each team-game, the kicker's log values as of his last game strictly
# before it (0 if none).
state_before <- function(log, cols) {
  out <- matrix(0, nrow(vol), length(cols), dimnames = list(NULL, cols))
  for (k in unique(vol$kicker_player_id)) {
    vi <- which(vol$kicker_player_id == k)
    li <- which(log$kicker_player_id == k)
    if (!length(li)) next
    pos <- findInterval(vol$ord[vi] - 0.5, log$ord[li])  # number of log games strictly before
    ok <- pos > 0
    out[vi[ok], ] <- as.matrix(log[li[pos[ok]], cols])
  }
  out
}

# Accuracy by range (script 05 method), plus pooled 40+
RATE_KEYS <- c(RANGES, "40plus")
lg_rate <- sapply(setNames(RATE_KEYS, RATE_KEYS), function(r)
  sum(kg[[paste0("makes_", r)]]) / sum(kg[[paste0("attempts_", r)]]))
acc_log <- kg |> group_by(kicker_player_id) |>
  mutate(across(c(starts_with("attempts_"), starts_with("makes_")),
                ~ running_after(.x, HALF_LIFE), .names = "d_{.col}")) |> ungroup()
for (r in RATE_KEYS) {
  s <- state_before(acc_log, c(paste0("d_makes_", r), paste0("d_attempts_", r)))
  vol[[paste0("krate_", r)]] <- (s[, 1] + W * lg_rate[[r]]) / (s[, 2] + W)
}

# Volume and share by range: game log adds zero-FG team-games
zero_games <- vol |> filter(fg_attempts == 0) |>
  transmute(kicker_player_id, ord, attempts_039 = 0, attempts_4049 = 0, attempts_50 = 0, tot = 0)
vol_log <- bind_rows(kg |> select(kicker_player_id, ord, attempts_039, attempts_4049, attempts_50, tot), zero_games) |>
  arrange(kicker_player_id, ord) |> mutate(games = 1)
lg_per_game <- sapply(setNames(c(RANGES, "tot"), c(RANGES, "total")), function(r) {
  col <- if (r == "tot") "tot" else paste0("attempts_", r); sum(vol_log[[col]]) / nrow(vol_log) })
lg_share <- sapply(setNames(RANGES, RANGES), function(r) sum(vol_log[[paste0("attempts_", r)]]) / sum(vol_log$tot))
for (hl in c(12, 24, 48, Inf)) {
  tag <- if (is.infinite(hl)) "all" else hl
  lg <- vol_log |> group_by(kicker_player_id) |>
    mutate(across(c(attempts_039, attempts_4049, attempts_50, tot, games), ~ running_after(.x, hl), .names = "d_{.col}")) |>
    ungroup()
  s <- state_before(lg, c("d_attempts_039", "d_attempts_4049", "d_attempts_50", "d_tot", "d_games"))
  for (r in RANGES) {
    vol[[paste0("kvol_", r, "_hl", tag)]] <- (s[, paste0("d_attempts_", r)] + W * lg_per_game[[r]]) / (s[, "d_games"] + W)
    vol[[paste0("kshare_", r, "_hl", tag)]] <- (s[, paste0("d_attempts_", r)] + W * lg_share[[r]]) / (s[, "d_tot"] + W)
  }
  if (hl == 12) vol$kvol_total_hl12 <- (s[, "d_tot"] + W * lg_per_game[["total"]]) / (s[, "d_games"] + W)
}

# --- Fantasy points, and the two top-16 definitions ------------------------------------
vol <- vol |> mutate(fpts = 3 * mk_039 + 4 * mk_4049 + 5 * mk_50 - (fg_attempts - fg_makes) + xp_makes)

# Season-end top 16 (uses the season's own results - comparisons only)
top_n <- vol |> group_by(season, kicker_player_id) |> summarise(pts = sum(fpts), .groups = "drop") |>
  group_by(season) |> slice_max(pts, n = TOP_N, with_ties = FALSE) |> ungroup() |> mutate(top16 = TRUE)
vol <- vol |> left_join(top_n |> select(season, kicker_player_id, top16), by = c("season", "kicker_player_id")) |>
  mutate(top16 = replace_na(top16, FALSE))

# Pre-game top 16 (only information available before each game)
pts_log <- vol |> select(kicker_player_id, ord, fpts) |> arrange(kicker_player_id, ord) |>
  mutate(games = 1) |> group_by(kicker_player_id) |>
  mutate(d_pts = running_after(fpts, TOP_PRE_HALF_LIFE), d_games = running_after(games, TOP_PRE_HALF_LIFE)) |>
  ungroup()
s_pts <- state_before(pts_log, c("d_pts", "d_games"))
lg_ppg <- mean(vol$fpts)
vol$kicker_ppg_pre <- ifelse(s_pts[, "d_games"] > 0,
                             (s_pts[, "d_pts"] + TOP_PRE_W * lg_ppg) / (s_pts[, "d_games"] + TOP_PRE_W), NA_real_)
vol <- vol |> group_by(season, week) |>
  mutate(top16pre = !is.na(kicker_ppg_pre) &
           rank(-kicker_ppg_pre, ties.method = "first", na.last = "keep") <= TOP_N) |>
  ungroup() |> mutate(top16pre = replace_na(top16pre, FALSE))

stopifnot(!anyDuplicated(vol[c("season", "week", "game_id", "posteam")]))
write_csv(vol, "data/volume_model_table.csv")
message("Wrote data/volume_model_table.csv (", nrow(vol), " team-games; pre-game top-", TOP_N, ": ",
        sum(vol$top16pre), "; season-end top-", TOP_N, ": ", sum(vol$top16), ")")
