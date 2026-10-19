# Weekly projection step (#12): design and checks

As of 2026-09-26. Scripts:
- `claude/09_weekly_inputs.R`: input builder (functions only)
- `claude/09a_check_weekly_inputs.R`: equivalence check
- `claude/09b_weekly_projections.R`: the weekly run

`run_all.R` runs 09b last. 09a runs only with `RUN_CHECKS <- TRUE`.

## What it does

1. Picks the **target week**: the earliest regular-season week of the current season with an unplayed game. Games in that week already played (e.g. Thursday night) are skipped.
2. Builds every team's inputs going into that week from the three training seasons plus this season to date. That covers the red zone and coach rates (02's method), the kicker accuracy, slump, XP rate, points-per-game rank and pre-game top 16 (05/06b's method), dome (03), and implied team total (04).
3. Projects each unplayed game with the saved volume models (07) and 08's functions: projected points, **90% confidence interval (headline)**, middle-80% outcome range, full distribution.

## Decisions (2026-09-26)

| Topic | Decision |
|---|---|
| Odds | nflverse's schedule file (spread and total), the same source as the training data. No API, scraper or team-name crosswalk. `lines_as_of` records when the lines were downloaded. |
| Kicker for an unplayed game | Whoever last attempted an FG or XP for the team (`kicker_source = last_kicked`, with `kicker_last_game`). On 2024–2025 this matched the game's actual kicker 93% of the time, so the starter should be confirmed elsewhere. |
| Retractable roofs | Blank in the schedule until game day. Filled with the league-average dome share (06's imputation rule) and flagged `roof_unknown`. |
| Shrinkage targets (league averages) | Computed over the whole sample, including this season to date, as 02/05/06b do over their sample. They differ slightly from training. |
| Scripts 01–07 | Unchanged. 09 reimplements their calculations for one week. |

## Equivalence check (09a)

09 was run on every week of 2023–2025 (54 weeks) using the training data, then compared with the Volume Table and 05's output.

**Result:** all 1,594 team-games matched with the same kicker. Every checked value agreed to within rounding error (largest difference 2e-15):
- implied total and dome;
- the three red zone rates and coach long-range FG rate;
- kicker accuracy (0–39, 40–49, 50+, 40+) and 40–49 share;
- points per game going into the week and pre-game top 16;
- slump adjustment (1,406 games) and XP rate (1,372 games).

If 02, 05, 06b or 09 changes, rerun 09a. It stops with an error on any mismatch.

## First run: 2026 week 3 (run 2026-09-26)

- **Coverage:** 30 kicker-games. ATL–GB was already played Thursday.
- **Data:** play-by-play through Thursday's game; lines downloaded 2026-09-26.
- **Top projections:**

| Kicker | Projected points | 90% confidence interval |
|---|---|---|
| B.Aubrey (DAL) | 9.6 | 8.5–10.9 |
| H.Mevis (LA) | 9.5 | 8.3–10.8 |
| T.Bass (BUF) | 9.5 | 8.3–10.8 |

- **Confidence interval widths:** typically 1.7–2.5 points (median 2.0).
- **Middle-80% outcome ranges:** typically about 2 to 15 points.
- **Reproducibility:** a clean rerun from an empty folder reproduced every value. Only `lines_as_of` changed.

## Limitations

- **Kicker changes:** injuries, cuts and signings since the last game aren't in the data.
- **Line freshness:** lines are only as fresh as nflverse's last update. Training lines are close to closing lines.
- **No weather yet** (#13).
- **Width:** the distributions are about 9% too wide (see `08_points_projection_log.md`).
- **Outside the top 16:** kickers not in the pre-game top 16 are projected with models trained on top-16 games.
