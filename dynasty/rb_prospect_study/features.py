"""RB prospect study, step 4: one row per drafted RB (2011-2023) with outcomes, draft capital, combine and college traits.
College traits use regular-season games only (postseason exists in the source only from 2023) and skip
team-seasons with < 18 carries a game (rushing plays largely unattributed, e.g. Miami 2014).
Usage: python3 -I features.py <scratch_dir> <cfb_repo_dir> <out_csv>
"""
import sys, numpy as np, pandas as pd
S, R, OUT = sys.argv[1:4]
o = pd.read_csv(f"{S}/outcomes.csv")
pl = pd.read_csv(f"{S}/nfl/players.csv", low_memory=False, usecols=["gsis_id", "birth_date"])
cb = pd.read_csv(f"{S}/nfl/combine.csv")
o = o.merge(pl, left_on="gsis", right_on="gsis_id", how="left")
o["bd"] = pd.to_datetime(o.birth_date)
o["age_draft"] = ((pd.to_datetime(o.cls.astype(str) + "-04-28") - o.bd).dt.days / 365.25).round(2)
o["logpick"] = np.log(o.pick)

# combine (match on pfr id, fallback name+year)
cb = cb[cb.pos == "RB"].copy()
m1 = o.merge(cb.drop_duplicates("pfr_id"), left_on="pfr", right_on="pfr_id", how="left", suffixes=("", "_cb"))
o = m1
def inches(h):
    try: f, i = str(h).split("-"); return int(f) * 12 + int(i)
    except Exception: return np.nan
o["ht_in"] = o.ht.map(inches)
o["bmi"] = 703 * o.wt / o.ht_in ** 2
o["speed_score"] = o.wt * 200 / o.forty ** 4

# college
c = pd.read_csv(f"{S}/matched.csv", low_memory=False)
# fumbles can be credited on an opponent-team row: sum fumbles by player-season, keep main team row
fum = c.groupby(["gsis", "season"]).fum.sum()
c = c.sort_values("car", ascending=False).drop_duplicates(["gsis", "season"])
c["fum"] = c.set_index(["gsis", "season"]).index.map(fum)
c["bad_team"] = (c.t_car / c.t_games) < 18
c = c[~c.bad_team]
# study seasons are 2014-2022, which carry no postseason games in the source, so they are regular season only.
# (A board built on 2023+ seasons must drop postseason games to stay comparable.)
c["touch"] = c.car + c.rec
c["scrim"] = c.ryd + c.recyd
c["t_scrim"] = c.t_ryd + c.t_recyd

def agg(g):
    g = g.sort_values("season"); last = g.iloc[-1]
    car = g.car.sum(); oc = g.oth_car.sum()
    r = dict(
        col_seasons=len(g), final_season=int(last.season), conf_tier=last.conf_tier,
        carry_share=last.car / last.t_car if last.t_car else np.nan,
        scrim_share=last.scrim / last.t_scrim if last.t_scrim else np.nan,
        tgt_share=last.tgt / last.t_tgt if last.t_tgt else np.nan,
        rec_pg=last.rec / last.games if last.games else np.nan,
        recyd_share=last.recyd / last.t_recyd if last.t_recyd else np.nan,
        third_share=(last.third_c + last.third_t) / last.t_third if last.t_third else np.nan,
        late_share=(last.late_c + last.late_t) / last.t_late if last.t_late else np.nan,
        in10_share=last.in10 / last.t_in10 if last.t_in10 else np.nan,
        fum_per_touch=g.fum.sum() / g.touch.sum() if g.touch.sum() else np.nan,
        starter_yrs=int((g.car / g.t_car >= 0.30).sum()),
        ypc_vs_team=(g.ryd.sum() / car - g.oth_ryd.sum() / oc) if car >= 100 and oc >= 50 else np.nan,
        succ_vs_team=(g.succ.sum() / car - g.oth_succ.sum() / oc) if car >= 100 and oc >= 50 else np.nan,
        exp10=g.e10.sum() / car if car >= 100 else np.nan,
        exp20=g.e20.sum() / car if car >= 100 else np.nan,
        career_touches=g.touch.sum(),
        first_season=int(g.season.min()),
    )
    bo = g[(g.scrim / g.t_scrim) >= 0.20]
    r["breakout_season"] = int(bo.season.min()) if len(bo) else np.nan
    return pd.Series(r)
col = c.groupby("gsis").apply(agg).reset_index()
o = o.merge(col, on="gsis", how="left")
o["breakout_age"] = np.where(o.breakout_season.notna(),
                             ((pd.to_datetime(o.breakout_season.astype("Int64").astype(str) + "-09-01", errors="coerce") - o.bd).dt.days / 365.25), np.nan)
o["never_broke_out"] = (o.col_seasons.notna() & o.breakout_season.isna()).astype(int)
# left-censoring: breakout in the first season on file, and that season is 2014 -> could be earlier
o.loc[(o.breakout_season == 2014) & (o.first_season == 2014), "breakout_age"] = np.nan
o.to_csv(OUT, index=False)
print("rows", len(o))
cols = ["wt", "bmi", "bench", "forty", "speed_score", "vertical", "broad_jump", "cone", "shuttle", "age_draft",
        "carry_share", "scrim_share", "tgt_share", "rec_pg", "recyd_share", "third_share", "late_share", "in10_share",
        "fum_per_touch", "starter_yrs", "ypc_vs_team", "succ_vs_team", "exp10", "exp20", "career_touches", "breakout_age"]
print(o[cols].describe().T[["count", "mean", "25%", "50%", "75%"]].round(3).to_string())
print(o[o.cls >= 2015].conf_tier.value_counts(dropna=False).to_string())
