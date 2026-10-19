# #25 Grid of pinned accuracy weights in the long-range attempt models (2026-10-05).
# One-off test run in the Kicker Wizerd chat. No production script or model was changed. Rules were set before results (see claude/25_pin_weight_grid_log.md).
# Three parts, run in order from the pipeline folder after run_all.R:
#   PART 1 builds the 2011-2025 long table (same as #23's build step, plus 40-49 accuracy `r4049`) -> t25_tg.rds
#   PART 2 estimates the outdoor accuracy weights on seasons the backtest doesn't score
#   PART 3 runs the grid on the production backtest (needs 08a_inputs.R = the input-building half of 08a, and 08_points_distribution.R)

# ======================= PART 1: long table =======================
suppressMessages({library(dplyr); library(tidyr); library(readr)})
YEARS <- 2011:2025
fix <- function(x) recode(x, OAK = "LV", SD = "LAC", STL = "LA", .default = x)
kicks <- list(); fourth <- list()
for (y in YEARS) {
  p <- readRDS(sprintf("data/raw/play_by_play_%d.rds", y))
  kicks[[as.character(y)]] <- p |> filter(field_goal_attempt == 1 | extra_point_attempt == 1, !is.na(posteam)) |>
    transmute(season, week, game_id, season_type, posteam = fix(posteam), kicker_player_id, kicker_player_name,
              fg = field_goal_attempt == 1, dist = kick_distance, made = field_goal_result == "made",
              xp_good = extra_point_attempt == 1 & extra_point_result == "good")
  fourth[[as.character(y)]] <- p |> filter(season_type == "REG", down == 4, yardline_100 >= 22, yardline_100 <= 41,
                                           play_type %in% c("field_goal", "punt", "pass", "run")) |>
    transmute(season, week, game_id, posteam = fix(posteam), yardline_100, ydstogo, score_differential,
              half_seconds_remaining, qtr, kicked = as.integer(field_goal_attempt == 1))
  rm(p); gc(verbose = FALSE)
}
kicks <- bind_rows(kicks); fourth <- bind_rows(fourth)
sched <- readRDS("data/raw/games.rds") |> filter(season %in% YEARS) |>
  mutate(home_team = fix(home_team), away_team = fix(away_team))
fgk <- kicks |> filter(fg, !is.na(kicker_player_id), !is.na(dist)) |> mutate(ord = season * 100 + week, long = dist >= 40)

# League 40+ make rate over the 3 seasons before each season
lg <- fgk |> filter(long) |> group_by(season) |> summarise(a = n(), m = sum(made), .groups = "drop")
L <- sapply(YEARS, function(s) { x <- lg[lg$season %in% (s - 3):(s - 1), ]; if (nrow(x)) sum(x$m) / sum(x$a) else NA })
names(L) <- YEARS; L["2011"] <- lg$m[lg$season == 2011] / lg$a[lg$season == 2011]

# Kicker-game log and decayed 40+ makes / attempts
kg <- fgk |> group_by(kicker_player_id, season, week, ord, game_id, posteam) |>
  summarise(tot = n(), a40 = sum(long), m40 = sum(long & made), a4049 = sum(dist >= 40 & dist <= 49), m4049 = sum(dist >= 40 & dist <= 49 & made), .groups = "drop") |> arrange(kicker_player_id, ord)
run_after <- function(x, hl) { d <- 0.5^(1 / hl); r <- 0; out <- numeric(length(x)); for (i in seq_along(x)) { r <- d * (r + x[i]); out[i] <- r }; out }
kg <- kg |> group_by(kicker_player_id) |> mutate(da12 = run_after(a40, 12), dm12 = run_after(m40, 12),
  da32 = run_after(a40, 32), dm32 = run_after(m40, 32), career_a40 = cumsum(a40), da4049 = run_after(a4049, 12), dm4049 = run_after(m4049, 12)) |> ungroup()

# Team-games (regular season), outcomes, kicker assignment
reg <- sched |> filter(game_type == "REG", !is.na(result))
tg <- bind_rows(reg |> transmute(season, week, game_id, posteam = home_team, roof),
                reg |> transmute(season, week, game_id, posteam = away_team, roof)) |>
  mutate(ord = season * 100 + week, dome = as.integer(roof %in% c("dome", "closed")))
cnt <- kicks |> group_by(game_id, posteam) |>
  summarise(att_4049 = sum(fg & dist >= 40 & dist <= 49, na.rm = TRUE), att_50 = sum(fg & dist >= 50, na.rm = TRUE),
            att_039 = sum(fg & dist <= 39, na.rm = TRUE),
            fpts = sum(ifelse(fg, ifelse(made, ifelse(dist >= 50, 5, ifelse(dist >= 40, 4, 3)), -1), as.integer(xp_good)), na.rm = TRUE),
            .groups = "drop")
tg <- tg |> left_join(cnt, by = c("game_id", "posteam")) |>
  mutate(across(c(att_4049, att_50, att_039, fpts), ~ replace_na(.x, 0)), att_40p = att_4049 + att_50)
primary <- kg |> group_by(game_id, posteam) |> slice_max(tot, n = 1, with_ties = FALSE) |> ungroup() |>
  select(game_id, posteam, ord, kicker_player_id)
tg <- tg |> left_join(primary |> select(-ord), by = c("game_id", "posteam"))
pr_by_team <- split(primary, primary$posteam)
for (i in which(is.na(tg$kicker_player_id))) {
  p <- pr_by_team[[tg$posteam[i]]]; p <- p[p$ord < tg$ord[i], ]
  if (nrow(p)) tg$kicker_player_id[i] <- p$kicker_player_id[which.max(p$ord)]
}
tg <- tg |> filter(!is.na(kicker_player_id))
state_before <- function(log, cols) {
  out <- matrix(0, nrow(tg), length(cols), dimnames = list(NULL, cols))
  for (k in unique(tg$kicker_player_id)) {
    vi <- which(tg$kicker_player_id == k); li <- which(log$kicker_player_id == k); if (!length(li)) next
    pos <- findInterval(tg$ord[vi] - 0.5, log$ord[li]); ok <- pos > 0
    out[vi[ok], ] <- as.matrix(log[li[pos[ok]], cols]) }
  out }
s <- state_before(kg, c("da12", "dm12", "da32", "dm32", "career_a40", "da4049", "dm4049"))
lg49 <- fgk |> filter(dist >= 40, dist <= 49) |> group_by(season) |> summarise(a = n(), m = sum(made), .groups = "drop")
L49 <- sapply(YEARS, function(s) { x <- lg49[lg49$season %in% (s - 3):(s - 1), ]; if (nrow(x)) sum(x$m) / sum(x$a) else NA }); names(L49) <- YEARS
L49["2011"] <- lg49$m[lg49$season == 2011] / lg49$a[lg49$season == 2011]
Ls <- L[as.character(tg$season)]
tg$acc12 <- (s[, "dm12"] + 5 * Ls) / (s[, "da12"] + 5) - Ls
tg$acc32 <- (s[, "dm32"] + 5 * Ls) / (s[, "da32"] + 5) - Ls
tg$prior_a40 <- s[, "career_a40"]; tg$lg40 <- Ls
tg$r4049 <- (s[, "dm4049"] + 5 * L49[as.character(tg$season)]) / (s[, "da4049"] + 5)
# Pre-game top 16 (06b's rule) on the long table
pts <- tg |> select(kicker_player_id, ord, fpts) |> arrange(kicker_player_id, ord) |> group_by(kicker_player_id) |>
  mutate(d_pts = run_after(fpts, 12), d_g = run_after(rep(1, n()), 12)) |> ungroup()
sp <- state_before(pts, c("d_pts", "d_g")); lgp <- mean(tg$fpts)
tg$ppg_pre <- ifelse(sp[, 2] > 0, (sp[, 1] + 4 * lgp) / (sp[, 2] + 4), NA)
tg <- tg |> group_by(season, week) |> mutate(top16pre = !is.na(ppg_pre) & rank(-ppg_pre, ties.method = "first", na.last = "keep") <= 16) |>
  ungroup() |> mutate(top16pre = replace_na(top16pre, FALSE))
fourth <- fourth |> inner_join(tg |> select(game_id, posteam, dome, acc12, acc32, top16pre, kicker_player_id), by = c("game_id", "posteam"))
saveRDS(tg, "t25_tg.rds"); saveRDS(fourth, "t25_fourth.rds")
cat("team-games 2011-2025:", nrow(tg), "; 2016-2025:", sum(tg$season >= 2016), "; top16pre 2016-25:", sum(tg$season >= 2016 & tg$top16pre), "\n")
cat("4th downs in long FG range 2016-2025:", sum(fourth$season >= 2016), " kicked share", round(mean(fourth$kicked[fourth$season >= 2016]), 3), "\n")
print(round(L, 3))
print(tg |> filter(season >= 2016) |> group_by(season) |> summarise(att40 = mean(att_40p), dome = mean(dome), sd12 = sd(acc12), sd32 = sd(acc32)) |> as.data.frame() |> round(3))
# Check vs production table for 2023-25: att counts and kicker
v <- read_csv("data/volume_model_table.csv", show_col_types = FALSE) |> select(game_id, posteam, p4049 = att_4049, p50 = att_50, pk = kicker_player_id, pdome = is_enclosed, ptop = top16pre)
ck <- inner_join(tg, v, by = c("game_id", "posteam"))
cat("vs production (", nrow(ck), "rows): att mismatch", sum(ck$att_4049 != ck$p4049 | ck$att_50 != ck$p50), "; kicker mismatch", sum(ck$kicker_player_id != ck$pk),
    "; dome mismatch", sum(ck$dome != round(ck$pdome)), "; top16 agree", round(mean(ck$top16pre == ck$ptop), 3), "\n")

# ======================= PART 2: independent estimates =======================
suppressMessages({library(dplyr)})
lt <- readRDS("t25_tg.rds") |> mutate(r40 = acc12 + lg40)
est <- function(d, y, x) { f <- glm(as.formula(paste(y, "~ factor(season) + dome +", x, "+ dome:", x)), poisson, d)
  b <- summary(f)$coefficients[x, 1:2]; sprintf("%+.3f (se %.3f; 95%% %+.2f to %+.2f)", b[1], b[2], b[1] - 1.96 * b[2], b[1] + 1.96 * b[2]) }
for (w in list(2016:2022, 2016:2025)) { d <- lt[lt$season %in% w, ]
  cat(min(w), "-", max(w), "\n")
  cat("  50+ attempts on 40+ accuracy:     all", est(d, "att_50", "r40"), " top16", est(d[d$top16pre, ], "att_50", "r40"), "\n")
  cat("  40-49 attempts on 40-49 accuracy: all", est(d, "att_4049", "r4049"), " top16", est(d[d$top16pre, ], "att_4049", "r4049"), "\n") }

# ======================= PART 3: grid on the production backtest =======================
suppressMessages({library(dplyr); library(tidyr); library(readr)})
set.seed(20261005)
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
source("08a_inputs.R"); source("08_points_distribution.R")
F_XP <- "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8 + coach_long_fg_rate"
F_039 <- "implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"
F4049_CUR <- "is_enclosed + krate_4049 + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"
F4049_PIN <- "is_enclosed + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate + offset(off49)"
F4049_40P <- "is_enclosed + krate_40plus + kshare_4049_hlall + is_enclosed:krate_40plus + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"
F50_CUR <- "is_enclosed + krate_40plus + is_enclosed:krate_50"; F50_PIN <- "is_enclosed + is_enclosed:krate_50 + offset(off50)"
top <- vol |> filter(top16pre)
run <- function(f4049, f50, w49 = 0, w50 = 0) bind_rows(lapply(2023:2025, function(s) {
  d <- top |> mutate(off49 = w49 * krate_4049, off50 = w50 * krate_40plus); tr <- d[d$season != s, ]; te <- d[d$season == s, ]
  g <- function(o, rhs) predict(glm(as.formula(paste(o, "~", rhs)), poisson, tr), te, type = "response")
  te |> mutate(l_xp = g("xp_attempts", F_XP), l039 = g("att_039", F_039), l4049 = g("att_4049", f4049), l50 = g("att_50", f50),
               proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp)) }))
hit <- function(d) { n <- 0; h <- 0
  for (g in split(d, list(d$season, d$week), drop = TRUE)) { if (nrow(g) < 2) next
    dp <- outer(g$proj, g$proj, "-"); da <- outer(g$fpts, g$fpts, "-"); ok <- upper.tri(da) & da != 0
    n <- n + sum(ok); h <- h + sum(ifelse(dp[ok] == 0, 0.5, as.numeric(sign(dp[ok]) == sign(da[ok])))) }
  h / n }
base <- run(F4049_CUR, F50_CUR)
row <- function(label, r, ref = base, which = "50") { y <- if (which == "50") "att_50" else "att_4049"; l <- if (which == "50") "l50" else "l4049"
  g <- 1000 * (dev_i(ref[[y]], ref[[l]]) - dev_i(r[[y]], r[[l]])); out <- r$is_enclosed == 0
  tibble(version = label, gain = mean(g), s2023 = mean(g[r$season == 2023]), s2024 = mean(g[r$season == 2024]), s2025 = mean(g[r$season == 2025]),
         seasons_better = sum(tapply(g, r$season, mean) > 0), gain_outdoors = mean(g[out]), gain_dome = mean(g[!out]),
         mse = mean((r$fpts - r$proj)^2), hit_rate = hit(r), mean_move = mean(abs(r$proj - base$proj)), max_move = max(abs(r$proj - base$proj))) }
W50 <- c(0, 0.664, 1.0, 1.307, 1.555, 2.0, 2.5, 3.0, 4.0)
r50 <- lapply(W50, function(w) run(F4049_CUR, F50_PIN, w50 = w)); names(r50) <- W50
t50 <- bind_rows(row("current (estimated each fold)", base), bind_rows(lapply(names(r50), function(w) row(paste("pinned", w), r50[[w]]))))
message("A. 50+ model: pinned weight on kicker 40+ accuracy (gain vs current, error x1000)"); print(as.data.frame(t50 |> mutate(across(where(is.double), ~ round(.x, 4)))), width = 250)
ref131 <- r50[["1.307"]]
t50b <- bind_rows(lapply(names(r50), function(w) row(paste("pinned", w, "vs pinned 1.307"), r50[[w]], ref = ref131))) |> select(version, gain, s2023, s2024, s2025, seasons_better)
message("   Same, measured against the 1.307 pin"); print(as.data.frame(t50b |> mutate(across(where(is.double), ~ round(.x, 3)))))
W49 <- c(-1.325, -0.5, 0, 0.25, 0.5, 1.0, 2.0)
r49 <- lapply(W49, function(w) run(F4049_PIN, F50_CUR, w49 = w)); names(r49) <- W49
t49 <- bind_rows(row("current (estimated each fold)", base, which = "4049"), bind_rows(lapply(names(r49), function(w) row(paste("pinned", w), r49[[w]], which = "4049"))),
                 row("40+ accuracy in place of 40-49 accuracy (estimated)", run(F4049_40P, F50_CUR), which = "4049"))
message("\nB. 40-49 model: pinned outdoor weight on kicker 40-49 accuracy (gain vs current, error x1000)"); print(as.data.frame(t49 |> mutate(across(where(is.double), ~ round(.x, 4)))), width = 250)
# Combination candidates
comb <- bind_rows(row("50+ 1.307 + 40-49 at 0", run(F4049_PIN, F50_PIN, 0, 1.307)), row("50+ 1.307 + 40-49 at +0.25", run(F4049_PIN, F50_PIN, 0.25, 1.307)),
                  row("50+ 1.307 + 40-49 at +0.5", run(F4049_PIN, F50_PIN, 0.5, 1.307)), row("50+ 2.0 + 40-49 at 0", run(F4049_PIN, F50_PIN, 0, 2.0)))
message("\nC. Combinations (50+ gain shown; mse and hit rate are for the whole projection)"); print(as.data.frame(comb |> mutate(across(where(is.double), ~ round(.x, 4)))), width = 250)
fold_est <- sapply(2023:2025, function(s) coef(glm(as.formula(paste("att_50 ~", F50_CUR)), poisson, top[top$season != s, ]))[["krate_40plus"]])
fold49 <- sapply(2023:2025, function(s) coef(glm(as.formula(paste("att_4049 ~", F4049_CUR)), poisson, top[top$season != s, ]))[["krate_4049"]])
message("Fold estimates of the 50+ weight (leaving out 2023/2024/2025): ", paste(round(fold_est, 2), collapse = " / "), "; 40-49 outdoor weight: ", paste(round(fold49, 2), collapse = " / "))
write_csv(t50, "t25_grid50.csv"); write_csv(t49, "t25_grid4049.csv"); write_csv(comb, "t25_comb.csv")
# Week bootstrap: are the points differences between pinned values distinguishable?
wk <- paste(base$season, base$week); uw <- unique(wk); idx <- split(seq_along(wk), wk)
hit_parts <- function(d) { t(sapply(uw, function(w) { g <- d[idx[[w]], ]; if (nrow(g) < 2) return(c(0, 0))
  dp <- outer(g$proj, g$proj, "-"); da <- outer(g$fpts, g$fpts, "-"); ok <- upper.tri(da) & da != 0
  c(sum(ifelse(dp[ok] == 0, 0.5, as.numeric(sign(dp[ok]) == sign(da[ok])))), sum(ok)) })) }
boot <- function(a, b, label, B = 2000) { se_a <- tapply((a$fpts - a$proj)^2, wk, sum)[uw]; se_b <- tapply((b$fpts - b$proj)^2, wk, sum)[uw]; n <- tapply(wk, wk, length)[uw]
  ha <- hit_parts(a); hb <- hit_parts(b)
  d <- replicate(B, { i <- sample(length(uw), replace = TRUE)
    c(sum(se_b[i]) / sum(n[i]) - sum(se_a[i]) / sum(n[i]), sum(hb[i, 1]) / sum(hb[i, 2]) - sum(ha[i, 1]) / sum(ha[i, 2])) })
  message(label, ": squared error change ", round(mean((b$fpts - b$proj)^2) - mean((a$fpts - a$proj)^2), 4), " (95% ", paste(round(quantile(d[1, ], c(.025, .975)), 4), collapse = " to "),
          "; share of resamples not better ", round(mean(d[1, ] >= 0), 3), "); hit rate change ", round(hit(b) - hit(a), 4), " (95% ", paste(round(quantile(d[2, ], c(.025, .975)), 4), collapse = " to "),
          "; share not better ", round(mean(d[2, ] <= 0), 3), ")") }
message("\nD. Week bootstrap of points measures")
boot(base, r50[["1.307"]], "1.307 vs current"); boot(r50[["1.307"]], r50[["1.555"]], "1.555 vs 1.307"); boot(r50[["1.307"]], r50[["2"]], "2.0 vs 1.307"); boot(r50[["1.307"]], r50[["3"]], "3.0 vs 1.307")
boot(base, r49[["0"]], "40-49 at 0 vs current"); boot(base, r49[["0.5"]], "40-49 at +0.5 vs current"); boot(base, r49[["-0.5"]], "40-49 at -0.5 vs current")
