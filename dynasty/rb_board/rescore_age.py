import warnings, numpy as np, pandas as pd
from sklearn.linear_model import LogisticRegression, LinearRegression
warnings.filterwarnings("ignore")
D0=pd.Timestamp("2027-04-28")
dob={"Kewan Lacy":"2006-07-06","Ahmad Hardy":"2005-12-19","Isaac Brown":"2005-03-02","Nate Frazier":"2005-09-26","Mark Fletcher Jr.":"2004-10-17",
 "Hollywood Smothers":"2005-02-03","Justice Haynes":"2004-10-24","Antwan Raymond":"2005-07-13","Cameron Dickey":"2005-11-04","Raleek Brown":"2003-08-02",
 "CJ Baxter":"2005-06-28","DeSean Bishop":"2004-10-15","Aneyas Williams":"2005-11-22","Waymond Jordan":"2003-11-04","Eli Gillman":"2003-11-17"}
pp_age_now={"LJ Martin":22.1}   # PlayerProfiler age, read Oct 31-Nov 1, 2026
age={n:round((D0-pd.Timestamp(v)).days/365.25,2) for n,v in dob.items()}
for n,a in pp_age_now.items(): age[n]=round(a+(D0-pd.Timestamp("2026-10-31")).days/365.25,2)
# training
d=pd.read_csv('features.csv'); m=pd.read_csv('matched.csv',low_memory=False)
m=m.sort_values("car",ascending=False).drop_duplicates(["gsis","season"]).sort_values("season")
L=m.groupby("gsis").tail(1).copy(); L["td_pg"]=L.rtd/L.games
d=d.merge(L[["gsis","td_pg"]],on="gsis",how="left")
d=d[(d.cls>=2015)&d.col_seasons.notna()].copy(); d["P4"]=d.conf_tier.isin(["SEC","B1G","OP4"]).astype(float)
SIX=["age_draft","scrim_share","P4","exp10","td_pg","rec_pg"]; FIVE=SIX[1:]
s=d.dropna(subset=SIX+["logpick"]).copy()
def fit_hit(cols):
    mu,sd=s[cols].mean(),s[cols].std(); return {y:(LogisticRegression(C=1.0,max_iter=2000).fit((s[cols]-mu)/sd,s[y]),mu,sd) for y in ["solid","elite"]}
H6,H5=fit_hit(SIX),fit_hit(FIVE)
S5=["age_draft","scrim_share","P4","exp10","td_pg"]; S4=S5[1:]
slot5=LinearRegression().fit(s[S5],s.logpick); slot4=LinearRegression().fit(s[S4],s.logpick)
print("training age range",s.age_draft.min(),s.age_draft.max(),"median",s.age_draft.median())
P=pd.read_csv('prospects_scored.csv'); P["age_draft"]=P.board_name.map(age)
for i,r in P.iterrows():
    has=pd.notna(r.age_draft); cols=SIX if has else FIVE; H=H6 if has else H5
    x=pd.DataFrame([r[cols].astype(float).values],columns=cols)
    for y in ["solid","elite"]:
        mdl,mu,sd=H[y]; P.loc[i,f"model_{y}"]=mdl.predict_proba((x-mu)/sd)[:,1][0]
    sc=S5 if has else S4; sm_=slot5 if has else slot4
    P.loc[i,"model_pick"]=float(np.exp(sm_.predict(pd.DataFrame([r[sc].astype(float).values],columns=sc))[0]))
    P.loc[i,"age_used"]="yes" if has else "no"
P.to_csv('prospects_scored.csv',index=False)
print(P[["board_name","age_draft","age_used","model_solid","model_elite","model_pick"]].round(3).to_string(index=False))
