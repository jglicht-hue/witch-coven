# Diagnostic: do elite kickers' accuracy edges persist more than the rest? Added 2026-09-29.
# Not part of the weekly run; nothing in the pipeline depends on it. See claude/v1.1_14_fg_shrinkage_log.md.
# Part 1 (2016-2025 play-by-play): make-over-expected per kicker-season (expected = league make chance at
#   that distance and season, from a logistic fit), season-to-season persistence, and prior-2-seasons
#   quintiles -> next season.
# Part 2 (data/fg_shrink_inputs.rds from 14_fg_shrinkage_experiments.R): kicker-games grouped by their
#   pre-game decayed record (top 20% / middle / bottom 20% / short record), next-game edge over league,
#   Brier by weight per group, and pairwise hit rate within the pre-game top 16 by weight.
suppressMessages({library(dplyr)})
source("00_nflverse_data.R")
fg <- bind_rows(lapply(2016:2025, function(s) load_pbp_data(s) |>
  filter(field_goal_attempt == 1, season_type == "REG", !is.na(kicker_player_id)) |>
  transmute(season, kicker_player_id, kicker_player_name, dist = kick_distance, made = as.integer(field_goal_result == "made"))))
m <- glm(made ~ poly(dist, 3) + factor(season), binomial, fg)
fg$exp <- fitted(m)
ks <- fg |> group_by(kicker_player_id, season) |> summarise(name = last(kicker_player_name), n = n(), mk = sum(made), ex = sum(exp), .groups = "drop") |>
  mutate(oe = (mk - ex) / n)
saveRDS(list(fg = fg, ks = ks), "data/elite_kicker_seasons.rds")
cat("attempts:", nrow(fg), " kicker-seasons:", nrow(ks), "\n")

# A. Season-to-season persistence (>= 15 attempts both seasons)
pp <- ks |> inner_join(ks |> mutate(season = season - 1), by = c("kicker_player_id", "season"), suffix = c("", "_next")) |>
  filter(n >= 15, n_next >= 15)
cat("A. pairs:", nrow(pp), " corr(oe_t, oe_t+1):", round(cor(pp$oe, pp$oe_next), 3), "\n")
# Reliability: observed variance vs binomial noise
q <- ks |> filter(n >= 15); noise <- mean(with(fg |> semi_join(q, by = c("kicker_player_id","season")) |> group_by(kicker_player_id, season) |> summarise(v = sum(exp*(1-exp))/n()^2, .groups="drop"), v))
cat("   var observed:", signif(var(q$oe),3), " binomial noise:", signif(noise,3), " true-skill SD:", round(sqrt(max(0, var(q$oe) - noise)), 4), "\n")

# B. Prior 2 seasons pooled -> next season, by prior quintile (kickers with >= 30 prior attempts, >= 10 next)
prior <- lapply(2018:2025, function(t) ks |> filter(season %in% c(t-2, t-1)) |> group_by(kicker_player_id) |>
  summarise(pn = sum(n), pmk = sum(mk), pex = sum(ex), name = last(name), .groups = "drop") |> mutate(season = t)) |> bind_rows() |>
  mutate(poe = (pmk - pex) / pn) |> inner_join(ks |> select(kicker_player_id, season, n, mk, ex, oe), by = c("kicker_player_id", "season")) |>
  filter(pn >= 30, n >= 10)
prior$bin <- ntile(prior$poe, 5)
b <- prior |> group_by(bin) |> summarise(kickers = n(), prior_oe_pct = round(100 * sum(pmk - pex) / sum(pn), 2),
  next_oe_pct = round(100 * sum(mk - ex) / sum(n), 2), .groups = "drop") |> mutate(retained = round(next_oe_pct / prior_oe_pct, 2))
cat("B. prior 2 seasons (>=30 att) -> next season, quintiles of prior make-over-expected (percentage points):\n"); print(as.data.frame(b))
fit_lin <- lm(oe ~ poe, prior, weights = n); fit_sp <- lm(oe ~ poe + I(pmax(poe - quantile(poe, .8), 0)), prior, weights = n)
cat("   linear slope:", round(coef(fit_lin)[2], 3), "  extra slope above 80th pct:", round(coef(fit_sp)[3], 3), " p =", signif(summary(fit_sp)$coef[3,4], 2), "\n")
# Top decile names
top <- prior |> filter(poe >= quantile(poe, .9)) |> summarise(prior = round(100*sum(pmk-pex)/sum(pn),2), nxt = round(100*sum(mk-ex)/sum(n),2), kicker_seasons = n())
cat("   top decile: kicker-seasons", top$kicker_seasons, " prior", top$prior, "pp  next", top$nxt, "pp\n")
print(prior |> filter(poe >= quantile(poe, .9)) |> transmute(season, name, prior_pp = round(100*poe,1), next_pp = round(100*oe,1), n) |> arrange(season) |> as.data.frame())

# ---- Part 2 ----
suppressMessages({library(dplyr)})
set.seed(2)
d <- readRDS("data/fg_shrink_inputs.rds"); PTS <- c("039","4049","50")
rate <- function(m, n, L, w) if (is.infinite(w)) L else ifelse(n + w > 0, (m + w * L) / (n + w), L)
W <- c(5, 10, 20, 35, 50, 100, Inf)
# Pre-game "edge": decayed makes over league expectation per decayed attempt, all ranges
d <- d |> mutate(hn = h_att_039 + h_att_4049 + h_att_50,
                 hedge = (h_mk_039 - h_att_039*lg_inc_039 + h_mk_4049 - h_att_4049*lg_inc_4049 + h_mk_50 - h_att_50*lg_inc_50) / pmax(hn, 1e-9),
                 gatt = g_att_039 + g_att_4049 + g_att_50,
                 gedge = g_mk_039 - g_att_039*lg_inc_039 + g_mk_4049 - g_att_4049*lg_inc_4049 + g_mk_50 - g_att_50*lg_inc_50)
est <- d |> filter(hn >= 15)
cut <- quantile(est$hedge, c(.2, .8))
d$grp <- case_when(d$hn < 15 ~ "short record (<15 decayed att)", d$hedge >= cut[2] ~ "top 20% by record", d$hedge <= cut[1] ~ "bottom 20% by record", TRUE ~ "middle 60%")
brier <- function(ix, w) { s <- 0; for (r in PTS) { p <- rate(d[[paste0("h_mk_",r)]][ix], d[[paste0("h_att_",r)]][ix], d[[paste0("lg_inc_",r)]][ix], w)
  s <- s + sum(d[[paste0("g_mk_",r)]][ix]*(1-p)^2 + (d[[paste0("g_att_",r)]][ix]-d[[paste0("g_mk_",r)]][ix])*p^2) }; 1000 * s / sum(d$gatt[ix]) }
out <- lapply(c(split(seq_len(nrow(d)), d$grp), list(`pre-game top 16` = which(d$top16pre), all = seq_len(nrow(d)))), function(ix)
  c(games = length(ix), fg_att = sum(d$gatt[ix]), prior_edge_pp = round(100*sum(d$hedge[ix]*d$hn[ix])/sum(d$hn[ix]),2),
    actual_edge_pp = round(100*sum(d$gedge[ix])/sum(d$gatt[ix]),2), sapply(W, function(w) round(brier(ix, w), 2))))
tab <- do.call(rbind, out); colnames(tab)[5:ncol(tab)] <- paste0("brier_w", W); print(tab)
# Bootstrap (by kicker) the actual edge of the top group
top <- d[d$grp == "top 20% by record", ]; ks <- unique(top$kicker_player_id)
bt <- replicate(2000, { s <- sample(ks, replace = TRUE); t <- bind_rows(lapply(s, function(k) top[top$kicker_player_id == k, ])); sum(t$gedge)/sum(t$gatt) })
cat("top 20% actual edge 90% range (kicker bootstrap):", round(100*quantile(bt, c(.05,.95)),2), "pp; kickers:", length(ks), "\n")
print(head(sort(table(top$kicker_player_name), decreasing = TRUE), 12))
# Pairwise hit rate within pre-game top 16 by w
pr <- function(w) with(d, lambda_xp*p_xp + lambda_039*(rate(h_mk_039,h_att_039,lg_inc_039,w)*4-1) + lambda_4049*(rate(h_mk_4049,h_att_4049,lg_inc_4049,w)*5-1) + lambda_50*(rate(h_mk_50,h_att_50,lg_inc_50,w)*6-1))
t16 <- which(d$top16pre); wk <- paste(d$season, d$week)[t16]
hit <- function(p, a, wk) { c1 <- 0; c2 <- 0; for (ix in split(seq_along(p), wk)) { dp <- outer(p[ix],p[ix],"-"); da <- outer(a[ix],a[ix],"-"); u <- upper.tri(dp) & da != 0
  c1 <- c1 + sum((sign(dp[u])==sign(da[u])) + 0.5*(dp[u]==0)); c2 <- c2 + sum(u) }; c1/c2 }
print(sapply(W, function(w) round(hit(pr(w)[t16], d$actual_points[t16], wk), 4)) |> setNames(paste0("w", W)))
pw <- function(p, a, wk) sapply(split(seq_along(p), wk), function(ix) { dp <- outer(p[ix],p[ix],"-"); da <- outer(a[ix],a[ix],"-"); u <- upper.tri(dp) & da != 0
  c(sum((sign(dp[u])==sign(da[u])) + 0.5*(dp[u]==0)), sum(u)) })
a5 <- pw(pr(5)[t16], d$actual_points[t16], wk); a35 <- pw(pr(35)[t16], d$actual_points[t16], wk)
dc <- a5[1,] - a35[1,]; np <- a5[2,]
bt <- replicate(2000, { i <- sample(length(dc), replace = TRUE); sum(dc[i])/sum(np[i]) })
seas <- tapply(dc, substr(names(dc),1,4), sum) / tapply(np, substr(names(dc),1,4), sum)
cat("top16: w5 minus w35 hit rate", round(sum(dc)/sum(np),4), " 90% range", round(quantile(bt, c(.05,.95)),4), " share w5 not better", mean(bt <= 0), " seasons w5 better", sum(seas > 0), "of 7\n")
