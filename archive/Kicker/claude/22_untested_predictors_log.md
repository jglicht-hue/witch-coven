# #22 Untested volume predictors, model forms and the narrow passes: test log

As of 2026-10-03. Run in a Kicker Wizerd chat as a one-off override of "don't edit scripts" (user request). Script: `claude/22_untested_predictors_tests.R`. Nothing in the production models, scripts, weekly files or the scheduled task was changed.

This covers the "Not tested yet" list in the volume modeling log (`claude/v3.1_07_volume_modeling_log.md`), items 1, 2, 3, 5 and 6, and its caveat that the narrow placebo passes should be rechecked with 2026 data. Item 4 (weather) was done separately in #13.

## Result

**One predictor passes strongly: the point spread, in the 0–39 FG-attempts model.** Nothing else earns a place.

| Part | Tested | Result |
|---|---|---|
| A. New predictors | 15 predictors × 4 models = 59 tests | 1 strong pass (expected margin in 0–39); 4 plain passes that look like luck; 54 fail |
| B. Model forms | Multinomial split (2 versions); team / kicker random effects (12) | None pass |
| C. Narrow passes | 4 terms, plus 2 borderline checks | 2 hold with 2026 added, 2 slip above 0.05; none is refuted |

**Decision needed:** whether to add expected margin to the 0–39 model. It met the rule set before the results. The one thing against it is the first three weeks of 2026, which lean the other way on a small sample (see "The catch").

## Setup

- **Pipeline:** rebuilt in the Claude workspace from the project's scripts with fresh nflverse data. Validation gains reproduce exactly: 177.431 / 13.243 / 19.591 / 20.296 on 832 pre-game top-16 team-games.
- **Base models:** the four production volume models (07's `FINAL_MODELS`), unchanged.
- **Scoring:** as in 07c. Models are trained and judged on pre-game top-16 team-games, leave-one-season-out over 2023–2025. Error is the mean Poisson deviance per held-out team-game, ×1000. Gain is how much a change lowers it; positive is better.
- **Placebo share:** the predictor's values are shuffled within each season and the model refit; the share is how often a shuffled version did at least as well as the real one. 2,000 shuffles, and 10,000 more for anything under 0.10.
- **2026 data:** 98 team-games played through 2026-10-01 (weeks 1–3 and the week-4 Thursday game), 49 of them pre-game top 16. Their inputs come from 09's `build_week_inputs()`, which was checked against the training table on 2025 week 10 (largest difference 2e-15).

## Rules, set before any result was computed

**A. New predictors**
- **Pass (07c's rule):** gain above 0 and placebo share below 0.05.
- **Strong pass:** placebo share below 0.05/15 ≈ 0.0033 and better in at least 2 of 3 seasons. With 59 tests, about 3 plain passes are expected by luck.
- **Recommended** only if a strong pass and the points backtest (squared error and top-16 pairwise hit rate) isn't worse.

**B. Model forms**
- **Pass:** better in at least 2 of 3 seasons; under 0.05/k of game-resamples show no gain (k = versions tried); and points squared error not worse.

**C. Narrow passes**
- **Holds:** placebo share stays below 0.05 once 2026 is added as a fourth held-out season.
- **2026 alone** is reported but was called too small to judge before it was looked at.

## A. New predictors

### What was built
All are known before kickoff. Trailing windows cover the games strictly before the one being predicted and cross seasons (2022 play-by-play was added so every window is full).

| Predictor | Definition |
|---|---|
| Team FG attempts per game | The team's FG attempts per game over its last 8 games, and last 16 |
| Team attempts in this range | Same, last 8 games, for the model's own range (range models only) |
| Expected margin | The team's expected winning margin from the spread: positive = favored. Equal to its implied total minus the opponent's |
| Absolute expected margin | How lopsided the game is expected to be |
| Offense EPA per play | Expected points added per run or pass play, last 8 games |
| Drives per game, plays per game | Offensive drives, and run plus pass plays, per game, last 8 games |
| Opponent defense EPA per play | EPA per play the opponent's defense allowed, last 8 games (added by Claude; not on the original list) |
| Grass vs turf | From the schedule's surface field; 44 blanks filled from the stadium's usual surface (3 international games set to grass by hand) |
| Retractable roof open / closed | Two flags, so a retractable roof can differ from a fixed dome or a true outdoor stadium |
| Primetime | Kickoff at 7pm Eastern or later |
| Rest days, short rest | Days since the team's last game (capped at 14); under 7 days |
| Week of season | Week number |

### The strong pass: expected margin in the 0–39 model

| Measure | Value |
|---|---|
| Held-out error, ×1000 | 1098.5 → 1084.7 (gain +13.7) |
| Gain over the league average | 13.2 → 27.0, about double |
| By season | +12.3 (2023), +13.0 (2024), +15.8 (2025) |
| Placebo share | 0.0001 (1 of 10,000 shuffles did as well) |
| Coefficient | +0.030 per point of margin (z = 2.9); 0.033 / 0.028 / 0.028 across the three fits |

- **What it means.** At the same implied total, each extra point of expected margin adds about 3% to 0–39 attempts. Written the other way, each extra point the opponent is expected to score cuts them by 3%; the two forms are the same model.
- **Size.** For an outdoor team with an implied total of 23 and median other inputs:

| Expected margin | Game total | 0–39 attempts, current model | With margin |
|---|---|---|---|
| −7 (underdog) | 53 | 1.03 | 0.79 |
| 0 | 46 | 1.03 | 0.97 |
| +7 (favorite) | 39 | 1.03 | 1.20 |

  A 7-point favorite gets about 0.4 more short attempts than a 7-point underdog with the same implied total, which is a little over 1 fantasy point.
- **Why it is plausible.** A team that is ahead takes the short FG; a team that is behind or in a shootout goes for it on fourth down.
- **It survives the strictest bar.** 0.0001 is below 0.05/59 = 0.00085, a correction over all 59 tests.
- **Only short FGs.** Margin added to the 40–49 model made it worse (−9.2), and it did nothing for 50+ (−2.3) or XP (−1.2).
- **Not a stand-in for the squared term.** With margin in the model, the squared implied total still adds +3.4.

### Points backtest (832 pre-game top-16 team-games, leave-one-season-out, as 08a)
The top-16 hit rate is 14c's: among pairs of top-16 kickers in the same week whose scores differ, how often the higher projection scored more. Resamples are of whole weeks (2,000).

| Model | Squared error | Change | Seasons better | Share of resamples not better | Top-16 hit rate | Change | Seasons better | Share not better |
|---|---|---|---|---|---|---|---|---|
| current | 22.084 | +0.000 | 0/3 | 1.000 | 0.5685 | +0.0000 | 0/3 | 1.000 |
| 0-39 + expected margin (strong pass) | 21.814 | -0.271 | 3/3 | 0.005 | 0.5845 | +0.0160 | 3/3 | 0.003 |
| XP + team FG attempts, last 8 (plain pass) | 22.052 | -0.032 | 2/3 | 0.218 | 0.5667 | -0.0017 | 1/3 | 0.745 |
| XP + rest days (plain pass) | 22.084 | -0.000 | 1/3 | 0.510 | 0.5649 | -0.0036 | 0/3 | 0.924 |
| 50+ + primetime (plain pass) | 22.093 | +0.008 | 2/3 | 0.556 | 0.5676 | -0.0009 | 1/3 | 0.627 |
| 50+ + week of season (plain pass) | 22.110 | +0.026 | 2/3 | 0.649 | 0.5698 | +0.0014 | 2/3 | 0.098 |
| multinomial split, all current predictors | 22.292 | +0.207 | 1/3 | 0.911 | 0.5700 | +0.0015 | 1/3 | 0.430 |
| multinomial split, lean | 22.237 | +0.153 | 1/3 | 0.799 | 0.5751 | +0.0067 | 2/3 | 0.189 |
| random effect, team, all four models | 22.049 | -0.035 | 2/3 | 0.214 | 0.5654 | -0.0031 | 1/3 | 0.810 |
| random effect, kicker, all four models | 22.015 | -0.069 | 3/3 | 0.048 | 0.5683 | -0.0002 | 1/3 | 0.530 |
| random effects, team and kicker, all four models | 22.031 | -0.053 | 3/3 | 0.127 | 0.5685 | +0.0000 | 1/3 | 0.492 |

- **Margin improves both measures in all three seasons.** Squared error falls from 22.084 to 21.814 and the hit rate rises from 0.5685 to 0.5845.
- **For scale:** kicker accuracy as a whole was worth +0.0049 of hit rate in #18 (measured on 2016–2025). This is +0.0160 on 2023–2025.
- **Projections move by 0.23 points on average,** and by 1.10 at most.

### Extra checks on margin (added after the result; not part of the pre-set rules)
These use a reduced model that needs no pipeline features: 0–39 attempts on implied total, its square and margin, on every regular-season team-game.

| Season | Team-games | Margin coefficient, that season alone (95% range) | Walk-forward gain | Coefficient used |
|---|---|---|---|---|
| 2016 | 512 | +0.007 (-0.020 to +0.034) |  |  |
| 2017 | 512 | +0.018 (-0.006 to +0.043) |  |  |
| 2018 | 512 | +0.012 (-0.011 to +0.034) |  |  |
| 2019 | 512 | +0.008 (-0.017 to +0.033) | -0.7 | 0.014 |
| 2020 | 512 | +0.008 (-0.017 to +0.033) | +4.3 | 0.014 |
| 2021 | 544 | +0.022 (-0.002 to +0.046) | +4.4 | 0.010 |
| 2022 | 542 | +0.025 (+0.000 to +0.050) | +6.1 | 0.015 |
| 2023 | 544 | +0.033 (+0.009 to +0.057) | +14.1 | 0.019 |
| 2024 | 544 | +0.020 (-0.006 to +0.046) | +3.8 | 0.026 |
| 2025 | 544 | +0.022 (-0.003 to +0.046) | +6.8 | 0.026 |
| 2026 (weeks 1-4) | 98 | -0.042 (-0.109 to +0.025) | -22.4 | 0.026 |

- **The effect is there in 2016–2022 too.** Leave-one-season-out on those seven seasons (3,646 team-games): gain +3.4, better in 5 of 7 seasons, and none of 2,000 shuffles did as well.
- **Every season from 2016 to 2025 has a positive coefficient** (10 of 10).
- **It has grown.** The pooled coefficient is +0.016 (standard error 0.005) for 2016–2022 and +0.026 (0.007) for 2023–2025 in this reduced model.
- **Walk-forward, the way the pipeline runs** (fit on the three seasons before, score the next): better in 6 of 7 seasons for 2019–2025, pooled gain +5.6 (95% range +1.6 to +9.7).
- **The 2023–25 fit does not transfer backwards.** Applied to 2016–2022 it is slightly worse than no margin (−1.7), because the effect was about half as large then.

### The catch: 2026 so far
Models fit on 2023–25, scored on 2026 games already played.

| Measure (pre-game top 16, 49 team-games) | Current | With margin |
|---|---|---|
| 0–39 attempts error, gain ×1000 | | −44.7 (95% range −112.3 to +9.9) |
| Points squared error | 21.32 | 21.50 (gain −0.19; 95% range −0.70 to +0.31) |
| Top-16 pairwise hit rate (337 pairs) | 0.421 | 0.451 |

- **Attempts lean against it.** 93% of resamples show margin hurting the 0–39 model in 2026. In these three weeks favorites have kicked fewer short FGs than underdogs.
- **Points are a wash:** squared error is slightly worse and the hit rate slightly better.
- **The sample is small.** The 2026 coefficient is −0.042 with a 95% range of −0.109 to +0.025, about 2 standard errors from the 2023–25 estimate. One season in eleven sitting that far out is not unusual, but it is the newest data.
- **Including 2026 does not overturn it:** the walk-forward gain for 2019–2026 is +4.9 (+0.9 to +8.9).

### The four plain passes (not recommended)

| Model | Predictor | Gain | Seasons better | Placebo share | Coefficient | 2026 gain | Points check |
|---|---|---|---|---|---|---|---|
| XP | Team FG attempts per game, last 8 | +4.2 | 2/3 | 0.014 | −0.121 per attempt | −7.9 | hit rate −0.002 |
| XP | Rest days | +3.0 | 3/3 | 0.028 | +0.018 per day | +5.0 | hit rate −0.004 |
| 50+ | Primetime | +6.6 | 3/3 | 0.008 | +0.243 | −60.1 | hit rate −0.001 |
| 50+ | Week of season | +5.2 | 3/3 | 0.016 | −0.017 per week | +3.6 | squared error worse |

- **About 3 passes were expected by luck** from 59 tests, and none of these four clears the strong bar.
- **None improves the points backtest.**
- **Week of season in 50+ is probably cold weather,** which `weather_adjust.py` already handles at answer time. Adding it would count cold twice.

### What it would change this week (illustration only)
Week 4 rebuilt with nflverse's lines as of 2026-10-03; ranks are by projection before any weather adjustment. Where the line hasn't moved since Friday's file (16 of 32 teams), the rebuilt current projection matches the file to 0.0005.

| Kicker (team vs opponent) | Implied total | Expected margin | 0-39 attempts: current | with margin | Projection: current | with margin | Change | Rank: current | with margin |
|---|---|---|---|---|---|---|---|---|---|
| W.Reichard (MIN vs MIA) | 24.25 | +10.0 | 1.01 | 1.29 | 11.03 | 11.85 | +0.82 | 1 | 1 |
| H.Mevis (LA vs PHI) | 23.00 | +3.5 | 1.02 | 1.06 | 9.30 | 9.43 | +0.12 | 3 | 2 |
| N.Folk (ATL vs NO) | 23.00 | -1.5 | 0.92 | 0.86 | 9.56 | 9.38 | -0.18 | 2 | 3 |
| J.Myers (SEA vs LAC) | 24.75 | +7.0 | 1.18 | 1.28 | 9.00 | 9.26 | +0.27 | 9 | 4 |
| K.Fairbairn (HOU vs DAL), roof unknown | 25.75 | +3.0 | 1.02 | 0.97 | 9.27 | 9.11 | -0.16 | 4 | 5 |
| T.Bass (BUF vs NE) | 28.75 | +7.0 | 0.92 | 0.84 | 9.22 | 9.01 | -0.21 | 5 | 6 |
| T.Loop (BAL vs TEN) | 26.50 | +11.5 | 0.90 | 1.05 | 8.48 | 8.92 | +0.43 | 14 | 7 |
| B.Aubrey (DAL vs HOU), roof unknown | 22.75 | -3.0 | 1.18 | 1.05 | 9.14 | 8.77 | -0.37 | 6 | 8 |
| E.Pineiro (SF vs DEN) | 25.75 | +3.0 | 1.09 | 1.01 | 9.00 | 8.75 | -0.25 | 8 | 9 |
| E.McPherson (CIN vs JAX) | 27.00 | +2.5 | 1.12 | 0.96 | 9.00 | 8.53 | -0.47 | 7 | 10 |
| H.Butker (KC vs LV) | 26.00 | +4.5 | 0.83 | 0.83 | 8.51 | 8.50 | -0.01 | 13 | 11 |
| C.Santos (CHI vs NYJ) | 23.50 | +3.5 | 0.92 | 0.94 | 8.40 | 8.48 | +0.07 | 16 | 12 |
| D.Carlson (NO vs ATL) | 24.50 | +1.5 | 1.05 | 1.02 | 8.53 | 8.44 | -0.10 | 12 | 13 |
| S.Shrader (IND vs WAS) | 25.50 | +4.5 | 0.84 | 0.83 | 8.42 | 8.39 | -0.03 | 15 | 14 |
| C.Little (JAX vs CIN) | 24.50 | -2.5 | 1.18 | 0.96 | 8.96 | 8.32 | -0.64 | 10 | 15 |
| J.Bates (DET vs CAR) | 27.50 | +3.5 | 0.91 | 0.80 | 8.59 | 8.26 | -0.33 | 11 | 16 |
| T.Smack (GB vs TB) | 20.75 | +3.0 | 0.98 | 1.10 | 7.87 | 8.21 | +0.34 | 21 | 17 |
| C.Boswell (PIT vs CLE), played | 20.50 | +2.5 | 0.96 | 1.08 | 7.80 | 8.13 | +0.33 | 22 | 18 |
| C.Ryland (ARI vs NYG) | 23.50 | +2.5 | 1.06 | 1.05 | 8.03 | 8.01 | -0.01 | 19 | 19 |
| M.Gay (LV vs KC) | 21.50 | -4.5 | 0.88 | 0.79 | 8.13 | 7.89 | -0.24 | 18 | 20 |
| A.Szmyt (CLE vs PIT), played | 18.00 | -2.5 | 1.01 | 1.06 | 7.57 | 7.70 | +0.13 | 25 | 21 |
| W.Lutz (DEN vs SF) | 22.75 | -3.0 | 1.16 | 1.00 | 8.16 | 7.69 | -0.47 | 17 | 22 |
| J.Sanders (NYJ vs CHI) | 20.00 | -3.5 | 0.98 | 0.93 | 7.74 | 7.59 | -0.15 | 23 | 23 |
| R.Fitzgerald (CAR vs DET) | 24.00 | -3.5 | 0.98 | 0.79 | 7.98 | 7.46 | -0.52 | 20 | 24 |
| D.Zvada (NYG vs ARI) | 21.00 | -2.5 | 0.89 | 0.84 | 7.49 | 7.35 | -0.14 | 27 | 25 |
| C.Dicker (LAC vs SEA) | 17.75 | -7.0 | 0.94 | 0.87 | 7.51 | 7.30 | -0.20 | 26 | 26 |
| A.Borregales (NE vs BUF) | 21.75 | -7.0 | 0.96 | 0.77 | 7.74 | 7.22 | -0.51 | 24 | 27 |
| C.McLaughlin (TB vs GB) | 17.75 | -3.0 | 0.77 | 0.82 | 7.07 | 7.20 | +0.13 | 29 | 28 |
| J.Elliott (PHI vs LA) | 19.50 | -3.5 | 0.93 | 0.90 | 7.05 | 6.96 | -0.09 | 30 | 29 |
| D.Stevens (WAS vs IND) | 21.00 | -4.5 | 0.99 | 0.88 | 7.25 | 6.94 | -0.32 | 28 | 30 |
| R.Patterson (MIA vs MIN) | 14.25 | -10.0 | 0.66 | 0.65 | 6.07 | 6.04 | -0.03 | 31 | 31 |
| J.Slye (TEN vs BAL) | 15.00 | -11.5 | 0.70 | 0.63 | 5.88 | 5.68 | -0.20 | 32 | 32 |

### All 59 tests
"2026 gain" is the forward check on 49 top-16 team-games and is noisy.

| Model | Predictor added | Gain | Seasons better | Placebo share | 2026 gain | Result |
|---|---|---|---|---|---|---|
| XP | Team FG attempts per game, last 8 | +4.2 | 2/3 | 0.0137 | -7.9 | pass (not strong) |
| XP | Team FG attempts per game, last 16 | -1.3 | 2/3 |  | +2.0 | no gain |
| XP | Expected margin (spread) | -1.2 | 1/3 |  | -1.3 | no gain |
| XP | Absolute expected margin | -1.8 | 2/3 |  | -5.0 | no gain |
| XP | Offense EPA per play, last 8 | -2.4 | 0/3 |  | +1.1 | no gain |
| XP | Drives per game, last 8 | -1.6 | 0/3 |  | +0.0 | no gain |
| XP | Plays per game, last 8 | -0.7 | 0/3 |  | -0.3 | no gain |
| XP | Opponent defense EPA per play, last 8 | -1.6 | 2/3 |  | -25.6 | no gain |
| XP | Grass vs turf | +0.3 | 1/3 | 0.1690 | -3.0 | fails |
| XP | Retractable roof open / closed | -4.2 | 0/3 |  | -0.9 | no gain |
| XP | Primetime | +1.6 | 2/3 | 0.0746 | -3.9 | fails |
| XP | Rest days | +3.0 | 3/3 | 0.0277 | +5.0 | pass (not strong) |
| XP | Short rest | -2.8 | 1/3 |  | -0.1 | no gain |
| XP | Week of season | -0.3 | 1/3 |  | -3.0 | no gain |
| 0-39 | Team FG attempts per game, last 8 | -2.8 | 0/3 |  | +5.5 | no gain |
| 0-39 | Team FG attempts per game, last 16 | -2.9 | 2/3 |  | -6.2 | no gain |
| 0-39 | Team attempts in this range per game, last 8 | -1.3 | 1/3 |  | +1.7 | no gain |
| 0-39 | Expected margin (spread) | +13.7 | 3/3 | 0.0001 | -44.7 | **strong pass** |
| 0-39 | Absolute expected margin | -0.4 | 1/3 |  | -1.5 | no gain |
| 0-39 | Offense EPA per play, last 8 | -6.7 | 1/3 |  | +2.4 | no gain |
| 0-39 | Drives per game, last 8 | -9.6 | 0/3 |  | -1.8 | no gain |
| 0-39 | Plays per game, last 8 | -0.5 | 0/3 |  | +0.0 | no gain |
| 0-39 | Opponent defense EPA per play, last 8 | -3.7 | 1/3 |  | -4.7 | no gain |
| 0-39 | Grass vs turf | -13.1 | 0/3 |  | +2.4 | no gain |
| 0-39 | Retractable roof open / closed | -1.1 | 0/3 |  | +28.8 | no gain |
| 0-39 | Primetime | -3.8 | 1/3 |  | +3.7 | no gain |
| 0-39 | Rest days | -8.4 | 0/3 |  | +0.3 | no gain |
| 0-39 | Short rest | -0.6 | 2/3 |  | -0.4 | no gain |
| 0-39 | Week of season | +1.8 | 2/3 | 0.0770 | +18.2 | fails |
| 40-49 | Team FG attempts per game, last 8 | -0.5 | 1/3 |  | +0.8 | no gain |
| 40-49 | Team FG attempts per game, last 16 | +0.1 | 2/3 | 0.2430 | -4.2 | fails |
| 40-49 | Team attempts in this range per game, last 8 | -1.6 | 0/3 |  | +0.5 | no gain |
| 40-49 | Expected margin (spread) | -9.2 | 1/3 |  | -3.8 | no gain |
| 40-49 | Absolute expected margin | +0.5 | 2/3 | 0.1595 | +16.0 | fails |
| 40-49 | Offense EPA per play, last 8 | -7.7 | 0/3 |  | +0.1 | no gain |
| 40-49 | Drives per game, last 8 | -3.2 | 0/3 |  | -6.2 | no gain |
| 40-49 | Plays per game, last 8 | -1.9 | 0/3 |  | +5.9 | no gain |
| 40-49 | Opponent defense EPA per play, last 8 | -0.8 | 2/3 |  | -27.5 | no gain |
| 40-49 | Grass vs turf | -3.1 | 0/3 |  | -15.7 | no gain |
| 40-49 | Retractable roof open / closed | +0.1 | 2/3 | 0.2225 | -65.5 | fails |
| 40-49 | Primetime | +0.3 | 2/3 | 0.2085 | -1.1 | fails |
| 40-49 | Rest days | +0.7 | 2/3 | 0.1545 | +0.1 | fails |
| 40-49 | Short rest | +0.8 | 2/3 | 0.1425 | +10.6 | fails |
| 40-49 | Week of season | -0.3 | 0/3 |  | +1.5 | no gain |
| 50+ | Team FG attempts per game, last 8 | -1.2 | 0/3 |  | +2.8 | no gain |
| 50+ | Team FG attempts per game, last 16 | -2.4 | 1/3 |  | -12.5 | no gain |
| 50+ | Team attempts in this range per game, last 8 | -1.4 | 1/3 |  | +3.0 | no gain |
| 50+ | Expected margin (spread) | -2.3 | 2/3 |  | -5.4 | no gain |
| 50+ | Absolute expected margin | -1.6 | 1/3 |  | +10.0 | no gain |
| 50+ | Offense EPA per play, last 8 | -1.2 | 2/3 |  | +8.4 | no gain |
| 50+ | Drives per game, last 8 | -2.5 | 2/3 |  | -24.7 | no gain |
| 50+ | Plays per game, last 8 | -0.1 | 1/3 |  | +0.7 | no gain |
| 50+ | Opponent defense EPA per play, last 8 | -1.8 | 2/3 |  | -19.3 | no gain |
| 50+ | Grass vs turf | -0.8 | 1/3 |  | -2.9 | no gain |
| 50+ | Retractable roof open / closed | -7.5 | 1/3 |  | +50.1 | no gain |
| 50+ | Primetime | +6.6 | 3/3 | 0.0083 | -60.1 | pass (not strong) |
| 50+ | Rest days | +2.5 | 2/3 | 0.0607 | +7.3 | fails |
| 50+ | Short rest | -0.3 | 1/3 |  | -8.3 | no gain |
| 50+ | Week of season | +5.2 | 3/3 | 0.0156 | +3.6 | pass (not strong) |

## B. Model forms

Gain is against the current model for that outcome. For the multinomial split it is the three FG ranges summed, against the three current range models summed (3166.1).

| Form | Gain | Seasons better | 95% range (game resamples) | Share with no gain | Bar | Passes |
|---|---|---|---|---|---|---|
| multinomial split, all current predictors (3 ranges summed) | -54.1 | 0/3 | -83.4 to -25.0 | 1.000 | 0.025 | no |
| multinomial split, lean (3 ranges summed) | -64.5 | 0/3 | -97.3 to -31.5 | 1.000 | 0.025 | no |
| random effect: team, XP attempts | -0.4 | 1/3 | -1.1 to +0.3 | 0.887 | 0.017 | no |
| random effect: team, 0-39 attempts | -1.9 | 1/3 | -5.7 to +1.7 | 0.837 | 0.017 | no |
| random effect: team, 40-49 attempts | -0.1 | 0/3 | -0.3 to +0.1 | 0.830 | 0.017 | no |
| random effect: team, 50+ attempts | +1.5 | 2/3 | -4.9 to +7.9 | 0.318 | 0.017 | no |
| random effect: kicker, XP attempts | -0.0 | 1/3 | -0.1 to +0.1 | 0.528 | 0.017 | no |
| random effect: kicker, 0-39 attempts | -0.9 | 2/3 | -3.0 to +1.1 | 0.821 | 0.017 | no |
| random effect: kicker, 40-49 attempts | -0.0 | 0/3 | -0.0 to +0.0 | 0.684 | 0.017 | no |
| random effect: kicker, 50+ attempts | +4.0 | 2/3 | -3.1 to +11.0 | 0.131 | 0.017 | no |
| random effect: team and kicker, XP attempts | -0.4 | 0/3 | -1.1 to +0.3 | 0.882 | 0.017 | no |
| random effect: team and kicker, 0-39 attempts | -2.8 | 0/3 | -7.0 to +1.3 | 0.908 | 0.017 | no |
| random effect: team and kicker, 40-49 attempts | -0.1 | 0/3 | -0.3 to +0.1 | 0.825 | 0.017 | no |
| random effect: team and kicker, 50+ attempts | +4.0 | 2/3 | -3.1 to +11.1 | 0.129 | 0.017 | no |

- **Multinomial split: worse in every season.**
  - *All current predictors:* one Poisson model for total FG attempts and a multinomial split, both using every predictor in the three range models. This is nearly the same as giving each range model all eleven terms (−52.4 when fit that way), so it overfits.
  - *Lean:* total attempts on implied total, its square, opponent red-zone rate, dome × coach long-range rate and dome × kicker 40+ accuracy; shares on dome × kicker 40+ accuracy, the kicker's 40–49 share and coach long-range rate.
- **Random effects: nothing to find.** The fitted team and kicker intercepts are tiny (standard deviations of 0.00 to 0.12 on the log scale), so predictions barely move. The best case, a kicker effect in the 50+ model, gains +4.0 with 13% of resamples showing no gain, against a bar of 1.7%.
- **Points:** the kicker random effect lowers squared error by 0.069 in all three seasons but leaves the hit rate unchanged (−0.0002). It did not pass the error rule, so it is not recommended.

## C. Narrow passes, rechecked

"Share 9/24" is the original placebo share from 500 shuffles. "2026 alone" is the gain on 2026's 49 top-16 team-games with models fit on 2023–25, with a 95% bootstrap range.

| Term | Share 9/24 (500) | Gain 2023-25 | Share 2023-25 (5,000) | Gain with 2026 | Share with 2026 | 2026 alone (49 team-games) | Holds |
|---|---|---|---|---|---|---|---|
| XP: coach long-range FG rate | 0.028 | +3.4 | 0.021 | +1.5 | 0.066 | -24.4 (-54.8 to +7.8) | no |
| 0-39: dome x coach long-range FG rate | 0.032 | +4.0 | 0.037 | +5.8 | 0.015 | +35.5 (+3.2 to +73.1) | yes |
| 40-49: kicker's 40-49 share (as first added) | 0.038 | +2.9 | 0.054 | +1.8 | 0.080 | -9.5 (-38.1 to +15.3) | no |
| 40-49: kicker's 40-49 share (dropped from the final model) | n/a | +6.7 | 0.008 | +4.7 | 0.022 | -16.1 (-47.0 to +11.8) | yes |
| 40-49: dome x coach long-range FG rate | 0.032 | +4.2 | 0.039 | +2.4 | 0.074 | -17.1 (-41.3 to +6.2) | no |
| 0-39: implied total squared (borderline check) | 0.038 | +1.7 | 0.095 | +2.0 | 0.066 | +2.0 (-19.2 to +24.1) | no |
| 50+: dome x kicker 50+ accuracy (borderline check) | 0.040 | +5.0 | 0.022 | +3.1 | 0.043 | -15.5 (-38.3 to +6.6) | yes |
| 50+: kicker 40+ accuracy (failed, kept by decision) | 0.730 | -3.5 | 0.755 | -2.5 | 0.684 | +9.7 (-2.0 to +21.2) | no |

- **Same data, more shuffles:** all four named terms land where they were, within noise. The kicker's 40–49 share is 0.054 as it was first added, but 0.008 when dropped from the final model, which is the test that matters now.
- **With 2026 added:**
  - *Holds:* dome × coach long-range rate in 0–39 (0.015), and the kicker's 40–49 share in the final model (0.022).
  - *Slips above 0.05:* coach long-range rate in XP (0.066), and dome × coach long-range rate in 40–49 (0.074).
- **Nothing is refuted.** Every 2026-alone range includes zero except dome × coach long-range rate in 0–39, which is positive.
- **Borderline checks:**
  - Dome × kicker 50+ accuracy holds (0.043).
  - The squared implied total in 0–39 fails when dropped from the final model (0.095 on 2023–25; 0.066 with 2026). Its 0.038 on 9/24 was against a model with implied total only.
  - Kicker 40+ accuracy in 50+ still fails (0.68), as known; it was kept by decision.
- **Recommendation: leave all of them in for now** and rerun this section at the week-11 scorecard checkpoint. The terms are worth 2 to 6 points of error per 1000, and three weeks of games cannot settle that.

## Caveats

- **Margin and implied total move together** (correlation 0.78 among top-16 team-games), so the margin coefficient is estimated less precisely than its placebo share suggests.
- **Line timing.** Training uses nflverse's near-closing lines; the weekly run uses whatever is posted on Tuesday or Friday. Margin would inherit that open question from the implied total.
- **The extra checks on margin were chosen after seeing the result.** They are replication on other seasons, not part of the rule.
- **Surface data is rough.** nflverse's surface field has blanks and a few doubtful entries, so "grass vs turf" is a weak test.
- **2026 inputs** use league averages (shrinkage targets) computed with 2026 games included, as the live weekly run does.

## If margin is adopted (for a build chat)

- **04 or 06:** add `exp_margin` to the team-game table (the home team's `spread_line`, sign flipped for the away team; equal to 2 × implied total − total line). Fill missing lines with 0.
- **07:** add `+ exp_margin` to the 0–39 formula. Validation gain should go from 13.243 to 26.991, and 08a's squared error from 22.084 to 21.814.
- **09, 09a, 09b:** add `exp_margin` to the weekly inputs and the check. The next-week file needs 0 where there is no line yet.
- **Instructions:** the "Lines" note says a higher implied total does not mean more FG attempts. It would need a line saying the spread now moves 0–39 attempts.
- **`weather_adjust.py`:** it works from the file's expected attempts, so it should need no change; confirm in the build.
- **Scorecard:** record the date the model changed.

## Files

| File | What it holds |
|---|---|
| `claude/22_untested_predictors_tests.R` | Every section, in run order, with the rules in the header |
| `t22_candidates.csv`, `t22_forms.csv`, `t22_narrow.csv`, `t22_points.csv` | Results behind the tables (workspace only, not saved to the project) |
| `t22_replication.csv`, `t22_walkforward.csv`, `t22_forward2026.csv`, `t22_week_illustration.csv` | The extra checks (workspace only) |
