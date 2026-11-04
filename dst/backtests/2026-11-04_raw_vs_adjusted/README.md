# Raw vs. adjusted matchup backtest (2026-11-04)

Question: should `base_score`'s matchup part (B) use the adjusted number (vs. what the defenses an offense faced usually get) instead of the raw one (vs. league average), at least later in the season? And which matchup number should DST Warlock chats show?

Answer: the score stays on raw, blended. Raw blended and adjusted blended predict DST points equally well (correlation 0.133 vs. 0.132, 2021-2025, 2,558 DST-games); this-season-only numbers do worse early. Chats show adjusted, blended (v1.6 columns `*_adj_blend_pg`), with this-season-only adjusted when last season came from a different QB. Full write-up: project doc `claude/v1.1_DST_adjusted_matchup_backtest_2026-11-04.md`.

## Rerun
1. `replay.R` is `dst/v1.4_ChooserBoy_weekly_pull.R` with season, week and output folder as arguments (it sets `AS_OF_WEEK`, `WEEKS_AHEAD = 1`). For each season 2021-2025 and week 2-18: `Rscript replay.R <season> <week> out/<season>_<week>`. The scripts read 2021-2024 actuals from `out/<season+1>_2` and 2025 actuals from a current run's game log at `../run14/chooserboy_data/` (edit `CUR` in both scripts).
2. `python3 analyze.py` -> `raw_vs_adjusted_results.csv` (early vs. late, in the full score).
3. `python3 predictors.py` -> `predictors_results.csv` (raw/adjusted x this season/blended, alone and in the full score).

Check: the rebuilt raw composite matches the script's `base_composite` to 0.001.
