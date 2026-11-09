# Running figure code for the benchmark (bench v0, Task 3).
#
# A PSU becomes a *script*: a list of chunks of R code plus setup code. The
# worker runs a script in a fresh callr subprocess, expression by expression,
# and records where figures appear:
#   - object: an expression returns a ggplot, patchwork, Heatmap(List) or grob,
#     visibly or through print()/plot()/draw()/grid.draw();
#   - base / grid: the device's display list changed. Such a figure is complete
#     at the end of its chunk, or just before a new page starts.
# Execution stops at the first error, as knitr would.
#
# The same worker reruns a frozen figure (code truncated after the chosen
# figure) and recovers the figure object from its last expression; with
# capture = TRUE it then calls gloss() on it.

source("bench/R/common.R")

figure_classes <- c("ggplot", "patchwork", "Heatmap", "HeatmapList", "grob", "gList", "gtable")

# ---- scripts ---------------------------------------------------------------

strip_installs <- function(code) {
  bad <- grepl("(install\\.packages|install_github|install_gitlab|install_version|BiocManager::install|remotes::install|devtools::install|pak::pkg_install|pak::pak)\\s*\\(", code)
  code[bad] <- paste("#", code[bad], "# [bench: install call removed]")
  code
}

gallery_script <- function(psu) {
  chunks <- rmd_chunks(file.path(src_root, "gallery", psu))
  list(setup = character(), chunks = lapply(chunks, function(k) strip_installs(k$code)),
       chunk_labels = vapply(chunks, `[[`, "", "header"))
}

topic_code <- function(pkg, topic, lib = c(lib_root, .libPaths())) {
  db <- tools::Rd_db(pkg, lib.loc = lib)
  rd <- db[[paste0(topic, ".Rd")]]
  if (is.null(rd)) stop("no help topic ", pkg, "::", topic)
  tmp <- tempfile(fileext = ".R")
  tools::Rd2ex(rd, out = tmp, commentDontrun = TRUE, commentDonttest = FALSE)
  if (!file.exists(tmp)) return(character())
  strip_installs(readLines(tmp, warn = FALSE))
}

topic_script <- function(pkg, topic) {
  list(setup = sprintf("library(%s)", pkg), chunks = list(topic_code(pkg, topic)),
       chunk_labels = paste0(pkg, "::", topic))
}

package_topics <- function(pkg, lib = c(lib_root, .libPaths())) {
  db <- tools::Rd_db(pkg, lib.loc = lib)
  has_ex <- vapply(db, function(rd) any(vapply(rd, function(s) identical(attr(s, "Rd_tag"), "\\examples"), TRUE)), TRUE)
  sort(sub("\\.Rd$", "", names(db)[has_ex]))
}

vignette_files <- function(pkg, lib = c(lib_root, .libPaths())) {
  info <- tools::getVignetteInfo(pkg, lib.loc = lib)
  if (!nrow(info)) return(data.frame())
  data.frame(dir = info[, "Dir"], file = info[, "File"], r = info[, "R"], stringsAsFactors = FALSE)
}

vignette_script <- function(pkg, vig) {
  doc <- file.path(vig$dir, "doc")
  rfile <- file.path(doc, vig$r)
  if (!nzchar(vig$r) || !file.exists(rfile)) {
    src <- file.path(doc, vig$file)
    rfile <- tempfile(fileext = ".R")
    if (grepl("\\.(Rnw|Snw)$", src, ignore.case = TRUE)) {
      utils::Stangle(src, output = rfile, quiet = TRUE)
    } else {
      knitr::purl(src, output = rfile, quiet = TRUE, documentation = 1)
    }
  }
  x <- strip_installs(readLines(rfile, warn = FALSE))
  starts <- sort(unique(c(1L, grep("^## ----|^### code chunk number", x))))
  ends <- c(starts[-1] - 1L, length(x))
  chunks <- Map(function(a, b) x[a:b], starts, ends)
  list(setup = character(), chunks = chunks, chunk_labels = x[starts])
}

# ---- packages ----------------------------------------------------------------

bench_libpaths <- function() unique(c(lib_root, .libPaths()))

installed_anywhere <- function(pkgs) {
  have <- rownames(utils::installed.packages(lib.loc = bench_libpaths()))
  pkgs %in% have
}

# Install missing packages into the bench library (CRAN and Bioconductor 3.21).
# Returns one row per requested package: present, installed or failed.
ensure_packages <- function(pkgs, log = file.path(cache_root, "install.log")) {
  pkgs <- unique(pkgs[nzchar(pkgs)])
  if (!length(pkgs)) return(data.frame(package = character(), status = character()))
  missing <- pkgs[!installed_anywhere(pkgs)]
  if (length(missing)) {
    callr::r(function(pkgs, lib, bioc, cran, log) {
      repos <- c(BiocManager::repositories(version = bioc), CRAN = cran)
      sink(file(log, open = "a"), type = "output")
      cat("\n==== ", format(Sys.time()), paste(pkgs, collapse = " "), "\n")
      try(utils::install.packages(pkgs, lib = lib, repos = repos, type = "binary",
                                  dependencies = c("Depends", "Imports", "LinkingTo"), quiet = TRUE, Ncpus = 4))
      still <- pkgs[!pkgs %in% rownames(utils::installed.packages(lib.loc = .libPaths()))]
      if (length(still))
        try(utils::install.packages(still, lib = lib, repos = repos, type = "source",
                                    dependencies = c("Depends", "Imports", "LinkingTo"), quiet = TRUE, Ncpus = 4))
      sink(type = "output")
      invisible(NULL)
    }, args = list(pkgs = missing, lib = lib_root, bioc = bioc_version, cran = cran_repo, log = log),
    libpath = bench_libpaths(), timeout = 3600, show = FALSE)
  }
  ok <- installed_anywhere(pkgs)
  data.frame(package = pkgs,
             status = ifelse(!pkgs %in% missing, "present", ifelse(ok, "installed", "failed")),
             stringsAsFactors = FALSE)
}

# ---- data vendoring ----------------------------------------------------------

data_ext <- "\\.(csv|txt|tsv|dat|json|geojson|xlsx?|rds|rda|RData|zip|gz|shp|dbf|shx|prj|xml|sav|dta)$"

# Download URL literals (and, for Gallery posts, relative data paths that exist
# in the Gallery repository) into dir/data/ and rewrite the literals.
vendor_data <- function(chunks, dir, gallery = FALSE) {
  code <- unlist(chunks)
  lits <- unique(unlist(regmatches(code, gregexpr("([\"'])(https?://[^\"'[:space:]]+)\\1", code))))
  lits <- unique(c(lits, if (gallery) unique(unlist(regmatches(code, gregexpr("([\"'])([A-Za-z0-9_./-]+)\\1", code))))))
  rewrites <- list()
  for (lit in lits) {
    target <- substr(lit, 2, nchar(lit) - 1)
    is_url <- grepl("^https?://", target)
    if (is_url && !(grepl(data_ext, sub("[?#].*$", "", target), ignore.case = TRUE) ||
                    grepl("raw\\.githubusercontent|gist\\.github|/raw/", target))) next
    if (!is_url && !grepl(data_ext, target, ignore.case = TRUE)) next
    url <- if (is_url) target else paste0(sources$gallery$raw, "/", sub("^\\./", "", target))
    name <- basename(sub("[?#].*$", "", url))
    dest <- file.path(dir, "data", name)
    k <- 1
    while (file.exists(dest) && !any(vapply(rewrites, function(r) identical(r$url, url), TRUE))) {
      k <- k + 1; dest <- file.path(dir, "data", paste0(k, "-", name))
    }
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    status <- system2("curl", c("-sS", "-L", "--fail", "--max-time", "300", "-o", shQuote(dest), shQuote(url)),
                      stdout = FALSE, stderr = FALSE)
    if (status != 0 || !file.exists(dest)) {
      unlink(dest)
      if (is_url) rewrites[[length(rewrites) + 1]] <- list(literal = target, url = url, file = NA, ok = FALSE)
      next
    }
    rel <- file.path("data", basename(dest))
    rewrites[[length(rewrites) + 1]] <- list(literal = target, url = url, file = rel, ok = TRUE,
                                             bytes = file.size(dest), md5 = md5(dest))
    chunks <- lapply(chunks, function(x) gsub(lit, paste0(substr(lit, 1, 1), rel, substr(lit, 1, 1)), x, fixed = TRUE))
  }
  list(chunks = chunks, rewrites = rewrites)
}

# ---- the worker ----------------------------------------------------------------

# Runs inside a fresh R process. Self-contained: callr ships only this function.
run_worker <- function(setup, chunks, dir, seed, figure_classes, recover, capture, repo) {
  setwd(dir)
  set.seed(seed)
  options(warn = 0, device = function(...) grDevices::pdf(NULL, width = 7, height = 5))
  open_dev <- function() {
    grDevices::pdf(NULL, width = 7, height = 5)
    grDevices::dev.control("enable")
  }
  open_dev()
  # the device's display list: raw entries plus an op name per entry
  dl <- function() {
    if (grDevices::dev.cur() == 1L) return(list(raw = list(), ops = character()))
    rp <- tryCatch(grDevices::recordPlot(), error = function(e) NULL)
    if (is.null(rp)) return(list(raw = list(), ops = character()))
    ops <- vapply(rp[[1]], function(el) {
      f <- tryCatch(el[[2]][[1]], error = function(e) NULL)
      if (is.list(f) && !is.null(f$name)) f$name else "call"
    }, "")
    list(raw = as.list(rp[[1]]), ops = ops)  # a pairlist; as.list() so prefixes compare
  }
  # drawing onto the same page only appends entries; anything else is a new page
  extends <- function(now, prev) {
    n <- length(prev$raw)
    length(now$raw) >= n && identical(now$raw[seq_len(n)], prev$raw)
  }
  dl_kind <- function(ops) {
    if (any(grepl("^C_", ops) & ops != "C_par")) "base" else if (any(ops == "call")) "grid" else NA_character_
  }
  engine_of <- function(v) {
    if (inherits(v, "patchwork")) "patchwork"
    else if (inherits(v, "ggplot")) "ggplot"
    else if (inherits(v, c("Heatmap", "HeatmapList"))) "heatmap"
    else "grid"
  }
  printer <- c("print", "plot", "draw", "grid.draw", "show")
  env <- new.env(parent = globalenv())
  cand <- list(); out_classes <- character(); err <- NULL; n_expr <- 0L
  last_value <- NULL; last_obj <- FALSE
  t0 <- Sys.time()
  if (length(setup)) eval(parse(text = setup), env)
  prev <- dl(); changed <- FALSE; changed_kind <- NA_character_
  add <- function(ch, ex, kind, cls, engine)
    cand[[length(cand) + 1]] <<- data.frame(chunk = ch, expr = ex, kind = kind, class = cls, engine = engine,
                                            stringsAsFactors = FALSE)
  for (i in seq_along(chunks)) {
    exprs <- tryCatch(parse(text = chunks[[i]], keep.source = TRUE), error = function(e) e)
    if (inherits(exprs, "error")) { err <- list(chunk = i, expr = 0L, stage = "parse", message = conditionMessage(exprs)); break }
    if (!length(exprs)) next
    srcref <- attr(exprs, "srcref")
    for (j in seq_along(exprs)) {
      n_expr <- n_expr + 1L
      res <- tryCatch(withVisible(eval(exprs[[j]], env)), error = function(e) e)
      if (inherits(res, "error")) {
        err <- list(chunk = i, expr = j, stage = "eval", message = conditionMessage(res))
        break
      }
      if (grDevices::dev.cur() == 1L) open_dev()
      e <- exprs[[j]]
      fn <- if (is.call(e)) paste(deparse(e[[1]]), collapse = "") else ""
      fn <- sub("^.*::", "", fn)
      v <- res$value
      last_obj <- inherits(v, figure_classes) && (res$visible || fn %in% printer)
      last_value <- if (last_obj) v else NULL
      if (res$visible && !last_obj && !is.null(v)) out_classes <- c(out_classes, class(v)[1])
      now <- dl()
      if (!identical(now$raw, prev$raw)) {
        new_page <- changed && !extends(now, prev)
        if (new_page) add(i, j - 1L, changed_kind, changed_kind, changed_kind)
        changed <- TRUE
        changed_kind <- dl_kind(now$ops)
        prev <- now
      }
      if (last_obj) {
        add(i, j, "object", class(v)[1], engine_of(v))
        # a printed object also draws; don't count that drawing again
        changed <- FALSE
      }
    }
    if (!is.null(err)) break
    if (changed && !is.na(changed_kind)) add(i, length(exprs), changed_kind, changed_kind, changed_kind)
    changed <- FALSE
  }
  cand <- if (length(cand)) do.call(rbind, cand) else
    data.frame(chunk = integer(), expr = integer(), kind = character(), class = character(), engine = character())
  cand <- cand[!is.na(cand$kind), , drop = FALSE]
  result <- list(candidates = cand, error = err, n_expr = n_expr, out_classes = unique(out_classes),
                 elapsed = as.numeric(difftime(Sys.time(), t0, units = "secs")))
  if (recover) {
    fig <- NULL; kind <- NA_character_
    if (last_obj) { fig <- last_value; kind <- "object" }
    else {
      k <- dl_kind(dl()$ops)
      if (identical(k, "base")) { fig <- grDevices::recordPlot(); kind <- "base" }
      else if (identical(k, "grid")) { fig <- grid::grid.grab(); kind <- "grid" }
    }
    result$recovered <- list(kind = kind, class = if (is.null(fig)) NA else class(fig)[1],
                             engine = if (is.null(fig)) NA else if (kind == "object") engine_of(fig) else kind)
    if (capture && !is.null(fig)) {
      suppressMessages(pkgload::load_all(repo, quiet = TRUE, export_all = FALSE, helpers = FALSE))
      t1 <- Sys.time()
      g <- tryCatch(gloss::gloss(fig), error = function(e) e)
      cap <- list(seconds = as.numeric(difftime(Sys.time(), t1, units = "secs")))
      if (inherits(g, "error")) {
        cap$status <- "error"; cap$message <- conditionMessage(g)
      } else {
        s <- g$substrate
        cap$status <- "captured"
        cap$engine <- g$meta$engine %||% NA
        cap$elements <- nrow(s$elements)
        cap$leaves <- nrow(s$leaves)
        cap$panels <- nrow(s$panels)
        cap$leaf_status <- as.list(table(s$leaves$status))
        cap$unowned <- sum(is.na(s$elements$leaf))
      }
      result$capture <- cap
    }
  }
  result
}

`%||%` <- function(a, b) if (is.null(a)) b else a

offline_env <- c(http_proxy = "http://127.0.0.1:9", https_proxy = "http://127.0.0.1:9",
                 HTTP_PROXY = "http://127.0.0.1:9", HTTPS_PROXY = "http://127.0.0.1:9",
                 ALL_PROXY = "http://127.0.0.1:9", no_proxy = "", NO_PROXY = "")

run_script <- function(script, dir, seed, timeout = 300, offline = FALSE,
                       recover = FALSE, capture = FALSE) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  env <- c(callr::rcmd_safe_env(), R_LIBS_USER = paste(bench_libpaths(), collapse = .Platform$path.sep))
  if (offline) env <- c(env, offline_env)
  res <- tryCatch(
    callr::r(run_worker,
             args = list(setup = script$setup, chunks = script$chunks, dir = normalizePath(dir),
                         seed = seed, figure_classes = figure_classes, recover = recover,
                         capture = capture, repo = normalizePath(".")),
             libpath = bench_libpaths(), env = env, timeout = timeout, show = FALSE,
             package = FALSE),
    error = function(e) e)
  if (inherits(res, "error")) {
    msg <- conditionMessage(res)
    timeout_hit <- inherits(res, "callr_timeout_error") || grepl("timed out|timeout", msg, ignore.case = TRUE)
    return(list(candidates = data.frame(chunk = integer(), expr = integer(), kind = character(),
                                        class = character(), engine = character()),
                error = list(chunk = NA, expr = NA, stage = if (timeout_hit) "timeout" else "process",
                             message = msg),
                n_expr = NA, out_classes = character(), elapsed = NA))
  }
  res
}

# Original text of a script truncated after expression `expr` of chunk `chunk`.
truncate_script <- function(script, chunk, expr) {
  keep <- script$chunks[seq_len(chunk)]
  exprs <- parse(text = keep[[chunk]], keep.source = TRUE)
  last_line <- attr(exprs, "srcref")[[expr]][3]
  keep[[chunk]] <- keep[[chunk]][seq_len(last_line)]
  keep
}

seed_for <- function(id) {
  h <- substr(digest::digest(id, algo = "md5"), 1, 7)
  strtoi(h, 16L)
}
