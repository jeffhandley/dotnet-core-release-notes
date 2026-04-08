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
safe-outputs:
  create-pull-request:
    title-prefix: "[release-notes] "
    labels: [area-release-notes, automation]
    draft: true
    max: 5
  push-to-pull-request-branch:
    title-prefix: "[release-notes] "
    labels: [area-release-notes, automation]
    max: 5
  add-comment:
    max: 20
    target: "*"
tools:
  github:
    toolsets: [issues, pull_requests, repos, search]
  bash:
    - dnx
    - dotnet
    - gh
    - release-notes
    - release-notes-gen
    - git
    - jq
timeout-minutes: 120

on:
  schedule: daily around 9am PDT
  workflow_dispatch:
    inputs:
      milestone:
        description: "Optional milestone override. Use the directory name, for example preview4, rc1, or ga. Leave empty to auto-detect."
        required: false
        type: string

---

# Write Release Notes - Bisect Checkpoint 2

This workflow is temporarily reduced to a skeleton for functional bisecting.

This checkpoint removes the PAT-pool override and relies only on the default
Copilot workflow authentication path.

Do not generate release notes, modify repository files, create pull requests, or add comments.

Your only task is to confirm that the workflow reached the agent successfully.

Call the `noop` tool exactly once with this message:

`Checkpoint 2 reached successfully: default Copilot auth without PAT override.`

Do not call any other tools.
