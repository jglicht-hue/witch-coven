# Writes the weekly Kicker Wizerd summary as Markdown, from the files run_all.R
# just wrote, so the scheduled task can send it instead of building the tables
# by hand. Added 2026-10-19.
#
# Run from the pipeline folder after run_all.R:
#   Rscript summary.R [run.log] [--tuesday | --not-tuesday]
# Writes summary.md and prints it. The accuracy and scorecard sections appear on
# Tuesday runs (Chicago time) unless overridden. It reads only; it changes nothing.

suppressMessages({library(dplyr); library(readr)})
args <- commandArgs(TRUE)
log_path <- if (length(args) && !startsWith(args[1], "--")) args[1] else "run.log"
tuesday <- if ("--tuesday" %in% args) TRUE else if ("--not-tuesday" %in% args) FALSE else
  format(as.POSIXct(Sys.time(), tz = "America/Chicago"), "%u") == "2"

rd <- function(f) if (file.exists(f)) suppressMessages(read_csv(f, show_col_types = FALSE, guess_max = 10000)) else NULL
f1 <- function(x) ifelse(is.na(x), "NA", formatC(round(as.numeric(x), 1), format = "f", digits = 1))
f3 <- function(x) ifelse(is.na(x), "NA", formatC(round(as.numeric(x), 3), format = "f", digits = 3))
pct <- function(x) ifelse(is.na(x), "NA", paste0(formatC(100 * as.numeric(x), format = "f", digits = 1), "%"))
tbl <- function(df) {
  df[] <- lapply(df, function(x) { x <- as.character(x); x[is.na(x)] <- ""; x })
  c(paste0("| ", paste(names(df), collapse = " | "), " |"),
    paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|"),
    apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
}
log <- if (file.exists(log_path)) readLines(log_path, warn = FALSE) else character()
grab <- function(pattern) { x <- grep(pattern, log, value = TRUE); if (length(x)) trimws(x[length(x)]) else NA_character_ }

p    <- rd("data/weekly_projections_latest.csv")
prev <- rd("data/weekly_projections_previous_model.csv")
nxt  <- rd("data/weekly_projections_next.csv")
acc  <- rd("data/accuracy_report_latest.csv")
sc   <- rd("data/scorecard_summary.csv")
dome <- rd("data/scorecard_dome_accurate.csv")
if (is.null(p)) stop("data/weekly_projections_latest.csv not found - run run_all.R first.")

out <- character()
add <- function(...) out <<- c(out, ...)
season <- p$season[1]; week <- p$week[1]

# Header
add(sprintf("**Kicker projections: %d week %d** (regular season)", season, week),
    sprintf("- %d kicker-games · play-by-play through week %s · betting lines downloaded %s",
            nrow(p), p$pbp_through_week[1], p$lines_as_of[1]), "")

# Top 12 (new model), with the previous model's projection for the same team
pm <- if (!is.null(prev)) select(prev, team, prev_proj = projected_points) else tibble(team = character(), prev_proj = numeric())
ranked <- p |> arrange(desc(projected_points)) |> mutate(rank = row_number()) |> left_join(pm, by = "team")
show <- function(d) transmute(d,
  Rank = rank, Team = team, Opp = opponent, Kicker = kicker_player_name,
  `Pre-game top 16 (PPG rank)` = paste0(ifelse(top16pre, "yes", "no"), " (", ppg_rank, ")"),
  Proj = f1(projected_points), `90% CI` = paste0(f1(ci_low), "–", f1(ci_high)),
  `Middle 80%` = paste0(f1(outcome_low), "–", f1(outcome_high)),
  `Prev model` = f1(prev_proj),
  Played = ifelse(played, paste0("played: ", f1(actual_points)), ""))
add("**Top 12 by projected points (new model)**", tbl(show(head(ranked, 12))), "")
pl <- filter(ranked, played, rank > 12)
if (nrow(pl)) add("**Already played, outside the top 12**",
                  tbl(transmute(pl, Rank = rank, Kicker = kicker_player_name, Proj = f1(projected_points), Actual = f1(actual_points))), "")
add("PPG = fantasy points per game going into the week. 90% CI = confidence interval on the projection; middle 80% = where 80% of single-game scores should land.", "")

# The two models
md <- grab("New model vs previous: mean absolute difference")
if (!is.na(md)) add(paste0("**New vs previous model:** ", sub(".*New model vs previous: ", "", md)), "")

# Flags
fl <- character()
s <- filter(ranked, slump_flagged %in% TRUE)
for (i in seq_len(nrow(s))) fl <- c(fl, sprintf("- **Slump test tripped:** %s (%s). Informational only, the projection is not cut; the cut the old rule would have made: ×%s.",
                                               s$kicker_player_name[i], s$team[i], f3(s$slump_test_ratio[i])))
r <- filter(ranked, roof_unknown %in% TRUE)
for (i in seq_len(nrow(r))) fl <- c(fl, sprintf("- **Roof not announced:** %s (%s vs %s). Chance the roof is closed, from that stadium's history for the month: %s. Closed %s, open %s; the projection %s blends the two.",
                                               r$kicker_player_name[i], r$team[i], r$opponent[i], pct(r$roof_closed_share[i]),
                                               f1(r$proj_roof_closed[i]), f1(r$proj_roof_open[i]), f1(r$projected_points[i])))
im <- filter(ranked, implied_imputed %in% TRUE)
if (nrow(im)) fl <- c(fl, paste0("- **No betting line yet (league-average implied total used):** ", paste(im$kicker_player_name, collapse = ", "), "."))
add("**Flags**", if (length(fl)) fl else "- None.", "")

# Next week
nl <- grab("Wrote next-week projection|No next-week projection")
if (!is.null(nxt) && !is.na(nl) && grepl("^Wrote next-week", nl) && nxt$week[1] == week + 1) {
  n_line <- regmatches(nl, regexpr("[0-9]+ of [0-9]+ games have a betting line", nl))
  top6 <- nxt |> arrange(desc(projected_points)) |> head(6) |> mutate(rank = row_number())
  add(sprintf("**Early look at week %d** (%s)", week + 1, if (length(n_line)) n_line else "betting lines: see log"),
      tbl(transmute(top6, Rank = rank, Kicker = kicker_player_name, Game = paste(team, "vs", opponent),
                    Proj = paste0(f1(projected_points), ifelse(implied_imputed %in% TRUE, " (no line yet)", "")))),
      "Made a week early, so the lines and starters can change.", "")
} else add(paste0("**Next week:** ", if (is.na(nl)) "no next-week line in the log." else sub(".*No next-week projection: ?", "No next-week projection: ", nl)), "")

if (tuesday) {
  # Most accurate active kickers
  if (!is.null(acc)) {
    t10 <- acc |> filter(top10 %in% TRUE) |> arrange(rank)
    add(sprintf("**Most accurate active kickers** (window: %s)", acc$window[1]),
        tbl(transmute(t10, Rank = rank, Kicker = kicker, Team = team, `FG made/att` = paste0(fg_made, "/", fg_att),
                      `Make %` = f1(make_pct), `Expected %` = f1(expected_pct), `Edge (pts)` = f1(edge_pts),
                      `Edge, 80% low` = f1(edge_low80), `Truly good` = ifelse(truly_good %in% TRUE, "yes", ""))),
        "Expected % = what a league-average kicker makes from his distances. Edge = make % minus expected %. A low 80% bound means a small sample. Truly good = edge of 5+ points on 20+ attempts.", "")
  }
  # Scorecard
  if (!is.null(sc) && any(sc$graded > 0, na.rm = TRUE)) {
    sc <- filter(sc, !is.na(source))
    wk <- suppressWarnings(max(as.integer(sc$week[sc$source == "live" & sc$week != "all"]), na.rm = TRUE))
    rows <- bind_rows(filter(sc, week == as.character(wk), source %in% c("live", "prev_model")) |> mutate(Period = paste("week", wk)),
                      filter(sc, week == "all") |> mutate(Period = "season to date"))
    add("**Scorecard** (live = the projection that was live: previous model through week 4, new model from week 5; prev_model = previous model graded alone from week 5; rebuilt = weeks 1–3 rebuilt afterwards)",
        tbl(transmute(rows, Period, Source = source, Graded = graded, `Wrong starter` = wrong_starter,
                      `Sq. error: model` = f1(mse_model), `vs own PPG` = f1(mse_ppg), `vs league avg` = f1(mse_league),
                      Bias = f3(bias), `80% range hit` = paste0(pct(range_hit), " (claimed ", pct(range_claimed), ")"),
                      `Rank corr.` = f3(rank_corr))), "")
    if (!is.null(dome) && nrow(dome))
      add(paste0("**Accurate kickers in domes, 40–49 yd attempts per game:** ",
                 paste(sprintf("%s: actual %s vs expected %s (%d kicker-games)", dome$source, f3(dome$actual_att_4049_per_game),
                               f3(dome$expected_att_4049_per_game), dome$kicker_games), collapse = "; "), "."), "")
  } else add("**Scorecard:** no graded games in data/scorecard_summary.csv.", "")
}

add("*The starting kicker is assumed to be whoever last kicked for each team, so injuries or signings since then are not reflected. Weather is not in this file; the Kicker Wizerd chat applies it from forecasts.*")
writeLines(out, "summary.md")
cat(out, sep = "\n")
