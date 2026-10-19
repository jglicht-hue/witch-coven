# Fits the four volume models - how many XP attempts, and how many 0-39,
# 40-49 and 50+ yard FG attempts, a team gets in a game - and saves them for
# the weekly projection step. Rewritten 2026-09-24 (the earlier version fit a
# single total-FG model on all team-games; replaced by the range models below).
#
# Reads data/volume_model_table.csv (06b). Run 06b first.
#
# WHO THE MODELS ARE TRAINED ON (decided 2026-09-24): pre-game top-16
# team-games only - team-games whose kicker ranked top 16 in fantasy points
# per game going into that week (see 06b). Those are the kickers a fantasy
# manager would roster. Applying the models to a kicker outside that group
# (e.g. a waiver candidate ranked 20th) extrapolates slightly beyond the
# training data; for near-top-16 kickers that should be minor.
#
# WHICH PREDICTORS (FINAL_MODELS below): chosen by 07c_select_volume_predictors.R
# under the user's rule of 2026-09-24 - a term is kept if it beats at least 95%
# of placebo shuffles, judged and trained on pre-game top-16 team-games -
# starting from the models the user adopted on 2026-09-23/24. See 07c's
# output files and the v3 volume modeling log for every step.
#
# FIXED ACCURACY WEIGHTS (added 2026-10-05, user decision): two weights on
# kicker accuracy are no longer estimated from the three training seasons.
# They are fixed at the values in FIXED_WEIGHTS below and enter the models as
# offsets (a term with a set coefficient). Three seasons are too few to
# estimate them: the estimates swung from fold to fold and disagreed with
# 2016-2022. See claude/24_pin_accuracy_slopes_log.md,
# claude/v1.1_25_pin_weight_grid_log.md and claude/26_pin_weights_hit_rate_log.md.
#
# MODEL FORM: Poisson regression with a log link. The attempt counts are not
# more spread out than Poisson assumes (dispersion printed below; values
# around or under 1 are fine).
#
# Outputs:
#   models/volume_<outcome>_model.rds - fitted glm per outcome; predict with
#     predict(model, newdata, type = "response") for expected attempts
#   data/volume_model_validation.csv - leave-one-season-out check on pre-game
#     top-16 team-games: each final model vs the league average
#   data/volume_model_coefficients.csv - coefficients, with a rate ratio per
#     1 standard deviation for continuous predictors (0 -> 1 for dome). The
#     fixed weights are listed too, marked "(fixed)", with no standard error.
#   models/points_gamma.csv - XP/FG dependence used by the points distribution
#     (added 2026-09-28)
#   data/volume_model_profiles.csv - predicted attempts for weak / average /
#     strong / elite kickers, outdoors vs dome, at a median offense

suppressMessages({library(dplyr); library(readr)})

MODEL_TABLE_PATH <- "data/volume_model_table.csv"
if (!file.exists(MODEL_TABLE_PATH)) stop("Missing ", MODEL_TABLE_PATH, " - run 06b_build_volume_features.R first.")
vol <- read_csv(MODEL_TABLE_PATH, show_col_types = FALSE)

# Fixed accuracy weights (2026-10-05). Change a value here and nowhere else;
# the number is written into the model formula, so every script that refits
# the models from the saved formulas (08a, 13a, 17a) picks it up.
#   att_50_krate_40plus: weight of the kicker's 40+ make rate in the 50+ model.
#     1.307 = the estimate from 2016-2022, all kickers (standard error 0.55).
#     Until 2026-10-05 it was estimated on 2023-25: 0.664 (standard error 0.84).
#   att_4049_krate_4049_outdoors: outdoor weight of the kicker's 40-49 make
#     rate in the 40-49 model. 0 = no outdoor effect; 2016-2022 puts it at
#     about 0 to +0.4. Until 2026-10-05 it was estimated on 2023-25: -1.325
#     (standard error 0.97). The dome x 40-49 accuracy term is still estimated.
# Revisit both when the training window rolls forward a season.
FIXED_WEIGHTS <- c(att_50_krate_40plus = 1.307, att_4049_krate_4049_outdoors = 0)

# Selected 2026-09-24 by 07c (see data/volume_selection_steps.csv) and
# confirmed by the user the same day. Terms marked "narrow pass" passed with a
# placebo share of 0.028-0.038; the user kept them all because they passed and
# make sense (e.g. a coach who generally kicks long is especially likely to do
# it indoors, hence dome x coach long-range FG rate).
FINAL_MODELS <- c(
  # implied total (adopted 2026-09-22); + all 3 red zone measures (p 0.014);
  # + coach long-range FG rate (p 0.028, narrow pass)
  xp_attempts = paste("implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8",
                      "+ opp_redzone_td_rate_allowed_trail8 + coach_long_fg_rate"),
  # implied total + its square (adopted 2026-09-22); + opponent red zone TD
  # rate allowed (p 0.010); + dome x coach long-range FG rate (p 0.032, narrow pass)
  att_039     = paste("implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8",
                      "+ is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"),
  # dome x kicker 40-49 accuracy (adopted 2026-09-24); + kicker's share of FG
  # attempts from 40-49, full history (p 0.038, narrow pass); + dome x coach
  # long-range FG rate (p 0.032, narrow pass). Since 2026-10-05 the outdoor
  # weight on kicker 40-49 accuracy is fixed (FIXED_WEIGHTS), not estimated.
  att_4049    = paste0("is_enclosed + kshare_4049_hlall + is_enclosed:krate_4049 ",
                       "+ coach_long_fg_rate + is_enclosed:coach_long_fg_rate ",
                       "+ offset(", FIXED_WEIGHTS[["att_4049_krate_4049_outdoors"]], " * krate_4049)"),
  # dome + kicker 40+ accuracy + dome x kicker 50+ accuracy (adopted
  # 2026-09-24). Under the pre-game top-16 rule the estimated kicker 40+
  # accuracy term failed its check (placebo share 0.73); the user kept it on
  # 2026-09-24 because it makes theoretical sense (coaches attempt more long
  # kicks with a trusted kicker). Since 2026-10-05 its weight is fixed
  # (FIXED_WEIGHTS), not estimated.
  att_50      = paste0("is_enclosed + is_enclosed:krate_50 ",
                       "+ offset(", FIXED_WEIGHTS[["att_50_krate_40plus"]], " * krate_40plus)"))
OUTCOME_LABEL <- c(xp_attempts = "XP attempts", att_039 = "0-39 FG attempts",
                   att_4049 = "40-49 FG attempts", att_50 = "50+ FG attempts")
BINARY <- c("is_enclosed", "is_high_altitude")

train <- vol |> filter(top16pre)
message("Training rows (pre-game top-16 team-games): ", nrow(train), " of ", nrow(vol))

# --- Leave-one-season-out validation on pre-game top-16 team-games ---------------------
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
SEASONS_ <- sort(unique(train$season))
heldout <- function(outcome, rhs) {
  bind_rows(lapply(SEASONS_, function(s) {
    fit <- glm(as.formula(paste(outcome, "~", rhs)), family = poisson, data = train[train$season != s, ])
    test <- train[train$season == s, ]
    tibble(season = s, y = test[[outcome]], mu = predict(fit, newdata = test, type = "response"))
  }))
}
validation <- bind_rows(lapply(names(FINAL_MODELS), function(o) {
  m <- heldout(o, FINAL_MODELS[[o]]); b <- heldout(o, "1")
  per_season <- tapply(dev_i(b$y, b$mu) - dev_i(m$y, m$mu), m$season, mean)
  tibble(outcome = o, model = FINAL_MODELS[[o]], team_games = nrow(m),
         error_final = 1000 * mean(dev_i(m$y, m$mu)), error_league_average = 1000 * mean(dev_i(b$y, b$mu)),
         gain = error_league_average - error_final, seasons_better = sum(per_season > 0),
         mean_predicted = mean(m$mu), mean_actual = mean(m$y),
         mae_final = mean(abs(m$y - m$mu)), mae_league_average = mean(abs(b$y - b$mu)))
})) |> mutate(across(where(is.double), ~ round(.x, 3)))
dir.create("data", showWarnings = FALSE)
write_csv(validation, "data/volume_model_validation.csv")
message("\nHeld-out check on pre-game top-16 team-games (error x1000, lower = better):")
print(as.data.frame(validation |> select(outcome, error_final, error_league_average, gain, seasons_better,
                                         mean_predicted, mean_actual)))

# --- Final fits on all three seasons -------------------------------------------------------
dir.create("models", showWarnings = FALSE)
final_fits <- lapply(names(FINAL_MODELS), function(o) {
  fit <- glm(as.formula(paste(o, "~", FINAL_MODELS[[o]])), family = poisson, data = train)
  saveRDS(fit, file.path("models", paste0("volume_", o, "_model.rds")))
  fit
})
names(final_fits) <- names(FINAL_MODELS)

# XP / FG dependence for the points distribution (added 2026-09-28; see
# claude/12_width_fix_log.md): gamma per range, fit on the same training rows.
source("08_points_distribution.R")
points_gamma <- estimate_gamma(final_fits, train)
write_csv(tibble(range = names(points_gamma), gamma = unname(points_gamma)), "models/points_gamma.csv")
message("XP/FG dependence gamma (0-39, 40-49, 50+): ", paste(round(points_gamma, 4), collapse = ", "))

# A rate ratio is shown only for predictors that enter their model on their
# own. For one that also appears inside an interaction or squared term, its
# coefficient alone describes the effect at 0 of the other variable, which is
# misleading - use the prediction profiles instead.
coefficients <- bind_rows(lapply(names(final_fits), function(o) {
  est <- summary(final_fits[[o]])$coefficients
  labels <- attr(terms(final_fits[[o]]), "term.labels")
  shared <- unique(unlist(lapply(labels[grepl(":|I\\(", labels)], function(t) all.vars(as.formula(paste("~", t))))))
  tibble(outcome = o, term = rownames(est), estimate = est[, 1], std_error = est[, 2], p_value_insample = est[, 4],
         stands_alone = term %in% names(train) & !(term %in% shared))
})) |>
  rowwise() |>
  mutate(rate_ratio = if (!stands_alone) NA_real_ else if (term %in% BINARY) exp(estimate) else
                        exp(estimate * sd(train[[term]])),
         rate_ratio_unit = if (!stands_alone) "depends on another term (interaction, squared term) or intercept - see profiles"
                           else if (term %in% BINARY) "0 -> 1" else paste0("+1 SD (", signif(sd(train[[term]]), 3), ")")) |>
  ungroup() |> select(-stands_alone) |> mutate(across(where(is.double), ~ signif(.x, 4)))
# The fixed weights aren't glm coefficients, so list them here (no standard error)
coefficients <- bind_rows(coefficients,
  tibble(outcome = c("att_4049", "att_50"), term = c("krate_4049 (fixed)", "krate_40plus (fixed)"),
         estimate = unname(FIXED_WEIGHTS[c("att_4049_krate_4049_outdoors", "att_50_krate_40plus")]),
         std_error = NA_real_, p_value_insample = NA_real_, rate_ratio = NA_real_,
         rate_ratio_unit = "fixed weight, not estimated (2026-10-05) - see profiles")) |>
  arrange(match(outcome, names(FINAL_MODELS)))
write_csv(coefficients, "data/volume_model_coefficients.csv")

# --- Dispersion check ------------------------------------------------------------------------
for (o in names(final_fits)) {
  f <- final_fits[[o]]
  disp <- sum(residuals(f, type = "pearson")^2) / f$df.residual
  message("Dispersion (", OUTCOME_LABEL[[o]], "): ", round(disp, 3))
  if (disp > 1.2) warning(OUTCOME_LABEL[[o]], ": counts more spread out than Poisson assumes - consider negative binomial")
}

# --- Prediction profiles -----------------------------------------------------------------------
# Kicker measures at matching percentiles (they move together); team measures
# at their medians among the training rows.
pct <- c(weak_10th = 0.10, average_50th = 0.50, strong_75th = 0.75, elite_95th = 0.95)
needed <- unique(unlist(lapply(FINAL_MODELS, function(r) all.vars(as.formula(paste("~", r))))))
kicker_vars <- grep("^krate_", needed, value = TRUE)
team_vars <- setdiff(needed, c(kicker_vars, BINARY))
base_row <- as.data.frame(lapply(setNames(team_vars, team_vars), function(v) median(train[[v]])))
profiles <- bind_rows(lapply(names(pct), function(p) bind_rows(lapply(0:1, function(dm) {
  nd <- base_row
  for (v in kicker_vars) nd[[v]] <- quantile(train[[v]], pct[[p]])
  if ("is_enclosed" %in% needed) nd$is_enclosed <- dm
  if ("is_high_altitude" %in% needed) nd$is_high_altitude <- 0
  preds <- vapply(final_fits, function(f) unname(predict(f, newdata = nd, type = "response")), numeric(1))
  tibble(kicker = p, venue = if (dm == 1) "dome" else "outdoors", !!!as.list(round(preds, 3)),
         fg_total = round(sum(preds[c("att_039", "att_4049", "att_50")]), 3))
}))))
write_csv(profiles, "data/volume_model_profiles.csv")
message("\nPredicted attempts per game at a median offense:")
print(as.data.frame(profiles))

message("\nWrote models/volume_*_model.rds, data/volume_model_validation.csv, ",
        "data/volume_model_coefficients.csv, data/volume_model_profiles.csv")
