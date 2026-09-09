# 参照知識の索引

- [cli-daemon-subcommands](cli-daemon-subcommands.md) — kawaz 製 CLI 共通の `daemon` / `service` サブコマンド体系 (1 instance = 1 unit、JSON 出力規約、OS 常駐登録)。
  発火語: daemon サブコマンド, service サブコマンド, supervise, 常駐プロセスの status / restart / log, launchd / systemd --user 登録, unit
- [app-file-placement](app-file-placement.md) — アプリのファイル置き場 (設定 / データ / 状態 / キャッシュ / socket・pid) を XDG Base Directory で判定する。
  発火語: config / data / state / cache / runtime の使い分け, XDG_CONFIG_HOME, XDG_STATE_HOME, XDG_RUNTIME_DIR が無い, unix socket path 長制限
- [jj-rebase-options](jj-rebase-options.md) — jj のリビジョン指定オプション (`-r` / `-s` / `-b` / `--onto` / `--insert-after` 等) の完全リファレンス。
  発火語: jj rebase, --onto, --insert-after, --insert-before, --source, --branch, jj のリビジョン指定
- [cross-env-ssh-signing](cross-env-ssh-signing.md) — 複数 CLAUDE_CONFIG_DIR 環境をまたいだ push / commit signing の切替手順。
  発火語: 越境 push, SSH sign failed, No private key found, IdentityAgent, signing.key, SSH_AUTH_SOCK
- [direnv-exec-cwd](direnv-exec-cwd.md) — 別ディレクトリでコマンドを実行する形と、cd だけ / direnv exec だけで踏む罠。
  発火語: direnv exec, 別ディレクトリでコマンド実行, cd したのに .envrc が効かない, SSH_AUTH_SOCK が切り替わらない, git -C, direnv allow
- [op-run-secret-injection](op-run-secret-injection.md) — op run で secret を env に注入する形と、masking の 2 段運用。
  発火語: op run, 1Password CLI, op://, --no-masking, env-file, secret を env に注入
- [say-katakana](say-katakana.md) — `say` に渡す頭字語のカタカナ変換表と変換の適用範囲。
  発火語: say, 音声通知, 読み上げ, 頭字語のカタカナ化
- [cli-design-preferences](cli-design-preferences.md) — kawaz の CLI 設計の好み (サブコマンド構成 / `--help` の節構成 / bool フラグ / 引数位置 / completion)。
  発火語: CLI 設計, サブコマンド, --help, オプション, bool フラグ, completion, 引数パーサ
- [findings-recording](findings-recording.md) — findings ファイルの構成テンプレと、記録をサブエージェントに委譲するプロンプトの型。
  発火語: findings, 調査結果を記録, 検証記録, docs/findings, 記録委譲

## private 層 (`~/.local/share/repos/github.com/kawaz/privacy-personal/main/reference/`)

本文は private リポにあり、索引だけをここに写す (privacy 側の `INDEX.md` を更新したら同じ変更でこちらも更新する)。未 clone なら何もしない。

- [kawaz-identity](~/.local/share/repos/github.com/kawaz/privacy-personal/main/reference/kawaz-identity.md) — kawaz 本人の表記正本 (漢字 / かな / ローマ字 / GitHub アカウント / 用途別の選び方 / 誤記)。
  発火語: 署名, 対外メール, 実名表記, 差出人名, ローマ字表記, GitHub アカウント名, 業務用アカウント
