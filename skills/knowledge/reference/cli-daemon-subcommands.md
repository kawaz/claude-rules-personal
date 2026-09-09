# CLI の daemon / service サブコマンド体系

出典: kawaz 発言 (ccmsg r285 mid 27, 32〜34、2026-09-09)。確定は ccmsg v2 の仕様待ち。
kawaz 製 CLI (ccmsg v2 / hyoui / cache-warden / llm-gateway 等) に共通適用する。
狙い: 設定ファイルの場所を知らないゼロ知識の状態から、起動済み daemon の status 確認や再起動に到達できること。

```
<tool> — one instance per <unit>

USAGE
  <tool> <command> [subcommand] [options] [--] [args...]
  引数なし / --help はテキストの help。それ以外の出力は JSON または JSONL (エラーも JSON、stderr、exit≠0)
  子を持つレベルと必須引数のあるコマンドは、引数なしで help。省略可能な引数だけのコマンドは実行

COMMANDS
  daemon      instance (= 1 <unit>) のプロセス操作
  service     OS への常駐登録 (launchd / systemd --user)。監督者を登録する
  ...         ツール固有のコマンド

<tool> daemon
  run [unit]                この unit の instance を foreground で起動する (未指定の場合はデフォルト)
  supervise                 foreground の監督者: 登録された instance を子として run で起動し、落ちたら上げる
  add <unit>                登録する
  remove <unit>             登録を外す
  list                      → [{id, unit, running, pid}]
  start <unit> | --all      supervise に instance の起動を要求する (add した unit を起動するトリガー)
  stop <unit> | --all       supervise に停止を要求する (対象プロセスの停止を待つかはツールの要件次第)
  restart <unit> | --all    stop → start
  status [<unit>] | --all   [{id, unit, running, pid, version, ...}]
  log [<unit>] | --all      instance のログ

  start / stop / restart / status は起動中の supervise に対する操作。supervise が未起動ならエラー終了。
  手元で単体起動したいだけなら run で足りる。
  unit = 登録の単位で、案件ドメインが決める (dir / config ファイル / id など)。

<tool> service
  register | unregister     監督者 (`<tool> daemon supervise`) を launchd / systemd に登録する
  start | stop              監督者の起動 / 停止
  status                    → {registered, running, pid, service: {OS 側の loaded, running, pid, last_exit}, instances: [...]}
  log [--follow]            監督者と OS 側のログ

OPTIONS (共通)
  --all         登録 instance 全部を対象にする
  --follow      log で追従する
  --help        そのレベルの help
```

ドメイン要件によっては launchd に登録する署名済み launcher を別途用意してそれを登録し、launcher は `<tool> daemon supervise` の起動と死活監視に徹する形も検討する。FDA 要求などがバージョンアップ毎に発生するのを回避するための構成。

採用側 (llm-gateway) で決まった補足:

- unit の設定に `binary_path` (既定は自分自身)
- restart 戦略や優先順位はツール固有
- 既存の `status` 系コマンドとの語彙衝突は `upstream status` 等に寄せる
- unit の既定値は「登録が 1 つならそれ、複数なら名前か `--all` を要求」

関連: [[cli-design-preferences]]
