# RB prospect study (brief v2.13, section 8) — Oct 31, 2026

Run in order from one working folder. Inputs: nflverse release files (draft_picks/draft_picks.csv, combine/combine.csv,
stats_player/stats_player_reg_<2011-2025>.csv, players/players.csv) in <nfl_dir>, and a clone of
github.com/sportsdataverse/cfbfastR-data (player_stats/parquet, rosters/parquet) in <cfb_repo>. Needs pandas, pyarrow,
statsmodels, scikit-learn, scipy.

1. python3 -I outcomes.py <nfl_dir> outcomes.csv            # solid/elite in first three seasons; reproduces brief section 5's count
2. python3 -I college.py <cfb_repo> 2014 2026 college.csv    # play-level college stats -> player-seasons
3. python3 -I match.py outcomes.csv <nfl_dir>/players.csv college.csv matched.csv
4. python3 -I features.py <scratch_dir_with_outcomes_and_nfl> <cfb_repo> features.csv
5. python3 -I models.py features.csv <out_dir>               # overlap check, one-trait tests, elite among hits
6. python3 -I models2.py features.csv                        # receiving composite, interactions, breakout layer, effect sizes, tier tables

Notes: college targets = catches + incompletions (the target_* columns log incompletions only). Study seasons (2014-2022)
have no postseason in the source; for 2023+ seasons drop postseason games before comparing.

Added after v2.13 (not yet in the brief):
7. python3 -I predraft.py features.csv matched.csv     # pre-draft: traits -> draft slot, and hit models without capital
8. python3 -I draftslot.py features.csv matched.csv    # candidate search for draft slot, nested CV, breakout age vs raw age
