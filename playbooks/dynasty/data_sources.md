# Dynasty Witch playbook: data sources

Read before the first live pull. Part of the Dynasty Witch instructions (v3.10). Text moved from v3.9 DATA SOURCES and the opening routine; script setup now comes from the coven repo at the commit the instructions name.

## Scripts (downloaded into `coven/`)
- `shared/v1.3_witch_usage.py`: one player's weekly usage. Same script as the grimoire's v1.3 (copy check `1c175118291b`, see the repo's `CHECKS.md`).
  - `python3 coven/shared/v1.3_witch_usage.py "Player Name"` (add `--team XXX` if the name is ambiguous)
  - `--season 2025` for last season, same output
  - Downloads are cached in `./witch_cache`. Run every script from one working folder so the cache is shared.
- `shared/v1_witch_offense.py [TEAM ...]`: the team-context table (guardrail 23). Use it as written; don't rebuild it from memory.
- `shared/research/offense_diag.py [TEAM ...]`: guardrail 23's diagnosis columns (yards per play, giveaways per game, sack rate, each with league rank). Run the offense or usage script first so `witch_cache` is filled.
- `shared/research/yprr.py`, `analyze.py`, `fd.py`: the league-wide WR route table, so every per-route figure gets a league rank. Run it once per session whenever a receiver add, drop, stash review or trade is in question. The first run takes about a minute. The scripts expect to sit in a `research/` folder next to `witch_cache`.
  - These were written for the redraft project: they stop at 2026 Weeks 1 to 3 and print a redraft player list. In the working copy only, extend the 2026 week range to the latest completed week and swap in the players in question, and say that you did. The repo files stay unchanged.
  - First downs per route run comes from `fd.py`, not from the usage script: `receiving_first_downs` in the nflverse weekly player stats file, over the same published route count.
- `shared/benchmarks_v2/build.py`, `season.py`: **the RB columns** (weighted opportunity per game, red-zone carry share). If the usage script doesn't print them, compute them in the working copy only, with `YEARS` set to 2026 and only completed weeks used, and say that you did. The download block covers 2018 to 2025; for 2026, download only the 2026 files. Weighted opportunity uses v2's weights (PFF, 2019).
- If the clone or a run is blocked even after the owner's go, stop (instructions, step 1). Never rebuild or retype a script from a project document to get around a block. The project copies of the scripts are reference only.

## When the usage script is required
One run per player, and only for players in the current question:
- **Midnight Brew:** every add candidate, and every stash being judged.
- **Trade Check:** every player on both sides with an NFL sample.
- **Stash reviews:** add `--season 2025` for a second-year player's rookie numbers.
- **Sunday Séance:** only the players in a close call.
- **Casual questions:** the players the owner names.
- **Last season:** for every add or stash candidate with an NFL season behind him, a second run with `--season` for last year (guardrail 29).

## The grimoire (project document)
The highest-numbered `v*_Dynasty_Witch_data_instructions.md` (v1.3 as of Oct 3, 2026). It holds the nflverse, PFF and FTN sources, the fallback chain for routes, the FantasyPros connector guide, the Sleeper guide and ID table (Part 3, including how to list free agents), the long-term facts (age, NFL round), the value sources, how to read the ETR and Harmon files (Part 5), the early indicators, and the schedule tool. Follow it for sources, their order and their fallbacks. Do not restate or improvise them. Search it for the part you need; its script section is replaced by the repo.

## The benchmarks: two project documents
Both copied into this project unchanged from the redraft project. Quote their rows; don't restate them from memory.
- **The bands:** the highest-numbered `v*_Redraft_Witch_benchmarks.md` (v2 as of Oct 15, 2026: `v2_Redraft_Witch_benchmarks.md`). Section 1 is the quick lookup, with a "fantasy-relevant line" and a "strong line" for each stat at WR, TE and RB.
  - **Share stats** (snap, target, first-read, red-zone and end-zone usage, carry share, inside-5 share, weighted opportunity) rest on 2018 to 2025 for WR, TE and RB, with first-read share on 2022 to 2025. They aren't rerun in season.
  - **Per-route stats** (yards, targets and first downs per route run, and route share) rest on 2025 alone. They are rerun with 2026 data after the season ends.
  - **Route minimum for placing a per-route figure in a band:** see Standing Preferences in the instructions (180 / 250). It replaces the per-position minimums printed in the bands (WR 250, TE 200, RB 100).
  - **What an early figure settles to:** section 3 gives a line for each share stat through Week 3, 6 and 9. Use the "all" line for every player. Use the Week 6 lines now and the Week 9 lines once Week 9 is complete. For per-route stats the only line is section 3.1, for WRs through Week 3. After Week 3, say that a per-route regression is untested rather than stretch that line.
  - **Players who change teams:** section 5 gives the season-to-season correlations for players who changed teams (guardrail 29).
- **`claude/v1.1_Redraft_Witch_benchmarks.md`:** its section 7 was the home of the route-table and diagnosis scripts, now in the repo. It is reference only.
- **Guardrail numbers in the two files are the redraft project's.** Read their "guardrail 18" as guardrail 23 here and their "guardrail 21" as guardrail 26. v2's "guardrail 25" (on Heath's rookie first-downs rule) is read as rule 5 here.

## The research brief (project document)
The evidence behind the seven rules: the highest-numbered `v*_Dynasty_Witch_research_brief.md`. It holds the age curves, Leone's pick tables, the ladder and its caveat, the stash and waiting tables, the yards-per-route-run tiers, Heath's first-downs finding, and the list of what couldn't be found.
- **Search it for the row you need;** don't read it in full. When a call leans on a base rate, quote the row with its sample.
- If the brief doesn't cover a question, say so; don't fill the gap from memory.

## The ranking files (project documents)
- `ETR_Dynasty_Rankings_<date>.csv`: the owner's export of Establish The Run's dynasty rankings, unchanged.
- `Harmon_Dynasty_WR_Ranks_<date>.csv`: Matt Harmon's dynasty WR ranks from Reception Perception, turned into a table from the owner's PDF (`dynasty/v1_harmon_pdf_to_csv.py` in the repo does the conversion).
- **Read them with code** and print only the players in the question, with the column headers. A row pulled this way is verbatim (guardrail 12). Use the newest file of each and state its date every time. If a file's name carries no date, ask the owner for it. The grimoire says how to read both (Part 5).

## The flag list (project document)
The highest-numbered `v*_Dynasty_Witch_flags.md`. Read its Open and Watch flags before the first call of a session: an Open flag that touches a call caps its moon phase. When a flag opens or closes, say so and offer the next version of the file for the owner to save.

## Sleeper (live)
- Pull by page fetch (the shell can't reach Sleeper): `https://api.sleeper.app/v1/league/1332059836468195328/rosters` (our roster_id is 6). Picks come from `/traded_picks` on the same league address. Team names, records and points come from Sleeper too (the grimoire's Part 3 says where). Player IDs become names through the ID table in the grimoire.
- Re-pull picks before any pick advice, and the standings and team names each session that needs them.
