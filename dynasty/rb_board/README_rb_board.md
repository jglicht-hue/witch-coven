# RB prospect board (Dynasty Witch) — Oct 31, 2026

Builds the 2027 RB prospect board: the consensus 20 RBs and five model sleepers, each ranked two ways.
- **Consensus view:** the blended board rank, treated as the NFL pick, run through brief section 8's model of draft capital plus final-season catches per game.
- **Model view:** the locked six-trait pre-draft model (age at the draft, catches per game, rushing TDs per game, scrimmage share, share of carries going 10+ yards, Power 4). An RB with no birth date runs on the same traits without age.

Run from one working folder that holds the study's outputs (`features.csv`, `matched.csv`, `college.csv`, and the `cfb/` and `nfl/` data folders), built with `dynasty/rb_prospect_study/` steps 1–4.

1. `python3 -I score.py` — fits both models, scores the consensus 20 (hard-coded college ids in `POOL`) and picks sleepers from 2026 RBs with 50+ carries. Writes `prospects_scored.csv` and `cap.pkl`.
2. `python3 -I rescore_age.py` — adds age at the draft from the birth-date table and rescores with age where it exists.
3. `python3 -I board.py` — blends the slot sources and the rookie lists, computes both rankings and the round-gap flag. Writes `board.csv`.
4. `python3 -I tables.py <date>` — writes the board's two tables and `RB_Prospect_Board_<date>.csv` for the project.
5. `python3 -I compare.py` — optional: scores the 2024–2026 drafted RB classes with the same models, for the class comparison in brief section 8.

**Hard-coded inputs to refresh each time (in the scripts):**
- `board.py`: NFL Mock Draft Database consensus ranks (Oct 3 PDF), Brugler's top 50 (owner's screenshots, Oct 31), Tice's top 25 (Apr 28), Draft Sharks rookie ranks (Oct 1), Dynasty Nerds Big Board 5.0 (Oct 14, superflex, QBs removed).
- `rescore_age.py`: birth dates from Wikipedia (read Oct 31–Nov 1, 2026), plus LJ Martin's age from PlayerProfiler. No birth date was found for Baugh, Bothwell, Knight, Cook, Edwards, White, Parker, J'Koby Williams or Yoder.
- `score.py`: the college ids of the consensus 20.

Check after a rerun: on the Oct 31 inputs, steps 1–4 reproduce the Oct 31 board exactly.
