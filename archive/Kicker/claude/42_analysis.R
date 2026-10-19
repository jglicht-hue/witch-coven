# #42 Kicker accuracy on the new model (2026-10-13). Rules: claude/42_accuracy_new_model_retest_rules.md (written first).
# Reads t42/inputs_<season>.rds (t42_build_inputs.R) and the raw play-by-play. Experiment only.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
source("09n_new_model.R"); nm <- load_new_model()
fix <- function(x) recode(x, OAK = "LV", SD = "LAC", STL = "LA", .default = x)
set.seed(42)
R <- c("039", "4049", "50"); PTS <- c("039" = 3, "4049" = 4, "50" = 5)

D <- bind_rows(lapply(2016:2025, function(s) readRDS(sprintf("t42/inputs_%d.rds", s)))) |>
  filter(!is.na(kicker_player_id), !is.na(actual_points)) |>
  mutate(exp_margin = 2 * implied_team_total - total_line, wk = season * 100 + week)
stopifnot(!anyNA(D[c("implied_team_total", "exp_margin", "is_enclosed", "krate_40plus", "coach_long_fg_rate")]))
cat("team-games", nrow(D), "; top-16", sum(D$top16pre), "; weeks", length(unique(D$wk)), "\n")

# decayed records (32-game fade) from the Beta parameters: a = dm + 5 lg, a + b = da + 5
for (r in R) { lg <- D[[paste0("lg_", r)]]; a <- D[[paste0("a_", r)]]; b <- D[[paste0("b_", r)]]
  D[[paste0("da_", r)]] <- a + b - 5; D[[paste0("dm_", r)]] <- a - 5 * lg
  stopifnot(max(abs(a / (a + b) - D[[paste0("p_", r)]])) < 1e-9) }
D$N_all <- D$da_039 + D$da_4049 + D$da_50
cat("check: decayed attempts >= 0:", all(D$N_all > -1e-9), "; makes <= attempts:", all(D$dm_039 <= D$da_039 + 1e-9), "\n")

# make chances under a candidate
make_p <- function(d, w_good = 5, w_bad = 5, dock = 0) {
  out <- lapply(setNames(R, R), function(r) { da <- d[[paste0("da_", r)]]; dm <- d[[paste0("dm_", r)]]; lg <- d[[paste0("lg_", r)]]
    good <- da > 1e-9 & dm / pmax(da, 1e-9) > lg; w <- ifelse(good, w_good, w_bad)
    p <- ifelse(da > 1e-9, (dm + w * lg) / (da + w), lg)
    pmin(pmax(p - dock / 100 * 10 / (d$N_all + 10), 0.01), 0.999) })
  x <- data.frame(p_039 = out[["039"]], p_4049 = out[["4049"]], p_50 = out[["50"]], p_xp = d$p_xp, is_enclosed = d$is_enclosed)
  new_model_make_chances(nm, x) }
proj_pts <- function(lam, p) lam$lambda_xp * p$p_xp + lam$lambda_039 * (4 * p$p_039 - 1) + lam$lambda_4049 * (5 * p$p_4049 - 1) + lam$lambda_50 * (6 * p$p_50 - 1)

LAM <- new_model_attempts(nm, D)
P0 <- make_p(D)
# reproduction: production make chances = base candidate
stopifnot(max(abs(P0$p_039 - new_model_make_chances(nm, D)$p_039)) < 1e-12)
D$proj_base <- proj_pts(LAM, P0)

CANDS <- list(A1 = list(w_good = 3, w_bad = 3), A2 = list(w_good = 2, w_bad = 2), B1 = list(w_bad = 2), B2 = list(w_bad = 3), B3 = list(w_bad = 20),
              C1 = list(dock = 1), C2 = list(dock = 2), C3 = list(dock = 3), E = list(w_bad = 2, dock = 2))
for (k in names(CANDS)) D[[paste0("proj_", k)]] <- proj_pts(LAM, do.call(make_p, c(list(d = D), CANDS[[k]])))

# ---- Candidate D: kick-decision accuracy at a 32-game fade, kick models refit leave-one-season-out ----
d32 <- (D$dm_4049 + D$dm_50 + 5 * D$lg_40plus) / (D$da_4049 + D$da_50 + 5)
D$krate32 <- d32
COLS <- c("season", "week", "game_id", "season_type", "posteam", "down", "yardline_100", "ydstogo", "score_differential", "half_seconds_remaining", "qtr", "play_type", "field_goal_attempt")
plays <- bind_rows(lapply(2016:2025, function(y) readRDS(sprintf("data/raw/play_by_play_%d.rds", y))[, COLS] |>
  filter(season_type == "REG", down == 4, yardline_100 >= 22, yardline_100 <= 41, play_type %in% c("field_goal", "punt", "pass", "run"),
         !is.na(score_differential), !is.na(half_seconds_remaining)))) |>
  mutate(posteam = fix(posteam), kicked = as.integer(field_goal_attempt == 1), zone = ifelse(yardline_100 <= 31, "M", "L"),
         lytg = log(ydstogo), q4 = as.integer(qtr >= 4), late = as.integer(half_seconds_remaining <= 120),
         d4 = as.integer(score_differential <= -4), d9 = as.integer(score_differential <= -9)) |>
  inner_join(D |> select(game_id, posteam, is_enclosed, krate_40plus, krate32, coach_long_fg_rate, exp_margin), by = c("game_id", "posteam"))
cat("4th-down plays in long range:", nrow(plays), "(M", sum(plays$zone == "M"), ", L", sum(plays$zone == "L"), ")\n")
T_GRID <- seq(-4, 12, by = 0.5); M_GRID <- seq(-32, 32, by = 4)
kick_att <- function(acc_col, hold) {
  tr_p <- plays[plays$season != hold, ]; te <- D[D$season == hold, ]; trD <- D[D$season != hold & D$top16pre, ]
  out <- list()
  for (z in c("M", "L")) {
    pt <- tr_p[tr_p$zone == z, ]; pt$acc <- pt[[acc_col]]; pt$fs <- factor(pt$season)
    g <- glm(kicked ~ yardline_100 + lytg + score_differential + d4 + d9 + q4 + late + q4:d4 + is_enclosed + acc + is_enclosed:acc + coach_long_fg_rate + fs, binomial, pt)
    b <- coef(g); lv <- levels(pt$fs); fe <- c(0, b[paste0("fs", lv[-1])]); level <- mean(fe)
    fx <- b[["(Intercept)"]] + level + b[["yardline_100"]] * pt$yardline_100 + b[["lytg"]] * pt$lytg + b[["q4"]] * pt$q4 + b[["late"]] * pt$late
    slope <- coef(lm(score_differential ~ exp_margin, pt))[[2]]
    chance_exact <- function(t, m) { sc <- pt$score_differential + slope * (m - pt$exp_margin)
      mean(plogis(fx + b[["score_differential"]] * sc + b[["d4"]] * (sc <= -4) + b[["d9"]] * (sc <= -9) + b[["d4:q4"]] * pt$q4 * (sc <= -4) + t)) }
    G <- outer(T_GRID, M_GRID, Vectorize(function(t, m) qlogis(chance_exact(t, m))))
    tt <- function(d) b[["is_enclosed"]] * d$is_enclosed + b[["acc"]] * d[[acc_col]] + b[["coach_long_fg_rate"]] * d$coach_long_fg_rate + b[["is_enclosed:acc"]] * d$is_enclosed * d[[acc_col]]
    interp <- function(t, m) { ti <- pmin(pmax((t - T_GRID[1]) / 0.5, 0), length(T_GRID) - 1 - 1e-9); i0 <- floor(ti); ft <- ti - i0
      mi <- pmin(pmax((m - M_GRID[1]) / 4, 0), length(M_GRID) - 1 - 1e-9); j0 <- floor(mi); fm <- mi - j0; at <- function(i, j) G[cbind(i + 1, j + 1)]
      plogis((1 - ft) * (1 - fm) * at(i0, j0) + ft * (1 - fm) * at(i0 + 1, j0) + (1 - ft) * fm * at(i0, j0 + 1) + ft * fm * at(i0 + 1, j0 + 1)) }
    y <- trD[[if (z == "M") "att_4049" else "att_50"]]
    scale <- sum(y) / sum(interp(tt(trD), trD$exp_margin))
    out[[z]] <- interp(tt(te), te$exp_margin) * scale }
  out }
# actual attempts and makes per team-game (for the kick-model level and the Brier score)
mk <- bind_rows(lapply(2016:2025, function(y) readRDS(sprintf("data/raw/play_by_play_%d.rds", y)) |>
  filter(season_type == "REG", field_goal_attempt == 1, !is.na(kick_distance), !is.na(posteam)) |>
  transmute(game_id, posteam = fix(posteam), r = case_when(kick_distance <= 39 ~ "039", kick_distance <= 49 ~ "4049", TRUE ~ "50"), made = as.integer(field_goal_result == "made")))) |>
  group_by(game_id, posteam, r) |> summarise(a = n(), m = sum(made), .groups = "drop") |> pivot_wider(names_from = r, values_from = c(a, m), values_fill = 0)
D <- D |> select(-a_039, -b_039, -a_4049, -b_4049, -a_50, -b_50) |> left_join(mk, by = c("game_id", "posteam")) |> mutate(across(c(a_039, a_4049, a_50, m_039, m_4049, m_50), ~ coalesce(.x, 0L)), att_4049 = a_4049, att_50 = a_50)
# careful: a_039 etc. now hold actual attempts; the Beta columns were consumed above
D$proj_Dbase <- NA_real_; D$proj_D <- NA_real_
for (h in 2016:2025) { i <- D$season == h
  for (v in c("krate_40plus", "krate32")) { k <- kick_att(v, h); lam <- LAM[i, ]; lam$lambda_4049 <- k$M; lam$lambda_50 <- k$L
    D[[if (v == "krate_40plus") "proj_Dbase" else "proj_D"]][i] <- proj_pts(lam, P0[i, ]) } }
cat("D refit done. mean |Dbase - production| =", round(mean(abs(D$proj_Dbase - D$proj_base)), 3), "\n")

# ---- measures -------------------------------------------------------------------------------
wk_stats <- function(d, col) { d |> group_by(season, wk) |> group_modify(function(x, k) {
  p <- x[[col]]; y <- x$actual_points; pc <- p - mean(p); yc <- y - mean(y)
  dy <- outer(y, y, "-"); dp <- outer(p, p, "-"); u <- upper.tri(dy) & dy != 0
  tibble(sxy = sum(pc * yc), sxx = sum(pc^2), syy = sum(yc^2), conc = sum((sign(dp[u]) == sign(dy[u])) + 0.5 * (dp[u] == 0)), pairs = sum(u),
         se = sum((y - p)^2), n = length(y)) }) |> ungroup() }
agg <- function(s) c(corr = sum(s$sxy) / sqrt(sum(s$sxx) * sum(s$syy)), hit = sum(s$conc) / sum(s$pairs), mse = sum(s$se) / sum(s$n))
TOP <- D[D$top16pre, ]
weeks <- sort(unique(D$wk)); B <- 2000; BOOT <- replicate(B, sample(length(weeks), replace = TRUE))
compare <- function(col, base) {
  st <- list(t_c = wk_stats(TOP, col), t_b = wk_stats(TOP, base), a_c = wk_stats(D, col), a_b = wk_stats(D, base))
  for (n in names(st)) st[[n]] <- st[[n]][match(weeks, st[[n]]$wk), ]
  full <- rbind(cand = agg(st$t_c), base = agg(st$t_b)); fa <- c(cand = agg(st$a_c)[["hit"]], base = agg(st$a_b)[["hit"]])
  bs <- t(sapply(seq_len(B), function(j) { i <- BOOT[, j]; ok <- !is.na(st$t_c$wk[i])
    dc <- agg(st$t_c[i[ok], ]) - agg(st$t_b[i[ok], ]); c(dc, all_hit = agg(st$a_c[i, ])[["hit"]] - agg(st$a_b[i, ])[["hit"]]) }))
  seas <- sapply(2016:2025, function(s) { a <- agg(st$t_c[st$t_c$season == s, ]); b <- agg(st$t_b[st$t_b$season == s, ]); c(corr = a[["corr"]] > b[["corr"]], hit = a[["hit"]] > b[["hit"]]) })
  tibble(corr = full["cand", "corr"], d_corr = full["cand", "corr"] - full["base", "corr"], share_corr = mean(bs[, "corr"] > 0), seasons_corr = sum(seas["corr", ]),
         hit = full["cand", "hit"], d_hit = full["cand", "hit"] - full["base", "hit"], share_hit = mean(bs[, "hit"] > 0), seasons_hit = sum(seas["hit", ]),
         d_mse = full["cand", "mse"] - full["base", "mse"], share_mse_better = mean(bs[, "mse"] < 0),
         d_all_hit = fa[["cand"]] - fa[["base"]], share_all_hit = mean(bs[, "all_hit"] > 0)) |>
    mutate(pass = share_corr >= 0.80 & share_hit >= 0.80 & seasons_corr >= 6 & share_all_hit >= 0.20) }
base_m <- agg(wk_stats(TOP, "proj_base")); cat("base (top 16): within-week corr", round(base_m[["corr"]], 4), " hit", round(base_m[["hit"]], 4), " mse", round(base_m[["mse"]], 3), "\n")
res <- bind_rows(lapply(names(CANDS), function(k) compare(paste0("proj_", k), "proj_base") |> mutate(cand = k, .before = 1)),
                 compare("proj_D", "proj_Dbase") |> mutate(cand = "D", .before = 1))
# Brier of FG make chances on actual kicks (all team-games)
brier <- function(P) { s <- 0; n <- 0; for (r in R) { a <- D[[paste0("a_", r)]]; m <- D[[paste0("m_", r)]]; p <- P[[paste0("p_", r)]]
  s <- s + sum(m * (1 - p)^2 + (a - m) * p^2); n <- n + sum(a) }; 1000 * s / n }
br <- c(base = brier(P0), sapply(names(CANDS), function(k) brier(do.call(make_p, c(list(d = D), CANDS[[k]])))))
res$brier_x1000 <- br[res$cand]; res$brier_base <- br[["base"]]
options(width = 250); print(as.data.frame(res |> mutate(across(where(is.double), ~ round(.x, 4)))))
write_csv(res, "t42/results.csv")
saveRDS(list(D = D, res = res, br = br), "t42/analysis.rds")
