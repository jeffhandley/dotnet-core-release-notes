# .NET Runtime in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new runtime features and performance work:

<!-- toc -->

- [System.Text.Json union support](#systemtextjson-union-support)
- [Configurable environment variable name transformation](#configurable-environment-variable-name-transformation)
- [Corrected keyed-service probing for built-in DI services](#corrected-keyed-service-probing-for-built-in-di-services)
- [JIT improvements](#jit-improvements)
- [`Vector<T>` passed by reference when `VectorT` ISA is available](#vectort-passed-by-reference-when-vectort-isa-is-available)
- [`Math.BigMul` performance on x64](#mathbigmul-performance-on-x64)
- [Linker dead-code elimination enabled globally on Unix](#linker-dead-code-elimination-enabled-globally-on-unix)
- [WebAssembly write barriers](#webassembly-write-barriers)
- [Bug fixes](#bug-fixes)
- [Community contributors](#community-contributors)

<!-- tocstop -->

.NET Runtime updates in .NET 11:

- [What's new in .NET 11 runtime](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-11/runtime)

## System.Text.Json union support

`System.Text.Json` now supports serializing and deserializing [C# union types](https://learn.microsoft.com/dotnet/csharp/language-reference/proposals/unions) (the new `union` feature shipping in C# 14). When a type annotated with `[JsonSerializable]` or registered via `AddJsonOptions` includes union properties, the generated serializer handles the active case automatically without requiring custom converters.

This is a building-block change: it enables the rest of the ecosystem — ASP.NET Core, Minimal APIs, SignalR, Blazor — to pass union values across HTTP and WebSocket boundaries without user-authored glue code. See the [ASP.NET Core release notes](./aspnetcore.md) for the framework-level union support that builds on this foundation ([dotnet/runtime #128162](https://github.com/dotnet/runtime/pull/128162)).

## Configurable environment variable name transformation

A new `VariableNameTransformation` option on `EnvironmentVariablesConfigurationSource` lets you control how environment variable names are converted to configuration key paths. By default the provider maps `__` to `:` and normalizes case. With this option you can supply a custom delegate to handle naming conventions that differ from the .NET default — for example, if you're running in an environment that uses single-underscore separators or a fully custom scheme ([dotnet/runtime #127503](https://github.com/dotnet/runtime/pull/127503)).

## Corrected keyed-service probing for built-in DI services

When calling `serviceProvider.GetRequiredKeyedService<T>(key)` with a key that matches a built-in registration, the container now returns the built-in service instead of throwing. A subtle ordering issue in the probing path caused keyed look-ups to bypass the built-in entries; the fix restores the expected precedence and behavior ([dotnet/runtime #128198](https://github.com/dotnet/runtime/pull/128198)).

## JIT improvements

### ARM64 PAC-RET hardware stack protection

The JIT now emits ARM64 Pointer Authentication Code return-address signing (`PAC-RET`) instructions on platforms that expose the feature. When the CPU supports Pointer Authentication (ARMv8.3+), the compiler inserts `PACIASP` on method entry and `AUTIASP` before each return, making it significantly harder for attackers to overwrite return addresses. The feature is enabled automatically when the hardware is capable; no source changes are required ([dotnet/runtime #127838](https://github.com/dotnet/runtime/pull/127838)).

### Improved loop backedge canonicalization

The JIT canonicalizes loop backedges to a single latch block, which is a prerequisite for several downstream loop optimizations such as strength reduction, induction-variable analysis, and loop unrolling. Code with tight inner loops may see additional optimization after this preparatory change ([dotnet/runtime #128303](https://github.com/dotnet/runtime/pull/128303)).

### Constant-folding `SELECT(cond, cns, cns)` nodes

When both branches of a conditional-move have the same constant value, the JIT now folds the whole expression to that constant and eliminates the branch. This fires when two code paths converge on the same result, which happens naturally after inlining ([dotnet/runtime #127915](https://github.com/dotnet/runtime/pull/127915)).

### Removed single-IG prolog restriction (RyuJIT)

RyuJIT no longer requires the method prolog to live in a single instruction group. Removing this restriction unblocks more advanced code motion in the prolog and is a prerequisite for future layout improvements in generated code ([dotnet/runtime #126552](https://github.com/dotnet/runtime/pull/126552)).

## `Vector<T>` passed by reference when `VectorT` ISA is available

On platforms where the JIT has confirmed the `VectorT` instruction set is available at runtime, `Vector<T>` arguments can now be passed by reference in the calling convention, reducing copies and improving performance in SIMD-heavy code ([dotnet/runtime #125729](https://github.com/dotnet/runtime/pull/125729)).

## `Math.BigMul` performance on x64

`Math.BigMul(long, long, out long)` is now implemented with a single `MUL`/`IMUL` instruction on x64 instead of multiple 32-bit multiply steps, improving throughput for code doing wide-integer arithmetic ([dotnet/runtime #117261](https://github.com/dotnet/runtime/pull/117261)).

## Linker dead-code elimination enabled globally on Unix

Link-time dead-code elimination (`--gc-sections`) is now enabled globally for native builds on Unix. Previously it was opt-in per project. This trims unreachable native code from binaries without any changes to managed source, reducing the size of single-file and NativeAOT outputs ([dotnet/runtime #128232](https://github.com/dotnet/runtime/pull/128232)).

## WebAssembly write barriers

The WebAssembly GC target now emits write barriers during object field stores, enabling the incremental/generational GC to correctly track inter-generational references in browser and WASI runtimes. This is an infrastructure prerequisite for more advanced GC modes on Wasm ([dotnet/runtime #128225](https://github.com/dotnet/runtime/pull/128225)).

## Bug fixes

- Resumption stubs for runtime-async are now laid out adjacent to their async method variants, improving code locality ([dotnet/runtime #128380](https://github.com/dotnet/runtime/pull/128380)).
- `ToFrozenDictionary` pre-sizes the intermediate `Dictionary` to reduce rehashing during construction ([dotnet/runtime #128300](https://github.com/dotnet/runtime/pull/128300)).
- NativeAOT now accepts full-width `0x`/`0X`-prefixed 64-bit hex values in environment configuration ([dotnet/runtime #128462](https://github.com/dotnet/runtime/pull/128462)).
- `Socket.Blocking` is now initialized correctly from the underlying handle when constructing from `SafeSocketHandle` ([dotnet/runtime #128433](https://github.com/dotnet/runtime/pull/128433)).
- Fixed a `PhysicalFilesWatcher` regression that created recursive `FileSystemWatcher` instances when watching a single file ([dotnet/runtime #128072](https://github.com/dotnet/runtime/pull/128072)).
- Fixed TAR parsing to reject negative PAX size values ([dotnet/runtime #128368](https://github.com/dotnet/runtime/pull/128368)).
- Fixed Windows tar path handling for absolute paths ([dotnet/runtime #128367](https://github.com/dotnet/runtime/pull/128367)).
- Fixed `MarshalAs.IidParameterIndex` for `out object` in source-generated COM stubs ([dotnet/runtime #128214](https://github.com/dotnet/runtime/pull/128214)).
- Fixed `NegotiateStream` stale read buffer on mid-frame read failure ([dotnet/runtime #128067](https://github.com/dotnet/runtime/pull/128067)).

## Community contributors

Thank you to the community contributors who contributed to .NET Runtime in this preview:

- [@Daniel-Svensson](https://github.com/Daniel-Svensson) — Math.BigMul x64 optimization ([dotnet/runtime #117261](https://github.com/dotnet/runtime/pull/117261))
