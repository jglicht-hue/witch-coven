# Redraft Witch playbook: data sources

Read before the first live pull. Part of the Redraft Witch instructions (v2.11). Scripts come from the coven repo at the commit the instructions name; project documents are listed where they are still used.

## Scripts (downloaded into `coven/`)
- `shared/v1.3_witch_usage.py`: one player's weekly usage (nflverse), routes (PFF recap tables) and FTN first-read / catchable / drop stats. Routes are never estimated.
  - `python3 coven/shared/v1.3_witch_usage.py "Player Name"` (add `--team XXX` if the name is ambiguous)
  - `--season 2025` for last season, same output
  - `--routes N --tprr X` is a fallback for a published season total; say so when used
  - Downloads are cached in `./witch_cache`. Run it from one working folder so the cache is shared by the other scripts.
- `shared/v1_witch_redzone.py "Name" "Name"`: red-zone and end-zone usage by week, with share of the team's red-zone looks.
- `shared/v1_witch_dpi.py "Name" "Name"`: DPI drawn. The 2026 play-by-play gives DPI plays no receiver id, so the usage script's target counts skip them; this script reads the receiver from the play description.
- `shared/v1_witch_offense.py [TEAM ...] [--through N]`: team context table (points per game, opponent-adjusted scoring, volume).
- `shared/research/offense_diag.py [TEAM ...]`: yards per play, giveaways per game, sack rate, each with league rank. Run the offense or usage script first so `witch_cache` is filled.
- `shared/research/yprr.py`, `analyze.py`, `fd.py`: the league-wide WR route table, so every per-route figure gets a league rank. Run it once per session whenever a receiver add, drop or trade is in question (about a minute). Run it as the project's `claude/v1.1_Redraft_Witch_benchmarks.md`, section 7, describes (the scripts expect a `research/` folder next to `witch_cache`).
- `shared/benchmarks_v2/*.py`: the code behind benchmarks v2 (bands, RB columns). Rerun only when rebuilding the benchmarks.

Copy checks for every script are in the repo's `CHECKS.md`. If the clone or a run is blocked even after the owner's go, stop (instructions, step 1). Never rebuild or retype a script from a project document to get around a block. The grimoire and script documents are reference only.

## When each script runs
- **Midnight Brew:** every add candidate and the whole bench.
- **Trades:** every player on both sides, plus the free agent who would fill an opened spot.
- **Sunday Séance:** only players in a close call.
- **Casual questions:** the players the owner names.
- **Last season:** a second usage run with `--season` for every add or stash candidate with an NFL season behind him.
- **Red zone and DPI:** whenever a usage table is built, for the same players.
- **Team context:** every add, drop and stash analysis (guardrail 18).

Order of sources and fallbacks for routes (PFF recap tables, then the published-total fallback) are in the grimoire; follow them, don't improvise.

## Benchmarks (project document)
- The highest-numbered `claude/v*_Redraft_Witch_benchmarks.md` (v2 as of Oct 15 2026). Section 1 is the quick lookup.
- **Share stats** (snap, target, first-read, red-zone and end-zone usage, carry share, inside-5 share, weighted opportunity) rest on 2018–2025 for WR, TE and RB (first-read share on 2022–2025). Section 3 gives what a Week 3, 6 or 9 figure usually regresses to.
- **Per-route stats** rest on 2025 only, the one full season of route tables. Rerun with 2026 after the season ends.
- **Route minimum** for quoting a per-route figure: 180 routes through Week 7, 250 from Week 8, at every position (Standing Preferences, Oct 20). This replaces the per-position minimums printed in the bands.
- **Not benchmarked:** DPI (owner decision), catchable-target rate and drops, and QB stats. Say so when quoting them (guardrail 19).

## ETR file (project document)
- The highest-numbered `claude/v*_Redraft_Witch_ETR_ROS_Top150.md` holds the owner's latest upload: a header block (upload date, the NFL week it covers, format) and the CSV verbatim.
- Read it with code and print only the players in the question. Rows pulled this way are verbatim (guardrail 11).
- **When the owner uploads a newer CSV in a chat,** save it to the project in the same session, before using it, as the next version (v1 to v1.1 to v1.2, version number at the start of the file name) with the same header block. Copy the CSV exactly as uploaded; never retype rows. Tell the owner the new file's name.
- Check its header date and week against today's NFL week. A file from an earlier week is stale.

## Roster source details
- If the owner makes the league public, the API is readable: `https://lm-api-reads.fantasy.espn.com/apis/v3/games/ffl/seasons/2026/segments/0/leagues/964752?view=mRoster&view=mTeam&view=mSettings`. Try it only if the owner says the league was made public.

## Project files this project still keeps
Flag list, Player Notes, ETR file, benchmarks, the grimoire (sources and route fallbacks; its scripts are reference only), the Roster Tracker. Script-only documents become redundant once chats use the repo.
