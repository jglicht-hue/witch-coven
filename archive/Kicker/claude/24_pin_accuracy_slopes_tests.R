# #24 Pin the outdoor accuracy weights in the long-range attempt models (2026-10-05, Kicker Wizerd chat, one-off; no production changes).
# Log: claude/24_pin_accuracy_slopes_log.md. Run after 23's build step (t23_tg.rds; for part 2 rebuild it with YEARS <- 2011:2026 as t23_tg_2026.rds)
# and run_all.R. Part 2 also needs 09_weekly_inputs.R and t5_week4_inputs.csv (week-4 inputs saved by 18's script).

# ===================== PART 1: 2016-2022 slopes and the 2023-25 backtest =====================
# #24 Pin the outdoor accuracy weights in the long-range models (2026-10-05). Rules set before results (see log).
# Needs t23_tg.rds (from 23's build step), data/ tables from run_all.R, 08a_inputs.R, 08_points_distribution.R.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
set.seed(20261005)
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))

# ---- 1. Outdoor slope of 50+ attempts on 40+ accuracy, estimated on 2016-2022 only -------------
lt <- readRDS("t23_tg.rds") |> filter(season %in% 2016:2022) |> mutate(r40 = acc12 + lg40)
est <- function(d) { f <- glm(att_50 ~ factor(season) + dome + r40 + dome:r40, poisson, d); summary(f)$coefficients["r40", 1:2] }
b_top <- est(lt[lt$top16pre, ]); b_all <- est(lt)
est4049 <- function(d) { f <- glm(att_4049 ~ factor(season) + dome + r40 + dome:r40, poisson, d); summary(f)$coefficients["r40", 1:2] }
message("2016-2022 outdoor slope of 50+ attempts per unit of 40+ accuracy: top16 ", round(b_top[1], 3), " (se ", round(b_top[2], 3),
        "), all ", round(b_all[1], 3), " (se ", round(b_all[2], 3), "); production (2023-25 fit): 0.664 (se 0.844)")
message("2016-2022 outdoor slope of 40-49 attempts on 40+ accuracy: top16 ", paste(round(est4049(lt[lt$top16pre, ]), 3), collapse = " se "),
        "; all ", paste(round(est4049(lt), 3), collapse = " se "), "; production on 40-49 accuracy: -1.325 (se 0.971)")
B50 <- c(top16 = unname(b_top[1]), all = unname(b_all[1]))

# ---- 2. Production backtest with each version -------------------------------------------------
source("08a_inputs.R"); source("08_points_distribution.R")
vol <- vol |> mutate(off_top = B50[["top16"]] * krate_40plus, off_all = B50[["all"]] * krate_40plus)
F_XP <- "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8 + coach_long_fg_rate"
F_039 <- "implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"
F4049 <- c(cur = "is_enclosed + krate_4049 + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
           zero = "is_enclosed + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate")
F50 <- c(cur = "is_enclosed + krate_40plus + is_enclosed:krate_50", top = "is_enclosed + is_enclosed:krate_50 + offset(off_top)",
         all = "is_enclosed + is_enclosed:krate_50 + offset(off_all)")
VERSIONS <- list(current = c("cur", "cur"), `50+ pinned (top-16 estimate)` = c("cur", "top"), `50+ pinned (all-kicker estimate)` = c("cur", "all"),
                 `40-49 outdoor weight zero` = c("zero", "cur"), `both (50+ top-16 estimate)` = c("zero", "top"), `both (50+ all-kicker estimate)` = c("zero", "all"))
fit4 <- function(tr, v) list(xp = glm(as.formula(paste("xp_attempts ~", F_XP)), poisson, tr), a039 = glm(as.formula(paste("att_039 ~", F_039)), poisson, tr),
                            a4049 = glm(as.formula(paste("att_4049 ~", F4049[[v[1]]])), poisson, tr), a50 = glm(as.formula(paste("att_50 ~", F50[[v[2]]])), poisson, tr))
pred <- function(fits, te) te |> mutate(l_xp = predict(fits$xp, te, type = "response"), l039 = predict(fits$a039, te, type = "response"),
  l4049 = predict(fits$a4049, te, type = "response"), l50 = predict(fits$a50, te, type = "response"),
  proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp))
top <- vol |> filter(top16pre)
loso <- function(v) bind_rows(lapply(2023:2025, function(s) pred(fit4(top[top$season != s, ], v), top[top$season == s, ])))
res <- lapply(VERSIONS, loso)
hit <- function(d) { n <- 0; h <- 0
  for (g in split(d, list(d$season, d$week), drop = TRUE)) { if (nrow(g) < 2) next
    dp <- outer(g$proj, g$proj, "-"); da <- outer(g$fpts, g$fpts, "-"); ok <- upper.tri(da) & da != 0
    n <- n + sum(ok); h <- h + sum(ifelse(dp[ok] == 0, 0.5, as.numeric(sign(dp[ok]) == sign(da[ok])))) }
  c(h = h, n = n) }
wk <- paste(res$current$season, res$current$week); wks <- unique(wk); widx <- split(seq_along(wk), wk)
hit_by_week <- function(d) t(sapply(wks, function(w) hit(d[widx[[w]], ])))
base <- res$current; hb <- hit_by_week(base)
tab <- bind_rows(lapply(names(VERSIONS), function(nm) { r <- res[[nm]]
  g4049 <- 1000 * (dev_i(base$att_4049, base$l4049) - dev_i(r$att_4049, r$l4049)); g50 <- 1000 * (dev_i(base$att_50, base$l50) - dev_i(r$att_50, r$l50))
  se_b <- (base$fpts - base$proj)^2; se_r <- (r$fpts - r$proj)^2; hr <- hit_by_week(r)
  bs <- replicate(2000, { pick <- sample(wks, replace = TRUE); i <- unlist(widx[pick], use.names = FALSE)
    c(mean(se_r[i]) - mean(se_b[i]), sum(hr[pick, "h"]) / sum(hr[pick, "n"]) - sum(hb[pick, "h"]) / sum(hb[pick, "n"])) })
  tibble(version = nm, gain_4049 = mean(g4049), seasons_4049 = sum(tapply(g4049, r$season, mean) > 0), gain_50 = mean(g50), seasons_50 = sum(tapply(g50, r$season, mean) > 0),
         gain_50_outdoor = mean(g50[r$is_enclosed == 0]), gain_4049_outdoor = mean(g4049[r$is_enclosed == 0]),
         mse = mean(se_r), mse_change = mean(se_r) - mean(se_b), mse_seasons_better = sum(tapply(se_b - se_r, r$season, mean) > 0), mse_share_not_better = mean(bs[1, ] >= 0),
         hit_rate = sum(hr[, "h"]) / sum(hr[, "n"]), hit_change = hit_rate - sum(hb[, "h"]) / sum(hb[, "n"]), hit_share_not_better = mean(bs[2, ] <= 0),
         mean_abs_move = mean(abs(r$proj - base$proj)), max_move = max(abs(r$proj - base$proj)))
}))
message("\nLeave-one-season-out, 832 pre-game top-16 team-games (gains: error x1000, positive = better than current)")
print(as.data.frame(tab |> mutate(across(where(is.double), ~ round(.x, 4)))), width = 260)
write_csv(tab, "t24_results.csv")
message("Pairs in hit rate: ", sum(hb[, "n"]))

# ---- 3. Who moves, and by how much (full-sample fits, week 4 2026 inputs as illustration) ---------
w4 <- read_csv("t5_week4_inputs.csv", show_col_types = FALSE) |> mutate(off_top = B50[["top16"]] * krate_40plus, off_all = B50[["all"]] * krate_40plus)
pc <- pred(fit4(top, VERSIONS$current), w4); pb <- pred(fit4(top, VERSIONS$`both (50+ top-16 estimate)`), w4); pa <- pred(fit4(top, VERSIONS$`both (50+ all-kicker estimate)`), w4)
ill <- tibble(kicker = pc$kicker_player_name, team = pc$posteam, dome = pc$is_enclosed, k40 = pc$krate_40plus, k4049 = pc$krate_4049,
              cur = pc$proj, both_top = pb$proj, change_top = pb$proj - pc$proj, change_all = pa$proj - pc$proj,
              d4049 = pb$l4049 - pc$l4049, d50 = pb$l50 - pc$l50) |> arrange(desc(change_top))
message("\nWeek 4 2026 illustration: projection change with both fixes (top-16 slope), largest gains and losses")
print(as.data.frame(bind_rows(head(ill, 8), tail(ill, 6)) |> mutate(across(where(is.double), ~ round(.x, 3)))), width = 200)
write_csv(ill, "t24_week4_illustration.csv")
message("Rank changes among 32 (current vs both): ", sum(rank(-pc$proj) != rank(-pb$proj)), " kickers change rank; largest rank move ", max(abs(rank(-pc$proj) - rank(-pb$proj))))
cf <- fit4(top, VERSIONS$`both (50+ top-16 estimate)`); message("Full-sample dome terms with pinned 50+ slope: "); print(round(coef(cf$a50), 3)); print(round(coef(cf$a4049), 3))

# ===================== PART 2: 2026 forward check and 50+-only illustration =====================
suppressMessages({library(dplyr); library(tidyr); library(readr)})
set.seed(20261005)
source("00_nflverse_data.R"); source("09_weekly_inputs.R"); source("08_points_distribution.R")
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
pbp <- bind_rows(lapply(2023:2026, function(y) readRDS(sprintf("data/raw/play_by_play_%d.rds", y)))); sched <- readRDS("data/raw/games.rds") |> filter(season %in% 2023:2026)
inp <- bind_rows(lapply(1:4, function(w) build_week_inputs(pbp, sched, 2026, w))) |> filter(!is.na(result))
lt <- readRDS("t23_tg_2026.rds") |> filter(season == 2026) |> select(game_id, posteam, att_4049, att_50, att_039, fpts, top16pre)
d <- inp |> inner_join(lt, by = c("game_id", "posteam"))
B50 <- c(top = 1.555, all = 1.307)   # 2016-2022 estimates from t24_pin_slopes.R
vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE); top <- vol |> filter(top16pre) |> mutate(off_top = B50[["top"]] * krate_40plus, off_all = B50[["all"]] * krate_40plus)
d <- d |> mutate(off_top = B50[["top"]] * krate_40plus, off_all = B50[["all"]] * krate_40plus)
f <- function(o, rhs) glm(as.formula(paste(o, "~", rhs)), poisson, top)
m <- list(xp = f("xp_attempts", "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8 + coach_long_fg_rate"),
  a039 = f("att_039", "implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"),
  c4049 = f("att_4049", "is_enclosed + krate_4049 + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"),
  z4049 = f("att_4049", "is_enclosed + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"),
  c50 = f("att_50", "is_enclosed + krate_40plus + is_enclosed:krate_50"), t50 = f("att_50", "is_enclosed + is_enclosed:krate_50 + offset(off_top)"),
  a50 = f("att_50", "is_enclosed + is_enclosed:krate_50 + offset(off_all)"))
P <- lapply(m, function(x) predict(x, d, type = "response"))
pts <- function(l4049, l50) projected_points(P$xp, P$a039, l4049, l50, d$p_039, d$p_4049, d$p_50, d$p_xp)
boot <- function(g, sel) { g <- g[sel]; gm <- d$game_id[sel]; ug <- unique(gm); idx <- split(seq_along(g), gm)
  b <- replicate(2000, mean(g[unlist(idx[sample(ug, replace = TRUE)], use.names = FALSE)])); sprintf("%+.1f (%+.1f to %+.1f)", mean(g), quantile(b, .025), quantile(b, .975)) }
for (who in c("top16", "all")) { sel <- if (who == "top16") d$top16pre else rep(TRUE, nrow(d))
  cat("\n2026 weeks 1-4,", who, ":", sum(sel), "team-games\n")
  cat(" 50+ attempts gain x1000, pinned (top-16 est):", boot(1000 * (dev_i(d$att_50, P$c50) - dev_i(d$att_50, P$t50)), sel), "\n")
  cat(" 50+ attempts gain x1000, pinned (all est):   ", boot(1000 * (dev_i(d$att_50, P$c50) - dev_i(d$att_50, P$a50)), sel), "\n")
  cat(" 40-49 attempts gain x1000, outdoor zero:      ", boot(1000 * (dev_i(d$att_4049, P$c4049) - dev_i(d$att_4049, P$z4049)), sel), "\n")
  se <- function(p) (d$fpts - p)^2
  cat(" points squared error: current", round(mean(se(pts(P$c4049, P$c50))[sel]), 3), "| 50+ pinned (all)", round(mean(se(pts(P$c4049, P$a50))[sel]), 3),
      "| 40-49 zero", round(mean(se(pts(P$z4049, P$c50))[sel]), 3), "| both", round(mean(se(pts(P$z4049, P$a50))[sel]), 3), "\n") }
# 50+-only illustration for week 4 (all-kicker estimate)
w4 <- read_csv("t5_week4_inputs.csv", show_col_types = FALSE) |> mutate(off_all = 1.307 * krate_40plus, off_top = 1.555 * krate_40plus)
l <- lapply(m, function(x) predict(x, w4, type = "response"))
pp <- function(l4049, l50) projected_points(l$xp, l$a039, l4049, l50, w4$p_039, w4$p_4049, w4$p_50, w4$p_xp)
ill <- tibble(kicker = w4$kicker_player_name, dome = w4$is_enclosed, k40 = round(w4$krate_40plus, 3), cur = pp(l$c4049, l$c50), pin50 = pp(l$c4049, l$a50)) |>
  mutate(change = pin50 - cur, rank_cur = rank(-cur), rank_new = rank(-pin50)) |> arrange(desc(change))
print(as.data.frame(bind_rows(head(ill, 6), tail(ill, 6)) |> mutate(across(where(is.double), ~ round(.x, 2)))))
cat("50+-only pin: mean |change|", round(mean(abs(ill$change)), 3), " max", round(max(abs(ill$change)), 3), " kickers changing rank:", sum(ill$rank_cur != ill$rank_new), " max rank move", max(abs(ill$rank_cur - ill$rank_new)), "\n")
write_csv(ill, "t24_week4_pin50_only.csv")
