#!/usr/bin/env Rscript

# Fast bench-only contract checks for the agent-first path.  This is a
# mechanism test on a hand-built figure, not a development-set coverage claim.

suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE))
source("bench/agent/binding-agent.R")

if (!requireNamespace("ggplot2", quietly = TRUE)) stop("ggplot2 is required")
library(ggplot2)

figure <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
root <- tempfile("gloss-binding-prototype-")
dir.create(root)
written <- binding_write_material(figure, "", root, figure_id = "synthetic")
stopifnot(isTRUE(binding_check_public_material(root)$ok))
public_files <- list.files(file.path(root, "public"), recursive = TRUE)
stopifnot(!any(grepl("oracle|answer|legacy|geometry|checker", public_files, ignore.case = TRUE)))

facts <- binding_read_public(root)
oracle <- binding_open_oracle(root)
verified <- oracle$legacy$leaves[oracle$legacy$leaves$status == "verified", , drop = FALSE]
stopifnot(nrow(verified) > 0L)
leaf <- verified$leaf[1L]
table <- verified$table[1L]
proposal <- list(version = binding_dsl_version, leaf = leaf, table = table,
                 rows = list(kind = "all"), order = list(kind = "build"),
                 per_row = list(kind = "one"), shift = list(kind = "none"),
                 anchor = list(kind = "center"))
accepted <- binding_checker(root, proposal)
stopifnot(identical(accepted$outcome, "accepted"), identical(accepted$mutation$status, "passed"))

bad_schema <- binding_validate_proposal(c(proposal, list(script = "plot(1)")))
stopifnot(!bad_schema$ok, any(grepl("unknown", bad_schema$errors)))

mutated <- binding_mutate_proposal(proposal, oracle$figure_object$tables[[table]]$data,
                                   facts$leaves$id)
stopifnot(length(mutated) > 0L)
mutated_results <- lapply(mutated, function(m) binding_checker(root, m$proposal, mutation = FALSE)$outcome)
stopifnot(!any(mutated_results %in% "accepted"))

legacy <- binding_legacy_arm(binding_load_material(root))
stopifnot(isTRUE(legacy$status == "measured"))
contract <- binding_contract_arm(binding_load_material(root))
stopifnot(contract$status %in% c("measured", "refused"))

sb <- sandbox_open_persistent(file.path(root, "public"))
before <- sandbox_tree_hash(sb$public)
analysis <- run_analysis(sb, "cat(file.exists('/material/facts.json')); writeLines('scratch', '/work/scratch.txt')")
stopifnot(analysis$status == 0L, grepl("TRUE", analysis$stdout), identical(before, analysis$public_hash_after))
sandbox_close_persistent(sb)

cat(sprintf("prototype checks passed: public files %d, legacy rows %d, contract %s, sandbox calls %d\n",
            length(public_files), nrow(oracle$legacy$elements), contract$status, analysis$call))
