import os, re, sys, time, urllib.request, concurrent.futures as cf
import pandas as pd, numpy as np
NV="https://github.com/nflverse/nflverse-data/releases/download"
TEAMS=dict(ARI="Arizona_Cardinals",ATL="Atlanta_Falcons",BAL="Baltimore_Ravens",BUF="Buffalo_Bills",CAR="Carolina_Panthers",CHI="Chicago_Bears",CIN="Cincinnati_Bengals",CLE="Cleveland_Browns",DAL="Dallas_Cowboys",DEN="Denver_Broncos",DET="Detroit_Lions",GB="Green_Bay_Packers",HOU="Houston_Texans",IND="Indianapolis_Colts",JAX="Jacksonville_Jaguars",KC="Kansas_City_Chiefs",LA="Los_Angeles_Rams",LAC="Los_Angeles_Chargers",LV="Las_Vegas_Raiders",MIA="Miami_Dolphins",MIN="Minnesota_Vikings",NE="New_England_Patriots",NO="New_Orleans_Saints",NYG="New_York_Giants",NYJ="New_York_Jets",PHI="Philadelphia_Eagles",PIT="Pittsburgh_Steelers",SEA="Seattle_Seahawks",SF="San_Francisco_49ers",TB="Tampa_Bay_Buccaneers",TEN="Tennessee_Titans",WAS="Washington_Commanders")
norm=lambda n: re.sub(r"\s+(jr|sr|ii|iii|iv)$","",str(n).lower().replace(".","").replace("'","").replace("-"," ")).strip()
os.makedirs("research/pff",exist_ok=True)
def get(y,w,t):
    f=f"{y}_{w}_{TEAMS[t]}.html"; p=f"research/pff/{f}"
    if not os.path.exists(p):
        try: urllib.request.urlretrieve(f"https://raw.githubusercontent.com/llmnj/html_tests/main/{f}",p)
        except Exception as e: return None
    h=open(p,encoding="utf-8",errors="ignore").read()
    t_=h[h.find("<table"):h.find("</table>")]
    rows=[[re.sub(r"<[^>]+>","",c).strip() for c in re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>",r,flags=re.S)] for r in t_.split("<tr")[1:]]
    d=pd.DataFrame([r for r in rows if len(r)==6 and r[0]!="Name"],columns=["name","pos","snaps","routes","targets","carries"])
    for c in ["snaps","routes","targets","carries"]: d[c]=pd.to_numeric(d[c],errors="coerce")
    d["team"]=t; d["week"]=w; d["season"]=y
    return d
def load(y,weeks):
    fn=f"stats_player_week_{y}.csv"; p=f"witch_cache/{fn}"
    if not os.path.exists(p): urllib.request.urlretrieve(f"{NV}/stats_player/{fn}",p)
    st=pd.read_csv(p,low_memory=False); st=st[(st.season_type=="REG")&st.player_id.notna()]
    jobs=[(y,w,t) for w in weeks for t in TEAMS]
    with cf.ThreadPoolExecutor(16) as ex: res=list(ex.map(lambda a:get(*a),jobs))
    got=[r for r in res if r is not None and len(r)]
    pf=pd.concat(got); print(y,"PFF team-weeks loaded",len(got),"of",len(jobs))
    tot=pf[pf.name=="Team Total"][["team","week","routes"]].rename(columns={"routes":"team_db"})
    pf=pf[(pf.pos=="WR")].copy(); pf["k"]=pf.name.map(norm)
    s=st[st.position=="WR"][["player_id","player_display_name","team","week","targets","receptions","receiving_yards","receiving_tds","fantasy_points_ppr"]].copy(); s["k"]=s.player_display_name.map(norm)
    m=pf.merge(s,on=["team","week","k"],how="left",suffixes=("_pff",""))
    # fallback: unique last name within team-week
    un=m[m.player_id.isna()].copy()
    s["ln"]=s.k.str.split().str[-1]; cnt=s.groupby(["team","week","ln"]).size().rename("n").reset_index()
    s1=s.merge(cnt,on=["team","week","ln"]); s1=s1[s1.n==1]
    un["ln"]=un.k.str.split().str[-1]
    fix=un[["team","week","name","ln","routes","targets_pff"]].merge(s1,on=["team","week","ln"],how="left")
    m=m[m.player_id.notna()]
    fixed=fix[fix.player_id.notna()]
    fixed=fixed.rename(columns={"targets":"targets"})
    cols=["player_id","player_display_name","team","week","routes","targets","receptions","receiving_yards","fantasy_points_ppr"]
    out=pd.concat([m[cols],fixed[cols]])
    # routes with no stat row = 0 yards (no target): keep them as zero-production routes
    zero=fix[fix.player_id.isna()]
    print(y,"WR rows",len(pf),"matched",len(out),"unmatched (no stat row, usually 0 targets)",len(zero),"unmatched routes",int(zero.routes.sum()),"of",int(pf.routes.sum()))
    out=out.merge(tot,on=["team","week"],how="left")
    return out
if __name__=="__main__":
    a=load(2025,range(1,19)); a.to_csv("research/wr2025.csv",index=False)
    b=load(2026,range(1,4)); b.to_csv("research/wr2026.csv",index=False)
