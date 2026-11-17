# Append-only semantic records and layer logs (ADR-0002).
#
# Derived tables are facts computed by the capture engines.  This file holds
# the other side of the substrate: records proposed by a person, an agent, or
# a plugin.  A layer keeps its materialised current records for fast queries
# and an append-only event log for history and bundle round trips.

record_states <- c("proposed", "verified", "rejected", "superseded",
                   "retracted", "invalid", "speculative")
record_events <- c("add", "revise", "retract", "verify", "rebase",
                   "rewrite")

semantic_check_body_schema <- function() {
  list(
    kind = "string",
    "table?" = "string",
    "args?" = "any"
  )
}

core_layer_body_schema <- function(name) {
  common <- list(
    "text?" = "string",
    "type?" = "string",
    "provenance?" = c("direct", "derived", "speculative"),
    "origin?" = c("direct", "derived", "speculative"),
    "description?" = "string",
    "label?" = "string",
    "value?" = "any",
    "check?" = semantic_check_body_schema(),
    "table?" = "string",
    "evidence?" = "any",
    "rationale?" = "string",
    "keep?" = list(type = "array", items = "string"),
    "name?" = "string",
    "role?" = "string",
    "kind?" = "string",
    "cue?" = "string",
    "rule?" = "string",
    "row?" = "integer",
    "trigger?" = c("hover", "click", "key", "state"),
    "operation?" = "string",
    "field?" = "string",
    "order?" = "integer",
    "alt_text?" = "string",
    "from?" = "any",
    "to?" = "any",
    "basis?" = list(type = "array", items = "string")
  )
  if (name == "binding") {
    common$table <- "string"
  }
  common
}

core_layer_specs <- function() {
  list(
    structure = list(depends = character(), scope = "element"),
    binding = list(depends = "structure", scope = "element"),
    meaning = list(depends = "binding", scope = "element"),
    relation = list(depends = c("structure", "binding"), scope = "element"),
    claim = list(depends = c("meaning", "relation"), scope = "figure"),
    narrative = list(depends = "claim", scope = "figure"),
    behavior = list(depends = c("structure", "relation"), scope = "figure"),
    overlay = list(depends = c("binding", "claim"), scope = "element")
  )
}

register_core_layer <- function(name, depends = character(), scope = "element") {
  body <- core_layer_body_schema(name)
  gl_register(
    "layer", name = name, version = "0.1.0", package = "gloss",
    description = sprintf("Built-in %s semantic record layer", name),
    schema = body, body = body,
    depends = depends, scope = scope
  )
}

register_builtin_layers <- function() {
  specs <- core_layer_specs()
  for (nm in names(specs)) {
    register_core_layer(nm, specs[[nm]]$depends, specs[[nm]]$scope)
  }
}

layer_plugin_info <- function(name) {
  p <- gl_plugin("layer", name, must_exist = FALSE)
  if (is.null(p)) {
    cli::cli_abort("No layer plugin named {.val {name}} is registered.")
  }
  list(name = p$name, version = p$version, package = p$package,
       depends = as.character(p$depends %||% character()),
       scope = p$scope %||% "element")
}

normalize_layer_plugin <- function(plugin, name = NULL) {
  if (is.null(plugin)) return(layer_plugin_info(name))
  plugin$depends <- as.character(unlist(plugin$depends %||% character()))
  plugin$name <- as.character(plugin$name %||% name)[1L]
  plugin$version <- as.character(plugin$version %||% "0.1.0")[1L]
  plugin$package <- as.character(plugin$package %||% "gloss")[1L]
  plugin$scope <- as.character(plugin$scope %||% "element")[1L]
  plugin
}

empty_layers <- function() {
  specs <- core_layer_specs()
  out <- lapply(names(specs), function(nm) {
    list(name = nm, plugin = layer_plugin_info(nm), records = list(), log = list())
  })
  stats::setNames(out, names(specs))
}

layer_file <- function(name) sprintf("layers/%s.jsonl", name)

encode_layers <- function(layers) {
  files <- list()
  for (nm in names(layers %||% list())) {
    log <- layers[[nm]]$log %||% list()
    txt <- if (!length(log)) "" else paste0(vapply(log, function(event) {
      sub("\\n$", "", json_write(event, pretty = FALSE))
    }, ""), collapse = "\n")
    if (nzchar(txt)) txt <- paste0(txt, "\n")
    files[[layer_file(nm)]] <- as_bytes(txt)
  }
  files
}

layers_manifest <- function(layers) {
  lapply(layers %||% list(), function(l) {
    list(plugin = l$plugin, file = layer_file(l$name),
         events = length(l$log %||% list()), records = length(l$records %||% list()))
  })
}

decode_layers <- function(files, manifest) {
  base <- empty_layers()
  if (is.null(manifest) || !length(manifest)) return(base)
  for (nm in names(manifest)) {
    m <- manifest[[nm]]
    path <- m$file %||% layer_file(nm)
    raw <- files[[path]]
    log <- list()
    if (!is.null(raw) && length(raw)) {
      lines <- strsplit(bytes_text(raw), "\n", fixed = TRUE)[[1L]]
      lines <- lines[nzchar(trimws(lines))]
      log <- lapply(lines, function(line) normalize_event_storage(json_read(line)))
    }
    plug <- normalize_layer_plugin(m$plugin %||% layer_plugin_info(nm), nm)
    base[[nm]] <- materialize_layer(log, nm, plug)
  }
  base
}

layer_state <- function(name, plugin = NULL, records = list(), log = list()) {
  list(name = name, plugin = plugin %||% layer_plugin_info(name),
       records = records, log = log)
}

normalize_record_storage <- function(rec) {
  if (!is.list(rec)) return(rec)
  if (!is.null(rec$depends_on)) rec$depends_on <- as.character(unlist(rec$depends_on))
  norm_res <- function(x) {
    if (!is.list(x)) return(x)
    if (!is.null(x$target)) x$target <- as.character(unlist(x$target))
    if (!is.null(x$candidates)) x$candidates <- as.character(unlist(x$candidates))
    x
  }
  if (is.list(rec$resolution)) rec$resolution <- lapply(rec$resolution, norm_res)
  if (is.list(rec$check) && !inherits(rec$check, "gloss_check") &&
      !is.null(rec$check$kind) && !is.null(rec$check$status)) {
    class(rec$check) <- c("gloss_check", "list")
  }
  rec
}

normalize_event_storage <- function(event) {
  if (!is.list(event)) return(event)
  if (is.list(event$record)) event$record <- normalize_record_storage(event$record)
  if (is.list(event$check) && !inherits(event$check, "gloss_check") &&
      !is.null(event$check$kind) && !is.null(event$check$status)) {
    class(event$check) <- c("gloss_check", "list")
  }
  if (!is.null(event$target_id)) event$target_id <- as.character(unlist(event$target_id))[1L]
  if (!is.null(event$candidates)) event$candidates <- lapply(event$candidates, as.character)
  event
}

record_provenance <- function(by, extra = list()) {
  if (is.null(by)) by <- "user"
  if (is.list(by)) {
    out <- by
    if (is.null(out$by)) out$by <- "user"
  } else {
    out <- list(by = as.character(by)[1])
  }
  out$time <- out$time %||% now_utc()
  c(out, extra)
}

record_digest <- function(x) {
  digest::digest(json_write(x, pretty = FALSE), algo = "sha256", serialize = FALSE)
}

new_record_id <- function(fig, layer, anchors, body, provenance) {
  n <- sum(vapply(fig$layers %||% list(), function(l) length(l$log %||% list()), integer(1))) + 1L
  paste0("r_", substr(record_digest(list(layer = layer, anchors = anchors,
                                         body = body, provenance = provenance,
                                         sequence = n)), 1L, 20L))
}

normalize_record_status <- function(status) {
  if (is.null(status)) return("proposed")
  status <- as.character(status)[1]
  if (!status %in% record_states) {
    cli::cli_abort("Unknown record status {.val {status}}.")
  }
  status
}

record_anchor_status <- function(resolutions) {
  if (!length(resolutions)) return("missing")
  st <- vapply(resolutions, `[[`, "", "status")
  if (all(st == "unique")) return("unique")
  if (any(st == "ambiguous")) return("ambiguous")
  "missing"
}

rebase_anchor_resolutions <- function(fig, rec, resolutions) {
  if (!length(resolutions)) return(resolutions)
  for (i in seq_along(resolutions)) {
    old <- rec$resolution[[i]] %||% NULL
    sel <- rec$anchors[[i]]$selectors[[1L]] %||% NULL
    if (is.null(old) || is.null(old$stable_target) || is.null(sel) ||
        !identical(sel$type, "element_id")) next
    cur <- resolutions[[i]]$stable_target %||% character()
    data_changed <- !is.null(old$data_target) &&
      !identical(as.character(old$data_target), as.character(resolutions[[i]]$data_target %||% character()))
    if (!identical(as.character(old$stable_target), as.character(cur)) || data_changed) {
      resolutions[[i]]$status <- "missing"
      resolutions[[i]]$target <- character()
      resolutions[[i]]$candidates <- as.character(resolutions[[i]]$candidates %||% character())
      resolutions[[i]]$reason <- "the element id resolves to a different stable element"
    }
  }
  resolutions
}

record_summary <- function(rec) {
  check <- rec$check
  data.frame(
    id = rec$id %||% NA_character_, layer = rec$layer %||% NA_character_,
    status = rec$status %||% NA_character_,
    anchor_status = rec$anchor_status %||% NA_character_,
    check_status = check$status %||% NA_character_,
    by = rec$provenance$by %||% NA_character_,
    created = rec$created %||% rec$provenance$time %||% NA_character_,
    supersedes = rec$supersedes %||% NA_character_,
    stringsAsFactors = FALSE
  )
}

record_projection_status <- function(rec) {
  body <- rec$body %||% list()
  origin <- body$provenance %||% body$origin %||% NULL
  if (identical(origin, "speculative") || identical(rec$status, "speculative")) {
    return("speculative")
  }
  check <- rec$check
  if (!is.null(check) && identical(check$status, "partial")) return("partial")
  if (!is.null(check) && identical(check$status, "refused")) return("uncheckable")
  rec$status %||% "proposed"
}

record_is_factual <- function(rec) {
  identical(record_projection_status(rec), "verified") &&
    (is.null(rec$check) || !identical(rec$check$status, "failed"))
}

record_rows <- function(fig, layer = NULL, status = NULL) {
  check_figure(fig)
  nms <- names(fig$layers %||% list())
  if (!is.null(layer)) {
    layer <- as.character(layer)
    missing <- setdiff(layer, nms)
    if (length(missing)) cli::cli_abort("Unknown record layer {.val {missing}}.")
    nms <- intersect(nms, layer)
  }
  recs <- unlist(lapply(nms, function(nm) fig$layers[[nm]]$records %||% list()),
                 recursive = FALSE, use.names = FALSE)
  if (length(status)) recs <- Filter(function(r) r$status %in% status, recs)
  if (!length(recs)) {
    out <- data.frame(id = character(), layer = character(), status = character(),
                      anchor_status = character(), check_status = character(),
                      by = character(), created = character(), supersedes = character(),
                      stringsAsFactors = FALSE)
    out$anchors <- list(); out$body <- list(); out$provenance <- list()
    out$depends_on <- list(); out$check <- list()
    return(out)
  }
  out <- do.call(rbind, lapply(recs, record_summary))
  out$anchors <- I(lapply(recs, `[[`, "anchors"))
  out$body <- I(lapply(recs, `[[`, "body"))
  out$provenance <- I(lapply(recs, `[[`, "provenance"))
  out$depends_on <- I(lapply(recs, function(r) as.character(r$depends_on %||% character())))
  out$check <- I(lapply(recs, `[[`, "check"))
  attr(out, "records") <- recs
  rownames(out) <- NULL
  out
}

materialize_layer <- function(log, name, plugin = NULL) {
  state <- layer_state(name, plugin = plugin, records = list(), log = log %||% list())
  records <- list()
  for (event in state$log) {
    if (is.list(event$record)) event$record <- normalize_record_storage(event$record)
    op <- event$op %||% event$event %||% "add"
    if (op %in% c("add", "revise")) {
      rec <- event$record %||% event
      if (is.null(rec$id)) next
      if (op == "revise" && !is.null(event$supersedes) &&
          !is.null(records[[event$supersedes]])) {
        records[[event$supersedes]]$status <- "superseded"
        records[[event$supersedes]]$superseded_by <- rec$id
      }
      records[[rec$id]] <- rec
    } else if (op == "retract") {
      id <- event$target_id %||% event$id
      if (!is.null(records[[id]])) records[[id]]$status <- "retracted"
    } else if (op %in% c("verify", "rebase")) {
      id <- event$target_id %||% event$id
      if (!is.null(records[[id]])) {
        if (!is.null(event$status)) records[[id]]$status <- event$status
        if (!is.null(event$check)) records[[id]]$check <- event$check
        if (!is.null(event$anchor_status)) records[[id]]$anchor_status <- event$anchor_status
        if (!is.null(event$resolution)) records[[id]]$resolution <- event$resolution
        if (!is.null(event$candidates)) records[[id]]$candidates <- event$candidates
      }
    } else if (op == "rewrite") {
      id <- event$target_id %||% event$id
      if (!is.null(records[[id]]) && !is.null(event$record)) records[[id]] <- event$record
    }
  }
  state$records <- unname(records)
  state
}

append_layer_event <- function(fig, layer, event) {
  if (!layer %in% names(fig$layers)) fig$layers[[layer]] <- layer_state(layer)
  state <- fig$layers[[layer]]
  state$log[[length(state$log) + 1L]] <- event
  fig$layers[[layer]] <- materialize_layer(state$log, layer, state$plugin)
  fig
}

record_event <- function(op, rec = NULL, target_id = NULL, ...) {
  extra <- list(...)
  event <- c(list(op = op, time = now_utc()), extra)
  if (!is.null(rec)) event$record <- rec
  if (!is.null(target_id)) event$target_id <- target_id
  event
}

record_check_spec <- function(body) {
  if (is.null(body$check)) return(NULL)
  check <- body$check
  if (inherits(check, "gloss_check")) return(check)
  if (!is.list(check) || is.null(check$kind)) return(NULL)
  check
}

run_record_check <- function(fig, rec) {
  spec <- record_check_spec(rec$body)
  if (is.null(spec)) return(NULL)
  if (inherits(spec, "gloss_check")) return(spec)
  table <- spec$table %||% rec$body$table
  if (is.null(table) || is.null(fig$tables[[table]]$data)) {
    return(list(kind = spec$kind, status = "refused", passed = NA,
                reason = sprintf("table '%s' is not available", table %||% ""),
                args = spec$args %||% list()))
  }
  gl_check(fig$tables[[table]]$data, spec$kind, spec$args %||% list())
}

record_fact_status <- function(check, proposed = "proposed", body = list()) {
  origin <- body$provenance %||% body$origin %||% NULL
  if (identical(origin, "speculative")) {
    if (is.null(check)) return("speculative")
    if (identical(check$status, "failed")) return("rejected")
    return("speculative")
  }
  if (is.null(check)) return(proposed)
  switch(check$status,
         verified = "verified",
         failed = "rejected",
         partial = "proposed",
         refused = "proposed",
         proposed)
}

validate_record_body <- function(layer, body) {
  p <- gl_plugin("layer", layer)
  problems <- gl_schema_validate(body, p$body %||% list(type = "any"))
  problems <- c(problems, payload_issues(body))
  if (length(problems)) cli::cli_abort(c(
    "Invalid body for layer {.val {layer}}.", bullets_x(problems)
  ))
  invisible(TRUE)
}

validate_record <- function(fig, rec, strict_anchor = TRUE) {
  validate_record_body(rec$layer, rec$body)
  resolutions <- lapply(rec$anchors, function(a) gl_resolve_anchor(fig, a))
  rec$anchor_status <- record_anchor_status(resolutions)
  rec$resolution <- resolutions
  if (strict_anchor && any(vapply(resolutions, `[[`, "", "status") != "unique")) {
    return(list(ok = FALSE, record = rec, resolutions = resolutions,
                reason = "one or more anchors are missing or ambiguous"))
  }
  rec$check <- run_record_check(fig, rec)
  rec$status <- record_fact_status(rec$check, rec$status %||% "proposed", rec$body)
  list(ok = TRUE, record = rec, resolutions = resolutions)
}

#' Append a semantic record to a named layer
#'
#' Records are validated before they enter the layer.  The body is checked
#' against the layer plugin, every anchor must resolve uniquely, and an
#' attached closed check is run against the stored built table.  Failed checks
#' are retained with status `rejected`; they can never become verified facts.
#'
#' @param fig A `gloss_figure`.
#' @param layer Layer plugin name.
#' @param anchor One anchor, or a list of anchors.
#' @param body A JSON-like record body.
#' @param by Provenance identity, or a named provenance list.
#' @param depends_on Record ids this record depends on.
#' @return The updated `gloss_figure`.
#' @export
gl_record <- function(fig, layer, anchor, body = list(), by = "user",
                      depends_on = character()) {
  check_figure(fig)
  if (!is_string(layer)) cli::cli_abort("{.arg layer} must be a single string.")
  if (is.null(gl_plugin("layer", layer, must_exist = FALSE))) {
    cli::cli_abort("No layer plugin named {.val {layer}} is registered.")
  }
  anchors <- normalize_anchors(anchor)
  prov <- record_provenance(by)
  rec <- list(
    id = new_record_id(fig, layer, anchors, body, prov),
    layer = layer, anchors = anchors, body = body,
    provenance = prov, created = prov$time,
    status = "proposed", depends_on = as.character(depends_on)
  )
  checked <- validate_record(fig, rec, strict_anchor = TRUE)
  if (!isTRUE(checked$ok)) {
    cli::cli_abort(c(
      "The record cannot be appended.",
      x = checked$reason,
      i = "Use gl_resolve_anchor() to inspect candidates before retrying."
    ))
  }
  append_layer_event(fig, layer, record_event("add", checked$record))
}

# A descriptive alias used internally and by extensions.
gl_add_record <- gl_record

#' Revise a record by appending a superseding record
#'
#' @param fig A `gloss_figure`.
#' @param id Existing record id.
#' @param body Replacement body.
#' @param anchor Replacement anchor; defaults to the old anchor.
#' @param by Provenance identity.
#' @return The updated figure.
#' @export
gl_revise <- function(fig, id, body, anchor = NULL, by = "user") {
  old <- record_by_id(fig, id)
  a <- anchor %||% old$anchors
  out <- gl_record(fig, old$layer, a, body, by = by,
                   depends_on = old$depends_on %||% character())
  # gl_record has already appended an add.  Replace its event with a revise
  # event in the log while retaining the exact append-only history.
  st <- out$layers[[old$layer]]
  ev <- st$log[[length(st$log)]]
  ev$op <- "revise"; ev$supersedes <- id
  st$log[[length(st$log)]] <- ev
  out$layers[[old$layer]] <- materialize_layer(st$log, old$layer, st$plugin)
  out
}

#' Retract a record by appending a retraction event
#'
#' @param fig A `gloss_figure`.
#' @param id Record id.
#' @param by Provenance identity.
#' @return The updated figure.
#' @export
gl_retract <- function(fig, id, by = "user") {
  rec <- record_by_id(fig, id)
  append_layer_event(fig, rec$layer,
                     record_event("retract", target_id = id,
                                  by = record_provenance(by)))
}

#' Query records in one or more layers
#'
#' @param fig A `gloss_figure`.
#' @param layer Optional layer name(s).
#' @param status Optional status filter.
#' @return A data frame with list columns for anchors, body, provenance and
#'   check.  The original records are available in the `records` attribute.
#' @export
gl_records <- function(fig, layer = NULL, status = NULL) {
  record_rows(fig, layer, status)
}

#' Re-run checks and anchor resolution for records
#'
#' @param fig A `gloss_figure`.
#' @param layers Optional layer names.
#' @return The updated figure.
#' @export
gl_verify <- function(fig, layers = NULL) {
  check_figure(fig)
  names0 <- names(fig$layers %||% list())
  names1 <- if (is.null(layers)) names0 else intersect(names0, as.character(layers))
  for (nm in names1) {
    for (rec in fig$layers[[nm]]$records %||% list()) {
      checked <- validate_record(fig, rec, strict_anchor = FALSE)
      r <- checked$record
      resolutions <- rebase_anchor_resolutions(fig, rec, checked$resolutions)
      st <- if (any(vapply(resolutions, `[[`, "", "status") != "unique")) "invalid" else r$status
      fig <- append_layer_event(fig, nm, record_event(
        "verify", target_id = rec$id, status = st,
        anchor_status = r$anchor_status, candidates = lapply(resolutions, `[[`, "candidates"),
        check = r$check
      ))
    }
  }
  fig
}

record_by_id <- function(fig, id) {
  rows <- record_rows(fig)
  recs <- attr(rows, "records")
  hit <- which(vapply(recs, function(r) identical(r$id, id), logical(1)))
  if (!length(hit)) cli::cli_abort("No active record {.val {id}}.")
  recs[[hit[1L]]]
}

#' List conflicting records
#'
#' Conflicts are intentionally reported rather than resolved by a fixed
#' precedence rule.  A conflict is a pair of live records with the same
#' canonical anchor and different bodies.
#'
#' @param fig A `gloss_figure`.
#' @return A data frame with one row per conflicting target.
#' @export
gl_conflicts <- function(fig) {
  rows <- record_rows(fig)
  recs <- attr(rows, "records")
  if (length(recs) < 2L) {
    return(data.frame(target = character(), records = I(list()), n = integer(),
                      stringsAsFactors = FALSE))
  }
  key <- vapply(recs, function(r) record_digest(r$anchors), "")
  groups <- split(seq_along(recs), key)
  out <- list()
  for (idx in groups) {
    if (length(idx) < 2L) next
    bodies <- unique(vapply(recs[idx], function(r) record_digest(r$body), ""))
    if (length(bodies) < 2L) next
    out[[length(out) + 1L]] <- data.frame(
      target = key[idx[1L]], records = I(list(vapply(recs[idx], `[[`, "", "id"))),
      n = length(idx), stringsAsFactors = FALSE
    )
  }
  if (!length(out)) return(data.frame(target = character(), records = I(list()), n = integer(), stringsAsFactors = FALSE))
  do.call(rbind, out)
}

#' Append a conflict-resolution record
#'
#' @param fig A `gloss_figure`.
#' @param conflict A row from [gl_conflicts()] or a vector of record ids.
#' @param keep Record id(s) retained by the judgment.
#' @param rationale Explanation for the judgment.
#' @param by Provenance identity.
#' @param evidence Optional JSON-like evidence attached to the resolution.
#' @return The updated figure.
#' @export
gl_resolve <- function(fig, conflict, keep, rationale, by = "user", evidence = NULL) {
  ids <- if (is.data.frame(conflict)) unlist(conflict$records[[1L]]) else as.character(conflict)
  layer <- record_by_id(fig, ids[1L])$layer
  anchor <- record_by_id(fig, ids[1L])$anchors
  body <- list(type = "resolution", keep = as.character(keep),
               rationale = as.character(rationale)[1L])
  if (!is.null(evidence)) body$evidence <- evidence
  gl_record(fig, layer, anchor, body, by = by, depends_on = ids)
}

#' Summarise record and anchor state
#'
#' @param fig A `gloss_figure`.
#' @return A data frame with one row per current record.
#' @export
gl_status <- function(fig) {
  rows <- gl_records(fig)
  if (!nrow(rows)) return(rows[, c("id", "layer", "status", "anchor_status", "check_status")])
  rows[, c("id", "layer", "status", "anchor_status", "check_status", "by", "created"), drop = FALSE]
}

rewrite_key_selectors <- function(fig, table, old_key, new_key, by = "user") {
  for (nm in names(fig$layers %||% list())) {
    st <- fig$layers[[nm]]
    for (rec in st$records %||% list()) {
      changed <- FALSE
      anchors <- rec$anchors
      for (j in seq_along(anchors)) {
        sels <- anchors[[j]]$selectors
        for (k in seq_along(sels)) {
          s <- sels[[k]]
          if (identical(s$type, "data_key") && identical(as.character(s$table), table)) {
            if (!is.null(s$key_names)) {
              s$key_names <- as.character(new_key)
              changed <- TRUE
            }
            sels[[k]] <- s
          }
        }
        anchors[[j]]$selectors <- sels
      }
      if (changed) {
        rec$anchors <- anchors
        rec$provenance <- record_provenance(by, list(reason = "row key changed"))
        fig <- append_layer_event(fig, nm, record_event("rewrite", target_id = rec$id,
                                                        record = rec))
      }
    }
  }
  fig
}

#' List records that need repair after a substrate change
#'
#' @param fig A `gloss_figure`.
#' @param by Reserved for a future repair agent; it is recorded in the result.
#' @return A data frame of invalid records.
#' @export
gl_repair <- function(fig, by = "agent") {
  out <- gl_records(fig, status = "invalid")
  attr(out, "repair_by") <- by
  out
}
