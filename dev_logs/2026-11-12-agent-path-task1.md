# 2026-11-12 — The agent-path plan opened; the free models drive tools (Task 1)

- **Related plan:** [plan/2026-11-12-agent-path.md](../plan/2026-11-12-agent-path.md) (active, opened here; Task 1 done; Tasks 2 to 6 open). [plan/2026-11-11-m1-roles-and-binding.md](../plan/2026-11-11-m1-roles-and-binding.md) stays active.
- **Related ADRs:** [ADR-0007](../dev_docs/decisions/0007-derived-tables-of-the-substrate.md), [ADR-0009](../dev_docs/decisions/0009-package-behaviour-enters-as-a-checked-proposal.md).
- **Worked on by:** Claude (Fable 5.2), on the owner's word of 2026-11-12 ("我们使用自己部署的模型，magpie 中的westlakeHPC 模型都是免费的。其他你来决定就行"). Follows [the log of Task 6a](2026-11-12-bindings-in-the-api.md).

The first model-driven runs in this project. Three free models each drove a loop of tools over a gloss figure to a validated submission in 10 of 10 runs, in a lookup variant and in a masked one. The task was too easy to say anything else: no submission was ever rejected.

## What changed

| Commit | What |
|---|---|
| `cce1bab` | `plan/2026-11-12-agent-path.md` (new); `plan/README.md`; `bench/agent/drive-tools.R`; predictions 102-107 |
| `dca7905` | the run's archive, unscored; the scorer; the stamp in UTC |
| this commit | the score file; predictions 102-107 scored; Task 1's result and a Scope change in the plan; this log |

Nothing under `R/` or `tests/` changed. aisdk is not in `DESCRIPTION`: the harness is under `bench/`.

## Measured

- **Dry run, no model** (`Rscript bench/agent/drive-tools.R --dry`): for each of the five questions and both variants the tools reach the checked row, a wrong row is rejected with its distance and the right one accepted.
- **The run** (`Rscript bench/agent/drive-tools.R`, host, gateway, aisdk 1.5.0, at `cce1bab`; archive `bench/runs/2026-11-12-1627-drive-tools.*`; scored by `bench/agent/score-drive-tools.R`):

  | model | correct, L | correct, M | median calls, L / M | median seconds, L / M | median tokens, L / M |
  |---|---|---|---|---|---|
  | glm-5.3-flash | 10 of 10 | 10 of 10 | 4 / 5 | 9.7 / 16.0 | 5156 / 8226 |
  | deepseek-v4.1-flash | 10 of 10 | 10 of 10 | 5 / 6 | 5.1 / 4.7 | 6976 / 10110 |
  | Qwen3.8-27B | 10 of 10 | 10 of 10 | 5 / 6 | 6.7 / 8.2 | 7505 / 11149 |

  60 runs in 9.2 minutes and 504923 tokens. Failed calls 0 of 313. Rejected submissions 0. Errors 0. Longest run 28.5 s.
- **Predictions 102-107:** 4 right of 6 (`bench/predictions.md`).
- **`R CMD check --no-manual`** on a tarball built in a fresh directory, read from that directory: Status OK; no development directory in the tarball. Run after Task 6a, before the model runs.
- **Suite:** not run again; nothing under `R/` or `tests/` changed since `f078dd9` (host and container 10 files / 119 tests / 885 expectations / 0 failed / 0 skipped).
- **Not run:** any bench figure; condition A; a model other than these three; more than two repeats.

## Surprises

- **The masked variant was no harder than the lookup.** I guessed 8, 9 and 5 of 10; all three models got 10. One figure with one layer and a tool that returns the nearest rows leaves nothing to get wrong. → plan, Scope change (a): the pilot's questions come from figures where a first answer can be wrong, by a rule fixed before the runs.
- **The validation never fired.** I predicted at least one rejection followed by an accepted submission. There were 0 rejections in 60 runs. The entry point the design rests on has not been exercised by a model once. → plan, Scope change (b): the pilot reports first-submission rejections per condition, and says so if there are none.
- **Models went round the tools.** Three masked runs never called `to_data` and two lookup runs never called `get_binding`; all five were correct. In one, Qwen asked for the rows near data values it had not been given, which the scales in `overview` yield for the circle's place; in another, glm read rows 1 to 10 and submitted the right one. A model with the scales and the rows does not need the binding handed to it on a figure like this, which is the rival explanation of the research card (the substrate is only a convenience) seen on one example. → plan, Scope change (a) and (c); nowhere else yet, since one figure decides nothing.
- **Temperature 0 does not repeat.** The two runs of one model, variant and question took the same path of tools in 16 of 30 pairs. → plan, Scope change (d).
- **My stamp was in the wrong timezone.** The harness stamped its archive in Asia/Shanghai time, a day ahead of the UTC stamps of every other run. Caught on listing the archive, before committing it. → the files renamed and the script fixed in `dca7905`, with the fact written in the commit and in `bench/predictions.md`.
- **aisdk calls out on its own.** Its first call printed "Testing for internet connectivity via https_proxy... success!". I did not look at what it requests. → nowhere yet: to be read before aisdk enters `Suggests` (Task 3), since the bench container has no network and a tool that probes the internet will behave differently there.

## What's next

- **Task 2,** no model: can a pairing be checked from the figure alone, measured against the capture-time bindings on both development sets in the container. It decides what `propose` rests on.
- **Then** Task 3 (tools and `propose` in the package, aisdk in `Suggests`), Task 4 (condition A's sandbox) and Task 5 (the pilot), each written out from the task before it.
- **Waiting on the owner:** pull request 1; reading ADR-0007; the branch `feat/agent-path` is not pushed.
