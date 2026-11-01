"""RB prospect board, step 4: the board's two tables and the dated CSV.
Reads board.csv and prospects_scored.csv; writes dash_board.csv, dash_sleepers.csv and RB_Prospect_Board_<date>.csv.
Usage: python3 -I tables.py <date YYYY-MM-DD>
"""
import sys, pandas as pd, numpy as np
DATE=sys.argv[1]
B=pd.read_csv('board.csv'); P=pd.read_csv('prospects_scored.csv').set_index('board_name')
B["age_at_draft"]=B.name.map(P.age_draft).round(1); B["age_used"]=B.name.map(P.age_used)
srcmap=lambda r: " · ".join([f"{k} {int(v)}" for k,v in [("NFLMDD",r.nflmdd_rank),("Brugler",r.brugler_rank),("Tice",r.tice_rank)] if pd.notna(v)]) or "Not named on the Oct 3 board (rank 185+ or unranked)"
notes={"Ahmad Hardy":"No 2026 games on file: shot in May, back at practice Oct 26 [Reporting]. Stats are his 2025 season.",
 "Kewan Lacy":"6 games on file in 2026.","Hollywood Smothers":"5 games on file in 2026; his catch rate is a small sample.",
 "LJ Martin":"4 games on file in 2026. Age from PlayerProfiler (to 0.1 year).","Cam Edwards":"4 games on file in 2026 (Michigan State, after UConn).",
 "Aneyas Williams":"Notre Dame is coded non-Power 4, as in the study's training data."}
c=B[B.pool=="consensus"].copy()
def note(r):
    n=notes.get(r["name"],"")
    if r.age_used=="no": n=(n+" " if n else "")+"No birth date found: model odds run without age."
    return n
D=pd.DataFrame({"name":c.name,"school":c.school,"class_2026":c.class_year_2026.map(lambda v:{3:"Jr",4:"Sr"}.get(v,str(v))),
 "age_at_draft":c.age_at_draft,"games_2026":c.games,"catches_pg":c.rec_pg.round(2),"target_share":c.tgt_share.round(3),"rec_yd_share":c.recyd_share.round(3),
 "td_pg":c.td_pg.round(2),"scrim_share":c.scrim_share.round(3),
 "consensus_rank":c.consensus_slot.round(1),"consensus_sources":c.apply(srcmap,axis=1),
 "consensus_round":c.apply(lambda r:"6+" if r.slot_is_bound else str(int(r.cons_round)),axis=1),
 "consensus_solid":c.cons_solid.round(3),"consensus_elite":c.cons_elite.round(3),"consensus_odds_are_ceiling":c.slot_is_bound.map({True:"yes",False:"no"}),
 "model_pick":c.model_pick.round(0),"model_round":c.model_round.map(lambda v:"UDFA" if v>7 else str(int(v))),
 "model_solid":c.model_solid.round(3),"model_elite":c.model_elite.round(3),"model_uses_age":c.age_used,
 "round_gap_flag":c.gap_flag.map({True:"yes",False:"no"}),
 "rookie_rank":c.rookie_blend.round(1),"rookie_round":c.rookie_round.map(lambda v:str(int(v)) if pd.notna(v) else ""),
 "draftsharks_rank":c.ds_rank,"dynastynerds_rank":c.dn_rank})
D["note"]=[note(r) for _,r in c.iterrows()]
D=D.sort_values("consensus_solid",ascending=False); D.to_csv('dash_board.csv',index=False)
s=B[B.pool=="sleeper"].copy(); conf=P.conf
fcs={"Big Sky","Patriot","Pioneer","SWAC","MVFC","Southland","OVC","UAC","NEC","Coastal Athletic","Southern","Big South","MEAC"}
S=pd.DataFrame({"name":s.name,"school":s.school,"conference":s.name.map(conf),"class_2026":s.class_year_2026.map(lambda v:{3:"Jr",4:"Sr"}.get(v,str(v))),
 "age_at_draft":s.age_at_draft,"games_2026":s.games,"catches_pg":s.rec_pg.round(2),"td_pg":s.td_pg.round(2),"scrim_share":s.scrim_share.round(3),
 "model_pick":s.model_pick.round(0),"model_round":s.model_round.astype(int).astype(str),"model_solid":s.model_solid.round(3),"model_elite":s.model_elite.round(3),"model_uses_age":s.age_used})
S["note"]=[" ".join(x for x in ["FCS: production is against weaker opponents than the study's sample." if cf in fcs else "","No birth date found: model odds run without age." if a=="no" else ""] if x) for cf,a in zip(S.conference,S.model_uses_age)]
S=S.sort_values("model_solid",ascending=False); S.to_csv('dash_sleepers.csv',index=False)
pd.concat([D.assign(pool="consensus"),S.assign(pool="model sleeper")]).to_csv(f'RB_Prospect_Board_{DATE}.csv',index=False)
print("rows", len(D), len(S))
