# Projection plugin: a single SVG file with the whole bundle embedded in a
# non-executable <script type="application/json">.

register_projection_svg <- function() {
  gl_register("projection", name = "svg", version = "0.1.0", package = "gloss",
              description = "single SVG file: the scene plus the embedded bundle",
              formats = "svg", write = write_svg)
}

write_svg <- function(fig, path, embed = "default", ...) {
  scene <- scene_for_projection(fig)
  scene <- sub("</svg>\\s*$", paste0(embed_script(fig, embed), "\n</svg>\n"), scene)
  writeBin(as_bytes(paste0("<?xml version='1.0' encoding='UTF-8' ?>\n", scene)), path)
  invisible(path)
}
