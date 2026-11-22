"""BMI-band study step 2. Bands by BMI x NFL round group, plus observed-vs-expected given the pick.
Solid = top-24 PPR RB season, elite = top-12, both within first three NFL seasons (study's outcomes.py).
Expected = predicted probability from a logistic on ln(pick) alone, fitted on all 283 RBs (same base model as brief section 8).
Usage: python3 -I bmi_bands.py <bmi_base.csv>
"""
import sys, numpy as np, pandas as pd, statsmodels.api as sm
from scipy import stats
d = pd.read_csv(sys.argv[1])
base = d.copy()
# pick-only expected probabilities, fitted on ALL 283 (not just those with BMI)
for y in ["solid", "elite"]:
    X = sm.add_constant(base[["logpick"]]); f = sm.Logit(base[y], X).fit(disp=0)
    base["exp_" + y] = f.predict(X)
d = base[base.bmi.notna()].copy()
print("n with BMI:", len(d), "| solid", int(d.solid.sum()), "| elite", int(d.elite.sum()))

bins = [0, 28.5, 29.5, 30.5, 31.5, 99]
labs = ["<28.5", "28.5-29.49", "29.5-30.49", "30.5-31.49", ">=31.5"]
d["band"] = pd.cut(d.bmi, bins=bins, labels=labs, right=False)
d["rg"] = pd.cut(d.rnd, [0, 2, 4, 7], labels=["NFL rd 1-2", "NFL rd 3-4", "NFL rd 5-7"])

def line(g):
    n = len(g)
    return pd.Series(dict(n=n, solid=int(g.solid.sum()), elite=int(g.elite.sum()),
        solid_exp=round(g.exp_solid.sum(), 1), elite_exp=round(g.exp_elite.sum(), 1),
        med_pick=int(g.pick.median())))
print("\n=== All rounds: by BMI band (observed vs expected given pick) ===")
print(d.groupby("band", observed=True).apply(line).to_string())
print("\n=== By NFL round group x band ===")
print(d.groupby(["rg", "band"], observed=True).apply(line).to_string())
# coarse: light (<29.5) vs rest, by round group
d["light"] = np.where(d.bmi < 29.5, "BMI<29.5", "BMI>=29.5")
print("\n=== Light (<29.5) vs rest, by NFL round group ===")
print(d.groupby(["rg", "light"], observed=True).apply(line).to_string())
print("\n=== Light vs rest, all rounds ===")
print(d.groupby("light").apply(line).to_string())

print("\n=== Tests (all with BMI; add BMI terms to ln(pick)) ===")
for y in ["solid", "elite"]:
    X0 = sm.add_constant(d[["logpick"]]); m0 = sm.Logit(d[y], X0).fit(disp=0)
    d["bmi_c"] = d.bmi - 30.26
    X1 = sm.add_constant(d[["logpick", "bmi_c"]]); m1 = sm.Logit(d[y], X1).fit(disp=0)
    d["bmi_c2"] = d.bmi_c ** 2
    X2 = sm.add_constant(d[["logpick", "bmi_c", "bmi_c2"]]); m2 = sm.Logit(d[y], X2).fit(disp=0)
    dl = pd.get_dummies(d.band, drop_first=True).astype(float)
    X3 = sm.add_constant(pd.concat([d[["logpick"]], dl], axis=1)); m3 = sm.Logit(d[y], X3).fit(disp=0)
    print(f"{y}: linear BMI coef {m1.params['bmi_c']:+.3f}/pt (OR {np.exp(m1.params['bmi_c']):.2f}), LR p={stats.chi2.sf(2*(m1.llf-m0.llf),1):.3f}"
          f" | +quadratic p={stats.chi2.sf(2*(m2.llf-m1.llf),1):.3f} | 5-band dummies vs pick-only p={stats.chi2.sf(2*(m3.llf-m0.llf),4):.3f}")
    # weight alone and height alone for context
    for v in ["wt", "ht_in"]:
        dd = d.dropna(subset=[v]); Xa = sm.add_constant(dd[["logpick"]]); ma = sm.Logit(dd[y], Xa).fit(disp=0)
        dd = dd.assign(vc=dd[v] - dd[v].median()); Xb = sm.add_constant(dd[["logpick", "vc"]]); mb = sm.Logit(dd[y], Xb).fit(disp=0)
        print(f"   {v}: coef {mb.params['vc']:+.3f}, LR p={stats.chi2.sf(2*(mb.llf-ma.llf),1):.3f}")
d.to_csv("/home/claude/work/out/bmi_banded.csv", index=False)
