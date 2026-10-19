# Shared data loader for the pipeline (added 2026-09-24). Every script that
# needs play-by-play or schedules sources this file instead of calling
# nflreadr, so the pipeline gives identical results on any machine.
#
# It downloads the same nflverse release files that nflreadr::load_pbp() and
# nflreadr::load_schedules() read, keeps a copy in data/raw/, and reads the
# copy from then on. Confirmed 2026-09-24: a clean run in the Claude workspace
# through this loader reproduced the volume and accuracy tables from the
# user's own nflreadr run, value for value.
#
# Caching rules:
#   - Completed seasons are downloaded once and never re-downloaded, so the
#     training data stays fixed. Delete data/raw/ (or one file in it) to
#     force a fresh copy.
#   - The in-progress season's play-by-play, and the schedules file whenever
#     the in-progress season is requested, are re-downloaded when the local
#     copy is more than a day old, because they change every week.
#   - Every download is recorded in data/raw/download_log.csv (file, time,
#     size), so you can see which snapshot a run used.
#
# Needs only base R (utils) and dplyr - nflreadr is no longer required.

NFLVERSE_RELEASE_URL <- "https://github.com/nflverse/nflverse-data/releases/download"
RAW_DIR <- "data/raw"

# The NFL season in progress on a given date, or NA in the offseason
# (March-August). January-February belong to the previous year's season.
current_nfl_season <- function(today = Sys.Date()) {
  y <- as.integer(format(today, "%Y"))
  m <- as.integer(format(today, "%m"))
  if (m >= 9) y else if (m <= 2) y - 1L else NA_integer_
}

# Returns the local path of a release file, downloading it first if it's
# missing or older than max_age_days.
fetch_release_file <- function(tag, file, max_age_days = Inf) {
  dir.create(RAW_DIR, recursive = TRUE, showWarnings = FALSE)
  dest <- file.path(RAW_DIR, file)
  too_old <- file.exists(dest) &&
    as.numeric(difftime(Sys.time(), file.mtime(dest), units = "days")) > max_age_days
  if (!file.exists(dest) || too_old) {
    url <- paste(NFLVERSE_RELEASE_URL, tag, file, sep = "/")
    message("Downloading ", url)
    old <- options(timeout = max(600, getOption("timeout")))
    on.exit(options(old), add = TRUE)
    tmp <- paste0(dest, ".part")
    utils::download.file(url, tmp, mode = "wb", quiet = TRUE)
    if (file.exists(dest)) file.remove(dest)
    file.rename(tmp, dest)
    log_path <- file.path(RAW_DIR, "download_log.csv")
    entry <- data.frame(file = file, downloaded_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
                        bytes = file.size(dest))
    utils::write.table(entry, log_path, sep = ",", row.names = FALSE,
                       col.names = !file.exists(log_path), append = file.exists(log_path))
  }
  dest
}

# Play-by-play for the given seasons (what nflreadr::load_pbp(seasons) returns).
load_pbp_data <- function(seasons) {
  in_progress <- current_nfl_season()
  dplyr::bind_rows(lapply(seasons, function(s) {
    max_age <- if (!is.na(in_progress) && s == in_progress) 1 else Inf
    readRDS(fetch_release_file("pbp", paste0("play_by_play_", s, ".rds"), max_age))
  }))
}

# Schedules, results and betting lines for the given seasons (what
# nflreadr::load_schedules(seasons) returns).
load_schedule_data <- function(seasons) {
  in_progress <- current_nfl_season()
  max_age <- if (!is.na(in_progress) && in_progress %in% seasons) 1 else Inf
  games <- readRDS(fetch_release_file("schedules", "games.rds", max_age))
  games[games$season %in% seasons, ]
}
