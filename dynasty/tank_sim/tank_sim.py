"""Tank sim v2 (Nov 17, 2026). Weeks LAST+1..14, all 12 teams. Method = Tank Plan v1.6 section 5.
Inputs: /home/claude/sleeper/{rosters,users,matchups_<wk>}.json ; nflverse stats_player_week_2026.csv, games.csv, db_playerids.csv"""
import json, sys, warnings; warnings.filterwarnings('ignore')
import json, sys, numpy as np, pandas as pd
sys.path.insert(0,'/home/claude/sim'); from engine import scores, idmap
import os
SL=os.environ.get('SLEEPER_DIR','/home/claude/sleeper')
LAST=int(os.environ.get('LAST_WEEK','10'))   # latest COMPLETE week (check games.csv)
WEEKS=list(range(LAST+1,15))                # weeks to simulate, through Week 14
g,name,pos,dpteam=idmap()
s=scores(); s=s[s.week<=LAST]
games=pd.read_csv('/home/claude/data/games.csv'); games=games[(games.season==2026)&(games.game_type=='REG')]
def team_weeks(t): return sorted(set(games[(games.home_team==t)|(games.away_team==t)].week))
R={r['roster_id']:r for r in json.load(open(f'{SL}/rosters.json'))}
U={u['user_id']:u for u in json.load(open(f'{SL}/users.json'))}
TEAMNAME={rid:((U[r['owner_id']]['metadata'].get('team_name') or '').strip() or U[r['owner_id']]['display_name']) for rid,r in R.items()}
WINS={rid:r['settings']['wins'] for rid,r in R.items()}
PF={rid:r['settings']['fpts']+r['settings']['fpts_decimal']/100 for rid,r in R.items()}
MAX={rid:r['settings']['ppts']+r['settings']['ppts_decimal']/100 for rid,r in R.items()}
RATIO={rid:PF[rid]/MAX[rid] for rid in R}
SCHED={}
for w in WEEKS:
    m=json.load(open(f'{SL}/matchups_{w}.json')); d={}
    for r in m: d.setdefault(r['matchup_id'],[]).append(r['roster_id'])
    SCHED[w]=list(d.values())
def player_profile(sid, ir, overrides):
    gid=g.get(sid); p=pos.get(sid)
    rows=s[s.player_id==gid] if gid else s.iloc[0:0]
    pool=rows.pts.values
    if len(rows): t=rows.sort_values('week').team.iloc[-1]
    else: t=None
    if t is None or len(pool)==0: return p,np.zeros(1),{w:0.0 for w in WEEKS}
    tw=[w for w in team_weeks(t)]; played=[w for w in tw if w<=LAST]
    lastg=max(played); rate=min(1.0,len(rows)/len(played))
    played_last=(lastg in set(rows[rows.team==t].week))
    base=0.95 if played_last else rate
    if ir and not played_last: base=0.0
    av={w:(base if w in tw else 0.0) for w in WEEKS}
    for w,v in overrides.get(sid,{}).items(): av[w]=v if w in tw else 0.0
    return p,pool,av
def build(moves=(), overrides=None, ir_return=False):
    """moves: list of (sid, from_rid, to_rid or None, first_week)"""
    overrides=overrides or {}
    teams={}
    for rid,r in R.items():
        ir=set(r['reserve'] or [])
        teams[rid]=[(sid,)+player_profile(sid, (sid in ir) and not ir_return, overrides) for sid in r['players'] if pos.get(sid) in ('QB','RB','WR','TE')]
    own={rid:{w:{x[0] for x in teams[rid]} for w in WEEKS} for rid in R}
    prof={x[0]:x for rid in teams for x in teams[rid]}
    for sid,fr,to,wk in moves:
        if sid not in prof:
            prof[sid]=(sid,)+player_profile(sid,False,overrides)
        for w in WEEKS:
            if w>=wk:
                own[fr][w].discard(sid)
                if to: own[to][w].add(sid)
    return prof,own
def best_matrix(S,P):
    P=np.array(P); tot=np.zeros(S.shape[0]); rest=[]
    for p,n in (('QB',1),('RB',2),('WR',3),('TE',1)):
        x=-np.sort(-S[:,P==p],axis=1) if (P==p).any() else np.zeros((S.shape[0],0))
        k=min(n,x.shape[1]); tot+=x[:,:k].sum(1)
        if p!='QB': rest.append(x[:,k:])
    r=np.concatenate(rest,1) if rest else np.zeros((S.shape[0],0))
    r=-np.sort(-r,axis=1); return tot+r[:,:2].sum(1)
def run(moves=(), err=0.13, N=20000, seed=7, overrides=None, label='', ir_return=False):
    rng=np.random.default_rng(seed)
    prof,own=build(moves,overrides,ir_return)
    rids=sorted(R); E=1+rng.normal(0,err,(N,len(rids))) if err else np.ones((N,len(rids)))
    wkmax={}
    draws={}
    for sid,(sid_,p,pool,av) in prof.items():
        for w in WEEKS:
            play=rng.random(N)<av[w]; sc=pool[rng.integers(0,len(pool),N)]
            draws[(sid,w)]=np.where(play,sc,0.0)
    for i,rid in enumerate(rids):
        for w in WEEKS:
            ps=sorted(own[rid][w]); 
            S=np.stack([draws[(x,w)] for x in ps],1); P=[prof[x][1] for x in ps]
            wkmax[(rid,w)]=best_matrix(S,P)*E[:,i]
    wins=np.array([[WINS[r]]*N for r in rids],float).T; pf=np.array([[PF[r]]*N for r in rids]).T
    mx=np.array([[MAX[r]]*N for r in rids]).T
    for w in WEEKS:
        M=np.stack([wkmax[(r,w)] for r in rids],1); P_=M*np.array([RATIO[r] for r in rids])
        mx+=M; pf+=P_
        rank=(-P_).argsort(1).argsort(1); wins+=(rank<6)
        for a,b in SCHED[w]:
            ia,ib=rids.index(a),rids.index(b)
            wins[:,ia]+=P_[:,ia]>P_[:,ib]; wins[:,ib]+=P_[:,ib]>P_[:,ia]
    key=wins*1e5+pf
    order=(-key).argsort(1); playoff=np.zeros_like(wins,bool)
    np.put_along_axis(playoff,order[:,:6],True,1)
    mxn=np.where(playoff,np.inf,mx); dorder=mxn.argsort(1)[:,:6]
    slot=np.full((N,len(rids)),0)
    for k in range(6): slot[np.arange(N),dorder[:,k]]=k+1
    return dict(label=label,slot=slot,playoff=playoff,mx=mx,rids=rids,wkmax=wkmax)
def summarize(o):
    rids=o['rids']; i6=rids.index(6); i12=rids.index(12); sl=o['slot']
    out={'label':o['label'],'P(1.01)':(sl[:,i6]==1).mean(),'our max/wk':np.mean([o['wkmax'][(6,w)].mean() for w in WEEKS])}
    for k in range(1,7): out[f'D{k}']=(sl[:,i12]==k).mean()
    out['D top4']=((sl[:,i12]>=1)&(sl[:,i12]<=4)).mean()
    for r in (9,4,2,1): out[f'miss_{r}']=1-o['playoff'][:,rids.index(r)].mean()
    return out
