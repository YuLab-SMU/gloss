# Deterministic role rules for base graphics display-list leaves.

register_rules_base <- function() {
  gl_register(
    "rules", name = "base", version = "0.1.0", package = "gloss",
    description = "base display-list call and page role rules",
    engine = "base",
    rules = list(call = base_role_rule)
  )
}

base_entry_index <- function(leaf) suppressWarnings(as.integer(sub("^base/([0-9]+)/.*$", "\\1", leaf_value(leaf, "path", ""))))

base_ops <- function(input) {
  rp <- input$state$recorded %||% NULL
  if (is.null(rp)) return(character())
  dl <- as.list(rp[[1]])
  vapply(dl, dl_op, "")
}

base_legend_leaf <- function(leaf, input) {
  k <- base_entry_index(leaf)
  if (is.na(k)) return(FALSE)
  op <- sub("^base/[0-9]+/", "", leaf_value(leaf, "path", ""))
  if (!op %in% c("plotXY", "text", "symbols")) return(FALSE)
  ops <- base_ops(input)
  if (!length(ops)) return(FALSE)
  lg <- which(grepl("legend", ops, ignore.case = TRUE))
  if (length(lg)) return(k >= max(lg))
  # When legend() is inlined into a single display-list entry, its last mark
  # and text leaves form a suffix after the plot's box/axes. The page path and
  # the code together give a stable, checkable cue.
  k > 0L && k >= length(ops) - 3L
}

base_legend_code <- function(input) grepl("legend\\s*\\(", tolower(rule_text(input)))

base_role_rule <- function(leaf, elements, input) {
  p <- leaf_value(leaf, "path", "")
  vp <- leaf_value(leaf, "vp", "")
  cls <- leaf_value(leaf, "class", "")
  op <- sub("^base/[0-9]+/", "", p)
  if (base_legend_leaf(leaf, input)) {
    if (!base_legend_code(input)) return(NULL)
    if (identical(cls, "text")) return(role_claim("guide", "legend label", "code/page:legend", "base.legend.label"))
    return(role_claim("guide", "legend key", "code/page:legend", "base.legend.key"))
  }
  if (identical(op, "box") || identical(cls, "box")) return(role_claim("decoration", "border", "call:box", "base.box"))
  if (identical(op, "axis") || identical(cls, "axis")) {
    es <- elements$ordinal
    is_text <- elements$tag == "text"
    first <- min(es)
    claims <- list(
      role_claim("guide", "axis line", "call:axis element 1", "base.axis", elements = first),
      role_claim("guide", "tick", "call:axis line elements", "base.axis", elements = es[!is_text & es != first]),
      role_claim("guide", "tick label", "call:axis text elements", "base.axis", elements = es[is_text])
    )
    return(Filter(function(x) length(x$elements %||% integer()), claims))
  }
  if (identical(op, "title") || identical(cls, "title")) {
    code <- tolower(rule_text(input))
    if ((grepl("boxplot\\s*\\(", code) && !grepl("main\\s*=", code)) ||
        (grepl("explo\\.plot", code) && grepl("::plot", paste(p, vp)))) {
      return(role_claim("guide", "axis title", "call:title axis labels", "base.title"))
    }
    main <- elements$ordinal[as.double(elements$y0) < 70 & as.double(elements$x0) > 30]
    if (!length(main)) main <- elements$ordinal[1]
    rest <- setdiff(elements$ordinal, main)
    claims <- list(role_claim("annotation", "title", "call:title main", "base.title", elements = main))
    if (length(rest)) claims[[length(claims) + 1L]] <- role_claim("guide", "axis title", "call:title axis labels", "base.title", elements = rest)
    return(claims)
  }
  if (identical(op, "mtext") || identical(cls, "mtext")) return(role_claim("guide", "axis title", "call:mtext", "base.mtext"))
  if (op %in% c("plot.new", "window")) return(role_claim("decoration", "background", paste0("call:", op), "base.background"))
  if (op %in% c("abline", "grid")) return(role_claim("reference", "reference line", paste0("call:", op), "base.reference"))
  if (op %in% c("plotXY", "points", "symbols", "segments", "arrows", "polygon", "path", "rect")) {
    tags <- unique(elements$tag)
    code <- tolower(rule_text(input))
    if (op == "plotXY" && (
      grepl("plot\\s*\\(\\s*data\\b", code) ||
      (grepl("for\\s*\\(", code) && grepl("lines\\s*\\(", code)) ||
      grepl("explo\\.plot|biocgraph|rgraphviz|agopen", code))) {
      return(role_claim("decoration", "other", "code:generated drawing", "base.generated.decoration"))
    }
    if (grepl("boxplot", code) && op %in% c("polygon", "segments")) {
      if (op == "polygon" || (op == "segments" && nrow(elements) == 1L)) return(role_claim("data", "box", paste0("call:", op), "base.boxplot"))
    }
    kind <- if ("text" %in% tags) "text" else if ("circle" %in% tags) "point" else if ("polyline" %in% tags || "path" %in% tags) "line" else if (op == "rect") "bar" else if (op == "polygon") "area" else "segment"
    return(role_claim("data", kind, paste0("call:", op), "base.data.mark"))
  }
  if (identical(op, "text")) {
    code <- tolower(rule_text(input))
    if (grepl("biocgraph", code) && any(as.double(elements$y0) < 50 | as.double(elements$x0) < 60, na.rm = TRUE)) {
      ann <- elements$ordinal[as.double(elements$y0) < 50 | as.double(elements$x0) < 60]
      rest <- setdiff(elements$ordinal, ann)
      claims <- list(role_claim("annotation", "text", "code:package title", "base.annotation.text", elements = ann))
      if (length(rest)) claims[[length(claims) + 1L]] <- role_claim("data", "text", "call:text", "base.data.text", elements = rest)
      return(claims)
    }
    return(role_claim("data", "text", "call:text", "base.data.text"))
  }
  NULL
}
