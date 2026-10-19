# #35 Reichard and Fairbairn in week 5, and where dome enters each model — log

2026-10-06. Run in the Kicker Wizerd chat after the user's questions on #33. Descriptive: no rule, nothing adopted. **No production script or model was changed.** Code: `claude/35_explain_week5_and_dome.R`.

## Questions
1. Does the new model (#31's final version) not include dome?
2. Why does it move W. Reichard from 11.4 to 9.6 and K. Fairbairn from 8.1 to 9.3 this week?

## Result
- **Dome is in the new model, in two places:** the kick-or-go decisions for 40–49 and 50+ kicks. It is not in XP attempts, 0–39 attempts, the number of chances, or the make chances.
- **The current model's dome effect for an accurate kicker is far larger than history supports.** Moving Reichard outdoors costs him 2.9 points in the current model and 0.6 in the new one. Most of it is one weight, dome × kicker 40–49 accuracy (+4.38), which was +0.45 on 2016–2022.
- **Both models under-credit domes on average.** In the 2019–2025 walk-forward test, dome kickers outscored outdoor kickers by 1.17 points per game; the new model predicted 0.50 and the current version 0.41. The new model misses dome games by +0.36 and outdoor games by −0.30 (gap 0.66; 95% range 0.24 to 1.11; positive in 99.9% of week-resamples).
- **About half of that gap is makes, half attempts.** Neither model's make chances know the venue (to-do #20).
- **Suggested, not decided:** test dome in the make chances and in the parts of the new model that lack it, before the build.

## Where dome enters
| Part | Current model | New model |
|---|---|---|
| XP attempts | No | No |
| 0–39 attempts | Dome −0.85; dome × coach long-range FG rate +1.70 | No |
| 40–49 attempts | Dome −3.72; dome × kicker 40–49 accuracy +4.38; dome × coach +0.69 | Kick decision: dome −0.71; dome × kicker 40+ accuracy +1.38 |
| 50+ attempts | Dome −0.71; dome × kicker 50+ accuracy +1.44 | Kick decision: dome −0.95; dome × kicker 40+ accuracy +2.04 |
| Chances for a kick | n/a | Same for every team |
| Make chances | No | No |

- New-model weights are from the fit on 2016–2025 (3,580 4th downs at the opponent's 22–31; 3,704 at the 32–41), on the log-odds of kicking.
- 4th downs 2016–2025, share kicked, outdoors vs dome: opponent's 22–31, 77% vs 80%; 32–41, 40% vs 51%. From 40–49 yards coaches nearly always kick, so no input can move those attempts much: this week the new model's 40–49 attempts run from 0.48 to 0.56 across the 30 kickers; the current model's run from 0.32 to 0.93.
- #28's audit of the current 40–49 model (2023–25 fit vs 2016–2022 fit): dome −4.75 vs −0.39; dome × accuracy +5.70 vs +0.45.

**Dome kickers by thirds of 40–49 accuracy, actual 40–49 attempts per game (top-16 team-games):**

| Accuracy third | 2016–2022 (games) | 2023–2025 (games) |
|---|---|---|
| Low (about 0.73) | 0.58 (226) | 0.42 (69) |
| Mid (about 0.81) | 0.61 (187) | 0.42 (108) |
| High (about 0.87) | 0.59 (163) | 0.81 (132) |

The current model's weight is fit to the bottom-right cell. About half of those 132 games belong to four kickers (C. Dicker 26, B. Aubrey 18, J. Bates 10, K. Fairbairn 10).

## Dome vs outdoors in the walk-forward test (2019–2025, 1,984 top-16 team-games)
| | Games | Actual points | New model | Miss | From attempts | From makes |
|---|---|---|---|---|---|---|
| Outdoors | 1,314 | 7.66 | 7.96 | −0.30 | −0.10 | −0.20 |
| Dome | 670 | 8.82 | 8.46 | +0.36 | +0.23 | +0.14 |

- "From makes" = actual points minus the points expected from the attempts he got at his make chances. "From attempts" = the rest.
- Current version: outdoors −0.30, dome +0.46 (gap 0.76; 95% range 0.32 to 1.22).
- Gap by season, new model: 2019 −0.62, 2020 +1.42, 2021 +0.70, 2022 +1.52, 2023 −0.49, 2024 +0.60, 2025 +1.14.
- Attempts per game, actual vs new model: dome XP 2.55 / 2.51, 0–39 1.00 / 1.02, 40–49 0.59 / 0.59, 50+ 0.51 / 0.45; outdoors 2.39 / 2.41, 0.98 / 1.02, 0.52 / 0.55, 0.40 / 0.36.
- **Not in these numbers:** the weather adjustment, which lowers outdoor projections in cold, wind and rain when an answer is given. It covers part of the outdoor miss and none of the dome miss.
- This week the production model's average dome edge is 1.0 points (6 dome games 8.88, 18 outdoor games 7.87) and the new model's is 0.5 (8.58 vs 8.08). The production model reaches that average through the dome × accuracy weight: it gives T. Bass and W. Lutz, in domes with 40–49 accuracy under 0.77, 0.32 and 0.33 attempts from 40–49, below the outdoor average of 0.49.

## W. Reichard (MIN at NO, dome; MIN favored by 1.5; implied total 22.0)
| Part | Current: attempts | New: attempts | Points change |
|---|---|---|---|
| XP | 1.93 | 2.20 | +0.25 |
| 0–39 | 1.12 | 0.99 | −0.38 |
| 40–49 | 0.93 | 0.56 | −1.28 |
| 50+ | 0.81 | 0.72 | −0.36 |
| **Projection** | **11.40** | **9.64** | **−1.76** |

Current model, one input changed at a time (projection change): outdoors −2.92; 40–49 accuracy at the week's average (0.897 → 0.824) −0.87; all range accuracies at average −1.64; coach long-range FG rate at average (0.567 → 0.430) −1.01; make chances at average −0.77.
New model: outdoors −0.56; 40+ accuracy at average −0.26; coach rate at average −0.23; expected margin 0 −0.08; make chances at average −0.61.

- **40–49 (−1.28):** in the current model, dome −3.72 + 4.38 × 0.897 + 0.69 × 0.567 = +0.60, which multiplies his 40–49 attempts by 1.82 (0.51 outdoors → 0.93). In the new model he gets the week's highest figure, 0.56.
- **50+ (−0.36):** current 0.81 (dome × his 50+ accuracy of 0.81). New 0.72, the week's highest; average 0.53.
- **0–39 (−0.38):** the current model's dome and dome × coach weights lift his short kicks 12% (1.00 outdoors → 1.12). Not in the new model; #28 found it doesn't hold on 2016–2022.
- **XP (+0.25):** the current model's XP model has a negative weight on coach long-range rate and a positive one on red-zone trips; both lower him. The new model uses implied total only.
- **His own record** (not a model input): since 2024, 22 dome games: 0.55 attempts per game from 40–49 and 0.82 from 50+. The new model's 0.56 matches the first; its 0.72 is under the second by 0.10 (about 0.4 points).

## K. Fairbairn (HOU at TEN, outdoors; HOU favored by 7; implied total 22.75)
| Part | Current: attempts | New: attempts | Points change |
|---|---|---|---|
| XP | 2.14 | 2.29 | +0.14 |
| 0–39 | 0.91 | 1.07 | +0.45 |
| 40–49 | 0.50 | 0.54 | +0.15 |
| 50+ | 0.49 | 0.62 | +0.44 |
| **Projection** | **8.15** | **9.34** | **+1.19** |

New model, one input changed at a time: expected margin 0 −0.38; coach long-range rate at average (0.618 → 0.430) −0.32; make chances at average −0.36; 40+ accuracy at average −0.08; in a dome +0.47.
Current model: red-zone inputs at average +0.19; kicker's share of attempts from 40–49 at average +0.21; coach rate at average +0.07; in a dome +3.28.

- **0–39 (+0.45):** two halves. The new model adds 11% for being a 7-point favorite (0.97 → 1.07). The current model takes about 10% off because Tennessee has allowed touchdowns on 71% of red-zone trips (1.01 → 0.91), a term that didn't hold on 2016–2022.
- **50+ (+0.44):** Houston's coach long-range FG rate is 2nd of 30 this week. It has a weight of +2.85 in the new 50+ kick decision and isn't in the current 50+ model.
- **40–49 (+0.15):** the current model marks him down for a low share of his past attempts coming from 40–49 (27th of 30).
- **XP (+0.14):** as for Reichard, the current XP model's negative weight on coach long-range rate.
- **Rank 16th → 4th:** the 4th and 16th projections are 1.2 points apart in the new model (9.34 and 8.09) and 1.0 in the current one.
- **His own record:** since 2024, 11 outdoor games: 0.64 attempts per game from 50+.

## Caveats
- Descriptive; no rule was set. The dome gap swings by season (−0.6 to +1.5).
- "Current version" in the walk-forward table is the current formulas refit on earlier seasons, not the production weights.
- Each kicker's own record is 11 to 22 games.
- Lines as of 2026-10-06 10:38 CDT.
