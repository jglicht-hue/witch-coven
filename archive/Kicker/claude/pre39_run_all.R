# Runs the whole volume-model pipeline in order, from raw nflverse data to the
# fitted models. Added 2026-09-24.
#
# Run it from the folder that holds the scripts (in RStudio: open the folder
# as a project, or setwd() to it). The first run downloads about 45 MB of
# nflverse data into data/raw/ (see 00_nflverse_data.R); later runs reuse it.
#
#   00_install_packages.R        one-time package install (not run here)
#   00_nflverse_data.R           shared data loader (sourced by the scripts)
#   01_pull_kicker_game_outcomes team-game FG/XP counts; kicker FG attempts/makes by range
#   02_pull_team_covariates      red zone, distance mix, coach FG-or-go and long-range FG rates
#   03_pull_venue_covariates     dome, altitude
#   04_pull_odds_covariates      Vegas implied team total (historical lines)
#   05_pull_kicker_accuracy      kicker accuracy by range, slump flag, XP accuracy
#   06_join_training_data        volume table (regular season) and accuracy table
#   06b_build_volume_features    per-range outcomes, kicker features, pre-game top 16
#   07_fit_volume_models         the four volume models -> models/
#   08_points_distribution       fantasy-point distribution, projection and intervals
#                                (functions only; sourced by 08a and 09b)
#   08a_backtest_points_distribution  checks the projections on past games (added 2026-09-26)
#   09_weekly_inputs             builds the inputs for one week (functions only; sourced by 09a, 09b)
#   09b_weekly_projections       projections for the upcoming week -> data/weekly_*_latest.csv
#                                (added 2026-09-26; needs this season's data, so run in-season)
#   15_accuracy_report           most accurate active kickers (distance-adjusted make rate) -> data/accuracy_report_latest.csv
#                                (added 2026-09-29; runs after 09b, which defines the active kickers)
#   13_scorecard                 grades past weeks' projections against actual scores (added 2026-09-28)
#   (13a_backfill_history is run by hand once; it rebuilt 2026 weeks 1-3)
#
# Experiments (not needed for the models; about 20 minutes together) - set
# RUN_EXPERIMENTS to TRUE to rerun them:
#   07a_volume_model_experiments every comparison and placebo check so far
#   07c_select_volume_predictors the predictor selection behind 07's formulas
#
# Checks (about 3 minutes) - set RUN_CHECKS to TRUE after changing 02, 05, 06b or 09:
#   09a_check_weekly_inputs      confirms 09's weekly inputs match the training tables exactly

RUN_EXPERIMENTS <- FALSE
RUN_CHECKS <- FALSE

PIPELINE <- c("01_pull_kicker_game_outcomes.R", "02_pull_team_covariates.R", "03_pull_venue_covariates.R",
              "04_pull_odds_covariates.R", "05_pull_kicker_accuracy.R", "06_join_training_data.R",
              "06b_build_volume_features.R", "07_fit_volume_models.R", "08a_backtest_points_distribution.R",
              "09b_weekly_projections.R", "15_accuracy_report.R", "13_scorecard.R")
EXPERIMENTS <- c("07a_volume_model_experiments.R", "07c_select_volume_predictors.R")
CHECKS <- c("09a_check_weekly_inputs.R")
SOURCED <- c("00_nflverse_data.R", "08_points_distribution.R", "09_weekly_inputs.R")

to_run <- c(PIPELINE, if (RUN_EXPERIMENTS) EXPERIMENTS, if (RUN_CHECKS) CHECKS)
missing <- c(to_run, SOURCED)[!file.exists(c(to_run, SOURCED))]
if (length(missing)) stop("Not found in ", getwd(), ": ", paste(missing, collapse = ", "),
                          " - run this from the folder that holds the scripts.")

for (script in to_run) {
  message("\n=== ", script, " ===")
  started <- Sys.time()
  source(script, local = new.env(parent = globalenv()))
  message("=== ", script, " done in ", round(as.numeric(difftime(Sys.time(), started, units = "secs"))), "s ===")
}
message("\nAll done.")
