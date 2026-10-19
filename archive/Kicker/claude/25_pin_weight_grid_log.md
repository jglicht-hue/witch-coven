# #25 How high should the pinned 50+ weight go, and a positive weight in the 40–49 model — log

2026-10-05. Run in the Kicker Wizerd chat as a one-off (user questions after #24). **No production script or model was changed.** Code: `claude/25_pin_weight_grid_tests.R`.

## Questions
After #24 the user said the 50+ accuracy weight should increase, and asked:
1. What if it went even higher than the 2016–2022 estimate of about 1.3?
2. What about a positive weight on accuracy in "that model" for 40+? Read here as: a positive outdoor weight on kicker accuracy in the **40–49 attempts model**, where production has −1.33.

## Result
- **Higher than 1.31 doesn't pass.** 1.56 and 2.0 each predict 50+ attempts worse than 1.31, and better in only 1 of 3 seasons. Above 2.0 the attempts error falls apart.
- **A positive 40–49 weight doesn't pass.** Every positive value predicts 40–49 attempts worse than the current model, better in only 1 of 3 seasons.
- **What 2023–25 can and can't say about the 50+ weight:** pinning beats estimating at any value from 0 to 1.56. The three seasons can't tell those values apart. The case for raising the weight to about 1.3 rests on the independent 2016–2022 estimate (and #23's coach-decision evidence), not on the 2023–25 backtest.
- **Decision pending with the user:** pin the 50+ weight at 1.307 and leave the 40–49 model alone (recommended), then a production build.

## Rules (set and sent to the user before results)
- **50+ model:** a higher value replaces 1.307 only if it
  1. sits inside the 95% range of the 2016–2022 all-kicker estimate (up to about 2.4), and
  2. beats 1.307 on 50+ attempts error overall and in at least 2 of 3 seasons, and
  3. leaves points squared error and top-16 hit rate no worse than 1.307.
- **40–49 model:** a positive outdoor value is recommended only if it
  1. beats the current model on 40–49 attempts error overall and in at least 2 of 3 seasons, and
  2. leaves points squared error and hit rate no worse, and
  3. sits inside the 95% range of the 2016–2022 estimate.
- **Scoring:** as in #24. Leave one season out on 2023–25, 832 pre-game top-16 team-games; hit rate on 5,858 pairs. A pinned weight is entered as a fixed offset; the dome terms are still estimated.

## Independent estimates (outdoor weight per unit of accuracy, 95% range)
| Model | Seasons | All kickers | Pre-game top 16 |
|---|---|---|---|
| 50+ attempts on 40+ accuracy | 2016–2022 | +1.31 (+0.24 to +2.38) | +1.56 (−0.15 to +3.26) |
| 50+ attempts on 40+ accuracy | 2016–2025 | +1.70 (+0.84 to +2.55) | +1.32 (−0.03 to +2.67) |
| 40–49 attempts on 40–49 accuracy | 2016–2022 | +0.41 (−0.32 to +1.14) | +0.03 (−1.13 to +1.19) |
| 40–49 attempts on 40–49 accuracy | 2016–2025 | +0.16 (−0.47 to +0.79) | −0.31 (−1.33 to +0.71) |

- Production (2023–25 fit): 50+ weight +0.664 (standard error 0.84); 40–49 outdoor weight −1.325 (standard error 0.97).
- The 40–49 row now uses 40–49 accuracy, like production (#24's long-table row used 40+ accuracy). Every 40–49 range includes zero.
- The 2016–2025 rows overlap the seasons the backtest scores, so they are context, not candidates.

## A. 50+ model: pinned weight on kicker 40+ accuracy
Gain = attempts error ×1000 per team-game, positive = better. "vs 1.307" is the rule's comparison.

| Pinned at | Gain vs current (seasons better) | Gain vs 1.307 (seasons better) | Points squared error | Hit rate | Mean / max projection move |
|---|---|---|---|---|---|
| Current (estimated) | — | −3.20 | 22.0844 | 0.5685 | — |
| 0 (no weight) | +3.54 (2/3) | +0.34 (1/3) | 22.1145 | 0.5673 | 0.05 / 0.47 |
| 0.664 (today's value, fixed) | +4.08 (3/3) | +0.88 (1/3) | 22.0923 | 0.5676 | 0.05 / 0.27 |
| 1.0 | +3.79 (3/3) | +0.59 (2/3) | 22.0845 | 0.5679 | 0.06 / 0.35 |
| **1.307** | **+3.20 (3/3)** | — | **22.0794** | **0.5688** | 0.07 / 0.46 |
| 1.555 | +2.49 (3/3) | −0.71 (1/3) | 22.0766 | 0.5691 | 0.07 / 0.55 |
| 2.0 | +0.73 (1/3) | −2.47 (1/3) | 22.0746 | 0.5712 | 0.11 / 0.72 |
| 2.5 | −2.02 (1/3) | −5.22 (0/3) | 22.0769 | 0.5719 | 0.14 / 0.92 |
| 3.0 | −5.56 (1/3) | −8.76 (0/3) | 22.0841 | 0.5736 | 0.18 / 1.13 |
| 4.0 | −14.97 (0/3) | −18.17 (0/3) | 22.1128 | 0.5746 | 0.26 / 1.59 |

- **Against the rule:** 1.555 and 2.0 are inside the range but lose to 1.307 on attempts error (1 of 3 seasons each). 2.5 and above are outside the range and lose in every season. **No higher value passes.**
- **The attempts error is flat from 0 to about 1.56** (gains of +2.5 to +4.1 vs current, all within 1.6 of each other) and best near 0.7–1.0. Most of the gain comes from not estimating the weight on 3 seasons: the leave-one-season-out estimates were 0.42 / −0.10 / 1.58.
- **Points measures drift the other way.** Squared error is lowest at 2.0; hit rate keeps rising to 4.0. Neither is distinguishable from noise (week bootstrap, section D).
- **Fixing the weight at today's 0.664 or at 1.0** predicts attempts slightly better than 1.307 but leaves both points measures slightly worse than the current model (so they'd fail #24's "points no worse" condition). Of the grid, only 1.307 and 1.555 meet #24's rule against the current model.

## B. 40–49 model: pinned outdoor weight on kicker 40–49 accuracy
| Pinned at | 40–49 attempts gain vs current (seasons better) | Outdoors | Points squared error | Hit rate | Mean / max projection move |
|---|---|---|---|---|---|
| Current (estimated) | — | — | 22.0844 | 0.5685 | — |
| −1.325 (today's value, fixed) | +2.24 (3/3) | +3.44 | 22.0925 | 0.5662 | 0.02 / 0.22 |
| −0.5 | +1.20 (2/3) | +1.85 | 22.0812 | 0.5720 | 0.04 / 0.49 |
| 0 | −0.24 (1/3) | −0.37 | 22.0789 | 0.5727 | 0.06 / 0.62 |
| +0.25 | −1.19 (1/3) | −1.83 | 22.0789 | 0.5724 | 0.07 / 0.68 |
| +0.5 | −2.28 (1/3) | −3.52 | 22.0797 | 0.5737 | 0.09 / 0.74 |
| +1.0 | −4.91 (1/3) | −7.57 | 22.0835 | 0.5737 | 0.11 / 0.84 |
| +2.0 | −11.82 (1/3) | −18.25 | 22.0993 | 0.5731 | 0.16 / 1.01 |
| 40+ accuracy in place of 40–49 accuracy (estimated) | −19.68 (1/3) | −6.14 | 22.2346 | 0.5683 | 0.20 / 1.26 |

- **Against the rule:** every positive value is worse on attempts error overall and better in only 1 of 3 seasons (2023). **No positive value passes.** Swapping 40+ accuracy into the 40–49 model is much worse.
- **Points measures lean the other way again:** zero to +0.5 has slightly lower squared error and a higher hit rate than current (+0.004 to +0.005). The hit-rate gain is borderline in the week bootstrap (about 5% of resamples show none); the squared-error gain is noise.
- **2023–25 keeps wanting a negative weight:** the leave-one-season-out estimates were −1.91 / −0.48 / −1.36, while 2016–2022 says about zero to +0.4. #23's coach-decision test explains why accuracy can't do much here: from 40–49 yards coaches kick 78% of the time whoever the kicker is.
- **Seen after the fact, not a pass:** −0.5 beats current on attempts error (2 of 3 seasons) and on both points measures. No rule was set for it; it's the best of a grid looked at afterwards, and it's outside the all-kicker 2016–2022 range.

## C. Combinations (points measures for the whole projection)
| Version | Points squared error | Hit rate | Mean / max projection move |
|---|---|---|---|
| Current | 22.0844 | 0.5685 | — |
| 50+ at 1.307 only | 22.0794 | 0.5688 | 0.07 / 0.46 |
| 50+ at 1.307, 40–49 at 0 | 22.0779 | 0.5705 | 0.11 / 0.86 |
| 50+ at 1.307, 40–49 at +0.25 | 22.0790 | 0.5720 | 0.12 / 0.92 |
| 50+ at 1.307, 40–49 at +0.5 | 22.0808 | 0.5719 | 0.13 / 0.98 |
| 50+ at 2.0, 40–49 at 0 | 22.0782 | 0.5746 | 0.15 / 1.02 |

All within 0.007 of each other on squared error (0.03%).

## D. Week bootstrap of the points measures (added after the main results; descriptive)
2,000 resamples of the 54 weeks. "Not better" = share of resamples in which the change doesn't improve the measure.

| Comparison | Squared error change (95% range; not better) | Hit rate change (95% range; not better) |
|---|---|---|
| 1.307 vs current | −0.005 (−0.074 to +0.060; 45%) | +0.0003 (−0.0048 to +0.0051; 46%) |
| 1.555 vs 1.307 | −0.003 (−0.019 to +0.012; 38%) | +0.0003 (−0.0017 to +0.0023; 40%) |
| 2.0 vs 1.307 | −0.005 (−0.051 to +0.036; 43%) | +0.0024 (−0.0014 to +0.0063; 11%) |
| 3.0 vs 1.307 | +0.005 (−0.108 to +0.107; 53%) | +0.0048 (−0.0017 to +0.0112; 8%) |
| 40–49 at 0 vs current | −0.006 (−0.068 to +0.053; 44%) | +0.0043 (−0.0003 to +0.0095; 5%) |
| 40–49 at +0.5 vs current | −0.005 (−0.087 to +0.077; 46%) | +0.0053 (−0.0010 to +0.0119; 5%) |
| 40–49 at −0.5 vs current | −0.003 (−0.047 to +0.037; 45%) | +0.0036 (−0.0009 to +0.0081; 6%) |

No points difference between pinned 50+ values clears noise.

## Conclusions
1. **50+ weight:** pin it at 1.307 (the 2016–2022 all-kicker estimate, about double today's). Going higher fails the rule, and the data can't support a value above about 1.6 on attempts error.
2. **Honest limit:** the 2023–25 backtest supports *pinning*, not a particular value between 0 and 1.56. 1.307 is chosen because it's the independent estimate and the only grid value besides 1.555 that's no worse than the current model on every measure.
3. **40–49 weight:** leave it estimated. Zero and positive values fail on attempts error; the hit-rate lean toward them is borderline and unconfirmed.
4. **Size:** the 50+ pin moves projections 0.07 points on average in the backtest (0.04 on week 4 2026 inputs), at most about 0.5.
5. Build steps for the 50+ pin are listed in `claude/24_pin_accuracy_slopes_log.md` ("If the 50+ pin is adopted").

## Caveats
- The grid is 9 + 7 values scored on the same 832 team-games; apart from the candidates named in the rules, treat rows as description.
- The 2016–2022 weight has a standard error of 0.55, so "1.307" is a centre, not a known value.
- The offset applies in domes too; the dome × 50+ accuracy term is re-estimated on top of it.
- Treating the pinned weight as known narrows the 90% CI very slightly.
- The reading of the user's second question (40–49 attempts model) is an assumption; the 50+ model's weight on 40+ accuracy is already positive and is the one being raised.
