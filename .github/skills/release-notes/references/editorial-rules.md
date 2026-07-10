# Editorial Rules

Tone, attribution, and content guidelines for .NET release notes.

## Tone

- **Positive** — highlight what's new, don't dwell on what was missing
  - ✅ `ProcessExitStatus provides a unified representation of how a process terminated.`
  - ❌ `Previously, there was no way to determine how a process terminated.`
- When context about the prior state is needed, keep it brief — one clause, then pivot to the new capability
- **Don't editorialize beyond the facts** — state what concretely changed ("enabled by default", "no longer requires opt-in") rather than making claims you can't back up ("ready for production use", "signals maturity"). If a PR removes a preview attribute, say that. Don't interpret it as a promise.
  - ✅ `Runtime-async is now enabled by default for anyone targeting net11.0.`
  - ❌ `This signals that runtime-async is ready for production use.`
- **Prefer concrete deltas over inferred outcomes** — say what changed and, if useful, the direct consequence for a real scenario. Avoid claims about trust, confidence, convenience, or behavior unless the source explicitly supports them.
  - ✅ `Regex recognizes all Unicode newline sequences.`
  - ✅ `Tar extraction now rejects entries that would write outside the destination directory.`
  - ✅ `Tar extraction now rejects path traversal entries, helping applications avoid overwriting files outside the target folder.`
  - ❌ `Compression and archive handling are easier to trust.`
  - ❌ `You can extract archives without worrying about attacks.`
- **Prefer short, direct sentences** — If a sentence has a parenthetical clause (`which...`, `where...`, `that...`) longer than a few words, split it into two sentences. Lead with the news, follow with context. Long sentences are fine when they flow as a single continuous thought (what → why); they're not fine when a subordinate clause interrupts the main verb.
  - ✅ `Runtime-async is now enabled for NativeAOT. This eliminates the state-machine overhead of async/await for ahead-of-time compiled applications.`
  - ❌ `The runtime-async feature, which eliminates the state-machine overhead of async/await, is now enabled for NativeAOT.`
  - ✅ `The JIT now generates ARM64 SM4 and SHA3 instructions directly, enabling hardware-accelerated implementations on capable processors.` (long but flows — one thought)
- **Frame conditions by their real prevalence** — don't hedge default or mainline behavior behind a conditional that makes it sound rare or optional. A leading "When X is configured / compiled with Y…" clause signals to readers that the change probably doesn't apply to them, so use it only when X is genuinely uncommon. When a configuration is the default — or is *becoming* the mainline assumption — state the change as the norm and mention the exception second, or not at all. Verify what is actually default before hedging; don't reflexively wrap a change in a condition or erase one that matters.
  - ❌ `On ARM64, Vector<T> values are now passed by reference rather than by value.` (overgeneralizes a change that applies only when the SVE-backed `Vector<T>` instruction set is available)
  - ✅ `When Vector<T> uses the SVE-backed instruction set on ARM64, values are now passed by reference rather than by value. This avoids treating runtime-width SVE vectors as fixed-width 128-bit values.`
- **State the scope — general vs. targeted — and tie it to what the reader builds** — say whether a feature applies broadly or only to specific platforms, app models, or scenarios, and name them. Don't describe a targeted change in general terms: a reader on the wrong platform thinks it applies to them, and a reader on the right platform never realizes it's for them. Ground abstract mechanisms ("the process", "the host") in the reader's apps. Check PR labels (e.g. `os-android`, `os-ios`) and body for the real scope. (This is the mirror of *Frame conditions by their real prevalence*: there, don't make a mainline change sound rare; here, don't make a targeted change sound general.)
  - ❌ `A new in-process crash reporting mechanism captures diagnostic information from within the crashing process before it terminates.` (reads as a general runtime capability; never says it's for mobile apps)
  - ✅ `.NET mobile apps now produce a compact in-process crash report. On Android it's written to logcat under the DOTNET_CRASH tag; on iOS, tvOS, and Mac Catalyst it's emitted to the app log. The report includes per-thread managed stacks and a module table, captured from inside the crashing app before it exits.`
  - ✅ Model done right: `On Windows, SafeProcessHandle.Start can launch a process with ProcessStartInfo.StartSuspended = true. Call Resume() on the returned handle after attaching, setting job objects, or configuring security attributes.` (states the platform — "on Windows" — up front, uses the approved API shape, and makes the motivation concrete)
- **Don't reuse an overloaded platform term in a new sense** — words like `native`, `managed`, `runtime`, and `dynamic` already carry strong, specific meanings in .NET (`native` ⇒ NativeAOT / native interop; `managed` ⇒ managed vs unmanaged code). Borrowing one for a different meaning confuses readers, especially when the note uses it several times. Use the **established feature name** instead (see *Use the established feature name* under Entry naming). A change to how the runtime executes async methods is **runtime-async**, not "native async" — "native" collides with NativeAOT.
  - ❌ `## JIT compiles async methods natively` … "generates native async implementations" … "native async continuation path" (three uses; "native" reads as NativeAOT)
  - ✅ `## Runtime-async compiles dedicated async versions of task-returning methods`

## Prohibited language

Empty filler and marketing phrases that carry no information. Delete them. If removing a phrase loses real meaning, replace it with the concrete fact (what works, what no longer requires configuration, what changed).

The lists below are **examples, not an exhaustive banlist**. The rule is the principle — *no empty filler or marketing wording* — so flag any semantically equivalent phrase even if it isn't spelled out here (e.g. "lightning fast", "first-class experience", "supercharged", "rock-solid", "next-generation").

- **"out of the box" / "out-of-the-box"** — every shipped capability is available by default, so the phrase adds nothing. If the point is that no configuration is required, say that concretely; otherwise just state what the feature does.
  - ✅ `System.Text.Json serializes C# 15 union types.`
  - ✅ `System.Text.Json serializes C# 15 union types with no extra configuration.`
  - ❌ `System.Text.Json now supports C# 15 union types out of the box.`
- **Empty intensifiers and marketing adjectives** — `seamless`/`seamlessly`, `effortless`/`effortlessly`, `simply`, `just` (as in "just works"), `powerful`, `robust`, `blazing fast`, `world-class`, `game-changer`, and equivalents. State the concrete behavior or measured result instead.
  - ✅ `Span-based parsing avoids the intermediate string allocation.`
  - ❌ `The new API makes parsing effortless.`
  - ❌ `This is a powerful, seamless way to parse spans.`
- **Informal or jokey acronym expansions** — don't expand an established acronym into its informal/origin name. The acronym is the proper term; the expansion adds nothing and reads as in-joke jargon. Use `SOS` as-is — never write "Son of Strike".
  - ✅ `loading cDAC from an installed SOS extension`
  - ❌ `existing SOS (Son of Strike) debugger installations`

This list grows as new phrases are flagged in review, but treat it as illustrative — apply the principle, not just string-matching. When in doubt, ask whether the sentence still says the same thing with the phrase removed; if it does, remove it.

## Familiar comparisons

- When a feature matches a workflow developers already know from another tool, say so. A short comparison can make the value obvious faster than a longer explanation.
- Use the comparison to **anchor the mental model**, not to claim perfect parity. Say what is similar, then explain the .NET-specific behavior.
- Prefer common tools and workflows the reader is likely to know already (for example Docker, GitHub Actions, shell usage, or package managers). Skip the comparison if it feels forced or more obscure than the feature itself.

  - ✅ `dotnet run -e FOO=BAR` gives you Docker-style CLI environment-variable injection for local app runs, so you can test configuration changes without editing shell state or launch profiles.
  - ❌ `dotnet run` now works just like Docker. (overstates the similarity)

## Explain when a feature is useful

This operationalizes the **WHY** half of the WHY/HOW rule in
[`quality-bar.md`](quality-bar.md). After the description and code sample, close
with a short statement of **when** the feature helps — name one or two concrete
scenarios. Without it, many features read as a mechanical API addition and the
reader can't tell why the feature exists or whether it applies to them.

- Lead with the concrete scenarios, not a restatement of the API. "This is useful when X or when Y" beats "This gives you more flexibility."
- Especially important for configuration knobs, extensibility hooks, and overridable defaults, where the value is the *scenario it unlocks*, not the API shape.
- One or two scenarios is enough — don't pad with a list of every hypothetical use.

✅ Good — a configurable delegate whose value is clear from the closing scenario sentence:

````markdown
`EnvironmentVariablesConfigurationProvider` now accepts a configurable
`VariableNameTransformation` delegate that controls how environment variable
names are mapped to configuration keys ([dotnet/runtime #127503](...)).

By default, the provider converts `__` to `:`. The new delegate lets you
override that logic:

```csharp
builder.Configuration.AddEnvironmentVariables(options =>
{
    options.VariableNameTransformation = name =>
        name.Replace("APP_", "", StringComparison.Ordinal)
            .Replace("__", ":", StringComparison.Ordinal);
});
```

This is useful when deploying to environments that follow a different naming
convention, or when running multiple apps in the same process that should each
consume a scoped prefix of environment variables.
````

❌ Weak — same feature, no scenario, so the reader can't tell why it exists:

```markdown
`EnvironmentVariablesConfigurationProvider` now accepts a
`VariableNameTransformation` delegate. This gives you more flexibility and
control over configuration keys.
```

### Features with no code surface

Some features are automatic — security hardening, JIT/codegen wins, transparent
performance improvements — and expose no API the developer calls. Don't force a
code sample. Let the body carry the value instead: **what** it does, **why** it
matters, that it requires **no action**, and **where** it applies (hardware,
platform, or target framework). This is the legitimate exception to the
"if you can't write a code sample, question whether it's user-facing" guidance
in [`quality-bar.md`](quality-bar.md) — a transparent platform win still belongs
in the notes when the prose makes its value concrete.

✅ Good — an automatic performance improvement with no new API; the body
explains the mechanism, the measured benefit, and its hardware scope:

```markdown
The JIT now uses a shorter widening-and-multiply sequence for 8-bit vector
multiplication on x64 ([dotnet/runtime #126348](...)). The PR's benchmark
improved by approximately 2x. Existing code that multiplies byte vectors
benefits without source changes.
```

Do not use an opt-in feature as this example. For instance, PAC-RET in Preview 6
is disabled by default and requires `DOTNET_JitPacEnabled=1`; describing it as
automatic would be a factual error.

**Calibration — the floor for a transparent perf/behavior win.** A lean section
still passes when it names the **mechanism** and **who benefits**, even without
a code sample or much background. Adding either would strengthen it, but neither
is required.

- ✅ Passing (lean): *Runtime-async ValueTask continuations avoid
  ExecutionContext work* — explains the mechanism (`ValueTaskContinuation`
  doesn't save or restore `ExecutionContext`) and names the affected path
  without claiming that all `Task` and `ValueTask` continuations changed. No
  code sample, but the scope and benefit are concrete.

### Don't assume the reader knows the API or feature

This applies to any **niche or specialized surface** — not just managed APIs,
but CLI commands and options (`dotnet ef migrations bundle`), MSBuild properties,
project/template knobs, and tooling features. Say **what it is and who uses it**
before describing the improvement. If you optimize or extend a surface most
readers have never heard of, anchor them first — one clause on what it does and a
typical use — or the change reads as noise. Implementation detail (which
instruction the JIT emits, which helper call was removed) is **not** a substitute
for explaining relevance. When even a one-line explanation can't make a recurring
perf tweak matter to a broad audience, fold it into the `## JIT improvements` /
`## <Area> improvements` cluster, or cut it under the 80/20 filter.

❌ Weak — assumes the reader already knows what `BigMul` is; the body explains the codegen but never what the API computes or who needs it:

```markdown
`Math.BigMul(long, long, out long)` is now significantly faster on x64
([dotnet/runtime #117261](...)).

The JIT generates a single `MUL r/m64` instruction when both operands are
64-bit values and the caller requests the high half of the result. Previously
the JIT emitted a helper call.
```

✅ Better — one clause says what `BigMul` computes and where it shows up, so a reader who has never used it can judge relevance before the codegen detail:

```markdown
`Math.BigMul` computes the full 128-bit product of two 64-bit integers,
returning the low and high halves separately. It shows up in big-integer
arithmetic, hashing, and fixed-point math. On x64 it is now significantly
faster: for the high-half case the JIT emits a single `MUL r/m64` instruction
instead of a helper call ([dotnet/runtime #117261](...)).
```

### Define domain terms on first use

This is the **vocabulary** counterpart to the rule above (which is about the API
or feature). When a section depends on a specialized domain term — `lane`,
`epoch`, `arena`, `tier`, `shard`, `prolog`, `discriminator` — define it in a
short clause the first time it appears, especially when the term recurs in the
heading, prose, and code comments. A reader who doesn't already know the term
can't follow the section no matter how good the rest is. One clause is enough;
then use the term freely.

❌ Weak — "lane" appears in the heading, prose, and code comments, but the section never says what a lane is:

```markdown
## SIMD: Lane construction and composition APIs

The new APIs let you construct a vector from individually specified lanes and
extract or reorder lanes between vectors.
```

✅ Better — one clause defines the term on first use, then the section proceeds:

```markdown
A *lane* is a single element slot within a SIMD vector — a `Vector128<int>`
holds four `int` lanes. The new APIs let you construct a vector from individual
lane values and extract or reorder lanes between vectors.
```

**Exception — established acronyms used as proper names.** Well-known acronyms
that function as a tool or product name (`SOS`, `JIT`, `GC`, `AOT`) are used
bare; they need no definition, and some should **not** be expanded at all (see
*Informal or jokey acronym expansions* under Prohibited language — write `SOS`,
not "Son of Strike"). Define genuinely unfamiliar terms; don't gloss the ones
every reader already treats as a name.

### Show the reader's code, not the runtime's

Code samples default to **your code** — what the *developer* writes, calls, or
observes — not **our code**, the runtime/compiler internals. The reader should
see themselves in the snippet.

- This is why a lean codegen item can still pass: the `SELECT(cond, cns, cns) → cns` JIT fold illustrates with `int x = condition ? 42 : 42;` — internal optimization, but the snippet is code a developer actually writes.
- Documenting **our code** — emitted assembly, generated IL, JIT pseudo-code, runtime-internal mechanics — is allowed but clears a **higher bar**: the emitted output must *be* the news (a codegen/intrinsics story), there must be a benefit the reader can see or measure, and it should still be paired with the C# the reader would write to trigger it. Use it sparingly.
- A snippet that only shows how the runtime is implemented, with no reader-facing code and no measurable payoff, is implementation trivia — cut it or route the change to **Bug fixes**.

  - ✅ `int x = condition ? 42 : 42;` — your code; the reader writes this.
  - ✅ An `asm` before/after **paired** with the C# that produces it, in a JIT/intrinsics section where the emitted instruction is the headline.
  - ❌ A standalone block of emitted assembly or JIT-internal pseudo-code with no C# and no stated, observable benefit.

## Lead with the significance — don't bury the lede

When a change is part of a named, in-progress feature, **name that feature and
lead with what the change means** — not a generic mechanical description.
Readers scan headings for the story; a vague or invented heading hides a
significant change. Before writing a heading, check `changes.json`/PR labels for
the real feature it belongs to (see *Use the established feature name* below).

- PR #128384 ("Compile runtime async versions of synchronous task-returning methods", labeled `runtime-async`) is part of the **runtime-async** effort: the JIT now compiles a dedicated runtime-async version of an ordinary `Task`/`ValueTask` method instead of delegating through thunks to the synchronous version. The lede is "runtime-async now covers ordinary task-returning methods," not "compiles async natively."
  - ❌ `## JIT compiles async methods natively` (invented, vague, and buries the runtime-async story behind an overloaded term)
  - ✅ `## Runtime-async now compiles ordinary task-returning methods` — with a body that frames the change as a runtime-async advance and links the backing issue/PR.

## Frame against the likely misreading

Before finalizing a section, ask what wrong conclusion a reader could draw —
especially one that **contradicts .NET's known direction** — and preempt it. A
technically accurate description can still mislead when it omits the intent. This
needs real understanding of the change: read the PR's *motivation*, not just its
mechanics.

The async-profiler case is the canonical example. PR #129043 extends the async
profiler to the **V1 (compiler state-machine) async path**. Because runtime-async
(V2) is the strategic focus, "new V1 instrumentation" reads as backtracking — as
if the team is investing in the old model against its own plan. The PR's actual
motivation is the opposite: the profiler was built for V2 first, and this brings
**V1 to parity** because V1 is still the dominant async path in the wild, so both
models now emit a **uniform event stream** and tools can attribute time across
**mixed async stacks** without knowing which model produced a chain. Say that, or
the reader infers inconsistency.

- ❌ `The V1 TaskAsync instrumentation layer inserts probes at async state machine transitions…` (presents V1 instrumentation in isolation; the reader wonders why we're investing in "v1" when v2 is the focus)
- ✅ `The async profiler — first built for runtime-async (V2) — now also instruments the compiler state-machine (V1) path, which remains the dominant async model. Both emit the same event stream, so a profiler can attribute time across mixed async stacks without knowing which model produced each chain.`

## Attribute the motivation correctly

Closely related: state *why* a change happened, and don't dress up a **forced or
structural** change as an optional convenience. The ergonomic benefit may be
real, but when a change is a **consequence of a larger model**, that driver is
the point — omitting it leaves the reader with a wrong mental model (they think
the old way is still fine and this is just a nicer alternative).

The `unsafe` fields case (C# Unsafe Evolution): the note frames field-level
`unsafe` purely as ergonomics — "limit the unsafe surface", "reduce the blast
radius". The real driver is the model itself: marking a **whole type** `unsafe`
is being removed, so member-level annotations (including `unsafe` fields) become
the **required** path for fields that need an unsafe context, not a
nicer-but-optional one. The narrower surface is a genuine benefit, but it is a
*consequence* of the type-level option going away — verify which it is before
writing, because "you can now…" wrongly implies the old approach still works.

- ❌ `Previously you had to make the whole type unsafe; now you can declare the field itself as unsafe, limiting the unsafe surface.` (reads as opt-in ergonomics; implies whole-type `unsafe` is still an option)
- ✅ `As part of Unsafe Evolution, unsafe is moving to the member level — marking a whole type unsafe is going away, and unsafe fields are the replacement for fields that need an unsafe context. The narrower unsafe surface is a benefit of that model change, not a standalone convenience.`

## Entry naming

- Prefer a **brief description** of what the feature does over the API name alone
  - ✅ `## Support for Zstandard compression`
  - ✅ `## Faster time zone conversions`
  - ❌ `## ZstandardStream`
  - ❌ `## TimeZoneInfo performance`
- Prefer **specific, customer-facing verbs** over generic `gets` phrasing. Name the capability the customer now has: `offers`, `adds`, `supports`, `recognizes`, `enables`, and similar verbs are usually stronger.
  - ✅ `## System.Text.Json offers more control over naming and ignore defaults`
  - ✅ `## Regex recognizes all Unicode newline sequences`
  - ❌ `## System.Text.Json gets more control over naming and ignore defaults`
- **Don't use `gains`, `joins`, or `gets`** — in headings *or* prose. Components and namespaces have no agency, and these verbs are vague: "X gains Y" hides whether Y is new, moved, or merely expanded, and it foregrounds the container (`System.IO`) instead of the capability. A literal term is essentially always available — prefer `now includes`, `now provides`, `adds`, `adds support for`, `supports`, `moves to`, `is now in`, `has been updated to`. Better still, lead with the capability rather than the namespace.
  - ✅ `System.IO now includes Stream wrappers for in-memory buffers and text sources.`
  - ✅ `You can now wrap a ReadOnlyMemory<byte> or TextReader as a Stream without copying into a MemoryStream first.` (leads with the capability)
  - ❌ `System.IO gains new Stream wrapper types.`
  - ✅ `## Zstandard moved to System.IO.Compression and ZIP reads validate CRC32`
  - ✅ `The Virtualize<TItem> component now supports variable-height items for its AnchorMode parameter.`
  - ✅ `Virtualize<TItem> has been updated to anchor scroll position correctly when items have varying heights.`
  - ❌ `## Zstandard joins System.IO.Compression and ZIP reads validate CRC32`
  - ❌ `The Virtualize<TItem> component gains variable-height support for its AnchorMode parameter.`
- Use the **established feature name** when one exists, especially for long-running preview features. If `release-notes/features.json` lists an `official_name`, use that in headings and prose. Treat aliases as match-only metadata, not as the default wording.
  - ✅ `## Unsafe Evolution remains a preview feature in .NET 11`
  - ✅ `## Unsafe Evolution adds clearer diagnostics in Preview 3`
  - ❌ `## Memory Safety v2 adds clearer diagnostics in Preview 3`
  - ❌ `## Unsafe code adds clearer diagnostics and annotations`
- Keep headings concise — 3–8 words
- **Backtick all code identifiers in headings and link text** — type names (`Virtualize<TItem>`), method names (`Random.NextInteger<T>`), directives (`#:ref`, `#:package`), namespaces (`System.Net.Http.Json`), and constants. Unticked code-like text in headings breaks the GitHub-compatible heading-slug algorithm that markdownlint MD051 enforces — e.g. `## File-based apps: #:ref directive` is rejected because the inline parser drops `#:ref`; `## File-based apps: \`#:ref\` directive` is accepted and slugs cleanly. The publish-step TOC regenerator can fix wrong anchors but cannot fix wrong headings.
  - ✅ `` ## `#:ref` directive for file-based app dependencies ``
  - ✅ `` ## `Virtualize<TItem>` supports variable-height items in AnchorMode ``
  - ✅ `` ## `System.Net.Http.Json` added to implicit usings ``
  - ❌ `## File-based apps: #:ref directive for NuGet packages`
  - ❌ `## Virtualize<TItem> supports variable-height items in AnchorMode`
- **Always specify a language on fenced code blocks** — markdownlint MD040 blocks publish on any unlabeled ` ``` ` fence. Use the actual language for runnable snippets (`csharp`, `bash`, `json`, `xml`, `powershell`, `console`, `diff`), and use `text` for plain output, file trees, or pseudo-code where no language fits. This includes README.md tables of contents, runtime.md JIT codegen snippets, and every other fenced block — there is no exception.
  - ✅ ` ```csharp `, ` ```bash `, ` ```json `, ` ```text `
  - ❌ ` ``` ` (bare triple-backtick with no language)

## Benchmarks

- Use **exact data** from PR descriptions — never round, approximate, or paraphrase
- State what was measured and the hardware/workload context
- Include specific before/after measurements when compelling
- Do **not** embed full BenchmarkDotNet tables — summarize in prose

## What to include

- **Shared audience filter** — apply the 80/20 rule from `editorial-scoring`; don't redefine a competing threshold here. Keep narrower items only when the broader audience can still see why they matter.
- **The two-sentence test** — if you can only write two sentences about a feature, it's probably an engineering fix, not a feature. Cut it. A community contribution or breaking change can lift a borderline entry, but "fixed an internal bug that happened to be visible" is not a feature.
- **Bug-fix titles are bug fixes by default** — if the PR title starts with or contains `Fix`, `Fixed`, `Fixes`, `bugfix`, `correct`, `resolve`, or describes patching incorrect behavior, treat the change as a bug fix and route it to the **Bug fixes** section. Do **not** promote it into a top-level feature heading, do **not** dress it up with a feature-style heading (e.g. "`Component X` security fix" or "`Component X` reliability fix"), and do **not** include "fix" in the heading. Override this default only when **all three** of the following are true:
  1. The change introduces a new public API surface, a new user-visible option, or a new default behavior — not just corrected existing behavior.
  2. A typical upgrader needs to know about it (not just the small set of users who hit the original bug).
  3. You can write more than two sentences of meaningful guidance — what to do with it, when to use it, what changes for the reader.
  If any of those fail, the entry belongs in **Bug fixes**.
- **Security and reliability work is usually a bug fix** — CVE-class fixes, input-validation hardening, and crash/hang/leak repairs almost always belong in the Bug fixes section. Lift them into a feature heading only when the work *also* introduces a new public option or a new default behavior the reader should know about.
- **Headlines should convey value** — a heading like "GC regions on macOS" doesn't tell the reader whether this is good or bad. Prefer headings that hint at the benefit: "GC regions enabled on macOS" or "Server GC memory model now available on macOS."
- **Product-boundary rule** — exclude higher-level IDE, editor, or design-time tooling features from product notes unless the release is specifically about that tooling surface. For example, a Razor editor code action should not be presented as an ASP.NET Core feature just because it is adjacent to the web stack.
- **TODO for borderline entries** — when a feature might deserve inclusion but you lack data to justify it (benchmark numbers, real-world impact, user demand), keep the entry but add an HTML `<!-- TODO -->` comment asking for the missing information. This is better than silently including a vague claim or silently cutting something that might matter. The TODO should state what's needed and link to the PR where the data might live.
- **Breaking changes are separate from hype** — a breaking change can be important even when it is not exciting. Keep the score honest; use `breaking_changes: true` to preserve a short callout instead of inflating the item into a headline feature.
- **Clusters can be stronger than the parts** — several related low-score items can justify one section when together they tell a clear story. Keep the individual scores honest, then merge them into one writeup instead of emitting several weak mini-features. Good examples include a group of "Unsafe evolution" changes or multiple runtime entries prefixed with `[browser]`.
- **Merge incremental work into a single "[Area] improvements" section** — when a milestone contains **three or more** small, related changes within the same long-running feature or subsystem (e.g. multiple JIT optimizations, multiple Runtime-async refinements, multiple Native AOT size wins, multiple GC tuning changes), emit **one** section titled `## <Area> improvements` (or `## <Feature> improvements`) instead of one heading per PR. Reserve standalone headings for items that genuinely warrant their own story (a new public API, a default behavior change, a major perf claim with benchmarks). Prefer the simpler `improvements` name over invented umbrella terms — readers scan for the area, not for clever phrasing.

  **Choose the right shape for the cluster:**

  - **Code-pattern clusters (JIT, codegen, runtime perf, GC tuning, AOT size, vectorization, intrinsics)** — these almost always benefit from **showing the pattern**. Use a brief intro paragraph, then either short prose-with-snippets paragraphs (one per change, with the PR link inline) or `###` sub-headings when each item warrants more than one paragraph. Include a small `csharp` (and occasionally `asm`) snippet that illustrates **what the developer would write or observe**, not the implementation detail. Prefer minimal, runnable-looking examples over excerpted PR descriptions.

    Example (prose-with-snippets):

    ````markdown
    ## JIT improvements

    Several JIT optimizations landed this preview that benefit normal C# without any source changes.

    Common patterns like multi-target `switch` expressions now fold into simpler branchless checks ([dotnet/runtime #124567](...)), index-from-end access can drop more redundant bounds checks ([dotnet/runtime #124571](...)), and `uint` → `float`/`double` casts are faster on pre-AVX-512 x86 hardware ([dotnet/runtime #124114](...)).

    ```csharp
    bool isSmall = x is 0 or 1 or 2 or 3 or 4;
    int tail = values[^1] + values[^2];
    double d = someUint;
    ```
    ````

    Use `###` sub-headings (as in past `## JIT optimizations` sections) when individual items merit a paragraph of explanation plus a code sample — for example, an inlining improvement with a before/after pattern, or a bounds-check elimination that needs a few lines of C# to make the pattern recognizable.

  - **Behavioral / library clusters (Runtime-async refinements, AsyncLocal flow, EventSource additions, etc.)** — a bullet list is fine when each item is a small behavior tweak without a meaningful code pattern to show. One bullet per PR with a one-line summary and the linked PR reference.

    ```markdown
    ## Runtime-async improvements

    Several refinements landed this preview that reduce overhead and improve diagnostics for runtime-async:

    - Lower suspend/resume overhead on the common path ([dotnet/runtime #12345](...))
    - `AsyncLocal<T>` values are now preserved across runtime-async awaits ([dotnet/runtime #12346](...))
    - `EventSource` tracing now reports runtime-async transitions ([dotnet/runtime #12347](...))
    ```

  The threshold is **three or more** related items. Two related items can stay as two short adjacent sections if each tells a meaningful story on its own; collapse them only when both would otherwise be two-sentence stubs. When in doubt for code-pattern clusters, look at the past two milestones' `runtime.md` for the established shape and match it.

## Feature ordering

Order features using three tiers, applied in order:

1. **Broad interest first** — features most developers will care about go at the top. A new `RegexOptions` value ranks above an ARM64-only instruction set.
2. **Cluster related features** — group related items together even if they differ in importance. All Regex work in one block, all System.Text.Json work in another, all JIT work together. Readers scan by area.
3. **Alphabetical within a cluster** — when features within a cluster have roughly equal weight, alphabetical order makes them scannable.

Use PR and issue reaction counts as a signal for tier 1, but apply judgment — a niche feature with 100 reactions may still rank below a broadly useful one with 10.

**Don't scatter related sections.** The most common ordering failure is splitting items about the same area across the document — for example two `Async …` sections with unrelated material between them. Related sections should be **adjacent**. If a milestone has a second section on an area already covered, move it next to the first (or merge them per the clustering rules under *What to include*). This matters most on longer documents (roughly 6+ sections); on short component files the reading cost of distance is low, so reach for consistent naming rather than fussing over exact order.

**Consistent naming makes alpha ordering cluster for you.** Alphabetical ordering is the simplest rule to apply consistently, and when sibling sections share a leading token it produces category clustering automatically — `Async continuations …` and `Async profiler …` sort together under an `Async` prefix without any manual judgment. Prefer naming related sections with a shared prefix so alpha order keeps them adjacent, rather than relying on hand-placement. A small number of marquee, broadly-interesting features can still be lifted to the top (tier 1); order the rest alphabetically and let consistent naming do the clustering.

## Community attribution

### Inline

When a documented feature was contributed externally:

```markdown
Thank you [@username](https://github.com/username) for this contribution!
```

### Community contributors section

At the bottom of each component's notes, list ALL external contributors — not just those with documented features. Any community contributor with **one or more merged PRs** in the milestone should get a mention exactly once in the **Community contributors** section, even if none of their work was promoted into a feature writeup. Use the `community-contribution` label as a strong signal, but do not rely on it exclusively if the merged PR history shows a clear external contribution.

**Vet the list** — the `community-contribution` label is sometimes wrong. Exclude Microsoft employees. The `-msft`/`-microsoft` suffix is only a weak first filter: **most Microsoft engineers have no suffix** (for example `@baronfel`, `@cshung`, `@jbevain`, `@eiriktsarpalis`, `@sebastienros`), so suffix-matching alone will leak employees into the community list. When a contributor isn't obviously external, verify before crediting — check their GitHub profile's company/affiliation or their PR history on dotnet repos — and when still in doubt, leave them out. Deterministic authorship/affiliation checking belongs in the `changes.json` validation pass; the editorial pass should treat any unverified name as "leave out".

**Never credit bots or automation accounts.** Bots are not community contributors. Exclude them from both the inline "Thank you" and the Community contributors section — both for individual feature credit and for the aggregated list. This includes `@Copilot`, `@dependabot`, `@github-actions`, `@renovate`, `@nuget-team`-style automation, and any account whose work is a bot-authored or bot-assisted PR. If a PR is co-authored by a human and a bot, credit the human only.

- ❌ `Thanks [@Copilot](https://github.com/Copilot) ([@EgorBot](https://github.com/EgorBot)) for contributions.`
- ✅ Omit the attribution entirely when the change has no human community author.

```markdown
## Community contributors

Thank you contributors! ❤️

- [@username](https://github.com/<owner>/<repo>/pulls?q=is%3Apr+is%3Amerged+author%3Ausername)
```

## Bug fixes section

After features but before community contributors, include a grouped bug fix summary when there are noteworthy fixes. When citing the source work, use linked `org/repo #number` references with a space before `#`:

```markdown
## Bug fixes

- **System.Net.Http**
  - Fixed authenticated proxy credential handling ([dotnet/runtime #123363](https://github.com/dotnet/runtime/issues/123363))
- **System.Collections**
  - Fixed integer overflow in ImmutableArray range validation ([dotnet/runtime #124042](https://github.com/dotnet/runtime/pull/124042))
```

Group by namespace/area. Don't include test-only, CI, or infra fixes.

## Preview-to-preview feedback fixes

Include a bug fix when ALL of these apply:

1. The issue was filed after the previous preview shipped
2. It was reported by someone outside the team
3. A fix shipped in the current preview

Frame positively: "Based on community feedback, X now does Y."

If the fix is for a feature that was never really announced or is still obscure to most readers, do **not** turn that fix into a standalone feature entry. It usually belongs in the bug-fix bucket, and often scores around `1`.

## Preview-to-preview deduplication

When prior previews already documented a feature, don't repeat the same information. But **do** document significant state changes in the current preview. A feature that was introduced as opt-in in P1 and is now enabled by default in P3 is new news — document the change in state, not the feature from scratch.

Ask: "What changed about this feature since the last preview's release notes?" If the answer is meaningful to users (enabled by default, no longer experimental, major perf improvement, new sub-features), write about that. If the answer is just "more PRs landed in the same area," skip it.

Examples:

- ✅ "Runtime-async is now enabled by default for anyone targeting `net11.0`." (state change: opt-in → default)
- ✅ "The Regex source generator now handles alternations 3× faster." (new perf data)
- ❌ Repeating the full explanation of what runtime-async is from P1 (already documented)
- ❌ "More JIT optimizations landed this preview." (no specific news)

## Filtered features

When you cut a feature for failing the 20/80 rule or two-sentence test, record it in an HTML comment block in the output file. This creates a learning record — future runs and human reviewers can see what was considered and why it was excluded.

Place the comment block immediately before the Bug fixes section:

```html
<!-- Filtered features (significant engineering work, but too niche for release notes):
  - Feature name: one-sentence description of the work. Why it was cut.
  - Another feature: description. Reason.
-->
```

Good filter reasons:

- **Internal infrastructure** — "Implementation detail of the Mono → CoreCLR unification. Developers don't target the interpreter."
- **Too narrow** — "Only affects COM interop startup — very narrow audience."
- **Engineering fix, not a feature** — "Two sentences max. No user-visible behavior change beyond a perf number."
- **Provider extensibility** — "Only matters to database provider authors, not EF Core users."

The comment is invisible to readers but preserved in the file for the next person (or agent) who reviews the notes.
