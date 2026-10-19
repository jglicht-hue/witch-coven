# Weekly report: the most accurate active kickers. Added 2026-09-29 (user request).
# Runs after 09b (it reads 09b's weekly file to know who is active). Part of run_all.R.
#
# WHAT IT MEASURES: each kicker's FG make rate against what a league-average kicker makes from the same
# distances ("expected"), over the model's data window (the current season and the 3 before it, regular
# season, games played so far). No fade, no dome adjustment (user decision 2026-09-29: a kicker who kicks
# in domes now will keep doing so, so that part of his edge is real for projection). Blocked kicks count
# as misses (they score -1).
#   expected make chance = league-wide logistic fit of make on distance (cubic), over the same window
#   edge_pts   = (makes - expected makes) / attempts, in percentage points
#   edge_low80 = edge minus 1.2816 standard errors (binomial, from the expected chances): the lower end of
#                an 80% interval - how sure we are he's above league (small samples give low values)
#   truly_good = edge_pts >= 5 on >= 20 attempts (definition agreed 2026-09-29; to-do #19). Informational
#                until the #19 test decides whether it should change the projections.
# ACTIVE = the kicker assumed for each team in data/weekly_projections_latest.csv (whoever last kicked
# for the team - check injuries and signings elsewhere). Ranked among active kickers with >= 20 attempts;
# the top 10 are flagged. Kickers under 20 attempts are listed at the bottom, unranked.
#
# Writes data/accuracy_report_latest.csv (and a dated copy data/accuracy_report_<season>_wk<NN>.csv).

suppressMessages({library(dplyr); library(readr)})
source("00_nflverse_data.R")

MIN_ATT <- 20; GOOD_EDGE <- 5; TOP_N <- 10
wk_path <- "data/weekly_projections_latest.csv"
if (!file.exists(wk_path)) stop("Run 09b_weekly_projections.R first (needs ", wk_path, ").")
wkly <- read_csv(wk_path, show_col_types = FALSE)
season <- wkly$season[1]; week <- wkly$week[1]
active <- wkly |> distinct(kicker_player_id, team)

pbp <- load_pbp_data((season - 3):season)
fg <- pbp |> filter(field_goal_attempt == 1, season_type == "REG", !is.na(kicker_player_id), !is.na(kick_distance)) |>
  transmute(season, week, kicker_player_id, kicker_player_name, dist = kick_distance,
            made = as.integer(field_goal_result == "made"))
fit <- glm(made ~ poly(dist, 3), binomial, fg)
fg$p_exp <- fitted(fit)

rep <- fg |> group_by(kicker_player_id) |>
  summarise(kicker = last(kicker_player_name), fg_made = sum(made), fg_att = n(), exp_made = sum(p_exp),
            var_made = sum(p_exp * (1 - p_exp)), avg_distance = mean(dist),
            fg50_made = sum(made[dist >= 50]), fg50_att = sum(dist >= 50),
            season_made = sum(made[season == !!season]), season_att = sum(season == !!season), .groups = "drop") |>
  inner_join(active, by = "kicker_player_id") |>
  mutate(make_pct = 100 * fg_made / fg_att, expected_pct = 100 * exp_made / fg_att,
         edge_pts = make_pct - expected_pct, edge_low80 = edge_pts - 100 * qnorm(0.9) * sqrt(var_made) / fg_att,
         eligible = fg_att >= MIN_ATT, truly_good = eligible & edge_pts >= GOOD_EDGE)
rep <- bind_rows(rep |> filter(eligible) |> arrange(desc(edge_pts)) |> mutate(rank = row_number()),
                 rep |> filter(!eligible) |> arrange(desc(edge_pts)) |> mutate(rank = NA_integer_)) |>
  mutate(top10 = !is.na(rank) & rank <= TOP_N, season = !!season, week = !!week,
         window = paste0(season - 3, "-", season, " regular season through week ", max(fg$week[fg$season == season])),
         created = format(Sys.time(), "%Y-%m-%d %H:%M %Z")) |>
  transmute(season, week, rank, top10, truly_good, kicker, team, kicker_player_id, fg_made, fg_att, make_pct, expected_pct,
            edge_pts, edge_low80, avg_distance, fg50_made, fg50_att, season_made, season_att, eligible, window, created) |>
  mutate(across(c(make_pct, expected_pct, edge_pts, edge_low80, avg_distance), ~ round(.x, 1)))

write_csv(rep, "data/accuracy_report_latest.csv")
write_csv(rep, sprintf("data/accuracy_report_%d_wk%02d.csv", season, week))
message("Accuracy report: ", sum(rep$eligible), " active kickers with >= ", MIN_ATT, " attempts, ",
        sum(rep$truly_good), " truly good; window ", rep$window[1])
print(as.data.frame(rep |> filter(top10) |> select(rank, kicker, team, fg_made, fg_att, make_pct, expected_pct, edge_pts, edge_low80, truly_good)))
