#!/bin/bash
# PreToolUse(Bash) hook: jj / git コマンドの実行を検知して、対応する参照知識の
# Read を additionalContext で促す。
#
# 目的 — VCS の手順書は「特定コマンドを打つ時だけ要る」ので、常時 context に
# 載せる代わりに本 hook が発火経路を担う。これで jj/git を使わないセッションでは
# 1 字も context を食わない。
#
# ブロックはしない (exit 0)。案内は 1 セッション 1 リポ 1 種別につき 1 回。
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

session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || cwd=$PWD

# 判定対象パス — command が `cd <path>` を含むならその最後の cd 先 (越境実行の
# 対象がそこなので)、無ければセッションの cwd。
target=$cwd
if printf '%s' "$command" | grep -qE '(^|&&|;|\|\|?|\()[[:space:]]*cd[[:space:]]'; then
  target=$(printf '%s' "$command" |
    grep -oE '(^|&&|;|\|\|?|\()[[:space:]]*cd[[:space:]]+[^;&|)]+' |
    tail -1 | sed -E 's/.*cd[[:space:]]+//; s/[[:space:]]+$//; s/^"//; s/"$//; s/^'"'"'//; s/'"'"'$//')
  case $target in
  '~' | '~/'*) target="$HOME${target#\~}" ;;
  '$HOME' | '$HOME/'*) target="$HOME${target#\$HOME}" ;;
  /*) ;;
  # 相対パスや解決できない変数展開は判定不能なので案内しない。
  *) exit 0 ;;
  esac
fi

# リポルートを求める (jj / git どちらでも)。見つからなければ対象パスで代替。
repo_root=$(cd "$target" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$repo_root" ]; then
  repo_root=$target
fi

ref_dir="$HOME/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/vcs"

# 構成:
#   colocate (新標準): repo_root に .git と .jj が両方ディレクトリ
#   bare + jj workspace (旧): .jj が存在 (secondary workspace では file のことがある)
#   git 専用: それ以外
if [ -d "$repo_root/.git" ] && [ -d "$repo_root/.jj" ]; then
  layout=colocate
elif [ -e "$repo_root/.jj" ]; then
  layout=bare
else
  layout=git-only
fi

has() { printf '%s' "$command" | grep -qE "$1"; }

# 変更系サブコマンド (状態確認だけなら手順書は要らない = 案内はノイズ)
changing='(^|&&|;|\|\|?)[[:space:]]*(jj|git)([[:space:]]+[^[:space:]]+)*[[:space:]]+(commit|split|squash|rebase|abandon|new|edit|describe|restore|bookmark|push|fetch|pull|merge|add|rm|mv|reset|checkout|switch|branch|tag|stash|cherry-pick|revert|duplicate|workspace|op|clone|init|apply|am)\b'
git_init='(^|&&|;|\|\|?)[[:space:]]*git([[:space:]]+[^[:space:]]+)*[[:space:]]+init\b'
git_status='(^|&&|;|\|\|?)[[:space:]]*git([[:space:]]+[^[:space:]]+)*[[:space:]]+status\b'
jj_run='(^|&&|;|\|\|?)[[:space:]]*jj[[:space:]]'

if has "$git_init"; then
  kind=git-init
elif has "$changing"; then
  if has "$jj_run" && [ "$layout" = bare ]; then
    kind=migrate
  else
    kind=normal
  fi
elif has "$git_status" && [ "$layout" != git-only ]; then
  kind=git-status
else
  exit 0
fi

# 手順書の案内は個人面のリポだけ (許可リスト)。他の面のリポは別ワークフローで
# 運用しており、本 hook の案内は当てはまらない。
# 例外は git-status — jj 管理下なら場所を問わず jj を使うべきなので常に案内する。
if [ "$kind" != git-status ]; then
  printf '%s' "$target" |
    grep -qE '/github\.com/kawaz/|/\.dotfiles/|/zunsystem/' || exit 0
fi

case $kind in
git-init)
  message="新規リポジトリは jj colocate + 親ガード方式で始めます。$ref_dir/jj-colocate-setup.md の「新規リポジトリ作成」節 (clone なら「既存リポジトリの clone」節) を Read して、その手順で作成してください。"
  ;;
git-status)
  message="jj 管理下なので \`git status\` ではなく \`jj status\` を使ってください (コミット操作は $ref_dir/jj-commit-basics.md を参照)。"
  ;;
migrate)
  message="このリポは旧方式 (git bare + jj workspace) です。手順書が未ロードなら次を Read してください: $ref_dir/jj-bare-workspace-setup.md (旧方式の手順), $ref_dir/jj-commit-basics.md (コミット操作), $ref_dir/jj-restructure.md (組み替え), $ref_dir/jj-recovery.md (復旧)。あわせて $ref_dir/jj-colocate-setup.md の「移行 (旧方式リポの入れ替え)」節を読み、colocate 方式への移行を検討してください。"
  ;;
*)
  case $layout in
  colocate)
    refs="$ref_dir/jj-colocate-setup.md (colocate 新標準の手順), $ref_dir/jj-commit-basics.md (コミット操作), $ref_dir/jj-restructure.md (組み替え), $ref_dir/jj-recovery.md (復旧)"
    ;;
  bare)
    refs="$ref_dir/jj-bare-workspace-setup.md (bare + jj workspace 旧方式の手順), $ref_dir/jj-commit-basics.md (コミット操作), $ref_dir/jj-restructure.md (組み替え), $ref_dir/jj-recovery.md (復旧)"
    ;;
  *)
    refs="$ref_dir/git-worktree-setup.md (worktree / PR 作業手順)"
    ;;
  esac
  message="このリポで VCS コマンドを実行しようとしています。手順書が未ロードなら次を Read してください: ${refs}。他の場面 (rebase オプション、越境 push 等) は $ref_dir/_index.md から引けます。既に読み込み済み、または単純な状態確認 (status / log / diff) だけなら不要です。"
  ;;
esac

# 1 セッション 1 リポ 1 種別につき 1 回だけ案内する。
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-rules-personal/vcs-guide"
if [ -n "$session_id" ]; then
  # repo_root をファイル名に使えるよう平坦化
  repo_key=$(printf '%s' "$repo_root" | tr '/' '_')
  marker="$state_dir/${session_id}${repo_key}.${kind}"
  if [ -e "$marker" ]; then
    exit 0
  fi
  mkdir -p "$state_dir" 2>/dev/null && : >"$marker" 2>/dev/null
fi

jq -n --arg message "$message" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $message
  }
}' 2>/dev/null || exit 0
exit 0
