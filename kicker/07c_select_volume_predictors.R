# Chooses which predictors go into the volume models, under the decision rule
# set by the user on 2026-09-24:
#
#   - Judged AND trained on pre-game top-16 team-games (kickers ranked top 16
#     by fantasy points per game going into that week - see 06b).
#   - A term is kept if it beats at least 95% of placebo shuffles: the share
#     of shuffles that did at least as well as the real variable is below 0.05.
#
# Scoring: leave-one-season-out (fit on the pre-game top-16 team-games of two
# seasons, predict the third season's pre-game top-16 team-games, rotate).
# Error = mean Poisson deviance per team-game; gain = how much a term lowers
# it (x1000, positive = better).
#
# Placebo: the variables a term brings in are shuffled within each season
# (same values, no real link to the outcome) and the model is refit with the
# shuffled version, N_SHUFFLES times. If a term only combines variables already
# in the model (e.g. an interaction or a squared term), the variables inside
# that term are shuffled instead.
#
# Two parts:
#   1. CHECK of the models adopted on 2026-09-23/24 (chosen under earlier
#      views): each term is tested by dropping it. Report only - nothing is
#      removed automatically. Main effects that are part of an interaction or
#      squared term in the same model aren't tested on their own.
#   2. FORWARD SELECTION starting from the adopted models (user OK'd
#      2026-09-24): try every candidate, add the one with the lowest placebo
#      share among those that pass (ties: larger gain), retest the rest
#      against the updated model, stop when nothing passes.
#
# Reads data/volume_model_table.csv (06b). Writes:
#   data/volume_selection_checks.csv  - part 1
#   data/volume_selection_steps.csv   - part 2, every candidate at every step
#   data/volume_selected_models.csv   - the resulting formula per outcome
#
# Multiple testing: at a 0.05 bar, about 1 in 20 useless candidates passes by
# luck. Each step tests dozens of candidates, so expect roughly one lucky pass
# per couple of steps - the steps file shows each pass's gain and seasons won
# so borderline additions can be judged.

suppressMessages({library(dplyr); library(readr); library(parallel)})

MODEL_TABLE_PATH <- "data/volume_model_table.csv"
if (!file.exists(MODEL_TABLE_PATH)) stop("Missing ", MODEL_TABLE_PATH, " - run 06b_build_volume_features.R first.")
vol <- read_csv(MODEL_TABLE_PATH, show_col_types = FALSE)

N_SHUFFLES <- 500
PASS_BAR <- 0.05
MAX_STEPS <- 6
N_CORES <- max(1, min(4, detectCores() - 0))

IMPLIED2 <- "implied_team_total + I(implied_team_total^2)"
ADOPTED <- list(
  xp_attempts = "implied_team_total",
  att_039     = IMPLIED2,
  att_4049    = "is_enclosed * krate_4049",
  att_50      = "is_enclosed + krate_40plus + is_enclosed:krate_50")

TEAM_CANDIDATES <- c(
  implied = "implied_team_total", implied_quadratic = IMPLIED2,
  coach_fg_or_go = "coach_fg_or_go_rate", coach_long_fg = "coach_long_fg_rate",
  dome = "is_enclosed", altitude = "is_high_altitude",
  redzone_td_rate = "redzone_td_rate_trail8", redzone_trips = "redzone_trips_per_game_trail8",
  opp_redzone_td_allowed = "opp_redzone_td_rate_allowed_trail8",
  all_3_red_zone = "redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8")
TEAM_SHARE <- c("039" = "share_0_39_trail8", "4049" = "share_40_49_trail8", "50" = "share_50plus_trail8")
candidates_for <- function(outcome) {
  if (outcome == "xp_attempts") return(TEAM_CANDIDATES)
  r <- sub("att_", "", outcome)
  c(TEAM_CANDIDATES,
    krate_039 = "krate_039", krate_4049 = "krate_4049", krate_50 = "krate_50", krate_40plus = "krate_40plus",
    kvol_own_hl12 = paste0("kvol_", r, "_hl12"), kvol_own_all = paste0("kvol_", r, "_hlall"),
    kvol_total_hl12 = "kvol_total_hl12",
    kshare_own_hl12 = paste0("kshare_", r, "_hl12"), kshare_own_all = paste0("kshare_", r, "_hlall"),
    team_share_own_trail8 = TEAM_SHARE[[r]],
    dome_x_krate_039 = "is_enclosed * krate_039", dome_x_krate_4049 = "is_enclosed * krate_4049",
    dome_x_krate_50 = "is_enclosed * krate_50", dome_x_krate_40plus = "is_enclosed * krate_40plus",
    dome_x_coach_long = "is_enclosed * coach_long_fg_rate",
    implied_x_krate_40plus = "implied_team_total * krate_40plus")
}

# --- Scoring on pre-game top-16 team-games ------------------------------------------
SEASONS_ <- sort(unique(vol$season))
test_rows <- unlist(lapply(SEASONS_, function(s) which(vol$season == s & vol$top16pre)))
season_of <- vol$season[test_rows]
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))

heldout_dev <- function(outcome, rhs, data = vol) {
  f <- as.formula(paste(outcome, "~", rhs))
  mu <- unlist(lapply(SEASONS_, function(s) {
    fit <- suppressWarnings(glm(f, family = poisson, data = data[data$season != s & data$top16pre, ]))
    predict(fit, newdata = data[data$season == s & data$top16pre, ], type = "response")
  }))
  dev_i(data[[outcome]][test_rows], mu)
}
gain_of <- function(d_ref, d_new) 1000 * mean(d_ref - d_new)
seasons_better <- function(d_ref, d_new) sum(tapply(d_ref - d_new, season_of, mean) > 0)

terms_of <- function(rhs) if (rhs == "1") character(0) else attr(terms(as.formula(paste("~", rhs))), "term.labels")
vars_of <- function(rhs) if (rhs == "1") character(0) else all.vars(as.formula(paste("~", rhs)))
join_terms <- function(t) if (length(t)) paste(t, collapse = " + ") else "1"

# Placebo share for adding `piece` (formula text of the new terms) to `base`.
# shuffle_vars are replaced inside `piece` by within-season shuffled copies.
placebo_share <- function(outcome, base, piece, shuffle_vars, real_gain, d_base, seed) {
  set.seed(seed)
  rows_by_season <- lapply(SEASONS_, function(s) which(vol$season == s))
  gains <- vapply(seq_len(N_SHUFFLES), function(i) {
    tmp <- vol
    pl_piece <- piece
    perm <- unlist(lapply(rows_by_season, function(idx) idx[sample.int(length(idx))]))
    rows <- unlist(rows_by_season)
    for (j in seq_along(shuffle_vars)) {
      nm <- paste0("pv_", j)
      tmp[[nm]] <- vol[[shuffle_vars[j]]]
      tmp[[nm]][rows] <- vol[[shuffle_vars[j]]][perm]
      pl_piece <- gsub(paste0("\\b", shuffle_vars[j], "\\b"), nm, pl_piece, perl = TRUE)
    }
    gain_of(d_base, heldout_dev(outcome, join_terms(c(terms_of(base), pl_piece)), data = tmp))
  }, numeric(1))
  c(p = mean(gains >= real_gain), placebo_95th = unname(quantile(gains, 0.95)))
}

# --- Part 1: check each term of the adopted models ---------------------------------------
check_rows <- list()
for (outcome in names(ADOPTED)) {
  full <- ADOPTED[[outcome]]
  full_terms <- terms_of(full)
  d_full <- heldout_dev(outcome, full)
  for (t in full_terms) {
    others <- setdiff(full_terms, t)
    part_of_higher <- any(vapply(others, function(o) t %in% vars_of(o) && o != t, logical(1)))
    if (part_of_higher) {
      check_rows[[length(check_rows) + 1]] <- tibble(outcome, adopted_model = full, term = t,
        gain_from_term = NA_real_, seasons_better = NA_integer_, placebo_p = NA_real_, passes = NA,
        note = "not tested alone: part of an interaction or squared term in this model")
      next
    }
    reduced <- join_terms(others)
    d_red <- heldout_dev(outcome, reduced)
    g <- gain_of(d_red, d_full)
    sv <- setdiff(vars_of(t), vars_of(reduced))
    if (!length(sv)) sv <- vars_of(t)
    pl <- placebo_share(outcome, reduced, t, sv, g, d_red, seed = 1000 + length(check_rows))
    check_rows[[length(check_rows) + 1]] <- tibble(outcome, adopted_model = full, term = t,
      gain_from_term = g, seasons_better = seasons_better(d_red, d_full), placebo_p = pl[["p"]],
      passes = pl[["p"]] < PASS_BAR, note = paste("tested by dropping it; shuffled:", paste(sv, collapse = ", ")))
    message("check ", outcome, " | ", t, ": gain ", round(g, 2), ", placebo p ", pl[["p"]])
  }
}
checks <- bind_rows(check_rows) |> mutate(across(where(is.double), ~ round(.x, 3)))
dir.create("data", showWarnings = FALSE)
write_csv(checks, "data/volume_selection_checks.csv")

# --- Part 2: forward selection from the adopted models ------------------------------------
step_rows <- list()
selected <- list()
for (outcome in names(ADOPTED)) {
  model <- ADOPTED[[outcome]]
  cands <- candidates_for(outcome)
  for (step in seq_len(MAX_STEPS)) {
    d_model <- heldout_dev(outcome, model)
    todo <- Filter(function(n) length(setdiff(terms_of(join_terms(c(terms_of(model), terms_of(cands[[n]])))),
                                              terms_of(model))) > 0, names(cands))
    res <- mclapply(seq_along(todo), function(k) {
      n <- todo[k]
      new_terms <- setdiff(terms_of(join_terms(c(terms_of(model), terms_of(cands[[n]])))), terms_of(model))
      d_new <- heldout_dev(outcome, join_terms(c(terms_of(model), new_terms)))
      g <- gain_of(d_model, d_new)
      out <- tibble(outcome, step, current_model = model, candidate = n, added_terms = paste(new_terms, collapse = " + "),
                    gain = g, seasons_better = seasons_better(d_model, d_new), placebo_p = NA_real_, placebo_95th = NA_real_)
      if (g > 0) {
        sv <- setdiff(vars_of(join_terms(new_terms)), vars_of(model))
        if (!length(sv)) sv <- vars_of(join_terms(new_terms))
        pl <- placebo_share(outcome, model, paste(new_terms, collapse = " + "), sv, g, d_model,
                            seed = 100000 * match(outcome, names(ADOPTED)) + 1000 * step + k)
        out$placebo_p <- pl[["p"]]; out$placebo_95th <- pl[["placebo_95th"]]
      }
      out
    }, mc.cores = N_CORES) |> bind_rows() |>
      mutate(passes = !is.na(placebo_p) & placebo_p < PASS_BAR)
    pick <- res |> filter(passes) |> arrange(placebo_p, desc(gain)) |> slice_head(n = 1)
    res <- res |> mutate(chosen = candidate %in% pick$candidate)
    step_rows[[length(step_rows) + 1]] <- res
    if (!nrow(pick)) {
      message(outcome, " step ", step, ": nothing passes - stop")
      break
    }
    message(outcome, " step ", step, ": add ", pick$candidate, " (gain ", round(pick$gain, 2),
            ", placebo p ", pick$placebo_p, ")")
    model <- join_terms(c(terms_of(model), strsplit(pick$added_terms, " \\+ ")[[1]]))
  }
  selected[[outcome]] <- tibble(outcome, adopted_model = ADOPTED[[outcome]], selected_model = model)
}
steps <- bind_rows(step_rows) |> mutate(across(where(is.double), ~ round(.x, 3)))
write_csv(steps, "data/volume_selection_steps.csv")
selected_models <- bind_rows(selected)
write_csv(selected_models, "data/volume_selected_models.csv")
message("Wrote data/volume_selection_checks.csv, data/volume_selection_steps.csv, data/volume_selected_models.csv")
print(as.data.frame(selected_models))
