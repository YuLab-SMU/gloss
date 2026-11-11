# Plugin registry (ADR-0003). One registration call for eight kinds of
# extension point; built-in plugins register in .onLoad() through the same
# call a third-party package uses.

registry <- new.env(parent = emptyenv())

is_fn <- function(x) is.function(x)
is_chr <- function(x) is.character(x) && length(x) >= 1L && !anyNA(x)
is_list <- function(x) is.list(x)
is_page_kind <- function(x) is_string(x) && x %in% c("grid", "base")

# Required and optional fields per kind, each with a predicate and a label.
plugin_kinds <- function() {
  f <- function(pred, label) list(pred = pred, label = label)
  fn <- f(is_fn, "a function")
  chr <- f(is_chr, "a character vector")
  lst <- f(is_list, "a list")
  str <- f(is_string, "a single string")
  page <- f(is_page_kind, '"grid" or "base"')
  list(
    engine = list(
      required = list(classes = chr, prepare = fn),
      optional = list(page = page, draw = fn, tables = fn, panels = fn, describe = fn,
                      example = fn, packages = chr),
      contract = contract_engine
    ),
    rules = list(
      required = list(engine = chr, rules = lst),
      optional = list(),
      contract = contract_declaration
    ),
    layer = list(
      required = list(body = lst),
      optional = list(depends = chr, verify = fn, scope = str),
      contract = contract_declaration
    ),
    check = list(
      required = list(run = fn),
      optional = list(example = fn),
      contract = contract_declaration
    ),
    operation = list(
      required = list(r = fn),
      optional = list(js = str),
      contract = contract_declaration
    ),
    projection = list(
      required = list(formats = chr, write = fn),
      optional = list(reads = chr),
      contract = contract_projection
    ),
    context = list(
      required = list(item = str, sniff = fn),
      optional = list(restore = fn),
      contract = contract_context
    ),
    stage = list(
      required = list(reads = chr, writes = chr, prompt = str),
      optional = list(tools = chr),
      contract = contract_declaration
    )
  )
}

#' Kinds of extension point
#'
#' @return The names of the eight plugin kinds accepted by [gl_register()].
#' @export
gl_plugin_kinds <- function() names(plugin_kinds())

#' Register a plugin
#'
#' Every extension point of gloss is registered through this one call:
#' engines, classification rules, layers, checks, operations, projections,
#' context sniffers and agent stages. Built-in plugins use it too, from
#' `.onLoad()`; another package does the same from its own `.onLoad()`.
#'
#' The declaration is validated when it is registered: the name and version,
#' the minimum core API version (`api`), the `schema` and the fields required
#' by the kind. Registering the same kind and name again replaces the earlier
#' plugin.
#'
#' Schemas use a small language: a scalar type name (`"string"`, `"number"`,
#' `"integer"`, `"boolean"`, `"any"`), a character vector of length > 1 for
#' an enum, or a named list for an object whose fields are schemas (a name
#' ending in `?` marks an optional field). `list(type = "array", items = )`
#' describes an array.
#'
#' Fields by kind:
#' * `engine`: `classes`, `prepare(x, width, height)`; optional `page`
#'   (`"grid"`, the default, or `"base"`: the kind of page its inputs draw,
#'   which chooses among engines that declare the same class), `draw(state)`,
#'   `tables(state)`, `panels(state, substrate)`, `describe(state)`,
#'   `example()`, `packages`. gloss draws the input itself and captures that
#'   page; `draw` is only for an engine that must keep what drawing returns.
#'   It draws on the current device and returns the state to use afterwards,
#'   and its page must be the page the input draws (the contract test checks
#'   this on `example()`).
#' * `rules`: `engine`, `rules`.
#' * `layer`: `body` (schema); optional `depends`, `verify`, `scope`.
#' * `check`: `run(table, args)`; `schema` describes `args`.
#' * `operation`: `r`; optional `js`.
#' * `projection`: `formats`, `write(fig, path, ...)`; optional `reads`.
#' * `context`: `item`, `sniff(input)`; optional `restore`.
#' * `stage`: `reads`, `writes`, `prompt`; optional `tools`.
#'
#' @param kind One of [gl_plugin_kinds()].
#' @param name Plugin name, unique within its kind.
#' @param version Plugin version, e.g. `"0.1.0"`.
#' @param schema A schema for the plugin's arguments or record body.
#' @param ... Kind-specific fields.
#' @param api Minimum core API version the plugin needs.
#' @param package Package providing the plugin; recorded in bundle manifests.
#' @param description One line describing the plugin.
#' @return The registered plugin, invisibly.
#' @examples
#' gl_register("check", name = "positive", version = "0.1.0",
#'   schema = list(column = "string"),
#'   run = function(table, args) all(table[[args$column]] > 0))
#' gl_plugins("check")
#' gl_unregister("check", "positive")
#' @export
gl_register <- function(kind, name, version, schema = list(), ...,
                        api = gloss_api_version, package = NULL,
                        description = NULL) {
  kinds <- plugin_kinds()
  if (!is_string(kind) || !kind %in% names(kinds)) {
    cli::cli_abort("{.arg kind} must be one of {.val {names(kinds)}}.")
  }
  fields <- list(...)
  plugin <- c(
    list(kind = kind, name = name, version = version, api = api,
         schema = schema, package = package %||% NA_character_,
         description = description %||% NA_character_),
    fields
  )
  problems <- plugin_problems(plugin, kinds[[kind]])
  if (length(problems)) {
    cli::cli_abort(c("Invalid {kind} plugin {.val {name}}.", bullets_x(problems)))
  }
  plugin <- structure(plugin, class = c(paste0("gloss_plugin_", kind), "gloss_plugin"))
  reg <- registry[[kind]] %||% list()
  reg[[name]] <- plugin
  registry[[kind]] <- reg
  invisible(plugin)
}

# cli bullets marked "x"; braces escaped so cli does not interpolate them.
bullets_x <- function(x) {
  x <- gsub("}", "}}", gsub("{", "{{", x, fixed = TRUE), fixed = TRUE)
  names(x) <- rep("x", length(x))
  x
}

plugin_problems <- function(plugin, spec) {
  out <- character()
  if (!is_string(plugin$name) || !grepl("^[A-Za-z][A-Za-z0-9_.-]*$", plugin$name)) {
    out <- c(out, "`name` must be a single string of letters, digits, '.', '_' or '-'.")
  }
  if (!is_string(plugin$version) || is.na(parse_version(plugin$version))) {
    out <- c(out, "`version` must be a version string such as \"0.1.0\".")
  }
  if (!is_string(plugin$api) || is.na(parse_version(plugin$api))) {
    out <- c(out, "`api` must be a version string such as \"0.1.0\".")
  } else if (!api_compatible(plugin$api)) {
    out <- c(out, sprintf("needs core API %s; this gloss provides %s.", plugin$api, gloss_api_version))
  }
  schema_issues <- gl_schema_check(plugin$schema)
  if (length(schema_issues)) out <- c(out, paste("`schema`:", schema_issues))
  for (nm in names(spec$required)) {
    if (is.null(plugin[[nm]])) {
      out <- c(out, sprintf("missing field `%s` (%s).", nm, spec$required[[nm]]$label))
    } else if (!spec$required[[nm]]$pred(plugin[[nm]])) {
      out <- c(out, sprintf("`%s` must be %s.", nm, spec$required[[nm]]$label))
    }
  }
  for (nm in names(spec$optional)) {
    if (!is.null(plugin[[nm]]) && !spec$optional[[nm]]$pred(plugin[[nm]])) {
      out <- c(out, sprintf("`%s` must be %s.", nm, spec$optional[[nm]]$label))
    }
  }
  if (identical(plugin$kind, "layer") && length(plugin$body)) {
    body_issues <- gl_schema_check(plugin$body)
    if (length(body_issues)) out <- c(out, paste("`body`:", body_issues))
  }
  known <- c("kind", "name", "version", "api", "schema", "package", "description",
             names(spec$required), names(spec$optional))
  if (identical(plugin$kind, "engine") && !is.null(plugin$grob)) {
    out <- c(out, paste("`grob` is no longer part of the engine contract (ADR-0006): gloss captures",
                        "the page the input draws. Supply `draw` only to keep what drawing returns."))
    known <- c(known, "grob")
  }
  extra <- setdiff(names(plugin), known)
  if (length(extra)) out <- c(out, sprintf("unknown field(s): %s.", paste(extra, collapse = ", ")))
  out
}

parse_version <- function(x) {
  tryCatch(package_version(x), error = function(e) NA)
}

api_compatible <- function(required) {
  req <- package_version(required)
  have <- package_version(gloss_api_version)
  req$major == have$major && have >= req
}

#' Remove a registered plugin
#'
#' @inheritParams gl_register
#' @return `TRUE` if a plugin was removed, invisibly.
#' @export
gl_unregister <- function(kind, name) {
  reg <- registry[[kind]] %||% list()
  found <- !is.null(reg[[name]])
  reg[[name]] <- NULL
  registry[[kind]] <- reg
  invisible(found)
}

#' Look up a registered plugin
#'
#' @inheritParams gl_register
#' @param must_exist Abort if the plugin is not registered.
#' @return The plugin, or `NULL` when it is not registered and `must_exist`
#'   is `FALSE`.
#' @export
gl_plugin <- function(kind, name, must_exist = TRUE) {
  p <- (registry[[kind]] %||% list())[[name]]
  if (is.null(p) && must_exist) {
    cli::cli_abort("No {kind} plugin named {.val {name}} is registered.")
  }
  p
}

#' List registered plugins
#'
#' @param kind Optional kind to filter by.
#' @return A data frame with one row per plugin: kind, name, version, the
#'   core API version it needs, the providing package and a description.
#' @export
gl_plugins <- function(kind = NULL) {
  kinds <- kind %||% names(plugin_kinds())
  rows <- list()
  for (k in kinds) {
    for (p in registry[[k]] %||% list()) {
      rows[[length(rows) + 1L]] <- data.frame(
        kind = p$kind, name = p$name, version = p$version, api = p$api,
        package = p$package, description = p$description,
        stringsAsFactors = FALSE
      )
    }
  }
  if (!length(rows)) {
    return(data.frame(kind = character(), name = character(), version = character(),
                      api = character(), package = character(), description = character(),
                      stringsAsFactors = FALSE))
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

plugins_of <- function(kind) registry[[kind]] %||% list()

#' @export
print.gloss_plugin <- function(x, ...) {
  cat(sprintf("<gloss %s plugin> %s %s (core API >= %s)\n", x$kind, x$name, x$version, x$api))
  if (!is.na(x$description)) cat(x$description, "\n", sep = "")
  invisible(x)
}

# ---- contract tests -------------------------------------------------------

#' Run the contract tests for a plugin
#'
#' Every kind of extension point has a shared contract. The declaration is
#' re-validated for every kind; engines, projections and context sniffers
#' are also exercised: an engine captures its `example()` input, a
#' projection writes and reads back a small figure, a context sniffer runs on
#' a capture input and its value must survive a JSON round trip.
#'
#' @param kind Plugin kind, or a plugin object.
#' @param name Plugin name, when `kind` is a string.
#' @return A data frame of checks with columns `check`, `passed` (`TRUE`,
#'   `FALSE`, or `NA` when the check could not run) and `message`, with class
#'   `gloss_contract`.
#' @examples
#' res <- gl_test_plugin("context", "env")
#' all(res$passed, na.rm = TRUE)
#' @export
gl_test_plugin <- function(kind, name = NULL) {
  plugin <- if (inherits(kind, "gloss_plugin")) kind else gl_plugin(kind, name)
  spec <- plugin_kinds()[[plugin$kind]]
  checks <- list(contract_check("declaration is valid", {
    pr <- plugin_problems(unclass(plugin), spec)
    if (length(pr)) stop(paste(pr, collapse = "; "))
    TRUE
  }))
  checks <- c(checks, spec$contract(plugin))
  out <- data.frame(
    check = vapply(checks, `[[`, "", "check"),
    passed = vapply(checks, `[[`, NA, "passed"),
    message = vapply(checks, `[[`, "", "message"),
    stringsAsFactors = FALSE
  )
  attr(out, "plugin") <- sprintf("%s/%s", plugin$kind, plugin$name)
  class(out) <- c("gloss_contract", class(out))
  out
}

#' @export
print.gloss_contract <- function(x, ...) {
  cat(sprintf("Contract for %s: %d passed, %d failed, %d skipped\n",
              attr(x, "plugin"), sum(x$passed %in% TRUE), sum(x$passed %in% FALSE),
              sum(is.na(x$passed))))
  for (i in seq_len(nrow(x))) {
    mark <- if (is.na(x$passed[i])) "-" else if (x$passed[i]) "v" else "x"
    cat(sprintf("  %s %s%s\n", mark, x$check[i],
                if (nzchar(x$message[i])) paste0(": ", x$message[i]) else ""))
  }
  invisible(x)
}

# Evaluate `expr`; TRUE passes, FALSE or an error fails, a string skips with
# that message. `expr` must not call return(): it is evaluated in the caller.
contract_check <- function(label, expr) {
  res <- tryCatch(expr, error = function(e) structure(conditionMessage(e), class = "contract_error"))
  if (inherits(res, "contract_error")) {
    return(list(check = label, passed = FALSE, message = unclass(res)))
  }
  if (is.character(res)) {
    return(list(check = label, passed = NA, message = res))
  }
  list(check = label, passed = isTRUE(res), message = if (isTRUE(res)) "" else "returned FALSE")
}

contract_declaration <- function(plugin) list()

contract_engine <- function(plugin) {
  if (is.null(plugin$example)) {
    return(list(contract_check("captures its example", "skipped: the plugin has no example()")))
  }
  fig <- NULL
  out <- list(contract_check("captures its example through gloss()", {
    x <- plugin$example()
    fig <- gloss(x, context = FALSE, engine = plugin$name)
    TRUE
  }))
  if (is.null(fig)) return(out)
  s <- fig$substrate
  c(out, list(
    contract_check("its drawing step draws the page the input draws", {
      if (is.null(plugin$draw)) "skipped: no drawing step; gloss draws the input itself"
      else {
        ex <- plugin$example()
        own <- page_signature(xml2::read_xml(plain_svg(function() draw_input(ex), 7, 5)))
        by_engine <- page_signature(xml2::read_xml(plain_svg(function() {
          plugin$draw(plugin$prepare(ex, 7, 5))
        }, 7, 5)))
        if (!identical(own, by_engine)) {
          stop(sprintf("the engine's page differs from the input's own page in %d primitives",
                       signature_diff(own, by_engine)))
        }
        TRUE
      }
    }),
    contract_check("records the engine in the substrate", identical(fig$meta$engine, plugin$name)),
    contract_check("finds at least one leaf", nrow(s$leaves) > 0L),
    contract_check("every drawn element except the device background has a leaf", {
      unowned <- s$elements[is.na(s$elements$leaf), , drop = FALSE]
      if (nrow(unowned) > 1L) stop(sprintf("%d unowned elements", nrow(unowned)))
      TRUE
    }),
    contract_check("drawn counts add up to the element table", {
      sum(s$leaves$n_drawn) == sum(!is.na(s$elements$leaf))
    }),
    contract_check("every table has a row key", {
      all(vapply(fig$tables, function(t) length(t$key) > 0L, logical(1)))
    }),
    contract_check("panel boxes lie inside the device", {
      # No return() here: the expression is a promise evaluated in this frame.
      p <- s$panels
      w <- fig$meta$width * pt_per_in
      h <- fig$meta$height * pt_per_in
      if (!nrow(p)) "skipped: no panels"
      else all(p$x0 >= -0.01 & p$x1 <= w + 0.01 & p$y0 >= -0.01 & p$y1 <= h + 0.01)
    })
  ))
}

contract_context <- function(plugin) {
  input <- NULL
  item <- NULL
  out <- list(contract_check("sniffs a capture input", {
    input <- contract_context_input()
    item <- run_sniffer(plugin, input)
    TRUE
  }))
  if (is.null(item)) return(out)
  c(out, list(
    contract_check("returns found, or a reason when not found", {
      is_flag(item$found) && (item$found || is_string(item$reason))
    }),
    contract_check("value survives a JSON round trip", {
      back <- json_read(json_write(item$value))
      isTRUE(all.equal(back, item$value, check.attributes = FALSE)) || identical(back, item$value)
    })
  ))
}

contract_context_input <- function() {
  grob <- grid::rectGrob(gp = grid::gpar(fill = "grey90"))
  list(x = grob, expr = quote(grob), call = quote(gloss(grob)), env = globalenv(),
       engine = "grid", tables = list(), width = 4, height = 3, substrate = NULL)
}

contract_projection <- function(plugin) {
  fig <- NULL
  out <- list(contract_check("writes a small figure", {
    fig <- gloss(grid::rectGrob(), context = FALSE, width = 2, height = 2)
    TRUE
  }))
  if (is.null(fig)) return(out)
  for (fmt in plugin$formats) {
    out <- c(out, list(contract_check(sprintf("writes and reads back .%s", fmt), {
      path <- tempfile(fileext = paste0(".", fmt))
      on.exit(unlink(path), add = TRUE)
      plugin$write(fig, path, embed = "all")
      back <- gl_read(path)
      identical(back$substrate$elements, fig$substrate$elements)
    })))
  }
  out
}
