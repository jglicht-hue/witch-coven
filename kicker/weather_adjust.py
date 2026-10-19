"""Weather adjustment for Kicker Wizerd projections (to-do #13, added 2026-09-28).

Use: for an OUTDOOR game (is_enclosed == 0 in data/weekly_projections_latest.csv,
or a retractable roof confirmed open), take the kicker's row from that file and
the game-time forecast, and call adjust(row, wind_mph, temp_f, rain, snow). It
returns the weather-adjusted expected attempts, make chances, projected points,
middle-80% outcome range and full distribution. Pure Python, no packages needed.

Where the numbers come from: claude/11b_weather_effects.R estimated weather
effects on 2016-2025 regular-season games. A term was kept only if it beat at
least 95% of placebo shuffles (placebo share <= 0.05, leave-one-season-out).
See claude/11_weather_log.md. Updated 2026-09-28 (round 2): wind on 50+
attempts added (the user set the pass line to <= 0.05); rain vs snow
separately and the interactions wind x cold, wind x rain, wind x snow and
cold x snow were tested and none passed, so rain and snow share one effect.
Round 3 (same day, user's suggestion): non-linear wind. A squared term and
wind bands (15-19 mph, 20+ mph) were tested for all 8 outcomes; only the bands
passed, for XP attempts (placebo share 0.045). The user chose to keep wind
linear (the bands implied a 20 mph game projects better than a 15 mph one,
and one pass in 16 tests is about what chance produces).
Adopted effects (per unit, relative to the average outdoor game of 2023-2025):
  XP attempts        wind  : x exp(-0.0059679 per mph)
  40-49 FG attempts  cold  : x exp(-0.011997 per degree below 40F)
  50+ FG attempts    cold  : x exp(-0.029032 per degree below 40F)
                     wind  : x exp(-0.011762 per mph)
  0-39 FG make       precip: log-odds -0.53315 if rain or snow
  XP make            wind  : log-odds -0.022451 per mph
Nothing passed for 0-39 attempts or for 40-49 / 50+ make chances.

The weekly models have no weather terms, so their outdoor projections reflect
average outdoor weather; each adjustment is applied to (forecast - reference).
The distribution includes the XP/FG dependence added 2026-09-28 (GAMMA below).
The confidence interval isn't recomputed: ci_low / ci_high are shifted by the
change in projected points (an approximation - say so when you report it).
"""
import math

EFFECTS = {  # outcome -> {term: coefficient}
    "xp_attempts": {"wind": -0.0059679},
    "att_039": {},
    "att_4049": {"cold": -0.011997},
    "att_50": {"cold": -0.029032, "wind": -0.011762},
    "make_039": {"precip": -0.53315},
    "make_4049": {},
    "make_50": {},
    "make_xp": {"wind": -0.0224510},
}
REFERENCE = {"wind": 7.8532, "cold": 1.2037, "precip": 0.077064}  # average outdoor game, 2023-2025


def _logit(p):
    return math.log(p / (1 - p))


def _expit(x):
    return 1 / (1 + math.exp(-x))


def _poisson_pmf(mean, tail=1e-10):
    if mean <= 0:
        return [1.0]
    out, k, p, cum = [], 0, math.exp(-mean), 0.0
    while True:
        out.append(p)
        cum += p
        if cum >= 1 - tail and k >= mean:
            return out
        k += 1
        p *= mean / k


# XP/FG dependence (added 2026-09-28; values from models/points_gamma.csv, fit by
# claude/07_fit_volume_models.R): FG attempts in each range move with the game's
# XP attempts k as lambda_r * exp(gamma_r * (k - lambda_xp)), rescaled to keep
# the mean. Update these if 07 is refit. See claude/12_width_fix_log.md.
GAMMA = (-0.0821077, -0.1016189, -0.1559659)  # 0-39, 40-49, 50+


def _binom_pmf(n, p):
    return [math.comb(n, m) * p ** m * (1 - p) ** (n - m) for m in range(n + 1)]


def _convolve(a, b):
    """a, b: {points: prob}."""
    out = {}
    for x, px in a.items():
        for y, py in b.items():
            out[x + y] = out.get(x + y, 0.0) + px * py
    return out


def _weighted(mean, weight):
    return {weight * k: p for k, p in enumerate(_poisson_pmf(mean))}


def points_distribution(l_xp, l_039, l_4049, l_50, p_039, p_4049, p_50, p_xp, gamma=GAMMA):
    """Exact distribution of fantasy points, same method as points_pmf_dep() in
    claude/08_points_distribution.R. Returns {points: probability}."""
    pk = _poisson_pmf(l_xp)
    lam, pr = (l_039, l_4049, l_50), (p_039, p_4049, p_50)
    norm = [sum(pk[k] * math.exp(g * (k - l_xp)) for k in range(len(pk))) for g in gamma]
    dist = {}
    for k, pkk in enumerate(pk):
        if pkk < 1e-12:
            continue
        lk = [lam[r] * math.exp(gamma[r] * (k - l_xp)) / norm[r] for r in range(3)]
        d = _weighted(lk[0] * pr[0], 3)
        d = _convolve(d, _weighted(lk[1] * pr[1], 4))
        d = _convolve(d, _weighted(lk[2] * pr[2], 5))
        d = _convolve(d, _weighted(sum(lk[r] * (1 - pr[r]) for r in range(3)), -1))
        d = _convolve(d, dict(enumerate(_binom_pmf(k, p_xp))))
        for pts, pr_ in d.items():
            dist[pts] = dist.get(pts, 0.0) + pkk * pr_
    total = sum(dist.values())
    return {k: v / total for k, v in sorted(dist.items()) if v / total > 1e-9}


def summarise(dist, lower_q=0.10, upper_q=0.90):
    pts = sorted(dist)
    mean = sum(k * dist[k] for k in pts)
    cum, lo, hi = 0.0, None, None
    for k in pts:
        cum += dist[k]
        if lo is None and cum >= lower_q - 1e-12:
            lo = k
        if hi is None and cum >= upper_q - 1e-12:
            hi = k
    inside = sum(dist[k] for k in pts if lo <= k <= hi)
    return {"projected_points": mean, "outcome_low": lo, "outcome_high": hi, "outcome_range_prob": inside,
            "prob_negative": sum(dist[k] for k in pts if k < 0), "prob_10plus": sum(dist[k] for k in pts if k >= 10)}


def adjust(row, wind_mph, temp_f, rain=False, snow=False):
    """row: dict of one kicker's columns from weekly_projections_latest.csv (numbers).
    wind_mph: forecast sustained wind at kickoff; temp_f: forecast temperature (F);
    rain / snow: True if rain (or drizzle/showers) / snow (or sleet/flurries) is
    expected during the game. They currently share one effect ("precip")."""
    x = {"wind": float(wind_mph), "cold": max(0.0, 40.0 - float(temp_f)), "precip": 1.0 if (rain or snow) else 0.0}
    delta = {t: x[t] - REFERENCE[t] for t in x}

    def shift(outcome):
        return sum(c * delta[t] for t, c in EFFECTS[outcome].items())

    l = {k: float(row["exp_" + k]) * math.exp(shift(k)) for k in ("xp_attempts", "att_039", "att_4049", "att_50")}
    p = {r: _expit(_logit(float(row["p_" + r])) + shift("make_" + r)) for r in ("039", "4049", "50", "xp")}
    dist = points_distribution(l["xp_attempts"], l["att_039"], l["att_4049"], l["att_50"],
                               p["039"], p["4049"], p["50"], p["xp"])
    s = summarise(dist)
    change = s["projected_points"] - float(row["projected_points"])
    return {**s, "change_vs_file": change,
            "ci_low_shifted": float(row["ci_low"]) + change, "ci_high_shifted": float(row["ci_high"]) + change,
            "exp_attempts": l, "make_chances": p, "distribution": dist, "weather_used": x}


if __name__ == "__main__":
    # Self-test: with the reference weather (and no rain/snow in both the
    # reference and the forecast) the adjustment must reproduce the file.
    import csv, sys
    path = sys.argv[1] if len(sys.argv) > 1 else "data/weekly_projections_latest.csv"
    rows = list(csv.DictReader(open(path)))
    saved = dict(REFERENCE)
    REFERENCE.update(precip=0.0)  # reference = a dry game at average wind and temperature
    worst = max(abs(adjust(r, REFERENCE["wind"], 40 - REFERENCE["cold"])["projected_points"] -
                    float(r["projected_points"])) for r in rows)
    REFERENCE.update(saved)
    print(f"{len(rows)} rows; largest |adjusted - file| at reference weather: {worst:.4f} (file is rounded to 4 decimals)")
