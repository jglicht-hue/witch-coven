# JAX Jacksonville Jaguars — Matchup Witch data, 2026 (current)

Source: nflverse (play-by-play, NGS participation, FTN charting, player stats, snap counts). Built 2026-11-24 14:53 UTC. Regular season only.
- 2026: weeks 1–11, 163 games, last game 2026-11-23; NGS participation NO (route, man/zone, coverage, pressure unavailable)

## 2026 DEFENSE — JAX Jacksonville Jaguars (10 games)

Flags, 2026 (leads to test, not verdicts; rank 1 = best D, among teams with enough plays; see README):

Weak (bottom ~15%):
- rush EPA, runs, right tackle: 0.317 (lg -0.006; 32/32; n=21)
- pass D, sack rate: 5% (lg 6%; 30/32)
- pass EPA/att, deep middle: +0.81 (lg +0.54; 15/16; n=8)

Strong (top ~15%):
- run D, EPA/rush: -0.143 (lg -0.034; 1/32)
- rush EPA, ≤6 box: -0.301 (lg -0.034; 1/32; n=69)
- pass EPA/att, short left: -0.28 (lg +0.02; 2/32; n=102)
- pass EPA/att, short middle: -0.31 (lg +0.06; 2/32; n=37)
- pass EPA/att, short right: -0.20 (lg +0.01; 2/32; n=89)
- rush EPA, runs, left tackle: -0.281 (lg -0.012; 3/32; n=24)
- PPR/g allowed, RB: 17.8 (lg 22.1; 3/32)
- run D, 10+ yd runs/game: 1.60 (lg 2.28; 4/32)
- rush EPA, runs, left guard: -0.251 (lg -0.042; 4/32; n=25)
- PPR/g allowed, TE: 10.6 (lg 13.4; 5/32)
- pass D, 20+ yd completions/game: 2.40 (lg 2.94; 5/32)
- pass D, EPA/dropback: -0.074 (lg 0.042; 5/32)

Fantasy points allowed (PPR, nflverse scoring incl. rushing, fumbles, 2-pt). Rank 1 = fewest allowed.

| pos | PPR total | PPR/game | rank |
|---|---|---|---|
| QB | 139.7 | 14.0 | 7 |
| RB | 178.1 | 17.8 | 3 |
| WR | 320.9 | 32.1 | 15 |
| TE | 106.4 | 10.6 | 5 |

Unit stats (rank 1 = best defense):

| stat | value | rank |
|---|---|---|
| EPA/dropback | -0.074 | 5 |
| YPA | 6.82 | 11 |
| Comp % | 64% | 19 |
| 20+ yd completions/game | 2.40 | 5 |
| Sack rate | 5% | 30 |
| Pressure rate (NGS) | – | – |
| Blitz rate (FTN: 1+ blitzer) | 32% | – |
| Man coverage rate (NGS) | – | – |
| EPA/rush (designed runs) | -0.143 | 1 |
| YPC | 3.62 | 8 |
| Rush success rate | 38% | 6 |
| Stuff rate (≤0 yds) | 20% | 6 |
| 10+ yd runs/game | 1.60 | 4 |
| 20+ yd runs/game | 0.20 | – |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing offense's adjusted rating from its other games; diff = allowed − expected, or for rates the % change vs expected; adjusted = league avg + diff; rank 1 = best defense; thin = games where that rating rests on under 100 plays; method in README):

| stat | allowed | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 3.62 | 3.83 | -0.21 | 3.89 | 12/32 | 10 | 0 |
| Run success rate | 38.5% | 41.2% | −6.6% | 40.0% | 7/32 | 10 | 0 |
| EPA/rush | -0.143 | -0.059 | -0.084 | -0.118 | 2/32 | 10 | 0 |
| EPA/dropback | -0.074 | 0.022 | -0.097 | -0.055 | 5/32 | 10 | 0 |
| YPA | 6.82 | 6.80 | +0.02 | 7.12 | 17/32 | 10 | 0 |
| Sack rate | 4.8% | 6.8% | −29.6% | 4.5% | 31/32 | 10 | 0 |

QB rushing allowed (runs + scrambles): 36 car, 188 yds, 2 TD; 18.8 yds/g (rank 24/32; lg 16.6); scramble rate 5% (lg 5%)

Passing allowed by throw (rank by EPA/att among teams with ≥8 att; share = opp. QBs' share of att here, usual = their share in other games):

| cell | att | comp | YPA | TD | INT | EPA | rank | share | usual |
|---|---|---|---|---|---|---|---|---|---|
| short left | 102 | 70% | 4.72 | 3 | 6 | -0.28 | 2/32 | 30% | 25% |
| short middle | 37 | 65% | 5.03 | 0 | 1 | -0.31 | 2/32 | 11% | 13% |
| short right | 89 | 74% | 4.67 | 4 | 3 | -0.20 | 2/32 | 27% | 30% |
| int left | 21 | 62% | 10.52 | 0 | 1 | 0.34 | 22/32 | 6% | 7% |
| int middle | 20 | 70% | 11.85 | 1 | 1 | 0.66 | 24/32 | 6% | 5% |
| int right | 33 | 52% | 7.88 | 1 | 0 | 0.26 | 14/32 | 10% | 8% |
| deep left | 12 | 25% | 9.58 | 0 | 0 | -0.05 | 6/31 | 4% | 4% |
| deep middle | 8 | 38% | 18.12 | 1 | 0 | 0.81 | 15/16 | 2% | 2% |
| deep right | 17 | 41% | 14.71 | 1 | 0 | 0.66 | 23/32 | 5% | 5% |

Targets allowed by receiver position:

| pos | tgt | catch | YPT | TD | PPR/tgt |
|---|---|---|---|---|---|
| RB | 66 | 80% | 5.24 | 1 | 1.42 |
| WR | 195 | 64% | 8.32 | 5 | 1.62 |
| TE | 63 | 65% | 5.44 | 5 | 1.67 |

Run defense by bucket (box count from FTN charting):

| type | bucket | rushes | YPC | success | EPA/rush |
|---|---|---|---|---|---|
| box | 7 | 84 | 4.05 | 30% | -0.093 |
| box | 8+ | 55 | 2.71 | 49% | -0.021 |
| box | ≤6 | 69 | 3.83 | 41% | -0.301 |
| direction/gap | ? | 4 | 0.00 | 0% | -2.261 |
| direction/gap | left end | 34 | 3.24 | 44% | -0.163 |
| direction/gap | left guard | 25 | 2.40 | 44% | -0.251 |
| direction/gap | left tackle | 24 | 4.71 | 29% | -0.281 |
| direction/gap | middle | 53 | 2.81 | 32% | -0.106 |
| direction/gap | right end | 29 | 4.03 | 45% | -0.048 |
| direction/gap | right guard | 18 | 3.06 | 33% | -0.099 |
| direction/gap | right tackle | 21 | 7.10 | 52% | 0.317 |
| offense formation | shotgun | 94 | 4.07 | 44% | -0.189 |
| offense formation | under center | 114 | 3.25 | 34% | -0.105 |

RB targets allowed by route type:

| route | tgt | catch | YPT | PPR/tgt |
|---|---|---|---|---|
| (route n/a) | 49 | 80% | 5.61 | 1.48 |
| screen | 17 | 82% | 4.18 | 1.24 |

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
| 11 | RB | NYG | Cam Skattebo | 14-34-0 rush, 7 tgt 3-14-0 rec | 5.8 | 7.8 |
| 1 | TE | CLE | Harold Fannin Jr. | 3 tgt, 2-21-0 | 4.1 | 6.5 |
| 2 | TE | DEN | Nate Adkins | 3 tgt, 3-32-1 (+1-6 rush) | 12.8 | 15.5 |
| 3 | TE | NE | Hunter Henry | 2 tgt, 1-5-0 | 1.5 | 1.5 |
| 4 | TE | CIN | Mike Gesicki | 5 tgt, 3-40-1 | 13.0 | 14.2 |
| 5 | TE | PHI | Dallas Goedert | 9 tgt, 6-38-0 | 9.8 | 9.8 |
| 6 | TE | HOU | Foster Moreau | 2 tgt, 2-7-2 | 14.7 | 23.4 |
| 8 | TE | IND | Tyler Warren | 10 tgt, 4-18-0 | 5.8 | 5.8 |
| 9 | TE | BAL | Mark Andrews | 2 tgt, 2-19-0 (+2-0 rush) | 3.9 | 5.4 |
| 10 | TE | TEN | Daniel Bellinger | 3 tgt, 2-6-1 | 8.6 | 14.9 |
| 11 | TE | NYG | Isaiah Likely | 3 tgt, 1-35-0 | 4.5 | 9.4 |
| 1 | WR | CLE | Denzel Boston | 4 tgt, 2-59-1 | 13.9 | 26.3 |
| 2 | WR | DEN | Jaylen Waddle | 10 tgt, 8-138-0 | 21.8 | 32.6 |
| 3 | WR | NE | Mack Hollins | 9 tgt, 6-87-0 | 14.7 | 33.5 |
| 4 | WR | CIN | Tee Higgins | 16 tgt, 11-157-0 | 26.7 | 55.5 |
| 5 | WR | PHI | Darius Cooper | 3 tgt, 2-71-1 | 15.1 | 35.7 |
| 6 | WR | HOU | Jaylin Noel | 4 tgt, 4-107-1 | 20.7 | 44.6 |
| 8 | WR | IND | Keenan Allen | 7 tgt, 7-67-0 | 13.7 | 30.3 |
| 9 | WR | BAL | Zay Flowers | 6 tgt, 3-6-0 (+3-17 rush) | 5.3 | 9.3 |
| 10 | WR | TEN | Elic Ayomanor | 10 tgt, 5-79-0 | 12.9 | 27.1 |
| 11 | WR | NYG | Malik Nabers | 12 tgt, 7-55-1 | 18.5 | 26.0 |

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
| 11 | NYG | J.J. McCarthy | 18/38 | 173 | 1 | 0 | 1 | 7-33-0 | 0 | 14.2 | Jameis Winston 0/1, 3 car, 6.5 pts | 20.7 |

Game by game, 2026: allowed (expected vs that offense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | CLE | 19 | 3.53 (3.60) | 47% (37%) | -0.08 (-0.15) | 30 | -0.18 (-0.01) | 9.32 (7.13) |
| 2 | DEN | 25 | 4.28 (3.73) | 44% (43%) | -0.08 (0.01) | 31 | 0.22 (0.02) | 9.29 (5.82) |
| 3 | NE | 23 | 2.78 (4.04) | 35% (39%) | -0.07 (-0.09) | 37 | -0.32 (0.15) | 7.90 (8.29) |
| 4 | CIN | 13 | 1.38 (4.19) | 23% (43%) | -0.24 (-0.03) | 58 | 0.09 (0.29) | 7.93 (8.02) |
| 5 | PHI | 17 | 1.18 (3.63) | 24% (37%) | -0.49 (-0.06) | 42 | -0.01 (-0.17) | 5.50 (5.69) |
| 6 | HOU | 24 | 4.54 (2.99) | 42% (34%) | 0.06 (-0.16) | 35 | 0.30 (0.11) | 9.18 (7.28) |
| 8 | IND | 21 | 4.67 (4.34) | 43% (48%) | -0.23 (0.06) | 37 | -0.49 (-0.23) | 5.07 (5.12) |
| 9 | BAL | 33 | 4.94 (4.11) | 39% (44%) | -0.07 (-0.05) | 21 | -0.55 (0.03) | 3.00 (7.49) |
| 10 | TEN | 14 | 4.71 (3.98) | 57% (46%) | -0.02 (-0.06) | 43 | -0.04 (-0.10) | 5.92 (6.05) |
| 11 | NYG | 19 | 2.16 (3.77) | 26% (40%) | -0.38 (-0.08) | 43 | -0.03 (0.02) | 4.44 (6.95) |

## 2026 OFFENSE — JAX Jacksonville Jaguars

Usage concentrations (share well above league avg at his position):
- Trevor Lawrence (QB, 304 att): int left 14% (lg 7%)
- Jakobi Meyers (WR, 53 tgt): int middle 21% (avg 8%)
- Parker Washington (WR, 81 tgt): int left 22% (avg 10%)
- Brenton Strange (TE, 43 tgt): int middle 19% (avg 7%)
- Brian Thomas Jr. (WR, 28 tgt): int left 21% (avg 10%)
- Josh Cameron (WR, 24 tgt): int left 21% (avg 10%)
- Ameer Abdullah (RB, 23 car): runs left tackle 39% (avg 13%); vs 8+ box 22% (avg 8%)
- Chris Rodriguez Jr. (RB, 63 car): runs left guard 24% (avg 13%)

Team passing context:

| stat | value |
|---|---|
| Dropbacks | 337 |
| EPA/dropback | 0.202 |
| Sack rate | 5% |
| Pressure rate faced (NGS) | – |
| EPA/db clean | – |
| EPA/db under pressure | – |
| Blitz rate faced (FTN) | 28% |
| EPA/db vs blitz | 0.087 |
| EPA/db vs no blitz | 0.248 |
| Pass rate over expected | −1.5% vs expected |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing defense's adjusted rating from its other games; diff = gained − expected, or for rates the % change vs expected; adjusted = league avg + diff; rank 1 = best offense; thin = games where that rating rests on under 100 plays; method in README):

| stat | gained | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 4.06 | 4.22 | -0.16 | 3.94 | 21/32 | 10 | 0 |
| Run success rate | 43.7% | 42.4% | +3.0% | 43.9% | 13/32 | 10 | 0 |
| EPA/rush | 0.011 | -0.016 | +0.028 | -0.006 | 13/32 | 10 | 0 |
| EPA/dropback | 0.202 | 0.063 | +0.139 | 0.182 | 5/32 | 10 | 0 |
| YPA | 8.39 | 7.25 | +1.15 | 8.25 | 4/32 | 10 | 0 |
| Sack rate | 5.0% | 6.9% | −27.1% | 4.6% | 5/32 | 10 | 0 |

QB throw map (share of att, EPA/att in parentheses; ≥40 att):

| QB | att | short left | short middle | short right | int left | int middle | int right | deep left | deep middle | deep right |
|---|---|---|---|---|---|---|---|---|---|---|
| Trevor Lawrence | 304 | 25% (-0.05) | 10% (0.13) | 21% (0.30) | 14% (0.31) | 10% (0.82) | 7% (0.22) | 6% (0.62) | 2% (0.62) | 4% (1.11) |
| league | 10692 | 25% (0.02) | 13% (0.06) | 29% (0.01) | 7% (0.22) | 6% (0.45) | 8% (0.26) | 4% (0.31) | 2% (0.54) | 5% (0.32) |

Player usage, season totals (RZ opps = carries + targets inside the 10 / 5):

| player | pos | G | snap% avg | tgt | tgt share | air yds share | aDOT | rec-yds-TD | YAC/rec | MOF tgt% | car | car share | rush yds-TD | RZ10 opps | RZ5 opps | PPR | PPR/g |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Trevor Lawrence | QB | 10 | 96% | 0 | 0% | 0% | – | 0-0-0 | – | – | 28 | 10% | 113-0 | 1 | 0 | 186.7 | 18.7 |
| Parker Washington | WR | 10 | 75% | 81 | 28% | 39% | 13.3 | 44-748-6 | 5.7 | 20% | 2 | 1% | 13-0 | 6 | 1 | 156.1 | 15.6 |
| Bhayshul Tuten | RB | 10 | 53% | 23 | 8% | -2% | -2.7 | 21-226-3 | 13.6 | 9% | 158 | 56% | 642-5 | 16 | 10 | 155.8 | 15.6 |
| Jakobi Meyers | WR | 10 | 76% | 53 | 18% | 22% | 11.4 | 33-493-2 | 2.9 | 32% | 2 | 1% | 2-0 | 8 | 3 | 94.5 | 9.4 |
| Brenton Strange | TE | 10 | 76% | 43 | 15% | 12% | 7.9 | 35-381-2 | 4.1 | 28% | 0 | 0% | 0-0 | 3 | 1 | 85.1 | 8.5 |
| Chris Rodriguez Jr. | RB | 10 | 27% | 6 | 2% | 0% | 1.8 | 5-49-0 | 8.0 | 33% | 63 | 22% | 261-4 | 9 | 6 | 60.0 | 6.0 |
| Josh Cameron | WR | 10 | 37% | 24 | 8% | 9% | 10.1 | 15-234-3 | 6.1 | 28% | 0 | 0% | 0-0 | 3 | 2 | 56.4 | 5.6 |
| Brian Thomas Jr. | WR | 9 | 44% | 28 | 10% | 12% | 12.3 | 14-164-3 | 0.8 | 14% | 0 | 0% | 0-0 | 4 | 2 | 48.4 | 5.4 |
| Nate Boerkircher | TE | 8 | 47% | 14 | 5% | 4% | 8.7 | 10-156-2 | 6.1 | 14% | 0 | 0% | 0-0 | 3 | 2 | 37.6 | 4.7 |
| Ameer Abdullah | RB | 9 | 6% | 3 | 1% | -0% | -4.0 | 2-2-0 | 5.5 | 0% | 23 | 8% | 88-0 | 1 | 0 | 11.0 | 1.2 |
| Tanner Koziol | TE | 3 | 14% | 4 | 1% | 0% | 2.5 | 4-31-0 | 5.2 | 0% | 0 | 0% | 0-0 | 0 | 0 | 7.1 | 2.4 |
| LeQuint Allen Jr. | RB | 9 | 13% | 9 | 3% | 1% | 2.1 | 3-8-0 | 1.7 | 44% | 1 | 0% | 1-0 | 1 | 1 | 3.9 | 0.4 |
| Quintin Morris | TE | 7 | 16% | 2 | 1% | 0% | 2.5 | 1-7-0 | 4.0 | 0% | 0 | 0% | 0-0 | 0 | 0 | 1.7 | 0.2 |
| Quinn Ewers | QB | 1 | 12% | 0 | 0% | 0% | – | 0-0-0 | – | – | 0 | 0% | 0-0 | 0 | 0 | 0.3 | 0.3 |
| Nick Mullens | QB | 1 | 12% | 0 | 0% | 0% | – | 0-0-0 | – | – | 3 | 1% | -3-0 | 0 | 0 | -0.3 | -0.3 |

Target depth mix (air yards):

| player | behind LOS | 0-9 | 10-19 | 20+ |
|---|---|---|---|---|
| Jakobi Meyers | 6% | 32% | 49% | 13% |
| Parker Washington | 7% | 36% | 33% | 23% |
| Chris Rodriguez Jr. | 17% | 83% | 0% | 0% |
| Brenton Strange | 7% | 56% | 30% | 7% |
| Brian Thomas Jr. | 4% | 32% | 50% | 14% |
| LeQuint Allen Jr. | 22% | 78% | 0% | 0% |
| nan | 45% | 45% | 9% | 0% |
| Bhayshul Tuten | 74% | 26% | 0% | 0% |
| Josh Cameron | 12% | 33% | 38% | 17% |
| Nate Boerkircher | 0% | 71% | 14% | 14% |

RB rushing by bucket (≥8 carries):

| RB | type | bucket | car | YPC | success | EPA/rush |
|---|---|---|---|---|---|---|
| Bhayshul Tuten | formation | shotgun | 36 | 3.11 | 31% | -0.162 |
| Bhayshul Tuten | formation | under center | 122 | 4.34 | 45% | 0.006 |
| Bhayshul Tuten | box | 7 | 61 | 4.84 | 54% | 0.045 |
| Bhayshul Tuten | box | 8+ | 13 | 3.15 | 31% | -0.004 |
| Bhayshul Tuten | box | ≤6 | 84 | 3.64 | 35% | -0.093 |
| Bhayshul Tuten | direction/gap | left end | 24 | 4.50 | 46% | -0.064 |
| Bhayshul Tuten | direction/gap | left guard | 19 | 3.32 | 32% | -0.118 |
| Bhayshul Tuten | direction/gap | left tackle | 16 | 4.62 | 50% | 0.163 |
| Bhayshul Tuten | direction/gap | middle | 31 | 3.77 | 32% | -0.086 |
| Bhayshul Tuten | direction/gap | right end | 19 | 3.95 | 47% | 0.003 |
| Bhayshul Tuten | direction/gap | right guard | 20 | 2.70 | 40% | -0.214 |
| Bhayshul Tuten | direction/gap | right tackle | 29 | 5.21 | 48% | 0.100 |
| Chris Rodriguez Jr. | formation | shotgun | 23 | 4.91 | 52% | 0.215 |
| Chris Rodriguez Jr. | formation | under center | 40 | 3.70 | 40% | -0.002 |
| Chris Rodriguez Jr. | box | 7 | 37 | 4.24 | 43% | 0.084 |
| Chris Rodriguez Jr. | box | 8+ | 7 | 5.86 | 71% | 0.464 |
| Chris Rodriguez Jr. | box | ≤6 | 19 | 3.32 | 37% | -0.080 |
| Chris Rodriguez Jr. | direction/gap | left end | 3 | 3.67 | 33% | -0.103 |
| Chris Rodriguez Jr. | direction/gap | left guard | 15 | 6.33 | 47% | 0.250 |
| Chris Rodriguez Jr. | direction/gap | left tackle | 6 | 3.33 | 50% | 0.187 |
| Chris Rodriguez Jr. | direction/gap | middle | 17 | 5.65 | 76% | 0.352 |
| Chris Rodriguez Jr. | direction/gap | right end | 2 | 4.00 | 50% | 0.124 |
| Chris Rodriguez Jr. | direction/gap | right guard | 11 | 2.64 | 27% | -0.104 |
| Chris Rodriguez Jr. | direction/gap | right tackle | 9 | 0.22 | 0% | -0.533 |
| Ameer Abdullah | formation | shotgun | 5 | 6.80 | 40% | -0.031 |
| Ameer Abdullah | formation | under center | 18 | 3.00 | 39% | -0.107 |
| Ameer Abdullah | box | 7 | 5 | 0.40 | 0% | -0.460 |
| Ameer Abdullah | box | 8+ | 5 | 0.60 | 0% | -0.430 |
| Ameer Abdullah | box | ≤6 | 13 | 6.38 | 69% | 0.182 |
| Ameer Abdullah | direction/gap | left guard | 1 | 5.00 | 100% | 0.265 |
| Ameer Abdullah | direction/gap | left tackle | 9 | 3.00 | 44% | -0.137 |
| Ameer Abdullah | direction/gap | middle | 4 | 6.00 | 25% | -0.171 |
| Ameer Abdullah | direction/gap | right end | 2 | -0.50 | 0% | -0.427 |
| Ameer Abdullah | direction/gap | right guard | 4 | 5.00 | 50% | 0.031 |
| Ameer Abdullah | direction/gap | right tackle | 3 | 4.33 | 33% | 0.099 |

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
| Ameer Abdullah | RB | 11 | NYG | 0% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Bhayshul Tuten | RB | 1 | CLE | 49% | 1 | 5% | 1-22-0 | -5.0 | 15 | 47% | 66-0 | 9.8 |
| Bhayshul Tuten | RB | 2 | DEN | 51% | 2 | 7% | 2-(-3)-0 | -4.0 | 13 | 54% | 65-1 | 14.2 |
| Bhayshul Tuten | RB | 3 | NE | 48% | 2 | 7% | 2-17-0 | -3.5 | 15 | 50% | 73-1 | 17.0 |
| Bhayshul Tuten | RB | 4 | CIN | 59% | 2 | 9% | 2-18-0 | -1.0 | 17 | 63% | 73-0 | 11.1 |
| Bhayshul Tuten | RB | 5 | PHI | 68% | 3 | 8% | 2-24-0 | -2.7 | 22 | 81% | 72-0 | 11.6 |
| Bhayshul Tuten | RB | 6 | HOU | 58% | 4 | 11% | 4-48-2 | -3.2 | 12 | 44% | 39-0 | 24.7 |
| Bhayshul Tuten | RB | 8 | IND | 50% | 2 | 12% | 2-55-1 | -3.0 | 16 | 48% | 104-1 | 29.9 |
| Bhayshul Tuten | RB | 9 | BAL | 36% | 0 | 0% | 0-0-0 | – | 12 | 40% | 29-1 | 8.9 |
| Bhayshul Tuten | RB | 10 | TEN | 70% | 4 | 12% | 3-25-0 | -1.8 | 26 | 72% | 88-1 | 20.3 |
| Bhayshul Tuten | RB | 11 | NYG | 43% | 3 | 7% | 3-20-0 | -2.0 | 10 | 56% | 33-0 | 8.3 |
| Brenton Strange | TE | 1 | CLE | 68% | 3 | 15% | 2-23-1 | 11.3 | 0 | 0% | 0-0 | 10.3 |
| Brenton Strange | TE | 2 | DEN | 83% | 2 | 7% | 2-17-0 | 8.5 | 0 | 0% | 0-0 | 3.7 |
| Brenton Strange | TE | 3 | NE | 77% | 5 | 19% | 3-32-0 | 6.4 | 0 | 0% | 0-0 | 6.2 |
| Brenton Strange | TE | 4 | CIN | 87% | 8 | 35% | 7-95-0 | 7.2 | 0 | 0% | 0-0 | 16.5 |
| Brenton Strange | TE | 5 | PHI | 81% | 8 | 22% | 7-68-0 | 7.1 | 0 | 0% | 0-0 | 13.8 |
| Brenton Strange | TE | 6 | HOU | 76% | 7 | 19% | 5-44-0 | 8.0 | 0 | 0% | 0-0 | 9.4 |
| Brenton Strange | TE | 8 | IND | 52% | 2 | 12% | 2-55-0 | 11.0 | 0 | 0% | 0-0 | 7.5 |
| Brenton Strange | TE | 9 | BAL | 79% | 2 | 8% | 2-22-0 | 10.0 | 0 | 0% | 0-0 | 4.2 |
| Brenton Strange | TE | 10 | TEN | 78% | 3 | 9% | 2-9-1 | 11.0 | 0 | 0% | 0-0 | 8.9 |
| Brenton Strange | TE | 11 | NYG | 82% | 3 | 7% | 3-16-0 | 3.7 | 0 | 0% | 0-0 | 4.6 |
| Brian Thomas Jr. | WR | 1 | CLE | 35% | 3 | 15% | 3-40-0 | 14.7 | 0 | 0% | 0-0 | 7.0 |
| Brian Thomas Jr. | WR | 2 | DEN | 54% | 8 | 29% | 3-40-0 | 10.2 | 0 | 0% | 0-0 | 7.0 |
| Brian Thomas Jr. | WR | 3 | NE | 37% | 1 | 4% | 1-8-0 | 4.0 | 0 | 0% | 0-0 | 1.8 |
| Brian Thomas Jr. | WR | 4 | CIN | 62% | 2 | 9% | 2-17-1 | 8.5 | 0 | 0% | 0-0 | 9.7 |
| Brian Thomas Jr. | WR | 5 | PHI | 51% | 3 | 8% | 0-0-0 | 12.7 | 0 | 0% | 0-0 | 0.0 |
| Brian Thomas Jr. | WR | 6 | HOU | 21% | 2 | 5% | 0-0-0 | 17.0 | 0 | 0% | 0-0 | 0.0 |
| Brian Thomas Jr. | WR | 8 | IND | 52% | 2 | 12% | 1-12-1 | 19.0 | 0 | 0% | 0-0 | 8.2 |
| Brian Thomas Jr. | WR | 10 | TEN | 48% | 4 | 12% | 3-29-0 | 7.2 | 0 | 0% | 0-0 | 5.9 |
| Brian Thomas Jr. | WR | 11 | NYG | 51% | 3 | 7% | 1-18-1 | 19.7 | 0 | 0% | 0-0 | 8.8 |
| Chris Rodriguez Jr. | RB | 1 | CLE | 40% | 0 | 0% | 0-0-0 | – | 6 | 19% | 23-0 | 2.3 |
| Chris Rodriguez Jr. | RB | 2 | DEN | 22% | 0 | 0% | 0-0-0 | – | 6 | 25% | 13-0 | 1.3 |
| Chris Rodriguez Jr. | RB | 3 | NE | 21% | 0 | 0% | 0-0-0 | – | 8 | 27% | 37-1 | 9.7 |
| Chris Rodriguez Jr. | RB | 4 | CIN | 25% | 0 | 0% | 0-0-0 | – | 6 | 22% | 35-1 | 9.5 |
| Chris Rodriguez Jr. | RB | 5 | PHI | 12% | 1 | 3% | 1-6-0 | 2.0 | 2 | 7% | 5-0 | 2.1 |
| Chris Rodriguez Jr. | RB | 6 | HOU | 30% | 1 | 3% | 0-0-0 | 2.0 | 11 | 41% | 55-0 | 5.5 |
| Chris Rodriguez Jr. | RB | 8 | IND | 22% | 1 | 6% | 1-17-0 | 3.0 | 6 | 18% | 41-1 | 12.8 |
| Chris Rodriguez Jr. | RB | 9 | BAL | 45% | 2 | 8% | 2-13-0 | 0.5 | 10 | 33% | 19-1 | 11.2 |
| Chris Rodriguez Jr. | RB | 10 | TEN | 14% | 0 | 0% | 0-0-0 | – | 4 | 11% | 5-0 | 0.5 |
| Chris Rodriguez Jr. | RB | 11 | NYG | 38% | 1 | 2% | 1-13-0 | 3.0 | 4 | 22% | 28-0 | 5.1 |
| Jakobi Meyers | WR | 1 | CLE | 65% | 2 | 10% | 2-40-1 | 14.5 | 1 | 3% | 2-0 | 12.2 |
| Jakobi Meyers | WR | 2 | DEN | 90% | 1 | 4% | 1-28-0 | 21.0 | 0 | 0% | 0-0 | 3.8 |
| Jakobi Meyers | WR | 3 | NE | 81% | 8 | 30% | 7-64-1 | 8.0 | 0 | 0% | 0-0 | 19.4 |
| Jakobi Meyers | WR | 4 | CIN | 82% | 4 | 17% | 3-33-0 | 8.8 | 0 | 0% | 0-0 | 6.3 |
| Jakobi Meyers | WR | 5 | PHI | 85% | 3 | 8% | 2-37-0 | 10.3 | 0 | 0% | 0-0 | 5.7 |
| Jakobi Meyers | WR | 6 | HOU | 75% | 10 | 27% | 5-83-0 | 11.7 | 0 | 0% | 0-0 | 13.3 |
| Jakobi Meyers | WR | 8 | IND | 54% | 3 | 19% | 2-24-0 | 10.0 | 0 | 0% | 0-0 | 4.4 |
| Jakobi Meyers | WR | 9 | BAL | 68% | 6 | 24% | 4-65-0 | 11.0 | 0 | 0% | 0-0 | 10.5 |
| Jakobi Meyers | WR | 10 | TEN | 81% | 6 | 19% | 3-34-0 | 15.5 | 1 | 3% | 0-0 | 6.4 |
| Jakobi Meyers | WR | 11 | NYG | 83% | 10 | 22% | 4-85-0 | 11.8 | 0 | 0% | 0-0 | 12.5 |
| Josh Cameron | WR | 1 | CLE | 33% | 2 | 10% | 2-20-1 | 9.0 | 0 | 0% | 0-0 | 10.0 |
| Josh Cameron | WR | 2 | DEN | 17% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Josh Cameron | WR | 3 | NE | 37% | 2 | 7% | 1-12-1 | 10.0 | 0 | 0% | 0-0 | 8.2 |
| Josh Cameron | WR | 4 | CIN | 36% | 2 | 9% | 2-42-0 | 3.5 | 0 | 0% | 0-0 | 6.2 |
| Josh Cameron | WR | 5 | PHI | 31% | 6 | 16% | 3-43-0 | 2.3 | 0 | 0% | 0-0 | 7.3 |
| Josh Cameron | WR | 6 | HOU | 51% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Josh Cameron | WR | 8 | IND | 52% | 1 | 6% | 0-0-0 | 28.0 | 0 | 0% | 0-0 | 0.0 |
| Josh Cameron | WR | 9 | BAL | 45% | 1 | 4% | 1-6-0 | 5.0 | 0 | 0% | 0-0 | 1.6 |
| Josh Cameron | WR | 10 | TEN | 33% | 3 | 9% | 3-67-1 | 17.0 | 0 | 0% | 0-0 | 15.7 |
| Josh Cameron | WR | 11 | NYG | 39% | 7 | 16% | 3-44-0 | 14.1 | 0 | 0% | 0-0 | 7.4 |
| LeQuint Allen Jr. | RB | 2 | DEN | 15% | 1 | 4% | 0-0-0 | 4.0 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 3 | NE | 18% | 2 | 7% | 2-9-0 | 2.0 | 0 | 0% | 0-0 | 2.9 |
| LeQuint Allen Jr. | RB | 4 | CIN | 15% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 5 | PHI | 18% | 2 | 5% | 0-0-0 | 2.5 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 6 | HOU | 11% | 0 | 0% | 0-0-0 | – | 1 | 4% | 1-0 | 0.1 |
| LeQuint Allen Jr. | RB | 8 | IND | 11% | 1 | 6% | 0-0-0 | 8.0 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 9 | BAL | 7% | 2 | 8% | 0-0-0 | -0.5 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 10 | TEN | 16% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 11 | NYG | 19% | 1 | 2% | 1-(-1)-0 | -1.0 | 0 | 0% | 0-0 | 0.9 |
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
| Parker Washington | WR | 11 | NYG | 82% | 17 | 38% | 8-103-0 | 15.5 | 0 | 0% | 0-0 | 18.3 |
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
| Trevor Lawrence | QB | 11 | NYG | 100% | 0 | 0% | 0-0-0 | – | 3 | 17% | 7-0 | 12.7 |

Game by game, 2026: gained (expected vs that defense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | CLE | 28 | 4.54 (4.41) | 57% (42%) | -0.03 (-0.03) | 24 | 0.65 (-0.01) | 10.65 (6.58) |
| 2 | DEN | 24 | 3.96 (4.35) | 46% (38%) | 0.07 (-0.02) | 31 | -0.10 (-0.04) | 6.52 (6.38) |
| 3 | NE | 28 | 4.61 (4.06) | 57% (40%) | 0.21 (-0.05) | 31 | 0.20 (0.09) | 6.50 (8.01) |
| 4 | CIN | 25 | 4.52 (4.24) | 40% (42%) | 0.06 (-0.02) | 28 | 0.28 (0.08) | 9.46 (7.42) |
| 5 | PHI | 24 | 3.21 (3.93) | 29% (43%) | -0.22 (0.03) | 44 | 0.23 (0.07) | 8.49 (6.76) |
| 6 | HOU | 24 | 3.96 (3.83) | 50% (41%) | 0.04 (-0.05) | 43 | 0.24 (0.01) | 7.46 (7.48) |
| 8 | IND | 31 | 5.65 (4.53) | 45% (46%) | 0.15 (-0.01) | 22 | 0.21 (0.05) | 12.82 (7.77) |
| 9 | BAL | 29 | 2.69 (3.79) | 41% (45%) | -0.12 (-0.00) | 26 | 0.19 (0.08) | 9.31 (7.58) |
| 10 | TEN | 34 | 2.97 (4.53) | 32% (44%) | -0.08 (0.01) | 37 | 0.48 (0.22) | 10.35 (8.34) |
| 11 | NYG | 16 | 4.81 (4.43) | 38% (42%) | 0.06 (-0.03) | 51 | -0.13 (0.05) | 6.27 (6.61) |
