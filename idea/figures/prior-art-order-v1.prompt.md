# prior-art-order-v1

AI-generated schematic for `idea/2026-11-07-semantic-svg-prior-art.md`, §1 ggiraph, "Where it stops" (figure type F3, stylized; not data; English twin of `dev_docs/figures/design/fig-order-vs-group-v1.png`).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-order-vs-group-v1.png`, role "edit target"
- **Rounds:**
  1. v1 was a text-localization edit of `dev_docs/figures/design/fig-order-vs-group-v1.png` (prompt below). Accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0086. Every string was re-read on the quantized file.
- **Checked on the published `prior-art-order-v1.png`:**
  - the four translated strings, letter by letter; no Chinese characters remain;
  - tiles, id tags, ✗, groups and ✓ are unchanged from the Chinese original;
  - no logo or watermark.
- **Mapping to the text:**
  - left = the measured silent misbinding (`"a\nb\nc"` and `"d"`, 4 `text` elements, `rep(each = )` recycling); right = group delimiting.

## Prompt (v1)

```text
Use case: text-localization
Input images: Image 1: edit target.
Primary request: translate the Chinese text into English, replacing these four strings and nothing else:
- the title "按顺序分配 id 会悄悄错位，按组划界不会" → "Assigning ids by order misbinds silently; grouping does not"
- the left card header "按顺序：第 i 个 id 给第 i 个元素" → "By order: the i-th id goes to the i-th element"
- the right card header "按组：设备把元素放进各自的组" → "By group: the device puts each element in its group"
- the red line under the left card's tiles "c 被标成了第二个标签的 id，没有警告" → "c gets the second label's id, with no warning"
Constraints: change only the text; preserve the layout, the letter tiles a, b, c, d in both cards, the id tags "id 1", "id 1", "id 2", "id 2", the red ✗, the dashed blue groups labelled "group 1" and "group 2", the green ✓, typography, colors, spacing and hierarchy. Use a clean sans-serif matching the original weights. No Chinese characters may remain. No extra words.
```
