# dev_docs

Long-lived engineering documentation. Unlike `dev_logs/` (append-only history) or `plan/` (phase plans), the design here is **the current best explanation**, rewritten as the system evolves: a dated note records a correction when it is made, and the notes a plan added are folded into the text when the plan closes. It can still lag the code; the code, the tests and the measurements say what gloss does (`AGENTS.md`). The research material is the exception and is kept as it was researched.

## Index

- [`design.qmd`](design.qmd): the design (Chinese). It opens with the five decisions and the evidence for each, marking every number as measured or design-only. It then gives one section per decision, followed by risks and open questions, milestones, settled decisions, and appendices with the full planned interface, package layout and glossary.
- [`research-report.qmd`](research-report.qmd): prior art and measured evidence (Chinese). Written on 2026-11-07 while the work was incubated in ggai; only file paths were updated after the move.
- [`research/`](research/README.md): archive of the scripts, captures and raw reports behind the report. `research/capture-groups/` holds the spikes behind ADR-0001 and the classification and hierarchy measurements that the design doc cites.
- [`figures/`](figures/): figures used by the research report, with the design doc's figures in `figures/design/`. Each design figure has its source in `figures/design/src/` (R scripts for data figures, SVG for schematics); the AI-generated hero image has a `.prompt.md` sidecar.
- [`decisions/`](decisions/README.md): ADRs.

## Rendering

```sh
quarto render dev_docs/design.qmd --to html
quarto render dev_docs/research-report.qmd --to html
```

Rendered outputs are gitignored. To rebuild the design figures, see [`figures/design/src/README.md`](figures/design/src/README.md).
