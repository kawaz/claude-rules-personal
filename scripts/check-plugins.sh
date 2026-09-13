#!/usr/bin/env bash
# check-plugins.sh — plugin の install 状態を宣言と突き合わせる。
#
#   rules 面 (repos_mapping.json .repos[] で home を持つもの):
#     全 repo の for-all/plugins.json + 自 repo の for-me/plugins.json に宣言された plugin が
#     install 済みか (不足だけを検査。宣言外の plugin が入っているのは自由)
#   bare 面 (repos_mapping.json .pluginOnlyHomes[]):
#     entry の plugins[] が install 済みで、かつそれ以外が入っていないか
#
# 差分があれば 1 で終了。使い方: scripts/check-plugins.sh [--home <dir>]
#
# disabled の plugin は install 済みとして扱う (enable / disable の状態はユーザの手動管理で、
# 本スクリプトも setup.sh も触らない)。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAPPING="${MAPPING:-$SCRIPT_DIR/../repos_mapping.json}"
REPO_BASE="${REPO_BASE:-${XDG_DATA_HOME:-$HOME/.local/share}/repos/github.com}"
WORKSPACE="${WORKSPACE:-main}"
ONLY_HOME=""
if [ "${1:-}" = "--home" ]; then ONLY_HOME="${2/#\~/$HOME}"; fi

expand() { printf '%s\n' "${1/#\~/$HOME}"; }
installed() { CLAUDE_CONFIG_DIR="$1" claude plugin list 2>/dev/null | awk '/^  ❯ /{print $2}' | sort -u; }
declared_in() { [ -f "$1" ] && jq -r '.plugins[]?.plugin // empty' "$1" || true; }
repo_root() { printf '%s/%s/%s/%s\n' "$REPO_BASE" "${1%%/*}" "${1##*/}" "$WORKSPACE"; }

fail=0
report() {  # $1 home, $2 missing, $3 extra
  if [ -z "$2" ] && [ -z "$3" ]; then echo "OK    $1"; return; fi
  fail=1; echo "DRIFT $1"
  [ -z "$2" ] || printf '  missing (宣言あり・未 install): %s\n' $2
  [ -z "$3" ] || printf '  extra   (宣言なし・install 済): %s\n' $3
}

# for-all の宣言 (全面共通)
all_decl=$(jq -r '.repos[].repo' "$MAPPING" | while read -r r; do declared_in "$(repo_root "$r")/for-all/plugins.json"; done | sort -u)

# rules 面: 不足だけ
jq -r '.repos[] | select(.home) | [.repo, .home] | @tsv' "$MAPPING" | while IFS=$'\t' read -r repo home; do
  home=$(expand "$home")
  [ -z "$ONLY_HOME" ] || [ "$home" = "$ONLY_HOME" ] || continue
  [ -d "$home" ] || { echo "skip  $home (no dir)"; continue; }
  expected=$( { printf '%s\n' "$all_decl"; declared_in "$(repo_root "$repo")/for-me/plugins.json"; } | sort -u)
  missing=$(comm -23 <(printf '%s\n' "$expected") <(installed "$home"))
  report "$home" "$missing" ""
done | tee /tmp/check-plugins.$$
grep -q '^DRIFT' /tmp/check-plugins.$$ && fail=1

# bare 面: 過不足
jq -r '.pluginOnlyHomes[]? | [.home, (.plugins | join(" "))] | @tsv' "$MAPPING" | while IFS=$'\t' read -r home plugins; do
  home=$(expand "$home")
  [ -z "$ONLY_HOME" ] || [ "$home" = "$ONLY_HOME" ] || continue
  [ -d "$home" ] || { echo "skip  $home (no dir)"; continue; }
  expected=$(printf '%s\n' $plugins | sort -u)
  actual=$(installed "$home")
  report "$home" "$(comm -23 <(printf '%s\n' "$expected") <(printf '%s\n' "$actual"))" "$(comm -13 <(printf '%s\n' "$expected") <(printf '%s\n' "$actual"))"
done | tee -a /tmp/check-plugins.$$
grep -q '^DRIFT' /tmp/check-plugins.$$ && fail=1
rm -f /tmp/check-plugins.$$

if [ "$fail" != 0 ]; then
  echo "→ rules 面の不足は setup.sh で入れる。bare 面は just setup-bare (ccmsg の install/update) と claude plugin uninstall で合わせる" >&2
  exit 1
fi
