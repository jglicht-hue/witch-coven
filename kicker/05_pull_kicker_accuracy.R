# Builds kicker accuracy features for the shrinkage/slump model: a
# long-run, recency-weighted, Bayesian-shrunk FG accuracy rate per
# distance range, a week-specific "slump adjustment" applied on top of
# that baseline when a kicker is significantly underperforming their own
# shot-mix-adjusted expectation THIS SEASON, and a raw (unshrunk) XP
# accuracy rate.
#
# Reads data/kicker_accuracy.csv and data/team_game_fg_xp_counts.csv
# (both written by 01_pull_kicker_game_outcomes.R) - run 01 first.
#
# Output: data/kicker_game_accuracy.csv - one row per (season, week,
# game_id, kicker_player_id, kicker_player_name), for every game where
# that kicker attempted at least one FG (the grain of 01's
# kicker_accuracy.csv - a kicker with zero FG attempts in a game isn't
# represented here, including for XP purposes; see the XP note below).
# Columns:
#
#   in_season_game_num : this kicker's game number within THIS season
#     (1 for their season opener, 2 for the next game, etc). Kept so it's
#     easy to see which of the two slump-test cases applied to a given
#     row (see SLUMP DETECTOR below) without recomputing it.
#
#   long_run_rate_0_39 / _40_49 / _50plus :
#     This kicker's exponentially-decayed, Bayesian-shrunk make rate in
#     that distance range, using only games strictly BEFORE this one
#     (leakage-safe walk-forward, same convention as scripts 02-04).
#     Falls back smoothly to the pure league-average rate for a kicker's
#     first tracked game (weighted sums are both 0, so the shrinkage
#     formula reduces to exactly league_avg) - no special-casing needed.
#     NOTE: this table only covers the 3-season pull window (same as the
#     rest of the pipeline). A veteran kicker's very first game inside
#     that window will look like a blank slate here even though they
#     have real history before the window starts - that's expected and
#     fine for training data (confirmed with user 2026-09-21): by the
#     time this script is ever used for an actual upcoming week, the
#     pulled window has already rolled forward past that boundary, so it
#     never affects a live estimate, only a handful of early training
#     rows.
#
#   final_rate_0_39 / _40_49 / _50plus :
#     Same as long_run_rate_* but multiplied by slump_deficit_ratio when
#     a slump is flagged for this week (see below). Identical to
#     long_run_rate_* in every non-slump week. THIS is the rate the
#     downstream fantasy-points model should actually use.
#     SINCE 2026-09-28 the slump cut is switched off (APPLY_SLUMP_ADJUSTMENT
#     below), so final_rate_* = long_run_rate_* in every week.
#
#   slump_flagged : 1 if the slump detector triggered for this game, 0
#     otherwise (including "not enough prior in-season history to test").
#   slump_deficit_ratio : actual_makes / shot_mix_expected_makes over the
#     pooled window. Always < 1 when slump_flagged == 1 (the test is
#     one-sided on underperformance); exactly 1 otherwise (no adjustment).
#   slump_p_value : the one-sided exact binomial test p-value behind the
#     flag, kept for auditing - NA if there wasn't enough prior in-season
#     history to run the test yet.
#   slump_pool_games : how many prior in-season games actually went into
#     the pooled test (see METHOD NOTES - this can be smaller than the
#     nominal window size early in a season, e.g. 1 game at week 2). Kept
#     so a very thin-sample flag is easy to spot rather than hidden.
#
#   xp_accuracy_rate : exponentially-decayed (same half-life) XP make rate,
#     walk-forward, leakage-safe. SINCE 2026-09-28 shrunk toward the league
#     XP rate with weight XP_SHRINKAGE_W = 100 attempts (was an unshrunk "raw
#     rate", NA until a kicker had a prior tracked XP).
#     APPROXIMATED: 01 has no per-kicker XP data, only team-level
#     (team_game_fg_xp_counts.csv). This script attributes a team's full
#     game XP attempts/makes to whichever kicker attempted the most FGs
#     for that team in that game (the "primary kicker"). This is
#     silently wrong on the rare game where a backup/emergency kicker
#     takes the XPs but not the FGs, or vice versa - a known, accepted
#     tradeoff (chosen over building real per-kicker XP data in 01). It
#     also means a team-game with ZERO FG attempts contributes no XP data
#     to any kicker here - there's no FG-based way to know who kicked, so
#     that team's XPs that game aren't attributed to anyone.
#
# METHOD NOTES
#
# Half-life = 12 games (confirmed with user 2026-09-19; FG rates 32 games since
# 2026-09-29, see FG_RATE_HALF_LIFE_GAMES). "Games" means
# games in which the kicker attempted >=1 FG (the only game unit 01's
# kicker_accuracy.csv gives us) - decay is measured in real elapsed
# games, not in range-specific attempt occurrences, so a rarely-attempted
# range like 50+ doesn't decay artificially slowly just because it's
# infrequent. weight = 0.5 ^ (games_ago / 12). No season reset for the
# baseline itself - crosses year boundaries, per the locked design.
#
# w=5 Bayesian shrinkage toward a single LEAGUE-AVERAGE rate per distance
# range, computed once across the full 3-season sample (same non-walk-
# forward convention 02 already uses for coach_fg_or_go_rate's league
# average - matched here rather than re-derived per kicker-game, to stay
# consistent with that precedent). shrunk_rate = (weighted_makes +
# 5*league_avg) / (weighted_attempts + 5).
#
# SLUMP DETECTOR - one-sided exact binomial test (confirmed with user
# 2026-09-19: pooled shot-mix-adjusted average probability, not a true
# Poisson-binomial test):
#   1. Pool FG attempts from the kicker's most recent games THIS SEASON
#      ONLY, strictly before the game being evaluated (confirmed with
#      user 2026-09-21: the pool must not cross into a prior season - the
#      whole point is to catch a slump happening NOW, and letting the
#      pool borrow from last season would make the season-reset case
#      pointless).
#   2. For each pooled attempt, use that attempt's OWN distance range's
#      long_run_rate AS OF the attempt's own game (the walk-forward value
#      in effect at the time, not today's value). Weighted-average these
#      (by how many attempts came from each range) into a single shot-
#      mix-adjusted probability p_bar.
#   3. binom.test(pooled_actual_makes, pooled_attempts, p_bar,
#      alternative = "less") - is the kicker making FEWER than their own
#      shot-mix-adjusted expectation, more than chance would explain?
#   4. Which of two cases applies is decided by how many prior games
#      exist THIS SEASON (not by which game is being evaluated), and a
#      test only ever runs with a FULL pool - never a partial one
#      (confirmed with user 2026-09-21, reversing an earlier partial-
#      window version of this script that could test off just 1 game's
#      worth of attempts - too thin to be meaningful even with a
#      stricter cutoff):
#       - 0 or 1 prior games this season: don't test - not enough data.
#       - Exactly 2 prior games this season: pool both, cutoff p < 0.10.
#       - 3+ prior games this season: pool the most recent 3, cutoff
#         p < 0.15.
#      So testing starts at a kicker's 3rd game of the season (pooling
#      games 1-2, the only point where the 2-game case is actually
#      reachable), never on a single game, and never across the season
#      boundary.
#   5. When flagged, slump_deficit_ratio = pooled_actual_makes /
#      pooled_expected_makes (< 1 by construction), applied
#      multiplicatively to all three distance ranges' long_run_rate for
#      THIS WEEK ONLY - it does not feed back into the long-run baseline
#      for future weeks.
#
# NOTE ON COLUMN NAMES: assumes 01's output columns are unchanged
# (season, week, game_id, posteam, kicker_player_id, kicker_player_name,
# distance_range, attempts, makes) and (season, week, game_id, posteam,
# xp_attempts, xp_makes). If 01 changes, this fails loudly (missing
# column error via the stopifnot checks below), not silently.

library(dplyr)
library(tidyr)
library(readr)

HALF_LIFE_GAMES <- 12        # XP rate (and 06b's volume features, separately)
# CHANGE OF 2026-09-29 (user decision; claude/14c_accuracy_fade_prior_log.md and
# 14d_fade_24_vs_32.R): the FG make-rate record (long_run_rate_*, final_rate_*,
# and so the slump test's expectation) fades with a 32-game half-life - about
# two regular seasons - instead of 12, so a veteran's longer record counts.
# XP stays at 12. Rule set before the result: 32 unless 24 beat it on
# pre-game top-16 ranking in >= 7 of 10 seasons (it did in 5).
FG_RATE_HALF_LIFE_GAMES <- 32
BAYES_SHRINKAGE_W <- 5
SLUMP_ALPHA_STEADY <- 0.15
SLUMP_ALPHA_EARLY_SEASON <- 0.10
SLUMP_WINDOW_STEADY <- 3
SLUMP_WINDOW_EARLY_SEASON <- 2

# CHANGES OF 2026-09-28 (tested in claude/10_input_fix_experiments.R against
# rules set with the user before results were seen; see
# claude/10_input_fixes_log.md):
#   - XP_SHRINKAGE_W: the XP rate is now shrunk toward the league XP rate with
#     a weight of 100 XP attempts, like the FG rates are (w = 5 there). Was
#     unshrunk ("raw"), which let one early miss drag a kicker with few XPs far
#     below the league rate. Brier score per XP improved in 3 of 3 seasons.
#     xp_accuracy_rate is therefore never NA any more (no XP history -> league rate).
#   - APPLY_SLUMP_ADJUSTMENT = FALSE: the slump test still runs and
#     slump_flagged / slump_deficit_ratio / slump_p_value are still written for
#     auditing, but final_rate_* no longer applies the cut (final_rate_* =
#     long_run_rate_*). Without the cut, FG makes in the 90 flagged games were
#     predicted far better (Brier x1000 123 vs 230), in 3 of 3 seasons.
XP_SHRINKAGE_W <- 100
APPLY_SLUMP_ADJUSTMENT <- FALSE

ka_path <- "data/kicker_accuracy.csv"
team_xp_path <- "data/team_game_fg_xp_counts.csv"
if (!file.exists(ka_path) || !file.exists(team_xp_path)) {
  stop("Missing input file(s) - run 01_pull_kicker_game_outcomes.R first to produce ",
       ka_path, " and ", team_xp_path, ".")
}

kicker_accuracy_raw <- read_csv(ka_path, show_col_types = FALSE)
team_game_fg_xp_counts <- read_csv(team_xp_path, show_col_types = FALSE)

stopifnot(all(c("season", "week", "game_id", "posteam", "kicker_player_id",
                 "kicker_player_name", "distance_range", "attempts", "makes") %in%
                names(kicker_accuracy_raw)))
stopifnot(all(c("season", "week", "game_id", "posteam", "xp_attempts", "xp_makes") %in%
                names(team_game_fg_xp_counts)))

RANGE_SUFFIX <- c("0-39" = "0_39", "40-49" = "40_49", "50+" = "50plus")

# --- Reshape to one row per kicker-game, wide by distance range -------------
# (0 for a range not attempted that game - needed so the decay recursion
# below sees a complete, gapless game sequence per kicker.)

kicker_game_wide <- kicker_accuracy_raw |>
  mutate(range_suffix = RANGE_SUFFIX[distance_range]) |>
  select(season, week, game_id, posteam, kicker_player_id, kicker_player_name,
         range_suffix, attempts, makes) |>
  pivot_wider(
    names_from = range_suffix,
    values_from = c(attempts, makes),
    values_fill = 0
  ) |>
  arrange(kicker_player_id, season, week)

# League-average rate per distance range, computed once across the full
# sample - same non-walk-forward convention as 02's coach_fg_or_go_rate.
league_avg_summary <- kicker_accuracy_raw |>
  group_by(distance_range) |>
  summarise(rate = sum(makes) / sum(attempts), .groups = "drop")
league_avg_rate <- setNames(league_avg_summary$rate, league_avg_summary$distance_range)
message("League-average FG rate by distance range: ",
        paste(names(league_avg_rate), round(league_avg_rate, 3), sep = "=", collapse = ", "))

# --- Exponential-decay trailing sum helper -----------------------------------
# Returns, for each position i in x (already chronologically sorted), the
# decayed sum of x[1..i-1] - strictly excluding position i itself, with
# the most recent prior element (i-1) weighted d^1, the one before that
# d^2, etc. (d = 0.5^(1/half_life), so weight = 0.5^(games_ago/half_life)).
exp_decay_trailing <- function(x, half_life) {
  d <- 0.5^(1 / half_life)
  n <- length(x)
  out <- numeric(n)
  running <- 0
  for (i in seq_len(n)) {
    out[i] <- running
    running <- d * (running + x[i])
  }
  out
}

# --- Per-kicker walk-forward long-run baseline -------------------------------

kicker_game_wide <- kicker_game_wide |>
  group_by(kicker_player_id) |>
  arrange(season, week, .by_group = TRUE) |>
  mutate(
    trail_makes_0_39      = exp_decay_trailing(makes_0_39,      FG_RATE_HALF_LIFE_GAMES),
    trail_attempts_0_39   = exp_decay_trailing(attempts_0_39,   FG_RATE_HALF_LIFE_GAMES),
    trail_makes_40_49     = exp_decay_trailing(makes_40_49,     FG_RATE_HALF_LIFE_GAMES),
    trail_attempts_40_49  = exp_decay_trailing(attempts_40_49,  FG_RATE_HALF_LIFE_GAMES),
    trail_makes_50plus    = exp_decay_trailing(makes_50plus,    FG_RATE_HALF_LIFE_GAMES),
    trail_attempts_50plus = exp_decay_trailing(attempts_50plus, FG_RATE_HALF_LIFE_GAMES),
    long_run_rate_0_39    = (trail_makes_0_39    + BAYES_SHRINKAGE_W * league_avg_rate["0-39"])  / (trail_attempts_0_39    + BAYES_SHRINKAGE_W),
    long_run_rate_40_49   = (trail_makes_40_49   + BAYES_SHRINKAGE_W * league_avg_rate["40-49"]) / (trail_attempts_40_49   + BAYES_SHRINKAGE_W),
    long_run_rate_50plus  = (trail_makes_50plus  + BAYES_SHRINKAGE_W * league_avg_rate["50+"])   / (trail_attempts_50plus  + BAYES_SHRINKAGE_W)
  ) |>
  ungroup() |>
  group_by(kicker_player_id, season) |>
  mutate(in_season_game_num = row_number()) |>
  ungroup()

# --- Slump detector (season-scoped) ------------------------------------------

compute_slump_columns <- function(df) {
  # df: one kicker's games, already sorted chronologically, with
  # attempts_*/makes_*/long_run_rate_*/in_season_game_num/season columns.
  n <- nrow(df)
  slump_flagged <- integer(n)
  slump_deficit_ratio <- rep(1, n)
  slump_p_value <- rep(NA_real_, n)
  slump_pool_games <- integer(n)

  attempts_mat <- as.matrix(df[, c("attempts_0_39", "attempts_40_49", "attempts_50plus")])
  makes_mat    <- as.matrix(df[, c("makes_0_39", "makes_40_49", "makes_50plus")])
  rate_mat     <- as.matrix(df[, c("long_run_rate_0_39", "long_run_rate_40_49", "long_run_rate_50plus")])

  for (i in seq_len(n)) {
    # Season-scoped pool: only games strictly before i, in the SAME
    # season - this intentionally never reaches into a prior season.
    same_season_before <- which(df$season == df$season[i] & seq_len(n) < i)
    n_available <- length(same_season_before)

    # Which of the two cases applies is decided by how many in-season
    # prior games actually exist, NOT by which game we're evaluating -
    # and a test only ever runs with a FULL window (2 games or 3 games),
    # never a partial one:
    #   0 or 1 prior games this season -> don't test, not enough data.
    #   exactly 2 prior games          -> pool both, cutoff p < 0.10.
    #   3+ prior games                 -> pool the most recent 3, cutoff p < 0.15.
    if (n_available < SLUMP_WINDOW_EARLY_SEASON) next  # 0 or 1 prior games - nothing testable yet
    if (n_available < SLUMP_WINDOW_STEADY) {
      window_n <- SLUMP_WINDOW_EARLY_SEASON
      alpha <- SLUMP_ALPHA_EARLY_SEASON
    } else {
      window_n <- SLUMP_WINDOW_STEADY
      alpha <- SLUMP_ALPHA_STEADY
    }
    pool_rows <- tail(same_season_before, window_n)

    pooled_attempts <- sum(attempts_mat[pool_rows, , drop = FALSE])
    if (pooled_attempts == 0) next  # guard only - shouldn't occur, every pooled game has >=1 FG attempt by construction

    pooled_actual_makes <- sum(makes_mat[pool_rows, , drop = FALSE])
    pooled_expected_makes <- sum(attempts_mat[pool_rows, , drop = FALSE] * rate_mat[pool_rows, , drop = FALSE])
    p_bar <- pooled_expected_makes / pooled_attempts

    test <- binom.test(round(pooled_actual_makes), pooled_attempts, p_bar, alternative = "less")
    slump_p_value[i] <- test$p.value
    slump_pool_games[i] <- length(pool_rows)

    if (test$p.value < alpha) {
      slump_flagged[i] <- 1L
      slump_deficit_ratio[i] <- pooled_actual_makes / pooled_expected_makes
    }
  }

  df$slump_flagged <- slump_flagged
  df$slump_deficit_ratio <- slump_deficit_ratio
  df$slump_p_value <- slump_p_value
  df$slump_pool_games <- slump_pool_games
  df
}

kicker_game_wide <- kicker_game_wide |>
  group_split(kicker_player_id) |>
  lapply(compute_slump_columns) |>
  bind_rows()

applied_slump_ratio <- if (APPLY_SLUMP_ADJUSTMENT) kicker_game_wide$slump_deficit_ratio else 1
kicker_game_wide <- kicker_game_wide |>
  mutate(
    final_rate_0_39   = long_run_rate_0_39   * applied_slump_ratio,
    final_rate_40_49  = long_run_rate_40_49  * applied_slump_ratio,
    final_rate_50plus = long_run_rate_50plus * applied_slump_ratio
  )

# --- XP accuracy (approximated via primary FG kicker attribution) -----------

league_xp_rate <- sum(team_game_fg_xp_counts$xp_makes) / sum(team_game_fg_xp_counts$xp_attempts)
message("League XP rate (shrinkage target, w = ", XP_SHRINKAGE_W, "): ", round(league_xp_rate, 4))

primary_kicker_by_game <- kicker_game_wide |>
  mutate(total_fg_attempts = attempts_0_39 + attempts_40_49 + attempts_50plus) |>
  group_by(season, week, game_id, posteam) |>
  slice_max(total_fg_attempts, n = 1, with_ties = FALSE) |>  # ties broken arbitrarily (first row) - rare, documented tradeoff
  ungroup() |>
  select(season, week, game_id, posteam, kicker_player_id) |>
  mutate(is_primary_kicker = TRUE)

kicker_game_wide <- kicker_game_wide |>
  left_join(
    team_game_fg_xp_counts |> select(season, week, game_id, posteam, xp_attempts, xp_makes),
    by = c("season", "week", "game_id", "posteam")
  ) |>
  left_join(
    primary_kicker_by_game,
    by = c("season", "week", "game_id", "posteam", "kicker_player_id")
  ) |>
  mutate(
    is_primary_kicker = replace_na(is_primary_kicker, FALSE),
    xp_attempts = if_else(is_primary_kicker, xp_attempts, 0L),
    xp_makes = if_else(is_primary_kicker, xp_makes, 0L)
  ) |>
  group_by(kicker_player_id) |>
  arrange(season, week, .by_group = TRUE) |>
  mutate(
    trail_xp_makes = exp_decay_trailing(xp_makes, HALF_LIFE_GAMES),
    trail_xp_attempts = exp_decay_trailing(xp_attempts, HALF_LIFE_GAMES),
    xp_accuracy_rate = (trail_xp_makes + XP_SHRINKAGE_W * league_xp_rate) / (trail_xp_attempts + XP_SHRINKAGE_W)
  ) |>
  ungroup()

# --- Diagnostics ---------------------------------------------------------------

n_slumps <- sum(kicker_game_wide$slump_flagged)
message("Slump flagged in ", n_slumps, " of ", nrow(kicker_game_wide), " kicker-games (",
        round(100 * n_slumps / nrow(kicker_game_wide), 1), "%)")

thin_sample_slumps <- sum(kicker_game_wide$slump_flagged == 1 & kicker_game_wide$slump_pool_games < SLUMP_WINDOW_STEADY)
message(thin_sample_slumps, " of those flags were based on fewer than ", SLUMP_WINDOW_STEADY,
        " pooled games (early-season, thinner evidence) - see slump_pool_games per row")

total_team_xp <- sum(team_game_fg_xp_counts$xp_attempts)
total_attributed_xp <- sum(kicker_game_wide$xp_attempts)
message("XP attempts attributed to a primary kicker: ", total_attributed_xp, " of ", total_team_xp,
        " total team XP attempts (", round(100 * total_attributed_xp / total_team_xp, 1),
        "% coverage - the gap is team-games with zero FG attempts, where no kicker could be identified)")

# --- Combine and write --------------------------------------------------------

kicker_game_accuracy <- kicker_game_wide |>
  select(
    season, week, game_id, posteam, kicker_player_id, kicker_player_name,
    in_season_game_num,
    long_run_rate_0_39, long_run_rate_40_49, long_run_rate_50plus,
    final_rate_0_39, final_rate_40_49, final_rate_50plus,
    slump_flagged, slump_deficit_ratio, slump_p_value, slump_pool_games,
    xp_accuracy_rate
  )

stopifnot(!anyDuplicated(kicker_game_accuracy[c("season", "week", "game_id", "kicker_player_id")]))

write_csv(kicker_game_accuracy, "data/kicker_game_accuracy.csv")
message("Wrote data/kicker_game_accuracy.csv (", nrow(kicker_game_accuracy), " rows)")
