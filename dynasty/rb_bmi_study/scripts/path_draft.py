"""Draft-slot study (owner request Nov 21). What predicts where an RB is drafted, and does BMI add to the brief's fixed pre-draft model?
NOTE: the brief locks the pre-draft model (Oct 31). This steps outside the lock at the owner's request; declared additions are ONLY BMI (and weight/height/Speed Score as named variants). Results are exploratory.
Held-out R2 method copied from draftslot.py: 20 repeats of 5-fold, LinearRegression on ln(pick).
Usage: python3 -I path_draft.py <features_csv> <matched_csv> <dur_base_csv>
"""
import sys, warnings, numpy as np, pandas as pd, statsmodels.api as sm
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.model_selection import KFold, RepeatedStratifiedKFold
from sklearn.metrics import r2_score, log_loss
warnings.filterwarnings("ignore")
F, M, DB = sys.argv[1:4]
f = pd.read_csv(F); m = pd.read_csv(M, low_memory=False)
m = m.sort_values("car", ascending=False).drop_duplicates(["gsis", "season"]).sort_values("season")
L = m.groupby("gsis").tail(1).copy(); L["td_pg"] = L.rtd / L.games
f = f.merge(L[["gsis", "td_pg", "lwt", "lht"]], on="gsis", how="left")
f["P4"] = f.conf_tier.isin(["SEC", "B1G", "OP4"]).astype(float)
dur = pd.read_csv(DB); dur = dur[dur.horizon == 3][["gsis", "ppr", "gshare"]]
f = f.merge(dur, on="gsis", how="left")
def cv(s, cols, reps=20):
    r = []; Y = s.logpick.values; A = s[cols].values
    for rep in range(reps):
        for tr, te in KFold(5, shuffle=True, random_state=rep).split(A):
            mdl = LinearRegression().fit(A[tr], Y[tr]); r.append(r2_score(Y[te], mdl.predict(A[te])))
    return np.mean(r)
def lrt(s, base, add):
    X0 = sm.add_constant(s[base]); X1 = sm.add_constant(s[base + [add]])
    m0 = sm.OLS(s.logpick, X0).fit(); m1 = sm.OLS(s.logpick, X1).fit()
    return m1.params[add], m1.pvalues[add]

print("=== D1: combine measurements only (all drafted RBs 2011-2023) -> ln(pick), held-out R2 ===")
c = f.copy(); c["ht"] = c.ht_in if "ht_in" in c else np.nan
sets = {"BMI": ["bmi"], "weight": ["wt"], "height": ["ht_in"], "height + weight": ["ht_in", "wt"], "40 time": ["forty"], "Speed Score": ["speed_score"],
        "weight + 40": ["wt", "forty"], "weight + 40 + vertical + broad": ["wt", "forty", "vertical", "broad_jump"], "BMI + 40": ["bmi", "forty"]}
for lab, cols in sets.items():
    s = c.dropna(subset=cols + ["logpick"])
    print(f"   {lab:32s} n={len(s):3d} held-out R2 {cv(s, cols):+.3f}")
print("   (R2 is the share of the spread in ln(pick) explained on RBs the model wasn't fitted to)")

BASE = ["age_draft", "scrim_share", "P4", "exp10", "td_pg"]   # the fixed five-trait slot model (4 base + TDs per game), brief v2.14/2.16
print("\n=== D2: brief's fixed five-trait slot model, plus BMI (2015-2023 drafted RBs with college stats and combine BMI) ===")
s = f[(f.cls >= 2015)].dropna(subset=BASE + ["bmi", "logpick"]).copy()
b0 = cv(s, BASE); print(f"   n={len(s)} | base held-out R2 {b0:.3f}")
for lab, extra in [("+ BMI", ["bmi"]), ("+ combine weight", ["wt"]), ("+ combine height", ["ht_in"]), ("+ Speed Score", ["speed_score"]), ("+ 40 time", ["forty"])]:
    ss = s.dropna(subset=extra); b = cv(ss, BASE); v = cv(ss, BASE + extra)
    coef, p = lrt(ss, BASE, extra[0])
    print(f"   {lab:20s} n={len(ss)} base {b:.3f} -> {v:.3f} (change {v-b:+.3f}); coefficient on ln(pick) {coef:+.3f}, p={p:.3f}")

print("\n=== D3: hits with NO draft capital: six-trait pre-draft model vs same + BMI (held-out log loss, lower = better) ===")
SIX = ["age_draft", "scrim_share", "P4", "exp10", "td_pg", "rec_pg"]
t = f[(f.cls >= 2015)].dropna(subset=SIX + ["bmi", "solid", "elite"]).copy()
def cvll(s, y, cols, reps=20):
    Y = s[y].values; A = s[cols].values; out = []
    for tr, te in RepeatedStratifiedKFold(n_splits=5, n_repeats=reps, random_state=7).split(A, Y):
        mu, sd = A[tr].mean(0), A[tr].std(0) + 1e-9
        mdl = LogisticRegression(C=1.0, max_iter=2000).fit((A[tr] - mu) / sd, Y[tr])
        out.append(log_loss(Y[te], mdl.predict_proba((A[te] - mu) / sd)[:, 1], labels=[0, 1]))
    return np.mean(out)
for y in ["solid", "elite"]:
    base = t[y].mean(); null = -(base * np.log(base) + (1 - base) * np.log(1 - base))
    a = cvll(t, y, SIX); b_ = cvll(t, y, SIX + ["bmi"]); c_ = cvll(t, y, SIX + ["wt"])
    print(f"   {y}: n={len(t)} no-info {null:.3f} | six-trait {a:.3f} | +BMI {b_:.3f} (change {b_-a:+.3f}) | +weight {c_:.3f} (change {c_-a:+.3f})")

print("\n=== D4: the light-BMI early picks. Picks 1-45, 2011-2023: who are they and what do they share? ===")
e = f[(f.pick <= 45) & f.bmi.notna()].sort_values("bmi")
cols = ["name", "cls", "pick", "bmi", "wt", "forty", "speed_score", "rec_pg", "age_draft", "ppr"]
print(e[cols].round(2).to_string(index=False))
e = e.assign(grp=np.where(e.bmi < 29.5, "BMI<29.5", np.where(e.bmi < 31, "29.5-30.99", "BMI>=31")))
print(e.groupby("grp").agg(n=("pick", "size"), med_pick=("pick", "median"), speed=("speed_score", "mean"), forty=("forty", "mean"), rec_pg=("rec_pg", "mean"), age=("age_draft", "mean"), ppr=("ppr", "mean")).round(2).to_string())
f.to_csv("/home/claude/work/out/path_full.csv", index=False)
