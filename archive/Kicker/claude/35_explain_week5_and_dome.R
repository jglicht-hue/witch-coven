# #35 Why the two models differ for Reichard and Fairbairn in week 5, and where dome enters each model (2026-10-06). Descriptive; workspace only.
# No production script or model is changed. Log: claude/35_week5_explained_and_dome_log.md. Needs the #31/#33 workspace (t33_week5.R = second part of claude/32_interactions_and_week5.R).

# ===================== PART 1: t35_explain.R =====================
# #35 (2026-10-06): why the two models differ for Reichard and Fairbairn in week 5, and where dome enters each model. Descriptive; workspace only.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
s33 <- readLines("t33_week5.R"); eval(parse(text = s33[1:(grep("^S <- 2026; spec <- ", s33) - 1)]))
D0 <- D; S <- 2026; spec <- mk("shift", "shift", "shift")
newp <- function(Dm) { D <<- Dm; rm(list = ls(cache), envir = cache); L <- attempts2(S, spec); L$att_039 <- count039(S); te <- D[D$season == S, ]
  out <- te |> transmute(posteam, xp = xp_skel(S), a039 = L$att_039, a4049 = L$att_4049, a50 = L$att_50, proj = projected_points(xp, a039, a4049, a50, p_039, p_4049, p_50, p_xp)); D <<- D0; out }
base <- newp(D0); wk <- D0$season == 2026; mm <- function(v) mean(D0[[v]][wk])
cat("=== New model, week 5: attempts range across the 30 kickers ===\n"); print(round(sapply(base[-1], function(x) c(min = min(x), mean = mean(x), max = max(x))), 2))
# 2026-fold weights
kM <- kick2(2026, "M", LONGDC, "shift"); kL <- kick2(2026, "L", LONGDC, "shift")
cat("\n40-49 kick-or-go (4th downs at opp 22-31), fit 2016-2025, n =", kM$n, ": team weights", paste(names(kM$coef), round(kM$coef, 3), collapse = ", "), "| situation", paste(names(kM$sit), round(kM$sit, 3), collapse = ", "), "| score slope", round(kM$slope, 3), "\n")
cat("50+ kick-or-go (4th downs at opp 32-41), n =", kL$n, ": team weights", paste(names(kL$coef), round(kL$coef, 3), collapse = ", "), "| situation", paste(names(kL$sit), round(kL$sit, 3), collapse = ", "), "| score slope", round(kL$slope, 3), "\n")
tr <- D0[D0$season < 2026 & D0$top, ]; tr$fs <- droplevels(tr$fs)
f039 <- glm(att_039 ~ implied_team_total + I(implied_team_total^2) + exp_margin + fs, poisson, tr); fxp <- glm(xp_attempts ~ implied_team_total + fs, poisson, tr)
cat("0-39 count model weights:", paste(names(coef(f039))[2:4], signif(coef(f039)[2:4], 3), collapse = ", "), "| XP:", signif(coef(fxp)[2], 3), "\n")
cat("0-39: effect of expected margin +7 vs 0: x", round(exp(7 * coef(f039)[["exp_margin"]]), 3), "\n")
cf <- function(tm, lab, f) { Dm <- D0; i <- which(Dm$season == 2026 & Dm$posteam == tm); Dm[i, ] <- f(Dm[i, ]); r <- newp(Dm); r <- r[r$posteam == tm, ]; b <- base[base$posteam == tm, ]
  tibble(team = tm, change = lab, xp = r$xp, a039 = r$a039, a4049 = r$a4049, a50 = r$a50, proj = r$proj, proj_minus_actual_inputs = r$proj - b$proj) }
CF <- function(tm) bind_rows(cf(tm, "as is", identity), cf(tm, "dome flipped", function(r) { r$is_enclosed <- 1 - r$is_enclosed; r }), cf(tm, "kicker 40+ accuracy at week average", function(r) { r$krate_40plus <- mm("krate_40plus"); r }),
  cf(tm, "coach long-range FG rate at week average", function(r) { r$coach_long_fg_rate <- mm("coach_long_fg_rate"); r }), cf(tm, "expected margin 0 (implied total kept)", function(r) { r$exp_margin <- 0; r }),
  cf(tm, "implied total at week average (margin kept)", function(r) { r$implied_team_total <- mm("implied_team_total"); r }),
  cf(tm, "make chances at week average", function(r) { for (v in c("p_039", "p_4049", "p_50", "p_xp")) r[[v]] <- mm(v); r }))
cat("\n=== New model: one input changed at a time ===\n"); nw <- bind_rows(CF("MIN"), CF("HOU")); print(as.data.frame(nw |> mutate(across(where(is.double), ~ round(.x, 3)))), row.names = FALSE)
# ---- current production model, same counterfactuals ----
inp <- readRDS("../build/wk5/inputs_wk5.rds") |> filter(!is.na(kicker_player_id)); mo <- lapply(c(xp = "xp_attempts", a039 = "att_039", a4049 = "att_4049", a50 = "att_50"), function(y) readRDS(sprintf("../build/wk5/models/volume_%s_model.rds", y)))
oldp <- function(d) { l <- lapply(mo, function(m) as.numeric(predict(m, d, type = "response"))); tibble(posteam = d$posteam, xp = l$xp, a039 = l$a039, a4049 = l$a4049, a50 = l$a50, proj = projected_points(l$xp, l$a039, l$a4049, l$a50, d$p_039, d$p_4049, d$p_50, d$p_xp)) }
ob <- oldp(inp); file <- read_csv("../build/wk5/data/weekly_projections_latest.csv", show_col_types = FALSE); chk <- inner_join(ob, file, by = c("posteam" = "team"))
cat("\ncurrent model rebuilt here vs the production file: max |projection diff|", signif(max(abs(chk$proj - chk$projected_points)), 2), "\n")
cat("=== Current model, week 5: attempts range across the 30 kickers ===\n"); print(round(sapply(ob[-1], function(x) c(min = min(x), mean = mean(x), max = max(x))), 2))
im <- function(v) mean(inp[[v]])
cfo <- function(tm, lab, f) { d <- inp; i <- which(d$posteam == tm); d[i, ] <- f(d[i, ]); r <- oldp(d)[i, ]; b <- ob[i, ]; tibble(team = tm, change = lab, xp = r$xp, a039 = r$a039, a4049 = r$a4049, a50 = r$a50, proj = r$proj, proj_minus_actual_inputs = r$proj - b$proj) }
CFO <- function(tm) bind_rows(cfo(tm, "as is", identity), cfo(tm, "dome flipped", function(r) { r$is_enclosed <- 1 - r$is_enclosed; r }),
  cfo(tm, "kicker range accuracy (40-49, 50+, 40+) at week average", function(r) { for (v in c("krate_4049", "krate_50", "krate_40plus")) r[[v]] <- im(v); r }),
  cfo(tm, "  of which 40-49 accuracy only", function(r) { r$krate_4049 <- im("krate_4049"); r }),
  cfo(tm, "coach long-range FG rate at week average", function(r) { r$coach_long_fg_rate <- im("coach_long_fg_rate"); r }),
  cfo(tm, "implied total at week average", function(r) { r$implied_team_total <- im("implied_team_total"); r }),
  cfo(tm, "red-zone inputs at week average", function(r) { for (v in c("redzone_td_rate_trail8", "redzone_trips_per_game_trail8", "opp_redzone_td_rate_allowed_trail8")) r[[v]] <- im(v); r }),
  cfo(tm, "kicker's share of attempts from 40-49 at week average", function(r) { r$kshare_4049_hlall <- im("kshare_4049_hlall"); r }),
  cfo(tm, "make chances at week average", function(r) { for (v in c("p_039", "p_4049", "p_50", "p_xp")) r[[v]] <- im(v); r }))
cat("\n=== Current model: one input changed at a time ===\n"); od <- bind_rows(CFO("MIN"), CFO("HOU")); print(as.data.frame(od |> mutate(across(where(is.double), ~ round(.x, 3)))), row.names = FALSE)
# points per attempt for each kicker
for (tm in c("MIN", "HOU")) { r <- inp[inp$posteam == tm, ]; cat(tm, "points per attempt: XP", round(r$p_xp, 3), "| 0-39", round(4 * r$p_039 - 1, 2), "| 40-49", round(5 * r$p_4049 - 1, 2), "| 50+", round(6 * r$p_50 - 1, 2), "\n") }
# ---- dome in the history ----
r29 <- readRDS("t29_results.rds")$R; r4 <- readRDS("t31_round4.rds"); V <- list(`current version` = r29$current_recipe, `new model (final 31)` = r4$FM[[1]])
dm <- D0 |> filter(season <= 2025) |> select(game_id, posteam, is_enclosed, krate_4049, krate_40plus)
cat("\n=== Walk-forward test 2019-2025 (top-16 team-games): actual vs predicted per game, dome vs outdoors ===\n")
for (k in names(V)) { v <- V[[k]] |> left_join(dm, by = c("game_id", "posteam")); cat(k, "\n")
  print(as.data.frame(v |> group_by(dome = is_enclosed) |> summarise(n = n(), xp_act = mean(xp_attempts), xp_pred = mean(l_xp), a039_act = mean(att_039), a039_pred = mean(l039), a4049_act = mean(att_4049), a4049_pred = mean(l4049), a50_act = mean(att_50), a50_pred = mean(l50), pts_act = mean(fpts), pts_pred = mean(proj)) |> mutate(across(where(is.double), ~ round(.x, 3))))) }
cat("\n=== Dome kickers by thirds of 40-49 accuracy: actual 40-49 attempts per game (top-16 team-games), and what each model predicted (2019-2025) ===\n")
tp <- D0 |> filter(season <= 2025, top, is_enclosed == 1); tp$acc3 <- cut(tp$krate_4049, quantile(tp$krate_4049, 0:3 / 3), include.lowest = TRUE, labels = c("low", "mid", "high")); tp$era <- ifelse(tp$season <= 2022, "2016-2022", "2023-2025")
print(as.data.frame(tp |> group_by(era, acc3) |> summarise(n = n(), acc = mean(krate_4049), att_4049 = mean(att_4049), att_50 = mean(att_50), .groups = "drop") |> mutate(across(where(is.double), ~ round(.x, 3)))))
cat("accuracy cut points:", round(quantile(tp$krate_4049, 0:3 / 3), 3), "\n")
for (k in names(V)) { v <- V[[k]] |> inner_join(tp |> select(game_id, posteam, acc3), by = c("game_id", "posteam")); cat(k, ":\n"); print(as.data.frame(v |> group_by(acc3) |> summarise(n = n(), a4049_act = mean(att_4049), a4049_pred = mean(l4049), a50_act = mean(att_50), a50_pred = mean(l50), pts_act = mean(fpts), pts_pred = mean(proj)) |> mutate(across(where(is.double), ~ round(.x, 3))))) }
cat("\n=== 4th downs 2016-2025: share kicked, dome vs outdoors ===\n"); pl <- plays |> left_join(dm |> select(game_id, posteam, de = is_enclosed), by = c("game_id", "posteam"))
print(as.data.frame(pl |> filter(!is.na(de)) |> group_by(zone, dome = de) |> summarise(n = n(), kicked = round(mean(kicked), 3), .groups = "drop")))
cat("all team-games 2016-2025, per game: \n"); print(as.data.frame(D0 |> filter(season <= 2025) |> group_by(dome = is_enclosed) |> summarise(n = n(), n4_M = mean(n4_M), n4_L = mean(n4_L), att_4049 = mean(att_4049), att_50 = mean(att_50), att_039 = mean(att_039), xp = mean(xp_attempts)) |> mutate(across(where(is.double), ~ round(.x, 3)))))
saveRDS(list(nw = nw, od = od, base = base, ob = ob), "t35_explain.rds")

# ===================== PART 2: t35b.R (dome vs outdoors miss; the two kickers' attempt history) =====================
suppressMessages({library(dplyr); library(tidyr); library(readr)})
source("08_points_distribution.R")
D0 <- readRDS("t31_D.rds"); r29 <- readRDS("t29_results.rds")$R; r4 <- readRDS("t31_round4.rds"); V <- list(`current version` = r29$current_recipe, `new model` = r4$FM[[1]])
dm <- D0 |> select(game_id, posteam, is_enclosed, p_039, p_4049, p_50, p_xp, kicker_player_name)
set.seed(1)
for (k in names(V)) { v <- V[[k]] |> left_join(dm, by = c("game_id", "posteam")) |> mutate(res = fpts - proj,
    given_att = xp_attempts * p_xp + att_039 * (4 * p_039 - 1) + att_4049 * (5 * p_4049 - 1) + att_50 * (6 * p_50 - 1),   # points expected from the attempts he actually got, at his make chances
    from_att = given_att - proj, from_makes = fpts - given_att)
  cat("\n==", k, "== (actual minus predicted points; split into attempts part and makes part)\n")
  print(as.data.frame(v |> group_by(dome = is_enclosed) |> summarise(n = n(), actual = mean(fpts), predicted = mean(proj), miss = mean(res), from_attempts = mean(from_att), from_makes = mean(from_makes)) |> mutate(across(where(is.double), ~ round(.x, 3)))))
  cat("dome minus outdoors: actual", round(mean(v$fpts[v$is_enclosed == 1]) - mean(v$fpts[v$is_enclosed == 0]), 2), " predicted", round(mean(v$proj[v$is_enclosed == 1]) - mean(v$proj[v$is_enclosed == 0]), 2), "\n")
  wk <- paste(v$season, v$week); uw <- unique(wk); gap <- function(d) mean(d$res[d$is_enclosed == 1]) - mean(d$res[d$is_enclosed == 0])
  idx <- split(seq_len(nrow(v)), wk); b <- replicate(2000, { s <- sample(uw, replace = TRUE); gap(v[unlist(idx[s]), ]) })
  cat("gap in the miss (dome minus outdoors):", round(gap(v), 3), " 95% range", round(quantile(b, c(.025, .975)), 2), " share of resamples > 0:", mean(b > 0), "\n")
  cat("by season:", paste(sapply(sort(unique(v$season)), function(s) paste0(s, " ", round(gap(v[v$season == s, ]), 2))), collapse = " | "), "\n")
  mk <- function(d) mean(d$from_makes[d$is_enclosed == 1]) - mean(d$from_makes[d$is_enclosed == 0]); cat("makes part of the gap:", round(mk(v), 3), " by season:", paste(sapply(sort(unique(v$season)), function(s) round(mk(v[v$season == s, ]), 2)), collapse = " "), "\n") }
# actual per-game attempts for the two kickers
tg <- readRDS("t25_tg.rds"); d26 <- readRDS("../t30/d2026.rds")
cat("\nnames tg:", paste(head(names(tg), 40), collapse = ","), "\n")
for (nm in c("W.Reichard", "K.Fairbairn")) { a <- D0 |> filter(kicker_player_name == nm, season >= 2023) |> select(season, week, is_enclosed, xp_attempts, att_039, att_4049, att_50, fpts)
  b <- if (all(c("kicker_player_name", "att_4049") %in% names(d26))) d26 |> filter(kicker_player_name == nm) |> transmute(season = 2026L, week, is_enclosed, xp_attempts, att_039, att_4049, att_50, fpts = if ("fpts" %in% names(d26)) fpts else NA_real_) else NULL
  x <- bind_rows(a, b); cat("\n", nm, ": per game by season\n"); print(as.data.frame(x |> group_by(season) |> summarise(games = n(), dome_share = mean(is_enclosed), xp = mean(xp_attempts), a039 = mean(att_039), a4049 = mean(att_4049), a50 = mean(att_50), pts = mean(fpts)) |> mutate(across(where(is.double), ~ round(.x, 2)))))
  cat("all games since 2024, dome vs outdoors:\n"); print(as.data.frame(x |> filter(season >= 2024) |> group_by(dome = is_enclosed) |> summarise(games = n(), xp = mean(xp_attempts), a039 = mean(att_039), a4049 = mean(att_4049), a50 = mean(att_50), pts = mean(fpts)) |> mutate(across(where(is.double), ~ round(.x, 2))))) }
# who are the 2023-25 dome kickers in the high third of 40-49 accuracy?
tp <- D0 |> filter(season <= 2025, top, is_enclosed == 1); cut <- quantile(tp$krate_4049, 2/3)
cat("\n2023-25 dome top-16 games with 40-49 accuracy above", round(cut, 3), ":\n"); print(as.data.frame(tp |> filter(season >= 2023, krate_4049 > cut) |> group_by(kicker_player_name) |> summarise(games = n(), a4049 = round(mean(att_4049), 2), a50 = round(mean(att_50), 2)) |> arrange(desc(games))))
