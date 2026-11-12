# Context sniffer: document and scenario. The knitr / Quarto document and
# chunk, the figure caption and output format, or a running Shiny app.

register_context_doc <- function() {
  gl_register("context", name = "doc", version = "0.1.0", package = "gloss",
              description = "document: knitr/Quarto input, chunk, caption, output format, Shiny",
              item = "doc", sniff = sniff_doc)
}

sniff_doc <- function(input) {
  if (in_knitr()) {
    v <- list(
      engine = if (!is.null(knitr::opts_knit$get("quarto.version"))) "quarto" else "knitr",
      input = tryCatch(knitr::current_input(dir = TRUE), error = function(e) NULL),
      chunk = knitr::opts_current$get("label"),
      caption = knitr::opts_current$get("fig.cap"),
      format = tryCatch(knitr::pandoc_to(), error = function(e) NULL)
    )
    return(list(found = TRUE, value = compact(v)))
  }
  if ("shiny" %in% loadedNamespaces()) {
    running <- tryCatch(get("isRunning", envir = asNamespace("shiny"))(), error = function(e) FALSE)
    if (isTRUE(running)) return(list(found = TRUE, value = list(engine = "shiny")))
  }
  list(found = FALSE, reason = "not running inside knitr, Quarto or a Shiny app")
}
