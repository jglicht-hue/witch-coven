# kicker-data branch

Data that the Kicker Wizerd weekly task reads and writes every run, kept apart from the scripts on `main`.

- `kicker/projection_history.csv`: every run's pre-game projections (new model `live`, previous model `prev_model`, and the rebuilt 2026 weeks 1–3). The weekly task downloads it, appends this run's rows, and pushes it back here. A backup copy is also saved in the Kicker Wizerd project as `data/projection_history.csv`.

Seeded Oct 20, 2026 from the project's copy (480 rows, weeks 1–6). Checked by grading it with `13_scorecard.R`: weeks 1–5 match the project's Oct 16 scorecard exactly.

Oct 20, 2026: added the 56 rows of that day's run (2026 week 7), taken from the project's backup copy. Those rows are rounded to 3 decimals; all earlier rows keep full precision.
