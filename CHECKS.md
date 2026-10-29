# How the scripts were checked (Oct 19, 2026)

Each project sent its files as a zip on Oct 19. The scripts were pulled out of the project documents and checked in a fresh cloud workspace, with data downloaded live from nflverse the same day (2026 data through Week 6, Monday night still to play).

## Exact copies (copy check matched)
The copy check is the first 12 characters of the SHA-256 of the file's text with surrounding whitespace removed, as written in the project instructions.

| Script | From | Copy check | Run check |
|---|---|---|---|
| `shared/v1.3_witch_usage.py` | Redraft grimoire v1.5, section 11 | `1c175118291b` ✓ (Dynasty grimoire v1.3's copy is the same) | Runs for Jaxon Smith-Njigba (2026) and Harold Fannin Jr. (2025) |
| `shared/v1_witch_offense.py` | `v1_Redraft_Witch_offense_context.md` | `9ccc5cf7afa8` ✓ | — |
| `shared/v1_witch_dpi.py` | `v1_Redraft_Witch_redzone_DPI_scripts.md` | `bfed932eaf16` ✓ (Matchup's copy is the same) | Tre Harris: Weeks 1 and 2, 2 DPIs for 54 yards ✓ |
| `shared/v1_witch_redzone.py` | same doc | `e88be7e229b5` ✓ (Matchup's copy is the same) | Fannin Weeks 1–5 red-zone targets 0, 0, 2, 1, 0 vs team 1, 4, 4, 4, 2 ✓ |
| `matchup/per_route.py` | `claude/per_route_guide.md`, section 4 | `36e64eeb64db` ✓ | Tre Harris 2025: 294 routes, TPRR 0.146, YPRR 1.10, first downs per route 0.061 ✓ |
| `matchup/pipeline/build.py` | `claude/pipeline/build.py` | full-file SHA-256 `283d5ed3…7772` ✓ (the weekly task's check) | — |

## No copy check on record (taken as sent)
| Script | From | Note |
|---|---|---|
| `shared/research/*.py` | Redraft benchmarks v1.1, section 7 | Dynasty's copy of the doc is identical. |
| `shared/benchmarks_v2/*.py` | Redraft benchmarks v2.1 | Identical to the code in Dynasty's `v2_Redraft_Witch_benchmarks.md`. |
| `dynasty/v1_harmon_pdf_to_csv.py` | Dynasty grimoire v1.3 | Not run (needs a Harmon PDF). |

## DST
`dst/v1.4_ChooserBoy_weekly_pull.R` ran start to finish and wrote all 7 files. Its game log was compared row by row with the project's Oct 13 file (702 rows):
- **Every 2025 row matches exactly,** including expected sacks, expected takeaways and points over expected.
- **2026 rows match** except where nflverse has updated its data since Oct 13: pressure counts for 28 Week 5 team-games (missing on Oct 13, posted since) and one stat correction (Jets fumble recoveries in Week 5, 1 → 2).

## Kicker
**These files were retyped by the Kicker project chat, not copied byte for byte** (its manifest says so), so they were checked by running them:
- `run_all.R` ran start to finish ("All done.") and printed "New model self-test passed (24 values)".
- `data/volume_model_validation.csv` gains: 177.431, 13.243, 19.350, 23.496, exactly the weekly task's check.
- `data/points_backtest_rules.csv`: all five rules pass.
- `13_scorecard.R` and `15_accuracy_report.R` ran without errors. Their numbers weren't compared: the projection history wasn't in the zip, and the data has moved on since the project's files were built.
- `07n_fit_new_model.R` (run by hand once a season): see below.
- **Not checked:** `weather_adjust.py`, `07a`, `07c` and `09a` (optional), since none of them run in the weekly pipeline. To close the gap, the Kicker weekly task can compare the project's original copies with these files once, byte for byte, before it switches to the repo.

### 07n refit
`07n_fit_new_model.R` (run by hand once a season) was run step by step as its header describes:
- step 1
- step 2 once for each season 2016–2025
- steps 3–7

It used nflverse play-by-play for 2011–2025, written to a separate folder.
- Step 1's own check against production: 0 mismatches in attempts, kickers and domes.
- **Step 7 reproduced the stored weight files exactly:** all 129 weights in `new_model_weights.csv` (the 24 self-test rows come from step 8, which only stores them) and every value in `new_model_kick_table.csv`, with a difference of 0.

### 09c next-week script (added Oct 20)
`kicker/09c_next_week_only.R` (the Wednesday look-ahead task's script; also retyped in the Kicker zip):
- It ran cleanly with the repo's 00, 08, 09 and 09n: self-test passed. On Oct 20 there were no Week 8 lines yet, so it correctly wrote nothing.
- Its three hand-copied XP/FG dependence values match `models/points_gamma.csv` from the Oct 19 pipeline run exactly.
- Forced to project Week 7 (test copy only), it wrote all 28 kicker-games. These matched the Oct 19 pipeline's Week 7 look-ahead within 0.18 points (mean 0.04); the largest gap follows an overnight line move (ATL implied total 23.0 → 23.75).

## Added later
| Script | Added | Run check |
|---|---|---|
| `dynasty/v1_tank_sim.py` | Oct 29, 2026, written in a Dynasty chat (no project copy) | With every random element switched off (weekly ratios 1, no absences, sigma 0) it returns 105.0 max points a week for roster 6 over Weeks 8–14, matching a hand-built best-lineup projection from the same FantasyPros numbers. A backtest of each roster's current players over 2026 Weeks 1–7 (nflverse PPR, +1 per interception for this league) gave 107.1 (roster 6) and 112.3 (roster 5); the projection-based sim runs about 21% above both, so use `--scale` to calibrate both rosters alike before quoting absolute numbers. |
