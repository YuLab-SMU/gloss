# Generic grid role rules. Extension-specific names remain classified only when
# viewport or class gives a stable engine cue; otherwise the result is residue.

register_rules_grid <- function() {
  gl_register(
    "rules", name = "grid", version = "0.1.0", package = "gloss",
    description = "grid viewport and grob role rules",
    engine = "grid",
    rules = list(viewport = grid_role_rule)
  )
}

grid_role_rule <- function(leaf, elements, input) {
  p <- leaf_value(leaf, "path", "")
  vp <- leaf_value(leaf, "vp", "")
  cls <- leaf_value(leaf, "class", "")
  q <- tolower(paste(p, vp))
  if (grepl("plot\\.background|panel\\.background|legend\\.background", q)) {
    return(role_claim("decoration", "background", "path:background", "grid.background"))
  }
  if (grepl("panel\\.border", q)) return(role_claim("decoration", "border", "path:border", "grid.border"))
  if (grepl("panel\\.grid", q)) return(role_claim("reference", "grid line", "path:grid", "grid.grid"))
  if (grepl("legend\\.key", q)) return(role_claim("guide", "legend key", "path:legend.key", "grid.legend.key"))
  if (grepl("legend", q)) {
    if (identical(cls, "text")) return(role_claim("guide", "legend label", "path:legend.label", "grid.legend.label"))
    return(role_claim("decoration", "background", "path:legend.background", "grid.legend.background"))
  }
  if (grepl("axis|ticks|labels|major|minor|graticule", q)) {
    if (identical(cls, "text") || grepl("labels", q)) return(role_claim("guide", "tick label", "path:axis.label", "grid.tick.label"))
    return(role_claim("guide", "tick", "path:axis.tick", "grid.tick"))
  }
  if (grepl("title|caption", q)) return(role_claim("annotation", "title", "path:title", "grid.title"))
  if (identical(cls, "points") || identical(cls, "circle")) return(role_claim("data", "point", "class:point", "grid.data.point"))
  if (identical(cls, "rect")) return(role_claim("data", "cell", "class:rect", "grid.data.cell"))
  if (identical(cls, "polygon")) return(role_claim("data", "area", "class:polygon", "grid.data.area"))
  if (identical(cls, "rastergrob")) return(role_claim("data", "cell", "class:raster", "grid.data.cell"))
  if (identical(cls, "segments")) return(role_claim("data", "segment", "class:segments", "grid.data.segment"))
  if (cls %in% c("polyline", "lines", "pathgrob")) return(role_claim("data", "line", "class:line", "grid.data.line"))
  if (identical(cls, "text")) return(role_claim("data", "text", "class:text", "grid.data.text"))
  NULL
}
