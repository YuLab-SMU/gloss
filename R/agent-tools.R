# Stage-scoped tools for an agent over one figure. The plain-R factory is
# useful in tests and in other runtimes. gl_tools() adds aisdk Tool objects but
# gloss still owns no model loop.

tool_row_limit <- 20L

tool_json <- function(x) {
  as.character(jsonlite::toJSON(x, auto_unbox = TRUE, digits = 8, na = "null",
                                null = "null", dataframe = "rows"))
}

tool_rows <- function(df) {
  keep <- vapply(df, is.atomic, logical(1))
  df <- df[keep]
  for (cn in names(df)) if (is.factor(df[[cn]])) df[[cn]] <- as.character(df[[cn]])
  rownames(df) <- NULL
  df
}

tool_disclosure_rank <- function(level) match(level, agent_disclosure_levels)

tool_requires <- function(level, required) {
  tool_disclosure_rank(level) >= tool_disclosure_rank(required)
}

tool_allowed_layers <- function(stage_info, fig) {
  if (is.null(stage_info)) return(names(fig$layers %||% list()))
  intersect(stage_info$reads %||% character(), names(fig$layers %||% list()))
}

tool_record_view <- function(rows, disclose) {
  if (!nrow(rows)) return(rows)
  if (identical(disclose, "rows")) return(rows)
  keep <- intersect(c("id", "layer", "status", "anchor_status", "check_status", "by", "created"), names(rows))
  rows[, keep, drop = FALSE]
}

tool_context_view <- function(fig, item = NULL, disclose = "summary") {
  if (is.null(item)) return(gl_context(fig))
  out <- gl_context(fig, item)
  if (tool_requires(disclose, "rows")) return(out)
  list(item = out$item, plugin = out$plugin, found = out$found, reason = out$reason)
}

tool_table_description <- function(t, disclose) {
  d <- if (is.null(t$data)) NULL else tool_rows(t$data)
  out <- list(name = t$name, role = t$role, rows = if (is.null(d)) NULL else nrow(d))
  if (!tool_requires(disclose, "schema") || is.null(d)) return(out)
  out$columns <- lapply(names(d), function(cn) {
    v <- d[[cn]]
    item <- list(name = cn, type = class(v)[1])
    if (is.numeric(v) && any(is.finite(v))) {
      item$min <- min(v[is.finite(v)])
      item$max <- max(v[is.finite(v)])
    }
    if (tool_requires(disclose, "summary")) {
      u <- unique(stats::na.omit(as.character(v)))
      item$distinct <- length(u)
      if (length(u) <= 8L) item$values <- as.list(u)
    }
    item
  })
  out
}

tool_specs <- function(fig, hide = NULL, stage = NULL, disclose = NULL, state = NULL) {
  check_figure(fig)
  stage_info <- if (is.null(stage)) NULL else if (is.list(stage)) stage else stage_plugin_info(stage)
  if (is.null(disclose)) disclose <- stage_info$disclose %||% if (is.null(stage_info)) "rows" else "summary"
  disclose <- match.arg(disclose, agent_disclosure_levels)
  if (is.null(state)) {
    state <- if (is.null(stage_info)) new.env(parent = emptyenv()) else
      agent_stage_state(fig, stage_info$name, disclose = disclose)
  }
  if (is.null(state$calls)) state$calls <- list()
  if (is.null(state$proposals)) state$proposals <- list()
  if (is.null(state$candidates)) state$candidates <- list()
  state$disclose <- disclose
  state$stage <- state$stage %||% stage_info$name %||% NULL
  state$plugin <- state$plugin %||% stage_info

  ctx <- propose_context(fig)
  sub <- fig$substrate
  elements <- gl_elements(fig)
  bound <- fig$derived$bindings$tables
  allowed_tools <- stage_info$tools %||% NULL
  default_tools <- c("overview", "find_elements", "get_element", "get_binding",
                     "describe_table", "get_rows", "find_rows", "to_data", "propose")
  allowed_layers <- tool_allowed_layers(stage_info, fig)
  stop_tool <- function(...) stop(sprintf(...), call. = FALSE)
  require_tool <- function(name) {
    if (!is.null(allowed_tools) && !name %in% allowed_tools) {
      stop_tool("tool '%s' is not enabled for stage '%s'", name, stage_info$name)
    }
  }
  require_disclosure <- function(level, reason) {
    if (!tool_requires(disclose, level)) stop_tool("%s requires disclosure '%s'", reason, level)
  }
  table_data <- function(name, rows = FALSE) {
    if (rows) require_disclosure("rows", "table rows")
    t <- fig$tables[[name]]
    if (is.null(t) || is.null(t$data)) stop_tool("no table '%s' with rows in the figure", quoted(name))
    t
  }
  panel_row <- function(id) {
    p <- sub$panels[sub$panels$id %in% id, , drop = FALSE]
    if (nrow(p) != 1L) stop_tool("no panel '%s'", quoted(id))
    if (anyNA(c(p$x_min, p$x_max, p$y_min, p$y_max))) {
      stop_tool("the scales of panel '%s' are not ranges on the page", p$id)
    }
    p
  }
  element_view <- function(e) {
    data.frame(id = e$id, tag = e$tag, leaf = e$leaf, panel = e$panel,
               cx = round((e$x0 + e$x1) / 2, 2), cy = round((e$y0 + e$y1) / 2, 2),
               fill = e$fill, text = e$text, stringsAsFactors = FALSE)
  }
  table_names <- names(fig$tables %||% list())

  tools <- list(
    overview = list(
      description = "The figure, panels, scales and table summaries.",
      params = list(),
      run = function(a) {
        tables <- lapply(fig$tables, function(t) tool_table_description(t, disclose))
        panels <- sub$panels[intersect(c("id", "key", "x0", "y0", "x1", "y1", "x_type", "x_min", "x_max",
                                         "y_type", "y_min", "y_max", "flipped"), names(sub$panels))]
        list(engine = fig$meta$engine, width_pt = fig$meta$width * 72, height_pt = fig$meta$height * 72,
             elements = nrow(elements), leaves = nrow(sub$leaves), panels = panels,
             tables = unname(tables), disclosure = disclose)
      }),
    tree = list(
      description = "A deterministic structure or data tree.",
      params = list(view = list("string", "structure or data")),
      run = function(a) {
        if (!a$view %in% c("structure", "data")) stop_tool("view must be structure or data")
        tr <- gl_tree(fig, a$view)
        list(view = tr$view, nodes = utils::head(tr$nodes, 200L), edges = utils::head(tr$edges, 400L))
      }),
    list_elements = list(
      description = "Elements filtered by leaf, panel, tag or role.",
      params = list("where?" = list(type = "any")),
      run = function(a) {
        out <- elements
        where <- a$where %||% list()
        for (nm in names(where)) {
          if (nm %in% names(out)) out <- out[out[[nm]] %in% where[[nm]], , drop = FALSE]
          else if (nm == "role") {
            roles <- gl_classify(fig, "element")
            out <- out[out$id %in% roles$element[roles$role %in% where[[nm]]], , drop = FALSE]
          } else stop_tool("unknown element filter '%s'", nm)
        }
        utils::head(element_view(out), tool_row_limit)
      }),
    find_elements = list(
      description = "The elements drawn at a point of the page, topmost first.",
      params = list(x = list("number", "horizontal position, pt"), y = list("number", "vertical position, pt")),
      run = function(a) utils::head(element_view(gl_hit(fig, a$x, a$y, tolerance = 1)), tool_row_limit)),
    get_element = list(
      description = "One element with its leaf and panel.",
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
      description = "The checked table row an element draws.",
      params = list(element = list("string", "element id")),
      run = function(a) {
        require_disclosure("rows", "binding rows")
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
        list(element = e$id, bound = TRUE, table = b$table, row = b$row,
             rows_in_group = b$n_rows, status = b$status)
      }),
    describe_table = list(
      description = "A table's columns, types, ranges and bounded summaries.",
      params = list(table = list("string", "table name")),
      run = function(a) {
        if (!a$table %in% table_names) stop_tool("no table '%s' in the figure", quoted(a$table))
        tool_table_description(fig$tables[[a$table]], disclose)
      }),
    get_rows = list(
      description = sprintf("Rows of a table by row number, at most %d.", tool_row_limit),
      params = list(table = list("string", "table name"), rows = list("integers", "row numbers")),
      run = function(a) {
        t <- table_data(a$table, rows = TRUE)
        r <- as.integer(unlist(a$rows))
        if (!length(r) || length(r) > tool_row_limit) stop_tool("between 1 and %d rows can be read at once", tool_row_limit)
        if (anyNA(r) || any(r < 1L | r > nrow(t$data))) stop_tool("the rows are not all in the table (%d rows)", nrow(t$data))
        cbind(row = r, tool_rows(t$data[r, , drop = FALSE]))
      }),
    find_rows = list(
      description = "The five rows of built data nearest to given data values in a panel.",
      params = list(table = list("string", "table name"), panel = list("string", "panel id"),
                    x = list("number", "horizontal data value"), y = list("number", "vertical data value")),
      run = function(a) {
        t <- table_data(a$table, rows = TRUE)
        if (!identical(t$role, "built")) stop_tool("'%s' is not a layer's built data", t$name)
        p <- panel_row(a$panel)
        d <- t$data; k <- seq_len(nrow(d))
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
      description = "The data values at a point of a panel.",
      params = list(panel = list("string", "panel id"), x = list("number", "horizontal position, pt"),
                    y = list("number", "vertical position, pt")),
      run = function(a) {
        p <- panel_row(a$panel); v <- gl_to_data(fig, p$id, a$x, a$y)
        list(panel = p$id, x = signif(v$x, 8), y = signif(v$y, 8),
             note = if (isTRUE(p$flipped)) "this panel is flipped" else NULL)
      }),
    get_code = list(
      description = "The plotting code context when it was captured.",
      params = list(),
      run = function(a) {
        require_disclosure("rows", "plotting code")
        tool_context_view(fig, "code", disclose)
      }),
    get_context = list(
      description = "Captured context such as code, data, engine, document and environment.",
      params = list("item?" = list(type = "string")),
      run = function(a) tool_context_view(fig, a$item %||% NULL, disclose)),
    records = list(
      description = "Records from layers the stage is allowed to read.",
      params = list("layer?" = list(type = "string"), "status?" = list(type = "string")),
      run = function(a) {
        layer <- a$layer %||% NULL
        if (!is.null(layer) && !layer %in% allowed_layers) stop_tool("layer '%s' is not readable by this stage", layer)
        layer <- layer %||% allowed_layers
        rows <- gl_records(fig, layer = layer, status = a$status %||% NULL)
        tool_record_view(rows, disclose)
      }),
    resolve = list(
      description = "List conflicts and submit a rationale-bearing resolution candidate.",
      params = list("conflict?" = list(type = "array", items = "string"),
                    "keep?" = list(type = "array", items = "string"),
                    "rationale?" = list(type = "string"), "evidence?" = list(type = "any")),
      run = function(a) {
        if (is.null(a$conflict)) return(gl_conflicts(fig))
        if (is.null(state$review_conflicts)) stop_tool("no conflicts are available for review")
        result <- agent_validate_resolution(fig, state, a$conflict, a$keep, a$rationale, a$evidence %||% NULL)
        agent_store_candidate(state, result)
        result[c("outcome", "stage", "reasons")]
      }),
    check = list(
      description = "Run a registered closed check on a built table.",
      params = list(table = list("string", "table name"), kind = list("string", "check name"),
                    "args?" = list(type = "any")),
      run = function(a) {
        require_disclosure("summary", "semantic checks")
        t <- table_data(a$table)
        if (is.null(gl_plugin("check", a$kind, must_exist = FALSE))) stop_tool("no check '%s'", a$kind)
        out <- gl_check(t$data, a$kind, a$args %||% list())
        if (!tool_requires(disclose, "rows")) out$evidence <- NULL
        out
      }),
    test_binding = list(
      description = "Check a proposed element-to-row binding without writing the figure.",
      params = list(element = list("string", "element id"), table = list("string", "table name"),
                    row = list("integer", "row number")),
      run = function(a) {
        require_disclosure("summary", "binding checks")
        r <- check_proposal(ctx, list(kind = "binding", element = a$element, table = a$table, row = a$row))
        r[c("outcome", "stage", "reasons", "record")]
      }),
    repair = list(
      description = "Submit an explicit repair or retraction for an invalid record.",
      params = list(target_id = list("string", "invalid record id"), action = list("string", "revise or retract"),
                    "anchor?" = list(type = "any"), "body?" = list(type = "any")),
      run = function(a) {
        result <- agent_validate_repair(fig, state, a$target_id, a$action, a$anchor %||% NULL, a$body %||% NULL)
        agent_store_candidate(state, result)
        result[c("outcome", "stage", "reasons")]
      }),
    propose = list(
      description = "Submit a checked record candidate. Binding stages use element, table and row.",
      params = if (identical(stage_info$name %||% "", "bind") || is.null(stage_info)) {
        list(element = list("string", "element id"), table = list("string", "table name"), row = list("integer", "row number"))
      } else {
        list(layer = list("string", "record layer"), anchor = list(type = "any"), body = list(type = "any"),
             "depends_on?" = list(type = "array", items = "string"))
      },
      run = function(a) {
        if (identical(stage_info$name %||% "", "bind") || is.null(stage_info)) {
          require_disclosure("summary", "binding proposals")
          r <- check_proposal(ctx, list(kind = "binding", element = a$element, table = a$table, row = a$row))
          state$proposals[[length(state$proposals) + 1L]] <- c(
            list(proposal = list(element = a$element, table = a$table, row = a$row)), unclass(r))
          out <- list(outcome = r$outcome)
          if (length(r$reasons)) out$reasons <- as.list(r$reasons)
          if (!is.null(r$record)) out$status <- r$record$status
          if (!is.null(r$record) && isFALSE(r$record$layer_known)) {
            out$note <- "checked by place only: the figure does not say which layer drew this element"
          }
          out
        } else {
          result <- agent_validate_record_proposal(fig, state, a)
          agent_store_candidate(state, result)
          out <- result[c("outcome", "stage", "reasons")]
          if (!is.null(result$record)) out$status <- result$record$status
          out
        }
      })
  )

  schema_of <- function(params) {
    lapply(params, function(p) {
      if (is.list(p) && !is.null(p$type)) return(p)
      switch(p[[1]],
             integers = list(type = "array", items = "integer", min = 1),
             strings = list(type = "array", items = "string", min = 1),
             p[[1]])
    })
  }
  run <- function(name, args = list()) {
    note <- function(ok, text) {
      state$calls[[length(state$calls) + 1L]] <- list(tool = name, args = args, ok = ok,
                                                       result = substr(text, 1L, 700L))
      text
    }
    spec <- if (is_string(name)) tools[[name]] else NULL
    if (is.null(spec)) return(note(FALSE, tool_json(list(error = "no such tool"))))
    require <- tryCatch(require_tool(name), error = function(e) e)
    if (inherits(require, "error")) return(note(FALSE, tool_json(list(error = conditionMessage(require)))))
    args <- if (length(args)) as.list(args) else stats::setNames(list(), character())
    problems <- gl_schema_validate(args, schema_of(spec$params))
    if (length(problems)) return(note(FALSE, tool_json(list(error = as.list(problems)))))
    out <- tryCatch(spec$run(args), error = function(e) structure(conditionMessage(e), class = "tool_error"))
    if (inherits(out, "tool_error")) return(note(FALSE, tool_json(list(error = substr(unclass(out), 1L, 400L)))))
    note(TRUE, tool_json(out))
  }
  visible_tools <- if (is.null(stage_info)) default_tools else intersect(stage_info$tools, names(tools))
  list(names = visible_tools, tools = tools, run = run, state = state,
       stage = stage_info$name %||% NULL, disclose = disclose)
}

#' Tools for an agent over one figure
#'
#' The default form keeps the binding-only API from M3. Supplying `stage`
#' restricts tools and record layers to that stage and applies a disclosure
#' level of `none`, `schema`, `summary` or `rows`.
#'
#' @param fig A `gloss_figure`.
#' @param hide Leaf ids whose bindings `get_binding` does not disclose.
#' @param stage Optional registered stage name.
#' @param disclose Disclosure level for a stage.
#' @param state Optional internal stage state created for a registered stage.
#' @return A list of `aisdk` tools. [gl_tool_state()] gives what happened.
#' @export
gl_tools <- function(fig, hide = NULL, stage = NULL, disclose = NULL, state = NULL) {
  if (!requireNamespace("aisdk", quietly = TRUE)) {
    cli::cli_abort(c("{.fn gl_tools} needs the {.pkg aisdk} package.",
                     i = "Use the internal tool_specs() factory for offline tests."))
  }
  specs <- tool_specs(fig, hide = hide, stage = stage, disclose = disclose, state = state)
  z <- function(p) {
    if (is.list(p) && !is.null(p$type)) return(aisdk::z_any(p$description %||% NULL))
    switch(p[[1]],
      any = aisdk::z_any(p[[2]]),
      number = aisdk::z_number(p[[2]]),
      string = aisdk::z_string(p[[2]]),
      integer = aisdk::z_integer(p[[2]]),
      integers = aisdk::z_array(aisdk::z_integer(), p[[2]]),
      strings = aisdk::z_array(aisdk::z_string(), p[[2]])
    )
  }
  tools <- lapply(specs$names, function(nm) {
    spec <- specs$tools[[nm]]
    params <- if (length(spec$params)) {
      values <- lapply(spec$params, z)
      names(values) <- sub("[?]$", "", names(values))
      required <- names(values)[!grepl("[?]$", names(spec$params))]
      do.call(aisdk::z_object, c(values, list(.required = required)))
    } else aisdk::z_empty_object()
    aisdk::tool(name = nm, description = spec$description, parameters = params,
                execute = function(...) specs$run(nm, list(...)))
  })
  attr(tools, "gloss_tool_state") <- specs$state
  tools
}

#' What happened through a figure's tools
#'
#' @param tools Tools made by [gl_tools()].
#' @return A list containing tool calls, proposals, candidates and stage metadata.
#' @export
gl_tool_state <- function(tools) {
  state <- attr(tools, "gloss_tool_state")
  if (!is.environment(state)) cli::cli_abort("{.arg tools} were not made by {.fn gl_tools}.")
  list(calls = state$calls, proposals = state$proposals,
       candidates = state$candidates %||% list(), stage = state$stage %||% NULL,
       disclose = state$disclose %||% NULL)
}
