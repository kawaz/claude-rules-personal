#!/usr/bin/env bash
# hooks/vcs-guide.sh の振る舞いテスト。
# 一時ディレクトリに colocate / bare / git 専用 / 許可リスト外のリポを作り、
# 擬似 hook 入力 JSON を流して additionalContext の有無と案内先を assert する。
set -uo pipefail

HOOK=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/vcs-guide.sh
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export XDG_STATE_HOME="$TMP/state"

pass=0
fail=0

# 許可リスト (/github.com/kawaz/) を通るパスに置く
OWN="$TMP/github.com/kawaz"
OTHER="$TMP/github.com/other-org"
mkdir -p "$OWN/colocate/.jj" && git init -q "$OWN/colocate"
mkdir -p "$OWN/bare/.jj"
mkdir -p "$OWN/gitonly" && git init -q "$OWN/gitonly"
mkdir -p "$OTHER/x/.jj" && git init -q "$OTHER/x"
mkdir -p "$OTHER/gitonly" && git init -q "$OTHER/gitonly"

run() { # run <cwd> <command> [session_id]
  jq -n --arg c "$2" --arg d "$1" --arg s "${3:-sess-default}" \
    '{session_id:$s, cwd:$d, tool_input:{command:$c}}' | bash "$HOOK"
}

assert_contains() { # assert_contains <name> <output> <needle>
  if printf '%s' "$2" | grep -qF -- "$3"; then
    echo "ok   - $1"
    pass=$((pass + 1))
  else
    echo "FAIL - $1 (期待: '$3' を含む / 実際: '${2:-<空>}')"
    fail=$((fail + 1))
  fi
}

assert_not_contains() { # assert_not_contains <name> <output> <needle>
  if printf '%s' "$2" | grep -qF -- "$3"; then
    echo "FAIL - $1 (期待: '$3' を含まない / 実際: $2)"
    fail=$((fail + 1))
  else
    echo "ok   - $1"
    pass=$((pass + 1))
  fi
}

assert_empty() { # assert_empty <name> <output>
  if [ -z "$2" ]; then
    echo "ok   - $1"
    pass=$((pass + 1))
  else
    echo "FAIL - $1 (期待: 無案内 / 実際: $2)"
    fail=$((fail + 1))
  fi
}

# --- 許可リスト -------------------------------------------------------------
assert_empty "許可リスト外の cwd は無案内" \
  "$(run "$OTHER/x" "jj commit -m x f" s1)"
assert_empty "許可リスト外へ cd する command は無案内" \
  "$(run "$OWN/colocate" "(cd $OTHER/x && jj commit -m x f)" s2)"
assert_contains "許可リスト外の cwd でも cd 先が許可リストなら案内" \
  "$(run "$OTHER/x" "(cd $OWN/colocate && jj commit -m x f)" s3)" \
  "jj-colocate-setup.md (colocate 新標準の手順)"

# --- cd 先の解決 ------------------------------------------------------------
assert_empty "相対パスへの cd は判定不能なので無案内" \
  "$(run "$OWN/colocate" "cd ../bare && jj commit -m x f" s4)"
assert_empty "解決できない変数展開への cd は無案内" \
  "$(run "$OWN/colocate" 'cd "$REPO/main" && jj commit -m x f' s5)"
assert_contains "\$HOME 始まりの cd は展開して判定" \
  "$(HOME="$OWN" bash -c 'jq -n --arg c "cd \$HOME/gitonly && git commit -m x f" --arg d "$1" --arg s s6 "{session_id:\$s, cwd:\$d, tool_input:{command:\$c}}" | bash "$2"' _ "$OTHER/x" "$HOOK")" \
  "git-worktree-setup.md"
assert_contains "~ 始まりの cd は展開して判定" \
  "$(HOME="$OWN" bash -c 'jq -n --arg c "(cd ~/bare && jj commit -m x f)" --arg d "$1" --arg s s7 "{session_id:\$s, cwd:\$d, tool_input:{command:\$c}}" | bash "$2"' _ "$OTHER/x" "$HOOK")" \
  "jj-bare-workspace-setup.md"
assert_contains "最後の cd 先で構成を判定する" \
  "$(run "$OWN/gitonly" "cd $OWN/gitonly && cd $OWN/colocate && jj commit -m x f" s8)" \
  "jj-colocate-setup.md (colocate 新標準の手順)"

# --- git init ---------------------------------------------------------------
assert_contains "git init は colocate 新規作成へ誘導" \
  "$(run "$OWN/gitonly" "git init" s9)" \
  "jj-colocate-setup.md の「新規リポジトリ作成」節"

# --- git status -------------------------------------------------------------
assert_contains "git 専用リポの git status は colocate 化を案内" \
  "$(run "$OWN/gitonly" "git status" s10)" \
  "jj 管理されていません"
assert_contains "git 専用リポの git status は移行節を案内" \
  "$(run "$OWN/gitonly" "git status" s11)" \
  "jj-colocate-setup.md"
assert_empty "jj 管理下 (colocate) の git status は無案内" \
  "$(run "$OWN/colocate" "git status" s12)"
assert_empty "許可リスト外の git 専用リポの git status は無案内" \
  "$(run "$OTHER/gitonly" "git status" s12b)"

# --- 読み取り系は無案内 -----------------------------------------------------
assert_empty "jj log は無案内" "$(run "$OWN/colocate" "jj log -r @" s13)"
assert_empty "git diff は無案内" "$(run "$OWN/colocate" "git diff" s14)"

# --- 構成別の通常案内 -------------------------------------------------------
assert_contains "colocate は colocate setup を案内" \
  "$(run "$OWN/colocate" "jj commit -m x f" s15)" \
  "jj-colocate-setup.md (colocate 新標準の手順)"
assert_contains "git 専用は worktree 手順を案内" \
  "$(run "$OWN/gitonly" "git commit -m x f" s16)" \
  "git-worktree-setup.md"

# --- 旧方式 (bare) の移行案内 -----------------------------------------------
out=$(run "$OWN/bare" "jj commit -m x f" s17)
assert_contains "bare + jj は旧方式手順を案内" "$out" "jj-bare-workspace-setup.md"
assert_contains "bare + jj は移行節を案内" "$out" "「移行 (旧方式リポの入れ替え)」節"
assert_contains "bare へ cd する command も移行案内する" \
  "$(run "$OWN/gitonly" "(cd $OWN/bare && jj commit -m x f)" s18)" \
  "「移行 (旧方式リポの入れ替え)」節"
assert_not_contains "bare で git コマンドのみなら移行案内をしない" \
  "$(run "$OWN/bare" "git commit -m x f" s19)" \
  "「移行 (旧方式リポの入れ替え)」節"

# --- dedup ------------------------------------------------------------------
first=$(run "$OWN/colocate" "jj commit -m x f" dedup-sess)
second=$(run "$OWN/colocate" "jj commit -m y f" dedup-sess)
assert_contains "dedup: 同一セッション同一リポの 1 回目は案内" "$first" "jj-colocate-setup.md"
assert_empty "dedup: 同一セッション同一リポの 2 回目は無案内" "$second"
assert_contains "dedup: 種別が違えば同じリポでも案内する" \
  "$(run "$OWN/colocate" "git init" dedup-sess)" \
  "新規リポジトリ作成"

echo
echo "passed: $pass, failed: $fail"
[ "$fail" -eq 0 ]
