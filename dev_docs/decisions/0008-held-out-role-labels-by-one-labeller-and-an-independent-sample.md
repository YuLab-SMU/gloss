# ADR-0008: Held-out role labels: annotator A labels every figure, people label a seeded sample independently

- **Status:** Accepted
- **Date:** 2026-11-11
- **Deciders:** Yonghe Xia (2026-11-11, on Claude's proposal, after labelling the pilot)
- **Related:** plan/2026-11-11-m1-roles-and-binding.md (Task 1, Scope changes of 2026-11-11); dev_logs/2026-11-11-m1-plan.md; bench/predictions.md (predictions 28–31, 43–52); design §评测设计. The number 0007 is kept for the decision the same plan names in its Task 6.

## Context

Design §评测设计 says that element roles on the held-out set are labelled by two people, independently, to a guideline written first, with Cohen's κ reported and disagreements settled by consensus. The pilot of that guideline (five development figures) was the first time a person labelled against it. The owner labelled all five, looked at the labels of annotator A (Claude, who wrote the guideline) and asked why people should label at all, A's being the more correct ones.

The answer cannot be "they label better". A writes the guideline, the labels and the rules that will be scored against the labels; a mistake the three share scores as correct. People are the only part A did not make. What the pilot changes is how much of them is needed, and for what.

## Evidence

- A against the owner, five figures, 121 leaves (`Rscript bench/R/score-labels.R agree bench/labels/pilot/claude bench/labels/pilot/team/yonghe bench/labels/pilot/sheets`): κ on roles 0.822, agreement 0.876. On the two figures labelled before A's examples were shown 0.651; on the three after, 0.856. Resampling leaves: 0.737 to 0.901, 29% of draws below 0.8.
- Of the 15 leaves that differ, the guideline's text decides 14 for A's label and leaves one open (a watermark). So a person labelling from scratch departs from the guideline on about one leaf in eight, and where two people would disagree with each other the consensus would be reached by reading the same text.
- After seeing A's labels the owner changed 4 leaves, each to A's. A check made with the answer in view agrees with it.
- A person's cost: 3.0 to 15.3 active minutes a figure, median 5.3 (17 s a leaf). The held-out set has 54 figures.
- Not yet measured: any lab member's labels. One human annotator and five figures do not place κ on one side of 0.8; predictions 43–44 and 48–49 say what the others are expected to show.

## Decision

On the held-out set, annotator A labels the role and kind of every leaf of every captured figure; people label a seeded sample of the figures independently, without A's labels or each other's; agreement and every disagreement are reported, and A's labels stand for the unsampled figures only if the sample supports them.

This covers element roles (the classification layer, M1). Rows that the deterministic layer cannot bind, relations and the truth of claims keep the two-person rule of the design until a pilot of their own says otherwise.

1. **Order.** The rule set is frozen at a tag first. Then A labels the held-out figures from the page, the sheet and the code, never from a rule's output, and the labels are committed before any rule runs on the held-out set. (With two people labelling, this order did not matter; with A labelling it does: A also writes the rules, and rules written after A has read the held-out leaves would be tuned on them.)
2. **Sample.** Drawn by seed, stratified by engine: at least one third of the held-out figures and at least three of each engine (all of an engine with fewer). A figure above the leaf cap is labelled on a seeded sample of its leaves. The seed, the size and the cap are fixed in the plan that labels the held-out set, before any label is made, and not below this floor.
3. **Independence.** Every sampled figure is labelled by at least two people in the team workbench, which shows no one another's labels before their own are frozen. The guideline version is frozen before the first label. No one who labels has seen a rule's output on the figure.
4. **What is reported.** κ on roles (and on role and kind) of A against each person and between people, with intervals from resampling figures; every leaf on which A differs from a person, read against the guideline's text with the reason, proposed by A and ruled by the owner; A's error rate on the sample after that ruling, with its interval, as the uncertainty of the labels on the figures no person labelled.
5. **Labels of record.** A's labels, with the rulings applied on the sample. If the rulings show a class of leaf that A labels wrongly, A relabels that class on every held-out figure before any score is computed, and this is reported as a change made after looking at the sample.
6. **Fallback.** If on the sample the median of A's pairwise κ against the people is below 0.8, or A's error rate after the rulings is above 5% of the sampled leaves, two people label every held-out figure, as the design first said, and the rules are scored against their consensus.

## Alternatives considered

- **Two people label every figure** (the design as written). Some ten hours of people's time for 54 figures, twice; the pilot suggests their disagreements would mostly be departures from the guideline, settled by its text. Kept as the fallback.
- **A labels every figure and people correct A's labels.** Cheapest, and not a check: the owner's four changes after seeing A's labels all went to A's.
- **A labels every figure and no one checks.** The labeller writes the rules; nothing independent is left.

## Consequences

### Positive

- People's time goes where it is the only independent evidence, and every figure still gets a label made before any rule ran.
- A's error rate against people is a reported number with an interval, instead of being assumed away by a consensus.

### Negative / accepted tradeoffs

- On the unsampled two thirds a mistake of A's is seen only through its rate on the sample. A rare class of leaf may not be in the sample at all.
- A mistake that the guideline itself carries is reproduced by A and by people who follow it; agreement does not test the guideline's validity.
- Reviewers will ask who labelled the held-out set. The answer is "the model that wrote the rules, checked on a sample by people who saw neither"; it rests on points 1, 3 and 6 being kept and shown.
- Rules cannot be changed after A has labelled the held-out set without the change being a change made after looking.

### Follow-ups

- Design §评测设计 (the rule on human labels, the metrics table, the research card) and §与上一版的区别: dated notes, in this commit.
- The workbench needs a way to label a sample of a figure's leaves before the held-out sample is drawn (the development set has five figures of 129 to 4011 leaves).
- The plan that labels the held-out set fixes seed, size and cap, and commits predictions for point 6's two numbers.

### Revisit when

- The pilot's lab members come in below what predictions 44 and 49 expect (A's median κ against people under 0.75 on the fifteen figures): A's labels start from a worse prior and the fallback may be taken from the start.
- The sample's rulings find a class of leaf A labels wrongly in more than one engine.
- Another label type (bindings, relations, claims) is proposed for the same treatment: it needs its own pilot and its own ADR.
