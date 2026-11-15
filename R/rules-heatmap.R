# Deterministic role rules for ComplexHeatmap pages.

register_rules_heatmap <- function() {
  gl_register(
    "rules", name = "heatmap", version = "0.1.0", package = "gloss",
    description = "ComplexHeatmap viewport role rules",
    engine = "heatmap",
    rules = list(viewport = heatmap_role_rule)
  )
}

heatmap_role_rule <- function(leaf, elements, input) {
  p <- leaf_value(leaf, "path", "")
  vp <- leaf_value(leaf, "vp", "")
  cls <- leaf_value(leaf, "class", "")
  q <- tolower(paste(p, vp))
  if (grepl("heatmap_legend|annotation_legend|legend", q)) {
    if (grepl("heatmap_legend", q) && identical(cls, "rect") && nrow(elements) == 1L) {
      return(role_claim("decoration", "background", "viewport:legend key", "heatmap.legend.background"))
    }
    if (grepl("title", q)) return(role_claim("guide", "legend title", "viewport:legend title", "heatmap.legend.title"))
    if (identical(cls, "text")) return(role_claim("guide", "legend label", "viewport:legend label", "heatmap.legend.label"))
    if (grepl("bar|colour|color|raster", q) || nrow(elements) > 1L) return(role_claim("guide", "colour bar", "viewport:legend bar", "heatmap.colour.bar"))
    return(role_claim("guide", "legend key", "viewport:legend key", "heatmap.legend.key"))
  }
  if (grepl("global", q) && identical(cls, "rect") && !grepl("heatmap_body|annotation", q)) {
    return(role_claim("decoration", "background", "viewport:global", "heatmap.background"))
  }
  if (grepl("heatmap_body|mat_heatmap_body|matrix_[0-9]+_heatmap_body", q)) {
    if (grepl("dend", q)) return(role_claim("data", "segment", "viewport:dendrogram", "heatmap.dendrogram"))
    if (identical(cls, "text")) return(role_claim("data", "text", "viewport:heatmap body", "heatmap.body.text"))
    if (cls %in% c("segments", "lines")) return(role_claim("data", "segment", "viewport:heatmap body", "heatmap.body.segment"))
    return(role_claim("data", "cell", "viewport:heatmap body", "heatmap.body.cell"))
  }
  if (grepl("dend_(row|column)|dendrogram", q)) return(role_claim("data", "segment", "viewport:dendrogram", "heatmap.dendrogram"))
  if (grepl("annotation_axis", q)) {
    if (identical(cls, "text")) return(role_claim("guide", "tick label", "viewport:annotation axis label", "heatmap.annotation.axis.label"))
    if (identical(cls, "lines")) return(role_claim("guide", "axis line", "viewport:annotation axis", "heatmap.annotation.axis"))
    return(role_claim("guide", "tick", "viewport:annotation axis", "heatmap.annotation.axis"))
  }
  if (grepl("row_names|column_names|row_name|column_name|row_title|column_title", q)) return(role_claim("guide", "tick label", "viewport:dimension names", "heatmap.dimension.label"))
  if (grepl("annotation|top_annotation|bottom_annotation|left_annotation|right_annotation", q)) {
    if (identical(cls, "rect") && grepl("annotation_point|annotation_foo", q)) {
      return(role_claim("decoration", if (grepl("annotation_foo", q)) "background" else "border", "viewport:annotation decoration", "heatmap.annotation.decoration"))
    }
    if (identical(cls, "text")) return(role_claim("guide", "strip label", "viewport:annotation label", "heatmap.annotation.label"))
    if (cls %in% c("segments", "lines")) return(role_claim("data", "segment", "viewport:annotation", "heatmap.annotation.segment"))
    if (identical(cls, "points")) return(role_claim("data", "point", "viewport:annotation", "heatmap.annotation.point"))
    return(role_claim("data", "cell", "viewport:annotation", "heatmap.annotation.cell"))
  }
  if (identical(cls, "text")) return(role_claim("annotation", if (grepl("title", q)) "title" else "text", "class:text", "heatmap.annotation.text"))
  if (identical(cls, "rect")) return(role_claim("decoration", if (grepl("border", q)) "border" else "other", "class:rect", "heatmap.decoration"))
  if (cls %in% c("segments", "lines")) return(role_claim("decoration", "border", "class:line", "heatmap.decoration"))
  NULL
}
