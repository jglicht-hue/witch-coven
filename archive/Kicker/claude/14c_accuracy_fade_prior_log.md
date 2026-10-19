# 14c — Kicker accuracy: fade × weight and a two-sided blend (to-do #18, 2026-09-29)

Script: `claude/14c_accuracy_fade_prior_experiments.R`. This is an experiment only; nothing in the pipeline changed. It follows `claude/v1.1_14_fg_shrinkage_log.md`.

## Question

This is the user's hypothesis. Most kickers' accuracy is noise, but a subset is truly better, and a model tuned on everyone may under-credit them.

Three questions follow from it:
1. Does a longer memory (fade), combined with a different blend weight, rank kickers better?
2. Does a two-sided blend help? That means separate weights for above-league and below-league records, plus a lower starting point for kickers with no record.
3. What does the user's prior cost or gain? The prior is that good kickers keep at least 2/3 of their edge and new kickers aren't docked.

## Rules (set with the user before any results were seen)

- **Sample:** every kicker-game in the 2016–2025 regular season: 5,278 kicker-games over 175 weeks, 2,800 of them in the pre-game top 16.
  - Each game uses the 4-season window a live run would use.
  - The volume models are unchanged; only the FG make chances change.
  - Blocked kicks count as misses.
- **Decides:** the pairwise hit rate within the pre-game top 16. For pairs of top-16 kickers in the same week, it's the share where the higher projection scored more. Pairs with equal actual points are left out.
- **Guardrail:** the hit rate across all kickers must not be worse in 95% or more of bootstrap resamples.
- **Adopt only if** all three hold, with the setting chosen leave-one-season-out (picked on 9 seasons, scored on the 10th):
  1. it's better in at least 95% of 2,000 week-block bootstrap resamples;
  2. it's better in at least 7 of 10 held-out seasons;
  3. the guardrail holds.
- **Test C:** half-life of 12, 24 or 48 games, or no fade, crossed with weights 2, 5, 10, 20, 35, 50, 100, 200 and ∞. It challenges the current setting (12, 5).
- **Test D:** a good-record weight of 2, 5, 10, 20, 35 or 50; a bad-record weight of 5, 20, 50, 100 or ∞; and a new-kicker start 0, 1, 2 or 3 points below league. The fade is free. It challenges Test C's winner, or the current setting if C fails.
  - The new-kicker dock is δ × 10 / (N + 10), where N is the kicker's decayed FG attempts in all ranges. With no record he gets the full δ; after 10 effective kicks, half; after 30, a quarter.
- **Reported, not deciding:**
  - the best setting where good records keep at least 2/3 of their edge (good-record weight ≤ 5);
  - the best setting with no new-kicker dock;
  - the Brier score (the make/miss error).

## Checks

- Fade 12 with weight 5 reproduces 09's make chances exactly.
- Data fix: nflverse play-by-play uses today's codes for relocated teams (LV, LAC, LA), but the schedule file keeps OAK, SD and STL. Without aligning them, those teams' games and their opponents' dropped out of pre-2020 weeks; in 2016, 63 of 512 team-games were missing. The script aligns the codes.
  - This doesn't affect the live pipeline, since 2023–2026 use current codes.
  - It did drop some OAK and opponent games from 2019 in `14_fg_shrinkage_experiments.R`. That test's conclusions don't hinge on them.

## Results: nothing passes, so the current setting stays (12-game fade, weight 5, one weight for all, no dock)

| Held-out comparison | Top-16 hit rate, new vs base | Difference | Share not better | Seasons better | All-kicker difference | Pass |
|---|---|---|---|---|---|---|
| C: fade × weight vs current | 0.5562 vs 0.5556 | +0.0007 | 0.27 | 6/10 | +0.0001 | no |
| D: two-sided + new-kicker start vs current | 0.5549 vs 0.5556 | −0.0006 | 0.68 | 5/10 | +0.0001 | no |
| Info: good kickers keep ≥ 2/3 vs current | 0.5543 vs 0.5556 | −0.0012 | 0.87 | 2/10 | +0.0001 | — |
| Info: no new-kicker dock vs current | 0.5567 vs 0.5556 | +0.0012 | 0.19 | 6/10 | +0.0002 | — |

Settings picked leave-one-season-out:
- **Test C:** a 24-game fade with weight 5, in all 10 seasons. It's the consistent in-sample favorite, but its held-out gain (+0.0007) is within noise.
- **Test D:** mostly a 24-game fade, good-record weight 10, bad-record weight 5, with a dock of 0–3 that varies by season.
- **Bad-record weight:** 5 in every pick. Pulling bad records toward league never helped ranking.

### Top-16 hit rate by fade × weight (full sample)

| Weight | 12 | 24 | 48 | none |
|---|---|---|---|---|
| 2 | 0.5522 | 0.5537 | 0.5537 | 0.5525 |
| **5** | **0.5556** | **0.5562** | 0.5548 | 0.5541 |
| 10 | 0.5549 | 0.5549 | 0.5540 | 0.5534 |
| 20 | 0.5538 | 0.5536 | 0.5529 | 0.5531 |
| 35 | 0.5524 | 0.5531 | 0.5529 | 0.5526 |
| 50 | 0.5514 | 0.5525 | 0.5531 | 0.5524 |
| 100 | 0.5515 | 0.5521 | 0.5522 | 0.5519 |
| ∞ (league rate) | 0.5507 | 0.5507 | 0.5507 | 0.5507 |

### Brier ×1000 by fade × weight

| Weight | 12 | 24 | 48 | none |
|---|---|---|---|---|
| 5 | 119.26 | 119.55 | 119.82 | 120.23 |
| 20 | 117.56 | 117.76 | 117.96 | 118.29 |
| 50 | 117.37 | 117.43 | 117.50 | 117.66 |
| 100 | 117.39 | 117.40 | 117.43 | 117.49 |
| ∞ | 117.51 | 117.51 | 117.51 | 117.51 |

### Does kicker accuracy help ranking within the top 16?

This is a follow-up comparison at a 12-game fade, not part of the pre-set tests.

| Comparison | Top 16 | All kickers |
|---|---|---|
| Weight 5 minus weight 35 | +0.0032 (90% range −0.0005 to +0.0071; not better in 8% of resamples; better in 8/10 seasons) | +0.0010 (not better in 23%; 6/10) |
| Weight 5 minus ∞ (accuracy ignored) | **+0.0049** (90% range −0.0004 to +0.0099; not better in 6.6%; **better in 9/10 seasons**) | +0.0021 (not better in 13%; 6/10) |

## Reading

- **The user's intuition holds for ranking.** Among top-16 kickers, crediting each kicker's own accuracy (weight 5) ranks better than blending heavily or ignoring it. Ignoring it loses about 0.5 points of hit rate, in 9 of 10 seasons, just short of the 95% bar. The earlier w = 35 proposal would have cost about 0.3 points in the top-16 pool.
- **Ranking and Brier want different things.** Heavier blending predicts the level of make/miss better. Lighter blending orders kickers better, especially at the top. Ranking is the stated priority, so weight 5 stays.
- **The current setting already matches the user's prior.** With a weight of 5, a kicker with 10 effective kicks in a range keeps 2/3 of his edge, and one with 20 keeps 80%.
- **The two-sided blend didn't help ranking.** Pulling bad records to league (the Brier-driven idea from the 14b diagnostic) never won a pick. Docking new kickers had no reliable effect, consistent with the user's hesitation. The no-dock family did slightly better held-out.
- **A 24-game fade** is a consistent but unproven favorite. Recheck it after the 2026 season, when another season of data is available.
