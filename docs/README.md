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

- Overview 用黑白粒子、关系线和内联 SVG 把 `R 图与数据 → 语义底座 → 提交即核验 → 记录与投影` 画成一条可点击的流程；节点会跳进 Explore 或 Propose。
- `M0—M5` 能力地图、当前选中元素卡和 evidence pulse 都来自同一份本地状态；切换元素、提交错误行或 relation 提议后，Overview 会同步最新核验颜色、原因和尝试次数。
- 页面支持 `#overview`、`#explore`、`#propose` 深链接，适合直接部署到 GitHub Pages 的静态入口。
