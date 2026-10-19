# Tests fixes for the points distributions being too wide (to-do: width fix).
# Rules set with the user on 2026-09-28 BEFORE results were seen. Not part of
# the weekly run.
#
# Candidates
#   A: today - XP attempts and FG attempts by range independent Poisson
#   B: FG attempts in range r depend on the game's XP attempts k:
#      lambda_r * exp(gamma_r * (k - lambda_xp)), rescaled to keep the mean
#   C: B, plus XP attempts drawn from a binomial with the XP model's measured
#      dispersion (variance = xp_disp x mean) instead of Poisson
#   Means (projected points) and the confidence interval are unchanged by
#   construction; only the shape/spread of the distribution changes.
# Estimation: inside each leave-one-season-out fold, the four volume models
#   (07's formulas) are refit on the other seasons' pre-game top-16 team-games;
#   gamma_r = coefficient on (xp_attempts - fitted XP) in a Poisson regression of
#   att_r with offset log(fitted att_r), on those training rows; xp_disp = the
#   XP model's Pearson dispersion on those rows.
# Scoring: the 832 held-out team-games of 08a (same lambdas and make chances).
#   Log score = mean log probability given to the actual fantasy points.
# RULE: a candidate is eligible if its log score beats A in >= 2 of 3 seasons;
#   adopt the eligible candidate with the best overall log score. Also
#   reported: 80% range hit rate vs claimed, and spread ratio (actual variance
#   of points around the projection / the distributions' average variance).
#
# Reads data/volume_model_table.csv (06b), data/points_backtest_games.csv
# (08a), models/volume_*_model.rds (07, formulas only). Writes
# data/width_fix_results.csv and data/width_fix_parameters.csv.

suppressMessages({library(dplyr); library(readr)})
source("08_points_distribution.R")

vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE) |> filter(top16pre)
bt <- read_csv("data/points_backtest_games.csv", show_col_types = FALSE)
MODEL_NAMES <- c("xp_attempts", "att_039", "att_4049", "att_50")
formulas <- lapply(setNames(MODEL_NAMES, MODEL_NAMES), function(o)
  formula(readRDS(file.path("models", paste0("volume_", o, "_model.rds")))))

estimate_params <- function(train) {
  fits <- lapply(formulas, function(f) glm(f, family = poisson, data = train))
  mu <- lapply(fits, function(f) predict(f, train, type = "response"))
  dxp <- train$xp_attempts - mu$xp_attempts
  gamma <- sapply(c("att_039", "att_4049", "att_50"), function(o)
    coef(glm(train[[o]] ~ dxp + offset(log(mu[[o]])), family = poisson))[["dxp"]])
  f <- fits$xp_attempts
  c(gamma, xp_disp = sum(residuals(f, type = "pearson")^2) / f$df.residual)
}

params <- bind_rows(lapply(sort(unique(bt$season)), function(s)
  as_tibble(as.list(estimate_params(vol[vol$season != s, ]))) |> mutate(held_out_season = s)))
print(params)

CANDS <- list(A = function(pp) list(gamma = c(0, 0, 0), xp_disp = 1),
              B = function(pp) list(gamma = unlist(pp[c("att_039", "att_4049", "att_50")]), xp_disp = 1),
              C = function(pp) list(gamma = unlist(pp[c("att_039", "att_4049", "att_50")]), xp_disp = pp[["xp_disp"]]))

res <- bind_rows(lapply(seq_len(nrow(bt)), function(i) {
  g <- bt[i, ]; pp <- params[params$held_out_season == g$season, ]
  bind_rows(lapply(names(CANDS), function(cn) {
    a <- CANDS[[cn]](pp)
    pm <- points_pmf_dep(g$lambda_xp, g$lambda_039, g$lambda_4049, g$lambda_50, g$p_039, g$p_4049, g$p_50, g$p_xp,
                         gamma = a$gamma, xp_disp = a$xp_disp)
    sm <- summarise_pmf(pm)
    p_act <- pm$prob[match(g$fpts, pm$points)]
    tibble(candidate = cn, season = g$season, fpts = g$fpts, mean = sm[["projected_points"]], var = sm[["sd_points"]]^2,
           lo = sm[["outcome_low"]], hi = sm[["outcome_high"]], claimed = sm[["outcome_range_prob"]],
           logp = log(max(ifelse(is.na(p_act), 0, p_act), 1e-12)))
  }))
}))
summ <- function(d) d |> summarise(team_games = n(), log_score = mean(logp),
                                   range_hit = mean(fpts >= lo & fpts <= hi), range_claimed = mean(claimed),
                                   spread_ratio = var(fpts - mean) / mean(var), mean_projection = mean(mean), .groups = "drop")
out <- bind_rows(res |> group_by(candidate, season) |> summ() |> mutate(season = as.character(season)),
                 res |> group_by(candidate) |> summ() |> mutate(season = "all"))
a_ls <- out |> filter(candidate == "A") |> select(season, a_log = log_score)
out <- out |> left_join(a_ls, by = "season")
elig <- out |> filter(season != "all", candidate != "A") |> group_by(candidate) |>
  summarise(seasons_better = sum(log_score > a_log), .groups = "drop")
out <- out |> left_join(elig, by = "candidate") |> select(-a_log)
pick <- out |> filter(season == "all", !is.na(seasons_better), seasons_better >= 2) |> slice_max(log_score, n = 1)
write_csv(out |> mutate(across(where(is.double), ~ round(.x, 4))), "data/width_fix_results.csv")
write_csv(params |> mutate(across(where(is.double), ~ round(.x, 5))), "data/width_fix_parameters.csv")
print(as.data.frame(out |> arrange(season, candidate) |> mutate(across(where(is.double), ~ round(.x, 4)))))
message("Adopt: ", if (nrow(pick)) pick$candidate else "none - keep A")
# Parameters for production (fit on all three seasons), reported for the adopted candidate
print(estimate_params(vol))
