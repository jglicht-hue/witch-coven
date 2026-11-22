# RB BMI / size study (exploratory, Nov 11-22, 2026)

Stepped outside the brief's Oct 31 lock on the pre-draft model at the owner's request. Nothing in the locked model changed. All results exploratory (50+ tests run).
Brief v2.18 section 8 holds only the Nov 11 band note; the durability, no-pick-control and Nov 22 results are NOT in the brief yet. See HANDOFF_2026-11-22.md.

## Layout
- `data/path_full.csv`  master table: 283 drafted RBs, classes 2011-2023 (233 with combine BMI). Outcomes solid/elite = top-24/top-12 full-PPR RB season in first 3 NFL seasons; ppr and gshare are 3-season totals. Built by path_draft.py from features.csv + matched.csv + dur_base.csv.
- `data/features.csv`, `data/matched.csv`  outputs of the brief's rb_prospect_study pipeline (../rb_prospect_study, pinned b149db7, run unchanged).
- `data/dur_base.csv`  per-RB games, Out weeks (injury report; undercounts IR), PPR, exposure, for 3- and 5-season horizons. Built by dur_build.py from nflverse.
- `scripts/`  bmi_merge, bmi_bands, bmi_comps, dur_build, dur_tests, dur_panel, path_total, path_draft, nov22_checks. Written in a scratch folder: bmi_bands.py, path_total.py and path_draft.py still write their CSV to /home/claude/work/out/ (hardcoded); change that before reuse.
- Not saved: college.csv (15 MB, regenerate with rb_prospect_study/college.py) and the raw nflverse / cfbfastR downloads.

## Reproduce the Nov 22 tables
    python3 -I scripts/nov22_checks.py data/path_full.csv
Needs pandas, statsmodels, scipy, scikit-learn.
