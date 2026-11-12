# Which geom classes bind with no code written for them (retrospective of
# 2026-11-12; design §绑定假设; the research card's contrast with one handler
# per geom). Reads three archived runs' leaf tables; runs no figure code:
#   Rscript dev_docs/research/bind-dev/d4-geoms.R
# A ggplot layer leaf carries its layer's geom class. A class is ggplot2's own
# when an object of that name is in ggplot2's namespace (the host's ggplot2;
# ggtree's "New..." classes made by ggnewscale are counted under their base
# name); otherwise it comes from an extension package. "Checked" is verified
# or ambiguous. Base call names (plotXY, ...) are left out: they are not geoms.

runs <- c(v0_dev = "bench/runs/2026-11-12-1116-bind-dev-leaves.csv",
          tree_dev = "bench/runs/2026-11-12-1107-bind-dev-tree-leaves.csv",
          tree_heldout = "bench/runs/2026-11-12-1427-bind-heldout-tree-leaves.csv")
d <- do.call(rbind, lapply(names(runs), function(n) {
  x <- utils::read.csv(runs[[n]], stringsAsFactors = FALSE)
  x <- x[!is.na(x$geom) & grepl("^(New)?Geom", x$geom), ]
  data.frame(set = n, id = x$id, geom = sub("^New", "", x$geom), elements = x$n_elements,
             checked = x$verified + x$ambiguous, stringsAsFactors = FALSE)
}))
own <- vapply(unique(d$geom), function(g) exists(g, envir = asNamespace("ggplot2"), inherits = FALSE), logical(1))
g <- stats::aggregate(cbind(elements, checked) ~ geom, d, sum)
g$figures <- vapply(g$geom, function(k) length(unique(d$id[d$geom == k])), 1L)
g$from <- ifelse(own[g$geom], "ggplot2", "extension")
g$state <- ifelse(g$elements == 0, "no element", ifelse(g$checked == g$elements, "all", ifelse(g$checked > 0, "part", "none")))
g <- g[order(g$from, -g$elements), ]
print(g, row.names = FALSE)
cat(sprintf("\nggplot2 %s; figures with a layer leaf: %d\n", utils::packageVersion("ggplot2"), length(unique(d$id))))
for (f in c("ggplot2", "extension")) {
  k <- g$from == f
  cat(sprintf("%-9s %2d classes: all checked %d, part %d, none %d, no element %d; %d of %d elements checked\n", f, sum(k),
              sum(g$state[k] == "all"), sum(g$state[k] == "part"), sum(g$state[k] == "none"), sum(g$state[k] == "no element"),
              sum(g$checked[k]), sum(g$elements[k])))
}
src <- unlist(lapply(list.files("R", full.names = TRUE), function(f) {
  l <- readLines(f, warn = FALSE)
  l[!grepl("^\\s*#", l)]
}))
code <- sub("#.*$", "", src)
hits <- grep("Geom[A-Z][A-Za-z0-9]+", code, value = TRUE)
hits <- hits[!grepl("ggplot2::Geom\\$", hits)]
cat(sprintf("lines of R/ outside comments that name a geom class other than ggplot2::Geom itself: %d\n", length(hits)))
if (length(hits)) print(trimws(hits))
