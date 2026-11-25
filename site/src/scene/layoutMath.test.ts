import test from 'node:test';
import assert from 'node:assert/strict';
import {
  ARCHITECTURE_LAYERS,
  ASSET_MAP_JSON,
  COMPANION_WORK_TREE,
  CONTRACT_LAYERS,
  DESIGN_PRINCIPLES,
  ECOSYSTEM_CONSUMERS,
  END_TO_END_PATHS,
  ENGINE_COVERAGE,
  GLUE_CHAINS,
  PCA_SAMPLES,
  PROGRESSIVE_SCENARIOS,
  PROJECT_LIVE_STATUS,
  PUBLIC_APIS,
  ROADMAP_STAGES,
  getPipelineHighlightLayers,
  traceSampleLineage,
} from '../data/glossModel';
import {
  BASE_STACK_Y,
  LAYER_ORDER,
  PLATE_DEPTH,
  PLATE_WIDTH,
  PLOT_LOCAL_BOUNDS,
  computeLayerTransforms,
  computeLayerYPositions,
  dampValue,
  getAssetCardTransforms,
  getCameraTargetState,
  mapDataToPlateLocal,
} from './layoutMath';
import {
  MAPPING_MODES,
  computeFlowCallouts,
  computeMappingPaths,
  computeMeridianGridLines,
} from './mappingPaths';

test('layer Y positions stay strictly monotonic with zero overlap across explode 0..1', () => {
  for (const explode of [0, 0.35, 0.75, 1]) {
    const pos = computeLayerYPositions(explode, null);
    for (let i = 1; i < LAYER_ORDER.length; i++) {
      const prev = pos[LAYER_ORDER[i - 1]];
      const curr = pos[LAYER_ORDER[i]];
      assert.ok(
        curr - prev >= 0.119,
        `Expected non-overlapping clearance >= 0.12 at explode=${explode}, got ${curr - prev}`,
      );
    }
  }
});

test('focusing a layer widens adjacent vertical clearance and pulls the focused sheet forward', () => {
  const neutral = computeLayerTransforms(0.85, 0.3, null);
  const focused = computeLayerTransforms(0.85, 0.3, 'ir');

  assert.ok(focused.ir.y - focused.code.y > neutral.ir.y - neutral.code.y + 0.4);
  assert.ok(focused.panels.y - focused.ir.y > neutral.panels.y - neutral.ir.y + 0.4);
  assert.ok(focused.ir.z > neutral.ir.z + 2.0, 'Focused sheet should slide forward out of stack');
  assert.equal(focused.svg.z, neutral.svg.z, 'Unfocused sheets keep their staggered Z positions');
});

test('stagger offset fans lower sheets forward monotonically while keeping vertical alignment at 0%', () => {
  const aligned = computeLayerTransforms(0.88, 0, null);
  for (const id of LAYER_ORDER) {
    assert.equal(aligned[id].x, 0);
    assert.equal(aligned[id].z, 0);
  }

  const fanned = computeLayerTransforms(0.88, 1, null);
  assert.ok(fanned.code.z > fanned.ir.z && fanned.ir.z > fanned.svg.z);
  assert.ok(fanned.code.x < fanned.svg.x);
});

test('flat-tiled layout places all 6 sheets coplanar at y=BASE_STACK_Y with zero 2D overlap and clean gutters', () => {
  const tiled = computeLayerTransforms(0, 0, null, 'tiled');

  // All 6 layers share identical Y elevation (vertical layer spacing = 0)
  for (const id of LAYER_ORDER) {
    assert.equal(tiled[id].y, BASE_STACK_Y);
  }

  // Pairwise non-overlapping 2D AABB check with generous gutters >= 1.0 unit
  for (let i = 0; i < LAYER_ORDER.length; i++) {
    for (let j = i + 1; j < LAYER_ORDER.length; j++) {
      const a = tiled[LAYER_ORDER[i]];
      const b = tiled[LAYER_ORDER[j]];
      const dx = Math.abs(a.x - b.x);
      const dz = Math.abs(a.z - b.z);
      const separatedX = dx >= PLATE_WIDTH + 1.0;
      const separatedZ = dz >= PLATE_DEPTH + 1.5;
      assert.ok(
        separatedX || separatedZ,
        `Tiles ${LAYER_ORDER[i]} and ${LAYER_ORDER[j]} must not overlap (dx=${dx}, dz=${dz})`,
      );
    }
  }

  // Right-wing flat asset cards (asset-map, asset-bundle, asset-work) clear Col 2 sheets cleanly & never overlap each other
  const cards = getAssetCardTransforms('tiled');
  assert.ok(cards['asset-map'].x - 1.5 > tiled.panels.x + PLATE_WIDTH / 2);
  assert.ok(cards['asset-bundle'].x - 1.5 > tiled.svg.x + PLATE_WIDTH / 2);
  assert.ok(cards['asset-work'].x - 1.5 > tiled.svg.x + PLATE_WIDTH / 2);
  assert.ok(cards['asset-bundle'].z - cards['asset-map'].z > 2.5);
  assert.ok(cards['asset-work'].z - cards['asset-bundle'].z > 2.5);

  // Stacked right-wing cards maintain clean vertical separation
  const stackedCards = getAssetCardTransforms('stacked');
  assert.ok(stackedCards['asset-map'].y - stackedCards['asset-bundle'].y > 1.7);
  assert.ok(stackedCards['asset-bundle'].y - stackedCards['asset-work'].y > 1.7);
});

test('flat-tiled arched connections rise above coplanar sheets and remain finite across all modes', () => {
  const tiled = computeLayerTransforms(0, 0, null, 'tiled');

  for (const spec of MAPPING_MODES) {
    const rails = computeMeridianGridLines(tiled, spec.id, 'tiled');
    assert.ok(rails.length >= 9, `Expected drafting rails + panel arches for ${spec.id}`);

    const curves = computeMappingPaths(
      spec.id,
      spec.id === 'point-lineage' ? 'S19' : null,
      tiled,
      'tiled',
    );
    assert.ok(curves.length >= 4, `Expected arched mapping curves in tiled mode for ${spec.id}`);
    for (const c of curves) {
      assert.ok(c.points.length >= 3, `Tiled curve ${c.id} must have >= 3 control points for arching`);
      const maxY = Math.max(...c.points.map((p) => p[1]));
      assert.ok(
        maxY > BASE_STACK_Y + 0.25,
        `Tiled bus/arch ${c.id} should clear coplanar sheets cleanly (maxY=${maxY})`,
      );
      c.points.forEach((pt) => pt.forEach((n) => assert.ok(Number.isFinite(n))));
    }

    const callouts = computeFlowCallouts(
      spec.id,
      spec.id === 'point-lineage' ? 'S19' : null,
      tiled,
      'tiled',
    );
    assert.ok(callouts.length >= 2 && callouts.length <= 3);
    callouts.forEach((b) => b.position.forEach((n) => assert.ok(Number.isFinite(n))));

    const cam = getCameraTargetState('tiled', null, null, 0, spec.id, 0, 'tiled');
    cam.position.forEach((n) => assert.ok(Number.isFinite(n)));
    cam.target.forEach((n) => assert.ok(Number.isFinite(n)));
  }
});

test('mapDataToPlateLocal maps PCA corners symmetrically within plate bounds', () => {
  const bl = mapDataToPlateLocal(-10, -10);
  const tr = mapDataToPlateLocal(10, 10);
  const center = mapDataToPlateLocal(0, 0);

  assert.ok(Math.abs(bl.x - PLOT_LOCAL_BOUNDS.minX) < 1e-9);
  assert.ok(Math.abs(bl.z - PLOT_LOCAL_BOUNDS.maxZ) < 1e-9);
  assert.ok(Math.abs(tr.x - PLOT_LOCAL_BOUNDS.maxX) < 1e-9);
  assert.ok(Math.abs(tr.z - PLOT_LOCAL_BOUNDS.minZ) < 1e-9);
  assert.ok(Math.abs(center.u - 0.5) < 1e-6);
  assert.ok(Math.abs(center.v - 0.5) < 1e-6);
});

test('dampValue approaches target smoothly and stays bounded', () => {
  const next = dampValue(0, 10, 6, 0.016);
  assert.ok(next > 0 && next < 10);
  assert.equal(dampValue(5, 5, 6, 0.016), 5);
});

test('traceSampleLineage resolves all 20 PCA samples and returns null for unknown IDs', () => {
  assert.equal(PCA_SAMPLES.length, 20);
  assert.equal(ARCHITECTURE_LAYERS.length, 6);

  const s1 = traceSampleLineage('S1');
  assert.ok(s1 !== null);
  assert.equal(s1.sample.group, 'A');
  assert.equal(s1.sample.colorHex, '#2F855A');
  assert.equal(s1.sample.panelId, 'P1');
  assert.equal(s1.sample.leafId, 'L004');
  assert.equal(s1.cardinality, '1:1');

  const s14 = traceSampleLineage('S14');
  assert.ok(s14 !== null);
  assert.equal(s14.sample.group, 'B');
  assert.equal(s14.sample.colorHex, '#DF6A2B');
  assert.equal(s14.sample.panelId, 'P2');
  assert.equal(s14.sample.leafId, 'L005');

  const s19 = traceSampleLineage('S19');
  assert.ok(s19 !== null);
  assert.equal(s19.sample.patientId, 'PT-2019');
  assert.equal(s19.sample.rowId, 19);

  assert.equal(traceSampleLineage('S999'), null);
});

test('meridian grid lines and key-element mapping paths stay anchored across staggered & focused transforms', () => {
  const configs = [
    computeLayerTransforms(0.88, 0, null),
    computeLayerTransforms(0.88, 0.75, null),
    computeLayerTransforms(0.88, 0.3, 'panels'),
  ];

  for (const transforms of configs) {
    for (const spec of MAPPING_MODES) {
      const meridians = computeMeridianGridLines(transforms, spec.id);
      assert.ok(meridians.length >= 18, `Expected >= 18 meridian lines for ${spec.id}`);
      for (const m of meridians) {
        assert.ok(m.points.length >= 4, 'Meridian lines must pass through intermediate sheets');
        for (let i = 1; i < m.points.length; i++) {
          assert.ok(
            m.points[i][1] > m.points[i - 1][1],
            'Meridian Y coordinates must increase monotonically',
          );
        }
      }

      const curves = computeMappingPaths(
        spec.id,
        spec.id === 'point-lineage' ? 'S19' : null,
        transforms,
      );
      assert.ok(curves.length >= 6, `Expected semantic mapping curves for ${spec.id}`);
      for (const c of curves) {
        assert.ok(c.points.length >= 2);
        c.points.forEach((pt) => {
          pt.forEach((n) => assert.ok(Number.isFinite(n)));
        });
      }

      const callouts = computeFlowCallouts(
        spec.id,
        spec.id === 'point-lineage' ? 'S19' : null,
        transforms,
      );
      assert.ok(callouts.length >= 2 && callouts.length <= 3, `Expected 2..3 callouts for ${spec.id}`);
      for (const badge of callouts) {
        assert.ok(badge.code.length > 0 && badge.role.length > 0);
        badge.position.forEach((n) => assert.ok(Number.isFinite(n)));
      }

      const cam = getCameraTargetState('isometric', null, null, 0.88, spec.id, 0.5);
      cam.position.forEach((n) => assert.ok(Number.isFinite(n)));
      cam.target.forEach((n) => assert.ok(Number.isFinite(n)));
    }
  }
});

test('4-layer open contract, 3 glue chains, and 4 progressive scenarios reference valid layers and modes', () => {
  assert.equal(CONTRACT_LAYERS.length, 4);
  for (const cl of CONTRACT_LAYERS) {
    assert.ok(cl.svgPainPoint.length > 0);
    assert.ok(cl.components.length >= 3);
    for (const comp of cl.components) {
      assert.ok(LAYER_ORDER.includes(comp.targetLayerId));
    }
  }

  assert.equal(GLUE_CHAINS.length, 3);
  const validModes = new Set(MAPPING_MODES.map((m) => m.id));
  for (const gc of GLUE_CHAINS) {
    assert.ok(validModes.has(gc.mappingMode));
    assert.ok(gc.keys.length >= 2);
  }

  assert.equal(PROGRESSIVE_SCENARIOS.length, 4);
  for (const sc of PROGRESSIVE_SCENARIOS) {
    assert.ok(validModes.has(sc.targetMode));
    assert.ok(sc.encodingSteps.length >= 2);
    assert.ok(sc.cliCommand.length > 0);
    if (sc.targetSampleId) {
      assert.ok(traceSampleLineage(sc.targetSampleId) !== null);
    }
  }
});

test('Schema v1.1.0 real-project specs (APIs, engines, skills, live status, JSON) stay valid and aligned', () => {
  const parsedMap = JSON.parse(ASSET_MAP_JSON);
  assert.equal(parsedMap.schema_version, '1.1.0');
  assert.equal(parsedMap.scene.coord.origin, 'top-left');
  assert.equal(parsedMap.scene.texts.path, 'scene/texts.json');
  assert.equal(parsedMap.scene.preview_png.path, 'assets/preview.png');
  assert.equal(parsedMap.ir.panels[0].domain_space, 'transformed');
  assert.equal(parsedMap.ir.layers[0].row_accounting.n_raw, 20);
  assert.equal(parsedMap.ir.guides.entries[0].kind, 'legend');
  assert.equal(parsedMap.lineage[0].edit_policy, 'geometry_locked');
  assert.equal(parsedMap.lineage[0].lineage_tier, 'row_exact');

  assert.equal(PUBLIC_APIS.length, 8);
  assert.equal(ENGINE_COVERAGE.length, 5);
  assert.equal(DESIGN_PRINCIPLES.length, 5);
  assert.equal(END_TO_END_PATHS.length, 6);
  assert.equal(ROADMAP_STAGES.length, 4);
  assert.equal(COMPANION_WORK_TREE.length, 1);
  assert.equal(ECOSYSTEM_CONSUMERS.filter((e) => e.status === 'implemented').length, 4);
  assert.equal(ECOSYSTEM_CONSUMERS.filter((e) => e.status === 'planned').length, 2);
  assert.equal(PROJECT_LIVE_STATUS.schemaVersion, '1.1.0');
  assert.equal(PROJECT_LIVE_STATUS.guardrails.length, 5);
  assert.ok(PROJECT_LIVE_STATUS.guardrails.every((g) => g.pass));

  const s19 = traceSampleLineage('S19');
  assert.ok(s19 !== null);
  assert.equal(s19.lineageTier, 'row_exact');
  assert.ok(s19.builtRow.includes('_raw_row_id=19'));
  assert.ok(s19.semanticsLock.includes('geometry_locked'));

  const validModes = new Set(MAPPING_MODES.map((m) => m.id));
  for (const ep of END_TO_END_PATHS) {
    assert.ok(validModes.has(ep.targetMode));
  }
});

test('pipeline steps map to valid architecture layers', () => {
  for (let step = 1; step <= 5; step++) {
    const layers = getPipelineHighlightLayers(step);
    assert.ok(layers.length >= 1);
    for (const id of layers) {
      assert.ok(LAYER_ORDER.includes(id));
    }
  }
});
