# Leaf names of a capture run: how many leaves have a generic own name
# (GRID.<class>.<n>), by engine, and the elements under each name stem.
# Reads only an archived run; draws nothing.
#
#   Rscript bench/R/leaf-names.R bench/runs/2026-11-11-0858-capture-dev.csv
#
# The run's `leaf_names` column (bench/R/runner.R) lists each distinct leaf
# name of a figure as "name:leaves:elements", largest first, cut at 600
# characters by bench/R/capture.R. An entry cut short is dropped, so the
# counts cover the leaves listed, which the first line reports.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("usage: Rscript bench/R/leaf-names.R <run.csv>")
d <- utils::read.csv(args[1], stringsAsFactors = FALSE)
d <- d[d$status == "captured", ]

x <- do.call(rbind, lapply(seq_len(nrow(d)), function(i) {
  s <- strsplit(d$leaf_names[i], " ", fixed = TRUE)[[1]]
  s <- s[grepl("^.+:[0-9]+:[0-9]+$", s)]
  if (!length(s)) return(NULL)
  name <- sub(":[0-9]+:[0-9]+$", "", s)
  num <- do.call(rbind, strsplit(sub("^.*:([0-9]+):([0-9]+)$", "\\1 \\2", s), " ", fixed = TRUE))
  data.frame(id = d$id[i], engine = d$engine[i], name = name,
             leaves = as.integer(num[, 1]), elements = as.integer(num[, 2]),
             stringsAsFactors = FALSE)
}))

cat(sprintf("captured figures %d; leaves listed %d of %d; elements listed %d of %d\n",
            nrow(d), sum(x$leaves), sum(d$leaves), sum(x$elements), sum(d$elements)))
x$generic <- grepl("^GRID[.]", x$name)
x$generic_leaves <- x$leaves * x$generic
x$generic_elements <- x$elements * x$generic
by_engine <- stats::aggregate(cbind(leaves, generic_leaves, elements, generic_elements) ~ engine, x, sum)
print(by_engine, row.names = FALSE)

# Leaf shares are unbiased only on figures listed in full: on a figure cut
# short, the names dropped are the smallest, where generic names gather.
listed <- tapply(x$leaves, x$id, sum)
full <- d$id[d$leaves == listed[d$id] & !is.na(listed[d$id])]
cat(sprintf("\nfigures listed in full: %d of %d\n", length(full), nrow(d)))
xf <- x[x$id %in% full, ]
by_full <- stats::aggregate(cbind(figures = !duplicated(id), leaves, generic_leaves) ~ engine, xf, sum)
print(by_full, row.names = FALSE)

x$stem <- sub("[.][.].*$", "", sub("[.][0-9]+$", "", x$name))
for (e in sort(unique(x$engine))) {
  cat("\n==", e, "(elements by name stem)\n")
  t <- sort(tapply(x$elements[x$engine == e], x$stem[x$engine == e], sum), decreasing = TRUE)
  print(utils::head(t, 25))
}
