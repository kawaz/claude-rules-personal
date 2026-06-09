---
name: jj-workflow
description: jj 管理リポジトリ (= `.jj/` ディレクトリが存在する) での workflow 手順書。git bare + jj workspace 方式のセットアップ、workspace 作成/削除、bookmark 命名、PR 作成 (新規 / wip 昇格)、push 後の手順、コミット操作 (`jj commit` 一発フロー)、署名運用 (`signing.behavior=drop` + `git.sign-on-push`)、bookmark 種類とデータ保護、トラブルシュート ("stale info" / tag が見えない)、jj-worktree / jj-guard 連携。`jj <command>` を実行する場面、jj リポでの新規 PR 作成、workspace 追加、push エラー対処など jj 固有の手順が必要なときに使う。git 管理リポ (`.git` のみ) では使わない。
---

# jj ワークフロー

`.jj` が存在するリポジトリで適用。それ以外は git-workflow.md（git bare + worktree 方式）に従う。

## 用語（git → jj）

| git 用語 | jj 用語 |
|---|---|
| branch | bookmark |
| worktree | workspace |

方式名: git bare + worktree 方式（git-workflow.md）/ git bare + jj workspace 方式（本ファイル）

## ディレクトリ構成

### 1. git bare + jj workspace 方式（新規、自分管理リポジトリ）

適用: `github.com/{kawaz,kawaz123,zunsystem}/*` の新規リポジトリ

```
~/.local/share/repos/{host}/{org-user}/{repo}/
  .git/          # git bare repository
  .jj/           # jj 実体（default@ workspace）
  ./             # default@ workspace
  {main}/        # メインワークスペース
  {workspace}/   # 追加ワークスペース
  .envrc         # (任意) direnv でworkspaceを横断した環境変数管理
```

repo 直下に `.git`(bare) + `.jj` を配置。利点:
- 上位ディレクトリへの `.git` / `.jj` の探索を打ち止め（上位のリポジトリが存在した場合の誤操作を防ぐ）
- repo 直下から直接 `jj workspace add` できる
- git は bare なので repo 直下で作業ツリーとしては機能しない

## セットアップ

`jj git init` 直後に `jj new -r 'root()'` で default WS の working copy を空にする。
default WS の `.jj` は repo 直下に残り、上位ディレクトリの `.jj` や `.git` への誤操作を防ぐガードとして機能する。削除してはならない。

### git bare + jj workspace 方式（新規リポジトリ作成）

```bash
(cd "$REPO_PARENT" && git init --bare .git && jj git init --git-repo .git && jj commit -m "Initial empty commit" && jj workspace add main)
```

### git bare + jj workspace 方式（既存リポジトリの clone）

```bash
(cd "$REPO_PARENT" && git clone --bare <url> .git && git --git-dir=.git config --add remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' && git --git-dir=.git config remote.origin.tagOpt --tags && jj git init --git-repo .git && jj workspace add {main} && jj new -r 'root()')
```

`tagOpt --tags` を入れる理由: `jj git fetch` は内部で git の fetch refspec / tagOpt を読む。標準の `+refs/heads/*:...` だけだと **tag が自動取得されない** (jj 0.41 で確認、jj-tips skill のトラブルシュート節参照)。bare git に tagOpt を設定しておけば `jj git fetch` 1 発で tag も来る。

### git bare + jj workspace 方式（fork して clone）

他者リポジトリを fork してからセットアップする場合:

```bash
gh repo fork {owner}/{repo} --clone=false
(cd "$REPO_PARENT" && git clone --bare https://github.com/{user}/{repo}.git .git && git --git-dir=.git config --add remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' && git --git-dir=.git config remote.origin.tagOpt --tags && jj git init --git-repo .git && jj new -r 'root()' && jj workspace add {main})
jj -R "$REPO_PARENT/{main}" git remote add upstream https://github.com/{owner}/{repo}.git
jj -R "$REPO_PARENT/{main}" git fetch --remote upstream
```

### colocate 方式（使用しない）

```bash
jj git clone <url> "$REPO_PARENT/{main-branch}"
```

jj 側の制限として --git-repo と --colocate は共存不可の為、現在のリポジトリ管理方針と合わないため使用しない。

## ワークスペース

### 作成

git bare + jj workspace 方式:
```bash
# repo 直下（default workspace）から
jj workspace add {name}
# 子ワークスペース内から
jj workspace add ../{name}
```

命名: `{pr_iss_no}-feature-xxx`, `review1234-xxx`, `wip-xxx`

作成後フルパスを省略せず報告。

### 削除

```bash
jj workspace forget {name}
rm -rf "$REPO_PARENT/{name}"
```

## bookmark

命名: `feature/`, `refactor/`, `fix/`, `docs/` プレフィックス。

bookmark は自動移動しない。push 前に明示的に設定:

```bash
jj bookmark set feature/xxx -r @
```

## PR

### 新規PR

メインワークスペースで実行。PR番号を先に取得してワークスペース名に使う:

```bash
# 現在の位置にタグを付ける（後で戻れるようにするため）
cur_tag="cur_tag.$(date +%s).$$"
jj tag set "$cur_tag"
# PR番号取得用の空コミットを作る
jj git fetch
jj new main@origin -m "chore: PR番号取得用空コミット"
jj bookmark set {branch}
jj git push --bookmark {branch}
gh pr create --head {branch} --title "..." --body "..."
# PR番号でワークスペース作成
jj workspace add ../{PR番号}-{branch}
# @ を元コミットに戻す
jj new main@origin
jj tag delete "$cur_tag"
```

### wip → PR昇格

```bash
jj bookmark set {branch} -r @
jj git push
gh pr create --head {branch} --title "..." --body "..."
# PR番号確定後にディレクトリ名変更
mv "$REPO_PARENT/wip-xxx" "$REPO_PARENT/{PR番号}-{branch}"
jj -R "$REPO_PARENT/{PR番号}-{branch}" workspace update-stale
```

move 前に新パス（フルパス）を案内。mv 後だとカレントディレクトリを失い、エージェントが稼働できなくなるため。

### push後

PRのURL表示。ブランチ名の数字は Issue 番号の可能性があるので `gh pr` で確認。

### 作業後の push

bookmark は自動移動しないため、push 前に更新:

```bash
jj bookmark set {branch} -r @
jj git push
```

## コミット操作

- jj では作業中の状態も常にコミット。uncommitted な状態は存在しない
- **基本フロー: `jj commit -m "メッセージ"` 一発**で「@ を確定 + 子に空 @ を作って前進」が完了する
  - 部分 commit したい時は `jj commit -m "msg" <paths>` (= 指定パスだけ確定、残りは新 @ に retain)
- 修正を親に吸収: `jj squash`
- bookmark を末端に追随させながら部分 commit したい時のみ `jj split -m "msg" <paths>` を選ぶ
  (commit と違って bookmark が @ = remaining 側に前進する。詳細は jj-tips skill の commit vs split 節)

### ユーザーが「コミット」と言った場合

1. 適切な関心事単位でコミットを分割する（chore/feat/refactor/docs 等）
2. 末端 change から順に `jj commit -m "..."` でメッセージを付けながら確定 (@ も自動で空に進む)
3. 最後に @ が空 change のまま (= 次の作業の入れ物として開いている) であることを確認する

## 署名

`signing.behavior = "drop"` + `git.sign-on-push = true` で運用。

- commit/rebase/squash 時は署名しない（1Password 不要）
- `jj git push` 時に未署名の mutable コミットをまとめて署名

## データ保護と bookmark 運用

push していない change はローカルのみ。PC 故障で失われる。

### bookmark の種類と運用

| bookmark | 用途 | force push | 保護方針 |
|---|---|---|---|
| `wip-*` | 個人作業中 | 自由 | 定期的に push |
| PR branch | レビュー用 | 前提（amend/rebase が日常） | 単一オーナー |
| `main` 等 | 共有 | しない | PR 経由のみ |
| 共有 branch | 複数人作業 | jj が bookmark conflict 検出 | fetch→解消→push |

### 作業中の bookmark 付与

作業中の change ツリーの先頭には `wip-*` bookmark を付け、適切なタイミングで push する:

```bash
jj bookmark set wip-xxx -r @
jj git push --bookmark wip-xxx
```

### PR 昇格時

wip bookmark を削除し、正式な bookmark に切り替え:

```bash
jj bookmark delete wip-xxx
jj bookmark set feature/xxx -r @
jj git push
```

### 安全性

- jj は bookmark conflict を検出し、ローカルとリモートの両方で移動していた場合 push を拒否する
- git の `--force` と違い知らずに上書きするリスクがない

## トラブルシューティング

### "stale info" エラーで push が拒否される

git bare + jj workspace 方式のセットアップ直後や `git clone --bare` 後に発生しやすい。
git bare リポジトリの fetch refspec にブランチ用設定が不足していることが原因。

```bash
# 原因確認: refs/heads 用の refspec があるか
git --git-dir="$REPO_PARENT/.git" config --get-all remote.origin.fetch

# ブランチ用 refspec が無ければ追加
git --git-dir="$REPO_PARENT/.git" config --add remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'

# git fetch → jj fetch → push
git --git-dir="$REPO_PARENT/.git" fetch origin
jj git fetch
jj bookmark track {bookmark} --remote=origin  # untracked の場合
jj git export # jj の状態を git に反映
jj git push --bookmark {bookmark}
```

### tag が jj 側に見えない (`jj git fetch` 後も古い tag のまま)

`jj git fetch` は内部で git の `remote.<name>.tagOpt` / fetch refspec を読む。標準の `+refs/heads/*:...` だけだと **tag は自動取得されない** (jj 0.41 で確認、git の `fetch` と同じ挙動)。具体的には bump-semver の `vcs:latest-tag()` 等で「jj 経由で最新 tag を見る」ものが古い tag を返す現象に出る。

**恒久対処** (新規 clone 時に仕込む、`既存リポジトリの clone` 節参照):

```bash
git --git-dir="$REPO_PARENT/.git" config remote.origin.tagOpt --tags
```

これ以降 `jj git fetch` 1 発で tag も取得される + jj op log に記録される。

**既設定なしで tag が来ない既存環境の応急対処**:

```bash
# (a) bare git で直接 fetch --tags してから jj 側に取り込む
git --git-dir="$REPO_PARENT/.git" fetch --tags origin
jj git import   # bare git の変更 (tag を含む) を jj に反映

# (b) または上記の tagOpt 設定を入れてから jj git fetch
git --git-dir="$REPO_PARENT/.git" config remote.origin.tagOpt --tags
jj git fetch
```

`jj git import` は「外部 git で起きた変更を jj 側に取り込む」公式コマンド (colocate **off** で必要、colocate **on** だと毎コマンド自動実行)。tag は immutable なので bookmark conflict / 自動 rebase は起きず、副作用は op log エントリ追加のみで安全。

`jj git export` は向きが逆 (jj → git、bookmark 等の反映用)、tag fetch には**使わない**。

## ツール連携

### jj-worktree（git worktree → jj workspace shim）

`git worktree add/remove` を `jj workspace add/forget` に置き換える shim。Claude Code の EnterWorktree 等、内部で git worktree を呼ぶツールが jj workspace として自然に動作する。

jj 管理リポジトリでも以下の worktree 機能は使用を避ける必要はない:
- `EnterWorktree` / `ExitWorktree` — セッション内で隔離ワークスペースに切り替え
- Agent ツールの `isolation: "worktree"` — サブエージェントを隔離 workspace で実行

特に複数サブエージェントが同じファイルを編集する可能性がある場合は `isolation: "worktree"` を積極的に使う。

### jj-guard（git コマンドブロック）

jj 管理リポジトリで git コマンドの実行をブロックするフック。git 操作を試みると jj での代替を促される。

## 注意事項

- **pre-commit フック未対応**: jj は Git の pre-commit フックを実行しない。push 前に手動で lint/format を確認、または `jj fix` を使用
- **IDE の git fetch**: bookmark conflict が発生したら `jj git fetch` で解消
