#!/usr/bin/env python3
"""Yards, targets and first downs per route for one player, by week and for the season.
Routes: PFF weekly recap tables. Targets, yards, first downs: nflverse weekly player stats.
  python3 per_route.py "Tre Harris"
  python3 per_route.py "Quentin Johnston" --season 2025
  python3 per_route.py "Mike Williams" --team LAC        # --team only if the name is ambiguous
Needs only pandas. Routes are never estimated: a week with no PFF row is left out and named."""
import argparse, os, re, time, sys, urllib.request
import pandas as pd

ap = argparse.ArgumentParser(); ap.add_argument("name"); ap.add_argument("--team"); ap.add_argument("--season", type=int, default=2026)
a = ap.parse_args(); Y = a.season; CACHE = "witch_cache"; os.makedirs(CACHE, exist_ok=True)
NV = "https://github.com/nflverse/nflverse-data/releases/download"
PFF = "https://raw.githubusercontent.com/llmnj/html_tests/main"
TEAMS = dict(ARI="Arizona_Cardinals", ATL="Atlanta_Falcons", BAL="Baltimore_Ravens", BUF="Buffalo_Bills", CAR="Carolina_Panthers",
    CHI="Chicago_Bears", CIN="Cincinnati_Bengals", CLE="Cleveland_Browns", DAL="Dallas_Cowboys", DEN="Denver_Broncos",
    DET="Detroit_Lions", GB="Green_Bay_Packers", HOU="Houston_Texans", IND="Indianapolis_Colts", JAX="Jacksonville_Jaguars",
    KC="Kansas_City_Chiefs", LA="Los_Angeles_Rams", LAC="Los_Angeles_Chargers", LV="Las_Vegas_Raiders", MIA="Miami_Dolphins",
    MIN="Minnesota_Vikings", NE="New_England_Patriots", NO="New_Orleans_Saints", NYG="New_York_Giants", NYJ="New_York_Jets",
    PHI="Philadelphia_Eagles", PIT="Pittsburgh_Steelers", SEA="Seattle_Seahawks", SF="San_Francisco_49ers",
    TB="Tampa_Bay_Buccaneers", TEN="Tennessee_Titans", WAS="Washington_Commanders")
norm = lambda n: re.sub(r"\s+(jr|sr|ii|iii|iv)$", "", str(n).lower().replace(".", "").replace("'", "").replace("-", " ")).strip()


def fetch(url, name, max_age_h):
    p = os.path.join(CACHE, name)
    if not os.path.exists(p) or time.time() - os.path.getmtime(p) > max_age_h * 3600: urllib.request.urlretrieve(url, p)
    return p


def pff_table(team, week):
    """First table of the PFF recap file: Name, Position, Snaps, Routes Run, Targets, Carries, plus a 'Team Total' row."""
    f = f"{Y}_{week}_{TEAMS[team]}.html"
    try: h = open(fetch(f"{PFF}/{f}", f, 24 * 7), encoding="utf-8", errors="ignore").read()
    except Exception: return None
    t = h[h.find("<table"):h.find("</table>")]
    rows = [[re.sub(r"<[^>]+>", "", c).strip() for c in re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", r, flags=re.S)] for r in t.split("<tr")[1:]]
    d = pd.DataFrame([r for r in rows if len(r) == 6 and r[0] != "Name"], columns=["name", "pos", "snaps", "routes", "targets", "carries"])
    for c in ["snaps", "routes", "targets", "carries"]: d[c] = pd.to_numeric(d[c], errors="coerce")
    return d


f = f"stats_player_week_{Y}.csv"
st = pd.read_csv(fetch(f"{NV}/stats_player/{f}", f, 6), low_memory=False)
st = st[(st.season_type == "REG") & st.player_id.notna()]
c = st[st.player_display_name.map(norm) == norm(a.name)]
if a.team: c = c[c.team == a.team]
if c.player_id.nunique() != 1:
    sys.exit(f"{c.player_id.nunique()} matches for '{a.name}': {c[['player_display_name','team','position']].drop_duplicates().values.tolist()} - check the spelling or pass --team")
me = c.set_index("week"); pos = me.position.iloc[0]; full = me.player_display_name.iloc[0]
team_weeks = st.groupby("team").week.unique()

rows = []
for t in me.team.unique():                       # every week his team played, so a game with routes but no target still counts
    for w in sorted(team_weeks[t]):
        if w in me.index and me.team[w] != t: continue
        d = pff_table(t, int(w)); r = dict(wk=int(w), tm=t, routes=float("nan"), team_routes=float("nan"), note="")
        if d is None: r["note"] = "no PFF table"
        else:
            p = d[d.pos.isin({"RB": ["HB", "FB"], "FB": ["HB", "FB"]}.get(pos, [pos]))]; k = p.name.map(norm)
            hit = p[k == norm(full)]
            if len(hit) != 1: hit = p[k.str.split().str[-1] == norm(full).split()[-1]]
            if len(hit) == 1: r["routes"] = hit.routes.iloc[0]; r["team_routes"] = d.loc[d.name == "Team Total", "routes"].max()
            else: r["note"] = "not in PFF table (did not play, or name mismatch)"
        s = me.loc[w] if w in me.index else None
        r.update(tgt=0 if s is None else int(s.targets), yds=0 if s is None else int(s.receiving_yards),
                 fd=0 if s is None else int(s.receiving_first_downs))
        rows.append(r)
df = pd.DataFrame(rows).sort_values("wk")
ok = df.routes > 0
df["route_sh"] = (df.routes / df.team_routes).where(ok).round(3)
df["tprr"] = (df.tgt / df.routes).where(ok).round(3); df["yprr"] = (df.yds / df.routes).where(ok).round(2); df["fdrr"] = (df.fd / df.routes).where(ok).round(3)
print(f"{full} ({pos}), {Y}")
print(df[["wk", "tm", "routes", "team_routes", "route_sh", "tgt", "yds", "fd", "tprr", "yprr", "fdrr", "note"]].to_string(index=False, na_rep="-"))
g = df[ok]; R = g.routes.sum()
if R: print(f"Season, weeks {g.wk.tolist()}: {R:.0f} routes | TPRR {g.tgt.sum()/R:.3f} | YPRR {g.yds.sum()/R:.2f} | first downs per route {g.fd.sum()/R:.3f}")
else: print("No published routes found, so no per-route stats. Never estimate routes.")
left = df[~ok & (df.tgt > 0)].wk.tolist()
if left: print(f"WARNING: weeks {left} have targets but no route count and are left out of the season line.")
