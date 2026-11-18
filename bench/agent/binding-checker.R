# Independent replay checker for binding proposals.

source("bench/agent/binding-dsl.R")

binding_reason_row <- function(category, ok, reason, details = list()) {
  data.frame(category = as.character(category), ok = isTRUE(ok), reason = as.character(reason %||% ""),
             stringsAsFactors = FALSE)
}

binding_json_frame <- function(x) {
  if (is.null(x)) return(data.frame())
  if (is.data.frame(x)) return(x)
  if (!length(x)) return(data.frame())
  if (is.list(x) && all(vapply(x, is.list, logical(1)))) {
    keys <- unique(unlist(lapply(x, names), use.names = FALSE))
    out <- lapply(keys, function(k) vapply(x, function(row) {
      value <- row[[k]]
      if (is.null(value) || length(value) != 1L) NA_character_ else as.character(value)
    }, character(1)))
    names(out) <- keys
    return(as.data.frame(out, stringsAsFactors = FALSE))
  }
  as.data.frame(x, stringsAsFactors = FALSE)
}

binding_read_public <- function(dir) {
  check <- binding_check_public_material(dir)
  if (!isTRUE(check$ok)) stop(check$reason)
  facts <- jsonlite::read_json(file.path(dir, "public", "facts.json"), simplifyVector = FALSE)
  facts$elements <- binding_json_frame(facts$elements)
  facts$leaves <- binding_json_frame(facts$leaves)
  facts$panels <- binding_json_frame(facts$panels)
  tabs <- list.files(file.path(dir, "public", "tables"), pattern = "\\.csv$", full.names = TRUE)
  facts$tables <- setNames(lapply(tabs, function(path) {
    d <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
    if ("row" %in% names(d)) d$row <- as.integer(d$row)
    d
  }), sub("\\.csv$", "", basename(tabs)))
  facts
}

binding_open_oracle <- function(dir) {
  path <- file.path(dir, "oracle", "oracle.rds")
  if (!file.exists(path)) stop("hidden binding oracle is absent")
  readRDS(path)
}

binding_leaf <- function(fig, id) {
  leaves <- fig$substrate$leaves
  hit <- which(leaves$id %in% id)
  if (length(hit) != 1L) return(NULL)
  leaves[hit, , drop = FALSE]
}

binding_panel_number <- function(panel) {
  if (length(panel) != 1L || is.na(panel)) return(NA_integer_)
  suppressWarnings(as.integer(sub("^.*?([0-9]+)$", "\\1", as.character(panel))))
}

binding_panel_rows <- function(table, panel) {
  if (!"PANEL" %in% names(table)) return(seq_len(nrow(table)))
  p <- binding_panel_number(panel)
  if (is.na(p)) return(seq_len(nrow(table)))
  k <- suppressWarnings(as.integer(as.character(table$PANEL)))
  hit <- which(k == p)
  if (length(hit)) hit else seq_len(nrow(table))
}

binding_shift <- function(pred, proposal, table, material_facts = NULL) {
  if (is.null(proposal$shift) || identical(proposal$shift$kind, "none")) return(list(ok = TRUE, pred = pred, value = c(x = 0, y = 0)))
  name <- proposal$shift$name
  if (!binding_string(name)) return(list(ok = FALSE, reason = "shift parameter name is absent"))
  candidates <- if (name %in% names(table)) unique(suppressWarnings(as.numeric(table[[name]]))) else numeric()
  candidates <- candidates[is.finite(candidates)]
  if (!length(candidates) && !is.null(material_facts$layer_params)) {
    all <- unlist(material_facts$layer_params, recursive = TRUE, use.names = TRUE)
    candidates <- suppressWarnings(as.numeric(all[grepl(paste0("(^|\\.)", name, "$"), names(all))]))
    candidates <- candidates[is.finite(candidates)]
  }
  if (!length(candidates) || length(unique(candidates)) != 1L) {
    return(list(ok = FALSE, reason = sprintf("shift parameter '%s' is absent or varies by row", name)))
  }
  value <- unique(candidates)[1L]
  # The checker only permits a parameter already captured in the material.  A
  # numeric parameter is interpreted on the page's matching axis.
  if (grepl("x", name, ignore.case = TRUE) && "x" %in% names(pred)) pred$x <- pred$x + value
  if (grepl("y", name, ignore.case = TRUE) && "y" %in% names(pred)) pred$y <- pred$y - value
  list(ok = TRUE, pred = pred, value = value)
}

binding_match_rows <- function(fig, leaf_id, table, match_spec) {
  if (is.null(match_spec)) return(NULL)
  elements <- fig$substrate$elements
  e <- elements[elements$leaf %in% leaf_id, , drop = FALSE]
  if (!nrow(e) || !"text" %in% names(e)) return(structure(integer(), reason = "the target leaf has no text elements"))
  texts <- as.character(e$text)
  values <- as.character(table[[match_spec$column]])
  if (identical(match_spec$normalization %||% "exact", "trim")) {
    texts <- trimws(texts); values <- trimws(values)
  }
  rows <- match(texts, values)
  if (anyNA(rows)) return(structure(integer(), reason = "one or more text elements have no exact table match"))
  as.integer(rows)
}

binding_pred_all <- function(fig, table_name, table, leaf, proposal, material_facts = NULL) {
  panel <- as.character(leaf$panel[1L])
  base_rows <- binding_panel_rows(table, panel)
  all_spec <- proposal
  all_spec$rows <- list(kind = "all")
  all_spec$order <- proposal$order %||% list(kind = "build")
  all_spec$per_row <- proposal$per_row %||% list(kind = "one")
  all_res <- binding_resolve_rows(all_spec, table)
  if (!all_res$ok) return(list(ok = FALSE, reason = all_res$reason))
  all_res$rows <- intersect(all_res$rows, base_rows)
  all_expanded <- binding_expand_rows(all_res$rows, all_spec$per_row, table)
  if (length(attr(all_expanded, "reason"))) return(list(ok = FALSE, reason = attr(all_expanded, "reason")))
  selected <- binding_resolve_rows(proposal, table)
  if (!selected$ok) return(list(ok = FALSE, reason = selected$reason))
  selected$rows <- intersect(selected$rows, base_rows)
  selected_expanded <- binding_expand_rows(selected$rows, proposal$per_row, table)
  if (length(attr(selected_expanded, "reason"))) return(list(ok = FALSE, reason = attr(selected_expanded, "reason")))
  matched <- binding_match_rows(fig, leaf$id[1L], table, proposal$match)
  if (!is.null(matched)) {
    if (length(attr(matched, "reason"))) return(list(ok = FALSE, reason = attr(matched, "reason")))
    selected_expanded <- matched
  }
  # Candidate rows are first, so the core comparison sees the proposal order.
  # The remaining rows stay in the prediction set for ambiguity detection.
  rest <- all_expanded[!seq_along(all_expanded) %in% match(seq_along(all_expanded), match(selected_expanded, all_expanded), nomatch = 0L)]
  # The expression above removes only one occurrence of each selected row.
  # For repeated rows, remove by a stable multiset count instead.
  counts <- table(selected_expanded)
  used <- integer()
  rest <- all_expanded[vapply(all_expanded, function(x) {
    key <- as.character(x)
    if (key %in% names(counts) && (sum(used == key) < counts[[key]])) {
      used <<- c(used, key)
      FALSE
    } else TRUE
  }, logical(1))]
  ordered <- c(selected_expanded, rest)
  placed <- gloss:::placed_rows(fig, table_name, ordered, panel)
  if (is.character(placed)) return(list(ok = FALSE, reason = placed))
  shifted <- binding_shift(placed, proposal, table, material_facts)
  if (!shifted$ok) return(shifted)
  list(ok = TRUE, panel = panel, selected = selected_expanded, all = ordered, pred = shifted$pred,
       shift = shifted$value)
}

binding_copy_result <- function(fig, oracle, proposal, tol = gloss:::bind_tolerance) {
  src <- binding_leaf(fig, proposal$copy_of)
  dst <- binding_leaf(fig, proposal$leaf)
  if (is.null(src) || is.null(dst)) return(list(outcome = "rejected", reports = binding_reason_row("element_leaf_table", FALSE, "copy source or target leaf does not exist")))
  geo <- oracle$geometry
  a <- geo[geo$leaf %in% proposal$copy_of, , drop = FALSE]
  b <- geo[geo$leaf %in% proposal$leaf, , drop = FALSE]
  a <- a[order(a$ordinal), , drop = FALSE]; b <- b[order(b$ordinal), , drop = FALSE]
  if (!nrow(a) || nrow(a) != nrow(b) || !identical(as.character(a$tag), as.character(b$tag))) {
    return(list(outcome = "rejected", reports = binding_reason_row("geometry", FALSE, "copy target has a different element shape or count")))
  }
  dx <- b$x0 - a$x0; dy <- b$y0 - a$y0
  same_text <- if ("text" %in% names(fig$substrate$elements)) {
    identical(as.character(fig$substrate$elements$text[match(a$id, fig$substrate$elements$id)]),
              as.character(fig$substrate$elements$text[match(b$id, fig$substrate$elements$id)]))
  } else TRUE
  constant <- same_text && all(is.finite(c(dx, dy))) && diff(range(dx)) <= tol && diff(range(dy)) <= tol
  if (!constant) return(list(outcome = "rejected", reports = binding_reason_row("geometry", FALSE, "copy offset is not constant element-for-element")))
  source_leaf <- oracle$legacy$leaves[oracle$legacy$leaves$leaf %in% proposal$copy_of, , drop = FALSE]
  status <- if (nrow(source_leaf) && source_leaf$status %in% "verified") "accepted" else "ambiguous"
  list(outcome = status, reports = binding_reason_row("geometry", TRUE, "copy offset measured from device geometry"),
       copy_offset = c(x = mean(dx), y = mean(dy)), source = proposal$copy_of)
}

binding_check_mutations <- function(dir, proposal, table, leaves, oracle, facts) {
  muts <- binding_mutate_proposal(proposal, table, leaves)
  if (!length(muts)) return(list(status = "refused", reason = "no distinct mutation can be generated", rows = data.frame()))
  rows <- lapply(muts, function(m) {
    r <- binding_checker(dir, m$proposal, mutation = FALSE)
    data.frame(label = m$label, outcome = r$outcome, accepted = identical(r$outcome, "accepted"),
               reason = paste(vapply(r$reports$reason, as.character, ""), collapse = " | "), stringsAsFactors = FALSE)
  })
  tab <- do.call(rbind, rows)
  ok <- !any(tab$accepted)
  list(status = if (ok) "passed" else "failed", reason = if (ok) "all generated mutations fail or are ambiguous" else "a mutation was accepted", rows = tab)
}

binding_checker <- function(dir, proposal, mutation = TRUE, tol = gloss:::bind_tolerance) {
  facts <- tryCatch(binding_read_public(dir), error = function(e) e)
  if (inherits(facts, "error")) return(list(outcome = "operational_failure", reports = binding_reason_row("schema", FALSE, conditionMessage(facts))))
  checked <- binding_validate_proposal(proposal, facts = facts)
  if (!checked$ok) return(list(outcome = "rejected", reports = do.call(rbind, lapply(checked$errors, function(e) binding_reason_row("schema", FALSE, e))), proposal = proposal))
  proposal <- checked$proposal
  oracle <- tryCatch(binding_open_oracle(dir), error = function(e) e)
  if (inherits(oracle, "error")) return(list(outcome = "operational_failure", reports = binding_reason_row("oracle", FALSE, conditionMessage(oracle)), proposal = proposal))
  if (!is.null(proposal$none)) return(list(outcome = "none", reports = binding_reason_row("residue", TRUE, proposal$none), proposal = proposal))
  if (!is.null(proposal$copy_of)) {
    result <- binding_copy_result(oracle$figure_object, oracle, proposal, tol)
    if (isTRUE(mutation) && identical(result$outcome, "accepted")) result$mutation <- binding_check_mutations(dir, proposal, data.frame(), facts$leaves$id, oracle, facts)
    if (identical(result$outcome, "accepted") && identical(result$mutation$status, "failed")) result$outcome <- "rejected"
    result$proposal <- proposal
    return(result)
  }
  fig <- oracle$figure_object
  leaf <- binding_leaf(fig, proposal$leaf)
  table <- if (proposal$table %in% names(fig$tables)) fig$tables[[proposal$table]]$data else NULL
  reports <- list()
  if (is.null(leaf) || is.null(table)) {
    reports[[1L]] <- binding_reason_row("element_leaf_table", FALSE, "element, leaf or table does not exist")
    return(list(outcome = "rejected", reports = do.call(rbind, reports), proposal = proposal))
  }
  legacy_leaf <- oracle$legacy$leaves[oracle$legacy$leaves$leaf %in% proposal$leaf, , drop = FALSE]
  if (nrow(legacy_leaf) && legacy_leaf$status %in% c("verified", "ambiguous") && !is.na(legacy_leaf$table[1L]) &&
      nzchar(legacy_leaf$table[1L]) && !identical(as.character(legacy_leaf$table[1L]), as.character(proposal$table))) {
    reports[[length(reports) + 1L]] <- binding_reason_row("layer_ownership", FALSE, "proposal table disagrees with the captured layer owner")
    return(list(outcome = "rejected", reports = do.call(rbind, reports), proposal = proposal))
  }
  candidate <- tryCatch(binding_pred_all(fig, proposal$table, table, leaf, proposal, facts), error = function(e) e)
  if (inherits(candidate, "error")) {
    reports[[1L]] <- binding_reason_row("geometry", FALSE, conditionMessage(candidate))
    return(list(outcome = "rejected", reports = do.call(rbind, reports), proposal = proposal))
  }
  if (!candidate$ok) {
    reports[[1L]] <- binding_reason_row("geometry", FALSE, candidate$reason)
    return(list(outcome = "rejected", reports = do.call(rbind, reports), proposal = proposal))
  }
  cl <- list(leaf = proposal$leaf, table = proposal$table, pred = candidate$pred, rows = candidate$selected)
  check <- tryCatch(gloss:::check_claim(cl, leaf, oracle$geometry, tol), error = function(e) e)
  if (inherits(check, "error")) {
    reports[[1L]] <- binding_reason_row("geometry", FALSE, conditionMessage(check))
    return(list(outcome = "rejected", reports = do.call(rbind, reports), proposal = proposal))
  }
  el <- check$elements
  lv <- check$leaf
  if (identical(lv$status, "ambiguous") || any(el$status == "ambiguous")) {
    reports[[length(reports) + 1L]] <- binding_reason_row("ambiguity", FALSE, "more than one row passes the device comparison")
    outcome <- "ambiguous"
  } else if (!identical(lv$status, "verified") || any(el$status != "verified")) {
    reason <- lv$reason %||% "the candidate row/order/count does not match the device"
    category <- if (identical(lv$status, "count_mismatch")) "count_order" else "geometry"
    reports[[length(reports) + 1L]] <- binding_reason_row(category, FALSE, reason)
    outcome <- "rejected"
  } else {
    reports[[length(reports) + 1L]] <- binding_reason_row("device_geometry", TRUE, "all candidate elements pass the independent device comparison")
    outcome <- "accepted"
  }
  mutation <- if (isTRUE(mutation) && identical(outcome, "accepted")) binding_check_mutations(dir, proposal, table, facts$leaves$id, oracle, facts) else list(status = "not_run", reason = "proposal is not accepted before mutation testing", rows = data.frame())
  if (identical(outcome, "accepted") && !identical(mutation$status, "passed")) {
    reports[[length(reports) + 1L]] <- binding_reason_row("mutation", FALSE, mutation$reason)
    outcome <- "rejected"
  } else if (identical(mutation$status, "passed")) {
    reports[[length(reports) + 1L]] <- binding_reason_row("mutation", TRUE, mutation$reason)
  }
  list(outcome = outcome, reports = do.call(rbind, reports), proposal = proposal,
       leaf = lv, elements = el, mutation = mutation, selected_rows = candidate$selected,
       panel = candidate$panel, shift = candidate$shift)
}
