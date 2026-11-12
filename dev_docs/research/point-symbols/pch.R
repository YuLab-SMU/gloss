# What svglite draws for each point symbol, and where each part's centre lies
# (plan 2026-11-11-tree-binding, Task 5, first checklist item).
#   Rscript dev_docs/research/point-symbols/pch.R            (host)
#   bench/docker/run.sh Rscript dev_docs/research/point-symbols/pch.R   (container)
# Draws on svglite only; writes nothing but stdout.
suppressMessages(library(grid))

draw <- function(expr, w = 3, h = 3) {
  s <- svglite::svgstring(width = w, height = h, standalone = TRUE)
  grid.newpage()
  suppressWarnings(expr)
  grDevices::dev.off()
  pages <- as.character(s())
  doc <- xml2::read_xml(pages[length(pages)])
  xml2::xml_ns_strip(doc)
  n <- xml2::xml_find_all(doc, "//circle|//rect|//line|//polyline|//polygon|//path|//text")
  # drop the device's background and grid.newpage()'s page fill
  page <- xml2::xml_name(n) == "rect" & (xml2::xml_attr(n, "width") %in% c("100%", sprintf("%.2f", w * 72)))
  n[!page]
}
nums <- function(s) as.numeric(regmatches(s, gregexpr("-?[0-9.]+", s))[[1]])
part_box <- function(nd) {
  t <- xml2::xml_name(nd)
  a <- function(k) as.numeric(xml2::xml_attr(nd, k))
  switch(t,
    circle = c(a("cx") - a("r"), a("cx") + a("r"), a("cy") - a("r"), a("cy") + a("r")),
    rect = c(a("x"), a("x") + a("width"), a("y"), a("y") + a("height")),
    line = c(min(a("x1"), a("x2")), max(a("x1"), a("x2")), min(a("y1"), a("y2")), max(a("y1"), a("y2"))),
    polygon = , polyline = {
      v <- matrix(nums(xml2::xml_attr(nd, "points")), ncol = 2, byrow = TRUE)
      c(range(v[, 1]), range(v[, 2]))
    },
    rep(NA_real_, 4))
}
part_vmean <- function(nd) {
  if (!xml2::xml_name(nd) %in% c("polygon", "polyline")) return(c(NA, NA))
  v <- matrix(nums(xml2::xml_attr(nd, "points")), ncol = 2, byrow = TRUE)
  colMeans(v)
}

cat("svglite", as.character(utils::packageVersion("svglite")), "| grid", as.character(utils::packageVersion("grid")),
    "|", R.version.string, "|", Sys.info()[["sysname"]], "\n\n")

# 1. pch 0-25 at one point (the page centre), at two sizes: tags in drawing
#    order, each part's box centre and vertex mean relative to the point, the
#    union box's centre, and where the point lies in the union box as a
#    fraction of its width and height (y down, as in the SVG).
cat("== 1. pch 0-25, one point at the page centre (108, 108 pt), size 6 pt and 24 pt\n")
cat("   dx, dy: offset from the point, pt; fy: the point's height in the union box (0 top, 1 bottom)\n")
for (p in c(0:25, 46)) {
  for (sz in c(6, 24)) {
    nd <- draw(grid.points(unit(0.5, "npc"), unit(0.5, "npc"), pch = p, size = unit(sz, "pt"), gp = gpar(fill = "grey")))
    tags <- xml2::xml_name(nd)
    boxes <- t(vapply(seq_along(nd), function(i) part_box(nd[[i]]), numeric(4)))
    bc <- cbind((boxes[, 1] + boxes[, 2]) / 2 - 108, (boxes[, 3] + boxes[, 4]) / 2 - 108)
    vm <- t(vapply(seq_along(nd), function(i) part_vmean(nd[[i]]), numeric(2))) - 108
    ub <- c(min(boxes[, 1]), max(boxes[, 2]), min(boxes[, 3]), max(boxes[, 4]))
    fx <- (108 - ub[1]) / (ub[2] - ub[1])
    fy <- (108 - ub[3]) / (ub[4] - ub[3])
    parts <- paste(sprintf("%s box(%+.2f,%+.2f)%s", tags, bc[, 1], bc[, 2],
                           ifelse(is.na(vm[, 1]), "", sprintf(" vmean(%+.2f,%+.2f)", vm[, 1], vm[, 2]))), collapse = "; ")
    cat(sprintf("pch %2d size %2d: %d part%s | union box %.2f x %.2f, point at fx %.4f fy %.4f | %s\n",
                p, sz, length(nd), if (length(nd) == 1) " " else "s", ub[2] - ub[1], ub[4] - ub[3], fx, fy, parts))
  }
}

# 1b. Where the point lies in each part's own box, at sizes 3 to 96 pt: the
#     fractions are the same at every size (up to svglite's 0.01 pt), so a
#     part's box and its symbol give the point. R's engine (GESymbol) builds
#     its triangles from TRC0 = sqrt(4 pi / (3 sqrt(3))) and TRC2 = TRC0 / 2:
#     an apex at r = TRC0 and a base at TRC2 give 2/3 and 1/3; pch 11's base
#     is at (TRC0 + TRC2) / 2, which gives 3/7 and 4/7.
cat("\n== 1b. The point in each part's box (fx, fy; y down), sizes 3, 6, 12, 24, 48, 96 pt\n")
for (p in 0:25) {
  fr <- NULL
  for (sz in c(3, 6, 12, 24, 48, 96)) {
    nd <- draw(grid.points(unit(0.5, "npc"), unit(0.5, "npc"), pch = p, size = unit(sz, "pt")))
    boxes <- t(vapply(seq_along(nd), function(i) part_box(nd[[i]]), numeric(4)))
    w <- boxes[, 2] - boxes[, 1]
    h <- boxes[, 4] - boxes[, 3]
    fx <- ifelse(w > 0, (108 - boxes[, 1]) / w, 0.5)
    fy <- ifelse(h > 0, (108 - boxes[, 3]) / h, 0.5)
    # the error of the fraction at this size, in pt: what svglite's rounding allows
    fr <- rbind(fr, data.frame(size = sz, part = seq_along(nd), tag = xml2::xml_name(nd), fx = fx, fy = fy, w = w, h = h))
  }
  big <- fr[fr$size == 96, ]
  cat(sprintf("pch %2d: %s\n", p, paste(sprintf("%d %s fx %.4f fy %.4f", big$part, big$tag, big$fx, big$fy), collapse = " | ")))
  # the largest distance, over all sizes, between the point and where the
  # fraction measured at 96 pt puts it in the part's box
  ref <- big[match(fr$part, big$part), ]
  err <- pmax(abs(fr$fx - ref$fx) * fr$w, abs(fr$fy - ref$fy) * fr$h)
  cat(sprintf("        largest error using the 96 pt fractions at sizes 3-96: %.4f pt\n", max(err)))
}
trc0 <- sqrt(4 * pi / (3 * sqrt(3)))
cat(sprintf("TRC0 %.6f: 2/3 = %.4f, 1/3 = %.4f, 3/7 = %.4f, 4/7 = %.4f\n", trc0, 2 / 3, 1 / 3, 3 / 7, 4 / 7))

# 2. What draws nothing, or something else.
cat("\n== 2. Other values, three points\n")
x3 <- unit(c(.2, .5, .8), "npc")
show <- function(label, nd) cat(sprintf("%-46s %d: %s\n", label, length(nd), paste(xml2::xml_name(nd), collapse = " ")))
show("pch '.'", draw(grid.points(x3, x3, pch = ".")))
show("pch 46", draw(grid.points(x3, x3, pch = 46)))
show("pch 'a'", draw(grid.points(x3, x3, pch = "a")))
show("pch 65", draw(grid.points(x3, x3, pch = 65)))
show("pch c('a', 'bc', 'd')", draw(grid.points(x3, x3, pch = c("a", "bc", "d"))))
for (p in 26:31) show(sprintf("pch %d", p), draw(grid.points(x3, x3, pch = p)))
show("pch 32 (space)", draw(grid.points(x3, x3, pch = 32)))
show("pch 127", draw(grid.points(x3, x3, pch = 127)))
show("pch c(1, NA, 3)", draw(grid.points(x3, x3, pch = c(1, NA, 3))))
show("x c(.2, NA, .8), pch 3", draw(grid.points(unit(c(.2, NA, .8), "npc"), x3, pch = 3)))
show("x c(.2, Inf, .8) native, pch 3", draw(grid.points(unit(c(.2, Inf, .8), "native"), x3, pch = 3)))
show("x c(.2, 2, .8) npc (off the page), pch 3", draw(grid.points(unit(c(.2, 2, .8), "npc"), x3, pch = 3)))
show("pch c(3, 8) recycled on 3 points", draw(grid.points(x3, x3, pch = c(3, 8))))
show("size 0, pch 8", draw(grid.points(x3, x3, pch = 8, size = unit(0, "pt"))))
show("col NA, pch 3", draw(grid.points(x3, x3, pch = 3, gp = gpar(col = NA))))
show("alpha 0, pch 8", draw(grid.points(x3, x3, pch = 8, gp = gpar(alpha = 0))))
show("lwd 0, pch 8", draw(grid.points(x3, x3, pch = 8, gp = gpar(lwd = 0))))
show("lwd NA, pch 8", draw(grid.points(x3, x3, pch = 8, gp = gpar(lwd = NA))))
show("lwd c(NA, 1, 1), pch 8", draw(grid.points(x3, x3, pch = 8, gp = gpar(lwd = c(NA, 1, 1)))))
show("col 'transparent', pch 8", draw(grid.points(x3, x3, pch = 8, gp = gpar(col = "transparent"))))
show("lty 0 on the viewport, pch 8", draw(grid.draw(gTree(children = gList(pointsGrob(x3, x3, pch = 8)),
                                                          vp = viewport(gp = gpar(lty = 0))))))
show("size c(1, NA, 1) char, pch 3", draw(grid.points(x3, x3, pch = 3, size = unit(c(1, NA, 1), "char"))))
show("size c(1, Inf, 1) char, pch 1", draw(grid.points(x3, x3, pch = 1, size = unit(c(1, Inf, 1), "char"))))
show("pch c(7, 1, 8): parts point after point", draw(grid.points(x3, x3, pch = c(7, 1, 8))))
for (p in list("", NA_character_, -65, 128L, 255L, 256L, 1000L, 0.5, 2.7, 25.9, TRUE)) {
  show(sprintf("pch %s", deparse(p)), draw(grid.points(x3, x3, pch = p)))
}
cat("l10n_info()$MBCS:", l10n_info()$MBCS, "(pch 128-255 draw a character only in a single-byte locale: GESymbol's maxchar)\n")
show("lty 0, pch 8", draw(grid.points(x3, x3, pch = 8, gp = gpar(lty = 0))))
show("lty 'blank', pch 7", draw(grid.points(x3, x3, pch = 7, gp = gpar(lty = "blank"))))
show("lty c(0, 1, 1), pch 8 (gp recycled per point?)", draw(grid.points(x3, x3, pch = 8, gp = gpar(lty = c(0, 1, 1)))))
show("lty 0 on the parent gTree, pch 8", draw(grid.draw(gTree(children = gList(pointsGrob(x3, x3, pch = 8)), gp = gpar(lty = 0)))))
for (p in 0:25) {
  nd <- draw(grid.points(x3, x3, pch = p, gp = gpar(lty = 0, fill = "grey")))
  show(sprintf("lty 0, pch %d", p), nd)
}
for (p in 0:25) {
  nd <- draw(grid.points(x3, x3, pch = p, gp = gpar(lwd = NA, fill = "grey")))
  show(sprintf("lwd NA, pch %d", p), nd)
}

# 2c. What a parent's gpar does (the leaf grob does not hold it): which
#     settings inherit, which multiply, and what a zero font size draws.
cat("\n== 2c. Settings from a parent gTree or viewport\n")
kid <- function(...) pointsGrob(x3, x3, ...)
show("parent lty 0, pch 7", draw(grid.draw(gTree(gp = gpar(lty = 0), children = gList(kid(pch = 7))))))
show("parent lty 0, leaf lty 1, pch 7", draw(grid.draw(gTree(gp = gpar(lty = 0), children = gList(kid(pch = 7, gp = gpar(lty = 1)))))))
show("parent lwd NA, leaf lwd 2, pch 3", draw(grid.draw(gTree(gp = gpar(lwd = NA), children = gList(kid(pch = 3, gp = gpar(lwd = 2)))))))
show("parent lex 0, pch 3", draw(grid.draw(gTree(gp = gpar(lex = 0), children = gList(kid(pch = 3))))))
show("parent lex NA, pch 3", draw(grid.draw(gTree(gp = gpar(lex = NA), children = gList(kid(pch = 3))))))
show("parent lex NA, leaf lex 1, pch 3", draw(grid.draw(gTree(gp = gpar(lex = NA), children = gList(kid(pch = 3, gp = gpar(lex = 1)))))))
show("parent cex 0, leaf cex 1, pch c(1, 3, 0)", draw(grid.draw(gTree(gp = gpar(cex = 0), children = gList(kid(pch = c(1, 3, 0), gp = gpar(cex = 1)))))))
show("parent fontsize 0, leaf fontsize 12, pch 3", draw(grid.draw(gTree(gp = gpar(fontsize = 0), children = gList(kid(pch = 3, gp = gpar(fontsize = 12)))))))
show("parent fontface 5, pch 200", draw(grid.draw(gTree(gp = gpar(fontface = 5), children = gList(kid(pch = 200))))))
# radius of pch 1 (0.375 of the size): cex multiplies down the tree, fontsize does not
r_of <- function(g) as.numeric(xml2::xml_attr(draw(grid.draw(g))[[1]], "r"))
cat(sprintf("pch 1 radius: parent cex 2 fontsize 10, leaf cex 3: %.2f; leaf nothing: %.2f; leaf fontsize 20: %.2f\n",
            r_of(gTree(gp = gpar(cex = 2, fontsize = 10), children = gList(pointsGrob(.5, .5, pch = 1, gp = gpar(cex = 3))))),
            r_of(gTree(gp = gpar(cex = 2, fontsize = 10), children = gList(pointsGrob(.5, .5, pch = 1)))),
            r_of(gTree(gp = gpar(cex = 2, fontsize = 10), children = gList(pointsGrob(.5, .5, pch = 1, gp = gpar(fontsize = 20)))))))
for (fs in list(0, NA)) {
  out <- vapply(c(0:25, 46), function(p) length(draw(grid.points(x3, x3, pch = p, gp = gpar(fontsize = fs)))), 1L)
  cat(sprintf("fontsize %s, size 1 char, pch 0-25 and 46: %s\n", format(fs), paste(out, collapse = " ")))
}
out <- vapply(c(0:25, 46), function(p) length(draw(grid.points(x3, x3, pch = p, gp = gpar(cex = 0)))), 1L)
cat(sprintf("cex 0, size 1 char, pch 0-25 and 46: %s\n", paste(out, collapse = " ")))
out <- vapply(c(0:25, 46), function(p) length(draw(grid.points(x3, x3, pch = p, size = unit(0, "pt")))), 1L)
cat(sprintf("size 0 pt, pch 0-25 and 46: %s\n", paste(out, collapse = " ")))
out <- vapply(c(0:25, 46), function(p) length(draw(grid.points(x3, x3, pch = p, size = unit(0, "char")))), 1L)
cat(sprintf("size 0 char, pch 0-25 and 46: %s\n", paste(out, collapse = " ")))
show("pch 'a', fontsize 0", draw(grid.points(x3, x3, pch = "a", gp = gpar(fontsize = 0))))
show("pch 'a', size 0 pt", draw(grid.points(x3, x3, pch = "a", size = unit(0, "pt"))))

# 2b. Units: which positions can be read as numbers before drawing.
cat("\n== 2b. Units\n")
for (u in list(unit(c(.2, NA, Inf), "npc"), unit(c(1, NA), c("npc", "mm")), unit(1, "npc") + unit(c(1, 2), "mm"))) {
  v <- tryCatch(format(as.numeric(u)), error = function(e) paste("error:", conditionMessage(e)))
  cat(sprintf("%-40s class %-22s as.numeric: %s\n", paste(format(u), collapse = ", "), paste(class(u), collapse = "/"),
              paste(v, collapse = " ")))
}

# 3. ggplot2: shapes 1:8 by a discrete scale, as tree-014 draws them; the
#    grob's pch and what the page holds.
cat("\n== 3. ggplot2", as.character(utils::packageVersion("ggplot2")), "geom_point(shape = factor), scale_shape_manual(values = 1:8)\n")
d <- data.frame(x = 1:16, y = 1:16, k = factor(rep(letters[1:8], 2)))
p <- ggplot2::ggplot(d, ggplot2::aes(x, y, shape = k)) + ggplot2::geom_point() +
  ggplot2::scale_shape_manual(values = 1:8, guide = "none") + ggplot2::theme_void()
b <- ggplot2::ggplot_build(p)
cat("built shape column:", class(b$data[[1]]$shape), paste(b$data[[1]]$shape, collapse = " "), "\n")
nd <- draw(print(p), w = 4, h = 4)
cat("drawn:", length(nd), "elements;", paste(names(table(xml2::xml_name(nd))), table(xml2::xml_name(nd)), collapse = ", "), "\n")
p2 <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point(shape = "triangle open") + ggplot2::theme_void()
cat("shape = 'triangle open': built shape column", class(ggplot2::ggplot_build(p2)$data[[1]]$shape),
    ggplot2::ggplot_build(p2)$data[[1]]$shape[1], "->", ggplot2::translate_shape_string("triangle open"), "\n")
