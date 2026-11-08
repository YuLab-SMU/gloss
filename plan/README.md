# plan

Forward-looking phase plans. Each plan covers a coherent slice of work with task-by-task tracking. Files here are **committed work**, unlike `idea/` (exploration).

## Conventions

- **Filename:** `YYYY-MM-DD-<slug>.md`, dated when the plan opens.
- **One plan per coherent phase.** The milestones in [`dev_docs/design.qmd`](../dev_docs/design.qmd) (M0–M5) are the natural phases.
- **Status discipline:** `[ ]` not started, `[~]` in progress, `[x]` done (record the verification command), `[!]` blocked (note the blocker), `[-]` cancelled (note the reason).
- **Update immediately, never batch.**
- **Never silently rewrite a `[x]` task.** Append a "Scope Change — YYYY-MM-DD" note instead.
- **When a plan closes:** move it to `plan/done/` and write a closing `dev_logs/` entry.

## Template

See [`_template.md`](_template.md).

## Active plans

_(none yet)_ — next: M0 (plugin registry, substrate, row-key inference, context sniffing, bundle read/write).

## Completed plans

_(none yet)_
