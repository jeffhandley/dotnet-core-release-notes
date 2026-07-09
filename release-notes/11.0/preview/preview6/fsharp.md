# F# in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new F# language features and compiler improvements:

<!-- toc -->

- [InlineIfLambda on Array.init](#inlineiflambda-on-arrayinit)
- [Improved for expression debugger stepping](#improved-for-expression-debugger-stepping)
- [Debug inline functions in non-optimized builds](#debug-inline-functions-in-non-optimized-builds)
- [Interpolated strings in named argument positions](#interpolated-strings-in-named-argument-positions)
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

Additionally, sequence point generation for `if` and `match` condition
expressions is now fixed
([dotnet/fsharp #19932](https://github.com/dotnet/fsharp/pull/19932))
so the debugger correctly highlights the condition before branching.

## Debug inline functions in non-optimized builds

In non-optimized (debug) builds, `inline` functions are now compiled as real
method calls instead of being inlined at every call site
([dotnet/fsharp #19548](https://github.com/dotnet/fsharp/pull/19548)).

Before this change, inline functions were always expanded at their call sites,
making them invisible to the debugger — you could not set a breakpoint inside
them, step into them, or inspect their local variables. With this change, when
a project is built without optimization (e.g. with `--debug+` or by default in
`Debug` configuration), the compiler emits a proper method body that the
debugger can navigate.

For inline functions that use SRTPs, the compiler generates a specialized
method for each type instantiation when a single shared method cannot be
produced.

```fsharp
let inline add a b = a + b

// In a Debug build, the debugger can now step into 'add' here
let result = add 1 2
```

This implements a long-requested [F# language suggestion](https://github.com/fsharp/fslang-suggestions/issues/824)
that makes it practical to write logic in inline functions without sacrificing
debuggability.

## Interpolated strings in named argument positions

F# now allows interpolated strings to appear immediately after `=` in named
argument and named record-field positions
([dotnet/fsharp #19820](https://github.com/dotnet/fsharp/pull/19820)).

Previously, writing an interpolated string as a named argument value required
an extra pair of parentheses because the parser interpreted the `$` as part
of an operator pattern. With the fix, the natural syntax compiles directly:

```fsharp
// Previously a parse error — now valid
let r = { Name = $"Hello, {user}!" }
let x = SomeFunction(label = $"item-{id}")
```

This removes a surprising inconsistency between interpolated strings and other
literal types in named-argument positions.

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

- Fixed FSI pretty printing for anonymous records. Anonymous record values
  now display with correct field names and layout in F# Interactive
  ([dotnet/fsharp #19919](https://github.com/dotnet/fsharp/pull/19919)).
- Fixed a `FieldAccessException` when the optimizer relocates a protected
  base-field access across method boundaries during optimization
  ([dotnet/fsharp #19964](https://github.com/dotnet/fsharp/pull/19964)).
- Fixed lost source range for empty-bodied computation expressions in
  pipelines, preventing correct breakpoint placement on continuation steps
  ([dotnet/fsharp #19849](https://github.com/dotnet/fsharp/pull/19849)).
- Added `FS3889` diagnostic for namespace/type name collision. When an
  open namespace and a local type share the same identifier, the compiler
  now emits a clear warning rather than silently choosing the wrong binding
  ([dotnet/fsharp #19802](https://github.com/dotnet/fsharp/pull/19802)).
- Improved FS3261 (nullness) warnings to pinpoint the receiver range, name the
  member, and identify the binding in dot-access expressions — making null
  safety warnings actionable for specific locations
  ([dotnet/fsharp #19814](https://github.com/dotnet/fsharp/pull/19814)).
- Fixed the language-version checker not recovering gracefully when parsing
  language version pragma values
  ([dotnet/fsharp #19970](https://github.com/dotnet/fsharp/pull/19970)).
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
- Fixed open declaration insertion in `.fsx` scripts being placed before
  `#r`/`#load` directives rather than after them, which caused compilation
  errors
  ([dotnet/fsharp #19879](https://github.com/dotnet/fsharp/pull/19879)).
- Fixed `FS1110` being incorrectly raised inside `task { let! }` expressions
  when a generic IL extension is in scope
  ([dotnet/fsharp #19938](https://github.com/dotnet/fsharp/pull/19938)).
- Fixed recursive self-reference ref cells being incorrectly classified as
  mutable, which caused spurious compile errors in valid recursive definitions
  ([dotnet/fsharp #19918](https://github.com/dotnet/fsharp/pull/19918)).
- Added diagnostic for duplicate sibling modules in recursive module groups,
  providing a clear error instead of silent miscompilation
  ([dotnet/fsharp #19913](https://github.com/dotnet/fsharp/pull/19913)).
- Fixed remaining interpolated-string forms adjacent to `=` not being parsed
  correctly, completing coverage for edge cases in the interpolation grammar
  ([dotnet/fsharp #19984](https://github.com/dotnet/fsharp/pull/19984)).
- Improved QuickInfo and symbol-use reporting for `[<CustomOperation>]` keywords:
  the resolved overload is now shown when the cursor is on a computation
  expression keyword
  ([dotnet/fsharp #19865](https://github.com/dotnet/fsharp/pull/19865)).
- Fixed closures raising a compilation error when reading a protected base field.
  Accessing an inherited protected field from inside an anonymous function or
  lambda now compiles correctly
  ([dotnet/fsharp #19991](https://github.com/dotnet/fsharp/pull/19991)).
- The optimizer now eliminates unused `Unchecked.defaultof<'T>` bindings instead
  of keeping them in the emitted IL, reducing unnecessary allocation in
  generated code
  ([dotnet/fsharp #19758](https://github.com/dotnet/fsharp/pull/19758)).
- Fixed spurious type errors for type-provided types under parallel compilation.
  Type-provider instances shared across parallel compilation workers no longer
  produce false type-mismatch errors
  ([dotnet/fsharp #19969](https://github.com/dotnet/fsharp/pull/19969)).
- Fixed a race condition in parallel compilation when resolving provided
  namespaces; they are now interned, preventing rare resolution failures
  ([dotnet/fsharp #20021](https://github.com/dotnet/fsharp/pull/20021)).
- Fixed FSI mutating script arguments after the `--` separator. Arguments passed
  after `--` are now read-only after startup, matching documented behavior
  ([dotnet/fsharp #19926](https://github.com/dotnet/fsharp/pull/19926)).
- `DebuggableAttribute` is now attached to FSI multi-emit assembly manifests
  when `--debug+` is active, enabling richer debugger support for FSI-loaded
  code
  ([dotnet/fsharp #19921](https://github.com/dotnet/fsharp/pull/19921)).
- `address-of` operators (`&` / `&&`) are now allowed on type-instantiated
  generalized `let` bindings, which previously raised an error
  ([dotnet/fsharp #19948](https://github.com/dotnet/fsharp/pull/19948)).
- Fixed semantic colorization missing for delegates, slices, computation
  expression keywords, and members from open types
  ([dotnet/fsharp #19960](https://github.com/dotnet/fsharp/pull/19960)).
- Fixed semantic classification missing for type names inside nested
  copy-and-update record expressions (`{ existing with Field = value }`)
  ([dotnet/fsharp #19878](https://github.com/dotnet/fsharp/pull/19878)).
- Fixed named-argument completion stopping after the first argument in
  method call expressions
  ([dotnet/fsharp #19940](https://github.com/dotnet/fsharp/pull/19940)).
- Fixed Go-to-Definition for provided constructors that have no source
  definition location — the IDE no longer shows an error toast for these
  ([dotnet/fsharp #19917](https://github.com/dotnet/fsharp/pull/19917)).
- Go to Metadata for IL fields now shows the `[<Literal>]` attribute and
  its constant value in the decompiled view
  ([dotnet/fsharp #19922](https://github.com/dotnet/fsharp/pull/19922)).
- Overload-resolution errors for C#-style extensions now name the declaring
  type, making it easier to identify which extension is in scope
  ([dotnet/fsharp #19925](https://github.com/dotnet/fsharp/pull/19925)).
- `FSharpMemberOrFunctionOrValue.IsPropertyAccessor` is now exposed in the
  FCS public API, letting IDEs and analyzers distinguish property accessors
  from regular methods
  ([dotnet/fsharp #19883](https://github.com/dotnet/fsharp/pull/19883)).
- Enum values are now preserved as their declared enum type in `obj`-typed
  custom attribute arguments, instead of being unboxed to an integer
  ([dotnet/fsharp #19975](https://github.com/dotnet/fsharp/pull/19975)).
- `FS0755` is now emitted when `[<CompiledName>]` is applied to a
  multi-value `let` binding, which cannot have a renamed compiled name
  ([dotnet/fsharp #19924](https://github.com/dotnet/fsharp/pull/19924)).
- Fixed packaging of design-time type providers referenced via
  `ProjectReference` in SDK-style projects
  ([dotnet/fsharp #19979](https://github.com/dotnet/fsharp/pull/19979)).
- `FS0039` (undefined identifier) in an `inherit` clause is no longer
  reported multiple times for the same symbol
  ([dotnet/fsharp #19862](https://github.com/dotnet/fsharp/pull/19862)).
- `FS0027` (value restriction) now names the specific function or method
  parameter where the restriction applies
  ([dotnet/fsharp #19866](https://github.com/dotnet/fsharp/pull/19866)).
- Fixed false-positive `FS1113` errors on inline instance members that use
  a class-scope self identifier
  ([dotnet/fsharp #19761](https://github.com/dotnet/fsharp/pull/19761)).
- Parallel and sequential compilation now produce byte-identical output.
  `--parallelcompilation+` previously could generate assemblies with different
  member and field emit order than `--parallelcompilation-`, breaking
  deterministic builds and the `FSharp.Compiler.Service.dll` determinism gate.
  Both modes now derive all emit-order keys from the file being emitted rather
  than thread-scheduling order
  ([dotnet/fsharp #19929](https://github.com/dotnet/fsharp/pull/19929)).
- Fixed the Release-mode optimizer silently dropping side-effectful receivers
  in `task {}` computation expressions. Expressions of the form
  `task { (sideEffect ()).UnitMember }` now correctly execute the receiver —
  previously `sideEffect()` was elided in Release builds
  ([dotnet/fsharp #19885](https://github.com/dotnet/fsharp/pull/19885)).
- Fixed a stack overflow on ppc64le when compiling files with long statement
  sequences. Deep right-nested `Sequential` chains in graph checking now walk
  iteratively, matching the existing handling for `IfThenElse`
  ([dotnet/fsharp #20028](https://github.com/dotnet/fsharp/pull/20028)).

## Community contributors

Thank you contributors! ❤️

- [@auduchinok](https://github.com/dotnet/fsharp/pulls?q=is%3Apr+is%3Amerged+author%3Aauduchinok)
- [@Booksbaum](https://github.com/dotnet/fsharp/pulls?q=is%3Apr+is%3Amerged+author%3ABooksbaum)
- [@edgarfgp](https://github.com/dotnet/fsharp/pulls?q=is%3Apr+is%3Amerged+author%3Aedgarfgp)
- [@KirtiRamchandani](https://github.com/dotnet/fsharp/pulls?q=is%3Apr+is%3Amerged+author%3AKirtiRamchandani)
- [@nojaf](https://github.com/dotnet/fsharp/pulls?q=is%3Apr+is%3Amerged+author%3Anojaf)
