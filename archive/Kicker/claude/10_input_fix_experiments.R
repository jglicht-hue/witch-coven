# Tests two changes to script 05's kicker-accuracy inputs, against rules set
# with the user on 2026-09-28 BEFORE any results were seen. Not part of the
# weekly run.
#
# 1. XP RATE. Today 05's XP make rate is unshrunk: decayed XP makes / decayed
#    XP attempts (12-game half-life). One early miss drags a rookie's rate down
#    hard (T.Smack: 76% after 1 miss in 4). Candidates: the unshrunk rate
#    (league rate when no history) vs a shrunk rate
#      (decayed makes + w * league rate) / (decayed attempts + w)
#    for w = 2, 5, 10, 20, 50, 100 attempts.
#    Score: Brier score per XP attempt = mean of (predicted make chance -
#    outcome)^2, outcome 1 = made, 0 = missed. Lower is better. Every
#    kicker-game with XP attempts, using only XPs before that game.
#    RULE: adopt shrinkage if the w with the best Brier score on 2023-2024 also
#    beats the unshrunk rate on 2025, AND beats it in at least 2 of 3 seasons.
#
# 2. SLUMP ADJUSTMENT SIZE. The slump test (when a slump is flagged) is kept.
#    Candidates for the size of the cut in a flagged game:
#      a. current: every range's make chance x (pooled actual / expected makes)
#      b. none: no cut
#      c. logodds: one shift d in log-odds, applied to every range, chosen so
#         the pooled games' expected makes (each at its own range's rate, as of
#         its own game) equal the actual makes
#      d. logodds_half: half of that shift
#    Score: Brier score per FG attempt in the slump-flagged games.
#    RULE: among b-d, the ones that beat (a) in at least 2 of 3 seasons are
#    eligible; adopt the eligible one with the best Brier score over all three
#    seasons. If none is eligible, keep (a).
#
# Reads data/kicker_accuracy.csv, data/team_game_fg_xp_counts.csv (01) and
# data/kicker_game_accuracy.csv (05). Writes data/input_fix_xp.csv,
# data/input_fix_slump.csv and data/input_fix_slump_examples.csv.

suppressMessages({library(dplyr); library(tidyr); library(readr)})

HALF_LIFE <- 12
XP_W <- c(2, 5, 10, 20, 50, 100)
RANGES <- c("0-39" = "0_39", "40-49" = "40_49", "50+" = "50plus")

ka <- read_csv("data/kicker_accuracy.csv", show_col_types = FALSE)
tc <- read_csv("data/team_game_fg_xp_counts.csv", show_col_types = FALSE)
k05 <- read_csv("data/kicker_game_accuracy.csv", show_col_types = FALSE)

exp_decay_trailing <- function(x, hl) {  # same as 05: decayed sum of earlier games only
  d <- 0.5^(1 / hl); out <- numeric(length(x)); run <- 0
  for (i in seq_along(x)) { out[i] <- run; run <- d * (run + x[i]) }
  out
}
brier <- function(p, makes, att) makes * (1 - p)^2 + (att - makes) * p^2   # summed over the game's attempts

# ---------------------------------------------------------------- 1. XP rate
wide <- ka |> mutate(r = RANGES[distance_range]) |>
  select(season, week, game_id, posteam, kicker_player_id, r, attempts, makes) |>
  pivot_wider(names_from = r, values_from = c(attempts, makes), values_fill = 0) |>
  mutate(tot = attempts_0_39 + attempts_40_49 + attempts_50plus)
# 05's attribution: team XPs go to the game's primary FG kicker
primary <- wide |> arrange(kicker_player_id, season, week) |> group_by(season, week, game_id, posteam) |>
  slice_max(tot, n = 1, with_ties = FALSE) |> ungroup() |> select(season, week, game_id, posteam, kicker_player_id)
lg_xp <- sum(tc$xp_makes) / sum(tc$xp_attempts)
xp <- primary |> left_join(tc |> select(game_id, posteam, xp_attempts, xp_makes), by = c("game_id", "posteam")) |>
  arrange(kicker_player_id, season, week) |> group_by(kicker_player_id) |>
  mutate(d_m = exp_decay_trailing(xp_makes, HALF_LIFE), d_a = exp_decay_trailing(xp_attempts, HALF_LIFE)) |>
  ungroup() |> filter(xp_attempts > 0)
check <- xp |> inner_join(k05 |> select(game_id, kicker_player_id, xp_accuracy_rate), by = c("game_id", "kicker_player_id")) |>
  filter(!is.na(xp_accuracy_rate))
stopifnot(max(abs(check$d_m / check$d_a - check$xp_accuracy_rate)) < 1e-9)  # rebuilt rate = 05's rate

xp_cands <- c(list(unshrunk = ifelse(xp$d_a > 0, xp$d_m / xp$d_a, lg_xp)),
              setNames(lapply(XP_W, function(w) (xp$d_m + w * lg_xp) / (xp$d_a + w)), paste0("w", XP_W)))
xp_long <- bind_rows(lapply(names(xp_cands), function(n) {
  b <- brier(xp_cands[[n]], xp$xp_makes, xp$xp_attempts)
  tibble(candidate = n, season = as.character(xp$season), b = b, att = xp$xp_attempts)
}))
xp_res <- bind_rows(xp_long,
                    xp_long |> filter(season %in% c("2023", "2024")) |> mutate(season = "2023-2024"),
                    xp_long |> mutate(season = "all")) |>
  group_by(candidate, season) |> summarise(xp_attempts = sum(att), brier_x1000 = 1000 * sum(b) / sum(att), .groups = "drop")
xp_wide <- xp_res |> select(-xp_attempts) |> pivot_wider(names_from = season, values_from = brier_x1000)
best_w <- xp_wide |> filter(candidate != "unshrunk") |> slice_min(`2023-2024`, n = 1) |> pull(candidate)
un <- xp_wide |> filter(candidate == "unshrunk")
bw <- xp_wide |> filter(candidate == best_w)
xp_seasons_better <- sum(c(bw$`2023`, bw$`2024`, bw$`2025`) < c(un$`2023`, un$`2024`, un$`2025`))
xp_pass <- bw$`2025` < un$`2025` && xp_seasons_better >= 2
write_csv(xp_wide |> mutate(across(where(is.double), ~ round(.x, 3))), "data/input_fix_xp.csv")
message("XP: best w on 2023-2024 = ", best_w, "; beats unshrunk on 2025: ", bw$`2025` < un$`2025`,
        "; seasons better: ", xp_seasons_better, " of 3 -> ", if (xp_pass) "ADOPT" else "KEEP UNSHRUNK")
print(as.data.frame(xp_wide |> mutate(across(where(is.double), ~ round(.x, 2)))))
cat("XP attempts scored by season:\n"); print(xp_res |> filter(candidate == "unshrunk") |> select(season, xp_attempts))

# ---------------------------------------------------------- 2. Slump size
g <- k05 |> left_join(wide |> select(-tot), by = c("season", "week", "game_id", "posteam", "kicker_player_id")) |>
  arrange(kicker_player_id, season, week) |> group_by(kicker_player_id) |> mutate(row = row_number()) |> ungroup()
logit <- function(p) log(p / (1 - p)); expit <- function(x) 1 / (1 + exp(-x))
flag <- which(g$slump_flagged == 1)
sl <- bind_rows(lapply(flag, function(i) {
  k <- g$kicker_player_id[i]
  prior <- g[g$kicker_player_id == k & g$season == g$season[i] & g$row < g$row[i], ]
  pool <- tail(prior, g$slump_pool_games[i])
  att <- as.matrix(pool[, paste0("attempts_", RANGES)]); mk <- sum(pool[, paste0("makes_", RANGES)])
  lr <- as.matrix(pool[, paste0("long_run_rate_", RANGES)])
  f <- function(d) sum(att * expit(logit(lr) + d)) - mk
  d <- if (mk == 0) -8 else uniroot(f, c(-8, 0))$root
  stopifnot(abs(g$slump_deficit_ratio[i] - mk / sum(att * lr)) < 1e-9)  # rebuilt ratio = 05's
  lr_i <- unlist(g[i, paste0("long_run_rate_", RANGES)])
  cands <- list(current = lr_i * g$slump_deficit_ratio[i], none = lr_i,
                logodds = expit(logit(lr_i) + d), logodds_half = expit(logit(lr_i) + d / 2))
  a_i <- unlist(g[i, paste0("attempts_", RANGES)]); m_i <- unlist(g[i, paste0("makes_", RANGES)])
  bind_rows(lapply(names(cands), function(n) tibble(
    season = g$season[i], game_id = g$game_id[i], kicker = g$kicker_player_name[i], candidate = n, shift = d,
    p_039 = cands[[n]][1], p_4049 = cands[[n]][2], p_50 = cands[[n]][3],
    b = sum(brier(cands[[n]], m_i, a_i)), att = sum(a_i))))
}))
sl_res <- bind_rows(sl |> mutate(season = as.character(season)), sl |> mutate(season = "all")) |>
  group_by(candidate, season) |> summarise(games = n(), fg_attempts = sum(att), brier_x1000 = 1000 * sum(b) / sum(att), .groups = "drop")
sl_wide <- sl_res |> select(candidate, season, brier_x1000) |> pivot_wider(names_from = season, values_from = brier_x1000)
cur <- sl_wide |> filter(candidate == "current")
elig <- sl_wide |> filter(candidate != "current") |> rowwise() |>
  mutate(seasons_better = sum(c(`2023`, `2024`, `2025`) < c(cur$`2023`, cur$`2024`, cur$`2025`))) |> ungroup()
pick <- elig |> filter(seasons_better >= 2) |> slice_min(all, n = 1)
write_csv(left_join(sl_wide, elig |> select(candidate, seasons_better), by = "candidate") |>
            mutate(across(where(is.double), ~ round(.x, 3))), "data/input_fix_slump.csv")
write_csv(sl |> mutate(across(where(is.double), ~ round(.x, 4))), "data/input_fix_slump_examples.csv")
# All FG attempts, for scale (unflagged games are identical under every candidate)
all_b_cur <- sum(brier(g$final_rate_0_39, g$makes_0_39, g$attempts_0_39) + brier(g$final_rate_40_49, g$makes_40_49, g$attempts_40_49) +
                   brier(g$final_rate_50plus, g$makes_50plus, g$attempts_50plus))
all_att <- sum(g$attempts_0_39 + g$attempts_40_49 + g$attempts_50plus)
message("Slump: flagged games ", length(flag), " (", sum(sl$att[sl$candidate == "current"]), " FG attempts of ", all_att, " total)")
print(as.data.frame(left_join(sl_wide, elig |> select(candidate, seasons_better), by = "candidate") |>
                      mutate(across(where(is.double), ~ round(.x, 1)))))
message("Slump pick: ", if (nrow(pick)) pick$candidate else "none eligible - keep current")
for (n in unique(sl$candidate)) {
  tot <- all_b_cur - sum(sl$b[sl$candidate == "current"]) + sum(sl$b[sl$candidate == n])
  message(sprintf("  all FG attempts, Brier x1000 with %-12s %.2f", n, 1000 * tot / all_att))
}

# Information only (not part of the rule, added after seeing w = 100 at the edge
# of the grid): the pure league rate, i.e. w = infinity.
lg_b <- brier(rep(lg_xp, nrow(xp)), xp$xp_makes, xp$xp_attempts)
message("Info: pure league XP rate, Brier x1000 by season: ",
        paste(sprintf("%s %.2f", sort(unique(xp$season)), tapply(lg_b, xp$season, sum) / tapply(xp$xp_attempts, xp$season, sum) * 1000), collapse = ", "),
        sprintf(", all %.2f", 1000 * sum(lg_b) / sum(xp$xp_attempts)))
