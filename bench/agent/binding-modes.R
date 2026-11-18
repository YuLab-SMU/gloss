# Four comparison arms for the bench prototype.  `binding_mode` is deliberately
# an internal bench argument.  It is not a gloss public parameter.

source("bench/agent/binding-dsl.R")
source("bench/agent/binding-material.R")
source("bench/agent/binding-checker.R")

binding_load_material <- function(dir) {
  facts <- binding_read_public(dir)
  oracle <- binding_open_oracle(dir)
  list(dir = normalizePath(dir), facts = facts, oracle = oracle)
}

binding_legacy_arm <- function(material) {
  legacy <- material$oracle$legacy
  if (is.null(legacy$elements) || is.null(legacy$leaves)) {
    return(list(status = "operational_failure", reason = "legacy oracle is incomplete", rows = data.frame()))
  }
  rows <- legacy$elements
  rows$arm <- rep("legacy", nrow(rows))
  rows$outcome <- ifelse(rows$status %in% c("verified", "ambiguous"), rows$status, "rejected")
  list(status = "measured", rows = rows,
       digest = digest::digest(legacy),
       accepted = sum(rows$outcome == "verified"), ambiguous = sum(rows$outcome == "ambiguous"),
       rejected = sum(rows$outcome == "rejected"))
}

binding_contract_arm <- function(material) {
  contract <- material$oracle$contract
  if (is.null(contract) || !identical(contract$status, "measured")) {
    source_figure <- material$oracle$source_figure
    if (is.null(source_figure)) {
      return(list(status = "refused", reason = contract$reason %||% "contract replay was unavailable", rows = data.frame()))
    }
    contract <- binding_contract_result(source_figure)
    if (!identical(contract$status, "measured")) {
      return(list(status = "refused", reason = contract$reason %||% "contract replay was unavailable", rows = data.frame()))
    }
  }
  rows <- contract$elements
  rows$arm <- rep("contract", nrow(rows))
  rows$outcome <- ifelse(rows$alone %in% "verified", "accepted",
                         ifelse(rows$alone %in% "ambiguous", "ambiguous", "rejected"))
  list(status = "measured", rows = rows,
       accepted = sum(rows$outcome == "accepted"), ambiguous = sum(rows$outcome == "ambiguous"),
       rejected = sum(rows$outcome == "rejected"))
}

binding_proposal_key <- function(p) {
  jsonlite::toJSON(p, auto_unbox = TRUE, null = "null", digits = NA)
}

binding_unique_accepts <- function(results) {
  acc <- Filter(function(x) identical(x$outcome, "accepted"), results)
  if (!length(acc)) return(list(status = "none", results = acc))
  binding_result_key <- function(x) {
    list(leaf = x$proposal$leaf %||% NA_character_, table = x$proposal$table %||% NA_character_,
         rows = x$selected_rows %||% x$proposal$rows)
  }
  key <- vapply(acc, function(x) binding_proposal_key(binding_result_key(x)), "")
  if (length(unique(key)) != 1L) return(list(status = "ambiguous", results = acc))
  list(status = "accepted", results = acc)
}

binding_enumeration_arm <- function(material, max_candidates = 2000L) {
  proposals <- binding_enumerate(material$facts, max_candidates = max_candidates)
  if (!length(proposals)) return(list(status = "refused", reason = "no finite candidates", traces = list(), rows = data.frame()))
  traces <- lapply(seq_along(proposals), function(i) {
    result <- tryCatch(binding_checker(material$dir, proposals[[i]]), error = function(e) {
      list(outcome = "operational_failure", reports = binding_reason_row("checker", FALSE, conditionMessage(e)), proposal = proposals[[i]])
    })
    result$index <- i
    result
  })
  selected <- binding_unique_accepts(traces)
  rows <- do.call(rbind, lapply(traces, function(r) {
    data.frame(index = r$index %||% NA_integer_, leaf = r$proposal$leaf %||% NA_character_,
               table = r$proposal$table %||% NA_character_, outcome = r$outcome,
               report = paste(unique(r$reports$category), collapse = "+"),
               reason = paste(unique(r$reports$reason), collapse = " | "),
               mutation = r$mutation$status %||% NA_character_, stringsAsFactors = FALSE)
  }))
  list(status = selected$status, traces = traces, rows = rows,
       candidates = length(proposals), accepted = sum(rows$outcome == "accepted"),
       ambiguous = sum(rows$outcome == "ambiguous"), rejected = sum(rows$outcome == "rejected"),
       refused = sum(rows$outcome %in% c("refused", "none")), operational_failure = sum(rows$outcome == "operational_failure"))
}

binding_trace_record <- function(material, arm, result, model = NA_character_, code = NA_character_,
                                 calls = NA_integer_, seconds = NA_real_, failure = NA_character_) {
  p <- result$proposal %||% list()
  list(
    material_version = material$facts$version %||% binding_material_version,
    material = basename(material$dir), arm = arm, model = model,
    proposal = p, proposal_sha256 = digest::digest(p, algo = "sha256"),
    code_sha256 = if (is.na(code)[1L]) NA_character_ else digest::digest(code, algo = "sha256", serialize = FALSE),
    output = result$output %||% NA_character_, outcome = result$outcome %||% "operational_failure",
    reports = result$reports %||% data.frame(), mutation = result$mutation %||% list(),
    calls = calls, seconds = seconds,
    failure = failure %||% NA_character_
  )
}

binding_arm <- function(material, binding_mode = c("legacy", "contract", "enumeration", "agent"), ...) {
  binding_mode <- match.arg(binding_mode)
  switch(binding_mode,
         legacy = binding_legacy_arm(material),
         contract = binding_contract_arm(material),
         enumeration = binding_enumeration_arm(material, ...),
         agent = stop("agent arm is provided by binding-agent.R"))
}
