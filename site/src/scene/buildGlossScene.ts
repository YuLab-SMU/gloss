import * as THREE from 'three';
import {
  ARCHITECTURE_LAYERS,
  PCA_SAMPLES,
  type AssetNodeId,
  type LayerId,
} from '../data/glossModel';
import {
  BASE_STACK_Y,
  PLATE_DEPTH,
  PLATE_WIDTH,
  mapDataToPlateLocal,
  type LayerTransform,
  type LayoutMode,
} from './layoutMath';
import {
  SHEET_ANCHORS,
  computeMappingPaths,
  computeMeridianGridLines,
  type MappingFocusMode,
} from './mappingPaths';
import {
  createAllPlateTextures,
  createAssetCardTexture,
  createContactShadowTexture,
  createStudioFloorTexture,
} from './plateTextures';

export interface LayerRig {
  id: LayerId;
  group: THREE.Group;
  sheetMesh: THREE.Mesh;
  tileShadowMesh: THREE.Mesh;
  sheetMaterial: THREE.MeshBasicMaterial;
  borderMaterial: THREE.LineBasicMaterial;
  baseOpacity: number;
  baseBorderColor: THREE.Color;
}

export interface PointHitRig {
  sampleId: string;
  layerRing: THREE.Mesh;
  svgRing: THREE.Mesh;
  baseColor: THREE.Color;
  localX: number;
  localZ: number;
}

export interface AssetNodeRig {
  id: AssetNodeId;
  group: THREE.Group;
  borderMaterial: THREE.LineBasicMaterial;
  baseColor: THREE.Color;
  calloutAnchor: THREE.Vector3;
}

export interface BuiltGlossScene {
  rootGroup: THREE.Group;
  mainShadow: THREE.Mesh;
  layerRigs: Record<LayerId, LayerRig>;
  pointHits: PointHitRig[];
  assetNodes: Record<AssetNodeId, AssetNodeRig>;
  interactables: THREE.Object3D[];
  updateMappings: (
    transforms: Record<LayerId, LayerTransform>,
    mode: MappingFocusMode,
    tracedSampleId: string | null,
    layoutMode?: LayoutMode,
  ) => void;
  stepFlow: (elapsedSec: number) => void;
  dispose: () => void;
}

function createRectBorderGeometry(w: number, d: number): THREE.BufferGeometry {
  const hw = w / 2;
  const hd = d / 2;
  const pts = [
    new THREE.Vector3(-hw, 0, -hd),
    new THREE.Vector3(hw, 0, -hd),
    new THREE.Vector3(hw, 0, hd),
    new THREE.Vector3(-hw, 0, hd),
  ];
  return new THREE.BufferGeometry().setFromPoints(pts);
}

function createRoundedRectBorderGeometry(
  w: number,
  d: number,
  radius: number,
  segmentsPerCorner = 8,
): THREE.BufferGeometry {
  const hw = w / 2;
  const hd = d / 2;
  const r = Math.min(radius, hw * 0.45, hd * 0.45);
  const pts: THREE.Vector3[] = [];
  const corners: [number, number, number, number][] = [
    [hw - r, -hd + r, -Math.PI / 2, 0],
    [hw - r, hd - r, 0, Math.PI / 2],
    [-hw + r, hd - r, Math.PI / 2, Math.PI],
    [-hw + r, -hd + r, Math.PI, Math.PI * 1.5],
  ];
  for (const [cx, cz, startA, endA] of corners) {
    for (let i = 0; i <= segmentsPerCorner; i++) {
      const a = startA + ((endA - startA) * i) / segmentsPerCorner;
      pts.push(new THREE.Vector3(cx + Math.cos(a) * r, 0, cz + Math.sin(a) * r));
    }
  }
  return new THREE.BufferGeometry().setFromPoints(pts);
}

export function buildGlossScene(
  scene: THREE.Scene,
  maxAnisotropy: number,
): BuiltGlossScene {
  const disposables: { dispose: () => void }[] = [];
  const track = <T extends { dispose: () => void }>(res: T): T => {
    disposables.push(res);
    return res;
  };

  const rootGroup = new THREE.Group();
  scene.add(rootGroup);

  const interactables: THREE.Object3D[] = [];

  // 1. Subtle Archival Drafting Ground & Soft Contact Shadow (no heavy 3D plinths)
  const floorTex = track(createStudioFloorTexture(maxAnisotropy));
  const floorMesh = new THREE.Mesh(
    track(new THREE.PlaneGeometry(110, 110)),
    track(
      new THREE.MeshBasicMaterial({
        map: floorTex,
        color: 0xffffff,
      }),
    ),
  );
  floorMesh.rotation.x = -Math.PI / 2;
  floorMesh.position.y = 0;
  rootGroup.add(floorMesh);

  const contactTex = track(createContactShadowTexture());
  const contactMat = track(
    new THREE.MeshBasicMaterial({
      map: contactTex,
      transparent: true,
      depthWrite: false,
      opacity: 0.72,
    }),
  );

  const mainShadow = new THREE.Mesh(
    track(new THREE.PlaneGeometry(PLATE_WIDTH * 1.38, PLATE_DEPTH * 1.38)),
    contactMat,
  );
  mainShadow.rotation.x = -Math.PI / 2;
  mainShadow.position.set(0, 0.01, 0);
  rootGroup.add(mainShadow);

  // 2. Six Razor-Thin Flat 2D Architectural Sheets (true-color crisp unlit rendering)
  const plateTextures = createAllPlateTextures(maxAnisotropy);
  Object.values(plateTextures).forEach((t) => track(t));

  const sharedSheetGeo = track(new THREE.PlaneGeometry(PLATE_WIDTH, PLATE_DEPTH));
  const sharedTileShadowGeo = track(
    new THREE.PlaneGeometry(PLATE_WIDTH * 1.18, PLATE_DEPTH * 1.2),
  );
  // Matches the exact 8px-inset, 30px-radius rounded archival card painted in plateTextures.ts
  const cardInsetW = (16 / 1280) * PLATE_WIDTH;
  const cardInsetD = (16 / 908) * PLATE_DEPTH;
  const cardCornerR = (30 / 1280) * PLATE_WIDTH;
  const sharedBorderGeo = track(
    createRoundedRectBorderGeometry(
      PLATE_WIDTH - cardInsetW + 0.025,
      PLATE_DEPTH - cardInsetD + 0.025,
      cardCornerR + 0.01,
    ),
  );

  const layerRigs = {} as Record<LayerId, LayerRig>;

  ARCHITECTURE_LAYERS.forEach((layerSpec, idx) => {
    const group = new THREE.Group();
    group.position.y = BASE_STACK_Y + idx * 1.02;

    // Translucent architectural vellum on Layers 2-6 so inter-layer 经纬线 & Layer 1->2 threads stay unbroken
    const baseOpacity =
      layerSpec.id === 'code'
        ? 0.96
        : layerSpec.id === 'svg'
          ? 0.92
          : layerSpec.id === 'ir'
            ? 0.86
            : 0.78;

    const sheetMaterial = track(
      new THREE.MeshBasicMaterial({
        map: plateTextures[layerSpec.id],
        transparent: true,
        alphaTest: 0.015,
        opacity: baseOpacity,
        side: THREE.DoubleSide,
        depthWrite: layerSpec.id === 'code',
      }),
    );

    const sheetMesh = new THREE.Mesh(sharedSheetGeo, sheetMaterial);
    sheetMesh.rotation.x = -Math.PI / 2;
    sheetMesh.renderOrder = idx + 1;
    sheetMesh.userData = { interactType: 'layer', layerId: layerSpec.id };
    group.add(sheetMesh);
    interactables.push(sheetMesh);

    // Per-tile soft feathered shadow (responds smoothly to hover lift in tiled mode)
    const tileShadowMat = track(
      new THREE.MeshBasicMaterial({
        map: contactTex,
        transparent: true,
        depthWrite: false,
        opacity: 0.44,
      }),
    );
    const tileShadowMesh = new THREE.Mesh(sharedTileShadowGeo, tileShadowMat);
    tileShadowMesh.rotation.x = -Math.PI / 2;
    tileShadowMesh.position.set(0.05, -0.025, 0.1);
    tileShadowMesh.visible = false;
    tileShadowMesh.renderOrder = 0;
    group.add(tileShadowMesh);

    // Matching rounded hover/focus highlight rim — invisible at rest so cards keep a single crisp hairline border
    const baseBorderColor = new THREE.Color(layerSpec.accentHex);
    const borderMaterial = track(
      new THREE.LineBasicMaterial({
        color: baseBorderColor,
        transparent: true,
        opacity: 0,
        depthWrite: false,
      }),
    );
    const borderLoop = new THREE.LineLoop(sharedBorderGeo, borderMaterial);
    borderLoop.position.y = 0.008;
    borderLoop.renderOrder = idx + 2;
    group.add(borderLoop);

    rootGroup.add(group);
    layerRigs[layerSpec.id] = {
      id: layerSpec.id,
      group,
      sheetMesh,
      tileShadowMesh,
      sheetMaterial,
      borderMaterial,
      baseOpacity,
      baseBorderColor,
    };
  });

  // 3. Flush 2D Interactive Sample Selection Rings on Layer 5 (Layers) & Layer 6 (SVG)
  const hitDiscGeo = track(new THREE.CircleGeometry(0.15, 20));
  const ringGeo = track(new THREE.RingGeometry(0.11, 0.165, 24));
  const pointHits: PointHitRig[] = [];

  PCA_SAMPLES.forEach((sample) => {
    const local = mapDataToPlateLocal(sample.pc1, sample.pc2);
    const baseColor = new THREE.Color(sample.colorHex);

    const makeHitAndRing = (parentGroup: THREE.Group, renderOrder: number) => {
      const hitMat = track(
        new THREE.MeshBasicMaterial({
          color: baseColor,
          transparent: true,
          opacity: 0.001,
          depthWrite: false,
        }),
      );
      const hitMesh = new THREE.Mesh(hitDiscGeo, hitMat);
      hitMesh.rotation.x = -Math.PI / 2;
      hitMesh.position.set(local.x, 0.012, local.z);
      hitMesh.userData = { interactType: 'sample', sampleId: sample.id };
      parentGroup.add(hitMesh);
      interactables.push(hitMesh);

      const selRingMat = track(
        new THREE.MeshBasicMaterial({
          color: baseColor,
          transparent: true,
          opacity: 0,
          side: THREE.DoubleSide,
          depthWrite: false,
        }),
      );
      const selRing = new THREE.Mesh(ringGeo, selRingMat);
      selRing.rotation.x = -Math.PI / 2;
      selRing.position.set(local.x, 0.016, local.z);
      selRing.renderOrder = renderOrder;
      parentGroup.add(selRing);
      return selRing;
    };

    const layerRing = makeHitAndRing(layerRigs.layers.group, 14);
    const svgRing = makeHitAndRing(layerRigs.svg.group, 15);

    pointHits.push({
      sampleId: sample.id,
      layerRing,
      svgRing,
      baseColor,
      localX: local.x,
      localZ: local.z,
    });
  });

  // 3b. Safety-Lock Semantic Zone Overlay on Layer 6 SVG (visible in 视觉寻址链 / panel-grid mode)
  const safetyLockGroup = new THREE.Group();
  safetyLockGroup.visible = false;
  safetyLockGroup.position.y = 0.018;
  layerRigs.svg.group.add(safetyLockGroup);

  const lockW = 3.8; // PLOT_LOCAL_BOUNDS.maxX - minX (-2.05 to 1.75)
  const lockD = 2.8; // PLOT_LOCAL_BOUNDS.maxZ - minZ (-1.45 to 1.35)
  const lockCenterX = -0.15;
  const lockCenterZ = -0.05;

  const lockFillMesh = new THREE.Mesh(
    track(new THREE.PlaneGeometry(lockW, lockD)),
    track(
      new THREE.MeshBasicMaterial({
        color: 0x2f855a,
        transparent: true,
        opacity: 0.09,
        side: THREE.DoubleSide,
        depthWrite: false,
      }),
    ),
  );
  lockFillMesh.rotation.x = -Math.PI / 2;
  lockFillMesh.position.set(lockCenterX, 0, lockCenterZ);
  lockFillMesh.renderOrder = 12;
  safetyLockGroup.add(lockFillMesh);

  const lockBorder = new THREE.LineLoop(
    track(createRectBorderGeometry(lockW, lockD)),
    track(
      new THREE.LineBasicMaterial({
        color: 0x2f855a,
        transparent: true,
        opacity: 0.92,
        depthWrite: false,
      }),
    ),
  );
  lockBorder.position.set(lockCenterX, 0.004, lockCenterZ);
  lockBorder.renderOrder = 13;
  safetyLockGroup.add(lockBorder);

  // Editable right guide-box zone (terracotta dashed outline + warm tint)
  const editGuideW = 0.98;
  const editGuideD = 0.92;
  const editGuideX = 2.48;
  const editGuideZ = -0.88;

  const editGuideFill = new THREE.Mesh(
    track(new THREE.PlaneGeometry(editGuideW, editGuideD)),
    track(
      new THREE.MeshBasicMaterial({
        color: 0xdf6a2b,
        transparent: true,
        opacity: 0.12,
        side: THREE.DoubleSide,
        depthWrite: false,
      }),
    ),
  );
  editGuideFill.rotation.x = -Math.PI / 2;
  editGuideFill.position.set(editGuideX, 0, editGuideZ);
  editGuideFill.renderOrder = 12;
  safetyLockGroup.add(editGuideFill);

  const editGuideLoopPts = [
    new THREE.Vector3(-editGuideW / 2, 0, -editGuideD / 2),
    new THREE.Vector3(editGuideW / 2, 0, -editGuideD / 2),
    new THREE.Vector3(editGuideW / 2, 0, editGuideD / 2),
    new THREE.Vector3(-editGuideW / 2, 0, editGuideD / 2),
    new THREE.Vector3(-editGuideW / 2, 0, -editGuideD / 2),
  ];
  const editGuideLine = new THREE.Line(
    track(new THREE.BufferGeometry().setFromPoints(editGuideLoopPts)),
    track(
      new THREE.LineDashedMaterial({
        color: 0xdf6a2b,
        transparent: true,
        opacity: 0.95,
        dashSize: 0.12,
        gapSize: 0.07,
        depthWrite: false,
      }),
    ),
  );
  editGuideLine.computeLineDistances();
  editGuideLine.position.set(editGuideX, 0.005, editGuideZ);
  editGuideLine.renderOrder = 13;
  safetyLockGroup.add(editGuideLine);

  // Editable bottom axis-b zone
  const editAxisW = 3.8;
  const editAxisD = 0.56;
  const editAxisX = -0.15;
  const editAxisZ = 1.66;
  const editAxisFill = new THREE.Mesh(
    track(new THREE.PlaneGeometry(editAxisW, editAxisD)),
    track(
      new THREE.MeshBasicMaterial({
        color: 0xdf6a2b,
        transparent: true,
        opacity: 0.1,
        side: THREE.DoubleSide,
        depthWrite: false,
      }),
    ),
  );
  editAxisFill.rotation.x = -Math.PI / 2;
  editAxisFill.position.set(editAxisX, 0, editAxisZ);
  editAxisFill.renderOrder = 12;
  safetyLockGroup.add(editAxisFill);

  const editAxisLoopPts = [
    new THREE.Vector3(-editAxisW / 2, 0, -editAxisD / 2),
    new THREE.Vector3(editAxisW / 2, 0, -editAxisD / 2),
    new THREE.Vector3(editAxisW / 2, 0, editAxisD / 2),
    new THREE.Vector3(-editAxisW / 2, 0, editAxisD / 2),
    new THREE.Vector3(-editAxisW / 2, 0, -editAxisD / 2),
  ];
  const editAxisLine = new THREE.Line(
    track(new THREE.BufferGeometry().setFromPoints(editAxisLoopPts)),
    track(
      new THREE.LineDashedMaterial({
        color: 0xdf6a2b,
        transparent: true,
        opacity: 0.9,
        dashSize: 0.12,
        gapSize: 0.07,
        depthWrite: false,
      }),
    ),
  );
  editAxisLine.computeLineDistances();
  editAxisLine.position.set(editAxisX, 0.005, editAxisZ);
  editAxisLine.renderOrder = 13;
  safetyLockGroup.add(editAxisLine);

  // 4. Clean Flat 2D Floating Output Cards on Right Wing (Asset Map & Asset Bundle)
  const assetNodes = {} as Record<AssetNodeId, AssetNodeRig>;
  const cardGeo = track(new THREE.PlaneGeometry(2.22, 1.66));

  const createFlatAssetCard = (
    id: AssetNodeId,
    pos: { x: number; y: number; z: number },
    accentHex: number,
  ) => {
    const group = new THREE.Group();
    group.position.set(pos.x, pos.y, pos.z);
    group.rotation.y = -0.24;
    group.rotation.x = -0.06;

    const tex = track(createAssetCardTexture(id, maxAnisotropy));
    const mat = track(
      new THREE.MeshBasicMaterial({
        map: tex,
        transparent: true,
        alphaTest: 0.05,
        side: THREE.DoubleSide,
      }),
    );
    const mesh = new THREE.Mesh(cardGeo, mat);
    mesh.renderOrder = 8;
    mesh.userData = { interactType: 'asset', assetId: id };
    group.add(mesh);
    interactables.push(mesh);

    const baseColor = new THREE.Color(accentHex);
    const borderMat = track(
      new THREE.LineBasicMaterial({
        color: baseColor,
        transparent: true,
        opacity: 0,
      }),
    );

    rootGroup.add(group);
    assetNodes[id] = {
      id,
      group,
      borderMaterial: borderMat,
      baseColor,
      calloutAnchor: new THREE.Vector3(pos.x, pos.y + 0.96, pos.z),
    };
  };

  createFlatAssetCard('asset-map', SHEET_ANCHORS.assetMapPos, 0xdf6a2b);
  createFlatAssetCard('asset-bundle', SHEET_ANCHORS.assetBundlePos, 0x2d603e);
  createFlatAssetCard('asset-work', SHEET_ANCHORS.assetWorkPos, 0x315c6b);

  // 5. Dynamic Group for Inter-Layer Meridian Grid Lines (经纬线) & Semantic Source-Map Splines
  const mappingGroup = new THREE.Group();
  mappingGroup.renderOrder = 12;
  rootGroup.add(mappingGroup);

  const sharedNodeDotGeo = track(new THREE.CircleGeometry(0.044, 16));
  const sharedNodeHaloGeo = track(new THREE.RingGeometry(0.056, 0.082, 20));
  const sharedFlowBeadGeo = track(new THREE.CapsuleGeometry(0.022, 0.085, 4, 8));
  const sharedFlowCoreGeo = track(new THREE.SphereGeometry(0.017, 8, 8));
  const flowCoreMat = track(
    new THREE.MeshBasicMaterial({
      color: 0xfcf9f3,
      transparent: true,
      opacity: 0.94,
      depthWrite: false,
    }),
  );

  interface ActiveFlowTrack {
    spline: THREE.CatmullRomCurve3;
    speed: number;
    packets: { group: THREE.Group; phaseOffset: number }[];
  }

  let activeFlowTracks: ActiveFlowTrack[] = [];
  let dynamicDisposables: { dispose: () => void }[] = [];
  let lastMappingKey = '';
  let lastFlowTime = 0;

  const _flowPos = new THREE.Vector3();
  const _flowTan = new THREE.Vector3();
  const _flowUp = new THREE.Vector3(0, 1, 0);

  const clearDynamicMappings = () => {
    while (mappingGroup.children.length > 0) {
      mappingGroup.remove(mappingGroup.children[0]);
    }
    for (const d of dynamicDisposables) {
      d.dispose();
    }
    dynamicDisposables = [];
    activeFlowTracks = [];
  };

  const stepFlow = (elapsedSec: number) => {
    lastFlowTime = elapsedSec;
    for (const trackItem of activeFlowTracks) {
      for (const pkt of trackItem.packets) {
        const u = (elapsedSec * trackItem.speed + pkt.phaseOffset) % 1;
        const safeU = u < 0 ? u + 1 : u;
        trackItem.spline.getPointAt(safeU, _flowPos);
        trackItem.spline.getTangentAt(safeU, _flowTan).normalize();
        pkt.group.position.copy(_flowPos);
        if (_flowTan.lengthSq() > 1e-6) {
          pkt.group.quaternion.setFromUnitVectors(_flowUp, _flowTan);
        }
      }
    }
  };

  const updateMappings = (
    transforms: Record<LayerId, LayerTransform>,
    mode: MappingFocusMode,
    tracedSampleId: string | null,
    layoutMode: LayoutMode = 'stacked',
  ) => {
    safetyLockGroup.visible = mode === 'panel-grid';

    // Only rebuild when any layer transform or focus state actually changes
    const tKey = (['code', 'ir', 'panels', 'axes', 'layers', 'svg'] as LayerId[])
      .map((id) => {
        const t = transforms[id];
        return `${t.x.toFixed(3)},${t.y.toFixed(3)},${t.z.toFixed(3)}`;
      })
      .join(';');
    const key = `${layoutMode}|${mode}|${tracedSampleId ?? ''}|${tKey}`;
    if (key === lastMappingKey) return;
    lastMappingKey = key;

    clearDynamicMappings();

    const isTiled = layoutMode === 'tiled';

    // 5a. Continuous Multi-Layer Coordinate Meridians (stacked) or Drafting Compilation Rails (tiled)
    const meridians = computeMeridianGridLines(transforms, mode, layoutMode);
    const matCache = new Map<string, THREE.Material>();

    const getLineMat = (hex: string, opacity: number, dashed: boolean) => {
      const mKey = `l|${hex}|${opacity.toFixed(2)}|${dashed ? 1 : 0}`;
      let mat = matCache.get(mKey);
      if (!mat) {
        mat = dashed
          ? new THREE.LineDashedMaterial({
              color: new THREE.Color(hex),
              transparent: true,
              opacity,
              dashSize: isTiled ? 0.22 : 0.12,
              gapSize: isTiled ? 0.14 : 0.08,
              depthWrite: false,
            })
          : new THREE.LineBasicMaterial({
              color: new THREE.Color(hex),
              transparent: true,
              opacity,
              depthWrite: false,
            });
        matCache.set(mKey, mat);
        dynamicDisposables.push(mat);
      }
      return mat;
    };

    const getBasicMat = (hex: string, opacity: number) => {
      const mKey = `b|${hex}|${opacity.toFixed(2)}`;
      let mat = matCache.get(mKey);
      if (!mat) {
        mat = new THREE.MeshBasicMaterial({
          color: new THREE.Color(hex),
          transparent: opacity < 0.99,
          opacity,
          side: THREE.DoubleSide,
          depthWrite: false,
        });
        matCache.set(mKey, mat);
        dynamicDisposables.push(mat);
      }
      return mat;
    };

    for (const m of meridians) {
      if (m.points.length < 2) continue;
      const vecPts = m.points.map((p) => new THREE.Vector3(...p));
      const isEmphasizedPanel =
        mode === 'panel-grid' && (m.kind === 'panel-p1' || m.kind === 'panel-p2');

      if (isEmphasizedPanel) {
        const path = isTiled
          ? new THREE.CatmullRomCurve3(vecPts, false, 'centripetal', 0.45)
          : (() => {
              const cp = new THREE.CurvePath<THREE.Vector3>();
              for (let i = 0; i < vecPts.length - 1; i++) {
                cp.add(new THREE.LineCurve3(vecPts[i], vecPts[i + 1]));
              }
              return cp;
            })();
        const segs = isTiled ? 28 : (vecPts.length - 1) * 4;
        const tubeGeo = new THREE.TubeGeometry(
          path,
          segs,
          isTiled ? 0.012 : 0.011,
          6,
          false,
        );
        dynamicDisposables.push(tubeGeo);
        const mesh = new THREE.Mesh(
          tubeGeo,
          getBasicMat(m.colorHex, Math.min(0.68, m.opacity)),
        );
        mesh.renderOrder = 11;
        mappingGroup.add(mesh);
      } else if (isTiled && (m.kind === 'panel-p1' || m.kind === 'panel-p2')) {
        // Smooth curved dashed bridge for subtle tiled panel arches
        const spline = new THREE.CatmullRomCurve3(vecPts, false, 'centripetal', 0.45);
        const sampled = spline.getPoints(24);
        const lineGeo = new THREE.BufferGeometry().setFromPoints(sampled);
        dynamicDisposables.push(lineGeo);
        const line = new THREE.Line(
          lineGeo,
          getLineMat(m.colorHex, m.opacity, true),
        );
        line.computeLineDistances();
        line.renderOrder = 10;
        mappingGroup.add(line);
      } else {
        const lineGeo = new THREE.BufferGeometry().setFromPoints(vecPts);
        dynamicDisposables.push(lineGeo);
        const isDashed = m.kind === 'axis-tick' || (!isTiled && m.kind === 'frame');
        const line = new THREE.Line(
          lineGeo,
          getLineMat(m.colorHex, m.opacity, isDashed),
        );
        if (isDashed) line.computeLineDistances();
        line.renderOrder = 10;
        mappingGroup.add(line);
      }
    }

    // 5b. Gossamer Semi-Translucent Source-Map Filaments, Crisp Anchor Dots & Sleek Flow Droplets
    const curves = computeMappingPaths(mode, tracedSampleId, transforms, layoutMode);

    curves.forEach((c, curveIdx) => {
      if (c.points.length < 2) return;
      const vecPoints = c.points.map((p) => new THREE.Vector3(...p));
      const spline = new THREE.CatmullRomCurve3(vecPoints, false, 'centripetal', 0.4);
      const tubularSegments = c.points.length > 3 ? 36 : 24;

      // Secondary / low-emphasis reference trails render as delicate dashed hairlines (zero visual occlusion)
      const useHairline = Boolean(c.dashed) || (!c.emphasized && c.opacity < 0.45);
      if (useHairline) {
        const sampled = spline.getPoints(tubularSegments);
        const lineGeo = new THREE.BufferGeometry().setFromPoints(sampled);
        dynamicDisposables.push(lineGeo);
        const line = new THREE.Line(
          lineGeo,
          getLineMat(c.colorHex, Math.min(0.45, c.opacity), true),
        );
        line.computeLineDistances();
        line.renderOrder = 11;
        mappingGroup.add(line);
      } else {
        // Slender translucent filament tube so charts & typography underneath remain 100% legible
        const radius = isTiled
          ? c.emphasized
            ? 0.015
            : 0.0095
          : c.emphasized
            ? 0.013
            : 0.008;
        const visualOpacity = c.emphasized
          ? Math.min(0.76, c.opacity * 0.82)
          : Math.min(0.52, c.opacity * 0.68);

        const tubeGeo = new THREE.TubeGeometry(
          spline,
          tubularSegments,
          radius,
          6,
          false,
        );
        dynamicDisposables.push(tubeGeo);

        const tubeMesh = new THREE.Mesh(
          tubeGeo,
          getBasicMat(c.colorHex, visualOpacity),
        );
        tubeMesh.renderOrder = c.emphasized ? 14 : 11;
        mappingGroup.add(tubeMesh);
      }

      // Sleek animated flow droplets convey direction cleanly (no bulky mid-curve cone arrowheads)
      if (!useHairline && c.opacity >= 0.45) {
        const packetCount = c.emphasized ? 2 : 1;
        const beadMat = getBasicMat(c.colorHex, c.emphasized ? 0.9 : 0.78);
        const packets: { group: THREE.Group; phaseOffset: number }[] = [];

        for (let p = 0; p < packetCount; p++) {
          const pktGroup = new THREE.Group();
          const outer = new THREE.Mesh(sharedFlowBeadGeo, beadMat);
          outer.renderOrder = 18;
          pktGroup.add(outer);

          const core = new THREE.Mesh(sharedFlowCoreGeo, flowCoreMat);
          core.renderOrder = 19;
          pktGroup.add(core);

          const scale = isTiled
            ? c.emphasized
              ? 1.06
              : 0.78
            : c.emphasized
              ? 0.9
              : 0.64;
          pktGroup.scale.setScalar(scale);
          mappingGroup.add(pktGroup);
          packets.push({
            group: pktGroup,
            phaseOffset: (p / packetCount + curveIdx * 0.17) % 1,
          });
        }

        activeFlowTracks.push({
          spline,
          speed: c.flowSpeed,
          packets,
        });
      }

      // Crisp jewel-like registration dots seated cleanly on each intersected 2D sheet
      const dotOpacity = c.emphasized
        ? Math.min(0.92, c.opacity)
        : Math.min(0.62, c.opacity * 0.85);
      const nodeMat = getBasicMat(c.colorHex, dotOpacity);
      for (const anchor of c.anchorNodes) {
        const dot = new THREE.Mesh(sharedNodeDotGeo, nodeMat);
        dot.rotation.x = -Math.PI / 2;
        dot.position.set(anchor[0], anchor[1] + 0.008, anchor[2]);
        dot.scale.setScalar(
          isTiled ? (c.emphasized ? 1.15 : 0.85) : c.emphasized ? 1.0 : 0.76,
        );
        dot.renderOrder = 15;
        mappingGroup.add(dot);

        if (c.emphasized) {
          const halo = new THREE.Mesh(sharedNodeHaloGeo, nodeMat);
          halo.rotation.x = -Math.PI / 2;
          halo.position.set(anchor[0], anchor[1] + 0.009, anchor[2]);
          halo.scale.setScalar(isTiled ? 1.15 : 0.95);
          halo.renderOrder = 15;
          mappingGroup.add(halo);
        }
      }
    });

    // Position flow beads immediately for the current phase
    stepFlow(lastFlowTime);
  };

  return {
    rootGroup,
    mainShadow,
    layerRigs,
    pointHits,
    assetNodes,
    interactables,
    updateMappings,
    stepFlow,
    dispose: () => {
      clearDynamicMappings();
      scene.remove(rootGroup);
      disposables.forEach((d) => d.dispose());
    },
  };
}
