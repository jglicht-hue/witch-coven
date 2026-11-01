import warnings, numpy as np, pandas as pd, statsmodels.api as sm
from sklearn.linear_model import LogisticRegression, LinearRegression
warnings.filterwarnings("ignore")
# ---- training data (same as study) ----
d=pd.read_csv('features.csv'); m=pd.read_csv('matched.csv',low_memory=False)
m=m.sort_values("car",ascending=False).drop_duplicates(["gsis","season"]).sort_values("season")
L=m.groupby("gsis").tail(1).copy(); L["td_pg"]=L.rtd/L.games
d=d.merge(L[["gsis","td_pg"]],on="gsis",how="left")
d=d[(d.cls>=2015)&d.col_seasons.notna()].copy(); d["P4"]=d.conf_tier.isin(["SEC","B1G","OP4"]).astype(float)
FIVE=["scrim_share","P4","exp10","td_pg","rec_pg"]
s=d.dropna(subset=FIVE+["logpick"]).copy()
mu,sd=s[FIVE].mean(),s[FIVE].std()
hit={y:LogisticRegression(C=1.0,max_iter=2000).fit((s[FIVE]-mu)/sd,s[y]) for y in ["solid","elite"]}
SLOT=["scrim_share","P4","exp10","td_pg"]; slot=LinearRegression().fit(s[SLOT],s.logpick)
cc=d.dropna(subset=["rec_pg"]); cap={y:sm.Logit(cc[y],sm.add_constant(cc[["logpick","rec_pg"]])).fit(disp=0) for y in ["solid","elite"]}
print("training n",len(s),"| capital+catches n",len(cc),"| OR/catch solid",round(np.exp(cap['solid'].params.rec_pg),2),"elite",round(np.exp(cap['elite'].params.rec_pg),2))
# ---- prospects ----
c=pd.read_csv('college.csv',low_memory=False)
c=c.sort_values("car",ascending=False).drop_duplicates(["pid","season"])
c=c[(c.t_car/c.t_games)>=18]
c.loc[(c.season>=2024)&(c.conf=="Pac-12"),"conf_tier"]="G5/other"   # Pac-12 lost its P4 members after 2023
ros=pd.concat([pd.read_parquet(f'cfb/rosters/parquet/cfb_rosters_{y}.parquet',columns=['athlete_id','year','season']) for y in [2025,2026]]).dropna(subset=['athlete_id'])
ros['athlete_id']=ros.athlete_id.astype('int64'); ros=ros.drop_duplicates(['athlete_id','season'])
def feats(g):
    g=g.sort_values("season"); last=g.iloc[-1]; car=g.car.sum()
    return pd.Series(dict(name=last["name"],team=last.team,final_season=int(last.season),games=last.games,car=last.car,ryd=last.ryd,
        rec=last.rec,recyd=last.recyd,rtd=last.rtd,conf=last.conf,P4=float(last.conf_tier in ["SEC","B1G","OP4"]),
        scrim_share=(last.ryd+last.recyd)/(last.t_ryd+last.t_recyd), rec_pg=last.rec/last.games, td_pg=last.rtd/last.games,
        tgt_share=last.tgt/last.t_tgt if last.t_tgt else np.nan, recyd_share=last.recyd/last.t_recyd if last.t_recyd else np.nan,
        exp10=g.e10.sum()/car if car>=100 else np.nan, career_car=car, lwt=last.lwt))
def score(P):
    X=P[FIVE]
    ok=X.notna().all(1)
    for y in ["solid","elite"]:
        P.loc[ok,f"model_{y}"]=hit[y].predict_proba((X[ok]-mu)/sd)[:,1]
    P.loc[P[SLOT].notna().all(1),"model_pick"]=np.exp(slot.predict(P.loc[P[SLOT].notna().all(1),SLOT]))
    return P
POOL={5079322:"Jadan Baugh",5086388:"Kewan Lacy",5197065:"Ahmad Hardy",5084047:"Nate Frazier",4870736:"Mark Fletcher Jr.",4871053:"Hollywood Smothers",
 5079349:"Isaac Brown",4918126:"LJ Martin",4870760:"Justice Haynes",5209945:"Antwan Raymond",5220197:"Fluff Bothwell",5193580:"Cameron Dickey",
 4685268:"Raleek Brown",4912342:"Wayne Knight",4918103:"Cam Cook",4870609:"CJ Baxter",4921108:"DeSean Bishop",5079742:"Aneyas Williams",
 5295318:"Waymond Jordan",5086034:"Cam Edwards"}
P=c[c.pid.isin(POOL)].groupby("pid").apply(feats).reset_index()
P["board_name"]=P.pid.map(POOL); P["pool"]="consensus"
# sleepers: 2026 RBs, class year 3+, 50+ carries in 2026, not in pool
c26=c[(c.season==2026)&(c.pos=="RB")&(c.car>=50)&(~c.pid.isin(POOL))]
yr=ros[ros.season==2026].set_index('athlete_id').year
c26=c26[c26.pid.map(yr).fillna(0)>=3]
S=c[c.pid.isin(c26.pid)].groupby("pid").apply(feats).reset_index(); S["board_name"]=S.name; S["pool"]="sleeper"
P=score(P); S=score(S)
S=S.sort_values("model_solid",ascending=False)
print("sleeper candidates scored:",len(S))
print(S.head(12)[["board_name","team","conf","games","car","rec_pg","td_pg","scrim_share","exp10","model_solid","model_elite","model_pick"]].round(3).to_string(index=False))
P["class_year_2026"]=P.pid.map(yr); S["class_year_2026"]=S.pid.map(yr)
pd.concat([P,S.head(5)]).to_csv('prospects_scored.csv',index=False)
print(P[["board_name","final_season","games","car","rec_pg","td_pg","scrim_share","exp10","P4","model_solid","model_elite","model_pick","class_year_2026"]].round(3).to_string(index=False))
import pickle; pickle.dump(dict(cap=cap),open('cap.pkl','wb'))
