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
  version     置いてある版と走っている版を並べる (--version は自分の版 1 行)
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

## `version` / `daemon status` / `service status` の出力

3 つは別の問いで、答えられる相手も違う。**版は走っている本人**、**子の生死は監督者**、**OS 登録は unit ファイルと launchctl / systemctl** しか知らない。知らないことは `null` にして、推し量らない。

### `<tool> version`

「置いてある版」と「走っている版」を並べる。`--version` (テキスト 1 行) はこの CLI 自身の版だけを言う口として残し、2 つを並べるのは `version` サブコマンドの仕事。

| field | 意味 |
|---|---|
| `cli` | 今叩いた CLI 自身の版 (`--version` と同じ) |
| `supervisor` | 監督者の `{running, on_disk, binary_path, restart_needed}`。OS に登録していなければ `null` (= 「監督者」という対象自体が無い) |
| `units[]` | unit ごとの `{unit, running, on_disk, binary_path, restart_needed}` |
| `running` | 走っているプロセス自身が答えた版 (= 今処理している版)。監督者が居ない / その口を持たない版が走っている → `null`。異常ではない |
| `on_disk` | 登録された binary に `--version` を聞いた版 (= 次に上がるときの版)。消えている / 名乗りが違う → `null` |
| `binary_path` | `on_disk` を読んだファイル。同名の binary が何箇所にも置かれる環境で「では何を入れ替えるのか」に届くため、版と並べて出す |
| `restart_needed` | `running` と `on_disk` の**両方が分かって**食い違うときだけ `true`。片方が `null` は「比べられない」であって食い違いではないので `false` |

ディスクのファイルの中身から版を推し量る経路は持たない。走っているプロセスがメモリに載せている版は本人にしか言えず、それが分からないなら 2 つを並べる意味が無い。

### `<tool> daemon status [<unit>] | --all`

監督者への問い合わせ。unit 1 行の形はこう:

| field | 意味 |
|---|---|
| `id` | 登録簿の並び順での番号 |
| `unit` | unit 名 |
| `enabled` | 居てほしいか (= 登録簿が持つ desired state)。`start` / `stop` が書き換える |
| `running` | 今いるか (= 監督者が子を抱えているか) |
| `pid` | 今の子の pid。居なければ省略 |
| `since_ms` | 今の子が起きた時刻。居なければ省略 |
| `version` | 走っている本人が答えた版。答えない版なら `null` |
| `restarts` | 監督者が起こし直した回数 |
| `last_exit` | 最後に終わったときの様子。一度も終わっていなければ省略 |

`enabled: true` かつ `running: false` で `restarts` が増え続けているなら、上げようとして失敗して backoff に入っている状態で、`last_exit` がその理由を持つ。この 3 つが揃っていないと「止めてあるのか、上がらないのか」が区別できない。

**監督者が居なければ `status` はエラー**。`supervisor_not_running` 相当の kind と、`daemon supervise` / `service start` を実行するための `hint` を添えて非 0 で終わる。監督者を飛ばして子を直接見に行く経路は持たない (= 生死の判定経路が 2 つに分岐する)。

**`daemon list` は登録の面を見る命令なので、監督者不在でも断らない**。登録簿から `{id, unit, enabled, config, binary_path}` を出し、監督者に聞けたときだけ `running` / `pid` を足す。聞けていない台に「動いている」と書くことはしない (知らないので)。

### `<tool> service status`

登録・OS から見た生死・抱えている台の 3 つを 1 つの答えに並べる。

| field | 意味 |
|---|---|
| `registered` | OS 側の unit ファイル (plist / systemd unit) が実在するか |
| `running` | **監督者の頼み口に届いたか**。OS が `loaded` と言っていても頼み口が開いていなければ頼めないので、届いたかどうかを正とする |
| `pid` | OS 側が答えた監督者の pid。分からなければ `null` |
| `label` / `path` | OS 側の label と unit ファイルのパス (= 人が launchctl / systemctl を直接叩くときの手がかり) |
| `service` | OS 側から取れる情報の入れ物: `{loaded, running, pid, last_exit}`。OS に聞けなくても `{loaded: false, running: false}` を返し、登録の有無までは答える |
| `instances[]` | 監督者が抱えている台の要約 (= `daemon status` の行と同じ形)。聞けなければ空配列 |

`registered` と `service.loaded` は別物 (ファイルが有るのに OS に載っていない状態がある)、`service.running` と top-level の `running` も別物 (OS から見て生きているのに頼み口が開いていない状態がある)。同じ語を階層で分けているのは、この食い違い自体を見せるため。

ドメイン要件によっては launchd に登録する署名済み launcher を別途用意してそれを登録し、launcher は `<tool> daemon supervise` の起動と死活監視に徹する形も検討する。FDA 要求などがバージョンアップ毎に発生するのを回避するための構成。

関連: [cli-design-preferences](cli-design-preferences.md)
