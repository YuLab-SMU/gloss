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
