# Projection plugin: a single HTML file showing the figure, with the whole
# bundle embedded. Interactivity arrives with the browser runtime (M3).

register_projection_html <- function() {
  gl_register("projection", name = "html", version = "0.1.0", package = "gloss",
              description = "single HTML file: the scene plus the embedded bundle",
              formats = c("html", "htm"), write = write_html)
}

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub("\"", "&quot;", x, fixed = TRUE)
}

runtime_root <- function() {
  installed <- system.file("js", package = "gloss")
  if (nzchar(installed)) return(installed)
  local <- file.path("inst", "js")
  if (dir.exists(local)) return(local)
  cli::cli_abort("The gloss browser runtime is not available.")
}

runtime_sources <- function(fig) {
  root <- runtime_root()
  files <- c("gloss-core.js")
  ops <- unique(vapply(fig$operations$specs %||% list(), `[[`, "", "op"))
  op_files <- vapply(ops, function(op) switch(op,
    select = "select", style = "style", show = "visibility", hide = "visibility",
    raise = "visibility", lower = "visibility", focus = "select", link = "select",
    unlink = "select", overlay = "select", tooltip = "tooltip", character()
  ), "")
  files <- c(files, file.path("ops", paste0(op_files[nzchar(op_files)], ".js")))
  files <- unique(files[file.exists(file.path(root, files))])
  vapply(files, function(f) paste(readLines(file.path(root, f), warn = FALSE), collapse = "\n"), "")
}

runtime_config <- function(fig) {
  list(id = fig$meta$id %||% "", operations = lapply(fig$operations$specs %||% list(), function(op) {
    op[c("op", "targets", "style", "value", "text", "trigger", "from_targets", "to_targets")]
  }))
}

runtime_script <- function(fig) {
  config <- json_write(runtime_config(fig), pretty = FALSE)
  # A model-supplied string is data inside a script tag. Escape the closing
  # sequence before embedding it so it cannot terminate the tag.
  config <- gsub("</", "<\\/", config, fixed = TRUE)
  paste0(
    "<script>window.__GLOSS_RUNTIME_CONFIG__=", config, ";\n",
    paste(runtime_sources(fig), collapse = "\n"),
    "\n</script>"
  )
}

write_html <- function(fig, path, embed = "default", title = NULL, ...) {
  title <- title %||% fig$context$doc$value$caption %||% "gloss figure"
  html <- paste0(
    "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n",
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n",
    sprintf("<meta name=\"generator\" content=\"gloss %s\">\n", html_escape(gloss_version())),
    sprintf("<title>%s</title>\n", html_escape(title)),
    "<style>body{margin:0;background:#fff}.gloss-figure{margin:0;position:relative}",
    ".gloss-figure svg{display:block;max-width:100%;height:auto}",
    ".gloss-hidden{display:none!important}.gloss-fade{opacity:.28!important}",
    ".gloss-highlight{stroke:#315bb6!important;stroke-width:2.2!important}",
    ".gloss-outline{stroke:#315bb6!important;stroke-width:1.6!important}",
    ".gloss-tooltip{position:absolute;z-index:2;transform:translate(-50%,-100%);",
    "padding:3px 6px;border:1px solid #b7c7df;background:#fff;color:#17345f;",
    "font:12px sans-serif;pointer-events:none}.gloss-overlay{pointer-events:none}</style>\n",
    "</head>\n<body>\n",
    sprintf("<figure class=\"gloss-figure\" data-gloss-id=\"%s\">\n", html_escape(fig$meta$id %||% "")),
    scene_for_projection(fig),
    "\n</figure>\n",
    embed_script(fig, embed),
    "\n", runtime_script(fig),
    "\n</body>\n</html>\n"
  )
  writeBin(as_bytes(html), path)
  invisible(path)
}
