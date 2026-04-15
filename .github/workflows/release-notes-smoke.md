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
  github:
    toolsets: [issues, pull_requests, repos, search]
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
    # ###############################################################
    # Override the COPILOT_GITHUB_TOKEN secret usage for the workflow
    # with a randomly-selected token from a pool of secrets.
    #
    # As soon as organization-level billing is offered for Agentic
    # Workflows, this stop-gap approach will be removed.
    #
    # See: /.github/actions/select-copilot-pat/README.md
    # ###############################################################
    - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
      name: Checkout the select-copilot-pat action folder
      with:
        persist-credentials: false
        sparse-checkout: .github/actions/select-copilot-pat
        sparse-checkout-cone-mode: true
        fetch-depth: 1

    - id: select-copilot-pat
      name: Select Copilot token from pool
      uses: ./.github/actions/select-copilot-pat
      env:
        SECRET_0: ${{ secrets.COPILOT_PAT_0 }}
        SECRET_1: ${{ secrets.COPILOT_PAT_1 }}
        SECRET_2: ${{ secrets.COPILOT_PAT_2 }}
        SECRET_3: ${{ secrets.COPILOT_PAT_3 }}
        SECRET_4: ${{ secrets.COPILOT_PAT_4 }}
        SECRET_5: ${{ secrets.COPILOT_PAT_5 }}
        SECRET_6: ${{ secrets.COPILOT_PAT_6 }}
        SECRET_7: ${{ secrets.COPILOT_PAT_7 }}
        SECRET_8: ${{ secrets.COPILOT_PAT_8 }}
        SECRET_9: ${{ secrets.COPILOT_PAT_9 }}

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

  pre-activation:
    outputs:
      copilot_pat_number: ${{ steps.select-copilot-pat.outputs.copilot_pat_number }}

engine:
  id: copilot
  env:
    COPILOT_GITHUB_TOKEN: ${{ case(needs.pre_activation.outputs.copilot_pat_number == '0', secrets.COPILOT_PAT_0, needs.pre_activation.outputs.copilot_pat_number == '1', secrets.COPILOT_PAT_1, needs.pre_activation.outputs.copilot_pat_number == '2', secrets.COPILOT_PAT_2, needs.pre_activation.outputs.copilot_pat_number == '3', secrets.COPILOT_PAT_3, needs.pre_activation.outputs.copilot_pat_number == '4', secrets.COPILOT_PAT_4, needs.pre_activation.outputs.copilot_pat_number == '5', secrets.COPILOT_PAT_5, needs.pre_activation.outputs.copilot_pat_number == '6', secrets.COPILOT_PAT_6, needs.pre_activation.outputs.copilot_pat_number == '7', secrets.COPILOT_PAT_7, needs.pre_activation.outputs.copilot_pat_number == '8', secrets.COPILOT_PAT_8, needs.pre_activation.outputs.copilot_pat_number == '9', secrets.COPILOT_PAT_9, secrets.COPILOT_GITHUB_TOKEN) }}
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
- Use GitHub tools for GitHub data. Do not fetch GitHub web pages or raw API URLs.
- Do not create branches, commits, pull requests, or comments.
- Do not modify files in this repository. If you need scratch space, use `/tmp/release-notes-smoke/` only.

## Tool setup

The workflow downloads `release-notes-gen` and places it on `PATH` before the agent
starts. If your selected phase needs it, use it directly from `PATH`. Do **not**
download it again, do **not** install it inline, and do **not** improvise another
setup path. If the command is missing, stop and report the failure.

## Phases

1. `boot` — read-only sanity check. Report the repository name, current branch, and HEAD SHA.
2. `tool` — prove `command -v release-notes-gen` resolves the tool on `PATH`. Do not invoke the binary by absolute path.
3. `github-read` — using GitHub tools only, list the latest three `Write Release Notes` workflow runs in this repo and summarize their status. Do not use shell `gh` and do not fetch web content.
4. `file-write` — create `/tmp/release-notes-smoke/`, copy `README.md` to `/tmp/release-notes-smoke/README.md`, and list the directory contents.
5. `changes` — clone `https://github.com/dotnet/dotnet` to `/tmp/dotnet-smoke` and show the first few lines of `main:eng/Versions.props`. Do not generate release notes or write repo files.

Return a short result for the selected phase only.
