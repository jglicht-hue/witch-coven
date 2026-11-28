#!/usr/bin/env python3
"""v1 - one player's usage as a small benchmark table: each stat with its percentile among past seasons at his position.
  python3 v1_witch_bench.py "Antonio Williams"                 # this season
  python3 v1_witch_bench.py "Antonio Williams" --since 8       # adds a column for Weeks 8 on (the current-role window)
  python3 v1_witch_bench.py "Ollie Gordon II" --team MIA
Percentile: where his figure ranks among full seasons by players at his position with 8+ games (2018-2025; first-read share
2022-2025). Before ranking, the figure is adjusted for how many games it rests on (bench_fit.csv: what a player's first n
games said about the rest of his season), so a hot 4-game stretch isn't ranked as if it were a full season.
Route share ranks among 2025 seasons with 8+ games (adjusted with snap share's fit); per-route stats among 2025 seasons with WR 250+, TE 200+ or RB 100+
routes, unadjusted, and only once he has the route minimum (180 routes through Week 7, 250 from Week 8).
Below a minimum the cell reads "not enough ... to confidently judge yet (X of N)".
Reads bench_fit.csv and bench_pct.csv from this folder. Downloads are cached in ./witch_cache (nflverse 6 h, PFF 7 days),
the same cache as the other coven scripts."""
import argparse, os, re, sys, time, urllib.request
import numpy as np, pandas as pd

ap = argparse.ArgumentParser()
ap.add_argument("name"); ap.add_argument("--team"); ap.add_argument("--since", type=int); ap.add_argument("--through", type=int)
a = ap.parse_args()
Y = 2026; CACHE = "witch_cache"; os.makedirs(CACHE, exist_ok=True); H = os.path.dirname(os.path.abspath(__file__))
NV = "https://github.com/nflverse/nflverse-data/releases/download"
PFF = ["https://raw.githubusercontent.com/llmnj/html_tests/main", "https://llmnj.github.io/html_tests"]
TEAMS = dict(ARI="Arizona_Cardinals", ATL="Atlanta_Falcons", BAL="Baltimore_Ravens", BUF="Buffalo_Bills", CAR="Carolina_Panthers",
    CHI="Chicago_Bears", CIN="Cincinnati_Bengals", CLE="Cleveland_Browns", DAL="Dallas_Cowboys", DEN="Denver_Broncos",
    DET="Detroit_Lions", GB="Green_Bay_Packers", HOU="Houston_Texans", IND="Indianapolis_Colts", JAX="Jacksonville_Jaguars",
    KC="Kansas_City_Chiefs", LA="Los_Angeles_Rams", LAC="Los_Angeles_Chargers", LV="Las_Vegas_Raiders", MIA="Miami_Dolphins",
    MIN="Minnesota_Vikings", NE="New_England_Patriots", NO="New_Orleans_Saints", NYG="New_York_Giants", NYJ="New_York_Jets",
    PHI="Philadelphia_Eagles", PIT="Pittsburgh_Steelers", SEA="Seattle_Seahawks", SF="San_Francisco_49ers",
    TB="Tampa_Bay_Buccaneers", TEN="Tennessee_Titans", WAS="Washington_Commanders")
norm = lambda n: re.sub(r"\s+(jr|sr|ii|iii|iv)$", "", str(n).lower().replace(".", "").replace("'", "").replace("-", " ")).strip()


def fetch(url, f, hours):
    p = os.path.join(CACHE, f)
    if not os.path.exists(p) or time.time() - os.path.getmtime(p) > hours * 3600:
        urllib.request.urlretrieve(url, p + ".tmp"); os.replace(p + ".tmp", p)
    return p


def nv(tag, f, **kw): return pd.read_csv(fetch(f"{NV}/{tag}/{f}", f, 6), low_memory=False, **kw)


def pff_table(team, week):
    f = f"{Y}_{week}_{TEAMS[team]}.html"; h = None
    for base in PFF:
        try: h = open(fetch(f"{base}/{f}", f, 24 * 7), encoding="utf-8", errors="ignore").read(); break
        except Exception: continue
    if h is None: return None
    t = h[h.find("<table"):h.find("</table>")]
    rows = [[re.sub(r"<[^>]+>", "", c).strip() for c in re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", r, flags=re.S)] for r in t.split("<tr")[1:]]
    d = pd.DataFrame([r for r in rows if len(r) == 6 and r[0] != "Name"], columns=["name", "pos", "snaps", "routes", "targets", "carries"])
    for c in ["snaps", "routes", "targets", "carries"]: d[c] = pd.to_numeric(d[c], errors="coerce")
    return d


def my_row(d, name, pos, snaps):
    d = d[d.pos.isin({"RB": ["HB", "FB"], "FB": ["HB", "FB"]}.get(pos, [pos]))]; k = d.name.map(norm)
    for mask in (k == norm(name), k.str.split().str[-1] == norm(name).split()[-1], (d.snaps - snaps).abs() <= 1):
        if mask.sum() == 1: return d[mask].iloc[0]
    return None


st = nv("stats_player", f"stats_player_week_{Y}.csv"); st = st[(st.season_type == "REG") & st.player_id.notna()]
sn = nv("snap_counts", f"snap_counts_{Y}.csv"); sn = sn[sn.game_type == "REG"]
pb = nv("pbp", f"play_by_play_{Y}.csv", usecols=["game_id", "play_id", "season_type", "week", "posteam", "play_type", "two_point_attempt",
        "receiver_player_id", "rusher_player_id", "yardline_100", "air_yards"]); pb = pb[pb.season_type == "REG"]
pl = nv("players", "players.csv", usecols=["gsis_id", "pfr_id"])
c = st[st.player_display_name.map(norm) == norm(a.name)]
if a.team: c = c[c.team == a.team]
ids = c.player_id.unique()
if len(ids) != 1: sys.exit(f"{len(ids)} matches: {c[['player_id','team','position']].drop_duplicates().values.tolist()} - pass --team")
gid = ids[0]; me = st[st.player_id == gid].set_index("week"); pos = me.position.iloc[0]; full = me.player_display_name.iloc[0]
if pos not in ("WR", "TE", "RB"): sys.exit(f"{full} is a {pos}; this table covers WR, TE and RB")
pfr = pl.loc[pl.gsis_id == gid, "pfr_id"].dropna()
s = sn[sn.pfr_player_id == pfr.iloc[0]] if len(pfr) else sn[(sn.player.map(norm) == norm(full)) & sn.team.isin(me.team.unique())]
s = s[s.offense_snaps > 0].set_index("week")

ok = pb.two_point_attempt.ne(1)
tg = pb[ok & (pb.play_type == "pass") & pb.receiver_player_id.notna()].copy()
ca = pb[ok & (pb.play_type == "run") & pb.rusher_player_id.notna()].copy()
tg["rz"] = tg.yardline_100 <= 20; tg["ez"] = tg.air_yards.notna() & (tg.air_yards >= tg.yardline_100)
ca["rz"] = ca.yardline_100 <= 20; ca["i5"] = ca.yardline_100 <= 5
k = ["posteam", "week"]
team = pd.concat([tg.groupby(k).size().rename("tm_tgt"), tg.groupby(k).rz.sum().rename("tm_rz_tgt"),
                  ca.groupby(k).size().rename("tm_car"), ca.groupby(k).rz.sum().rename("tm_rz_car"), ca.groupby(k).i5.sum().rename("tm_i5")], axis=1)
mt, mc = tg[tg.receiver_player_id == gid], ca[ca.rusher_player_id == gid]
try:
    ftn = nv("ftn_charting", f"ftn_charting_{Y}.csv", usecols=["nflverse_game_id", "nflverse_play_id", "read_thrown"])
    ft = tg.merge(ftn, left_on=["game_id", "play_id"], right_on=["nflverse_game_id", "nflverse_play_id"])
    ft["fr"] = ft.read_thrown.astype(str).isin(["1", "1.0"]); charted = set(zip(ft.posteam, ft.week))
    tfr = ft[ft.fr].groupby(k).size()
except Exception as e:
    ft = None; charted = set(); print("FTN charting not loaded:", e)

rows = []
for w in sorted(set(s.index) | set(me.index)):
    if a.through and w > a.through: continue
    t = s.team.get(w, me.team.get(w)); snaps = s.offense_snaps.get(w, 0); x, y = mt[mt.week == w], mc[mc.week == w]
    tm = team.loc[(t, w)] if (t, w) in team.index else pd.Series(0, index=team.columns)
    r = dict(wk=int(w), snap=s.offense_pct.get(w, np.nan), tgt=len(x), rz_tgt=int(x.rz.sum()), ez=int(x.ez.sum()), car=len(y),
             rz_car=int(y.rz.sum()), i5=int(y.i5.sum()), yds=me.receiving_yards.get(w, 0), fd=me.receiving_first_downs.get(w, 0),
             routes=np.nan, tm_routes=np.nan, fr=np.nan, tm_fr=np.nan, **tm.to_dict())
    if (t, w) in charted:
        r["fr"] = int(((ft.receiver_player_id == gid) & (ft.week == w) & ft.fr).sum()); r["tm_fr"] = int(tfr.get((t, w), 0))
    if snaps:
        d = pff_table(t, int(w)); row = None if d is None else my_row(d, full, pos, snaps)
        if row is not None: r["routes"] = row.routes; r["tm_routes"] = d.loc[d.name == "Team Total", "routes"].max()
    rows.append(r)
df = pd.DataFrame(rows)
last_wk = int(pb.week.max()); route_min = 180 if last_wk <= 7 else 250

F = pd.read_csv(os.path.join(H, "bench_fit.csv")); Q = pd.read_csv(os.path.join(H, "bench_pct.csv"))


def pctile(stat, v, n=None, regular=True):
    if v is None or not np.isfinite(v): return None
    if n is not None:                                   # adjust for the games it rests on (route share borrows snap share's fit)
        f = F[(F.pos == pos) & (F.stat == ("snap" if stat == "rsh" else stat)) & (F.pool == ("regulars" if regular else "all")) & (F.n == min(max(n, 2), 11))]
        if len(f): v = f.a.iloc[0] + f.b.iloc[0] * v
    q = Q[(Q.pos == pos) & (Q.stat == stat)].sort_values("p")
    p = float(np.interp(v, q.value, q.p)); p = int(round(min(max(p, 1), 99)))
    return f"{p}{'th' if 10 <= p % 100 <= 20 else {1: 'st', 2: 'nd', 3: 'rd'}.get(p % 10, 'th')}"


def short(word, have, need): return f"not enough {word} to confidently judge yet ({have:.0f} of {need})"


def column(d):
    n = len(d); reg = d.snap.mean() >= 0.5; out = {}
    def share(stat, num, den, word, cnt, need=20):
        D = d[den].sum()
        if not D: return None
        v = d[num].sum() / D
        return (v, pctile(stat, v, n, reg) if cnt >= need else short(word, cnt, need))
    out["Snap share"] = (d.snap.mean(), pctile("snap", d.snap.mean(), n, reg))
    dr = d[d.routes.notna()]
    if len(dr) and dr.tm_routes.sum():
        out["Route share"] = (dr.routes.sum() / dr.tm_routes.sum(), pctile("rsh", dr.routes.sum() / dr.tm_routes.sum(), len(dr), reg))
    T, C = d.tgt.sum(), d.car.sum()
    if pos in ("WR", "TE"):
        out["Target share"] = share("tgt_sh", "tgt", "tm_tgt", "targets", T)
        dc = d[d.tm_fr.notna()]
        if len(dc) and dc.tm_fr.sum():
            v = dc.fr.sum() / dc.tm_fr.sum(); tc = dc.tgt.sum()
            out["First-read share"] = (v, pctile("fr_sh", v, len(dc), reg) if tc >= 20 else short("targets", tc, 20))
        out["Red-zone target share"] = share("rz_tgt_sh", "rz_tgt", "tm_rz_tgt", "red-zone looks", d.tm_rz_tgt.sum())
        out["End-zone targets per game"] = (d.ez.sum() / n, pctile("ezpg", d.ez.sum() / n, n, reg) if T >= 20 else short("targets", T, 20))
    else:
        out["Carry share"] = share("car_sh", "car", "tm_car", "carries", C)
        out["Red-zone carry share"] = share("rz_car_sh", "rz_car", "tm_rz_car", "red-zone looks", d.tm_rz_car.sum())
        out["Inside-5 carry share"] = share("i5_sh", "i5", "tm_i5", "red-zone looks", d.tm_rz_car.sum())
        out["Target share"] = share("tgt_sh", "tgt", "tm_tgt", "targets", T)
        wo = (1.28 * d.rz_car.sum() + 2.39 * d.rz_tgt.sum() + 0.47 * (C - d.rz_car.sum()) + 1.54 * (T - d.rz_tgt.sum())) / n
        out["Weighted opportunity per game"] = (wo, pctile("wo", wo, n, reg) if T + C >= 20 else short("touches", T + C, 20))
    R = dr.routes.sum() if len(dr) else 0
    if R:
        for lab, stat, v in (("Targets per route", "tprr", dr.tgt.sum() / R), ("Yards per route", "yprr", dr.yds.sum() / R),
                             ("First downs per route", "fdrr", dr.fd.sum() / R)):
            out[lab] = (v, pctile(stat, v) if R >= route_min else short("routes", R, route_min))
    return out, n, R


FMT = {"Snap share": "{:.0%}", "Route share": "{:.0%}", "Target share": "{:.1%}", "First-read share": "{:.1%}",
       "Red-zone target share": "{:.0%}", "Carry share": "{:.0%}", "Red-zone carry share": "{:.0%}", "Inside-5 carry share": "{:.0%}",
       "End-zone targets per game": "{:.2f}", "Weighted opportunity per game": "{:.1f}", "Targets per route": "{:.3f}",
       "Yards per route": "{:.2f}", "First downs per route": "{:.3f}"}
cols = [("Season", df)]
if a.since: cols.append((f"Wks {a.since}–{int(df.wk.max())}", df[df.wk >= a.since]))
res = [(lab, *column(d), d) for lab, d in cols]
wk = lambda d: f"Wks {int(d.wk.min())}–{int(d.wk.max())}" if len(d) else "no games"
print(f"**{full} ({pos})** — {res[0][2]} games, {wk(df)}" + (f"; window {res[1][2]} games" if a.since else ""))
hdr = "| Stat | " + " | ".join(f"{lab} | Percentile" for lab, *_ in res) + " |"
print(hdr); print("|" + "---|" * (1 + 2 * len(res)))
for stat in res[0][1]:
    cells = []
    for lab, out, n, R, d in res:
        v = out.get(stat)
        cells += ["–", "–"] if v is None else [FMT[stat].format(v[0]), v[1] or "–"]
    print(f"| {stat} | " + " | ".join(cells) + " |")
miss = df[(df.snap.notna()) & df.routes.isna()].wk.tolist()
fr_note = f" First-read share from FTN charting, weeks {sorted(int(w) for w in df[df.tm_fr.notna()].wk)}." if pos != "RB" else ""
print(f"\n_Percentile among {pos} seasons with 8+ games, adjusted for games played; route share against 2025, per-route stats against 2025 "
      f"({ {'WR': 250, 'TE': 200, 'RB': 100}[pos] }+ routes). Routes from PFF tables{'; weeks without a table: ' + str(miss) if miss else ''}.{fr_note}_")
