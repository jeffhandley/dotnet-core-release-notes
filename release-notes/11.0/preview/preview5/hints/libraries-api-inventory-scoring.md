---
scope: libraries
type: scoring
applies_when: "MediaTypeNames, MIME types, enum constants, string constants, nested class"
source: editorial feedback 2026-05-21
last_verified: 2026-05-21
---

# API inventory / enum constant additions

## Scoring guidance

Adding a nested class of string constants (like `MediaTypeNames.Video`) is essentially API inventory documentation — it follows an existing pattern and eliminates magic strings. Score these at **3–4** (not 6+).

Include them only if:
- The area is one most developers actively work with (e.g. widely-used serialization, networking, IO)
- There is a clear, concrete scenario the reader would recognize from their own code

`MediaTypeNames.Video` with MIME type constants is a convenience for code that deals with video content types. This is useful but narrow — most developers do not serve video over HTTP from .NET directly. **Score at 3–4 and group into a brief "API additions" bullet list rather than a standalone section.**

## Avoid "gains"

Do not use the word "gains" to introduce new APIs or features. Use "adds," "now includes," "supports," or a specific verb instead.
