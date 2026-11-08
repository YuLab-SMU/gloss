# hero-manuscript-gloss-v1

AI-generated hero image for `dev_docs/design.qmd` (figure type F15, metaphor collage). Not data.

- **Final:** `openai/gpt-image-2.6-sunburst` · quality `high` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** draft 1 of the step below, role "layout reference" (draft deleted after selection)
- **Draft step:** `openai/gpt-image-2.6-flare` · quality `low` · size `1824x1024` · n 2. Draft 1 chosen: all four leader lines ended on red dots and the plot area was cleaner; draft 2 had blurred dots.
- **Post-processing:** `magick hero-manuscript-gloss-v1.png -resize 1600x -quality 86 hero-manuscript-gloss-v1.jpg`; the 1824 px PNG was not kept.
- **Checked:** four vermilion leader lines, each ending on one of exactly four vermilion dots; no readable letters; no logo or watermark; dots crisp.
- **Mapping to the analogy:** the untouched central plot = the figure's geometry; marginal notes in several hands = records added over time by many writers; red leader lines = anchors.

## Prompt (final)

```text
Use case: stylized-concept
Asset type: hero image for a technical design document about a software package that lets people and AI agents attach layered, anchored, verifiable notes to an already-drawn data figure, without ever changing the figure itself
Input images: Image 1: layout reference. Keep its composition: the manuscript page on the right two thirds, plain warm ivory space on the left third, the scatter plot as the central block, marginal glosses on all four sides, four vermilion leader lines.
Primary request: archival collage. A single page of a medieval glossed manuscript on aged vellum, in the classic layout where a central block is surrounded by marginal commentary written by later readers. The central block is a clean modern scatter plot printed in crisp dark ink: two thin axes with small tick marks, about forty small, perfectly round, sharp-edged dots following a gentle downward trend; no smudges, no blurred or half-printed dots. The scatter plot is untouched and perfectly crisp. Around it, in all four margins, dense handwritten marginal glosses in brown iron-gall ink, in several different hands and line heights as if added by many readers over centuries, written as illegible script-like marks; a few short interlinear notes sit just below the x axis. Exactly four of the marginal notes connect to four individual dots with fine, straight vermilion-red ink leader lines; each red leader line starts at the end of a marginal note and ends exactly on the centre of one dot; those four dots are vermilion red, all other dots are dark ink.
Style/medium: flat, high-resolution scan of a real archival object combined with one precise modern graphic element; museum-catalogue photography, no perspective distortion; subtle vellum texture, gentle wear at the page edges
Composition/framing: landscape 16:9; the page fills the right two thirds of the frame, very slightly rotated; the left third is a plain warm ivory background (#F0EEE6) for breathing room
Color palette: parchment, sepia and brown ink, warm ivory background (#F0EEE6), a single accent color vermilion red (#C8553D); nothing else saturated
Constraints: no readable words or letters anywhere, no title, no logos, no watermark; every red leader line ends exactly on a red dot; exactly four red dots
Avoid: fantasy styling, glowing effects, 3D rendering, extra objects, illuminated gold initials, ink blots inside the plot area
```

## Prompt (draft)

Same as the final prompt without the `Input images` line, with "about forty small round dots following a gentle downward trend" and without the dot-sharpness and ink-blot constraints.
