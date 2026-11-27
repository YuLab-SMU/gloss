import { useEffect, useState } from 'react';
import {
  ArrowRight,
  ArrowUpRight,
  Box,
  Check,
  CheckCircle2,
  Copy,
  Cpu,
  FileJson2,
  GitBranch,
  Layers,
  Map as MapIcon,
  ShieldCheck,
  Terminal,
} from 'lucide-react';
import {
  CONTRACT_LAYERS,
  ECOSYSTEM_CONSUMERS,
  ENGINE_COVERAGE,
  PROJECT_LIVE_STATUS,
  PUBLIC_APIS,
} from './data/glossModel';

interface LiveStatusJson {
  package_version?: string;
  generated_at?: string;
  git?: {
    sha?: string;
    branch?: string;
  };
  summary?: {
    exports_implemented?: number;
    exports_total?: number;
    engines_implemented?: number;
    engines_total?: number;
    guardrails_passed?: number;
    guardrails_total?: number;
    r_files?: number;
    r_loc?: number;
    tests?: {
      ran?: boolean;
      passed?: number;
      failed?: number;
      skipped?: number;
    };
  };
}

const REPO_URL = 'https://github.com/YuLab-SMU/gloss';

const R_QUICKSTART = `library(gloss)
library(ggplot2)

p <- ggplot(df, aes(PC1, PC2, colour = group)) +
  geom_point(size = 3) +
  theme_classic()

# 单次绘制捕获：original.svg + 可寻址 scene.svg + 144dpi preview.png + Engine IR
cap <- gloss(p, sources = list(code = "plot_pca.R", docs = "methods.md"))

# 零重绘输出开放资产（几十 KB 目录 + 自包含只读 .gloss/ 资产包）
map <- gl_asset_map(cap)
gl_asset_bundle(cap, "figure.gloss", table_format = "csv") # 大表可选 "parquet"`;

const CLI_QUICKSTART = `# 1. 像素选区 <-> 原始样本行双向反查（兼容 >10^4 光栅密集层）
python3 skills/gloss/scripts/focus_bridge.py box-to-rows \\
  --bundle figure.gloss --box 180,40,260,110 --out figure.gloss.work/focus.json

# 2. 声明式视觉补丁精修（自动校验 edit_policy 锁 + 项级图例同步 + 零位移验真）
python3 skills/gloss-svg-refine/scripts/apply_visual_patch.py \\
  --bundle figure.gloss --patch figure.gloss.work/patches/pub-v1.json \\
  --out figure.gloss.work/derived/figure-pub.svg

# 3. 投稿前审稿级统计对账（自动揪出 NA / limits 静默丢行行号）
python3 skills/gloss-audit/scripts/audit_bundle.py \\
  --bundle figure.gloss --claims claims.json --emit-threads figure.gloss.work/threads.json`;

function IsometricPreviewIllustration() {
  return (
    <svg
      viewBox="0 0 420 190"
      className="h-44 w-full rounded-lg border border-[#1D2B22]/10 bg-[#F4EFE5]"
      role="img"
      aria-label="gloss 3D 六层爆炸图与开放资产流示意图"
    >
      <defs>
        <pattern
          id="iso-grid"
          width="20"
          height="20"
          patternUnits="userSpaceOnUse"
        >
          <path
            d="M 20 0 L 0 0 0 20"
            fill="none"
            stroke="#2D603E"
            strokeOpacity="0.08"
            strokeWidth="1"
          />
        </pattern>
      </defs>
      <rect width="420" height="190" fill="url(#iso-grid)" />

      {/* 6 Stacked Isometric Architectural Sheets */}
      {[
        { dy: 0, fill: '#FCF9F3', stroke: '#2D603E', label: '01' },
        { dy: -16, fill: '#FAF7F0', stroke: '#356D4A', label: '02' },
        { dy: -32, fill: '#F8F5EE', stroke: '#467D58', label: '03' },
        { dy: -48, fill: '#F9F6EF', stroke: '#598A67', label: '04' },
        { dy: -64, fill: '#FCF8F2', stroke: '#DF6A2B', label: '05' },
        { dy: -80, fill: '#FFFFFF', stroke: '#234F33', label: '06' },
      ].map((s, idx) => {
        const y = 148 + s.dy;
        return (
          <g key={s.label}>
            <polygon
              points={`48,${y} 174,${y - 26} 266,${y - 2} 140,${y + 24}`}
              fill={s.fill}
              fillOpacity={idx === 0 || idx === 5 ? 0.96 : 0.82}
              stroke={s.stroke}
              strokeWidth={idx === 5 ? 1.8 : 1.2}
              strokeOpacity={idx === 5 ? 0.85 : 0.55}
            />
            <text
              x="28"
              y={y + 3}
              fontSize="9"
              fontFamily="JetBrains Mono, monospace"
              fontWeight="700"
              fill={s.stroke}
            >
              {s.label}
            </text>
          </g>
        );
      })}

      {/* Vertical lineage threads */}
      <line
        x1="138"
        y1="146"
        x2="138"
        y2="64"
        stroke="#2F855A"
        strokeWidth="1.6"
        strokeDasharray="3 2"
      />
      <line
        x1="186"
        y1="134"
        x2="186"
        y2="56"
        stroke="#DF6A2B"
        strokeWidth="1.8"
      />
      <circle cx="138" cy="64" r="3.5" fill="#2F855A" />
      <circle cx="186" cy="56" r="4" fill="#DF6A2B" />
      <circle cx="186" cy="134" r="3" fill="#DF6A2B" />

      {/* Right-wing 3 output cards */}
      <path
        d="M 244 74 C 274 70, 282 44, 304 42"
        fill="none"
        stroke="#DF6A2B"
        strokeWidth="1.5"
      />
      <path
        d="M 248 106 C 276 104, 282 96, 304 96"
        fill="none"
        stroke="#2D603E"
        strokeWidth="1.5"
      />
      <path
        d="M 352 118 L 352 132"
        fill="none"
        stroke="#315C6B"
        strokeWidth="1.5"
      />
      <path
        d="M 304 152 C 266 164, 212 172, 166 158"
        fill="none"
        stroke="#315C6B"
        strokeWidth="1.3"
        strokeDasharray="4 3"
      />

      <g transform="translate(304, 22)">
        <rect
          width="96"
          height="38"
          rx="6"
          fill="#FCF9F3"
          stroke="#DF6A2B"
          strokeWidth="1.4"
        />
        <rect width="96" height="10" rx="4" fill="#DF6A2B" />
        <text
          x="8"
          y="23"
          fontSize="8.5"
          fontFamily="JetBrains Mono, monospace"
          fontWeight="700"
          fill="#1D2B22"
        >
          asset-map.json
        </text>
        <text x="8" y="33" fontSize="7.5" fill="#5B6A60">
          v1.1 · ≈24 KB
        </text>
      </g>

      <g transform="translate(304, 78)">
        <rect
          width="96"
          height="38"
          rx="6"
          fill="#FCF9F3"
          stroke="#2D603E"
          strokeWidth="1.4"
        />
        <rect width="96" height="10" rx="4" fill="#2D603E" />
        <text
          x="8"
          y="23"
          fontSize="8.5"
          fontFamily="JetBrains Mono, monospace"
          fontWeight="700"
          fill="#1D2B22"
        >
          figure.gloss/
        </text>
        <text x="8" y="33" fontSize="7.5" fill="#5B6A60">
          只读不可变源包
        </text>
      </g>

      <g transform="translate(304, 134)">
        <rect
          width="96"
          height="38"
          rx="6"
          fill="#FCF9F3"
          stroke="#315C6B"
          strokeWidth="1.4"
        />
        <rect width="96" height="10" rx="4" fill="#315C6B" />
        <text
          x="8"
          y="23"
          fontSize="8.5"
          fontFamily="JetBrains Mono, monospace"
          fontWeight="700"
          fill="#1D2B22"
        >
          .gloss.work/
        </text>
        <text x="8" y="33" fontSize="7.5" fill="#5B6A60">
          Track A/B 协作态
        </text>
      </g>
    </svg>
  );
}

function LikeC4PreviewIllustration() {
  return (
    <svg
      viewBox="0 0 420 190"
      className="h-44 w-full rounded-lg border border-[#1D2B22]/10 bg-[#EFF5F1]"
      role="img"
      aria-label="gloss LikeC4 实时代码-意图架构地图示意图"
    >
      <defs>
        <pattern
          id="c4-grid"
          width="20"
          height="20"
          patternUnits="userSpaceOnUse"
        >
          <circle cx="2" cy="2" r="1" fill="#2D603E" fillOpacity="0.14" />
        </pattern>
      </defs>
      <rect width="420" height="190" fill="url(#c4-grid)" />

      {/* Container 1: R Core */}
      <rect
        x="18"
        y="22"
        width="148"
        height="146"
        rx="8"
        fill="#FCF9F3"
        stroke="#2D603E"
        strokeWidth="1.5"
        strokeDasharray="4 3"
      />
      <text
        x="28"
        y="38"
        fontSize="8.5"
        fontFamily="JetBrains Mono, monospace"
        fontWeight="700"
        fill="#2D603E"
      >
        gloss R Core (14 files)
      </text>

      {[
        { y: 48, title: '8 Public APIs', meta: 'NAMESPACE 8/8' },
        { y: 86, title: '5 Built-in Engines', meta: 'Suggests isolated' },
        { y: 124, title: 'IR & Lineage v1.1', meta: '839 PASS' },
      ].map((n) => (
        <g key={n.title} transform={`translate(28, ${n.y})`}>
          <rect
            width="128"
            height="30"
            rx="5"
            fill="#E8F3EC"
            stroke="#2F855A"
            strokeWidth="1.1"
          />
          <circle cx="116" cy="10" r="3.2" fill="#2F855A" />
          <text
            x="8"
            y="13"
            fontSize="8.5"
            fontWeight="700"
            fill="#1D2B22"
          >
            {n.title}
          </text>
          <text
            x="8"
            y="24"
            fontSize="7.5"
            fontFamily="JetBrains Mono, monospace"
            fill="#3A5946"
          >
            {n.meta}
          </text>
        </g>
      ))}

      {/* Arrows to Open Assets */}
      <path
        d="M 166 76 L 194 76"
        stroke="#2D603E"
        strokeWidth="1.6"
        markerEnd="none"
      />
      <polygon points="196,76 190,72 190,80" fill="#2D603E" />
      <path d="M 166 124 L 194 124" stroke="#DF6A2B" strokeWidth="1.6" />
      <polygon points="196,124 190,120 190,128" fill="#DF6A2B" />

      {/* Container 2: Open Contract */}
      <g transform="translate(198, 48)">
        <rect
          width="88"
          height="98"
          rx="8"
          fill="#FBF4EC"
          stroke="#DF6A2B"
          strokeWidth="1.4"
        />
        <text
          x="8"
          y="16"
          fontSize="8"
          fontFamily="JetBrains Mono, monospace"
          fontWeight="700"
          fill="#B9501B"
        >
          Open Assets
        </text>
        <rect
          x="8"
          y="25"
          width="72"
          height="28"
          rx="4"
          fill="#FCF9F3"
          stroke="#DF6A2B"
          strokeOpacity="0.45"
        />
        <text
          x="13"
          y="42"
          fontSize="8"
          fontFamily="JetBrains Mono, monospace"
          fontWeight="700"
          fill="#1D2B22"
        >
          Asset Map
        </text>
        <rect
          x="8"
          y="60"
          width="72"
          height="28"
          rx="4"
          fill="#FCF9F3"
          stroke="#2D603E"
          strokeOpacity="0.45"
        />
        <text
          x="13"
          y="77"
          fontSize="8"
          fontFamily="JetBrains Mono, monospace"
          fontWeight="700"
          fill="#1D2B22"
        >
          .gloss/
        </text>
      </g>

      {/* Arrow to Ecosystem */}
      <path d="M 286 96 L 310 96" stroke="#315C6B" strokeWidth="1.6" />
      <polygon points="312,96 306,92 306,100" fill="#315C6B" />

      {/* Container 3: Ecosystem & Guardrails */}
      <g transform="translate(314, 24)">
        <rect
          width="88"
          height="142"
          rx="8"
          fill="#FCF9F3"
          stroke="#315C6B"
          strokeWidth="1.4"
        />
        <text
          x="8"
          y="16"
          fontSize="8"
          fontFamily="JetBrains Mono, monospace"
          fontWeight="700"
          fill="#274B58"
        >
          Ecosystem
        </text>
        {[
          { y: 26, label: '4 Skills', bg: '#E8F3EC', tc: '#1F5432' },
          { y: 54, label: '5 Py CLIs', bg: '#E8F3EC', tc: '#1F5432' },
          { y: 82, label: 'Workbench', bg: '#E8F1F4', tc: '#274B58' },
          { y: 110, label: 'gloss-mcp', bg: '#E8F1F4', tc: '#274B58' },
        ].map((item) => (
          <g key={item.label} transform={`translate(8, ${item.y})`}>
            <rect width="72" height="22" rx="4" fill={item.bg} />
            <text
              x="8"
              y="14"
              fontSize="8"
              fontFamily="JetBrains Mono, monospace"
              fontWeight="700"
              fill={item.tc}
            >
              {item.label}
            </text>
          </g>
        ))}
      </g>
    </svg>
  );
}

export default function PortalHome() {
  const [live, setLive] = useState<LiveStatusJson | null>(null);
  const [snippetTab, setSnippetTab] = useState<'r' | 'cli'>('r');
  const [copiedCode, setCopiedCode] = useState(false);

  // Hydrate live CI status.json on GitHub Pages (falls back gracefully to baked-in v1.1.0 snapshot locally)
  useEffect(() => {
    let active = true;
    fetch('./status.json')
      .then((res) => {
        const ct = res.headers.get('content-type') ?? '';
        return res.ok && ct.includes('json') ? res.json() : null;
      })
      .then((data: LiveStatusJson | null) => {
        if (active && data && data.summary) {
          setLive(data);
        }
      })
      .catch(() => {
        // Local dev without status.json: silently use baked-in defaults
      });
    return () => {
      active = false;
    };
  }, []);

  const rTestsPassed =
    live?.summary?.tests?.passed ?? PROJECT_LIVE_STATUS.rTestsPassed;
  const rTestsFailed =
    live?.summary?.tests?.failed ?? PROJECT_LIVE_STATUS.rTestsFailed;
  const guardrailsPassed =
    live?.summary?.guardrails_passed ?? PROJECT_LIVE_STATUS.guardrails.length;
  const guardrailsTotal =
    live?.summary?.guardrails_total ?? PROJECT_LIVE_STATUS.guardrails.length;
  const rFiles = live?.summary?.r_files ?? PROJECT_LIVE_STATUS.rFiles;
  const rLoc = live?.summary?.r_loc ?? PROJECT_LIVE_STATUS.rLoc;
  const gitCommit = live?.git?.sha
    ? `${live.git.sha} (${live.git.branch ?? 'main'})`
    : PROJECT_LIVE_STATUS.gitCommit;

  const activeSnippet = snippetTab === 'r' ? R_QUICKSTART : CLI_QUICKSTART;

  const handleCopySnippet = () => {
    navigator.clipboard?.writeText(activeSnippet).then(() => {
      setCopiedCode(true);
      window.setTimeout(() => setCopiedCode(false), 1800);
    });
  };

  return (
    <div className="min-h-screen bg-[#F5F0E6] text-[#1D2B22]">
      {/* Sticky Editorial Portal Header */}
      <header className="sticky top-0 z-30 border-b border-[#1D2B22]/10 bg-[#F7F3EA]/95 backdrop-blur-sm">
        <div className="mx-auto flex h-15 max-w-6xl items-center justify-between gap-4 px-5 sm:px-8">
          <div className="flex items-center gap-3">
            <a
              href="./"
              className="flex items-baseline gap-2 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#2D603E]"
            >
              <span className="text-2xl font-extrabold tracking-tight text-[#DF6A2B]">
                gloss
              </span>
              <span className="hidden text-sm font-semibold text-[#1D2B22] sm:inline">
                R 图形编译现场的 Source Map 内核
              </span>
            </a>

            <span className="hidden items-center gap-1.5 rounded-full border border-[#2D603E]/25 bg-[#EDF5EF] px-2.5 py-0.5 text-[11px] font-semibold text-[#234F33] md:inline-flex">
              <span
                className="h-1.5 w-1.5 rounded-full bg-[#2F855A]"
                aria-hidden="true"
              />
              <span className="font-mono-tabular">
                Schema v{PROJECT_LIVE_STATUS.schemaVersion} · {rTestsPassed} PASS
              </span>
            </span>
          </div>

          <nav
            aria-label="站点导航"
            className="flex items-center gap-2 sm:gap-3"
          >
            <a
              href="./3d/"
              className="rounded-lg bg-[#2D603E] px-3 py-1.5 text-xs font-semibold text-[#FCF9F3] transition-colors hover:bg-[#234F33]"
            >
              3D 架构空间
            </a>
            <a
              href="./map/"
              className="rounded-lg border border-[#2D603E]/30 bg-[#FCF9F3] px-3 py-1.5 text-xs font-semibold text-[#2D603E] transition-colors hover:border-[#2D603E] hover:bg-[#EDF5EF]"
            >
              LikeC4 地图
            </a>
            <a
              href={REPO_URL}
              target="_blank"
              rel="noreferrer"
              className="hidden items-center gap-1 rounded-lg border border-[#1D2B22]/14 bg-[#FCF9F3] px-3 py-1.5 text-xs font-semibold text-[#3A4D41] transition-colors hover:border-[#1D2B22]/35 hover:text-[#1D2B22] sm:inline-flex"
            >
              <span>GitHub</span>
              <ArrowUpRight className="h-3.5 w-3.5" aria-hidden="true" />
            </a>
          </nav>
        </div>
      </header>

      {/* Hero + Dual Interactive Portal Cards */}
      <section className="gloss-drafting-grid border-b border-[#1D2B22]/10">
        <div className="mx-auto max-w-6xl px-5 pb-14 pt-12 sm:px-8 sm:pt-16">
          <div className="max-w-3xl">
            <div className="inline-flex flex-wrap items-center gap-2 rounded-full border border-[#DF6A2B]/30 bg-[#FBF4EC] px-3 py-1 text-xs font-semibold text-[#B9501B]">
              <span>Schema v{PROJECT_LIVE_STATUS.schemaVersion} 完整闭环</span>
              <span aria-hidden="true">·</span>
              <span>8 公开 API · 5 大绘图引擎 · 4 Agent Skills</span>
            </div>

            <h1 className="mt-4 text-3xl font-extrabold tracking-tight text-[#1D2B22] sm:text-5xl sm:leading-[1.14]">
              把 R 绘图编译现场，变成
              <span className="text-[#2D603E]">人机共享的开放图资产</span>
            </h1>

            <p className="mt-4 text-base leading-relaxed text-[#3E5045] sm:text-lg">
              <code className="font-mono-tabular font-semibold text-[#DF6A2B]">
                gloss
              </code>{' '}
              在 R 图形设备渲染瞬间单次抓拍，零重绘产出不可变{' '}
              <code className="font-mono-tabular text-sm">original.svg</code>、可寻址{' '}
              <code className="font-mono-tabular text-sm">scene.svg</code>、像素对齐{' '}
              <code className="font-mono-tabular text-sm">preview.png</code>、引擎中间态（Engine IR）与行级双向数据桥，让审稿对账、出版精修与跨语言复现告别“看图猜数”。
            </p>
          </div>

          {/* Primary Dual Portal Cards */}
          <div className="mt-10 grid grid-cols-1 gap-6 lg:grid-cols-2">
            {/* Portal Card 1: 3D Interactive Architecture Space */}
            <article className="group flex flex-col justify-between rounded-2xl border border-[#DF6A2B]/30 bg-[#FCF9F3] p-6 shadow-sm transition-all duration-200 hover:-translate-y-0.5 hover:border-[#DF6A2B] hover:shadow-md">
              <div>
                <div className="flex items-center justify-between gap-2">
                  <div className="inline-flex items-center gap-2 text-xs font-bold text-[#C45720]">
                    <Box className="h-4 w-4" aria-hidden="true" />
                    <span>交互式三维原理演示</span>
                  </div>
                  <span className="font-mono-tabular rounded-full bg-[#FBF4EC] px-2.5 py-0.5 text-[11px] font-semibold text-[#B9501B]">
                    /3d/
                  </span>
                </div>

                <h2 className="mt-2.5 text-2xl font-extrabold text-[#1D2B22]">
                  3D 架构空间（Source Map Space）
                </h2>
                <p className="mt-2 text-sm leading-relaxed text-[#43554A]">
                  通过可抽拉的 6 层二维蓝图纸面与动态三维信息流，直观拆解代码、Engine IR、面板逆变换、编辑权限锁、图层血缘与双轨协作工作态（
                  <code className="font-mono-tabular text-xs">.gloss.work/</code>
                  ）的咬合机制。
                </p>

                <div className="mt-4">
                  <IsometricPreviewIllustration />
                </div>

                <div className="mt-4 flex flex-wrap gap-1.5">
                  {[
                    '6 层爆炸图 / 3×2 平铺',
                    '单点 S19 双向溯源',
                    'Track A/B 双轨演化流',
                    '4 类实战场景与 CLI',
                  ].map((tag) => (
                    <span
                      key={tag}
                      className="rounded-md bg-[#F4EFE5] px-2 py-1 text-[11px] font-semibold text-[#33463A]"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              </div>

              <div className="mt-6 flex items-center justify-between border-t border-[#1D2B22]/10 pt-4">
                <span className="text-xs text-[#5B6A60]">
                  适合快速理解核心原理与 Schema v1.1 契约
                </span>
                <a
                  href="./3d/"
                  className="inline-flex shrink-0 items-center gap-1.5 rounded-lg bg-[#DF6A2B] px-4 py-2 text-xs font-bold text-[#FCF9F3] transition-colors hover:bg-[#C45720]"
                >
                  <span>进入 3D 架构空间</span>
                  <ArrowRight className="h-3.5 w-3.5" aria-hidden="true" />
                </a>
              </div>
            </article>

            {/* Portal Card 2: LikeC4 Live Project Map */}
            <article className="group flex flex-col justify-between rounded-2xl border border-[#2D603E]/28 bg-[#FCF9F3] p-6 shadow-sm transition-all duration-200 hover:-translate-y-0.5 hover:border-[#2D603E] hover:shadow-md">
              <div>
                <div className="flex items-center justify-between gap-2">
                  <div className="inline-flex items-center gap-2 text-xs font-bold text-[#2D603E]">
                    <MapIcon className="h-4 w-4" aria-hidden="true" />
                    <span>代码-意图实时对齐地图</span>
                  </div>
                  <span className="font-mono-tabular rounded-full bg-[#EDF5EF] px-2.5 py-0.5 text-[11px] font-semibold text-[#234F33]">
                    /map/
                  </span>
                </div>

                <h2 className="mt-2.5 text-2xl font-extrabold text-[#1D2B22]">
                  LikeC4 实时工程架构地图
                </h2>
                <p className="mt-2 text-sm leading-relaxed text-[#43554A]">
                  每次推送自动运行{' '}
                  <code className="font-mono-tabular text-xs">
                    project-map/build_map.R
                  </code>{' '}
                  扫描 <code className="font-mono-tabular text-xs">DESCRIPTION</code>、
                  <code className="font-mono-tabular text-xs">NAMESPACE</code> 与全量单测，生成可钻取的 C4 系统组件图、源码直链与架构护栏状态。
                </p>

                <div className="mt-4">
                  <LikeC4PreviewIllustration />
                </div>

                <div className="mt-4 flex flex-wrap gap-1.5">
                  {[
                    'C4 系统/容器/模块视图',
                    '源码与 testthat 直链',
                    '5 项护栏自动探针',
                    '导出 status.json',
                  ].map((tag) => (
                    <span
                      key={tag}
                      className="rounded-md bg-[#EDF5EF] px-2 py-1 text-[11px] font-semibold text-[#234F33]"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              </div>

              <div className="mt-6 flex items-center justify-between border-t border-[#1D2B22]/10 pt-4">
                <span className="text-xs text-[#5B6A60]">
                  适合开发者巡检模块边界、测试与实现状态
                </span>
                <a
                  href="./map/"
                  className="inline-flex shrink-0 items-center gap-1.5 rounded-lg bg-[#2D603E] px-4 py-2 text-xs font-bold text-[#FCF9F3] transition-colors hover:bg-[#234F33]"
                >
                  <span>进入 LikeC4 地图</span>
                  <ArrowRight className="h-3.5 w-3.5" aria-hidden="true" />
                </a>
              </div>
            </article>
          </div>
        </div>
      </section>

      {/* Live Engineering Verification Strip */}
      <section className="border-b border-[#1D2B22]/10 bg-[#FCF9F3]">
        <div className="mx-auto max-w-6xl px-5 py-8 sm:px-8">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="flex items-center gap-2 text-xs font-bold text-[#2D603E]">
              <ShieldCheck className="h-4 w-4" aria-hidden="true" />
              <span>主分支实时验收快照</span>
            </div>
            <div className="flex items-center gap-3 text-xs text-[#5B6A60]">
              <span className="font-mono-tabular inline-flex items-center gap-1">
                <GitBranch className="h-3.5 w-3.5" aria-hidden="true" />
                {gitCommit}
              </span>
              <a
                href="./status.json"
                className="font-mono-tabular inline-flex items-center gap-1 font-semibold text-[#2D603E] hover:underline"
              >
                <FileJson2 className="h-3.5 w-3.5" aria-hidden="true" />
                status.json
              </a>
            </div>
          </div>

          <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
            {[
              {
                value: `v${PROJECT_LIVE_STATUS.schemaVersion}`,
                label: '开放协议 Schema',
                accent: 'text-[#DF6A2B]',
              },
              {
                value: `${rTestsPassed} PASS`,
                label: `R testthat (${rTestsFailed} FAIL)`,
                accent: 'text-[#2D603E]',
              },
              {
                value: `${PROJECT_LIVE_STATUS.pyWorkflowsPassed}/${PROJECT_LIVE_STATUS.pyWorkflowsTotal}`,
                label: '跨语言 Python 工作流',
                accent: 'text-[#2D603E]',
              },
              {
                value: `${guardrailsPassed}/${guardrailsTotal}`,
                label: '架构护栏全通过',
                accent: 'text-[#2D603E]',
              },
              {
                value: `${PROJECT_LIVE_STATUS.issuesClosed}/${PROJECT_LIVE_STATUS.issuesTotal}`,
                label: '最后一公里断层闭环',
                accent: 'text-[#315C6B]',
              },
              {
                value: `${rFiles} 文件`,
                label: `${rLoc.toLocaleString()} LOC · 8 API`,
                accent: 'text-[#1D2B22]',
              },
            ].map((kpi) => (
              <div
                key={kpi.label}
                className="rounded-xl border border-[#1D2B22]/10 bg-[#F7F3EA]/80 px-3.5 py-3"
              >
                <div
                  className={`font-mono-tabular text-lg font-extrabold ${kpi.accent}`}
                >
                  {kpi.value}
                </div>
                <div className="mt-0.5 text-[11px] font-medium text-[#4B5B50]">
                  {kpi.label}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Main Content Body: 4-Layer Contract, Quickstart, APIs & Ecosystem */}
      <main className="mx-auto max-w-6xl space-y-14 px-5 py-12 sm:px-8">
        {/* 4-Layer Open Asset Contract Overview */}
        <section>
          <div className="flex flex-wrap items-end justify-between gap-3">
            <div>
              <div className="inline-flex items-center gap-1.5 text-xs font-bold text-[#2D603E]">
                <Layers className="h-4 w-4" aria-hidden="true" />
                <span>File-First · 零私有编码</span>
              </div>
              <h2 className="mt-1 text-2xl font-extrabold text-[#1D2B22]">
                Schema v1.1.0 四层开放契约与旁侧协作态
              </h2>
            </div>
            <a
              href="./3d/"
              className="inline-flex items-center gap-1 text-xs font-bold text-[#DF6A2B] hover:underline"
            >
              <span>在 3D 空间交互探索各层字段</span>
              <ArrowRight className="h-3.5 w-3.5" aria-hidden="true" />
            </a>
          </div>

          <div className="mt-5 grid grid-cols-1 gap-4 md:grid-cols-2">
            {CONTRACT_LAYERS.map((layer) => (
              <div
                key={layer.id}
                className="rounded-xl border border-[#1D2B22]/12 bg-[#FCF9F3] p-5"
              >
                <div className="flex items-baseline justify-between gap-2">
                  <h3 className="text-base font-bold text-[#1D2B22]">
                    0{layer.index}. {layer.title}
                  </h3>
                  <span
                    className="font-mono-tabular text-xs font-bold"
                    style={{ color: layer.accentHex }}
                  >
                    层 {layer.index}/4
                  </span>
                </div>
                <div className="font-mono-tabular mt-1 text-xs text-[#2D603E]">
                  {layer.filesSummary}
                </div>
                <p className="mt-2 text-xs leading-relaxed text-[#43554A]">
                  {layer.positioning}
                </p>
                <div className="mt-3 flex flex-wrap gap-1.5 border-t border-[#1D2B22]/8 pt-3">
                  {layer.components.map((c) => (
                    <code
                      key={c.code}
                      className="font-mono-tabular rounded bg-[#F3EEE3] px-2 py-0.5 text-[10.5px] font-semibold text-[#1D2B22]"
                    >
                      {c.code}
                    </code>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Quickstart Code & Skills CLI */}
        <section className="grid grid-cols-1 gap-6 lg:grid-cols-12">
          <div className="lg:col-span-7">
            <div className="flex items-center justify-between gap-2">
              <div className="inline-flex items-center gap-1.5 text-xs font-bold text-[#2D603E]">
                <Terminal className="h-4 w-4" aria-hidden="true" />
                <span>端到端快速上手</span>
              </div>
              <div className="flex items-center gap-1 rounded-lg bg-[#E9E2D4] p-1">
                <button
                  type="button"
                  onClick={() => setSnippetTab('r')}
                  className={`rounded-md px-2.5 py-1 text-xs font-semibold transition-colors ${
                    snippetTab === 'r'
                      ? 'bg-[#FCF9F3] text-[#1D2B22] shadow-xs'
                      : 'text-[#4B5B50] hover:text-[#1D2B22]'
                  }`}
                >
                  R 编译现场捕获
                </button>
                <button
                  type="button"
                  onClick={() => setSnippetTab('cli')}
                  className={`rounded-md px-2.5 py-1 text-xs font-semibold transition-colors ${
                    snippetTab === 'cli'
                      ? 'bg-[#FCF9F3] text-[#1D2B22] shadow-xs'
                      : 'text-[#4B5B50] hover:text-[#1D2B22]'
                  }`}
                >
                  包外 Agent CLI
                </button>
              </div>
            </div>

            <div className="relative mt-3 rounded-xl border border-[#1D2B22]/14 bg-[#1C2720] p-4 text-[#ECE7DC]">
              <button
                type="button"
                onClick={handleCopySnippet}
                className="absolute right-3 top-3 inline-flex items-center gap-1 rounded-md border border-white/15 bg-white/8 px-2 py-1 text-[11px] font-semibold text-[#ECE7DC] transition-colors hover:bg-white/15"
              >
                {copiedCode ? (
                  <>
                    <Check className="h-3 w-3 text-[#7ED49E]" aria-hidden="true" />
                    <span>已复制</span>
                  </>
                ) : (
                  <>
                    <Copy className="h-3 w-3" aria-hidden="true" />
                    <span>复制</span>
                  </>
                )}
              </button>
              <pre className="font-mono-tabular overflow-x-auto pr-16 text-xs leading-relaxed">
                {activeSnippet}
              </pre>
            </div>
          </div>

          {/* Minimal Surface: 8 Exports + 5 Engines */}
          <div className="lg:col-span-5">
            <div className="inline-flex items-center gap-1.5 text-xs font-bold text-[#DF6A2B]">
              <Cpu className="h-4 w-4" aria-hidden="true" />
              <span>极简内核表面（8 API · 5 引擎）</span>
            </div>

            <div className="mt-3 rounded-xl border border-[#1D2B22]/12 bg-[#FCF9F3] p-4">
              <div className="text-xs font-bold text-[#1D2B22]">
                NAMESPACE 全部导出函数（8 / 8）
              </div>
              <div className="mt-2 flex flex-wrap gap-1.5">
                {PUBLIC_APIS.map((api) => (
                  <code
                    key={api.name}
                    title={api.summary}
                    className="font-mono-tabular rounded border border-[#2D603E]/25 bg-[#EDF5EF] px-2 py-1 text-[11px] font-semibold text-[#1F5432]"
                  >
                    {api.name}
                  </code>
                ))}
              </div>

              <div className="mt-4 border-t border-[#1D2B22]/10 pt-3.5">
                <div className="text-xs font-bold text-[#1D2B22]">
                  五大内置引擎 & 扩展防腐
                </div>
                <ul className="mt-2 space-y-1.5 text-xs text-[#3E5045]">
                  {ENGINE_COVERAGE.map((eng) => (
                    <li
                      key={eng.id}
                      className="flex items-center justify-between gap-2"
                    >
                      <span className="font-semibold text-[#1D2B22]">
                        {eng.name}
                      </span>
                      <span className="font-mono-tabular text-[11px] text-[#5B6A60]">
                        {eng.dependency} · {eng.loc} LOC
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </section>

        {/* Outer Ecosystem Readiness Strip */}
        <section>
          <h2 className="text-xl font-extrabold text-[#1D2B22]">
            包外生态组件与就绪度
          </h2>
          <p className="mt-1 text-xs text-[#4B5B50]">
            所有 Agent Skill、Python 执行器、前端工作台与 MCP 桥接严格位于 R 包核心之外，零耦合消费开放资产文件。
          </p>

          <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {ECOSYSTEM_CONSUMERS.map((eco) => (
              <div
                key={eco.id}
                className="rounded-xl border border-[#1D2B22]/12 bg-[#FCF9F3] p-4"
              >
                <div className="flex items-center justify-between gap-2">
                  <h3 className="text-xs font-bold text-[#1D2B22]">
                    {eco.name}
                  </h3>
                  <span
                    className={`inline-flex shrink-0 items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold ${
                      eco.status === 'implemented'
                        ? 'bg-[#E5F2E9] text-[#1F5432]'
                        : 'bg-[#E2EDF2] text-[#274B58]'
                    }`}
                  >
                    {eco.status === 'implemented' && (
                      <CheckCircle2 className="h-3 w-3" aria-hidden="true" />
                    )}
                    <span>
                      {eco.status === 'implemented' ? '已就绪' : '规划中'}
                    </span>
                  </span>
                </div>
                <div className="font-mono-tabular mt-1 text-[11px] text-[#2D603E]">
                  {eco.role}
                </div>
                <p className="mt-2 text-xs leading-relaxed text-[#43554A]">
                  {eco.example}
                </p>
              </div>
            ))}
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-[#1D2B22]/10 bg-[#EFE9DC]/70">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 px-5 py-6 text-xs text-[#4B5B50] sm:px-8">
          <div className="flex items-center gap-2">
            <span className="font-extrabold text-[#DF6A2B]">gloss</span>
            <span>·</span>
            <span>MIT License · YuLab-SMU</span>
          </div>
          <div className="flex flex-wrap items-center gap-4 font-medium">
            <a href="./3d/" className="hover:text-[#1D2B22] hover:underline">
              3D 架构空间
            </a>
            <a href="./map/" className="hover:text-[#1D2B22] hover:underline">
              LikeC4 实时地图
            </a>
            <a
              href={`${REPO_URL}/blob/main/dev_docs/architecture.md`}
              target="_blank"
              rel="noreferrer"
              className="hover:text-[#1D2B22] hover:underline"
            >
              架构设计文档
            </a>
            <a
              href={REPO_URL}
              target="_blank"
              rel="noreferrer"
              className="hover:text-[#1D2B22] hover:underline"
            >
              GitHub 仓库
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}
