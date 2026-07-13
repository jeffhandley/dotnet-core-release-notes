# Libraries in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new library features and improvements:

<!-- toc -->

- [System.Text.Json union support](#systemtextjson-union-support)
- [Configurable environment variable name transformation](#configurable-environment-variable-name-transformation)
- [Corrected keyed-service probing for built-in DI services](#corrected-keyed-service-probing-for-built-in-di-services)
- [Performance improvements](#performance-improvements)
- [Bug fixes](#bug-fixes)
- [Community contributors](#community-contributors)

<!-- tocstop -->

Libraries updates in .NET 11:

- [What's new in .NET 11 libraries](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-11/libraries)

## System.Text.Json union support

`System.Text.Json` gains serialization support for the new C# 14 `union` types. When a `union` type is used as a property in a type registered for source-generated or reflection-based serialization, the serializer correctly reads and writes the active case. The discriminator encoding follows the same conventions as sealed class hierarchies — the active type name is written as a `$type` discriminator property by default, and the full value is written inline.

This is the runtime-layer piece; ASP.NET Core, Minimal APIs, SignalR, and Blazor each build on this support to pass union values over HTTP and WebSocket boundaries. See [ASP.NET Core release notes](./aspnetcore.md) for the framework-level integration ([dotnet/runtime #128162](https://github.com/dotnet/runtime/pull/128162)).

## Configurable environment variable name transformation

`EnvironmentVariablesConfigurationSource` now accepts a `VariableNameTransformation` delegate that controls how raw environment variable names are converted into configuration key paths. The built-in transformation maps `__` to `:` and normalizes separators; the new option lets you override this for environments that use different conventions — single-underscore separators, all-caps prefixes, or custom schemes. Existing code without the option continues to behave identically ([dotnet/runtime #127503](https://github.com/dotnet/runtime/pull/127503)).

## Corrected keyed-service probing for built-in DI services

`IServiceProvider.GetRequiredKeyedService<T>(key)` now correctly returns built-in service registrations when the key matches. A probing-order bug caused the lookup to bypass built-in entries, resulting in unexpected `InvalidOperationException` errors when callers expected to retrieve a framework-registered service by key. The fix restores the expected precedence ([dotnet/runtime #128198](https://github.com/dotnet/runtime/pull/128198)).

## Performance improvements

- **`Math.BigMul` on x64** — the `Math.BigMul(long, long, out long)` overload now compiles to a single `MUL`/`IMUL` instruction on x64, replacing multiple 32-bit multiplies ([dotnet/runtime #117261](https://github.com/dotnet/runtime/pull/117261)). Thanks [@Daniel-Svensson](https://github.com/Daniel-Svensson).
- **`ToFrozenDictionary` pre-sizing** — the intermediate `Dictionary<K,V>` built during `ToFrozenDictionary()` is now pre-sized to the source count, reducing allocations and rehashing for large collections ([dotnet/runtime #128300](https://github.com/dotnet/runtime/pull/128300)).

## Bug fixes

- Fixed `PhysicalFilesWatcher` creating recursive `FileSystemWatcher` instances when watching individual files, which caused excessive file-system events ([dotnet/runtime #128072](https://github.com/dotnet/runtime/pull/128072)).
- TAR parsing now rejects negative PAX size field values that could lead to incorrect length calculations ([dotnet/runtime #128368](https://github.com/dotnet/runtime/pull/128368)).
- Fixed absolute path handling in the Windows TAR implementation ([dotnet/runtime #128367](https://github.com/dotnet/runtime/pull/128367)).
- Fixed `MarshalAs.IidParameterIndex` handling for `out object` parameters in source-generated COM interop stubs ([dotnet/runtime #128214](https://github.com/dotnet/runtime/pull/128214)).
- Fixed a stale read-buffer issue in `NegotiateStream` when a read fails mid-frame ([dotnet/runtime #128067](https://github.com/dotnet/runtime/pull/128067)).
- NativeAOT now correctly accepts full-width `0x`/`0X`-prefixed 64-bit hex values in environment configuration ([dotnet/runtime #128462](https://github.com/dotnet/runtime/pull/128462)).
- Fixed `Socket.Blocking` not reflecting the correct state when constructing a `Socket` from a `SafeSocketHandle` ([dotnet/runtime #128433](https://github.com/dotnet/runtime/pull/128433)).
- Fixed an infinite spin-wait in `Socket` release when the socket is closed after the handle was invalidated ([dotnet/runtime #128434](https://github.com/dotnet/runtime/pull/128434)).

## Community contributors

Thank you to the community contributors who contributed to .NET Libraries in this preview:

- [@Daniel-Svensson](https://github.com/Daniel-Svensson) — `Math.BigMul` x64 optimization ([dotnet/runtime #117261](https://github.com/dotnet/runtime/pull/117261))
