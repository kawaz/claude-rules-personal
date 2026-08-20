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

# PATH 上の `git` は jj-worktree shim (~/.cache/jj-worktree/bin/git) のことがある。
# shim 経由だと `git worktree add` が **jj workspace** を作ってしまい (.jj のみで .git
# を持たない)、isolation:"worktree" の git identity 検証で拒否される。--porcelain も
# 非対応 (`error: list takes no options`) で冪等チェックが黙って効かなくなる。
# 素の git に委譲させるため、本 hook の git 呼び出しは全てこの wrapper を通す。
git_() { JJ_WORKTREE_DISABLED=1 git "$@"; }

payload=$(cat)
cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty')
name=$(printf '%s' "$payload" | jq -r '.name // empty')

[ -n "$cwd" ] && [ -d "$cwd" ] || exit 1
[ -n "$name" ] || exit 1
case "$name" in */*|..*) exit 1 ;; esac   # パス区切りを含む name は弾く

fallback="$cwd/.claude/worktrees/$name"

# 規約パスを適用するのは **実測済みの構成に完全一致する場合だけ**。
# 1 つでも欠けたら既定の .claude/worktrees へ回す (未検証の構成でどう転ぶか
# 予想がつかないため、規約パス適用を発動させない)。
#
#   a. $cwd/.git がディレクトリ = colocate の実体
#      (git worktree の中から発火した場合は .git がファイルなので自然に除外される)
#   b. $cwd/.jj がディレクトリ = jj colocate 運用
#   c. 親の .git が存在しないか通常ファイル (= ガードファイル)
#      親に本物の .git ディレクトリがある = 親が別リポなので、そこに worktree を
#      撒かないため必ず塞ぐ
#   d. 親ディレクトリ名が remote のリポ名と一致 (= {repo}/{workspace} レイアウト)
parent=$(dirname "$cwd")
is_convention_layout() {
  [ -d "$cwd/.git" ] || return 1
  [ -d "$cwd/.jj" ] || return 1
  [ ! -e "$parent/.git" ] || [ -f "$parent/.git" ] || return 1
  local origin repo
  origin=$(git_ -C "$cwd" remote get-url origin 2>/dev/null) || return 1
  [ -n "$origin" ] || return 1
  repo=$(basename "${origin%.git}")
  [ "$(basename "$parent")" = "$repo" ]
}

if is_convention_layout; then
  target="$parent/$name"
else
  target="$fallback"
fi

# 既に同じ場所が worktree として登録済みなら、それを返して終わり (冪等)。
# 前回の失敗で作りかけが残っていても、ここで拾える。
if git_ -C "$cwd" worktree list --porcelain 2>/dev/null |
     grep -qxF "worktree $target"; then
  printf '%s\n' "$target"
  exit 0
fi

branch="worktree-$name"
add() {
  local path=$1
  mkdir -p "$(dirname "$path")" || return 1
  if git_ -C "$cwd" show-ref --verify --quiet "refs/heads/$branch"; then
    git_ -C "$cwd" worktree add "$path" "$branch" >/dev/null 2>&1
  else
    git_ -C "$cwd" worktree add -b "$branch" "$path" >/dev/null 2>&1
  fi || return 1
  # 作れたつもりでも git worktree になっていなければ失敗扱いにする。
  # isolation:"worktree" は .git を持たないディレクトリを拒否するので、
  # ここで弾かないと worktree 作成そのものが落ちる。
  [ -e "$path/.git" ]
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
