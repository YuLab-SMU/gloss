# Optional aisdk orchestration. gloss supplies stage capabilities and validates
# every candidate. External agents can use the MCP interface without aisdk.

agent_stage_task <- function(stage, context = NULL) {
  prompt <- stage_plugin_info(stage)$prompt
  image <- if (is.list(context)) context$image %||% NULL else NULL
  if (!is.null(image)) {
    rest <- context
    rest$image <- NULL
    suffix <- if (length(rest)) paste0("\nTask context:\n", json_write(rest, pretty = FALSE)) else ""
    return(list(list(role = "user", content = list(
      aisdk::input_text(paste0(prompt, suffix)),
      aisdk::input_image(as.character(image)[1L])
    ))))
  }
  suffix <- if (is.null(context)) "" else paste0("\nTask context:\n", json_write(context, pretty = FALSE))
  paste0(prompt, suffix)
}

agent_replay_candidate <- function(fig, state, candidate) {
  if (identical(candidate$kind, "record")) {
    rec <- candidate$record
    if (is.null(rec)) return(agent_candidate_result("rejected", "cache", "cached record is missing"))
    return(agent_validate_record_proposal(fig, state, list(
      layer = rec$layer, anchor = rec$anchors, body = rec$body,
      depends_on = rec$depends_on %||% character())))
  }
  if (identical(candidate$kind, "resolve")) {
    p <- candidate$payload %||% list()
    return(agent_validate_resolution(fig, state, p$conflict, p$keep,
                                     p$rationale, p$evidence %||% NULL))
  }
  if (identical(candidate$kind, "repair")) {
    p <- candidate$payload %||% list()
    return(agent_validate_repair(fig, state, p$target_id, p$action,
                                 p$anchor %||% NULL, p$body %||% NULL))
  }
  agent_candidate_result("rejected", "cache", "unknown cached candidate kind")
}

#' Run registered agent stages over a figure
#'
#' @param fig A `gloss_figure`.
#' @param stages Stage names. Dependencies are inserted automatically.
#' @param model An aisdk model identifier or model object. External agents can
#'   use [gl_mcp_session()] and [gl_mcp_serve()] instead.
#' @param context Optional JSON-like task context.
#' @param disclose Optional disclosure level or named levels by stage.
#' @param max_steps Maximum aisdk tool steps per stage.
#' @param max_tokens Optional token limit passed to aisdk.
#' @param cache_dir Optional directory for validated candidate caches.
#' @return A list with the updated `fig` and one report per executed stage.
#' @export
gl_annotate <- function(fig, stages = c("meaning", "relation", "claim"), model = NULL,
                        context = NULL, disclose = NULL, max_steps = 30L,
                        max_tokens = NULL, cache_dir = NULL) {
  check_figure(fig)
  order <- stage_dependency_order(stages)
  reports <- list()
  out <- fig
  for (stage in order) {
    level <- if (is.null(disclose)) NULL else if (length(disclose) == 1L) disclose else disclose[[stage]] %||% NULL
    result <- run_stage(out, stage, model = model, context = context, disclose = level,
                        max_steps = max_steps, max_tokens = max_tokens, cache_dir = cache_dir)
    out <- result$fig
    reports[[stage]] <- result$report
  }
  structure(list(fig = out, reports = reports), class = "gloss_annotation_run")
}

run_stage <- function(fig, stage, model = NULL, context = NULL, disclose = NULL,
                      max_steps = 30L, max_tokens = NULL, cache_dir = NULL,
                      run_id = NULL) {
  check_figure(fig)
  p <- stage_plugin_info(stage)
  level <- disclose %||% p$disclose
  level <- match.arg(level, agent_disclosure_levels)
  key <- agent_cache_key(fig, stage, model, level)
  run_id <- run_id %||% paste0("run-", substr(key, 1L, 12L))
  metadata <- list(run_id = run_id, model = agent_model_label(model),
                   prompt_version = p$prompt_version, cache = "miss")
  cached <- agent_cache_read(cache_dir, key)
  if (!is.null(cached)) {
    metadata$cache <- "hit"
    state <- agent_stage_state(fig, stage, disclose = level, metadata = metadata)
    for (candidate in cached$candidates %||% list()) {
      replay <- agent_replay_candidate(fig, state, candidate)
      agent_store_candidate(state, replay)
    }
    committed <- stage_commit(fig, state)
    committed$cache_hit <- TRUE
    committed$cache_key <- key
    committed$usage <- cached$usage %||% NULL
    return(list(fig = committed$fig, report = committed))
  }
  if (!requireNamespace("aisdk", quietly = TRUE)) {
    cli::cli_abort(c("{.fn gl_annotate} needs the {.pkg aisdk} package for a cache miss.",
                     i = "The substrate, records and checked proposals work without it."))
  }
  if (is.null(model)) cli::cli_abort("Provide {.arg model} to run agent stage {.val {stage}}.")
  state <- agent_stage_state(fig, stage, disclose = level, metadata = metadata)
  tools <- gl_tools(fig, stage = stage, disclose = level, state = state)
  agent <- aisdk::create_agent(
    name = paste0("gloss-", stage),
    description = paste("Run the", stage, "stage over a gloss figure."),
    system_prompt = p$prompt, tools = tools, model = model
  )
  args <- list(task = agent_stage_task(stage, context), model = model, max_steps = max_steps)
  if (!is.null(max_tokens)) args$max_tokens <- max_tokens
  result <- do.call(agent$run, args)
  committed <- stage_commit(fig, state)
  committed$cache_hit <- FALSE
  committed$cache_key <- key
  committed$usage <- result$usage %||% NULL
  committed$text_length <- nchar(result$text %||% "")
  agent_cache_write(cache_dir, key, state, committed)
  list(fig = committed$fig, report = committed)
}

#' @export
print.gloss_annotation_run <- function(x, ...) {
  cat(sprintf("<gloss annotation run> %d stage(s)\n", length(x$reports)))
  for (nm in names(x$reports)) {
    r <- x$reports[[nm]]
    cat(sprintf("  %s: committed %d, rejected %d%s\n", nm,
                length(r$committed %||% list()), length(r$rejected %||% list()),
                if (isTRUE(r$cache_hit)) " (cache hit)" else ""))
  }
  invisible(x)
}
