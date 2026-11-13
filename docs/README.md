# gloss roadmap wireframe

这是把路线图信息拆成网页结构后的第一版低保真线稿。页面不使用参考图片作为素材，内容由 HTML、CSS 和少量原生 JavaScript 组成。

## 本地预览

在仓库根目录运行：

```bash
python3 -m http.server 4173 --directory docs
```

然后打开 <http://127.0.0.1:4173>。

## GitHub Pages

在仓库设置中选择 **Pages → Deploy from a branch → `main` → `/docs`**。提交后，`docs/index.html` 就是站点入口。

## 线稿交互

- 点击技术路径节点，切换右侧说明；
- 点击 M0–M5 卡片，查看里程碑详情；
- 用状态筛选只显示已完成、部分完成或待完成项；
- “看证据”和“回到技术路径”按钮用于页面内导航；
- 路径节点支持键盘方向键，里程碑卡片支持 Enter/Space。

下一版可以在保留这个信息架构的前提下，替换为正式视觉系统、项目数据驱动的状态卡和可展开的证据详情。
