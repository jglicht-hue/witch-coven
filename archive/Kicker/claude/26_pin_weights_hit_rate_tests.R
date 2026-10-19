# #26 Do the pinned accuracy weights rank top-16 kickers better on seasons the models never saw? (2026-10-05)
# One-off test run in the Kicker Wizerd chat. No production script or model was changed.
# Rules were set and sent to the user before any 2016-2022 hit rate was seen (see claude/26_pin_weights_hit_rate_log.md).
# Run from the pipeline folder after run_all.R. Needs: data/raw/play_by_play_2013..2025.rds and games.rds, 09_weekly_inputs.R,
# 08a_inputs.R (the input-building half of 08a), 08_points_distribution.R, and t25_tg.rds (the long table from #25's PART 1).

# ======================= PART 1: live-style weekly inputs, 2016-2025 (about 1 minute per season) =======================
suppressMessages({library(dplyr); library(tidyr); library(readr)})
source("09_weekly_inputs.R")
fix <- function(x) recode(x, OAK = "LV", SD = "LAC", STL = "LA", .default = x)
COLS <- c("season", "week", "game_id", "play_id", "season_type", "posteam", "defteam", "fixed_drive", "drive_inside20", "fixed_drive_result", "down",
          "yardline_100", "field_goal_attempt", "extra_point_attempt", "field_goal_result", "extra_point_result", "kick_distance",
          "kicker_player_id", "kicker_player_name")
for (S in 2016:2025) { if (file.exists(sprintf("t26_inputs_%d.rds", S))) next
  # the 4-season window a live run would use; relocated-team codes aligned between play-by-play and schedule
  pbp <- bind_rows(lapply((S - 3):S, function(y) readRDS(sprintf("data/raw/play_by_play_%d.rds", y))[, COLS])) |>
    mutate(posteam = fix(posteam), defteam = fix(defteam), ord = season * 100 + week)
  sched <- readRDS("data/raw/games.rds") |> filter(season %in% (S - 3):S) |>
    mutate(home_team = fix(home_team), away_team = fix(away_team), ord = season * 100 + week)
  weeks <- sort(unique(sched$week[sched$season == S & sched$game_type == "REG" & !is.na(sched$result)]))
  out <- bind_rows(lapply(weeks, function(w) { tord <- S * 100 + w
    # data through the target week only; later results blanked (the target week's kicks are kept so the kicker is who kicked, as in training)
    p <- pbp |> filter(ord <= tord) |> select(-ord)
    s <- sched |> mutate(result = if_else(ord > tord, NA_real_, as.numeric(result))) |> select(-ord)
    build_week_inputs(p, s, S, w) }))
  saveRDS(out, sprintf("t26_inputs_%d.rds", S)); cat(S, "rows", nrow(out), "weeks", length(weeks), "\n") }

# ======================= PART 2: hit-rate test =======================
set.seed(20261005)
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
source("08a_inputs.R"); source("08_points_distribution.R")
F_XP <- "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8 + coach_long_fg_rate"
F_039 <- "implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"
F4049_CUR <- "is_enclosed + krate_4049 + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"
F4049_PIN <- "is_enclosed + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate + offset(off49)"
F50_CUR <- "is_enclosed + krate_40plus + is_enclosed:krate_50"; F50_PIN <- "is_enclosed + is_enclosed:krate_50 + offset(off50)"
top <- vol |> filter(top16pre)

# ---- long-window inputs (09's builder, data through each target week only) + outcomes from the long table ----
inp <- bind_rows(lapply(2016:2025, function(s) readRDS(sprintf("t26_inputs_%d.rds", s))))
lt <- readRDS("t25_tg.rds") |> select(game_id, posteam, lt_kicker = kicker_player_id, att_039, att_4049, att_50, fpts, top16pre)
d <- inp |> inner_join(lt, by = c("game_id", "posteam"))
cat("builder rows", nrow(inp), "; joined", nrow(d), "; kicker agrees with long table", round(mean(d$kicker_player_id == d$lt_kicker, na.rm = TRUE), 4),
    "; roof unknown", sum(d$roof_unknown), "; lines imputed", sum(d$implied_imputed), "; missing predictors", sum(!complete.cases(d[, c("krate_40plus", "krate_4049", "krate_50", "coach_long_fg_rate", "p_xp")])), "\n")
ck <- d |> filter(season >= 2023) |> inner_join(vol |> select(game_id, posteam, v_fpts = fpts, v_top = top16pre, v_k40 = krate_40plus, v_k4049 = krate_4049, v_itt = implied_team_total, v_coach = coach_long_fg_rate, v_p50 = p_50), by = c("game_id", "posteam"))
cat("2023-25 check vs production table (", nrow(ck), "rows): fpts mismatches", sum(ck$fpts != ck$v_fpts), "; top16 agree", round(mean(ck$top16pre == ck$v_top), 4),
    "; max |diff| krate_40plus", signif(max(abs(ck$krate_40plus - ck$v_k40)), 3), " krate_4049", signif(max(abs(ck$krate_4049 - ck$v_k4049)), 3),
    " implied total", signif(max(abs(ck$implied_team_total - ck$v_itt)), 3), " coach long rate", signif(max(abs(ck$coach_long_fg_rate - ck$v_coach)), 3), " p_50", signif(max(abs(ck$p_50 - ck$v_p50)), 3), "\n")
old <- d |> filter(season <= 2022, top16pre)
cat("2016-2022 pre-game top-16 team-games:", nrow(old), "\n")

# ---- projections: models fit on all 2023-25 top-16 rows (as production), scored on 2016-2022 ----
proj_old <- function(f4049, f50, w49 = 0, w50 = 0) { tr <- top |> mutate(off49 = w49 * krate_4049, off50 = w50 * krate_40plus)
  te <- old |> mutate(off49 = w49 * krate_4049, off50 = w50 * krate_40plus)
  g <- function(o, rhs) predict(glm(as.formula(paste(o, "~", rhs)), poisson, tr), te, type = "response")
  te |> mutate(l_xp = g("xp_attempts", F_XP), l039 = g("att_039", F_039), l4049 = g("att_4049", f4049), l50 = g("att_50", f50),
               proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp)) }
# 2023-25: leave one season out, as #24/#25
proj_new <- function(f4049, f50, w49 = 0, w50 = 0) bind_rows(lapply(2023:2025, function(s) {
  dd <- top |> mutate(off49 = w49 * krate_4049, off50 = w50 * krate_40plus); tr <- dd[dd$season != s, ]; te <- dd[dd$season == s, ]
  g <- function(o, rhs) predict(glm(as.formula(paste(o, "~", rhs)), poisson, tr), te, type = "response")
  te |> mutate(l_xp = g("xp_attempts", F_XP), l039 = g("att_039", F_039), l4049 = g("att_4049", f4049), l50 = g("att_50", f50),
               proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp)) }))
CAND <- list(current = list(F4049_CUR, F50_CUR, 0, 0), `50+ at 1.307` = list(F4049_CUR, F50_PIN, 0, 1.307), `50+ at 2.0` = list(F4049_CUR, F50_PIN, 0, 2.0),
             `50+ at 3.0` = list(F4049_CUR, F50_PIN, 0, 3.0), `40-49 at 0` = list(F4049_PIN, F50_CUR, 0, 0), `40-49 at +0.5` = list(F4049_PIN, F50_CUR, 0.5, 0),
             `50+ at 2.0 with 40-49 at 0` = list(F4049_PIN, F50_PIN, 0, 2.0))
COMP <- list(c("50+ at 1.307", "current"), c("50+ at 2.0", "50+ at 1.307"), c("50+ at 3.0", "50+ at 1.307"), c("40-49 at 0", "current"),
             c("40-49 at +0.5", "current"), c("50+ at 2.0 with 40-49 at 0", "current"))
hit_parts <- function(dd) { wk <- paste(dd$season, dd$week); uw <- unique(wk)
  m <- t(sapply(uw, function(w) { g <- dd[wk == w, ]; if (nrow(g) < 2) return(c(0, 0))
    dp <- outer(g$proj, g$proj, "-"); da <- outer(g$fpts, g$fpts, "-"); ok <- upper.tri(da) & da != 0
    c(sum(ifelse(dp[ok] == 0, 0.5, as.numeric(sign(dp[ok]) == sign(da[ok])))), sum(ok)) }))
  data.frame(wk = uw, season = as.integer(substr(uw, 1, 4)), h = m[, 1], n = m[, 2], sse = as.numeric(tapply((dd$fpts - dd$proj)^2, wk, sum)[uw]), ng = as.numeric(tapply(wk, wk, length)[uw])) }
report <- function(P, label, B = 2000) { H <- lapply(P, hit_parts); nw <- nrow(H[[1]]); seasons <- sort(unique(H[[1]]$season))
  cat("\n=====", label, ": weeks", nw, "; pairs", sum(H[[1]]$n), "; team-games", sum(H[[1]]$ng), "=====\n")
  tab <- bind_rows(lapply(names(H), function(k) { h <- H[[k]]; bs <- sapply(seasons, function(s) sum(h$h[h$season == s]) / sum(h$n[h$season == s]))
    as_tibble(c(list(version = k, hit = sum(h$h) / sum(h$n), mse = sum(h$sse) / sum(h$ng)), setNames(as.list(bs), paste0("hit", seasons)))) }))
  print(as.data.frame(tab |> mutate(across(where(is.double), ~ round(.x, 4)))), width = 250)
  idx <- replicate(B, sample(nw, replace = TRUE))
  out <- bind_rows(lapply(COMP, function(cc) { a <- H[[cc[1]]]; b <- H[[cc[2]]]
    dh <- apply(idx, 2, function(i) sum(a$h[i]) / sum(a$n[i]) - sum(b$h[i]) / sum(b$n[i])); dm <- apply(idx, 2, function(i) (sum(a$sse[i]) - sum(b$sse[i])) / sum(a$ng[i]))
    ps <- sapply(seasons, function(s) sum(a$h[a$season == s]) / sum(a$n[a$season == s]) - sum(b$h[b$season == s]) / sum(b$n[b$season == s]))
    tibble(candidate = cc[1], vs = cc[2], hit_change = sum(a$h) / sum(a$n) - sum(b$h) / sum(b$n), lo = quantile(dh, .025), hi = quantile(dh, .975), share_better = mean(dh > 0),
           seasons_better = paste0(sum(ps > 0), "/", length(seasons)), mse_change = sum(a$sse) / sum(a$ng) - sum(b$sse) / sum(b$ng), mse_share_better = mean(dm < 0)) }))
  print(as.data.frame(out |> mutate(across(where(is.double), ~ round(.x, 4)))), width = 250); invisible(list(tab = tab, comp = out)) }
P_old <- lapply(CAND, function(x) proj_old(x[[1]], x[[2]], x[[3]], x[[4]]))
r_old <- report(P_old, "2016-2022 (independent; models fit on 2023-25)")
P_new <- lapply(CAND, function(x) proj_new(x[[1]], x[[2]], x[[3]], x[[4]]))
r_new <- report(P_new, "2023-2025 (leave one season out; the seasons the grid was scanned on)")
# attempts error on 2016-2022 (reported, not deciding)
att <- bind_rows(lapply(names(P_old), function(k) tibble(version = k, gain50 = mean(1000 * (dev_i(P_old$current$att_50, P_old$current$l50) - dev_i(P_old[[k]]$att_50, P_old[[k]]$l50))),
  gain4049 = mean(1000 * (dev_i(P_old$current$att_4049, P_old$current$l4049) - dev_i(P_old[[k]]$att_4049, P_old[[k]]$l4049))),
  mean_proj = mean(P_old[[k]]$proj), mean_actual = mean(P_old[[k]]$fpts))))
cat("\nAttempts gain vs current on 2016-2022 (x1000, positive = better) and projection level\n"); print(as.data.frame(att |> mutate(across(where(is.double), ~ round(.x, 3)))))
# descriptive grids on 2016-2022
g50 <- bind_rows(lapply(c(0, 0.664, 1, 1.307, 1.555, 2, 2.5, 3, 4), function(w) { h <- hit_parts(proj_old(F4049_CUR, F50_PIN, 0, w)); tibble(w50 = w, hit = sum(h$h) / sum(h$n), mse = sum(h$sse) / sum(h$ng)) }))
g49 <- bind_rows(lapply(c(-1.325, -0.5, 0, 0.25, 0.5, 1, 2), function(w) { h <- hit_parts(proj_old(F4049_PIN, F50_CUR, w, 0)); tibble(w49 = w, hit = sum(h$h) / sum(h$n), mse = sum(h$sse) / sum(h$ng)) }))
cat("\nDescriptive grids on 2016-2022\n"); print(as.data.frame(g50 |> mutate(across(everything(), ~ round(.x, 4))))); print(as.data.frame(g49 |> mutate(across(everything(), ~ round(.x, 4)))))
write_csv(r_old$tab, "t26_old_tab.csv"); write_csv(r_old$comp, "t26_old_comp.csv"); write_csv(r_new$tab, "t26_new_tab.csv"); write_csv(r_new$comp, "t26_new_comp.csv"); write_csv(g50, "t26_grid50_old.csv"); write_csv(g49, "t26_grid49_old.csv")
# ---- pooled over all 10 seasons (2016-22 scored with 2023-25 fits; 2023-25 leave one season out) ----
P_all <- lapply(names(CAND), function(k) bind_rows(P_old[[k]] |> select(season, week, fpts, proj), P_new[[k]] |> select(season, week, fpts, proj))); names(P_all) <- names(CAND)
r_all <- report(P_all, "2016-2025 pooled")
write_csv(r_all$tab, "t26_all_tab.csv"); write_csv(r_all$comp, "t26_all_comp.csv")
# ---- how far the live-style inputs sit from the training table, by season (expected: the training table starts kicker records in 2023) ----
print(as.data.frame(ck |> group_by(season) |> summarise(mean_abs_k40 = mean(abs(krate_40plus - v_k40)), mean_abs_k4049 = mean(abs(krate_4049 - v_k4049)), mean_abs_coach = mean(abs(coach_long_fg_rate - v_coach)),
  cor_k40 = cor(krate_40plus, v_k40)) |> mutate(across(where(is.double), ~ round(.x, 4)))))
# ---- added after the results (descriptive): the likely build, 50+ at 1.307 with the 40-49 outdoor weight at 0 ----
CAND <- c(CAND, list(`50+ at 1.307 with 40-49 at 0` = list(F4049_PIN, F50_PIN, 0, 1.307))); COMP <- list(c("50+ at 1.307 with 40-49 at 0", "current"), c("50+ at 1.307 with 40-49 at 0", "50+ at 1.307"))
k <- "50+ at 1.307 with 40-49 at 0"; x <- CAND[[k]]; P_old[[k]] <- proj_old(x[[1]], x[[2]], x[[3]], x[[4]]); P_new[[k]] <- proj_new(x[[1]], x[[2]], x[[3]], x[[4]])
P_all[[k]] <- bind_rows(P_old[[k]] |> select(season, week, fpts, proj), P_new[[k]] |> select(season, week, fpts, proj))
a1 <- report(P_old, "ADDED AFTER: 2016-2022"); a2 <- report(P_new, "ADDED AFTER: 2023-2025"); a3 <- report(P_all, "ADDED AFTER: 2016-2025 pooled")
cat("Projection moves vs current, 50+ at 1.307 with 40-49 at 0: 2016-22 mean", round(mean(abs(P_old[[k]]$proj - P_old$current$proj)), 3), "max", round(max(abs(P_old[[k]]$proj - P_old$current$proj)), 2), "\n")
