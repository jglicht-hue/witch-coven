# #37 (2026-10-06): a general dome bump, dome x accuracy in the chances for long kicks, and a proxy for unannounced retractable roofs.
# Run in the Kicker Wizerd chat as a one-off. No production script or model is changed. Log: claude/37_dome_bump_and_roof_proxy_log.md. Needs the #36 workspace.

# ===================== PART 1: t37.R =====================
# #37 (2026-10-06): (1) a general dome bump, (2) dome x accuracy in the chances for long kicks, (3) a proxy for unannounced retractable roofs.
# Checks were sent to the user before the results. Workspace only; no production script or model is changed.
s36 <- readLines("t36_test.R"); eval(parse(text = s36[1:(grep("^cat\\(\"=== base \\(final 31\\) ===", s36) - 1)]))
f <- with_p(base, padj(c("K1", "K4"))); BOOT <- NULL
# ---- 1. general dome bump: size = the model's dome-minus-outdoors miss in earlier tested seasons ----
d <- f |> left_join(D[c("game_id", "posteam", "is_enclosed")], by = c("game_id", "posteam")); res <- d$fpts - d$proj
bump <- sapply(SCORED, function(S) if (S == 2019) 0 else mean(res[d$season < S & d$is_enclosed == 1]) - mean(res[d$season < S & d$is_enclosed == 0])); names(bump) <- SCORED
shr <- sapply(SCORED, function(S) mean(d$is_enclosed[d$season < S])); shr[1] <- 0
mkb <- function(k) { g <- f; i <- match(d$season, SCORED); g$proj <- f$proj + k * bump[i] * (d$is_enclosed - shr[i]); g }
cat("=== 1. General dome bump ===\nbump by season (points, dome minus outdoors):", paste(SCORED, round(bump, 2), collapse = " | "), "\n")
B <- list(`full bump` = mkb(1), `half bump (not pre-stated)` = mkb(0.5)); se <- function(g, i) mean((g$fpts - g$proj)[i]^2)
for (k in names(B)) { g <- B[[k]]; cc <- cmp(g, f, k, "new + make shifts"); pa <- parts(g); pb <- parts(f); e <- pa$season <= 2021; dg <- dome_gap(g)
  cat(k, ": hit", round(cc$hit_change, 4), "(", cc$hit_share, ") wcorr", round(cc$wcorr_change, 4), "(", cc$wcorr_share, "; halves", round(wc(pa, which(e)) - wc(pb, which(e)), 4), round(wc(pa, which(!e)) - wc(pb, which(!e)), 4), ") mse", round(cc$mse_change, 4), "(", cc$mse_share, "; halves",
      round(se(g, g$season <= 2021) - se(f, f$season <= 2021), 4), round(se(g, g$season >= 2022) - se(f, f$season >= 2022), 4), ") | miss dome", round(dg[[1]], 3), "outdoors", round(dg[[2]], 3), "gap", round(dg[[3]], 3), "\n")
  cat("   squared error change by season:", paste(sapply(SCORED, function(s) round(se(g, g$season == s) - se(f, f$season == s), 3)), collapse = " "), "\n") }
cat("dome-minus-outdoors miss by season, new + make shifts:", paste(sapply(SCORED, function(s) round(mean(res[d$season == s & d$is_enclosed == 1]) - mean(res[d$season == s & d$is_enclosed == 0]), 2)), collapse = " "), "\n")
# ---- 2. dome x kicker accuracy in the chances for long kicks ----
s34 <- readLines("t34_test.R"); eval(parse(text = s34[grep("^build2 <- ", s34):(grep("^chrow <- ", s34) - 1)]))
INT <- "is_enclosed + krate_40plus + is_enclosed:krate_40plus"
cat("\n=== 2. Dome x kicker 40+ accuracy in the chances ===\n")
for (z in c("M", "L")) { ch <- BASE$ch; ch[z] <- INT; r <- build2(ch); cc <- cmp(r, base, z, "final 31"); pa <- parts(r); pb <- parts(base); e <- pa$season <= 2021
  co <- t(sapply(SCORED, function(S) chances(S, z, INT)$coef)); rownames(co) <- SCORED; g <- lapply(SCORED, function(S) chances(S, z, "1")$oos - chances(S, z, INT)$oos)
  cat("zone", z, if (z == "M") "(40-49)" else "(50+)", ": interaction weight by fold", round(co[, "is_enclosed:krate_40plus"], 2), "| chances gain", round(1000 * mean(unlist(g)), 2), "(", round(1000 * mean(unlist(g[SCORED <= 2021])), 2), "/", round(1000 * mean(unlist(g[SCORED >= 2022])), 2), ")",
      "| hit", round(cc$hit_change, 4), "(", cc$hit_share, ") wcorr", round(cc$wcorr_change, 4), "(", cc$wcorr_share, "; halves", round(wc(pa, which(e)) - wc(pb, which(e)), 4), round(wc(pa, which(!e)) - wc(pb, which(!e)), 4), ") mse", round(cc$mse_change, 4), "(", cc$mse_share, ")\n"); print(round(co, 2)) }
# raw: do accurate kickers get more chances indoors? all team-games 2016-2025, by thirds of 40+ accuracy
ta <- D[D$season <= 2025, ]; ta$acc3 <- cut(ta$krate_40plus, quantile(ta$krate_40plus, 0:3 / 3), include.lowest = TRUE, labels = c("low", "mid", "high")); ta$era <- ifelse(ta$season <= 2022, "2016-22", "2023-25")
cat("\nraw per game by venue and thirds of kicker 40+ accuracy (all team-games): 4th downs at opp 22-31 and 32-41, attempts by range, XP\n")
print(as.data.frame(ta |> group_by(dome = is_enclosed, acc3) |> summarise(n = n(), n4_M = mean(n4_M), n4_L = mean(n4_L), att_039 = mean(att_039), att_4049 = mean(att_4049), att_50 = mean(att_50), xp = mean(xp_attempts), implied = mean(implied_team_total), .groups = "drop") |> mutate(across(where(is.double), ~ round(.x, 3)))))
print(as.data.frame(ta |> group_by(era, dome = is_enclosed, acc3) |> summarise(n = n(), n4_M = mean(n4_M), att_4049 = mean(att_4049), n4_L = mean(n4_L), att_50 = mean(att_50), .groups = "drop") |> mutate(across(where(is.double), ~ round(.x, 3)))))
# ---- 3. roof proxy ----
g <- readRDS("data/raw/games.rds") |> filter(game_type == "REG", roof %in% c("open", "closed"), !grepl("Maracana", stadium)) |> mutate(closed = as.integer(roof == "closed"), month = as.integer(substr(gameday, 6, 7)), mg = ifelse(month == 9, "Sep", ifelse(month == 10, "Oct", ifelse(month == 11, "Nov", "Dec-Jan"))), st = ifelse(home_team == "SF", "ARI", home_team))
cat("\n=== 3. Roof ===\nclosed/games by season:", paste(sapply(2016:2026, function(s) paste0(s, " ", sum(g$closed[g$season == s]), "/", sum(g$season == s))), collapse = " | "), "\n")
OK <- c(2016:2019, 2021:2023); gg <- g[g$season %in% OK, ]   # 2020, 2024 and 2025 show no open roof at all in nflverse; at least two 2024 games are known to have been open
cat("seasons used:", paste(OK, collapse = ","), "| games", nrow(gg), "| closed", round(mean(gg$closed), 3), "\n")
print(as.data.frame(gg |> group_by(st) |> summarise(games = n(), closed = round(mean(closed), 2))))
x <- gg |> group_by(st, mg) |> summarise(v = paste0(round(mean(closed), 2), " (", n(), ")"), .groups = "drop"); print(as.data.frame(tidyr::pivot_wider(x, names_from = mg, values_from = v)[, c("st", "Sep", "Oct", "Nov", "Dec-Jan")]))
x2 <- gg |> group_by(mg) |> summarise(games = n(), closed = round(mean(closed), 2)); print(as.data.frame(x2))
brier <- function(test, train_seasons) { tr <- gg[gg$season %in% train_seasons, ]; te <- gg[gg$season %in% test, ]; lg <- 0.324
  a <- rep(lg, nrow(te)); b <- rep(mean(tr$closed), nrow(te)); sm <- function(k, key) { n <- tapply(tr$closed, tr[[key]], length); s <- tapply(tr$closed, tr[[key]], sum); function(v) { nn <- ifelse(is.na(n[v]), 0, n[v]); ss <- ifelse(is.na(s[v]), 0, s[v]); (ss + k * mean(tr$closed)) / (nn + k) } }
  tr$sm <- paste(tr$st, tr$mg); te$sm <- paste(te$st, te$mg); c1 <- sm(4, "st")(te$st); c2 <- sm(4, "sm")(te$sm)
  c(games = nrow(te), placeholder = mean((a - te$closed)^2), all_retractable = mean((b - te$closed)^2), by_stadium = mean((c1 - te$closed)^2), by_stadium_month = mean((c2 - te$closed)^2)) }
cat("\nBrier score (lower is better), each test season predicted from earlier usable seasons; shares blended with the all-stadium share as if 4 games were added:\n")
bt <- t(sapply(c(2019, 2021, 2022, 2023), function(s) brier(s, OK[OK < s]))); rownames(bt) <- c(2019, 2021, 2022, 2023); print(round(bt, 3)); cat("weighted over the four seasons:", round(colSums(bt[, -1] * bt[, 1]) / sum(bt[, 1]), 3), "\n")
saveRDS(list(bump = bump, gg = gg), "t37_results.rds")

# ===================== PART 2: t37b.R (weather text check) =====================
# #37 part 2: (a) can the play-by-play weather text recover open/closed where the schedule's roof field looks unfilled? (b) this week's roof-unknown games under stadium-by-month closed shares.
suppressMessages({library(dplyr); library(tidyr); library(readr)})
g <- readRDS("data/raw/games.rds") |> filter(game_type == "REG", roof %in% c("open", "closed"), !grepl("Maracana", stadium))
wx <- bind_rows(lapply(2016:2026, function(s) readRDS(sprintf("data/raw/play_by_play_%d.rds", s)) |> filter(season_type == "REG") |> distinct(game_id, weather, pbp_roof = roof, pbp_temp = temp, pbp_wind = wind)))
x <- g |> left_join(wx, by = "game_id") |> mutate(indoor_text = grepl("indoor|controlled|dome|roof closed|closed roof|n/a", weather, ignore.case = TRUE), has_temp = grepl("Temp: *[0-9]", weather), txt_temp = suppressWarnings(as.numeric(sub(".*Temp: *([0-9]+).*", "\\1", weather))),
                                         text_says = case_when(is.na(weather) | weather == "" ~ "no text", indoor_text ~ "indoors", has_temp ~ "outdoor conditions", TRUE ~ "other"))
cat("schedule roof vs weather text, by season group:\n"); x$grp <- ifelse(x$season %in% c(2020, 2024, 2025), "2020/2024/2025 (no open roofs in schedule)", ifelse(x$season == 2026, "2026", "other seasons")); print(table(x$grp, paste(x$roof, "|", x$text_says)))
cat("\nexamples, schedule says open (other seasons):\n"); print(head(x$weather[x$roof == "open" & x$grp == "other seasons"], 6)); cat("examples, schedule says closed (other seasons):\n"); print(head(unique(x$weather[x$roof == "closed" & x$grp == "other seasons"]), 8))
cat("\n2024-25 games whose weather text shows outdoor conditions:\n"); print(as.data.frame(x |> filter(season %in% c(2024, 2025), text_says == "outdoor conditions") |> transmute(season, week, away_team, home_team, roof, weather = substr(weather, 1, 70))), row.names = FALSE)
cat("closed-labelled games in 'other seasons' with outdoor-conditions text: temp summary\n"); print(summary(x$txt_temp[x$roof == "closed" & x$grp == "other seasons" & x$text_says == "outdoor conditions"])); cat("open-labelled: temp summary\n"); print(summary(x$txt_temp[x$roof == "open" & x$grp == "other seasons"]))
saveRDS(x, "t37_roof_text.rds")

# ===================== PART 3: t37c.R (this week's roof-unknown games) =====================
# #37 part 3: this week's roof-unknown games under stadium-by-month closed shares, for the current production model and the new model with dome make shifts.
s36f <- readLines("t36_final.R"); eval(parse(text = s36f[1:(grep("^V <- list", s36f) - 1)])); eval(parse(text = s36f[grep("^old <- read_csv", s36f):(grep("^D <- bind_rows", s36f))]))
gg <- readRDS("t37_results.rds")$gg; all_share <- mean(gg$closed); sh_oct <- sapply(c("DAL", "ARI", "ATL"), function(s) { i <- gg$st == s & gg$mg == "Oct"; (sum(gg$closed[i]) + 4 * all_share) / (sum(i) + 4) })
cat("closed shares used (stadium, October, blended with the all-stadium share", round(all_share, 3), "as if 4 games were added):", paste(names(sh_oct), round(sh_oct, 3), collapse = " | "), "\n")
unk <- c(DAL = "DAL", TB = "DAL", DET = "ARI", ARI = "ARI", ATL = "ATL", BAL = "ATL"); stopifnot(all(inp$roof_unknown[match(names(unk), inp$posteam)]), sum(inp$roof_unknown) == length(unk))
D1 <- D; S <- 2026; sh <- c(shift(S, "K1"), shift(S, "K4"))
newp <- function(dv) { Dm <- D1; i <- match(names(unk), Dm$posteam[Dm$season == S]); rows <- which(Dm$season == S)[i]; Dm$is_enclosed[rows] <- dv; D <<- Dm; rm(list = ls(cache)[grepl("^k2 2026", ls(cache))], envir = cache)
  L <- attempts2(S, mk("shift", "shift", "shift")); L$att_039 <- count039(S); te <- D[D$season == S, ]; q <- lapply(setNames(R, R), function(r) plogis(qlogis(te[[paste0("p_", r)]]) + sh[[r]][["b"]] * (te$is_enclosed - sh[[r]][["xbar"]])))
  out <- tibble(posteam = te$posteam, proj = projected_points(xp_skel(S), L$att_039, L$att_4049, L$att_50, q[["039"]], q[["4049"]], q[["50"]], q[["xp"]])); D <<- D1; out[match(names(unk), out$posteam), ] }
mo <- lapply(c(xp = "xp_attempts", a039 = "att_039", a4049 = "att_4049", a50 = "att_50"), function(y) readRDS(sprintf("../build/wk5/models/volume_%s_model.rds", y)))
oldp <- function(dv) { d <- inp; i <- match(names(unk), d$posteam); d$is_enclosed[i] <- dv; l <- lapply(mo, function(m) as.numeric(predict(m, d, type = "response"))); tibble(posteam = d$posteam, proj = projected_points(l$xp, l$a039, l$a4049, l$a50, d$p_039, d$p_4049, d$p_50, d$p_xp))[i, ] }
p <- unname(sh_oct[unk]); ph <- inp$is_enclosed[match(names(unk), inp$posteam)]
res <- tibble(posteam = names(unk), stadium = unname(unk), p_closed = p, kicker = inp$kicker_player_name[match(names(unk), inp$posteam)],
  cur_file = oldp(ph)$proj, cur_closed = oldp(1)$proj, cur_open = oldp(0)$proj, new_file = newp(ph)$proj, new_closed = newp(1)$proj, new_open = newp(0)$proj) |>
  mutate(cur_expected = p_closed * cur_closed + (1 - p_closed) * cur_open, new_expected = p_closed * new_closed + (1 - p_closed) * new_open)
print(as.data.frame(res |> mutate(across(where(is.double), ~ round(.x, 2)))), row.names = FALSE)
chk <- read_csv("../build/wk5/data/weekly_projections_latest.csv", show_col_types = FALSE); cat("current-model file value reproduced: max |diff|", signif(max(abs(res$cur_file - chk$projected_points[match(res$posteam, chk$team)])), 2), "\n")
write_csv(res, "t37_week5_roof.csv")
