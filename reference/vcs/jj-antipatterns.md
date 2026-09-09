# jj で AI がハマりやすいアンチパターン

## 読み取りスキャンには `--ignore-working-copy` を付ける

`jj -R <repo> log/st/workspace list` は**読み取りのつもりでも working copy の snapshot を発生させる** (jj の通常動作)。複数リポを一括スキャンすると、各リポの default workspace が勝手に snapshot され、build 生成物などが working copy commit に取り込まれる (実測 2026-08-21: 一括スキャン中に別リポの `target/` 配下を snapshot しかけ、巨大ファイルだけ size ガードで拒否された)。

```bash
# Bad — 観測のつもりで対象リポの状態を変える
jj -R /path/to/repo log -r '...'

# Good — snapshot を発生させない
jj -R /path/to/repo --ignore-working-copy log -r '...'
```

調査・棚卸し・監視スクリプトなど「対象を変えないはず」の jj 呼び出しは全部これを付ける。

## restore / revert を多用する

git の癖で `jj restore` や revert 的操作をしがち。jj では `new` + `rebase` / `split` で組み替えるほうが自然で安全。

## 複数エージェントが同じワークスペースに書き込む

並列エージェントは必ず別ワークスペースで作業させる。別プロセス推奨。同じ working copy を触ると conflict や意図しないスナップショットが発生する。外側から作業中の ws に change を送り込む安全な手順は reference の `vcs/jj-restructure`。

## マージコミットを急いで作る

独立した作業を無理にマージコミットでまとめない。bookmark で管理し、必要になったら合流。マージが不要になったら `abandon` で消せる。

## git コマンドを使う

jj 管理リポジトリでは git コマンドを使わない。jj が管理する状態と不整合が起きる。**jj-guard** フックが jj 管理リポジトリでの git コマンド実行をブロックし、jj での代替を促す。

## worktree 系ツールを避ける

`git worktree add/remove` を `jj workspace add/forget` に置き換える shim **jj-worktree** があるため、Claude Code の EnterWorktree 等、内部で git worktree を呼ぶツールは jj workspace として自然に動作する。jj 管理リポジトリでも以下の worktree 機能は使用を避ける必要はない:

- `EnterWorktree` / `ExitWorktree` — セッション内で隔離ワークスペースに切り替え
- Agent ツールの `isolation: "worktree"` — サブエージェントを隔離 workspace で実行

特に複数サブエージェントが同じファイルを編集する可能性がある場合は `isolation: "worktree"` を積極的に使う。

## パス指定なしの `jj commit` / `jj split`

他セッションの未認識変更を巻き込む禁則。詳細と予防は reference の `vcs/jj-commit-basics`。

## `jj describe` だけ実行して終わる

@ に description を付けるだけで空 @ が進まないため「commit したつもり」事故になる。詳細は reference の `vcs/jj-commit-basics`。
