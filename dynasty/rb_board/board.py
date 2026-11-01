import numpy as np, pandas as pd, pickle, statsmodels.api as sm
P=pd.read_csv('prospects_scored.csv'); cap=pickle.load(open('cap.pkl','rb'))['cap']
nflmdd={"Jadan Baugh":21,"Kewan Lacy":40,"Ahmad Hardy":63,"Nate Frazier":94,"Mark Fletcher Jr.":103,"Hollywood Smothers":104,"Isaac Brown":106,
 "LJ Martin":116,"Justice Haynes":134,"Antwan Raymond":142,"Fluff Bothwell":163}
brugler={"Kewan Lacy":17,"Jadan Baugh":26,"Ahmad Hardy":31}
tice={"Jadan Baugh":25}
ds={"Jadan Baugh":4,"Kewan Lacy":6,"Ahmad Hardy":12,"Mark Fletcher Jr.":18,"Antwan Raymond":19,"LJ Martin":21,"Cameron Dickey":26,"Raleek Brown":29,
 "Wayne Knight":32,"Nate Frazier":35,"Cam Cook":38,"Isaac Brown":42,"Hollywood Smothers":44,"Justice Haynes":48,"Fluff Bothwell":49,"CJ Baxter":53,
 "DeSean Bishop":57,"Aneyas Williams":58,"Waymond Jordan":61,"Cam Edwards":68}
dn={"Jadan Baugh":2,"Kewan Lacy":4,"Fluff Bothwell":8,"Ahmad Hardy":9,"Cam Cook":11,"Nate Frazier":15}
rows=[]
for _,r in P.iterrows():
    n=r.board_name; src=[v for v in [nflmdd.get(n),brugler.get(n),tice.get(n)] if v]
    slot=np.mean(src) if src else np.nan; bound=not src and r.pool=="consensus"
    pk=slot if src else (185 if bound else np.nan)
    o={}
    for y in ["solid","elite"]:
        o[y]=float(cap[y].predict(pd.DataFrame({"const":[1.0],"logpick":[np.log(pk)],"rec_pg":[r.rec_pg]}))[0]) if pd.notna(pk) else np.nan
    rk=[v for v in [ds.get(n),dn.get(n)] if v]
    rows.append(dict(name=n, school=r.team, pool=r.pool, final_season=int(r.final_season), games=int(r.games), class_year_2026=r.class_year_2026,
        conf=r.conf, P4=int(r.P4), rec_pg=r.rec_pg, tgt_share=r.tgt_share, recyd_share=r.recyd_share, td_pg=r.td_pg, scrim_share=r.scrim_share, exp10=r.exp10,
        nflmdd_rank=nflmdd.get(n), brugler_rank=brugler.get(n), tice_rank=tice.get(n), consensus_slot=slot, slot_is_bound=bound,
        cons_round=(int(np.ceil(pk/32)) if pd.notna(pk) else None), cons_solid=o["solid"], cons_elite=o["elite"],
        model_pick=r.model_pick, model_round=int(np.ceil(r.model_pick/32)), model_solid=r.model_solid, model_elite=r.model_elite,
        ds_rank=ds.get(n), dn_rank=dn.get(n), rookie_blend=np.mean(rk) if rk else np.nan))
B=pd.DataFrame(rows)
B["round_gap"]=B.model_round-B.cons_round
B["gap_flag"]=(B.round_gap.abs()>=1)&B.cons_round.notna()&~B.slot_is_bound
B.loc[B.slot_is_bound&(B.model_round<=5),"gap_flag"]=True   # model sees NFL round 1-5 where the board has him 185+
B["rookie_round"]=np.ceil(B.rookie_blend/12)
B["cons_rank"]=B.cons_solid.rank(ascending=False,method="min"); B["model_rank"]=B.model_solid.rank(ascending=False,method="min")
B=B.sort_values(["cons_solid"],ascending=False)
pd.set_option('display.width',250)
print(B[["name","consensus_slot","slot_is_bound","cons_round","cons_solid","cons_elite","model_pick","model_round","model_solid","model_elite","gap_flag","rookie_blend","rookie_round","rec_pg"]].round(2).to_string(index=False))
B.to_csv('board.csv',index=False)
