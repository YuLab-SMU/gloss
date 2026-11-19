import React from "react";
import { SEMANTIC_STAGES, type SemanticStageId } from "../../codec";
import { useWorkbenchStore } from "../../store/useWorkbenchStore";
import { RiveStateMachine } from "./RiveAdapter";

const TRACK_ACCENT: Record<string, string> = {
  substrate: "var(--ink-secondary)",
  "in-figure": "var(--st-verified)",
  contextual: "var(--st-contextual)",
  projection: "var(--st-focus)",
};

export const StageRail: React.FC = () => {
  const activeStage = useWorkbenchStore((s) => s.activeStage);
  const setActiveStage = useWorkbenchStore((s) => s.setActiveStage);
  const stageStats = useWorkbenchStore((s) => s.stageStats);
  const riveSrc = useWorkbenchStore((s) => s.config.riveAssets?.stageRail);

  const activeIdx = SEMANTIC_STAGES.findIndex((s) => s.id === activeStage);
  const progressPct = (activeIdx / (SEMANTIC_STAGES.length - 1)) * 100;

  return (
    <div
      className="relative flex flex-col border-b px-3 py-2"
      style={{
        background: "var(--bg-surface)",
        borderColor: "var(--border-subtle)",
      }}
    >
      {/* Optional Rive ambient progress ribbon behind the rail (zero-height fallback) */}
      {riveSrc && (
        <div className="pointer-events-none absolute inset-x-0 top-0 h-1 overflow-hidden">
          <RiveStateMachine
            src={riveSrc}
            stateMachine="StageRail"
            inputs={{ activeStage: activeIdx }}
            className="h-full w-full"
            fallback={null}
          />
        </div>
      )}

      <div className="relative flex items-center justify-between gap-1">
        {/* Continuous optical track behind nodes */}
        <div
          className="pointer-events-none absolute left-5 right-5 top-[15px] h-[2px] rounded-full"
          style={{ background: "var(--border-subtle)" }}
        >
          <div
            className="h-full rounded-full transition-all duration-300 ease-out"
            style={{
              width: `${progressPct}%`,
              background:
                "linear-gradient(90deg, var(--ink-secondary) 0%, var(--st-verified) 45%, var(--st-contextual) 62%, var(--st-focus) 100%)",
            }}
          />
        </div>

        {SEMANTIC_STAGES.map((stage, idx) => {
          const stat = stageStats?.[stage.id];
          const isActive = stage.id === activeStage;
          const isPast = idx < activeIdx;
          const populated = stat?.populated ?? false;
          const hasFail = (stat?.failedCount ?? 0) > 0;
          const hasWarn = (stat?.warningCount ?? 0) > 0;
          const accent = TRACK_ACCENT[stage.sourceTrack];

          let dotBorder = "var(--border-strong)";
          let dotBg = "var(--bg-surface)";
          if (isActive) {
            dotBorder = "var(--st-focus)";
            dotBg = "var(--st-focus)";
          } else if (hasFail) {
            dotBorder = "var(--st-fail)";
            dotBg = "var(--st-fail-soft)";
          } else if (populated && isPast) {
            dotBorder = accent;
            dotBg = accent;
          } else if (populated) {
            dotBorder = accent;
            dotBg = "var(--bg-surface)";
          }

          return (
            <button
              key={stage.id}
              type="button"
              onClick={() => setActiveStage(stage.id as SemanticStageId)}
              title={`${idx + 1}. ${stage.label} (${stage.zhLabel}) — ${stage.description}`}
              className="group relative z-10 flex min-w-0 flex-1 flex-col items-center gap-1 rounded-lg px-1 py-0.5 transition-colors hover:bg-[var(--bg-subtle)]/70 focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--st-focus)]"
            >
              {/* Tactile node dot */}
              <div className="relative flex h-6 w-6 items-center justify-center">
                {isActive && (
                  <span
                    className="absolute inset-0 rounded-full opacity-25"
                    style={{ background: "var(--st-focus)", transform: "scale(1.25)" }}
                  />
                )}
                <span
                  className="relative flex h-3.5 w-3.5 items-center justify-center rounded-full border-2 transition-all duration-200 group-hover:scale-110"
                  style={{
                    borderColor: dotBorder,
                    background: dotBg,
                    borderStyle: !populated && !isActive ? "dashed" : "solid",
                  }}
                >
                  {isActive && <span className="h-1.5 w-1.5 rounded-full bg-white" />}
                </span>
                {/* Subtle warning / fail pip */}
                {hasFail && !isActive && (
                  <span
                    className="absolute right-0 top-0 h-2 w-2 rounded-full ring-1 ring-[var(--bg-surface)]"
                    style={{ background: "var(--st-fail)" }}
                  />
                )}
                {!hasFail && hasWarn && !isActive && (
                  <span
                    className="absolute right-0 top-0 h-2 w-2 rounded-full ring-1 ring-[var(--bg-surface)]"
                    style={{ background: "var(--st-warn)" }}
                  />
                )}
              </div>

              {/* Label + count pill */}
              <div className="flex max-w-full items-center gap-1">
                <span
                  className="truncate text-[11px] font-semibold tracking-tight transition-colors"
                  style={{
                    color: isActive
                      ? "var(--st-focus)"
                      : populated
                        ? "var(--ink-primary)"
                        : "var(--ink-muted)",
                  }}
                >
                  {stage.shortLabel}
                </span>
                {stat && stat.count > 0 && (
                  <span
                    className="font-mono-num rounded px-1 py-0 text-[9.5px] font-medium"
                    style={{
                      background: isActive ? "var(--st-focus-soft)" : "var(--bg-subtle)",
                      color: isActive ? "var(--st-focus)" : "var(--ink-secondary)",
                    }}
                  >
                    {stat.count}
                  </span>
                )}
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
};
