import React, { useRef, useState } from "react";
import { FolderOpen, Sparkles, Upload } from "lucide-react";
import { useWorkbenchStore } from "../../store/useWorkbenchStore";
import { RiveStateMachine } from "./RiveAdapter";

export const DropzoneHero: React.FC<{ onLoadSample?: () => void; sampleAvailable?: boolean }> = ({
  onLoadSample,
  sampleAvailable,
}) => {
  const loadFromFiles = useWorkbenchStore((s) => s.loadFromFiles);
  const loading = useWorkbenchStore((s) => s.loading);
  const error = useWorkbenchStore((s) => s.error);
  const riveSrc = useWorkbenchStore((s) => s.config.riveAssets?.dropzone);

  const [dragging, setDragging] = useState(false);
  const [tilt, setTilt] = useState({ x: 0, y: 0 });
  const fileInputRef = useRef<HTMLInputElement>(null);
  const dirInputRef = useRef<HTMLInputElement>(null);

  const handleDrop = async (e: React.DragEvent) => {
    e.preventDefault();
    setDragging(false);
    if (e.dataTransfer.files?.length) {
      await loadFromFiles(e.dataTransfer.files);
    }
  };

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const nx = ((e.clientX - rect.left) / rect.width - 0.5) * 2;
    const ny = ((e.clientY - rect.top) / rect.height - 0.5) * 2;
    setTilt({ x: nx, y: ny });
  };

  const unfoldOffset = dragging ? 18 : 9;

  const svgManuscriptFallback = (
    <svg
      viewBox="0 0 360 210"
      className="h-48 w-full max-w-[360px] select-none overflow-visible"
      aria-hidden="true"
    >
      {/* Layer 4: Behavior / Interaction layer */}
      <g
        style={{
          transform: `translate(${tilt.x * 14}px, ${-unfoldOffset * 2.1 + tilt.y * 8}px)`,
          transition: "transform 280ms cubic-bezier(0.22, 1, 0.36, 1)",
        }}
      >
        <rect
          x="74"
          y="42"
          width="212"
          height="112"
          rx="12"
          fill="var(--st-focus-soft)"
          fillOpacity="0.65"
          stroke="var(--st-focus)"
          strokeWidth="1.4"
          strokeDasharray="4 3"
        />
        <rect x="196" y="54" width="76" height="22" rx="6" fill="var(--bg-surface)" stroke="var(--st-focus)" strokeWidth="1" />
        <text x="205" y="68" fontSize="8.5" fontWeight="600" fill="var(--st-focus)">
          Behavior · Tooltip
        </text>
      </g>

      {/* Layer 3: Contextual & Verified Claims */}
      <g
        style={{
          transform: `translate(${tilt.x * 9}px, ${-unfoldOffset * 1.1 + tilt.y * 5}px)`,
          transition: "transform 280ms cubic-bezier(0.22, 1, 0.36, 1)",
        }}
      >
        <rect
          x="64"
          y="58"
          width="212"
          height="112"
          rx="12"
          fill="var(--st-verified-soft)"
          fillOpacity="0.55"
          stroke="var(--st-verified)"
          strokeWidth="1.4"
        />
        <circle cx="152" cy="106" r="9" fill="none" stroke="var(--st-verified)" strokeWidth="2" />
        <path d="M161 103 Q188 86 208 92" fill="none" stroke="var(--st-contextual)" strokeWidth="1.4" strokeDasharray="3 2" />
        <text x="78" y="76" fontSize="8.5" fontWeight="600" fill="var(--st-verified)">
          Records · Checks · Context
        </text>
      </g>

      {/* Layer 2: Data Binding Grid */}
      <g
        style={{
          transform: `translate(${tilt.x * 4}px, ${tilt.y * 3}px)`,
          transition: "transform 280ms cubic-bezier(0.22, 1, 0.36, 1)",
        }}
      >
        <rect
          x="54"
          y="74"
          width="212"
          height="112"
          rx="12"
          fill="var(--bg-surface)"
          stroke="var(--border-strong)"
          strokeWidth="1.5"
        />
        {/* Original scatter substrate marks */}
        <line x1="78" y1="164" x2="244" y2="164" stroke="var(--ink-muted)" strokeWidth="1.2" />
        <line x1="78" y1="96" x2="78" y2="164" stroke="var(--ink-muted)" strokeWidth="1.2" />
        <circle cx="104" cy="112" r="4.2" fill="#e15759" />
        <circle cx="126" cy="122" r="4.2" fill="#4e79a7" />
        <circle cx="148" cy="128" r="5" fill="#0d9488" stroke="#2563eb" strokeWidth="2" />
        <circle cx="176" cy="138" r="4.2" fill="#4e79a7" />
        <circle cx="204" cy="146" r="4.2" fill="#f28e2b" />
        <circle cx="226" cy="153" r="4.2" fill="#f28e2b" />
        <text x="78" y="90" fontSize="8.5" fontWeight="600" fill="var(--ink-secondary)">
          Substrate · Untouched svglite SVG
        </text>
      </g>
    </svg>
  );

  return (
    <div
      className="stage-grid-bg flex h-full w-full flex-col items-center justify-center p-8"
      onDragOver={(e) => {
        e.preventDefault();
        setDragging(true);
      }}
      onDragLeave={() => setDragging(false)}
      onDrop={handleDrop}
      onMouseMove={handleMouseMove}
    >
      <div
        className="flex w-full max-w-2xl flex-col items-center rounded-2xl border-2 border-dashed p-10 text-center transition-all duration-200"
        style={{
          background: "var(--bg-surface)",
          borderColor: dragging ? "var(--st-focus)" : "var(--border-strong)",
          boxShadow: dragging ? "var(--shadow-float)" : "var(--shadow-card)",
          transform: dragging ? "scale(1.01)" : "scale(1)",
        }}
      >
        <div className="mb-3 flex h-48 w-full items-center justify-center">
          <RiveStateMachine
            src={riveSrc}
            stateMachine="DropzoneUnfold"
            inputs={{ isDragging: dragging, tiltX: tilt.x, tiltY: tilt.y }}
            className="h-48 w-full max-w-[360px]"
            fallback={svgManuscriptFallback}
          />
        </div>

        <div
          className="mb-2 inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-[11px] font-semibold uppercase tracking-wider"
          style={{ background: "var(--st-focus-soft)", color: "var(--st-focus)" }}
        >
          gloss Workbench · v0.3 Bundle Inspector
        </div>

        <h1 className="mb-2 text-2xl font-bold tracking-tight" style={{ color: "var(--ink-primary)" }}>
          Drop a gloss artifact to inspect its semantic layers
        </h1>
        <p className="mb-6 max-w-lg text-sm leading-relaxed" style={{ color: "var(--ink-secondary)" }}>
          Supports any single-file <code className="font-mono-num">.html</code> /{" "}
          <code className="font-mono-num">.svg</code> written by{" "}
          <code className="font-mono-num">gl_write()</code> or{" "}
          <code className="font-mono-num">gl_workbench()</code>, or a{" "}
          <code className="font-mono-num">.gloss/</code> bundle directory. Decoded 100% locally in your browser with SHA-256 verification.
        </p>

        <div className="flex flex-wrap items-center justify-center gap-3">
          <button
            type="button"
            disabled={loading}
            onClick={() => fileInputRef.current?.click()}
            className="inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition-transform hover:-translate-y-0.5 active:translate-y-0"
            style={{ background: "var(--st-focus)" }}
          >
            <Upload className="h-4 w-4" />
            Open .html / .svg Artifact
          </button>

          <button
            type="button"
            disabled={loading}
            onClick={() => dirInputRef.current?.click()}
            className="inline-flex items-center gap-2 rounded-xl border px-4 py-2.5 text-sm font-semibold transition-colors hover:bg-[var(--bg-subtle)]"
            style={{
              borderColor: "var(--border-strong)",
              color: "var(--ink-primary)",
            }}
          >
            <FolderOpen className="h-4 w-4" />
            Open .gloss/ Folder
          </button>

          {sampleAvailable && onLoadSample && (
            <button
              type="button"
              disabled={loading}
              onClick={onLoadSample}
              className="inline-flex items-center gap-2 rounded-xl border px-4 py-2.5 text-sm font-semibold transition-colors hover:bg-[var(--st-verified-soft)]"
              style={{
                borderColor: "var(--st-verified)",
                color: "var(--st-verified)",
              }}
            >
              <Sparkles className="h-4 w-4" />
              Load Demo Artifact (mtcars)
            </button>
          )}
        </div>

        <input
          ref={fileInputRef}
          type="file"
          accept=".html,.htm,.svg"
          className="hidden"
          onChange={(e) => {
            if (e.target.files?.length) void loadFromFiles(e.target.files);
          }}
        />
        <input
          ref={dirInputRef}
          type="file"
          // @ts-expect-error non-standard directory picker supported in Chromium/Safari/Firefox
          webkitdirectory=""
          multiple
          className="hidden"
          onChange={(e) => {
            if (e.target.files?.length) void loadFromFiles(e.target.files);
          }}
        />

        {error && (
          <div
            className="mt-5 w-full rounded-xl border px-4 py-3 text-left text-xs font-medium"
            style={{
              background: "var(--st-fail-soft)",
              borderColor: "var(--st-fail)",
              color: "var(--st-fail)",
            }}
          >
            {error}
          </div>
        )}
      </div>
    </div>
  );
};
