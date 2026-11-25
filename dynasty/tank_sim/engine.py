import pandas as pd, numpy as np, json, os
D='/home/claude/data'; S='/home/claude/sleeper'
def scores():
    s=pd.read_csv(f'{D}/stats_player_week_2026.csv',low_memory=False)
    s=s[s.season_type=='REG']
    f=lambda c: s[c].fillna(0) if c in s else 0
    pts=(f('passing_yards')*0.04+f('passing_tds')*4-f('passing_interceptions')
         +f('passing_2pt_conversions')*2+f('rushing_yards')*0.1+f('rushing_tds')*6
         +f('rushing_2pt_conversions')*2+f('receptions')*1+f('receiving_yards')*0.1
         +f('receiving_tds')*6+f('receiving_2pt_conversions')*2+f('special_teams_tds')*6
         -2*(f('rushing_fumbles_lost')+f('receiving_fumbles_lost')+f('sack_fumbles_lost')))
    s=s.assign(pts=pts.round(2))
    return s[['player_id','player_display_name','position','team','week','pts']]
def idmap():
    ids=pd.read_csv(f'{D}/db_playerids.csv',dtype=str)
    ids=ids[ids.sleeper_id.notna()&ids.gsis_id.notna()]
    return dict(zip(ids.sleeper_id,ids.gsis_id)), dict(zip(ids.sleeper_id,ids.name)), dict(zip(ids.sleeper_id,ids.position)), dict(zip(ids.sleeper_id,ids.team))
SLOTS={'QB':1,'RB':2,'WR':3,'TE':1}
def best(pl):  # pl: list of (pos,pts)
    by={p:sorted([x for q,x in pl if q==p],reverse=True) for p in SLOTS}
    tot=0; rest=[]
    for p,n in SLOTS.items():
        tot+=sum(by[p][:n])
        if p!='QB': rest+=by[p][n:]
    return tot+sum(sorted(rest,reverse=True)[:2])
