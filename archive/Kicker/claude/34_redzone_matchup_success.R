# #34 Red-zone matchup (offense vs defense) and success-rate terms on top of #31's final version (2026-10-06).
# Run in the Kicker Wizerd chat as a one-off. No production script or model is changed. Log: claude/34_redzone_matchup_success_log.md
# Three parts, run in order in a workspace holding #31/#32's scripts and data (t31_D.rds, t31_plays.rds, t31_round4.rds, t32_test.R = claude/32_interactions_and_week5.R):
#   PART 1 builds the features (Rscript part1 reg); PART 2 is the pre-stated test; PART 3 is the follow-up run after the results.

# ===================== PART 1: t34_build.R =====================
# #34 (2026-10-06): red-zone matchup and success-rate features, per team-game, trailing 8 and 16 games (crossing seasons).
suppressMessages({library(dplyr); library(tidyr)})
fix <- function(x) recode(x, OAK = "LV", SD = "LAC", STL = "LA", .default = x)
args <- commandArgs(TRUE); types <- if (length(args) && args[1] == "all") c("REG", "POST") else "REG"
per <- bind_rows(lapply(2012:2025, function(s) {
  p <- readRDS(sprintf("data/raw/play_by_play_%d.rds", s)) |> filter(season_type %in% types, !is.na(posteam), !is.na(defteam)) |>
    select(season, week, game_id, game_date, posteam, defteam, play_type, success, yardline_100, fixed_drive, fixed_drive_result, drive_inside20) |>
    mutate(posteam = fix(posteam), defteam = fix(defteam))
  pl <- p |> filter(play_type %in% c("pass", "run"), !is.na(success), !is.na(yardline_100)) |> group_by(season, week, game_id, game_date, posteam, defteam) |>
    summarise(n = n(), s = sum(success), rn = sum(yardline_100 <= 20), rs = sum(success[yardline_100 <= 20]), .groups = "drop")
  dr <- p |> filter(!is.na(fixed_drive)) |> group_by(game_id, posteam, fixed_drive) |> summarise(rz = any(drive_inside20 == 1, na.rm = TRUE), td = first(fixed_drive_result) == "Touchdown", .groups = "drop") |>
    filter(rz) |> group_by(game_id, posteam) |> summarise(trips = n(), tds = sum(td), .groups = "drop")
  pl |> left_join(dr, by = c("game_id", "posteam")) |> mutate(across(c(trips, tds), ~ coalesce(.x, 0L))) }))
tr <- function(x, w) { cs <- c(0, cumsum(x)); i <- seq_along(x); cs[i] - cs[pmax(1, i - w)] }   # sum over the previous w games (excluding this one)
roll <- function(d, key, pre) { d |> arrange(.data[[key]], game_date, game_id) |> group_by(.data[[key]]) |>
  mutate(across(c(n, s, rn, rs, trips, tds), list(`8` = ~ tr(.x, 8), `16` = ~ tr(.x, 16)), .names = "{.col}_{.fn}"), g_before = row_number() - 1L) |> ungroup() |>
  transmute(game_id, team = .data[[key]], g_before,
            !!paste0(pre, "sr8") := s_8 / n_8, !!paste0(pre, "sr16") := s_16 / n_16, !!paste0(pre, "rzsr8") := rs_8 / rn_8, !!paste0(pre, "rzsr16") := rs_16 / rn_16,
            !!paste0(pre, "rztd8") := tds_8 / trips_8, !!paste0(pre, "rztd16") := tds_16 / trips_16, !!paste0(pre, "rzn8") := rn_8, !!paste0(pre, "trips8") := trips_8) }
off <- roll(per, "posteam", "o_"); def <- roll(per, "defteam", "d_")
saveRDS(list(off = off, def = def, per = per), if (length(types) == 2) "t34_feat_all.rds" else "t34_feat_reg.rds")
D <- readRDS("t31_D.rds") |> left_join(off |> rename(posteam = team), by = c("game_id", "posteam")) |> left_join(def |> select(-g_before) |> rename(opponent = team), by = c("game_id", "opponent"))
cat("types:", types, "| rows", nrow(D), "| missing o_sr8", sum(is.na(D$o_sr8)), " d_sr8", sum(is.na(D$d_sr8)), "\n")
cat("rebuild vs production table: own RZ TD rate max |diff|", max(abs(D$o_rztd8 - D$redzone_td_rate_trail8), na.rm = TRUE), " share equal", mean(abs(D$o_rztd8 - D$redzone_td_rate_trail8) < 1e-9, na.rm = TRUE),
    "| opp allowed max |diff|", max(abs(D$d_rztd8 - D$opp_redzone_td_rate_allowed_trail8), na.rm = TRUE), " share equal", mean(abs(D$d_rztd8 - D$opp_redzone_td_rate_allowed_trail8) < 1e-9, na.rm = TRUE), "\n")
print(summary(D[c("o_sr8", "o_rzsr8", "o_rztd8", "d_sr8", "d_rzsr8", "d_rztd8", "o_rzn8", "o_trips8")]))

# ===================== PART 2: t34_test.R =====================
# #34 (2026-10-06): red-zone matchup (offense vs defense) and success-rate terms on top of #31's final version.
# Signs and pass rule were sent to the user before this was run (see log). No production script or model is changed.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
s32 <- readLines("t32_test.R"); eval(parse(text = s32[1:(grep("^# offense strength apart", s32) - 1)]))
F <- readRDS("t34_feat_reg.rds")
D <- D |> left_join(F$off |> select(-g_before) |> rename(posteam = team), by = c("game_id", "posteam")) |> left_join(F$def |> select(-g_before) |> rename(opponent = team), by = c("game_id", "opponent")) |>
  mutate(rztd_m8 = (o_rztd8 + d_rztd8) / 2, rztd_m16 = (o_rztd16 + d_rztd16) / 2, rzsr_m8 = (o_rzsr8 + d_rzsr8) / 2, rzsr_m16 = (o_rzsr16 + d_rzsr16) / 2, sr_m8 = (o_sr8 + d_sr8) / 2, sr_m16 = (o_sr16 + d_sr16) / 2)
stopifnot(max(abs(D$o_rztd8 - D$redzone_td_rate_trail8)) < 1e-12, max(abs(D$d_rztd8 - D$opp_redzone_td_rate_allowed_trail8)) < 1e-12, !anyNA(D[c("rztd_m8", "rztd_m16", "rzsr_m8", "rzsr_m16", "sr_m8", "sr_m16")]))
# ---- how steady is each measure? last 8 games vs the next 8 (this game and the following 7), same team ----
per <- F$per; fw <- function(x, w) { cs <- c(0, cumsum(x)); i <- seq_along(x); cs[pmin(length(x), i + w - 1) + 1] - cs[i] }; bw <- function(x, w) { cs <- c(0, cumsum(x)); i <- seq_along(x); cs[i] - cs[pmax(1, i - w)] }
pers <- function(key) { z <- per |> arrange(.data[[key]], game_date, game_id) |> group_by(.data[[key]]) |> mutate(i = row_number(), N = n(), across(c(n, s, rn, rs, trips, tds), list(b = ~ bw(.x, 8), f = ~ fw(.x, 8)))) |> ungroup() |>
    filter(i > 8, i + 7 <= N, season >= 2016); c(`overall success rate` = cor(z$s_b / z$n_b, z$s_f / z$n_f), `red-zone success rate` = cor(z$rs_b / z$rn_b, z$rs_f / z$rn_f), `red-zone TD rate` = cor(z$tds_b / z$trips_b, z$tds_f / z$trips_f)) }
cat("=== How steady: correlation of a team's last-8-games rate with its next-8-games rate (2016-2025) ===\n"); print(round(rbind(offense = pers("posteam"), `defense (allowed)` = pers("defteam")), 3))
tp <- D[D$top & D$season >= 2019, ]
cat("\n=== Correlations on the scored rows (top-16 team-games 2019-2025, n =", nrow(tp), ") ===\n")
v <- c("implied_team_total", "o_sr8", "d_sr8", "sr_m8", "o_rzsr8", "d_rzsr8", "rzsr_m8", "o_rztd8", "d_rztd8", "rztd_m8"); print(round(cor(tp[v])[, c("implied_team_total", "o_sr8", "o_rzsr8", "o_rztd8")], 2))
cat("offense rate vs the same game's defense-allowed rate (should be ~0): RZ TD", round(cor(tp$o_rztd8, tp$d_rztd8), 3), " RZ success", round(cor(tp$o_rzsr8, tp$d_rzsr8), 3), " overall", round(cor(tp$o_sr8, tp$d_sr8), 3), "\n")
cat("spread (sd) of each: ", paste(v[-1], round(sapply(tp[v[-1]], sd), 3), collapse = " | "), "\n")
# ---- raw look: short FG attempts and XP attempts per game by matchup cell (top-16 rows, 2016-2025) ----
ta <- D[D$top, ]; cut3 <- function(x) cut(x, quantile(x, c(0, 1/3, 2/3, 1)), labels = c("low", "mid", "high"), include.lowest = TRUE)
for (nm in list(c("o_rztd8", "d_rztd8", "red-zone TD rate"), c("o_rzsr8", "d_rzsr8", "red-zone success rate"), c("o_sr8", "d_sr8", "overall success rate"))) {
  cat("\n--- raw averages by thirds of", nm[3], "(rows = offense, columns = defense allowed; all top-16 team-games 2016-2025) ---\n")
  for (y in c("att_039", "xp_attempts")) { cat(y, ":\n"); print(round(tapply(ta[[y]], list(offense = cut3(ta[[nm[1]]]), defense = cut3(ta[[nm[2]]])), mean), 2)) } }
cat("cell sizes about", round(nrow(ta) / 9), "\n")
# ---- candidates ----
eval(parse(text = s32[grep("^# generic count model", s32):(grep("^decS <- ", s32) - 1)]))
add <- function(b, x) paste(b, "+", x)
mkterms <- function(y, b, lab, sg) list(
  list(paste0(lab, ": 1 red-zone TD rate, matchup"), y, add(b, "rztd_m8"), "rztd_m8", sg),
  list(paste0(lab, ": 2 red-zone TD rate, offense + defense + product"), y, add(b, "o_rztd8 + d_rztd8 + o_rztd8:d_rztd8"), "o_rztd8:d_rztd8", 0),
  list(paste0(lab, ": 3 red-zone success rate, offense only"), y, add(b, "o_rzsr8"), "o_rzsr8", sg),
  list(paste0(lab, ": 4 red-zone success rate, matchup"), y, add(b, "rzsr_m8"), "rzsr_m8", sg),
  list(paste0(lab, ": 5 red-zone success rate, offense + defense + product"), y, add(b, "o_rzsr8 + d_rzsr8 + o_rzsr8:d_rzsr8"), "o_rzsr8:d_rzsr8", 0),
  list(paste0(lab, ": 6 overall success rate, offense only"), y, add(b, "o_sr8"), "o_sr8", if (y == "att_039") 0 else 1),
  list(paste0(lab, ": 7 overall success rate, matchup"), y, add(b, "sr_m8"), "sr_m8", if (y == "att_039") 0 else 1))
TERMS <- c(mkterms("att_039", B039, "0-39", -1), mkterms("xp_attempts", BXP, "XP", 1))
REFT <- c(lapply(c("rztd_m16", "rzsr_m16", "sr_m16"), function(x) list(paste0("0-39: ", x, " (16-game window)"), "att_039", add(B039, x), x, if (x == "sr_m16") 0 else -1)),
          lapply(c("rztd_m16", "rzsr_m16", "sr_m16"), function(x) list(paste0("XP: ", x, " (16-game window)"), "xp_attempts", add(BXP, x), x, 1)),
          list(list("0-39: red-zone TD rate, offense + defense, no product (reference)", "att_039", add(B039, "o_rztd8 + d_rztd8"), "o_rztd8", -1),
               list("0-39: same, defense weight", "att_039", add(B039, "o_rztd8 + d_rztd8"), "d_rztd8", -1),
               list("0-39: red-zone success rate, offense + defense, no product (reference)", "att_039", add(B039, "o_rzsr8 + d_rzsr8"), "o_rzsr8", -1),
               list("0-39: same, defense weight", "att_039", add(B039, "o_rzsr8 + d_rzsr8"), "d_rzsr8", -1),
               list("XP: red-zone TD rate, offense + defense, no product (reference)", "xp_attempts", add(BXP, "o_rztd8 + d_rztd8"), "o_rztd8", 1),
               list("XP: same, defense weight", "xp_attempts", add(BXP, "o_rztd8 + d_rztd8"), "d_rztd8", 1),
               list("XP: overall success rate, offense + defense, no product (reference)", "xp_attempts", add(BXP, "o_sr8 + d_sr8"), "o_sr8", 1),
               list("XP: same, defense weight", "xp_attempts", add(BXP, "o_sr8 + d_sr8"), "d_sr8", 1)))
lcol <- c(xp_attempts = "l_xp", att_039 = "l039")
row1 <- function(tm) { nm <- tm[[1]]; y <- tm[[2]]; rhs <- tm[[3]]; v <- tm[[4]]; sg <- tm[[5]]; b0 <- if (y == "att_039") B039 else BXP
  r <- if (y == "att_039") build(rhs039 = rhs) else build(rhsxp = rhs); co <- sapply(SCORED, function(S) cnt(S, y, rhs)$coef[[v]])
  g <- lapply(SCORED, function(S) cnt(S, y, b0)$oos - cnt(S, y, rhs)$oos); gs <- sapply(g, mean); cc <- cmp(r, base, nm, "final 31")
  sign_ok <- if (sg == 0) (all(co > 0) || all(co < 0)) else all(sign(co) == sg); h1 <- 1000 * mean(unlist(g[SCORED <= 2021])); h2 <- 1000 * mean(unlist(g[SCORED >= 2022]))
  pa <- parts(r); pb <- parts(base); e <- pa$season <= 2021
  tibble(term = nm, stated_sign = c("-", "none", "+")[sg + 2], weight_first_fold = co[1], weight_last_fold = co[length(co)], folds_ok = if (sg == 0) max(sum(co > 0), sum(co < 0)) else sum(sign(co) == sg), att_gain = 1000 * mean(unlist(g)), gain_2019_21 = h1, gain_2022_25 = h2, seasons_better = paste0(sum(gs > 0), "/7"),
         hit_change = cc$hit_change, hit_share = cc$share_better, wcorr_change = cc$wcorr_change, wcorr_share = cc$wcorr_share, wcorr_2019_21 = wc(pa, which(e)) - wc(pb, which(e)), wcorr_2022_25 = wc(pa, which(!e)) - wc(pb, which(!e)),
         mse_change = cc$mse_change, mse_share = cc$mse_share, mean_abs_move = mean(abs(r$proj - base$proj)), max_abs_move = max(abs(r$proj - base$proj)), passes = sign_ok & h1 > 0 & h2 > 0 & cc$wcorr_change >= 0) }
BOOT <- NULL; tt <- bind_rows(lapply(TERMS, row1))
cat("\n=== Candidates on top of the final version of #31 (columns = effect of adding the term) ===\n"); show(tt)
cat("\nbase (final 31):\n"); show(summ(base, "final 31") |> select(version, hit, wcorr, mse, err_039))
rt <- bind_rows(lapply(REFT, row1)); cat("\n=== Reference rows (not candidates): 16-game window; main effects without the product ===\n"); show(rt)
cat("\n--- weights by fold, product terms ---\n")
for (tm in TERMS[c(2, 5, 9, 12)]) { co <- t(sapply(SCORED, function(S) cnt(S, tm[[2]], tm[[3]])$coef)); co <- co[, !grepl("implied|exp_margin", colnames(co)), drop = FALSE]; rownames(co) <- SCORED; cat(tm[[1]], "\n"); print(round(co, 2)) }
# ---- 8. matchup overall success rate in the chances for 40-49 and 50+ kicks ----
build2 <- function(ch) bind_rows(lapply(SCORED, function(S) { spec <- mk("shift", "shift", "shift", kc = c(S = BASE$kc[["S"]], M = LONGDC, L = LONGDC), ch = ch)
  L <- attempts2(S, spec); L$att_039 <- cnt(S, "att_039", B039)$mu; te <- D[D$season == S, ]
  te |> transmute(season, week, game_id, posteam, top, fpts, xp_attempts, att_039, att_4049, att_50, l_xp = cnt(S, "xp_attempts", BXP)$mu, l039 = L$att_039, l4049 = L$att_4049, l50 = L$att_50,
                  proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp)) })) |> filter(top)
chrow <- function(nm, x, zs) { ch <- BASE$ch; ch[zs] <- x; r <- build2(ch); cc <- cmp(r, base, nm, "final 31"); pa <- parts(r); pb <- parts(base); e <- pa$season <= 2021
  bind_rows(lapply(zs, function(z) { co <- sapply(SCORED, function(S) chances(S, z, x)$coef[[1]]); g <- lapply(SCORED, function(S) chances(S, z, "1")$oos - chances(S, z, x)$oos)
    tibble(term = paste0(nm, " | zone ", z), weight_first_fold = co[1], weight_last_fold = co[length(co)], folds_same_sign = max(sum(co > 0), sum(co < 0)), chances_gain = 1000 * mean(unlist(g)), gain_2019_21 = 1000 * mean(unlist(g[SCORED <= 2021])), gain_2022_25 = 1000 * mean(unlist(g[SCORED >= 2022])),
           hit_change = cc$hit_change, hit_share = cc$hit_share, wcorr_change = cc$wcorr_change, wcorr_share = cc$wcorr_share, wcorr_2019_21 = wc(pa, which(e)) - wc(pb, which(e)), wcorr_2022_25 = wc(pa, which(!e)) - wc(pb, which(!e)), mse_change = cc$mse_change, mse_share = cc$mse_share) })) }
c8 <- bind_rows(chrow("8 chances 40-49 and 50+: matchup overall success rate", "sr_m8", c("M", "L")), chrow("(reference) chances: offense overall success rate", "o_sr8", c("M", "L")), chrow("(reference) chances: matchup, 16 games", "sr_m16", c("M", "L")))
cat("\n=== 8. Chances for 40-49 (zone M) and 50+ (zone L) kicks; hit/corr/mse columns are for both zones changed together ===\n"); show(c8)
saveRDS(list(tt = tt, rt = rt, c8 = c8, base = base), "t34_results.rds")

# ===================== PART 3: t34_follow.R (after the main results; not pre-stated) =====================
# #34 follow-up (after the main results; not pre-stated): candidate 8 split by zone. 50+ chances (4th downs at the opponent's 32-41) alone.
s34 <- readLines("t34_test.R"); eval(parse(text = s34[1:(grep("^BOOT <- NULL; tt <- ", s34) - 1)])); eval(parse(text = s34[grep("^build2 <- ", s34):(grep("^c8 <- ", s34) - 1)]))
D$o_sr16c <- D$o_sr16; BOOT <- NULL
one <- function(nm, x, z) { r <- chrow(nm, x, z); r$mean_abs_move <- NA; r }
mv <- function(x, z) { ch <- BASE$ch; ch[z] <- x; r <- build2(ch); c(mean(abs(r$proj - base$proj)), max(abs(r$proj - base$proj))) }
L <- list(c("50+ chances: matchup overall success, 8 games", "sr_m8"), c("50+ chances: offense overall success, 8 games", "o_sr8"), c("50+ chances: matchup overall success, 16 games", "sr_m16"), c("50+ chances: offense overall success, 16 games", "o_sr16"),
          c("50+ chances: defense success allowed, 8 games", "d_sr8"), c("50+ chances: implied total (as #31)", "implied_team_total"), c("50+ chances: implied total + matchup success 16", "implied_team_total + sr_m16"))
out <- bind_rows(lapply(L, function(l) { r <- chrow(l[1], l[2], "L"); m <- mv(l[2], "L"); r$mean_abs_move <- m[1]; r$max_abs_move <- m[2]; r }))
cat("=== 50+ chances only ===\n"); show(out)
cat("\n40-49 chances only:\n"); show(bind_rows(chrow("40-49 chances: matchup overall success, 8 games", "sr_m8", "M"), chrow("40-49 chances: matchup overall success, 16 games", "sr_m16", "M")))
cat("\nweights by fold (50+ chances):\n"); for (l in L[c(1, 3, 4)]) { cat(l[1], ":", round(sapply(SCORED, function(S) chances(S, "L", l[2])$coef[[1]]), 2), "\n") }
ta <- D[D$season >= 2016, ]; q <- cut(ta$sr_m16, quantile(ta$sr_m16, 0:4 / 4), include.lowest = TRUE, labels = c("lowest quarter", "2", "3", "highest quarter"))
cat("\nraw, all team-games 2016-2025, by quarters of 16-game matchup success rate: 4th downs at opp 32-41 per game, 50+ attempts per game, 4th downs at opp 22-31, 40-49 attempts, implied total\n")
print(round(cbind(n4_L = tapply(ta$n4_L, q, mean), att_50 = tapply(ta$att_50, q, mean), n4_M = tapply(ta$n4_M, q, mean), att_4049 = tapply(ta$att_4049, q, mean), implied = tapply(ta$implied_team_total, q, mean)), 3))
r16 <- { ch <- BASE$ch; ch["L"] <- "sr_m16"; build2(ch) }; pa <- parts(r16); pb <- parts(base)
cat("\n50+ chances with 16-game matchup success, by season: hit change", paste(sapply(SCORED, function(s) round(sum(pa$h[pa$season == s]) / sum(pa$n[pa$season == s]) - sum(pb$h[pb$season == s]) / sum(pb$n[pb$season == s]), 4)), collapse = " "),
    "| within-week corr change", paste(sapply(SCORED, function(s) round(wc(pa, which(pa$season == s)) - wc(pb, which(pb$season == s)), 4)), collapse = " "), "\n")
cat("50+ attempts error x1000:", round(1000 * mean(dev_i(base$att_50, base$l50)), 2), "->", round(1000 * mean(dev_i(r16$att_50, r16$l50)), 2), "\n")
saveRDS(list(out = out, r16 = r16), "t34_follow.rds")
