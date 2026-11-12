# Task 1's questions again, through the package's own tools (agent-path plan
# 2026-11-12, Task 3, step 4; predictions 120-123 in bench/predictions.md,
# committed before the first run).
#
#   Rscript bench/agent/drive-gl-tools.R --dry    # no model: a script drives gl_tools()
#   Rscript bench/agent/drive-gl-tools.R          # 3 models x 2 variants x 5 questions x 2 runs
#
# Same figure, same five elements (seed 20261112) and same models as
# bench/agent/drive-tools.R. The tools are gloss::gl_tools(fig): variant L
# discloses the bindings made at capture (get_binding), variant M hides
# those of the layer asked about. A run is correct when `propose` accepted
# a binding for the element asked about. Host only; the gateway's key is
# read from ANTHROPIC_AUTH_TOKEN and is never printed or archived.

suppressMessages({
  pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE)
  library(ggplot2)
})
`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a
options(aisdk.skip_internet_check = TRUE)   # the gateway is on this machine
args <- commandArgs(trailingOnly = TRUE)
dry <- "--dry" %in% args
gateway <- "http://127.0.0.1:3425/v1"
models <- c("westlakehpc/glm-5.3-flash", "westlakehpc/deepseek-v4.1-flash", "westlakehpc/Qwen3.8-27B")
variants <- c("L", "M")
n_questions <- 5L
n_repeats <- 2L
max_steps <- 12L

p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point() + facet_wrap(~am)
fig <- gloss::gloss(p, width = 7, height = 4, context = FALSE)
truth <- gloss::gl_bindings(fig)
stopifnot(nrow(truth) == 32L, all(truth$status == "verified"), all(truth$table == "built_layer1"))
elements <- gloss::gl_elements(fig)
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
  "When you know the answer, call `propose`. If `propose` rejects it, read the reason and try again.",
  "An answer counts only when `propose` accepts it."
)
tools_for <- function(variant) gloss::gl_tools(fig, hide = if (variant == "M") unique(truth$leaf))

score <- function(state, q) {
  props <- state$proposals
  acc <- Filter(function(s) identical(s$outcome, "accepted"), props)
  # propose accepts only what the page shows: on this figure, the checked row
  stopifnot(all(vapply(acc, function(s) identical(as.integer(s$record$row), truth$row[truth$element == s$record$element]), logical(1))))
  list(correct = any(vapply(acc, function(s) identical(s$record$element, q$element), logical(1))),
       tool_calls = length(state$calls),
       failed_calls = sum(!vapply(state$calls, function(c) isTRUE(c$ok), logical(1))),
       rejected = sum(vapply(props, function(s) identical(s$outcome, "rejected"), logical(1))),
       refused = sum(vapply(props, function(s) identical(s$outcome, "refused"), logical(1))))
}
flat_calls <- function(state) lapply(state$calls, function(c) c[c("tool", "args", "ok", "result")])
flat_subs <- function(state) lapply(state$proposals, function(s) {
  list(element = s$proposal$element, row = s$proposal$row, accepted = identical(s$outcome, "accepted"),
       outcome = s$outcome, reasons = s$reasons)
})

if (dry) {
  call <- function(tools, name, a) {
    t <- Filter(function(t) identical(t$name, name), tools)[[1]]
    jsonlite::fromJSON(t$run(a))
  }
  for (q in questions) for (v in variants) {
    tools <- tools_for(v)
    hit <- call(tools, "find_elements", list(x = q$cx, y = q$cy))
    el <- hit$id[hit$tag == "circle"][1]
    gb <- call(tools, "get_binding", list(element = el))
    row <- if (v == "L") gb$row else {
      stopifnot(isTRUE(gb$hidden))
      d <- call(tools, "to_data", list(panel = hit$panel[hit$tag == "circle"][1], x = q$cx, y = q$cy))
      call(tools, "find_rows", list(table = "built_layer1", panel = d$panel, x = d$x, y = d$y))$row[1]
    }
    wrong <- call(tools, "propose", list(element = el, table = "built_layer1", row = if (row == 1L) 2L else 1L))
    right <- call(tools, "propose", list(element = el, table = "built_layer1", row = row))
    s <- score(gloss::gl_tool_state(tools), q)
    cat(sprintf("%s %s -> %s row %d | wrong row: %s | right row: %s | correct: %s\n", v, q$element, el, row,
                wrong$outcome, right$outcome, s$correct))
    stopifnot(identical(el, q$element), row == q$row, wrong$outcome == "rejected", right$outcome == "accepted", s$correct)
  }
  cat("dry run: every question reaches its checked row through gl_tools(), in both variants\n")
  quit(status = 0)
}

key <- Sys.getenv("ANTHROPIC_AUTH_TOKEN")
if (!nzchar(key)) stop("the gateway's key is not in the environment")
provider <- aisdk::create_openai(api_key = key, base_url = gateway, api_format = "chat", name = "magpie",
                                 total_timeout_seconds = 180)
stamp <- format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
out_base <- file.path("bench", "runs", paste0(stamp, "-drive-gl-tools"))
runs <- list()
for (model_id in models) {
  model <- provider$language_model(model_id)
  for (v in variants) for (qi in seq_along(questions)) for (rep in seq_len(n_repeats)) {
    q <- questions[[qi]]
    tools <- tools_for(v)
    t0 <- Sys.time()
    res <- tryCatch(
      aisdk::generate_text(model = model, system = system_prompt, prompt = q$text, tools = tools,
                           max_steps = max_steps, temperature = 0),
      error = function(e) e)
    secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    state <- gloss::gl_tool_state(tools)
    s <- score(state, q)
    failed <- inherits(res, "error")
    runs[[length(runs) + 1L]] <- c(
      list(model = model_id, variant = v, question = qi, element = q$element, row = q$row, rep = rep,
           seconds = round(secs, 2),
           error = if (failed) substr(conditionMessage(res), 1L, 300L) else NA_character_,
           finish = if (failed) NA_character_ else as.character(res$finish_reason %||% NA),
           steps = if (failed) NA_integer_ else as.integer(res$steps %||% NA),
           calls_seen_by_aisdk = if (failed) NA_integer_ else length(res$all_tool_calls),
           usage = if (failed) NULL else res$usage,
           text = if (failed) NA_character_ else substr(paste(res$text, collapse = " "), 1L, 300L)),
      s, list(calls = flat_calls(state), submissions = flat_subs(state)))
    cat(sprintf("%-32s %s q%d r%d  %s  calls %2d  rejected %d  refused %d  failed %d  %5.1f s%s\n",
                model_id, v, qi, rep, if (s$correct) "correct" else "WRONG  ", s$tool_calls, s$rejected, s$refused,
                s$failed_calls, secs, if (failed) "  (error)" else ""))
  }
}
meta <- list(stamp = stamp, script = "bench/agent/drive-gl-tools.R", gateway = gateway, models = models,
             aisdk = as.character(utils::packageVersion("aisdk")),
             gloss_commit = system("git rev-parse --short HEAD", intern = TRUE),
             max_steps = max_steps, temperature = 0, system_prompt = system_prompt,
             questions = lapply(questions, function(q) q[c("element", "cx", "cy", "row", "text")]))
writeLines(jsonlite::toJSON(list(meta = meta, runs = runs), auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"),
           paste0(out_base, ".json"))
flat <- do.call(rbind, lapply(runs, function(r) {
  as.data.frame(r[c("model", "variant", "question", "element", "row", "rep", "seconds", "error", "finish", "steps",
                    "calls_seen_by_aisdk", "correct", "tool_calls", "failed_calls", "rejected", "refused")],
                stringsAsFactors = FALSE)
}))
utils::write.csv(flat, paste0(out_base, ".csv"), row.names = FALSE)
cat("archived:", paste0(out_base, c(".json", ".csv")), "\n")
