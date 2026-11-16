# Accessibility and annotation projections.  They are exporter plugins so the
# internal record representation stays independent of any external standard.

register_projection_aria <- function() {
  gl_register("projection", name = "aria", version = "0.1.0", package = "gloss",
              description = "WAI-ARIA graphics tree as JSON",
              formats = "aria", reads = "json", write = write_aria)
}

register_projection_text <- function() {
  gl_register("projection", name = "text", version = "0.1.0", package = "gloss",
              description = "Plain-text figure description",
              formats = "text", reads = "text", write = write_text_projection)
}

register_projection_annotation <- function() {
  gl_register("projection", name = "annotation", version = "0.1.0", package = "gloss",
              description = "W3C Web Annotation JSON",
              formats = "annotation", reads = "json", write = write_annotation)
}

projection_records <- function(fig) {
  rows <- gl_records(fig)
  attr(rows, "records") %||% list()
}

record_targets <- function(rec) {
  if (is.null(rec$resolution)) return(character())
  unique(unlist(lapply(rec$resolution, function(x) as.character(x$target %||% character())),
                use.names = FALSE))
}

record_text <- function(rec) {
  body <- rec$body %||% list()
  txt <- body$text %||% body$description %||% body$alt_text %||% ""
  if (!is_string(txt)) txt <- paste(as.character(txt), collapse = " ")
  txt
}

record_projection_entries <- function(fig, include_rejected = FALSE) {
  recs <- projection_records(fig)
  if (!length(recs)) return(list())
  out <- list()
  for (rec in recs) {
    status <- record_projection_status(rec)
    if (!include_rejected && status %in% c("rejected", "invalid", "retracted", "superseded")) next
    txt <- record_text(rec)
    if (!nzchar(txt)) next
    out[[length(out) + 1L]] <- list(
      id = rec$id, layer = rec$layer, status = status, text = txt,
      targets = record_targets(rec), by = rec$provenance$by %||% "unknown",
      created = rec$created %||% rec$provenance$time %||% NA_character_
    )
  }
  out
}

aria_role_for_tag <- function(tag) {
  switch(tag,
         text = "graphics-symbol",
         image = "img",
         rect = "graphics-symbol",
         circle = "graphics-symbol",
         line = "graphics-symbol",
         polyline = "graphics-symbol",
         polygon = "graphics-symbol",
         path = "graphics-symbol",
         "graphics-symbol")
}

aria_tree <- function(fig) {
  el <- gl_elements(fig)
  panels <- gl_panels(fig)
  panel_children <- lapply(seq_len(nrow(panels)), function(i) {
    p <- panels[i, , drop = FALSE]
    ids <- el$id[el$panel %in% p$id]
    list(role = "graphics-object", id = as.character(p$id),
         label = paste("panel", p$key %||% p$id),
         children = lapply(ids, function(id) {
           e <- el[el$id == id, , drop = FALSE]
           list(role = aria_role_for_tag(e$tag), id = id,
                label = ifelse(is.na(e$text), e$tag, e$text),
                bbox = list(x = e$x0, y = e$y0, width = e$x1 - e$x0,
                            height = e$y1 - e$y0))
         }))
  })
  list(role = "graphics-document", id = fig$meta$id %||% "gloss-figure",
       label = fig$context$doc$value$caption %||% "R figure",
       children = panel_children,
       records = record_projection_entries(fig))
}

text_projection <- function(fig) {
  lines <- c(fig$context$doc$value$caption %||% "Figure", "")
  p <- gl_panels(fig)
  if (nrow(p)) lines <- c(lines, sprintf("Panels: %d.", nrow(p)))
  entries <- record_projection_entries(fig)
  if (length(entries)) {
    lines <- c(lines, "Semantic records:")
    lines <- c(lines, vapply(entries, function(x) {
      prefix <- if (x$status == "verified") "verified" else x$status
      sprintf("%s [%s]", x$text, prefix)
    }, ""))
  }
  paste(lines, collapse = "\n")
}

annotation_projection <- function(fig) {
  entries <- record_projection_entries(fig, include_rejected = TRUE)
  annotations <- lapply(entries, function(x) {
    purpose <- switch(x$status, verified = "commenting", speculative = "commenting",
                      rejected = "rejecting", "commenting")
    list(
      id = paste0("#", x$id), type = "Annotation", motivation = purpose,
      body = list(value = x$text, format = "text/plain", status = x$status),
      target = list(source = fig$meta$id %||% "gloss-figure",
                    selector = lapply(x$targets, function(id) {
                      list(type = "FragmentSelector", conformsTo = "gloss-element",
                           value = paste0("element=", id))
                    })),
      creator = x$by, generator = "gloss", created = x$created
    )
  })
  list(`@context` = "http://www.w3.org/ns/anno.jsonld", type = "AnnotationPage",
       partOf = list(id = fig$meta$id %||% "gloss-figure"), items = annotations)
}

write_projection_text <- function(value, path) {
  out <- if (is.character(value)) value else json_write(value, pretty = TRUE)
  if (!is.null(path)) {
    writeBin(as_bytes(paste0(out, if (endsWith(out, "\n")) "" else "\n")), path)
    return(invisible(path))
  }
  out
}

write_aria <- function(fig, path, ...) write_projection_text(aria_tree(fig), path)
write_text_projection <- function(fig, path, ...) write_projection_text(text_projection(fig), path)
write_annotation <- function(fig, path, ...) write_projection_text(annotation_projection(fig), path)

#' Export an accessibility or annotation projection
#'
#' @param fig A `gloss_figure`.
#' @param format One of `"aria"`, `"text"` or `"annotation"`.
#' @param path Optional output path. Without it, return the projection value.
#' @return The projection value, or `path` invisibly when writing a file.
#' @export
gl_export <- function(fig, format = c("aria", "text", "annotation"), path = NULL, ...) {
  check_figure(fig)
  format <- match.arg(format)
  plugin <- gl_plugin("projection", format)
  plugin$write(fig, path, ...)
}

