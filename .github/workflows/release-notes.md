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
  bash:
    - dnx
    - dotnet
    - gh
    - release-notes
    - release-notes-gen
    - git
    - jq
    - mkdir
    - cp
    - mv
    - rm
    - chmod
    - cat
    - ls
    - pwd
    - echo
    - grep
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

steps:
  - name: Preload release-notes context
    uses: ./.github/actions/release-notes-preload
    with:
      milestone: ${{ github.event.inputs.milestone }}
      github-token: ${{ github.token }}

post-steps:
  - name: Translate publish manifests to safe outputs
    env:
      GH_AW_SAFE_OUTPUTS: ${{ steps.set-runtime-paths.outputs.GH_AW_SAFE_OUTPUTS }}
    run: |
      set -euo pipefail
      manifest_dir=/tmp/gh-aw/agent/publish
      prs_json=/tmp/gh-aw/agent/release-notes-prs.json
      output_file="${GH_AW_SAFE_OUTPUTS}"
      agent_output_file=/tmp/gh-aw/agent_output.json

      mkdir -p /tmp/gh-aw
      : > "$output_file"

      # Reset agent_output.json to a known-empty shape. The gh-aw "Ingest agent
      # output" step ran BEFORE this post-step and wrote {"items":[]} (because
      # the agent uses publish-manifest indirection rather than calling
      # safeoutputs MCP tools directly). We rebuild it here from the manifests.
      echo '{"items":[]}' > "$agent_output_file"

      if [ ! -d "$manifest_dir" ]; then
        echo "No publish manifests were written"
        exit 0
      fi

      shopt -s nullglob
      manifests=("$manifest_dir"/*.json)
      if [ ${#manifests[@]} -eq 0 ]; then
        echo "No publish manifests were written"
        exit 0
      fi

      # append_item <json-object>
      # Appends a JSON object to both the JSONL safe-outputs file (for audit
      # parity with the in-band path) and to agent_output.json's .items array
      # (which is what the downstream safe_outputs job actually consumes via
      # the uploaded artifact).
      append_item() {
        local item_json="$1"
        printf '%s\n' "$item_json" >> "$output_file"
        local tmp
        tmp=$(mktemp)
        jq --argjson item "$item_json" '.items += [$item]' "$agent_output_file" > "$tmp"
        mv "$tmp" "$agent_output_file"
      }

      for manifest in "${manifests[@]}"; do
        branch=$(jq -r '.branch // empty' "$manifest")
        title=$(jq -r '.title // empty' "$manifest")
        body=$(jq -r '.body // empty' "$manifest")
        comment=$(jq -r '.comment // empty' "$manifest")

        if [ -z "$branch" ]; then
          echo "Publish manifest is missing branch: $manifest" >&2
          exit 1
        fi

        # Determine source of the branch content. Three cases:
        #   1. local branch exists      -> bundle from local, push to origin
        #   2. only origin/<branch>     -> branch is already on origin, no
        #                                  push needed; just open PR if missing
        #   3. neither exists           -> hard error
        bundle_path=""
        remote_only="false"
        if git show-ref --verify --quiet "refs/heads/$branch"; then
          safe_branch=$(printf '%s' "$branch" | tr '/[:space:]' '__')
          bundle_path="/tmp/gh-aw/aw-${safe_branch}.bundle"
          rm -f "$bundle_path"
          git bundle create "$bundle_path" "refs/heads/$branch"
        elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
          echo "Branch $branch only exists on origin; will open PR without pushing"
          remote_only="true"
        else
          echo "Publish manifest references unknown branch (no local or remote): $branch" >&2
          exit 1
        fi

        open_pr=$(jq -c --arg branch "$branch" '[.[] | select(.headRefName == $branch and .state == "OPEN")] | first' "$prs_json")
        non_open_pr=$(jq -c --arg branch "$branch" '[.[] | select(.headRefName == $branch and .state != "OPEN")] | first' "$prs_json")

        if [ "$open_pr" != "null" ]; then
          pr_number=$(jq -r '.number' <<<"$open_pr")
          ahead_count=$(git rev-list --count "origin/$branch..$branch" 2>/dev/null || echo 0)

          if [ "$ahead_count" -gt 0 ]; then
            push_item=$(jq -cn \
              --arg branch "$branch" \
              --arg bundle_path "$bundle_path" \
              --arg message "${comment:-Updated release notes content.}" \
              --argjson pull_request_number "$pr_number" \
              '{
                type: "push_to_pull_request_branch",
                branch: $branch,
                bundle_path: $bundle_path,
                message: $message,
                pull_request_number: $pull_request_number
              }')
            append_item "$push_item"
          fi

          if [ -n "$comment" ]; then
            comment_item=$(jq -cn \
              --arg body "$comment" \
              --argjson item_number "$pr_number" \
              '{
                type: "add_comment",
                body: $body,
                item_number: $item_number
              }')
            append_item "$comment_item"
          fi

          continue
        fi

        if [ "$non_open_pr" != "null" ]; then
          state=$(jq -r '.state' <<<"$non_open_pr")
          echo "Refusing to create a replacement PR for $branch because a non-open PR already exists ($state)" >&2
          exit 1
        fi

        if [ -z "$title" ] || [ -z "$body" ]; then
          echo "New PR manifest must include title and body: $manifest" >&2
          exit 1
        fi

        create_item=$(jq -cn \
          --arg branch "$branch" \
          --arg bundle_path "$bundle_path" \
          --arg title "$title" \
          --arg body "$body" \
          --argjson remote_only "$remote_only" \
          '{
            type: "create_pull_request",
            branch: $branch,
            bundle_path: $bundle_path,
            title: $title,
            body: $body,
            remote_only: $remote_only
          }')
        append_item "$create_item"
      done
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

  publish_release_notes:
    name: Publish release-notes branches
    needs: [agent]
    if: always() && needs.agent.result == 'success'
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: read
    steps:
      - name: Checkout repository
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
        with:
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}
          persist-credentials: true

      - name: Download agent artifact
        uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          name: agent
          path: /tmp/gh-aw/

      - name: Configure git identity
        run: |
          git config --global user.email "github-actions[bot]@users.noreply.github.com"
          git config --global user.name "github-actions[bot]"

      - name: Publish PRs from agent output
        env:
          # Requires repo Settings → Actions → General →
          # "Allow GitHub Actions to create and approve pull requests" to be on.
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          set -euo pipefail
          agent_output=/tmp/gh-aw/agent_output.json
          if [ ! -f "$agent_output" ]; then
            echo "::notice::No agent_output.json produced by the agent — nothing to publish"
            exit 0
          fi
          items_count=$(jq '.items | length' "$agent_output")
          if [ "$items_count" -eq 0 ]; then
            echo "::notice::agent_output.json contained 0 items — nothing to publish"
            exit 0
          fi
          echo "Publishing $items_count item(s) from agent_output.json"

          # Bundles produced by the agent post-step are uploaded with absolute
          # paths under /tmp/gh-aw/. The download artifact extracts them to
          # /tmp/gh-aw/<basename>, so resolve by basename.
          resolve_bundle() {
            local bundle_path="$1"
            local local_path="/tmp/gh-aw/$(basename "$bundle_path")"
            if [ ! -f "$local_path" ]; then
              echo "::error::Bundle file not found in artifact: $local_path (manifest path was $bundle_path)" >&2
              return 1
            fi
            printf '%s' "$local_path"
          }

          # The job is intentionally branches-only. We don't call `gh pr
          # create` because that would require enabling the repo-level
          # "Allow GitHub Actions to create and approve pull requests"
          # setting, which also grants approval power. Instead, push the
          # branch and surface a one-click "compare" URL that a human can
          # use to open the PR.
          repo_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}"

          # Emit a Markdown summary header for branch links.
          summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
          {
            echo "## Release notes branches published"
            echo ""
            echo "Open a PR for any of these from the link below:"
            echo ""
          } >> "$summary"

          # Track whether any branch was rejected by the markdownlint gate
          # so we can fail the run after processing all items.
          lint_failed=0

          # Regenerate the auto-TOC in every changed .md that contains the
          # `<!-- toc -->` / `<!-- tocstop -->` markers, then amend the tip
          # commit if anything actually changed. Hand-written TOC entries
          # between the markers are the #1 source of MD051 anchor-fragment
          # failures (the agent slugifies headings by hand and gets it
          # wrong, e.g. `mediatypesnames` instead of `mediatypenames`).
          # Running markdown-toc here makes the TOC content authoritative
          # regardless of what the agent wrote between the markers.
          # Assumes the working tree is checked out on $branch (rebase did this).
          regenerate_tocs() {
            local branch="$1"
            local touched=0
            local md_files
            md_files=$(git diff --name-only "origin/main...$branch" -- '*.md' 2>/dev/null || true)
            [ -z "$md_files" ] && return 0
            while IFS= read -r md_path; do
              [ -z "$md_path" ] && continue
              [ -f "$md_path" ] || continue
              grep -q '<!-- toc -->' "$md_path" || continue
              grep -q '<!-- tocstop -->' "$md_path" || continue
              npx --yes markdown-toc -i "$md_path" --maxdepth 2 >/dev/null 2>&1 || true
              if ! git diff --quiet -- "$md_path"; then
                touched=1
                git add "$md_path"
              fi
            done <<< "$md_files"
            if [ "$touched" -eq 1 ]; then
              git -c user.email="${GIT_AUTHOR_EMAIL:-actions@github.com}" \
                  -c user.name="${GIT_AUTHOR_NAME:-github-actions[bot]}" \
                  commit --amend --no-edit >/dev/null
              echo "  TOC regenerated for $branch"
            fi
          }

          for i in $(seq 0 $((items_count - 1))); do
            item=$(jq -c ".items[$i]" "$agent_output")
            type=$(jq -r '.type' <<<"$item")
            case "$type" in
              create_pull_request)
                branch=$(jq -r '.branch' <<<"$item")
                title=$(jq -r '.title' <<<"$item")
                bundle=$(jq -r '.bundle_path // empty' <<<"$item")
                remote_only=$(jq -r '.remote_only // false' <<<"$item")
                echo "→ create_pull_request branch=$branch remote_only=$remote_only"

                if [ "$remote_only" = "true" ]; then
                  echo "  branch already on origin — skipping push"
                else
                  bundle_local=$(resolve_bundle "$bundle")
                  git fetch "$bundle_local" "+refs/heads/$branch:refs/heads/$branch"

                  # Rebase the agent's commits onto the CURRENT origin/main so
                  # the branch tree's `.github/workflows/` matches main. The
                  # workflow token lacks the `workflows: write` scope; GitHub
                  # rejects any push from a GitHub App where the branch's
                  # workflow tree differs from the default branch, even when
                  # the new commits don't touch workflow files. This happens
                  # whenever main moves forward (e.g., workflow edits land)
                  # while the agent is running — the agent's worktree was
                  # forked from an older main snapshot.
                  if ! git rebase origin/main "$branch"; then
                    git rebase --abort 2>/dev/null || true
                    echo "::error::Could not rebase $branch onto current origin/main"
                    echo "- ❌ \`$branch\` — push blocked: rebase conflict" >> "$summary"
                    lint_failed=1
                    continue
                  fi

                  # Rebase succeeded; regenerate auto-TOCs in changed files
                  # (replaces hand-written TOC entries between the markers).
                  regenerate_tocs "$branch"

                  # Hard gate: refuse to push markdown that fails markdownlint.
                  # Lint the files this branch added or modified vs origin/main.
                  # markdownlint validates the whole file, not just the diff,
                  # so this catches structural problems anywhere in any file
                  # the agent wrote on this branch. If the gate fails, only
                  # this branch is blocked — other branches in the run still
                  # publish if their own files lint clean.
                  md_files=$(git diff --name-only "origin/main...$branch" -- '*.md' 2>/dev/null || true)
                  if [ -n "$md_files" ]; then
                    lint_dir=$(mktemp -d)
                    while IFS= read -r md_path; do
                      [ -z "$md_path" ] && continue
                      mkdir -p "$lint_dir/$(dirname "$md_path")"
                      git show "$branch:$md_path" > "$lint_dir/$md_path"
                    done <<< "$md_files"
                    if ! npx --yes markdownlint-cli --config .github/linters/.markdown-lint.yml "$lint_dir" 2>&1 | tee -a "$summary"; then
                      echo "::error::Markdownlint violations on $branch — refusing to push. See log above."
                      echo "- ❌ \`$branch\` — push blocked: markdownlint violations" >> "$summary"
                      rm -rf "$lint_dir"
                      lint_failed=1
                      continue
                    fi
                    rm -rf "$lint_dir"
                  fi

                  git push origin "refs/heads/$branch:refs/heads/$branch" --force-with-lease
                fi

                # If an open PR already exists, link to it; otherwise emit a
                # compare URL so a human can open the PR with one click.
                existing=$(gh pr list --head "$branch" --state open --json number,url --jq '.[0]')
                if [ -n "$existing" ] && [ "$existing" != "null" ]; then
                  url=$(jq -r '.url' <<<"$existing")
                  num=$(jq -r '.number' <<<"$existing")
                  echo "::notice::Branch $branch updated; existing PR #$num: $url"
                  echo "- ✅ \`$branch\` — existing PR [#$num]($url) updated" >> "$summary"
                else
                  compare="${repo_url}/compare/main...$(printf '%s' "$branch" | sed 's,/,%2F,g')?expand=1"
                  echo "::notice::Branch $branch pushed. Open PR: $compare"
                  enc_title=$(printf '%s' "$title" | jq -sRr @uri)
                  compare_titled="${compare}&title=${enc_title}"
                  echo "- 🌱 \`$branch\` — [open a PR]($compare_titled)" >> "$summary"
                fi
                ;;
              push_to_pull_request_branch)
                branch=$(jq -r '.branch' <<<"$item")
                bundle=$(jq -r '.bundle_path' <<<"$item")
                bundle_local=$(resolve_bundle "$bundle")
                pr_number=$(jq -r '.pull_request_number' <<<"$item")
                echo "→ push_to_pull_request_branch branch=$branch pr=$pr_number"
                git fetch "$bundle_local" "+refs/heads/$branch:refs/heads/$branch"

                # Rebase onto current origin/main so the branch tree's
                # .github/workflows/ matches main (see longer comment above).
                if ! git rebase origin/main "$branch"; then
                  git rebase --abort 2>/dev/null || true
                  echo "::error::Could not rebase $branch onto current origin/main"
                  echo "- ❌ \`$branch\` — push blocked: rebase conflict" >> "$summary"
                  lint_failed=1
                  continue
                fi

                # Rebase succeeded; regenerate auto-TOCs in changed files.
                regenerate_tocs "$branch"

                # Hard gate: refuse to push markdown that fails markdownlint.
                # Lint the files this branch added or modified vs origin/main.
                md_files=$(git diff --name-only "origin/main...$branch" -- '*.md' 2>/dev/null || true)
                if [ -n "$md_files" ]; then
                  lint_dir=$(mktemp -d)
                  while IFS= read -r md_path; do
                    [ -z "$md_path" ] && continue
                    mkdir -p "$lint_dir/$(dirname "$md_path")"
                    git show "$branch:$md_path" > "$lint_dir/$md_path"
                  done <<< "$md_files"
                  if ! npx --yes markdownlint-cli --config .github/linters/.markdown-lint.yml "$lint_dir" 2>&1 | tee -a "$summary"; then
                    echo "::error::Markdownlint violations on $branch — refusing to push. See log above."
                    echo "- ❌ \`$branch\` — push blocked: markdownlint violations" >> "$summary"
                    rm -rf "$lint_dir"
                    lint_failed=1
                    continue
                  fi
                  rm -rf "$lint_dir"
                fi

                git push origin "refs/heads/$branch:refs/heads/$branch" --force-with-lease
                pr_url="${repo_url}/pull/${pr_number}"
                echo "- 🔁 \`$branch\` — pushed update to PR [#$pr_number]($pr_url)" >> "$summary"
                ;;
              add_comment)
                # Comments are skipped in the branches-only design — the
                # human will see content via the PR they create.
                num=$(jq -r '.item_number' <<<"$item")
                echo "→ add_comment item=$num (skipped — branches-only mode)"
                ;;
              *)
                echo "::warning::Unknown agent_output item type: $type"
                ;;
            esac
          done

          if [ "$lint_failed" -ne 0 ]; then
            echo "::error::One or more branches were blocked by the markdownlint gate. Re-run after fixing markdown."
            exit 1
          fi

  pre-activation:
    outputs:
      copilot_pat_number: ${{ steps.select-copilot-pat.outputs.copilot_pat_number }}
engine:
  id: copilot
  version: "1.0.43"
  env:
    # We cannot use line breaks in this expression as it leads to a syntax error in the compiled workflow
    # If none of the `COPILOT_PAT_#` secrets were selected, then the default COPILOT_GITHUB_TOKEN is used
    COPILOT_GITHUB_TOKEN: ${{ case(needs.pre_activation.outputs.copilot_pat_number == '0', secrets.COPILOT_PAT_0, needs.pre_activation.outputs.copilot_pat_number == '1', secrets.COPILOT_PAT_1, needs.pre_activation.outputs.copilot_pat_number == '2', secrets.COPILOT_PAT_2, needs.pre_activation.outputs.copilot_pat_number == '3', secrets.COPILOT_PAT_3, needs.pre_activation.outputs.copilot_pat_number == '4', secrets.COPILOT_PAT_4, needs.pre_activation.outputs.copilot_pat_number == '5', secrets.COPILOT_PAT_5, needs.pre_activation.outputs.copilot_pat_number == '6', secrets.COPILOT_PAT_6, needs.pre_activation.outputs.copilot_pat_number == '7', secrets.COPILOT_PAT_7, needs.pre_activation.outputs.copilot_pat_number == '8', secrets.COPILOT_PAT_8, needs.pre_activation.outputs.copilot_pat_number == '9', secrets.COPILOT_PAT_9, secrets.COPILOT_GITHUB_TOKEN) }}
    # GITHUB_TOKEN is the workflow's run-scoped token (read-only per the `permissions:` block above). `release-notes-gen generate changes` requires it to query PR metadata against dotnet/dotnet.
    GITHUB_TOKEN: ${{ github.token }}
---

<!-- markdownlint-disable-next-line MD025 -->
# Write Release Notes

You maintain release notes for .NET preview, RC, and GA releases in this repository (dotnet/core), running on a schedule to frequently identify changes in the upcoming releases. This is a **multi-master live system** — humans edit branches and leave PR comments at any time. You must respect their changes and engage with their feedback.

Your outputs are pull requests — one per active milestone — each containing:

1. **`changes.json`** — a comprehensive manifest of all PRs/commits that shipped, generated by `release-notes generate changes`
2. **`features.json`** — a scored derivative of `changes.json` used to rank what is worth documenting
3. **Markdown release notes** — curated editorial content covering high-value features

## Your principles

- **High fidelity** — only document what actually ships. The VMR (`dotnet/dotnet`) and its `src/source-manifest.json` are the source of truth. Trust `release-notes generate changes` output.
- **High value** — bias toward features users care about. Skip infra, test-only, and internal refactoring.
- **Never document non-shipping features** — if it's not in `changes.json`, it didn't ship.
- **Use scoring as guidance, not law** — `features.json` helps prioritize, but humans and editorial judgment still decide what makes the cut.
- **Reader value first** — use the score from the reader's point of view: 10 = "first thing I'll try", 8 = "I'll use this on upgrade", 6 = "glad to know", 4 = "maybe later", 2 = "mystery", 0 = "internal gobbledygook".
- **Prefer the 80%** — default to features that make sense to most users. Keep 20%-audience features only when the other 80% can still appreciate why they matter.
- **Respect human edits** — this is a shared workspace. Humans edit branch content directly. Diff before writing and preserve everything they've touched. When in doubt, ask via PR comment.
- **Engage with comments** — read PR comments and review threads. Some are actionable, some need discussion. Respond and iterate.
- **Incremental improvement** — early drafts are rough. Each nightly run improves them.

## Reference documents

Read these files and skills for detailed guidance:

- **editorial-scoring** — shared reader-centric scoring rubric and 80/20 audience filter ([skill](../skills/editorial-scoring/SKILL.md))
- **quality-bar.md** — what good release notes look like
- **vmr-structure.md** — how the VMR works, branch naming, source-manifest.json
- **changes-schema.md** — the shared `changes.json` / `features.json` schema
- **feature-scoring.md** — how to score and cut candidate features
- **component-mapping.md** — VMR paths → components → product slugs → output files
- **format-template.md** — markdown document structure
- **editorial-rules.md** — tone, attribution, naming conventions
- **examples/** — curated examples from previous releases, organized by component ([README](../skills/release-notes/references/examples/README.md) has principles)

## Model strategy

- Use **Claude Opus 4.6** as the default model throughout the workflow for orchestration, scoring, and drafting.
- For the **final `review-release-notes` pass**, prefer this **two-model reviewer set** to widen the editorial viewpoint:
  - **Claude Opus 4.6**
  - **GPT-5.4**
- Give both reviewers the same inputs and ask for the same output shape. Synthesize the overlap, inspect meaningful disagreements, and prefer the shared `editorial-scoring` rubric over any single model's preference.

## Tool setup

The workflow shell is allowlisted. Stick to the commands declared in the frontmatter
above plus the `write` tool. Prefer the local files and git state the workflow
prepared for you. Avoid Python or other ad hoc interpreters, env-var probing loops,
raw web/API fetches for GitHub data, shell job-control built-ins such as `jobs`
and `wait`, and unnecessary command chains or redirections.

In particular:

- do **not** use `python3 -c`, heredocs, or pipe JSON into an interpreter just to inspect it; use `jq` directly when you need JSON filtering
- do **not** inspect `/tmp/gh-aw`, `/tmp/gh-aw/mcp-config`, or other runner internals to discover tool names or configuration; rely on the runtime tool list and the documented tool names in this prompt
- do **not** `git checkout` files from `/tmp/dotnet` into the working tree just to read them; use `git show <ref>:<path>` instead
- do **not** scan the runner filesystem looking for preinstalled tools when the workflow already told you where the artifact is downloaded and what binary name to run
- do **not** use `curl` or raw GitHub REST endpoints for workflow runs, artifacts, PRs, comments, or repository contents; the workflow already preloaded the release-notes GitHub context you need
- do **not** inspect environment variables to hunt for tokens, credentials, or auth state; assume the deterministic preloaded files and `gh` shell are the supported interfaces in this workflow

For VMR content, use the **local git checkout** you cloned into `/tmp/dotnet` as the source of truth for repository files and ref comparisons:

- read `src/source-manifest.json` with `git -C /tmp/dotnet show <ref>:src/source-manifest.json`
- inspect files at a ref with `git -C /tmp/dotnet show <ref>:<path>`
- compare refs with local `git log`, `git diff`, `git rev-list`, and related git commands

When you need to inspect `source-manifest.json`, prefer `jq` over Python. For
example:

```bash
git -C /tmp/dotnet show main:src/source-manifest.json | \
  jq -r '.repositories[:30][] | [.path, (.remoteUri // ""), ((.commitSha // "")[0:12])] | @tsv'
```

Do **not** fetch repository file contents or compare views from `raw.githubusercontent.com`, GitHub compare pages, or other web URLs when the data already exists in the local clone. If a web fetch is blocked, switch to local git commands instead of retrying with another GitHub URL.

### Preloaded context in this workflow

The workflow downloads `release-notes-gen`, places it on `PATH`, and clones the
dotnet VMR to `/tmp/dotnet` before agentic execution starts. It also computes
the active milestone target deterministically and preloads release-notes
repository context into local files:

- `/tmp/gh-aw/agent/context-index.json`
- `/tmp/gh-aw/agent/target.json` — **the single source of truth for what this run targets** (see below)
- `/tmp/gh-aw/agent/components.json` — copy of `release-notes/components.json` for component routing
- `/tmp/gh-aw/agent/release-notes-prs.json`
- `/tmp/gh-aw/agent/release-notes-branches.txt`
- `/tmp/gh-aw/agent/pr-comments/<pr>-issue-comments.json`
- `/tmp/gh-aw/agent/pr-comments/<pr>-review-comments.json`
- `/tmp/gh-aw/agent/pr-comments/<pr>-reviews.json`
- `/tmp/gh-aw/agent/publish/` — write publish manifests here; the workflow converts them into safe outputs after you finish

- use `release-notes-gen` directly when you need it
- use the pre-cloned VMR at `/tmp/dotnet`
- read `/tmp/gh-aw/agent/context-index.json` first so you know where the preloaded
  release-notes PR, branch, and comment data lives
- use the preloaded release-notes PR/comment files instead of GitHub MCP reads for
  this repository
- use shell `gh` only for targeted cross-repo follow-up that the workflow could not
  preload, such as revert searches in component repos
- do **not** probe `PATH` with `command -v` or `which` from inside the agent
- do **not** run `gh run download` or `dotnet tool install` for `ReleaseNotes.Gen`
- do **not** run `git clone https://github.com/dotnet/dotnet /tmp/dotnet` yourself
- do **not** background clone work or use `jobs`, `wait`, `sleep`, or polling loops to watch clone progress
- do **not** call GitHub MCP tools or safe-output tools directly in this workflow;
  your job is to prepare local edits and publish manifests, not to fetch or publish
  through MCP

If `release-notes-gen`, `/tmp/dotnet`, or the preloaded context files are absent or
unusable, stop before making repo changes and explain the missing prerequisite in
your final response.

## What to do each run

### 1. Read the active target

The workflow computed the active milestone targets for you deterministically from `release-notes/releases-index.json` and wrote them to `/tmp/gh-aw/agent/target.json`. **Use this file verbatim. Do not discover milestones yourself.**

```bash
cat /tmp/gh-aw/agent/target.json
```

The structure is a JSON array of targets, typically a single entry:

```json
[
  {
    "major": "11.0",
    "major_flat": "11",
    "milestone": "preview3",
    "milestone_branch_label": "preview-3",
    "last_shipped": "11.0.0-preview.2",
    "support_phase": "preview",
    "branch_features": "release-notes/dotnet-11-preview-3-features",
    "content_dir": "release-notes/11.0/preview/preview3",
    "vmr_base_tag": "release/11.0.1xx-preview2",
    "vmr_head_ref": "main"
  }
]
```

Rules:

- If `target.json` is `[]`, exit cleanly with a final message that there is nothing to do this run — do not invent a target.
- For each entry, the **only** valid publish branch for that target is `branch_features`. Do not create or push to any other branch for that target.
- `vmr_base_tag` and `vmr_head_ref` are the refs to feed `release-notes generate changes`. Despite the field name, `vmr_base_tag` is normally a **branch ref** (e.g. `release/11.0.1xx-preview4`) — the release branch of the previously shipped milestone, used as the inclusive lower bound. Verify it exists with `git -C /tmp/dotnet rev-parse --verify "$vmr_base_tag" >/dev/null` (this resolves either a tag or a branch). If it does not resolve, fail loudly and report which nearby refs do exist (`git -C /tmp/dotnet for-each-ref --format='%(refname:short)' 'refs/heads/release/*' 'refs/tags/v*' | grep -F "<major>"`). Do not silently substitute another ref.
- Use `content_dir` for file paths inside this repository (this matches the existing per-milestone directory convention).
- Strict serial invariant: exactly one milestone is active per major version at any time. The workflow already enforced this; if it produced multiple entries for the same major, that is a workflow bug — abort.

### Legacy branches are read-only history

The preload step lists every branch matching `release-notes/*` in `/tmp/gh-aw/agent/release-notes-branches.txt`. Branches whose names do not match the `branch_features` of any current target — and are not a component branch (`<branch_features>-<component-id>`) of a current target — are **legacy history**:

- treat them as read-only context for understanding earlier editorial decisions
- do **not** push to them, do **not** reuse them, and do **not** create PRs against them
- if a legacy branch contains content that should carry forward, copy/adapt it into the current `branch_features` worktree rather than reviving the legacy branch

### 2. For each active target

Process targets in array order. Each target has its own family of long-lived branches and PRs for the lifetime of that release draft:

- **Features branch** — `target.branch_features` (e.g. `release-notes/dotnet-11-preview-5-features`). Holds the **shared data** for the milestone: `changes.json`, `features.json`, `README.md`, and any other non-component metadata (e.g. `build-metadata.json`, `release.json`) that lives in `content_dir`. **Never write per-component `.md` files to this branch.**
- **Component branches** — one branch per component that has noteworthy features in this milestone, named `<target.branch_features>-<component-id>` (e.g. `release-notes/dotnet-11-preview-5-features-runtime`, `…-aspnetcore`). Each component branch contains **only that component's `.md` file** inside `content_dir`. Components with no noteworthy features do **not** get a branch and do **not** get a stub `.md` — skip them entirely.

Component IDs come from `release-notes/components.json` (the `id` field of each component, which matches the markdown file stem, e.g. `runtime` → `runtime.md`). Use `jq -r '.components[].id' /tmp/gh-aw/agent/components.json` to enumerate them.

#### a. Regenerate changes.json

Always regenerate — VMR content may have changed since the previous run. Use the refs from `target.json`:

```bash
mkdir -p "$content_dir"
release-notes generate changes /tmp/dotnet \
  --base "$vmr_base_tag" \
  --head "$vmr_head_ref" \
  --version "<major>.0-<milestone>" \
  --labels \
  --output "$content_dir/changes.json"
```

For example, with the target shown above: `--base release/11.0.1xx-preview2 --head main --version "11.0.0-preview.3" --output release-notes/11.0/preview/preview3/changes.json`.

#### a2. Regenerate build-metadata.json

Always regenerate alongside `changes.json` so package versions stay in sync with the milestone:

```bash
release-notes generate build-metadata /tmp/dotnet \
  --base "$vmr_base_tag" \
  --head "$vmr_head_ref" \
  --output "$content_dir/build-metadata.json"
```

`build-metadata.json` belongs on the **features branch** alongside `changes.json` and `features.json`. The `nuget.source` and `nuget.packages` values are also what downstream API verification steps consume when checking shipped types — keep this file current.

#### b. Generate or refresh features.json

Before you assign scores, do a mechanical revert audit. The goal is to catch
features that landed and were later backed out, including reverts that live
outside the current milestone diff.

Start by scanning `changes.json` for explicit revert titles:

```bash
jq -r '.changes[] | select(.title | test("(?i)^(partial(ly)?\\s+)?revert\\b|\\bback out\\b")) | [.repo, .title, .url] | @tsv' \
  "$content_dir/changes.json"
```

Then, for each section-worthy candidate, search the source repo for later merged
PRs that say they revert or back out the original PR. Do this even if the later
PR is in Preview N+1 and therefore absent from the current `changes.json`:

```bash
gh search prs --repo dotnet/<repo> --state merged \
  "\"This reverts https://github.com/dotnet/<repo>/pull/<number>\" OR \"revert <number>\" OR \"back out <number>\"" \
  --json number,title,mergedAt,url
```

If a merged revert exists, record that evidence in `features.json` with optional
`reverted_by` / `reverts` fields and score the original item to `0` unless the
shipped build clearly still contains it.

Use `changes.json` as the source of truth and write a sibling `features.json` that preserves the same schema while adding optional scoring metadata:

- keep the same `id` and `commits{}` values
- assign higher scores to externally meaningful, user-visible changes
- down-rank infra, churn, test-only work, and anything that appears reverted
- apply the product-boundary rule from `editorial-rules.md`
- preserve any useful human annotations if the file already exists

If `features.json` already exists on the branch, treat it as the editorial
baseline and do a **delta merge**:

- compare the old and new `changes.json` entries by `id`
- score only newly added or materially changed entries
- preserve previous scores and notes for unchanged entries
- avoid rescoring the whole release unless review feedback or new evidence says the earlier cut was wrong

#### c. Re-check the cut with the reader rubric

Before finalizing the candidate list, ask:

- Is this one of the **first things a reader will want to try**?
- Will many readers **use it when they upgrade**?
- Will readers at least be **glad they learned about it now**?
- Or does it mainly read like **internal engineering jargon**?

Default to features that make sense to roughly **80% of the audience**. Specialized features are still welcome, but only when the other 80% can still understand why they matter.

#### d. Check for human edits on the branches

For each branch in this target's family (`$branch_features` and every existing `$branch_features-<component-id>`) that already exists on origin:

```bash
# What has changed on the branch since we last pushed?
git log --oneline --decorate "origin/$branch"
```

Treat branch history as **provenance**, not just diff noise.

Before editing any existing file on a branch:

- inspect the commit history on that branch and identify whether the relevant changes came from `github-actions[bot]` / prior agent runs or from human authors
- for files you plan to modify, inspect the commits that last touched the relevant sections and, when needed, use line-level provenance (`git blame`) to see who last edited the text
- assume content written by non-bot authors is human-owned unless you have strong evidence otherwise

Identify which markdown files and sections humans have edited. For those files, diff them to understand what changed. Do **not** overwrite human-edited sections. Only add new sections or update sections the agent previously wrote that no human has touched. If human-written and agent-written material are interleaved, make the smallest safe edit around the human content instead of rewriting the whole section.

If a component branch already has drafted markdown, that content is the **baseline** for the next run. Follow the shared `update-existing-branch` playbook: refresh `changes.json` (on the features branch) only if the preview moved forward, merge the delta into `features.json`, preserve the current structure on each component branch, address unresolved feedback, and update only the sections affected by new evidence or newly shipped changes.

If provenance is ambiguous, preserve the existing text and ask on the PR before changing it.

#### e. Write or update markdown

Using `features.json`, `changes.json`, and the reference documents:

- Route changes to output files via `product` field and component-mapping.md
- For each component, identify which PRs are worth writing about. **If a component has no noteworthy features in this milestone, skip it entirely — do not create a branch, do not write an empty or stub `.md` file.**
- For each component that *does* have noteworthy features, prepare a worktree on its component branch (`<branch_features>-<component-id>`) containing only that component's `.md` file:

  ```bash
  component_branch="${branch_features}-${component_id}"
  if git show-ref --verify --quiet "refs/remotes/origin/$component_branch"; then
    git fetch origin "$component_branch":"$component_branch"
    git worktree add "/tmp/gh-aw/worktrees/$component_branch" "$component_branch"
  else
    git worktree add -b "$component_branch" "/tmp/gh-aw/worktrees/$component_branch" origin/main
  fi
  ```

  Write or update *only* `$content_dir/<component-id>.md` inside that worktree. Do **not** copy `changes.json`, `features.json`, or any other component's `.md` into the worktree.

  **Do not hand-write the table of contents.** Leave a placeholder bracketed by HTML markers near the top of the file (after the title and intro sentence), then run `markdown-toc` to populate it from the `##` headings. This eliminates anchor typos and orphaned TOC entries when headings are renamed, clustered, or removed.

  ```markdown
  # .NET <Component> in .NET <Version> - Release Notes

  .NET <Version> includes new <Component> features & enhancements:

  <!-- toc -->
  <!-- tocstop -->

  ## First heading

  …
  ```

  After writing all `##` and `###` headings, populate the TOC:

  ```bash
  npx --yes markdown-toc -i "/tmp/gh-aw/worktrees/$component_branch/$content_dir/$component_id.md" --maxdepth 2
  ```

  `--maxdepth 2` includes `##` headings only (matches the established style — `###` subsections inside `## [Area] improvements` are intentionally not listed). The tool reads the headings, generates GitHub-style anchor slugs, and replaces the content between the markers. Re-run it any time you add, remove, or rename a `##` heading.

  Before committing, **lint and auto-fix the markdown** to catch structural mistakes (missing blank lines between headings and body, headings fused with paragraphs, duplicate or orphaned anchors, broken list indentation):

  ```bash
  npx --yes markdownlint-cli --config .github/linters/.markdown-lint.yml --fix "/tmp/gh-aw/worktrees/$component_branch/$content_dir/$component_id.md"
  npx --yes markdownlint-cli --config .github/linters/.markdown-lint.yml "/tmp/gh-aw/worktrees/$component_branch/$content_dir/$component_id.md"
  ```

  The second invocation (no `--fix`) is the gate — it must exit `0` before you commit. If it fails, read the violations, repair the markdown by hand (and re-run `markdown-toc` if you changed a heading), and re-run both commands until clean. Common breakages: a `##` heading that runs into the next paragraph with no newline (e.g. `## Heap Dumps Use HEAP2 by DefaultHeap dumps generated…`); sub-bullets that lost their indentation. Anchor-fragment mismatches (MD051) should not occur once the TOC is auto-generated — if they do, you forgot to re-run `markdown-toc` after changing a heading.

  Run the same lint pair against `README.md` on the features branch worktree before committing it (the README uses inter-file links rather than anchors, so it does not need the TOC tool). **Never commit markdown that does not pass `markdownlint-cli` without `--fix`.**
- On a populated branch, start by editing the existing markdown rather than drafting a replacement from zero. Integrate new material into existing clusters and sections when it fits the current story (for example, extend an existing performance or GC heading instead of creating a duplicate one).
- Write feature descriptions following `format-template.md` and `editorial-rules.md`.
- If `features.json` already includes notes for matching long-running features, use the established feature name and start the section with the standard preview blockquote from the sidecar file.
- Include a **Community contributors** section that mentions every external contributor with at least one merged PR in the milestone for *this component*, even if their change only appears in bug fixes or was not promoted into a top-level feature section. (External contributors who only worked on other components belong on those components' branches.)

Separately, prepare the **features branch** worktree (`$branch_features`) containing only the shared milestone data:

- `$content_dir/changes.json`
- `$content_dir/features.json`
- `$content_dir/build-metadata.json` (always present — regenerated in step (a2))
- `$content_dir/README.md` — milestone landing page / index linking to each component file
- Any other non-component metadata that belongs in the milestone directory (e.g. `release.json`) when applicable

Do **not** include component `.md` files on the features branch.

#### f. Ask for what you can't generate

Some features need content that only humans can provide — benchmark data, definitive code samples, or domain-specific context. When you identify a feature that would benefit from this:

- **Benchmark data** — if a JIT or performance feature would be better told with numbers, write a placeholder section noting the optimization and what it improves, and flag in the manifest `body` or `comment` that benchmark data is still needed
- **Code samples** — if you can't confidently generate a correct, idiomatic sample (e.g., complex API interactions, platform-specific patterns), note in the manifest that a maintainer-provided sample would improve the section. A description without a sample is better than an incorrect sample.
- **Domain expertise** — if a feature's significance isn't clear from the PR title and diff alone, note the open question in the manifest so humans can follow up

Frame these as suggestions, not demands. For example: "This JIT improvement in loop unrolling looks significant. Benchmark data showing the before/after would help tell the story."

#### g. Read and respond to PR comments

For each open release-notes PR, the workflow preloaded:

- issue comments in `/tmp/gh-aw/agent/pr-comments/<pr>-issue-comments.json`
- review comments in `/tmp/gh-aw/agent/pr-comments/<pr>-review-comments.json`
- reviews in `/tmp/gh-aw/agent/pr-comments/<pr>-reviews.json`

Check those files for all comments and review feedback since the last run:

- **Actionable feedback** (e.g., "add detail about X", "this is wrong", "wrong component") → make the change and capture the reply you want posted in the manifest `comment`
- **Questions** (e.g., "is this the right framing?") → answer if you can, or flag it for a human
- **Disagreements** (e.g., "I don't think this shipped") → cross-check against `changes.json`. If the commenter is right, fix it. If unclear, explain what you found and ask for clarification in the manifest `comment`
- **Resolved threads** → skip

Pay special attention to comments that are clearly addressed to the workflow or agent — for example comments that mention the automation directly, ask it to make a change, ask why it chose some wording, or point out a mistake it introduced. Do not silently consume those. If you act, include a reply summary in the manifest `comment` field. If you do not act, explain why in that same field.

Comments may also direct the agent to make **branch changes** — for example "please add this missing feature", "rewrite this section", "keep the current structure but update the intro", "drop this heading", or "preserve the human wording in this paragraph". Treat those as first-class instructions for the next branch update. Apply them on the release branch when they are clear and consistent with shipped content, then summarize what changed in the manifest `comment`. If the request conflicts with release fidelity or is ambiguous, explain the conflict there instead of ignoring it.

When unsure about a human's intent, preserve the text and note the question in the
manifest `comment`. This is a conversation, not a one-shot generation.

#### h. Run the final multi-model review

Before pushing the draft, run the `review-release-notes` stage as a **two-agent parallel review**:

- **Reviewer 1:** Claude Opus 4.6
- **Reviewer 2:** GPT-5.4

Have each reviewer critique the same draft using the same rubric, examples, and
this checklist:

- Which headings still sound vague, passive, anthropomorphic, or promotional?
- Which sections fail the 80/20 reader-value test and should be cut, grouped, or demoted?
- Which sentences infer feelings or outcomes instead of stating the concrete change?
- Which sections drift into API-inventory mode instead of teaching a user story?
- Which code samples or examples are weak or confusing?
- Which links, issue/PR references, or formatting details still violate house style?
- What is the single highest-value rewrite still needed?
- Is the wording conventional, or is it inventing non-standard phrasing or terms?
- Are the subject and its adjective or adverb paired in a familiar way?
- Would this phrasing seem normal within release notes for another developer platform?

Ask for file + heading + issue + suggested rewrite, not generic preference. Then:

- apply the changes that have clear consensus
- keep a human-readable note of any major disagreement
- avoid "majority vote" thinking when it conflicts with fidelity or house style

#### i. Prepare the publication manifest

Each target produces **one manifest per branch you touched** — one for `$branch_features`, plus one for each component branch `<branch_features>-<component-id>` you wrote to. The downstream publish step opens or updates one PR per manifest.

For each branch:

- **No PR exists for this branch** → commit your changes locally on that branch, then write `/tmp/gh-aw/agent/publish/<branch_filename>.json` (replace `/` in the branch name with `-` for the filename) with `branch`, `title`, and `body`.
- **PR already exists for this branch** → reuse that exact branch, commit the updates locally, then write or update the matching manifest with `branch` and a `comment` summarizing what changed; the workflow will reuse the existing PR and post the comment after you finish.

Branch identity is fixed:

- The features branch is exactly `target.branch_features`.
- Each component branch is exactly `<target.branch_features>-<component-id>` where `<component-id>` comes from `components.json`.

Do **not** mint fresh branch names for a rerun of the same target. Do **not** reuse any legacy branch even if it appears to contain related content — copy the relevant content into the appropriate new branch instead.

PR title formats:

- Features branch: `[release-notes] .NET <major_flat> <Capitalized milestone with space>` — for example, `[release-notes] .NET 11 Preview 5`.
- Component branch: `[release-notes] .NET <major_flat> <Capitalized milestone with space> — <Component title>` — for example, `[release-notes] .NET 11 Preview 5 — ASP.NET Core` (use the component's `title` field from `components.json`).

PR bodies:

- Features branch body: summarize the target milestone, number of changes, which component branches were created/updated, and any open questions or items needing human review.
- Component branch body: summarize what changed in that component this milestone — number of features written, notable additions, and any open questions for that team. Link back to the features-branch PR.

Manifest examples (target features branch `release-notes/dotnet-11-preview-5-features`):

```json
{
  "branch": "release-notes/dotnet-11-preview-5-features",
  "title": "[release-notes] .NET 11 Preview 5",
  "body": "Draft release notes data for .NET 11 Preview 5.\n\n- changes.json generated from release/11.0.1xx-preview4 to main\n- features.json scored for 87 changes\n- Component branches opened: runtime, aspnetcore, sdk\n- Open question: benchmark data still needed for the JIT section (see runtime PR)",
  "comment": "Refreshed changes.json and features.json scores."
}
```

```json
{
  "branch": "release-notes/dotnet-11-preview-5-features-runtime",
  "title": "[release-notes] .NET 11 Preview 5 — .NET Runtime",
  "body": "Draft Runtime release notes for .NET 11 Preview 5.\n\n- 12 features written across GC, JIT, and diagnostics\n- See companion features PR for changes.json/features.json\n- Open question: benchmark data still needed for the new loop-unrolling optimization",
  "comment": "Added two new JIT features and refreshed the GC section."
}
```

Publication manifests are **required**. A run that edits files for an active target is not complete until it has written a manifest for every branch it touched — the features branch and every component branch — so the workflow can publish them after agent execution. Conversely, do **not** write a manifest for a component branch you did not modify (the workflow will not open empty PRs).

### 3. Handle transitions

Things change between runs. Handle these gracefully:

- **Main bumps to next iteration** — the previous milestone's head ref changes from `main` to its release branch or tag. Regenerate with the correct ref.
- **New tag appears** — a milestone was finalized. Do a final regeneration with `--head <tag>` to capture exactly what shipped. Note in the PR that this is now final.
- **Release branch appears** — a milestone is stabilizing. Switch the head ref from `main` to the release branch.
- **PR was merged** — the milestone is done. Skip it on future runs.
- **PR was closed** — something went wrong. Don't reopen. Log it and move on.

### 4. Daily summary

At the end of each run, include in the manifest `comment` for each updated PR:

- What was regenerated or updated
- How many new changes appeared since yesterday
- Whether the head ref changed
- Any comments that still need human attention
