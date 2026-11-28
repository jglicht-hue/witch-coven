#!/usr/bin/env python3
"""Builds the two small reference tables that v1_witch_bench.py reads. Run once a season (or when the method changes).
Inputs: benchmarks_v2/data/pw.parquet (benchmarks_v2/build.py) and perroute_2025.parquet (benchmarks_v2/perroute.py).
  bench_fit.csv  - pos, stat, n, pool, a, b, nobs: a player's first n games predict the rest of his season as a + b x figure
                   (2018-2025; first-read share 2022-2025; n = 2..11 games played; rest of season 6+ games;
                   pool = regulars if his snap share over those n games is 50%+, else all)
  bench_pct.csv  - pos, stat, p, value: the p-th percentile (0-100) of full-season figures, player-seasons with 8+ games,
                   2018-2025 (first-read share 2022-2025). Route share: 2025 PFF routes, 8+ games.
                   Per-route stats: 2025, WR 250+, TE 200+, RB 100+ routes.
  python3 build_ref.py"""
import os, sys, numpy as np, pandas as pd
H = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(H, "..", "benchmarks_v2"))
import season as S
pw = S.load()
STATS = {"WR": ["snap", "tgt_sh", "fr_sh", "rz_tgt_sh", "ezpg", "tpg"], "TE": ["snap", "tgt_sh", "fr_sh", "rz_tgt_sh", "ezpg", "tpg"],
         "RB": ["snap", "car_sh", "rz_car_sh", "i5_sh", "tgt_sh", "tpg", "wo"]}
pw = pw.sort_values(["player_id", "season", "week"]).copy()
pw["gn"] = pw.groupby(["player_id", "season"]).cumcount() + 1                 # his n-th game of the season
fits = []
for n in range(2, 12):
    e = S.agg(pw[pw.gn <= n]); e = e[e.g == n]
    r = S.agg(pw[pw.gn > n]); r = r[r.g >= 6]
    j = e.merge(r, on=["player_id", "season"], suffixes=("_e", "_r"))
    for pos, cols in STATS.items():
        for c in cols:
            for pool in ("all", "regulars"):
                x = j[j.pos_e == pos]
                if pool == "regulars": x = x[x.snap_e >= 0.5]
                else: x = x[x.snap_e < 0.5]
                x = x[[c + "_e", c + "_r"]].replace([np.inf, -np.inf], np.nan).dropna()
                if len(x) < 30: continue
                b, a = np.polyfit(x[c + "_e"], x[c + "_r"], 1)
                fits.append((pos, c, n, pool, round(a, 4), round(b, 4), len(x)))
F = pd.DataFrame(fits, columns=["pos", "stat", "n", "pool", "a", "b", "nobs"])
F.to_csv(os.path.join(H, "bench_fit.csv"), index=False)
s = S.ranked(S.agg(pw))
P = np.arange(0, 101)
rows = []
for pos, cols in STATS.items():
    for c in cols:
        x = s[(s.pos == pos)][c].replace([np.inf, -np.inf], np.nan).dropna()
        for p, v in zip(P, np.percentile(x, P)): rows.append((pos, c, int(p), round(float(v), 4), len(x)))
g = pd.read_parquet(os.path.join(S.D, "perroute_2025.parquet"))
for pos, minr in (("WR", 250), ("TE", 200), ("RB", 100)):
    for c in ("rsh", "tprr", "yprr", "fdrr"):
        z = g[(g.pos == pos) & ((g.g >= 8) if c == "rsh" else (g.routes >= minr))]     # route share: same 8+ game pool as snap share
        for p, v in zip(P, np.percentile(z[c].dropna(), P)): rows.append((pos, c, int(p), round(float(v), 4), len(z)))
pd.DataFrame(rows, columns=["pos", "stat", "p", "value", "nobs"]).to_csv(os.path.join(H, "bench_pct.csv"), index=False)
print(f"bench_fit.csv {len(F)} rows | bench_pct.csv {len(rows)} rows")
print(F[(F.n.isin([3, 6, 9])) & (F.pool == "regulars") & (F.stat == "tgt_sh")].to_string(index=False))
