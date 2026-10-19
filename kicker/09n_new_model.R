# The new attempts model and the dome shifts on make chances, applied to one
# week's inputs. Added 2026-10-06 (to-do #31b; tests #29-#38).
#
# This file only defines functions. It is sourced by 09b_weekly_projections.R.
# Needs 08_points_distribution.R and 09_weekly_inputs.R to be sourced first.
#
# WHAT THE MODEL IS
#   XP attempts      count model on the implied team total.
#   0-39 attempts    count model on the implied team total, its square and the
#                    expected margin (2 x implied team total - game total;
#                    positive = favored).
#   40-49 attempts   proportional to a kick chance: the share of 4th downs at
#                    the opponent's 22-31 on which this team would kick, from a
#                    kick-or-go model. Team inputs: dome, kicker 40+ accuracy,
#                    dome x accuracy, coach long-range FG rate. The chance is
#                    averaged over a fixed set of past 4th downs (the reference
#                    plays), with each play's score shifted to what it would
#                    typically be for this team's expected margin.
#   50+ attempts     the same on 4th downs at the opponent's 32-41.
#   Level            every part is scaled so that, on the calibration rows
#                    (pre-game top-16 team-games of the last three seasons),
#                    predicted attempts add up to actual attempts.
#   Make chances     the kicker's own rates from 09_weekly_inputs.R, shifted up
#                    in a dome and down outdoors (one shift per range, one for
#                    XPs), on the log-odds scale and centered on the share of
#                    past kicks taken in domes.
#   Unknown roof     a retractable roof not yet announced gets that stadium's
#                    closed share for the month; the projection is the closed
#                    and open projections blended by that share.
#
# WHERE THE WEIGHTS COME FROM: they were fit once on 2016-2025 (07n_fit_new_model.R,
# run by hand; see claude/39_new_model_build_log.md) and are read from two small
# data files. The weekly run does not refit them. Refit before each season.
#   data/new_model_weights.csv     one long table (part, term, term2, value): the
#                                  weights, each part's level, the dome shifts, the
#                                  covariances (for the confidence interval), the
#                                  roof closed shares by stadium and month, and
#                                  self-test values
#   data/new_model_kick_table.csv  the kick chance for 40-49 (zone M) and 50+ (zone L)
#                                  kicks as a table over the team term and the
#                                  expected margin, on the log-odds scale. It was
#                                  computed from 3,580 and 3,704 past 4th downs; the
#                                  weekly run reads values off it by interpolation
#                                  (within 0.001 of the exact value).

NEW_MODEL_FILES <- c(weights = "data/new_model_weights.csv", kick_table = "data/new_model_kick_table.csv")
NM_TEAM <- c("is_enclosed", "krate_40plus", "coach_long_fg_rate", "is_enclosed:krate_40plus")
NM_RANGES <- c("039", "4049", "50", "xp")

load_new_model <- function(files = NEW_MODEL_FILES) {
  if (any(!file.exists(files))) stop("New-model data files missing: ", paste(files[!file.exists(files)], collapse = ", "))
  w <- as.data.frame(readr::read_csv(files[["weights"]], show_col_types = FALSE, col_types = readr::cols(part = "c", term = "c", term2 = "c", value = "d")))
  part <- function(p) { x <- w[w$part == p, ]; if (!nrow(x)) stop("New-model weights file has no part '", p, "'"); stats::setNames(x$value, x$term) }
  vmat <- function(p, terms) { x <- w[w$part == p, ]; m <- matrix(NA_real_, length(terms), length(terms), dimnames = list(terms, terms))
    m[cbind(x$term, x$term2)] <- x$value; stopifnot(!anyNA(m)); m }
  nm <- list(xp = part("xp"), att_039 = part("att_039"), meta = part("meta"), level = list(xp = part("xp_level"), att_039 = part("att_039_level")))
  nm$V <- list(xp = vmat("vcov_xp", names(nm$xp)), att_039 = vmat("vcov_att_039", names(nm$att_039)))
  kt <- as.data.frame(readr::read_csv(files[["kick_table"]], show_col_types = FALSE)); mcols <- setdiff(names(kt), c("zone", "team_term"))
  for (z in c("M", "L")) { nm[[paste0("team_", z)]] <- part(paste0("kick_", z, "_team"))[NM_TEAM]; nm$level[[z]] <- part(paste0("kick_", z, "_level"))
    nm$V[[paste0("team_", z)]] <- vmat(paste0("vcov_kick_", z, "_team"), NM_TEAM)
    k <- kt[kt$zone == z, ]; tg <- k$team_term; mg <- as.numeric(sub("^m_", "", mcols))
    stopifnot(length(tg) > 2, !is.unsorted(tg), !is.unsorted(mg), max(abs(diff(diff(tg)))) < 1e-9, max(abs(diff(diff(mg)))) < 1e-9)
    nm$grid[[z]] <- list(G = as.matrix(k[mcols]), t0 = tg[1], dt = tg[2] - tg[1], nt = length(tg), m0 = mg[1], dm = mg[2] - mg[1], nmg = length(mg)) }
  nm$shift <- lapply(stats::setNames(NM_RANGES, NM_RANGES), function(r) part(paste0("make_shift_", r)))
  r <- w[w$part == "roof_closed_share", ]; nm$roof <- data.frame(home_team = r$term, month_group = r$term2, share = r$value)
  nm$selftest <- w[w$part == "selftest", ]
  nm
}

# --- attempts -------------------------------------------------------------------------
.nm_x039 <- function(d) cbind(implied_team_total = d$implied_team_total, implied_team_total_sq = d$implied_team_total^2, exp_margin = d$exp_margin)
.nm_xteam <- function(d) cbind(d$is_enclosed, d$krate_40plus, d$coach_long_fg_rate, d$is_enclosed * d$krate_40plus)
# Kick chance for team terms t (the team inputs times their weights; a matrix, rows =
# kicker-games) and expected margins m (one per row): read off the stored table by
# linear interpolation on the log-odds scale. Values outside the table use its edge.
.nm_kick_chance <- function(nm, z, t, m) {
  g <- nm$grid[[z]]; t <- as.matrix(t)
  ti <- pmin(pmax((t - g$t0) / g$dt, 0), g$nt - 1 - 1e-9); i0 <- floor(ti); ft <- ti - i0
  mi <- pmin(pmax((m - g$m0) / g$dm, 0), g$nmg - 1 - 1e-9); j0 <- floor(mi); fm <- mi - j0
  j0 <- matrix(j0, nrow(t), ncol(t)); fm <- matrix(fm, nrow(t), ncol(t)); at <- function(i, j) g$G[cbind(as.vector(i) + 1, as.vector(j) + 1)]
  stats::plogis(matrix((1 - ft) * (1 - fm) * at(i0, j0) + ft * (1 - fm) * at(i0 + 1, j0) + (1 - ft) * fm * at(i0, j0 + 1) + ft * fm * at(i0 + 1, j0 + 1), nrow(t)))
}
# Expected attempts for the rows of d (needs implied_team_total, exp_margin, is_enclosed,
# krate_40plus, coach_long_fg_rate). Returns a data.frame with the four lambdas.
# "scale" is each part's level: it makes predicted attempts add up to actual attempts on
# the calibration rows (pre-game top-16 team-games of the last three seasons).
new_model_attempts <- function(nm, d) {
  kick <- function(z) as.numeric(.nm_kick_chance(nm, z, .nm_xteam(d) %*% nm[[paste0("team_", z)]], d$exp_margin)) * nm$level[[z]][["scale"]]
  data.frame(lambda_xp = as.numeric(exp(cbind(d$implied_team_total) %*% nm$xp)) * nm$level$xp[["scale"]],
             lambda_039 = as.numeric(exp(.nm_x039(d) %*% nm$att_039)) * nm$level$att_039[["scale"]],
             lambda_4049 = kick("M"), lambda_50 = kick("L"))
}

# --- make chances ---------------------------------------------------------------------
# Shifts a make chance for the venue: log-odds + shift x (dome - share of past kicks in domes).
.nm_shift_p <- function(p, dome, shift, dome_share) stats::plogis(stats::qlogis(p) + shift * (dome - dome_share))
new_model_make_chances <- function(nm, d) {
  as.data.frame(lapply(stats::setNames(NM_RANGES, paste0("p_", NM_RANGES)), function(r)
    .nm_shift_p(d[[paste0("p_", r)]], d$is_enclosed, nm$shift[[r]][["shift"]], nm$shift[[r]][["dome_share"]])))
}

# --- self-test ------------------------------------------------------------------------
# The weights file carries the attempts the model gave three made-up games when it was
# fit. Recomputing them here catches a damaged or mismatched data file.
NM_SELFTEST_ROWS <- data.frame(row = 1:3, implied_team_total = c(24, 18, 28), exp_margin = c(3, -6, 9), is_enclosed = c(1, 0, 0),
                               krate_40plus = c(0.85, 0.70, 0.90), coach_long_fg_rate = c(0.50, 0.35, 0.60),
                               p_039 = 0.96, p_4049 = 0.82, p_50 = 0.70, p_xp = 0.95)
new_model_selftest_values <- function(nm) {
  a <- new_model_attempts(nm, NM_SELFTEST_ROWS); p <- new_model_make_chances(nm, NM_SELFTEST_ROWS)
  v <- cbind(a, p); data.frame(term = paste0(rep(names(v), each = 3), "_row", rep(1:3, ncol(v))), value = unlist(v, use.names = FALSE))
}
new_model_selftest <- function(nm) {
  got <- new_model_selftest_values(nm); want <- nm$selftest[match(got$term, nm$selftest$term), ]
  if (anyNA(want$value) || max(abs(got$value - want$value)) > 1e-6) stop("New model self-test FAILED: the data files don't reproduce the stored values.")
  message("New model self-test passed (", nrow(got), " values)")
  invisible(TRUE)
}

# --- roof -----------------------------------------------------------------------------
# Chance the roof is closed for each row: 1 or 0 when the schedule says so; otherwise the
# stadium's closed share for the month (a home game at one of the retractable-roof
# stadiums), or the all-stadium share (any other game with no roof value, e.g. a neutral
# site with a retractable roof).
new_model_roof_share <- function(nm, d, sched) {
  g <- sched[match(d$game_id, sched$game_id), c("home_team", "location", "gameday")]
  mo <- as.integer(substr(as.character(g$gameday), 6, 7)); mg <- ifelse(mo == 9, "Sep", ifelse(mo == 10, "Oct", ifelse(mo == 11, "Nov", "Dec-Jan")))
  r <- nm$roof; all_share <- r$share[r$home_team == "ALL"]
  s <- r$share[match(paste(g$home_team, mg), paste(r$home_team, r$month_group))]
  s <- ifelse(is.na(s) | !(g$location %in% "Home"), all_share, s)
  ifelse(d$roof_unknown, s, d$is_enclosed)
}

# --- confidence interval --------------------------------------------------------------
.nm_mvn <- function(n, b, V) sweep(matrix(stats::rnorm(length(b) * n), n) %*% chol(V), 2, b, "+")   # n x length(b)
# Draws of projected points for the rows of d (rows x n_draws). Redrawn each time:
#   - the count models' weights and the kick-or-go models' team weights (normal, with
#     their fitted covariance). The kick-or-go models' situation weights are held fixed.
#   - each part's level. A redrawn weight changes what the model predicts on the
#     calibration rows, and the level is reset so those still add up: the level file
#     rows "center_*" (count models) and "grad_*" (kick-or-go models) carry that
#     correction to first order. On top, the calibration rows' total attempts
#     ("cal_total") is a count with Poisson noise.
#   - make chances: the Beta draws 08 uses, then the dome shift with its own standard error.
# acc carries a_039/b_039, a_4049/b_4049, a_50/b_50, a_xp/b_xp and slump_ratio.
new_model_draws <- function(nm, d, acc, n_draws = 2000) {
  lev <- function(L) stats::rgamma(n_draws, shape = L[["cal_total"]], rate = 1) / L[["cal_total"]]
  cnt <- function(b, V, X, L) { B <- .nm_mvn(n_draws, b, V); ctr <- L[paste0("center_", names(b))]
    sweep(exp(X %*% t(B)), 2, L[["scale"]] * lev(L) * exp(-as.numeric(sweep(B, 2, b, "-") %*% ctr)), "*") }
  kick <- function(z) { b <- nm[[paste0("team_", z)]]; L <- nm$level[[z]]; B <- .nm_mvn(n_draws, b, nm$V[[paste0("team_", z)]])
    rel <- pmax(1 + as.numeric(sweep(B, 2, b, "-") %*% L[paste0("grad_", NM_TEAM)]), 0.2)     # calibration total under the redrawn weights, relative
    sweep(.nm_kick_chance(nm, z, .nm_xteam(d) %*% t(B), d$exp_margin), 2, L[["scale"]] * lev(L) / rel, "*") }
  lam <- list(xp = cnt(nm$xp, nm$V$xp, cbind(d$implied_team_total), nm$level$xp), a039 = cnt(nm$att_039, nm$V$att_039, .nm_x039(d), nm$level$att_039),
              a4049 = kick("M"), a50 = kick("L"))
  pr <- function(r, slump) { p <- draw_rates(acc[[paste0("a_", r)]], acc[[paste0("b_", r)]], n_draws); if (slump) p <- pmin(p * acc$slump_ratio, 1)
    sh <- stats::rnorm(n_draws, nm$shift[[r]][["shift"]], nm$shift[[r]][["se"]])
    stats::plogis(stats::qlogis(p) + outer(d$is_enclosed - nm$shift[[r]][["dome_share"]], sh)) }
  projected_points(lam$xp, lam$a039, lam$a4049, lam$a50, pr("039", TRUE), pr("4049", TRUE), pr("50", TRUE), pr("xp", FALSE))
}

# --- one week ---------------------------------------------------------------------------
# Same job and same output columns as 09's project_week(), from the new model, plus:
#   exp_margin, roof_closed_share (chance the roof is closed; 1 or 0 when known),
#   proj_roof_closed / proj_roof_open (roof-unknown rows only: the projection either way),
#   p_039_record ... p_xp_record (make chances before the dome shift), krate_4049,
#   krate_40plus, coach_long_fg_rate (inputs), model.
# For a roof-unknown row every number is the closed and open versions blended by
# roof_closed_share; the distribution is the same blend of the two distributions.
# Also returns `scenarios`: for roof-unknown rows, one full row per roof state.
project_week_new <- function(pbp, sched, season, week, nm, points_gamma, lines_as_of, last_played_week, N_DRAWS = 2000) {
  inputs <- build_week_inputs(pbp, sched, season, week, pregame_kicker_for_played = TRUE)
  league_ppg <- attr(inputs, "league_averages")[["ppg"]]
  proj <- inputs |> dplyr::mutate(played = !is.na(result))
  if (any(is.na(proj$kicker_player_id))) warning("No kicker found for: ", paste(proj$posteam[is.na(proj$kicker_player_id)], collapse = ", "))
  proj <- proj |> dplyr::filter(!is.na(kicker_player_id))
  if (any(proj$implied_imputed)) warning("No betting line yet for: ", paste(proj$game_id[proj$implied_imputed], collapse = ", "),
                                         " - league-average implied total used")
  proj$exp_margin <- ifelse(proj$implied_imputed | is.na(proj$total_line), 0, 2 * proj$implied_team_total - proj$total_line)
  proj$roof_closed_share <- new_model_roof_share(nm, proj, sched)
  w <- proj$roof_closed_share; unk <- proj$roof_unknown
  REC <- paste0("p_", NM_RANGES)
  seed <- sample.int(.Machine$integer.max, 1)   # the closed and open versions reuse the same random draws
  one <- function(dome) { d <- proj; d$is_enclosed <- dome; set.seed(seed)
    list(v = cbind(new_model_attempts(nm, d), new_model_make_chances(nm, d)), draws = new_model_draws(nm, d, d, N_DRAWS)) }
  cl_all <- one(rep(1, nrow(proj))); op_all <- one(rep(0, nrow(proj))); cl <- cl_all$v; op <- op_all$v
  V <- c("lambda_xp", "lambda_039", "lambda_4049", "lambda_50", REC)
  blend <- as.data.frame(lapply(stats::setNames(V, V), function(v) w * cl[[v]] + (1 - w) * op[[v]]))
  pmf <- function(x, i) points_pmf_dep(x$lambda_xp[i], x$lambda_039[i], x$lambda_4049[i], x$lambda_50[i], x$p_039[i], x$p_4049[i], x$p_50[i], x$p_xp[i], gamma = points_gamma)
  mix <- function(a, b, wa) { m <- merge(a, b, by = "points", all = TRUE); m[is.na(m)] <- 0
    out <- data.frame(points = m$points, prob = wa * m$prob.x + (1 - wa) * m$prob.y); out[order(out$points), ] }
  dists <- lapply(seq_len(nrow(proj)), function(i) if (w[i] >= 1) pmf(cl, i) else if (w[i] <= 0) pmf(op, i) else mix(pmf(cl, i), pmf(op, i), w[i]))
  stat <- function(d) c(summarise_pmf(d), prob_negative = sum(d$prob[d$points < 0]), prob_10plus = sum(d$prob[d$points >= 10]))
  summ <- do.call(rbind, lapply(dists, stat))
  qci <- function(m) t(apply(m, 1, stats::quantile, probs = c(0.05, 0.95), names = FALSE))
  ci <- qci(w * cl_all$draws + (1 - w) * op_all$draws); colnames(ci) <- c("ci_low", "ci_high")
  pp <- function(x) projected_points(x$lambda_xp, x$lambda_039, x$lambda_4049, x$lambda_50, x$p_039, x$p_4049, x$p_50, x$p_xp)
  rec <- proj[REC]; names(rec) <- paste0(REC, "_record")
  full <- dplyr::bind_cols(proj[setdiff(names(proj), REC)], blend, rec, tibble::as_tibble(summ), tibble::as_tibble(ci)) |>
    dplyr::mutate(is_enclosed = w, proj_roof_closed = ifelse(unk, pp(cl), NA_real_), proj_roof_open = ifelse(unk, pp(op), NA_real_))
  shape <- function(x) x |> dplyr::transmute(season, week, game_id, gameday, team = posteam, opponent, home_away, played, actual_points,
              kicker_player_name, kicker_player_id, kicker_source, kicker_last_game,
              ppg_rank, top16pre, kicker_ppg_pre,
              projected_points, ci_low, ci_high, outcome_low, outcome_high, outcome_range_prob, sd_points,
              prob_negative, prob_10plus,
              exp_xp_attempts = lambda_xp, exp_att_039 = lambda_039, exp_att_4049 = lambda_4049, exp_att_50 = lambda_50,
              p_039, p_4049, p_50, p_xp, slump_ratio,
              slump_flagged = slump_test_ratio < 1, slump_test_ratio, slump_p_value,
              implied_team_total, spread_line, total_line, is_enclosed, roof_unknown, implied_imputed,
              lines_as_of = lines_as_of, pbp_through_week = last_played_week, league_ppg = league_ppg,
              exp_margin, roof_closed_share, proj_roof_closed, proj_roof_open,
              p_039_record, p_4049_record, p_50_record, p_xp_record, krate_4049, krate_40plus, coach_long_fg_rate,
              model = "new model (2026-10-06)")
  out <- shape(full) |> dplyr::arrange(dplyr::desc(projected_points))
  scen <- NULL
  if (any(unk)) scen <- dplyr::bind_rows(lapply(list(list("closed", cl_all, 1), list("open", op_all, 0)), function(s) { x <- s[[2]]$v; i <- which(unk)
    sm <- do.call(rbind, lapply(i, function(k) stat(pmf(x, k)))); cs <- qci(s[[2]]$draws[i, , drop = FALSE]); colnames(cs) <- c("ci_low", "ci_high")
    f <- dplyr::bind_cols(proj[i, setdiff(names(proj), REC)], x[i, V], rec[i, ], tibble::as_tibble(sm), tibble::as_tibble(cs)) |>
      dplyr::mutate(is_enclosed = s[[3]], proj_roof_closed = NA_real_, proj_roof_open = NA_real_)
    shape(f) |> dplyr::mutate(roof_assumed = s[[1]], .after = opponent) })) |> dplyr::arrange(team, roof_assumed)
  dist_long <- dplyr::bind_rows(lapply(seq_along(dists), function(i)
    tibble::tibble(season = season, week = week, team = proj$posteam[i], kicker_player_name = proj$kicker_player_name[i],
                   kicker_player_id = proj$kicker_player_id[i], points = dists[[i]]$points, prob = dists[[i]]$prob)))
  list(out = out, dist_long = dist_long, scenarios = scen)
}
