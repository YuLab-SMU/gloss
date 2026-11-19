import Flatbush from "flatbush";
import type { GlossBundle, GlossElement, GlossPanel } from "./types";

export interface SpatialIndex {
  tree: Flatbush | null;
  elements: GlossElement[];
  hitTest(svgX: number, svgY: number, tolerancePt?: number): GlossElement | null;
  queryBox(minX: number, minY: number, maxX: number, maxY: number): GlossElement[];
}

/**
 * Build a Flatbush static R-tree over all substrate elements (including 10^5 dense leaves).
 */
export function buildSpatialIndex(elements: GlossElement[]): SpatialIndex {
  if (elements.length === 0) {
    return {
      tree: null,
      elements,
      hitTest: () => null,
      queryBox: () => [],
    };
  }
  const tree = new Flatbush(elements.length);
  for (let i = 0; i < elements.length; i += 1) {
    const e = elements[i];
    const x0 = Math.min(e.x0, e.x1);
    const y0 = Math.min(e.y0, e.y1);
    const x1 = Math.max(e.x0, e.x1);
    const y1 = Math.max(e.y0, e.y1);
    tree.add(x0, y0, x1, y1);
  }
  tree.finish();

  return {
    tree,
    elements,
    hitTest(svgX: number, svgY: number, tolerancePt = 4): GlossElement | null {
      const ids = tree.search(
        svgX - tolerancePt,
        svgY - tolerancePt,
        svgX + tolerancePt,
        svgY + tolerancePt
      );
      if (ids.length === 0) return null;
      // Prefer exact containment (crucial for ComplexHeatmap tiles) & smallest-area marks closest to cursor
      let best: GlossElement | null = null;
      let bestScore = Infinity;
      for (const idx of ids) {
        const el = elements[idx];
        const minX = Math.min(el.x0, el.x1);
        const maxX = Math.max(el.x0, el.x1);
        const minY = Math.min(el.y0, el.y1);
        const maxY = Math.max(el.y0, el.y1);
        const inside = svgX >= minX && svgX <= maxX && svgY >= minY && svgY <= maxY;
        const cx = (minX + maxX) / 2;
        const cy = (minY + maxY) / 2;
        const dist = Math.hypot(svgX - cx, svgY - cy);
        const area = Math.max(1, (maxX - minX) * (maxY - minY));
        // Penalize huge background rects so small data points & exact heatmap cells win on overlap
        const score = (inside ? dist * 0.25 : dist + 4) + Math.log10(area) * 2.2;
        if (score < bestScore) {
          bestScore = score;
          best = el;
        }
      }
      return best;
    },
    queryBox(minX: number, minY: number, maxX: number, maxY: number): GlossElement[] {
      const ids = tree.search(minX, minY, maxX, maxY);
      return ids.map((i) => elements[i]);
    },
  };
}

export interface DataCoordinateReadout {
  panel: GlossPanel;
  dataX: number | null;
  dataY: number | null;
}

/**
 * Convert an SVG point (in pt, viewBox coordinates) to panel data coordinates.
 * Note: SVG y increases downward, so y_min corresponds to panel.y1 and y_max to panel.y0.
 */
export function svgPointToData(
  bundle: GlossBundle,
  svgX: number,
  svgY: number
): DataCoordinateReadout | null {
  for (const panel of bundle.substrate.panels) {
    const minX = Math.min(panel.x0, panel.x1);
    const maxX = Math.max(panel.x0, panel.x1);
    const minY = Math.min(panel.y0, panel.y1);
    const maxY = Math.max(panel.y0, panel.y1);
    if (svgX >= minX && svgX <= maxX && svgY >= minY && svgY <= maxY) {
      let dataX: number | null = null;
      let dataY: number | null = null;
      if (
        panel.x_min !== null &&
        panel.x_max !== null &&
        maxX > minX &&
        panel.x_type === "continuous"
      ) {
        const tx = (svgX - minX) / (maxX - minX);
        dataX = panel.x_min + tx * (panel.x_max - panel.x_min);
      }
      if (
        panel.y_min !== null &&
        panel.y_max !== null &&
        maxY > minY &&
        panel.y_type === "continuous"
      ) {
        const ty = (maxY - svgY) / (maxY - minY);
        dataY = panel.y_min + ty * (panel.y_max - panel.y_min);
      }
      return { panel, dataX, dataY };
    }
  }
  return null;
}
