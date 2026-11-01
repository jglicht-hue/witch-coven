"""RB prospect study, step 5: overlap check, one-trait-at-a-time logistic tests against a draft-capital baseline,
effect sizes, interactions, elite-among-hits, and tier tables.
Usage: python3 -I models.py <features_csv> <out_dir>
"""
import sys, warnings, numpy as np, pandas as pd
import statsmodels.api as sm
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import RepeatedStratifiedKFold
from sklearn.metrics import log_loss
warnings.filterwarnings("ignore")
F, OUTD = sys.argv[1:3]
d = pd.read_csv(F)
for t in ["SEC", "B1G", "OP4"]:
    d[f"conf_{t}"] = np.where(d.conf_tier.notna(), (d.conf_tier == t).astype(float), np.nan)
d["conf_P4"] = np.where(d.conf_tier.notna(), d.conf_tier.isin(["SEC", "B1G", "OP4"]).astype(float), np.nan)

L1 = ["wt", "bmi", "bench", "forty", "speed_score", "vertical", "broad_jump", "cone", "shuttle", "age_draft"]
L2 = ["carry_share", "scrim_share", "tgt_share", "rec_pg", "recyd_share", "third_share", "late_share", "in10_share",
      "fum_per_touch", "starter_yrs", "ypc_vs_team", "succ_vs_team", "exp10", "exp20", "career_touches", "conf_P4", "conf_SEC", "conf_B1G"]
SIGN = {"forty": -1, "cone": -1, "shuttle": -1, "fum_per_touch": -1, "age_draft": -1}  # lower is better

def fit(df, y, X):
    m = sm.Logit(df[y], sm.add_constant(df[X])).fit(disp=0, maxiter=200)
    return m

def cv_gain(df, y, base, full, reps=20, seed=7):
    """Mean out-of-sample log-loss improvement (base - full) and share of repeats where full wins."""
    Y = df[y].values; Xb = df[base].values; Xf = df[full].values
    rk = RepeatedStratifiedKFold(n_splits=5, n_repeats=reps, random_state=seed)
    gains = []; per = []
    for i, (tr, te) in enumerate(rk.split(Xf, Y)):
        if Y[tr].sum() < 3: continue
        mu, sd = Xf[tr].mean(0), Xf[tr].std(0) + 1e-9
        b = LogisticRegression(penalty=None, max_iter=1000).fit((Xb[tr] - mu[:Xb.shape[1]]) / sd[:Xb.shape[1]], Y[tr])
        f = LogisticRegression(penalty=None, max_iter=1000).fit((Xf[tr] - mu) / sd, Y[tr])
        pb = np.clip(b.predict_proba((Xb[te] - mu[:Xb.shape[1]]) / sd[:Xb.shape[1]])[:, 1], 1e-4, 1 - 1e-4)
        pf = np.clip(f.predict_proba((Xf[te] - mu) / sd)[:, 1], 1e-4, 1 - 1e-4)
        g = log_loss(Y[te], pb, labels=[0, 1]) - log_loss(Y[te], pf, labels=[0, 1])
        gains.append(g); per.append((i // 5, g))
    rep = pd.DataFrame(per, columns=["r", "g"]).groupby("r").g.mean()
    return float(np.mean(gains)), float((rep > 0).mean())

def effect(m, df, trait, X):
    """Mean predicted probability with trait set to its 75th vs 25th percentile, everything else as observed."""
    lo, hi = df[trait].quantile(.25), df[trait].quantile(.75)
    a = df[X].copy(); b = df[X].copy(); a[trait] = lo; b[trait] = hi
    pa = m.predict(sm.add_constant(a, has_constant="add")).mean(); pb = m.predict(sm.add_constant(b, has_constant="add")).mean()
    return lo, hi, pb - pa

def test(df, y, trait, base=("logpick",), label=""):
    s = df.dropna(subset=[trait, y] + list(base))
    if trait.startswith("conf_"): s = s[s[trait].notna()]
    if s[y].sum() < 8 or len(s) < 40: return None
    X0 = list(base); X1 = X0 + [trait]
    try:
        m0 = fit(s, y, X0); m1 = fit(s, y, X1)
    except Exception as e:
        return dict(layer=label, outcome=y, trait=trait, n=len(s), note=f"fit failed: {e}")
    lr = 2 * (m1.llf - m0.llf); from scipy.stats import chi2; p = chi2.sf(lr, 1)
    g, w = cv_gain(s, y, X0, X1)
    if trait.startswith("conf_"):
        a = s[X1].copy(); b = s[X1].copy(); a[trait] = 0; b[trait] = 1
        lo, hi = 0, 1
        eff = m1.predict(sm.add_constant(b, has_constant="add")).mean() - m1.predict(sm.add_constant(a, has_constant="add")).mean()
    else:
        lo, hi, eff = effect(m1, s, trait, X1)
    return dict(layer=label, outcome=y, trait=trait, n=len(s), hits=int(s[y].sum()), p25=round(lo, 3), p75=round(hi, 3),
                effect_pts=round(eff * 100, 1), coef_sign=int(np.sign(m1.params[trait])), lr_p=round(p, 3),
                cv_gain_x1000=round(g * 1000, 1), cv_win=round(w, 2))

out = {}
# ---- overlap check
allt = L1 + [t for t in L2 if not t.startswith("conf_")] + ["breakout_age", "logpick"]
cor = d[allt].corr(method="spearman")
pairs = [(a, b, round(cor.loc[a, b], 2)) for i, a in enumerate(allt) for b in allt[i + 1:] if abs(cor.loc[a, b]) >= 0.7]
print("== Overlap check: trait pairs with |Spearman r| >= 0.7")
for p in pairs: print("  ", p)
print("  correlation with logpick (draft capital; negative = earlier pick goes with higher trait):")
print("  ", cor["logpick"].drop("logpick").round(2).sort_values().to_dict())

# ---- baseline
for y in ["solid", "elite"]:
    s = d.dropna(subset=[y]); m = fit(s, y, ["logpick"])
    print(f"\n== Baseline {y}: n={len(s)}, hits={int(s[y].sum())}, coef logpick={m.params['logpick']:.2f}, pseudo-R2={m.prsquared:.2f}")
    for pk in [5, 16, 32, 50, 75, 100, 150, 200]:
        print(f"   pick {pk}: {m.predict([[1, np.log(pk)]])[0]*100:.0f}%", end="")
    print()

rows = []
d1 = d
d2 = d[(d.cls >= 2015) & d.col_seasons.notna()]
for y in ["solid", "elite"]:
    for t in L1: rows.append(test(d1, y, t, label="L1 combine (2011-23)"))
    for t in L2: rows.append(test(d2, y, t, label="L2 college (2015-23)"))
    # Layer 3: breakout age vs Layer 2's sample restricted to 2017-23 with breakout data
    d3 = d2[(d2.cls >= 2017)]
    rows.append(test(d3.assign(broke_out=(d3.never_broke_out == 0).astype(float)), y, "broke_out", label="L3 breakout (2017-23)"))
    rows.append(test(d3, y, "breakout_age", label="L3 breakout (2017-23)"))
res = pd.DataFrame([r for r in rows if r])
res.to_csv(f"{OUTD}/trait_tests.csv", index=False)
pd.set_option("display.width", 250)
print("\n== One trait at a time, added to draft capital (effect = pts of probability, 25th->75th pct; cv_gain>0 & cv_win>=0.8 = adds signal out of sample)")
print(res.sort_values(["outcome", "cv_gain_x1000"], ascending=[True, False]).to_string(index=False))

# ---- elite among hits
print("\n== Elite among solid hits (outcome elite, sample = solid==1)")
hits = d[d.solid == 1]
er = []
for t in L1: er.append(test(hits, "elite", t, label="hits L1"))
h2 = hits[(hits.cls >= 2015) & hits.col_seasons.notna()]
print("   hits: L1 n =", len(hits), "elite", int(hits.elite.sum()), "| L2 n =", len(h2), "elite", int(h2.elite.sum()))
for t in L2:
    s = h2.dropna(subset=[t])
    if len(s) >= 30: er.append(test(h2.assign(), "elite", t, label="hits L2"))
er = pd.DataFrame([r for r in er if r]); er.to_csv(f"{OUTD}/elite_among_hits.csv", index=False)
print(er.sort_values("cv_gain_x1000", ascending=False).to_string(index=False))
res.to_pickle(f"{OUTD}/res.pkl")
