# Backtest: adjusting offenses for the defenses they faced (2026-09-25)

**Question:** Does judging each offense (and QB) against what the defenses it faced normally get, instead of against league average, make `base_score` better?

**Setup:** The same 2021-2025 week-by-week backtest as the current formula. It covers 2,718 DST-games and uses only data available before each game. It matched the current formula's sample and unit-quality spread. Blend weights were kept at 35/25/40.

- **Defense yardstick:** the defense's sacks + 2 × takeaways per game. It blends the defense's other games this season with last season, counted as 3 games.
- **Tracking:** "tracks actual points" = correlation of the score with actual DST fantasy points.
- **Head-to-head:** share of same-week pairs where the higher-scored DST scored more.

## Results

| Version | Tracks actual pts | Head-to-head | Weeks 2-6 tracking |
|---|---|---|---|
| Current (defense 6, offense 6, raw matchup) | 0.182 | 56.6% | 0.143 |
| Step 1: defense weight 6 → 3 | 0.180 | 56.5% | 0.136 |
| Step 2: Step 1 + adjusted matchup | 0.179 | 56.5% | 0.136 |
| Side check: Step 2 with offense at 3 | 0.180 | 56.5% | 0.135 |
| Extra: current + adjusted matchup | 0.182 | 56.6% | 0.143 |

- **Defense weight 3 is worse than 6.** It was worse in 91% of resamples and in 4 of 5 seasons.
- **Last season is informative for defenses.** A defense's quality correlates 0.24 with the next season. First half vs. second half of the same season correlates only 0.18.
- **The adjusted matchup input is slightly better on its own** (0.128 → 0.131, better in 75-85% of resamples). But it adds nothing once Vegas is in the score. Raw and adjusted versions correlate 0.97, and Vegas already accounts for the schedule.
- **Verdict: `base_score` unchanged.** The adjusted matchup is shown as `base_matchup_B_adj` for reference.

## QB profiles

- **Sack rate is sticky.** A QB's rate through Week 4 correlates 0.43 with his rate for the rest of the season. Adjusting it for defenses faced didn't help (0.42).
- **Turnover rate barely carries forward.**
  - Weeks 1-4 turnover rate vs. rest of season: about 0, raw or adjusted.
  - Weeks 1-8 vs. rest of season: 0.01 adjusted, -0.02 raw.
  - Last season vs. this season: 0.04.
- The adjusted QB columns are kept for reference only.

## Pipeline

`v1.2_ChooserBoy_weekly_pull.R` adds the adjusted columns and keeps `base_score` identical to v1.1. This was verified by diffing outputs.
