#!/bin/bash
# PreToolUse(Bash) hook: jj / git コマンドの実行を検知して、対応する skill の
# invoke を additionalContext で促す。
#
# 目的 — skill の `description` は全セッションの context に常時載る。jj-tips /
# jj-workflow のような「特定コマンドを打つ時だけ要る手順書」は、description を
# 意味判断の材料として太らせる代わりに、本 hook が発火経路を担う。これで jj/git を
# 使わないセッションでは 1 字も context を食わない。
#
# frontmatter に「コマンド実行を trigger にする」フィールドは存在しない
# (`paths` はファイル glob のみ) ため、hook がこの経路の唯一の実装手段。
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

# jj 管理か git 専用かで案内先が変わる。jj workspace は `.jj` が file の
# ことがある (secondary workspace) ので -e で判定する。
if [ -e "$repo_root/.jj" ]; then
  skills="personal-jj-workflow (workspace / bookmark / PR / push 手順), personal-jj-tips (コミット操作・組み替え・復旧)"
else
  skills="personal-git-worktree-workflow (worktree / PR 作業手順)"
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

jq -n --arg skills "$skills" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: ("このリポで VCS コマンドを実行しようとしています。手順書 skill が未ロードなら Skill tool で invoke してください: " + $skills + "。既にロード済み、または単純な状態確認 (status / log / diff) だけなら不要です。")
  }
}' 2>/dev/null || exit 0
exit 0
