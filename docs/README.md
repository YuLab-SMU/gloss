# gloss roadmap wireframe

这是把路线图信息拆成网页结构后的交互原型。页面不使用参考图片作为素材，内容由 HTML、CSS、内联 SVG 和原生 JavaScript 组成。Overview、Explore 和 Propose 是三个可以互相跳转的工作区。

## 本地预览

在仓库根目录运行：

```bash
python3 -m http.server 4173 --directory docs
```

然后打开 <http://127.0.0.1:4173>。

## GitHub Pages

在仓库设置中选择 **Pages → Deploy from a branch → `main` → `/docs`**。提交后，`docs/index.html` 就是站点入口。

## Explore 交互

- 点击中央画布的粒子，切换选中元素；
- 右侧 inspector 显示 element、leaf、layer、panel、binding 和 status；
- 底部数据表与画布互相定位，支持键盘选择；
- \`hide binding\`、关系模式、搜索和缩放均在本地原型中可用；
- 核验抽屉支持正确行、错误行和无稳定比较三种结果；
- 结构颜色保持克制：蓝色表示当前结构焦点，绿色表示 verified，琥珀表示 ambiguous，红色表示 rejected，灰色虚线表示 unresolved；工具栏和状态均使用内联 SVG 图标；
- Propose 工作区复用同一选中元素，提供上下文卡、结构化表单、verification gate 和 attempt history；\`relation (next)\` 会明确返回 unresolved，不伪装成已完成能力。

## Overview 交互

- Overview 用黑白粒子、关系线和内联 SVG 把 `R 图与数据 → 语义底座 → 结构化语义提议 → 记录与多种呈现` 画成一条可点击的流程；节点会跳进 Explore 或 Propose。
- 页面明确区分底座事实和高层语义：元素 ↔ 数据行只是 substrate，角色与结构、数据与领域含义、关系分组、声明证据、叙事无障碍、交互协作以六层语义堆栈追加，并显示各自的核验边界。
- `M0—M5` 能力地图、当前选中元素卡和 evidence pulse 都来自同一份本地状态；切换元素、提交错误行或高层提议后，Overview 会同步最新核验颜色、原因和尝试次数。
- Overview 内含同屏语义提议工作区：Relation 会核验选中企鹅元素的分组关系，Claim 会对 Palmer Penguins 的分组均值运行确定性检查；两类记录都会回写六层状态和 record history。
- Explore 的示例数据使用 Palmer Penguins 风格的 `species / island / bill / flipper` 字段，避免把产品叙事收窄成通用点位配对。
- Narrative / Accessibility 会记录阅读顺序、关键结论和无障碍描述；Behavior / Collaboration 会记录聚焦、批注、复核、修订、来源和目标。四类记录共用同一个 append-only history。
- Data / Domain Meaning 会把 `species / island / bill / flipper / mass` 映射到物种、采样岛、喙长、鳍长和体重等领域术语，并按单位与范围核验后写入 `M-` 记录。
- 页面支持 `#overview`、`#explore`、`#propose` 深链接，适合直接部署到 GitHub Pages 的静态入口。
