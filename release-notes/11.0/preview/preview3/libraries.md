# .NET Libraries in .NET 11 Preview 3 - Release Notes

.NET 11 Preview 3 includes new .NET Libraries features & enhancements:

- [LINQ join tuple overloads](#linq-join-tuple-overloads)
- [SafeFileHandle.CreateAnonymousPipe](#safefilehandlecreateanonymouspipe)
- [DirectoryNotFoundException.DirectoryPath](#directorynotfoundexceptiondirectorypath)
- [Utf8JsonWriter.Reset with options](#utf8jsonwriterreset-with-options)

.NET Libraries updates in .NET 11:

- [What's new in .NET 11](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-11/overview) documentation

## LINQ join tuple overloads

`Enumerable.Join`, `LeftJoin`, and `RightJoin` now have overloads that return tuples of matched key and element pairs, removing the need to write a result selector when you just want both elements together. ([dotnet/runtime #121998](https://github.com/dotnet/runtime/pull/121998))

```csharp
var orders = new[] { new { Id = 1, CustomerId = 10, Amount = 99.95m } };
var customers = new[] { new { Id = 10, Name = "Alice" } };

// Before: explicit result selector required
var joined = orders.Join(customers,
    o => o.CustomerId,
    c => c.Id,
    (o, c) => new { o.Amount, c.Name });

// After: tuple overload — no result selector needed
var joined = orders.Join(customers,
    o => o.CustomerId,
    c => c.Id);
// Each element is (TLeft Left, TRight Right)
foreach (var (order, customer) in joined)
    Console.WriteLine($"{customer.Name}: {order.Amount:C}");
```

`LeftJoin` and `RightJoin` work the same way, returning tuples where the nullable side is `TLeft?` or `TRight?` respectively.

## SafeFileHandle.CreateAnonymousPipe

A new static factory method creates a pair of `SafeFileHandle` objects for an anonymous pipe, with independent control over async mode and non-blocking I/O on each end. ([dotnet/runtime #125220](https://github.com/dotnet/runtime/pull/125220))

```csharp
var (readHandle, writeHandle) = SafeFileHandle.CreateAnonymousPipe(
    readerOpenAsynchronous: true,
    writerOpenAsynchronous: false);

await using var reader = new FileStream(readHandle, FileAccess.Read, bufferSize: 4096, isAsync: true);
using var writer = new FileStream(writeHandle, FileAccess.Write);
```

Previously, creating pipes with configurable async behavior required platform-specific workarounds or manual P/Invoke. The new API works on Windows and Unix and is adopted by `Process.StandardInput`/`StandardOutput`/`StandardError` on Windows for more reliable async I/O with child processes.

### FileStream async handles on Unix

`FileStream` now supports async handles on Unix, closing a longstanding behavioral gap with Windows. Callers can pass `isAsync: true` when constructing a `FileStream` from a `SafeFileHandle` on Linux and macOS and get true async I/O semantics. ([dotnet/runtime #125377](https://github.com/dotnet/runtime/pull/125377))

### RandomAccess on non-seekable files

`RandomAccess.Read` and `RandomAccess.Write` now accept non-seekable file handles. Previously, calling these methods on a pipe or character device threw an exception even when the underlying OS call would succeed. ([dotnet/runtime #125512](https://github.com/dotnet/runtime/pull/125512))

## DirectoryNotFoundException.DirectoryPath

`DirectoryNotFoundException` now exposes a `DirectoryPath` property containing the path that was not found, so callers no longer need to parse the exception message string. ([dotnet/runtime #126428](https://github.com/dotnet/runtime/pull/126428))

```csharp
try
{
    Directory.EnumerateFiles("/no/such/path");
}
catch (DirectoryNotFoundException ex)
{
    Console.WriteLine(ex.DirectoryPath); // "/no/such/path"
}
```

## Utf8JsonWriter.Reset with options

`Utf8JsonWriter.Reset` now has overloads that accept `JsonWriterOptions`, letting you change formatting, encoder, or indentation settings when reusing a writer. Previously, changing options required creating a new `Utf8JsonWriter` instance. ([dotnet/runtime #126578](https://github.com/dotnet/runtime/pull/126578))

```csharp
var writer = new Utf8JsonWriter(stream);
writer.WriteStartObject();
// ... write first document
writer.WriteEndObject();
await writer.FlushAsync();

// Reset with different options (e.g., enable indented output for the next doc)
writer.Reset(stream, new JsonWriterOptions { Indented = true });
writer.WriteStartObject();
// ... write second document
```

## WebProxy credentials from URI userinfo

`WebProxy` now reads credentials directly from the userinfo component of the proxy URI, eliminating the need to set `Credentials` separately. ([dotnet/runtime #125384](https://github.com/dotnet/runtime/pull/125384))

```csharp
// Before: separate Credentials assignment needed
var proxy = new WebProxy("http://proxy.example.com:8080")
{
    Credentials = new NetworkCredential("user", "pass")
};

// After: credentials parsed from URI automatically
var proxy = new WebProxy("http://user:pass@proxy.example.com:8080");
```

## Performance

### HashSet\<T\> and Dictionary\<T\> improvements

`HashSet<T>` lookup and insertion operations benefit from JIT bounds-check elimination, reducing instruction count in the hot path. `Dictionary<T>.Remove` has been restructured to produce better codegen for value-type keys, reducing unnecessary branch overhead. ([dotnet/runtime #125893](https://github.com/dotnet/runtime/pull/125893), [dotnet/runtime #125884](https://github.com/dotnet/runtime/pull/125884))

## Bug fixes

- **System.Linq** — `ToAsyncEnumerable` now returns the source object directly when it already implements `IAsyncEnumerable<T>`, avoiding a wrapper allocation ([dotnet/runtime #126362](https://github.com/dotnet/runtime/pull/126362))

## Community contributors

Thank you contributors! ❤️

- [@ViveliDuCh](https://github.com/dotnet/runtime/pulls?q=is%3Apr+is%3Amerged+merged%3A2026-03-10..2026-04-08+author%3AViveliDuCh) — System.IO improvements
