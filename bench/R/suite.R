# Run the package's full test suite inside the bench container (Linux), with
# the slow tests on, and print the counts the dev log records:
#   GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/suite.R
# AGENTS.md (Tests) asks for this run whenever code that reads what a graphics
# device wrote is changed: the stale-bytes defect of 2026-11-11 (`254bd73`)
# showed on Linux only. The repository is mounted read-only in the container,
# so a test that writes into it fails here, as it should.

source("bench/R/common.R")
.libPaths(unique(c(bench_envs$cran$lib, .libPaths())))
Sys.setenv(NOT_CRAN = "true")
res <- as.data.frame(testthat::test_local(".", reporter = "summary", stop_on_failure = FALSE))
cat(sprintf("\n%s | %s\nsuite: %d files / %d tests / %d expectations / %d failed / %d errors / %d skipped / %d warnings\n",
            R.version.string, R.version$platform,
            length(unique(res$file)), nrow(res), sum(res$nb), sum(res$failed), sum(res$error),
            sum(res$skipped), sum(res$warning)))
if (sum(res$failed) + sum(res$error) > 0) quit(status = 1)
