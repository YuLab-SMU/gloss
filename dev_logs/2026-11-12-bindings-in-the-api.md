# 2026-11-12 — Bindings in the figure, the bundle and the API (M1 Task 6a)

- **Related plan:** [plan/2026-11-11-m1-roles-and-binding.md](../plan/2026-11-11-m1-roles-and-binding.md) (active; Task 6a done here; Tasks 1, 3, 4, 6b, 7, 8 and the legend item of Task 5 open).
- **Related ADRs:** [ADR-0007](../dev_docs/decisions/0007-derived-tables-of-the-substrate.md) (written here); [ADR-0009](../dev_docs/decisions/0009-package-behaviour-enters-as-a-checked-proposal.md); [ADR-0005](../dev_docs/decisions/0005-bundle-format-v0.md).
- **Worked on by:** Claude (Fable 5.2), on the owner's word after the review: "推送，实验室搜集数据先用已有的，不过结论很明确，人标注的远没有Claude 的准。绑定可以进api。我们使用自己部署的模型，magpie 中的westlakeHPC 模型都是免费的。其他你来决定就行". Follows [the retrospective](2026-11-12-retrospective.md).

Until today no exported function returned a binding. Now `gloss()` makes the bindings at capture, the figure and its bundle keep them, and `gl_bindings()` reads them. The step costs 7% to 18% of the capture on scatter plots of 10^3 to 10^5 points and adds 1.5% to 6.5% to their bundles; on a page of thousands of leaves it costs more than the capture itself.

## What changed

| Commit | What |
|---|---|
| pushed before this work, on the owner's word | `68f8091` (M1 decisions 4 and 5 settled), `8835020` (the demo tour tracked; `.rho/`, `.workbuddy/` and the tour's outputs ignored). [Pull request 1](https://github.com/YuLab-SMU/gloss/pull/1) opened from `feat/m0-substrate` to `main`; this work is on a new branch, `feat/agent-path` |
| `f078dd9` | `R/core-derived.R` (new: the derived table and its files in the bundle); `R/core-bind.R` (`derive_bindings()`, `gl_bindings()`, a group's rows returned by the check); `R/core-substrate.R` (`bind =`, `fig$derived`, the print line); `R/core-bundle.R`; format 0.2.0; `tests/testthat/test-bindings.R`; `NEWS.md`; `bench/R/runner.R` (capture with `bind = FALSE`); `dev_docs/research/bind-dev/d5-bind-cost.R` and `.out` |
| this commit | ADR-0007 and the index; design (the status note, §绑定假设也要能检查, §实施计划, the file-size risk, §与上一版的区别, Appendix A); the M1 plan (Task 6a's result, a Scope change); `README.md`; `dev_docs/demo/gloss-tour.R` (steps 3 and 9 on `gl_bindings()`); this log |

Decided on the owner's behalf under "其他你来决定就行", each the owner's to overturn: the pull request was opened and left for the owner to merge (a merge by me was refused by the permission check, and I did not look for a way round it); the untracked `bench/labels/pilot/owner/` was removed after checking that its files were byte-identical copies of tracked ones; ADR-0007 is marked Accepted on the owner's decision of 2026-11-11 and its points 2 to 6 are mine.

## Measured

- **Suite,** `NOT_CRAN=true Rscript -e "devtools::test()"`: 9 files / 109 tests / 807 expectations / 0 failed / 0 skipped before (`1f7aa1f`); 10 / 119 / 885 / 0 / 0 after (`f078dd9`), in three runs. The first of four host runs after the change had 1 failure, in "base leaves keep the counts read while replaying, also across clip changes". I did not capture its message. It did not recur: the test took 11.1, 11.6 and 11.5 s in the three runs that followed, against its limit of 30 s.
- **Container,** `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/suite.R`: 10 / 119 / 885 / 0 failed / 0 errors / 0 skipped / 0 warnings (R 4.5.2, aarch64-unknown-linux-gnu).
- **The new tests failed first:** `test-bindings.R` run before any change under `R/` stopped at the reporter's limit of 10 failures (`gl_bindings` did not exist).
- **Time and size** (`dev_docs/research/bind-dev/d5-bind-cost.R`, host, hand-built figures; times the median of 3):

  | points | panels | capture, s | bind step, s | single file, KB | with bindings, KB | added, KB |
  |---|---|---|---|---|---|---|
  | 10^3 | 1 | 0.22 | 0.03 | 160.3 | 166.8 | 6.5 |
  | 10^4 | 1 | 0.59 | 0.05 | 661.9 | 676.8 | 14.9 |
  | 10^5 | 1 | 5.38 | 0.43 | 2717.0 | 2811.4 | 94.4 |
  | 10^3 | 4 | 0.32 | 0.04 | 200.7 | 207.6 | 6.9 |
  | 10^4 | 4 | 0.72 | 0.13 | 1811.9 | 1839.5 | 27.6 |
  | 10^5 | 4 | 5.49 | 0.39 | 3115.0 | 3319.1 | 204.0 |

- **Many leaves** (same script, one run each): a base page of 500, 1000, 2000 and 5000 `segments()` calls captures in 0.25, 0.39, 0.79 and 1.92 s and binds in 0.80, 1.52, 3.23 and 8.63 s, 1.5 to 1.7 ms a leaf; every leaf verified.
- **Plain against compact storage,** the element table of the 10^5-point scatter: about 575 KB of the single file as plain JSON (881 KB with unrounded deviations), 93 KB as integers.
- **On the development sets,** an estimate from archived runs (bind run minus capture run, per figure; the capture run sniffs context, the bind run does not): median 0.12 s, 90th percentile 0.68 s, maximum 55.0 s (gallery-029, 4011 leaves) on v0's 54; median 0.21 s, maximum 0.70 s on the tree stratum's 29.
- **Lines:** 501 added, 26 removed under `R/` and `tests/` (`git diff --shortstat 8835020..f078dd9 -- R tests`); 192 of them the test file.
- `quarto render dev_docs/design.qmd --to html`: exit 0. `fact_diff.py` between the design before and after: nothing missing.
- **Not run:** the bench (no number of it should change: its capture step passes `bind = FALSE`, and `bind_capture()` is as it was); `R CMD check`; the bind step inside `gloss()` on any bench figure; a 0.2.0 bundle read by the 0.1.0 reader.

## Surprises

- **The bind step is not small on a page of many leaves.** I expected a share of the capture like the scatters' everywhere. A base page of 5004 leaves binds in 8.6 s and captures in 1.9 s, and gallery-029's 55 s in the archived bind run is the same thing: 4011 leaves. A profile puts 30% under `data.frame()` and 30% under `%in%`. My first fix, looking each claim's elements up once, took a profiled run from 9.04 s to 8.68 s, so the scan was not the cost, and I dropped the change. → M1 plan, Scope change of 2026-11-12; ADR-0007 (*Negative*, *Follow-ups*, *Revisit when*). Not fixed.
- **One failed run I cannot explain.** The first full host run after the change failed the 5000-segment capture test once. I assumed the 30 s limit and wrote that into the commit message before checking; the message was not captured, three later runs passed at about 11 s, and I amended the commit to say only what was seen. With bindings made at capture that test has 19 s of margin where it had about 28. → nowhere yet: if it fails again, its message decides.
- **The 3 MiB check covers one figure.** The same 10^5 points in four coloured panels give 3115 KB with no bindings at all. The criterion "10^5 points under 3 MB" was met on the figure it was written for and is not a property of 10^5 points. → design §风险与未决问题 (the file-size item, dated note).
- **Plain storage would have failed that check.** I had planned to store the tables with the codec as it was. Measured first, the element table alone was about 575 KB of the single file. → ADR-0007 point 5 and its evidence; the compaction is kept only where it expands back exactly, and tables under 10000 rows stay plain text.
- **Two captures of one plot do not have identical substrates.** grid numbers its grobs anew, so leaf paths differ between captures while every element is the same. Two of my new tests compared whole substrates and were wrong. → the tests compare elements; nowhere else.
- **A binding names a built row, and the car in the demo is still found by value.** Step 3 of the tour now goes element → `built_layer1` row through `gl_bindings()`, checked, and then from the built row to the row of `mtcars` by matching `wt` and `mpg`. → M1 plan Task 7 (the data tree), where it already is; `README.md` says so.
- **The bench would have silently changed what its capture time means.** `gloss()` now binds by default, and the runner timed `gloss(fig)`. → `bench/R/runner.R` passes `bind = FALSE`, in the same commit as the default.

## What's next

- **The agent-path plan,** `plan/2026-11-12-agent-path.md`, opened next: read-only tools over the substrate and one validating `propose`, through aisdk, then a pilot of the decisive comparison on development figures with the owner's westlakeHPC models. Its riskiest assumption is that a free model drives tools reliably at all, so that is measured first.
- **Waiting on the owner:** pull request 1; reading ADR-0007.
- **Open in the M1 plan:** Task 1's full development labels by annotator A (settled by decision 4, not started); Tasks 3, 4, 6b, 7, 8.
- **Deferred with their sizes:** the per-leaf cost of the bind step (1.7 ms a leaf; one development figure above 5 s); the deferred code gaps listed in the retrospective.
