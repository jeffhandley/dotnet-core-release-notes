---
scope: sdk
type: fact
applies_when: "#:ref, #:include, #:exclude, #:project, #:sdk, file-based app, FBA, directives"
source: https://github.com/dotnet/sdk/issues/52532
last_verified: 2026-05-21
---

# File-based app directive semantics

This is a factual constraint. Do not write anything that contradicts these semantics.

## Directive meanings

- `#:include <path>` / `#:exclude <path>` — adds or removes files from the virtual project. The item type is inferred from the file extension (e.g. `.cs` → `Compile`, `.resx` → `EmbeddedResource`). The mapping is extensible via MSBuild. These are NOT NuGet-related.
- `#:ref <other-fba.cs>` — references one file-based app (FBA) from another. Maps to `ProjectReference`. This is app-to-app referencing, NOT a NuGet package reference. The "app" concept includes libraries produced by FBAs.
- `#:project <path.csproj>` — references a `.csproj` project. Maps to `ProjectReference`.
- `#:sdk <SdkName>` — references an SDK.
- `#:package <id>` or similar — for NuGet package references (if applicable).

## Common mistakes to avoid

- Do NOT describe `#:ref` as "NuGet package references" — it is FBA-to-FBA referencing.
- Do NOT show a `.csproj` path as a `#:ref` example — use `#:project` for `.csproj` files.
- The correct description of `#:ref`: "references another file-based app (which may produce a library), mapping to a `ProjectReference` under the hood."
