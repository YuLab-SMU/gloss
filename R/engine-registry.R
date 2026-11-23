# Engine registry for built-in and third-party plotting engines.

.gloss_engines <- new.env(parent = emptyenv())
.gloss_engines$registry <- list()
.gloss_engines$seq <- 0L

#' Register a plotting engine with gloss
#'
#' Registers a custom or third-party plotting engine so [gloss()] can dispatch
#' objects of `classes` to `capture_fn`. Built-in engines (`ggplot`,
#' `patchwork`, `heatmap`, `base`, `grid`) use the same registry.
#'
#' @param name Single non-empty string identifying the engine.
#' @param classes Non-empty character vector of S3/S4 class names handled by
#'   this engine (e.g. `c("ggplot", "ggplot2::ggplot")`).
#' @param capture_fn Function that draws and extracts engine IR for an input
#'   object. Called by [gloss()] during capture.
#' @param packages Optional character vector of package names required when
#'   running this engine (checked lazily via [requireNamespace()]).
#' @param version Optional engine version string.
#' @param description Optional short description of the engine.
#' @param priority Integer priority used to break ties when multiple engines
#'   claim the same class (higher wins; ties broken by most recent
#'   registration). Defaults to `0L`.
#' @param page_kind Character hint describing the graphics system drawn by this
#'   engine: `"any"` (default), `"grid"`, or `"base"`. Used to disambiguate
#'   generic inputs such as functions or `recordedplot` objects after drawing.
#' @param overwrite Logical; whether registering an existing `name` replaces
#'   the previous entry. Defaults to `TRUE`.
#'
#' @return Invisibly returns the registered `gloss_engine` specification.
#' @export
#' @examples
#' my_cap <- function(x, ...) x
#' gl_register_engine(
#'   name = "my_custom_plot",
#'   classes = "my_custom_plot",
#'   capture_fn = my_cap,
#'   description = "Example custom engine"
#' )
gl_register_engine <- function(
    name,
    classes,
    capture_fn,
    packages = character(),
    version = NULL,
    description = NULL,
    priority = 0L,
    page_kind = c("any", "grid", "base"),
    overwrite = TRUE) {

  page_kind <- match.arg(page_kind)

  if (!is.character(name) || length(name) != 1L || is.na(name) || !nzchar(name)) {
    cli::cli_abort("{.arg name} must be a single non-empty character string.")
  }
  if (!is.character(classes) || length(classes) == 0L || anyNA(classes) || any(!nzchar(classes))) {
    cli::cli_abort("{.arg classes} must be a non-empty character vector of class names.")
  }
  if (!is.function(capture_fn)) {
    cli::cli_abort("{.arg capture_fn} must be a function.")
  }
  if (!is.character(packages) || anyNA(packages)) {
    cli::cli_abort("{.arg packages} must be a character vector.")
  }
  if (!is.numeric(priority) || length(priority) != 1L || is.na(priority)) {
    cli::cli_abort("{.arg priority} must be a single finite number.")
  }

  if (!isTRUE(overwrite) && name %in% names(.gloss_engines$registry)) {
    cli::cli_abort(
      "Engine {.val {name}} is already registered. Pass {.code overwrite = TRUE} to replace it."
    )
  }

  next_seq <- .gloss_engines$seq + 1L
  .gloss_engines$seq <- next_seq

  spec <- structure(
    list(
      name = name,
      classes = unique(classes),
      capture_fn = capture_fn,
      packages = unique(packages),
      version = if (is.null(version)) NA_character_ else as.character(version)[[1L]],
      description = if (is.null(description)) "" else as.character(description)[[1L]],
      priority = as.integer(priority),
      page_kind = page_kind,
      seq = next_seq
    ),
    class = "gloss_engine"
  )

  .gloss_engines$registry[[name]] <- spec
  invisible(spec)
}

#' @export
print.gloss_engine <- function(x, ...) {
  cat(sprintf("<gloss_engine %s>\n", x$name))
  cat(sprintf("  classes  : %s\n", paste(x$classes, collapse = ", ")))
  if (length(x$packages) > 0L) {
    cat(sprintf("  packages : %s\n", paste(x$packages, collapse = ", ")))
  }
  if (nzchar(x$description)) {
    cat(sprintf("  desc     : %s\n", x$description))
  }
  invisible(x)
}

list_registered_engines <- function() {
  .gloss_engines$registry
}

get_engine <- function(name) {
  if (!is.character(name) || length(name) != 1L || is.na(name)) {
    return(NULL)
  }
  .gloss_engines$registry[[name]]
}

unregister_engine <- function(name) {
  if (is.character(name) && length(name) == 1L && name %in% names(.gloss_engines$registry)) {
    .gloss_engines$registry[[name]] <- NULL
    return(invisible(TRUE))
  }
  invisible(FALSE)
}

reset_engine_registry <- function(register_builtins = TRUE) {
  .gloss_engines$registry <- list()
  .gloss_engines$seq <- 0L
  if (isTRUE(register_builtins)) {
    register_builtin_engines()
  }
  invisible(NULL)
}

missing_engine_packages <- function(spec) {
  if (length(spec$packages) == 0L) {
    return(character())
  }
  spec$packages[!vapply(spec$packages, has_pkg, logical(1L))]
}

engine_version_string <- function(spec) {
  if (!is.na(spec$version) && nzchar(spec$version)) {
    return(spec$version)
  }
  if (length(spec$packages) > 0L && has_pkg(spec$packages[[1L]])) {
    return(as.character(utils::packageVersion(spec$packages[[1L]])))
  }
  as.character(utils::packageVersion("gloss"))
}

#' Resolve candidate engines matching a plot object
#'
#' Returns all engines matching the most specific class in `class(x)` (or the
#' single explicitly named `engine`), ordered by `priority` descending then
#' recency (`seq`) descending. Optionally filters by `page_kind` (`"grid"` or
#' `"base"`) to disambiguate generic objects such as functions or recorded plots.
#' @noRd
resolve_engine_candidates <- function(x, engine = NULL, page_kind = NULL, error = TRUE) {
  reg <- list_registered_engines()

  matches_page_kind <- function(spec) {
    if (is.null(page_kind)) return(TRUE)
    identical(spec$page_kind, "any") || identical(spec$page_kind, page_kind)
  }

  if (!is.null(engine)) {
    spec <- get_engine(engine)
    if (is.null(spec)) {
      if (!isTRUE(error)) return(list())
      cli::cli_abort("Unknown gloss engine {.val {engine}}.")
    }
    missing_pkgs <- missing_engine_packages(spec)
    if (length(missing_pkgs) > 0L) {
      if (!isTRUE(error)) return(list())
      cli::cli_abort(
        "Engine {.val {spec$name}} requires missing package(s): {.pkg {missing_pkgs}}."
      )
    }
    return(list(spec))
  }

  obj_classes <- class(x)
  for (cls in obj_classes) {
    matches <- Filter(function(spec) cls %in% spec$classes, reg)
    if (length(matches) == 0L) next

    ord <- order(
      vapply(matches, function(s) s$priority, integer(1L)),
      vapply(matches, function(s) s$seq, integer(1L)),
      decreasing = TRUE
    )
    matches <- matches[ord]

    available <- Filter(function(s) length(missing_engine_packages(s)) == 0L, matches)
    if (length(available) == 0L) {
      first_missing <- missing_engine_packages(matches[[1L]])
      if (!isTRUE(error)) return(list())
      cli::cli_abort(
        "Engine {.val {matches[[1L]]$name}} for class {.cls {cls}} requires package(s): {.pkg {first_missing}}."
      )
    }

    if (!is.null(page_kind)) {
      filtered <- Filter(matches_page_kind, available)
      if (length(filtered) > 0L) {
        # Prefer exact page_kind match over "any"
        exact <- vapply(filtered, function(s) identical(s$page_kind, page_kind), logical(1L))
        filtered <- c(filtered[exact], filtered[!exact])
        return(filtered)
      }
      next
    }

    return(available)
  }

  if (!isTRUE(error)) return(list())
  cli::cli_abort(
    "No registered gloss engine handles object of class {.cls {obj_classes}}."
  )
}

#' Resolve the single winning engine for a plot object
#' @noRd
resolve_engine <- function(x, engine = NULL, page_kind = NULL, error = TRUE) {
  cands <- resolve_engine_candidates(x, engine = engine, page_kind = page_kind, error = error)
  if (length(cands) == 0L) return(NULL)
  cands[[1L]]
}
