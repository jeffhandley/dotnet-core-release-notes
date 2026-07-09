# C# 14 in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new C# 14 language features:

<!-- toc -->

- [Union type refinements](#union-type-refinements)
- [Unsafe fields](#unsafe-fields)
- [RegisterPreCompilationSourceOutput for incremental generators](#registerprecompilationsourceoutput-for-incremental-generators)
- [Hot Reload fix: re-enables after debug session restarts](#hot-reload-fix-re-enables-after-debug-session-restarts)
- [Bug fixes](#bug-fixes)
- [Community contributors](#community-contributors)

<!-- tocstop -->

C# 14 language features are in preview in .NET 11 Preview 6. Syntax and
semantics may evolve before the final release. Feedback is welcome on the
[dotnet/csharplang](https://github.com/dotnet/csharplang) repo.

C# updates in .NET 11:

- [What's new in C# 14](https://learn.microsoft.com/dotnet/csharp/whats-new/csharp-14)

## Union type refinements

> Union types were introduced in Preview 5. Preview 6 continues to refine the
> feature. Syntax and semantics are still subject to change.

Several correctness and expressibility improvements landed for C# 14 union
types in Preview 6.

**`not` patterns apply to the union value itself.** When you use a `not`
pattern in a union switch arm, the compiler now correctly applies the negation
to the union value rather than to a case tag. This closes gaps where `not null`
patterns over a union did not behave as expected
([dotnet/roslyn #83904](https://github.com/dotnet/roslyn/pull/83904)).

**Direct matching on `Value` is union-aware.** When you match a union's `.Value`
property directly in a pattern, the compiler now understands the union structure
and uses that knowledge for exhaustiveness analysis and switch warnings
([dotnet/roslyn #83856](https://github.com/dotnet/roslyn/pull/83856)).

**Language-version gate for `Value`-based matching.** Code that matches a
`Union`'s `Value` property directly now emits an error when the language
version does not support unions, so users on older language versions get a
clear diagnostic instead of a hard-to-diagnose runtime behavior
([dotnet/roslyn #83759](https://github.com/dotnet/roslyn/pull/83759)).

**Dedicated syntax type.** The compiler now uses a dedicated `UnionDeclarationSyntax`
node for union declarations instead of re-using an existing syntax shape. This
makes tooling and analyzer work more predictable and correct
([dotnet/roslyn #83808](https://github.com/dotnet/roslyn/pull/83808)).

**Custom union declarations are validated.** If you implement a union-compatible
type by hand (without the `union` keyword), the compiler now checks that the
type has the required minimal set of APIs and reports a diagnostic if any are
missing
([dotnet/roslyn #83813](https://github.com/dotnet/roslyn/pull/83813)).

**Union member provider interface is disallowed.** Declaring a union member
provider as an interface is now an error, since the interface shape alone
cannot satisfy the runtime requirements of a union
([dotnet/roslyn #83815](https://github.com/dotnet/roslyn/pull/83815)).

Together with the Preview 5 foundation ([PR #83705](https://github.com/dotnet/roslyn/pull/83705)),
Preview 6 makes union exhaustiveness, pattern semantics, and toolability
significantly more complete. Example:

```csharp
union Result
{
    Ok(int Value),
    Error(string Message)
}

string Describe(Result r) => r switch
{
    Result.Ok(var v)      => $"OK: {v}",
    Result.Error(var msg) => $"Error: {msg}",
    // compiler enforces exhaustiveness — no default needed
};
```

## Unsafe fields

C# 14 adds `unsafe` field declarations as part of the Unsafe Evolution
roadmap ([dotnet/roslyn #83694](https://github.com/dotnet/roslyn/pull/83694)).

Previously, a field whose type requires unsafe context (a pointer or a
function pointer) forced you to put `unsafe` on the entire containing type
or on every method that accessed the field. With C# 14, you can now declare
the field itself as `unsafe`, limiting the unsafe surface to the declaration
site:

```csharp
class SomeNativeWrapper
{
    private unsafe void* _handle;  // only this line requires unsafe context

    public void Initialize() => ...
    public void Dispose()
    {
        unsafe { NativeApi.Free(_handle); _handle = null; }
    }
}
```

This is the same granularity that exists for unsafe *methods* and unsafe
*local variables*, now extended to fields. The feature is part of the broader
C# Unsafe Evolution effort to reduce the blast radius of the `unsafe` modifier.

## RegisterPreCompilationSourceOutput for incremental generators

Incremental source generators can now register a `RegisterPreCompilationSourceOutput`
callback ([dotnet/roslyn #83088](https://github.com/dotnet/roslyn/pull/83088)).

Previously, all `RegisterSourceOutput` callbacks ran after the compilation
phase. The new pre-compilation step runs before the semantic model is built,
which lets generators emit code that participates in compilation — for example,
adding types that other generators or user code can reference during the same
compilation. This unlocks generator chaining scenarios that were previously
difficult or required multiple compilation passes.

```csharp
context.RegisterPreCompilationSourceOutput(
    context.CompilationProvider,
    static (spc, compilation) =>
    {
        // Runs before compilation — output here is visible to other generators
        spc.AddSource("MyEarlyTypes.g.cs", SourceText.From(...));
    });
```

## Hot Reload fix: re-enables after debug session restarts

Hot Reload was staying disabled after a previous debug session disabled it.
The disabled flag is now reset at the start of each new debug session, so
Hot Reload works correctly across consecutive sessions without restarting the
IDE ([dotnet/roslyn #83747](https://github.com/dotnet/roslyn/pull/83747)).

## Bug fixes

- Suppressed the IDE0019 code-fix when a local variable is later passed to an
  `out`/`ref` parameter of a nullable type, where the suggested pattern-match
  would have been semantically incorrect
  ([dotnet/roslyn #83883](https://github.com/dotnet/roslyn/pull/83883)).

## Community contributors

Thank you contributors! ❤️

- [@aeneasr](https://github.com/dotnet/roslyn/pulls?q=is%3Apr+is%3Amerged+author%3Aaeneasr)
