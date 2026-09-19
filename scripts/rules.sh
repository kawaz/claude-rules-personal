#!/usr/bin/env bash
# rules.sh — claude-rules-* の rules / skills 層を各 CLAUDE_CONFIG_DIR に symlink で配備する。
# `just rules-{setup,check}` から呼ぶ。
#
#   setup : repos_mapping.local.json の各面 (home を持つ repo) に symlink を張り、dangling link を掃除する
#   check : 各面に期待する symlink が揃っていて、実体を指しているか (dangling / 未配備を検出)
#
# 配備先レイアウト (rules: ディレクトリ symlink / skills: skill ごとの symlink):
#   $HOME_DIR/rules/for-me-from-<self>       -> <self>/for-me/rules
#   $HOME_DIR/rules/for-all-from-<repo>      -> <repo>/for-all/rules    (全 repo)
#   $HOME_DIR/rules/for-others-from-<repo>   -> <repo>/for-others/rules (self 以外)
#   $HOME_DIR/skills/<repo>-<slug>           -> <repo>/for-*/skills/<slug>
#   $HOME_DIR/CLAUDE.md                      -> <self>/for-me/CLAUDE.md
#
# skills / agents は plugin 配布へ移行中 (plugin 自身の skills/ agents/ は自動走査される)。
# for-*/skills/ を残す overlay だけ上の形で link し、agents は link しない ($HOME_DIR/agents の
# dangling link は旧方式の残骸として掃除する)。plugin は scripts/plugins.sh が担う。
#
# 使い方: scripts/rules.sh <setup|check> [--home <dir>]   (home 省略時は宣言された全面)
set -euo pipefail

CMD="${1:-}"; shift || true
case "$CMD" in setup|check) ;; *) echo "usage: $0 <setup|check> [--home <dir>]" >&2; exit 2 ;; esac
ONLY_HOME=""
if [ "${1:-}" = "--home" ]; then ONLY_HOME="${2/#\~/$HOME}"; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
MAPPING="${MAPPING:-$SCRIPT_DIR/../repos_mapping.local.json}"
REPO_BASE="${REPO_BASE:-${XDG_DATA_HOME:-$HOME/.local/share}/repos/github.com}"
WORKSPACE="${WORKSPACE:-main}"
[ -f "$MAPPING" ] || { echo "Missing mapping: $MAPPING" >&2; exit 1; }

NAMES=(); REPOS=(); HOMES=()
while IFS=$'\t' read -r n r h; do NAMES+=("$n"); REPOS+=("$r"); HOMES+=("${h/#\~/$HOME}"); done \
  < <(jq -r '.repos[] | [.name, .repo, (.home // "")] | @tsv' "$MAPPING")

repo_root() { printf '%s/%s/%s/%s\n' "$REPO_BASE" "${1%%/*}" "${1##*/}" "$WORKSPACE"; }

link_dir() {  # $1 dest dir, $2 link name, $3 source
  if [ ! -d "$3" ]; then echo "  skip (no dir): $2 -> $3" >&2; return; fi
  ln -sfn "$3" "$1/$2"; echo "  linked: $2 -> $3"
}

# <repo>/for-*/skills/<slug> をフラットな <repo>-<slug> で link する (Claude Code は skills/ を
# 再帰しないためフラット必須、<repo>- prefix で overlay 間の slug 衝突を避ける)
link_skills() {  # $1 skills dest, $2 repo name, $3 skills src
  [ -d "$3" ] || return 0
  local d
  for d in "$3"/*/; do
    [ -d "$d" ] || continue
    ln -sfn "${d%/}" "$1/$2-$(basename "$d")"; echo "  skill linked: $2-$(basename "$d") -> ${d%/}"
  done
}

prune_dangling() {  # $1 dir
  [ -d "$1" ] || return 0
  local l
  for l in "$1"/*; do
    if [ -L "$l" ] && [ ! -e "$l" ]; then rm "$l"; echo "  pruned dangling: $l"; fi
  done
}

# 面ごとに期待する link を "link_path<TAB>source" で列挙する (setup と check の共通定義)
expected_links() {  # $1 home, $2 self name
  local home=$1 self=$2 i name root d
  for i in "${!NAMES[@]}"; do
    name="${NAMES[$i]}"; root=$(repo_root "${REPOS[$i]}")
    [ -d "$root" ] || continue
    [ -d "$root/for-all/rules" ] && printf '%s\t%s\n' "$home/rules/for-all-from-$name" "$root/for-all/rules"
    for d in "$root/for-all/skills"/*/; do [ -d "$d" ] && printf '%s\t%s\n' "$home/skills/$name-$(basename "$d")" "${d%/}"; done
    if [ "$name" = "$self" ]; then
      [ -d "$root/for-me/rules" ] && printf '%s\t%s\n' "$home/rules/for-me-from-$name" "$root/for-me/rules"
      [ -f "$root/for-me/CLAUDE.md" ] && printf '%s\t%s\n' "$home/CLAUDE.md" "$root/for-me/CLAUDE.md"
      for d in "$root/for-me/skills"/*/; do [ -d "$d" ] && printf '%s\t%s\n' "$home/skills/$name-$(basename "$d")" "${d%/}"; done
    else
      [ -d "$root/for-others/rules" ] && printf '%s\t%s\n' "$home/rules/for-others-from-$name" "$root/for-others/rules"
      for d in "$root/for-others/skills"/*/; do [ -d "$d" ] && printf '%s\t%s\n' "$home/skills/$name-$(basename "$d")" "${d%/}"; done
    fi
  done
  return 0
}

do_setup() {  # $1 home, $2 self
  local home=$1 self=$2 i name root
  local dest="$home/rules" agents="$home/agents" skills="$home/skills"
  mkdir -p "$dest" "$agents" "$skills"
  # 旧フラット配置の *.md が直置きされていたら手動移行を求めて止める (自動移動はしない:
  # setup が作った迷子ディレクトリと Claude Code のディレクトリが区別できなくなる)
  if find "$dest" "$agents" -maxdepth 1 -type f -name '*.md' 2>/dev/null | grep -q .; then
    echo "ERROR: legacy *.md files exist directly under $dest / $agents. Move them into a claude-rules-* repo (for-me/for-all/for-others under rules/) and rerun." >&2
    return 1
  fi
  for i in "${!NAMES[@]}"; do
    name="${NAMES[$i]}"; root=$(repo_root "${REPOS[$i]}")
    [ -d "$root" ] || { echo "  WARN: repo missing: $root (clone from gh:${REPOS[$i]})" >&2; continue; }
    link_dir "$dest" "for-all-from-$name" "$root/for-all/rules"
    link_skills "$skills" "$name" "$root/for-all/skills"
    if [ "$name" = "$self" ]; then
      link_dir "$dest" "for-me-from-$name" "$root/for-me/rules"
      link_skills "$skills" "$name" "$root/for-me/skills"
      if [ -f "$root/for-me/CLAUDE.md" ]; then ln -sfn "$root/for-me/CLAUDE.md" "$home/CLAUDE.md"; echo "  linked: CLAUDE.md -> $root/for-me/CLAUDE.md"; fi
    else
      link_dir "$dest" "for-others-from-$name" "$root/for-others/rules"
      link_skills "$skills" "$name" "$root/for-others/skills"
    fi
  done
  prune_dangling "$dest"; prune_dangling "$agents"; prune_dangling "$skills"
}

do_check() {  # $1 home, $2 self
  local home=$1 self=$2 bad=0 link src l
  while IFS=$'\t' read -r link src; do
    [ -n "$link" ] || continue
    if [ ! -L "$link" ]; then echo "  missing link: $link"; bad=1
    elif [ "$(readlink -f "$link")" != "$(readlink -f "$src")" ]; then echo "  wrong target: $link -> $(readlink "$link") (expected $src)"; bad=1
    elif [ ! -e "$link" ]; then echo "  dangling: $link"; bad=1; fi
  done < <(expected_links "$home" "$self")
  for l in "$home/rules"/* "$home/skills"/* "$home/agents"/*; do
    [ -L "$l" ] && [ ! -e "$l" ] && { echo "  dangling: $l"; bad=1; }
  done
  if [ "$bad" = 0 ]; then echo "OK    $home (self=$self)"; else echo "DRIFT $home (self=$self)"; fi
  return $bad
}

fail=0
for i in "${!NAMES[@]}"; do
  home="${HOMES[$i]}"; self="${NAMES[$i]}"
  [ -n "$home" ] || continue
  [ -z "$ONLY_HOME" ] || [ "$home" = "$ONLY_HOME" ] || continue
  [ -d "$home" ] || { echo "skip  $home (no dir)"; continue; }
  case "$CMD" in
    setup) echo "--- $home (self=$self)"; do_setup "$home" "$self" && do_check "$home" "$self" || fail=1 ;;
    check) do_check "$home" "$self" || fail=1 ;;
  esac
done
if [ "$fail" != 0 ]; then echo "→ 'just rules-setup' で配備し直す" >&2; exit 1; fi
