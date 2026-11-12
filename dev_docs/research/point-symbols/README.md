# What svglite draws for a point symbol (2026-11-12)

Evidence for [plan 2026-11-11-tree-binding](../../../plan/2026-11-11-tree-binding.md), Task 5, written before the rule it informs. Nothing here is package code.

**Question.** Bench tree-014 draws 8100 points in eight shapes (`scale_shape_manual(values = 1:8)`) as 12690 SVG elements. Capture expected one element per point, so the leaf, half the tree stratum's layer elements, is a count mismatch. What does each `pch` draw, and where does each part lie relative to its point, so that a point drawn as k elements can be counted and checked part by part?

**Script.** [`pch.R`](pch.R), run from the repository root, draws on `svglite::svgstring()` only.

| Output | Where | Library |
|---|---|---|
| [`pch-host.out`](pch-host.out) | host, macOS, R 4.5.2, svglite 2.2.2, ggplot2 4.0.3.9000 | the host's |
| [`pch-container-bioc.out`](pch-container-bioc.out) | bench container, Linux, R 4.5.2, svglite 2.2.2, ggplot2 4.0.0 | `bioc`, the tree stratum's |

The two outputs are identical line for line except the ggplot2 version.

## What it showed

**1. Parts per symbol, in drawing order** (one point; lines solid; positive size):

| pch | parts | | pch | parts |
|---|---|---|---|---|
| 0 | rect | | 13 | circle, line, line |
| 1 | circle | | 14 | polygon, rect |
| 2 | polygon | | 15 | polygon |
| 3 | line, line | | 16 | circle |
| 4 | line, line | | 17 | polygon |
| 5 | polygon | | 18 | polygon |
| 6 | polygon | | 19 | circle |
| 7 | rect, line, line | | 20 | circle |
| 8 | line × 4 | | 21 | circle |
| 9 | line, line, polygon | | 22 | rect |
| 10 | circle, line, line | | 23 | polygon |
| 11 | polygon, polygon | | 24 | polygon |
| 12 | line, line, rect | | 25 | polygon |

`"."` (46) draws one rect; another character, or a code from 32 to 127, or a negative code (Unicode), draws one `<text>`. Codes 26-31 and from 256 up draw nothing (with R's warning "unimplemented pch value"); so do 128-255 in a multibyte locale unless the font face is 5 (symbol), as `GESymbol()`'s `maxchar` says. `pch = NA`, `""` and `NA_character_` draw nothing. Several points draw their parts point after point (`pch = c(7, 1, 8)`: rect line line circle line line line line).

**2. Where the point lies in each part's box** (section 1b, sizes 3 to 96 pt): at the centre, `(0.5, 0.5)`, for every part of every symbol except the triangles. An upward triangle (2, 17, 24) holds its point 2/3 of the way down its box, a downward one (6, 25) 1/3; pch 11's two triangles hold it at 3/7 and 4/7. These are the ratios R's engine builds its triangles from (`TRC0`, `TRC2 = TRC0 / 2`; pch 11's base at `(TRC0 + TRC2) / 2`). Using the fractions measured at 96 pt at every size from 3 to 96 pt puts the point within 0.0075 pt of where it is. So a part's box alone gives its point, which is what a dense leaf keeps (`core-substrate.R`: a dense leaf's elements keep their boxes).

The vertex mean, the rule the binder applies to one polygon per row today, is the point for a single triangle (the triangles are centred on their centroid) but not for pch 11 (±0.58 pt at size 6) or pch 14's triangle (0.75 pt).

**3. What removes parts** (sections 2 and 2c):

- A point whose x, y or size is not finite draws nothing (`NA`, `Inf`); a point off the page still draws all its parts.
- `lty = 0` or `"blank"`, `lwd = NA` or `lex = NA` remove the `<line>` parts and nothing else: polygons, rects and circles are still drawn (pch 7 under `lty = 0` draws its rect; pch 3, 4 and 8 draw nothing). `lwd = 0`, `lex = 0`, `col = NA` and `alpha = 0` remove nothing.
- A size of zero (or below) removes the circles and nothing else; lines and squares are drawn with zero length. The same holds for a zero font size or `cex` when the size is in `"char"` (ggplot2's case: `pointsGrob()`'s size is `unit(1, "char")` and the symbol's size is the font size). A character symbol is drawn at any size.
- These settings can come from the leaf's own `gpar` or from a parent gTree or viewport: `lty`, `lwd` and `fontsize` are replaced by the leaf's when it sets them; `lex` and `cex` multiply down the tree. Settings in a `gpar` are recycled point by point.

**4. ggplot2** (section 3): the built `shape` column holds what `scale_shape_*()` mapped (integers for `values = 1:8`); a shape given by name stays a string in the built data and `GeomPoint$draw_panel()` turns it into a number with `translate_shape_string()` (exported in both versions above) just before drawing.

**5. A character symbol drawn as a glyph outline** ([`glyph.R`](glyph.R), [`glyph-host.out`](glyph-host.out), [`glyph-container-bioc.out`](glyph-container-bioc.out); added the same day, after reading bench tree-061, whose `geom_point(shape = '|')` under `emojifont` draws each symbol as a path and passed the vertex-mean rule at 0.49 pt). Under `showtext`, six glyphs at sizes 1.5, 4 and 10, host and container identical: the vertex mean of the outline is off the point by up to 10.7 pt (`|` at tree-061's size: 0.48-0.49 pt, which is the 0.49 the bench reported), so that pass was luck. The outline's box is centred on the point across the baseline within 0.01 pt for every glyph, since `GESymbol()` draws a character with `GEText()` centred by its metric box and `showtext` gives that box from the outline. Along the baseline the box's centre is the point for symmetric glyphs (0.01 pt) and off by the side bearings otherwise (`j`: 0.24-1.36 pt); the point lies inside the box in every case.

**6. Base graphics** ([`base.R`](base.R), [`base-host.out`](base-host.out); added 2026-11-12 for plan Task 6). `points()` and `plot(type = "p")` draw each `pch` with the same parts as grid (the engine's `GESymbol()`), point after point. The recorded `plot.xy()` call holds `xy`, `type`, `pch`, `lty`, `col`, `bg`, `cex`, `lwd` in that order, `pch` and `cex` recycled over the points, and `font` among the extra arguments when given. Two things differ from grid: base draws a symbol's lines solid whatever `lty` or `lwd` says (`lty = 0`, `"blank"`, `par(lty = 0)`, `lwd = NA`: all parts drawn), and a point whose `cex` is 0, negative or `NA` draws nothing at all, where grid drops only a zero-size symbol's circles.

## What follows for gloss

- Capture can count a points grob exactly from its `pch`, positions, size and settings, when it knows the settings it inherits; the leaf grob alone does not hold a parent's `lty`. They are known where the leaf is drawn, which is where gloss's probe runs.
- The binder can check a point drawn as k parts part by part, in drawing order, from each part's box and the fraction its symbol puts the point at, on dense leaves too, provided the rows state their shape.
- A character symbol drawn as an outline can be checked as text is: exactly across the baseline (the box's centre), inside the box along it.
