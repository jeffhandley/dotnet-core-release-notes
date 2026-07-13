# C# in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new C# 14 features:

<!-- toc -->

- [Extension indexers](#extension-indexers)
- [Union types: continued progress](#union-types-continued-progress)
- [Unsafe fields](#unsafe-fields)
- [Labeled `break` and `continue`](#labeled-break-and-continue)
- [Incremental generators: `RegisterPreCompilationSourceOutput`](#incremental-generators-registerprecompilationsourceoutput)
- [Caching compiler: output timestamps](#caching-compiler-output-timestamps)
- [Bug fixes and tooling improvements](#bug-fixes-and-tooling-improvements)
- [Community contributors](#community-contributors)

<!-- tocstop -->

C# updates in .NET 11:

- [What's new in C# 14](https://learn.microsoft.com/dotnet/csharp/whats-new/csharp-14)

## Extension indexers

C# 14 extension indexers allow you to add indexer syntax to types you don't own. Extension indexers use the same `extension` block syntax introduced in earlier previews for extension properties and methods:

```csharp
extension(IReadOnlyDictionary<string, int> dict)
{
    public int this[string key, int defaultValue] =>
        dict.TryGetValue(key, out var v) ? v : defaultValue;
}

// Usage:
IReadOnlyDictionary<string, int> scores = ...;
int score = scores["Alice", 0];   // calls extension indexer
```

Preview 6 completes the core compiler work for extension indexers, including:

- Full semantic binding and CREF support in XML documentation ([dotnet/roslyn #81607](https://github.com/dotnet/roslyn/pull/81607), [dotnet/roslyn #82012](https://github.com/dotnet/roslyn/pull/82012)).
- Nullability flow analysis through extension indexers ([dotnet/roslyn #81971](https://github.com/dotnet/roslyn/pull/81971)).
- Implicit-indexer (`^n`) and list-pattern support ([dotnet/roslyn #82453](https://github.com/dotnet/roslyn/pull/82453), [dotnet/roslyn #82757](https://github.com/dotnet/roslyn/pull/82757)).
- Compound assignment, read/write receiver handling, and all remaining complex assignment forms ([dotnet/roslyn #83505](https://github.com/dotnet/roslyn/pull/83505), [dotnet/roslyn #83553](https://github.com/dotnet/roslyn/pull/83553), [dotnet/roslyn #83587](https://github.com/dotnet/roslyn/pull/83587)).
- Classic extension `Slice` method allowed alongside extension indexers ([dotnet/roslyn #82836](https://github.com/dotnet/roslyn/pull/82836)).
- Full `string` and `array` indexer scenarios ([dotnet/roslyn #83041](https://github.com/dotnet/roslyn/pull/83041)).

## Union types: continued progress

C# 14 `union` types continue to evolve in Preview 6. A `union` declares a closed set of named cases, each of which can carry typed data:

```csharp
union Shape
{
    Circle(double radius),
    Rectangle(double width, double height),
    Triangle(double a, double b, double c)
}

double Area(Shape shape) => shape switch
{
    Shape.Circle(var r) => Math.PI * r * r,
    Shape.Rectangle(var w, var h) => w * h,
    Shape.Triangle(var a, var b, var c) => /* Heron's formula */ ...,
};
```

Preview 6 improvements:

- Non-public constructors with a single parameter are now allowed in a `union` declaration, enabling factory-style controlled construction ([dotnet/roslyn #83788](https://github.com/dotnet/roslyn/pull/83788)).
- The compiler now reports an error when a custom `union`-like declaration is missing the minimal required set of APIs ([dotnet/roslyn #83813](https://github.com/dotnet/roslyn/pull/83813)).
- Language-version guards added for scenarios that match a `Union`'s `Value` property directly ([dotnet/roslyn #83759](https://github.com/dotnet/roslyn/pull/83759)).
- `TypeUnionValueSet` creation is now optimized using a `HashSet` for large union types ([dotnet/roslyn #83789](https://github.com/dotnet/roslyn/pull/83789)).

## Unsafe fields

C# 14 adds `unsafe` fields in `struct` types. A field declared `unsafe` can hold pointer types or fixed-size buffers without requiring an `unsafe` block around every use site:

```csharp
public unsafe struct Packet
{
    public unsafe byte* Data;
    public int Length;
}
```

Previously, fixed-size buffers in structs required the enclosing type to be marked `unsafe` or required `fixed` block scoping at every call site. The `unsafe` field modifier scopes the unsafety to the field declaration, allowing the rest of the struct to remain safe ([dotnet/roslyn #83694](https://github.com/dotnet/roslyn/pull/83694)).

## Labeled `break` and `continue`

C# 14 adds labeled `break` and `continue` statements, allowing you to break out of or continue to an outer loop from a nested loop without a flag variable:

```csharp
outer:
foreach (var row in grid)
{
    foreach (var cell in row)
    {
        if (cell == target)
            break outer;    // exits the outer foreach directly
    }
}
```

The syntax follows the label declaration established by existing C# `goto` labels: a `label:` before the loop, then `break label` or `continue label` inside a nested body. The label must identify an enclosing iteration statement ([dotnet/roslyn #83197](https://github.com/dotnet/roslyn/pull/83197)).

## Incremental generators: `RegisterPreCompilationSourceOutput`

The Roslyn incremental source generator API gains `RegisterPreCompilationSourceOutput`, which allows a generator to produce source that the compiler adds to the compilation **before** the main semantic analysis pass. This enables generators to emit foundational infrastructure types — base classes, interfaces, or attribute definitions — that other generators or hand-written code depend on, without requiring a separate generator package or a multi-pass workaround ([dotnet/roslyn #83088](https://github.com/dotnet/roslyn/pull/83088)).

## Caching compiler: output timestamps

The Roslyn caching compiler (used in `dotnet build` when build caching is enabled) now updates the file modification timestamps of output assemblies when it serves a cached hit. Previously a cache hit left timestamps unchanged, which caused some downstream tools to conclude that the output was stale and rebuild unnecessarily ([dotnet/roslyn #83802](https://github.com/dotnet/roslyn/pull/83802)).

## Bug fixes and tooling improvements

- Fixed a warning in the "make async Task" code fixer when the method is assigned to a delegate with a different return type ([dotnet/roslyn #84142](https://github.com/dotnet/roslyn/pull/84142)).
- Fixed an incorrect argument order detected by the Roslyn analyzer ([dotnet/roslyn #83773](https://github.com/dotnet/roslyn/pull/83773)).
- Source generator child nodes now correctly appear in Solution Explorer for generators under the project directory ([dotnet/roslyn #83778](https://github.com/dotnet/roslyn/pull/83778)).
- Hot reload: the `_disabled` flag is now reset when a new debug session starts, so hot reload works again after a session where it was previously disabled ([dotnet/roslyn #83747](https://github.com/dotnet/roslyn/pull/83747)).
- Full semantic tokens support added to the Razor language server ([dotnet/roslyn #83800](https://github.com/dotnet/roslyn/pull/83800)).
- Roslyn uses non-recursive file watches when watching individual files, reducing the number of OS handles held ([dotnet/roslyn #83725](https://github.com/dotnet/roslyn/pull/83725)).
- Another `SourceText.ToString` optimization for the VS (net472) path ([dotnet/roslyn #83654](https://github.com/dotnet/roslyn/pull/83654)).

## Community contributors

No external community contributors were identified for C# in this preview.
