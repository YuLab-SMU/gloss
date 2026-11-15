# Consistency checks for role classifications. Checks return evidence; a
# failed check flags the derived role but does not rewrite it.

role_checks <- function(fig, roles) {
  el <- roles$elements
  if (!nrow(el)) return(data.frame(check = character(), element = character(), leaf = character(),
                                   passed = logical(), evidence = character(), stringsAsFactors = FALSE))
  tags <- fig$substrate$elements$tag[match(el$element, fig$substrate$elements$id)]
  rows <- new.env(parent = emptyenv())
  rows$values <- list()
  add <- function(check, idx, passed, evidence) {
    if (!length(idx)) return()
    rows$values[[length(rows$values) + 1L]] <- data.frame(
      check = rep(check, length(idx)), element = el$element[idx], leaf = el$leaf[idx],
      passed = rep(as.logical(passed), length.out = length(idx)),
      evidence = rep(evidence, length(idx)), stringsAsFactors = FALSE
    )
  }
  text_roles <- el$kind %in% c("text", "tick label", "axis title", "legend label", "legend title", "strip label", "title")
  add("text roles are text elements", which(text_roles), !is.na(tags[ text_roles ]) & tags[text_roles] == "text",
      "role kind requires an SVG text element")
  failed <- logical(nrow(el))
  b <- fig$derived$bindings$tables$elements
  if (!is.null(b) && nrow(b)) failed <- b$status[match(el$element, b$element)] %in% "failed"
  add("data leaves do not have failed bindings", which(el$role == "data"), !failed[el$role == "data"],
      "a failed binding is a geometry contradiction")
  nondata <- el$role %in% c("guide", "reference", "decoration", "annotation")
  bound <- if (is.null(b) || !nrow(b)) rep(FALSE, nrow(el)) else b$status[match(el$element, b$element)] %in% c("verified", "ambiguous")
  add("non-data roles do not bind to rows", which(nondata), !bound[nondata],
      "guide, reference, decoration and annotation leaves must not claim layer rows")
  data.frame(
    check = unlist(lapply(rows$values, `[[`, "check"), use.names = FALSE),
    element = unlist(lapply(rows$values, `[[`, "element"), use.names = FALSE),
    leaf = unlist(lapply(rows$values, `[[`, "leaf"), use.names = FALSE),
    passed = unlist(lapply(rows$values, `[[`, "passed"), use.names = FALSE),
    evidence = unlist(lapply(rows$values, `[[`, "evidence"), use.names = FALSE),
    stringsAsFactors = FALSE
  )
}

#' Consistency checks for role classification
#'
#' @param fig A `gloss_figure`.
#' @return A data frame with one row per check and element.
#' @export
gl_role_checks <- function(fig) {
  check_figure(fig)
  d <- fig$derived$roles
  if (is.null(d$tables$checks)) return(role_checks(fig, list(elements = d$tables$elements)))
  d$tables$checks
}
