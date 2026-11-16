# Closed semantic checks (design: 检查原语). These checks operate on a table
# already built by the drawing engine. They return evidence rather than a
# bare boolean so a claim can distinguish verified, failed, partial and
# uncheckable groups without asking a model to judge the data.

semantic_check_result <- function(kind, status, groups = NULL, reason = NULL,
                                  args = list(), plugin = NULL) {
  passed <- switch(status,
                   verified = TRUE,
                   failed = FALSE,
                   partial = FALSE,
                   refused = NA,
                   NA)
  structure(list(kind = kind, status = status, passed = passed,
                 groups = groups, reason = reason, args = args,
                 plugin = plugin),
            class = c("gloss_check", "list"))
}

#' Run a registered semantic check on built data
#'
#' A semantic check is a closed, deterministic function over one built data
#' table. It returns group-level evidence and one of four statuses: `verified`
#' when every runnable group passes, `failed` when every runnable group fails,
#' `partial` when the evidence is mixed or incomplete, and `refused` when the
#' check cannot run. The function does not create a record or change a figure.
#'
#' @param table A data frame, normally one of a figure's built tables.
#' @param kind Name of a registered `check` plugin.
#' @param args Named arguments for the plugin's schema.
#' @return A `gloss_check` with `kind`, `status`, `passed`, `groups`, `reason`,
#'   `args` and `plugin` fields.
#' @export
gl_check <- function(table, kind, args = list()) {
  if (!is.data.frame(table)) {
    cli::cli_abort("{.arg table} must be a data frame of built data.")
  }
  if (!is_string(kind)) {
    cli::cli_abort("{.arg kind} must be a single check name.")
  }
  if (!is.list(args) || (length(args) && is.null(names(args)))) {
    cli::cli_abort("{.arg args} must be a named list.")
  }
  plugin <- gl_plugin("check", kind)
  problems <- gl_schema_validate(args, plugin$schema)
  if (length(problems)) {
    cli::cli_abort(c("Invalid arguments for check {.val {kind}}.", bullets_x(problems)))
  }
  out <- tryCatch(plugin$run(table, args), error = function(e) {
    semantic_check_result(kind, "refused", reason = conditionMessage(e),
                          args = args, plugin = plugin_row(plugin))
  })
  normalize_semantic_check(out, kind, args, plugin)
}

normalize_semantic_check <- function(out, kind, args, plugin) {
  if (is.logical(out) && length(out) == 1L && !is.na(out)) {
    return(semantic_check_result(kind, if (out) "verified" else "failed",
                                 args = args, plugin = plugin_row(plugin)))
  }
  if (!is.list(out) || !is_string(out$status) ||
      !out$status %in% c("verified", "failed", "partial", "refused")) {
    return(semantic_check_result(
      kind, "refused",
      reason = "the check plugin returned no valid semantic status",
      args = args, plugin = plugin_row(plugin)
    ))
  }
  out$kind <- kind
  out$passed <- switch(out$status,
                       verified = TRUE,
                       failed = FALSE,
                       partial = FALSE,
                       refused = NA,
                       NA)
  out$args <- args
  out$plugin <- plugin_row(plugin)
  class(out) <- c("gloss_check", "list")
  out
}

#' @export
print.gloss_check <- function(x, ...) {
  cat(sprintf("<gloss check> %s (%s)\n", x$kind, x$status))
  if (!is.null(x$reason) && nzchar(x$reason)) cat("  ", x$reason, "\n", sep = "")
  if (is.data.frame(x$groups) && nrow(x$groups)) {
    cat(sprintf("  %d group%s with evidence\n", nrow(x$groups), if (nrow(x$groups) == 1L) "" else "s"))
  }
  invisible(x)
}

register_check_trend <- function() {
  gl_register(
    "check", "trend", "0.1.0", package = "gloss",
    description = "Check the sign of a per-group linear trend in built data.",
    schema = list(
      response = "string",
      predictor = "string",
      "by?" = list(type = "array", items = "string"),
      expect = c("positive", "negative", "zero")
    ),
    run = check_trend
  )
}

register_check_count <- function() {
  gl_register(
    "check", "count", "0.1.0", package = "gloss",
    description = "Check row counts, optionally within groups.",
    schema = list(
      "by?" = list(type = "array", items = "string"),
      "equals?" = "integer",
      "min?" = "integer",
      "max?" = "integer"
    ),
    run = check_count
  )
}

register_check_value <- function() {
  gl_register(
    "check", "value", "0.1.0", package = "gloss",
    description = "Check that a column has an expected value.",
    schema = list(
      column = "string", value = "any", "row?" = "integer",
      "by?" = list(type = "array", items = "string")
    ),
    run = check_value
  )
}

register_check_compare <- function() {
  gl_register(
    "check", "compare", "0.1.0", package = "gloss",
    description = "Compare two numeric columns by a closed summary statistic.",
    schema = list(
      left = "string", right = "string",
      "stat?" = c("mean", "median", "sum", "min", "max"),
      expect = c("less", "less_equal", "equal", "greater_equal", "greater"),
      "by?" = list(type = "array", items = "string"),
      "tolerance?" = "number"
    ),
    run = check_compare
  )
}

register_check_range <- function() {
  gl_register(
    "check", "range", "0.1.0", package = "gloss",
    description = "Check that a numeric column lies in a closed range.",
    schema = list(
      column = "string", "min?" = "number", "max?" = "number",
      "inclusive?" = "boolean"
    ),
    run = check_range
  )
}

register_check_exists <- function() {
  gl_register(
    "check", "exists", "0.1.0", package = "gloss",
    description = "Check that a table contains a matching value.",
    schema = list(
      column = "string", value = "any", "op?" = c("==", "!=", "contains")
    ),
    run = check_exists
  )
}

semantic_check_groups <- function(table, by) {
  if (!length(by)) return(list(all = seq_len(nrow(table))))
  key <- as.data.frame(lapply(table[by], as.character), stringsAsFactors = FALSE)
  if (!nrow(key)) return(list())
  id <- do.call(paste, c(key, sep = " / "))
  split(seq_len(nrow(table)), id, drop = TRUE)
}

check_missing_columns <- function(table, columns, kind) {
  missing <- setdiff(columns, names(table))
  if (!length(missing)) return(NULL)
  semantic_check_result(
    kind, "refused",
    reason = sprintf("missing column%s: %s", if (length(missing) == 1L) "" else "s",
                     paste(missing, collapse = ", "))
  )
}

check_status_from_evidence <- function(evidence, passed, kind, reason = NULL) {
  passed <- as.logical(passed)
  runnable <- !is.na(passed)
  evidence$passed <- passed
  if (!any(runnable)) {
    status <- "refused"
    reason <- reason %||% "no group could be checked"
  } else if (all(passed[runnable])) {
    status <- "verified"
  } else if (all(!passed[runnable])) {
    status <- "failed"
  } else {
    status <- "partial"
    reason <- reason %||% "some groups passed and some groups failed"
  }
  semantic_check_result(kind, status, groups = evidence, reason = reason)
}

check_count <- function(table, args) {
  by <- args$by %||% character()
  missing <- check_missing_columns(table, by, "count")
  if (!is.null(missing)) return(missing)
  if (is.null(args$equals) && is.null(args$min) && is.null(args$max)) {
    return(semantic_check_result("count", "refused",
                                 reason = "supply equals, min or max"))
  }
  groups <- semantic_check_groups(table, by)
  if (!length(groups)) return(semantic_check_result("count", "refused", reason = "the table has no rows"))
  evidence <- do.call(rbind, lapply(names(groups), function(label) {
    n <- length(groups[[label]])
    ok <- (is.null(args$equals) || n == args$equals) &&
      (is.null(args$min) || n >= args$min) &&
      (is.null(args$max) || n <= args$max)
    data.frame(group = label, n = n, expected = args$equals %||% NA_integer_,
               passed = ok, reason = if (ok) NA_character_ else "count outside expected range",
               stringsAsFactors = FALSE)
  }))
  check_status_from_evidence(evidence, evidence$passed, "count")
}

check_value <- function(table, args) {
  by <- args$by %||% character()
  missing <- check_missing_columns(table, c(args$column, by), "value")
  if (!is.null(missing)) return(missing)
  rows <- if (!is.null(args$row)) as.integer(args$row) else seq_len(nrow(table))
  if (any(rows < 1L | rows > nrow(table))) {
    return(semantic_check_result("value", "refused", reason = "row is outside the table"))
  }
  x <- table[[args$column]][rows]
  equal <- function(v) {
    if (length(v) != 1L || is.na(v) || is.na(args$value)) return(identical(v, args$value))
    isTRUE(all.equal(v, args$value, tolerance = 1e-12, check.attributes = FALSE))
  }
  passed <- vapply(x, equal, logical(1))
  evidence <- data.frame(row = rows, value = as.character(x), passed = passed,
                         reason = ifelse(passed, NA_character_, "value differs from expected"),
                         stringsAsFactors = FALSE)
  check_status_from_evidence(evidence, passed, "value")
}

check_compare <- function(table, args) {
  by <- args$by %||% character()
  missing <- check_missing_columns(table, c(args$left, args$right, by), "compare")
  if (!is.null(missing)) return(missing)
  if (!is.numeric(table[[args$left]]) || !is.numeric(table[[args$right]])) {
    return(semantic_check_result("compare", "refused",
                                 reason = "left and right columns must be numeric"))
  }
  stat <- args$stat %||% "mean"
  fun <- switch(stat, mean = mean, median = stats::median, sum = sum, min = min, max = max)
  groups <- semantic_check_groups(table, by)
  if (!length(groups)) return(semantic_check_result("compare", "refused", reason = "the table has no rows"))
  tol <- args$tolerance %||% 1e-12
  evidence <- do.call(rbind, lapply(names(groups), function(label) {
    idx <- groups[[label]]
    left <- table[[args$left]][idx]; right <- table[[args$right]][idx]
    keep <- is.finite(left) & is.finite(right)
    if (!any(keep)) {
      return(data.frame(group = label, left = NA_real_, right = NA_real_,
                        passed = NA, reason = "no finite paired values",
                        stringsAsFactors = FALSE))
    }
    lv <- fun(left[keep]); rv <- fun(right[keep])
    passed <- switch(args$expect,
      less = lv < rv - tol,
      less_equal = lv <= rv + tol,
      equal = abs(lv - rv) <= tol,
      greater_equal = lv >= rv - tol,
      greater = lv > rv + tol
    )
    data.frame(group = label, left = lv, right = rv, passed = passed,
               reason = if (passed) NA_character_ else "comparison failed",
               stringsAsFactors = FALSE)
  }))
  check_status_from_evidence(evidence, evidence$passed, "compare")
}

check_range <- function(table, args) {
  missing <- check_missing_columns(table, args$column, "range")
  if (!is.null(missing)) return(missing)
  if (!is.numeric(table[[args$column]])) {
    return(semantic_check_result("range", "refused", reason = "column must be numeric"))
  }
  if (is.null(args$min) && is.null(args$max)) {
    return(semantic_check_result("range", "refused", reason = "supply min or max"))
  }
  inclusive <- args$inclusive %||% TRUE
  x <- table[[args$column]]
  passed <- is.finite(x)
  if (!is.null(args$min)) passed <- passed & if (inclusive) x >= args$min else x > args$min
  if (!is.null(args$max)) passed <- passed & if (inclusive) x <= args$max else x < args$max
  evidence <- data.frame(row = seq_along(x), value = x, passed = passed,
                         reason = ifelse(passed, NA_character_, "value outside expected range"),
                         stringsAsFactors = FALSE)
  check_status_from_evidence(evidence, passed, "range")
}

check_exists <- function(table, args) {
  missing <- check_missing_columns(table, args$column, "exists")
  if (!is.null(missing)) return(missing)
  x <- table[[args$column]]
  op <- args$op %||% "=="
  hit <- switch(op,
    `==` = !is.na(x) & x == args$value,
    `!=` = !is.na(x) & x != args$value,
    contains = !is.na(x) & grepl(as.character(args$value), as.character(x), fixed = TRUE)
  )
  hit[is.na(hit)] <- FALSE
  evidence <- data.frame(row = seq_along(x), value = as.character(x), passed = hit,
                         reason = ifelse(hit, NA_character_, "no matching value"),
                         stringsAsFactors = FALSE)
  semantic_check_result("exists", if (any(hit)) "verified" else "failed",
                        groups = evidence,
                        reason = if (any(hit)) NULL else "no matching value")
}

check_trend <- function(table, args) {
  response <- args$response
  predictor <- args$predictor
  by <- args$by %||% character()
  missing <- setdiff(c(response, predictor, by), names(table))
  if (length(missing)) {
    return(semantic_check_result(
      "trend", "refused",
      reason = sprintf("missing column%s: %s", if (length(missing) == 1L) "" else "s",
                       paste(missing, collapse = ", "))
    ))
  }
  if (!is.numeric(table[[response]]) || !is.numeric(table[[predictor]])) {
    return(semantic_check_result(
      "trend", "refused",
      reason = "response and predictor columns must be numeric"
    ))
  }

  key <- if (length(by)) {
    as.data.frame(lapply(table[by], function(x) as.character(x)),
                  stringsAsFactors = FALSE)
  } else {
    data.frame(.group = rep("all", nrow(table)), stringsAsFactors = FALSE)
  }
  group_id <- if (nrow(key)) do.call(paste, c(key, sep = " / ")) else character()
  groups <- split(seq_len(nrow(table)), group_id, drop = TRUE)
  if (!length(groups)) {
    return(semantic_check_result("trend", "refused",
                                 reason = "the table has no rows"))
  }

  expect_sign <- switch(args$expect, positive = 1, negative = -1, zero = 0)
  rows <- lapply(names(groups), function(label) {
    idx <- groups[[label]]
    x <- table[[predictor]][idx]
    y <- table[[response]][idx]
    keep <- is.finite(x) & is.finite(y)
    x <- x[keep]
    y <- y[keep]
    reason <- NA_character_
    estimate <- NA_real_
    passed <- NA
    if (length(x) < 2L) {
      reason <- "fewer than two finite rows"
    } else if (isTRUE(stats::var(x) == 0)) {
      reason <- "predictor has no variation"
    } else {
      estimate <- unname(stats::coef(stats::lm(y ~ x))[2])
      passed <- switch(args$expect,
                       positive = estimate > 0,
                       negative = estimate < 0,
                       zero = isTRUE(all.equal(estimate, 0, tolerance = 1e-12)))
      if (!passed) reason <- sprintf("slope is %+.6g", estimate)
    }
    data.frame(
      group = label,
      n = length(x),
      estimate = estimate,
      passed = passed,
      reason = reason,
      stringsAsFactors = FALSE
    )
  })
  evidence <- do.call(rbind, rows)
  runnable <- !is.na(evidence$passed)
  if (!any(runnable)) {
    status <- "refused"
    reason <- "no group had enough finite rows and predictor variation"
  } else if (all(runnable) && all(evidence$passed[runnable])) {
    status <- "verified"
    reason <- NULL
  } else if (all(runnable) && all(!evidence$passed[runnable])) {
    status <- "failed"
    reason <- "every runnable group failed the expected trend"
  } else {
    status <- "partial"
    reason <- if (any(!runnable)) {
      if (any(evidence$passed[runnable])) {
        "some groups passed and some groups could not be checked"
      } else {
        "some groups failed and some groups could not be checked"
      }
    } else {
      "some groups passed and some groups failed the expected trend"
    }
  }
  semantic_check_result("trend", status, groups = evidence, reason = reason)
}
