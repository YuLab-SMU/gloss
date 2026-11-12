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
sandbox_run <- function(sb, code, timeout = 60, limit = 6000) {
  n <- length(list.files(sb$work, pattern = "^\\.call-[0-9]+\\.R$", all.files = TRUE)) + 1L
  call_file <- sprintf(".call-%03d.R", n)
  writeLines(enc2utf8(as.character(code)), file.path(sb$work, call_file), useBytes = TRUE)
  cache <- sandbox_cache()
  args <- c(
    "run", "--rm", "--network", "none", "--read-only", "--tmpfs", "/tmp:rw,exec,size=512m",
    "--memory", "2g", "--memory-swap", "2g", "--cpus", "2", "--pids-limit", "256",
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
  timed_out <- status %in% c(124L, 137L)
  text <- paste(out, collapse = "\n")
  if (timed_out) text <- paste0(text, sprintf("\n[stopped: the code ran longer than %d s]", as.integer(timeout)))
  clip <- sandbox_clip(text, limit)
  list(output = clip$text, status = as.integer(status), timed_out = timed_out, clipped = clip$clipped,
       seconds = round(seconds, 2), call = n)
}

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
  sb2 <- sandbox_open(material)
  r <- sandbox_run(sb2, 'cat(file.exists("mine.txt"), readLines("note.txt"))')
  check("a new sandbox starts from the material, not from the last run", identical(r$output, "FALSE the note"), r$output)
  sandbox_close(sb); sandbox_close(sb2)
  check("is removed when closed", !dir.exists(sb$work) && !dir.exists(sb2$work))
  unlink(material, recursive = TRUE)
  if (failed) { cat(sprintf("%d check%s failed\n", failed, if (failed == 1L) "" else "s")); quit(status = 1) }
  cat("sandbox self-check passed\n")
}
