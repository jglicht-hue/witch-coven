# Exploratory test bench for the volume models - NOT part of the weekly
# pipeline. Reproduces every volume-model comparison made while designing
# script 07 (2026-09-22/23), so results can be rechecked or extended.
#
# Reads data/volume_model_table.csv (06b_build_volume_features.R's output:
# the volume table plus per-range outcomes, kicker features and both top-16
# flags - see 06b's header for how each column is built).
# Writes:
#   data/volume_experiment_results.csv     - one row per model tested
#   data/volume_experiment_placebo.csv     - placebo checks of key comparisons
#   data/volume_experiment_audit.csv       - every predictor added to the
#                                            adopted models, with placebo p-values
#   data/volume_experiment_audit_coefs.csv - direction of effect for passes
#   data/volume_experiment_profiles.csv    - predicted attempts for kicker profiles
#   data/volume_experiment_facts.csv       - supporting figures quoted in the log
#
# See the column key and how-to-read guide in the volume modeling log
# (latest version: v3_07_volume_modeling_log.md).
#
# SCORING (all prediction errors are mean Poisson deviance per team-game,
# multiplied by 1000 so differences read as whole numbers; lower = better)
#   Leave-one-season-out: fit on two seasons, predict the third, rotate.
#   Five views of every model:
#     _all         : fit on all team-games, scored on all held-out team-games
#     _top16       : same fitted model, scored only on team-games whose kicker
#                    finished top 16 in fantasy points THAT SEASON
#     _top16fit    : fit ONLY on those top-16 team-games, scored on them
#     _top16pre    : fit on all team-games, scored only on team-games whose
#                    kicker was top 16 GOING INTO THAT WEEK (pre-game top 16,
#                    see below) - no peeking at results
#     _top16prefit : fit ONLY on pre-game top-16 team-games, scored on them
#                    ("remove the bad kickers", done without peeking)
#   gain = reference model's error minus this model's error, on the same
#   held-out team-games. Positive = this model predicts better.
#   gain_se = standard error of that gain, clustered by game: the two teams
#   in a game share venue and conditions, so they're treated as one unit
#   rather than two independent observations.
#   gain_z = gain / gain_se. Around 2 or more = unlikely to be luck.
#   seasons_better = in how many of the 3 held-out seasons gain was > 0.
#
# PLACEBO CHECK: for a few key comparisons, the extra term is rebuilt from a
# shuffled copy of the variable (shuffled within season), which has the same
# values but no real link to the outcome. Repeating that many times shows how
# big a "gain" pure luck produces, which checks the gain_se formula directly.
#
# KICKER FEATURES AND TOP-16 DEFINITIONS: built in 06b (moved there
# 2026-09-24 so experiments and the final models share one copy). The pre-game
# top 16 uses only information available before kickoff; the season-end top 16
# (views _top16 / _top16fit) is picked using that season's results, so those
# two views are kept only to reproduce earlier comparisons.

suppressMessages({library(dplyr); library(tidyr); library(readr)})
set.seed(20260923)

MODEL_TABLE_PATH <- "data/volume_model_table.csv"
if (!file.exists(MODEL_TABLE_PATH)) stop("Missing ", MODEL_TABLE_PATH, " - run 06b_build_volume_features.R first.")
vol <- read_csv(MODEL_TABLE_PATH, show_col_types = FALSE)
TOP_N <- 16
N_PLACEBO <- 300
RANGES <- c("0-39" = "039", "40-49" = "4049", "50+" = "50")
HAVE_COACH_LONG <- "coach_long_fg_rate" %in% names(vol)

message("Team-games: ", nrow(vol), " | season-end top-", TOP_N, " kicker team-games: ", sum(vol$top16),
        " | pre-game top-", TOP_N, ": ", sum(vol$top16pre), " (overlap ", sum(vol$top16 & vol$top16pre), ")")

# --- Scoring ------------------------------------------------------------------------------
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
SEASONS_ <- sort(unique(vol$season))
test_order <- unlist(lapply(SEASONS_, function(s) which(vol$season == s)))
season_of <- vol$season[test_order]
top_of <- vol$top16[test_order]
pre_of <- vol$top16pre[test_order]
game_of <- vol$game_id[test_order]

# Held-out per-team-game deviance. fit_on = "top16" or "top16pre" trains on
# those rows only (predictions are still made for every held-out row; the
# views decide which rows are scored).
cache <- list()
heldout_dev <- function(outcome, rhs, fit_on = "all", data = vol) {
  key <- paste(outcome, "~", rhs, "| fit on", fit_on)
  if (identical(data, vol) && !is.null(cache[[key]])) return(cache[[key]])
  f <- as.formula(paste(outcome, "~", rhs))
  in_fit <- if (fit_on == "all") rep(TRUE, nrow(data)) else data[[fit_on]]
  mu <- unlist(lapply(SEASONS_, function(s) {
    train <- data[data$season != s & in_fit, ]
    fit <- suppressWarnings(glm(f, family = poisson, data = train))
    predict(fit, newdata = data[data$season == s, ], type = "response")
  }))
  out <- dev_i(data[[outcome]][test_order], mu)
  if (identical(data, vol)) cache[[key]] <<- out
  out
}

# Mean gain and its game-clustered standard error.
clustered_gain <- function(g, cl) {
  n <- length(g); m <- mean(g)
  s <- tapply(g - m, cl, sum); k <- length(s)
  c(gain = m, se = sqrt(k / (k - 1) * sum(s^2)) / n)
}
view_stats <- function(d, dr, keep) {
  g <- (dr - d)[keep]
  cg <- clustered_gain(g, game_of[keep])
  c(error = 1000 * mean(d[keep]), gain = 1000 * cg[["gain"]], gain_se = 1000 * cg[["se"]],
    gain_z = cg[["gain"]] / cg[["se"]],
    seasons_better = sum(tapply(g, season_of[keep], mean) > 0))
}

results <- list()
score <- function(section, outcome, rhs, ref_rhs, ref_label, label = rhs) {
  d <- heldout_dev(outcome, rhs); dr <- heldout_dev(outcome, ref_rhs)
  df <- heldout_dev(outcome, rhs, "top16"); drf <- heldout_dev(outcome, ref_rhs, "top16")
  dp <- heldout_dev(outcome, rhs, "top16pre"); drp <- heldout_dev(outcome, ref_rhs, "top16pre")
  v <- list(all = view_stats(d, dr, rep(TRUE, length(d))), top16 = view_stats(d, dr, top_of),
            top16fit = view_stats(df, drf, top_of), top16pre = view_stats(d, dr, pre_of),
            top16prefit = view_stats(dp, drp, pre_of))
  stats <- unlist(lapply(names(v), function(n) setNames(v[[n]], paste0(names(v[[n]]), "_", n))))
  results[[length(results) + 1]] <<- bind_cols(
    tibble(section, outcome, model = label, formula = rhs, reference = ref_label, reference_formula = ref_rhs),
    as_tibble(as.list(stats)))
}

IMPLIED2 <- "implied_team_total + I(implied_team_total^2)"
TEAM_PREDICTORS <- c(
  implied = "implied_team_total", implied_quadratic = IMPLIED2,
  coach_fg_or_go = "coach_fg_or_go_rate", dome = "is_enclosed", altitude = "is_high_altitude",
  redzone_td_rate = "redzone_td_rate_trail8", redzone_trips = "redzone_trips_per_game_trail8",
  opp_redzone_td_allowed = "opp_redzone_td_rate_allowed_trail8")
if (HAVE_COACH_LONG) TEAM_PREDICTORS <- c(TEAM_PREDICTORS, coach_long_fg = "coach_long_fg_rate")

# A. Total FG attempts (single model) ---------------------------------------------------
fg_full <- paste(IMPLIED2, "+ coach_fg_or_go_rate + is_enclosed")
score("A_total_fg", "fg_attempts", "1", "1", "league average", "league average")
for (p in names(TEAM_PREDICTORS)) score("A_total_fg", "fg_attempts", TEAM_PREDICTORS[[p]], "1", "league average", p)
score("A_total_fg", "fg_attempts",
      "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8 + coach_fg_or_go_rate + is_enclosed + is_high_altitude + share_40_49_trail8 + share_50plus_trail8",
      "1", "league average", "original agreed set (9 predictors)")
score("A_total_fg", "fg_attempts", fg_full, "1", "league average", "implied quadratic + coach + dome")
score("A_total_fg", "fg_attempts", paste(fg_full, "+ implied_team_total:coach_fg_or_go_rate"), fg_full,
      "implied quadratic + coach + dome", "+ implied x coach interaction")

# B. XP attempts -------------------------------------------------------------------------
score("B_xp", "xp_attempts", "1", "1", "league average", "league average")
for (p in c("implied", "implied_quadratic", "redzone_td_rate", "redzone_trips", "opp_redzone_td_allowed"))
  score("B_xp", "xp_attempts", TEAM_PREDICTORS[[p]], "1", "league average", p)
for (p in c("implied_quadratic", "redzone_td_rate", "redzone_trips", "opp_redzone_td_allowed", "dome"))
  score("B_xp", "xp_attempts", paste("implied_team_total +", TEAM_PREDICTORS[[p]]), "implied_team_total",
        "implied only", paste("implied +", p))
score("B_xp", "xp_attempts",
      "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8",
      "implied_team_total", "implied only", "implied + all 3 red zone")

# C. Per-range FG attempts -----------------------------------------------------------------
TEAM_SHARE <- c("039" = "share_0_39_trail8", "4049" = "share_40_49_trail8", "50" = "share_50plus_trail8")
CURRENT_BASE <- c("039" = IMPLIED2, "4049" = "1", "50" = "is_enclosed + krate_50")
BASE_LABEL <- c("039" = "implied quadratic", "4049" = "league average", "50" = "dome + kicker 50+ accuracy")

for (r in RANGES) {
  y <- paste0("att_", r)
  kicker_preds <- c(
    krate_039 = "krate_039", krate_4049 = "krate_4049", krate_50 = "krate_50", krate_40plus = "krate_40plus",
    kvol_own_hl12 = paste0("kvol_", r, "_hl12"), kvol_own_hl24 = paste0("kvol_", r, "_hl24"),
    kvol_own_hl48 = paste0("kvol_", r, "_hl48"), kvol_own_all = paste0("kvol_", r, "_hlall"),
    kvol_total_hl12 = "kvol_total_hl12",
    kshare_own_hl12 = paste0("kshare_", r, "_hl12"), kshare_own_hl24 = paste0("kshare_", r, "_hl24"),
    kshare_own_hl48 = paste0("kshare_", r, "_hl48"), kshare_own_all = paste0("kshare_", r, "_hlall"),
    team_share_own_trail8 = TEAM_SHARE[[r]])
  all_preds <- c(TEAM_PREDICTORS, kicker_preds)
  sec <- paste0("C_range_", r)
  # C1: each predictor alone vs league average
  score(sec, y, "1", "1", "league average", "league average")
  for (p in names(all_preds)) score(sec, y, all_preds[[p]], "1", "league average", paste("alone:", p))
  # C2: each predictor added to the current proposed model for this range
  # (skipped for 40-49, where the proposed model IS the league average, so
  # "added to proposed" would repeat C1)
  base <- CURRENT_BASE[[r]]
  terms_of <- function(x) strsplit(x, " \\+ ")[[1]]
  if (base != "1") {
    score(sec, y, base, "1", "league average", paste("PROPOSED:", BASE_LABEL[[r]]))
    for (p in names(all_preds)) {
      if (all(terms_of(all_preds[[p]]) %in% terms_of(base))) next
      score(sec, y, paste(base, "+", all_preds[[p]]), base, BASE_LABEL[[r]], paste("proposed +", p))
    }
  }
  # C3: interactions
  own_rate <- c("039" = "krate_039", "4049" = "krate_4049", "50" = "krate_50")[[r]]
  for (kr in c("krate_039", "krate_4049", "krate_50", "krate_40plus")) {
    ref <- paste("is_enclosed +", kr)
    score(sec, y, paste("is_enclosed *", kr), ref, paste("dome +", kr), paste("dome x", kr, "interaction"))
  }
  score(sec, y, paste(IMPLIED2, "+", own_rate, "+ implied_team_total:", own_rate),
        paste(IMPLIED2, "+", own_rate), paste("implied quadratic +", own_rate), paste("implied x", own_rate, "interaction"))
  score(sec, y, paste("is_enclosed *", paste0("kvol_", r, "_hl12")), paste("is_enclosed +", paste0("kvol_", r, "_hl12")),
        "dome + kicker own-range volume", "dome x kicker own-range volume interaction")
  score(sec, y, paste("is_enclosed + krate_50 *", paste0("kshare_", r, "_hlall")),
        paste("is_enclosed + krate_50 +", paste0("kshare_", r, "_hlall")),
        "dome + krate_50 + kicker share", "kicker share x krate_50 interaction")
  if (HAVE_COACH_LONG) {
    score(sec, y, "is_enclosed * coach_long_fg_rate", "is_enclosed + coach_long_fg_rate",
          "dome + coach long FG rate", "dome x coach long FG rate interaction")
    score(sec, y, "is_enclosed + krate_40plus * coach_long_fg_rate", "is_enclosed + krate_40plus + coach_long_fg_rate",
          "dome + kicker 40+ accuracy + coach long FG rate", "kicker 40+ accuracy x coach long FG rate interaction")
  }
}
# 50+ alternatives: swap the kicker measure in the proposed model
score("C_range_50", "att_50", "is_enclosed + krate_40plus", CURRENT_BASE[["50"]], BASE_LABEL[["50"]],
      "SWAP: dome + kicker 40+ accuracy (instead of 50+)")
score("C_range_50", "att_50", "is_enclosed + krate_4049 + krate_50", CURRENT_BASE[["50"]], BASE_LABEL[["50"]],
      "proposed + krate_4049 (both long accuracies separately)")
if (HAVE_COACH_LONG) {
  score("C_range_50", "att_50", "is_enclosed + krate_40plus + coach_long_fg_rate", "is_enclosed + krate_40plus",
        "dome + kicker 40+ accuracy", "dome + kicker 40+ accuracy + coach long FG rate")
}

# Head-to-head candidates vs league average (added 2026-09-23)
H2H_50 <- c(
  "CANDIDATE: dome + kicker 40+ accuracy" = "is_enclosed + krate_40plus",
  "CANDIDATE: dome x kicker 50+ accuracy" = "is_enclosed * krate_50",
  "CANDIDATE: dome x kicker 40+ accuracy" = "is_enclosed * krate_40plus",
  "CANDIDATE: dome x kicker 50+ accuracy + kicker 40-49 accuracy" = "is_enclosed * krate_50 + krate_4049",
  "CANDIDATE: dome + kicker 40+ accuracy + dome x kicker 50+ accuracy" = "is_enclosed + krate_40plus + is_enclosed:krate_50")
for (n in names(H2H_50)) score("C_range_50", "att_50", H2H_50[[n]], "1", "league average", n)
score("C_range_50", "att_50", "is_enclosed + krate_40plus + is_enclosed:krate_50", "is_enclosed + krate_40plus",
      "dome + kicker 40+ accuracy", "dome + kicker 40+ accuracy, then add dome x kicker 50+ accuracy")
H2H_4049 <- c(
  "CANDIDATE: dome + kicker 40-49 accuracy" = "is_enclosed + krate_4049",
  "CANDIDATE: dome x kicker 40-49 accuracy" = "is_enclosed * krate_4049")
for (n in names(H2H_4049)) score("C_range_4049", "att_4049", H2H_4049[[n]], "1", "league average", n)

results <- bind_rows(results) |> mutate(across(where(is.double), ~ round(.x, 3)))
write_csv(results, "data/volume_experiment_results.csv")
message("Wrote data/volume_experiment_results.csv (", nrow(results), " models)")

# --- Placebo check of the noise estimate ---------------------------------------------------
# For each comparison: the real extra term vs the same term rebuilt from a
# within-season shuffle of the variable. share_placebo_at_least_real is an
# empirical p-value: how often a meaningless term did at least as well.
shuffle_within_season <- function(x) {
  out <- x
  for (s in SEASONS_) { i <- which(vol$season == s); out[i] <- x[i][sample.int(length(i))] }
  out
}
PLACEBOS <- list(
  list(label = "40-49: kicker 40-49 accuracy (main effect + dome interaction) added to dome", outcome = "att_4049",
       base = "is_enclosed", var = "krate_4049", term = "%s + is_enclosed:%s"),
  list(label = "50+: dome x kicker 50+ accuracy (interaction)", outcome = "att_50",
       base = "is_enclosed + krate_50", var = "krate_50", term = "is_enclosed:%s"),
  list(label = "40-49: dome x kicker 40-49 accuracy (interaction)", outcome = "att_4049",
       base = "is_enclosed + krate_4049", var = "krate_4049", term = "is_enclosed:%s"),
  list(label = "50+: add kicker 40-49 accuracy to dome + 50+ accuracy", outcome = "att_50",
       base = "is_enclosed + krate_50", var = "krate_4049", term = "%s"),
  list(label = "50+: kicker 50+ accuracy added to dome", outcome = "att_50",
       base = "is_enclosed", var = "krate_50", term = "%s"),
  list(label = "0-39: implied total squared term added to implied total", outcome = "att_039",
       base = "implied_team_total", var = "implied_team_total", term = "I(%s^2)"),
  list(label = "50+: kicker 40+ accuracy added to dome", outcome = "att_50",
       base = "is_enclosed", var = "krate_40plus", term = "%s"),
  list(label = "50+: dome x kicker 50+ accuracy added to dome + kicker 40+ accuracy", outcome = "att_50",
       base = "is_enclosed + krate_40plus", var = "krate_50", term = "is_enclosed:%s"),
  list(label = "50+: dome x kicker 40+ accuracy added to dome + kicker 40+ accuracy", outcome = "att_50",
       base = "is_enclosed + krate_40plus", var = "krate_40plus", term = "is_enclosed:%s")
)
fill_term <- function(term, v) gsub("%s", v, term, fixed = TRUE)
PLACEBO_VIEWS <- c("all", "top16", "top16pre", "top16prefit")
placebo_rows <- lapply(PLACEBOS, function(p) {
  full <- paste(p$base, "+", fill_term(p$term, p$var))
  dr <- heldout_dev(p$outcome, p$base); drp <- heldout_dev(p$outcome, p$base, "top16pre")
  d_real <- heldout_dev(p$outcome, full); d_realp <- heldout_dev(p$outcome, full, "top16pre")
  real <- c(all = view_stats(d_real, dr, rep(TRUE, length(dr)))[["gain"]],
            top16 = view_stats(d_real, dr, top_of)[["gain"]],
            top16pre = view_stats(d_real, dr, pre_of)[["gain"]],
            top16prefit = view_stats(d_realp, drp, pre_of)[["gain"]])
  pl <- t(sapply(seq_len(N_PLACEBO), function(i) {
    tmp <- vol; tmp$placebo_var <- shuffle_within_season(vol[[p$var]])
    pl_rhs <- paste(p$base, "+", fill_term(p$term, "placebo_var"))
    g <- dr - heldout_dev(p$outcome, pl_rhs, data = tmp)
    gp <- drp - heldout_dev(p$outcome, pl_rhs, "top16pre", data = tmp)
    1000 * c(all = mean(g), top16 = mean(g[top_of]), top16pre = mean(g[pre_of]), top16prefit = mean(gp[pre_of]))
  }))
  out <- tibble(comparison = p$label, outcome = p$outcome, base = p$base, added = fill_term(p$term, p$var),
                shuffled_variable = p$var)
  for (v in PLACEBO_VIEWS) {
    out[[paste0("real_gain_", v)]] <- real[[v]]
    out[[paste0("placebo_mean_", v)]] <- mean(pl[, v])
    out[[paste0("placebo_95th_", v)]] <- unname(quantile(pl[, v], 0.95))
    out[[paste0("share_placebo_at_least_real_", v)]] <- mean(pl[, v] >= real[[v]])
  }
  out
}) |> bind_rows() |> mutate(across(where(is.double), ~ round(.x, 3)))
write_csv(placebo_rows, "data/volume_experiment_placebo.csv")
message("Wrote data/volume_experiment_placebo.csv (", nrow(placebo_rows), " comparisons, ",
        N_PLACEBO, " shuffles each)")

# --- Audit: what else passes the 95% placebo bar on top of the ADOPTED models ------------
# Decision rule (set by user 2026-09-24): a predictor is kept if it beats at least 95% of
# placebo shuffles. This section takes the models adopted on 2026-09-23 and
# tries adding every other predictor, with a placebo check for every addition that
# shows any positive gain. Shuffles: N_AUDIT_PLACEBO per candidate.
# Placebo construction: the variables the candidate brings in (those not already
# in the adopted model) are shuffled jointly within season. If the candidate only
# adds a new term of variables already in the model (e.g. implied total squared),
# the variables inside that new term are shuffled instead.
N_AUDIT_PLACEBO <- 300
ADOPTED <- list(
  xp_attempts = "implied_team_total",
  att_039     = IMPLIED2,
  att_4049    = "is_enclosed * krate_4049",
  att_50      = "is_enclosed + krate_40plus + is_enclosed:krate_50")
ADOPTED_LABEL <- c(xp_attempts = "implied total", att_039 = "implied total + its square",
                   att_4049 = "dome x kicker 40-49 accuracy",
                   att_50 = "dome + kicker 40+ accuracy + dome x kicker 50+ accuracy")

audit_candidates <- function(outcome) {
  team <- c(TEAM_PREDICTORS,
            all_3_red_zone = "redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8")
  if (outcome == "xp_attempts") return(team)
  r <- sub("att_", "", outcome)
  c(team,
    krate_039 = "krate_039", krate_4049 = "krate_4049", krate_50 = "krate_50", krate_40plus = "krate_40plus",
    kvol_own_hl12 = paste0("kvol_", r, "_hl12"), kvol_own_all = paste0("kvol_", r, "_hlall"),
    kvol_total_hl12 = "kvol_total_hl12",
    kshare_own_hl12 = paste0("kshare_", r, "_hl12"), kshare_own_all = paste0("kshare_", r, "_hlall"),
    team_share_own_trail8 = TEAM_SHARE[[r]],
    dome_x_krate_039 = "is_enclosed * krate_039", dome_x_krate_4049 = "is_enclosed * krate_4049",
    dome_x_krate_50 = "is_enclosed * krate_50", dome_x_krate_40plus = "is_enclosed * krate_40plus",
    implied_x_krate_40plus = "implied_team_total * krate_40plus")
}

rhs_terms <- function(rhs) if (rhs == "1") character(0) else attr(terms(as.formula(paste("~", rhs))), "term.labels")
rhs_vars <- function(rhs) if (rhs == "1") character(0) else all.vars(as.formula(paste("~", rhs)))

audit_rows <- list()
for (outcome in names(ADOPTED)) {
  base <- ADOPTED[[outcome]]
  dr <- heldout_dev(outcome, base); drp <- heldout_dev(outcome, base, "top16pre")
  for (cand in names(audit_candidates(outcome))) {
    add <- audit_candidates(outcome)[[cand]]
    full <- paste(base, "+", add)
    new_terms <- setdiff(rhs_terms(full), rhs_terms(base))
    if (!length(new_terms)) next  # candidate already fully in the adopted model
    d <- heldout_dev(outcome, full); dp <- heldout_dev(outcome, full, "top16pre")
    real_all <- view_stats(d, dr, rep(TRUE, length(d)))
    real_top <- view_stats(d, dr, top_of)
    real_pre <- view_stats(d, dr, pre_of)
    real_prefit <- view_stats(dp, drp, pre_of)
    p_all <- NA_real_; p_top <- NA_real_; p_pre <- NA_real_; p_prefit <- NA_real_
    if (max(real_all[["gain"]], real_top[["gain"]], real_pre[["gain"]], real_prefit[["gain"]]) > 0) {
      shuffle_vars <- setdiff(rhs_vars(add), rhs_vars(base))
      if (!length(shuffle_vars)) {  # only a new term of existing variables, e.g. I(x^2)
        shuffle_vars <- unique(unlist(lapply(new_terms, function(t) all.vars(as.formula(paste("~", t))))))
        placebo_rhs <- paste(c(base, new_terms), collapse = " + ")
        subst_in <- "new_terms"
      } else {
        placebo_rhs <- full
        subst_in <- "added"
      }
      pl <- t(sapply(seq_len(N_AUDIT_PLACEBO), function(i) {
        tmp <- vol
        perm <- unlist(lapply(SEASONS_, function(s) { idx <- which(vol$season == s); idx[sample.int(length(idx))] }))
        rows <- unlist(lapply(SEASONS_, function(s) which(vol$season == s)))
        new_names <- paste0("pv_", seq_along(shuffle_vars))
        for (j in seq_along(shuffle_vars)) { tmp[[new_names[j]]] <- vol[[shuffle_vars[j]]]; tmp[[new_names[j]]][rows] <- vol[[shuffle_vars[j]]][perm] }
        piece <- if (subst_in == "added") add else paste(new_terms, collapse = " + ")
        for (j in seq_along(shuffle_vars)) piece <- gsub(paste0("\\b", shuffle_vars[j], "\\b"), new_names[j], piece, perl = TRUE)
        g <- dr - heldout_dev(outcome, paste(base, "+", piece), data = tmp)
        gp <- drp - heldout_dev(outcome, paste(base, "+", piece), "top16pre", data = tmp)
        1000 * c(mean(g), mean(g[top_of]), mean(g[pre_of]), mean(gp[pre_of]))
      }))
      p_all <- mean(pl[, 1] >= real_all[["gain"]])
      p_top <- mean(pl[, 2] >= real_top[["gain"]])
      p_pre <- mean(pl[, 3] >= real_pre[["gain"]])
      p_prefit <- mean(pl[, 4] >= real_prefit[["gain"]])
    }
    audit_rows[[length(audit_rows) + 1]] <- tibble(
      outcome, adopted_model = ADOPTED_LABEL[[outcome]], candidate = cand, added = add,
      gain_all = real_all[["gain"]], seasons_better_all = real_all[["seasons_better"]], placebo_p_all = p_all,
      passes_95_all = !is.na(p_all) & p_all < 0.05,
      gain_top16 = real_top[["gain"]], seasons_better_top16 = real_top[["seasons_better"]], placebo_p_top16 = p_top,
      passes_95_top16 = !is.na(p_top) & p_top < 0.05,
      gain_top16pre = real_pre[["gain"]], seasons_better_top16pre = real_pre[["seasons_better"]], placebo_p_top16pre = p_pre,
      passes_95_top16pre = !is.na(p_pre) & p_pre < 0.05,
      gain_top16prefit = real_prefit[["gain"]], seasons_better_top16prefit = real_prefit[["seasons_better"]],
      placebo_p_top16prefit = p_prefit, passes_95_top16prefit = !is.na(p_prefit) & p_prefit < 0.05)
  }
}
audit <- bind_rows(audit_rows) |> mutate(across(where(is.double), ~ round(.x, 3)))
write_csv(audit, "data/volume_experiment_audit.csv")
message("Wrote data/volume_experiment_audit.csv (", nrow(audit), " candidate additions; ",
        sum(audit$passes_95_all | audit$passes_95_top16 | audit$passes_95_top16pre | audit$passes_95_top16prefit),
        " pass the 95% bar in at least one view)")

# --- Prediction profiles and supporting figures for the adopted kicker-based models -------
# Kicker profiles use matching percentiles of each accuracy measure (they move together).
pct <- c(weak_10th = 0.10, average_50th = 0.50, strong_75th = 0.75, elite_95th = 0.95)
prof <- data.frame(profile = names(pct),
                   krate_4049 = quantile(vol$krate_4049, pct), krate_50 = quantile(vol$krate_50, pct),
                   krate_40plus = quantile(vol$krate_40plus, pct))
fit50 <- glm(as.formula(paste("att_50 ~", ADOPTED$att_50)), family = poisson, data = vol)
fit50_simple <- glm(att_50 ~ is_enclosed + krate_40plus, family = poisson, data = vol)
fit4049_all <- glm(as.formula(paste("att_4049 ~", ADOPTED$att_4049)), family = poisson, data = vol)
fit4049_top <- glm(as.formula(paste("att_4049 ~", ADOPTED$att_4049)), family = poisson, data = vol[vol$top16, ])
fit4049_pre <- glm(as.formula(paste("att_4049 ~", ADOPTED$att_4049)), family = poisson, data = vol[vol$top16pre, ])
profiles <- bind_rows(lapply(0:1, function(dm) {
  nd <- transform(prof, is_enclosed = dm)
  tibble(profile = prof$profile, venue = ifelse(dm == 1, "dome", "outdoors"),
         krate_4049 = prof$krate_4049, krate_50 = prof$krate_50, krate_40plus = prof$krate_40plus,
         pred_att_50_adopted = predict(fit50, nd, type = "response"),
         pred_att_50_without_dome_x_50 = predict(fit50_simple, nd, type = "response"),
         pred_att_4049_fit_all = predict(fit4049_all, nd, type = "response"),
         pred_att_4049_fit_top16 = predict(fit4049_top, nd, type = "response"),
         pred_att_4049_fit_top16pre = predict(fit4049_pre, nd, type = "response"))
})) |> mutate(across(where(is.double), ~ round(.x, 3)))
write_csv(profiles, "data/volume_experiment_profiles.csv")
# Total FG attempts: sum of the three adopted range models vs the single total model
mu_heldout <- function(outcome, rhs) unlist(lapply(SEASONS_, function(s) {
  fit <- glm(as.formula(paste(outcome, "~", rhs)), family = poisson, data = vol[vol$season != s, ])
  predict(fit, newdata = vol[vol$season == s, ], type = "response") }))
y_fg <- vol$fg_attempts[test_order]
err_single <- 1000 * mean(dev_i(y_fg, mu_heldout("fg_attempts", paste(IMPLIED2, "+ coach_fg_or_go_rate + is_enclosed"))))
err_summed <- 1000 * mean(dev_i(y_fg, mu_heldout("att_039", ADOPTED$att_039) + mu_heldout("att_4049", ADOPTED$att_4049) +
                                  mu_heldout("att_50", ADOPTED$att_50)))
err_league <- 1000 * mean(dev_i(y_fg, mu_heldout("fg_attempts", "1")))
dispersion <- function(outcome) { f <- glm(as.formula(paste(outcome, "~", ADOPTED[[outcome]])), family = poisson, data = vol)
  sum(residuals(f, type = "pearson")^2) / f$df.residual }
facts <- tibble(
  fact = c("cor(kicker 40-49 accuracy, kicker 50+ accuracy)", "cor(kicker 40+ accuracy, kicker 50+ accuracy)",
           "dome team-games", "dome team-games with kicker 50+ accuracy >= 0.80",
           "team-games", "season-end top-16 kicker team-games", "pre-game top-16 kicker team-games",
           "team-games in both top-16 definitions", "team-games whose kicker has no earlier game in the table",
           "total FG error x1000: league average", "total FG error x1000: single total model (implied quadratic + coach + dome)",
           "total FG error x1000: sum of the three adopted range models",
           "dispersion: XP model", "dispersion: 0-39 model", "dispersion: 40-49 model", "dispersion: 50+ model"),
  value = c(cor(vol$krate_4049, vol$krate_50), cor(vol$krate_40plus, vol$krate_50),
            sum(vol$is_enclosed == 1), sum(vol$is_enclosed == 1 & vol$krate_50 >= 0.80),
            nrow(vol), sum(vol$top16), sum(vol$top16pre), sum(vol$top16 & vol$top16pre), sum(is.na(vol$kicker_ppg_pre)),
            err_league, err_single, err_summed,
            dispersion("xp_attempts"), dispersion("att_039"), dispersion("att_4049"), dispersion("att_50"))) |>
  mutate(value = round(value, 3))
write_csv(facts, "data/volume_experiment_facts.csv")
message("Wrote data/volume_experiment_profiles.csv and data/volume_experiment_facts.csv")

# --- Direction of effect for candidates that pass the 95% bar -----------------------------
# Fits adopted model + candidate on all team-games; reports each new term's
# coefficient and, for main effects, the rate ratio for a +1 standard deviation change.
passing <- audit |> filter(passes_95_all | passes_95_top16 | passes_95_top16pre | passes_95_top16prefit)
coef_rows <- lapply(seq_len(nrow(passing)), function(i) {
  p <- passing[i, ]
  base <- ADOPTED[[p$outcome]]
  fit <- glm(as.formula(paste(p$outcome, "~", base, "+", p$added)), family = poisson, data = vol)
  new_terms <- setdiff(names(coef(fit)), names(coef(glm(as.formula(paste(p$outcome, "~", base)), family = poisson, data = vol))))
  est <- summary(fit)$coefficients[new_terms, , drop = FALSE]
  tibble(outcome = p$outcome, candidate = p$candidate, term = new_terms, estimate = est[, 1], p_value_insample = est[, 4],
         rate_ratio_per_sd = ifelse(new_terms %in% names(vol), exp(est[, 1] * sapply(new_terms, function(t) if (t %in% names(vol)) sd(vol[[t]]) else NA)), NA))
})
audit_coefs <- bind_rows(coef_rows) |> mutate(across(where(is.double), ~ round(.x, 4)))
write_csv(audit_coefs, "data/volume_experiment_audit_coefs.csv")
message("Wrote data/volume_experiment_audit_coefs.csv")
