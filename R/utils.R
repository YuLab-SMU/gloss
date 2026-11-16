`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

# Version of the plugin-facing core API. Plugins declare the minimum core API
# they need; a different major version is refused.
gloss_api_version <- "0.1.0"

gloss_version <- function() as.character(utils::packageVersion("gloss"))

# Bundle format written by this version of gloss.
bundle_format_version <- "0.3.0"

is_string <- function(x) is.character(x) && length(x) == 1L && !is.na(x)

is_flag <- function(x) is.logical(x) && length(x) == 1L && !is.na(x)

payload_issues <- function(x, path = "<root>") {
  out <- character()
  if (is.character(x)) {
    bad <- grepl("<[^>]+>|javascript:|data:text/html|on[a-z]+\\s*=|url\\s*\\(",
                 x, ignore.case = TRUE, perl = TRUE)
    if (any(bad)) out <- c(out, sprintf("%s contains executable markup", path))
    return(out)
  }
  if (is.function(x) || is.environment(x) || is.language(x) || is.expression(x)) {
    return(sprintf("%s is not JSON-like", path))
  }
  if (is.list(x)) {
    nms <- names(x)
    if (is.null(nms)) nms <- seq_along(x)
    for (i in seq_along(x)) {
      out <- c(out, payload_issues(x[[i]], paste0(path, "$", nms[[i]])))
    }
  }
  out
}

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
