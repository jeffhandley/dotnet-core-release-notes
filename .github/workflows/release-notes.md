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

# Add the pre-activation output of the randomly selected PAT
jobs:
  pre-activation:
    outputs:
      copilot_pat_number: ${{ steps.select-copilot-pat.outputs.copilot_pat_number }}

# Override the COPILOT_GITHUB_TOKEN expression used in the activation job
# Consume the PAT number from the pre-activation step and select the corresponding secret
engine:
  id: copilot
  env:
    # We cannot use line breaks in this expression as it leads to a syntax error in the compiled workflow
    # If none of the `COPILOT_PAT_#` secrets were selected, then the default COPILOT_GITHUB_TOKEN is used
    COPILOT_GITHUB_TOKEN: ${{ case(needs.pre_activation.outputs.copilot_pat_number == '0', secrets.COPILOT_PAT_0, needs.pre_activation.outputs.copilot_pat_number == '1', secrets.COPILOT_PAT_1, needs.pre_activation.outputs.copilot_pat_number == '2', secrets.COPILOT_PAT_2, needs.pre_activation.outputs.copilot_pat_number == '3', secrets.COPILOT_PAT_3, needs.pre_activation.outputs.copilot_pat_number == '4', secrets.COPILOT_PAT_4, needs.pre_activation.outputs.copilot_pat_number == '5', secrets.COPILOT_PAT_5, needs.pre_activation.outputs.copilot_pat_number == '6', secrets.COPILOT_PAT_6, needs.pre_activation.outputs.copilot_pat_number == '7', secrets.COPILOT_PAT_7, needs.pre_activation.outputs.copilot_pat_number == '8', secrets.COPILOT_PAT_8, needs.pre_activation.outputs.copilot_pat_number == '9', secrets.COPILOT_PAT_9, secrets.COPILOT_GITHUB_TOKEN) }}
---

# Write Release Notes - Bisect Checkpoint 1

This workflow is temporarily reduced to a skeleton for functional bisecting.

Do not generate release notes, modify repository files, create pull requests, or add comments.

Your only task is to confirm that the workflow reached the agent successfully after the pre-activation steps completed.

Call the `noop` tool exactly once with this message:

`Checkpoint 1 reached successfully: pre-activation + agent skeleton only.`

Do not call any other tools.
