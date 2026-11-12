# The frame of the tree stratum (bench v1; plan/2026-11-11-bench-tree-stratum.md):
# figures drawn with the ggtree family. Three kinds of PSU: help topics with
# examples of ggtree and ggtreeExtra; the Bioconductor 3.21 software packages
# with vignettes that depend on or import either (both as in the heatmap
# stratum); and the chapters of the ggtree book at a pinned commit (the
# owner's decision, 2026-11-11). Run in the bench container, whose bioc library holds the pinned
# versions (the host's ggtree is another one):
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/frame-tree.R
# The container mounts bench/frame read-only, so the two files are written to
# bench/runs/frame-tree/ and copied to bench/frame/ by hand. The frames of the
# five v0 strata are not read or written.
source("bench/R/common.R")
source("bench/R/runner.R")
use_env(bench_envs$bioc)
lib <- bench_libpaths(active_env())
pkgs <- c("ggtree", "ggtreeExtra")

views_file <- file.path(src_root, "bioc", paste0("VIEWS-", bioc_version))
stopifnot(file.exists(views_file))
views <- as.data.frame(read.dcf(views_file, fields = c("Package", "Version", "Depends", "Imports", "vignettes")), stringsAsFactors = FALSE)
views[is.na(views)] <- ""
uses <- function(p) grepl(paste0("(^|[ ,\n])", p, "([ ,\n(]|$)"), paste(views$Depends, views$Imports))
users <- views[(uses("ggtree") | uses("ggtreeExtra")) & nzchar(views$vignettes), ]

topic_rows <- function(pkg) {
  db <- tools::Rd_db(pkg, lib.loc = lib)
  has_ex <- vapply(db, function(rd) any(vapply(rd, function(s) identical(attr(s, "Rd_tag"), "\\examples"), TRUE)), TRUE)
  t <- sort(sub("\\.Rd$", "", names(db)[has_ex]))
  in_scope <- vapply(t, function(x) has_example_code(rd_example_code(db[[paste0(x, ".Rd")]])), TRUE, USE.NAMES = FALSE)
  data.frame(psu = paste0(pkg, "::", t), kind = "topic", in_scope = in_scope, stringsAsFactors = FALSE)
}
# The book as it is built: the files _bookdown.yml lists, without the title
# page, the author's page and the references. A chapter is in scope if a chunk
# that knitr evaluates has an executable line.
book_root <- file.path(src_root, "treebook", "repo")
stopifnot(file.exists(file.path(book_root, "_bookdown.yml")))
head_ref <- trimws(readLines(file.path(book_root, ".git", "HEAD"), warn = FALSE)[1])
head_sha <- if (startsWith(head_ref, "ref: ")) {
  ref <- sub("^ref: ", "", head_ref)
  f <- file.path(book_root, ".git", ref)
  if (file.exists(f)) trimws(readLines(f, warn = FALSE)[1]) else {
    packed <- readLines(file.path(book_root, ".git", "packed-refs"), warn = FALSE)
    sub(" .*$", "", packed[endsWith(packed, paste0(" ", ref))][1])
  }
} else head_ref
if (!identical(head_sha, sources$treebook$sha)) stop("the book's checkout is at ", head_sha, ", not the pinned ", sources$treebook$sha)
yml <- paste(readLines(file.path(book_root, "_bookdown.yml"), warn = FALSE), collapse = " ")
rest <- sub("^.*rmd_files", "", yml)
listed <- regmatches(rest, gregexpr("[A-Za-z0-9_.-]+\\.Rmd", rest))[[1]]
chapters <- setdiff(listed, c("index.Rmd", "00_author.Rmd", "B-references.Rmd"))
book <- data.frame(psu = chapters, kind = "book", stringsAsFactors = FALSE)
book$in_scope <- vapply(chapters, function(f) {
  ch <- Filter(function(k) k$eval, rmd_chunks(file.path(book_root, f)))
  has_example_code(unlist(lapply(ch, `[[`, "code")))
}, TRUE, USE.NAMES = FALSE)
book <- book[order(book$psu), ]

tree <- rbind(do.call(rbind, lapply(pkgs, topic_rows)),
              data.frame(psu = sort(users$Package), kind = "vignette", in_scope = TRUE, stringsAsFactors = FALSE),
              book)

out_dir <- file.path(bench_root, "runs", "frame-tree")
dir.create(out_dir, showWarnings = FALSE)
write_csv(tree, file.path(out_dir, "tree.csv"))
ver <- function(p) as.character(utils::packageVersion(p, lib.loc = lib))
info <- list(
  built = format(Sys.Date()),
  bioc = list(url = sources$bioc$url, md5 = unname(tools::md5sum(views_file)), packages = nrow(views), users_with_vignettes = nrow(users)),
  topics = stats::setNames(lapply(pkgs, ver), pkgs),
  book = list(repo = sources$treebook$repo, sha = sources$treebook$sha, listed = length(listed), chapters = nrow(book),
              license = "CC BY-NC-SA 4.0 (the online version, as index.Rmd states)"),
  frame = list(topics = sum(tree$kind == "topic"), vignettes = sum(tree$kind == "vignette"), book = sum(tree$kind == "book"), rows = nrow(tree)),
  out_of_scope = list(rule = "help topic whose examples have no executable line (blank, comment or bare NULL only)",
                      tree = sum(!tree$in_scope)),
  not_in_frame = "CRAN packages that import ggtree; Rmd files of the book's repository that the book does not build (ggtree-comicR, ggtree-identity, ggtree-plotly, Introduction, session-info, software-info)"
)
jsonlite::write_json(info, file.path(out_dir, "sources-tree.json"), auto_unbox = TRUE, pretty = TRUE)
cat("tree frame:", nrow(tree), "rows;", sum(tree$in_scope), "in scope\n"); print(table(tree$kind, tree$in_scope)); str(info$topics)
