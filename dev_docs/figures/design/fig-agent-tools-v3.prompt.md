# fig-agent-tools-v3

AI-generated schematic for `dev_docs/design.qmd`, agent 只是底座的一个客户端 → 工具：除了 propose，全部只读 (figure type F2, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the first prompt below. All ten strings were exact, but a small grey × sat where the `propose` arrow crosses the dashed boundary, which read as "propose is blocked".
  2. v2 was a precise edit of v1 asking to remove that mark (second prompt below). The × was still there. Two rounds had failed on the same mark, so the fix was made deterministically.
  3. v3 = v2 plus a PIL fix: the box `[1186, 438, 1230, 482]` was painted with the sampled canvas colour `(241, 238, 230)`, and the arrow line was redrawn through it as `[1184, 458, 1232, 461]` in the sampled arrow colour `(216, 80, 37)`. This leaves a clean gap in the dashed boundary. Drafts v1 and v2 were deleted.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0064. Every string was re-read on the quantized file.
- **Checked on the published `fig-agent-tools-v3.png`:**
  - the ten strings on v3, character by character, each exactly once;
  - the `propose` arrow passes through a gap in the dashed boundary with no mark on it;
  - the red dashed error-list arrow returns from 校验 to the agent;
  - three red chips with ✗ hang below the boundary;
  - no logo or watermark.
- **Mapping to the text:**
  - dashed boundary = what the agent can reach; blue chip = the read-only tools in `tbl-tools`;
  - `propose` → 校验 → 层日志 = the only write path; the three ✗ chips = what the agent cannot do.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus a few Latin words; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, pill-shaped chips, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "agent 只有只读工具和一个提交即校验的写入口"
Subject:
- Center: a large rounded rectangle with a dashed grey outline (#87867F) marking the agent's boundary. Inside it, near the middle, a rounded card with an orange-red outline (#C8553D) and orange-red bold text: "agent".
- Left side, inside the boundary: a light blue chip (#EEF3FA fill, #4C75AD outline and text): "只读工具：查底座和各层". A thin blue arrow points from this chip toward the agent card (information flows in only).
- Right side: from the agent card, an orange-red arrow passes through a narrow opening in the dashed boundary, labelled at the opening in orange-red monospace: "propose". Just outside, a blue gate chip: "校验". After the gate, a green arrow (#3B8C5A) with ✓ to a grey card: "层日志". A thin red dashed arrow (#D65451) returns from the gate back to the agent, labelled in red: "错误清单".
- Below the boundary, three small red crossed-out chips in a row, each with a ✗ and red text (#D65451): "写 SVG", "执行代码", "绕过核验". Each has a short red line ending at the dashed boundary, showing the agent cannot reach them.
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; the boundary in the middle; gate and log on the right; the three forbidden actions along the bottom
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #EEF3FA; orange-red #C8553D; green #3B8C5A; red #D65451
Text (verbatim, exactly these strings and nothing else): "agent 只有只读工具和一个提交即校验的写入口", "agent", "只读工具：查底座和各层", "propose", "校验", "层日志", "错误清单", "写 SVG", "执行代码", "绕过核验"
Constraints: render every string exactly once with exactly these characters and punctuation; the only other symbols are one ✓ and three ✗; no robots, faces or extra icons; no additional text, logos or watermark
```

## Prompt (v2, edit; reference image `dev_docs/figures/design/fig-agent-tools-v1.png`, role "edit target")

```text
Use case: precise-object-edit
Input images: Image 1: edit target.
Primary request: change only one thing. Where the orange-red "propose" arrow crosses the dashed grey boundary on the right, there is a small grey × mark, and there is a second small stray grey tick mark lower down on the same boundary where the red dashed "错误清单" line crosses it. Remove both stray marks and leave a clean small gap in the dashed boundary where each arrow passes through, so both arrows pass through openings unobstructed.
Constraints: keep everything else exactly unchanged: the title, the dashed boundary, the blue chip, the agent card, the orange-red propose arrow and its label, the blue gate chip, the green ✓ arrow and the log card, the red dashed return arrow and its label, the three red chips with ✗ at the bottom and their red lines, all fonts, colors and spacing. Text that must remain, exactly once each: "agent 只有只读工具和一个提交即校验的写入口", "只读工具：查底座和各层", "agent", "propose", "校验", "层日志", "错误清单", "写 SVG", "执行代码", "绕过核验". No additional text, icons, logos or watermark.
```
