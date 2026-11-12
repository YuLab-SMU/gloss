# Tools for an agent over one figure (design: agent tools; plan
# 2026-11-12-agent-path, Task 3). Read-only queries and one `propose`, which
# validates on submit (gl_propose()). gloss owns no agent loop: gl_tools()
# hands the tools to aisdk, and the loop is aisdk's.
#
# tool_specs() is the tools' work in plain R, with no aisdk: each tool takes
# its arguments as a list, checks them against its schema, and returns JSON.
# A call a tool cannot serve comes back as {"error": ...}; it never raises.
# Every call is noted in `state$calls`; only `propose` writes
# `state$proposals`. The figure is never changed.

tool_row_limit <- 20L

tool_json <- function(x) {
  as.character(jsonlite::toJSON(x, auto_unbox = TRUE, digits = 8, na = "null", null = "null", dataframe = "rows"))
}

# A data frame of atomic columns a model can read: factors as strings.
tool_rows <- function(df) {
  keep <- vapply(df, is.atomic, logical(1))
  df <- df[keep]
  for (cn in names(df)) if (is.factor(df[[cn]])) df[[cn]] <- as.character(df[[cn]])
  rownames(df) <- NULL
  df
}

tool_specs <- function(fig, hide = NULL) {
  check_figure(fig)
  state <- new.env(parent = emptyenv())
  state$calls <- list()
  state$proposals <- list()
  ctx <- propose_context(fig)
  sub <- fig$substrate
  elements <- gl_elements(fig)
  bound <- fig$derived$bindings$tables
  stop_tool <- function(...) stop(sprintf(...), call. = FALSE)
  table_data <- function(name) {
    t <- fig$tables[[name]]
    if (is.null(t) || is.null(t$data)) stop_tool("no table '%s' with rows in the figure", quoted(name))
    t
  }
  panel_row <- function(id) {
    p <- sub$panels[sub$panels$id %in% id, , drop = FALSE]
    if (nrow(p) != 1L) stop_tool("no panel '%s'", quoted(id))
    if (anyNA(c(p$x_min, p$x_max, p$y_min, p$y_max))) stop_tool("the scales of panel '%s' are not ranges on the page", p$id)
    p
  }
  element_view <- function(e) {
    data.frame(id = e$id, tag = e$tag, leaf = e$leaf, panel = e$panel,
               cx = round((e$x0 + e$x1) / 2, 2), cy = round((e$y0 + e$y1) / 2, 2),
               fill = e$fill, text = e$text, stringsAsFactors = FALSE)
  }

  tools <- list(
    overview = list(
      description = "The figure: its size, its panels with their place on the page and their scales, and its tables.",
      params = list(),
      run = function(a) {
        list(engine = fig$meta$engine, width_pt = fig$meta$width * 72, height_pt = fig$meta$height * 72,
             elements = nrow(elements), leaves = nrow(sub$leaves),
             panels = sub$panels[intersect(c("id", "key", "x0", "y0", "x1", "y1", "x_type", "x_min", "x_max",
                                             "y_type", "y_min", "y_max", "flipped"), names(sub$panels))],
             tables = unname(lapply(fig$tables, function(t) {
               list(name = t$name, role = t$role, layer = if (is.na(t$layer)) NULL else t$layer,
                    rows = if (is.null(t$data)) NULL else nrow(t$data),
                    columns = if (is.null(t$data)) NULL else as.list(names(t$data)))
             })),
             note = paste("Positions are in pt from the top left of the page. A panel's scales map data values",
                          "onto its box (x0..x1, y1..y0). In a flipped panel the horizontal scale carries the tables' y.",
                          "In a built table, PANEL k is the panel whose id ends in 'panel' and k."))
      }),
    find_elements = list(
      description = "The elements drawn at a point of the page (pt from the top left), topmost first.",
      params = list(x = list("number", "horizontal position, pt"), y = list("number", "vertical position, pt")),
      run = function(a) utils::head(element_view(gl_hit(fig, a$x, a$y, tolerance = 1)), tool_row_limit)),
    get_element = list(
      description = "One element: what it is, where it is drawn, its leaf and its panel.",
      params = list(element = list("string", "element id")),
      run = function(a) {
        e <- elements[elements$id %in% a$element, , drop = FALSE]
        if (nrow(e) != 1L) stop_tool("no element '%s' in the figure", quoted(a$element))
        lf <- sub$leaves[sub$leaves$id %in% e$leaf, , drop = FALSE]
        c(as.list(element_view(e)), list(x0 = e$x0, y0 = e$y0, x1 = e$x1, y1 = e$y1, stroke = e$stroke,
                                         leaf_class = if (nrow(lf)) lf$class else NULL,
                                         leaf_elements = if (nrow(lf)) lf$n_drawn else NULL))
      }),
    get_binding = list(
      description = "The row of a table an element draws, as checked against the page when the figure was captured.",
      params = list(element = list("string", "element id")),
      run = function(a) {
        e <- elements[elements$id %in% a$element, , drop = FALSE]
        if (nrow(e) != 1L) stop_tool("no element '%s' in the figure", quoted(a$element))
        if (is.null(bound)) return(list(element = e$id, bound = FALSE, reason = "the figure holds no bindings"))
        if (!is.na(e$leaf) && e$leaf %in% hide) {
          return(list(element = e$id, hidden = TRUE, note = "the bindings of this leaf are hidden for this run"))
        }
        b <- bound$elements[bound$elements$element %in% e$id, , drop = FALSE]
        if (!nrow(b) || is.na(b$row)) {
          lv <- bound$leaves[bound$leaves$leaf %in% e$leaf, , drop = FALSE]
          return(list(element = e$id, bound = FALSE,
                      reason = if (nrow(lv)) lv$reason %|NA|% lv$status else "the element belongs to no leaf"))
        }
        list(element = e$id, bound = TRUE, table = b$table, row = b$row, rows_in_group = b$n_rows, status = b$status)
      }),
    describe_table = list(
      description = "A table's columns, with their types and ranges; no rows.",
      params = list(table = list("string", "table name")),
      run = function(a) {
        t <- table_data(a$table)
        d <- tool_rows(t$data)
        list(name = t$name, role = t$role, rows = nrow(d), columns = lapply(names(d), function(cn) {
          v <- d[[cn]]
          out <- list(name = cn, type = class(v)[1])
          if (is.numeric(v) && any(is.finite(v))) {
            out$min <- min(v[is.finite(v)])
            out$max <- max(v[is.finite(v)])
          } else {
            u <- unique(stats::na.omit(as.character(v)))
            out$distinct <- length(u)
            if (length(u) <= 8L) out$values <- as.list(u)
          }
          out
        }))
      }),
    get_rows = list(
      description = sprintf("Rows of a table by their row numbers, at most %d.", tool_row_limit),
      params = list(table = list("string", "table name"), rows = list("integers", "row numbers")),
      run = function(a) {
        t <- table_data(a$table)
        r <- as.integer(unlist(a$rows))
        if (!length(r) || length(r) > tool_row_limit) stop_tool("between 1 and %d rows can be read at once", tool_row_limit)
        if (anyNA(r) || any(r < 1L | r > nrow(t$data))) stop_tool("the rows are not all in the table (%d rows)", nrow(t$data))
        cbind(row = r, tool_rows(t$data[r, , drop = FALSE]))
      }),
    find_rows = list(
      description = "The five rows of a layer's built data nearest to given data values of x and y, within one panel.",
      params = list(table = list("string", "table name"), panel = list("string", "panel id"),
                    x = list("number", "data value on the panel's horizontal scale"),
                    y = list("number", "data value on the panel's vertical scale")),
      run = function(a) {
        t <- table_data(a$table)
        if (!identical(t$role, "built")) stop_tool("'%s' is not a layer's built data", t$name)
        p <- panel_row(a$panel)
        d <- t$data
        k <- seq_len(nrow(d))
        if ("PANEL" %in% names(d)) k <- which(as.character(d$PANEL) == sub("^.*panel", "", p$id))
        placed <- place_rows(fig, t$name, k, p$id)
        if (is.character(placed)) stop_tool("%s", placed)
        at <- gl_to_pixel(fig, p$id, a$x, a$y)
        if (!all(c("x", "y") %in% names(placed))) stop_tool("the rows of '%s' have no single position (x, y)", t$name)
        dist <- pmax(abs(placed$x - at$x), abs(placed$y - at$y))
        o <- utils::head(order(dist), 5L)
        cols <- intersect(c("x", "y", "PANEL", "group"), names(d))
        cbind(row = k[o], tool_rows(d[k[o], cols, drop = FALSE]), pt_away = round(dist[o], 2))
      }),
    to_data = list(
      description = "The data values at a point of the page, on the scales of a panel.",
      params = list(panel = list("string", "panel id"), x = list("number", "horizontal position, pt"),
                    y = list("number", "vertical position, pt")),
      run = function(a) {
        p <- panel_row(a$panel)
        v <- gl_to_data(fig, p$id, a$x, a$y)
        list(panel = p$id, x = signif(v$x, 8), y = signif(v$y, 8),
             note = if (isTRUE(p$flipped)) "this panel is flipped: x here is what the tables call y, and y what they call x")
      }),
    propose = list(
      description = paste("Submit a binding: this element draws this row of this table. It is checked against the page.",
                          "Returns accepted, rejected with the reason, or refused when this figure does not let it be checked."),
      params = list(element = list("string", "element id"), table = list("string", "table name"),
                    row = list("integer", "row number")),
      run = function(a) {
        r <- check_proposal(ctx, list(kind = "binding", element = a$element, table = a$table, row = a$row))
        state$proposals[[length(state$proposals) + 1L]] <- c(
          list(proposal = list(element = a$element, table = a$table, row = a$row)), unclass(r))
        out <- list(outcome = r$outcome)
        if (length(r$reasons)) out$reasons <- as.list(r$reasons)
        if (!is.null(r$record)) out$status <- r$record$status
        if (isFALSE(r$record$layer_known)) {
          out$note <- "checked by place only: the figure does not say which layer drew this element"
        }
        out
      })
  )

  schema_of <- function(params) {
    lapply(params, function(p) switch(p[[1]], integers = list(type = "array", items = "integer", min = 1), p[[1]]))
  }
  run <- function(name, args = list()) {
    note <- function(ok, text) {
      state$calls[[length(state$calls) + 1L]] <- list(tool = name, args = args, ok = ok, result = substr(text, 1L, 500L))
      text
    }
    spec <- if (is_string(name)) tools[[name]]
    if (is.null(spec)) return(note(FALSE, tool_json(list(error = "no such tool"))))
    args <- if (length(args)) as.list(args) else stats::setNames(list(), character())
    problems <- gl_schema_validate(args, schema_of(spec$params))
    if (length(problems)) return(note(FALSE, tool_json(list(error = as.list(problems)))))
    out <- tryCatch(spec$run(args), error = function(e) structure(conditionMessage(e), class = "tool_error"))
    if (inherits(out, "tool_error")) return(note(FALSE, tool_json(list(error = substr(unclass(out), 1L, 300L)))))
    note(TRUE, tool_json(out))
  }
  list(names = names(tools), tools = tools, run = run, state = state)
}

#' Tools for an agent over one figure
#'
#' Read-only queries over a figure and one `propose`, as tools for
#' [aisdk](https://github.com/YuLab-SMU/aisdk) (`aisdk::generate_text(tools = )`,
#' `aisdk::create_agent(tools = )`). gloss runs no agent loop of its own.
#'
#' An agent given these tools can read the figure and can submit a binding,
#' which is checked on submit exactly as [gl_propose()] checks it: accepted,
#' rejected with the reason, or refused. It has no tool that writes the
#' figure, runs code or reaches outside. Every tool answers with JSON; a call
#' a tool cannot serve answers `{"error": ...}`.
#'
#' | tool | what it returns |
#' |---|---|
#' | `overview` | size, panels with their boxes and scales, tables with their columns |
#' | `find_elements` | the elements drawn at a point of the page |
#' | `get_element` | one element, its leaf and its panel |
#' | `get_binding` | the row an element draws, as checked at capture ([gl_bindings()]) |
#' | `describe_table` | a table's columns, types and ranges |
#' | `get_rows` | rows of a table by number, at most 20 |
#' | `find_rows` | the rows of a layer's built data nearest to data values in a panel |
#' | `to_data` | the data values at a point of the page |
#' | `propose` | the outcome of a submitted binding |
#'
#' @param fig A `gloss_figure`.
#' @param hide Leaf ids whose bindings `get_binding` does not disclose, for
#'   runs that ask an agent to work them out. `propose` checks all the same.
#' @return A list of `aisdk` tools. [gl_tool_state()] gives what happened
#'   through them.
#' @examples
#' \dontrun{
#' fig <- gloss(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point())
#' tools <- gl_tools(fig)
#' aisdk::generate_text(model = model, prompt = "Which row does the circle at (120, 80) pt draw?",
#'                      tools = tools, max_steps = 10)
#' gl_tool_state(tools)$proposals
#' }
#' @export
gl_tools <- function(fig, hide = NULL) {
  if (!requireNamespace("aisdk", quietly = TRUE)) {
    cli::cli_abort(c("{.fn gl_tools} needs the {.pkg aisdk} package.",
                     i = "The figure's queries and {.fn gl_propose} work without it."))
  }
  specs <- tool_specs(fig, hide = hide)
  z <- function(p) switch(p[[1]],
    number = aisdk::z_number(p[[2]]), string = aisdk::z_string(p[[2]]), integer = aisdk::z_integer(p[[2]]),
    integers = aisdk::z_array(aisdk::z_integer(), p[[2]]))
  tools <- lapply(specs$names, function(nm) {
    spec <- specs$tools[[nm]]
    params <- if (length(spec$params)) do.call(aisdk::z_object, lapply(spec$params, z)) else aisdk::z_empty_object()
    aisdk::tool(name = nm, description = spec$description, parameters = params,
                execute = function(...) specs$run(nm, list(...)))
  })
  attr(tools, "gloss_tool_state") <- specs$state
  tools
}

#' What happened through a figure's tools
#'
#' @param tools Tools made by [gl_tools()].
#' @return A list: `calls`, one entry per tool call (the tool, its arguments,
#'   whether it was served, the start of its answer), and `proposals`, one
#'   entry per call of `propose` (the proposal, its `outcome`, `stage`,
#'   `reasons` and, when accepted, its `record`).
#' @export
gl_tool_state <- function(tools) {
  state <- attr(tools, "gloss_tool_state")
  if (!is.environment(state)) cli::cli_abort("{.arg tools} were not made by {.fn gl_tools}.")
  list(calls = state$calls, proposals = state$proposals)
}
