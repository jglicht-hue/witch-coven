# Weather effects (#13): method and results (2026-09-28)

**Files:**
- Scripts: `claude/11_build_weather_tables.R` (builds the tables) and `claude/11b_weather_effects.R` (runs selection with placebo checks and writes the effects).
- Agent helper: `claude/weather_adjust.py`.

These are not part of the weekly run. Rerun them only to re-estimate the effects.

## Data
- Regular-season games from **2016–2025**: 2,631 games, 1,870 of them outdoors, giving 5,262 team-games and 22,433 kicks.
  - This is 10 seasons instead of the models' 3, because weather effects are physical and bad-weather games are rare. Among outdoor games, 201 had wind of 15 mph or more, 79 were 30°F or colder, and 152 had rain or snow.
  - The user was told about this choice before results were seen.
- Weather source: nflverse's schedule file (game-time temperature and wind). Blanks are filled from the play-by-play weather text, which also supplies precipitation (rain, snow, sleet, drizzle, showers, flurries). 8 games were dropped for a missing roof or weather value.
- Terms, each 0 in dome or closed-roof games:
  - `wind` in mph;
  - `cold` = degrees below 40°F;
  - `precip` = 1 if rain or snow, else 0.

## Rules (set before results)
- **Attempt models** (Poisson, one row per team-game): XP, 0–39, 40–49 and 50+ attempts, each ~ implied team total + its square + dome. The implied total controls for what the betting line already prices in.
- **Make models** (logistic, one row per kick): 0–39, 40–49, 50+ and XP makes, each ~ dome.
- **Selection:** forward selection per outcome, as in 07c.
  - A term is kept if it beats at least 95% of 200 placebo shuffles. A shuffle permutes that weather variable among each season's outdoor games.
  - Score: leave-one-season-out deviance gain ×1000.

## Results

| Outcome | Terms tested (gain ×1000, placebo share) | Adopted |
|---|---|---|
| XP attempts | wind 0.90 (0.005); cold −0.17; precip −0.12 | **wind** |
| 0–39 attempts | all three negative | none |
| 40–49 attempts | cold 0.68 (0.035); wind 0.02 (0.195); precip −0.28 | **cold** |
| 50+ attempts | cold 2.00 (0.000); wind 0.61 (0.015); precip −0.81. After adding cold: wind 0.44 (**0.050**, fails by the strict rule) | **cold** |
| 0–39 makes | precip 0.43 (0.020); wind 0.16 (0.095); cold −0.01 | **precip** |
| 40–49 makes | wind 0.33 (0.110); cold −0.81; precip −0.12 | none |
| 50+ makes | all three negative | none |
| XP makes | wind 0.55 (0.010); cold 0.02 (0.135); precip −0.17 | **wind** |

Adopted effects, fit on all 10 seasons:

| Outcome | Term | Coefficient | Meaning |
|---|---|---|---|
| XP attempts | wind | −0.00597 per mph (SE 0.0022) | −0.6% per mph |
| 40–49 attempts | cold | −0.01200 per degree (SE 0.0059) | −1.2% per degree below 40°F |
| 50+ attempts | cold | −0.03020 per degree (SE 0.0090) | −3.0% per degree below 40°F |
| 0–39 makes | precip | −0.533 log-odds (SE 0.22) | odds ×0.59 (e.g. 97% → 95%) |
| XP makes | wind | −0.0225 log-odds per mph (SE 0.0083) | odds ×0.978 per mph |

**Reading the results:**
- **Cold matters most, by cutting long attempts.** At 20°F, 50+ attempts fall by about 43% and 40–49 attempts by about 20%.
- **Wind lowers XP attempts and XP makes a little.**
- **Wind's effect on 50+ attempts was borderline** (placebo share exactly 0.050), so it isn't applied.
- **No weather term improved the prediction of 40–49 or 50+ makes.** The likely reason is selection: coaches only attempt long kicks when conditions allow, so the long kicks that do happen in bad weather aren't much worse.

**Reference:** adjustments are relative to the average outdoor game of 2023–2025 (wind 7.85 mph, cold 1.20, precip share 0.077). The weekly models have no weather terms, so their outdoor projections already reflect average weather.

## Check on the points backtest
Game-day weather was applied to the 536 outdoor pre-game top-16 team-games from 08a's backtest. Actual weather stands in for a perfect forecast. This check is information only: no rule was set for it, and the effects were estimated on seasons that include these games.

| Measure | No weather | With weather | Seasons improved |
|---|---|---|---|
| Squared error | 20.96 | 20.82 | 3 of 3 |
| Log score | −2.914 | −2.912 | 3 of 3 |
| Squared error, 109 bad-weather games (wind ≥ 15, 30°F or colder, or rain/snow) | 19.17 | 18.54 | — |

In those bad-weather games the average projection went from 7.99 to 7.74, against an actual average of 7.39.

## Example (T.Bass, BUF, week 3 file: projected 9.57)

| Forecast | Adjusted projection | Main driver |
|---|---|---|
| 20 mph wind, 55°F, dry | 9.37 | fewer XP tries and makes |
| 8 mph, 20°F, dry | 8.53 | 50+ attempts 0.47 → 0.26 |
| 25 mph, 15°F, snow | 7.75 | all effects combined |

## Caveats
- **Forecasts vs actuals:** training used measured game-time weather, while live use relies on forecasts, which are noisier. Real effects may be somewhat smaller.
- **Confidence interval:** it isn't recomputed. The helper shifts it by the change in projected points, which is approximate.
- **Retractable roofs:** for a `roof_unknown` game, the file's expected attempts already include a partial dome effect (dome share about 0.33). The helper can't remove that. If the roof will be open, apply the weather and also say the projection is likely too high because of the dome placeholder.
