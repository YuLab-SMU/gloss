# Self-check of which figures a run covers (bench v1; plan
# 2026-11-11-bench-tree-stratum). A stratum added after v0 was frozen is run
# and scored on its own, so that no number of v0 moves when the split grows.
# Reads split.csv and the archived runs; runs no figure code:
#   Rscript bench/R/check-scope.R
source("bench/R/common.R")
ok <- TRUE
expect <- function(what, cond) { cat(sprintf("%-86s %s\n", what, if (isTRUE(cond)) "OK" else "FAILED")); ok <<- ok && isTRUE(cond) }
have <- function(f) exists(f, mode = "function")
split <- read_csv(file.path(bench_root, "split.csv"))

expect("the helpers exist: strata_added, set_figures(), run_scope(), file_scope()",
       exists("strata_added") && have("set_figures") && have("run_scope") && have("file_scope"))
if (!ok) { cat("\nscope check: FAILED\n"); quit(status = 1) }

v0 <- lapply(c(dev = "dev", heldout = "heldout"), function(s) set_figures(split, s))
tree <- lapply(c(dev = "dev", heldout = "heldout"), function(s) set_figures(split, s, "tree"))
expect("a run of v0 covers v0's figures: 55 development, 54 held-out",
       nrow(v0$dev) == 55L && nrow(v0$heldout) == 54L)
expect("no figure of an added stratum is in a run of v0",
       !any(c(v0$dev$stratum, v0$heldout$stratum) %in% strata_added))
expect("the tree stratum is run on its own: 29 development, 28 held-out",
       nrow(tree$dev) == 29L && nrow(tree$heldout) == 28L && all(c(tree$dev$stratum, tree$heldout$stratum) == "tree"))
ids <- c(v0$dev$id, v0$heldout$id, tree$dev$id, tree$heldout$id)
expect("the four runs cover every figure of the split once", !anyDuplicated(ids) && setequal(ids, split$id))
expect("a stratum of v0 is not a run of its own (its numbers were reported pooled)",
       inherits(try(set_figures(split, "dev", "gallery"), silent = TRUE), "try-error"))
expect("an unknown set is refused", inherits(try(set_figures(split, "all"), silent = TRUE), "try-error"))

expect("a run's file name carries its stratum", run_scope("dev") == "dev" && run_scope("heldout", "tree") == "heldout-tree")
sc <- function(f) { s <- file_scope(f); paste(s$set, s$stratum %||% "v0") }
expect("the scope is read back from a file name",
       sc("2026-11-11-0858-capture-dev.csv") == "dev v0" &&
       sc("2026-11-11-0843-capture-heldout-engine-route.csv") == "heldout v0" &&
       sc("2026-11-11-1205-bind-dev.csv") == "dev v0" &&
       sc("bench/runs/2026-11-12-0100-capture-dev-tree.csv") == "dev tree" &&
       sc("2026-11-12-0100-bind-heldout-tree.csv") == "heldout tree" &&
       sc("2026-11-12-0100-capture-dev-tree-engine-route.csv") == "dev tree")

# The archived runs of v0 still cover their set, so they can be scored again.
runs <- list.files(file.path(bench_root, "runs"), pattern = "-(capture|bind)-(dev|heldout)[.]csv$", full.names = TRUE)
covered <- vapply(runs, function(f) {
  s <- file_scope(f)
  setequal(read_csv(f)$id, set_figures(split, s$set, s$stratum)$id)
}, logical(1))
expect(sprintf("the archived capture and bind runs of v0 cover their set (%d of %d)", sum(covered), length(runs)),
       length(runs) > 0L && all(covered))
if (any(!covered)) cat("  not covering:", paste(basename(runs[!covered]), collapse = ", "), "\n")

# No run script selects figures by set alone.
scripts <- file.path("bench", "R", c("capture.R", "bind.R", "score-capture.R", "label-sheet.R"))
bare <- vapply(scripts, function(f) any(grepl("split[$]set == set", readLines(f, warn = FALSE), fixed = FALSE)), logical(1))
expect("capture.R, bind.R, score-capture.R and label-sheet.R select through set_figures()",
       !any(bare) && all(vapply(scripts, function(f) any(grepl("set_figures(", readLines(f, warn = FALSE), fixed = TRUE)), logical(1))))

cat(if (ok) "\nscope check: OK\n" else "\nscope check: FAILED\n")
if (!ok) quit(status = 1)
