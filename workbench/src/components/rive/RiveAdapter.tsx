import React, { useEffect, useState } from "react";
import { useRive, useStateMachineInput } from "@rive-app/react-canvas";

export interface RiveStateMachineProps {
  /** Optional URL or data URI to a `.riv` asset authored in Rive Editor. */
  src?: string;
  stateMachine?: string;
  inputs?: Record<string, number | boolean>;
  className?: string;
  /** High-craft native SVG state machine fallback used when no `.riv` asset is provided or in lite mode. */
  fallback: React.ReactNode;
}

const IS_LITE_MODE = import.meta.env.VITE_WORKBENCH_MODE === "lite";

function RiveCanvasHost({
  src,
  stateMachine = "State Machine 1",
  inputs,
  className,
  onError,
}: {
  src: string;
  stateMachine: string;
  inputs?: Record<string, number | boolean>;
  className?: string;
  onError: () => void;
}) {
  const { rive, RiveComponent } = useRive({
    src,
    stateMachines: stateMachine,
    autoplay: true,
    onLoadError: onError,
  });

  // Drive primary numeric/boolean state inputs when provided
  const firstEntry = inputs ? Object.entries(inputs)[0] : undefined;
  const primaryInput = useStateMachineInput(
    rive,
    stateMachine,
    firstEntry?.[0] ?? "state"
  );

  useEffect(() => {
    if (!rive || !inputs) return;
    const smInputs = rive.stateMachineInputs(stateMachine) ?? [];
    for (const [name, value] of Object.entries(inputs)) {
      const target = smInputs.find((i) => i.name === name);
      if (target) {
        target.value = value;
      }
    }
    if (primaryInput && firstEntry) {
      primaryInput.value = firstEntry[1];
    }
  }, [rive, stateMachine, inputs, primaryInput, firstEntry]);

  return <RiveComponent className={className} />;
}

/**
 * Rive State Machine adapter with automatic hot-swap and zero-WASM lite fallback.
 * Drop any authored `.riv` file into `public/rive/` (or configure via `window.__GLOSS_WORKBENCH_CONFIG__.riveAssets`)
 * to drive real Rive animations with the exact same State Machine inputs.
 */
export const RiveStateMachine: React.FC<RiveStateMachineProps> = ({
  src,
  stateMachine = "State Machine 1",
  inputs,
  className,
  fallback,
}) => {
  const [failed, setFailed] = useState(false);

  if (IS_LITE_MODE || !src || failed) {
    return <>{fallback}</>;
  }

  return (
    <RiveCanvasHost
      src={src}
      stateMachine={stateMachine}
      inputs={inputs}
      className={className}
      onError={() => setFailed(true)}
    />
  );
};
