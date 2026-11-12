# dev_logs

The feedback record. One file per session or unit of work, `YYYY-MM-DD-<slug>.md`. Each says what was measured, what surprised us and where each surprise went; plans and the design doc are adjusted from it.

## Conventions

- **Append-only.** To correct a past log, add a dated note in a later one; don't edit the old file.
- **Numbers, not impressions.** "Tests pass" is not a result. Give the command and what it printed, and the figure set it ran on.
- **Say what was not run.** A check that was skipped, or a path that was never exercised, is written down as such.
- **Every surprise is routed.** Each item under *Surprises* ends with where it went: a plan scope change, a design doc note, an ADR, a risk, an `idea/` note, or "nowhere yet" with the reason.

[`2026-11-09-m0-substrate.md`](2026-11-09-m0-substrate.md) is a worked example; its "Things the design did not anticipate" is what *Surprises* means.

## Format

```markdown
# YYYY-MM-DD — <title>

- **Related plan:** plan/<file> (status; open tasks)
- **Related ADRs:** ...
- **Worked on by:** ...

## What changed

Code and docs, briefly; a table of files when there are many.

## Measured

Commands and their output, before → after where it applies:

- suite: files, tests, expectations, failures, skips (`NOT_CRAN=true Rscript -e "devtools::test()"`);
- the numbers the work was meant to move (coverage, size, time, hit rate), with the figure set they ran on;
- what was not run, and why.

## Surprises

What the plan or the design did not anticipate, one bullet each, ending with where it went
(→ plan scope change / design doc / ADR-NNNN / risk / idea / nowhere yet, because ...).

## What's next

Derived from the measurements and surprises above, not copied from the milestone table.
```
