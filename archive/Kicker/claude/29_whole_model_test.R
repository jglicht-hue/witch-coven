# #29 Whole-model test on ten seasons: structures and predictor sets (2026-10-06).
# One-off test run in the Kicker Wizerd chat. No production script or model was changed. Rules were set and sent to the user before any result
# (see claude/29_whole_model_test_log.md). Run from the pipeline folder. Needs t26_inputs_<season>.rds (#26 PART 1), t25_tg.rds and t25_fourth.rds (#25 PART 1),
# t28_xp.rds (#28) and 08_points_distribution.R. In this session the four parts were separate files: t29_build.R, t29_test.R, t29_more.R, t29_extra.R;
# PARTS 3 and 4 read t29_test.R to reuse its functions, so save PART 2 under that name before running them.

# ======================= PART 1 (t29_build.R): test table and 4th-down plays =======================
suppressMessages({library(dplyr); library(tidyr); library(readr)})
inp <- bind_rows(lapply(2016:2025, function(s) readRDS(sprintf("t26_inputs_%d.rds", s))))
lt <- readRDS("t25_tg.rds") |> select(game_id, posteam, att_039, att_4049, att_50, fpts, top = top16pre)
xp <- readRDS("t28_xp.rds")
D <- inp |> inner_join(lt, by = c("game_id", "posteam")) |> left_join(xp, by = c("game_id", "posteam")) |>
  mutate(xp_attempts = replace_na(xp_attempts, 0L), att_tot = att_039 + att_4049 + att_50, att_40p = att_4049 + att_50,
         exp_margin = 2 * implied_team_total - total_line, fs = factor(season)) |>
  select(season, week, game_id, posteam, opponent, home_away, kicker_player_id, kicker_player_name, top, fs,
         xp_attempts, att_039, att_4049, att_50, att_tot, att_40p, fpts,
         implied_team_total, total_line, spread_line, exp_margin, is_enclosed, redzone_td_rate_trail8, redzone_trips_per_game_trail8,
         opp_redzone_td_rate_allowed_trail8, coach_long_fg_rate, krate_039, krate_4049, krate_50, krate_40plus, kshare_4049_hlall,
         p_039, p_4049, p_50, p_xp)
stopifnot(!anyNA(D), !anyDuplicated(D[c("game_id", "posteam")]))
# sanity: expected margin has the same sign as the favorite; the two teams' margins cancel
chk <- D |> group_by(game_id) |> summarise(s = sum(exp_margin), t = sum(implied_team_total) - first(total_line), n = n(), .groups = "drop")
cat("team-games", nrow(D), "; top-16", sum(D$top), "; games with both teams", sum(chk$n == 2), "; max |margin sum|", max(abs(chk$s[chk$n == 2])), "; max |implied sum - total|", max(abs(chk$t[chk$n == 2])), "\n")
print(as.data.frame(D |> group_by(season) |> summarise(n = n(), top = sum(top), fpts = mean(fpts), fpts_top = mean(fpts[top]), tot = mean(att_tot)) |> mutate(across(where(is.double), ~ round(.x, 2)))))
plays <- readRDS("t25_fourth.rds") |> filter(season >= 2016) |>
  select(season, week, game_id, posteam, yardline_100, ydstogo, score_differential, half_seconds_remaining, qtr, kicked) |>
  inner_join(D |> select(game_id, posteam, fs, is_enclosed, krate_40plus, krate_4049, krate_50, coach_long_fg_rate), by = c("game_id", "posteam")) |>
  mutate(zone = if_else(yardline_100 <= 31, "A", "B"), q4 = as.integer(qtr >= 4), late = as.integer(half_seconds_remaining <= 120), lytg = log(ydstogo)) |>
  filter(!is.na(score_differential), !is.na(half_seconds_remaining), !is.na(kicked))
cat("4th downs in 40-59 yard range, 2016-2025:", nrow(plays), "; kick share zone A (40-49):", round(mean(plays$kicked[plays$zone == "A"]), 3), " n", sum(plays$zone == "A"),
    "; zone B (50-59):", round(mean(plays$kicked[plays$zone == "B"]), 3), " n", sum(plays$zone == "B"), "\n")
# how many long attempts come from these plays
cat("share of 40-49 attempts that are 4th-down kicks in zone A:", round(sum(plays$kicked[plays$zone == "A"]) / sum(D$att_4049), 3), "; 50+ in zone B:", round(sum(plays$kicked[plays$zone == "B"]) / sum(D$att_50), 3), "\n")
saveRDS(D, "t29_D.rds"); saveRDS(plays, "t29_plays.rds")

# ======================= PART 2 (t29_test.R): versions and single terms =======================
suppressMessages({library(dplyr); library(tidyr); library(readr)})
set.seed(20261006)
source("08_points_distribution.R")   # projected_points()
dev_i <- function(y, mu) 2 * (ifelse(y == 0, 0, y * log(y / mu)) - (y - mu))
D <- readRDS("t29_D.rds"); plays <- readRDS("t29_plays.rds")
SCORED <- 2019:2025

# ---------- generic walk-forward fits ----------
# Weights from all training rows (with a level per season); level for the predicted season from the 3 seasons before it.
wf <- function(y, rhs, S, top_only = TRUE, family = poisson, window = NULL, fe = TRUE, data = D) {
  pool <- data[data$season < S & (if (is.null(window)) TRUE else data$season >= S - window), ]
  tr <- if (top_only) pool[pool$top, ] else pool
  te <- data[data$season == S, ]
  if (!fe) { f <- glm(as.formula(paste(y, "~", rhs)), family, tr); return(list(mu = as.numeric(predict(f, te, type = "response")), fit = f)) }
  tr$fs <- droplevels(tr$fs); ref <- levels(tr$fs)[nlevels(tr$fs)]
  f <- glm(as.formula(paste(y, "~", rhs, "+ fs")), family, tr)
  setref <- function(d) { d$fs <- factor(ref, levels = levels(tr$fs)); d }
  cal <- pool[pool$top & pool$season >= S - 3, ]                      # level: top-16 rows of the last 3 seasons
  cal$eta <- as.numeric(predict(f, setref(cal), type = "link")); eta_te <- as.numeric(predict(f, setref(te), type = "link"))
  a <- coef(glm(as.formula(paste(y, "~ 1 + offset(eta)")), family, cal))[[1]]
  list(mu = family()$linkinv(eta_te + a), fit = f)
}
F_XP <- "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8 + coach_long_fg_rate"
F_039 <- "implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate"
CUR <- c(xp_attempts = F_XP, att_039 = F_039,
         att_4049 = "is_enclosed + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate + offset(0 * krate_4049)",
         att_50 = "is_enclosed + is_enclosed:krate_50 + offset(1.307 * krate_40plus)")
OLD <- c(xp_attempts = F_XP, att_039 = F_039,
         att_4049 = "is_enclosed + krate_4049 + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
         att_50 = "is_enclosed + krate_40plus + is_enclosed:krate_50")
SKEL <- c(xp_attempts = "implied_team_total", att_039 = "implied_team_total + I(implied_team_total^2)", att_4049 = "1",
          att_50 = "is_enclosed + krate_40plus + is_enclosed:krate_50")
OUT <- names(SKEL)
ranges <- function(forms, S, ...) setNames(lapply(OUT, function(o) wf(o, forms[[o]], S, ...)$mu), OUT)

# ---------- total + split ----------
split_model <- function(S, total_rhs = "implied_team_total + I(implied_team_total^2)", share_rhs = c("is_enclosed + krate_40plus", "is_enclosed + krate_40plus + is_enclosed:krate_50")) {
  tot <- wf("att_tot", total_rhs, S)$mu
  d40 <- D[D$att_tot > 0, ]; p40 <- wf("cbind(att_40p, att_039)", share_rhs[1], S, family = binomial, data = d40)   # share of attempts from 40+
  d50 <- D[D$att_40p > 0, ]; p50 <- wf("cbind(att_50, att_4049)", share_rhs[2], S, family = binomial, data = d50)  # share of 40+ attempts from 50+
  te <- D[D$season == S, ]
  pr <- function(m, dd) { tr <- dd[dd$season < S & dd$top, ]; tr$fs <- droplevels(tr$fs); ref <- levels(tr$fs)[nlevels(tr$fs)]
    setref <- function(d) { d$fs <- factor(ref, levels = levels(tr$fs)); d }
    cal <- dd[dd$season < S & dd$season >= S - 3 & dd$top, ]; resp <- all.vars(formula(m$fit))[1:2]
    cal$eta <- as.numeric(predict(m$fit, setref(cal), type = "link"))
    a <- coef(glm(as.formula(paste0("cbind(", resp[1], ", ", resp[2], ") ~ 1 + offset(eta)")), binomial, cal))[[1]]
    plogis(as.numeric(predict(m$fit, setref(te), type = "link")) + a) }
  s40 <- pr(p40, d40); s50 <- pr(p50, d50)
  list(att_039 = tot * (1 - s40), att_4049 = tot * s40 * (1 - s50), att_50 = tot * s40 * s50)
}

# ---------- decision model: kick-or-go on 4th down in 40-59 yard range -> long-kick propensity ----------
DEC_RHS <- "yardline_100 + lytg + score_differential + q4 + late + is_enclosed + krate_40plus + is_enclosed:krate_40plus + coach_long_fg_rate"
dec_coefs <- list()
propensity <- function(S, zone) {
  pt <- plays[plays$season < S & plays$zone == zone, ]; pt$fs <- droplevels(pt$fs)
  g <- glm(as.formula(paste("kicked ~", DEC_RHS, "+ fs")), binomial, pt); b <- coef(g)
  dec_coefs[[paste(S, zone)]] <<- c(S = S, zone = zone, n = nrow(pt), round(b[c("is_enclosed", "krate_40plus", "is_enclosed:krate_40plus", "coach_long_fg_rate")], 3),
                                    z_acc = round(summary(g)$coefficients["krate_40plus", 3], 2))
  lv <- levels(pt$fs); fe <- c(0, b[paste0("fs", lv[-1])]); names(fe) <- lv
  level <- mean(fe[as.character(intersect((S - 3):(S - 1), as.integer(lv)))])                       # level of the last 3 seasons
  a <- b[["(Intercept)"]] + level + b[["yardline_100"]] * pt$yardline_100 + b[["lytg"]] * pt$lytg + b[["score_differential"]] * pt$score_differential +
    b[["q4"]] * pt$q4 + b[["late"]] * pt$late                                                       # situation part, reference plays = training plays
  rows <- D[D$season <= S, ]
  tj <- b[["is_enclosed"]] * rows$is_enclosed + b[["krate_40plus"]] * rows$krate_40plus + b[["is_enclosed:krate_40plus"]] * rows$is_enclosed * rows$krate_40plus +
    b[["coach_long_fg_rate"]] * rows$coach_long_fg_rate
  prop <- vapply(tj, function(t) mean(plogis(a + t)), numeric(1))
  tibble(game_id = rows$game_id, posteam = rows$posteam, prop = prop)
}
decision <- function(S, free = FALSE) {
  out <- list()
  for (z in c("A", "B")) { o <- if (z == "A") "att_4049" else "att_50"
    pr <- propensity(S, z); d <- D |> left_join(pr, by = c("game_id", "posteam")) |> mutate(lprop = log(prop))
    if (free) out[[o]] <- wf(o, "lprop", S, data = d)$mu                                              # exponent on the propensity estimated
    else { cal <- d[d$season < S & d$season >= S - 3 & d$top, ]; te <- d[d$season == S, ]            # attempts proportional to the propensity
      out[[o]] <- te$prop * sum(cal[[o]]) / sum(cal$prop) } }
  out
}

# ---------- versions ----------
build <- function(S, v) {
  sk <- function() ranges(SKEL, S)
  L <- switch(v,
    current_recipe = setNames(lapply(OUT, function(o) wf(o, CUR[[o]], S, window = 3, fe = FALSE)$mu), OUT),
    old_recipe = setNames(lapply(OUT, function(o) wf(o, OLD[[o]], S, window = 3, fe = FALSE)$mu), OUT),
    current_10 = ranges(CUR, S),
    skeleton = sk(),
    skeleton_all = ranges(SKEL, S, top_only = FALSE),
    total_split = { s <- sk(); m <- split_model(S); s[names(m)] <- m; s },
    decision = { s <- sk(); m <- decision(S); s[names(m)] <- m; s },
    decision_free = { s <- sk(); m <- decision(S, free = TRUE); s[names(m)] <- m; s },
    stop("unknown version"))
  te <- D[D$season == S, ]
  te |> transmute(season, week, game_id, posteam, top, fpts, xp_attempts, att_039, att_4049, att_50, l_xp = L$xp_attempts, l039 = L$att_039, l4049 = L$att_4049, l50 = L$att_50,
                  proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp))
}
run <- function(v) bind_rows(lapply(SCORED, build, v = v)) |> filter(top)
# skeleton + one term (the term's model gets the extra piece)
TERMS <- list(`0-39 + expected margin` = c("att_039", "exp_margin", "exp_margin", 1),
              `0-39 + opp red-zone TD rate allowed` = c("att_039", "opp_redzone_td_rate_allowed_trail8", "opp_redzone_td_rate_allowed_trail8", -1),
              `XP + opp red-zone TD rate allowed` = c("xp_attempts", "opp_redzone_td_rate_allowed_trail8", "opp_redzone_td_rate_allowed_trail8", 1),
              `XP + own red-zone TD rate` = c("xp_attempts", "redzone_td_rate_trail8", "redzone_td_rate_trail8", 1),
              `40-49 + dome` = c("att_4049", "is_enclosed", "is_enclosed", 1),
              `40-49 + kicker 40-49 accuracy` = c("att_4049", "krate_4049", "krate_4049", 1),
              `40-49 + dome x kicker 40-49 accuracy` = c("att_4049", "is_enclosed + krate_4049 + is_enclosed:krate_4049", "is_enclosed:krate_4049", 1),
              `40-49 + coach long-range FG rate` = c("att_4049", "coach_long_fg_rate", "coach_long_fg_rate", 1),
              `50+ + coach long-range FG rate` = c("att_50", "coach_long_fg_rate", "coach_long_fg_rate", 1))
with_terms <- function(S, which_terms) { forms <- SKEL
  for (k in which_terms) { o <- TERMS[[k]][1]; forms[[o]] <- if (forms[[o]] == "1") TERMS[[k]][2] else paste(forms[[o]], "+", TERMS[[k]][2]) }
  L <- ranges(forms, S); te <- D[D$season == S, ]
  te |> transmute(season, week, game_id, posteam, top, fpts, xp_attempts, att_039, att_4049, att_50, l_xp = L$xp_attempts, l039 = L$att_039, l4049 = L$att_4049, l50 = L$att_50,
                  proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp)) }
run_terms <- function(which_terms, seasons = SCORED) bind_rows(lapply(seasons, with_terms, which_terms = which_terms)) |> filter(top)

# ---------- scoring ----------
parts <- function(d) { wk <- paste(d$season, d$week); uw <- unique(wk)
  m <- t(sapply(uw, function(w) { g <- d[wk == w, ]; dp <- outer(g$proj, g$proj, "-"); da <- outer(g$fpts, g$fpts, "-"); ok <- upper.tri(da) & da != 0
    c(sum(ifelse(dp[ok] == 0, 0.5, as.numeric(sign(dp[ok]) == sign(da[ok])))), sum(ok)) }))
  data.frame(wk = uw, season = as.integer(substr(uw, 1, 4)), h = m[, 1], n = m[, 2], sse = as.numeric(tapply((d$fpts - d$proj)^2, wk, sum)[uw]), ng = as.numeric(tapply(wk, wk, length)[uw])) }
att_err <- function(d) c(xp = 1000 * mean(dev_i(d$xp_attempts, d$l_xp)), a039 = 1000 * mean(dev_i(d$att_039, d$l039)), a4049 = 1000 * mean(dev_i(d$att_4049, d$l4049)), a50 = 1000 * mean(dev_i(d$att_50, d$l50)))
summ <- function(d, label) { p <- parts(d); bs <- tapply(p$h, p$season, sum) / tapply(p$n, p$season, sum); e <- att_err(d)
  tibble(version = label, hit = sum(p$h) / sum(p$n), mse = sum(p$sse) / sum(p$ng), bias = mean(d$proj) - mean(d$fpts), err_xp = e[["xp"]], err_039 = e[["a039"]], err_4049 = e[["a4049"]], err_50 = e[["a50"]],
         !!!setNames(as.list(round(bs, 4)), paste0("h", names(bs)))) }
BOOT <- NULL
cmp <- function(a, b, la, lb, B = 2000) { pa <- parts(a); pb <- parts(b); stopifnot(identical(pa$wk, pb$wk)); nw <- nrow(pa)
  if (is.null(BOOT) || nrow(BOOT) != nw) BOOT <<- replicate(B, sample(nw, replace = TRUE))
  dh <- apply(BOOT, 2, function(i) sum(pa$h[i]) / sum(pa$n[i]) - sum(pb$h[i]) / sum(pb$n[i])); dm <- apply(BOOT, 2, function(i) (sum(pa$sse[i]) - sum(pb$sse[i])) / sum(pa$ng[i]))
  ss <- sort(unique(pa$season)); ps <- sapply(ss, function(s) sum(pa$h[pa$season == s]) / sum(pa$n[pa$season == s]) - sum(pb$h[pb$season == s]) / sum(pb$n[pb$season == s]))
  ms <- sapply(ss, function(s) sum(pa$sse[pa$season == s]) / sum(pa$ng[pa$season == s]) - sum(pb$sse[pb$season == s]) / sum(pb$ng[pb$season == s]))
  tibble(version = la, vs = lb, hit_change = sum(pa$h) / sum(pa$n) - sum(pb$h) / sum(pb$n), hit_lo = quantile(dh, .025), hit_hi = quantile(dh, .975), share_better = mean(dh > 0),
         seasons_better = paste0(sum(ps > 0), "/", length(ss)), mse_change = sum(pa$sse) / sum(pa$ng) - sum(pb$sse) / sum(pb$ng), mse_share_better = mean(dm < 0), mse_seasons_better = paste0(sum(ms < 0), "/", length(ss))) }
show <- function(x) print(as.data.frame(x |> mutate(across(where(is.double), ~ round(.x, 4)))), width = 260, right = FALSE)

# ---------- 1. versions ----------
V <- c("current_recipe", "old_recipe", "current_10", "skeleton", "skeleton_all", "total_split", "decision", "decision_free")
R <- lapply(setNames(V, V), run)
cat("scored top-16 team-games:", nrow(R$skeleton), "; weeks", length(unique(paste(R$skeleton$season, R$skeleton$week))), "; pairs", sum(parts(R$skeleton)$n), "\n")
cat("\n=== 1. Versions (2019-2025, pre-game top 16) ===\n"); tabV <- bind_rows(lapply(V, function(v) summ(R[[v]], v))); show(tabV)
C1 <- bind_rows(cmp(R$skeleton, R$current_recipe, "skeleton", "current_recipe"), cmp(R$current_10, R$current_recipe, "current_10", "current_recipe"),
                cmp(R$current_recipe, R$old_recipe, "current_recipe", "old_recipe"), cmp(R$skeleton, R$current_10, "skeleton", "current_10"),
                cmp(R$total_split, R$skeleton, "total_split", "skeleton"), cmp(R$decision, R$skeleton, "decision", "skeleton"),
                cmp(R$decision_free, R$skeleton, "decision_free", "skeleton"), cmp(R$skeleton_all, R$skeleton, "skeleton_all", "skeleton"))
cat("\n--- comparisons ---\n"); show(C1)
cat("\n--- decision model: weights by fold ---\n"); print(as.data.frame(bind_rows(lapply(dec_coefs, function(x) as_tibble(as.list(x))))), right = FALSE)

# ---------- 2. skeleton + one term ----------
RT <- lapply(setNames(names(TERMS), names(TERMS)), function(k) run_terms(k))
term_tab <- bind_rows(lapply(names(TERMS), function(k) { o <- TERMS[[k]][1]; lcol <- c(xp_attempts = "l_xp", att_039 = "l039", att_4049 = "l4049", att_50 = "l50")[[o]]
  a <- RT[[k]]; b <- R$skeleton; g <- 1000 * (dev_i(b[[o]], b[[lcol]]) - dev_i(a[[o]], a[[lcol]])); bys <- tapply(g, a$season, mean)
  # sign of the term in each fold's fit
  sg <- sapply(SCORED, function(S) { rhs <- if (SKEL[[o]] == "1") TERMS[[k]][2] else paste(SKEL[[o]], "+", TERMS[[k]][2]); coef(wf(o, rhs, S)$fit)[[TERMS[[k]][3]]] })
  cc <- cmp(a, b, k, "skeleton")
  tibble(term = k, coef_last_fold = sg[length(sg)], folds_right_sign = paste0(sum(sign(sg) == as.numeric(TERMS[[k]][4])), "/", length(sg)), att_gain = mean(g), gain_2019_21 = mean(g[a$season <= 2021]), gain_2022_25 = mean(g[a$season >= 2022]),
         seasons_better = paste0(sum(bys > 0), "/", length(bys)), hit_change = cc$hit_change, hit_share_better = cc$share_better, hit_seasons = cc$seasons_better, mse_change = cc$mse_change, mse_share_better = cc$mse_share_better) }))
term_tab <- term_tab |> mutate(right_sign = folds_right_sign == "7/7", passes = right_sign & gain_2019_21 > 0 & gain_2022_25 > 0 & as.integer(substr(seasons_better, 1, 1)) >= 5 & hit_change >= 0)
cat("\n=== 2. Skeleton + one term ===\n"); show(term_tab)
passed <- term_tab$term[term_tab$passes]; cat("Passed:", if (length(passed)) paste(passed, collapse = "; ") else "none", "\n")
saveRDS(list(R = R, RT = RT, tabV = tabV, C1 = C1, term_tab = term_tab, passed = passed, dec = dec_coefs), "t29_results.rds")
write_csv(tabV, "t29_versions.csv"); write_csv(C1, "t29_comparisons.csv"); write_csv(term_tab, "t29_terms.csv")

# ======================= PART 3 (t29_more.R): pass rules, nested check, context =======================
suppressMessages({library(dplyr); library(tidyr); library(readr)})
src <- readLines("t29_test.R"); eval(parse(text = src[1:(grep("^# ---------- 1. versions", src) - 1)]))   # functions and data only
res <- readRDS("t29_results.rds"); R <- res$R; RT <- res$RT; passed <- res$passed
set.seed(20261006)
lcol <- c(xp_attempts = "l_xp", att_039 = "l039", att_4049 = "l4049", att_50 = "l50")

# ---- final version by the rules: range models (no structure confirmed better) + passed terms ----
final <- run_terms(passed)
cat("=== 3. Final version (skeleton +", paste(passed, collapse = "; "), ") ===\n")
show(bind_rows(summ(R$current_recipe, "current_recipe"), summ(R$skeleton, "skeleton"), summ(final, "final")))
show(bind_rows(cmp(final, R$current_recipe, "final", "current_recipe"), cmp(final, R$skeleton, "final", "skeleton"), cmp(final, R$current_10, "final", "current_10")))

# ---- nested: for S = 2022..2025, use only terms that passed on scored seasons before S ----
sgn <- lapply(names(TERMS), function(k) { o <- TERMS[[k]][1]; rhs <- if (SKEL[[o]] == "1") TERMS[[k]][2] else paste(SKEL[[o]], "+", TERMS[[k]][2])
  setNames(sapply(SCORED, function(S) coef(wf(o, rhs, S)$fit)[[TERMS[[k]][3]]]), SCORED) }); names(sgn) <- names(TERMS)
hit_of <- function(d) { p <- parts(d); sum(p$h) / sum(p$n) }
pick <- function(S) { prior <- SCORED[SCORED < S]
  names(TERMS)[sapply(names(TERMS), function(k) { o <- TERMS[[k]][1]; a <- RT[[k]][RT[[k]]$season %in% prior, ]; b <- R$skeleton[R$skeleton$season %in% prior, ]
    g <- 1000 * (dev_i(b[[o]], b[[lcol[[o]]]]) - dev_i(a[[o]], a[[lcol[[o]]]])); bys <- tapply(g, a$season, mean)
    all(sign(sgn[[k]][as.character(prior)]) == as.numeric(TERMS[[k]][4])) && mean(g) > 0 && mean(bys > 0) > 0.5 && hit_of(a) >= hit_of(b) })] }
NS <- 2022:2025; picks <- lapply(setNames(NS, NS), pick)
cat("\n=== 4. Nested check: terms that had passed before each season ===\n"); for (S in NS) cat(S, ":", if (length(picks[[as.character(S)]])) paste(picks[[as.character(S)]], collapse = "; ") else "none", "\n")
nested <- bind_rows(lapply(NS, function(S) with_terms(S, picks[[as.character(S)]]))) |> filter(top)
sub <- function(d) d[d$season %in% NS, ]
BOOT <- NULL
show(bind_rows(summ(sub(R$current_recipe), "current_recipe 2022-25"), summ(sub(R$skeleton), "skeleton 2022-25"), summ(sub(final), "final 2022-25"), summ(nested, "nested 2022-25")))
show(bind_rows(cmp(nested, sub(R$current_recipe), "nested", "current_recipe"), cmp(nested, sub(R$skeleton), "nested", "skeleton"), cmp(sub(final), sub(R$current_recipe), "final", "current_recipe")))

# ---- context and rows added after the main results ----
BOOT <- NULL
skel3 <- bind_rows(lapply(SCORED, function(S) { L <- setNames(lapply(OUT, function(o) wf(o, SKEL[[o]], S, window = 3, fe = FALSE)$mu), OUT); te <- D[D$season == S, ]
  te |> transmute(season, week, game_id, posteam, top, fpts, xp_attempts, att_039, att_4049, att_50, l_xp = L$xp_attempts, l039 = L$att_039, l4049 = L$att_4049, l50 = L$att_50,
                  proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp)) })) |> filter(top)
decm <- bind_rows(lapply(SCORED, function(S) { forms <- SKEL; forms[["att_039"]] <- paste(forms[["att_039"]], "+ exp_margin"); L <- ranges(forms, S); m <- decision(S); L[names(m)] <- m; te <- D[D$season == S, ]
  te |> transmute(season, week, game_id, posteam, top, fpts, xp_attempts, att_039, att_4049, att_50, l_xp = L$xp_attempts, l039 = L$att_039, l4049 = L$att_4049, l50 = L$att_50,
                  proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp)) })) |> filter(top)
lt <- readRDS("t25_tg.rds") |> select(game_id, posteam, ppg_pre)
base <- R$skeleton |> left_join(lt, by = c("game_id", "posteam"))
lg <- sapply(SCORED, function(S) mean(D$fpts[D$season < S & D$season >= S - 3 & D$top])); names(lg) <- SCORED
ppg <- base |> mutate(proj = ifelse(is.na(ppg_pre), lg[as.character(season)], ppg_pre)); lgv <- base |> mutate(proj = lg[as.character(season)])
cat("\n=== 5. Context (added after the main results) ===\n")
show(bind_rows(summ(lgv, "league average (last 3 seasons)"), summ(ppg, "kicker's points per game"), summ(R$current_recipe, "current_recipe"), summ(skel3, "skeleton, fit on 3 seasons"),
               summ(R$skeleton, "skeleton, all earlier seasons"), summ(final, "final"), summ(R$decision, "decision"), summ(decm, "decision + expected margin")) |> select(version, hit, mse, bias, starts_with("err")))
show(bind_rows(cmp(R$skeleton, skel3, "skeleton, all earlier seasons", "skeleton, fit on 3 seasons"), cmp(skel3, R$current_recipe, "skeleton, fit on 3 seasons", "current_recipe"),
               cmp(R$current_recipe, ppg, "current_recipe", "points per game"), cmp(final, ppg, "final", "points per game"),
               cmp(decm, final, "decision + expected margin", "final"), cmp(decm, R$current_recipe, "decision + expected margin", "current_recipe")))
# attempts error of the decision version vs skeleton, by range
dg <- function(o) { a <- R$decision; b <- R$skeleton; g <- 1000 * (dev_i(b[[o]], b[[lcol[[o]]]]) - dev_i(a[[o]], a[[lcol[[o]]]])); bys <- tapply(g, a$season, mean)
  c(gain = mean(g), h1 = mean(g[a$season <= 2021]), h2 = mean(g[a$season >= 2022]), seasons = sum(bys > 0)) }
cat("\nDecision vs skeleton, attempts gain: 40-49", round(dg("att_4049"), 2), "| 50+", round(dg("att_50"), 2), "\n")
# expected margin: by season, and how much the final version moves projections
em <- RT[["0-39 + expected margin"]]; p1 <- parts(em); p0 <- parts(R$skeleton)
cat("Expected margin, hit rate change by season:", paste(round(tapply(p1$h, p1$season, sum) / tapply(p1$n, p1$season, sum) - tapply(p0$h, p0$season, sum) / tapply(p0$n, p0$season, sum), 4), collapse = " "), "\n")
cat("margin weight by fold:", paste(round(sgn[["0-39 + expected margin"]], 4), collapse = " "), "\n")
cat("final vs current recipe: mean |projection change|", round(mean(abs(final$proj - R$current_recipe$proj)), 3), " max", round(max(abs(final$proj - R$current_recipe$proj)), 2),
    "; sd of projections: current", round(sd(R$current_recipe$proj), 3), " final", round(sd(final$proj), 3), " skeleton", round(sd(R$skeleton$proj), 3), "\n")
saveRDS(list(final = final, nested = nested, picks = picks, skel3 = skel3, decm = decm), "t29_more.rds")

# ======================= PART 4 (t29_extra.R): independent checks and one added row =======================
suppressMessages({library(dplyr); library(tidyr); library(readr)})
src <- readLines("t29_test.R"); eval(parse(text = src[1:(grep("^# ---------- 1. versions", src) - 1)]))
res <- readRDS("t29_results.rds"); R <- res$R; more <- readRDS("t29_more.rds"); set.seed(20261006)
# independent recomputation of hit rate and squared error for two versions (plain loops, no shared helper)
indep <- function(d) { h <- 0; n <- 0
  for (s in unique(d$season)) for (w in unique(d$week[d$season == s])) { g <- d[d$season == s & d$week == w, ]
    if (nrow(g) > 1) for (i in 1:(nrow(g) - 1)) for (j in (i + 1):nrow(g)) if (g$fpts[i] != g$fpts[j]) { n <- n + 1
      if (g$proj[i] == g$proj[j]) h <- h + 0.5 else if ((g$proj[i] > g$proj[j]) == (g$fpts[i] > g$fpts[j])) h <- h + 1 } }
  c(hit = h / n, pairs = n, mse = mean((d$fpts - d$proj)^2)) }
cat("independent check, skeleton:", round(indep(R$skeleton), 4), "| current recipe:", round(indep(R$current_recipe), 4), "\n")
# manual refit of one fold (skeleton 50+, season 2024) without the helper
tr <- D[D$season < 2024 & D$top, ]; f <- glm(att_50 ~ is_enclosed + krate_40plus + is_enclosed:krate_50 + factor(season), poisson, tr)
te <- D[D$season == 2024 & D$top, ]; b <- coef(f); xb <- function(d) b[["is_enclosed"]] * d$is_enclosed + b[["krate_40plus"]] * d$krate_40plus + b[["is_enclosed:krate_50"]] * d$is_enclosed * d$krate_50
cal <- tr[tr$season >= 2021, ]; mu <- exp(xb(te)) * sum(cal$att_50) / sum(exp(xb(cal)))
cat("manual fold check (skeleton 50+, 2024): max |difference| from the helper:", signif(max(abs(mu - R$skeleton$l50[R$skeleton$season == 2024])), 3), "\n")
# weights of the last fold (fit on 2016-2024)
for (o in OUT) { f <- wf(o, if (o == "att_039") paste(SKEL[[o]], "+ exp_margin") else SKEL[[o]], 2025)$fit; ct <- summary(f)$coefficients; ct <- ct[!grepl("^fs|Intercept", rownames(ct)), , drop = FALSE]
  if (nrow(ct)) print(round(ct[, 1:3, drop = FALSE], 4)) }
# added after the results: 0-39 model with expected margin fit on the 3 seasons before only (recent weight)
rec <- bind_rows(lapply(SCORED, function(S) { L <- ranges(SKEL, S); L$att_039 <- wf("att_039", "implied_team_total + I(implied_team_total^2) + exp_margin", S, window = 3, fe = FALSE)$mu; te <- D[D$season == S, ]
  te |> transmute(season, week, game_id, posteam, top, fpts, xp_attempts, att_039, att_4049, att_50, l_xp = L$xp_attempts, l039 = L$att_039, l4049 = L$att_4049, l50 = L$att_50,
                  proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp)) })) |> filter(top)
w3 <- sapply(SCORED, function(S) coef(wf("att_039", "implied_team_total + I(implied_team_total^2) + exp_margin", S, window = 3, fe = FALSE)$fit)[["exp_margin"]])
cat("\nmargin weight, 3-season window, by fold:", paste(round(w3, 4), collapse = " "), "\n")
show(bind_rows(summ(more$final, "final (margin weight pooled)"), summ(rec, "margin weight from last 3 seasons")) |> select(version, hit, mse, err_039, starts_with("h2")))
show(bind_rows(cmp(rec, more$final, "margin weight from last 3 seasons", "final"), cmp(rec, R$skeleton, "margin weight from last 3 seasons", "skeleton")))
