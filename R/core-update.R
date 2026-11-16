# Re-capture and rebase the append-only record log (M2).

rebase_record_state <- function(fig, old_fig = NULL) {
  # First resolve each record against the new substrate.  Dependencies are
  # propagated in a second pass so a valid anchor cannot hide an invalid
  # upstream record.
  for (nm in names(fig$layers %||% list())) {
    st <- fig$layers[[nm]]
    for (rec in st$records %||% list()) {
      checked <- validate_record(fig, rec, strict_anchor = FALSE)
      r <- checked$record
      resolutions <- rebase_anchor_resolutions(fig, rec, checked$resolutions)
      anchor_status <- record_anchor_status(resolutions)
      status <- if (anchor_status != "unique") "invalid" else r$status
      fig <- append_layer_event(fig, nm, record_event(
        "rebase", target_id = rec$id, status = status,
        anchor_status = anchor_status,
        candidates = lapply(resolutions, `[[`, "candidates"),
        resolution = resolutions, check = r$check
      ))
    }
  }
  # Propagate invalidity through the dependency graph.  This is deliberately
  # a fixed point rather than a layer-order assumption: custom layers may
  # depend on any earlier or later registered layer.
  changed <- TRUE
  while (changed) {
    changed <- FALSE
    for (nm in names(fig$layers %||% list())) {
      for (rec in fig$layers[[nm]]$records %||% list()) {
        deps <- as.character(rec$depends_on %||% character())
        if (!length(deps) || rec$status %in% c("invalid", "retracted", "superseded")) next
        dep_recs <- lapply(deps, function(id) tryCatch(record_by_id(fig, id), error = function(e) NULL))
        if (any(vapply(dep_recs, function(d) !is.null(d) && d$status == "invalid", logical(1)))) {
          fig <- append_layer_event(fig, nm, record_event(
            "rebase", target_id = rec$id, status = "invalid",
            anchor_status = rec$anchor_status,
            resolution = rec$resolution,
            reason = "depends on an invalid record"
          ))
          changed <- TRUE
        }
      }
    }
  }
  fig
}

rebase_input <- function(fig, p_edited, trust = FALSE) {
  if (!missing(p_edited) && !is.null(p_edited)) return(p_edited)
  code <- fig$context$code$value %||% fig$context$code$expression %||% NULL
  if (is.null(code)) {
    cli::cli_abort(c(
      "No edited figure or captured drawing code is available for {.code gl_rebase()}.",
      i = "Pass the edited figure explicitly. Code restored from a bundle requires trust = TRUE."
    ))
  }
  if (!isTRUE(trust)) {
    cli::cli_abort(c(
      "Rebasing would execute drawing code recovered from the figure context.",
      i = "Pass the edited figure explicitly, or use trust = TRUE after reviewing the code."
    ))
  }
  # A normal capture stores the expression symbol and the call as context
  # values.  If the caller still has that object, use it after the explicit
  # trust gate; this makes `gl_rebase(fig, trust = TRUE)` useful in the same
  # session without pretending a serialized environment is safe to restore.
  value <- fig$context$code$value %||% list()
  caller <- tryCatch(parent.frame(2L), error = function(e) parent.frame())
  expr_name <- value$expr %||% NULL
  if (is.character(expr_name) && length(expr_name) == 1L &&
      exists(expr_name, envir = caller, inherits = TRUE)) {
    return(get(expr_name, envir = caller, inherits = TRUE))
  }
  call_text <- value$call %||% NULL
  if (is.character(call_text) && length(call_text) == 1L) {
    parsed <- tryCatch(parse(text = call_text), error = function(e) NULL)
    if (!is.null(parsed)) return(eval(parsed[[1L]], envir = caller))
  }
  if (is.character(code) && length(code) == 1L) {
    env <- new.env(parent = parent.frame())
    return(eval(parse(text = code), envir = env))
  }
  if (is.language(code) || is.expression(code)) {
    env <- new.env(parent = parent.frame())
    return(eval(code, envir = env))
  }
  cli::cli_abort("Captured drawing code is not an executable R expression.")
}

#' Re-capture an edited figure and re-resolve all records
#'
#' The old layer logs are copied unchanged.  Rebase appends a rebase event for
#' each current record, marks missing or ambiguous anchors invalid, and then
#' propagates invalidity through `depends_on`.  No old record is overwritten.
#'
#' @param fig A `gloss_figure`.
#' @param p_edited Edited figure object, drawing function, or `NULL` to use
#'   captured context.
#' @param trust Execute captured context code when `p_edited` is omitted.
#' @return A new `gloss_figure` with the old logs and rebase events.
#' @export
gl_rebase <- function(fig, p_edited = NULL, trust = FALSE) {
  check_figure(fig)
  edited <- rebase_input(fig, p_edited, trust = trust)
  bind <- !is.null(fig$derived$bindings)
  classify <- !is.null(fig$derived$roles)
  engine <- fig$meta$engine %||% NULL
  if (!is_string(engine)) engine <- NULL
  out <- gloss(edited, width = fig$meta$width %||% 7,
               height = fig$meta$height %||% 5, context = FALSE,
               engine = engine, bind = bind,
               classify = classify)
  out$layers <- fig$layers
  out$context <- fig$context
  out$meta$parent_id <- fig$meta$id %||% NA_character_
  out$meta$rebase <- list(time = now_utc(), from = fig$meta$id %||% NA_character_)
  rebase_record_state(out, old_fig = fig)
}

#' Compare substrate and record state between two figures
#'
#' @param fig A `gloss_figure`.
#' @param fig2 Another `gloss_figure`.
#' @return A structured diff with substrate, layers, records and status.
#' @export
gl_diff <- function(fig, fig2) {
  check_figure(fig); check_figure(fig2)
  old_el <- fig$substrate$elements$id %||% character()
  new_el <- fig2$substrate$elements$id %||% character()
  old_rows <- gl_records(fig); new_rows <- gl_records(fig2)
  old_ids <- old_rows$id; new_ids <- new_rows$id
  rec_status <- merge(old_rows[, c("id", "status"), drop = FALSE],
                      new_rows[, c("id", "status"), drop = FALSE], by = "id", all = TRUE,
                      suffixes = c("_old", "_new"))
  structure(list(
    substrate = list(id_old = fig$meta$id %||% NA_character_,
                     id_new = fig2$meta$id %||% NA_character_,
                     added_elements = setdiff(new_el, old_el),
                     removed_elements = setdiff(old_el, new_el)),
    records = list(added = setdiff(new_ids, old_ids),
                   removed = setdiff(old_ids, new_ids), status = rec_status),
    layers = list(old = names(fig$layers %||% list()), new = names(fig2$layers %||% list())),
    changed = !identical(fig$meta$id, fig2$meta$id) ||
      !identical(old_el, new_el) || !identical(old_rows$status, new_rows$status)
  ), class = "gloss_diff")
}

#' @export
print.gloss_diff <- function(x, ...) {
  cat(sprintf("<gloss diff> substrate %s; %d added, %d removed record(s)\n",
              if (isTRUE(x$changed)) "changed" else "unchanged",
              length(x$records$added), length(x$records$removed)))
  invisible(x)
}
