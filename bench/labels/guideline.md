# Role labelling guideline

> Version 1, 2026-11-11, written before any bench figure was labelled (M1 plan [`2026-11-11-m1-roles-and-binding`](../../plan/2026-11-11-m1-roles-and-binding.md), Task 1). It may change on the development set; each change gets a dated entry under *Changes* and a new version number, and labels record the version they were made under. The held-out set gets its own fixed version in the next plan.

Labels are the truth that rules and checks are scored against. A label says what an element **is to a reader of the figure**. It does not say how gloss could find that out.

## What you label

Every leaf with at least one element on the figure's sheet gets a **role** and a **kind**. Leaves with 0 elements are skipped: they draw nothing, and they are not counted.

Materials, under `bench/labels/sheets/` (built by `bench/R/label-sheet.R` from a container capture):

| File | What it is |
|---|---|
| `<id>-page.png` | The page as the figure's code draws it |
| `<id>.png`, `<id>.svg` | The same page with each leaf's elements boxed and numbered by `k` (the SVG zooms) |
| `<id>.csv` | One row per leaf: `k`, class, number of elements, tags, box, first text, colours, path. This is the file you fill in |
| `<id>-elements.csv` | One row per element, numbered within its leaf (`index`); use it for splits |
| `bench/figures/<id>/code.R` | The figure's code |

You may use the page, the sheet, the two tables and the code. Do not use the other annotator's labels, gloss's output beyond the sheet, or any bench run tables (`bench/runs/`). The path in the sheet shows which part of the figure drew a leaf. It **locates** the leaf; it does not decide the role. A base `legend()` draws `rect`, `points` and `text`, and none of them is data.

## Roles and kinds

| Role | What it is | Kinds |
|---|---|---|
| `data` | Its position or content comes from the rows of a data table: the plot's data, a layer's data, what a stat computed from them, a matrix | `point`, `line`, `area`, `bar`, `cell`, `segment`, `box`, `text`, `other` |
| `guide` | It tells the reader how to read the data marks | `axis line`, `tick`, `tick label`, `axis title`, `legend key`, `legend label`, `legend title`, `colour bar`, `strip label`, `other` |
| `reference` | A line or band at a value typed in the code or fixed by the scale, which helps read positions | `grid line`, `reference line`, `reference area` |
| `annotation` | Text or marks whose content and position the author typed | `title`, `text`, `mark` |
| `decoration` | Carries no information: backgrounds, borders, frames | `background`, `border`, `other` |

Kinds:

- `point`: a symbol at a row's position (scatter, jitter, outliers of a boxplot, dot plot).
- `line`: a path through several rows (line, step, fitted line, density curve, ROC curve, the edges of a band).
- `area`: a filled region drawn from rows (area, ribbon, confidence band, density fill, violin, map polygon).
- `bar`: a rectangle from a baseline to a value (bar, column, histogram bin).
- `cell`: a rectangle or raster in a grid of them (tile, raster, heatmap body cell, heatmap annotation cell, hexagon).
- `segment`: a straight piece per row or per pair of rows (segment, error bar, whisker, line range, rug, dendrogram branch, a data label's leader line, a computed comparison bracket).
- `box`: the box and median of a boxplot, a crossbar.
- `text`: text whose content or position comes from rows (data labels, repelled labels, counts on bars, values in heatmap cells, computed p-values).
- `axis line`, `tick`, `tick label`, `axis title`: one axis's parts. A heatmap's row and column names are `tick label`; the name of a heatmap annotation track is `axis title`.
- `legend key`: the glyph of a legend entry, whatever its shape (point, line, rectangle, the letter "a" ggplot draws for text layers).
- `legend label`, `legend title`: the entry's text, the legend's title.
- `colour bar`: a continuous legend's bar (its rectangles or raster) and its ticks.
- `strip label`: text naming a facet panel, or a slice of a split heatmap.
- `grid line`: a panel's grid lines (major and minor), base `grid()`, a map's graticule.
- `reference line`: a line at a typed value (`geom_hline(yintercept = 0)`, `abline(h = 20)`, a ROC plot's diagonal).
- `reference area`: a band at typed values that spans the panel (`geom_rect(xmin = -Inf, xmax = Inf, ymin = 1, ymax = 2)`).
- `title`: title, subtitle, caption, tag (`labs(tag = "A")`, patchwork tags), base `main`; a heatmap's column or row title when that dimension is not split.
- `text`: other typed text (`annotate("text")`, base `text()` or `mtext()` with typed strings that are not axis titles).
- `mark`: a typed shape (`annotate("rect")` or `annotate("segment")` placed by hand, a typed arrow or bracket).
- `background`: a filled rectangle behind other elements (plot, panel, legend, legend key, strip backgrounds; a base legend's filled box).
- `border`: an outline with no fill (panel border, base `box()`, a heatmap's border).
- `other`, in any role: say what it is in `note`.

## How to decide

Ask in this order and stop at the first yes.

1. **Is its position or content computed from rows?** Then `data`. This includes text that labels rows, the segments that lead to such labels, fitted lines and their bands, boxplots, densities and error bars, brackets and p-values computed by a stat (`ggsignif`, `stat_compare_means()`), heatmap body and annotation cells, and dendrograms. A line whose value comes from the data (`geom_hline(aes(yintercept = mean_y))` on a computed mean) is `data`.
2. **Does it tell the reader how to read the data marks?** Then `guide`: axes, legends, colour bars, facet and slice labels, a heatmap's row and column names, annotation track names.
3. **Is it a line or band at a typed value that helps read positions?** Then `reference`. A value typed in a data frame in the code (`geom_vline(data = data.frame(x = c(-1, 1)), ...)`) is typed, so `reference`.
4. **Did the author type both its content and its position?** Then `annotation`. A typed label drawn once per row (a constant `label` mapped over all rows) is still `annotation`, kind `text`.
5. Otherwise `decoration`.

Cases decided here so that two annotators decide them the same way:

- **Strips and slices.** Strip or slice background: `decoration` / `background`. Its text: `guide` / `strip label`.
- **Legends.** Legend and key backgrounds: `decoration` / `background`. Every key glyph: `guide` / `legend key`. A base `legend()` box: `decoration`, `background` if it is filled, `border` if it is only an outline.
- **Base axes.** One `axis` leaf draws the axis line, the ticks and the tick labels. All are `guide`; give the kinds by element ranges (see *Splits*).
- **Base `title()`.** One leaf draws `main`, `xlab` and `ylab`: `main` is `annotation` / `title`, the axis labels are `guide` / `axis title`. This is a split.
- **Heatmap titles.** A column title of a heatmap whose columns are split names a slice: `guide` / `strip label`. If the columns are not split, it is the heatmap's title: `annotation` / `title`. The same holds for row titles.
- **Repelled labels** (`ggrepel`) and their segments: `data` / `text` and `data` / `segment`.
- **Rugs, marginal plots** (`ggExtra`, `ggside`): `data`, with the kinds of their marks; their axes are `guide`.
- **Invisible elements** (no stroke and no fill, zero size, fully transparent, clipped away) are labelled by what drew them, with `invisible` in `note`. An invisible outline of a confidence band is `data` / `line`.
- **Images, logos, rasters that are not data:** `decoration` / `other`, with a note.
- **Dense leaves** appear on the page as one image. Label them by the marks they draw.
- **Unsure:** give the role you think most likely and write `unsure: <other role or kind>` in `note`. Never leave a leaf with elements unlabelled.

## Splits

A leaf normally takes one row with `elements` = `all`. When its elements need different labels, copy the row once per group and set `elements` on each copy to that group's element indices from `<id>-elements.csv`: `1`, `2-5` or `1,3-4`. The copies must cover every element of the leaf exactly once.

- When the copies have **different roles**, the leaf is **split**. Splits test the plan's assumption 3, that a role belongs to a leaf.
- Different **kinds** under one role (a base axis) are given the same way. They are not counted as splits.

## Recording

Labels can be made in the label workbench, which writes the files below and the time (`python3 bench/labels/workbench/serve.py --sheets <sheets> --out <your labels directory>`), or by hand:

- Copy `<id>.csv` from the sheets to your labels directory (`bench/labels/pilot/<annotator>/` for the pilot, `bench/labels/dev/` for the development set). Fill in `role`, `kind` and, where needed, `note`. Do not edit the other columns: `key`, `occurrence`, `class` and `n_elements` tie the label to the leaf, and a label that no longer resolves to its leaf fails `bench/R/score-labels.R`.
- Record the minutes you spent on each figure in `time.csv` in the same directory, with columns `figure`, `minutes`, `guideline` (this file's version) and `note`.

## Agreement

The pilot compares two annotators on the same figures, using `Rscript bench/R/score-labels.R agree <dir A> <dir B>`.

- **Unit.** Each leaf with elements counts once. Its weight is shared equally by its elements, so a split leaf counts by the share of its elements in each role. Cohen's κ on roles in this leaf-weighted form is the plan's criterion: 0.8 or more.
- **Also reported.** κ weighted by elements (dominated by a figure's largest leaves); κ on role and kind together; the confusion of roles; the share of leaves each annotator split; minutes per figure.

## Worked examples

These come from three hand-built figures, not bench figures (`bench/labels/examples/make.R`). Their sheets and one annotator's labels are in `bench/labels/examples/`. `k` refers to each sheet.

| Role / kind | Example |
|---|---|
| data / point | `ex-ggplot` 8, 26 (`geom_point`); `ex-base` 1 (`plot()` points) |
| data / line | `ex-ggplot` 11, 14, 17 (`geom_smooth` fitted lines); 10, 13, 16 (the bands' edges, invisible) |
| data / area | `ex-ggplot` 9, 12, 15 (confidence bands) |
| data / bar | `ex-base` 12 (`barplot()`) |
| data / cell | `ex-heatmap` 2, 3 (body cells), 15 (annotation track cells) |
| data / segment | `ex-heatmap` 7–11 (dendrograms) |
| data / text | `ex-ggplot` 36 (car names from the rows) |
| guide / axis line | `ex-base` 2, element 1 |
| guide / tick | `ex-ggplot` 43, 45, 48; `ex-base` 2, elements 2–5 |
| guide / tick label | `ex-ggplot` 44, 46, 47; `ex-heatmap` 12–14 (row and column names) |
| guide / axis title | `ex-ggplot` 49, 50; `ex-base` 5, elements 2–3; `ex-heatmap` 16 (annotation name) |
| guide / legend key | `ex-ggplot` 54–57 (point, band, line and text glyphs); `ex-base` 8 (`legend()` points); `ex-heatmap` 24 |
| guide / legend label | `ex-ggplot` 66–68; `ex-base` 10; `ex-heatmap` 18, 23 |
| guide / legend title | `ex-ggplot` 52; `ex-base` 9; `ex-heatmap` 17, 22 |
| guide / colour bar | `ex-heatmap` 19–21 (bar and ticks) |
| guide / strip label | `ex-ggplot` 40, 42; `ex-heatmap` 5, 6 (row slice titles) |
| reference / grid line | `ex-ggplot` 3–6, 21–24 |
| reference / reference line | `ex-ggplot` 7, 25 (`geom_hline(yintercept = 20)`); `ex-base` 6 (`abline(h = 20)`) |
| annotation / title | `ex-ggplot` 69 (title), 70 (caption); `ex-base` 5, element 1, and 14; `ex-heatmap` 4 (column title, columns not split) |
| annotation / text | `ex-ggplot` 18, 37; `ex-base` 11 |
| annotation / mark | `ex-ggplot` 19, 38 (`annotate("rect")`) |
| decoration / background | `ex-ggplot` 1, 2, 20 (plot and panels), 39, 41 (strips), 51 (legend), 53, 58, 62 (keys); `ex-base` 7 (`legend()` box, filled); `ex-heatmap` 1 |
| decoration / border | `ex-base` 4 (`box()`) |

Not shown by the examples: `data` / `box`, `reference` / `reference area` and the three `other` kinds; nor a ggplot axis line (the default theme draws none).

## Changes

- 2026-11-11, version unchanged (1): the *Recording* section names the label workbench as a second way to make the same label files. No role, kind, case or unit of agreement changed. The workbench asks the questions of *How to decide* in their order and shows the kinds' definitions in Chinese, translated from this file (`bench/labels/vocabulary.json`, which also holds the English); where a translation and this file differ, this file holds.
