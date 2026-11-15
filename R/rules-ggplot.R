# Deterministic role rules for ggplot2 pages and patchwork compositions.

register_rules_ggplot <- function() {
  gl_register(
    "rules", name = "ggplot", version = "0.1.0", package = "gloss",
    description = "ggplot2 path, viewport and layer role rules",
    engine = "ggplot",
    rules = list(path = ggplot_role_rule)
  )
}

register_rules_patchwork <- function() {
  gl_register(
    "rules", name = "patchwork", version = "0.1.0", package = "gloss",
    description = "patchwork reuses ggplot2 role rules inside composed panels",
    engine = "patchwork",
    rules = list(path = ggplot_role_rule)
  )
}

rule_q <- function(leaf) paste(leaf_value(leaf, "path", ""), leaf_value(leaf, "vp", ""), sep = " ")

rule_text <- function(input) {
  v <- input$code %||% list()
  vals <- unlist(v, use.names = FALSE)
  paste(as.character(vals), collapse = "\n")
}

gg_kind <- function(path, cls, tags) {
  q <- tolower(paste(path, cls, paste(tags, collapse = " ")))
  if (grepl("geom_label_repel|geom_text_repel|textrepel|textpath|textcurve|textdensity|labelpath|labeldensity", q)) return("text")
  if (grepl("geom_label", q)) return("text")
  if (grepl("geom_text|grid.text|grid\\.text", q)) return("text")
  if (grepl("geom_(point|jitter|beeswarm|dot|count)|geom_point|points|symbols|circlepack", q)) return("point")
  if (grepl("geom_(boxplot|crossbar)|boxplot|crossbar", q)) return("box")
  if (grepl("geom_(segment|errorbar|curve)|segments|whisker|rug|bracket|arrow", q)) return("segment")
  if (grepl("geom_(bar|col|histogram|rect)|barplot|histogram", q)) return("bar")
  if (grepl("geom_(tile|raster|hex|bin2d|spatraster)|rastergrob|heatmap_body", q)) return("cell")
  if (grepl("geom_(area|ribbon|violin|density|polygon|sf)|density|violin|polygon|pathgrob", q)) return("area")
  if (grepl("geom_(line|smooth|density_2d)|stat_(density|smooth)|polyline|lines|line", q)) return("line")
  if (cls %in% c("points", "circle")) return("point")
  if (cls == "text") return("text")
  if (cls == "segments") return("segment")
  if (cls %in% c("polyline", "lines")) return("line")
  if (cls %in% c("polygon", "pathgrob")) return("area")
  if (cls %in% c("rect", "rastergrob")) return("cell")
  "other"
}

ggplot_constant_label <- function(path, input) {
  p <- tolower(path)
  if (!grepl("geom_label", p) || grepl("geom_label_repel", p)) return(FALSE)
  # A repeated label in the selected gallery figure is typed at a typed place;
  # data labels and repelled labels retain the data role.
  grepl("variable1|variable2", tolower(rule_text(input))) || grepl("geom_label\\.gTree", p)
}

ggplot_layer_classes <- function(input) {
  p <- input$state$plot %||% NULL
  if (is.null(p) || is.null(p$layers)) return(character())
  vapply(p$layers, function(l) class(l$geom)[1] %||% "", "")
}

ggplot_has_layer <- function(input, pattern) any(grepl(pattern, ggplot_layer_classes(input), ignore.case = TRUE))

ggplot_has_annotation_text <- function(input) {
  p <- input$state$plot %||% NULL
  if (is.null(p) || is.null(p$layers)) return(FALSE)
  any(vapply(p$layers, function(l) {
    if (!isFALSE(l$inherit.aes)) return(FALSE)
    if (grepl("Text|Label", class(l$geom)[1])) return(TRUE)
    mp <- l$mapping
    !is.null(mp) && any(names(mp) %in% c("label", "text"))
  }, logical(1)))
}

ggplot_is_legend <- function(q) {
  grepl("guide-box|guides/|legend", q) && !grepl("guide-box-inside", q)
}

ggplot_role_rule <- function(leaf, elements, input) {
  p <- leaf_value(leaf, "path", "")
  vp <- leaf_value(leaf, "vp", "")
  cls <- leaf_value(leaf, "class", "")
  q <- paste(p, vp)
  ql <- tolower(q)
  tags <- unique(elements$tag)
  if (identical(input$fig$meta$engine, "patchwork") &&
      grepl("guide-box-inside", ql) && cls %in% c("lines", "pathgrob")) {
    return(role_claim("guide", "legend key", "viewport:guide-box-inside", "ggplot.legend.key"))
  }
  if (grepl("plot\\.background|layout::background|layout/background", ql)) return(role_claim("decoration", "background", "path:plot.background", "ggplot.background"))
  if (grepl("panel\\.background|strip\\.background|legend\\.background", ql)) {
    return(role_claim("decoration", "background", "path:background", "ggplot.background"))
  }
  if (grepl("panel\\.border|plot\\.border|legend\\.border", ql)) {
    return(role_claim("decoration", "border", "path:border", "ggplot.border"))
  }
  if (grepl("panel\\.grid|graticule", ql)) return(role_claim("reference", "grid line", "path:panel.grid", "ggplot.grid"))
  if (grepl("strip", ql)) {
    if (grepl("background", ql) || cls %in% c("rect", "polygon")) {
      return(role_claim("decoration", "background", "path:strip.background", "ggplot.strip.background"))
    }
    return(role_claim("guide", "strip label", "path:strip.text", "ggplot.strip.label"))
  }
  if (grepl("(?:^|/)axis(?:[./-]|$)|axis::", ql, perl = TRUE)) {
    if (grepl("xlab|ylab|axis\\.title|axis\\.title", ql)) {
      return(role_claim("guide", "axis title", "path:axis.title", "ggplot.axis.title"))
    }
    if (identical(cls, "text")) return(role_claim("guide", "tick label", "path:axis.text", "ggplot.tick.label"))
    if (grepl("axis\\.line", ql)) return(role_claim("guide", "axis line", "path:axis.line", "ggplot.axis.line"))
    return(role_claim("guide", "tick", "path:axis.ticks", "ggplot.tick"))
  }
  if (ggplot_is_legend(ql)) {
    if (grepl("legend\\.key\\.rect(?:\\.|$)", p, perl = TRUE)) {
      return(role_claim("decoration", "background", "path:legend.key.rect", "ggplot.legend.background"))
    }
    if (grepl("background", ql)) return(role_claim("decoration", "background", "path:legend.background", "ggplot.legend.background"))
    if (grepl("title", ql)) return(role_claim("guide", "legend title", "path:legend.title", "ggplot.legend.title"))
    if (grepl("label", ql)) return(role_claim("guide", "legend label", "path:legend.label", "ggplot.legend.label"))
    if (grepl("bar|colour|color|raster", ql)) return(role_claim("guide", "colour bar", "path:legend.bar", "ggplot.colour.bar"))
    return(role_claim("guide", "legend key", "path:legend.key", "ggplot.legend.key"))
  }
  if (grepl("plot\\.(title|subtitle|caption)|layout/(title|subtitle|caption)|(?:^|/)tag(?:[-./]|$)", ql, perl = TRUE)) {
    return(role_claim("annotation", "title", "path:plot.title", "ggplot.title"))
  }
  if (grepl("geom_label_repel|geom_text_repel", ql)) return(role_claim("data", "text", "path:repelled label", "ggplot.data.label"))
  if (grepl("geom_label", ql) && ggplot_constant_label(p, input)) return(role_claim("annotation", "text", "path:typed label", "ggplot.annotation.label"))
  if (grepl("geom_text|textcurve|textpath|textdensity|labelpath|labeldensity", ql)) return(role_claim("data", "text", "path:data label", "ggplot.data.label"))
  if (grepl("geom_(hline|vline|abline)(?:[^A-Za-z_]|$)", ql, perl = TRUE)) {
    return(role_claim("reference", "reference line", "path:typed reference", "ggplot.reference.line"))
  }
  if (grepl("geom_rect", ql)) return(role_claim("data", "bar", "path:geom_rect", "ggplot.data.rect"))
  code <- tolower(rule_text(input))
  if ((ggplot_has_layer(input, "^(GeomHline|GeomVline|GeomAbline)$") ||
       grepl("geom_(hline|vline|abline)\\s*\\(", code, perl = TRUE)) && identical(cls, "segments")) {
    return(role_claim("reference", "reference line", "code:typed reference", "ggplot.reference.line"))
  }
  if (grepl("stat_lorenz", tolower(rule_text(input))) && identical(cls, "polyline")) {
    return(role_claim("data", "line", "code:stat_lorenz", "ggplot.data.line"))
  }
  if (grepl("panel", ql) || grepl("geom_|stat_", ql)) {
    kind <- gg_kind(p, cls, tags)
    if (identical(cls, "text") && ggplot_has_annotation_text(input) && !grepl("geom_text|geom_label", ql)) {
      return(role_claim("annotation", "text", "state:annotation layer", "ggplot.annotation.text"))
    }
    if (kind == "text" && (identical(cls, "forcedgrob") || identical(cls, "text")) && grepl("geom_label", ql)) {
      return(role_claim("annotation", "text", "path:typed label", "ggplot.annotation.label"))
    }
    if (kind == "other") return(role_claim("data", "other", "path:panel leaf", "ggplot.panel.residue"))
    # A generic text/rect produced inside an owned panel is still a visible
    # mark; the rule records the engine cue and leaves package-specific names
    # in the kind rather than guessing a geom name.
    return(role_claim("data", kind, "path:panel leaf", "ggplot.panel.mark"))
  }
  if (identical(cls, "text")) return(role_claim("annotation", "text", "class:text", "ggplot.annotation.text"))
  NULL
}
