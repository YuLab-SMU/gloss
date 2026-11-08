# 2026-11-08 — Figures for the idea notes and the evaluation plan; two evaluation-plan corrections

- **Related plan:** none (documentation patch; M0 is still next)
- **Related ADRs:** none changed
- **Worked on by:** Yonghe Xia, Claude

## What changed

The two idea notes and the evaluation part of `dev_docs/design.qmd` now have figures. Generated images are used only where the research-writing skill allows them: schematics with little text, and hero images. Evidence figures are drawn from real screenshots or real data in R.

**Figures**

| File | Where | Kind |
|---|---|---|
| `idea/figures/prior-art-routes-v4.png` | prior-art note, Findings | AI-generated schematic (Sunburst medium): four routes, each stopped at its measured boundary |
| `idea/figures/prior-art-redraw-evidence.png` | prior-art note, §3 | real 700×500 screenshots (svglite / plotly / canvasXpress) for patchwork, ggrepel and the forest plot. Pixel shares are read from `pixel_diffs.csv` and asserted against the numbers in the note. |
| `idea/figures/agentic-svg-hero-v1.jpg` | founding note | AI-generated hero (Sunburst high), anchored on the design doc's hero |
| `man/figures/README-overview.png` (existing) | founding note, "What became of it" | existing schematic, reused |
| `dev_docs/figures/design/fig-decisive-v1.png` | design §research-card | AI-generated schematic: conditions A and B differ only in the substrate |
| `dev_docs/figures/design/fig-masked-v1.png` | design §eval | AI-generated schematic of masked evaluation |
| `dev_docs/figures/design/fig-perturb.png` | design §eval | data (mtcars): the original, a perturbed version and a counterfactual version, with each check computed |

Every generated image has a `.prompt.md` sidecar with the model, quality, size, full prompt, rounds and the checks run. Each caption says it is AI-generated.

The routes figure took three generation rounds:
- v1 had a blurred dot and a box touching the edge;
- v2 fixed the dot but moved the box onto two labels;
- v3 still had a faint blur.

The dot was then repainted with ImageMagick and the canvas padded. Both steps are recorded in the sidecar. Drafts were deleted. The generated PNGs were resized to 1600 px and quantized to PNG8 (100–180 KB each), and every string was re-checked after quantization.

**Evaluation-plan corrections in `design.qmd` (made while drawing the figures)**
- **The silent mis-anchoring threshold is now provisional.** "低于 1%" became "低于事先登记的门槛（暂定 1%，没有数据依据）", fixed after the M2 pilot and registered before M5. Anchor hit rates have no measurement yet (§risks).
- **The pre-registered predictions now state their basis.** Only the first has data (481/486 on three figures); the other three are marked as reasoning. The rationale for the verification prediction was wrong: it said roles are not checked, but §classify defines consistency checks for roles. It now cites them.
- **The perturbed set no longer shuffles each column independently.** Independent shuffling erases the relationships between columns, so the perturbed figure is no longer the same task. The rule is now: rename everything, apply an increasing affine map per numeric column, shuffle row order, and rewrite the claim with the new names. `fig-perturb.png` shows that the trend survives: the slope goes from −5.34 to −4.70.
- **New counterfactual subset.** Names are kept and one column is reflected onto its own range, so common sense and the data disagree. This tests whether a model checks claims or guesses them; on mtcars the slope becomes +5.34 and "heavier = thirstier" fails. It was added to the rival explanations in the research card, the leakage section, the M5 row, the reviewer pre-mortem and the change note.

## Verification

- Every string in each generated image was checked against its prompt, character by character for the Chinese ones. Semantics were checked per sidecar: leader lines end on dots, the ✓/✗ placement is right, and blue appears only on condition B.
- `Rscript idea/figures/src/prior-art-redraw-evidence.R` and `Rscript dev_docs/figures/design/src/fig-perturb.R` both run. Their `stopifnot` checks hold: the pixel shares match the note, the screenshots are 700×500, the slopes have the expected signs, and the reflected range is unchanged.
- `fact_diff.py` against `HEAD` for the three changed documents: nothing missing.
- `tell_scan.py`: 0 strong tells.
- `quarto render dev_docs/design.qmd --to html`: renders; `fig-decisive`, `fig-perturb` and `fig-masked` resolve.
- All image and sidecar links in the idea notes resolve.

## What's next

- Same as the evaluation-plan log: open M0, which now includes sampling and freezing the benchmark. Write `bench/predictions.md` with the anchor threshold once the M2 pilot exists.
- If the generated schematics need a Chinese/English twin or frequent edits, redraw them as SVG under `dev_docs/figures/design/src/`, as the skill recommends for that case.
