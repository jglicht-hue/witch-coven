"""RB prospect study, step 7: what can be known before the NFL draft.
(a) Which pre-draft traits predict NFL draft slot (log pick), and how well.
(b) How well pre-draft traits predict solid/elite with no draft capital, against the capital-only model.
Pre-draft traits: listed college weight/height, final-season shares, receiving, age at the draft, conference, efficiency.
Sample: drafted RBs 2015-2023 with college stats (undrafted prospects are not in the sample).
Usage: python3 -I predraft.py <features_csv> <matched_csv>
"""
import sys, warnings, numpy as np, pandas as pd, statsmodels.api as sm
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.model_selection import RepeatedKFold, RepeatedStratifiedKFold
from sklearn.metrics import log_loss, r2_score
warnings.filterwarnings("ignore")
F, M = sys.argv[1:3]
d = pd.read_csv(F); m = pd.read_csv(M, low_memory=False)
m = m.sort_values("car", ascending=False).drop_duplicates(["gsis", "season"]).sort_values("season")
last = m.groupby("gsis").tail(1)[["gsis", "lwt", "lht"]]
d = d.merge(last, on="gsis", how="left")
d2 = d[(d.cls >= 2015) & d.col_seasons.notna()].copy()
d2["P4"] = d2.conf_tier.isin(["SEC", "B1G", "OP4"]).astype(float)
print("listed weight available:", int(d2.lwt.notna().sum()), "of", len(d2),
      "| listed vs combine weight, median gap:", round((d2.lwt - d2.wt).median(), 1), "lb, corr", round(d2.lwt.corr(d2.wt), 2))

T = ["lwt", "rec_pg", "scrim_share", "carry_share", "tgt_share", "age_draft", "P4", "ypc_vs_team", "exp10", "career_touches", "starter_yrs"]
s = d2.dropna(subset=T + ["logpick"]).copy()
print("\n(a) Draft slot from pre-draft traits, n =", len(s))
X = sm.add_constant((s[T] - s[T].mean()) / s[T].std()); ols = sm.OLS(s.logpick, X).fit()
print("   standardized coefficients on log(pick) (negative = drafted earlier), with p:")
for t in T: print(f"     {t:15s} {ols.params[t]:+.2f}  p={ols.pvalues[t]:.3f}")
rk = RepeatedKFold(n_splits=5, n_repeats=20, random_state=7); r2 = []
for tr, te in rk.split(s):
    lr = LinearRegression().fit(s.iloc[tr][T], s.iloc[tr].logpick); r2.append(r2_score(s.iloc[te].logpick, lr.predict(s.iloc[te][T])))
print(f"   in-sample R2 {ols.rsquared:.2f} | held-out R2 {np.mean(r2):.2f}")
# typical miss in picks
pred = ols.predict(X); err = np.exp(pred) / s.pick
print(f"   held-in typical miss: predicted pick within 2x of actual for {((err>0.5)&(err<2)).mean()*100:.0f}% of RBs")

print("\n(b) Hits with no draft capital: pre-draft traits vs capital alone (held-out log loss, lower = better)")
def cvll(s, y, cols, reps=20):
    Y = s[y].values; A = s[cols].values; out = []
    for tr, te in RepeatedStratifiedKFold(n_splits=5, n_repeats=reps, random_state=7).split(A, Y):
        mu, sd = A[tr].mean(0), A[tr].std(0) + 1e-9
        mdl = LogisticRegression(C=1.0, max_iter=2000).fit((A[tr] - mu) / sd, Y[tr])
        out.append(log_loss(Y[te], mdl.predict_proba((A[te] - mu) / sd)[:, 1], labels=[0, 1]))
    return np.mean(out)
for y in ["solid", "elite"]:
    base = s[y].mean(); null = -(base * np.log(base) + (1 - base) * np.log(1 - base))
    cap = cvll(s, y, ["logpick"]); cap_r = cvll(s, y, ["logpick", "rec_pg"])
    pre = cvll(s, y, T); pre2 = cvll(s, y, ["rec_pg", "lwt", "age_draft", "scrim_share", "P4"])
    rec = lambda v: (null - v) / (null - cap_r) * 100
    print(f"   {y}: hit rate {base*100:.0f}% | no-info {null:.3f} | capital {cap:.3f} | capital+catches {cap_r:.3f} | all pre-draft traits {pre:.3f} | 5-trait pre-draft {pre2:.3f}")
    print(f"      share of the capital+catches model's gain recovered: capital alone {rec(cap):.0f}%, all pre-draft traits {rec(pre):.0f}%, 5-trait {rec(pre2):.0f}%")
# pre-draft hit model coefficients (5 traits)
P = ["rec_pg", "lwt", "age_draft", "scrim_share", "P4"]
for y in ["solid", "elite"]:
    mm = sm.Logit(s[y], sm.add_constant((s[P] - s[P].mean()) / s[P].std())).fit(disp=0)
    print(f"   {y} pre-draft model, standardized log-odds:", {k: round(v, 2) for k, v in mm.params.drop('const').items()},
          "p:", {k: round(v, 3) for k, v in mm.pvalues.drop('const').items()})
