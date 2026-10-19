# Backtest: QB-aware baselines (M1, M2) + head-to-head odds by score gap (2026-09-27)

**Question:** Both yardsticks in `base_score` lean on each offense's last season (6 games' weight), and neither knows who played QB. Does making them QB-aware improve the score? Separately, what are the head-to-head odds for each score gap, to replace the three bands?

**Answer:** No. QB-aware yardsticks don't help unit quality (A), and they make the matchup (B) and the full score worse. **`base_score` is unchanged.** The per-gap odds table is below.

## Setup and reproduction check

- **Sample:** a walk-forward backtest of 2021-2025, 2,718 DST-games. Each game uses only data from before its week. The code is rebuilt from the pipeline and saved as `claude/backtest_engine_2026-09-27.R`, since the earlier backtest code wasn't in the project.
- **Reproduction:** the rebuild matches the published current model before any change was tested.

| Check | Published | Rebuilt |
|---|---|---|
| DST-games | 2,718 | 2,718 |
| A mean / sd | -0.00549 / 0.89183 | -0.00549 / 0.89183 |
| Tracks actual pts | 0.184 | 0.184 |
| Head-to-head | 56.6% | 56.6% |
| Bands 1-2 / 3-4 / 5+ | 53 / 57 / 62% | 53.1 / 56.8 / 62.0% |
| Provisional bands | 52 / 55 / 59% | 51.9 / 55.0 / 59.7% |

- **One gap:** B's published scaling constant (sd 0.860) doesn't reproduce; the rebuild gives 0.932. The headline metrics still match with the published constants. For a like-for-like comparison, every version below, the current one included, is standardized and cut on its own sample.

## Versions tested

- **M1 (unit quality A):** each past game is graded against the QB who actually played it. The last-season weight is scaled by that QB's share of the offense's last-season dropbacks.
  - **M1a:** the remainder goes to the league average.
  - **M1b:** the remainder goes to the QB's own last-season rates. This is exactly the hand re-base (C2).
  - **M1c:** M1b, plus each of the offense's other games this season is weighted by that QB's share.
- **M2 (matchup B):** the same idea for this week's starter.
  - **M2a:** swaps the last-season part only.
  - **M2b:** also re-weights this season's games.
  - **"_prev":** uses the previous game's QB as the starter instead of the actual one, so there's no hindsight.
- **Extra checks:**
  - **M2s:** discount the old team's history toward league average, without the QB's rates.
  - **Shrunk QB:** QB rates pulled toward league average first (200 / 400 dropbacks), since some rest on small samples.
  - **Combinations:** M1 + M2.

## Results

**How to read the columns:**
- **Tracking:** correlation of the score with actual DST fantasy points.
- **H2H:** share of same-week pairs where the higher-scored DST scored more.
- **Weeks 2-6:** tracking in weeks 2-6 only.
- **A / B alone:** correlation of that input with actual core points (sacks + 2 × takeaways).
- **Resamples:** % of 1,000 week-level bootstraps where the version beat the current one.
- **Flipped pairs:** same-week pairs the version orders differently from the current one, and how often its new pick won.

| Version | Tracking | H2H | Weeks 2-6 | A alone (wk 2-6) | B alone | Tracking better in | H2H better in | Seasons better | Flipped pairs (new pick wins) |
|---|---|---|---|---|---|---|---|---|---|
| **Current** | **0.184** | **56.60%** | **0.146** | **0.104** | **0.126** | — | — | — | — |
| M1a | 0.183 | 56.63% | 0.146 | 0.102 | 0.126 | 12% | 77% | 3/5 | 262 (52.7%) |
| M1b (= C2) | 0.184 | 56.54% | 0.146 | 0.102 | 0.126 | 16% | 10% | 4/5 | 279 (45.5%) |
| M1c | 0.184 | 56.56% | 0.146 | 0.103 | 0.126 | 70% | 18% | 3/5 | 389 (47.8%) |
| M1b, shrunk QB | 0.184 | 56.56% | 0.146 | 0.101 | 0.126 | 17% | 17% | 3/5 | 237 (46.6%) |
| M2a | 0.179 | 56.46% | 0.135 | 0.104 | 0.117 | 7% | 24% | 0/5 | 1,971 (48.6%) |
| M2b | 0.170 | 56.25% | 0.145 | 0.104 | 0.095 | 0% | 7% | 0/5 | 3,052 (47.7%) |
| M2a_prev | 0.175 | 56.34% | 0.132 | 0.104 | 0.113 | 1% | 9% | 0/5 | 1,899 (47.3%) |
| M2b_prev | 0.168 | 56.17% | 0.135 | 0.104 | 0.096 | 0% | 3% | 0/5 | 2,739 (46.9%) |
| M2a, shrunk QB | 0.179 | 56.43% | 0.137 | 0.104 | 0.120 | 8% | 18% | 1/5 | 1,785 (48.1%) |
| M2s (discount old team only) | 0.183 | 56.70% | 0.145 | 0.104 | 0.127 | 35% | 76% | 2/5 | 2,031 (51.0%) |
| M1c + M2a | 0.179 | 56.41% | 0.134 | 0.103 | 0.117 | 9% | 16% | 0/5 | 2,047 (48.2%) |
| M1a + M2a | 0.178 | 56.45% | 0.134 | 0.102 | 0.117 | 6% | 20% | 0/5 | 2,031 (48.5%) |

**Games where the starter threw under 50% of the offense's last-season dropbacks** (1,293 DST-games, 48% of the sample), B alone vs. actual core points:

| Current | M2a (QB's rates) | M2a, shrunk QB | M2b | M2s (discount only) |
|---|---|---|---|---|
| 0.099 | 0.086 | 0.095 | 0.031 | 0.118 |

**Spot checks:** B values for known QB changes were inspected directly: Russell Wilson in DEN in 2022, Zach Wilson in NYJ in 2023, Fields in PIT in 2024, Ridder in ATL in 2023, and Dart in NYG in 2025. The mechanics work as designed. The losses come from the idea itself, not a bug.

## What it means

- **M1 does nothing measurable.** Every variant is within ±0.001 of the current model, and unit quality on its own gets slightly worse. The hand re-base (C2) is M1b's formula, so it isn't supported either.
- **Swapping in the new QB's own history makes B worse, in every season.**
  - This holds even in the QB-change games where it should help most.
  - It still loses after shrinking noisy QB rates toward league average.
  - The team's own history (offensive line, scheme, play-caller) predicts sacks and giveaways allowed better than the QB's personal numbers from somewhere else. This fits the earlier finding that QB turnover rates barely carry from season to season.
- **Discounting the old team's history is the one hint of signal, and it's too small to use.**
  - In QB-change games, trusting the old team history less, without replacing it with the QB's numbers, helps B a little (0.099 → 0.118).
  - Across the full score it's a wash: head-to-head is better in 76% of resamples, tracking is worse in 65%, it wins 2 of 5 seasons, and its flipped pairs are a coin flip (51%). It doesn't pass.
  - Vegas already prices QB changes, which is where most of the gain would have come from.
- **Verdict:**
  - `base_score` is unchanged.
  - The v1.4 flag columns stay reference-only.
  - The chat modifiers that act on QB identity are not supported by this test (see "Pending decisions").

## Head-to-head odds by score gap

**How it's computed:** every same-week pair of DSTs, 2021-2025, walk-forward. "Win" = the higher-scored DST scored more league fantasy points, TDs included; a tie in points counts as half.

**Which number to use:**
- The raw per-gap rates wobble. For example, a live gap of 8 comes in below a gap of 7.
- The recommended values are therefore a logistic curve fitted on the gap. It stays inside the 90% range of the raw rates at every gap except 8, where it sits just above.
- Provisional scores are measured at 2-3 weeks' lead: data through 2 and 3 weeks before the game, pooled.

| Score gap | Current score: recommended | Raw (90% range) | Avg points edge | Provisional: recommended | Raw |
|---|---|---|---|---|---|
| 1 | **52%** | 52.2 (51.0-53.3) | +0.2 | **51%** | 51.3 |
| 2 | **54%** | 54.1 (52.7-55.4) | +0.5 | **53%** | 52.6 |
| 3 | **56%** | 55.1 (53.7-56.6) | +0.7 | **55%** | 54.0 |
| 4 | **58%** | 58.8 (56.7-60.9) | +1.3 | **56%** | 56.2 |
| 5 | **60%** | 59.7 (57.7-61.9) | +1.5 | **58%** | 58.2 |
| 6 | **62%** | 62.6 (59.9-65.1) | +1.8 | **60%** | 58.9 |
| 7 | **64%** | 63.3 (61.0-65.8) | +2.0 | **61%** | 59.4 |
| 8 | **66%** | 62.0 (58.7-65.3) | +1.9 | **63%** | 62.3 |
| 9 | **68%** | 66.9 (63.5-70.5) | +2.6 | **65%** | 65.2 |

- **Sample sizes:** 35,984 live pairs and 72,036 provisional pairs.
- **Ties:** 7.7% of pairs tied in fantasy points.

## Pending decisions (proposed, not made)

1. **Put the per-gap table into the instructions.** It replaces the three bands in the head-to-head odds section.
2. **Drop C2** (the hand re-base) from the revised instructions. It is M1b, and M1b didn't help.
3. **Scale back the "QB context" modifier.** Leaning on a new QB's personal rates is the manual version of M2, which lost in all 5 seasons. Keep the existing rule for QB news the line hasn't priced in yet, and treat QB identity as color otherwise.
4. **v1.4 flag columns:** keep them as reference, or remove them in v1.5.
