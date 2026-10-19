# #30 follow-up to #29 (2026-10-06, descriptive): why the decision version predicts points better without ranking better,
# and the literal production model against the new versions on 2026 weeks 1-4. Nothing here was pre-registered.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
src <- readLines("t29_test.R"); eval(parse(text = src[1:(grep("^# ---------- 1. versions", src) - 1)]))
res <- readRDS("t29_results.rds"); R <- res$R; more <- readRDS("t29_more.rds"); final <- more$final; decm <- more$decm; set.seed(20261006)
P <- D |> select(game_id, posteam, p_039, p_4049, p_50, p_xp)
# ---- A1. pairs the two versions order differently ----
disagree <- function(a, b, la, lb) { n <- 0; dis <- 0; a_right <- 0; wk <- paste(a$season, a$week)
  for (w in unique(wk)) { ga <- a[wk == w, ]; gb <- b[wk == w, ]; da <- outer(ga$fpts, ga$fpts, "-"); ok <- upper.tri(da) & da != 0
    sa <- sign(outer(ga$proj, ga$proj, "-"))[ok]; sb <- sign(outer(gb$proj, gb$proj, "-"))[ok]; st <- sign(da[ok]); d <- sa != sb
    n <- n + sum(ok); dis <- dis + sum(d); a_right <- a_right + sum(sa[d] == st[d]) }
  cc <- cor(a$proj, b$proj); tibble(version = la, vs = lb, pairs = n, ordered_differently = dis, share = dis / n, first_right_in_those = a_right / dis, corr_of_projections = cc) }
cat("=== A1. Pairs ordered differently ===\n")
show(bind_rows(disagree(R$decision, R$skeleton, "decision", "skeleton"), disagree(decm, final, "decision + margin", "final"), disagree(final, R$current_recipe, "final", "current recipe"),
               disagree(R$skeleton, R$current_recipe, "skeleton", "current recipe"), disagree(decm, R$current_recipe, "decision + margin", "current recipe")))
# ---- A2. squared error split: week level vs within week ----
split_mse <- function(d, label) { e <- d$fpts - d$proj; wk <- paste(d$season, d$week); m <- ave(e, wk)
  ep <- d$proj - ave(d$proj, wk); ea <- d$fpts - ave(d$fpts, wk)
  tibble(version = label, mse = mean(e^2), week_level_part = mean(m^2), within_week_part = mean((e - m)^2), sd_proj_within_week = sd(ep), within_week_corr = cor(ep, ea), slope_actual_on_proj = coef(lm(ea ~ ep))[[2]]) }
cat("\n=== A2. Squared error: week-level part and within-week part ===\n")
VV <- list(`current recipe` = R$current_recipe, skeleton = R$skeleton, final = final, decision = R$decision, `decision + margin` = decm)
show(bind_rows(lapply(names(VV), function(k) split_mse(VV[[k]], k))))
wboot <- function(a, b, la, lb, B = 2000) { wk <- paste(a$season, a$week); uw <- unique(wk); f <- function(d) { e <- d$fpts - d$proj; m <- ave(e, wk); cbind(tapply((e - m)^2, wk, sum)[uw], tapply(m^2, wk, sum)[uw], tapply(e, wk, length)[uw]) }
  A <- f(a); Bm <- f(b); idx <- replicate(B, sample(length(uw), replace = TRUE))
  dw <- apply(idx, 2, function(i) (sum(A[i, 1]) - sum(Bm[i, 1])) / sum(A[i, 3])); dl <- apply(idx, 2, function(i) (sum(A[i, 2]) - sum(Bm[i, 2])) / sum(A[i, 3]))
  ca <- function(d) { ep <- d$proj - ave(d$proj, wk); ea <- d$fpts - ave(d$fpts, wk); cbind(tapply(ep * ea, wk, sum)[uw], tapply(ep^2, wk, sum)[uw], tapply(ea^2, wk, sum)[uw]) }
  Ca <- ca(a); Cb <- ca(b); dc <- apply(idx, 2, function(i) sum(Ca[i, 1]) / sqrt(sum(Ca[i, 2]) * sum(Ca[i, 3])) - sum(Cb[i, 1]) / sqrt(sum(Cb[i, 2]) * sum(Cb[i, 3])))
  tibble(version = la, vs = lb, within_week_change = (sum(A[, 1]) - sum(Bm[, 1])) / sum(A[, 3]), within_share_better = mean(dw < 0), week_level_change = (sum(A[, 2]) - sum(Bm[, 2])) / sum(A[, 3]), level_share_better = mean(dl < 0),
         within_corr_change = sum(Ca[, 1]) / sqrt(sum(Ca[, 2]) * sum(Ca[, 3])) - sum(Cb[, 1]) / sqrt(sum(Cb[, 2]) * sum(Cb[, 3])), corr_share_better = mean(dc > 0)) }
show(bind_rows(wboot(R$decision, R$skeleton, "decision", "skeleton"), wboot(decm, final, "decision + margin", "final"), wboot(final, R$current_recipe, "final", "current recipe"),
               wboot(decm, R$current_recipe, "decision + margin", "current recipe"), wboot(R$skeleton, R$current_recipe, "skeleton", "current recipe")))
# ---- A3. which range carries the decision version's gain ----
swap <- function(use4049, use50) { d <- R$skeleton |> left_join(P, by = c("game_id", "posteam"))
  if (use4049) d$l4049 <- R$decision$l4049; if (use50) d$l50 <- R$decision$l50
  d$proj <- projected_points(d$l_xp, d$l039, d$l4049, d$l50, d$p_039, d$p_4049, d$p_50, d$p_xp); d }
stopifnot(all(R$decision$game_id == R$skeleton$game_id), max(abs(swap(TRUE, TRUE)$proj - R$decision$proj)) < 1e-9)
BOOT <- NULL
cat("\n=== A3. Decision version one range at a time (vs skeleton) ===\n")
show(bind_rows(cmp(swap(TRUE, FALSE), R$skeleton, "decision 40-49 only", "skeleton"), cmp(swap(FALSE, TRUE), R$skeleton, "decision 50+ only", "skeleton"), cmp(R$decision, R$skeleton, "decision both", "skeleton")))
# spread of the long-attempt predictions, and how much of the projection's spread they are
sp <- function(d) c(sd_l4049 = sd(d$l4049), sd_l50 = sd(d$l50), sd_l039 = sd(d$l039), sd_lxp = sd(d$l_xp))
cat("spread of expected attempts (sd): skeleton", round(sp(R$skeleton), 3), "| decision", round(sp(R$decision), 3), "| current", round(sp(R$current_recipe), 3), "\n")
# calibration of 50+ attempts by fifth of predicted 50+ attempts
calib <- function(d, label) d |> mutate(q = ntile(l50, 5)) |> group_by(q) |> summarise(pred = mean(l50), actual = mean(att_50), .groups = "drop") |> mutate(version = label)
cat("50+ attempts, predicted vs actual by fifth of prediction:\n"); print(as.data.frame(bind_rows(calib(R$skeleton, "skeleton"), calib(R$decision, "decision"), calib(R$current_recipe, "current")) |>
  mutate(cell = sprintf("%.2f / %.2f", pred, actual)) |> select(version, q, cell) |> pivot_wider(names_from = q, values_from = cell)), right = FALSE)

# ---- B. 2026 weeks 1-4: the production models themselves against the new versions ----
d26 <- readRDS("../t30/d2026.rds") |> mutate(top = top16pre, fpts = actual_points, att_tot = att_039 + att_4049 + att_50, att_40p = att_4049 + att_50,
                                              exp_margin = 2 * implied_team_total - total_line)
vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE) |> filter(top16pre)
prodfit <- function(forms) { L <- lapply(OUT, function(o) as.numeric(predict(glm(as.formula(paste(o, "~", forms[[o]])), poisson, vol), d26, type = "response"))); names(L) <- OUT
  d26 |> transmute(season, week, game_id, posteam, top, fpts, xp_attempts, att_039, att_4049, att_50, l_xp = L$xp_attempts, l039 = L$att_039, l4049 = L$att_4049, l50 = L$att_50,
                   proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp)) |> filter(top) }
D <- bind_rows(D |> mutate(fs = as.character(fs)), d26 |> mutate(fs = "2026") |> select(all_of(names(D)))) |> mutate(fs = factor(fs))
N26 <- list(`production model now (fit 2023-25)` = prodfit(CUR), `production before #27` = prodfit(OLD), skeleton = build(2026, "skeleton") |> filter(top), final = with_terms(2026, "0-39 + expected margin") |> filter(top),
            decision = build(2026, "decision") |> filter(top))
N26[["decision + margin"]] <- { forms <- SKEL; forms[["att_039"]] <- paste(forms[["att_039"]], "+ exp_margin"); L <- ranges(forms, 2026); m <- decision(2026); L[names(m)] <- m; te <- D[D$season == 2026, ]
  te |> transmute(season, week, game_id, posteam, top, fpts, xp_attempts, att_039, att_4049, att_50, l_xp = L$xp_attempts, l039 = L$att_039, l4049 = L$att_4049, l50 = L$att_50,
                  proj = projected_points(l_xp, l039, l4049, l50, p_039, p_4049, p_50, p_xp)) |> filter(top) }
cat("\n=== B. 2026 weeks 1-4 (", nrow(N26[[1]]), "top-16 kicker-games,", sum(parts(N26[[1]])$n), "pairs ) ===\n")
show(bind_rows(lapply(names(N26), function(k) summ(N26[[k]], k))) |> select(version, hit, mse, bias, starts_with("err")))
BOOT <- NULL; o1 <- N26[[1]]; ord <- function(d) d[match(paste(o1$game_id, o1$posteam), paste(d$game_id, d$posteam)), ]
show(bind_rows(lapply(names(N26)[-1], function(k) cmp(ord(N26[[k]]), o1, k, "production model now"))) |> select(version, hit_change, hit_lo, hit_hi, share_better, mse_change, mse_share_better))
saveRDS(N26, "t30_2026.rds")
suppressMessages({library(dplyr); library(tidyr); library(readr)})
src <- readLines("t30_followup.R"); i1 <- grep("^split_mse <- ", src); i2 <- grep("^show\\(bind_rows\\(wboot", src)
s29 <- readLines("t29_test.R"); eval(parse(text = s29[1:(grep("^# ---------- 1. versions", s29) - 1)]))
res <- readRDS("t29_results.rds"); R <- res$R; more <- readRDS("t29_more.rds"); final <- more$final; decm <- more$decm; set.seed(20261006)
eval(parse(text = src[i1:(i2 - 1)]))
out <- bind_rows(wboot(final, R$skeleton, "final (adds expected margin)", "skeleton"), wboot(R$total_split, R$skeleton, "total + split", "skeleton"), wboot(R$decision_free, R$skeleton, "decision, free exponent", "skeleton"),
                 wboot(R$current_10, R$current_recipe, "current, ten seasons", "current recipe"), wboot(R$skeleton, more$skel3, "skeleton all seasons", "skeleton 3 seasons"),
                 wboot(R$current_recipe, R$old_recipe, "current recipe", "before #27"), wboot(res$RT[["50+ + coach long-range FG rate"]], R$skeleton, "skeleton + coach long (50+)", "skeleton"),
                 wboot(decm, R$decision, "decision + margin", "decision"))
show(out |> select(version, vs, within_corr_change, corr_share_better, within_week_change, within_share_better))
