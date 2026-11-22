# 2026-11-22 — technical route and architecture diagrams

- **Related plan:** `plan/2026-11-21-context-assembly.md` remains open at task 5. This documentation slice did not change the plan tasks.
- **Related ADRs:** [ADR-0011](../dev_docs/decisions/0011-external-agents-use-mcp-boundary.md) is reflected in the external-agent boundary shown in the architecture diagram.
- **Worked on by:** Codex

## What changed

- Added the Diagram Design Steps asset for the M0–M6 route and the next external-agent interoperability slice.
- Added the Diagram Design Architecture asset for inputs, gloss core, plugin registration, tool boundary, bundle/context and projections.
- Added a Chinese route and architecture summary with code entry points, implementation status, architecture constraints and the next evaluation gate.
- Added the asset index under `dev_docs/figures/diagram-design/` and linked the summary from `dev_docs/README.md`.

## Measured

- `NOT_CRAN=true Rscript -e "devtools::test()"` → 26 files, 1758 expectations passed, 0 failures, 0 warnings and 0 skips in 277.5 seconds.
- `python3 scripts/self_check.py --offline` from the Diagram Design skill → both HTML files passed.
- `python3 scripts/verify_geometry.py` → 2 files, 0 findings.
- `python3 scripts/verify-steps.py gloss-technical-route.html` → passed.
- `export_svg.py` and `rsvg-convert` produced both SVG and PNG exports. Both PNGs were inspected after rendering.
- Browser `lint-render.py` did not complete because the environment had no Playwright Chromium executable. A `python3 -m playwright install chromium` attempt stalled at the 0% download stage and was stopped. No browser-lint result is claimed.
- No R implementation, benchmark figure set or model evaluation changed in this slice.

## Surprises

- The skill's Steps verifier expects its shipped paper and ink tokens, two-digit step numbers and a medallion for every rail. The route asset was adjusted to that contract while keeping milestone codes in the stage titles. → nowhere yet, because this is a local diagram validation contract and does not change gloss behavior.

## What's next

Freeze the development questions, model, budget, disclosure level and tool-call cap for the context-value comparison. Add real Streamable HTTP, legacy SSE and stdio interoperability runs before treating the external-agent boundary as complete.
