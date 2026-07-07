# F# in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new F# language features and compiler improvements:

<!-- toc -->

- [InlineIfLambda on Array.init](#inlineiflambda-on-arrayinit)
- [Improved for expression debugger stepping](#improved-for-expression-debugger-stepping)
- [Compiler diagnostics improvements](#compiler-diagnostics-improvements)
- [Bug fixes](#bug-fixes)
- [Community contributors](#community-contributors)

<!-- tocstop -->

F# updates in .NET 11:

- [What's new in F# 9](https://learn.microsoft.com/dotnet/fsharp/whats-new/fsharp-9)

## InlineIfLambda on Array.init

`Array.init` now uses `[<InlineIfLambda>]` on its body parameter
([dotnet/fsharp #19869](https://github.com/dotnet/fsharp/pull/19869)).

When the initializer function is a lambda, the compiler can now inline it
directly at the call site, eliminating the overhead of a function call per
element. This benefits tight loops that initialize arrays with computed values:

```fsharp
// The lambda is inlined — no per-element function call overhead
let squares = Array.init 1_000_000 (fun i -> i * i)
```

The change brings `Array.init` in line with other collection functions that
already use `[<InlineIfLambda>]`.

## Improved for expression debugger stepping

The debugger step-through experience for `for` expressions has been improved
([dotnet/fsharp #19894](https://github.com/dotnet/fsharp/pull/19894)).

Previously, stepping through `for` loops in the debugger could skip lines or
land on the wrong statement. The rework ensures that:

- Each loop iteration starts at the correct sequence point.
- The loop variable binding is visible before the body executes.
- Stepping over the loop header moves to the first statement in the body as expected.

Debug points are also now emitted at stack-empty positions
([dotnet/fsharp #19877](https://github.com/dotnet/fsharp/pull/19877)),
which prevents stale variable values from appearing in the debugger when
stepping between statements.

## Compiler diagnostics improvements

**`[<CompiledName>]` consistency warning.** The compiler now warns when
extension overloads of the same name are decorated with inconsistent
`[<CompiledName>]` attributes
([dotnet/fsharp #19737](https://github.com/dotnet/fsharp/pull/19737)).

Inconsistent `[<CompiledName>]` values produce unexpected compiled names when
the overloads are consumed from C# or other .NET languages. The new warning
catches this at the declaration site:

```fsharp
type Foo with
    [<CompiledName "Bar">]
    member _.Overload(x: int) = x

    // FS-warning: [<CompiledName>] value differs from other overloads
    [<CompiledName "Baz">]
    member _.Overload(x: string) = x
```

**`ObsoleteDiagnosticInfo` in symbols.** The compiler symbol API now exposes
`ObsoleteDiagnosticInfo` for obsolete symbols, enabling tooling and analyzers
to read the obsolete message and error flag without parsing the raw attribute
arguments
([dotnet/fsharp #19359](https://github.com/dotnet/fsharp/pull/19359)).

**Reject non-function bindings for active patterns.** The compiler now
rejects single-case and partial active pattern names that are bound to a
non-function value, which was previously a silent misuse that produced
surprising compilation errors or incorrect runtime behavior
([dotnet/fsharp #19763](https://github.com/dotnet/fsharp/pull/19763)).

## Bug fixes

- Fixed type aliases not being preserved in `match | null` branch refinement.
  Matching a union type against `null` no longer strips the type alias from
  the non-null branch
  ([dotnet/fsharp #19745](https://github.com/dotnet/fsharp/pull/19745)).
- Fixed hover and symbol resolution incorrectly resolving wildcard `_` patterns
  inside `member _.Method` declarations
  ([dotnet/fsharp #19760](https://github.com/dotnet/fsharp/pull/19760)).
- Fixed duplicate format-specifier locations being reported in computation
  expressions
  ([dotnet/fsharp #19791](https://github.com/dotnet/fsharp/pull/19791)).

## Community contributors

Thank you contributors! ❤️

- [@Booksbaum](https://github.com/dotnet/fsharp/pulls?q=is%3Apr+is%3Amerged+author%3ABooksbaum)
- [@edgarfgp](https://github.com/dotnet/fsharp/pulls?q=is%3Apr+is%3Amerged+author%3Aedgarfgp)
- [@nojaf](https://github.com/dotnet/fsharp/pulls?q=is%3Apr+is%3Amerged+author%3Anojaf)
