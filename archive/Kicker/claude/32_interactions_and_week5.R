# #32 Interactions and offense-quality controls on top of #31's final version, and #33 this week's projections old vs new (2026-10-06).
# One-off tests in the Kicker Wizerd chat; no production script or model was changed. See claude/32_interactions_and_week5_log.md.
# Parts were separate files in the session (t32_test.R, t32_half.R, t33_week5.R) and reuse #31's functions by reading t31_round4.R.

# ======================= t32_test.R =======================
# #32 (2026-10-06): interactions and offense-quality controls, tested on top of #31's final version. Signs stated before running (see log).
suppressMessages({library(dplyr); library(tidyr); library(readr)})
src <- readLines("t31_round4.R"); eval(parse(text = src[1:(grep("^MV <- ", src) - 1)]))
r4 <- readRDS("t31_round4.rds"); final31 <- r4$FM[[1]]; set.seed(20261006)
fix <- function(x) recode(x, OAK = "LV", SD = "LAC", STL = "LA", .default = x)
# offense strength apart from the opponent: points scored per game over the team's last 8 games; and points the opponent allowed over its last 8
g <- readRDS("data/raw/games.rds") |> filter(season >= 2014, season <= 2025, !is.na(result)) |> mutate(home_team = fix(home_team), away_team = fix(away_team))
tg <- bind_rows(g |> transmute(game_id, gameday, team = home_team, pf = home_score, pa = away_score), g |> transmute(game_id, gameday, team = away_team, pf = away_score, pa = home_score)) |> arrange(team, gameday) |>
  group_by(team) |> mutate(ppg8 = sapply(seq_along(pf), function(i) if (i > 1) mean(pf[max(1, i - 8):(i - 1)]) else NA_real_), pa8 = sapply(seq_along(pa), function(i) if (i > 1) mean(pa[max(1, i - 8):(i - 1)]) else NA_real_)) |> ungroup()
D <- D |> left_join(tg |> select(game_id, posteam = team, own_ppg8 = ppg8), by = c("game_id", "posteam")) |> left_join(tg |> select(game_id, opponent = team, opp_pa8 = pa8), by = c("game_id", "opponent")) |>
  mutate(rz_stalls = redzone_trips_per_game_trail8 * (1 - redzone_td_rate_trail8), rz_tds = redzone_trips_per_game_trail8 * redzone_td_rate_trail8)
stopifnot(!anyNA(D$own_ppg8), !anyNA(D$opp_pa8))
plays <- plays |> left_join(D |> select(game_id, posteam, own_ppg8, opp_pa8), by = c("game_id", "posteam"))
cat("correlations (all team-games): implied total with own points per game", round(cor(D$implied_team_total, D$own_ppg8), 2), ", with opponent points allowed", round(cor(D$implied_team_total, D$opp_pa8), 2),
    "; own red-zone TD rate with own points per game", round(cor(D$redzone_td_rate_trail8, D$own_ppg8), 2), "\n")
# generic count model on top-16 rows (weights from all earlier seasons, level from the last 3)
cnt <- function(S, y, rhs) memo(paste("cnt", S, y, rhs), { tr <- D[D$season < S & D$top, ]; tr$fs <- droplevels(tr$fs); ref <- levels(tr$fs)[nlevels(tr$fs)]
  f <- glm(as.formula(paste(y, "~", rhs, "+ fs")), poisson, tr); sr <- function(d) { d$fs <- factor(ref, levels = levels(tr$fs)); d }
  cal <- D[D$season < S & D$season >= S - 3 & D$top, ]; te <- D[D$season == S, ]
  mu <- exp(as.numeric(predict(f, sr(te), type = "link")) + log(sum(cal[[y]]) / sum(exp(predict(f, sr(cal), type = "link")))))
  list(mu = mu, coef = coef(f)[!grepl("^fs|Intercept", names(coef(f)))], oos = dev_i(te[[y]][te$top], mu[te$top])) })
B039 <- "implied_team_total + I(implied_team_total^2) + exp_margin"; BXP <- "implied_team_total"
build <- function(rhs039 = B039, rhsxp = BXP, kcS = NULL) bind_rows(lapply(SCORED, function(S) { spec <- mk("shift", "shift", "shift", kc = c(S = if (is.null(kcS)) BASE$kc[["S"]] else kcS, M = LONGDC, L = LONGDC))
  L <- attempts2(S, spec); if (is.null(kcS)) L$att_039 <- cnt(S, "att_039", rhs039)$mu; te <- D[D$season == S, ]
  te |> transmute(season, week, game_id, posteam, top, fpts, xp_attempts, att_039, att_4049, att_50, l_xp = cnt(S, "xp_attempts", rhsxp)$mu, l039 = L$att_039, l4049 = L$att_4049, l50 = L$att_50,
                  proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp)) })) |> filter(top)
base <- build(); stopifnot(max(abs(base$proj - final31$proj)) < 1e-9)
decS <- build(kcS = BASE$kc[["S"]])   # short range from the kick-or-go model with score shift (#31's structure C)
TERMS <- list(
  list("0-39: implied total x expected margin", "att_039", paste(B039, "+ implied_team_total:exp_margin"), "implied_team_total:exp_margin", 0),
  list("0-39: own points per game, last 8", "att_039", paste(B039, "+ own_ppg8"), "own_ppg8", 0),
  list("0-39: own points per game and opponent points allowed (in place of nothing; both added)", "att_039", paste(B039, "+ own_ppg8 + opp_pa8"), "own_ppg8", 0),
  list("0-39: stalled red-zone trips per game (trips x (1 - TD rate))", "att_039", paste(B039, "+ rz_stalls"), "rz_stalls", 1),
  list("0-39: own red-zone TD rate and its interaction with implied total", "att_039", paste(B039, "+ redzone_td_rate_trail8 + implied_team_total:redzone_td_rate_trail8"), "implied_team_total:redzone_td_rate_trail8", -1),
  list("0-39: opp red-zone TD rate allowed and its interaction with implied total", "att_039", paste(B039, "+ opp_redzone_td_rate_allowed_trail8 + implied_team_total:opp_redzone_td_rate_allowed_trail8"), "implied_team_total:opp_redzone_td_rate_allowed_trail8", -1),
  list("0-39: own red-zone TD rate and its interaction with own points per game", "att_039", paste(B039, "+ own_ppg8 + redzone_td_rate_trail8 + own_ppg8:redzone_td_rate_trail8"), "own_ppg8:redzone_td_rate_trail8", -1),
  list("XP: red-zone TDs per game (trips x TD rate)", "xp_attempts", paste(BXP, "+ rz_tds"), "rz_tds", 1),
  list("XP: own red-zone TD rate and its interaction with implied total", "xp_attempts", paste(BXP, "+ redzone_td_rate_trail8 + implied_team_total:redzone_td_rate_trail8"), "implied_team_total:redzone_td_rate_trail8", 1),
  list("XP: own points per game, last 8", "xp_attempts", paste(BXP, "+ own_ppg8"), "own_ppg8", 1),
  list("XP: expected margin", "xp_attempts", paste(BXP, "+ exp_margin"), "exp_margin", 0))
lcol <- c(xp_attempts = "l_xp", att_039 = "l039")
row1 <- function(tm) { nm <- tm[[1]]; y <- tm[[2]]; rhs <- tm[[3]]; v <- tm[[4]]; sg <- tm[[5]]; b0 <- if (y == "att_039") B039 else BXP
  r <- if (y == "att_039") build(rhs039 = rhs) else build(rhsxp = rhs); co <- sapply(SCORED, function(S) cnt(S, y, rhs)$coef[[v]])
  g <- lapply(SCORED, function(S) cnt(S, y, b0)$oos - cnt(S, y, rhs)$oos); gs <- sapply(g, mean); cc <- cmp(r, base, nm, "final 31")
  sign_ok <- if (sg == 0) (all(co > 0) || all(co < 0)) else all(sign(co) == sg); h1 <- 1000 * mean(unlist(g[SCORED <= 2021])); h2 <- 1000 * mean(unlist(g[SCORED >= 2022]))
  tibble(term = nm, weight_last_fold = co[length(co)], folds_same_or_right_sign = if (sg == 0) max(sum(co > 0), sum(co < 0)) else sum(sign(co) == sg), att_gain = 1000 * mean(unlist(g)), gain_2019_21 = h1, gain_2022_25 = h2, seasons_better = paste0(sum(gs > 0), "/7"),
         hit_change = cc$hit_change, hit_share = cc$hit_share, wcorr_change = cc$wcorr_change, wcorr_share = cc$wcorr_share, mse_change = cc$mse_change, mse_share = cc$mse_share, passes = sign_ok & h1 > 0 & h2 > 0 & cc$wcorr_change >= 0) }
BOOT <- NULL; tt <- bind_rows(lapply(TERMS, row1))
cat("\n=== Count-model terms on top of the final version (columns = effect of adding the term) ===\n"); show(tt)
# kick-or-go model for short kicks with offense-quality inputs: does it now beat the count model?
KS <- list(`short decision: expected margin + implied total (as #31)` = BASE$kc[["S"]], `short decision: + own points per game` = paste(BASE$kc[["S"]], "+ own_ppg8"),
           `short decision: own points per game in place of implied total` = "exp_margin + own_ppg8", `short decision: + own red-zone TD rate` = paste(BASE$kc[["S"]], "+ redzone_td_rate_trail8"),
           `short decision: + own points per game + opponent points allowed` = paste(BASE$kc[["S"]], "+ own_ppg8 + opp_pa8"))
RK <- lapply(KS, function(k) build(kcS = k))
cat("\n=== Short-range kick-or-go model with offense-quality inputs (vs the final version, whose short kicks come from the count model) ===\n")
show(bind_rows(summ(base, "final 31 (count model for short kicks)"), lapply(names(RK), function(k) summ(RK[[k]], k))) |> select(version, hit, wcorr, mse, err_039))
show(bind_rows(lapply(names(RK), function(k) cmp(RK[[k]], base, k, "final 31"))) |> select(version, hit_change, hit_share, wcorr_change, wcorr_share, wcorr_seasons, mse_change, mse_share))
for (k in names(KS)[-1]) { co <- t(sapply(SCORED, function(S) kick2(S, "S", KS[[k]], "shift")$coef)); cat(k, "| weights by fold:\n"); print(round(co, 3)) }
ll <- sapply(KS, function(k) 1000 * mean(unlist(lapply(SCORED, function(S) kick2(S, "S", k, "shift")$oos)))); cat("short-range kick-or-go log loss x1000 on unseen seasons:\n"); print(round(ll, 2))
saveRDS(list(tt = tt, RK = RK, base = base), "t32_results.rds")

# ======================= t32_half.R =======================
suppressMessages({library(dplyr); library(tidyr); library(readr)})
src <- readLines("t32_test.R"); eval(parse(text = src[1:(grep("^TERMS <- list", src) - 1)]))
half <- function(a, b, la) bind_rows(lapply(list(2019:2021, 2022:2025), function(ss) { BOOT <<- NULL; cmp(a[a$season %in% ss, ], b[b$season %in% ss, ], la, "") })) |> mutate(half = c("2019-21", "2022-25")) |>
  select(version, half, hit_change, hit_share, wcorr_change, wcorr_share, mse_change, mse_share)
a5 <- build(rhs039 = paste(B039, "+ redzone_td_rate_trail8 + implied_team_total:redzone_td_rate_trail8")); a2 <- build(rhs039 = paste(B039, "+ own_ppg8")); a3 <- build(rhs039 = paste(B039, "+ own_ppg8 + opp_pa8"))
show(bind_rows(half(a5, base, "0-39 + own red-zone TD rate x implied total"), half(a2, base, "0-39 + own points per game"), half(a3, base, "0-39 + own points per game + opp points allowed")))
co <- t(sapply(SCORED, function(S) cnt(S, "att_039", paste(B039, "+ redzone_td_rate_trail8 + implied_team_total:redzone_td_rate_trail8"))$coef)); print(round(co, 4))
# what the interaction implies in the last fold: short attempts at implied total 20 vs 27, red-zone TD rate 45% vs 70% (margin 0)
f <- co[7, ]; lp <- function(it, rz) f[["implied_team_total"]] * it + f[["I(implied_team_total^2)"]] * it^2 + f[["redzone_td_rate_trail8"]] * rz + f[["implied_team_total:redzone_td_rate_trail8"]] * it * rz
cat("ratio of short attempts, red-zone TD rate 45% vs 70%: at implied total 20:", round(exp(lp(20, .45) - lp(20, .70)), 3), "; at 27:", round(exp(lp(27, .45) - lp(27, .70)), 3), "\n")

# ======================= t33_week5.R =======================
# #33 (2026-10-06): this week's projections from the current production model and from #31's final version, on the same inputs. Workspace only.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
src <- readLines("t31_round4.R"); eval(parse(text = src[1:(grep("^MV <- ", src) - 1)]))
old <- read_csv("../build/wk5/data/weekly_projections_latest.csv", show_col_types = FALSE)
inp <- readRDS("../build/wk5/inputs_wk5.rds") |> filter(!is.na(kicker_player_id))
j <- inner_join(inp, old, by = c("game_id", "posteam" = "team"), suffix = c("", ".old"))
cat("week-5 rows:", nrow(inp), "; matched to the production file:", nrow(j), "; same kicker:", all(j$kicker_player_id == j$kicker_player_id.old), "; max |implied total diff|", max(abs(j$implied_team_total - j$implied_team_total.old)),
    "; max |p_50 diff|", signif(max(abs(j$p_50 - j$p_50.old)), 2), "\n")
w5 <- inp |> mutate(season = 2026L, top = top16pre, fpts = NA_real_, xp_attempts = 0L, att_039 = 0L, att_4049 = 0L, att_50 = 0L, att_tot = 0L, att_40p = 0L, n4_S = 0L, n4_M = 0L, n4_L = 0L,
                    exp_margin = if_else(implied_imputed, 0, 2 * implied_team_total - total_line))
stopifnot(!anyNA(w5[c("exp_margin", "krate_40plus", "coach_long_fg_rate", "is_enclosed", "implied_team_total")]))
D <- bind_rows(D |> mutate(fs = as.character(fs)), w5 |> mutate(fs = "2026") |> select(all_of(names(D)))) |> mutate(fs = factor(fs))
S <- 2026; spec <- mk("shift", "shift", "shift"); L <- attempts2(S, spec); L$att_039 <- count039(S); te <- D[D$season == S, ]
new <- te |> transmute(game_id, posteam, new_xp = xp_skel(S), new_039 = L$att_039, new_4049 = L$att_4049, new_50 = L$att_50, exp_margin, new = projected_points(new_xp, new_039, new_4049, new_50, p_039, p_4049, p_50, p_xp),
                       kick_4049 = kick2(S, "M", LONGDC, "shift")$prop[D[D$season >= S - 3 & D$season <= S, ]$season == S], kick_50 = kick2(S, "L", LONGDC, "shift")$prop[D[D$season >= S - 3 & D$season <= S, ]$season == S])
cmp5 <- old |> transmute(game_id, posteam = team, opponent, kicker = kicker_player_name, top16pre, ppg_rank, dome = is_enclosed, roof_unknown, implied = implied_team_total, spread_line, total_line, old = projected_points, ci_low, ci_high,
                         old_xp = exp_xp_attempts, old_039 = exp_att_039, old_4049 = exp_att_4049, old_50 = exp_att_50, p_039, p_4049, p_50) |>
  inner_join(new, by = c("game_id", "posteam")) |> mutate(change = new - old, rank_old = rank(-old), rank_new = rank(-new),
    d_xp = (new_xp - old_xp) * 0.95, d_039 = (new_039 - old_039) * (4 * p_039 - 1), d_4049 = (new_4049 - old_4049) * (5 * p_4049 - 1), d_50 = (new_50 - old_50) * (6 * p_50 - 1)) |> arrange(rank_new)
cat("mean |change|", round(mean(abs(cmp5$change)), 2), "; max", round(max(abs(cmp5$change)), 2), "; mean old", round(mean(cmp5$old), 2), " mean new", round(mean(cmp5$new), 2), "; correlation", round(cor(cmp5$old, cmp5$new), 3),
    "; rank changes of 3+ places:", sum(abs(cmp5$rank_old - cmp5$rank_new) >= 3), "of", nrow(cmp5), "; top-12 kept:", length(intersect(cmp5$posteam[cmp5$rank_old <= 12], cmp5$posteam[cmp5$rank_new <= 12])), "of 12\n")
cat("mean expected attempts old/new: XP", round(mean(cmp5$old_xp), 2), round(mean(cmp5$new_xp), 2), "| 0-39", round(mean(cmp5$old_039), 2), round(mean(cmp5$new_039), 2), "| 40-49", round(mean(cmp5$old_4049), 2), round(mean(cmp5$new_4049), 2), "| 50+", round(mean(cmp5$old_50), 2), round(mean(cmp5$new_50), 2), "\n")
print(as.data.frame(cmp5 |> transmute(rank_new, rank_old, kicker, team = posteam, opp = opponent, top16 = top16pre, dome = round(dome, 2), implied = round(implied, 1), margin = round(exp_margin, 1), old = round(old, 2), new = round(new, 2), change = round(change, 2),
                                    from_xp = round(d_xp, 2), from_039 = round(d_039, 2), from_4049 = round(d_4049, 2), from_50 = round(d_50, 2), kick_50 = round(kick_50, 2))), row.names = FALSE)
write_csv(cmp5, "t33_week5_comparison.csv")
