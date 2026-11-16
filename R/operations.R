# Operations are serializable requests over the substrate.  They are validated
# before projection and materialised into attributes/classes plus a separate
# overlay group.  The captured scene stored in the figure is never rewritten.

operation_names <- c("select", "style", "show", "hide", "raise", "lower",
                     "focus", "link", "unlink", "overlay", "tooltip")

operation_target_schema <- list(target = "any")

register_operation_builtin <- function(name, schema, r, js = name, description = name) {
  schema <- c(list(op = list(type = "string", enum = name)), schema)
  gl_register("operation", name = name, version = "0.1.0", package = "gloss",
              description = description, schema = schema, r = r, js = js)
}

register_builtin_operations <- function() {
  register_operation_builtin(
    "select", list(target = "any", "trigger?" = c("click", "hover", "key")),
    operation_select, description = "Select anchored elements.")
  register_operation_builtin(
    "style", list(target = "any", style = c("highlight", "fade", "color", "outline"),
                  "value?" = "string", "trigger?" = c("click", "hover", "key")),
    operation_style, description = "Apply a class-based style to anchored elements.")
  register_operation_builtin(
    "show", operation_target_schema, operation_show, description = "Show anchored elements.")
  register_operation_builtin(
    "hide", operation_target_schema, operation_hide, description = "Hide anchored elements.")
  register_operation_builtin(
    "raise", operation_target_schema, operation_raise, description = "Mark anchored elements for the raised order.")
  register_operation_builtin(
    "lower", operation_target_schema, operation_lower, description = "Mark anchored elements for the lowered order.")
  register_operation_builtin(
    "focus", operation_target_schema, operation_focus, description = "Make anchored elements keyboard focusable.")
  register_operation_builtin(
    "link", list(from = "any", to = "any", "relation?" = "string"),
    operation_link, description = "Link two anchored targets.")
  register_operation_builtin(
    "unlink", list(from = "any", to = "any", "relation?" = "string"),
    operation_unlink, description = "Remove a link between two anchored targets.")
  register_operation_builtin(
    "overlay", list(target = "any", kind = c("box", "leader", "bracket", "region"),
                     "text?" = "string", "basis?" = list(type = "array", items = "string")),
    operation_overlay, description = "Draw an anchored semantic overlay.")
  register_operation_builtin(
    "tooltip", list(target = "any", "field?" = "string", "text?" = "string",
                     "trigger?" = c("hover", "click", "key")),
    operation_tooltip, description = "Show text for an anchored target.")
}

operation_state_empty <- function() {
  list(classes = list(), attrs = list(), styles = list(), visibility = list(),
       order = list(), overlays = list(), links = list(), tooltips = list(),
       focus = character())
}

operation_add_class <- function(state, id, class) {
  state$classes[[id]] <- unique(c(state$classes[[id]] %||% character(), class))
  state
}

operation_set_attr <- function(state, id, name, value) {
  attrs <- state$attrs[[id]] %||% list()
  attrs[[name]] <- as.character(value)[1L]
  state$attrs[[id]] <- attrs
  state
}

operation_select <- function(fig, op, state) {
  for (id in op$targets) state <- operation_add_class(state, id, "gloss-selected")
  state
}

operation_style <- function(fig, op, state) {
  class <- paste0("gloss-", op$style)
  declarations <- switch(op$style,
    highlight = c(stroke = "#315bb6", `stroke-width` = "2.2"),
    fade = c(opacity = "0.28"),
    color = c(stroke = op$value %||% "#315bb6"),
    outline = c(stroke = op$value %||% "#315bb6", `stroke-width` = "1.6")
  )
  for (id in op$targets) {
    state <- operation_add_class(state, id, class)
    state$styles[[id]] <- c(state$styles[[id]] %||% list(), as.list(declarations))
    if (!is.null(op$value)) state <- operation_set_attr(state, id, "data-gloss-style-value", op$value)
  }
  state
}

operation_show <- function(fig, op, state) {
  for (id in op$targets) state$visibility[[id]] <- TRUE
  state
}

operation_hide <- function(fig, op, state) {
  for (id in op$targets) state$visibility[[id]] <- FALSE
  state
}

operation_raise <- function(fig, op, state) {
  for (id in op$targets) {
    state$order[[id]] <- "raise"
    state <- operation_add_class(state, id, "gloss-raised")
  }
  state
}

operation_lower <- function(fig, op, state) {
  for (id in op$targets) {
    state$order[[id]] <- "lower"
    state <- operation_add_class(state, id, "gloss-lowered")
  }
  state
}

operation_focus <- function(fig, op, state) {
  for (id in op$targets) {
    state$focus <- unique(c(state$focus, id))
    state <- operation_set_attr(state, id, "tabindex", "0")
    state <- operation_add_class(state, id, "gloss-focus")
  }
  state
}

operation_link <- function(fig, op, state) {
  state$links[[length(state$links) + 1L]] <- list(
    from = op$from_targets[1L], to = op$to_targets[1L],
    relation = op$relation %||% "related"
  )
  state
}

operation_unlink <- function(fig, op, state) {
  keep <- vapply(state$links, function(x) {
    !identical(c(x$from, x$to), c(op$from_targets[1L], op$to_targets[1L])) &&
      !identical(c(x$from, x$to), c(op$to_targets[1L], op$from_targets[1L]))
  }, logical(1))
  state$links <- state$links[keep]
  state
}

operation_overlay <- function(fig, op, state) {
  state$overlays[[length(state$overlays) + 1L]] <- list(
    kind = op$kind, targets = op$targets, text = op$text %||% "",
    basis = op$basis %||% character(), status = op$basis_status %||% "unverified"
  )
  state
}

operation_tooltip <- function(fig, op, state) {
  text <- op$text %||% if (!is.null(op$field)) paste0("field:", op$field) else ""
  for (id in op$targets) {
    state$tooltips[[id]] <- text
    state <- operation_set_attr(state, id, "data-gloss-tooltip", text)
    state <- operation_set_attr(state, id, "tabindex", "0")
  }
  state
}

operation_anchor_ids <- function(fig, anchor) {
  if (is.null(anchor)) cli::cli_abort("An operation target is required.")
  anchors <- if (is.character(anchor) && length(anchor) > 1L) {
    lapply(anchor, normalize_anchor)
  } else {
    list(normalize_anchor(anchor))
  }
  ids <- character()
  for (a in anchors) {
    resolved <- gl_resolve_anchor(fig, a)
    if (resolved$status == "missing") {
      cli::cli_abort("An operation target could not be resolved.")
    }
    if (resolved$status == "ambiguous" && !length(resolved$candidates)) {
      cli::cli_abort("An operation target is ambiguous and has no candidates.")
    }
    ids <- c(ids, as.character(resolved$candidates %||% resolved$target))
  }
  unique(ids)
}

operation_basis_status <- function(fig, ids) {
  if (!length(ids)) return("unverified")
  recs <- attr(gl_records(fig), "records")
  if (!length(recs)) return("unverified")
  hits <- recs[vapply(recs, function(r) r$id %in% ids, logical(1))]
  if (!length(hits)) return("unverified")
  if (all(vapply(hits, record_is_factual, logical(1)))) return("verified")
  if (any(vapply(hits, function(r) identical(record_projection_status(r), "speculative"), logical(1)))) {
    return("speculative")
  }
  "unverified"
}

normalize_operation <- function(fig, operation) {
  if (!is.list(operation) || is.null(operation$op)) {
    cli::cli_abort("An operation needs an {.arg op} field.")
  }
  name <- as.character(operation$op)[1L]
  plugin <- gl_plugin("operation", name, must_exist = FALSE)
  if (is.null(plugin)) cli::cli_abort("No operation plugin named {.val {name}} is registered.")
  problems <- gl_schema_validate(operation, plugin$schema)
  if (length(problems)) cli::cli_abort(c("Invalid operation {.val {name}}.", bullets_x(problems)))
  out <- operation
  out$op <- name
  if (!is.null(operation$target)) out$targets <- operation_anchor_ids(fig, operation$target)
  if (name %in% c("link", "unlink")) {
    out$from_targets <- operation_anchor_ids(fig, operation$from)
    out$to_targets <- operation_anchor_ids(fig, operation$to)
    if (length(out$from_targets) != 1L || length(out$to_targets) != 1L) {
      cli::cli_abort("A link operation needs exactly one target at each endpoint.")
    }
  }
  if (name == "overlay") {
    basis <- as.character(operation$basis %||% character())
    out$basis_status <- operation_basis_status(fig, basis)
    if (length(basis) && identical(out$basis_status, "unverified")) {
      cli::cli_abort("An overlay basis must reference a verified or speculative record.")
    }
    if (!length(basis) && nzchar(operation$text %||% "")) {
      cli::cli_abort("A factual overlay needs a verified record in {.arg basis}.")
    }
  }
  out
}

normalize_operations <- function(operations) {
  if (is.null(operations)) return(list())
  if (is.list(operations) && is_string(operations$op)) return(list(operations))
  if (!is.list(operations) || !length(operations) ||
      !all(vapply(operations, is.list, logical(1)))) {
    cli::cli_abort("{.arg operations} must be an operation or a list of operations.")
  }
  operations
}

#' Apply checked semantic operations to a figure projection
#'
#' Operations are validated against the operation registry and existing
#' anchors. The returned figure carries the operation specifications and a
#' materialised projection state. Its captured substrate is not modified.
#'
#' @param fig A `gloss_figure`.
#' @param operations One operation or a list of operations.
#' @return A `gloss_figure` with projection operations attached.
#' @export
gl_apply <- function(fig, operations) {
  check_figure(fig)
  specs <- normalize_operations(operations)
  state <- fig$operations$state %||% operation_state_empty()
  old_specs <- fig$operations$specs %||% list()
  normalized <- lapply(specs, function(op) normalize_operation(fig, op))
  for (op in normalized) {
    plugin <- gl_plugin("operation", op$op)
    state <- plugin$r(fig, op, state)
  }
  out <- fig
  out$operations <- list(specs = c(old_specs, normalized), state = state,
                         enabled = unique(vapply(c(old_specs, normalized), `[[`, "", "op")))
  out
}

operation_element_style <- function(node, declarations) {
  old <- xml2::xml_attr(node, "style")
  old <- ifelse(is.na(old), "", old)
  add <- paste(names(declarations), declarations, sep = ": ", collapse = "; ")
  if (nzchar(old) && !grepl(";$", old)) old <- paste0(old, ";")
  xml2::xml_set_attr(node, "style", paste(old, add, sep = " "))
}

operation_node_map <- function(doc, fig) {
  nodes <- xml2::xml_find_all(doc, prim_xpath(), svg_ns(doc))
  ids <- fig$substrate$elements$id
  n <- min(length(nodes), length(ids))
  out <- stats::setNames(nodes[seq_len(n)], ids[seq_len(n)])
  if (n) {
    for (i in seq_len(n)) {
      xml2::xml_set_attr(nodes[[i]], "data-gloss-element", ids[i])
      stable <- fig$substrate$elements$stable_id[i] %||% ids[i]
      xml2::xml_set_attr(nodes[[i]], "data-gloss-stable", stable)
    }
  }
  out
}

operation_box <- function(fig, id) {
  row <- fig$substrate$elements[fig$substrate$elements$id == id, , drop = FALSE]
  if (!nrow(row)) return(NULL)
  list(x = mean(c(row$x0, row$x1)), y = mean(c(row$y0, row$y1)),
       x0 = row$x0, x1 = row$x1, y0 = row$y0, y1 = row$y1)
}

operation_overlay_node <- function(group, spec, fig) {
  boxes <- Filter(Negate(is.null), lapply(spec$targets, operation_box, fig = fig))
  if (!length(boxes)) return(invisible())
  x0 <- min(vapply(boxes, `[[`, 0, "x0")); x1 <- max(vapply(boxes, `[[`, 0, "x1"))
  y0 <- min(vapply(boxes, `[[`, 0, "y0")); y1 <- max(vapply(boxes, `[[`, 0, "y1"))
  if (spec$kind %in% c("box", "region", "bracket")) {
    xml2::xml_add_child(
      group, "rect", x = x0, y = y0, width = max(0, x1 - x0), height = max(0, y1 - y0),
      class = paste("gloss-overlay-mark", paste0("gloss-overlay-", spec$kind)),
      fill = "none", stroke = "#315bb6", `stroke-width` = "1.2",
      `pointer-events` = "none"
    )
  }
  if (spec$kind %in% c("leader", "bracket") && nzchar(spec$text %||% "")) {
    xml2::xml_add_child(
      group, "line", x1 = x1, y1 = y0, x2 = x1 + 12, y2 = y0 - 12,
      class = "gloss-overlay-leader", stroke = "#315bb6",
      `stroke-width` = "1.2", `pointer-events` = "none"
    )
  }
  if (nzchar(spec$text %||% "")) {
    xml2::xml_add_child(
      group, "text", as.character(spec$text), x = x1 + 14, y = y0 - 14,
      class = "gloss-overlay-text", fill = "#17345f",
      `font-size` = "10", `pointer-events` = "none"
    )
  }
  invisible()
}

operation_link_node <- function(group, link, fig) {
  from <- operation_box(fig, link$from); to <- operation_box(fig, link$to)
  if (is.null(from) || is.null(to)) return(invisible())
  xml2::xml_add_child(
    group, "line", x1 = from$x, y1 = from$y, x2 = to$x, y2 = to$y,
    class = "gloss-overlay-link", `data-gloss-relation` = link$relation,
    stroke = "#6b7280", `stroke-width` = "1", `stroke-dasharray` = "3 2",
    `pointer-events` = "none"
  )
  invisible()
}

scene_with_operations <- function(fig) {
  s <- fig$substrate$scene
  ops <- fig$operations %||% NULL
  if (is.null(ops) || !length(ops$specs)) return(s)
  doc <- read_page(s)
  nodes <- operation_node_map(doc, fig)
  state <- ops$state %||% operation_state_empty()
  for (id in names(state$classes %||% list())) {
    node <- nodes[[id]]
    if (is.null(node)) next
    old <- xml2::xml_attr(node, "class")
    classes <- unique(c(ifelse(is.na(old), character(), strsplit(old, "\\s+")[[1L]]), state$classes[[id]]))
    xml2::xml_set_attr(node, "class", paste(classes, collapse = " "))
  }
  for (id in names(state$visibility %||% list())) {
    node <- nodes[[id]]
    if (is.null(node)) next
    if (isTRUE(state$visibility[[id]])) {
      xml2::xml_set_attr(node, "data-gloss-visible", "true")
    } else {
      xml2::xml_set_attr(node, "data-gloss-visible", "false")
      operation_element_style(node, c(display = "none"))
    }
  }
  for (id in names(state$attrs %||% list())) {
    node <- nodes[[id]]
    if (is.null(node)) next
    for (nm in names(state$attrs[[id]])) xml2::xml_set_attr(node, nm, state$attrs[[id]][[nm]])
  }
  for (id in names(state$styles %||% list())) {
    node <- nodes[[id]]
    if (is.null(node)) next
    operation_element_style(node, state$styles[[id]])
  }
  for (id in names(state$tooltips %||% list())) {
    node <- nodes[[id]]
    if (!is.null(node)) xml2::xml_set_attr(node, "data-gloss-tooltip", state$tooltips[[id]])
  }
  root <- xml2::xml_find_first(doc, "/d1:svg/d1:g[@class='svglite']", svg_ns(doc))
  if (inherits(root, "xml_missing")) root <- xml2::xml_root(doc)
  overlay <- xml2::xml_add_child(
    root, "g", class = "gloss-overlay", `data-gloss-generated` = "true",
    `pointer-events` = "none"
  )
  for (spec in state$overlays %||% list()) operation_overlay_node(overlay, spec, fig)
  for (link in state$links %||% list()) operation_link_node(overlay, link, fig)
  if (!length(xml2::xml_children(overlay))) xml2::xml_remove(overlay)
  sub("^<\\?xml[^>]*>\\s*", "", as.character(doc))
}

