# C# 14 in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new C# 14 language features:

<!-- toc -->

- [Extension indexers](#extension-indexers)
- [Union type refinements](#union-type-refinements)
- [Unsafe fields](#unsafe-fields)
- [Unsafe evolution: unsafe expressions](#unsafe-evolution-unsafe-expressions)
- [Unsafe evolution: explicit struct layout](#unsafe-evolution-explicit-struct-layout)
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

## Extension indexers

> Extension indexers are a C# 14 preview feature. Syntax and semantics may
> change before the final release. Feedback is welcome on the
> [dotnet/csharplang](https://github.com/dotnet/csharplang) repo.

C# 14 now supports defining indexers in extension types
([dotnet/roslyn #84200](https://github.com/dotnet/roslyn/pull/84200)).

Previously, extension methods let you add methods to an existing type, but
indexers — the `this[...]` member syntax — could not be defined as extension
members. With C# 14 extension types, you can now add indexers to types you
don't own:

```csharp
// Extend IDictionary<string, object> with a typed indexer
extension DictionaryExtensions for IDictionary<string, object>
{
    public T this<T>[string key] => (T)this[key];
}

var bag = new Dictionary<string, object> { ["name"] = "Alice", ["age"] = 30 };
string name = bag<string>["name"];   // uses the extension indexer
int    age  = bag<int>["age"];
```

Extension indexers support the same features as regular indexers: read/write
access, multi-parameter signatures, and `ref`/`in` return types. They also
participate in the collection slice protocol — a type that defines an
extension `Slice(int, int)` method can now also gain an extension indexer for
range access:

```csharp
extension SpanLikeRange for MyCollection
{
    public int this[Range r] => this.Slice(r.Start.Value, r.GetOffsetAndLength(Count).Length);
}

var col = new MyCollection(1..10);
var sub = col[2..5];   // calls the extension indexer
```

Nullability analysis, list-pattern matching, and CREF documentation
references all work with extension indexers
([dotnet/roslyn #81971](https://github.com/dotnet/roslyn/pull/81971),
[dotnet/roslyn #82757](https://github.com/dotnet/roslyn/pull/82757),
[dotnet/roslyn #82012](https://github.com/dotnet/roslyn/pull/82012)).

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

**Non-public constructors are allowed in union members.** A union member
declaration can now specify a constructor with a single parameter whose
accessibility is `private`, `internal`, or `protected`, giving you control over
who can construct that union case:

```csharp
union Result
{
    Ok(int Value),
    internal Error(string Message)  // only code in the same assembly can create Error
}
```

This is useful for sealed class hierarchies where you want to expose pattern
matching publicly but restrict direct construction of error or internal cases
([dotnet/roslyn #83788](https://github.com/dotnet/roslyn/pull/83788)).

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

## Unsafe evolution: unsafe expressions

C# 14 extends the Unsafe Evolution roadmap with `unsafe` expressions
([dotnet/roslyn #84012](https://github.com/dotnet/roslyn/pull/84012)).

Previously, accessing an unsafe API inside an otherwise-safe method required
an `unsafe` block wrapping the entire statement. With `unsafe` expressions,
you can apply the `unsafe` modifier directly to the expression that needs it,
limiting the unsafe context to the smallest possible site:

```csharp
// Before: entire block is unsafe
unsafe
{
    byte* ptr = stackalloc byte[64];
    Process(ptr);
}

// After: only the stackalloc expression is unsafe
byte* ptr = unsafe stackalloc byte[64];
Process(ptr);
```

This is a natural complement to `unsafe` fields (Preview 6) and continues the
goal of reducing the blast radius of the `unsafe` modifier.

## Unsafe evolution: explicit struct layout

C# 14 removes the requirement to mark a struct as `unsafe` when it uses
explicit layout
([dotnet/roslyn #83974](https://github.com/dotnet/roslyn/pull/83974)).

`[StructLayout(LayoutKind.Explicit)]` and `[FieldOffset]` attributes control
the byte-level position of fields in a struct. These are used for interop with
native code or for memory-mapped I/O. In prior C# versions, the compiler
required the enclosing type to be in an `unsafe` context even when no pointer
or function-pointer types were involved. C# 14 removes that restriction so
you can write a safe struct with explicit layout:

```csharp
// No `unsafe` needed — struct and method are fully safe
[StructLayout(LayoutKind.Explicit, Size = 4)]
struct Color
{
    [FieldOffset(0)] public byte B;
    [FieldOffset(1)] public byte G;
    [FieldOffset(2)] public byte R;
    [FieldOffset(3)] public byte A;
}
```

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
- Improved nullable flow analysis inside switch expressions: the compiler now
  correctly reports unhandled `null` values when decision-dag reachability is
  refined by nullable analysis, preventing false positives where `null` was
  considered handled even though no arm matched it
  ([dotnet/roslyn #84207](https://github.com/dotnet/roslyn/pull/84207)).
- Added a warning to the "make async Task" code fixer when the target method
  is used as a delegate: making it async changes the return type from `void`
  to `Task`, which may be incompatible with the delegate signature
  ([dotnet/roslyn #84142](https://github.com/dotnet/roslyn/pull/84142)).

## Community contributors

Thank you contributors! ❤️

- [@aeneasr](https://github.com/dotnet/roslyn/pulls?q=is%3Apr+is%3Amerged+author%3Aaeneasr)
