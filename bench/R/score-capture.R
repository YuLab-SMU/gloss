# Score predictions 5-8 on a capture run (bench v0, Task 6), with the rules
# fixed in predictions.md before the first capture run. Reads a capture CSV,
# by default the earliest development run:
#   Rscript bench/R/score-capture.R [bench/runs/<stamp>-capture-dev.csv]

source("bench/R/common.R")
args <- commandArgs(trailingOnly = TRUE)
runs <- sort(list.files(file.path(bench_root, "runs"), pattern = "-capture-dev[.]csv$", full.names = TRUE))
file <- if (length(args)) args[1] else if (length(runs)) runs[1] else stop("no development capture run in bench/runs")
cap <- read_csv(file)
split <- read_csv(file.path(bench_root, "split.csv"))
dev <- split[split$set == "dev", ]
if (!setequal(cap$id, dev$id)) stop("the run does not cover the development set: ", nrow(cap), " of ", nrow(dev), " figures")
cat("run:", basename(file), "|", nrow(cap), "figures\n\n")

# capture.R up to 803437f wrote status NA when gloss() raised an error that is
# not a known refusal (refusal() returned NA_character_, which `%||% "error"`
# does not replace); every other branch writes a string. NA therefore means error.
n_na <- sum(is.na(cap$status) | cap$status == "NA")
if (n_na) cat("status NA read as \"error\" (capture.R labelling bug, fixed after the run):", n_na, "figures\n\n")
cap$status[is.na(cap$status) | cap$status == "NA"] <- "error"
cap$outcome <- ifelse(cap$status == "captured", "captured",
               ifelse(startsWith(cap$status, "refused"), "refused",
               ifelse(cap$status == "timeout", "timeout",
               ifelse(startsWith(cap$status, "rerun") | cap$status == "no figure recovered", "rerun failure", "error"))))
pct <- function(a, b) if (b) sprintf("%d/%d = %.0f%%", a, b, 100 * a / b) else sprintf("%d/0", a)

cat("Outcomes by engine\n")
print(addmargins(table(engine = cap$engine, outcome = cap$outcome)))
cat("\nStatus detail\n"); print(table(cap$status))
bad <- cap[cap$outcome != "captured", c("id", "engine", "recovered", "status", "message")]
if (nrow(bad)) { cat("\nNot captured\n"); bad$message <- substr(bad$message, 1, 90); print(bad, row.names = FALSE) }

reran <- cap[cap$outcome != "rerun failure", ]
got <- cap[cap$outcome == "captured", ]
cat("\nPrediction 5 (>= 90% capture without error)\n")
cat("  captured / figures that rerun:", pct(sum(reran$outcome == "captured"), nrow(reran)), "\n")
cat("  captured / all development figures:", pct(nrow(got), nrow(cap)), "\n")
cat("  verdict:", if (nrow(reran) && sum(reran$outcome == "captured") / nrow(reran) >= 0.9) "right" else "wrong", "\n")

cat("\nPrediction 6 (grid scenes fail more often than returned objects)\n")
fail_share <- function(kind) { x <- reran[reran$recovered %in% kind, ]; c(fail = sum(x$outcome != "captured"), n = nrow(x)) }
g6 <- fail_share("grid"); o6 <- fail_share("object"); b6 <- fail_share("base")
cat("  not captured, recovered by grid.grab():", pct(g6[["fail"]], g6[["n"]]), "\n")
cat("  not captured, returned objects:", pct(o6[["fail"]], o6[["n"]]), "\n")
cat("  not captured, base (recordPlot), for reference:", pct(b6[["fail"]], b6[["n"]]), "\n")
v6 <- if (!g6[["n"]] || !o6[["n"]]) "not scorable" else if (g6[["fail"]] / g6[["n"]] > o6[["fail"]] / o6[["n"]]) "right" else "wrong"
cat("  verdict:", v6, sprintf("(n = %d grid, %d objects)", g6[["n"]], o6[["n"]]), "\n")

cat("\nPrediction 7 (>= 30% of captured figures have a leaf with a count mismatch)\n")
m7 <- sum(got$leaves_mismatch >= 1)
cat("  ", pct(m7, nrow(got)), "| verdict:", if (nrow(got) && m7 / nrow(got) >= 0.3) "right" else "wrong", "\n")
cat("  by engine:\n"); for (en in sort(unique(got$engine))) cat("    ", en, pct(sum(got$leaves_mismatch[got$engine == en] >= 1), sum(got$engine == en)), "\n")

cat("\nPrediction 8 (>= 95% of captured figures: the only unowned element is the device background)\n")
if (anyNA(got$unowned_bg)) cat("  !! background test missing for", sum(is.na(got$unowned_bg)), "figures\n")
ok8 <- !is.na(got$unowned_bg) & got$unowned == got$unowned_bg
cat("  ", pct(sum(ok8), nrow(got)), "| verdict:", if (nrow(got) && sum(ok8) / nrow(got) >= 0.95) "right" else "wrong", "\n")
if (any(!ok8)) {
  cat("  figures with other unowned elements:\n")
  x <- got[!ok8, c("id", "engine", "elements", "unowned", "unowned_bg", "unowned_other")]
  x$unowned_other <- substr(x$unowned_other, 1, 60)
  print(x, row.names = FALSE)
}

cat("\nCapture size and time (captured figures)\n")
print(do.call(rbind, lapply(split(got, got$engine), function(x) data.frame(
  engine = x$engine[1], n = nrow(x), median_elements = stats::median(x$elements), median_leaves = stats::median(x$leaves),
  median_seconds = round(stats::median(x$seconds), 2), max_seconds = round(max(x$seconds), 2)))), row.names = FALSE)

# Not a prediction (added 2026-11-10, after the first run): does the captured
# scene draw exactly what the code drew? Runs from 087476c on record it.
if ("faithful" %in% names(cap)) {
  cat("\nFidelity (captured scene = what the code drew on svglite; not predicted)\n")
  for (en in sort(unique(got$engine))) {
    x <- got[got$engine == en, ]
    cat(sprintf("  %-9s faithful %s | not compared %d | median primitives differing among the rest %s\n", en,
                pct(sum(x$faithful %in% TRUE), sum(!is.na(x$faithful))), sum(is.na(x$faithful)),
                if (any(x$faithful %in% FALSE)) stats::median(x$prims_differ[x$faithful %in% FALSE]) else "-"))
  }
  uf <- got[got$faithful %in% FALSE, c("id", "engine", "recovered", "prims_ref", "prims_scene", "prims_differ")]
  if (nrow(uf)) { cat("  not faithful:\n"); print(uf, row.names = FALSE) }
}

# Fidelity verdicts added with the capture-fidelity slice (2026-11-10). Runs
# before it have no verdict column; their strict fidelity numbers stand.
if ("verdict" %in% names(cap)) {
  cat("\nFidelity verdicts (equal / known exception / different)\n")
  v <- factor(got$verdict, levels = c("equal", "known_exception", "different"))
  print(addmargins(table(engine = got$engine, verdict = v)))

  cat("\nKnown exceptions, with the reason\n")
  ke <- got[got$verdict %in% "known_exception", c("id", "engine", "prims_differ", "exception")]
  if (nrow(ke)) print(ke, row.names = FALSE) else cat("  none\n")

  cat("\nDifferent: first primitives present on only one side\n")
  df <- got[got$verdict %in% "different",
            c("id", "engine", "prims_scene", "prims_ref", "prims_differ", "diff_scene", "diff_ref")]
  if (nrow(df)) {
    df$diff_scene <- substr(df$diff_scene, 1, 70); df$diff_ref <- substr(df$diff_ref, 1, 70)
    print(df, row.names = FALSE)
  } else cat("  none\n")

  ml_ok <- !is.na(got$mismatch_leaves) & nzchar(got$mismatch_leaves)
  cat("\nWhich leaves mismatch:", pct(sum(ml_ok), nrow(got)), "captured figures\n")
  if (any(ml_ok)) print(utils::head(got[ml_ok, c("id", "engine", "leaves_mismatch", "mismatch_leaves")], 8L),
                        row.names = FALSE)
  dl <- got[!is.na(got$dense_leaves) & got$dense_leaves > 0, c("id", "engine", "dense_leaves")]
  cat("Rasterized dense leaves:", nrow(dl), "captured figures\n")
  if (nrow(dl)) print(dl, row.names = FALSE)
}

# Page route (page-capture plan Task 4, 2026-11-11). Runs from then on record
# the bench's proof of determinism, the page the code left against the object
# alone, and gloss's own verdict. Base figures are still drawn by
# gridGraphics (the base engine's drawing step) until plan Task 5.
if ("gloss_verdict" %in% names(cap)) {
  cap$page <- ifelse(cap$engine == "base", "base", ifelse(is.na(cap$page_kind), "-", cap$page_kind))
  cat("\nPage route: outcome by page (base = base engine, through gridGraphics)\n")
  cap$result <- ifelse(cap$outcome == "captured", cap$verdict, cap$status)
  print(addmargins(table(page = cap$page, result = cap$result)))

  cat("\nThe bench's verdict against gloss's own (captured figures)\n")
  print(addmargins(table(bench = got$verdict, gloss = got$gloss_verdict, useNA = "ifany")))
  grid_got <- got[got$engine != "base", ]
  agree <- grid_got$verdict == grid_got$gloss_verdict
  cat("  agreement on grid pages:", pct(sum(agree, na.rm = TRUE), nrow(grid_got)), "\n")
  broken <- got[got$verdict %in% "different" & got$gloss_verdict %in% "equal" & got$engine != "base", ]
  cat("  different for the bench while gloss says equal (failed invariant), grid pages:", nrow(broken), "\n")
  if (nrow(broken)) print(broken[, c("id", "engine", "prims_differ", "diff_scene", "diff_ref")], row.names = FALSE)
  if (any(!agree, na.rm = TRUE)) {
    cat("  disagreements:\n")
    print(grid_got[which(!agree), c("id", "engine", "verdict", "gloss_verdict", "self_differ", "gloss_differ")], row.names = FALSE)
  }
  b <- got[got$engine == "base", ]
  cat("  base pages: gloss compares with gridGraphics' page, the bench with the code's:",
      sum(b$gloss_verdict %in% "equal"), "equal for gloss,", sum(b$verdict %in% "equal"), "equal for the bench, of", nrow(b), "\n")

  cat("\nNot deterministic (two plain drawings differ, the bench's proof)\n")
  nd <- got[got$deterministic %in% FALSE, c("id", "engine", "self_differ", "verdict", "gloss_verdict")]
  if (nrow(nd)) print(nd, row.names = FALSE) else cat("  none\n")

  obj <- got[got$recovered %in% "object", ]
  cat("\nObjects: the object drawn alone against the page the code left:",
      pct(sum(obj$code_faithful %in% TRUE), nrow(obj)), "equal\n")
  oc <- obj[obj$code_faithful %in% FALSE, c("id", "engine", "code_differ", "verdict")]
  if (nrow(oc)) print(oc, row.names = FALSE)

  cat("\nWithheld tables or panels:", pct(sum(nzchar(got$withheld %||% "") & !is.na(got$withheld)), nrow(got)), "captured figures\n")
  wh <- got[!is.na(got$withheld) & nzchar(got$withheld), c("id", "engine", "withheld")]
  if (nrow(wh)) print(wh, row.names = FALSE)

  cat("\nDrawn pages per figure (gloss): more than one in",
      sum(got$pages > 1, na.rm = TRUE), "of", nrow(got), "captured figures\n")
  cat("Dense figures compared on a vector recapture:", sum(got$vector_recapture %in% TRUE), "\n")
}
