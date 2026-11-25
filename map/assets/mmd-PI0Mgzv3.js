var e=e=>{switch(e){case`index`:return`---
title: "01 · gloss System Landscape & Alignment Overview"
---
graph LR
  User@{ icon: "fa:user", shape: rounded, label: "R Analyst / AI Coding Agent" }
  Principles@{ shape: rectangle, label: "Design Principles & Alignment Guardrails" }
  Ecosystem@{ shape: rectangle, label: "Outer Ecosystem (Out-of-Core)" }
  Gloss_core@{ shape: rectangle, label: "gloss R Core Package" }
  subgraph Open_assets["\`Open File Contracts\`"]
    Open_assets.Asset_map@{ shape: doc, label: "Asset Map (asset-map.json)" }
    Open_assets.Asset_bundle@{ shape: doc, label: "Asset Bundle (figure.gloss/ or .zip)" }
  end
  User -. "\`Captures R figure + sources\`" .-> Gloss_core
  Principles -. "\`Guards architecture, surface & CRAN hygiene\`" .-> Gloss_core
  Gloss_core -- "\`gl_asset_map()\`" --> Open_assets.Asset_map
  Gloss_core -- "\`gl_asset_bundle()\`" --> Open_assets.Asset_bundle
  Ecosystem -. "\`Calls 4 core functions in live R\`" .-> Gloss_core
  Ecosystem -- "\`Reads compact map first\`" --> Open_assets.Asset_map
  Ecosystem -- "\`[...]\`" --> Open_assets.Asset_bundle
  classDef core fill:#0F766E,stroke:#00524b,color:#c7ffff
  class Principles core
  classDef ecosystem fill:#7C3AED,stroke:#4e0cc3,color:#ffffff
  class Ecosystem ecosystem
  classDef done fill:#16A34A,stroke:#007c27,color:#ffffff
  class Gloss_core,Open_assets.Asset_map,Open_assets.Asset_bundle done
  linkStyle 0 stroke:#8D8D8D,stroke-dasharray:8 4
  linkStyle 1 stroke:#a35905,stroke-dasharray:8 4
  linkStyle 2,3,5,6 stroke:#026395
  linkStyle 4 stroke:#5d2cb2
`;case`core_architecture`:return`---
title: "02 · R Core Internal Architecture (Modules, Engines & APIs)"
---
graph TB
  Gloss_corePublic_api@{ shape: rectangle, label: "Public API Surface (8 Exports)" }
  subgraph Gloss_coreModules["\`Core Internal Modules\`"]
    Gloss_coreModules.Mod_capture@{ shape: rectangle, label: "Device Capture & SVG Instrumentation" }
    Gloss_coreModules.Mod_package_assets@{ shape: rectangle, label: "Asset Map & Bundle Packager" }
    Gloss_coreModules.Mod_query@{ shape: rectangle, label: "In-Memory Query & Slicing" }
    Gloss_coreModules.Mod_registry@{ shape: rectangle, label: "Engine Registry & Load Hook" }
    Gloss_coreModules.Mod_sources@{ shape: rectangle, label: "Source Context Inventory" }
    Gloss_coreModules.Mod_utils@{ shape: rectangle, label: "Contract & Open Serialization" }
    Gloss_coreModules.Mod_ir_lineage@{ shape: rectangle, label: "Engine IR & Structural Lineage" }
  end
  subgraph Gloss_coreEngines["\`Built-in Plotting Engines (Suggests)\`"]
    Gloss_coreEngines.Eng_grid@{ shape: rectangle, label: "grid Engine" }
    Gloss_coreEngines.Eng_ggplot@{ shape: rectangle, label: "ggplot2 Engine" }
    Gloss_coreEngines.Eng_patchwork@{ shape: rectangle, label: "patchwork Engine" }
    Gloss_coreEngines.Eng_heatmap@{ shape: rectangle, label: "ComplexHeatmap Engine" }
    Gloss_coreEngines.Eng_base@{ shape: rectangle, label: "base Graphics Engine" }
  end
  Open_assetsAsset_map@{ shape: doc, label: "Asset Map (asset-map.json)" }
  Open_assetsAsset_bundle@{ shape: doc, label: "Asset Bundle (figure.gloss/ or .zip)" }
  Gloss_corePublic_api -. "\`Registers engine spec\`" .-> Gloss_coreModules.Mod_registry
  Gloss_corePublic_api -. "\`Orchestrates single-draw capture\`" .-> Gloss_coreModules.Mod_capture
  Gloss_corePublic_api -. "\`[...]\`" .-> Gloss_coreModules.Mod_package_assets
  Gloss_corePublic_api -. "\`[...]\`" .-> Gloss_coreModules.Mod_query
  Gloss_coreModules.Mod_capture -. "\`Builds validated gloss_capture\`" .-> Gloss_coreModules.Mod_utils
  Gloss_coreModules.Mod_package_assets -. "\`Writes UTF-8 JSON, CSV & SHA-256\`" .-> Gloss_coreModules.Mod_utils
  Gloss_coreModules.Mod_query -. "\`Validates gloss_capture\`" .-> Gloss_coreModules.Mod_utils
  Gloss_coreModules.Mod_capture -. "\`Dispatches by class & page_kind\`" .-> Gloss_coreModules.Mod_registry
  Gloss_coreModules.Mod_capture -. "\`Snapshots provenance & session\`" .-> Gloss_coreModules.Mod_sources
  Gloss_coreModules.Mod_package_assets -- "\`gl_asset_map()\`" --> Open_assetsAsset_map
  Gloss_coreModules.Mod_package_assets -- "\`gl_asset_bundle()\`" --> Open_assetsAsset_bundle
  Gloss_coreEngines -. "\`Normalizes IR & lineage\`" .-> Gloss_coreModules.Mod_ir_lineage
  Gloss_coreModules.Mod_capture -. "\`Invokes engine capture_fn\`" .-> Gloss_coreEngines
  classDef slate fill:#64748b,stroke:#475569,color:#f8fafc
  class Gloss_corePublic_api slate
  classDef done fill:#16A34A,stroke:#007c27,color:#ffffff
  class Gloss_coreModules.Mod_capture,Gloss_coreModules.Mod_package_assets,Gloss_coreModules.Mod_query,Gloss_coreModules.Mod_registry,Gloss_coreModules.Mod_sources,Gloss_coreEngines.Eng_grid,Gloss_coreEngines.Eng_ggplot,Gloss_coreEngines.Eng_patchwork,Gloss_coreEngines.Eng_heatmap,Gloss_coreEngines.Eng_base,Open_assetsAsset_map,Open_assetsAsset_bundle,Gloss_coreModules.Mod_utils,Gloss_coreModules.Mod_ir_lineage done
  linkStyle 0,1,2,3,4,5,6,7,8,11,12 stroke:#8D8D8D,stroke-dasharray:8 4
  linkStyle 9,10 stroke:#026395
`;case`public_api_surface`:return`---
title: "03 · Public API Surface (8 Exports Contract)"
---
graph LR
  User@{ icon: "fa:user", shape: rounded, label: "R Analyst / AI Coding Agent" }
  Gloss_corePublic_apiFn_register_engine@{ shape: rectangle, label: "gl_register_engine()" }
  Gloss_corePublic_apiFn_asset_map@{ shape: rectangle, label: "gl_asset_map()" }
  Gloss_corePublic_apiFn_asset_bundle@{ shape: rectangle, label: "gl_asset_bundle()" }
  Gloss_corePublic_apiFn_scene@{ shape: rectangle, label: "gl_scene()" }
  Gloss_corePublic_apiFn_tables@{ shape: rectangle, label: "gl_tables()" }
  Gloss_corePublic_apiFn_sources@{ shape: rectangle, label: "gl_sources()" }
  Gloss_corePublic_apiFn_query@{ shape: rectangle, label: "gl_query()" }
  Gloss_corePublic_apiFn_gloss@{ shape: rectangle, label: "gloss()" }
  Gloss_coreModulesMod_package_assets@{ shape: rectangle, label: "Asset Map & Bundle Packager" }
  Gloss_coreModulesMod_query@{ shape: rectangle, label: "In-Memory Query & Slicing" }
  Gloss_coreModulesMod_capture@{ shape: rectangle, label: "Device Capture & SVG Instrumentation" }
  Gloss_coreModulesMod_registry@{ shape: rectangle, label: "Engine Registry & Load Hook" }
  User -. "\`Captures R figure + sources\`" .-> Gloss_corePublic_apiFn_gloss
  Gloss_corePublic_apiFn_gloss -. "\`Orchestrates single-draw capture\`" .-> Gloss_coreModulesMod_capture
  Gloss_corePublic_apiFn_register_engine -. "\`Registers engine spec\`" .-> Gloss_coreModulesMod_registry
  Gloss_coreModulesMod_capture -. "\`Dispatches by class & page_kind\`" .-> Gloss_coreModulesMod_registry
  Gloss_corePublic_apiFn_asset_map -. "\`Serializes asset-map.json\`" .-> Gloss_coreModulesMod_package_assets
  Gloss_corePublic_apiFn_asset_bundle -. "\`Writes .gloss/ or .zip\`" .-> Gloss_coreModulesMod_package_assets
  Gloss_corePublic_apiFn_scene -. "\`Reads scene view\`" .-> Gloss_coreModulesMod_query
  Gloss_corePublic_apiFn_tables -. "\`Reads data frames\`" .-> Gloss_coreModulesMod_query
  Gloss_corePublic_apiFn_sources -. "\`Reads source table\`" .-> Gloss_coreModulesMod_query
  Gloss_corePublic_apiFn_query -. "\`Slices leaves, elements & rows\`" .-> Gloss_coreModulesMod_query
  classDef done fill:#16A34A,stroke:#007c27,color:#ffffff
  class Gloss_corePublic_apiFn_register_engine,Gloss_corePublic_apiFn_asset_map,Gloss_corePublic_apiFn_asset_bundle,Gloss_corePublic_apiFn_scene,Gloss_corePublic_apiFn_tables,Gloss_corePublic_apiFn_sources,Gloss_corePublic_apiFn_query,Gloss_corePublic_apiFn_gloss,Gloss_coreModulesMod_package_assets,Gloss_coreModulesMod_query,Gloss_coreModulesMod_capture,Gloss_coreModulesMod_registry done
  linkStyle 0,1,2,3,4,5,6,7,8,9 stroke:#8D8D8D,stroke-dasharray:8 4
`;case`engines_matrix`:return`---
title: "04 · Built-in Plotting Engines Matrix"
---
graph LR
  Gloss_coreModulesMod_capture@{ shape: rectangle, label: "Device Capture & SVG Instrumentation" }
  Gloss_coreModulesMod_registry@{ shape: rectangle, label: "Engine Registry & Load Hook" }
  Gloss_coreEnginesEng_grid@{ shape: rectangle, label: "grid Engine" }
  Gloss_coreEnginesEng_ggplot@{ shape: rectangle, label: "ggplot2 Engine" }
  Gloss_coreEnginesEng_patchwork@{ shape: rectangle, label: "patchwork Engine" }
  Gloss_coreEnginesEng_heatmap@{ shape: rectangle, label: "ComplexHeatmap Engine" }
  Gloss_coreEnginesEng_base@{ shape: rectangle, label: "base Graphics Engine" }
  Gloss_coreModulesMod_ir_lineage@{ shape: rectangle, label: "Engine IR & Structural Lineage" }
  Gloss_coreModulesMod_capture -. "\`Dispatches by class & page_kind\`" .-> Gloss_coreModulesMod_registry
  classDef done fill:#16A34A,stroke:#007c27,color:#ffffff
  class Gloss_coreModulesMod_capture,Gloss_coreModulesMod_registry,Gloss_coreEnginesEng_grid,Gloss_coreEnginesEng_ggplot,Gloss_coreEnginesEng_patchwork,Gloss_coreEnginesEng_heatmap,Gloss_coreEnginesEng_base,Gloss_coreModulesMod_ir_lineage done
  linkStyle 0 stroke:#8D8D8D,stroke-dasharray:8 4
`;case`guardrails_monitor`:return`---
title: "05 · Design Intent vs Code Alignment Guardrails"
---
graph LR
  PrinciplesP1_source_map@{ shape: rectangle, label: "P1 · Compiler Source Map, Not Gatekeeper" }
  PrinciplesP2_core_boundary@{ shape: rectangle, label: "P2 · Strict In-Core Boundary" }
  PrinciplesP3_single_capture@{ shape: rectangle, label: "P3 · Single Capture, Layered Payload" }
  PrinciplesP4_file_first@{ shape: rectangle, label: "P4 · File-First, Zero Proprietary Codecs" }
  PrinciplesP5_minimal_surface@{ shape: rectangle, label: "P5 · Minimal Export Surface (8 APIs)" }
  PrinciplesG_tests@{ shape: rectangle, label: "Guardrail · Unit Test & Build Health" }
  PrinciplesG_core_boundary@{ shape: rectangle, label: "Guardrail · Strict In-Core Boundary" }
  PrinciplesG_cran_hygiene@{ shape: rectangle, label: "Guardrail · CRAN & R Hygiene" }
  PrinciplesG_exports@{ shape: rectangle, label: "Guardrail · Export Surface Alignment (8 APIs)" }
  PrinciplesG_suggests@{ shape: rectangle, label: "Guardrail · Engine Dependencies in Suggests" }
  Gloss_core@{ shape: rectangle, label: "gloss R Core Package" }
  PrinciplesP1_source_map -. "\`Verifies neutral capture facts\`" .-> PrinciplesG_tests
  PrinciplesP2_core_boundary -. "\`Prevents v1 scope creep\`" .-> PrinciplesG_core_boundary
  PrinciplesP4_file_first -. "\`Verifies clean open packaging\`" .-> PrinciplesG_cran_hygiene
  PrinciplesP5_minimal_surface -. "\`Enforces 8-API contract\`" .-> PrinciplesG_exports
  PrinciplesP5_minimal_surface -. "\`Enforces Suggests isolation\`" .-> PrinciplesG_suggests
  classDef principle fill:#D97706,stroke:#ac5300,color:#ffffff
  class PrinciplesP1_source_map,PrinciplesP2_core_boundary,PrinciplesP3_single_capture,PrinciplesP4_file_first,PrinciplesP5_minimal_surface principle
  classDef done fill:#16A34A,stroke:#007c27,color:#ffffff
  class PrinciplesG_tests,PrinciplesG_core_boundary,PrinciplesG_cran_hygiene,PrinciplesG_exports,PrinciplesG_suggests,Gloss_core done
  linkStyle 0,1,2,3,4 stroke:#a35905,stroke-dasharray:8 4
`;case`open_contracts`:return`---
title: "06 · Open File Contracts & Outer Ecosystem"
---
graph LR
  subgraph Ecosystem["\`Outer Ecosystem (Out-of-Core)\`"]
    Ecosystem.Skill_gloss@{ shape: rounded, label: "Base Protocol Skill: gloss" }
    Ecosystem.Workbench@{ shape: rounded, label: "Static Frontend: Workbench" }
    Ecosystem.External_scripts@{ shape: rounded, label: "Python / JS / DuckDB Toolchains" }
    Ecosystem.Skill_refine@{ shape: rounded, label: "SVG Refinement Skill: gloss-svg-refine" }
    Ecosystem.Skill_audit@{ shape: rounded, label: "Semantic Audit Skill: gloss-audit" }
    Ecosystem.Skill_report@{ shape: rounded, label: "Report Skill: gloss-report" }
    Ecosystem.Gloss_mcp@{ shape: rounded, label: "Live R Bridge: gloss-mcp" }
  end
  Gloss_core@{ shape: rectangle, label: "gloss R Core Package" }
  subgraph Open_assets["\`Open File Contracts\`"]
    Open_assets.Asset_map@{ shape: doc, label: "Asset Map (asset-map.json)" }
    Open_assets.Asset_bundle@{ shape: doc, label: "Asset Bundle (figure.gloss/ or .zip)" }
  end
  Gloss_core -- "\`gl_asset_map()\`" --> Open_assets.Asset_map
  Gloss_core -- "\`gl_asset_bundle()\`" --> Open_assets.Asset_bundle
  Ecosystem.Skill_gloss -- "\`Reads compact map first\`" --> Open_assets.Asset_map
  Ecosystem.Skill_gloss -- "\`Reads targeted CSV/SVG slices\`" --> Open_assets.Asset_bundle
  Ecosystem.Gloss_mcp -. "\`Calls 4 core functions in live R\`" .-> Gloss_core
  Ecosystem.Workbench -- "\`Opens .gloss dir / zip\`" --> Open_assets.Asset_bundle
  Ecosystem.External_scripts -- "\`Batch SQL / Python / JS\`" --> Open_assets.Asset_bundle
  Ecosystem.Skill_gloss -. "\`Delegates visual refinement\`" .-> Ecosystem.Skill_refine
  Ecosystem.Skill_gloss -. "\`Delegates statistical/caption verification\`" .-> Ecosystem.Skill_audit
  Ecosystem.Skill_gloss -. "\`Delegates multi-figure reporting\`" .-> Ecosystem.Skill_report
  Ecosystem.Skill_gloss -. "\`Optional live-session queries\`" .-> Ecosystem.Gloss_mcp
  classDef ecosystem fill:#7C3AED,stroke:#4e0cc3,color:#ffffff
  class Ecosystem.Skill_gloss,Ecosystem.Workbench,Ecosystem.External_scripts,Ecosystem.Skill_refine,Ecosystem.Skill_audit,Ecosystem.Skill_report,Ecosystem.Gloss_mcp ecosystem
  classDef done fill:#16A34A,stroke:#007c27,color:#ffffff
  class Gloss_core,Open_assets.Asset_map,Open_assets.Asset_bundle done
  linkStyle 0,1,2,3,5,6 stroke:#026395
  linkStyle 4,10 stroke:#5d2cb2
  linkStyle 7,8,9 stroke:#8D8D8D,stroke-dasharray:8 4
`;default:throw Error(`Unknown viewId: `+e)}};export{e as mmdSource};