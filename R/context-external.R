# Read-only external context plugins and structured context attachment.
# External context extends gloss beyond in-figure code/data/env/git facts to
# data dictionaries, project notes, dataset documentation, ontologies,
# literature, external metadata and user task context.

register_context_data_dictionary <- function() {
  gl_register(
    "context", name = "data_dictionary", version = "0.1.0", package = "gloss",
    description = "external context: variable definitions and units from data dictionary files",
    item = "data_dictionary", sniff = sniff_data_dictionary
  )
}

register_context_project_notes <- function() {
  gl_register(
    "context", name = "project_notes", version = "0.1.0", package = "gloss",
    description = "external context: README or project notes beside the plotting script",
    item = "project_notes", sniff = sniff_project_notes
  )
}

register_context_dataset_documentation <- function() {
  gl_register(
    "context", name = "dataset_documentation", version = "0.1.0", package = "gloss",
    description = "external context: installed package Rd help for referenced datasets",
    item = "dataset_documentation", sniff = sniff_dataset_documentation
  )
}

register_context_ontology <- function() {
  gl_register(
    "context", name = "ontology", version = "0.1.0", package = "gloss",
    description = "external context: ontology terms and controlled vocabulary mappings",
    item = "ontology", sniff = function(input) sniff_external_slot(input, "ontology")
  )
}

register_context_literature <- function() {
  gl_register(
    "context", name = "literature", version = "0.1.0", package = "gloss",
    description = "external context: references, DOIs and literature citations",
    item = "literature", sniff = function(input) sniff_external_slot(input, "literature")
  )
}

register_context_external_metadata <- function() {
  gl_register(
    "context", name = "external_metadata", version = "0.1.0", package = "gloss",
    description = "external context: experimental design and sample annotation metadata",
    item = "external_metadata", sniff = function(input) sniff_external_slot(input, "external_metadata")
  )
}

register_context_user_context <- function() {
  gl_register(
    "context", name = "user_context", version = "0.1.0", package = "gloss",
    description = "external context: analyst question, target audience and decision context",
    item = "user_context", sniff = function(input) sniff_external_slot(input, "user_context")
  )
}

register_builtin_external_contexts <- function() {
  register_context_data_dictionary()
  register_context_project_notes()
  register_context_dataset_documentation()
  register_context_ontology()
  register_context_literature()
  register_context_external_metadata()
  register_context_user_context()
}

sniff_external_slot <- function(input, item) {
  supplied <- input$context_extra[[item]] %||% NULL
  if (!is.null(supplied)) {
    return(list(found = TRUE, value = supplied))
  }
  list(found = FALSE, reason = sprintf("no %s context attached (use gl_add_context() to add one)", item))
}

script_search_dirs <- function(input) {
  script <- input$context$code$value$script$path %||% NULL
  if (is.null(script) || !nzchar(script)) return(character())
  d1 <- dirname(script)
  d2 <- dirname(d1)
  unique(c(d1, d2))
}

sniff_data_dictionary <- function(input) {
  supplied <- input$context_extra$data_dictionary %||% NULL
  if (!is.null(supplied)) return(list(found = TRUE, value = supplied))

  dirs <- script_search_dirs(input)
  candidates <- c("data_dictionary.json", "data-dictionary.json",
                  "data_dictionary.csv", "data-dictionary.csv")
  for (d in dirs) {
    for (nm in candidates) {
      p <- file.path(d, nm)
      if (!file.exists(p)) next
      val <- tryCatch({
        if (grepl("\\.json$", p, ignore.case = TRUE)) {
          jsonlite::fromJSON(p, simplifyVector = FALSE)
        } else {
          utils::read.csv(p, stringsAsFactors = FALSE, check.names = FALSE)
        }
      }, error = function(e) NULL)
      if (!is.null(val)) {
        return(list(found = TRUE, value = list(
          source = normalizePath(p),
          source_type = "data_dictionary_file",
          md5 = unname(tools::md5sum(p)),
          entries = val
        )))
      }
    }
  }
  list(found = FALSE, reason = "no data_dictionary file found beside the script and none attached")
}

sniff_project_notes <- function(input) {
  supplied <- input$context_extra$project_notes %||% NULL
  if (!is.null(supplied)) return(list(found = TRUE, value = supplied))

  dirs <- script_search_dirs(input)
  candidates <- c("project-notes.md", "project_notes.md", "notes.md", "README.md")
  for (d in dirs) {
    for (nm in candidates) {
      p <- file.path(d, nm)
      if (!file.exists(p)) next
      txt <- tryCatch(paste(readLines(p, n = 120L, warn = FALSE, encoding = "UTF-8"), collapse = "\n"),
                      error = function(e) NULL)
      if (!is.null(txt) && nzchar(txt)) {
        excerpt <- if (nchar(txt) > 4000L) paste0(substr(txt, 1L, 4000L), "\n...") else txt
        return(list(found = TRUE, value = list(
          source = normalizePath(p),
          source_type = "project_notes_file",
          md5 = unname(tools::md5sum(p)),
          excerpt = excerpt
        )))
      }
    }
  }
  list(found = FALSE, reason = "no project notes or README found beside the script")
}

rd_text_extract <- function(rd, tag) {
  parts <- Filter(function(x) identical(attr(x, "Rd_tag"), tag), rd)
  if (!length(parts)) return(NULL)
  flatten <- function(node) {
    if (is.character(node)) return(paste(node, collapse = ""))
    if (is.list(node)) return(paste(vapply(node, flatten, ""), collapse = ""))
    ""
  }
  txt <- trimws(gsub("[[:space:]]+", " ", paste(vapply(parts, flatten, ""), collapse = " ")))
  if (nzchar(txt)) txt else NULL
}

dataset_rd_summary <- function(name) {
  h <- tryCatch(utils::help(topic = (name), help_type = "text"), error = function(e) NULL)
  if (is.null(h) || !length(h)) return(NULL)
  rd <- tryCatch(
    get(".getHelpFile", envir = asNamespace("utils"))(as.character(h)[1L]),
    error = function(e) NULL
  )
  if (is.null(rd)) return(NULL)
  title <- rd_text_extract(rd, "\\title")
  desc <- rd_text_extract(rd, "\\description")
  if (is.null(title) && is.null(desc)) return(NULL)
  pkg <- basename(dirname(dirname(as.character(h)[1L])))
  list(
    dataset = name,
    package = pkg,
    title = title %||% name,
    description = if (!is.null(desc) && nchar(desc) > 1200L) paste0(substr(desc, 1L, 1200L), "...") else desc
  )
}

sniff_dataset_documentation <- function(input) {
  supplied <- input$context_extra$dataset_documentation %||% NULL
  if (!is.null(supplied)) return(list(found = TRUE, value = supplied))

  objs <- as.character(unlist(input$context$data$value$objects %||% character()))
  objs <- unique(objs[nzchar(objs)])
  if (!length(objs)) {
    return(list(found = FALSE, reason = "no named dataset object detected in plotting code"))
  }
  docs <- list()
  for (nm in utils::head(objs, 5L)) {
    d <- dataset_rd_summary(nm)
    if (!is.null(d)) docs[[length(docs) + 1L]] <- d
  }
  if (!length(docs)) {
    return(list(found = FALSE, reason = sprintf("no installed package help found for dataset(s): %s", paste(objs, collapse = ", "))))
  }
  list(found = TRUE, value = list(
    source_type = "r_package_help",
    datasets = docs
  ))
}

#' Attach structured external context to a gloss figure
#'
#' Adds or replaces a named context item in `fig$context` (such as
#' `"data_dictionary"`, `"project_notes"`, `"dataset_documentation"`,
#' `"ontology"`, `"literature"`, `"external_metadata"`, or `"user_context"`).
#' Values are validated for safe JSON-like payloads and travel through
#' `gl_write()`, `gl_workbench()` and `gl_read()` inside `context.json`.
#'
#' @param fig A `gloss_figure`.
#' @param item Context item name (single non-empty string).
#' @param value A JSON-like list, data frame, or atomic value describing the context.
#' @param source Optional provenance source label (file path, DOI, URI, document).
#' @param source_type Optional source category (for example `"dataset_metadata"`,
#'   `"data_dictionary"`, `"ontology"`, `"literature"`, `"user_prompt"`).
#' @param by Author or tool identity attaching the context.
#' @return The updated `gloss_figure`.
#' @export
gl_add_context <- function(fig, item, value, source = NULL, source_type = NULL, by = "user") {
  check_figure(fig)
  if (!is_string(item) || !nzchar(trimws(item))) {
    cli::cli_abort("{.arg item} must be a non-empty string.")
  }
  problems <- payload_issues(value)
  if (length(problems)) {
    cli::cli_abort(c("Context value for {.val {item}} failed safety validation.", bullets_x(problems)))
  }
  wrapped <- if (is.list(value) && !is.data.frame(value)) {
    out <- value
    if (!is.null(source) && is.null(out$source)) out$source <- as.character(source)[1L]
    if (!is.null(source_type) && is.null(out$source_type)) out$source_type <- as.character(source_type)[1L]
    out
  } else {
    compact(list(content = value, source = source, source_type = source_type))
  }
  plug <- gl_plugin("context", item, must_exist = FALSE)
  fig$context[[item]] <- list(
    item = item,
    plugin = if (!is.null(plug)) plug$name else "attached",
    version = if (!is.null(plug)) plug$version else "0.1.0",
    found = TRUE,
    value = wrapped,
    reason = NULL,
    provenance = list(by = as.character(by)[1L], time = now_utc())
  )
  fig
}
