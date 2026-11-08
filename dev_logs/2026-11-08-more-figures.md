# 2026-11-08 — Illustrate the abstract mechanisms in the design doc, README and idea notes

- **Related plan:** none (documentation patch; M0 is still next)
- **Related ADRs:** none changed
- **Worked on by:** Yonghe Xia, Claude

## What changed

The first figure round covered the evaluation plan and the idea notes' headline claims. Most of the design doc's mechanisms still had no picture: anchors, the record log, conflicts, the agent's tool boundary, row-key inference, the bundle, restore and the plugin core. These are described only in prose and tables. This round adds 25 AI-generated schematics and one analogy illustration, each placed where the text explains the mechanism and cited from that text.

**`dev_docs/design.qmd` (20 figures, each with `@fig-` references in the text)**

| Figure | Section | What it shows |
|---|---|---|
| `fig-analogy` | §analogy | the four parts of a glossed manuscript and their gloss counterparts (Sunburst high, in the hero's series) |
| `fig-order-vs-group` | substrate, rejected alternatives | the measured ggiraph misbinding (`rep(each = )` over 4 elements) next to group delimiting |
| `fig-rowkey` | §rowkey | the five inference rules in order, and re-keying with `gl_key()` |
| `fig-cues` | §classify | three cue kinds → rules → residue → agent → correction as a record |
| `fig-views` | §hierarchy | structure tree, data tree and semantic groups over the same elements |
| `fig-provenance` | §provenance | Direct / Derived / Speculative and what each requires |
| `fig-verify-loop` | verify re-run | the three checks per write, and the re-run after any substrate change |
| `fig-anchor` | §anchor | the selector ladder and the three outcomes of the anchor as a whole |
| `fig-log` | records, layers and log | the four kinds of change, all appended to `claim.jsonl` |
| `fig-conflict` | §conflicts | two contradictory records and a resolution record |
| `fig-agent-tools` | agent tools | read-only tools, one validated `propose`, and what the agent cannot do |
| `fig-disclose` | safety and disclosure | the four disclosure levels, `summary` by default |
| `fig-operate` | §operate | four callers, one vocabulary, two runtimes |
| `fig-ops-context` | context-enabled operations | the three examples from the text |
| `fig-bundle` | directory and single file | the two bundle forms and `gl_write()` / `gl_read()` |
| `fig-restore` | restore | four inputs and what each restores |
| `fig-sniff` | §context | the six sniffed items, one shown as not found |
| `fig-plugins` | §plugins | the five-part core and eight extension points |
| `fig-milestones` | §plan | M0–M3 without an LLM, M4–M5 with one |
| `fig-misanchor` | §risks | the open selector-fallback problem, step by step |

**README:** `man/figures/README-question-v3.png` in "Why": the same "which car is this?" question asked of a plain SVG and of gloss.

**Idea notes:**
- prior-art note: the English twin of the order figure (§1), Shiny's jitter miss (§2) and InteractiveComplexHeatmap's position table (§2). The redraw-evidence figure was renumbered from 2 to 5.
- founding note: the S0–S4 levels and the 2026-11-07 pipeline. The overview figure was renumbered from 2 to 4, and its caption now points to Figure 3.

Every caption says the image is AI-generated and not data. Captions also mark design figures as not yet implemented, and say where a pixel fix was made. Every image has a `.prompt.md` sidecar with the model, quality, size, reference image, rounds, fixes, checks, the mapping to the text, and the full prompts, including the edit prompts. The two figure index files list the new images.

## Defects found and how they were fixed

Every image was opened and checked string by string, character by character for Chinese. The semantics were checked too: arrows, ✓/✗ placement, and dot counts across panels. Six images failed:

- **`fig-anchor` v1:** arrows from single selectors implied per-selector outcomes. An edit replaced them with one bracket (v2).
- **`fig-agent-tools`:** a stray × on the `propose` arrow read as "blocked". One edit failed to remove it, so it was painted out with PIL (v3).
- **`fig-views`:** "来自构建数据" came out as "表自构建数据", and one edit failed to fix it. The character was redrawn with PIL in Hiragino Sans GB W6, with the colour sampled from its neighbours (v3).
- **`fig-misanchor` v1:** two dots sat inside the region, which broke the "unique but wrong" story. One was painted out (v2).
- **`README-question`:** v1 trended upward, although mpg falls with weight, and had a ghost dot. In v2 the right panel had one dot more than the left. That dot was painted out (v3), so both panels show the same 25 dots.
- **`prior-art-hittest` v1:** labels pointed at the wrong marks. It was regenerated from a corrected prompt (v2).

All drafts were deleted. The PNGs were resized to 1600 px and quantized to 128-colour PNG8 (70–233 KB each). The normalized RMSE against the unquantized resize was at most 0.0098. Every string was re-read on the published files, and `fig-analogy` is a JPG.

Two facts were re-checked against the sources while writing captions:
- the misbinding mechanism (`rep(each = )` recycling, from the prior-art note);
- `facet_wrap(~am)` in the spike scripts, together with Mazda RX4 being row 1 of `mtcars` with `am = 1`.

## Verification

- `quarto render dev_docs/design.qmd --to html`: renders with no warnings. The output has 0 unresolved `?@fig`/`?@tbl`/`?@sec` references, and all 20 new figure ids are present.
- `fact_diff.py` against `HEAD` for `design.qmd`, `README.md` and both idea notes: nothing missing; only figure and reference tokens added.
- `tell_scan.py`: 0 strong. The founding note's 2 medium hits are in the Showcase section and are the same in `HEAD`.
- Every relative link, image, GitHub link and cited sidecar in the four documents resolves (102 checked).

## What's next

- M0 as before.
- If these schematics need frequent edits or a Chinese/English twin beyond `fig-order-vs-group`, redraw them as SVG under `dev_docs/figures/design/src/`. Generated images cannot be edited reliably, as the three edit failures in this round show.
