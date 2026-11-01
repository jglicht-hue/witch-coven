"""RB prospect study, step 2: college player-season table from SportsDataverse player_stats (play level).
Targets = catches + incomplete targets (the target_* columns log incompletions only).
Usage: python3 -I college.py <cfb_repo_dir> <first_season> <last_season> <out_csv>
"""
import sys, numpy as np, pandas as pd

R, Y0, Y1, OUT = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
P4 = {"SEC": "SEC", "Big Ten": "B1G", "Big 12": "OP4", "ACC": "OP4", "Pac-12": "OP4"}
out = []
for y in range(Y0, Y1 + 1):
    d = pd.read_parquet(f"{R}/player_stats/parquet/player_stats_{y}.parquet")
    d["games_key"] = d.game_id
    ru = d[d.rush_player_id.notna()].copy()
    ru["pid"] = ru.rush_player_id.astype("int64")
    ru["succ"] = np.where(ru.down == 1, ru.rush_yds >= 0.4 * ru.distance,
                 np.where(ru.down == 2, ru.rush_yds >= 0.6 * ru.distance, ru.rush_yds >= ru.distance))
    ru["td"] = (ru.touchdown_player_id == ru.rush_player_id)
    ru["in10"] = ru.yards_to_goal <= 10
    ru["e10"] = ru.rush_yds >= 10; ru["e20"] = ru.rush_yds >= 20
    tm = ru.clock_minutes * 60 + ru.clock_seconds
    ru["late"] = ru.period.isin([2, 4]) & (tm <= 120)
    ru["third"] = ru.down >= 3
    rc = d[d.reception_player_id.notna()].copy(); rc["pid"] = rc.reception_player_id.astype("int64")
    ic = d[d.target_player_id.notna()].copy(); ic["pid"] = ic.target_player_id.astype("int64")
    tg = pd.concat([rc[["pid", "team", "game_id", "down", "period", "clock_minutes", "clock_seconds"]].assign(rec=1, ryds=rc.reception_yds.fillna(0)),
                    ic[["pid", "team", "game_id", "down", "period", "clock_minutes", "clock_seconds"]].assign(rec=0, ryds=0)])
    tt = tg.clock_minutes * 60 + tg.clock_seconds
    tg["late"] = tg.period.isin([2, 4]) & (tt <= 120); tg["third"] = tg.down >= 3
    fu = d[d.fumble_player_id.notna()].copy(); fu["pid"] = fu.fumble_player_id.astype("int64")

    g_r = ru.groupby(["pid", "team"]).agg(name=("rush_player", "first"), car=("rush_yds", "size"), ryd=("rush_yds", "sum"),
        rtd=("td", "sum"), succ=("succ", "sum"), in10=("in10", "sum"), e10=("e10", "sum"), e20=("e20", "sum"),
        late_c=("late", "sum"), third_c=("third", "sum"), g_r=("game_id", "nunique"))
    g_t = tg.groupby(["pid", "team"]).agg(tgt=("rec", "size"), rec=("rec", "sum"), recyd=("ryds", "sum"),
        late_t=("late", "sum"), third_t=("third", "sum"))
    g_f = fu.groupby(["pid", "team"]).size().rename("fum")
    games = pd.concat([ru[["pid", "team", "game_id"]], tg[["pid", "team", "game_id"]]]).drop_duplicates().groupby(["pid", "team"]).size().rename("games")
    p = pd.concat([g_r, g_t, g_f, games], axis=1).reset_index()
    for c in ["car", "ryd", "rtd", "succ", "in10", "e10", "e20", "late_c", "third_c", "tgt", "rec", "recyd", "late_t", "third_t", "fum"]:
        p[c] = p[c].fillna(0)
    nm = pd.concat([rc[["pid", "reception_player"]].rename(columns={"reception_player": "n2"})]).groupby("pid").n2.first()
    p["name"] = p.name.fillna(p.pid.map(nm))
    # team totals
    T = pd.DataFrame({
        "t_car": ru.groupby("team").size(), "t_ryd": ru.groupby("team").rush_yds.sum(), "t_in10": ru.groupby("team").in10.sum(),
        "t_tgt": tg.groupby("team").size(), "t_recyd": tg.groupby("team").ryds.sum(),
        "t_late": ru.groupby("team").late.sum() + tg.groupby("team").late.sum(),
        "t_third": ru.groupby("team").third.sum() + tg.groupby("team").third.sum(),
        "t_games": d.groupby("team").game_id.nunique(),
        "conf": d.groupby("team").conference.agg(lambda s: s.mode().iat[0] if len(s.mode()) else None)}).reset_index().rename(columns={"index": "team"})
    p = p.merge(T, on="team", how="left")
    # teammates' rushing (everyone else on the team), for team-adjusted efficiency
    # teammates = non-QB carriers (QB runs and scrambles excluded via roster position)
    ros = pd.read_parquet(f"{R}/rosters/parquet/cfb_rosters_{y}.parquet", columns=["athlete_id", "position", "weight", "height"])
    ros = ros.drop_duplicates("athlete_id")
    qb = set(ros[ros.position == "QB"].athlete_id.astype("int64"))
    nq = ru[~ru.pid.isin(qb)]
    tq = nq.groupby("team").agg(nq_car=("rush_yds", "size"), nq_ryd=("rush_yds", "sum"), nq_succ=("succ", "sum")).reset_index()
    p = p.merge(tq, on="team", how="left")
    p["oth_car"] = p.nq_car - p.car; p["oth_ryd"] = p.nq_ryd - p.ryd; p["oth_succ"] = p.nq_succ - p.succ
    rr = ros.set_index(ros.athlete_id.astype("int64"))
    p["pos"] = p.pid.map(rr.position); p["lwt"] = p.pid.map(rr.weight); p["lht"] = p.pid.map(rr.height)
    p["season"] = y
    out.append(p)
    print(y, "player-teams:", len(p), flush=True)
c = pd.concat(out)
c["conf_tier"] = c.conf.map(P4).fillna("G5/other")
c.to_csv(OUT, index=False)
print("rows", len(c))
