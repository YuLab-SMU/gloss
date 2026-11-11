# Figures used across tests. Each input comes with the plain drawing call
# that the capture must reproduce element for element.

skip_if_no <- function(...) for (p in c(...)) testthat::skip_if_not_installed(p)

p_facet <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point() +
    ggplot2::geom_smooth(method = "lm", formula = y ~ x) +
    ggplot2::facet_wrap(~am) +
    ggplot2::annotate("text", x = 4, y = 32, label = "heavier = thirstier")
}

base_scatter <- function() {
  plot(mtcars$wt, mtcars$mpg, pch = 19)
  abline(lm(mpg ~ wt, mtcars))
  legend("topright", "fit", lty = 1)
}

heatmap_example <- function() {
  set.seed(1)
  m <- matrix(rnorm(80), 10, dimnames = list(paste0("g", 1:10), paste0("s", 1:8)))
  ha <- ComplexHeatmap::HeatmapAnnotation(cyl = sample(c("a", "b"), 8, TRUE))
  ComplexHeatmap::Heatmap(m, top_annotation = ha, name = "z")
}

six_inputs <- function() {
  big <- local({
    set.seed(2)
    data.frame(x = rnorm(1e4), y = rnorm(1e4))
  })
  pf <- p_facet()
  p2 <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg)) + ggplot2::geom_boxplot()
  pw <- patchwork::wrap_plots(pf, p2, ncol = 1)
  pr <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, label = rownames(mtcars))) +
    ggplot2::geom_point() + ggrepel::geom_text_repel(seed = 1)
  pb <- ggplot2::ggplot(big, ggplot2::aes(x, y)) + ggplot2::geom_point(size = 0.3)
  ht <- heatmap_example()
  list(
    ggplot_facet = list(x = pf, draw = function() print(pf)),
    patchwork = list(x = pw, draw = function() print(pw)),
    base = list(x = base_scatter, draw = base_scatter),
    heatmap = list(x = ht, draw = function() ComplexHeatmap::draw(ht)),
    ggrepel = list(x = pr, draw = function() print(pr)),
    points_1e4 = list(x = pb, draw = function() print(pb))
  )
}

# The clip regions in force for each drawn primitive: the geometry of every
# clipPath referenced by an ancestor group, outermost first. The clip is an
# attribute of an ancestor, so scene_signatures() alone cannot see a primitive
# that lost its clip.
clip_regions <- function(svg) {
  doc <- xml2::read_xml(svg)
  ns <- svg_ns(doc)
  defs <- xml2::xml_find_all(doc, "//d1:clipPath", ns)
  geom <- vapply(defs, function(d) {
    paste(vapply(xml2::xml_children(d), function(k) {
      a <- xml2::xml_attrs(k)
      paste(xml2::xml_name(k), paste(names(a), a, sep = "=", collapse = " "))
    }, ""), collapse = ";")
  }, "")
  names(geom) <- xml2::xml_attr(defs, "id")
  nodes <- xml2::xml_find_all(doc, prim_xpath(), ns)
  anc <- xml2::xml_find_all(nodes, "ancestor::d1:g[@clip-path]", ns, flatten = FALSE)
  vapply(anc, function(a) {
    if (!length(a)) return("")
    ids <- sub("^url\\(#(.*)\\)$", "\\1", xml2::xml_attr(a, "clip-path"))
    paste(geom[ids], collapse = " > ")
  }, "")
}

# source() a script the way a user would, so that sniffers see the file.
sys.source_like <- function(path, env) {
  source(path, local = env, keep.source = TRUE)
}
