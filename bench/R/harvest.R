# Harvest and eligibility (bench v0, Task 4). Run from the repository root:
#   Rscript bench/R/harvest.R            # every sampled PSU without an outcome yet
#   Rscript bench/R/harvest.R gallery-001 heatmap-012
# For each PSU: install what it needs into the bench library, vendor URL data,
# run it online to find its figures, choose one at random (seeded by the id),
# freeze the code up to that figure into bench/figures/<id>/, and rerun the
# frozen copy with the network blocked. One outcome row per PSU goes to
# bench/runs/attempts.csv. This executes third-party code (Gallery posts,
# package examples, vignettes) in subprocesses.

source("bench/R/runner.R")

attempts_file <- file.path(bench_root, "runs", "attempts.csv")
figures_root <- file.path(bench_root, "figures")
work_root <- file.path(cache_root, "work")
stratum_engine <- c(patchwork = "patchwork", heatmap = "heatmap")
# Strata whose figures are told by what the figure holds, not by its engine
# (bench v1): in the tree stratum a figure counts when it is a ggtree plot or
# a patchwork holding one (the worker's `tree`). Every figure a PSU of such a
# stratum drew is listed in runs/tree-candidates.csv, counted or not.
stratum_tree <- "tree"
tree_candidates_file <- file.path(bench_root, "runs", "tree-candidates.csv")
# files a book chapter reads from the book's repository, besides data_ext
book_ext <- sub("\\)\\$$", "|nex|nwk|newick|tree|tre|fas|fasta|phy|png|jpe?g|svg|pdf)$", data_ext)
max_topics <- 8L

missing_package_re <- paste(
  "there is no package called|is not available|could not find function \"(library|require)",
  "Required packages? (is|are) missing", "[Pp]ackages? [‘'\"][^’'\"]+[’'\"] (is|are) (required|needed)",
  sep = "|")

classify_failure <- function(err, install_failed = character()) {
  if (length(install_failed)) return("missing package")
  if (is.null(err)) return("no figure")
  msg <- err$message
  if (identical(err$stage, "timeout")) return("timeout")
  if (identical(err$stage, "parse")) return("parse error")
  if (grepl(missing_package_re, msg)) return("missing package")
  # a relative path handed to url() or download.file() is missing data, not network
  if (grepl("cannot open URL '(?!(https?|ftp)://)", msg, perl = TRUE)) return("missing data")
  if (grepl("resolve host|Failed to connect|Couldn't connect|cannot open URL|proxy|SSL|HTTP error|HTTP [45][0-9][0-9]|Timeout was reached|internet|curl_fetch|download.*fail", msg, ignore.case = TRUE)) return("needs network")
  if (grepl("cannot open (file|the connection|\")|No such file|does not exist|not found in.*path", msg, ignore.case = TRUE)) return("missing data")
  "code error"
}

outside_population <- function(out_classes) any(grepl(outside_classes, out_classes))

# Packages an error message says are needed but absent (base R, caret, rlang).
packages_in_error <- function(msg) {
  if (is.null(msg) || !length(msg) || is.na(msg)) return(character())
  name <- "([A-Za-z][A-Za-z0-9.]*[A-Za-z0-9])"
  pats <- c(paste0("there is no package called [‘'\"]", name, "[’'\"]"),
            paste0("[Pp]ackages? [‘'\"]", name, "[’'\"] (?:is|are) (?:required|needed)"))
  out <- unlist(lapply(pats, function(p) {
    m <- regmatches(msg, gregexpr(p, msg, perl = TRUE))[[1]]
    sub(p, "\\1", m, perl = TRUE)
  }))
  caret <- regmatches(msg, regexpr("Required packages? (?:is|are) missing: [A-Za-z0-9., ]+", msg, perl = TRUE))
  if (length(caret)) out <- c(out, trimws(strsplit(sub("^.*missing: ", "", caret), ",")[[1]]))
  unique(out[nzchar(out)])
}

# Outcome of a PSU that gave no figure of its stratum, from its last run (NULL
# if nothing ran), the packages that failed to install and their reasons.
# "Outside population" only for a clean run that drew nothing on the device and
# showed a widget or a table: a run that stopped is classified by its error
# (a vignette that prints a table and then fails before its figures is a code
# error), and a run that drew figures of another engine is "no figure" of the
# stratum's engine. Widget or table output is named in the detail either way.
psu_outcome <- function(last, failed, note = "", install_detail = "", tree = FALSE) {
  if (is.null(last)) {
    return(list(outcome = if (length(failed)) "missing package" else "no code",
                detail = if (length(failed)) install_detail else note))
  }
  err <- last$error
  shown <- unique(grep(outside_classes, last$out_classes, value = TRUE))
  shown <- if (length(shown)) paste(shown, collapse = ", ") else ""
  if (!length(failed) && is.null(err) && !nrow(last$candidates) && nzchar(shown)) {
    return(list(outcome = "outside population", detail = shown))
  }
  detail <- if (!is.null(err)) paste(err$stage, err$message) else if (nrow(last$candidates)) {
    # ran cleanly, but its figures are not of the stratum's engine (or, in the
    # tree stratum, hold no tree: then their classes say what they are)
    n <- table(if (tree) last$candidates$class else last$candidates$engine)
    paste(if (tree) "figures holding no tree:" else "figures of other engines:", paste(names(n), n, sep = " x", collapse = ", "))
  } else "ran without error, no figure"
  if (nzchar(shown)) detail <- paste0(detail, " (also shown: ", shown, ")")
  if (length(failed)) detail <- paste0(install_detail, " | run: ", detail)
  list(outcome = classify_failure(err, failed), detail = detail)
}

# Run a script; if it stops because a package is absent that the static scan
# did not see (a Suggests of a package it uses), install that and run again.
run_installing <- function(s, work_dir, seed, timeout, pkgs, rounds = 3L) {
  for (k in seq_len(rounds)) {
    r <- run_script(s, work_dir, seed = seed, timeout = timeout)
    need <- setdiff(packages_in_error(r$error$message), pkgs$package)
    if (!length(need)) break
    st <- ensure_packages(need)
    pkgs <- rbind(pkgs, st)
    if (!any(st$status == "installed")) break
  }
  list(run = r, pkgs = pkgs)
}

# Write code.R, data/ and meta.json for one chosen figure.
freeze_figure <- function(id, script, cand, work_dir, meta) {
  dir <- file.path(figures_root, id)
  unlink(dir, recursive = TRUE)
  dir.create(dir, recursive = TRUE)
  chunks <- truncate_script(script, cand$chunk, cand$expr)
  body <- unlist(Map(function(code, i) c(sprintf("# ---- chunk %d ----", i), code), chunks, seq_along(chunks)))
  nbsp_n <- script$nbsp %||% 0L
  header <- c(sprintf("# gloss bench figure %s", id),
              sprintf("# source: %s (%s)", meta$psu, meta$kind),
              "# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.",
              if (nbsp_n > 0) sprintf("# %d no-break space(s) (U+00A0) in the source replaced by spaces.", nbsp_n),
              if (length(script$setup)) c("# ---- setup ----", script$setup))
  writeLines(c(header, body), file.path(dir, "code.R"), useBytes = TRUE)
  used <- Filter(function(r) isTRUE(r$ok), meta$rewrites)
  for (r in used) {
    if (any(grepl(r$file, unlist(chunks), fixed = TRUE))) {
      dir.create(file.path(dir, "data"), showWarnings = FALSE)
      for (f in c(r$file, vapply(r$companions %||% list(), `[[`, "", "file")))
        file.copy(file.path(work_dir, f), file.path(dir, f), overwrite = TRUE)
    }
  }
  meta$nbsp_replaced <- nbsp_n
  meta$figure <- as.list(cand)
  meta$seed <- seed_for(id)
  jsonlite::write_json(meta, file.path(dir, "meta.json"), auto_unbox = TRUE, pretty = TRUE, null = "null")
  dir
}

frozen_script <- function(dir) list(setup = character(), chunks = list(readLines(file.path(dir, "code.R"), warn = FALSE)))

# A fresh run directory holding a copy of the frozen data (paths in code.R are relative).
prepare_run_dir <- function(fig_dir) {
  run_dir <- file.path(work_root, "eligibility", basename(fig_dir))
  unlink(run_dir, recursive = TRUE)
  dir.create(run_dir, recursive = TRUE)
  if (dir.exists(file.path(fig_dir, "data"))) file.copy(file.path(fig_dir, "data"), run_dir, recursive = TRUE)
  run_dir
}

# Rerun a frozen figure with the network blocked; the recovered engine must match.
# The environment a frozen figure was harvested in (meta.json), else its stratum's.
figure_env <- function(meta) {
  name <- meta$environment$name %||% env_for_stratum(meta$stratum %||% "")$name
  if (is.null(bench_envs[[name]])) stop("unknown package environment ", name, " in meta.json")
  bench_envs[[name]]
}

# A capture run draws on svglite, gloss's device (see run_worker); the
# eligibility checks keep pdf(NULL), as at the freeze.
check_eligibility <- function(dir, engine, timeout = 300, capture = FALSE, device = if (capture) "svg" else "pdf",
                              bind = FALSE, keep = NULL) {
  meta <- jsonlite::read_json(file.path(dir, "meta.json"))
  use_env(figure_env(meta))
  r <- run_script(frozen_script(dir), prepare_run_dir(dir), seed = meta$seed, timeout = timeout,
                  offline = TRUE, recover = TRUE, capture = capture, device = device, bind = bind,
                  keep = keep)
  list(ok = is.null(r$error) && identical(r$recovered$engine, engine), run = r)
}

build_script <- function(row, work_dir) {
  pkgs_status <- data.frame(package = character(), status = character(), reason = character())
  rewrites <- list()
  if (row$kind == "gallery") {
    script <- gallery_script(row$psu)
    pkgs_status <- ensure_packages(code_packages(unlist(script$chunks)))
    v <- vendor_data(script$chunks, work_dir, gallery = TRUE)
    script$chunks <- v$chunks; rewrites <- v$rewrites
    return(list(scripts = list(script), pkgs = pkgs_status, rewrites = rewrites))
  }
  if (row$kind == "topic") {
    pkg <- sub("::.*$", "", row$psu); topic <- sub("^.*::", "", row$psu)
    pkgs_status <- ensure_packages(pkg)
    script <- topic_script(pkg, topic)
    pkgs_status <- rbind(pkgs_status, ensure_packages(code_packages(unlist(script$chunks))))
    return(list(scripts = list(script), pkgs = pkgs_status, rewrites = rewrites))
  }
  if (row$kind == "examples") {
    pkgs_status <- ensure_packages(row$psu)
    if (any(pkgs_status$status == "failed")) return(list(scripts = list(), pkgs = pkgs_status, rewrites = rewrites))
    topics <- package_topics(row$psu)
    set.seed(seed_for(row$id))
    topics <- topics[sample.int(length(topics))][seq_len(min(max_topics, length(topics)))]
    scripts <- lapply(topics, function(t) topic_script(row$psu, t))
    pkgs_status <- rbind(pkgs_status, ensure_packages(code_packages(unlist(lapply(scripts, `[[`, "chunks")))))
    return(list(scripts = scripts, pkgs = pkgs_status, rewrites = rewrites))
  }
  if (row$kind == "vignette") {
    pkgs_status <- ensure_packages(row$psu)
    if (any(pkgs_status$status == "failed")) return(list(scripts = list(), pkgs = pkgs_status, rewrites = rewrites))
    vigs <- vignette_files(row$psu)
    if (!nrow(vigs)) return(list(scripts = list(), pkgs = pkgs_status, rewrites = rewrites, note = "no installed vignette"))
    set.seed(seed_for(row$id))
    vig <- vigs[sample.int(nrow(vigs), 1), ]
    script <- vignette_script(row$psu, vig)
    pkgs_status <- rbind(pkgs_status, ensure_packages(code_packages(unlist(script$chunks))))
    v <- vendor_data(script$chunks, work_dir)
    script$chunks <- v$chunks; rewrites <- v$rewrites
    return(list(scripts = list(script), pkgs = pkgs_status, rewrites = rewrites, vignette = vig$file))
  }
  if (row$kind == "book") {
    script <- book_script(row$psu)
    pkgs_status <- ensure_packages(code_packages(c(script$setup, unlist(script$chunks))))
    v <- vendor_data(script$chunks, work_dir, base = sources$treebook$raw, data_ext = book_ext)
    script$chunks <- v$chunks; rewrites <- v$rewrites
    return(list(scripts = list(script), pkgs = pkgs_status, rewrites = rewrites))
  }
  stop("unknown kind ", row$kind)
}

harvest_psu <- function(row) {
  t0 <- Sys.time()
  work_dir <- file.path(work_root, "harvest", row$id)
  unlink(work_dir, recursive = TRUE); dir.create(work_dir, recursive = TRUE)
  out <- data.frame(id = row$id, stratum = row$stratum, kind = row$kind, psu = row$psu,
                    outcome = NA_character_, detail = "", n_figures = 0L, chunk = NA_integer_, expr = NA_integer_,
                    engine = NA_character_, class = NA_character_, missing_packages = "", seconds = NA_real_,
                    stringsAsFactors = FALSE)
  b <- tryCatch(build_script(row, work_dir), error = function(e) list(error = conditionMessage(e)))
  if (!is.null(b$error)) { out$outcome <- "setup error"; out$detail <- b$error; return(out) }
  timeout <- if (row$kind %in% c("vignette", "book")) 900 else 300
  chosen <- NULL; last <- NULL; script <- NULL; n_fig <- 0L
  for (s in b$scripts) {
    ri <- run_installing(s, work_dir, seed = seed_for(row$id), timeout = timeout, pkgs = b$pkgs)
    r <- ri$run
    b$pkgs <- ri$pkgs
    last <- r
    cand <- r$candidates
    if (!is.na(stratum_engine[row$stratum])) cand <- cand[cand$engine == stratum_engine[row$stratum], , drop = FALSE]
    if (row$stratum %in% stratum_tree) {
      if (nrow(cand)) {
        all_cand <- cbind(id = row$id, cand)
        old <- if (file.exists(tree_candidates_file)) read_csv(tree_candidates_file) else all_cand[0, ]
        write_csv(rbind(old[old$id != row$id, ], all_cand), tree_candidates_file)
      }
      cand <- cand[cand$tree %in% TRUE, , drop = FALSE]
    }
    n_fig <- n_fig + nrow(cand)
    if (nrow(cand)) {
      set.seed(seed_for(row$id))
      chosen <- cand[sample.int(nrow(cand), 1), ]
      script <- s
      break
    }
  }
  out$n_figures <- n_fig
  fail <- b$pkgs[b$pkgs$status == "failed", , drop = FALSE]
  failed <- unique(fail$package)
  out$missing_packages <- paste(failed, collapse = " ")
  if (is.null(chosen)) {
    o <- psu_outcome(last, failed, note = b$note %||% "",
                     install_detail = paste(fail$package, fail$reason, sep = ": ", collapse = "; "),
                     tree = row$stratum %in% stratum_tree)
    out$outcome <- o$outcome
    out$detail <- substr(o$detail, 1, 300)
    out$seconds <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    return(out)
  }
  meta <- list(id = row$id, stratum = row$stratum, kind = row$kind, psu = row$psu,
               vignette = b$vignette %||% NULL, rewrites = b$rewrites,
               environment = list(name = active_env()$name, cran = active_env()$cran, bioconductor = bioc_version),
               packages = b$pkgs, harvested = format(Sys.time(), tz = "UTC", usetz = TRUE))
  fig_dir <- freeze_figure(row$id, script, chosen, work_dir, meta)
  e <- check_eligibility(fig_dir, chosen$engine)
  # a figure of the tree stratum must come back holding its tree
  if (row$stratum %in% stratum_tree && e$ok && !isTRUE(e$run$recovered$tree)) e$ok <- FALSE
  out[c("chunk", "expr", "engine", "class")] <- chosen[c("chunk", "expr", "engine", "class")]
  if (e$ok) {
    out$outcome <- "retained"
  } else {
    out$outcome <- if (!is.null(e$run$error)) paste("offline:", classify_failure(e$run$error)) else "offline: figure not recovered"
    out$detail <- substr(paste(e$run$error$stage, e$run$error$message, e$run$recovered$engine), 1, 300)
    unlink(fig_dir, recursive = TRUE)
  }
  out$seconds <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  out
}

if (sys.nframe() == 0L) {
  smp <- read_csv(file.path(bench_root, "sample.csv"))
  args <- commandArgs(trailingOnly = TRUE)
  done <- if (file.exists(attempts_file)) read_csv(attempts_file)$id else character()
  todo <- if (length(args)) smp[smp$id %in% args, ] else smp[!smp$id %in% done, ]
  dir.create(dirname(attempts_file), showWarnings = FALSE)
  for (k in seq_len(nrow(todo))) {
    row <- todo[k, ]
    use_env(env_for_stratum(row$stratum))
    res <- tryCatch(harvest_psu(row), error = function(e) data.frame(
      id = row$id, stratum = row$stratum, kind = row$kind, psu = row$psu, outcome = "harness error",
      detail = conditionMessage(e), n_figures = 0L, chunk = NA, expr = NA, engine = NA, class = NA,
      missing_packages = "", seconds = NA))
    prev <- if (file.exists(attempts_file)) read_csv(attempts_file) else NULL
    prev <- prev[!prev$id %in% res$id, , drop = FALSE]
    all <- rbind(prev, res)
    write_csv(all[order(match(all$id, smp$id)), ], attempts_file)
    cat(sprintf("[%d/%d] %s %s: %s %s\n", k, nrow(todo), res$id, res$psu, res$outcome, substr(res$detail, 1, 80)))
  }
}
