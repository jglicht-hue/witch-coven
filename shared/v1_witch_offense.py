#!/usr/bin/env python3
"""v1 - team offense context for the Redraft Witch (guardrail 18).
For every team, over COMPLETED weeks only:
  - points per game and league rank (ties share the worse rank, so a tie for last reads as 32nd)
  - opponent-adjusted scoring and rank: for each game, points scored minus the average that opponent
    allowed in its OTHER games, averaged across the team's games
  - volume, left raw: dropbacks per game and rushing attempts per game, with ranks
  python3 v1_witch_offense.py MIA DAL            # these teams (nflverse codes: LA = Rams, JAX = Jaguars)
  python3 v1_witch_offense.py                    # all 32 teams
  python3 v1_witch_offense.py MIA --through 3    # stop at a given week
  python3 v1_witch_offense.py MIA --games        # also print the game-by-game adjustment
Uses the same ./witch_cache folder as v1.3_witch_usage.py (files refreshed after 6 hours)."""
import argparse, os, time, urllib.request
import pandas as pd

ap = argparse.ArgumentParser()
ap.add_argument("teams", nargs="*"); ap.add_argument("--season", type=int, default=2026)
ap.add_argument("--through", type=int); ap.add_argument("--games", action="store_true")
a = ap.parse_args()
NV = "https://github.com/nflverse/nflverse-data/releases/download"
CACHE = "witch_cache"; os.makedirs(CACHE, exist_ok=True)


def fetch(tag, f):
    p = os.path.join(CACHE, f)
    if not os.path.exists(p) or time.time() - os.path.getmtime(p) > 6 * 3600:
        urllib.request.urlretrieve(f"{NV}/{tag}/{f}", p)
    return p


# Scores and the schedule come from the nflverse games file. A week is complete when every scheduled game has a score.
g = pd.read_csv(fetch("schedules", "games.csv"), low_memory=False)
g = g[(g.season == a.season) & (g.game_type == "REG")]
by_week = g.groupby("week").agg(scheduled=("game_id", "size"), played=("home_score", "count"))
weeks = [int(w) for w in by_week.index if by_week.played[w] == by_week.scheduled[w]]
if a.through: weeks = [w for w in weeks if w <= a.through]
if not weeks: raise SystemExit("No completed weeks found.")
g = g[g.week.isin(weeks)]

r = pd.concat([g.rename(columns={"home_team": "team", "away_team": "opp", "home_score": "pf", "away_score": "pa"}),
               g.rename(columns={"away_team": "team", "home_team": "opp", "away_score": "pf", "home_score": "pa"})])[["week", "team", "opp", "pf", "pa"]]
tot = r.groupby("team").agg(pa_sum=("pa", "sum"), n=("pa", "size"))
r = r.merge(tot, left_on="opp", right_index=True)
r["opp_allowed_elsewhere"] = (r.pa_sum - r.pf) / (r.n - 1).where(r.n > 1)   # leave this game out of the opponent's baseline
r["adj"] = r.pf - r.opp_allowed_elsewhere

pb = pd.read_csv(fetch("pbp", f"play_by_play_{a.season}.csv"), low_memory=False,
                 usecols=["season_type", "week", "posteam", "play_type", "two_point_attempt", "qb_dropback", "rusher_player_id"])
pb = pb[(pb.season_type == "REG") & pb.week.isin(weeks)]
ok = pb.two_point_attempt.ne(1)                                   # same play definitions as the grimoire, section 3
db = pb[ok & pb.play_type.isin(["pass", "run"]) & (pb.qb_dropback == 1)].groupby("posteam").size()
ru = pb[ok & (pb.play_type == "run") & pb.rusher_player_id.notna()].groupby("posteam").size()

t = r.groupby("team").agg(games=("pf", "size"), ppg=("pf", "mean"), opp_allowed_elsewhere=("opp_allowed_elsewhere", "mean"), adj=("adj", "mean"))
t["dropbacks_pg"] = db / t.games; t["rushes_pg"] = ru / t.games
for c in ["ppg", "adj", "dropbacks_pg", "rushes_pg"]:
    t[c + "_rk"] = t[c].rank(ascending=False, method="max").astype("Int64")   # ties share the worse rank
want = [x.upper() for x in a.teams] or sorted(t.index)
bad = [x for x in want if x not in t.index]
if bad: raise SystemExit(f"Unknown team code(s) {bad}. nflverse codes: {sorted(t.index)}")
pd.set_option("display.width", 200)
print(f"Completed weeks used: {weeks} | games per week: {by_week.scheduled[weeks].to_dict()} | teams: {len(t)}")
print(t.loc[want, ["games", "ppg", "ppg_rk", "opp_allowed_elsewhere", "adj", "adj_rk", "dropbacks_pg", "dropbacks_pg_rk",
                   "rushes_pg", "rushes_pg_rk"]].round(1).to_string())
if t.dropbacks_pg.isna().any(): print("WARNING: play-by-play is missing a completed game; volume columns are incomplete.")
if len(weeks) < 6: print("THIN SAMPLE: fewer than 6 completed weeks, so each opponent baseline rests on few games.")
if a.games:
    print(r[r.team.isin(want)].sort_values(["team", "week"])[["team", "week", "opp", "pf", "opp_allowed_elsewhere", "adj"]].round(1).to_string(index=False))
