`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

# Version of the plugin-facing core API. Plugins declare the minimum core API
# they need; a different major version is refused.
gloss_api_version <- "0.1.0"

gloss_version <- function() as.character(utils::packageVersion("gloss"))

# Bundle format written by this version of gloss.
bundle_format_version <- "0.1.0"

is_string <- function(x) is.character(x) && length(x) == 1L && !is.na(x)

is_flag <- function(x) is.logical(x) && length(x) == 1L && !is.na(x)

# Geometry is kept in SVG user units (1/72 in) rounded to 1/100, the
# precision svglite writes. Rounding through integers makes the value
# identical whether it was parsed from text or decoded from the index.
round_pt <- function(x) round(x * 100) / 100

pt_per_in <- 72

now_utc <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

compact <- function(x) x[!vapply(x, is.null, logical(1))]

pkg_version_or_na <- function(pkg) {
  tryCatch(as.character(utils::packageVersion(pkg)), error = function(e) NA_character_)
}

has_pkg <- function(pkg) requireNamespace(pkg, quietly = TRUE)

new_env <- function() new.env(parent = emptyenv())
