#!/usr/bin/env python3
"""v1 - red-zone and end-zone usage by week for named players, with share of the team's red-zone looks.
Red zone = snap inside the opponent's 20 (yardline_100 <= 20). End-zone target = air_yards >= yardline_100 (thrown into the end zone).
Two-point tries are excluded, as in the usage script. DPI plays are NOT here (they carry no receiver id); use v1_witch_dpi.py.
  python3 v1_witch_redzone.py "Harold Fannin Jr." "Tyler Higbee"
Uses ./witch_cache."""
import os, sys, time, urllib.request
import pandas as pd
NV = "https://github.com/nflverse/nflverse-data/releases/download"; CACHE = "witch_cache"; Y = 2026
os.makedirs(CACHE, exist_ok=True)
def fetch(tag, f):
    p = os.path.join(CACHE, f)
    if not os.path.exists(p) or time.time() - os.path.getmtime(p) > 6 * 3600: urllib.request.urlretrieve(f"{NV}/{tag}/{f}", p)
    return p
st = pd.read_csv(fetch("stats_player", f"stats_player_week_{Y}.csv"), low_memory=False); st = st[(st.season_type == "REG") & st.player_id.notna()]
pb = pd.read_csv(fetch("pbp", f"play_by_play_{Y}.csv"), low_memory=False, usecols=["season_type", "week", "posteam", "play_type", "two_point_attempt",
     "receiver_player_id", "rusher_player_id", "yardline_100", "air_yards", "pass_touchdown", "rush_touchdown"])
pb = pb[(pb.season_type == "REG") & pb.two_point_attempt.ne(1) & (pb.yardline_100 <= 20)]
tg = pb[(pb.play_type == "pass") & pb.receiver_player_id.notna()]; ca = pb[(pb.play_type == "run") & pb.rusher_player_id.notna()]
for name in sys.argv[1:]:
    ids = st[st.player_display_name == name].player_id.unique()
    if len(ids) != 1: print(f"{name}: {len(ids)} matches in weekly stats - check the spelling"); continue
    i = ids[0]; team = st[st.player_id == i].team.iloc[-1]
    t, c = tg[tg.receiver_player_id == i], ca[ca.rusher_player_id == i]
    ez = t[t.air_yards.notna() & (t.air_yards >= t.yardline_100)]
    tt, tc = tg[tg.posteam == team], ca[ca.posteam == team]
    wk = pd.DataFrame({"rz_tgt": t.groupby("week").size(), "ez_tgt": ez.groupby("week").size(), "rz_car": c.groupby("week").size(),
                       "team_rz_tgt": tt.groupby("week").size(), "team_rz_car": tc.groupby("week").size()}).fillna(0).astype(int)
    print(f"\n{name} ({team}) - red-zone looks by week (team totals shown for share)")
    print(wk.to_string())
    print(f"Season: RZ targets {len(t)} of {len(tt)} ({len(t)/max(len(tt),1):.0%}) | end-zone targets {len(ez)} | RZ carries {len(c)} of {len(tc)} ({len(c)/max(len(tc),1):.0%})"
          f" | RZ TDs: receiving {int(t.pass_touchdown.fillna(0).sum())}, rushing {int(c.rush_touchdown.fillna(0).sum())}")
