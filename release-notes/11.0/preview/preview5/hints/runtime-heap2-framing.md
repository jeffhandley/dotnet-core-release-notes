---
scope: runtime
type: editorial
applies_when: "HEAP2, heap dump, dotnet-dump, dump collection"
source: https://github.com/dotnet/runtime/pull/127321
last_verified: 2026-05-21
---

# HEAP2 heap dump framing

## Lead with speed, not format

The primary user benefit of HEAP2 is **faster dump collection** — smaller files mean less I/O time when collecting a dump, which matters especially in production scenarios. The size reduction is the mechanism; the benefit is speed.

**Preferred framing:** "Heap dumps now collect faster. The new HEAP2 format is more compact, reducing typical dump sizes by 10–30%, which translates directly to shorter collection windows."

**Avoid:** Framing HEAP2 primarily as a format change or a metadata-richness story. Don't lead with "richer metadata" or "more accurate type resolution" — those are tool-quality improvements, not the primary win.

## Link to authoritative format documentation

If citing "HEAP2 format," link to an authoritative resource explaining the format rather than leaving it as unexplained jargon. If no clean public doc exists, describe it briefly inline: "HEAP2, a more compact heap dump format."
