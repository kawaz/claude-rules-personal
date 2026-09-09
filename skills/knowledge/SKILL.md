---
name: knowledge
description: 読むだけの参照知識のカタログ (索引 + 本文の二段構成)。索引に発火語があるトピックだけ `reference/<slug>.md` を Read する。プロジェクト横断メモリ (ローカル private リポ) の読み書き手順もここ。収録トピックの発火語 — daemon / service サブコマンド体系、常駐プロセスの status・restart・log の CLI 設計、launchd / systemd --user への常駐登録、supervise 監督者構成、XDG Base Directory によるアプリのファイル置き場、jj のリビジョン指定・配置オプション、越境作業の SSH 認証・commit signing 切替、別ディレクトリでのコマンド実行 (direnv exec と cwd)、op run による secret の env 注入、say に渡す頭字語のカタカナ化、CLI 設計の好み (サブコマンド / --help / completion)、kawaz 本人の表記正本、findings の書き方と記録委譲。
---

# knowledge — 参照知識カタログ

参照知識は 2 層ある。どちらも**索引を見て、必要なトピックのファイルだけ Read** する (context を最小化する)。索引だけ読んで該当が無ければ何も Read しない。

- **`reference/`** (このリポで git 管理、下記「索引」) — 公開してよい体系知識
- **プロジェクト横断メモリ** (ローカルの private リポ、下記「メモリ」) — kawaz の好み・feedback・環境の癖

索引エントリの書き方・追加削除の規約は `for-all/rules/rule-writing-guidelines.md` (常時ロード rule) が正本。
本文ファイルに書くのは**知識そのものだけ**: 出典・確定待ちの注記・採用側の個別事情・雑談めいたメモは書かず、help や spec の形で足りるものに表や節の装飾を足さない。

## メモリ (プロジェクト横断)

メモリの実体は面ごとの private リポにあり、どのリポを見るかは `${CLAUDE_PLUGIN_DATA}/memory-repos` (= `$CLAUDE_CONFIG_DIR/plugins/data/rules-personal-rules-personal/memory-repos`、1 行 1 ローカル絶対パス) が持つ。

読む手順:

1. `${CLAUDE_PLUGIN_DATA}/memory-repos` を Read する。無ければメモリ未設定 — 何もしない
2. 列挙された各パスの `MEMORY.md` を Read する (索引。`- [Title](file.md) — hook` の 1 行 1 件)
3. いまの話題に該当するエントリだけ、そのリポの `<slug>.md` を Read する

書く手順: 対象リポに `<slug>.md` を作り (frontmatter は `name` / `description` / `metadata.type: user|feedback|project|reference`、本文は 1 ファイル 1 事実、feedback / project は `**Why:**` と `**How to apply:**` を続ける)、`MEMORY.md` に 1 行足し、その 2 ファイルを**パス指定で** commit する (push は任意)。

書き先の判定:

- **auto-memory** (`$CLAUDE_CONFIG_DIR/projects/<project>/memory/`) — そのプロジェクトでしか意味を持たない事実
- **メモリリポ** — 別プロジェクトのセッションが読んで役に立つ事実 (kawaz の好み、ツール横断の運用、環境の癖、feedback)
- リポが複数列挙されている場合は、**その事実が効く最も広い面**に置く (業務でしか効かない → 業務面のリポ、個人面にも効く → personal)

## 索引

- [cli-daemon-subcommands](reference/cli-daemon-subcommands.md) — kawaz 製 CLI 共通の `daemon` / `service` サブコマンド体系 (1 instance = 1 unit、JSON 出力規約、OS 常駐登録)。
  発火語: daemon サブコマンド, service サブコマンド, supervise, 常駐プロセスの status / restart / log, launchd / systemd --user 登録, unit
- [app-file-placement](reference/app-file-placement.md) — アプリのファイル置き場 (設定 / データ / 状態 / キャッシュ / socket・pid) を XDG Base Directory で判定する。
  発火語: config / data / state / cache / runtime の使い分け, XDG_CONFIG_HOME, XDG_STATE_HOME, XDG_RUNTIME_DIR が無い, unix socket path 長制限
- [jj-rebase-options](reference/jj-rebase-options.md) — jj のリビジョン指定オプション (`-r` / `-s` / `-b` / `--onto` / `--insert-after` 等) の完全リファレンス。
  発火語: jj rebase, --onto, --insert-after, --insert-before, --source, --branch, jj のリビジョン指定
- [cross-env-ssh-signing](reference/cross-env-ssh-signing.md) — 複数 CLAUDE_CONFIG_DIR 環境をまたいだ push / commit signing の切替手順。
  発火語: 越境 push, SSH sign failed, No private key found, IdentityAgent, signing.key, SSH_AUTH_SOCK
- [direnv-exec-cwd](reference/direnv-exec-cwd.md) — 別ディレクトリでコマンドを実行する形と、cd だけ / direnv exec だけで踏む罠。
  発火語: direnv exec, 別ディレクトリでコマンド実行, cd したのに .envrc が効かない, SSH_AUTH_SOCK が切り替わらない, git -C, direnv allow
- [op-run-secret-injection](reference/op-run-secret-injection.md) — op run で secret を env に注入する形と、masking の 2 段運用。
  発火語: op run, 1Password CLI, op://, --no-masking, env-file, secret を env に注入
- [say-katakana](reference/say-katakana.md) — `say` に渡す頭字語のカタカナ変換表と変換の適用範囲。
  発火語: say, 音声通知, 読み上げ, 頭字語のカタカナ化
- [cli-design-preferences](reference/cli-design-preferences.md) — kawaz の CLI 設計の好み (サブコマンド構成 / `--help` の節構成 / bool フラグ / 引数位置 / completion)。
  発火語: CLI 設計, サブコマンド, --help, オプション, bool フラグ, completion, 引数パーサ
- [kawaz-identity](reference/kawaz-identity.md) — kawaz 本人の表記正本 (漢字 / かな / ローマ字 / 用途別の選び方 / 誤記)。
  発火語: 署名, 対外メール, 実名表記, 差出人名, ローマ字表記
- [findings-recording](reference/findings-recording.md) — findings ファイルの構成テンプレと、記録をサブエージェントに委譲するプロンプトの型。
  発火語: findings, 調査結果を記録, 検証記録, docs/findings, 記録委譲
