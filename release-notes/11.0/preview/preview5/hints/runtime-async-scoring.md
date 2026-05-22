---
scope: runtime
type: scoring
applies_when: "runtime-async, JIT async, suspend/resume, async state machine, RuntimeAsyncValueTaskMethodBuilder"
source: editorial feedback 2026-05-21
last_verified: 2026-05-21
---

# Runtime-async internal improvements

## Scoring guidance

Runtime-async implementation improvements (suspend/resume path optimizations, JIT codegen tweaks for async frames, register spill reductions) are **sausage-making** — they are ongoing internal work on a feature that is already announced.

**Score these at 0–3** unless:
- There is a concrete, measurable user-visible outcome with benchmark data (e.g. "X% throughput improvement on workload Y")
- A new user-facing API or option was added
- A previously broken or unavailable scenario now works

**Do not include** as a standalone section entries that read like: "we optimized the suspend/resume path," "we reduced register spills," "we improved branch prediction on hot paths." These belong in a filtered-features comment or a brief bullet under an existing runtime-async section if one exists.

## When runtime-async *does* warrant inclusion

A state change (opt-in → default, experimental → stable) is worth documenting. An incremental internal optimization is not.
