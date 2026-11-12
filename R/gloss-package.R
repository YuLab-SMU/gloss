#' gloss: layered, verifiable semantics for R figures
#'
#' `gloss()` captures a figure that has already been drawn into a read-only
#' substrate: every drawn element is traced to the leaf grob, viewport and
#' panel that produced it, and the figure's data tables are kept with an
#' inferred row key. The substrate can be queried (`gl_elements()`,
#' `gl_hit()`, `gl_to_pixel()`), re-keyed (`gl_key()`) and written to a
#' directory or a single HTML or SVG file (`gl_write()`, `gl_read()`).
#'
#' Engines, context sniffers and projections are plugins registered with
#' `gl_register()`; the built-in ones use the same call.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom grid drawDetails
#' @importFrom rlang .data
## usethis namespace: end
NULL
