import pandas as pd, numpy as np, re, sys
sys.path.insert(0,'research')
import yprr as Y
def full(y,weeks):
    st=pd.read_csv(f"witch_cache/stats_player_week_{y}.csv",low_memory=False); st=st[(st.season_type=="REG")&st.player_id.notna()&(st.position=="WR")]
    st["k"]=st.player_display_name.map(Y.norm)
    frames=[Y.get(y,w,t) for w in weeks for t in Y.TEAMS]; pf=pd.concat([f for f in frames if f is not None and len(f)])
    tot=pf[pf.name=="Team Total"][["team","week","routes"]].rename(columns={"routes":"team_db"})
    pf=pf[pf.pos=="WR"].drop(columns=["targets","carries"]).copy(); pf["k"]=pf.name.map(Y.norm)
    ids=st.groupby(["team","k"]).player_id.first().reset_index()
    pf=pf.merge(ids,on=["team","k"],how="left")
    # last-name fallback at team level
    st["ln"]=st.k.str.split().str[-1]; l=st.groupby(["team","ln"]).player_id.nunique().reset_index(); l=l[l.player_id==1][["team","ln"]].merge(st.groupby(["team","ln"]).player_id.first().reset_index(),on=["team","ln"])
    pf["ln"]=pf.k.str.split().str[-1]; pf=pf.merge(l.rename(columns={"player_id":"pid2"}),on=["team","ln"],how="left"); pf["player_id"]=pf.player_id.fillna(pf.pid2)
    print(y,"routes with id",int(pf[pf.player_id.notna()].routes.sum()),"of",int(pf.routes.sum()))
    pf=pf[pf.player_id.notna()]
    d=pf.merge(st[["player_id","team","week","targets","receiving_yards","fantasy_points_ppr","player_display_name"]],on=["player_id","team","week"],how="left")
    for c in ["targets","receiving_yards","fantasy_points_ppr"]: d[c]=d[c].fillna(0)
    nm=st.groupby("player_id").player_display_name.first(); d["player"]=d.player_id.map(nm)
    return d.merge(tot,on=["team","week"],how="left")
def agg(d,minr):
    g=d.groupby("player_id").agg(player=("player","first"),routes=("routes","sum"),tgt=("targets","sum"),yds=("receiving_yards","sum"),ppr=("fantasy_points_ppr","sum"),g=("week","nunique"),db=("team_db","sum"))
    g=g[g.routes>=minr].copy(); g["yprr"]=g.yds/g.routes; g["tprr"]=g.tgt/g.routes; g["rsh"]=g.routes/g.db; g["ppg"]=g.ppr/g.g; g["tpg"]=g.tgt/g.g
    return g
a=full(2025,range(1,19))
s=agg(a,250); print("\n2025 season, WRs with 250+ routes: n =",len(s))
print("YPRR percentiles 10/25/50/75/90/95:",s.yprr.quantile([.1,.25,.5,.75,.9,.95]).round(2).tolist())
print("count >=2.0:",int((s.yprr>=2.0).sum()),"| >=1.8:",int((s.yprr>=1.8).sum()),"| >=2.5:",int((s.yprr>=2.5).sum()),"| percentile of 2.0:",round((s.yprr<2.0).mean()*100))
print("top 12 by YPRR:\n",s.sort_values("yprr",ascending=False).head(12)[["player","routes","yprr","tprr","ppg"]].round(2).to_string(index=False))
print("corr season YPRR with PPR/game:",round(s.yprr.corr(s.ppg),2),"| TPRR with PPR/g:",round(s.tprr.corr(s.ppg),2),"| route share with PPR/g:",round(s.rsh.corr(s.ppg),2))
# finish position by yprr band
s["rank"]=s.ppg.rank(ascending=False)
for lo,hi in [(2.5,9),(2.0,2.5),(1.7,2.0),(1.4,1.7),(0,1.4)]:
    x=s[(s.yprr>=lo)&(s.yprr<hi)]; print(f"  YPRR {lo}-{hi}: n={len(x)}, median PPR/g {x.ppg.median():.1f}, share top-24 PPR/g {(x['rank']<=24).mean():.0%}, top-36 {(x['rank']<=36).mean():.0%}")
# early vs rest
e=agg(a[a.week<=3],60); r=agg(a[a.week>=4],150); j=e.join(r,lsuffix="_e",rsuffix="_r",how="inner")
print("\nEarly (Wk1-3, 60+ routes) vs rest (Wk4-18, 150+ routes): n =",len(j))
for c in ["yprr","tprr","rsh","tpg","ppg"]: print(f"  corr early {c} -> rest {c}: {j[c+'_e'].corr(j[c+'_r']):.2f}")
for c in ["yprr","tprr","rsh","tpg"]: print(f"  corr early {c} -> rest PPR/g: {j[c+'_e'].corr(j.ppg_r):.2f}")
hi=j[j.yprr_e>=2.0]; print(f"  early YPRR>=2.0: n={len(hi)}, median rest YPRR {hi.yprr_r.median():.2f}, mean {hi.yprr_r.mean():.2f}, stayed>=2.0 {(hi.yprr_r>=2.0).mean():.0%}, stayed>=1.7 {(hi.yprr_r>=1.7).mean():.0%}, median rest PPR/g {hi.ppg_r.median():.1f}")
lo=j[j.yprr_e<1.0]; print(f"  early YPRR<1.0: n={len(lo)}, median rest YPRR {lo.yprr_r.median():.2f}, reached>=1.7 {(lo.yprr_r>=1.7).mean():.0%}, median rest PPR/g {lo.ppg_r.median():.1f}")
mid=j[(j.yprr_e>=1.8)&(j.yprr_e<2.3)]; print(f"  early YPRR 1.8-2.3: n={len(mid)}, median rest YPRR {mid.yprr_r.median():.2f}, IQR {mid.yprr_r.quantile(.25):.2f}-{mid.yprr_r.quantile(.75):.2f}")
# regression to mean slope
b=np.polyfit(j.yprr_e,j.yprr_r,1); print(f"  rest YPRR = {b[1]:.2f} + {b[0]:.2f} x early YPRR -> early 2.01 predicts {b[1]+b[0]*2.01:.2f}; early 0.78 predicts {b[1]+b[0]*0.78:.2f}")
b2=np.polyfit(j.tprr_e,j.tprr_r,1); print(f"  rest TPRR = {b2[1]:.3f} + {b2[0]:.2f} x early TPRR")
# trend within first three weeks
w=a[a.week<=3].copy(); w=w[w.routes>=15]; w["y"]=w.receiving_yards/w.routes
p=w.pivot_table(index="player_id",columns="week",values="y"); p=p.dropna(); p["slope"]=p[3]-p[1]
k=p.join(j[["yprr_e","yprr_r","ppg_r"]],how="inner"); print("\nTrend test: n =",len(k))
X=np.column_stack([np.ones(len(k)),k.yprr_e,k.slope]); beta,res,_,_=np.linalg.lstsq(X,k.yprr_r,rcond=None)
print(f"  rest YPRR ~ {beta[0]:.2f} + {beta[1]:.2f}*avg + {beta[2]:.3f}*(Wk3-Wk1); corr(slope, rest YPRR | raw) {k.slope.corr(k.yprr_r):.2f}; partial resid corr {np.corrcoef(k.slope, k.yprr_r-(np.polyfit(k.yprr_e,k.yprr_r,1)[0]*k.yprr_e))[0,1]:.2f}")
up=k[(k[1]<k[2])&(k[2]<k[3])]; print(f"  rose each week (n={len(up)}): median early {up.yprr_e.median():.2f}, median rest {up.yprr_r.median():.2f}; everyone else median early {k.drop(up.index).yprr_e.median():.2f}, rest {k.drop(up.index).yprr_r.median():.2f}")
# halves
h1=agg(a[a.week<=9],120); h2=agg(a[a.week>=10],120); hh=h1.join(h2,lsuffix="_1",rsuffix="_2",how="inner")
print("\nHalves (Wk1-9 vs 10-18, 120+ routes each): n =",len(hh), "| YPRR corr",round(hh.yprr_1.corr(hh.yprr_2),2),"| TPRR corr",round(hh.tprr_1.corr(hh.tprr_2),2),"| route share corr",round(hh.rsh_1.corr(hh.rsh_2),2))
# 2026
c=full(2026,range(1,4)); t=agg(c,50); t["rk"]=t.yprr.rank(ascending=False).astype(int); t["trk"]=t.tprr.rank(ascending=False).astype(int)
print("\n2026 Wk1-3, WRs with 50+ routes: n =",len(t),"| median YPRR",round(t.yprr.median(),2),"| count >=2.0:",int((t.yprr>=2).sum()))
print(t[t.player.isin(["Tre Harris","Quentin Johnston","Ladd McConkey","Malik Washington","Dontayvion Wicks","Rashod Bateman","Ted Hurst III","Chris Bell","Ryan Flournoy","Drake London"])][["player","routes","yprr","rk","tprr","trk","rsh"]].round(3).sort_values("rk").to_string(index=False))
# 2025 Johnston & Harris season
print(s[s.player.isin(["Quentin Johnston","Tre Harris","Ladd McConkey"])][["player","routes","yprr","tprr","ppg"]].round(2).to_string(index=False))
