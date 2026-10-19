#!/usr/bin/env python3
"""v1 - defensive pass interference (DPI) drawn by receiver, from nflverse play-by-play.
Why: in the 2026 nflverse play-by-play, DPI plays are logged as play_type 'no_play' with NO receiver_player_id,
so any target/usage count built on receiver_player_id silently skips them.
Method: read the intended receiver from the play description ("... to 9-T.Harris" or "intended for 13-P.Bryant"),
then map jersey number + offense team to a GSIS id with the nflverse roster file. Plays with no named receiver are listed as unmatched.
  python3 v1_witch_dpi.py "Tre Harris" "Tyler Higbee"     # these players
  python3 v1_witch_dpi.py                                 # league table, top 25 by DPI yards
Uses ./witch_cache (same folder and 6-hour refresh as v1.3_witch_usage.py)."""
import os, re, sys, time, urllib.request
import pandas as pd
NV = "https://github.com/nflverse/nflverse-data/releases/download"; CACHE = "witch_cache"; Y = 2026
os.makedirs(CACHE, exist_ok=True)
def fetch(tag, f):
    p = os.path.join(CACHE, f)
    if not os.path.exists(p) or time.time() - os.path.getmtime(p) > 6 * 3600: urllib.request.urlretrieve(f"{NV}/{tag}/{f}", p)
    return p
pb = pd.read_csv(fetch("pbp", f"play_by_play_{Y}.csv"), low_memory=False,
                 usecols=["season_type", "week", "posteam", "penalty_type", "penalty_yards", "yardline_100", "desc"])
pb = pb[(pb.season_type == "REG") & pb.penalty_type.fillna("").str.contains("Defensive Pass Interference")].copy()
ro = pd.read_csv(fetch("rosters", f"roster_{Y}.csv"), low_memory=False, usecols=["team", "jersey_number", "full_name", "gsis_id", "week"])
pat = re.compile(r"(?:\bto|intended for) (\d+)-([A-Za-z][\w'.-]*)")
m = pb.desc.map(lambda s: pat.search(str(s)))
pb["jersey"] = m.map(lambda x: float(x.group(1)) if x else None); pb["abbr"] = m.map(lambda x: x.group(2) if x else None)
ro = ro.dropna(subset=["jersey_number"]).sort_values("week").drop_duplicates(["team", "jersey_number", "gsis_id"], keep="last")
j = pb.merge(ro[["team", "jersey_number", "full_name", "gsis_id"]], left_on=["posteam", "jersey"], right_on=["team", "jersey_number"], how="left")
# a jersey can be reused within a season: keep the roster name whose surname matches the description abbreviation
j["ok"] = [isinstance(n, str) and isinstance(a, str) and a.split(".")[-1].lower() in n.lower() for n, a in zip(j.full_name, j.abbr)]
j = j.sort_values("ok", ascending=False).drop_duplicates(subset=["desc"], keep="first")
j.loc[~j.ok, ["full_name", "gsis_id"]] = None
print(f"DPI plays {len(pb)} | receiver named in description {pb.jersey.notna().sum()} | matched to a player {j.gsis_id.notna().sum()}")
g = j[j.gsis_id.notna()].groupby(["full_name", "posteam"]).agg(dpi=("desc", "size"), yds=("penalty_yards", "sum"),
     rz=("yardline_100", lambda s: int((s <= 20).sum())), weeks=("week", lambda s: sorted(s.astype(int).tolist()))).reset_index()
want = sys.argv[1:]
if want:
    out = g[g.full_name.isin(want)]
    print(out.to_string(index=False) if len(out) else "none found"); miss = [w for w in want if w not in set(g.full_name)]
    if miss: print("No DPI drawn (or not matched):", miss)
else:
    print(g.sort_values("yds", ascending=False).head(25).to_string(index=False))
un = j[j.gsis_id.isna()]
if len(un): print(f"\nUnmatched DPI plays ({len(un)}):\n" + "\n".join(un.desc.str.slice(0, 140)))
