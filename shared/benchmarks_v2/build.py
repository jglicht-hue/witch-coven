#!/usr/bin/env python3
"""Benchmarks v2 - step 1: one row per player-week, 2018-2025 regular seasons, from nflverse.
Definitions match the usage script (v1.3) and the red-zone script (v1):
  target  = pass play, receiver_player_id set, not a 2-pt try
  carry   = run play, rusher_player_id set, not a 2-pt try (kneels are play_type qb_kneel, so excluded)
  red zone = yardline_100 <= 20 ; inside 5 = yardline_100 <= 5 ; end-zone target = air_yards >= yardline_100
  first read = FTN read_thrown == '1' (2022+ only)
Team totals are per team-week. Snap share = snap_counts offense_pct joined on pfr_id.
Output: pw.parquet in the data folder."""
import pandas as pd, numpy as np, os
D = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
YEARS = range(2018, 2026)
pl = pd.read_parquet(f"{D}/players.parquet", columns=["gsis_id", "pfr_id", "rookie_season", "draft_round", "draft_year"])
out = []
for y in YEARS:
    pb = pd.read_parquet(f"{D}/play_by_play_{y}.parquet", columns=["game_id", "play_id", "season_type", "week", "posteam", "play_type",
         "two_point_attempt", "receiver_player_id", "rusher_player_id", "yardline_100", "air_yards", "qb_dropback"])
    pb = pb[(pb.season_type == "REG") & pb.two_point_attempt.ne(1)]
    tg = pb[(pb.play_type == "pass") & pb.receiver_player_id.notna()].copy()
    ca = pb[(pb.play_type == "run") & pb.rusher_player_id.notna()].copy()
    db = pb[pb.play_type.isin(["pass", "run"]) & (pb.qb_dropback == 1)]
    tg["rz"] = tg.yardline_100 <= 20; tg["ez"] = tg.air_yards.notna() & (tg.air_yards >= tg.yardline_100)
    ca["rz"] = ca.yardline_100 <= 20; ca["i5"] = ca.yardline_100 <= 5
    tg["fr"] = np.nan
    if y >= 2022:
        f = pd.read_parquet(f"{D}/ftn_charting_{y}.parquet", columns=["nflverse_game_id", "nflverse_play_id", "read_thrown"])
        f["nflverse_play_id"] = pd.to_numeric(f.nflverse_play_id); tg["play_id"] = pd.to_numeric(tg.play_id)
        tg = tg.merge(f, left_on=["game_id", "play_id"], right_on=["nflverse_game_id", "nflverse_play_id"], how="left")
        tg["fr"] = np.where(tg.read_thrown.isna(), np.nan, (tg.read_thrown.astype(str).str.strip() == "1").astype(float))
    k = ["posteam", "week"]
    team = pd.concat([tg.groupby(k).size().rename("tm_tgt"), tg.groupby(k).rz.sum().rename("tm_rz_tgt"),
                      tg.groupby(k).ez.sum().rename("tm_ez_tgt"), tg.groupby(k).fr.sum(min_count=1).rename("tm_fr"),
                      ca.groupby(k).size().rename("tm_car"), ca.groupby(k).rz.sum().rename("tm_rz_car"),
                      ca.groupby(k).i5.sum().rename("tm_i5_car"), db.groupby(k).size().rename("tm_db")], axis=1).reset_index()
    pr = tg.groupby(["receiver_player_id", "posteam", "week"]).agg(tgt=("rz", "size"), rz_tgt=("rz", "sum"), ez_tgt=("ez", "sum"),
          fr_tgt=("fr", lambda s: s.sum(min_count=1))).reset_index().rename(columns={"receiver_player_id": "player_id"})
    pc = ca.groupby(["rusher_player_id", "posteam", "week"]).agg(car=("rz", "size"), rz_car=("rz", "sum"), i5_car=("i5", "sum")
          ).reset_index().rename(columns={"rusher_player_id": "player_id"})
    st = pd.read_parquet(f"{D}/stats_player_week_{y}.parquet")
    st = st[(st.season_type == "REG") & st.player_id.notna() & st.position.isin(["WR", "TE", "RB"])]
    st = st[["player_id", "player_display_name", "position", "team", "week", "receptions", "receiving_yards", "receiving_tds",
             "receiving_first_downs", "rushing_yards", "rushing_tds", "fantasy_points_ppr"]].rename(columns={"team": "posteam"})
    sn = pd.read_parquet(f"{D}/snap_counts_{y}.parquet"); sn = sn[(sn.game_type == "REG") & (sn.offense_snaps > 0)]
    sn = sn.merge(pl[["gsis_id", "pfr_id"]].dropna(), left_on="pfr_player_id", right_on="pfr_id", how="inner")
    sn = sn[["gsis_id", "team", "week", "offense_snaps", "offense_pct"]].rename(columns={"gsis_id": "player_id", "team": "posteam"})
    sn = sn.drop_duplicates(["player_id", "week"])
    # a player-week exists if he had an offensive snap OR a stat line (stats file rows mean he touched the ball or was targeted)
    base = st.merge(sn, on=["player_id", "posteam", "week"], how="outer")
    base = base.merge(pr, on=["player_id", "posteam", "week"], how="left").merge(pc, on=["player_id", "posteam", "week"], how="left")
    base = base.merge(team, on=["posteam", "week"], how="left")
    for c in ["tgt", "rz_tgt", "ez_tgt", "car", "rz_car", "i5_car", "receptions", "receiving_yards", "receiving_tds",
              "receiving_first_downs", "rushing_yards", "rushing_tds", "fantasy_points_ppr"]:
        base[c] = base[c].fillna(0)
    if y < 2022: base["fr_tgt"] = np.nan; base["tm_fr"] = np.nan
    else: base["fr_tgt"] = base.fr_tgt.fillna(0).where(base.tm_fr.notna())
    base["season"] = y
    out.append(base)
    print(y, "player-weeks", len(base), "| snap rows matched", base.offense_pct.notna().sum(), "| team-weeks", len(team))
pw = pd.concat(out, ignore_index=True)
# position and name: fill from the player's season mode where the stats file had no row (snap-only weeks)
pw["position"] = pw.groupby(["player_id", "season"]).position.transform(lambda s: s.dropna().mode().iloc[0] if s.notna().any() else np.nan)
pw["player_display_name"] = pw.groupby("player_id").player_display_name.transform(lambda s: s.dropna().iloc[0] if s.notna().any() else np.nan)
pw = pw[pw.position.isin(["WR", "TE", "RB"])]
pw = pw.merge(pl[["gsis_id", "rookie_season", "draft_round"]].drop_duplicates("gsis_id"), left_on="player_id", right_on="gsis_id", how="left").drop(columns="gsis_id")
pw.to_parquet(f"{D}/pw.parquet", index=False)
print("total", len(pw), pw.groupby(["season", "position"]).player_id.nunique().unstack().to_string())
