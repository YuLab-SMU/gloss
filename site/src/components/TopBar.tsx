import { ArrowLeft, ArrowUpRight } from 'lucide-react';
import { PROJECT_LIVE_STATUS, type DrawerTab } from '../data/glossModel';

export interface TopBarProps {
  activeNav: 'spatial' | DrawerTab;
  onSelectNav: (nav: 'spatial' | DrawerTab) => void;
  onResetView: () => void;
}

const NAV_ITEMS: { id: 'spatial' | DrawerTab; label: string }[] = [
  { id: 'spatial', label: '空间分解' },
  { id: 'contract', label: '四层契约' },
  { id: 'assets', label: '内核与资产' },
  { id: 'roadmap', label: '实况与路线' },
];

export function TopBar({
  activeNav,
  onSelectNav,
  onResetView,
}: TopBarProps) {
  return (
    <header className="pointer-events-auto fixed inset-x-0 top-0 z-30 flex h-14 items-center justify-between gap-4 border-b border-[#1D2B22]/10 bg-[#F7F3EA]/96 px-4 sm:px-6">
      {/* Zone 1: Back to Portal Home + Brand Wordmark + Live Schema Pill */}
      <div className="flex items-center gap-2.5 shrink-0">
        <a
          href="../"
          title="返回 gloss 主页"
          className="inline-flex items-center gap-1 rounded-md border border-[#1D2B22]/12 bg-[#FCF9F3] px-2 py-1 text-[11px] font-semibold text-[#3A4D41] transition-colors hover:border-[#2D603E] hover:text-[#2D603E]"
        >
          <ArrowLeft className="h-3 w-3" aria-hidden="true" />
          <span className="hidden sm:inline">主页</span>
        </a>

        <button
          type="button"
          onClick={() => onSelectNav('spatial')}
          className="flex items-baseline gap-2 text-left whitespace-nowrap shrink-0 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#2D603E]"
        >
          <span className="text-xl font-extrabold tracking-tight text-[#DF6A2B]">
            gloss
          </span>
          <span className="text-sm font-semibold text-[#1D2B22]">
            3D 架构空间
          </span>
        </button>

        <button
          type="button"
          onClick={() => onSelectNav('roadmap')}
          title="查看项目实时工程实况与 839 项测试验收状态"
          className="hidden items-center gap-1.5 rounded-full border border-[#2D603E]/25 bg-[#EDF5EF] px-2.5 py-0.5 text-[11px] font-semibold text-[#234F33] transition-colors hover:border-[#2D603E] hover:bg-[#E2EFE6] xl:inline-flex"
        >
          <span
            className="h-1.5 w-1.5 rounded-full bg-[#2F855A]"
            aria-hidden="true"
          />
          <span className="font-mono-tabular">
            Schema v{PROJECT_LIVE_STATUS.schemaVersion}
          </span>
          <span className="text-[#2D603E]/40" aria-hidden="true">
            ·
          </span>
          <span className="font-mono-tabular">
            {PROJECT_LIVE_STATUS.rTestsPassed} PASS
          </span>
        </button>
      </div>

      {/* Zone 2: 4 Clean Single-Line Navigation Links */}
      <nav
        aria-label="主导航"
        className="hidden items-center gap-5 md:flex"
      >
        {NAV_ITEMS.map((item) => {
          const isCurrent = activeNav === item.id;
          return (
            <button
              key={item.id}
              type="button"
              onClick={() => onSelectNav(item.id)}
              aria-current={isCurrent ? 'page' : undefined}
              className={`relative py-1 text-sm font-medium whitespace-nowrap shrink-0 transition-colors duration-150 focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#2D603E] ${
                isCurrent
                  ? 'text-[#2D603E] font-semibold'
                  : 'text-[#4B5B50] hover:text-[#1D2B22]'
              }`}
            >
              {item.label}
              {isCurrent && (
                <span
                  aria-hidden="true"
                  className="absolute inset-x-0 -bottom-[17px] h-0.5 bg-[#2D603E]"
                />
              )}
            </button>
          );
        })}
      </nav>

      {/* Zone 3: LikeC4 Map Switch + Reset View */}
      <div className="flex items-center gap-2 shrink-0">
        <a
          href="../map/"
          title="切换到 LikeC4 实时代码-意图架构地图"
          className="hidden items-center gap-1 rounded-lg border border-[#2D603E]/30 bg-[#FCF9F3] px-2.5 py-1.5 text-xs font-semibold text-[#2D603E] whitespace-nowrap shrink-0 transition-colors hover:border-[#2D603E] hover:bg-[#EDF5EF] sm:inline-flex"
        >
          <span>LikeC4 地图</span>
          <ArrowUpRight className="h-3.5 w-3.5" aria-hidden="true" />
        </a>

        <button
          type="button"
          onClick={onResetView}
          className="rounded-lg bg-[#2D603E] px-3.5 py-1.5 text-xs font-semibold text-[#FCF9F3] whitespace-nowrap shrink-0 transition-colors duration-150 hover:bg-[#234F33] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#2D603E]"
        >
          重置视角
        </button>
      </div>
    </header>
  );
}
