import React from "react";
import { RiveStateMachine } from "./RiveAdapter";
import { useWorkbenchStore } from "../../store/useWorkbenchStore";

export type SealStatus =
  | "verified"
  | "partial"
  | "failed"
  | "rejected"
  | "ambiguous"
  | "proposed"
  | "speculative"
  | "uncheckable"
  | "unbound";

const STATUS_CODE: Record<SealStatus, number> = {
  verified: 1,
  partial: 2,
  ambiguous: 3,
  proposed: 4,
  speculative: 5,
  failed: 6,
  rejected: 6,
  uncheckable: 7,
  unbound: 0,
};

const STATUS_META: Record<
  SealStatus,
  { label: string; colorVar: string; softVar: string; dashed?: boolean }
> = {
  verified: { label: "Verified", colorVar: "var(--st-verified)", softVar: "var(--st-verified-soft)" },
  partial: { label: "Partial (Exception)", colorVar: "var(--st-warn)", softVar: "var(--st-warn-soft)" },
  ambiguous: { label: "Ambiguous", colorVar: "var(--st-warn)", softVar: "var(--st-warn-soft)" },
  proposed: { label: "Proposed", colorVar: "var(--st-warn)", softVar: "var(--st-warn-soft)" },
  speculative: {
    label: "Speculative",
    colorVar: "var(--st-spec)",
    softVar: "var(--st-spec-soft)",
    dashed: true,
  },
  failed: { label: "Failed", colorVar: "var(--st-fail)", softVar: "var(--st-fail-soft)" },
  rejected: { label: "Rejected", colorVar: "var(--st-fail)", softVar: "var(--st-fail-soft)" },
  uncheckable: {
    label: "Refused / Uncheckable",
    colorVar: "var(--st-spec)",
    softVar: "var(--st-spec-soft)",
    dashed: true,
  },
  unbound: {
    label: "Unbound",
    colorVar: "var(--st-spec)",
    softVar: "var(--st-spec-soft)",
    dashed: true,
  },
};

export const VerificationSeal: React.FC<{
  status: string;
  size?: number;
  showLabel?: boolean;
}> = ({ status, size = 34, showLabel = true }) => {
  const riveSrc = useWorkbenchStore((s) => s.config.riveAssets?.verifySeal);
  const norm = (status in STATUS_META ? status : "proposed") as SealStatus;
  const meta = STATUS_META[norm];

  const svgFallback = (
    <svg
      width={size}
      height={size}
      viewBox="0 0 40 40"
      className="shrink-0 overflow-visible"
      aria-label={`Verification status: ${meta.label}`}
    >
      {/* Outer tactile halo */}
      <circle
        cx="20"
        cy="20"
        r="17"
        fill={meta.softVar}
        stroke={meta.colorVar}
        strokeWidth={meta.dashed ? "1.6" : "2"}
        strokeDasharray={meta.dashed ? "3.5 3" : undefined}
        className={norm === "partial" || norm === "ambiguous" ? "gloss-pulse" : undefined}
      />
      {/* Inner precision dial ticks */}
      <circle
        cx="20"
        cy="20"
        r="12.5"
        fill="none"
        stroke={meta.colorVar}
        strokeOpacity="0.28"
        strokeWidth="1"
        strokeDasharray="1.5 3"
      />
      {/* State glyph */}
      {norm === "verified" && (
        <path
          d="M13.5 20.5 L18 25 L27 15.5"
          fill="none"
          stroke={meta.colorVar}
          strokeWidth="2.6"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      )}
      {(norm === "partial" || norm === "proposed") && (
        <>
          <line
            x1="20"
            y1="13"
            x2="20"
            y2="21.5"
            stroke={meta.colorVar}
            strokeWidth="2.5"
            strokeLinecap="round"
          />
          <circle cx="20" cy="26.5" r="1.6" fill={meta.colorVar} />
        </>
      )}
      {norm === "ambiguous" && (
        <>
          <circle cx="16.5" cy="20" r="4.2" fill="none" stroke={meta.colorVar} strokeWidth="2" />
          <circle cx="23.5" cy="20" r="4.2" fill="none" stroke={meta.colorVar} strokeWidth="2" />
        </>
      )}
      {(norm === "failed" || norm === "rejected") && (
        <path
          d="M14.5 14.5 L25.5 25.5 M25.5 14.5 L14.5 25.5"
          fill="none"
          stroke={meta.colorVar}
          strokeWidth="2.5"
          strokeLinecap="round"
        />
      )}
      {(norm === "speculative" || norm === "uncheckable" || norm === "unbound") && (
        <circle
          cx="20"
          cy="20"
          r="5"
          fill="none"
          stroke={meta.colorVar}
          strokeWidth="2"
          strokeDasharray="2.5 2.5"
        />
      )}
    </svg>
  );

  return (
    <div className="inline-flex items-center gap-2">
      <div style={{ width: size, height: size }} className="relative flex items-center justify-center">
        <RiveStateMachine
          src={riveSrc}
          stateMachine="VerifySeal"
          inputs={{ statusCode: STATUS_CODE[norm] }}
          className="h-full w-full"
          fallback={svgFallback}
        />
      </div>
      {showLabel && (
        <span
          className="text-xs font-semibold tracking-tight"
          style={{ color: meta.colorVar }}
        >
          {meta.label}
        </span>
      )}
    </div>
  );
};
