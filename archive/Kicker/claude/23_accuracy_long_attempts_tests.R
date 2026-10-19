# #23 Does long-range accuracy raise long attempts? (2026-10-05, Kicker Wizerd chat, one-off; no production changes)
# Log: claude/23_accuracy_long_attempts_log.md. Needs nflverse play-by-play 2011-2025 and games.rds in data/raw/,
# and data/volume_model_table.csv (only for the reproduction check). Part 1 builds the tables (30 s); part 2 runs the tests (3 min).

# ===================== PART 1: build =====================
# #23 Does long-range accuracy raise long attempts? Build step (2026-10-05).
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
  summarise(tot = n(), a40 = sum(long), m40 = sum(long & made), .groups = "drop") |> arrange(kicker_player_id, ord)
run_after <- function(x, hl) { d <- 0.5^(1 / hl); r <- 0; out <- numeric(length(x)); for (i in seq_along(x)) { r <- d * (r + x[i]); out[i] <- r }; out }
kg <- kg |> group_by(kicker_player_id) |> mutate(da12 = run_after(a40, 12), dm12 = run_after(m40, 12),
  da32 = run_after(a40, 32), dm32 = run_after(m40, 32), career_a40 = cumsum(a40)) |> ungroup()

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
s <- state_before(kg, c("da12", "dm12", "da32", "dm32", "career_a40"))
Ls <- L[as.character(tg$season)]
tg$acc12 <- (s[, "dm12"] + 5 * Ls) / (s[, "da12"] + 5) - Ls
tg$acc32 <- (s[, "dm32"] + 5 * Ls) / (s[, "da32"] + 5) - Ls
tg$prior_a40 <- s[, "career_a40"]; tg$lg40 <- Ls
# Pre-game top 16 (06b's rule) on the long table
pts <- tg |> select(kicker_player_id, ord, fpts) |> arrange(kicker_player_id, ord) |> group_by(kicker_player_id) |>
  mutate(d_pts = run_after(fpts, 12), d_g = run_after(rep(1, n()), 12)) |> ungroup()
sp <- state_before(pts, c("d_pts", "d_g")); lgp <- mean(tg$fpts)
tg$ppg_pre <- ifelse(sp[, 2] > 0, (sp[, 1] + 4 * lgp) / (sp[, 2] + 4), NA)
tg <- tg |> group_by(season, week) |> mutate(top16pre = !is.na(ppg_pre) & rank(-ppg_pre, ties.method = "first", na.last = "keep") <= 16) |>
  ungroup() |> mutate(top16pre = replace_na(top16pre, FALSE))
fourth <- fourth |> inner_join(tg |> select(game_id, posteam, dome, acc12, acc32, top16pre, kicker_player_id), by = c("game_id", "posteam"))
saveRDS(tg, "t23_tg.rds"); saveRDS(fourth, "t23_fourth.rds")
cat("team-games 2011-2025:", nrow(tg), "; 2016-2025:", sum(tg$season >= 2016), "; top16pre 2016-25:", sum(tg$season >= 2016 & tg$top16pre), "\n")
cat("4th downs in long FG range 2016-2025:", sum(fourth$season >= 2016), " kicked share", round(mean(fourth$kicked[fourth$season >= 2016]), 3), "\n")
print(round(L, 3))
print(tg |> filter(season >= 2016) |> group_by(season) |> summarise(att40 = mean(att_40p), dome = mean(dome), sd12 = sd(acc12), sd32 = sd(acc32)) |> as.data.frame() |> round(3))
# Check vs production table for 2023-25: att counts and kicker
v <- read_csv("data/volume_model_table.csv", show_col_types = FALSE) |> select(game_id, posteam, p4049 = att_4049, p50 = att_50, pk = kicker_player_id, pdome = is_enclosed, ptop = top16pre)
ck <- inner_join(tg, v, by = c("game_id", "posteam"))
cat("vs production (", nrow(ck), "rows): att mismatch", sum(ck$att_4049 != ck$p4049 | ck$att_50 != ck$p50), "; kicker mismatch", sum(ck$kicker_player_id != ck$pk),
    "; dome mismatch", sum(ck$dome != round(ck$pdome)), "; top16 agree", round(mean(ck$top16pre == ck$ptop), 3), "\n")

# ===================== PART 2: tests =====================
# #23 tests. Rules set before results (see log).
suppressMessages({library(dplyr); library(tidyr); library(readr); library(splines)})
set.seed(20261005)
tg <- readRDS("t23_tg.rds") |> filter(season >= 2016); fourth <- readRDS("t23_fourth.rds") |> filter(season >= 2016)
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))

# ---- 1. Raw: 40+ attempts per team-game by accuracy fifth x venue ------------------------
raw <- function(d, who, v) d |> group_by(season) |> mutate(fifth = ntile(.data[[v]], 5)) |> ungroup() |>
  group_by(venue = ifelse(dome == 1, "dome", "outdoors"), fifth) |>
  summarise(who = who, measure = v, n = n(), acc = mean(.data[[v]]), att40 = mean(att_40p), se = sd(att_40p) / sqrt(n()),
            att4049 = mean(att_4049), att50 = mean(att_50), .groups = "drop")
r1 <- bind_rows(raw(tg, "all", "acc12"), raw(tg |> filter(top16pre), "top16", "acc12"), raw(tg, "all", "acc32"), raw(tg |> filter(top16pre), "top16", "acc32"))
write_csv(r1, "t23_raw.csv")
message("1. RAW: 40+ attempts per team-game by accuracy fifth (within season), 2016-2025")
print(as.data.frame(r1 |> filter(measure == "acc12") |> mutate(across(where(is.double), ~ round(.x, 3)))), width = 200)
print(as.data.frame(r1 |> filter(measure == "acc32") |> mutate(across(where(is.double), ~ round(.x, 3)))), width = 200)

# ---- 2. Coach decisions on 4th down in long FG range -------------------------------------
fourth <- fourth |> mutate(sd_bin = cut(score_differential, c(-Inf, -9, -4, -1, 0, 3, 8, Inf)), late = as.integer(half_seconds_remaining < 120),
                           band = ifelse(yardline_100 <= 31, "40-49", "50-59"), ts = paste(posteam, season), outdoor = 1 - dome)
fit4 <- function(d, v) { d$a <- d[[v]] * 10  # per 10 percentage points
  glm(kicked ~ ns(yardline_100, 4) + log(ydstogo) + I(ydstogo <= 2) + sd_bin + factor(qtr) + late + ns(half_seconds_remaining, 3) +
        factor(season) + dome + a:outdoor + a:dome, binomial, d) }
boot4 <- function(d, v, B = 400) { ids <- unique(d$ts); idx <- split(seq_len(nrow(d)), d$ts)
  t(replicate(B, { s <- sample(ids, replace = TRUE); coef(fit4(d[unlist(idx[s], use.names = FALSE), ], v))[c("a:outdoor", "dome:a")] })) }
dec <- bind_rows(lapply(c("acc12", "acc32"), function(v) bind_rows(lapply(list(all = fourth, `40-49` = fourth[fourth$band == "40-49", ], `50-59` = fourth[fourth$band == "50-59", ],
                                                                               top16 = fourth[fourth$top16pre, ]), function(d) {
  f <- fit4(d, v); b <- boot4(d, v); co <- coef(f)[c("a:outdoor", "dome:a")]
  # average change in kick probability per +10 points of accuracy, outdoors
  d2 <- d[d$outdoor == 1, ]; d2$a <- d2[[v]] * 10; p0 <- predict(f, d2, type = "response"); d2$a <- d2$a + 1; p1 <- predict(f, d2, type = "response")
  tibble(n = nrow(d), kick_share = mean(d$kicked), venue = c("outdoors", "dome"), logodds_per10 = co, lo = apply(b, 2, quantile, 0.025, na.rm = TRUE),
         hi = apply(b, 2, quantile, 0.975, na.rm = TRUE), outdoor_prob_change_per10 = c(mean(p1 - p0), NA))
}), .id = "sample") |> mutate(measure = v)))
write_csv(dec, "t23_decisions.csv")
message("\n2. COACH DECISIONS: log-odds of kicking per +10 points of 40+ accuracy (95% range, team-season bootstrap)")
print(as.data.frame(dec |> mutate(across(where(is.double), ~ round(.x, 3)))), width = 200)
q4 <- fourth |> group_by(season) |> mutate(q = ntile(acc12, 4)) |> ungroup() |> group_by(venue = ifelse(dome == 1, "dome", "outdoors"), band, q) |>
  summarise(n = n(), acc = mean(acc12), kick_share = mean(kicked), .groups = "drop")
write_csv(q4, "t23_decisions_quartiles.csv")
print(as.data.frame(q4 |> mutate(across(where(is.double), ~ round(.x, 3)))))

# ---- 3. Prediction: walk-forward, fit on 3 prior seasons, score the next (2019-2025) -----
FORMS <- list(linear = "a", squared = "a + I(a^2)", top_end = "hinge")
wf <- function(d, outcome, v, form, shuffle = FALSE) {
  d$a <- d[[v]]
  if (shuffle) d <- d |> group_by(season) |> mutate(a = sample(a)) |> ungroup()
  bind_rows(lapply(2019:2025, function(s) {
    tr <- d[d$season %in% (s - 3):(s - 1), ]; te <- d[d$season == s, ]
    q <- quantile(tr$a, 0.75); tr$hinge <- pmax(tr$a - q, 0); te$hinge <- pmax(te$a - q, 0)
    rhs <- if (is.null(form)) "dome" else paste0("dome * (", form, ")")
    f <- glm(as.formula(paste(outcome, "~", rhs)), poisson, tr)
    tibble(season = s, dome = te$dome, game_id = te$game_id, dev = dev_i(te[[outcome]], predict(f, te, type = "response")))
  }))
}
run <- function(d, who, outcome, placebo_n) bind_rows(lapply(c("acc12", "acc32"), function(v) {
  base <- wf(d, outcome, v, NULL)
  bind_rows(lapply(names(FORMS), function(fn) {
    m <- wf(d, outcome, v, FORMS[[fn]]); g <- 1000 * (base$dev - m$dev)
    gain <- mean(g); ps <- NA
    if (placebo_n > 0 && gain > 0) ps <- mean(replicate(placebo_n, mean(1000 * (base$dev - wf(d, outcome, v, FORMS[[fn]], TRUE)$dev))) >= gain)
    tibble(who = who, outcome = outcome, measure = v, form = fn, n_scored = nrow(m), gain = gain,
           seasons_better = sum(tapply(g, m$season, mean) > 0), gain_outdoors = mean(g[m$dome == 0]), gain_dome = mean(g[m$dome == 1]), placebo_share = ps)
  }))
}))
top <- tg |> filter(top16pre)
t3 <- bind_rows(run(top, "top16", "att_40p", 1000), run(tg, "all", "att_40p", 1000),
                run(top, "top16", "att_4049", 0), run(top, "top16", "att_50", 0), run(tg, "all", "att_4049", 0), run(tg, "all", "att_50", 0))
t3 <- t3 |> mutate(passes = gain > 0 & seasons_better >= 5 & !is.na(placebo_share) & placebo_share < 0.05 / 6)
write_csv(t3, "t23_prediction.csv")
message("\n3. PREDICTION: walk-forward gain vs dome-only base (error x1000 per team-game)")
print(as.data.frame(t3 |> mutate(across(where(is.double), ~ round(.x, 3)))), width = 200)

# In-sample shape on all 10 seasons (descriptive): fitted 40+ attempts at accuracy percentiles
shape <- function(d, who) { d$a <- d$acc12
  f <- glm(att_40p ~ factor(season) + dome * (a + I(a^2)), poisson, d); fl <- glm(att_40p ~ factor(season) + dome * a, poisson, d)
  qs <- quantile(d$a, c(.1, .25, .5, .75, .9, .97)); nd <- expand.grid(a = qs, dome = 0:1, season = 2025)
  cbind(who = who, pct = rep(names(qs), 2), nd[, 1:2], squared = round(predict(f, nd, type = "response"), 3), linear = round(predict(fl, nd, type = "response"), 3)) }
message("\nIn-sample fitted 40+ attempts per game at accuracy percentiles (season fixed effects, 2025 level)")
sh <- rbind(shape(tg, "all"), shape(top, "top16")); print(sh, row.names = FALSE); write_csv(sh, "t23_shape.csv")
co <- function(d) { d$a <- d$acc12 * 10; f <- glm(att_40p ~ factor(season) + dome + a:I(1 - dome) + a:dome, poisson, d); round(summary(f)$coefficients[c("a:I(1 - dome)", "dome:a"), ], 4) }
message("\nIn-sample linear effect per +10 points of accuracy (log scale): all kickers, then top 16"); print(co(tg)); print(co(top))
