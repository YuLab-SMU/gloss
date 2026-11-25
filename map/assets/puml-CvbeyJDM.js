var e=e=>{switch(e){case`index`:return`@startuml
title "01 · gloss System Landscape & Alignment Overview"
left to right direction

hide stereotype
skinparam ranksep 60
skinparam nodesep 30
skinparam {
  arrowFontSize 10
  defaultTextAlignment center
  wrapWidth 200
  maxMessageSize 100
  shadowing false
}

skinparam person<<User>>{
  BackgroundColor #64748b
  FontColor #f8fafc
  BorderColor #475569
}
skinparam rectangle<<Principles>>{
  BackgroundColor #0F766E
  FontColor #c7ffff
  BorderColor #00524b
}
skinparam rectangle<<Ecosystem>>{
  BackgroundColor #7C3AED
  FontColor #ffffff
  BorderColor #4e0cc3
}
skinparam rectangle<<Gloss_core>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Open_assetsAsset_map>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Open_assetsAsset_bundle>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
person "==R Analyst / AI Coding Agent\\n\\nAuthors R figures in an active R session or consumes portable .gloss assets for Q&A, publication SVG refinement, and statistical auditing." <<User>> as User
rectangle "==Design Principles & Alignment Guardrails\\n\\nCanonical architectural invariants from AGENTS.md paired with live code-vs-intent verification checks." <<Principles>> as Principles
rectangle "==Outer Ecosystem (Out-of-Core)\\n\\nIndependent skills, live bridge, static frontend, and cross-language scripts collaborating exclusively over Asset Map & Asset Bundle contracts." <<Ecosystem>> as Ecosystem
rectangle "==gloss R Core Package\\n<size:10>[R (>= 4.2.0), svglite, xml2, jsonlite, digest]</size>\\n\\nLightweight R core package: single-draw device capture, Engine IR extraction, structural lineage, runtime source inventory, and open asset packaging." <<Gloss_core>> as Gloss_core
rectangle "Open File Contracts" <<Open_assets>> as Open_assets {
  skinparam RectangleBorderColor<<Open_assets>> #0F766E
  skinparam RectangleFontColor<<Open_assets>> #0F766E
  skinparam RectangleBorderStyle<<Open_assets>> dashed

  rectangle "==Asset Map (asset-map.json)\\n<size:10>[JSON (~tens of KB)]</size>\\n\\nLightweight global catalog of page geometry, SVG digests, Engine IR (panels, layers, scales, orders), table column summaries, lineage, and source pointers." <<Open_assetsAsset_map>> as Open_assetsAsset_map
  rectangle "==Asset Bundle (figure.gloss/ or .zip)\\n<size:10>[UTF-8 SVG + JSON + CSV + PNG]</size>\\n\\nSelf-contained portable bundle: manifest.json, asset-map.json, omitted.json, assets/original.svg, scene/{scene.svg,leaves.json,elements.json,rasters/}, tables/{schema.json,*.csv}, sources/." <<Open_assetsAsset_bundle>> as Open_assetsAsset_bundle
}

User .[#8D8D8D,thickness=2].> Gloss_core : <color:#8D8D8D>Captures R figure + sources
Principles .[#a35905,thickness=2].> Gloss_core : <color:#a35905>Guards architecture, surface & CRAN hygiene
Gloss_core .[#026395,thickness=2].> Open_assetsAsset_map : <color:#026395>gl_asset_map()
Gloss_core .[#026395,thickness=2].> Open_assetsAsset_bundle : <color:#026395>gl_asset_bundle()
Ecosystem .[#5d2cb2,thickness=2].> Gloss_core : <color:#5d2cb2>Calls 4 core functions in live R
Ecosystem .[#026395,thickness=2].> Open_assetsAsset_map : <color:#026395>Reads compact map first
Ecosystem .[#026395,thickness=2].> Open_assetsAsset_bundle : <color:#026395>[...]
@enduml
`;case`core_architecture`:return`@startuml
title "02 · R Core Internal Architecture (Modules, Engines & APIs)"
top to bottom direction

hide stereotype
skinparam ranksep 60
skinparam nodesep 30
skinparam {
  arrowFontSize 10
  defaultTextAlignment center
  wrapWidth 200
  maxMessageSize 100
  shadowing false
}

skinparam rectangle<<Gloss_corePublic_api>>{
  BackgroundColor #64748b
  FontColor #f8fafc
  BorderColor #475569
}
skinparam component<<Gloss_coreModulesMod_capture>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreModulesMod_package_assets>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreModulesMod_query>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreModulesMod_registry>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreModulesMod_sources>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreEnginesEng_grid>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreEnginesEng_ggplot>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreEnginesEng_patchwork>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreEnginesEng_heatmap>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreEnginesEng_base>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Open_assetsAsset_map>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Open_assetsAsset_bundle>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreModulesMod_utils>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreModulesMod_ir_lineage>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
rectangle "==Public API Surface (8 Exports)\\n\\nThe minimal, stable exported interface of gloss." <<Gloss_corePublic_api>> as Gloss_corePublic_api
rectangle "Core Internal Modules" <<Gloss_coreModules>> as Gloss_coreModules {
  skinparam RectangleBorderColor<<Gloss_coreModules>> #64748b
  skinparam RectangleFontColor<<Gloss_coreModules>> #64748b
  skinparam RectangleBorderStyle<<Gloss_coreModules>> dashed

  component "==Device Capture & SVG Instrumentation\\n<size:10>[R/capture.R]</size>\\n\\nsvglite::svgstring() single-draw dual SVG capture, grid display-list leaf wrapping, draw-time gloss_probe viewport recorder, <defs>/<use> inlining, xml2 geometry parsing, and dense PNG rasterization." <<Gloss_coreModulesMod_capture>> as Gloss_coreModulesMod_capture
  component "==Asset Map & Bundle Packager\\n<size:10>[R/package-assets.R]</size>\\n\\nLayered open-format serialization for asset-map.json and .gloss/ dir/zip bundles with SHA-256 manifest.json, column/row filtering, and omitted.json." <<Gloss_coreModulesMod_package_assets>> as Gloss_coreModulesMod_package_assets
  component "==In-Memory Query & Slicing\\n<size:10>[R/query.R]</size>\\n\\nRead-only inspection and panel/leaf/spatial-box/row slicing on gloss_capture objects." <<Gloss_coreModulesMod_query>> as Gloss_coreModulesMod_query
  component "==Engine Registry & Load Hook\\n<size:10>[R/engine-registry.R, R/zzz.R]</size>\\n\\nPrivate package environment registry, class-hierarchy & priority dispatch, page_kind candidate disambiguation, and lazy Suggests checks." <<Gloss_coreModulesMod_registry>> as Gloss_coreModulesMod_registry
  component "==Source Context Inventory\\n<size:10>[R/sources.R]</size>\\n\\nCollects explicit files/docs/inline snippets, runtime_observed session/package/git metadata, and knitr/Rscript sniffed_hint pointers." <<Gloss_coreModulesMod_sources>> as Gloss_coreModulesMod_sources
  component "==Contract & Open Serialization\\n<size:10>[R/utils.R]</size>\\n\\ngloss_capture S3 contract, deterministic capture_id, SHA-256 helpers, UTF-8 JSON/CSV writers with 1-based _row_id, and column schema inference." <<Gloss_coreModulesMod_utils>> as Gloss_coreModulesMod_utils
  component "==Engine IR & Structural Lineage\\n<size:10>[R/ir-lineage.R]</size>\\n\\nNormalizes panel coordinate domains, scale/palette dictionaries, layer specs, and neutral element-to-table cardinalities (1:1, N:1, 1:M, stat_aggregated)." <<Gloss_coreModulesMod_ir_lineage>> as Gloss_coreModulesMod_ir_lineage
}
rectangle "Built-in Plotting Engines (Suggests)" <<Gloss_coreEngines>> as Gloss_coreEngines {
  skinparam RectangleBorderColor<<Gloss_coreEngines>> #64748b
  skinparam RectangleFontColor<<Gloss_coreEngines>> #64748b
  skinparam RectangleBorderStyle<<Gloss_coreEngines>> dashed

  component "==grid Engine\\n<size:10>[R/engine-grid.R (grid)]</size>\\n\\nCaptures raw grid grobs, gLists, gTrees, gtables, grid drawing functions, and recorded grid plots." <<Gloss_coreEnginesEng_grid>> as Gloss_coreEnginesEng_grid
  component "==ggplot2 Engine\\n<size:10>[R/engine-ggplot.R (Suggests: ggplot2)]</size>\\n\\nSingle-build ggplot_build -> ggplot_gtable -> grid.draw extracting raw/built tables, scale/palette maps, layer recipes, facets, and neutral lineage." <<Gloss_coreEnginesEng_ggplot>> as Gloss_coreEnginesEng_ggplot
  component "==patchwork Engine\\n<size:10>[R/engine-patchwork.R (Suggests: patchwork)]</size>\\n\\nComposite multi-plot IR extraction with per-subplot panel and table namespaces without double-building stochastic subplots." <<Gloss_coreEnginesEng_patchwork>> as Gloss_coreEnginesEng_patchwork
  component "==ComplexHeatmap Engine\\n<size:10>[R/engine-heatmap.R (Suggests: ComplexHeatmap)]</size>\\n\\nSingle draw() capture preserving draw-time clustering permutations (row_order/column_order) in ir.orders, matrix/annotation tables, and color maps." <<Gloss_coreEnginesEng_heatmap>> as Gloss_coreEnginesEng_heatmap
  component "==base Graphics Engine\\n<size:10>[R/engine-base.R (grDevices/graphics)]</size>\\n\\nStep-by-step display-list replay on svglite isolating per-call <g id='L...'> leaves and par('usr')/par('plt') plot regions." <<Gloss_coreEnginesEng_base>> as Gloss_coreEnginesEng_base
}
rectangle "==Asset Map (asset-map.json)\\n<size:10>[JSON (~tens of KB)]</size>\\n\\nLightweight global catalog of page geometry, SVG digests, Engine IR (panels, layers, scales, orders), table column summaries, lineage, and source pointers." <<Open_assetsAsset_map>> as Open_assetsAsset_map
rectangle "==Asset Bundle (figure.gloss/ or .zip)\\n<size:10>[UTF-8 SVG + JSON + CSV + PNG]</size>\\n\\nSelf-contained portable bundle: manifest.json, asset-map.json, omitted.json, assets/original.svg, scene/{scene.svg,leaves.json,elements.json,rasters/}, tables/{schema.json,*.csv}, sources/." <<Open_assetsAsset_bundle>> as Open_assetsAsset_bundle

Gloss_corePublic_api .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_registry : <color:#8D8D8D>Registers engine spec
Gloss_corePublic_api .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_capture : <color:#8D8D8D>Orchestrates single-draw capture
Gloss_corePublic_api .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_package_assets : <color:#8D8D8D>[...]
Gloss_corePublic_api .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_query : <color:#8D8D8D>[...]
Gloss_coreModulesMod_capture .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_utils : <color:#8D8D8D>Builds validated gloss_capture
Gloss_coreModulesMod_package_assets .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_utils : <color:#8D8D8D>Writes UTF-8 JSON, CSV & SHA-256
Gloss_coreModulesMod_query .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_utils : <color:#8D8D8D>Validates gloss_capture
Gloss_coreModulesMod_capture .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_registry : <color:#8D8D8D>Dispatches by class & page_kind
Gloss_coreModulesMod_capture .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_sources : <color:#8D8D8D>Snapshots provenance & session
Gloss_coreModulesMod_package_assets .[#026395,thickness=2].> Open_assetsAsset_map : <color:#026395>gl_asset_map()
Gloss_coreModulesMod_package_assets .[#026395,thickness=2].> Open_assetsAsset_bundle : <color:#026395>gl_asset_bundle()
Gloss_coreEngines .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_ir_lineage : <color:#8D8D8D>Normalizes IR & lineage
Gloss_coreModulesMod_capture .[#8D8D8D,thickness=2].> Gloss_coreEngines : <color:#8D8D8D>Invokes engine capture_fn
@enduml
`;case`public_api_surface`:return`@startuml
title "03 · Public API Surface (8 Exports Contract)"
left to right direction

hide stereotype
skinparam ranksep 60
skinparam nodesep 30
skinparam {
  arrowFontSize 10
  defaultTextAlignment center
  wrapWidth 200
  maxMessageSize 100
  shadowing false
}

skinparam person<<User>>{
  BackgroundColor #64748b
  FontColor #f8fafc
  BorderColor #475569
}
skinparam rectangle<<Gloss_corePublic_apiFn_register_engine>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Gloss_corePublic_apiFn_asset_map>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Gloss_corePublic_apiFn_asset_bundle>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Gloss_corePublic_apiFn_scene>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Gloss_corePublic_apiFn_tables>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Gloss_corePublic_apiFn_sources>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Gloss_corePublic_apiFn_query>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Gloss_corePublic_apiFn_gloss>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreModulesMod_package_assets>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreModulesMod_query>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreModulesMod_capture>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreModulesMod_registry>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
person "==R Analyst / AI Coding Agent\\n\\nAuthors R figures in an active R session or consumes portable .gloss assets for Q&A, publication SVG refinement, and statistical auditing." <<User>> as User
rectangle "==gl_register_engine()\\n\\nRegister built-in or third-party plotting engines by S3/S4 class and page kind." <<Gloss_corePublic_apiFn_register_engine>> as Gloss_corePublic_apiFn_register_engine
rectangle "==gl_asset_map()\\n\\nSerialize compact asset-map.json index from an in-memory gloss_capture without redrawing." <<Gloss_corePublic_apiFn_asset_map>> as Gloss_corePublic_apiFn_asset_map
rectangle "==gl_asset_bundle()\\n\\nPackage portable .gloss/ directory or .zip bundle with manifest.json, omitted.json, dual SVG, CSV tables, and sources." <<Gloss_corePublic_apiFn_asset_bundle>> as Gloss_corePublic_apiFn_asset_bundle
rectangle "==gl_scene()\\n\\nInspect captured page metadata, dual SVG descriptors, leaves, elements, rasters, and panels in memory." <<Gloss_corePublic_apiFn_scene>> as Gloss_corePublic_apiFn_scene
rectangle "==gl_tables()\\n\\nAccess raw and engine-built data frames from an in-memory gloss_capture." <<Gloss_corePublic_apiFn_tables>> as Gloss_corePublic_apiFn_tables
rectangle "==gl_sources()\\n\\nInspect explicit, runtime_observed, and sniffed_hint source inventory table." <<Gloss_corePublic_apiFn_sources>> as Gloss_corePublic_apiFn_sources
rectangle "==gl_query()\\n\\nComposable structural, spatial (SVG bbox), and tabular slicing over an in-memory gloss_capture." <<Gloss_corePublic_apiFn_query>> as Gloss_corePublic_apiFn_query
rectangle "==gloss()\\n\\nDraw once on svglite, instrument dual SVG + viewport probes, extract Engine IR, lineage, and sources into a gloss_capture object." <<Gloss_corePublic_apiFn_gloss>> as Gloss_corePublic_apiFn_gloss
component "==Asset Map & Bundle Packager\\n<size:10>[R/package-assets.R]</size>\\n\\nLayered open-format serialization for asset-map.json and .gloss/ dir/zip bundles with SHA-256 manifest.json, column/row filtering, and omitted.json." <<Gloss_coreModulesMod_package_assets>> as Gloss_coreModulesMod_package_assets
component "==In-Memory Query & Slicing\\n<size:10>[R/query.R]</size>\\n\\nRead-only inspection and panel/leaf/spatial-box/row slicing on gloss_capture objects." <<Gloss_coreModulesMod_query>> as Gloss_coreModulesMod_query
component "==Device Capture & SVG Instrumentation\\n<size:10>[R/capture.R]</size>\\n\\nsvglite::svgstring() single-draw dual SVG capture, grid display-list leaf wrapping, draw-time gloss_probe viewport recorder, <defs>/<use> inlining, xml2 geometry parsing, and dense PNG rasterization." <<Gloss_coreModulesMod_capture>> as Gloss_coreModulesMod_capture
component "==Engine Registry & Load Hook\\n<size:10>[R/engine-registry.R, R/zzz.R]</size>\\n\\nPrivate package environment registry, class-hierarchy & priority dispatch, page_kind candidate disambiguation, and lazy Suggests checks." <<Gloss_coreModulesMod_registry>> as Gloss_coreModulesMod_registry

User .[#8D8D8D,thickness=2].> Gloss_corePublic_apiFn_gloss : <color:#8D8D8D>Captures R figure + sources
Gloss_corePublic_apiFn_gloss .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_capture : <color:#8D8D8D>Orchestrates single-draw capture
Gloss_corePublic_apiFn_register_engine .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_registry : <color:#8D8D8D>Registers engine spec
Gloss_coreModulesMod_capture .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_registry : <color:#8D8D8D>Dispatches by class & page_kind
Gloss_corePublic_apiFn_asset_map .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_package_assets : <color:#8D8D8D>Serializes asset-map.json
Gloss_corePublic_apiFn_asset_bundle .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_package_assets : <color:#8D8D8D>Writes .gloss/ or .zip
Gloss_corePublic_apiFn_scene .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_query : <color:#8D8D8D>Reads scene view
Gloss_corePublic_apiFn_tables .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_query : <color:#8D8D8D>Reads data frames
Gloss_corePublic_apiFn_sources .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_query : <color:#8D8D8D>Reads source table
Gloss_corePublic_apiFn_query .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_query : <color:#8D8D8D>Slices leaves, elements & rows
@enduml
`;case`engines_matrix`:return`@startuml
title "04 · Built-in Plotting Engines Matrix"
left to right direction

hide stereotype
skinparam ranksep 60
skinparam nodesep 30
skinparam {
  arrowFontSize 10
  defaultTextAlignment center
  wrapWidth 200
  maxMessageSize 100
  shadowing false
}

skinparam component<<Gloss_coreModulesMod_capture>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreModulesMod_registry>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreEnginesEng_grid>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreEnginesEng_ggplot>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreEnginesEng_patchwork>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreEnginesEng_heatmap>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreEnginesEng_base>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam component<<Gloss_coreModulesMod_ir_lineage>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
component "==Device Capture & SVG Instrumentation\\n<size:10>[R/capture.R]</size>\\n\\nsvglite::svgstring() single-draw dual SVG capture, grid display-list leaf wrapping, draw-time gloss_probe viewport recorder, <defs>/<use> inlining, xml2 geometry parsing, and dense PNG rasterization." <<Gloss_coreModulesMod_capture>> as Gloss_coreModulesMod_capture
component "==Engine Registry & Load Hook\\n<size:10>[R/engine-registry.R, R/zzz.R]</size>\\n\\nPrivate package environment registry, class-hierarchy & priority dispatch, page_kind candidate disambiguation, and lazy Suggests checks." <<Gloss_coreModulesMod_registry>> as Gloss_coreModulesMod_registry
component "==grid Engine\\n<size:10>[R/engine-grid.R (grid)]</size>\\n\\nCaptures raw grid grobs, gLists, gTrees, gtables, grid drawing functions, and recorded grid plots." <<Gloss_coreEnginesEng_grid>> as Gloss_coreEnginesEng_grid
component "==ggplot2 Engine\\n<size:10>[R/engine-ggplot.R (Suggests: ggplot2)]</size>\\n\\nSingle-build ggplot_build -> ggplot_gtable -> grid.draw extracting raw/built tables, scale/palette maps, layer recipes, facets, and neutral lineage." <<Gloss_coreEnginesEng_ggplot>> as Gloss_coreEnginesEng_ggplot
component "==patchwork Engine\\n<size:10>[R/engine-patchwork.R (Suggests: patchwork)]</size>\\n\\nComposite multi-plot IR extraction with per-subplot panel and table namespaces without double-building stochastic subplots." <<Gloss_coreEnginesEng_patchwork>> as Gloss_coreEnginesEng_patchwork
component "==ComplexHeatmap Engine\\n<size:10>[R/engine-heatmap.R (Suggests: ComplexHeatmap)]</size>\\n\\nSingle draw() capture preserving draw-time clustering permutations (row_order/column_order) in ir.orders, matrix/annotation tables, and color maps." <<Gloss_coreEnginesEng_heatmap>> as Gloss_coreEnginesEng_heatmap
component "==base Graphics Engine\\n<size:10>[R/engine-base.R (grDevices/graphics)]</size>\\n\\nStep-by-step display-list replay on svglite isolating per-call <g id='L...'> leaves and par('usr')/par('plt') plot regions." <<Gloss_coreEnginesEng_base>> as Gloss_coreEnginesEng_base
component "==Engine IR & Structural Lineage\\n<size:10>[R/ir-lineage.R]</size>\\n\\nNormalizes panel coordinate domains, scale/palette dictionaries, layer specs, and neutral element-to-table cardinalities (1:1, N:1, 1:M, stat_aggregated)." <<Gloss_coreModulesMod_ir_lineage>> as Gloss_coreModulesMod_ir_lineage

Gloss_coreModulesMod_capture .[#8D8D8D,thickness=2].> Gloss_coreModulesMod_registry : <color:#8D8D8D>Dispatches by class & page_kind
@enduml
`;case`guardrails_monitor`:return`@startuml
title "05 · Design Intent vs Code Alignment Guardrails"
left to right direction

hide stereotype
skinparam ranksep 60
skinparam nodesep 30
skinparam {
  arrowFontSize 10
  defaultTextAlignment center
  wrapWidth 200
  maxMessageSize 100
  shadowing false
}

skinparam rectangle<<PrinciplesP1_source_map>>{
  BackgroundColor #D97706
  FontColor #ffffff
  BorderColor #ac5300
}
skinparam rectangle<<PrinciplesP2_core_boundary>>{
  BackgroundColor #D97706
  FontColor #ffffff
  BorderColor #ac5300
}
skinparam rectangle<<PrinciplesP3_single_capture>>{
  BackgroundColor #D97706
  FontColor #ffffff
  BorderColor #ac5300
}
skinparam rectangle<<PrinciplesP4_file_first>>{
  BackgroundColor #D97706
  FontColor #ffffff
  BorderColor #ac5300
}
skinparam rectangle<<PrinciplesP5_minimal_surface>>{
  BackgroundColor #D97706
  FontColor #ffffff
  BorderColor #ac5300
}
skinparam rectangle<<PrinciplesG_tests>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<PrinciplesG_core_boundary>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<PrinciplesG_cran_hygiene>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<PrinciplesG_exports>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<PrinciplesG_suggests>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Gloss_core>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
rectangle "==P1 · Compiler Source Map, Not Gatekeeper\\n\\nFaithfully observe and record device groups, viewports, engine IR, and neutral lineage cardinalities. Verification belongs to upper-layer semantic tools, never low-level capture gates." <<PrinciplesP1_source_map>> as PrinciplesP1_source_map
rectangle "==P2 · Strict In-Core Boundary\\n\\nThe R package owns only live-R graphics device instrumentation, engine IR extraction, runtime source inventory, and open-format packaging. Agents, MCP, Workbench, and SVG refinement live outside core." <<PrinciplesP2_core_boundary>> as PrinciplesP2_core_boundary
rectangle "==P3 · Single Capture, Layered Payload\\n\\nAsset Map and Asset Bundle serialize from the same in-memory gloss_capture object so figures (including stochastic jitter/UMAP) are never redrawn during packaging." <<PrinciplesP3_single_capture>> as PrinciplesP3_single_capture
rectangle "==P4 · File-First, Zero Proprietary Codecs\\n\\nEmit standard UTF-8 SVG, JSON, and CSV (or Parquet) readable directly by Python, JS, DuckDB, R, and coding agents without custom binary decoders or background R processes." <<PrinciplesP4_file_first>> as PrinciplesP4_file_first
rectangle "==P5 · Minimal Export Surface (8 APIs)\\n\\nKeep NAMESPACE tight at exactly 8 exported functions and keep built-in engines in-repo with package dependencies strictly in Suggests." <<PrinciplesP5_minimal_surface>> as PrinciplesP5_minimal_surface
rectangle "==Guardrail · Unit Test & Build Health\\n\\nTracks live testthat suite coverage across core modules and engines." <<PrinciplesG_tests>> as PrinciplesG_tests
rectangle "==Guardrail · Strict In-Core Boundary\\n\\nVerifies R/ contains no out-of-core agent runners, MCP servers, binary codecs, or embedded UI code." <<PrinciplesG_core_boundary>> as PrinciplesG_core_boundary
rectangle "==Guardrail · CRAN & R Hygiene\\n\\nChecks R/ and tests/ for forbidden super-assignment (<<-), .GlobalEnv writes, and stray Rplots.pdf artifacts." <<PrinciplesG_cran_hygiene>> as PrinciplesG_cran_hygiene
rectangle "==Guardrail · Export Surface Alignment (8 APIs)\\n\\nVerifies NAMESPACE exports match the 8 canonical functions in AGENTS.md with zero unexpected exports." <<PrinciplesG_exports>> as PrinciplesG_exports
rectangle "==Guardrail · Engine Dependencies in Suggests\\n\\nVerifies ggplot2, patchwork, ComplexHeatmap stay in DESCRIPTION Suggests and never leak into Imports." <<PrinciplesG_suggests>> as PrinciplesG_suggests
rectangle "==gloss R Core Package\\n<size:10>[R (>= 4.2.0), svglite, xml2, jsonlite, digest]</size>\\n\\nLightweight R core package: single-draw device capture, Engine IR extraction, structural lineage, runtime source inventory, and open asset packaging." <<Gloss_core>> as Gloss_core

PrinciplesP1_source_map .[#a35905,thickness=2].> PrinciplesG_tests : <color:#a35905>Verifies neutral capture facts
PrinciplesP2_core_boundary .[#a35905,thickness=2].> PrinciplesG_core_boundary : <color:#a35905>Prevents v1 scope creep
PrinciplesP4_file_first .[#a35905,thickness=2].> PrinciplesG_cran_hygiene : <color:#a35905>Verifies clean open packaging
PrinciplesP5_minimal_surface .[#a35905,thickness=2].> PrinciplesG_exports : <color:#a35905>Enforces 8-API contract
PrinciplesP5_minimal_surface .[#a35905,thickness=2].> PrinciplesG_suggests : <color:#a35905>Enforces Suggests isolation
@enduml
`;case`open_contracts`:return`@startuml
title "06 · Open File Contracts & Outer Ecosystem"
left to right direction

hide stereotype
skinparam ranksep 60
skinparam nodesep 30
skinparam {
  arrowFontSize 10
  defaultTextAlignment center
  wrapWidth 200
  maxMessageSize 100
  shadowing false
}

skinparam rectangle<<EcosystemSkill_gloss>>{
  BackgroundColor #7C3AED
  FontColor #ffffff
  BorderColor #4e0cc3
}
skinparam rectangle<<EcosystemWorkbench>>{
  BackgroundColor #7C3AED
  FontColor #ffffff
  BorderColor #4e0cc3
}
skinparam rectangle<<EcosystemExternal_scripts>>{
  BackgroundColor #7C3AED
  FontColor #ffffff
  BorderColor #4e0cc3
}
skinparam rectangle<<EcosystemSkill_refine>>{
  BackgroundColor #7C3AED
  FontColor #ffffff
  BorderColor #4e0cc3
}
skinparam rectangle<<EcosystemSkill_audit>>{
  BackgroundColor #7C3AED
  FontColor #ffffff
  BorderColor #4e0cc3
}
skinparam rectangle<<EcosystemSkill_report>>{
  BackgroundColor #7C3AED
  FontColor #ffffff
  BorderColor #4e0cc3
}
skinparam rectangle<<EcosystemGloss_mcp>>{
  BackgroundColor #7C3AED
  FontColor #ffffff
  BorderColor #4e0cc3
}
skinparam rectangle<<Gloss_core>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Open_assetsAsset_map>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
skinparam rectangle<<Open_assetsAsset_bundle>>{
  BackgroundColor #16A34A
  FontColor #ffffff
  BorderColor #007c27
}
rectangle "Outer Ecosystem (Out-of-Core)" <<Ecosystem>> as Ecosystem {
  skinparam RectangleBorderColor<<Ecosystem>> #7C3AED
  skinparam RectangleFontColor<<Ecosystem>> #7C3AED
  skinparam RectangleBorderStyle<<Ecosystem>> dashed

  rectangle "==Base Protocol Skill: gloss\\n<size:10>[SKILL.md]</size>\\n\\nEntry protocol guiding AI coding agents to read asset-map.json first, plan task context packets, and selectively unpack tables/sources." <<EcosystemSkill_gloss>> as EcosystemSkill_gloss
  rectangle "==Static Frontend: Workbench\\n<size:10>[Static SPA (Browser)]</size>\\n\\nZero-decoder browser inspector for .gloss bundles: layer outline tree, raw/built data tables, bidirectional brushing, and original-vs-derived SVG diff." <<EcosystemWorkbench>> as EcosystemWorkbench
  rectangle "==Python / JS / DuckDB Toolchains\\n<size:10>[pandas, polars, DuckDB, lxml]</size>\\n\\nDirect batch analytics and automated publishing pipelines reading standard SVG/JSON/CSV without installing R." <<EcosystemExternal_scripts>> as EcosystemExternal_scripts
  rectangle "==SVG Refinement Skill: gloss-svg-refine\\n<size:10>[SKILL.md]</size>\\n\\nPublication-grade label repulsion, typography hierarchy, legend layout, and palette updates producing derived SVGs linked via parent_manifest_sha256." <<EcosystemSkill_refine>> as EcosystemSkill_refine
  rectangle "==Semantic Audit Skill: gloss-audit\\n<size:10>[SKILL.md]</size>\\n\\nHigh-level verification checking manuscript claims, sample sizes, statistical summaries, and derived SVG geometric fidelity against bundle tables." <<EcosystemSkill_audit>> as EcosystemSkill_audit
  rectangle "==Report Skill: gloss-report\\n<size:10>[SKILL.md]</size>\\n\\nSynthesizes traceable multi-figure analysis reports backed by table rows, leaf IDs, and methods docs." <<EcosystemSkill_report>> as EcosystemSkill_report
  rectangle "==Live R Bridge: gloss-mcp\\n<size:10>[Thin 4-tool MCP Adapter]</size>\\n\\nOptional bridge for interactive RStudio/Positron sessions or million-row tables: capture_figure, get_asset_map, query_slice, create_bundle." <<EcosystemGloss_mcp>> as EcosystemGloss_mcp
}
rectangle "==gloss R Core Package\\n<size:10>[R (>= 4.2.0), svglite, xml2, jsonlite, digest]</size>\\n\\nLightweight R core package: single-draw device capture, Engine IR extraction, structural lineage, runtime source inventory, and open asset packaging." <<Gloss_core>> as Gloss_core
rectangle "Open File Contracts" <<Open_assets>> as Open_assets {
  skinparam RectangleBorderColor<<Open_assets>> #0F766E
  skinparam RectangleFontColor<<Open_assets>> #0F766E
  skinparam RectangleBorderStyle<<Open_assets>> dashed

  rectangle "==Asset Map (asset-map.json)\\n<size:10>[JSON (~tens of KB)]</size>\\n\\nLightweight global catalog of page geometry, SVG digests, Engine IR (panels, layers, scales, orders), table column summaries, lineage, and source pointers." <<Open_assetsAsset_map>> as Open_assetsAsset_map
  rectangle "==Asset Bundle (figure.gloss/ or .zip)\\n<size:10>[UTF-8 SVG + JSON + CSV + PNG]</size>\\n\\nSelf-contained portable bundle: manifest.json, asset-map.json, omitted.json, assets/original.svg, scene/{scene.svg,leaves.json,elements.json,rasters/}, tables/{schema.json,*.csv}, sources/." <<Open_assetsAsset_bundle>> as Open_assetsAsset_bundle
}

Gloss_core .[#026395,thickness=2].> Open_assetsAsset_map : <color:#026395>gl_asset_map()
Gloss_core .[#026395,thickness=2].> Open_assetsAsset_bundle : <color:#026395>gl_asset_bundle()
EcosystemSkill_gloss .[#026395,thickness=2].> Open_assetsAsset_map : <color:#026395>Reads compact map first
EcosystemSkill_gloss .[#026395,thickness=2].> Open_assetsAsset_bundle : <color:#026395>Reads targeted CSV/SVG slices
EcosystemGloss_mcp .[#5d2cb2,thickness=2].> Gloss_core : <color:#5d2cb2>Calls 4 core functions in live R
EcosystemWorkbench .[#026395,thickness=2].> Open_assetsAsset_bundle : <color:#026395>Opens .gloss dir / zip
EcosystemExternal_scripts .[#026395,thickness=2].> Open_assetsAsset_bundle : <color:#026395>Batch SQL / Python / JS
EcosystemSkill_gloss .[#8D8D8D,thickness=2].> EcosystemSkill_refine : <color:#8D8D8D>Delegates visual refinement
EcosystemSkill_gloss .[#8D8D8D,thickness=2].> EcosystemSkill_audit : <color:#8D8D8D>Delegates statistical/caption verification
EcosystemSkill_gloss .[#8D8D8D,thickness=2].> EcosystemSkill_report : <color:#8D8D8D>Delegates multi-figure reporting
EcosystemSkill_gloss .[#5d2cb2,thickness=2].> EcosystemGloss_mcp : <color:#5d2cb2>Optional live-session queries
@enduml
`;default:throw Error(`Unknown viewId: `+e)}};export{e as pumlSource};