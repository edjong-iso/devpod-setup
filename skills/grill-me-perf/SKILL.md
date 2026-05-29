---
name: grill-me-perf
description: Interview the user relentlessly about a performance-engineering plan or design (kernels, sharding, fusions, memory, architecture experiments) until reaching shared understanding, primed with the perf decision tree. Use when the user wants to stress-test a perf plan or mentions "grill me" on optimization work. For general/feature plans, use grill-me.
---

Interview me relentlessly about every aspect of this perf plan until we reach shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead of asking.

This is performance-engineering work, so also press hard on the perf decision tree below. Resolve earlier branches before later ones (a target is meaningless without a baseline; a tolerance is meaningless without a named reference):

1. **Baseline** — what is it, on what shapes / GPU count / bucket / config, and how was it measured? Is it the right baseline?
2. **Target** — what's the goal and what single metric tells you you hit it (SPS, peak memory, collective width, …)?
3. **"Still correct"** — equivalence against *which* reference, within *which* tolerance? Bit-exact, or a stated atol/rtol?
4. **Regression vs noise** — how will you distinguish a real numerics regression from expected shard/accumulation noise?
5. **Invariants** — what must NOT move (collective width, dtype counts, no new OOM, out-of-scope codepaths unchanged)?
6. **Regimes** — what must it hold across: train vs infer, pow2 vs non-pow2 shapes, GPU counts, dtypes?
7. **Failure mode discipline** — on an unhandled spec/shape/regime, does it raise loudly or silently fall through to wrong-but-running? (Recommend: raise.)
8. **Stack / rebase risk** — does this depend on or block other work, and how stale will it get against main? (cross-ref `stack-this`.)

Not every branch applies to every perf task — skip the ones that don't, but don't skip a branch just because it's uncomfortable to answer.
