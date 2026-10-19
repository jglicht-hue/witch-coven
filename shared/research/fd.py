import pandas as pd, numpy as np, sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0,'research'); import yprr as Y
def full(y,weeks):
    st=pd.read_csv(f"witch_cache/stats_player_week_{y}.csv",low_memory=False); st=st[(st.season_type=="REG")&st.player_id.notna()&(st.position=="WR")].copy()
    st["k"]=st.player_display_name.map(Y.norm)
    frames=[Y.get(y,w,t) for w in weeks for t in Y.TEAMS]; pf=pd.concat([f for f in frames if f is not None and len(f)])
    tot=pf[pf.name=="Team Total"][["team","week","routes"]].rename(columns={"routes":"team_db"})
    pf=pf[pf.pos=="WR"].drop(columns=["targets","carries"]).copy(); pf["k"]=pf.name.map(Y.norm)
    ids=st.groupby(["team","k"]).player_id.first().reset_index(); pf=pf.merge(ids,on=["team","k"],how="left")
    st["ln"]=st.k.str.split().str[-1]; l=st.groupby(["team","ln"]).player_id.nunique().reset_index(); l=l[l.player_id==1][["team","ln"]].merge(st.groupby(["team","ln"]).player_id.first().reset_index(),on=["team","ln"])
    pf["ln"]=pf.k.str.split().str[-1]; pf=pf.merge(l.rename(columns={"player_id":"pid2"}),on=["team","ln"],how="left"); pf["player_id"]=pf.player_id.fillna(pf.pid2)
    pf=pf[pf.player_id.notna()]
    d=pf.merge(st[["player_id","team","week","targets","receiving_yards","receiving_first_downs","fantasy_points_ppr"]],on=["player_id","team","week"],how="left")
    for c in ["targets","receiving_yards","receiving_first_downs","fantasy_points_ppr"]: d[c]=d[c].fillna(0)
    nm=st.groupby("player_id").player_display_name.first(); d["player"]=d.player_id.map(nm)
    return d.merge(tot,on=["team","week"],how="left")
def agg(d,minr):
    g=d.groupby("player_id").agg(player=("player","first"),routes=("routes","sum"),tgt=("targets","sum"),yds=("receiving_yards","sum"),fd=("receiving_first_downs","sum"),ppr=("fantasy_points_ppr","sum"),g=("week","nunique"))
    g=g[g.routes>=minr].copy(); g["yprr"]=g.yds/g.routes; g["tprr"]=g.tgt/g.routes; g["fdrr"]=g.fd/g.routes; g["ppg"]=g.ppr/g.g
    return g
a=full(2025,range(1,19)); s=agg(a,250)
print("2025 season WRs 250+ routes n=",len(s))
print("1D/route percentiles 10/25/50/75/90/95:",s.fdrr.quantile([.1,.25,.5,.75,.9,.95]).round(3).tolist())
print("TPRR percentiles 10/25/50/75/90/95:",s.tprr.quantile([.1,.25,.5,.75,.9,.95]).round(3).tolist())
print("corr with PPR/g: 1D/RR",round(s.fdrr.corr(s.ppg),2),"YPRR",round(s.yprr.corr(s.ppg),2),"TPRR",round(s.tprr.corr(s.ppg),2),"| corr 1D/RR vs YPRR",round(s.fdrr.corr(s.yprr),2))
s["rank"]=s.ppg.rank(ascending=False)
for lo,hi in [(0.12,9),(0.10,0.12),(0.085,0.10),(0.07,0.085),(0,0.07)]:
    x=s[(s.fdrr>=lo)&(s.fdrr<hi)]; print(f"  1D/RR {lo}-{hi}: n={len(x)}, median PPR/g {x.ppg.median():.1f}, top-24 {(x['rank']<=24).mean():.0%}, top-36 {(x['rank']<=36).mean():.0%}")
print(s.sort_values("fdrr",ascending=False).head(8)[["player","routes","fdrr","yprr","tprr"]].round(3).to_string(index=False))
for lo,hi in [(0.27,9),(0.23,0.27),(0.20,0.23),(0.17,0.20),(0,0.17)]:
    x=s[(s.tprr>=lo)&(s.tprr<hi)]; print(f"  TPRR {lo}-{hi}: n={len(x)}, median PPR/g {x.ppg.median():.1f}, top-24 {(x['rank']<=24).mean():.0%}, top-36 {(x['rank']<=36).mean():.0%}")
e=agg(a[a.week<=3],60); r=agg(a[a.week>=4],150); j=e.join(r,lsuffix="_e",rsuffix="_r",how="inner"); print("early vs rest n=",len(j))
for c in ["fdrr","yprr","tprr"]: print(f"  early {c}: -> rest same stat {j[c+'_e'].corr(j[c+'_r']):.2f} | -> rest PPR/g {j[c+'_e'].corr(j.ppg_r):.2f}")
# combined model
for cols in [["yprr_e"],["tprr_e"],["fdrr_e"],["yprr_e","tprr_e"],["yprr_e","tprr_e","fdrr_e"]]:
    X=np.column_stack([np.ones(len(j))]+[j[c] for c in cols]); b=np.linalg.lstsq(X,j.ppg_r,rcond=None)[0]; p=X@b; print("  R2 rest PPR/g ~",cols,round(1-((j.ppg_r-p)**2).sum()/((j.ppg_r-j.ppg_r.mean())**2).sum(),3))
h1=agg(a[a.week<=9],120); h2=agg(a[a.week>=10],120); hh=h1.join(h2,lsuffix="_1",rsuffix="_2",how="inner"); print("halves n=",len(hh),"1D/RR corr",round(hh.fdrr_1.corr(hh.fdrr_2),2))
c=full(2026,range(1,4)); t=agg(c,50); t["rk"]=t.fdrr.rank(ascending=False,method="min").astype(int)
print("2026 wk1-3 n=",len(t),"median 1D/RR",round(t.fdrr.median(),3))
print(t[t.player.isin(["Tre Harris","Quentin Johnston","Ladd McConkey","Malik Washington","Dontayvion Wicks","Rashod Bateman","Drake London","Zay Flowers"])][["player","routes","fd","fdrr","rk","yprr","tprr"]].round(3).sort_values("rk").to_string(index=False))
w=c[c.player.isin(["Tre Harris","Quentin Johnston"])][["player","week","routes","targets","receiving_yards","receiving_first_downs"]].sort_values(["player","week"]); print(w.to_string(index=False))
