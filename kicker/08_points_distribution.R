# Fantasy-point projection for one kicker-game: the full probability
# distribution, projected points, a confidence interval on the projection,
# and a range of likely outcomes. Added 2026-09-26 (to-do #11).
#
# This file only defines functions. It is sourced by 08a (the backtest) and
# will be sourced by the weekly projection step (#12). Needs base R only.
#
# INPUTS PER KICKER-GAME
#   lambda_xp, lambda_039, lambda_4049, lambda_50 : expected attempts from the
#     four volume models (07), i.e. predict(model, newdata, type = "response").
#   p_039, p_4049, p_50 : the kicker's make chance by range going into the game
#     (script 05's final_rate: shrunk long-run rate x slump adjustment).
#   p_xp : the kicker's XP make chance going into the game (05's xp_accuracy_rate;
#     league XP rate if he has no XP history yet).
#
# SCORING: 3 / 4 / 5 points per made FG from 0-39 / 40-49 / 50+ yards, -1 per
# missed FG, +1 per made XP (a missed XP scores 0).
#
# WHY THE DISTRIBUTION IS EXACT (no simulation): the volume models treat
# attempts in each range as Poisson counts. If attempts are Poisson with mean
# L and each is made with chance p, then makes and misses are two INDEPENDENT
# Poisson counts with means L*p and L*(1-p) (the "thinning" property). So
#   points = 3*A + 4*B + 5*C - D + E
# with A, B, C = makes by range, D = all FG misses, E = XP makes, all
# independent Poisson. The distribution of points is the convolution of those
# five, computed exactly below.
#
# ASSUMPTION TO KEEP IN MIND: the four attempt counts are treated as
# independent given the inputs (the four models were fit separately). If in
# reality they move together or against each other within a game (e.g. a
# game with many TDs has fewer FGs), the true spread of points differs from
# this one. The backtest (08a) checks this by comparing how spread out actual
# results are against what the distributions claim.
#
# PROJECTED POINTS: the average of the distribution,
#   3*L039*p039 + 4*L4049*p4049 + 5*L50*p50 - sum(L*(1-p)) + Lxp*pxp.
#
# CONFIDENCE INTERVAL (the headline range): how sure we are about the projected
# points number itself - NOT where this game's score will land. The inputs are
# estimates, so the projection is uncertain. We redraw the inputs many times
# and recompute the projection each time:
#   - volume-model coefficients: drawn from a multivariate normal with each
#     fitted model's coefficient estimates and their covariance (the standard
#     large-sample uncertainty of a Poisson regression). Weights that 07 fixes
#     instead of estimating (offsets, since 2026-10-05) are added as they are,
#     with no draw, so the interval treats them as known;
#   - FG make chances: drawn from the Beta distribution implied by 05's shrinkage
#     (shrunk rate = (weighted makes + w*league) / (weighted attempts + w), which
#     is the mean of Beta(weighted makes + w*league, weighted misses + w*(1-league)));
#     the slump adjustment, when flagged, multiplies each draw;
#   - XP make chance: Beta(weighted XP makes + 1*league, weighted XP misses +
#     1*(1-league)). 05's XP rate is unshrunk; the weight of 1 attempt is used
#     only to keep the draws valid for a kicker who has made every XP.
# The 5th and 95th percentiles of the redrawn projections form the 90% CI.
#
# RANGE OF LIKELY OUTCOMES: where this game's score will probably land, from
# the distribution: 10th to 90th percentile (the "middle 80%"). Points are whole
# numbers, so the range usually holds a bit more than 80%; the actual
# probability inside it is returned too (outcome_range_prob).

# Probability distribution of a Poisson count times an integer weight, as a
# vector over consecutive integer point values starting at `offset`.
.weighted_poisson_pmf <- function(mean, weight, tail = 1e-10) {
  if (mean <= 0) return(list(p = 1, offset = 0))
  kmax <- qpois(1 - tail, mean)
  pk <- dpois(0:kmax, mean)
  pts <- (0:kmax) * weight
  offset <- min(pts)
  p <- numeric(max(pts) - offset + 1)
  p[pts - offset + 1] <- pk
  list(p = p, offset = offset)
}

.convolve_pmf <- function(a, b) {
  p <- stats::convolve(a$p, rev(b$p), type = "open")
  p[p < 0] <- 0  # FFT rounding
  list(p = p, offset = a$offset + b$offset)
}

# XP-attempt distribution: Poisson (xp_disp >= 1) or, when XP attempts vary
# less than Poisson (xp_disp < 1), a binomial with the same mean and variance
# about xp_disp x mean. Returns probabilities for k = 0, 1, 2, ...
.xp_attempt_pmf <- function(lambda_xp, xp_disp = 1, tail = 1e-10) {
  if (xp_disp >= 1) return(dpois(0:qpois(1 - tail, lambda_xp), lambda_xp))
  n <- max(1, round(lambda_xp / (1 - xp_disp)))
  if (n <= lambda_xp) n <- ceiling(lambda_xp) + 1
  dbinom(0:n, n, lambda_xp / n)
}

# Distribution when FG attempts depend on the game's XP attempts (added
# 2026-09-28, see 12_width_fix_log.md). For each possible XP-attempt count k,
# expected FG attempts in range r are lambda_r * exp(gamma_r * (k - lambda_xp)),
# rescaled so their average over k is still lambda_r; XP makes | k are
# binomial(k, p_xp). With gamma = 0 and xp_disp = 1 this is exactly
# points_pmf() (independent Poisson).
points_pmf_dep <- function(lambda_xp, lambda_039, lambda_4049, lambda_50, p_039, p_4049, p_50, p_xp,
                           gamma = c(0, 0, 0), xp_disp = 1) {
  pk <- .xp_attempt_pmf(lambda_xp, xp_disp); k <- seq_along(pk) - 1
  lam <- c(lambda_039, lambda_4049, lambda_50); pr <- c(p_039, p_4049, p_50)
  norm <- sapply(1:3, function(r) sum(pk * exp(gamma[r] * (k - lambda_xp))))
  total <- NULL
  for (i in seq_along(pk)) {
    if (pk[i] < 1e-12) next
    lk <- lam * exp(gamma * (k[i] - lambda_xp)) / norm
    parts <- list(.weighted_poisson_pmf(lk[1] * pr[1], 3), .weighted_poisson_pmf(lk[2] * pr[2], 4),
                  .weighted_poisson_pmf(lk[3] * pr[3], 5), .weighted_poisson_pmf(sum(lk * (1 - pr)), -1),
                  list(p = dbinom(0:k[i], k[i], p_xp), offset = 0))
    d <- Reduce(.convolve_pmf, parts)
    pts <- d$offset + seq_along(d$p) - 1
    add <- data.frame(points = pts, prob = pk[i] * d$p)
    total <- if (is.null(total)) add else rbind(total, add)
  }
  out <- aggregate(prob ~ points, data = total, FUN = sum)
  out$prob <- out$prob / sum(out$prob)
  out[out$prob > 1e-9, ]
}

# Estimates gamma (how FG attempts in each range move with the game's XP
# attempts) from volume-model fits on training rows: Poisson regression of each
# range's attempts on (XP attempts - fitted XP attempts), offset by the fitted
# attempts. Used by 07 (production values) and 08a (per backtest fold).
estimate_gamma <- function(fits, train) {
  mu <- lapply(fits, function(f) predict(f, train, type = "response"))
  dxp <- train$xp_attempts - mu$xp_attempts
  sapply(c("att_039", "att_4049", "att_50"), function(o)
    coef(glm(train[[o]] ~ dxp + offset(log(mu[[o]])), family = poisson))[["dxp"]])
}

# Full distribution of fantasy points for one kicker-game.
# Returns a data.frame with columns points and prob.
points_pmf <- function(lambda_xp, lambda_039, lambda_4049, lambda_50, p_039, p_4049, p_50, p_xp) {
  misses <- lambda_039 * (1 - p_039) + lambda_4049 * (1 - p_4049) + lambda_50 * (1 - p_50)
  parts <- list(
    .weighted_poisson_pmf(lambda_039 * p_039, 3),
    .weighted_poisson_pmf(lambda_4049 * p_4049, 4),
    .weighted_poisson_pmf(lambda_50 * p_50, 5),
    .weighted_poisson_pmf(misses, -1),
    .weighted_poisson_pmf(lambda_xp * p_xp, 1))
  out <- Reduce(.convolve_pmf, parts)
  d <- data.frame(points = out$offset + seq_along(out$p) - 1, prob = out$p / sum(out$p))
  d[d$prob > 1e-9, ]
}

# Projected points (average of the distribution). Vectorised.
projected_points <- function(lambda_xp, lambda_039, lambda_4049, lambda_50, p_039, p_4049, p_50, p_xp) {
  3 * lambda_039 * p_039 + 4 * lambda_4049 * p_4049 + 5 * lambda_50 * p_50 -
    (lambda_039 * (1 - p_039) + lambda_4049 * (1 - p_4049) + lambda_50 * (1 - p_50)) +
    lambda_xp * p_xp
}

# Summary of one distribution: projection, spread, middle-80% range and the
# probability it actually holds.
summarise_pmf <- function(pmf, lower_q = 0.10, upper_q = 0.90) {
  cdf <- cumsum(pmf$prob)
  lo <- pmf$points[which(cdf >= lower_q - 1e-12)[1]]
  hi <- pmf$points[which(cdf >= upper_q - 1e-12)[1]]
  m <- sum(pmf$points * pmf$prob)
  c(projected_points = m, sd_points = sqrt(sum((pmf$points - m)^2 * pmf$prob)),
    outcome_low = lo, outcome_high = hi,
    outcome_range_prob = sum(pmf$prob[pmf$points >= lo & pmf$points <= hi]))
}

# Draws of the four expected-attempt values for the rows of `newdata`, using
# coefficient draws from each fitted glm. Returns a list of n_rows x n_draws
# matrices, one per model name.
# A model's offset (a term with a fixed weight, e.g. 07's fixed accuracy
# weights) is added to every draw (2026-10-05). model.matrix() leaves offsets
# out, so without this the draws would ignore the fixed weights and the
# interval would sit in the wrong place.
draw_lambdas <- function(fits, newdata, n_draws) {
  lapply(fits, function(f) {
    tt <- stats::delete.response(stats::terms(f))
    mf <- stats::model.frame(tt, newdata)
    X <- stats::model.matrix(tt, mf)
    off <- stats::model.offset(mf)
    if (is.null(off)) off <- 0
    stopifnot(nrow(X) == nrow(newdata))   # a dropped row would misalign the offset
    b <- stats::coef(f); V <- stats::vcov(f)
    z <- matrix(stats::rnorm(length(b) * n_draws), n_draws)
    B <- sweep(z %*% chol(V), 2, b, "+")          # n_draws x n_coef
    exp(X[, names(b), drop = FALSE] %*% t(B) + off) # n_rows x n_draws (offset added to each row)
  })
}

# Draws of a make chance from its Beta distribution; rows x draws matrix.
draw_rates <- function(alpha, beta, n_draws) {
  matrix(stats::rbeta(length(alpha) * n_draws, rep(alpha, n_draws), rep(beta, n_draws)), length(alpha))
}

# Confidence interval on projected points for many kicker-games at once.
#   fits    : named list of the four glms (xp_attempts, att_039, att_4049, att_50)
#   newdata : one row per kicker-game with the volume models' predictors
#   acc     : data.frame, same rows, with columns
#             a_039/b_039, a_4049/b_4049, a_50/b_50 (Beta parameters for FG make
#             chances), slump_ratio, a_xp/b_xp (Beta parameters for XP)
# Returns a matrix with columns ci_low and ci_high.
projection_ci <- function(fits, newdata, acc, n_draws = 2000, level = 0.90) {
  lam <- draw_lambdas(fits, newdata, n_draws)
  p039 <- pmin(draw_rates(acc$a_039, acc$b_039, n_draws) * acc$slump_ratio, 1)
  p4049 <- pmin(draw_rates(acc$a_4049, acc$b_4049, n_draws) * acc$slump_ratio, 1)
  p50 <- pmin(draw_rates(acc$a_50, acc$b_50, n_draws) * acc$slump_ratio, 1)
  pxp <- draw_rates(acc$a_xp, acc$b_xp, n_draws)
  proj <- projected_points(lam$xp_attempts, lam$att_039, lam$att_4049, lam$att_50, p039, p4049, p50, pxp)
  a <- (1 - level) / 2
  t(apply(proj, 1, stats::quantile, probs = c(a, 1 - a), names = FALSE)) |>
    `colnames<-`(c("ci_low", "ci_high"))
}
