# Self-check of score-labels.R on the guideline's worked examples (no bench
# figure is read): the examples resolve and agree with themselves; each
# mutation a label file can suffer makes `check` fail, and disagreement
# lowers kappa by the amount computed by hand.
#   Rscript bench/R/check-labels.R
sheets <- "bench/labels/examples"
labels <- file.path(sheets, "labels")
run <- function(...) {
  out <- suppressWarnings(system2("Rscript", c("bench/R/score-labels.R", ...), stdout = TRUE, stderr = TRUE))
  list(ok = is.null(attr(out, "status")), out = out)
}
expect <- function(what, cond) { cat(sprintf("%-70s %s\n", what, if (cond) "OK" else "FAILED")); if (!cond) quit(status = 1) }
r <- run("check", labels, sheets)
expect("the examples resolve", r$ok)
r <- run("agree", labels, labels, sheets)
expect("the examples agree with themselves: kappa 1", r$ok && any(grepl("criterion, >= 0.8): kappa 1.000", r$out, fixed = TRUE)))

mutate <- function(f, id = "ex-base") {
  d <- file.path(tempdir(), paste0("lab-", as.integer(stats::runif(1) * 1e6)))
  dir.create(d)
  for (x in list.files(labels, full.names = TRUE)) file.copy(x, d)
  t <- utils::read.csv(file.path(d, paste0(id, ".csv")), stringsAsFactors = FALSE, colClasses = "character", na.strings = character())
  utils::write.csv(f(t), file.path(d, paste0(id, ".csv")), row.names = FALSE)
  d
}
fails <- function(what, d, pattern) {
  r <- run("check", d, sheets)
  expect(what, !r$ok && any(grepl(pattern, r$out)))
}
fails("a leaf whose class changed does not resolve", mutate(function(t) { t$class[1] <- "points"; t }), "is now plotXY")
fails("a leaf whose element count changed does not resolve", mutate(function(t) { t$n_elements[1] <- "31"; t }), "is now plotXY with 32")
fails("an unknown key does not resolve", mutate(function(t) { t$key[1] <- "figure-1 | base/#/lines"; t }), "resolves to no leaf")
fails("a leaf left out fails", mutate(function(t) t[-nrow(t), ]), "not labelled")
fails("a split that misses an element fails", mutate(function(t) { t$elements[t$elements == "2-3"] <- "2"; t }), "elements 3 not labelled")
fails("a split that labels an element twice fails", mutate(function(t) { t$elements[t$elements == "2-3"] <- "1-3"; t }), "labelled more than once")
fails("a role outside the vocabulary fails", mutate(function(t) { t$role[1] <- "mark"; t }), "not in the vocabulary")
fails("a kind of another role fails", mutate(function(t) { t$kind[1] <- "tick"; t }), "is not a kind of data")

# Disagreement on one leaf of ex-heatmap's leaves with elements (k 4, the
# column title: annotation for A, guide for B). Leaf-weighted, by hand:
# agreement (n - 1) / n; kappa from the two role distributions.
d <- mutate(function(t) { t$role[t$k == "4"] <- "guide"; t$kind[t$k == "4"] <- "strip label"; t }, "ex-heatmap")
for (f in c("ex-ggplot.csv", "ex-base.csv")) file.remove(file.path(d, f))
a <- utils::read.csv(file.path(labels, "ex-heatmap.csv"), stringsAsFactors = FALSE)
a <- a[a$n_elements > 0, ]
b <- a; b$role[b$k == 4] <- "guide"
po <- mean(a$role == b$role)
pa <- table(factor(a$role, union(a$role, b$role))) / nrow(a)
pb <- table(factor(b$role, union(a$role, b$role))) / nrow(b)
k <- (po - sum(pa * pb)) / (1 - sum(pa * pb))
r <- run("agree", labels, d, sheets)
line <- grep("criterion", r$out, value = TRUE)
expect(sprintf("one leaf in %d differs: kappa %.3f, agreement %.3f", nrow(a), k, po),
       r$ok && grepl(sprintf("kappa %.3f, agreement %.3f", k, po), line, fixed = TRUE))
expect("the differing leaf is listed", any(grepl("ex-heatmap +4 +annotation +title +guide +strip label", r$out)))
