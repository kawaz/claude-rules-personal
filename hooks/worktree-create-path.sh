#!/usr/bin/env bash
# WorktreeCreate hook — worktree を kawaz のパス規約 ({repo}/{name}/) に作る。
#
# 契約 (claude-plugin-reference hooks.md §6.2、実機検証済: v2.1.237):
#   - stdin に {"cwd": "<元リポの絶対パス>", "name": "agent-<id>", ...} が来る
#   - stdout に「作成済みディレクトリの絶対パス」を生パスで echo する (JSON にしない)
#   - hook が先にディレクトリを作る。パスを返さないと既定動作に fallback せず
#     worktree 作成自体がエラーになる
#   - 失敗しても副作用は巻き戻らないので冪等に作る
#
# したがって本 script は **どの経路でも必ずパスを 1 つ返す**。規約パスが使えない状況
# (レイアウトが違う / git worktree add が失敗) では既定の .claude/worktrees/<name> に
# 作って返し、worktree 作成自体は止めない。
set -uo pipefail

payload=$(cat)
cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty')
name=$(printf '%s' "$payload" | jq -r '.name // empty')

[ -n "$cwd" ] && [ -d "$cwd" ] || exit 1
[ -n "$name" ] || exit 1
case "$name" in */*|..*) exit 1 ;; esac   # パス区切りを含む name は弾く

fallback="$cwd/.claude/worktrees/$name"

# 規約レイアウトの判定: cwd が {repo}/{workspace} の形か。
# 親ディレクトリ名が remote のリポ名と一致するときだけ sibling 配置にする
# (= 素の clone `~/src/foo` を `~/src/<name>` に撒き散らさないため)。
target=""
parent=$(dirname "$cwd")
origin=$(git -C "$cwd" remote get-url origin 2>/dev/null || true)
if [ -n "$origin" ]; then
  repo=$(basename "${origin%.git}")
  [ "$(basename "$parent")" = "$repo" ] && target="$parent/$name"
fi
[ -n "$target" ] || target="$fallback"

# 既に同じ場所が worktree として登録済みなら、それを返して終わり (冪等)。
# 前回の失敗で作りかけが残っていても、ここで拾える。
if git -C "$cwd" worktree list --porcelain 2>/dev/null |
     grep -qxF "worktree $target"; then
  printf '%s\n' "$target"
  exit 0
fi

branch="worktree-$name"
add() {
  local path=$1
  mkdir -p "$(dirname "$path")" || return 1
  if git -C "$cwd" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$cwd" worktree add "$path" "$branch" >/dev/null 2>&1
  else
    git -C "$cwd" worktree add -b "$branch" "$path" >/dev/null 2>&1
  fi
}

if add "$target"; then
  printf '%s\n' "$target"
  exit 0
fi

# 規約パスで失敗した場合のみ既定の場所へ退避 (= worktree 作成を止めない)
if [ "$target" != "$fallback" ] && add "$fallback"; then
  echo "worktree-create-path: 規約パス ($target) に作れなかったので既定の場所に作成しました" >&2
  printf '%s\n' "$fallback"
  exit 0
fi

echo "worktree-create-path: worktree を作成できませんでした (target=$target)" >&2
exit 1
