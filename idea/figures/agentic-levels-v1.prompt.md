# agentic-levels-v1

AI-generated schematic for `idea/2026-11-07-agentic-semantic-svg.md`, Semantic levels (figure type F8, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `idea/figures/prior-art-routes-v4.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0098. Every string was re-read on the quantized file.
- **Checked on the published `agentic-levels-v1.png`:**
  - the six strings, letter by letter, each exactly once;
  - S0 grey; S1 blue; S2 half blue, half orange-red; S3 and S4 orange-red;
  - no logo or watermark.
- **Mapping to the text:**
  - the five rows of the levels table; colour = who produces the level (grey: device, blue: deterministic code, orange-red: agent).

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a research note (stylized, not data)
Input images: Image 1: style anchor from the same project. Match its canvas color, fonts, line weights, greys and blue. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold geometric sans-serif, near-black #1F1E1D): "Five semantic levels, and who produces each"
Subject: five wide horizontal rounded bars stacked vertically like a ladder, the lowest at the bottom, equal size and even spacing. Each bar holds one line of text: a bold level code, then the content, then after a middle dot the producer.
- bottom bar, grey fill (#EEECE5) with grey outline: "S0 geometry · graphics device"
- second bar, light blue fill (#EEF3FA) with blue outline (#4C75AD): "S1 structure · deterministic"
- third bar, split fill: left half light blue with blue outline, right half light warm (#FBF1EC) with orange-red outline (#C8553D): "S2 data binding · deterministic, or agent-proposed and verified"
- fourth bar, light warm fill with orange-red outline: "S3 meaning and relations · agent"
- top bar, light warm fill with orange-red outline: "S4 interaction intent · agent, from a closed vocabulary"
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients except the split fill of the S2 bar
Composition/framing: landscape 16:9; title on top; the five bars centered with wide margins
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF, #EEECE5; blue #4C75AD / #EEF3FA for deterministic; orange-red #C8553D / #FBF1EC for agent
Text (verbatim, exactly these strings and nothing else): "Five semantic levels, and who produces each", "S0 geometry · graphics device", "S1 structure · deterministic", "S2 data binding · deterministic, or agent-proposed and verified", "S3 meaning and relations · agent", "S4 interaction intent · agent, from a closed vocabulary"
Constraints: render every string exactly once, spelled exactly; no additional text, icons, logos or watermark
```
