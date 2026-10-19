# Matchup Witch playbook: data sources and known quirks

Read this before the first live pull in a chat (anything beyond the cached docs). It is part of the project instructions, moved out so it isn't resent with every message.

- Cached data (use first): project docs under `claude/data/`, built from nflverse.
  `claude/data/history/{CODE}_{Nickname}_history.md` covers 2023–2025 and never
  changes; `claude/data/current/{CODE}_{Nickname}_current.md` covers the current
  season and is rewritten every Tuesday morning; `LEAGUE_history.md` and
  `LEAGUE_current.md` hold league averages. `claude/data/v1.1_README.md` lists exactly
  what they contain: points allowed by position with ranks, pass and run defense
  unit stats, coverage mix, targets allowed by position/route/man-zone, run
  defense by box count and direction, week-by-week top scorers and QBs faced, and
  offense usage (snap share, target and carry share, air yards, aDOT, red-zone
  work, QB pressure and blitz splits, RB run buckets). Since v1.2 they also have,
  per season: each defense's Flags (top and bottom ~15% in every bucket), throw
  funnel, passing allowed by throw depth and location, and QB rushing allowed;
  and each offense's usage concentrations and QB throw map. Current-season docs
  have no route, man/zone, coverage-shell or pressure data (NGS participation
  isn't posted in season). Their target counts leave out DPIs.
  Still pull these live every time: routes run, route participation, TPRR, YPRR and
  first downs per route (all from `per_route.py`, below), DPI drawn and red-zone
  looks (`v1_witch_dpi.py`, `v1_witch_redzone.py`, below), individual defender
  coverage stats, injuries and practice reports, inactives, QB
  status, depth charts, lines, props, weather, ECR, and coordinator confirmation.
  For QBs, also pull live: his passing lines and splits, pass rusher stats, and OL
  grades and win rates.
  The sources below are fallbacks for anything the docs don't cover, and for games
  after a doc's "last game" date.
- Benchmarks: `claude/v1_Matchup_Witch_benchmarks.md`, trimmed from the Redraft
  Witch's `v2_Redraft_Witch_benchmarks.md` (Oct 15, 2026). It holds:
  - section 1, quick-lookup lines for WR, TE and RB usage, plus the weighted-
    opportunity formula;
  - section 2, carry-forward fits at Weeks 3, 6 and 9, and the WR per-route fit;
  - section 3, the 2025 per-route bands for WR, TE and RB;
  - section 4, the own-target red-zone regression flag (not used in this project);
  - section 5, what travels when a player changes teams.
  Its definitions match the cached docs and the scripts (targets exclude DPIs and
  two-point tries; red zone inside the 20). Weighted opportunity takes red-zone
  carries and targets from `v1_witch_redzone.py` and all carries and targets from
  nflverse weekly stats. The doc leaves out first-read share; this project doesn't
  pull FTN charting, so don't compute it. Any mention of the Redraft Witch's
  guardrails, grimoire or usage script belongs to her project; don't look for them.
- Pro-Football-Reference, full-season points allowed by position:
  pro-football-reference.com/years/{YEAR}/fantasy-points-against-{QB|RB|WR|TE}.htm
  Standard scoring; add receptions for PPR. Includes WR/TE rushing, so it runs
  slightly higher than receiving-only totals. QB scoring there is 4-point passing
  TDs and −2 INT, same as the docs.
- FFToday per-game points allowed by team:
  fftoday.com/stats/fantasystats.php?o=2&TeamID={ID}&Season={YEAR}&PosID={10 QB|20 RB|30 WR|40 TE}&Side=Allowed&LeagueID=
  (Eagles = 9016). Reliable for the current season only; the Season parameter often
  gets ignored for past seasons. Includes targets.
- PFR box scores (from the team schedule page /teams/{abbr}/{YEAR}.htm): the
  passing, receiving and rushing tables work, but snap counts and play-by-play are
  hidden from page fetches. Pull every opposing player and identify positions yourself.
- nflverse (best for routes, coverage, run direction, box counts, blitz, pressure
  and snap counts). Needs code execution plus GitHub access:
  github.com/nflverse/nflverse-data/releases/download/
    pbp/play_by_play_{YEAR}.parquet   (EPA, success, air yards, YAC, pass location,
      run_location, run_gap, shotgun, spread_line; for QBs also cpoe, qb_dropback,
      qb_scramble, sack, interception, fumble_lost)
    pbp_participation/pbp_participation_{YEAR}.parquet   (route, man/zone, coverage
      type, defenders_in_box, number_of_pass_rushers, was_pressure; join on
      game_id + play_id)
    stats_player/stats_player_week_{YEAR}.parquet   (weekly stat lines incl.
      passing, sacks, fumbles lost and fantasy points; posted for the current season)
    snap_counts/snap_counts_{YEAR}.parquet   (weekly offensive snap % by player;
      posted for the current season)
    rosters/roster_{YEAR}.parquet   (positions; weekly team, useful for tracking
      players who changed teams)
  Route charting covers only the targeted receiver's route. nflverse does not
  label zone vs gap runs. Participation data for the current season is usually not
  posted yet, so current-season route and coverage detail must come from articles
  (PFF, Fantasy Points, PlayerProfiler) or play-by-play depth and location only.
  If code or GitHub isn't available, say so and use web sources: PlayerProfiler,
  4for4, PFF/Fantasy Points articles, rbsdm.com (EPA and success-rate team
  rankings), ESPN win rates.
- Routes and per-route stats (routes run, route participation, TPRR, YPRR, first
  downs per route): run `per_route.py`. The script, its failure table and its limits
  are in the project doc `claude/per_route_guide.md`.
  - Setup: the script is in the coven repo (see "Start of every chat" in the
    instructions): `coven/matchup/per_route.py`. The repo copy was
    checked against the guide's copy check (`36e64eeb64db`) and the Tre Harris line
    (2025: 294 routes, TPRR 0.146, YPRR 1.10, first downs per route 0.061) on
    Oct 19, 2026; no need to rerun them. If the repo can't be downloaded, read the
    guide, save its section 4 script as `per_route.py` exactly as written, run the
    guide's copy check, and say so.
  - Run: `python3 per_route.py "Player Name"`, with `--season 2025` for last season
    and `--team {nflverse code}` only if the name is ambiguous. It needs code
    execution, pandas and GitHub access.
  - Each stat is a division across two sources. Routes come only from the PFF weekly
    recap tables (one file per team per week, on a PFF writer's GitHub; unofficial,
    and the address could change). Targets, receiving yards and receiving first downs
    come only from nflverse weekly player stats. nflverse has no route counts; the PFF
    table has no first downs.
  - Route participation is the script's `route_sh` column: his routes ÷ the table's
    Team Total routes, which is the team's dropbacks.
  - Take targets from nflverse, not the PFF table (PFF's count is sometimes off by
    one). A game with routes and no target counts, with zero yards. Running backs are
    `HB` and fullbacks `FB` in the PFF table; the Rams are `LA` in nflverse.
  - nflverse targets leave out DPIs, so TPRR does too. For a receiver who draws a
    lot of DPI, say that his TPRR understates how often he's thrown at.
  - Coverage: 2025 and 2026 only. Expect a Sunday game's table and stats within a day
    or two (the lag was not measured). Name any week that is missing.
  - Benchmark bands for all three positions, and the Weeks 1–3 WR per-route fit,
    are in the benchmarks doc (above).
  - If the script fails, follow the guide's section 7. If the shell can't reach
    GitHub, fetch the PFF table by page fetch at
    `https://llmnj.github.io/html_tests/{season}_{week}_{Team_Name}.html`. If routes
    still can't be had, say so and fall back to PFF, PlayerProfiler, Fantasy Points or
    FTN articles. Name the source for each number; mixing providers within a
    comparison is fine.
  - The guide points to a grimoire, a `v1.3_witch_usage.py` script and a benchmarks
    doc. None of them is in this project except this project's own benchmarks doc
    (above); don't look for the others.
  - Snap share comes from nflverse snap_counts.
- DPI and red-zone scripts: `v1_witch_dpi.py` (DPI drawn by receiver) and
  `v1_witch_redzone.py` (red-zone and end-zone looks by week, with team totals).
  Written by the Redraft Witch; code, method and test record are in the project doc
  `claude/v1_redzone_DPI_scripts.md`.
  - Why: nflverse logs every DPI as `play_type == "no_play"` with no
    `receiver_player_id`, so every target count built on nflverse (play-by-play
    targets, weekly stats, the cached docs, `per_route.py`) leaves DPIs out.
    `v1_witch_dpi.py` reads the intended receiver from the play description and
    matches jersey number and team to the nflverse roster.
  - Setup: both scripts are in the coven repo:
    `coven/shared/v1_witch_dpi.py` and `coven/shared/v1_witch_redzone.py`.
    The repo copies were checked against the doc's copy checks (`bfed932eaf16`,
    `e88be7e229b5`) and its settled lines (Tre Harris: 2 DPIs for 54 yards in Weeks
    1–2; Fannin Weeks 1–5 red-zone targets 0, 0, 2, 1, 0 vs team 1, 4, 4, 4, 2) on
    Oct 19, 2026; no need to rerun them. If the repo can't be downloaded, save each
    script from the doc exactly as written, run the doc's copy checks, and say so.
  - Run: `python3 v1_witch_dpi.py "Name" "Name"` and
    `python3 v1_witch_redzone.py "Name" "Name"`, with names spelled as in nflverse
    weekly stats (e.g. "Harold Fannin Jr.", "Ollie Gordon II"). Both read the CSV
    files into `./witch_cache` and refresh them after 6 hours. Both are hard-coded
    to 2026; don't estimate a last-season comparison.
  - Definitions: red zone = inside the opponent's 20; end-zone target =
    `air_yards >= yardline_100`; two-point tries excluded. DPIs are not in the
    red-zone counts; the DPI script's `rz` column counts DPIs drawn inside the 20.
  - The DPI script prints every DPI it couldn't match. If one involves the player
    or a named alternative, name it and count it by hand from the description.
  - Red-zone samples are small: under ~20 looks, the share is a pattern, not a rate
    (ground rules).
  - DPI committed by a defense is in neither script. Count it from play-by-play
    (`penalty_type` containing "Defensive Pass Interference", grouped by
    `defteam`, regular season), and check that the league total matches the DPI
    script's header count.
  - The scripts' notes mention `v1.3_witch_usage.py`, the grimoire and a
    "guardrail 19". Those belong to the Redraft Witch's project; don't look for them.
- QB splits and grades: PFF (pressure, blitz, play-action, time in pocket,
  turnover-worthy plays, pass-block and pass-rush grades), Next Gen Stats (time to
  throw, aggressiveness, CPOE), rbsdm.com (EPA and CPOE by QB), Fantasy Points, FTN,
  ESPN pass-rush and pass-block win rates.
- Weather: NFL weather pages (e.g. RotoWire's) and forecast services; recheck on
  game day. For games already played, the nflverse play-by-play `weather` column
  has a text description with conditions, temperature and wind (e.g. "Steady rain
  ... Wind: E 11 mph"); read wind from that text, because the numeric `wind` and
  `temp` columns are often empty. If the text is missing for an outdoor game, say
  so.
- Prop lines: BetMGM, FanDuel and DraftKings player-prop pages, or BettingPros.
  Newspaper odds roundups (e.g., the Philadelphia Inquirer) often list props too.
- Consensus rankings: FantasyPros weekly ECR (1QB and superflex for QBs).
- Injuries and QB news: team sites, beat writers and RotoWire/CBS/NBC player news
  (search "{team} injury report week {N}" and "{player} injury update").
