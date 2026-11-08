# fig-verify-loop-v1

AI-generated schematic for `dev_docs/design.qmd`, 每条可计算的声明都带一条检查 → 底座每变一次，核验就重跑一次 (figure type F8, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0082. Every string was re-read on the quantized file.
- **Checked on the published `fig-verify-loop-v1.png`:**
  - the nine strings, character by character, each exactly once;
  - the proposal (orange-red) enters one blue box holding the three checks in order;
  - a green arrow with ✓ goes to the log; a red arrow with ✗ goes to the rejection line;
  - a grey curved arrow labelled "全部重跑" runs from the substrate-change box back to the checks;
  - no logo or watermark.
- **Mapping to the text:**
  - the three checks = schema validation, anchor resolution, claim verification;
  - the red line = the one hard constraint (principle 8);
  - the loop = re-running every check after re-capture, re-keying or new data.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus the Latin word "schema"; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, pill-shaped chips, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "每次写入都过三道检查，底座一变就全部重跑"
Subject:
- Left: a small rounded card with an orange-red outline (#C8553D), text in orange-red: "提议". A grey arrow runs right into a gate.
- Center: a tall rounded gate panel with a blue outline (#4C75AD) and light blue fill (#EEF3FA), containing three stacked blue chips, top to bottom: "schema 校验", "锚点解析", "声明核验".
- Right of the gate, upper path: a green arrow to a rounded card with green outline and green text (#3B8C5A) and a ✓: "追加进层日志".
- Right of the gate, lower path: a red arrow to a rounded card with red outline and red text (#D65451) and a ✗: "没通过的声明不能作为事实投影".
- Below the gate: a grey rounded card: "底座变化：重新捕获 · 改键 · 换数据". From it, a curved grey loop arrow goes back up into the gate, labelled next to the arrow in grey: "全部重跑".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; the flow runs left to right through the middle, the loop below the gate
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #EEF3FA for the checks; orange-red #C8553D for the proposal; green #3B8C5A; red #D65451
Text (verbatim, exactly these strings and nothing else): "每次写入都过三道检查，底座一变就全部重跑", "提议", "schema 校验", "锚点解析", "声明核验", "追加进层日志", "没通过的声明不能作为事实投影", "底座变化：重新捕获 · 改键 · 换数据", "全部重跑"
Constraints: render every string exactly once with exactly these characters and punctuation; the only other symbols are one ✓ and one ✗; no additional text, icons, logos or watermark
```
