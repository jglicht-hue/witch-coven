"""BMI-band study step 1: outcomes (from the study's outcomes.py) + nflverse combine height/weight.
Merge and BMI formula copied from coven/dynasty/rb_prospect_study/features.py (pfr id match, integer-inch height, 703*lb/in^2).
Usage: python3 -I bmi_merge.py <nfl_dir> <outcomes.csv> <out.csv>
"""
import sys, numpy as np, pandas as pd
D, OC, OUT = sys.argv[1:4]
o = pd.read_csv(OC)
cb = pd.read_csv(f"{D}/combine.csv")
cb = cb[cb.pos == "RB"].copy()
m = o.merge(cb.drop_duplicates("pfr_id"), left_on="pfr", right_on="pfr_id", how="left", suffixes=("", "_cb"))
def inches(h):
    try: f, i = str(h).split("-"); return int(f) * 12 + int(i)
    except Exception: return np.nan
m["ht_in"] = m.ht.map(inches)
m["bmi"] = 703 * m.wt / m.ht_in ** 2
m["speed_score"] = m.wt * 200 / m.forty ** 4
m["logpick"] = np.log(m.pick)
m.to_csv(OUT, index=False)
print("rows", len(m), "| with weight:", int(m.wt.notna().sum()), "| with ht:", int(m.ht_in.notna().sum()), "| with bmi:", int(m.bmi.notna().sum()))
print(m.bmi.describe().round(2).to_string())
print("median bmi", round(m.bmi.median(), 2), "median wt", m.wt.median())
print("combine seasons present:", sorted(cb.season.unique())[-4:])
print(m.groupby("rnd").bmi.agg(["count", "median"]).round(2).to_string())
print("quantiles", m.bmi.quantile([.1,.2,.25,.33,.5,.67,.75,.8,.9]).round(2).to_dict())
