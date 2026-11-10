# JAX Jacksonville Jaguars — Matchup Witch data, 2026 (current)

Source: nflverse (play-by-play, NGS participation, FTN charting, player stats, snap counts). Built 2026-11-10 14:53 UTC. Regular season only.
- 2026: weeks 1–9, 136 games, last game 2026-11-09; NGS participation NO (route, man/zone, coverage, pressure unavailable)

## 2026 DEFENSE — JAX Jacksonville Jaguars (8 games)

Flags, 2026 (leads to test, not verdicts; rank 1 = best D, among teams with enough plays; see README):

Weak (bottom ~15%):
- rush EPA, runs, right tackle: 0.353 (lg -0.054; 31/32; n=18)
- pass EPA/att, int left: +0.76 (lg +0.32; 30/32; n=19)
- pass EPA/att, deep right: 1.24 (lg +0.40; 25/28; n=13)

Strong (top ~15%):
- pass EPA/att, short middle: -0.43 (lg +0.06; 1/32; n=26)
- pass EPA/att, short left: -0.45 (lg +0.02; 1/32; n=78)
- rush EPA, ≤6 box: -0.281 (lg -0.082; 1/32; n=64)
- pass EPA/att, short right: -0.27 (lg +0.01; 2/32; n=70)
- run D, EPA/rush: -0.172 (lg -0.079; 3/32)
- PPR/g allowed, RB: 17.8 (lg 21.9; 3/32)
- pass D, EPA/dropback: -0.101 (lg 0.046; 3/32)
- run D, 10+ yd runs/game: 1.50 (lg 2.28; 4/32)
- PPR/g allowed, TE: 10.3 (lg 13.8; 5/32)

Fantasy points allowed (PPR, nflverse scoring incl. rushing, fumbles, 2-pt). Rank 1 = fewest allowed.

| pos | PPR total | PPR/game | rank |
|---|---|---|---|
| QB | 99.9 | 12.5 | 6 |
| RB | 142.6 | 17.8 | 3 |
| WR | 267.8 | 33.5 | 19 |
| TE | 82.1 | 10.3 | 5 |

Unit stats (rank 1 = best defense):

| stat | value | rank |
|---|---|---|
| EPA/dropback | -0.101 | 3 |
| YPA | 7.31 | 19 |
| Comp % | 66% | 25 |
| 20+ yd completions/game | 2.62 | 11 |
| Sack rate | 5% | 20 |
| Pressure rate (NGS) | – | – |
| Blitz rate (FTN: 1+ blitzer) | 31% | – |
| Man coverage rate (NGS) | – | – |
| EPA/rush (designed runs) | -0.172 | 3 |
| YPC | 3.69 | 9 |
| Rush success rate | 36% | 7 |
| Stuff rate (≤0 yds) | 19% | 10 |
| 10+ yd runs/game | 1.50 | 4 |
| 20+ yd runs/game | 0.25 | – |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing offense's adjusted rating from its other games; diff = allowed − expected; adjusted = league avg + diff; rank 1 = best defense; thin = games where that rating rests on under 100 plays; method in README):

| stat | allowed | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 3.69 | 3.82 | -0.13 | 3.96 | 13/32 | 8 | 0 |
| Run success rate | 36.0% | 38.6% | -2.6 | 37.8% | 9/32 | 8 | 0 |
| EPA/rush | -0.172 | -0.101 | -0.072 | -0.150 | 6/32 | 8 | 0 |
| EPA/dropback | -0.101 | 0.058 | -0.158 | -0.112 | 3/32 | 8 | 0 |
| YPA | 7.31 | 7.02 | +0.29 | 7.37 | 18/32 | 8 | 0 |
| Sack rate | 5.5% | 7.0% | -1.5 | 4.9% | 27/32 | 8 | 0 |

QB rushing allowed (runs + scrambles): 26 car, 106 yds, 1 TD; 13.2 yds/g (rank 10/32; lg 16.6); scramble rate 5% (lg 5%)

Passing allowed by throw (rank by EPA/att among teams with ≥8 att; share = opp. QBs' share of att here, usual = their share in other games):

| cell | att | comp | YPA | TD | INT | EPA | rank | share | usual |
|---|---|---|---|---|---|---|---|---|---|
| short left | 78 | 68% | 4.64 | 2 | 6 | -0.45 | 1/32 | 30% | 26% |
| short middle | 26 | 62% | 5.04 | 0 | 1 | -0.43 | 1/32 | 10% | 12% |
| short right | 70 | 74% | 4.74 | 2 | 3 | -0.27 | 2/32 | 27% | 31% |
| int left | 19 | 68% | 11.63 | 0 | 0 | 0.76 | 30/32 | 8% | 6% |
| int middle | 14 | 71% | 11.00 | 1 | 1 | 0.73 | 22/32 | 5% | 5% |
| int right | 28 | 57% | 8.82 | 1 | 0 | 0.47 | 22/32 | 11% | 8% |
| deep left | 9 | 22% | 7.22 | 0 | 0 | -0.25 | 6/29 | 3% | 4% |
| deep middle | 4 | 75% | 36.25 | 1 | 0 | 2.70 | – | 2% | 1% |
| deep right | 13 | 54% | 19.23 | 1 | 0 | 1.24 | 25/28 | 5% | 6% |

Targets allowed by receiver position:

| pos | tgt | catch | YPT | TD | PPR/tgt |
|---|---|---|---|---|---|
| RB | 48 | 83% | 5.44 | 0 | 1.38 |
| WR | 150 | 67% | 9.31 | 4 | 1.76 |
| TE | 51 | 63% | 4.90 | 4 | 1.59 |

Run defense by bucket (box count from FTN charting):

| type | bucket | rushes | YPC | success | EPA/rush |
|---|---|---|---|---|---|
| box | 7 | 71 | 4.21 | 34% | -0.075 |
| box | 8+ | 40 | 2.65 | 40% | -0.172 |
| box | ≤6 | 64 | 3.77 | 36% | -0.281 |
| direction/gap | ? | 4 | 0.00 | 0% | -2.739 |
| direction/gap | left end | 32 | 3.34 | 44% | -0.176 |
| direction/gap | left guard | 19 | 2.95 | 42% | -0.186 |
| direction/gap | left tackle | 15 | 5.33 | 33% | -0.183 |
| direction/gap | middle | 47 | 2.96 | 30% | -0.164 |
| direction/gap | right end | 23 | 4.04 | 39% | -0.056 |
| direction/gap | right guard | 17 | 3.06 | 29% | -0.275 |
| direction/gap | right tackle | 18 | 6.61 | 44% | 0.353 |
| offense formation | shotgun | 77 | 4.17 | 42% | -0.161 |
| offense formation | under center | 98 | 3.32 | 32% | -0.181 |

RB targets allowed by route type:

| route | tgt | catch | YPT | PPR/tgt |
|---|---|---|---|---|
| (route n/a) | 34 | 79% | 5.65 | 1.36 |
| screen | 14 | 93% | 4.93 | 1.42 |

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
| 1 | TE | CLE | Harold Fannin Jr. | 3 tgt, 2-21-0 | 4.1 | 6.5 |
| 2 | TE | DEN | Nate Adkins | 3 tgt, 3-32-1 (+1-6 rush) | 12.8 | 15.5 |
| 3 | TE | NE | Hunter Henry | 2 tgt, 1-5-0 | 1.5 | 1.5 |
| 4 | TE | CIN | Mike Gesicki | 5 tgt, 3-40-1 | 13.0 | 14.2 |
| 5 | TE | PHI | Dallas Goedert | 9 tgt, 6-38-0 | 9.8 | 9.8 |
| 6 | TE | HOU | Foster Moreau | 2 tgt, 2-7-2 | 14.7 | 23.4 |
| 8 | TE | IND | Tyler Warren | 10 tgt, 4-18-0 | 5.8 | 5.8 |
| 9 | TE | BAL | Mark Andrews | 2 tgt, 2-19-0 (+2-0 rush) | 3.9 | 5.4 |
| 1 | WR | CLE | Denzel Boston | 4 tgt, 2-59-1 | 13.9 | 26.3 |
| 2 | WR | DEN | Jaylen Waddle | 10 tgt, 8-138-0 | 21.8 | 32.6 |
| 3 | WR | NE | Mack Hollins | 9 tgt, 6-87-0 | 14.7 | 33.5 |
| 4 | WR | CIN | Tee Higgins | 16 tgt, 11-157-0 | 26.7 | 55.5 |
| 5 | WR | PHI | Darius Cooper | 3 tgt, 2-71-1 | 15.1 | 35.7 |
| 6 | WR | HOU | Jaylin Noel | 4 tgt, 4-107-1 | 20.7 | 44.6 |
| 8 | WR | IND | Keenan Allen | 7 tgt, 7-67-0 | 13.7 | 30.3 |
| 9 | WR | BAL | Zay Flowers | 6 tgt, 3-6-0 (+3-17 rush) | 5.3 | 9.3 |

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

Game by game, 2026: allowed (expected vs that offense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | CLE | 19 | 3.53 (3.62) | 42% (35%) | -0.12 (-0.24) | 30 | -0.23 (0.01) | 9.32 (7.26) |
| 2 | DEN | 25 | 4.28 (3.79) | 44% (40%) | -0.06 (-0.02) | 31 | 0.27 (0.01) | 9.29 (5.82) |
| 3 | NE | 23 | 2.78 (4.28) | 26% (39%) | -0.13 (-0.11) | 37 | -0.33 (0.24) | 7.90 (8.64) |
| 4 | CIN | 13 | 1.38 (4.30) | 23% (44%) | -0.31 (-0.06) | 58 | 0.13 (0.31) | 7.93 (7.85) |
| 5 | PHI | 17 | 1.18 (3.47) | 24% (35%) | -0.61 (-0.12) | 42 | -0.04 (-0.21) | 5.50 (5.75) |
| 6 | HOU | 24 | 4.54 (2.88) | 42% (32%) | 0.01 (-0.20) | 35 | 0.37 (0.13) | 9.18 (7.65) |
| 8 | IND | 21 | 4.67 (4.35) | 48% (47%) | -0.30 (0.08) | 37 | -0.59 (-0.21) | 5.07 (5.50) |
| 9 | BAL | 33 | 4.94 (3.97) | 33% (39%) | -0.09 (-0.12) | 21 | -0.75 (0.07) | 3.00 (7.66) |

## 2026 OFFENSE — JAX Jacksonville Jaguars

Usage concentrations (share well above league avg at his position):
- Trevor Lawrence (QB, 223 att): int left 12% (lg 7%); int middle 11% (lg 6%)
- Jakobi Meyers (WR, 37 tgt): int middle 27% (avg 8%)
- Parker Washington (WR, 55 tgt): int left 20% (avg 10%)
- Brenton Strange (TE, 37 tgt): int middle 22% (avg 7%)
- Brian Thomas Jr. (WR, 21 tgt): int right 24% (avg 10%)
- Josh Cameron (WR, 14 tgt): short middle 29% (avg 10%)
- Ameer Abdullah (RB, 23 car): runs left tackle 39% (avg 13%); vs 8+ box 22% (avg 7%)
- Chris Rodriguez Jr. (RB, 55 car): runs left guard 24% (avg 13%)

Team passing context:

| stat | value |
|---|---|
| Dropbacks | 249 |
| EPA/dropback | 0.269 |
| Sack rate | 5% |
| Pressure rate faced (NGS) | – |
| EPA/db clean | – |
| EPA/db under pressure | – |
| Blitz rate faced (FTN) | 31% |
| EPA/db vs blitz | 0.104 |
| EPA/db vs no blitz | 0.343 |
| Pass rate over expected | -4.6 pts |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing defense's adjusted rating from its other games; diff = gained − expected; adjusted = league avg + diff; rank 1 = best offense; thin = games where that rating rests on under 100 plays; method in README):

| stat | gained | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 4.17 | 4.12 | +0.06 | 4.14 | 13/32 | 8 | 0 |
| Run success rate | 43.2% | 40.1% | +3.1 | 43.5% | 11/32 | 8 | 0 |
| EPA/rush | 0.010 | -0.056 | +0.066 | -0.013 | 8/32 | 8 | 0 |
| EPA/dropback | 0.269 | 0.063 | +0.206 | 0.253 | 4/32 | 8 | 0 |
| YPA | 8.55 | 7.28 | +1.27 | 8.35 | 3/32 | 8 | 0 |
| Sack rate | 5.2% | 7.5% | -2.2 | 4.1% | 7/32 | 8 | 0 |

QB throw map (share of att, EPA/att in parentheses; ≥40 att):

| QB | att | short left | short middle | short right | int left | int middle | int right | deep left | deep middle | deep right |
|---|---|---|---|---|---|---|---|---|---|---|
| Trevor Lawrence | 223 | 26% (-0.10) | 9% (0.18) | 24% (0.36) | 12% (0.73) | 11% (1.13) | 8% (0.27) | 6% (0.90) | 1% (1.61) | 3% (1.41) |
| league | 8916 | 26% (0.02) | 12% (0.06) | 29% (0.01) | 7% (0.32) | 6% (0.60) | 8% (0.32) | 4% (0.33) | 2% (0.66) | 5% (0.40) |

Player usage, season totals (RZ opps = carries + targets inside the 10 / 5):

| player | pos | G | snap% avg | tgt | tgt share | air yds share | aDOT | rec-yds-TD | YAC/rec | MOF tgt% | car | car share | rush yds-TD | RZ10 opps | RZ5 opps | PPR | PPR/g |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Trevor Lawrence | QB | 8 | 96% | 0 | 0% | 0% | – | 0-0-0 | – | – | 21 | 9% | 79-0 | 0 | 0 | 147.2 | 18.4 |
| Bhayshul Tuten | RB | 8 | 52% | 16 | 8% | -3% | -3.1 | 15-181-3 | 15.0 | 6% | 122 | 53% | 521-4 | 9 | 6 | 127.2 | 15.9 |
| Parker Washington | WR | 8 | 74% | 55 | 26% | 36% | 12.3 | 29-493-5 | 5.9 | 13% | 2 | 1% | 13-0 | 4 | 0 | 109.6 | 13.7 |
| Jakobi Meyers | WR | 8 | 75% | 37 | 17% | 21% | 10.6 | 26-374-2 | 2.9 | 32% | 1 | 0% | 2-0 | 6 | 3 | 75.6 | 9.4 |
| Brenton Strange | TE | 8 | 75% | 37 | 17% | 16% | 8.0 | 30-356-1 | 4.6 | 30% | 0 | 0% | 0-0 | 2 | 0 | 71.6 | 9.0 |
| Chris Rodriguez Jr. | RB | 8 | 27% | 5 | 2% | 0% | 1.6 | 4-36-0 | 7.5 | 20% | 55 | 24% | 228-4 | 9 | 6 | 54.4 | 6.8 |
| Nate Boerkircher | TE | 7 | 49% | 12 | 6% | 6% | 8.6 | 9-144-2 | 5.9 | 17% | 0 | 0% | 0-0 | 3 | 2 | 35.4 | 5.1 |
| Brian Thomas Jr. | WR | 7 | 43% | 21 | 10% | 14% | 12.2 | 10-117-2 | 0.7 | 9% | 0 | 0% | 0-0 | 4 | 2 | 33.7 | 4.8 |
| Josh Cameron | WR | 8 | 38% | 14 | 7% | 5% | 6.6 | 9-123-2 | 8.0 | 29% | 0 | 0% | 0-0 | 2 | 1 | 33.3 | 4.2 |
| Ameer Abdullah | RB | 8 | 8% | 3 | 1% | -1% | -4.0 | 2-2-0 | 5.5 | 0% | 23 | 10% | 88-0 | 1 | 0 | 11.0 | 1.4 |
| Tanner Koziol | TE | 2 | 17% | 3 | 1% | 0% | 2.7 | 3-23-0 | 5.0 | 0% | 0 | 0% | 0-0 | 0 | 0 | 5.3 | 2.6 |
| LeQuint Allen Jr. | RB | 7 | 12% | 8 | 4% | 1% | 2.5 | 2-9-0 | 2.5 | 50% | 1 | 0% | 1-0 | 1 | 1 | 3.0 | 0.4 |
| Quintin Morris | TE | 6 | 18% | 2 | 1% | 0% | 2.5 | 1-7-0 | 4.0 | 0% | 0 | 0% | 0-0 | 0 | 0 | 1.7 | 0.3 |
| Quinn Ewers | QB | 1 | 12% | 0 | 0% | 0% | – | 0-0-0 | – | – | 0 | 0% | 0-0 | 0 | 0 | 0.3 | 0.3 |
| Nick Mullens | QB | 1 | 12% | 0 | 0% | 0% | – | 0-0-0 | – | – | 3 | 1% | -3-0 | 0 | 0 | -0.3 | -0.3 |

Target depth mix (air yards):

| player | behind LOS | 0-9 | 10-19 | 20+ |
|---|---|---|---|---|
| Jakobi Meyers | 8% | 27% | 54% | 11% |
| Parker Washington | 9% | 38% | 33% | 20% |
| Chris Rodriguez Jr. | 20% | 80% | 0% | 0% |
| Brenton Strange | 8% | 51% | 35% | 5% |
| Brian Thomas Jr. | 5% | 33% | 48% | 14% |
| LeQuint Allen Jr. | 12% | 88% | 0% | 0% |
| nan | 38% | 50% | 12% | 0% |
| Bhayshul Tuten | 81% | 19% | 0% | 0% |
| Josh Cameron | 21% | 50% | 21% | 7% |
| Nate Boerkircher | 0% | 75% | 8% | 17% |

RB rushing by bucket (≥8 carries):

| RB | type | bucket | car | YPC | success | EPA/rush |
|---|---|---|---|---|---|---|
| Bhayshul Tuten | formation | shotgun | 26 | 2.96 | 31% | -0.202 |
| Bhayshul Tuten | formation | under center | 96 | 4.62 | 45% | 0.026 |
| Bhayshul Tuten | box | 7 | 49 | 5.51 | 57% | 0.163 |
| Bhayshul Tuten | box | 8+ | 12 | 3.08 | 33% | 0.046 |
| Bhayshul Tuten | box | ≤6 | 61 | 3.51 | 31% | -0.184 |
| Bhayshul Tuten | direction/gap | left end | 22 | 4.36 | 45% | -0.126 |
| Bhayshul Tuten | direction/gap | left guard | 14 | 3.86 | 36% | 0.015 |
| Bhayshul Tuten | direction/gap | left tackle | 11 | 5.00 | 45% | 0.023 |
| Bhayshul Tuten | direction/gap | middle | 25 | 4.04 | 36% | -0.037 |
| Bhayshul Tuten | direction/gap | right end | 15 | 3.80 | 53% | 0.109 |
| Bhayshul Tuten | direction/gap | right guard | 15 | 2.80 | 27% | -0.264 |
| Bhayshul Tuten | direction/gap | right tackle | 20 | 5.80 | 50% | 0.141 |
| Chris Rodriguez Jr. | formation | shotgun | 21 | 5.14 | 48% | 0.242 |
| Chris Rodriguez Jr. | formation | under center | 34 | 3.53 | 35% | -0.089 |
| Chris Rodriguez Jr. | box | 7 | 32 | 4.50 | 41% | 0.075 |
| Chris Rodriguez Jr. | box | 8+ | 6 | 3.33 | 50% | 0.091 |
| Chris Rodriguez Jr. | box | ≤6 | 17 | 3.76 | 35% | -0.051 |
| Chris Rodriguez Jr. | direction/gap | left end | 3 | 3.67 | 0% | -0.225 |
| Chris Rodriguez Jr. | direction/gap | left guard | 13 | 5.23 | 38% | 0.087 |
| Chris Rodriguez Jr. | direction/gap | left tackle | 6 | 3.33 | 50% | 0.168 |
| Chris Rodriguez Jr. | direction/gap | middle | 15 | 6.13 | 73% | 0.463 |
| Chris Rodriguez Jr. | direction/gap | right end | 2 | 4.00 | 50% | 0.146 |
| Chris Rodriguez Jr. | direction/gap | right guard | 8 | 2.75 | 25% | -0.227 |
| Chris Rodriguez Jr. | direction/gap | right tackle | 8 | 0.88 | 0% | -0.601 |
| Ameer Abdullah | formation | shotgun | 5 | 6.80 | 60% | 0.060 |
| Ameer Abdullah | formation | under center | 18 | 3.00 | 39% | -0.096 |
| Ameer Abdullah | box | 7 | 5 | 0.40 | 0% | -0.547 |
| Ameer Abdullah | box | 8+ | 5 | 0.60 | 0% | -0.464 |
| Ameer Abdullah | box | ≤6 | 13 | 6.38 | 77% | 0.280 |
| Ameer Abdullah | direction/gap | left guard | 1 | 5.00 | 100% | 0.245 |
| Ameer Abdullah | direction/gap | left tackle | 9 | 3.00 | 44% | -0.124 |
| Ameer Abdullah | direction/gap | middle | 4 | 6.00 | 50% | -0.100 |
| Ameer Abdullah | direction/gap | right end | 2 | -0.50 | 0% | -0.344 |
| Ameer Abdullah | direction/gap | right guard | 4 | 5.00 | 50% | 0.030 |
| Ameer Abdullah | direction/gap | right tackle | 3 | 4.33 | 33% | 0.138 |

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
| Brenton Strange | TE | 1 | CLE | 68% | 3 | 15% | 2-23-1 | 11.3 | 0 | 0% | 0-0 | 10.3 |
| Brenton Strange | TE | 2 | DEN | 83% | 2 | 7% | 2-17-0 | 8.5 | 0 | 0% | 0-0 | 3.7 |
| Brenton Strange | TE | 3 | NE | 77% | 5 | 19% | 3-32-0 | 6.4 | 0 | 0% | 0-0 | 6.2 |
| Brenton Strange | TE | 4 | CIN | 87% | 8 | 35% | 7-95-0 | 7.2 | 0 | 0% | 0-0 | 16.5 |
| Brenton Strange | TE | 5 | PHI | 81% | 8 | 22% | 7-68-0 | 7.1 | 0 | 0% | 0-0 | 13.8 |
| Brenton Strange | TE | 6 | HOU | 76% | 7 | 19% | 5-44-0 | 8.0 | 0 | 0% | 0-0 | 9.4 |
| Brenton Strange | TE | 8 | IND | 52% | 2 | 12% | 2-55-0 | 11.0 | 0 | 0% | 0-0 | 7.5 |
| Brenton Strange | TE | 9 | BAL | 79% | 2 | 8% | 2-22-0 | 10.0 | 0 | 0% | 0-0 | 4.2 |
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
| Chris Rodriguez Jr. | RB | 9 | BAL | 45% | 2 | 8% | 2-13-0 | 0.5 | 10 | 33% | 19-1 | 11.2 |
| Jakobi Meyers | WR | 1 | CLE | 65% | 2 | 10% | 2-40-1 | 14.5 | 1 | 3% | 2-0 | 12.2 |
| Jakobi Meyers | WR | 2 | DEN | 90% | 1 | 4% | 1-28-0 | 21.0 | 0 | 0% | 0-0 | 3.8 |
| Jakobi Meyers | WR | 3 | NE | 81% | 8 | 30% | 7-64-1 | 8.0 | 0 | 0% | 0-0 | 19.4 |
| Jakobi Meyers | WR | 4 | CIN | 82% | 4 | 17% | 3-33-0 | 8.8 | 0 | 0% | 0-0 | 6.3 |
| Jakobi Meyers | WR | 5 | PHI | 85% | 3 | 8% | 2-37-0 | 10.3 | 0 | 0% | 0-0 | 5.7 |
| Jakobi Meyers | WR | 6 | HOU | 75% | 10 | 27% | 5-83-0 | 11.7 | 0 | 0% | 0-0 | 13.3 |
| Jakobi Meyers | WR | 8 | IND | 54% | 3 | 19% | 2-24-0 | 10.0 | 0 | 0% | 0-0 | 4.4 |
| Jakobi Meyers | WR | 9 | BAL | 68% | 6 | 24% | 4-65-0 | 11.0 | 0 | 0% | 0-0 | 10.5 |
| Josh Cameron | WR | 1 | CLE | 33% | 2 | 10% | 2-20-1 | 9.0 | 0 | 0% | 0-0 | 10.0 |
| Josh Cameron | WR | 2 | DEN | 17% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Josh Cameron | WR | 3 | NE | 37% | 2 | 7% | 1-12-1 | 10.0 | 0 | 0% | 0-0 | 8.2 |
| Josh Cameron | WR | 4 | CIN | 36% | 2 | 9% | 2-42-0 | 3.5 | 0 | 0% | 0-0 | 6.2 |
| Josh Cameron | WR | 5 | PHI | 31% | 6 | 16% | 3-43-0 | 2.3 | 0 | 0% | 0-0 | 7.3 |
| Josh Cameron | WR | 6 | HOU | 51% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Josh Cameron | WR | 8 | IND | 52% | 1 | 6% | 0-0-0 | 28.0 | 0 | 0% | 0-0 | 0.0 |
| Josh Cameron | WR | 9 | BAL | 45% | 1 | 4% | 1-6-0 | 5.0 | 0 | 0% | 0-0 | 1.6 |
| LeQuint Allen Jr. | RB | 2 | DEN | 15% | 1 | 4% | 0-0-0 | 4.0 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 3 | NE | 18% | 2 | 7% | 2-9-0 | 2.0 | 0 | 0% | 0-0 | 2.9 |
| LeQuint Allen Jr. | RB | 4 | CIN | 15% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 5 | PHI | 18% | 2 | 5% | 0-0-0 | 2.5 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 6 | HOU | 11% | 0 | 0% | 0-0-0 | – | 1 | 4% | 1-0 | 0.1 |
| LeQuint Allen Jr. | RB | 8 | IND | 11% | 1 | 6% | 0-0-0 | 8.0 | 0 | 0% | 0-0 | 0.0 |
| LeQuint Allen Jr. | RB | 9 | BAL | 7% | 2 | 8% | 0-0-0 | -0.5 | 0 | 0% | 0-0 | 0.0 |
| Nate Boerkircher | TE | 1 | CLE | 67% | 1 | 5% | 1-9-0 | 2.0 | 0 | 0% | 0-0 | 1.9 |
| Nate Boerkircher | TE | 3 | NE | 45% | 1 | 4% | 0-0-0 | 4.0 | 0 | 0% | 0-0 | 0.0 |
| Nate Boerkircher | TE | 4 | CIN | 34% | 2 | 9% | 1-15-0 | 4.5 | 0 | 0% | 0-0 | 2.5 |
| Nate Boerkircher | TE | 5 | PHI | 49% | 2 | 5% | 2-20-0 | 7.0 | 0 | 0% | 0-0 | 4.0 |
| Nate Boerkircher | TE | 6 | HOU | 55% | 2 | 5% | 2-8-1 | 2.5 | 0 | 0% | 0-0 | 8.8 |
| Nate Boerkircher | TE | 8 | IND | 48% | 1 | 6% | 1-31-1 | 25.0 | 0 | 0% | 0-0 | 10.1 |
| Nate Boerkircher | TE | 9 | BAL | 55% | 3 | 12% | 2-61-0 | 14.7 | 0 | 0% | 0-0 | 8.1 |
| Nick Mullens | QB | 1 | CLE | 12% | 0 | 0% | 0-0-0 | – | 3 | 9% | -3-0 | -0.3 |
| Parker Washington | WR | 1 | CLE | 61% | 6 | 30% | 5-83-1 | 17.0 | 0 | 0% | 0-0 | 19.3 |
| Parker Washington | WR | 2 | DEN | 81% | 12 | 43% | 7-98-0 | 14.8 | 0 | 0% | 0-0 | 16.8 |
| Parker Washington | WR | 3 | NE | 81% | 5 | 19% | 3-40-1 | 10.0 | 0 | 0% | 0-0 | 13.0 |
| Parker Washington | WR | 4 | CIN | 80% | 3 | 13% | 1-7-0 | 12.7 | 1 | 4% | 3-0 | 2.0 |
| Parker Washington | WR | 5 | PHI | 82% | 9 | 24% | 6-124-2 | 8.8 | 0 | 0% | 0-0 | 30.4 |
| Parker Washington | WR | 6 | HOU | 73% | 11 | 30% | 4-64-0 | 13.9 | 0 | 0% | 0-0 | 10.4 |
| Parker Washington | WR | 8 | IND | 67% | 2 | 12% | 1-16-0 | 9.5 | 1 | 3% | 10-0 | 3.6 |
| Parker Washington | WR | 9 | BAL | 68% | 7 | 28% | 2-61-1 | 8.7 | 0 | 0% | 0-0 | 14.1 |
| Quinn Ewers | QB | 8 | IND | 19% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.3 |
| Quintin Morris | TE | 1 | CLE | 42% | 1 | 5% | 0-0-0 | 2.0 | 0 | 0% | 0-0 | 0.0 |
| Quintin Morris | TE | 2 | DEN | 22% | 1 | 4% | 1-7-0 | 3.0 | 0 | 0% | 0-0 | 1.7 |
| Quintin Morris | TE | 4 | CIN | 2% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Quintin Morris | TE | 5 | PHI | 3% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Quintin Morris | TE | 8 | IND | 20% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Quintin Morris | TE | 9 | BAL | 11% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Tanner Koziol | TE | 8 | IND | 35% | 1 | 6% | 1-8-0 | 1.0 | 0 | 0% | 0-0 | 1.8 |
| Tanner Koziol | TE | 9 | BAL | 21% | 2 | 8% | 2-15-0 | 3.5 | 0 | 0% | 0-0 | 3.5 |
| Trevor Lawrence | QB | 1 | CLE | 88% | 0 | 0% | 0-0-0 | – | 2 | 6% | 3-0 | 26.1 |
| Trevor Lawrence | QB | 2 | DEN | 100% | 0 | 0% | 0-0-0 | – | 2 | 8% | 6-0 | 6.2 |
| Trevor Lawrence | QB | 3 | NE | 95% | 0 | 0% | 0-0-0 | – | 4 | 13% | 25-0 | 19.8 |
| Trevor Lawrence | QB | 4 | CIN | 100% | 0 | 0% | 0-0-0 | – | 3 | 11% | 0-0 | 13.1 |
| Trevor Lawrence | QB | 5 | PHI | 100% | 0 | 0% | 0-0-0 | – | 3 | 11% | 25-0 | 21.7 |
| Trevor Lawrence | QB | 6 | HOU | 100% | 0 | 0% | 0-0-0 | – | 3 | 11% | 11-0 | 27.3 |
| Trevor Lawrence | QB | 8 | IND | 81% | 0 | 0% | 0-0-0 | – | 3 | 9% | 10-0 | 19.4 |
| Trevor Lawrence | QB | 9 | BAL | 100% | 0 | 0% | 0-0-0 | – | 1 | 3% | -1-0 | 13.6 |

Game by game, 2026: gained (expected vs that defense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | CLE | 28 | 4.54 (4.38) | 54% (42%) | -0.01 (-0.06) | 24 | 0.79 (-0.01) | 10.65 (6.71) |
| 2 | DEN | 24 | 3.96 (4.06) | 46% (33%) | 0.06 (-0.06) | 31 | -0.13 (-0.03) | 6.52 (6.50) |
| 3 | NE | 28 | 4.61 (3.79) | 54% (36%) | 0.24 (-0.14) | 31 | 0.23 (0.10) | 6.50 (7.75) |
| 4 | CIN | 25 | 4.52 (4.26) | 36% (36%) | 0.03 (-0.07) | 28 | 0.33 (0.07) | 9.46 (7.31) |
| 5 | PHI | 24 | 3.21 (4.08) | 29% (45%) | -0.29 (0.05) | 44 | 0.25 (0.12) | 8.49 (7.03) |
| 6 | HOU | 24 | 3.96 (4.05) | 50% (42%) | 0.01 (-0.08) | 43 | 0.27 (0.04) | 7.46 (7.62) |
| 8 | IND | 31 | 5.65 (4.63) | 39% (46%) | 0.17 (-0.01) | 22 | 0.25 (0.11) | 12.82 (7.98) |
| 9 | BAL | 29 | 2.69 (3.63) | 38% (41%) | -0.17 (-0.07) | 26 | 0.30 (0.08) | 9.31 (7.48) |
