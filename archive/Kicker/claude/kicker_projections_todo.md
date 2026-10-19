# Kicker Projections — to-do

As of 2026-09-25. Detailed modeling decisions live in the volume modeling log (latest: `v3.1_07_volume_modeling_log.md`) and in each script's header.

## Done

| # | Piece | Where |
|---|---|---|
| 1 | Kicker game outcomes (team FG/XP counts; kicker attempts/makes by range) | `01_pull_kicker_game_outcomes.R` |
| 2 | Team covariates (red zone, distance mix, coach FG-or-go and long-range FG rates) | `02_pull_team_covariates.R` |
| 3 | Live odds scraper (runs daily on your PC) | `scrape_odds.py` |
| 4 | Venue covariates (dome, altitude) | `03_pull_venue_covariates.R` |
| 5 | Historical implied team totals | `04_pull_odds_covariates.R` |
| 6 | Kicker accuracy (shrunk rates by range, slump flag, XP accuracy) | `05_pull_kicker_accuracy.R` |
| 7 | Training tables (join-everything) and volume features | `06_join_training_data.R`, `06b_build_volume_features.R` |
| 8 | FG-attempts volume models (0-39, 40-49, 50+) | `07_fit_volume_models.R` |
| 9 | XP-attempts volume model | `07_fit_volume_models.R` |
| — | Shared data loader and one-command run (replicable on your PC and in the Claude workspace) | `00_nflverse_data.R`, `run_all.R` |

## Not started

**10. Team-name crosswalk for the live odds join.** The scraper writes full team names ("Kansas City Chiefs"); the pipeline uses abbreviations ("KC").

**11. Fantasy points distribution per kicker.** Combine the volume models (expected attempts by range, XP attempts) with kicker accuracy (05's rates by range, slump-adjusted; XP accuracy) into a full probability distribution of fantasy points for a game (3/4/5 per make by range, -1 per miss, +1 per XP), not just an average. This is what the probability-distribution plots show.

**12. Weekly projection step.** For the upcoming week, build each team's inputs:
- Live odds from the scraper, which needs #10.
- The schedule and venue.
- Each team's starting kicker and his accuracy going into the week.
- Pre-game top-16 status.

Then run the models and #11, and write one projection file for the week. Open issue carried over from 04: the models train on closing lines, but the scraper captures whatever day it runs, and those lines can differ.

**13. Weather effects (needed before Kicker Friend can adjust for weather).** The models don't include weather yet, so there's no estimate of how much wind, temperature or rain changes attempts or accuracy. nflverse schedules record game-time temperature and wind for past outdoor games. Use them to estimate, by distance range, how weather shifts:
- how many FG attempts a team gets;
- how often kicks are made.

Those estimates become the adjustment Kicker Friend applies to forecasts. (Weather was deferred on 2026-09-22 because live use needs a forecast source; Kicker Friend's web search now provides one.)

**14. Kicker Friend (Claude Project).** A separate Claude Project with its own instructions, used to query projections. It should:
- Answer either "top N kickers this week" or questions about specific kickers.
- Show plots of each kicker's fantasy-point probability distribution.
- **Search up-to-date weather forecasts for each outdoor game and apply the weather adjustment from #13.** The adjustment should change the inputs (attempts and make rates by range) and recompute the distribution, rather than just shifting the average. For example, strong wind cuts 50+ tries and makes, which changes the shape of the distribution, not only its average.

Open design questions:
- How the weekly projection file (#12) gets into Kicker Friend: uploaded weekly, or read from somewhere.
- Whether Kicker Friend recomputes distributions itself with code, using per-kicker inputs in the projection file, or reads precomputed ones.
- How the weather adjustment is expressed so the instructions can apply it consistently.

**15. Maintenance: season setting.** `CURRENT_SEASON` is set separately in 01, 02, 03, 04 and 06. Before the 2027 season, move it to one place so it only changes once.

## Open questions (undecided)

- **Playoff data for the volume models.** Extending 02-04 to cover playoff games, so the volume models could train on them. Raised 2026-09-21, not decided.
