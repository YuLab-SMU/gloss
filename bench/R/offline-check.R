# Rerun every retained figure in a container with no network (bench v0, Task 4).
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/offline-check.R
# The check inside harvest blocks the network with a dead proxy, which stops
# url() and download.file() but not raw sockets (measured 2026-11-09); this
# pass runs with no network interface at all. split.R uses only figures that
# pass it.

source("bench/R/harvest.R")

reachable <- tryCatch({
  con <- suppressWarnings(socketConnection("cloud.r-project.org", 80, blocking = TRUE, timeout = 5))
  close(con); TRUE
}, error = function(e) FALSE)
if (reachable) stop("the network is reachable; run with GLOSS_BENCH_OFFLINE=true bench/docker/run.sh")

att <- read_csv(attempts_file)
ret <- att[att$outcome == "retained", ]
res <- do.call(rbind, lapply(seq_len(nrow(ret)), function(k) {
  e <- tryCatch(check_eligibility(file.path(bench_root, "figures", ret$id[k]), ret$engine[k]),
                error = function(err) list(ok = FALSE, run = list(error = list(stage = "harness", message = conditionMessage(err)))))
  detail <- if (e$ok) "" else substr(paste(e$run$error$stage, e$run$error$message, e$run$recovered$engine), 1, 300)
  cat(sprintf("[%d/%d] %s: %s %s\n", k, nrow(ret), ret$id[k], if (e$ok) "ok" else "FAILED", detail))
  data.frame(id = ret$id[k], ok = e$ok, detail = detail, stringsAsFactors = FALSE)
}))
if (is.null(res)) res <- data.frame(id = character(), ok = logical(), detail = character())
write_csv(res, file.path(bench_root, "runs", "offline-check.csv"))
cat("offline check:", sum(res$ok), "of", nrow(res), "retained figures rerun with no network\n")
