# 2026-11-21 — semantic context assembly

## Starting state

- Host suite: `NOT_CRAN=true Rscript -e "devtools::test()"` → 25 files,
  1705 expectations passed, 0 failures, 0 warnings and 0 skips.
- Research-card clause: the substrate should give an agent a smaller,
  checkable context than the raw figure materials, while preserving the
  evidence needed to challenge a claim.
- Current gap: `gl_context()` exposes sniffed items and `gl_tools()` exposes
  read-only queries, but no value in the package plans or materialises a
  task-specific context packet. The Workbench can focus a figure, but that
  focus is not yet a recorded input to agent context.

## Working hypothesis

An agent will be easier to steer and audit when it receives a deterministic
context plan and a bounded packet that names included sources, omitted sources,
focus resolution, evidence status and available follow-up reads. The first
implementation must remain model-agnostic and must not turn a heuristic intent
guess into a scientific conclusion.

## Tasks

- [x] **1. Define the context plan and packet contract.** Add an intent-aware
  planner with deterministic focus resolution, disclosure and row/character
  budgets. The output records reasons and omissions. Verified by
  `test-context-assembly.R` and the full host suite.
- [x] **2. Materialise the packet from substrate, records and context.** Include
  checked bindings, relevant records/checks, selected rows, context slices and
  continuation actions. Add unit tests for focus, omission and JSON safety.
  Verified by 34 passing expectations in the new context fixture and the full
  host suite.
- [x] **3. Expose the packet to agent tools and the live Workbench.** Add a
  read-only assembly tool and a live endpoint. Do not add a model loop to gloss.
  The external MCP endpoint supports modern per-request metadata and headers,
  Origin checks, discovery, tool listing and checked calls, while retaining a
  legacy `initialize` path. Verified by the stage-tool, live endpoint and MCP
  tests.
- [x] **4. Connect the Workbench's natural-language focus and human turns.**
  Reuse the existing outline/focus resolver and send a structured focus plus the
  user's question to the live endpoint. Keep proposal submission behind the
  existing checked write path. Verified by Workbench typecheck, 7 Vitest tests,
  and the single-file build.
- [ ] **5. Measure context value and revise the plan.** Compare raw-material,
  fixed-summary and assembled-packet conditions on development figures. Record
  token/cost, evidence retrieval, unsupported-claim rate and failure modes before
  touching any held-out figures.

## Completion criteria for this slice

1. `gl_context_plan()` and `gl_context_assemble()` are public, JSON-safe and
   deterministic for the same figure, question, focus and disclosure.
2. The packet distinguishes figure facts, checked evidence, semantic records,
   contextual sources, omissions and next reads.
3. A selected element or natural-language focus query resolves to the relevant
   data rows and anchored records when the substrate can support that mapping;
   unresolved focus is reported explicitly.
4. Stage-scoped packets respect the host's readable semantic layers and
   disclosure ceiling.
5. The full host suite remains green with counts recorded in the closing log.

The external-agent extension adds `gl_mcp_session()`, `gl_mcp_tools()`,
`gl_mcp_call()`, `gl_mcp_serve()` and the live `/mcp` route. It is covered by
offline JSON-RPC and checked-commit fixtures. It does not yet claim complete
interoperability with every MCP transport revision. The boundary decision is
recorded in [ADR-0011](../dev_docs/decisions/0011-external-agents-use-mcp-boundary.md).

## Scope change policy

If the first fixture shows that a deterministic packet cannot represent a
needed evidence boundary, stop and record the mismatch here before adding model
selection or a conversation loop. Do not infer domain meaning from geometry.

## Scope change

- **2026-11-21:** User requested external-agent use through MCP so the package
  does not narrow the domain around `aisdk`. The plan now treats `aisdk` as an
  optional compatibility runner and exposes the same tools through a
  transport-neutral MCP interface. Full external-client evaluation remains in
  task 5.
- **2026-11-22:** Modern MCP request metadata and HTTP headers are validated at
  the local endpoint, and the packet planner records stage-readable semantic
  layers. The deterministic implementation slice remains complete. External
  client interoperability and model comparisons remain task 5.
