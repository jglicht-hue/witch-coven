"""RB prospect study, step 1: outcomes.
Solid = a top-24 RB season (full-PPR total, regular season); elite = top-12.
Window = the RB's first three NFL seasons (draft year, +1, +2). Also flags hits in years 1-2.
Classes 2011-2023. Data: nflverse draft_picks, stats_player_reg_<year>, players.
Usage: python3 -I outcomes.py <nfl_data_dir> <out_csv>
"""
import sys, pandas as pd

D, OUT = sys.argv[1], sys.argv[2]
draft = pd.read_csv(f"{D}/draft.csv")
rb = draft[(draft.position == "RB") & draft.season.between(2011, 2023)].copy()

# season ranks among RBs, 2011-2025
ranks = []
for y in range(2011, 2026):
    s = pd.read_csv(f"{D}/stats_player_reg_{y}.csv", low_memory=False)
    s = s[s.position == "RB"][["player_id", "season", "fantasy_points_ppr", "games"]].copy()
    s["rk"] = s.fantasy_points_ppr.rank(ascending=False, method="min")
    ranks.append(s)
ranks = pd.concat(ranks)

def best(gid, first, n):
    r = ranks[(ranks.player_id == gid) & ranks.season.between(first, first + n - 1)]
    return r.rk.min() if len(r) else None

rows = []
for _, p in rb.iterrows():
    gid, y = p.gsis_id, int(p.season)
    b3 = best(gid, y, 3) if pd.notna(gid) else None
    b2 = best(gid, y, 2) if pd.notna(gid) else None
    ball = ranks[ranks.player_id == gid].rk.min() if pd.notna(gid) else None
    rows.append(dict(name=p.pfr_player_name, cls=y, rnd=int(p["round"]), pick=int(p.pick),
                     gsis=gid, pfr=p.pfr_player_id, college=p.college, age_draft=p.age,
                     best3=b3, solid=int(b3 is not None and b3 <= 24), elite=int(b3 is not None and b3 <= 12),
                     solid_y12=int(b2 is not None and b2 <= 24), elite_y12=int(b2 is not None and b2 <= 12),
                     solid_ever=int(pd.notna(ball) and ball <= 24)))
o = pd.DataFrame(rows)
o.to_csv(OUT, index=False)
print("RBs:", len(o), "| missing gsis:", int(o.gsis.isna().sum()))
print("\nSanity check vs brief section 5 (2011-2021, ever top-24):")
c = o[o.cls <= 2021].groupby("rnd").solid_ever.agg(["sum", "count"])
print(c.to_string())
print("\nStudy outcome by NFL round, 2011-2023 (first three seasons):")
t = o.groupby("rnd").agg(n=("solid", "size"), solid=("solid", "sum"), elite=("elite", "sum"),
                         solid_y12=("solid_y12", "sum"), elite_y12=("elite_y12", "sum"))
t["solid%"] = (t.solid / t.n * 100).round(0); t["elite%"] = (t.elite / t.n * 100).round(0)
print(t.to_string()); print("totals:", t[["n", "solid", "elite", "solid_y12", "elite_y12"]].sum().to_dict())
