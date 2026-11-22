"""Total-effect and draft-slot study (owner request Nov 21): NO draft-capital control.
Part A: BMI (and weight, height) alone vs production, first 3 NFL seasons, drafted RBs 2011-2023 with combine BMI (n=233).
Part B: BMI -> ln(pick) and the path decomposition BMI -> pick -> production, bootstrap CIs.
Usage: python3 -I path_total.py <dur_base.csv> <bmi_base.csv>
"""
import sys, numpy as np, pandas as pd, statsmodels.api as sm
from scipy import stats
rng = np.random.default_rng(31)
d = pd.read_csv(sys.argv[1]); d = d[(d.horizon == 3) & d.bmi.notna()].copy()
b = pd.read_csv(sys.argv[2])[["gsis", "solid", "elite", "forty", "speed_score", "vertical", "broad_jump", "cone", "shuttle", "bench"]]
d = d.merge(b, on="gsis", how="left")
MED = 30.26; IQR = 31.19 - 29.27
d["bc"] = d.bmi - MED; d["sq"] = np.sqrt(d.ppr.clip(lower=0))
print("n =", len(d), "| BMI sd %.2f, IQR %.2f" % (d.bmi.std(), IQR))

print("\n=== PART A: BMI alone (no pick control), per +1 BMI point ===")
def ols(y, x="bc", data=d):
    m = sm.OLS(data[y], sm.add_constant(data[[x]])).fit(cov_type="HC3"); ci = m.conf_int().loc[x]
    rho, rp = stats.spearmanr(data[x], data[y])
    return m.params[x], ci[0], ci[1], m.pvalues[x], rho, rp
rows = {}
for lab, y in [("PPR points, 3 seasons", "ppr"), ("sqrt PPR", "sq"), ("games share", "gshare"), ("Out-week share", "outshare"), ("solid (LPM)", "solid"), ("elite (LPM)", "elite")]:
    rows[lab] = ols(y)
print(pd.DataFrame(rows, index=["coef", "lo", "hi", "p", "spearman", "sp_p"]).T.round(3).to_string())
for lab, y in [("solid", "solid"), ("elite", "elite")]:
    m = sm.Logit(d[y], sm.add_constant(d[["bc"]])).fit(disp=0); ci = np.exp(m.conf_int().loc["bc"])
    print(f"logit {lab}: OR per BMI pt {np.exp(m.params['bc']):.2f} (95% CI {ci[0]:.2f}-{ci[1]:.2f}), p={m.pvalues['bc']:.3f}")
d["wc"] = d.wt - d.wt.median(); d["hc"] = d.ht_in - d.ht_in.median()
for v in ["wc", "hc"]:
    r = {lab: ols(y, v) for lab, y in [("PPR", "ppr"), ("games share", "gshare"), ("solid", "solid"), ("elite", "elite")]}
    print(f"\n{v} alone:"); print(pd.DataFrame(r, index=["coef", "lo", "hi", "p", "spearman", "sp_p"]).T.round(3).to_string())

print("\n=== Band means (no pick control) ===")
d["band"] = pd.cut(d.bmi, [0, 28.5, 29.5, 30.5, 31.5, 99], labels=["<28.5", "28.5-29.49", "29.5-30.49", "30.5-31.49", ">=31.5"], right=False)
g = d.groupby("band", observed=True).agg(n=("ppr", "size"), median_pick=("pick", "median"), pct_rd1_2=("rnd", lambda s: (s <= 2).mean() * 100),
    solid=("solid", "mean"), elite=("elite", "mean"), ppr_mean=("ppr", "mean"), ppr_median=("ppr", "median"), games=("gshare", "mean"))
print(g.round(2).to_string())

print("\n=== PART B: does BMI predict where RBs are drafted? ===")
d["lp"] = np.log(d.pick)
for v, lab in [("bc", "BMI"), ("wc", "weight"), ("hc", "height")]:
    m = sm.OLS(d.lp, sm.add_constant(d[[v]])).fit(cov_type="HC3"); ci = m.conf_int().loc[v]
    rho, rp = stats.spearmanr(d[v], d.lp)
    print(f"ln(pick) ~ {lab}: coef {m.params[v]:+.3f} (95% CI {ci[0]:+.3f} to {ci[1]:+.3f}), p={m.pvalues[v]:.3f}, R2={sm.OLS(d.lp, sm.add_constant(d[[v]])).fit().rsquared:.3f}, spearman {rho:+.2f}")
m = sm.OLS(d.lp, sm.add_constant(d[["bc"]])).fit(); a = m.params["bc"]
print(f"  a-path: +1 BMI moves ln(pick) {a:+.3f} => a pick-50 RB becomes pick {50*np.exp(a):.0f}; +IQR (1.92) => pick {50*np.exp(a*IQR):.0f}")

print("\n=== PATH DECOMPOSITION (OLS, bootstrap 4000): total = direct + indirect-through-pick ===")
def decomp(df, y):
    X1 = sm.add_constant(df[["bc"]]); c = sm.OLS(df[y], X1).fit().params["bc"]
    X2 = sm.add_constant(df[["lp", "bc"]]); mm = sm.OLS(df[y], X2).fit(); cp = mm.params["bc"]; bpath = mm.params["lp"]
    a_ = sm.OLS(df.lp, X1).fit().params["bc"]
    return c, cp, a_ * bpath
for y in ["ppr", "sq", "solid", "elite", "gshare"]:
    c, cp, ind = decomp(d, y)
    bs = []
    for _ in range(4000):
        s = d.sample(len(d), replace=True, random_state=int(rng.integers(1e9)))
        bs.append(decomp(s, y))
    bs = np.array(bs); lo = np.percentile(bs, 2.5, axis=0); hi = np.percentile(bs, 97.5, axis=0)
    print(f"{y:7s} total {c:+.4f} [{lo[0]:+.4f},{hi[0]:+.4f}] | direct {cp:+.4f} [{lo[1]:+.4f},{hi[1]:+.4f}] | via pick {ind:+.4f} [{lo[2]:+.4f},{hi[2]:+.4f}]")

print("\n=== BMI effect WITHIN draft tiers, pick not otherwise controlled (means) ===")
d["tier"] = pd.cut(d.pick, [0, 40, 100, 400], labels=["picks 1-40", "41-100", "101+"])
d["bmi_grp"] = np.where(d.bmi < 29.5, "BMI<29.5", np.where(d.bmi < 31.0, "29.5-30.99", "BMI>=31"))
t = d.groupby(["tier", "bmi_grp"], observed=True).agg(n=("ppr", "size"), ppr_mean=("ppr", "mean"), ppr_median=("ppr", "median"), solid=("solid", "mean"), elite=("elite", "mean"), med_pick=("pick", "median"))
print(t.round(2).to_string())
d.to_csv("/home/claude/work/out/path_base.csv", index=False)
