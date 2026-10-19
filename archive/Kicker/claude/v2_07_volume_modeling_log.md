# Volume model testing log — v2

As of 2026-09-23. **What changed from v1:**
- The noise estimate is explained and checked with a placebo test. That test showed the v1 cutoff (z ≈ 2) was too strict.
- The noise estimate now treats the two teams in a game as one unit, since they share venue and conditions.
- Every model is also scored on top-16 kickers, in two ways (see the column key).
- Two new predictors are tested: pooled 40+ kicker accuracy, and the coach's long-range FG rate. The coach rate is pending: you need to run `07b_pull_coach_long_fg_rate.R`.
- The 50+ recommendation changes.
- There's a column key for the results files.

Covers every model tested for the volume side of the projection: how many XP attempts and FG attempts (total and by 0-39 / 40-49 / 50+ range) a team gets in a game. Everything is reproducible with `07a_volume_model_experiments.R`, which writes `data/volume_experiment_results.csv` (146 models) and `data/volume_experiment_placebo.csv`.

## Where things stand

| Outcome | Recommended model | Gain vs league average: all kickers / top-16 scored / top-16 fit + scored | Evidence |
|---|---|---|---|
| XP attempts | Implied team total | +155.0 / +172.3 / +163.2 | Strong |
| 0-39 FG attempts | Implied total + its square | +10.7 / +10.1 / +4.7 | Real (placebo: 0 of 300 shuffles matched the squared term) |
| 40-49 FG attempts | League average (no predictors) | — | Nothing beats it for all kickers. Top-16 exception below. |
| 50+ FG attempts | **Dome + kicker 40+ accuracy** (changed from dome + 50+ accuracy) | +21.0 / +24.2 / +17.4 | Real (placebo: 0 of 300 shuffles matched 40+ accuracy) |

Open choices:
- **Add dome × kicker 50+ accuracy to the 50+ model?** It adds +2.3 (all) and +2.2 (top-16) on top of dome + 40+ accuracy. The placebo result is borderline: 3–5% of shuffles did as well, depending on the random draw. It matters most for elite kickers in domes: predicted 50+ attempts per game go from 0.75 to 0.83 with it. That estimate rests on only 56 dome team-games with a kicker at 80%+ from 50.
- **Top-16 exception for 40-49: dome × kicker 40-49 accuracy.** For all kickers it's worse than the league average (-3.2). Scored on top-16 kickers it's +5.4, and fit only on top-16 kickers it's +13.1. It's the same shape as the 50+ finding: indoors, a trusted kicker gets more long tries; outdoors, accuracy barely matters. The catch is that the top-16-only fit selects rows on the outcome (see caveats).
- **Coach long-range FG rate:** pending. Run `07b_pull_coach_long_fg_rate.R`, put its CSV in `data/`, and rerun 07a.

## How to read the numbers

Every model is scored the same way: fit on two seasons, predict the third, rotate through 2023, 2024 and 2025 (1,594 regular-season team-games; 789 of them have a top-16 kicker).

- **Error**: mean Poisson deviance per held-out team-game, ×1000. Lower = better. For scale, guessing the league average gives about 1,000–1,130, depending on the outcome.
- **Gain**: the reference model's error minus this model's error, on the same team-games. Positive = this model predicts better.
- **Rule of thumb from the placebo test:** a meaningless extra term scores about **-0.9** on average, and 95% of the time scores below about **+2.5** (all kickers) or **+3.5** (top-16). A gain below those levels can't be told apart from a useless term. A gain above them is worth a placebo check, which is the real test.
- **x/3**: in how many of the three held-out seasons the model beat its reference. On its own this is weak evidence: 3/3 happens by luck about 1 time in 8.

### The noise estimate, and why it was checked

Each held-out team-game gets an error from both models, and the gain is the average difference. A single game's difference swings a lot: a kicker gets 0 attempts or 4. So the average bounces depending on which games happen to be in the sample. With gains this small (a few thousandths of the error), a single number can't separate a real improvement from luck.

**Formula version (gain_se, gain_z).** The standard error of an average: the spread of the per-game differences divided by the square root of the number of independent units. The two teams in a game are counted as one unit, since they share venue and conditions. v1 counted them separately, which made the standard error slightly too small.

**Placebo version (the direct check).** Take the variable being tested, shuffle its values among team-games within each season, and fit the model with the shuffled version. It keeps the same values and distribution but has no real link to the outcome. Repeating that 300 times shows exactly how big a "gain" a meaningless term produces. The share of shuffles that did at least as well as the real variable is an empirical p-value.

| Comparison | Real gain (all) | Shuffled: average / 95th pct | Share of shuffles ≥ real | Real gain (top-16) | Shuffled 95th pct (top-16) | Share ≥ real (top-16) |
|---|---|---|---|---|---|---|
| 50+: kicker 40+ accuracy added to dome | +14.2 | -1.0 / +1.6 | 0.000 | +14.7 | +3.0 | 0.000 |
| 50+: kicker 50+ accuracy added to dome | +7.2 | -0.9 / +1.6 | 0.000 | +10.7 | +2.4 | 0.000 |
| 50+: add kicker 40-49 accuracy to dome + 50+ accuracy | +5.8 | -0.9 / +1.8 | 0.003 | +2.9 | +2.7 | 0.050 |
| 50+: dome × kicker 50+ accuracy (on dome + 50+ accuracy) | +3.5 | -0.9 / +1.5 | 0.010 | +2.9 | +1.8 | 0.027 |
| 50+: dome × kicker 50+ accuracy (on dome + 40+ accuracy) | +2.3 | -0.7 / +2.4 | 0.053 | +2.2 | +3.4 | 0.087 |
| 50+: dome × kicker 40+ accuracy (on dome + 40+ accuracy) | -0.3 | -0.9 / +1.0 | 0.373 | -0.3 | +2.3 | 0.353 |
| 40-49: dome × kicker 40-49 accuracy (on dome + 40-49 accuracy) | +1.8 | -1.0 / +1.8 | 0.050 | +7.1 | +3.4 | 0.017 |
| 0-39: implied total squared term (on implied total) | +9.6 | -0.8 / +1.8 | 0.000 | +11.9 | +2.5 | 0.000 |

**What the check showed:** the formula was too strict, for two reasons.
1. A useless term doesn't score 0. It costs about 0.9 on average, from fitting noise. The formula measures from 0, so every real gain looked about 0.9 smaller than it is.
2. The formula's spread also includes uncertainty about how big a real effect is. That's relevant for "how much better will it be next season", but it makes the formula a harsh test of "is there any real signal at all".

So for the yes/no question "does this predictor carry real signal?", trust the placebo. That's how v1 wrongly waved off dome × 50+ accuracy: its formula z was only 1.4, but it beat 99% of the shuffles.

**Why this wasn't included before:** it should have been. The first round of comparisons used single held-out numbers plus the count of seasons won, which is too crude for gains this small. v1 added the formula version, and v2 adds the placebo check that the formula needed.

**Remaining caution:** about 146 models have been scored on the same three seasons. At a 5% bar, several meaningless terms would pass by luck across that many tries. Findings that pass the placebo *and* have a sensible mechanism *and* show up consistently (e.g. the same indoor pattern at both 40-49 and 50+) deserve more trust than a single borderline pass.

## 50+ attempts: the candidates head to head

Gain vs league average (seasons better in brackets):

| Model | All kickers | Top-16 (scored) | Top-16 (fit + scored) |
|---|---|---|---|
| Dome + kicker 50+ accuracy (v1 proposal) | +14.0 (3/3) | +20.3 (2/3) | +16.7 (2/3) |
| **Dome + kicker 40+ accuracy** | **+21.0 (3/3)** | **+24.2 (2/3)** | **+17.4 (2/3)** |
| Dome × kicker 50+ accuracy | +17.5 (3/3) | +23.2 (2/3) | +18.7 (2/3) |
| Dome × kicker 40+ accuracy | +20.7 (3/3) | +23.9 (2/3) | +18.0 (2/3) |
| Dome × kicker 50+ accuracy + kicker 40-49 accuracy | +22.8 (3/3) | +25.4 (2/3) | +19.0 (2/3) |
| Dome + kicker 40+ accuracy + dome × kicker 50+ accuracy | +23.3 (3/3) | +26.4 (2/3) | +19.3 (2/3) |

Why pooled 40+ accuracy works: a kicker's 40-49 and 50+ accuracy are almost uncorrelated game to game (r = 0.03). Each is a noisy read on the same thing, long-range leg strength, and pooling them cuts the noise. The three larger models beat dome + 40+ accuracy by only 1.8–2.3. That's within placebo range, so the simpler model is recommended unless you want the dome interaction (see open choices).

Predicted 50+ attempts per game. Kicker profiles use matching percentiles of 40+ and 50+ accuracy, which move together over a season (r = 0.7):

| Kicker | 40+ / 50+ accuracy | Outdoors: without / with dome × 50+ | Dome: without / with dome × 50+ |
|---|---|---|---|
| Weak (10th pct) | 65% / 58% | 0.33 / 0.34 | 0.44 / 0.39 |
| Average (50th) | 75% / 69% | 0.42 / 0.42 | 0.57 / 0.55 |
| Strong (75th) | 81% / 75% | 0.48 / 0.47 | 0.65 / 0.67 |
| Elite (95th) | 87% / 83% | 0.55 / 0.53 | 0.75 / 0.83 |

## Top-16 kickers: what looks different

The top 16 are ranked by that season's fantasy points (3/4/5 per make by range, -1 per miss, +1 per XP). "Scored" = models fit on all kickers, judged only on top-16 kickers' games. "Fit + scored" = models fit and judged on top-16 kickers only, i.e. the bad kickers are removed entirely.

- **XP:** no change. Implied total dominates (+172.3 top-16 scored). The red zone measures look a little stronger for top-16 kickers alone, but still add nothing once implied total is in.
- **Total FG (single model):** the implied-total curve mostly disappears for top-16 kickers (+12.8 all vs +1.7 top-16). The curve comes largely from weak offenses, whose kickers rarely make the top 16.
- **0-39:** the implied-total curve holds when scored on top-16 kickers (+10.1), and is weaker when fit on them only (+4.7).
- **40-49:** the one real difference. Dome × kicker 40-49 accuracy helps top-16 kickers only (see open choices).
- **50+:** kicker accuracy matters as much or more for top-16 kickers: 40+ accuracy alone gives +15.6 top-16 scored vs +13.5 all.
- **Kicker volume and share measures:** still no help, and clearly worse when fit on top-16 kickers only.

## Column key for the results files

**`volume_experiment_results.csv`** (one row per model):

| Column | Meaning |
|---|---|
| section | A_total_fg (single total-FG model), B_xp, C_range_039 / C_range_4049 / C_range_50 (FG attempts by range) |
| outcome | What's predicted: fg_attempts, xp_attempts, att_039, att_4049, att_50 (attempts per team-game) |
| model | Label. `alone: X` = X by itself vs league average; `proposed + X` = X added to the recommended model for that range; `PROPOSED:` = the v1 recommended model; `CANDIDATE:` = head-to-head candidate vs league average; `interaction` rows compare A × B against A + B |
| formula | Predictors as an R formula. `*` = both main effects plus the interaction; `:` = the interaction term only |
| reference, reference_formula | The model this row is compared against |
| error_all | Held-out error ×1000, fit and scored on all kickers. Lower = better |
| gain_all | reference error − this model's error, ×1000. Positive = better |
| gain_se_all, gain_z_all | Formula noise estimate and gain ÷ se. Conservative, so use the placebo rule of thumb above |
| seasons_better_all | Held-out seasons (of 3) where this model beat the reference |
| …_top16 | Same, fit on all kickers but scored only on top-16 kickers' team-games |
| …_top16fit | Same, fit and scored on top-16 kickers' team-games only |

Model labels use short variable names:

| Name | Meaning |
|---|---|
| implied | implied team total |
| implied_quadratic | implied team total + its square |
| coach_fg_or_go | coach FG rate on 4th down at the opponent's 42 or closer |
| coach_long_fg | same, at the opponent's 33–42 only (pending 07b) |
| dome | is_enclosed |
| redzone_td_rate / redzone_trips | own red zone TD rate / trips per game, trailing 8 |
| opp_redzone_td_allowed | opponent's red zone TD rate allowed, trailing 8 |
| krate_039 / krate_4049 / krate_50 / krate_40plus | kicker accuracy by range (40plus = 40-49 and 50+ pooled) |
| kvol_… | kicker FG attempts per game (own range or total); hl12 = 12-game half-life, all / hlall = full history |
| kshare_… | kicker's share of FG attempts in that range |
| team_share_own_trail8 | team's share of FG attempts in that range, trailing 8 |

**`volume_experiment_placebo.csv`** (one row per placebo check): real_gain = the real variable's gain; formula_se = its formula standard error; placebo_mean / placebo_sd / placebo_95th = average, spread and 95th percentile of the 300 shuffled gains; share_placebo_at_least_real = empirical p-value. Suffix `_all` or `_top16` as above.

## How the kicker predictors are built

All use only games before the one being predicted.
- Each team-game gets a kicker: whoever attempted the most FGs that game or, if the team attempted none, the team's most recent kicker.
- **Accuracy by range** (including pooled 40+): script 05's method (12-game half-life, shrunk toward the league rate).
- **Attempts per game in a range**: includes his teams' zero-FG games, shrunk toward the league per-game average.
- **Share of FGs in a range**: shrunk toward the league share.

## Not tested yet

1. **Coach long-range FG rate** (script written; needs your run of 07b).
2. **Team's own trailing FG attempts per game** (team counts; only team shares were tested).
3. **Point spread**, separately from implied total.
4. **Offensive efficiency beyond red zone**: EPA per play, drives per game, pace.
5. **Weather**: deferred by decision on 2026-09-22.
6. **Other venue/game details**: grass vs turf, retractable roof open vs closed, primetime, rest days, week of season.
7. **Different model forms**: multinomial split of total attempts into ranges, kicker/team random effects. Negative binomial was ruled out because the counts are less spread out than Poisson.

## Caveats

- **Many comparisons**: see the remaining caution in the noise section.
- **Top 16 is chosen on the same season's results.** Use top-16 numbers to compare models with each other, not as absolute accuracy. The fit-on-top-16 view has a further problem: kickers partly make the top 16 *by* getting lots of attempts, so those fits are biased toward higher volume and toward whatever happened to go with lucky volume.
- **Only 3 held-out seasons**, and kicker history starts in 2023: a veteran's first games in the window look like a new kicker's.

## Appendix: every model tested

Gain vs the "compared with" model, ×1000 (positive = better). The all-kickers column also shows the formula z; read it with the placebo rule of thumb above, not as a strict z ≥ 2 cutoff.

### Total FG attempts (single model, replaced by the range models)

| Model | Compared with | All kickers | Top-16 (scored) | Top-16 (fit + scored) |
|---|---|---|---|---|
| implied | league average | +2.3 (z 1.1, 3/3) | -1.8 (1/3) | -3.1 (0/3) |
| implied_quadratic | league average | +12.8 (z 2.0, 3/3) | +1.7 (2/3) | -0.1 (1/3) |
| coach_fg_or_go | league average | +2.3 (z 0.8, 2/3) | +4.5 (3/3) | +2.2 (2/3) |
| dome | league average | +0.8 (z 0.3, 2/3) | +2.9 (2/3) | +0.9 (1/3) |
| altitude | league average | -8.2 (z -3.6, 0/3) | -8.9 (0/3) | -4.1 (1/3) |
| redzone_td_rate | league average | -0.8 (z -0.8, 2/3) | -1.7 (1/3) | -3.6 (1/3) |
| redzone_trips | league average | -1.9 (z -2.0, 0/3) | -0.1 (2/3) | +5.1 (3/3) |
| opp_redzone_td_allowed | league average | -0.3 (z -0.6, 0/3) | -0.8 (0/3) | -0.8 (0/3) |
| original agreed set (9 predictors) | league average | -9.0 (z -1.5, 1/3) | -10.3 (1/3) | -12.8 (0/3) |
| implied quadratic + coach + dome | league average | +14.7 (z 2.1, 3/3) | +8.3 (2/3) | +3.7 (2/3) |
| + implied x coach interaction | implied quadratic + coach + dome | -1.0 (z -1.4, 0/3) | -0.3 (2/3) | -0.8 (1/3) |

### XP attempts

| Model | Compared with | All kickers | Top-16 (scored) | Top-16 (fit + scored) |
|---|---|---|---|---|
| implied | league average | +155.0 (z 8.4, 3/3) | +172.3 (3/3) | +163.2 (3/3) |
| implied_quadratic | league average | +154.2 (z 8.4, 3/3) | +169.0 (3/3) | +160.2 (3/3) |
| redzone_td_rate | league average | +6.7 (z 1.1, 2/3) | +19.3 (3/3) | +19.7 (3/3) |
| redzone_trips | league average | +60.8 (z 5.1, 3/3) | +45.4 (3/3) | +34.2 (2/3) |
| opp_redzone_td_allowed | league average | +8.4 (z 2.0, 3/3) | +15.8 (3/3) | +16.6 (3/3) |
| implied + implied_quadratic | implied only | -0.8 (z -0.6, 1/3) | -3.3 (1/3) | -3.0 (0/3) |
| implied + redzone_td_rate | implied only | -2.3 (z -1.4, 0/3) | -4.4 (0/3) | -2.1 (1/3) |
| implied + redzone_trips | implied only | +1.2 (z 0.7, 2/3) | -2.0 (1/3) | -5.2 (0/3) |
| implied + opp_redzone_td_allowed | implied only | +1.1 (z 0.7, 2/3) | +3.0 (2/3) | +2.4 (2/3) |
| implied + dome | implied only | -0.1 (z -0.3, 2/3) | -0.3 (2/3) | -1.7 (1/3) |
| implied + all 3 red zone | implied only | +1.2 (z 0.4, 2/3) | -2.6 (1/3) | -3.2 (2/3) |

### 0-39 FG attempts

| Model | Compared with | All kickers | Top-16 (scored) | Top-16 (fit + scored) |
|---|---|---|---|---|
| alone: implied | league average | +1.0 (z 0.5, 2/3) | -1.8 (1/3) | -2.6 (0/3) |
| alone: implied_quadratic | league average | +10.7 (z 1.8, 2/3) | +10.1 (2/3) | +4.7 (2/3) |
| alone: coach_fg_or_go | league average | +1.3 (z 0.9, 3/3) | +0.8 (2/3) | -0.1 (2/3) |
| alone: dome | league average | -0.7 (z -0.4, 2/3) | -1.2 (1/3) | -1.5 (0/3) |
| alone: altitude | league average | -6.0 (z -1.9, 1/3) | -6.6 (1/3) | -4.7 (2/3) |
| alone: redzone_td_rate | league average | -0.6 (z -0.2, 2/3) | +1.2 (2/3) | -1.1 (1/3) |
| alone: redzone_trips | league average | -0.7 (z -1.0, 1/3) | -0.1 (2/3) | +0.8 (2/3) |
| alone: opp_redzone_td_allowed | league average | +0.1 (z 0.0, 2/3) | -0.9 (2/3) | -1.8 (1/3) |
| alone: krate_039 | league average | -1.1 (z -0.7, 2/3) | -0.8 (1/3) | -0.4 (0/3) |
| alone: krate_4049 | league average | -0.8 (z -1.0, 0/3) | -0.1 (1/3) | -2.9 (1/3) |
| alone: krate_50 | league average | -0.5 (z -0.5, 0/3) | -0.3 (2/3) | -0.7 (0/3) |
| alone: krate_40plus | league average | +0.3 (z 0.4, 2/3) | -0.4 (1/3) | -0.3 (2/3) |
| alone: kvol_own_hl12 | league average | +0.3 (z 0.2, 2/3) | -0.6 (1/3) | -0.6 (1/3) |
| alone: kvol_own_all | league average | -0.4 (z -0.2, 1/3) | -1.7 (1/3) | -2.4 (0/3) |
| alone: kvol_total_hl12 | league average | +0.1 (z 0.1, 2/3) | -0.4 (0/3) | -0.1 (2/3) |
| alone: kshare_own_hl12 | league average | +0.1 (z 0.1, 2/3) | -0.0 (1/3) | -0.2 (2/3) |
| alone: kshare_own_all | league average | +0.2 (z 0.1, 2/3) | -0.2 (1/3) | -0.7 (1/3) |
| alone: team_share_own_trail8 | league average | -0.5 (z -0.8, 0/3) | -0.1 (1/3) | +0.1 (2/3) |
| PROPOSED: implied quadratic | league average | +10.7 (z 1.8, 2/3) | +10.1 (2/3) | +4.7 (2/3) |
| proposed + coach_fg_or_go | implied quadratic | +0.2 (z 0.2, 2/3) | -0.3 (2/3) | -0.5 (1/3) |
| proposed + dome | implied quadratic | -0.5 (z -0.2, 2/3) | -1.5 (1/3) | -1.6 (0/3) |
| proposed + altitude | implied quadratic | -4.3 (z -1.4, 2/3) | -5.7 (2/3) | -4.4 (2/3) |
| proposed + redzone_td_rate | implied quadratic | -0.9 (z -0.4, 2/3) | +1.4 (2/3) | -1.0 (2/3) |
| proposed + redzone_trips | implied quadratic | -0.4 (z -0.2, 2/3) | -0.7 (2/3) | -1.0 (2/3) |
| proposed + opp_redzone_td_allowed | implied quadratic | +0.2 (z 0.1, 2/3) | -1.0 (2/3) | -2.2 (1/3) |
| proposed + krate_039 | implied quadratic | -1.6 (z -1.4, 1/3) | -0.4 (1/3) | -0.0 (1/3) |
| proposed + krate_4049 | implied quadratic | -0.5 (z -0.8, 0/3) | -0.0 (1/3) | -2.6 (0/3) |
| proposed + krate_50 | implied quadratic | -0.6 (z -0.6, 0/3) | -0.4 (1/3) | -1.1 (1/3) |
| proposed + krate_40plus | implied quadratic | +0.3 (z 0.4, 2/3) | -0.3 (1/3) | -0.2 (1/3) |
| proposed + kvol_own_hl12 | implied quadratic | -0.4 (z -0.7, 0/3) | -0.4 (0/3) | -0.8 (0/3) |
| proposed + kvol_own_all | implied quadratic | -1.0 (z -1.1, 0/3) | -1.4 (0/3) | -2.2 (1/3) |
| proposed + kvol_total_hl12 | implied quadratic | -0.3 (z -0.7, 0/3) | -0.1 (2/3) | -0.5 (2/3) |
| proposed + kshare_own_hl12 | implied quadratic | -0.1 (z -0.1, 2/3) | +0.1 (2/3) | +0.3 (2/3) |
| proposed + kshare_own_all | implied quadratic | -0.1 (z -0.1, 2/3) | +0.0 (1/3) | +0.0 (2/3) |
| proposed + team_share_own_trail8 | implied quadratic | -0.2 (z -0.6, 0/3) | -0.1 (1/3) | +0.3 (2/3) |
| dome x krate_039 interaction | dome + krate_039 | -0.2 (z -0.4, 2/3) | -0.2 (2/3) | -1.4 (1/3) |
| dome x krate_4049 interaction | dome + krate_4049 | -5.1 (z -2.9, 0/3) | -4.1 (0/3) | -3.2 (0/3) |
| dome x krate_50 interaction | dome + krate_50 | -0.6 (z -1.1, 0/3) | -0.3 (1/3) | -1.7 (0/3) |
| dome x krate_40plus interaction | dome + krate_40plus | -4.2 (z -3.2, 0/3) | -3.3 (0/3) | -4.2 (0/3) |
| implied x krate_039 interaction | implied quadratic + krate_039 | -2.9 (z -2.6, 1/3) | -0.4 (1/3) | -3.2 (1/3) |
| dome x kicker own-range volume interaction | dome + kicker own-range volume | -0.7 (z -0.6, 2/3) | -2.7 (1/3) | -5.7 (1/3) |
| kicker share x krate_50 interaction | dome + krate_50 + kicker share | +0.0 (z 0.0, 2/3) | +0.9 (2/3) | -7.4 (2/3) |

### 40-49 FG attempts

| Model | Compared with | All kickers | Top-16 (scored) | Top-16 (fit + scored) |
|---|---|---|---|---|
| alone: implied | league average | -3.3 (z -2.2, 0/3) | -4.3 (0/3) | -3.9 (1/3) |
| alone: implied_quadratic | league average | -7.3 (z -2.1, 1/3) | -12.9 (0/3) | -18.7 (0/3) |
| alone: coach_fg_or_go | league average | -0.6 (z -0.4, 1/3) | +1.3 (2/3) | +0.7 (2/3) |
| alone: dome | league average | -2.3 (z -0.8, 2/3) | -1.3 (2/3) | -6.9 (2/3) |
| alone: altitude | league average | -1.3 (z -1.1, 0/3) | -1.4 (1/3) | -4.0 (2/3) |
| alone: redzone_td_rate | league average | -0.1 (z -0.1, 2/3) | +0.9 (3/3) | +1.4 (3/3) |
| alone: redzone_trips | league average | -3.0 (z -1.9, 1/3) | -4.4 (1/3) | -4.0 (0/3) |
| alone: opp_redzone_td_allowed | league average | +2.8 (z 1.2, 3/3) | -1.2 (1/3) | -2.4 (1/3) |
| alone: krate_039 | league average | -1.2 (z -1.6, 0/3) | -1.6 (0/3) | +0.5 (2/3) |
| alone: krate_4049 | league average | -2.2 (z -1.7, 0/3) | -0.3 (1/3) | +7.5 (3/3) |
| alone: krate_50 | league average | -0.9 (z -0.6, 1/3) | -0.8 (1/3) | -0.1 (1/3) |
| alone: krate_40plus | league average | +0.5 (z 0.3, 2/3) | -2.0 (1/3) | -1.3 (1/3) |
| alone: kvol_own_hl12 | league average | -2.2 (z -1.8, 0/3) | -2.9 (0/3) | -4.1 (0/3) |
| alone: kvol_own_all | league average | -1.9 (z -1.8, 0/3) | -3.0 (0/3) | -5.7 (0/3) |
| alone: kvol_total_hl12 | league average | -0.1 (z -0.1, 2/3) | -0.4 (1/3) | -1.6 (0/3) |
| alone: kshare_own_hl12 | league average | -2.2 (z -1.6, 0/3) | -3.4 (0/3) | -6.0 (1/3) |
| alone: kshare_own_all | league average | -1.6 (z -1.6, 0/3) | -2.7 (0/3) | -5.9 (0/3) |
| alone: team_share_own_trail8 | league average | -4.8 (z -1.9, 1/3) | -6.5 (1/3) | -2.7 (1/3) |
| dome x krate_039 interaction | dome + krate_039 | -2.3 (z -2.0, 0/3) | -1.0 (1/3) | +1.6 (2/3) |
| dome x krate_4049 interaction | dome + krate_4049 | +1.8 (z 0.8, 2/3) | +7.1 (3/3) | +11.9 (2/3) |
| dome x krate_50 interaction | dome + krate_50 | +1.0 (z 0.7, 2/3) | +0.5 (1/3) | -1.3 (2/3) |
| dome x krate_40plus interaction | dome + krate_40plus | -0.3 (z -0.5, 1/3) | +0.3 (2/3) | +0.1 (2/3) |
| implied x krate_4049 interaction | implied quadratic + krate_4049 | -0.3 (z -0.2, 2/3) | -1.2 (1/3) | -3.4 (2/3) |
| dome x kicker own-range volume interaction | dome + kicker own-range volume | -1.0 (z -1.2, 0/3) | -1.3 (1/3) | -1.3 (0/3) |
| kicker share x krate_50 interaction | dome + krate_50 + kicker share | +0.9 (z 0.4, 2/3) | +3.3 (2/3) | +3.8 (2/3) |
| CANDIDATE: dome + kicker 40-49 accuracy | league average | -5.0 (z -1.5, 2/3) | -1.7 (2/3) | +1.2 (2/3) |
| CANDIDATE: dome x kicker 40-49 accuracy | league average | -3.2 (z -0.8, 1/3) | +5.4 (2/3) | +13.1 (2/3) |

### 50+ FG attempts

| Model | Compared with | All kickers | Top-16 (scored) | Top-16 (fit + scored) |
|---|---|---|---|---|
| alone: implied | league average | -0.9 (z -0.7, 1/3) | -0.4 (1/3) | +0.1 (1/3) |
| alone: implied_quadratic | league average | +0.7 (z 0.3, 1/3) | -2.4 (0/3) | -0.4 (1/3) |
| alone: coach_fg_or_go | league average | -0.8 (z -0.2, 2/3) | -0.0 (2/3) | -1.5 (2/3) |
| alone: dome | league average | +6.8 (z 1.3, 2/3) | +9.6 (2/3) | +9.8 (2/3) |
| alone: altitude | league average | -2.1 (z -0.9, 2/3) | -1.6 (2/3) | -2.5 (2/3) |
| alone: redzone_td_rate | league average | -0.1 (z -0.1, 1/3) | +1.5 (3/3) | +3.0 (2/3) |
| alone: redzone_trips | league average | -0.0 (z -0.1, 2/3) | +1.1 (2/3) | +1.7 (2/3) |
| alone: opp_redzone_td_allowed | league average | -1.5 (z -2.1, 1/3) | -1.8 (0/3) | -2.2 (0/3) |
| alone: krate_039 | league average | -4.2 (z -2.7, 0/3) | -6.3 (0/3) | -12.8 (1/3) |
| alone: krate_4049 | league average | +5.2 (z 1.3, 2/3) | +2.1 (2/3) | -0.3 (1/3) |
| alone: krate_50 | league average | +7.4 (z 1.5, 2/3) | +12.2 (2/3) | +8.5 (2/3) |
| alone: krate_40plus | league average | +13.5 (z 2.3, 2/3) | +15.6 (3/3) | +8.4 (3/3) |
| alone: kvol_own_hl12 | league average | -0.1 (z -0.0, 2/3) | -4.3 (2/3) | -8.9 (1/3) |
| alone: kvol_own_all | league average | -2.8 (z -0.7, 2/3) | -7.0 (2/3) | -13.8 (1/3) |
| alone: kvol_total_hl12 | league average | -1.2 (z -0.4, 2/3) | -3.1 (2/3) | -12.0 (1/3) |
| alone: kshare_own_hl12 | league average | -2.1 (z -0.7, 2/3) | -5.7 (2/3) | -8.1 (1/3) |
| alone: kshare_own_all | league average | -4.5 (z -1.4, 2/3) | -7.8 (2/3) | -11.8 (1/3) |
| alone: team_share_own_trail8 | league average | -2.9 (z -1.4, 1/3) | -5.6 (1/3) | -7.4 (0/3) |
| PROPOSED: dome + kicker 50+ accuracy | league average | +14.0 (z 1.9, 3/3) | +20.3 (2/3) | +16.7 (2/3) |
| proposed + implied | dome + kicker 50+ accuracy | -1.2 (z -1.2, 1/3) | -0.4 (0/3) | +0.2 (2/3) |
| proposed + implied_quadratic | dome + kicker 50+ accuracy | -0.5 (z -0.3, 1/3) | -2.8 (0/3) | -1.0 (1/3) |
| proposed + coach_fg_or_go | dome + kicker 50+ accuracy | -1.1 (z -0.5, 2/3) | +0.1 (1/3) | +0.0 (2/3) |
| proposed + altitude | dome + kicker 50+ accuracy | -2.2 (z -1.3, 1/3) | -2.3 (1/3) | -2.3 (2/3) |
| proposed + redzone_td_rate | dome + kicker 50+ accuracy | -0.1 (z -0.3, 0/3) | +0.7 (3/3) | +2.1 (2/3) |
| proposed + redzone_trips | dome + kicker 50+ accuracy | -0.3 (z -0.5, 0/3) | +1.4 (3/3) | +1.8 (2/3) |
| proposed + opp_redzone_td_allowed | dome + kicker 50+ accuracy | -1.8 (z -2.1, 0/3) | -2.6 (0/3) | -4.4 (0/3) |
| proposed + krate_039 | dome + kicker 50+ accuracy | -5.5 (z -3.0, 0/3) | -7.4 (0/3) | -15.7 (0/3) |
| proposed + krate_4049 | dome + kicker 50+ accuracy | +5.8 (z 1.6, 3/3) | +2.9 (2/3) | +0.5 (2/3) |
| proposed + krate_40plus | dome + kicker 50+ accuracy | +7.0 (z 1.7, 2/3) | +3.8 (2/3) | -0.4 (2/3) |
| proposed + kvol_own_hl12 | dome + kicker 50+ accuracy | -3.0 (z -1.1, 1/3) | -6.7 (1/3) | -6.4 (0/3) |
| proposed + kvol_own_all | dome + kicker 50+ accuracy | -4.6 (z -1.6, 1/3) | -8.6 (0/3) | -10.2 (0/3) |
| proposed + kvol_total_hl12 | dome + kicker 50+ accuracy | -1.3 (z -0.7, 2/3) | -2.8 (2/3) | -5.6 (0/3) |
| proposed + kshare_own_hl12 | dome + kicker 50+ accuracy | -3.3 (z -1.4, 1/3) | -6.0 (1/3) | -4.4 (1/3) |
| proposed + kshare_own_all | dome + kicker 50+ accuracy | -4.8 (z -1.9, 1/3) | -7.5 (1/3) | -7.0 (0/3) |
| proposed + team_share_own_trail8 | dome + kicker 50+ accuracy | -2.6 (z -1.9, 0/3) | -4.4 (0/3) | -4.7 (0/3) |
| dome x krate_039 interaction | dome + krate_039 | -0.0 (z -0.1, 0/3) | -0.6 (0/3) | -1.5 (0/3) |
| dome x krate_4049 interaction | dome + krate_4049 | -0.8 (z -0.9, 1/3) | -0.8 (0/3) | -0.3 (0/3) |
| dome x krate_50 interaction | dome + krate_50 | +3.5 (z 1.4, 3/3) | +2.9 (2/3) | +2.0 (3/3) |
| dome x krate_40plus interaction | dome + krate_40plus | -0.3 (z -0.3, 2/3) | -0.3 (2/3) | +0.6 (3/3) |
| implied x krate_50 interaction | implied quadratic + krate_50 | -0.1 (z -0.5, 1/3) | -0.4 (0/3) | +0.4 (2/3) |
| dome x kicker own-range volume interaction | dome + kicker own-range volume | -0.7 (z -0.4, 2/3) | -1.0 (2/3) | -1.8 (1/3) |
| kicker share x krate_50 interaction | dome + krate_50 + kicker share | -3.5 (z -2.1, 1/3) | -4.1 (1/3) | -2.9 (1/3) |
| SWAP: dome + kicker 40+ accuracy (instead of 50+) | dome + kicker 50+ accuracy | +7.0 (z 1.8, 2/3) | +4.0 (2/3) | +0.7 (2/3) |
| proposed + krate_4049 (both long accuracies separately) | dome + kicker 50+ accuracy | +5.8 (z 1.6, 3/3) | +2.9 (2/3) | +0.5 (2/3) |
| CANDIDATE: dome + kicker 40+ accuracy | league average | +21.0 (z 2.7, 3/3) | +24.2 (2/3) | +17.4 (2/3) |
| CANDIDATE: dome x kicker 50+ accuracy | league average | +17.5 (z 2.3, 3/3) | +23.2 (2/3) | +18.7 (2/3) |
| CANDIDATE: dome x kicker 40+ accuracy | league average | +20.7 (z 2.7, 3/3) | +23.9 (2/3) | +18.0 (2/3) |
| CANDIDATE: dome x kicker 50+ accuracy + kicker 40-49 accuracy | league average | +22.8 (z 2.9, 3/3) | +25.4 (2/3) | +19.0 (2/3) |
| CANDIDATE: dome + kicker 40+ accuracy + dome x kicker 50+ accuracy | league average | +23.3 (z 2.9, 3/3) | +26.4 (2/3) | +19.3 (2/3) |
| dome + kicker 40+ accuracy, then add dome x kicker 50+ accuracy | dome + kicker 40+ accuracy | +2.3 (z 1.2, 3/3) | +2.2 (2/3) | +1.9 (2/3) |
