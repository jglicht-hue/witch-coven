# #21 Opponent red-zone window test (2026-10-01). Rules set before results (see log).
# Run from the pipeline folder after run_all.R (needs data/volume_model_table.csv and 00_nflverse_data.R).
# Downloads 2022 play-by-play in addition to 2023-2025. Takes about 20 seconds. Log: claude/21_rz_window_log.md
suppressMessages({library(dplyr); library(tidyr); library(readr)})
source("00_nflverse_data.R")
set.seed(20261001)
pbp <- load_pbp_data(2022:2025)
sched <- load_schedule_data(2022:2025) |> filter(game_type == "REG")

# --- Defense game log: red-zone trips and TDs allowed per regular-season game ----------
drives <- pbp |> filter(!is.na(posteam), !is.na(defteam), !is.na(fixed_drive), game_id %in% sched$game_id) |>
  group_by(game_id, posteam, defteam, fixed_drive) |>
  summarise(rz = any(drive_inside20 == 1, na.rm = TRUE), td = dplyr::first(fixed_drive_result) == "Touchdown", .groups = "drop") |>
  filter(rz) |> group_by(game_id, defteam) |> summarise(trips = n(), tds = sum(td), .groups = "drop")
dlog <- bind_rows(sched |> transmute(season, week, game_id, gameday, team = home_team),
                  sched |> transmute(season, week, game_id, gameday, team = away_team)) |>
  left_join(drives, by = c("game_id", "team" = "defteam")) |>
  mutate(across(c(trips, tds), ~ replace_na(.x, 0))) |> arrange(team, gameday)
L <- sum(dlog$tds) / sum(dlog$trips)

# --- Coaching changes -------------------------------------------------------------------
# Head coach: from the schedule (week-1 coach differs from the previous season's last coach).
hc <- bind_rows(sched |> transmute(season, week, team = home_team, coach = home_coach),
                sched |> transmute(season, week, team = away_team, coach = away_coach))
hc_first <- hc |> group_by(team, season) |> slice_min(week, n = 1, with_ties = FALSE) |> ungroup() |> select(team, season, first = coach)
hc_last  <- hc |> group_by(team, season) |> slice_max(week, n = 1, with_ties = FALSE) |> ungroup() |> transmute(team, season = season + 1, prev_last = coach)
new_hc <- hc_first |> inner_join(hc_last, by = c("team", "season")) |> mutate(new_hc = first != prev_last) |> select(team, season, new_hc)
# Defensive coordinator: hand-built (web search 2026-10-01; FanDuel 2024 tracker, PFN 2025 rankings, checked
# against known hires). Play-caller changes; TB counted as unchanged (Bowles calls the defense).
NEW_DC <- list(`2024` = c("ATL","BAL","BUF","CHI","DAL","GB","JAX","LAC","LA","MIA","NE","NYG","PHI","SF","SEA","TEN","WAS"),
               `2025` = c("ATL","CHI","CIN","DAL","DET","IND","JAX","NE","NO","NYJ","SF"))
new_dc <- bind_rows(lapply(names(NEW_DC), function(s) tibble(team = NEW_DC[[s]], season = as.integer(s), new_dc = TRUE)))
changes <- new_hc |> full_join(new_dc, by = c("team", "season")) |>
  mutate(new_hc = replace_na(new_hc, FALSE), new_dc = replace_na(new_dc, FALSE), changed = new_hc | new_dc)

# --- Variants for each defense-game, using that defense's earlier games only ------------
variants <- dlog |> group_by(team) |> group_modify(function(d, key) {
  n <- nrow(d); out <- matrix(NA_real_, n, 8, dimnames = list(NULL, c("A","B4","B8","B16","C50","C25","D8","season_games")))
  for (i in seq_len(n)) {
    prev <- if (i > 1) d[max(1, i - 8):(i - 1), ] else d[0, ]
    same <- prev$season == d$season[i]
    s_all <- d[seq_len(i - 1), ]; s_all <- s_all[s_all$season == d$season[i], ]
    A <- if (sum(prev$trips) > 0) sum(prev$tds) / sum(prev$trips) else NA
    B <- function(k) (sum(s_all$tds) + k * L) / (sum(s_all$trips) + k)
    C <- function(f) { w <- ifelse(same, 1, f); if (sum(w * prev$trips) > 0) sum(w * prev$tds) / sum(w * prev$trips) else NA }
    out[i, ] <- c(A, B(4), B(8), B(16), C(0.5), C(0.25), (sum(prev$tds) + 8 * L) / (sum(prev$trips) + 8), nrow(s_all))
  }
  bind_cols(d |> select(game_id), as_tibble(out))
}) |> ungroup() |> rename(defteam = team)

vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE)
opp <- bind_rows(sched |> transmute(game_id, posteam = home_team, defteam = away_team),
                 sched |> transmute(game_id, posteam = away_team, defteam = home_team))
vol <- vol |> left_join(opp, by = c("game_id", "posteam")) |>
  left_join(variants, by = c("game_id", "defteam")) |>
  left_join(changes |> rename(defteam = team), by = c("defteam", "season")) |>
  mutate(changed = replace_na(changed, FALSE), F8 = ifelse(changed, B8, A))
# Reproduction check: A must equal production for rows whose window doesn't reach 2022
chk <- vol |> filter(!(season == 2023 & week <= 9))
message("A vs production opp rate (2023 wk10+ and 2024-25): max |diff| = ",
        signif(max(abs(chk$A - chk$opp_redzone_td_rate_allowed_trail8)), 3), " over ", nrow(chk), " rows")

# --- Held-out comparison -----------------------------------------------------------------
REST039 <- "implied_team_total + I(implied_team_total^2) + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"
RESTXP <- "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + coach_long_fg_rate"
VARS <- c("A", "B4", "B8", "B16", "C50", "C25", "D8", "F8")
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
train_all <- vol |> filter(top16pre)
heldout <- function(v) bind_rows(lapply(2023:2025, function(s) {
  d <- vol |> mutate(oppv = .data[[v]]); tr <- d |> filter(top16pre, season != s); te <- d |> filter(season == s)
  f1 <- glm(as.formula(paste("att_039 ~ oppv +", REST039)), poisson, tr)
  f2 <- glm(as.formula(paste("xp_attempts ~ oppv +", RESTXP)), poisson, tr)
  te |> transmute(season, week, game_id, posteam, top16pre,
                  dev = dev_i(att_039, predict(f1, te, type = "response")) + dev_i(xp_attempts, predict(f2, te, type = "response")),
                  dev039 = dev_i(att_039, predict(f1, te, type = "response")),
                  devxp = dev_i(xp_attempts, predict(f2, te, type = "response")))
}))
res <- lapply(setNames(VARS, VARS), heldout)
base <- res$A
early <- function(d) d$season %in% 2024:2025 & d$week <= 6
boot_p <- function(g, games) {
  ug <- unique(games); idx <- split(seq_along(g), games)
  bs <- replicate(2000, { pick <- sample(ug, replace = TRUE); mean(g[unlist(idx[pick], use.names = FALSE)]) })
  c(p = mean(bs <= 0), lo = unname(quantile(bs, 0.025)), hi = unname(quantile(bs, 0.975)))
}
tab <- bind_rows(lapply(VARS[-1], function(v) {
  r <- res[[v]]; g <- 1000 * (base$dev - r$dev)
  e <- early(r) & r$top16pre
  b <- boot_p(g[e], r$game_id[e])
  ea <- early(r)
  tibble(variant = v,
         n_early_top16 = sum(e),
         gain_early_top16 = mean(g[e]),
         gain_2024 = mean(g[e & r$season == 2024]), gain_2025 = mean(g[e & r$season == 2025]),
         gain039_early = 1000 * mean((base$dev039 - r$dev039)[e]), gainxp_early = 1000 * mean((base$devxp - r$devxp)[e]),
         boot_p = b[["p"]], boot_lo = b[["lo"]], boot_hi = b[["hi"]],
         gain_early_allteams = mean(g[ea]), n_early_all = sum(ea),
         gain_allweeks_top16 = mean(g[r$top16pre]),
         rule1 = gain_2024 > 0 & gain_2025 > 0, rule2 = boot_p < 0.05 / 7, rule3 = gain_allweeks_top16 >= 0,
         passes = rule1 & rule2 & rule3)
}))
message("\nGain vs current (error x1000 per team-game, 0-39 + XP deviance; positive = better than current)")
print(as.data.frame(tab |> mutate(across(where(is.double), ~ round(.x, 3)))), width = 250)
write_csv(tab, "t21_results.csv")

# --- How different are the variants where it matters? -----------------------------------
e <- vol |> filter(season %in% 2024:2025, week <= 6, top16pre)
message("\nWeeks 1-6 2024-25 top16: SD of (variant - A): ",
        paste(sapply(VARS[-1], function(v) paste0(v, "=", round(sd(e[[v]] - e$A), 3))), collapse = ", "))
message("Coefficient on opp rate in current 0-39 / XP models (all train): ",
        round(coef(glm(as.formula(paste("att_039 ~ A +", REST039)), poisson, train_all))[["A"]], 3), " / ",
        round(coef(glm(as.formula(paste("xp_attempts ~ A +", RESTXP)), poisson, train_all))[["A"]], 3))

# --- Coaching diagnostic: does last season predict weeks 1-6 worse after a change? ---------
seas_rate <- dlog |> group_by(team, season) |> summarise(full = sum(tds) / sum(trips),
  early = sum(tds[week <= 6]) / sum(trips[week <= 6]), early_trips = sum(trips[week <= 6]), .groups = "drop")
diag <- seas_rate |> filter(season %in% 2024:2025) |>
  left_join(seas_rate |> transmute(team, season = season + 1, prev_full = full), by = c("team", "season")) |>
  left_join(changes, by = c("team", "season")) |> mutate(changed = replace_na(changed, FALSE))
dsum <- diag |> group_by(changed) |> summarise(defense_seasons = n(), cor_prev_vs_early = cor(prev_full, early),
  mean_abs_shift = mean(abs(early - prev_full)), mean_early_trips = mean(early_trips), .groups = "drop")
print(as.data.frame(dsum |> mutate(across(where(is.double), ~ round(.x, 3)))))
message("Split-half reliability of a defense's own rate within a season (weeks 1-6 vs 7-18, 2023-25): r = ",
        round({ x <- dlog |> filter(season %in% 2023:2025) |> group_by(team, season) |>
          summarise(a = sum(tds[week <= 6]) / sum(trips[week <= 6]), b = sum(tds[week > 6]) / sum(trips[week > 6]), .groups = "drop"); cor(x$a, x$b) }, 3))
write_csv(diag, "t21_coaching_diag.csv")
message("New HC by season: ", paste(capture.output(print(changes |> filter(new_hc) |> group_by(season) |> summarise(teams = paste(team, collapse = " ")))), collapse = " | "))
