# gloss diagram-design assets

这组图按 [Diagram Design](https://github.com/cathrynlavery/diagram-design) 的 Architecture 和 Steps 规范生成。图形使用该技能的 editorial 视觉约束，同时保留 gloss 现有的状态语义。

## 文件

- `gloss-technical-route.html` 是可直接打开的单文件技术路线图。
- `gloss-technical-route.svg` 和 `gloss-technical-route.png` 是对应的导出版本。
- `gloss-architecture.html` 是可直接打开的单文件架构图。
- `gloss-architecture.svg` 和 `gloss-architecture.png` 是对应的导出版本。
- [`../../technical-route-and-architecture.md`](../../technical-route-and-architecture.md) 是配套说明，包含代码入口、当前状态和下一片验收口径。

## 校验

```sh
python3 /tmp/diagram-design.JSZwEz/skills/diagram-design/scripts/self_check.py --offline gloss-technical-route.html gloss-architecture.html
python3 /tmp/diagram-design.JSZwEz/skills/diagram-design/scripts/verify_geometry.py gloss-technical-route.html gloss-architecture.html
python3 /tmp/diagram-design.JSZwEz/scripts/verify-steps.py gloss-technical-route.html
```

静态 SVG 已用 `rsvg-convert` 导出并逐张检查。浏览器渲染 lint 需要 Playwright Chromium，当前工作环境没有可用的 Chromium 缓存，因此没有把 `lint-render.py` 的结果写成通过。
