"""RB prospect study, step 6: receiving composite, multi-trait check, named interactions, Layer 3 vs Layer 2 model,
tier tables with pre-set median cutoffs, and the 'top-16' check.
Usage: python3 -I models2.py <features_csv>
"""
import sys, warnings, numpy as np, pandas as pd, statsmodels.api as sm
from scipy.stats import chi2
warnings.filterwarnings("ignore")
F = sys.argv[1]
d = pd.read_csv(F)
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import RepeatedStratifiedKFold
from sklearn.metrics import log_loss

def fit(s, y, X): return sm.Logit(s[y], sm.add_constant(s[X])).fit(disp=0, maxiter=200)
def cv(s, y, Xb, Xf, reps=20):
    Y = s[y].values; rk = RepeatedStratifiedKFold(n_splits=5, n_repeats=reps, random_state=7); g = []
    for tr, te in rk.split(s, Y):
        def pr(X):
            A = s[X].values; mu, sd = A[tr].mean(0), A[tr].std(0) + 1e-9
            m = LogisticRegression(penalty=None, max_iter=2000).fit((A[tr] - mu) / sd, Y[tr])
            return np.clip(m.predict_proba((A[te] - mu) / sd)[:, 1], 1e-4, 1 - 1e-4)
        g.append(log_loss(Y[te], pr(Xb), labels=[0, 1]) - log_loss(Y[te], pr(Xf), labels=[0, 1]))
    g = np.array(g).reshape(reps, 5).mean(1)
    return round(g.mean() * 1000, 1), round((g > 0).mean(), 2)
def lr(s, y, Xb, Xf):
    a, b = fit(s, y, Xb), fit(s, y, Xf); return round(chi2.sf(2 * (b.llf - a.llf), len(Xf) - len(Xb)), 3)

d2 = d[(d.cls >= 2015) & d.col_seasons.notna()].copy()
z = lambda x: (x - x.mean()) / x.std()
d2["recv"] = (z(d2.rec_pg) + z(d2.recyd_share) + z(d2.tgt_share)) / 3

print("== Receiving: composite vs single measures (added to draft capital), L2 2015-23")
for y in ["solid", "elite"]:
    for t in ["recv", "rec_pg", "recyd_share", "tgt_share"]:
        s = d2.dropna(subset=[t]); print(f"  {y:5s} {t:12s} cv_gain {cv(s, y, ['logpick'], ['logpick', t])}  lr_p {lr(s, y, ['logpick'], ['logpick', t])}")

print("\n== Does anything add beyond draft capital + receiving? (base = logpick + rec_pg)")
for y in ["solid", "elite"]:
    for t in ["wt", "bmi", "speed_score", "forty", "bench", "age_draft", "carry_share", "scrim_share", "late_share", "exp10", "succ_vs_team", "ypc_vs_team", "in10_share"]:
        s = d2.dropna(subset=[t, "rec_pg"])
        if len(s) < 60: continue
        print(f"  {y:5s} + {t:13s} n={len(s):3d} cv_gain {cv(s, y, ['logpick','rec_pg'], ['logpick','rec_pg',t])} lr_p {lr(s, y, ['logpick','rec_pg'], ['logpick','rec_pg',t])}")

print("\n== Named interactions (each added to its main effects + logpick)")
d["wt_x_lp"] = d.wt * d.logpick
def inter(s, y, a, b, name):
    s = s.dropna(subset=[a, b]).copy(); s["ix"] = (s[a] - s[a].mean()) * (s[b] - s[b].mean())
    base = ["logpick", a, b] if b != "logpick" else ["logpick", a]
    print(f"  {y:5s} {name:34s} n={len(s):3d} cv_gain {cv(s, y, base, base + ['ix'])} lr_p {lr(s, y, base, base + ['ix'])} sign {np.sign(fit(s, y, base+['ix']).params['ix']):+.0f}")
for y in ["solid", "elite"]:
    for t in ["wt", "bmi", "speed_score", "forty", "age_draft"]: inter(d, y, t, "logpick", f"{t} x draft capital")
    for t in ["rec_pg", "carry_share", "scrim_share", "exp10"]: inter(d2, y, t, "logpick", f"{t} x draft capital")
    inter(d2, y, "wt", "rec_pg", "size x receiving (wt x rec_pg)")
    inter(d2, y, "bmi", "rec_pg", "size x receiving (bmi x rec_pg)")
    inter(d2, y, "carry_share", "age_draft", "production x age (carry share)")
    inter(d2, y, "scrim_share", "age_draft", "production x age (scrimmage share)")
    inter(d, y, "forty", "wt", "speed x size (forty x wt)")

print("\n== Layer 3: breakout vs Layer 2's model on the same RBs (2017-23)")
d3 = d2[d2.cls >= 2017].copy(); d3["broke_out"] = 1 - d3.never_broke_out
for y in ["solid", "elite"]:
    s = d3.dropna(subset=["rec_pg"]); print(f"  {y:5s} broke_out   n={len(s)} cv_gain {cv(s, y, ['logpick','rec_pg'], ['logpick','rec_pg','broke_out'])} lr_p {lr(s, y, ['logpick','rec_pg'], ['logpick','rec_pg','broke_out'])}")
    s = d3.dropna(subset=["rec_pg", "breakout_age"]); print(f"  {y:5s} breakout_age n={len(s)} cv_gain {cv(s, y, ['logpick','rec_pg'], ['logpick','rec_pg','breakout_age'])} lr_p {lr(s, y, ['logpick','rec_pg'], ['logpick','rec_pg','breakout_age'])}")
print("  breakout coverage 2017-23:", len(d3), "RBs;", int(d3.breakout_age.notna().sum()), "with an age;", int(d3.never_broke_out.sum()), "never reached 20%")

print("\n== Effect sizes for the receiving model (logpick + rec_pg), 25th -> 75th pct of rec_pg, at fixed picks")
for y in ["solid", "elite"]:
    m = fit(d2.dropna(subset=["rec_pg"]), y, ["logpick", "rec_pg"])
    lo, hi = d2.rec_pg.quantile([.25, .75])
    print(f"  {y}: coef rec_pg {m.params['rec_pg']:.2f} (OR per catch/game {np.exp(m.params['rec_pg']):.2f}); p25 {lo:.2f} p75 {hi:.2f}")
    for pk in [16, 32, 50, 75, 100, 150]:
        p = [m.predict([[1, np.log(pk), r]])[0] * 100 for r in (lo, hi)]
        print(f"     pick {pk:3d}: {p[0]:4.0f}% at {lo:.1f} catches/game -> {p[1]:4.0f}% at {hi:.1f}")

print("\n== Tier tables, median cutoffs set before counting (L1 medians on 2011-23, L2 on 2015-23)")
tier = lambda r: "NFL rounds 1-2" if r <= 2 else ("NFL rounds 3-4" if r <= 4 else "NFL rounds 5-7")
d["tier"] = d.rnd.map(tier); d2["tier"] = d2.rnd.map(tier)
def table(s, t):
    s = s.dropna(subset=[t]); med = s[t].median(); s["hi"] = s[t] > med
    g = s.groupby(["tier", "hi"]).agg(n=("solid", "size"), solid=("solid", "mean"), elite=("elite", "mean"), y12=("solid_y12", "mean"))
    print(f"  -- {t} (median {med:.3f})")
    for (tr, h), r in g.iterrows():
        tag = "above" if h else "at/below"
        cell = f"n={int(r.n):3d}  solid {r.solid*100:3.0f}%  elite {r.elite*100:3.0f}%  solid by yr2 {r.y12*100:3.0f}%" if r.n >= 20 else f"n={int(r.n):3d}  (under 20: not shown)"
        print(f"     {tr:15s} {tag:9s} {cell}")
for t in ["rec_pg", "recyd_share", "tgt_share"]: table(d2, t)
for t in ["wt", "bmi", "speed_score", "forty", "bench", "age_draft"]: table(d, t)
for t in ["carry_share", "scrim_share", "exp10", "ypc_vs_team"]: table(d2, t)
print("\n  tier sizes L1:", d.tier.value_counts().to_dict(), "| L2:", d2.tier.value_counts().to_dict())
