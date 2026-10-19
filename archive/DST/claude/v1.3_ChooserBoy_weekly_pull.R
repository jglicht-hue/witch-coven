#!/usr/bin/env Rscript
# =============================================================================
#  CHOOSER BOY - weekly DST data pull (nflreadr)
# -----------------------------------------------------------------------------
#  What it does: pulls nflverse play-by-play, PFR pressure data and the
#  schedule/Vegas lines, then writes the CSVs Chooser Boy uses for its
#  opponent-adjusted DST scoring.
#
#  When to run: once a week, ideally Tuesday morning after Monday Night Football
#  (nflverse updates play-by-play overnight). Rerun on Thursday/Sunday if you
#  want fresher Vegas lines.
#
#  Then: upload every CSV in OUTPUT_DIR to the Chooser Boy Claude Project,
#  replacing last week's copies (same file names every week).
#
#  Output files
#    chooserboy_meta.csv             when the data was pulled + freshness info
#    chooserboy_matchup_board.csv    every team's next few games, both sides
#                                    of the matchup pre-joined, plus base_score
#                                    (the backtested 1-10 score) - start here
#    chooserboy_dst_season.csv       (A) DST quality, opponent-adjusted
#    chooserboy_offense_season.csv   (B) how generous each offense is
#    chooserboy_dst_game_log.csv     game-by-game detail behind both
#    chooserboy_qb_profiles.csv      QB sack/turnover history (incl. backups)
#    chooserboy_data_dictionary.csv  what every column means
#
#  v1.2 (2026-09-25): offense-side and QB numbers are now adjusted against a
#  defense yardstick that blends the defense's other games this season with its
#  last season (DEF_BASELINE_PRIOR_GAMES). New columns: base_matchup_B_adj
#  (board), sack_rate_adj / int_rate_adj / turnover_rate_adj (qb_profiles).
#  base_score is UNCHANGED - the adjusted B did not beat the raw B in the
#  2021-2025 backtest, so it is shown for reference only.
#
#  v1.3 (2026-09-25):
#   * (A) mirror fix, now IN base_score: a DST is judged against what each
#     opponent offense normally allows = its other games this season + its last
#     season counted as OFF_BASELINE_PRIOR_GAMES games. A's scaling and the score
#     cutoffs were recalibrated on the 2021-2025 backtest.
#   * prov_score: provisional 1-10 score (A + B only) for games with no Vegas
#     line yet (usually 2+ weeks out). Own cutoffs and points table.
#   * qb_profiles: sack_rate_blend / turnover_rate_blend = this season blended
#     with the QB's last season (best early-season predictor in the backtest).
# =============================================================================

## ---- CONFIG ----------------------------------------------------------------
SEASON        <- NULL   # NULL = current NFL season; or set e.g. 2026
PRIOR_SEASONS <- 1      # extra past seasons of DST/offense data (early-season backup)
QB_SEASONS    <- 3      # seasons of QB history (current + 2 prior) for backup QBs
WEEKS_AHEAD   <- 4      # upcoming week + next 3 (the forward-look)
OUTPUT_DIR    <- "chooserboy_data"
AS_OF_WEEK    <- NULL   # leave NULL. Advanced: set e.g. 10 (with SEASON = 2025) to replay the data
                        # exactly as it stood before that week - handy for spot-checking past calls
DEF_BASELINE_PRIOR_GAMES <- 3   # when judging an OFFENSE (or QB) against the defenses it faced, each
                                # defense's "normal" output = its other games this season + last season
                                # counted as this many games. 0 = this season's other games only (v1.1).
OFF_BASELINE_PRIOR_GAMES <- 6   # when judging a DEFENSE (A) against the offenses it faced, each offense's
                                # "normal" allowed = its other games this season + last season counted as
                                # this many games. Part of base_score - don't change without re-backtesting.
QB_BLEND_DROPBACKS <- c(sack = 200, turnover = 400)  # last season's weight in the *_blend QB rates,
                                # in dropbacks (~6 and ~12 games). Backtest-best values.

# League DST scoring. Points/yards allowed are deliberately absent: they never count.
SCORING <- list(
  sack         = 1,
  interception = 2,
  fumble_rec   = 2,
  safety       = 4,
  touchdown    = 6,  # defensive AND special-teams return TDs
  blocked_kick = 2,  # blocked FG or punt
  blocked_xp   = 0,  # set to 2 if your league also scores blocked PATs
  def_2pt_ret  = 2,
  # FALSE = a blocked kick returned for a TD scores only the 6 (per v2 instructions);
  # TRUE  = it scores 2 + 6
  block_pts_when_returned_for_td = FALSE
)

# Base score = the exact formula backtested on 2021-2025 (walk-forward, 2,718 games).
# 35% matchup (B) / 25% unit quality (A) / 40% Vegas (implied total + spread), each put on a
# common scale, then turned into 1-10 using the backtest's decile cutoffs.
# Don't edit these unless the backtest is rerun - they are what make the v2.x points table true.
# v1.3: A_mean / A_sd / cuts recalibrated for the mirror fix (was -0.00034 / 0.92782 and
#       cuts -0.91531 ... 0.92411). prov_cuts added for the provisional (no-Vegas) score.
BASE <- list(
  k = 6,                                        # prior-season games blended in (early-season stabilizer)
  w_matchup = 0.35, w_unit = 0.25, w_vegas = 0.40,
  A_mean = -0.00549, A_sd = 0.89183,            # unit quality (core pts over expected / game)
  B_mean = -0.00022, B_sd = 0.86016,            # matchup (core pts allowed vs league / game)
  imp_mean = 22.25123, imp_sd = 3.92319,        # opponent implied total
  spr_mean = 0, spr_sd = 6.45428,               # DST team spread
  cuts = c(-0.92024, -0.61841, -0.41056, -0.19747, -0.02055, 0.16587, 0.35804, 0.62013, 0.95315),
  # provisional score = (35% B + 25% A) / 60%, same scaling; cutoffs from the backtest at 2-3 weeks' lead
  prov_cuts = c(-0.96042, -0.65218, -0.42250, -0.23098, -0.03263, 0.17004, 0.38947, 0.64708, 1.00328)
)

## ---- PACKAGES --------------------------------------------------------------
for (p in c("nflreadr", "dplyr", "tidyr", "readr")) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
}
suppressPackageStartupMessages({
  library(nflreadr); library(dplyr); library(tidyr); library(readr)
})
options(nflreadr.verbose = FALSE, dplyr.summarise.inform = FALSE)

flag     <- function(x) dplyr::coalesce(as.numeric(x), 0) == 1      # NA-safe 0/1 -> TRUE/FALSE
safe_div <- function(a, b) ifelse(is.na(b) | b == 0, NA_real_, a / b)
say      <- function(...) cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n")
`%||%`   <- function(a, b) if (is.null(a)) b else a

if (is.null(SEASON)) SEASON <- nflreadr::get_current_season()
dst_seasons <- (SEASON - PRIOR_SEASONS):SEASON
qb_seasons  <- (SEASON - QB_SEASONS + 1):SEASON
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)

## ---- 1. PLAY-BY-PLAY ---------------------------------------------------------
say("Loading play-by-play for", paste(range(union(dst_seasons, qb_seasons)), collapse = "-"))
pbp <- nflreadr::load_pbp(sort(union(dst_seasons, qb_seasons)))
pbp_updated <- attr(pbp, "nflverse_timestamp") %||% NA
pbp <- pbp |> filter(season_type == "REG")
if (!is.null(AS_OF_WEEK)) pbp <- pbp |> filter(!(season == SEASON & week >= AS_OF_WEEK))
if (!any(pbp$season == SEASON)) {
  warning("No ", SEASON, " regular-season play-by-play yet - current-season files will be empty.")
}

SCRIMMAGE <- c("pass", "run", "qb_kneel", "qb_spike")
KICKS     <- c("kickoff", "punt", "field_goal", "extra_point")

# Flag every scoring event and who gets DST credit for it.
# nflverse conventions this relies on (checked against 2025 data):
#   * punts: posteam = punting team;  kickoffs: posteam = RECEIVING team
#   * scrimmage return TDs have td_team == defteam
#   * safeties can sit on "no_play" rows (penalty in end zone) so they are NOT filtered out
plays <- pbp |>
  filter(season %in% dst_seasons) |>
  mutate(
    live  = coalesce(play_type, "") != "no_play" & !flag(two_point_attempt),
    scrim = play_type %in% SCRIMMAGE,
    st    = play_type %in% KICKS,
    is_sack = live & flag(sack),
    is_int  = live & scrim & flag(interception),
    # fumble recoveries: must recover the OTHER team's fumble. On scrimmage plays only the
    # defense gets credit; on kicks either unit can (e.g. kicking team recovers a muffed punt).
    fr1 = live & !is.na(fumble_recovery_1_team) & !is.na(fumbled_1_team) &
          fumble_recovery_1_team != fumbled_1_team &
          (st | (scrim & fumble_recovery_1_team == defteam)),
    fr2 = live & !is.na(fumble_recovery_2_team) & !is.na(fumbled_2_team) &
          fumble_recovery_2_team != fumbled_2_team &
          (st | (scrim & fumble_recovery_2_team == defteam)),
    is_def_td = flag(touchdown) & scrim & !is.na(td_team) & td_team == defteam,
    is_st_td  = flag(touchdown) & play_type %in% c("kickoff", "punt", "field_goal") & !is.na(td_team),
    is_safety = flag(safety),
    is_block  = flag(punt_blocked) | coalesce(field_goal_result == "blocked", FALSE),
    block_td  = is_block & flag(touchdown) & coalesce(td_team == defteam, FALSE),
    is_xp_blk = coalesce(extra_point_result == "blocked", FALSE),
    is_d2p    = flag(defensive_two_point_conv)
  )

credit <- bind_rows(
  plays |> filter(is_sack)   |> transmute(game_id, team = defteam, stat = "sacks"),
  plays |> filter(is_int)    |> transmute(game_id, team = defteam, stat = "ints"),
  plays |> filter(fr1)       |> transmute(game_id, team = fumble_recovery_1_team, stat = "fum_rec"),
  plays |> filter(fr2)       |> transmute(game_id, team = fumble_recovery_2_team, stat = "fum_rec"),
  plays |> filter(is_def_td) |> transmute(game_id, team = td_team, stat = "def_td"),
  plays |> filter(is_st_td)  |> transmute(game_id, team = td_team, stat = "st_td"),
  plays |> filter(is_safety) |> transmute(game_id, team = defteam, stat = "safeties"),
  plays |> filter(is_block)  |> transmute(game_id, team = defteam, stat = "blocked_kicks"),
  plays |> filter(block_td)  |> transmute(game_id, team = defteam, stat = "blocked_kicks_ret_td"),
  plays |> filter(is_xp_blk) |> transmute(game_id, team = defteam, stat = "blocked_xp"),
  plays |> filter(is_d2p)    |> transmute(game_id, team = defteam, stat = "def_2pt_ret")
) |>
  count(game_id, team, stat) |>
  pivot_wider(names_from = stat, values_from = n, values_fill = 0)

stat_cols <- c("sacks", "ints", "fum_rec", "def_td", "st_td", "safeties", "blocked_kicks",
               "blocked_kicks_ret_td", "blocked_xp", "def_2pt_ret")
for (s in setdiff(stat_cols, names(credit))) credit[[s]] <- 0L   # stat never happened

## ---- 2. TEAM-GAME TABLE (DST perspective) -------------------------------------
games <- plays |> distinct(season, week, game_id, home_team, away_team)
tg <- bind_rows(
  games |> transmute(season, week, game_id, team = home_team, opponent = away_team, home_away = "home"),
  games |> transmute(season, week, game_id, team = away_team, opponent = home_team, home_away = "away")
) |>
  left_join(credit, by = c("game_id", "team")) |>
  mutate(across(all_of(stat_cols), ~ coalesce(.x, 0L)),
         takeaways = ints + fum_rec)

# Opponent dropbacks (the DST's pass-rush opportunities)
dropbacks <- plays |> filter(live, flag(qb_dropback)) |> count(game_id, posteam, name = "opp_dropbacks")
tg <- tg |> left_join(dropbacks, by = c("game_id", "opponent" = "posteam"))

# Pressures from PFR (QB-level "times pressured", summed per offense per game)
say("Loading PFR pressure data")
pfr <- tryCatch(nflreadr::load_pfr_advstats(dst_seasons, stat_type = "pass", summary_level = "week"),
                error = function(e) { warning("PFR pressure data unavailable: ", conditionMessage(e)); NULL })
if (!is.null(pfr) && nrow(pfr) > 0 && "times_pressured" %in% names(pfr)) {
  pressure <- pfr |>
    filter(game_type == "REG") |>
    group_by(season, week, team) |>
    summarise(pressures = if (all(is.na(times_pressured))) NA_real_ else sum(times_pressured, na.rm = TRUE))
  tg <- tg |> left_join(pressure, by = c("season", "week", "opponent" = "team"))
} else {
  tg$pressures <- NA_real_
}

# Fantasy points (league scoring)
block_pts <- if (SCORING$block_pts_when_returned_for_td) quote(blocked_kicks) else quote(blocked_kicks - blocked_kicks_ret_td)
tg <- tg |>
  mutate(
    fpts_ex_td = sacks * SCORING$sack + ints * SCORING$interception + fum_rec * SCORING$fumble_rec +
                 safeties * SCORING$safety + !!block_pts * SCORING$blocked_kick +
                 blocked_xp * SCORING$blocked_xp + def_2pt_ret * SCORING$def_2pt_ret,
    fpts = fpts_ex_td + (def_td + st_td) * SCORING$touchdown
  )

## ---- 3. OPPONENT ADJUSTMENT (the core formula) --------------------------------
# (A) For each game: what did the DST get vs. what THIS opponent normally gives up
#     = its OTHER games this season (this game excluded so it can't inflate its own baseline)
#     blended with its last season (counted as OFF_BASELINE_PRIOR_GAMES games). Without a
#     prior season in the data: other games only, or the league per-game average if none.
# (B mirror) Same idea from the offense's side: sacks/giveaways allowed vs. what that
#     DST normally gets = its other games this season blended with its last season
#     (last season counted as DEF_BASELINE_PRIOR_GAMES games). Without a prior season in the
#     data (the oldest season loaded), it falls back to other games only / league average.
league <- tg |> group_by(season) |>
  summarise(lg_sacks_pg = mean(sacks), lg_takeaways_pg = mean(takeaways),
            lg_pressure_rate = safe_div(sum(pressures, na.rm = TRUE), sum(opp_dropbacks[!is.na(pressures)], na.rm = TRUE)),
            lg_sacks_per_pressure = safe_div(sum(sacks[!is.na(pressures)]), sum(pressures, na.rm = TRUE)),
            lg_sack_rate = safe_div(sum(sacks), sum(opp_dropbacks, na.rm = TRUE)),
            lg_fpts_pg = mean(fpts), lg_fpts_ex_td_pg = mean(fpts_ex_td))

opp_tot <- tg |> group_by(season, opponent) |>
  summarise(o_games = n(), o_sacks = sum(sacks), o_takeaways = sum(takeaways))
dst_tot <- tg |> group_by(season, team) |>
  summarise(d_games = n(), d_sacks = sum(sacks), d_takeaways = sum(takeaways))
turnover_pts <- mean(c(SCORING$interception, SCORING$fumble_rec))
# each DST's full-season per-game output, shifted forward so it lines up as "last season"
dst_prior <- tg |> group_by(season, team) |>
  summarise(p_sacks = mean(sacks), p_takeaways = mean(takeaways)) |>
  mutate(season = season + 1L)
# each OFFENSE's full-season per-game sacks/giveaways allowed, shifted forward as "last season" (mirror fix)
off_prior <- tg |> group_by(season, opponent) |>
  summarise(po_sacks = mean(sacks), po_takeaways = mean(takeaways)) |>
  mutate(season = season + 1L)
kD <- DEF_BASELINE_PRIOR_GAMES
kO <- OFF_BASELINE_PRIOR_GAMES

tg <- tg |>
  left_join(opp_tot, by = c("season", "opponent")) |>
  left_join(dst_tot, by = c("season", "team")) |>
  left_join(dst_prior, by = c("season", "team")) |>
  left_join(off_prior, by = c("season", "opponent")) |>
  left_join(league |> select(season, lg_sacks_pg, lg_takeaways_pg), by = "season") |>
  mutate(
    has_off_prior  = !is.na(po_sacks) & kO > 0,
    baseline_type  = case_when(has_off_prior ~ "opp_other_games+last_season",
                               o_games > 1   ~ "opp_other_games",
                               TRUE          ~ "league_avg"),
    exp_sacks      = case_when(has_off_prior ~ (o_sacks - sacks + kO * po_sacks) / (o_games - 1 + kO),
                               o_games > 1   ~ (o_sacks - sacks) / (o_games - 1),
                               TRUE          ~ lg_sacks_pg),
    exp_takeaways  = case_when(has_off_prior ~ (o_takeaways - takeaways + kO * po_takeaways) / (o_games - 1 + kO),
                               o_games > 1   ~ (o_takeaways - takeaways) / (o_games - 1),
                               TRUE          ~ lg_takeaways_pg),
    sacks_oe       = sacks - exp_sacks,
    takeaways_oe   = takeaways - exp_takeaways,
    core_fpts_oe   = sacks_oe * SCORING$sack + takeaways_oe * turnover_pts,
    # offense-side mirror
    has_prior                 = !is.na(p_sacks) & kD > 0,
    opp_exp_sacks_allowed     = case_when(
      has_prior   ~ (d_sacks - sacks + kD * p_sacks) / (d_games - 1 + kD),
      d_games > 1 ~ (d_sacks - sacks) / (d_games - 1),
      TRUE        ~ lg_sacks_pg),
    opp_exp_giveaways         = case_when(
      has_prior   ~ (d_takeaways - takeaways + kD * p_takeaways) / (d_games - 1 + kD),
      d_games > 1 ~ (d_takeaways - takeaways) / (d_games - 1),
      TRUE        ~ lg_takeaways_pg),
    opp_sacks_allowed_oe      = sacks - opp_exp_sacks_allowed,
    opp_giveaways_oe          = takeaways - opp_exp_giveaways
  ) |>
  select(-o_games, -o_sacks, -o_takeaways, -d_games, -d_sacks, -d_takeaways, -lg_sacks_pg, -lg_takeaways_pg,
         -p_sacks, -p_takeaways, -has_prior, -po_sacks, -po_takeaways, -has_off_prior)

## ---- 4. (A) DST SEASON SUMMARY ----------------------------------------------
dst_season <- tg |>
  group_by(season, team) |>
  summarise(
    games = n(),
    total_sacks = sum(sacks), total_ints = sum(ints), total_fum_rec = sum(fum_rec),
    total_takeaways = sum(takeaways),
    sacks_pg = mean(sacks), takeaways_pg = mean(takeaways),
    exp_sacks_pg = mean(exp_sacks), exp_takeaways_pg = mean(exp_takeaways),
    sacks_oe_pg = mean(sacks_oe), takeaways_oe_pg = mean(takeaways_oe),
    core_fpts_oe_pg = mean(core_fpts_oe),
    games_league_avg_baseline = sum(baseline_type == "league_avg"),
    pressure_games = sum(!is.na(pressures)),
    pressure_rate = safe_div(sum(pressures, na.rm = TRUE), sum(opp_dropbacks[!is.na(pressures)], na.rm = TRUE)),
    sacks_per_pressure = safe_div(sum(sacks[!is.na(pressures)]), sum(pressures, na.rm = TRUE)),
    def_td = sum(def_td), st_td = sum(st_td), safeties = sum(safeties),
    blocked_kicks = sum(blocked_kicks), blocked_xp = sum(blocked_xp), def_2pt_ret = sum(def_2pt_ret),
    fantasy_ppg = mean(fpts), fantasy_ppg_ex_td = mean(fpts_ex_td)
  ) |>
  left_join(league |> select(season, lg_pressure_rate, lg_sacks_per_pressure), by = "season") |>
  group_by(season) |>
  mutate(rank_sacks_oe     = min_rank(desc(sacks_oe_pg)),
         rank_takeaways_oe = min_rank(desc(takeaways_oe_pg)),
         rank_core_fpts_oe = min_rank(desc(core_fpts_oe_pg)),
         rank_pressure     = min_rank(desc(pressure_rate))) |>
  ungroup() |>
  arrange(desc(season), rank_core_fpts_oe)

## ---- 5. (B) OFFENSE GENEROSITY -----------------------------------------------
# Most recent starter = QB with the most dropbacks in the team's latest game
last_qb <- plays |>
  filter(live, flag(qb_dropback), !is.na(passer_id)) |>
  count(season, week, posteam, passer_id, passer) |>
  group_by(season, posteam) |> filter(week == max(week)) |>
  slice_max(n, n = 1, with_ties = FALSE) |> ungroup() |>
  transmute(season, team = posteam, last_game_qb = passer, last_game_qb_id = passer_id)

offense_season <- tg |>
  group_by(season, team = opponent) |>
  summarise(
    games = n(),
    dropbacks_pg = mean(opp_dropbacks, na.rm = TRUE),
    sacks_allowed_pg = mean(sacks),
    sack_rate_allowed = safe_div(sum(sacks), sum(opp_dropbacks, na.rm = TRUE)),
    ints_thrown_pg = mean(ints), fumbles_lost_pg = mean(fum_rec), giveaways_pg = mean(takeaways),
    sacks_allowed_oe_pg = mean(opp_sacks_allowed_oe), giveaways_oe_pg = mean(opp_giveaways_oe),
    pressure_games = sum(!is.na(pressures)),
    pressure_rate_allowed = safe_div(sum(pressures, na.rm = TRUE), sum(opp_dropbacks[!is.na(pressures)], na.rm = TRUE)),
    dst_fpts_allowed_pg = mean(fpts), dst_fpts_allowed_ex_td_pg = mean(fpts_ex_td),
    def_st_tds_allowed = sum(def_td + st_td)
  ) |>
  left_join(league, by = "season") |>
  mutate(sacks_allowed_index = sacks_allowed_pg / lg_sacks_pg,
         giveaways_index     = giveaways_pg / lg_takeaways_pg) |>
  group_by(season) |>
  mutate(rank_generosity_ex_td = min_rank(desc(dst_fpts_allowed_ex_td_pg))) |>  # 1 = juiciest matchup
  ungroup() |>
  left_join(last_qb, by = c("season", "team")) |>
  select(-starts_with("lg_")) |>
  arrange(desc(season), rank_generosity_ex_td)

## ---- 6. QB PROFILES ------------------------------------------------------------
qb_plays <- pbp |>
  filter(season %in% qb_seasons, coalesce(play_type, "") != "no_play",
         !flag(two_point_attempt), flag(qb_dropback), !is.na(passer_id))
qb_league <- qb_plays |> group_by(season) |>
  summarise(lg_sack_rate = mean(flag(sack)), lg_int_rate = mean(flag(interception)),
            lg_turnover_rate = mean(flag(interception) | (flag(fumble_lost) & coalesce(fumbled_1_player_id == passer_id, FALSE))))
qb_profiles <- qb_plays |>
  mutate(fum_lost_qb = flag(fumble_lost) & coalesce(fumbled_1_player_id == passer_id, FALSE),
         pick6       = flag(interception) & flag(touchdown) & coalesce(td_team == defteam, FALSE)) |>
  group_by(season, passer_id) |>
  summarise(qb = last(passer), team = last(posteam), games = n_distinct(game_id), last_week = max(week),
            dropbacks = n(), sacks_taken = sum(flag(sack)), ints = sum(flag(interception)),
            fumbles_lost = sum(fum_lost_qb), pick_sixes = sum(pick6)) |>
  ungroup() |>
  filter(dropbacks >= 10) |>
  mutate(sack_rate = sacks_taken / dropbacks, int_rate = ints / dropbacks,
         turnover_rate = (ints + fumbles_lost) / dropbacks) |>
  left_join(qb_league, by = "season") |>
  select(season, qb, team, passer_id, everything()) |>
  arrange(desc(season), desc(dropbacks))

# Adjusted QB rates: what the QB did vs. what the defenses he faced normally force per dropback.
# Defense yardstick = its other games that season (this game excluded) + last season counted as
# DEF_BASELINE_PRIOR_GAMES games' worth of dropbacks. Oldest QB season has no prior -> other games only.
qb_d <- qb_plays |>
  mutate(sk = flag(sack), it = flag(interception),
         to = flag(interception) | (flag(fumble_lost) & coalesce(fumbled_1_player_id == passer_id, FALSE)))
def_game   <- qb_d |> group_by(season, game_id, defteam) |>
  summarise(g_db = n(), g_sk = sum(sk), g_it = sum(it), g_to = sum(to))
def_season <- def_game |> group_by(season, defteam) |>
  summarise(s_games = n(), s_db = sum(g_db), s_sk = sum(g_sk), s_it = sum(g_it), s_to = sum(g_to))
def_prior  <- def_season |>
  transmute(season = season + 1L, defteam, p_w = DEF_BASELINE_PRIOR_GAMES * s_db / s_games,
            p_sk = s_sk / s_db, p_it = s_it / s_db, p_to = s_to / s_db)
qb_exp <- qb_d |>
  group_by(season, game_id, passer_id, defteam) |> summarise(db = n()) |> ungroup() |>
  left_join(def_game,   by = c("season", "game_id", "defteam")) |>
  left_join(def_season, by = c("season", "defteam")) |>
  left_join(def_prior,  by = c("season", "defteam")) |>
  left_join(qb_league,  by = "season") |>
  mutate(p_w = coalesce(p_w, 0), o_db = s_db - g_db,
         base_sk = coalesce(safe_div(s_sk - g_sk + p_w * coalesce(p_sk, 0), o_db + p_w), lg_sack_rate),
         base_it = coalesce(safe_div(s_it - g_it + p_w * coalesce(p_it, 0), o_db + p_w), lg_int_rate),
         base_to = coalesce(safe_div(s_to - g_to + p_w * coalesce(p_to, 0), o_db + p_w), lg_turnover_rate)) |>
  group_by(season, passer_id) |>
  summarise(exp_sacks = sum(db * base_sk), exp_ints = sum(db * base_it), exp_turnovers = sum(db * base_to))
qb_profiles <- qb_profiles |>
  left_join(qb_exp, by = c("season", "passer_id")) |>
  mutate(sack_rate_adj     = lg_sack_rate     + (sacks_taken - exp_sacks) / dropbacks,
         int_rate_adj      = lg_int_rate      + (ints - exp_ints) / dropbacks,
         turnover_rate_adj = lg_turnover_rate + (ints + fumbles_lost - exp_turnovers) / dropbacks) |>
  relocate(sack_rate_adj, .after = sack_rate) |>
  relocate(int_rate_adj, .after = int_rate) |>
  relocate(turnover_rate_adj, .after = turnover_rate) |>
  select(-exp_sacks, -exp_ints, -exp_turnovers)

# Blended QB rates: this season + the QB's last season (>= 100 dropbacks) weighted as QB_BLEND_DROPBACKS;
# no usable last season (rookie, backup) -> blend toward this season's league rate instead.
# Blank for the oldest season in the file (its prior season isn't loaded).
qb_prior <- qb_profiles |> filter(dropbacks >= 100) |>
  transmute(season = season + 1L, passer_id, p_sack_rate = sack_rate, p_to_rate = turnover_rate)
qb_profiles <- qb_profiles |>
  left_join(qb_prior, by = c("season", "passer_id")) |>
  mutate(
    ws = QB_BLEND_DROPBACKS[["sack"]], wt = QB_BLEND_DROPBACKS[["turnover"]],
    sack_rate_blend     = (sacks_taken + ws * coalesce(p_sack_rate, lg_sack_rate)) / (dropbacks + ws),
    turnover_rate_blend = (ints + fumbles_lost + wt * coalesce(p_to_rate, lg_turnover_rate)) / (dropbacks + wt),
    blend_prior         = if_else(is.na(p_sack_rate), "league_avg", "own_last_season"),
    across(c(sack_rate_blend, turnover_rate_blend, blend_prior), ~ if_else(season == min(qb_seasons), NA, .x))
  ) |>
  relocate(sack_rate_blend, .after = sack_rate_adj) |>
  relocate(turnover_rate_blend, .after = turnover_rate_adj) |>
  relocate(blend_prior, .after = turnover_rate_blend) |>
  select(-p_sack_rate, -p_to_rate, -ws, -wt)

## ---- 7. SCHEDULE + MATCHUP BOARD ----------------------------------------------
say("Loading schedule / Vegas lines")
sched <- tryCatch(nflreadr::load_schedules(SEASON), error = function(e) NULL)
sched_source <- "nflreadr::load_schedules"
if (is.null(sched) || nrow(sched) == 0 || !"week" %in% names(sched)) {   # fallback: nflverse release file
  sched <- readr::read_csv("https://github.com/nflverse/nflverse-data/releases/download/schedules/games.csv",
                           show_col_types = FALSE, progress = FALSE)
  sched_source <- "nflverse-data games.csv"
}
upcoming <- sched |> filter(season == SEASON, game_type == "REG")
upcoming <- if (is.null(AS_OF_WEEK)) upcoming |> filter(is.na(result)) else upcoming |> filter(week >= AS_OF_WEEK)
next_week <- if (nrow(upcoming)) min(upcoming$week) else NA_integer_
upcoming <- upcoming |> filter(week < next_week + WEEKS_AHEAD)

board <- bind_rows(
  upcoming |> transmute(week, gameday, gametime, game_id, dst_team = home_team, opponent = away_team,
                        home_away = "home", dst_spread = -spread_line, total_line,
                        opp_implied_total = total_line / 2 - spread_line / 2, roof, opp_qb_listed = away_qb_name),
  upcoming |> transmute(week, gameday, gametime, game_id, dst_team = away_team, opponent = home_team,
                        home_away = "away", dst_spread = spread_line, total_line,
                        opp_implied_total = total_line / 2 + spread_line / 2, roof, opp_qb_listed = home_qb_name)
) |>
  mutate(weeks_out = week - next_week, .after = week)

cur_dst <- dst_season |> filter(season == SEASON) |>
  select(dst_team = team, dst_games = games, dst_sacks_oe_pg = sacks_oe_pg, dst_takeaways_oe_pg = takeaways_oe_pg,
         dst_core_fpts_oe_pg = core_fpts_oe_pg, dst_pressure_rate = pressure_rate,
         dst_sacks_per_pressure = sacks_per_pressure, dst_fantasy_ppg = fantasy_ppg,
         dst_fantasy_ppg_ex_td = fantasy_ppg_ex_td, dst_def_st_tds = def_td, dst_rank_core_fpts_oe = rank_core_fpts_oe)
cur_off <- offense_season |> filter(season == SEASON) |>
  select(opponent = team, opp_games = games, opp_last_game_qb = last_game_qb,
         opp_sacks_allowed_pg = sacks_allowed_pg, opp_sack_rate_allowed = sack_rate_allowed,
         opp_giveaways_pg = giveaways_pg, opp_sacks_allowed_index = sacks_allowed_index,
         opp_giveaways_index = giveaways_index, opp_sacks_allowed_oe_pg = sacks_allowed_oe_pg,
         opp_giveaways_oe_pg = giveaways_oe_pg, opp_pressure_rate_allowed = pressure_rate_allowed,
         opp_dst_fpts_allowed_ex_td_pg = dst_fpts_allowed_ex_td_pg, opp_rank_generosity = rank_generosity_ex_td)
board <- board |> left_join(cur_dst, by = "dst_team") |> left_join(cur_off, by = "opponent")

if (PRIOR_SEASONS >= 1) {   # last season's numbers, for thin early-season samples
  board <- board |>
    left_join(dst_season |> filter(season == SEASON - 1) |>
                select(dst_team = team, dst_prior_core_fpts_oe_pg = core_fpts_oe_pg,
                       dst_prior_fantasy_ppg_ex_td = fantasy_ppg_ex_td), by = "dst_team") |>
    left_join(offense_season |> filter(season == SEASON - 1) |>
                select(opponent = team, opp_prior_dst_fpts_allowed_ex_td_pg = dst_fpts_allowed_ex_td_pg),
              by = "opponent")
}

# ---- Base score (the backtested formula) ----
# core points c = sacks + 2*takeaways (fixed, matches the backtest regardless of SCORING)
core <- tg |>
  mutate(c = sacks + 2 * takeaways, unit_c_oe = c - (exp_sacks + 2 * exp_takeaways)) |>
  group_by(season) |> mutate(c_vs_lg = c - mean(c)) |> ungroup()
cur_A   <- core |> filter(season == SEASON) |> group_by(team) |> summarise(A_sum = sum(unit_c_oe), A_n = n())
cur_B   <- core |> filter(season == SEASON) |> group_by(opponent) |> summarise(B_sum = sum(c_vs_lg), B_n = n())
prior_A <- core |> filter(season == SEASON - 1) |> group_by(team) |> summarise(pA = mean(unit_c_oe))
prior_B <- core |> filter(season == SEASON - 1) |> group_by(opponent) |> summarise(pB = mean(c_vs_lg))
# Reference only (not in base_score): B adjusted for the defenses faced, same blend with last season
core <- core |> mutate(c_adj_oe = c - (opp_exp_sacks_allowed + 2 * opp_exp_giveaways))
cur_Badj   <- core |> filter(season == SEASON) |> group_by(opponent) |> summarise(Ba_sum = sum(c_adj_oe), Ba_n = n())
prior_Badj <- core |> filter(season == SEASON - 1) |> group_by(opponent) |> summarise(pBa = mean(c_adj_oe))
board <- board |>
  left_join(cur_A, by = c("dst_team" = "team")) |> left_join(prior_A, by = c("dst_team" = "team")) |>
  left_join(cur_B, by = "opponent") |> left_join(prior_B, by = "opponent") |>
  left_join(cur_Badj, by = "opponent") |> left_join(prior_Badj, by = "opponent") |>
  mutate(across(c(A_sum, A_n, B_sum, B_n, pA, pB, Ba_sum, Ba_n, pBa), ~ coalesce(as.numeric(.x), 0)),
         base_matchup_B_adj = (Ba_sum + BASE$k * pBa) / (Ba_n + BASE$k),
         base_unit_A    = (A_sum + BASE$k * pA) / (A_n + BASE$k),     # this season blended with last
         base_matchup_B = (B_sum + BASE$k * pB) / (B_n + BASE$k),
         base_composite = BASE$w_matchup * (base_matchup_B - BASE$B_mean) / BASE$B_sd +
                          BASE$w_unit    * (base_unit_A - BASE$A_mean) / BASE$A_sd +
                          BASE$w_vegas   * (-(opp_implied_total - BASE$imp_mean) / BASE$imp_sd -
                                             (dst_spread - BASE$spr_mean) / BASE$spr_sd) / 2,
         base_score     = if_else(is.na(base_composite), NA_integer_,
                                  1L + findInterval(base_composite, BASE$cuts)),
         # provisional score: only where there's no Vegas line yet (so no base_score)
         prov_composite = if_else(is.na(base_composite),
                                  (BASE$w_matchup * (base_matchup_B - BASE$B_mean) / BASE$B_sd +
                                   BASE$w_unit    * (base_unit_A - BASE$A_mean) / BASE$A_sd) /
                                  (BASE$w_matchup + BASE$w_unit), NA_real_),
         prov_score     = if_else(is.na(prov_composite), NA_integer_,
                                  1L + findInterval(prov_composite, BASE$prov_cuts))) |>
  select(-A_sum, -A_n, -B_sum, -B_n, -pA, -pB, -Ba_sum, -Ba_n, -pBa) |>
  relocate(base_score, prov_score, base_composite, prov_composite, base_matchup_B, base_matchup_B_adj,
           base_unit_A, .after = opponent)
board <- board |> arrange(week, desc(coalesce(base_composite, prov_composite)), dst_team)

## ---- 8. META + DATA DICTIONARY -------------------------------------------------
cur_tg <- tg |> filter(season == SEASON)
meta <- tibble(
  generated_at          = format(Sys.time(), "%Y-%m-%d %H:%M %Z"),
  season                = SEASON,
  last_week_in_data     = if (nrow(cur_tg)) max(cur_tg$week) else NA,
  games_in_data         = n_distinct(cur_tg$game_id),
  next_unplayed_week    = next_week,
  pbp_last_updated      = as.character(pbp_updated),
  pressure_data_games   = n_distinct(cur_tg$game_id[!is.na(cur_tg$pressures)]),
  schedule_source       = sched_source,
  scoring = paste(names(SCORING), unlist(SCORING), sep = "=", collapse = "; ")
)

dict <- tribble(
  ~file, ~column, ~meaning,
  "all", "season / week", "NFL season and regular-season week. Only regular-season games are included.",
  "all", "_pg", "Suffix = per game.",
  "all", "_oe", "Suffix = over expected: actual minus what you'd expect given who they played (positive = more than expected). DST side: expectation = the opponent offense's OTHER games this season blended with its last season (counted as OFF_BASELINE_PRIOR_GAMES games). Offense/QB side: expectation = the defense's OTHER games this season blended with its last season (counted as DEF_BASELINE_PRIOR_GAMES games).",
  "all", "_adj", "Suffix = adjusted for the defenses faced, using the same blended defense yardstick as the offense-side _oe columns.",
  "meta", "last_week_in_data", "Latest week with play-by-play. If behind the current NFL week, the data is stale - use web search for stats.",
  "meta", "next_unplayed_week", "The week the matchup board treats as 'this week' (weeks_out = 0).",
  "meta", "pressure_data_games", "Current-season games that have PFR pressure data. Low vs games_in_data = pressure numbers incomplete.",
  "matchup_board", "dst_team / opponent", "One row per team per upcoming game, from the DST's point of view.",
  "matchup_board", "weeks_out", "0 = this week's game; 1-3 = forward-look.",
  "matchup_board", "base_score", "START HERE. 1-10 score from the backtested formula (35% matchup / 25% unit quality / 40% Vegas). Same scale as the points table in the instructions. Blank when Vegas lines aren't posted - then use prov_score.",
  "matchup_board", "prov_score", "Provisional 1-10 score for games with NO Vegas line yet (usually 2+ weeks out): matchup (B) and unit quality (A) only, in the same 35:25 proportion. Own cutoffs and points table (weaker than base_score). Blank whenever base_score exists.",
  "matchup_board", "prov_composite", "The raw number behind prov_score (0 = average).",
  "matchup_board", "base_composite", "The raw blended number behind base_score (0 = average matchup; roughly -1.5 to +1.5). Useful for breaking ties between equal base_scores.",
  "matchup_board", "base_matchup_B", "(B) input to base_score: opponent's core points allowed (sacks + 2 x takeaways) per game vs league average, blended with last season (6 games' weight).",
  "matchup_board", "base_matchup_B_adj", "REFERENCE ONLY (not in base_score): same as base_matchup_B but measured against what the defenses this offense faced normally get (their other games + last season), instead of league average. Backtest 2021-2025: no measurable gain over the raw B once Vegas is in the score.",
  "matchup_board", "base_unit_A", "(A) input to base_score: DST's core points over expected per game (vs. what each opponent normally allows: its other games + last season), blended with the DST's last season (6 games' weight).",
  "matchup_board", "dst_spread", "(C) Vegas spread for the DST's team (negative = favored). Part of base_score. Blank until lines are posted.",
  "matchup_board", "opp_implied_total", "(C) Opponent's Vegas implied points (from spread + total). Core input - 40% of base_score with the spread. Points allowed still don't score; a low total flags an offense likely to take sacks and turn it over.",
  "matchup_board", "roof", "dome / closed / open / outdoors. Dome or closed = ignore weather.",
  "matchup_board", "opp_qb_listed", "QB listed by nflverse for the game (often blank for future games) - confirm with web search.",
  "matchup_board", "opp_last_game_qb", "QB with the most dropbacks in the opponent's most recent game.",
  "matchup_board", "dst_* columns", "Current-season DST quality (A). See dst_season columns of the same name.",
  "matchup_board", "opp_* columns", "Current-season offense generosity (B). See offense_season columns of the same name.",
  "matchup_board", "*_prior_*", "Same metric from last season - backup signal when the current-season sample is thin.",
  "dst_season", "sacks_pg / takeaways_pg", "Raw sacks and takeaways (INTs + fumble recoveries, incl. special teams) per game.",
  "dst_season", "exp_sacks_pg / exp_takeaways_pg", "Average of what this DST's opponents normally allow (their other games this season + last season) = strength of schedule. Higher = easier schedule.",
  "dst_season", "sacks_oe_pg / takeaways_oe_pg", "(A) core metric: per-game production above what its opponents normally allow. Tracked separately.",
  "dst_season", "core_fpts_oe_pg", "sacks_oe and takeaways_oe converted to league fantasy points (TDs excluded). Best single unit-quality number.",
  "dst_season", "games_league_avg_baseline", "Games where the opponent had no other games and no last season in the data, so league average was the baseline (normally 0 in the current season).",
  "dst_season", "pressure_rate", "Pressures generated / opponent dropbacks (PFR pressures). Compare to lg_pressure_rate.",
  "dst_season", "sacks_per_pressure", "Sack conversion. Well above lg_sacks_per_pressure = sack total may not hold up; well below = likely due for more sacks.",
  "dst_season", "def_td / st_td", "Defensive return TDs / special-teams return TDs. Ceiling note only, not part of the baseline.",
  "dst_season", "fantasy_ppg / fantasy_ppg_ex_td", "Actual league-scoring fantasy points per game, with and without TDs.",
  "dst_season", "rank_*", "League rank within season (1 = best).",
  "offense_season", "team", "The OFFENSE being described (i.e. a potential opponent for your DST).",
  "offense_season", "sacks_allowed_pg / giveaways_pg", "What opposing DSTs have gotten against this team per game. Giveaways include special-teams fumbles.",
  "offense_season", "sack_rate_allowed", "Sacks allowed / dropbacks.",
  "offense_season", "sacks_allowed_index / giveaways_index", "Per-game rate vs. league average (1.00 = average, 1.30 = 30% more generous).",
  "offense_season", "sacks_allowed_oe_pg / giveaways_oe_pg", "(B) adjusted: allowed vs. what the DSTs they faced normally get elsewhere (their other games this season + last season). Positive = generous even after accounting for who they played.",
  "offense_season", "dst_fpts_allowed_ex_td_pg", "Fantasy points (ex TD) opposing DSTs averaged against this offense.",
  "offense_season", "rank_generosity_ex_td", "1 = most generous offense for DSTs.",
  "offense_season", "last_game_qb", "QB with the most dropbacks in the team's latest game. If a different QB starts this week, lean on qb_profiles.",
  "dst_game_log", "baseline_type", "opp_other_games+last_season = opponent's other games this season blended with its last season (current season); opp_other_games = other games only (last season's rows); league_avg = no other games.",
  "dst_game_log", "exp_sacks / exp_takeaways", "What the opponent normally allows (see baseline_type). The game's sacks_oe / takeaways_oe = actual minus these.",
  "dst_game_log", "opp_sacks_allowed_oe / opp_giveaways_oe", "Offense-side mirror: game result vs. what THIS DST normally gets (its other games this season + last season). opp_exp_* = that expectation.",
  "dst_game_log", "pressures", "PFR pressures generated in the game (blank if not available).",
  "dst_game_log", "fpts / fpts_ex_td", "League-scoring fantasy points for the game, with and without TDs.",
  "qb_profiles", "qb / passer_id", "One row per QB per season (min 10 dropbacks), includes backups. team = last team he threw for that season.",
  "qb_profiles", "sack_rate / int_rate / turnover_rate", "Per dropback. turnover_rate = (INTs + fumbles lost by the QB) / dropbacks. Compare to lg_* columns.",
  "qb_profiles", "sack_rate_blend / turnover_rate_blend", "BEST EARLY-SEASON READ of a QB: this season's raw rate blended with his last season (sacks: 200 dropbacks' weight, turnovers: 400). blend_prior says whether his own last season or league average was used. Backtest: cut next-week prediction error ~29-39% in Weeks 2-3 vs. the raw rate. Blank for the oldest season in the file.",
  "qb_profiles", "sack_rate_adj / int_rate_adj / turnover_rate_adj", "Same rates adjusted for the defenses faced: league rate + (actual - what those defenses normally force on the same dropbacks) / dropbacks. Backtest: early-season adjusted rates did not predict later-season rates better than raw ones; early-season turnover rates (raw or adjusted) barely predict later turnovers at all.",
  "qb_profiles", "pick_sixes", "INTs returned for TDs."
)

## ---- 9. WRITE ---------------------------------------------------------------
out <- function(df, name) {
  df <- df |> mutate(across(where(is.double), ~ round(.x, 3)))
  readr::write_csv(df, file.path(OUTPUT_DIR, paste0("chooserboy_", name, ".csv")), na = "")
  say(sprintf("wrote chooserboy_%s.csv (%d rows)", name, nrow(df)))
}
out(meta, "meta")
out(board, "matchup_board")
out(dst_season, "dst_season")
out(offense_season, "offense_season")
out(tg |> arrange(desc(season), week, team), "dst_game_log")
out(qb_profiles, "qb_profiles")
out(dict, "data_dictionary")
say("Done, Big Dawg. Upload everything in", normalizePath(OUTPUT_DIR), "to the Chooser Boy project.")
