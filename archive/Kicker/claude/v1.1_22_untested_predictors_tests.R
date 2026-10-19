# 22 - Untested volume predictors, other model forms, and the narrow placebo passes rechecked
# (2026-10-03, Kicker Wizerd chat, one-off override of "don't edit scripts"; user asked for the test).
# Log: claude/v1.1_22_untested_predictors_log.md. Nothing here changes the production models, scripts or files.
# v1.1 (2026-10-04): section 22h added at the end (follow-up asked by the user); sections 22a-22g are unchanged.
#
# HOW TO RUN: from the pipeline folder after scripts 01-07 (run_all.R is enough). Each "====" section below
# was run as its own file, in this order. Needs lme4 and nnet in addition to the pipeline's packages.
# 22a downloads 2022 and 2026 play-by-play; 22f downloads 2016-2021. 22e reads ../weekly_projections_latest.csv,
# a copy of the project's data/weekly_projections_latest.csv (only for a rebuild check).
# Run time: 22b about 5 minutes, 22d about 5, 22f about 2, the rest seconds (2 cores).
#
# RULES, SET AND SENT TO THE USER BEFORE ANY RESULT WAS COMPUTED
# A. New predictors, each added alone to each of the four production models (07's FINAL_MODELS):
#    team FG attempts per game (last 8, last 16, own range last 8); expected margin from the spread and its
#    absolute value; offense EPA per play, drives per game, plays per game (last 8); opponent defense EPA per play
#    allowed (last 8); grass vs turf; retractable roof open / closed; primetime (kickoff 7pm ET or later);
#    rest days and short rest (under 7 days); week of season. 59 tests.
#    Pass (07c's rule): trained and judged on pre-game top-16 team-games, leave-one-season-out 2023-25,
#      gain > 0 and placebo share < 0.05 (2,000 within-season shuffles; 10,000 for anything under 0.10).
#    Strong pass: placebo share < 0.05/15 and better in >= 2 of 3 seasons.
#    Recommended only if a strong pass AND the points backtest (squared error, top-16 pairwise hit rate) isn't worse.
# B. Model forms: (a) Poisson total FG attempts x multinomial split by range, two pre-set versions;
#    (b) team, kicker, or both random intercepts in each model.
#    Pass: better in >= 2 of 3 seasons, share of game-resamples with no gain < 0.05/k (k = versions tried),
#      and points squared error not worse.
# C. Narrow passes (XP: coach long-range FG rate; 0-39 and 40-49: dome x coach long-range rate; 40-49: kicker's
#    40-49 share), plus two borderline checks: same placebo test with 5,000 shuffles on 2023-25, then with 2026
#    weeks 1-4 (played games) as a fourth held-out season. "Holds" = four-season placebo share < 0.05.
#    2026 alone (fit on 2023-25) is reported but was called too small to judge before it was looked at.
# 22f and 22g were added after the results (replication of the one strong pass on 2016-2022, effect sizes);
# they are extra checks, not part of the pre-set rules.

# ==== 22a_build.R: candidate predictors for 2023-2026, and 2026 team-game rows ====
# Writes t22_vol.rds (the volume table plus candidates) and t22_vol26.rds (2026 played
# team-games with the production predictors, the candidates and the outcomes).
suppressMessages({library(dplyr); library(tidyr); library(readr); library(slider)})
source("00_nflverse_data.R"); source("09_weekly_inputs.R")

PBP_COLS <- c("season", "week", "game_id", "play_id", "posteam", "defteam", "fixed_drive", "drive_inside20",
              "fixed_drive_result", "field_goal_attempt", "field_goal_result", "kick_distance", "down",
              "yardline_100", "kicker_player_id", "kicker_player_name", "extra_point_attempt",
              "extra_point_result", "play_type", "epa")
pbp_all <- bind_rows(lapply(2022:2026, function(s) {
  max_age <- if (s == 2026) 1 else Inf
  as_tibble(readRDS(fetch_release_file("pbp", paste0("play_by_play_", s, ".rds"), max_age)))[, PBP_COLS]
}))
sched_all <- as_tibble(load_schedule_data(2022:2026))
reg <- sched_all |> filter(game_type == "REG", !is.na(result))
message("Regular-season games played: ", paste(capture.output(print(table(reg$season))), collapse = " "))

# --- Team-game backbone (regular season, played), one row per team per game -------------
home_margin_sign <- sign(cor(reg$spread_line, reg$home_score - reg$away_score, use = "complete.obs"))
stopifnot(home_margin_sign > 0)  # spread_line = home team's expected margin, as 04 found
surface_mode <- sched_all |> filter(!is.na(surface), surface != "") |> count(stadium_id, surface) |>
  group_by(stadium_id) |> slice_max(n, n = 1, with_ties = FALSE) |> ungroup() |> select(stadium_id, surface_fill = surface)
reg <- reg |> left_join(surface_mode, by = "stadium_id") |>
  mutate(surface_filled = is.na(surface) | surface == "",
         surface2 = if_else(surface_filled, surface_fill, surface))
message("Surface blank for ", sum(reg$surface_filled), " played games; filled from the stadium's usual surface (",
        sum(is.na(reg$surface2)), " still unknown: ", paste(unique(reg$stadium[is.na(reg$surface2)]), collapse = ", "), ")")
# Allianz Arena (Munich) and Arena Corinthians (Sao Paulo) are soccer grounds with grass pitches
stopifnot(all(reg$stadium_id[is.na(reg$surface2)] %in% c("GER00", "SAO00")))
reg <- reg |> mutate(surface2 = coalesce(surface2, "grass"))
side <- function(home) {
  reg |> transmute(season, week, game_id, gameday,
                   posteam = if (home) home_team else away_team, opponent = if (home) away_team else home_team,
                   exp_margin = (if (home) 1 else -1) * spread_line,
                   abs_exp_margin = abs(spread_line),
                   rest_days = pmin(if (home) home_rest else away_rest, 14),
                   short_rest = as.integer((if (home) home_rest else away_rest) < 7),
                   is_grass = as.integer(surface2 == "grass"),
                   retr_open = as.integer(roof == "open"), retr_closed = as.integer(roof == "closed"),
                   is_primetime = as.integer(as.integer(substr(gametime, 1, 2)) >= 19))
}
bb <- bind_rows(side(TRUE), side(FALSE))

# --- Per-game team totals -----------------------------------------------------------------
plays <- pbp_all |> filter(play_type %in% c("pass", "run"), !is.na(epa), !is.na(posteam), !is.na(defteam))
off_g <- plays |> group_by(game_id, posteam) |> summarise(off_plays = n(), off_epa = sum(epa), .groups = "drop")
def_g <- plays |> group_by(game_id, defteam) |> summarise(def_plays = n(), def_epa = sum(epa), .groups = "drop")
drv_g <- pbp_all |> filter(!is.na(posteam), !is.na(fixed_drive)) |> distinct(game_id, posteam, fixed_drive) |>
  count(game_id, posteam, name = "drives")
fg_g <- pbp_all |> filter(field_goal_attempt == 1, !is.na(posteam)) |>
  mutate(r = case_when(kick_distance <= 39 ~ "039", kick_distance <= 49 ~ "4049", TRUE ~ "50")) |>
  count(game_id, posteam, r) |> pivot_wider(names_from = r, values_from = n, names_prefix = "g_att_", values_fill = 0)
tg <- bb |> left_join(off_g, by = c("game_id", "posteam")) |>
  left_join(def_g, by = c("game_id", "posteam" = "defteam")) |>
  left_join(drv_g, by = c("game_id", "posteam")) |> left_join(fg_g, by = c("game_id", "posteam")) |>
  mutate(across(c(g_att_039, g_att_4049, g_att_50), ~ replace_na(.x, 0)), g_fga = g_att_039 + g_att_4049 + g_att_50)
stopifnot(!anyNA(tg[c("off_plays", "off_epa", "def_plays", "def_epa", "drives")]))

# --- Trailing windows: the `w` games strictly before each game, crossing seasons ----------
trail <- function(x, w) slide_dbl(x, sum, .before = w, .after = -1, .complete = FALSE)
tg <- tg |> arrange(posteam, gameday) |> group_by(posteam) |>
  mutate(n8 = trail(rep(1, n()), 8), n16 = trail(rep(1, n()), 16),
         team_fga_pg_trail8 = trail(g_fga, 8) / n8, team_fga_pg_trail16 = trail(g_fga, 16) / n16,
         team_att_039_pg_trail8 = trail(g_att_039, 8) / n8, team_att_4049_pg_trail8 = trail(g_att_4049, 8) / n8,
         team_att_50_pg_trail8 = trail(g_att_50, 8) / n8,
         off_epa_play_trail8 = trail(off_epa, 8) / trail(off_plays, 8),
         drives_pg_trail8 = trail(drives, 8) / n8, plays_pg_trail8 = trail(off_plays, 8) / n8,
         own_def_epa_play_trail8 = trail(def_epa, 8) / trail(def_plays, 8)) |> ungroup()
tg <- tg |> left_join(tg |> select(game_id, opponent = posteam, opp_def_epa_play_trail8 = own_def_epa_play_trail8),
                      by = c("game_id", "opponent"))
CAND_COLS <- c("team_fga_pg_trail8", "team_fga_pg_trail16", "team_att_039_pg_trail8", "team_att_4049_pg_trail8",
               "team_att_50_pg_trail8", "exp_margin", "abs_exp_margin", "off_epa_play_trail8", "drives_pg_trail8",
               "plays_pg_trail8", "opp_def_epa_play_trail8", "is_grass", "retr_open", "retr_closed", "is_primetime",
               "rest_days", "short_rest")
cand <- tg |> select(game_id, posteam, n8, n16, all_of(CAND_COLS))

# --- 2023-2025: the volume table plus candidates -------------------------------------------
vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE) |> left_join(cand, by = c("game_id", "posteam"))
stopifnot(nrow(vol) == 1594, sum(vol$top16pre) == 832, !anyNA(vol[CAND_COLS]))
message("Trailing-window games behind the candidates (2023-25 rows): 8-game window full for ",
        sum(vol$n8 == 8), " of ", nrow(vol), "; 16-game window full for ", sum(vol$n16 == 16))
saveRDS(vol, "t22_vol.rds")

# --- 2026: played team-games, built with 09's weekly inputs (kicker = who kicked, as in training) ----
pbp26 <- pbp_all |> filter(season >= 2023); sched26 <- sched_all |> filter(season >= 2023)
weeks26 <- sort(unique(reg$week[reg$season == 2026]))
vol26 <- bind_rows(lapply(weeks26, function(w)
  build_week_inputs(pbp26, sched26, 2026, w) |> filter(!is.na(result))))
out26 <- pbp_all |> filter(season == 2026, !is.na(posteam)) |> group_by(game_id, posteam) |>
  summarise(xp_attempts = sum(extra_point_attempt == 1, na.rm = TRUE),
            att_039 = sum(field_goal_attempt == 1 & kick_distance <= 39, na.rm = TRUE),
            att_4049 = sum(field_goal_attempt == 1 & kick_distance > 39 & kick_distance <= 49, na.rm = TRUE),
            att_50 = sum(field_goal_attempt == 1 & kick_distance > 49, na.rm = TRUE), .groups = "drop") |>
  mutate(fg_attempts = att_039 + att_4049 + att_50)
vol26 <- vol26 |> left_join(out26, by = c("game_id", "posteam")) |> left_join(cand, by = c("game_id", "posteam")) |>
  rename(fpts = actual_points)
stopifnot(!anyNA(vol26[c("xp_attempts", "att_039", "fpts", CAND_COLS)]), !any(vol26$roof_unknown), !any(vol26$implied_imputed))
message("2026 team-games played: ", nrow(vol26), " (weeks ", paste(range(vol26$week), collapse = "-"), "); pre-game top 16: ",
        sum(vol26$top16pre), "; by week: ", paste(capture.output(print(table(vol26$week, vol26$top16pre))), collapse = " | "))
saveRDS(vol26, "t22_vol26.rds")

# --- Check: 09's builder reproduces the training table for a 2025 week (same code path as 2026) ----
chk <- build_week_inputs(pbp26 |> filter(season <= 2025), sched26 |> filter(season <= 2025), 2025, 10)
cmp <- chk |> inner_join(vol, by = c("game_id", "posteam"), suffix = c("", ".v"))
vars <- c("implied_team_total", "redzone_td_rate_trail8", "redzone_trips_per_game_trail8", "opp_redzone_td_rate_allowed_trail8",
          "coach_long_fg_rate", "is_enclosed", "krate_4049", "krate_40plus", "krate_50", "kshare_4049_hlall", "kicker_ppg_pre")
message("2025 week 10 rebuilt with 09 vs the volume table (", nrow(cmp), " rows): max |diff| = ",
        signif(max(sapply(vars, function(v) max(abs(cmp[[v]] - cmp[[paste0(v, ".v")]])))), 3),
        "; top16pre agree: ", sum(cmp$top16pre == cmp$top16pre.v))

# ==== 22b_candidates.R: Part A - each new predictor added alone to each production model ====
suppressMessages({library(dplyr); library(readr); library(parallel)})
vol <- readRDS("t22_vol.rds"); vol26 <- readRDS("t22_vol26.rds")
N_SHUFFLES <- 2000; N_SHUFFLES_RESOLVE <- 10000; PASS_BAR <- 0.05; N_CORES <- 2

FINAL <- c(  # 07's FINAL_MODELS, unchanged
  xp_attempts = "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8 + coach_long_fg_rate",
  att_039     = "implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
  att_4049    = "is_enclosed + krate_4049 + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
  att_50      = "is_enclosed + krate_40plus + is_enclosed:krate_50")
candidates_for <- function(outcome) {
  c(team_fga_trail8 = "team_fga_pg_trail8", team_fga_trail16 = "team_fga_pg_trail16",
    if (outcome != "xp_attempts") c(team_own_range_trail8 = paste0("team_", outcome, "_pg_trail8")),
    exp_margin = "exp_margin", abs_exp_margin = "abs_exp_margin",
    off_epa_play = "off_epa_play_trail8", drives_pg = "drives_pg_trail8", plays_pg = "plays_pg_trail8",
    opp_def_epa_play = "opp_def_epa_play_trail8",
    grass = "is_grass", retractable_roof = "retr_open + retr_closed", primetime = "is_primetime",
    rest_days = "rest_days", short_rest = "short_rest", week = "week")
}

# --- Scoring: leave-one-season-out on pre-game top-16 team-games (07c's method, glm.fit for speed) ----
S <- sort(unique(vol$season)); TOP <- vol$top16pre; SEAS <- vol$season
rows_by_season <- lapply(S, function(s) which(SEAS == s))
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
pois_coef <- function(X, y) { b <- suppressWarnings(glm.fit(X, y, family = poisson()))$coefficients; b[is.na(b)] <- 0; b }
heldout_dev <- function(outcome, rhs, data = vol) {
  X <- model.matrix(as.formula(paste("~", rhs)), data); y <- data[[outcome]]; d <- numeric(nrow(data))
  for (s in S) { tr <- SEAS != s & TOP; te <- SEAS == s & TOP
    d[te] <- dev_i(y[te], exp(drop(X[te, , drop = FALSE] %*% pois_coef(X[tr, , drop = FALSE], y[tr])))) }
  d[TOP]
}
gain_of <- function(d_ref, d_new) 1000 * mean(d_ref - d_new)
seasons_better <- function(d_ref, d_new) sum(tapply(d_ref - d_new, SEAS[TOP], mean) > 0)
vars_of <- function(rhs) all.vars(as.formula(paste("~", rhs)))
# Placebo: the piece's variables are replaced by copies shuffled within season (one shared shuffle).
placebo_gains <- function(outcome, base, piece, shuffle_vars, d_base, n, seed, data = vol, hd = heldout_dev, rbs = rows_by_season) {
  set.seed(seed); rows <- unlist(rbs); pl_piece <- piece
  for (j in seq_along(shuffle_vars)) pl_piece <- gsub(paste0("\\b", shuffle_vars[j], "\\b"), paste0("pv_", j), pl_piece, perl = TRUE)
  vapply(seq_len(n), function(i) {
    perm <- unlist(lapply(rbs, function(idx) idx[sample.int(length(idx))]))
    tmp <- data
    for (j in seq_along(shuffle_vars)) { v <- data[[shuffle_vars[j]]]; v[rows] <- data[[shuffle_vars[j]]][perm]; tmp[[paste0("pv_", j)]] <- v }
    gain_of(d_base, hd(outcome, paste(base, "+", pl_piece), data = tmp))
  }, numeric(1))
}
# Forward check on 2026: fit on all 2023-25 top-16 rows, score 2026 top-16 rows
dev26 <- function(outcome, rhs) {
  f <- glm(as.formula(paste(outcome, "~", rhs)), poisson, vol[TOP, ])
  t26 <- vol26[vol26$top16pre, ]
  dev_i(t26[[outcome]], predict(f, t26, type = "response"))
}

# --- Reproduction check ----------------------------------------------------------------------
repro <- sapply(names(FINAL), function(o) gain_of(heldout_dev(o, "1"), heldout_dev(o, FINAL[[o]])))
message("Production models vs league average (should be 177.431 / 13.243 / 19.591 / 20.296): ",
        paste(sprintf("%.3f", repro), collapse = " / "))
stopifnot(all(abs(repro - c(177.431, 13.243, 19.591, 20.296)) < 0.001))

# --- Stage 1: gain, seasons better, placebo share (2,000 shuffles when gain > 0) ---------------
jobs <- bind_rows(lapply(names(FINAL), function(o) tibble(outcome = o, candidate = names(candidates_for(o)), piece = unname(candidates_for(o)))))
message(nrow(jobs), " tests")
res <- bind_rows(mclapply(seq_len(nrow(jobs)), function(k) {
  o <- jobs$outcome[k]; piece <- jobs$piece[k]; base <- FINAL[[o]]
  d_base <- heldout_dev(o, base); d_new <- heldout_dev(o, paste(base, "+", piece))
  g <- gain_of(d_base, d_new)
  g26 <- 1000 * mean(dev26(o, base) - dev26(o, paste(base, "+", piece)))
  full <- glm(as.formula(paste(o, "~", base, "+", piece)), poisson, vol[TOP, ])
  ct <- summary(full)$coefficients; new_terms <- setdiff(rownames(ct), names(coef(glm(as.formula(paste(o, "~", base)), poisson, vol[TOP, ]))))
  out <- tibble(outcome = o, candidate = jobs$candidate[k], added = piece, gain = g, seasons_better = seasons_better(d_base, d_new),
                placebo_share = NA_real_, placebo_95th = NA_real_, gain_2026 = g26,
                coef = paste(sprintf("%s %+.3f (z %+.2f)", new_terms, ct[new_terms, 1], ct[new_terms, 3]), collapse = "; "))
  if (g > 0) {
    pg <- placebo_gains(o, base, piece, vars_of(piece), d_base, N_SHUFFLES, seed = 220000 + k)
    out$placebo_share <- mean(pg >= g); out$placebo_95th <- unname(quantile(pg, 0.95))
  }
  out
}, mc.cores = N_CORES))
res <- res |> mutate(passes = !is.na(placebo_share) & placebo_share < PASS_BAR)

# --- Stage 2: anything under 0.10 gets 10,000 fresh shuffles, to resolve it against 0.05 and 0.05/15 ----
res$placebo_share_10k <- NA_real_
for (k in which(!is.na(res$placebo_share) & res$placebo_share < 0.10)) {
  o <- res$outcome[k]; d_base <- heldout_dev(o, FINAL[[o]])
  pg <- unlist(mclapply(1:N_CORES, function(c) placebo_gains(o, FINAL[[o]], res$added[k], vars_of(res$added[k]), d_base,
                                                              N_SHUFFLES_RESOLVE / N_CORES, seed = 990000 + 10 * k + c), mc.cores = N_CORES))
  res$placebo_share_10k[k] <- mean(pg >= res$gain[k])
}
res <- res |> mutate(share_final = coalesce(placebo_share_10k, placebo_share),
                     passes = !is.na(share_final) & share_final < PASS_BAR,
                     strong_pass = passes & share_final < PASS_BAR / 15 & seasons_better >= 2)
write_csv(res |> mutate(across(where(is.double), ~ round(.x, 4))), "t22_candidates.csv")
print(as.data.frame(res |> select(outcome, candidate, gain, seasons_better, placebo_share, placebo_share_10k, passes, strong_pass, gain_2026) |>
                      mutate(across(where(is.double), ~ round(.x, 4)))), width = 200)
message("Tests: ", nrow(res), "; gain > 0: ", sum(res$gain > 0), "; pass (< 0.05): ", sum(res$passes), "; strong pass: ", sum(res$strong_pass))

# ==== 22c_forms.R: Part B - other model forms (multinomial split; team / kicker random effects) ====
suppressMessages({library(dplyr); library(readr); library(nnet); library(lme4)})
vol <- readRDS("t22_vol.rds")
top <- vol[vol$top16pre, ]; S <- sort(unique(top$season)); set.seed(20261003)
FINAL <- c(
  xp_attempts = "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8 + coach_long_fg_rate",
  att_039     = "implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
  att_4049    = "is_enclosed + krate_4049 + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
  att_50      = "is_enclosed + krate_40plus + is_enclosed:krate_50")
RANGES <- c("att_039", "att_4049", "att_50")
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
loso <- function(fun) {  # fun(train, held) -> matrix of predictions for held rows
  res <- NULL
  for (s in S) { p <- fun(top[top$season != s, ], top[top$season == s, ])
    if (is.null(res)) res <- matrix(NA_real_, nrow(top), ncol(p), dimnames = list(NULL, colnames(p)))
    res[top$season == s, ] <- p }
  res }

# --- Current models: held-out expected attempts ------------------------------------------------
lam_cur <- loso(function(tr, te) sapply(names(FINAL), function(o)
  predict(glm(as.formula(paste(o, "~", FINAL[[o]])), poisson, tr), te, type = "response")))
dev_of <- function(lam, outs) rowSums(sapply(outs, function(o) dev_i(top[[o]], lam[, o])))
cur_fg <- dev_of(lam_cur, RANGES)
message("Current models, held-out error x1000: ", paste(sprintf("%s %.1f", names(FINAL), sapply(names(FINAL), function(o) 1000 * mean(dev_i(top[[o]], lam_cur[, o])))), collapse = "; "),
        "; three FG ranges summed: ", round(1000 * mean(cur_fg), 1))

boot_share <- function(g, B = 5000) {  # resample games (both teams of a game stay together)
  idx <- split(seq_along(g), top$game_id); ug <- names(idx)
  bs <- replicate(B, mean(g[unlist(idx[sample(ug, replace = TRUE)], use.names = FALSE)]))
  c(share_no_gain = mean(bs <= 0), lo = unname(quantile(bs, 0.025)), hi = unname(quantile(bs, 0.975)))
}
report <- function(label, family, g, k) { b <- boot_share(g)
  tibble(form = label, family = family, gain = mean(g), seasons_better = sum(tapply(g, top$season, mean) > 0),
         boot_lo = b[["lo"]], boot_hi = b[["hi"]], share_no_gain = b[["share_no_gain"]], bar = 0.05 / k,
         passes_error_rule = seasons_better >= 2 & share_no_gain < 0.05 / k) }

# --- (a) Multinomial split: Poisson total FG attempts x multinomial shares by range ---------------
UNION <- paste("implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate",
               "+ is_enclosed:coach_long_fg_rate + krate_4049 + is_enclosed:krate_4049 + kshare_4049_hlall + krate_40plus + is_enclosed:krate_50")
MULTI <- list(
  multinomial_all_predictors = list(total = UNION, share = UNION),
  multinomial_lean = list(total = "implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed * coach_long_fg_rate + is_enclosed * krate_40plus",
                          share = "is_enclosed * krate_40plus + kshare_4049_hlall + coach_long_fg_rate"))
lam_forms <- list(current = lam_cur); rows <- list()
for (nm in names(MULTI)) {
  m <- MULTI[[nm]]
  lam <- loso(function(tr, te) {
    tot <- predict(glm(as.formula(paste("fg_attempts ~", m$total)), poisson, tr), te, type = "response")
    trk <- tr[tr$fg_attempts > 0, ]
    sh <- multinom(as.formula(paste("cbind(att_039, att_4049, att_50) ~", m$share)), trk, trace = FALSE, maxit = 500)
    pr <- predict(sh, te, type = "probs"); colnames(pr) <- RANGES
    cbind(xp_attempts = predict(glm(as.formula(paste("xp_attempts ~", FINAL[["xp_attempts"]])), poisson, tr), te, type = "response"),
          tot * pr) })
  lam_forms[[nm]] <- lam
  rows[[nm]] <- report(nm, "multinomial split (3 FG ranges summed)", 1000 * (cur_fg - dev_of(lam, RANGES)), k = length(MULTI))
  message(nm, ": per range gain x1000: ", paste(sprintf("%s %+.1f", RANGES, sapply(RANGES, function(o) 1000 * mean(dev_i(top[[o]], lam_cur[, o]) - dev_i(top[[o]], lam[, o])))), collapse = "; "))
}

# --- (b) Random effects: team and/or kicker intercepts added to each production model ---------------
# Fixed effects enter as standardized model-matrix columns (same fit, better conditioned for glmer).
RE <- c(team = "(1 | posteam)", kicker = "(1 | kicker_player_id)", team_and_kicker = "(1 | posteam) + (1 | kicker_player_id)")
re_pred <- function(o, re, tr, te) {
  f <- as.formula(paste("~", FINAL[[o]])); Xtr <- model.matrix(f, tr)[, -1, drop = FALSE]; Xte <- model.matrix(f, te)[, -1, drop = FALSE]
  mu <- colMeans(Xtr); sdv <- apply(Xtr, 2, sd)
  mk <- function(X, d) { Z <- as.data.frame(sweep(sweep(X, 2, mu), 2, sdv, "/")); names(Z) <- paste0("x", seq_len(ncol(Z)))
    cbind(Z, y = d[[o]], posteam = d$posteam, kicker_player_id = d$kicker_player_id) }
  dtr <- mk(Xtr, tr); dte <- mk(Xte, te)
  fit <- suppressWarnings(suppressMessages(glmer(as.formula(paste("y ~", paste(paste0("x", seq_len(ncol(Xtr))), collapse = " + "), "+", re)),
                                                   dtr, family = poisson, control = glmerControl(optimizer = "bobyqa"))))
  sds <- as.data.frame(VarCorr(fit))$sdcor
  list(p = predict(fit, dte, type = "response", allow.new.levels = TRUE), sd = setNames(sds, as.data.frame(VarCorr(fit))$grp))
}
re_sd <- list()
for (v in names(RE)) {
  lam <- lam_cur
  for (o in names(FINAL)) {
    sdv <- NULL
    lam[, o] <- loso(function(tr, te) { r <- re_pred(o, RE[[v]], tr, te); sdv <<- rbind(sdv, r$sd); cbind(r$p) })[, 1]
    re_sd[[paste(v, o)]] <- colMeans(sdv)
    g <- 1000 * (dev_i(top[[o]], lam_cur[, o]) - dev_i(top[[o]], lam[, o]))
    rows[[paste(v, o)]] <- report(paste0("random effect: ", v, " | ", o), paste("random effects,", o), g, k = length(RE)) |>
      mutate(re_sd = paste(sprintf("%s %.3f", names(re_sd[[paste(v, o)]]), re_sd[[paste(v, o)]]), collapse = "; "))
  }
  lam_forms[[paste0("random_effect_", v)]] <- lam
}
res <- bind_rows(rows)
write_csv(res |> mutate(across(where(is.double), ~ round(.x, 4))), "t22_forms.csv")
saveRDS(lam_forms, "t22_lam_forms.rds")
print(as.data.frame(res |> select(-family) |> mutate(across(where(is.double), ~ round(.x, 3)))), width = 250)

# ==== 22d_narrow.R: Part C - the narrow placebo passes, rechecked ====
suppressMessages({library(dplyr); library(readr); library(parallel)})
vol <- readRDS("t22_vol.rds"); vol26 <- readRDS("t22_vol26.rds")
N_SHUFFLES <- 5000; N_CORES <- 2
KEEP <- c("season", "week", "game_id", "posteam", "top16pre", "xp_attempts", "att_039", "att_4049", "att_50",
          "implied_team_total", "redzone_td_rate_trail8", "redzone_trips_per_game_trail8", "opp_redzone_td_rate_allowed_trail8",
          "coach_long_fg_rate", "is_enclosed", "krate_4049", "krate_40plus", "krate_50", "kshare_4049_hlall")
d3 <- vol[, KEEP]; d4 <- bind_rows(d3, vol26[, KEEP])

RZ3 <- "redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8"
# base = the model without the term; piece = the term; sv = what 07c shuffles for it; orig = share on 2026-09-24 (500 shuffles)
TERMS <- list(
  list(o = "xp_attempts", label = "XP: coach long-range FG rate", narrow = TRUE, orig = 0.028,
       base = paste("implied_team_total +", RZ3), piece = "coach_long_fg_rate", sv = "coach_long_fg_rate"),
  list(o = "att_039", label = "0-39: dome x coach long-range FG rate", narrow = TRUE, orig = 0.032,
       base = "implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8",
       piece = "is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate", sv = c("is_enclosed", "coach_long_fg_rate")),
  list(o = "att_4049", label = "40-49: kicker's 40-49 share (as first added)", narrow = TRUE, orig = 0.038,
       base = "is_enclosed + krate_4049 + is_enclosed:krate_4049", piece = "kshare_4049_hlall", sv = "kshare_4049_hlall"),
  list(o = "att_4049", label = "40-49: kicker's 40-49 share (dropped from the final model)", narrow = TRUE, orig = NA,
       base = "is_enclosed + krate_4049 + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
       piece = "kshare_4049_hlall", sv = "kshare_4049_hlall"),
  list(o = "att_4049", label = "40-49: dome x coach long-range FG rate", narrow = TRUE, orig = 0.032,
       base = "is_enclosed + krate_4049 + kshare_4049_hlall + is_enclosed:krate_4049",
       piece = "coach_long_fg_rate + is_enclosed:coach_long_fg_rate", sv = "coach_long_fg_rate"),
  list(o = "att_039", label = "0-39: implied total squared (borderline check)", narrow = FALSE, orig = 0.038,
       base = "implied_team_total + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
       piece = "I(implied_team_total^2)", sv = "implied_team_total"),
  list(o = "att_50", label = "50+: dome x kicker 50+ accuracy (borderline check)", narrow = FALSE, orig = 0.040,
       base = "is_enclosed + krate_40plus", piece = "is_enclosed:krate_50", sv = "krate_50"),
  list(o = "att_50", label = "50+: kicker 40+ accuracy (failed, kept by decision)", narrow = FALSE, orig = 0.730,
       base = "is_enclosed + is_enclosed:krate_50", piece = "krate_40plus", sv = "krate_40plus"))

dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
pois_coef <- function(X, y) { b <- suppressWarnings(glm.fit(X, y, family = poisson()))$coefficients; b[is.na(b)] <- 0; b }
hd <- function(outcome, rhs, data) {  # leave-one-season-out over the seasons in `data`, top-16 rows
  X <- model.matrix(as.formula(paste("~", rhs)), data); y <- data[[outcome]]; d <- numeric(nrow(data)); top <- data$top16pre
  for (s in sort(unique(data$season))) { tr <- data$season != s & top; te <- data$season == s & top
    d[te] <- dev_i(y[te], exp(drop(X[te, , drop = FALSE] %*% pois_coef(X[tr, , drop = FALSE], y[tr])))) }
  d[top]
}
placebo <- function(t, data, n, seed) {
  set.seed(seed); rbs <- lapply(sort(unique(data$season)), function(s) which(data$season == s)); rows <- unlist(rbs)
  d_base <- hd(t$o, t$base, data); real <- 1000 * mean(d_base - hd(t$o, paste(t$base, "+", t$piece), data))
  pl <- t$piece; for (j in seq_along(t$sv)) pl <- gsub(paste0("\\b", t$sv[j], "\\b"), paste0("pv_", j), pl, perl = TRUE)
  g <- vapply(seq_len(n), function(i) {
    perm <- unlist(lapply(rbs, function(idx) idx[sample.int(length(idx))])); tmp <- data
    for (j in seq_along(t$sv)) { v <- data[[t$sv[j]]]; v[rows] <- data[[t$sv[j]]][perm]; tmp[[paste0("pv_", j)]] <- v }
    1000 * mean(d_base - hd(t$o, paste(t$base, "+", pl), tmp)) }, numeric(1))
  seas <- data$season[data$top16pre]
  dd <- d_base - hd(t$o, paste(t$base, "+", t$piece), data)
  list(gain = real, share = mean(g >= real), by_season = 1000 * tapply(dd, seas, mean))
}
forward26 <- function(t) {  # fit on 2023-25, score 2026 (new data only)
  tr <- d3[d3$top16pre, ]; te <- vol26[vol26$top16pre, ]
  f0 <- glm(as.formula(paste(t$o, "~", t$base)), poisson, tr); f1 <- glm(as.formula(paste(t$o, "~", t$base, "+", t$piece)), poisson, tr)
  d <- 1000 * (dev_i(te[[t$o]], predict(f0, te, type = "response")) - dev_i(te[[t$o]], predict(f1, te, type = "response")))
  set.seed(22); bs <- replicate(5000, mean(sample(d, replace = TRUE)))
  c(gain = mean(d), lo = unname(quantile(bs, 0.025)), hi = unname(quantile(bs, 0.975)), n = length(d))
}
res <- bind_rows(mclapply(seq_along(TERMS), function(k) {
  t <- TERMS[[k]]
  p3 <- placebo(t, d3, N_SHUFFLES, 2200 + k); p4 <- placebo(t, d4, N_SHUFFLES, 2300 + k); f <- forward26(t)
  tibble(term = t$label, narrow = t$narrow, share_orig_500 = t$orig,
         gain_3s = p3$gain, share_3s = p3$share, seasons_better_3s = sum(p3$by_season > 0),
         gain_4s = p4$gain, share_4s = p4$share, seasons_better_4s = sum(p4$by_season > 0),
         gain_2026_block = p4$by_season[["2026"]],
         fwd2026_gain = f[["gain"]], fwd2026_lo = f[["lo"]], fwd2026_hi = f[["hi"]], n_2026 = f[["n"]],
         holds = p4$share < 0.05)
}, mc.cores = N_CORES))
write_csv(res |> mutate(across(where(is.double), ~ round(.x, 4))), "t22_narrow.csv")
print(as.data.frame(res |> mutate(across(where(is.double), ~ round(.x, 4)))), width = 250)

# ==== 22e_points.R: points check for anything that passed, 2026 forward check, week-4 illustration ====
suppressMessages({library(dplyr); library(tidyr); library(readr)})
source("08_points_distribution.R")
set.seed(20261003)
vol <- readRDS("t22_vol.rds"); vol26 <- readRDS("t22_vol26.rds"); lam_forms <- readRDS("t22_lam_forms.rds")
# --- Make-chance inputs exactly as 08a builds them (32-game fade, w = 5; XP w = 100) --------------
HALF_LIFE <- 12; RATE_HALF_LIFE <- 32; W <- 5
RANGES <- c("0-39" = "039", "40-49" = "4049", "50+" = "50")
acc <- read_csv("data/kicker_training_table.csv", show_col_types = FALSE)
team_counts <- read_csv("data/team_game_fg_xp_counts.csv", show_col_types = FALSE)
running_after <- function(x, hl) { d <- 0.5^(1 / hl); run <- 0; out <- numeric(length(x))
  for (i in seq_along(x)) { run <- d * (run + x[i]); out[i] <- run }; out }
state_before <- function(log, cols) {
  out <- matrix(0, nrow(vol), length(cols), dimnames = list(NULL, cols))
  for (k in unique(vol$kicker_player_id)) {
    vi <- which(vol$kicker_player_id == k); li <- which(log$kicker_player_id == k)
    if (!length(li)) next
    pos <- findInterval(vol$ord[vi] - 0.5, log$ord[li]); ok <- pos > 0
    out[vi[ok], ] <- as.matrix(log[li[pos[ok]], cols]) }
  out }
vol <- vol |> mutate(ord = season * 100 + week)
kg <- acc |> mutate(r = RANGES[distance_range]) |>
  select(season, week, game_id, posteam, kicker_player_id, r, attempts, makes) |>
  pivot_wider(names_from = r, values_from = c(attempts, makes), values_fill = 0) |>
  mutate(ord = season * 100 + week, tot = attempts_039 + attempts_4049 + attempts_50) |> arrange(kicker_player_id, ord)
lg_rate <- sapply(setNames(RANGES, RANGES), function(r) sum(kg[[paste0("makes_", r)]]) / sum(kg[[paste0("attempts_", r)]]))
acc_log_rate <- kg |> group_by(kicker_player_id) |>
  mutate(across(c(starts_with("attempts_"), starts_with("makes_")), ~ running_after(.x, RATE_HALF_LIFE), .names = "d_{.col}")) |> ungroup()
for (r in RANGES) {
  s <- state_before(acc_log_rate, c(paste0("d_makes_", r), paste0("d_attempts_", r)))
  vol[[paste0("p_", r)]] <- (s[, 1] + W * lg_rate[[r]]) / (s[, 2] + W)
}
primary <- kg |> group_by(game_id, posteam) |> slice_max(tot, n = 1, with_ties = FALSE) |> ungroup() |> select(game_id, posteam, ord, kicker_player_id)
xp_log <- primary |> left_join(team_counts |> select(game_id, posteam, xp_attempts, xp_makes), by = c("game_id", "posteam")) |>
  arrange(kicker_player_id, ord) |> group_by(kicker_player_id) |>
  mutate(d_xp_makes = running_after(xp_makes, HALF_LIFE), d_xp_attempts = running_after(xp_attempts, HALF_LIFE)) |> ungroup()
lg_xp <- sum(team_counts$xp_makes) / sum(team_counts$xp_attempts)
s <- state_before(xp_log, c("d_xp_makes", "d_xp_attempts")); vol$p_xp <- (s[, 1] + 100 * lg_xp) / (s[, 2] + 100)

top <- vol[vol$top16pre, ]; S <- sort(unique(top$season))
FINAL <- c(
  xp_attempts = "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8 + coach_long_fg_rate",
  att_039     = "implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
  att_4049    = "is_enclosed + krate_4049 + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
  att_50      = "is_enclosed + krate_40plus + is_enclosed:krate_50")
alt <- function(o, piece) { f <- FINAL; f[[o]] <- paste(f[[o]], "+", piece); f }
SETS <- list(current = FINAL,
             `0-39 + expected margin (strong pass)` = alt("att_039", "exp_margin"),
             `XP + team FG attempts, last 8 (plain pass)` = alt("xp_attempts", "team_fga_pg_trail8"),
             `XP + rest days (plain pass)` = alt("xp_attempts", "rest_days"),
             `50+ + primetime (plain pass)` = alt("att_50", "is_primetime"),
             `50+ + week of season (plain pass)` = alt("att_50", "week"))
loso_lam <- function(Fs) { out <- matrix(NA_real_, nrow(top), 4, dimnames = list(NULL, names(Fs)))
  for (s in S) for (o in names(Fs))
    out[top$season == s, o] <- predict(glm(as.formula(paste(o, "~", Fs[[o]])), poisson, top[top$season != s, ]), top[top$season == s, ], type = "response")
  out }
pts <- function(lam, d) projected_points(lam[, "xp_attempts"], lam[, "att_039"], lam[, "att_4049"], lam[, "att_50"], d$p_039, d$p_4049, d$p_50, d$p_xp)
proj <- c(lapply(SETS, function(Fs) pts(loso_lam(Fs), top)),
          lapply(lam_forms[setdiff(names(lam_forms), "current")], function(l) pts(l, top)))
stopifnot(max(abs(pts(lam_forms$current, top) - proj$current)) < 1e-8)

pairs_by_week <- function(p, a, wk) { sp <- split(seq_along(p), wk)   # 14c's definition
  t(vapply(sp, function(ix) { dp <- outer(p[ix], p[ix], "-"); da <- outer(a[ix], a[ix], "-"); u <- upper.tri(dp) & da != 0
    c(conc = sum((sign(dp[u]) == sign(da[u])) + 0.5 * (dp[u] == 0)), pairs = sum(u)) }, numeric(2))) }
wk <- paste(top$season, sprintf("%02d", top$week)); WEEKS <- sort(unique(wk)); wk_season <- as.integer(substr(WEEKS, 1, 4))
base_pw <- pairs_by_week(proj$current, top$fpts, wk)[WEEKS, ]
se_week <- function(p) tapply((top$fpts - p)^2, wk, sum)[WEEKS]; n_week <- tapply(top$fpts, wk, length)[WEEKS]
tab <- bind_rows(lapply(names(proj), function(nm) {
  p <- proj[[nm]]; pw <- pairs_by_week(p, top$fpts, wk)[WEEKS, ]
  dse <- se_week(p) - se_week(proj$current); dc <- pw[, "conc"] - base_pw[, "conc"]
  bs <- t(replicate(2000, { ix <- sample(length(WEEKS), replace = TRUE)
    c(sum(dse[ix]) / sum(n_week[ix]), sum(dc[ix]) / sum(base_pw[ix, "pairs"])) }))
  tibble(model = nm, mse = mean((top$fpts - p)^2), mse_diff = mse - mean((top$fpts - proj$current)^2),
         mse_seasons_better = sum(tapply((top$fpts - proj$current)^2 - (top$fpts - p)^2, top$season, mean) > 0),
         share_mse_not_better = mean(bs[, 1] >= 0),
         hit16 = sum(pw[, "conc"]) / sum(pw[, "pairs"]), hit16_diff = hit16 - sum(base_pw[, "conc"]) / sum(base_pw[, "pairs"]),
         hit_seasons_better = sum(sapply(S, function(s) sum(dc[wk_season == s])) > 0),
         share_hit_not_better = mean(bs[, 2] <= 0), bias = mean(p) - mean(top$fpts),
         mean_abs_change = mean(abs(p - proj$current)), max_abs_change = max(abs(p - proj$current)))
}))
write_csv(tab |> mutate(across(where(is.double), ~ round(.x, 4))), "t22_points.csv")
message("Points backtest, 832 pre-game top-16 team-games, leave-one-season-out (08a's current squared error is 22.084):")
print(as.data.frame(tab |> mutate(across(where(is.double), ~ round(.x, 4)))), width = 250)
by_season <- sapply(c("current", "0-39 + expected margin (strong pass)"), function(nm) tapply((top$fpts - proj[[nm]])^2, top$season, mean))
print(round(by_season, 3))

# --- 2026 forward check: models fit on all 2023-25 top-16 rows, 2026 played games ----------------
fit_all <- function(Fs) lapply(setNames(names(Fs), names(Fs)), function(o) glm(as.formula(paste(o, "~", Fs[[o]])), poisson, top))
f_cur <- fit_all(FINAL); f_alt <- fit_all(SETS[[2]])
lam26 <- function(fits, d) sapply(fits, function(f) predict(f, d, type = "response"))
p26 <- list(current = pts(lam26(f_cur, vol26), vol26), alt = pts(lam26(f_alt, vol26), vol26))
fwd <- bind_rows(lapply(c("top16", "all"), function(who) { ix <- if (who == "top16") vol26$top16pre else rep(TRUE, nrow(vol26))
  w26 <- paste(vol26$season, vol26$week)[ix]
  bind_rows(lapply(names(p26), function(nm) { p <- p26[[nm]][ix]; a <- vol26$fpts[ix]; pw <- pairs_by_week(p, a, w26)
    tibble(who = who, model = nm, n = sum(ix), mse = mean((a - p)^2), mse_ppg = mean((a - vol26$kicker_ppg_pre[ix])^2, na.rm = TRUE),
           hit = sum(pw[, 1]) / sum(pw[, 2]), pairs = sum(pw[, 2]), bias = mean(p) - mean(a)) })) }))
message("\n2026 weeks 1-4 played games (models fit on 2023-25):"); print(as.data.frame(fwd |> mutate(across(where(is.double), ~ round(.x, 3)))))
d26 <- (vol26$fpts - p26$current)^2 - (vol26$fpts - p26$alt)^2
for (who in c("top16", "all")) { x <- if (who == "top16") d26[vol26$top16pre] else d26
  bs <- replicate(5000, mean(sample(x, replace = TRUE)))
  message("2026 squared-error gain from the margin term (", who, "): ", round(mean(x), 3), " [", paste(round(quantile(bs, c(.025, .975)), 3), collapse = ", "), "]") }
write_csv(fwd, "t22_forward2026.csv")

# --- What it would change this week (illustration only; nothing is written to the weekly files) ----
source("00_nflverse_data.R"); source("09_weekly_inputs.R")
pbp <- load_pbp_data(2023:2026); sched <- load_schedule_data(2023:2026)
wk_now <- min(sched$week[sched$season == 2026 & sched$game_type == "REG" & is.na(sched$result)])
inp <- build_week_inputs(pbp, sched, 2026, wk_now, pregame_kicker_for_played = TRUE) |>
  mutate(exp_margin = 2 * implied_team_total - total_line)
prod <- lapply(setNames(names(FINAL), names(FINAL)), function(o) readRDS(file.path("models", paste0("volume_", o, "_model.rds"))))
stopifnot(all(sapply(names(FINAL), function(o) max(abs(coef(prod[[o]]) - coef(f_cur[[o]]))) < 1e-10)))
inp$proj_current <- pts(lam26(f_cur, inp), inp); inp$proj_alt <- pts(lam26(f_alt, inp), inp)
inp$att039_current <- predict(f_cur$att_039, inp, type = "response"); inp$att039_alt <- predict(f_alt$att_039, inp, type = "response")
ill <- inp |> transmute(week, team = posteam, opponent, kicker = kicker_player_name, played = !is.na(result), roof_unknown, implied_team_total, exp_margin,
                        att039_current, att039_alt, proj_current, proj_alt, change = proj_alt - proj_current,
                        rank_current = rank(-proj_current), rank_alt = rank(-proj_alt)) |> arrange(desc(proj_alt))
write_csv(ill |> mutate(across(where(is.double), ~ round(.x, 3))), "t22_week_illustration.csv")
message("\nWeek ", wk_now, " illustration (current model vs 0-39 + expected margin):")
print(as.data.frame(ill |> mutate(across(where(is.double), ~ round(.x, 2)))), width = 250)
file <- tryCatch(read_csv("../weekly_projections_latest.csv", show_col_types = FALSE), error = function(e) NULL)
if (!is.null(file)) { j <- ill |> inner_join(file |> select(team, file_proj = projected_points, file_implied = implied_team_total), by = "team")
  message("Rebuilt current projection vs the project's weekly file: max |diff| = ", round(max(abs(j$proj_current - j$file_proj)), 4),
          "; implied totals identical for ", sum(abs(j$implied_team_total - j$file_implied) < 1e-9), " of ", nrow(j)) }

# ==== 22f_replication.R: extra check (not in the pre-set rules) - does the margin effect exist in 2016-2022? ====
# Uses only schedule lines and play-by-play, so no pipeline features are needed: every regular-season team-game,
# 0-39 attempts ~ implied total + implied total squared, with and without expected margin.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
source("00_nflverse_data.R"); set.seed(20261003)
YEARS <- 2016:2026
pbp <- bind_rows(lapply(YEARS, function(s) {
  as_tibble(readRDS(fetch_release_file("pbp", paste0("play_by_play_", s, ".rds"), if (s == 2026) 1 else Inf)))[,
    c("season", "game_id", "posteam", "field_goal_attempt", "kick_distance", "extra_point_attempt")] |>
    filter(field_goal_attempt == 1 | extra_point_attempt == 1) }))
sched <- as_tibble(load_schedule_data(YEARS)) |> filter(game_type == "REG", !is.na(result), !is.na(spread_line), !is.na(total_line)) |>
  mutate(across(c(home_team, away_team), ~ dplyr::recode(.x, OAK = "LV", SD = "LAC", STL = "LA")))
stopifnot(cor(sched$spread_line, sched$result) > 0)
kicks <- pbp |> filter(!is.na(posteam)) |> group_by(game_id, posteam) |>
  summarise(att_039 = sum(field_goal_attempt == 1 & kick_distance <= 39, na.rm = TRUE),
            att_4049 = sum(field_goal_attempt == 1 & kick_distance > 39 & kick_distance <= 49, na.rm = TRUE),
            att_50 = sum(field_goal_attempt == 1 & kick_distance > 49, na.rm = TRUE),
            xp_attempts = sum(extra_point_attempt == 1, na.rm = TRUE), .groups = "drop")
tg <- bind_rows(sched |> transmute(season, week, game_id, posteam = home_team, implied = total_line / 2 + spread_line / 2, exp_margin = spread_line),
                sched |> transmute(season, week, game_id, posteam = away_team, implied = total_line / 2 - spread_line / 2, exp_margin = -spread_line)) |>
  left_join(kicks, by = c("game_id", "posteam")) |> mutate(across(c(att_039, att_4049, att_50, xp_attempts), ~ replace_na(.x, 0)))
message("Team-games by season: ", paste(capture.output(print(table(tg$season))), collapse = " "))
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
B0 <- "implied + I(implied^2)"; B1 <- paste(B0, "+ exp_margin")
# Per-season coefficient on expected margin (each season fit alone)
per <- bind_rows(lapply(YEARS, function(s) { d <- tg[tg$season == s, ]
  ct <- summary(glm(as.formula(paste("att_039 ~", B1)), poisson, d))$coefficients["exp_margin", ]
  tibble(season = s, team_games = nrow(d), coef = ct[[1]], se = ct[[2]], lo = coef - 1.96 * se, hi = coef + 1.96 * se) }))
# (1) Models fit on 2023-25, scored on each other season (pure transfer)
tr <- tg[tg$season %in% 2023:2025, ]
f0 <- glm(as.formula(paste("att_039 ~", B0)), poisson, tr); f1 <- glm(as.formula(paste("att_039 ~", B1)), poisson, tr)
per$gain_fit_2023_25 <- sapply(YEARS, function(s) { d <- tg[tg$season == s, ]
  if (s %in% 2023:2025) return(NA_real_)
  1000 * mean(dev_i(d$att_039, predict(f0, d, type = "response")) - dev_i(d$att_039, predict(f1, d, type = "response"))) })
# (2) Leave-one-season-out within 2016-2022, with a placebo (margin shuffled within season)
old <- tg[tg$season <= 2022, ]; SO <- sort(unique(old$season))
loso <- function(rhs, d = old) { out <- numeric(nrow(d))
  for (s in SO) { f <- glm(as.formula(paste("att_039 ~", rhs)), poisson, d[d$season != s, ]); te <- d$season == s
    out[te] <- dev_i(d$att_039[te], predict(f, d[te, ], type = "response")) }
  out }
d0 <- loso(B0); g <- d0 - loso(B1); real <- 1000 * mean(g)
pl <- replicate(2000, { d <- old |> group_by(season) |> mutate(exp_margin = sample(exp_margin)) |> ungroup(); 1000 * mean(d0 - loso(B1, d)) })
per$gain_loso_2016_22 <- NA_real_; per$gain_loso_2016_22[match(SO, per$season)] <- 1000 * tapply(g, old$season, mean)
message("2016-2022 leave-one-season-out: gain x1000 = ", round(real, 2), ", seasons better ", sum(tapply(g, old$season, mean) > 0), " of ", length(SO),
        ", placebo share ", mean(pl >= real), " (2,000 shuffles; ", nrow(old), " team-games)")
fo <- glm(as.formula(paste("att_039 ~", B1)), poisson, old)
message("Coefficient on expected margin, 2016-2022 pooled: ", round(coef(fo)[["exp_margin"]], 4), " (se ", round(summary(fo)$coefficients["exp_margin", 2], 4),
        "); 2023-2025 pooled, same reduced model: ", round(coef(f1)[["exp_margin"]], 4), " (se ", round(summary(f1)$coefficients["exp_margin", 2], 4), ")")
tr26 <- tg[tg$season == 2026, ]
message("Transfer to 2016-2022 (fit 2023-25): gain x1000 = ", round(1000 * mean(dev_i(old$att_039, predict(f0, old, type = "response")) - dev_i(old$att_039, predict(f1, old, type = "response"))), 2))
# Other outcomes, 2016-2022 pooled coefficient on margin (same reduced model)
oth <- sapply(c("att_039", "att_4049", "att_50", "xp_attempts"), function(o) { ct <- summary(glm(as.formula(paste(o, "~", B1)), poisson, old))$coefficients["exp_margin", ]; c(coef = ct[[1]], z = ct[[3]]) })
print(round(oth, 4))
write_csv(per |> mutate(across(where(is.double), ~ round(.x, 4))), "t22_replication.csv")
print(as.data.frame(per |> mutate(across(where(is.double), ~ round(.x, 4)))))
# (3) Walk-forward, the way the pipeline is run: fit on the three seasons before, score the next season
wf <- bind_rows(lapply(2019:2026, function(s) { a <- tg[tg$season %in% (s - 3):(s - 1), ]; b <- tg[tg$season == s, ]
  m0 <- glm(as.formula(paste("att_039 ~", B0)), poisson, a); m1 <- glm(as.formula(paste("att_039 ~", B1)), poisson, a)
  tibble(season = s, game_id = b$game_id, g = 1000 * (dev_i(b$att_039, predict(m0, b, type = "response")) - dev_i(b$att_039, predict(m1, b, type = "response"))),
         coef_used = coef(m1)[["exp_margin"]]) }))
wfs <- wf |> group_by(season) |> summarise(team_games = n(), gain = mean(g), coef_used = first(coef_used), .groups = "drop")
bootg <- function(d) { idx <- split(seq_len(nrow(d)), d$game_id); ug <- names(idx)
  bs <- replicate(5000, mean(d$g[unlist(idx[sample(ug, replace = TRUE)], use.names = FALSE)])); c(mean(d$g), quantile(bs, c(0.025, 0.975)), mean(bs <= 0)) }
message("\nWalk-forward (fit on the 3 seasons before, score the next):"); print(as.data.frame(wfs |> mutate(across(where(is.double), ~ round(.x, 3)))))
b1 <- bootg(wf[wf$season <= 2025, ]); b2 <- bootg(wf)
message("Pooled 2019-2025: gain ", round(b1[1], 2), " [", round(b1[2], 2), ", ", round(b1[3], 2), "], share of game-resamples with no gain ", b1[4],
        "; seasons better ", sum(wfs$gain[wfs$season <= 2025] > 0), " of 7. Including 2026 weeks 1-4: ", round(b2[1], 2), " [", round(b2[2], 2), ", ", round(b2[3], 2), "], share ", b2[4])
write_csv(wfs, "t22_walkforward.csv")

# ==== 22g_followups.R: numbers quoted in the log (passers' coefficients, 2026 forward check, effect sizes) ====
suppressMessages({library(dplyr); library(readr)})
vol <- readRDS("t22_vol.rds"); vol26 <- readRDS("t22_vol26.rds")
r <- read_csv("t22_candidates.csv", show_col_types = FALSE)
print(as.data.frame(r |> filter(passes) |> select(outcome, candidate, gain, seasons_better, share_final, placebo_95th, gain_2026, coef)), width = 220)
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
B039 <- "implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"
tr <- vol[vol$top16pre, ]
f0 <- glm(as.formula(paste("att_039 ~", B039)), poisson, tr); f1 <- update(f0, . ~ . + exp_margin)
print(round(summary(f1)$coefficients, 4))
cat("exp_margin sd among top16:", round(sd(tr$exp_margin), 2), " rate ratio per +7 points of margin:", round(exp(7 * coef(f1)[["exp_margin"]]), 3), "\n")
cat("cor(implied, margin):", round(cor(tr$implied_team_total, tr$exp_margin), 3), "\n")
# by season held-out gains
S <- 2023:2025
g <- sapply(S, function(s) { a <- tr[tr$season != s, ]; b <- tr[tr$season == s, ]
  m0 <- glm(formula(f0), poisson, a); m1 <- glm(formula(f1), poisson, a)
  c(gain = 1000 * mean(dev_i(b$att_039, predict(m0, b, type = "response")) - dev_i(b$att_039, predict(m1, b, type = "response"))),
    coef = coef(m1)[["exp_margin"]], n = nrow(b)) })
colnames(g) <- S; print(round(g, 4))
# raw: mean 0-39 attempts by margin bucket (top16 and all)
bk <- function(d) d |> mutate(bucket = cut(exp_margin, c(-Inf, -6.5, -2.5, 2.5, 6.5, Inf), labels = c("dog 7+", "dog 3-6.5", "within 2.5", "fav 3-6.5", "fav 7+"))) |>
  group_by(bucket) |> summarise(n = n(), implied = mean(implied_team_total), att_039 = mean(att_039), att_4049 = mean(att_4049), att_50 = mean(att_50), xp = mean(xp_attempts), fpts = mean(fpts), .groups = "drop")
cat("\nTop-16 team-games 2023-25:\n"); print(as.data.frame(bk(tr) |> mutate(across(where(is.double), ~ round(.x, 2)))))
cat("\nAll team-games 2023-25:\n"); print(as.data.frame(bk(vol) |> mutate(across(where(is.double), ~ round(.x, 2)))))
cat("\n2026 weeks 1-4, all team-games / top16:\n"); print(as.data.frame(bk(vol26) |> mutate(across(where(is.double), ~ round(.x, 2)))))
print(as.data.frame(bk(vol26[vol26$top16pre, ]) |> mutate(across(where(is.double), ~ round(.x, 2)))))
# 2026 forward gain with bootstrap, top16 and all team-games
for (lab in c("top16", "all")) { t26 <- if (lab == "top16") vol26[vol26$top16pre, ] else vol26
  d <- 1000 * (dev_i(t26$att_039, predict(f0, t26, type = "response")) - dev_i(t26$att_039, predict(f1, t26, type = "response")))
  set.seed(1); bs <- replicate(5000, mean(sample(d, replace = TRUE)))
  cat(lab, "2026 gain:", round(mean(d), 1), " n =", length(d), " 95% bootstrap:", round(quantile(bs, c(.025, .975)), 1), " share <= 0:", mean(bs <= 0), "\n") }
# all-kickers view: trained on all, scored on all / top16
ga <- sapply(S, function(s) { a <- vol[vol$season != s, ]; b <- vol[vol$season == s, ]
  m0 <- glm(formula(f0), poisson, a); m1 <- glm(formula(f1), poisson, a)
  d <- dev_i(b$att_039, predict(m0, b, type = "response")) - dev_i(b$att_039, predict(m1, b, type = "response"))
  c(all = 1000 * mean(d), top16 = 1000 * mean(d[b$top16pre])) })
colnames(ga) <- S; cat("\nTrained on all team-games:\n"); print(round(ga, 2))

# ---- effect size and the squared term ----
suppressMessages({library(dplyr); library(readr)})
vol <- readRDS("t22_vol.rds"); top <- vol[vol$top16pre, ]; S <- 2023:2025; set.seed(5)
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
hd <- function(rhs, d = vol) { tp <- d[d$top16pre, ]; out <- numeric(nrow(tp))
  for (s in S) out[tp$season == s] <- dev_i(tp$att_039[tp$season == s], predict(glm(as.formula(paste("att_039 ~", rhs)), poisson, tp[tp$season != s, ]), tp[tp$season == s, ], type = "response")); out }
REST <- "opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"
m <- c(current = paste("implied_team_total + I(implied_team_total^2) +", REST),
       with_margin = paste("implied_team_total + I(implied_team_total^2) + exp_margin +", REST),
       margin_no_square = paste("implied_team_total + exp_margin +", REST),
       margin_only_no_implied = paste("exp_margin +", REST),
       league_average = "1")
d <- lapply(m, hd)
for (n in names(m)) cat(sprintf("%-24s error x1000 %.1f | gain vs current %+.2f | seasons better %d\n", n, 1000 * mean(d[[n]]), 1000 * mean(d$current - d[[n]]), sum(tapply(d$current - d[[n]], top$season, mean) > 0)))
cat("squared term given margin: gain", round(1000 * mean(d$margin_no_square - d$with_margin), 2), " seasons", sum(tapply(d$margin_no_square - d$with_margin, top$season, mean) > 0), "\n")
# opponent-implied-total form is the same model
top$opp_implied <- top$implied_team_total - top$exp_margin
f <- glm(as.formula(paste("att_039 ~ implied_team_total + I(implied_team_total^2) + opp_implied +", REST)), poisson, top)
print(round(summary(f)$coefficients[c("implied_team_total", "I(implied_team_total^2)", "opp_implied"), ], 4))
f1 <- glm(as.formula(paste("att_039 ~", m[["with_margin"]])), poisson, top); f0 <- glm(as.formula(paste("att_039 ~", m[["current"]])), poisson, top)
cat("max |fitted diff| margin form vs opponent-total form:", max(abs(fitted(f) - fitted(f1))), "\n")
# Expected 0-39 attempts at typical lines (outdoors, median opponent red zone and coach rate)
nd <- expand.grid(implied_team_total = c(20, 23, 26), exp_margin = c(-7, -3, 0, 3, 7)) |>
  mutate(opp_redzone_td_rate_allowed_trail8 = median(top$opp_redzone_td_rate_allowed_trail8), is_enclosed = 0, coach_long_fg_rate = median(top$coach_long_fg_rate))
nd$current <- predict(f0, nd, type = "response"); nd$with_margin <- predict(f1, nd, type = "response")
print(as.data.frame(nd |> transmute(implied_team_total, exp_margin, game_total = 2 * implied_team_total - exp_margin, current = round(current, 2), with_margin = round(with_margin, 2))))
cat("validation-style gain vs league average with margin:", round(1000 * mean(d$league_average - d$with_margin), 3), "\n")
# hit rate by season for current vs margin (from points file)
print(read_csv("t22_points.csv", show_col_types = FALSE) |> select(model, mse, mse_diff, mse_seasons_better, share_mse_not_better, hit16, hit16_diff, hit_seasons_better, share_hit_not_better) |> as.data.frame())
print(sapply(list(top16 = top, all = vol), function(x) c(sd_margin = sd(x$exp_margin), mean_abs = mean(abs(x$exp_margin)))))

# ==== 22h_xp_interaction.R: follow-up (user question, 2026-10-03) - team FG attempts x implied total in the XP model ====
# Rule set before running: interaction added on top of the main effect; pass = gain > 0 and placebo share < 0.05
# (07c's rule, 10,000 shuffles); strong = share < 0.0033 and >= 2 of 3 seasons. Chosen after seeing 22b, so exploratory.
suppressMessages({library(dplyr); library(readr); library(parallel)})
vol <- readRDS("t22_vol.rds"); vol26 <- readRDS("t22_vol26.rds")
XP <- "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8 + coach_long_fg_rate"
S <- 2023:2025; TOP <- vol$top16pre; SEAS <- vol$season; rbs <- lapply(S, function(s) which(SEAS == s)); rows <- unlist(rbs)
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
pc <- function(X, y) { b <- suppressWarnings(glm.fit(X, y, family = poisson()))$coefficients; b[is.na(b)] <- 0; b }
hd <- function(rhs, data = vol) { X <- model.matrix(as.formula(paste("~", rhs)), data); y <- data$xp_attempts; d <- numeric(nrow(data))
  for (s in S) { tr <- SEAS != s & TOP; te <- SEAS == s & TOP; d[te] <- dev_i(y[te], exp(drop(X[te, , drop = FALSE] %*% pc(X[tr, , drop = FALSE], y[tr])))) }
  d[TOP] }
placebo <- function(base, piece, sv, n, seed) { d_base <- hd(base); real <- 1000 * mean(d_base - hd(paste(base, "+", piece)))
  pl <- piece; for (j in seq_along(sv)) pl <- gsub(paste0("\\b", sv[j], "\\b"), paste0("pv_", j), pl, perl = TRUE)
  g <- unlist(mclapply(1:2, function(c) { set.seed(seed + c); vapply(seq_len(n / 2), function(i) {
    perm <- unlist(lapply(rbs, function(idx) idx[sample.int(length(idx))])); tmp <- vol
    for (j in seq_along(sv)) { v <- vol[[sv[j]]]; v[rows] <- vol[[sv[j]]][perm]; tmp[[paste0("pv_", j)]] <- v }
    1000 * mean(d_base - hd(paste(base, "+", pl), tmp)) }, numeric(1)) }, mc.cores = 2))
  dd <- d_base - hd(paste(base, "+", piece))
  c(gain = real, seasons_better = sum(tapply(dd, SEAS[TOP], mean) > 0), share = mean(g >= real), by = 1000 * tapply(dd, SEAS[TOP], mean)) }
f26 <- function(base, piece) { tr <- vol[TOP, ]; te <- vol26[vol26$top16pre, ]
  f0 <- glm(as.formula(paste("xp_attempts ~", base)), poisson, tr); f1 <- glm(as.formula(paste("xp_attempts ~", base, "+", piece)), poisson, tr)
  d <- 1000 * (dev_i(te$xp_attempts, predict(f0, te, type = "response")) - dev_i(te$xp_attempts, predict(f1, te, type = "response")))
  set.seed(7); bs <- replicate(5000, mean(sample(d, replace = TRUE))); c(g26 = mean(d), lo26 = unname(quantile(bs, .025)), hi26 = unname(quantile(bs, .975))) }
res <- list()
for (w in c("team_fga_pg_trail8", "team_fga_pg_trail16")) {
  int <- paste0("implied_team_total:", w)
  T <- list(list(lab = "main effect alone, vs production", base = XP, piece = w, sv = w),
            list(lab = "interaction on top of the main effect", base = paste(XP, "+", w), piece = int, sv = c("implied_team_total", w)),
            list(lab = "interaction, only team FG attempts shuffled inside it", base = paste(XP, "+", w), piece = int, sv = w),
            list(lab = "main effect + interaction together, vs production", base = XP, piece = paste(w, "+", int), sv = w))
  for (k in seq_along(T)) { t <- T[[k]]; p <- placebo(t$base, t$piece, t$sv, 10000, 2260 + 10 * k + nchar(w)); f <- f26(t$base, t$piece)
    res[[length(res) + 1]] <- tibble(window = w, test = t$lab, gain = p[["gain"]], g2023 = p[["by.2023"]], g2024 = p[["by.2024"]], g2025 = p[["by.2025"]],
                                     seasons_better = p[["seasons_better"]], placebo_share = p[["share"]], gain_2026 = f[["g26"]], lo26 = f[["lo26"]], hi26 = f[["hi26"]]) }
}
res <- bind_rows(res); write_csv(res, "t22_xp_interaction.csv")
print(as.data.frame(res |> mutate(across(where(is.double), ~ round(.x, 4)))), width = 250)
# Shape of the fitted interaction (all 2023-25 top-16 rows)
tr <- vol[TOP, ]
fi <- glm(as.formula(paste("xp_attempts ~", XP, "+ team_fga_pg_trail8 + implied_team_total:team_fga_pg_trail8")), poisson, tr)
fm <- glm(as.formula(paste("xp_attempts ~", XP, "+ team_fga_pg_trail8")), poisson, tr)
print(round(summary(fi)$coefficients[c("implied_team_total", "team_fga_pg_trail8", "implied_team_total:team_fga_pg_trail8"), ], 4))
b <- coef(fi); cat("Effect of +1 team FG attempt per game on XP attempts, at implied total 18 / 22 / 26 / 30:",
  paste(sprintf("%+.1f%%", 100 * (exp(b[["team_fga_pg_trail8"]] + b[["implied_team_total:team_fga_pg_trail8"]] * c(18, 22, 26, 30)) - 1)), collapse = " / "), "\n")
cat("Main-effect-only model: ", sprintf("%+.1f%%", 100 * (exp(coef(fm)[["team_fga_pg_trail8"]]) - 1)), "\n")
cat("team FG attempts per game, last 8 (top 16): mean", round(mean(tr$team_fga_pg_trail8), 2), " sd", round(sd(tr$team_fga_pg_trail8), 2),
    " 10th-90th pct", paste(round(quantile(tr$team_fga_pg_trail8, c(.1, .9)), 2), collapse = "-"),
    "; correlation with implied total", round(cor(tr$team_fga_pg_trail8, tr$implied_team_total), 3),
    ", with red-zone trips", round(cor(tr$team_fga_pg_trail8, tr$redzone_trips_per_game_trail8), 3),
    ", with red-zone TD rate", round(cor(tr$team_fga_pg_trail8, tr$redzone_td_rate_trail8), 3), "\n")
# Raw look: XP attempts by implied-total half and trailing-FG tercile
raw <- tr |> mutate(implied = ifelse(implied_team_total >= median(implied_team_total), "implied high", "implied low"),
                    fga = cut(team_fga_pg_trail8, quantile(team_fga_pg_trail8, c(0, 1/3, 2/3, 1)), include.lowest = TRUE, labels = c("FGA low", "FGA mid", "FGA high"))) |>
  group_by(implied, fga) |> summarise(n = n(), implied_mean = mean(implied_team_total), xp = mean(xp_attempts), .groups = "drop")
print(as.data.frame(raw |> mutate(across(where(is.double), ~ round(.x, 2)))))

# ---- 22h points check ----
# Run as a copy of 22e_points.R cut off before "2026 forward check", with no model forms, writing
# t22_points_xp_interaction.csv, and with SETS replaced by:
#   SETS <- list(current = FINAL,
#                `XP + team FG attempts (last 8)` = alt("xp_attempts", "team_fga_pg_trail8"),
#                `XP + team FG attempts + interaction with implied total` =
#                  alt("xp_attempts", "team_fga_pg_trail8 + implied_team_total:team_fga_pg_trail8"))
