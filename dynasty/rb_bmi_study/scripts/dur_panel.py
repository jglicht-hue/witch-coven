"""Durability study step 3 (EXPLORATORY): (a) look into the BMI x ln(pick) interaction on PPR points; (b) player-season panel, rostered seasons only,
clustered by player. A rostered season = games>0 or on the REG injury report that season. Outcomes: games/team games, Out weeks/team games.
Controls: ln(pick), years since draft (0..), BMI centered. SE clustered by player. Usage: python3 -I dur_panel.py <nfl_dir> <dur_base.csv>
"""
import sys, numpy as np, pandas as pd, statsmodels.api as sm, statsmodels.formula.api as smf
D, B = sys.argv[1:3]
MED = 30.26
b = pd.read_csv(B); b3 = b[(b.horizon == 3) & b.bmi.notna()].copy()
# (a) interaction, robust
b3["bc"] = b3.bmi - MED; b3["lp"] = b3.logpick - b3.logpick.mean(); b3["sq"] = np.sqrt(b3.ppr.clip(lower=0))
for y in ["ppr", "sq"]:
    m = smf.ols(f"{y} ~ lp + bc + bc:lp", b3).fit(cov_type="HC3")
    print(f"(a) {y}: BMI x ln(pick) coef {m.params['bc:lp']:.3f}, HC3 p={m.pvalues['bc:lp']:.3f}")
b3["tier"] = pd.cut(b3.pick, [0, 40, 100, 400], labels=["picks 1-40", "41-100", "101+"])
for t, g in b3.groupby("tier", observed=True):
    m = smf.ols("ppr ~ lp + bc", g).fit(cov_type="HC3"); ci = m.conf_int().loc["bc"]
    print(f"   {t}: n={len(g)} BMI effect on 3-season PPR {m.params['bc']:+.1f} (95% CI {ci[0]:.1f} to {ci[1]:.1f}), p={m.pvalues['bc']:.2f}")
big = b3.sort_values("ppr", ascending=False).head(6)[["name", "pick", "bmi", "ppr"]]
print("   top-6 PPR outcomes:\n" + big.round(1).to_string(index=False))
# (b) panel
st = pd.concat([pd.read_csv(f"{D}/stats_player_reg_{y}.csv", low_memory=False) for y in range(2011, 2026)])
st = st.groupby(["player_id", "season"], as_index=False).agg(games=("games", "sum"), car=("carries", "sum"), rec=("receptions", "sum"))
inj = pd.concat([pd.read_csv(f"{D}/injuries_{y}.csv", low_memory=False) for y in range(2011, 2026)]); inj = inj[inj.game_type == "REG"]
out = inj[inj.report_status == "Out"].groupby(["gsis_id", "season"]).week.nunique().rename("out_wks").reset_index()
rep = inj.groupby(["gsis_id", "season"]).week.nunique().rename("rep_wks").reset_index()
p = b3[["name", "gsis", "cls", "pick", "bmi", "wt", "ht_in", "logpick"]].drop_duplicates("gsis")
rows = []
for _, r in p.iterrows():
    for s in range(int(r.cls), 2026):
        x = st[(st.player_id == r.gsis) & (st.season == s)]
        g = float(x.games.sum()) if len(x) else 0.0
        o = float(out[(out.gsis_id == r.gsis) & (out.season == s)].out_wks.sum())
        rp = float(rep[(rep.gsis_id == r.gsis) & (rep.season == s)].rep_wks.sum())
        if g > 0 or rp > 0:
            av = 16 if s <= 2020 else 17
            rows.append(dict(gsis=r.gsis, name=r["name"], season=s, yrs=s - int(r.cls), pick=r.pick, logpick=r.logpick, bmi=r.bmi, wt=r.wt, ht_in=r.ht_in,
                             gshare=g / av, outshare=o / av, touches=(float(x.car.sum()) + float(x.rec.sum())) if len(x) else 0.0))
pn = pd.DataFrame(rows); pn["bc"] = pn.bmi - MED; pn["wc"] = pn.wt - 213
print(f"\n(b) panel: {len(pn)} rostered RB-seasons, {pn.gsis.nunique()} RBs, mean games share {pn.gshare.mean():.3f}, mean Out share {pn.outshare.mean():.3f}")
for y in ["gshare", "outshare"]:
    for xv in ["bc", "wc"]:
        m = smf.ols(f"{y} ~ logpick + yrs + {xv}", pn).fit(cov_type="cluster", cov_kwds={"groups": pn.gsis})
        ci = m.conf_int().loc[xv]
        print(f"   {y} ~ {xv}: coef {m.params[xv]:+.4f} (95% CI {ci[0]:+.4f} to {ci[1]:+.4f}), p={m.pvalues[xv]:.2f}")
# established seasons: >=100 touches the PRIOR season (exposure not conditioned on this season's health)
pn = pn.sort_values(["gsis", "season"]); pn["prev_touch"] = pn.groupby("gsis").touches.shift(1)
est = pn[(pn.prev_touch >= 100)]
print(f"\n   established (>=100 touches prior season): {len(est)} RB-seasons, {est.gsis.nunique()} RBs")
for y in ["gshare", "outshare"]:
    m = smf.ols(f"{y} ~ logpick + yrs + bc + prev_touch", est).fit(cov_type="cluster", cov_kwds={"groups": est.gsis}); ci = m.conf_int().loc["bc"]
    print(f"   {y} ~ BMI | pick, years, prior touches: coef {m.params['bc']:+.4f} (95% CI {ci[0]:+.4f} to {ci[1]:+.4f}), p={m.pvalues['bc']:.2f}")
est = est.assign(hi=(est.bmi >= 31.0))
print(est.groupby("hi").agg(n=("gshare", "size"), games=("gshare", "mean"), out=("outshare", "mean")).round(3).to_string())
