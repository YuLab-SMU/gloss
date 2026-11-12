# Do the owner's free models drive tools to a validated submission?
# (plan 2026-11-12-agent-path, Task 1; predictions 102-107 in
# bench/predictions.md, committed before the first run.)
#
#   Rscript bench/agent/drive-tools.R --dry     # no model: the tools and the truth, checked by a script
#   Rscript bench/agent/drive-tools.R           # 3 models x 2 variants x 5 questions x 2 runs
#
# Host only: the gateway is on the host, and the one figure is hand-built
# from mtcars (no third-party code). The gateway's key is read from
# ANTHROPIC_AUTH_TOKEN and is never printed or archived. Nothing here is
# part of the package: it is a harness to learn whether tools are worth
# building into it.
#
# Variant L (lookup): the element's binding is one tool call away.
# Variant M (masked): no binding tool; the model works the row out from the
# element's place, the panel's scales and the table.
# A run is correct when it ends with a submission that `submit` accepted
# for the element asked about. `submit` accepts only the checked pairing.

suppressMessages({
  pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE)
  library(ggplot2)
})

`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a
args <- commandArgs(trailingOnly = TRUE)
dry <- "--dry" %in% args
gateway <- "http://127.0.0.1:3425/v1"
models <- c("westlakehpc/glm-5.3-flash", "westlakehpc/deepseek-v4.1-flash", "westlakehpc/Qwen3.8-27B")
variants <- c("L", "M")
n_questions <- 5L
n_repeats <- 2L
max_steps <- 12L

# ---- the figure and the questions -------------------------------------------

p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point() + facet_wrap(~am)
fig <- gloss::gloss(p, width = 7, height = 4, context = FALSE)
truth <- gloss::gl_bindings(fig)
stopifnot(nrow(truth) == 32L, all(truth$status == "verified"), all(truth$table == "built_layer1"))
elements <- gloss::gl_elements(fig)
panels <- gloss::gl_panels(fig)
built <- gloss::gl_table(fig, "built_layer1")
centre <- function(id) {
  e <- elements[match(id, elements$id), ]
  list(x = round((e$x0 + e$x1) / 2, 2), y = round((e$y0 + e$y1) / 2, 2))
}
set.seed(20261112)
asked <- sample(truth$element, n_questions)
questions <- lapply(asked, function(id) {
  at <- centre(id)
  list(element = id, cx = at$x, cy = at$y, row = truth$row[truth$element == id],
       text = sprintf(paste(
         "The figure has a circle centred at (%.2f, %.2f) pt.",
         "Which row of the table `built_layer1` does this circle draw?",
         "Find the element, work out the row, and submit it."), at$x, at$y))
})
system_prompt <- paste(
  "You answer questions about a figure by calling tools. You cannot see the figure.",
  "Coordinates are in pt from the top left of the page; data values are on the scales of a panel.",
  "When you know the answer, call `submit`. If `submit` is rejected, read the reason and try again.",
  "An answer counts only when `submit` accepts it."
)

# ---- the tools: closures over the figure and one run's log ------------------

json <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, digits = 6, na = "null", dataframe = "rows"))

make_tools <- function(variant, log) {
  note <- function(name, args, result, ok = TRUE) {
    log$calls[[length(log$calls) + 1L]] <- list(tool = name, args = args, ok = ok, result = substr(result, 1L, 400L))
    result
  }
  guarded <- function(name, fn) {
    function(...) {
      a <- list(...)
      out <- tryCatch(fn(...), error = function(e) NULL)
      if (is.null(out)) return(note(name, a, json(list(error = "the call failed: check the arguments")), ok = FALSE))
      note(name, a, json(out))
    }
  }
  panel_of_row <- function(row) panels$id[as.integer(as.character(built$PANEL[row]))]
  z <- aisdk::z_object
  tools <- list(
    overview = aisdk::tool(
      "overview", "The figure's size, its panels with their place on the page and their scales, and its tables.",
      aisdk::z_empty_object(), guarded("overview", function() {
        list(width_pt = fig$meta$width * 72, height_pt = fig$meta$height * 72,
             panels = panels[c("id", "key", "x0", "y0", "x1", "y1", "x_min", "x_max", "y_min", "y_max")],
             tables = list(list(name = "built_layer1", rows = nrow(built), columns = names(built),
                                note = "PANEL k is the panel with id panelk")),
             elements = nrow(elements))
      })),
    find_elements = aisdk::tool(
      "find_elements", "The elements drawn at a point of the page (pt from the top left), topmost first.",
      z(x = aisdk::z_number("horizontal position, pt"), y = aisdk::z_number("vertical position, pt")),
      guarded("find_elements", function(x, y) {
        h <- gloss::gl_hit(fig, as.numeric(x), as.numeric(y), tolerance = 1)
        h$cx <- round((h$x0 + h$x1) / 2, 2)
        h$cy <- round((h$y0 + h$y1) / 2, 2)
        h[c("id", "tag", "leaf", "panel", "cx", "cy", "fill")]
      })),
    get_rows = aisdk::tool(
      "get_rows", "Rows of a table by their row numbers.",
      z(table = aisdk::z_string("table name"), rows = aisdk::z_array(aisdk::z_integer(), "row numbers, at most 10")),
      guarded("get_rows", function(table, rows) {
        stopifnot(identical(table, "built_layer1"))
        r <- as.integer(unlist(rows))
        stopifnot(length(r) >= 1L, length(r) <= 10L, all(r >= 1L & r <= nrow(built)))
        cbind(row = r, built[r, c("x", "y", "colour", "PANEL", "group")])
      })),
    submit = aisdk::tool(
      "submit", "Submit the answer: the element and the row of the table it draws. Returns accepted, or the reason it was rejected.",
      z(element = aisdk::z_string("element id"), table = aisdk::z_string("table name"), row = aisdk::z_integer("row number")),
      function(element, table, row) {
        a <- list(element = element, table = table, row = row)
        errors <- character()
        row <- suppressWarnings(as.integer(row))
        if (!element %in% elements$id) errors <- c(errors, sprintf("no element '%s'", element))
        if (!identical(table, "built_layer1")) errors <- c(errors, sprintf("no table '%s'", table))
        if (is.na(row) || row < 1L || row > nrow(built)) errors <- c(errors, "the row is outside the table")
        if (!length(errors)) {
          t <- truth[truth$element == element, ]
          if (!nrow(t)) {
            errors <- "this element is not one a layer drew"
          } else if (t$row != row) {
            px <- gloss::gl_to_pixel(fig, panel_of_row(row), built$x[row], built$y[row])
            at <- centre(element)
            errors <- sprintf("row %d is drawn %.1f pt from this element; the tolerance is 0.5 pt",
                              row, max(abs(px$x - at$x), abs(px$y - at$y)))
          }
        }
        ok <- !length(errors)
        log$submissions[[length(log$submissions) + 1L]] <- list(element = element, row = row, accepted = ok)
        note("submit", a, json(if (ok) list(accepted = TRUE) else list(accepted = FALSE, errors = as.list(errors))), ok = TRUE)
      })
  )
  if (variant == "L") {
    tools$get_binding <- aisdk::tool(
      "get_binding", "The row of a table that an element draws, as checked against the page.",
      z(element = aisdk::z_string("element id")),
      guarded("get_binding", function(element) {
        t <- truth[truth$element == element, c("element", "table", "row", "status")]
        stopifnot(nrow(t) == 1L)
        as.list(t)
      }))
  } else {
    tools$to_data <- aisdk::tool(
      "to_data", "The data values at a point of the page, on the scales of a panel.",
      z(panel = aisdk::z_string("panel id"), x = aisdk::z_number("horizontal position, pt"),
        y = aisdk::z_number("vertical position, pt")),
      guarded("to_data", function(panel, x, y) {
        d <- gloss::gl_to_data(fig, panel, as.numeric(x), as.numeric(y))
        list(panel = panel, x = signif(d$x, 6), y = signif(d$y, 6))
      }))
    tools$find_rows <- aisdk::tool(
      "find_rows", "The five rows of a table nearest to given data values of x and y, within one panel.",
      z(table = aisdk::z_string("table name"), panel = aisdk::z_string("panel id"),
        x = aisdk::z_number("x data value"), y = aisdk::z_number("y data value")),
      guarded("find_rows", function(table, panel, x, y) {
        stopifnot(identical(table, "built_layer1"), panel %in% panels$id)
        pr <- panels[panels$id == panel, ]
        k <- which(as.integer(as.character(built$PANEL)) == match(panel, panels$id))
        d <- pmax(abs(built$x[k] - as.numeric(x)) / (pr$x_max - pr$x_min),
                  abs(built$y[k] - as.numeric(y)) / (pr$y_max - pr$y_min))
        o <- k[order(d)][seq_len(min(5L, length(k)))]
        cbind(row = o, built[o, c("x", "y", "PANEL")])
      }))
  }
  unname(tools)
}

new_log <- function() {
  log <- new.env(parent = emptyenv())
  log$calls <- list()
  log$submissions <- list()
  log
}

score <- function(log, q) {
  acc <- Filter(function(s) isTRUE(s$accepted), log$submissions)
  hit <- Filter(function(s) identical(s$element, q$element), acc)
  # the harness's invariant: `submit` accepts only the checked pairing
  stopifnot(all(vapply(acc, function(s) identical(s$row, truth$row[truth$element == s$element]), logical(1))))
  list(correct = length(hit) > 0L,
       tool_calls = length(log$calls),
       failed_calls = sum(!vapply(log$calls, function(c) isTRUE(c$ok), logical(1))),
       rejected = sum(!vapply(log$submissions, function(s) isTRUE(s$accepted), logical(1))))
}

# ---- dry run: the tools and the truth, with no model --------------------------

if (dry) {
  run_tool <- function(tools, name, a) {
    t <- Filter(function(t) identical(t$name, name), tools)[[1]]
    jsonlite::fromJSON(t$run(a))
  }
  for (q in questions) {
    for (v in variants) {
      log <- new_log()
      tools <- make_tools(v, log)
      hit <- run_tool(tools, "find_elements", list(x = q$cx, y = q$cy))
      el <- hit$id[hit$tag == "circle"][1]
      row <- if (v == "L") {
        run_tool(tools, "get_binding", list(element = el))$row
      } else {
        d <- run_tool(tools, "to_data", list(panel = hit$panel[hit$tag == "circle"][1], x = q$cx, y = q$cy))
        run_tool(tools, "find_rows", list(table = "built_layer1", panel = d$panel, x = d$x, y = d$y))$row[1]
      }
      wrong <- run_tool(tools, "submit", list(element = el, table = "built_layer1", row = if (row == 1L) 2L else 1L))
      right <- run_tool(tools, "submit", list(element = el, table = "built_layer1", row = row))
      s <- score(log, q)
      cat(sprintf("%s %s (%.2f, %.2f) -> %s row %d | wrong row rejected: %s | right row accepted: %s | correct: %s\n",
                  v, q$element, q$cx, q$cy, el, row, !isTRUE(wrong$accepted), isTRUE(right$accepted), s$correct))
      stopifnot(identical(el, q$element), row == q$row, !isTRUE(wrong$accepted), isTRUE(right$accepted), s$correct)
    }
  }
  cat("dry run: every question reaches its checked row through the tools, in both variants\n")
  quit(status = 0)
}

# ---- the runs -------------------------------------------------------------------

key <- Sys.getenv("ANTHROPIC_AUTH_TOKEN")
if (!nzchar(key)) stop("the gateway's key is not in the environment")
provider <- aisdk::create_openai(api_key = key, base_url = gateway, api_format = "chat", name = "magpie",
                                 total_timeout_seconds = 180)
stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")  # as the other runs in bench/runs
out_base <- file.path("bench", "runs", paste0(stamp, "-drive-tools"))
runs <- list()
for (model_id in models) {
  model <- provider$language_model(model_id)
  for (v in variants) for (qi in seq_along(questions)) for (rep in seq_len(n_repeats)) {
    q <- questions[[qi]]
    log <- new_log()
    t0 <- Sys.time()
    res <- tryCatch(
      aisdk::generate_text(model = model, system = system_prompt, prompt = q$text,
                           tools = make_tools(v, log), max_steps = max_steps, temperature = 0),
      error = function(e) e)
    secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    s <- score(log, q)
    failed <- inherits(res, "error")
    run <- c(list(model = model_id, variant = v, question = qi, element = q$element, row = q$row, rep = rep,
                  seconds = round(secs, 2),
                  error = if (failed) substr(conditionMessage(res), 1L, 300L) else NA_character_,
                  finish = if (failed) NA_character_ else as.character(res$finish_reason %||% NA),
                  steps = if (failed) NA_integer_ else as.integer(res$steps %||% NA),
                  calls_seen_by_aisdk = if (failed) NA_integer_ else length(res$all_tool_calls),
                  usage = if (failed) NULL else res$usage,
                  text = if (failed) NA_character_ else substr(paste(res$text, collapse = " "), 1L, 300L)),
             s, list(calls = log$calls, submissions = log$submissions))
    runs[[length(runs) + 1L]] <- run
    cat(sprintf("%-32s %s q%d r%d  %s  calls %2d  rejected %d  failed %d  %5.1f s%s\n",
                model_id, v, qi, rep, if (s$correct) "correct" else "WRONG  ", s$tool_calls, s$rejected,
                s$failed_calls, secs, if (failed) paste("  error:", run$error) else ""))
  }
}
meta <- list(stamp = stamp, script = "bench/agent/drive-tools.R", gateway = gateway, models = models,
             aisdk = as.character(utils::packageVersion("aisdk")), gloss_commit = system("git rev-parse --short HEAD", intern = TRUE),
             max_steps = max_steps, temperature = 0, system_prompt = system_prompt,
             questions = lapply(questions, function(q) q[c("element", "cx", "cy", "row", "text")]))
writeLines(jsonlite::toJSON(list(meta = meta, runs = runs), auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"),
           paste0(out_base, ".json"))
flat <- do.call(rbind, lapply(runs, function(r) {
  as.data.frame(r[c("model", "variant", "question", "element", "row", "rep", "seconds", "error", "finish", "steps",
                    "calls_seen_by_aisdk", "correct", "tool_calls", "failed_calls", "rejected")], stringsAsFactors = FALSE)
}))
utils::write.csv(flat, paste0(out_base, ".csv"), row.names = FALSE)
cat("archived:", paste0(out_base, c(".json", ".csv")), "\n")
