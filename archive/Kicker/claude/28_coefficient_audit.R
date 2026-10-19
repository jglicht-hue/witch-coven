# #28 (exploratory): do the production coefficients hold on other seasons? Descriptive only - no adoption test.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
fix <- function(x) recode(x, OAK = "LV", SD = "LAC", STL = "LA", .default = x)
if (!file.exists("t28_xp.rds")) {
  xp <- bind_rows(lapply(2016:2025, function(y) readRDS(sprintf("data/raw/play_by_play_%d.rds", y))[, c("game_id", "posteam", "extra_point_attempt", "season_type")] |>
    filter(extra_point_attempt == 1, season_type == "REG") |> mutate(posteam = fix(posteam)) |> count(game_id, posteam, name = "xp_attempts")))
  saveRDS(xp, "t28_xp.rds") }
xp <- readRDS("t28_xp.rds")
inp <- bind_rows(lapply(2016:2025, function(s) readRDS(sprintf("t26_inputs_%d.rds", s))))
lt <- readRDS("t25_tg.rds") |> select(game_id, posteam, att_039, att_4049, att_50, fpts, lt_top = top16pre)
vol <- read_csv("data/volume_model_table.csv", show_col_types = FALSE)
d <- inp |> inner_join(lt, by = c("game_id", "posteam")) |> left_join(xp, by = c("game_id", "posteam")) |> mutate(xp_attempts = replace_na(xp_attempts, 0)) |>
  left_join(vol |> select(game_id, posteam, v_top = top16pre, v_xp = xp_attempts), by = c("game_id", "posteam")) |>
  mutate(top = if_else(season >= 2023, v_top, lt_top), fs = factor(season))
cat("rows", nrow(d), "; xp matches production on 2023-25:", all(d$xp_attempts[d$season >= 2023] == d$v_xp[d$season >= 2023]), "; top16 rows 2016-22:", sum(d$top & d$season <= 2022), " 2023-25:", sum(d$top & d$season >= 2023), "\n")
F <- c(xp_attempts = "implied_team_total + redzone_td_rate_trail8 + redzone_trips_per_game_trail8 + opp_redzone_td_rate_allowed_trail8 + coach_long_fg_rate",
       att_039 = "implied_team_total + I(implied_team_total^2) + opp_redzone_td_rate_allowed_trail8 + is_enclosed + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
       att_4049 = "is_enclosed + krate_4049 + kshare_4049_hlall + is_enclosed:krate_4049 + coach_long_fg_rate + is_enclosed:coach_long_fg_rate",
       att_50 = "is_enclosed + krate_40plus + is_enclosed:krate_50")
SETS <- list(`A prod table 23-25 (top16)` = list(vol |> filter(top16pre), FALSE),
             `B live inputs 23-25 (top16)` = list(d |> filter(season >= 2023, top), TRUE),
             `C 2016-22 (top16)` = list(d |> filter(season <= 2022, top), TRUE),
             `D 2016-25 (top16)` = list(d |> filter(top), TRUE),
             `E 2016-25 (all kickers)` = list(d, TRUE))
res <- bind_rows(lapply(names(F), function(o) bind_rows(lapply(names(SETS), function(k) { dd <- SETS[[k]][[1]]
  f <- glm(as.formula(paste(o, "~", F[[o]], if (SETS[[k]][[2]]) "+ fs" else "")), poisson, dd |> mutate(fs = if ("fs" %in% names(dd)) droplevels(fs) else factor(season)))
  ct <- summary(f)$coefficients; ct <- ct[!grepl("^fs|Intercept", rownames(ct)), , drop = FALSE]
  tibble(model = o, set = k, n = nrow(dd), term = rownames(ct), est = ct[, 1], se = ct[, 2]) }))))
wide <- res |> mutate(cell = sprintf("%+.2f (%.2f)", est, se)) |> select(model, term, set, cell) |> pivot_wider(names_from = set, values_from = cell)
print(as.data.frame(wide), width = 250, right = FALSE)
# flags: production vs 2016-22
fl <- res |> filter(set %in% c("A prod table 23-25 (top16)", "C 2016-22 (top16)")) |> mutate(s = ifelse(grepl("^A", set), "A", "C")) |> select(model, term, s, est, se) |>
  pivot_wider(names_from = s, values_from = c(est, se)) |> mutate(z_diff = (est_A - est_C) / sqrt(se_A^2 + se_C^2), sign_flip = sign(est_A) != sign(est_C), z_C = est_C / se_C)
cat("\nProduction (A) vs 2016-22 (C): difference in standard errors, sign flips, and how clearly C differs from zero\n")
print(as.data.frame(fl |> transmute(model, term, A = round(est_A, 2), C = round(est_C, 2), z_diff = round(z_diff, 1), sign_flip, z_C = round(z_C, 1))), right = FALSE)
write_csv(res, "t28_audit.csv")
# era drift: attempts per team-game by season (all teams)
cat("\nAttempts per team-game by season (all teams)\n")
print(as.data.frame(d |> group_by(season) |> summarise(xp = mean(xp_attempts), a039 = mean(att_039), a4049 = mean(att_4049), a50 = mean(att_50), fpts = mean(fpts), dome = mean(is_enclosed)) |> mutate(across(-season, ~ round(.x, 3)))))
