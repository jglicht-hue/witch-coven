"""Nov 22 checks that were first run inline (not saved at the time). Reproduces: cutoff sensitivity for the light-BMI early picks, the top-15 split,
weight/BMI outside the top 15 (with and without ln(pick)), the additive college rec_pg control, and the fine-bin observed-vs-expected tables.
Expected hits/PPR come from a logit/OLS on ln(pick) and ln(pick)^2 fitted on the same sample (so they are in-sample expectations).
NOTE: the additive rec_pg control is NOT an interaction test; the interaction/bucket test is still to do (see HANDOFF).
Usage: python3 -I nov22_checks.py <path_full.csv>
"""
import sys, numpy as np, pandas as pd, statsmodels.api as sm
f = pd.read_csv(sys.argv[1]); d = f[f.bmi.notna()].copy(); d["lp"] = np.log(d.pick); d["lp2"] = d.lp ** 2
print("n drafted", len(f), "| with BMI", len(d), "| BMI<29.5", int((d.bmi < 29.5).sum()), "| BMI<29.5 & pick<=45", int(((d.bmi < 29.5) & (d.pick <= 45)).sum()))
print("\n== cutoff sensitivity (light <29.5, mid 29.5-31, heavy 31+) ==")
for cut in (32, 45, 64, 100, 260):
    for lo, hi, lab in ((0, 29.5, "<29.5"), (29.5, 31, "29.5-31"), (31, 99, ">=31")):
        s = d[(d.pick <= cut) & (d.bmi >= lo) & (d.bmi < hi)]
        print(f"picks<={cut:3d} BMI {lab:8s} n={len(s):3d} med_pick={s.pick.median():5.1f} meanPPR={s.ppr.mean():6.0f} solid={s.solid.mean():.2f} elite={s.elite.mean():.2f}")
print("\n== top 15 picks with BMI ==")
s = d[d.pick <= 15].sort_values("pick"); print(s[["name", "cls", "pick", "bmi", "wt", "ht_in", "ppr", "solid", "elite"]].round(1).to_string(index=False))
print(s.assign(light=s.bmi < 29.5).groupby("light").agg(n=("pick", "size"), med=("pick", "median"), ppr=("ppr", "mean"), solid=("solid", "mean"), elite=("elite", "mean")).round(2))
def fit(df, y, x, ctrl):
    X = sm.add_constant(df[[x] + ctrl])
    if y in ("solid", "elite"):
        m = sm.Logit(df[y], X).fit(disp=0); ci = m.conf_int().loc[x]; return f"OR/unit {np.exp(m.params[x]):.3f} ({np.exp(ci[0]):.3f}-{np.exp(ci[1]):.3f}) p={m.pvalues[x]:.3f}"
    m = sm.OLS(df[y], X).fit(cov_type="HC3"); ci = m.conf_int().loc[x]; return f"{m.params[x]:+.1f} ({ci[0]:+.1f},{ci[1]:+.1f}) p={m.pvalues[x]:.3f}"
print("\n== BMI / weight effects (HC3 for PPR; logit OR for solid/elite) ==")
for lab, df in (("outside top 15", d[d.pick > 15]), ("all", d)):
    for x in ("bmi", "wt"):
        for ctrl, cl in (([], "no pick ctrl"), (["lp"], "ctrl ln(pick)")):
            for y in ("ppr", "solid", "elite"):
                print(f"{lab:15s} {x:3s} {cl:14s} {y:5s} {fit(df, y, x, ctrl)}")
r = d.dropna(subset=["rec_pg"]); print("\n== additive college rec_pg control, n =", len(r), "(NOT an interaction test) ==")
for lab, df in (("outside top15", r[r.pick > 15]), ("all", r)):
    for x in ("bmi", "wt"):
        for y in ("ppr", "solid", "elite"):
            print(f"{lab:14s} {x:3s} ctrl lp+rec_pg {y:5s} {fit(df, y, x, ['lp', 'rec_pg'])}")
print("corr rec_pg with bmi/wt:", r[["rec_pg", "bmi", "wt"]].corr().round(2).iloc[0].to_dict())
def oe(df, col, bins, labels):
    df = df.copy(); df["b"] = pd.cut(df[col], bins, labels=labels, right=False); X = sm.add_constant(df[["lp", "lp2"]])
    ex = {y: sm.Logit(df[y], X).fit(disp=0).predict(X) for y in ("solid", "elite")}; ex["ppr"] = sm.OLS(df.ppr, X).fit().predict(X); rows = []
    for b, g in df.groupby("b", observed=True):
        i = g.index; rows.append((b, len(g), g.pick.median(), g.solid.sum(), ex["solid"][i].sum(), g.elite.sum(), ex["elite"][i].sum(), g.ppr.mean(), ex["ppr"][i].mean()))
    print(pd.DataFrame(rows, columns=[col, "n", "med_pick", "solid", "solid_exp", "elite", "elite_exp", "PPR", "PPR_exp"]).round(1).to_string(index=False))
for lab, df in (("ALL", d), ("OUTSIDE TOP 15", d[d.pick > 15]), ("PICKS 16-100", d[(d.pick > 15) & (d.pick <= 100)])):
    print("\n== observed vs expected given pick:", lab, "n =", len(df), "==")
    oe(df, "bmi", [0, 27.5, 28.5, 29.5, 30.5, 31.5, 99], ["<27.5", "27.5-28.5", "28.5-29.5", "29.5-30.5", "30.5-31.5", "31.5+"])
    oe(df, "wt", [0, 190, 200, 210, 220, 230, 999], ["<190", "190-200", "200-210", "210-220", "220-230", "230+"])
print("\nLowest-BMI RBs:"); print(d.sort_values("bmi").head(14)[["name", "cls", "pick", "bmi", "wt", "ht_in", "ppr", "solid", "elite"]].round(1).to_string(index=False))
