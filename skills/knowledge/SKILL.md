---
name: knowledge
description: 読むだけの参照知識のカタログ (索引 + 本文の二段構成)。索引に発火語があるトピックだけ `reference/<slug>.md` を Read する。収録トピックの発火語 — daemon / service サブコマンド体系、常駐プロセスの status・restart・log の CLI 設計、launchd / systemd --user への常駐登録、supervise 監督者構成、XDG Base Directory によるアプリのファイル置き場、jj のリビジョン指定・配置オプション、越境作業の SSH 認証・commit signing 切替。
---

# knowledge — 参照知識カタログ

`${CLAUDE_SKILL_DIR}/reference/` 配下のうち、**いま必要なトピックのファイルのみ Read** する (索引 + 本文の二段構成で context を最小化する)。索引だけ読んで該当が無ければ何も Read しない。

索引エントリの書き方・追加削除の規約は `for-all/rules/rule-writing-guidelines.md` (常時ロード rule) が正本。
本文ファイルに書くのは**知識そのものだけ**: 出典・確定待ちの注記・採用側の個別事情・雑談めいたメモは書かず、help や spec の形で足りるものに表や節の装飾を足さない。

## 索引

- [cli-daemon-subcommands](reference/cli-daemon-subcommands.md) — kawaz 製 CLI 共通の `daemon` / `service` サブコマンド体系 (1 instance = 1 unit、JSON 出力規約、OS 常駐登録)。
  発火語: daemon サブコマンド, service サブコマンド, supervise, 常駐プロセスの status / restart / log, launchd / systemd --user 登録, unit
- [app-file-placement](reference/app-file-placement.md) — アプリのファイル置き場 (設定 / データ / 状態 / キャッシュ / socket・pid) を XDG Base Directory で判定する。
  発火語: config / data / state / cache / runtime の使い分け, XDG_CONFIG_HOME, XDG_STATE_HOME, XDG_RUNTIME_DIR が無い, unix socket path 長制限
- [jj-rebase-options](reference/jj-rebase-options.md) — jj のリビジョン指定オプション (`-r` / `-s` / `-b` / `--onto` / `--insert-after` 等) の完全リファレンス。
  発火語: jj rebase, --onto, --insert-after, --insert-before, --source, --branch, jj のリビジョン指定
- [cross-env-ssh-signing](reference/cross-env-ssh-signing.md) — 複数 CLAUDE_CONFIG_DIR 環境をまたいだ push / commit signing の切替手順。
  発火語: 越境 push, SSH sign failed, No private key found, IdentityAgent, signing.key, SSH_AUTH_SOCK
