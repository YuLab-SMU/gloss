var e=e=>{switch(e){case`index`:return`direction: right

"User": {
  label: "R Analyst / AI Coding Agent"
  shape: c4-person
}
"Principles": {
  label: "Design Principles & Alignment Guardrails"
}
"Ecosystem": {
  label: "Outer Ecosystem (Out-of-Core)"
}
"Gloss_core": {
  label: "gloss R Core Package"
}
"Open_assets": {
  label: "Open File Contracts"

  "Asset_map": {
    label: "Asset Map (asset-map.json)"
    shape: document
  }
  "Asset_bundle": {
    label: "Asset Bundle (figure.gloss/ or .zip)"
    shape: document
  }
}

"User" -> "Gloss_core": "Captures R figure + sources"
"Principles" -> "Gloss_core": "Guards architecture, surface & CRAN hygiene"
"Gloss_core" -> "Open_assets"."Asset_map": "gl_asset_map()"
"Gloss_core" -> "Open_assets"."Asset_bundle": "gl_asset_bundle()"
"Ecosystem" -> "Gloss_core": "Calls 4 core functions in live R"
"Ecosystem" -> "Open_assets"."Asset_map": "Reads compact map first"
"Ecosystem" -> "Open_assets"."Asset_bundle": "[...]"
`;case`core_architecture`:return`direction: down

"Gloss_corePublic_api": {
  label: "Public API Surface (8 Exports)"
}
"Gloss_coreModules": {
  label: "Core Internal Modules"

  "Mod_capture": {
    label: "Device Capture & SVG Instrumentation"
  }
  "Mod_package_assets": {
    label: "Asset Map & Bundle Packager"
  }
  "Mod_query": {
    label: "In-Memory Query & Slicing"
  }
  "Mod_registry": {
    label: "Engine Registry & Load Hook"
  }
  "Mod_sources": {
    label: "Source Context Inventory"
  }
  "Mod_utils": {
    label: "Contract & Open Serialization"
  }
  "Mod_ir_lineage": {
    label: "Engine IR & Structural Lineage"
  }
}
"Gloss_coreEngines": {
  label: "Built-in Plotting Engines (Suggests)"

  "Eng_grid": {
    label: "grid Engine"
  }
  "Eng_ggplot": {
    label: "ggplot2 Engine"
  }
  "Eng_patchwork": {
    label: "patchwork Engine"
  }
  "Eng_heatmap": {
    label: "ComplexHeatmap Engine"
  }
  "Eng_base": {
    label: "base Graphics Engine"
  }
}
"Open_assetsAsset_map": {
  label: "Asset Map (asset-map.json)"
  shape: document
}
"Open_assetsAsset_bundle": {
  label: "Asset Bundle (figure.gloss/ or .zip)"
  shape: document
}

"Gloss_corePublic_api" -> "Gloss_coreModules"."Mod_registry": "Registers engine spec"
"Gloss_corePublic_api" -> "Gloss_coreModules"."Mod_capture": "Orchestrates single-draw capture"
"Gloss_corePublic_api" -> "Gloss_coreModules"."Mod_package_assets": "[...]"
"Gloss_corePublic_api" -> "Gloss_coreModules"."Mod_query": "[...]"
"Gloss_coreModules"."Mod_capture" -> "Gloss_coreModules"."Mod_utils": "Builds validated gloss_capture"
"Gloss_coreModules"."Mod_package_assets" -> "Gloss_coreModules"."Mod_utils": "Writes UTF-8 JSON, CSV & SHA-256"
"Gloss_coreModules"."Mod_query" -> "Gloss_coreModules"."Mod_utils": "Validates gloss_capture"
"Gloss_coreModules"."Mod_capture" -> "Gloss_coreModules"."Mod_registry": "Dispatches by class & page_kind"
"Gloss_coreModules"."Mod_capture" -> "Gloss_coreModules"."Mod_sources": "Snapshots provenance & session"
"Gloss_coreModules"."Mod_package_assets" -> "Open_assetsAsset_map": "gl_asset_map()"
"Gloss_coreModules"."Mod_package_assets" -> "Open_assetsAsset_bundle": "gl_asset_bundle()"
"Gloss_coreEngines" -> "Gloss_coreModules"."Mod_ir_lineage": "Normalizes IR & lineage"
"Gloss_coreModules"."Mod_capture" -> "Gloss_coreEngines": "Invokes engine capture_fn"
`;case`public_api_surface`:return`direction: right

"User": {
  label: "R Analyst / AI Coding Agent"
  shape: c4-person
}
"Gloss_corePublic_apiFn_register_engine": {
  label: "gl_register_engine()"
}
"Gloss_corePublic_apiFn_asset_map": {
  label: "gl_asset_map()"
}
"Gloss_corePublic_apiFn_asset_bundle": {
  label: "gl_asset_bundle()"
}
"Gloss_corePublic_apiFn_scene": {
  label: "gl_scene()"
}
"Gloss_corePublic_apiFn_tables": {
  label: "gl_tables()"
}
"Gloss_corePublic_apiFn_sources": {
  label: "gl_sources()"
}
"Gloss_corePublic_apiFn_query": {
  label: "gl_query()"
}
"Gloss_corePublic_apiFn_gloss": {
  label: "gloss()"
}
"Gloss_coreModulesMod_package_assets": {
  label: "Asset Map & Bundle Packager"
}
"Gloss_coreModulesMod_query": {
  label: "In-Memory Query & Slicing"
}
"Gloss_coreModulesMod_capture": {
  label: "Device Capture & SVG Instrumentation"
}
"Gloss_coreModulesMod_registry": {
  label: "Engine Registry & Load Hook"
}

"User" -> "Gloss_corePublic_apiFn_gloss": "Captures R figure + sources"
"Gloss_corePublic_apiFn_gloss" -> "Gloss_coreModulesMod_capture": "Orchestrates single-draw capture"
"Gloss_corePublic_apiFn_register_engine" -> "Gloss_coreModulesMod_registry": "Registers engine spec"
"Gloss_coreModulesMod_capture" -> "Gloss_coreModulesMod_registry": "Dispatches by class & page_kind"
"Gloss_corePublic_apiFn_asset_map" -> "Gloss_coreModulesMod_package_assets": "Serializes asset-map.json"
"Gloss_corePublic_apiFn_asset_bundle" -> "Gloss_coreModulesMod_package_assets": "Writes .gloss/ or .zip"
"Gloss_corePublic_apiFn_scene" -> "Gloss_coreModulesMod_query": "Reads scene view"
"Gloss_corePublic_apiFn_tables" -> "Gloss_coreModulesMod_query": "Reads data frames"
"Gloss_corePublic_apiFn_sources" -> "Gloss_coreModulesMod_query": "Reads source table"
"Gloss_corePublic_apiFn_query" -> "Gloss_coreModulesMod_query": "Slices leaves, elements & rows"
`;case`engines_matrix`:return`direction: right

"Gloss_coreModulesMod_capture": {
  label: "Device Capture & SVG Instrumentation"
}
"Gloss_coreModulesMod_registry": {
  label: "Engine Registry & Load Hook"
}
"Gloss_coreEnginesEng_grid": {
  label: "grid Engine"
}
"Gloss_coreEnginesEng_ggplot": {
  label: "ggplot2 Engine"
}
"Gloss_coreEnginesEng_patchwork": {
  label: "patchwork Engine"
}
"Gloss_coreEnginesEng_heatmap": {
  label: "ComplexHeatmap Engine"
}
"Gloss_coreEnginesEng_base": {
  label: "base Graphics Engine"
}
"Gloss_coreModulesMod_ir_lineage": {
  label: "Engine IR & Structural Lineage"
}

"Gloss_coreModulesMod_capture" -> "Gloss_coreModulesMod_registry": "Dispatches by class & page_kind"
`;case`guardrails_monitor`:return`direction: right

"PrinciplesP1_source_map": {
  label: "P1 · Compiler Source Map, Not Gatekeeper"
}
"PrinciplesP2_core_boundary": {
  label: "P2 · Strict In-Core Boundary"
}
"PrinciplesP3_single_capture": {
  label: "P3 · Single Capture, Layered Payload"
}
"PrinciplesP4_file_first": {
  label: "P4 · File-First, Zero Proprietary Codecs"
}
"PrinciplesP5_minimal_surface": {
  label: "P5 · Minimal Export Surface (8 APIs)"
}
"PrinciplesG_tests": {
  label: "Guardrail · Unit Test & Build Health"
}
"PrinciplesG_core_boundary": {
  label: "Guardrail · Strict In-Core Boundary"
}
"PrinciplesG_cran_hygiene": {
  label: "Guardrail · CRAN & R Hygiene"
}
"PrinciplesG_exports": {
  label: "Guardrail · Export Surface Alignment (8 APIs)"
}
"PrinciplesG_suggests": {
  label: "Guardrail · Engine Dependencies in Suggests"
}
"Gloss_core": {
  label: "gloss R Core Package"
}

"PrinciplesP1_source_map" -> "PrinciplesG_tests": "Verifies neutral capture facts"
"PrinciplesP2_core_boundary" -> "PrinciplesG_core_boundary": "Prevents v1 scope creep"
"PrinciplesP4_file_first" -> "PrinciplesG_cran_hygiene": "Verifies clean open packaging"
"PrinciplesP5_minimal_surface" -> "PrinciplesG_exports": "Enforces 8-API contract"
"PrinciplesP5_minimal_surface" -> "PrinciplesG_suggests": "Enforces Suggests isolation"
`;case`open_contracts`:return`direction: right

"Ecosystem": {
  label: "Outer Ecosystem (Out-of-Core)"

  "Skill_gloss": {
    label: "Base Protocol Skill: gloss"
  }
  "Workbench": {
    label: "Static Frontend: Workbench"
  }
  "External_scripts": {
    label: "Python / JS / DuckDB Toolchains"
  }
  "Skill_refine": {
    label: "SVG Refinement Skill: gloss-svg-refine"
  }
  "Skill_audit": {
    label: "Semantic Audit Skill: gloss-audit"
  }
  "Skill_report": {
    label: "Report Skill: gloss-report"
  }
  "Gloss_mcp": {
    label: "Live R Bridge: gloss-mcp"
  }
}
"Gloss_core": {
  label: "gloss R Core Package"
}
"Open_assets": {
  label: "Open File Contracts"

  "Asset_map": {
    label: "Asset Map (asset-map.json)"
    shape: document
  }
  "Asset_bundle": {
    label: "Asset Bundle (figure.gloss/ or .zip)"
    shape: document
  }
}

"Gloss_core" -> "Open_assets"."Asset_map": "gl_asset_map()"
"Gloss_core" -> "Open_assets"."Asset_bundle": "gl_asset_bundle()"
"Ecosystem"."Skill_gloss" -> "Open_assets"."Asset_map": "Reads compact map first"
"Ecosystem"."Skill_gloss" -> "Open_assets"."Asset_bundle": "Reads targeted CSV/SVG slices"
"Ecosystem"."Gloss_mcp" -> "Gloss_core": "Calls 4 core functions in live R"
"Ecosystem"."Workbench" -> "Open_assets"."Asset_bundle": "Opens .gloss dir / zip"
"Ecosystem"."External_scripts" -> "Open_assets"."Asset_bundle": "Batch SQL / Python / JS"
"Ecosystem"."Skill_gloss" -> "Ecosystem"."Skill_refine": "Delegates visual refinement"
"Ecosystem"."Skill_gloss" -> "Ecosystem"."Skill_audit": "Delegates statistical/caption verification"
"Ecosystem"."Skill_gloss" -> "Ecosystem"."Skill_report": "Delegates multi-figure reporting"
"Ecosystem"."Skill_gloss" -> "Ecosystem"."Gloss_mcp": "Optional live-session queries"
`;default:throw Error(`Unknown viewId: `+e)}};export{e as d2Source};