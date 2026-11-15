# ADR-0010: Targeted human audits for semantic layers; correspondence stays evidence-bearing

- **Status:** Accepted
- **Date:** 2026-11-15
- **Deciders:** Yonghe Xia
- **Related:** [ADR-0008](0008-held-out-role-labels-by-one-labeller-and-an-independent-sample.md), [ADR-0007](0007-derived-tables-of-the-substrate.md), [ADR-0009](0009-package-behaviour-enters-as-a-checked-proposal.md), [dev log](../../dev_logs/2026-11-15-m1-reflection.md)

## Context

M1 measured the role layer on 54 captured development figures. The deterministic rules classified 33,231 of 33,243 labelled elements, with 100% role accuracy among classified elements, zero silent errors and 12 explicit residues. The five-figure pilot gave role κ 0.822 and role-and-kind κ 0.664. The disagreements mostly exposed guideline interpretation and missing examples. Broad human annotation did not add a decision-changing signal at this semantic layer.

M1 also showed that element-to-built-row correspondence can be checked for some engine paths while other cases remain ambiguous, unbound or count-mismatched. The binding table does not establish a complete mapping back to the user's original rows or to the meaning of a claim.

## Evidence

- `dev_logs/2026-11-15-m1-role-rules.md` records the final development classification and the role checks.
- `dev_logs/2026-11-15-m1-role-labels.md` records the pilot agreement and the full development label coverage.
- The M1 binding run records checked, ambiguous and explicitly unbound elements by engine in `plan/done/2026-11-11-m1-roles-and-binding.md`.
- The agent-path pilot found 30/30 binding questions answerable by code enumeration, with raw-material and substrate model arms at 91.1% and 99.6% on that layer. The difference was mainly cost and completion, not a stable accuracy gap.

## Decision

The current role layer uses deterministic engine rules plus targeted audits. Human annotation is reserved for semantic layers where code cannot derive the answer, including claims, relations and open-world correspondence.

1. The next role-layer work does not begin with broad held-out human annotation. A targeted audit may sample residues, disputed kinds or newly observed failure classes when its result could change a rule, a scope decision or a reported number.
2. Correspondence is reported as evidence with an explicit status. `verified` means the stored comparison passed. `ambiguous` means multiple candidates remain. `unbound` and `count_mismatch` preserve the reason that code could not establish the pairing. None of these statuses implies a complete mapping to the user's original data frame or to a semantic claim.
3. Programmatic completeness is not a completion criterion for the correspondence layer. The API keeps the evidence-bearing derived tables because some pairings are established and useful. The unresolved part moves to checked proposals, records or later semantic experiments.
4. The next evaluation plan starts with a semantic pilot that measures where code can decide, where a model can propose, and whether a targeted human audit changes the result. The pilot determines whether a larger held-out study is worth its cost.

## Alternatives considered

- **Keep ADR-0008's broad held-out role annotation as the next gate.** Rejected because the M1 role evidence and pilot did not show a decision-changing benefit at this layer.
- **Force every element to a raw-data row.** Rejected because M1 measured genuine ambiguity, missing engine cues and package-specific drawing behavior.
- **Remove programmatic correspondence entirely.** Rejected because the verified subset is reproducible and useful when its evidence status is exposed.

## Consequences

### Positive

- Human effort moves to claims and relations, where the current code has less authority.
- Reports distinguish established geometry from unresolved lineage and semantics.
- The next experiment tests the riskiest remaining claim instead of expanding a low-yield annotation protocol.

### Negative / accepted tradeoffs

- Role accuracy on unseen figures will be reported from deterministic checks and targeted audits rather than a broad human-labelled role set.
- The correspondence API exposes a useful partial result and leaves gaps visible. It does not promise raw-row provenance for every element.

### Follow-ups

- Update the evaluation section and the next plan to remove broad held-out role annotation as the default first task.
- Keep human annotation requirements for claims, relations and other semantic layers open until their own pilot measures the value.
- Report correspondence by status and engine, with raw-row lineage as a separate question.

### Revisit when

- A targeted audit changes a role rule or a reported role metric in a material way.
- A semantic pilot shows that human labels are required to establish its truth or to calibrate a check.
- A new engine contract makes a previously unresolved correspondence deterministically checkable.
