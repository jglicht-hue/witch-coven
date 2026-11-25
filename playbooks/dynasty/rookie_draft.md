# Dynasty Witch playbook: rookie picks and the rookie draft

Read for any question about a rookie pick (its value, a trade involving one) and for the rookie draft itself. Part of the Dynasty Witch instructions (v4.3). Text moved from v3.9 (moon rules, LEAGUE SETTINGS, TEAM STRATEGY and rule 3). v4 moved rule 2's hit rates here and v4.3 added the tank sim; the instructions keep the four tiers' names.

## 2. The four tiers and their hit rates
Share with at least one viable season / one elite season in their first two years (Leone, by rookie-draft slot):
- **Top 4:** 70% / 50%
- **Picks 5 to 8:** 38% / 23%
- **Picks 9 to 12, together with early seconds:** 35% / 13% for the firsts, 20% / 12% for early seconds
- **Late seconds, together with thirds:** 15% / 3% for late seconds, about 15% / 8% for thirds
- "Early" means picks 1 to 6 of the rookie round, which in this league means the pick came from a team that missed the playoffs.

## Moon phase for a rookie pick
- The three inputs are its tier rate from the brief (rule 2), Boone's pick chart, and the DynastyProcess pick value, which is the consensus in value form.
- Establish The Run's pick value is shown beside them but isn't an input, because it prices each rookie round once, with no early, mid or late.
- For a pick, the new moon reads: its tier rate is missing, or both Boone's pick chart and the DynastyProcess value are missing.
- For a ranking or superlative about picks (guardrail 14), use these inputs.

## Draft order
- **Rookie draft:** 4 rookie rounds, **linear** (the same order in every rookie round, not a snake).
- Order (owner, Oct 21; flag A1 closed): the six teams that miss the playoffs pick 1 to 6 in order of lowest maximum points (Sleeper's Max PF, the best possible lineup each week). The six playoff teams pick 7 to 12, with the champion last. The playoff field is set by record.
- So our own pick moves with roster strength (Max PF), not with the lineup we start; the lineup matters only for staying out of the playoffs.
- Because the order repeats, a team that misses the playoffs picks in the first half of every rookie round.
- Track our Max PF against the other teams likely to miss the playoffs.

## The tank sim (the tank, our finish, next season's picks)
- **Read the newest Tank Plan first** (`claude/v*_Tank_Plan_and_2027_Draft.md`, project doc). Its sim section gives the run date, the latest complete week it used, and the results. Quote those numbers with that week.
- **Rerun only when** a week has been completed since that run, or something notable has changed since it: a trade or roster move on a team that touches our picks (every team but Efton, McBride or Die and jrogers617), a new multi-week injury to an 8+ point-a-game player on one of those teams, or the owner asks for a rerun or a new scenario. Otherwise don't run it.
- **A rerun** needs the owner's go (opening routine) and the Sleeper data store, with `matchups_<week>` for every remaining week through Week 14; ask in one line for anything missing. Steps and method: `coven/dynasty/tank_sim/README_tank_sim.md`. Start from the scenarios file saved in the newest Tank Plan, not the repo copy, change only what changed, and say what changed.
- **Save as you go:** in the same reply, save the next Tank Plan version with its sim section replaced: run date, latest complete week, data store version, what changed since the last run, the results table, and the full scenarios file as run. The next chat reads that instead of redoing the week's injury sweep.
- If the sim can't run, quote the newest Tank Plan with its data week, marked as not current.

## Valuing a pick
- By tier (rule 2) and by the record of the team it came from. Re-check that team's standing each time.
- **Missing the playoffs** puts our own second in the early half of rookie round 2, where the elite-season rate is about 12% against 3% for a late second.
- **A bottom-four finish** makes our own first a top-4 pick, where both hit rates roughly double.
- The pick row of the status table gives the rookie round and year, the team it came from with that team's record, its projected tier (rule 2), and its KTC, Establish The Run and Boone values.

## 3. In the rookie draft
- **Rookie round 1:** a receiver for safety or an RB for upside.
- **Rookie rounds 2 and 3:** compare the candidates on the clock by NFL round and position, using the ladder in section 2 of the brief. Then adjust for landing spot and profile.
- **For an RB, profile means receiving first** (owner, Oct 31; brief v2.15, section 8): final-season college catches per game, with team target share and receiving-yard share beside it. Catches per game is the only trait that adds signal once the NFL pick is known, and the edge is biggest in NFL rounds 3 and 4.
- **The ladder's rows are tiers** (owner, Oct 3). A gap of 15 to 20 picks, or one side of an NFL round boundary, isn't a reason on its own.
- **The caveat goes with every use of the ladder:** its rates cover every player from that NFL round, including ones nobody takes in a rookie draft. A player the market has singled out probably has better odds than his row says. The rate is the starting point.
- Leone's tables are by rookie-draft slot; the ladder is by NFL round. Never carry a rate across (guardrail 18).
- For each candidate, the profile (`profiles.md`) gives his NFL draft capital row from section 5 of the brief.
