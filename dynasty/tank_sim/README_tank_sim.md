# Tank sim (Dynasty Witch) — v1.2, Nov 21, 2026

Simulates the rest of the regular season for all 12 teams and reports where the 2027 rookie picks land: our own (roster 6) and The Disappointments' (roster 12), plus playoff odds for the teams that decide them. Behind Tank Plan v1.9. Copied unchanged from the Dynasty project doc `v1.2_Tank_Sim_Code.md`.

| File | What it does |
|---|---|
| `engine.py` | League scoring from nflverse weekly stats; the Sleeper-to-nflverse ID map; best legal lineup |
| `tank_sim.py` | The simulation (`run`) and the summary (`summarize`) |
| `load_store.py` | Writes the JSON blocks of the Sleeper data store doc to files the sim reads |
| `scenarios_nov21.py` | The Nov 21 injury overrides, trades and scenarios; prints the results table |

## Inputs
- **The Sleeper data store** (Dynasty project doc, newest `v*_Sleeper_Data_2026.md`). Each block is a `### <name>` heading followed by a fenced JSON block. The sim needs `rosters`, `users`, and `matchups_<week>` for every week from the first incomplete week through Week 14. If the Projects tool returns the doc inline rather than as a file, write each JSON block to `/home/claude/sleeper/<name>.json` directly, and check each team's player count and Max PF against the doc's standings table.
- **nflverse:** `stats_player_week_2026.csv` and `games.csv`; **DynastyProcess:** `db_playerids.csv`.
- **Paths are hard-coded** to `/home/claude/sim` (the scripts), `/home/claude/data` (the downloads) and `/home/claude/sleeper` (the Sleeper JSON).

## Run (once a week, or after a notable change)
When to rerun and when to quote the newest Tank Plan instead: `playbooks/dynasty/rookie_draft.md`, "The tank sim."

```
mkdir -p /home/claude/sim /home/claude/data /home/claude/sleeper
cp coven/dynasty/tank_sim/*.py /home/claude/sim/
# then overwrite scenarios_nov21.py with the scenarios file saved in the newest Tank Plan
cd /home/claude/data
curl -fsSL -O https://github.com/nflverse/nflverse-data/releases/download/stats_player/stats_player_week_2026.csv
curl -fsSL -O https://raw.githubusercontent.com/dynastyprocess/data/master/files/db_playerids.csv
curl -fsSL -o games.csv https://raw.githubusercontent.com/nflverse/nfldata/master/data/games.csv
python3 /home/claude/sim/load_store.py <local copy of the data store doc> /home/claude/sleeper
LAST_WEEK=<latest complete week> python3 /home/claude/sim/scenarios_nov21.py
```
Before the last command:
1. **Check the lineup math:** the best lineup from nflverse should equal each team's Sleeper Max PF change for the latest complete week.
2. **Start from the scenarios file saved in the newest Tank Plan** (the repo copy is the Nov 21 starting point only). Update only what changed since that run, and say what changed: overrides (IR returns, short absences) from current injury news, and any trade the owner reports goes in the moves until a paste shows it.
3. **Flag C29 injury sweep:** put every player averaging 8+ points a game on the nine teams that touch our picks (all but Efton, McBride or Die and jrogers617) through the FantasyPros `injury_status` tool, in batches of 20 to 30 names. Large results are saved to a file; parse them with code. Out for the season goes into `OUT_SEASON`; short absences go in as one-week overrides.

Results print as a table and are saved to `/home/claude/sim/results_nov21.csv`.

**After the run, save the next Tank Plan version** with its sim section replaced: run date, latest complete week, data store version, what changed since the last run, the results table, and the full scenarios file as run. That file is where the next run starts, so the injury sweep is done once a week, not once a chat.

## Method (Tank Plan v1.6, section 5)
- **Scores:** each player, each remaining week, plays or doesn't. If he plays, he scores one of his own 2026 weekly scores (league scoring), drawn at random. Byes score 0.
- **Availability:** 95% if he played his NFL team's latest game, otherwise his season rate (games with a stat line ÷ team games). IR: out unless he played the latest game. Named overrides for known return windows.
- **Model error:** each team's weekly max × (1 + e), e ~ Normal(0, 13%), one draw per team per run (backtest, Tank Plan v1.6).
- **Records:** weekly median (top 6 of 12) plus head-to-head on the real schedule. PF = max × the team's season PF/Max PF ratio; ties go to PF. Playoffs: top 6 by record.
- **Draft:** the six non-playoff teams by final Max PF, lowest first. 20,000 runs.
- **Not modeled:** trades or waiver moves by other teams unless a scenario names them, and new injuries beyond each player's rate.
- **Weeks covered:** from the first incomplete week through Week 14.
