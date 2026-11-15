# Deterministic structure/data views over a captured figure (M1 Task 7).
# These are read-only projections of the substrate, derived roles and checked
# bindings. They do not add records or change the figure.

tree_node_empty <- function() {
  data.frame(id = character(), parent = character(), type = character(), name = character(),
             path = character(), panel = character(), leaf = character(), element = character(),
             role = character(), kind = character(), n_elements = integer(), table = character(),
             row = integer(), status = character(), stringsAsFactors = FALSE)
}

tree_edge_empty <- function() data.frame(parent = character(), child = character(), stringsAsFactors = FALSE)

structure_tree <- function(fig) {
  sub <- fig$substrate
  roles <- fig$derived$roles$tables %||% list()
  re <- roles$elements %||% role_element_empty()
  rl <- roles$leaves %||% role_leaf_empty()
  acc <- new.env(parent = emptyenv())
  acc$nodes <- list()
  acc$edges <- list()
  add <- function(id, parent, type, name = NA_character_, path = NA_character_, panel = NA_character_,
                  leaf = NA_character_, element = NA_character_, role = NA_character_, kind = NA_character_,
                  n_elements = NA_integer_, table = NA_character_, row = NA_integer_, status = NA_character_) {
    acc$nodes[[length(acc$nodes) + 1L]] <- data.frame(
      id = id, parent = parent, type = type, name = name, path = path, panel = panel,
      leaf = leaf, element = element, role = role, kind = kind, n_elements = as.integer(n_elements),
      table = table, row = as.integer(row), status = status, stringsAsFactors = FALSE
    )
    if (!is.na(parent) && nzchar(parent)) acc$edges[[length(acc$edges) + 1L]] <- data.frame(parent = parent, child = id, stringsAsFactors = FALSE)
  }
  fig_id <- "structure:figure"
  add(fig_id, NA_character_, "figure", fig$meta$class[1] %||% "figure", status = fig$meta$page$verdict %||% NA_character_)
  panels <- sub$panels
  if (is.data.frame(panels) && nrow(panels)) {
    for (i in seq_len(nrow(panels))) {
      pid <- paste0("structure:panel:", panels$id[i])
      add(pid, fig_id, "panel", panels$key[i] %||% panels$id[i], panels$vp[i] %||% NA_character_, panel = panels$id[i])
    }
  }
  panel_parent <- function(pid) {
    if (!is.na(pid) && nzchar(pid) && is.data.frame(panels) && pid %in% panels$id) paste0("structure:panel:", pid) else fig_id
  }
  for (i in seq_len(nrow(sub$leaves))) {
    lf <- sub$leaves[i, , drop = FALSE]
    id <- lf$id[1]
    lr <- rl[rl$leaf == id, , drop = FALSE]
    parent <- panel_parent(lf$panel[1])
    lid <- paste0("structure:leaf:", id)
    add(lid, parent, "leaf", lf$name[1], lf$path[1], panel = lf$panel[1], leaf = id,
        role = if (nrow(lr)) lr$role[1] else NA_character_, kind = if (nrow(lr)) lr$kind[1] else NA_character_,
        n_elements = lf$n_drawn[1], status = if (nrow(lr)) lr$status[1] else NA_character_)
    es <- sub$elements[sub$elements$leaf == id, , drop = FALSE]
    for (j in seq_len(nrow(es))) {
      er <- re[re$element == es$id[j], , drop = FALSE]
      eid <- paste0("structure:element:", es$id[j])
      add(eid, lid, "element", es$tag[j], path = NA_character_, panel = lf$panel[1], leaf = id,
          element = es$id[j], role = if (nrow(er)) er$role[1] else NA_character_,
          kind = if (nrow(er)) er$kind[1] else NA_character_, n_elements = 1L,
          status = if (nrow(er)) er$status[1] else NA_character_)
    }
  }
  list(view = "structure", nodes = if (length(acc$nodes)) do.call(rbind, acc$nodes) else tree_node_empty(),
       edges = if (length(acc$edges)) do.call(rbind, acc$edges) else tree_edge_empty())
}

data_tree <- function(fig) {
  acc <- new.env(parent = emptyenv())
  acc$nodes <- list()
  acc$edges <- list()
  add <- function(id, parent, type, name = NA_character_, path = NA_character_, panel = NA_character_,
                  leaf = NA_character_, element = NA_character_, role = NA_character_, kind = NA_character_,
                  n_elements = NA_integer_, table = NA_character_, row = NA_integer_, status = NA_character_) {
    acc$nodes[[length(acc$nodes) + 1L]] <- data.frame(
      id = id, parent = parent, type = type, name = name, path = path, panel = panel,
      leaf = leaf, element = element, role = role, kind = kind, n_elements = as.integer(n_elements),
      table = table, row = as.integer(row), status = status, stringsAsFactors = FALSE
    )
    if (!is.na(parent) && nzchar(parent)) acc$edges[[length(acc$edges) + 1L]] <- data.frame(parent = parent, child = id, stringsAsFactors = FALSE)
  }
  for (nm in names(fig$tables)) {
    tbl <- fig$tables[[nm]]
    tid <- paste0("data:table:", nm)
    n <- if (is.null(tbl$data)) 0L else nrow(tbl$data)
    add(tid, NA_character_, "table", nm, table = nm, n_elements = n, status = tbl$status)
    if (!n) next
    keys <- key_values(tbl)
    group <- if (!is.null(tbl$data$group)) as.character(tbl$data$group) else rep("__all__", n)
    for (g in unique(group)) {
      gid <- paste0(tid, ":series:", g)
      add(gid, tid, "series", g, table = nm)
      for (j in which(group == g)) {
        rid <- paste0(gid, ":row:", j)
        add(rid, gid, "row", if (length(keys)) keys[j] else as.character(j), table = nm, row = j, status = tbl$status)
      }
    }
  }
  list(view = "data", nodes = if (length(acc$nodes)) do.call(rbind, acc$nodes) else tree_node_empty(),
       edges = if (length(acc$edges)) do.call(rbind, acc$edges) else tree_edge_empty())
}

#' Read the deterministic structure or data tree
#'
#' @param fig A `gloss_figure`.
#' @param view One of `"structure"` or `"data"`.
#' @return A list with `nodes` and `edges` data frames.
#' @export
gl_tree <- function(fig, view = c("structure", "data")) {
  check_figure(fig)
  view <- match.arg(view)
  out <- if (identical(view, "structure")) structure_tree(fig) else data_tree(fig)
  class(out) <- c("gloss_tree", class(out))
  out
}

#' Map structure elements or leaves to checked data rows
#'
#' @param fig A `gloss_figure`.
#' @param by One row per `"element"` or `"leaf"`.
#' @param where Optional named filters applied to the mapping columns.
#' @return A data frame joining roles to checked binding rows.
#' @export
gl_map <- function(fig, by = c("element", "leaf"), where = NULL) {
  check_figure(fig)
  by <- match.arg(by)
  roles <- fig$derived$roles$tables %||% list()
  rr <- if (identical(by, "element")) roles$elements else roles$leaves
  if (is.null(rr)) rr <- if (identical(by, "element")) role_element_empty() else role_leaf_empty()
  b <- gl_bindings(fig, by = by)
  if ("status" %in% names(rr)) {
    rr$role_status <- rr$status
    rr$status <- NULL
  }
  if ("status" %in% names(b)) {
    b$binding_status <- b$status
    b$status <- NULL
  }
  keys <- if (identical(by, "element")) c("element", "leaf") else "leaf"
  out <- merge(rr, b, by = keys, all = TRUE, sort = FALSE)
  if (!"status" %in% names(out)) out$status <- out$binding_status %||% out$role_status
  out$structure <- if (identical(by, "element")) paste0("structure:element:", out$element) else paste0("structure:leaf:", out$leaf)
  if (!is.null(where)) {
    for (nm in names(where)) {
      if (!nm %in% names(out)) cli::cli_abort("Unknown map field {.val {nm}}.")
      out <- out[out[[nm]] %in% where[[nm]], , drop = FALSE]
    }
  }
  rownames(out) <- NULL
  out
}
