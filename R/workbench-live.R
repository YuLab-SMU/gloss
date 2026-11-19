# Local live gloss Workbench server (optional `httpuv`).
# Serves the exact same single-file workbench UI connected to the active R
# session so users can propose checked records, dry-run gl_check(), and attach
# external context live.

live_json_response <- function(obj, status = 200L) {
  body <- json_write(obj, pretty = FALSE)
  list(
    status = as.integer(status),
    headers = list(
      "Content-Type" = "application/json; charset=utf-8",
      "Cache-Control" = "no-store"
    ),
    body = body
  )
}

read_req_body <- function(req) {
  inp <- req[["rook.input"]]
  if (is.null(inp)) return("")
  if (is.character(inp)) return(paste(inp, collapse = ""))
  if ((is.environment(inp) || is.list(inp)) && is.function(inp$read)) {
    raw <- inp$read()
    if (is.raw(raw)) {
      s <- rawToChar(raw)
      Encoding(s) <- "UTF-8"
      return(s)
    }
    return(paste(as.character(raw), collapse = ""))
  }
  ""
}

workbench_live_bundle_payload <- function(fig, embed = "all") {
  list(
    format = "gloss-bundle-embed",
    format_version = bundle_format_version,
    encoding = "zlib+base64",
    packing = "u32-length-prefixed files",
    embed = embed,
    payload = pack_files(bundle_files(fig, embed))
  )
}

workbench_live_html <- function(fig, mode = "full", view = "reader", theme = "paper",
                                initial_stage = NULL, title = NULL,
                                template = NULL, embed = "all") {
  tmp <- tempfile("gloss-live-", fileext = ".html")
  on.exit(unlink(tmp), add = TRUE)
  write_workbench(
    fig = fig, path = tmp, embed = embed, mode = mode, view = view, theme = theme,
    initial_stage = initial_stage, title = title, template = template
  )
  txt <- read_workbench_template(tmp)
  live_tag <- "<script>window.__GLOSS_LIVE_API__={baseUrl:\"\"};</script>\n</body>"
  sub("</body>", live_tag, txt, fixed = TRUE)
}

workbench_live_handler <- function(state) {
  function(req) {
    method <- toupper(req$REQUEST_METHOD %||% "GET")
    path <- req$PATH_INFO %||% "/"

    if (identical(method, "GET") && (identical(path, "/") || identical(path, "/index.html"))) {
      html <- workbench_live_html(
        state$fig, mode = state$mode, view = state$view %||% "reader", theme = state$theme,
        initial_stage = state$initial_stage, title = state$title,
        template = state$template, embed = state$embed
      )
      return(list(
        status = 200L,
        headers = list("Content-Type" = "text/html; charset=utf-8", "Cache-Control" = "no-store"),
        body = html
      ))
    }

    if (identical(method, "GET") && identical(path, "/api/status")) {
      fig <- state$fig
      return(live_json_response(list(
        ok = TRUE,
        live = TRUE,
        gloss_version = gloss_version(),
        substrate_id = fig$meta$id %||% NA_character_,
        engine = fig$meta$engine %||% NA_character_,
        n_elements = nrow(fig$substrate$elements),
        n_records = nrow(gl_records(fig)),
        tables = names(fig$tables),
        checks = gl_plugins("check")$name,
        layers = names(fig$layers %||% list())
      )))
    }

    if (identical(method, "GET") && identical(path, "/api/bundle")) {
      return(live_json_response(workbench_live_bundle_payload(state$fig, embed = state$embed)))
    }

    if (identical(method, "POST") && identical(path, "/api/propose")) {
      raw_body <- read_req_body(req)
      payload <- tryCatch(jsonlite::fromJSON(raw_body, simplifyVector = FALSE), error = function(e) NULL)
      if (is.null(payload) || !is.list(payload)) {
        return(live_json_response(list(ok = FALSE, error = "Invalid JSON request body."), 400L))
      }
      layer <- payload$layer
      anchor <- payload$anchor
      body <- payload$body %||% list()
      by <- payload$by %||% "workbench-user"
      depends_on <- as.character(unlist(payload$depends_on %||% character()))

      res <- tryCatch({
        updated <- gl_record(state$fig, layer = layer, anchor = anchor, body = body,
                             by = by, depends_on = depends_on)
        state$fig <- updated
        recs <- gl_records(updated, layer = layer)
        last_rec <- if (nrow(recs)) recs[nrow(recs), c("id", "layer", "status", "anchor_status", "check_status")] else NULL
        list(
          ok = TRUE,
          record = last_rec,
          bundle = workbench_live_bundle_payload(updated, embed = state$embed)
        )
      }, error = function(e) {
        list(ok = FALSE, error = cli::ansi_strip(conditionMessage(e)))
      })
      return(live_json_response(res, if (isTRUE(res$ok)) 200L else 422L))
    }

    if (identical(method, "POST") && identical(path, "/api/check")) {
      raw_body <- read_req_body(req)
      payload <- tryCatch(jsonlite::fromJSON(raw_body, simplifyVector = FALSE), error = function(e) NULL)
      if (is.null(payload) || !is.list(payload)) {
        return(live_json_response(list(ok = FALSE, error = "Invalid JSON request body."), 400L))
      }
      tbl_name <- as.character(payload$table %||% "")[1L]
      tbl <- state$fig$tables[[tbl_name]]$data
      if (is.null(tbl)) {
        return(live_json_response(list(ok = FALSE, error = sprintf("Table '%s' is not available.", tbl_name)), 404L))
      }
      res <- tryCatch({
        chk <- gl_check(tbl, kind = as.character(payload$kind)[1L], args = payload$args %||% list())
        list(ok = TRUE, check = chk)
      }, error = function(e) {
        list(ok = FALSE, error = cli::ansi_strip(conditionMessage(e)))
      })
      return(live_json_response(res, if (isTRUE(res$ok)) 200L else 422L))
    }

    if (identical(method, "POST") && identical(path, "/api/context")) {
      raw_body <- read_req_body(req)
      payload <- tryCatch(jsonlite::fromJSON(raw_body, simplifyVector = FALSE), error = function(e) NULL)
      if (is.null(payload) || !is.list(payload)) {
        return(live_json_response(list(ok = FALSE, error = "Invalid JSON request body."), 400L))
      }
      res <- tryCatch({
        updated <- gl_add_context(
          state$fig,
          item = payload$item,
          value = payload$value,
          source = payload$source %||% NULL,
          source_type = payload$source_type %||% NULL,
          by = payload$by %||% "workbench-user"
        )
        state$fig <- updated
        list(ok = TRUE, bundle = workbench_live_bundle_payload(updated, embed = state$embed))
      }, error = function(e) {
        list(ok = FALSE, error = cli::ansi_strip(conditionMessage(e)))
      })
      return(live_json_response(res, if (isTRUE(res$ok)) 200L else 422L))
    }

    live_json_response(list(ok = FALSE, error = sprintf("Not found: %s %s", method, path)), 404L)
  }
}

#' Serve a live browser gloss Workbench connected to the current R session
#'
#' Starts a local `httpuv` HTTP server bound to `127.0.0.1` so the browser
#' Workbench can propose semantic records through [gl_record()], dry-run
#' [gl_check()], and attach external context via [gl_add_context()] live.
#' Requires the optional `httpuv` package.
#'
#' @param fig A `gloss_figure`.
#' @param host Bind address. Defaults to `"127.0.0.1"` (localhost only).
#' @param port Port number, or `NULL` to pick a free local port automatically.
#' @param embed Data embedding policy for bundles sent to the browser.
#' @param mode `"full"` or `"lite"`.
#' @param view Initial view mode (`"reader"` or `"inspector"`).
#' @param theme Initial theme (`"paper"` or `"obsidian"`).
#' @param initial_stage Optional initial semantic stage.
#' @param title Optional page title.
#' @param template Optional custom workbench shell path.
#' @param open Open the local URL in the default browser.
#' @return A `gloss_workbench_server` handle with `$url`, `$fig()` (returns the
#'   latest updated `gloss_figure`), and `$stop()`.
#' @export
gl_workbench_serve <- function(fig,
                               host = "127.0.0.1",
                               port = NULL,
                               embed = c("all", "default", "summary", "none"),
                               mode = c("full", "lite"),
                               view = c("reader", "inspector"),
                               theme = c("paper", "obsidian"),
                               initial_stage = NULL,
                               title = NULL,
                               template = NULL,
                               open = interactive()) {
  check_figure(fig)
  if (!requireNamespace("httpuv", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.fn gl_workbench_serve} requires the optional {.pkg httpuv} package.",
      i = "Install it with `install.packages(\"httpuv\")`, or use `gl_workbench()` for a static single-file HTML."
    ))
  }
  embed <- match.arg(embed)
  mode <- match.arg(mode)
  view <- match.arg(view)
  theme <- match.arg(theme)

  state <- new.env(parent = emptyenv())
  state$fig <- fig
  state$embed <- embed
  state$mode <- mode
  state$view <- view
  state$theme <- theme
  state$initial_stage <- initial_stage
  state$title <- title %||% fig$context$doc$value$caption %||% "Live gloss figure"
  state$template <- template

  chosen_port <- if (is.null(port)) httpuv::randomPort(host = host) else as.integer(port)
  srv <- httpuv::startServer(host, chosen_port, list(call = workbench_live_handler(state)))
  url <- sprintf("http://%s:%d/", host, chosen_port)
  if (isTRUE(open)) utils::browseURL(url)

  structure(
    list(
      url = url,
      host = host,
      port = chosen_port,
      fig = function() state$fig,
      stop = function() {
        httpuv::stopServer(srv)
        invisible(state$fig)
      }
    ),
    class = "gloss_workbench_server"
  )
}

#' @export
print.gloss_workbench_server <- function(x, ...) {
  cat(sprintf("<gloss workbench server> %s\n", x$url))
  cat("  Use $fig() to retrieve the updated gloss_figure, and $stop() to shut down.\n")
  invisible(x)
}
