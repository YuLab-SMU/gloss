import * as THREE from 'three';
import { PCA_SAMPLES, type AssetNodeId, type LayerId } from '../data/glossModel';
import {
  PLATE_DEPTH,
  PLATE_WIDTH,
  PLOT_LOCAL_BOUNDS,
  mapDataToPlateLocal,
} from './layoutMath';
import { SHEET_ANCHORS, getPanelSubRects } from './mappingPaths';

const TEX_W = 1280;
const TEX_H = 908;

function localToCanvas(x: number, z: number): { px: number; py: number } {
  const px = ((x + PLATE_WIDTH / 2) / PLATE_WIDTH) * TEX_W;
  const py = ((z + PLATE_DEPTH / 2) / PLATE_DEPTH) * TEX_H;
  return { px, py };
}

function drawRoundedRect(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  w: number,
  h: number,
  r: number,
) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}

function drawAnchorPort(
  ctx: CanvasRenderingContext2D,
  localX: number,
  localZ: number,
  color: string,
  radius = 10,
) {
  const { px, py } = localToCanvas(localX, localZ);
  ctx.save();
  ctx.beginPath();
  ctx.arc(px, py, radius + 5, 0, Math.PI * 2);
  ctx.fillStyle = color + '24';
  ctx.fill();
  ctx.beginPath();
  ctx.arc(px, py, radius, 0, Math.PI * 2);
  ctx.fillStyle = '#FCF9F3';
  ctx.fill();
  ctx.lineWidth = 3.5;
  ctx.strokeStyle = color;
  ctx.stroke();
  ctx.beginPath();
  ctx.arc(px, py, 3.5, 0, Math.PI * 2);
  ctx.fillStyle = color;
  ctx.fill();
  ctx.restore();
}

function drawSheetHeader(
  ctx: CanvasRenderingContext2D,
  fill: string,
  border: string,
  stepText: string,
  title: string,
  badgeColor: string,
  meta: string,
) {
  ctx.clearRect(0, 0, TEX_W, TEX_H);

  // Sleek single-bordered rounded archival card (genuine rounded corners via WebGL alphaTest)
  ctx.save();
  drawRoundedRect(ctx, 8, 8, TEX_W - 16, TEX_H - 16, 30);
  ctx.fillStyle = fill;
  ctx.fill();

  // Subtle top-edge architectural accent ribbon clipped cleanly inside the rounded silhouette
  ctx.save();
  ctx.clip();
  ctx.fillStyle = badgeColor;
  ctx.globalAlpha = 0.78;
  ctx.fillRect(8, 8, TEX_W - 16, 6);
  // Subtle inner paper highlight sheen at top edge for tactile lightness
  const topSheen = ctx.createLinearGradient(0, 14, 0, 110);
  topSheen.addColorStop(0, 'rgba(255, 255, 255, 0.42)');
  topSheen.addColorStop(1, 'rgba(255, 255, 255, 0)');
  ctx.globalAlpha = 1;
  ctx.fillStyle = topSheen;
  ctx.fillRect(8, 14, TEX_W - 16, 96);
  ctx.restore();

  // Single refined hairline border (zero double-frame bulk)
  drawRoundedRect(ctx, 8, 8, TEX_W - 16, TEX_H - 16, 30);
  ctx.lineWidth = 1.8;
  ctx.strokeStyle = border;
  ctx.stroke();
  ctx.restore();

  // Minimalist drafting corner ticks (matching 3D frame meridians without visual heaviness)
  const hw = PLATE_WIDTH / 2 - 0.14;
  const hd = PLATE_DEPTH / 2 - 0.14;
  ctx.strokeStyle = 'rgba(45, 96, 62, 0.22)';
  ctx.lineWidth = 1.4;
  for (const [cx, cz] of [
    [-hw, -hd],
    [hw, -hd],
    [-hw, hd],
    [hw, hd],
  ]) {
    const p = localToCanvas(cx, cz);
    ctx.beginPath();
    ctx.moveTo(p.px - 6, p.py);
    ctx.lineTo(p.px + 6, p.py);
    ctx.moveTo(p.px, p.py - 6);
    ctx.lineTo(p.px, p.py + 6);
    ctx.stroke();
  }

  // Refined architectural header pill
  drawRoundedRect(ctx, 44, 38, 352, 46, 12);
  ctx.fillStyle = badgeColor;
  ctx.fill();

  ctx.fillStyle = '#FCF9F3';
  ctx.font = '700 21px "Plus Jakarta Sans", "Noto Sans SC", sans-serif';
  ctx.textBaseline = 'middle';
  ctx.textAlign = 'left';
  ctx.fillText(`${stepText}  ${title}`, 64, 62);

  ctx.fillStyle = '#4B5B50';
  ctx.font = '600 18.5px "JetBrains Mono", monospace';
  ctx.textAlign = 'right';
  ctx.fillText(meta, TEX_W - 50, 62);
  ctx.textAlign = 'left';
}

function finalizeTexture(
  canvas: HTMLCanvasElement,
  maxAnisotropy: number,
): THREE.CanvasTexture {
  const tex = new THREE.CanvasTexture(canvas);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = Math.min(maxAnisotropy, 8);
  tex.needsUpdate = true;
  return tex;
}

function createCodeTexture(maxAnisotropy: number): THREE.CanvasTexture {
  const canvas = document.createElement('canvas');
  canvas.width = TEX_W;
  canvas.height = TEX_H;
  const ctx = canvas.getContext('2d')!;

  drawSheetHeader(
    ctx,
    'rgba(252, 249, 242, 0.97)',
    'rgba(45, 96, 62, 0.28)',
    '01',
    '代码与数据  Code & Data',
    '#2D603E',
    'sources/code/plot_pca.R · tables/raw.csv',
  );

  // Left Card: ggplot R Code
  drawRoundedRect(ctx, 56, 126, 610, 620, 16);
  ctx.fillStyle = '#FFFFFF';
  ctx.fill();
  ctx.lineWidth = 2.2;
  ctx.strokeStyle = 'rgba(45, 96, 62, 0.28)';
  ctx.stroke();

  ctx.fillStyle = '#2D603E';
  ctx.font = '700 21px "JetBrains Mono", monospace';
  ctx.fillText('R / plot_pca.R', 84, 170);

  ctx.strokeStyle = 'rgba(45, 96, 62, 0.14)';
  ctx.beginPath();
  ctx.moveTo(84, 196);
  ctx.lineTo(638, 196);
  ctx.stroke();

  // Highlight band around aes(colour = group) matching SHEET_ANCHORS.codeAesColour
  const aesPt = localToCanvas(
    SHEET_ANCHORS.codeAesColour.x,
    SHEET_ANCHORS.codeAesColour.z,
  );
  drawRoundedRect(ctx, 76, aesPt.py - 28, 568, 56, 8);
  ctx.fillStyle = 'rgba(223, 106, 43, 0.11)';
  ctx.fill();
  ctx.strokeStyle = 'rgba(223, 106, 43, 0.45)';
  ctx.lineWidth = 1.6;
  ctx.stroke();

  // Highlight band around geom_point() matching SHEET_ANCHORS.codeGeomPoint
  const geomPt = localToCanvas(
    SHEET_ANCHORS.codeGeomPoint.x,
    SHEET_ANCHORS.codeGeomPoint.z,
  );
  drawRoundedRect(ctx, 76, geomPt.py - 28, 568, 56, 8);
  ctx.fillStyle = 'rgba(47, 133, 90, 0.09)';
  ctx.fill();

  ctx.font = '600 22.5px "JetBrains Mono", monospace';
  ctx.fillStyle = '#DF6A2B';
  ctx.fillText('cap <- gloss(', 88, 246);
  ctx.fillStyle = '#1D2B22';
  ctx.fillText('  ggplot(df, aes(PC1, PC2,', 88, 298);
  ctx.fillStyle = '#C45720';
  ctx.fillText('         colour = group)) +', 88, aesPt.py + 2);
  ctx.fillStyle = '#2D603E';
  ctx.fillText('  geom_point(size = 3) +', 88, geomPt.py + 2);
  ctx.fillStyle = '#1D2B22';
  ctx.fillText('  theme_classic(),', 88, 536);
  ctx.fillStyle = '#5B6A60';
  ctx.fillText('  sources = list(code="plot_pca.R"),', 88, 592);
  ctx.fillText('  preview = TRUE, parent = prev_cap', 88, 636);
  ctx.fillStyle = '#DF6A2B';
  ctx.fillText(')', 88, 694);

  // Right Card: raw.csv rows aligned directly to SHEET_ANCHORS.codeRawS1/S14/S19
  drawRoundedRect(ctx, 696, 126, 528, 464, 16);
  ctx.fillStyle = '#FFFFFF';
  ctx.fill();
  ctx.lineWidth = 2.2;
  ctx.strokeStyle = 'rgba(45, 96, 62, 0.28)';
  ctx.stroke();

  ctx.fillStyle = '#2D603E';
  ctx.font = '700 20px "JetBrains Mono", monospace';
  ctx.fillText('tables/raw.csv (.parquet) · _row_id', 720, 170);

  ctx.fillStyle = '#EEF3EF';
  ctx.fillRect(718, 196, 484, 44);
  ctx.fillStyle = '#1D2B22';
  ctx.font = '700 19px "JetBrains Mono", monospace';
  ctx.fillText('_row  sample   PC1    PC2   group', 732, 224);

  const rawRows = [
    { s: PCA_SAMPLES[0], anchor: SHEET_ANCHORS.codeRawS1 },
    { s: PCA_SAMPLES[13], anchor: SHEET_ANCHORS.codeRawS14 },
    { s: PCA_SAMPLES[18], anchor: SHEET_ANCHORS.codeRawS19 },
  ];

  rawRows.forEach(({ s, anchor }) => {
    const p = localToCanvas(anchor.x, anchor.z);
    drawRoundedRect(ctx, 718, p.py - 28, 484, 56, 8);
    ctx.fillStyle =
      s.group === 'A'
        ? 'rgba(47, 133, 90, 0.09)'
        : 'rgba(223, 106, 43, 0.09)';
    ctx.fill();
    ctx.font = '600 20px "JetBrains Mono", monospace';
    ctx.fillStyle = '#1D2B22';
    ctx.fillText(
      `#${String(s.rowId).padEnd(4)} ${s.id.padEnd(6)} ${s.pc1.toFixed(1).padStart(5)}  ${s.pc2.toFixed(1).padStart(5)}`,
      732,
      p.py + 2,
    );
    ctx.fillStyle = s.colorHex;
    ctx.font = '700 20px "JetBrains Mono", monospace';
    ctx.fillText(`Group ${s.group}`, 1094, p.py + 2);
  });

  // Bottom-right Sources Metadata Box
  drawRoundedRect(ctx, 696, 612, 528, 134, 14);
  ctx.fillStyle = '#F5F0E6';
  ctx.fill();
  ctx.strokeStyle = 'rgba(45, 96, 62, 0.25)';
  ctx.stroke();

  ctx.fillStyle = '#1D2B22';
  ctx.font = '700 20px "Plus Jakarta Sans", "Noto Sans SC", sans-serif';
  ctx.fillText('来源清单 · Track B 演化链', 724, 652);
  ctx.fillStyle = '#4B5B50';
  ctx.font = '500 17.5px "JetBrains Mono", monospace';
  ctx.fillText('session.json (call_expr) · parent_capture_id', 724, 696);

  // Anchor ports where 3D mapping threads depart
  drawAnchorPort(ctx, SHEET_ANCHORS.codeAesColour.x, SHEET_ANCHORS.codeAesColour.z, '#DF6A2B');
  drawAnchorPort(ctx, SHEET_ANCHORS.codeRawS1.x, SHEET_ANCHORS.codeRawS1.z, '#2F855A');
  drawAnchorPort(ctx, SHEET_ANCHORS.codeRawS14.x, SHEET_ANCHORS.codeRawS14.z, '#DF6A2B');
  drawAnchorPort(ctx, SHEET_ANCHORS.codeSourcesRight.x, SHEET_ANCHORS.codeSourcesRight.z, '#2D603E', 8);

  ctx.fillStyle = '#5B6A60';
  ctx.font = '600 20px "Plus Jakarta Sans", "Noto Sans SC", sans-serif';
  ctx.fillText(
    '第 01 层：原始绘图脚本、CSV/Parquet 样本表、多页边界与 Track B 重算链',
    58,
    820,
  );

  return finalizeTexture(canvas, maxAnisotropy);
}

function createIrTexture(maxAnisotropy: number): THREE.CanvasTexture {
  const canvas = document.createElement('canvas');
  canvas.width = TEX_W;
  canvas.height = TEX_H;
  const ctx = canvas.getContext('2d')!;

  drawSheetHeader(
    ctx,
    'rgba(251, 248, 241, 0.95)',
    'rgba(53, 109, 74, 0.28)',
    '02',
    'Engine IR 引擎中间态 (v1.1)',
    '#356D4A',
    '_raw_row_id · row_accounting · stops',
  );

  // Left compartment: built_layer1 table
  drawRoundedRect(ctx, 56, 126, 560, 620, 16);
  ctx.fillStyle = '#FFFFFF';
  ctx.fill();
  ctx.lineWidth = 2.2;
  ctx.strokeStyle = 'rgba(45, 96, 62, 0.28)';
  ctx.stroke();

  ctx.fillStyle = '#2D603E';
  ctx.font = '700 20px "JetBrains Mono", monospace';
  ctx.fillText('built_layer1.csv (+ _raw_row_id)', 80, 168);

  ctx.fillStyle = '#EEF3EF';
  ctx.fillRect(74, 194, 524, 42);
  ctx.fillStyle = '#1D2B22';
  ctx.font = '700 17.5px "JetBrains Mono", monospace';
  ctx.fillText('_raw  sample    x     y    colour   panel', 84, 220);

  const irRows = [
    { s: PCA_SAMPLES[0], anchor: SHEET_ANCHORS.irBuiltS1 },
    { s: PCA_SAMPLES[13], anchor: SHEET_ANCHORS.irBuiltS14 },
    { s: PCA_SAMPLES[18], anchor: SHEET_ANCHORS.irBuiltS19 },
  ];

  irRows.forEach(({ s, anchor }) => {
    const p = localToCanvas(anchor.x, anchor.z);
    drawRoundedRect(ctx, 74, p.py - 32, 524, 64, 10);
    ctx.fillStyle =
      s.group === 'A'
        ? 'rgba(47, 133, 90, 0.10)'
        : 'rgba(223, 106, 43, 0.10)';
    ctx.fill();
    ctx.strokeStyle = s.colorHex + '66';
    ctx.lineWidth = 1.6;
    ctx.stroke();

    ctx.font = '600 18.5px "JetBrains Mono", monospace';
    ctx.fillStyle = '#2D603E';
    ctx.fillText(`#${String(s.rowId).padEnd(3)}`, 86, p.py + 2);
    ctx.fillStyle = '#1D2B22';
    ctx.fillText(
      `${s.id.padEnd(4)} ${s.pc1.toFixed(1).padStart(5)} ${s.pc2.toFixed(1).padStart(5)}`,
      150,
      p.py + 2,
    );
    ctx.fillStyle = s.colorHex;
    ctx.font = '700 18.5px "JetBrains Mono", monospace';
    ctx.fillText(s.colorHex, 370, p.py + 2);
    ctx.fillStyle = '#2D603E';
    ctx.fillText(s.panelId, 526, p.py + 2);
  });

  // Middle compartment: ir.scales color mapping dictionary
  drawRoundedRect(ctx, 642, 126, 292, 620, 16);
  ctx.fillStyle = '#FFFFFF';
  ctx.fill();
  ctx.strokeStyle = 'rgba(45, 96, 62, 0.32)';
  ctx.lineWidth = 2.2;
  ctx.stroke();

  ctx.fillStyle = '#2D603E';
  ctx.font = '700 22px "JetBrains Mono", monospace';
  ctx.fillText('ir.scales (v1.1)', 666, 168);

  ctx.fillStyle = '#4B5B50';
  ctx.font = '600 17.5px "JetBrains Mono", monospace';
  ctx.fillText('discrete map + 11 stops', 666, 210);
  ctx.fillText('midpoint / na_value / oob', 666, 242);
  ctx.fillText('field: group (colour)', 666, 274);

  const pScaleA = localToCanvas(SHEET_ANCHORS.irScaleA.x, SHEET_ANCHORS.irScaleA.z);
  drawRoundedRect(ctx, 664, pScaleA.py - 34, 248, 68, 12);
  ctx.fillStyle = 'rgba(47, 133, 90, 0.12)';
  ctx.fill();
  ctx.strokeStyle = '#2F855A';
  ctx.lineWidth = 2;
  ctx.stroke();
  ctx.fillStyle = '#1D2B22';
  ctx.font = '700 21px "JetBrains Mono", monospace';
  ctx.fillText('A → #2F855A', 762, pScaleA.py + 2);

  const pScaleB = localToCanvas(SHEET_ANCHORS.irScaleB.x, SHEET_ANCHORS.irScaleB.z);
  drawRoundedRect(ctx, 664, pScaleB.py - 34, 248, 68, 12);
  ctx.fillStyle = 'rgba(223, 106, 43, 0.12)';
  ctx.fill();
  ctx.strokeStyle = '#DF6A2B';
  ctx.lineWidth = 2;
  ctx.stroke();
  ctx.fillStyle = '#1D2B22';
  ctx.fillText('B → #DF6A2B', 762, pScaleB.py + 2);

  ctx.fillStyle = '#4B5B50';
  ctx.font = '600 17.5px "Plus Jakarta Sans", "Noto Sans SC", sans-serif';
  ctx.fillText('原子联动至：', 666, 622);
  ctx.fillText('• ir.guides.entries 图例项', 666, 658);
  ctx.fillText('• 散点图层 L004 / L005', 666, 694);

  // Right compartment: ir.layers & row_accounting
  drawRoundedRect(ctx, 960, 126, 264, 620, 16);
  ctx.fillStyle = '#FFFFFF';
  ctx.fill();
  ctx.strokeStyle = 'rgba(45, 96, 62, 0.28)';
  ctx.stroke();

  ctx.fillStyle = '#2D603E';
  ctx.font = '700 20px "JetBrains Mono", monospace';
  ctx.fillText('layers / accounting', 978, 168);

  const badges = [
    'geom: GeomPoint',
    'params: size=3',
    'n_raw=20 n_built=20',
    'dropped: NA=0 OOB=0',
    'groups_*.json / orders',
  ];
  ctx.font = '600 16.5px "JetBrains Mono", monospace';
  badges.forEach((b, idx) => {
    drawRoundedRect(ctx, 976, 218 + idx * 78, 232, 56, 10);
    ctx.fillStyle = idx === 3 ? '#FBF4EC' : '#F5F0E6';
    ctx.fill();
    ctx.fillStyle = idx === 3 ? '#B9501B' : '#1D2B22';
    ctx.fillText(b, 990, 250 + idx * 78);
  });

  // Exact anchor ports
  drawAnchorPort(ctx, SHEET_ANCHORS.irBuiltS1.x, SHEET_ANCHORS.irBuiltS1.z, '#2F855A');
  drawAnchorPort(ctx, SHEET_ANCHORS.irBuiltS14.x, SHEET_ANCHORS.irBuiltS14.z, '#DF6A2B');
  drawAnchorPort(ctx, SHEET_ANCHORS.irScaleA.x, SHEET_ANCHORS.irScaleA.z, '#2F855A', 12);
  drawAnchorPort(ctx, SHEET_ANCHORS.irScaleB.x, SHEET_ANCHORS.irScaleB.z, '#DF6A2B', 12);
  drawAnchorPort(ctx, SHEET_ANCHORS.irExportRight.x, SHEET_ANCHORS.irExportRight.z, '#DF6A2B', 8);

  ctx.fillStyle = '#5B6A60';
  ctx.font = '600 20px "Plus Jakarta Sans", "Noto Sans SC", sans-serif';
  ctx.fillText(
    '第 02 层：直读 _raw_row_id 行桥、stat_params、row_accounting 丢行账本与色板',
    58,
    820,
  );

  return finalizeTexture(canvas, maxAnisotropy);
}

function createPanelsTexture(maxAnisotropy: number): THREE.CanvasTexture {
  const canvas = document.createElement('canvas');
  canvas.width = TEX_W;
  canvas.height = TEX_H;
  const ctx = canvas.getContext('2d')!;

  drawSheetHeader(
    ctx,
    'rgba(250, 248, 242, 0.84)',
    'rgba(70, 125, 88, 0.28)',
    '03',
    '面板布局  Panels',
    '#467D58',
    'viewport probe · P1 / P2 bbox_pt',
  );

  const tl = localToCanvas(PLOT_LOCAL_BOUNDS.minX, PLOT_LOCAL_BOUNDS.minZ);
  const br = localToCanvas(PLOT_LOCAL_BOUNDS.maxX, PLOT_LOCAL_BOUNDS.maxZ);
  const pw = br.px - tl.px;
  const ph = br.py - tl.py;

  // Fine meridian/parallel grid matching [-10, -5, 0, 5, 10]
  ctx.fillStyle = 'rgba(45, 96, 62, 0.045)';
  ctx.fillRect(tl.px, tl.py, pw, ph);

  ctx.strokeStyle = 'rgba(45, 96, 62, 0.22)';
  ctx.lineWidth = 1.6;
  for (const val of [-10, -5, 0, 5, 10]) {
    const gx = localToCanvas(mapDataToPlateLocal(val, 0).x, 0).px;
    ctx.beginPath();
    ctx.moveTo(gx, tl.py);
    ctx.lineTo(gx, br.py);
    ctx.stroke();

    const gy = localToCanvas(0, mapDataToPlateLocal(0, val).z).py;
    ctx.beginPath();
    ctx.moveTo(tl.px, gy);
    ctx.lineTo(br.px, gy);
    ctx.stroke();
  }

  // Exact P1 and P2 dashed viewport boxes aligned to getPanelSubRects()
  const { p1, p2 } = getPanelSubRects();
  const p1TL = localToCanvas(p1.minX, p1.minZ);
  const p1BR = localToCanvas(p1.maxX, p1.maxZ);
  const p2TL = localToCanvas(p2.minX, p2.minZ);
  const p2BR = localToCanvas(p2.maxX, p2.maxZ);

  ctx.save();
  ctx.setLineDash([14, 9]);
  ctx.lineWidth = 4;
  ctx.strokeStyle = '#2F855A';
  ctx.fillStyle = 'rgba(47, 133, 90, 0.06)';
  ctx.fillRect(p1TL.px, p1TL.py, p1BR.px - p1TL.px, p1BR.py - p1TL.py);
  ctx.strokeRect(p1TL.px, p1TL.py, p1BR.px - p1TL.px, p1BR.py - p1TL.py);

  ctx.strokeStyle = '#DF6A2B';
  ctx.fillStyle = 'rgba(223, 106, 43, 0.06)';
  ctx.fillRect(p2TL.px, p2TL.py, p2BR.px - p2TL.px, p2BR.py - p2TL.py);
  ctx.strokeRect(p2TL.px, p2TL.py, p2BR.px - p2TL.px, p2BR.py - p2TL.py);
  ctx.restore();

  // Corner registration pins at P1 & P2 corners (exact base of 3D vertical meridian lines)
  for (const [cx, cz] of [
    [p1.minX, p1.minZ],
    [p1.maxX, p1.minZ],
    [p1.minX, p1.maxZ],
    [p1.maxX, p1.maxZ],
  ]) {
    drawAnchorPort(ctx, cx, cz, '#2F855A', 7);
  }
  for (const [cx, cz] of [
    [p2.minX, p2.minZ],
    [p2.maxX, p2.minZ],
    [p2.minX, p2.maxZ],
    [p2.maxX, p2.maxZ],
  ]) {
    drawAnchorPort(ctx, cx, cz, '#DF6A2B', 7);
  }

  ctx.fillStyle = '#234F33';
  ctx.font = '700 26px "JetBrains Mono", monospace';
  ctx.fillText('Panel P1', p1TL.px + 26, p1TL.py + 52);
  ctx.font = '600 18px "JetBrains Mono", monospace';
  ctx.fillStyle = '#3B4D42';
  ctx.fillText('PC1: [-10, 0]', p1TL.px + 26, p1TL.py + 88);
  ctx.fillText('slot: panel-1-1', p1TL.px + 26, p1TL.py + 118);

  ctx.fillStyle = '#C45720';
  ctx.font = '700 26px "JetBrains Mono", monospace';
  ctx.fillText('Panel P2', p2TL.px + 26, p2TL.py + 52);
  ctx.font = '600 18px "JetBrains Mono", monospace';
  ctx.fillStyle = '#3B4D42';
  ctx.fillText('PC1: [0, 10]', p2TL.px + 26, p2TL.py + 88);
  ctx.fillText('slot: panel-1-2', p2TL.px + 26, p2TL.py + 118);

  // Right spec notes (Schema v1.1 scene.coord & dual domain)
  ctx.fillStyle = '#1D2B22';
  ctx.font = '700 22px "Plus Jakarta Sans", "Noto Sans SC", sans-serif';
  ctx.fillText('统一坐标逆变换', br.px + 34, tl.py + 46);
  ctx.fillStyle = '#2D603E';
  ctx.font = '700 17.5px "JetBrains Mono", monospace';
  ctx.fillText('origin: top-left (y↓)', br.px + 34, tl.py + 88);
  ctx.fillStyle = '#4B5B50';
  ctx.font = '600 17.5px "JetBrains Mono", monospace';
  ctx.fillText('domain_space:', br.px + 34, tl.py + 128);
  ctx.fillText('  "transformed"', br.px + 34, tl.py + 158);
  ctx.fillText('x_data_domain:', br.px + 34, tl.py + 196);
  ctx.fillText('  [-10, 10]', br.px + 34, tl.py + 226);
  ctx.fillText('x_axis_group: s_x_1', br.px + 34, tl.py + 266);
  ctx.fillStyle = '#DF6A2B';
  ctx.font = '700 16.5px "Plus Jakarta Sans", "Noto Sans SC", sans-serif';
  ctx.fillText('支撑光栅逆投影反查', br.px + 34, tl.py + 312);

  return finalizeTexture(canvas, maxAnisotropy);
}

function drawPlotAxesAndLegend(
  ctx: CanvasRenderingContext2D,
  filledLegend: boolean,
  showSubGrid: boolean,
) {
  const tl = localToCanvas(PLOT_LOCAL_BOUNDS.minX, PLOT_LOCAL_BOUNDS.minZ);
  const br = localToCanvas(PLOT_LOCAL_BOUNDS.maxX, PLOT_LOCAL_BOUNDS.maxZ);
  const pw = br.px - tl.px;
  const ph = br.py - tl.py;

  if (showSubGrid) {
    ctx.strokeStyle = 'rgba(45, 96, 62, 0.14)';
    ctx.lineWidth = 1.4;
    for (const val of [-5, 0, 5, 10]) {
      const gx = localToCanvas(mapDataToPlateLocal(val, 0).x, 0).px;
      ctx.beginPath();
      ctx.moveTo(gx, tl.py);
      ctx.lineTo(gx, br.py);
      ctx.stroke();

      const gy = localToCanvas(0, mapDataToPlateLocal(0, val).z).py;
      ctx.beginPath();
      ctx.moveTo(tl.px, gy);
      ctx.lineTo(br.px, gy);
      ctx.stroke();
    }
  }

  // Crisp classic L-axes
  ctx.strokeStyle = '#1D2B22';
  ctx.lineWidth = 4.5;
  ctx.beginPath();
  ctx.moveTo(tl.px, tl.py);
  ctx.lineTo(tl.px, br.py);
  ctx.lineTo(br.px, br.py);
  ctx.stroke();

  const ticks = [-10, -5, 0, 5, 10];
  ctx.fillStyle = '#1D2B22';
  ctx.font = '700 22px "JetBrains Mono", monospace';

  ticks.forEach((val) => {
    const posX = mapDataToPlateLocal(val, -10);
    const cX = localToCanvas(posX.x, posX.z);
    ctx.beginPath();
    ctx.moveTo(cX.px, br.py);
    ctx.lineTo(cX.px, br.py + 14);
    ctx.stroke();
    ctx.textAlign = 'center';
    ctx.fillText(String(val), cX.px, br.py + 42);

    const posY = mapDataToPlateLocal(-10, val);
    const cY = localToCanvas(posY.x, posY.z);
    ctx.beginPath();
    ctx.moveTo(tl.px - 14, cY.py);
    ctx.lineTo(tl.px, cY.py);
    ctx.stroke();
    ctx.textAlign = 'right';
    ctx.fillText(String(val), tl.px - 22, cY.py + 8);
  });

  ctx.textAlign = 'center';
  ctx.font = '700 26px "Plus Jakarta Sans", sans-serif';
  ctx.fillText('PC1', tl.px + pw / 2, br.py + 84);

  ctx.save();
  ctx.translate(tl.px - 84, tl.py + ph / 2);
  ctx.rotate(-Math.PI / 2);
  ctx.fillText('PC2', 0, 0);
  ctx.restore();

  // Legend / Guide box aligned directly to SHEET_ANCHORS.legendGroupA / legendGroupB
  const legA = localToCanvas(SHEET_ANCHORS.legendGroupA.x, SHEET_ANCHORS.legendGroupA.z);
  const legB = localToCanvas(SHEET_ANCHORS.legendGroupB.x, SHEET_ANCHORS.legendGroupB.z);
  const boxX = legA.px - 44;
  const boxY = legA.py - 76;

  drawRoundedRect(ctx, boxX, boxY, 198, 186, 14);
  ctx.fillStyle = 'rgba(255, 255, 255, 0.92)';
  ctx.fill();
  ctx.lineWidth = 2.2;
  ctx.strokeStyle = 'rgba(45, 96, 62, 0.42)';
  ctx.stroke();

  ctx.textAlign = 'left';
  ctx.fillStyle = '#1D2B22';
  ctx.font = '700 24px "Plus Jakarta Sans", sans-serif';
  ctx.fillText('Group', boxX + 24, boxY + 38);

  if (filledLegend) {
    ctx.beginPath();
    ctx.arc(legA.px, legA.py, 14, 0, Math.PI * 2);
    ctx.fillStyle = '#2F855A';
    ctx.fill();
    ctx.beginPath();
    ctx.arc(legB.px, legB.py, 14, 0, Math.PI * 2);
    ctx.fillStyle = '#DF6A2B';
    ctx.fill();
  } else {
    drawAnchorPort(ctx, SHEET_ANCHORS.legendGroupA.x, SHEET_ANCHORS.legendGroupA.z, '#2F855A', 12);
    drawAnchorPort(ctx, SHEET_ANCHORS.legendGroupB.x, SHEET_ANCHORS.legendGroupB.z, '#DF6A2B', 12);
  }

  ctx.fillStyle = '#1D2B22';
  ctx.font = '700 22px "Plus Jakarta Sans", sans-serif';
  ctx.fillText('A (Control)', legA.px + 28, legA.py + 8);
  ctx.fillText('B (Treated)', legB.px + 28, legB.py + 8);
}

function createAxesTexture(maxAnisotropy: number): THREE.CanvasTexture {
  const canvas = document.createElement('canvas');
  canvas.width = TEX_W;
  canvas.height = TEX_H;
  const ctx = canvas.getContext('2d')!;

  drawSheetHeader(
    ctx,
    'rgba(251, 249, 243, 0.82)',
    'rgba(89, 138, 103, 0.28)',
    '04',
    '坐标、图例与语义锁',
    '#598A67',
    'edit_policy · ir.guides.entries · texts.json',
  );

  drawPlotAxesAndLegend(ctx, false, true);

  // Schema v1.1 edit_policy & texts.json callout below legend
  const br = localToCanvas(PLOT_LOCAL_BOUNDS.maxX, PLOT_LOCAL_BOUNDS.maxZ);
  const tl = localToCanvas(PLOT_LOCAL_BOUNDS.minX, PLOT_LOCAL_BOUNDS.minZ);
  drawRoundedRect(ctx, br.px + 32, tl.py + 246, 206, 178, 12);
  ctx.fillStyle = '#F5F0E6';
  ctx.fill();
  ctx.strokeStyle = 'rgba(89, 138, 103, 0.42)';
  ctx.lineWidth = 1.8;
  ctx.stroke();

  ctx.fillStyle = '#2D603E';
  ctx.font = '700 17.5px "JetBrains Mono", monospace';
  ctx.fillText('texts.json (<10 KB)', br.px + 46, tl.py + 282);
  ctx.fillStyle = '#1D2B22';
  ctx.font = '600 16px "JetBrains Mono", monospace';
  ctx.fillText('• geometry_locked', br.px + 46, tl.py + 318);
  ctx.fillStyle = '#DF6A2B';
  ctx.fillText('• movable + links', br.px + 46, tl.py + 350);
  ctx.fillStyle = '#4B5B50';
  ctx.fillText('• z_index / clipBox', br.px + 46, tl.py + 382);

  return finalizeTexture(canvas, maxAnisotropy);
}

function createLayersTexture(maxAnisotropy: number): THREE.CanvasTexture {
  const canvas = document.createElement('canvas');
  canvas.width = TEX_W;
  canvas.height = TEX_H;
  const ctx = canvas.getContext('2d')!;

  drawSheetHeader(
    ctx,
    'rgba(252, 250, 244, 0.78)',
    'rgba(223, 106, 43, 0.34)',
    '05',
    '图层  Layers',
    '#DF6A2B',
    'GeomPoint (stat = identity) · L004 / L005',
  );

  const tl = localToCanvas(PLOT_LOCAL_BOUNDS.minX, PLOT_LOCAL_BOUNDS.minZ);
  const br = localToCanvas(PLOT_LOCAL_BOUNDS.maxX, PLOT_LOCAL_BOUNDS.maxZ);

  // Subtle coordinate frame & dashed leaf-group envelopes
  ctx.strokeStyle = 'rgba(45, 96, 62, 0.16)';
  ctx.lineWidth = 1.5;
  ctx.strokeRect(tl.px, tl.py, br.px - tl.px, br.py - tl.py);

  ctx.save();
  ctx.setLineDash([10, 7]);
  ctx.lineWidth = 2.6;
  ctx.strokeStyle = 'rgba(47, 133, 90, 0.68)';
  ctx.fillStyle = 'rgba(47, 133, 90, 0.06)';
  drawRoundedRect(ctx, tl.px + 96, tl.py + 230, 306, 302, 24);
  ctx.fill();
  ctx.stroke();

  ctx.strokeStyle = 'rgba(223, 106, 43, 0.68)';
  ctx.fillStyle = 'rgba(223, 106, 43, 0.06)';
  drawRoundedRect(ctx, tl.px + 492, tl.py + 34, 272, 314, 24);
  ctx.fill();
  ctx.stroke();
  ctx.restore();

  // Crisp flat 2D scatter markers on Layer 5
  PCA_SAMPLES.forEach((s) => {
    const local = mapDataToPlateLocal(s.pc1, s.pc2);
    const pt = localToCanvas(local.x, local.z);
    ctx.beginPath();
    ctx.arc(pt.px, pt.py, 14, 0, Math.PI * 2);
    ctx.fillStyle = s.colorHex;
    ctx.fill();
    ctx.lineWidth = 2.5;
    ctx.strokeStyle = '#FCF9F3';
    ctx.stroke();

    if (s.id === 'S1' || s.id === 'S14' || s.id === 'S19') {
      ctx.fillStyle = '#1D2B22';
      ctx.font = '700 17px "JetBrains Mono", monospace';
      ctx.fillText(s.id, pt.px + 18, pt.py + 5);
    }
  });

  ctx.fillStyle = '#234F33';
  ctx.font = '700 20px "JetBrains Mono", monospace';
  ctx.fillText('L004 · Group A (10)', tl.px + 112, tl.py + 260);

  ctx.fillStyle = '#C45720';
  ctx.fillText('L005 · Group B (10)', tl.px + 510, tl.py + 66);

  // Right spec block (Schema v1.1 row bridge + lineage tier)
  ctx.fillStyle = '#1D2B22';
  ctx.font = '700 22px "JetBrains Mono", monospace';
  ctx.fillText('GeomPoint', br.px + 34, tl.py + 58);
  ctx.fillStyle = '#4B5B50';
  ctx.font = '600 17.5px "JetBrains Mono", monospace';
  ctx.fillText('cardinality: 1:1', br.px + 34, tl.py + 96);
  ctx.fillText('tier: row_exact', br.px + 34, tl.py + 130);
  ctx.fillText('part_role: point', br.px + 34, tl.py + 164);
  ctx.fillStyle = '#2D603E';
  ctx.fillText('built_row_id: 1..20', br.px + 34, tl.py + 198);
  ctx.fillStyle = '#DF6A2B';
  ctx.font = '700 17px "Plus Jakarta Sans", "Noto Sans SC", sans-serif';
  ctx.fillText('点击任意散点', br.px + 34, tl.py + 250);
  ctx.fillText('追踪 6 层完整血缘', br.px + 34, tl.py + 280);

  return finalizeTexture(canvas, maxAnisotropy);
}

function createSvgTexture(maxAnisotropy: number): THREE.CanvasTexture {
  const canvas = document.createElement('canvas');
  canvas.width = TEX_W;
  canvas.height = TEX_H;
  const ctx = canvas.getContext('2d')!;

  drawSheetHeader(
    ctx,
    'rgba(255, 254, 250, 0.96)',
    'rgba(35, 79, 51, 0.34)',
    '06',
    '结构化场景  <svg id="scene.svg">',
    '#234F33',
    '18 leaves · 2 panels · 412 elements',
  );

  drawPlotAxesAndLegend(ctx, true, true);

  // Draw crisp final SVG scatter markers
  PCA_SAMPLES.forEach((s) => {
    const local = mapDataToPlateLocal(s.pc1, s.pc2);
    const pt = localToCanvas(local.x, local.z);
    ctx.beginPath();
    ctx.arc(pt.px, pt.py, 14, 0, Math.PI * 2);
    ctx.fillStyle = s.colorHex;
    ctx.fill();
    ctx.lineWidth = 2.8;
    ctx.strokeStyle = '#FCF9F3';
    ctx.stroke();

    if (s.id === 'S1' || s.id === 'S14' || s.id === 'S19') {
      ctx.fillStyle = '#1D2B22';
      ctx.font = '700 17px "JetBrains Mono", monospace';
      ctx.fillText(s.id, pt.px + 18, pt.py + 5);
    }
  });

  // Addressable metadata callout under legend (Tri-modal v1.1)
  const br = localToCanvas(PLOT_LOCAL_BOUNDS.maxX, PLOT_LOCAL_BOUNDS.maxZ);
  const tl = localToCanvas(PLOT_LOCAL_BOUNDS.minX, PLOT_LOCAL_BOUNDS.minZ);
  drawRoundedRect(ctx, br.px + 32, tl.py + 248, 206, 174, 12);
  ctx.fillStyle = '#F5F0E6';
  ctx.fill();
  ctx.strokeStyle = 'rgba(45, 96, 62, 0.35)';
  ctx.lineWidth = 1.8;
  ctx.stroke();

  ctx.fillStyle = '#234F33';
  ctx.font = '700 18px "JetBrains Mono", monospace';
  ctx.fillText('L001..L018 (v1.1)', br.px + 46, tl.py + 284);
  ctx.fillStyle = '#4B5B50';
  ctx.font = '600 16.5px "Plus Jakarta Sans", "Noto Sans SC", sans-serif';
  ctx.fillText('original.svg 基准', br.px + 46, tl.py + 318);
  ctx.fillText('scene.svg 可寻址', br.px + 46, tl.py + 350);
  ctx.fillStyle = '#DF6A2B';
  ctx.fillText('preview.png (144dpi)', br.px + 46, tl.py + 384);

  return finalizeTexture(canvas, maxAnisotropy);
}

export function createAllPlateTextures(
  maxAnisotropy: number,
): Record<LayerId, THREE.CanvasTexture> {
  return {
    code: createCodeTexture(maxAnisotropy),
    ir: createIrTexture(maxAnisotropy),
    panels: createPanelsTexture(maxAnisotropy),
    axes: createAxesTexture(maxAnisotropy),
    layers: createLayersTexture(maxAnisotropy),
    svg: createSvgTexture(maxAnisotropy),
  };
}

export function createAssetCardTexture(
  kind: AssetNodeId,
  maxAnisotropy: number,
): THREE.CanvasTexture {
  const canvas = document.createElement('canvas');
  canvas.width = 640;
  canvas.height = 480;
  const ctx = canvas.getContext('2d')!;

  const accent =
    kind === 'asset-map'
      ? '#DF6A2B'
      : kind === 'asset-bundle'
        ? '#2D603E'
        : '#315C6B';
  const strokeRgba =
    kind === 'asset-map'
      ? 'rgba(223, 106, 43, 0.38)'
      : kind === 'asset-bundle'
        ? 'rgba(45, 96, 62, 0.36)'
        : 'rgba(49, 92, 107, 0.42)';

  ctx.clearRect(0, 0, 640, 480);

  ctx.save();
  drawRoundedRect(ctx, 10, 10, 620, 460, 26);
  ctx.fillStyle = '#FCF9F3';
  ctx.fill();

  ctx.save();
  ctx.clip();
  ctx.fillStyle = accent;
  ctx.globalAlpha = 0.84;
  ctx.fillRect(10, 10, 620, 6);
  ctx.restore();

  drawRoundedRect(ctx, 10, 10, 620, 460, 26);
  ctx.lineWidth = 2;
  ctx.strokeStyle = strokeRgba;
  ctx.stroke();
  ctx.restore();

  drawRoundedRect(ctx, 32, 34, 576, 68, 14);
  ctx.fillStyle = accent;
  ctx.fill();

  ctx.fillStyle = '#FCF9F3';
  ctx.font = '700 24px "Plus Jakarta Sans", "Noto Sans SC", sans-serif';
  ctx.textBaseline = 'middle';
  ctx.fillText(
    kind === 'asset-map'
      ? '① 异构感知索引 · Asset Map'
      : kind === 'asset-bundle'
        ? '② 只读开放源包 · figure.gloss/'
        : '③ 旁侧协作态 · figure.gloss.work/',
    48,
    68,
  );

  ctx.fillStyle = '#1D2B22';
  ctx.font = '700 20px "JetBrains Mono", monospace';
  ctx.fillText(
    kind === 'asset-map'
      ? 'asset-map.json (v1.1.0 · ≈24 KB)'
      : kind === 'asset-bundle'
        ? 'manifest.json (capture_id · sha256)'
        : 'workspace.json (Track A / Track B)',
    40,
    142,
  );

  const lines =
    kind === 'asset-map'
      ? [
          '{ "scene": { coord, texts(<10KB), preview },',
          '  "ir": { panels(2x域), layers(row_acc) },',
          '  "scales": [ map + 11 stops ],',
          '  "guides": [ item swatch/label IDs ],',
          '  "lineage": [ edit_policy / row_exact ] }'
        ]
      : kind === 'asset-bundle'
        ? [
            '├── manifest.json (parent_capture_id)',
            '├── assets/original.svg + preview.png',
            '├── scene/scene.svg + texts.json + leaves',
            '├── tables/raw + built(_raw) + groups_*',
            '└── sources/ (call_expr) + omitted.json',
          ]
        : [
            '├── workspace.json (源包 sha256 只读锚)',
            '├── focus.json (box↔rows 双向指代契约)',
            '├── threads.json (审计问题单/人工裁决)',
            '├── patches/ (声明式 Visual Patch JSON)',
            '└── derived/ (精修 SVG + 零位移回执)',
          ];

  ctx.fillStyle = '#33463A';
  ctx.font = '600 18.5px "JetBrains Mono", monospace';
  lines.forEach((line, idx) => {
    ctx.fillText(line, 40, 196 + idx * 46);
  });

  return finalizeTexture(canvas, maxAnisotropy);
}

export function createContactShadowTexture(): THREE.CanvasTexture {
  const size = 256;
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext('2d')!;

  ctx.clearRect(0, 0, size, size);
  // Soft feathered rounded-card drop shadow for airy floating sheet elevation
  ctx.save();
  ctx.filter = 'blur(18px)';
  drawRoundedRect(ctx, 36, 36, size - 72, size - 72, 24);
  ctx.fillStyle = 'rgba(29, 43, 34, 0.22)';
  ctx.fill();
  ctx.restore();

  // Gentle ambient outer bloom
  const grad = ctx.createRadialGradient(
    size / 2,
    size / 2,
    size * 0.14,
    size / 2,
    size / 2,
    size * 0.5,
  );
  grad.addColorStop(0, 'rgba(29, 43, 34, 0.08)');
  grad.addColorStop(0.65, 'rgba(29, 43, 34, 0.03)');
  grad.addColorStop(1, 'rgba(29, 43, 34, 0)');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, size, size);

  const tex = new THREE.CanvasTexture(canvas);
  tex.needsUpdate = true;
  return tex;
}

export function createStudioFloorTexture(
  maxAnisotropy: number,
): THREE.CanvasTexture {
  const size = 512;
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext('2d')!;

  ctx.fillStyle = '#F2ECE0';
  ctx.fillRect(0, 0, size, size);

  ctx.strokeStyle = 'rgba(45, 96, 62, 0.06)';
  ctx.lineWidth = 1.5;
  const step = 64;
  for (let i = 0; i <= size; i += step) {
    ctx.beginPath();
    ctx.moveTo(i, 0);
    ctx.lineTo(i, size);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(0, i);
    ctx.lineTo(size, i);
    ctx.stroke();
  }

  const tex = new THREE.CanvasTexture(canvas);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.wrapS = THREE.RepeatWrapping;
  tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(16, 16);
  tex.anisotropy = Math.min(maxAnisotropy, 8);
  tex.needsUpdate = true;
  return tex;
}
