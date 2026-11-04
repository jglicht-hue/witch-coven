"""Raw vs adjusted matchup (B) in base_score, split by part of season.

Inputs: replays out/<season>_<week>/ made by replay.R (v1.4 with AS_OF_WEEK),
actual DST points from the following season's replay (prior-season rows), or the
current-season run for 2025.
"""
import glob, os, sys
import numpy as np, pandas as pd

BT = os.path.dirname(os.path.abspath(__file__))
CUR = os.path.join(BT, "..", "run14", "chooserboy_data")

rows = []
for d in sorted(glob.glob(os.path.join(BT, "out", "*_*"))):
    y, w = map(int, os.path.basename(d).split("_"))
    b = pd.read_csv(os.path.join(d, "chooserboy_matchup_board.csv"))
    b = b[(b.weeks_out == 0) & b.base_composite.notna()].copy()
    b["season"] = y
    rows.append(b)
board = pd.concat(rows, ignore_index=True)

logs = []
for y in range(2021, 2026):
    src = os.path.join(BT, "out", f"{y+1}_2", "chooserboy_dst_game_log.csv") if y < 2025 \
        else os.path.join(CUR, "chooserboy_dst_game_log.csv")
    g = pd.read_csv(src)
    logs.append(g[g.season == y][["season", "week", "team", "fpts"]])
act = pd.concat(logs).rename(columns={"team": "dst_team"})
df = board.merge(act, on=["season", "week", "dst_team"], how="inner")
print(f"DST-games: {len(df)} (board rows {len(board)})")

# script constants (the backtested ones)
W = dict(m=0.35, u=0.25, v=0.40)
Bm, Bs, Am, As = -0.00022, 0.86016, -0.00549, 0.89183
im, isd, ssd = 22.25123, 3.92319, 6.45428
vegas = (-(df.opp_implied_total - im) / isd - df.dst_spread / ssd) / 2
unit = (df.base_unit_A - Am) / As
z_raw = (df.base_matchup_B - Bm) / Bs
z_adj = (df.base_matchup_B_adj - df.base_matchup_B_adj.mean()) / df.base_matchup_B_adj.std()
df["c_raw"] = W["m"] * z_raw + W["u"] * unit + W["v"] * vegas
df["c_adj"] = W["m"] * z_adj + W["u"] * unit + W["v"] * vegas
chk = (df.c_raw - df.base_composite).abs().max()
print(f"rebuilt raw composite vs script: max diff {chk:.4f}")
print(f"corr raw B vs adjusted B: {df.base_matchup_B.corr(df.base_matchup_B_adj):.3f}")


def h2h(g, col):
    """share of same-week pairs (fpts not tied) where higher composite scored more"""
    win = n = 0
    for _, wk in g.groupby(["season", "week"]):
        c = wk[col].to_numpy(); f = wk.fpts.to_numpy()
        i, j = np.triu_indices(len(c), 1)
        keep = (f[i] != f[j]) & (c[i] != c[j])
        win += ((c[i] > c[j]) == (f[i] > f[j]))[keep].sum(); n += keep.sum()
    return win / n, n


def flips(g):
    win = n = 0
    for _, wk in g.groupby(["season", "week"]):
        r = wk.c_raw.to_numpy(); a = wk.c_adj.to_numpy(); f = wk.fpts.to_numpy()
        i, j = np.triu_indices(len(r), 1)
        fl = ((r[i] > r[j]) != (a[i] > a[j])) & (f[i] != f[j])
        win += ((a[i] > a[j]) == (f[i] > f[j]))[fl].sum(); n += fl.sum()
    return win, n


rng = np.random.default_rng(1)
def boot_corr_gain(g, reps=2000):
    keys = g[["season", "week"]].drop_duplicates().to_numpy()
    groups = {tuple(k): gg for k, gg in g.groupby(["season", "week"])}
    better = 0
    for _ in range(reps):
        s = pd.concat([groups[tuple(k)] for k in keys[rng.integers(0, len(keys), len(keys))]])
        better += s.fpts.corr(s.c_adj) > s.fpts.corr(s.c_raw)
    return better / reps


out = []
for name, mask in [("All weeks 2-18", df.week.between(2, 18)),
                   ("Weeks 2-8", df.week.between(2, 8)),
                   ("Weeks 9-17", df.week.between(9, 17)),
                   ("Weeks 12-17", df.week.between(12, 17))]:
    g = df[mask]
    hr, n = h2h(g, "c_raw"); ha, _ = h2h(g, "c_adj"); fw, fn = flips(g)
    out.append(dict(span=name, games=len(g),
                    track_raw=round(g.fpts.corr(g.c_raw), 3), track_adj=round(g.fpts.corr(g.c_adj), 3),
                    adj_better_in=f"{boot_corr_gain(g):.0%}",
                    h2h_raw=f"{hr:.1%}", h2h_adj=f"{ha:.1%}",
                    flipped_pairs=fn, flip_share=f"{fn/n:.1%}", adj_pick_wins=f"{fw/fn:.1%}" if fn else "-",
                    corr_B=round(g.base_matchup_B.corr(g.base_matchup_B_adj), 3)))
res = pd.DataFrame(out)
pd.set_option("display.width", 200)
print(res.to_string(index=False))
res.to_csv(os.path.join(BT, "raw_vs_adjusted_results.csv"), index=False)
