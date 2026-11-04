"""Which matchup number predicts DST points best: raw/adjusted x this-season/blended."""
import glob, os
import numpy as np, pandas as pd
BT = os.path.dirname(os.path.abspath(__file__)); CUR = os.path.join(BT, "..", "run14", "chooserboy_data")
rows = []
for d in sorted(glob.glob(os.path.join(BT, "out", "*_*"))):
    y, w = map(int, os.path.basename(d).split("_"))
    b = pd.read_csv(os.path.join(d, "chooserboy_matchup_board.csv")); b = b[(b.weeks_out == 0) & b.base_composite.notna()].copy()
    b["season"] = y; rows.append(b)
df = pd.concat(rows, ignore_index=True)
logs = []
for y in range(2021, 2026):
    src = os.path.join(BT, "out", f"{y+1}_2", "chooserboy_dst_game_log.csv") if y < 2025 else os.path.join(CUR, "chooserboy_dst_game_log.csv")
    g = pd.read_csv(src); logs.append(g[g.season == y][["season", "week", "team", "fpts"]])
df = df.merge(pd.concat(logs).rename(columns={"team": "dst_team"}), on=["season", "week", "dst_team"])
df["raw_season"] = df.opp_sacks_allowed_pg + 2 * df.opp_giveaways_pg
df["adj_season"] = df.opp_sacks_allowed_oe_pg + 2 * df.opp_giveaways_oe_pg
df["raw_blend"] = df.base_matchup_B; df["adj_blend"] = df.base_matchup_B_adj
cands = ["raw_blend", "adj_blend", "raw_season", "adj_season"]
# demean within week so league-wide shifts don't count
for c in cands + ["fpts"]:
    df[c + "_w"] = df[c] - df.groupby(["season", "week"])[c].transform("mean")
unit = (df.base_unit_A + 0.00549) / 0.89183
vegas = (-(df.opp_implied_total - 22.25123) / 3.92319 - df.dst_spread / 6.45428) / 2
def z(s): return (s - s.mean()) / s.std()
for c in cands:
    df["full_" + c] = 0.35 * z(df[c]) + 0.25 * unit + 0.40 * vegas
def h2h(g, col):
    win = n = 0
    for _, wk in g.groupby(["season", "week"]):
        c = wk[col].to_numpy(); f = wk.fpts.to_numpy(); i, j = np.triu_indices(len(c), 1)
        k = (f[i] != f[j]) & (c[i] != c[j]); win += ((c[i] > c[j]) == (f[i] > f[j]))[k].sum(); n += k.sum()
    return win / n
rng = np.random.default_rng(1)
keys = df[["season", "week"]].drop_duplicates().to_numpy()
out = []
for span, m in [("Weeks 2-8", df.week.between(2, 8)), ("Weeks 9-17", df.week.between(9, 17)), ("All", df.week.between(2, 18))]:
    g = df[m]
    for c in cands:
        out.append(dict(span=span, matchup=c, games=len(g),
                        alone_corr=round(g.fpts_w.corr(g[c + "_w"]), 3),
                        alone_h2h=round(h2h(g, c), 3),
                        full_corr=round(g.fpts.corr(g["full_" + c]), 3),
                        full_h2h=round(h2h(g, "full_" + c), 3)))
r = pd.DataFrame(out); print(r.to_string(index=False)); r.to_csv(os.path.join(BT, "predictors_results.csv"), index=False)
# bootstrap: alone corr, adj_season vs raw_blend and adj_blend vs raw_blend
for span, m in [("Weeks 2-8", df.week.between(2, 8)), ("Weeks 9-17", df.week.between(9, 17))]:
    g = df[m]; grp = {k: v for k, v in g.groupby(["season", "week"])}; ks = list(grp)
    wins = {c: 0 for c in cands if c != "raw_blend"}
    for _ in range(1000):
        s = pd.concat([grp[ks[i]] for i in rng.integers(0, len(ks), len(ks))])
        base = s.fpts_w.corr(s.raw_blend_w)
        for c in wins: wins[c] += s.fpts_w.corr(s[c + "_w"]) > base
    print(span, "alone: share of resamples beating raw_blend", {c: f"{v/10:.0f}%" for c, v in wins.items()})
