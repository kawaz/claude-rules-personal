#!/bin/bash
# PreToolUse(Bash) hook: jj / git コマンドの実行を検知して、対応する参照知識の
# Read を additionalContext で促す。
#
# 目的 — VCS の手順書は「特定コマンドを打つ時だけ要る」ので、常時 context に
# 載せる代わりに本 hook が発火経路を担う。これで jj/git を使わないセッションでは
# 1 字も context を食わない。
#
# ブロックはしない (exit 0)。案内は 1 セッション 1 回 (リポごと)。
#
# NOTE: `set -e` は使わない。hook 自体の不具合 (jq 不在、JSON 不正等) で
# ユーザの作業を止めないこと。

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$command" ] || exit 0

# 行頭 / `&&` / `;` / `||` / `|` 直後の jj / git のみ対象。コミットメッセージや
# heredoc 内の文字列リテラルを誤検知しない。
printf '%s' "$command" |
  grep -qE '(^|&&|;|\|\|?)[[:space:]]*(jj|git)[[:space:]]' || exit 0

# 状態確認だけのコマンドは手順書が要らない (= 案内はノイズ)。ワーキングコピーや
# リモートを変更しうるサブコマンドが 1 つでも含まれる時だけ案内する。
printf '%s' "$command" |
  grep -qE '(^|&&|;|\|\|?)[[:space:]]*(jj|git)([[:space:]]+[^[:space:]]+)*[[:space:]]+(commit|split|squash|rebase|abandon|new|edit|describe|restore|bookmark|push|fetch|pull|merge|add|rm|mv|reset|checkout|switch|branch|tag|stash|cherry-pick|revert|duplicate|workspace|op|clone|init|apply|am)\b' || exit 0

session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || cwd=$PWD

# リポルートを求める (jj / git どちらでも)。見つからなければ cwd で代替。
repo_root=$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$repo_root" ]; then
  repo_root=$cwd
fi

ref_dir="$HOME/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/vcs"

# 構成で案内先が変わる。
#   colocate (新標準): repo_root に .git と .jj が両方ディレクトリ
#   bare + jj workspace (旧): .jj が存在 (secondary workspace では file のことがある)
#   git 専用: それ以外
if [ -d "$repo_root/.git" ] && [ -d "$repo_root/.jj" ]; then
  refs="$ref_dir/jj-colocate-setup.md (colocate 新標準の手順), $ref_dir/jj-commit-basics.md (コミット操作), $ref_dir/jj-restructure.md (組み替え), $ref_dir/jj-recovery.md (復旧)"
elif [ -e "$repo_root/.jj" ]; then
  refs="$ref_dir/jj-bare-workspace-setup.md (bare + jj workspace 旧方式の手順), $ref_dir/jj-commit-basics.md (コミット操作), $ref_dir/jj-restructure.md (組み替え), $ref_dir/jj-recovery.md (復旧)"
else
  refs="$ref_dir/git-worktree-setup.md (worktree / PR 作業手順)"
fi

# 1 セッション 1 リポにつき 1 回だけ案内する。
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-rules-personal/vcs-skill-autoload"
if [ -n "$session_id" ]; then
  # repo_root をファイル名に使えるよう平坦化
  repo_key=$(printf '%s' "$repo_root" | tr '/' '_')
  marker="$state_dir/${session_id}${repo_key}"
  if [ -e "$marker" ]; then
    exit 0
  fi
  mkdir -p "$state_dir" 2>/dev/null && : >"$marker" 2>/dev/null
fi

jq -n --arg refs "$refs" --arg idx "$ref_dir/_index.md" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: ("このリポで VCS コマンドを実行しようとしています。手順書が未ロードなら次を Read してください: " + $refs + "。他の場面 (rebase オプション、越境 push 等) は " + $idx + " から引けます。既に読み込み済み、または単純な状態確認 (status / log / diff) だけなら不要です。")
  }
}' 2>/dev/null || exit 0
exit 0
