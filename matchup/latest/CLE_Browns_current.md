# CLE Cleveland Browns — Matchup Witch data, 2026 (current)

Source: nflverse (play-by-play, NGS participation, FTN charting, player stats, snap counts). Built 2026-11-10 14:53 UTC. Regular season only.
- 2026: weeks 1–9, 136 games, last game 2026-11-09; NGS participation NO (route, man/zone, coverage, pressure unavailable)

## 2026 DEFENSE — CLE Cleveland Browns (9 games)

Flags, 2026 (leads to test, not verdicts; rank 1 = best D, among teams with enough plays; see README):

Weak (bottom ~15%):
- pass EPA/att, short middle: +0.42 (lg +0.06; 32/32; n=30)
- run D, 10+ yd runs/game: 3.78 (lg 2.28; 32/32)
- rush EPA, 7 box: 0.101 (lg -0.076; 30/32; n=82)
- run D, EPA/rush: -0.016 (lg -0.079; 30/32)
- rush EPA, runs, middle: 0.074 (lg -0.098; 30/32; n=65)
- run D, YPC: 4.64 (lg 4.09; 28/32)

Strong (top ~15%):
- pass EPA/att, deep right: -0.41 (lg +0.40; 2/28; n=18)
- PPR/tgt, RB: 1.10 (lg 1.50; 2/32; n=44)
- run D, stuff rate: 23% (lg 18%; 3/32)
- pass D, completion %: 60% (lg 64%; 3/32)
- pass EPA/att, short left: -0.19 (lg +0.02; 5/32; n=69)

Fantasy points allowed (PPR, nflverse scoring incl. rushing, fumbles, 2-pt). Rank 1 = fewest allowed.

| pos | PPR total | PPR/game | rank |
|---|---|---|---|
| QB | 127.3 | 14.1 | 8 |
| RB | 191.8 | 21.3 | 18 |
| WR | 265.7 | 29.5 | 11 |
| TE | 133.1 | 14.8 | 23 |

Unit stats (rank 1 = best defense):

| stat | value | rank |
|---|---|---|
| EPA/dropback | -0.021 | 9 |
| YPA | 6.70 | 11 |
| Comp % | 60% | 3 |
| 20+ yd completions/game | 2.89 | 15 |
| Sack rate | 8% | 6 |
| Pressure rate (NGS) | – | – |
| Blitz rate (FTN: 1+ blitzer) | 24% | – |
| Man coverage rate (NGS) | – | – |
| EPA/rush (designed runs) | -0.016 | 30 |
| YPC | 4.64 | 28 |
| Rush success rate | 43% | 25 |
| Stuff rate (≤0 yds) | 23% | 3 |
| 10+ yd runs/game | 3.78 | 32 |
| 20+ yd runs/game | 0.67 | – |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing offense's adjusted rating from its other games; diff = allowed − expected; adjusted = league avg + diff; rank 1 = best defense; thin = games where that rating rests on under 100 plays; method in README):

| stat | allowed | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 4.64 | 4.23 | +0.41 | 4.50 | 28/32 | 9 | 0 |
| Run success rate | 43.5% | 40.7% | +2.8 | 43.2% | 23/32 | 9 | 0 |
| EPA/rush | -0.016 | -0.046 | +0.030 | -0.049 | 23/32 | 9 | 0 |
| EPA/dropback | -0.021 | -0.017 | -0.003 | 0.043 | 12/32 | 9 | 0 |
| YPA | 6.70 | 6.67 | +0.03 | 7.11 | 15/32 | 9 | 0 |
| Sack rate | 7.7% | 6.7% | +1.0 | 7.3% | 7/32 | 9 | 0 |

QB rushing allowed (runs + scrambles): 26 car, 128 yds, 0 TD; 14.2 yds/g (rank 14/32; lg 16.6); scramble rate 4% (lg 5%)

Passing allowed by throw (rank by EPA/att among teams with ≥8 att; share = opp. QBs' share of att here, usual = their share in other games):

| cell | att | comp | YPA | TD | INT | EPA | rank | share | usual |
|---|---|---|---|---|---|---|---|---|---|
| short left | 69 | 68% | 4.81 | 2 | 0 | -0.19 | 5/32 | 23% | 27% |
| short middle | 30 | 80% | 7.27 | 3 | 0 | 0.42 | 32/32 | 10% | 11% |
| short right | 88 | 68% | 4.51 | 2 | 0 | -0.05 | 9/32 | 30% | 31% |
| int left | 22 | 45% | 9.41 | 0 | 2 | 0.22 | 11/32 | 7% | 7% |
| int middle | 15 | 47% | 6.87 | 1 | 0 | 0.27 | 8/32 | 5% | 7% |
| int right | 22 | 64% | 10.14 | 1 | 0 | 0.60 | 27/32 | 7% | 7% |
| deep left | 15 | 40% | 11.73 | 1 | 0 | 0.70 | 22/29 | 5% | 4% |
| deep middle | 16 | 38% | 13.56 | 1 | 1 | 0.48 | 4/9 | 5% | 2% |
| deep right | 18 | 17% | 6.06 | 1 | 3 | -0.41 | 2/28 | 6% | 4% |

Targets allowed by receiver position:

| pos | tgt | catch | YPT | TD | PPR/tgt |
|---|---|---|---|---|---|
| RB | 44 | 73% | 3.68 | 0 | 1.10 |
| WR | 168 | 58% | 7.74 | 7 | 1.61 |
| TE | 68 | 69% | 7.65 | 5 | 1.90 |

Run defense by bucket (box count from FTN charting):

| type | bucket | rushes | YPC | success | EPA/rush |
|---|---|---|---|---|---|
| box | 7 | 82 | 4.70 | 49% | 0.101 |
| box | 8+ | 6 | 2.00 | 50% | -0.457 |
| box | ≤6 | 142 | 4.72 | 40% | -0.065 |
| direction/gap | ? | 5 | 1.40 | 40% | -0.526 |
| direction/gap | left end | 32 | 5.78 | 47% | 0.113 |
| direction/gap | left guard | 31 | 4.45 | 39% | -0.032 |
| direction/gap | left tackle | 21 | 5.14 | 48% | 0.014 |
| direction/gap | middle | 65 | 4.83 | 52% | 0.074 |
| direction/gap | right end | 17 | 5.24 | 35% | -0.061 |
| direction/gap | right guard | 33 | 3.67 | 45% | -0.084 |
| direction/gap | right tackle | 26 | 4.04 | 23% | -0.193 |
| offense formation | shotgun | 97 | 5.51 | 49% | 0.102 |
| offense formation | under center | 133 | 4.01 | 39% | -0.103 |

RB targets allowed by route type:

| route | tgt | catch | YPT | PPR/tgt |
|---|---|---|---|---|
| (route n/a) | 34 | 65% | 3.85 | 1.03 |
| screen | 10 | 100% | 3.10 | 1.31 |

Week by week: top scorer at each position vs this defense (RB line = car-yds-TD rush, tgt, rec-yds-TD):

| wk | pos | opp | top player | line | PPR | pos total PPR |
|---|---|---|---|---|---|---|
| 1 | RB | JAX | Bhayshul Tuten | 15-66-0 rush, 1 tgt 1-22-0 rec | 9.8 | 16.3 |
| 2 | RB | TB | Bucky Irving | 17-89-0 rush, 4 tgt 4-1-0 rec | 13.0 | 17.5 |
| 3 | RB | CAR | Chuba Hubbard | 19-82-0 rush, 4 tgt 4-28-0 rec | 15.0 | 17.4 |
| 4 | RB | PIT | Jaylen Warren | 17-93-0 rush, 6 tgt 3-33-0 rec | 15.6 | 15.5 |
| 5 | RB | NYJ | Braelon Allen | 24-116-1 rush, 4 tgt 1-0-0 rec | 18.6 | 21.3 |
| 6 | RB | BAL | Derrick Henry | 17-58-0 rush, 1 tgt 1-2-0 rec | 5.0 | 8.9 |
| 7 | RB | TEN | Tony Pollard | 25-129-3 rush, 3 tgt 3-26-0 rec | 36.5 | 38.9 |
| 8 | RB | PIT | Jaylen Warren | 17-143-1 rush, 2 tgt 1-0-0 rec | 21.3 | 32.9 |
| 9 | RB | NO | Audric Estimé | 15-72-1 rush, 1 tgt 1-5-0 rec | 14.7 | 23.1 |
| 1 | TE | JAX | Brenton Strange | 3 tgt, 2-23-1 | 10.3 | 12.2 |
| 2 | TE | TB | Cade Otton | 6 tgt, 5-38-0 | 8.8 | 8.8 |
| 3 | TE | CAR | Darren Waller | 8 tgt, 5-51-0 | 10.1 | 23.8 |
| 4 | TE | PIT | Darnell Washington | 5 tgt, 3-27-1 | 11.7 | 22.4 |
| 5 | TE | NYJ | Mason Taylor | 3 tgt, 3-24-0 | 5.4 | 5.7 |
| 6 | TE | BAL | Josh Cuevas | 5 tgt, 4-44-1 | 14.4 | 15.8 |
| 7 | TE | TEN | Gunnar Helm | 4 tgt, 3-24-0 | 5.4 | 6.8 |
| 8 | TE | PIT | Darnell Washington | 5 tgt, 3-94-0 | 12.4 | 24.0 |
| 9 | TE | NO | Juwan Johnson | 2 tgt, 2-34-1 | 11.4 | 13.6 |
| 1 | WR | JAX | Parker Washington | 6 tgt, 5-83-1 | 19.3 | 48.5 |
| 2 | WR | TB | Emeka Egbuka | 5 tgt, 3-16-1 (+1--3 rush) | 10.3 | 29.7 |
| 3 | WR | CAR | Brycen Tremayne | 6 tgt, 4-83-0 | 12.3 | 29.7 |
| 4 | WR | PIT | DK Metcalf | 9 tgt, 5-115-0 | 16.5 | 41.2 |
| 5 | WR | NYJ | Garrett Wilson | 11 tgt, 7-104-1 | 23.4 | 30.9 |
| 6 | WR | BAL | Zay Flowers | 11 tgt, 6-66-0 (+1-1 rush) | 12.7 | 20.7 |
| 7 | WR | TEN | Carnell Tate | 7 tgt, 5-69-0 | 9.9 | 22.0 |
| 8 | WR | PIT | Germie Bernard | 5 tgt, 5-30-0 | 8.0 | 11.3 |
| 9 | WR | NO | Chris Olave | 12 tgt, 7-98-0 | 16.8 | 31.7 |

Week by week: QBs vs this defense (main QB = most attempts + sacks + carries; rush = car-yds-TD; pts = nflverse fantasy points: 4-pt pass TD, −2 INT, −2 fumble lost):

| wk | opp | QB | cmp/att | pass yds | pass TD | INT | sk | rush | FL | pts | other QBs | all-QB pts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | JAX | Trevor Lawrence | 18/23 | 245 | 4 | 0 | 1 | 2-3-0 | 0 | 26.1 | Nick Mullens 0/0, 3 car, -0.3 pts | 25.8 |
| 2 | TB | Baker Mayfield | 21/34 | 182 | 1 | 1 | 3 | 4-29-0 | 0 | 12.2 | – | 12.2 |
| 3 | CAR | Bryce Young | 26/48 | 291 | 1 | 1 | 3 | 0-0-0 | 0 | 13.6 | – | 13.6 |
| 4 | PIT | Aaron Rodgers | 22/40 | 299 | 3 | 2 | 5 | 0-0-0 | 0 | 22.0 | – | 22.0 |
| 5 | NYJ | Geno Smith | 17/30 | 182 | 1 | 0 | 4 | 5-7-0 | 1 | 10.0 | – | 10.0 |
| 6 | BAL | Tyler Huntley | 19/31 | 165 | 1 | 0 | 3 | 5-28-0 | 0 | 13.4 | – | 13.4 |
| 7 | TEN | Cam Ward | 20/31 | 181 | 0 | 1 | 1 | 2-5-0 | 0 | 5.7 | – | 5.7 |
| 8 | PIT | Aaron Rodgers | 13/25 | 172 | 0 | 1 | 1 | 0-0-0 | 0 | 4.9 | – | 4.9 |
| 9 | NO | Tyler Shough | 21/35 | 265 | 1 | 0 | 5 | 10-51-0 | 0 | 19.7 | – | 19.7 |

Game by game, 2026: allowed (expected vs that offense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | JAX | 28 | 4.54 (4.07) | 54% (42%) | -0.01 (-0.02) | 24 | 0.79 (0.20) | 10.65 (8.11) |
| 2 | TB | 22 | 5.05 (4.80) | 45% (46%) | 0.02 (-0.01) | 40 | -0.23 (-0.14) | 5.35 (5.96) |
| 3 | CAR | 24 | 4.08 (4.16) | 29% (43%) | -0.15 (-0.03) | 50 | -0.12 (0.17) | 6.19 (7.49) |
| 4 | PIT | 20 | 4.70 (4.83) | 55% (41%) | 0.11 (0.06) | 46 | 0.05 (-0.15) | 7.29 (5.83) |
| 5 | NYJ | 29 | 4.52 (4.20) | 38% (43%) | 0.05 (-0.14) | 35 | -0.36 (0.09) | 6.07 (7.55) |
| 6 | BAL | 19 | 3.11 (4.36) | 26% (40%) | -0.56 (-0.05) | 38 | 0.14 (-0.01) | 5.32 (7.50) |
| 7 | TEN | 29 | 4.69 (3.97) | 45% (38%) | -0.14 (-0.10) | 33 | 0.01 (-0.16) | 5.84 (5.69) |
| 8 | PIT | 33 | 6.06 (4.83) | 55% (41%) | 0.34 (0.06) | 25 | -0.15 (-0.15) | 7.17 (5.83) |
| 9 | NO | 26 | 4.27 (2.97) | 38% (33%) | -0.01 (-0.16) | 45 | -0.06 (0.00) | 7.57 (6.22) |

## 2026 OFFENSE — CLE Cleveland Browns

Usage concentrations (share well above league avg at his position):
- Deshaun Watson (QB, 249 att): short left 37% (lg 26%)
- Dylan Sampson (RB, 17 tgt): short middle 29% (avg 17%)
- Raheim Sanders (RB, 12 tgt): short left 67% (avg 39%)
- KC Concepcion (WR, 55 tgt): short left 40% (avg 22%)
- Dylan Sampson (RB, 15 car): runs left end 27% (avg 10%); runs right end 20% (avg 9%)

Team passing context:

| stat | value |
|---|---|
| Dropbacks | 353 |
| EPA/dropback | -0.007 |
| Sack rate | 11% |
| Pressure rate faced (NGS) | – |
| EPA/db clean | – |
| EPA/db under pressure | – |
| Blitz rate faced (FTN) | 35% |
| EPA/db vs blitz | -0.089 |
| EPA/db vs no blitz | 0.037 |
| Pass rate over expected | -0.4 pts |

Opponent-adjusted run and pass, 2026 (expected = league avg + each opposing defense's adjusted rating from its other games; diff = gained − expected; adjusted = league avg + diff; rank 1 = best offense; thin = games where that rating rests on under 100 plays; method in README):

| stat | gained | expected | diff | adjusted | rank | games | thin |
|---|---|---|---|---|---|---|---|
| Run YPC | 3.51 | 3.89 | -0.38 | 3.70 | 26/32 | 9 | 0 |
| Run success rate | 36.1% | 39.8% | -3.7 | 36.7% | 21/32 | 9 | 0 |
| EPA/rush | -0.223 | -0.090 | -0.133 | -0.212 | 28/32 | 9 | 0 |
| EPA/dropback | -0.007 | 0.056 | -0.064 | -0.017 | 23/32 | 9 | 0 |
| YPA | 7.41 | 7.15 | +0.26 | 7.34 | 14/32 | 9 | 0 |
| Sack rate | 10.8% | 5.6% | +5.1 | 11.5% | 32/32 | 9 | 0 |

QB throw map (share of att, EPA/att in parentheses; ≥40 att):

| QB | att | short left | short middle | short right | int left | int middle | int right | deep left | deep middle | deep right |
|---|---|---|---|---|---|---|---|---|---|---|
| Deshaun Watson | 249 | 37% (-0.01) | 14% (0.06) | 23% (0.17) | 7% (0.45) | 4% (0.90) | 4% (0.10) | 5% (0.32) | 2% (-0.06) | 4% (0.78) |
| league | 8916 | 26% (0.02) | 12% (0.06) | 29% (0.01) | 7% (0.32) | 6% (0.60) | 8% (0.32) | 4% (0.33) | 2% (0.66) | 5% (0.40) |

Player usage, season totals (RZ opps = carries + targets inside the 10 / 5):

| player | pos | G | snap% avg | tgt | tgt share | air yds share | aDOT | rec-yds-TD | YAC/rec | MOF tgt% | car | car share | rush yds-TD | RZ10 opps | RZ5 opps | PPR | PPR/g |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Deshaun Watson | QB | 8 | 99% | 0 | 0% | 0% | – | 0-0-0 | – | – | 51 | 22% | 217-1 | 2 | 0 | 117.9 | 14.7 |
| Denzel Boston | WR | 9 | 91% | 60 | 22% | 42% | 14.5 | 32-507-3 | 5.0 | 23% | 0 | 0% | 0-0 | 7 | 4 | 102.7 | 11.4 |
| Harold Fannin Jr. | TE | 9 | 86% | 53 | 19% | 15% | 5.8 | 37-453-4 | 7.4 | 19% | 0 | 0% | 0-0 | 3 | 3 | 102.3 | 11.4 |
| Quinshon Judkins | RB | 8 | 54% | 24 | 9% | -2% | -1.7 | 22-136-0 | 8.0 | 17% | 116 | 50% | 385-3 | 14 | 9 | 92.1 | 11.5 |
| KC Concepcion | WR | 9 | 74% | 55 | 20% | 21% | 7.7 | 37-437-1 | 6.4 | 24% | 10 | 4% | 37-0 | 1 | 0 | 88.4 | 9.8 |
| Jerry Jeudy | WR | 8 | 60% | 28 | 10% | 13% | 9.9 | 18-208-0 | 2.4 | 18% | 0 | 0% | 0-0 | 0 | 0 | 38.8 | 4.8 |
| Dylan Sampson | RB | 4 | 42% | 17 | 6% | -1% | -0.8 | 12-121-0 | 10.4 | 29% | 15 | 6% | 73-0 | 0 | 0 | 31.4 | 7.9 |
| Shedeur Sanders | QB | 3 | 36% | 0 | 0% | 0% | – | 0-0-0 | – | – | 10 | 4% | 28-0 | 0 | 0 | 22.8 | 7.6 |
| Raheim Sanders | RB | 5 | 32% | 12 | 4% | -1% | -1.8 | 11-74-0 | 8.6 | 0% | 9 | 4% | 43-0 | 0 | 0 | 22.7 | 4.5 |
| Jaleel McLaughlin | RB | 5 | 15% | 6 | 2% | 0% | 0.8 | 4-14-0 | 3.2 | 33% | 11 | 5% | 72-1 | 0 | 0 | 18.6 | 3.7 |
| Blake Whiteheart | TE | 6 | 33% | 6 | 2% | 2% | 5.3 | 4-48-1 | 6.5 | 33% | 0 | 0% | 0-0 | 0 | 0 | 14.8 | 2.5 |
| Isaiah Bond | WR | 5 | 16% | 9 | 3% | 6% | 13.3 | 5-86-0 | 3.8 | 11% | 0 | 0% | 0-0 | 0 | 0 | 13.6 | 2.7 |
| Audric Estimé | RB | 1 | 30% | 0 | 0% | 0% | – | 0-0-0 | – | – | 9 | 4% | 19-1 | 3 | 2 | 7.9 | 7.9 |
| Tylan Wallace | WR | 4 | 18% | 3 | 1% | 0% | 0.0 | 3-21-0 | 7.0 | 0% | 0 | 0% | 0-0 | 0 | 0 | 5.1 | 1.3 |
| Michael Burton | RB | 3 | 14% | 2 | 1% | 0% | 0.0 | 0-0-0 | – | 50% | 1 | 0% | 2-0 | 0 | 0 | 0.2 | 0.1 |
| Malachi Corley | WR | 9 | 12% | 1 | 0% | -0% | -7.0 | 0-0-0 | – | 0% | 0 | 0% | 0-0 | 0 | 0 | 0.0 | 0.0 |

Target depth mix (air yards):

| player | behind LOS | 0-9 | 10-19 | 20+ |
|---|---|---|---|---|
| Jerry Jeudy | 7% | 46% | 39% | 7% |
| Blake Whiteheart | 0% | 100% | 0% | 0% |
| Jaleel McLaughlin | 50% | 50% | 0% | 0% |
| Dylan Sampson | 53% | 47% | 0% | 0% |
| Raheim Sanders | 92% | 8% | 0% | 0% |
| Harold Fannin Jr. | 25% | 53% | 17% | 6% |
| Isaiah Bond | 0% | 56% | 11% | 33% |
| Quinshon Judkins | 71% | 29% | 0% | 0% |
| Denzel Boston | 3% | 53% | 18% | 25% |
| KC Concepcion | 25% | 45% | 16% | 13% |

RB rushing by bucket (≥8 carries):

| RB | type | bucket | car | YPC | success | EPA/rush |
|---|---|---|---|---|---|---|
| Quinshon Judkins | formation | shotgun | 60 | 4.00 | 38% | -0.074 |
| Quinshon Judkins | formation | under center | 56 | 2.59 | 21% | -0.432 |
| Quinshon Judkins | box | 7 | 54 | 2.72 | 24% | -0.385 |
| Quinshon Judkins | box | 8+ | 8 | 2.12 | 25% | -0.825 |
| Quinshon Judkins | box | ≤6 | 54 | 4.09 | 37% | -0.023 |
| Quinshon Judkins | direction/gap | left end | 14 | 2.21 | 21% | -0.345 |
| Quinshon Judkins | direction/gap | left guard | 21 | 3.10 | 38% | -0.319 |
| Quinshon Judkins | direction/gap | left tackle | 14 | 4.00 | 14% | -0.306 |
| Quinshon Judkins | direction/gap | middle | 27 | 3.56 | 30% | -0.188 |
| Quinshon Judkins | direction/gap | right end | 7 | 2.86 | 29% | -0.191 |
| Quinshon Judkins | direction/gap | right guard | 21 | 4.14 | 38% | -0.150 |
| Quinshon Judkins | direction/gap | right tackle | 12 | 2.50 | 33% | -0.272 |
| Dylan Sampson | formation | shotgun | 5 | 3.80 | 40% | -0.302 |
| Dylan Sampson | formation | under center | 10 | 5.40 | 50% | 0.032 |
| Dylan Sampson | box | 7 | 8 | 5.88 | 50% | 0.071 |
| Dylan Sampson | box | ≤6 | 7 | 3.71 | 43% | -0.251 |
| Dylan Sampson | direction/gap | left end | 4 | 8.75 | 50% | 0.255 |
| Dylan Sampson | direction/gap | left guard | 1 | 7.00 | 100% | 0.260 |
| Dylan Sampson | direction/gap | left tackle | 3 | 3.67 | 67% | -0.119 |
| Dylan Sampson | direction/gap | middle | 3 | 3.33 | 33% | -0.332 |
| Dylan Sampson | direction/gap | right end | 3 | 1.67 | 0% | -0.447 |
| Dylan Sampson | direction/gap | right guard | 1 | 5.00 | 100% | 0.232 |
| Jaleel McLaughlin | formation | shotgun | 10 | 6.90 | 60% | 0.288 |
| Jaleel McLaughlin | formation | under center | 1 | 3.00 | 0% | -0.287 |
| Jaleel McLaughlin | box | 7 | 2 | 1.50 | 0% | -0.312 |
| Jaleel McLaughlin | box | 8+ | 1 | 3.00 | 0% | -0.287 |
| Jaleel McLaughlin | box | ≤6 | 8 | 8.25 | 75% | 0.437 |
| Jaleel McLaughlin | direction/gap | left guard | 1 | 5.00 | 100% | 0.069 |
| Jaleel McLaughlin | direction/gap | left tackle | 3 | 2.33 | 33% | -0.401 |
| Jaleel McLaughlin | direction/gap | middle | 1 | 4.00 | 0% | -0.115 |
| Jaleel McLaughlin | direction/gap | right end | 1 | 28.00 | 100% | 2.886 |
| Jaleel McLaughlin | direction/gap | right guard | 2 | 4.50 | 50% | -0.017 |
| Jaleel McLaughlin | direction/gap | right tackle | 3 | 6.33 | 67% | 0.328 |
| Raheim Sanders | formation | shotgun | 8 | 5.00 | 38% | 0.037 |
| Raheim Sanders | formation | under center | 1 | 3.00 | 0% | -0.471 |
| Raheim Sanders | box | 7 | 4 | 2.25 | 0% | -0.426 |
| Raheim Sanders | box | ≤6 | 5 | 6.80 | 60% | 0.306 |
| Raheim Sanders | direction/gap | left guard | 1 | 6.00 | 100% | 0.156 |
| Raheim Sanders | direction/gap | middle | 3 | 2.33 | 33% | -0.338 |
| Raheim Sanders | direction/gap | right end | 1 | 3.00 | 0% | -0.087 |
| Raheim Sanders | direction/gap | right guard | 3 | 3.33 | 0% | -0.305 |
| Raheim Sanders | direction/gap | right tackle | 1 | 17.00 | 100% | 1.686 |
| Audric Estimé | formation | shotgun | 3 | 2.33 | 67% | -0.120 |
| Audric Estimé | formation | under center | 6 | 2.00 | 33% | -0.125 |
| Audric Estimé | box | 7 | 3 | 2.33 | 33% | -0.407 |
| Audric Estimé | box | 8+ | 1 | 3.00 | 0% | -0.180 |
| Audric Estimé | box | ≤6 | 5 | 1.80 | 60% | 0.058 |
| Audric Estimé | direction/gap | left guard | 1 | -2.00 | 0% | -1.168 |
| Audric Estimé | direction/gap | left tackle | 3 | 3.00 | 33% | -0.182 |
| Audric Estimé | direction/gap | middle | 2 | 1.50 | 50% | -0.324 |
| Audric Estimé | direction/gap | right guard | 2 | 2.50 | 50% | 0.482 |
| Audric Estimé | direction/gap | right tackle | 1 | 4.00 | 100% | 0.288 |

Week by week usage:

| player | pos | wk | opp | snap% | tgt | tgt share | rec-yds-TD | aDOT | car | car share | rush yds-TD | PPR |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Audric Estimé | RB | 6 | BAL | 30% | 0 | 0% | 0-0-0 | – | 9 | 31% | 19-1 | 7.9 |
| Blake Whiteheart | TE | 1 | JAX | 39% | 1 | 5% | 1-14-0 | 6.0 | 0 | 0% | 0-0 | 2.4 |
| Blake Whiteheart | TE | 2 | TB | 47% | 2 | 7% | 1-17-1 | 3.0 | 0 | 0% | 0-0 | 8.7 |
| Blake Whiteheart | TE | 4 | PIT | 34% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Blake Whiteheart | TE | 6 | BAL | 27% | 1 | 4% | 1-8-0 | 7.0 | 0 | 0% | 0-0 | 1.8 |
| Blake Whiteheart | TE | 8 | PIT | 36% | 1 | 2% | 1-9-0 | 6.0 | 0 | 0% | 0-0 | 1.9 |
| Blake Whiteheart | TE | 9 | NO | 26% | 1 | 3% | 0-0-0 | 7.0 | 0 | 0% | 0-0 | 0.0 |
| Denzel Boston | WR | 1 | JAX | 92% | 4 | 18% | 2-59-1 | 28.5 | 0 | 0% | 0-0 | 13.9 |
| Denzel Boston | WR | 2 | TB | 93% | 7 | 23% | 5-95-1 | 8.6 | 0 | 0% | 0-0 | 20.5 |
| Denzel Boston | WR | 3 | CAR | 89% | 4 | 13% | 2-41-0 | 12.8 | 0 | 0% | 0-0 | 8.1 |
| Denzel Boston | WR | 4 | PIT | 95% | 7 | 21% | 4-89-0 | 22.6 | 0 | 0% | 0-0 | 12.9 |
| Denzel Boston | WR | 5 | NYJ | 91% | 7 | 22% | 3-46-1 | 13.4 | 0 | 0% | 0-0 | 13.6 |
| Denzel Boston | WR | 6 | BAL | 92% | 5 | 20% | 1-15-0 | 17.4 | 0 | 0% | 0-0 | 2.5 |
| Denzel Boston | WR | 7 | TEN | 87% | 8 | 23% | 3-27-0 | 16.8 | 0 | 0% | 0-0 | 5.7 |
| Denzel Boston | WR | 8 | PIT | 83% | 11 | 28% | 6-37-0 | 9.4 | 0 | 0% | 0-0 | 9.7 |
| Denzel Boston | WR | 9 | NO | 93% | 7 | 24% | 6-98-0 | 10.0 | 0 | 0% | 0-0 | 15.8 |
| Deshaun Watson | QB | 1 | JAX | 100% | 0 | 0% | 0-0-0 | – | 6 | 27% | 38-0 | 14.0 |
| Deshaun Watson | QB | 2 | TB | 100% | 0 | 0% | 0-0-0 | – | 7 | 30% | 22-0 | 19.7 |
| Deshaun Watson | QB | 3 | CAR | 99% | 0 | 0% | 0-0-0 | – | 11 | 37% | 45-0 | 20.3 |
| Deshaun Watson | QB | 4 | PIT | 100% | 0 | 0% | 0-0-0 | – | 7 | 26% | 22-0 | 12.9 |
| Deshaun Watson | QB | 5 | NYJ | 100% | 0 | 0% | 0-0-0 | – | 6 | 25% | 40-0 | 12.2 |
| Deshaun Watson | QB | 6 | BAL | 100% | 0 | 0% | 0-0-0 | – | 8 | 28% | 29-0 | 9.5 |
| Deshaun Watson | QB | 7 | TEN | 100% | 0 | 0% | 0-0-0 | – | 3 | 10% | 19-1 | 18.2 |
| Deshaun Watson | QB | 8 | PIT | 94% | 0 | 0% | 0-0-0 | – | 3 | 20% | 2-0 | 11.2 |
| Dylan Sampson | RB | 1 | JAX | 0% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Dylan Sampson | RB | 7 | TEN | 46% | 3 | 9% | 3-32-0 | -3.3 | 6 | 21% | 45-0 | 10.7 |
| Dylan Sampson | RB | 8 | PIT | 56% | 8 | 20% | 6-62-0 | 0.9 | 1 | 7% | 7-0 | 12.9 |
| Dylan Sampson | RB | 9 | NO | 64% | 6 | 21% | 3-27-0 | -1.7 | 8 | 24% | 21-0 | 7.8 |
| Harold Fannin Jr. | TE | 1 | JAX | 82% | 3 | 14% | 2-21-0 | 3.3 | 0 | 0% | 0-0 | 4.1 |
| Harold Fannin Jr. | TE | 2 | TB | 86% | 6 | 20% | 5-54-0 | 4.0 | 0 | 0% | 0-0 | 10.4 |
| Harold Fannin Jr. | TE | 3 | CAR | 86% | 9 | 30% | 7-51-2 | 8.3 | 0 | 0% | 0-0 | 24.1 |
| Harold Fannin Jr. | TE | 4 | PIT | 89% | 5 | 15% | 3-27-1 | 6.2 | 0 | 0% | 0-0 | 11.7 |
| Harold Fannin Jr. | TE | 5 | NYJ | 93% | 4 | 12% | 1-4-0 | 8.5 | 0 | 0% | 0-0 | 1.4 |
| Harold Fannin Jr. | TE | 6 | BAL | 89% | 3 | 12% | 1-9-0 | 3.3 | 0 | 0% | 0-0 | 1.9 |
| Harold Fannin Jr. | TE | 7 | TEN | 83% | 9 | 26% | 6-91-0 | 4.2 | 0 | 0% | 0-0 | 13.1 |
| Harold Fannin Jr. | TE | 8 | PIT | 86% | 12 | 30% | 10-154-0 | 7.0 | 0 | 0% | 0-0 | 23.4 |
| Harold Fannin Jr. | TE | 9 | NO | 84% | 2 | 7% | 2-42-1 | 1.5 | 0 | 0% | 0-0 | 12.2 |
| Isaiah Bond | WR | 2 | TB | 7% | 1 | 3% | 1-10-0 | 7.0 | 0 | 0% | 0-0 | 2.0 |
| Isaiah Bond | WR | 4 | PIT | 11% | 1 | 3% | 1-2-0 | 2.0 | 0 | 0% | 0-0 | 1.2 |
| Isaiah Bond | WR | 5 | NYJ | 72% | 7 | 22% | 3-74-0 | 15.9 | 0 | 0% | 0-0 | 10.4 |
| Isaiah Bond | WR | 8 | PIT | 11% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Isaiah Bond | WR | 9 | NO | 0% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Jaleel McLaughlin | RB | 2 | TB | 14% | 1 | 3% | 0-0-0 | 1.0 | 1 | 4% | 3-0 | 0.3 |
| Jaleel McLaughlin | RB | 4 | PIT | 2% | 0 | 0% | 0-0-0 | – | 1 | 4% | 28-1 | 8.8 |
| Jaleel McLaughlin | RB | 5 | NYJ | 21% | 1 | 3% | 0-0-0 | 3.0 | 0 | 0% | 0-0 | 0.0 |
| Jaleel McLaughlin | RB | 6 | BAL | 62% | 4 | 16% | 4-14-0 | 0.2 | 9 | 31% | 41-0 | 9.5 |
| Jaleel McLaughlin | RB | 7 | TEN | 0% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Jerry Jeudy | WR | 1 | JAX | 63% | 4 | 18% | 2-26-0 | 10.0 | 0 | 0% | 0-0 | 4.6 |
| Jerry Jeudy | WR | 2 | TB | 59% | 1 | 3% | 0-0-0 | 10.0 | 0 | 0% | 0-0 | 0.0 |
| Jerry Jeudy | WR | 4 | PIT | 38% | 3 | 9% | 3-36-0 | 7.7 | 0 | 0% | 0-0 | 6.6 |
| Jerry Jeudy | WR | 5 | NYJ | 81% | 7 | 22% | 3-19-0 | 8.9 | 0 | 0% | 0-0 | 4.9 |
| Jerry Jeudy | WR | 6 | BAL | 62% | 4 | 16% | 4-69-0 | 13.5 | 0 | 0% | 0-0 | 10.9 |
| Jerry Jeudy | WR | 7 | TEN | 61% | 4 | 11% | 4-21-0 | 4.5 | 0 | 0% | 0-0 | 6.1 |
| Jerry Jeudy | WR | 8 | PIT | 60% | 1 | 2% | 0-0-0 | 8.0 | 0 | 0% | 0-0 | 0.0 |
| Jerry Jeudy | WR | 9 | NO | 68% | 4 | 14% | 2-37-0 | 15.2 | 0 | 0% | 0-0 | 5.7 |
| KC Concepcion | WR | 1 | JAX | 69% | 5 | 23% | 4-43-0 | 12.6 | 3 | 14% | 15-0 | 7.8 |
| KC Concepcion | WR | 2 | TB | 66% | 6 | 20% | 6-28-0 | 2.0 | 1 | 4% | -6-0 | 8.2 |
| KC Concepcion | WR | 3 | CAR | 86% | 9 | 30% | 2-9-0 | 4.0 | 0 | 0% | 0-0 | 2.9 |
| KC Concepcion | WR | 4 | PIT | 92% | 8 | 24% | 5-64-0 | 7.8 | 0 | 0% | 0-0 | 11.4 |
| KC Concepcion | WR | 5 | NYJ | 16% | 1 | 3% | 1-5-0 | 3.0 | 0 | 0% | 0-0 | 1.5 |
| KC Concepcion | WR | 6 | BAL | 81% | 6 | 24% | 4-37-0 | 9.2 | 2 | 7% | 2-0 | 7.9 |
| KC Concepcion | WR | 7 | TEN | 79% | 10 | 29% | 8-129-0 | 11.0 | 3 | 10% | 23-0 | 23.2 |
| KC Concepcion | WR | 8 | PIT | 83% | 4 | 10% | 3-37-0 | 5.2 | 0 | 0% | 0-0 | 6.7 |
| KC Concepcion | WR | 9 | NO | 93% | 6 | 21% | 4-85-1 | 10.5 | 1 | 3% | 3-0 | 18.8 |
| Malachi Corley | WR | 1 | JAX | 0% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Malachi Corley | WR | 2 | TB | 0% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Malachi Corley | WR | 3 | CAR | 1% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Malachi Corley | WR | 4 | PIT | 22% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Malachi Corley | WR | 5 | NYJ | 24% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Malachi Corley | WR | 6 | BAL | 11% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Malachi Corley | WR | 7 | TEN | 20% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Malachi Corley | WR | 8 | PIT | 19% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Malachi Corley | WR | 9 | NO | 12% | 1 | 3% | 0-0-0 | -7.0 | 0 | 0% | 0-0 | 0.0 |
| Michael Burton | RB | 3 | CAR | 21% | 1 | 3% | 0-0-0 | 2.0 | 0 | 0% | 0-0 | 0.0 |
| Michael Burton | RB | 5 | NYJ | 1% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Michael Burton | RB | 6 | BAL | 16% | 1 | 4% | 0-0-0 | -2.0 | 1 | 3% | 2-0 | 0.2 |
| Quinshon Judkins | RB | 1 | JAX | 65% | 2 | 9% | 2-17-0 | 0.5 | 12 | 55% | 33-0 | 7.0 |
| Quinshon Judkins | RB | 2 | TB | 67% | 5 | 17% | 5-27-0 | -1.6 | 12 | 52% | 21-0 | 9.8 |
| Quinshon Judkins | RB | 3 | CAR | 51% | 2 | 7% | 2-9-0 | -3.0 | 18 | 60% | 70-0 | 9.9 |
| Quinshon Judkins | RB | 4 | PIT | 66% | 7 | 21% | 6-43-0 | -2.1 | 17 | 63% | 53-1 | 21.6 |
| Quinshon Judkins | RB | 5 | NYJ | 53% | 4 | 12% | 3-6-0 | -0.2 | 14 | 58% | 44-0 | 8.0 |
| Quinshon Judkins | RB | 7 | TEN | 53% | 1 | 3% | 1-8-0 | 0.0 | 17 | 59% | 96-2 | 23.4 |
| Quinshon Judkins | RB | 8 | PIT | 39% | 2 | 5% | 2-24-0 | -3.5 | 11 | 73% | 25-0 | 6.9 |
| Quinshon Judkins | RB | 9 | NO | 34% | 1 | 3% | 1-2-0 | -5.0 | 15 | 44% | 43-0 | 5.5 |
| Raheim Sanders | RB | 1 | JAX | 35% | 3 | 14% | 3-25-0 | -2.0 | 1 | 5% | 1-0 | 5.6 |
| Raheim Sanders | RB | 2 | TB | 19% | 1 | 3% | 1-7-0 | -4.0 | 2 | 9% | 4-0 | 2.1 |
| Raheim Sanders | RB | 3 | CAR | 43% | 5 | 17% | 4-34-0 | 0.8 | 1 | 3% | 17-0 | 9.1 |
| Raheim Sanders | RB | 4 | PIT | 34% | 2 | 6% | 2-7-0 | -5.0 | 2 | 7% | 9-0 | 3.6 |
| Raheim Sanders | RB | 5 | NYJ | 29% | 1 | 3% | 1-1-0 | -6.0 | 3 | 12% | 12-0 | 2.3 |
| Shedeur Sanders | QB | 3 | CAR | 1% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Shedeur Sanders | QB | 8 | PIT | 6% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.1 |
| Shedeur Sanders | QB | 9 | NO | 100% | 0 | 0% | 0-0-0 | – | 10 | 29% | 28-0 | 22.7 |
| Tylan Wallace | WR | 3 | CAR | 20% | 0 | 0% | 0-0-0 | – | 0 | 0% | 0-0 | 0.0 |
| Tylan Wallace | WR | 6 | BAL | 16% | 1 | 4% | 1-12-0 | -1.0 | 0 | 0% | 0-0 | 2.2 |
| Tylan Wallace | WR | 8 | PIT | 14% | 1 | 2% | 1-3-0 | -2.0 | 0 | 0% | 0-0 | 1.3 |
| Tylan Wallace | WR | 9 | NO | 8% | 1 | 3% | 1-6-0 | 3.0 | 0 | 0% | 0-0 | 1.6 |

Game by game, 2026: gained (expected vs that defense; * = its rating rests on under 100 plays):

| wk | opp | rush | YPC | success | EPA/rush | db | EPA/db | YPA |
|---|---|---|---|---|---|---|---|---|
| 1 | JAX | 19 | 3.53 (3.91) | 42% (36%) | -0.12 (-0.18) | 30 | -0.23 (-0.11) | 9.32 (7.14) |
| 2 | TB | 18 | 1.78 (3.67) | 22% (36%) | -0.57 (-0.13) | 35 | 0.31 (-0.27) | 7.93 (6.41) |
| 3 | CAR | 23 | 3.87 (4.45) | 30% (41%) | -0.29 (-0.00) | 39 | 0.14 (0.08) | 4.50 (6.73) |
| 4 | PIT | 23 | 3.74 (3.14) | 35% (33%) | -0.23 (-0.15) | 37 | 0.30 (0.04) | 8.12 (6.83) |
| 5 | NYJ | 21 | 2.86 (4.22) | 24% (47%) | -0.42 (-0.07) | 44 | -0.24 (0.19) | 4.70 (7.06) |
| 6 | BAL | 23 | 2.91 (3.48) | 52% (38%) | 0.02 (-0.13) | 37 | -0.21 (0.11) | 6.31 (7.69) |
| 7 | TEN | 28 | 6.29 (3.94) | 54% (40%) | 0.24 (-0.10) | 38 | 0.07 (0.22) | 8.56 (8.09) |
| 8 | PIT | 13 | 2.46 (3.14) | 23% (33%) | -0.52 (-0.15) | 50 | -0.21 (0.04) | 7.95 (6.83) |
| 9 | NO | 26 | 2.77 (4.66) | 31% (49%) | -0.41 (0.04) | 43 | 0.06 (0.12) | 9.58 (7.68) |
