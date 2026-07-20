# .NET Runtime in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new runtime features and performance work:

<!-- toc -->

- [JIT improvements](#jit-improvements)
- [`Vector<T>` passed by reference when `VectorT` ISA is available](#vectort-passed-by-reference-when-vectort-isa-is-available)
- [Linker dead-code elimination enabled globally on Unix](#linker-dead-code-elimination-enabled-globally-on-unix)
- [WebAssembly write barriers](#webassembly-write-barriers)
- [Bug fixes](#bug-fixes)
- [Community contributors](#community-contributors)

<!-- tocstop -->

.NET Runtime updates in .NET 11:

- [What's new in .NET 11 runtime](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-11/runtime)

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

## Linker dead-code elimination enabled globally on Unix

Link-time dead-code elimination (`--gc-sections`) is now enabled globally for native builds on Unix. Previously it was opt-in per project. This trims unreachable native code from binaries without any changes to managed source, reducing the size of single-file and NativeAOT outputs ([dotnet/runtime #128232](https://github.com/dotnet/runtime/pull/128232)).

## WebAssembly write barriers

The WebAssembly GC target now emits write barriers during object field stores, enabling the incremental/generational GC to correctly track inter-generational references in browser and WASI runtimes. This is an infrastructure prerequisite for more advanced GC modes on Wasm ([dotnet/runtime #128225](https://github.com/dotnet/runtime/pull/128225)).

## Bug fixes

- Resumption stubs for runtime-async are now laid out adjacent to their async method variants, improving code locality ([dotnet/runtime #128380](https://github.com/dotnet/runtime/pull/128380)).

## Community contributors

No external community contributors were identified for the .NET Runtime in this preview.
