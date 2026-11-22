# ADR-0011: External agents use a model-independent MCP boundary

- **Status:** Accepted
- **Date:** 2026-11-21
- **Deciders:** Yonghe Xia
- **Related:** [ADR-0009](0009-package-behaviour-enters-as-a-checked-proposal.md), [ADR-0010](0010-targeted-human-audits-and-evidence-bearing-correspondence.md), [context assembly plan](../../plan/2026-11-21-context-assembly.md), [context assembly dev log](../../dev_logs/2026-11-21-context-assembly.md)

## Context

gloss needs to support a person's agent across data, algorithms, code,
documents, user context and figure semantics. The existing `aisdk` runner is
useful for the package's scripted R-stage workflow, but making it the required
agent boundary would tie a domain substrate to one development-time model SDK.
The substrate already has stage-scoped read-only tools and one checked write
path. The missing piece was a task-specific context packet and a stable way
for an external agent to call those capabilities.

## Evidence

- The repository's core and semantic store load without `aisdk`; it is already
  listed under `Suggests`.
- The context assembly fixture resolves natural-language focus to data rows,
  includes checked bindings and anchored records, and reports omitted reads.
- The final host suite passed 26 files and 1758 expectations with no failures,
  warnings or skips. The live Workbench test covers `/api/context/assemble`,
  modern and legacy discovery, `tools/list` and `tools/call`.
- `gl_mcp_serve()` started on a free localhost port and stopped cleanly in an
  offline smoke test. No external model or client was used.
- A local interoperability smoke test used `aisdk.mcp` 0.1.3.1's
  `McpHttpClient` with an injected transport connected to gloss's dispatch
  function. The client completed the handshake, listed the stage tools,
  assembled a focused packet and submitted a checked proposal that committed
  one record. This exercises the JSON-RPC tool contract without claiming a
  live network transport result.

## Decision

gloss exposes a model-independent MCP tool boundary and keeps `aisdk` as an
optional compatibility runner for `gl_annotate()`.

1. `gl_context_plan()` and `gl_context_assemble()` create deterministic,
   bounded packets from a question, focus, disclosure level and evidence
   state. They do not call a model or write the figure.
2. `gl_mcp_session()`, `gl_mcp_tools()` and `gl_mcp_call()` expose the same
   stage-scoped tools to an embedding client. `propose`, `resolve` and
   `repair` still commit only through the checked stage path.
3. `gl_mcp_serve()` and the live Workbench `/mcp` route provide a local
   single-response Streamable HTTP tool surface. Modern requests carry the
   protocol version in body metadata and HTTP headers, and the adapter checks
   method, tool name and Origin. The older `initialize` form remains available
   for legacy clients. The implementation remains independent of an MCP SDK.
4. gloss does not own a model loop, memory policy, routing policy, permission
   policy or retry policy. The external agent owns those choices and receives
   provenance, focus, omissions and continuation actions from the packet.

## Alternatives considered

- **Require `aisdk` for all agents.** Rejected because it makes external
  agents and non-R hosts depend on a package-internal orchestration choice.
- **Add a second model-specific SDK adapter.** Rejected because every new SDK
  would duplicate the checked tool boundary and increase the core's domain
  coupling.
- **Make `aisdk.mcp` a gloss dependency.** Rejected because its server and
  tool-combination helpers are intentionally tied to `aisdk`, while gloss only
  needs the MCP boundary and must remain usable by a user's own agent.
- **Expose only a free-form HTTP endpoint.** Rejected because the agent needs
  discoverable JSON Schemas and the existing tool permissions, while the
  transport should remain replaceable.

## Consequences

### Positive

- A user's existing agent can reuse gloss without configuring `aisdk`.
- Human turns in the Workbench and external tool calls use the same context
  packet and checked write path.
- Model, memory, routing and permissions can vary without changing the
  substrate or semantic records.

### Negative / accepted tradeoffs

- The current R adapter implements the single-response Streamable HTTP shape
  and the legacy initialize form. Other transport revisions and external
  client combinations remain unmeasured.
- External-client interoperability, model accuracy and context-value metrics
  remain unmeasured and are task 5 of the context assembly plan.
- The injected-transport smoke test covers the shared JSON-RPC shape only.
  It does not cover a real Streamable HTTP exchange, legacy SSE, stdio, or
  server-initiated requests.
- A live server is local and unauthenticated by default. Deployment policy
  stays with the host application.

## Revisit when

- A conforming MCP client fails against the tool discovery or call surface in
  a reproducible fixture.
- The context evaluation shows that the packet contract cannot express a
  needed evidence boundary or that the external-agent surface reduces
  evidence recall materially.
- A future standard transport requires a change to session state or response
  framing that cannot be added as a separate adapter.
