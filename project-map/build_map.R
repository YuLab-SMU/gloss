#!/usr/bin/env Rscript
# gloss Project Map — Live Code-vs-Intent Alignment Probe
#
# Scans DESCRIPTION, NAMESPACE, R/, man/, tests/testthat/, and git history,
# optionally runs testthat, and generates:
#   1. <map-dir>/model/90-live-status.c4  (LikeC4 `extend` status overlay)
#   2. <map-dir>/status.json              (machine-readable alignment report)
#
# Usage:
#   Rscript project-map/build_map.R [--repo-dir DIR] [--map-dir DIR] [--run-tests] [--strict] [--summary FILE]

suppressPackageStartupMessages({
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required to run build_map.R.", call. = FALSE)
  }
})

get_arg_value <- function(args, flag) {
  idx <- match(flag, args)
  if (!is.na(idx) && idx < length(args)) args[[idx + 1L]] else NULL
}

detect_script_dir <- function() {
  full_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", full_args, value = TRUE)
  if (length(file_arg) > 0L) {
    script_path <- sub("^--file=", "", file_arg[[1L]])
    return(dirname(normalizePath(script_path, mustWork = FALSE)))
  }
  if (dir.exists("project-map")) {
    normalizePath("project-map", mustWork = FALSE)
  } else {
    normalizePath(".project-map", mustWork = FALSE)
  }
}

args <- commandArgs(trailingOnly = TRUE)
run_tests <- "--run-tests" %in% args
strict_mode <- "--strict" %in% args
summary_file <- get_arg_value(args, "--summary")
if (!is.null(summary_file) && nzchar(summary_file)) {
  summary_file <- normalizePath(summary_file, mustWork = FALSE)
}
map_dir_arg <- get_arg_value(args, "--map-dir")
map_dir <- if (!is.null(map_dir_arg) && nzchar(map_dir_arg)) {
  normalizePath(map_dir_arg, mustWork = FALSE)
} else {
  detect_script_dir()
}
repo_dir_arg <- get_arg_value(args, "--repo-dir")
if (!is.null(repo_dir_arg) && nzchar(repo_dir_arg)) {
  repo_dir <- normalizePath(repo_dir_arg, mustWork = TRUE)
  setwd(repo_dir)
}

# --- Helpers -----------------------------------------------------------------

`%||%` <- function(a, b) if (is.null(a)) b else a

utc_now <- function() {
  format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

c4_escape <- function(x) {
  x <- as.character(x %||% "")[[1L]]
  x <- gsub("\\\\", "\\\\\\\\", x)
  x <- gsub("\"", "\\\\\"", x)
  x <- gsub("[\r\n]+", " ", x)
  x
}

parse_pkg_list <- function(field) {
  if (is.null(field) || is.na(field) || !nzchar(field)) return(character())
  raw <- strsplit(field, ",", fixed = TRUE)[[1L]]
  pkgs <- trimws(sub("\\s*\\(.*\\)$", "", raw))
  pkgs[nzchar(pkgs)]
}

count_loc <- function(paths) {
  existing <- paths[file.exists(paths)]
  if (length(existing) == 0L) return(0L)
  sum(vapply(existing, function(p) length(readLines(p, warn = FALSE)), integer(1L)))
}

count_test_blocks <- function(paths) {
  existing <- paths[file.exists(paths)]
  if (length(existing) == 0L) return(0L)
  sum(vapply(existing, function(p) {
    lines <- readLines(p, warn = FALSE)
    sum(grepl("^\\s*test_that\\s*\\(", lines))
  }, integer(1L)))
}

run_git <- function(git_args) {
  git_bin <- Sys.which("git")
  if (!nzchar(git_bin)) return(character())
  out <- tryCatch(
    suppressWarnings(system2(git_bin, git_args, stdout = TRUE, stderr = FALSE)),
    error = function(e) character()
  )
  st <- attr(out, "status")
  if (!is.null(st) && st != 0L) return(character())
  out
}

# --- 1. Read Repository Metadata ---------------------------------------------

if (!file.exists("DESCRIPTION")) {
  stop("Run build_map.R from the root of the gloss repository.", call. = FALSE)
}

dcf <- as.list(read.dcf("DESCRIPTION")[1L, ])
pkg_version <- dcf$Version %||% "0.0.0"
schema_version <- {
  u_lines <- if (file.exists("R/utils.R")) readLines("R/utils.R", warn = FALSE) else character()
  m <- regmatches(u_lines, regexec("^GLOSS_SCHEMA_VERSION\\s*<-\\s*[\"']([^\"']+)[\"']", u_lines))
  hits <- Filter(function(x) length(x) == 2L, m)
  if (length(hits) > 0L) hits[[1L]][[2L]] else "1.0.0"
}
repo_url <- trimws(strsplit(dcf$URL %||% "https://github.com/YuLab-SMU/gloss", "[,[:space:]]+")[[1L]][[1L]])
repo_url <- sub("/+$", "", repo_url)

imports_pkgs <- parse_pkg_list(dcf$Imports)
suggests_pkgs <- parse_pkg_list(dcf$Suggests)
depends_pkgs <- parse_pkg_list(dcf$Depends)

ns_lines <- if (file.exists("NAMESPACE")) readLines("NAMESPACE", warn = FALSE) else character()
export_matches <- regmatches(ns_lines, regexec("^export\\(([^)]+)\\)", ns_lines))
actual_exports <- sort(unique(vapply(
  Filter(function(m) length(m) == 2L, export_matches),
  function(m) gsub("[\"']", "", trimws(m[[2L]])),
  character(1L)
)))

git_sha <- {
  s <- run_git(c("rev-parse", "--short", "HEAD"))
  if (length(s) > 0L) s[[1L]] else "unknown"
}
git_branch <- {
  b <- run_git(c("rev-parse", "--abbrev-ref", "HEAD"))
  if (length(b) > 0L) b[[1L]] else "main"
}
git_subject <- {
  m <- run_git(c("log", "-1", "--pretty=%s"))
  if (length(m) > 0L) m[[1L]] else ""
}
blob_base <- paste0(repo_url, "/blob/main/")

# --- 2. Optional Live Test Execution -----------------------------------------

test_summary <- list(
  ran = FALSE,
  passed = NA_integer_,
  failed = NA_integer_,
  warnings = NA_integer_,
  skipped = NA_integer_,
  by_file = list()
)

if (isTRUE(run_tests)) {
  if (!requireNamespace("devtools", quietly = TRUE) || !requireNamespace("testthat", quietly = TRUE)) {
    stop("--run-tests requires 'devtools' and 'testthat'.", call. = FALSE)
  }
  Sys.setenv(NOT_CRAN = "true")
  res <- devtools::test(reporter = testthat::ListReporter$new(), stop_on_failure = FALSE)
  df <- as.data.frame(res)
  test_summary$ran <- TRUE
  test_summary$passed <- as.integer(sum(df$passed))
  test_summary$failed <- as.integer(sum(df$failed))
  test_summary$warnings <- as.integer(sum(df$warning))
  test_summary$skipped <- as.integer(sum(df$skipped))

  if (nrow(df) > 0L) {
    by_f <- split(df, df$file)
    test_summary$by_file <- lapply(by_f, function(sub) {
      list(
        passed = as.integer(sum(sub$passed)),
        failed = as.integer(sum(sub$failed)),
        warnings = as.integer(sum(sub$warning)),
        skipped = as.integer(sum(sub$skipped))
      )
    })
  }
}

# --- 3. Canonical Intent Catalog ---------------------------------------------

canonical_apis <- list(
  list(id = "gloss_core.public_api.fn_gloss", name = "gloss", file = "R/capture.R", phase = "Phase 2"),
  list(id = "gloss_core.public_api.fn_asset_map", name = "gl_asset_map", file = "R/package-assets.R", phase = "Phase 3"),
  list(id = "gloss_core.public_api.fn_asset_bundle", name = "gl_asset_bundle", file = "R/package-assets.R", phase = "Phase 3"),
  list(id = "gloss_core.public_api.fn_scene", name = "gl_scene", file = "R/query.R", phase = "Phase 3"),
  list(id = "gloss_core.public_api.fn_tables", name = "gl_tables", file = "R/query.R", phase = "Phase 3"),
  list(id = "gloss_core.public_api.fn_sources", name = "gl_sources", file = "R/query.R", phase = "Phase 3"),
  list(id = "gloss_core.public_api.fn_query", name = "gl_query", file = "R/query.R", phase = "Phase 3"),
  list(id = "gloss_core.public_api.fn_register_engine", name = "gl_register_engine", file = "R/engine-registry.R", phase = "Phase 1")
)

core_modules <- list(
  list(
    id = "gloss_core.modules.mod_utils",
    name = "Contract & Open Serialization",
    files = c("R/utils.R", "R/gloss-package.R"),
    tests = c("tests/testthat/test-capture-contract.R"),
    phase = "Phase 1"
  ),
  list(
    id = "gloss_core.modules.mod_registry",
    name = "Engine Registry & Load Hook",
    files = c("R/engine-registry.R", "R/zzz.R"),
    tests = c("tests/testthat/test-engine-registry.R"),
    phase = "Phase 1"
  ),
  list(
    id = "gloss_core.modules.mod_capture",
    name = "Device Capture & SVG Instrumentation",
    files = c("R/capture.R"),
    tests = c("tests/testthat/test-capture.R"),
    phase = "Phase 2"
  ),
  list(
    id = "gloss_core.modules.mod_sources",
    name = "Source Context Inventory",
    files = c("R/sources.R"),
    tests = c("tests/testthat/test-sources.R"),
    phase = "Phase 3"
  ),
  list(
    id = "gloss_core.modules.mod_package_assets",
    name = "Asset Map & Bundle Packager",
    files = c("R/package-assets.R"),
    tests = c("tests/testthat/test-package-assets.R"),
    phase = "Phase 3"
  ),
  list(
    id = "gloss_core.modules.mod_query",
    name = "In-Memory Query & Slicing",
    files = c("R/query.R"),
    tests = c("tests/testthat/test-query.R"),
    phase = "Phase 3"
  ),
  list(
    id = "gloss_core.modules.mod_ir_lineage",
    name = "Engine IR & Structural Lineage",
    files = c("R/ir-lineage.R"),
    tests = c("tests/testthat/test-ir-lineage.R", "tests/testthat/test-v11-issues.R", "tests/testthat/test-v12-kernel.R"),
    phase = "Phase 4"
  )
)

builtin_engines <- list(
  list(
    id = "gloss_core.engines.eng_grid",
    name = "grid",
    pkg = "grid",
    files = c("R/engine-grid.R"),
    tests = c("tests/testthat/test-capture.R"),
    phase = "Phase 2"
  ),
  list(
    id = "gloss_core.engines.eng_ggplot",
    name = "ggplot2",
    pkg = "ggplot2",
    files = c("R/engine-ggplot.R"),
    tests = c("tests/testthat/test-engine-ggplot.R"),
    phase = "Phase 4"
  ),
  list(
    id = "gloss_core.engines.eng_patchwork",
    name = "patchwork",
    pkg = "patchwork",
    files = c("R/engine-patchwork.R"),
    tests = c("tests/testthat/test-engine-patchwork.R"),
    phase = "Phase 5"
  ),
  list(
    id = "gloss_core.engines.eng_heatmap",
    name = "ComplexHeatmap",
    pkg = "ComplexHeatmap",
    files = c("R/engine-heatmap.R"),
    tests = c("tests/testthat/test-engine-heatmap.R"),
    phase = "Phase 5"
  ),
  list(
    id = "gloss_core.engines.eng_base",
    name = "base",
    pkg = "grDevices",
    files = c("R/engine-base.R"),
    tests = c("tests/testthat/test-engine-base.R"),
    phase = "Phase 5"
  )
)

ecosystem_tools <- list(
  list(
    id = "ecosystem.skill_gloss",
    name = "Base Protocol Skill: gloss",
    files = c("skills/gloss/SKILL.md", "skills/gloss/scripts/focus_bridge.py", "skills/gloss/scripts/workspace_state.py"),
    tests = c("skills/tests/test_workflows.py"),
    phase = "Phase 6"
  ),
  list(
    id = "ecosystem.skill_refine",
    name = "SVG Refinement Skill: gloss-svg-refine",
    files = c("skills/gloss-svg-refine/SKILL.md", "skills/gloss-svg-refine/scripts/apply_visual_patch.py", "skills/gloss-svg-refine/scripts/verify_svg_fidelity.py"),
    tests = c("skills/tests/test_workflows.py"),
    phase = "Phase 6"
  ),
  list(
    id = "ecosystem.skill_audit",
    name = "Semantic Audit Skill: gloss-audit",
    files = c("skills/gloss-audit/SKILL.md", "skills/gloss-audit/scripts/audit_bundle.py"),
    tests = c("skills/tests/test_workflows.py"),
    phase = "Phase 6"
  ),
  list(
    id = "ecosystem.skill_report",
    name = "Report Skill: gloss-report",
    files = c("skills/gloss-report/SKILL.md"),
    tests = character(),
    phase = "Phase 6"
  ),
  list(
    id = "ecosystem.external_scripts",
    name = "Python / JS / DuckDB Toolchains",
    files = c(
      "skills/gloss/scripts/focus_bridge.py",
      "skills/gloss/scripts/workspace_state.py",
      "skills/gloss-svg-refine/scripts/apply_visual_patch.py",
      "skills/gloss-svg-refine/scripts/verify_svg_fidelity.py",
      "skills/gloss-audit/scripts/audit_bundle.py"
    ),
    tests = c("skills/tests/test_workflows.py"),
    phase = "Phase 6"
  )
)

# --- 4. Evaluate Live Status & Guardrails ------------------------------------

canonical_export_names <- vapply(canonical_apis, `[[`, character(1L), "name")
missing_exports <- setdiff(canonical_export_names, actual_exports)
unexpected_exports <- setdiff(actual_exports, canonical_export_names)

api_records <- lapply(canonical_apis, function(a) {
  is_exported <- a$name %in% actual_exports
  rd_path <- file.path("man", paste0(a$name, ".Rd"))
  has_rd <- file.exists(rd_path)
  has_src <- file.exists(a$file)

  status <- if (is_exported && has_rd && has_src) {
    "implemented"
  } else if (!is_exported && !has_rd) {
    "planned"
  } else {
    "drift"
  }

  list(
    id = a$id,
    name = a$name,
    phase = a$phase,
    status = status,
    exported = is_exported,
    rd_doc = has_rd,
    rd_path = rd_path,
    source_file = a$file,
    source_exists = has_src
  )
})

module_records <- lapply(core_modules, function(m) {
  src_exists <- all(file.exists(m$files))
  any_src <- any(file.exists(m$files))
  test_exists <- any(file.exists(m$tests))
  loc <- count_loc(m$files)
  n_test_blocks <- count_test_blocks(m$tests)

  live_passed <- NA_integer_
  live_failed <- NA_integer_
  if (isTRUE(test_summary$ran)) {
    test_bnames <- basename(m$tests)
    hits <- test_summary$by_file[intersect(test_bnames, names(test_summary$by_file))]
    if (length(hits) > 0L) {
      live_passed <- as.integer(sum(vapply(hits, `[[`, integer(1L), "passed")))
      live_failed <- as.integer(sum(vapply(hits, `[[`, integer(1L), "failed")))
    }
  }

  status <- if (!is.na(live_failed) && live_failed > 0L) {
    "drift"
  } else if (src_exists) {
    "implemented"
  } else if (any_src) {
    "drift"
  } else {
    "planned"
  }

  list(
    id = m$id,
    name = m$name,
    phase = m$phase,
    status = status,
    files = m$files,
    tests = m$tests,
    source_exists = src_exists,
    test_exists = test_exists,
    loc = loc,
    test_blocks = n_test_blocks,
    live_passed = live_passed,
    live_failed = live_failed
  )
})

engine_records <- lapply(builtin_engines, function(e) {
  src_exists <- all(file.exists(e$files))
  test_exists <- any(file.exists(e$tests))
  loc <- count_loc(e$files)
  dep_bucket <- if (e$pkg %in% suggests_pkgs) {
    "Suggests"
  } else if (e$pkg %in% imports_pkgs) {
    "Imports"
  } else {
    "Base/Unlisted"
  }

  # Optional plot engines MUST stay in Suggests, never Imports
  leaked_to_imports <- e$pkg %in% c("ggplot2", "patchwork", "ComplexHeatmap") && (e$pkg %in% imports_pkgs)
  status <- if (leaked_to_imports) {
    "drift"
  } else if (src_exists) {
    "implemented"
  } else {
    "planned"
  }

  list(
    id = e$id,
    name = e$name,
    pkg = e$pkg,
    phase = e$phase,
    status = status,
    files = e$files,
    tests = e$tests,
    source_exists = src_exists,
    test_exists = test_exists,
    dependency_bucket = dep_bucket,
    loc = loc
  )
})

ecosystem_records <- lapply(ecosystem_tools, function(ec) {
  src_exists <- length(ec$files) > 0L && all(file.exists(ec$files))
  any_src <- length(ec$files) > 0L && any(file.exists(ec$files))
  test_exists <- length(ec$tests) > 0L && any(file.exists(ec$tests))
  loc <- count_loc(ec$files)
  status <- if (src_exists) {
    "implemented"
  } else if (any_src) {
    "drift"
  } else {
    "planned"
  }
  list(
    id = ec$id,
    name = ec$name,
    phase = ec$phase,
    status = status,
    files = ec$files,
    tests = ec$tests,
    source_exists = src_exists,
    test_exists = test_exists,
    loc = loc
  )
})

# --- Guardrail checks --------------------------------------------------------

r_files <- sort(list.files("R", pattern = "\\.[Rr]$", full.names = TRUE))
test_files <- sort(list.files("tests/testthat", pattern = "^test-.*\\.[Rr]$", full.names = TRUE))

scan_pattern <- function(files, pattern) {
  hits <- character()
  for (f in files) {
    lines <- readLines(f, warn = FALSE)
    # Ignore pure comment lines
    code_lines <- sub("#.*$", "", lines)
    matched <- which(grepl(pattern, code_lines, perl = TRUE))
    if (length(matched) > 0L) {
      hits <- c(hits, paste0(f, ":", matched))
    }
  }
  hits
}

superassign_hits <- scan_pattern(c(r_files, test_files), "<<-")
globalenv_hits <- scan_pattern(r_files, "\\.GlobalEnv|globalenv\\(\\)")
rplots_files <- list.files(".", pattern = "^Rplots.*\\.pdf$", recursive = TRUE)

suggests_engines <- c("ggplot2", "patchwork", "ComplexHeatmap")
leaked_engines <- intersect(suggests_engines, c(imports_pkgs, depends_pkgs))
missing_suggests <- setdiff(suggests_engines, suggests_pkgs)

prohibited_r_files <- basename(r_files)[grepl("^(agent-|mcp-|workbench-|core-codec|propose|semantic-checks)", basename(r_files))]
prohibited_imports <- intersect(c("shiny", "httpuv", "ellmer", "httr2"), c(imports_pkgs, depends_pkgs))

g_exports_ok <- length(unexpected_exports) == 0L && length(missing_exports) == 0L
g_suggests_ok <- length(leaked_engines) == 0L && length(missing_suggests) == 0L
g_cran_ok <- length(superassign_hits) == 0L && length(globalenv_hits) == 0L && length(rplots_files) == 0L
g_boundary_ok <- length(prohibited_r_files) == 0L && length(prohibited_imports) == 0L
g_tests_ok <- if (isTRUE(test_summary$ran)) {
  test_summary$failed == 0L && test_summary$passed > 0L
} else {
  length(test_files) > 0L
}

guardrails <- list(
  list(
    id = "principles.g_exports",
    name = "Export Surface Alignment (8 APIs)",
    pass = g_exports_ok,
    detail = if (g_exports_ok) {
      sprintf("%d/%d canonical exports aligned in NAMESPACE", length(actual_exports), length(canonical_export_names))
    } else {
      paste(c(
        if (length(missing_exports) > 0L) paste("Missing:", paste(missing_exports, collapse = ", ")),
        if (length(unexpected_exports) > 0L) paste("Unexpected:", paste(unexpected_exports, collapse = ", "))
      ), collapse = " | ")
    }
  ),
  list(
    id = "principles.g_suggests",
    name = "Engine Dependencies in Suggests",
    pass = g_suggests_ok,
    detail = if (g_suggests_ok) {
      "ggplot2, patchwork, ComplexHeatmap isolated in Suggests"
    } else {
      paste("Leaked:", paste(leaked_engines, collapse = ", "), "Missing:", paste(missing_suggests, collapse = ", "))
    }
  ),
  list(
    id = "principles.g_cran_hygiene",
    name = "CRAN & R Hygiene",
    pass = g_cran_ok,
    detail = if (g_cran_ok) {
      "0 <<- super-assignments, 0 .GlobalEnv writes, 0 stray Rplots*.pdf"
    } else {
      sprintf("<<- hits: %d | .GlobalEnv hits: %d | Rplots.pdf: %d",
              length(superassign_hits), length(globalenv_hits), length(rplots_files))
    }
  ),
  list(
    id = "principles.g_core_boundary",
    name = "Strict In-Core Boundary",
    pass = g_boundary_ok,
    detail = if (g_boundary_ok) {
      sprintf("%d lean R files in R/ (%d LOC); zero agent/MCP/UI/codec bloat", length(r_files), count_loc(r_files))
    } else {
      paste("Prohibited files/imports:", paste(c(prohibited_r_files, prohibited_imports), collapse = ", "))
    }
  ),
  list(
    id = "principles.g_tests",
    name = "Unit Test & Build Health",
    pass = g_tests_ok,
    detail = if (isTRUE(test_summary$ran)) {
      sprintf("%d PASS / %d FAIL / %d WARN / %d SKIP across %d test files",
              test_summary$passed, test_summary$failed, test_summary$warnings, test_summary$skipped, length(test_files))
    } else {
      sprintf("%d test files (%d test_that blocks); pass --run-tests for live execution",
              length(test_files), count_test_blocks(test_files))
    }
  )
)

# --- 5. Emit <map-dir>/model/90-live-status.c4 -------------------------------

now_ts <- utc_now()
c4_lines <- c(
  "// AUTO-GENERATED by project-map/build_map.R — DO NOT EDIT BY HAND.",
  sprintf("// Generated: %s | git: %s (%s) | version: %s", now_ts, git_sha, git_branch, pkg_version),
  "",
  "model {"
)

append_extend <- function(fqn, tags = character(), links = list(), meta = list()) {
  blk <- c(sprintf("  extend %s {", fqn))
  if (length(tags) > 0L) {
    blk <- c(blk, paste0("    ", paste0("#", tags, collapse = " ")))
  }
  for (lk in links) {
    blk <- c(blk, sprintf("    link %s \"%s\"", lk$url, c4_escape(lk$label)))
  }
  if (length(meta) > 0L) {
    blk <- c(blk, "    metadata {")
    for (nm in names(meta)) {
      blk <- c(blk, sprintf("      %s \"%s\"", nm, c4_escape(meta[[nm]])))
    }
    blk <- c(blk, "    }")
  }
  blk <- c(blk, "  }", "")
  blk
}

# System-level rollups
n_mod_done <- sum(vapply(module_records, function(x) identical(x$status, "implemented"), logical(1L)))
n_eng_done <- sum(vapply(engine_records, function(x) identical(x$status, "implemented"), logical(1L)))
n_api_done <- sum(vapply(api_records, function(x) identical(x$status, "implemented"), logical(1L)))
n_guard_pass <- sum(vapply(guardrails, function(x) isTRUE(x$pass), logical(1L)))
all_guards_ok <- n_guard_pass == length(guardrails)

c4_lines <- c(
  c4_lines,
  append_extend(
    "gloss_core",
    tags = if (all_guards_ok) "implemented" else "drift",
    meta = list(
      version = pkg_version,
      git_commit = sprintf("%s (%s)", git_sha, git_branch),
      exports = sprintf("%d / %d aligned", n_api_done, length(api_records)),
      modules = sprintf("%d / %d implemented", n_mod_done, length(module_records)),
      engines = sprintf("%d / %d implemented", n_eng_done, length(engine_records)),
      total_r_loc = as.character(count_loc(r_files)),
      guardrails = sprintf("%d / %d PASS", n_guard_pass, length(guardrails)),
      updated_at = now_ts
    )
  ),
  append_extend(
    "open_assets.asset_map",
    tags = if ("gl_asset_map" %in% actual_exports) "implemented" else "planned",
    links = list(
      list(url = paste0(blob_base, "R/package-assets.R"), label = "Source: R/package-assets.R"),
      list(url = paste0(blob_base, "dev_docs/architecture.md"), label = "Spec: Architecture")
    ),
    meta = list(
      status = if ("gl_asset_map" %in% actual_exports) "implemented" else "planned",
      schema_version = schema_version,
      package_version = pkg_version
    )
  ),
  append_extend(
    "open_assets.asset_bundle",
    tags = if ("gl_asset_bundle" %in% actual_exports) "implemented" else "planned",
    links = list(
      list(url = paste0(blob_base, "R/package-assets.R"), label = "Source: R/package-assets.R"),
      list(url = paste0(blob_base, "tests/testthat/test-package-assets.R"), label = "Tests: test-package-assets.R")
    ),
    meta = list(
      status = if ("gl_asset_bundle" %in% actual_exports) "implemented" else "planned",
      formats = "dir (.gloss/), zip (.gloss.zip); tables: csv, parquet"
    )
  )
)

# Public APIs
for (a in api_records) {
  lks <- list()
  if (a$source_exists) {
    lks[[length(lks) + 1L]] <- list(url = paste0(blob_base, a$source_file), label = paste("Source:", a$source_file))
  }
  if (a$rd_doc) {
    lks[[length(lks) + 1L]] <- list(url = paste0(blob_base, a$rd_path), label = paste("Docs:", a$rd_path))
  }
  c4_lines <- c(
    c4_lines,
    append_extend(
      a$id,
      tags = a$status,
      links = lks,
      meta = list(
        status = a$status,
        phase = a$phase,
        exported_in_namespace = if (a$exported) "yes" else "no",
        rd_documented = if (a$rd_doc) "yes" else "no",
        source = a$source_file
      )
    )
  )
}

# Core modules
for (m in module_records) {
  lks <- list()
  for (f in m$files) {
    if (file.exists(f)) {
      lks[[length(lks) + 1L]] <- list(url = paste0(blob_base, f), label = paste("Source:", f))
    }
  }
  for (tf in m$tests) {
    if (file.exists(tf)) {
      lks[[length(lks) + 1L]] <- list(url = paste0(blob_base, tf), label = paste("Tests:", basename(tf)))
    }
  }
  test_stat <- if (!is.na(m$live_passed)) {
    sprintf("%d PASS / %d FAIL (%d blocks)", m$live_passed, m$live_failed, m$test_blocks)
  } else if (m$test_exists) {
    sprintf("%d test_that blocks", m$test_blocks)
  } else {
    "none yet"
  }

  c4_lines <- c(
    c4_lines,
    append_extend(
      m$id,
      tags = m$status,
      links = lks,
      meta = list(
        status = m$status,
        phase = m$phase,
        files = paste(m$files, collapse = ", "),
        loc = as.character(m$loc),
        tests = test_stat
      )
    )
  )
}

# Built-in engines
for (e in engine_records) {
  lks <- list()
  for (f in e$files) {
    if (file.exists(f)) {
      lks[[length(lks) + 1L]] <- list(url = paste0(blob_base, f), label = paste("Source:", f))
    }
  }
  for (tf in e$tests) {
    if (file.exists(tf)) {
      lks[[length(lks) + 1L]] <- list(url = paste0(blob_base, tf), label = paste("Tests:", basename(tf)))
    }
  }
  c4_lines <- c(
    c4_lines,
    append_extend(
      e$id,
      tags = e$status,
      links = lks,
      meta = list(
        status = e$status,
        phase = e$phase,
        package = e$pkg,
        dependency_bucket = e$dependency_bucket,
        loc = as.character(e$loc)
      )
    )
  )
}

# Guardrails
for (g in guardrails) {
  c4_lines <- c(
    c4_lines,
    append_extend(
      g$id,
      tags = if (isTRUE(g$pass)) "guardrail_pass" else "guardrail_fail",
      meta = list(
        verdict = if (isTRUE(g$pass)) "PASS" else "FAIL",
        detail = g$detail,
        git_commit = git_sha,
        checked_at = now_ts
      )
    )
  )
}

# Outer Ecosystem (Out-of-Core Skills & Verifiers)
for (ec in ecosystem_records) {
  lks <- list()
  for (f in ec$files) {
    if (file.exists(f)) {
      lks[[length(lks) + 1L]] <- list(url = paste0(blob_base, f), label = paste("Source:", f))
    }
  }
  for (tf in ec$tests) {
    if (file.exists(tf)) {
      lks[[length(lks) + 1L]] <- list(url = paste0(blob_base, tf), label = paste("Tests:", basename(tf)))
    }
  }
  c4_lines <- c(
    c4_lines,
    append_extend(
      ec$id,
      tags = ec$status,
      links = lks,
      meta = list(
        status = ec$status,
        phase = ec$phase,
        files = paste(ec$files, collapse = ", "),
        loc = as.character(ec$loc)
      )
    )
  )
}

c4_lines <- c(c4_lines, "}")

model_dir <- file.path(map_dir, "model")
dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)
writeLines(enc2utf8(c4_lines), file.path(model_dir, "90-live-status.c4"), useBytes = TRUE)

# --- 6. Emit <map-dir>/status.json -------------------------------------------

status_payload <- list(
  format = "gloss-project-map-status",
  generated_at = now_ts,
  package_version = pkg_version,
  schema_version = schema_version,
  git = list(
    sha = git_sha,
    branch = git_branch,
    subject = git_subject
  ),
  summary = list(
    exports_implemented = n_api_done,
    exports_total = length(api_records),
    modules_implemented = n_mod_done,
    modules_total = length(module_records),
    engines_implemented = n_eng_done,
    engines_total = length(engine_records),
    guardrails_passed = n_guard_pass,
    guardrails_total = length(guardrails),
    all_guardrails_passed = all_guards_ok,
    r_files = length(r_files),
    r_loc = count_loc(r_files),
    test_files = length(test_files),
    tests = test_summary
  ),
  guardrails = guardrails,
  apis = api_records,
  modules = module_records,
  engines = engine_records,
  ecosystem = ecosystem_records
)

json_txt <- as.character(jsonlite::toJSON(
  status_payload,
  auto_unbox = TRUE,
  pretty = TRUE,
  null = "null",
  na = "null"
))
writeLines(enc2utf8(json_txt), file.path(map_dir, "status.json"), useBytes = TRUE)

# --- 7. Optional Markdown Summary (for CI Step Summary) ----------------------

md_lines <- c(
  "## gloss Project Map — Code vs Design Intent Alignment",
  "",
  sprintf("- **Version**: `%s` | **Commit**: `%s` (`%s`) | **Updated**: `%s`",
          pkg_version, git_sha, git_branch, now_ts),
  sprintf("- **Progress**: APIs `%d/%d` | Core Modules `%d/%d` | Built-in Engines `%d/%d` | Guardrails `%d/%d`",
          n_api_done, length(api_records),
          n_mod_done, length(module_records),
          n_eng_done, length(engine_records),
          n_guard_pass, length(guardrails)),
  "",
  "| Guardrail | Verdict | Detail |",
  "| --- | :---: | --- |"
)
for (g in guardrails) {
  badge <- if (isTRUE(g$pass)) "PASS" else "FAIL"
  md_lines <- c(md_lines, sprintf("| %s | **%s** | %s |", g$name, badge, g$detail))
}

if (!is.null(summary_file) && nzchar(summary_file)) {
  cat(paste0(paste(md_lines, collapse = "\n"), "\n"), file = summary_file, append = TRUE)
}

cat(sprintf(
  "[project-map] Generated 90-live-status.c4 & status.json | APIs %d/%d | Modules %d/%d | Engines %d/%d | Guardrails %d/%d\n",
  n_api_done, length(api_records),
  n_mod_done, length(module_records),
  n_eng_done, length(engine_records),
  n_guard_pass, length(guardrails)
))

if (isTRUE(strict_mode) && !isTRUE(all_guards_ok)) {
  stop("One or more gloss architectural guardrails failed (--strict).", call. = FALSE)
}
