# Part 2 of 2 for to-do #13 (weather): forward selection with placebo checks
# and the adjustment table. Reads the tables written by
# 11_build_weather_tables.R (see its header for data and term definitions).
# Added 2026-09-28; round 2 and the <= pass bar added the same day at the
# user's request.
#
# RULES (set with the user before results were seen)
#   Outcomes / base models: attempts (Poisson, per team-game) ~ implied team
#   total + its square + dome; makes (logistic, per kick) ~ dome.
#   Score: leave-one-season-out mean deviance per row, gain x1000 vs the
#   current model. Placebo: the variables a candidate brings in (or, for an
#   interaction of variables already in the model, the variables inside it)
#   are permuted jointly among each season's outdoor games, N_SHUFFLES times.
#   A candidate passes if its placebo share (shuffles doing at least as well)
#   is <= 0.05. (First run used < 0.05; the user set <= on 2026-09-28 after
#   wind on 50+ attempts landed exactly on 0.050.) Among passing candidates the
#   lowest placebo share is added first (ties: larger gain); the rest are
#   retested; stop when none passes.
#   Round 1: main effects wind, cold, precip.
#   Round 3 (added 2026-09-28 at the user's suggestion, before results; starts
#   from round 2's models): is wind's effect non-linear? Candidates, each on
#   the same rule:
#     wind_sq    : (wind/10)^2, with linear wind added if missing (a curve)
#     wind_bands : two indicators, wind 15-19 mph and wind 20+ mph (a step
#                  shape; 0-14 is the baseline), added to whatever is in the model
#   Placebo: the new columns themselves are shuffled (jointly for the bands).
#   RESULT: only the bands passed, for XP attempts (placebo share 0.045). The
#   user decided on 2026-09-28 to keep wind linear: the bands implied a 20 mph
#   game projects better than a 15 mph game, rest on 42 games with 20+ mph
#   wind, and one pass in 16 tests is about what chance alone produces. Round 3
#   still runs and its steps are written, but the final effects use round 2's
#   models.
#   Round 2 (starting from round 1's models): rain and snow separately (where
#   precip is already in the model only "snow" is offered: precip + snow lets
#   snow differ from rain), wind or cold if not yet in, and the interactions
#   wind:cold, wind:rain, wind:snow, cold:snow (missing main effects are added
#   with them).
#
# Writes:
#   data/weather_selection_steps.csv - every candidate at every step, both rounds
#   data/weather_effects.csv         - adopted terms: coefficient, ratio per unit,
#                                      and each term's average over 2023-2025
#                                      outdoor games (the reference)

suppressMessages({library(dplyr); library(tidyr); library(readr); library(parallel)})
set.seed(20260928)
REF_SEASONS <- 2023:2025
N_SHUFFLES <- if (exists("N_SHUFFLES_OVERRIDE")) N_SHUFFLES_OVERRIDE else 200
PASS_BAR <- 0.05   # pass if placebo share <= PASS_BAR
N_CORES <- max(1, min(4, detectCores()))
games <- read_csv("data/weather_game_table.csv", show_col_types = FALSE)
tg <- read_csv("data/weather_team_games.csv", show_col_types = FALSE)
kicks <- read_csv("data/weather_kicks.csv", show_col_types = FALSE)

ATT_BASE <- "implied_team_total + I(implied_team_total^2) + is_enclosed"
OUTCOMES <- list(
  xp_attempts = list(family = poisson(), base = ATT_BASE, data = "tg"),
  att_039 = list(family = poisson(), base = ATT_BASE, data = "tg"),
  att_4049 = list(family = poisson(), base = ATT_BASE, data = "tg"),
  att_50 = list(family = poisson(), base = ATT_BASE, data = "tg"),
  make_039 = list(family = binomial(), base = "is_enclosed", data = "kicks"),
  make_4049 = list(family = binomial(), base = "is_enclosed", data = "kicks"),
  make_50 = list(family = binomial(), base = "is_enclosed", data = "kicks"),
  make_xp = list(family = binomial(), base = "is_enclosed", data = "kicks"))
games <- games |> mutate(wind_sq = (wind / 10)^2, wind_15_19 = as.integer(wind >= 15 & wind < 20),
                          wind_20plus = as.integer(wind >= 20))
WX_VARS <- c("wind", "cold", "precip", "rain", "snow", "wind_sq", "wind_15_19", "wind_20plus")
gw <- games |> select(game_id, season, is_enclosed, all_of(WX_VARS))
table_for <- function(o) {
  d <- if (OUTCOMES[[o]]$data == "tg") tg |> mutate(y = .data[[o]]) else kicks |> filter(outcome == o) |> mutate(y = made)
  d <- d |> select(-any_of(c("is_enclosed", WX_VARS))) |> left_join(gw |> select(-season), by = "game_id")
  d[unlist(lapply(sort(unique(d$season)), function(s) which(d$season == s))), ]
}
dev_rows <- function(y, mu, fam) {
  if (fam == "poisson") 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu)) else -2 * (y * log(mu) + (1 - y) * log(1 - mu))
}
heldout <- function(d, rhs, fam) {
  f <- as.formula(paste("y ~", rhs)); famobj <- if (fam == "poisson") poisson() else binomial()
  unlist(lapply(sort(unique(d$season)), function(s) {
    fit <- suppressWarnings(glm(f, family = famobj, data = d[d$season != s, ]))
    dev_rows(d$y[d$season == s], predict(fit, newdata = d[d$season == s, ], type = "response"), fam)
  }))
}
terms_of <- function(rhs) attr(terms(as.formula(paste("~", rhs))), "term.labels")
vars_of <- function(rhs) intersect(all.vars(as.formula(paste("~", rhs))), WX_VARS)
# Joint within-season permutation of `vars` among outdoor games
shuffle_vars <- function(d, vars) {
  perm <- gw |> filter(is_enclosed == 0) |> group_by(season) |>
    mutate(src = sample(game_id)) |> ungroup() |> select(game_id, src)
  newvals <- perm |> left_join(gw |> select(src = game_id, all_of(vars)), by = "src") |> select(-src)
  out <- d |> left_join(newvals, by = "game_id", suffix = c("", ".new"))
  for (v in vars) out[[v]] <- ifelse(out$is_enclosed == 0, out[[paste0(v, ".new")]], out[[v]])
  out |> select(-ends_with(".new"))
}

candidates_round <- function(model, round) {
  have <- terms_of(model)
  if (round == 3) {
    c3 <- list()
    if (!"wind_sq" %in% have) c3$wind_sq <- paste(c(if (!"wind" %in% have) "wind", "wind_sq"), collapse = " + ")
    if (!"wind_20plus" %in% have) c3$wind_bands <- "wind_15_19 + wind_20plus"
    return(c3)
  }
  if (round == 1) return(setNames(as.list(setdiff(c("wind", "cold", "precip"), have)), setdiff(c("wind", "cold", "precip"), have)))
  c1 <- list()
  if ("precip" %in% have) { if (!"snow" %in% have) c1$snow <- "snow" } else {
    for (v in c("rain", "snow")) if (!v %in% have) c1[[v]] <- v }
  for (v in c("wind", "cold")) if (!v %in% have) c1[[v]] <- v
  for (ia in c("wind:cold", "wind:rain", "wind:snow", "cold:snow")) {
    if (ia %in% have) next
    parts <- strsplit(ia, ":")[[1]]
    mains <- parts[!parts %in% have & !(parts == "rain" & "precip" %in% have & FALSE)]
    c1[[ia]] <- paste(c(mains, ia), collapse = " + ")
  }
  c1
}

run_round <- function(round, start_models) {
  steps <- list(); final <- start_models
  for (o in names(OUTCOMES)) {
    d <- table_for(o); fam <- OUTCOMES[[o]]$family$family
    model <- start_models[[o]]
    for (step in 1:6) {
      cands <- candidates_round(model, round)
      if (!length(cands)) break
      d_base <- heldout(d, model, fam)
      res <- mclapply(seq_along(cands), function(k) {
        add <- cands[[k]]; full <- paste(model, "+", add)
        set.seed(100000 * round + 1000 * match(o, names(OUTCOMES)) + 10 * step + k)
        d_new <- heldout(d, full, fam)
        gain <- 1000 * mean(d_base - d_new)
        sb <- sum(tapply(d_base - d_new, d$season, mean) > 0)
        p <- NA_real_; p95 <- NA_real_
        if (gain > 0) {
          sv <- setdiff(vars_of(add), vars_of(model)); if (!length(sv)) sv <- vars_of(add)
          pl <- vapply(seq_len(N_SHUFFLES), function(i) 1000 * mean(d_base - heldout(shuffle_vars(d, sv), full, fam)), numeric(1))
          p <- mean(pl >= gain); p95 <- unname(quantile(pl, 0.95))
        }
        tibble(round, outcome = o, step, current_model = model, candidate = names(cands)[k], added = add,
               gain_x1000 = gain, seasons_better_of_10 = sb, placebo_p = p, placebo_95th = p95)
      }, mc.cores = N_CORES)
      if (length(res) != length(cands) || any(vapply(res, function(r) !is.data.frame(r), logical(1))))
        stop("A parallel job failed for ", o, " round ", round, " step ", step)
      res <- bind_rows(res) |> mutate(passes = !is.na(placebo_p) & placebo_p <= PASS_BAR)
      pick <- res |> filter(passes) |> arrange(placebo_p, desc(gain_x1000)) |> slice_head(n = 1)
      steps[[length(steps) + 1]] <- res |> mutate(chosen = candidate %in% pick$candidate)
      message("round ", round, " ", o, " step ", step, ": ",
              paste(sprintf("%s %.3f (p %s)", res$candidate, res$gain_x1000,
                            ifelse(is.na(res$placebo_p), "-", format(res$placebo_p))), collapse = "; "),
              if (nrow(pick)) paste0(" -> add ", pick$candidate) else " -> stop")
      if (!nrow(pick)) break
      model <- paste(model, "+", pick$added)
    }
    final[[o]] <- model
  }
  list(steps = bind_rows(steps), models = final)
}

r1 <- run_round(1, lapply(OUTCOMES, `[[`, "base"))
r2 <- run_round(2, r1$models)
r3 <- run_round(3, r2$models)
write_csv(bind_rows(r1$steps, r2$steps, r3$steps) |> mutate(across(where(is.double), ~ round(.x, 4))), "data/weather_selection_steps.csv")

# --- Final fits and the adjustment table ---------------------------------------------------
ref_games <- games |> filter(is_enclosed == 0, season %in% REF_SEASONS)
term_value <- function(t, df) Reduce(`*`, lapply(strsplit(t, ":")[[1]], function(v) df[[v]]))
effects <- bind_rows(lapply(names(OUTCOMES), function(o) {
  model <- r2$models[[o]]  # round 3's wind bands (XP attempts) were rejected by the user, 2026-09-28
  wx_terms <- Filter(function(t) all(strsplit(t, ":")[[1]] %in% WX_VARS), terms_of(model))
  if (!length(wx_terms)) return(tibble(outcome = o, model = model, term = NA_character_))
  fit <- glm(as.formula(paste("y ~", model)), family = OUTCOMES[[o]]$family, data = table_for(o))
  est <- summary(fit)$coefficients[wx_terms, , drop = FALSE]
  tibble(outcome = o, model = model, term = wx_terms, coefficient = est[, 1], std_error = est[, 2],
         ratio_per_unit = exp(est[, 1]),
         scale = ifelse(OUTCOMES[[o]]$family$family == "poisson", "log expected attempts", "log-odds of a make"),
         reference_outdoor_mean = vapply(wx_terms, function(t) mean(term_value(t, ref_games)), numeric(1)))
})) |> mutate(across(where(is.double), ~ signif(.x, 5)))
write_csv(effects, "data/weather_effects.csv")
print(as.data.frame(effects |> select(-model)))
