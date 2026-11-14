# Versions

Projects pin a commit from this list. Newest first. A pinned commit never changes.

| Date | Commit | What changed |
|---|---|---|
| 2026-11-14 | `5ba987a` | `dst/v1.7_ChooserBoy_weekly_pull.R`: unit quality blends last season as 3 games from Week 9 (6 before); A scaling and score cutoffs recalibrated. Pinned by the DST weekly task. v1.6 kept. |
| 2026-11-04 | `3673637` | Adds `dst/v1.6_ChooserBoy_weekly_pull.R`: board through Week 18, adjusted blended matchup columns, `score_formula` rows in the data dictionary. `base_score` and `prov_score` unchanged (CHECKS.md). Adds `dst/backtests/2026-11-04_raw_vs_adjusted/`. For the DST Warlock v2.3 instructions. Branch `dst-v1.6`. |
| 2026-11-01 | `b149db7` | Adds `dynasty/rb_board/` (5 scripts and a README: the 2027 RB prospect board). `playbooks/dynasty/rookie_draft.md`: the draft order is the confirmed rule (non-playoff teams by lowest Max PF, owner Oct 21). README and CHECKS rows added. No existing script changed. For the Dynasty v3.12 instructions. |
| 2026-10-31 | `2e6b246` | Adds `dynasty/rb_prospect_study/` (8 scripts and a README, the study behind Dynasty brief v2.15 section 8). `playbooks/dynasty/rookie_draft.md`: rule 3 gains "for an RB, profile means receiving first" (owner, Oct 31). README and CHECKS rows added. No existing script changed. For the Dynasty v3.11 instructions. |
| 2026-10-22 | `37b67ea` | Redraft, Matchup and Dynasty `data_sources.md` playbooks: stop on a blocked run instead of retyping scripts. Pinned by Redraft v2.14, Matchup v2.8 and the Dynasty v3.10 draft. No script changed. |
| 2026-10-21 | `201469b` | Pinned by Redraft v2.13 (one commit for scripts and playbooks; scripts as `e286060`, playbooks as `25f01df`, `00e53ad` and `dd78d20`). |
| 2026-10-21 | `dd78d20` | Adds `playbooks/dynasty/` for the Dynasty Witch v3.10 draft. No script changed; scripts stay at `e286060`. |
| 2026-10-20 | `25f01df` | Adds `playbooks/redraft/` (data sources, brew, trade check, usage tables, profiles) for Redraft Witch v2.11. No script changed; scripts stay at `e286060`. |
| 2026-10-20 | `e286060` | Adds `kicker/09c_next_week_only.R` for the Wednesday look-ahead task. No other script changed. |
| 2026-10-19 | `00e53ad` | Matchup data-sources playbook: script paths for per-file downloads (`coven/...`). |
| 2026-10-19 | `e8c6d7e` | Adds `playbooks/matchup/` for Matchup Witch v2.7. No script changed. |
| 2026-10-19 | `8c5ccc5` | Adds `kicker/summary.R`, which writes the Kicker weekly summary. No other script changed. |
| 2026-10-19 | `f970d0d` | First checked set of scripts for all five projects (see `CHECKS.md`). Later commits on the same day only changed the README and this file. |
