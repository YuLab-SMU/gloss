# Spot check of frozen figures (bench v0, Task 4 verification): 10 figures
# drawn at random from those that passed the no-network pass, each rerun 3
# times from bench/figures/ with no network; every run must recover the
# recorded engine.
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/spot-check.R

source("bench/R/harvest.R")
RNGkind("Mersenne-Twister", "Inversion", "Rejection")

reachable <- tryCatch({
  con <- suppressWarnings(socketConnection("cloud.r-project.org", 80, blocking = TRUE, timeout = 5))
  close(con); TRUE
}, error = function(e) FALSE)
if (reachable) stop("the network is reachable; run with GLOSS_BENCH_OFFLINE=true bench/docker/run.sh")

att <- read_csv(attempts_file)
oc <- read_csv(file.path(bench_root, "runs", "offline-check.csv"))
pool <- att[att$outcome == "retained" & att$id %in% oc$id[oc$ok], ]
pool <- pool[order(pool$id), ]
set.seed(20261110)
pick <- pool[sort(sample.int(nrow(pool), 10)), ]

rows <- list()
for (k in seq_len(nrow(pick))) {
  for (rep in 1:3) {
    e <- tryCatch(check_eligibility(file.path(figures_root, pick$id[k]), pick$engine[k]),
                  error = function(err) list(ok = FALSE, run = list(error = list(stage = "harness", message = conditionMessage(err)))))
    rows[[length(rows) + 1]] <- data.frame(id = pick$id[k], engine = pick$engine[k], run = rep, ok = e$ok,
                                           recovered = e$run$recovered$engine %||% NA,
                                           detail = if (e$ok) "" else substr(paste(e$run$error$stage, e$run$error$message), 1, 200),
                                           stringsAsFactors = FALSE)
    cat(sprintf("%s run %d: %s (%s)\n", pick$id[k], rep, if (e$ok) "ok" else "FAILED", e$run$recovered$engine %||% NA))
  }
}
res <- do.call(rbind, rows)
write_csv(res, file.path(bench_root, "runs", "spot-check.csv"))
per <- tapply(res$ok, res$id, sum)
cat("spot check:", sum(per == 3), "of", length(per), "figures recovered their engine 3 of 3 times\n")
