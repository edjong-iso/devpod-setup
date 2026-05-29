---
name: to-prd-perf
description: Turn the current conversation context into a performance-engineering PRD (kernels, sharding, fusions, memory, architecture experiments) and publish it to the project issue tracker. Use for perf/optimization work where "done" is defined by measured metrics + invariants, not user-facing behaviour. For feature/full-stack work, use to-prd instead.
---

This skill takes the current conversation context and codebase understanding and produces a **performance-engineering PRD**. Do NOT interview the user — just synthesize what you already know. (To stress-test the plan first, use `grill-me-perf`.)

The spine of a perf PRD is **measured metrics + invariants**, not user stories. There is usually no human actor — the consumer is a training run, an inference job, or the next engineer. A perf change that ships without evidence of where the cost currently goes is the thing reviewers should distrust most.

The issue tracker and triage label vocabulary should have been provided to you — run `/setup-matt-pocock-skills` if not.

## Process

1. Explore the repo to understand current state, if you haven't already. Use the project's domain glossary throughout and respect any ADRs in the area you're touching.

2. Identify the **isolatable units** you'll build or modify. A good perf unit is one you can **measure in isolation** — equivalence-check it against a reference *and* benchmark it standalone. (This replaces the usual "deep module with an interface that rarely changes" test: perf interfaces churn constantly under tuning, so interface stability is the wrong criterion.) Check with the user which units they want validated in isolation.

3. Write the PRD using the template below, then publish it to the project issue tracker. Apply the `ready-for-agent` triage label.

Do NOT include specific file paths or code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose (a spec, a shard rule, a kernel signature), inline the decision-rich part and note it came from a prototype.

<prd-template>

## Why — bottleneck / profile evidence

The measured reason this work is worth doing. Lead with evidence of where cost currently goes: profile/trace, current SPS/throughput, peak memory, the specific hot op / collective / dtype boundary, or a concrete engineering cost (e.g. an un-rebasable long-lived branch). Link the trace / W&B baseline. This is what motivates the work the way user stories motivate a feature — and it forces the "is this even the bottleneck?" question up front, the #1 way perf effort gets wasted.

## Baseline → Target

The measured starting point and the goal, in the same units.
- e.g. backward pass: 1.00x → ~1.18x SPS
- e.g. cross-device collectives: 1024-channel → 256-channel only
- e.g. peak memory: X GB → fits at sequence length N

## Invariants (must NOT change)

What must hold across the change. These are the things a perf bug would silently violate.
- numerical output within stated tolerance vs reference (or bit-exact where claimed)
- no new collectives / collectives only at the expected tensor width
- no new OOM / memory headroom preserved at target scale
- behaviour unchanged for out-of-scope paths (single-device, training mode, other call sites)

## Failure modes (silent risks)

Perf bugs run fine and produce subtly wrong numbers — enumerate what could go silently wrong and which validation gate catches each.
- numerics drift below tolerance → caught by equivalence gate
- runs-but-wrong sharding / unhandled spec → loud-fail principle (raise, don't fall through)
- a dropped dict key / silent default → strict=True, fail loudly
- OOM only at scale → memory gate in the regime sweep

**Loud-fail principle:** on an unrecognized spec / shape / regime, raise (NotImplementedError with the observed value) rather than silently falling through to a wrong-but-running path. Prefer `strict=True` on zips and explicit asserts over silent defaults.

## Units (measurable in isolation)

The kernels / modules / fusions / variants to build or modify, framed by whether each can be equivalence-checked and benchmarked standalone. Note interfaces are expected to churn under tuning — don't promise stable signatures.

## Validation gates

The protocol that defines "done." Every child issue inherits the CORE floor and selects the conditional gates its change touches. Validation is a property of each unit of work, not a separate phase.

**CORE floor (always — required to both define and close any perf issue):**
- numerical/behavioural equivalence vs a *named* reference within a *stated* tolerance (or bit-exact). State both.
- measured perf delta vs baseline — **only if the change claims a speedup/memory win.** Refactors and capability-enabling changes satisfy the floor with equivalence alone; do not invent a perf number.

**CONDITIONAL gates (include the ones the change touches):**
- sharding / multi-device → N-GPU correctness vs 1-GPU baseline within tol + HLO/collective inventory (count and tensor width)
- memory work → peak-memory / headroom / OOM check at target scale
- shape / dtype / training-mode changes → regime sweep (pow2 vs non-pow2, train vs infer, dtypes, GPU counts)
- any speedup claim → profiling trace + W&B/report link as evidence

## Out of scope

What this PRD deliberately does not cover, and any regimes explicitly gated off (e.g. backward pass, training-time, specific shapes).

## Further notes

Stack position and rebase risk if this is part of a stack or a long-lived branch (cross-ref `stack-this`). Any other context.

</prd-template>
