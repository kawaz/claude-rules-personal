#!/usr/bin/env bash
# install.sh — Distribute claude-rules to ~/.claude/rules or ~/.claude-work/rules
#
# Uses directory symlinks (not file symlinks) so new .md files added to source
# repos are picked up automatically without re-running install.
#
# Usage:
#   ./install.sh <target> [--overlay PATH ...]
#
#   target: personal | work
#   --overlay PATH: external overlay repo (repeatable)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

usage() {
  cat <<EOF
Usage: $0 <target> [--overlay PATH ...]

Targets:
  personal    Install to ~/.claude/rules/
  work        Install to ~/.claude-work/rules/

Options:
  --overlay PATH    External overlay repo root. Repeatable.
                    For 'personal' target, reads PATH/personal-overlay/rules/.
                    For 'work' target,     reads PATH/rules/.

Existing *.md files directly under the target dir are moved to
.legacy-backup-YYYYMMDD-HHMMSS/ on first run (subdirectories untouched).
EOF
  exit 1
}

TARGET=""
OVERLAYS=()

while [ $# -gt 0 ]; do
  case "$1" in
    personal|work) TARGET="$1"; shift ;;
    --overlay) [ -n "${2:-}" ] || { echo "--overlay requires PATH" >&2; exit 1; }
               OVERLAYS+=("$2"); shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

[ -z "$TARGET" ] && usage

case "$TARGET" in
  personal)
    DEST="$HOME/.claude/rules"
    LAYER_DIR_LOCAL="personal/rules"
    LAYER_SUBDIR_OVERLAY="personal-overlay/rules"
    LAYER_LABEL="personal"
    ;;
  work)
    DEST="$HOME/.claude-work/rules"
    LAYER_DIR_LOCAL="work-overlay/rules"
    LAYER_SUBDIR_OVERLAY="rules"
    LAYER_LABEL="work-overlay"
    ;;
esac

mkdir -p "$DEST"

# Backup legacy *.md files directly under DEST (subdirectories untouched)
LEGACY_FILES=()
while IFS= read -r -d '' f; do LEGACY_FILES+=("$f"); done < <(
  find "$DEST" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null
)
if [ "${#LEGACY_FILES[@]}" -gt 0 ]; then
  BACKUP="$DEST/.legacy-backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP"
  echo "Backing up ${#LEGACY_FILES[@]} legacy *.md file(s) to $BACKUP"
  mv "${LEGACY_FILES[@]}" "$BACKUP/"
fi

link_dir() {
  local link_name=$1
  local target_path=$2
  if [ ! -d "$target_path" ]; then
    echo "  skip (not a dir): $link_name -> $target_path" >&2
    return
  fi
  ln -sfn "$target_path" "$DEST/$link_name"
  echo "  linked: $DEST/$link_name -> $target_path"
}

link_dir "common"        "$SCRIPT_DIR/common/rules"
link_dir "$LAYER_LABEL"  "$SCRIPT_DIR/$LAYER_DIR_LOCAL"

for overlay_path in "${OVERLAYS[@]}"; do
  overlay_path="${overlay_path/#\~/$HOME}"
  # overlay_path expected to point at a workspace dir (e.g., .../claude-rules-emeradaco/main).
  # Extract overlay name from the repo parent (one level up).
  overlay_name=$(basename "$(dirname "$overlay_path")" | sed 's/^claude-rules-//')
  link_dir "sanitize-$overlay_name" "$overlay_path/$LAYER_SUBDIR_OVERLAY"
done

echo
echo "Install complete: $DEST"
echo "---"
ls -la "$DEST" | grep -vE '^total|^d.*\.\.?$' || true
