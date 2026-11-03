# JAX Jacksonville Jaguars — Matchup Witch data, 2026 (current)

Source: nflverse (play-by-play, NGS participation, FTN charting, player stats, snap counts). Built 2026-11-03 14:53 UTC. Regular season only.
- 2026: weeks 1–8, 121 games, last game 2026-11-02; NGS participation NO (route, man/zone, coverage, pressure unavailable)

## 2026 DEFENSE — JAX Jacksonville Jaguars (7 games)

Flags, 2026 (leads to test, not verdicts; rank 1 = best D, among teams with enough plays; see README):

Weak (bottom ~15%):
- pass EPA/att, int left: +0.82 (lg +0.31; 29/32; n=18)
- rush EPA, runs, right tackle: 0.160 (lg -0.064; 29/32; n=11)
- pass EPA/att, deep right: 1.24 (lg +0.33; 23/26; n=13)

Strong (top ~15%):
- run D, EPA/rush: -0.192 (lg -0.075; 1/32)
- PPR/g allowed, RB: 17.0 (lg 22.2; 2/32)
- pass EPA/att, short middle: -0.38 (lg +0.05; 2/32; n=24)
- pass EPA/att, short left: -0.37 (lg +0.04; 2/32; n=68)
- rush EPA, ≤6 box: -0.262 (lg -0.079; 2/32; n=57)
- pass EPA/att, deep left: -0.25 (lg +0.35; 3/23; n=9)
- rush EPA, runs, right end: -0.248 (lg 0.009; 3/31; n=14)
- pass EPA/att, short right: -0.25 (lg +0.01; 3/32; n=64)
- run D, YPC: 3.40 (lg 4.10; 4/32)
- run D, 10+ yd runs/game: 1.57 (lg 2.29; 4/32)

Fantasy points allowed (PPR, nflverse scoring incl. rushing, fumbles, 2-pt). Rank 1 = fewest allowed.

| pos | PPR total | PPR/game | rank |
|---|---|---|---|
| QB | 100.2 | 14.3 | 9 |
| RB | 118.8 | 17.0 | 2 |
| WR | 258.5 | 36.9 | 27 |
| TE | 76.7 | 11.0 | 8 |

Unit stats (rank 1 = best defense):

| stat | value | rank |
|---|---|---|
| EPA/dropback | -0.050 | 6 |
| YPA | 7.64 | 25 |
| Comp % | 67% | 26 |
| 20+ yd completions/game | 3.00 | 17 |
| Sack rate | 6% | 22 |
| Pressure rate (NGS) | – | – |
| Blitz rate (FTN: 1+ blitzer) | 30% | – |
| Man coverage rate (NGS) | – | – |
| EPA/rush (designed runs) | -0.192 | 1 |
| YPC | 3.40 | 4 |
| Rush success rate | 37% | 8 |
| Stuff rate (≤0 yds) | 20% | 10 |
| 10+ yd runs/game | 1.57 | 4 |
| 20+ yd runs/game | 0.14 | – |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing offense's adjusted rating from its other games; diff = allowed − expected; adjusted = league avg + diff; rank 1 = best defense; thin = games where that rating rests on under 100 plays; method in README):

| stat | allowed | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 3.40 | 3.85 | -0.45 | 3.65 | 9/32 | 7 | 0 |
| Run success rate | 36.6% | 39.0% | -2.4 | 38.3% | 10/32 | 7 | 0 |
| EPA/rush | -0.192 | -0.085 | -0.107 | -0.182 | 3/32 | 7 | 0 |
| EPA/dropback | -0.050 | 0.044 | -0.095 | -0.041 | 9/32 | 7 | 0 |
| YPA | 7.64 | 6.73 | +0.91 | 7.97 | 28/32 | 7 | 0 |
| Sack rate | 5.6% | 6.6% | -1.0 | 5.1% | 24/32 | 7 | 0 |

QB rushing allowed (runs + scrambles): 23 car, 93 yds, 1 TD; 13.3 yds/g (rank 10/32; lg 16.7); scramble rate 5% (lg 5%)

Passing allowed by throw (rank by EPA/att among teams with ≥8 att; share = opp. QBs' share of att here, usual = their share in other games):

| cell | att | comp | YPA | TD | INT | EPA | rank | share | usual |
|---|---|---|---|---|---|---|---|---|---|
| short left | 68 | 69% | 4.68 | 2 | 4 | -0.37 | 2/32 | 28% | 27% |
| short middle | 24 | 62% | 5.58 | 0 | 1 | -0.38 | 2/32 | 10% | 12% |
| short right | 64 | 75% | 4.94 | 2 | 3 | -0.25 | 3/32 | 27% | 30% |
| int left | 18 | 72% | 12.28 | 0 | 0 | 0.82 | 29/32 | 8% | 6% |
| int middle | 14 | 71% | 11.00 | 1 | 1 | 0.73 | 23/32 | 6% | 6% |
| int right | 28 | 57% | 8.82 | 1 | 0 | 0.47 | 20/31 | 12% | 8% |
| deep left | 9 | 22% | 7.22 | 0 | 0 | -0.25 | 3/23 | 3% | 4% |
| deep middle | 4 | 75% | 36.25 | 1 | 0 | 2.70 | – | 2% | 2% |
| deep right | 13 | 54% | 19.23 | 1 | 0 | 1.24 | 23/26 | 6% | 6% |

Targets allowed by receiver position:

| pos | tgt | catch | YPT | TD | PPR/tgt |
|---|---|---|---|---|---|
| RB | 45 | 82% | 5.64 | 0 | 1.39 |
| WR | 141 | 67% | 9.72 | 4 | 1.82 |
| TE | 47 | 62% | 4.81 | 4 | 1.61 |

Run defense by bucket (box count from FTN charting):

| type | bucket | rushes | YPC | success | EPA/rush |
|---|---|---|---|---|---|
| box | 7 | 63 | 3.27 | 30% | -0.192 |
| box | 8+ | 22 | 2.50 | 45% | -0.010 |
| box | ≤6 | 57 | 3.89 | 40% | -0.262 |
| direction/gap | ? | 2 | 0.00 | 0% | -3.459 |
| direction/gap | left end | 23 | 3.26 | 43% | -0.209 |
| direction/gap | left guard | 18 | 2.83 | 44% | -0.180 |
| direction/gap | left tackle | 12 | 6.25 | 42% | -0.041 |
| direction/gap | middle | 46 | 3.02 | 30% | -0.131 |
| direction/gap | right end | 14 | 4.07 | 36% | -0.248 |
| direction/gap | right guard | 16 | 3.00 | 31% | -0.252 |
| direction/gap | right tackle | 11 | 3.45 | 45% | 0.160 |
| offense formation | shotgun | 50 | 3.42 | 44% | -0.279 |
| offense formation | under center | 92 | 3.39 | 33% | -0.145 |

RB targets allowed by route type:

| route | tgt | catch | YPT | PPR/tgt |
|---|---|---|---|---|
| (route n/a) | 34 | 79% | 5.65 | 1.36 |
| screen | 11 | 91% | 5.64 | 1.47 |

Week by week: top scorer at each position vs this defense (RB line = car-yds-TD rush, tgt, rec-yds-TD):

| wk | pos | opp | top player | line | PPR | pos total PPR |
|---|---|---|---|---|---|---|
| 1 | RB | CLE | Quinshon Judkins | 12-33-0 rush, 2 tgt 2-17-0 rec | 7.0 | 12.6 |
| 2 | RB | DEN | Jonah Coleman | 10-39-1 rush, 3 tgt 3-19-0 rec | 14.8 | 24.5 |
| 3 | RB | NE | Rhamondre Stevenson | 7-22-0 rush, 3 tgt 3-16-0 rec | 6.8 | 14.4 |
| 4 | RB | CIN | Chase Brown | 9-10-0 rush, 11 tgt 11-71-0 rec | 19.1 | 19.8 |
| 5 | RB | PHI | Will Shipley | 5-6-1 rush, 2 tgt 1-7-0 rec | 8.3 | 11.5 |
| 6 | RB | HOU | Jawhar Jordan | 6-43-1 rush, 1 tgt 1-7-0 rec | 12.0 | 22.1 |
| 8 | RB | IND | Jonathan Taylor | 8-23-0 rush, 5 tgt 4-24-0 rec | 6.7 | 13.9 |
| 1 | TE | CLE | Harold Fannin Jr. | 3 tgt, 2-21-0 | 4.1 | 6.5 |
| 2 | TE | DEN | Nate Adkins | 3 tgt, 3-32-1 (+1-6 rush) | 12.8 | 15.5 |
| 3 | TE | NE | Hunter Henry | 2 tgt, 1-5-0 | 1.5 | 1.5 |
| 4 | TE | CIN | Mike Gesicki | 5 tgt, 3-40-1 | 13.0 | 14.2 |
| 5 | TE | PHI | Dallas Goedert | 9 tgt, 6-38-0 | 9.8 | 9.8 |
| 6 | TE | HOU | Foster Moreau | 2 tgt, 2-7-2 | 14.7 | 23.4 |
| 8 | TE | IND | Tyler Warren | 10 tgt, 4-18-0 | 5.8 | 5.8 |
| 1 | WR | CLE | Denzel Boston | 4 tgt, 2-59-1 | 13.9 | 26.3 |
| 2 | WR | DEN | Jaylen Waddle | 10 tgt, 8-138-0 | 21.8 | 32.6 |
| 3 | WR | NE | Mack Hollins | 9 tgt, 6-87-0 | 14.7 | 33.5 |
| 4 | WR | CIN | Tee Higgins | 16 tgt, 11-157-0 | 26.7 | 55.5 |
| 5 | WR | PHI | Darius Cooper | 3 tgt, 2-71-1 | 15.1 | 35.7 |
| 6 | WR | HOU | Jaylin Noel | 4 tgt, 4-107-1 | 20.7 | 44.6 |
| 8 | WR | IND | Keenan Allen | 7 tgt, 7-67-0 | 13.7 | 30.3 |

Week by week: QBs vs this defense (main QB = most attempts + sacks + carries; rush = car-yds-TD; pts = nflverse fantasy points: 4-pt pass TD, −2 INT, −2 fumble lost):

| wk | opp | QB | cmp/att | pass yds | pass TD | INT | sk | rush | FL | pts | other QBs | all-QB pts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | CLE | Deshaun Watson | 16/22 | 205 | 1 | 1 | 5 | 6-38-0 | 0 | 14.0 | – | 14.0 |
| 2 | DEN | Bo Nix | 22/31 | 288 | 1 | 1 | 0 | 5-6-0 | 0 | 14.1 | – | 14.1 |
| 3 | NE | Drake Maye | 14/25 | 199 | 0 | 2 | 3 | 4-18-0 | 1 | 3.8 | Tommy DeVito 3/5, 1 car, 1.4 pts | 5.2 |
| 4 | CIN | Joe Burrow | 39/54 | 428 | 1 | 2 | 2 | 3-6-1 | 0 | 23.7 | – | 23.7 |
| 5 | PHI | Jalen Hurts | 21/40 | 220 | 1 | 0 | 1 | 2-2-0 | 0 | 13.0 | – | 13.0 |
| 6 | HOU | C.J. Stroud | 24/34 | 312 | 3 | 1 | 0 | 1-5-0 | 0 | 23.0 | – | 23.0 |
| 8 | IND | Daniel Jones | 19/28 | 144 | 1 | 2 | 3 | 4-7-0 | 0 | 6.5 | Anthony Richardson 2/2, 2 car, 0.7 pts | 7.2 |

Game by game, 2026: allowed (expected vs that offense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | CLE | 19 | 3.53 (3.88) | 42% (38%) | -0.12 (-0.20) | 30 | -0.23 (0.02) | 9.32 (7.04) |
| 2 | DEN | 25 | 4.28 (3.96) | 44% (41%) | -0.06 (0.01) | 31 | 0.27 (-0.03) | 9.29 (5.60) |
| 3 | NE | 23 | 2.78 (4.15) | 26% (38%) | -0.13 (-0.12) | 37 | -0.33 (0.29) | 7.90 (8.62) |
| 4 | CIN | 13 | 1.38 (4.21) | 23% (45%) | -0.31 (-0.09) | 58 | 0.13 (0.27) | 7.93 (7.56) |
| 5 | PHI | 17 | 1.18 (3.73) | 24% (37%) | -0.61 (-0.10) | 42 | -0.04 (-0.21) | 5.50 (5.54) |
| 6 | HOU | 24 | 4.54 (2.80) | 42% (32%) | 0.01 (-0.22) | 35 | 0.37 (0.03) | 9.18 (7.00) |
| 8 | IND | 21 | 4.67 (4.47) | 48% (46%) | -0.30 (0.11) | 37 | -0.59 (-0.17) | 5.07 (5.52) |

## 2026 OFFENSE — JAX Jacksonville Jaguars

Usage concentrations (share well above league avg at his position):
- Trevor Lawrence (QB, 197 att): int middle 11% (lg 6%)
- Jakobi Meyers (WR, 31 tgt): int middle 26% (avg 9%)
- Brenton Strange (TE, 35 tgt): int middle 20% (avg 7%)
- Brian Thomas Jr. (WR, 21 tgt): int right 24% (avg 9%)
- Josh Cameron (WR, 13 tgt): short middle 23% (avg 10%)
- Ameer Abdullah (RB, 16 car): runs left tackle 50% (avg 13%); vs 8+ box 31% (avg 8%)

Team passing context:

| stat | value |
|---|---|
| Dropbacks | 223 |
| EPA/dropback | 0.266 |
| Sack rate | 6% |
| Pressure rate faced (NGS) | – |
| EPA/db clean | – |
| EPA/db under pressure | – |
| Blitz rate faced (FTN) | 30% |
| EPA/db vs blitz | 0.147 |
| EPA/db vs no blitz | 0.318 |
| Pass rate over expected | -4.1 pts |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing defense's adjusted rating from its other games; diff = gained − expected; adjusted = league avg + diff; rank 1 = best offense; thin = games where that rating rests on under 100 plays; method in README):

| stat | gained | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 4.41 | 4.12 | +0.29 | 4.39 | 9/32 | 7 | 0 |
| Run success rate | 44.0% | 39.5% | +4.5 | 45.1% | 8/32 | 7 | 0 |
| EPA/rush | 0.038 | -0.055 | +0.093 | 0.018 | 6/32 | 7 | 0 |
| EPA/dropback | 0.266 | 0.034 | +0.232 | 0.285 | 3/32 | 7 | 0 |
| YPA | 8.45 | 7.11 | +1.34 | 8.40 | 3/32 | 7 | 0 |
| Sack rate | 5.8% | 7.1% | -1.2 | 5.0% | 12/32 | 7 | 0 |

QB throw map (share of att, EPA/att in parentheses; ≥40 att):

| QB | att | short left | short middle | short right | int left | int middle | int right | deep left | deep middle | deep right |
|---|---|---|---|---|---|---|---|---|---|---|
| Trevor Lawrence | 197 | 26% (0.07) | 9% (0.07) | 24% (0.38) | 11% (0.67) | 11% (1.09) | 8% (0.24) | 7% (0.90) | 1% (1.61) | 3% (0.97) |
| league | 7970 | 26% (0.04) | 13% (0.05) | 29% (0.01) | 7% (0.31) | 6% (0.59) | 7% (0.38) | 4% (0.35) | 2% (0.76) | 5% (0.33) |

Player usage, season totals (RZ opps = carries + targets inside the 10 / 5):

| player | pos | G | snap% avg | tgt | tgt share | air yds share | aDOT | rec-yds-TD | YAC/rec | MOF tgt% | car | car share | rush yds-TD | RZ10 opps | RZ5 opps | PPR | PPR/g |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Trevor Lawrence | QB | 7 | 95% | 0 | 0% | 0% | – | 0-0-0 | – | – | 20 | 10% | 80-0 | 0 | 0 | 133.6 | 19.1 |
| Bhayshul Tuten | RB | 7 | 55% | 16 | 9% | -3% | -3.1 | 15-181-3 | 15.0 | 6% | 110 | 55% | 492-3 | 8 | 5 | 118.3 | 16.9 |
| Parker Washington | WR | 7 | 75% | 48 | 26% | 37% | 12.9 | 27-432-4 | 5.0 | 15% | 2 | 1% | 13-0 | 4 | 0 | 95.5 | 13.6 |
| Brenton Strange | TE | 7 | 75% | 35 | 19% | 17% | 7.9 | 28-334-1 | 4.9 | 29% | 0 | 0% | 0-0 | 2 | 0 | 67.4 | 9.6 |
| Jakobi Meyers | WR | 7 | 76% | 31 | 16% | 20% | 10.5 | 22-309-2 | 3.0 | 32% | 1 | 0% | 2-0 | 6 | 3 | 65.1 | 9.3 |
| Chris Rodriguez Jr. | RB | 7 | 25% | 3 | 2% | 0% | 2.3 | 2-23-0 | 9.0 | 0% | 45 | 22% | 209-3 | 7 | 4 | 43.2 | 6.2 |
| Brian Thomas Jr. | WR | 7 | 45% | 21 | 11% | 16% | 12.2 | 10-117-2 | 0.7 | 9% | 0 | 0% | 0-0 | 4 | 2 | 33.7 | 4.8 |
| Josh Cameron | WR | 7 | 37% | 13 | 7% | 5% | 6.7 | 8-117-2 | 8.9 | 23% | 0 | 0% | 0-0 | 2 | 1 | 31.7 | 4.5 |
| Nate Boerkircher | TE | 6 | 48% | 9 | 5% | 4% | 6.6 | 7-83-2 | 5.0 | 11% | 0 | 0% | 0-0 | 2 | 1 | 27.3 | 4.6 |
| Ameer Abdullah | RB | 7 | 7% | 3 | 2% | -1% | -4.0 | 2-2-0 | 5.5 | 0% | 16 | 8% | 58-0 | 0 | 0 | 8.0 | 1.1 |
| LeQuint Allen Jr. | RB | 6 | 13% | 6 | 3% | 1% | 3.5 | 2-9-0 | 2.5 | 67% | 1 | 0% | 1-0 | 1 | 1 | 3.0 | 0.5 |
| Tanner Koziol | TE | 1 | 16% | 1 | 1% | 0% | 1.0 | 1-8-0 | 7.0 | 0% | 0 | 0% | 0-0 | 0 | 0 | 1.8 | 1.8 |
| Quintin Morris | TE | 5 | 19% | 2 | 1% | 0% | 2.5 | 1-7-0 | 4.0 | 0% | 0 | 0% | 0-0 | 0 | 0 | 1.7 | 0.3 |
| Quinn Ewers | QB | 1 | 12% | 0 | 0% | 0% | – | 0-0-0 | – | – | 0 | 0% | 0-0 | 0 | 0 | 0.3 | 0.3 |
| Nick Mullens | QB | 1 | 12% | 0 | 0% | 0% | – | 0-0-0 | – | – | 3 | 2% | -3-0 | 0 | 0 | -0.3 | -0.3 |

Target depth mix (air yards):

| player | behind LOS | 0-9 | 10-19 | 20+ |
|---|---|---|---|---|
| Jakobi Meyers | 6% | 32% | 48% | 13% |
| Parker Washington | 8% | 40% | 29% | 23% |
| Brenton Strange | 9% | 51% | 34% | 6% |
| Brian Thomas Jr. | 5% | 33% | 48% | 14% |
| LeQuint Allen Jr. | 0% | 100% | 0% | 0% |
| nan | 29% | 57% | 14% | 0% |
| Bhayshul Tuten | 81% | 19% | 0% | 0% |
| Josh Cameron | 23% | 46% | 23% | 8% |
| Nate Boerkircher | 0% | 78% | 11% | 11% |

RB rushing by bucket (≥8 carries):

| RB | type | bucket | car | YPC | success | EPA/rush |
|---|---|---|---|---|---|---|
| Bhayshul Tuten | formation | shotgun | 23 | 3.13 | 30% | -0.155 |
| Bhayshul Tuten | formation | under center | 87 | 4.83 | 45% | 0.038 |
| Bhayshul Tuten | box | 7 | 45 | 5.69 | 56% | 0.140 |
| Bhayshul Tuten | box | 8+ | 12 | 3.08 | 33% | 0.046 |
| Bhayshul Tuten | box | ≤6 | 53 | 3.75 | 32% | -0.135 |
| Bhayshul Tuten | direction/gap | left end | 20 | 4.40 | 45% | -0.124 |
| Bhayshul Tuten | direction/gap | left guard | 11 | 4.18 | 27% | -0.116 |
| Bhayshul Tuten | direction/gap | left tackle | 11 | 5.00 | 45% | 0.023 |
| Bhayshul Tuten | direction/gap | middle | 25 | 4.04 | 36% | -0.037 |
| Bhayshul Tuten | direction/gap | right end | 13 | 4.54 | 62% | 0.293 |
| Bhayshul Tuten | direction/gap | right guard | 13 | 3.15 | 31% | -0.187 |
| Bhayshul Tuten | direction/gap | right tackle | 17 | 6.00 | 47% | 0.162 |
| Chris Rodriguez Jr. | formation | shotgun | 18 | 5.67 | 50% | 0.286 |
| Chris Rodriguez Jr. | formation | under center | 27 | 3.96 | 41% | 0.009 |
| Chris Rodriguez Jr. | box | 7 | 27 | 4.96 | 41% | 0.110 |
| Chris Rodriguez Jr. | box | 8+ | 6 | 3.33 | 50% | 0.091 |
| Chris Rodriguez Jr. | box | ≤6 | 12 | 4.58 | 50% | 0.158 |
| Chris Rodriguez Jr. | direction/gap | left end | 3 | 3.67 | 0% | -0.225 |
| Chris Rodriguez Jr. | direction/gap | left guard | 8 | 7.00 | 50% | 0.424 |
| Chris Rodriguez Jr. | direction/gap | left tackle | 6 | 3.33 | 50% | 0.168 |
| Chris Rodriguez Jr. | direction/gap | middle | 15 | 6.13 | 73% | 0.463 |
| Chris Rodriguez Jr. | direction/gap | right end | 2 | 4.00 | 50% | 0.146 |
| Chris Rodriguez Jr. | direction/gap | right guard | 7 | 2.86 | 14% | -0.382 |
| Chris Rodriguez Jr. | direction/gap | right tackle | 4 | 0.50 | 0% | -0.720 |
| Ameer Abdullah | formation | shotgun | 3 | 8.00 | 67% | 0.199 |
| Ameer Abdullah | formation | under center | 13 | 2.62 | 31% | -0.218 |
| Ameer Abdullah | box | 7 | 4 | 0.00 | 0% | -0.596 |
| Ameer Abdullah | box | 8+ | 5 | 0.60 | 0% | -0.464 |
| Ameer Abdullah | box | ≤6 | 7 | 7.86 | 86% | 0.353 |
| Ameer Abdullah | direction/gap | left tackle | 8 | 2.62 | 38% | -0.167 |
| Ameer Abdullah | direction/gap | middle | 4 | 6.00 | 50% | -0.100 |
| Ameer Abdullah | direction/gap | right end | 1 | -3.00 | 0% | -0.336 |
| Ameer Abdullah | direction/gap | right guard | 3 | 5.33 | 33% | -0.055 |

Week by week usage:

| player | pos | wk | opp | snap% | tgt | tgt share | rec-yds-TD | aDOT | car | car share | rush yds-TD | PPR |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ameer Abdullah | RB | 1 | CLE | 9% | 1 | 5% | 1-0-0 | -3.0 | 4 | 12% | 32-0 | 4.2 |
| Ameer Abdullah | RB | 2 | DEN | 10% | 1 | 4% | 1-2-0 | -6.0 | 3 | 12% | 11-0 | 2.3 |
| Ameer Abdullah | RB | 3 | NE | 11% | 1 | 4% | 0-0-0 | -3.0 | 3 | 10% | 2-0 | 0.2 |
| Ameer Abdullah | RB | 4 | CIN | 2% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Ameer Abdullah | RB | 5 | PHI | 1% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Ameer Abdullah | RB | 6 | HOU | 0% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Ameer Abdullah | RB | 8 | IND | 17% | 0 | 0% | 0-0-0 | – | 6 | 18% | 13-0 | 1.3 |
| Bhayshul Tuten | RB | 1 | CLE | 49% | 1 | 5% | 1-22-0 | -5.0 | 15 | 47% | 66-0 | 9.8 |
| Bhayshul Tuten | RB | 2 | DEN | 51% | 2 | 7% | 2-(-3)-0 | -4.0 | 13 | 54% | 65-1 | 14.2 |
| Bhayshul Tuten | RB | 3 | NE | 48% | 2 | 7% | 2-17-0 | -3.5 | 15 | 50% | 73-1 | 17.0 |
| Bhayshul Tuten | RB | 4 | CIN | 59% | 2 | 9% | 2-18-0 | -1.0 | 17 | 63% | 73-0 | 11.1 |
| Bhayshul Tuten | RB | 5 | PHI | 68% | 3 | 8% | 2-24-0 | -2.7 | 22 | 81% | 72-0 | 11.6 |
| Bhayshul Tuten | RB | 6 | HOU | 58% | 4 | 11% | 4-48-2 | -3.2 | 12 | 44% | 39-0 | 24.7 |
| Bhayshul Tuten | RB | 8 | IND | 50% | 2 | 12% | 2-55-1 | -3.0 | 16 | 48% | 104-1 | 29.9 |
| Brenton Strange | TE | 1 | CLE | 68% | 3 | 15% | 2-23-1 | 11.3 | 0 | 0% | 0-0 | 10.3 |
| Brenton Strange | TE | 2 | DEN | 83% | 2 | 7% | 2-17-0 | 8.5 | 0 | 0% | 0-0 | 3.7 |
| Brenton Strange | TE | 3 | NE | 77% | 5 | 19% | 3-32-0 | 6.4 | 0 | 0% | 0-0 | 6.2 |
| Brenton Strange | TE | 4 | CIN | 87% | 8 | 35% | 7-95-0 | 7.2 | 0 | 0% | 0-0 | 16.5 |
| Brenton Strange | TE | 5 | PHI | 81% | 8 | 22% | 7-68-0 | 7.1 | 0 | 0% | 0-0 | 13.8 |
| Brenton Strange | TE | 6 | HOU | 76% | 7 | 19% | 5-44-0 | 8.0 | 0 | 0% | 0-0 | 9.4 |
| Brenton Strange | TE | 8 | IND | 52% | 2 | 12% | 2-55-0 | 11.0 | 0 | 0% | 0-0 | 7.5 |
| Brian Thomas Jr. | WR | 1 | CLE | 35% | 3 | 15% | 3-40-0 | 14.7 | 0 | 0% | 0-0 | 7.0 |
| Brian Thomas Jr. | WR | 2 | DEN | 54% | 8 | 29% | 3-40-0 | 10.2 | 0 | 0% | 0-0 | 7.0 |
| Brian Thomas Jr. | WR | 3 | NE | 37% | 1 | 4% | 1-8-0 | 4.0 | 0 | 0% | 0-0 | 1.8 |
| Brian Thomas Jr. | WR | 4 | CIN | 62% | 2 | 9% | 2-17-1 | 8.5 | 0 | 0% | 0-0 | 9.7 |
| Brian Thomas Jr. | WR | 5 | PHI | 51% | 3 | 8% | 0-0-0 | 12.7 | 0 | 0% | 0-0 | 0.0 |
| Brian Thomas Jr. | WR | 6 | HOU | 21% | 2 | 5% | 0-0-0 | 17.0 | 0 | 0% | 0-0 | 0.0 |
| Brian Thomas Jr. | WR | 8 | IND | 52% | 2 | 12% | 1-12-1 | 19.0 | 0 | 0% | 0-0 | 8.2 |
| Chris Rodriguez Jr. | RB | 1 | CLE | 40% | 0 | 0% | 0-0-0 | – | 6 | 19% | 23-0 | 2.3 |
| Chris Rodriguez Jr. | RB | 2 | DEN | 22% | 0 | 0% | 0-0-0 | – | 6 | 25% | 13-0 | 1.3 |
| Chris Rodriguez Jr. | RB | 3 | NE | 21% | 0 | 0% | 0-0-0 | – | 8 | 27% | 37-1 | 9.7 |
| Chris Rodriguez Jr. | RB | 4 | CIN | 25% | 0 | 0% | 0-0-0 | – | 6 | 22% | 35-1 | 9.5 |
| Chris Rodriguez Jr. | RB | 5 | PHI | 12% | 1 | 3% | 1-6-0 | 2.0 | 2 | 7% | 5-0 | 2.1 |
| Chris Rodriguez Jr. | RB | 6 | HOU | 30% | 1 | 3% | 0-0-0 | 2.0 | 11 | 41% | 55-0 | 5.5 |
| Chris Rodriguez Jr. | RB | 8 | IND | 22% | 1 | 6% | 1-17-0 | 3.0 | 6 | 18% | 41-1 | 12.8 |
| Jakobi Meyers | WR | 1 | CLE | 65% | 2 | 10% | 2-40-1 | 14.5 | 1 | 3% | 2-0 | 12.2 |
| Jakobi Meyers | WR | 2 | DEN | 90% | 1 | 4% | 1-28-0 | 21.0 | 0 | 0% | 0-0 | 3.8 |
| Jakobi Meyers | WR | 3 | NE | 81% | 8 | 30% | 7-64-1 | 8.0 | 0 | 0% | 0-0 | 19.4 |
| Jakobi Meyers | WR | 4 | CIN | 82% | 4 | 17% | 3-33-0 | 8.8 | 0 | 0% | 0-0 | 6.3 |
| Jakobi Meyers | WR | 5 | PHI | 85% | 3 | 8% | 2-37-0 | 10.3 | 0 | 0% | 0-0 | 5.7 |
| Jakobi Meyers | WR | 6 | HOU | 75% | 10 | 27% | 5-83-0 | 11.7 | 0 | 0% | 0-0 | 13.3 |
| Jakobi Meyers | WR | 8 | IND | 54% | 3 | 19% | 2-24-0 | 10.0 | 0 | 0% | 0-0 | 4.4 |
| Josh Cameron | WR | 1 | CLE | 33% | 2 | 10% | 2-20-1 | 9.0 | 0 | 0% | 0-0 | 10.0 |
| Josh Cameron | WR | 2 | DEN | 17% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Josh Cameron | WR | 3 | NE | 37% | 2 | 7% | 1-12-1 | 10.0 | 0 | 0% | 0-0 | 8.2 |
| Josh Cameron | WR | 4 | CIN | 36% | 2 | 9% | 2-42-0 | 3.5 | 0 | 0% | 0-0 | 6.2 |
| Josh Cameron | WR | 5 | PHI | 31% | 6 | 16% | 3-43-0 | 2.3 | 0 | 0% | 0-0 | 7.3 |
| Josh Cameron | WR | 6 | HOU | 51% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Josh Cameron | WR | 8 | IND | 52% | 1 | 6% | 0-0-0 | 28.0 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 2 | DEN | 15% | 1 | 4% | 0-0-0 | 4.0 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 3 | NE | 18% | 2 | 7% | 2-9-0 | 2.0 | 0 | 0% | 0-0 | 2.9 |
| LeQuint Allen Jr. | RB | 4 | CIN | 15% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 5 | PHI | 18% | 2 | 5% | 0-0-0 | 2.5 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 6 | HOU | 11% | 0 | 0% | 0-0-0 | – | 1 | 4% | 1-0 | 0.1 |
| LeQuint Allen Jr. | RB | 8 | IND | 11% | 1 | 6% | 0-0-0 | 8.0 | 0 | 0% | 0-0 | 0.0 |
| Nate Boerkircher | TE | 1 | CLE | 67% | 1 | 5% | 1-9-0 | 2.0 | 0 | 0% | 0-0 | 1.9 |
| Nate Boerkircher | TE | 3 | NE | 45% | 1 | 4% | 0-0-0 | 4.0 | 0 | 0% | 0-0 | 0.0 |
| Nate Boerkircher | TE | 4 | CIN | 34% | 2 | 9% | 1-15-0 | 4.5 | 0 | 0% | 0-0 | 2.5 |
| Nate Boerkircher | TE | 5 | PHI | 49% | 2 | 5% | 2-20-0 | 7.0 | 0 | 0% | 0-0 | 4.0 |
| Nate Boerkircher | TE | 6 | HOU | 55% | 2 | 5% | 2-8-1 | 2.5 | 0 | 0% | 0-0 | 8.8 |
| Nate Boerkircher | TE | 8 | IND | 48% | 1 | 6% | 1-31-1 | 25.0 | 0 | 0% | 0-0 | 10.1 |
| Nick Mullens | QB | 1 | CLE | 12% | 0 | 0% | 0-0-0 | – | 3 | 9% | -3-0 | -0.3 |
| Parker Washington | WR | 1 | CLE | 61% | 6 | 30% | 5-83-1 | 17.0 | 0 | 0% | 0-0 | 19.3 |
| Parker Washington | WR | 2 | DEN | 81% | 12 | 43% | 7-98-0 | 14.8 | 0 | 0% | 0-0 | 16.8 |
| Parker Washington | WR | 3 | NE | 81% | 5 | 19% | 3-40-1 | 10.0 | 0 | 0% | 0-0 | 13.0 |
| Parker Washington | WR | 4 | CIN | 80% | 3 | 13% | 1-7-0 | 12.7 | 1 | 4% | 3-0 | 2.0 |
| Parker Washington | WR | 5 | PHI | 82% | 9 | 24% | 6-124-2 | 8.8 | 0 | 0% | 0-0 | 30.4 |
| Parker Washington | WR | 6 | HOU | 73% | 11 | 30% | 4-64-0 | 13.9 | 0 | 0% | 0-0 | 10.4 |
| Parker Washington | WR | 8 | IND | 67% | 2 | 12% | 1-16-0 | 9.5 | 1 | 3% | 10-0 | 3.6 |
| Quinn Ewers | QB | 8 | IND | 19% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.3 |
| Quintin Morris | TE | 1 | CLE | 42% | 1 | 5% | 0-0-0 | 2.0 | 0 | 0% | 0-0 | 0.0 |
| Quintin Morris | TE | 2 | DEN | 22% | 1 | 4% | 1-7-0 | 3.0 | 0 | 0% | 0-0 | 1.7 |
| Quintin Morris | TE | 4 | CIN | 2% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Quintin Morris | TE | 5 | PHI | 3% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Quintin Morris | TE | 8 | IND | 20% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Tanner Koziol | TE | 8 | IND | 35% | 1 | 6% | 1-8-0 | 1.0 | 0 | 0% | 0-0 | 1.8 |
| Trevor Lawrence | QB | 1 | CLE | 88% | 0 | 0% | 0-0-0 | – | 2 | 6% | 3-0 | 26.1 |
| Trevor Lawrence | QB | 2 | DEN | 100% | 0 | 0% | 0-0-0 | – | 2 | 8% | 6-0 | 6.2 |
| Trevor Lawrence | QB | 3 | NE | 95% | 0 | 0% | 0-0-0 | – | 4 | 13% | 25-0 | 19.8 |
| Trevor Lawrence | QB | 4 | CIN | 100% | 0 | 0% | 0-0-0 | – | 3 | 11% | 0-0 | 13.1 |
| Trevor Lawrence | QB | 5 | PHI | 100% | 0 | 0% | 0-0-0 | – | 3 | 11% | 25-0 | 21.7 |
| Trevor Lawrence | QB | 6 | HOU | 100% | 0 | 0% | 0-0-0 | – | 3 | 11% | 11-0 | 27.3 |
| Trevor Lawrence | QB | 8 | IND | 81% | 0 | 0% | 0-0-0 | – | 3 | 9% | 10-0 | 19.4 |

Game by game, 2026: gained (expected vs that defense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | CLE | 28 | 4.54 (4.28) | 54% (42%) | -0.01 (-0.07) | 24 | 0.79 (-0.02) | 10.65 (6.36) |
| 2 | DEN | 24 | 3.96 (4.05) | 46% (33%) | 0.06 (-0.06) | 31 | -0.13 (-0.04) | 6.52 (6.34) |
| 3 | NE | 28 | 4.61 (3.55) | 54% (35%) | 0.24 (-0.17) | 31 | 0.23 (0.00) | 6.50 (7.01) |
| 4 | CIN | 25 | 4.52 (4.25) | 36% (35%) | 0.03 (-0.11) | 28 | 0.33 (0.05) | 9.46 (7.66) |
| 5 | PHI | 24 | 3.21 (4.40) | 29% (47%) | -0.29 (0.11) | 44 | 0.25 (0.11) | 8.49 (7.02) |
| 6 | HOU | 24 | 3.96 (3.91) | 50% (40%) | 0.01 (-0.06) | 43 | 0.27 (0.02) | 7.46 (7.71) |
| 8 | IND | 31 | 5.65 (4.39) | 39% (45%) | 0.17 (-0.01) | 22 | 0.25 (0.10) | 12.82 (7.61) |
