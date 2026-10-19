suppressMessages({library(dplyr); library(tidyr); library(readr)})
source("09n_new_model.R"); source("09_weekly_inputs.R"); nm <- load_new_model()
pbp <- bind_rows(lapply(2023:2026, function(y) readRDS(sprintf("data/raw/play_by_play_%d.rds", y))))
sched <- readRDS("data/raw/games.rds") |> filter(season %in% 2023:2026)
x <- build_week_inputs(pbp, sched, 2026, 6, pregame_kicker_for_played = TRUE); lg <- attr(x, "league_averages")
x <- x |> filter(!is.na(kicker_player_id)) |> mutate(exp_margin = 2 * implied_team_total - total_line)
f <- read_csv("data/weekly_projections_latest.csv", show_col_types = FALSE)
R <- c("039","4049","50")
for (r in R) { a <- x[[paste0("a_", r)]]; b <- x[[paste0("b_", r)]]; x[[paste0("da_", r)]] <- a + b - 5; x[[paste0("dm_", r)]] <- a - 5 * lg[[r]]; x[[paste0("lg_", r)]] <- lg[[r]] }
x$N_all <- x$da_039 + x$da_4049 + x$da_50
make_p <- function(d, w_good = 5, w_bad = 5, dock = 0) {
  out <- lapply(setNames(R, R), function(r) { da <- d[[paste0("da_", r)]]; dm <- d[[paste0("dm_", r)]]; lg <- d[[paste0("lg_", r)]]
    good <- da > 1e-9 & dm / pmax(da, 1e-9) > lg; w <- ifelse(good, w_good, w_bad)
    p <- ifelse(da > 1e-9, (dm + w * lg) / (da + w), lg); pmin(pmax(p - dock / 100 * 10 / (d$N_all + 10), 0.01), 0.999) })
  new_model_make_chances(nm, data.frame(p_039 = out[["039"]], p_4049 = out[["4049"]], p_50 = out[["50"]], p_xp = d$p_xp, is_enclosed = d$is_enclosed)) }
pp <- function(lam, p) lam$lambda_xp * p$p_xp + lam$lambda_039 * (4 * p$p_039 - 1) + lam$lambda_4049 * (5 * p$p_4049 - 1) + lam$lambda_50 * (6 * p$p_50 - 1)
x$is_enclosed <- f$is_enclosed[match(x$posteam, f$team)]   # roof-unknown rows: use the file's blended share for this check
lam <- new_model_attempts(nm, x); base <- pp(lam, make_p(x))
fm <- f[match(x$posteam, f$team), ]; known <- !fm$roof_unknown
cat("reproduction vs file (roof-known rows):", sum(known), "rows, max |diff|", signif(max(abs(base[known] - fm$projected_points[known])), 3), "\n")
C <- list(A1 = list(w_good = 3, w_bad = 3), A2 = list(w_good = 2, w_bad = 2), B1 = list(w_bad = 2), B2 = list(w_bad = 3), B3 = list(w_bad = 20), C1 = list(dock = 1), C2 = list(dock = 2), C3 = list(dock = 3), E = list(w_bad = 2, dock = 2))
tab <- sapply(C, function(k) pp(lam, do.call(make_p, c(list(d = x), k))) - base)
out <- data.frame(kicker = x$kicker_player_name, team = x$posteam, N_all = round(x$N_all, 1), file = round(fm$projected_points, 2), round(tab, 2))
out <- out[order(-out$file), ]; out$rank_file <- seq_len(nrow(out))
for (k in names(C)) out[[paste0("rk_", k)]] <- rank(-(out$file + out[[k]]))
print(out[out$kicker %in% c("H.Mevis","N.Folk","T.Bass","C.Santos","C.Little","T.Smack","S.Shrader"), c("kicker","team","N_all","file", names(C))], row.names = FALSE)
cat("Mevis rank under each:", unlist(out[out$kicker == "H.Mevis", paste0("rk_", names(C))]), "\n")
cat("max |change| any kicker:", apply(abs(tab), 2, max) |> round(2), "\n")
