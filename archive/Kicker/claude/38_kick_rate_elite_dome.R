# #38 (2026-10-06): do coaches kick more from 40-49 range with an elite kicker in a dome? Descriptive tables, and kick-or-go models fit on recent seasons only.
# Run in the Kicker Wizerd chat as a one-off. No production script or model is changed. Log: claude/38_kick_rate_elite_dome_log.md. Needs the #36 workspace.

# ===================== PART 1: t38.R =====================
# #38 (2026-10-06): do coaches kick more often from 40-49 range with an elite kicker in a dome? Descriptive.
suppressMessages({library(dplyr); library(tidyr)})
plays <- readRDS("t31_plays.rds"); D <- readRDS("t31_D.rds")
pl <- plays |> filter(zone == "M", season <= 2025) |> left_join(D |> select(game_id, posteam, k4049 = krate_4049, k40 = krate_40plus, dome = is_enclosed, top16 = top), by = c("game_id", "posteam"))
cat("4th downs at the opponent's 22-31, 2016-2025:", nrow(pl), "| columns:", paste(intersect(c("ydstogo", "lytg", "score_differential", "qtr"), names(pl)), collapse = ","), "\n")
q <- quantile(D$krate_4049[D$season <= 2025], c(1/3, 2/3, .9)); cat("40-49 accuracy cut points (thirds, top 10%):", round(q, 3), "\n")
pl <- pl |> mutate(acc = cut(k4049, c(-Inf, q[1], q[2], Inf), labels = c("low", "mid", "high")), elite = k4049 >= q[3], era = ifelse(season <= 2022, "2016-22", "2023-25"), ytg = exp(lytg), long = ytg >= 3)
se <- function(p, n) sqrt(p * (1 - p) / n)
tab <- function(d, ...) as.data.frame(d |> group_by(...) |> summarise(fourth_downs = n(), kicked = round(mean(kicked), 3), se = round(se(mean(kicked), n()), 3), .groups = "drop"))
cat("\n-- by venue and accuracy third --\n"); print(tab(pl, dome, acc))
cat("\n-- by era, venue and accuracy third --\n"); print(tab(pl, era, dome, acc))
cat("\n-- top 10% of 40-49 accuracy (", round(q[3], 3), "+ ) vs the rest --\n"); print(tab(pl, dome, elite)); print(tab(pl, era, dome, elite))
cat("\n-- by yards to go: 1-2 vs 3+ --\n"); print(tab(pl, dome, acc, long))
cat("\n-- top-16 kickers only --\n"); print(tab(pl |> filter(top16), era, dome, acc))
# how many 4th downs in the zone per game, and how many 40-49 attempts come on other downs
tg <- D |> filter(season <= 2025) |> mutate(acc = cut(krate_4049, c(-Inf, q[1], q[2], Inf), labels = c("low", "mid", "high")), era = ifelse(season <= 2022, "2016-22", "2023-25"))
cat("\n-- per game: 4th downs at opp 22-31, 40-49 attempts --\n"); print(as.data.frame(tg |> group_by(era, dome = is_enclosed, acc) |> summarise(games = n(), fourth_downs = round(mean(n4_M), 3), att_4049 = round(mean(att_4049), 3), ratio = round(mean(att_4049) / mean(n4_M), 2), .groups = "drop")))
fix <- function(x) recode(x, OAK = "LV", SD = "LAC", STL = "LA", .default = x)
fg <- bind_rows(lapply(2016:2025, function(s) readRDS(sprintf("data/raw/play_by_play_%d.rds", s)) |> filter(season_type == "REG", field_goal_attempt == 1, kick_distance >= 40, kick_distance <= 49) |> transmute(season, game_id, posteam = fix(posteam), down, yardline_100, kick_distance, qtr, half_seconds_remaining)))
fg <- fg |> left_join(tg |> select(game_id, posteam, dome = is_enclosed, acc, era), by = c("game_id", "posteam"))
cat("\n40-49 yard attempts 2016-2025:", nrow(fg), "| on 4th down:", round(mean(fg$down == 4, na.rm = TRUE), 3), "| on 4th down from the opp 22-31:", round(mean(fg$down == 4 & fg$yardline_100 >= 22 & fg$yardline_100 <= 31, na.rm = TRUE), 3), "\n")
print(as.data.frame(fg |> group_by(era, dome, acc) |> summarise(attempts = n(), not_4th_down = round(mean(down != 4, na.rm = TRUE), 3), .groups = "drop")))
cat("kick distance minus yardline:", paste(names(table(fg$kick_distance - fg$yardline_100)), table(fg$kick_distance - fg$yardline_100), collapse = " | "), "\n")

# ===================== PART 2: t38b.R (check stated to the user first) =====================
# #38 part 2: kick-or-go models for long kicks fit on the four most recent seasons only. Check stated to the user first. Workspace only.
s36 <- readLines("t36_test.R"); eval(parse(text = s36[1:(grep("^cat\\(\"=== base \\(final 31\\) ===", s36) - 1)]))
r2 <- readLines("t31_round2.R"); a <- grep("^kick2 <- function", r2); b <- grep("^kfun <- function", r2) - 1; src <- paste(r2[a:b], collapse = "\n")
src <- sub("kick2 <- function\\(S, z, rhs, mode\\) memo\\(paste\\(\"k2\", S, z, rhs, mode\\)", "kick2w <- function(S, z, rhs, mode, win) memo(paste(\"k2w\", S, z, rhs, mode, win)", src)
stopifnot(grepl("kick2w", src), grepl("plays$season < S & plays$zone == z", src, fixed = TRUE))
src <- sub("plays$season < S & plays$zone == z", "plays$season < S & plays$season >= S - win & plays$zone == z", src, fixed = TRUE); eval(parse(text = src))
kfun <- function(mode) if (mode == "pre") function(S, z, rhs) kick(S, z, rhs) else if (grepl("^w", mode)) function(S, z, rhs) kick2w(S, z, rhs, "shift", as.integer(sub("w", "", mode))) else function(S, z, rhs) kick2(S, z, rhs, mode)
bld <- function(mM, mL) bind_rows(lapply(SCORED, function(S) { spec <- mk("shift", mM, mL, kc = c(S = BASE$kc[["S"]], M = LONGDC, L = LONGDC)); L <- attempts2(S, spec); L$att_039 <- cnt(S, "att_039", B039)$mu; te <- D[D$season == S, ]
  te |> transmute(season, week, game_id, posteam, top, fpts, xp_attempts, att_039, att_4049, att_50, l_xp = cnt(S, "xp_attempts", BXP)$mu, l039 = L$att_039, l4049 = L$att_4049, l50 = L$att_50, proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp)) })) |> filter(top)
chk <- bld("shift", "shift"); stopifnot(max(abs(chk$proj - base$proj)) < 1e-9); BOOT <- NULL
rowk <- function(nm, mM, mL, zs, win) { r <- bld(mM, mL); cc <- cmp(r, base, nm, "final 31"); pa <- parts(r); pb <- parts(base); e <- pa$season <= 2021
  g <- lapply(SCORED, function(S) unlist(lapply(zs, function(z) kick2(S, z, LONGDC, "shift")$oos - kick2w(S, z, LONGDC, "shift", win)$oos)))
  tibble(version = nm, decision_gain = 1000 * mean(unlist(g)), gain_2019_21 = 1000 * mean(unlist(g[SCORED <= 2021])), gain_2022_25 = 1000 * mean(unlist(g[SCORED >= 2022])), by_season = paste(round(1000 * sapply(g, mean), 1), collapse = " "),
         hit_change = cc$hit_change, hit_share = cc$hit_share, wcorr_change = cc$wcorr_change, wcorr_share = cc$wcorr_share, wcorr_2019_21 = wc(pa, which(e)) - wc(pb, which(e)), wcorr_2022_25 = wc(pa, which(!e)) - wc(pb, which(!e)), mse_change = cc$mse_change, mse_share = cc$mse_share,
         err_4049 = 1000 * (mean(dev_i(r$att_4049, r$l4049)) - mean(dev_i(base$att_4049, base$l4049))), err_50 = 1000 * (mean(dev_i(r$att_50, r$l50)) - mean(dev_i(base$att_50, base$l50)))) }
out <- bind_rows(rowk("40-49 decision on the last 4 seasons", "w4", "shift", "M", 4), rowk("50+ decision on the last 4 seasons", "shift", "w4", "L", 4), rowk("both on the last 4 seasons", "w4", "w4", c("M", "L"), 4),
                 rowk("(reference) 40-49 on the last 3 seasons", "w3", "shift", "M", 3), rowk("(reference) 40-49 on the last 6 seasons", "w6", "shift", "M", 6))
cat("=== Kick-or-go models on recent seasons only (vs the new model, which uses all earlier seasons) ===\n"); show(out)
cat("\n40-49 decision, team weights by fold: all earlier seasons | last 4 seasons\n")
A <- t(sapply(SCORED, function(S) kick2(S, "M", LONGDC, "shift")$coef)); W <- t(sapply(SCORED, function(S) kick2w(S, "M", LONGDC, "shift", 4)$coef)); rownames(A) <- rownames(W) <- SCORED; print(round(cbind(A, W), 2))
cat("\nfor the 2026 projections: fit on 2016-2025 vs 2022-2025\n"); print(round(rbind(all = kick2(2026, "M", LONGDC, "shift")$coef, last4 = kick2w(2026, "M", LONGDC, "shift", 4)$coef), 2)); cat("plays:", kick2(2026, "M", LONGDC, "shift")$n, kick2w(2026, "M", LONGDC, "shift", 4)$n, "\n")
cat("50+ decision, 2026: \n"); print(round(rbind(all = kick2(2026, "L", LONGDC, "shift")$coef, last4 = kick2w(2026, "L", LONGDC, "shift", 4)$coef), 2))
# dome kickers in the top third of 40-49 accuracy: actual vs predicted 40-49 attempts, by season group
tp <- D |> filter(season <= 2025, top, is_enclosed == 1); cutp <- quantile(tp$krate_4049, 2/3); r4 <- bld("w4", "shift")
for (nm in c("new model", "40-49 decision on last 4")) { v <- (if (nm == "new model") base else r4) |> inner_join(tp |> filter(krate_4049 > cutp) |> select(game_id, posteam), by = c("game_id", "posteam")) |> mutate(era = ifelse(season <= 2022, "2019-22", "2023-25"))
  cat(nm, ": accurate dome kickers, 40-49 attempts actual vs predicted:\n"); print(as.data.frame(v |> group_by(era) |> summarise(n = n(), actual = round(mean(att_4049), 3), predicted = round(mean(l4049), 3)))) }
saveRDS(list(out = out), "t38_results.rds")

# ===================== PART 3: t38c.R (season by season) =====================
suppressMessages({library(dplyr); library(tidyr)})
D <- readRDS("t31_D.rds"); plays <- readRDS("t31_plays.rds"); q <- quantile(D$krate_4049[D$season <= 2025], c(1/3, 2/3))
tg <- D |> filter(season <= 2025) |> mutate(grp = ifelse(is_enclosed == 1 & krate_4049 > q[2], "dome, accurate", ifelse(is_enclosed == 1, "dome, others", ifelse(krate_4049 > q[2], "outdoors, accurate", "outdoors, others"))))
cat("40-49 attempts per game by season, all team-games (games in the dome-accurate group in brackets)\n")
x <- tg |> group_by(season, grp) |> summarise(v = round(mean(att_4049), 2), n = n(), .groups = "drop"); w <- pivot_wider(x |> select(-n), names_from = grp, values_from = v); w$n_dome_accurate <- x$n[x$grp == "dome, accurate"]; print(as.data.frame(w))
cat("\n4th downs at opp 22-31 per game by season\n"); print(as.data.frame(pivot_wider(tg |> group_by(season, grp) |> summarise(v = round(mean(n4_M), 2), .groups = "drop"), names_from = grp, values_from = v)))
pl <- plays |> filter(zone == "M", season <= 2025) |> left_join(tg |> select(game_id, posteam, grp), by = c("game_id", "posteam"))
cat("\nshare kicked on those 4th downs by season\n"); print(as.data.frame(pivot_wider(pl |> group_by(season, grp) |> summarise(v = round(mean(kicked), 2), .groups = "drop"), names_from = grp, values_from = v)))
cat("\ntop-16 kickers only, 40-49 attempts per game by season\n"); x <- tg |> filter(top) |> group_by(season, grp) |> summarise(v = round(mean(att_4049), 2), n = n(), .groups = "drop"); w <- pivot_wider(x |> select(-n), names_from = grp, values_from = v); w$n_dome_accurate <- x$n[x$grp == "dome, accurate"]; print(as.data.frame(w))
d26 <- readRDS("../t30/d2026.rds"); if (all(c("att_4049", "krate_4049", "is_enclosed") %in% names(d26))) { d26$grp <- ifelse(d26$is_enclosed == 1 & d26$krate_4049 > q[2], "dome, accurate", ifelse(d26$is_enclosed == 1, "dome, others", ifelse(d26$krate_4049 > q[2], "outdoors, accurate", "outdoors, others")))
  cat("\n2026 weeks 1-4:\n"); print(as.data.frame(d26 |> group_by(grp) |> summarise(games = n(), att_4049 = round(mean(att_4049), 2), att_50 = round(mean(att_50), 2)))) }
