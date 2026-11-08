# dev_docs

Long-lived engineering documentation. Unlike `dev_logs/` (append-only history) or `plan/` (phase plans), the design here is **the current truth** and is rewritten as the system evolves. The research material is the exception: it is kept as researched.

## Index

- [`design.qmd`](design.qmd) — The design (Chinese): six capabilities, core model, agent layer, storage, plugins, package layout, tests, milestones, settled decisions.
- [`research-report.qmd`](research-report.qmd) — Prior art and measured evidence (Chinese). Written 2026-11-07 while the work was incubated in ggai; only file paths were updated after the move.
- [`research/`](research/README.md) — Archive of scripts, captures and raw reports behind the report. `research/capture-groups/` holds the spikes behind ADR-0001 and the classify / hierarchy measurements.
- [`figures/`](figures/) — Figures used by the report.
- [`decisions/`](decisions/README.md) — ADRs.

## Rendering

```sh
quarto render dev_docs/design.qmd --to html
quarto render dev_docs/research-report.qmd --to html
```

Rendered outputs are gitignored.
