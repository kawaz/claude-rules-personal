# jj colocate + 親ガード方式のセットアップと運用 (新標準)

適用: **`{repo}/main/.git` と `{repo}/main/.jj` が両方ディレクトリ** (= colocate) のリポ。`{repo}/main/` を起点にする親ガード方式のレイアウトは `~/.local/share/repos/` 配下のリポだけの規約で、それ以外の場所 (とりあえずバージョン管理したい適当なディレクトリ等) は main/ も親ガードも要らず、その場で `git init && git commit -m "Initial empty commit" --allow-empty && jj git init --colocate` を行う。**`git init` 直後に commit を挟まず `jj git init` すると `main` bookmark が作られない** (後から立て直す手間が大きい) ので、順番だけは守る。workspace 名はどの順でも `default` になるので、repos 配下では `jj workspace rename main` でディレクトリ名と揃える。リポ直下に `.jj` があり `main/.git` が無い場合は旧方式なので reference の `vcs/jj-bare-workspace-setup` に従う (既存リポを本方式へ移す手順は下記「移行」)。

## レイアウト

```
{repo}/                # 例: ~/.local/share/repos/github.com/kawaz/foo/
  .git                 # ガード (通常ファイル。内容は「ガードである」旨の説明文)
  .jj/                 # ガード (ディレクトリ。README.md で説明)
  main/                # 実体 (git + jj colocate)。main/.git も main/.jj もディレクトリ
  <name>/              # 恒久 workspace (jj workspace add で作る。命名は従来規約のまま)
  agent-<id>/          # isolation:"worktree" が hook 経由で作る使い捨て git worktree
```

- ガードの形は**厳密に**: `.git` は**ファイル**でないと git が素通りし、`.jj` は**ディレクトリ**でないと jj が素通りする (逆にすると両方ガードにならない)。効果は実測済み: repo 直下で git は `fatal: invalid gitfile format`、jj は `The repository appears broken or inaccessible` で双方停止し、main/ 内は無傷
- `agent-*` prefix = サブエージェントの使い捨て作業場 (WorktreeCreate hook が作る)。掃除は自動化しない (溜まったら手で消す)。`{repo}/agent-*` で機械判定できる

## 新規リポジトリ作成

```bash
mkdir -p "$REPO_PARENT/main" && cd "$REPO_PARENT/main"
# commit を挟んでから jj git init (main bookmark が立つ)、workspace 名は default のままなので rename まで 1 行で
git init && git commit -m "Initial empty commit" --allow-empty && jj git init && jj workspace rename main
cd .. && echo "guard: 上位への .git 探索を止める (実体は main/)" > .git && mkdir .jj
echo "guard: 上位への .jj 探索を止める (実体は main/)" > .jj/README.md
```

続けて VS Code の workspace ファイルを作る。名前は `{repo}@{ws}.local.code-workspace` (グローバル gitignore の `*.local.*` に載るので commit されない。リポに追跡させる workspace ファイルは作らない):

```jsonc
// {repo}@{ws}.local.code-workspace (main/ 直下)
{
  "folders": [
    { "name": "{repo}@{ws}", "path": "../../../{owner}/{repo}/{ws}" }
  ],
  "settings": {
    "prettier.enable": false
  }
}
```

自分のリポも `.` でなく `../../../{owner}/{repo}/{ws}` (main/ から見て repo → owner → github.com の 3 段上) で書く (workspace ファイルごと別リポにコピーした時に name と path の対応が崩れないため)。関連リポや設定ディレクトリを一緒に開きたい時は `folders` に同じ形で足す (`$HOME` 配下の設定は絶対パスでよい。追跡されないファイルなので sanitize の対象外)。

## 既存リポジトリの clone

```bash
mkdir -p "$REPO_PARENT" && git clone <url> "$REPO_PARENT/main"
cd "$REPO_PARENT/main"
# 既定ブランチは main とは限らない (master / develop 等) ので origin/HEAD から取る。workspace 名はディレクトリに合わせて main 固定
default_branch=$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||')
jj git init && jj workspace rename main && jj bookmark track "$default_branch" --remote=origin   # rename と track を落とさない (下記)
cd .. && echo "guard: 上位への .git 探索を止める (実体は main/)" > .git && mkdir .jj
echo "guard: 上位への .jj 探索を止める (実体は main/)" > .jj/README.md
```

`jj bookmark track main --remote=origin` が必要: clone → `jj git init` 直後は main@origin が untracked (jj 自身が hint を出す)。track するとローカル main が立ち @git / @origin と一致する。新規作成手順では main が自動で立つのと挙動が違う。

## 移行 (旧方式リポの入れ替え)

旧方式 (bare + jj workspace) のリポは**削除して clone し直す** (in-place 変換はしない)。

1. [ ] **remote (origin url) があることを確認** — `git --git-dir={repo}/.git config remote.origin.url`。無いローカル専用リポは clone し直せないので本手順の対象外 (実測: 2026-08-21 の一括移行で url 空のまま退避まで進み、手動復元が要った)
2. [ ] 全 workspace で未 push の変更・bookmark が無いか確認 (`jj log -r 'remote_bookmarks()..'` が空、`jj status` が clean)
3. [ ] 未 push があれば push するか退避してから進む
4. [ ] リポディレクトリごと `<repo>.old-bare-<date>` へ mv 退避 (削除しない。削除は kawaz 判断)
5. [ ] 上の「既存リポジトリの clone」手順で作り直す (track main を忘れない)
6. [ ] 動作確認: repo 直下で `git status` と `jj st` が**双方エラーで止まる**こと、main/ 内で双方動くこと

## 作業場所の使い分け (最重要)

| 作業場所 | 作り方 | 中で使える VCS |
|---|---|---|
| `main/` | (実体) | **jj を使う** (git も動くが統合は jj で) |
| 恒久 workspace `<name>/` | `main/` 内から `jj workspace add ../<name>` | **jj** (自分の workspace を正しく掴む。実測済み) |
| 使い捨て `agent-<id>/` | WorktreeCreate hook (自動) | **git のみ** |
| 手動の git worktree | `git worktree add ../<name> -b <branch>` | **git のみ** |

- **git worktree の中で jj を叩かない**: git worktree は `.jj` を持たないため、jj はリポを見つけられずエラー停止する (親ガードのおかげで main 誤爆はしないが作業不能)。worktree 内の作業・コミットは git で行う
- **main への統合は jj で行う** (`jj bookmark set main -r <rev>` 等)。jj 操作後の main/ の git HEAD は detached になるため (実測済み)、`git merge` は使えない。git worktree で作った branch のコミットは jj 側から change として見えるので、jj で main に取り込む
- colocate なので jj bookmark と git branch は自動同期する (`jj bookmark set main` → `git branch` の main も同じ commit を指す。実測済み)

## bookmark / PR / コミット操作 / 署名

VCS 操作の運用は旧方式と共通:

- **コミットは必ずパス指定**: `jj commit -m "msg" <files...>` (パスなしは他セッションの変更を巻き込む禁則。push-workflow rule 参照)
- bookmark は自動移動しないので push 前に `jj bookmark set <branch> -r @`
- bookmark 命名: `feature/` `refactor/` `fix/` `docs/` プレフィックス
- PR 用の恒久 workspace は `jj workspace add ../{PR番号}-{branch}` (main/ 内から)
- 署名は `signing.behavior = "drop"` + `git.sign-on-push = true` (push 時にまとめて署名)
- コミット操作の詳細 (squash / split / 復旧) は reference の `vcs/jj-commit-basics` / `vcs/jj-restructure` / `vcs/jj-recovery`
