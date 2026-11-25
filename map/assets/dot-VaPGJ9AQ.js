var e=e=>{switch(e){case`index`:return`digraph {
    graph [TBbalance=min,
        bgcolor=transparent,
        compound=true,
        fontname=Arial,
        fontsize=20,
        labeljust=l,
        labelloc=t,
        layout=dot,
        likec4_viewId=index,
        nodesep=1.389,
        outputorder=nodesfirst,
        pad=0.209,
        rankdir=LR,
        ranksep=1.945,
        splines=spline
    ];
    node [color="#2563eb",
        fillcolor="#3b82f6",
        fontcolor="#eff6ff",
        fontname=Arial,
        label="\\N",
        penwidth=0,
        shape=rect,
        style=filled
    ];
    edge [arrowsize=0.75,
        color="#8D8D8D",
        fontcolor="#C9C9C9",
        fontname=Arial,
        fontsize=14,
        penwidth=2,
        style=""
    ];
    subgraph cluster_open_assets {
        graph [color="#052c29",
            fillcolor="#0f413d",
            label=<<FONT POINT-SIZE="11" COLOR="#b2ffffb3"><B>OPEN FILE CONTRACTS</B></FONT>>,
            likec4_depth=1,
            likec4_id=open_assets,
            likec4_level=0,
            margin=40,
            style=filled
        ];
        asset_map [color="#007c27",
            fillcolor="#16A34A",
            fixedsize=true,
            fontcolor="#ffffff",
            height=2.5,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Asset Map (asset-map.json)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">JSON (~tens of KB)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Lightweight global catalog of page<BR/>geometry, SVG digests, Engine IR (panels,<BR/>layers, scales, orders), table column<BR/>summaries, lineage, and source pointers.</FONT></TD></TR></TABLE>>,
            likec4_id="open_assets.asset_map",
            likec4_level=1,
            margin="0.223,0.223",
            width=4.445];
        asset_bundle [color="#007c27",
            fillcolor="#16A34A",
            fixedsize=true,
            fontcolor="#ffffff",
            height=2.723,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Asset Bundle<BR/>(figure.gloss/ or .zip)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">UTF-8 SVG + JSON + CSV + PNG</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Self-contained portable bundle:<BR/>manifest.json, asset-map.json,<BR/>omitted.json, assets/original.svg,<BR/>scene/{scene.svg,leaves.json,elements.jso<BR/>n,rasters/}, tables/{schema.json,*.csv},</FONT></TD></TR></TABLE>>,
            likec4_id="open_assets.asset_bundle",
            likec4_level=1,
            margin="0.223,0.223",
            width=4.445];
    }
    user [color="#475569",
        fillcolor="#64748b",
        fixedsize=true,
        fontcolor="#f8fafc",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">R Analyst / AI Coding Agent</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#cbd5e1">Authors R figures in an active R session or<BR/>consumes portable .gloss assets for Q&amp;A,<BR/>publication SVG refinement, and statistical<BR/>auditing.</FONT></TD></TR></TABLE>>,
        likec4_id=user,
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    gloss_core [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">gloss R Core Package</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R (&gt;= 4.2.0), svglite, xml2, jsonlite, digest</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Lightweight R core package: single-draw<BR/>device capture, Engine IR extraction,<BR/>structural lineage, runtime source<BR/>inventory, and open asset packaging.</FONT></TD></TR></TABLE>>,
        likec4_id=gloss_core,
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    user -> gloss_core [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="185" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Captures R figure + sources</FONT></TD></TR></TABLE>>,
        likec4_id="1d6zq57",
        minlen=1,
        style=dashed,
        weight=2];
    principles [color="#00524b",
        fillcolor="#0F766E",
        fixedsize=true,
        fontcolor="#c7ffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Design Principles &amp;<BR/>Alignment Guardrails</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#b2ffff">Canonical architectural invariants from<BR/>AGENTS.md paired with live code-vs-<BR/>intent verification checks.</FONT></TD></TR></TABLE>>,
        likec4_id=principles,
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    principles -> gloss_core [arrowhead=normal,
        color="#a35905",
        fontcolor="#ffffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="164" HEIGHT="42" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Guards architecture,<BR/>surface &amp; CRAN hygiene</FONT></TD></TR></TABLE>>,
        likec4_id="1a8xcxb",
        minlen=1,
        style=dashed,
        weight=2];
    ecosystem [color="#4e0cc3",
        fillcolor="#7C3AED",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Outer Ecosystem (Out-of-Core)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Independent skills, live bridge, static<BR/>frontend, and cross-language scripts<BR/>collaborating exclusively over Asset Map &amp;<BR/>Asset Bundle contracts.</FONT></TD></TR></TABLE>>,
        likec4_id=ecosystem,
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    ecosystem -> gloss_core [arrowhead=normal,
        color="#5d2cb2",
        fontcolor="#ffffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="199" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Calls 4 core functions in live R</FONT></TD></TR></TABLE>>,
        likec4_id=r621ja,
        style=dotted,
        weight=2];
    ecosystem -> asset_map [arrowhead=normal,
        color="#026395",
        fontcolor="#ddffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="168" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Reads compact map first</FONT></TD></TR></TABLE>>,
        likec4_id="1idauvn",
        style=solid];
    ecosystem -> asset_bundle [arrowhead=normal,
        color="#026395",
        fontcolor="#ddffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="33" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">[...]</FONT></TD></TR></TABLE>>,
        likec4_id="11nw057",
        style=solid];
    gloss_core -> asset_map [arrowhead=normal,
        color="#026395",
        fontcolor="#ddffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="110" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">gl_asset_map()</FONT></TD></TR></TABLE>>,
        likec4_id="151z9wf",
        style=solid];
    gloss_core -> asset_bundle [arrowhead=normal,
        color="#026395",
        fontcolor="#ddffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="126" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">gl_asset_bundle()</FONT></TD></TR></TABLE>>,
        likec4_id="3jr86v",
        style=solid];
}
`;case`core_architecture`:return`digraph {
    graph [TBbalance=min,
        bgcolor=transparent,
        compound=true,
        fontname=Arial,
        fontsize=20,
        labeljust=l,
        labelloc=t,
        layout=dot,
        likec4_viewId=core_architecture,
        nodesep=1.25,
        outputorder=nodesfirst,
        pad=0.209,
        rankdir=TB,
        ranksep=1.528,
        splines=spline
    ];
    node [color="#2563eb",
        fillcolor="#3b82f6",
        fontcolor="#eff6ff",
        fontname=Arial,
        label="\\N",
        penwidth=0,
        shape=rect,
        style=filled
    ];
    edge [arrowsize=0.75,
        color="#8D8D8D",
        fontcolor="#C9C9C9",
        fontname=Arial,
        fontsize=14,
        penwidth=2,
        style=""
    ];
    subgraph cluster_modules {
        graph [color="#2d333d",
            fillcolor="#3e4651",
            label=<<FONT POINT-SIZE="11" COLOR="#cbd5e1b3"><B>CORE INTERNAL MODULES</B></FONT>>,
            likec4_depth=1,
            likec4_id="gloss_core.modules",
            likec4_level=0,
            margin=40,
            style=filled
        ];
        mod_capture [color="#007c27",
            fillcolor="#16A34A",
            fixedsize=true,
            fontcolor="#ffffff",
            group="gloss_core.modules",
            height=2.723,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Device Capture &amp;<BR/>SVG Instrumentation</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/capture.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">svglite::svgstring() single-draw dual SVG<BR/>capture, grid display-list leaf wrapping,<BR/>draw-time gloss_probe viewport<BR/>recorder, &lt;defs&gt;/&lt;use&gt; inlining, xml2<BR/>geometry parsing, and dense PNG</FONT></TD></TR></TABLE>>,
            likec4_id="gloss_core.modules.mod_capture",
            likec4_level=1,
            margin="0.5,0.223",
            width=4.584];
        mod_package_assets [color="#007c27",
            fillcolor="#16A34A",
            fixedsize=true,
            fontcolor="#ffffff",
            group="gloss_core.modules",
            height=2.5,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Asset Map &amp; Bundle Packager</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/package-assets.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Layered open-format serialization for<BR/>asset-map.json and .gloss/ dir/zip<BR/>bundles with SHA-256 manifest.json,<BR/>column/row filtering, and omitted.json.</FONT></TD></TR></TABLE>>,
            likec4_id="gloss_core.modules.mod_package_assets",
            likec4_level=1,
            margin="0.5,0.223",
            width=4.584];
        mod_query [color="#007c27",
            fillcolor="#16A34A",
            fixedsize=true,
            fontcolor="#ffffff",
            group="gloss_core.modules",
            height=2.5,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">In-Memory Query &amp; Slicing</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/query.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Read-only inspection and<BR/>panel/leaf/spatial-box/row slicing on<BR/>gloss_capture objects.</FONT></TD></TR></TABLE>>,
            likec4_id="gloss_core.modules.mod_query",
            likec4_level=1,
            margin="0.5,0.223",
            width=4.584];
        mod_registry [color="#007c27",
            fillcolor="#16A34A",
            fixedsize=true,
            fontcolor="#ffffff",
            group="gloss_core.modules",
            height=2.5,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Engine Registry &amp; Load Hook</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/engine-registry.R, R/zzz.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Private package environment registry,<BR/>class-hierarchy &amp; priority dispatch,<BR/>page_kind candidate disambiguation,<BR/>and lazy Suggests checks.</FONT></TD></TR></TABLE>>,
            likec4_id="gloss_core.modules.mod_registry",
            likec4_level=1,
            margin="0.5,0.223",
            width=4.584];
        mod_sources [color="#007c27",
            fillcolor="#16A34A",
            fixedsize=true,
            fontcolor="#ffffff",
            group="gloss_core.modules",
            height=2.5,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Source Context Inventory</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/sources.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Collects explicit files/docs/inline<BR/>snippets, runtime_observed<BR/>session/package/git metadata, and<BR/>knitr/Rscript sniffed_hint pointers.</FONT></TD></TR></TABLE>>,
            likec4_id="gloss_core.modules.mod_sources",
            likec4_level=1,
            margin="0.5,0.223",
            width=4.584];
        mod_utils [color="#007c27",
            fillcolor="#16A34A",
            fixedsize=true,
            fontcolor="#ffffff",
            group="gloss_core.modules",
            height=2.5,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Contract &amp; Open Serialization</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/utils.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">gloss_capture S3 contract, deterministic<BR/>capture_id, SHA-256 helpers, UTF-8<BR/>JSON/CSV writers with 1-based<BR/>_row_id, and column schema inference.</FONT></TD></TR></TABLE>>,
            likec4_id="gloss_core.modules.mod_utils",
            likec4_level=1,
            margin="0.5,0.223",
            width=4.584];
        mod_ir_lineage [color="#007c27",
            fillcolor="#16A34A",
            fixedsize=true,
            fontcolor="#ffffff",
            height=2.723,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Engine IR &amp;<BR/>Structural Lineage</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/ir-lineage.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Normalizes panel coordinate domains,<BR/>scale/palette dictionaries, layer specs,<BR/>and neutral element-to-table<BR/>cardinalities (1:1, N:1, 1:M,<BR/>stat_aggregated).</FONT></TD></TR></TABLE>>,
            likec4_id="gloss_core.modules.mod_ir_lineage",
            likec4_level=1,
            margin="0.5,0.223",
            width=4.584];
    }
    subgraph cluster_engines {
        graph [color="#2d333d",
            fillcolor="#3e4651",
            label=<<FONT POINT-SIZE="11" COLOR="#cbd5e1b3"><B>BUILT-IN PLOTTING ENGINES (SUGGESTS)</B></FONT>>,
            likec4_depth=1,
            likec4_id="gloss_core.engines",
            likec4_level=0,
            margin=40,
            style=filled
        ];
        {
            graph [rank=same];
            eng_grid [color="#007c27",
                fillcolor="#16A34A",
                fixedsize=true,
                fontcolor="#ffffff",
                height=2.5,
                label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">grid Engine</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/engine-grid.R (grid)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Captures raw grid grobs, gLists, gTrees,<BR/>gtables, grid drawing functions, and<BR/>recorded grid plots.</FONT></TD></TR></TABLE>>,
                likec4_id="gloss_core.engines.eng_grid",
                likec4_level=1,
                margin="0.5,0.223",
                width=4.584];
            eng_ggplot [color="#007c27",
                fillcolor="#16A34A",
                fixedsize=true,
                fontcolor="#ffffff",
                height=2.5,
                label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">ggplot2 Engine</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/engine-ggplot.R (Suggests: ggplot2)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Single-build ggplot_build -&gt;<BR/>ggplot_gtable -&gt; grid.draw extracting<BR/>raw/built tables, scale/palette maps,<BR/>layer recipes, facets, and neutral<BR/>lineage.</FONT></TD></TR></TABLE>>,
                likec4_id="gloss_core.engines.eng_ggplot",
                likec4_level=1,
                margin="0.5,0.223",
                width=4.584];
            eng_patchwork [color="#007c27",
                fillcolor="#16A34A",
                fixedsize=true,
                fontcolor="#ffffff",
                height=2.5,
                label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">patchwork Engine</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/engine-patchwork.R (Suggests: patchwork)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Composite multi-plot IR extraction with<BR/>per-subplot panel and table<BR/>namespaces without double-building<BR/>stochastic subplots.</FONT></TD></TR></TABLE>>,
                likec4_id="gloss_core.engines.eng_patchwork",
                likec4_level=1,
                margin="0.5,0.223",
                width=4.584];
        }
        {
            graph [rank=same];
            eng_heatmap [color="#007c27",
                fillcolor="#16A34A",
                fixedsize=true,
                fontcolor="#ffffff",
                height=2.5,
                label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">ComplexHeatmap Engine</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/engine-heatmap.R (Suggests:</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Single draw() capture preserving draw-<BR/>time clustering permutations<BR/>(row_order/column_order) in ir.orders,<BR/>matrix/annotation tables, and color<BR/>maps.</FONT></TD></TR></TABLE>>,
                likec4_id="gloss_core.engines.eng_heatmap",
                likec4_level=1,
                margin="0.5,0.223",
                width=4.584];
            eng_base [color="#007c27",
                fillcolor="#16A34A",
                fixedsize=true,
                fontcolor="#ffffff",
                height=2.5,
                label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">base Graphics Engine</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/engine-base.R (grDevices/graphics)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Step-by-step display-list replay on<BR/>svglite isolating per-call &lt;g id='L...'&gt;<BR/>leaves and par('usr')/par('plt') plot<BR/>regions.</FONT></TD></TR></TABLE>>,
                likec4_id="gloss_core.engines.eng_base",
                likec4_level=1,
                margin="0.5,0.223",
                width=4.584];
        }
        eng_grid -> eng_heatmap [minlen=1,
            style=invis];
    }
    public_api [color="#475569",
        fillcolor="#64748b",
        fixedsize=true,
        fontcolor="#f8fafc",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Public API Surface (8 Exports)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#cbd5e1">The minimal, stable exported interface of<BR/>gloss.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.public_api",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    public_api -> mod_capture [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="223" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Orchestrates single-draw capture</FONT></TD></TR></TABLE>>,
        likec4_id="1xfbzjq",
        style=dashed];
    public_api -> mod_package_assets [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="33" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">[...]</FONT></TD></TR></TABLE>>,
        likec4_id=z0gss4,
        style=dashed,
        weight=3];
    public_api -> mod_query [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="33" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">[...]</FONT></TD></TR></TABLE>>,
        likec4_id="5vm33s",
        style=dashed];
    public_api -> mod_registry [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="149" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Registers engine spec</FONT></TD></TR></TABLE>>,
        likec4_id="13w91gn",
        style=dashed];
    mod_capture -> mod_registry [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="217" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Dispatches by class &amp; page_kind</FONT></TD></TR></TABLE>>,
        likec4_id="1vpn2qj",
        style=dashed,
        weight=2];
    mod_capture -> mod_sources [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="219" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Snapshots provenance &amp; session</FONT></TD></TR></TABLE>>,
        likec4_id=wdv2zk,
        minlen=1,
        style=dashed,
        weight=2];
    mod_capture -> eng_grid [arrowhead=normal,
        lhead=cluster_engines,
        likec4_id=uqke99,
        style=dashed,
        xlabel=<<TABLE FIXEDSIZE="TRUE" WIDTH="178" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Invokes engine capture_fn</FONT></TD></TR></TABLE>>];
    mod_capture -> mod_utils [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="204" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Builds validated gloss_capture</FONT></TD></TR></TABLE>>,
        likec4_id=qbxlo9,
        style=dashed,
        weight=2];
    asset_map [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Asset Map (asset-map.json)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">JSON (~tens of KB)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Lightweight global catalog of page<BR/>geometry, SVG digests, Engine IR (panels,<BR/>layers, scales, orders), table column<BR/>summaries, lineage, and source pointers.</FONT></TD></TR></TABLE>>,
        likec4_id="open_assets.asset_map",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    mod_package_assets -> asset_map [arrowhead=normal,
        color="#026395",
        fontcolor="#ddffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="110" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">gl_asset_map()</FONT></TD></TR></TABLE>>,
        likec4_id=g8c5d5,
        minlen=1,
        style=solid];
    asset_bundle [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.723,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Asset Bundle<BR/>(figure.gloss/ or .zip)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">UTF-8 SVG + JSON + CSV + PNG</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Self-contained portable bundle:<BR/>manifest.json, asset-map.json,<BR/>omitted.json, assets/original.svg,<BR/>scene/{scene.svg,leaves.json,elements.jso<BR/>n,rasters/}, tables/{schema.json,*.csv},</FONT></TD></TR></TABLE>>,
        likec4_id="open_assets.asset_bundle",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    mod_package_assets -> asset_bundle [arrowhead=normal,
        color="#026395",
        fontcolor="#ddffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="126" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">gl_asset_bundle()</FONT></TD></TR></TABLE>>,
        likec4_id="9ce3r5",
        minlen=1,
        style=solid];
    mod_package_assets -> mod_utils [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="138" HEIGHT="42" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Writes UTF-8 JSON,<BR/>CSV &amp; SHA-256</FONT></TD></TR></TABLE>>,
        likec4_id="15ntf5n",
        style=dashed,
        weight=4];
    mod_query -> mod_utils [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="161" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Validates gloss_capture</FONT></TD></TR></TABLE>>,
        likec4_id="1g1o1tj",
        style=dashed,
        weight=2];
    eng_ggplot -> eng_patchwork [style=invis];
    eng_base -> mod_ir_lineage [arrowhead=normal,
        likec4_id="110ne5c",
        ltail=cluster_engines,
        style=dashed,
        xlabel=<<TABLE FIXEDSIZE="TRUE" WIDTH="163" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Normalizes IR &amp; lineage</FONT></TD></TR></TABLE>>];
}
`;case`public_api_surface`:return`digraph {
    graph [TBbalance=min,
        bgcolor=transparent,
        compound=true,
        fontname=Arial,
        fontsize=20,
        labeljust=l,
        labelloc=t,
        layout=dot,
        likec4_viewId=public_api_surface,
        nodesep=1.112,
        outputorder=nodesfirst,
        pad=0.209,
        rankdir=LR,
        ranksep=1.806,
        splines=spline
    ];
    node [color="#2563eb",
        fillcolor="#3b82f6",
        fontcolor="#eff6ff",
        fontname=Arial,
        label="\\N",
        penwidth=0,
        shape=rect,
        style=filled
    ];
    edge [arrowsize=0.75,
        color="#8D8D8D",
        fontcolor="#C9C9C9",
        fontname=Arial,
        fontsize=14,
        penwidth=2,
        style=""
    ];
    user [color="#475569",
        fillcolor="#64748b",
        fixedsize=true,
        fontcolor="#f8fafc",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">R Analyst / AI Coding Agent</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#cbd5e1">Authors R figures in an active R session or<BR/>consumes portable .gloss assets for Q&amp;A,<BR/>publication SVG refinement, and statistical<BR/>auditing.</FONT></TD></TR></TABLE>>,
        likec4_id=user,
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    fn_gloss [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">gloss()</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Draw once on svglite, instrument dual SVG<BR/>+ viewport probes, extract Engine IR,<BR/>lineage, and sources into a gloss_capture<BR/>object.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.public_api.fn_gloss",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    user -> fn_gloss [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="185" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Captures R figure + sources</FONT></TD></TR></TABLE>>,
        likec4_id=lbepce,
        minlen=1,
        style=dashed];
    fn_register_engine [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">gl_register_engine()</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Register built-in or third-party plotting<BR/>engines by S3/S4 class and page kind.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.public_api.fn_register_engine",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    mod_registry [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Engine Registry &amp; Load Hook</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/engine-registry.R, R/zzz.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Private package environment registry,<BR/>class-hierarchy &amp; priority dispatch,<BR/>page_kind candidate disambiguation,<BR/>and lazy Suggests checks.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.modules.mod_registry",
        likec4_level=0,
        margin="0.5,0.223",
        width=4.584];
    fn_register_engine -> mod_registry [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="149" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Registers engine spec</FONT></TD></TR></TABLE>>,
        likec4_id="14tezty",
        minlen=1,
        style=dashed];
    fn_asset_map [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">gl_asset_map()</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Serialize compact asset-map.json index<BR/>from an in-memory gloss_capture without<BR/>redrawing.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.public_api.fn_asset_map",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    mod_package_assets [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Asset Map &amp; Bundle Packager</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/package-assets.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Layered open-format serialization for<BR/>asset-map.json and .gloss/ dir/zip<BR/>bundles with SHA-256 manifest.json,<BR/>column/row filtering, and omitted.json.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.modules.mod_package_assets",
        likec4_level=0,
        margin="0.5,0.223",
        width=4.584];
    fn_asset_map -> mod_package_assets [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="172" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Serializes asset-map.json</FONT></TD></TR></TABLE>>,
        likec4_id="1nle4la",
        minlen=1,
        style=dashed];
    fn_asset_bundle [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">gl_asset_bundle()</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Package portable .gloss/ directory or .zip<BR/>bundle with manifest.json, omitted.json,<BR/>dual SVG, CSV tables, and sources.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.public_api.fn_asset_bundle",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    fn_asset_bundle -> mod_package_assets [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="140" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Writes .gloss/ or .zip</FONT></TD></TR></TABLE>>,
        likec4_id="13tgm7q",
        minlen=1,
        style=dashed];
    fn_scene [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">gl_scene()</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Inspect captured page metadata, dual<BR/>SVG descriptors, leaves, elements,<BR/>rasters, and panels in memory.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.public_api.fn_scene",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    mod_query [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">In-Memory Query &amp; Slicing</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/query.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Read-only inspection and<BR/>panel/leaf/spatial-box/row slicing on<BR/>gloss_capture objects.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.modules.mod_query",
        likec4_level=0,
        margin="0.5,0.223",
        width=4.584];
    fn_scene -> mod_query [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="124" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Reads scene view</FONT></TD></TR></TABLE>>,
        likec4_id="1kbf1lr",
        minlen=1,
        style=dashed];
    fn_tables [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">gl_tables()</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Access raw and engine-built data frames<BR/>from an in-memory gloss_capture.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.public_api.fn_tables",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    fn_tables -> mod_query [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="130" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Reads data frames</FONT></TD></TR></TABLE>>,
        likec4_id=oh0rsc,
        minlen=1,
        style=dashed];
    fn_sources [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">gl_sources()</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Inspect explicit, runtime_observed, and<BR/>sniffed_hint source inventory table.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.public_api.fn_sources",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    fn_sources -> mod_query [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="132" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Reads source table</FONT></TD></TR></TABLE>>,
        likec4_id="15fh2r3",
        minlen=1,
        style=dashed];
    fn_query [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">gl_query()</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Composable structural, spatial (SVG<BR/>bbox), and tabular slicing over an in-<BR/>memory gloss_capture.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.public_api.fn_query",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    fn_query -> mod_query [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="205" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Slices leaves, elements &amp; rows</FONT></TD></TR></TABLE>>,
        likec4_id=ymcyyz,
        minlen=1,
        style=dashed];
    mod_capture [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.723,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Device Capture &amp;<BR/>SVG Instrumentation</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/capture.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">svglite::svgstring() single-draw dual SVG<BR/>capture, grid display-list leaf wrapping,<BR/>draw-time gloss_probe viewport<BR/>recorder, &lt;defs&gt;/&lt;use&gt; inlining, xml2<BR/>geometry parsing, and dense PNG</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.modules.mod_capture",
        likec4_level=0,
        margin="0.5,0.223",
        width=4.584];
    fn_gloss -> mod_capture [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="223" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Orchestrates single-draw capture</FONT></TD></TR></TABLE>>,
        likec4_id="19udmrv",
        style=dashed];
    mod_capture -> mod_registry [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="217" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Dispatches by class &amp; page_kind</FONT></TD></TR></TABLE>>,
        likec4_id="1vpn2qj",
        style=dashed,
        weight=3];
}
`;case`engines_matrix`:return`digraph {
    graph [TBbalance=min,
        bgcolor=transparent,
        compound=true,
        fontname=Arial,
        fontsize=20,
        labeljust=l,
        labelloc=t,
        layout=dot,
        likec4_viewId=engines_matrix,
        nodesep=1.25,
        outputorder=nodesfirst,
        pad=0.209,
        rankdir=LR,
        ranksep=1.806,
        splines=spline
    ];
    node [color="#2563eb",
        fillcolor="#3b82f6",
        fontcolor="#eff6ff",
        fontname=Arial,
        label="\\N",
        penwidth=0,
        shape=rect,
        style=filled
    ];
    edge [arrowsize=0.75,
        color="#8D8D8D",
        fontcolor="#C9C9C9",
        fontname=Arial,
        fontsize=14,
        penwidth=2,
        style=""
    ];
    mod_capture [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.723,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Device Capture &amp;<BR/>SVG Instrumentation</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/capture.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">svglite::svgstring() single-draw dual SVG<BR/>capture, grid display-list leaf wrapping,<BR/>draw-time gloss_probe viewport<BR/>recorder, &lt;defs&gt;/&lt;use&gt; inlining, xml2<BR/>geometry parsing, and dense PNG</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.modules.mod_capture",
        likec4_level=0,
        margin="0.5,0.223",
        width=4.584];
    mod_registry [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Engine Registry &amp; Load Hook</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/engine-registry.R, R/zzz.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Private package environment registry,<BR/>class-hierarchy &amp; priority dispatch,<BR/>page_kind candidate disambiguation,<BR/>and lazy Suggests checks.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.modules.mod_registry",
        likec4_level=0,
        margin="0.5,0.223",
        width=4.584];
    mod_capture -> mod_registry [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="217" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Dispatches by class &amp; page_kind</FONT></TD></TR></TABLE>>,
        likec4_id="1vpn2qj",
        style=dashed];
    eng_grid [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">grid Engine</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/engine-grid.R (grid)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Captures raw grid grobs, gLists, gTrees,<BR/>gtables, grid drawing functions, and<BR/>recorded grid plots.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.engines.eng_grid",
        likec4_level=0,
        margin="0.5,0.223",
        width=4.584];
    eng_ggplot [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">ggplot2 Engine</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/engine-ggplot.R (Suggests: ggplot2)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Single-build ggplot_build -&gt;<BR/>ggplot_gtable -&gt; grid.draw extracting<BR/>raw/built tables, scale/palette maps,<BR/>layer recipes, facets, and neutral<BR/>lineage.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.engines.eng_ggplot",
        likec4_level=0,
        margin="0.5,0.223",
        width=4.584];
    eng_grid -> eng_ggplot [style=invis];
    eng_patchwork [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">patchwork Engine</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/engine-patchwork.R (Suggests: patchwork)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Composite multi-plot IR extraction with<BR/>per-subplot panel and table<BR/>namespaces without double-building<BR/>stochastic subplots.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.engines.eng_patchwork",
        likec4_level=0,
        margin="0.5,0.223",
        width=4.584];
    eng_ggplot -> eng_patchwork [style=invis];
    eng_heatmap [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">ComplexHeatmap Engine</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/engine-heatmap.R (Suggests:</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Single draw() capture preserving draw-<BR/>time clustering permutations<BR/>(row_order/column_order) in ir.orders,<BR/>matrix/annotation tables, and color<BR/>maps.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.engines.eng_heatmap",
        likec4_level=0,
        margin="0.5,0.223",
        width=4.584];
    eng_patchwork -> eng_heatmap [style=invis];
    eng_base [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">base Graphics Engine</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/engine-base.R (grDevices/graphics)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Step-by-step display-list replay on<BR/>svglite isolating per-call &lt;g id='L...'&gt;<BR/>leaves and par('usr')/par('plt') plot<BR/>regions.</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.engines.eng_base",
        likec4_level=0,
        margin="0.5,0.223",
        width=4.584];
    mod_ir_lineage [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.723,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Engine IR &amp;<BR/>Structural Lineage</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R/ir-lineage.R</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Normalizes panel coordinate domains,<BR/>scale/palette dictionaries, layer specs,<BR/>and neutral element-to-table<BR/>cardinalities (1:1, N:1, 1:M,<BR/>stat_aggregated).</FONT></TD></TR></TABLE>>,
        likec4_id="gloss_core.modules.mod_ir_lineage",
        likec4_level=0,
        margin="0.5,0.223",
        width=4.584];
    eng_base -> mod_ir_lineage [style=invis];
}
`;case`guardrails_monitor`:return`digraph {
    graph [TBbalance=min,
        bgcolor=transparent,
        compound=true,
        fontname=Arial,
        fontsize=20,
        labeljust=l,
        labelloc=t,
        layout=dot,
        likec4_viewId=guardrails_monitor,
        nodesep=1.25,
        outputorder=nodesfirst,
        pad=0.209,
        rankdir=LR,
        ranksep=1.945,
        splines=spline
    ];
    node [color="#2563eb",
        fillcolor="#3b82f6",
        fontcolor="#eff6ff",
        fontname=Arial,
        label="\\N",
        penwidth=0,
        shape=rect,
        style=filled
    ];
    edge [arrowsize=0.75,
        color="#8D8D8D",
        fontcolor="#C9C9C9",
        fontname=Arial,
        fontsize=14,
        penwidth=2,
        style=""
    ];
    p1_source_map [color="#ac5300",
        fillcolor="#D97706",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">P1 · Compiler Source<BR/>Map, Not Gatekeeper</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Faithfully observe and record device<BR/>groups, viewports, engine IR, and neutral<BR/>lineage cardinalities. Verification belongs<BR/>to upper-layer semantic tools, never low-<BR/>level capture gates.</FONT></TD></TR></TABLE>>,
        likec4_id="principles.p1_source_map",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    g_tests [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Guardrail · Unit<BR/>Test &amp; Build Health</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Tracks live testthat suite coverage across<BR/>core modules and engines.</FONT></TD></TR></TABLE>>,
        likec4_id="principles.g_tests",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    p1_source_map -> g_tests [arrowhead=normal,
        color="#a35905",
        fontcolor="#ffffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="193" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Verifies neutral capture facts</FONT></TD></TR></TABLE>>,
        likec4_id="2f34yf",
        style=dashed];
    p2_core_boundary [color="#ac5300",
        fillcolor="#D97706",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">P2 · Strict In-Core Boundary</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">The R package owns only live-R graphics<BR/>device instrumentation, engine IR<BR/>extraction, runtime source inventory, and<BR/>open-format packaging. Agents, MCP,<BR/>Workbench, and SVG refinement live</FONT></TD></TR></TABLE>>,
        likec4_id="principles.p2_core_boundary",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    g_core_boundary [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Guardrail · Strict<BR/>In-Core Boundary</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Verifies R/ contains no out-of-core agent<BR/>runners, MCP servers, binary codecs, or<BR/>embedded UI code.</FONT></TD></TR></TABLE>>,
        likec4_id="principles.g_core_boundary",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    p2_core_boundary -> g_core_boundary [arrowhead=normal,
        color="#a35905",
        fontcolor="#ffffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="166" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Prevents v1 scope creep</FONT></TD></TR></TABLE>>,
        likec4_id="166k9b",
        style=dashed];
    p3_single_capture [color="#ac5300",
        fillcolor="#D97706",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">P3 · Single Capture,<BR/>Layered Payload</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Asset Map and Asset Bundle serialize from<BR/>the same in-memory gloss_capture object<BR/>so figures (including stochastic<BR/>jitter/UMAP) are never redrawn during<BR/>packaging.</FONT></TD></TR></TABLE>>,
        likec4_id="principles.p3_single_capture",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    gloss_core [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">gloss R Core Package</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R (&gt;= 4.2.0), svglite, xml2, jsonlite, digest</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Lightweight R core package: single-draw<BR/>device capture, Engine IR extraction,<BR/>structural lineage, runtime source<BR/>inventory, and open asset packaging.</FONT></TD></TR></TABLE>>,
        likec4_id=gloss_core,
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    p3_single_capture -> gloss_core [style=invis];
    p4_file_first [color="#ac5300",
        fillcolor="#D97706",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">P4 · File-First, Zero<BR/>Proprietary Codecs</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Emit standard UTF-8 SVG, JSON, and CSV<BR/>(or Parquet) readable directly by Python,<BR/>JS, DuckDB, R, and coding agents without<BR/>custom binary decoders or background R<BR/>processes.</FONT></TD></TR></TABLE>>,
        likec4_id="principles.p4_file_first",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    g_cran_hygiene [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Guardrail · CRAN &amp; R Hygiene</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Checks R/ and tests/ for forbidden super-<BR/>assignment (&lt;&lt;-), .GlobalEnv writes, and<BR/>stray Rplots.pdf artifacts.</FONT></TD></TR></TABLE>>,
        likec4_id="principles.g_cran_hygiene",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    p4_file_first -> g_cran_hygiene [arrowhead=normal,
        color="#a35905",
        fontcolor="#ffffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="199" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Verifies clean open packaging</FONT></TD></TR></TABLE>>,
        likec4_id="1f3ofzu",
        style=dashed];
    p5_minimal_surface [color="#ac5300",
        fillcolor="#D97706",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">P5 · Minimal Export<BR/>Surface (8 APIs)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Keep NAMESPACE tight at exactly 8<BR/>exported functions and keep built-in<BR/>engines in-repo with package<BR/>dependencies strictly in Suggests.</FONT></TD></TR></TABLE>>,
        likec4_id="principles.p5_minimal_surface",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    g_exports [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Guardrail · Export Surface<BR/>Alignment (8 APIs)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Verifies NAMESPACE exports match the 8<BR/>canonical functions in AGENTS.md with<BR/>zero unexpected exports.</FONT></TD></TR></TABLE>>,
        likec4_id="principles.g_exports",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    p5_minimal_surface -> g_exports [arrowhead=normal,
        color="#a35905",
        fontcolor="#ffffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="163" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Enforces 8-API contract</FONT></TD></TR></TABLE>>,
        likec4_id=zx6b6e,
        minlen=1,
        style=dashed];
    g_suggests [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Guardrail · Engine<BR/>Dependencies in Suggests</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Verifies ggplot2, patchwork,<BR/>ComplexHeatmap stay in DESCRIPTION<BR/>Suggests and never leak into Imports.</FONT></TD></TR></TABLE>>,
        likec4_id="principles.g_suggests",
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    p5_minimal_surface -> g_suggests [arrowhead=normal,
        color="#a35905",
        fontcolor="#ffffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="185" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Enforces Suggests isolation</FONT></TD></TR></TABLE>>,
        likec4_id="6t2ora",
        minlen=1,
        style=dashed];
}
`;case`open_contracts`:return`digraph {
    graph [TBbalance=min,
        bgcolor=transparent,
        compound=true,
        fontname=Arial,
        fontsize=20,
        labeljust=l,
        labelloc=t,
        layout=dot,
        likec4_viewId=open_contracts,
        nodesep=1.25,
        outputorder=nodesfirst,
        pad=0.209,
        rankdir=LR,
        ranksep=1.945,
        splines=spline
    ];
    node [color="#2563eb",
        fillcolor="#3b82f6",
        fontcolor="#eff6ff",
        fontname=Arial,
        label="\\N",
        penwidth=0,
        shape=rect,
        style=filled
    ];
    edge [arrowsize=0.75,
        color="#8D8D8D",
        fontcolor="#C9C9C9",
        fontname=Arial,
        fontsize=14,
        penwidth=2,
        style=""
    ];
    subgraph cluster_ecosystem {
        graph [color="#32126a",
            fillcolor="#491e93",
            label=<<FONT POINT-SIZE="11" COLOR="#ffffffb3"><B>OUTER ECOSYSTEM (OUT-OF-CORE)</B></FONT>>,
            likec4_depth=1,
            likec4_id=ecosystem,
            likec4_level=0,
            margin=40,
            style=filled
        ];
        skill_gloss [color="#4e0cc3",
            fillcolor="#7C3AED",
            fixedsize=true,
            fontcolor="#ffffff",
            group=ecosystem,
            height=2.514,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Base Protocol Skill: gloss</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">SKILL.md</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Entry protocol guiding AI coding agents to<BR/>read asset-map.json first, plan task<BR/>context packets, and selectively unpack<BR/>tables/sources.</FONT></TD></TR></TABLE>>,
            likec4_id="ecosystem.skill_gloss",
            likec4_level=1,
            margin="0.278,0.306",
            width=4.445];
        workbench [color="#4e0cc3",
            fillcolor="#7C3AED",
            fixedsize=true,
            fontcolor="#ffffff",
            height=2.514,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Static Frontend: Workbench</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">Static SPA (Browser)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Zero-decoder browser inspector for .gloss<BR/>bundles: layer outline tree, raw/built data<BR/>tables, bidirectional brushing, and<BR/>original-vs-derived SVG diff.</FONT></TD></TR></TABLE>>,
            likec4_id="ecosystem.workbench",
            likec4_level=1,
            margin="0.278,0.306",
            width=4.445];
        external_scripts [color="#4e0cc3",
            fillcolor="#7C3AED",
            fixedsize=true,
            fontcolor="#ffffff",
            height=2.639,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Python / JS /<BR/>DuckDB Toolchains</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">pandas, polars, DuckDB, lxml</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Direct batch analytics and automated<BR/>publishing pipelines reading standard<BR/>SVG/JSON/CSV without installing R.</FONT></TD></TR></TABLE>>,
            likec4_id="ecosystem.external_scripts",
            likec4_level=1,
            margin="0.278,0.306",
            width=4.445];
        skill_refine [color="#4e0cc3",
            fillcolor="#7C3AED",
            fixedsize=true,
            fontcolor="#ffffff",
            group=ecosystem,
            height=2.875,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">SVG Refinement<BR/>Skill: gloss-svg-refine</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">SKILL.md</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Publication-grade label repulsion,<BR/>typography hierarchy, legend layout, and<BR/>palette updates producing derived SVGs<BR/>linked via parent_manifest_sha256.</FONT></TD></TR></TABLE>>,
            likec4_id="ecosystem.skill_refine",
            likec4_level=1,
            margin="0.278,0.306",
            width=4.445];
        skill_audit [color="#4e0cc3",
            fillcolor="#7C3AED",
            fixedsize=true,
            fontcolor="#ffffff",
            group=ecosystem,
            height=2.875,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Semantic Audit<BR/>Skill: gloss-audit</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">SKILL.md</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">High-level verification checking<BR/>manuscript claims, sample sizes,<BR/>statistical summaries, and derived SVG<BR/>geometric fidelity against bundle tables.</FONT></TD></TR></TABLE>>,
            likec4_id="ecosystem.skill_audit",
            likec4_level=1,
            margin="0.278,0.306",
            width=4.445];
        skill_report [color="#4e0cc3",
            fillcolor="#7C3AED",
            fixedsize=true,
            fontcolor="#ffffff",
            group=ecosystem,
            height=2.5,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Report Skill: gloss-report</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">SKILL.md</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Synthesizes traceable multi-figure<BR/>analysis reports backed by table rows, leaf<BR/>IDs, and methods docs.</FONT></TD></TR></TABLE>>,
            likec4_id="ecosystem.skill_report",
            likec4_level=1,
            margin="0.278,0.306",
            width=4.445];
        gloss_mcp [color="#4e0cc3",
            fillcolor="#7C3AED",
            fixedsize=true,
            fontcolor="#ffffff",
            group=ecosystem,
            height=2.514,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Live R Bridge: gloss-mcp</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">Thin 4-tool MCP Adapter</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Optional bridge for interactive<BR/>RStudio/Positron sessions or million-row<BR/>tables: capture_figure, get_asset_map,<BR/>query_slice, create_bundle.</FONT></TD></TR></TABLE>>,
            likec4_id="ecosystem.gloss_mcp",
            likec4_level=1,
            margin="0.278,0.306",
            width=4.445];
    }
    subgraph cluster_open_assets {
        graph [color="#052c29",
            fillcolor="#0f413d",
            label=<<FONT POINT-SIZE="11" COLOR="#b2ffffb3"><B>OPEN FILE CONTRACTS</B></FONT>>,
            likec4_depth=1,
            likec4_id=open_assets,
            likec4_level=0,
            margin=40,
            style=filled
        ];
        asset_map [color="#007c27",
            fillcolor="#16A34A",
            fixedsize=true,
            fontcolor="#ffffff",
            height=2.5,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Asset Map (asset-map.json)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">JSON (~tens of KB)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Lightweight global catalog of page<BR/>geometry, SVG digests, Engine IR (panels,<BR/>layers, scales, orders), table column<BR/>summaries, lineage, and source pointers.</FONT></TD></TR></TABLE>>,
            likec4_id="open_assets.asset_map",
            likec4_level=1,
            margin="0.223,0.223",
            width=4.445];
        asset_bundle [color="#007c27",
            fillcolor="#16A34A",
            fixedsize=true,
            fontcolor="#ffffff",
            height=2.723,
            label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">Asset Bundle<BR/>(figure.gloss/ or .zip)</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">UTF-8 SVG + JSON + CSV + PNG</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Self-contained portable bundle:<BR/>manifest.json, asset-map.json,<BR/>omitted.json, assets/original.svg,<BR/>scene/{scene.svg,leaves.json,elements.jso<BR/>n,rasters/}, tables/{schema.json,*.csv},</FONT></TD></TR></TABLE>>,
            likec4_id="open_assets.asset_bundle",
            likec4_level=1,
            margin="0.223,0.223",
            width=4.445];
    }
    skill_gloss -> skill_refine [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="187" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Delegates visual refinement</FONT></TD></TR></TABLE>>,
        likec4_id=wkcun1,
        minlen=1,
        style=dashed,
        weight=3];
    skill_gloss -> skill_audit [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="191" HEIGHT="42" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Delegates statistical/caption<BR/>verification</FONT></TD></TR></TABLE>>,
        likec4_id="1p1lnxf",
        minlen=1,
        style=dashed,
        weight=3];
    skill_gloss -> skill_report [arrowhead=normal,
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="213" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Delegates multi-figure reporting</FONT></TD></TR></TABLE>>,
        likec4_id=wjsz7k,
        minlen=1,
        style=dashed,
        weight=3];
    skill_gloss -> gloss_mcp [arrowhead=normal,
        color="#5d2cb2",
        fontcolor="#ffffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="194" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Optional live-session queries</FONT></TD></TR></TABLE>>,
        likec4_id="14wysat",
        style=dotted,
        weight=3];
    skill_gloss -> asset_map [arrowhead=normal,
        color="#026395",
        fontcolor="#ddffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="168" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Reads compact map first</FONT></TD></TR></TABLE>>,
        likec4_id="1oafq3b",
        style=solid];
    skill_gloss -> asset_bundle [arrowhead=normal,
        color="#026395",
        fontcolor="#ddffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="206" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Reads targeted CSV/SVG slices</FONT></TD></TR></TABLE>>,
        likec4_id="1la4x1b",
        style=solid];
    workbench -> asset_bundle [arrowhead=normal,
        color="#026395",
        fontcolor="#ddffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="143" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Opens .gloss dir / zip</FONT></TD></TR></TABLE>>,
        likec4_id="1od99g6",
        minlen=1,
        style=solid];
    external_scripts -> asset_bundle [arrowhead=normal,
        color="#026395",
        fontcolor="#ddffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="161" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Batch SQL / Python / JS</FONT></TD></TR></TABLE>>,
        likec4_id="10wesln",
        minlen=1,
        style=solid];
    gloss_core [color="#007c27",
        fillcolor="#16A34A",
        fixedsize=true,
        fontcolor="#ffffff",
        height=2.5,
        label=<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="4"><TR><TD><FONT POINT-SIZE="20">gloss R Core Package</FONT></TD></TR><TR><TD><FONT POINT-SIZE="13" COLOR="#ffffff">R (&gt;= 4.2.0), svglite, xml2, jsonlite, digest</FONT></TD></TR><TR><TD><FONT POINT-SIZE="15" COLOR="#ffffff">Lightweight R core package: single-draw<BR/>device capture, Engine IR extraction,<BR/>structural lineage, runtime source<BR/>inventory, and open asset packaging.</FONT></TD></TR></TABLE>>,
        likec4_id=gloss_core,
        likec4_level=0,
        margin="0.223,0.223",
        width=4.445];
    gloss_mcp -> gloss_core [arrowhead=normal,
        color="#5d2cb2",
        fontcolor="#ffffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="199" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">Calls 4 core functions in live R</FONT></TD></TR></TABLE>>,
        likec4_id=ntyiy5,
        style=dotted];
    gloss_core -> asset_map [arrowhead=normal,
        color="#026395",
        fontcolor="#ddffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="110" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">gl_asset_map()</FONT></TD></TR></TABLE>>,
        likec4_id="151z9wf",
        style=solid,
        weight=2];
    gloss_core -> asset_bundle [arrowhead=normal,
        color="#026395",
        fontcolor="#ddffff",
        label=<<TABLE FIXEDSIZE="TRUE" WIDTH="126" HEIGHT="25" BORDER="0" CELLPADDING="0" CELLSPACING="0" BGCOLOR="#18191BA0"><TR><TD ALIGN="TEXT" BALIGN="LEFT"><FONT POINT-SIZE="14">gl_asset_bundle()</FONT></TD></TR></TABLE>>,
        likec4_id="3jr86v",
        style=solid,
        weight=2];
}
`;default:throw Error(`Unknown viewId: `+e)}},t=e=>{switch(e){case`index`:return`<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
 "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<!-- Generated by graphviz version 16.1.0 (0)
 -->
<!-- Pages: 1 -->
<svg width="1643pt" height="968pt"
 viewBox="0.00 0.00 1643.00 968.00" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<g id="graph0" class="graph" transform="scale(1 1) rotate(0) translate(15.05 953.05)">
<g id="clust1" class="cluster">
<title>cluster_open_assets</title>
<polygon fill="#0f413d" stroke="#052c29" points="1205.08,-353 1205.08,-930 1605.12,-930 1605.12,-353 1205.08,-353"/>
<text xml:space="preserve" text-anchor="start" x="1213.08" y="-917.1" font-family="Arial" font-weight="bold" font-size="11.00" fill="#b2ffff" fill-opacity="0.701961">OPEN FILE CONTRACTS</text>
</g>
<!-- asset_map -->
<g id="node1" class="node">
<title>asset_map</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1565.12,-869 1245.08,-869 1245.08,-689 1565.12,-689 1565.12,-869"/>
<text xml:space="preserve" text-anchor="start" x="1280.61" y="-818.8" font-family="Arial" font-size="20.00" fill="#ffffff">Asset Map (asset&#45;map.json)</text>
<text xml:space="preserve" text-anchor="start" x="1347.84" y="-797.8" font-family="Arial" font-size="13.00" fill="#ffffff">JSON (~tens of KB)</text>
<text xml:space="preserve" text-anchor="start" x="1291.68" y="-776.2" font-family="Arial" font-size="15.00" fill="#ffffff">Lightweight global catalog of page</text>
<text xml:space="preserve" text-anchor="start" x="1262.11" y="-758.2" font-family="Arial" font-size="15.00" fill="#ffffff">geometry, SVG digests, Engine IR (panels,</text>
<text xml:space="preserve" text-anchor="start" x="1285.05" y="-740.2" font-family="Arial" font-size="15.00" fill="#ffffff">layers, scales, orders), table column</text>
<text xml:space="preserve" text-anchor="start" x="1267.95" y="-722.2" font-family="Arial" font-size="15.00" fill="#ffffff">summaries, lineage, and source pointers.</text>
</g>
<!-- asset_bundle -->
<g id="node2" class="node">
<title>asset_bundle</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1565.12,-589.03 1245.08,-589.03 1245.08,-392.97 1565.12,-392.97 1565.12,-589.03"/>
<text xml:space="preserve" text-anchor="start" x="1346.17" y="-551.8" font-family="Arial" font-size="20.00" fill="#ffffff">Asset Bundle</text>
<text xml:space="preserve" text-anchor="start" x="1314.51" y="-527.8" font-family="Arial" font-size="20.00" fill="#ffffff">(figure.gloss/ or .zip)</text>
<text xml:space="preserve" text-anchor="start" x="1304.14" y="-506.8" font-family="Arial" font-size="13.00" fill="#ffffff">UTF&#45;8 SVG + JSON + CSV + PNG</text>
<text xml:space="preserve" text-anchor="start" x="1301.28" y="-485.2" font-family="Arial" font-size="15.00" fill="#ffffff">Self&#45;contained portable bundle:</text>
<text xml:space="preserve" text-anchor="start" x="1303.81" y="-467.2" font-family="Arial" font-size="15.00" fill="#ffffff">manifest.json, asset&#45;map.json,</text>
<text xml:space="preserve" text-anchor="start" x="1296.72" y="-449.2" font-family="Arial" font-size="15.00" fill="#ffffff">omitted.json, assets/original.svg,</text>
<text xml:space="preserve" text-anchor="start" x="1262.94" y="-431.2" font-family="Arial" font-size="15.00" fill="#ffffff">scene/{scene.svg,leaves.json,elements.jso</text>
<text xml:space="preserve" text-anchor="start" x="1277.54" y="-413.2" font-family="Arial" font-size="15.00" fill="#ffffff">n,rasters/}, tables/{schema.json,*.csv},</text>
</g>
<!-- user -->
<g id="node3" class="node">
<title>user</title>
<polygon fill="#64748b" stroke="#475569" stroke-width="0" points="320.04,-460 0,-460 0,-280 320.04,-280 320.04,-460"/>
<text xml:space="preserve" text-anchor="start" x="36.06" y="-400" font-family="Arial" font-size="20.00" fill="#f8fafc">R Analyst / AI Coding Agent</text>
<text xml:space="preserve" text-anchor="start" x="18.29" y="-377" font-family="Arial" font-size="15.00" fill="#cbd5e1">Authors R figures in an active R session or</text>
<text xml:space="preserve" text-anchor="start" x="20.37" y="-359" font-family="Arial" font-size="15.00" fill="#cbd5e1">consumes portable .gloss assets for Q&amp;A,</text>
<text xml:space="preserve" text-anchor="start" x="19.11" y="-341" font-family="Arial" font-size="15.00" fill="#cbd5e1">publication SVG refinement, and statistical</text>
<text xml:space="preserve" text-anchor="start" x="131.66" y="-323" font-family="Arial" font-size="15.00" fill="#cbd5e1">auditing.</text>
</g>
<!-- gloss_core -->
<g id="node4" class="node">
<title>gloss_core</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="979.08,-457 659.04,-457 659.04,-277 979.08,-277 979.08,-457"/>
<text xml:space="preserve" text-anchor="start" x="719.57" y="-406.8" font-family="Arial" font-size="20.00" fill="#ffffff">gloss R Core Package</text>
<text xml:space="preserve" text-anchor="start" x="700.2" y="-385.8" font-family="Arial" font-size="13.00" fill="#ffffff">R (&gt;= 4.2.0), svglite, xml2, jsonlite, digest</text>
<text xml:space="preserve" text-anchor="start" x="683.99" y="-364.2" font-family="Arial" font-size="15.00" fill="#ffffff">Lightweight R core package: single&#45;draw</text>
<text xml:space="preserve" text-anchor="start" x="696.49" y="-346.2" font-family="Arial" font-size="15.00" fill="#ffffff">device capture, Engine IR extraction,</text>
<text xml:space="preserve" text-anchor="start" x="708.17" y="-328.2" font-family="Arial" font-size="15.00" fill="#ffffff">structural lineage, runtime source</text>
<text xml:space="preserve" text-anchor="start" x="694.81" y="-310.2" font-family="Arial" font-size="15.00" fill="#ffffff">inventory, and open asset packaging.</text>
</g>
<!-- principles -->
<g id="node5" class="node">
<title>principles</title>
<polygon fill="#0f766e" stroke="#00524b" stroke-width="0" points="320.04,-180 0,-180 0,0 320.04,0 320.04,-180"/>
<text xml:space="preserve" text-anchor="start" x="73.32" y="-123" font-family="Arial" font-size="20.00" fill="#c7ffff">Design Principles &amp;</text>
<text xml:space="preserve" text-anchor="start" x="66.65" y="-99" font-family="Arial" font-size="20.00" fill="#c7ffff">Alignment Guardrails</text>
<text xml:space="preserve" text-anchor="start" x="32.47" y="-76" font-family="Arial" font-size="15.00" fill="#b2ffff">Canonical architectural invariants from</text>
<text xml:space="preserve" text-anchor="start" x="34.15" y="-58" font-family="Arial" font-size="15.00" fill="#b2ffff">AGENTS.md paired with live code&#45;vs&#45;</text>
<text xml:space="preserve" text-anchor="start" x="76.23" y="-40" font-family="Arial" font-size="15.00" fill="#b2ffff">intent verification checks.</text>
</g>
<!-- ecosystem -->
<g id="node6" class="node">
<title>ecosystem</title>
<polygon fill="#7c3aed" stroke="#4e0cc3" stroke-width="0" points="320.04,-745 0,-745 0,-565 320.04,-565 320.04,-745"/>
<text xml:space="preserve" text-anchor="start" x="21.1" y="-685" font-family="Arial" font-size="20.00" fill="#ffffff">Outer Ecosystem (Out&#45;of&#45;Core)</text>
<text xml:space="preserve" text-anchor="start" x="39.95" y="-662" font-family="Arial" font-size="15.00" fill="#ffffff">Independent skills, live bridge, static</text>
<text xml:space="preserve" text-anchor="start" x="38.7" y="-644" font-family="Arial" font-size="15.00" fill="#ffffff">frontend, and cross&#45;language scripts</text>
<text xml:space="preserve" text-anchor="start" x="17.87" y="-626" font-family="Arial" font-size="15.00" fill="#ffffff">collaborating exclusively over Asset Map &amp;</text>
<text xml:space="preserve" text-anchor="start" x="81.23" y="-608" font-family="Arial" font-size="15.00" fill="#ffffff">Asset Bundle contracts.</text>
</g>
<!-- user&#45;&gt;gloss_core -->
<g id="edge1" class="edge">
<title>user&#45;&gt;gloss_core</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M319.65,-369.28C419.15,-368.82 547.33,-368.24 648.78,-367.77"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="648.62,-370.4 656.11,-367.74 648.6,-365.15 648.62,-370.4"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="397.04,-368.94 397.04,-393.94 582.04,-393.94 582.04,-368.94 397.04,-368.94"/>
<text xml:space="preserve" text-anchor="start" x="397.04" y="-379.94" font-family="Arial" font-size="14.00" fill="#c9c9c9">Captures R figure + sources</text>
</g>
<!-- gloss_core&#45;&gt;asset_map -->
<g id="edge6" class="edge">
<title>gloss_core&#45;&gt;asset_map</title>
<path fill="none" stroke="#026395" stroke-width="2" d="M947.04,-456.8C1022.08,-509.84 1118.96,-578.29 1205.08,-639 1225.35,-653.29 1246.79,-668.39 1267.8,-683.17"/>
<polygon fill="#026395" stroke="#026395" stroke-width="2" points="1266.02,-685.13 1273.66,-687.3 1269.04,-680.84 1266.02,-685.13"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1057.08,-616.98 1057.08,-641.98 1167.08,-641.98 1167.08,-616.98 1057.08,-616.98"/>
<text xml:space="preserve" text-anchor="start" x="1057.08" y="-627.98" font-family="Arial" font-size="14.00" fill="#ddffff">gl_asset_map()</text>
</g>
<!-- gloss_core&#45;&gt;asset_bundle -->
<g id="edge7" class="edge">
<title>gloss_core&#45;&gt;asset_bundle</title>
<path fill="none" stroke="#026395" stroke-width="2" d="M978.77,-376.05C1040.62,-381.75 1111.72,-391.01 1175.08,-406 1194.85,-410.68 1215.25,-416.59 1235.33,-423.09"/>
<polygon fill="#026395" stroke="#026395" stroke-width="2" points="1234.35,-425.53 1242.29,-425.39 1235.99,-420.55 1234.35,-425.53"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1049.08,-406 1049.08,-431 1175.08,-431 1175.08,-406 1049.08,-406"/>
<text xml:space="preserve" text-anchor="start" x="1049.08" y="-417" font-family="Arial" font-size="14.00" fill="#ddffff">gl_asset_bundle()</text>
</g>
<!-- principles&#45;&gt;gloss_core -->
<g id="edge2" class="edge">
<title>principles&#45;&gt;gloss_core</title>
<path fill="none" stroke="#a35905" stroke-width="2" stroke-dasharray="5,2" d="M319.65,-156.88C419.45,-198.95 548.11,-253.19 649.7,-296.02"/>
<polygon fill="#a35905" stroke="#a35905" stroke-width="2" points="648.42,-298.33 656.35,-298.82 650.46,-293.49 648.42,-298.33"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="407.54,-269.5 407.54,-311.5 571.54,-311.5 571.54,-269.5 407.54,-269.5"/>
<text xml:space="preserve" text-anchor="start" x="407.54" y="-297.5" font-family="Arial" font-size="14.00" fill="#ffffff">Guards architecture,</text>
<text xml:space="preserve" text-anchor="start" x="407.54" y="-280.7" font-family="Arial" font-size="14.00" fill="#ffffff">surface &amp; CRAN hygiene</text>
</g>
<!-- ecosystem&#45;&gt;asset_map -->
<g id="edge4" class="edge">
<title>ecosystem&#45;&gt;asset_map</title>
<path fill="none" stroke="#026395" stroke-width="2" d="M319.95,-715.53C343.18,-722.5 367.03,-728.65 390.04,-733 683.22,-788.41 1032.15,-790.65 1234.85,-785.81"/>
<polygon fill="#026395" stroke="#026395" stroke-width="2" points="1234.83,-788.44 1242.26,-785.63 1234.7,-783.19 1234.83,-788.44"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="735.06,-786.1 735.06,-811.1 903.06,-811.1 903.06,-786.1 735.06,-786.1"/>
<text xml:space="preserve" text-anchor="start" x="735.06" y="-797.1" font-family="Arial" font-size="14.00" fill="#ddffff">Reads compact map first</text>
</g>
<!-- ecosystem&#45;&gt;asset_bundle -->
<g id="edge5" class="edge">
<title>ecosystem&#45;&gt;asset_bundle</title>
<path fill="none" stroke="#026395" stroke-width="2" d="M319.86,-665.92C522.01,-675.48 880.35,-677.81 1175.08,-602 1195.12,-596.84 1215.5,-589.86 1235.41,-581.89"/>
<polygon fill="#026395" stroke="#026395" stroke-width="2" points="1236.4,-584.32 1242.34,-579.05 1234.41,-579.46 1236.4,-584.32"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="802.56,-667.76 802.56,-692.76 835.56,-692.76 835.56,-667.76 802.56,-667.76"/>
<text xml:space="preserve" text-anchor="start" x="802.56" y="-678.76" font-family="Arial" font-size="14.00" fill="#ddffff">[...]</text>
</g>
<!-- ecosystem&#45;&gt;gloss_core -->
<g id="edge3" class="edge">
<title>ecosystem&#45;&gt;gloss_core</title>
<path fill="none" stroke="#5d2cb2" stroke-width="2" stroke-dasharray="1,5" d="M319.65,-585.47C419.45,-541.72 548.11,-485.33 649.7,-440.8"/>
<polygon fill="#5d2cb2" stroke="#5d2cb2" stroke-width="2" points="650.55,-443.29 656.37,-437.87 648.44,-438.48 650.55,-443.29"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="390.04,-553.62 390.04,-578.62 589.04,-578.62 589.04,-553.62 390.04,-553.62"/>
<text xml:space="preserve" text-anchor="start" x="390.04" y="-564.62" font-family="Arial" font-size="14.00" fill="#ffffff">Calls 4 core functions in live R</text>
</g>
</g>
</svg>
`;case`core_architecture`:return`<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
 "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<!-- Generated by graphviz version 16.1.0 (0)
 -->
<!-- Pages: 1 -->
<svg width="2837pt" height="1304pt"
 viewBox="0.00 0.00 2837.00 1304.00" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<g id="graph0" class="graph" transform="scale(1 1) rotate(0) translate(15.05 1288.53)">
<g id="clust1" class="cluster">
<title>cluster_modules</title>
<polygon fill="#3e4651" stroke="#2d333d" points="770.02,-8 770.02,-645.28 2754.02,-645.28 2754.02,-8 770.02,-8"/>
<text xml:space="preserve" text-anchor="start" x="778.02" y="-632.38" font-family="Arial" font-weight="bold" font-size="11.00" fill="#cbd5e1" fill-opacity="0.701961">CORE INTERNAL MODULES</text>
</g>
<g id="clust2" class="cluster">
<title>cluster_engines</title>
<polygon fill="#3e4651" stroke="#2d333d" points="275.02,-693.28 275.02,-1265.48 1615.02,-1265.48 1615.02,-693.28 275.02,-693.28"/>
<text xml:space="preserve" text-anchor="start" x="283.02" y="-1252.58" font-family="Arial" font-weight="bold" font-size="11.00" fill="#cbd5e1" fill-opacity="0.701961">BUILT&#45;IN PLOTTING ENGINES (SUGGESTS)</text>
</g>
<!-- mod_capture -->
<g id="node1" class="node">
<title>mod_capture</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="2400.04,-584.08 2070,-584.08 2070,-388.03 2400.04,-388.03 2400.04,-584.08"/>
<text xml:space="preserve" text-anchor="start" x="2156.65" y="-546.86" font-family="Arial" font-size="20.00" fill="#ffffff">Device Capture &amp;</text>
<text xml:space="preserve" text-anchor="start" x="2142.2" y="-522.86" font-family="Arial" font-size="20.00" fill="#ffffff">SVG Instrumentation</text>
<text xml:space="preserve" text-anchor="start" x="2200.34" y="-501.86" font-family="Arial" font-size="13.00" fill="#ffffff">R/capture.R</text>
<text xml:space="preserve" text-anchor="start" x="2099.97" y="-480.26" font-family="Arial" font-size="15.00" fill="#ffffff">svglite::svgstring() single&#45;draw dual SVG</text>
<text xml:space="preserve" text-anchor="start" x="2107.46" y="-462.26" font-family="Arial" font-size="15.00" fill="#ffffff">capture, grid display&#45;list leaf wrapping,</text>
<text xml:space="preserve" text-anchor="start" x="2129.14" y="-444.26" font-family="Arial" font-size="15.00" fill="#ffffff">draw&#45;time gloss_probe viewport</text>
<text xml:space="preserve" text-anchor="start" x="2111.62" y="-426.26" font-family="Arial" font-size="15.00" fill="#ffffff">recorder, &lt;defs&gt;/&lt;use&gt; inlining, xml2</text>
<text xml:space="preserve" text-anchor="start" x="2119.54" y="-408.26" font-family="Arial" font-size="15.00" fill="#ffffff">geometry parsing, and dense PNG</text>
</g>
<!-- mod_package_assets -->
<g id="node2" class="node">
<title>mod_package_assets</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1560.04,-576.06 1230,-576.06 1230,-396.06 1560.04,-396.06 1560.04,-576.06"/>
<text xml:space="preserve" text-anchor="start" x="1259.39" y="-525.86" font-family="Arial" font-size="20.00" fill="#ffffff">Asset Map &amp; Bundle Packager</text>
<text xml:space="preserve" text-anchor="start" x="1336.49" y="-504.86" font-family="Arial" font-size="13.00" fill="#ffffff">R/package&#45;assets.R</text>
<text xml:space="preserve" text-anchor="start" x="1272.87" y="-483.26" font-family="Arial" font-size="15.00" fill="#ffffff">Layered open&#45;format serialization for</text>
<text xml:space="preserve" text-anchor="start" x="1283.72" y="-465.26" font-family="Arial" font-size="15.00" fill="#ffffff">asset&#45;map.json and .gloss/ dir/zip</text>
<text xml:space="preserve" text-anchor="start" x="1272.46" y="-447.26" font-family="Arial" font-size="15.00" fill="#ffffff">bundles with SHA&#45;256 manifest.json,</text>
<text xml:space="preserve" text-anchor="start" x="1269.13" y="-429.26" font-family="Arial" font-size="15.00" fill="#ffffff">column/row filtering, and omitted.json.</text>
</g>
<!-- mod_query -->
<g id="node3" class="node">
<title>mod_query</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1980.04,-576.06 1650,-576.06 1650,-396.06 1980.04,-396.06 1980.04,-576.06"/>
<text xml:space="preserve" text-anchor="start" x="1695.54" y="-516.86" font-family="Arial" font-size="20.00" fill="#ffffff">In&#45;Memory Query &amp; Slicing</text>
<text xml:space="preserve" text-anchor="start" x="1785.76" y="-495.86" font-family="Arial" font-size="13.00" fill="#ffffff">R/query.R</text>
<text xml:space="preserve" text-anchor="start" x="1730.38" y="-474.26" font-family="Arial" font-size="15.00" fill="#ffffff">Read&#45;only inspection and</text>
<text xml:space="preserve" text-anchor="start" x="1696.62" y="-456.26" font-family="Arial" font-size="15.00" fill="#ffffff">panel/leaf/spatial&#45;box/row slicing on</text>
<text xml:space="preserve" text-anchor="start" x="1740.39" y="-438.26" font-family="Arial" font-size="15.00" fill="#ffffff">gloss_capture objects.</text>
</g>
<!-- mod_registry -->
<g id="node4" class="node">
<title>mod_registry</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="2294.04,-228 1964,-228 1964,-48 2294.04,-48 2294.04,-228"/>
<text xml:space="preserve" text-anchor="start" x="1997.83" y="-177.8" font-family="Arial" font-size="20.00" fill="#ffffff">Engine Registry &amp; Load Hook</text>
<text xml:space="preserve" text-anchor="start" x="2046.67" y="-156.8" font-family="Arial" font-size="13.00" fill="#ffffff">R/engine&#45;registry.R, R/zzz.R</text>
<text xml:space="preserve" text-anchor="start" x="2003.13" y="-135.2" font-family="Arial" font-size="15.00" fill="#ffffff">Private package environment registry,</text>
<text xml:space="preserve" text-anchor="start" x="2014.81" y="-117.2" font-family="Arial" font-size="15.00" fill="#ffffff">class&#45;hierarchy &amp; priority dispatch,</text>
<text xml:space="preserve" text-anchor="start" x="2005.18" y="-99.2" font-family="Arial" font-size="15.00" fill="#ffffff">page_kind candidate disambiguation,</text>
<text xml:space="preserve" text-anchor="start" x="2040.22" y="-81.2" font-family="Arial" font-size="15.00" fill="#ffffff">and lazy Suggests checks.</text>
</g>
<!-- mod_sources -->
<g id="node5" class="node">
<title>mod_sources</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="2714.04,-228 2384,-228 2384,-48 2714.04,-48 2714.04,-228"/>
<text xml:space="preserve" text-anchor="start" x="2436.18" y="-177.8" font-family="Arial" font-size="20.00" fill="#ffffff">Source Context Inventory</text>
<text xml:space="preserve" text-anchor="start" x="2513.26" y="-156.8" font-family="Arial" font-size="13.00" fill="#ffffff">R/sources.R</text>
<text xml:space="preserve" text-anchor="start" x="2444.39" y="-135.2" font-family="Arial" font-size="15.00" fill="#ffffff">Collects explicit files/docs/inline</text>
<text xml:space="preserve" text-anchor="start" x="2456.88" y="-117.2" font-family="Arial" font-size="15.00" fill="#ffffff">snippets, runtime_observed</text>
<text xml:space="preserve" text-anchor="start" x="2433.11" y="-99.2" font-family="Arial" font-size="15.00" fill="#ffffff">session/package/git metadata, and</text>
<text xml:space="preserve" text-anchor="start" x="2438.14" y="-81.2" font-family="Arial" font-size="15.00" fill="#ffffff">knitr/Rscript sniffed_hint pointers.</text>
</g>
<!-- mod_utils -->
<g id="node6" class="node">
<title>mod_utils</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1676.04,-228 1346,-228 1346,-48 1676.04,-48 1676.04,-228"/>
<text xml:space="preserve" text-anchor="start" x="1379.29" y="-177.8" font-family="Arial" font-size="20.00" fill="#ffffff">Contract &amp; Open Serialization</text>
<text xml:space="preserve" text-anchor="start" x="1486.46" y="-156.8" font-family="Arial" font-size="13.00" fill="#ffffff">R/utils.R</text>
<text xml:space="preserve" text-anchor="start" x="1378.04" y="-135.2" font-family="Arial" font-size="15.00" fill="#ffffff">gloss_capture S3 contract, deterministic</text>
<text xml:space="preserve" text-anchor="start" x="1389.3" y="-117.2" font-family="Arial" font-size="15.00" fill="#ffffff">capture_id, SHA&#45;256 helpers, UTF&#45;8</text>
<text xml:space="preserve" text-anchor="start" x="1404.74" y="-99.2" font-family="Arial" font-size="15.00" fill="#ffffff">JSON/CSV writers with 1&#45;based</text>
<text xml:space="preserve" text-anchor="start" x="1378.45" y="-81.2" font-family="Arial" font-size="15.00" fill="#ffffff">_row_id, and column schema inference.</text>
</g>
<!-- mod_ir_lineage -->
<g id="node7" class="node">
<title>mod_ir_lineage</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1140.04,-584.08 810,-584.08 810,-388.03 1140.04,-388.03 1140.04,-584.08"/>
<text xml:space="preserve" text-anchor="start" x="921.66" y="-546.86" font-family="Arial" font-size="20.00" fill="#ffffff">Engine IR &amp;</text>
<text xml:space="preserve" text-anchor="start" x="893.86" y="-522.86" font-family="Arial" font-size="20.00" fill="#ffffff">Structural Lineage</text>
<text xml:space="preserve" text-anchor="start" x="935.28" y="-501.86" font-family="Arial" font-size="13.00" fill="#ffffff">R/ir&#45;lineage.R</text>
<text xml:space="preserve" text-anchor="start" x="847.45" y="-480.26" font-family="Arial" font-size="15.00" fill="#ffffff">Normalizes panel coordinate domains,</text>
<text xml:space="preserve" text-anchor="start" x="848.71" y="-462.26" font-family="Arial" font-size="15.00" fill="#ffffff">scale/palette dictionaries, layer specs,</text>
<text xml:space="preserve" text-anchor="start" x="881.21" y="-444.26" font-family="Arial" font-size="15.00" fill="#ffffff">and neutral element&#45;to&#45;table</text>
<text xml:space="preserve" text-anchor="start" x="885.82" y="-426.26" font-family="Arial" font-size="15.00" fill="#ffffff">cardinalities (1:1, N:1, 1:M,</text>
<text xml:space="preserve" text-anchor="start" x="916.23" y="-408.26" font-family="Arial" font-size="15.00" fill="#ffffff">stat_aggregated).</text>
</g>
<!-- eng_grid -->
<g id="node8" class="node">
<title>eng_grid</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="645.04,-1204.28 315,-1204.28 315,-1024.28 645.04,-1024.28 645.04,-1204.28"/>
<text xml:space="preserve" text-anchor="start" x="429.43" y="-1145.08" font-family="Arial" font-size="20.00" fill="#ffffff">grid Engine</text>
<text xml:space="preserve" text-anchor="start" x="417.52" y="-1124.08" font-family="Arial" font-size="13.00" fill="#ffffff">R/engine&#45;grid.R (grid)</text>
<text xml:space="preserve" text-anchor="start" x="346.63" y="-1102.48" font-family="Arial" font-size="15.00" fill="#ffffff">Captures raw grid grobs, gLists, gTrees,</text>
<text xml:space="preserve" text-anchor="start" x="362.03" y="-1084.48" font-family="Arial" font-size="15.00" fill="#ffffff">gtables, grid drawing functions, and</text>
<text xml:space="preserve" text-anchor="start" x="415.82" y="-1066.48" font-family="Arial" font-size="15.00" fill="#ffffff">recorded grid plots.</text>
</g>
<!-- eng_ggplot -->
<g id="node9" class="node">
<title>eng_ggplot</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1065.04,-1204.28 735,-1204.28 735,-1024.28 1065.04,-1024.28 1065.04,-1204.28"/>
<text xml:space="preserve" text-anchor="start" x="833.3" y="-1163.08" font-family="Arial" font-size="20.00" fill="#ffffff">ggplot2 Engine</text>
<text xml:space="preserve" text-anchor="start" x="789.45" y="-1142.08" font-family="Arial" font-size="13.00" fill="#ffffff">R/engine&#45;ggplot.R (Suggests: ggplot2)</text>
<text xml:space="preserve" text-anchor="start" x="809.33" y="-1120.48" font-family="Arial" font-size="15.00" fill="#ffffff">Single&#45;build ggplot_build &#45;&gt;</text>
<text xml:space="preserve" text-anchor="start" x="778.49" y="-1102.48" font-family="Arial" font-size="15.00" fill="#ffffff">ggplot_gtable &#45;&gt; grid.draw extracting</text>
<text xml:space="preserve" text-anchor="start" x="781.21" y="-1084.48" font-family="Arial" font-size="15.00" fill="#ffffff">raw/built tables, scale/palette maps,</text>
<text xml:space="preserve" text-anchor="start" x="791.63" y="-1066.48" font-family="Arial" font-size="15.00" fill="#ffffff">layer recipes, facets, and neutral</text>
<text xml:space="preserve" text-anchor="start" x="873.75" y="-1048.48" font-family="Arial" font-size="15.00" fill="#ffffff">lineage.</text>
</g>
<!-- eng_patchwork -->
<g id="node10" class="node">
<title>eng_patchwork</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1575.04,-1204.28 1245,-1204.28 1245,-1024.28 1575.04,-1024.28 1575.04,-1204.28"/>
<text xml:space="preserve" text-anchor="start" x="1330.53" y="-1154.08" font-family="Arial" font-size="20.00" fill="#ffffff">patchwork Engine</text>
<text xml:space="preserve" text-anchor="start" x="1279.24" y="-1133.08" font-family="Arial" font-size="13.00" fill="#ffffff">R/engine&#45;patchwork.R (Suggests: patchwork)</text>
<text xml:space="preserve" text-anchor="start" x="1282.06" y="-1111.48" font-family="Arial" font-size="15.00" fill="#ffffff">Composite multi&#45;plot IR extraction with</text>
<text xml:space="preserve" text-anchor="start" x="1319.12" y="-1093.48" font-family="Arial" font-size="15.00" fill="#ffffff">per&#45;subplot panel and table</text>
<text xml:space="preserve" text-anchor="start" x="1288.69" y="-1075.48" font-family="Arial" font-size="15.00" fill="#ffffff">namespaces without double&#45;building</text>
<text xml:space="preserve" text-anchor="start" x="1344.57" y="-1057.48" font-family="Arial" font-size="15.00" fill="#ffffff">stochastic subplots.</text>
</g>
<!-- eng_heatmap -->
<g id="node11" class="node">
<title>eng_heatmap</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="645.04,-913.28 315,-913.28 315,-733.28 645.04,-733.28 645.04,-913.28"/>
<text xml:space="preserve" text-anchor="start" x="366.07" y="-872.08" font-family="Arial" font-size="20.00" fill="#ffffff">ComplexHeatmap Engine</text>
<text xml:space="preserve" text-anchor="start" x="387.16" y="-851.08" font-family="Arial" font-size="13.00" fill="#ffffff">R/engine&#45;heatmap.R (Suggests:</text>
<text xml:space="preserve" text-anchor="start" x="350.8" y="-829.48" font-family="Arial" font-size="15.00" fill="#ffffff">Single draw() capture preserving draw&#45;</text>
<text xml:space="preserve" text-anchor="start" x="386.23" y="-811.48" font-family="Arial" font-size="15.00" fill="#ffffff">time clustering permutations</text>
<text xml:space="preserve" text-anchor="start" x="353.72" y="-793.48" font-family="Arial" font-size="15.00" fill="#ffffff">(row_order/column_order) in ir.orders,</text>
<text xml:space="preserve" text-anchor="start" x="365.37" y="-775.48" font-family="Arial" font-size="15.00" fill="#ffffff">matrix/annotation tables, and color</text>
<text xml:space="preserve" text-anchor="start" x="459.6" y="-757.48" font-family="Arial" font-size="15.00" fill="#ffffff">maps.</text>
</g>
<!-- eng_base -->
<g id="node12" class="node">
<title>eng_base</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1140.04,-913.28 810,-913.28 810,-733.28 1140.04,-733.28 1140.04,-913.28"/>
<text xml:space="preserve" text-anchor="start" x="876.63" y="-863.08" font-family="Arial" font-size="20.00" fill="#ffffff">base Graphics Engine</text>
<text xml:space="preserve" text-anchor="start" x="864.83" y="-842.08" font-family="Arial" font-size="13.00" fill="#ffffff">R/engine&#45;base.R (grDevices/graphics)</text>
<text xml:space="preserve" text-anchor="start" x="862.47" y="-820.48" font-family="Arial" font-size="15.00" fill="#ffffff">Step&#45;by&#45;step display&#45;list replay on</text>
<text xml:space="preserve" text-anchor="start" x="856.88" y="-802.48" font-family="Arial" font-size="15.00" fill="#ffffff">svglite isolating per&#45;call &lt;g id=&#39;L...&#39;&gt;</text>
<text xml:space="preserve" text-anchor="start" x="864.66" y="-784.48" font-family="Arial" font-size="15.00" fill="#ffffff">leaves and par(&#39;usr&#39;)/par(&#39;plt&#39;) plot</text>
<text xml:space="preserve" text-anchor="start" x="948.34" y="-766.48" font-family="Arial" font-size="15.00" fill="#ffffff">regions.</text>
</g>
<!-- public_api -->
<g id="node13" class="node">
<title>public_api</title>
<polygon fill="#64748b" stroke="#475569" stroke-width="0" points="1975.04,-913.28 1655,-913.28 1655,-733.28 1975.04,-733.28 1975.04,-913.28"/>
<text xml:space="preserve" text-anchor="start" x="1679.97" y="-835.28" font-family="Arial" font-size="20.00" fill="#f8fafc">Public API Surface (8 Exports)</text>
<text xml:space="preserve" text-anchor="start" x="1679.54" y="-812.28" font-family="Arial" font-size="15.00" fill="#cbd5e1">The minimal, stable exported interface of</text>
<text xml:space="preserve" text-anchor="start" x="1795.43" y="-794.28" font-family="Arial" font-size="15.00" fill="#cbd5e1">gloss.</text>
</g>
<!-- asset_map -->
<g id="node14" class="node">
<title>asset_map</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="730.04,-228 410,-228 410,-48 730.04,-48 730.04,-228"/>
<text xml:space="preserve" text-anchor="start" x="445.53" y="-177.8" font-family="Arial" font-size="20.00" fill="#ffffff">Asset Map (asset&#45;map.json)</text>
<text xml:space="preserve" text-anchor="start" x="512.76" y="-156.8" font-family="Arial" font-size="13.00" fill="#ffffff">JSON (~tens of KB)</text>
<text xml:space="preserve" text-anchor="start" x="456.6" y="-135.2" font-family="Arial" font-size="15.00" fill="#ffffff">Lightweight global catalog of page</text>
<text xml:space="preserve" text-anchor="start" x="427.03" y="-117.2" font-family="Arial" font-size="15.00" fill="#ffffff">geometry, SVG digests, Engine IR (panels,</text>
<text xml:space="preserve" text-anchor="start" x="449.97" y="-99.2" font-family="Arial" font-size="15.00" fill="#ffffff">layers, scales, orders), table column</text>
<text xml:space="preserve" text-anchor="start" x="432.87" y="-81.2" font-family="Arial" font-size="15.00" fill="#ffffff">summaries, lineage, and source pointers.</text>
</g>
<!-- asset_bundle -->
<g id="node15" class="node">
<title>asset_bundle</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="320.04,-236.03 0,-236.03 0,-39.97 320.04,-39.97 320.04,-236.03"/>
<text xml:space="preserve" text-anchor="start" x="101.09" y="-198.8" font-family="Arial" font-size="20.00" fill="#ffffff">Asset Bundle</text>
<text xml:space="preserve" text-anchor="start" x="69.43" y="-174.8" font-family="Arial" font-size="20.00" fill="#ffffff">(figure.gloss/ or .zip)</text>
<text xml:space="preserve" text-anchor="start" x="59.06" y="-153.8" font-family="Arial" font-size="13.00" fill="#ffffff">UTF&#45;8 SVG + JSON + CSV + PNG</text>
<text xml:space="preserve" text-anchor="start" x="56.2" y="-132.2" font-family="Arial" font-size="15.00" fill="#ffffff">Self&#45;contained portable bundle:</text>
<text xml:space="preserve" text-anchor="start" x="58.73" y="-114.2" font-family="Arial" font-size="15.00" fill="#ffffff">manifest.json, asset&#45;map.json,</text>
<text xml:space="preserve" text-anchor="start" x="51.64" y="-96.2" font-family="Arial" font-size="15.00" fill="#ffffff">omitted.json, assets/original.svg,</text>
<text xml:space="preserve" text-anchor="start" x="17.86" y="-78.2" font-family="Arial" font-size="15.00" fill="#ffffff">scene/{scene.svg,leaves.json,elements.jso</text>
<text xml:space="preserve" text-anchor="start" x="32.46" y="-60.2" font-family="Arial" font-size="15.00" fill="#ffffff">n,rasters/}, tables/{schema.json,*.csv},</text>
</g>
<!-- mod_capture&#45;&gt;mod_registry -->
<g id="edge6" class="edge">
<title>mod_capture&#45;&gt;mod_registry</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M2186.97,-388.26C2179.19,-370.2 2171.81,-351.26 2166.02,-333.03 2156.42,-302.78 2148.93,-269.05 2143.27,-238.3"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="2145.87,-237.9 2141.96,-230.98 2140.7,-238.82 2145.87,-237.9"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="2166.02,-299.53 2166.02,-324.53 2383.02,-324.53 2383.02,-299.53 2166.02,-299.53"/>
<text xml:space="preserve" text-anchor="start" x="2166.02" y="-310.53" font-family="Arial" font-size="14.00" fill="#c9c9c9">Dispatches by class &amp; page_kind</text>
</g>
<!-- mod_capture&#45;&gt;mod_sources -->
<g id="edge7" class="edge">
<title>mod_capture&#45;&gt;mod_sources</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M2346.17,-388.35C2365.04,-370.52 2384.02,-351.63 2401.02,-333.03 2428.69,-302.76 2456.59,-267.64 2480.6,-235.66"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="2482.42,-237.61 2484.8,-230.03 2478.21,-234.47 2482.42,-237.61"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="2435.96,-299.53 2435.96,-324.53 2654.96,-324.53 2654.96,-299.53 2435.96,-299.53"/>
<text xml:space="preserve" text-anchor="start" x="2435.96" y="-310.53" font-family="Arial" font-size="14.00" fill="#c9c9c9">Snapshots provenance &amp; session</text>
</g>
<!-- mod_capture&#45;&gt;mod_utils -->
<g id="edge9" class="edge">
<title>mod_capture&#45;&gt;mod_utils</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M2070.28,-406.31C1955.41,-351.41 1802.38,-278.26 1685.44,-222.37"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="1686.65,-220.04 1678.75,-219.17 1684.38,-224.77 1686.65,-220.04"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1916.37,-299.53 1916.37,-324.53 2120.37,-324.53 2120.37,-299.53 1916.37,-299.53"/>
<text xml:space="preserve" text-anchor="start" x="1916.37" y="-310.53" font-family="Arial" font-size="14.00" fill="#c9c9c9">Builds validated gloss_capture</text>
</g>
<!-- mod_capture&#45;&gt;eng_grid -->
<g id="edge8" class="edge">
<title>mod_capture&#45;&gt;eng_grid</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M2274.24,-583.91C2281.21,-614.93 2282.75,-648.85 2270.02,-678.28 2209.49,-818.25 2159.33,-851.26 2020.02,-913.28 1867.55,-981.17 1741.18,-1008.38 1625.47,-1015.6"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="1625.38,-1012.98 1618.04,-1016.03 1625.68,-1018.22 1625.38,-1012.98"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1818.99,-923.31 1818.99,-948.31 1996.99,-948.31 1996.99,-923.31 1818.99,-923.31"/>
<text xml:space="preserve" text-anchor="start" x="1818.99" y="-934.31" font-family="Arial" font-size="14.00" fill="#c9c9c9">Invokes engine capture_fn</text>
</g>
<!-- mod_package_assets&#45;&gt;mod_utils -->
<g id="edge12" class="edge">
<title>mod_package_assets&#45;&gt;mod_utils</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M1371.15,-396.38C1366.14,-362.51 1365.59,-324.11 1378.02,-291.03 1385.33,-271.56 1396.39,-252.96 1409.07,-235.86"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="1411.09,-237.54 1413.58,-229.99 1406.93,-234.34 1411.09,-237.54"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1378.02,-291.03 1378.02,-333.03 1516.02,-333.03 1516.02,-291.03 1378.02,-291.03"/>
<text xml:space="preserve" text-anchor="start" x="1378.02" y="-319.03" font-family="Arial" font-size="14.00" fill="#c9c9c9">Writes UTF&#45;8 JSON,</text>
<text xml:space="preserve" text-anchor="start" x="1378.02" y="-302.23" font-family="Arial" font-size="14.00" fill="#c9c9c9">CSV &amp; SHA&#45;256</text>
</g>
<!-- mod_package_assets&#45;&gt;asset_map -->
<g id="edge10" class="edge">
<title>mod_package_assets&#45;&gt;asset_map</title>
<path fill="none" stroke="#026395" stroke-width="2" d="M1230.04,-406.99C1214.9,-400.38 1199.73,-393.97 1185.02,-388.03 994.34,-311.03 936.04,-319.3 748.02,-236.03 745.14,-234.75 742.24,-233.44 739.32,-232.11"/>
<polygon fill="#026395" stroke="#026395" stroke-width="2" points="740.65,-229.83 732.74,-229.05 738.43,-234.59 740.65,-229.83"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1026.14,-299.53 1026.14,-324.53 1136.14,-324.53 1136.14,-299.53 1026.14,-299.53"/>
<text xml:space="preserve" text-anchor="start" x="1026.14" y="-310.53" font-family="Arial" font-size="14.00" fill="#ddffff">gl_asset_map()</text>
</g>
<!-- mod_package_assets&#45;&gt;asset_bundle -->
<g id="edge11" class="edge">
<title>mod_package_assets&#45;&gt;asset_bundle</title>
<path fill="none" stroke="#026395" stroke-width="2" d="M1230.04,-403.14C1215.03,-397.43 1199.89,-392.27 1185.02,-388.03 993.81,-333.45 936.36,-370.16 741.02,-333.03 571.47,-300.8 527.3,-294.76 365.02,-236.03 353.33,-231.8 341.41,-227.14 329.49,-222.21"/>
<polygon fill="#026395" stroke="#026395" stroke-width="2" points="330.66,-219.86 322.73,-219.38 328.64,-224.7 330.66,-219.86"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="741.02,-299.53 741.02,-324.53 867.02,-324.53 867.02,-299.53 741.02,-299.53"/>
<text xml:space="preserve" text-anchor="start" x="741.02" y="-310.53" font-family="Arial" font-size="14.00" fill="#ddffff">gl_asset_bundle()</text>
</g>
<!-- mod_query&#45;&gt;mod_utils -->
<g id="edge13" class="edge">
<title>mod_query&#45;&gt;mod_utils</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M1677.45,-396.16C1653.59,-377.09 1630.3,-355.77 1611.02,-333.03 1586.94,-304.62 1566.62,-269.44 1550.71,-236.86"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="1553.26,-236.11 1547.65,-230.48 1548.52,-238.38 1553.26,-236.11"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1611.02,-299.53 1611.02,-324.53 1772.02,-324.53 1772.02,-299.53 1611.02,-299.53"/>
<text xml:space="preserve" text-anchor="start" x="1611.02" y="-310.53" font-family="Arial" font-size="14.00" fill="#c9c9c9">Validates gloss_capture</text>
</g>
<!-- eng_grid&#45;&gt;eng_heatmap -->
<!-- eng_ggplot&#45;&gt;eng_patchwork -->
<!-- eng_base&#45;&gt;mod_ir_lineage -->
<g id="edge15" class="edge">
<title>eng_base&#45;&gt;mod_ir_lineage</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M975.02,-693.29C975.02,-660.53 975.02,-625.69 975.02,-594.15"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="977.65,-594.32 975.02,-586.82 972.4,-594.32 977.65,-594.32"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="975.02,-638.55 975.02,-663.55 1138.02,-663.55 1138.02,-638.55 975.02,-638.55"/>
<text xml:space="preserve" text-anchor="start" x="975.02" y="-649.55" font-family="Arial" font-size="14.00" fill="#c9c9c9">Normalizes IR &amp; lineage</text>
</g>
<!-- public_api&#45;&gt;mod_capture -->
<g id="edge2" class="edge">
<title>public_api&#45;&gt;mod_capture</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M1926.47,-733.33C1981.59,-689.33 2048.44,-635.98 2105.79,-590.2"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="2107.23,-592.41 2111.46,-585.68 2103.96,-588.31 2107.23,-592.41"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="2025.02,-653.28 2025.02,-678.28 2248.02,-678.28 2248.02,-653.28 2025.02,-653.28"/>
<text xml:space="preserve" text-anchor="start" x="2025.02" y="-664.28" font-family="Arial" font-size="14.00" fill="#c9c9c9">Orchestrates single&#45;draw capture</text>
</g>
<!-- public_api&#45;&gt;mod_package_assets -->
<g id="edge3" class="edge">
<title>public_api&#45;&gt;mod_package_assets</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M1703.57,-733.33C1645.19,-686.73 1573.68,-629.65 1514.2,-582.18"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="1516.13,-580.36 1508.63,-577.73 1512.85,-584.46 1516.13,-580.36"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1630.17,-653.28 1630.17,-678.28 1663.17,-678.28 1663.17,-653.28 1630.17,-653.28"/>
<text xml:space="preserve" text-anchor="start" x="1630.17" y="-664.28" font-family="Arial" font-size="14.00" fill="#c9c9c9">[...]</text>
</g>
<!-- public_api&#45;&gt;mod_query -->
<g id="edge4" class="edge">
<title>public_api&#45;&gt;mod_query</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M1815.02,-733.33C1815.02,-688.07 1815.02,-632.91 1815.02,-586.27"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="1817.65,-586.37 1815.02,-578.87 1812.4,-586.37 1817.65,-586.37"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1815.02,-653.28 1815.02,-678.28 1848.02,-678.28 1848.02,-653.28 1815.02,-653.28"/>
<text xml:space="preserve" text-anchor="start" x="1815.02" y="-664.28" font-family="Arial" font-size="14.00" fill="#c9c9c9">[...]</text>
</g>
<!-- public_api&#45;&gt;mod_registry -->
<g id="edge5" class="edge">
<title>public_api&#45;&gt;mod_registry</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M1974.71,-806.47C2109.91,-786.65 2303.71,-742.55 2445.02,-645.28 2587.44,-547.26 2622.72,-497.17 2677.02,-333.03 2682.88,-315.31 2689.11,-305.25 2677.02,-291.03 2627.72,-233.06 2411.79,-258.3 2339.02,-236.03 2327.28,-232.43 2315.35,-228.31 2303.43,-223.84"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="2304.66,-221.5 2296.72,-221.27 2302.78,-226.41 2304.66,-221.5"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="2657.73,-473.56 2657.73,-498.56 2806.73,-498.56 2806.73,-473.56 2657.73,-473.56"/>
<text xml:space="preserve" text-anchor="start" x="2657.73" y="-484.56" font-family="Arial" font-size="14.00" fill="#c9c9c9">Registers engine spec</text>
</g>
</g>
</svg>
`;case`public_api_surface`:return`<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
 "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<!-- Generated by graphviz version 16.1.0 (0)
 -->
<!-- Pages: 1 -->
<svg width="2375pt" height="2030pt"
 viewBox="0.00 0.00 2375.00 2030.00" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<g id="graph0" class="graph" transform="scale(1 1) rotate(0) translate(15.05 2015.05)">
<!-- user -->
<g id="node1" class="node">
<title>user</title>
<polygon fill="#64748b" stroke="#475569" stroke-width="0" points="320.04,-440 0,-440 0,-260 320.04,-260 320.04,-440"/>
<text xml:space="preserve" text-anchor="start" x="36.06" y="-380" font-family="Arial" font-size="20.00" fill="#f8fafc">R Analyst / AI Coding Agent</text>
<text xml:space="preserve" text-anchor="start" x="18.29" y="-357" font-family="Arial" font-size="15.00" fill="#cbd5e1">Authors R figures in an active R session or</text>
<text xml:space="preserve" text-anchor="start" x="20.37" y="-339" font-family="Arial" font-size="15.00" fill="#cbd5e1">consumes portable .gloss assets for Q&amp;A,</text>
<text xml:space="preserve" text-anchor="start" x="19.11" y="-321" font-family="Arial" font-size="15.00" fill="#cbd5e1">publication SVG refinement, and statistical</text>
<text xml:space="preserve" text-anchor="start" x="131.66" y="-303" font-family="Arial" font-size="15.00" fill="#cbd5e1">auditing.</text>
</g>
<!-- fn_gloss -->
<g id="node2" class="node">
<title>fn_gloss</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="980.08,-420 660.04,-420 660.04,-240 980.08,-240 980.08,-420"/>
<text xml:space="preserve" text-anchor="start" x="790.06" y="-360" font-family="Arial" font-size="20.00" fill="#ffffff">gloss()</text>
<text xml:space="preserve" text-anchor="start" x="677.08" y="-337" font-family="Arial" font-size="15.00" fill="#ffffff">Draw once on svglite, instrument dual SVG</text>
<text xml:space="preserve" text-anchor="start" x="696.88" y="-319" font-family="Arial" font-size="15.00" fill="#ffffff">+ viewport probes, extract Engine IR,</text>
<text xml:space="preserve" text-anchor="start" x="681.64" y="-301" font-family="Arial" font-size="15.00" fill="#ffffff">lineage, and sources into a gloss_capture</text>
<text xml:space="preserve" text-anchor="start" x="797.97" y="-283" font-family="Arial" font-size="15.00" fill="#ffffff">object.</text>
</g>
<!-- fn_register_engine -->
<g id="node3" class="node">
<title>fn_register_engine</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="320.04,-180 0,-180 0,0 320.04,0 320.04,-180"/>
<text xml:space="preserve" text-anchor="start" x="71.08" y="-102" font-family="Arial" font-size="20.00" fill="#ffffff">gl_register_engine()</text>
<text xml:space="preserve" text-anchor="start" x="37.05" y="-79" font-family="Arial" font-size="15.00" fill="#ffffff">Register built&#45;in or third&#45;party plotting</text>
<text xml:space="preserve" text-anchor="start" x="30.77" y="-61" font-family="Arial" font-size="15.00" fill="#ffffff">engines by S3/S4 class and page kind.</text>
</g>
<!-- mod_registry -->
<g id="node4" class="node">
<title>mod_registry</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="2345.18,-409 2015.14,-409 2015.14,-229 2345.18,-229 2345.18,-409"/>
<text xml:space="preserve" text-anchor="start" x="2048.97" y="-358.8" font-family="Arial" font-size="20.00" fill="#ffffff">Engine Registry &amp; Load Hook</text>
<text xml:space="preserve" text-anchor="start" x="2097.81" y="-337.8" font-family="Arial" font-size="13.00" fill="#ffffff">R/engine&#45;registry.R, R/zzz.R</text>
<text xml:space="preserve" text-anchor="start" x="2054.27" y="-316.2" font-family="Arial" font-size="15.00" fill="#ffffff">Private package environment registry,</text>
<text xml:space="preserve" text-anchor="start" x="2065.95" y="-298.2" font-family="Arial" font-size="15.00" fill="#ffffff">class&#45;hierarchy &amp; priority dispatch,</text>
<text xml:space="preserve" text-anchor="start" x="2056.32" y="-280.2" font-family="Arial" font-size="15.00" fill="#ffffff">page_kind candidate disambiguation,</text>
<text xml:space="preserve" text-anchor="start" x="2091.36" y="-262.2" font-family="Arial" font-size="15.00" fill="#ffffff">and lazy Suggests checks.</text>
</g>
<!-- fn_asset_map -->
<g id="node5" class="node">
<title>fn_asset_map</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="320.04,-960 0,-960 0,-780 320.04,-780 320.04,-960"/>
<text xml:space="preserve" text-anchor="start" x="91.1" y="-891" font-family="Arial" font-size="20.00" fill="#ffffff">gl_asset_map()</text>
<text xml:space="preserve" text-anchor="start" x="27.88" y="-868" font-family="Arial" font-size="15.00" fill="#ffffff">Serialize compact asset&#45;map.json index</text>
<text xml:space="preserve" text-anchor="start" x="22.46" y="-850" font-family="Arial" font-size="15.00" fill="#ffffff">from an in&#45;memory gloss_capture without</text>
<text xml:space="preserve" text-anchor="start" x="125" y="-832" font-family="Arial" font-size="15.00" fill="#ffffff">redrawing.</text>
</g>
<!-- mod_package_assets -->
<g id="node6" class="node">
<title>mod_package_assets</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="985.09,-830 655.04,-830 655.04,-650 985.09,-650 985.09,-830"/>
<text xml:space="preserve" text-anchor="start" x="684.43" y="-779.8" font-family="Arial" font-size="20.00" fill="#ffffff">Asset Map &amp; Bundle Packager</text>
<text xml:space="preserve" text-anchor="start" x="761.54" y="-758.8" font-family="Arial" font-size="13.00" fill="#ffffff">R/package&#45;assets.R</text>
<text xml:space="preserve" text-anchor="start" x="697.92" y="-737.2" font-family="Arial" font-size="15.00" fill="#ffffff">Layered open&#45;format serialization for</text>
<text xml:space="preserve" text-anchor="start" x="708.76" y="-719.2" font-family="Arial" font-size="15.00" fill="#ffffff">asset&#45;map.json and .gloss/ dir/zip</text>
<text xml:space="preserve" text-anchor="start" x="697.5" y="-701.2" font-family="Arial" font-size="15.00" fill="#ffffff">bundles with SHA&#45;256 manifest.json,</text>
<text xml:space="preserve" text-anchor="start" x="694.17" y="-683.2" font-family="Arial" font-size="15.00" fill="#ffffff">column/row filtering, and omitted.json.</text>
</g>
<!-- fn_asset_bundle -->
<g id="node7" class="node">
<title>fn_asset_bundle</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="320.04,-700 0,-700 0,-520 320.04,-520 320.04,-700"/>
<text xml:space="preserve" text-anchor="start" x="80.52" y="-631" font-family="Arial" font-size="20.00" fill="#ffffff">gl_asset_bundle()</text>
<text xml:space="preserve" text-anchor="start" x="24.54" y="-608" font-family="Arial" font-size="15.00" fill="#ffffff">Package portable .gloss/ directory or .zip</text>
<text xml:space="preserve" text-anchor="start" x="29.12" y="-590" font-family="Arial" font-size="15.00" fill="#ffffff">bundle with manifest.json, omitted.json,</text>
<text xml:space="preserve" text-anchor="start" x="39.12" y="-572" font-family="Arial" font-size="15.00" fill="#ffffff">dual SVG, CSV tables, and sources.</text>
</g>
<!-- fn_scene -->
<g id="node8" class="node">
<title>fn_scene</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="320.04,-2000 0,-2000 0,-1820 320.04,-1820 320.04,-2000"/>
<text xml:space="preserve" text-anchor="start" x="113.33" y="-1931" font-family="Arial" font-size="20.00" fill="#ffffff">gl_scene()</text>
<text xml:space="preserve" text-anchor="start" x="34.1" y="-1908" font-family="Arial" font-size="15.00" fill="#ffffff">Inspect captured page metadata, dual</text>
<text xml:space="preserve" text-anchor="start" x="42.89" y="-1890" font-family="Arial" font-size="15.00" fill="#ffffff">SVG descriptors, leaves, elements,</text>
<text xml:space="preserve" text-anchor="start" x="57.06" y="-1872" font-family="Arial" font-size="15.00" fill="#ffffff">rasters, and panels in memory.</text>
</g>
<!-- mod_query -->
<g id="node9" class="node">
<title>mod_query</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="985.09,-1610 655.04,-1610 655.04,-1430 985.09,-1430 985.09,-1610"/>
<text xml:space="preserve" text-anchor="start" x="700.59" y="-1550.8" font-family="Arial" font-size="20.00" fill="#ffffff">In&#45;Memory Query &amp; Slicing</text>
<text xml:space="preserve" text-anchor="start" x="790.8" y="-1529.8" font-family="Arial" font-size="13.00" fill="#ffffff">R/query.R</text>
<text xml:space="preserve" text-anchor="start" x="735.43" y="-1508.2" font-family="Arial" font-size="15.00" fill="#ffffff">Read&#45;only inspection and</text>
<text xml:space="preserve" text-anchor="start" x="701.66" y="-1490.2" font-family="Arial" font-size="15.00" fill="#ffffff">panel/leaf/spatial&#45;box/row slicing on</text>
<text xml:space="preserve" text-anchor="start" x="745.44" y="-1472.2" font-family="Arial" font-size="15.00" fill="#ffffff">gloss_capture objects.</text>
</g>
<!-- fn_tables -->
<g id="node10" class="node">
<title>fn_tables</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="320.04,-1740 0,-1740 0,-1560 320.04,-1560 320.04,-1740"/>
<text xml:space="preserve" text-anchor="start" x="113.33" y="-1662" font-family="Arial" font-size="20.00" fill="#ffffff">gl_tables()</text>
<text xml:space="preserve" text-anchor="start" x="24.53" y="-1639" font-family="Arial" font-size="15.00" fill="#ffffff">Access raw and engine&#45;built data frames</text>
<text xml:space="preserve" text-anchor="start" x="46.23" y="-1621" font-family="Arial" font-size="15.00" fill="#ffffff">from an in&#45;memory gloss_capture.</text>
</g>
<!-- fn_sources -->
<g id="node11" class="node">
<title>fn_sources</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="320.04,-1480 0,-1480 0,-1300 320.04,-1300 320.04,-1480"/>
<text xml:space="preserve" text-anchor="start" x="105" y="-1402" font-family="Arial" font-size="20.00" fill="#ffffff">gl_sources()</text>
<text xml:space="preserve" text-anchor="start" x="29.95" y="-1379" font-family="Arial" font-size="15.00" fill="#ffffff">Inspect explicit, runtime_observed, and</text>
<text xml:space="preserve" text-anchor="start" x="44.12" y="-1361" font-family="Arial" font-size="15.00" fill="#ffffff">sniffed_hint source inventory table.</text>
</g>
<!-- fn_query -->
<g id="node12" class="node">
<title>fn_query</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="320.04,-1220 0,-1220 0,-1040 320.04,-1040 320.04,-1220"/>
<text xml:space="preserve" text-anchor="start" x="115" y="-1151" font-family="Arial" font-size="20.00" fill="#ffffff">gl_query()</text>
<text xml:space="preserve" text-anchor="start" x="38.72" y="-1128" font-family="Arial" font-size="15.00" fill="#ffffff">Composable structural, spatial (SVG</text>
<text xml:space="preserve" text-anchor="start" x="39.12" y="-1110" font-family="Arial" font-size="15.00" fill="#ffffff">bbox), and tabular slicing over an in&#45;</text>
<text xml:space="preserve" text-anchor="start" x="82.07" y="-1092" font-family="Arial" font-size="15.00" fill="#ffffff">memory gloss_capture.</text>
</g>
<!-- mod_capture -->
<g id="node13" class="node">
<title>mod_capture</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1668.14,-417.03 1338.09,-417.03 1338.09,-220.97 1668.14,-220.97 1668.14,-417.03"/>
<text xml:space="preserve" text-anchor="start" x="1424.74" y="-379.8" font-family="Arial" font-size="20.00" fill="#ffffff">Device Capture &amp;</text>
<text xml:space="preserve" text-anchor="start" x="1410.29" y="-355.8" font-family="Arial" font-size="20.00" fill="#ffffff">SVG Instrumentation</text>
<text xml:space="preserve" text-anchor="start" x="1468.43" y="-334.8" font-family="Arial" font-size="13.00" fill="#ffffff">R/capture.R</text>
<text xml:space="preserve" text-anchor="start" x="1368.06" y="-313.2" font-family="Arial" font-size="15.00" fill="#ffffff">svglite::svgstring() single&#45;draw dual SVG</text>
<text xml:space="preserve" text-anchor="start" x="1375.55" y="-295.2" font-family="Arial" font-size="15.00" fill="#ffffff">capture, grid display&#45;list leaf wrapping,</text>
<text xml:space="preserve" text-anchor="start" x="1397.23" y="-277.2" font-family="Arial" font-size="15.00" fill="#ffffff">draw&#45;time gloss_probe viewport</text>
<text xml:space="preserve" text-anchor="start" x="1379.71" y="-259.2" font-family="Arial" font-size="15.00" fill="#ffffff">recorder, &lt;defs&gt;/&lt;use&gt; inlining, xml2</text>
<text xml:space="preserve" text-anchor="start" x="1387.63" y="-241.2" font-family="Arial" font-size="15.00" fill="#ffffff">geometry parsing, and dense PNG</text>
</g>
<!-- user&#45;&gt;fn_gloss -->
<g id="edge1" class="edge">
<title>user&#45;&gt;fn_gloss</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M319.89,-345.17C419.64,-342.14 548.16,-338.23 649.81,-335.14"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="649.74,-337.77 657.16,-334.92 649.58,-332.52 649.74,-337.77"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="395.04,-342.96 395.04,-367.96 580.04,-367.96 580.04,-342.96 395.04,-342.96"/>
<text xml:space="preserve" text-anchor="start" x="395.04" y="-353.96" font-family="Arial" font-size="14.00" fill="#c9c9c9">Captures R figure + sources</text>
</g>
<!-- fn_gloss&#45;&gt;mod_capture -->
<g id="edge9" class="edge">
<title>fn_gloss&#45;&gt;mod_capture</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M979.88,-327.43C1084.21,-325.75 1220.73,-323.54 1328.01,-321.81"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="1327.82,-324.44 1335.28,-321.69 1327.74,-319.19 1327.82,-324.44"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1050.09,-326.13 1050.09,-351.13 1273.09,-351.13 1273.09,-326.13 1050.09,-326.13"/>
<text xml:space="preserve" text-anchor="start" x="1050.09" y="-337.13" font-family="Arial" font-size="14.00" fill="#c9c9c9">Orchestrates single&#45;draw capture</text>
</g>
<!-- fn_register_engine&#45;&gt;mod_registry -->
<g id="edge2" class="edge">
<title>fn_register_engine&#45;&gt;mod_registry</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M319.77,-89.02C595.8,-89.67 1181.3,-101.42 1668.14,-181 1782.12,-199.63 1907.36,-233.23 2005.33,-262.61"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="2004.48,-265.1 2012.42,-264.75 2006,-260.07 2004.48,-265.1"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1087.09,-129.97 1087.09,-154.97 1236.09,-154.97 1236.09,-129.97 1087.09,-129.97"/>
<text xml:space="preserve" text-anchor="start" x="1087.09" y="-140.97" font-family="Arial" font-size="14.00" fill="#c9c9c9">Registers engine spec</text>
</g>
<!-- fn_asset_map&#45;&gt;mod_package_assets -->
<g id="edge3" class="edge">
<title>fn_asset_map&#45;&gt;mod_package_assets</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M319.89,-838.61C418.07,-819.22 544.14,-794.31 645.01,-774.38"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="645.5,-776.97 652.34,-772.94 644.48,-771.81 645.5,-776.97"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="401.54,-824.24 401.54,-849.24 573.54,-849.24 573.54,-824.24 401.54,-824.24"/>
<text xml:space="preserve" text-anchor="start" x="401.54" y="-835.24" font-family="Arial" font-size="14.00" fill="#c9c9c9">Serializes asset&#45;map.json</text>
</g>
<!-- fn_asset_bundle&#45;&gt;mod_package_assets -->
<g id="edge4" class="edge">
<title>fn_asset_bundle&#45;&gt;mod_package_assets</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M319.89,-641.39C418.07,-660.78 544.14,-685.69 645.01,-705.62"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="644.48,-708.19 652.34,-707.06 645.5,-703.03 644.48,-708.19"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="417.54,-694.24 417.54,-719.24 557.54,-719.24 557.54,-694.24 417.54,-694.24"/>
<text xml:space="preserve" text-anchor="start" x="417.54" y="-705.24" font-family="Arial" font-size="14.00" fill="#c9c9c9">Writes .gloss/ or .zip</text>
</g>
<!-- fn_scene&#45;&gt;mod_query -->
<g id="edge5" class="edge">
<title>fn_scene&#45;&gt;mod_query</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M312.81,-1820.04C416.37,-1758.66 553.31,-1677.5 658.66,-1615.07"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="659.75,-1617.47 664.86,-1611.39 657.07,-1612.96 659.75,-1617.47"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="425.54,-1772.72 425.54,-1797.72 549.54,-1797.72 549.54,-1772.72 425.54,-1772.72"/>
<text xml:space="preserve" text-anchor="start" x="425.54" y="-1783.72" font-family="Arial" font-size="14.00" fill="#c9c9c9">Reads scene view</text>
</g>
<!-- fn_tables&#45;&gt;mod_query -->
<g id="edge6" class="edge">
<title>fn_tables&#45;&gt;mod_query</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M319.89,-1618.61C418.07,-1599.22 544.14,-1574.31 645.01,-1554.38"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="645.5,-1556.97 652.34,-1552.94 644.48,-1551.81 645.5,-1556.97"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="422.54,-1604.24 422.54,-1629.24 552.54,-1629.24 552.54,-1604.24 422.54,-1604.24"/>
<text xml:space="preserve" text-anchor="start" x="422.54" y="-1615.24" font-family="Arial" font-size="14.00" fill="#c9c9c9">Reads data frames</text>
</g>
<!-- fn_sources&#45;&gt;mod_query -->
<g id="edge7" class="edge">
<title>fn_sources&#45;&gt;mod_query</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M319.89,-1421.39C418.07,-1440.78 544.14,-1465.69 645.01,-1485.62"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="644.48,-1488.19 652.34,-1487.06 645.5,-1483.03 644.48,-1488.19"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="421.54,-1474.24 421.54,-1499.24 553.54,-1499.24 553.54,-1474.24 421.54,-1474.24"/>
<text xml:space="preserve" text-anchor="start" x="421.54" y="-1485.24" font-family="Arial" font-size="14.00" fill="#c9c9c9">Reads source table</text>
</g>
<!-- fn_query&#45;&gt;mod_query -->
<g id="edge8" class="edge">
<title>fn_query&#45;&gt;mod_query</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M312.81,-1219.96C416.37,-1281.34 553.31,-1362.5 658.66,-1424.93"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="657.07,-1427.04 664.86,-1428.61 659.75,-1422.53 657.07,-1427.04"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="385.04,-1382.72 385.04,-1407.72 590.04,-1407.72 590.04,-1382.72 385.04,-1382.72"/>
<text xml:space="preserve" text-anchor="start" x="385.04" y="-1393.72" font-family="Arial" font-size="14.00" fill="#c9c9c9">Slices leaves, elements &amp; rows</text>
</g>
<!-- mod_capture&#45;&gt;mod_registry -->
<g id="edge10" class="edge">
<title>mod_capture&#45;&gt;mod_registry</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M1667.95,-319C1770.01,-319 1901.2,-319 2005.12,-319"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="2004.88,-321.63 2012.38,-319 2004.88,-316.38 2004.88,-321.63"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1733.14,-319 1733.14,-344 1950.14,-344 1950.14,-319 1733.14,-319"/>
<text xml:space="preserve" text-anchor="start" x="1733.14" y="-330" font-family="Arial" font-size="14.00" fill="#c9c9c9">Dispatches by class &amp; page_kind</text>
</g>
</g>
</svg>
`;case`engines_matrix`:return`<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
 "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<!-- Generated by graphviz version 16.1.0 (0)
 -->
<!-- Pages: 1 -->
<svg width="1959pt" height="782pt"
 viewBox="0.00 0.00 1959.00 782.00" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<g id="graph0" class="graph" transform="scale(1 1) rotate(0) translate(15.05 767.1)">
<!-- mod_capture -->
<g id="node1" class="node">
<title>mod_capture</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="330.05,-196.06 0,-196.06 0,0 330.05,0 330.05,-196.06"/>
<text xml:space="preserve" text-anchor="start" x="86.65" y="-158.83" font-family="Arial" font-size="20.00" fill="#ffffff">Device Capture &amp;</text>
<text xml:space="preserve" text-anchor="start" x="72.2" y="-134.83" font-family="Arial" font-size="20.00" fill="#ffffff">SVG Instrumentation</text>
<text xml:space="preserve" text-anchor="start" x="130.34" y="-113.83" font-family="Arial" font-size="13.00" fill="#ffffff">R/capture.R</text>
<text xml:space="preserve" text-anchor="start" x="29.97" y="-92.23" font-family="Arial" font-size="15.00" fill="#ffffff">svglite::svgstring() single&#45;draw dual SVG</text>
<text xml:space="preserve" text-anchor="start" x="37.46" y="-74.23" font-family="Arial" font-size="15.00" fill="#ffffff">capture, grid display&#45;list leaf wrapping,</text>
<text xml:space="preserve" text-anchor="start" x="59.15" y="-56.23" font-family="Arial" font-size="15.00" fill="#ffffff">draw&#45;time gloss_probe viewport</text>
<text xml:space="preserve" text-anchor="start" x="41.62" y="-38.23" font-family="Arial" font-size="15.00" fill="#ffffff">recorder, &lt;defs&gt;/&lt;use&gt; inlining, xml2</text>
<text xml:space="preserve" text-anchor="start" x="49.54" y="-20.23" font-family="Arial" font-size="15.00" fill="#ffffff">geometry parsing, and dense PNG</text>
</g>
<!-- mod_registry -->
<g id="node2" class="node">
<title>mod_registry</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1007.1,-188.03 677.05,-188.03 677.05,-8.03 1007.1,-8.03 1007.1,-188.03"/>
<text xml:space="preserve" text-anchor="start" x="710.89" y="-137.83" font-family="Arial" font-size="20.00" fill="#ffffff">Engine Registry &amp; Load Hook</text>
<text xml:space="preserve" text-anchor="start" x="759.72" y="-116.83" font-family="Arial" font-size="13.00" fill="#ffffff">R/engine&#45;registry.R, R/zzz.R</text>
<text xml:space="preserve" text-anchor="start" x="716.18" y="-95.23" font-family="Arial" font-size="15.00" fill="#ffffff">Private package environment registry,</text>
<text xml:space="preserve" text-anchor="start" x="727.87" y="-77.23" font-family="Arial" font-size="15.00" fill="#ffffff">class&#45;hierarchy &amp; priority dispatch,</text>
<text xml:space="preserve" text-anchor="start" x="718.23" y="-59.23" font-family="Arial" font-size="15.00" fill="#ffffff">page_kind candidate disambiguation,</text>
<text xml:space="preserve" text-anchor="start" x="753.27" y="-41.23" font-family="Arial" font-size="15.00" fill="#ffffff">and lazy Suggests checks.</text>
</g>
<!-- eng_grid -->
<g id="node3" class="node">
<title>eng_grid</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="330.05,-466.03 0,-466.03 0,-286.03 330.05,-286.03 330.05,-466.03"/>
<text xml:space="preserve" text-anchor="start" x="114.43" y="-406.83" font-family="Arial" font-size="20.00" fill="#ffffff">grid Engine</text>
<text xml:space="preserve" text-anchor="start" x="102.53" y="-385.83" font-family="Arial" font-size="13.00" fill="#ffffff">R/engine&#45;grid.R (grid)</text>
<text xml:space="preserve" text-anchor="start" x="31.64" y="-364.23" font-family="Arial" font-size="15.00" fill="#ffffff">Captures raw grid grobs, gLists, gTrees,</text>
<text xml:space="preserve" text-anchor="start" x="47.03" y="-346.23" font-family="Arial" font-size="15.00" fill="#ffffff">gtables, grid drawing functions, and</text>
<text xml:space="preserve" text-anchor="start" x="100.82" y="-328.23" font-family="Arial" font-size="15.00" fill="#ffffff">recorded grid plots.</text>
</g>
<!-- eng_ggplot -->
<g id="node4" class="node">
<title>eng_ggplot</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1007.1,-466.03 677.05,-466.03 677.05,-286.03 1007.1,-286.03 1007.1,-466.03"/>
<text xml:space="preserve" text-anchor="start" x="775.35" y="-424.83" font-family="Arial" font-size="20.00" fill="#ffffff">ggplot2 Engine</text>
<text xml:space="preserve" text-anchor="start" x="731.51" y="-403.83" font-family="Arial" font-size="13.00" fill="#ffffff">R/engine&#45;ggplot.R (Suggests: ggplot2)</text>
<text xml:space="preserve" text-anchor="start" x="751.38" y="-382.23" font-family="Arial" font-size="15.00" fill="#ffffff">Single&#45;build ggplot_build &#45;&gt;</text>
<text xml:space="preserve" text-anchor="start" x="720.54" y="-364.23" font-family="Arial" font-size="15.00" fill="#ffffff">ggplot_gtable &#45;&gt; grid.draw extracting</text>
<text xml:space="preserve" text-anchor="start" x="723.26" y="-346.23" font-family="Arial" font-size="15.00" fill="#ffffff">raw/built tables, scale/palette maps,</text>
<text xml:space="preserve" text-anchor="start" x="733.68" y="-328.23" font-family="Arial" font-size="15.00" fill="#ffffff">layer recipes, facets, and neutral</text>
<text xml:space="preserve" text-anchor="start" x="815.8" y="-310.23" font-family="Arial" font-size="15.00" fill="#ffffff">lineage.</text>
</g>
<!-- eng_patchwork -->
<g id="node5" class="node">
<title>eng_patchwork</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1468.14,-466.03 1138.1,-466.03 1138.1,-286.03 1468.14,-286.03 1468.14,-466.03"/>
<text xml:space="preserve" text-anchor="start" x="1223.63" y="-415.83" font-family="Arial" font-size="20.00" fill="#ffffff">patchwork Engine</text>
<text xml:space="preserve" text-anchor="start" x="1172.34" y="-394.83" font-family="Arial" font-size="13.00" fill="#ffffff">R/engine&#45;patchwork.R (Suggests: patchwork)</text>
<text xml:space="preserve" text-anchor="start" x="1175.16" y="-373.23" font-family="Arial" font-size="15.00" fill="#ffffff">Composite multi&#45;plot IR extraction with</text>
<text xml:space="preserve" text-anchor="start" x="1212.22" y="-355.23" font-family="Arial" font-size="15.00" fill="#ffffff">per&#45;subplot panel and table</text>
<text xml:space="preserve" text-anchor="start" x="1181.79" y="-337.23" font-family="Arial" font-size="15.00" fill="#ffffff">namespaces without double&#45;building</text>
<text xml:space="preserve" text-anchor="start" x="1237.67" y="-319.23" font-family="Arial" font-size="15.00" fill="#ffffff">stochastic subplots.</text>
</g>
<!-- eng_heatmap -->
<g id="node6" class="node">
<title>eng_heatmap</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1929.19,-466.03 1599.14,-466.03 1599.14,-286.03 1929.19,-286.03 1929.19,-466.03"/>
<text xml:space="preserve" text-anchor="start" x="1650.22" y="-424.83" font-family="Arial" font-size="20.00" fill="#ffffff">ComplexHeatmap Engine</text>
<text xml:space="preserve" text-anchor="start" x="1671.31" y="-403.83" font-family="Arial" font-size="13.00" fill="#ffffff">R/engine&#45;heatmap.R (Suggests:</text>
<text xml:space="preserve" text-anchor="start" x="1634.95" y="-382.23" font-family="Arial" font-size="15.00" fill="#ffffff">Single draw() capture preserving draw&#45;</text>
<text xml:space="preserve" text-anchor="start" x="1670.38" y="-364.23" font-family="Arial" font-size="15.00" fill="#ffffff">time clustering permutations</text>
<text xml:space="preserve" text-anchor="start" x="1637.87" y="-346.23" font-family="Arial" font-size="15.00" fill="#ffffff">(row_order/column_order) in ir.orders,</text>
<text xml:space="preserve" text-anchor="start" x="1649.52" y="-328.23" font-family="Arial" font-size="15.00" fill="#ffffff">matrix/annotation tables, and color</text>
<text xml:space="preserve" text-anchor="start" x="1743.74" y="-310.23" font-family="Arial" font-size="15.00" fill="#ffffff">maps.</text>
</g>
<!-- eng_base -->
<g id="node7" class="node">
<title>eng_base</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="330.05,-744.03 0,-744.03 0,-564.03 330.05,-564.03 330.05,-744.03"/>
<text xml:space="preserve" text-anchor="start" x="66.63" y="-693.83" font-family="Arial" font-size="20.00" fill="#ffffff">base Graphics Engine</text>
<text xml:space="preserve" text-anchor="start" x="54.84" y="-672.83" font-family="Arial" font-size="13.00" fill="#ffffff">R/engine&#45;base.R (grDevices/graphics)</text>
<text xml:space="preserve" text-anchor="start" x="52.47" y="-651.23" font-family="Arial" font-size="15.00" fill="#ffffff">Step&#45;by&#45;step display&#45;list replay on</text>
<text xml:space="preserve" text-anchor="start" x="46.89" y="-633.23" font-family="Arial" font-size="15.00" fill="#ffffff">svglite isolating per&#45;call &lt;g id=&#39;L...&#39;&gt;</text>
<text xml:space="preserve" text-anchor="start" x="54.67" y="-615.23" font-family="Arial" font-size="15.00" fill="#ffffff">leaves and par(&#39;usr&#39;)/par(&#39;plt&#39;) plot</text>
<text xml:space="preserve" text-anchor="start" x="138.34" y="-597.23" font-family="Arial" font-size="15.00" fill="#ffffff">regions.</text>
</g>
<!-- mod_ir_lineage -->
<g id="node8" class="node">
<title>mod_ir_lineage</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1007.1,-752.06 677.05,-752.06 677.05,-556 1007.1,-556 1007.1,-752.06"/>
<text xml:space="preserve" text-anchor="start" x="788.71" y="-714.83" font-family="Arial" font-size="20.00" fill="#ffffff">Engine IR &amp;</text>
<text xml:space="preserve" text-anchor="start" x="760.91" y="-690.83" font-family="Arial" font-size="20.00" fill="#ffffff">Structural Lineage</text>
<text xml:space="preserve" text-anchor="start" x="802.34" y="-669.83" font-family="Arial" font-size="13.00" fill="#ffffff">R/ir&#45;lineage.R</text>
<text xml:space="preserve" text-anchor="start" x="714.51" y="-648.23" font-family="Arial" font-size="15.00" fill="#ffffff">Normalizes panel coordinate domains,</text>
<text xml:space="preserve" text-anchor="start" x="715.76" y="-630.23" font-family="Arial" font-size="15.00" fill="#ffffff">scale/palette dictionaries, layer specs,</text>
<text xml:space="preserve" text-anchor="start" x="748.26" y="-612.23" font-family="Arial" font-size="15.00" fill="#ffffff">and neutral element&#45;to&#45;table</text>
<text xml:space="preserve" text-anchor="start" x="752.87" y="-594.23" font-family="Arial" font-size="15.00" fill="#ffffff">cardinalities (1:1, N:1, 1:M,</text>
<text xml:space="preserve" text-anchor="start" x="783.28" y="-576.23" font-family="Arial" font-size="15.00" fill="#ffffff">stat_aggregated).</text>
</g>
<!-- mod_capture&#45;&gt;mod_registry -->
<g id="edge1" class="edge">
<title>mod_capture&#45;&gt;mod_registry</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M329.87,-98.03C431.93,-98.03 563.11,-98.03 667.03,-98.03"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="666.8,-100.65 674.3,-98.03 666.8,-95.4 666.8,-100.65"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="395.05,-98.03 395.05,-123.03 612.05,-123.03 612.05,-98.03 395.05,-98.03"/>
<text xml:space="preserve" text-anchor="start" x="395.05" y="-109.03" font-family="Arial" font-size="14.00" fill="#c9c9c9">Dispatches by class &amp; page_kind</text>
</g>
<!-- eng_grid&#45;&gt;eng_ggplot -->
<!-- eng_ggplot&#45;&gt;eng_patchwork -->
<!-- eng_patchwork&#45;&gt;eng_heatmap -->
<!-- eng_base&#45;&gt;mod_ir_lineage -->
</g>
</svg>
`;case`guardrails_monitor`:return`<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
 "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<!-- Generated by graphviz version 16.1.0 (0)
 -->
<!-- Pages: 1 -->
<svg width="1009pt" height="1560pt"
 viewBox="0.00 0.00 1009.00 1560.00" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<g id="graph0" class="graph" transform="scale(1 1) rotate(0) translate(15.05 1545.05)">
<!-- p1_source_map -->
<g id="node1" class="node">
<title>p1_source_map</title>
<polygon fill="#d97706" stroke="#ac5300" stroke-width="0" points="320.04,-180 0,-180 0,0 320.04,0 320.04,-180"/>
<text xml:space="preserve" text-anchor="start" x="62.2" y="-141" font-family="Arial" font-size="20.00" fill="#ffffff">P1 · Compiler Source</text>
<text xml:space="preserve" text-anchor="start" x="64.41" y="-117" font-family="Arial" font-size="20.00" fill="#ffffff">Map, Not Gatekeeper</text>
<text xml:space="preserve" text-anchor="start" x="39.54" y="-94" font-family="Arial" font-size="15.00" fill="#ffffff">Faithfully observe and record device</text>
<text xml:space="preserve" text-anchor="start" x="23.27" y="-76" font-family="Arial" font-size="15.00" fill="#ffffff">groups, viewports, engine IR, and neutral</text>
<text xml:space="preserve" text-anchor="start" x="24.52" y="-58" font-family="Arial" font-size="15.00" fill="#ffffff">lineage cardinalities. Verification belongs</text>
<text xml:space="preserve" text-anchor="start" x="24.96" y="-40" font-family="Arial" font-size="15.00" fill="#ffffff">to upper&#45;layer semantic tools, never low&#45;</text>
<text xml:space="preserve" text-anchor="start" x="94.98" y="-22" font-family="Arial" font-size="15.00" fill="#ffffff">level capture gates.</text>
</g>
<!-- g_tests -->
<g id="node2" class="node">
<title>g_tests</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="979.08,-180 659.04,-180 659.04,0 979.08,0 979.08,-180"/>
<text xml:space="preserve" text-anchor="start" x="749.04" y="-114" font-family="Arial" font-size="20.00" fill="#ffffff">Guardrail · Unit</text>
<text xml:space="preserve" text-anchor="start" x="733.46" y="-90" font-family="Arial" font-size="20.00" fill="#ffffff">Test &amp; Build Health</text>
<text xml:space="preserve" text-anchor="start" x="681.5" y="-67" font-family="Arial" font-size="15.00" fill="#ffffff">Tracks live testthat suite coverage across</text>
<text xml:space="preserve" text-anchor="start" x="729" y="-49" font-family="Arial" font-size="15.00" fill="#ffffff">core modules and engines.</text>
</g>
<!-- p2_core_boundary -->
<g id="node3" class="node">
<title>p2_core_boundary</title>
<polygon fill="#d97706" stroke="#ac5300" stroke-width="0" points="320.04,-450 0,-450 0,-270 320.04,-270 320.04,-450"/>
<text xml:space="preserve" text-anchor="start" x="32.19" y="-399" font-family="Arial" font-size="20.00" fill="#ffffff">P2 · Strict In&#45;Core Boundary</text>
<text xml:space="preserve" text-anchor="start" x="22.04" y="-376" font-family="Arial" font-size="15.00" fill="#ffffff">The R package owns only live&#45;R graphics</text>
<text xml:space="preserve" text-anchor="start" x="48.71" y="-358" font-family="Arial" font-size="15.00" fill="#ffffff">device instrumentation, engine IR</text>
<text xml:space="preserve" text-anchor="start" x="24.54" y="-340" font-family="Arial" font-size="15.00" fill="#ffffff">extraction, runtime source inventory, and</text>
<text xml:space="preserve" text-anchor="start" x="32.87" y="-322" font-family="Arial" font-size="15.00" fill="#ffffff">open&#45;format packaging. Agents, MCP,</text>
<text xml:space="preserve" text-anchor="start" x="36.63" y="-304" font-family="Arial" font-size="15.00" fill="#ffffff">Workbench, and SVG refinement live</text>
</g>
<!-- g_core_boundary -->
<g id="node4" class="node">
<title>g_core_boundary</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="979.08,-450 659.04,-450 659.04,-270 979.08,-270 979.08,-450"/>
<text xml:space="preserve" text-anchor="start" x="744.04" y="-393" font-family="Arial" font-size="20.00" fill="#ffffff">Guardrail · Strict</text>
<text xml:space="preserve" text-anchor="start" x="740.13" y="-369" font-family="Arial" font-size="20.00" fill="#ffffff">In&#45;Core Boundary</text>
<text xml:space="preserve" text-anchor="start" x="684.82" y="-346" font-family="Arial" font-size="15.00" fill="#ffffff">Verifies R/ contains no out&#45;of&#45;core agent</text>
<text xml:space="preserve" text-anchor="start" x="684.85" y="-328" font-family="Arial" font-size="15.00" fill="#ffffff">runners, MCP servers, binary codecs, or</text>
<text xml:space="preserve" text-anchor="start" x="753.6" y="-310" font-family="Arial" font-size="15.00" fill="#ffffff">embedded UI code.</text>
</g>
<!-- p3_single_capture -->
<g id="node5" class="node">
<title>p3_single_capture</title>
<polygon fill="#d97706" stroke="#ac5300" stroke-width="0" points="320.04,-720 0,-720 0,-540 320.04,-540 320.04,-720"/>
<text xml:space="preserve" text-anchor="start" x="67.74" y="-681" font-family="Arial" font-size="20.00" fill="#ffffff">P3 · Single Capture,</text>
<text xml:space="preserve" text-anchor="start" x="84.97" y="-657" font-family="Arial" font-size="20.00" fill="#ffffff">Layered Payload</text>
<text xml:space="preserve" text-anchor="start" x="17.04" y="-634" font-family="Arial" font-size="15.00" fill="#ffffff">Asset Map and Asset Bundle serialize from</text>
<text xml:space="preserve" text-anchor="start" x="20.79" y="-616" font-family="Arial" font-size="15.00" fill="#ffffff">the same in&#45;memory gloss_capture object</text>
<text xml:space="preserve" text-anchor="start" x="57.89" y="-598" font-family="Arial" font-size="15.00" fill="#ffffff">so figures (including stochastic</text>
<text xml:space="preserve" text-anchor="start" x="33.72" y="-580" font-family="Arial" font-size="15.00" fill="#ffffff">jitter/UMAP) are never redrawn during</text>
<text xml:space="preserve" text-anchor="start" x="123.74" y="-562" font-family="Arial" font-size="15.00" fill="#ffffff">packaging.</text>
</g>
<!-- gloss_core -->
<g id="node6" class="node">
<title>gloss_core</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="979.08,-720 659.04,-720 659.04,-540 979.08,-540 979.08,-720"/>
<text xml:space="preserve" text-anchor="start" x="719.57" y="-669.8" font-family="Arial" font-size="20.00" fill="#ffffff">gloss R Core Package</text>
<text xml:space="preserve" text-anchor="start" x="700.2" y="-648.8" font-family="Arial" font-size="13.00" fill="#ffffff">R (&gt;= 4.2.0), svglite, xml2, jsonlite, digest</text>
<text xml:space="preserve" text-anchor="start" x="683.99" y="-627.2" font-family="Arial" font-size="15.00" fill="#ffffff">Lightweight R core package: single&#45;draw</text>
<text xml:space="preserve" text-anchor="start" x="696.49" y="-609.2" font-family="Arial" font-size="15.00" fill="#ffffff">device capture, Engine IR extraction,</text>
<text xml:space="preserve" text-anchor="start" x="708.17" y="-591.2" font-family="Arial" font-size="15.00" fill="#ffffff">structural lineage, runtime source</text>
<text xml:space="preserve" text-anchor="start" x="694.81" y="-573.2" font-family="Arial" font-size="15.00" fill="#ffffff">inventory, and open asset packaging.</text>
</g>
<!-- p4_file_first -->
<g id="node7" class="node">
<title>p4_file_first</title>
<polygon fill="#d97706" stroke="#ac5300" stroke-width="0" points="320.04,-990 0,-990 0,-810 320.04,-810 320.04,-990"/>
<text xml:space="preserve" text-anchor="start" x="71.68" y="-951" font-family="Arial" font-size="20.00" fill="#ffffff">P4 · File&#45;First, Zero</text>
<text xml:space="preserve" text-anchor="start" x="74.43" y="-927" font-family="Arial" font-size="20.00" fill="#ffffff">Proprietary Codecs</text>
<text xml:space="preserve" text-anchor="start" x="14.14" y="-904" font-family="Arial" font-size="15.00" fill="#ffffff">Emit standard UTF&#45;8 SVG, JSON, and CSV</text>
<text xml:space="preserve" text-anchor="start" x="25.37" y="-886" font-family="Arial" font-size="15.00" fill="#ffffff">(or Parquet) readable directly by Python,</text>
<text xml:space="preserve" text-anchor="start" x="18.7" y="-868" font-family="Arial" font-size="15.00" fill="#ffffff">JS, DuckDB, R, and coding agents without</text>
<text xml:space="preserve" text-anchor="start" x="22.87" y="-850" font-family="Arial" font-size="15.00" fill="#ffffff">custom binary decoders or background R</text>
<text xml:space="preserve" text-anchor="start" x="123.75" y="-832" font-family="Arial" font-size="15.00" fill="#ffffff">processes.</text>
</g>
<!-- g_cran_hygiene -->
<g id="node8" class="node">
<title>g_cran_hygiene</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="979.08,-990 659.04,-990 659.04,-810 979.08,-810 979.08,-990"/>
<text xml:space="preserve" text-anchor="start" x="679.57" y="-921" font-family="Arial" font-size="20.00" fill="#ffffff">Guardrail · CRAN &amp; R Hygiene</text>
<text xml:space="preserve" text-anchor="start" x="682.33" y="-898" font-family="Arial" font-size="15.00" fill="#ffffff">Checks R/ and tests/ for forbidden super&#45;</text>
<text xml:space="preserve" text-anchor="start" x="683.17" y="-880" font-family="Arial" font-size="15.00" fill="#ffffff">assignment (&lt;&lt;&#45;), .GlobalEnv writes, and</text>
<text xml:space="preserve" text-anchor="start" x="736.53" y="-862" font-family="Arial" font-size="15.00" fill="#ffffff">stray Rplots.pdf artifacts.</text>
</g>
<!-- p5_minimal_surface -->
<g id="node9" class="node">
<title>p5_minimal_surface</title>
<polygon fill="#d97706" stroke="#ac5300" stroke-width="0" points="320.04,-1395 0,-1395 0,-1215 320.04,-1215 320.04,-1395"/>
<text xml:space="preserve" text-anchor="start" x="70.55" y="-1347" font-family="Arial" font-size="20.00" fill="#ffffff">P5 · Minimal Export</text>
<text xml:space="preserve" text-anchor="start" x="86.66" y="-1323" font-family="Arial" font-size="20.00" fill="#ffffff">Surface (8 APIs)</text>
<text xml:space="preserve" text-anchor="start" x="37.05" y="-1300" font-family="Arial" font-size="15.00" fill="#ffffff">Keep NAMESPACE tight at exactly 8</text>
<text xml:space="preserve" text-anchor="start" x="41.61" y="-1282" font-family="Arial" font-size="15.00" fill="#ffffff">exported functions and keep built&#45;in</text>
<text xml:space="preserve" text-anchor="start" x="62.46" y="-1264" font-family="Arial" font-size="15.00" fill="#ffffff">engines in&#45;repo with package</text>
<text xml:space="preserve" text-anchor="start" x="46.62" y="-1246" font-family="Arial" font-size="15.00" fill="#ffffff">dependencies strictly in Suggests.</text>
</g>
<!-- g_exports -->
<g id="node10" class="node">
<title>g_exports</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="979.08,-1530 659.04,-1530 659.04,-1350 979.08,-1350 979.08,-1530"/>
<text xml:space="preserve" text-anchor="start" x="700.68" y="-1473" font-family="Arial" font-size="20.00" fill="#ffffff">Guardrail · Export Surface</text>
<text xml:space="preserve" text-anchor="start" x="735.7" y="-1449" font-family="Arial" font-size="20.00" fill="#ffffff">Alignment (8 APIs)</text>
<text xml:space="preserve" text-anchor="start" x="676.92" y="-1426" font-family="Arial" font-size="15.00" fill="#ffffff">Verifies NAMESPACE exports match the 8</text>
<text xml:space="preserve" text-anchor="start" x="686.5" y="-1408" font-family="Arial" font-size="15.00" fill="#ffffff">canonical functions in AGENTS.md with</text>
<text xml:space="preserve" text-anchor="start" x="734.84" y="-1390" font-family="Arial" font-size="15.00" fill="#ffffff">zero unexpected exports.</text>
</g>
<!-- g_suggests -->
<g id="node11" class="node">
<title>g_suggests</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="979.08,-1260 659.04,-1260 659.04,-1080 979.08,-1080 979.08,-1260"/>
<text xml:space="preserve" text-anchor="start" x="735.68" y="-1203" font-family="Arial" font-size="20.00" fill="#ffffff">Guardrail · Engine</text>
<text xml:space="preserve" text-anchor="start" x="700.09" y="-1179" font-family="Arial" font-size="20.00" fill="#ffffff">Dependencies in Suggests</text>
<text xml:space="preserve" text-anchor="start" x="726.93" y="-1156" font-family="Arial" font-size="15.00" fill="#ffffff">Verifies ggplot2, patchwork,</text>
<text xml:space="preserve" text-anchor="start" x="681.94" y="-1138" font-family="Arial" font-size="15.00" fill="#ffffff">ComplexHeatmap stay in DESCRIPTION</text>
<text xml:space="preserve" text-anchor="start" x="693.16" y="-1120" font-family="Arial" font-size="15.00" fill="#ffffff">Suggests and never leak into Imports.</text>
</g>
<!-- p1_source_map&#45;&gt;g_tests -->
<g id="edge1" class="edge">
<title>p1_source_map&#45;&gt;g_tests</title>
<path fill="none" stroke="#a35905" stroke-width="2" stroke-dasharray="5,2" d="M319.65,-90C419.15,-90 547.33,-90 648.78,-90"/>
<polygon fill="#a35905" stroke="#a35905" stroke-width="2" points="648.61,-92.63 656.11,-90 648.61,-87.38 648.61,-92.63"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="393.04,-90 393.04,-115 586.04,-115 586.04,-90 393.04,-90"/>
<text xml:space="preserve" text-anchor="start" x="393.04" y="-101" font-family="Arial" font-size="14.00" fill="#ffffff">Verifies neutral capture facts</text>
</g>
<!-- p2_core_boundary&#45;&gt;g_core_boundary -->
<g id="edge2" class="edge">
<title>p2_core_boundary&#45;&gt;g_core_boundary</title>
<path fill="none" stroke="#a35905" stroke-width="2" stroke-dasharray="5,2" d="M319.65,-360C419.15,-360 547.33,-360 648.78,-360"/>
<polygon fill="#a35905" stroke="#a35905" stroke-width="2" points="648.61,-362.63 656.11,-360 648.61,-357.38 648.61,-362.63"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="406.54,-360 406.54,-385 572.54,-385 572.54,-360 406.54,-360"/>
<text xml:space="preserve" text-anchor="start" x="406.54" y="-371" font-family="Arial" font-size="14.00" fill="#ffffff">Prevents v1 scope creep</text>
</g>
<!-- p3_single_capture&#45;&gt;gloss_core -->
<!-- p4_file_first&#45;&gt;g_cran_hygiene -->
<g id="edge4" class="edge">
<title>p4_file_first&#45;&gt;g_cran_hygiene</title>
<path fill="none" stroke="#a35905" stroke-width="2" stroke-dasharray="5,2" d="M319.65,-900C419.15,-900 547.33,-900 648.78,-900"/>
<polygon fill="#a35905" stroke="#a35905" stroke-width="2" points="648.61,-902.63 656.11,-900 648.61,-897.38 648.61,-902.63"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="390.04,-900 390.04,-925 589.04,-925 589.04,-900 390.04,-900"/>
<text xml:space="preserve" text-anchor="start" x="390.04" y="-911" font-family="Arial" font-size="14.00" fill="#ffffff">Verifies clean open packaging</text>
</g>
<!-- p5_minimal_surface&#45;&gt;g_exports -->
<g id="edge5" class="edge">
<title>p5_minimal_surface&#45;&gt;g_exports</title>
<path fill="none" stroke="#a35905" stroke-width="2" stroke-dasharray="5,2" d="M319.65,-1337.59C419.25,-1358.06 547.59,-1384.43 649.09,-1405.28"/>
<polygon fill="#a35905" stroke="#a35905" stroke-width="2" points="648.3,-1407.8 656.17,-1406.74 649.36,-1402.66 648.3,-1407.8"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="408.04,-1392.48 408.04,-1417.48 571.04,-1417.48 571.04,-1392.48 408.04,-1392.48"/>
<text xml:space="preserve" text-anchor="start" x="408.04" y="-1403.48" font-family="Arial" font-size="14.00" fill="#ffffff">Enforces 8&#45;API contract</text>
</g>
<!-- p5_minimal_surface&#45;&gt;g_suggests -->
<g id="edge6" class="edge">
<title>p5_minimal_surface&#45;&gt;g_suggests</title>
<path fill="none" stroke="#a35905" stroke-width="2" stroke-dasharray="5,2" d="M319.65,-1272.41C419.25,-1251.94 547.59,-1225.57 649.09,-1204.72"/>
<polygon fill="#a35905" stroke="#a35905" stroke-width="2" points="649.36,-1207.34 656.17,-1203.26 648.3,-1202.2 649.36,-1207.34"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="397.04,-1257.48 397.04,-1282.48 582.04,-1282.48 582.04,-1257.48 397.04,-1257.48"/>
<text xml:space="preserve" text-anchor="start" x="397.04" y="-1268.48" font-family="Arial" font-size="14.00" fill="#ffffff">Enforces Suggests isolation</text>
</g>
</g>
</svg>
`;case`open_contracts`:return`<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
 "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<!-- Generated by graphviz version 16.1.0 (0)
 -->
<!-- Pages: 1 -->
<svg width="2371pt" height="1853pt"
 viewBox="0.00 0.00 2371.00 1853.00" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<g id="graph0" class="graph" transform="scale(1 1) rotate(0) translate(15.05 1838.4)">
<g id="clust1" class="cluster">
<title>cluster_ecosystem</title>
<polygon fill="#491e93" stroke="#32126a" points="8,-667.36 8,-1815.36 1081.08,-1815.36 1081.08,-667.36 8,-667.36"/>
<text xml:space="preserve" text-anchor="start" x="16" y="-1802.46" font-family="Arial" font-weight="bold" font-size="11.00" fill="#ffffff" fill-opacity="0.701961">OUTER ECOSYSTEM (OUT&#45;OF&#45;CORE)</text>
</g>
<g id="clust2" class="cluster">
<title>cluster_open_assets</title>
<polygon fill="#0f413d" stroke="#052c29" points="1933.12,-333.36 1933.12,-900.36 2333.16,-900.36 2333.16,-333.36 1933.12,-333.36"/>
<text xml:space="preserve" text-anchor="start" x="1941.12" y="-887.46" font-family="Arial" font-weight="bold" font-size="11.00" fill="#b2ffff" fill-opacity="0.701961">OPEN FILE CONTRACTS</text>
</g>
<!-- skill_gloss -->
<g id="node1" class="node">
<title>skill_gloss</title>
<polygon fill="#7c3aed" stroke="#4e0cc3" stroke-width="0" points="368.04,-1439.86 48,-1439.86 48,-1258.85 368.04,-1258.85 368.04,-1439.86"/>
<text xml:space="preserve" text-anchor="start" x="95.75" y="-1389.16" font-family="Arial" font-size="20.00" fill="#ffffff">Base Protocol Skill: gloss</text>
<text xml:space="preserve" text-anchor="start" x="179.48" y="-1368.16" font-family="Arial" font-size="13.00" fill="#ffffff">SKILL.md</text>
<text xml:space="preserve" text-anchor="start" x="69.18" y="-1346.56" font-family="Arial" font-size="15.00" fill="#ffffff">Entry protocol guiding AI coding agents to</text>
<text xml:space="preserve" text-anchor="start" x="91.72" y="-1328.56" font-family="Arial" font-size="15.00" fill="#ffffff">read asset&#45;map.json first, plan task</text>
<text xml:space="preserve" text-anchor="start" x="76.28" y="-1310.56" font-family="Arial" font-size="15.00" fill="#ffffff">context packets, and selectively unpack</text>
<text xml:space="preserve" text-anchor="start" x="157.58" y="-1292.56" font-family="Arial" font-size="15.00" fill="#ffffff">tables/sources.</text>
</g>
<!-- workbench -->
<g id="node2" class="node">
<title>workbench</title>
<polygon fill="#7c3aed" stroke="#4e0cc3" stroke-width="0" points="368.04,-1168.86 48,-1168.86 48,-987.85 368.04,-987.85 368.04,-1168.86"/>
<text xml:space="preserve" text-anchor="start" x="84.07" y="-1118.16" font-family="Arial" font-size="20.00" fill="#ffffff">Static Frontend: Workbench</text>
<text xml:space="preserve" text-anchor="start" x="146.98" y="-1097.16" font-family="Arial" font-size="13.00" fill="#ffffff">Static SPA (Browser)</text>
<text xml:space="preserve" text-anchor="start" x="69.21" y="-1075.56" font-family="Arial" font-size="15.00" fill="#ffffff">Zero&#45;decoder browser inspector for .gloss</text>
<text xml:space="preserve" text-anchor="start" x="73.36" y="-1057.56" font-family="Arial" font-size="15.00" fill="#ffffff">bundles: layer outline tree, raw/built data</text>
<text xml:space="preserve" text-anchor="start" x="96.28" y="-1039.56" font-family="Arial" font-size="15.00" fill="#ffffff">tables, bidirectional brushing, and</text>
<text xml:space="preserve" text-anchor="start" x="114.65" y="-1021.56" font-family="Arial" font-size="15.00" fill="#ffffff">original&#45;vs&#45;derived SVG diff.</text>
</g>
<!-- external_scripts -->
<g id="node3" class="node">
<title>external_scripts</title>
<polygon fill="#7c3aed" stroke="#4e0cc3" stroke-width="0" points="368.04,-897.36 48,-897.36 48,-707.35 368.04,-707.35 368.04,-897.36"/>
<text xml:space="preserve" text-anchor="start" x="151.33" y="-845.16" font-family="Arial" font-size="20.00" fill="#ffffff">Python / JS /</text>
<text xml:space="preserve" text-anchor="start" x="120.21" y="-821.16" font-family="Arial" font-size="20.00" fill="#ffffff">DuckDB Toolchains</text>
<text xml:space="preserve" text-anchor="start" x="122.76" y="-800.16" font-family="Arial" font-size="13.00" fill="#ffffff">pandas, polars, DuckDB, lxml</text>
<text xml:space="preserve" text-anchor="start" x="84.62" y="-778.56" font-family="Arial" font-size="15.00" fill="#ffffff">Direct batch analytics and automated</text>
<text xml:space="preserve" text-anchor="start" x="84.18" y="-760.56" font-family="Arial" font-size="15.00" fill="#ffffff">publishing pipelines reading standard</text>
<text xml:space="preserve" text-anchor="start" x="85.89" y="-742.56" font-family="Arial" font-size="15.00" fill="#ffffff">SVG/JSON/CSV without installing R.</text>
</g>
<!-- skill_refine -->
<g id="node4" class="node">
<title>skill_refine</title>
<polygon fill="#7c3aed" stroke="#4e0cc3" stroke-width="0" points="1041.08,-914.86 721.04,-914.86 721.04,-707.86 1041.08,-707.86 1041.08,-914.86"/>
<text xml:space="preserve" text-anchor="start" x="806.03" y="-863.16" font-family="Arial" font-size="20.00" fill="#ffffff">SVG Refinement</text>
<text xml:space="preserve" text-anchor="start" x="786.59" y="-839.16" font-family="Arial" font-size="20.00" fill="#ffffff">Skill: gloss&#45;svg&#45;refine</text>
<text xml:space="preserve" text-anchor="start" x="852.52" y="-818.16" font-family="Arial" font-size="13.00" fill="#ffffff">SKILL.md</text>
<text xml:space="preserve" text-anchor="start" x="770.16" y="-796.56" font-family="Arial" font-size="15.00" fill="#ffffff">Publication&#45;grade label repulsion,</text>
<text xml:space="preserve" text-anchor="start" x="745.55" y="-778.56" font-family="Arial" font-size="15.00" fill="#ffffff">typography hierarchy, legend layout, and</text>
<text xml:space="preserve" text-anchor="start" x="746.39" y="-760.56" font-family="Arial" font-size="15.00" fill="#ffffff">palette updates producing derived SVGs</text>
<text xml:space="preserve" text-anchor="start" x="763.07" y="-742.56" font-family="Arial" font-size="15.00" fill="#ffffff">linked via parent_manifest_sha256.</text>
</g>
<!-- skill_audit -->
<g id="node5" class="node">
<title>skill_audit</title>
<polygon fill="#7c3aed" stroke="#4e0cc3" stroke-width="0" points="1041.08,-1211.86 721.04,-1211.86 721.04,-1004.86 1041.08,-1004.86 1041.08,-1211.86"/>
<text xml:space="preserve" text-anchor="start" x="813.8" y="-1160.16" font-family="Arial" font-size="20.00" fill="#ffffff">Semantic Audit</text>
<text xml:space="preserve" text-anchor="start" x="808.81" y="-1136.16" font-family="Arial" font-size="20.00" fill="#ffffff">Skill: gloss&#45;audit</text>
<text xml:space="preserve" text-anchor="start" x="852.52" y="-1115.16" font-family="Arial" font-size="13.00" fill="#ffffff">SKILL.md</text>
<text xml:space="preserve" text-anchor="start" x="778.1" y="-1093.56" font-family="Arial" font-size="15.00" fill="#ffffff">High&#45;level verification checking</text>
<text xml:space="preserve" text-anchor="start" x="771.45" y="-1075.56" font-family="Arial" font-size="15.00" fill="#ffffff">manuscript claims, sample sizes,</text>
<text xml:space="preserve" text-anchor="start" x="750.18" y="-1057.56" font-family="Arial" font-size="15.00" fill="#ffffff">statistical summaries, and derived SVG</text>
<text xml:space="preserve" text-anchor="start" x="749.73" y="-1039.56" font-family="Arial" font-size="15.00" fill="#ffffff">geometric fidelity against bundle tables.</text>
</g>
<!-- skill_report -->
<g id="node6" class="node">
<title>skill_report</title>
<polygon fill="#7c3aed" stroke="#4e0cc3" stroke-width="0" points="1041.08,-1482.36 721.04,-1482.36 721.04,-1302.36 1041.08,-1302.36 1041.08,-1482.36"/>
<text xml:space="preserve" text-anchor="start" x="771.58" y="-1423.16" font-family="Arial" font-size="20.00" fill="#ffffff">Report Skill: gloss&#45;report</text>
<text xml:space="preserve" text-anchor="start" x="852.52" y="-1402.16" font-family="Arial" font-size="13.00" fill="#ffffff">SKILL.md</text>
<text xml:space="preserve" text-anchor="start" x="768.51" y="-1380.56" font-family="Arial" font-size="15.00" fill="#ffffff">Synthesizes traceable multi&#45;figure</text>
<text xml:space="preserve" text-anchor="start" x="739.74" y="-1362.56" font-family="Arial" font-size="15.00" fill="#ffffff">analysis reports backed by table rows, leaf</text>
<text xml:space="preserve" text-anchor="start" x="802.27" y="-1344.56" font-family="Arial" font-size="15.00" fill="#ffffff">IDs, and methods docs.</text>
</g>
<!-- gloss_mcp -->
<g id="node7" class="node">
<title>gloss_mcp</title>
<polygon fill="#7c3aed" stroke="#4e0cc3" stroke-width="0" points="1041.08,-1753.86 721.04,-1753.86 721.04,-1572.85 1041.08,-1572.85 1041.08,-1753.86"/>
<text xml:space="preserve" text-anchor="start" x="769.91" y="-1703.16" font-family="Arial" font-size="20.00" fill="#ffffff">Live R Bridge: gloss&#45;mcp</text>
<text xml:space="preserve" text-anchor="start" x="809.53" y="-1682.16" font-family="Arial" font-size="13.00" fill="#ffffff">Thin 4&#45;tool MCP Adapter</text>
<text xml:space="preserve" text-anchor="start" x="783.09" y="-1660.56" font-family="Arial" font-size="15.00" fill="#ffffff">Optional bridge for interactive</text>
<text xml:space="preserve" text-anchor="start" x="746.84" y="-1642.56" font-family="Arial" font-size="15.00" fill="#ffffff">RStudio/Positron sessions or million&#45;row</text>
<text xml:space="preserve" text-anchor="start" x="751.4" y="-1624.56" font-family="Arial" font-size="15.00" fill="#ffffff">tables: capture_figure, get_asset_map,</text>
<text xml:space="preserve" text-anchor="start" x="789.34" y="-1606.56" font-family="Arial" font-size="15.00" fill="#ffffff">query_slice, create_bundle.</text>
</g>
<!-- asset_map -->
<g id="node8" class="node">
<title>asset_map</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="2293.16,-839.36 1973.12,-839.36 1973.12,-659.36 2293.16,-659.36 2293.16,-839.36"/>
<text xml:space="preserve" text-anchor="start" x="2008.65" y="-789.16" font-family="Arial" font-size="20.00" fill="#ffffff">Asset Map (asset&#45;map.json)</text>
<text xml:space="preserve" text-anchor="start" x="2075.88" y="-768.16" font-family="Arial" font-size="13.00" fill="#ffffff">JSON (~tens of KB)</text>
<text xml:space="preserve" text-anchor="start" x="2019.72" y="-746.56" font-family="Arial" font-size="15.00" fill="#ffffff">Lightweight global catalog of page</text>
<text xml:space="preserve" text-anchor="start" x="1990.15" y="-728.56" font-family="Arial" font-size="15.00" fill="#ffffff">geometry, SVG digests, Engine IR (panels,</text>
<text xml:space="preserve" text-anchor="start" x="2013.09" y="-710.56" font-family="Arial" font-size="15.00" fill="#ffffff">layers, scales, orders), table column</text>
<text xml:space="preserve" text-anchor="start" x="1995.99" y="-692.56" font-family="Arial" font-size="15.00" fill="#ffffff">summaries, lineage, and source pointers.</text>
</g>
<!-- asset_bundle -->
<g id="node9" class="node">
<title>asset_bundle</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="2293.16,-569.38 1973.12,-569.38 1973.12,-373.33 2293.16,-373.33 2293.16,-569.38"/>
<text xml:space="preserve" text-anchor="start" x="2074.21" y="-532.16" font-family="Arial" font-size="20.00" fill="#ffffff">Asset Bundle</text>
<text xml:space="preserve" text-anchor="start" x="2042.55" y="-508.16" font-family="Arial" font-size="20.00" fill="#ffffff">(figure.gloss/ or .zip)</text>
<text xml:space="preserve" text-anchor="start" x="2032.18" y="-487.16" font-family="Arial" font-size="13.00" fill="#ffffff">UTF&#45;8 SVG + JSON + CSV + PNG</text>
<text xml:space="preserve" text-anchor="start" x="2029.32" y="-465.56" font-family="Arial" font-size="15.00" fill="#ffffff">Self&#45;contained portable bundle:</text>
<text xml:space="preserve" text-anchor="start" x="2031.85" y="-447.56" font-family="Arial" font-size="15.00" fill="#ffffff">manifest.json, asset&#45;map.json,</text>
<text xml:space="preserve" text-anchor="start" x="2024.76" y="-429.56" font-family="Arial" font-size="15.00" fill="#ffffff">omitted.json, assets/original.svg,</text>
<text xml:space="preserve" text-anchor="start" x="1990.98" y="-411.56" font-family="Arial" font-size="15.00" fill="#ffffff">scene/{scene.svg,leaves.json,elements.jso</text>
<text xml:space="preserve" text-anchor="start" x="2005.58" y="-393.56" font-family="Arial" font-size="15.00" fill="#ffffff">n,rasters/}, tables/{schema.json,*.csv},</text>
</g>
<!-- gloss_core -->
<g id="node10" class="node">
<title>gloss_core</title>
<polygon fill="#16a34a" stroke="#007c27" stroke-width="0" points="1707.12,-922.36 1387.08,-922.36 1387.08,-742.36 1707.12,-742.36 1707.12,-922.36"/>
<text xml:space="preserve" text-anchor="start" x="1447.61" y="-872.16" font-family="Arial" font-size="20.00" fill="#ffffff">gloss R Core Package</text>
<text xml:space="preserve" text-anchor="start" x="1428.24" y="-851.16" font-family="Arial" font-size="13.00" fill="#ffffff">R (&gt;= 4.2.0), svglite, xml2, jsonlite, digest</text>
<text xml:space="preserve" text-anchor="start" x="1412.03" y="-829.56" font-family="Arial" font-size="15.00" fill="#ffffff">Lightweight R core package: single&#45;draw</text>
<text xml:space="preserve" text-anchor="start" x="1424.53" y="-811.56" font-family="Arial" font-size="15.00" fill="#ffffff">device capture, Engine IR extraction,</text>
<text xml:space="preserve" text-anchor="start" x="1436.21" y="-793.56" font-family="Arial" font-size="15.00" fill="#ffffff">structural lineage, runtime source</text>
<text xml:space="preserve" text-anchor="start" x="1422.85" y="-775.56" font-family="Arial" font-size="15.00" fill="#ffffff">inventory, and open asset packaging.</text>
</g>
<!-- skill_gloss&#45;&gt;skill_refine -->
<g id="edge1" class="edge">
<title>skill_gloss&#45;&gt;skill_refine</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M317.22,-1259.19C334.39,-1244.4 351.82,-1229.09 368.04,-1214.36 400.15,-1185.19 405.14,-1174.62 438.04,-1146.36 530.47,-1066.96 639.52,-984.2 726.18,-920.8"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="727.55,-923.06 732.05,-916.52 724.45,-918.82 727.55,-923.06"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="451.04,-1146.36 451.04,-1171.36 638.04,-1171.36 638.04,-1146.36 451.04,-1146.36"/>
<text xml:space="preserve" text-anchor="start" x="451.04" y="-1157.36" font-family="Arial" font-size="14.00" fill="#c9c9c9">Delegates visual refinement</text>
</g>
<!-- skill_gloss&#45;&gt;skill_audit -->
<g id="edge2" class="edge">
<title>skill_gloss&#45;&gt;skill_audit</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M367.62,-1292.4C471.06,-1255.25 605.92,-1206.81 711.32,-1168.96"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="712.09,-1171.47 718.26,-1166.47 710.31,-1166.53 712.09,-1171.47"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="449.04,-1264.52 449.04,-1306.52 640.04,-1306.52 640.04,-1264.52 449.04,-1264.52"/>
<text xml:space="preserve" text-anchor="start" x="449.04" y="-1292.52" font-family="Arial" font-size="14.00" fill="#c9c9c9">Delegates statistical/caption</text>
<text xml:space="preserve" text-anchor="start" x="449.04" y="-1275.72" font-family="Arial" font-size="14.00" fill="#c9c9c9">verification</text>
</g>
<!-- skill_gloss&#45;&gt;skill_report -->
<g id="edge3" class="edge">
<title>skill_gloss&#45;&gt;skill_report</title>
<path fill="none" stroke="#8d8d8d" stroke-width="2" stroke-dasharray="5,2" d="M367.62,-1359.52C470.85,-1366.13 605.37,-1374.75 710.69,-1381.5"/>
<polygon fill="#8d8d8d" stroke="#8d8d8d" stroke-width="2" points="710.43,-1384.12 718.09,-1381.98 710.77,-1378.88 710.43,-1384.12"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="438.04,-1377.22 438.04,-1402.22 651.04,-1402.22 651.04,-1377.22 438.04,-1377.22"/>
<text xml:space="preserve" text-anchor="start" x="438.04" y="-1388.22" font-family="Arial" font-size="14.00" fill="#c9c9c9">Delegates multi&#45;figure reporting</text>
</g>
<!-- skill_gloss&#45;&gt;gloss_mcp -->
<g id="edge4" class="edge">
<title>skill_gloss&#45;&gt;gloss_mcp</title>
<path fill="none" stroke="#5d2cb2" stroke-width="2" stroke-dasharray="1,5" d="M367.62,-1423.57C471.16,-1472.02 606.19,-1535.2 711.64,-1584.55"/>
<polygon fill="#5d2cb2" stroke="#5d2cb2" stroke-width="2" points="710.46,-1586.89 718.37,-1587.69 712.68,-1582.14 710.46,-1586.89"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="447.54,-1552.83 447.54,-1577.83 641.54,-1577.83 641.54,-1552.83 447.54,-1552.83"/>
<text xml:space="preserve" text-anchor="start" x="447.54" y="-1563.83" font-family="Arial" font-size="14.00" fill="#ffffff">Optional live&#45;session queries</text>
</g>
<!-- skill_gloss&#45;&gt;asset_map -->
<g id="edge5" class="edge">
<title>skill_gloss&#45;&gt;asset_map</title>
<path fill="none" stroke="#026395" stroke-width="2" d="M331.68,-1259.02C345.3,-1245.2 357.89,-1230.22 368.04,-1214.36 430.48,-1116.82 381.09,-1064.2 438.04,-963.36 528.18,-803.75 554.21,-739.29 721.04,-663.36 1199.51,-445.57 1394.4,-488.84 1903.12,-621.36 1932.03,-628.89 1961.16,-640.96 1988.5,-654.75"/>
<polygon fill="#026395" stroke="#026395" stroke-width="2" points="1987.13,-657.01 1995,-658.11 1989.54,-652.34 1987.13,-657.01"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1130.08,-528.22 1130.08,-553.22 1298.08,-553.22 1298.08,-528.22 1130.08,-528.22"/>
<text xml:space="preserve" text-anchor="start" x="1130.08" y="-539.22" font-family="Arial" font-size="14.00" fill="#ddffff">Reads compact map first</text>
</g>
<!-- skill_gloss&#45;&gt;asset_bundle -->
<g id="edge6" class="edge">
<title>skill_gloss&#45;&gt;asset_bundle</title>
<path fill="none" stroke="#026395" stroke-width="2" d="M335.02,-1259.1C347.82,-1245.4 359.3,-1230.42 368.04,-1214.36 483.06,-1002.93 304.08,-877.32 438.04,-677.36 518.7,-556.95 583.7,-561.63 721.04,-515.36 1149.16,-371.12 1692.29,-411.77 1962.89,-445.85"/>
<polygon fill="#026395" stroke="#026395" stroke-width="2" points="1962.41,-448.43 1970.19,-446.78 1963.08,-443.22 1962.41,-448.43"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1111.08,-430.42 1111.08,-455.42 1317.08,-455.42 1317.08,-430.42 1111.08,-430.42"/>
<text xml:space="preserve" text-anchor="start" x="1111.08" y="-441.42" font-family="Arial" font-size="14.00" fill="#ddffff">Reads targeted CSV/SVG slices</text>
</g>
<!-- workbench&#45;&gt;asset_bundle -->
<g id="edge7" class="edge">
<title>workbench&#45;&gt;asset_bundle</title>
<path fill="none" stroke="#026395" stroke-width="2" d="M334.92,-987.88C347.82,-973.97 359.36,-958.72 368.04,-942.36 433.12,-819.68 339.35,-419.06 438.04,-321.36 669.41,-92.3 1597.12,-210.17 1903.12,-321.36 1935.04,-332.95 1966.98,-349.76 1996.44,-367.97"/>
<polygon fill="#026395" stroke="#026395" stroke-width="2" points="1994.78,-370.02 2002.53,-371.79 1997.57,-365.58 1994.78,-370.02"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1142.58,-206 1142.58,-231 1285.58,-231 1285.58,-206 1142.58,-206"/>
<text xml:space="preserve" text-anchor="start" x="1142.58" y="-217" font-family="Arial" font-size="14.00" fill="#ddffff">Opens .gloss dir / zip</text>
</g>
<!-- external_scripts&#45;&gt;asset_bundle -->
<g id="edge8" class="edge">
<title>external_scripts&#45;&gt;asset_bundle</title>
<path fill="none" stroke="#026395" stroke-width="2" d="M211.51,-707.55C220.95,-560.15 262.43,-278.53 438.04,-139.36 693.19,62.87 1624.22,28.61 1903.12,-139.36 1988.86,-190.99 2050.25,-288.47 2087.76,-364.5"/>
<polygon fill="#026395" stroke="#026395" stroke-width="2" points="2085.25,-365.34 2090.89,-370.94 2089.97,-363.05 2085.25,-365.34"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1133.58,-6.62 1133.58,-31.62 1294.58,-31.62 1294.58,-6.62 1133.58,-6.62"/>
<text xml:space="preserve" text-anchor="start" x="1133.58" y="-17.62" font-family="Arial" font-size="14.00" fill="#ddffff">Batch SQL / Python / JS</text>
</g>
<!-- gloss_mcp&#45;&gt;gloss_core -->
<g id="edge9" class="edge">
<title>gloss_mcp&#45;&gt;gloss_core</title>
<path fill="none" stroke="#5d2cb2" stroke-width="2" stroke-dasharray="1,5" d="M1028.55,-1572.95C1047.13,-1558.75 1065.18,-1543.41 1081.08,-1527.36 1264.63,-1342 1419.6,-1074.46 1495.69,-931.42"/>
<polygon fill="#5d2cb2" stroke="#5d2cb2" stroke-width="2" points="1497.98,-932.71 1499.17,-924.85 1493.34,-930.25 1497.98,-932.71"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1114.58,-1494.9 1114.58,-1519.9 1313.58,-1519.9 1313.58,-1494.9 1114.58,-1494.9"/>
<text xml:space="preserve" text-anchor="start" x="1114.58" y="-1505.9" font-family="Arial" font-size="14.00" fill="#ffffff">Calls 4 core functions in live R</text>
</g>
<!-- gloss_core&#45;&gt;asset_map -->
<g id="edge10" class="edge">
<title>gloss_core&#45;&gt;asset_map</title>
<path fill="none" stroke="#026395" stroke-width="2" d="M1706.92,-809.79C1786.28,-798.51 1882.35,-784.85 1963.08,-773.38"/>
<polygon fill="#026395" stroke="#026395" stroke-width="2" points="1963.3,-776 1970.35,-772.35 1962.56,-770.8 1963.3,-776"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1785.12,-798.29 1785.12,-823.29 1895.12,-823.29 1895.12,-798.29 1785.12,-798.29"/>
<text xml:space="preserve" text-anchor="start" x="1785.12" y="-809.29" font-family="Arial" font-size="14.00" fill="#ddffff">gl_asset_map()</text>
</g>
<!-- gloss_core&#45;&gt;asset_bundle -->
<g id="edge11" class="edge">
<title>gloss_core&#45;&gt;asset_bundle</title>
<path fill="none" stroke="#026395" stroke-width="2" d="M1693.6,-742.42C1775.91,-691.55 1879.18,-627.71 1964.83,-574.77"/>
<polygon fill="#026395" stroke="#026395" stroke-width="2" points="1966.02,-577.12 1971.02,-570.95 1963.26,-572.66 1966.02,-577.12"/>
<polygon fill="#18191b" fill-opacity="0.627451" stroke="none" points="1777.12,-684.19 1777.12,-709.19 1903.12,-709.19 1903.12,-684.19 1777.12,-684.19"/>
<text xml:space="preserve" text-anchor="start" x="1777.12" y="-695.19" font-family="Arial" font-size="14.00" fill="#ddffff">gl_asset_bundle()</text>
</g>
</g>
</svg>
`;default:throw Error(`Unknown viewId: `+e)}};export{e as dotSource,t as svgSource};