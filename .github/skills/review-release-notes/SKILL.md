---
name: review-release-notes
description: >
  Review `features.json` scores and draft release notes against the editorial
  examples and the shared `editorial-scoring` rubric. Use it to identify
  over-scored, under-scored, or missing features before publishing release
  notes. DO NOT USE FOR: generating `changes.json` or writing the first draft.
---

# Review Release Notes

Audit a scored `features.json` file and its markdown draft from the perspective of the **reader**, not the implementer.

This is the **editorial QA stage** of the pipeline. Its job is to make sure the release notes feel curated, legible, and exciting to the right audience — not like an API inventory.

This skill **reuses the shared rubric** from [`editorial-scoring`](../editorial-scoring/SKILL.md). It critiques the scoring; it does not invent a separate scoring philosophy.

## When to use

- After `generate-features` produced `features.json`
- After `release-notes` drafted the markdown
- When the selection feels too broad, too niche, or too internally focused
- When you want to compare the current draft against the examples and recalibrate the cut

## Inputs

Review these, in order:

1. `changes.json` — the source of truth for what shipped
2. `features.json` — the scored candidate list, if present
3. Draft markdown files (`libraries.md`, `runtime.md`, `sdk.md`, etc.)
4. Editorial examples in `references/examples/`
5. The scoring and quality bar references:
   - `../editorial-scoring/SKILL.md`
   - `references/feature-scoring.md`
   - `references/quality-bar.md`

If `features.json` does not exist yet, infer the current implicit scoring from:

- which features were promoted to headings
- how much space each feature received
- what was grouped into bug-fix buckets or omitted

## Core review questions

Use the shared rubric from [`../editorial-scoring/SKILL.md`](../editorial-scoring/SKILL.md)
rather than inventing a new one here. In particular:

- keep the same reader-centric `10 / 8 / 6 / 4 / 2 / 0` scale
- apply the same 80/20 audience filter
- compare the draft against the examples to see whether it still teaches instead
  of merely enumerating

### Example check

Compare the draft against the component examples:

- Does the length match the importance?
- Are medium-value items grouped instead of getting their own heavyweight sections?
- Are performance stories backed by evidence?
- Does the draft teach, not just enumerate?

## Common failure modes

- **Over-scoring** — too many `4-6` items are promoted to top-level sections
- **Under-explaining** — a real `8+` feature is present but buried or not framed clearly
- **API inventory mode** — the draft starts mirroring `api-diff` instead of telling a user story
- **Technical novelty bias** — clever implementation details outrank practical user value
- **Missed revert** — a promoted feature was later backed out or does not appear in the actual build
- **Bug-fix-as-feature** — a `Fix`/`correct`/`resolve` change, or a pure internal refactor, is promoted to a top-level feature heading instead of routed to the Bug fixes bucket
- **Impenetrable internal jargon** — a section leans on compiler/runtime-internal terms (e.g. "instruction group / IG", "prolog", "helper call") without explaining what the reader gains
- **Unexplained niche API** — the section optimizes or extends an API most readers have never heard of, but never says what it is or who uses it
- **Value not stated** — no "useful when…" scenario and no plain-language reason the feature exists; the reader can't tell whether it applies to them

## Hard reject / rewrite triggers

These are concrete, checkable defects that should **always** be flagged — not
matters of taste. Each maps to a rule in
[`../release-notes/references/editorial-rules.md`](../release-notes/references/editorial-rules.md);
when guidance changes there, mirror it here. For each hit, return the file,
heading, the rule violated, and a suggested fix (rewrite, demote to Bug fixes,
group into an `## <Area> improvements` cluster, or cut).

1. **Prohibited language** — empty filler and marketing wording. The named set
   ("out of the box / out-of-the-box", `seamless`, `effortless`, `simply`,
   `just works`, `powerful`, `robust`, `blazing fast`, `world-class`,
   `game-changer`) is **illustrative, not exhaustive** — also flag equivalents
   ("lightning fast", "first-class experience", "supercharged", "rock-solid").
   Apply the principle, not just string-matching. Also flag **informal/jokey
   acronym expansions** (e.g. "Son of Strike" for `SOS`) — use the bare acronym.
   → Delete or replace with the concrete fact. (editorial-rules: *Prohibited language*)
2. **Bug-fix-as-feature** — heading describes a fix/refactor with no new public
   API, option, or default behavior. → Demote to **Bug fixes** unless all three
   override conditions hold. (editorial-rules: *Bug-fix titles are bug fixes by default*)
3. **Impenetrable internal jargon** — internal codegen/runtime/subsystem terms
   (JIT, GC, codegen, loader, tooling internals — not only JIT) carry the
   section and there is no plain-language "what you gain". → Cut, or fold into a
   `## <Area> improvements` cluster. (quality-bar: *unexplained engineering jargon*)
   - **Calibration — don't over-fire.** A *lean* item still **passes** when it
     shows a concrete before/after pattern **and** says when it occurs, even if
     the heading is symbolic. Reject only when neither is present. (The examples
     below are JIT, but the calibration applies to any internal subsystem.)
     - ✅ Passing (lean): `SELECT(cond, cns, cns) → cns` — a symbolic heading,
       but the body shows `int x = condition ? 42 : 42;` → folds to `42` and
       notes it occurs "after earlier optimizations unify branches."
     - ❌ Reject: `single-IG prolog restriction removed` — "instruction group"
       carries the section, no code pattern, no reader-visible gain.
4. **Missing WHY / scenario** — no "useful when…" sentence and no stated problem
   the feature solves. → Add a concrete scenario, or cut if none exists.
   (editorial-rules: *Explain when a feature is useful*)
5. **Unexplained niche API or surface** — a specialized surface (managed API,
   **CLI command/option, MSBuild property, template/tooling knob**) is improved
   without one clause on what it is and who uses it. → Add the anchor clause
   before the implementation detail. (editorial-rules: *Don't assume the reader knows the API or feature*)
6. **Bot or Microsoft attribution** — inline thanks or Community contributors
   list includes a bot (`@Copilot`, `@dependabot`, `@github-actions`, …) or a
   Microsoft employee. The `-msft`/`-microsoft` suffix is only a weak filter —
   **most Microsoft engineers have no suffix** (e.g. `@baronfel`, `@cshung`,
   `@jbevain`). When a name isn't obviously external, treat it as unverified and
   leave it out (deterministic affiliation checking belongs in the changes.json
   validation pass). → Remove; credit the human external author only, or omit.
   (editorial-rules: *Community attribution*)
7. **Broken or mistyped references** — an issue linked as `/pull/<n>` (or vice
   versa), or a `url` that does not resolve. → Fix the link type/number against
   the source. (changes.json validation)
8. **Implementation-only code sample ("our code")** — a snippet shows
   runtime/compiler internals (emitted asm, generated IL, JIT pseudo-code) with
   no reader-facing C# and no observable payoff. → Pair it with the developer's
   code and a stated benefit, or cut. (editorial-rules: *Show the reader's code, not the runtime's*)
9. **Undefined domain term** — a specialized term (`lane`, `epoch`, `arena`,
   `tier`, `shard`, `discriminator`, …) recurs across the heading/prose/code but
   is never defined. → Add a one-clause definition on first use.
   (editorial-rules: *Define domain terms on first use*)

## Multi-model review pattern

For the final editorial QA pass, use this skill as a **two-reviewer parallel check** to get broader viewpoint diversity:

Preferred set:

1. **Claude Opus 4.6**
2. **GPT-5.4**

Give both reviewers the same inputs and the same requested output:

- most correct scoring
- most wrong scoring
- important omissions
- cut list

Then synthesize the overlap and disagreements. Treat consensus as a strong signal, but do **not** turn this into a blind vote — fidelity to `changes.json`, the shared `editorial-scoring` rubric, and the repo's editorial rules still wins.

## Reviewer checklist

Do not ask reviewers the vague question "do you like this?" Give them the same
specific checks instead:

1. **Which headings *or sentences* still sound vague, passive, anthropomorphic, or promotional** — including agency verbs like `gains`/`joins`/`gets` ("X gains Y")? (editorial-rules: *Entry naming*)
2. **Which sections fail the 80/20 reader-value test and should be cut, grouped, or demoted?**
3. **Which sentences infer feelings or outcomes (`trust`, `confidence`, `easier`, `better`) instead of stating the concrete change?**
4. **Which sections drift into API-inventory mode instead of teaching a user-facing story?**
5. **Which promoted items were later reverted, backed out, or are missing from the actual build/package set? Cite the revert PR or verification gap.**
6. **Which code samples or examples are weak, confusing, or unsupported by the text?**
7. **Which links, issue/PR references, or formatting details still violate house style?**
8. **What is the single highest-value rewrite still needed in the draft?**
9. **Is the wording conventional, or is it inventing non-standard phrasing or terms?** *(Lower-confidence taste check — only raise with a concrete, named alternative; do not flag on vibes.)*
10. **Are the subject and its adjective or adverb paired in a familiar way?** *(Lower-confidence taste check — same caveat as 9.)*
11. **Would this phrasing seem normal in release notes for another developer platform?** *(Lower-confidence taste check — same caveat as 9.)*
12. **If `release-notes/features.json` lists this feature, does the section begin with the standard preview blockquote?**
13. **Does any section hit a hard reject/rewrite trigger above** (prohibited language, bug-fix-as-feature, impenetrable jargon, missing WHY, unexplained niche API, bot/Microsoft attribution, broken reference, implementation-only "our code" sample, undefined domain term)? List each with file + heading + the trigger.
14. **Does any section misstate scope?** Either (a) it hedges a mainline/default change behind a "when X is configured / compiled with Y" conditional that makes it sound rare, or (b) it describes a *targeted* change (platform/app-model/scenario-specific — check PR labels like `os-android`, `os-ios`) as a general capability without naming the scope or tying it to the reader's apps. Flag it and suggest the corrected framing. (editorial-rules: *Frame conditions by their real prevalence*, *State the scope*)
15. **Does any heading invent a vague label, reuse an overloaded platform term (e.g. "native") in a new sense, or otherwise bury a named in-flight feature (e.g. runtime-async)?** Name the established feature and suggest a heading that leads with the real significance. (editorial-rules: *Lead with the significance*, *Use the established feature name*)
16. **Could any section be misread as contradicting .NET's known direction** (e.g. "V1 async" instrumentation reading as backtracking from the runtime-async/V2 focus), **or does it misattribute motivation** — presenting a model-forced/structural change as an optional convenience (e.g. Unsafe Evolution's `unsafe` fields framed as mere ergonomics when whole-type `unsafe` is going away)? Check the PR's *motivation*; state the real driver. (editorial-rules: *Frame against the likely misreading*, *Attribute the motivation correctly*)
17. **Are related sections clustered, not scattered?** Prefer recommending a **consistent-prefix renaming** (so alpha order keeps an area together) over mechanically flagging distance. Only raise scattering on docs with enough sections (roughly **6+**) that adjacency actually helps the reader — skip it on short component files. (editorial-rules: *Feature ordering*)

Ask reviewers to answer with file + heading + issue + suggested rewrite. This
produces actionable review instead of general taste feedback.

## Output

Return a concise review with:

1. **Most correct scoring** — the features that are best prioritized
2. **Most wrong scoring** — over-scored and under-scored items
3. **Important omissions** — items from `changes.json` / `features.json` that should likely be promoted
4. **Cut list** — what to group, compress, demote, or drop first

As a working rule of thumb:

- **8+** — section-worthy
- **6-7** — grouped paragraph or short section
- **0-5** — bug-fix bucket, one-liner, or cut
