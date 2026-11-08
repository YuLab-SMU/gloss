# fig-log-v1

AI-generated schematic for `dev_docs/design.qmd`, 语义是锚定在元素上、只追加的记录 → 记录、层与日志 (figure type F6, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0061. Every string was re-read on the quantized file.
- **Checked on the published `fig-log-v1.png`:**
  - the strings, character by character: the title, "claim.jsonl", "新增" exactly twice (rows 1 and 3), "被取代，仍在日志里", "修订：取代旧记录", "撤回", "核验：附上结果", "日志只追加，旧记录不擦除";
  - a curved arrow runs from the revision row (row 4) up to the superseded row (row 2);
  - the verification pill is green with ✓; a dashed empty row at the bottom marks the next append;
  - no logo or watermark.
- **Mapping to the text:**
  - rows = entries of one layer's JSONL log, oldest first;
  - the four kinds of change (add, revise, withdraw, verify) are all appended; a superseded entry stays in the log.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus one file name; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, header bands, pill-shaped chips, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "修改只有四种，全部是追加"
Subject:
- Center-left: one tall rounded card drawn like a log file. Header band (#F4F2EC) with monospace text: "claim.jsonl". Body: six horizontal entry rows stacked from top to bottom, each a thin rounded strip with a short grey placeholder line and a small colored tag at its left. Rows from top: row 1 orange-red tag "新增"; row 2 is faded grey with its tag in grey: "被取代，仍在日志里"; row 3 orange-red tag "新增"; row 4 orange-red tag "修订：取代旧记录", with a thin curved grey arrow from row 4 back up to row 2; row 5 grey tag "撤回"; row 6 green tag (#3B8C5A) with a ✓: "核验：附上结果". Below row 6, an empty dashed strip with a small downward arrow, showing where the next entry is appended.
- Right side, beside the card, one line of dark text with a thin grey bracket spanning the whole log: "日志只追加，旧记录不擦除".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; the log card centered slightly left, the bracket label on the right
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; orange-red #C8553D for new and revised records; green #3B8C5A for the verification
Text (verbatim): "修改只有四种，全部是追加", "claim.jsonl", "新增" (exactly twice, rows 1 and 3), "被取代，仍在日志里", "修订：取代旧记录", "撤回", "核验：附上结果", "日志只追加，旧记录不擦除". Nothing else.
Constraints: exactly these characters and punctuation; the only other symbol is one ✓; no additional text, icons, logos or watermark
```
