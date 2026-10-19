# 18 - Implied-total shape tests (2026-09-29, Kicker Wizerd chat, one-off override of
# "don't edit scripts", user approved). Log: claude/18_implied_total_shape_log.md
# Run from the pipeline folder after run_all.R (needs data/volume_model_table.csv,
# models/, and the 08a input rebuild below). Nothing here changes the production models.
# Sections: (1) raw bins, (2-3) shape tests + placebo, (4) backtest bias by bin,
# (5) week-4 2026 rerun + decomposition (needs 09_weekly_inputs.R and 2026 play-by-play;
# /tmp/kw/latest.csv was a copy of data/weekly_projections_latest.csv's key columns).

# ==== 08a_inputs.R (make-chance inputs exactly as 08a builds them) ====
# Builds per-team-game make-chance inputs exactly as 08a does (sourced by tests).
suppressMessages({library(dplyr); library(tidyr); library(readr)})
HALF_LIFE <- 12; RATE_HALF_LIFE <- 32; W <- 5
RANGES <- c("0-39" = "039", "40-49" = "4049", "50+" = "50")
vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE)
acc <- read_csv("data/kicker_training_table.csv", show_col_types = FALSE)
k05 <- read_csv("data/kicker_game_accuracy.csv", show_col_types = FALSE)
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
  mutate(ord = season * 100 + week, tot = attempts_039 + attempts_4049 + attempts_50) |>
  arrange(kicker_player_id, ord)
lg_rate <- sapply(setNames(RANGES, RANGES), function(r) sum(kg[[paste0("makes_", r)]]) / sum(kg[[paste0("attempts_", r)]]))
acc_log_rate <- kg |> group_by(kicker_player_id) |>
  mutate(across(c(starts_with("attempts_"), starts_with("makes_")), ~ running_after(.x, RATE_HALF_LIFE), .names = "d_{.col}")) |>
  ungroup()
for (r in RANGES) {
  s <- state_before(acc_log_rate, c(paste0("d_makes_", r), paste0("d_attempts_", r)))
  L <- lg_rate[[r]]
  vol[[paste0("a_", r)]] <- s[, 1] + W * L
  vol[[paste0("b_", r)]] <- (s[, 2] - s[, 1]) + W * (1 - L)
}
vol <- vol |> left_join(k05 |> transmute(game_id, kicker_player_id, slump_ratio = final_rate_0_39 / long_run_rate_0_39),
                        by = c("game_id", "kicker_player_id")) |> mutate(slump_ratio = replace_na(slump_ratio, 1))
for (r in RANGES) vol[[paste0("p_", r)]] <- vol[[paste0("a_", r)]] / (vol[[paste0("a_", r)]] + vol[[paste0("b_", r)]]) * vol$slump_ratio
primary <- kg |> group_by(game_id, posteam) |> slice_max(tot, n = 1, with_ties = FALSE) |> ungroup() |>
  select(game_id, posteam, ord, kicker_player_id)
xp_log <- primary |> left_join(team_counts |> select(game_id, posteam, xp_attempts, xp_makes), by = c("game_id", "posteam")) |>
  arrange(kicker_player_id, ord) |> group_by(kicker_player_id) |>
  mutate(d_xp_makes = running_after(xp_makes, HALF_LIFE), d_xp_attempts = running_after(xp_attempts, HALF_LIFE)) |> ungroup()
lg_xp <- sum(team_counts$xp_makes) / sum(team_counts$xp_attempts)
s <- state_before(xp_log, c("d_xp_makes", "d_xp_attempts"))
vol$p_xp <- (s[, 1] + 100 * lg_xp) / (s[, 2] + 100)

# ==== (1) t1_bins.R ====
suppressMessages({library(dplyr); library(readr)})
vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE) |>
  mutate(fg_pts = 3*mk_039 + 4*mk_4049 + 5*mk_50 - (fg_attempts - fg_makes),
         att_40p = att_4049 + att_50,
         bin = cut(implied_team_total, c(-Inf, 19, 21, 23, 25, 27, Inf), right = FALSE,
                   labels = c("<19", "19-21", "21-23", "23-25", "25-27", "27+")))
fit039 <- glm(att_039 ~ implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8 +
                is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate, poisson, vol[vol$top16pre, ])
vol$fit039 <- predict(fit039, vol, type = "response")
b <- coef(fit039); message("0-39 squared-term peak at implied total = ", round(-b[2] / (2 * b[3]), 2))
summ <- function(d, who) d |> group_by(bin) |> summarise(
  who = who, n = n(), implied = mean(implied_team_total),
  se039 = sd(att_039)/sqrt(n()), se40 = sd(att_40p)/sqrt(n()), sefg = sd(fg_attempts)/sqrt(n()),
  septs = sd(fg_pts)/sqrt(n()), sefpts = sd(fpts)/sqrt(n()),
  xp = mean(xp_attempts), att_039 = mean(att_039), fit039 = mean(fit039), att_40p = mean(att_40p),
  fg_att = mean(fg_attempts), fg_pts = mean(fg_pts), fpts = mean(fpts), .groups = "drop")
out <- bind_rows(summ(vol[vol$top16pre, ], "top16pre"), summ(vol, "all"))
write_csv(out, "t1_bins.csv")
print(as.data.frame(out |> mutate(across(where(is.double), ~ round(.x, 2)))), width = 250)
# Where do top-16 training rows sit?
message("Top-16 rows with implied >= 23: ", sum(vol$top16pre & vol$implied_team_total >= 23), " of ", sum(vol$top16pre))

# ==== (2-3) t23_shapes.R ====
suppressMessages({library(dplyr); library(readr); library(splines)})
set.seed(20260929)
vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE)
train <- vol |> filter(top16pre) |> mutate(it = implied_team_total)
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
S <- sort(unique(train$season))
loso <- function(d, outcome, rhs) {
  unlist(lapply(S, function(s) {
    fit <- glm(as.formula(paste(outcome, "~", rhs)), family = poisson, data = d[d$season != s, ])
    predict(fit, newdata = d[d$season == s, ], type = "response") }))
}
ord <- unlist(lapply(S, function(s) which(train$season == s)))
y_of <- function(o) train[[o]][ord]; seas <- train$season[ord]
score <- function(outcome, rhs, ref_rhs, d = train) {
  y <- d[[outcome]][ord]; m <- loso(d, outcome, rhs); r <- loso(d, outcome, ref_rhs)
  g <- dev_i(y, r) - dev_i(y, m)
  c(error = 1000 * mean(dev_i(y, m)), gain = 1000 * mean(g), gain_se = 1000 * sd(g) / sqrt(length(g)),
    seasons_better = sum(tapply(g, seas, mean) > 0))
}
SHAPES <- c(squared_current = "it + I(it^2)", linear = "it", bend23 = "it + pmax(it - 23, 0)",
            flat_after23 = "pmin(it, 23)", spline3 = "ns(it, df = 3)", none = NULL)
REST039 <- "opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"
cur039 <- paste("it + I(it^2) +", REST039)
t2 <- bind_rows(lapply(c(names(SHAPES), "none"), function(nm) {
  rhs <- if (nm == "none") REST039 else paste(SHAPES[[nm]], "+", REST039)
  as_tibble(as.list(score("att_039", rhs, cur039))) |> mutate(shape = nm, .before = 1)
}))
message("\nTEST 2: 0-39 shapes vs current squared term (gain > 0 = better than current)")
print(as.data.frame(t2 |> mutate(across(where(is.double), ~ round(.x, 2)))))
# Same for total FG attempts and FG points-relevant sum? total FG attempts, shapes alone + coach + dome
t2b <- bind_rows(lapply(names(SHAPES), function(nm)
  as_tibble(as.list(score("fg_attempts", paste(SHAPES[[nm]], "+ is_enclosed + coach_long_fg_rate"),
                          "is_enclosed + coach_long_fg_rate"))) |> mutate(shape = nm, .before = 1)))
message("\nContext: total FG attempts, implied-total shape added to dome + coach long rate")
print(as.data.frame(t2b |> mutate(across(where(is.double), ~ round(.x, 2)))))
write_csv(bind_rows(t2 |> mutate(test = "0-39 shape vs current"), t2b |> mutate(test = "total FG: shape added")), "t2_results.csv")

# TEST 3: add implied total to 40-49 and 50+
BASE <- c(att_4049 = "is_enclosed + krate_4049 + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
          att_50 = "is_enclosed + krate_40plus + is_enclosed:krate_50")
ADD <- c(linear = "it", flat_after23 = "pmin(it, 23)", spline3 = "ns(it, df = 3)", squared = "it + I(it^2)")
t3 <- bind_rows(lapply(names(BASE), function(o) bind_rows(lapply(names(ADD), function(a)
  as_tibble(as.list(score(o, paste(BASE[[o]], "+", ADD[[a]]), BASE[[o]]))) |>
    mutate(outcome = o, added = a, .before = 1)))))
# placebo for each added form: shuffle implied within season
placebo <- function(o, add_rhs, n = 500) {
  real <- score(o, paste(BASE[[o]], "+", add_rhs), BASE[[o]])[["gain"]]
  ref <- loso(train, o, BASE[[o]]); y <- train[[o]][ord]; ref_dev <- dev_i(y, ref)
  sh <- replicate(n, { d <- train |> group_by(season) |> mutate(it = sample(it)) |> ungroup()
    1000 * mean(ref_dev - dev_i(y, loso(d, o, paste(BASE[[o]], "+", add_rhs)))) })
  c(placebo_share = mean(sh >= real), placebo_95th = unname(quantile(sh, 0.95)))
}
t3 <- t3 |> rowwise() |> mutate(pl = list(if (gain > 0) placebo(outcome, ADD[[added]]) else c(placebo_share = NA, placebo_95th = NA))) |>
  mutate(placebo_share = pl[["placebo_share"]], placebo_95th = pl[["placebo_95th"]]) |> select(-pl) |> ungroup()
message("\nTEST 3: implied total added to 40-49 / 50+ (gain vs current model)")
print(as.data.frame(t3 |> mutate(across(where(is.double), ~ round(.x, 3)))))
write_csv(t3, "t3_results.csv")

# ==== (4) t4_bias.R ====
source("08a_inputs.R"); suppressMessages(library(splines))
test <- vol |> filter(top16pre) |> mutate(it = implied_team_total)
F <- list(xp_attempts = "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8 + coach_long_fg_rate",
  att_039 = "it + I(it^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
  att_4049 = "is_enclosed + krate_4049 + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
  att_50 = "is_enclosed + krate_40plus + is_enclosed:krate_50")
F_alt <- F; F_alt$att_039 <- sub("it \\+ I\\(it\\^2\\)", "ns(it, df = 3)", F$att_039)
proj <- function(Fs) bind_rows(lapply(sort(unique(test$season)), function(s) {
  tr <- test[test$season != s, ]; h <- test[test$season == s, ]
  lam <- lapply(Fs, function(f) predict(glm(as.formula(paste(names(Fs)[which(sapply(Fs, identical, f))][1], "~", f)), poisson, tr), h, type = "response"))
  names(lam) <- names(Fs)
  h |> mutate(l_xp = lam$xp_attempts, l039 = lam$att_039, l4049 = lam$att_4049, l50 = lam$att_50)
}))
fg_proj <- function(d) with(d, 3*l039*p_039 + 4*l4049*p_4049 + 5*l50*p_50 - (l039*(1-p_039) + l4049*(1-p_4049) + l50*(1-p_50)))
res <- bind_rows(lapply(list(current = F, spline3_039 = F_alt), function(Fs) {
  d <- proj(Fs) |> mutate(fg_pts = 3*mk_039 + 4*mk_4049 + 5*mk_50 - (fg_attempts - fg_makes),
                          fg_hat = fg_proj(cur_data()), xp_hat = l_xp * p_xp, tot_hat = fg_hat + xp_hat)
  d
}), .id = "model") |>
  mutate(bin = cut(implied_team_total, c(-Inf, 19, 21, 23, 25, 27, Inf), right = FALSE,
                   labels = c("<19", "19-21", "21-23", "23-25", "25-27", "27+")))
out <- res |> group_by(model, bin) |> summarise(n = n(),
  fg_att_actual = mean(fg_attempts), fg_att_proj = mean(l039 + l4049 + l50),
  fg_pts_actual = mean(fg_pts), fg_pts_proj = mean(fg_hat),
  fg_resid = mean(fg_pts - fg_hat), fg_resid_lo = fg_resid - 1.96 * sd(fg_pts - fg_hat) / sqrt(n()),
  fg_resid_hi = fg_resid + 1.96 * sd(fg_pts - fg_hat) / sqrt(n()),
  tot_resid = mean(fpts - tot_hat), tot_resid_se = sd(fpts - tot_hat) / sqrt(n()), .groups = "drop")
hi <- res |> filter(implied_team_total >= 25) |> group_by(model) |> summarise(n = n(),
  fg_resid = mean(fg_pts - fg_hat), lo = fg_resid - 1.96*sd(fg_pts - fg_hat)/sqrt(n()), hi = fg_resid + 1.96*sd(fg_pts - fg_hat)/sqrt(n()),
  tot_resid = mean(fpts - tot_hat), mse = mean((fpts - tot_hat)^2), .groups = "drop")
allm <- res |> group_by(model, season) |> summarise(mse = mean((fpts - tot_hat)^2), .groups = "drop")
print(as.data.frame(out |> mutate(across(where(is.double), ~ round(.x, 2)))), width = 250)
message("\nImplied total 25+ combined:"); print(as.data.frame(hi |> mutate(across(where(is.double), ~ round(.x, 3)))))
message("\nPoints MSE by season:"); print(as.data.frame(allm |> mutate(mse = round(mse, 3))))
write_csv(out, "t4_bias_bins.csv"); write_csv(hi, "t4_bias_25plus.csv"); write_csv(allm, "t4_mse.csv")

# ==== (5) t5_week4.R ====
suppressMessages({library(dplyr); library(readr); library(splines)})
source("00_nflverse_data.R"); source("09_weekly_inputs.R"); source("08_points_distribution.R")
pbp <- load_pbp_data(2023:2026); sched <- load_schedule_data(2023:2026)
inp <- build_week_inputs(pbp, sched, 2026, 4, pregame_kicker_for_played = TRUE) |> mutate(it = implied_team_total)
vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE)
train <- vol |> filter(top16pre) |> mutate(it = implied_team_total)
fits <- lapply(c("xp_attempts", "att_039", "att_4049", "att_50"), function(o) readRDS(paste0("models/volume_", o, "_model.rds")))
names(fits) <- c("xp_attempts", "att_039", "att_4049", "att_50")
cur039 <- glm(att_039 ~ it + I(it^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate, poisson, train)
alt039 <- glm(att_039 ~ ns(it, df = 3) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate, poisson, train)
gam <- read_csv("models/points_gamma.csv", show_col_types = FALSE)$gamma
fits_alt <- fits; fits_alt$att_039 <- alt039
gam_alt <- estimate_gamma(fits_alt, train)
p <- inp |> mutate(l_xp = predict(fits$xp_attempts, inp, type = "response"),
                   l039 = predict(fits$att_039, inp, type = "response"),
                   l039_alt = predict(alt039, inp, type = "response"),
                   l4049 = predict(fits$att_4049, inp, type = "response"),
                   l50 = predict(fits$att_50, inp, type = "response"),
                   proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp),
                   proj_alt = projected_points(l_xp, l039_alt, l4049, l50, p_039, p_4049, p_50, p_xp))
file <- read_csv("/tmp/kw/latest.csv", show_col_types = FALSE)
chk <- p |> select(posteam, kicker_player_name, it, proj, proj_alt, l039, l039_alt, l4049, l50, l_xp) |>
  left_join(file |> select(posteam = team, file_proj = projected_points, file_it = implied_team_total, file_l039 = exp_att_039), by = "posteam") |>
  arrange(desc(proj_alt))
print(as.data.frame(chk |> mutate(across(where(is.double), ~ round(.x, 3)))), width = 250)
message("max |rebuilt current - file| projection: ", round(max(abs(chk$proj - chk$file_proj)), 4),
        "; implied totals identical for ", sum(abs(chk$it - chk$file_it) < 1e-9), " of ", nrow(chk))
write_csv(p, "t5_week4_inputs.csv")
# Decompose log(expected attempts) for the kickers in question vs a training-median team
dec <- function(fit, rows) {
  X <- model.matrix(delete.response(terms(fit)), rows); b <- coef(fit)
  base <- model.matrix(delete.response(terms(fit)), as.data.frame(lapply(train[, all.vars(formula(fit))[-1], drop = FALSE], median)) |> mutate(it = median(train$it)))
  contr <- sweep(X[, names(b), drop = FALSE], 2, b, "*") - matrix(base[, names(b)] * b, nrow(X), length(b), byrow = TRUE)
  cbind(rows |> select(kicker_player_name), as.data.frame(round(contr, 3)), total_log_ratio = round(rowSums(contr), 3))
}
who <- inp |> filter(kicker_player_name %in% c("S.Shrader", "H.Mevis", "N.Folk", "T.Smack"))
message("\n0-39 model: contribution to log expected attempts vs a median training team-game")
print(dec(fits$att_039, who |> mutate(implied_team_total = it)))
message("\n40-49 model:"); print(dec(fits$att_4049, who))
message("\nInputs:"); print(as.data.frame(who |> select(kicker_player_name, it, opp_redzone_td_rate_allowed_trail8, coach_long_fg_rate, is_enclosed, krate_4049, kshare_4049_hlall, krate_40plus, krate_50) |> mutate(across(where(is.double), ~ round(.x, 3)))))
message("Training medians: opp RZ TD allowed ", round(median(train$opp_redzone_td_rate_allowed_trail8), 3), ", coach long ", round(median(train$coach_long_fg_rate), 3),
        ", kshare_4049 ", round(median(train$kshare_4049_hlall), 3), ", krate_4049 ", round(median(train$krate_4049), 3))
