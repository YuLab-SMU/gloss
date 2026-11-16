# Anchors resolve records to substrate elements without evaluating arbitrary
# code.  Selectors are deliberately structured JSON-like values so a bundle
# can be inspected and safely restored in another R session.

anchor_selector_types <- c("data_key", "data_predicate", "structure_path",
                           "role", "region", "element_id")

stable_element_id <- function(fig, i) {
  el <- fig$substrate$elements
  leaf <- el$leaf[i]
  lv <- fig$substrate$leaves[match(leaf, fig$substrate$leaves$id), , drop = FALSE]
  # This id deliberately depends only on the captured structure.  It remains
  # identical for a bound and an unbound capture of the same page; a separate
  # data target below detects a row silently changing underneath an id anchor.
  basis <- c("leaf", leaf, "tag", el$tag[i], "ordinal", el$ordinal[i])
  paste0("e", substr(digest::digest(paste(basis, collapse = "\u001f"),
                                    algo = "xxhash64", serialize = FALSE), 1L, 16L))
}

data_element_id <- function(fig, i) {
  el <- fig$substrate$elements
  basis <- el$stable_id[i] %||% el$id[i]
  b <- fig$derived$bindings$tables$elements %||% data.frame()
  if (nrow(b) && "element" %in% names(b)) {
    hit <- which(b$element == el$id[i] & b$status %in% c("verified", "ambiguous"))
    if (length(hit)) {
      hit <- hit[1L]
      tab <- fig$tables[[as.character(b$table[hit])]]
      row <- as.integer(b$row[hit])
      if (!is.null(tab) && !is.null(tab$data) && length(tab$key) && row >= 1L && row <= nrow(tab$data)) {
        vals <- vapply(tab$key, function(nm) paste(as.character(tab$data[[nm]][row]), collapse = ""), "")
        basis <- c(basis, "table", as.character(b$table[hit]), paste(tab$key, vals, sep = "=", collapse = "|"))
      }
    }
  }
  if (length(basis) == 1L) return(as.character(basis))
  paste0("e", substr(digest::digest(paste(basis, collapse = "\u001f"),
                                    algo = "xxhash64", serialize = FALSE), 1L, 16L))
}

ensure_stable_ids <- function(fig) {
  el <- fig$substrate$elements
  if (!nrow(el)) {
    el$stable_id <- character()
    fig$substrate$elements <- el
    return(fig)
  }
  el$stable_id <- vapply(seq_len(nrow(el)), function(i) stable_element_id(fig, i), "")
  fig$substrate$elements <- el
  fig
}

selector_type <- function(s) {
  t <- s$type %||% s$kind %||% names(s)[1L]
  aliases <- c(element = "element_id", id = "element_id", data = "data_key",
               predicate = "data_predicate", path = "structure_path",
               data_space = "region")
  t <- if (t %in% names(aliases)) aliases[[t]] else t
  if (!t %in% anchor_selector_types) {
    cli::cli_abort("Unknown anchor selector type {.val {t}}.")
  }
  t
}

normalize_selector <- function(s) {
  if (is.character(s) && length(s) == 1L) {
    return(list(type = "element_id", id = s))
  }
  if (!is.list(s) || (!length(s) && is.null(names(s)))) {
    cli::cli_abort("An anchor selector must be a named list or element id.")
  }
  t <- selector_type(s)
  s$type <- t
  s$kind <- NULL
  if (t == "element_id") s$id <- s$id %||% s$element %||% s$value
  if (t == "data_key") {
    s$table <- s$table %||% s$from
    s$key <- s$key %||% s$values %||% s$row_key
    if (is.null(s$key) && !is.null(s$row)) s$key <- list(.row = s$row)
  }
  if (t == "structure_path") {
    s$leaf <- s$leaf %||% s$leaf_id
    s$element <- s$element %||% s$id
  }
  if (t == "role") s$role <- s$role %||% s$name
  s
}

normalize_anchor <- function(anchor) {
  if (is.character(anchor) && length(anchor) == 1L) {
    return(list(selectors = list(normalize_selector(anchor))))
  }
  if (!is.list(anchor)) cli::cli_abort("An anchor must be a named list.")
  if (!is.null(anchor$selectors)) {
    sels <- anchor$selectors
    if (!is.list(sels)) sels <- as.list(sels)
    return(list(selectors = lapply(sels, normalize_selector)))
  }
  if (!is.null(anchor$selector)) {
    return(list(selectors = list(normalize_selector(anchor$selector))))
  }
  # A selector itself is accepted as an anchor for a concise API.
  list(selectors = list(normalize_selector(anchor)))
}

normalize_anchors <- function(anchor) {
  if (is.null(anchor)) cli::cli_abort("A record needs at least one anchor.")
  # A list with selectors/type is one anchor.  Otherwise a list of anchors is
  # accepted; this keeps `anchor = list(a1, a2)` unambiguous.
  one <- is.list(anchor) && (!is.null(anchor$type) || !is.null(anchor$kind) ||
                             !is.null(anchor$selector) || !is.null(anchor$selectors))
  if (one || is.character(anchor)) return(list(normalize_anchor(anchor)))
  if (is.list(anchor) && length(anchor) && all(vapply(anchor, function(x) {
    is.character(x) || (is.list(x) && ("selectors" %in% names(x) || "type" %in% names(x)))
  }, logical(1)))) return(lapply(anchor, normalize_anchor))
  list(normalize_anchor(anchor))
}

#' Construct a structured anchor
#'
#' @param selectors A selector or list of selectors.  A character value is an
#'   element id.
#' @param ... A concise selector, for example `element = "e1"` or
#'   `data_key = list(table = "built_layer1", key = list(id = "A"))`.
#' @return A normalized anchor.
#' @export
gl_anchor <- function(selectors = NULL, ...) {
  dots <- list(...)
  if (!is.null(selectors) && length(dots)) dots <- c(list(selectors = selectors), dots)
  if (length(dots)) {
    if (length(dots) == 1L && is.list(dots[[1L]]) && !is.null(dots[[1L]]$type)) return(normalize_anchor(dots[[1L]]))
    if (!is.null(dots$element)) return(normalize_anchor(list(type = "element_id", id = dots$element)))
    if (!is.null(dots$id)) return(normalize_anchor(list(type = "element_id", id = dots$id)))
    for (nm in c("data_key", "data_predicate", "structure_path", "role", "region")) {
      if (!is.null(dots[[nm]])) return(normalize_anchor(c(list(type = nm), dots[[nm]])))
    }
  }
  if (is.null(selectors)) cli::cli_abort("Provide an anchor selector.")
  normalize_anchor(selectors)
}

anchor_candidates <- function(fig, selector) {
  s <- normalize_selector(selector)
  t <- s$type
  el <- fig$substrate$elements
  if (!nrow(el)) return(character())
  if (t == "element_id") {
    id <- as.character(s$id %||% "")
    return(el$id[el$id == id | (!is.null(el$stable_id) & el$stable_id == id)])
  }
  if (t == "structure_path") {
    lv <- fig$substrate$leaves
    keep <- rep(TRUE, nrow(lv))
    if (!is.null(s$leaf)) keep <- keep & lv$id %in% as.character(s$leaf)
    if (!is.null(s$path)) keep <- keep & lv$path %in% as.character(s$path)
    if (!is.null(s$name)) keep <- keep & lv$name %in% as.character(s$name)
    if (!is.null(s$class)) keep <- keep & lv$class %in% as.character(s$class)
    if (!is.null(s$panel) && "panel" %in% names(lv)) keep <- keep & lv$panel %in% as.character(s$panel)
    leaves <- lv$id[keep]
    out <- el$id[el$leaf %in% leaves]
    if (!is.null(s$tag)) out <- el$id[el$id %in% out & el$tag %in% as.character(s$tag)]
    if (!is.null(s$ordinal)) out <- el$id[el$id %in% out & el$ordinal %in% as.integer(s$ordinal)]
    if (!is.null(s$element)) out <- intersect(out, as.character(s$element))
    return(out)
  }
  if (t == "role") {
    roles <- tryCatch(gl_classify(fig, by = "element"), error = function(e) NULL)
    if (is.null(roles) || !nrow(roles)) return(character())
    keep <- rep(TRUE, nrow(roles))
    if (!is.null(s$role)) keep <- keep & roles$role %in% as.character(s$role)
    if (!is.null(s$kind)) keep <- keep & roles$kind %in% as.character(s$kind)
    ids <- roles$element[keep]
    if (!is.null(s$panel) && "leaf" %in% names(el)) {
      ids <- ids[ids %in% el$id[el$leaf %in% fig$substrate$leaves$id[fig$substrate$leaves$panel %in% s$panel]]]
    }
    return(ids)
  }
  if (t == "region") {
    keep <- rep(TRUE, nrow(el))
    if (!is.null(s$panel)) {
      lv <- fig$substrate$leaves
      ids <- lv$id[lv$panel %in% as.character(s$panel)]
      keep <- keep & el$leaf %in% ids
    }
    cx <- (el$x0 + el$x1) / 2; cy <- (el$y0 + el$y1) / 2
    xr <- as.numeric(s$x %||% s$x_range %||% c(-Inf, Inf)); yr <- as.numeric(s$y %||% s$y_range %||% c(-Inf, Inf))
    if (length(xr) != 2L || length(yr) != 2L) cli::cli_abort("A region selector needs x and y ranges of length 2.")
    keep <- keep & cx >= min(xr) & cx <= max(xr) & cy >= min(yr) & cy <= max(yr)
    return(el$id[keep])
  }
  bindings <- fig$derived$bindings$tables$elements %||% data.frame()
  if (!nrow(bindings) || is.null(s$table)) return(character())
  b <- bindings[bindings$table %in% as.character(s$table), , drop = FALSE]
  if (!nrow(b)) return(character())
  tbl <- fig$tables[[as.character(s$table)[1L]]]
  if (is.null(tbl) || is.null(tbl$data)) return(character())
  d <- tbl$data
  rows <- seq_len(nrow(d))
  if (t == "data_key") {
    key <- s$key
    if (is.list(key) && length(key) && !is.null(names(key))) {
      for (nm in names(key)) if (nm %in% names(d)) rows <- rows[!is.na(d[[nm]][rows]) & as.character(d[[nm]][rows]) %in% as.character(key[[nm]])]
    } else if (!is.null(s$row) || (is.list(key) && !is.null(key$.row))) {
      rr <- as.integer(s$row %||% key$.row); rows <- intersect(rows, rr)
    } else if (!is.null(key) && length(tbl$key)) {
      vals <- as.character(key); names(vals) <- tbl$key[seq_len(min(length(vals), length(tbl$key)))]
      for (nm in names(vals)) rows <- rows[as.character(d[[nm]][rows]) %in% vals[[nm]]]
    }
  } else if (t == "data_predicate") {
    pred <- s$predicate %||% s$where
    if (is.null(pred) && !is.null(s$column)) pred <- s[c("column", "op", "value")]
    if (!is.list(pred) || is.null(pred$column)) return(character())
    col <- pred$column; op <- pred$op %||% "=="; val <- pred$value
    if (!col %in% names(d)) return(character())
    x <- d[[col]]
    hit <- switch(op, `==` = x == val, `!=` = x != val, `>` = x > val, `>=` = x >= val,
                  `<` = x < val, `<=` = x <= val, `%in%` = x %in% val,
                  contains = grepl(as.character(val), as.character(x), fixed = TRUE), rep(FALSE, length(x)))
    rows <- rows[which(!is.na(hit) & hit)]
  }
  b$element[which(b$row %in% rows)]
}

#' Resolve an anchor against a figure
#'
#' @param fig A `gloss_figure`.
#' @param anchor An anchor or selector.
#' @return A list with `status` (`unique`, `ambiguous` or `missing`), selected
#'   selector and candidate element ids.
#' @export
gl_resolve_anchor <- function(fig, anchor) {
  check_figure(fig)
  a <- normalize_anchor(anchor)
  attempts <- list()
  missed <- FALSE
  for (s in a$selectors) {
    ids <- unique(as.character(anchor_candidates(fig, s)))
    status <- if (length(ids) == 1L) "unique" else if (length(ids) > 1L) "ambiguous" else "missing"
    attempts[[length(attempts) + 1L]] <- list(selector = s, status = status, candidates = ids)
    if (status == "unique") {
      row <- match(ids, fig$substrate$elements$id)
      stable <- if (length(row) && "stable_id" %in% names(fig$substrate$elements)) {
        fig$substrate$elements$stable_id[row]
      } else ids
      data_target <- if (length(row)) data_element_id(fig, row) else stable
      if (missed) {
        return(list(status = "ambiguous", target = character(), stable_target = stable,
                    data_target = data_target, candidates = ids, selector = s,
                    reason = "a more stable selector was missing; a fallback target is not accepted",
                    attempts = attempts))
      }
      return(list(status = status, target = ids, stable_target = stable,
                  data_target = data_target, candidates = ids, selector = s,
                  attempts = attempts))
    }
    if (status == "ambiguous") return(list(status = status, target = character(), candidates = ids,
                                            selector = s, attempts = attempts))
    missed <- TRUE
  }
  list(status = "missing", target = character(), candidates = character(),
       selector = if (length(attempts)) attempts[[length(attempts)]]$selector else NULL,
       attempts = attempts)
}
