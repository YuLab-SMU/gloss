# Development-set material and oracle writer for the agent-first binding path.
#
# The writer is called from the pinned bench worker through `export_fun`.  It
# writes a public directory and a sibling oracle directory.  Only the public
# directory is copied into an agent sandbox.

source("bench/agent/binding-dsl.R")

binding_material_version <- "0.1.0"

binding_safe_columns <- function(x, drop = character()) {
  if (!is.data.frame(x)) return(data.frame())
  keep <- setdiff(names(x), drop)
  x[, keep, drop = FALSE]
}

binding_fact_tables <- function(fig) {
  tabs <- fig$tables %||% list()
  out <- list()
  for (nm in names(tabs)) {
    d <- tabs[[nm]]$data
    if (!is.data.frame(d)) next
    keep <- vapply(d, function(x) is.atomic(x) && is.null(dim(x)), logical(1))
    out[[nm]] <- d[, keep, drop = FALSE]
  }
  out
}

binding_fact_leaves <- function(fig) {
  leaves <- fig$substrate$leaves %||% data.frame()
  drop <- intersect(c("status", "reason", "bindable", "table", "mode", "verified", "ambiguous",
                      "failed", "max_dev", "n_rows", "n_groups"), names(leaves))
  binding_safe_columns(leaves, drop)
}

binding_fact_elements <- function(fig) {
  elements <- fig$substrate$elements %||% data.frame()
  drop <- intersect(c("bindable", "binding", "status", "reason", "table", "row"), names(elements))
  binding_safe_columns(elements, drop)
}

binding_layer_params <- function(fig, tables = binding_fact_tables(fig)) {
  # Parameters that can be named by the proposal DSL are values already
  # present in captured tables or in the engine's public description.  The
  # writer never invents a shift value.
  out <- list()
  for (nm in names(tables)) {
    d <- tables[[nm]]
    cols <- intersect(c("nudge_x", "nudge_y", "hjust", "vjust", "angle", "width", "height"), names(d))
    if (length(cols)) out[[nm]] <- as.list(stats::setNames(lapply(cols, function(col) unique(d[[col]])), cols))
  }
  out
}

binding_public_facts <- function(fig, figure_id = NA_character_, source_scene_sha256 = NA_character_) {
  tabs <- binding_fact_tables(fig)
  list(
    format = "gloss-agent-binding-material",
    version = binding_material_version,
    figure = as.character(figure_id),
    engine = as.character(fig$meta$engine %||% fig$context$engine$value$engine %||% NA_character_),
    width_pt = as.numeric(fig$meta$width %||% NA_real_) * 72,
    height_pt = as.numeric(fig$meta$height %||% NA_real_) * 72,
    elements = binding_fact_elements(fig),
    leaves = binding_fact_leaves(fig),
    panels = fig$substrate$panels %||% data.frame(),
    tables = tabs,
    layer_params = binding_layer_params(fig, tabs),
    scene_sha256 = source_scene_sha256
  )
}

binding_geometry <- function(fig) {
  gloss:::scene_geometry(fig$substrate)
}

binding_contract_result <- function(fig) {
  # The contract arm replays engine claims and independently places their rows
  # through the captured panel scales.  It does not use a package rule written
  # by this prototype.  A failure is a recorded refusal.
  out <- tryCatch(gloss:::alone_capture(fig), error = function(e) e)
  if (inherits(out, "error")) {
    return(list(status = "refused", reason = conditionMessage(out)))
  }
  list(status = "measured", leaves = out$leaves, elements = out$elements)
}

binding_legacy_result <- function(fig) {
  list(elements = gloss::gl_bindings(fig, by = "element"),
       leaves = gloss::gl_bindings(fig, by = "leaf"),
       rows = gloss::gl_bindings(fig, by = "row"))
}

binding_write_material <- function(fig, svg, dir, figure_id = NA_character_) {
  dir.create(file.path(dir, "public", "tables"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(dir, "oracle"), recursive = TRUE, showWarnings = FALSE)
  gx <- suppressWarnings(gloss::gloss(fig, context = TRUE))
  scene <- gx$substrate$scene
  scene_hash <- digest::digest(scene, algo = "sha256", serialize = FALSE)
  facts <- binding_public_facts(gx, figure_id = figure_id, source_scene_sha256 = scene_hash)
  jsonlite::write_json(facts, file.path(dir, "public", "facts.json"), auto_unbox = TRUE,
                       pretty = TRUE, null = "null", na = "null", dataframe = "rows")
  writeLines(enc2utf8(scene), file.path(dir, "public", "figure.svg"), useBytes = TRUE)
  for (nm in names(facts$tables)) {
    d <- facts$tables[[nm]]
    utils::write.csv(cbind(row = seq_len(nrow(d)), d),
                     file.path(dir, "public", "tables", paste0(nm, ".csv")), row.names = FALSE)
  }
  tree <- tryCatch({
    grDevices::pdf(NULL, width = gx$meta$width, height = gx$meta$height)
    dev <- grDevices::dev.cur()
    on.exit(if (dev %in% grDevices::dev.list()) grDevices::dev.off(dev), add = TRUE)
    gt <- if (inherits(fig, "patchwork")) patchwork::patchworkGrob(fig) else ggplot2::ggplotGrob(fig)
    utils::capture.output(grid::grid.ls(grid::grid.force(gt)))
  }, error = function(e) paste("the grob tree could not be listed:", conditionMessage(e)))
  writeLines(tree, file.path(dir, "public", "grob_tree.txt"), useBytes = TRUE)
  legacy <- binding_legacy_result(gx)
  geometry <- binding_geometry(gx)
  # Replaying the engine's contract can be much slower than writing the
  # material for a large figure.  Keep the raw figure in the hidden oracle and
  # defer this replay to the contract arm, where its cost is measured.
  contract <- list(status = "deferred", reason = "contract replay is run by the contract arm")
  oracle <- list(format = "gloss-agent-binding-oracle", version = binding_material_version,
                 figure = as.character(figure_id), figure_object = gx, source_figure = fig, legacy = legacy,
                 geometry = geometry, contract = contract,
                 scene_sha256 = scene_hash)
  saveRDS(oracle, file.path(dir, "oracle", "oracle.rds"), version = 3)
  # This JSON is intentionally a digest-only index.  It makes it possible to
  # audit which hidden files were used without putting their values in public.
  jsonlite::write_json(list(format = oracle$format, version = oracle$version,
                            scene_sha256 = scene_hash,
                            legacy_sha256 = digest::digest(legacy),
                            geometry_sha256 = digest::digest(geometry),
                            contract_sha256 = digest::digest(contract)),
                       file.path(dir, "oracle", "index.json"), auto_unbox = TRUE, pretty = TRUE)
  list(elements = nrow(facts$elements), leaves = nrow(facts$leaves), tables = length(facts$tables),
       source_scene_sha256 = scene_hash, contains_binding_answers = FALSE,
       legacy_rows = nrow(legacy$elements), contract_status = contract$status)
}

binding_export_helpers <- function() {
  list(
    `%||%` = `%||%`,
    binding_material_version = binding_material_version,
    binding_safe_columns = binding_safe_columns,
    binding_fact_tables = binding_fact_tables,
    binding_fact_leaves = binding_fact_leaves,
    binding_fact_elements = binding_fact_elements,
    binding_layer_params = binding_layer_params,
    binding_public_facts = binding_public_facts,
    binding_geometry = binding_geometry,
    binding_contract_result = binding_contract_result,
    binding_legacy_result = binding_legacy_result,
    binding_write_material = binding_write_material
  )
}

binding_files_hash <- function(dir, public = TRUE) {
  root <- file.path(dir, if (public) "public" else "oracle")
  files <- sort(list.files(root, recursive = TRUE, all.files = FALSE, full.names = TRUE))
  files <- files[file.info(files)$isdir %in% FALSE]
  if (!length(files)) return(list(files = character(), sha256 = character(), manifest = digest::digest(character(), algo = "sha256")))
  rel <- sub(paste0("^", normalizePath(root), "/?"), "", normalizePath(files))
  sums <- vapply(files, digest::digest, "", algo = "sha256", serialize = FALSE)
  list(files = rel, sha256 = unname(sums), manifest = digest::digest(paste(rel, sums, sep = "=", collapse = "\n"), algo = "sha256", serialize = FALSE))
}

binding_check_public_material <- function(dir) {
  public <- file.path(dir, "public")
  required <- file.path(public, c("facts.json", "figure.svg", "grob_tree.txt"))
  if (!all(file.exists(required))) return(list(ok = FALSE, reason = "public material is incomplete"))
  forbidden <- c("answers.rds", "oracle.rds", "legacy", "geometry", "checker")
  files <- list.files(public, recursive = TRUE, all.files = TRUE, full.names = TRUE)
  hit <- files[grepl(paste(forbidden, collapse = "|"), basename(files), ignore.case = TRUE)]
  if (length(hit)) return(list(ok = FALSE, reason = sprintf("public material contains hidden filename: %s", basename(hit[1L]))))
  facts <- tryCatch(jsonlite::read_json(file.path(public, "facts.json"), simplifyVector = FALSE), error = function(e) e)
  if (inherits(facts, "error")) return(list(ok = FALSE, reason = conditionMessage(facts)))
  if (!identical(facts$version, binding_material_version)) return(list(ok = FALSE, reason = "unexpected public material version"))
  list(ok = TRUE, reason = NA_character_, manifest = binding_files_hash(dir, TRUE))
}
