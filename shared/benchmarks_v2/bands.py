#!/usr/bin/env python3
"""Benchmarks v2 - step 2: full-season bands by position, 2018-2025 pooled, plus year-to-year stickiness.
Pool: player-seasons with 8+ games. Finish = PPR-per-game rank within season and position in that pool.
  python3 bands.py > bands_out.md"""
import pandas as pd, numpy as np, sys
import season as S
pd.set_option("display.width", 200)
s = S.ranked(S.agg(S.load()))
P = lambda x: f"{x:.0%}"
def md(t, title):
    print(f"\n#### {title}\n| Band | Player-seasons | Median PPR/g | Top 12 | Top 24 | Top 36 |\n|---|---|---|---|---|---|")
    for r in t.itertuples(): print(f"| {r.band} | {r.n} | {r.med_ppg:.1f} | {P(r.top12)} | {P(r.top24)} | {P(r.top36)} |")
def pct(x, col, f="{:.3f}"):
    q = x[col].quantile([.25, .5, .75, .9]).tolist(); return " / ".join(f.format(v) for v in q)
SPEC = {
 "WR": [("snap", [.85, .70, .55], "Snap share", P), ("tgt_sh", [.25, .20, .15, .10], "Target share", P),
        ("fr_sh", [.30, .22, .15], "Share of team first-read targets (2022-2025)", P),
        ("rz_tgt_sh", [.25, .18, .12], "Red-zone target share", P), ("ezpg", [.75, .5, .25], "End-zone targets per game", "{:.2f}".format)],
 "TE": [("snap", [.80, .65, .50], "Snap share", P), ("tgt_sh", [.20, .15, .10], "Target share", P),
        ("fr_sh", [.20, .14, .08], "Share of team first-read targets (2022-2025)", P),
        ("rz_tgt_sh", [.20, .13, .08], "Red-zone target share", P), ("ezpg", [.5, .3, .15], "End-zone targets per game", "{:.2f}".format)],
 "RB": [("snap", [.65, .50, .35], "Snap share", P), ("car_sh", [.60, .45, .30, .15], "Carry share", P),
        ("rz_car_sh", [.60, .45, .30], "Red-zone carry share", P), ("i5_sh", [.60, .40, .20], "Share of team carries inside the 5", P),
        ("tgt_sh", [.12, .08, .05], "Target share", P), ("tpg", [5, 3.5, 2], "Targets per game", "{:.1f}".format),
        ("wo", [16, 12, 8], "Weighted opportunity per game", "{:.0f}".format)],
}
for pos, specs in SPEC.items():
    x = s[s.pos == pos]
    print(f"\n### {pos} (2018-2025, {len(x)} player-seasons with 8+ games)")
    for col, cuts, title, f in specs:
        xx = x[x[col].notna()]
        if col == "fr_sh": xx = xx[xx.season >= 2022]
        t = S.bands(xx, col, cuts, fmt="{}")
        t["band"] = [b for b in t.band]
        # re-label with the column's own format
        edges = sorted(cuts, reverse=True); labels = [f(edges[0]) + "+"] + [f"{f(edges[i])} to {f(edges[i-1])}" for i in range(1, len(edges))] + ["under " + f(edges[-1])]
        t["band"] = labels
        md(t, f"{title} (n={len(xx)}; 25th/50th/75th/90th pct: {pct(xx, col)})")
# year-to-year stickiness
print("\n### Year-to-year stickiness (same player, 8+ games both seasons; r = correlation season N to N+1)")
a = s.copy(); b = s.copy(); b["season"] -= 1
j = a.merge(b, on=["player_id", "season"], suffixes=("", "_n"))
j["moved"] = j.team != j.team_n
print("| Stat | Pos | Pairs | r all | r same team | r changed team | r with next-year PPR/g |\n|---|---|---|---|---|---|---|")
for pos, cols in [("WR", ["snap", "tgt_sh", "fr_sh", "rz_tgt_sh", "rz_pct_own", "ezpg", "ppg"]), ("TE", ["snap", "tgt_sh", "fr_sh", "rz_tgt_sh", "rz_pct_own", "ezpg", "ppg"]),
                  ("RB", ["snap", "car_sh", "rz_car_sh", "i5_sh", "tgt_sh", "wo", "ppg"])]:
    x = j[j.pos == pos]
    for c in cols:
        y = x[list(dict.fromkeys([c, c + "_n", "moved", "ppg_n"]))].dropna()
        print(f"| {c} | {pos} | {len(y)} | {y[c].corr(y[c+'_n']):.2f} | {y[~y.moved][c].corr(y[~y.moved][c+'_n']):.2f} | {y[y.moved][c].corr(y[y.moved][c+'_n']):.2f} | {y[c].corr(y.ppg_n):.2f} |")
# PFF 2012-style red-zone share-of-own-targets regression (40+ catches, as in the original)
print("\n### Share of a receiver's own targets that came in the red zone, next season (WR+TE, 40+ catches in season N, 8+ games both)")
r = j[j.pos.isin(["WR", "TE"])].copy()
rec = S.load().groupby(["player_id", "season"]).receptions.sum().rename("rec").reset_index()
r = r.merge(rec, on=["player_id", "season"]); r = r[r.rec >= 40]
print(f"Sample {len(r)} pairs; mean {r.rz_pct_own.mean():.1%}; median {r.rz_pct_own.median():.1%}")
print("| Season-N band | Pairs | Median next season | Share that fell | Share that rose |\n|---|---|---|---|---|")
for lo, hi, lab in [(.19, 1, "19%+"), (.15, .19, "15-19%"), (.10, .15, "10-15%"), (.075, .10, "7.5-10%"), (0, .075, "under 7.5%")]:
    y = r[(r.rz_pct_own >= lo) & (r.rz_pct_own < hi)]
    print(f"| {lab} | {len(y)} | {y.rz_pct_own_n.median():.1%} | {(y.rz_pct_own_n < y.rz_pct_own).mean():.0%} | {(y.rz_pct_own_n > y.rz_pct_own).mean():.0%} |")
# refit weighted-opportunity weights for full PPR on this sample (RB seasons)
x = s[s.pos == "RB"].copy()
X = np.column_stack([x.rz_car / x.g, x.rz_tgt / x.g, (x.car - x.rz_car) / x.g, (x.tgt - x.rz_tgt) / x.g])
b = np.linalg.lstsq(X, x.ppg, rcond=None)[0]; pred = X @ b
print(f"\nRB full-PPR weights refit 2018-2025 (no intercept): rz carry {b[0]:.2f}, rz target {b[1]:.2f}, other carry {b[2]:.2f}, other target {b[3]:.2f}; "
      f"r = {np.corrcoef(pred, x.ppg)[0,1]:.3f} vs PFF-weight r = {x.wo.corr(x.ppg):.3f}")
for pos in ["WR", "TE"]:
    x = s[s.pos == pos]; print(f"{pos}: corr PPR/g with target share {x.tgt_sh.corr(x.ppg):.2f}, with weighted opp {x.wo.corr(x.ppg):.2f}")
