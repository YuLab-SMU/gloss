# S3 (2026-11-10): page capture on the 55 development figures of bench v0.
# Runs third-party code: container only, no network, as bench/R/capture.R:
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript dev_docs/research/capture-fidelity/s3-dev-set.R
# Development set only. The held-out set is never read: the set is fixed below
# and is not an argument (arguments are figure ids within the development set). A spike, made after looking at the development
# results of 2026-11-10; it scores no prediction.
#
# For each figure the frozen code runs on svglite, as in a capture run. Then:
#   A0  the page the code left on the device (the bench's reference);
#   A1  grid pages only: the same display list redrawn by grid.refresh(),
#       untouched (is a plain redraw stable?);
#   B   the page captured by the page route (page-capture.R). From the second
#       run on (2026-11-10-17xx), A1 and B start from the same RNG state.
# For figures the bench recovers as an object, the object is also printed on a
# fresh page (P) and that page is captured (BP): P differs from A0 when the
# code left something else on the page.

source("bench/R/harvest.R")
set_name <- "dev"

reachable <- tryCatch({
  con <- suppressWarnings(socketConnection("cloud.r-project.org", 80, blocking = TRUE, timeout = 5))
  close(con); TRUE
}, error = function(e) FALSE)
if (reachable) stop("the network is reachable; run with GLOSS_BENCH_OFFLINE=true bench/docker/run.sh")

spike_worker <- function(chunks, dir, seed, repo, skip_print, figure_classes, lib_file) {
  setwd(dir)
  set.seed(seed)
  devs <- new.env()
  new_dev <- function() {
    devs$svg <- svglite::svgstring(width = 7, height = 5, standalone = TRUE)
    devs$num <- grDevices::dev.cur()
  }
  options(warn = 0, device = function(...) new_dev(), knitr.graphics.error = FALSE)
  open_dev <- function() { new_dev(); grDevices::dev.control("enable") }
  open_dev()
  env <- new.env(parent = globalenv())
  printer <- c("print", "plot", "draw", "grid.draw", "show")
  exprs <- parse(text = unlist(chunks), keep.source = FALSE)
  last <- NULL; last_obj <- FALSE
  for (j in seq_along(exprs)) {
    res <- tryCatch(withVisible(eval(exprs[[j]], env)), error = function(e) e)
    if (inherits(res, "error")) return(list(error = paste("eval:", conditionMessage(res))))
    v <- res$value
    cls <- paste(class(v), collapse = " ")
    if (res$visible && !is.null(v) && !grepl(skip_print, cls)) {
      pr <- tryCatch({ if (isS4(v)) methods::show(v) else print(v); NULL }, error = function(e) e)
      if (inherits(pr, "error")) return(list(error = paste("print:", conditionMessage(pr))))
    }
    if (grDevices::dev.cur() == 1L) open_dev()
    e <- exprs[[j]]
    fn <- if (is.call(e)) paste(deparse(e[[1]]), collapse = "") else ""
    fn <- sub("^.*::", "", fn)
    last_obj <- inherits(v, figure_classes) && (res$visible || fn %in% printer)
    last <- if (last_obj) v else NULL
  }
  suppressMessages(pkgload::load_all(repo, quiet = TRUE, export_all = TRUE, helpers = FALSE))
  sys.source(lib_file, envir = environment())
  msg <- function(e) substr(gsub("\\s+", " ", conditionMessage(e)), 1, 160)
  out <- list(error = NA_character_, class = if (last_obj) class(last)[1] else NA_character_)
  grDevices::dev.set(devs$num)
  pk <- page_kind()
  out$bench_kind <- if (last_obj) "object" else pk$kind
  out$page_kind <- pk$kind
  out$dl_entries <- length(pk$ops)
  out$grid_grobs <- pk$grid_grobs
  A0 <- last_page(devs$svg)
  out$pages <- length(as.character(devs$svg()))
  a0 <- if (is.na(A0)) character() else scene_signatures(A0)
  out$prims_A0 <- length(a0)
  # the same comparison with each primitive's clip regions (third run on)
  c0 <- if (is.na(A0)) character() else tryCatch(clip_signatures(A0), error = function(e) NULL)

  # ---- the page as the code left it -------------------------------------
  t0 <- Sys.time()
  if (identical(pk$kind, "grid")) {
    out$route <- "grid: display list wrapped in place"
    # the plain redraw and the wrapped redraw start from the same RNG state:
    # a figure that draws random numbers while drawing (ggrepel without a
    # seed) then lays itself out the same way in both
    rs <- get0(".Random.seed", envir = globalenv())
    grid::grid.refresh()
    A1 <- last_page(devs$svg)
    a1 <- scene_signatures(A1)
    out$redraw_stable <- identical(a1, a0)
    out$redraw_differ <- diffn(a1, a0)
    if (!is.null(rs)) assign(".Random.seed", rs, envir = globalenv())
    sub <- tryCatch(suppressWarnings(capture_grid_page(devs$svg)), error = function(e) e)
    if (inherits(sub, "error")) {
      out$error <- paste("capture:", msg(sub))
    } else {
      b <- scene_signatures(sub$scene)
      out$prims_B <- length(b); out$identical <- identical(b, a0); out$differ <- diffn(b, a0)
      out$stable_identical <- identical(b, a1); out$stable_differ <- diffn(b, a1)
      out$leaves <- nrow(sub$leaves); out$unowned <- sum(is.na(sub$elements$leaf))
      out$mismatch <- sum(sub$leaves$status == "count_mismatch")
      out$vector_names <- sub$vector_names
      out$clip_leaves <- sum(sub$leaves$class == "clip")
      cb <- tryCatch(clip_signatures(sub$scene), error = function(e) NULL)
      c1 <- tryCatch(clip_signatures(A1), error = function(e) NULL)
      out$clip_identical <- if (is.null(cb) || is.null(c0)) NA else identical(cb, c0)
      out$clip_stable_identical <- if (is.null(cb) || is.null(c1)) NA else identical(cb, c1)
    }
  } else if (identical(pk$kind, "base")) {
    out$route <- "base: display list replayed by entry"
    by <- tryCatch(suppressWarnings(replay_by_entry(pk$rp)), error = function(e) e)
    if (inherits(by, "error")) {
      out$error <- paste("capture:", msg(by))
    } else {
      b <- scene_signatures(by$page)
      out$prims_B <- length(b); out$identical <- identical(b, a0); out$differ <- diffn(b, a0)
      out$leaves <- sum(diff(c(0L, by$seen)) > 0L)            # entries that drew something
      out$unowned <- length(b) - by$seen[length(by$seen)]
      out$monotone <- all(diff(c(0L, by$seen)) >= 0L)
      cb <- tryCatch(clip_signatures(by$page), error = function(e) NULL)
      out$clip_identical <- if (is.null(cb) || is.null(c0)) NA else identical(cb, c0)
    }
  } else {
    out$route <- paste("none:", pk$kind, "page")
  }
  out$seconds <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

  # ---- the recovered object, printed on a fresh page -----------------------
  if (last_obj) {
    r <- tryCatch({
      open_dev()
      if (isS4(last)) methods::show(last) else print(last)
      grDevices::dev.set(devs$num)
      P <- last_page(devs$svg)
      p <- if (is.na(P)) character() else scene_signatures(P)
      k2 <- page_kind()$kind
      res <- list(prims_P = length(p), fresh_same = identical(p, a0), fresh_differ = diffn(p, a0), fresh_kind = k2)
      if (identical(k2, "grid")) {
        sub <- suppressWarnings(capture_grid_page(devs$svg))
        bp <- scene_signatures(sub$scene)
        res$obj_identical <- identical(bp, p); res$obj_differ <- diffn(bp, p)
      }
      res
    }, error = function(e) list(obj_error = msg(e)))
    out[names(r)] <- r
  }
  out
}

split <- read_csv(file.path(bench_root, "split.csv"))
todo <- split[split$set == set_name, ]
# optional ids, for a pilot: always a subset of the development set
ids <- commandArgs(trailingOnly = TRUE)
if (length(ids)) todo <- todo[todo$id %in% ids, ]
stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
out_file <- file.path(bench_root, "runs", sprintf("%s-page-capture-spike-%s%s.csv", stamp, set_name,
                                                  if (length(ids)) "-pilot" else ""))
lib_file <- normalizePath("dev_docs/research/capture-fidelity/page-capture.R")
fields <- c("error", "class", "bench_kind", "page_kind", "route", "pages", "dl_entries", "grid_grobs", "prims_A0",
            "prims_B", "identical", "differ", "redraw_stable", "redraw_differ", "stable_identical", "stable_differ",
            "leaves", "unowned", "mismatch", "vector_names", "clip_leaves", "clip_identical", "clip_stable_identical", "monotone", "prims_P", "fresh_same", "fresh_differ", "fresh_kind",
            "obj_identical", "obj_differ", "obj_error", "seconds")
rows <- list()
for (k in seq_len(nrow(todo))) {
  id <- todo$id[k]
  dir <- file.path(bench_root, "figures", id)
  meta <- jsonlite::read_json(file.path(dir, "meta.json"))
  use_env(figure_env(meta))
  env <- c(callr::rcmd_safe_env(), R_LIBS_USER = paste(bench_libpaths(), collapse = .Platform$path.sep), offline_env)
  res <- tryCatch(
    callr::r(spike_worker,
             args = list(chunks = frozen_script(dir)$chunks, dir = normalizePath(prepare_run_dir(dir)),
                         seed = meta$seed, repo = normalizePath("."), skip_print = outside_classes,
                         figure_classes = figure_classes, lib_file = lib_file),
             libpath = bench_libpaths(), env = env, timeout = 900, show = FALSE, package = FALSE),
    error = function(e) list(error = paste("process:", substr(gsub("\\s+", " ", conditionMessage(e)), 1, 160))))
  row <- lapply(setNames(nm = fields), function(f) { v <- res[[f]]; if (is.null(v) || !length(v)) NA else v })
  rows[[k]] <- data.frame(id = id, stratum = todo$stratum[k], engine = todo$engine[k], row, stringsAsFactors = FALSE)
  write_csv(do.call(rbind, rows), out_file)
  r <- rows[[k]]
  cat(sprintf("[%d/%d] %-14s %-9s %-6s A0 %5s B %5s identical=%-5s differ=%-5s stable=%-5s fresh_same=%-5s %s\n",
              k, nrow(todo), id, todo$engine[k], r$page_kind, r$prims_A0, r$prims_B, r$identical, r$differ,
              r$redraw_stable, r$fresh_same, if (is.na(r$error)) "" else r$error))
  if (!is.na(r$clip_identical) && !r$clip_identical) cat("        clip regions differ from the page\n")
}
cat("written:", out_file, "\n")
