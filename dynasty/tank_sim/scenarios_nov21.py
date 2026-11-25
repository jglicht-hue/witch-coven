import sys; sys.path.insert(0,'/home/claude/sim'); from tank_sim import *
# Overrides (Nov 21; FantasyPros injury feed and news, Nov 21 sweep of every 8+ ppg player on the nine teams)
def ids(nm): return [k for k,v in name.items() if v==nm and any(k in R[r]['players'] for r in R)]
OUT_SEASON=['Michael Wilson','Drake Maye','Jalen Hurts',"Wan'Dale Robinson",'Dameon Pierce','Kyler Murray','Lamar Jackson','Puka Nacua']
OV={'13287':{11:0,12:0,13:0.5}}   # Love (nobodies), IR, 50% Wk 13 (v1.8)
for nm in OUT_SEASON:
    for i in ids(nm): OV[i]={11:0,12:0,13:0,14:0}
for nm in ['Woody Marks','Kenneth Walker III','Omar Cooper','Dontayvion Wicks']:
    for i in ids(nm): OV[i]={11:0}
OV['9756']={11:0,12:0,13:0.3,14:0.6}            # Addison (Pratik), thumb surgery, short-term IR
for i in ids('Josh Jacobs'): OV[i]={11:0,12:0,13:0.5,14:0.9}   # Bpapi99, finger surgery Nov 14, 2-3 weeks
for i in ids('Mike Evans'): OV[i]={11:0.75,12:0.9,13:0.9,14:0.9}  # Disappointments, Q returning (0.79)
for i in ids('Carnell Tate'): OV[i]={11:0.85,12:0.9,13:0.9,14:0.9} # Disappointments, Q returning (0.89)
ALLEN,KELCE,MEYERS,FLOWERS,PRICE='4984','1466','5947','9997','13075'
KELCE_MOVE=[(KELCE,6,9,11),(PRICE,9,6,11)]
PRATIK_SELL=[('3198',3,None,12),('11625',3,None,12),('12634',3,None,12),('3257',3,None,12)]
S=[('Base: Kelce sold, keep the rest',dict(moves=KELCE_MOVE)),
   ('Base, no model error',dict(moves=KELCE_MOVE,err=0)),
   ('Base, 15% error',dict(moves=KELCE_MOVE,err=0.15)),
   ('Base, every other IR player back at his season rate',dict(moves=KELCE_MOVE,ir_return=True)),
   ('Counterfactual: kept Kelce',dict()),
   ('Meyers to jrogers617 before Wk 12',dict(moves=KELCE_MOVE+[(MEYERS,6,11,12)])),
   ('Meyers to Shawesome Sauce before Wk 12',dict(moves=KELCE_MOVE+[(MEYERS,6,4,12)])),
   ('Meyers held to Wk 14 deadline (sold after Wk 13)',dict(moves=KELCE_MOVE+[(MEYERS,6,11,14)])),
   ('Allen -> McBride for Flowers, Wk 12',dict(moves=KELCE_MOVE+[(ALLEN,6,8,12),(FLOWERS,8,6,12)])),
   ('Allen -> Flowers + Meyers sold, Wk 12',dict(moves=KELCE_MOVE+[(ALLEN,6,8,12),(FLOWERS,8,6,12),(MEYERS,6,11,12)])),
   ('Pratik sells Henry, Mitchell, Watkins, Brissett (Wk 12)',dict(moves=KELCE_MOVE+PRATIK_SELL)),
]
if __name__=='__main__':
    print({k:name.get(k) for k in OV})
    rows=[]
    for lab,kw in S:
        o=run(label=lab,overrides=OV,**kw); x=summarize(o); r=o['rids']
        x['nob_po']=o['playoff'][:,r.index(5)].mean(); g_=o['mx'][:,r.index(5)]-o['mx'][:,r.index(6)]
        x['gap_med'],x['gap_p10'],x['gap_p5']=np.median(g_),np.percentile(g_,10),np.percentile(g_,5)
        for k in (1,2,3,4): x[f'us{k}']=(o['slot'][:,r.index(6)]==k).mean()
        x['P_pratik_101']=(o['slot'][:,r.index(3)]==1).mean()
        nob=o['playoff'][:,r.index(5)]; sl=o['slot'][:,r.index(12)]; t4=(sl>=1)&(sl<=4)
        x['t4_nobIn']=t4[nob].mean() if nob.any() else np.nan; x['t4_nobOut']=t4[~nob].mean()
        x['ourMaxFinal_med']=np.median(o['mx'][:,r.index(6)])
        rows.append(x)
    pd.set_option('display.width',400); pd.set_option('display.max_columns',50)
    df=pd.DataFrame(rows).set_index('label').round(3); df.to_csv('/home/claude/sim/results_nov21.csv'); print(df.T.to_string())
