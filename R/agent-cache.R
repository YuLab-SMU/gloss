# Disk cache for stage candidates. Cache files contain validated data and
# provenance, never model secrets or executable values.

agent_substrate_hash <- function(fig) {
  digest::digest(list(scene = fig$substrate$scene,
                      elements = fig$substrate$elements,
                      leaves = fig$substrate$leaves,
                      panels = fig$substrate$panels,
                      tables = lapply(fig$tables, function(t) list(name = t$name, role = t$role,
                                                                   key = t$key, data = t$data))),
                 algo = "sha256")
}

agent_layer_hash <- function(fig) {
  digest::digest(lapply(fig$layers, function(l) l$log %||% list()), algo = "sha256")
}

agent_model_label <- function(model) {
  if (is.null(model)) return("")
  if (is.character(model)) return(paste(model, collapse = ","))
  id <- tryCatch(model$model_id, error = function(e) NULL)
  if (is.null(id)) id <- tryCatch(model$provider, error = function(e) NULL)
  if (!is.null(id)) return(as.character(id)[1L])
  paste(class(model), collapse = "/")
}

agent_cache_key <- function(fig, stage, model = NULL, disclose = "summary") {
  p <- stage_plugin_info(stage)
  digest::digest(list(substrate = agent_substrate_hash(fig), layers = agent_layer_hash(fig),
                      stage = stage, model = agent_model_label(model),
                      prompt_version = p$prompt_version, schema = record_digest(p$schema),
                      disclose = disclose), algo = "sha256")
}

agent_cache_path <- function(cache_dir, key) {
  if (is.null(cache_dir)) return(NULL)
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  file.path(cache_dir, paste0(key, ".json"))
}

agent_cache_read <- function(cache_dir, key) {
  path <- agent_cache_path(cache_dir, key)
  if (is.null(path) || !file.exists(path)) return(NULL)
  out <- tryCatch(json_read(readLines(path, warn = FALSE, encoding = "UTF-8")), error = function(e) NULL)
  if (is.null(out) || !identical(out$key, key)) return(NULL)
  out
}

agent_cache_write <- function(cache_dir, key, state, report) {
  path <- agent_cache_path(cache_dir, key)
  if (is.null(path)) return(invisible(NULL))
  candidates <- lapply(state$candidates %||% list(), function(x) {
    list(outcome = x$outcome, stage = x$stage, reasons = x$reasons,
         kind = x$kind, record = x$record, payload = x$payload)
  })
  value <- list(key = key, stage = state$stage, metadata = state$metadata,
               candidates = candidates, committed = length(report$committed %||% list()))
  writeLines(json_write(value, pretty = TRUE), path, useBytes = TRUE)
  invisible(path)
}
