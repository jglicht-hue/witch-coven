"""RB prospect study, step 8: can pre-draft information predict NFL draft slot better?
Candidates are added one at a time to a base model and judged on held-out R2; the whole selection
procedure is then re-scored with nested cross-validation so the headline number isn't flattered.
Also: breakout age against raw age on the same RBs, and two nonlinear models.
Usage: python3 -I draftslot.py <features_csv> <matched_csv>
"""
import sys, warnings, numpy as np, pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor, HistGradientBoostingRegressor
from sklearn.model_selection import KFold
from sklearn.metrics import r2_score
warnings.filterwarnings("ignore")
F, M = sys.argv[1:3]
d = pd.read_csv(F); m = pd.read_csv(M, low_memory=False)
m = m.sort_values("car", ascending=False).drop_duplicates(["gsis", "season"]).sort_values("season")
L = m.groupby("gsis").tail(1).copy()
L["ypg"] = (L.ryd + L.recyd) / L.games; L["rush_ypg"] = L.ryd / L.games; L["td_pg"] = (L.rtd) / L.games
L["ypc"] = L.ryd / L.car; L["games_final"] = L.games
d = d.merge(L[["gsis", "lwt", "lht", "ypg", "rush_ypg", "td_pg", "ypc", "games_final"]], on="gsis", how="left")
d = d[(d.cls >= 2015) & d.col_seasons.notna()].copy()
for t in ["SEC", "B1G", "OP4"]: d[f"is_{t}"] = (d.conf_tier == t).astype(float)
d["P4"] = d.conf_tier.isin(["SEC", "B1G", "OP4"]).astype(float)
d["seasons_on_file"] = d.col_seasons

def cv(s, cols, reps=20, model=None):
    r = []; Y = s.logpick.values; A = s[cols].values
    for rep in range(reps):
        for tr, te in KFold(5, shuffle=True, random_state=rep).split(A):
            mdl = (model() if model else LinearRegression()).fit(A[tr], Y[tr]); r.append(r2_score(Y[te], mdl.predict(A[te])))
    return np.mean(r)

BASE = ["age_draft", "scrim_share", "P4", "exp10"]
CAND = ["rec_pg", "tgt_share", "recyd_share", "carry_share", "ypg", "rush_ypg", "td_pg", "ypc", "ypc_vs_team", "succ_vs_team",
        "exp20", "in10_share", "third_share", "late_share", "fum_per_touch", "career_touches", "starter_yrs", "games_final",
        "is_SEC", "is_B1G"]
s = d.dropna(subset=BASE + CAND).copy()
b = cv(s, BASE); print(f"Sample with every candidate: n={len(s)} | base held-out R2 {b:.3f}")
print("One at a time on top of the base (change in held-out R2):")
gains = {c: cv(s, BASE + [c]) - b for c in CAND}
for c, g in sorted(gains.items(), key=lambda x: -x[1]): print(f"   {c:15s} {g:+.3f}")

# forward selection, scored honestly by nested CV
def forward(s, pool, base, reps=5):
    cur = list(base); best = cv(s, cur, reps)
    while True:
        tries = {c: cv(s, cur + [c], reps) for c in pool if c not in cur}
        if not tries: break
        c, v = max(tries.items(), key=lambda x: x[1])
        if v - best < 0.005: break
        cur.append(c); best = v
    return cur, best
sel, sc = forward(s, CAND, BASE); print(f"\nForward selection on all data: {sel} -> held-out R2 {sc:.3f} (optimistic)")
outer = []
for rep in range(4):
    for tr, te in KFold(5, shuffle=True, random_state=100 + rep).split(s):
        st, se = s.iloc[tr], s.iloc[te]; cols, _ = forward(st, CAND, BASE, reps=3)
        mdl = LinearRegression().fit(st[cols], st.logpick); outer.append(r2_score(se.logpick, mdl.predict(se[cols])))
print(f"Nested CV of the whole selection procedure: held-out R2 {np.mean(outer):.3f}")
allc = BASE + CAND
print(f"Random forest, all {len(allc)} traits: {cv(s, allc, reps=5, model=lambda: RandomForestRegressor(300, min_samples_leaf=5, random_state=0)):.3f}")
print(f"Gradient boosting, all traits: {cv(s, allc, reps=5, model=lambda: HistGradientBoostingRegressor(max_depth=3, learning_rate=0.05, max_iter=200, min_samples_leaf=10)):.3f}")

print("\nBreakout age against raw age (2017-23 classes; never-broke-out RBs given their own flag)")
t = d[d.cls >= 2017].copy(); t["never"] = t.never_broke_out
t["bo_age"] = t.breakout_age.fillna(t.breakout_age.max())   # never broke out = latest possible
t = t.dropna(subset=["age_draft", "scrim_share", "exp10"])
for name, cols in [("age only", ["age_draft"]), ("breakout age + never flag", ["bo_age", "never"]), ("both", ["age_draft", "bo_age", "never"]),
                   ("base", BASE), ("base + breakout", BASE + ["bo_age", "never"]), ("base with breakout instead of age", ["bo_age", "never", "scrim_share", "P4", "exp10"])]:
    print(f"   {name:36s} n={len(t)} held-out R2 {cv(t, cols):.3f}")
print("   Spearman with pick: age", round(t.age_draft.corr(t.pick, method="spearman"), 2), "| breakout age (broke out only)",
      round(t.breakout_age.corr(t.pick, method="spearman"), 2), "| never broke out", round(t.never.corr(t.pick, method="spearman"), 2))
print("\nListed weight and height (smaller sample):")
w = d.dropna(subset=BASE + ["lwt", "lht"])
print(f"   n={len(w)} base {cv(w, BASE):.3f} | +listed weight {cv(w, BASE+['lwt']):.3f} | +weight & height {cv(w, BASE+['lwt','lht']):.3f}")
