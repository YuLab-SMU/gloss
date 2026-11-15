# 2026-11-15 — M1 reflection: human labels and correspondence are narrower than the plan assumed

- **Related plan:** [plan/done/2026-11-11-m1-roles-and-binding.md](../plan/done/2026-11-11-m1-roles-and-binding.md) (closed)
- **Related ADRs:** [ADR-0007](../dev_docs/decisions/0007-derived-tables-of-the-substrate.md), [ADR-0008](../dev_docs/decisions/0008-held-out-role-labels-by-one-labeller-and-an-independent-sample.md), [ADR-0009](../dev_docs/decisions/0009-package-behaviour-enters-as-a-checked-proposal.md), [ADR-0010](../dev_docs/decisions/0010-targeted-human-audits-and-evidence-bearing-correspondence.md)
- **Worked on by:** Codex, following the owner's reflection after M1 closure.

## What changed

The next-step recommendation is revised from broad held-out role annotation to a semantic pilot with targeted audits. The role layer remains deterministic and derived. Correspondence remains available through evidence-bearing binding tables, while raw-row lineage and semantic correspondence are treated as separate questions.

## Measured

- M1 development classification run `2026-11-15-2239`: 33,231 of 33,243 elements classified, 100.0% role accuracy among classified elements, 0 silent errors, 12 explicit residues.
- M1 role labels: 54 figures, 7,108 leaves with elements and 33,243 elements. Pilot role κ 0.822 on 121 leaf units. Role-and-kind κ 0.664.
- Binding pilot from the closed agent path: raw material and substrate tool arms were right in 91.1% and 99.6% of 270 runs on the binding layer. Code enumeration answered 30/30 questions.
- The package suite was run on the current code before these documentation-only changes and exited successfully with no failures. The M1 closing log records 14 test files, 1,450 expectations, 0 failures and 0 skips.
- No held-out role annotation or new semantic pilot was run in this session.

## Surprises

- **Human labels do not currently move the role-layer decision.** The pilot measures agreement and guideline interpretation, while deterministic rules already have complete role agreement on the classified development elements. Broad human labelling would spend effort on a layer whose current question is already answered by code. → ADR-0010 and the design's evaluation section.
- **Data–figure correspondence has distinct evidence levels.** Some element-to-built-row pairings are checked, some remain ambiguous or unbound, and raw user-row lineage is a separate gap. Treating all of these as one binding completion number would overstate the result. → ADR-0010, the design's research card and the next plan.

## What's next

Open a plan for a semantic pilot. Start with a layer where code cannot fully decide truth, use targeted independent audits only where they can change the result, and report correspondence by evidence status. The record core remains an alternative next slice when product continuity has priority.
