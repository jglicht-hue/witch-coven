# Volume model testing log

As of 2026-09-23. Covers every model tested for the volume side of the projection: how many XP attempts and FG attempts (total and by 0-39 / 40-49 / 50+ range) a team gets in a game. Reproduce or extend any of it with `07a_volume_model_experiments.R`, which writes the full results (145 models) to `data/volume_experiment_results.csv`.

## How to read the numbers

Every model is scored the same way: fit on two seasons, predict the third, rotate through 2023, 2024 and 2025 (1,594 regular-season team-games).

- **Gain**: how much a model lowers held-out prediction error (mean Poisson deviance) compared with its reference model, shown in thousandths. Positive = better. For scale, guessing the league average gives an error of about 1,000–1,130 thousandths, depending on the outcome.
- **z**: the gain divided by its standard error. Treat a gain as real only when z is about 2 or more. Below that, it can't be told apart from luck.
- **x/3**: in how many of the three held-out seasons the model beat its reference.
- Written as: `+10.7 (1.8, 2/3)` = gain 10.7, z 1.8, better in 2 of 3 seasons.
- **Top-12**: the same gain, scored only on games where the kicker finished top 12 in fantasy points that season (the rostered kickers). Top 12 is picked using that season's results, so use it to compare models with each other, not as an absolute accuracy figure.

**Correction to earlier chat numbers.** Before 2026-09-23, results were quoted as a single held-out number, with no noise estimate, plus in-sample p-values from fits on all data. Some of those overstated how solid the effects are. Examples: dome's "33% more 50+ attempts, p = 0.0001" is an in-sample figure; on held-out seasons, dome's gain is only z = 1.3. The tables below replace those numbers.

## Where things stand

| Outcome | Proposed model | Gain vs league average | Evidence |
|---|---|---|---|
| XP attempts | Implied team total | +155.0 (8.5, 3/3) | Strong. The only unambiguous predictor on the volume side. |
| 0-39 FG attempts | Implied total + its square | +10.7 (1.8, 2/3) | Borderline |
| 40-49 FG attempts | League average (no predictors) | — | Nothing tested beats it |
| 50+ FG attempts | Dome + kicker 50+ accuracy | +14.0 (2.0, 3/3); top-12: +35.5 | Modest, most consistent of the FG ranges |

Bottom line: predicting FG volume is close to the noise floor with everything we have. The proposed FG models are kept because they are simple, have a sensible mechanism, and never move predictions far from the league average, so the risk of keeping them is low. Most of the week-to-week difference between rostered kickers will come from XP volume and kicker accuracy, not from FG volume.

Script 07 in the project still holds the original single-FG-model design. It will be rewritten once the choices below are settled.

## XP attempts

| Model | vs | Result |
|---|---|---|
| Implied total | league average | +155.0 (8.5, 3/3) |
| Implied total + its square | league average | +154.2 (8.6, 3/3) |
| Own red zone trips/game | league average | +60.9 (5.2, 3/3) |
| Opp. red zone TD rate allowed | league average | +8.4 (1.9, 3/3) |
| Own red zone TD rate | league average | +6.7 (1.1, 2/3) |
| Implied + its square | implied only | -0.8 (-0.6, 1/3) |
| Implied + own red zone TD rate | implied only | -2.3 (-1.5, 0/3) |
| Implied + own red zone trips | implied only | +1.2 (0.7, 2/3) |
| Implied + opp. red zone TD allowed | implied only | +1.1 (0.7, 2/3) |
| Implied + dome | implied only | -0.1 (-0.3, 2/3) |
| Implied + all 3 red zone measures | implied only | +1.2 (0.4, 2/3) |

Red zone trips predict XP attempts on their own, but add nothing once implied total is in. Decided 2026-09-22: implied total only.

## Total FG attempts (single model, since replaced by range models)

| Model | vs | Result |
|---|---|---|
| Implied total | league average | +2.3 (1.0, 3/3) |
| Implied total + its square | league average | +12.8 (2.1, 3/3) |
| Coach FG-or-go rate | league average | +2.3 (0.8, 2/3) |
| Dome | league average | +0.8 (0.3, 2/3) |
| Altitude | league average | -8.1 (-4.1, 0/3) |
| Own red zone TD rate | league average | -0.8 (-0.8, 2/3) |
| Own red zone trips/game | league average | -1.9 (-2.0, 0/3) |
| Opp. red zone TD rate allowed | league average | -0.3 (-0.6, 0/3) |
| Original agreed set (9 predictors) | league average | -9.0 (-1.5, 1/3) |
| Implied + its square + coach + dome | league average | +14.7 (2.1, 3/3) |
| … + implied × coach interaction | model above | -1.0 (-1.4, 0/3) |

FG attempts peak at an implied total of about 23 points: weak offenses rarely reach range, and strong ones score touchdowns instead. That's why the squared term matters. Summing the three proposed range models predicts total FG attempts as well as this single model (error 0.9934 vs 0.9931; gain -0.3, z -0.1), so switching to ranges costs nothing on the total.

## FG attempts by range: each predictor tested

**Alone** = the predictor on its own vs the league average. **Added** = added to the proposed model for that range (0-39: implied + its square; 50+: dome + kicker 50+ accuracy). The proposed 40-49 model *is* the league average, so for 40-49 "alone" and "added" are the same test.

| Predictor | 0-39 alone | 0-39 added | 40-49 alone | 50+ alone | 50+ added |
|---|---|---|---|---|---|
| Implied total | +1.0 (0.5, 2/3) | in model | -3.3 (-2.2, 0/3) | -0.9 (-0.7, 1/3) | -1.2 (-1.2, 1/3) |
| Implied total + its square | +10.7 (1.8, 2/3) | in model | -7.3 (-2.1, 1/3) | +0.7 (0.3, 1/3) | -0.6 (-0.3, 1/3) |
| Coach FG-or-go rate | +1.3 (0.9, 3/3) | +0.2 (0.2, 2/3) | -0.7 (-0.4, 1/3) | -0.8 (-0.2, 2/3) | -1.1 (-0.5, 2/3) |
| Dome | -0.7 (-0.4, 2/3) | -0.5 (-0.2, 2/3) | -2.3 (-0.8, 2/3) | +6.8 (1.3, 2/3) | in model |
| Altitude | -6.0 (-2.2, 1/3) | -4.3 (-1.6, 2/3) | -1.3 (-1.1, 0/3) | -2.1 (-0.8, 2/3) | -2.2 (-1.2, 1/3) |
| Own red zone TD rate | -0.6 (-0.2, 2/3) | -0.9 (-0.4, 2/3) | -0.1 (-0.1, 2/3) | -0.1 (-0.1, 1/3) | -0.1 (-0.3, 0/3) |
| Own red zone trips/game | -0.7 (-1.0, 1/3) | -0.4 (-0.2, 2/3) | -3.0 (-1.9, 1/3) | -0.0 (-0.1, 2/3) | -0.3 (-0.5, 0/3) |
| Opp. red zone TD rate allowed | +0.1 (0.0, 2/3) | +0.2 (0.1, 2/3) | +2.8 (1.2, 3/3) | -1.5 (-2.1, 1/3) | -1.8 (-2.1, 0/3) |
| Team share of FGs in this range (8 games) | -0.5 (-0.8, 0/3) | -0.2 (-0.6, 0/3) | -4.8 (-1.9, 1/3) | -2.9 (-1.4, 1/3) | -2.6 (-1.9, 0/3) |
| Kicker 0-39 accuracy | -1.1 (-0.7, 2/3) | -1.6 (-1.4, 1/3) | -1.2 (-1.6, 0/3) | -4.2 (-2.7, 0/3) | -5.5 (-3.0, 0/3) |
| Kicker 40-49 accuracy | -0.8 (-1.0, 0/3) | -0.5 (-0.8, 0/3) | -2.2 (-1.8, 0/3) | +5.2 (1.3, 2/3) | +5.8 (1.6, 3/3) |
| Kicker 50+ accuracy | -0.5 (-0.5, 0/3) | -0.6 (-0.5, 0/3) | -0.9 (-0.5, 1/3) | +7.4 (1.5, 2/3) | in model |
| Kicker attempts/game in this range (12-game half-life) | +0.3 (0.2, 2/3) | -0.4 (-0.7, 0/3) | -2.2 (-1.8, 0/3) | -0.1 (-0.0, 2/3) | -3.0 (-1.1, 1/3) |
| Kicker attempts/game in this range (full history) | -0.4 (-0.2, 1/3) | -1.0 (-1.1, 0/3) | -1.9 (-1.7, 0/3) | -2.8 (-0.7, 2/3) | -4.6 (-1.6, 1/3) |
| Kicker total FG attempts/game (12-game half-life) | +0.1 (0.1, 2/3) | -0.3 (-0.8, 0/3) | -0.1 (-0.1, 2/3) | -1.2 (-0.4, 2/3) | -1.3 (-0.7, 2/3) |
| Kicker share of FGs in this range (12-game half-life) | +0.1 (0.1, 2/3) | -0.1 (-0.1, 2/3) | -2.2 (-1.6, 0/3) | -2.1 (-0.7, 2/3) | -3.3 (-1.5, 1/3) |
| Kicker share of FGs in this range (full history) | +0.2 (0.1, 2/3) | -0.1 (-0.1, 2/3) | -1.6 (-1.6, 0/3) | -4.5 (-1.5, 2/3) | -4.9 (-2.0, 1/3) |

How the kicker predictors are built (all use only games before the one being predicted):
- Each team-game gets a kicker: whoever attempted the most FGs that game or, if the team attempted none, the team's most recent kicker.
- **Accuracy by range**: same method as script 05 (12-game half-life, shrunk toward the league rate).
- **Attempts per game in a range**: includes his teams' zero-FG games, shrunk toward the league per-game average.
- **Share of FGs in a range**: shrunk toward the league share.

What stands out:
- No volume or share measure helps in any range, whether kicker-based or team-based, at a 12-game half-life or full history. An earlier ad-hoc test also tried 24- and 48-game half-lives for the kicker's 50+ share. Each longer tail did slightly worse than the one before.
- Kicker accuracy only matters for 50+ attempts, and it's the long-range accuracies (40-49 and 50+) that matter. That fits coaches sending out kickers they trust from distance. Kicker 0-39 accuracy makes 50+ predictions worse.
- 40-49: nothing beats the league average. The closest is opponent red zone TD rate allowed (+2.8, z 1.2), but it's worse for top-12 kickers (-3.5).

## Interactions tested

| Outcome | Interaction | vs | Result | Top-12 |
|---|---|---|---|---|
| Total FG | Implied × coach FG-or-go | implied + its square + coach + dome | -1.0 (-1.4, 0/3) | -0.3 |
| 0-39 | Dome × kicker 0-39 accuracy | dome + that accuracy | -0.2 (-0.4, 2/3) | +0.0 |
| 0-39 | Dome × kicker 40-49 accuracy | dome + that accuracy | -5.1 (-3.0, 0/3) | -5.6 |
| 0-39 | Dome × kicker 50+ accuracy | dome + that accuracy | -0.6 (-1.0, 0/3) | -0.6 |
| 0-39 | Implied × kicker 0-39 accuracy | implied + its square + that accuracy | -2.9 (-2.6, 1/3) | -0.3 |
| 0-39 | Dome × kicker 0-39 volume | dome + that volume | -0.7 (-0.6, 2/3) | -3.5 |
| 0-39 | Kicker 0-39 share × 50+ accuracy | dome + 50+ accuracy + that share | +0.0 (0.0, 2/3) | -0.1 |
| 40-49 | Dome × kicker 0-39 accuracy | dome + that accuracy | -2.3 (-1.9, 0/3) | -1.6 |
| 40-49 | Dome × kicker 40-49 accuracy | dome + that accuracy | +1.8 (0.8, 2/3) | +9.0 |
| 40-49 | Dome × kicker 50+ accuracy | dome + that accuracy | +1.0 (0.7, 2/3) | +0.0 |
| 40-49 | Implied × kicker 40-49 accuracy | implied + its square + that accuracy | -0.3 (-0.2, 2/3) | -0.8 |
| 40-49 | Dome × kicker 40-49 volume | dome + that volume | -1.0 (-1.2, 0/3) | -1.9 |
| 40-49 | Kicker 40-49 share × 50+ accuracy | dome + 50+ accuracy + that share | +0.9 (0.4, 2/3) | +1.4 |
| 50+ | Dome × kicker 0-39 accuracy | dome + that accuracy | -0.0 (-0.1, 0/3) | -0.6 |
| 50+ | Dome × kicker 40-49 accuracy | dome + that accuracy | -0.8 (-0.9, 1/3) | -1.8 |
| 50+ | Dome × kicker 50+ accuracy | dome + that accuracy | +3.4 (1.4, 3/3) | -1.6 |
| 50+ | Implied × kicker 50+ accuracy | implied + its square + that accuracy | -0.1 (-0.5, 1/3) | +0.1 |
| 50+ | Dome × kicker 50+ volume | dome + that volume | -0.7 (-0.4, 2/3) | -1.8 |
| 50+ | Kicker 50+ share × 50+ accuracy | dome + 50+ accuracy + that share | -3.5 (-2.2, 1/3) | -2.1 |

No interaction clears the noise bar. Two are worth a note, but neither is enough to adopt:
- **Dome × kicker 50+ accuracy, for 50+ attempts**: better in 3/3 seasons but z 1.4, and it hurts the top-12 subset.
- **Dome × kicker 40-49 accuracy, for 40-49 attempts**: +9.0 for top-12. But the model it improves on (dome + 40-49 accuracy) is itself worse than the league average (error 1.0267 vs 1.0235).

## Not tested yet

Roughly in order of how promising I think they are:

1. **Pooled 40+ kicker accuracy** as one "long-range leg" measure for 50+ attempts. Both 40-49 and 50+ accuracy show similar signal, and pooling them would be less noisy than either alone.
2. **Coach willingness to attempt long kicks specifically.** The current coach rate lumps together all 4th downs at the opponent's 42 or closer. A rate restricted to the opponent's 33–42 (50+ kick territory) could predict 50+ attempts directly.
3. **Team's own trailing FG attempts per game** (team-keyed volume). Only team *shares* by range were tested, not team counts.
4. **Point spread**, separately from implied total (game script: trailing teams go for it more).
5. **Offensive efficiency beyond red zone**: EPA per play, drives per game, plays per game (pace).
6. **Weather** (wind, temperature). Deferred by decision on 2026-09-22; a forecast source would be needed for live weeks.
7. **Other venue/game details**: grass vs turf, retractable roof open vs closed as separate categories, primetime, rest days, week of season.
8. **Different model forms**: negative binomial (ruled out because the counts are less spread out than Poisson, not fitted), a multinomial split of total attempts into ranges, or kicker/team random effects.

## Caveats

- **Many comparisons.** About 145 models have been scored on the same three held-out seasons. At that count, a few will look good by luck. That's why the bar is z ≈ 2 *and* consistency across seasons, and why the proposal favors simple models with a clear mechanism over the single best number.
- **Small sample for one team-game.** Only 3 held-out seasons, so "3/3 seasons" is weak evidence on its own.
- **Kicker history starts in 2023.** A veteran's first games in the window look like a new kicker's (shrunk to league average), same as in script 05.
