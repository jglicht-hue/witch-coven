#!/usr/bin/env python3
"""Matchup Witch data build.

Builds one markdown doc per team (defense + offense) plus a league-averages doc
from nflverse data.

  python3 build.py --seasons 2023 2024 2025 --label history --raw raw --out out/history
  python3 build.py --seasons 2026 --label current --raw raw --out out/current

Regular season only. Ranks: 1 = best defense (fewest allowed / lowest EPA).

v1.3: adds opponent-adjusted run and pass numbers for every defense and offense
(season summary in every doc; game-by-game table with --weekly). Adds sections only.
"""
import argparse, os, datetime as dt
import numpy as np
import pandas as pd

BASE = "https://github.com/nflverse/nflverse-data/releases/download"
FILES = {
    "pbp": "pbp/play_by_play_{y}.parquet",
    "part": "pbp_participation/pbp_participation_{y}.parquet",
    "ftn": "ftn_charting/ftn_charting_{y}.parquet",
    "stats": "stats_player/stats_player_week_{y}.parquet",
    "snaps": "snap_counts/snap_counts_{y}.parquet",
    "roster": "rosters/roster_{y}.parquet",
}
POS_MAP = {"FB": "RB", "HB": "RB"}
SKILL = ["QB", "RB", "WR", "TE"]
TEAM_NAMES = {
    "ARI": "Arizona Cardinals", "ATL": "Atlanta Falcons", "BAL": "Baltimore Ravens", "BUF": "Buffalo Bills",
    "CAR": "Carolina Panthers", "CHI": "Chicago Bears", "CIN": "Cincinnati Bengals", "CLE": "Cleveland Browns",
    "DAL": "Dallas Cowboys", "DEN": "Denver Broncos", "DET": "Detroit Lions", "GB": "Green Bay Packers",
    "HOU": "Houston Texans", "IND": "Indianapolis Colts", "JAX": "Jacksonville Jaguars", "KC": "Kansas City Chiefs",
    "LA": "Los Angeles Rams", "LAC": "Los Angeles Chargers", "LV": "Las Vegas Raiders", "MIA": "Miami Dolphins",
    "MIN": "Minnesota Vikings", "NE": "New England Patriots", "NO": "New Orleans Saints", "NYG": "New York Giants",
    "NYJ": "New York Jets", "PHI": "Philadelphia Eagles", "PIT": "Pittsburgh Steelers", "SEA": "Seattle Seahawks",
    "SF": "San Francisco 49ers", "TB": "Tampa Bay Buccaneers", "TEN": "Tennessee Titans", "WAS": "Washington Commanders",
}


def tname(tm):
    return f"{tm} {TEAM_NAMES.get(tm, '')}".strip()


def fname(tm, label):
    nick = TEAM_NAMES.get(tm, tm).split()[-1]
    return f"{tm}_{nick}_{label}.md"


# ---------------------------------------------------------------- loading
def fetch(raw, kind, y):
    fn = os.path.join(raw, os.path.basename(FILES[kind].format(y=y)))
    if not os.path.exists(fn):
        import urllib.request
        try:
            urllib.request.urlretrieve(f"{BASE}/{FILES[kind].format(y=y)}", fn)
        except Exception as e:  # participation is often missing for the current season
            print(f"  (no {kind} {y}: {e})")
            return None
    return pd.read_parquet(fn)


def load(raw, y):
    d = {k: fetch(raw, k, y) for k in FILES}
    pbp = d["pbp"]
    pbp = pbp[pbp.season_type == "REG"].copy()
    ftn = d["ftn"]
    if ftn is not None:
        ftn = ftn.rename(columns={"nflverse_game_id": "game_id", "nflverse_play_id": "play_id"})
        pbp = pbp.merge(ftn[["game_id", "play_id", "n_blitzers", "n_pass_rushers", "n_defense_box",
                             "is_screen_pass", "is_play_action"]], on=["game_id", "play_id"], how="left")
    part = d["part"]
    if part is not None:
        part = part.rename(columns={"nflverse_game_id": "game_id"})
        pbp = pbp.merge(part[["game_id", "play_id", "was_pressure", "route", "defense_man_zone_type",
                              "defense_coverage_type"]], on=["game_id", "play_id"], how="left")
    for c in ["was_pressure", "route", "defense_man_zone_type", "defense_coverage_type",
              "n_blitzers", "n_pass_rushers", "n_defense_box"]:
        if c not in pbp:
            pbp[c] = np.nan
    pbp["route"] = pbp["route"].replace("", np.nan)
    pbp["defense_man_zone_type"] = pbp["defense_man_zone_type"].replace("", np.nan)
    st = d["stats"]
    st = st[st.season_type == "REG"].copy()
    st["pos"] = st.position.replace(POS_MAP)
    ro = d["roster"]
    pos_by_id = (ro.dropna(subset=["gsis_id"]).drop_duplicates("gsis_id", keep="last")
                 .set_index("gsis_id").position.replace(POS_MAP))
    sn = d["snaps"]
    sn = sn[sn.game_type == "REG"].copy()
    return dict(pbp=pbp, stats=st, roster=ro, pos_by_id=pos_by_id, snaps=sn,
                has_part=part is not None, season=y)


# ---------------------------------------------------------------- helpers
def f(x, nd=1):
    if x is None or (isinstance(x, float) and np.isnan(x)):
        return "–"
    if isinstance(x, (int, np.integer)):
        return str(int(x))
    return f"{x:.{nd}f}"


def pct(x):
    return "–" if x is None or pd.isna(x) else f"{100 * x:.0f}%"


def table(df, cols=None):
    cols = cols or list(df.columns)
    out = ["| " + " | ".join(cols) + " |", "|" + "---|" * len(cols)]
    for _, r in df.iterrows():
        out.append("| " + " | ".join(str(r[c]) for c in cols) + " |")
    return "\n".join(out)


def rank(s, ascending=True):
    return s.rank(ascending=ascending, method="min").astype("Int64")


def line(a, b, c):
    a, b, c = int(a), int(b), int(c)
    return f"{a}-{b}-{c}" if b >= 0 else f"{a}-({b})-{c}"


# ---------------------------------------------------------------- plays
def plays(pbp):
    db = pbp[(pbp.qb_dropback == 1) & (pbp.qb_spike != 1)].copy()
    att = pbp[(pbp.pass_attempt == 1) & (pbp.sack != 1) & (pbp.qb_spike != 1)].copy()
    run = pbp[(pbp.rush == 1) & (pbp.qb_scramble != 1) & (pbp.qb_kneel != 1)].copy()
    return db, att, run


def pass_unit(db, att, key):
    g = db.groupby(key)
    out = pd.DataFrame({
        "dropbacks": g.size(),
        "epa_db": g.epa.mean(),
        "sack_rate": g.sack.mean(),
        "pressure_rate": g.was_pressure.apply(lambda s: s.dropna().astype(float).mean() if s.notna().any() else np.nan),
        "blitz_rate": g.n_blitzers.apply(lambda s: (s.dropna() > 0).mean() if s.notna().any() else np.nan),
        "man_rate": g.defense_man_zone_type.apply(lambda s: (s.dropna() == "MAN_COVERAGE").mean() if s.notna().any() else np.nan),
    })
    ga = att.groupby(key)
    out["att"] = ga.size()
    out["ypa"] = ga.passing_yards.apply(lambda s: s.fillna(0).sum()) / out["att"]
    out["comp"] = ga.complete_pass.mean()
    out["exp20"] = ga.apply(lambda d: int(((d.complete_pass == 1) & (d.yards_gained >= 20)).sum()))
    return out


def run_unit(run, key):
    g = run.groupby(key)
    return pd.DataFrame({
        "rushes": g.size(),
        "epa_rush": g.epa.mean(),
        "ypc": g.yards_gained.mean(),
        "success": g.success.mean(),
        "stuff": g.yards_gained.apply(lambda s: (s <= 0).mean()),
        "exp10": g.yards_gained.apply(lambda s: int((s >= 10).sum())),
        "exp20": g.yards_gained.apply(lambda s: int((s >= 20).sum())),
    })


def box_bucket(n):
    if pd.isna(n) or n <= 0:
        return np.nan
    return "≤6" if n <= 6 else ("7" if n == 7 else "8+")


def run_buckets(run):
    run = run.copy()
    run["dir"] = run.run_location.fillna("?").str.cat(run.run_gap.fillna(""), sep=" ").str.strip()
    run["dir"] = run["dir"].replace({"middle": "middle"})
    run["box"] = run.n_defense_box.map(box_bucket)
    run["form"] = np.where(run.shotgun == 1, "shotgun", "under center")
    return run


def cov_mix(db):
    s = db.defense_coverage_type.dropna()
    if s.empty:
        return {}
    vc = s.value_counts(normalize=True)
    return {k: vc.get(k, 0) for k in ["COVER_0", "COVER_1", "COVER_2", "2_MAN", "COVER_3", "COVER_4", "COVER_6", "COVER_9"]}


# ---------------------------------------------------------------- builders
def targets_frame(att, pos_by_id):
    t = att[att.receiver_player_id.notna()].copy()
    t["tpos"] = t.receiver_player_id.map(pos_by_id).replace(POS_MAP)
    t["rec"] = t.complete_pass.fillna(0)
    t["yds"] = t.receiving_yards.fillna(0)
    t["td"] = t.pass_touchdown.fillna(0)
    return t


def target_summary(t, key):
    g = t.groupby(key)
    o = pd.DataFrame({"tgt": g.size(), "catch": g.rec.mean(), "ypt": g.yds.mean(), "td": g.td.sum().astype(int)})
    o["ppr_tgt"] = (g.rec.sum() + g.yds.sum() / 10 + 6 * g.td.sum()) / o.tgt
    return o


# ---------------------------------------------------------------- v1.2: throw grid, funnel, flags, concentrations
CELLS = [f"{d} {l}" for d in ("short", "int", "deep") for l in ("left", "middle", "right")]
CELL_NOTE = "short = under 10 air yards (incl. behind the line), int = 10–19, deep = 20+; left/middle/right = nflverse pass_location"


def add_cells(df):
    df = df[df.air_yards.notna() & df.pass_location.notna()].copy()
    df["cell"] = np.select([df.air_yards >= 20, df.air_yards >= 10], ["deep", "int"], "short")
    df["cell"] = df["cell"] + " " + df.pass_location
    return df


def sample_mins(weekly):
    if weekly:  # current season: a few games
        return dict(cell=8, run=8, tgt=10, route=6, mz=8, rbroute=5, funnel=40, other=15, rec=12, car=15, qb=40, fun_pp=0.06)
    return dict(cell=25, run=30, tgt=40, route=15, mz=25, rbroute=10, funnel=150, other=60, rec=40, car=60, qb=150, fun_pp=0.04)


def fam_rows(F, df, bcol, vcol, fam, m, fmt, low_good=True):
    """Per-team mean of vcol in each bucket, ranked among teams with >= m plays (1 = best defense)."""
    if df.empty:
        return
    g = df.groupby(["defteam", bcol])[vcol].agg(["mean", "size"]).reset_index()
    lg = df.groupby(bcol)[vcol].mean()
    g = g[g["size"] >= m].copy()
    if g.empty:
        return
    g["N"] = g.groupby(bcol)["mean"].transform("size")
    g["rank"] = g.groupby(bcol)["mean"].rank(ascending=low_good, method="min")
    for _, r in g.iterrows():
        F.append(dict(team=r.defteam, fam=fam, bucket=r[bcol], val=r["mean"], lg=lg[r[bcol]], n=int(r["size"]),
                      rank=int(r["rank"]), N=int(r.N), fmt=fmt))


def fmt_v(v, fmt):
    if fmt == "pct":
        return pct(v)
    return f"{v:+.{fmt}f}" if fmt == 2 and abs(v) < 1 else f(v, fmt)


def funnel_frame(ac, mins):
    """For each defense and throw cell: opposing QBs' share of attempts there vs their share in all their other games."""
    pid = "passer_player_id"
    a = ac[ac[pid].notna()]
    cnt = a.groupby([pid, "defteam", "cell"]).size().rename("n").reset_index()
    tot_pd = cnt.groupby([pid, "defteam"]).n.sum().rename("n_pd").reset_index()
    tot_p = cnt.groupby(pid).n.sum()
    tot_pc = cnt.groupby([pid, "cell"]).n.sum().rename("pc").reset_index()
    tot_pd["other"] = tot_pd[pid].map(tot_p) - tot_pd.n_pd
    pairs = tot_pd[tot_pd.other >= mins["other"]]
    full = pairs.merge(pd.DataFrame({"cell": CELLS}), how="cross")
    full = full.merge(cnt, on=[pid, "defteam", "cell"], how="left").merge(tot_pc, on=[pid, "cell"], how="left")
    full[["n", "pc"]] = full[["n", "pc"]].fillna(0)
    full["exp"] = full.n_pd * (full.pc - full.n) / full.other
    fun = full.groupby(["defteam", "cell"]).agg(obs=("n", "sum"), exp=("exp", "sum")).reset_index()
    inc = pairs.groupby("defteam").n_pd.sum()
    fun["inc"] = fun.defteam.map(inc)
    fun["obs_sh"] = fun.obs / fun.inc
    fun["exp_sh"] = fun.exp / fun.inc
    fun["diff"] = fun.obs_sh - fun.exp_sh
    return fun


def defense_extras(D, db, att, run, t, pu, ru, pu_rank, ru_rank, fpg, fpr, fpa, games, lp, lr, teams, league_rows):
    """Return team -> (flags markdown, throw grid markdown, QB rushing markdown)."""
    mins = sample_mins(D.get("weekly"))
    pbp, y = D["pbp"], D["season"]
    ac = add_cells(att)
    ac["yds0"] = ac.passing_yards.fillna(0)
    ac["td_"] = ac.pass_touchdown.fillna(0)
    ac["int_"] = ac.interception.fillna(0)
    agg = dict(att=("epa", "size"), comp=("complete_pass", "mean"), ypa=("yds0", "mean"), td=("td_", "sum"),
               int_=("int_", "sum"), epa=("epa", "mean"))
    lgrid = ac.groupby("cell").agg(**agg).reindex(CELLS)
    league_rows.append(f"League passing by throw depth and location ({CELL_NOTE}):\n\n" + table(pd.DataFrame({
        "cell": lgrid.index, "att": lgrid.att.astype(int), "share": (lgrid.att / lgrid.att.sum()).map(pct),
        "comp": lgrid.comp.map(pct), "YPA": lgrid.ypa.map(lambda v: f(v, 2)), "TD": lgrid.td.astype(int),
        "INT": lgrid.int_.astype(int), "EPA/att": lgrid.epa.map(lambda v: f(v, 3))})))
    dgrid = ac.groupby(["defteam", "cell"]).agg(**agg).reset_index()
    el = dgrid[dgrid.att >= mins["cell"]].copy()
    el["rank"] = el.groupby("cell").epa.rank(method="min")
    el["N"] = el.groupby("cell").epa.transform("size")
    dgrid = dgrid.merge(el[["defteam", "cell", "rank", "N"]], on=["defteam", "cell"], how="left")
    fun = funnel_frame(ac, mins)
    fun["frank"] = fun[fun.inc >= mins["funnel"]].groupby("cell")["diff"].rank(ascending=False, method="min")

    # QB rushing allowed (designed QB runs + scrambles, no kneels)
    qbr = pbp[(pbp.rush_attempt == 1) & (pbp.play_type == "run") & (pbp.qb_kneel != 1)].copy()  # scrambles have rush == 0
    qbr = qbr[(qbr.qb_scramble == 1) | (qbr.rusher_player_id.map(D["pos_by_id"]) == "QB")]
    qg = qbr.groupby("defteam").agg(car=("epa", "size"), yds=("yards_gained", "sum"), scr=("qb_scramble", "sum"),
                                    td=("rush_touchdown", "sum"))
    qg = qg.reindex(teams).fillna(0)
    qg["ypg"] = qg.yds / games
    qg["cpg"] = qg.car / games
    qg["scr_rate"] = qg.scr / db.groupby("defteam").size()
    qg["rank"] = rank(qg.ypg, True)
    lq_ypg, lq_scr = qg.yds.sum() / games.sum(), qg.scr.sum() / len(db)
    league_rows.append(f"League QB rushing allowed (designed runs + scrambles): {f(qg.cpg.mean(), 1)} carries and "
                       f"{f(lq_ypg, 1)} yds per team-game; scramble rate {pct(lq_scr)} of dropbacks")

    # ---- flags
    F = []
    n_t = len(teams)
    unit = [("pass D", "EPA/dropback", pu.epa_db, lp.epa_db, pu_rank["epa_db"], 3),
            ("pass D", "YPA", pu.ypa, lp.ypa, pu_rank["ypa"], 2),
            ("pass D", "completion %", pu.comp, lp.comp, pu_rank["comp"], "pct"),
            ("pass D", "20+ yd completions/game", pu.exp20_pg, lp.exp20 / games.sum(), pu_rank["exp20_pg"], 2),
            ("pass D", "sack rate", pu.sack_rate, lp.sack_rate, pu_rank["sack_rate"], "pct"),
            ("run D", "EPA/rush", ru.epa_rush, lr.epa_rush, ru_rank["epa_rush"], 3),
            ("run D", "YPC", ru.ypc, lr.ypc, ru_rank["ypc"], 2),
            ("run D", "success rate", ru.success, lr.success, ru_rank["success"], "pct"),
            ("run D", "stuff rate", ru.stuff, lr.stuff, ru_rank["stuff"], "pct"),
            ("run D", "10+ yd runs/game", ru.exp10_pg, lr.exp10 / games.sum(), ru_rank["exp10_pg"], 2)]
    if pu.pressure_rate.notna().any():
        unit.append(("pass D", "pressure rate", pu.pressure_rate, lp.pressure_rate, pu_rank["pressure_rate"], "pct"))
    for fam, b, ser, lgv, rk, fm in unit:
        for tm in teams:
            if tm in ser.index and not pd.isna(ser[tm]):
                F.append(dict(team=tm, fam=fam, bucket=b, val=ser[tm], lg=lgv, n=None, rank=int(rk[tm]), N=n_t, fmt=fm))
    for p in SKILL:
        for tm in teams:
            F.append(dict(team=tm, fam="PPR/g allowed", bucket=p, val=fpg.loc[tm, p], lg=fpa[p].sum() / games.sum(),
                          n=None, rank=int(fpr.loc[tm, p]), N=n_t, fmt=1))
    for tm in teams:
        F.append(dict(team=tm, fam="QB rush yds/g allowed", bucket="all QBs", val=qg.ypg[tm], lg=lq_ypg, n=int(qg.car[tm]),
                      rank=int(qg["rank"][tm]), N=n_t, fmt=1))
    fam_rows(F, ac, "cell", "epa", "pass EPA/att", mins["cell"], 2)
    tt = t[t.tpos.isin(["RB", "WR", "TE"])].copy()
    fam_rows(F, tt, "tpos", "ppr", "PPR/tgt", mins["tgt"], 2)
    if D["has_part"]:
        mz = tt.dropna(subset=["defense_man_zone_type"]).copy()
        mz["b"] = mz.tpos + " vs " + mz.defense_man_zone_type.str.replace("_COVERAGE", "").str.lower()
        fam_rows(F, mz, "b", "ppr", "PPR/tgt", mins["mz"], 2)
        rt = tt.dropna(subset=["route"]).copy()
        rt["b"] = rt.tpos + " " + rt.route.str.lower()
        fam_rows(F, rt, "b", "ppr", "PPR/tgt", mins["route"], 2)
    rb = tt[tt.tpos == "RB"].copy()
    rb["b"] = np.where(rb.is_screen_pass == True, "RB screen", "RB " + rb.route.fillna("other").str.lower())
    if not D["has_part"]:
        rb = rb[rb.b == "RB screen"]
    fam_rows(F, rb, "b", "ppr", "PPR/tgt", mins["rbroute"], 2)
    bx = run.dropna(subset=["box"]).copy()
    bx["b"] = bx.box + " box"
    fam_rows(F, bx, "b", "epa", "rush EPA", mins["run"], 3)
    dr = run[run.dir != "?"]
    fam_rows(F, dr, "dir", "epa", "rush EPA, runs", mins["run"], 3)
    F = pd.DataFrame(F)
    F = F[F.N >= 10]

    out = {}
    for tm in teams:
        ft = F[F.team == tm]
        k = (ft.N * 5 / 32).round().clip(lower=2)  # top/bottom 5 of 32, scaled down when fewer teams qualify
        weak = ft[ft["rank"] > ft.N - k].sort_values("rank", ascending=False)
        strong = ft[ft["rank"] <= k].sort_values("rank")

        def bl(r):
            ss = f"; n={int(r.n)}" if r.n is not None and not pd.isna(r.n) else ""
            return f"- {r.fam}, {r.bucket}: {fmt_v(r.val, r.fmt)} (lg {fmt_v(r.lg, r.fmt)}; {r['rank']}/{r.N}{ss})"
        md = [f"Flags, {y} (leads to test, not verdicts; rank 1 = best D, among teams with enough plays; see README):"]
        md.append("Weak (bottom ~15%):\n" + ("\n".join(bl(r) for _, r in weak.iterrows()) or "- none"))
        md.append("Strong (top ~15%):\n" + ("\n".join(bl(r) for _, r in strong.iterrows()) or "- none"))
        fu = fun[(fun.defteam == tm) & (fun.inc >= mins["funnel"]) & (fun["diff"].abs() >= mins["fun_pp"])]
        if len(fu):
            md.append(f"Throw funnel (opp. QBs' share of att here vs their usual; {int(mins['fun_pp'] * 100)}+ pt shifts):\n" + "\n".join(
                          f"- {r.cell}: {pct(r.obs_sh)} vs {pct(r.exp_sh)} ({'+' if r['diff'] > 0 else '−'}"
                          f"{abs(r['diff']) * 100:.0f}; {int(r.inc)} att)"
                          for _, r in fu.sort_values("diff", ascending=False).iterrows()))
        g_ = dgrid[dgrid.defteam == tm].set_index("cell").reindex(CELLS)
        fn = fun[fun.defteam == tm].set_index("cell").reindex(CELLS)
        grid = table(pd.DataFrame({
            "cell": CELLS, "att": g_.att.fillna(0).astype(int), "comp": g_.comp.map(pct),
            "YPA": g_.ypa.map(lambda v: f(v, 2)), "TD": g_.td.fillna(0).astype(int), "INT": g_.int_.fillna(0).astype(int),
            "EPA": g_.epa.map(lambda v: f(v, 2)),
            "rank": [("–" if pd.isna(r) else f"{int(r)}/{int(n)}") for r, n in zip(g_["rank"], g_.N)],
            "share": fn.obs_sh.map(pct), "usual": fn.exp_sh.map(pct)}))
        grid = (f"Passing allowed by throw (rank by EPA/att among teams with ≥{mins['cell']} att; share = opp. QBs' "
                f"share of att here, usual = their share in other games):\n\n" + grid)
        q = qg.loc[tm]
        qmd = (f"QB rushing allowed (runs + scrambles): {int(q.car)} car, {int(q.yds)} yds, {int(q.td)} TD; "
               f"{f(q.ypg, 1)} yds/g (rank {int(q['rank'])}/{n_t}; lg {f(lq_ypg, 1)}); scramble rate {pct(q.scr_rate)} "
               f"(lg {pct(lq_scr)})")
        out[tm] = ("\n\n".join(md), grid, qmd)
    return out, ac, lgrid


def offense_extras(D, ac, lgrid, t, run, teams):
    """Return team -> (usage concentrations markdown, QB throw map markdown)."""
    mins = sample_mins(D.get("weekly"))
    st = D["stats"]
    name = st.drop_duplicates("player_id").set_index("player_id").player_display_name
    lg_share = lgrid.att / lgrid.att.sum()
    tc = add_cells(t[t.tpos.isin(["RB", "WR", "TE"])])
    lg_rec_cell = tc.groupby("tpos").cell.value_counts(normalize=True)
    has_route = D["has_part"]
    if has_route:
        tr = t[t.tpos.isin(["RB", "WR", "TE"])].dropna(subset=["route"])
        lg_route = tr.groupby("tpos").route.value_counts(normalize=True)
    rbr = run[run.rusher_player_id.map(D["pos_by_id"]).replace(POS_MAP) == "RB"].copy()
    rbr["b_dir"] = rbr.dir
    rbr["b_box"] = rbr.box.map(lambda b: np.nan if pd.isna(b) else f"{b} box")
    lg_rb = {k: rbr[k].dropna().value_counts(normalize=True) for k in ("b_dir", "b_box")}
    out = {}
    for tm in teams:
        lines = []
        # QBs
        qa = ac[(ac.posteam == tm) & ac.passer_player_id.notna()]
        qmap_rows = []
        for pid, gq in qa.groupby("passer_player_id"):
            if len(gq) < mins["qb"]:
                continue
            sh = gq.cell.value_counts(normalize=True).reindex(CELLS).fillna(0)
            ep = gq.groupby("cell").epa.mean().reindex(CELLS)
            nm = name.get(pid, pid)
            row = {"QB": nm, "att": len(gq)}
            for c in CELLS:
                row[c] = f"{pct(sh[c])} ({f(ep[c], 2)})" if sh[c] > 0 else "0%"
            qmap_rows.append(row)
            hits = [f"{c} {pct(sh[c])} (lg {pct(lg_share[c])})" for c in CELLS
                    if sh[c] >= lg_share[c] + 0.04 and sh[c] >= 1.3 * lg_share[c]]
            if hits:
                lines.append(f"- {nm} (QB, {len(gq)} att): " + "; ".join(hits))
        lrow = {"QB": "league", "att": int(lgrid.att.sum())}
        for c in CELLS:
            lrow[c] = f"{pct(lg_share[c])} ({f(lgrid.epa[c], 2)})"
        qmap = ""
        if qmap_rows:
            qmap = (f"QB throw map (share of att, EPA/att in parentheses; ≥{mins['qb']} att):\n\n"
                    + table(pd.DataFrame(qmap_rows + [lrow])))
        # receivers
        tt = tc[tc.posteam == tm]
        for pid, gr in tt.groupby("receiver_player_id"):
            if len(gr) < mins["rec"]:
                continue
            pos = gr.tpos.iloc[0]
            sh = gr.cell.value_counts(normalize=True)
            hits = []
            for c, v in sh.items():
                lv = lg_rec_cell.get((pos, c), 0)
                if v >= lv + 0.10 and v >= 1.5 * lv:
                    hits.append(f"{c} {pct(v)} (avg {pct(lv)})")
            if has_route:
                rr = t[(t.posteam == tm) & (t.receiver_player_id == pid)].route.dropna()
                if len(rr) >= mins["rec"] // 2:
                    for r_, v in rr.value_counts(normalize=True).items():
                        lv = lg_route.get((pos, r_), 0)
                        if v >= lv + 0.10 and v >= 1.5 * lv:
                            hits.append(f"{r_.lower()} {pct(v)} (avg {pct(lv)})")
            if hits:
                lines.append(f"- {name.get(pid, pid)} ({pos}, {len(gr)} tgt): " + "; ".join(hits))
        # RBs
        rt = rbr[rbr.posteam == tm]
        for pid, gr in rt.groupby("rusher_player_id"):
            if len(gr) < mins["car"]:
                continue
            hits = []
            for k in ("b_dir", "b_box"):
                sh = gr[k].dropna().value_counts(normalize=True)
                for b, v in sh.items():
                    lv = lg_rb[k].get(b, 0)
                    if b != "?" and v >= lv + 0.10 and v >= 1.5 * lv:
                        hits.append(f"{'runs ' if k == 'b_dir' else 'vs '}{b} {pct(v)} (avg {pct(lv)})")
            if hits:
                lines.append(f"- {name.get(pid, pid)} (RB, {len(gr)} car): " + "; ".join(hits))
        conc = ("Usage concentrations (share well above league avg at his position):\n"
                + ("\n".join(lines) if lines else "- none"))
        out[tm] = (conc, qmap)
    return out


# ---------------------------------------------------------------- v1.3: opponent-adjusted run and pass
ADJ_MIN = 100  # an opponent rating resting on fewer plays than this gets a *
ADJ_STATS = [  # key, label, play frame, value column, format, low is good for the defense, in the game-by-game table
    ("ypc", "Run YPC", "run", "yards_gained", 2, True, True),
    ("rsucc", "Run success rate", "run", "success", "pct", True, True),
    ("repa", "EPA/rush", "run", "epa", 3, True, True),
    ("pepa", "EPA/dropback", "db", "epa", 3, True, True),
    ("ypa", "YPA", "att", "yds0", 2, True, True),
    ("sack", "Sack rate", "db", "sack", "pct", False, False),
]
ADJ_SHORT = {"ypc": "YPC", "rsucc": "success", "repa": "EPA/rush", "pepa": "EPA/db", "ypa": "YPA"}
ADJ_SIDES = (("def", "defteam", "posteam"), ("off", "posteam", "defteam"))


def adj_tables(db, att, run):
    """Opponent adjustment in two leave-one-out steps, weighted by plays.

    Step 1, each unit's rating: its result in each game minus what that opponent did (offense) or
    allowed (defense) in all its games against everyone else, averaged over the unit's games.
    Step 2, each game: expected = league average + the opponent's step-1 rating, built only from the
    opponent's games against everyone else. diff = actual - expected.
    Runs here are real plays only (play_type == "run"); runs wiped out by a penalty are left out.
    Returns side -> (S, P): S[stat] = one row per team, P[stat] = one row per game; and the league averages.
    """
    frames = {"run": run[run.play_type == "run"], "db": db, "att": att.assign(yds0=att.passing_yards.fillna(0))}
    out, lg = {side: ({}, {}) for side, _, _ in ADJ_SIDES}, {}
    for key, _, fr, col, _, low_good, _ in ADJ_STATS:
        g0 = (frames[fr].groupby(["posteam", "defteam", "game_id", "week"])[col]
              .agg(n="count", s="sum", plays="size").reset_index())
        mu = lg[key] = g0.s.sum() / g0.n.sum()
        one = {}
        for side, team_col, opp_col in ADJ_SIDES:  # step 1
            g = g0.copy()
            tot = g.groupby(opp_col)[["n", "s"]].sum()
            pair = g.groupby([team_col, opp_col])[["n", "s"]].transform("sum")
            bn = g[opp_col].map(tot.n) - pair.n  # the opponent's plays in games not against this team
            g["val"] = g.s / g.n.where(g.n > 0)
            g["usual"] = (g[opp_col].map(tot.s) - pair.s) / bn.where(bn > 0)
            ok = g.usual.notna() & (g.n > 0)
            g["wn"] = g.n.where(ok, 0)
            g["wd"] = (g.n * (g.val - g.usual)).where(ok, 0)
            one[side] = g
        for side, team_col, opp_col in ADJ_SIDES:  # step 2
            g = one[side].copy()
            o = one["off" if side == "def" else "def"]  # the opponents' own step-1 games
            otot = o.groupby(opp_col)[["wn", "wd"]].sum()
            opair = o.groupby([opp_col, team_col])[["wn", "wd"]].sum()
            ix = pd.MultiIndex.from_arrays([g[opp_col], g[team_col]])
            g["on"] = g[opp_col].map(otot.wn).values - opair.wn.reindex(ix).values  # opponent's rated plays elsewhere
            od = g[opp_col].map(otot.wd).values - opair.wd.reindex(ix).values
            g["exp"] = mu + od / g.on.where(g.on > 0)
            g["diff"] = g.val - g.exp
            k = g[g.exp.notna() & (g.n > 0)].copy()
            k["w"] = k.n * k.exp
            k["thin"] = (k.on < ADJ_MIN).astype(int)
            a = k.groupby(team_col).agg(n=("n", "sum"), s=("s", "sum"), w=("w", "sum"), games=("n", "size"),
                                        thin=("thin", "sum"))
            a["raw"] = a.s / a.n
            a["exp"] = a.w / a.n
            a["diff"] = a.raw - a.exp
            a["adj"] = mu + a["diff"]
            a["rank"] = a["diff"].rank(ascending=low_good if side == "def" else not low_good, method="min")
            a["N"] = len(a)
            out[side][0][key], out[side][1][key] = a, g
    return out, lg


def adj_fmt(v, fmt, sign=False, short=False):
    if v is None or pd.isna(v):
        return "–"
    if fmt == "pct":
        return f"{100 * v:+.1f}" if sign else (f"{100 * v:.0f}%" if short else f"{100 * v:.1f}%")
    nd = 2 if short else fmt
    return f"{v:+.{nd}f}" if sign else f"{v:.{nd}f}"


def opp_adjusted(db, att, run, y, weekly):
    """Return side -> team -> (season summary markdown, game-by-game markdown or None), plus a league line."""
    T, lg = adj_tables(db, att, run)
    out = {}
    for side, team_col, opp_col in ADJ_SIDES:
        S, P = T[side]
        did = "allowed" if side == "def" else "gained"
        unit = "defense" if side == "def" else "offense"
        other = "offense" if side == "def" else "defense"
        res = {}
        for tm in sorted(P["ypc"][team_col].dropna().unique()):
            rows = []
            for key, label, _, _, fmt, _, _ in ADJ_STATS:
                if tm not in S[key].index:
                    continue
                r = S[key].loc[tm]
                rows.append({"stat": label, did: adj_fmt(r.raw, fmt), "expected": adj_fmt(r.exp, fmt),
                             "diff": adj_fmt(r["diff"], fmt, sign=True), "adjusted": adj_fmt(r.adj, fmt),
                             "rank": f"{int(r['rank'])}/{int(r.N)}", "games": int(r.games), "thin": int(r.thin)})
            if rows:
                summ = (f"Opponent-adjusted run and pass, {y} (expected = league avg + each opposing {other}'s adjusted "
                        f"rating from its other games; diff = {did} − expected; adjusted = league avg + diff; rank 1 = "
                        f"best {unit}; thin = games where that rating rests on under {ADJ_MIN} plays; run rows leave "
                        f"out penalty-nullified plays; method in README):\n\n" + table(pd.DataFrame(rows)))
            else:
                summ = f"Opponent-adjusted run and pass, {y}: not available yet (opponents need games against other teams)."
            games = None
            if weekly:
                idx = {key: P[key][P[key][team_col] == tm].set_index("game_id") for key, *_ in ADJ_STATS}
                grows = []
                for gid, b in idx["ypc"].sort_values("week").iterrows():
                    row = {"wk": int(b.week), "opp": b[opp_col]}
                    for key, label, _, _, fmt, _, show in ADJ_STATS:
                        if not show:
                            continue
                        label = ADJ_SHORT[key]
                        if key == "ypc":
                            row["rush"] = int(b.plays)
                        if key == "pepa":
                            row["db"] = int(idx[key].plays.get(gid, 0))
                        if gid not in idx[key].index:
                            row[label] = "–"
                            continue
                        r = idx[key].loc[gid]
                        star = "*" if (not pd.isna(r.exp) and r.on < ADJ_MIN) else ""
                        row[label] = f"{adj_fmt(r.val, fmt, short=True)} ({adj_fmt(r.exp, fmt, short=True)}{star})"
                    grows.append(row)
                if grows:
                    games = (f"Game by game, {y}: {did} (expected vs that {other}; * = its rating rests on under "
                             f"{ADJ_MIN} plays):\n\n" + table(pd.DataFrame(grows)))
            res[tm] = (summ, games)
        out[side] = res
    out["league"] = ("League averages on the opponent-adjusted tables' definitions (runs leave out penalty-nullified plays): "
                     + ", ".join(f"{label} {adj_fmt(lg[key], fmt)}" for key, label, _, _, fmt, _, _ in ADJ_STATS))
    return out


def season_docs(D, league_rows):
    """Return dict team -> list of markdown sections for one season."""
    y = D["season"]
    pbp, st = D["pbp"], D["stats"]
    db, att, run = plays(pbp)
    run = run_buckets(run)
    t = targets_frame(att, D["pos_by_id"])
    t["ppr"] = t.rec + t.yds / 10 + 6 * t.td
    games = pbp.groupby("defteam").game_id.nunique()
    weeks = sorted(pbp.week.unique())
    teams = sorted(pbp.posteam.dropna().unique())
    sec = {tm: [] for tm in teams}

    # --- fantasy points allowed by position
    sk = st[st.pos.isin(SKILL)]
    fpa = sk.groupby(["opponent_team", "pos"]).agg(ppr=("fantasy_points_ppr", "sum"),
                                                   rec=("receptions", "sum")).reset_index()
    fpa = fpa.pivot(index="opponent_team", columns="pos", values="ppr").reindex(teams)
    fpg = fpa.div(games, axis=0)
    fpr = fpg.apply(lambda c: rank(c, True))

    # --- units
    pu = pass_unit(db, att, "defteam")
    ru = run_unit(run, "defteam")
    pu_rank = {c: rank(pu[c], c not in ("sack_rate", "pressure_rate")) for c in ["epa_db", "ypa", "comp", "sack_rate", "pressure_rate"]}
    ru_rank = {c: rank(ru[c], c != "stuff") for c in ["epa_rush", "ypc", "success", "stuff"]}
    pu["exp20_pg"] = pu.exp20 / games
    ru["exp10_pg"] = ru.exp10 / games
    ru["exp20_pg"] = ru.exp20 / games
    pu_rank["exp20_pg"] = rank(pu["exp20_pg"], True)
    ru_rank["exp10_pg"] = rank(ru["exp10_pg"], True)

    # --- league averages
    lp = pass_unit(db.assign(k=1), att.assign(k=1), "k").iloc[0]
    lr = run_unit(run.assign(k=1), "k").iloc[0]
    league_rows.append(f"### {y} league averages (per team-game where noted)\n"
                       f"- Pass D: EPA/dropback {f(lp.epa_db,3)}, YPA {f(lp.ypa,2)}, comp {pct(lp.comp)}, "
                       f"20+ completions/game {f(lp.exp20 / games.sum(),2)}, sack rate {pct(lp.sack_rate)}, "
                       f"pressure rate {pct(lp.pressure_rate)}, blitz rate {pct(lp.blitz_rate)}, man rate {pct(lp.man_rate)}\n"
                       f"- Run D: EPA/rush {f(lr.epa_rush,3)}, YPC {f(lr.ypc,2)}, success {pct(lr.success)}, stuff {pct(lr.stuff)}, "
                       f"10+ runs/game {f(lr.exp10 / games.sum(),2)}, 20+ runs/game {f(lr.exp20 / games.sum(),2)}\n"
                       f"- PPR allowed per game by position: " +
                       ", ".join(f"{p} {f(fpa[p].sum() / games.sum())}" for p in SKILL))
    lt = target_summary(t, "tpos").reindex(["RB", "WR", "TE"])
    league_rows.append("League targets by receiver position:\n\n" + table(pd.DataFrame({
        "pos": lt.index, "tgt": lt.tgt.astype(int), "catch": lt.catch.map(pct), "YPT": lt.ypt.map(lambda v: f(v, 2)),
        "PPR/tgt": lt.ppr_tgt.map(lambda v: f(v, 2))})))
    if D["has_part"]:
        lrt = target_summary(t.dropna(subset=["route"]), ["tpos", "route"]).reset_index()
        lrt = lrt[lrt.tpos.isin(["RB", "WR", "TE"]) & (lrt.tgt >= 30)]
        league_rows.append("League targets by position and route (targeted receiver's route; ≥30 targets):\n\n" + table(pd.DataFrame({
            "pos": lrt.tpos, "route": lrt.route, "tgt": lrt.tgt.astype(int), "catch": lrt.catch.map(pct),
            "YPT": lrt.ypt.map(lambda v: f(v, 2)), "TD": lrt.td, "PPR/tgt": lrt.ppr_tgt.map(lambda v: f(v, 2))})))
        lmz = target_summary(t.dropna(subset=["defense_man_zone_type"]), ["tpos", "defense_man_zone_type"]).reset_index()
        lmz = lmz[lmz.tpos.isin(["RB", "WR", "TE"])]
        league_rows.append("League targets by position vs man/zone:\n\n" + table(pd.DataFrame({
            "pos": lmz.tpos, "coverage": lmz.defense_man_zone_type.str.replace("_COVERAGE", "").str.lower(),
            "tgt": lmz.tgt.astype(int), "catch": lmz.catch.map(pct), "YPT": lmz.ypt.map(lambda v: f(v, 2)),
            "PPR/tgt": lmz.ppr_tgt.map(lambda v: f(v, 2))})))
    lb = run.dropna(subset=["box"]).groupby("box").agg(n=("epa", "size"), ypc=("yards_gained", "mean"),
                                                     succ=("success", "mean"), epa=("epa", "mean"))
    ld = run.groupby("dir").agg(n=("epa", "size"), ypc=("yards_gained", "mean"), succ=("success", "mean"), epa=("epa", "mean"))
    league_rows.append("League run results by box count and by direction/gap:\n\n" + table(pd.DataFrame({
        "bucket": list(lb.index) + list(ld.index), "rushes": list(lb.n) + list(ld.n),
        "YPC": [f(v, 2) for v in list(lb.ypc) + list(ld.ypc)], "success": [pct(v) for v in list(lb.succ) + list(ld.succ)],
        "EPA/rush": [f(v, 3) for v in list(lb.epa) + list(ld.epa)]})))

    # --- per-team defense
    dx, ac, lgrid = defense_extras(D, db, att, run, t, pu, ru, pu_rank, ru_rank, fpg, fpr, fpa, games, lp, lr, teams, league_rows)
    adj = opp_adjusted(db, att, run, y, D.get("weekly"))
    league_rows.append(adj["league"])
    for tm in teams:
        g = int(games.get(tm, 0))
        s = [f"## {y} DEFENSE — {tname(tm)} ({g} games)"]
        s.append(dx[tm][0])
        s.append("Fantasy points allowed (PPR, nflverse scoring incl. rushing, fumbles, 2-pt). Rank 1 = fewest allowed.\n\n" + table(pd.DataFrame({
            "pos": SKILL,
            "PPR total": [f(fpa.loc[tm, p]) for p in SKILL],
            "PPR/game": [f(fpg.loc[tm, p]) for p in SKILL],
            "rank": [fpr.loc[tm, p] for p in SKILL]})))
        p, r = pu.loc[tm], ru.loc[tm]
        rows = [("EPA/dropback", f(p.epa_db, 3), pu_rank["epa_db"][tm]), ("YPA", f(p.ypa, 2), pu_rank["ypa"][tm]),
                ("Comp %", pct(p.comp), pu_rank["comp"][tm]), ("20+ yd completions/game", f(p.exp20_pg, 2), pu_rank["exp20_pg"][tm]),
                ("Sack rate", pct(p.sack_rate), pu_rank["sack_rate"][tm]),
                ("Pressure rate (NGS)", pct(p.pressure_rate), pu_rank["pressure_rate"][tm] if not pd.isna(p.pressure_rate) else "–"),
                ("Blitz rate (FTN: 1+ blitzer)", pct(p.blitz_rate), "–"),
                ("Man coverage rate (NGS)", pct(p.man_rate), "–"),
                ("EPA/rush (designed runs)", f(r.epa_rush, 3), ru_rank["epa_rush"][tm]), ("YPC", f(r.ypc, 2), ru_rank["ypc"][tm]),
                ("Rush success rate", pct(r.success), ru_rank["success"][tm]), ("Stuff rate (≤0 yds)", pct(r.stuff), ru_rank["stuff"][tm]),
                ("10+ yd runs/game", f(r.exp10_pg, 2), ru_rank["exp10_pg"][tm]), ("20+ yd runs/game", f(r.exp20_pg, 2), "–")]
        s.append("Unit stats (rank 1 = best defense):\n\n" + table(pd.DataFrame(rows, columns=["stat", "value", "rank"])))
        if tm in adj["def"]:
            s.append(adj["def"][tm][0])
        s.append(dx[tm][2])
        s.append(dx[tm][1])
        cm = cov_mix(db[db.defteam == tm])
        if cm:
            s.append("Coverage shell mix on dropbacks (NGS): " + ", ".join(f"{k.replace('COVER_', 'Cover ')} {pct(v)}" for k, v in cm.items()))
        tt = t[t.defteam == tm]
        ts = target_summary(tt, "tpos").reindex(["RB", "WR", "TE"]).dropna(how="all")
        s.append("Targets allowed by receiver position:\n\n" + table(pd.DataFrame({
            "pos": ts.index, "tgt": ts.tgt.astype(int), "catch": ts.catch.map(pct), "YPT": ts.ypt.map(lambda v: f(v, 2)),
            "TD": ts.td, "PPR/tgt": ts.ppr_tgt.map(lambda v: f(v, 2))})))
        if D["has_part"]:
            mz = target_summary(tt.dropna(subset=["defense_man_zone_type"]), ["tpos", "defense_man_zone_type"]).reset_index()
            mz = mz[mz.tpos.isin(["RB", "WR", "TE"])]
            s.append("Targets allowed by position vs man/zone:\n\n" + table(pd.DataFrame({
                "pos": mz.tpos, "coverage": mz.defense_man_zone_type.str.replace("_COVERAGE", "").str.lower(), "tgt": mz.tgt.astype(int),
                "catch": mz.catch.map(pct), "YPT": mz.ypt.map(lambda v: f(v, 2)), "TD": mz.td,
                "PPR/tgt": mz.ppr_tgt.map(lambda v: f(v, 2))})))
            rt = target_summary(tt.dropna(subset=["route"]), ["tpos", "route"]).reset_index()
            rt = rt[rt.tpos.isin(["RB", "WR", "TE"])].sort_values(["tpos", "tgt"], ascending=[True, False])
            s.append("Targets allowed by position and route (targeted receiver's route):\n\n" + table(pd.DataFrame({
                "pos": rt.tpos, "route": rt.route, "tgt": rt.tgt.astype(int), "catch": rt.catch.map(pct),
                "YPT": rt.ypt.map(lambda v: f(v, 2)), "TD": rt.td, "PPR/tgt": rt.ppr_tgt.map(lambda v: f(v, 2))})))
        rr = run[run.defteam == tm]
        bk = pd.concat([rr.dropna(subset=["box"]).groupby("box").agg(n=("epa", "size"), ypc=("yards_gained", "mean"), succ=("success", "mean"), epa=("epa", "mean")).assign(kind="box"),
                        rr.groupby("dir").agg(n=("epa", "size"), ypc=("yards_gained", "mean"), succ=("success", "mean"), epa=("epa", "mean")).assign(kind="direction/gap"),
                        rr.groupby("form").agg(n=("epa", "size"), ypc=("yards_gained", "mean"), succ=("success", "mean"), epa=("epa", "mean")).assign(kind="offense formation")])
        s.append("Run defense by bucket (box count from FTN charting):\n\n" + table(pd.DataFrame({
            "type": bk.kind, "bucket": bk.index, "rushes": bk.n, "YPC": bk.ypc.map(lambda v: f(v, 2)),
            "success": bk.succ.map(pct), "EPA/rush": bk.epa.map(lambda v: f(v, 3))})))
        rbt = tt[tt.tpos == "RB"].copy()
        if len(rbt):
            rbt["rt"] = np.where(rbt.is_screen_pass == True, "screen", rbt.route.fillna("(route n/a)"))
            rs = target_summary(rbt, "rt").sort_values("tgt", ascending=False)
            s.append("RB targets allowed by route type:\n\n" + table(pd.DataFrame({
                "route": rs.index, "tgt": rs.tgt.astype(int), "catch": rs.catch.map(pct), "YPT": rs.ypt.map(lambda v: f(v, 2)),
                "PPR/tgt": rs.ppr_tgt.map(lambda v: f(v, 2))})))
        # weekly top scorer
        wk = sk[(sk.opponent_team == tm) & sk.pos.isin(["RB", "WR", "TE"])].copy()
        rows = []
        for (w, pos), gdf in wk.groupby(["week", "pos"]):
            top = gdf.sort_values("fantasy_points_ppr", ascending=False).iloc[0]
            ln = (f"{line(top.carries, top.rushing_yards, top.rushing_tds)} rush, "
                    f"{int(top.targets)} tgt {line(top.receptions, top.receiving_yards, top.receiving_tds)} rec"
                    if pos == "RB" else
                    f"{int(top.targets)} tgt, {line(top.receptions, top.receiving_yards, top.receiving_tds)}"
                    + (f" (+{int(top.carries)}-{int(top.rushing_yards)} rush)" if top.carries > 0 else ""))
            rows.append({"wk": int(w), "pos": pos, "opp": top.team, "top player": top.player_display_name, "line": ln,
                         "PPR": f(top.fantasy_points_ppr), "pos total PPR": f(gdf.fantasy_points_ppr.sum())})
        if rows:
            wdf = pd.DataFrame(rows).sort_values(["pos", "wk"])
            s.append("Week by week: top scorer at each position vs this defense (RB line = car-yds-TD rush, tgt, rec-yds-TD):\n\n" + table(wdf))
        # weekly QBs faced (v1.1): the QB with the most pass attempts + carries, plus anyone else who played
        qwk = sk[(sk.opponent_team == tm) & (sk.pos == "QB")].copy()
        if len(qwk):
            qwk["fl"] = (qwk.sack_fumbles_lost.fillna(0) + qwk.rushing_fumbles_lost.fillna(0)
                         + qwk.receiving_fumbles_lost.fillna(0))
            qwk["vol"] = qwk.attempts.fillna(0) + qwk.sacks_suffered.fillna(0) + qwk.carries.fillna(0)
            rows = []
            for w, gdf in qwk.groupby("week"):
                gdf = gdf.sort_values("vol", ascending=False)
                q1 = gdf.iloc[0]
                others = gdf.iloc[1:]
                others = others[others.vol > 0]
                rows.append({
                    "wk": int(w), "opp": q1.team, "QB": q1.player_display_name,
                    "cmp/att": f"{int(q1.completions)}/{int(q1.attempts)}",
                    "pass yds": int(q1.passing_yards), "pass TD": int(q1.passing_tds),
                    "INT": int(q1.passing_interceptions), "sk": int(q1.sacks_suffered),
                    "rush": line(q1.carries, q1.rushing_yards, q1.rushing_tds), "FL": int(q1.fl),
                    "pts": f(q1.fantasy_points_ppr),
                    "other QBs": "; ".join(f"{o.player_display_name} {int(o.completions)}/{int(o.attempts)}, "
                                           f"{int(o.carries)} car, {f(o.fantasy_points_ppr)} pts"
                                           for _, o in others.iterrows()) or "–",
                    "all-QB pts": f(gdf.fantasy_points_ppr.sum())})
            s.append("Week by week: QBs vs this defense (main QB = most attempts + sacks + carries; rush = car-yds-TD; "
                     "pts = nflverse fantasy points: 4-pt pass TD, −2 INT, −2 fumble lost):\n\n" + table(pd.DataFrame(rows)))
        if tm in adj["def"] and adj["def"][tm][1]:
            s.append(adj["def"][tm][1])
        sec[tm].extend(s)

    # --- per-team offense
    sn = D["snaps"].copy()
    ro = D["roster"]
    pfr2gsis = ro.dropna(subset=["pfr_id", "gsis_id"]).drop_duplicates("pfr_id").set_index("pfr_id").gsis_id
    sn["player_id"] = sn.pfr_player_id.map(pfr2gsis)
    team_carries = st.groupby(["team", "week"]).carries.sum()
    rz = pbp[(pbp.rush == 1) | (pbp.pass_attempt == 1)].copy()
    rz["pid"] = rz.rusher_player_id.fillna(rz.receiver_player_id)
    rz10 = rz[rz.yardline_100 <= 10]
    rz5 = rz[rz.yardline_100 <= 5]
    # QB pressure / blitz by offense
    qb = db.copy()
    qb["press"] = qb.was_pressure.map(lambda v: np.nan if pd.isna(v) else float(v))
    qb["blitz"] = qb.n_blitzers.map(lambda v: np.nan if pd.isna(v) else float(v > 0))
    ox = offense_extras(D, ac, lgrid, t, run, teams)
    for tm in teams:
        s = [f"## {y} OFFENSE — {tname(tm)}"]
        s.append(ox[tm][0])
        q = qb[qb.posteam == tm]
        pr = pbp[(pbp.posteam == tm) & pbp.pass_oe.notna()]
        rows = [("Dropbacks", len(q)), ("EPA/dropback", f(q.epa.mean(), 3)), ("Sack rate", pct(q.sack.mean())),
                ("Pressure rate faced (NGS)", pct(q.press.mean())),
                ("EPA/db clean", f(q[q.press == 0].epa.mean(), 3)), ("EPA/db under pressure", f(q[q.press == 1].epa.mean(), 3)),
                ("Blitz rate faced (FTN)", pct(q.blitz.mean())),
                ("EPA/db vs blitz", f(q[q.blitz == 1].epa.mean(), 3)), ("EPA/db vs no blitz", f(q[q.blitz == 0].epa.mean(), 3)),
                ("Pass rate over expected", f(pr.pass_oe.mean(), 1) + " pts")]
        s.append("Team passing context:\n\n" + table(pd.DataFrame(rows, columns=["stat", "value"])))
        if tm in adj["off"]:
            s.append(adj["off"][tm][0])
        if ox[tm][1]:
            s.append(ox[tm][1])
        ps = st[(st.team == tm) & st.pos.isin(SKILL)]
        if ps.empty:
            sec[tm].extend(s); continue
        ids = ps.player_id.unique()
        tsn = sn[sn.team == tm]
        agg = []
        team_tgt = ps.targets.sum() if len(ps) else 0
        tteam = t[t.posteam == tm]
        for pid in ids:
            p = ps[ps.player_id == pid]
            nm, pos = p.player_display_name.iloc[0], p.pos.iloc[0]
            snp = tsn[tsn.player_id == pid]
            ptg = tteam[tteam.receiver_player_id == pid]
            tgt = int(p.targets.sum())
            car = int(p.carries.sum())
            if tgt == 0 and car == 0 and pos != "QB":
                continue
            agg.append({
                "player": nm, "pos": pos, "G": p.week.nunique(),
                "snap% avg": pct(snp.offense_pct.mean()) if len(snp) else "–",
                "tgt": tgt, "tgt share": pct(tgt / team_tgt if team_tgt else np.nan),
                "air yds share": pct(p.receiving_air_yards.sum() / max(ps.receiving_air_yards.clip(lower=0).sum(), 1)),
                "aDOT": f(p.receiving_air_yards.sum() / tgt) if tgt else "–",
                "rec-yds-TD": line(p.receptions.sum(), p.receiving_yards.sum(), p.receiving_tds.sum()),
                "YAC/rec": f(p.receiving_yards_after_catch.sum() / p.receptions.sum()) if p.receptions.sum() else "–",
                "MOF tgt%": pct((ptg.pass_location == "middle").mean()) if len(ptg) else "–",
                "car": car, "car share": pct(car / max(team_carries.loc[tm].sum(), 1)),
                "rush yds-TD": f"{int(p.rushing_yards.sum())}-{int(p.rushing_tds.sum())}",
                "RZ10 opps": int((rz10.pid == pid).sum()), "RZ5 opps": int((rz5.pid == pid).sum()),
                "PPR": f(p.fantasy_points_ppr.sum()), "PPR/g": f(p.fantasy_points_ppr.sum() / p.week.nunique()),
                "_sort": p.fantasy_points_ppr.sum()})
        if agg:
            a = pd.DataFrame(agg).sort_values("_sort", ascending=False).drop(columns="_sort")
            cur = D.get("next_team", {})
            if cur:
                a.insert(2, "now on", [cur.get(n, "?") for n in a.player])
            s.append("Player usage, season totals (RZ opps = carries + targets inside the 10 / 5):\n\n" + table(a))
        # route profile, man/zone, and pass location (targeted receiver)
        rec = tteam[tteam.tpos.isin(["WR", "TE", "RB"])]
        top_ids = rec.receiver_player_id.value_counts()
        top_ids = top_ids[top_ids >= (5 if D.get("weekly") else 15)].index
        if len(top_ids):
            name = ps.drop_duplicates("player_id").set_index("player_id").player_display_name
            if D["has_part"]:
                rp = rec[rec.receiver_player_id.isin(top_ids)].dropna(subset=["route"])
                rt = rp.groupby(["receiver_player_id", "route"]).size().unstack(fill_value=0)
                share = rt.div(rt.sum(axis=1), axis=0)
                lines = []
                for pid in share.index:
                    top = share.loc[pid].sort_values(ascending=False)
                    top = top[top > 0].head(7)
                    lines.append(f"- {name.get(pid, pid)} ({int(rt.loc[pid].sum())} charted tgts): " +
                                 ", ".join(f"{k.lower()} {pct(v)}" for k, v in top.items()))
                s.append("Target profile by route (share of targets):\n" + "\n".join(lines))
                mz = target_summary(rec[rec.receiver_player_id.isin(top_ids)].dropna(subset=["defense_man_zone_type"]),
                                    ["receiver_player_id", "defense_man_zone_type"]).reset_index()
                s.append("Results vs man/zone (targets):\n\n" + table(pd.DataFrame({
                    "player": mz.receiver_player_id.map(name), "coverage": mz.defense_man_zone_type.str.replace("_COVERAGE", "").str.lower(),
                    "tgt": mz.tgt.astype(int), "catch": mz.catch.map(pct), "YPT": mz.ypt.map(lambda v: f(v, 2)), "TD": mz.td})))
            dp = rec[rec.receiver_player_id.isin(top_ids)].copy()
            dp["depth"] = pd.cut(dp.air_yards, [-99, 0, 9, 19, 99], labels=["behind LOS", "0-9", "10-19", "20+"])
            dd = dp.groupby(["receiver_player_id", "depth"], observed=False).size().unstack(fill_value=0)
            dd = dd.div(dd.sum(axis=1), axis=0)
            s.append("Target depth mix (air yards):\n\n" + table(pd.DataFrame({
                "player": dd.index.map(name), **{c: dd[c].map(pct) for c in dd.columns}})))
        # RB run buckets
        rbr = run[(run.posteam == tm)]
        rbr = rbr[rbr.rusher_player_id.map(D["pos_by_id"]).replace(POS_MAP) == "RB"]
        vc = rbr.rusher_player_id.value_counts()
        vc = vc[vc >= (8 if D.get("weekly") else 15)]
        if len(vc):
            name = ps.drop_duplicates("player_id").set_index("player_id").player_display_name
            rows = []
            for pid in vc.index:
                r = rbr[rbr.rusher_player_id == pid]
                for kind, col in [("formation", "form"), ("box", "box"), ("direction/gap", "dir")]:
                    for b, gg in r.dropna(subset=[col]).groupby(col):
                        rows.append({"RB": name.get(pid, pid), "type": kind, "bucket": b, "car": len(gg),
                                     "YPC": f(gg.yards_gained.mean(), 2), "success": pct(gg.success.mean()),
                                     "EPA/rush": f(gg.epa.mean(), 3)})
            s.append(f"RB rushing by bucket (≥{8 if D.get('weekly') else 15} carries):\n\n" + table(pd.DataFrame(rows)))
        # weekly usage (current season only)
        if D.get("weekly"):
            wrows = []
            for pid in ids:
                p = ps[ps.player_id == pid].sort_values("week")
                if p.targets.sum() + p.carries.sum() == 0 and p.pos.iloc[0] != "QB":
                    continue
                for _, r in p.iterrows():
                    sp = tsn[(tsn.player_id == pid) & (tsn.week == r.week)]
                    wt = ps[ps.week == r.week].targets.sum()
                    wrows.append({"player": r.player_display_name, "pos": r.pos, "wk": int(r.week), "opp": r.opponent_team,
                                  "snap%": pct(sp.offense_pct.iloc[0]) if len(sp) else "–",
                                  "tgt": int(r.targets), "tgt share": pct(r.targets / wt if wt else np.nan),
                                  "rec-yds-TD": line(r.receptions, r.receiving_yards, r.receiving_tds),
                                  "aDOT": f(r.receiving_air_yards / r.targets) if r.targets else "–",
                                  "car": int(r.carries), "car share": pct(r.carries / max(team_carries.loc[(tm, r.week)], 1)),
                                  "rush yds-TD": f"{int(r.rushing_yards)}-{int(r.rushing_tds)}",
                                  "PPR": f(r.fantasy_points_ppr)})
            if wrows:
                s.append("Week by week usage:\n\n" + table(pd.DataFrame(wrows).sort_values(["player", "wk"])))
        if tm in adj["off"] and adj["off"][tm][1]:
            s.append(adj["off"][tm][1])
        sec[tm].extend(s)
    return sec


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seasons", nargs="+", type=int, required=True)
    ap.add_argument("--label", required=True)
    ap.add_argument("--raw", default="raw")
    ap.add_argument("--out", required=True)
    ap.add_argument("--weekly", action="store_true", help="include week-by-week player usage")
    a = ap.parse_args()
    os.makedirs(a.raw, exist_ok=True); os.makedirs(a.out, exist_ok=True)
    per_team, league, meta = {}, [], []
    for y in a.seasons:
        print("season", y)
        D = load(a.raw, y)
        D["weekly"] = a.weekly
        # map player -> current (latest) team for history docs
        nxt = fetch(a.raw, "roster", max(y + 1, a.seasons[-1] + 1)) if a.label == "history" else None
        if nxt is not None:
            nxt = nxt.sort_values("week") if "week" in nxt else nxt
            last = nxt.drop_duplicates("gsis_id", keep="last").set_index("gsis_id").team
            names = D["stats"].drop_duplicates("player_id").set_index("player_id").player_display_name
            D["next_team"] = {names[i]: last.get(i, "not on a roster") for i in names.index} if y == a.seasons[-1] else {}
        sec = season_docs(D, league)
        for tm, s in sec.items():
            per_team.setdefault(tm, []).append("\n\n".join(s))
        pbp = D["pbp"]
        meta.append(f"{y}: weeks {int(pbp.week.min())}–{int(pbp.week.max())}, {pbp.game_id.nunique()} games, "
                    f"last game {pbp.game_date.max()}; NGS participation {'yes' if D['has_part'] else 'NO (route, man/zone, coverage, pressure unavailable)'}")
    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    span = f"{a.seasons[0]}–{a.seasons[-1]}" if len(a.seasons) > 1 else str(a.seasons[0])
    hdr = (f"Source: nflverse (play-by-play, NGS participation, FTN charting, player stats, snap counts). "
           f"Built {stamp}. Regular season only.\n" + "\n".join(f"- {m}" for m in meta))
    for tm, parts in per_team.items():
        with open(os.path.join(a.out, fname(tm, a.label)), "w") as fh:
            fh.write(f"# {tname(tm)} — Matchup Witch data, {span} ({a.label})\n\n{hdr}\n\n" + "\n\n".join(parts) + "\n")
    with open(os.path.join(a.out, f"LEAGUE_{a.label}.md"), "w") as fh:
        fh.write(f"# League averages — Matchup Witch data, {span} ({a.label})\n\n{hdr}\n\n" + "\n\n".join(league) + "\n")
    print("wrote", len(per_team) + 1, "docs to", a.out)


if __name__ == "__main__":
    main()
