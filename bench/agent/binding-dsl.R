# A closed proposal language for the bench binding prototype.
#
# This file deliberately has no dependency on the gloss package.  It is used
# by the public-material reader, the enumeration arm and the checker.  A
# proposal is data.  It is never evaluated as R code.

binding_dsl_version <- "0.1.0"

binding_none_reasons <- c(
  "no verifiable row or geometry",
  "text has no table match",
  "geometry is unsupported",
  "table is withheld",
  "layer ownership is unknown",
  "open-world meaning is not a binding"
)

binding_rows_kinds <- c("all", "non_missing", "equals")
binding_order_kinds <- c("build", "column")
binding_per_row_kinds <- c("one", "column", "length")
binding_anchor_kinds <- c("center", "first_vertex", "last_vertex", "justification")

`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a

binding_scalar <- function(x) {
  is.atomic(x) && is.null(dim(x)) && length(x) == 1L && !is.list(x)
}

binding_string <- function(x) binding_scalar(x) && is.character(x) && nzchar(x)

binding_named_list <- function(x) is.list(x) && !is.null(names(x)) && all(nzchar(names(x)))

binding_unknown <- function(x, allowed, path) {
  bad <- setdiff(names(x) %||% character(), allowed)
  if (length(bad)) sprintf("%s has unknown field(s): %s", path, paste(bad, collapse = ", ")) else character()
}

binding_validate_rows <- function(x, path = "rows") {
  if (!binding_named_list(x)) return(sprintf("%s must be an object", path))
  out <- binding_unknown(x, c("kind", "column", "value"), path)
  if (!binding_string(x$kind) || !x$kind %in% binding_rows_kinds) {
    return(c(out, sprintf("%s.kind must be one of %s", path, paste(binding_rows_kinds, collapse = ", "))))
  }
  if (x$kind %in% c("non_missing", "equals") && !binding_string(x$column)) {
    out <- c(out, sprintf("%s.column is required", path))
  }
  if (x$kind == "equals" && !binding_scalar(x$value)) {
    out <- c(out, sprintf("%s.value must be a scalar already present in the table", path))
  }
  if (x$kind != "equals" && !is.null(x$value)) out <- c(out, sprintf("%s.value is only allowed for equals", path))
  if (x$kind == "all" && (!is.null(x$column) || !is.null(x$value))) {
    out <- c(out, sprintf("%s.all cannot carry column or value", path))
  }
  out
}

binding_validate_order <- function(x, path = "order") {
  if (!binding_named_list(x)) return(sprintf("%s must be an object", path))
  out <- binding_unknown(x, c("kind", "column", "decreasing"), path)
  if (!binding_string(x$kind) || !x$kind %in% binding_order_kinds) {
    return(c(out, sprintf("%s.kind must be one of %s", path, paste(binding_order_kinds, collapse = ", "))))
  }
  if (x$kind == "column" && !binding_string(x$column)) out <- c(out, sprintf("%s.column is required", path))
  if (!is.null(x$decreasing) && !(binding_scalar(x$decreasing) && is.logical(x$decreasing))) {
    out <- c(out, sprintf("%s.decreasing must be TRUE or FALSE", path))
  }
  if (x$kind == "build" && (!is.null(x$column) || !is.null(x$decreasing))) {
    out <- c(out, sprintf("%s.build cannot carry column or decreasing", path))
  }
  out
}

binding_validate_per_row <- function(x, path = "per_row") {
  if (!binding_named_list(x)) return(sprintf("%s must be an object", path))
  out <- binding_unknown(x, c("kind", "column"), path)
  if (!binding_string(x$kind) || !x$kind %in% binding_per_row_kinds) {
    return(c(out, sprintf("%s.kind must be one of %s", path, paste(binding_per_row_kinds, collapse = ", "))))
  }
  if (x$kind %in% c("column", "length") && !binding_string(x$column)) {
    out <- c(out, sprintf("%s.column is required", path))
  }
  if (x$kind == "one" && !is.null(x$column)) out <- c(out, sprintf("%s.one cannot carry column", path))
  out
}

binding_validate_shift <- function(x, path = "shift") {
  if (!binding_named_list(x)) return(sprintf("%s must be an object", path))
  out <- binding_unknown(x, c("kind", "name"), path)
  if (!binding_string(x$kind) || !x$kind %in% c("none", "parameter")) {
    return(c(out, sprintf("%s.kind must be none or parameter", path)))
  }
  if (x$kind == "parameter" && !binding_string(x$name)) out <- c(out, sprintf("%s.name is required", path))
  if (x$kind == "none" && !is.null(x$name)) out <- c(out, sprintf("%s.none cannot carry name", path))
  out
}

binding_validate_anchor <- function(x, path = "anchor") {
  if (!binding_named_list(x)) return(sprintf("%s must be an object", path))
  out <- binding_unknown(x, c("kind"), path)
  if (!binding_string(x$kind) || !x$kind %in% binding_anchor_kinds) {
    out <- c(out, sprintf("%s.kind must be one of %s", path, paste(binding_anchor_kinds, collapse = ", ")))
  }
  out
}

binding_validate_match <- function(x, path = "match") {
  if (!binding_named_list(x)) return(sprintf("%s must be an object", path))
  out <- binding_unknown(x, c("column", "normalization"), path)
  if (!binding_string(x$column)) out <- c(out, sprintf("%s.column is required", path))
  if (!is.null(x$normalization) && (!binding_string(x$normalization) ||
                                     !x$normalization %in% c("exact", "trim"))) {
    out <- c(out, sprintf("%s.normalization must be exact or trim", path))
  }
  out
}

binding_validate_proposal <- function(proposal, table = NULL, facts = NULL) {
  if (!binding_named_list(proposal)) return(list(ok = FALSE, errors = "proposal must be an object"))
  allowed <- c("version", "leaf", "table", "rows", "order", "per_row", "shift", "anchor",
               "match", "copy_of", "none", "evidence")
  errors <- binding_unknown(proposal, allowed, "proposal")
  if (!identical(as.character(proposal$version %||% ""), binding_dsl_version)) {
    errors <- c(errors, sprintf("proposal.version must be %s", binding_dsl_version))
  }
  if (!binding_string(proposal$leaf)) errors <- c(errors, "proposal.leaf is required")
  is_none <- !is.null(proposal$none)
  has_copy <- !is.null(proposal$copy_of)
  if (is_none) {
    if (!binding_string(proposal$none) || !proposal$none %in% binding_none_reasons) {
      errors <- c(errors, "proposal.none must be one of the fixed residue reasons")
    }
    if (has_copy || !is.null(proposal$table) || !is.null(proposal$rows) || !is.null(proposal$order) ||
        !is.null(proposal$per_row) || !is.null(proposal$shift) || !is.null(proposal$anchor) ||
        !is.null(proposal$match)) errors <- c(errors, "none proposals cannot carry binding fields")
  } else if (has_copy) {
    if (!binding_string(proposal$copy_of)) errors <- c(errors, "proposal.copy_of must be a leaf id")
    if (!is.null(proposal$table) || !is.null(proposal$rows) || !is.null(proposal$order) ||
        !is.null(proposal$per_row) || !is.null(proposal$shift) || !is.null(proposal$match)) {
      errors <- c(errors, "copy_of proposals cannot carry row-selection fields")
    }
  } else {
    if (!binding_string(proposal$table)) errors <- c(errors, "proposal.table is required")
    if (!is.null(proposal$rows)) errors <- c(errors, binding_validate_rows(proposal$rows))
    if (!is.null(proposal$order)) errors <- c(errors, binding_validate_order(proposal$order))
    if (!is.null(proposal$per_row)) errors <- c(errors, binding_validate_per_row(proposal$per_row))
    if (!is.null(proposal$shift)) errors <- c(errors, binding_validate_shift(proposal$shift))
    if (!is.null(proposal$anchor)) errors <- c(errors, binding_validate_anchor(proposal$anchor))
    if (!is.null(proposal$match)) errors <- c(errors, binding_validate_match(proposal$match))
    if (!is.null(proposal$evidence) && !(is.character(proposal$evidence) && length(proposal$evidence) <= 8L)) {
      errors <- c(errors, "proposal.evidence must be at most eight strings")
    }
  }
  if (!is.null(facts)) {
    leaves <- if (is.data.frame(facts$leaves)) facts$leaves$id else as.character(facts$leaves %||% character())
    tables <- names(facts$tables %||% list())
    if (length(leaves) && !proposal$leaf %in% leaves) errors <- c(errors, sprintf("no leaf '%s'", proposal$leaf))
    if (!is_none && !has_copy && length(tables) && !proposal$table %in% tables) {
      errors <- c(errors, sprintf("no table '%s'", proposal$table))
    }
    if (has_copy && length(leaves) && !proposal$copy_of %in% leaves) {
      errors <- c(errors, sprintf("no copy source leaf '%s'", proposal$copy_of))
    }
    if (!is_none && !has_copy && length(tables) && proposal$table %in% tables) {
      d <- facts$tables[[proposal$table]]
      cols <- names(d)
      if (!is.null(proposal$rows$column) && !proposal$rows$column %in% cols) errors <- c(errors, sprintf("rows column '%s' is absent", proposal$rows$column))
      if (!is.null(proposal$order$column) && !proposal$order$column %in% cols) errors <- c(errors, sprintf("order column '%s' is absent", proposal$order$column))
      if (!is.null(proposal$per_row$column) && !proposal$per_row$column %in% cols) errors <- c(errors, sprintf("per_row column '%s' is absent", proposal$per_row$column))
      if (!is.null(proposal$match$column) && !proposal$match$column %in% cols) errors <- c(errors, sprintf("match column '%s' is absent", proposal$match$column))
    }
  }
  if (length(errors)) return(list(ok = FALSE, errors = unique(errors)))
  defaults <- list(rows = list(kind = "all"), order = list(kind = "build"),
                   per_row = list(kind = "one"), shift = list(kind = "none"),
                   anchor = list(kind = "center"))
  for (nm in names(defaults)) if (is.null(proposal[[nm]]) && !is_none && !has_copy) proposal[[nm]] <- defaults[[nm]]
  list(ok = TRUE, errors = character(), proposal = proposal)
}

binding_validate_output <- function(output) {
  if (!binding_named_list(output)) return(list(ok = FALSE, errors = "agent output must be an object"))
  bad <- setdiff(names(output), c("version", "proposals", "analysis", "model"))
  errors <- if (length(bad)) sprintf("agent output has unknown field(s): %s", paste(bad, collapse = ", ")) else character()
  if (!identical(as.character(output$version %||% ""), binding_dsl_version)) errors <- c(errors, "agent output version is not the DSL version")
  ps <- output$proposals
  if (!is.list(ps) || !length(ps) || length(ps) > 64L) errors <- c(errors, "agent output proposals must contain one to 64 objects")
  if (length(errors)) return(list(ok = FALSE, errors = unique(errors)))
  checked <- lapply(ps, binding_validate_proposal)
  errs <- unlist(lapply(seq_along(checked), function(i) if (checked[[i]]$ok) character() else paste0("proposal[", i, "]: ", checked[[i]]$errors)))
  if (length(errs)) return(list(ok = FALSE, errors = errs))
  list(ok = TRUE, errors = character(), proposals = lapply(checked, `[[`, "proposal"))
}

binding_table_rows <- function(table, proposal) {
  n <- nrow(table)
  kind <- proposal$rows$kind
  if (kind == "all") return(seq_len(n))
  col <- table[[proposal$rows$column]]
  if (kind == "non_missing") return(which(!is.na(col)))
  value <- proposal$rows$value
  if (!binding_scalar(value) || !any(!is.na(col) & col == value, na.rm = TRUE)) {
    return(structure(character(), reason = "equals value is absent from the table"))
  }
  which(!is.na(col) & col == value)
}

binding_order_rows <- function(rows, order, table) {
  if (order$kind == "build" || !length(rows)) return(rows)
  col <- table[[order$column]]
  rows[order(col[rows], rows, decreasing = isTRUE(order$decreasing), na.last = TRUE, method = "radix")]
}

binding_per_row_counts <- function(rows, per_row, table) {
  if (per_row$kind == "one") return(rep.int(1L, length(rows)))
  x <- table[[per_row$column]][rows]
  if (per_row$kind == "length") return(as.integer(pmax(0, nchar(as.character(x), type = "chars"))))
  num <- suppressWarnings(as.numeric(x))
  if (anyNA(num) || any(!is.finite(num)) || any(num < 0) || any(num != floor(num))) {
    return(structure(integer(), reason = "per_row column is not a finite non-negative integer"))
  }
  as.integer(num)
}

binding_expand_rows <- function(rows, per_row, table) {
  counts <- binding_per_row_counts(rows, per_row, table)
  if (!length(rows) && !is.null(attr(counts, "reason"))) return(counts)
  if (length(attr(counts, "reason"))) return(counts)
  rep(rows, counts)
}

binding_resolve_rows <- function(proposal, table) {
  rows <- binding_table_rows(table, proposal)
  if (length(attr(rows, "reason"))) return(list(ok = FALSE, reason = attr(rows, "reason")))
  rows <- binding_order_rows(rows, proposal$order, table)
  expanded <- binding_expand_rows(rows, proposal$per_row, table)
  if (length(attr(expanded, "reason"))) return(list(ok = FALSE, reason = attr(expanded, "reason")))
  list(ok = TRUE, rows = rows, expanded = expanded,
       counts = if (length(rows)) tabulate(match(expanded, rows), nbins = length(rows)) else integer())
}

binding_fixed_proposal <- function(leaf, reason) {
  list(version = binding_dsl_version, leaf = as.character(leaf), none = reason)
}

binding_mutate_proposal <- function(proposal, table = NULL, leaves = character()) {
  p <- proposal
  out <- list()
  add <- function(label, value) out[[length(out) + 1L]] <<- list(label = label, proposal = value)
  if (!is.null(p$none)) return(list())
  if (!is.null(p$copy_of)) {
    if (length(leaves) > 1L) add("replace_target", within(p, copy_of <- leaves[leaves != p$copy_of][1L]))
    return(out)
  }
  if (identical(p$order$kind, "build") && !is.null(table) && nrow(table) > 1L) {
    q <- p; q$order <- list(kind = "column", column = names(table)[1L], decreasing = TRUE); add("reverse_or_column_order", q)
  } else if (identical(p$order$kind, "column")) {
    q <- p; q$order <- list(kind = "build"); add("restore_build_order", q)
  }
  if (identical(p$rows$kind, "all") && !is.null(table) && nrow(table)) {
    cols <- names(table)[vapply(table, function(x) anyNA(x), logical(1))]
    if (length(cols)) { q <- p; q$rows <- list(kind = "non_missing", column = cols[1L]); add("change_filter", q) }
  } else if (identical(p$rows$kind, "non_missing")) {
    q <- p; q$rows <- list(kind = "all"); add("remove_filter", q)
  } else if (identical(p$rows$kind, "equals") && !is.null(table)) {
    vals <- unique(table[[p$rows$column]])
    vals <- vals[!is.na(vals) & vals != p$rows$value]
    if (length(vals)) { q <- p; q$rows$value <- vals[1L]; add("change_equals_value", q) }
  }
  if (!is.null(table) && length(leaves) > 1L) {
    q <- p; q$leaf <- leaves[leaves != p$leaf][1L]; add("replace_target", q)
  }
  out
}

binding_enumerate <- function(facts, max_candidates = 2000L) {
  leaves <- facts$leaves
  if (is.data.frame(leaves)) leaves <- leaves$id
  leaves <- as.character(leaves %||% character())
  tables <- facts$tables %||% list()
  out <- list()
  for (leaf in leaves) for (table_name in names(tables)) {
    d <- tables[[table_name]]
    if (!is.data.frame(d) || !nrow(d)) next
    row_specs <- list(list(kind = "all"))
    for (col in names(d)) {
      if (anyNA(d[[col]])) row_specs[[length(row_specs) + 1L]] <- list(kind = "non_missing", column = col)
      vals <- unique(d[[col]])
      vals <- vals[!is.na(vals)]
      if (length(vals) && length(vals) <= 4L) for (value in vals) row_specs[[length(row_specs) + 1L]] <- list(kind = "equals", column = col, value = value)
    }
    orders <- list(list(kind = "build"))
    for (col in names(d)) if (is.numeric(d[[col]]) || is.integer(d[[col]]) || is.character(d[[col]])) orders[[length(orders) + 1L]] <- list(kind = "column", column = col, decreasing = FALSE)
    for (rows in row_specs) for (ord in orders) {
      p <- list(version = binding_dsl_version, leaf = leaf, table = table_name, rows = rows,
                order = ord, per_row = list(kind = "one"), shift = list(kind = "none"),
                anchor = list(kind = "center"))
      out[[length(out) + 1L]] <- p
      if (length(out) >= max_candidates) return(out)
    }
  }
  out
}
