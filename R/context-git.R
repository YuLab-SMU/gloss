# Context sniffer: project. The git commit of the directory holding the
# script (or the working directory) and whether it has uncommitted changes.

register_context_git <- function() {
  gl_register("context", name = "git", version = "0.1.0", package = "gloss",
              description = "project: git commit and uncommitted changes",
              item = "git", sniff = sniff_git)
}

sniff_git <- function(input) {
  git <- Sys.which("git")
  if (!nzchar(git)) return(list(found = FALSE, reason = "git is not installed"))
  script <- input$context$code$value$script$path
  dir <- if (!is.null(script)) dirname(script) else getwd()
  run <- function(...) {
    out <- suppressWarnings(tryCatch(
      system2(git, c("-C", shQuote(dir), ...), stdout = TRUE, stderr = FALSE, timeout = 5),
      error = function(e) structure(character(), status = 1L)
    ))
    if (!is.null(attr(out, "status")) && attr(out, "status") != 0L) return(NULL)
    out
  }
  commit <- run("rev-parse", "HEAD")
  if (is.null(commit) || !length(commit)) {
    return(list(found = FALSE, reason = sprintf("'%s' is not inside a git repository", dir)))
  }
  status <- run("status", "--porcelain") %||% character()
  list(found = TRUE, value = list(
    commit = commit[1],
    branch = (run("rev-parse", "--abbrev-ref", "HEAD") %||% NA_character_)[1],
    root = (run("rev-parse", "--show-toplevel") %||% NA_character_)[1],
    dirty = length(status) > 0L,
    n_changed = length(status)
  ))
}
