---
if: (!github.event.repository.fork) || github.event_name == 'workflow_dispatch'

permissions:
  actions: read
  contents: read
  pull-requests: read
  issues: read

runtimes:
  dotnet:
    version: "11.0"
network:
  allowed:
    - defaults
    - dotnet
tools:
  bash:
    - dotnet
    - gh
    - release-notes
    - release-notes-gen
    - git
    - jq
    - mkdir
    - cp
    - rm
    - chmod
    - cat
    - ls
    - pwd
    - echo
    - grep
timeout-minutes: 30

on:
  permissions: {}
  workflow_dispatch:
    inputs:
      phase:
        description: "Smoke-test phase to run"
        required: true
        default: boot
        type: choice
        options:
          - boot
          - tool
          - github-read
          - file-write
          - changes

steps:
  - name: Download release-notes-gen tool
    uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
    with:
      name: release-notes-gen-tool
      path: /tmp/release-notes-gen-tool

  - name: Prepare release-notes-gen
    run: |
      chmod +x /tmp/release-notes-gen-tool/release-notes-gen
      echo /tmp/release-notes-gen-tool >> "$GITHUB_PATH"

  - name: Verify release-notes-gen is available
    run: |
      command -v release-notes-gen >/dev/null

  - name: Clone dotnet VMR
    run: |
      git clone --filter=blob:none https://github.com/dotnet/dotnet /tmp/dotnet

  - name: Verify dotnet VMR clone
    run: |
      git -C /tmp/dotnet rev-parse --verify HEAD >/dev/null

  - name: Preload smoke workflow context
    env:
      GH_TOKEN: ${{ github.token }}
    run: |
      mkdir -p /tmp/gh-aw/agent
      gh run list \
        --repo "$GITHUB_REPOSITORY" \
        --workflow "Write Release Notes" \
        --limit 3 \
        --json databaseId,displayTitle,event,headBranch,status,conclusion,createdAt,url \
        > /tmp/gh-aw/agent/write-release-notes-runs.json

jobs:
  install-tool:
    runs-on: ubuntu-latest
    permissions:
      packages: read
    steps:
      - name: Setup .NET for tool install
        uses: actions/setup-dotnet@c2fa09f4bde5ebb9d1777cf28262a3eb3db3ced7 # v5.2.0
        with:
          dotnet-version: '11.0'

      - name: Install release-notes-gen tool
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          dotnet nuget add source https://nuget.pkg.github.com/richlander/index.json \
            --name github-richlander \
            --username github-actions \
            --password "$GITHUB_TOKEN" \
            --store-password-in-clear-text
          dotnet tool install ReleaseNotes.Gen \
            --tool-path "$RUNNER_TEMP/release-notes-gen-tool"

      - name: Upload release-notes-gen tool
        uses: actions/upload-artifact@bbbca2ddaa5d8feaa63e36b76fdaad77386f024f # v7
        with:
          name: release-notes-gen-tool
          path: ${{ runner.temp }}/release-notes-gen-tool

# ###############################################################
# Override COPILOT_GITHUB_TOKEN with a random PAT from the pool.
# This stop-gap will be removed when org billing is available.
# See: .github/workflows/shared/pat_pool.README.md for more info.
# ###############################################################
imports:
  - shared/pat_pool.md

engine:
  id: copilot
  version: "1.0.60"
  env:
    COPILOT_GITHUB_TOKEN: ${{ case(needs.pat_pool.outputs.pat_number == '0', secrets.COPILOT_PAT_0, needs.pat_pool.outputs.pat_number == '1', secrets.COPILOT_PAT_1, needs.pat_pool.outputs.pat_number == '2', secrets.COPILOT_PAT_2, needs.pat_pool.outputs.pat_number == '3', secrets.COPILOT_PAT_3, needs.pat_pool.outputs.pat_number == '4', secrets.COPILOT_PAT_4, needs.pat_pool.outputs.pat_number == '5', secrets.COPILOT_PAT_5, needs.pat_pool.outputs.pat_number == '6', secrets.COPILOT_PAT_6, needs.pat_pool.outputs.pat_number == '7', secrets.COPILOT_PAT_7, needs.pat_pool.outputs.pat_number == '8', secrets.COPILOT_PAT_8, needs.pat_pool.outputs.pat_number == '9', secrets.COPILOT_PAT_9, secrets.COPILOT_GITHUB_TOKEN) }}
---

# Write Release Notes Smoke Test

This workflow is a bisect harness for the release-notes agent. Run **exactly one**
phase and then stop. The selected phase for this run is: `${{ inputs.phase }}`.

## Guardrails

- Perform only the selected phase.
- Never inspect, print, loop over, or probe token environment variables.
- Never try alternate credential names or fallback token discovery.
- Never use Python.
- Never use shell job-control built-ins such as `jobs`, `wait`, or backgrounding tricks.
- Prefer one simple shell command per tool call. Avoid `&&`, shell loops, and `2>&1`
  unless they are absolutely required.
- Use the preloaded local context files for external data. Do not fetch GitHub web pages or raw API URLs.
- Do not create branches, commits, pull requests, or comments.
- Do not modify files in this repository. If you need scratch space, use `/tmp/release-notes-smoke/` only.

## Tool setup

The workflow downloads `release-notes-gen`, places it on `PATH`, clones the VMR to
`/tmp/dotnet`, and writes the latest three `Write Release Notes` workflow runs to
`/tmp/gh-aw/agent/write-release-notes-runs.json` before the agent starts. Use those
preloaded resources directly. Do **not** download them again, do **not** clone the
VMR yourself, and do **not** improvise another setup path.

## Phases

1. `boot` — read-only sanity check. Report the repository name, current branch, and HEAD SHA.
2. `tool` — prove `command -v release-notes-gen` resolves the tool on `PATH`. Do not invoke the binary by absolute path.
3. `github-read` — read `/tmp/gh-aw/agent/write-release-notes-runs.json` and summarize the latest three `Write Release Notes` workflow runs. Do not use shell `gh`, `curl`, web content, or Python.
4. `file-write` — create `/tmp/release-notes-smoke/`, copy `README.md` to `/tmp/release-notes-smoke/README.md`, and list the directory contents.
5. `changes` — show the first few lines of `main:eng/Versions.props` from the pre-cloned `/tmp/dotnet`. Do not generate release notes or write repo files.

Return a short result for the selected phase only.
