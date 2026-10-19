#!/usr/bin/env python3
"""Benchmarks v2 - step 3: how much an early-season number carries forward, 2018-2025 pooled.
Early window = Weeks 1..K (K = 3, 6, 9); he must have played in at least K-1 of them (2 of 3, 5 of 6, 8 of 9).
Rest of season = Weeks K+1 to the end, 6+ games. Two pools: everyone, and regulars (early snap share 50%+).
For each stat: r (early -> same stat rest of season), r (early -> rest-of-season PPR/g), and the line
rest = a + b x early, which says what an early figure usually regresses to.
  python3 carry.py > carry_out.md"""
import pandas as pd, numpy as np
import season as S
pw = S.load()
STATS = {"WR": ["snap", "tgt_sh", "fr_sh", "rz_tgt_sh", "ezpg", "tpg", "ppg"], "TE": ["snap", "tgt_sh", "fr_sh", "rz_tgt_sh", "ezpg", "tpg", "ppg"],
         "RB": ["snap", "car_sh", "rz_car_sh", "i5_sh", "tgt_sh", "tpg", "wo", "ppg"]}
for K in (3, 6, 9):
    e = S.agg(pw[pw.week <= K]); e = e[e.g >= K - 1]
    r = S.agg(pw[pw.week > K]); r = r[r.g >= 6]
    j = e.merge(r, on=["player_id", "season"], suffixes=("_e", "_r"))
    print(f"\n### Through Week {K} (early: {K-1}+ of {K} games; rest of season: 6+ games)")
    print("| Pos | Stat | Pool | n | r same stat | r ROS PPR/g | Rest of season = a + b x early |\n|---|---|---|---|---|---|---|")
    for pos, cols in STATS.items():
        for c in cols:
            for pool in ("all", "regulars"):
                x = j[(j.pos_e == pos)]
                if pool == "regulars": x = x[x.snap_e >= 0.5]
                x = x[[c + "_e", c + "_r", "ppg_r"]].dropna() if c != "ppg" else x[["ppg_e", "ppg_r"]].dropna()
                if c == "fr_sh": pass
                if len(x) < 30: continue
                b, a = np.polyfit(x[c + "_e"], x[c + "_r"], 1)
                fmt = (lambda v: f"{v:.3f}") if c not in ("ezpg", "tpg", "wo", "ppg") else (lambda v: f"{v:.2f}")
                print(f"| {pos} | {c} | {pool} | {len(x)} | {x[c+'_e'].corr(x[c+'_r']):.2f} | {x[c+'_e'].corr(x.ppg_r):.2f} | {fmt(a)} + {b:.2f} x early |")
