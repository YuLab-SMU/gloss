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

write_html <- function(fig, path, embed = "default", title = NULL, ...) {
  title <- title %||% fig$context$doc$value$caption %||% "gloss figure"
  html <- paste0(
    "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n",
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n",
    sprintf("<meta name=\"generator\" content=\"gloss %s\">\n", html_escape(gloss_version())),
    sprintf("<title>%s</title>\n", html_escape(title)),
    "<style>body{margin:0;background:#fff}.gloss-figure{margin:0}",
    ".gloss-figure svg{display:block;max-width:100%;height:auto}</style>\n",
    "</head>\n<body>\n",
    sprintf("<figure class=\"gloss-figure\" data-gloss-id=\"%s\">\n", html_escape(fig$meta$id %||% "")),
    scene_for_projection(fig),
    "\n</figure>\n",
    embed_script(fig, embed),
    "\n</body>\n</html>\n"
  )
  writeBin(as_bytes(html), path)
  invisible(path)
}
