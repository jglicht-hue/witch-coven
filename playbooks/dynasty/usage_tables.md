# Dynasty Witch playbook: usage tables, the reading and the team-context table

Read before building any usage table or team-context table. Part of the Dynasty Witch instructions (v3.10). Moved from v3.9 OUTPUT FORMAT items 2 and 3 and guardrail 23.

## Usage table
**Weekly through the latest completed week:**
- **WR and TE:** snap share · route share · targets with target share · targets per route run · share of team first-read targets · yards per route run · first downs per route run.
- **RB:** snap share · carries with carry share · carries inside the 5 · red-zone carry share · route share · targets · weighted opportunity per game.
- **Caption:** the source of each column, the weeks the first-read data covers, and the season and sample behind any benchmark quoted. A missing route count reads "not found."
- **Teammates share the table.** When a player shares a target pie or a backfield with a player we roster, or with another player in the question, both go in the same usage table.
- **The reading.** Directly under the usage table, a short list that says, for each player: which way each column moved week to week and what the movement is made of; what each early figure usually settles to (`data_sources.md`, benchmarks); and where each figure sits against the benchmark bands, with its league rank. For a TE or an RB, use v2's TE and RB bands, and say that the per-route bands for both rest on 2025 alone. For an RB, the lean follows route share and weighted opportunity (guardrail 16).
- **For a receiver or tight end in his first or second season,** add the season line in `stash.md`.

## Team-context table (guardrail 23)
**Always a table**, never a list or a sentence, one row per team, computed with the offense script over completed weeks only. Columns:
- team points per game with league rank (a tie for last reads as 32nd)
- opponent-adjusted scoring with league rank: for each game, points scored minus the average that opponent allowed in its other games, averaged across the team's games
- volume, left raw: dropbacks per game for pass catchers, rushing attempts per game for RBs
- the diagnosis columns, from `offense_diag.py`: yards per play, giveaways per game and sack rate, each with league rank
- The caption gives the weeks covered. Until about Week 6 it also carries a thin-sample note on the adjusted figure.
- Under the table, one line that says which kind of bad or good offense this is: it can't move the ball, it moves the ball and gives it away, or it can't protect the QB.
