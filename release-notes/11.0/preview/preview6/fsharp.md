# F# in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new F# features and bug fixes:

<!-- toc -->

- [`InlineIfLambda` for `Array.init`](#inlineiflambda-for-arrayinit)
- [Improved debugger stepping for `for` expressions](#improved-debugger-stepping-for-for-expressions)
- [Compiler warnings and diagnostics](#compiler-warnings-and-diagnostics)
- [Bug fixes](#bug-fixes)
- [Community contributors](#community-contributors)

<!-- tocstop -->

F# updates in .NET 11:

- [What's new in F# 9](https://learn.microsoft.com/dotnet/fsharp/whats-new/fsharp-9)

## `InlineIfLambda` for `Array.init`

`Array.init` now carries the `[<InlineIfLambda>]` attribute on its function parameter. When you pass a lambda directly to `Array.init`, the compiler can inline the lambda into the generated loop body — eliminating the delegate call overhead and enabling the JIT to optimize the inner loop as if you had written the initialization inline ([dotnet/fsharp #19869](https://github.com/dotnet/fsharp/pull/19869)).

```fsharp
let arr = Array.init 1000 (fun i -> i * i)
// The lambda is now inlined; no delegate allocation or indirect call.
```

## Improved debugger stepping for `for` expressions

The F# debugger experience for `for` loops has been reworked. Debug points are now emitted in positions that correctly reflect the programmer's intent: the loop header, the body, and the continuation are each individually steppable, making it possible to step into, over, and out of `for` expressions naturally. This also fixes conditional erasure so that optimized-away expressions don't produce stray step events ([dotnet/fsharp #19894](https://github.com/dotnet/fsharp/pull/19894), [dotnet/fsharp #19897](https://github.com/dotnet/fsharp/pull/19897)).

## Compiler warnings and diagnostics

Several new diagnostic improvements land in Preview 6:

- **FS3888 — consumer-visible attributes missing from `.fsi`**: The compiler now warns when a declaration's attribute is visible to consumers but is absent from the corresponding `.fsi` signature file. This catches cases where attributes (like `[<Obsolete>]` or `[<EditorBrowsable>]`) are silently dropped from the public API surface ([dotnet/fsharp #19880](https://github.com/dotnet/fsharp/pull/19880)).
- **`[<CompiledName>]` inconsistency warning**: A new warning fires when `[<CompiledName>]` is applied inconsistently across overloads of an extension method — different overloads compiling to different IL names confuse interop callers ([dotnet/fsharp #19737](https://github.com/dotnet/fsharp/pull/19737)).
- **FS1182 for unused `let` functions in class types**: The "unused binding" warning now correctly fires for unused `let`-bound functions defined inside class types, matching the behavior for module-level functions ([dotnet/fsharp #19805](https://github.com/dotnet/fsharp/pull/19805)).

## Bug fixes

- Fixed `let _ = &expr` not compiling like `let x = &expr` ([dotnet/fsharp #19811](https://github.com/dotnet/fsharp/pull/19811)).
- Fixed non-deterministic reference assembly MVIDs ([dotnet/fsharp #19801](https://github.com/dotnet/fsharp/pull/19801)).
- Fixed SRTP `get_Item` witness resolution for `string` indexers ([dotnet/fsharp #19757](https://github.com/dotnet/fsharp/pull/19757)).
- Fixed parser error for anonymous record type aliases with postfix type operators when the closing bracket is column-aligned ([dotnet/fsharp #19762](https://github.com/dotnet/fsharp/pull/19762)).
- Fixed duplicate editor diagnostics by reverting a Roslyn workaround that was no longer needed ([dotnet/fsharp #19812](https://github.com/dotnet/fsharp/pull/19812)).
- Fixed NuGet restore stdout appearing under `fsi --quiet` ([dotnet/fsharp #19808](https://github.com/dotnet/fsharp/pull/19808)).
- Fixed a double `Dispose` in `use` bindings with `as` patterns ([dotnet/fsharp #19858](https://github.com/dotnet/fsharp/pull/19858)).
- Fixed incorrect colorization of type names in `MyType<Qualified.Name>.StaticMember` expressions ([dotnet/fsharp #19800](https://github.com/dotnet/fsharp/pull/19800)).
- Fixed type alias preservation in `match | null` refinement ([dotnet/fsharp #19745](https://github.com/dotnet/fsharp/pull/19745)).
- Fixed XmlDoc validation for get/set property pairs ([dotnet/fsharp #19884](https://github.com/dotnet/fsharp/pull/19884)).
- Fixed degraded codegen for inner recursive functions under `realsig` ([dotnet/fsharp #19882](https://github.com/dotnet/fsharp/pull/19882)).
- Fixed quotations leaking empty-string match lowering into AST ([dotnet/fsharp #19923](https://github.com/dotnet/fsharp/pull/19923)).
- Fixed ICE on named-arg indexer setter ([dotnet/fsharp #19851](https://github.com/dotnet/fsharp/pull/19851)).

## Community contributors

Thank you to the community contributors who contributed to F# in this preview:

- [@kerams](https://github.com/kerams) — `InlineIfLambda` for `Array.init` ([dotnet/fsharp #19869](https://github.com/dotnet/fsharp/pull/19869))
- [@auduchinok](https://github.com/auduchinok) — Emit debug points at stack-empty position; improved debugger `for` stepping ([dotnet/fsharp #19877](https://github.com/dotnet/fsharp/pull/19877), [dotnet/fsharp #19894](https://github.com/dotnet/fsharp/pull/19894), [dotnet/fsharp #19897](https://github.com/dotnet/fsharp/pull/19897))
