import warnings, numpy as np, pandas as pd, statsmodels.api as sm, pickle, re
from sklearn.linear_model import LogisticRegression, LinearRegression
warnings.filterwarnings("ignore")
cap=pickle.load(open('cap.pkl','rb'))['cap']
# six-trait pre-draft model (same as board)
d=pd.read_csv('features.csv'); m=pd.read_csv('matched.csv',low_memory=False)
m=m.sort_values("car",ascending=False).drop_duplicates(["gsis","season"]).sort_values("season")
L=m.groupby("gsis").tail(1).copy(); L["td_pg"]=L.rtd/L.games
d=d.merge(L[["gsis","td_pg"]],on="gsis",how="left"); d=d[(d.cls>=2015)&d.col_seasons.notna()].copy(); d["P4"]=d.conf_tier.isin(["SEC","B1G","OP4"]).astype(float)
SIX=["age_draft","scrim_share","P4","exp10","td_pg","rec_pg"]; s=d.dropna(subset=SIX+["logpick"])
mu,sd=s[SIX].mean(),s[SIX].std(); H={y:LogisticRegression(C=1.0,max_iter=2000).fit((s[SIX]-mu)/sd,s[y]) for y in ["solid","elite"]}
# 2025/2026 drafted RBs -> college
dr=pd.read_csv('nfl/draft.csv'); pl=pd.read_csv('nfl/players.csv',low_memory=False,usecols=["gsis_id","espn_id","birth_date"])
rb=dr[(dr.position=="RB")&dr.season.isin([2024,2025,2026])][["season","pick","pfr_player_name","gsis_id","age"]].merge(pl,on="gsis_id",how="left")
c=pd.read_csv('college.csv',low_memory=False); c=c.sort_values("car",ascending=False).drop_duplicates(["pid","season"]); c=c[(c.t_car/c.t_games)>=18]
c.loc[(c.season>=2024)&(c.conf=="Pac-12"),"conf_tier"]="G5/other"
norm=lambda x: " ".join(re.sub(r"[^a-z ]","",re.sub(r"\b(jr|sr|ii|iii|iv)\b","",str(x).lower().replace(".",""))).split())
c["k"]=c.name.map(norm)
rows=[]
for _,r in rb.iterrows():
    sub=c[(c.season<r.season)&(c.season>=r.season-5)]
    g=sub[sub.pid==r.espn_id] if pd.notna(r.espn_id) else sub.iloc[0:0]
    if not len(g):
        cand=sub[(sub.k==norm(r.pfr_player_name))&(sub.car>=20)]
        if cand.pid.nunique()==1: g=sub[sub.pid==cand.pid.iat[0]]
    if not len(g): rows.append(dict(cls=r.season,name=r.pfr_player_name,pick=r.pick,linked=False)); continue
    g=g.sort_values("season"); last=g.iloc[-1]; car=g.car.sum()
    bd=pd.to_datetime(r.birth_date) if pd.notna(r.birth_date) else pd.NaT
    age=((pd.Timestamp(f"{int(r.season)}-04-28")-bd).days/365.25) if pd.notna(bd) else np.nan
    rows.append(dict(cls=r.season,name=r.pfr_player_name,pick=r.pick,linked=True,age_draft=age,
        scrim_share=(last.ryd+last.recyd)/(last.t_ryd+last.t_recyd),P4=float(last.conf_tier in ["SEC","B1G","OP4"]),
        exp10=g.e10.sum()/car if car>=100 else np.nan,td_pg=last.rtd/last.games,rec_pg=last.rec/last.games))
R=pd.DataFrame(rows)
def score(df,pickcol):
    ok=df[SIX].notna().all(1)
    for y in ["solid","elite"]:
        df.loc[ok,f"model_{y}"]=H[y].predict_proba((df.loc[ok,SIX]-mu)/sd)[:,1]
        okc=df.rec_pg.notna()&df[pickcol].notna()
        df.loc[okc,f"cap_{y}"]=cap[y].predict(pd.DataFrame({"const":1.0,"logpick":np.log(df.loc[okc,pickcol]),"rec_pg":df.loc[okc,"rec_pg"]}))
    return df
R=score(R,"pick")
B=pd.read_csv('dash_board.csv'); P=pd.read_csv('prospects_scored.csv').set_index('board_name')
K=pd.DataFrame({"cls":2027,"name":B.name,"pick":B.consensus_rank.fillna(185),"linked":True,"age_draft":B.name.map(P.age_draft),
 "scrim_share":B.name.map(P.scrim_share),"P4":B.name.map(P.P4),"exp10":B.name.map(P.exp10),"td_pg":B.name.map(P.td_pg),"rec_pg":B.name.map(P.rec_pg)})
K=score(K,"pick")
A=pd.concat([R,K]); A.to_csv('class_compare.csv',index=False)
print("linked:",R.groupby("cls").linked.agg(['sum','count']).to_dict())
pd.set_option('display.width',250)
for y in [2025,2026,2027]:
    t=A[A.cls==y].sort_values("pick").head(10)
    print(f"\n== {y} (top 10 by {'board rank' if y==2027 else 'draft pick'})")
    print(t[["name","pick","age_draft","rec_pg","cap_solid","cap_elite","model_solid","model_elite"]].round(2).to_string(index=False))
print("\nSummary, top 10 by slot:")
for y in [2024,2025,2026,2027]:
    t=A[A.cls==y].sort_values("pick").head(10); t5=t.head(5)
    print(y, "| sum cap solid",round(t.cap_solid.sum(),1),"elite",round(t.cap_elite.sum(),1),
      "| sum model solid",round(t.model_solid.sum(),1),"elite",round(t.model_elite.sum(),1),"(n model",int(t.model_solid.notna().sum()),")",
      "| top5 cap solid",round(t5.cap_solid.sum(),1),"elite",round(t5.cap_elite.sum(),1),"| top5 model solid",round(t5.model_solid.sum(),1),
      "| med catches",round(t.rec_pg.median(),2),"| med age",round(t.age_draft.median(),1))
