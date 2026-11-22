# Deterministic, task-scoped context assembly.
#
# Context sniffers describe what a figure has.  These helpers decide which
# parts to put in front of a person or an agent for one request.  They never
# infer a scientific conclusion and they never call a model.  A plan records
# the proposed reads, and a packet records what was actually included,
# omitted, or left for a later read.

context_assembly_version <- "0.1.0"
context_intents <- c("explain", "inspect", "verify", "propose", "compare", "plan")

context_intent <- function(question = NULL, intent = NULL) {
  if (!is.null(intent)) return(match.arg(as.character(intent)[1L], context_intents))
  q <- tolower(trimws(as.character(question %||% "")[1L]))
  if (!nzchar(q)) return("explain")
  if (grepl("\u5b9e\u9a8c|experiment|next|\u4e0b\u4e00\u6b65|hypothes|\u5047\u8bbe|\u5e72\u9884|intervention|design", q, perl = TRUE)) {
    return("plan")
  }
  if (grepl("\u9a8c\u8bc1|\u6838\u9a8c|check|verify|evidence|\u8bc1\u636e|\u652f\u6301|supported|exception|\u4f8b\u5916", q, perl = TRUE)) {
    return("verify")
  }
  if (grepl("\u6bd4\u8f83|compare|\u5bf9\u7167|\u5dee\u5f02|versus| vs\\.? |group", q, perl = TRUE)) {
    return("compare")
  }
  if (grepl("\u6807\u6ce8|annotat|propose|\u8bb0\u5f55|meaning|\u542b\u4e49|\u8bed\u4e49", q, perl = TRUE)) {
    return("propose")
  }
  if (grepl("\u54ea\u91cc|\u54ea\u4e2a|which|where|focus|\u805a\u7126|inspect|\u67e5\u770b|\u770b\u4e00\u4e0b", q, perl = TRUE)) {
    return("inspect")
  }
  "explain"
}

context_trim_text <- function(x, max_chars) {
  if (is.null(x)) return(NULL)
  x <- as.character(x)[1L]
  if (is.na(x)) return(NA_character_)
  if (!is.finite(max_chars) || nchar(x, type = "chars") <= max_chars) return(x)
  paste0(substr(x, 1L, max_chars), "\n[truncated]")
}

context_trim_value <- function(x, max_chars = 4000L, depth = 0L) {
  if (is.null(x)) return(NULL)
  if (depth > 8L) return("[deferred]")
  if (is.character(x)) {
    return(vapply(x, context_trim_text, "", max_chars = max_chars, USE.NAMES = FALSE))
  }
  if (is.factor(x)) return(context_trim_value(as.character(x), max_chars, depth + 1L))
  if (is.data.frame(x)) {
    n <- min(nrow(x), 50L)
    if (!n) return(list())
    return(lapply(seq_len(n), function(i) {
      row <- as.list(x[i, , drop = FALSE])
      row <- lapply(row, function(value) context_trim_value(value, max_chars, depth + 1L))
      row
    }))
  }
  if (is.list(x)) {
    n <- min(length(x), 60L)
    out <- lapply(x[seq_len(n)], context_trim_value, max_chars = max_chars, depth = depth + 1L)
    names(out) <- names(x)[seq_len(n)] %||% NULL
    return(out)
  }
  x
}

context_focus_empty <- function(query = NULL) {
  list(query = query, elements = character(), leaves = character(), panels = character(),
       tables = character(), rows = list(), records = character(), matched_by = character(),
       unresolved = character())
}

context_focus_ids <- function(x) unique(as.character(unlist(x %||% character(), use.names = FALSE)))

context_record_targets <- function(fig, rec) {
  resolutions <- rec$resolution %||% lapply(rec$anchors %||% list(), function(a) {
    tryCatch(gl_resolve_anchor(fig, a), error = function(e) list(status = "missing"))
  })
  ids <- unlist(lapply(resolutions, function(r) {
    if (identical(r$status, "unique")) as.character(r$target %||% character()) else character()
  }), use.names = FALSE)
  unique(ids)
}

context_match_query <- function(fig, query, disclose) {
  q <- tolower(trimws(as.character(query)[1L]))
  out <- context_focus_empty(query)
  if (!nzchar(q)) {
    out$unresolved <- "the focus query is empty"
    return(out)
  }
  el <- fig$substrate$elements
  hit_el <- if (nrow(el)) {
    text <- if ("text" %in% names(el)) as.character(el$text) else rep("", nrow(el))
    hay <- tolower(paste(el$id, el$tag, el$leaf, text, sep = " "))
    el$id[grepl(q, hay, fixed = TRUE)]
  } else character()
  if (length(hit_el)) {
    out$elements <- unique(c(out$elements, hit_el))
    out$matched_by <- c(out$matched_by, "element text, tag or id")
  }

  for (nm in names(fig$tables %||% list())) {
    tbl <- fig$tables[[nm]]
    d <- tbl$data
    if (is.null(d) || !nrow(d)) next
    if (!identical(disclose, "rows")) next
    key <- tryCatch(key_values(tbl), error = function(e) rep("", nrow(d)))
    atomic <- vapply(d, function(x) is.atomic(x) && !is.list(x), logical(1))
    row_data <- d[, atomic, drop = FALSE]
    row_data$.row_key <- as.character(key)
    row_hay <- if (ncol(row_data)) {
      tolower(apply(as.data.frame(row_data, stringsAsFactors = FALSE), 1L, function(row) {
        paste(row, collapse = " ")
      }))
    } else rep("", nrow(d))
    rows <- which(grepl(q, row_hay, fixed = TRUE))
    # A common natural-language form is "column value" or "column=value".
    parts <- strsplit(gsub("=|:", " ", q), "[[:space:]]+", perl = TRUE)[[1L]]
    parts <- parts[nzchar(parts)]
    if (length(parts) >= 2L && parts[1L] %in% names(d)) {
      value <- paste(parts[-1L], collapse = " ")
      rows <- unique(c(rows, which(tolower(as.character(d[[parts[1L]]])) == value)))
    }
    if (length(rows)) {
      out$tables <- unique(c(out$tables, nm))
      out$rows[[nm]] <- rows
      out$matched_by <- c(out$matched_by, paste0("data table ", nm))
    }
    if (grepl(q, tolower(paste(names(d), collapse = " ")), fixed = TRUE)) {
      out$tables <- unique(c(out$tables, nm))
      out$matched_by <- c(out$matched_by, paste0("column name in ", nm))
    }
  }

  records <- tryCatch(gl_records(fig), error = function(e) NULL)
  if (!is.null(records) && nrow(records)) {
    bodies <- if (identical(disclose, "rows")) vapply(records$body, function(b) {
      tolower(json_write(context_trim_value(b, 1200L), pretty = FALSE))
    }, "") else tolower(records$id)
    ids <- records$id[grepl(q, bodies, fixed = TRUE)]
    if (length(ids)) {
      out$records <- unique(c(out$records, ids))
      out$matched_by <- c(out$matched_by, "semantic record text")
    }
    failed <- records$id[records$check_status %in% c("failed", "partial", "refused")]
    if (grepl("exception|\u4f8b\u5916|failed|\u5931\u8d25", q) && length(failed)) {
      out$records <- unique(c(out$records, failed))
      out$matched_by <- c(out$matched_by, "non-passing checks")
    }
  }

  if (!length(out$elements) && length(out$tables) == 0L && !length(out$records)) {
    out$unresolved <- sprintf("no element, data row, table or record matched '%s'", query)
  }
  out
}

context_focus_from_input <- function(fig, focus = NULL, disclose = "rows") {
  if (is.null(focus)) return(context_focus_empty())
  raw <- if (is.character(focus)) {
    ids <- context_focus_ids(focus)
    if (length(ids) && all(ids %in% fig$substrate$elements$id)) list(elements = ids) else
      list(query = paste(focus, collapse = " "))
  } else if (is.list(focus)) focus else cli::cli_abort("{.arg focus} must be a query, element ids or a named list.")
  out <- context_focus_empty(raw$query %||% NULL)
  if (!is.null(raw$query)) out <- context_match_query(fig, raw$query, disclose)
  out$elements <- unique(c(out$elements, context_focus_ids(raw$elements %||% raw$element)))
  out$leaves <- context_focus_ids(raw$leaves %||% raw$leaf)
  out$panels <- context_focus_ids(raw$panels %||% raw$panel)
  out$tables <- unique(c(out$tables, context_focus_ids(raw$tables %||% raw$table)))
  out$records <- unique(c(out$records, context_focus_ids(raw$records %||% raw$record)))
  supplied_rows <- raw$rows %||% list()
  if (length(supplied_rows) && is.null(names(supplied_rows)) && is_string(raw$table)) {
    named_rows <- list()
    named_rows[[as.character(raw$table)[1L]]] <- supplied_rows
    supplied_rows <- named_rows
  }
  if (is.list(supplied_rows) && length(supplied_rows)) {
    for (nm in intersect(names(supplied_rows), names(fig$tables))) {
      if (!nm %in% names(fig$tables)) {
        out$unresolved <- c(out$unresolved, sprintf("no table '%s' in the figure", nm))
        next
      }
      n <- if (is.null(fig$tables[[nm]]$data)) 0L else nrow(fig$tables[[nm]]$data)
      rr <- unique(unlist(supplied_rows[[nm]], use.names = FALSE))
      ok <- is.numeric(rr) & is.finite(suppressWarnings(as.numeric(rr))) & rr %in% seq_len(n)
      if (!all(ok)) out$unresolved <- c(out$unresolved, sprintf("invalid row in '%s'", nm))
      rr <- as.integer(rr[ok])
      if (length(rr)) out$rows[[nm]] <- unique(c(out$rows[[nm]] %||% integer(), rr))
    }
  }

  el <- fig$substrate$elements
  out$tables <- unique(c(out$tables, names(supplied_rows)))
  known <- list(elements = el$id, leaves = fig$substrate$leaves$id,
                panels = fig$substrate$panels$id, tables = names(fig$tables),
                records = gl_records(fig)$id)
  for (key in names(known)) {
    missing <- setdiff(out[[key]], known[[key]])
    if (length(missing)) out$unresolved <- c(out$unresolved, paste("unknown", key, paste(missing, collapse = ", ")))
    out[[key]] <- intersect(out[[key]], known[[key]])
  }
  if (length(out$leaves)) out$elements <- unique(c(out$elements, el$id[el$leaf %in% out$leaves]))
  if (length(out$panels) && "panel" %in% names(el)) out$elements <- unique(c(out$elements, el$id[el$panel %in% out$panels]))
  out$elements <- intersect(out$elements, el$id)

  b <- if (identical(disclose, "rows")) gl_bindings(fig, by = "row", where = list(status = "verified"))
  if (!is.null(b) && nrow(b)) {
    if (length(out$elements)) {
      eb <- b[b$element %in% out$elements, , drop = FALSE]
      for (nm in unique(eb$table[!is.na(eb$table)])) {
        rr <- eb$row[eb$table == nm & !is.na(eb$row)]
        if (length(rr)) out$rows[[nm]] <- unique(c(out$rows[[nm]] %||% integer(), as.integer(rr)))
      }
    }
    if (length(out$tables)) {
      for (nm in intersect(out$tables, names(fig$tables))) {
        rr <- out$rows[[nm]] %||% integer()
        if (length(rr)) out$elements <- unique(c(out$elements, b$element[b$table == nm & b$row %in% rr]))
      }
    }
  }
  out$leaves <- unique(c(out$leaves, el$leaf[el$id %in% out$elements]))
  if ("panel" %in% names(el)) out$panels <- unique(c(out$panels, el$panel[el$id %in% out$elements]))
  out$tables <- unique(c(out$tables, names(out$rows)))
  out$matched_by <- unique(out$matched_by)
  if (!length(out$elements) && !length(out$tables) && !length(out$records) && !length(out$unresolved)) {
    out$unresolved <- "the supplied focus resolved to no substrate element, data row or record"
  }
  out
}

context_available_items <- function(fig) {
  ctx <- fig$context %||% list()
  if (!length(ctx)) return(list())
  lapply(ctx, function(x) list(item = x$item, found = isTRUE(x$found),
                               plugin = x$plugin %||% NA_character_,
                               reason = x$reason %||% NULL))
}

context_requested_items <- function(intent) {
  base <- c("code", "data", "engine", "doc", "analysis_method")
  switch(intent,
    explain = c(base, "data_dictionary", "dataset_documentation", "ontology", "literature", "user_context", "project_notes"),
    inspect = c(base, "data_dictionary", "user_context"),
    verify = c(base, "env", "git", "external_metadata", "data_dictionary", "user_context"),
    propose = c(base, "project_notes", "user_context", "literature", "ontology"),
    compare = c(base, "data_dictionary", "external_metadata", "literature"),
    plan = c(base, "user_context", "literature", "ontology", "external_metadata", "project_notes"),
    base
  )
}

context_plan_steps <- function(intent, focus, disclose, max_rows, max_chars) {
  steps <- list(
    list(id = "figure", source = "substrate", disclosure = "summary", required = TRUE,
         reason = "The figure geometry, panels and engine contract are deterministic facts."),
    list(id = "focus", source = "focus", disclosure = "summary", required = TRUE,
         reason = "The request's selected scope must be explicit before rows or records are read."),
    list(id = "data", source = "tables", disclosure = disclose, required = TRUE,
         reason = "Data summaries establish row keys, table status and available measurements."),
    list(id = "bindings", source = "derived.bindings", disclosure = disclose, required = FALSE,
         reason = "Only checked element-to-row correspondences may be used as evidence."),
    list(id = "semantics", source = "layers", disclosure = "summary", required = TRUE,
         reason = "Existing semantic records and check states constrain the conversation."),
    list(id = "context", source = "context", disclosure = disclose, required = FALSE,
         reason = "Code, documents, user intent and domain sources are selected from captured context."),
    list(id = "continuation", source = "actions", disclosure = "summary", required = TRUE,
         reason = "Unselected sources remain available through named, auditable follow-up reads.")
  )
  for (i in seq_along(steps)) {
    steps[[i]]$budget <- list(rows = as.integer(max_rows), chars = as.integer(max_chars))
  }
  steps
}

#' Plan a task-specific context packet for a figure
#'
#' The plan is deterministic and model-agnostic. It records an inferred or
#' supplied intent, a resolved focus, the sources that will be read and the
#' budgets applied. A plan is a proposal for reads, not a scientific claim.
#'
#' @param fig A `gloss_figure`.
#' @param question Optional natural-language request from a person or agent.
#' @param focus Optional element ids, data selectors, record ids or a named
#'   list with `query`, `elements`, `table`, `rows` or `records`.
#' @param intent Optional intent. One of `explain`, `inspect`, `verify`,
#'   `propose`, `compare` or `plan`.
#' @param disclose Maximum disclosure level for the packet.
#' @param max_rows Maximum number of data rows per selected table.
#' @param max_chars Character budget for a context item.
#' @param sources Optional context item names to read, including attached method
#'   descriptions or third-party context plugins. Defaults depend on intent.
#' @param layers Optional semantic layers that may be read. `NULL` reads all
#'   layers. Stage-scoped callers should pass the stage's declared reads.
#' @return A `gloss_context_plan` list.
#' @export
gl_context_plan <- function(fig, question = NULL, focus = NULL, intent = NULL,
                            disclose = c("summary", "schema", "rows", "none"),
                            max_rows = 20L, max_chars = 4000L, sources = NULL,
                            layers = NULL) {
  check_figure(fig)
  if (!is.null(question) && !is_string(question)) {
    cli::cli_abort(" {.arg question} must be a single character string or NULL.")
  }
  disclose <- match.arg(disclose)
  valid_limit <- function(x) length(x) == 1L && is.numeric(x) &&
    isTRUE(is.finite(x)) && x == floor(x) && x >= 0 && x <= .Machine$integer.max
  if (!valid_limit(max_rows) || !valid_limit(max_chars) || max_chars < 1L) {
    cli::cli_abort("Provide whole number budgets, with max_rows >= 0 and max_chars >= 1.")
  }
  q <- if (is.null(question)) NULL else context_trim_text(question, max_chars)
  intent <- context_intent(q, intent)
  resolved <- context_focus_from_input(fig, focus, disclose)
  counts <- lengths(resolved$rows)
  selected_count <- length(resolved$elements)
  resolved$rows <- lapply(resolved$rows, utils::head, n = max_rows)
  resolved$elements <- utils::head(resolved$elements, 50L)
  resolved$records <- utils::head(resolved$records, 60L)
  if (!is.null(sources) && (!is.character(sources) || anyNA(sources))) {
    cli::cli_abort("{.arg sources} must contain context item names.")
  }
  if (!is.null(layers) && (!is.character(layers) || anyNA(layers))) {
    cli::cli_abort("{.arg layers} must contain semantic layer names.")
  }
  sources <- unique(sources %||% context_requested_items(intent))
  layers <- unique(as.character(layers %||% names(fig$layers %||% list())))
  unknown_layers <- setdiff(layers, names(fig$layers %||% list()))
  if (length(unknown_layers)) {
    cli::cli_abort("Unknown semantic layer(s) in {.arg layers}: {.val {unknown_layers}}.")
  }
  steps <- context_plan_steps(intent, resolved, disclose, max_rows, max_chars)
  plan <- list(
    version = context_assembly_version,
    intent = intent,
    question = q,
    focus = resolved,
    scoped = !is.null(focus),
    matched = list(row_counts = as.list(counts), element_count = selected_count),
    sources = sources,
    layers = layers,
    steps = steps,
    budgets = list(max_rows = max_rows, max_chars = max_chars, disclose = disclose),
    available = context_available_items(fig),
    substrate_id = fig$meta$id %||% NULL
  )
  plan$digest <- record_digest(plan)
  structure(plan, class = c("gloss_context_plan", "list"))
}

context_table_summary <- function(tbl, disclose = "summary", max_chars = 4000L) {
  d <- tbl$data
  if (identical(disclose, "none")) {
    return(list(name = tbl$name, role = tbl$role,
                rows = if (is.null(d)) NULL else nrow(d),
                key = tbl$key, key_fragile = tbl$key_fragile, status = tbl$status))
  }
  columns <- if (is.null(d)) list() else lapply(names(d), function(nm) {
    v <- d[[nm]]
    item <- list(name = nm, type = class(v)[1L])
    if (disclose %in% c("summary", "rows") && is.numeric(v) && any(is.finite(v))) {
      item$min <- min(v[is.finite(v)])
      item$max <- max(v[is.finite(v)])
    }
    item
  })
  list(name = tbl$name, role = tbl$role, rows = if (is.null(d)) NULL else nrow(d),
       key = tbl$key, key_basis = context_trim_text(tbl$key_basis, max_chars),
       key_fragile = tbl$key_fragile, status = tbl$status, columns = columns)
}

context_atomic_rows <- function(d, rows, max_rows) {
  if (is.null(d) || !nrow(d) || !length(rows) || max_rows < 1L) return(NULL)
  rows <- utils::head(unique(as.integer(rows)), max_rows)
  keep <- vapply(d, function(x) is.atomic(x) && !is.list(x), logical(1))
  out <- d[rows, keep, drop = FALSE]
  out$.row <- rows
  rownames(out) <- NULL
  out
}

context_focus_payload <- function(fig, focus, max_chars = 4000L) {
  el <- fig$substrate$elements
  selected <- el[el$id %in% focus$elements, intersect(c("id", "tag", "leaf", "panel", "x0", "y0", "x1", "y1", "fill", "text"), names(el)), drop = FALSE]
  list(query = focus$query, matched_by = focus$matched_by,
       elements = context_trim_value(selected, max_chars), leaves = focus$leaves,
       panels = focus$panels, tables = focus$tables, rows = focus$rows,
       records = focus$records, unresolved = focus$unresolved)
}

context_bindings_payload <- function(fig, focus, disclose, max_rows) {
  if (disclose %in% c("none", "schema") || !length(focus$elements)) return(NULL)
  b <- gl_bindings(fig, by = if (disclose == "rows") "row" else "element")
  if (is.null(b) || !nrow(b)) return(NULL)
  cols <- c("element", "leaf", "table", "status", if (disclose == "rows") "row")
  out <- b[b$element %in% focus$elements, intersect(cols, names(b)), drop = FALSE]
  if (!nrow(out)) return(NULL)
  context_trim_value(utils::head(out, max_rows), 4000L)
}

context_records_payload <- function(fig, focus, disclose, max_chars, scoped, layers = NULL) {
  rows <- tryCatch(gl_records(fig), error = function(e) NULL)
  if (is.null(rows) || !nrow(rows)) return(list())
  recs <- attr(rows, "records") %||% list()
  keep <- vapply(recs, function(r) {
    if (!is.null(layers) && !r$layer %in% layers) return(FALSE)
    if (!scoped) return(TRUE)
    r$id %in% focus$records || length(intersect(context_record_targets(fig, r), focus$elements)) > 0L
  }, logical(1))
  recs <- recs[keep]
  if (length(recs) > 60L) recs <- recs[seq_len(60L)]
  lapply(recs, function(r) {
    out <- list(id = r$id, layer = r$layer, status = r$status, anchor_status = r$anchor_status,
                targets = context_record_targets(fig, r))
    out$check_status <- r$check$status %||% NULL
    if (identical(disclose, "rows")) {
      out$check <- context_trim_value(r$check %||% NULL, max_chars)
      out$depends_on <- as.character(r$depends_on %||% character())
    }
    if (identical(disclose, "schema")) {
      out$body_fields <- names(r$body %||% list())
    } else if (identical(disclose, "rows")) {
      out$body <- context_trim_value(r$body %||% list(), max_chars)
      out$provenance <- context_trim_value(r$provenance %||% list(), max_chars)
    }
    out
  })
}

context_item_payload <- function(item, info, disclose, max_chars) {
  if (is.null(info)) return(list(item = item, found = FALSE, reason = "not captured"))
  out <- list(item = item, found = isTRUE(info$found), plugin = info$plugin,
              version = info$version, reason = info$reason %||% NULL)
  if (!isTRUE(info$found) || disclose == "none") return(out)
  value <- info$value %||% NULL
  if (disclose == "schema") {
    if (is.list(value)) out$fields <- names(value)
    return(out)
  }
  if (disclose == "summary") return(out)
  out$provenance <- info$provenance
  value <- context_trim_value(value, max_chars)
  serialized <- tool_json(value)
  if (nchar(serialized) > max_chars) {
    out$excerpt <- substr(serialized, 1L, max_chars)
    out$truncated <- TRUE
  } else out$value <- value
  out
}

context_actions <- function(plan, context) {
  actions <- list()
  if (!length(plan$focus$elements) && !length(plan$focus$tables) && !length(plan$focus$records)) {
    actions[[length(actions) + 1L]] <- list(name = "focus", mode = "element, data row, group or query",
                                             reason = "a narrower focus will make the next packet smaller and more specific")
  }
  if (length(plan$focus$unresolved)) {
    actions[[length(actions) + 1L]] <- list(name = "clarify_focus", reason = "the supplied focus did not resolve uniquely",
                                             unresolved = plan$focus$unresolved)
  }
  if (plan$budgets$disclose != "rows" && length(plan$focus$elements)) {
    actions[[length(actions) + 1L]] <- list(name = "get_rows", requires = "disclose='rows'",
                                             tables = names(plan$focus$rows), reason = "selected rows were withheld by the disclosure level")
  }
  missing <- vapply(context, function(x) !isTRUE(x$found), logical(1))
  if (any(missing)) {
    actions[[length(actions) + 1L]] <- list(name = "attach_context", items = names(context)[missing],
                                             reason = "the figure reports these context sources as unavailable")
  }
  if (identical(plan$intent, "verify")) {
    actions[[length(actions) + 1L]] <- list(name = "check", requires = "a registered check and selected table",
                                             reason = "a semantic claim should be tested on the embedded table")
  }
  if (identical(plan$intent, "propose")) {
    actions[[length(actions) + 1L]] <- list(name = "propose", requires = "the checked write path",
                                             reason = "writing remains a separate, validated operation")
  }
  if (!length(plan$question)) {
    actions[[length(actions) + 1L]] <- list(name = "ask_user", reason = "no question was supplied")
  }
  actions
}

#' Assemble a bounded, evidence-bearing context packet
#'
#' The packet is a read-only projection of a figure for one conversational turn.
#' It contains the plan, selected facts, semantic records, context slices,
#' omissions and named continuation actions. Re-running it with a new question
#' or focus is the supported way to continue a conversation.
#'
#' @param fig A `gloss_figure`.
#' @param plan Optional plan returned by [gl_context_plan()] for this substrate.
#' @param question Optional natural-language request used to build a plan.
#' @param focus Optional focus passed to [gl_context_plan()].
#' @param intent Optional intent passed to [gl_context_plan()].
#' @param disclose Maximum disclosure level passed to [gl_context_plan()].
#' @param max_rows Maximum number of selected rows per table.
#' @param max_chars Character budget for a context item.
#' @param sources Optional context item names passed to [gl_context_plan()].
#' @param layers Optional semantic layers that may be read by this packet.
#' @return A `gloss_context_packet` list.
#' @export
gl_context_assemble <- function(fig, plan = NULL, question = NULL, focus = NULL,
                                 intent = NULL,
                                 disclose = c("summary", "schema", "rows", "none"),
                                 max_rows = 20L, max_chars = 4000L, sources = NULL,
                                 layers = NULL) {
  check_figure(fig)
  if (is.null(plan)) {
    plan <- gl_context_plan(fig, question = question, focus = focus, intent = intent,
                            disclose = disclose, max_rows = max_rows, max_chars = max_chars,
                            sources = sources, layers = layers)
  } else if (!inherits(plan, "gloss_context_plan") || !identical(plan$substrate_id, fig$meta$id)) {
    cli::cli_abort("Supply a context plan for this figure's current substrate.")
  }
  if (is.null(plan$focus)) plan$focus <- context_focus_empty()
  context_selected <- lapply(plan$sources, function(nm) {
    x <- fig$context[[nm]]
    context_item_payload(nm, x, plan$budgets$disclose, plan$budgets$max_chars)
  })
  names(context_selected) <- plan$sources
  omitted_context <- setdiff(names(fig$context), plan$sources)
  omitted <- lapply(omitted_context, function(nm) list(source = nm, reason = "not selected for this intent; request it explicitly in a follow-up packet"))
  names(omitted) <- NULL
  for (nm in names(plan$matched$row_counts)) {
    if (plan$matched$row_counts[[nm]] > length(plan$focus$rows[[nm]])) {
      omitted[[length(omitted) + 1L]] <- list(source = nm, reason = "row budget",
                                               matched = plan$matched$row_counts[[nm]])
    }
  }
  if (plan$matched$element_count > length(plan$focus$elements)) {
    omitted[[length(omitted) + 1L]] <- list(source = "focus.elements", reason = "element preview limit",
                                             matched = plan$matched$element_count)
  }

  tables <- lapply(fig$tables %||% list(), context_table_summary,
                   disclose = plan$budgets$disclose, max_chars = plan$budgets$max_chars)
  names(tables) <- names(fig$tables %||% list())
  tables <- context_trim_value(tables, plan$budgets$max_chars)
  rows <- list()
  if (identical(plan$budgets$disclose, "rows")) {
    for (nm in names(plan$focus$rows)) {
      tbl <- fig$tables[[nm]]
      value <- context_atomic_rows(tbl$data, plan$focus$rows[[nm]], plan$budgets$max_rows)
      if (!is.null(value)) rows[[nm]] <- context_trim_value(value, plan$budgets$max_chars)
    }
  } else if (length(plan$focus$elements) || length(plan$focus$rows)) {
    omitted[[length(omitted) + 1L]] <- list(source = "data.rows", reason = "selected rows require disclose='rows'")
  }
  bindings <- context_bindings_payload(fig, plan$focus, plan$budgets$disclose, plan$budgets$max_rows)
  if (is.null(bindings) && length(plan$focus$elements) && plan$budgets$disclose %in% c("none", "schema")) {
    omitted[[length(omitted) + 1L]] <- list(source = "derived.bindings", reason = "element bindings require summary or rows disclosure")
  }
  records <- context_records_payload(fig, plan$focus, plan$budgets$disclose,
                                     plan$budgets$max_chars, plan$scoped,
                                     layers = plan$layers %||% NULL)
  data_section <- list(tables = tables, selected_rows = rows)
  figure <- list(engine = fig$meta$engine, engine_version = fig$meta$engine_version,
                 width = fig$meta$width, height = fig$meta$height,
                 substrate_id = fig$meta$id, elements = nrow(fig$substrate$elements),
                 leaves = nrow(fig$substrate$leaves), panels = context_trim_value(fig$substrate$panels, plan$budgets$max_chars),
                 withheld = context_trim_value(fig$status$withheld %||% NULL, plan$budgets$max_chars))
  evidence <- list(bindings = bindings, record_ids = lapply(records, `[[`, "id"))
  packet <- list(
    version = context_assembly_version,
    request = list(question = plan$question, intent = plan$intent, focus = plan$focus),
    plan = plan,
    sections = list(figure = figure,
                    focus = context_focus_payload(fig, plan$focus, plan$budgets$max_chars),
                    data = data_section,
                    evidence = evidence,
                    semantics = records,
                    context = context_selected),
    available = context_available_items(fig),
    omitted = omitted,
    actions = context_actions(plan, context_selected),
    disclosure = plan$budgets$disclose
  )
  packet$digest <- record_digest(packet)
  structure(packet, class = c("gloss_context_packet", "list"))
}

#' @export
print.gloss_context_plan <- function(x, ...) {
  cat(sprintf("<gloss context plan> %s intent, %d source(s), focus %d element(s)\n",
              x$intent, length(x$sources), length(x$focus$elements)))
  cat(sprintf("  digest: %s\n", x$digest %||% "unhashed"))
  invisible(x)
}

#' @export
print.gloss_context_packet <- function(x, ...) {
  n <- length(x$sections$semantics %||% list())
  cat(sprintf("<gloss context packet> %s intent, %d semantic record(s), %d action(s)\n",
              x$request$intent, n, length(x$actions %||% list())))
  if (length(x$omitted)) cat(sprintf("  omitted: %d source(s) or section(s)\n", length(x$omitted)))
  cat(sprintf("  digest: %s\n", x$digest %||% "unhashed"))
  invisible(x)
}
