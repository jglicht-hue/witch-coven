# CIN Cincinnati Bengals — Matchup Witch data, 2026 (current)

Source: nflverse (play-by-play, NGS participation, FTN charting, player stats, snap counts). Built 2026-10-27 17:19 UTC. Regular season only.
- 2026: weeks 1–7, 107 games, last game 2026-10-26; NGS participation NO (route, man/zone, coverage, pressure unavailable)

## 2026 DEFENSE — CIN Cincinnati Bengals (6 games)

Flags, 2026 (leads to test, not verdicts; rank 1 = best D, among teams with enough plays; see README):

Weak (bottom ~15%):
- pass EPA/att, short left: +0.39 (lg +0.05; 32/32; n=38)
- QB rush yds/g allowed, all QBs: 26.7 (lg 17.4; 31/32; n=20)
- rush EPA, runs, middle: 0.022 (lg -0.100; 29/32; n=31)

Strong (top ~15%):
- run D, stuff rate: 26% (lg 18%; 1/32)
- pass D, sack rate: 9% (lg 6%; 2/32)
- run D, success rate: 34% (lg 41%; 3/32)
- PPR/g allowed, RB: 17.9 (lg 22.0; 3/32)
- pass EPA/att, int right: -0.20 (lg +0.35; 3/31; n=12)
- rush EPA, 8+ box: -0.523 (lg -0.061; 3/24; n=13)
- rush EPA, runs, left tackle: -0.450 (lg -0.030; 3/32; n=11)

Fantasy points allowed (PPR, nflverse scoring incl. rushing, fumbles, 2-pt). Rank 1 = fewest allowed.

| pos | PPR total | PPR/game | rank |
|---|---|---|---|
| QB | 98.4 | 16.4 | 15 |
| RB | 107.2 | 17.9 | 3 |
| WR | 187.4 | 31.2 | 16 |
| TE | 94.0 | 15.7 | 22 |

Unit stats (rank 1 = best defense):

| stat | value | rank |
|---|---|---|
| EPA/dropback | -0.004 | 8 |
| YPA | 7.62 | 24 |
| Comp % | 64% | 13 |
| 20+ yd completions/game | 3.17 | 19 |
| Sack rate | 9% | 2 |
| Pressure rate (NGS) | – | – |
| Blitz rate (FTN: 1+ blitzer) | 17% | – |
| Man coverage rate (NGS) | – | – |
| EPA/rush (designed runs) | -0.108 | 11 |
| YPC | 4.20 | 23 |
| Rush success rate | 34% | 3 |
| Stuff rate (≤0 yds) | 26% | 1 |
| 10+ yd runs/game | 2.33 | 18 |
| 20+ yd runs/game | 1.00 | – |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing offense's adjusted rating from its other games; diff = allowed − expected; adjusted = league avg + diff; rank 1 = best defense; thin = games where that rating rests on under 100 plays; method in README):

| stat | allowed | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 4.20 | 4.19 | +0.01 | 4.08 | 16/32 | 6 | 0 |
| Run success rate | 33.8% | 40.8% | -7.0 | 33.7% | 4/32 | 6 | 0 |
| EPA/rush | -0.108 | -0.028 | -0.080 | -0.157 | 6/32 | 6 | 0 |
| EPA/dropback | -0.004 | 0.077 | -0.081 | -0.018 | 10/32 | 6 | 0 |
| YPA | 7.62 | 7.25 | +0.36 | 7.40 | 20/32 | 6 | 0 |
| Sack rate | 8.9% | 6.8% | +2.1 | 8.1% | 3/32 | 6 | 0 |

QB rushing allowed (runs + scrambles): 20 car, 160 yds, 2 TD; 26.7 yds/g (rank 31/32; lg 17.4); scramble rate 6% (lg 5%)

Passing allowed by throw (rank by EPA/att among teams with ≥8 att; share = opp. QBs' share of att here, usual = their share in other games):

| cell | att | comp | YPA | TD | INT | EPA | rank | share | usual |
|---|---|---|---|---|---|---|---|---|---|
| short left | 38 | 82% | 7.34 | 1 | 1 | 0.39 | 32/32 | 19% | 24% |
| short middle | 24 | 62% | 7.29 | 1 | 0 | 0.14 | 21/32 | 12% | 12% |
| short right | 64 | 81% | 8.02 | 2 | 2 | 0.15 | 27/32 | 32% | 29% |
| int left | 13 | 62% | 8.46 | 0 | 0 | 0.13 | 12/31 | 7% | 6% |
| int middle | 23 | 65% | 11.65 | 0 | 1 | 0.61 | 17/32 | 12% | 8% |
| int right | 12 | 17% | 3.33 | 0 | 0 | -0.20 | 3/31 | 6% | 8% |
| deep left | 10 | 30% | 9.00 | 1 | 0 | 0.10 | 10/23 | 5% | 5% |
| deep middle | 3 | 33% | 8.33 | 0 | 0 | 0.30 | – | 2% | 3% |
| deep right | 11 | 9% | 2.09 | 1 | 0 | -0.33 | 5/24 | 6% | 6% |

Targets allowed by receiver position:

| pos | tgt | catch | YPT | TD | PPR/tgt |
|---|---|---|---|---|---|
| RB | 28 | 86% | 6.75 | 0 | 1.53 |
| WR | 110 | 57% | 7.50 | 6 | 1.65 |
| TE | 55 | 75% | 9.25 | 0 | 1.67 |

Run defense by bucket (box count from FTN charting):

| type | bucket | rushes | YPC | success | EPA/rush |
|---|---|---|---|---|---|
| box | 7 | 48 | 4.33 | 33% | -0.111 |
| box | 8+ | 13 | 1.92 | 31% | -0.523 |
| box | ≤6 | 69 | 4.54 | 35% | -0.027 |
| direction/gap | ? | 1 | 0.00 | 0% | -0.651 |
| direction/gap | left end | 17 | 5.47 | 35% | 0.131 |
| direction/gap | left guard | 25 | 5.20 | 36% | -0.109 |
| direction/gap | left tackle | 11 | 1.64 | 18% | -0.450 |
| direction/gap | middle | 31 | 4.00 | 39% | 0.022 |
| direction/gap | right end | 12 | 4.83 | 33% | -0.132 |
| direction/gap | right guard | 16 | 3.19 | 25% | -0.287 |
| direction/gap | right tackle | 17 | 4.24 | 41% | -0.143 |
| offense formation | shotgun | 41 | 4.15 | 27% | -0.097 |
| offense formation | under center | 89 | 4.22 | 37% | -0.113 |

RB targets allowed by route type:

| route | tgt | catch | YPT | PPR/tgt |
|---|---|---|---|---|
| (route n/a) | 22 | 82% | 7.64 | 1.58 |
| screen | 6 | 100% | 3.50 | 1.35 |

Week by week: top scorer at each position vs this defense (RB line = car-yds-TD rush, tgt, rec-yds-TD):

| wk | pos | opp | top player | line | PPR | pos total PPR |
|---|---|---|---|---|---|---|
| 1 | RB | TB | Bucky Irving | 8-45-1 rush, 7 tgt 7-48-0 rec | 20.3 | 23.1 |
| 2 | RB | HOU | Woody Marks | 8-8-0 rush, 6 tgt 5-27-0 rec | 8.5 | 12.9 |
| 3 | RB | PIT | Jaylen Warren | 17-127-0 rush, 4 tgt 3-49-0 rec | 20.6 | 20.6 |
| 4 | RB | JAX | Bhayshul Tuten | 17-73-0 rush, 2 tgt 2-18-0 rec | 11.1 | 20.6 |
| 5 | RB | MIA | Ollie Gordon II | 18-88-1 rush, 0 tgt 0-0-0 rec | 14.8 | 15.9 |
| 7 | RB | BAL | Justice Hill | 3-7-0 rush, 4 tgt 3-26-0 rec | 6.3 | 14.1 |
| 1 | TE | TB | Cade Otton | 5 tgt, 3-26-0 | 5.6 | 5.6 |
| 2 | TE | HOU | Dalton Schultz | 14 tgt, 12-140-0 | 26.0 | 31.4 |
| 3 | TE | PIT | Darnell Washington | 4 tgt, 3-67-0 | 9.7 | 16.0 |
| 4 | TE | JAX | Brenton Strange | 8 tgt, 7-95-0 | 16.5 | 19.0 |
| 5 | TE | MIA | Greg Dulcich | 5 tgt, 4-37-0 | 9.7 | 11.2 |
| 7 | TE | BAL | Josh Cuevas | 3 tgt, 2-35-0 | 5.5 | 10.8 |
| 1 | WR | TB | Emeka Egbuka | 6 tgt, 5-63-0 | 11.3 | 25.8 |
| 2 | WR | HOU | Kayshon Boutte | 5 tgt, 3-37-0 | 6.7 | 24.1 |
| 3 | WR | PIT | Roman Wilson | 6 tgt, 3-60-1 | 15.0 | 42.4 |
| 4 | WR | JAX | Brian Thomas Jr. | 2 tgt, 2-17-1 | 9.7 | 24.2 |
| 5 | WR | MIA | Malik Washington | 8 tgt, 6-43-0 (+1-18 rush) | 12.1 | 29.9 |
| 7 | WR | BAL | Zay Flowers | 11 tgt, 8-137-1 | 27.7 | 41.0 |

Week by week: QBs vs this defense (main QB = most attempts + sacks + carries; rush = car-yds-TD; pts = nflverse fantasy points: 4-pt pass TD, −2 INT, −2 fumble lost):

| wk | opp | QB | cmp/att | pass yds | pass TD | INT | sk | rush | FL | pts | other QBs | all-QB pts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | TB | Baker Mayfield | 23/28 | 216 | 0 | 0 | 4 | 5-30-1 | 3 | 11.6 | – | 11.6 |
| 2 | HOU | C.J. Stroud | 30/55 | 353 | 0 | 0 | 4 | 3-29-0 | 0 | 17.0 | – | 17.0 |
| 3 | PIT | Aaron Rodgers | 19/34 | 292 | 3 | 1 | 2 | 3-10-0 | 0 | 22.7 | – | 22.7 |
| 4 | JAX | Trevor Lawrence | 18/23 | 227 | 1 | 0 | 4 | 3-0-0 | 0 | 13.1 | – | 13.1 |
| 5 | MIA | Malik Willis | 15/27 | 137 | 1 | 2 | 3 | 8-74-1 | 1 | 18.9 | – | 18.9 |
| 7 | BAL | Tyler Huntley | 23/34 | 298 | 1 | 1 | 4 | 3-12-0 | 0 | 15.1 | – | 15.1 |

Game by game, 2026: allowed (expected vs that offense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | TB | 15 | 3.93 (4.60) | 40% (45%) | 0.07 (0.02) | 36 | -0.29 (-0.09) | 7.71 (5.65) |
| 2 | HOU | 15 | 2.07 (3.49) | 7% (37%) | -0.80 (-0.09) | 61 | -0.11 (0.13) | 6.54 (7.64) |
| 3 | PIT | 20 | 6.40 (4.58) | 45% (42%) | 0.13 (0.05) | 36 | 0.24 (-0.15) | 8.85 (5.96) |
| 4 | JAX | 25 | 4.52 (4.01) | 36% (48%) | 0.03 (-0.02) | 28 | 0.33 (0.29) | 9.46 (7.95) |
| 5 | MIA | 30 | 4.80 (3.97) | 47% (34%) | 0.10 (-0.07) | 34 | -0.15 (0.06) | 5.07 (7.78) |
| 7 | BAL | 25 | 2.84 (4.48) | 20% (41%) | -0.39 (-0.03) | 40 | 0.09 (0.21) | 8.76 (8.30) |

## 2026 OFFENSE — CIN Cincinnati Bengals

Usage concentrations (share well above league avg at his position):
- Mike Gesicki (TE, 18 tgt): short left 39% (avg 25%); int right 17% (avg 6%)
- Tee Higgins (WR, 50 tgt): int middle 20% (avg 9%)
- Dohnte Meyers (WR, 20 tgt): short middle 20% (avg 9%)
- Samaje Perine (RB, 31 car): runs middle 48% (avg 29%); runs right guard 26% (avg 14%)

Team passing context:

| stat | value |
|---|---|
| Dropbacks | 236 |
| EPA/dropback | 0.207 |
| Sack rate | 4% |
| Pressure rate faced (NGS) | – |
| EPA/db clean | – |
| EPA/db under pressure | – |
| Blitz rate faced (FTN) | 27% |
| EPA/db vs blitz | 0.040 |
| EPA/db vs no blitz | 0.268 |
| Pass rate over expected | 6.7 pts |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing defense's adjusted rating from its other games; diff = gained − expected; adjusted = league avg + diff; rank 1 = best offense; thin = games where that rating rests on under 100 plays; method in README):

| stat | gained | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 3.63 | 3.72 | -0.08 | 3.99 | 18/32 | 6 | 0 |
| Run success rate | 42.3% | 38.9% | +3.3 | 44.0% | 10/32 | 6 | 0 |
| EPA/rush | -0.080 | -0.111 | +0.031 | -0.046 | 14/32 | 6 | 0 |
| EPA/dropback | 0.207 | 0.057 | +0.151 | 0.214 | 6/32 | 6 | 0 |
| YPA | 7.55 | 7.66 | -0.12 | 6.93 | 18/32 | 6 | 0 |
| Sack rate | 4.2% | 5.7% | -1.5 | 4.5% | 12/32 | 6 | 0 |

QB throw map (share of att, EPA/att in parentheses; ≥40 att):

| QB | att | short left | short middle | short right | int left | int middle | int right | deep left | deep middle | deep right |
|---|---|---|---|---|---|---|---|---|---|---|
| Joe Burrow | 219 | 24% (0.06) | 15% (-0.38) | 31% (-0.05) | 6% (0.68) | 7% (1.29) | 9% (0.86) | 0% (3.13) | 2% (3.06) | 6% (1.04) |
| league | 7106 | 26% (0.05) | 12% (0.06) | 30% (0.02) | 7% (0.30) | 7% (0.59) | 8% (0.35) | 4% (0.32) | 2% (0.76) | 5% (0.37) |

Player usage, season totals (RZ opps = carries + targets inside the 10 / 5):

| player | pos | G | snap% avg | tgt | tgt share | air yds share | aDOT | rec-yds-TD | YAC/rec | MOF tgt% | car | car share | rush yds-TD | RZ10 opps | RZ5 opps | PPR | PPR/g |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Joe Burrow | QB | 6 | 99% | 0 | 0% | 0% | – | 0-0-0 | – | – | 17 | 13% | 60-1 | 1 | 1 | 130.1 | 21.7 |
| Tee Higgins | WR | 6 | 79% | 50 | 23% | 44% | 14.2 | 33-571-2 | 4.0 | 28% | 0 | 0% | 0-0 | 0 | 0 | 102.1 | 17.0 |
| Ja'Marr Chase | WR | 6 | 80% | 45 | 21% | 26% | 9.3 | 32-351-5 | 3.2 | 22% | 0 | 0% | 0-0 | 4 | 3 | 97.1 | 16.2 |
| Chase Brown | RB | 6 | 71% | 33 | 15% | -2% | -0.8 | 28-143-0 | 5.4 | 18% | 82 | 61% | 285-1 | 9 | 4 | 74.8 | 12.5 |
| Mike Gesicki | TE | 5 | 44% | 18 | 8% | 11% | 10.2 | 13-165-5 | 2.2 | 17% | 0 | 0% | 0-0 | 4 | 3 | 59.5 | 11.9 |
| Samaje Perine | RB | 6 | 35% | 10 | 5% | 1% | 1.3 | 7-61-1 | 7.4 | 50% | 31 | 23% | 126-1 | 4 | 1 | 37.7 | 6.3 |
| Dohnte Meyers | WR | 6 | 41% | 20 | 9% | 6% | 4.9 | 13-141-0 | 5.5 | 20% | 1 | 1% | 10-0 | 1 | 1 | 28.1 | 4.7 |
| Drew Sample | TE | 4 | 52% | 8 | 4% | 0% | 0.9 | 7-48-1 | 6.7 | 25% | 0 | 0% | 0-0 | 0 | 0 | 17.8 | 4.5 |
| Tanner Hudson | TE | 4 | 26% | 7 | 3% | 1% | 3.4 | 7-33-1 | 1.3 | 14% | 0 | 0% | 0-0 | 2 | 1 | 16.3 | 4.1 |
| Erick All | TE | 3 | 32% | 9 | 4% | 1% | 1.8 | 8-56-0 | 4.9 | 22% | 0 | 0% | 0-0 | 0 | 0 | 13.6 | 4.5 |
| Mitchell Tinsley | WR | 2 | 36% | 8 | 4% | 6% | 12.9 | 4-56-0 | 1.8 | 12% | 0 | 0% | 0-0 | 2 | 0 | 9.6 | 4.8 |
| Andrei Iosivas | WR | 2 | 57% | 4 | 2% | 1% | 5.2 | 3-19-0 | 0.7 | 25% | 0 | 0% | 0-0 | 1 | 1 | 4.9 | 2.5 |
| Colbie Young | WR | 2 | 12% | 2 | 1% | 0% | 3.5 | 2-9-0 | 1.0 | 50% | 0 | 0% | 0-0 | 0 | 0 | 2.9 | 1.5 |
| Tahj Brooks | RB | 4 | 2% | 0 | 0% | 0% | – | 0-0-0 | – | – | 3 | 2% | 6-0 | 0 | 0 | 0.6 | 0.2 |

Target depth mix (air yards):

| player | behind LOS | 0-9 | 10-19 | 20+ |
|---|---|---|---|---|
| Samaje Perine | 30% | 70% | 0% | 0% |
| Tanner Hudson | 0% | 100% | 0% | 0% |
| Mike Gesicki | 0% | 56% | 33% | 11% |
| Drew Sample | 38% | 62% | 0% | 0% |
| Tee Higgins | 0% | 34% | 50% | 16% |
| Ja'Marr Chase | 13% | 53% | 24% | 9% |
| Chase Brown | 61% | 39% | 0% | 0% |
| Mitchell Tinsley | 12% | 38% | 12% | 38% |
| Erick All | 44% | 56% | 0% | 0% |
| Dohnte Meyers | 35% | 40% | 20% | 5% |

RB rushing by bucket (≥8 carries):

| RB | type | bucket | car | YPC | success | EPA/rush |
|---|---|---|---|---|---|---|
| Chase Brown | formation | shotgun | 31 | 3.71 | 45% | -0.017 |
| Chase Brown | formation | under center | 51 | 3.33 | 33% | -0.180 |
| Chase Brown | box | 7 | 34 | 3.41 | 35% | -0.077 |
| Chase Brown | box | 8+ | 13 | 1.77 | 23% | -0.504 |
| Chase Brown | box | ≤6 | 35 | 4.17 | 46% | -0.016 |
| Chase Brown | direction/gap | left end | 4 | 2.50 | 25% | -0.597 |
| Chase Brown | direction/gap | left guard | 17 | 3.82 | 29% | -0.115 |
| Chase Brown | direction/gap | left tackle | 10 | 2.40 | 50% | -0.111 |
| Chase Brown | direction/gap | middle | 27 | 3.78 | 41% | -0.007 |
| Chase Brown | direction/gap | right end | 8 | 3.38 | 50% | -0.138 |
| Chase Brown | direction/gap | right guard | 11 | 4.36 | 36% | -0.044 |
| Chase Brown | direction/gap | right tackle | 5 | 1.80 | 20% | -0.496 |
| Samaje Perine | formation | shotgun | 27 | 4.11 | 41% | -0.120 |
| Samaje Perine | formation | under center | 4 | 3.75 | 75% | 0.256 |
| Samaje Perine | box | 7 | 12 | 3.00 | 42% | -0.232 |
| Samaje Perine | box | ≤6 | 19 | 4.74 | 47% | 0.029 |
| Samaje Perine | direction/gap | left guard | 4 | 3.75 | 75% | 0.362 |
| Samaje Perine | direction/gap | left tackle | 4 | 7.00 | 50% | -0.164 |
| Samaje Perine | direction/gap | middle | 15 | 3.73 | 40% | -0.058 |
| Samaje Perine | direction/gap | right guard | 8 | 3.38 | 38% | -0.268 |

Week by week usage:

| player | pos | wk | opp | snap% | tgt | tgt share | rec-yds-TD | aDOT | car | car share | rush yds-TD | PPR |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Andrei Iosivas | WR | 1 | TB | 61% | 3 | 9% | 2-12-0 | 5.0 | 0 | 0% | 0-0 | 3.2 |
| Andrei Iosivas | WR | 2 | HOU | 53% | 1 | 3% | 1-7-0 | 6.0 | 0 | 0% | 0-0 | 1.7 |
| Chase Brown | RB | 1 | TB | 72% | 6 | 18% | 5-22-0 | -2.0 | 16 | 59% | 56-1 | 18.8 |
| Chase Brown | RB | 2 | HOU | 70% | 5 | 16% | 3-2-0 | -3.0 | 20 | 87% | 80-0 | 11.2 |
| Chase Brown | RB | 3 | PIT | 70% | 2 | 5% | 2-8-0 | -0.5 | 13 | 72% | 61-0 | 8.9 |
| Chase Brown | RB | 4 | JAX | 79% | 11 | 21% | 11-71-0 | 0.7 | 9 | 60% | 10-0 | 19.1 |
| Chase Brown | RB | 5 | MIA | 60% | 4 | 13% | 3-21-0 | -1.0 | 13 | 42% | 39-0 | 7.0 |
| Chase Brown | RB | 7 | BAL | 75% | 5 | 18% | 4-19-0 | -0.4 | 11 | 55% | 39-0 | 9.8 |
| Colbie Young | WR | 2 | HOU | 17% | 1 | 3% | 1-7-0 | 6.0 | 0 | 0% | 0-0 | 1.7 |
| Colbie Young | WR | 3 | PIT | 2% | 1 | 3% | 1-2-0 | 1.0 | 0 | 0% | 0-0 | 1.2 |
| Dohnte Meyers | WR | 1 | TB | 16% | 1 | 3% | 1-18-0 | 2.0 | 1 | 4% | 10-0 | 3.8 |
| Dohnte Meyers | WR | 2 | HOU | 18% | 1 | 3% | 0-0-0 | -4.0 | 0 | 0% | 0-0 | 0.0 |
| Dohnte Meyers | WR | 3 | PIT | 56% | 5 | 14% | 3-29-0 | 3.6 | 0 | 0% | 0-0 | 5.9 |
| Dohnte Meyers | WR | 4 | JAX | 89% | 9 | 17% | 7-82-0 | 7.6 | 0 | 0% | 0-0 | 15.2 |
| Dohnte Meyers | WR | 5 | MIA | 29% | 2 | 6% | 2-12-0 | 4.5 | 0 | 0% | 0-0 | 3.2 |
| Dohnte Meyers | WR | 7 | BAL | 38% | 2 | 7% | 0-0-0 | 2.5 | 0 | 0% | 0-0 | 0.0 |
| Drew Sample | TE | 1 | TB | 66% | 3 | 9% | 3-19-0 | 0.0 | 0 | 0% | 0-0 | 4.9 |
| Drew Sample | TE | 3 | PIT | 51% | 2 | 5% | 1-0-0 | 1.5 | 0 | 0% | 0-0 | 1.0 |
| Drew Sample | TE | 5 | MIA | 52% | 1 | 3% | 1-5-0 | 3.0 | 0 | 0% | 0-0 | 1.5 |
| Drew Sample | TE | 7 | BAL | 55% | 2 | 7% | 2-24-1 | 0.5 | 0 | 0% | 0-0 | 10.4 |
| Erick All | TE | 2 | HOU | 42% | 3 | 10% | 2-5-0 | -0.3 | 0 | 0% | 0-0 | 2.5 |
| Erick All | TE | 5 | MIA | 52% | 3 | 10% | 3-25-0 | 3.7 | 0 | 0% | 0-0 | 5.5 |
| Erick All | TE | 7 | BAL | 28% | 3 | 11% | 3-26-0 | 2.0 | 0 | 0% | 0-0 | 5.6 |
| Ja'Marr Chase | WR | 1 | TB | 94% | 4 | 12% | 2-12-0 | 8.5 | 0 | 0% | 0-0 | 3.2 |
| Ja'Marr Chase | WR | 2 | HOU | 88% | 9 | 29% | 7-75-2 | 9.0 | 0 | 0% | 0-0 | 26.5 |
| Ja'Marr Chase | WR | 3 | PIT | 100% | 12 | 32% | 9-98-1 | 8.2 | 0 | 0% | 0-0 | 24.8 |
| Ja'Marr Chase | WR | 4 | JAX | 20% | 3 | 6% | 3-27-0 | 4.0 | 0 | 0% | 0-0 | 5.7 |
| Ja'Marr Chase | WR | 5 | MIA | 89% | 10 | 32% | 6-77-1 | 12.4 | 0 | 0% | 0-0 | 19.7 |
| Ja'Marr Chase | WR | 7 | BAL | 87% | 7 | 25% | 5-62-1 | 9.6 | 0 | 0% | 0-0 | 17.2 |
| Joe Burrow | QB | 1 | TB | 100% | 0 | 0% | 0-0-0 | – | 5 | 19% | 20-0 | 14.2 |
| Joe Burrow | QB | 2 | HOU | 100% | 0 | 0% | 0-0-0 | – | 1 | 4% | -1-0 | 16.2 |
| Joe Burrow | QB | 3 | PIT | 100% | 0 | 0% | 0-0-0 | – | 2 | 11% | 13-0 | 22.6 |
| Joe Burrow | QB | 4 | JAX | 100% | 0 | 0% | 0-0-0 | – | 3 | 20% | 6-1 | 23.7 |
| Joe Burrow | QB | 5 | MIA | 100% | 0 | 0% | 0-0-0 | – | 4 | 13% | 10-0 | 24.6 |
| Joe Burrow | QB | 7 | BAL | 94% | 0 | 0% | 0-0-0 | – | 2 | 10% | 12-0 | 28.9 |
| Mike Gesicki | TE | 1 | TB | 33% | 7 | 21% | 5-78-1 | 9.0 | 0 | 0% | 0-0 | 18.8 |
| Mike Gesicki | TE | 3 | PIT | 51% | 3 | 8% | 3-37-1 | 10.7 | 0 | 0% | 0-0 | 12.7 |
| Mike Gesicki | TE | 4 | JAX | 62% | 5 | 9% | 3-40-1 | 12.2 | 0 | 0% | 0-0 | 13.0 |
| Mike Gesicki | TE | 5 | MIA | 45% | 2 | 6% | 1-4-1 | 10.5 | 0 | 0% | 0-0 | 7.4 |
| Mike Gesicki | TE | 7 | BAL | 38% | 1 | 4% | 1-6-1 | 6.0 | 0 | 0% | 0-0 | 7.6 |
| Mitchell Tinsley | WR | 4 | JAX | 53% | 7 | 13% | 3-49-0 | 14.1 | 0 | 0% | 0-0 | 7.9 |
| Mitchell Tinsley | WR | 7 | BAL | 34% | 1 | 4% | 1-7-0 | 4.0 | 0 | 0% | 0-0 | 1.7 |
| Samaje Perine | RB | 1 | TB | 28% | 3 | 9% | 3-30-0 | 1.0 | 5 | 19% | 20-0 | 8.0 |
| Samaje Perine | RB | 2 | HOU | 40% | 1 | 3% | 1-16-0 | 7.0 | 2 | 9% | 6-0 | 3.2 |
| Samaje Perine | RB | 3 | PIT | 32% | 3 | 8% | 1-5-0 | 2.0 | 3 | 17% | 9-0 | 2.4 |
| Samaje Perine | RB | 4 | JAX | 36% | 1 | 2% | 0-0-0 | 0.0 | 3 | 20% | 7-0 | 0.7 |
| Samaje Perine | RB | 5 | MIA | 51% | 2 | 6% | 2-10-1 | -1.5 | 14 | 45% | 68-0 | 15.8 |
| Samaje Perine | RB | 7 | BAL | 23% | 0 | 0% | 0-0-0 | – | 4 | 20% | 16-1 | 7.6 |
| Tahj Brooks | RB | 1 | TB | 3% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Tahj Brooks | RB | 3 | PIT | 0% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Tahj Brooks | RB | 5 | MIA | 0% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Tahj Brooks | RB | 7 | BAL | 6% | 0 | 0% | 0-0-0 | – | 3 | 15% | 6-0 | 0.6 |
| Tanner Hudson | TE | 1 | TB | 9% | 1 | 3% | 1-4-0 | 4.0 | 0 | 0% | 0-0 | 1.4 |
| Tanner Hudson | TE | 3 | PIT | 23% | 2 | 5% | 2-13-0 | 4.5 | 0 | 0% | 0-0 | 3.3 |
| Tanner Hudson | TE | 4 | JAX | 41% | 1 | 2% | 1-2-0 | 2.0 | 0 | 0% | 0-0 | 1.2 |
| Tanner Hudson | TE | 5 | MIA | 29% | 3 | 10% | 3-14-1 | 3.0 | 0 | 0% | 0-0 | 10.4 |
| Tee Higgins | WR | 1 | TB | 72% | 6 | 18% | 3-59-0 | 19.5 | 0 | 0% | 0-0 | 8.9 |
| Tee Higgins | WR | 2 | HOU | 72% | 10 | 32% | 5-95-0 | 9.3 | 0 | 0% | 0-0 | 14.5 |
| Tee Higgins | WR | 3 | PIT | 93% | 7 | 19% | 6-90-1 | 13.1 | 0 | 0% | 0-0 | 21.0 |
| Tee Higgins | WR | 4 | JAX | 79% | 16 | 30% | 11-157-0 | 13.7 | 0 | 0% | 0-0 | 26.7 |
| Tee Higgins | WR | 5 | MIA | 69% | 4 | 13% | 2-22-0 | 13.0 | 0 | 0% | 0-0 | 4.2 |
| Tee Higgins | WR | 7 | BAL | 87% | 7 | 25% | 6-148-1 | 19.6 | 0 | 0% | 0-0 | 26.8 |

Game by game, 2026: gained (expected vs that defense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | TB | 25 | 4.04 (3.62) | 40% (36%) | 0.05 (-0.16) | 37 | -0.04 (-0.11) | 7.26 (6.69) |
| 2 | HOU | 22 | 3.91 (3.74) | 36% (41%) | -0.22 (-0.07) | 36 | -0.02 (0.06) | 6.68 (7.76) |
| 3 | PIT | 16 | 4.38 (3.16) | 50% (32%) | 0.04 (-0.18) | 40 | 0.38 (0.05) | 7.62 (7.06) |
| 4 | JAX | 13 | 1.38 (3.84) | 23% (40%) | -0.31 (-0.10) | 58 | 0.13 (0.02) | 7.93 (8.41) |
| 5 | MIA | 28 | 3.86 (4.04) | 50% (44%) | -0.03 (-0.09) | 33 | 0.29 (0.31) | 5.94 (8.28) |
| 7 | BAL | 19 | 3.37 (3.73) | 47% (38%) | -0.11 (-0.08) | 32 | 0.59 (0.07) | 9.73 (7.44) |
