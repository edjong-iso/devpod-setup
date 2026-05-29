---
name: to-issues-perf
description: Break a performance-engineering plan or PRD into independently-grabbable issues sliced by validatable change (kernels, sharding, fusions, memory, architecture experiments). Use for perf/optimization work. For feature/full-stack work, use to-issues instead.
---

# To Issues (perf)

Break a perf plan into independently-grabbable issues, sliced by **independently-validatable change** — not by layer (schema/API/UI). Perf work has no such layers; its natural grain is "one self-contained change you can measure against the baseline on its own and land without leaving a broken intermediate state."

The issue tracker and triage label vocabulary should have been provided to you — run `/setup-matt-pocock-skills` if not.

## Core principle: validation is a property of the issue

Validation is not a phase you run at the end — it is built into each issue's lifecycle:
- **Definition gate:** an issue is *malformed* if its acceptance criteria contain no validation steps. No validation = not a real issue.
- **Closure gate:** an issue *cannot be closed* without validation evidence attached (the numbers / trace / HLO inventory / `[OK]` leaves).

## Process

### 1. Gather context

Work from whatever is in the conversation context. If the user passes an issue reference, fetch its full body and comments.

### 2. Explore the codebase (optional)

If you haven't, explore to understand current state. Use the project's domain glossary and respect ADRs in the area you're touching.

### 3. Draft slices (by validatable change)

Each slice is **one self-contained perf change** — a kernel migration, a swapped module, a fusion, a sharding rule, an architecture variant.

<slice-rules>
- A slice can be equivalence-checked and (if it claims a win) benchmarked against the baseline on its own.
- A slice lands atomically — no intermediate state where the code is double-wrapped, half-sharded, or otherwise broken.
- An **enabling sub-change rides inside the slice that needs it** when separating it would create a broken intermediate (e.g. a kernel relaxed to accept sharded shapes co-commits with the sharding that requires it). Don't split it into its own issue just for tidiness.
- Prefer many thin slices over few thick ones — but see "landing unit" below: a slice is a validation/commit boundary, not necessarily its own PR.
</slice-rules>

Slices may be **HITL** (need a human — an architectural decision or design review) or **AFK** (implementable and mergeable without human interaction). Prefer AFK where possible.

### 4. Quiz the user

Present the breakdown as a numbered list. For each slice show: **Title**, **Type** (HITL/AFK), **Blocked by**, **Validation** (floor + which conditional gates), and **Landing unit** (own PR vs commit in a stacked PR). Ask:
- Does the granularity feel right (too coarse / too fine)?
- Are the dependency relationships correct?
- Should the landing units differ from the slicing (e.g. a clean re-port that must land as one reviewable stacked PR)?
- Are the correct slices marked HITL vs AFK?

Iterate until approved.

### 5. Publish in dependency order (blockers first)

<issue-template>
## Parent

Reference to the parent issue / PRD (omit if none).

## What to build

The end-to-end perf change this slice delivers. Avoid file paths and code snippets (they go stale); exception: a prototype snippet that encodes a decision (a shard rule, kernel signature, spec) more precisely than prose — inline the decision-rich part and note it came from a prototype. Note any enabling sub-change that co-commits with this slice.

## Validation (definition gate — required)

**Floor (always):**
- [ ] Numerical/behavioural equivalence vs <named reference> within <stated tolerance> (or bit-exact)
- [ ] Measured perf delta vs baseline — *only if this slice claims a win; omit for pure refactors/enabling changes*

**Conditional gates (keep only what this change touches):**
- [ ] Sharding/multi-device → N-GPU correctness vs 1-GPU within tol + HLO/collective inventory (count + width)
- [ ] Memory → peak-memory / headroom / OOM at target scale
- [ ] Shape/dtype/training-mode → regime sweep (pow2/non-pow2, train/infer, dtypes, GPU counts)
- [ ] Speedup claim → profiling trace + W&B/report link

Closure gate: this issue cannot be closed until the evidence for the boxes above is attached.

## Instrumentation (strip before merge)

Any dev-only flags / harness / scaffolding needed to *validate* this slice but not shipped (e.g. force-a-codepath flags, comparison dumps). Omit if none.

## Blocked by

Reference to blocking slice(s), or "None - can start immediately".

## Stack / landing

- **Landing unit:** own PR, or a commit within a stacked PR (cross-ref `stack-this`). A clean re-port often lands as one reviewable stacked PR even though it's many validated slices.
- **Rebase risk:** low/med/high — long-lived perf branches go stale fast when main churns the same files; flag it.

</issue-template>

Do NOT close or modify any parent issue.
