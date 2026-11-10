# Running figure code for the benchmark (bench v0, Task 3).
#
# A PSU becomes a *script*: a list of chunks of R code plus setup code. The
# worker runs a script in a fresh callr subprocess, expression by expression,
# and records where figures appear:
#   - object: an expression returns a ggplot, patchwork, Heatmap(List) or grob,
#     visibly or through print()/plot()/draw()/grid.draw();
#   - base / grid: the device's display list changed. Such a figure is complete
#     at the end of its chunk, or just before a new page starts.
# Visible values are printed, as at the top level and in knitr (lattice and
# others draw only then). Execution stops at the first error, as knitr would.
#
# The same worker reruns a frozen figure (code truncated after the chosen
# figure) and recovers the figure object from its last expression; with
# capture = TRUE it then calls gloss() on it.

source("bench/R/common.R")

figure_classes <- c("ggplot", "patchwork", "Heatmap", "HeatmapList", "grob", "gList", "gtable")

# Visible values outside the population (widgets, tables, 3D scenes, apps).
# Matched against all of a value's classes; the worker does not print them.
outside_classes <- "htmlwidget|gt_tbl|knitr_kable|kableExtra|flextable|datatables|rgl|plotly|leaflet|girafe|reactable|gtsummary|tbl_summary|shiny\\.appobj"

# ---- scripts ---------------------------------------------------------------

strip_installs <- function(code) {
  bad <- grepl("(install\\.packages|install_github|install_gitlab|install_version|BiocManager::install|remotes::install|devtools::install|pak::pkg_install|pak::pak)\\s*\\(", code)
  code[bad] <- paste("#", code[bad], "# [bench: install call removed]")
  code
}

nbsp <- " "
count_nbsp <- function(code) sum(lengths(regmatches(code, gregexpr(nbsp, code, fixed = TRUE))))

# Mechanical edits applied to every script and recorded with each frozen
# figure: install calls are commented out; no-break spaces (U+00A0, pasted from
# web pages) become spaces, because R 4.5's parser rejects them outside strings.
clean_code <- function(code) {
  code <- tryCatch(gsub(nbsp, " ", code, fixed = TRUE), error = function(e) code)
  strip_installs(code)
}

# The Gallery's closing chunk includes HTML from the website, which is not in
# the repository; it draws nothing and would end every post on an error.
site_scaffolding <- function(code) {
  x <- trimws(code)
  x <- x[nzchar(x)]
  length(x) > 0 && all(grepl("^(htmltools::)?includeHTML\\(", x))
}

gallery_script <- function(psu, root = file.path(src_root, "gallery")) {
  chunks <- rmd_chunks(file.path(root, psu))
  chunks <- Filter(function(k) !site_scaffolding(k$code), chunks)
  code <- lapply(chunks, `[[`, "code")
  list(setup = character(), chunks = lapply(code, clean_code),
       chunk_labels = vapply(chunks, `[[`, "", "header"), nbsp = count_nbsp(unlist(code)))
}

topic_code <- function(pkg, topic, lib = bench_libpaths()) {
  db <- tools::Rd_db(pkg, lib.loc = lib)
  rd <- db[[paste0(topic, ".Rd")]]
  if (is.null(rd)) stop("no help topic ", pkg, "::", topic)
  code <- rd_example_code(rd)
  structure(clean_code(code), nbsp = count_nbsp(code))
}

topic_script <- function(pkg, topic) {
  code <- topic_code(pkg, topic)
  list(setup = sprintf("library(%s)", pkg), chunks = list(as.vector(code)),
       chunk_labels = paste0(pkg, "::", topic), nbsp = attr(code, "nbsp"))
}

package_topics <- function(pkg, lib = bench_libpaths()) {
  db <- tools::Rd_db(pkg, lib.loc = lib)
  has_ex <- vapply(db, function(rd) any(vapply(rd, function(s) identical(attr(s, "Rd_tag"), "\\examples"), TRUE)), TRUE)
  db <- db[has_ex]
  has_code <- vapply(db, function(rd) has_example_code(rd_example_code(rd)), TRUE)
  sort(sub("\\.Rd$", "", names(db)[has_code]))
}

vignette_files <- function(pkg, lib = bench_libpaths()) {
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
  raw <- readLines(rfile, warn = FALSE)
  x <- clean_code(raw)
  starts <- sort(unique(c(1L, grep("^## ----|^### code chunk number", x))))
  ends <- c(starts[-1] - 1L, length(x))
  chunks <- Map(function(a, b) x[a:b], starts, ends)
  list(setup = character(), chunks = chunks, chunk_labels = x[starts], nbsp = count_nbsp(raw))
}

# ---- packages ----------------------------------------------------------------

# The active environment's library, then the session's (the image's site and
# base libraries); the other environments' libraries are never on the path.
bench_libpaths <- function(env = active_env()) {
  others <- vapply(Filter(function(e) e$name != env$name, bench_envs), `[[`, "", "lib")
  sess <- .libPaths()
  sess <- sess[!normalizePath(sess, mustWork = FALSE) %in% normalizePath(others, mustWork = FALSE)]
  unique(c(env$lib, sess))
}

installed_anywhere <- function(pkgs, env = active_env()) {
  have <- rownames(utils::installed.packages(lib.loc = bench_libpaths(env)))
  pkgs %in% have
}

# Why a package failed to install, from the warnings install.packages() gave:
# the ones naming it, and any unavailable dependency.
install_reason <- function(pkg, notes) {
  notes <- sub("\n.*$", "", notes)
  own <- grep(paste0("[^A-Za-z0-9.]", gsub(".", "\\.", pkg, fixed = TRUE), "[^A-Za-z0-9.]"), notes, value = TRUE)
  deps <- grep("^dependenc(y|ies) .* (is|are) not available", notes, value = TRUE)
  x <- unique(c(own, deps))
  if (length(x)) paste(x, collapse = "; ") else "install failed (see install.log)"
}

# Install missing packages into the active environment's library (its CRAN
# snapshot and Bioconductor 3.21). Returns one row per requested package:
# present, installed or failed, with the reason for a failure. A download
# through the proxy fails now and then (SSL connect error), so failed downloads
# are retried. Build output goes to the log (quiet = FALSE): with quiet = TRUE
# a failed build left only "installation of package ... failed". R CMD INSTALL
# writes through system2(), outside R's sink(), so the log takes the child
# process's whole stdout and stderr, not a sink (check-runner Part 1d).
ensure_packages <- function(pkgs, log = file.path(cache_root, "install.log"), tries = 3L, env = active_env()) {
  pkgs <- unique(pkgs[nzchar(pkgs)])
  if (!length(pkgs)) return(data.frame(package = character(), status = character(), reason = character()))
  missing <- pkgs[!installed_anywhere(pkgs, env)]
  notes <- character()
  if (length(missing)) {
    out <- tempfile("install-", fileext = ".log")
    on.exit(if (file.exists(out)) { file.append(log, out); unlink(out) }, add = TRUE)
    notes <- callr::r(function(pkgs, lib, bioc, cran, tries, env_name) {
      # BiocManager validates the version online; through the proxy that fails now and then
      repos <- NULL
      for (k in seq_len(tries)) {
        repos <- tryCatch(BiocManager::repositories(version = bioc), error = function(e) e)
        if (!inherits(repos, "error")) break
        Sys.sleep(10 * k)
      }
      if (inherits(repos, "error")) stop(repos)
      repos[["CRAN"]] <- cran  # always the pinned CRAN, never the session's option
      # Linux (the container) installs type "source": Posit Package Manager
      # serves CRAN binaries under it; Bioconductor packages compile (no arm64
      # container binaries for 3.21)
      first <- if (.Platform$pkgType == "source") "source" else "binary"
      # errors from install.packages() arrive as messages, most failures as
      # warnings: all three reach the log (stdout and stderr), and the
      # warnings are also kept
      cat("\n==== ", format(Sys.time()), paste0("[", env_name, "]"), paste(pkgs, collapse = " "), "\n")
      acc <- new.env()
      acc$notes <- character()
      install <- function(p, type) withCallingHandlers(
        try(utils::install.packages(p, lib = lib, repos = repos, type = type,
                                    dependencies = c("Depends", "Imports", "LinkingTo"), quiet = FALSE, Ncpus = 4)),
        warning = function(w) {
          acc$notes <- c(acc$notes, conditionMessage(w))
          cat("Warning:", conditionMessage(w), "\n")
          invokeRestart("muffleWarning")
        })
      still <- function() pkgs[!pkgs %in% rownames(utils::installed.packages(lib.loc = .libPaths()))]
      install(pkgs, first)
      if (length(still()) && first != "source") install(still(), "source")
      k <- 1L
      while (length(still()) && k < tries && any(grepl("download of package .* failed", acc$notes))) {
        Sys.sleep(10 * k)
        cat("---- retry", k, ":", paste(still(), collapse = " "), "\n")
        acc$notes <- character()
        install(still(), "source")
        k <- k + 1L
      }
      acc$notes
    }, args = list(pkgs = missing, lib = env$lib, bioc = bioc_version, cran = env$cran, tries = tries,
                   env_name = env$name),
    libpath = bench_libpaths(env), timeout = 3600, stdout = out, stderr = "2>&1")
  }
  ok <- installed_anywhere(pkgs, env)
  status <- ifelse(!pkgs %in% missing, "present", ifelse(ok, "installed", "failed"))
  data.frame(package = pkgs, status = status,
             reason = ifelse(status == "failed", vapply(pkgs, install_reason, "", notes = notes), ""),
             stringsAsFactors = FALSE, row.names = NULL)
}

# ---- data vendoring ----------------------------------------------------------

data_ext <- "\\.(csv|txt|tsv|dat|json|geojson|xlsx?|rds|rda|RData|zip|gz|shp|dbf|shx|prj|xml|sav|dta)$"

# Replace a quoted literal by the vendored file's relative path. On a line that
# calls download.file() the literal must stay a URL, so it becomes file://<rel>
# (download.file() opens relative file:// URLs; a bare path it cannot fetch).
rewrite_literal <- function(chunks, lit, rel) {
  q <- substr(lit, 1, 1)
  lapply(chunks, function(x) {
    dl <- grepl("download\\.file\\(", x)
    x[dl] <- gsub(lit, paste0(q, "file://", rel, q), x[dl], fixed = TRUE)
    x[!dl] <- gsub(lit, paste0(q, rel, q), x[!dl], fixed = TRUE)
    x
  })
}

# A shapefile is read together with its sidecar files of the same name.
shp_sidecars <- c("shx", "dbf", "prj", "cpg")

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
    companions <- list()
    if (grepl("\\.shp$", dest, ignore.case = TRUE)) {
      for (ext in shp_sidecars) {
        u2 <- sub("\\.shp([?#].*)?$", paste0(".", ext, "\\1"), url, ignore.case = TRUE)
        d2 <- sub("\\.shp$", paste0(".", ext), dest, ignore.case = TRUE)
        s2 <- system2("curl", c("-sS", "-L", "--fail", "--max-time", "300", "-o", shQuote(d2), shQuote(u2)),
                      stdout = FALSE, stderr = FALSE)
        if (s2 == 0 && file.exists(d2)) {
          companions[[length(companions) + 1]] <- list(url = u2, file = file.path("data", basename(d2)),
                                                       bytes = file.size(d2), md5 = md5(d2))
        } else unlink(d2)
      }
    }
    rewrites[[length(rewrites) + 1]] <- list(literal = target, url = url, file = rel, ok = TRUE,
                                             bytes = file.size(dest), md5 = md5(dest), companions = companions)
    chunks <- rewrite_literal(chunks, lit, rel)
  }
  list(chunks = chunks, rewrites = rewrites)
}

# ---- the worker ----------------------------------------------------------------

# Runs inside a fresh R process. Self-contained: callr ships only this function.
run_worker <- function(setup, chunks, dir, seed, figure_classes, skip_print, recover, capture, repo,
                       device = "pdf", fidelity_verdict = NULL) {
  setwd(dir)
  set.seed(seed)
  # The device the code draws on. "svg" (capture runs) is gloss's own device,
  # svglite, 7 x 5 in like gloss's default: a grob built while the code runs
  # (ggplot titles, legends) carries the measurements of the device open at
  # the time, so a grid.grab() made on pdf(NULL) and drawn by gloss on svglite
  # mixed two devices' text metrics (bench run 2026-11-10-1131, exts-007).
  # Its last page is also the reference the captured scene is compared with.
  devs <- new.env()
  new_dev <- function() {
    if (identical(device, "svg")) {
      devs$svg_pages <- svglite::svgstring(width = 7, height = 5, standalone = TRUE)
      devs$num <- grDevices::dev.cur()
    } else grDevices::pdf(NULL, width = 7, height = 5)
  }
  # knitr::include_graphics() of an image shipped with a vignette's sources but
  # not with the installed package draws nothing; as in the vignette's own
  # build, where the file exists, it must not stop the run
  options(warn = 0, device = function(...) new_dev(), knitr.graphics.error = FALSE)
  open_dev <- function() {
    new_dev()
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
      v <- res$value
      cls <- paste(class(v), collapse = " ")
      # print a visible value, as the top level and knitr do: lattice and
      # others draw only then, and a ggplot's own errors surface only then
      if (res$visible && !is.null(v) && !grepl(skip_print, cls)) {
        pr <- tryCatch({
          if (isS4(v)) methods::show(v) else print(v)
          NULL
        }, error = function(e) e)
        if (inherits(pr, "error")) {
          err <- list(chunk = i, expr = j, stage = "print", message = conditionMessage(pr))
          break
        }
      }
      if (grDevices::dev.cur() == 1L) open_dev()
      e <- exprs[[j]]
      fn <- if (is.call(e)) paste(deparse(e[[1]]), collapse = "") else ""
      fn <- sub("^.*::", "", fn)
      last_obj <- inherits(v, figure_classes) && (res$visible || fn %in% printer)
      last_value <- if (last_obj) v else NULL
      if (res$visible && !last_obj && !is.null(v)) out_classes <- c(out_classes, cls)
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
  # what the code drew, as svglite draws it: its last page, read before
  # recovery (grid.grab() draws on the device). An open svglite page leaves
  # its clip groups open, so the missing </g> are added before </svg>; where
  # recovery draws nothing, that page is compared with the closed one.
  close_groups <- function(x) {
    open_g <- lengths(regmatches(x, gregexpr("<g[ >]", x))) - lengths(regmatches(x, gregexpr("</g>", x)))
    if (open_g <= 0L) return(x)
    sub("</svg>\\s*$", paste0(strrep("</g>\n", open_g), "</svg>\n"), x)
  }
  pre_pages <- if (!is.null(devs$svg_pages)) as.character(devs$svg_pages())
  closed_page <- NULL
  ref_page <- if (length(pre_pages)) close_groups(pre_pages[length(pre_pages)])
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
    if (!is.null(devs$svg_pages)) {
      untouched <- identical(as.character(devs$svg_pages()), pre_pages)
      if (devs$num %in% grDevices::dev.list()) grDevices::dev.off(devs$num)
      pg <- as.character(devs$svg_pages())
      closed_page <- if (untouched && length(pg)) pg[length(pg)] else NULL
      result$reference <- list(pages = length(pg), untouched = untouched, same_as_closed = NA)
    }
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
        # which unowned elements are the device background: the first element,
        # a rect covering the whole viewBox (prediction 8); tags of the others
        un <- s$elements[is.na(s$elements$leaf), , drop = FALSE]
        vb <- regmatches(s$scene, regexpr("viewBox=['\"][-0-9. ]+['\"]", s$scene))
        # no viewBox: the test answers NA, it must never fail the capture record
        vb <- if (length(vb)) suppressWarnings(as.numeric(strsplit(trimws(gsub("[^-0-9. ]", "", vb[1])), " +")[[1]])) else numeric()
        if (length(vb) == 4L && !anyNA(vb)) {
          bg <- un$id == "e1" & un$tag == "rect" & un$x0 <= vb[1] + 0.5 & un$y0 <= vb[2] + 0.5 &
            un$x1 >= vb[1] + vb[3] - 0.5 & un$y1 >= vb[2] + vb[4] - 0.5
          bg[is.na(bg)] <- FALSE
          cap$unowned_bg <- sum(bg)
          cap$unowned_other <- paste(utils::head(un$tag[!bg], 20), collapse = " ")
        } else {
          cap$unowned_bg <- NA_integer_
          cap$unowned_other <- NA_character_
        }
        # fidelity: the captured scene draws exactly what the code drew on
        # svglite (tag, attributes and text of every primitive, in order).
        # The strict verdict is kept in `faithful`; known exceptions are
        # classified from the diff itself, with the differing primitives
        # recorded as evidence. Nothing is silently tolerated.
        if (!is.null(ref_page) && !is.na(ref_page)) {
          sig <- get("scene_signatures", asNamespace("gloss"))
          if (!is.null(closed_page))
            result$reference$same_as_closed <- isTRUE(tryCatch(identical(sig(ref_page), sig(closed_page)), error = function(e) FALSE))
          a <- tryCatch(sig(s$scene), error = function(e) NULL)
          b <- tryCatch(sig(ref_page), error = function(e) NULL)
          if (!is.null(a) && !is.null(b)) {
            cap$faithful <- identical(a, b)
            cap$prims_scene <- length(a); cap$prims_ref <- length(b)
            # primitives without a match in the other scene, either way (a
            # multiset difference: one inserted element does not shift the rest)
            ta <- table(a); tb <- table(b); common <- intersect(names(ta), names(tb))
            cap$prims_differ <- length(a) + length(b) - 2L * sum(pmin(ta[common], tb[common]))
            only_a <- setdiff(names(ta), names(tb)); only_b <- setdiff(names(tb), names(ta))
            cap$diff_scene_n <- length(only_a); cap$diff_ref_n <- length(only_b)
            cap$diff_scene <- paste(substr(utils::head(only_a, 3L), 1L, 110L), collapse = " | ")
            cap$diff_ref <- paste(substr(utils::head(only_b, 3L), 1L, 110L), collapse = " | ")
            cap$dense_leaves <- sum(s$leaves$dense %in% TRUE)
            bad <- s$leaves[which(s$leaves$status == "count_mismatch"), , drop = FALSE]
            cap$mismatch_leaves <- if (nrow(bad))
              paste(utils::head(substr(paste0(bad$id, ":", bad$name), 1L, 40L), 20L), collapse = " ") else ""
            v <- fidelity_verdict(cap)
            cap$verdict <- v$verdict; cap$exception <- v$exception
          }
        }
      }
      result$capture <- cap
    }
  }
  result
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# ---- capture fidelity -------------------------------------------------------

# Pure function, shipped into the worker as an argument (callr sends only
# run_worker itself). Classify a strict primitive difference from the diff,
# never from the engine. Known exceptions: a leaf rasterized by design (the
# scene holds an <image>, the reference its primitives) and gridGraphics'
# one extra "graphics-background" rect when a recorded base plot is echoed on
# svglite. Everything else stays "different", with the diff recorded.
fidelity_verdict <- function(cap) {
  nvl <- function(x, d) if (is.null(x)) d else x
  if (isTRUE(cap$faithful)) return(list(verdict = "equal", exception = NA_character_))
  if (nvl(cap$dense_leaves, 0L) > 0L) return(list(
    verdict = "known_exception",
    exception = sprintf("%d dense leaf drawn as a raster by design", nvl(cap$dense_leaves, 0L))))
  one_rect <- isTRUE(cap$prims_differ == 1) &&
    isTRUE(cap$diff_scene_n == 1) && isTRUE(cap$diff_ref_n == 0) &&
    nvl(cap$prims_scene, 0) == nvl(cap$prims_ref, 0) + 1 &&
    startsWith(nvl(cap$diff_scene, ""), "rect ")
  if (one_rect) return(list(
    verdict = "known_exception",
    exception = "gridGraphics background rect: one extra rect, nothing missing"))
  list(verdict = "different", exception = NA_character_)
}

offline_env <- c(http_proxy = "http://127.0.0.1:9", https_proxy = "http://127.0.0.1:9",
                 HTTP_PROXY = "http://127.0.0.1:9", HTTPS_PROXY = "http://127.0.0.1:9",
                 ALL_PROXY = "http://127.0.0.1:9", no_proxy = "", NO_PROXY = "")

run_script <- function(script, dir, seed, timeout = 300, offline = FALSE,
                       recover = FALSE, capture = FALSE, device = "pdf") {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  env <- c(callr::rcmd_safe_env(), R_LIBS_USER = paste(bench_libpaths(), collapse = .Platform$path.sep))
  if (offline) env <- c(env, offline_env)
  res <- tryCatch(
    callr::r(run_worker,
             args = list(setup = script$setup, chunks = script$chunks, dir = normalizePath(dir),
                         seed = seed, figure_classes = figure_classes, skip_print = outside_classes,
                         recover = recover,
                         capture = capture, repo = normalizePath("."), device = device,
                         fidelity_verdict = fidelity_verdict),
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
