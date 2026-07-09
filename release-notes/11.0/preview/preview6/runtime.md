# .NET Runtime in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new runtime features and performance work:

<!-- toc -->

- [System.Text.Json union type support](#systemtextjson-union-type-support)
- [Configurable EnvironmentVariables key transformation](#configurable-environmentvariables-key-transformation)
- [Arm64 PAC-RET support](#arm64-pac-ret-support)
- [JIT improvements](#jit-improvements)
- [In-process crash report logging](#in-process-crash-report-logging)
- [Process start-suspended support](#process-start-suspended-support)
- [Async continuations without ExecutionContext](#async-continuations-without-executioncontext)
- [NativeAOT: faster interface dispatch](#nativeaot-faster-interface-dispatch)
- [SIMD: Lane construction and composition APIs](#simd-lane-construction-and-composition-apis)
- [Diagnostics: cDAC loading from SOS installations](#diagnostics-cdac-loading-from-sos-installations)
- [Bug fixes](#bug-fixes)
- [Community contributors](#community-contributors)

<!-- tocstop -->

.NET Runtime updates in .NET 11:

- [What's new in .NET 11 runtime](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-11/runtime)

## System.Text.Json union type support

`System.Text.Json` now supports C# 14 union types out of the box
([dotnet/runtime #128162](https://github.com/dotnet/runtime/pull/128162)).

When you serialize or deserialize a C# 14 `union` value, `System.Text.Json`
uses the union's discriminator to write a tagged JSON representation and to
select the correct case during deserialization:

```csharp
union Shape
{
    Circle(double Radius),
    Rectangle(double Width, double Height)
}

var circle = new Shape.Circle(Radius: 3.0);
string json = JsonSerializer.Serialize(circle);
// {"$type":"Circle","Radius":3.0}

var shape = JsonSerializer.Deserialize<Shape>(json);
// shape is Shape.Circle(Radius: 3.0)
```

No manual `[JsonDerivedType]` annotations are required — the serializer
discovers union cases automatically from the union declaration. The feature
works with `JsonSerializerContext` for source-generation mode as well.

## Configurable EnvironmentVariables key transformation

`EnvironmentVariablesConfigurationProvider` now accepts a configurable
`VariableNameTransformation` delegate that controls how environment variable
names are mapped to configuration keys
([dotnet/runtime #127503](https://github.com/dotnet/runtime/pull/127503)).

By default, the provider converts `__` to `:` and uppercases keys. The new
delegate lets you override that logic:

```csharp
builder.Configuration.AddEnvironmentVariables(options =>
{
    options.VariableNameTransformation = name =>
        name.Replace("APP_", "", StringComparison.Ordinal)
            .Replace("__", ":", StringComparison.Ordinal);
});
```

This is useful when deploying to environments that follow a different
naming convention or when running multiple apps in the same process that
should each consume a scoped prefix of environment variables.

## Arm64 PAC-RET support

The JIT now emits Pointer Authentication Code (PAC) instructions for
return-address signing on ARM64 hardware that supports
`FEAT_PAuth` or `FEAT_PAuth2`
([dotnet/runtime #127838](https://github.com/dotnet/runtime/pull/127838)).

PAC-RET adds hardware-enforced return-address integrity: the CPU signs the
return address when a function is entered and verifies the signature before
jumping on return. If an attacker overwrites the return address on the stack,
the signature check fails and the process terminates cleanly rather than
executing attacker-controlled code. This is the ARM64 counterpart of Intel
Control-flow Enforcement Technology (CET) shadow stacks that the runtime
already supports on x64.

The feature is enabled automatically when the runtime detects PAC support at
startup. No application changes are required. PAC-RET is active on Apple
Silicon, recent Qualcomm Snapdragon, and AWS Graviton3 / Graviton4 systems.

Thanks [@a74nh](https://github.com/a74nh) for the contribution.

## JIT improvements

### `Math.BigMul` performance on x64

`Math.BigMul(long, long, out long)` is now significantly faster on x64
([dotnet/runtime #117261](https://github.com/dotnet/runtime/pull/117261)).

The JIT generates a single `MUL r/m64` instruction when both operands are
64-bit values and the caller requests the high half of the result. Previously
the JIT emitted a helper call. The change eliminates the call overhead and
makes code that multiplies large numbers tighter.

Thanks [@xtqqczze](https://github.com/xtqqczze) for the contribution.

### RyuJIT: single-IG prolog restriction removed

The JIT no longer requires the function prolog to fit in a single instruction
group (IG)
([dotnet/runtime #126552](https://github.com/dotnet/runtime/pull/126552)).

Previously, complex prologues — for example, frames with many saved registers,
large stack allocations, or runtime-async state setup — had to be squeezed
into one IG or trigger fallback paths. Removing the restriction simplifies the
code generator, enables better prolog code for complex methods, and removes an
artificial size limit that occasionally affected generated assembly quality.

Thanks [@Copilot](https://github.com/Copilot) ([@EgorBot](https://github.com/EgorBot)) for contributions.

### `SELECT(cond, cns, cns)` → `cns`

The JIT now folds conditional selects whose two branches both produce the
same constant into just that constant
([dotnet/runtime #127915](https://github.com/dotnet/runtime/pull/127915)).

```csharp
// Before: emit a conditional select instruction
int x = condition ? 42 : 42;

// After: JIT replaces the SELECT with the constant 42
```

While writing identical constants in both branches is rare in hand-authored
code, it occurs after earlier optimizations simplify or unify branches. The
fold eliminates the unnecessary comparison and select instruction.

Thanks [@DeaglePC](https://github.com/DeaglePC) for the contribution.

### ARM64: `Vector<T>` passed by reference for SVE

When the runtime is compiled with ARM SVE (Scalable Vector Extension) support,
`Vector<T>` values are now passed by reference rather than by value
([dotnet/runtime #125729](https://github.com/dotnet/runtime/pull/125729)).

SVE vectors have runtime-determined widths (512 bits on some hardware), so
passing them on the stack by value was both expensive and incorrect on some
platforms. Passing by reference aligns with the ARM calling convention for
scalable types and enables better code generation for SVE-intensive code.

Thanks [@SwapnilGaikwad](https://github.com/SwapnilGaikwad) for the contribution.

### JIT compiles async methods natively

The JIT now generates native async implementations for synchronous
task-returning methods
([dotnet/runtime #128384](https://github.com/dotnet/runtime/pull/128384)).

When a method returns `Task` or `ValueTask` and the JIT determines that the
async state machine emitted by the C# compiler can be handled more efficiently,
it generates a native async continuation path instead of the heap-allocated
state machine. This reduces allocation pressure and stack overhead for methods
that await a small number of awaitables. The transformation is transparent —
no code changes are required, and the observable async behavior is identical.

## In-process crash report logging

A new in-process crash reporting mechanism captures diagnostic information
from within the crashing process before it terminates
([dotnet/runtime #128105](https://github.com/dotnet/runtime/pull/128105)).

Previously, crash diagnostics were collected by an out-of-process monitor.
While the out-of-process approach is safe (the monitor isn't affected by the
crash), it can miss information that is only available inside the dying
process. The new in-process path logs the managed stack trace, module list,
and key runtime state to a well-known path before the process exits.

## Process start-suspended support

`Process.Start` on Windows now supports launching a process in a suspended state
([dotnet/runtime #129512](https://github.com/dotnet/runtime/pull/129512)).

Set `ProcessStartInfo.StartSuspended = true` to create the process with the
Windows `CREATE_SUSPENDED` flag, then call `Resume()` on the returned
`SafeProcessHandle` to begin execution. This lets you attach to the process,
set job objects, or configure security attributes before the first user-mode
instruction runs.

```csharp
var psi = new ProcessStartInfo("myapp")
{
    StartSuspended = true
};
using var process = Process.Start(psi)!;
// Do setup work here (e.g., assign to a job object)
process.SafeHandle.Resume();
```

## Async continuations without ExecutionContext

Async continuations can now opt out of `ExecutionContext` capture and restore
([dotnet/runtime #128323](https://github.com/dotnet/runtime/pull/128323)).

`ExecutionContext` carries ambient state — such as `AsyncLocal<T>` values —
across `await` points. Every `Task` continuation previously captured a
snapshot of the context and restored it before running, even when no
`AsyncLocal<T>` state was in use and the restore was a no-op.

The runtime now detects when a continuation has nothing to restore and skips
the capture/restore cycle entirely. `Task`, `Task<T>`, `ValueTask`, and
`ValueTask<T>` all benefit from this change, as does the `runtime-async`
implementation path. Applications that use `ConfigureAwait(false)` and
`AsyncLocal<T>` sparingly will see reduced overhead in high-throughput async
code paths.

## NativeAOT: faster interface dispatch

Native AOT now uses a dispatch helper for interface method calls
([dotnet/runtime #123252](https://github.com/dotnet/runtime/pull/123252)).

Instead of a direct fat-pointer call sequence, the runtime routes interface
dispatch through a shared helper that can be patched to the correct
implementation after the call site warms up. This reduces the binary size of
interface call sites and improves throughput on workloads with many interface
method calls.

## SIMD: Lane construction and composition APIs

`System.Runtime.Intrinsics` now includes lane construction and composition
APIs for all hardware vector types
([dotnet/runtime #127690](https://github.com/dotnet/runtime/pull/127690),
[dotnet/runtime #129627](https://github.com/dotnet/runtime/pull/129627)).

The new APIs let you construct a vector from individually specified lanes and
extract or reorder lanes between vectors. This enables precise, portable
control over SIMD vector element placement without falling back to
platform-specific intrinsics:

```csharp
// Construct a Vector128<int> from four individual lane values
var v = Vector128.Create(lane0: 10, lane1: 20, lane2: 30, lane3: 40);

// Extract a lane from one vector and insert it into another
var composed = v.WithElement(2, 99);
// composed = <10, 20, 99, 40>
```

These building blocks are useful for image processing, audio DSP, and other
SIMD-intensive workloads that need fine-grained control over vector element
layout.

Thanks [@SebastianSie](https://github.com/SebastianSie) for the contribution.

## Diagnostics: cDAC loading from SOS installations

The .NET diagnostics infrastructure now supports loading the Compact Data
Access Component (cDAC) from existing SOS (Son of Strike) debugger
installations
([dotnet/diagnostics #5874](https://github.com/dotnet/diagnostics/pull/5874)).

The cDAC provides a compact, versioned description of CLR data structures that
diagnostic tools use to inspect running processes and crash dumps without
depending on hard-coded offsets. Previously, cDAC loading required the component
to be co-located with the runtime. The new support allows cDAC to be discovered
and loaded from an installed SOS extension, enabling newer cDAC capabilities
in environments where SOS is deployed separately — such as within Visual Studio,
dotnet-sos, or crash-dump analysis workflows.

## Bug fixes

- Fixed duplicate disposal of shared singleton instances in `IServiceProvider`.
  Previously, a singleton registered with `AddSingleton` could be disposed
  twice when multiple container scopes shared the same instance and both
  scopes were disposed
  ([dotnet/runtime #128768](https://github.com/dotnet/runtime/pull/128768)).
- Fixed alignment of 8-byte thread statics on the direct TLS path, which
  could cause misalignment faults on platforms with strict alignment requirements
  ([dotnet/runtime #129749](https://github.com/dotnet/runtime/pull/129749)).
- Fixed `ValueType.GetHashCode` for structs with nested generic fields,
  which was producing incorrect hash codes in some cases
  ([dotnet/runtime #129728](https://github.com/dotnet/runtime/pull/129728)).
- Fixed a GC hole when a method return is hijacked for GC suspension —
  the return value could be collected before it was stored
  ([dotnet/runtime #129714](https://github.com/dotnet/runtime/pull/129714)).
- Fixed `JsonSchemaExporter` dropping nullability for nullable floating-point
  composition schemas
  ([dotnet/runtime #129530](https://github.com/dotnet/runtime/pull/129530)).
- Validated DNS hostnames for embedded null characters, which could previously
  cause unexpected behavior in hostname resolution
  ([dotnet/runtime #128982](https://github.com/dotnet/runtime/pull/128982)).
- Validated uncompressed size up front in `ZipArchiveEntry` update mode to
  detect corrupted archives earlier
  ([dotnet/runtime #128319](https://github.com/dotnet/runtime/pull/128319)).
- Fixed `OpenSSL X509Chain` time validity check depending on process time zone
  instead of UTC
  ([dotnet/runtime #129394](https://github.com/dotnet/runtime/pull/129394)).
- Fixed `Socket.Blocking` not being set from the underlying handle when
  constructing a `Socket` from a `SafeSocketHandle`
  ([dotnet/runtime #128433](https://github.com/dotnet/runtime/pull/128433)).
- Fixed an infinite release spin-wait when a `Socket` is closed after its
  handle has already been invalidated
  ([dotnet/runtime #128434](https://github.com/dotnet/runtime/pull/128434)).
- Fixed `FileSystemWatcher` creating an unnecessary recursive watcher in
  `PhysicalFilesWatcher` when only a single file is being watched
  ([dotnet/runtime #128072](https://github.com/dotnet/runtime/pull/128072)).
- Fixed `MarshalAs.IidParameterIndex` not being honored for `out object`
  parameters in source-generated COM stubs
  ([dotnet/runtime #128214](https://github.com/dotnet/runtime/pull/128214)).
- Fixed negative PAX size values in TAR headers being rejected with an
  unhelpful error
  ([dotnet/runtime #128368](https://github.com/dotnet/runtime/pull/128368)).
- Fixed keyed-service probing for built-in DI services
  ([dotnet/runtime #128198](https://github.com/dotnet/runtime/pull/128198)).
- Pre-sized the intermediate `Dictionary` in `ToFrozenDictionary` to reduce
  reallocations for known-size inputs
  ([dotnet/runtime #128300](https://github.com/dotnet/runtime/pull/128300)).
  Thanks [@eiriktsarpalis](https://github.com/eiriktsarpalis) for the contribution.
- Improved `WebSocket` exceptions to include informative messages with connection
  context, making WebSocket failures easier to diagnose
  ([dotnet/runtime #129428](https://github.com/dotnet/runtime/pull/129428)).
- Fixed `NoopLimiter` disposal in `DefaultPartitionedRateLimiter` heartbeat loop
  ([dotnet/runtime #127582](https://github.com/dotnet/runtime/pull/127582)).

## Community contributors

Thank you contributors! ❤️

- [@a74nh](https://github.com/dotnet/runtime/pulls?q=is%3Apr+is%3Amerged+author%3Aa74nh)
- [@DeaglePC](https://github.com/dotnet/runtime/pulls?q=is%3Apr+is%3Amerged+author%3ADeaglePC)
- [@eiriktsarpalis](https://github.com/dotnet/runtime/pulls?q=is%3Apr+is%3Amerged+author%3Aeiriktsarpalis)
- [@hez2010](https://github.com/dotnet/runtime/pulls?q=is%3Apr+is%3Amerged+author%3Ahez2010)
- [@SwapnilGaikwad](https://github.com/dotnet/runtime/pulls?q=is%3Apr+is%3Amerged+author%3ASwapnilGaikwad)
- [@xtqqczze](https://github.com/dotnet/runtime/pulls?q=is%3Apr+is%3Amerged+author%3Axtqqczze)
