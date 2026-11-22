"""Durability/points study step 2. Every test adds BMI (centered at the sample median 30.26) to ln(pick).
PRIMARY (declared before running, first 3 seasons, all drafted RBs 2011-2023 with BMI): P1 games share, P2 Out-week share, P3 total PPR points.
Everything else is EXPLORATORY. Effects: OLS with HC3 robust SE; Spearman partial correlation (rank residuals after ln(pick)).
Usage: python3 -I dur_tests.py <dur_base.csv>
"""
import sys, numpy as np, pandas as pd, statsmodels.api as sm
from scipy import stats
d0 = pd.read_csv(sys.argv[1])
MED = 30.26; IQR = 31.19 - 29.27

def fit(d, y, x="bmi", ctrl=("logpick",), center=None):
    d = d.dropna(subset=[y, x, *ctrl]).copy()
    d["x_c"] = d[x] - (MED if center is None else center)
    X = sm.add_constant(d[[*ctrl, "x_c"]]); m = sm.OLS(d[y], X).fit(cov_type="HC3")
    ci = m.conf_int().loc["x_c"]
    # spearman partial
    ry = stats.rankdata(d[y]); rx = stats.rankdata(d.x_c)
    Z = sm.add_constant(np.column_stack([stats.rankdata(d[c]) for c in ctrl]))
    ey = sm.OLS(ry, Z).fit().resid; ex = sm.OLS(rx, Z).fit().resid
    rho, rp = stats.pearsonr(ey, ex)
    return dict(n=len(d), coef=m.params["x_c"], lo=ci[0], hi=ci[1], p=m.pvalues["x_c"], rho=rho, rho_p=rp, mean_y=d[y].mean())

def show(title, rows):
    print("\n" + title)
    t = pd.DataFrame(rows).T
    print(t.round(3).to_string())

d3 = d0[(d0.horizon == 3) & d0.bmi.notna()].copy()
d3["miss_share_act"] = np.where(d3.av_act > 0, d3.miss_act / d3.av_act, np.nan)
d3["games_pg"] = d3.games  # games over 3 seasons (max 49-51)
print("N first-3-season RBs with BMI:", len(d3))

prim = {"P1 games share": fit(d3, "gshare"), "P2 Out-week share": fit(d3, "outshare"), "P3 PPR points (3 seasons)": fit(d3, "ppr")}
show("=== PRIMARY (per +1 BMI point, controlling ln(pick)) ===", prim)
print("  per IQR (+1.92 BMI): games share %+.3f (= %+.1f games of ~%d); Out share %+.4f; PPR %+.0f points" % (
    prim["P1 games share"]["coef"]*IQR, prim["P1 games share"]["coef"]*IQR*d3.avail.mean(), d3.avail.mean(), prim["P2 Out-week share"]["coef"]*IQR, prim["P3 PPR points (3 seasons)"]["coef"]*IQR))

d3["sqrt_ppr"] = np.sqrt(d3.ppr.clip(lower=0)); d3["log_ppr"] = np.log1p(d3.ppr.clip(lower=0))
expl = {
 "games share, missed-while-rostered share": fit(d3, "miss_share_act"),
 "PPR points, sqrt": fit(d3, "sqrt_ppr"),
 "PPR points, log1p": fit(d3, "log_ppr"),
 "PPR per game played (games>=8)": fit(d3[d3.games >= 8], "ppg"),
 "best-season PPR": fit(d3.assign(best=d3.ppr), "best"),
}
show("=== EXPLORATORY: other outcome forms ===", expl)

# subsets: roster-secure RBs (picked in top 100) and NFL rounds 1-4
for lab, sub in [("picks 1-100", d3[d3.pick <= 100]), ("NFL rounds 1-2", d3[d3.rnd <= 2]), ("picks 101+", d3[d3.pick > 100])]:
    show(f"=== EXPLORATORY subset: {lab} ===", {"games share": fit(sub, "gshare"), "Out share": fit(sub, "outshare"), "missed-while-rostered": fit(sub.assign(m=sub.miss_share_act), "m"), "PPR 3 seasons": fit(sub, "ppr")})

# weight and height separately
for v, c in [("wt", d3.wt.median()), ("ht_in", d3.ht_in.median())]:
    show(f"=== EXPLORATORY: {v} instead of BMI (centered {c}) ===", {"games share": fit(d3, "gshare", x=v, center=c), "Out share": fit(d3, "outshare", x=v, center=c), "PPR 3 seasons": fit(d3, "ppr", x=v, center=c)})

# 5-season window
d5 = d0[(d0.horizon == 5) & d0.bmi.notna()].copy()
d5["miss_share_act"] = np.where(d5.av_act > 0, d5.miss_act / d5.av_act, np.nan)
show("=== ROBUSTNESS: first 5 seasons (classes 2011-2021) ===", {"games share": fit(d5, "gshare"), "Out share": fit(d5, "outshare"), "PPR 5 seasons": fit(d5, "ppr")})

# interaction and nonlinearity
for y in ["gshare", "outshare", "ppr"]:
    dd = d3.copy(); dd["b"] = dd.bmi - MED; dd["b2"] = dd.b ** 2; dd["bxp"] = dd.b * (dd.logpick - dd.logpick.mean())
    m1 = sm.OLS(dd[y], sm.add_constant(dd[["logpick", "b"]])).fit()
    m2 = sm.OLS(dd[y], sm.add_constant(dd[["logpick", "b", "b2"]])).fit()
    m3 = sm.OLS(dd[y], sm.add_constant(dd[["logpick", "b", "bxp"]])).fit()
    print(f"{y}: quadratic term p={m2.pvalues['b2']:.2f} | BMI x ln(pick) interaction p={m3.pvalues['bxp']:.2f}")

# bands: observed vs expected given pick (games share, Out share, PPR)
d3["band"] = pd.cut(d3.bmi, [0, 28.5, 29.5, 30.5, 31.5, 99], labels=["<28.5", "28.5-29.49", "29.5-30.49", "30.5-31.49", ">=31.5"], right=False)
rows = {}
for y in ["gshare", "outshare", "ppr"]:
    m = sm.OLS(d3[y], sm.add_constant(d3[["logpick"]])).fit(); d3["e_" + y] = m.predict(sm.add_constant(d3[["logpick"]]))
g = d3.groupby("band", observed=True).agg(n=("gshare", "size"), games_obs=("gshare", "mean"), games_exp=("e_gshare", "mean"),
      out_obs=("outshare", "mean"), out_exp=("e_outshare", "mean"), ppr_obs=("ppr", "mean"), ppr_exp=("e_ppr", "mean"))
print("\n=== Bands: observed mean vs expected given pick ==="); print(g.round(3).to_string())
