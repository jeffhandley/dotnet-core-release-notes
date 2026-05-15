#!/usr/bin/env bash
# Shared helpers used by both release-notes.md (post-step publish) and
# fix-release-notes-lint.md (fixup workflow). Sourced, not executed.
#
# Provides:
#   setup_toc_tool          — install github-slugger and emit /tmp/toctool/regen-toc.js
#   regenerate_tocs BRANCH  — regenerate `<!-- toc -->` blocks in files this branch
#                             added/modified vs origin/main, amending the tip commit
#   lint_branch BRANCH OUT  — run markdownlint against each .md this branch
#                             added/modified vs origin/main; writes violations to OUT;
#                             returns 0 if clean, 1 if any file failed

setup_toc_tool() {
  mkdir -p /tmp/toctool
  ( cd /tmp/toctool && npm init -y >/dev/null 2>&1 && npm install --silent github-slugger >/dev/null 2>&1 )

  cat > /tmp/toctool/regen-toc.js <<'TOC_JS_EOF'
const fs = require('fs');
const GithubSlugger = require('github-slugger').default || require('github-slugger');
const path = process.argv[2];
if (!path) { console.error('usage: regen-toc.js FILE.md'); process.exit(2); }
let content = fs.readFileSync(path, 'utf8');
const startMarker = '<!-- toc -->';
const endMarker = '<!-- tocstop -->';
const start = content.indexOf(startMarker);
const end = content.indexOf(endMarker);
if (start === -1 || end === -1 || end < start) process.exit(0);
const slugger = new GithubSlugger();
const lines = content.split('\n');
const entries = [];
let inCode = false;
for (const line of lines) {
  if (/^```/.test(line)) { inCode = !inCode; continue; }
  if (inCode) continue;
  const m = /^##\s+([^#].*)$/.exec(line);
  if (!m) continue;
  const text = m[1].trimEnd();
  const plain = text.replace(/\[([^\]]+)\]\([^)]+\)/g, '$1').replace(/`/g, '');
  const slug = slugger.slug(plain);
  entries.push(`- [${text}](#${slug})`);
}
const toc = entries.length
  ? `${startMarker}\n\n${entries.join('\n')}\n\n${endMarker}`
  : `${startMarker}\n${endMarker}`;
const out = content.slice(0, start) + toc + content.slice(end + endMarker.length);
fs.writeFileSync(path, out);
TOC_JS_EOF
}

# Regenerate auto-TOCs in every .md this branch added/modified vs origin/main.
# Amends the tip commit if anything changed. Working tree must be checked out on BRANCH.
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
    ( cd /tmp/toctool && node regen-toc.js "$GITHUB_WORKSPACE/$md_path" ) || true
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

# Run markdownlint against each .md this branch added/modified vs origin/main.
# Writes violations to OUT (one section per failing file). Returns 0 if all clean.
lint_branch() {
  local branch="$1"
  local out="$2"
  : > "$out"
  local md_files
  md_files=$(git diff --name-only "origin/main...$branch" -- '*.md' 2>/dev/null || true)
  [ -z "$md_files" ] && return 0
  local any_failed=0
  local tmpdir
  tmpdir=$(mktemp -d)
  while IFS= read -r md_path; do
    [ -z "$md_path" ] && continue
    [ -f "$md_path" ] || continue
    local dest="$tmpdir/$md_path"
    mkdir -p "$(dirname "$dest")"
    cp "$md_path" "$dest"
  done <<< "$md_files"
  ( cd "$tmpdir" && npx --yes markdownlint-cli \
      --config "$GITHUB_WORKSPACE/.github/linters/.markdown-lint.yml" \
      $(echo "$md_files" | tr '\n' ' ') 2> "$out.raw" || true )
  if [ -s "$out.raw" ]; then
    sed "s|$tmpdir/||g" "$out.raw" > "$out"
    any_failed=1
  fi
  rm -rf "$tmpdir" "$out.raw" 2>/dev/null || true
  return $any_failed
}
