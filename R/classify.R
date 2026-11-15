# Role classification: deterministic engine rules over the captured substrate.
#
# Rules are derived facts. They are recomputed at capture and kept beside the
# substrate as a derived table; a person or agent can add a correction later as
# a record without changing this table.

role_claim <- function(role, kind, cue, rule, elements = NULL, reason = NA_character_) {
  list(role = role, kind = kind, cue = cue, rule = rule,
       elements = elements, reason = reason)
}

leaf_value <- function(leaf, name, default = NA_character_) {
  if (is.null(leaf[[name]]) || !length(leaf[[name]])) return(default)
  leaf[[name]][1]
}

rule_element_indices <- function(claim, elements) {
  if (is.null(claim$elements)) return(seq_len(nrow(elements)))
  x <- as.integer(claim$elements)
  if (!length(x) || anyNA(x) || any(!x %in% elements$ordinal)) return(integer())
  match(x, elements$ordinal)
}

rule_plugin <- function(engine) gl_plugin("rules", engine, must_exist = FALSE)

rules_input <- function(fig, state) {
  code <- fig$context$code$value %||% list()
  list(fig = fig, state = state, code = code)
}

run_role_rules <- function(fig, engine, state = NULL) {
  sub <- fig$substrate
  plugin <- rule_plugin(engine$name %||% fig$meta$engine)
  rows <- list()
  leaves <- list()
  for (i in seq_len(nrow(sub$leaves))) {
    lf <- sub$leaves[i, , drop = FALSE]
    id <- lf$id[1]
    els <- sub$elements[sub$elements$leaf %in% id, , drop = FALSE]
    if (!nrow(els)) next
    claims <- list()
    errors <- new.env(parent = emptyenv())
    errors$values <- character()
    if (!is.null(plugin)) {
      for (nm in names(plugin$rules)) {
        out <- tryCatch(plugin$rules[[nm]](lf, els, rules_input(fig, state)),
                        error = function(e) {
                          errors$values <- c(errors$values, sprintf("rule %s failed: %s", nm, conditionMessage(e)))
                          NULL
                        })
        if (is.null(out)) next
        if (!is.list(out) || (!is.null(out$role) && !is.null(out$kind))) out <- list(out)
        claims <- c(claims, out)
        # The first matching plugin rule owns the leaf; a rule may split it
        # explicitly, but a later rule must not overlap its elements.
        break
      }
    }
    assigned <- rep(FALSE, nrow(els))
    erows <- list()
    conflict <- character()
    if (length(claims)) {
      for (cl in claims) {
        if (!is.list(cl) || is.null(cl$role) || is.null(cl$kind)) {
          conflict <- c(conflict, "rule returned no role and kind")
          next
        }
        at <- rule_element_indices(cl, els)
        if (!length(at)) {
          conflict <- c(conflict, sprintf("rule %s returned an invalid element range", cl$rule %||% "unknown"))
          next
        }
        if (any(assigned[at])) {
          conflict <- c(conflict, sprintf("rule %s overlaps another rule result", cl$rule %||% "unknown"))
          next
        }
        assigned[at] <- TRUE
        erows[[length(erows) + 1L]] <- data.frame(
          element = els$id[at], leaf = rep(id, length(at)), ordinal = els$ordinal[at],
          role = rep(as.character(cl$role), length(at)), kind = rep(as.character(cl$kind), length(at)),
          cue = rep(as.character(cl$cue %||% NA_character_), length(at)),
          rule = rep(as.character(cl$rule %||% plugin$name), length(at)),
          status = rep("classified", length(at)),
          reason = rep(as.character(cl$reason %||% NA_character_), length(at)),
          flagged = rep(FALSE, length(at)), flags = rep(NA_character_, length(at)),
          stringsAsFactors = FALSE
        )
      }
    }
    if (length(conflict)) {
      # A conflicting result is residue for the whole leaf. Keeping the reason
      # is safer than choosing one rule silently.
      erows <- list(data.frame(
        element = els$id, leaf = rep(id, nrow(els)), ordinal = els$ordinal,
        role = NA_character_, kind = NA_character_, cue = NA_character_,
        rule = NA_character_, status = "residue",
        reason = paste(conflict, collapse = "; "), flagged = TRUE,
        flags = paste(conflict, collapse = "; "), stringsAsFactors = FALSE
      ))
      assigned[] <- TRUE
    }
    if (!all(assigned)) {
      miss <- which(!assigned)
          why <- if (length(errors$values)) paste(errors$values, collapse = "; ") else
        if (is.null(plugin)) sprintf("no rules plugin registered for engine '%s'", engine$name) else
        "no rule matched the leaf"
      erows[[length(erows) + 1L]] <- data.frame(
        element = els$id[miss], leaf = rep(id, length(miss)), ordinal = els$ordinal[miss],
        role = NA_character_, kind = NA_character_, cue = NA_character_,
        rule = NA_character_, status = "residue", reason = why,
        flagged = TRUE, flags = why, stringsAsFactors = FALSE
      )
    }
    e <- do.call(rbind, erows)
    e <- e[order(e$ordinal), , drop = FALSE]
    rows[[length(rows) + 1L]] <- e
    roles <- unique(e$role[!is.na(e$role)])
    kinds <- unique(e$kind[!is.na(e$kind)])
    bad <- any(e$status != "classified")
    leaves[[length(leaves) + 1L]] <- data.frame(
      leaf = id, n_elements = nrow(e),
      role = if (length(roles) == 1L && !bad) roles else if (length(roles) > 1L) "split" else NA_character_,
      kind = if (length(kinds) == 1L && !bad) kinds else if (length(kinds) > 1L) "split" else NA_character_,
      status = if (bad) "residue" else "classified",
      rule = if (all(!is.na(e$rule))) paste(unique(e$rule), collapse = ";") else NA_character_,
      cue = if (all(!is.na(e$cue))) paste(unique(e$cue), collapse = ";") else NA_character_,
      reason = if (any(bad)) paste(unique(e$reason[e$status != "classified"]), collapse = "; ") else NA_character_,
      split = length(roles) > 1L, stringsAsFactors = FALSE
    )
  }
  el <- if (length(rows)) do.call(rbind, rows) else role_element_empty()
  lv <- if (length(leaves)) do.call(rbind, leaves) else role_leaf_empty()
  rownames(el) <- NULL; rownames(lv) <- NULL
  list(elements = el, leaves = lv, plugin = plugin)
}

role_element_empty <- function() data.frame(
  element = character(), leaf = character(), ordinal = integer(), role = character(), kind = character(),
  cue = character(), rule = character(), status = character(), reason = character(), flagged = logical(),
  flags = character(), stringsAsFactors = FALSE
)

role_leaf_empty <- function() data.frame(
  leaf = character(), n_elements = integer(), role = character(), kind = character(), status = character(),
  rule = character(), cue = character(), reason = character(), split = logical(), stringsAsFactors = FALSE
)

role_binding_status <- function(fig, leaf) {
  b <- fig$derived$bindings$tables$leaves
  if (is.null(b) || !nrow(b)) return(NA_character_)
  b$status[match(leaf, b$leaf)] %||% NA_character_
}

apply_role_checks <- function(fig, roles) {
  el <- roles$elements
  if (!nrow(el)) return(roles)
  tags <- fig$substrate$elements$tag[match(el$element, fig$substrate$elements$id)]
  text_kind <- el$kind %in% c("text", "tick label", "axis title", "legend label", "legend title", "strip label", "title")
  bad_text <- text_kind & !is.na(tags) & tags != "text"
  for (i in which(bad_text)) {
    el$flagged[i] <- TRUE
    el$flags[i] <- paste(unique(c(el$flags[i], "text role is drawn by a non-text element")), collapse = "; ")
  }
  # A failed pairing is a hard geometry error. An unbound or count-mismatch
  # reason is reported by bindings and does not silently turn a role into an
  # error: the rule has named what it knows and the engine has named its limit.
  for (i in seq_len(nrow(el))) {
    if (!identical(el$role[i], "data")) next
    st <- role_binding_status(fig, el$leaf[i])
    if (identical(st, "failed")) {
      el$flagged[i] <- TRUE
      el$flags[i] <- paste(unique(c(el$flags[i], "data leaf has a failed binding")), collapse = "; ")
    }
  }
  roles$elements <- el
  roles$leaves$flagged <- vapply(roles$leaves$leaf, function(id) any(el$flagged[el$leaf == id]), logical(1))
  roles$leaves$flags <- vapply(roles$leaves$leaf, function(id) paste(unique(el$flags[el$leaf == id][!is.na(el$flags[el$leaf == id])]), collapse = "; "), "")
  roles$leaves$flags[!nzchar(roles$leaves$flags)] <- NA_character_
  roles
}

derive_roles <- function(fig, eng, state = NULL) {
  r <- run_role_rules(fig, eng, state)
  r <- apply_role_checks(fig, r)
  r$checks <- role_checks(fig, r)
  by <- r$plugin %||% list(kind = "rules", name = eng$name, version = NA_character_)
  new_derived("roles", by = by, params = list(), tables = r[c("elements", "leaves", "checks")])
}

#' Role classification of a figure
#'
#' @param fig A `gloss_figure`.
#' @param by Return one row per `"element"` or one row per `"leaf"`.
#' @param where Optional named filters applied to the returned table.
#' @return A data frame with deterministic roles, kinds, cues and residue reasons.
#' @export
gl_classify <- function(fig, by = c("element", "leaf"), where = NULL) {
  check_figure(fig)
  by <- match.arg(by)
  d <- fig$derived$roles
  if (is.null(d)) cli::cli_abort("This figure has no role classification.")
  table_name <- if (identical(by, "element")) "elements" else "leaves"
  out <- d$tables[[table_name]]
  if (!is.null(where)) {
    for (nm in names(where)) {
      if (!nm %in% names(out)) cli::cli_abort("Unknown role field {.val {nm}}.")
      out <- out[out[[nm]] %in% where[[nm]], , drop = FALSE]
    }
  }
  rownames(out) <- NULL
  out
}

#' Role of an element
#'
#' @param fig A `gloss_figure`.
#' @param element Optional element id. Without it, returns all element roles.
#' @return A role classification row or a data frame.
#' @export
gl_role <- function(fig, element = NULL) {
  out <- gl_classify(fig, "element")
  if (is.null(element)) return(out)
  hit <- out[out$element %in% element, , drop = FALSE]
  if (!nrow(hit)) cli::cli_abort("No classified element {.val {element}}.")
  hit
}

#' Residue from role classification
#'
#' @param fig A `gloss_figure`.
#' @return Elements for which no deterministic role was assigned, with reasons.
#' @export
gl_unclassified <- function(fig) {
  out <- gl_classify(fig, "element")
  out[out$status == "residue" | is.na(out$role), , drop = FALSE]
}
