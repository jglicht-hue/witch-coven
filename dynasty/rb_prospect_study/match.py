"""RB prospect study, step 3: link drafted RBs (2015-2023 classes) to college player-seasons.
ESPN id first; fallback = normalized full name among college RB/athlete seasons in the 4 years before the draft.
Usage: python3 -I match.py <outcomes_csv> <players_csv> <college_csv> <out_csv>
"""
import sys, re, pandas as pd
O, PL, C, OUT = sys.argv[1:5]
o = pd.read_csv(O); p = pd.read_csv(PL, low_memory=False, usecols=["gsis_id", "espn_id", "birth_date"])
o = o.merge(p, left_on="gsis", right_on="gsis_id", how="left")
c = pd.read_csv(C, low_memory=False)
norm = lambda s: re.sub(r"[^a-z ]", "", re.sub(r"\b(jr|sr|ii|iii|iv)\b\.?", "", str(s).lower().replace(".", ""))).split() and " ".join(re.sub(r"[^a-z ]", "", re.sub(r"\b(jr|sr|ii|iii|iv)\b\.?", "", str(s).lower().replace(".", ""))).split())
c["k"] = c.name.map(norm)
o["k"] = o.name.map(norm)
rows, how = [], []
for _, r in o[o.cls >= 2015].iterrows():
    sub = c[(c.season < r.cls) & (c.season >= r.cls - 5)]
    m = sub[sub.pid == r.espn_id] if pd.notna(r.espn_id) else sub.iloc[0:0]
    h = "espn_id"
    if not len(m):
        cand = sub[(sub.k == r.k) & (sub.car >= 20)]
        if cand.pid.nunique() == 1:
            m = sub[sub.pid == cand.pid.iat[0]]; h = "name"
        else:
            h = "none" if cand.pid.nunique() == 0 else "ambiguous"
    how.append((r["name"], r.cls, h, m.pid.iat[0] if len(m) else None))
    if len(m):
        rows.append(m.assign(gsis=r.gsis))
lk = pd.DataFrame(how, columns=["name", "cls", "how", "pid"])
print(lk.how.value_counts().to_string())
print("unmatched:", lk[lk.how.isin(["none", "ambiguous"])][["name", "cls", "how"]].to_string(index=False))
pd.concat(rows).to_csv(OUT, index=False)
