# Score a role classification run against the committed development labels.
#
#   Rscript bench/R/score-classify.R bench/runs/<stamp>-classify-dev.csv
#
# The classifier never reads labels while it runs. This script joins the
# archived element table to the labels after the run and reports coverage,
# accuracy, residue reasons, checks and silent errors.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("usage: Rscript bench/R/score-classify.R <run.csv>")
run_file <- args[1]
el_file <- sub("\\.csv$", "-elements.csv", run_file)
check_file <- sub("\\.csv$", "-checks.csv", run_file)
summary_file <- run_file
if (!file.exists(el_file)) stop("missing element table: ", el_file)

read_chr <- function(f) utils::read.csv(f, stringsAsFactors = FALSE, colClasses = "character", na.strings = character())
parse_elements <- function(spec, n) {
  spec <- gsub("\\s", "", spec)
  if (identical(spec, "all") || !nzchar(spec)) return(seq_len(n))
  parts <- strsplit(strsplit(spec, ",", fixed = TRUE)[[1]], "-", fixed = TRUE)
  out <- unlist(lapply(parts, function(p) {
    v <- suppressWarnings(as.integer(p))
    if (anyNA(v) || !length(v) || length(v) > 2L) return(integer())
    if (length(v) == 2L) seq.int(v[1], v[2]) else v
  }))
  if (anyNA(out) || any(out < 1L | out > n)) stop("invalid element range: ", spec)
  out
}

idx <- read_chr("bench/labels/sheets/index.csv")
idx <- idx[idx$status == "captured", , drop = FALSE]
label_rows <- list()
for (id in idx$id) {
  sh <- read_chr(file.path("bench/labels/sheets", paste0(id, ".csv")))
  lb <- read_chr(file.path("bench/labels/dev", paste0(id, ".csv")))
  at <- match(paste(lb$key, lb$occurrence), paste(sh$key, sh$occurrence))
  for (i in seq_len(nrow(lb))) {
    if (is.na(at[i]) || !nzchar(lb$role[i])) next
    n <- as.integer(sh$n_elements[at[i]])
    for (j in parse_elements(lb$elements[i], n)) {
      label_rows[[length(label_rows) + 1L]] <- data.frame(
        id = id, leaf = sh$leaf[at[i]], ordinal = j,
        label_role = lb$role[i], label_kind = lb$kind[i], stringsAsFactors = FALSE
      )
    }
  }
}
labels <- do.call(rbind, label_rows)
els <- read_chr(el_file)
if ("ordinal" %in% names(els)) els$ordinal <- as.integer(els$ordinal)
if ("flagged" %in% names(els)) els$flagged <- as.logical(els$flagged)
els$ordinal <- as.integer(els$ordinal)
sc <- merge(els, labels, by = c("id", "leaf", "ordinal"), all.x = TRUE, sort = FALSE)
sc$classified <- sc$status == "classified" & !is.na(sc$role)
sc$role_correct <- sc$classified & sc$role == sc$label_role
sc$kind_correct <- sc$classified & sc$kind == sc$label_kind
sc$silent_error <- sc$classified & !sc$role_correct & !(sc$flagged %in% TRUE)
sc$flagged_correct <- sc$classified & sc$role_correct & (sc$flagged %in% TRUE)
sc$labelled <- !is.na(sc$label_role)

pct <- function(a, b) if (!b) "-" else sprintf("%.1f%%", 100 * a / b)
line <- function(...) cat(sprintf(...), "\n", sep = "")
sumtab <- read_chr(summary_file)
line("== run")
print(sumtab[, intersect(c("id", "engine", "status", "elements", "classified", "residue", "flagged"), names(sumtab)), drop = FALSE], row.names = FALSE)

line("\n== overall elements")
line("labelled %d; classified %d (%s); residue %d (%s)", sum(sc$labelled), sum(sc$classified & sc$labelled),
     pct(sum(sc$classified & sc$labelled), sum(sc$labelled)), sum(!sc$classified & sc$labelled),
     pct(sum(!sc$classified & sc$labelled), sum(sc$labelled)))
line("role correct among classified %d / %d (%s); kind correct %d / %d (%s)",
     sum(sc$role_correct), sum(sc$classified), pct(sum(sc$role_correct), sum(sc$classified)),
     sum(sc$kind_correct), sum(sc$classified), pct(sum(sc$kind_correct), sum(sc$classified)))
line("silent errors %d; flagged-but-correct %d; flagged correct share %s", sum(sc$silent_error), sum(sc$flagged_correct),
     pct(sum(sc$flagged_correct), sum(sc$role_correct)))

line("\n== by engine")
by_engine <- do.call(rbind, lapply(split(sc[sc$labelled, , drop = FALSE], sc$engine[sc$labelled]), function(d) {
  data.frame(elements = nrow(d), classified = sum(d$classified), residue = sum(!d$classified),
             coverage = pct(sum(d$classified), nrow(d)), role_correct = sum(d$role_correct),
             accuracy = pct(sum(d$role_correct), sum(d$classified)),
             silent_errors = sum(d$silent_error), flagged_correct = sum(d$flagged_correct))
}))
print(by_engine)

line("\n== by labelled role")
by_role <- do.call(rbind, lapply(split(sc[sc$labelled & sc$classified, , drop = FALSE], sc$label_role[sc$labelled & sc$classified]), function(d) {
  data.frame(classified = nrow(d), correct = sum(d$role_correct), silent_errors = sum(d$silent_error), flagged_correct = sum(d$flagged_correct))
}))
print(by_role)

line("\n== residue reasons")
res <- sc[sc$labelled & !sc$classified, , drop = FALSE]
if (nrow(res)) print(sort(table(res$reason), decreasing = TRUE)) else line("none")
if (nrow(res)) {
  line("\n== residue by figure")
  rf <- do.call(rbind, lapply(split(sc[sc$labelled, , drop = FALSE], sc$id[sc$labelled]), function(d) {
    data.frame(id = d$id[1], engine = d$engine[1], elements = nrow(d), classified = sum(d$classified),
               residue = sum(!d$classified), coverage = pct(sum(d$classified), nrow(d)), stringsAsFactors = FALSE)
  }))
  print(rf[order(rf$engine, rf$id), ], row.names = FALSE)
}

line("\n== checks")
if (file.exists(check_file)) {
  ck <- read_chr(check_file)
  if (nrow(ck)) {
    ck$passed <- as.logical(ck$passed)
    print(stats::aggregate(cbind(passed = ck$passed, failed = !ck$passed) ~ check, ck, sum))
  } else line("none")
} else line("no checks table")

line("\n== silent errors")
bad <- sc[sc$silent_error, c("id", "engine", "leaf", "ordinal", "role", "kind", "label_role", "label_kind", "rule", "reason"), drop = FALSE]
if (nrow(bad)) print(bad, row.names = FALSE) else line("none")
