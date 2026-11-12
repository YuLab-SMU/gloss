# NIST 铝合金实验：gloss 使用体验示例的数据依据

本目录支持一张可复现的材料科学图和一张 gloss 目标界面概念图。它不属于 gloss 的开发/留出基准集，不是新实验，也不用于评估模型效果。

## 来源与选择

- 数据集：[Dynamic compressive stress-strain curves of aluminum alloy 6061-T6 with rapid heating](https://data.nist.gov/od/id/mds2-3090)，NIST，标识符 `ark:/88434/mds2-3090`，下载日期 2026-11-12。
- [元数据目录](https://catalog.data.gov/dataset/dynamic-compressive-stress-strain-curves-of-aluminum-alloy-6061-t6-with-rapid-heating-cbe3e)列出资源、方法论文与 [NIST 使用条款](https://www.nist.gov/open/license)。
- [原始压缩包](https://data.nist.gov/od/ds/mds2-3090/Datafiles_aluminum_6061T6.zip)包含实验文件。本地只保留 `4655_analyzed_w_unc.csv`、`4886_analyzed_w_unc.csv`、`5327_analyzed_w_unc.csv`，字节不变。
- `Datafile_master_list_6061T6.csv` 和 `README_6061_Data_Pub.txt` 原样来自同一数据目录；前者含初始温度、平均应变率和加热时间。CSV 的编码/换行保留原样。
- 选择 23、305、499°C 三次实验是为了说明一张图上的对象、关系和比较，非代表性统计抽样。每条曲线是单次试验，不能把三个温度当作控制其他条件后的因果比较。
- 原始 README 的概括范围与逐试验元数据并不完全一致。本例条件取自 master CSV 的具体行；不把概括性的应变率范围套到这些实验上。

## 处理与数值

从项目根目录运行：

```sh
Rscript dev_docs/figures/design/src/gloss-aluminium-example.R
```

依赖本地已安装的 ggplot2、patchwork、ragg、svglite，以及用于中文排版的 PingFang SC 字体。

脚本读取全部 791 条观测（259 / 282 / 250），不平滑、不删减曲线。图 (a) 的阴影为 CSV 中 `Unc True Stress [MPa]` 字段的正负范围；不解释成重复样本的分布或 95% 置信区间。图 (b) 在各自真实应变区间内对 ε = 0.10 线性插值，无外推。

| 实验 | 初始温度（°C） | 平均应变率（s⁻¹） | 加热时间（s） | ε=0.10 应力（MPa） | 图中舍入值 |
|---|---:|---:|---:|---:|---:|
| 4655 | 23 | 2400 | 不适用 | 370.88435 | 371 |
| 4886 | 305 | 2900 | 1 | 251.83272 | 252 |
| 5327 | 499 | 3100 | 3.5 | 79.16936 | 79 |

`section-at-strain-0.10.csv` 保存未舍入的截面值。界面选中试验 4886 的数据行 91，其原始 ε=0.100148、σ=252.207 MPa，记录在 `selected-row-4886-91.csv`；“数据行”不含文件开头的元数据和列名。原始观测与 ε=0.10 的插值不是同一点，界面按约数显示时均约为 252 MPa。

检验的声明仅为“这三次选定实验，在 ε=0.10 处有 371 > 252 > 79 MPa 的数值顺序”。没有进行显著性检验，没有推出普遍温度效应或材料机理。示例批注“应变率也不同，先别归因于温度”是为界面设计的审阅内容，不归于原研究作者。

## 原始文件校验值

| 文件 | SHA-256 |
|---|---|
| `4655_analyzed_w_unc.csv` | `a8b2c24d9b1ed39ed10d17518fa626a052b3239442590b8842593e1d8867a695` |
| `4886_analyzed_w_unc.csv` | `af4e59fad72d571977db9b6991521097bef5870ab4fa74eb1227984a267a0125` |
| `5327_analyzed_w_unc.csv` | `316da0abd6f555ca8b29fc412479b71439c168c159ce4efd8ff051bbdef169a9` |

## 两类产物

- `gloss-aluminium-original-v1.png` 和 `.svg`：由上述 R 脚本直接生成的科学图，包含原始曲线与计算结果。
- `gloss-aluminium-before-after-v1.png`：以上述科学图为参考的 AI 界面概念图，展示目标交互；不是 gloss 当前版本的真实运行截图，也不替代原始科学图。
