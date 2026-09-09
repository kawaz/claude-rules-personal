# VCS (jj / git) の参照知識

## まずリポの構成を見分ける

`{repo}/` 直下を見て 3 方式のどれかを判定し、該当する setup ファイルを開く。コミット操作・組み替え・復旧は方式に依らず共通。

| 判定 | 方式 | 開くファイル |
|---|---|---|
| `{repo}/main/.git` と `{repo}/main/.jj` が両方**ディレクトリ** | colocate + 親ガード (新標準) | [jj-colocate-setup](jj-colocate-setup.md) |
| `{repo}/.jj` が実体で `{repo}/main/.git` が無い | git bare + jj workspace (旧方式) | [jj-bare-workspace-setup](jj-bare-workspace-setup.md) |
| `.jj` が無い | git bare + worktree (git 専用) | [git-worktree-setup](git-worktree-setup.md) |

## 本文

- [jj-commit-basics](jj-commit-basics.md) — 覚えるべき 5 コマンド、commit と split の使い分け、パス指定の禁則、describe だけで終わる事故。
  発火語: jj commit, jj split, jj describe, jj new, jj edit, コミットしたい, パス指定, pre-commit
- [jj-restructure](jj-restructure.md) — split / squash / rebase / duplicate による組み替え、過去コミットからのパス除去、隔離 workspace 経由の送り込み。
  発火語: jj rebase, jj squash, jj duplicate, jj abandon, コミットの並べ替え, 過去コミットから消したい, filter-repo, ignore-immutable, 作業中の ws に change を入れる
- [jj-recovery](jj-recovery.md) — op restore、bookmark 移動と push のハマりどころ、bookmark conflict、fork の upstream 追従。
  発火語: jj op restore, op log, push が拒否される, Refusing to move bookmark backwards, Name is conflicted, bookmark を消したい, upstream に追従
- [jj-antipatterns](jj-antipatterns.md) — 読み取りスキャンでの snapshot 事故、複数エージェントの同一 workspace、git コマンド混用、worktree ツールの扱い。
  発火語: --ignore-working-copy, 複数リポを一括スキャン, jj restore, 並列エージェント, jj-guard, jj-worktree, isolation worktree
- [jj-colocate-setup](jj-colocate-setup.md) — colocate + 親ガード方式のレイアウト・新規作成・clone・旧方式からの移行・作業場所の使い分け。
  発火語: colocate, 親ガード, jj git init, リポを作る, リポを clone, agent-worktree, main への統合
- [jj-bare-workspace-setup](jj-bare-workspace-setup.md) — 旧方式のセットアップ・workspace・PR 手順・署名・トラブルシュート。
  発火語: git bare, jj workspace add, PR を作る, wip を PR に昇格, sign-on-push, stale info, tag が jj に見えない, tagOpt
- [git-worktree-setup](git-worktree-setup.md) — git 専用リポの worktree 構成・命名・PR 手順。
  発火語: git worktree, pr-base, worktree move, git 専用リポ, ブランチ命名
- [jj-rebase-options](jj-rebase-options.md) — jj のリビジョン指定オプション (`-r` / `-s` / `-b` / `--onto` / `--insert-after` 等) の完全リファレンス。
  発火語: jj rebase, --onto, --insert-after, --insert-before, --source, --branch, jj のリビジョン指定
- [cross-env-ssh-signing](cross-env-ssh-signing.md) — 複数 CLAUDE_CONFIG_DIR 環境をまたいだ push / commit signing の切替手順。
  発火語: 越境 push, SSH sign failed, No private key found, IdentityAgent, signing.key, SSH_AUTH_SOCK
