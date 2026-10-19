#!/usr/bin/env python3
"""Benchmarks v2 - shared helpers: aggregate player-weeks (pw.parquet from build.py) into player-season lines.
A game counts if the player had an offensive snap or a stat line that week. Shares are his total over his games
divided by his teams' totals in those same games (handles trades). Snap share = mean offense_pct over games with a snap row."""
import pandas as pd, numpy as np, os
D = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
WO = dict(rz_car=1.28, rz_tgt=2.39, out_car=0.47, out_tgt=1.54)        # PFF 2019 weighted-opportunity weights

def load():
    pw = pd.read_parquet(f"{D}/pw.parquet")
    pw = pw[(pw.offense_snaps.fillna(0) > 0) | (pw.tgt + pw.car + pw.receptions > 0)].copy()
    return pw

def agg(pw, keys=("player_id", "season")):
    keys = list(keys)
    g = pw.groupby(keys).agg(name=("player_display_name", "first"), pos=("position", "first"), team=("posteam", "last"),
        g=("week", "nunique"), snap=("offense_pct", "mean"),
        tgt=("tgt", "sum"), tm_tgt=("tm_tgt", "sum"), rz_tgt=("rz_tgt", "sum"), tm_rz_tgt=("tm_rz_tgt", "sum"),
        ez_tgt=("ez_tgt", "sum"), fr_tgt=("fr_tgt", lambda s: s.sum(min_count=1)), tm_fr=("tm_fr", lambda s: s.sum(min_count=1)),
        car=("car", "sum"), tm_car=("tm_car", "sum"), rz_car=("rz_car", "sum"), tm_rz_car=("tm_rz_car", "sum"),
        i5_car=("i5_car", "sum"), tm_i5_car=("tm_i5_car", "sum"), fd=("receiving_first_downs", "sum"),
        ppr=("fantasy_points_ppr", "sum"), rookie=("rookie_season", "first"), rnd=("draft_round", "first")).reset_index()
    g["tgt_sh"] = g.tgt / g.tm_tgt; g["rz_tgt_sh"] = g.rz_tgt / g.tm_rz_tgt.replace(0, np.nan)
    g["rz_pct_own"] = g.rz_tgt / g.tgt.replace(0, np.nan)              # share of HIS targets that came in the red zone (PFF 2012 method)
    g["fr_sh"] = g.fr_tgt / g.tm_fr; g["car_sh"] = g.car / g.tm_car
    g["rz_car_sh"] = g.rz_car / g.tm_rz_car.replace(0, np.nan); g["i5_sh"] = g.i5_car / g.tm_i5_car.replace(0, np.nan)
    g["ppg"] = g.ppr / g.g; g["tpg"] = g.tgt / g.g; g["cpg"] = g.car / g.g; g["ezpg"] = g.ez_tgt / g.g
    g["i5pg"] = g.i5_car / g.g; g["rztpg"] = g.rz_tgt / g.g; g["rzcpg"] = g.rz_car / g.g
    g["wo"] = (WO["rz_car"] * g.rz_car + WO["rz_tgt"] * g.rz_tgt + WO["out_car"] * (g.car - g.rz_car) + WO["out_tgt"] * (g.tgt - g.rz_tgt)) / g.g
    return g

def ranked(s, minG=8):
    """Season pool: 8+ games. Finish rank = PPR per game rank within season and position among that pool."""
    s = s[s.g >= minG].copy()
    s["fin"] = s.groupby(["season", "pos"]).ppg.rank(ascending=False, method="min")
    return s

def bands(s, col, cuts, label=None, fmt="{:.0%}"):
    """Print one band table: n, median PPR/g, share finishing top 12/24/36 in PPR per game."""
    rows = []
    edges = sorted(cuts, reverse=True)
    for i, lo in enumerate(edges):
        hi = edges[i - 1] if i else np.inf
        x = s[(s[col] >= lo) & (s[col] < hi)]
        rows.append((fmt.format(lo) + ("+" if i == 0 else " to " + fmt.format(hi)), len(x), x.ppg.median(), (x.fin <= 12).mean(), (x.fin <= 24).mean(), (x.fin <= 36).mean()))
    x = s[s[col] < edges[-1]]
    rows.append(("under " + fmt.format(edges[-1]), len(x), x.ppg.median(), (x.fin <= 12).mean(), (x.fin <= 24).mean(), (x.fin <= 36).mean()))
    t = pd.DataFrame(rows, columns=["band", "n", "med_ppg", "top12", "top24", "top36"])
    return t
