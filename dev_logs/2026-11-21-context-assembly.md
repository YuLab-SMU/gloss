# 2026-11-21 — semantic context assembly and external agents

- **Related plan:** `plan/2026-11-21-context-assembly.md` (tasks 1–4 implemented,
  task 5 remains an evaluation slice).
- **Related ADRs:** [ADR-0011](../dev_docs/decisions/0011-external-agents-use-mcp-boundary.md).
  The existing checked-write and least-disclosure invariants remain in force.
- **Worked on by:** Codex

## What changed

- Added deterministic `gl_context_plan()` and `gl_context_assemble()` with
  intent inference, natural-language and structured focus resolution, bounded
  data rows, disclosure-aware table and record views, omission reasons and
  continuation actions.
- Added `assemble_context` to the relevant stage-scoped tools and the live
  `/api/context/assemble` endpoint.
- Added a Workbench question composer that sends the current focus and a human
  question to the live endpoint and displays the returned packet digest,
  selected evidence and deferred reads.
- Added `gl_mcp_session()`, `gl_mcp_tools()`, `gl_mcp_call()` and
  `gl_mcp_serve()`. The live `/mcp` endpoint handles MCP discovery and tool
  calls without loading `aisdk`; checked proposals commit through the existing
  stage commit path.
- Updated the design, plan, NEWS and generated documentation. The design now
  treats `aisdk` as an optional compatibility runner and records the external
  agent evaluation card.

## Measured

- Baseline before the slice: `NOT_CRAN=true Rscript -e "devtools::test()"` →
  25 files, 1705 expectations passed, 0 failures, 0 warnings and 0 skips.
- After the slice: the same command → 26 files, 1740 expectations passed,
  0 failures, 0 warnings and 0 skips in 276.8 seconds.
- Focus, packet, MCP, agent-stage and live endpoint tests were run separately
  while iterating. The new context assembly file contributed 23 passing
  expectations and the live endpoint file contributed 31 passing expectations
  in the final targeted run.
- Workbench `npm test` → 2 files, 7 tests passed. `npm run typecheck`,
  `npm run build:singlefile` and `npm run sync:r` completed, updating the
  bundled Workbench artifact.
- `Rscript -e "devtools::document(quiet=TRUE)"` completed without warnings on
  the final run.
- `gl_mcp_serve()` started on a free localhost port and stopped cleanly in an
  offline smoke test. The direct HTTP handler and live Workbench MCP route
  were covered by the test suite.
- No bench development or held-out figures were run. No model loop was run.
  The new benchmark comparison remains task 5 of the plan.

## Surprises

- A first natural-language query for `Mazda` matched every row because the row
  key vector was appended out of alignment during row-hay construction. The
  fixture caught this and the resolver now appends one key per row. → design
  doc `sec-context-assembly` and the new context fixture.
- `json_write()` encodes data frames as an internal `__df__` representation.
  The packet now converts selected rows, bindings and focus elements to named
  row objects so the live endpoint and MCP text content are directly usable by
  external clients. → plan task 2 and packet tests.
- A disclosure level initially affected context and data rows but left full
  semantic bodies visible. Table summaries and semantic record payloads now
  honor `none`, `schema`, `summary` and `rows`. → plan task 2 and the packet
  contract in `dev_docs/design.qmd`.
- MCP protocol revisions now include both handshake-based and newer discovery
  forms. The adapter accepts `initialize` and `server/discover` while keeping
  tool discovery and calls transport-neutral. Full transport compliance and
  external-client interoperability are still unmeasured. → plan task 5 and
  `dev_docs/design.qmd`.
- `R CMD check --no-manual --no-vignettes .` stops at the pre-existing
  DESCRIPTION metadata check for missing `Author` and `Maintainer` fields
  before running package tests. The source currently declares `Authors@R`, so
  this metadata issue is outside the context-assembly slice and remains
  visible for a later package-hygiene fix.

## What's next

Freeze a development set of figure questions and compare raw materials,
fixed-summary packets and assembled packets with the same external agent,
budget and tool-call cap. Report evidence recall and precision, unsupported
claim rate, focus errors, per-turn context degradation and packet cost before
using any held-out figures.

## Follow-up on 2026-11-22

- Added stage-readable semantic-layer scope to context plans and enforced the
  host disclosure ceiling in `assemble_context`.
- Added modern MCP per-request metadata and HTTP validation for protocol
  version, method, tool name, `Accept` and localhost `Origin`, while retaining
  the legacy `initialize` path. `server/discover` now returns
  `supportedVersions` and the standard server metadata shape.
- Added a JSON Schema regression for array item types and passed optional
  context sources through the live assembly endpoint.
- Final host suite: `NOT_CRAN=true Rscript` with the package test runner → 26
  files, 1758 expectations passed, 0 failures, 0 errors, 0 warnings and 0
  skips.
- Workbench checks: 2 Vitest files and 7 tests passed, TypeScript typecheck
  passed, single-file build completed at 2,443.71 kB before gzip, and the R
  bundle was synchronized.
- `R CMD build --no-build-vignettes .` and tarball `R CMD check --no-manual
  --no-vignettes` completed package checks. The check ended with 1 warning and
  1 note caused by the pre-existing untracked `City bike-share demand/.rho`
  directory included in the source tree. No files in that directory were
  changed.
- The held-out benchmark and external-client interoperability experiment were
  not run. They remain task 5 of the plan.

## Follow-up on 2026-11-22 — aisdk.mcp interoperability

- Inspected `YuLab-SMU/aisdk.mcp` at the current main revision. Its useful
  boundary is a shared client API over stdio, Streamable HTTP and legacy SSE,
  with `list_tools()`, `call_tool()`, `call_tool_data()` and injected
  transports for offline tests. Its server and tool-combination helpers remain
  coupled to `aisdk`.
- A local smoke test installed `aisdk.mcp` 0.1.3.1 beside the development
  package and used its `McpHttpClient` with an injected transport backed by
  `gloss:::mcp_dispatch`. The client listed the stage tools, assembled a
  focused packet with two selected rows at disclosure `rows`, and submitted a
  proposal that committed one checked record.
- This is evidence for the current model-independent MCP boundary and for
  borrowing the transport-neutral client and test patterns. It does not claim
  live Streamable HTTP, legacy SSE or stdio interoperability. Task 5 remains
  open for those measurements and for the context-value comparison.
