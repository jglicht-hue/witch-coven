# JAX Jacksonville Jaguars — Matchup Witch data, 2026 (current)

Source: nflverse (play-by-play, NGS participation, FTN charting, player stats, snap counts). Built 2026-11-17 14:53 UTC. Regular season only.
- 2026: weeks 1–10, 150 games, last game 2026-11-16; NGS participation NO (route, man/zone, coverage, pressure unavailable)

## 2026 DEFENSE — JAX Jacksonville Jaguars (9 games)

Flags, 2026 (leads to test, not verdicts; rank 1 = best D, among teams with enough plays; see README):

Weak (bottom ~15%):
- rush EPA, runs, right tackle: 0.308 (lg -0.024; 31/32; n=19)

Strong (top ~15%):
- rush EPA, ≤6 box: -0.259 (lg -0.061; 1/32; n=66)
- pass EPA/att, short middle: -0.36 (lg +0.05; 1/32; n=31)
- run D, EPA/rush: -0.136 (lg -0.056; 2/32)
- pass EPA/att, short left: -0.28 (lg +0.02; 2/32; n=94)
- pass EPA/att, short right: -0.20 (lg +0.01; 2/32; n=80)
- rush EPA, runs, left guard: -0.287 (lg -0.055; 3/32; n=22)
- PPR/g allowed, QB: 13.2 (lg 16.6; 5/32)
- pass D, EPA/dropback: -0.065 (lg 0.048; 5/32)

Fantasy points allowed (PPR, nflverse scoring incl. rushing, fumbles, 2-pt). Rank 1 = fewest allowed.

| pos | PPR total | PPR/game | rank |
|---|---|---|---|
| QB | 119.0 | 13.2 | 5 |
| RB | 170.3 | 18.9 | 6 |
| WR | 294.9 | 32.8 | 19 |
| TE | 97.0 | 10.8 | 6 |

Unit stats (rank 1 = best defense):

| stat | value | rank |
|---|---|---|
| EPA/dropback | -0.065 | 5 |
| YPA | 7.13 | 17 |
| Comp % | 67% | 27 |
| 20+ yd completions/game | 2.56 | 8 |
| Sack rate | 5% | 24 |
| Pressure rate (NGS) | – | – |
| Blitz rate (FTN: 1+ blitzer) | 31% | – |
| Man coverage rate (NGS) | – | – |
| EPA/rush (designed runs) | -0.136 | 2 |
| YPC | 3.77 | 11 |
| Rush success rate | 38% | 9 |
| Stuff rate (≤0 yds) | 20% | 12 |
| 10+ yd runs/game | 1.67 | 7 |
| 20+ yd runs/game | 0.22 | – |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing offense's adjusted rating from its other games; diff = allowed − expected; adjusted = league avg + diff; rank 1 = best defense; thin = games where that rating rests on under 100 plays; method in README):

| stat | allowed | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 3.77 | 3.82 | -0.05 | 4.04 | 15/32 | 9 | 0 |
| Run success rate | 37.6% | 38.8% | -1.3 | 39.3% | 11/32 | 9 | 0 |
| EPA/rush | -0.136 | -0.074 | -0.061 | -0.118 | 6/32 | 9 | 0 |
| EPA/dropback | -0.065 | 0.034 | -0.099 | -0.051 | 5/32 | 9 | 0 |
| YPA | 7.13 | 6.79 | +0.33 | 7.46 | 20/32 | 9 | 0 |
| Sack rate | 5.1% | 6.4% | -1.3 | 5.1% | 28/32 | 9 | 0 |

QB rushing allowed (runs + scrambles): 29 car, 145 yds, 1 TD; 16.1 yds/g (rank 16/32; lg 16.8); scramble rate 5% (lg 5%)

Passing allowed by throw (rank by EPA/att among teams with ≥8 att; share = opp. QBs' share of att here, usual = their share in other games):

| cell | att | comp | YPA | TD | INT | EPA | rank | share | usual |
|---|---|---|---|---|---|---|---|---|---|
| short left | 94 | 71% | 4.87 | 3 | 6 | -0.28 | 2/32 | 31% | 26% |
| short middle | 31 | 68% | 5.39 | 0 | 1 | -0.36 | 1/32 | 10% | 12% |
| short right | 80 | 74% | 4.60 | 3 | 3 | -0.20 | 2/32 | 27% | 31% |
| int left | 20 | 65% | 11.05 | 0 | 1 | 0.45 | 24/32 | 7% | 7% |
| int middle | 14 | 71% | 11.00 | 1 | 1 | 0.65 | 24/32 | 5% | 5% |
| int right | 32 | 53% | 8.12 | 1 | 0 | 0.28 | 14/32 | 10% | 8% |
| deep left | 10 | 30% | 11.50 | 0 | 0 | 0.11 | 10/31 | 3% | 4% |
| deep middle | 5 | 60% | 29.00 | 1 | 0 | 1.75 | – | 2% | 2% |
| deep right | 14 | 50% | 17.86 | 1 | 0 | 0.91 | 24/29 | 5% | 5% |

Targets allowed by receiver position:

| pos | tgt | catch | YPT | TD | PPR/tgt |
|---|---|---|---|---|---|
| RB | 58 | 84% | 5.64 | 1 | 1.51 |
| WR | 170 | 66% | 9.01 | 4 | 1.71 |
| TE | 58 | 66% | 4.81 | 5 | 1.65 |

Run defense by bucket (box count from FTN charting):

| type | bucket | rushes | YPC | success | EPA/rush |
|---|---|---|---|---|---|
| box | 7 | 78 | 4.29 | 33% | -0.064 |
| box | 8+ | 45 | 2.73 | 44% | -0.078 |
| box | ≤6 | 66 | 3.85 | 38% | -0.259 |
| direction/gap | ? | 4 | 0.00 | 0% | -2.219 |
| direction/gap | left end | 32 | 3.34 | 38% | -0.168 |
| direction/gap | left guard | 22 | 2.45 | 41% | -0.287 |
| direction/gap | left tackle | 17 | 5.82 | 35% | -0.089 |
| direction/gap | middle | 50 | 2.92 | 32% | -0.126 |
| direction/gap | right end | 27 | 4.33 | 44% | -0.048 |
| direction/gap | right guard | 18 | 3.06 | 33% | -0.098 |
| direction/gap | right tackle | 19 | 7.05 | 53% | 0.308 |
| offense formation | shotgun | 87 | 4.29 | 45% | -0.121 |
| offense formation | under center | 102 | 3.32 | 31% | -0.148 |

RB targets allowed by route type:

| route | tgt | catch | YPT | PPR/tgt |
|---|---|---|---|---|
| (route n/a) | 43 | 81% | 5.95 | 1.55 |
| screen | 15 | 93% | 4.73 | 1.41 |

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
| 9 | RB | BAL | Justice Hill | 9-85-1 rush, 3 tgt 3-7-0 rec | 18.2 | 23.8 |
| 10 | RB | TEN | Tony Pollard | 9-33-0 rush, 9 tgt 8-66-1 rec | 23.9 | 27.7 |
| 1 | TE | CLE | Harold Fannin Jr. | 3 tgt, 2-21-0 | 4.1 | 6.5 |
| 2 | TE | DEN | Nate Adkins | 3 tgt, 3-32-1 (+1-6 rush) | 12.8 | 15.5 |
| 3 | TE | NE | Hunter Henry | 2 tgt, 1-5-0 | 1.5 | 1.5 |
| 4 | TE | CIN | Mike Gesicki | 5 tgt, 3-40-1 | 13.0 | 14.2 |
| 5 | TE | PHI | Dallas Goedert | 9 tgt, 6-38-0 | 9.8 | 9.8 |
| 6 | TE | HOU | Foster Moreau | 2 tgt, 2-7-2 | 14.7 | 23.4 |
| 8 | TE | IND | Tyler Warren | 10 tgt, 4-18-0 | 5.8 | 5.8 |
| 9 | TE | BAL | Mark Andrews | 2 tgt, 2-19-0 (+2-0 rush) | 3.9 | 5.4 |
| 10 | TE | TEN | Daniel Bellinger | 3 tgt, 2-6-1 | 8.6 | 14.9 |
| 1 | WR | CLE | Denzel Boston | 4 tgt, 2-59-1 | 13.9 | 26.3 |
| 2 | WR | DEN | Jaylen Waddle | 10 tgt, 8-138-0 | 21.8 | 32.6 |
| 3 | WR | NE | Mack Hollins | 9 tgt, 6-87-0 | 14.7 | 33.5 |
| 4 | WR | CIN | Tee Higgins | 16 tgt, 11-157-0 | 26.7 | 55.5 |
| 5 | WR | PHI | Darius Cooper | 3 tgt, 2-71-1 | 15.1 | 35.7 |
| 6 | WR | HOU | Jaylin Noel | 4 tgt, 4-107-1 | 20.7 | 44.6 |
| 8 | WR | IND | Keenan Allen | 7 tgt, 7-67-0 | 13.7 | 30.3 |
| 9 | WR | BAL | Zay Flowers | 6 tgt, 3-6-0 (+3-17 rush) | 5.3 | 9.3 |
| 10 | WR | TEN | Elic Ayomanor | 10 tgt, 5-79-0 | 12.9 | 27.1 |

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
| 9 | BAL | Joe Fagnano | 10/18 | 60 | 0 | 2 | 1 | 3-13-0 | 0 | -0.3 | – | -0.3 |
| 10 | TEN | Cam Ward | 28/39 | 231 | 2 | 1 | 1 | 3-39-0 | 0 | 19.1 | – | 19.1 |

Game by game, 2026: allowed (expected vs that offense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | CLE | 19 | 3.53 (3.67) | 42% (36%) | -0.10 (-0.16) | 30 | -0.15 (-0.00) | 9.32 (7.17) |
| 2 | DEN | 25 | 4.28 (3.85) | 44% (40%) | -0.08 (0.00) | 31 | 0.23 (0.04) | 9.29 (5.90) |
| 3 | NE | 23 | 2.78 (4.05) | 30% (39%) | -0.12 (-0.10) | 37 | -0.29 (0.15) | 7.90 (8.17) |
| 4 | CIN | 13 | 1.38 (4.31) | 23% (44%) | -0.26 (-0.01) | 58 | 0.10 (0.32) | 7.93 (8.15) |
| 5 | PHI | 17 | 1.18 (3.51) | 18% (34%) | -0.49 (-0.10) | 42 | -0.02 (-0.16) | 5.50 (5.65) |
| 6 | HOU | 24 | 4.54 (2.93) | 42% (31%) | 0.03 (-0.17) | 35 | 0.34 (0.11) | 9.18 (7.44) |
| 8 | IND | 21 | 4.67 (4.48) | 48% (47%) | -0.25 (0.07) | 37 | -0.49 (-0.22) | 5.07 (5.23) |
| 9 | BAL | 33 | 4.94 (3.80) | 36% (40%) | -0.07 (-0.09) | 21 | -0.57 (0.05) | 3.00 (7.42) |
| 10 | TEN | 14 | 4.71 (4.04) | 50% (39%) | -0.04 (-0.10) | 43 | -0.01 (-0.10) | 5.92 (5.83) |

## 2026 OFFENSE — JAX Jacksonville Jaguars

Usage concentrations (share well above league avg at his position):
- Trevor Lawrence (QB, 257 att): int left 12% (lg 7%)
- Jakobi Meyers (WR, 43 tgt): int middle 26% (avg 8%)
- Brenton Strange (TE, 40 tgt): int middle 20% (avg 7%)
- Brian Thomas Jr. (WR, 25 tgt): int left 24% (avg 10%); int right 20% (avg 10%)
- Josh Cameron (WR, 17 tgt): short middle 24% (avg 10%)
- Ameer Abdullah (RB, 23 car): runs left tackle 39% (avg 13%); vs 8+ box 22% (avg 8%)
- Chris Rodriguez Jr. (RB, 59 car): runs left guard 24% (avg 13%)

Team passing context:

| stat | value |
|---|---|
| Dropbacks | 286 |
| EPA/dropback | 0.274 |
| Sack rate | 5% |
| Pressure rate faced (NGS) | – |
| EPA/db clean | – |
| EPA/db under pressure | – |
| Blitz rate faced (FTN) | 29% |
| EPA/db vs blitz | 0.152 |
| EPA/db vs no blitz | 0.324 |
| Pass rate over expected | -3.1 pts |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing defense's adjusted rating from its other games; diff = gained − expected; adjusted = league avg + diff; rank 1 = best offense; thin = games where that rating rests on under 100 plays; method in README):

| stat | gained | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 4.01 | 4.17 | -0.16 | 3.93 | 22/32 | 9 | 0 |
| Run success rate | 41.3% | 40.6% | +0.7 | 41.2% | 15/32 | 9 | 0 |
| EPA/rush | -0.010 | -0.033 | +0.024 | -0.033 | 15/32 | 9 | 0 |
| EPA/dropback | 0.274 | 0.073 | +0.201 | 0.249 | 3/32 | 9 | 0 |
| YPA | 8.78 | 7.36 | +1.42 | 8.54 | 2/32 | 9 | 0 |
| Sack rate | 4.9% | 7.1% | -2.2 | 4.2% | 4/32 | 9 | 0 |

QB throw map (share of att, EPA/att in parentheses; ≥40 att):

| QB | att | short left | short middle | short right | int left | int middle | int right | deep left | deep middle | deep right |
|---|---|---|---|---|---|---|---|---|---|---|
| Trevor Lawrence | 257 | 26% (-0.00) | 9% (0.12) | 23% (0.34) | 12% (0.66) | 10% (0.88) | 8% (0.21) | 7% (0.76) | 1% (1.47) | 4% (1.19) |
| league | 9825 | 25% (0.02) | 13% (0.05) | 29% (0.01) | 7% (0.26) | 6% (0.48) | 8% (0.29) | 4% (0.31) | 2% (0.60) | 5% (0.35) |

Player usage, season totals (RZ opps = carries + targets inside the 10 / 5):

| player | pos | G | snap% avg | tgt | tgt share | air yds share | aDOT | rec-yds-TD | YAC/rec | MOF tgt% | car | car share | rush yds-TD | RZ10 opps | RZ5 opps | PPR | PPR/g |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Trevor Lawrence | QB | 9 | 96% | 0 | 0% | 0% | – | 0-0-0 | – | – | 25 | 9% | 106-0 | 1 | 0 | 174.0 | 19.3 |
| Bhayshul Tuten | RB | 9 | 54% | 20 | 8% | -3% | -2.8 | 18-206-3 | 14.4 | 5% | 148 | 56% | 609-5 | 16 | 10 | 147.5 | 16.4 |
| Parker Washington | WR | 9 | 74% | 64 | 26% | 37% | 12.8 | 36-645-6 | 6.2 | 16% | 2 | 1% | 13-0 | 5 | 1 | 137.8 | 15.3 |
| Jakobi Meyers | WR | 9 | 76% | 43 | 18% | 22% | 11.3 | 29-408-2 | 2.7 | 33% | 2 | 1% | 2-0 | 6 | 3 | 82.0 | 9.1 |
| Brenton Strange | TE | 9 | 76% | 40 | 16% | 15% | 8.2 | 32-365-2 | 4.4 | 28% | 0 | 0% | 0-0 | 3 | 1 | 80.5 | 8.9 |
| Chris Rodriguez Jr. | RB | 9 | 26% | 5 | 2% | 0% | 1.6 | 4-36-0 | 7.5 | 20% | 59 | 22% | 233-4 | 9 | 6 | 54.9 | 6.1 |
| Josh Cameron | WR | 9 | 37% | 17 | 7% | 6% | 8.4 | 12-190-3 | 7.3 | 24% | 0 | 0% | 0-0 | 2 | 1 | 49.0 | 5.4 |
| Brian Thomas Jr. | WR | 8 | 44% | 25 | 10% | 13% | 11.4 | 13-146-2 | 0.8 | 8% | 0 | 0% | 0-0 | 4 | 2 | 39.6 | 5.0 |
| Nate Boerkircher | TE | 8 | 49% | 14 | 6% | 5% | 8.7 | 10-156-2 | 6.1 | 14% | 0 | 0% | 0-0 | 3 | 2 | 37.6 | 4.7 |
| Ameer Abdullah | RB | 8 | 7% | 3 | 1% | -1% | -4.0 | 2-2-0 | 5.5 | 0% | 23 | 9% | 88-0 | 1 | 0 | 11.0 | 1.4 |
| Tanner Koziol | TE | 3 | 16% | 4 | 2% | 0% | 2.5 | 4-31-0 | 5.2 | 0% | 0 | 0% | 0-0 | 0 | 0 | 7.1 | 2.4 |
| LeQuint Allen Jr. | RB | 8 | 13% | 8 | 3% | 1% | 2.5 | 2-9-0 | 2.5 | 50% | 1 | 0% | 1-0 | 1 | 1 | 3.0 | 0.4 |
| Quintin Morris | TE | 7 | 17% | 2 | 1% | 0% | 2.5 | 1-7-0 | 4.0 | 0% | 0 | 0% | 0-0 | 0 | 0 | 1.7 | 0.2 |
| Quinn Ewers | QB | 1 | 12% | 0 | 0% | 0% | – | 0-0-0 | – | – | 0 | 0% | 0-0 | 0 | 0 | 0.3 | 0.3 |
| Nick Mullens | QB | 1 | 12% | 0 | 0% | 0% | – | 0-0-0 | – | – | 3 | 1% | -3-0 | 0 | 0 | -0.3 | -0.3 |

Target depth mix (air yards):

| player | behind LOS | 0-9 | 10-19 | 20+ |
|---|---|---|---|---|
| Jakobi Meyers | 7% | 28% | 53% | 12% |
| Parker Washington | 8% | 38% | 33% | 22% |
| Chris Rodriguez Jr. | 20% | 80% | 0% | 0% |
| Brenton Strange | 8% | 52% | 32% | 8% |
| Brian Thomas Jr. | 4% | 36% | 48% | 12% |
| LeQuint Allen Jr. | 12% | 88% | 0% | 0% |
| nan | 40% | 50% | 10% | 0% |
| Bhayshul Tuten | 75% | 25% | 0% | 0% |
| Josh Cameron | 18% | 47% | 18% | 18% |
| Nate Boerkircher | 0% | 71% | 14% | 14% |

RB rushing by bucket (≥8 carries):

| RB | type | bucket | car | YPC | success | EPA/rush |
|---|---|---|---|---|---|---|
| Bhayshul Tuten | formation | shotgun | 33 | 3.03 | 24% | -0.212 |
| Bhayshul Tuten | formation | under center | 115 | 4.43 | 43% | -0.009 |
| Bhayshul Tuten | box | 7 | 54 | 5.07 | 50% | 0.048 |
| Bhayshul Tuten | box | 8+ | 12 | 3.08 | 33% | 0.029 |
| Bhayshul Tuten | box | ≤6 | 82 | 3.63 | 32% | -0.133 |
| Bhayshul Tuten | direction/gap | left end | 22 | 4.36 | 45% | -0.125 |
| Bhayshul Tuten | direction/gap | left guard | 16 | 3.69 | 38% | -0.112 |
| Bhayshul Tuten | direction/gap | left tackle | 15 | 4.53 | 47% | 0.233 |
| Bhayshul Tuten | direction/gap | middle | 30 | 3.87 | 30% | -0.122 |
| Bhayshul Tuten | direction/gap | right end | 18 | 4.17 | 50% | 0.016 |
| Bhayshul Tuten | direction/gap | right guard | 19 | 2.42 | 26% | -0.297 |
| Bhayshul Tuten | direction/gap | right tackle | 28 | 5.32 | 39% | 0.075 |
| Chris Rodriguez Jr. | formation | shotgun | 22 | 5.09 | 50% | 0.232 |
| Chris Rodriguez Jr. | formation | under center | 37 | 3.27 | 35% | -0.109 |
| Chris Rodriguez Jr. | box | 7 | 34 | 4.41 | 41% | 0.053 |
| Chris Rodriguez Jr. | box | 8+ | 6 | 3.33 | 50% | 0.079 |
| Chris Rodriguez Jr. | box | ≤6 | 19 | 3.32 | 37% | -0.062 |
| Chris Rodriguez Jr. | direction/gap | left end | 3 | 3.67 | 0% | -0.190 |
| Chris Rodriguez Jr. | direction/gap | left guard | 14 | 5.29 | 43% | 0.084 |
| Chris Rodriguez Jr. | direction/gap | left tackle | 6 | 3.33 | 50% | 0.153 |
| Chris Rodriguez Jr. | direction/gap | middle | 17 | 5.65 | 71% | 0.343 |
| Chris Rodriguez Jr. | direction/gap | right end | 2 | 4.00 | 50% | 0.142 |
| Chris Rodriguez Jr. | direction/gap | right guard | 8 | 2.75 | 25% | -0.170 |
| Chris Rodriguez Jr. | direction/gap | right tackle | 9 | 0.22 | 0% | -0.578 |
| Ameer Abdullah | formation | shotgun | 5 | 6.80 | 60% | 0.025 |
| Ameer Abdullah | formation | under center | 18 | 3.00 | 39% | -0.069 |
| Ameer Abdullah | box | 7 | 5 | 0.40 | 0% | -0.447 |
| Ameer Abdullah | box | 8+ | 5 | 0.60 | 0% | -0.377 |
| Ameer Abdullah | box | ≤6 | 13 | 6.38 | 77% | 0.231 |
| Ameer Abdullah | direction/gap | left guard | 1 | 5.00 | 100% | 0.208 |
| Ameer Abdullah | direction/gap | left tackle | 9 | 3.00 | 44% | -0.095 |
| Ameer Abdullah | direction/gap | middle | 4 | 6.00 | 50% | -0.110 |
| Ameer Abdullah | direction/gap | right end | 2 | -0.50 | 0% | -0.310 |
| Ameer Abdullah | direction/gap | right guard | 4 | 5.00 | 50% | 0.029 |
| Ameer Abdullah | direction/gap | right tackle | 3 | 4.33 | 33% | 0.157 |

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
| Ameer Abdullah | RB | 9 | BAL | 12% | 0 | 0% | 0-0-0 | – | 7 | 23% | 30-0 | 3.0 |
| Bhayshul Tuten | RB | 1 | CLE | 49% | 1 | 5% | 1-22-0 | -5.0 | 15 | 47% | 66-0 | 9.8 |
| Bhayshul Tuten | RB | 2 | DEN | 51% | 2 | 7% | 2-(-3)-0 | -4.0 | 13 | 54% | 65-1 | 14.2 |
| Bhayshul Tuten | RB | 3 | NE | 48% | 2 | 7% | 2-17-0 | -3.5 | 15 | 50% | 73-1 | 17.0 |
| Bhayshul Tuten | RB | 4 | CIN | 59% | 2 | 9% | 2-18-0 | -1.0 | 17 | 63% | 73-0 | 11.1 |
| Bhayshul Tuten | RB | 5 | PHI | 68% | 3 | 8% | 2-24-0 | -2.7 | 22 | 81% | 72-0 | 11.6 |
| Bhayshul Tuten | RB | 6 | HOU | 58% | 4 | 11% | 4-48-2 | -3.2 | 12 | 44% | 39-0 | 24.7 |
| Bhayshul Tuten | RB | 8 | IND | 50% | 2 | 12% | 2-55-1 | -3.0 | 16 | 48% | 104-1 | 29.9 |
| Bhayshul Tuten | RB | 9 | BAL | 36% | 0 | 0% | 0-0-0 | – | 12 | 40% | 29-1 | 8.9 |
| Bhayshul Tuten | RB | 10 | TEN | 70% | 4 | 12% | 3-25-0 | -1.8 | 26 | 72% | 88-1 | 20.3 |
| Brenton Strange | TE | 1 | CLE | 68% | 3 | 15% | 2-23-1 | 11.3 | 0 | 0% | 0-0 | 10.3 |
| Brenton Strange | TE | 2 | DEN | 83% | 2 | 7% | 2-17-0 | 8.5 | 0 | 0% | 0-0 | 3.7 |
| Brenton Strange | TE | 3 | NE | 77% | 5 | 19% | 3-32-0 | 6.4 | 0 | 0% | 0-0 | 6.2 |
| Brenton Strange | TE | 4 | CIN | 87% | 8 | 35% | 7-95-0 | 7.2 | 0 | 0% | 0-0 | 16.5 |
| Brenton Strange | TE | 5 | PHI | 81% | 8 | 22% | 7-68-0 | 7.1 | 0 | 0% | 0-0 | 13.8 |
| Brenton Strange | TE | 6 | HOU | 76% | 7 | 19% | 5-44-0 | 8.0 | 0 | 0% | 0-0 | 9.4 |
| Brenton Strange | TE | 8 | IND | 52% | 2 | 12% | 2-55-0 | 11.0 | 0 | 0% | 0-0 | 7.5 |
| Brenton Strange | TE | 9 | BAL | 79% | 2 | 8% | 2-22-0 | 10.0 | 0 | 0% | 0-0 | 4.2 |
| Brenton Strange | TE | 10 | TEN | 78% | 3 | 9% | 2-9-1 | 11.0 | 0 | 0% | 0-0 | 8.9 |
| Brian Thomas Jr. | WR | 1 | CLE | 35% | 3 | 15% | 3-40-0 | 14.7 | 0 | 0% | 0-0 | 7.0 |
| Brian Thomas Jr. | WR | 2 | DEN | 54% | 8 | 29% | 3-40-0 | 10.2 | 0 | 0% | 0-0 | 7.0 |
| Brian Thomas Jr. | WR | 3 | NE | 37% | 1 | 4% | 1-8-0 | 4.0 | 0 | 0% | 0-0 | 1.8 |
| Brian Thomas Jr. | WR | 4 | CIN | 62% | 2 | 9% | 2-17-1 | 8.5 | 0 | 0% | 0-0 | 9.7 |
| Brian Thomas Jr. | WR | 5 | PHI | 51% | 3 | 8% | 0-0-0 | 12.7 | 0 | 0% | 0-0 | 0.0 |
| Brian Thomas Jr. | WR | 6 | HOU | 21% | 2 | 5% | 0-0-0 | 17.0 | 0 | 0% | 0-0 | 0.0 |
| Brian Thomas Jr. | WR | 8 | IND | 52% | 2 | 12% | 1-12-1 | 19.0 | 0 | 0% | 0-0 | 8.2 |
| Brian Thomas Jr. | WR | 10 | TEN | 48% | 4 | 12% | 3-29-0 | 7.2 | 0 | 0% | 0-0 | 5.9 |
| Chris Rodriguez Jr. | RB | 1 | CLE | 40% | 0 | 0% | 0-0-0 | – | 6 | 19% | 23-0 | 2.3 |
| Chris Rodriguez Jr. | RB | 2 | DEN | 22% | 0 | 0% | 0-0-0 | – | 6 | 25% | 13-0 | 1.3 |
| Chris Rodriguez Jr. | RB | 3 | NE | 21% | 0 | 0% | 0-0-0 | – | 8 | 27% | 37-1 | 9.7 |
| Chris Rodriguez Jr. | RB | 4 | CIN | 25% | 0 | 0% | 0-0-0 | – | 6 | 22% | 35-1 | 9.5 |
| Chris Rodriguez Jr. | RB | 5 | PHI | 12% | 1 | 3% | 1-6-0 | 2.0 | 2 | 7% | 5-0 | 2.1 |
| Chris Rodriguez Jr. | RB | 6 | HOU | 30% | 1 | 3% | 0-0-0 | 2.0 | 11 | 41% | 55-0 | 5.5 |
| Chris Rodriguez Jr. | RB | 8 | IND | 22% | 1 | 6% | 1-17-0 | 3.0 | 6 | 18% | 41-1 | 12.8 |
| Chris Rodriguez Jr. | RB | 9 | BAL | 45% | 2 | 8% | 2-13-0 | 0.5 | 10 | 33% | 19-1 | 11.2 |
| Chris Rodriguez Jr. | RB | 10 | TEN | 14% | 0 | 0% | 0-0-0 | – | 4 | 11% | 5-0 | 0.5 |
| Jakobi Meyers | WR | 1 | CLE | 65% | 2 | 10% | 2-40-1 | 14.5 | 1 | 3% | 2-0 | 12.2 |
| Jakobi Meyers | WR | 2 | DEN | 90% | 1 | 4% | 1-28-0 | 21.0 | 0 | 0% | 0-0 | 3.8 |
| Jakobi Meyers | WR | 3 | NE | 81% | 8 | 30% | 7-64-1 | 8.0 | 0 | 0% | 0-0 | 19.4 |
| Jakobi Meyers | WR | 4 | CIN | 82% | 4 | 17% | 3-33-0 | 8.8 | 0 | 0% | 0-0 | 6.3 |
| Jakobi Meyers | WR | 5 | PHI | 85% | 3 | 8% | 2-37-0 | 10.3 | 0 | 0% | 0-0 | 5.7 |
| Jakobi Meyers | WR | 6 | HOU | 75% | 10 | 27% | 5-83-0 | 11.7 | 0 | 0% | 0-0 | 13.3 |
| Jakobi Meyers | WR | 8 | IND | 54% | 3 | 19% | 2-24-0 | 10.0 | 0 | 0% | 0-0 | 4.4 |
| Jakobi Meyers | WR | 9 | BAL | 68% | 6 | 24% | 4-65-0 | 11.0 | 0 | 0% | 0-0 | 10.5 |
| Jakobi Meyers | WR | 10 | TEN | 81% | 6 | 19% | 3-34-0 | 15.5 | 1 | 3% | 0-0 | 6.4 |
| Josh Cameron | WR | 1 | CLE | 33% | 2 | 10% | 2-20-1 | 9.0 | 0 | 0% | 0-0 | 10.0 |
| Josh Cameron | WR | 2 | DEN | 17% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Josh Cameron | WR | 3 | NE | 37% | 2 | 7% | 1-12-1 | 10.0 | 0 | 0% | 0-0 | 8.2 |
| Josh Cameron | WR | 4 | CIN | 36% | 2 | 9% | 2-42-0 | 3.5 | 0 | 0% | 0-0 | 6.2 |
| Josh Cameron | WR | 5 | PHI | 31% | 6 | 16% | 3-43-0 | 2.3 | 0 | 0% | 0-0 | 7.3 |
| Josh Cameron | WR | 6 | HOU | 51% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Josh Cameron | WR | 8 | IND | 52% | 1 | 6% | 0-0-0 | 28.0 | 0 | 0% | 0-0 | 0.0 |
| Josh Cameron | WR | 9 | BAL | 45% | 1 | 4% | 1-6-0 | 5.0 | 0 | 0% | 0-0 | 1.6 |
| Josh Cameron | WR | 10 | TEN | 33% | 3 | 9% | 3-67-1 | 17.0 | 0 | 0% | 0-0 | 15.7 |
| LeQuint Allen Jr. | RB | 2 | DEN | 15% | 1 | 4% | 0-0-0 | 4.0 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 3 | NE | 18% | 2 | 7% | 2-9-0 | 2.0 | 0 | 0% | 0-0 | 2.9 |
| LeQuint Allen Jr. | RB | 4 | CIN | 15% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 5 | PHI | 18% | 2 | 5% | 0-0-0 | 2.5 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 6 | HOU | 11% | 0 | 0% | 0-0-0 | – | 1 | 4% | 1-0 | 0.1 |
| LeQuint Allen Jr. | RB | 8 | IND | 11% | 1 | 6% | 0-0-0 | 8.0 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 9 | BAL | 7% | 2 | 8% | 0-0-0 | -0.5 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 10 | TEN | 16% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Nate Boerkircher | TE | 1 | CLE | 67% | 1 | 5% | 1-9-0 | 2.0 | 0 | 0% | 0-0 | 1.9 |
| Nate Boerkircher | TE | 3 | NE | 45% | 1 | 4% | 0-0-0 | 4.0 | 0 | 0% | 0-0 | 0.0 |
| Nate Boerkircher | TE | 4 | CIN | 34% | 2 | 9% | 1-15-0 | 4.5 | 0 | 0% | 0-0 | 2.5 |
| Nate Boerkircher | TE | 5 | PHI | 49% | 2 | 5% | 2-20-0 | 7.0 | 0 | 0% | 0-0 | 4.0 |
| Nate Boerkircher | TE | 6 | HOU | 55% | 2 | 5% | 2-8-1 | 2.5 | 0 | 0% | 0-0 | 8.8 |
| Nate Boerkircher | TE | 8 | IND | 48% | 1 | 6% | 1-31-1 | 25.0 | 0 | 0% | 0-0 | 10.1 |
| Nate Boerkircher | TE | 9 | BAL | 55% | 3 | 12% | 2-61-0 | 14.7 | 0 | 0% | 0-0 | 8.1 |
| Nate Boerkircher | TE | 10 | TEN | 49% | 2 | 6% | 1-12-0 | 9.5 | 0 | 0% | 0-0 | 2.2 |
| Nick Mullens | QB | 1 | CLE | 12% | 0 | 0% | 0-0-0 | – | 3 | 9% | -3-0 | -0.3 |
| Parker Washington | WR | 1 | CLE | 61% | 6 | 30% | 5-83-1 | 17.0 | 0 | 0% | 0-0 | 19.3 |
| Parker Washington | WR | 2 | DEN | 81% | 12 | 43% | 7-98-0 | 14.8 | 0 | 0% | 0-0 | 16.8 |
| Parker Washington | WR | 3 | NE | 81% | 5 | 19% | 3-40-1 | 10.0 | 0 | 0% | 0-0 | 13.0 |
| Parker Washington | WR | 4 | CIN | 80% | 3 | 13% | 1-7-0 | 12.7 | 1 | 4% | 3-0 | 2.0 |
| Parker Washington | WR | 5 | PHI | 82% | 9 | 24% | 6-124-2 | 8.8 | 0 | 0% | 0-0 | 30.4 |
| Parker Washington | WR | 6 | HOU | 73% | 11 | 30% | 4-64-0 | 13.9 | 0 | 0% | 0-0 | 10.4 |
| Parker Washington | WR | 8 | IND | 67% | 2 | 12% | 1-16-0 | 9.5 | 1 | 3% | 10-0 | 3.6 |
| Parker Washington | WR | 9 | BAL | 68% | 7 | 28% | 2-61-1 | 8.7 | 0 | 0% | 0-0 | 14.1 |
| Parker Washington | WR | 10 | TEN | 77% | 9 | 28% | 7-152-1 | 15.3 | 0 | 0% | 0-0 | 28.2 |
| Quinn Ewers | QB | 8 | IND | 19% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.3 |
| Quintin Morris | TE | 1 | CLE | 42% | 1 | 5% | 0-0-0 | 2.0 | 0 | 0% | 0-0 | 0.0 |
| Quintin Morris | TE | 2 | DEN | 22% | 1 | 4% | 1-7-0 | 3.0 | 0 | 0% | 0-0 | 1.7 |
| Quintin Morris | TE | 4 | CIN | 2% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Quintin Morris | TE | 5 | PHI | 3% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Quintin Morris | TE | 8 | IND | 20% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Quintin Morris | TE | 9 | BAL | 11% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Quintin Morris | TE | 10 | TEN | 8% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Tanner Koziol | TE | 8 | IND | 35% | 1 | 6% | 1-8-0 | 1.0 | 0 | 0% | 0-0 | 1.8 |
| Tanner Koziol | TE | 9 | BAL | 21% | 2 | 8% | 2-15-0 | 3.5 | 0 | 0% | 0-0 | 3.5 |
| Tanner Koziol | TE | 10 | TEN | 10% | 1 | 3% | 1-8-0 | 2.0 | 0 | 0% | 0-0 | 1.8 |
| Trevor Lawrence | QB | 1 | CLE | 88% | 0 | 0% | 0-0-0 | – | 2 | 6% | 3-0 | 26.1 |
| Trevor Lawrence | QB | 2 | DEN | 100% | 0 | 0% | 0-0-0 | – | 2 | 8% | 6-0 | 6.2 |
| Trevor Lawrence | QB | 3 | NE | 95% | 0 | 0% | 0-0-0 | – | 4 | 13% | 25-0 | 19.8 |
| Trevor Lawrence | QB | 4 | CIN | 100% | 0 | 0% | 0-0-0 | – | 3 | 11% | 0-0 | 13.1 |
| Trevor Lawrence | QB | 5 | PHI | 100% | 0 | 0% | 0-0-0 | – | 3 | 11% | 25-0 | 21.7 |
| Trevor Lawrence | QB | 6 | HOU | 100% | 0 | 0% | 0-0-0 | – | 3 | 11% | 11-0 | 27.3 |
| Trevor Lawrence | QB | 8 | IND | 81% | 0 | 0% | 0-0-0 | – | 3 | 9% | 10-0 | 19.4 |
| Trevor Lawrence | QB | 9 | BAL | 100% | 0 | 0% | 0-0-0 | – | 1 | 3% | -1-0 | 13.6 |
| Trevor Lawrence | QB | 10 | TEN | 100% | 0 | 0% | 0-0-0 | – | 4 | 11% | 27-0 | 26.8 |

Game by game, 2026: gained (expected vs that defense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | CLE | 28 | 4.54 (4.41) | 54% (40%) | -0.03 (-0.04) | 24 | 0.67 (-0.00) | 10.65 (6.59) |
| 2 | DEN | 24 | 3.96 (4.06) | 46% (34%) | 0.05 (-0.05) | 31 | -0.09 (-0.02) | 6.52 (6.31) |
| 3 | NE | 28 | 4.61 (4.05) | 50% (38%) | 0.20 (-0.06) | 31 | 0.22 (0.10) | 6.50 (7.95) |
| 4 | CIN | 25 | 4.52 (4.23) | 36% (37%) | 0.05 (-0.07) | 28 | 0.26 (0.08) | 9.46 (7.19) |
| 5 | PHI | 24 | 3.21 (4.11) | 29% (45%) | -0.27 (0.04) | 44 | 0.24 (0.10) | 8.49 (7.00) |
| 6 | HOU | 24 | 3.96 (3.99) | 50% (41%) | 0.01 (-0.05) | 43 | 0.25 (0.03) | 7.46 (7.60) |
| 8 | IND | 31 | 5.65 (4.52) | 42% (43%) | 0.15 (-0.02) | 22 | 0.23 (0.05) | 12.82 (7.93) |
| 9 | BAL | 29 | 2.69 (3.67) | 34% (43%) | -0.15 (-0.03) | 26 | 0.23 (0.09) | 9.31 (7.52) |
| 10 | TEN | 34 | 2.97 (4.38) | 32% (43%) | -0.11 (-0.02) | 37 | 0.50 (0.19) | 10.35 (8.16) |
