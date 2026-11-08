# fig-masked-v1

AI-generated schematic for `dev_docs/design.qmd`, section 评测设计 → 遮蔽评测 (figure type F3/F8, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08. The first round was accepted.
- **Post-processing:** resized to 1600 px wide and quantized to a 128-colour PNG8, as for `fig-decisive-v1`. The strings were re-checked after quantization.
- **Checked:**
  - the five strings, character by character, each exactly once: "遮蔽评测：藏起确定性层的绑定，让 agent 重新提出", "① 确定性层的绑定", "② 藏起来", "③ agent 提出", "④ 对照藏起的答案";
  - card 1 has five solid blue bindings, one per row;
  - card 2 has faint dashed placeholders;
  - in card 3, four orange-red proposals match card 1, and the fourth dot is bound to the second row instead of the fourth;
  - card 4 marks four rows ✓ and the fourth row ✗;
  - no text in the tables, no logo or watermark.
- **Reading note:** the ✓/✗ marks sit beside table rows, so the ✗ marks the row whose binding the agent got wrong.

## Prompt

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus the Latin word "agent"; render the characters exactly.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "遮蔽评测：藏起确定性层的绑定，让 agent 重新提出"
Subject: four equal small rounded cards in one row, left to right, connected by thin grey arrows (#87867F). Each card: white body (#FDFCF9), thin grey border (#C8C7BF). Inside every card the same miniature: on the left, five small dark grey dots scattered loosely; on the right, a small table drawn as five stacked grey horizontal bars (#C8C7BF) with no text. Below each card, its caption in dark sans-serif (#3D3D3A).
- Card 1: five solid blue lines (#4C75AD) connect each dot to a different table row. Caption: "① 确定性层的绑定"
- Card 2: the lines are gone; instead five very faint grey dashed lines mark where they were. Caption: "② 藏起来"
- Card 3: five dotted orange-red lines (#C8553D) connect each dot to a row; four of them go to the same rows as in card 1, one goes to a different row. Caption: "③ agent 提出"
- Card 4: the same five dotted orange-red lines; next to the four that match card 1, a small green tick ✓ (#3B8C5A); next to the one that does not match, a small red cross ✗ (#D65451). Caption: "④ 对照藏起的答案"
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; the four cards in one row across the middle with equal gaps; captions centered under each card
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD for deterministic bindings; orange-red #C8553D for agent proposals; green #3B8C5A ticks; red #D65451 cross; nothing else saturated
Text (verbatim, exactly these strings and nothing else): "遮蔽评测：藏起确定性层的绑定，让 agent 重新提出", "① 确定性层的绑定", "② 藏起来", "③ agent 提出", "④ 对照藏起的答案"
Constraints: render every string exactly once with exactly these characters and punctuation; the only other symbols are four ✓ and one ✗ in card 4; no numbers or text in the tables; no additional text, icons, logos or watermark
```
