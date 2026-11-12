# Where ggimage puts a justified image (2026-11-12)

Evidence for [plan 2026-11-11-tree-binding](../../../plan/done/2026-11-11-tree-binding.md), Task 6. It was written after a rule it overturned (`897bedc`) and before the rule that replaced it. Nothing here is package code.

**Question.** In bench tree-041, `geom_tiplab(geom = "image")` passes ggimage `hjust = 0`, a parameter of `GeomImage$draw_panel()`, not a column of the rows. `imageGrob()` then moves the image right by `width / 2`, where `width` is its own estimate. That estimate is `size * adj` for `by = "width"` and `size * asp * adj` for `by = "height"`, with `adj = size / diff(x.range)` from `build_adjust()`. The raster itself is drawn with a height and no width, so grid gives it the width its aspect ratio implies. Where does the image lie relative to its row?

**Script.** [`ggimage.R`](ggimage.R) runs in the bench container with the bioc library (ggimage 0.3.4, ggplot2 4.0.0, svglite 2.2.2, R 4.5.2). It draws three rows with `geom_image()`, crossing `by` (width, height), the x range (0-8, 0-30), `size` (0.05, 0.2) and `hjust` (0, 0.5, 1). For each case and row it prints the row's position on the page, from gloss's ggplot engine (the transform the binder uses), and the box of the `<image>` svglite wrote. Output: [`ggimage-container-bioc.out`](ggimage-container-bioc.out), 72 cases.

## What it showed

| hjust | by | size | box width (pt) | box centre − row along x (pt) |
|---|---|---|---|---|
| 0.5 | both | both | 16.1-83.3 | -0.01 to 0.01 |
| 0 | width | 0.05 | 16.1 | 0.01-0.07 |
| 0 | width | 0.2 | 64.5 | 0.28-1.07 |
| 0 | height | 0.05 | 20.8 | 0.17-0.18 |
| 0 | height | 0.2 | 83.3 | 2.75-2.76 |
| 1 | (the same, negated) | | | |

- The image moves by ggimage's estimate of half its width. That is far less than half the width it is drawn at (32-42 pt at size 0.2), and it depends on the x range for `by = "width"`. So the row is neither at the box's edge (grid's meaning of `hjust = 0`) nor at its centre once the move exceeds the binder's 0.5 pt.
- In all 72 cases the row lies inside the box along x, and at the box's centre across, within 0.01 pt.

## What follows for gloss

- An image whose rows state a justification other than the centre is checked along that axis by the box (the row must lie inside it) and across by the centre. Grid's `rasterGrob(hjust = )`, which starts or ends the image at its row, passes the same check. This is what `R/core-bind.R` does after this note. The rule it replaced placed the box by `(0.5 - hjust)` of its width; it was right for grid and would have failed tree-041's six tip images by about 31 pt.
- Modelling ggimage's own estimate would put one package's internals in the core; the box check needs none.
