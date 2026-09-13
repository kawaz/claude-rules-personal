#!/usr/bin/env bash
# plugins.sh — plugin の宣言 (plugins.json / repos_mapping.json) と各 CLAUDE_CONFIG_DIR の
# install 状態をつなぐ。`just plugins-{check,setup,update}` から呼ぶ。
#
#   check  : 宣言された plugin が入っているか (rules 面は不足だけ、bare 面は過不足)
#   setup  : 宣言された plugin を marketplace add + install する (未 install のものだけ)
#   update : 宣言された plugin の marketplace update + plugin update
#
# 宣言の所在:
#   rules 面 (repos_mapping.json .repos[] で home を持つ面): 全 repo の for-all/plugins.json +
#     その面を所有する repo の for-me/plugins.json
#   bare 面 (repos_mapping.json .pluginOnlyHomes[]): entry の plugins[] (marketplace は
#     "<plugin>@<marketplace>" の marketplace 部を owner/repo に引く map を entry の marketplaces に持つ)
#
# 宣言外に手で入れた plugin と、enable / disable の状態は一切触らない (disabled は install 済み扱い)。
#
# 使い方: scripts/plugins.sh <check|setup|update> [--home <dir>]
set -euo pipefail

CMD="${1:-}"; shift || true
case "$CMD" in check|setup|update) ;; *) echo "usage: $0 <check|setup|update> [--home <dir>]" >&2; exit 2 ;; esac
ONLY_HOME=""
if [ "${1:-}" = "--home" ]; then ONLY_HOME="${2/#\~/$HOME}"; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAPPING="${MAPPING:-$SCRIPT_DIR/../repos_mapping.json}"
REPO_BASE="${REPO_BASE:-${XDG_DATA_HOME:-$HOME/.local/share}/repos/github.com}"
WORKSPACE="${WORKSPACE:-main}"

expand() { printf '%s\n' "${1/#\~/$HOME}"; }
repo_root() { printf '%s/%s/%s/%s\n' "$REPO_BASE" "${1%%/*}" "${1##*/}" "$WORKSPACE"; }
installed() { CLAUDE_CONFIG_DIR="$1" claude plugin list 2>/dev/null | awk '/^  ❯ /{print $2}' | sort -u; }
# plugins.json → "plugin<TAB>marketplace(owner/repo or empty)" 行
declared_in() { [ -f "$1" ] && jq -r '.plugins[]? | [.plugin, (.marketplace // "")] | @tsv' "$1" || true; }

# 面ごとの宣言を "plugin<TAB>marketplace<TAB>ctx_repo_root" で列挙する。ctx_repo_root は
# marketplace add をその repo の direnv 環境で実行すべき時だけ非空 (自面の for-me 宣言:
# private marketplace の SSH 認証が cwd と .envrc で決まるため)。
declarations() {  # $1 home
  local home=$1 repo root
  # rules 面
  repo=$(jq -r --arg h "$home" '.repos[] | select((.home // "" | sub("^~"; env.HOME)) == $h) | .repo' "$MAPPING")
  if [ -n "$repo" ]; then
    jq -r '.repos[].repo' "$MAPPING" | while read -r r; do
      declared_in "$(repo_root "$r")/for-all/plugins.json" | sed 's/$/\t/'
    done
    root=$(repo_root "$repo")
    declared_in "$root/for-me/plugins.json" | sed "s|\$|\t$root|"
    return
  fi
  # bare 面
  jq -r --arg h "$home" '.pluginOnlyHomes[]? | select((.home | sub("^~"; env.HOME)) == $h)
    | .plugins[] as $p | [$p, (.marketplaces[($p | split("@")[1])] // "")] | @tsv' "$MAPPING" | sed 's/$/\t/'
}

homes() {
  jq -r '(.repos[] | .home // empty), (.pluginOnlyHomes[]? | .home)' "$MAPPING" | sed "s|^~|$HOME|" | sort -u
}
is_bare() { jq -e --arg h "$1" '.pluginOnlyHomes[]? | select((.home | sub("^~"; env.HOME)) == $h)' "$MAPPING" >/dev/null; }

do_check() {  # $1 home
  local home=$1 expected actual missing extra=""
  expected=$(declarations "$home" | cut -f1 | sort -u)
  actual=$(installed "$home")
  missing=$(comm -23 <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") | grep . || true)
  if is_bare "$home"; then
    extra=$(comm -13 <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") | grep . || true)
  fi
  if [ -z "$missing" ] && [ -z "$extra" ]; then echo "OK    $home"; return 0; fi
  echo "DRIFT $home"
  [ -z "$missing" ] || printf '  missing (宣言あり・未 install): %s\n' $missing
  [ -z "$extra" ]   || printf '  extra   (宣言なし・install 済、bare 面は ccmsg 以外を置かない): %s\n' $extra
  return 1
}

add_marketplace() {  # $1 home, $2 owner/repo, $3 ctx repo root (optional)
  local home=$1 mp=$2 ctx=${3:-}
  if [ -n "$ctx" ] && [ -d "$ctx" ]; then
    ( cd "$ctx" && CLAUDE_CONFIG_DIR="$home" direnv exec . claude plugin marketplace add "$mp" ) 2>&1 | grep -E '✔|✗|already' || true
  else
    CLAUDE_CONFIG_DIR="$home" claude plugin marketplace add "$mp" 2>&1 | grep -E '✔|✗|already' || true
  fi
}

do_setup() {  # $1 home
  local home=$1 seen="" pl mp ctx actual
  actual=$(installed "$home")
  while IFS=$'\t' read -r pl mp ctx; do
    [ -n "$pl" ] || continue
    if [ -n "$mp" ] && [[ "$seen" != *"|$mp|"* ]]; then
      seen="$seen|$mp|"; add_marketplace "$home" "$mp" "$ctx"
    fi
    if printf '%s\n' "$actual" | grep -qx "$pl"; then
      echo "  already installed: $pl"
    else
      CLAUDE_CONFIG_DIR="$home" claude plugin install "$pl" 2>&1 | tail -1 || true
    fi
  done < <(declarations "$home")
}

do_update() {  # $1 home
  local home=$1 seen="" pl mp ctx
  while IFS=$'\t' read -r pl mp ctx; do
    [ -n "$pl" ] || continue
    local mpname="${pl##*@}"
    if [[ "$seen" != *"|$mpname|"* ]]; then
      seen="$seen|$mpname|"
      CLAUDE_CONFIG_DIR="$home" claude plugin marketplace update "$mpname" 2>&1 | tail -1 || true
    fi
    CLAUDE_CONFIG_DIR="$home" claude plugin update "$pl" 2>&1 | tail -1 || true
  done < <(declarations "$home")
}

fail=0
for home in $(homes); do
  [ -z "$ONLY_HOME" ] || [ "$home" = "$ONLY_HOME" ] || continue
  [ -d "$home" ] || { echo "skip  $home (no dir)"; continue; }
  case "$CMD" in
    check)  do_check "$home" || fail=1 ;;
    setup)  echo "--- $home"; do_setup "$home"; do_check "$home" || fail=1 ;;
    update) echo "--- $home"; do_update "$home" ;;
  esac
done
if [ "$fail" != 0 ]; then
  echo "→ 不足は 'just plugins-setup' で入れる。bare 面の余分は claude plugin uninstall で外す" >&2
  exit 1
fi
