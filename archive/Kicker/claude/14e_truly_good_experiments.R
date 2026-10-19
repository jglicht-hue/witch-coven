# Experiment (to-do #19): a lighter blend for "truly good" kickers. Added 2026-09-29. Not part of the weekly run.
# Log: claude/14e_truly_good_log.md. Reuses data/fade_prior_inputs.rds (14c) for volume, XP and actual points.
#
# RULES (set with the user 2026-09-29, before any results were seen):
#   Truly good (pre-game, recomputed before every game from earlier kicks only): make rate beats the
#     distance-based expectation (league-wide logistic of make on distance, cubic, over the 4-season window)
#     by >= 5 points on >= 20 FG attempts in the window (no fade, no dome adjustment) - the same rule as the
#     weekly accuracy report (15_accuracy_report.R).
#   Change: their FG make chances use a lighter blend weight w_good in {0, 1, 2, 3}; everyone else stays at
#     the current setting (32-game fade, weight 5). The truly good also keep the 32-game fade.
#   Data: every kicker-game, 2016-2025 regular season.
#   Decides: pairwise hit rate within the pre-game top 16. w_good chosen leave-one-season-out (9 seasons),
#     scored on the 10th. Adopt only if (1) better than the current setting in >= 95% of 2,000 week-block
#     bootstrap resamples, (2) better in >= 7 of 10 held-out seasons, (3) the all-kicker hit rate is not
#     worse in >= 95% of resamples.
#   Reported, not deciding: how often kickers are flagged; hit rate on top-16 pairs with at least one flagged
#     kicker; Brier score.

suppressMessages({library(dplyr); library(tidyr); library(readr)})
source("00_nflverse_data.R"); source("09_weekly_inputs.R")
set.seed(20260929)
d <- readRDS("data/fade_prior_inputs.rds"); d$top16pre <- coalesce(d$top16pre, FALSE)
d$ord <- d$season * 100 + d$week
PTS <- c("039", "4049", "50"); base_cols <- c(outer(c("att_", "mk_"), PTS, paste0))
SEASONS <- sort(unique(d$season))
new_cols <- c(paste0("h32_", base_cols), "c_att", "c_mk", "c_exp")
for (c in new_cols) d[[c]] <- NA_real_
for (S in SEASONS) {
  pbp <- load_pbp_data((S - 3):S)
  kp <- pbp |> filter(field_goal_attempt == 1, !is.na(kicker_player_id)) |>
    mutate(made = as.integer(field_goal_result == "made"), r = case_when(kick_distance <= 39 ~ "039", kick_distance <= 49 ~ "4049", TRUE ~ "50"))
  # distance expectation (regular season, as in 15_accuracy_report.R)
  reg <- kp |> filter(season_type == "REG", !is.na(kick_distance))
  fit <- glm(made ~ poly(kick_distance, 3), binomial, reg)
  kp$p_exp <- NA_real_; kp$p_exp[kp$season_type == "REG" & !is.na(kp$kick_distance)] <- fitted(fit)
  kg <- kp |> group_by(season, week, game_id, posteam, kicker_player_id, r) |> summarise(att = n(), mk = sum(made, na.rm = TRUE), .groups = "drop") |>
    pivot_wider(names_from = r, values_from = c(att, mk), values_fill = 0) |> mutate(ord = season * 100 + week)
  cum <- kp |> filter(season_type == "REG", !is.na(p_exp)) |> group_by(season, week, game_id, posteam, kicker_player_id) |>
    summarise(c_att = n(), c_mk = sum(made), c_exp = sum(p_exp), .groups = "drop")
  kg <- kg |> left_join(cum, by = c("season", "week", "game_id", "posteam", "kicker_player_id")) |>
    mutate(across(c(c_att, c_mk, c_exp), ~ replace_na(.x, 0))) |> arrange(kicker_player_id, ord)
  lg <- kg |> group_by(kicker_player_id) |>
    mutate(across(all_of(base_cols), ~ .running_after(.x, 32), .names = "h32_{.col}"),
           across(c(c_att, c_mk, c_exp), ~ .running_after(.x, Inf))) |> ungroup()
  ix <- which(d$season == S)
  st <- .state_before(lg, d$kicker_player_id[ix], d$ord[ix], new_cols)
  for (c in new_cols) d[[c]][ix] <- st[, c]
  rm(pbp); gc()
  message("Season ", S, " done")
}
d$edge <- ifelse(d$c_att > 0, 100 * (d$c_mk - d$c_exp) / d$c_att, NA_real_)
d$good <- d$c_att >= 20 & !is.na(d$edge) & d$edge >= 5
message(sprintf("Truly good: %.1f%% of kicker-games (%.1f%% of pre-game top 16); about %.1f kickers per week",
                100 * mean(d$good), 100 * mean(d$good[d$top16pre]), mean(tapply(d$good, paste(d$season, d$week), sum))))

make_p <- function(w_good) setNames(lapply(PTS, function(r) {
  m <- d[[paste0("h32_mk_", r)]]; n <- d[[paste0("h32_att_", r)]]; L <- d[[paste0("lg_", r)]]
  w <- ifelse(d$good, w_good, 5)
  p <- ifelse(n + w > 0, (m + w * L) / (n + w), L)
  pmin(pmax(p, 0.01), 0.999)
}), PTS)
proj <- function(p) with(d, lambda_xp * p_xp + lambda_039 * (p[["039"]] * 4 - 1) + lambda_4049 * (p[["4049"]] * 5 - 1) + lambda_50 * (p[["50"]] * 6 - 1))
wk <- paste(d$season, d$week); WEEKS <- sort(unique(wk)); ws <- as.integer(substr(WEEKS, 1, 4))
pw <- function(pr, ix, need_good = FALSE) sapply(split(ix, factor(wk[ix], levels = WEEKS)), function(j) {
  if (length(j) < 2) return(c(0, 0))
  dp <- outer(pr[j], pr[j], "-"); da <- outer(d$actual_points[j], d$actual_points[j], "-"); u <- upper.tri(dp) & da != 0
  if (need_good) u <- u & outer(d$good[j], d$good[j], "|")
  c(sum((sign(dp[u]) == sign(da[u])) + 0.5 * (dp[u] == 0)), sum(u)) })
brier <- function(p) 1000 * sum(sapply(PTS, function(r) sum(d[[paste0("g_mk_", r)]] * (1 - p[[r]])^2 + (d[[paste0("g_att_", r)]] - d[[paste0("g_mk_", r)]]) * p[[r]]^2))) /
  sum(d$g_att_039 + d$g_att_4049 + d$g_att_50)
t16 <- which(d$top16pre); allx <- seq_len(nrow(d))
W <- c(0, 1, 2, 3, 5)
res <- lapply(W, function(w) { p <- make_p(w); pr <- proj(p)
  list(w = w, a16 = pw(pr, t16), aall = pw(pr, allx), agood = pw(pr, t16, TRUE), brier = brier(p)) }); names(res) <- W
grid <- bind_rows(lapply(res, function(r) tibble(w_good = r$w, hit16 = sum(r$a16[1, ]) / sum(r$a16[2, ]), hit_all = sum(r$aall[1, ]) / sum(r$aall[2, ]),
  hit16_good_pairs = sum(r$agood[1, ]) / sum(r$agood[2, ]), good_pairs = sum(r$agood[2, ]), brier_x1000 = r$brier)))
print(as.data.frame(grid |> mutate(across(where(is.double), ~ round(.x, 4)))))

# Leave-one-season-out pick among 0-3, compared with the current setting (5)
hit_s <- function(w, s) { a <- res[[as.character(w)]]$a16; ix <- ws %in% s; sum(a[1, ix]) / sum(a[2, ix]) }
picks <- sapply(SEASONS, function(h) { c(0, 1, 2, 3)[which.max(sapply(c(0, 1, 2, 3), hit_s, s = setdiff(SEASONS, h)))] })
held <- function(key) { out <- res[["5"]][[key]] * 0; for (j in seq_along(SEASONS)) { ix <- ws == SEASONS[j]; out[, ix] <- res[[as.character(picks[j])]][[key]][, ix] }; out }
n16 <- held("a16"); nall <- held("aall"); ngood <- held("agood"); b16 <- res[["5"]]$a16; ball <- res[["5"]]$aall; bgood <- res[["5"]]$agood
d16 <- n16[1, ] - b16[1, ]; dall <- nall[1, ] - ball[1, ]
bt <- replicate(2000, { i <- sample(length(WEEKS), replace = TRUE); c(sum(d16[i]) / sum(b16[2, i]), sum(dall[i]) / sum(ball[2, i])) })
seas <- tapply(d16, ws, sum) / tapply(b16[2, ], ws, sum)
test <- tibble(test = "Truly good: lighter weight (LOSO) vs current (fade 32, weight 5)",
               hit16_new = sum(n16[1, ]) / sum(n16[2, ]), hit16_base = sum(b16[1, ]) / sum(b16[2, ]), diff16 = sum(d16) / sum(b16[2, ]),
               boot16_lo = quantile(bt[1, ], .05), boot16_hi = quantile(bt[1, ], .95), share_not_better = mean(bt[1, ] <= 0),
               seasons_better = sum(seas > 0), diff_all = sum(dall) / sum(ball[2, ]), share_all_worse = mean(bt[2, ] < 0),
               good_pairs_new = sum(ngood[1, ]) / sum(ngood[2, ]), good_pairs_base = sum(bgood[1, ]) / sum(bgood[2, ]),
               pass = share_not_better <= 0.05 & seasons_better >= 7 & share_all_worse < 0.95)
print(as.data.frame(test |> mutate(across(where(is.double), ~ round(.x, 4)))))
print(data.frame(season = SEASONS, w_good_picked = picks, diff16 = round(seas, 4)))
write_csv(grid |> mutate(across(where(is.double), ~ round(.x, 5))), "data/truly_good_grid.csv")
write_csv(test |> mutate(across(where(is.double), ~ round(.x, 5))), "data/truly_good_test.csv")
