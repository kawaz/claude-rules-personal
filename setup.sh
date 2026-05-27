#!/usr/bin/env bash
# setup.sh — install claude-rules-* layers into a CLAUDE_CONFIG_DIR.
#
# Reads repos_mapping.json (sibling to this script) and lays out
# for-me/for-all/for-others as directory symlinks under $TARGET/rules.
# Then installs plugins listed in any for-all/plugins.json across repos.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
MAPPING="$SCRIPT_DIR/repos_mapping.json"
REPO_BASE="${REPO_BASE:-$HOME/.dotfiles/local/share/repos/github.com}"
WORKSPACE="${WORKSPACE:-main}"   # jj workspace dir name under each repo root

usage() {
  cat <<EOF
Usage: $0 [--home PATH]

Without --home, derives the target from \$CLAUDE_CONFIG_DIR.

repos_mapping.json defines all repos and which CLAUDE_CONFIG_DIR each one
"owns". The repo whose 'home' matches the target is treated as 'self'.

Target layout (rules: directory symlink / skills: per-skill symlink):
  \$TARGET/rules/for-me-from-<self>       -> <self>/for-me/rules
  \$TARGET/rules/for-all-from-<repo>      -> <repo>/for-all/rules   (every repo)
  \$TARGET/rules/for-others-from-<repo>   -> <repo>/for-others/rules (non-self repos)
  \$TARGET/skills/<repo>-<slug>           -> <repo>/for-*/skills/<slug>
  \$TARGET/CLAUDE.md                      -> <self>/for-me/CLAUDE.md

Plugins:
  Every repo's for-all/plugins.json is merged and applied via
  \`claude plugin marketplace add\` + \`claude plugin install\` (idempotent).

Env:
  REPO_BASE  Default: \$HOME/.dotfiles/local/share/repos/github.com
  WORKSPACE  Default: main (jj workspace under each repo root)
EOF
  exit 1
}

TARGET="${CLAUDE_CONFIG_DIR:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --home) TARGET="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

TARGET="${TARGET/#\~/$HOME}"
[ -n "$TARGET" ] || { echo "Set CLAUDE_CONFIG_DIR or pass --home" >&2; exit 1; }
[ -d "$TARGET" ] || { echo "Target dir not found: $TARGET" >&2; exit 1; }
[ -f "$MAPPING" ] || { echo "Missing mapping: $MAPPING" >&2; exit 1; }

# Load repos list (bash 3.2-compatible: no mapfile)
NAMES=()
REPOS=()
HOMES=()
while IFS=$'\t' read -r n r h; do
  NAMES+=("$n"); REPOS+=("$r"); HOMES+=("$h")
done < <(jq -r '.repos[] | [.name, .repo, (.home // "")] | @tsv' "$MAPPING")

# Find self
SELF=""
for i in "${!NAMES[@]}"; do
  h="${HOMES[$i]/#\~/$HOME}"
  if [ -n "$h" ] && [ "$h" = "$TARGET" ]; then
    SELF="${NAMES[$i]}"; break
  fi
done
[ -n "$SELF" ] || { echo "No repo in mapping has home matching $TARGET" >&2; exit 1; }

echo "Target: $TARGET (self=$SELF)"
DEST="$TARGET/rules"
SKILLS_DEST="$TARGET/skills"
mkdir -p "$DEST" "$SKILLS_DEST"

# Detect legacy *.md files directly in DEST. Refuse to proceed if found.
#
# Auto-moving was deliberately removed: any stray directory created by setup
# pollutes the Claude Code config-dir layout (CC and user-created dirs become
# indistinguishable). The migration step from the old flat layout is a one-time
# operation that the user handles manually.
LEGACY=()
while IFS= read -r -d '' f; do LEGACY+=("$f"); done < <(
  find "$DEST" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null
)
if [ "${#LEGACY[@]}" -gt 0 ]; then
  echo "ERROR: legacy *.md files exist directly under $DEST:" >&2
  for f in "${LEGACY[@]}"; do echo "  $f" >&2; done
  echo "" >&2
  echo "These predate the symlinked layout. Remove or relocate them manually," >&2
  echo "then rerun setup.sh. Their content should already be in claude-rules-*" >&2
  echo "repos (in for-me/, for-all/, or for-others/ under rules/)." >&2
  exit 1
fi

link_dir() {
  local link_name=$1 source=$2
  if [ ! -d "$source" ]; then
    echo "  skip (no dir): $link_name -> $source" >&2; return
  fi
  ln -sfn "$source" "$DEST/$link_name"
  echo "  linked: $link_name -> $source"
}

# Link each skill directory under <repo>/for-*/skills/ as a flat, prefixed
# symlink: $SKILLS_DEST/<repo>-<slug>. Claude Code does not recurse into
# skills/ subdirectories, so a flat layout is required; the <repo>- prefix
# keeps slugs unique across overlays and aids slash-command completion.
link_skills() {
  local repo_name=$1 skills_src=$2
  [ -d "$skills_src" ] || return 0
  local slug_dir slug
  for slug_dir in "$skills_src"/*/; do
    [ -d "$slug_dir" ] || continue
    slug=$(basename "$slug_dir")
    ln -sfn "${slug_dir%/}" "$SKILLS_DEST/$repo_name-$slug"
    echo "  skill linked: $repo_name-$slug -> ${slug_dir%/}"
  done
}

# Remove dangling symlinks (target no longer exists) directly under a dir.
# Lets rules/skills that were moved or deleted leave no stale links behind.
prune_dangling() {
  local dir=$1 link
  [ -d "$dir" ] || return 0
  for link in "$dir"/*; do
    if [ -L "$link" ] && [ ! -e "$link" ]; then
      rm "$link"
      echo "  pruned dangling: $link"
    fi
  done
}

PLUGIN_JSONS=()

for i in "${!NAMES[@]}"; do
  name="${NAMES[$i]}"
  repo="${REPOS[$i]}"
  owner="${repo%%/*}"
  reponame="${repo##*/}"
  repo_root="$REPO_BASE/$owner/$reponame/$WORKSPACE"

  if [ ! -d "$repo_root" ]; then
    echo "  WARN: repo missing: $repo_root  (clone from gh:$repo)" >&2
    continue
  fi

  link_dir "for-all-from-$name" "$repo_root/for-all/rules"
  link_skills "$name" "$repo_root/for-all/skills"
  if [ "$name" = "$SELF" ]; then
    link_dir "for-me-from-$name" "$repo_root/for-me/rules"
    link_skills "$name" "$repo_root/for-me/skills"
    # self repo's for-me/CLAUDE.md -> $TARGET/CLAUDE.md (env-specific user memory)
    if [ -f "$repo_root/for-me/CLAUDE.md" ]; then
      ln -sfn "$repo_root/for-me/CLAUDE.md" "$TARGET/CLAUDE.md"
      echo "  linked: CLAUDE.md -> $repo_root/for-me/CLAUDE.md"
    fi
  else
    link_dir "for-others-from-$name" "$repo_root/for-others/rules"
    link_skills "$name" "$repo_root/for-others/skills"
  fi

  [ -f "$repo_root/for-all/plugins.json" ] && PLUGIN_JSONS+=("$repo_root/for-all/plugins.json")
done

# Plugin install (idempotent)
if [ "${#PLUGIN_JSONS[@]}" -gt 0 ]; then
  echo
  echo "=== Plugin install ==="

  declare -a MARKETPLACES=()
  declare -a INSTALLS=()

  for pj in "${PLUGIN_JSONS[@]}"; do
    while IFS= read -r mp; do
      [ -n "$mp" ] && MARKETPLACES+=("$mp")
    done < <(jq -r '.plugins[]?.marketplace // empty' "$pj")
    while IFS= read -r pl; do
      [ -n "$pl" ] && INSTALLS+=("$pl")
    done < <(jq -r '.plugins[]?.plugin // empty' "$pj")
  done

  # dedup marketplaces
  if [ "${#MARKETPLACES[@]}" -gt 0 ]; then
    for mp in $(printf "%s\n" "${MARKETPLACES[@]}" | sort -u); do
      claude plugin marketplace add "$mp" 2>&1 | grep -E '✔|✗|already|Adding' || true
    done
  fi

  # install plugins (skip if already installed)
  INSTALLED=$(claude plugin list 2>/dev/null | awk '/^  ❯ /{print $2}' || true)
  for pl in "${INSTALLS[@]}"; do
    if printf '%s\n' "$INSTALLED" | grep -qx "$pl"; then
      echo "  already installed: $pl"
    else
      claude plugin install "$pl" 2>&1 | tail -1 || true
    fi
  done
fi

# Prune dangling symlinks left by moved/removed rules and skills
echo
echo "=== Prune dangling symlinks ==="
prune_dangling "$DEST"
prune_dangling "$SKILLS_DEST"

echo
echo "Install complete: rules=$DEST skills=$SKILLS_DEST"
echo "--- rules ---"
ls -la "$DEST" | grep -vE '^total|^d.*\.\.?$|\.legacy-backup' | head -30
echo "--- skills ---"
ls -la "$SKILLS_DEST" | grep -vE '^total|^d.*\.\.?$' | head -30
