# Stage run state and checked semantic candidates. Tool calls accumulate
# candidates in an isolated environment. Only stage_commit() appends records.

agent_stage_state <- function(fig, stage, disclose = NULL, metadata = list()) {
  check_figure(fig)
  plugin <- stage_plugin_info(stage)
  state <- new.env(parent = emptyenv())
  state$stage <- plugin$name
  state$plugin <- plugin
  state$disclose <- disclose %||% plugin$disclose
  state$metadata <- metadata
  state$calls <- list()
  state$proposals <- list()
  state$candidates <- list()
  state$review_conflicts <- tryCatch(gl_conflicts(fig), error = function(e) NULL)
  state$repair_records <- tryCatch(gl_repair(fig), error = function(e) NULL)
  state
}

agent_stage_provenance <- function(state, by = NULL) {
  meta <- state$metadata %||% list()
  identity <- by %||% meta$by %||% paste0("agent:", state$stage)
  extra <- compact(list(
    stage = state$stage,
    model = meta$model %||% NULL,
    prompt_version = meta$prompt_version %||% state$plugin$prompt_version,
    disclose = state$disclose,
    run_id = meta$run_id %||% NULL,
    cache = meta$cache %||% NULL
  ))
  record_provenance(identity, extra)
}

agent_proposal_schema <- function() {
  list(
    layer = "string",
    anchor = "any",
    body = "any",
    "depends_on?" = list(type = "array", items = "string")
  )
}

agent_candidate_result <- function(outcome, stage, reasons = character(), record = NULL,
                                   kind = "record", payload = NULL) {
  list(outcome = outcome, stage = stage, reasons = substr(as.character(reasons), 1L, 400L),
       record = record, kind = kind, payload = payload)
}

agent_validate_record_proposal <- function(fig, state, proposal) {
  problems <- gl_schema_validate(proposal, agent_proposal_schema())
  if (length(problems)) return(agent_candidate_result("rejected", "schema", problems))
  layer <- as.character(proposal$layer)[1L]
  if (!layer %in% state$plugin$writes) {
    return(agent_candidate_result("rejected", "capability",
                                  sprintf("stage '%s' cannot write layer '%s'", state$stage, layer)))
  }
  if (is.null(gl_plugin("layer", layer, must_exist = FALSE))) {
    return(agent_candidate_result("rejected", "schema", sprintf("unknown record layer '%s'", layer)))
  }
  anchors <- tryCatch(normalize_anchors(proposal$anchor), error = function(e) e)
  if (inherits(anchors, "error")) {
    return(agent_candidate_result("rejected", "schema", conditionMessage(anchors)))
  }
  body <- proposal$body %||% list()
  prov <- agent_stage_provenance(state, proposal$by %||% NULL)
  rec <- list(
    id = new_record_id(fig, layer, anchors, body, prov), layer = layer,
    anchors = anchors, body = body, provenance = prov, created = prov$time,
    status = "proposed", depends_on = as.character(proposal$depends_on %||% character())
  )
  checked <- tryCatch(validate_record(fig, rec, strict_anchor = TRUE), error = function(e) e)
  if (inherits(checked, "error")) {
    return(agent_candidate_result("rejected", "schema", conditionMessage(checked)))
  }
  if (!isTRUE(checked$ok)) {
    return(agent_candidate_result("rejected", "anchor", checked$reason, record = checked$record))
  }
  rec <- checked$record
  if (identical(rec$status, "rejected")) {
    reason <- rec$check$reason %||% rec$check$status %||% "the attached check failed"
    return(agent_candidate_result("rejected", "check", reason, record = rec))
  }
  agent_candidate_result("accepted", "validated", record = rec)
}

agent_store_candidate <- function(state, result) {
  state$candidates[[length(state$candidates) + 1L]] <- result
  result
}

agent_conflict_ids <- function(conflicts) {
  if (is.null(conflicts) || !nrow(conflicts)) return(list())
  lapply(conflicts$records, as.character)
}

agent_validate_resolution <- function(fig, state, conflict, keep, rationale, evidence = NULL) {
  ids <- as.character(unlist(conflict, use.names = FALSE))
  keep <- as.character(unlist(keep, use.names = FALSE))
  if (!length(ids) || !length(keep) || !is_string(rationale) || !nzchar(trimws(rationale))) {
    return(agent_candidate_result("rejected", "schema", "a resolution needs conflict ids, kept ids and a rationale"))
  }
  groups <- agent_conflict_ids(state$review_conflicts)
  valid <- any(vapply(groups, function(group) setequal(ids, group), logical(1)))
  if (!valid) return(agent_candidate_result("rejected", "capability", "the conflict is outside this review stage"))
  if (!all(keep %in% ids)) return(agent_candidate_result("rejected", "schema", "kept ids must be in the supplied conflict"))
  if (!all(vapply(keep, function(id) {
    tryCatch({ record_by_id(fig, id); TRUE }, error = function(e) FALSE)
  }, logical(1)))) {
    return(agent_candidate_result("rejected", "exists", "a kept record is no longer present"))
  }
  payload <- list(conflict = ids, keep = keep, rationale = rationale, evidence = evidence)
  agent_candidate_result("accepted", "validated", kind = "resolve", payload = payload)
}

agent_validate_repair <- function(fig, state, target_id, action, anchor = NULL, body = NULL) {
  target_id <- as.character(target_id)[1L]
  action <- as.character(action)[1L]
  rows <- state$repair_records
  if (is.null(rows) || !nrow(rows) || !target_id %in% rows$id) {
    return(agent_candidate_result("rejected", "capability", "the record is outside this repair stage"))
  }
  rec <- tryCatch(record_by_id(fig, target_id), error = function(e) NULL)
  if (is.null(rec) || !identical(rec$status, "invalid")) {
    return(agent_candidate_result("rejected", "exists", "the record is not currently invalid"))
  }
  if (action == "retract") {
    return(agent_candidate_result("accepted", "validated", kind = "repair",
                                  payload = list(target_id = target_id, action = action)))
  }
  if (action != "revise" || is.null(anchor) || is.null(body)) {
    return(agent_candidate_result("rejected", "schema", "a repair must revise with an explicit anchor and body"))
  }
  anchors <- tryCatch(normalize_anchors(anchor), error = function(e) e)
  if (inherits(anchors, "error")) {
    return(agent_candidate_result("rejected", "schema", conditionMessage(anchors)))
  }
  test <- tryCatch(lapply(anchors, function(a) gl_resolve_anchor(fig, a)), error = function(e) e)
  if (inherits(test, "error") || any(vapply(test, `[[`, "", "status") != "unique")) {
    return(agent_candidate_result("rejected", "anchor", "the repair anchor is missing or ambiguous"))
  }
  agent_candidate_result("accepted", "validated", kind = "repair",
                         payload = list(target_id = target_id, action = action,
                                        anchor = anchors, body = body, layer = rec$layer))
}

stage_commit <- function(fig, state) {
  check_figure(fig)
  out <- fig
  committed <- list()
  rejected <- list()
  for (candidate in state$candidates %||% list()) {
    if (!identical(candidate$outcome, "accepted")) {
      rejected[[length(rejected) + 1L]] <- candidate
      next
    }
    result <- tryCatch({
      if (identical(candidate$kind, "record")) {
        rec <- candidate$record
        out <- gl_record(out, rec$layer, rec$anchors, rec$body,
                         by = rec$provenance, depends_on = rec$depends_on)
      } else if (identical(candidate$kind, "resolve")) {
        p <- candidate$payload
        out <- gl_resolve(out, p$conflict, p$keep, p$rationale,
                          by = agent_stage_provenance(state), evidence = p$evidence)
      } else if (identical(candidate$kind, "repair")) {
        p <- candidate$payload
        if (identical(p$action, "retract")) {
          out <- gl_retract(out, p$target_id, by = agent_stage_provenance(state))
        } else {
          out <- gl_revise(out, p$target_id, p$body, p$anchor,
                           by = agent_stage_provenance(state))
        }
      }
      TRUE
    }, error = function(e) e)
    if (inherits(result, "error")) {
      failed <- candidate
      failed$outcome <- "rejected"
      failed$stage <- "commit"
      failed$reasons <- substr(conditionMessage(result), 1L, 400L)
      rejected[[length(rejected) + 1L]] <- failed
    } else {
      committed[[length(committed) + 1L]] <- candidate
    }
  }
  if (length(committed)) {
    layers <- intersect(state$plugin$writes, names(out$layers))
    if (length(layers)) out <- gl_verify(out, layers = layers)
  }
  list(fig = out, committed = committed, rejected = rejected,
       candidates = state$candidates %||% list(),
       proposals = state$proposals %||% list(), calls = state$calls %||% list(),
       stage = state$stage, metadata = state$metadata)
}
