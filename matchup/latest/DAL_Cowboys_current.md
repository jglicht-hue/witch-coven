# DAL Dallas Cowboys — Matchup Witch data, 2026 (current)

Source: nflverse (play-by-play, NGS participation, FTN charting, player stats, snap counts). Built 2026-10-27 17:19 UTC. Regular season only.
- 2026: weeks 1–7, 107 games, last game 2026-10-26; NGS participation NO (route, man/zone, coverage, pressure unavailable)

## 2026 DEFENSE — DAL Dallas Cowboys (7 games)

Flags, 2026 (leads to test, not verdicts; rank 1 = best D, among teams with enough plays; see README):

Weak (bottom ~15%):
- pass EPA/att, short middle: +0.62 (lg +0.06; 32/32; n=25)
- QB rush yds/g allowed, all QBs: 33.3 (lg 17.4; 32/32; n=32)
- pass D, EPA/dropback: 0.273 (lg 0.063; 31/32)
- pass D, completion %: 69% (lg 64%; 30/32)
- run D, YPC: 4.69 (lg 4.07; 29/32)
- pass EPA/att, int middle: 1.43 (lg +0.59; 29/32; n=13)
- PPR/tgt, WR: 1.88 (lg 1.70; 29/32; n=127)
- rush EPA, ≤6 box: 0.022 (lg -0.072; 29/32; n=67)
- rush EPA, runs, right guard: 0.026 (lg -0.129; 29/32; n=22)
- rush EPA, runs, right end: 0.424 (lg 0.003; 28/28; n=17)

Strong (top ~15%):
- rush EPA, 8+ box: -0.696 (lg -0.061; 1/24; n=11)
- rush EPA, runs, middle: -0.256 (lg -0.100; 4/32; n=34)

Fantasy points allowed (PPR, nflverse scoring incl. rushing, fumbles, 2-pt). Rank 1 = fewest allowed.

| pos | PPR total | PPR/game | rank |
|---|---|---|---|
| QB | 138.2 | 19.7 | 27 |
| RB | 172.4 | 24.6 | 25 |
| WR | 248.2 | 35.5 | 23 |
| TE | 86.6 | 12.4 | 15 |

Unit stats (rank 1 = best defense):

| stat | value | rank |
|---|---|---|
| EPA/dropback | 0.273 | 31 |
| YPA | 7.69 | 26 |
| Comp % | 69% | 30 |
| 20+ yd completions/game | 3.29 | 20 |
| Sack rate | 4% | 27 |
| Pressure rate (NGS) | – | – |
| Blitz rate (FTN: 1+ blitzer) | 28% | – |
| Man coverage rate (NGS) | – | – |
| EPA/rush (designed runs) | -0.033 | 26 |
| YPC | 4.69 | 29 |
| Rush success rate | 43% | 23 |
| Stuff rate (≤0 yds) | 16% | 23 |
| 10+ yd runs/game | 2.86 | 26 |
| 20+ yd runs/game | 1.00 | – |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing offense's adjusted rating from its other games; diff = allowed − expected; adjusted = league avg + diff; rank 1 = best defense; thin = games where that rating rests on under 100 plays; method in README):

| stat | allowed | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 4.69 | 3.75 | +0.94 | 5.01 | 32/32 | 7 | 0 |
| Run success rate | 42.6% | 37.2% | +5.4 | 46.1% | 30/32 | 7 | 0 |
| EPA/rush | -0.033 | -0.129 | +0.096 | 0.019 | 29/32 | 7 | 0 |
| EPA/dropback | 0.273 | 0.018 | +0.255 | 0.318 | 32/32 | 7 | 0 |
| YPA | 7.69 | 6.64 | +1.05 | 8.09 | 28/32 | 7 | 0 |
| Sack rate | 4.1% | 6.8% | -2.6 | 3.3% | 30/32 | 7 | 0 |

QB rushing allowed (runs + scrambles): 32 car, 233 yds, 1 TD; 33.3 yds/g (rank 32/32; lg 17.4); scramble rate 8% (lg 5%)

Passing allowed by throw (rank by EPA/att among teams with ≥8 att; share = opp. QBs' share of att here, usual = their share in other games):

| cell | att | comp | YPA | TD | INT | EPA | rank | share | usual |
|---|---|---|---|---|---|---|---|---|---|
| short left | 54 | 83% | 6.20 | 2 | 1 | 0.16 | 23/32 | 24% | 23% |
| short middle | 25 | 76% | 7.20 | 3 | 0 | 0.62 | 32/32 | 11% | 12% |
| short right | 66 | 76% | 6.21 | 4 | 1 | 0.14 | 26/32 | 34% | 31% |
| int left | 12 | 50% | 9.50 | 0 | 0 | 0.63 | 24/31 | 4% | 6% |
| int middle | 13 | 85% | 16.23 | 0 | 0 | 1.43 | 29/32 | 6% | 7% |
| int right | 10 | 50% | 7.10 | 1 | 0 | 0.45 | 18/31 | 4% | 7% |
| deep left | 15 | 27% | 8.33 | 0 | 0 | -0.03 | 7/23 | 8% | 4% |
| deep middle | 3 | 33% | 9.00 | 0 | 0 | 0.22 | – | 2% | 2% |
| deep right | 16 | 38% | 10.81 | 2 | 0 | 0.49 | 15/24 | 8% | 6% |

Targets allowed by receiver position:

| pos | tgt | catch | YPT | TD | PPR/tgt |
|---|---|---|---|---|---|
| RB | 35 | 80% | 4.54 | 2 | 1.60 |
| WR | 127 | 65% | 8.99 | 7 | 1.88 |
| TE | 45 | 80% | 7.24 | 3 | 1.92 |

Run defense by bucket (box count from FTN charting):

| type | bucket | rushes | YPC | success | EPA/rush |
|---|---|---|---|---|---|
| box | 7 | 88 | 4.95 | 42% | -0.036 |
| box | 8+ | 11 | 0.09 | 36% | -0.696 |
| box | ≤6 | 67 | 4.99 | 43% | 0.022 |
| direction/gap | ? | 1 | 0.00 | 0% | -2.174 |
| direction/gap | left end | 27 | 6.63 | 52% | 0.193 |
| direction/gap | left guard | 29 | 3.21 | 45% | -0.222 |
| direction/gap | left tackle | 35 | 5.54 | 34% | -0.055 |
| direction/gap | middle | 34 | 3.03 | 35% | -0.256 |
| direction/gap | right end | 17 | 6.06 | 53% | 0.424 |
| direction/gap | right guard | 22 | 3.68 | 50% | 0.026 |
| direction/gap | right tackle | 25 | 5.52 | 40% | -0.004 |
| offense formation | shotgun | 65 | 5.45 | 46% | 0.135 |
| offense formation | under center | 125 | 4.30 | 41% | -0.121 |

RB targets allowed by route type:

| route | tgt | catch | YPT | PPR/tgt |
|---|---|---|---|---|
| (route n/a) | 31 | 81% | 5.52 | 1.75 |
| screen | 4 | 75% | -3.00 | 0.45 |

Week by week: top scorer at each position vs this defense (RB line = car-yds-TD rush, tgt, rec-yds-TD):

| wk | pos | opp | top player | line | PPR | pos total PPR |
|---|---|---|---|---|---|---|
| 1 | RB | NYG | Cam Skattebo | 18-81-1 rush, 0 tgt 0-0-0 rec | 14.1 | 27.3 |
| 2 | RB | WAS | Rachaad White | 7-43-0 rush, 6 tgt 6-40-0 rec | 14.3 | 22.5 |
| 3 | RB | BAL | Derrick Henry | 26-89-2 rush, 1 tgt 1-0-0 rec | 21.9 | 25.2 |
| 4 | RB | HOU | Woody Marks | 6-22-1 rush, 1 tgt 0-0-0 rec | 8.2 | 12.5 |
| 5 | RB | TB | Bucky Irving | 21-165-1 rush, 3 tgt 2-10-1 rec | 31.5 | 39.1 |
| 6 | RB | GB | Pierre Strong | 11-28-0 rush, 6 tgt 5-39-0 rec | 11.7 | 12.5 |
| 7 | RB | PHI | Saquon Barkley | 7-62-1 rush, 2 tgt 2-9-0 rec | 15.1 | 33.3 |
| 1 | TE | NYG | Isaiah Likely | 8 tgt, 8-78-2 | 27.8 | 29.7 |
| 2 | TE | WAS | Colson Yankoff | 1 tgt, 1-14-0 | 2.4 | 4.0 |
| 3 | TE | BAL | Matthew Hibner | 2 tgt, 2-23-1 | 10.3 | 18.1 |
| 4 | TE | HOU | Cade Stover | 1 tgt, 1-20-0 | 3.0 | 9.3 |
| 5 | TE | TB | Cade Otton | 4 tgt, 3-25-0 | 5.5 | 7.0 |
| 6 | TE | GB | Tucker Kraft | 8 tgt, 5-37-0 | 8.7 | 8.7 |
| 7 | TE | PHI | Dallas Goedert | 7 tgt, 5-48-0 | 9.8 | 9.8 |
| 1 | WR | NYG | Malik Nabers | 9 tgt, 6-69-0 | 12.9 | 22.1 |
| 2 | WR | WAS | Stefon Diggs | 6 tgt, 5-47-2 | 21.7 | 38.2 |
| 3 | WR | BAL | Zay Flowers | 6 tgt, 5-84-0 (+1-20 rush) | 15.4 | 28.5 |
| 4 | WR | HOU | Nico Collins | 8 tgt, 7-118-2 | 30.8 | 56.9 |
| 5 | WR | TB | Emeka Egbuka | 9 tgt, 6-38-0 (+1-14 rush) | 17.2 | 31.6 |
| 6 | WR | GB | Matthew Golden | 13 tgt, 6-104-1 | 22.4 | 39.9 |
| 7 | WR | PHI | Makai Lemon | 8 tgt, 7-67-1 | 19.7 | 31.0 |

Week by week: QBs vs this defense (main QB = most attempts + sacks + carries; rush = car-yds-TD; pts = nflverse fantasy points: 4-pt pass TD, −2 INT, −2 fumble lost):

| wk | opp | QB | cmp/att | pass yds | pass TD | INT | sk | rush | FL | pts | other QBs | all-QB pts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | NYG | Jaxson Dart | 23/29 | 230 | 3 | 0 | 2 | 11-54-0 | 0 | 26.6 | – | 26.6 |
| 2 | WAS | Jayden Daniels | 11/17 | 96 | 1 | 0 | 0 | 7-69-0 | 0 | 14.7 | Marcus Mariota 11/16, 1 car, 8.7 pts | 23.5 |
| 3 | BAL | Lamar Jackson | 15/20 | 186 | 2 | 0 | 0 | 6-50-0 | 0 | 20.4 | – | 20.4 |
| 4 | HOU | C.J. Stroud | 21/31 | 347 | 2 | 0 | 2 | 2-12-0 | 0 | 23.1 | – | 23.1 |
| 5 | TB | Jalon Daniels | 19/25 | 189 | 1 | 0 | 1 | 7-23-0 | 0 | 13.9 | – | 13.9 |
| 6 | GB | Jordan Love | 23/41 | 276 | 1 | 1 | 3 | 4-12-1 | 0 | 20.2 | – | 20.2 |
| 7 | PHI | Tanner McKee | 23/35 | 211 | 1 | 1 | 2 | 1-1-0 | 0 | 10.5 | – | 10.5 |

Game by game, 2026: allowed (expected vs that offense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | NYG | 32 | 5.00 (3.79) | 50% (33%) | 0.06 (-0.12) | 33 | 0.67 (-0.08) | 7.93 (6.57) |
| 2 | WAS | 25 | 4.40 (3.66) | 48% (35%) | -0.08 (-0.18) | 42 | 0.16 (0.05) | 5.91 (6.96) |
| 3 | BAL | 36 | 4.83 (4.19) | 42% (39%) | -0.13 (-0.06) | 22 | 0.57 (0.18) | 9.30 (8.27) |
| 4 | HOU | 17 | 2.94 (3.46) | 24% (36%) | -0.23 (-0.15) | 33 | 0.48 (0.05) | 11.97 (6.54) |
| 5 | TB | 32 | 6.81 (4.08) | 50% (44%) | 0.10 (0.01) | 31 | 0.22 (-0.13) | 7.56 (5.71) |
| 6 | GB | 24 | 2.46 (3.29) | 29% (37%) | -0.16 (-0.28) | 44 | 0.14 (0.19) | 6.73 (7.50) |
| 7 | PHI | 24 | 5.00 (3.35) | 46% (33%) | 0.13 (-0.21) | 38 | -0.10 (-0.13) | 6.03 (5.21) |

## 2026 OFFENSE — DAL Dallas Cowboys

Usage concentrations (share well above league avg at his position):
- George Pickens (WR, 58 tgt): short left 34% (avg 22%)
- Ryan Flournoy (WR, 40 tgt): short left 40% (avg 22%)
- Brevyn Spann-Ford (TE, 13 tgt): short right 69% (avg 34%)
- Tyler Goodson (RB, 21 car): runs left tackle 24% (avg 13%)

Team passing context:

| stat | value |
|---|---|
| Dropbacks | 296 |
| EPA/dropback | 0.149 |
| Sack rate | 2% |
| Pressure rate faced (NGS) | – |
| EPA/db clean | – |
| EPA/db under pressure | – |
| Blitz rate faced (FTN) | 33% |
| EPA/db vs blitz | 0.021 |
| EPA/db vs no blitz | 0.166 |
| Pass rate over expected | 1.8 pts |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing defense's adjusted rating from its other games; diff = gained − expected; adjusted = league avg + diff; rank 1 = best offense; thin = games where that rating rests on under 100 plays; method in README):

| stat | gained | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 3.96 | 3.87 | +0.09 | 4.16 | 14/32 | 7 | 0 |
| Run success rate | 45.3% | 42.0% | +3.3 | 43.9% | 11/32 | 7 | 0 |
| EPA/rush | 0.044 | -0.057 | +0.100 | 0.024 | 6/32 | 7 | 0 |
| EPA/dropback | 0.149 | 0.033 | +0.116 | 0.179 | 8/32 | 7 | 0 |
| YPA | 6.71 | 6.99 | -0.28 | 6.76 | 20/32 | 7 | 0 |
| Sack rate | 2.4% | 5.7% | -3.4 | 2.6% | 1/32 | 7 | 0 |

QB throw map (share of att, EPA/att in parentheses; ≥40 att):

| QB | att | short left | short middle | short right | int left | int middle | int right | deep left | deep middle | deep right |
|---|---|---|---|---|---|---|---|---|---|---|
| Dak Prescott | 273 | 28% (0.21) | 11% (-0.20) | 30% (0.18) | 10% (0.35) | 5% (-0.19) | 8% (0.38) | 2% (0.20) | 1% (2.21) | 4% (0.43) |
| league | 7106 | 26% (0.05) | 12% (0.06) | 30% (0.02) | 7% (0.30) | 7% (0.59) | 8% (0.35) | 4% (0.32) | 2% (0.76) | 5% (0.37) |

Player usage, season totals (RZ opps = carries + targets inside the 10 / 5):

| player | pos | G | snap% avg | tgt | tgt share | air yds share | aDOT | rec-yds-TD | YAC/rec | MOF tgt% | car | car share | rush yds-TD | RZ10 opps | RZ5 opps | PPR | PPR/g |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| CeeDee Lamb | WR | 7 | 79% | 81 | 30% | 40% | 10.6 | 53-651-6 | 3.5 | 14% | 2 | 1% | -6-0 | 7 | 5 | 155.5 | 22.2 |
| Javonte Williams | RB | 7 | 75% | 22 | 8% | -2% | -1.6 | 19-103-1 | 6.9 | 23% | 110 | 69% | 472-8 | 20 | 17 | 130.5 | 18.6 |
| Dak Prescott | QB | 7 | 100% | 0 | 0% | 0% | – | 0-0-0 | – | – | 16 | 10% | 81-0 | 1 | 1 | 128.1 | 18.3 |
| George Pickens | WR | 7 | 81% | 58 | 22% | 30% | 11.1 | 37-485-2 | 2.8 | 10% | 0 | 0% | 0-0 | 4 | 3 | 97.5 | 13.9 |
| Ryan Flournoy | WR | 7 | 74% | 40 | 15% | 13% | 6.8 | 27-304-1 | 5.2 | 22% | 0 | 0% | 0-0 | 3 | 2 | 63.4 | 9.1 |
| Jake Ferguson | TE | 7 | 67% | 25 | 9% | 6% | 5.0 | 17-115-3 | 2.8 | 28% | 0 | 0% | 0-0 | 3 | 1 | 44.5 | 6.4 |
| Brevyn Spann-Ford | TE | 7 | 39% | 13 | 5% | 2% | 2.5 | 9-79-0 | 5.0 | 15% | 0 | 0% | 0-0 | 0 | 0 | 16.9 | 2.4 |
| KaVontae Turpin | WR | 6 | 15% | 7 | 3% | 2% | 6.1 | 4-39-0 | 4.8 | 14% | 2 | 1% | 10-1 | 1 | 0 | 14.9 | 2.5 |
| Tyler Goodson | RB | 4 | 15% | 5 | 2% | -0% | -0.6 | 2-4-0 | 3.0 | 40% | 21 | 13% | 72-0 | 1 | 0 | 9.6 | 2.4 |
| Hunter Luepke | RB | 6 | 17% | 4 | 2% | 0% | 1.8 | 4-11-0 | 1.0 | 50% | 4 | 2% | 16-0 | 1 | 0 | 6.7 | 1.1 |
| Luke Schoonmaker | TE | 3 | 17% | 3 | 1% | 1% | 7.7 | 3-30-0 | 2.3 | 33% | 0 | 0% | 0-0 | 0 | 0 | 6.0 | 2.0 |
| Jonathan Mingo | WR | 5 | 21% | 8 | 3% | 6% | 17.1 | 3-30-0 | 0.3 | 0% | 0 | 0% | 0-0 | 0 | 0 | 6.0 | 1.2 |
| Emari Demercado | RB | 2 | 12% | 0 | 0% | 0% | – | 0-0-0 | – | – | 5 | 3% | 15-0 | 0 | 0 | 1.5 | 0.8 |

Target depth mix (air yards):

| player | behind LOS | 0-9 | 10-19 | 20+ |
|---|---|---|---|---|
| CeeDee Lamb | 10% | 48% | 31% | 11% |
| Javonte Williams | 64% | 36% | 0% | 0% |
| Tyler Goodson | 60% | 40% | 0% | 0% |
| George Pickens | 2% | 59% | 28% | 12% |
| KaVontae Turpin | 0% | 71% | 29% | 0% |
| Jake Ferguson | 28% | 48% | 24% | 0% |
| Jonathan Mingo | 0% | 25% | 50% | 25% |
| Ryan Flournoy | 20% | 57% | 18% | 5% |
| Brevyn Spann-Ford | 31% | 62% | 8% | 0% |

RB rushing by bucket (≥8 carries):

| RB | type | bucket | car | YPC | success | EPA/rush |
|---|---|---|---|---|---|---|
| Javonte Williams | formation | shotgun | 31 | 4.06 | 52% | 0.061 |
| Javonte Williams | formation | under center | 79 | 4.38 | 46% | 0.121 |
| Javonte Williams | box | 7 | 44 | 3.00 | 36% | -0.078 |
| Javonte Williams | box | 8+ | 4 | 1.50 | 100% | 0.633 |
| Javonte Williams | box | ≤6 | 37 | 4.84 | 51% | 0.074 |
| Javonte Williams | direction/gap | left end | 5 | 2.20 | 40% | -0.095 |
| Javonte Williams | direction/gap | left guard | 15 | 4.53 | 40% | 0.088 |
| Javonte Williams | direction/gap | left tackle | 21 | 7.76 | 57% | 0.412 |
| Javonte Williams | direction/gap | middle | 37 | 3.51 | 43% | 0.131 |
| Javonte Williams | direction/gap | right end | 3 | 4.33 | 33% | -0.358 |
| Javonte Williams | direction/gap | right guard | 16 | 3.88 | 56% | 0.139 |
| Javonte Williams | direction/gap | right tackle | 13 | 1.92 | 46% | -0.310 |
| Tyler Goodson | formation | shotgun | 8 | 4.12 | 62% | 0.056 |
| Tyler Goodson | formation | under center | 13 | 3.00 | 31% | -0.266 |
| Tyler Goodson | box | 7 | 5 | 1.60 | 20% | -0.453 |
| Tyler Goodson | box | ≤6 | 6 | 4.33 | 50% | 0.033 |
| Tyler Goodson | direction/gap | left end | 4 | 4.75 | 75% | 0.024 |
| Tyler Goodson | direction/gap | left guard | 1 | 2.00 | 0% | -0.504 |
| Tyler Goodson | direction/gap | left tackle | 5 | 5.60 | 40% | 0.077 |
| Tyler Goodson | direction/gap | middle | 5 | 3.40 | 40% | -0.055 |
| Tyler Goodson | direction/gap | right end | 2 | 2.00 | 50% | -0.408 |
| Tyler Goodson | direction/gap | right guard | 1 | 2.00 | 100% | 0.382 |
| Tyler Goodson | direction/gap | right tackle | 3 | 0.00 | 0% | -0.758 |

Week by week usage:

| player | pos | wk | opp | snap% | tgt | tgt share | rec-yds-TD | aDOT | car | car share | rush yds-TD | PPR |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Brevyn Spann-Ford | TE | 1 | NYG | 22% | 2 | 7% | 2-14-0 | 3.0 | 0 | 0% | 0-0 | 3.4 |
| Brevyn Spann-Ford | TE | 2 | WAS | 38% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Brevyn Spann-Ford | TE | 3 | BAL | 38% | 1 | 2% | 1-19-0 | 2.0 | 0 | 0% | 0-0 | 2.9 |
| Brevyn Spann-Ford | TE | 4 | HOU | 40% | 1 | 2% | 0-0-0 | -2.0 | 0 | 0% | 0-0 | 0.0 |
| Brevyn Spann-Ford | TE | 5 | TB | 33% | 2 | 5% | 0-0-0 | -4.0 | 0 | 0% | 0-0 | 0.0 |
| Brevyn Spann-Ford | TE | 6 | GB | 46% | 5 | 9% | 4-35-0 | 6.2 | 0 | 0% | 0-0 | 7.5 |
| Brevyn Spann-Ford | TE | 7 | PHI | 53% | 2 | 8% | 2-11-0 | 2.0 | 0 | 0% | 0-0 | 3.1 |
| CeeDee Lamb | WR | 1 | NYG | 81% | 8 | 27% | 5-44-1 | 11.2 | 1 | 6% | 0-0 | 15.4 |
| CeeDee Lamb | WR | 2 | WAS | 75% | 9 | 29% | 8-153-2 | 15.1 | 0 | 0% | 0-0 | 35.3 |
| CeeDee Lamb | WR | 3 | BAL | 82% | 8 | 20% | 7-112-0 | 10.6 | 0 | 0% | 0-0 | 20.2 |
| CeeDee Lamb | WR | 4 | HOU | 86% | 21 | 49% | 17-189-1 | 7.6 | 1 | 4% | -6-0 | 41.3 |
| CeeDee Lamb | WR | 5 | TB | 57% | 5 | 12% | 2-9-0 | 11.2 | 0 | 0% | 0-0 | 2.9 |
| CeeDee Lamb | WR | 6 | GB | 88% | 18 | 33% | 9-70-0 | 8.5 | 0 | 0% | 0-0 | 16.0 |
| CeeDee Lamb | WR | 7 | PHI | 81% | 12 | 46% | 5-74-2 | 14.7 | 0 | 0% | 0-0 | 24.4 |
| Dak Prescott | QB | 1 | NYG | 100% | 0 | 0% | 0-0-0 | – | 2 | 11% | 14-0 | 14.4 |
| Dak Prescott | QB | 2 | WAS | 100% | 0 | 0% | 0-0-0 | – | 4 | 19% | 26-0 | 29.8 |
| Dak Prescott | QB | 3 | BAL | 100% | 0 | 0% | 0-0-0 | – | 4 | 13% | 19-0 | 18.9 |
| Dak Prescott | QB | 4 | HOU | 100% | 0 | 0% | 0-0-0 | – | 2 | 8% | 7-0 | 18.1 |
| Dak Prescott | QB | 5 | TB | 100% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 12.6 |
| Dak Prescott | QB | 6 | GB | 100% | 0 | 0% | 0-0-0 | – | 2 | 13% | 7-0 | 11.0 |
| Dak Prescott | QB | 7 | PHI | 100% | 0 | 0% | 0-0-0 | – | 2 | 5% | 8-0 | 23.3 |
| Emari Demercado | RB | 1 | NYG | 9% | 0 | 0% | 0-0-0 | – | 2 | 11% | 7-0 | 0.7 |
| Emari Demercado | RB | 2 | WAS | 16% | 0 | 0% | 0-0-0 | – | 3 | 14% | 8-0 | 0.8 |
| George Pickens | WR | 1 | NYG | 84% | 6 | 20% | 3-28-0 | 17.3 | 0 | 0% | 0-0 | 5.8 |
| George Pickens | WR | 2 | WAS | 76% | 8 | 26% | 6-40-0 | 10.4 | 0 | 0% | 0-0 | 10.0 |
| George Pickens | WR | 3 | BAL | 85% | 11 | 28% | 7-82-0 | 7.3 | 0 | 0% | 0-0 | 15.2 |
| George Pickens | WR | 4 | HOU | 86% | 3 | 7% | 2-75-0 | 24.3 | 0 | 0% | 0-0 | 9.5 |
| George Pickens | WR | 5 | TB | 88% | 13 | 31% | 9-130-1 | 9.8 | 0 | 0% | 0-0 | 28.0 |
| George Pickens | WR | 6 | GB | 88% | 11 | 20% | 6-73-0 | 10.5 | 0 | 0% | 0-0 | 13.3 |
| George Pickens | WR | 7 | PHI | 60% | 6 | 23% | 4-57-1 | 10.2 | 0 | 0% | 0-0 | 15.7 |
| Hunter Luepke | RB | 1 | NYG | 26% | 0 | 0% | 0-0-0 | – | 1 | 6% | 7-0 | 0.7 |
| Hunter Luepke | RB | 2 | WAS | 18% | 0 | 0% | 0-0-0 | – | 1 | 5% | 1-0 | 0.1 |
| Hunter Luepke | RB | 4 | HOU | 12% | 1 | 2% | 1-2-0 | 2.0 | 0 | 0% | 0-0 | 1.2 |
| Hunter Luepke | RB | 5 | TB | 12% | 0 | 0% | 0-0-0 | – | 1 | 8% | 5-0 | 0.5 |
| Hunter Luepke | RB | 6 | GB | 14% | 3 | 6% | 3-9-0 | 1.7 | 0 | 0% | 0-0 | 3.9 |
| Hunter Luepke | RB | 7 | PHI | 24% | 0 | 0% | 0-0-0 | – | 1 | 3% | 3-0 | 0.3 |
| Jake Ferguson | TE | 1 | NYG | 76% | 2 | 7% | 2-6-0 | 3.0 | 0 | 0% | 0-0 | 2.6 |
| Jake Ferguson | TE | 2 | WAS | 60% | 4 | 13% | 4-43-2 | 7.2 | 0 | 0% | 0-0 | 20.3 |
| Jake Ferguson | TE | 3 | BAL | 69% | 5 | 12% | 3-23-1 | 2.4 | 0 | 0% | 0-0 | 9.3 |
| Jake Ferguson | TE | 4 | HOU | 71% | 4 | 9% | 3-11-0 | 4.5 | 0 | 0% | 0-0 | 4.1 |
| Jake Ferguson | TE | 5 | TB | 83% | 6 | 14% | 3-19-0 | 4.8 | 0 | 0% | 0-0 | 4.9 |
| Jake Ferguson | TE | 6 | GB | 54% | 3 | 6% | 2-13-0 | 7.7 | 0 | 0% | 0-0 | 3.3 |
| Jake Ferguson | TE | 7 | PHI | 56% | 1 | 4% | 0-0-0 | 9.0 | 0 | 0% | 0-0 | 0.0 |
| Javonte Williams | RB | 1 | NYG | 71% | 5 | 17% | 5-31-1 | -2.2 | 12 | 67% | 41-1 | 24.2 |
| Javonte Williams | RB | 2 | WAS | 80% | 4 | 13% | 3-20-0 | -3.0 | 12 | 57% | 30-0 | 8.0 |
| Javonte Williams | RB | 3 | BAL | 76% | 3 | 8% | 2-5-0 | -3.0 | 19 | 63% | 98-1 | 18.3 |
| Javonte Williams | RB | 4 | HOU | 74% | 5 | 12% | 5-21-0 | 0.2 | 19 | 76% | 62-3 | 31.3 |
| Javonte Williams | RB | 5 | TB | 85% | 3 | 7% | 2-17-0 | 1.7 | 12 | 92% | 45-1 | 14.2 |
| Javonte Williams | RB | 6 | GB | 73% | 2 | 4% | 2-9-0 | -5.0 | 11 | 73% | 41-1 | 13.0 |
| Javonte Williams | RB | 7 | PHI | 65% | 0 | 0% | 0-0-0 | – | 25 | 66% | 155-1 | 21.5 |
| Jonathan Mingo | WR | 1 | NYG | 19% | 1 | 3% | 1-10-0 | 11.0 | 0 | 0% | 0-0 | 2.0 |
| Jonathan Mingo | WR | 4 | HOU | 18% | 2 | 5% | 0-0-0 | 8.0 | 0 | 0% | 0-0 | 0.0 |
| Jonathan Mingo | WR | 5 | TB | 20% | 4 | 10% | 2-20-0 | 16.2 | 0 | 0% | 0-0 | 4.0 |
| Jonathan Mingo | WR | 6 | GB | 19% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Jonathan Mingo | WR | 7 | PHI | 34% | 1 | 4% | 0-0-0 | 45.0 | 0 | 0% | 0-0 | 0.0 |
| KaVontae Turpin | WR | 1 | NYG | 14% | 1 | 3% | 1-8-0 | 1.0 | 0 | 0% | 0-0 | 1.8 |
| KaVontae Turpin | WR | 2 | WAS | 9% | 0 | 0% | 0-0-0 | – | 1 | 5% | 1-0 | 0.1 |
| KaVontae Turpin | WR | 3 | BAL | 16% | 2 | 5% | 1-9-0 | 7.5 | 1 | 3% | 9-1 | 8.8 |
| KaVontae Turpin | WR | 4 | HOU | 10% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| KaVontae Turpin | WR | 5 | TB | 40% | 4 | 10% | 2-22-0 | 6.8 | 0 | 0% | 0-0 | 4.2 |
| KaVontae Turpin | WR | 6 | GB | 0% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Luke Schoonmaker | TE | 1 | NYG | 22% | 1 | 3% | 1-12-0 | 12.0 | 0 | 0% | 0-0 | 2.2 |
| Luke Schoonmaker | TE | 3 | BAL | 22% | 1 | 2% | 1-9-0 | 6.0 | 0 | 0% | 0-0 | 1.9 |
| Luke Schoonmaker | TE | 5 | TB | 8% | 1 | 2% | 1-9-0 | 5.0 | 0 | 0% | 0-0 | 1.9 |
| Ryan Flournoy | WR | 1 | NYG | 71% | 4 | 13% | 2-22-0 | 5.8 | 0 | 0% | 0-0 | 4.2 |
| Ryan Flournoy | WR | 2 | WAS | 76% | 6 | 19% | 5-23-0 | 1.3 | 0 | 0% | 0-0 | 7.3 |
| Ryan Flournoy | WR | 3 | BAL | 66% | 8 | 20% | 2-22-0 | 10.9 | 0 | 0% | 0-0 | 4.2 |
| Ryan Flournoy | WR | 4 | HOU | 74% | 5 | 12% | 4-37-0 | 1.0 | 0 | 0% | 0-0 | 7.7 |
| Ryan Flournoy | WR | 5 | TB | 68% | 4 | 10% | 3-90-0 | 12.5 | 0 | 0% | 0-0 | 12.0 |
| Ryan Flournoy | WR | 6 | GB | 87% | 9 | 17% | 7-40-1 | 5.8 | 0 | 0% | 0-0 | 17.0 |
| Ryan Flournoy | WR | 7 | PHI | 78% | 4 | 15% | 4-70-0 | 11.5 | 0 | 0% | 0-0 | 11.0 |
| Tyler Goodson | RB | 3 | BAL | 15% | 1 | 2% | 1-(-5)-0 | -6.0 | 6 | 20% | 22-0 | 2.7 |
| Tyler Goodson | RB | 4 | HOU | 21% | 1 | 2% | 0-0-0 | -1.0 | 3 | 12% | 12-0 | 1.2 |
| Tyler Goodson | RB | 6 | GB | 14% | 3 | 6% | 1-9-0 | 1.3 | 2 | 13% | 0-0 | 1.9 |
| Tyler Goodson | RB | 7 | PHI | 21% | 0 | 0% | 0-0-0 | – | 10 | 26% | 38-0 | 3.8 |

Game by game, 2026: gained (expected vs that defense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | NYG | 16 | 3.44 (5.04) | 44% (44%) | 0.01 (-0.04) | 36 | 0.31 (0.06) | 5.15 (6.89) |
| 2 | WAS | 18 | 2.39 (3.96) | 39% (47%) | -0.24 (-0.05) | 36 | 0.46 (0.11) | 9.00 (7.05) |
| 3 | BAL | 26 | 4.96 (3.43) | 42% (40%) | -0.01 (-0.07) | 46 | 0.17 (0.13) | 6.73 (7.86) |
| 4 | HOU | 23 | 2.96 (3.97) | 48% (39%) | 0.08 (-0.10) | 50 | 0.17 (0.01) | 7.44 (7.46) |
| 5 | TB | 13 | 3.85 (3.78) | 38% (36%) | 0.05 (-0.12) | 43 | -0.08 (-0.12) | 7.35 (6.45) |
| 6 | GB | 14 | 2.93 (3.66) | 50% (43%) | -0.01 (-0.11) | 57 | -0.16 (-0.01) | 4.69 (6.53) |
| 7 | PHI | 38 | 5.26 (3.69) | 50% (44%) | 0.22 (0.01) | 28 | 0.45 (0.09) | 7.85 (6.76) |
