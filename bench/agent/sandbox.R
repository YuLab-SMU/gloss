# Condition A's sandbox (agent-path plan 2026-11-12, Task 4): R code that a
# model wrote, run in the bench container.
#
#   source("bench/agent/sandbox.R")              # the functions, from the repository root
#   Rscript bench/agent/sandbox.R --dry          # self-check: what the sandbox can and cannot do
#
# One sandbox serves one run of one model on one figure. It is a fresh copy
# of the figure's material, mounted as the working directory /work; each
# call is a new R process in a new container, so only files in /work last
# from one call to the next. The container has
#   - no network (--network none),
#   - a read-only root file system; /work and /tmp are the only places it can write,
#   - the bench's package library of the figure's environment, read-only,
#   - none of the host's environment (docker passes none; the gateway's key
#     never reaches it), and not the repository,
#   - limits on memory, CPUs, processes and time.
# The material itself is never written: the copy is thrown away with the run.

sandbox_cache <- function() path.expand(Sys.getenv("GLOSS_BENCH_CACHE", "~/.cache/gloss-bench"))
sandbox_image <- function() readLines(file.path("bench", "docker", "image"), warn = FALSE)[1]

# The container's library of one package environment ("cran" or "bioc"), as
# the path the container sees. The bench keeps one per platform and R version.
sandbox_lib <- function(env = c("cran", "bioc")) {
  env <- match.arg(env)
  top <- if (env == "bioc") "lib-bioc" else "lib"
  found <- Sys.glob(file.path(sandbox_cache(), top, "*linux*", "*"))
  if (length(found) != 1L) stop("expected one Linux library under ", file.path(sandbox_cache(), top), ", found ", length(found))
  file.path("/cache", top, basename(dirname(found)), basename(found))
}

# A sandbox over a fresh copy of `material` (a directory).
sandbox_open <- function(material, env = "cran") {
  stopifnot(dir.exists(material))
  work <- tempfile("gloss-sandbox-")
  dir.create(work)
  files <- list.files(material, all.files = TRUE, no.. = TRUE, full.names = TRUE)
  if (length(files)) file.copy(files, work, recursive = TRUE, copy.date = TRUE)
  list(work = normalizePath(work), lib = sandbox_lib(env), env = env, calls = 0L)
}

sandbox_close <- function(sb) invisible(unlink(sb$work, recursive = TRUE))

# Head and tail of an output longer than `limit` characters.
sandbox_clip <- function(text, limit) {
  n <- nchar(text)
  if (n <= limit) return(list(text = text, clipped = FALSE))
  head_n <- floor(limit * 2 / 3)
  tail_n <- limit - head_n
  list(text = paste0(substr(text, 1L, head_n), sprintf("\n[... %d characters left out ...]\n", n - limit),
                     substr(text, n - tail_n + 1L, n)), clipped = TRUE)
}

# Run `code` (R, as one script) in the sandbox. Returns what R printed, both
# streams together and clipped to `limit` characters, the exit status and
# whether the time ran out. Never raises for anything the code does.
sandbox_memory <- "6g"   # a figure's own code must run: one vignette of the pilot needs more than 2 GB

sandbox_run <- function(sb, code, timeout = 60, limit = 6000) {
  n <- length(list.files(sb$work, pattern = "^\\.call-[0-9]+\\.R$", all.files = TRUE)) + 1L
  call_file <- sprintf(".call-%03d.R", n)
  writeLines(enc2utf8(as.character(code)), file.path(sb$work, call_file), useBytes = TRUE)
  cache <- sandbox_cache()
  args <- c(
    "run", "--rm", "--network", "none", "--read-only", "--tmpfs", "/tmp:rw,exec,size=512m",
    "--memory", sandbox_memory, "--memory-swap", sandbox_memory, "--cpus", "2", "--pids-limit", "256",
    "--security-opt", "no-new-privileges",
    "-v", paste0(sb$work, ":/work"),
    "-v", paste0(file.path(cache, "lib"), ":/cache/lib:ro"),
    "-v", paste0(file.path(cache, "lib-bioc"), ":/cache/lib-bioc:ro"),
    "-e", paste0("R_LIBS_USER=", sb$lib), "-e", "HOME=/tmp", "-e", "TMPDIR=/tmp", "-e", "LANG=C.UTF-8",
    "-w", "/work", sandbox_image(),
    "timeout", "-k", "5", as.character(as.integer(timeout)),
    "Rscript", "--no-init-file", "--no-save", "--no-restore", call_file
  )
  t0 <- Sys.time()
  out <- tryCatch(suppressWarnings(system2("docker", shQuote(args), stdout = TRUE, stderr = TRUE, timeout = timeout + 60)),
                  error = function(e) structure(conditionMessage(e), status = -1L))
  seconds <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  status <- attr(out, "status") %||% 0L
  # 124: `timeout` ended the code; 137: it was killed, by `timeout -k` after
  # the limit or, before the limit, by the container for the memory it took
  timed_out <- status == 124L || (status == 137L && seconds >= timeout)
  killed <- status == 137L && !timed_out
  text <- paste(out, collapse = "\n")
  if (timed_out) text <- paste0(text, sprintf("\n[stopped: the code ran longer than %d s]", as.integer(timeout)))
  if (killed) text <- paste0(text, sprintf("\n[stopped: the code was killed, most likely for using more memory than the sandbox has (%s)]", sandbox_memory))
  clip <- sandbox_clip(text, limit)
  list(output = clip$text, status = as.integer(status), timed_out = timed_out, killed = killed, clipped = clip$clipped,
       seconds = round(seconds, 2), call = n)
}

# ---- persistent analysis sandbox --------------------------------------------

# The original pilot API above copies a material into /work.  The binding
# prototype keeps public material on a separate read-only mount and gives the
# analysis process a persistent scratch directory.  A new process is used for
# each call, while the session state (files and call count) persists.

sandbox_tree_hash <- function(path) {
  files <- sort(list.files(path, recursive = TRUE, all.files = TRUE, full.names = TRUE))
  files <- files[file.info(files)$isdir %in% FALSE]
  if (!length(files)) return(digest::digest(character(), algo = "sha256"))
  rel <- sub(paste0("^", normalizePath(path, mustWork = FALSE), "/?"), "", normalizePath(files, mustWork = FALSE))
  sums <- vapply(files, digest::digest, "", algo = "sha256", serialize = FALSE)
  digest::digest(paste(rel, sums, sep = "=", collapse = "\n"), algo = "sha256", serialize = FALSE)
}

sandbox_open_persistent <- function(material, env = "cran") {
  stopifnot(dir.exists(material))
  public <- normalizePath(material, mustWork = TRUE)
  work <- tempfile("gloss-analysis-")
  dir.create(work, recursive = TRUE)
  e <- new.env(parent = emptyenv())
  e$public <- public
  e$work <- normalizePath(work)
  e$lib <- sandbox_lib(env)
  e$env <- env
  e$calls <- 0L
  e$resets <- 0L
  e$public_hash <- sandbox_tree_hash(public)
  e$closed <- FALSE
  e
}

sandbox_reset <- function(sb, reason = "analysis session reset") {
  sb$resets <- as.integer(sb$resets %||% 0L) + 1L
  sb$last_reset <- list(reason = as.character(reason), time = format(Sys.time(), tz = "UTC"))
  invisible(sb)
}

sandbox_close_persistent <- function(sb) {
  if (isTRUE(sb$closed)) return(invisible(NULL))
  unlink(sb$work, recursive = TRUE)
  sb$closed <- TRUE
  invisible(NULL)
}

sandbox_analysis_clip <- function(text, limit) {
  sandbox_clip(as.character(text %||% ""), limit)
}

sandbox_run_analysis <- function(sb, code, timeout = 60, limit = 6000) {
  if (!is.environment(sb) || isTRUE(sb$closed)) stop("analysis sandbox is closed")
  if (!(is.character(code) && length(code) == 1L)) stop("analysis code must be one string")
  sb$calls <- as.integer(sb$calls) + 1L
  call <- sb$calls
  file <- sprintf(".analysis-%03d.R", call)
  call_file <- file.path(sb$work, file)
  writeLines(enc2utf8(code), call_file, useBytes = TRUE)
  status_file <- sprintf(".analysis-%03d.status", call)
  stdout_file <- tempfile("gloss-analysis-stdout-")
  stderr_file <- tempfile("gloss-analysis-stderr-")
  args <- c(
    "run", "--rm", "--network", "none", "--read-only", "--tmpfs", "/tmp:rw,exec,size=512m",
    "--memory", sandbox_memory, "--memory-swap", sandbox_memory, "--cpus", "2", "--pids-limit", "256",
    "--security-opt", "no-new-privileges", "-v", paste0(sb$public, ":/material:ro"),
    "-v", paste0(sb$work, ":/work"), "-v", paste0(file.path(sandbox_cache(), "lib"), ":/cache/lib:ro"),
    "-v", paste0(file.path(sandbox_cache(), "lib-bioc"), ":/cache/lib-bioc:ro"),
    "-e", paste0("R_LIBS_USER=", sb$lib), "-e", "HOME=/tmp", "-e", "TMPDIR=/tmp",
    "-e", "LANG=C.UTF-8", "-e", "GLOSS_MATERIAL_DIR=/material", "-e", "GLOSS_SCRATCH_DIR=/work",
    "-w", "/work", sandbox_image(), "sh", "-c",
    sprintf("timeout -k 5 %s Rscript --no-init-file --no-save --no-restore %s; s=$?; printf '__GLOSS_STATUS=%%s\\n' \"$s\" > %s; exit \"$s\"",
            as.character(as.integer(timeout)), shQuote(file), shQuote(status_file))
  )
  t0 <- Sys.time()
  status <- 0L
  err <- NULL
  tryCatch({
    result <- system2("docker", shQuote(args), stdout = stdout_file, stderr = stderr_file,
                      timeout = timeout + 60L)
    status <<- as.integer(attr(result, "status") %||% if (length(result)) result[[length(result)]] else 0L)
  }, error = function(e) {
    err <<- conditionMessage(e)
    status <<- -1L
  })
  # system2() exposes the child's status as an attribute on some R builds and
  # as its last integer result on others.  Both are handled above.
  if (file.exists(stdout_file) && file.exists(stderr_file)) {
    stdout <- paste(readLines(stdout_file, warn = FALSE), collapse = "\n")
    stderr <- paste(readLines(stderr_file, warn = FALSE), collapse = "\n")
  } else {
    stdout <- ""; stderr <- err %||% "analysis process did not produce output"
  }
  marker <- file.path(sb$work, status_file)
  if (file.exists(marker)) {
    parsed_status <- suppressWarnings(as.integer(sub("^__GLOSS_STATUS=", "", readLines(marker, warn = FALSE)[1L])))
    if (!is.na(parsed_status)) status <- parsed_status
    unlink(marker)
  }
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  timed_out <- grepl("timed out|stopped: the code ran longer", paste(stdout, stderr), ignore.case = TRUE) || elapsed >= timeout
  killed <- grepl("killed|out of memory|more memory", paste(stdout, stderr), ignore.case = TRUE)
  if (timed_out || killed) sandbox_reset(sb, if (timed_out) "analysis timeout" else "analysis process killed")
  after <- sandbox_tree_hash(sb$work)
  generated <- sort(setdiff(list.files(sb$work, recursive = TRUE, all.files = TRUE), c(file, status_file)))
  unlink(c(stdout_file, stderr_file))
  clipped_out <- sandbox_analysis_clip(stdout, limit)
  clipped_err <- sandbox_analysis_clip(stderr, limit)
  list(stdout = clipped_out$text, stderr = clipped_err$text,
       output = sandbox_clip(paste(c(stdout, stderr), collapse = "\n"), limit)$text,
       status = as.integer(status), timed_out = isTRUE(timed_out), killed = isTRUE(killed),
       seconds = round(elapsed, 2), call = call, sandbox_reset = isTRUE(timed_out || killed),
       generated_files = generated, generated_hash = after, public_hash_before = sb$public_hash,
       public_hash_after = sandbox_tree_hash(sb$public))
}

run_analysis <- sandbox_run_analysis

`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a

# ---- self-check ---------------------------------------------------------------

if (sys.nframe() == 0L && "--dry" %in% commandArgs(trailingOnly = TRUE)) {
  material <- tempfile("material-")
  dir.create(material)
  writeLines("the note", file.path(material, "note.txt"))
  dir.create(file.path(material, "data"))
  utils::write.csv(data.frame(a = 1:3), file.path(material, "data", "t.csv"), row.names = FALSE)
  before <- tools::md5sum(list.files(material, recursive = TRUE, full.names = TRUE))
  sb <- sandbox_open(material)
  check <- function(what, ok, shown = "") {
    cat(sprintf("%-68s %s%s\n", what, if (isTRUE(ok)) "ok" else "FAILED", if (isTRUE(ok) || !nzchar(shown)) "" else paste0("\n    ", shown)))
    if (!isTRUE(ok)) failed <<- failed + 1L
  }
  failed <- 0L
  r <- sandbox_run(sb, 'cat(readLines("note.txt"), nrow(read.csv("data/t.csv")), getwd())')
  check("reads the material in its working directory", identical(r$output, "the note 3 /work") && r$status == 0L, r$output)
  r <- sandbox_run(sb, 'suppressMessages(library(ggplot2)); b <- ggplot_build(ggplot(mtcars, aes(wt, mpg)) + geom_point()); cat(nrow(b$data[[1]]))')
  check("loads the bench's packages and builds a plot", identical(r$output, "32"), r$output)
  cat(sprintf("    (that call took %.1f s)\n", r$seconds))
  r <- sandbox_run(sb, 'r <- tryCatch({con <- suppressWarnings(socketConnection("cloud.r-project.org", 80, blocking = TRUE, timeout = 5)); close(con); "reachable"}, error = function(e) "no network"); cat(r)')
  check("has no network", identical(r$output, "no network"), r$output)
  r <- sandbox_run(sb, 'e <- Sys.getenv(); cat(sum(grepl("TOKEN|KEY|SECRET|ANTHROPIC|PROXY", names(e), ignore.case = TRUE)), nzchar(Sys.getenv("ANTHROPIC_AUTH_TOKEN")))')
  check("sees no key, token or proxy of the host", identical(r$output, "0 FALSE"), r$output)
  r <- sandbox_run(sb, 'cat(file.exists("/gloss"), dir.exists("/cache/src"), suppressWarnings(file.create("/usr/local/x")), suppressWarnings(file.create("/cache/lib/x")))')
  check("sees no repository or sources, and cannot write outside /work and /tmp", identical(r$output, "FALSE FALSE FALSE FALSE"), r$output)
  r <- sandbox_run(sb, 'writeLines("kept", "mine.txt"); writeLines("x", "note.txt"); cat(file.exists(file.path(tempdir(), "..")))')
  r <- sandbox_run(sb, 'cat(readLines("mine.txt"), readLines("note.txt"))')
  check("keeps its own files from one call to the next", identical(r$output, "kept x"), r$output)
  after <- tools::md5sum(list.files(material, recursive = TRUE, full.names = TRUE))
  check("leaves the material itself unchanged", identical(unname(before), unname(after)) && !file.exists(file.path(material, "mine.txt")))
  r <- sandbox_run(sb, 'Sys.sleep(30); cat("done")', timeout = 3)
  check("stops code that runs too long, and says so", r$timed_out && grepl("stopped: the code ran longer than 3 s", r$output) && r$seconds < 20, r$output)
  r <- sandbox_run(sb, 'cat(strrep("a", 50000), "END")', limit = 600)
  check("clips a long output to its head and tail", r$clipped && nchar(r$output) < 700 && grepl("END$", r$output) && grepl("characters left out", r$output))
  r <- sandbox_run(sb, 'stop("it broke")')
  check("an error in the code is an output, not an R error here", r$status != 0L && grepl("it broke", r$output), r$output)
  r <- sandbox_run(sb, 'x <- numeric(3e9)')
  check("a call that asks for more memory than allowed fails alone", r$status != 0L, r$output)
  r <- sandbox_run(sb, 'x <- lapply(1:200, function(i) rnorm(2e7)); cat("done")')
  check("code that takes more memory than the sandbox has is killed, and told so", r$killed && !r$timed_out && grepl("more memory than the sandbox has", r$output), r$output)
  sb2 <- sandbox_open(material)
  r <- sandbox_run(sb2, 'cat(file.exists("mine.txt"), readLines("note.txt"))')
  check("a new sandbox starts from the material, not from the last run", identical(r$output, "FALSE the note"), r$output)
  sandbox_close(sb); sandbox_close(sb2)
  check("is removed when closed", !dir.exists(sb$work) && !dir.exists(sb2$work))
  unlink(material, recursive = TRUE)
  if (failed) { cat(sprintf("%d check%s failed\n", failed, if (failed == 1L) "" else "s")); quit(status = 1) }
  cat("sandbox self-check passed\n")
}
