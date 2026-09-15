# CLI の daemon / service サブコマンド体系

kawaz 製 CLI に共通のサブコマンド体系。設定ファイルの場所を知らなくても、起動済み daemon の status 確認や再起動に到達できるようにする。

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
  start <unit> | --all      supervise に instance の起動を要求する
  stop <unit> | --all       supervise に停止を要求する (停止を待つ --wait や --force の追加は要件次第)
  restart <unit> | --all    stop → start
  status [<unit>] | --all   [{id, unit, running, pid, version, ...}]
  log [<unit>] | --all      instance のログ

  start / stop / restart / status は起動中の supervise に対する操作。supervise が未起動ならエラー終了。
  unit = 登録の単位で、案件ドメインが決める (dir / config ファイル / id など)。
  reload (設定再読み込み、再起動なし) や graceful_upgrade など、要件に応じたサブコマンドの追加・削除はしてよい。

<tool> service
  register | unregister     監督者 (`<tool> daemon supervise`) を launchd / systemd に登録する
  start | stop              監督者の起動 / 停止
  status                    → {registered, running, pid, service: {launchd / systemd 側から取れる情報 (loaded, running, pid, last_exit など)}, instances: [...]}
  log [--follow]            監督者と OS 側のログ

OPTIONS (共通)
  --all         登録 instance 全部を対象にする
  --follow      log で追従する
  --help        そのレベルの help
```

## `daemon supervise` を置く目的

**OS 登録の契約を binary 更新から切り離す。** 監督者は OS に「`<tool> daemon supervise` を常駐させる」という 1 点だけを約束する。unit の実体や数がどう変わっても、tool の binary を入れ替えても、この契約は変わらないので `service register` をやり直さない。OS 登録レベルの更新 (plist / unit ファイルの書き換え、署名や FDA 等の権限付与のやり直し) をバージョンアップ毎に発生させない。

**status とログのスコープを分離する。** `service` はサービスとしての面 (OS への登録の有無、監督者が上がっているか、OS 側から取れる last_exit 等) だけを担当する。`daemon` は子である instance の生存と再起動だけを担当する。OS の機能と重複しない — OS が見るのは監督者だけ、監督者が見るのは unit だけで、見る対象が階層で分かれている。

**障害時の単一入口にする。** daemon を複数管理すると、launchd 側だけで扱おうとした場合「今どの unit が登録されているか」「どの plist がどれに対応するか」を思い出し、その plist を指定して status を見る、という作業が先に挟まる。この手の操作は普段から頻繁にやるものではないので、障害に気づいて急いで見たい場面で launchd の使い方の確認から始まってしまう。`<tool> daemon status` / `log` / `restart` で全 unit を一発で扱えること、= 目的のコマンドの状態確認・ログ確認・再起動にサクッと到達できることが第一の目的。

**「監督者は OS の KeepAlive の再発明」は誤読。** 守る対象が違う。OS の KeepAlive が守るのは監督者 1 プロセス、監督者が守るのは登録された unit 群。片方を消すともう片方の対象が無監督になるので、どちらも要る。

ドメイン要件によっては launchd に登録する署名済み launcher を別途用意してそれを登録し、launcher は `<tool> daemon supervise` の起動と死活監視に徹する形も検討する。FDA 要求などがバージョンアップ毎に発生するのを回避するための構成。

関連: [cli-design-preferences](cli-design-preferences.md)
