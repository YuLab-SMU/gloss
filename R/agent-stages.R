# Built-in agent stages. A stage is a capability declaration, not an agent
# loop. The declaration fixes the layers an agent may read or write, the tools
# it can see and the prompt version that identifies its contract.

agent_disclosure_levels <- c("none", "schema", "summary", "rows")

agent_stage_schema <- function() {
  list(
    layer = "string",
    anchor = "any",
    body = "any",
    "depends_on?" = list(type = "array", items = "string")
  )
}

agent_tool_catalog <- c(
  "overview", "tree", "list_elements", "find_elements", "get_element",
  "get_binding", "describe_table", "get_rows", "find_rows", "to_data",
  "get_code", "get_context", "records", "resolve", "check", "test_binding",
  "propose", "repair"
)

agent_stage_specs <- function() {
  all_layers <- c("structure", "binding", "meaning", "relation", "claim",
                  "narrative", "behavior", "overlay")
  list(
    classify = list(reads = "structure", writes = "structure",
                    depends = character(), disclose = "summary",
                    tools = c("overview", "tree", "list_elements", "get_element",
                              "get_code", "propose")),
    bind = list(reads = "structure", writes = "binding",
                depends = "classify", disclose = "summary",
                tools = c("overview", "tree", "list_elements", "get_element",
                          "describe_table", "get_rows", "find_rows", "to_data",
                          "test_binding", "propose")),
    meaning = list(reads = "binding", writes = "meaning",
                   depends = "bind", disclose = "summary",
                   tools = c("overview", "tree", "list_elements", "get_element",
                             "get_binding", "describe_table", "get_rows", "get_context",
                             "records", "resolve", "propose")),
    relation = list(reads = c("structure", "binding"), writes = "relation",
                    depends = c("classify", "bind"), disclose = "summary",
                    tools = c("overview", "tree", "list_elements", "get_element",
                              "get_binding", "records", "resolve", "propose")),
    claim = list(reads = c("binding", "meaning", "relation"), writes = "claim",
                 depends = c("meaning", "relation"), disclose = "summary",
                 tools = c("overview", "tree", "list_elements", "get_element",
                           "get_binding", "describe_table", "get_rows", "get_context",
                           "records", "check", "propose")),
    narrative = list(reads = c("claim", "relation"), writes = "narrative",
                     depends = "claim", disclose = "summary",
                     tools = c("overview", "tree", "list_elements", "get_element",
                               "records", "propose")),
    accessibility = list(reads = all_layers, writes = "narrative",
                         depends = "claim", disclose = "summary",
                         tools = c("overview", "tree", "list_elements", "get_element",
                                   "records", "propose")),
    behavior = list(reads = c("structure", "relation", "claim"),
                    writes = c("behavior", "overlay"),
                    depends = c("relation", "claim"), disclose = "summary",
                    tools = c("overview", "tree", "list_elements", "get_element",
                              "records", "check", "propose")),
    review = list(reads = all_layers, writes = all_layers,
                  depends = c("claim", "behavior"), disclose = "summary",
                  tools = c("overview", "records", "resolve", "propose")),
    repair = list(reads = all_layers, writes = all_layers,
                  depends = "review", disclose = "summary",
                  tools = c("overview", "records", "resolve", "repair", "propose"))
  )
}

stage_prompt_text <- function(name) {
  path <- system.file("prompts", "v0", paste0(name, ".txt"), package = "gloss")
  if (!nzchar(path)) path <- file.path("inst", "prompts", "v0", paste0(name, ".txt"))
  if (!file.exists(path)) cli::cli_abort("No prompt file for agent stage {.val {name}}.")
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

register_builtin_stages <- function() {
  specs <- agent_stage_specs()
  for (name in names(specs)) {
    spec <- specs[[name]]
    gl_register(
      "stage", name = name, version = "0.1.0", package = "gloss",
      description = sprintf("Built-in %s agent stage", name),
      schema = agent_stage_schema(), reads = spec$reads, writes = spec$writes,
      depends = spec$depends, disclose = spec$disclose, tools = spec$tools,
      prompt_version = "v0", prompt = stage_prompt_text(name)
    )
  }
}

stage_plugin_info <- function(name) {
  p <- gl_plugin("stage", name)
  list(name = p$name, version = p$version, reads = as.character(p$reads),
       writes = as.character(p$writes), depends = as.character(p$depends %||% character()),
       tools = as.character(p$tools %||% agent_tool_catalog),
       disclose = as.character(p$disclose %||% "summary")[1L],
       prompt_version = p$prompt_version %||% p$version,
       prompt = p$prompt, schema = p$schema)
}

#' List registered agent stages
#'
#' @return A data frame describing the registered stage capabilities.
#' @export
gl_stages <- function() {
  ps <- plugins_of("stage")
  if (!length(ps)) {
    return(data.frame(name = character(), version = character(), reads = character(),
                      writes = character(), depends = character(), disclose = character(),
                      prompt_version = character(), stringsAsFactors = FALSE))
  }
  out <- do.call(rbind, lapply(ps, function(p) data.frame(
    name = p$name, version = p$version,
    reads = paste(p$reads, collapse = ","), writes = paste(p$writes, collapse = ","),
    depends = paste(p$depends %||% character(), collapse = ","),
    disclose = p$disclose %||% "summary", prompt_version = p$prompt_version %||% p$version,
    stringsAsFactors = FALSE
  )))
  rownames(out) <- NULL
  out
}

stage_dependency_order <- function(stages) {
  stages <- as.character(stages)
  registered <- vapply(plugins_of("stage"), `[[`, "", "name")
  missing <- setdiff(stages, registered)
  if (length(missing)) cli::cli_abort("Unknown agent stage(s) {.val {missing}}.")
  out <- character()
  visit <- function(name, path = character()) {
    if (name %in% out) return(invisible())
    if (name %in% path) cli::cli_abort("Cyclic agent stage dependency at {.val {name}}.")
    p <- stage_plugin_info(name)
    for (dep in p$depends) visit(dep, c(path, name))
    out <<- c(out, name)
    invisible()
  }
  for (name in stages) visit(name)
  unique(out)
}
