# .NET Libraries in .NET 11 Preview 3 - Release Notes

.NET 11 Preview 3 includes new .NET Libraries features & enhancements:

- [SafeFileHandle.CreateAnonymousPipe](#safefilehandlecreateanonymouspipe)
- [WebProxy credentials from URI userinfo](#webproxy-credentials-from-uri-userinfo)

.NET Libraries updates in .NET 11:

- [What's new in .NET 11](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-11/overview) documentation

## SafeFileHandle.CreateAnonymousPipe

A new static factory method creates a pair of `SafeFileHandle` objects for an anonymous pipe, with independent control over async mode and non-blocking I/O on each end. ([dotnet/runtime #125220](https://github.com/dotnet/runtime/pull/125220))

```csharp
SafeFileHandle.CreateAnonymousPipe(
    out SafeFileHandle readHandle,
    out SafeFileHandle writeHandle,
    asyncRead: true,
    asyncWrite: false);

await using var reader = new FileStream(readHandle, FileAccess.Read, bufferSize: 4096, isAsync: true);
using var writer = new FileStream(writeHandle, FileAccess.Write);
```

Previously, creating pipes with configurable async behavior required platform-specific workarounds or manual P/Invoke. The new API works on Windows and Unix and is adopted by `Process.StandardInput`/`StandardOutput`/`StandardError` on Windows for more reliable async I/O with child processes.

### FileStream async handles on Unix

`FileStream` now supports async handles on Unix, closing a longstanding behavioral gap with Windows. Callers can pass `isAsync: true` when constructing a `FileStream` from a `SafeFileHandle` on Linux and macOS and get true async I/O semantics. ([dotnet/runtime #125377](https://github.com/dotnet/runtime/pull/125377))

### RandomAccess on non-seekable files

`RandomAccess.Read` and `RandomAccess.Write` now accept non-seekable file handles. Previously, calling these methods on a pipe or character device threw an exception even when the underlying OS call would succeed. ([dotnet/runtime #125512](https://github.com/dotnet/runtime/pull/125512))

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

Thank you to everyone who contributed to .NET 11 Preview 3! ❤️
