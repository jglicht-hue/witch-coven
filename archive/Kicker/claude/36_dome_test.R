# #36 Dome in the parts of the new model (#31's final version) that lack it (2026-10-06).
# Run in the Kicker Wizerd chat as a one-off. No production script or model is changed. Log: claude/36_dome_test_log.md
# Needs the #31/#32/#34 workspace. PART 1 builds makes by range and dome share; PART 2 is the pre-stated test; PART 3 combines the passing terms and applies them to week 5.

# ===================== PART 1: t36_build.R =====================
# #36 (2026-10-06): makes by range per team-game (regular season 2016-2025), and each kicker's dome share going into the game.
suppressMessages({library(dplyr); library(tidyr)})
fix <- function(x) recode(x, OAK = "LV", SD = "LAC", STL = "LA", .default = x)
mk <- bind_rows(lapply(2016:2025, function(s) { p <- readRDS(sprintf("data/raw/play_by_play_%d.rds", s)) |> filter(season_type == "REG", !is.na(posteam))
  fg <- p |> filter(field_goal_attempt == 1, !is.na(kick_distance)) |> mutate(posteam = fix(posteam), r = case_when(kick_distance <= 39 ~ "039", kick_distance <= 49 ~ "4049", TRUE ~ "50"), made = as.integer(field_goal_result == "made")) |>
    group_by(game_id, posteam, r) |> summarise(a = n(), m = sum(made), .groups = "drop") |> pivot_wider(names_from = r, values_from = c(a, m), values_fill = 0)
  xp <- p |> filter(extra_point_attempt == 1) |> mutate(posteam = fix(posteam)) |> group_by(game_id, posteam) |> summarise(a_xp = n(), m_xp = sum(extra_point_result == "good", na.rm = TRUE), .groups = "drop")
  full_join(fg, xp, by = c("game_id", "posteam")) }))
D <- readRDS("t31_D.rds") |> left_join(mk, by = c("game_id", "posteam")) |> mutate(across(c(a_039, a_4049, a_50, m_039, m_4049, m_50, a_xp, m_xp), ~ coalesce(.x, 0L)))
cat("attempt counts match the table: 0-39", mean(D$a_039 == D$att_039), " 40-49", mean(D$a_4049 == D$att_4049), " 50+", mean(D$a_50 == D$att_50), " XP", mean(D$a_xp == D$xp_attempts), "\n")
D <- D |> mutate(pts_check = m_xp + 3 * m_039 + 4 * m_4049 + 5 * m_50 - (a_039 - m_039) - (a_4049 - m_4049) - (a_50 - m_50)); cat("points rebuilt from makes equal fpts in", mean(D$pts_check == D$fpts), "of rows; mismatches", sum(D$pts_check != D$fpts), "\n")
# kicker's dome share over his previous 32 games (any team), blended with the league share as if 5 league-average games were added
g <- readRDS("data/raw/games.rds") |> select(game_id, gameday)
D <- D |> left_join(g, by = "game_id") |> arrange(kicker_player_id, gameday, game_id) |> group_by(kicker_player_id) |>
  mutate(k_n = pmin(row_number() - 1L, 32L), k_dome = { cs <- c(0, cumsum(is_enclosed)); i <- seq_along(is_enclosed); cs[i] - cs[pmax(1, i - 32)] }) |> ungroup()
lg <- mean(D$is_enclosed); D <- D |> mutate(dome_share = (k_dome + 5 * lg) / (k_n + 5), dome_rel = is_enclosed - dome_share)
cat("league dome share", round(lg, 3), "| kicker dome share: summary\n"); print(summary(D$dome_share)); cat("dome_rel by venue (top-16, 2019+):\n"); print(tapply(D$dome_rel[D$top & D$season >= 2019], D$is_enclosed[D$top & D$season >= 2019], function(x) round(c(mean = mean(x), sd = sd(x)), 3)))
saveRDS(D |> select(-pts_check), "t36_D.rds")

# ===================== PART 2: t36_test.R =====================
# #36 (2026-10-06): dome in the parts of the new model (#31's final version) that lack it. Candidates and rule were sent to the user before this was run.
# No production script or model is changed.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
s32 <- readLines("t32_test.R"); eval(parse(text = s32[1:(grep("^# offense strength apart", s32) - 1)]))
X <- readRDS("t36_D.rds") |> select(game_id, posteam, a_039, a_4049, a_50, m_039, m_4049, m_50, a_xp, m_xp, dome_share, dome_rel)
D <- D |> left_join(X, by = c("game_id", "posteam")); stopifnot(!anyNA(D$dome_rel), all(D$a_039 == D$att_039))
eval(parse(text = s32[grep("^# generic count model", s32):(grep("^decS <- ", s32) - 1)]))          # cnt, B039, BXP, build, base (= final 31, checked)
s34 <- readLines("t34_test.R"); eval(parse(text = s34[grep("^lcol <- ", s34):(grep("^BOOT <- NULL; tt <- ", s34) - 1)])); eval(parse(text = s34[grep("^build2 <- ", s34):(grep("^c8 <- ", s34) - 1)]))
set.seed(20261006); BOOT <- NULL
R <- c("039", "4049", "50", "xp"); key <- function(d) paste(d$game_id, d$posteam)
# ---- make-chance shifts, fit on kicks from earlier seasons (all team-games), centered on the training share ----
shift <- function(S, form) memo(paste("shift", S, form), { tr <- D[D$season < S, ]; v <- if (form == "K3") "dome_rel" else "is_enclosed"; out <- list()
  one <- function(r) { d <- tr[tr[[paste0("a_", r)]] > 0, ]; a <- d[[paste0("a_", r)]]; m <- d[[paste0("m_", r)]]; f <- glm(cbind(m, a - m) ~ x + offset(qlogis(p)), binomial, data.frame(m = m, a = a, x = d[[v]], p = d[[paste0("p_", r)]]))
    c(b = coef(f)[["x"]], se = sqrt(vcov(f)["x", "x"]), a0 = coef(f)[[1]], xbar = sum(a * d[[v]]) / sum(a), n = sum(a)) }
  if (form %in% c("K1", "K3")) for (r in R[1:3]) out[[r]] <- one(r)
  if (form == "K4") out[["xp"]] <- one("xp")
  if (form == "K2") { st <- bind_rows(lapply(c("4049", "50"), function(r) { d <- tr[tr[[paste0("a_", r)]] > 0, ]; data.frame(m = d[[paste0("m_", r)]], a = d[[paste0("a_", r)]], x = d$is_enclosed, p = d[[paste0("p_", r)]], r = r) }))
    f <- glm(cbind(m, a - m) ~ x + r + offset(qlogis(p)), binomial, st); z <- c(b = coef(f)[["x"]], se = sqrt(vcov(f)["x", "x"]), a0 = coef(f)[[1]], xbar = sum(st$a * st$x) / sum(st$a), n = sum(st$a)); out[["4049"]] <- z; out[["50"]] <- z }
  out })
padj <- function(forms) bind_rows(lapply(SCORED, function(S) { te <- D[D$season == S & D$top, ]; P <- te[c("game_id", "posteam", "season", "week", "is_enclosed", "dome_rel", paste0("p_", R), paste0("a_", R), paste0("m_", R))]
  for (r in R) P[[paste0("q_", r)]] <- P[[paste0("p_", r)]]
  for (fm in forms) { sh <- shift(S, fm); v <- if (fm == "K3") "dome_rel" else "is_enclosed"; for (r in names(sh)) P[[paste0("q_", r)]] <- plogis(qlogis(P[[paste0("p_", r)]]) + sh[[r]][["b"]] * (P[[v]] - sh[[r]][["xbar"]])) }
  P }))
ll <- function(m, a, p) -(m * log(p) + (a - m) * log(1 - p))
with_p <- function(b, P) { stopifnot(identical(key(b), key(P))); b$proj <- projected_points(b$l_xp, b$l039, b$l4049, b$l50, P$q_039, P$q_4049, P$q_50, P$q_xp); b }
dome_gap <- function(r) { d <- r |> left_join(D[c("game_id", "posteam", "is_enclosed")], by = c("game_id", "posteam")); res <- d$fpts - d$proj; wk <- paste(d$season, d$week); uw <- unique(wk); idx <- split(seq_len(nrow(d)), wk)
  g <- function(i) mean(res[i][d$is_enclosed[i] == 1]) - mean(res[i][d$is_enclosed[i] == 0]); b <- replicate(1000, g(unlist(idx[sample(uw, replace = TRUE)])))
  c(miss_dome = mean(res[d$is_enclosed == 1]), miss_outdoors = mean(res[d$is_enclosed == 0]), gap = g(seq_len(nrow(d))), gap_share_pos = mean(b > 0)) }
krow <- function(nm, form, ranges) { P <- padj(form); r <- with_p(base, P); cc <- cmp(r, base, nm, "final 31"); pa <- parts(r); pb <- parts(base); e <- pa$season <= 2021
  co <- sapply(SCORED, function(S) sapply(shift(S, form)[ranges], function(z) z[["b"]])); co <- matrix(co, nrow = length(ranges), dimnames = list(ranges, SCORED))
  L <- sapply(ranges, function(rr) { a <- P[[paste0("a_", rr)]]; m <- P[[paste0("m_", rr)]]; ll(m, a, P[[paste0("p_", rr)]]) - ll(m, a, P[[paste0("q_", rr)]]) }); L <- matrix(L, ncol = length(ranges)); k <- sapply(ranges, function(rr) P[[paste0("a_", rr)]]); k <- matrix(k, ncol = length(ranges))
  gain <- function(i) 1000 * sum(L[i, ]) / sum(k[i, ]); dg <- dome_gap(r)
  list(row = tibble(term = nm, folds_positive = paste(apply(co > 0, 1, sum), collapse = "/"), makes_gain = gain(TRUE), gain_2019_21 = gain(P$season <= 2021), gain_2022_25 = gain(P$season >= 2022), seasons_better = paste0(sum(sapply(SCORED, function(S) gain(P$season == S)) > 0), "/7"),
       hit_change = cc$hit_change, hit_share = cc$hit_share, wcorr_change = cc$wcorr_change, wcorr_share = cc$wcorr_share, wcorr_2019_21 = wc(pa, which(e)) - wc(pb, which(e)), wcorr_2022_25 = wc(pa, which(!e)) - wc(pb, which(!e)), mse_change = cc$mse_change, mse_share = cc$mse_share,
       mean_abs_move = mean(abs(r$proj - base$proj)), max_abs_move = max(abs(r$proj - base$proj)), miss_dome = dg[[1]], miss_outdoors = dg[[2]], gap = dg[[3]],
       passes = all(co > 0) & gain(P$season <= 2021) > 0 & gain(P$season >= 2022) > 0 & cc$wcorr_change >= 0), co = co, r = r, P = P) }
cat("=== base (final 31) ===\n"); show(summ(base, "final 31") |> select(version, hit, wcorr, mse, bias)); print(round(dome_gap(base), 3))
K <- list(K1 = krow("K1 FG makes: dome shift per range", "K1", R[1:3]), K2 = krow("K2 FG makes: one dome shift for 40-49 and 50+", "K2", c("4049", "50")), K3 = krow("K3 FG makes: per range, vs the kicker's own dome share", "K3", R[1:3]), K4 = krow("K4 XP makes: dome shift", "K4", "xp"))
cat("\n=== Make-chance candidates (columns = effect of adding the term to the final version) ===\n"); show(bind_rows(lapply(K, `[[`, "row")))
for (k in names(K)) { cat("\n", k, "dome shift (log-odds) by fold:\n"); print(round(K[[k]]$co, 3)) }
cat("\nlast fold (fit on 2016-2024) detail: shift, standard error, kicks, share of kicks in domes\n"); for (k in c("K1", "K2", "K3", "K4")) { sh <- shift(2025, k); for (r in names(sh)) cat(k, r, paste(names(sh[[r]]), round(sh[[r]], 3), collapse = " "), "\n") }
cat("\nraw make rates, all team-games 2016-2025 (dome vs outdoors), with the kickers' average make chance going in:\n")
for (r in R) { a <- D[[paste0("a_", r)]]; m <- D[[paste0("m_", r)]]; p <- D[[paste0("p_", r)]]; for (dv in 0:1) { i <- D$is_enclosed == dv; cat(r, if (dv) "dome    " else "outdoors", "kicks", sum(a[i]), " made", round(sum(m[i]) / sum(a[i]), 4), " expected from make chances", round(sum(a[i] * p[i]) / sum(a[i]), 4), "\n") } }
# ---- attempts candidates ----
ATT <- list(list("A1 XP attempts: dome", "xp_attempts", paste(BXP, "+ is_enclosed"), "is_enclosed", 1), list("A2 0-39 attempts: dome", "att_039", paste(B039, "+ is_enclosed"), "is_enclosed", 0))
ta <- bind_rows(lapply(ATT, row1)); ra <- list(A1 = build(rhsxp = ATT[[1]][[3]]), A2 = build(rhs039 = ATT[[2]][[3]]))
ta$miss_dome <- sapply(ra, function(r) dome_gap(r)[[1]]); ta$miss_outdoors <- sapply(ra, function(r) dome_gap(r)[[2]]); ta$gap <- sapply(ra, function(r) dome_gap(r)[[3]])
cat("\n=== Attempts candidates: count models ===\n"); show(ta)
cat("dome weight by fold: A1", round(sapply(SCORED, function(S) cnt(S, "xp_attempts", ATT[[1]][[3]])$coef[["is_enclosed"]]), 3), "| A2", round(sapply(SCORED, function(S) cnt(S, "att_039", ATT[[2]][[3]])$coef[["is_enclosed"]]), 3), "\n")
c34 <- bind_rows(chrow("A3 chances for 40-49 kicks: dome", "is_enclosed", "M"), chrow("A4 chances for 50+ kicks: dome", "is_enclosed", "L"))
rc <- list(A3 = { ch <- BASE$ch; ch["M"] <- "is_enclosed"; build2(ch) }, A4 = { ch <- BASE$ch; ch["L"] <- "is_enclosed"; build2(ch) })
c34$miss_dome <- sapply(rc, function(r) dome_gap(r)[[1]]); c34$miss_outdoors <- sapply(rc, function(r) dome_gap(r)[[2]]); c34$gap <- sapply(rc, function(r) dome_gap(r)[[3]])
cat("\n=== Attempts candidates: chances for long kicks ===\n"); show(c34)
cat("dome weight by fold: A3", round(sapply(SCORED, function(S) chances(S, "M", "is_enclosed")$coef[[1]]), 3), "| A4", round(sapply(SCORED, function(S) chances(S, "L", "is_enclosed")$coef[[1]]), 3), "\n")
saveRDS(list(K = lapply(K, function(k) k[c("row", "co", "r")]), ta = ta, c34 = c34, ra = ra, rc = rc, base = base), "t36_results.rds")

# ===================== PART 3: t36_final.R =====================
# #36 part 2: the passing dome terms together, and this week's projections under three versions. Workspace only.
s36 <- readLines("t36_test.R"); eval(parse(text = s36[1:(grep("^cat\\(\"=== base \\(final 31\\) ===", s36) - 1)]))
r29 <- readRDS("t29_results.rds")$R; cur <- r29$current_recipe; stopifnot(identical(key(cur), key(base)))
A1 <- build(rhsxp = paste(BXP, "+ is_enclosed"))
V <- list(`new model (final 31)` = base, `+ K1 (FG makes, per range)` = with_p(base, padj("K1")), `+ K4 (XP makes)` = with_p(base, padj("K4")), `+ K1 + K4` = with_p(base, padj(c("K1", "K4"))), `+ K2 + K4` = with_p(base, padj(c("K2", "K4"))), `+ K3 + K4` = with_p(base, padj(c("K3", "K4"))),
          `+ K1 + K4 + A1 (XP attempts dome; failed the rule)` = with_p(A1, padj(c("K1", "K4"))), `current version` = cur)
cat("=== Versions, 2019-2025 ===\n"); show(bind_rows(lapply(names(V), function(k) { s <- summ(V[[k]], k); g <- dome_gap(V[[k]]); s |> select(version, hit, wcorr, mse, bias) |> mutate(miss_dome = g[[1]], miss_outdoors = g[[2]], gap = g[[3]], gap_share_pos = g[[4]]) })))
BOOT <- NULL; f <- V[["+ K1 + K4"]]
cc <- bind_rows(cmp(f, base, "+ K1 + K4", "new model (final 31)"), cmp(f, cur, "+ K1 + K4", "current version"), cmp(V[["+ K3 + K4"]], f, "+ K3 + K4", "+ K1 + K4"), cmp(V[["+ K2 + K4"]], f, "+ K2 + K4", "+ K1 + K4"), cmp(V[[7]], f, "+ K1 + K4 + A1", "+ K1 + K4"), cmp(base, cur, "new model (final 31)", "current version"))
show(cc)
pa <- parts(f); pb <- parts(base); pc <- parts(cur); e <- pa$season <= 2021
cat("halves, + K1 + K4 vs new model: wcorr", round(wc(pa, which(e)) - wc(pb, which(e)), 4), round(wc(pa, which(!e)) - wc(pb, which(!e)), 4), "| vs current version:", round(wc(pa, which(e)) - wc(pc, which(e)), 4), round(wc(pa, which(!e)) - wc(pc, which(!e)), 4), "\n")
cat("by season, + K1 + K4 vs new model: hit", paste(sapply(SCORED, function(s) round(sum(pa$h[pa$season == s]) / sum(pa$n[pa$season == s]) - sum(pb$h[pb$season == s]) / sum(pb$n[pb$season == s]), 4)), collapse = " "), "| wcorr", paste(sapply(SCORED, function(s) round(wc(pa, which(pa$season == s)) - wc(pb, which(pb$season == s)), 4)), collapse = " "), "\n")
cat("mean / max projection move, + K1 + K4 vs new model:", round(mean(abs(f$proj - base$proj)), 3), round(max(abs(f$proj - base$proj)), 3), "\n")
d <- f |> left_join(D[c("game_id", "posteam", "is_enclosed")], by = c("game_id", "posteam")); cat("mean move in domes", round(mean((f$proj - base$proj)[d$is_enclosed == 1]), 3), " outdoors", round(mean((f$proj - base$proj)[d$is_enclosed == 0]), 3), "\n")
# make chances after the shift: are they calibrated by venue on the scored rows?
P <- padj(c("K1", "K4")); cat("\nscored rows (top-16, 2019-2025): made vs expected, before -> after the shift\n")
for (r in R) for (dv in 0:1) { i <- P$is_enclosed == dv; a <- P[[paste0("a_", r)]][i]; cat(r, if (dv) "dome    " else "outdoors", "kicks", sum(a), " made", round(sum(P[[paste0("m_", r)]][i]) / sum(a), 4), " expected", round(sum(a * P[[paste0("p_", r)]][i]) / sum(a), 4), "->", round(sum(a * P[[paste0("q_", r)]][i]) / sum(a), 4), "\n") }
# ---- this week ----
old <- read_csv("../build/wk5/data/weekly_projections_latest.csv", show_col_types = FALSE); inp <- readRDS("../build/wk5/inputs_wk5.rds") |> filter(!is.na(kicker_player_id))
w5 <- inp |> mutate(season = 2026L, top = top16pre, fpts = NA_real_, xp_attempts = 0L, att_039 = 0L, att_4049 = 0L, att_50 = 0L, att_tot = 0L, att_40p = 0L, n4_S = 0L, n4_M = 0L, n4_L = 0L, exp_margin = if_else(implied_imputed, 0, 2 * implied_team_total - total_line),
                    a_039 = 0L, a_4049 = 0L, a_50 = 0L, m_039 = 0L, m_4049 = 0L, m_50 = 0L, a_xp = 0L, m_xp = 0L, dome_share = NA_real_, dome_rel = 0)
D <- bind_rows(D |> mutate(fs = as.character(fs)), w5 |> mutate(fs = "2026") |> select(all_of(names(D)))) |> mutate(fs = factor(fs))
S <- 2026; L <- attempts2(S, mk("shift", "shift", "shift")); L$att_039 <- count039(S); te <- D[D$season == S, ]; sh <- c(shift(S, "K1"), shift(S, "K4"))
cat("\nshifts fit on 2016-2025 (log-odds, standard error, share of kicks in domes):\n"); for (r in names(sh)) cat(r, round(sh[[r]][c("b", "se", "xbar", "n")], 3), "\n")
q <- lapply(setNames(R, R), function(r) plogis(qlogis(te[[paste0("p_", r)]]) + sh[[r]][["b"]] * (te$is_enclosed - sh[[r]][["xbar"]])))
w <- te |> transmute(posteam, dome = is_enclosed, xp = xp_skel(S), a039 = L$att_039, a4049 = L$att_4049, a50 = L$att_50, p_039, p_4049, p_50, p_xp, q_039 = q[["039"]], q_4049 = q[["4049"]], q_50 = q[["50"]], q_xp = q[["xp"]],
                     new = projected_points(xp, a039, a4049, a50, p_039, p_4049, p_50, p_xp), new_dome = projected_points(xp, a039, a4049, a50, q_039, q_4049, q_50, q_xp))
out <- old |> transmute(kicker = kicker_player_name, posteam = team, opponent, top16pre, roof_unknown, current = projected_points) |> inner_join(w, by = "posteam") |>
  mutate(rank_current = rank(-current), rank_new = rank(-new), rank_new_dome = rank(-new_dome), dome_change = new_dome - new, vs_current = new_dome - current) |> arrange(rank_new_dome)
print(as.data.frame(out |> transmute(rank = rank_new_dome, kicker, team = posteam, opp = opponent, dome = round(dome, 2), current = round(current, 2), new = round(new, 2), new_dome = round(new_dome, 2), dome_change = round(dome_change, 2), vs_current = round(vs_current, 2), rank_current, rank_new,
                                     p_4049 = round(p_4049, 3), q_4049 = round(q_4049, 3), p_50 = round(p_50, 3), q_50 = round(q_50, 3))), row.names = FALSE)
cat("by venue: "); print(as.data.frame(out |> mutate(venue = ifelse(dome == 1, "dome", ifelse(dome == 0, "outdoors", "roof unknown"))) |> group_by(venue) |> summarise(n = n(), current = round(mean(current), 2), new = round(mean(new), 2), new_dome = round(mean(new_dome), 2))))
cat("mean |new_dome - current|", round(mean(abs(out$vs_current)), 2), " max", round(max(abs(out$vs_current)), 2), "; top-12 kept vs current:", length(intersect(out$posteam[out$rank_current <= 12], out$posteam[out$rank_new_dome <= 12])), "; vs new:", length(intersect(out$posteam[out$rank_new <= 12], out$posteam[out$rank_new_dome <= 12])), "\n")
write_csv(out, "t36_week5_three_versions.csv"); saveRDS(list(V = V, cc = cc, out = out, sh = sh), "t36_final.rds")
