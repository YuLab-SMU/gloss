# agentic-svg-hero-v1

AI-generated hero image for `idea/2026-11-07-agentic-semantic-svg.md` (figure type F15/F16, metaphor collage). Not data. It is the second image in the series anchored on `dev_docs/figures/design/hero-manuscript-gloss-v1.jpg`.

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `high` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/hero-manuscript-gloss-v1.jpg`, role "style anchor", composition not copied
- **Post-processing:** `magick agentic-svg-hero-v1.png -resize 1600x -quality 86 agentic-svg-hero-v1.jpg`; the PNG was not kept.
- **Checked:**
  - exactly four vermilion glosses, each joined by a vermilion leader line that ends on one of exactly four vermilion dots;
  - three green ticks;
  - one gloss struck through with a single red line;
  - the plot is crisp and its dots are sharp;
  - no readable letters, no logo or watermark.
  
  The leader lines cross the plot area, as in the anchor image.
- **Mapping to the idea:**
  - the untouched central plot = the figure's geometry (the agent never redraws);
  - vermilion glosses = agent-authored semantics;
  - leader lines = anchors to elements;
  - green ticks = claims that passed their checks against the data;
  - the struck-through gloss = a claim the checks rejected.

## Prompt

```text
Use case: style-transfer (series consistency)
Asset type: hero image for a founding idea note about a tool in which an AI agent annotates an already-drawn data figure and every annotation that touches the data is checked; the agent never redraws the figure
Input images: Image 1: style anchor from the same project. Match its medium exactly: a scan of a medieval glossed manuscript page on aged vellum, brown iron-gall ink marginal glosses in several hands, a crisp modern scatter plot printed in dark ink as the central block, vermilion leader lines, warm ivory background. Do not copy its composition.
Primary request: a NEW archival collage in the same style. A single glossed manuscript page, seen flat and straight-on, filling the centre of the frame with warm ivory space on both sides. The central block is a crisp modern scatter plot in dark ink: two thin axes with small tick marks and about thirty small, perfectly round, sharp-edged dots following a gentle downward trend; the plot is untouched and perfectly crisp. In the margins, illegible script-like marginal glosses in brown ink. Exactly four of the glosses are written in vermilion ink (#C8553D), and each of these four connects to one dot with a fine straight vermilion leader line that ends exactly on the centre of that dot; those four dots are vermilion, all other dots are dark ink. Three of the four vermilion glosses have a small, neat green ink tick mark (#3B8C5A) beside them. The fourth vermilion gloss is struck through with one clean horizontal red line (#D65451), as if rejected by a later reader.
Style/medium: flat, high-resolution scan of a real archival object combined with one precise modern graphic element; museum-catalogue photography, no perspective distortion; subtle vellum texture
Composition/framing: landscape 16:9; the page centered, occupying the middle three fifths of the width, very slightly rotated; plain warm ivory background (#F0EEE6) on the left and right
Color palette: parchment, sepia and brown ink, warm ivory background (#F0EEE6), vermilion (#C8553D) for the four glosses and leader lines, a small green (#3B8C5A) for the three ticks, red (#D65451) for the single strike-through line; nothing else saturated
Constraints: no readable words or letters anywhere, no title, no logos, no watermark; exactly four vermilion leader lines, each ending exactly on one of exactly four vermilion dots; exactly three green ticks; exactly one strike-through line; the scatter plot itself is never written over
Avoid: fantasy styling, glowing effects, 3D rendering, extra objects, illuminated gold initials, ink blots inside the plot area, blurred dots
```
