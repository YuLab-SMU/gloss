# Data interface: tables with an inferred row key (design: 行键自动推断).
#
# Inference tries, in order:
#   1. meaningful row names (not 1..n);
#   2. a column the plotting code uses as a label, group or join key;
#   3. a unique column without missing values, character or factor first;
#   4. a unique combination of columns;
#   5. a hash of the row content plus a duplicate index (fragile).
# The rule and its basis are kept with the table; gl_key() changes the key.

key_rownames <- ".rownames"
key_hash <- ".hash"

new_table <- function(spec) {
  if (!is_string(spec$name) || !grepl("^[A-Za-z0-9][A-Za-z0-9_.-]*$", spec$name)) {
    cli::cli_abort("Table names must be letters, digits, '.', '_' or '-'; got {.val {spec$name}}.")
  }
  data <- spec$data
  if (!is.null(data) && !is.data.frame(data)) data <- as.data.frame(data, stringsAsFactors = FALSE)
  k <- if (is.null(data)) list(key = character(), rule = NA_integer_, basis = "no data", fragile = NA)
       else infer_key(data, spec$key_hints %||% character())
  list(
    name = spec$name,
    role = spec$role %||% "raw",
    layer = spec$layer %||% NA_integer_,
    description = spec$description %||% NA_character_,
    referenced = spec$referenced %||% character(),
    data = data,
    key = k$key,
    key_rule = k$rule,
    key_basis = k$basis,
    key_fragile = isTRUE(k$fragile),
    key_history = empty_key_history(),
    status = if (is.null(data)) "missing_data" else "ok"
  )
}

empty_key_history <- function() {
  data.frame(time = character(), from = character(), to = character(),
             by = character(), stringsAsFactors = FALSE)
}

col_is_key <- function(v) {
  !is.list(v) && !anyNA(v) && !anyDuplicated(v)
}

key_tier <- function(v) {
  if (is.character(v) || is.factor(v)) return(1L)
  if (is.integer(v) || is.logical(v)) return(2L)
  if (is.numeric(v) && isTRUE(all(v == round(v)))) return(2L)
  3L
}

#' Infer a row key for a data frame
#'
#' Applies the five inference rules in order and returns the first that
#' holds, with the rule number and the evidence.
#'
#' @param data A data frame.
#' @param hints Columns the plotting code uses as a label, group or join
#'   key, optionally named by their role (e.g. `c(label = "name")`).
#' @return A list with `key` (column names, or `".rownames"` / `".hash"`),
#'   `rule` (1-5), `basis` (a sentence) and `fragile` (`TRUE` for rule 5).
#' @examples
#' gl_infer_key(mtcars)$basis
#' gl_infer_key(iris)$rule
#' @export
gl_infer_key <- function(data, hints = character()) infer_key(data, hints)

infer_key <- function(data, hints = character()) {
  n <- nrow(data)
  rn_auto <- .row_names_info(data, type = 1L) < 0L
  if (!rn_auto && n > 0L) {
    rn <- rownames(data)
    if (!identical(rn, as.character(seq_len(n)))) {
      return(list(key = key_rownames, rule = 1L, fragile = FALSE,
                  basis = sprintf("row names are not 1..n (e.g. '%s')", rn[1])))
    }
  }
  if (length(hints)) {
    roles <- names(hints) %||% rep("", length(hints))
    for (i in seq_along(hints)) {
      h <- hints[[i]]
      if (h %in% names(data) && col_is_key(data[[h]])) {
        role <- if (nzchar(roles[i])) roles[i] else "key"
        return(list(key = h, rule = 2L, fragile = FALSE,
                    basis = sprintf("column '%s' is used as %s in the plotting code and is unique", h, role)))
      }
    }
  }
  cols <- names(data)
  usable <- cols[!vapply(data, is.list, logical(1))]
  tiers <- vapply(usable, function(cn) key_tier(data[[cn]]), integer(1))
  ordered <- usable[order(tiers, seq_along(usable))]
  for (cn in ordered) {
    if (col_is_key(data[[cn]])) {
      return(list(key = cn, rule = 3L, fragile = FALSE,
                  basis = sprintf("column '%s' is unique with no missing values (%s)", cn, type_label(data[[cn]]))))
    }
  }
  complete <- ordered[vapply(ordered, function(cn) !anyNA(data[[cn]]), logical(1))]
  complete <- utils::head(complete, 8L)
  for (m in 2:3) {
    if (length(complete) < m) break
    combos <- utils::combn(complete, m, simplify = FALSE)
    for (cc in combos) {
      if (!anyDuplicated(data[cc])) {
        return(list(key = cc, rule = 4L, fragile = FALSE,
                    basis = sprintf("columns %s are jointly unique", paste0("'", cc, "'", collapse = " + "))))
      }
    }
  }
  list(key = key_hash, rule = 5L, fragile = TRUE,
       basis = "no unique column or combination; rows keyed by a hash of their content plus a duplicate index")
}

type_label <- function(v) {
  if (is.factor(v)) return("factor")
  if (is.character(v)) return("character")
  if (is.integer(v)) return("integer")
  if (is.numeric(v)) return("double")
  class(v)[1]
}

key_values <- function(tbl) {
  data <- tbl$data
  if (is.null(data)) return(NULL)
  key <- tbl$key
  if (identical(key, key_rownames)) return(rownames(data))
  if (identical(key, key_hash)) return(row_hash_keys(data))
  if (length(key) == 1L) return(as.character(data[[key]]))
  do.call(paste, c(lapply(data[key], as.character), sep = "\u001f"))
}

row_hash_keys <- function(data) {
  if (!nrow(data)) return(character())
  txt <- do.call(paste, c(lapply(data, function(v) {
    if (is.list(v)) vapply(v, function(e) paste(format(e), collapse = ","), "") else format(v, digits = 17)
  }), sep = "\u001f"))
  vd <- digest::getVDigest(algo = "xxhash64")
  h <- vd(txt, serialize = FALSE)
  paste0(h, ":", stats_seq_by(h))
}

#' Row keys of a table
#'
#' @param fig A `gloss_figure`.
#' @param table Table name.
#' @return A character vector with one key per row.
#' @export
gl_key_values <- function(fig, table) key_values(get_table(fig, table))

get_table <- function(fig, table) {
  tbl <- fig$tables[[table]]
  if (is.null(tbl)) {
    cli::cli_abort(c("No table named {.val {table}}.", i = "Tables: {.val {names(fig$tables)}}."))
  }
  tbl
}

#' Tables of a figure
#'
#' @param fig A `gloss_figure`.
#' @return A data frame with one row per table: name, role, layer, rows,
#'   columns, key, the inference rule and its basis, whether the key is
#'   fragile, and the table's status (`ok` or `missing_data`).
#' @export
gl_tables <- function(fig) {
  rows <- lapply(fig$tables, function(t) {
    data.frame(
      name = t$name, role = t$role, layer = as.integer(t$layer),
      nrow = if (is.null(t$data)) NA_integer_ else nrow(t$data),
      ncol = if (is.null(t$data)) NA_integer_ else ncol(t$data),
      key = paste(t$key, collapse = " + "), key_rule = as.integer(t$key_rule),
      key_basis = t$key_basis, key_fragile = t$key_fragile, status = t$status,
      stringsAsFactors = FALSE
    )
  })
  if (!length(rows)) {
    return(data.frame(name = character(), role = character(), layer = integer(), nrow = integer(),
                      ncol = integer(), key = character(), key_rule = integer(), key_basis = character(),
                      key_fragile = logical(), status = character(), stringsAsFactors = FALSE))
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Get one table's data
#'
#' @inheritParams gl_key_values
#' @return The data frame, or `NULL` when the data was not embedded.
#' @export
gl_table <- function(fig, table) get_table(fig, table)$data

#' Change a table's row key
#'
#' The new key must identify every row: no duplicates and no missing
#' values. The change is kept in the table's key history. Once records exist
#' (M2), data-key selectors are rewritten from the old key to the new one,
#' since both identify the same rows.
#'
#' @param fig A `gloss_figure`.
#' @param table Table name.
#' @param key Column name(s), `".rownames"`, or `".hash"`.
#' @param by Who made the change.
#' @return The figure with the new key.
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   library(ggplot2)
#'   fig <- gloss(ggplot(mtcars, aes(wt, mpg)) + geom_point(), context = FALSE)
#'   fig <- gl_key(fig, "built_layer1", c("x", "y"))
#'   gl_tables(fig)[, c("name", "key", "key_rule")]
#' }
#' @export
gl_key <- function(fig, table, key, by = "user") {
  tbl <- get_table(fig, table)
  data <- tbl$data
  if (is.null(data)) cli::cli_abort("Table {.val {table}} has no data in this figure; cannot check a new key.")
  if (identical(key, key_rownames)) {
    if (.row_names_info(data, type = 1L) < 0L) cli::cli_abort("Table {.val {table}} has automatic row names.")
  } else if (!identical(key, key_hash)) {
    miss <- setdiff(key, names(data))
    if (length(miss)) cli::cli_abort("Not in table {.val {table}}: {.val {miss}}.")
    if (any(vapply(data[key], anyNA, logical(1)))) cli::cli_abort("A key column has missing values.")
    if (anyDuplicated(data[key])) cli::cli_abort("Key {.val {key}} does not identify rows uniquely.")
  }
  hist <- tbl$key_history
  hist[nrow(hist) + 1L, ] <- list(now_utc(), paste(tbl$key, collapse = " + "),
                                  paste(key, collapse = " + "), by)
  tbl$key_history <- hist
  tbl$key <- key
  tbl$key_rule <- 0L
  tbl$key_basis <- sprintf("set by %s with gl_key()", by)
  tbl$key_fragile <- identical(key, key_hash)
  fig$tables[[table]] <- tbl
  fig
}

# Per-column summary used when tables are embedded as summaries only.
table_summary <- function(data) {
  rows <- lapply(names(data), function(cn) {
    v <- data[[cn]]
    num <- is.numeric(v) && !is.factor(v)
    data.frame(
      column = cn, type = type_label(v), n = length(v), n_missing = sum(is.na(v)),
      n_unique = if (is.list(v)) NA_integer_ else length(unique(v)),
      min = if (num && any(is.finite(v))) min(v[is.finite(v)]) else NA_real_,
      max = if (num && any(is.finite(v))) max(v[is.finite(v)]) else NA_real_,
      stringsAsFactors = FALSE
    )
  })
  if (!length(rows)) return(data.frame())
  do.call(rbind, rows)
}
