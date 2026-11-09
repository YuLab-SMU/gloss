# Context sniffing (design: 上下文自动嗅探). Each context item is sniffed by
# one plugin; an item that cannot be sniffed is left empty with a reason.

run_sniffer <- function(plugin, input) {
  res <- tryCatch(plugin$sniff(input), error = function(e) {
    list(found = FALSE, reason = paste("sniffer failed:", conditionMessage(e)))
  })
  found <- isTRUE(res$found)
  list(
    item = plugin$item,
    plugin = plugin$name,
    version = plugin$version,
    found = found,
    value = res$value,
    reason = if (found) NULL else (res$reason %||% "not found")
  )
}

sniff_context <- function(input) {
  items <- list()
  used <- list()
  input$context <- items
  for (p in plugins_of("context")) {
    it <- run_sniffer(p, input)
    items[[p$item]] <- it
    input$context <- items
    used[[length(used) + 1L]] <- plugin_row(p)
  }
  list(items = items, plugins = if (length(used)) do.call(rbind, used) else NULL)
}

#' Context of a figure
#'
#' @param fig A `gloss_figure`.
#' @param item Optional item name (`"code"`, `"data"`, `"engine"`, `"env"`,
#'   `"doc"`, `"git"`, or one added by a plugin).
#' @return For one item, a list with `found`, `value` and, when not found,
#'   `reason`. Without `item`, a data frame summarising every item.
#' @export
gl_context <- function(fig, item = NULL) {
  if (!is.null(item)) {
    it <- fig$context[[item]]
    if (is.null(it)) cli::cli_abort("No context item {.val {item}}.")
    return(it)
  }
  if (!length(fig$context)) {
    return(data.frame(item = character(), plugin = character(), found = logical(),
                      reason = character(), stringsAsFactors = FALSE))
  }
  data.frame(
    item = names(fig$context),
    plugin = vapply(fig$context, function(i) i$plugin %||% NA_character_, ""),
    found = vapply(fig$context, function(i) isTRUE(i$found), logical(1)),
    reason = vapply(fig$context, function(i) i$reason %||% NA_character_, ""),
    stringsAsFactors = FALSE, row.names = NULL
  )
}

deparse_one <- function(x) paste(deparse(x, width.cutoff = 500L), collapse = "\n")

in_knitr <- function() isTRUE(getOption("knitr.in.progress")) && has_pkg("knitr")
