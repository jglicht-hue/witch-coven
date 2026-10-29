#!/usr/bin/env python3
"""v1_tank_sim.py - Monte Carlo of the rest-of-regular-season MAX POINTS race (Sleeper "ppts", the best possible
lineup each week). In The Mega Bowl, picks 1-6 go to the non-playoff teams in order of lowest max points, so this
estimates where our own rookie pick lands under different roster moves.

Inputs
  --rosters      Sleeper /league/<id>/rosters JSON (pasted or saved). Supplies each roster's players, IR (reserve)
                 and max points so far (settings.ppts + ppts_decimal/100).
  --projections  CSV with columns fp_id,name,pos,team,ros_ppr: FantasyPros rest-of-season projections from the
                 connector (get_projections, projection_type="ros", use the points_ppr field). Team codes may be
                 FantasyPros' (JAC, LAR, ...); they are mapped to nflverse's.
  --me 6 --field 5,6     rosters to rank by max points (the projected non-playoff teams). Default: 5,6.
  --scenario "label|sell=ID,ID|add=ID|out=ID"   repeatable; IDs are Sleeper player ids. sell = removed from our
                 roster; add = added to it; out = held at zero for every simulated week (e.g. a player shut down).
                 A "Keep everyone" scenario is always run first.
  --start-miss ID=P      repeatable: chance the player misses the FIRST simulated week (e.g. 1 - FantasyPros'
                 probability_of_playing). Later weeks follow the absence chain below.
  --activate ID,ID       IR players (any roster) expected back this season: counted at their projection, whose
                 rest-of-season total already discounts the games they are expected to miss.
  --scale RID=F  stress test: multiply roster RID's projections by F (e.g. to hold a rival to his pace so far).
  --sigma 0.25   projection error: each player's true level for the rest of the season is drawn as
                 projection x lognormal(sd=sigma). 0 = trust projections exactly.
  --last-week 14 last regular-season week (the week before playoff_week_start).

Model (calibrated on the 2025 regular season, nflverse weekly player stats):
  - Weekly score = per-game mean x a ratio drawn from 2025 regulars at the same position (6+ games, 6+ PPR/g),
    i.e. each week's PPR points / that player's season mean. Keeps the real skew toward boom weeks.
  - Absence: two-state chain. P(miss | played last week) and P(miss | missed last week) are measured from 2025
    (a regular's team games between his first and last appearance). The projection's per-game mean is divided by
    (1 - steady-state miss rate), because FantasyPros' rest-of-season totals already discount expected absences.
  - Byes come from nflverse games.csv. IR players (Sleeper reserve) are left out. Players with no projection
    row count as zero and are listed in the output.
  - Each simulated week takes the best legal lineup: QB, RB, RB, WR, WR, WR, TE, FLEX, FLEX (FLEX = RB/WR/TE).
Not modelled: other managers' moves, teammates' scores moving together, league scoring differences from
FantasyPros' (e.g. -1 per interception), and whether Sleeper counts IR players in max points.

  python3 v1_tank_sim.py --rosters rosters.json --projections proj.csv --scenario "Sell Moore|sell=4983"
Downloads are cached in ./witch_cache (shared with the other coven scripts).
"""
import argparse, json, os, sys, time, urllib.request
import numpy as np, pandas as pd

NV = "https://github.com/nflverse/nflverse-data/releases/download"
GAMES = "https://raw.githubusercontent.com/nflverse/nfldata/master/data/games.csv"
IDS = "https://raw.githubusercontent.com/dynastyprocess/data/master/files/db_playerids.csv"
FP2NV = {"JAC": "JAX", "LAR": "LA", "WSH": "WAS", "KCC": "KC", "SFO": "SF", "NEP": "NE", "GBP": "GB", "TBB": "TB",
         "LVR": "LV", "NOS": "NO"}
CACHE = "witch_cache"


def fetch(url, name, max_age_h=6):
    os.makedirs(CACHE, exist_ok=True); p = os.path.join(CACHE, name)
    if not os.path.exists(p) or time.time() - os.path.getmtime(p) > max_age_h * 3600:
        urllib.request.urlretrieve(url, p)
    return p


def calibrate(season):
    s = pd.read_csv(fetch(f"{NV}/stats_player/stats_player_week_{season}.csv", f"stats_player_week_{season}.csv", 24 * 30),
                    low_memory=False)
    s = s[(s.season_type == "REG") & s.position.isin(["QB", "RB", "WR", "TE"]) & s.player_id.notna()]
    g = pd.read_csv(fetch(GAMES, "games.csv")); g = g[(g.season == season) & (g.game_type == "REG")]
    tg = {}
    for r in g.itertuples():
        tg.setdefault(r.home_team, set()).add(r.week); tg.setdefault(r.away_team, set()).add(r.week)
    a = s.groupby("player_id").agg(n=("week", "nunique"), ppg=("fantasy_points_ppr", "mean"))
    reg = a[(a.n >= 6) & (a.ppg >= 6)]
    s = s[s.player_id.isin(reg.index)].copy(); s["ratio"] = s.fantasy_points_ppr / s.player_id.map(reg.ppg)
    ratios = {p: s[s.position == p].ratio.values for p in ["QB", "RB", "WR", "TE"]}
    t = {"aa": 0, "am": 0, "ma": 0, "mm": 0}
    for _, grp in s.groupby("player_id"):
        wk = sorted(w for w in tg.get(grp.team.iloc[-1], []) if grp.week.min() <= w <= grp.week.max())
        seq = [w in set(grp.week) for w in wk]
        for x, y in zip(seq, seq[1:]):
            t[("a" if x else "m") + ("a" if y else "m")] += 1
    pa = t["am"] / (t["aa"] + t["am"]); pm = t["mm"] / (t["ma"] + t["mm"])
    return ratios, pa, pm


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rosters", required=True); ap.add_argument("--projections", required=True)
    ap.add_argument("--me", type=int, default=6); ap.add_argument("--field", default="5,6")
    ap.add_argument("--scenario", action="append", default=[]); ap.add_argument("--start-miss", action="append", default=[])
    ap.add_argument("--sigma", type=float, default=0.25); ap.add_argument("--n", type=int, default=20000)
    ap.add_argument("--seed", type=int, default=29); ap.add_argument("--last-week", type=int, default=14)
    ap.add_argument("--season", type=int, default=2026); ap.add_argument("--calib-season", type=int, default=2025)
    ap.add_argument("--activate", action="append", default=[],
                    help="Sleeper ids on a roster's IR who are expected back; counted at their projection")
    ap.add_argument("--scale", action="append", default=[],
                    help="RID=F stress test: multiply every projection on roster RID by F")
    a = ap.parse_args(); rng = np.random.default_rng(a.seed)

    rosters = {r["roster_id"]: r for r in json.load(open(a.rosters))}
    field = [int(x) for x in a.field.split(",")]
    if a.me not in field: field.append(a.me)
    ids = pd.read_csv(fetch(IDS, "db_playerids.csv", 24 * 7), dtype=str).dropna(subset=["sleeper_id"]).drop_duplicates("sleeper_id")
    s2fp = dict(zip(ids.sleeper_id, ids.fantasypros_id)); s2name = dict(zip(ids.sleeper_id, ids.name))
    pr = pd.read_csv(a.projections, dtype={"fp_id": str}); pr["team"] = pr.team.replace(FP2NV)
    proj = {r.fp_id: (r.name, r.pos, r.team, float(r.ros_ppr)) for r in pr.itertuples()}

    g = pd.read_csv(fetch(GAMES, "games.csv")); g = g[(g.season == a.season) & (g.game_type == "REG")]
    done = g.groupby("week").result.apply(lambda r: r.notna().all())
    first = int(min(w for w, d in done.items() if not d)); weeks = list(range(first, a.last_week + 1))
    last_reg = int(g.week.max())
    def ngames(t, lo, hi):
        return int(((g.week >= lo) & (g.week <= hi) & ((g.home_team == t) | (g.away_team == t))).sum())

    ratios, PA, PM = calibrate(a.calib_season); STAT = PA / (PA + 1 - PM)
    print(f"Simulating Weeks {weeks[0]}-{weeks[-1]} | {a.n} runs | sigma {a.sigma} | "
          f"P(miss|played) {PA:.3f}, P(miss|missed) {PM:.3f} (from {a.calib_season})")
    start_miss = {k: float(v) for k, v in (x.split("=") for x in a.start_miss)}

    activate = {x.strip() for v in a.activate for x in v.split(",") if x.strip()}
    scale = {int(k): float(v) for k, v in (x.split("=") for x in a.scale)}

    def players(rid, sell=(), add=(), out=()):
        r = rosters[rid]; reserve = set(r.get("reserve") or []) - activate
        ps = [p for p in r["players"] if p not in reserve and p not in sell] + list(add)
        rows, missing = [], []
        for p in ps:
            fp = s2fp.get(p)
            if fp not in proj: missing.append(s2name.get(p, p)); continue
            name, pos, team, pts = proj[fp]
            if pos not in ("QB", "RB", "WR", "TE"): continue
            n_rest = ngames(team, first, last_reg)
            mu = 0.0 if (p in out or n_rest == 0) else pts / n_rest / (1 - STAT) * scale.get(rid, 1.0)
            rows.append((p, name, pos, team, mu))
        return rows, missing

    def simulate(rows):
        N, P = a.n, len(rows)
        pos = np.array([r[2] for r in rows]); mu = np.array([r[4] for r in rows])
        play = np.array([[ngames(r[3], w, w) > 0 for w in weeks] for r in rows]).reshape(P, len(weeks))
        talent = np.exp(rng.normal(-a.sigma ** 2 / 2, a.sigma, (N, P)))
        p0 = np.array([start_miss.get(r[0], STAT) for r in rows])
        miss = rng.random((N, P)) < p0[None, :]
        tot = np.zeros(N); rr = np.arange(N)[:, None]
        for wi in range(len(weeks)):
            if wi:
                u = rng.random((N, P)); miss = np.where(miss, u < PM, u < PA)
            sc = np.zeros((N, P))
            for p in ("QB", "RB", "WR", "TE"):
                idx = np.where(pos == p)[0]
                if len(idx): sc[:, idx] = mu[idx] * talent[:, idx] * rng.choice(ratios[p], (N, len(idx)))
            sc = np.where(miss | ~play[:, wi][None, :], 0, sc)
            used = np.zeros((N, P), bool); week_pts = np.zeros(N)
            for p, k in (("QB", 1), ("RB", 2), ("WR", 3), ("TE", 1)):
                idx = np.where(pos == p)[0]
                if not len(idx): continue
                o = np.argsort(-sc[:, idx], axis=1)[:, :k]
                used[rr, idx[o]] = True; week_pts += np.take_along_axis(sc[:, idx], o, 1).sum(1)
            fl = np.where(used | (pos == "QB")[None, :], -1, sc)
            week_pts += (-np.sort(-fl, axis=1))[:, :2].clip(0).sum(1)
            tot += week_pts
        return tot

    so_far = {rid: rosters[rid]["settings"]["ppts"] + rosters[rid]["settings"].get("ppts_decimal", 0) / 100 for rid in field}
    print("Max points so far:", {rid: round(v, 2) for rid, v in so_far.items()})
    others = {}
    for rid in field:
        if rid == a.me: continue
        rows, miss = players(rid)
        if miss: print(f"  roster {rid}: no projection for {', '.join(miss)} (counted as zero)")
        others[rid] = so_far[rid] + simulate(rows)
        print(f"  roster {rid}: projected {np.mean(others[rid] - so_far[rid]) / len(weeks):.1f} max points a week")

    scen = [("Keep everyone", (), (), ())]
    for sdef in a.scenario:
        parts = sdef.split("|"); kw = {"sell": (), "add": (), "out": ()}
        for x in parts[1:]:
            k, v = x.split("="); kw[k.strip()] = tuple(i.strip() for i in v.split(",") if i.strip())
        scen.append((parts[0], kw["sell"], kw["add"], kw["out"]))
    print(f"\n{'Scenario':48s} {'us/wk':>6s} {'P(pick1)':>9s}  slot distribution (1..{len(field)})")
    for lab, sell, add, out in scen:
        rows, miss = players(a.me, sell, add, out)
        us = so_far[a.me] + simulate(rows)
        slot = 1 + sum((others[r] < us).astype(int) for r in others)
        dist = " ".join(f"{100 * (slot == k).mean():4.1f}%" for k in range(1, len(field) + 1))
        print(f"{lab:48s} {np.mean(us - so_far[a.me]) / len(weeks):6.1f} {100 * (slot == 1).mean():8.1f}%  {dist}")
        if miss: print(f"    no projection (counted as zero): {', '.join(miss)}")
        if len(others) == 1:
            gap = us - list(others.values())[0]
            print(f"    gap to roster {list(others)[0]} at season end, p10/p50/p90: {np.percentile(gap, [10, 50, 90]).round(0)}")


if __name__ == "__main__":
    main()
