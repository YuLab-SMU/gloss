import { useEffect, useRef, useState } from 'react';
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import {
  ARCHITECTURE_LAYERS,
  type AssetNodeId,
  type LayerId,
} from '../data/glossModel';
import {
  LAYER_ORDER,
  PLATE_DEPTH,
  PLATE_WIDTH,
  computeLayerTransforms,
  dampValue,
  getAssetCardTransforms,
  getCameraTargetState,
  type CameraPresetId,
  type LayerTransform,
  type LayoutMode,
} from '../scene/layoutMath';
import {
  computeFlowCallouts,
  type MappingFocusMode,
} from '../scene/mappingPaths';
import { buildGlossScene, type BuiltGlossScene } from '../scene/buildGlossScene';

export interface GlossViewport3DProps {
  explode: number;
  layerOffset: number;
  layoutMode: LayoutMode;
  flowPlaying: boolean;
  mappingMode: MappingFocusMode;
  focusLayer: LayerId | null;
  focusAsset: AssetNodeId | null;
  highlightLayers: LayerId[];
  tracedSampleId: string | null;
  cameraPreset: CameraPresetId;
  cameraRevision: number;
  showLabels: boolean;
  drawerOpen: boolean;
  onSelectLayer: (id: LayerId) => void;
  onSelectSample: (sampleId: string) => void;
  onSelectAsset: (assetId: AssetNodeId) => void;
}

// Pre-allocated scratch math helpers (zero GC in render loop)
const _projVec = new THREE.Vector3();
const _targetCamPos = new THREE.Vector3();
const _targetLookAt = new THREE.Vector3();
const _activeBorderOrange = new THREE.Color(0xdf6a2b);
const _activeBorderGreen = new THREE.Color(0x2d603e);

function detectSoftwareGl(): boolean {
  try {
    const canvas = document.createElement('canvas');
    const gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
    if (!gl) return true;
    const ext = gl.getExtension('WEBGL_debug_renderer_info');
    const param = ext ? ext.UNMASKED_RENDERER_WEBGL : gl.RENDERER;
    const gpu = String(gl.getParameter(param) ?? '');
    gl.getExtension('WEBGL_lose_context')?.loseContext();
    return /SwiftShader|llvmpipe|softpipe|Software|Basic Render/i.test(gpu);
  } catch {
    return true;
  }
}

export function GlossViewport3D({
  explode,
  layerOffset,
  layoutMode,
  flowPlaying,
  mappingMode,
  focusLayer,
  focusAsset,
  highlightLayers,
  tracedSampleId,
  cameraPreset,
  cameraRevision,
  showLabels,
  drawerOpen,
  onSelectLayer,
  onSelectSample,
  onSelectAsset,
}: GlossViewport3DProps) {
  const mountRef = useRef<HTMLDivElement | null>(null);
  const labelLayerRefs = useRef<Record<string, HTMLButtonElement | null>>({});
  const labelAssetRefs = useRef<Record<string, HTMLButtonElement | null>>({});
  const flowBadgeRefs = useRef<(HTMLDivElement | null)[]>([]);
  const [webglError, setWebglError] = useState(false);

  const stateRef = useRef({
    explode,
    layerOffset,
    layoutMode,
    flowPlaying,
    mappingMode,
    focusLayer,
    focusAsset,
    highlightLayers,
    tracedSampleId,
    cameraPreset,
    cameraRevision,
    showLabels,
    drawerOpen,
  });
  stateRef.current = {
    explode,
    layerOffset,
    layoutMode,
    flowPlaying,
    mappingMode,
    focusLayer,
    focusAsset,
    highlightLayers,
    tracedSampleId,
    cameraPreset,
    cameraRevision,
    showLabels,
    drawerOpen,
  };

  const callbacksRef = useRef({
    onSelectLayer,
    onSelectSample,
    onSelectAsset,
  });
  callbacksRef.current = { onSelectLayer, onSelectSample, onSelectAsset };

  const triggerRenderRef = useRef<(() => void) | null>(null);
  const startCameraTransitionRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    startCameraTransitionRef.current?.();
    triggerRenderRef.current?.();
  }, [cameraPreset, layoutMode, mappingMode, focusLayer, focusAsset, cameraRevision, drawerOpen, layerOffset]);

  useEffect(() => {
    triggerRenderRef.current?.();
  }, [explode, flowPlaying, highlightLayers, tracedSampleId, showLabels]);

  useEffect(() => {
    const container = mountRef.current;
    if (!container) return;

    const isSoftwareGl = detectSoftwareGl();

    let renderer: THREE.WebGLRenderer;
    try {
      renderer = new THREE.WebGLRenderer({
        antialias: !isSoftwareGl,
        powerPreference: 'high-performance',
        preserveDrawingBuffer: true,
      });
    } catch {
      setWebglError(true);
      return;
    }

    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.toneMapping = THREE.NoToneMapping;
    renderer.setPixelRatio(
      isSoftwareGl ? 1 : Math.min(window.devicePixelRatio || 1, 2),
    );

    const width = container.clientWidth || window.innerWidth;
    const height = container.clientHeight || window.innerHeight;
    renderer.setSize(width, height);
    renderer.domElement.style.display = 'block';
    renderer.domElement.style.width = '100%';
    renderer.domElement.style.height = '100%';
    renderer.domElement.setAttribute('data-testid', 'gloss-3d-canvas');
    container.appendChild(renderer.domElement);

    const scene = new THREE.Scene();
    const bgHex = 0xf4efe5;
    scene.background = new THREE.Color(bgHex);
    scene.fog = new THREE.Fog(bgHex, 38, 84);

    const camera = new THREE.PerspectiveCamera(35, width / height, 0.2, 140);
    const initialCam = getCameraTargetState(
      stateRef.current.cameraPreset,
      stateRef.current.focusLayer,
      stateRef.current.focusAsset,
      stateRef.current.explode,
      stateRef.current.mappingMode,
      stateRef.current.layerOffset,
      stateRef.current.layoutMode,
    );
    camera.position.set(...initialCam.position);

    const controls = new OrbitControls(camera, renderer.domElement);
    controls.target.set(...initialCam.target);
    controls.enableDamping = !isSoftwareGl;
    controls.dampingFactor = 0.07;
    controls.minDistance = 4.6;
    controls.maxDistance = 44;
    controls.maxPolarAngle = Math.PI * 0.48;
    controls.minPolarAngle = 0.12;
    controls.update();

    const maxAnisotropy = renderer.capabilities.getMaxAnisotropy();
    const built: BuiltGlossScene = buildGlossScene(scene, maxAnisotropy);

    const currentTransforms: Record<LayerId, LayerTransform> =
      computeLayerTransforms(
        stateRef.current.explode,
        stateRef.current.layerOffset,
        stateRef.current.focusLayer,
        stateRef.current.layoutMode,
      );

    let cameraTransitionActive = false;
    _targetCamPos.set(...initialCam.position);
    _targetLookAt.set(...initialCam.target);

    startCameraTransitionRef.current = () => {
      const nextCam = getCameraTargetState(
        stateRef.current.cameraPreset,
        stateRef.current.focusLayer,
        stateRef.current.focusAsset,
        stateRef.current.explode,
        stateRef.current.mappingMode,
        stateRef.current.layerOffset,
        stateRef.current.layoutMode,
      );
      _targetCamPos.set(...nextCam.position);
      _targetLookAt.set(...nextCam.target);
      if (stateRef.current.drawerOpen) {
        const viewDir = new THREE.Vector3()
          .subVectors(_targetLookAt, _targetCamPos)
          .normalize();
        const rightVec = new THREE.Vector3()
          .crossVectors(viewDir, new THREE.Vector3(0, 1, 0))
          .normalize();
        const isTiled = stateRef.current.layoutMode === 'tiled';
        _targetLookAt.addScaledVector(rightVec, isTiled ? 4.2 : 2.35);
        _targetCamPos.addScaledVector(rightVec, isTiled ? 3.8 : 1.75);
      }
      cameraTransitionActive = true;
    };

    const handleControlsStart = () => {
      cameraTransitionActive = false;
    };
    controls.addEventListener('start', handleControlsStart);

    let frameId = 0;
    let renderBusy = false;
    let renderDirty = false;
    let disposed = false;
    let lastTime = performance.now();
    let flowElapsed = 0.28;
    let pendingSize: { w: number; h: number } | null = null;
    let hoveredKey: string | null = null;
    const layerHoverLift: Record<LayerId, number> = {
      code: 0,
      ir: 0,
      panels: 0,
      axes: 0,
      layers: 0,
      svg: 0,
    };
    const assetHoverLift: Record<AssetNodeId, number> = {
      'asset-map': 0,
      'asset-bundle': 0,
      'asset-work': 0,
    };

    function afterDraw(cb: () => void, flowOnly: boolean) {
      const gl = renderer.getContext() as WebGL2RenderingContext;
      const delayMs = flowOnly ? 160 : 65;
      if (gl && typeof gl.fenceSync === 'function') {
        const sync = gl.fenceSync(gl.SYNC_GPU_COMMANDS_COMPLETE, 0);
        gl.flush();
        let polls = 0;
        const poll = () => {
          if (disposed) {
            if (sync) gl.deleteSync(sync);
            return;
          }
          polls += 1;
          const status = sync && gl.getSyncParameter(sync, gl.SYNC_STATUS);
          if (status === gl.UNSIGNALED && polls < 24) {
            frameId = window.setTimeout(poll, 5);
          } else {
            if (sync) gl.deleteSync(sync);
            frameId = window.setTimeout(cb, delayMs);
          }
        };
        frameId = window.setTimeout(poll, 5);
      } else {
        frameId = window.setTimeout(cb, delayMs);
      }
    }

    function updateProjectedLabels(viewportW: number, viewportH: number) {
      const {
        showLabels: visibleLabels,
        drawerOpen: isDrawerOpen,
        focusLayer: activeFocusLayer,
        layoutMode: activeLayoutMode,
      } = stateRef.current;
      const isTiled = activeLayoutMode === 'tiled';
      const rightLimit = isDrawerOpen ? viewportW - 472 : viewportW - 20;

      for (const layerId of LAYER_ORDER) {
        const btn = labelLayerRefs.current[layerId];
        if (!btn) continue;
        if (
          !visibleLabels ||
          (activeFocusLayer !== null && activeFocusLayer !== layerId)
        ) {
          btn.style.opacity = '0';
          btn.style.pointerEvents = 'none';
          continue;
        }
        const rig = built.layerRigs[layerId];
        if (isTiled) {
          // Sit cleanly above each tile's top-left header margin so adjacent columns never collide
          _projVec.set(
            rig.group.position.x - PLATE_WIDTH / 2 + 0.12,
            rig.group.position.y + 0.05,
            rig.group.position.z - PLATE_DEPTH / 2 - 0.16,
          );
        } else {
          _projVec.set(
            rig.group.position.x - PLATE_WIDTH / 2 - 0.22,
            rig.group.position.y,
            rig.group.position.z + 0.2,
          );
        }
        _projVec.project(camera);

        if (_projVec.z > 1) {
          btn.style.opacity = '0';
          btn.style.pointerEvents = 'none';
          continue;
        }
        const sx = (_projVec.x * 0.5 + 0.5) * viewportW;
        const sy = (-_projVec.y * 0.5 + 0.5) * viewportH;
        const inSafeZone = isTiled
          ? sx > 12 && sx < rightLimit - 40 && sy > 24 && sy < viewportH - 115
          : sx > 18 && sx < rightLimit && sy > 18 && sy < viewportH - 108;

        btn.style.transform = isTiled
          ? `translate3d(${Math.round(sx)}px, ${Math.round(sy)}px, 0) translate(0%, -100%)`
          : `translate3d(${Math.round(sx)}px, ${Math.round(sy)}px, 0) translate(-100%, -50%)`;
        btn.style.opacity = inSafeZone ? '1' : '0';
        btn.style.pointerEvents = inSafeZone ? 'auto' : 'none';
      }

      for (const assetId of ['asset-map', 'asset-bundle', 'asset-work'] as AssetNodeId[]) {
        const btn = labelAssetRefs.current[assetId];
        if (!btn) continue;
        if (!visibleLabels) {
          btn.style.opacity = '0';
          btn.style.pointerEvents = 'none';
          continue;
        }
        const rig = built.assetNodes[assetId];
        _projVec.copy(rig.calloutAnchor);
        _projVec.project(camera);

        if (_projVec.z > 1) {
          btn.style.opacity = '0';
          btn.style.pointerEvents = 'none';
          continue;
        }
        const sx = (_projVec.x * 0.5 + 0.5) * viewportW;
        const sy = (-_projVec.y * 0.5 + 0.5) * viewportH;
        const inSafeZone =
          sx > 18 && sx < rightLimit && sy > 18 && sy < viewportH - 108;

        btn.style.transform = `translate3d(${Math.round(sx)}px, ${Math.round(sy)}px, 0) translate(-50%, -100%)`;
        btn.style.opacity = inSafeZone ? '1' : '0';
        btn.style.pointerEvents = inSafeZone ? 'auto' : 'none';
      }

      // Project floating 3D Glue-Code / Component Meaning Badges along active information-flow chains
      const showFlowBadges =
        visibleLabels && activeFocusLayer === null && stateRef.current.cameraPreset !== 'top';
      const badges = showFlowBadges
        ? computeFlowCallouts(
            stateRef.current.mappingMode,
            stateRef.current.tracedSampleId,
            currentTransforms,
            activeLayoutMode,
          )
        : [];

      for (let i = 0; i < 3; i++) {
        const el = flowBadgeRefs.current[i];
        if (!el) continue;
        const badge = badges[i];
        if (!badge) {
          el.style.opacity = '0';
          continue;
        }
        _projVec.set(...badge.position);
        _projVec.project(camera);
        if (_projVec.z > 1) {
          el.style.opacity = '0';
          continue;
        }
        const sx = (_projVec.x * 0.5 + 0.5) * viewportW;
        const sy = (-_projVec.y * 0.5 + 0.5) * viewportH;
        const inSafeZone =
          sx > 120 && sx < rightLimit - 95 && sy > 76 && sy < viewportH - 130;

        if (!inSafeZone) {
          el.style.opacity = '0';
          continue;
        }
        const codeEl = el.firstElementChild as HTMLElement | null;
        const roleEl = el.lastElementChild as HTMLElement | null;
        if (codeEl && codeEl.textContent !== badge.code) {
          codeEl.textContent = badge.code;
          codeEl.style.color = badge.colorHex;
        }
        if (roleEl && roleEl.textContent !== badge.role) {
          roleEl.textContent = badge.role;
        }
        el.style.borderColor = `${badge.colorHex}55`;
        el.style.transform = `translate3d(${Math.round(sx)}px, ${Math.round(sy)}px, 0) translate(-50%, -100%)`;
        el.style.opacity = '1';
      }
    }

    function stepScene(dt: number): boolean {
      const {
        explode: targetExplode,
        layerOffset: targetOffset,
        layoutMode: curLayoutMode,
        mappingMode: curMode,
        focusLayer: curFocusLayer,
        focusAsset: curFocusAsset,
        highlightLayers: curHighlights,
        tracedSampleId: curSampleId,
      } = stateRef.current;

      const isTiled = curLayoutMode === 'tiled';
      const targetTransforms = computeLayerTransforms(
        targetExplode,
        targetOffset,
        curFocusLayer,
        curLayoutMode,
      );
      let stillMoving = false;
      const dampRate = isSoftwareGl ? 15 : 10;

      // Toggle stacked central shadow vs per-tile shadows
      built.mainShadow.visible = !isTiled;

      // 1. Damp each of the 6 flat 2D sheets along (x, y, z), add lively hover/breathing motion & focus rim
      LAYER_ORDER.forEach((layerId, idx) => {
        const rig = built.layerRigs[layerId];
        const cur = currentTransforms[layerId];
        const tgt = targetTransforms[layerId];

        const nextX = dampValue(cur.x, tgt.x, dampRate, dt);
        const nextY = dampValue(cur.y, tgt.y, dampRate, dt);
        const nextZ = dampValue(cur.z, tgt.z, dampRate, dt);

        if (
          Math.abs(nextX - tgt.x) > 0.002 ||
          Math.abs(nextY - tgt.y) > 0.002 ||
          Math.abs(nextZ - tgt.z) > 0.002
        ) {
          stillMoving = true;
          cur.x = nextX;
          cur.y = nextY;
          cur.z = nextZ;
        } else {
          cur.x = tgt.x;
          cur.y = tgt.y;
          cur.z = tgt.z;
        }

        const isFocused = curFocusLayer === layerId;
        const isPipelineHighlighted = curHighlights.includes(layerId);
        const isHovered = hoveredKey === `layer:${layerId}`;
        const hasFilter = curFocusLayer !== null || curHighlights.length > 0;

        // Smooth tactile elevation & micro-scale bloom on hover
        const targetLift = isHovered ? 1 : 0;
        const nextLift = dampValue(layerHoverLift[layerId], targetLift, 11, dt);
        if (Math.abs(nextLift - targetLift) > 0.004) {
          stillMoving = true;
          layerHoverLift[layerId] = nextLift;
        } else {
          layerHoverLift[layerId] = targetLift;
        }
        const lift = layerHoverLift[layerId];
        const liftY = lift * (isTiled ? 0.18 : 0.1);

        // Ultra-subtle organic paper buoyancy in stacked mode when live flow is playing
        const canBreathe =
          stateRef.current.flowPlaying && !isTiled && curFocusLayer === null;
        const bobY = canBreathe
          ? Math.sin(flowElapsed * 1.15 + idx * 0.85) * 0.03
          : 0;
        const tiltZ = canBreathe
          ? Math.sin(flowElapsed * 0.85 + idx * 1.15) * 0.0045
          : 0;

        rig.group.position.set(cur.x, cur.y + liftY + bobY, cur.z);
        rig.group.rotation.set(0, 0, tiltZ);
        rig.group.scale.setScalar(1 + lift * 0.018);

        // Per-tile soft shadow deepens & expands as the sheet lifts off the drafting table
        rig.tileShadowMesh.visible = isTiled;
        if (isTiled) {
          rig.tileShadowMesh.position.set(
            0.05 + lift * 0.06,
            -0.025 - liftY,
            0.1 + lift * 0.08,
          );
          rig.tileShadowMesh.scale.setScalar(1 + lift * 0.05);
        }

        // Single rounded highlight halo: completely invisible at rest (no double-border bloat!)
        const targetRimOpacity =
          isFocused || isHovered ? 0.94 : isPipelineHighlighted ? 0.85 : 0;
        if (isFocused || isHovered) {
          rig.borderMaterial.color.copy(_activeBorderOrange);
        } else if (isPipelineHighlighted) {
          rig.borderMaterial.color.copy(_activeBorderGreen);
        } else {
          rig.borderMaterial.color.copy(rig.baseBorderColor);
        }
        const nextRimOp = dampValue(
          rig.borderMaterial.opacity,
          targetRimOpacity,
          12,
          dt,
        );
        if (Math.abs(nextRimOp - targetRimOpacity) > 0.006) {
          stillMoving = true;
          rig.borderMaterial.opacity = nextRimOp;
        } else {
          rig.borderMaterial.opacity = targetRimOpacity;
        }

        const dimmed =
          hasFilter && !isFocused && !isPipelineHighlighted && !curSampleId;
        if (isTiled) {
          (rig.tileShadowMesh.material as THREE.MeshBasicMaterial).opacity =
            dimmed ? 0.14 : Math.max(0.24, 0.44 - lift * 0.1);
        }

        // In flat-tiled spread mode sheets do not overlap vertically, so render at crisp archival paper opacity
        const neutralOpacity = isTiled ? 0.99 : rig.baseOpacity;
        rig.sheetMaterial.opacity = isFocused
          ? 0.99
          : dimmed
            ? 0.28
            : !isTiled && curMode === 'panel-grid' && (layerId === 'code' || layerId === 'ir')
              ? 0.48
              : neutralOpacity;
      });

      // 2. Update 20 flat sample hit-ring highlights
      for (const hit of built.pointHits) {
        const isTraced = curSampleId === hit.sampleId;
        const isHovered = hoveredKey === `sample:${hit.sampleId}`;
        const op = isTraced ? 0.95 : isHovered ? 0.65 : 0;
        const sc = isTraced ? (isTiled ? 1.35 : 1.2) : 1.0;

        (hit.layerRing.material as THREE.MeshBasicMaterial).opacity = op;
        (hit.svgRing.material as THREE.MeshBasicMaterial).opacity = op;
        hit.layerRing.scale.setScalar(sc);
        hit.svgRing.scale.setScalar(sc);
      }

      // 3. Asset Map & Asset Bundle highlight + smooth stacked <-> flat-table morph & hover bloom
      const assetTargets = getAssetCardTransforms(curLayoutMode);
      for (const assetId of ['asset-map', 'asset-bundle', 'asset-work'] as AssetNodeId[]) {
        const rig = built.assetNodes[assetId];
        const tgt = assetTargets[assetId];

        const isAssetHovered = hoveredKey === `asset:${assetId}`;
        const nextALift = dampValue(
          assetHoverLift[assetId],
          isAssetHovered ? 1 : 0,
          11,
          dt,
        );
        if (Math.abs(nextALift - (isAssetHovered ? 1 : 0)) > 0.004) {
          stillMoving = true;
          assetHoverLift[assetId] = nextALift;
        } else {
          assetHoverLift[assetId] = isAssetHovered ? 1 : 0;
        }
        const aLift = assetHoverLift[assetId];

        const targetYWithLift = tgt.y + aLift * 0.14;
        const targetScaleWithLift = tgt.scale * (1 + aLift * 0.028);

        const ax = dampValue(rig.group.position.x, tgt.x, dampRate, dt);
        const ay = dampValue(rig.group.position.y, targetYWithLift, dampRate, dt);
        const az = dampValue(rig.group.position.z, tgt.z, dampRate, dt);
        const arx = dampValue(rig.group.rotation.x, tgt.rotX, dampRate, dt);
        const ary = dampValue(rig.group.rotation.y, tgt.rotY, dampRate, dt);
        const asc = dampValue(rig.group.scale.x, targetScaleWithLift, dampRate, dt);

        if (
          Math.abs(ax - tgt.x) > 0.002 ||
          Math.abs(ay - targetYWithLift) > 0.002 ||
          Math.abs(az - tgt.z) > 0.002 ||
          Math.abs(arx - tgt.rotX) > 0.002 ||
          Math.abs(ary - tgt.rotY) > 0.002 ||
          Math.abs(asc - targetScaleWithLift) > 0.002
        ) {
          stillMoving = true;
        }

        rig.group.position.set(ax, ay, az);
        rig.group.rotation.set(arx, ary, 0);
        rig.group.scale.setScalar(asc);
        rig.calloutAnchor.set(
          ax + tgt.calloutOffset[0],
          ay + tgt.calloutOffset[1],
          az + tgt.calloutOffset[2],
        );

        const active =
          curFocusAsset === assetId ||
          isAssetHovered ||
          curMode === 'asset-export';
        rig.borderMaterial.color.copy(
          active ? _activeBorderOrange : rig.baseColor,
        );
        rig.borderMaterial.opacity = active ? 0.9 : 0;
      }

      // 4. Rebuild continuous 3D Meridian Lattice / Tiled Arch Routes & Advance Flow Packets
      built.updateMappings(currentTransforms, curMode, curSampleId, curLayoutMode);
      if (stateRef.current.flowPlaying) {
        flowElapsed += isSoftwareGl ? 0.055 : Math.min(dt, 0.05);
        built.stepFlow(flowElapsed);
      }

      // 5. Smooth camera transitions
      if (cameraTransitionActive) {
        const camLambda = isSoftwareGl ? 13 : 8;
        camera.position.x = dampValue(
          camera.position.x,
          _targetCamPos.x,
          camLambda,
          dt,
        );
        camera.position.y = dampValue(
          camera.position.y,
          _targetCamPos.y,
          camLambda,
          dt,
        );
        camera.position.z = dampValue(
          camera.position.z,
          _targetCamPos.z,
          camLambda,
          dt,
        );

        controls.target.x = dampValue(
          controls.target.x,
          _targetLookAt.x,
          camLambda,
          dt,
        );
        controls.target.y = dampValue(
          controls.target.y,
          _targetLookAt.y,
          camLambda,
          dt,
        );
        controls.target.z = dampValue(
          controls.target.z,
          _targetLookAt.z,
          camLambda,
          dt,
        );

        const posDist = camera.position.distanceTo(_targetCamPos);
        const tgtDist = controls.target.distanceTo(_targetLookAt);
        if (posDist < 0.03 && tgtDist < 0.03) {
          camera.position.copy(_targetCamPos);
          controls.target.copy(_targetLookAt);
          cameraTransitionActive = false;
        } else {
          stillMoving = true;
        }
      }

      return stillMoving;
    }

    function requestRender() {
      if (disposed) return;
      if (renderBusy) {
        renderDirty = true;
        return;
      }
      renderBusy = true;
      frameId = requestAnimationFrame(() => {
        if (disposed) return;
        renderDirty = false;
        if (pendingSize) {
          camera.aspect = pendingSize.w / pendingSize.h;
          camera.updateProjectionMatrix();
          renderer.setSize(pendingSize.w, pendingSize.h);
          pendingSize = null;
        }
        const now = performance.now();
        const dt = Math.min((now - lastTime) / 1000, 0.06);
        lastTime = now;

        const transformOrCamMoving = stepScene(dt);
        const flowActive = stateRef.current.flowPlaying;
        const keepAnimating = transformOrCamMoving || flowActive;

        controls.update();
        renderer.render(scene, camera);
        updateProjectedLabels(
          container?.clientWidth || window.innerWidth,
          container?.clientHeight || window.innerHeight,
        );

        const finish = () => {
          renderBusy = false;
          if (!disposed && (renderDirty || keepAnimating || pendingSize)) {
            requestRender();
          }
        };

        if (isSoftwareGl) {
          afterDraw(finish, !transformOrCamMoving && flowActive);
        } else {
          finish();
        }
      });
    }

    triggerRenderRef.current = requestRender;
    controls.addEventListener('change', requestRender);

    const raycaster = new THREE.Raycaster();
    const pointer = new THREE.Vector2();
    let pointerDownPos = { x: 0, y: 0 };
    let lastHoverTime = 0;

    const getHit = (clientX: number, clientY: number) => {
      const rect = renderer.domElement.getBoundingClientRect();
      pointer.x = ((clientX - rect.left) / rect.width) * 2 - 1;
      pointer.y = -((clientY - rect.top) / rect.height) * 2 + 1;
      raycaster.setFromCamera(pointer, camera);
      const hits = raycaster.intersectObjects(built.interactables, false);
      const sampleHit = hits.find((h) => h.object.userData.interactType === 'sample');
      return sampleHit ?? hits[0] ?? null;
    };

    const handlePointerDown = (e: PointerEvent) => {
      pointerDownPos = { x: e.clientX, y: e.clientY };
    };

    const handlePointerUp = (e: PointerEvent) => {
      const moved = Math.hypot(
        e.clientX - pointerDownPos.x,
        e.clientY - pointerDownPos.y,
      );
      if (moved > 6) return;

      const hit = getHit(e.clientX, e.clientY);
      if (!hit) return;
      const data = hit.object.userData;
      if (data.interactType === 'sample' && data.sampleId) {
        callbacksRef.current.onSelectSample(data.sampleId);
      } else if (data.interactType === 'asset' && data.assetId) {
        callbacksRef.current.onSelectAsset(data.assetId);
      } else if (data.interactType === 'layer' && data.layerId) {
        callbacksRef.current.onSelectLayer(data.layerId);
      }
    };

    const handlePointerMove = (e: PointerEvent) => {
      const now = performance.now();
      if (now - lastHoverTime < 65) return;
      lastHoverTime = now;

      const hit = getHit(e.clientX, e.clientY);
      let nextKey: string | null = null;
      if (hit) {
        const data = hit.object.userData;
        if (data.interactType === 'sample') nextKey = `sample:${data.sampleId}`;
        else if (data.interactType === 'asset') nextKey = `asset:${data.assetId}`;
        else if (data.interactType === 'layer') nextKey = `layer:${data.layerId}`;
      }
      if (nextKey !== hoveredKey) {
        hoveredKey = nextKey;
        renderer.domElement.style.cursor = nextKey ? 'pointer' : 'grab';
        requestRender();
      }
    };

    renderer.domElement.addEventListener('pointerdown', handlePointerDown);
    renderer.domElement.addEventListener('pointerup', handlePointerUp);
    renderer.domElement.addEventListener('pointermove', handlePointerMove);

    const handleContextLost = (e: Event) => {
      e.preventDefault();
      setWebglError(true);
    };
    const handleContextRestored = () => {
      setWebglError(false);
      requestRender();
    };
    renderer.domElement.addEventListener('webglcontextlost', handleContextLost);
    renderer.domElement.addEventListener(
      'webglcontextrestored',
      handleContextRestored,
    );

    const handleResize = () => {
      if (!container || disposed) return;
      const w = container.clientWidth || window.innerWidth;
      const h = container.clientHeight || window.innerHeight;
      pendingSize = { w, h };
      requestRender();
    };
    window.addEventListener('resize', handleResize);

    // Immediate crisp first paint
    stepScene(0);
    controls.update();
    renderer.render(scene, camera);
    updateProjectedLabels(width, height);
    requestRender();

    return () => {
      disposed = true;
      cancelAnimationFrame(frameId);
      clearTimeout(frameId);
      window.removeEventListener('resize', handleResize);
      controls.removeEventListener('start', handleControlsStart);
      controls.removeEventListener('change', requestRender);
      renderer.domElement.removeEventListener('pointerdown', handlePointerDown);
      renderer.domElement.removeEventListener('pointerup', handlePointerUp);
      renderer.domElement.removeEventListener('pointermove', handlePointerMove);
      renderer.domElement.removeEventListener(
        'webglcontextlost',
        handleContextLost,
      );
      renderer.domElement.removeEventListener(
        'webglcontextrestored',
        handleContextRestored,
      );
      controls.dispose();
      built.dispose();
      renderer.dispose();
      if (renderer.domElement.parentNode === container) {
        container.removeChild(renderer.domElement);
      }
    };
  }, []);

  if (webglError) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-[#F4EFE5] p-8 text-center">
        <div className="max-w-md rounded-xl border border-[#1D2B22]/15 bg-[#FCF9F3] p-6">
          <h2 className="text-lg font-bold text-[#1D2B22]">
            3D WebGL 渲染上下文暂不可用
          </h2>
          <p className="mt-2 text-sm text-[#4A5D50]">
            您仍可通过顶部导航浏览 gloss 五层捕获流水线、开放资产契约与四阶段工程演进路线。
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="relative h-full w-full overflow-hidden">
      <div ref={mountRef} className="h-full w-full" />

      {/* Projected 3D Layer & Asset Callout Pins */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        {ARCHITECTURE_LAYERS.map((layer) => {
          const isActive = focusLayer === layer.id;
          const isHighlighted = highlightLayers.includes(layer.id);
          return (
            <button
              key={layer.id}
              ref={(el) => {
                labelLayerRefs.current[layer.id] = el;
              }}
              type="button"
              onClick={() => onSelectLayer(layer.id)}
              aria-label={`聚焦第 ${layer.stepNumber} 层：${layer.titleZh}`}
              style={{ opacity: 0 }}
              className={`absolute left-0 top-0 flex items-center gap-2 rounded-md border px-2.5 py-1 text-xs font-semibold whitespace-nowrap transition-colors duration-150 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#2D603E] ${
                isActive
                  ? 'border-[#DF6A2B] bg-[#DF6A2B] text-[#FCF9F3] shadow-md'
                  : isHighlighted
                    ? 'border-[#2D603E] bg-[#2D603E] text-[#FCF9F3] shadow-sm'
                    : 'border-[#1D2B22]/15 bg-[#FCF9F3]/95 text-[#1D2B22] hover:border-[#2D603E] hover:text-[#2D603E]'
              }`}
            >
              <span className="font-mono-tabular text-[11px] opacity-80">
                0{layer.stepNumber}
              </span>
              <span>{layer.shortLabel}</span>
            </button>
          );
        })}

        <button
          ref={(el) => {
            labelAssetRefs.current['asset-map'] = el;
          }}
          type="button"
          onClick={() => onSelectAsset('asset-map')}
          aria-label="查看输出产物：Asset Map"
          style={{ opacity: 0 }}
          className={`absolute left-0 top-0 flex items-center gap-1.5 rounded-md border px-2.5 py-1 text-xs font-semibold whitespace-nowrap transition-colors duration-150 ${
            focusAsset === 'asset-map'
              ? 'border-[#DF6A2B] bg-[#DF6A2B] text-[#FCF9F3] shadow-md'
              : 'border-[#DF6A2B]/40 bg-[#FCF9F3]/95 text-[#B5511E] hover:border-[#DF6A2B]'
          }`}
        >
          <span>Asset Map</span>
          <span className="font-mono-tabular text-[11px] opacity-75">
            ≈24 KB
          </span>
        </button>

        <button
          ref={(el) => {
            labelAssetRefs.current['asset-bundle'] = el;
          }}
          type="button"
          onClick={() => onSelectAsset('asset-bundle')}
          aria-label="查看输出产物：Asset Bundle"
          style={{ opacity: 0 }}
          className={`absolute left-0 top-0 flex items-center gap-1.5 rounded-md border px-2.5 py-1 text-xs font-semibold whitespace-nowrap transition-colors duration-150 ${
            focusAsset === 'asset-bundle'
              ? 'border-[#2D603E] bg-[#2D603E] text-[#FCF9F3] shadow-md'
              : 'border-[#2D603E]/40 bg-[#FCF9F3]/95 text-[#234F33] hover:border-[#2D603E]'
          }`}
        >
          <span>Asset Bundle</span>
          <span className="font-mono-tabular text-[11px] opacity-75">
            .gloss/
          </span>
        </button>

        <button
          ref={(el) => {
            labelAssetRefs.current['asset-work'] = el;
          }}
          type="button"
          onClick={() => onSelectAsset('asset-work')}
          aria-label="查看伴随协作工作态：.gloss.work/"
          style={{ opacity: 0 }}
          className={`absolute left-0 top-0 flex items-center gap-1.5 rounded-md border px-2.5 py-1 text-xs font-semibold whitespace-nowrap transition-colors duration-150 ${
            focusAsset === 'asset-work'
              ? 'border-[#315C6B] bg-[#315C6B] text-[#FCF9F3] shadow-md'
              : 'border-[#315C6B]/40 bg-[#FCF9F3]/95 text-[#274B58] hover:border-[#315C6B]'
          }`}
        >
          <span>伴随协作态</span>
          <span className="font-mono-tabular text-[11px] opacity-75">
            .gloss.work/
          </span>
        </button>

        {/* Projected 3D Glue-Code & Component Meaning Callout Badges */}
        {[0, 1, 2].map((idx) => (
          <div
            key={idx}
            ref={(el) => {
              flowBadgeRefs.current[idx] = el;
            }}
            style={{ opacity: 0 }}
            className="pointer-events-none absolute left-0 top-0 rounded-md border bg-[#FCF9F3]/95 px-2.5 py-1 shadow-sm"
          >
            <div className="font-mono-tabular whitespace-nowrap text-[11px] font-bold leading-tight text-[#2D603E]" />
            <div className="whitespace-nowrap text-[10px] leading-tight text-[#4B5B50]" />
          </div>
        ))}
      </div>
    </div>
  );
}
