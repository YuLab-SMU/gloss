import type { AssetNodeId, LayerId } from '../data/glossModel';
import type { MappingFocusMode } from './mappingPaths';

export const LAYER_ORDER: LayerId[] = [
  'code',
  'ir',
  'panels',
  'axes',
  'layers',
  'svg',
];

// Clean 2D architectural sheet proportions in Three.js world units
export const PLATE_WIDTH = 6.2;
export const PLATE_DEPTH = 4.4;
export const PLATE_THICKNESS = 0.012;
export const BASE_STACK_Y = 0.25;

// Flat-tiled 3x2 drafting-table grid spacing (layer vertical spacing = 0)
export const TILED_COL_STEP = 7.45; // 6.2 sheet + 1.25 horizontal gutter
export const TILED_ROW_STEP = 6.4;  // 4.4 sheet + 2.0 central routing corridor

// Plot area bounds inside the sheet (shared identically by 2D CanvasTexture and 3D mapping threads)
export const PLOT_LOCAL_BOUNDS = {
  minX: -2.05,
  maxX: 1.75,
  minZ: -1.45, // corresponds to PC2 = +10 (top of chart)
  maxZ: 1.35,  // corresponds to PC2 = -10 (bottom of chart)
} as const;

export type LayoutMode = 'stacked' | 'tiled';
export type CameraPresetId = 'isometric' | 'tiled' | 'top' | 'side' | 'assets';

export interface LayerTransform {
  x: number;
  y: number;
  z: number;
}

export interface AssetCardTransform {
  x: number;
  y: number;
  z: number;
  rotX: number;
  rotY: number;
  scale: number;
  calloutOffset: [number, number, number];
}

export interface CameraTargetState {
  position: [number, number, number];
  target: [number, number, number];
}

/**
 * Returns deterministic world transforms for right-wing Asset Map & Asset Bundle cards
 * in both vertically stacked mode and flat-tiled blueprint spread mode.
 */
export function getAssetCardTransforms(
  layoutMode: LayoutMode = 'stacked',
): Record<AssetNodeId, AssetCardTransform> {
  if (layoutMode === 'tiled') {
    return {
      'asset-map': {
        x: 12.45,
        y: BASE_STACK_Y + 0.03,
        z: -3.35,
        rotX: -Math.PI / 2,
        rotY: 0,
        scale: 1.14,
        calloutOffset: [0, 0.06, -1.16],
      },
      'asset-bundle': {
        x: 12.45,
        y: BASE_STACK_Y + 0.03,
        z: 0.0,
        rotX: -Math.PI / 2,
        rotY: 0,
        scale: 1.14,
        calloutOffset: [0, 0.06, -1.16],
      },
      'asset-work': {
        x: 12.45,
        y: BASE_STACK_Y + 0.03,
        z: 3.35,
        rotX: -Math.PI / 2,
        rotY: 0,
        scale: 1.14,
        calloutOffset: [0, 0.06, -1.16],
      },
    };
  }

  return {
    'asset-map': {
      x: 5.85,
      y: 4.5,
      z: -0.92,
      rotX: -0.06,
      rotY: -0.24,
      scale: 0.95,
      calloutOffset: [0, 0.92, 0],
    },
    'asset-bundle': {
      x: 5.85,
      y: 2.58,
      z: 0.08,
      rotX: -0.06,
      rotY: -0.24,
      scale: 0.95,
      calloutOffset: [0, 0.92, 0],
    },
    'asset-work': {
      x: 5.85,
      y: 0.66,
      z: 1.08,
      rotX: -0.06,
      rotY: -0.24,
      scale: 0.95,
      calloutOffset: [0, 0.92, 0],
    },
  };
}

/**
 * Computes strictly monotonic Y elevations for all 6 flat 2D sheets in stacked mode.
 * Even when explodeFactor === 0, sheets maintain clean non-Z-fighting clearance (>= 0.12).
 */
export function computeLayerYPositions(
  explodeFactor: number,
  focusLayerId: LayerId | null,
): Record<LayerId, number> {
  const clampedExplode = Math.max(0, Math.min(1, explodeFactor));
  const collapsedGap = 0.12;
  const explodedGap = 1.04;
  const baseGap = collapsedGap + (explodedGap - collapsedGap) * clampedExplode;

  const focusIndex = focusLayerId ? LAYER_ORDER.indexOf(focusLayerId) : -1;
  const extraClearance = focusIndex >= 0 ? 0.44 + 0.34 * clampedExplode : 0;

  const positions = {} as Record<LayerId, number>;
  let currentY = BASE_STACK_Y;

  for (let i = 0; i < LAYER_ORDER.length; i++) {
    const id = LAYER_ORDER[i];
    if (i > 0) {
      let gap = baseGap;
      if (focusIndex >= 0 && (i === focusIndex || i === focusIndex + 1)) {
        gap += extraClearance;
      }
      currentY += gap;
    }
    positions[id] = Number(currentY.toFixed(4));
  }

  return positions;
}

/**
 * Computes full 3D (x, y, z) transforms for all 6 flat 2D sheets:
 * - In 'tiled' mode: all 6 sheets lie flat at y = BASE_STACK_Y (0 vertical spacing) in a clean
 *   3-column x 2-row architectural compilation grid (Row 1: 01→02→03, Row 2: 04→05→06) with a
 *   dedicated central routing corridor between rows.
 * - In 'stacked' mode: vertical spacing + waterfall stagger offset + single-layer drawer pull-out.
 */
export function computeLayerTransforms(
  explodeFactor: number,
  staggerOffset: number,
  focusLayerId: LayerId | null,
  layoutMode: LayoutMode = 'stacked',
): Record<LayerId, LayerTransform> {
  const transforms = {} as Record<LayerId, LayerTransform>;

  if (layoutMode === 'tiled') {
    for (let i = 0; i < LAYER_ORDER.length; i++) {
      const id = LAYER_ORDER[i];
      const col = i % 3; // 0, 1, 2
      const row = Math.floor(i / 3); // 0 (top/back: 01-03), 1 (bottom/front: 04-06)
      const x = (col - 1) * TILED_COL_STEP;
      const z = (row - 0.5) * TILED_ROW_STEP;
      const y = focusLayerId === id ? BASE_STACK_Y + 0.36 : BASE_STACK_Y;

      transforms[id] = {
        x: Number(x.toFixed(4)),
        y: Number(y.toFixed(4)),
        z: Number(z.toFixed(4)),
      };
    }
    return transforms;
  }

  const yMap = computeLayerYPositions(explodeFactor, focusLayerId);
  const clampedStagger = Math.max(0, Math.min(1, staggerOffset));

  for (let i = 0; i < LAYER_ORDER.length; i++) {
    const id = LAYER_ORDER[i];
    // Centered index from -2.5 (Layer 01 bottom) to +2.5 (Layer 06 top)
    const centered = i - 2.5;
    let x = centered * 0.42 * clampedStagger;
    let z = -centered * 0.94 * clampedStagger;

    // Pull focused sheet forward like a blueprint flat-file drawer
    if (focusLayerId === id) {
      x -= 0.65;
      z += 2.35;
    }

    transforms[id] = {
      x: Number(x.toFixed(4)),
      y: yMap[id],
      z: Number(z.toFixed(4)),
    };
  }

  return transforms;
}

/**
 * Maps PCA coordinates (PC1 in [-10, 10], PC2 in [-10, 10]) to local (x, z) coordinates on the 2D sheet.
 */
export function mapDataToPlateLocal(
  pc1: number,
  pc2: number,
): { x: number; z: number; u: number; v: number } {
  const clampedX = Math.max(-10, Math.min(10, pc1));
  const clampedY = Math.max(-10, Math.min(10, pc2));

  const u = (clampedX + 10) / 20;
  const v = (10 - clampedY) / 20;

  const x =
    PLOT_LOCAL_BOUNDS.minX +
    u * (PLOT_LOCAL_BOUNDS.maxX - PLOT_LOCAL_BOUNDS.minX);
  const z =
    PLOT_LOCAL_BOUNDS.minZ +
    v * (PLOT_LOCAL_BOUNDS.maxZ - PLOT_LOCAL_BOUNDS.minZ);

  return { x, z, u, v };
}

/**
 * Frame-rate independent exponential damping helper.
 */
export function dampValue(
  current: number,
  target: number,
  lambda: number,
  dt: number,
): number {
  const safeDt = Math.max(0, Math.min(dt, 0.1));
  return current + (target - current) * (1 - Math.exp(-lambda * safeDt));
}

/**
 * Computes optimal 3D camera vantage point for flat-tiled blueprint spread,
 * focused sheets, key-element mapping modes, or standard presets.
 */
export function getCameraTargetState(
  preset: CameraPresetId,
  focusLayerId: LayerId | null,
  focusAssetId: AssetNodeId | null,
  explodeFactor: number,
  mappingMode: MappingFocusMode = 'overview',
  staggerOffset = 0,
  layoutMode: LayoutMode = 'stacked',
): CameraTargetState {
  const clampedStagger = Math.max(0, Math.min(1, staggerOffset));
  const transforms = computeLayerTransforms(
    explodeFactor,
    clampedStagger,
    focusLayerId,
    layoutMode,
  );
  const assetCards = getAssetCardTransforms(layoutMode);

  if (focusAssetId === 'asset-map') {
    const c = assetCards['asset-map'];
    return layoutMode === 'tiled'
      ? {
          position: [c.x, c.y + 6.4, c.z + 3.8],
          target: [c.x, c.y, c.z + 0.35],
        }
      : {
          position: [8.9, 5.2, 5.3],
          target: [5.3, 4.35, -0.75],
        };
  }

  if (focusAssetId === 'asset-bundle') {
    const c = assetCards['asset-bundle'];
    return layoutMode === 'tiled'
      ? {
          position: [c.x, c.y + 6.4, c.z + 3.8],
          target: [c.x, c.y, c.z + 0.35],
        }
      : {
          position: [8.9, 3.55, 5.6],
          target: [5.3, 2.5, 0.12],
        };
  }

  if (focusAssetId === 'asset-work') {
    const c = assetCards['asset-work'];
    return layoutMode === 'tiled'
      ? {
          position: [c.x, c.y + 6.4, c.z + 3.8],
          target: [c.x, c.y, c.z + 0.35],
        }
      : {
          position: [8.9, 2.25, 6.2],
          target: [5.3, 0.75, 1.0],
        };
  }

  // Flat-tiled blueprint spread mode (y spacing = 0, 3x2 grid + right output wing)
  if (layoutMode === 'tiled' || preset === 'tiled') {
    if (focusLayerId) {
      const t = transforms[focusLayerId];
      return {
        position: [t.x, t.y + 6.9, t.z + 4.3],
        target: [t.x, t.y, t.z + 0.45],
      };
    }

    if (mappingMode === 'asset-export') {
      return {
        position: [5.6, 17.8, 13.8],
        target: [5.2, BASE_STACK_Y, 0.65],
      };
    }

    // Elevated ~58-degree architectural drafting-table overview showing all 6 tiles, corridor bus links & output wing
    return {
      position: [1.35, 21.4, 14.8],
      target: [1.35, BASE_STACK_Y, 0.92],
    };
  }

  const midY = (transforms.code.y + transforms.svg.y) * 0.5;

  // Focused single-layer inspection: frame the pulled-out 2D drafting sheet squarely above the bottom dock
  if (focusLayerId) {
    const t = transforms[focusLayerId];
    return {
      position: [t.x - 1.2, t.y + 5.75, t.z + 7.45],
      target: [t.x + 0.12, t.y - 0.65, t.z + 0.25],
    };
  }

  // Gently widen distance when waterfall stagger is large so all 6 fanned sheets stay cleanly above the bottom dock
  const staggerPadZ = clampedStagger * 2.5;
  const staggerPadY = clampedStagger * 1.45;
  const staggerTargetZ = clampedStagger * 0.45;

  if (preset === 'isometric') {
    if (mappingMode === 'point-lineage') {
      return {
        position: [-5.8, midY + 4.2 + staggerPadY, 11.4 + staggerPadZ],
        target: [0.2, midY - 0.55, 0.08 + staggerTargetZ],
      };
    }
    if (mappingMode === 'scale-color') {
      return {
        position: [5.4, midY + 4.4 + staggerPadY, 12.2 + staggerPadZ],
        target: [0.85, midY - 0.5, -0.05 + staggerTargetZ],
      };
    }
    if (mappingMode === 'panel-grid') {
      return {
        position: [-6.0, midY + 4.6 + staggerPadY, 11.4 + staggerPadZ],
        target: [0.25, midY - 0.5, staggerTargetZ],
      };
    }
    if (mappingMode === 'asset-export') {
      return {
        position: [6.8, midY + 3.8 + staggerPadY, 11.6 + staggerPadZ],
        target: [2.2, midY - 0.5, 0.05 + staggerTargetZ],
      };
    }
  }

  switch (preset) {
    case 'top':
      return {
        position: [0.2, transforms.svg.y + 8.8 + staggerPadY * 1.5, 1.8],
        target: [0.2, transforms.svg.y * 0.55, 0.0],
      };
    case 'side':
      return {
        position: [0.2, midY + 0.65, 11.8 + staggerPadZ],
        target: [0.9, midY - 0.35, staggerTargetZ],
      };
    case 'assets':
      return {
        position: [7.6, midY + 3.2 + staggerPadY, 10.4 + staggerPadZ],
        target: [2.7, midY - 0.45, 0.1 + staggerTargetZ],
      };
    case 'isometric':
    default:
      return {
        position: [-6.4, midY + 4.9 + staggerPadY, 12.2 + staggerPadZ],
        target: [1.0, midY - 0.6, staggerTargetZ],
      };
  }
}
