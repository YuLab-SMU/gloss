# A small schema language for plugin arguments and record bodies.
#
# Shorthand forms:
#   "string", "number", "integer", "boolean", "any"   scalar types
#   c("up", "down")                                     enum (length > 1)
#   list(column = "string", "note?" = "string")         object; "?" marks optional
# Explicit forms:
#   list(type = "array", items = <schema>, min = 0, max = Inf)
#   list(type = "object", fields = list(...))
#   list(type = "string", enum = c(...))
#
# Values are JSON-like R objects: scalars, atomic vectors, lists.

schema_scalar_types <- c("string", "number", "integer", "boolean", "any")

schema_normalize <- function(schema) {
  if (is.character(schema) && length(schema) == 1L && schema %in% schema_scalar_types) {
    return(list(type = schema))
  }
  if (is.character(schema) && length(schema) > 1L) {
    return(list(type = "string", enum = schema))
  }
  if (is.list(schema) && is_string(schema$type)) {
    if (identical(schema$type, "object")) {
      schema$fields <- lapply(schema$fields %||% list(), schema_normalize)
    }
    if (identical(schema$type, "array")) {
      schema$items <- schema_normalize(schema$items %||% "any")
    }
    return(schema)
  }
  if (is.list(schema) && (length(schema) == 0L || !is.null(names(schema)))) {
    return(list(type = "object", fields = lapply(schema, schema_normalize)))
  }
  list(type = "invalid", original = schema)
}

#' Check that a schema is well formed
#'
#' @param schema A schema in the gloss schema language (see Details of
#'   [gl_register()]).
#' @return A character vector of problems; empty when the schema is valid.
#' @export
gl_schema_check <- function(schema) {
  schema_check_norm(schema_normalize(schema), "")
}

schema_check_norm <- function(s, path) {
  where <- if (nzchar(path)) path else "<root>"
  type <- s$type
  if (identical(type, "invalid")) {
    return(sprintf("%s: not a schema (use a type name, an enum vector or a named list)", where))
  }
  if (type %in% schema_scalar_types) {
    if (!is.null(s$enum) && !is.character(s$enum)) {
      return(sprintf("%s: enum must be a character vector", where))
    }
    return(character())
  }
  if (identical(type, "array")) {
    return(schema_check_norm(s$items, paste0(path, "[]")))
  }
  if (identical(type, "object")) {
    flds <- s$fields
    if (length(flds) && (is.null(names(flds)) || any(!nzchar(names(flds))))) {
      return(sprintf("%s: every object field needs a name", where))
    }
    out <- character()
    for (nm in names(flds)) {
      out <- c(out, schema_check_norm(flds[[nm]], paste0(path, "$", sub("[?]$", "", nm))))
    }
    return(out)
  }
  sprintf("%s: unknown type '%s'", where, type)
}

#' Validate a value against a schema
#'
#' @param value A JSON-like R value.
#' @param schema A schema in the gloss schema language.
#' @return A character vector of problems; empty when the value conforms.
#' @export
gl_schema_validate <- function(value, schema) {
  schema_validate_norm(value, schema_normalize(schema), "")
}

schema_validate_norm <- function(v, s, path) {
  where <- if (nzchar(path)) path else "<root>"
  bad <- function(msg) sprintf("%s: %s", where, msg)
  switch(s$type,
    any = character(),
    string = {
      if (!is_string(v)) return(bad("expected a single string"))
      if (!is.null(s$enum) && !v %in% s$enum) {
        return(bad(sprintf("'%s' is not one of %s", v, paste(s$enum, collapse = ", "))))
      }
      character()
    },
    number = if (is.numeric(v) && length(v) == 1L && !is.na(v)) character() else bad("expected a single number"),
    integer = if (is.numeric(v) && length(v) == 1L && !is.na(v) && v == round(v)) character() else bad("expected a single integer"),
    boolean = if (is_flag(v)) character() else bad("expected TRUE or FALSE"),
    array = {
      if (!(is.list(v) && is.null(names(v))) && !is.atomic(v)) return(bad("expected an array"))
      n <- length(v)
      if (!is.null(s$min) && n < s$min) return(bad(sprintf("expected at least %s items", s$min)))
      if (!is.null(s$max) && n > s$max) return(bad(sprintf("expected at most %s items", s$max)))
      out <- character()
      for (i in seq_len(n)) {
        out <- c(out, schema_validate_norm(v[[i]], s$items, sprintf("%s[%d]", path, i)))
      }
      out
    },
    object = {
      if (!is.list(v) || (length(v) && is.null(names(v)))) return(bad("expected a named list"))
      flds <- s$fields
      fnames <- sub("[?]$", "", names(flds))
      optional <- grepl("[?]$", names(flds))
      out <- character()
      extra <- setdiff(names(v), fnames)
      if (length(extra)) out <- c(out, bad(sprintf("unknown field(s): %s", paste(extra, collapse = ", "))))
      for (i in seq_along(flds)) {
        nm <- fnames[i]
        if (is.null(v[[nm]])) {
          if (!optional[i]) out <- c(out, bad(sprintf("missing field '%s'", nm)))
          next
        }
        out <- c(out, schema_validate_norm(v[[nm]], flds[[i]], paste0(path, "$", nm)))
      }
      out
    },
    bad(sprintf("unknown schema type '%s'", s$type))
  )
}
