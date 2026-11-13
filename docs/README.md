# gloss roadmap wireframe

这是把路线图信息拆成网页结构后的交互原型。页面不使用参考图片作为素材，内容由 HTML、CSS、内联 SVG 和原生 JavaScript 组成。当前优先实现 Explore 工作区。

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
- overview / propose 入口保留为后续工作区提示，当前不伪装成已完成能力。

下一版可以在保留这个信息架构的前提下，替换为正式视觉系统、项目数据驱动的状态卡和可展开的证据详情。
