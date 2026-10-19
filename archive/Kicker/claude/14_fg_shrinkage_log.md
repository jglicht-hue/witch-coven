# 14 — FG accuracy shrinkage weight and blocked kicks (2026-09-28)

Script: `claude/14_fg_shrinkage_experiments.R`. This is an experiment only; nothing in the pipeline changed.

## Question

Scripts 05 and 09 estimate a kicker's make chance in each range as:

> p = (decayed makes + w × league rate) / (decayed attempts + w)

- "Decayed" means older kicks count less (12-game half-life).
- The weight is w = 5. It was a design-phase value and had never been tested.

Two questions:
1. Does another w pick better kickers week to week?
2. Should blocked FGs be left out of a kicker's accuracy record? They still score −1.

The user's priority: identify good kicker games more than predict the average.

## Rules (set before any results were seen)

- **Sample:** every kicker-game (all teams) in the 2019–2025 regular season, 3,708 kicker-games over 124 weeks.
  - Inputs come from `build_week_inputs()` (09), using 06b's kicker rule and the 4-season window a live run would use.
  - The volume models are unchanged; their kicker-accuracy features stay at w = 5. Only the make chances change.
- **Primary metric: pairwise hit rate.** Take every pair of kickers in the same week whose actual points differ. The hit rate is the share of pairs where the higher projection scored more. A tie in projection counts as half.
- **Secondary metrics** (reported, not used to decide):
  - top-12 capture: the average actual points of each week's 12 highest projections;
  - mean squared error (MSE) of projected points;
  - Brier score (squared error of a make/miss prediction) of the make chances, on each game's actual attempts.
- **Grid:** w = 0, 1, 2, 5, 10, 20, 35, 50, 75, 100, 150, 200, 300, 500 and ∞. w = ∞ means the league rate for everyone.
- **Test A (w).**
  - Pick w leave-one-season-out: the best pooled hit rate on six seasons, scored on the seventh.
  - Adopt it only if both hold:
    1. It beats w = 5 in at least 95% of 2,000 week-block bootstrap resamples.
    2. It beats w = 5 in at least 5 of 7 held-out seasons.
  - If ranking can't separate the options but the Brier score clearly prefers one, the choice goes to the user as a decision rather than being adopted.
- **Test B (blocks):** same rules. Blocked FGs are dropped from the record, with w picked leave-one-season-out within that variant, and compared against Test A's winner.

## Checks

- At w = 5, the recomputed make chances reproduce 09's exactly.
- Projected points are computed analytically as the mean of the distribution. On 25 random rows this matched the full distribution from `points_pmf_dep` to within 1e-4.

## Results

### Grid (blocked kicks counted as misses, as now)

| w | Pairwise hit rate | Top-12 capture | MSE | Brier ×1000 | SD of projections |
|---|---|---|---|---|---|
| 0 (his raw record) | 0.5457 | 8.35 | 20.86 | 126.69 | 1.21 |
| 1 | 0.5494 | 8.35 | 20.71 | 122.17 | 1.13 |
| 2 | 0.5511 | 8.39 | 20.65 | 120.45 | 1.08 |
| **5 (current)** | **0.5526** | **8.42** | **20.58** | **118.35** | **1.02** |
| 10 | 0.5530 | 8.45 | 20.55 | 117.27 | 0.98 |
| 20 | 0.5526 | 8.47 | 20.54 | 116.74 | 0.95 |
| 35 | 0.5524 | 8.47 | 20.54 | 116.62 | 0.93 |
| 50 | 0.5521 | 8.46 | 20.55 | 116.62 | 0.92 |
| 100 | 0.5519 | 8.46 | 20.55 | 116.67 | 0.92 |
| 200 | 0.5514 | 8.45 | 20.56 | 116.74 | 0.91 |
| ∞ (league rate for all) | 0.5511 | 8.45 | 20.56 | 116.83 | 0.91 |

For context, ranking by points per game going into the week gives a hit rate of 0.5302, and a coin flip gives 0.5.

### Test A: FAILS, so w = 5 stays for ranking

- Leave-one-season-out picked w = 10, 10, 5, 20, 10, 5, 20 for 2019–2025.
- Held-out hit rate was 0.5507 for the picked w vs 0.5526 at w = 5, a difference of −0.0019 (bootstrap 90% range −0.0032 to −0.0006).
- The picked w was better in 1 of 7 seasons.
- Fixed-w comparisons against 5: every w from 10 to ∞ is within ±0.002, and none is separable. w of 0–2 is clearly worse.

### Test B (blocked kicks left out): FAILS

- Leave-one-season-out picked w = 10 in six seasons and 20 in one.
- Held-out hit rate was 0.5527 vs 0.5526 (+0.0001; bootstrap share not better 0.48). It was better in 3 of 7 seasons.

### Brier score: clearly prefers heavier shrinkage

The rule sends this to the user as a decision.

| Season | w = 5 | 20 | 35 | 50 | 100 | ∞ |
|---|---|---|---|---|---|---|
| 2019 | 132.15 | 129.86 | 129.62 | 129.57 | 129.57 | 129.67 |
| 2020 | 118.10 | 116.88 | 116.87 | 116.93 | 117.07 | 117.34 |
| 2021 | 114.23 | 112.71 | 112.54 | 112.51 | 112.50 | 112.57 |
| 2022 | 119.05 | 117.32 | 117.11 | 117.06 | 117.05 | 117.11 |
| 2023 | 110.07 | 108.38 | 108.14 | 108.07 | 108.02 | 108.02 |
| 2024 | 121.84 | 120.75 | 120.85 | 120.97 | 121.21 | 121.62 |
| 2025 | 114.44 | 112.66 | 112.53 | 112.54 | 112.62 | 112.82 |

- Leave-one-season-out on Brier picks w = 35 in four seasons and 50 in three.
- Held-out Brier ×1000 is 116.65 vs 118.35 at w = 5, better in 7 of 7 seasons. In the week-block bootstrap, 0 of 2,000 resamples were not better (90% range −2.4 to −1.0).

## Reading

- **Kicker-specific FG accuracy carries little signal.** Setting everyone to the league rate (w = ∞) loses only 0.0015 of hit rate, and its Brier score is better than w = 5. Most of the model's edge over points-per-game comes from volume (how many kicks, from what range), not from who's kicking.
- **w = 5 is too light for predicting make chances.** One or two kicks move a kicker's rate a lot. A weight of about 35–50 league-average kicks predicts makes better every season. That fits the XP result (w = 100): kicking accuracy is mostly noise over the samples we have.
- **For ranking, anything from 5 to ∞ is equivalent within noise.** Only very light shrinkage (w ≤ 2) is clearly worse.
- **Effect on projections of w = 50 vs w = 5:**
  - the projection changes with a standard deviation of 0.26 points, and 90% of changes are under 0.42 (max 1.1);
  - the weekly top 12 changes by about 1.2 kickers per week;
  - the spread of projections narrows (SD 1.02 → 0.92).
- **Example, 2026 week 4 at w = 35:**
  - Smack moves from 8.02 (19th of 32) to 8.08 (18th).
  - Shrader moves from 8.41 (14th) to 8.05 (19th), so they are essentially tied.
  - Smack's 40–49 make chance moves from 0.716 to 0.787; Shrader's from 0.895 to 0.825.

## Decision needed

Recommended: move the make-chance weight to w = 35. The volume models' accuracy features stay at w = 5.

**Why:**
- Ranking is indifferent.
- Make predictions are better in every season.
- MSE improves slightly (20.58 → 20.54).
- Top-12 capture is up slightly (+0.05, within noise).

**If approved, the changes are:**
- 05 and 09: split the constant so make chances and the CI's Beta parameters use 35 while `krate_*` stays at 5.
- Rerun 09a, which must still pass for the volume features.
- Rerun 08a and confirm the points backtest still passes its 4 rules.
- The weekly file's `p_039/4049/50` and projections will shift as shown above.
