#!/usr/bin/env python3
"""v1 - offense diagnosis for the team-context table (guardrail 18): yards per play, giveaways and sack rate,
each with league rank, over COMPLETED weeks only. Ties share the worse rank.
  python3 offense_diag.py LAC TB        # these teams (nflverse codes)
  python3 offense_diag.py               # all 32
Uses ./witch_cache (run v1_witch_offense.py or v1.3_witch_usage.py first so the files are there)."""
import sys, os, time, urllib.request
import pandas as pd
NV = "https://github.com/nflverse/nflverse-data/releases/download"; CACHE = "witch_cache"; os.makedirs(CACHE, exist_ok=True)
def fetch(tag, f):
    p = os.path.join(CACHE, f)
    if not os.path.exists(p) or time.time() - os.path.getmtime(p) > 6 * 3600: urllib.request.urlretrieve(f"{NV}/{tag}/{f}", p)
    return p
Y = 2026
g = pd.read_csv(fetch("schedules", "games.csv"), low_memory=False); g = g[(g.season == Y) & (g.game_type == "REG")]
bw = g.groupby("week").agg(n=("game_id", "size"), played=("home_score", "count")); weeks = [int(w) for w in bw.index if bw.played[w] == bw.n[w]]
pb = pd.read_csv(fetch("pbp", f"play_by_play_{Y}.csv"), low_memory=False, usecols=["season_type", "week", "game_id", "posteam", "play_type",
     "two_point_attempt", "qb_dropback", "sack", "interception", "fumble_lost", "yards_gained"])
pb = pb[(pb.season_type == "REG") & pb.week.isin(weeks) & pb.play_type.isin(["pass", "run"]) & pb.two_point_attempt.ne(1)]
t = pb.groupby("posteam").agg(games=("game_id", "nunique"), plays=("yards_gained", "size"), yards_per_play=("yards_gained", "mean"),
     ints=("interception", "sum"), fum=("fumble_lost", "sum"))
d = pb[pb.qb_dropback == 1].groupby("posteam").agg(dropbacks=("sack", "size"), sacks=("sack", "sum"))
t = t.join(d); t["giveaways_pg"] = (t.ints + t.fum) / t.games; t["sack_rate"] = t.sacks / t.dropbacks
t["ypp_rk"] = t.yards_per_play.rank(ascending=False, method="max").astype(int)
t["give_rk"] = t.giveaways_pg.rank(ascending=True, method="max").astype(int)        # 1 = fewest giveaways
t["sack_rk"] = t.sack_rate.rank(ascending=True, method="max").astype(int)           # 1 = lowest sack rate
want = [x.upper() for x in sys.argv[1:]] or sorted(t.index)
print(f"Completed weeks used: {weeks}" + (" | THIN SAMPLE" if len(weeks) < 6 else ""))
print(t.loc[want, ["games", "yards_per_play", "ypp_rk", "giveaways_pg", "give_rk", "sack_rate", "sack_rk"]].round(3).to_string())
