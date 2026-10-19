#!/usr/bin/env python3
"""Benchmarks v2 - step 4: per-route bands for TE and RB (and a WR re-check) from 2025 PFF weekly recap tables.
Same source and matching as benchmarks v1.1 (yprr.py): PFF tables carry no ids, so rows are matched to nflverse by
normalized name within team-week, then by unique last name within team-week. PFF 'HB' and 'FB' count as RB.
Pools: WR 250+ routes, TE 200+ routes, RB 100+ routes. Finish = PPR-per-game rank among all 2025 position players with 8+ games.
  python3 perroute.py > perroute_out.md   (first run downloads ~570 small files)"""
import os, re, urllib.request, concurrent.futures as cf
import pandas as pd, numpy as np
import season as S
TEAMS = dict(ARI="Arizona_Cardinals", ATL="Atlanta_Falcons", BAL="Baltimore_Ravens", BUF="Buffalo_Bills", CAR="Carolina_Panthers", CHI="Chicago_Bears",
    CIN="Cincinnati_Bengals", CLE="Cleveland_Browns", DAL="Dallas_Cowboys", DEN="Denver_Broncos", DET="Detroit_Lions", GB="Green_Bay_Packers",
    HOU="Houston_Texans", IND="Indianapolis_Colts", JAX="Jacksonville_Jaguars", KC="Kansas_City_Chiefs", LA="Los_Angeles_Rams", LAC="Los_Angeles_Chargers",
    LV="Las_Vegas_Raiders", MIA="Miami_Dolphins", MIN="Minnesota_Vikings", NE="New_England_Patriots", NO="New_Orleans_Saints", NYG="New_York_Giants",
    NYJ="New_York_Jets", PHI="Philadelphia_Eagles", PIT="Pittsburgh_Steelers", SEA="Seattle_Seahawks", SF="San_Francisco_49ers", TB="Tampa_Bay_Buccaneers",
    TEN="Tennessee_Titans", WAS="Washington_Commanders")
norm = lambda n: re.sub(r"\s+(jr|sr|ii|iii|iv|v)$", "", str(n).lower().replace(".", "").replace("'", "").replace("-", " ")).strip()
DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pff"); os.makedirs(DIR, exist_ok=True)
def get(y, w, t):
    f = f"{y}_{w}_{TEAMS[t]}.html"; p = os.path.join(DIR, f)
    if not os.path.exists(p):
        try: urllib.request.urlretrieve(f"https://raw.githubusercontent.com/llmnj/html_tests/main/{f}", p)
        except Exception: return None
    h = open(p, encoding="utf-8", errors="ignore").read(); tb = h[h.find("<table"):h.find("</table>")]
    rows = [[re.sub(r"<[^>]+>", "", c).strip() for c in re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", r, flags=re.S)] for r in tb.split("<tr")[1:]]
    d = pd.DataFrame([r for r in rows if len(r) == 6 and r[0] != "Name"], columns=["name", "ppos", "snaps", "routes", "ptgt", "pcar"])
    for c in ["snaps", "routes", "ptgt", "pcar"]: d[c] = pd.to_numeric(d[c], errors="coerce")
    d["posteam"] = t; d["week"] = w; return d
Y = 2025
with cf.ThreadPoolExecutor(16) as ex: res = list(ex.map(lambda a: get(*a), [(Y, w, t) for w in range(1, 19) for t in TEAMS]))
pf = pd.concat([r for r in res if r is not None and len(r)]); print(f"PFF team-weeks loaded: {pf[pf.name=='Team Total'].shape[0]} of {18*32} (byes have no table)")
tot = pf[pf.name == "Team Total"][["posteam", "week", "routes"]].rename(columns={"routes": "tm_routes"})
pf = pf[pf.ppos.isin(["WR", "TE", "HB", "FB"])].copy(); pf["k"] = pf.name.map(norm)
pw = S.load(); pw = pw[pw.season == Y].copy(); pw["k"] = pw.player_display_name.map(norm); pw["ln"] = pw.k.str.split().str[-1]
m = pf.merge(pw[["player_id", "posteam", "week", "k"]], on=["posteam", "week", "k"], how="left")
un = m[m.player_id.isna()].drop(columns="player_id"); un["ln"] = un.k.str.split().str[-1]
cnt = pw.groupby(["posteam", "week", "ln"]).player_id.nunique().rename("n").reset_index()
one = pw.merge(cnt, on=["posteam", "week", "ln"]); one = one[one.n == 1][["player_id", "posteam", "week", "ln"]]
fix = un.merge(one, on=["posteam", "week", "ln"], how="left")
m = pd.concat([m[m.player_id.notna()], fix[fix.player_id.notna()].drop(columns="ln")])
lost = fix[fix.player_id.isna()]
print(f"PFF WR/TE/HB/FB rows {len(pf)}, routes {int(pf.routes.sum())}; matched routes {int(m.routes.sum())}; unmatched rows {len(lost)} with {int(lost.routes.sum())} routes")
r = m.groupby(["player_id", "posteam", "week"]).agg(routes=("routes", "sum")).reset_index()
x = pw.merge(r, on=["player_id", "posteam", "week"], how="left").merge(tot, on=["posteam", "week"], how="left")
x = x[x.routes.fillna(0) > 0]
g = x.groupby("player_id").agg(name=("player_display_name", "first"), pos=("position", "first"), routes=("routes", "sum"), tm_routes=("tm_routes", "sum"),
     tgt=("tgt", "sum"), yds=("receiving_yards", "sum"), fd=("receiving_first_downs", "sum"), g=("week", "nunique")).reset_index()
g["yprr"] = g.yds / g.routes; g["tprr"] = g.tgt / g.routes; g["fdrr"] = g.fd / g.routes; g["rsh"] = g.routes / g.tm_routes
fin = S.ranked(S.agg(S.load()))[lambda d: d.season == Y][["player_id", "fin", "ppg"]]
g = g.merge(fin, on="player_id", how="left")
P = lambda v: f"{v:.0%}"
for pos, minr, specs in [("WR", 250, [("yprr", [2.5, 2.0, 1.7, 1.4]), ("tprr", [.27, .23, .20, .17]), ("fdrr", [.12, .10, .085, .07])]),
                         ("TE", 200, [("yprr", [2.0, 1.7, 1.4, 1.1]), ("tprr", [.24, .21, .18, .15]), ("fdrr", [.10, .085, .07, .055]), ("rsh", [.75, .60, .45])]),
                         ("RB", 100, [("yprr", [1.6, 1.3, 1.0]), ("tprr", [.25, .20, .15]), ("fdrr", [.07, .05, .035]), ("rsh", [.50, .40, .30])])]:
    z = g[(g.pos == pos) & (g.routes >= minr)]
    print(f"\n### {pos}, 2025, {minr}+ routes (n = {len(z)})")
    for c, cuts in specs:
        q = z[c].quantile([.1, .25, .5, .75, .9, .95]).round(3).tolist()
        print(f"\n#### {c} - percentiles 10/25/50/75/90/95: {q}; corr with PPR/g {z[c].corr(z.ppg):.2f}")
        print("| Band | Players | Median PPR/g | Top 12 | Top 24 | Top 36 |\n|---|---|---|---|---|---|")
        e = sorted(cuts, reverse=True); f = (lambda v: f"{v:.0%}") if c == "rsh" else (lambda v: f"{v:.3g}")
        for i, lo in enumerate(e + [-1]):
            hi = e[i - 1] if i else 9
            y = z[(z[c] >= lo) & (z[c] < hi)]
            lab = f(lo) + "+" if i == 0 else (f"{f(lo)} to {f(hi)}" if lo >= 0 else f"under {f(e[-1])}")
            print(f"| {lab} | {len(y)} | {y.ppg.median():.1f} | {P((y.fin<=12).mean())} | {P((y.fin<=24).mean())} | {P((y.fin<=36).mean())} |")
    if pos != "WR":
        print("Top 12 by YPRR:", z.sort_values("yprr", ascending=False).head(12)[["name", "routes", "yprr", "tprr", "fdrr", "ppg"]].round(3).to_string(index=False))
g.to_parquet(os.path.join(S.D, "perroute_2025.parquet"), index=False)
