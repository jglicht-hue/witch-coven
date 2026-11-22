"""Durability/points study step 1: per-RB outcomes over his first 3 NFL seasons (draft year, +1, +2) and first 5 (classes 2011-2021).
Inputs: bmi_base.csv (study outcomes + nflverse combine BMI), nflverse stats_player_reg_<yr>.csv (season rows), injuries_<yr>.csv.
games = games played (stats_player_reg 'games'); avail = team games (16 through 2020, 17 from 2021).
out_wks = weeks listed report_status == 'Out' on the weekly injury report (REG). Caveat: IR players may drop off the report.
Usage: python3 -I dur_build.py <nfl_dir> <bmi_base.csv> <out.csv>
"""
import sys, numpy as np, pandas as pd
D, B, OUT = sys.argv[1:4]
b = pd.read_csv(B)
st = pd.concat([pd.read_csv(f"{D}/stats_player_reg_{y}.csv", low_memory=False) for y in range(2011, 2026)])
st = st.groupby(["player_id", "season"], as_index=False).agg(games=("games", "sum"), ppr=("fantasy_points_ppr", "sum"),
        car=("carries", "sum"), rec=("receptions", "sum"), tgt=("targets", "sum"), ypos=("position", "first"))
inj = pd.concat([pd.read_csv(f"{D}/injuries_{y}.csv", low_memory=False) for y in range(2011, 2026)])
inj = inj[inj.game_type == "REG"]
print("report_status values:", inj.report_status.value_counts(dropna=False).to_dict())
out = inj[inj.report_status == "Out"].groupby(["gsis_id", "season"]).week.nunique().rename("out_wks").reset_index()
anyrep = inj.groupby(["gsis_id", "season"]).week.nunique().rename("rep_wks").reset_index()
tg = lambda s: 16 if s <= 2020 else 17
rows = []
for _, r in b.iterrows():
    g = r.gsis
    for horizon in (3, 5):
        seasons = [r.cls + i for i in range(horizon)]
        if max(seasons) > 2025: continue
        gp = pp = out_w = av_all = av_act = miss_act = car = rec = 0
        n_act = 0
        for s in seasons:
            x = st[(st.player_id == g) & (st.season == s)]
            games = float(x.games.sum()) if len(x) else 0.0
            ppr = float(x.ppr.sum()) if len(x) else 0.0
            o = out[(out.gsis_id == g) & (out.season == s)].out_wks.sum()
            rp = anyrep[(anyrep.gsis_id == g) & (anyrep.season == s)].rep_wks.sum()
            av = tg(s); av_all += av
            gp += games; pp += ppr; out_w += o
            car += float(x.car.sum()) if len(x) else 0; rec += float(x.rec.sum()) if len(x) else 0
            if games > 0 or rp > 0:   # season in which he was on a roster / report
                av_act += av; miss_act += max(av - games, 0); n_act += 1
        rows.append(dict(name=r["name"], cls=r.cls, rnd=r.rnd, pick=r.pick, gsis=g, bmi=r.bmi, wt=r.wt, ht_in=r.ht_in,
                         horizon=horizon, games=gp, avail=av_all, out_wks=out_w, ppr=pp, car=car, rec=rec,
                         av_act=av_act, miss_act=miss_act, n_act=n_act))
d = pd.DataFrame(rows)
d["gshare"] = d.games / d.avail
d["outshare"] = d.out_wks / d.avail
d["ppg"] = np.where(d.games > 0, d.ppr / d.games.replace(0, np.nan), np.nan)
d["logpick"] = np.log(d.pick)
d.to_csv(OUT, index=False)
for h in (3, 5):
    x = d[d.horizon == h]
    print(f"horizon {h}: RBs {len(x)}, with BMI {int(x.bmi.notna().sum())}, mean games share {x.gshare.mean():.3f}, mean out share {x.outshare.mean():.3f}, median ppr {x.ppr.median():.0f}")
print(d[d.horizon == 3].groupby(pd.cut(d[d.horizon == 3].rnd, [0, 2, 4, 7])).agg(n=("gshare", "size"), gshare=("gshare", "mean"), outshare=("outshare", "mean"), ppr=("ppr", "median")).round(3).to_string())
