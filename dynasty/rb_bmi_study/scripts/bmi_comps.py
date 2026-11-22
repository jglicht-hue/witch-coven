"""BMI-band study step 3: (a) check the Gemini table's players against nflverse combine measurements; (b) Price's nearest comps among drafted RBs 2011-2023.
Usage: python3 -I bmi_comps.py <nfl_dir> <bmi_base.csv>
"""
import sys, numpy as np, pandas as pd
D, B = sys.argv[1:3]
cb = pd.read_csv(f"{D}/combine.csv"); cb = cb[cb.pos == "RB"].copy()
def inches(h):
    try: f, i = str(h).split("-"); return int(f) * 12 + int(i)
    except Exception: return np.nan
cb["ht_in"] = cb.ht.map(inches); cb["bmi"] = (703 * cb.wt / cb.ht_in ** 2).round(1)
names = ["Jadarian Price","Chris Johnson","James Cook","De'Von Achane","Bucky Irving","Christian McCaffrey","Adrian Peterson","Kyren Williams","Jahmyr Gibbs",
 "Derrick Henry","Breece Hall","Austin Ekeler","Alvin Kamara","Bijan Robinson","Barry Sanders","Josh Jacobs","Jaylen Warren","Saquon Barkley","Nick Chubb",
 "Maurice Jones-Drew","Jerome Bettis","A.J. Dillon","AJ Dillon"]
print("=== Gemini-table players found in nflverse combine (RB) ===")
print(cb[cb.player_name.isin(names)][["season","player_name","school","ht","wt","bmi","forty"]].sort_values("player_name").to_string(index=False))
missing = [n for n in names if n not in set(cb.player_name)]
print("\nNot in nflverse combine RB file (by exact name):", missing)
# Price
print("\nPrice rows (any pos):"); a = pd.read_csv(f"{D}/combine.csv"); print(a[a.player_name.str.contains("Jadarian", na=False)].to_string(index=False))
d = pd.read_csv(B)
d = d[d.bmi.notna()]
near = d[(d.bmi >= 27.8) & (d.bmi <= 29.4) & (d.rnd <= 3)].sort_values(["rnd", "pick"])
print("\n=== Drafted RBs 2011-2023, NFL rounds 1-3, BMI 27.8-29.4 (Price band, int-inch BMI) ===")
print(near[["name","cls","rnd","pick","ht","wt","bmi","forty","speed_score","best3","solid","elite"]].round(1).to_string(index=False))
r12 = d[d.rnd <= 2]
print("\nAll NFL rd 1-2 RBs with BMI: n=%d; BMI<29.5: n=%d solid=%d elite=%d" % (len(r12), (r12.bmi<29.5).sum(), r12[r12.bmi<29.5].solid.sum(), r12[r12.bmi<29.5].elite.sum()))
print("pick 20-45 NFL RBs (Price-like slot #32), BMI <29.5 vs rest:")
s = d[d.pick.between(20, 45)]
for lab, g in [("BMI<29.5", s[s.bmi < 29.5]), ("BMI>=29.5", s[s.bmi >= 29.5])]:
    print(f"  {lab}: n={len(g)} solid={int(g.solid.sum())} elite={int(g.elite.sum())}")
