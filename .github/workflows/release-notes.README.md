# Write Release Notes — Production Readiness

Operational and editorial contract for the `Write Release Notes` agentic workflow
([`release-notes.md`](release-notes.md)). This is the **definition of done**: it
states what the workflow produces, where every file belongs, and the invariants
the publish step enforces. The companion editorial guidance lives in the
[`release-notes` skill](../skills/release-notes/SKILL.md); this document is the
operational contract for the workflow that drives it.

## What the workflow is

A [GitHub Agentic Workflow](https://github.com/githubnext/gh-aw) (`gh-aw`) that
runs on a daily schedule, diffs the .NET VMR for each active milestone, and drafts
release notes as a set of pull requests — one per component team plus a shared
"features" PR that carries the machine-readable data. It is recompiled from
[`release-notes.md`](release-notes.md) into
[`release-notes.lock.yml`](release-notes.lock.yml) with `gh aw compile`.

> The firewall image version is baked into the `.lock.yml` **at compile time** and
> cannot be overridden from frontmatter. Fixing firewall/runner issues means
> upgrading the `gh aw` CLI and recompiling — see [Operations](#operations).

## Definition of good

| Goal | What it means |
| --- | --- |
| **green** | Scheduled runs succeed reliably. Failures are infrastructure-free; the agent always reaches execution. |
| **quality_pr** | The PR a human editor accepts with light edits — no restructuring required. |
| **no_hallucination** | Zero non-shipping features. Every note traces to a change in `changes.json`. |
| **incremental** | Reruns respect human edits and PR feedback instead of clobbering them (see [`update-existing-branch`](../skills/update-existing-branch/SKILL.md)). |
| **observability** | Failures are easy to diagnose via the smoke harness and run summaries. |
| **correct placement** | Every generated file lands on the right branch in the right path (see below). This is enforced, not just documented. |

## File layout and branch model

Each milestone produces **one features branch** and **one component branch per
component that has noteworthy changes**. The agent resolves the per-milestone
directory (`content_dir`, e.g. `release-notes/11.0/preview/preview5`) from the
target metadata and writes files **flat** inside it.

### Features branch — `release-notes/dotnet-<major>-<milestone>-features`

The "primary PR." Carries the shared, machine-readable milestone data and the
human-facing index. **Never carries a component `.md` file.**

| File | Owner | Purpose |
| --- | --- | --- |
| `changes.json` | agent | Authoritative shipped-change manifest (VMR diff). |
| `features.json` | agent | Scored/triaged derivative of `changes.json`. |
| `build-metadata.json` | agent | Build refs + NuGet source/packages used for API verification. |
| `README.md` | agent | Milestone index linking to each component file. |
| `blog.md` | agent | Aggregated highlights post (see [README and blog](#readme-and-blog)). |
| `.hints/` | human + agent | Editorial scaffolding (see [Hints](#hints)). Not customer content. |

### Component branch — `<features-branch>-<component-id>`

Example: `release-notes/dotnet-11-preview-5-features-runtime`. Contains **only that
component's `<id>.md`** inside `content_dir` (e.g. `runtime.md`) — nothing else. No
`changes.json`, no `features.json`, no other component's `.md`, no `.hints/`.
Components with no noteworthy changes get **no branch and no stub**.

### Out of agent scope (humans / release tooling)

`release.json`, the `11.0.0-preview.N.md` download page, `api-diff/`, and `media/`
are produced by release tooling or humans and must not be written by the agent.

## Placement invariants

The publish step ([`release-notes-publish-prep.sh`](../scripts/release-notes-publish-prep.sh))
enforces these before any branch is pushed. A branch that violates an invariant is
**rejected** (its PR is not opened/updated) and the violation is reported in the run
summary; other branches in the same run still publish.

1. A **component branch** `<features>-<id>` may only add/modify `<content_dir>/<id>.md`
   (plus an optional `README.md`). Stray sibling component files, `.hints/`, and
   metadata are rejected.
2. The **features branch** must not add/modify any component `.md` file.
3. Component filenames must be a known **`components.json` id** (`runtime.md`,
   `libraries.md`, `maui.md`, …). Unknown stems (e.g. a misnamed `dotnetmaui.md`)
   are rejected.

> These invariants close a gap that previously required repeated manual fixups
> ("Prune sibling markdown from component branches", "Keep hints on features
> branch only"). The component id is the single source of truth — see
> [Component naming](#component-naming).

## Component naming

[`release-notes/components.json`](../../release-notes/components.json) is the source
of truth. Each component's `id` is the markdown file stem the agent must emit and
the suffix of its branch name:

```text
runtime, libraries, sdk, csharp, fsharp, aspnetcore, efcore, maui, winforms, wpf, general
```

Enumerate with `jq -r '.components[].id' release-notes/components.json`. Repo
ownership in that file defines routing boundaries (e.g. `dotnet/roslyn` → `csharp`,
never `sdk`). Historical milestones contain pre-convention filenames (for example
`dotnetmaui.md`); new runs must use the canonical id.

## Hints

Hints are **agent scaffolding, not customer-facing content** — facts, scoring
overrides, and editorial steers that keep reruns on track. They are dot-prefixed
(`.hints/`) so reviewers of the primary PR don't treat them as copy to review, and
they are excluded from markdownlint/prettier.

**Locations** (both are read when processing a milestone):

- Per-phase — `release-notes/<major>/preview/.hints/` — durable across previews.
- Per-milestone — `release-notes/<major>/preview/<milestone>/.hints/` — one preview.

**File header** (required) — each hint `.md` begins with:

```yaml
---
applies-to: <milestone-id|all>
type: fact|scoring|editorial
---
```

**Precedence** — milestone-level hints win over phase-level on conflict. A phase
hint applies when its `applies-to` matches the current milestone or is `all`.

**Lifecycle** — hints are committed on the **features branch** in the primary PR so
a human can retain or delete them at merge. They are **never** copied to component
branches.

## README and blog

The agent owns both human-facing aggregations on the features branch:

- **`README.md`** — the milestone index/TOC linking to each component file.
- **`blog.md`** — an aggregated highlights post modeled on the
  `announcement.md` precedent: curated top stories with deep links into the
  component `.md` heading anchors. Anchors are generated deterministically (a
  slug/TOC tool), never hand-typed.

## Operations

- **Firewall / runner fixes require a recompile.** The `awf-squid` firewall image
  and runner labels are pinned in the `.lock.yml` at compile time. To pick up an
  upstream fix: `gh extension upgrade gh-aw`, then `gh aw compile`, then verify with
  the smoke harness. Do not hand-edit `.lock.yml`.
- **Copilot auth uses the PAT pool** — a stop-gap of numbered `COPILOT_PAT_<0-9>`
  secrets with weekly renewal. See [`shared/pat_pool.README.md`](shared/pat_pool.README.md).
- **Smoke harness** — [`release-notes-smoke.md`](release-notes-smoke.md) runs
  `workflow_dispatch` phases (`boot`, `tool`, `github-read`, `file-write`,
  `changes`) inside the firewall. Any green phase proves the firewall starts and
  the agent reaches execution — use it to validate a recompile before relying on
  the scheduled run.
- **Lint fixups** — [`fix-release-notes-lint.md`](fix-release-notes-lint.md) shares
  the publish-prep normalizer to repair markdownlint issues on draft branches.

## Generated files (do not edit)

`*.lock.yml` and `agentics-maintenance.yml` are generated by `gh aw compile` and
are excluded from super-linter. Edit the `.md` source and recompile instead.
