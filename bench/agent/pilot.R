# The pilot of the decisive comparison (agent-path plan 2026-11-12, Tasks 4
# and 5): one question, "which row of which table does this element draw?",
# asked of the same model in two arms, and of code alone in a third.
#
#   A  the raw material and an R sandbox (bench/agent/sandbox.R); `submit`
#      records the answer and checks nothing
#   B  gloss::gl_tools() over the figure read back from its bundle, every
#      binding hidden; `propose` checks on submit
#   S  no model: every row of every built table tried through the check
#
# Host only. From the repository root:
#   Rscript bench/agent/pilot.R questions            # draw the questions from the material (seeded; no model)
#   Rscript bench/agent/pilot.R dry                  # no model: both tool sets reach the answer on every question
#   Rscript bench/agent/pilot.R enumerate            # arm S, archived
#   Rscript bench/agent/pilot.R rehearse [model]     # both arms on a hand-built figure that is not in the pilot
#   Rscript bench/agent/pilot.R run <stamp> <model>  # arms A and B for one model, appended run by run
#
# The material is made in the container by bench/agent/material.R; the rule
# for figures and questions is in the plan and was fixed before any run.
# The gateway's key is read from ANTHROPIC_AUTH_TOKEN and is never printed
# or archived. Nothing a model writes runs outside the sandbox.

suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE))
source("bench/agent/sandbox.R")
source("bench/agent/material-writer.R")
options(aisdk.skip_internet_check = TRUE)   # the gateway is on this machine

seed <- 20261113L
gateway <- "http://127.0.0.1:3425/v1"
models <- c("westlakehpc/glm-5.3-flash", "westlakehpc/deepseek-v4.1-flash", "westlakehpc/Qwen3.8-27B")
arms <- c("A", "B")
n_repeats <- 3L
n_questions <- 3L
# one budget for both arms
max_steps <- 16L          # model turns, each with at most one round of tool calls
request_timeout <- 180    # seconds for one model request
sandbox_timeout <- 120    # seconds for one run_r call: the slowest figure's own code takes 46 s there
output_limit <- 4000      # characters a tool hands back (gl_tools' answers are far shorter)
place_tol <- 0.01         # pt: an element's place in svglite's page against gloss's scene

material_root <- file.path(sandbox_cache(), "agent", "pilot")
figures_file <- file.path("bench", "agent", "pilot-figures.csv")
questions_file <- file.path("bench", "agent", "pilot-questions.csv")

# ---- material and questions ----------------------------------------------------

figure_env <- function(id) {
  meta <- jsonlite::read_json(file.path("bench", "figures", id, "meta.json"))
  meta$environment$name %||% (if (meta$stratum %in% c("bioc", "heatmap", "tree")) "bioc" else "cran")
}

load_material <- function(dir, env = "cran") {
  list(dir = dir, env = env, fig = gloss::gl_read(file.path(dir, "figure.html")),
       answers = readRDS(file.path(dir, "answers.rds")))
}
pilot_material <- function(id) load_material(file.path(material_root, id), figure_env(id))

# Centres of the circles and rectangles svglite wrote.
svg_places <- function(path) {
  doc <- xml2::read_xml(path)
  ns <- c(s = "http://www.w3.org/2000/svg")
  num <- function(nodes, a) suppressWarnings(as.numeric(xml2::xml_attr(nodes, a)))
  ci <- xml2::xml_find_all(doc, "//s:circle", ns)
  re <- xml2::xml_find_all(doc, "//s:rect", ns)
  out <- rbind(data.frame(tag = rep("circle", length(ci)), x = num(ci, "cx"), y = num(ci, "cy")),
               data.frame(tag = rep("rect", length(re)), x = num(re, "x") + num(re, "width") / 2,
                          y = num(re, "y") + num(re, "height") / 2))
  out[!is.na(out$x) & !is.na(out$y), , drop = FALSE]
}

# Elements a question can ask about: a circle or a rectangle bound at capture
# to one row of a layer's built data, verified; alone at its place among the
# elements of its tag; at the same place in svglite's own page.
askable <- function(m) {
  b <- m$answers$elements
  g <- m$answers$geometry
  i <- match(b$element, g$id)
  b$tag <- g$tag[i]
  b$cx <- (g$x0[i] + g$x1[i]) / 2
  b$cy <- (g$y0[i] + g$y1[i]) / 2
  b <- b[b$status %in% "verified" & b$n_rows %in% 1L & grepl("built_layer", b$table) & b$tag %in% c("circle", "rect"), ,
         drop = FALSE]
  sp <- svg_places(file.path(m$dir, "A", "figure.svg"))
  gx <- (g$x0 + g$x1) / 2
  gy <- (g$y0 + g$y1) / 2
  b$svg_gap <- b$twins <- rep(NA_real_, nrow(b))
  for (k in seq_len(nrow(b))) {
    s <- sp[sp$tag == b$tag[k], , drop = FALSE]
    b$svg_gap[k] <- if (nrow(s)) min(pmax(abs(s$x - b$cx[k]), abs(s$y - b$cy[k]))) else Inf
    same <- which(g$tag == b$tag[k] & g$id != b$element[k])
    b$twins[k] <- sum(pmax(abs(gx[same] - b$cx[k]), abs(gy[same] - b$cy[k])) <= place_tol, na.rm = TRUE)
  }
  b
}

pick <- function(x, n) x[sample.int(length(x), min(n, length(x)))]

# Up to n_questions elements of one figure: one from each of up to n leaves,
# then more from what is left.
draw_elements <- function(el) {
  leaves <- pick(sort(unique(el$leaf)), n_questions)
  got <- vapply(leaves, function(l) pick(el$element[el$leaf == l], 1L), "")
  rest <- setdiff(el$element, got)
  c(unname(got), pick(rest, n_questions - length(got)))
}

question_text <- function(q) {
  sprintf(paste(
    "The figure has a %s whose box is centred at (%.2f, %.2f) pt, counted from the top left of the page.",
    "Which row of which table does it draw?",
    "Give the table's name (for example `built_layer1`) and the row's number in that table, counted from 1."),
    if (q$tag == "circle") "circle" else "rectangle", q$cx, q$cy)
}

# ---- the two arms' tools ---------------------------------------------------------

system_A <- paste(
  "You answer a question about a figure drawn in R. You cannot see the figure, but you have everything it was made from,",
  "in the working directory of an R sandbox:\n",
  "- code.R: the code that drew the figure (the data it reads, if any, is under data/);\n",
  "- tables/<name>.csv: the plot's data (`raw`) and the built data of each layer (`built_layer<i>`, as ggplot_build() gives it;",
  "in a composition of plots, `plot<j>_built_layer<i>`), with the row's number in a first column `row`;",
  "columns that hold lists are left out there, and tables.rds holds every table whole, as a named list;\n",
  "- grob_tree.txt: the figure's grob tree as text;\n",
  "- figure.svg: the figure as the svglite device wrote it, 504 x 360 pt, with coordinates in pt from the top left of the page.\n",
  "Call `run_r` to run R code there; the packages the code uses are installed.",
  "When you know the answer, call `submit` with the table's name and the row's number in that table. Your last submission counts."
)
system_B <- paste(
  "You answer a question about a figure drawn in R by calling tools. You cannot see the figure.",
  "Coordinates are in pt from the top left of the page; data values are on the scales of a panel.",
  "When you know the answer, call `propose` with the element, the table's name and the row's number in that table.",
  "If `propose` rejects it, read the reason and try again. An answer counts only when `propose` accepts it."
)

tools_B <- function(fig) gloss::gl_tools(fig, hide = gloss::gl_bindings(fig, by = "leaf")$leaf)

# `run_r` and `submit` over one sandbox. What happened is kept as gl_tools()
# keeps it: every call, and every submission.
tools_A <- function(sb) {
  st <- new.env(parent = emptyenv())
  st$calls <- list()
  st$submissions <- list()
  note <- function(tool, args, ok, result, ...) {
    st$calls[[length(st$calls) + 1L]] <- c(list(tool = tool, args = args, ok = ok, result = result), list(...))
    result
  }
  run_r <- aisdk::tool(
    name = "run_r",
    description = sprintf(paste(
      "Run R code in the sandbox and get back what it printed (output and messages together, at most %d characters).",
      "The working directory holds the figure's material. Each call is a new R session: objects do not last from one call",
      "to the next, files you write do. There is no network. A call is stopped after %d s."), output_limit, sandbox_timeout),
    parameters = aisdk::z_object(code = aisdk::z_string("R code, run as one script")),
    execute = function(...) {
      a <- list(...)
      if (!is.character(a$code) || length(a$code) != 1L || !nzchar(a$code)) {
        return(note("run_r", a, FALSE, '{"error":"`code` must be one string of R code"}'))
      }
      r <- sandbox_run(sb, a$code, timeout = sandbox_timeout, limit = output_limit)
      out <- if (nzchar(r$output)) r$output else "[the code printed nothing]"
      if (r$status != 0L && !r$timed_out && !r$killed) out <- paste0(out, sprintf("\n[R ended with status %d]", r$status))
      note("run_r", a, r$status == 0L, out, seconds = r$seconds, timed_out = r$timed_out, killed = r$killed)
    })
  submit <- aisdk::tool(
    name = "submit",
    description = paste("Submit your answer: the table's name and the row's number in that table, counted from 1.",
                        "It is recorded as given and not checked. Your last submission counts."),
    parameters = aisdk::z_object(table = aisdk::z_string("table name"), row = aisdk::z_integer("row number")),
    execute = function(...) {
      a <- list(...)
      whole <- is.numeric(a$row) && length(a$row) == 1L && !is.na(a$row) && a$row == round(a$row)
      if (!is.character(a$table) || length(a$table) != 1L || !whole) {
        return(note("submit", a, FALSE, '{"error":"`table` must be a string and `row` a whole number"}'))
      }
      st$submissions[[length(st$submissions) + 1L]] <- list(table = a$table, row = as.integer(a$row))
      note("submit", a, TRUE, '{"recorded":true}')
    })
  structure(list(run_r, submit), pilot_state = st)
}
state_A <- function(tools) {
  st <- attr(tools, "pilot_state")
  list(calls = st$calls, submissions = st$submissions)
}
call_tool <- function(tools, name, args) {
  t <- Filter(function(t) identical(t$name, name), tools)[[1]]
  t$run(args)
}

# ---- scoring one run ----------------------------------------------------------------

same_answer <- function(table, row, q) identical(as.character(table), q$table) && identical(as.integer(row), as.integer(q$row))

score_A <- function(state, q) {
  subs <- state$submissions
  last <- if (length(subs)) subs[[length(subs)]]
  list(answered = !is.null(last), answer_table = last$table %||% NA_character_, answer_row = last$row %||% NA_integer_,
       correct = !is.null(last) && same_answer(last$table, last$row, q),
       submissions = length(subs), wrong_accepted = NA_integer_, rejected = NA_integer_, refused = NA_integer_,
       first_outcome = NA_character_, other_element = NA_integer_,
       tool_calls = length(state$calls), failed_calls = sum(!vapply(state$calls, function(c) isTRUE(c$ok), logical(1))))
}

score_B <- function(state, q) {
  props <- state$proposals
  outcome <- vapply(props, function(p) p$outcome, "")
  mine <- vapply(props, function(p) identical(p$proposal$element, q$element), logical(1))
  right <- vapply(props, function(p) same_answer(p$proposal$table, p$proposal$row, q), logical(1))
  acc <- which(outcome == "accepted" & mine)
  last <- if (length(acc)) props[[acc[length(acc)]]]$proposal
  list(answered = length(acc) > 0L, answer_table = last$table %||% NA_character_,
       answer_row = if (is.null(last)) NA_integer_ else as.integer(last$row),
       # right only when the answer was accepted and nothing else was accepted for this element
       correct = length(acc) > 0L && all(right[acc]),
       submissions = length(props), wrong_accepted = sum(outcome == "accepted" & mine & !right),
       rejected = sum(outcome == "rejected"), refused = sum(outcome == "refused"),
       first_outcome = if (length(props)) outcome[1] else NA_character_,
       other_element = sum(outcome == "accepted" & !mine),
       tool_calls = length(state$calls), failed_calls = sum(!vapply(state$calls, function(c) isTRUE(c$ok), logical(1))))
}

clip <- function(x, n) if (is.character(x) && length(x) == 1L && nchar(x) > n) paste0(substr(x, 1L, n), " [...]") else x

# One run of one model on one question in one arm.
run_one <- function(model, arm, m, q) {
  if (arm == "A") {
    sb <- sandbox_open(file.path(m$dir, "A"), m$env)
    on.exit(sandbox_close(sb), add = TRUE)
    tools <- tools_A(sb)
  } else tools <- tools_B(m$fig)
  t0 <- Sys.time()
  res <- tryCatch(
    aisdk::generate_text(model = model, system = if (arm == "A") system_A else system_B, prompt = question_text(q),
                         tools = tools, max_steps = max_steps, temperature = 0),
    error = function(e) e)
  secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  failed <- inherits(res, "error")
  state <- if (arm == "A") state_A(tools) else gloss::gl_tool_state(tools)
  s <- if (arm == "A") score_A(state, q) else score_B(state, q)
  c(list(arm = arm, figure = q$figure, question = q$question, element = q$element, tag = q$tag,
         truth_table = q$table, truth_row = q$row, seconds = round(secs, 2),
         error = if (failed) substr(conditionMessage(res), 1L, 300L) else NA_character_,
         finish = if (failed) NA_character_ else as.character(res$finish_reason %||% NA),
         steps = if (failed) NA_integer_ else as.integer(res$steps %||% NA),
         usage = if (failed) NULL else res$usage,
         text = if (failed) NA_character_ else substr(paste(res$text, collapse = " "), 1L, 600L)),
    s,
    list(calls = lapply(state$calls, function(c) { c$result <- clip(c$result, output_limit); c }),
         submissions = if (arm == "A") state$submissions else lapply(state$proposals, function(p) {
           list(element = p$proposal$element, table = p$proposal$table, row = p$proposal$row, outcome = p$outcome,
                stage = p$stage, reasons = p$reasons)
         })))
}

read_questions <- function() {
  q <- utils::read.csv(questions_file, stringsAsFactors = FALSE)
  lapply(seq_len(nrow(q)), function(i) as.list(q[i, ]))
}

json_line <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", digits = NA))
git_head <- function() system("git rev-parse --short HEAD", intern = TRUE)
utc_stamp <- function() format(Sys.time(), "%Y-%m-%d-%H%M", tz = "UTC")
short <- function(model_id) gsub("[^A-Za-z0-9.-]", "-", sub("^westlakehpc/", "", model_id))

provider <- function() {
  key <- Sys.getenv("ANTHROPIC_AUTH_TOKEN")
  if (!nzchar(key)) stop("the gateway's key is not in the environment")
  aisdk::create_openai(api_key = key, base_url = gateway, api_format = "chat", name = "magpie",
                       total_timeout_seconds = request_timeout)
}

# ---- modes ------------------------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[1] else ""

if (mode == "questions") {
  # The sampled figures; one whose material could not be made is replaced by
  # the next of its stratum in the seeded order (plan, Task 5), and named.
  figs <- utils::read.csv(figures_file, stringsAsFactors = FALSE)
  has_material <- file.exists(file.path(material_root, figs$id, "figure.html"))
  ids <- character()
  for (s in unique(figs$stratum)) {
    k <- which(figs$stratum == s)
    k <- k[order(figs$order[k])]
    want <- sum(figs$sampled[k] %in% TRUE)
    got <- utils::head(k[has_material[k]], want)
    out <- k[figs$sampled[k] %in% TRUE & !has_material[k]]
    if (length(out)) cat(sprintf("%s: no material for %s; standing in: %s\n", s, paste(figs$id[out], collapse = ", "),
                                 paste(setdiff(figs$id[got], figs$id[k[figs$sampled[k] %in% TRUE]]), collapse = ", ")))
    if (length(got) < want) cat(sprintf("%s: %d of %d figures have material\n", s, length(got), want))
    ids <- c(ids, figs$id[got])
  }
  ids <- sort(ids)
  set.seed(seed)
  rows <- list()
  for (id in ids) {
    m <- pilot_material(id)
    el <- askable(m)
    ok <- el[el$svg_gap <= place_tol & el$twins == 0, , drop = FALSE]
    cat(sprintf("%-14s %5d elements bound one for one row | %d at another place in svglite's page | %d not alone at their place | %d askable in %d leaves\n",
                id, nrow(el), sum(el$svg_gap > place_tol), sum(el$twins > 0), nrow(ok), length(unique(ok$leaf))))
    if (!nrow(ok)) next
    got <- draw_elements(ok)
    k <- match(got, ok$element)
    rows[[id]] <- data.frame(figure = id, question = seq_along(got), element = got, tag = ok$tag[k], leaf = ok$leaf[k],
                             cx = round(ok$cx[k], 2), cy = round(ok$cy[k], 2), table = ok$table[k], row = ok$row[k],
                             stringsAsFactors = FALSE)
  }
  q <- do.call(rbind, rows)
  utils::write.csv(q, questions_file, row.names = FALSE)
  cat(sprintf("%d questions on %d figures (seed %d) -> %s\n", nrow(q), length(unique(q$figure)), seed, questions_file))
}

if (mode == "dry") {
  qs <- read_questions()
  bad <- 0L
  for (id in unique(vapply(qs, function(q) q$figure, ""))) {
    m <- pilot_material(id)
    sb <- sandbox_open(file.path(m$dir, "A"), m$env)
    ta <- tools_A(sb)
    src <- call_tool(ta, "run_r", list(code = 'invisible(source("code.R")); cat("\\ncode.R ran\\n")'))
    code_ok <- grepl("code.R ran", src, fixed = TRUE)
    code_secs <- state_A(ta)$calls[[1]]$seconds
    for (q in Filter(function(q) q$figure == id, qs)) {
      # A: the answer's row is in the material, and a submission of it scores as right
      seen <- call_tool(ta, "run_r", list(code = sprintf(
        'd <- read.csv("tables/%s.csv"); t <- readRDS("tables.rds")[["%s"]]; cat(nrow(d) == nrow(t), %d %%in%% d$row)', q$table, q$table, q$row)))
      call_tool(ta, "submit", list(table = q$table, row = q$row))
      a_ok <- identical(seen, "TRUE TRUE") && score_A(state_A(ta), q)$correct
      # B: the element is found at its place, and its answer is accepted
      tb <- tools_B(m$fig)
      hit <- jsonlite::fromJSON(call_tool(tb, "find_elements", list(x = q$cx, y = q$cy)))
      found <- is.data.frame(hit) && q$element %in% hit$id[hit$tag == q$tag]
      hidden <- isTRUE(jsonlite::fromJSON(call_tool(tb, "get_binding", list(element = q$element)))$hidden)
      out <- jsonlite::fromJSON(call_tool(tb, "propose", list(element = q$element, table = q$table, row = q$row)))
      b_ok <- found && hidden && identical(out$outcome, "accepted") && score_B(gloss::gl_tool_state(tb), q)$correct
      cat(sprintf("%-14s q%d %-5s %s row %-5d | A: material %s | B: found %s, hidden %s, answer %s\n", id, q$question, q$element,
                  q$table, q$row, if (a_ok) "ok" else "FAILED", found, hidden, out$outcome))
      if (!a_ok || !b_ok) bad <- bad + 1L
    }
    cat(sprintf("%-14s code.R in the sandbox: %s, %.1f s\n", id, if (code_ok) "ran" else "DID NOT RUN", code_secs))
    if (!code_ok) { bad <- bad + 1L; cat("    ", substr(src, 1L, 400L), "\n") }
    sandbox_close(sb)
  }
  if (bad) { cat(bad, "checks failed\n"); quit(status = 1) }
  cat(sprintf("dry run: %d questions; both tool sets reach each answer, and every figure's code runs in the sandbox\n", length(qs)))
}

if (mode == "enumerate") {
  qs <- read_questions()
  stamp <- utc_stamp()
  rows <- list()
  for (id in unique(vapply(qs, function(q) q$figure, ""))) {
    m <- pilot_material(id)
    ctx <- gloss:::propose_context(m$fig)
    tabs <- gloss::gl_tables(m$fig)
    tabs <- tabs[tabs$role %in% "built" & !is.na(tabs$nrow), , drop = FALSE]
    for (q in Filter(function(q) q$figure == id, qs)) {
      t0 <- Sys.time()
      acc <- list()
      n_out <- c(accepted = 0L, rejected = 0L, refused = 0L)
      for (i in seq_len(nrow(tabs))) for (r in seq_len(tabs$nrow[i])) {
        res <- gloss:::check_proposal(ctx, list(kind = "binding", element = q$element, table = tabs$name[i], row = r))
        n_out[res$outcome] <- n_out[res$outcome] + 1L
        if (identical(res$outcome, "accepted")) acc[[length(acc) + 1L]] <- list(table = tabs$name[i], row = r, status = res$record$status)
      }
      right <- vapply(acc, function(a) same_answer(a$table, a$row, q), logical(1))
      rows[[length(rows) + 1L]] <- data.frame(
        figure = id, question = q$question, element = q$element, tag = q$tag, truth_table = q$table, truth_row = q$row,
        tables = nrow(tabs), tried = sum(n_out), accepted = n_out[["accepted"]], rejected = n_out[["rejected"]],
        refused = n_out[["refused"]], truth_accepted = any(right), wrong_accepted = sum(!right),
        correct = length(acc) == 1L && all(right),
        accepted_list = paste(utils::head(vapply(acc, function(a) sprintf("%s:%d:%s", a$table, a$row, a$status), ""), 8L), collapse = " "),
        seconds = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 2), stringsAsFactors = FALSE)
      r <- rows[[length(rows)]]
      cat(sprintf("%-14s q%d %-5s tried %5d in %d tables | accepted %d (the answer: %s; others: %d) | refused %d | %.1f s\n", id,
                  q$question, q$element, r$tried, r$tables, r$accepted, r$truth_accepted, r$wrong_accepted, r$refused, r$seconds))
    }
  }
  out <- do.call(rbind, rows)
  f <- file.path("bench", "runs", paste0(stamp, "-pilot-enumerate.csv"))
  utils::write.csv(out, f, row.names = FALSE)
  writeLines(json_line(list(stamp = stamp, script = "bench/agent/pilot.R enumerate", gloss_commit = git_head(), seed = seed,
                            questions = length(qs))), sub("\\.csv$", ".json", f))
  cat("archived:", f, "\n")
}

if (mode == "rehearse") {
  # A figure built here and not in the pilot: does a run of each arm go
  # through, and what does it cost? Not a pilot result.
  suppressMessages(library(ggplot2))
  code <- c("library(ggplot2)", "p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point() + facet_wrap(~am)", "p")
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point() + facet_wrap(~am)
  dir <- tempfile("rehearsal-")
  s <- svglite::svgstring(width = 7, height = 5, standalone = TRUE)
  print(p)
  grDevices::dev.off()
  write_material(p, as.character(s())[1], dir)
  writeLines(code, file.path(dir, "A", "code.R"))
  m <- load_material(dir)
  el <- askable(m)
  el <- el[el$svg_gap <= place_tol & el$twins == 0, , drop = FALSE]
  set.seed(seed)
  got <- pick(el$element, 2L)
  k <- match(got, el$element)
  qs <- lapply(seq_along(got), function(i) list(figure = "hand-built", question = i, element = got[i], tag = el$tag[k[i]],
                                                cx = round(el$cx[k[i]], 2), cy = round(el$cy[k[i]], 2), table = el$table[k[i]],
                                                row = el$row[k[i]]))
  ids <- if (length(args) > 1) args[-1] else models
  prov <- provider()
  stamp <- utc_stamp()
  f <- file.path("bench", "runs", paste0(stamp, "-pilot-rehearsal.jsonl"))
  cat(json_line(list(meta = TRUE, stamp = stamp, script = "bench/agent/pilot.R rehearse", models = ids, gloss_commit = git_head(),
                     aisdk = as.character(utils::packageVersion("aisdk")), max_steps = max_steps, temperature = 0,
                     system_A = system_A, system_B = system_B, questions = lapply(qs, function(q) c(q, list(text = question_text(q)))))),
      "\n", file = f, sep = "")
  for (id in ids) for (q in qs) for (arm in arms) {
    r <- c(list(model = id, rep = 1L), run_one(prov$language_model(id), arm, m, q))
    cat(json_line(r), "\n", file = f, append = TRUE, sep = "")
    cat(sprintf("%-22s %s q%d  %s  calls %2d  failed %d  %6.1f s  tokens %s%s\n", short(id), arm, q$question,
                if (r$correct) "correct" else if (r$answered) "WRONG  " else "no answer", r$tool_calls, r$failed_calls, r$seconds,
                format(r$usage$total_tokens %||% NA), if (is.na(r$error)) "" else paste0("  (error: ", substr(r$error, 1L, 80L), ")")))
  }
  unlink(dir, recursive = TRUE)
  cat("archived:", f, "\n")
}

if (mode == "run") {
  if (length(args) != 3L) stop("usage: Rscript bench/agent/pilot.R run <stamp> <model>")
  stamp <- args[2]
  model_id <- args[3]
  stopifnot(model_id %in% models)
  qs <- read_questions()
  f <- file.path("bench", "runs", sprintf("%s-pilot-%s.jsonl", stamp, short(model_id)))
  # Runs already made under this stamp are not made again, except a run that
  # ended in a request error (the gateway or the models behind it failed, so
  # the model gave no answer): it stays in the archive and is made once more.
  done <- list()
  if (file.exists(f)) for (ln in readLines(f, warn = FALSE)) {
    r <- jsonlite::fromJSON(ln, simplifyVector = FALSE)
    if (isTRUE(r$meta)) next
    key <- paste(r$arm, r$figure, r$question, r$rep)
    done[[key]] <- c(done[[key]], is.null(r$error))
  } else {
    cat(json_line(list(meta = TRUE, stamp = stamp, script = "bench/agent/pilot.R run", model = model_id, gateway = gateway,
                       gloss_commit = git_head(), aisdk = as.character(utils::packageVersion("aisdk")), max_steps = max_steps,
                       request_timeout = request_timeout, sandbox_timeout = sandbox_timeout, output_limit = output_limit,
                       repeats = n_repeats, temperature = 0, seed = seed, system_A = system_A, system_B = system_B,
                       questions = lapply(qs, function(q) c(q, list(text = question_text(q)))))),
        "\n", file = f, sep = "")
  }
  model <- provider()$language_model(model_id)
  errors_in_a_row <- 0L
  mats <- list()
  for (q in qs) for (rep in seq_len(n_repeats)) for (arm in arms) {
    key <- paste(arm, q$figure, q$question, rep)
    tries <- done[[key]]
    if (any(tries) || length(tries) >= 2L) next
    if (is.null(mats[[q$figure]])) mats[[q$figure]] <- pilot_material(q$figure)
    r <- c(list(model = model_id, rep = rep, attempt = length(tries) + 1L), run_one(model, arm, mats[[q$figure]], q))
    cat(json_line(r), "\n", file = f, append = TRUE, sep = "")
    cat(sprintf("%-20s %s %-14s q%d r%d  %s  calls %2d  %6.1f s%s\n", short(model_id), arm, q$figure, q$question, rep,
                if (r$correct) "correct" else if (r$answered) "WRONG  " else "no answer", r$tool_calls, r$seconds,
                if (is.na(r$error)) "" else "  (request error)"))
    errors_in_a_row <- if (is.na(r$error)) 0L else errors_in_a_row + 1L
    if (errors_in_a_row >= 3L) stop("three requests in a row failed: the models are not answering; run again later under the same stamp")
  }
  cat("done:", f, "\n")
}
