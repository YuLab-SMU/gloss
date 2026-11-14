# gloss semantic workbench

这是 gloss 的六层语义工作台。页面用 HTML、CSS、内联 SVG 和原生 JavaScript，把同一张 Palmer Penguins 图放在“原始底座”和“语义投影”两种读法中，提议、核验、记录历史、叙事投影和协作时间线都在同一屏完成。

## 本地预览

在仓库根目录运行：

```bash
python3 -m http.server 4173 --directory docs
```

然后打开 <http://127.0.0.1:4173>。

## GitHub Pages

在仓库设置中选择 **Pages → Deploy from a branch → `feat/agent-path` → `/docs`**。提交后，`docs/index.html` 就是站点入口；`main` 保持 R 包主线，站点原型和生成资产只在这个分支维护。

## 工作台交互

- 六层语义轨道是主导航：structure、meaning、relation、claim、narrative、behavior；
- “一张图，两个读法”并排显示 12 个 raw substrate 点和 12 个 gloss projection 点；
- 选择表格行、画布粒子或六层效果卡，焦点、检查状态和右侧 inspector 会同步更新；
- 语义提议在当前屏展开，提交后会更新对应的 callout、关系线、证据卡、阅读顺序或协作标记；
- 企鹅图像资产用于语义投影和 Narrative / Accessibility 的物种选择，不作为静态海报背景；
- 颜色只表达状态：蓝色表示当前焦点，绿色表示 verified，琥珀表示待核验，灰色虚线表示待提议或待实现。

## 本地状态

记录存储在页面的本地 append-only store 中；刷新页面会恢复原型初始记录。R 包代码、图形几何和数据表不会被网页直接修改。
