# The bundle's round trip on the frozen figures of one development set
# (agent-path plan 2026-11-12, Task 5b): capture each figure with its
# bindings, write it as a single HTML file, read the file back and compare.
# Runs third-party code, so run it in the container, with no network:
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/bundle.R dev
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/bundle.R dev tree
# Development sets only: this script refuses the held-out set.
#
# Per figure, twice: with everything embedded (`embed = "all"`), where the
# figure read back must be identical to the one written, and with the
# default embedding, which leaves out raw columns nothing refers to and is
# what an agent on the host is served. On the default bundle read back, up
# to 5 verified pairings of one element with one row are put to gl_propose().
#
# Output: runs/<stamp>-bundle-<set>[-<stratum>].csv (one row per figure), .json.

source("bench/R/harvest.R")
args <- commandArgs(trailingOnly = TRUE)
# --only=id1,id2: a trial of the script on a few figures; written as -trial, never archived as a run
only <- sub("^--only=", "", grep("^--only=", args, value = TRUE))
args <- args[!grepl("^--only=", args)]
set <- if (length(args)) args[1] else "dev"
stratum <- if (length(args) > 1) args[2] else NULL
if (!identical(set, "dev")) stop("bundle.R runs on the development sets only")

reachable <- tryCatch({
  con <- suppressWarnings(socketConnection("cloud.r-project.org", 80, blocking = TRUE, timeout = 5))
  close(con); TRUE
}, error = function(e) FALSE)
if (reachable) stop("the network is reachable; run with GLOSS_BENCH_OFFLINE=true bench/docker/run.sh")

# Runs in the worker, beside the figure. Self-contained.
bundle_roundtrip <- function(fig, svg, dir) {
  g <- suppressWarnings(gloss::gloss(fig))
  parts_all <- c("substrate", "tables", "derived", "meta", "status")
  one <- function(embed, parts) {
    f <- file.path(dir, paste0("figure-", embed, ".html"))
    t0 <- Sys.time()
    w <- tryCatch({ gloss::gl_write(g, f, embed = embed); NULL }, error = function(e) conditionMessage(e))
    secs <- function() round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 2)
    if (!is.null(w)) return(list(stage = "not written", message = w, bytes = NA_real_, seconds = secs()))
    back <- tryCatch(gloss::gl_read(f), error = function(e) e)
    if (inherits(back, "error")) {
      return(list(stage = "not read", message = conditionMessage(back), bytes = file.size(f), seconds = secs()))
    }
    differs <- parts[!vapply(parts, function(p) identical(back[[p]], g[[p]]), logical(1))]
    # which tables, when it is the tables
    if ("tables" %in% differs) {
      tn <- union(names(g$tables), names(back$tables))
      bad <- tn[!vapply(tn, function(n) identical(back$tables[[n]], g$tables[[n]]), logical(1))]
      differs[differs == "tables"] <- paste0("tables(", paste(utils::head(bad, 6), collapse = ","), ")")
    }
    list(stage = if (length(differs)) "differs" else "identical", message = paste(differs, collapse = " "),
         bytes = file.size(f), seconds = secs(), back = back)
  }
  all <- one("all", parts_all)
  def <- one("default", c("substrate", "derived"))
  out <- list(all_stage = all$stage, all_message = all$message, all_bytes = all$bytes, all_seconds = all$seconds,
              default_stage = def$stage, default_message = def$message, default_bytes = def$bytes,
              default_seconds = def$seconds, tried = 0L, accepted = 0L, rejected = 0L, refused = 0L, reasons = "")
  if (!is.null(def$back)) {
    b <- tryCatch(gloss::gl_bindings(def$back), error = function(e) NULL)
    b <- if (is.null(b)) NULL else b[b$status %in% "verified" & b$n_rows %in% 1L, , drop = FALSE]
    if (!is.null(b) && nrow(b)) {
      set.seed(20261113L)
      b <- b[sort(sample.int(nrow(b), min(5L, nrow(b)))), , drop = FALSE]
      res <- lapply(seq_len(nrow(b)), function(i) {
        tryCatch(gloss::gl_propose(def$back, list(kind = "binding", element = b$element[i], table = b$table[i], row = b$row[i])),
                 error = function(e) list(outcome = "error", reasons = conditionMessage(e)))
      })
      oc <- vapply(res, function(r) r$outcome, "")
      out$tried <- length(oc)
      out$accepted <- sum(oc == "accepted")
      out$rejected <- sum(oc == "rejected")
      out$refused <- sum(oc == "refused")
      out$errors <- sum(oc == "error")
      why <- unique(unlist(lapply(res[oc != "accepted"], function(r) substr(paste(r$reasons, collapse = "; "), 1L, 160L))))
      out$reasons <- paste(utils::head(why, 3L), collapse = " | ")
    }
  }
  out
}

split <- read_csv(file.path(bench_root, "split.csv"))
todo <- set_figures(split, set, stratum)
if (length(only)) todo <- todo[todo$id %in% strsplit(only, ",")[[1]], , drop = FALSE]
stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
gloss_snapshot()
out_file <- file.path(if (length(only)) tempdir() else file.path(bench_root, "runs"),
                      sprintf("%s-bundle-%s%s.csv", stamp, run_scope(set, stratum), if (length(only)) "-trial" else ""))
work <- file.path(work_root, "bundle")
rows <- list()
for (k in seq_len(nrow(todo))) {
  id <- todo$id[k]
  dir <- file.path(bench_root, "figures", id)
  out <- file.path(work, id)
  unlink(out, recursive = TRUE)
  dir.create(out, recursive = TRUE)
  e <- check_eligibility(dir, todo$engine[k], timeout = 900, capture = TRUE, export = normalizePath(out),
                         export_fun = bundle_roundtrip)
  cap <- e$run$capture
  status <- if (!is.null(e$run$error)) {
              if (identical(e$run$error$stage, "timeout")) "timeout" else paste("rerun:", e$run$error$stage)
            }
            else if (is.null(cap)) "no figure recovered"
            else if (!identical(e$run$recovered$engine, todo$engine[k])) "rerun: engine changed"
            else if (!identical(cap$status, "captured")) "not captured"
            else if (!isTRUE(cap$export)) "round trip did not run"
            else "captured"
  r <- cap$export_result %||% list()
  val <- function(name, default = NA) r[[name]] %||% default
  rows[[k]] <- data.frame(
    id = id, stratum = todo$stratum[k], engine = todo$engine[k], status = status,
    message = substr(if (is.character(cap$export)) cap$export else cap$message %||% e$run$error$message %||% "", 1, 300),
    elements = cap$elements %||% NA, leaves = cap$leaves %||% NA,
    all_stage = val("all_stage", NA_character_), all_message = substr(val("all_message", ""), 1, 300),
    all_kb = round(val("all_bytes") / 1024), all_seconds = val("all_seconds"),
    default_stage = val("default_stage", NA_character_), default_message = substr(val("default_message", ""), 1, 300),
    default_kb = round(val("default_bytes") / 1024), default_seconds = val("default_seconds"),
    tried = val("tried"), accepted = val("accepted"), rejected = val("rejected"), refused = val("refused"),
    propose_errors = val("errors", 0L), reasons = val("reasons", ""), stringsAsFactors = FALSE)
  unlink(out, recursive = TRUE)
  cat(sprintf("[%d/%d] %s %s: %s | all: %s %s | default: %s %s | proposed %s, accepted %s\n", k, nrow(todo), id, todo$engine[k], status,
              rows[[k]]$all_stage, substr(rows[[k]]$all_message, 1, 70), rows[[k]]$default_stage,
              substr(rows[[k]]$default_message, 1, 50), rows[[k]]$tried, rows[[k]]$accepted))
}
res <- do.call(rbind, rows)
write_csv(res, out_file)
writeLines(jsonlite::toJSON(list(set = set, stratum = stratum %||% "v0", figures = nrow(res), started = stamp,
                                 gloss_source_digest = gloss_source$digest, R = R.version.string,
                                 image = Sys.getenv("GLOSS_BENCH_IMAGE_DIGEST")), auto_unbox = TRUE, pretty = TRUE),
           sub("\\.csv$", ".json", out_file))
cat(sprintf("\n%d figures | captured %d | all: %s | default: %s | %s\n", nrow(res), sum(res$status == "captured"),
            paste(names(table(res$all_stage)), table(res$all_stage), collapse = ", "),
            paste(names(table(res$default_stage)), table(res$default_stage), collapse = ", "), out_file))
