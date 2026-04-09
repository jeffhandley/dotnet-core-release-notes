# .NET Runtime in .NET 11 Preview 3

## Runtime Async (V3)

> This is a preview feature for .NET 11.

Preview 3 delivers two significant Runtime Async advances: **crossgen2 integration** and **continuation reuse**. These extend the runtime-native async infrastructure introduced in Preview 1 and refined in Preview 2.

### crossgen2 support

Runtime-async methods can now be compiled ahead-of-time by crossgen2, enabling ReadyToRun images for applications that use the `runtime-async=on` feature flag. Previously, async methods marked with `MethodImplOptions.Async` were excluded from AOT compilation, limiting the feature to JIT-only workloads. ([dotnet/runtime #124203](https://github.com/dotnet/runtime/pull/124203))

### Continuation reuse

The runtime can now save and reuse continuation instances rather than allocating a fresh one each time an async method suspends. A companion JIT optimization skips saving locals that haven't changed into the reused continuation, reducing the per-suspension cost. Together these changes lower GC pressure in high-throughput async workloads. ([dotnet/runtime #125556](https://github.com/dotnet/runtime/pull/125556), [dotnet/runtime #125615](https://github.com/dotnet/runtime/pull/125615))

### Profiler and diagnostic tool support

`GetNativeCodeInfo` now understands async thunk methods, allowing profilers and sampling tools to correctly attribute execution time spent in runtime-async methods. ([dotnet/runtime #124354](https://github.com/dotnet/runtime/pull/124354))

---

## GC

### GC regions on macOS

GC regions are now enabled by default on macOS, matching the behavior already in place on Windows and Linux since .NET 8. Regions allow the GC to reclaim and reuse heap memory in finer-grained increments, which reduces fragmentation and can lower overall memory usage on long-running applications. Apple silicon workloads in particular may benefit from more predictable heap growth. ([dotnet/runtime #125416](https://github.com/dotnet/runtime/pull/125416))

## JIT

### SDSU interval register allocation

The JIT now preferentially assigns single-definition single-use (SDSU) intervals to registers not destroyed by nearby calls, reducing unnecessary spills in method prologues and epilogues. This improves code density for methods that call helpers before using their result. ([dotnet/runtime #125219](https://github.com/dotnet/runtime/pull/125219))
