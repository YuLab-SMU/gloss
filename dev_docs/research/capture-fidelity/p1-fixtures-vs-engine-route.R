# P1 (2026-11-11): page-capture plan, Task 1 and the fixture line of "Done
# when". The six capture inputs captured by the package on the page route,
# against the same inputs captured at the tag engine-route-final.
#
# Run from the repository root, with the tag checked out in a worktree:
#   git worktree add /tmp/gloss-engine-route engine-route-final
#   Rscript dev_docs/research/capture-fidelity/p1-fixtures-vs-engine-route.R /tmp/gloss-engine-route
args <- commandArgs(trailingOnly = TRUE)
old_root <- if (length(args)) args[1] else "/tmp/gloss-engine-route"

capture_six <- function(root, out) {
  code <- sprintf('
    suppressMessages(pkgload::load_all("%s", quiet = TRUE, export_all = TRUE, helpers = FALSE))
    source(file.path("%s", "tests/testthat/helper-figures.R"))
    inputs <- six_inputs()
    res <- lapply(names(inputs), function(nm) {
      set.seed(99)
      t0 <- Sys.time()
      fig <- suppressWarnings(gloss(inputs[[nm]]$x, width = 7, height = 5, dense = Inf, context = FALSE))
      list(sub = fig$substrate, tables = fig$tables, page = fig$meta$page,
           seconds = as.numeric(difftime(Sys.time(), t0, units = "secs")),
           clip = clip_regions(fig$substrate$scene))
    })
    names(res) <- names(inputs)
    saveRDS(res, "%s")', root, root, out)
  f <- tempfile(fileext = ".R")
  writeLines(code, f)
  status <- system2(file.path(R.home("bin"), "Rscript"), f)
  if (status != 0) stop("capture failed in ", root)
  readRDS(out)
}

old <- capture_six(old_root, tempfile(fileext = ".rds"))
new <- capture_six(normalizePath("."), tempfile(fileext = ".rds"))

digits_out <- function(x) gsub("[0-9]+", "#", x)
cat("== six inputs: page route (package) against the engine route (tag engine-route-final) ==\n")
for (nm in names(new)) {
  a <- old[[nm]]$sub
  b <- new[[nm]]$sub
  same_el <- identical(a$elements, b$elements)
  cols <- setdiff(names(a$leaves), c("name", "vp"))
  same_lv <- nrow(a$leaves) == nrow(b$leaves) && identical(a$leaves[cols], b$leaves[cols])
  names_num <- identical(digits_out(a$leaves$name), digits_out(b$leaves$name)) &&
    identical(digits_out(a$leaves$vp), digits_out(b$leaves$vp))
  same_pan <- identical(a$panels, b$panels)
  same_tab <- identical(lapply(old[[nm]]$tables, `[[`, "data"), lapply(new[[nm]]$tables, `[[`, "data"))
  same_clip <- identical(old[[nm]]$clip, new[[nm]]$clip)
  pg <- new[[nm]]$page
  cat(sprintf("  %-12s elements %5d / %5d identical=%-5s | leaves %3d / %3d other columns identical=%-5s name+vp equal up to digits=%-5s | panels identical=%-5s | tables identical=%-5s | clip regions identical=%-5s | verdict %s | %.2f s / %.2f s\n",
              nm, nrow(a$elements), nrow(b$elements), same_el, nrow(a$leaves), nrow(b$leaves), same_lv, names_num,
              same_pan, same_tab, same_clip, pg$verdict, old[[nm]]$seconds, new[[nm]]$seconds))
}

cat("\n== leaf columns that differ, and whether they are equal up to digits ==\n")
for (nm in names(new)) {
  a <- old[[nm]]$sub$leaves
  b <- new[[nm]]$sub$leaves
  cols <- names(a)[!vapply(names(a), function(cc) identical(a[[cc]], b[[cc]]), TRUE)]
  if (!length(cols)) next
  for (cc in cols) {
    up_to_digits <- is.character(a[[cc]]) && identical(digits_out(a[[cc]]), digits_out(b[[cc]]))
    k <- which(a[[cc]] != b[[cc]] | xor(is.na(a[[cc]]), is.na(b[[cc]])))[1]
    cat(sprintf("  %-12s %-6s differs in %d of %d leaves; equal up to digits=%s; first: %s -> %s\n", nm, cc,
                sum(a[[cc]] != b[[cc]], na.rm = TRUE), nrow(a), up_to_digits,
                substr(a[[cc]][k], 1, 70), substr(b[[cc]][k], 1, 70)))
  }
}
