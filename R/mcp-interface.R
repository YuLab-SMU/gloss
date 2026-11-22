# A transport-neutral MCP-shaped interface for external agents.
#
# gloss keeps the figure substrate and checked write path independent of a
# model SDK. This file translates the existing stage-scoped tools to the MCP
# tool vocabulary. A host can use the R session directly or forward these
# results through stdio, Streamable HTTP or another MCP transport.

mcp_protocol_versions <- c("2026-07-28", "2025-11-25")

mcp_schema_for_param <- function(param) {
  if (is.list(param) && !is.null(param$type)) {
    out <- param
    if (identical(out$type, "any")) return(list())
    if (is.character(out$items) && length(out$items) == 1L) {
      out$items <- list(type = out$items)
    }
    return(out)
  }
  if (is.character(param) && length(param) == 1L) {
    return(list(type = param))
  }
  if (is.character(param) && length(param) > 1L) {
    return(list(type = "string", enum = param))
  }
  if (is.list(param) && length(param) >= 1L) {
    type <- as.character(param[[1L]])[1L]
    description <- if (length(param) >= 2L) as.character(param[[2L]])[1L] else NULL
    out <- list(type = switch(type, integers = "array", strings = "array", type))
    if (type == "integers") out$items <- list(type = "integer")
    if (type == "strings") out$items <- list(type = "string")
    if (!is.null(description) && nzchar(description)) out$description <- description
    return(out)
  }
  list()
}

mcp_tool_definitions <- function(session) {
  specs <- session$specs
  lapply(specs$names, function(name) {
    spec <- specs$tools[[name]]
    params <- spec$params %||% list()
    fields <- lapply(params, mcp_schema_for_param)
    required <- names(params)[!grepl("[?]$", names(params))]
    names(fields) <- sub("[?]$", "", names(fields))
    schema <- list(type = "object", properties = fields)
    if (length(required)) schema$required <- required
    list(name = name, description = spec$description %||% "gloss tool",
         inputSchema = schema)
  })
}

#' Create a model-independent MCP tool session
#'
#' The session owns a figure value and a stage-scoped tool state. It can be
#' passed to gl_mcp_tools() and gl_mcp_call() by an external agent adapter.
#' No model SDK is loaded by this interface.
#'
#' @param fig A gloss_figure.
#' @param stage Registered stage whose read and write capabilities are exposed.
#' @param disclose Disclosure level for the external agent.
#' @param metadata Optional provenance fields recorded when a proposal commits.
#' @return A gloss_mcp_session.
#' @export
gl_mcp_session <- function(fig, stage = "meaning", disclose = NULL, metadata = list()) {
  check_figure(fig)
  stage <- as.character(stage)[1L]
  plugin <- stage_plugin_info(stage)
  level <- disclose %||% plugin$disclose
  level <- match.arg(level, agent_disclosure_levels)
  state <- agent_stage_state(fig, stage, disclose = level, metadata = metadata)
  specs <- tool_specs(fig, stage = stage, disclose = level, state = state)
  structure(list(fig = fig, stage = stage, disclose = level, state = state, specs = specs),
            class = c("gloss_mcp_session", "list"))
}

#' List MCP tools for an external agent
#'
#' @param session A gloss_mcp_session.
#' @return A list of MCP tool definitions with JSON schemas.
#' @export
gl_mcp_tools <- function(session) {
  if (!inherits(session, "gloss_mcp_session")) {
    cli::cli_abort("{.arg session} must be a {.cls gloss_mcp_session}.")
  }
  mcp_tool_definitions(session)
}

mcp_write_tools <- c("propose", "resolve", "repair")

#' Call one MCP tool without a model SDK
#'
#' Read-only calls return the tool result. A checked propose, resolve or
#' repair is committed immediately through the same stage commit used by the
#' optional aisdk runner. The returned session contains the updated figure and
#' can be used for the next call.
#'
#' @param session A gloss_mcp_session.
#' @param name Tool name.
#' @param arguments Named JSON-like tool arguments.
#' @return A list with result, is_error and the updated session.
#' @export
gl_mcp_call <- function(session, name, arguments = list()) {
  if (!inherits(session, "gloss_mcp_session")) {
    cli::cli_abort("{.arg session} must be a {.cls gloss_mcp_session}.")
  }
  name <- as.character(name)[1L]
  raw <- session$specs$run(name, arguments)
  result <- tryCatch(jsonlite::fromJSON(raw, simplifyVector = FALSE), error = function(e) {
    list(error = conditionMessage(e))
  })
  is_error <- is.list(result) && !is.null(result$error)
  committed <- 0L
  if (!is_error && name %in% mcp_write_tools) {
    report <- stage_commit(session$fig, session$specs$state)
    committed <- length(report$committed %||% list())
    if (committed) session$fig <- report$fig
    session$specs$state$candidates <- list()
    session$specs <- tool_specs(session$fig, stage = session$stage,
                                disclose = session$disclose, state = session$specs$state)
    result$committed <- committed
    if (length(report$rejected %||% list())) result$commit_rejected <- length(report$rejected)
  }
  list(result = result, is_error = is_error, session = session)
}

mcp_jsonrpc_result <- function(id, result) {
  list(jsonrpc = "2.0", id = id, result = result)
}

mcp_jsonrpc_error <- function(id, code, message, data = NULL) {
  error <- list(code = as.integer(code), message = message)
  if (!is.null(data)) error$data <- data
  list(jsonrpc = "2.0", id = id, error = error)
}

mcp_server_info <- function() {
  list(name = "gloss", version = gloss_version())
}

mcp_header <- function(req, name) {
  key <- paste0("HTTP_", gsub("-", "_", toupper(name)))
  req[[key]] %||% req[[name]] %||% NULL
}

mcp_request_meta <- function(request) {
  params <- request$params %||% list()
  meta <- params[["_meta"]] %||% list()
  if (!is.list(meta)) list() else meta
}

mcp_decode_header_value <- function(value) {
  if (is.null(value) || !length(value)) return(NULL)
  value <- as.character(value)[1L]
  prefix <- "=?base64?"
  suffix <- "?="
  if (!startsWith(value, prefix) || !endsWith(value, suffix)) return(value)
  encoded <- substr(value, nchar(prefix) + 1L, nchar(value) - nchar(suffix))
  decoded <- tryCatch(rawToChar(jsonlite::base64_dec(encoded)), error = function(e) NULL)
  decoded %||% value
}

mcp_http_validation <- function(req, request, legacy = FALSE) {
  origin <- mcp_header(req, "Origin")
  if (!is.null(origin) && nzchar(origin) && !grepl(
    "^https?://(localhost|127\\.0\\.0\\.1|\\[::1\\])(?::[0-9]+)?$",
    origin, perl = TRUE
  )) {
    return(list(status = 403L,
                response = mcp_jsonrpc_error(NULL, -32020L, "Invalid Origin header.")))
  }

  meta <- mcp_request_meta(request)
  body_version <- meta[["io.modelcontextprotocol/protocolVersion"]] %||% NULL
  header_version <- mcp_header(req, "MCP-Protocol-Version")
  method <- as.character(request$method %||% "")[1L]
  method_header <- mcp_header(req, "Mcp-Method")
  name_header <- mcp_header(req, "Mcp-Name")
  has_modern_fields <- !is.null(body_version) || !is.null(header_version) ||
    !is.null(method_header) || !is.null(name_header)

  if (!has_modern_fields) {
    if (isTRUE(legacy) || identical(method, "initialize")) return(NULL)
    return(list(status = 400L,
                response = mcp_jsonrpc_error(request$id %||% NULL, -32020L,
                                             "Missing MCP request metadata.")))
  }

  if (is.null(body_version) || is.null(header_version) ||
      !identical(as.character(body_version)[1L], as.character(header_version)[1L])) {
    return(list(status = 400L,
                response = mcp_jsonrpc_error(request$id %||% NULL, -32020L,
                                             "MCP protocol version header does not match request metadata.")))
  }
  version <- as.character(body_version)[1L]
  if (!version %in% mcp_protocol_versions) {
    return(list(status = 400L,
                response = mcp_jsonrpc_error(
                  request$id %||% NULL, -32022L, "Unsupported protocol version.",
                  data = list(supported = mcp_protocol_versions, requested = version)
                )))
  }
  if (is.null(method_header) || !identical(as.character(method_header)[1L], method)) {
    return(list(status = 400L,
                response = mcp_jsonrpc_error(request$id %||% NULL, -32020L,
                                             "Mcp-Method header does not match request method.")))
  }
  if (identical(method, "tools/call")) {
    body_name <- as.character((request$params %||% list())$name %||% "")[1L]
    header_name <- mcp_decode_header_value(name_header)
    if (!nzchar(body_name) || is.null(name_header) || !identical(header_name, body_name)) {
      return(list(status = 400L,
                  response = mcp_jsonrpc_error(request$id %||% NULL, -32020L,
                                               "Mcp-Name header does not match the tool name.")))
    }
  }
  accept <- mcp_header(req, "Accept")
  if (is.null(accept) || !grepl("application/json", accept, fixed = TRUE) ||
      !grepl("text/event-stream", accept, fixed = TRUE)) {
    return(list(status = 400L,
                response = mcp_jsonrpc_error(request$id %||% NULL, -32020L,
                                             "Accept must include application/json and text/event-stream.")))
  }
  NULL
}

mcp_dispatch <- function(state, request) {
  id <- request$id %||% NULL
  method <- as.character(request$method %||% "")[1L]
  params <- request$params %||% list()
  if (!is.list(params)) params <- list()

  if (method == "initialize") {
    requested <- as.character(params$protocolVersion %||% "2025-11-25")[1L]
    version <- if (requested %in% mcp_protocol_versions) requested else "2025-11-25"
    stage <- params$stage %||% state$mcp_stage %||% "meaning"
    disclose <- params$disclose %||% state$mcp_disclose %||% NULL
    state$mcp_stage <- stage
    state$mcp_disclose <- disclose
    state$mcp_session <- gl_mcp_session(state$fig, stage = stage, disclose = disclose,
                                        metadata = list(by = "mcp-agent"))
    return(mcp_jsonrpc_result(id, list(protocolVersion = version,
                                       capabilities = list(tools = list(listChanged = FALSE)),
                                       serverInfo = mcp_server_info())))
  }
  if (method == "server/discover") {
    return(mcp_jsonrpc_result(id, list(
      resultType = "complete",
      supportedVersions = mcp_protocol_versions,
      protocolVersions = mcp_protocol_versions,
      capabilities = list(tools = list(listChanged = FALSE)),
      `_meta` = list(`io.modelcontextprotocol/serverInfo` = mcp_server_info()),
      instructions = "Use the task-scoped context packet before proposing a semantic record."
    )))
  }
  if (method == "notifications/initialized" || method == "notifications/cancelled") return(NULL)

  if (is.null(state$mcp_session)) {
    state$mcp_session <- gl_mcp_session(state$fig,
                                        stage = state$mcp_stage %||% "meaning",
                                        disclose = state$mcp_disclose %||% NULL,
                                        metadata = list(by = "mcp-agent"))
  }
  session <- state$mcp_session
  if (method == "tools/list") {
    return(mcp_jsonrpc_result(id, list(tools = gl_mcp_tools(session))))
  }
  if (method == "tools/call") {
    name <- params$name %||% ""
    if (!is_string(name) || !name %in% session$specs$names) {
      return(mcp_jsonrpc_error(id, -32602L, sprintf("Unknown tool '%s'.", name)))
    }
    call <- gl_mcp_call(session, name, params$arguments %||% list())
    state$mcp_session <- call$session
    state$fig <- call$session$fig
    text <- json_write(call$result, pretty = FALSE)
    return(mcp_jsonrpc_result(id, list(content = list(list(type = "text", text = text)),
                              isError = isTRUE(call$is_error),
                              structuredContent = call$result)))
  }
  mcp_jsonrpc_error(id, -32601L, sprintf("Method '%s' is not supported.", method))
}

mcp_http_handler <- function(state) {
  function(req) {
    method <- toupper(req$REQUEST_METHOD %||% "GET")
    path <- req$PATH_INFO %||% "/"
    if (!identical(method, "POST") || !path %in% c("/", "/mcp")) {
      return(list(status = 404L,
                  headers = list("Content-Type" = "application/json; charset=utf-8"),
                  body = json_write(mcp_jsonrpc_error(NULL, -32601L, "Use POST /mcp."), pretty = FALSE)))
    }
    raw_body <- read_req_body(req)
    payload <- tryCatch(jsonlite::fromJSON(raw_body, simplifyVector = FALSE), error = function(e) NULL)
    if (is.null(payload) || !is.list(payload)) {
      response <- mcp_jsonrpc_error(NULL, -32700L, "Invalid JSON request.")
      return(list(status = 400L,
                  headers = list("Content-Type" = "application/json; charset=utf-8"),
                  body = json_write(response, pretty = FALSE)))
    }
    validation <- mcp_http_validation(req, payload, legacy = isTRUE(state$mcp_legacy))
    if (!is.null(validation)) {
      return(list(status = validation$status,
                  headers = list("Content-Type" = "application/json; charset=utf-8",
                                 "Cache-Control" = "no-store"),
                  body = json_write(validation$response, pretty = FALSE)))
    }
    if (identical(payload$method, "initialize") &&
        is.null((payload$params %||% list())[["_meta"]])) {
      state$mcp_legacy <- TRUE
    }
    response <- tryCatch(mcp_dispatch(state, payload), error = function(e) {
      mcp_jsonrpc_error(payload$id %||% NULL, -32603L, cli::ansi_strip(conditionMessage(e)))
    })
    if (is.null(response)) return(list(status = 202L, headers = list(), body = ""))
    response_status <- if (!is.null(response$error) && identical(as.integer(response$error$code), -32601L)) 404L else 200L
    list(status = response_status,
         headers = list("Content-Type" = "application/json; charset=utf-8",
                        "Cache-Control" = "no-store"),
         body = json_write(response, pretty = FALSE))
  }
}

#' Serve gloss tools to an external agent over MCP-shaped HTTP
#'
#' This server exposes the same stage-scoped tool definitions as
#' gl_mcp_session() without starting a model loop or requiring aisdk. It is
#' useful when a user's agent supports MCP and the figure lives in an R
#' session. The /mcp body follows the JSON-RPC tool discovery and call
#' methods. Requires the optional httpuv package.
#'
#' @param fig A gloss_figure.
#' @param host Bind address. Defaults to "127.0.0.1".
#' @param port Port number, or NULL to pick a free local port.
#' @param stage Registered semantic stage exposed to the external agent.
#' @param disclose Disclosure level for the external agent.
#' @return A gloss_mcp_server handle with $url, $fig() and $stop().
#' @export
gl_mcp_serve <- function(fig, host = "127.0.0.1", port = NULL,
                         stage = "meaning", disclose = NULL) {
  check_figure(fig)
  if (!requireNamespace("httpuv", quietly = TRUE)) {
    cli::cli_abort("{.fn gl_mcp_serve} requires the optional {.pkg httpuv} package.")
  }
  state <- new.env(parent = emptyenv())
  state$fig <- fig
  state$mcp_stage <- stage
  state$mcp_disclose <- disclose
  chosen_port <- if (is.null(port)) httpuv::randomPort(host = host) else as.integer(port)
  srv <- httpuv::startServer(host, chosen_port, list(call = mcp_http_handler(state)))
  url <- sprintf("http://%s:%d/mcp", host, chosen_port)
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
    class = "gloss_mcp_server"
  )
}

#' @export
print.gloss_mcp_server <- function(x, ...) {
  cat(sprintf("<gloss MCP server> %s\n", x$url))
  cat("  Use $fig() to retrieve the updated gloss_figure, and $stop() to shut down.\n")
  invisible(x)
}
