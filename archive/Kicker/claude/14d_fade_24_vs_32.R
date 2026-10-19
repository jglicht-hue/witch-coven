# Fade 24 vs 32 games for the FG make chances (weight 5). Added 2026-09-29. Not part of the weekly run.
# Rule (set with the user before results): switch to 32 unless 24 beats it on pre-game top-16 pairwise hit
# rate in >= 7 of 10 seasons (2016-2025). Reported: week-block bootstrap, all-kicker hit rate, Brier.
# Reuses data/fade_prior_inputs.rds (14c) and adds fade-32 records computed the same way.
suppressMessages({library(dplyr); library(tidyr)})
source("00_nflverse_data.R"); source("09_weekly_inputs.R")
set.seed(20260929)
d <- readRDS("data/fade_prior_inputs.rds"); d$top16pre <- coalesce(d$top16pre, FALSE)
PTS <- c("039", "4049", "50"); base_cols <- c(outer(c("att_", "mk_"), PTS, paste0))
d$ord <- d$season * 100 + d$week
st_all <- list()
for (S in sort(unique(d$season))) {
  pbp <- load_pbp_data((S - 3):S)
  kg <- pbp |> filter(field_goal_attempt == 1, !is.na(kicker_player_id)) |>
    mutate(made = as.integer(field_goal_result == "made"), r = case_when(kick_distance <= 39 ~ "039", kick_distance <= 49 ~ "4049", TRUE ~ "50")) |>
    group_by(season, week, game_id, posteam, kicker_player_id, r) |> summarise(att = n(), mk = sum(made, na.rm = TRUE), .groups = "drop") |>
    pivot_wider(names_from = r, values_from = c(att, mk), values_fill = 0) |> mutate(ord = season * 100 + week) |> arrange(kicker_player_id, ord)
  lg <- kg |> group_by(kicker_player_id) |> mutate(across(all_of(base_cols), ~ .running_after(.x, 32), .names = "h32_{.col}")) |> ungroup()
  ix <- which(d$season == S)
  st <- .state_before(lg, d$kicker_player_id[ix], d$ord[ix], paste0("h32_", base_cols))
  # sanity: fade 12 recomputed here must match the cache
  lg12 <- kg |> group_by(kicker_player_id) |> mutate(across(all_of(base_cols), ~ .running_after(.x, 12), .names = "h12_{.col}")) |> ungroup()
  st12 <- .state_before(lg12, d$kicker_player_id[ix], d$ord[ix], paste0("h12_", base_cols))
  stopifnot(max(abs(st12 - as.matrix(d[ix, paste0("h12_", base_cols)]))) < 1e-9)
  st_all[[as.character(S)]] <- list(ix = ix, st = st); rm(pbp); gc()
}
for (c in paste0("h32_", base_cols)) d[[c]] <- NA_real_
for (x in st_all) for (c in colnames(x$st)) d[[c]][x$ix] <- x$st[, c]
proj <- function(f, w = 5) { p <- setNames(lapply(PTS, function(r) { m <- d[[paste0("h", f, "_mk_", r)]]; n <- d[[paste0("h", f, "_att_", r)]]; L <- d[[paste0("lg_", r)]]; (m + w * L) / (n + w) }), PTS)
  list(p = p, pr = with(d, lambda_xp * p_xp + lambda_039 * (p[["039"]] * 4 - 1) + lambda_4049 * (p[["4049"]] * 5 - 1) + lambda_50 * (p[["50"]] * 6 - 1))) }
wk <- paste(d$season, d$week); WEEKS <- sort(unique(wk))
pw <- function(pr, ix) { o <- sapply(split(ix, factor(wk[ix], levels = WEEKS)), function(j) { if (length(j) < 2) return(c(0, 0))
  dp <- outer(pr[j], pr[j], "-"); da <- outer(d$actual_points[j], d$actual_points[j], "-"); u <- upper.tri(dp) & da != 0
  c(sum((sign(dp[u]) == sign(da[u])) + 0.5 * (dp[u] == 0)), sum(u)) }); o }
brier <- function(p) 1000 * sum(sapply(PTS, function(r) sum(d[[paste0("g_mk_", r)]] * (1 - p[[r]])^2 + (d[[paste0("g_att_", r)]] - d[[paste0("g_mk_", r)]]) * p[[r]]^2))) /
  sum(d$g_att_039 + d$g_att_4049 + d$g_att_50)
t16 <- which(d$top16pre); allx <- seq_len(nrow(d)); ws <- as.integer(substr(WEEKS, 1, 4))
res <- lapply(c("12", "24", "32"), function(f) { x <- proj(f); list(f = f, a16 = pw(x$pr, t16), aall = pw(x$pr, allx), brier = brier(x$p)) }); names(res) <- c("12", "24", "32")
summ <- bind_rows(lapply(res, function(r) tibble(fade = r$f, hit16 = sum(r$a16[1, ]) / sum(r$a16[2, ]), hit_all = sum(r$aall[1, ]) / sum(r$aall[2, ]), brier_x1000 = r$brier)))
print(as.data.frame(summ |> mutate(across(where(is.double), ~ round(.x, 4)))))
cmp <- function(a, b) { d16 <- res[[a]]$a16[1, ] - res[[b]]$a16[1, ]; n16 <- res[[b]]$a16[2, ]; dall <- res[[a]]$aall[1, ] - res[[b]]$aall[1, ]; nall <- res[[b]]$aall[2, ]
  bt <- replicate(2000, { i <- sample(length(WEEKS), replace = TRUE); c(sum(d16[i]) / sum(n16[i]), sum(dall[i]) / sum(nall[i])) })
  seas <- tapply(d16, ws, sum) / tapply(n16, ws, sum)
  tibble(comparison = paste(a, "minus", b), diff16 = sum(d16) / sum(n16), boot16_lo = quantile(bt[1, ], .05), boot16_hi = quantile(bt[1, ], .95),
         share_not_better = mean(bt[1, ] <= 0), seasons_better = sum(seas > 0), diff_all = sum(dall) / sum(nall), share_all_not_better = mean(bt[2, ] <= 0)) }
cmps <- bind_rows(cmp("24", "32"), cmp("32", "12"), cmp("24", "12"))
print(as.data.frame(cmps |> mutate(across(where(is.double), ~ round(.x, 4)))))
seas_tab <- sapply(c("12", "24", "32"), function(f) round(tapply(res[[f]]$a16[1, ], ws, sum) / tapply(res[[f]]$a16[2, ], ws, sum), 4)); print(seas_tab)
winner <- if (cmps$seasons_better[1] >= 7) "24" else "32"
cat("\nRule: 24 better than 32 in", cmps$seasons_better[1], "of 10 seasons -> fade", winner, "\n")
readr::write_csv(bind_rows(summ, cmps) , "data/fade_24_vs_32.csv")
