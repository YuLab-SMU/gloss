# Self-check of what the tree stratum adds to the runner (bench v1; plan
# 2026-11-11-bench-tree-stratum, Task 3). Run from the repository root, on the
# host or in the container; it needs ggtree, patchwork and ape, and runs no
# third-party code:
#   Rscript bench/R/check-tree.R
source("bench/R/runner.R")
use_env(bench_envs$bioc)   # the tree stratum's environment; in the container it holds the pinned ggtree
ok <- TRUE
expect <- function(what, cond) { cat(sprintf("%-78s %s\n", what, if (isTRUE(cond)) "OK" else "FAILED")); ok <<- ok && isTRUE(cond) }
dir <- file.path(tempdir(), "check-tree")

# ---- which figures hold a tree
script <- list(setup = c("library(ggplot2)", "library(ggtree)", "library(patchwork)", "set.seed(1)", "tr <- ape::rtree(8)"),
               chunks = list(c("ggtree(tr) + geom_tiplab()",
                               "ggplot(mtcars, aes(wt, mpg)) + geom_point()",
                               "ggplot(mtcars, aes(wt, mpg)) + geom_point() | ggtree(tr)",
                               "ggtree(tr) | ggplot(mtcars, aes(wt, mpg)) + geom_point()",
                               "ggplot(mtcars, aes(wt, mpg)) + geom_point() | ggplot(mtcars, aes(hp, mpg)) + geom_point()",
                               "plot(tr)")))
r <- run_script(script, dir, seed = 1, timeout = 300)
print(r$candidates)
expect("six figures, none lost to the new column", nrow(r$candidates) == 6 && is.null(r$error))
expect("engines as before: ggplot, ggplot, patchwork, patchwork, patchwork, base",
       identical(r$candidates$engine, c("ggplot", "ggplot", "patchwork", "patchwork", "patchwork", "base")))
expect("a ggtree plot and a patchwork holding one are tree figures, wherever the tree sits; nothing else is",
       identical(r$candidates$tree, c(TRUE, FALSE, TRUE, TRUE, FALSE, FALSE)))
for (k in c(1, 2, 4)) {
  c1 <- r$candidates[k, ]
  r2 <- run_script(list(setup = script$setup, chunks = truncate_script(script, c1$chunk, c1$expr)), dir, seed = 1,
                   timeout = 300, offline = TRUE, recover = TRUE)
  expect(sprintf("the frozen figure %d is recovered with the same answer (%s)", k, c1$tree), identical(r2$recovered$tree, c1$tree))
}

# ---- a chapter of a book as a script
book <- file.path(dir, "book")
dir.create(book, recursive = TRUE, showWarnings = FALSE)
writeLines(c("if (!requireNamespace(\"pacman\", quietly = TRUE)) {", "    install.packages(\"pacman\")", "}", "",
             "library(pacman)", "p_load(ape)", "## p_load(OutbreakTools)", "p_load(ggtree)", "source(\"conflicted.R\")",
             "helper <- function(x) x + 1"), file.path(book, "setup.R"))
writeLines(c("pacman::p_load(conflicted)", "conflict_prefer(\"filter\", \"dplyr\")"), file.path(book, "conflicted.R"))
writeLines(c("# A chapter", "", "```{r include=F}", "library(knitr)", "opts_chunk$set(message=FALSE)", "```", "",
             "```{r eval=F}", "stop(\"shown, never run\")", "```", "",
             "```{r fig1, fig.cap=\"a tree\"}", "tr <- read.tree(\"data/small.nwk\")", "ggtree(tr)", "```"), file.path(book, "01_ch.Rmd"))
s <- book_script("01_ch.Rmd", root = book)
expect("the chapter's script: the chunks knitr evaluates, in order", length(s$chunks) == 2 && any(grepl("read.tree", s$chunks[[2]])) && !any(grepl("never run", unlist(s$chunks))))
expect("the book's setup: p_load(x) read as require(x), pacman's own lines dropped, comments kept as they are",
       all(c("require(ape)", "require(ggtree)", "## p_load(OutbreakTools)", "helper <- function(x) x + 1") %in% s$setup) && !any(grepl("pacman|install\\.packages", s$setup[!startsWith(s$setup, "#")])))
expect("files the setup sources are inlined, with p_load read the same way",
       all(c("require(conflicted)", "conflict_prefer(\"filter\", \"dplyr\")") %in% s$setup) && !any(grepl("^source\\(", s$setup)))
expect("packages the script needs are found in the setup too", all(c("ape", "ggtree", "conflicted") %in% code_packages(c(s$setup, unlist(s$chunks)))))

cat(if (ok) "\ntree check: OK\n" else "\ntree check: FAILED\n")
if (!ok) quit(status = 1)
