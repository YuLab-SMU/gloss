# Visual semantic pilot: prepared views for agent proposals

> Status: active
> Date opened: 2026-11-15. Owner: Codex.

**Goal:** Measure whether a deterministic visual evidence view helps an agent propose semantic relations and claims, while the original device geometry and the check gate remain authoritative.

**Why now:** The closed claim pilot showed that code can verify a trend, while wording, open-world meaning and missing mappings still need proposals or audit. The owner suggested adding visual capability, especially a deliberately prepared figure view, before committing to a larger agentic semantic route.

**Research-card clause:** The main comparison's semantic part: whether the substrate plus an agent can improve proposal quality without reducing coverage or allowing unchecked facts. This plan isolates the visual input as a new condition before a real-model study.

**Starting state (measured):** `NOT_CRAN=true Rscript -e "devtools::test()"` on 2026-11-15: 17 test files, 1477 expectations, 0 failures, 0 skips. The semantic claim pilot has one deterministic `trend` check, a five-proposal offline fixture and three owner-resolved audit cases. No visual condition has been measured.

**Assumptions to test:**

1. A prompt-side visual evidence view can make elements, panels and candidate relations easier to locate without changing the figure's geometry or leaking a binding answer. Task 1 tests this with structural and pixel checks.
2. The same model and budget can produce better semantic proposals from the prepared view than from text-only substrate context. Task 2 tests this on claims and relations; a tie is still useful evidence.
3. The visual view does not turn plausible language into verified fact. Task 3 keeps every proposal behind the same schema/check gate and reports false-acceptance and audit load separately.

**Architecture:** Generate a separate, deterministic prompt artifact from the captured substrate: the original figure, numbered element callouts, panel/layer labels, and optional zooms. The artifact is presented to the agent only; it is never stored as the figure's geometry or used as the checker's source of truth. Compare text-only and visual conditions on the same frozen semantic cases and budget. Keep record persistence and anchor rebasing in the next M2 slice.

**Out of scope:** Real-model claims before the visual artifact contract is tested, replacing the original figure, image-generation model edits to geometry, append-only record storage, anchor rebasing, broad human labelling, and benchmark-wide conclusions.

**Tech stack:** R, existing substrate tables and geometry, `xml2`/SVG or a deterministic rasterizer, testthat 3, and the existing offline proposal harness. Optional vision-model runs remain gated and archived separately.

**Done when:**

- the prepared view is reproducible and its annotations are provably outside the source geometry;
- the same semantic cases run in text-only and visual conditions with proposal source, status, coverage, audit load, tokens and time recorded;
- no failed, partial, refused or speculative proposal is promoted to a verified fact;
- the result says whether to proceed to M2 records first, or to run a real-model visual ablation.

---

## Progress tracking

**Status legend**
- `[ ]` Not started
- `[~]` In progress
- `[x]` Completed
- `[!]` Blocked
- `[-]` Cancelled

**Current state** _(update as results come in)_
- Suite: 17 files, 1477 expectations, 0 failures, 0 skips.
- Key numbers: prepared view has 12 labelled elements across 2 panels; source scene hash is `f046477e...c67d`; repeated PNG hash is `92a37f...a114`. The visual condition is not yet compared with an agent; the text-only semantic fixture has 1 verified code proposal and 3 audited cases.

**Overall progress**
- [x] Task 1: Define and verify the prepared visual evidence artifact.
- [-] Task 2: Run the text-only versus visual proposal fixture. _(Deferred; the prepared artifact remains reusable for the later agent evaluation.)_
- [x] Task 3: Decide whether to add a real vision-model ablation before M2 records. _(Route: start M2 records and anchors first, per the owner's `/goal 完成M2` request.)_

---

### Task 1: Prepared visual evidence artifact

**Status:** `[x]`

**Tests assumption:** Assumption 1.

**Files**
- Create: `bench/semantic/vision/` generator and fixture outputs; tests for artifact integrity if package code is touched.
- Modify: this plan and the dev log.

**Intent**
- Make the visual condition explicit and reproducible: source figure, stable element labels, panel/layer key and optional zooms. Keep annotations in a separate prompt artifact so the graphics-device geometry remains untouched.

**Verification**
- Render the same fixture twice and compare hashes.
- Check that source primitives and dimensions are unchanged, every callout points to an existing element, and no binding row is printed into the visual artifact.

**Result** _(filled in when done)_
- `Rscript bench/semantic/vision/make_view.R` → deterministic prompt-side view with 12 element labels across 2 panels. The source scene hash is `f046477e...c67d`; the repeated prepared PNG hash is `92a37f...a114`; metadata records `contains_binding_answers = false`. The view is archived in `bench/runs/2026-11-15-visual-view/`.
- Visual inspection confirms the original points remain visible, panel guides and element IDs are legible, and the prepared overlay is separate from the source SVG. Cost: 1 generator (128 lines) and 4 visual artifact files; no package source or test changes.

---

### Task 2: Text-only versus visual proposal fixture

**Status:** `[-]` — Deferred in favour of the M2 record and anchor slice; no model comparison was run.

**Tests assumption:** Assumption 2.

**Files**
- Create: frozen visual proposal cases and scorer under `bench/semantic/vision/`.
- Modify: `bench/runs/` archives, this plan and the dev log.

**Intent**
- Hold model identity, task wording, budget and checker constant. Vary only whether the agent receives text-only substrate context or the prepared visual evidence view.

**Verification**
- Report proposal correctness/coverage, verified/failed/partial/refused/speculative counts, audit queue size, token cost and time by condition.
- Keep the offline fixture separate from any real-model run.

**Result** _(filled in when done)_
- Deferred by the route decision below; no model run was made and no comparison number is claimed.

---

### Task 3: Route decision

**Status:** `[x]`

**Tests assumption:** Assumption 3.

**Intent**
- Use the visual pilot's evidence to choose between a real-model visual ablation and M2 record/anchor implementation. Preserve the hard rule that only checked proposals can become verified records.

**Verification**
- Update `plan/README.md`, `dev_docs/design.qmd`, and a closing `dev_logs/` entry with the measured route.

**Result** _(filled in when done)_
- Route decision recorded 2026-11-15: defer a real vision-model ablation and proceed to M2 records and anchors. The prepared view is retained for a later controlled agent comparison.

---

## Scope changes

_(append-only; the route decision below is the only scope change.)_

- 2026-11-15 — The owner requested `/goal 完成M2`; the visual artifact contract was complete, but no text-only versus visual model run had been made. Task 2 is deferred and Task 3 routes the next slice to M2 records and anchors. The artifact remains in `bench/runs/2026-11-15-visual-view/` for a later evaluation.

## Closing notes

The visual artifact is complete and archived; the comparative model run is deferred. The plan closes with M2 as the next slice.
