# Fixed-model agent arm.  The model receives public facts and has two tools:
# run_analysis (inside the persistent sandbox) and submit_proposal (the host
# checker).  The proposal tool accepts data only.  No model output is ever
# evaluated as R code outside the sandbox.

source("bench/agent/binding-modes.R")
source("bench/agent/sandbox.R")

binding_agent_system <- paste(
  "You are a binding analyst. Read only the supplied public material.",
  "Use run_analysis to inspect CSV tables, facts.json and the SVG. The analysis",
  "process can write scratch files but cannot access the hidden oracle.",
  "When ready, call submit_proposal with a single JSON-like proposal using DSL",
  "version 0.1.0. Do not include R expressions, URLs, HTML, JavaScript or",
  "numbers that are not present in the material. A proposal is not accepted",
  "until submit_proposal reports accepted. If the row or geometry cannot be",
  "verified, submit one fixed none reason."
)

binding_agent_tools <- function() {
  list(
    list(type = "function", `function` = list(
      name = "run_analysis",
      description = "Run read-only R analysis against /material and scratch /work.",
      parameters = list(type = "object", properties = list(code = list(type = "string")), required = list("code")))),
    list(type = "function", `function` = list(
      name = "submit_proposal",
      description = "Submit one restricted binding proposal to the independent checker.",
      parameters = list(type = "object", properties = list(proposal = list(type = "object")), required = list("proposal"))))
  )
}

binding_chat_request <- function(messages, tools, model_id, gateway, timeout = 180L) {
  payload <- jsonlite::toJSON(list(model = model_id, messages = messages, temperature = 0,
                                   tools = tools), auto_unbox = TRUE, null = "null", digits = NA)
  h <- curl::new_handle()
  curl::handle_setheaders(h, Authorization = paste("Bearer", Sys.getenv("ANTHROPIC_AUTH_TOKEN", "local")),
                          `Content-Type` = "application/json")
  curl::handle_setopt(h, copypostfields = payload, timeout = timeout)
  response <- tryCatch(curl::curl_fetch_memory(paste0(gateway, "/chat/completions"), handle = h), error = function(e) e)
  if (inherits(response, "error")) return(list(error = conditionMessage(response)))
  text <- rawToChar(response$content); Encoding(text) <- "UTF-8"
  parsed <- tryCatch(jsonlite::fromJSON(text, simplifyVector = FALSE), error = function(e) NULL)
  if (response$status_code != 200L || is.null(parsed$choices[[1L]]$message)) {
    return(list(error = sprintf("HTTP %d: %s", response$status_code, substr(text, 1L, 500L))))
  }
  list(message = parsed$choices[[1L]]$message, usage = parsed$usage %||% list())
}

binding_agent_public_prompt <- function(facts) {
  jsonlite::toJSON(list(version = binding_dsl_version, facts = facts), auto_unbox = TRUE,
                   null = "null", na = "null", dataframe = "rows", digits = NA)
}

binding_agent_parse_proposal <- function(x) {
  if (is.character(x) && length(x) == 1L) {
    y <- tryCatch(jsonlite::fromJSON(x, simplifyVector = FALSE), error = function(e) NULL)
    if (is.null(y)) return(NULL)
    return(y)
  }
  x
}

binding_agent_run <- function(material, model_id = Sys.getenv("GLOSS_BINDING_MODEL", "auto/glm-5.3-flash"),
                              gateway = Sys.getenv("GLOSS_BINDING_GATEWAY", "http://127.0.0.1:3425/v1"),
                              timeout = 180L, max_steps = 8L, dry = FALSE) {
  public <- file.path(material$dir, "public")
  sandbox_env <- material$facts$environment
  if (is.null(sandbox_env) || !length(sandbox_env) || is.na(sandbox_env[1L])) {
    source_meta <- file.path(material$dir, "public", "source-meta.json")
    source_environment <- tryCatch(jsonlite::read_json(source_meta, simplifyVector = FALSE)$environment$name,
                                    error = function(e) NULL)
    sandbox_env <- source_environment %||% "cran"
  }
  if (!sandbox_env %in% c("cran", "bioc")) sandbox_env <- "cran"
  sb <- sandbox_open_persistent(public, env = sandbox_env)
  on.exit(sandbox_close_persistent(sb), add = TRUE)
  calls <- list(); proposals <- list(); usage <- list(prompt_tokens = 0, completion_tokens = 0, total_tokens = 0)
  if (isTRUE(dry)) {
    analysis <- run_analysis(sb, "f <- list.files('/material', recursive = TRUE); cat(paste(f, collapse = '\\n'))", timeout = 30)
    calls[[1L]] <- list(tool = "run_analysis", args = list(code = "public file inventory"), result = analysis)
    if (!identical(analysis$public_hash_before, analysis$public_hash_after)) {
      return(list(outcome = "operational_failure", model = "dry", text = "", calls = calls,
                  proposals = proposals, usage = usage, seconds = analysis$seconds,
                  failure = "public material hash changed during analysis", sandbox_calls = sb$calls,
                  sandbox_resets = sb$resets))
    }
    enum <- binding_enumeration_arm(material, max_candidates = as.integer(Sys.getenv("GLOSS_BINDING_MAX_CANDIDATES", "2000")))
    accepted <- Filter(function(x) identical(x$outcome, "accepted"), enum$traces)
    if (length(accepted)) {
      proposal <- accepted[[1L]]$proposal
      checked <- binding_checker(material$dir, proposal)
      proposals[[1L]] <- checked
      calls[[2L]] <- list(tool = "submit_proposal", args = list(proposal = proposal), result = checked)
    } else {
      proposal <- binding_fixed_proposal(as.character(material$facts$leaves$id[1L]), binding_none_reasons[1L])
      checked <- binding_checker(material$dir, proposal)
      proposals[[1L]] <- checked
      calls[[2L]] <- list(tool = "submit_proposal", args = list(proposal = proposal), result = checked)
    }
    return(list(outcome = checked$outcome, model = "dry", text = "", calls = calls, proposals = proposals,
                usage = usage, seconds = NA_real_, sandbox_calls = sb$calls, sandbox_resets = sb$resets))
  }
  if (!nzchar(Sys.getenv("ANTHROPIC_AUTH_TOKEN"))) {
    return(list(outcome = "operational_failure", model = model_id, text = "",
                calls = calls, proposals = proposals, usage = usage, seconds = 0,
                failure = "ANTHROPIC_AUTH_TOKEN is absent", sandbox_calls = 0L, sandbox_resets = 0L))
  }
  security_failure <- FALSE
  messages <- list(list(role = "system", content = binding_agent_system),
                   list(role = "user", content = binding_agent_public_prompt(material$facts)))
  started <- Sys.time(); finish <- ""; text <- ""
  for (step in seq_len(max_steps)) {
    response <- binding_chat_request(messages, binding_agent_tools(), model_id, gateway, timeout)
    if (!is.null(response$error)) {
      finish <- "request_error"
      return(list(outcome = "operational_failure", model = model_id, text = "", calls = calls,
                  proposals = proposals, usage = usage, seconds = as.numeric(difftime(Sys.time(), started, units = "secs")),
                  failure = response$error, finish = finish, sandbox_calls = sb$calls, sandbox_resets = sb$resets))
    }
    for (nm in names(usage)) usage[[nm]] <- as.numeric(usage[[nm]] %||% 0) + as.numeric(response$usage[[nm]] %||% 0)
    message <- response$message
    tool_calls <- message$tool_calls %||% list()
    if (!length(tool_calls)) {
      finish <- "stop"
      text <- as.character(message$content %||% "")
      break
    }
    assistant_calls <- lapply(tool_calls, function(x) list(id = x$id, type = "function",
                                                             `function` = list(name = x$`function`$name,
                                                                               arguments = x$`function`$arguments %||% "{}")))
    messages[[length(messages) + 1L]] <- list(role = "assistant", content = message$content %||% "",
                                               tool_calls = assistant_calls)
    for (x in tool_calls) {
      fn <- x$`function`$name %||% ""
      args <- tryCatch(jsonlite::fromJSON(x$`function`$arguments %||% "{}", simplifyVector = FALSE), error = function(e) list())
      result <- if (identical(fn, "run_analysis")) {
        run_analysis(sb, as.character(args$code %||% ""), timeout = 60L)
      } else if (identical(fn, "submit_proposal")) {
        proposal <- binding_agent_parse_proposal(args$proposal)
        checked <- if (is.null(proposal)) list(outcome = "rejected", reports = binding_reason_row("schema", FALSE, "proposal is not an object")) else binding_checker(material$dir, proposal)
        proposals[[length(proposals) + 1L]] <- checked
        checked
      } else list(outcome = "rejected", reports = binding_reason_row("schema", FALSE, "unknown tool"))
      if (identical(fn, "run_analysis") && !identical(result$public_hash_before, result$public_hash_after)) {
        security_failure <- TRUE
        result$security_failure <- TRUE
      }
      calls[[length(calls) + 1L]] <- list(tool = fn, args = args, result = result)
      messages[[length(messages) + 1L]] <- list(role = "tool", tool_call_id = x$id,
                                                 content = jsonlite::toJSON(result, auto_unbox = TRUE, null = "null", dataframe = "rows"))
    }
  }
  accepted <- Filter(function(x) identical(x$outcome, "accepted"), proposals)
  outcomes <- unique(vapply(proposals, function(x) x$outcome %||% "operational_failure", ""))
  outcome <- if (security_failure) "operational_failure" else if (length(accepted) > 1L) "ambiguous" else if (length(accepted) == 1L) "accepted" else if ("none" %in% outcomes) "none" else if (length(proposals)) "refused" else "operational_failure"
  list(outcome = outcome, model = model_id, text = text %||% "", calls = calls, proposals = proposals,
       usage = usage, seconds = as.numeric(difftime(Sys.time(), started, units = "secs")), finish = finish,
       sandbox_calls = sb$calls, sandbox_resets = sb$resets)
}
