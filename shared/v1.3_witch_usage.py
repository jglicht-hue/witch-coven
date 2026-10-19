#!/usr/bin/env python3
"""v1.3 - one player's weekly usage (nflverse), weekly routes (PFF recap tables) and FTN first-read / catchable / drop stats.
Routes are never estimated.
  python3 v1.3_witch_usage.py "Jaxon Smith-Njigba"
  python3 v1.3_witch_usage.py "Bijan Robinson" --team ATL
  python3 v1.3_witch_usage.py "Jaxon Smith-Njigba" --season 2025        # last season, same output
  python3 v1.3_witch_usage.py "Chris Olave" --routes 132 --tprr 0.27     # fallback: a published season total
  python3 v1.3_witch_usage.py "Chris Olave" --pff-base https://new.host/path   # if PFF moves its tables
Downloads are cached in ./witch_cache (nflverse 6 h, PFF tables 7 days). Only the player's own team tables are pulled."""
import argparse, os, re, sys, time, urllib.request
import pandas as pd

ap = argparse.ArgumentParser()
ap.add_argument("name"); ap.add_argument("--team")
ap.add_argument("--routes", type=float); ap.add_argument("--tprr", type=float); ap.add_argument("--through", type=int)
ap.add_argument("--season", type=int, default=2026); ap.add_argument("--pff-base")
a = ap.parse_args()
Y = a.season; CACHE = "witch_cache"; os.makedirs(CACHE, exist_ok=True)
NV = "https://github.com/nflverse/nflverse-data/releases/download"
PFF = ([a.pff_base] if a.pff_base else []) + ["https://raw.githubusercontent.com/llmnj/html_tests/main", "https://llmnj.github.io/html_tests"]
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
    if not os.path.exists(p) or time.time() - os.path.getmtime(p) > max_age_h * 3600:
        urllib.request.urlretrieve(url, p)
    return p


def nv(tag, f, **kw):
    return pd.read_csv(fetch(f"{NV}/{tag}/{f}", f, 6), low_memory=False, **kw)


def pff_table(team, week):
    """PFF recap table for one team-game: name, pos, snaps, routes, targets, carries (+ a 'Team Total' row)."""
    f = f"{Y}_{week}_{TEAMS[team]}.html"; h = None
    for base in PFF:
        try: h = open(fetch(f"{base}/{f}", f, 24 * 7), encoding="utf-8", errors="ignore").read(); break
        except Exception: continue
    if h is None: return None
    t = h[h.find("<table"):h.find("</table>")]
    rows = [[re.sub(r"<[^>]+>", "", c).strip() for c in re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", r, flags=re.S)] for r in t.split("<tr")[1:]]
    d = pd.DataFrame([r for r in rows if len(r) == 6 and r[0] != "Name"], columns=["name", "pos", "snaps", "routes", "targets", "carries"])
    for col in ["snaps", "routes", "targets", "carries"]: d[col] = pd.to_numeric(d[col], errors="coerce")
    return d


def my_row(d, name, pos, snaps):
    """Find the player in a PFF table: exact name, else unique last name, else unique snap match, within his position."""
    d = d[d.pos.isin({"RB": ["HB", "FB"], "FB": ["HB", "FB"]}.get(pos, [pos]))]; k = d.name.map(norm)
    for mask in (k == norm(name), k.str.split().str[-1] == norm(name).split()[-1], (d.snaps - snaps).abs() <= 1):
        if mask.sum() == 1: return d[mask].iloc[0]
    return None


st = nv("stats_player", f"stats_player_week_{Y}.csv"); st = st[(st.season_type == "REG") & st.player_id.notna()]
sn = nv("snap_counts", f"snap_counts_{Y}.csv"); sn = sn[sn.game_type == "REG"]
pb = nv("pbp", f"play_by_play_{Y}.csv", usecols=["game_id", "play_id", "season_type", "week", "posteam", "play_type", "two_point_attempt",
        "receiver_player_id", "rusher_player_id", "yardline_100", "qb_dropback"]); pb = pb[pb.season_type == "REG"]
pl = nv("players", "players.csv", usecols=["gsis_id", "pfr_id"])

c = st[st.player_display_name.map(norm) == norm(a.name)]          # "D.K." and "DK" both match
if a.team: c = c[c.team == a.team]
ids = c.player_id.unique()
if len(ids) != 1:
    sys.exit(f"{len(ids)} matches: {c[['player_id','team','position']].drop_duplicates().values.tolist()} - pass --team")
gid = ids[0]; me = st[st.player_id == gid].set_index("week"); pos = me.position.iloc[0]; full = me.player_display_name.iloc[0]
pfr = pl.loc[pl.gsis_id == gid, "pfr_id"].dropna()
s = sn[sn.pfr_player_id == pfr.iloc[0]] if len(pfr) else sn[(sn.player.map(norm) == norm(full)) & sn.team.isin(me.team.unique())]
if not len(pfr): print("WARNING: no pfr_id in players.csv; joined snap_counts on name+team")
s = s[s.offense_snaps > 0].set_index("week")                      # games played = games with an offensive snap

ok = pb.two_point_attempt.ne(1)                                   # 2-pt tries excluded; no_play/spikes/kneels drop out by play_type
tg = pb[ok & (pb.play_type == "pass") & pb.receiver_player_id.notna()]
ca = pb[ok & (pb.play_type == "run") & pb.rusher_player_id.notna()]
db = pb[ok & pb.play_type.isin(["pass", "run"]) & (pb.qb_dropback == 1)]
tt, tc, td = (x.groupby(["posteam", "week"]).size() for x in (tg, ca, db))
mt, mc = tg[tg.receiver_player_id == gid], ca[ca.rusher_player_id == gid]
kn = pb[(pb.play_type == "qb_kneel") & (pb.rusher_player_id == gid)]
try:    # FTN charting: flags on every target. It lags by a few days, so only charted games are used.
    ftn = nv("ftn_charting", f"ftn_charting_{Y}.csv", usecols=["nflverse_game_id", "nflverse_play_id", "read_thrown", "is_screen_pass",
             "is_catchable_ball", "is_contested_ball", "is_drop", "date_pulled"])
    ft = tg.merge(ftn, left_on=["game_id", "play_id"], right_on=["nflverse_game_id", "nflverse_play_id"])
    ft["fr"] = ft.read_thrown.astype(str).isin(["1", "1.0"])     # 1 = first read in the data (0 is the blank value on runs, kicks, sacks)
    tfr = ft[ft.fr].groupby(["posteam", "week"]).size(); charted = set(zip(ft.posteam, ft.week))
except Exception as e:
    ft = None; charted = set(); print("FTN charting not loaded:", e)

best = s.offense_pct.max() if len(s) else 0
rows = []
for w in sorted(set(s.index) | set(me.index)):
    t = s.team.get(w, me.team.get(w)); x, y = (mt.week == w), (mc.week == w); pct = s.offense_pct.get(w); snaps = s.offense_snaps.get(w, 0)
    r = dict(wk=int(w), tm=t, snaps=snaps, snap_pct=None if pct is None else round(pct * 100), routes=float("nan"), team_db=float("nan"),
        tgt=x.sum(), team_tgt=tt.get((t, w), 0), car=y.sum(), team_car=tc.get((t, w), 0),
        rz_tgt=(x & (mt.yardline_100 <= 20)).sum(), car_i10=(y & (mc.yardline_100 <= 10)).sum(), car_i5=(y & (mc.yardline_100 <= 5)).sum(),
        nv_db=td.get((t, w), 0), kneels=(kn.week == w).sum(), low=bool(pct is not None and best >= 0.5 and pct < 0.6 * best), note="",
        fr_tgt=float("nan"), team_fr=float("nan"))
    if (t, w) in charted:
        r["fr_tgt"] = int(((ft.receiver_player_id == gid) & (ft.week == w) & ft.fr).sum()); r["team_fr"] = int(tfr.get((t, w), 0))
    if snaps and not a.routes:                                    # weekly routes: his own team's PFF table only
        d = pff_table(t, int(w)); row = None if d is None else my_row(d, full, pos, snaps)
        if row is None: r["note"] = "no PFF table" if d is None else "not found in PFF table"
        else:
            r["routes"] = row.routes; r["team_db"] = d.loc[d.name == "Team Total", "routes"].max()
            if abs(row.snaps - snaps) > 2: r["note"] = f"PFF snaps {row.snaps:.0f} differ"
    rows.append(r)
df = pd.DataFrame(rows)
df["tgt_sh"] = (df.tgt / df.team_tgt).round(3); df["car_sh"] = (df.car / df.team_car).round(3)
df["route_sh"] = (df.routes / df.team_db).astype(float).round(3); df["tprr"] = (df.tgt / df.routes.where(df.routes > 0)).astype(float).round(3)
df["flag"] = df.low.map({True: "LOW-SNAP ", False: ""}) + df.note
df[["fr_tgt", "team_fr"]] = df[["fr_tgt", "team_fr"]].astype("Int64")
print(f"{full} ({gid}, {pos})")
print(df[["wk", "tm", "snaps", "snap_pct", "routes", "team_db", "route_sh", "tgt", "team_tgt", "tgt_sh", "tprr", "fr_tgt", "team_fr",
          "car", "team_car", "car_sh", "rz_tgt", "car_i10", "car_i5", "flag"]].to_string(index=False, na_rep="-"))
chk = df[df.wk.isin(me.index)]
print("CHECK targets==stats", (chk.tgt.values == me.targets.values).all(),
      "| carries+kneels==stats", ((chk.car + chk.kneels).values == me.carries.values).all(),
      "| games per week in pbp:", pb.groupby("week").game_id.nunique().to_dict())


def season(d, label):
    m = me[me.index.isin(d.wk)]; R = d.routes.sum()
    if R <= 0: return print(f"{label}: weeks {d.wk.tolist()} | 0 routes of {d.team_db.sum():.0f} team dropbacks -> no per-route stats")
    ppr = (m.receptions + 0.1 * m.receiving_yards + 6 * m.receiving_tds + 2 * m.receiving_2pt_conversions.fillna(0)).sum()
    print(f"{label}: weeks {d.wk.tolist()} | routes {R:.0f} of {d.team_db.sum():.0f} team dropbacks = route share {R/d.team_db.sum():.1%}"
          f" | TPRR {m.targets.sum()/R:.3f} | YPRR {m.receiving_yards.sum()/R:.2f} | FPPRR (receiving PPR) {ppr/R:.3f}")


if a.routes:                                                       # fallback: a published season total (Sumer / PFF / RotoWire page)
    W = a.through or int(df.wk.max()); d = df[(df.wk <= W) & (df.snaps > 0)].assign(routes=0.0)
    d.loc[d.index[0], "routes"] = a.routes; d["team_db"] = d.nv_db
    print(f"\nPublished season routes {a.routes:.0f} through week {W} (dropbacks from nflverse)")
    if a.tprr:
        site, mine = a.routes * a.tprr, me.targets[me.index <= W].sum()
        if abs(site - mine) > max(2, 0.10 * mine): print(f"WARNING: site targets {site:.1f} vs nflverse {mine} - the page may cover different weeks; check --through")
    season(d, "Season")
    if d.low.any(): print(f"LOW-SNAP weeks {d[d.low].wk.tolist()} are included, so route share is understated.")
else:
    d = df[df.routes.notna()]
    print()
    if len(d):
        season(d, "Season")
        if d.low.any() and (~d.low).any(): season(d[~d.low], "Excluding LOW-SNAP games")
    else: print("No published routes found -> route stats omitted (never estimate routes).")
    gap = df[(df.snaps > 0) & df.routes.isna()].wk.tolist()
    if gap: print(f"Weeks played but without PFF routes (left out of the season line): {gap}. Fallback: get a published season total and rerun with --routes N --tprr X.")
if ft is not None:
    wk = [w for w, t in zip(df.wk, df.tm) if (t, w) in charted]; mine = ft[(ft.receiver_player_id == gid) & ft.week.isin(wk)]; n = len(mine)
    print(f"FTN charting covers weeks {sorted(int(w) for w in ft.week.unique())} (pulled {str(ftn.date_pulled.max())[:10]}); his charted weeks: {wk}")
    if n:
        fr, cat, dr = int(mine.fr.sum()), int(mine.is_catchable_ball.sum()), int(mine.is_drop.sum()); tf = df[df.wk.isin(wk)].team_fr.sum()
        print(f"  first-read targets {fr} of {n} ({fr/n:.0%}) = {fr/tf:.1%} of team first-read targets | designed {int(mine.read_thrown.astype(str).eq('DES').sum())}"
              f" | catchable {cat} of {n} ({cat/n:.0%}) | drops {dr} ({dr/max(cat,1):.1%} of catchable) | contested {int(mine.is_contested_ball.sum())} | screens {int(mine.is_screen_pass.sum())}")
    late = [w for w in df[df.snaps > 0].wk if w not in wk]
    if late: print(f"  Not charted yet: weeks {late}")
team_now = df.tm.iloc[-1]; played = sorted(int(w) for w in pb.loc[pb.posteam == team_now, "week"].unique())
missed = [w for w in played if w not in set(df[df.snaps > 0].wk)]
if missed: print(f"Team games with no offensive snap for him (not counted): weeks {missed}")
try:
    inj = nv("injuries", f"injuries_{Y}.csv"); inj = inj[inj.gsis_id == gid]
    if len(inj): print("Injury reports:\n" + inj[["week", "report_primary_injury", "report_status", "practice_status"]].to_string(index=False))
except Exception as e:
    print("injury file not loaded:", e)
